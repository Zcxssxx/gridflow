///|
priv struct Complex {
  re : Double
  im : Double
}

///|
fn complex_add(a : Complex, b : Complex) -> Complex {
  { re: a.re + b.re, im: a.im + b.im, }
}

///|
fn complex_neg(a : Complex) -> Complex {
  { re: -a.re, im: -a.im, }
}

///|
fn complex_mul(a : Complex, b : Complex) -> Complex {
  { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re, }
}

///|
fn complex_conjugate(a : Complex) -> Complex {
  { re: a.re, im: -a.im, }
}

///|
fn complex_div(a : Complex, b : Complex) -> Complex {
  let denominator = b.re * b.re + b.im * b.im
  {
    re: (a.re * b.re + a.im * b.im) / denominator,
    im: (a.im * b.re - a.re * b.im) / denominator,
  }
}

///|
fn branch_admittances(branch : Branch) -> (Complex, Complex, Complex, Complex) {
  let impedance_square = branch.r_pu * branch.r_pu + branch.x_pu * branch.x_pu
  let series = {
    re: branch.r_pu / impedance_square,
    im: -branch.x_pu / impedance_square,
  }
  let charging = { re: 0.0, im: branch.b_pu / 2.0, }
  let tap_angle = branch.phase_shift_degree * 3.141592653589793 / 180.0
  let tap = {
    re: branch.tap_ratio * @math.cos(tap_angle),
    im: branch.tap_ratio * @math.sin(tap_angle),
  }
  let tap_square = branch.tap_ratio * branch.tap_ratio
  let yff = complex_add(series, charging)
  let yff = { re: yff.re / tap_square, im: yff.im / tap_square, }
  let ytt = complex_add(series, charging)
  let yft = complex_neg(complex_div(series, complex_conjugate(tap)))
  let ytf = complex_neg(complex_div(series, tap))
  (yff, yft, ytf, ytt)
}

///|
fn make_ybus(network : Network) -> (Array[Array[Double]], Array[Array[Double]]) {
  let count = network.buses.length()
  let g = Array::make(count, Array::make(0, 0.0))
  let b = Array::make(count, Array::make(0, 0.0))
  for i in 0..<count {
    g[i] = Array::make(count, 0.0)
    b[i] = Array::make(count, 0.0)
    g[i][i] = network.buses[i].shunt_g_mw / network.base_mva
    b[i][i] = network.buses[i].shunt_b_mvar / network.base_mva
  }
  for branch in network.branches {
    if branch.in_service {
      let from_index = find_bus_index(network.buses, branch.from_bus).unwrap()
      let to_index = find_bus_index(network.buses, branch.to_bus).unwrap()
      let (yff, yft, ytf, ytt) = branch_admittances(branch)
      g[from_index][from_index] += yff.re
      b[from_index][from_index] += yff.im
      g[from_index][to_index] += yft.re
      b[from_index][to_index] += yft.im
      g[to_index][from_index] += ytf.re
      b[to_index][from_index] += ytf.im
      g[to_index][to_index] += ytt.re
      b[to_index][to_index] += ytt.im
    }
  }
  (g, b)
}

///|
fn calculate_injections(
  g : Array[Array[Double]],
  b : Array[Array[Double]],
  vm : Array[Double],
  va : Array[Double],
) -> (Array[Double], Array[Double]) {
  let count = vm.length()
  let p = Array::make(count, 0.0)
  let q = Array::make(count, 0.0)
  for i in 0..<count {
    for j in 0..<count {
      let difference = va[i] - va[j]
      let angle_cos = @math.cos(difference)
      let angle_sin = @math.sin(difference)
      let scale = vm[i] * vm[j]
      p[i] += scale * (g[i][j] * angle_cos + b[i][j] * angle_sin)
      q[i] += scale * (g[i][j] * angle_sin - b[i][j] * angle_cos)
    }
  }
  (p, q)
}

