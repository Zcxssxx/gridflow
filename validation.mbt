///|
fn finite(value : Double) -> Bool {
  value == value && value - value == 0.0
}

///|
fn find_bus_index(buses : Array[Bus], bus_id : Int32) -> Int32? {
  for i in 0..<buses.length() {
    if buses[i].id == bus_id {
      return Some(i)
    }
  }
  None
}

///|
/// Validate topology and numerical parameters before constructing the Y-bus.
pub fn validate_network(
  network : Network,
) -> Result[Unit, NetworkValidationError] {
  if network.buses.length() == 0 {
    return Err(EmptyNetwork)
  }
  if !finite(network.base_mva) || network.base_mva <= 0.0 {
    return Err(InvalidBaseMva)
  }

  let mut slack_count = 0
  let mut slack_index = -1
  for i in 0..<network.buses.length() {
    let bus = network.buses[i]
    for j in 0..<i {
      if network.buses[j].id == bus.id {
        return Err(DuplicateBusId(bus.id))
      }
    }
    if !finite(bus.p_load_mw) ||
      !finite(bus.q_load_mvar) ||
      !finite(bus.shunt_g_mw) ||
      !finite(bus.shunt_b_mvar) ||
      !finite(bus.vm_pu) ||
      !finite(bus.va_degree) ||
      bus.vm_pu <= 0.0 {
      return Err(InvalidBusData(bus.id))
    }
    if bus.kind is Slack {
      slack_count += 1
      slack_index = i
    }
  }
  if slack_count == 0 {
    return Err(MissingSlackBus)
  }
  if slack_count > 1 {
    return Err(MultipleSlackBuses)
  }

  for i in 0..<network.generators.length() {
    let generator = network.generators[i]
    if find_bus_index(network.buses, generator.bus_id) is None {
      return Err(UnknownGeneratorBus(generator.bus_id))
    }
    if !finite(generator.p_mw) ||
      !finite(generator.q_mvar) ||
      !finite(generator.q_min_mvar) ||
      !finite(generator.q_max_mvar) ||
      !finite(generator.v_set_pu) ||
      generator.v_set_pu <= 0.0 {
      return Err(InvalidGeneratorData(generator.bus_id))
    }
    if generator.q_min_mvar > generator.q_max_mvar {
      return Err(InvalidGeneratorReactiveLimits(generator.bus_id))
    }
  }

  for i in 0..<network.buses.length() {
    let bus = network.buses[i]
    if bus.kind is PV || bus.kind is Slack {
      let mut has_generator = false
      for generator in network.generators {
        if generator.bus_id == bus.id && generator.in_service {
          has_generator = true
        }
      }
      if !has_generator {
        return Err(MissingGeneratorAtControlledBus(bus.id))
      }
    }
  }

  for branch in network.branches {
    if find_bus_index(network.buses, branch.from_bus) is None {
      return Err(UnknownBranchBus(branch.from_bus))
    }
    if find_bus_index(network.buses, branch.to_bus) is None {
      return Err(UnknownBranchBus(branch.to_bus))
    }
    if branch.from_bus == branch.to_bus {
      return Err(BranchLoop(branch.from_bus))
    }
    if !finite(branch.r_pu) ||
      !finite(branch.x_pu) ||
      !finite(branch.b_pu) ||
      !finite(branch.tap_ratio) ||
      !finite(branch.phase_shift_degree) ||
      (branch.r_pu == 0.0 && branch.x_pu == 0.0) {
      return Err(InvalidBranchImpedance(branch.from_bus, branch.to_bus))
    }
    if branch.tap_ratio <= 0.0 {
      return Err(InvalidTapRatio(branch.from_bus, branch.to_bus))
    }
  }

  // Propagate reachability from the slack bus until the active topology stops changing.
  let reached = Array::make(network.buses.length(), false)
  reached[slack_index] = true
  let mut changed = true
  while changed {
    changed = false
    for branch in network.branches {
      if branch.in_service {
        let from_index = find_bus_index(network.buses, branch.from_bus).unwrap()
        let to_index = find_bus_index(network.buses, branch.to_bus).unwrap()
        if reached[from_index] && !reached[to_index] {
          reached[to_index] = true
          changed = true
        }
        if reached[to_index] && !reached[from_index] {
          reached[from_index] = true
          changed = true
        }
      }
    }
  }
  for i in 0..<network.buses.length() {
    if !reached[i] {
      return Err(IsolatedBus(network.buses[i].id))
    }
  }

  Ok(())
}
