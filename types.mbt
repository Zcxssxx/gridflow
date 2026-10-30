///|
/// Bus role in a positive-sequence AC power-flow model.
pub(all) enum BusKind {
  /// Both active and reactive injections are specified.
  PQ
  /// Active injection and voltage magnitude are specified.
  PV
  /// Voltage magnitude and angle are fixed; injections are solved.
  Slack
}

///|
pub(all) struct Bus {
  id : Int32
  kind : BusKind
  p_load_mw : Double
  q_load_mvar : Double
  shunt_g_mw : Double
  shunt_b_mvar : Double
  vm_pu : Double
  va_degree : Double
}

///|
pub fn Bus::new(
  id~ : Int32,
  kind~ : BusKind,
  p_load_mw~ : Double = 0.0,
  q_load_mvar~ : Double = 0.0,
  shunt_g_mw~ : Double = 0.0,
  shunt_b_mvar~ : Double = 0.0,
  vm_pu~ : Double = 1.0,
  va_degree~ : Double = 0.0,
) -> Bus {
  {
    id,
    kind,
    p_load_mw,
    q_load_mvar,
    shunt_g_mw,
    shunt_b_mvar,
    vm_pu,
    va_degree,
  }
}

///|
pub(all) struct Generator {
  bus_id : Int32
  p_mw : Double
  q_mvar : Double
  q_min_mvar : Double
  q_max_mvar : Double
  v_set_pu : Double
  in_service : Bool
}

///|
pub fn Generator::new(
  bus_id~ : Int32,
  p_mw~ : Double,
  q_mvar~ : Double = 0.0,
  q_min_mvar~ : Double = -1.0e9,
  q_max_mvar~ : Double = 1.0e9,
  v_set_pu~ : Double = 1.0,
  in_service~ : Bool = true,
) -> Generator {
  { bus_id, p_mw, q_mvar, q_min_mvar, q_max_mvar, v_set_pu, in_service, }
}

///|
pub(all) struct Branch {
  from_bus : Int32
  to_bus : Int32
  r_pu : Double
  x_pu : Double
  b_pu : Double
  tap_ratio : Double
  phase_shift_degree : Double
  in_service : Bool
}

///|
pub fn Branch::new(
  from_bus~ : Int32,
  to_bus~ : Int32,
  r_pu~ : Double,
  x_pu~ : Double,
  b_pu~ : Double = 0.0,
  tap_ratio~ : Double = 1.0,
  phase_shift_degree~ : Double = 0.0,
  in_service~ : Bool = true,
) -> Branch {
  {
    from_bus,
    to_bus,
    r_pu,
    x_pu,
    b_pu,
    tap_ratio,
    phase_shift_degree,
    in_service,
  }
}

///|
pub(all) struct Network {
  base_mva : Double
  buses : Array[Bus]
  generators : Array[Generator]
  branches : Array[Branch]
}

///|
pub fn Network::new(
  base_mva~ : Double,
  buses~ : Array[Bus],
  generators~ : Array[Generator],
  branches~ : Array[Branch],
) -> Network {
  { base_mva, buses, generators, branches, }
}

///|
pub(all) enum NetworkValidationError {
  EmptyNetwork
  InvalidBaseMva
  DuplicateBusId(Int32)
  InvalidBusData(Int32)
  MissingSlackBus
  MultipleSlackBuses
  UnknownGeneratorBus(Int32)
  InvalidGeneratorData(Int32)
  InvalidGeneratorReactiveLimits(Int32)
  UnknownBranchBus(Int32)
  BranchLoop(Int32)
  InvalidBranchImpedance(Int32, Int32)
  InvalidTapRatio(Int32, Int32)
  MissingGeneratorAtControlledBus(Int32)
  IsolatedBus(Int32)
}

///|
pub(all) enum PowerFlowError {
  InvalidNetwork(NetworkValidationError)
  InvalidOptions
  SingularJacobian(Int32)
  NonFiniteCalculation(Int32)
  DidNotConverge(Int32, Double)
}

///|
pub(all) struct SolveOptions {
  tolerance_pu : Double
  max_iterations : Int32
  enforce_q_limits : Bool
}

///|
pub fn SolveOptions::new(
  tolerance_pu~ : Double = 1.0e-8,
  max_iterations~ : Int32 = 20,
  enforce_q_limits~ : Bool = false,
) -> SolveOptions {
  { tolerance_pu, max_iterations, enforce_q_limits, }
}

///|
pub fn SolveOptions::default() -> SolveOptions {
  SolveOptions::new()
}

///|
pub(all) struct BusResult {
  bus_id : Int32
  voltage_magnitude_pu : Double
  voltage_angle_degree : Double
  p_generation_mw : Double
  q_generation_mvar : Double
  p_injection_mw : Double
  q_injection_mvar : Double
}

///|
pub(all) struct BranchResult {
  from_bus : Int32
  to_bus : Int32
  in_service : Bool
  p_from_mw : Double
  q_from_mvar : Double
  p_to_mw : Double
  q_to_mvar : Double
  p_loss_mw : Double
  q_loss_mvar : Double
}

///|
pub(all) struct PowerFlowResult {
  buses : Array[BusResult]
  branches : Array[BranchResult]
  iterations : Int32
  max_mismatch_pu : Double
}