///|
fn solve_dense(
  matrix : Array[Array[Double]],
  rhs : Array[Double],
) -> Result[Array[Double], Int32] {
  let size = rhs.length()
  for column in 0..<size {
    let mut pivot_row = column
    let mut pivot_value = matrix[column][column].abs()
    for row in (column + 1)..<size {
      let candidate = matrix[row][column].abs()
      if candidate > pivot_value {
        pivot_row = row
        pivot_value = candidate
      }
    }
    if pivot_value < 1.0e-14 {
      return Err(column)
    }
    if pivot_row != column {
      let row_swap = matrix[column]
      matrix[column] = matrix[pivot_row]
      matrix[pivot_row] = row_swap
      let value_swap = rhs[column]
      rhs[column] = rhs[pivot_row]
      rhs[pivot_row] = value_swap
    }
    for row in (column + 1)..<size {
      let factor = matrix[row][column] / matrix[column][column]
      matrix[row][column] = 0.0
      for j in (column + 1)..<size {
        matrix[row][j] -= factor * matrix[column][j]
      }
      rhs[row] -= factor * rhs[column]
    }
  }
  let solution = Array::make(size, 0.0)
  for offset in 0..<size {
    let row = size - offset - 1
    let mut value = rhs[row]
    for column in (row + 1)..<size {
      value -= matrix[row][column] * solution[column]
    }
    solution[row] = value / matrix[row][row]
  }
  Ok(solution)
}

///|
fn build_jacobian(
  g : Array[Array[Double]],
  b : Array[Array[Double]],
  vm : Array[Double],
  va : Array[Double],
  p : Array[Double],
  q : Array[Double],
  angle_buses : Array[Int32],
  pq_buses : Array[Int32],
) -> Array[Array[Double]] {
  let angle_count = angle_buses.length()
  let pq_count = pq_buses.length()
  let size = angle_count + pq_count
  let jacobian = Array::make(size, Array::make(0, 0.0))
  for i in 0..<size {
    jacobian[i] = Array::make(size, 0.0)
  }

  for row in 0..<angle_count {
    let i = angle_buses[row]
    for column in 0..<angle_count {
      let j = angle_buses[column]
      if i == j {
        jacobian[row][column] = -q[i] - b[i][i] * vm[i] * vm[i]
      } else {
        let difference = va[i] - va[j]
        jacobian[row][column] = vm[i] *
          vm[j] *
          (g[i][j] * @math.sin(difference) - b[i][j] * @math.cos(difference))
      }
    }
    for column in 0..<pq_count {
      let j = pq_buses[column]
      let jacobian_column = angle_count + column
      if i == j {
        jacobian[row][jacobian_column] = p[i] / vm[i] + g[i][i] * vm[i]
      } else {
        let difference = va[i] - va[j]
        jacobian[row][jacobian_column] = vm[i] *
          (g[i][j] * @math.cos(difference) + b[i][j] * @math.sin(difference))
      }
    }
  }

  for row in 0..<pq_count {
    let i = pq_buses[row]
    let jacobian_row = angle_count + row
    for column in 0..<angle_count {
      let j = angle_buses[column]
      if i == j {
        jacobian[jacobian_row][column] = p[i] - g[i][i] * vm[i] * vm[i]
      } else {
        let difference = va[i] - va[j]
        jacobian[jacobian_row][column] = -vm[i] *
          vm[j] *
          (g[i][j] * @math.cos(difference) + b[i][j] * @math.sin(difference))
      }
    }
    for column in 0..<pq_count {
      let j = pq_buses[column]
      let jacobian_column = angle_count + column
      if i == j {
        jacobian[jacobian_row][jacobian_column] = q[i] / vm[i] - b[i][i] * vm[i]
      } else {
        let difference = va[i] - va[j]
        jacobian[jacobian_row][jacobian_column] = vm[i] *
          (g[i][j] * @math.sin(difference) - b[i][j] * @math.cos(difference))
      }
    }
  }
  jacobian
}

