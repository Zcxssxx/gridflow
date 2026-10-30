///|
test "validation rejects a network without a slack bus" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[@gridflow.Bus::new(id=1, kind=@gridflow.BusKind::PQ)],
    generators=[],
    branches=[],
  )
  match @gridflow.validate_network(network) {
    Err(@gridflow.NetworkValidationError::MissingSlackBus) => ()
    _ => fail("network without a slack bus must be rejected")
  }
}

///|
test "validation rejects non-positive base MVA" {
  let network = @gridflow.Network::new(
    base_mva=0.0,
    buses=[@gridflow.Bus::new(id=1, kind=@gridflow.Slack)],
    generators=[],
    branches=[],
  )
  match @gridflow.validate_network(network) {
    Err(@gridflow.NetworkValidationError::InvalidBaseMva) => ()
    _ => fail("base MVA must be positive")
  }
}

///|
test "validation rejects duplicate bus identifiers" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(id=1, kind=@gridflow.PQ),
    ],
    generators=[],
    branches=[],
  )
  match @gridflow.validate_network(network) {
    Err(@gridflow.NetworkValidationError::DuplicateBusId(1)) => ()
    _ => fail("duplicate bus IDs must be rejected")
  }
}

///|
test "validation rejects branches with unknown endpoints" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[@gridflow.Bus::new(id=1, kind=@gridflow.Slack)],
    generators=[@gridflow.Generator::new(bus_id=1, p_mw=0.0)],
    branches=[@gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1)],
  )
  match @gridflow.validate_network(network) {
    Err(@gridflow.NetworkValidationError::UnknownBranchBus(2)) => ()
    _ => fail("unknown branch endpoint must be rejected")
  }
}

///|
test "validation rejects zero series impedance" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(id=2, kind=@gridflow.PQ),
    ],
    generators=[@gridflow.Generator::new(bus_id=1, p_mw=0.0)],
    branches=[@gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.0, x_pu=0.0)],
  )
  match @gridflow.validate_network(network) {
    Err(@gridflow.NetworkValidationError::InvalidBranchImpedance(1, 2)) => ()
    _ => fail("zero series impedance must be rejected")
  }
}

///|
test "validation rejects a disconnected bus" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(id=2, kind=@gridflow.PQ),
      @gridflow.Bus::new(id=3, kind=@gridflow.PQ),
    ],
    generators=[@gridflow.Generator::new(bus_id=1, p_mw=0.0)],
    branches=[@gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1)],
  )
  match @gridflow.validate_network(network) {
    Err(@gridflow.NetworkValidationError::IsolatedBus(3)) => ()
    _ => fail("disconnected buses must be rejected")
  }
}

///|
test "two-bus Newton solve balances active and reactive power" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(
        id=2,
        kind=@gridflow.PQ,
        p_load_mw=100.0,
        q_load_mvar=50.0,
      ),
    ],
    generators=[@gridflow.Generator::new(bus_id=1, p_mw=0.0)],
    branches=[@gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1)],
  )
  match @gridflow.solve_power_flow(network) {
    Ok(result) => {
      assert_eq(result.buses.length(), 2)
      assert_eq(result.branches.length(), 1)
      assert_true(result.iterations > 0)
      assert_true(result.max_mismatch_pu < 1.0e-8)
      let slack = result.buses[0]
      let load = result.buses[1]
      let line = result.branches[0]
      assert_true(slack.p_generation_mw > 100.0)
      assert_true(slack.q_generation_mvar > 50.0)
      // Closed-form two-bus solution for this series-impedance load case.
      assert_true(
        (load.voltage_magnitude_pu - 0.930274994519425).abs() < 1.0e-8,
      )
      assert_true((load.voltage_angle_degree + 5.86128228603902).abs() < 1.0e-8)
      assert_true((slack.p_generation_mw - 101.44439946256278).abs() < 1.0e-6)
      assert_true((slack.q_generation_mvar - 64.44399462562796).abs() < 1.0e-6)
      assert_true(load.voltage_magnitude_pu < 1.0)
      assert_true(line.p_loss_mw > 0.0)
      assert_true(
        (line.p_from_mw + line.p_to_mw - line.p_loss_mw).abs() < 1.0e-8,
      )
    }
    Err(@gridflow.DidNotConverge(iterations, mismatch)) =>
      fail("two-bus case did not converge: \{iterations}, \{mismatch}")
    Err(@gridflow.SingularJacobian(column)) =>
      fail("two-bus Jacobian was singular at column \{column}")
    Err(_) => fail("two-bus case returned an unexpected solver error")
  }
}

