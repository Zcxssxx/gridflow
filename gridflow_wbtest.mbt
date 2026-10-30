///|
test "dense linear solver pivots rows when the diagonal starts at zero" {
  let matrix = [[0.0, 2.0], [1.0, 1.0]]
  match solve_dense(matrix, [4.0, 3.0]) {
    Ok(solution) => {
      assert_true((solution[0] - 1.0).abs() < 1.0e-12)
      assert_true((solution[1] - 2.0).abs() < 1.0e-12)
    }
    Err(_) => fail("row pivoting should solve a nonsingular system")
  }
}

///|
test "dense linear solver reports singular systems" {
  let matrix = [[1.0, 2.0], [2.0, 4.0]]
  assert_true(solve_dense(matrix, [3.0, 6.0]) is Err(_))
}

///|
test "analytic polar Jacobian matches finite differences with transformer terms" {
  let network = Network::new(
    base_mva=100.0,
    buses=[
      Bus::new(id=10, kind=Slack, shunt_g_mw=1.2, shunt_b_mvar=2.5),
      Bus::new(id=20, kind=PV, shunt_b_mvar=-1.0),
      Bus::new(id=30, kind=PQ),
    ],
    generators=[
      Generator::new(bus_id=10, p_mw=0.0),
      Generator::new(bus_id=20, p_mw=20.0),
    ],
    branches=[
      Branch::new(
        from_bus=10,
        to_bus=20,
        r_pu=0.02,
        x_pu=0.15,
        b_pu=0.03,
        tap_ratio=1.05,
        phase_shift_degree=7.0,
      ),
      Branch::new(from_bus=20, to_bus=30, r_pu=0.03, x_pu=0.2, b_pu=0.02),
      Branch::new(from_bus=10, to_bus=30, r_pu=0.015, x_pu=0.12, b_pu=0.01),
    ],
  )
  let (g, b) = make_ybus(network)
  let vm = [1.02, 1.03, 0.97]
  let va = [0.0, 0.12, -0.08]
  let angle_buses = [1, 2]
  let pq_buses = [2]
  let (p, q) = calculate_injections(g, b, vm, va)
  let jacobian = build_jacobian(g, b, vm, va, p, q, angle_buses, pq_buses)
  let step = 1.0e-6

  let (p_plus_a, q_plus_a) = calculate_injections(g, b, vm, [
    0.0,
    0.12 + step,
    -0.08,
  ])
  let (p_minus_a, q_minus_a) = calculate_injections(g, b, vm, [
    0.0,
    0.12 - step,
    -0.08,
  ])
  assert_true(
    ((p_plus_a[1] - p_minus_a[1]) / (2.0 * step) - jacobian[0][0]).abs() <
    1.0e-6,
  )
  assert_true(
    ((p_plus_a[2] - p_minus_a[2]) / (2.0 * step) - jacobian[1][0]).abs() <
    1.0e-6,
  )
  assert_true(
    ((q_plus_a[2] - q_minus_a[2]) / (2.0 * step) - jacobian[2][0]).abs() <
    1.0e-6,
  )

  let (p_plus_b, q_plus_b) = calculate_injections(g, b, vm, [
    0.0,
    0.12,
    -0.08 + step,
  ])
  let (p_minus_b, q_minus_b) = calculate_injections(g, b, vm, [
    0.0,
    0.12,
    -0.08 - step,
  ])
  assert_true(
    ((p_plus_b[1] - p_minus_b[1]) / (2.0 * step) - jacobian[0][1]).abs() <
    1.0e-6,
  )
  assert_true(
    ((p_plus_b[2] - p_minus_b[2]) / (2.0 * step) - jacobian[1][1]).abs() <
    1.0e-6,
  )
  assert_true(
    ((q_plus_b[2] - q_minus_b[2]) / (2.0 * step) - jacobian[2][1]).abs() <
    1.0e-6,
  )

  let (p_plus_v, q_plus_v) = calculate_injections(
    g,
    b,
    [1.02, 1.03, 0.97 + step],
    va,
  )
  let (p_minus_v, q_minus_v) = calculate_injections(
    g,
    b,
    [1.02, 1.03, 0.97 - step],
    va,
  )
  assert_true(
    ((p_plus_v[1] - p_minus_v[1]) / (2.0 * step) - jacobian[0][2]).abs() <
    1.0e-6,
  )
  assert_true(
    ((p_plus_v[2] - p_minus_v[2]) / (2.0 * step) - jacobian[1][2]).abs() <
    1.0e-6,
  )
  assert_true(
    ((q_plus_v[2] - q_minus_v[2]) / (2.0 * step) - jacobian[2][2]).abs() <
    1.0e-6,
  )
}