///|
fn make_power_flow_result(
  network : Network,
  vm : Array[Double],
  va : Array[Double],
  g : Array[Array[Double]],
  b : Array[Array[Double]],
  iterations : Int32,
  mismatch : Double,
) -> PowerFlowResult {
  let (p, q) = calculate_injections(g, b, vm, va)
  let bus_results = []
  for i in 0..<network.buses.length() {
    let bus = network.buses[i]
    let p_generation = p[i] * network.base_mva + bus.p_load_mw
    let q_generation = q[i] * network.base_mva + bus.q_load_mvar
    bus_results.push({
      bus_id: bus.id,
      voltage_magnitude_pu: vm[i],
      voltage_angle_degree: va[i] * 180.0 / 3.141592653589793,
      p_generation_mw: p_generation,
      q_generation_mvar: q_generation,
      p_injection_mw: p[i] * network.base_mva,
      q_injection_mvar: q[i] * network.base_mva,
    })
  }

  let branch_results = []
  for branch in network.branches {
    if branch.in_service {
      let (yff, yft, ytf, ytt) = branch_admittances(branch)
      let from_index = find_bus_index(network.buses, branch.from_bus).unwrap()
      let to_index = find_bus_index(network.buses, branch.to_bus).unwrap()
      let from_angle = va[from_index]
      let to_angle = va[to_index]
      let from_voltage = {
        re: vm[from_index] * @math.cos(from_angle),
        im: vm[from_index] * @math.sin(from_angle),
      }
      let to_voltage = {
        re: vm[to_index] * @math.cos(to_angle),
        im: vm[to_index] * @math.sin(to_angle),
      }
      let from_current = complex_add(
        complex_mul(yff, from_voltage),
        complex_mul(yft, to_voltage),
      )
      let to_current = complex_add(
        complex_mul(ytf, from_voltage),
        complex_mul(ytt, to_voltage),
      )
      let from_power = complex_mul(
        from_voltage,
        complex_conjugate(from_current),
      )
      let to_power = complex_mul(to_voltage, complex_conjugate(to_current))
      let p_from = from_power.re * network.base_mva
      let q_from = from_power.im * network.base_mva
      let p_to = to_power.re * network.base_mva
      let q_to = to_power.im * network.base_mva
      branch_results.push({
        from_bus: branch.from_bus,
        to_bus: branch.to_bus,
        in_service: true,
        p_from_mw: p_from,
        q_from_mvar: q_from,
        p_to_mw: p_to,
        q_to_mvar: q_to,
        p_loss_mw: p_from + p_to,
        q_loss_mvar: q_from + q_to,
      })
    } else {
      branch_results.push({
        from_bus: branch.from_bus,
        to_bus: branch.to_bus,
        in_service: false,
        p_from_mw: 0.0,
        q_from_mvar: 0.0,
        p_to_mw: 0.0,
        q_to_mvar: 0.0,
        p_loss_mw: 0.0,
        q_loss_mvar: 0.0,
      })
    }
  }
  {
    buses: bus_results,
    branches: branch_results,
    iterations,
    max_mismatch_pu: mismatch,
  }
}