///|
test "PV reactive limit enforcement converts the bus to PQ" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(
        id=2,
        kind=@gridflow.PV,
        p_load_mw=100.0,
        q_load_mvar=80.0,
        vm_pu=1.04,
      ),
    ],
    generators=[
      @gridflow.Generator::new(bus_id=1, p_mw=0.0),
      @gridflow.Generator::new(
        bus_id=2,
        p_mw=100.0,
        q_min_mvar=-20.0,
        q_max_mvar=20.0,
        v_set_pu=1.04,
      ),
    ],
    branches=[@gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1)],
  )
  let options = @gridflow.SolveOptions::default()
  let options = { ..options, enforce_q_limits: true, }
  match @gridflow.solve_power_flow(network, options~) {
    Ok(result) => {
      let controlled_bus = result.buses[1]
      assert_true(controlled_bus.q_generation_mvar <= 20.0 + 1.0e-6)
      assert_true(controlled_bus.voltage_magnitude_pu < 1.04)
    }
    Err(_) => fail("PV limit case should converge after conversion")
  }
  let limited_options = @gridflow.SolveOptions::new(
    max_iterations=2,
    enforce_q_limits=true,
  )
  match @gridflow.solve_power_flow(network, options=limited_options) {
    Err(@gridflow.DidNotConverge(iterations, _)) => assert_true(iterations > 2)
    Err(_) => fail("iteration limit should report non-convergence")
    Ok(_) => fail("the two-iteration PV and PQ limits should not converge")
  }
}

///|
test "out-of-service branches carry no solved flow" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(id=2, kind=@gridflow.PQ, p_load_mw=40.0),
    ],
    generators=[@gridflow.Generator::new(bus_id=1, p_mw=0.0)],
    branches=[
      @gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1),
      @gridflow.Branch::new(
        from_bus=1,
        to_bus=2,
        r_pu=0.01,
        x_pu=0.1,
        in_service=false,
      ),
    ],
  )
  match @gridflow.solve_power_flow(network) {
    Ok(result) => {
      assert_eq(result.branches.length(), 2)
      assert_eq(result.branches[1].p_from_mw, 0.0)
      assert_eq(result.branches[1].q_from_mvar, 0.0)
      assert_eq(result.branches[1].p_to_mw, 0.0)
      assert_eq(result.branches[1].q_to_mvar, 0.0)
      assert_eq(result.branches[1].p_loss_mw, 0.0)
    }
    Err(_) =>
      fail("parallel in-service branch should keep the network connected")
  }
}

///|
test "three-bus PV case solves with tap, phase shift, and shunts" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack, vm_pu=1.03),
      @gridflow.Bus::new(id=2, kind=@gridflow.PV, vm_pu=1.02),
      @gridflow.Bus::new(
        id=3,
        kind=@gridflow.PQ,
        p_load_mw=60.0,
        q_load_mvar=25.0,
        shunt_g_mw=1.0,
        shunt_b_mvar=2.0,
      ),
    ],
    generators=[
      @gridflow.Generator::new(bus_id=1, p_mw=0.0),
      @gridflow.Generator::new(bus_id=2, p_mw=20.0, v_set_pu=1.02),
    ],
    branches=[
      @gridflow.Branch::new(
        from_bus=1,
        to_bus=2,
        r_pu=0.02,
        x_pu=0.15,
        b_pu=0.03,
        tap_ratio=1.04,
        phase_shift_degree=8.0,
      ),
      @gridflow.Branch::new(
        from_bus=2,
        to_bus=3,
        r_pu=0.01,
        x_pu=0.1,
        b_pu=0.02,
      ),
      @gridflow.Branch::new(
        from_bus=1,
        to_bus=3,
        r_pu=0.04,
        x_pu=0.25,
        b_pu=0.01,
      ),
    ],
  )
  match @gridflow.solve_power_flow(network) {
    Ok(result) => {
      assert_true(result.max_mismatch_pu < 1.0e-8)
      assert_true(result.buses[1].voltage_magnitude_pu == 1.02)
      assert_true(result.branches[0].p_loss_mw > 0.0)
      let mut generation = 0.0
      let mut losses = 0.0
      for bus in result.buses {
        generation += bus.p_generation_mw
      }
      for branch in result.branches {
        losses += branch.p_loss_mw
      }
      let shunt_loss = result.buses[2].voltage_magnitude_pu *
        result.buses[2].voltage_magnitude_pu
      assert_true((generation - 60.0 - losses - shunt_loss).abs() < 1.0e-6)
    }
    Err(_) => fail("tap and phase-shifting case should converge")
  }
}

///|
test "non-finite Newton iterates never report a converged solution" {
  let network = @gridflow.Network::new(
    base_mva=100.0,
    buses=[
      @gridflow.Bus::new(id=1, kind=@gridflow.Slack),
      @gridflow.Bus::new(
        id=2,
        kind=@gridflow.PQ,
        p_load_mw=1.0e308,
        q_load_mvar=1.0e308,
      ),
    ],
    generators=[@gridflow.Generator::new(bus_id=1, p_mw=0.0)],
    branches=[@gridflow.Branch::new(from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1)],
  )
  assert_true(@gridflow.solve_power_flow(network) is Err(_))
}