///|
/// Solve balanced positive-sequence AC power flow with a polar Newton method.
/// Values are reported in per-unit, MW, MVAr, and degrees as named in the result.
pub fn solve_power_flow(
  network : Network,
  options~ : SolveOptions = SolveOptions::default(),
) -> Result[PowerFlowResult, PowerFlowError] {
  match validate_network(network) {
    Err(error) => return Err(InvalidNetwork(error))
    Ok(_) => ()
  }
  if !finite(options.tolerance_pu) ||
    options.tolerance_pu <= 0.0 ||
    options.max_iterations <= 0 {
    return Err(InvalidOptions)
  }

  let (g, b) = make_ybus(network)
  let count = network.buses.length()
  let vm = Array::make(count, 1.0)
  let va = Array::make(count, 0.0)
  let angle_buses = []
  let pq_buses = []
  let mut pv_buses = []
  let specified_p = Array::make(count, 0.0)
  let specified_q = Array::make(count, 0.0)

  for i in 0..<count {
    let bus = network.buses[i]
    vm[i] = bus.vm_pu
    va[i] = bus.va_degree * 3.141592653589793 / 180.0
    let mut generator_p = 0.0
    let mut generator_q = 0.0
    let mut voltage_set = bus.vm_pu
    for generator in network.generators {
      if generator.in_service && generator.bus_id == bus.id {
        generator_p += generator.p_mw
        generator_q += generator.q_mvar
        voltage_set = generator.v_set_pu
      }
    }
    specified_p[i] = (generator_p - bus.p_load_mw) / network.base_mva
    specified_q[i] = (generator_q - bus.q_load_mvar) / network.base_mva
    match bus.kind {
      PQ => {
        angle_buses.push(i)
        pq_buses.push(i)
      }
      PV => {
        angle_buses.push(i)
        pv_buses.push(i)
        vm[i] = voltage_set
      }
      Slack => ()
    }
  }

  let mut iteration = 0
  let mut total_iterations = 0
  while iteration <= options.max_iterations {
    let (p, q) = calculate_injections(g, b, vm, va)
    let mismatch = []
    let mut max_mismatch = 0.0
    for i in 0..<count {
      if !finite(p[i]) || !finite(q[i]) || !finite(vm[i]) || !finite(va[i]) {
        return Err(NonFiniteCalculation(total_iterations))
      }
    }
    for i in angle_buses {
      let value = specified_p[i] - p[i]
      if !finite(value) {
        return Err(NonFiniteCalculation(total_iterations))
      }
      mismatch.push(value)
      if value.abs() > max_mismatch {
        max_mismatch = value.abs()
      }
    }
    for i in pq_buses {
      let value = specified_q[i] - q[i]
      if !finite(value) {
        return Err(NonFiniteCalculation(total_iterations))
      }
      mismatch.push(value)
      if value.abs() > max_mismatch {
        max_mismatch = value.abs()
      }
    }
    if max_mismatch <= options.tolerance_pu {
      if options.enforce_q_limits && pv_buses.length() > 0 {
        let remaining_pv = []
        let mut changed_bus_type = false
        for i in pv_buses {
          let bus = network.buses[i]
          let mut q_min = 0.0
          let mut q_max = 0.0
          for generator in network.generators {
            if generator.in_service && generator.bus_id == bus.id {
              q_min += generator.q_min_mvar
              q_max += generator.q_max_mvar
            }
          }
          let q_generation = q[i] * network.base_mva + bus.q_load_mvar
          if q_generation < q_min {
            specified_q[i] = (q_min - bus.q_load_mvar) / network.base_mva
            pq_buses.push(i)
            changed_bus_type = true
          } else if q_generation > q_max {
            specified_q[i] = (q_max - bus.q_load_mvar) / network.base_mva
            pq_buses.push(i)
            changed_bus_type = true
          } else {
            remaining_pv.push(i)
          }
        }
        if changed_bus_type {
          pv_buses = remaining_pv
          iteration = 0
          continue
        }
      }
      return Ok(
        make_power_flow_result(
          network, vm, va, g, b, total_iterations, max_mismatch,
        ),
      )
    }
    if iteration == options.max_iterations {
      return Err(DidNotConverge(total_iterations, max_mismatch))
    }

    let jacobian = build_jacobian(g, b, vm, va, p, q, angle_buses, pq_buses)
    for row in jacobian {
      for value in row {
        if !finite(value) {
          return Err(NonFiniteCalculation(total_iterations))
        }
      }
    }
    let correction = match solve_dense(jacobian, mismatch) {
      Err(column) => return Err(SingularJacobian(column))
      Ok(values) => values
    }
    for value in correction {
      if !finite(value) {
        return Err(NonFiniteCalculation(total_iterations))
      }
    }
    for i in 0..<angle_buses.length() {
      va[angle_buses[i]] += correction[i]
    }
    for i in 0..<pq_buses.length() {
      vm[pq_buses[i]] += correction[angle_buses.length() + i]
    }
    iteration += 1
    total_iterations += 1
  }
  Err(DidNotConverge(total_iterations, 0.0))
}
