///|
enum CliArgsError {
  MissingCase
  MissingValue(String)
  DuplicateOption(String)
  UnknownOption(String)
  InvalidValue(String)
}

///|
struct CliOptions {
  case_path : String
  json_output : Bool
  solve_options : @gridflow.SolveOptions
}

///|
fn parse_cli_args(args : Array[String]) -> Result[CliOptions, CliArgsError] {
  let mut case_path : String? = None
  let mut json_output = false
  let mut enforce_q_limits = false
  let mut max_iterations = 20
  let mut tolerance_pu = 1.0e-8
  let mut index = 1
  while index < args.length() {
    let argument = args[index]
    match argument {
      "--case" => {
        if case_path is Some(_) {
          return Err(DuplicateOption(argument))
        }
        if index + 1 >= args.length() {
          return Err(MissingValue(argument))
        }
        case_path = Some(args[index + 1])
        index += 2
      }
      "--json" => {
        if json_output {
          return Err(DuplicateOption(argument))
        }
        json_output = true
        index += 1
      }
      "--enforce-q-limits" => {
        if enforce_q_limits {
          return Err(DuplicateOption(argument))
        }
        enforce_q_limits = true
        index += 1
      }
      "--max-iterations" => {
        if index + 1 >= args.length() {
          return Err(MissingValue(argument))
        }
        match
          (Ok(@string.parse_int(args[index + 1])) catch {
            _ => Err(InvalidValue(argument))
          }) {
          Ok(value) => {
            if value <= 0 {
              return Err(InvalidValue(argument))
            }
            max_iterations = value
          }
          Err(error) => return Err(error)
        }
        index += 2
      }
      "--tolerance" => {
        if index + 1 >= args.length() {
          return Err(MissingValue(argument))
        }
        match
          (Ok(@string.parse_double(args[index + 1])) catch {
            _ => Err(InvalidValue(argument))
          }) {
          Ok(value) => {
            if !(value == value && value - value == 0.0 && value > 0.0) {
              return Err(InvalidValue(argument))
            }
            tolerance_pu = value
          }
          Err(error) => return Err(error)
        }
        index += 2
      }
      _ => return Err(UnknownOption(argument))
    }
  }
  let case_path = match case_path {
    Some(path) => path
    None => return Err(MissingCase)
  }
  let solve_options = @gridflow.SolveOptions::new(
    tolerance_pu~,
    max_iterations~,
    enforce_q_limits~,
  )
  Ok({ case_path, json_output, solve_options, })
}

///|
fn cli_args_error_message(error : CliArgsError) -> String {
  match error {
    MissingCase => "missing required --case PATH argument"
    MissingValue(option) => "missing value after \{option}"
    DuplicateOption(option) => "option supplied more than once: \{option}"
    UnknownOption(option) => "unknown option: \{option}"
    InvalidValue(option) => "invalid value for \{option}"
  }
}

///|
fn parse_error_message(error : @matpower.ParseError) -> String {
  match error {
    @matpower.UnsupportedSyntax(line, syntax) =>
      "unsupported syntax at line \{line}: \{syntax}"
    @matpower.InvalidNumber(line, token) =>
      "invalid number at line \{line}: \{token}"
    @matpower.InvalidRow(row, message) =>
      "invalid matrix row \{row}: \{message}"
    @matpower.UnsupportedBusType(row, bus_type) =>
      "unsupported bus type \{bus_type} in bus row \{row}"
    @matpower.MissingBaseMva => "missing mpc.baseMVA assignment"
    @matpower.MissingMatrix(name) => "missing mpc.\{name} matrix"
    @matpower.UnterminatedMatrix(line, name) =>
      "unterminated mpc.\{name} matrix at line \{line}"
  }
}

///|
fn solver_error_message(error : @gridflow.PowerFlowError) -> String {
  match error {
    @gridflow.InvalidNetwork(_) => "network validation failed"
    @gridflow.InvalidOptions => "invalid solver options"
    @gridflow.SingularJacobian(column) =>
      "Newton Jacobian is singular at pivot \{column}"
    @gridflow.NonFiniteCalculation(iterations) =>
      "non-finite numerical value during Newton iteration \{iterations}"
    @gridflow.DidNotConverge(iterations, mismatch) =>
      "power flow did not converge after \{iterations} iterations; residual \{mismatch} pu"
  }
}

///|
fn text_report(result : @gridflow.PowerFlowResult) -> String {
  let mut report = "Converged in \{result.iterations} Newton iterations; max mismatch \{result.max_mismatch_pu} pu\n\n"
  report += "BUS RESULTS\n"
  report += "bus_id\tvm_pu\tva_degree\tpg_mw\tqg_mvar\n"
  for bus in result.buses {
    report += "\{bus.bus_id}\t\{bus.voltage_magnitude_pu}\t\{bus.voltage_angle_degree}\t\{bus.p_generation_mw}\t\{bus.q_generation_mvar}\n"
  }
  report += "\nBRANCH FLOWS\n"
  report += "from\tto\tstatus\tp_from_mw\tq_from_mvar\tp_to_mw\tq_to_mvar\tp_loss_mw\n"
  for branch in result.branches {
    let status = if branch.in_service { "in" } else { "out" }
    report += "\{branch.from_bus}\t\{branch.to_bus}\t\{status}\t\{branch.p_from_mw}\t\{branch.q_from_mvar}\t\{branch.p_to_mw}\t\{branch.q_to_mvar}\t\{branch.p_loss_mw}\n"
  }
  report
}

///|
fn json_report(result : @gridflow.PowerFlowResult) -> String {
  let bus_values = result.buses.map(fn(bus) {
    "{\"bus_id\":\{bus.bus_id},\"vm_pu\":\{bus.voltage_magnitude_pu},\"va_degree\":\{bus.voltage_angle_degree},\"pg_mw\":\{bus.p_generation_mw},\"qg_mvar\":\{bus.q_generation_mvar},\"p_injection_mw\":\{bus.p_injection_mw},\"q_injection_mvar\":\{bus.q_injection_mvar}}"
  })
  let branch_values = result.branches.map(fn(branch) {
    let status = if branch.in_service { "true" } else { "false" }
    "{\"from_bus\":\{branch.from_bus},\"to_bus\":\{branch.to_bus},\"in_service\":\{status},\"p_from_mw\":\{branch.p_from_mw},\"q_from_mvar\":\{branch.q_from_mvar},\"p_to_mw\":\{branch.p_to_mw},\"q_to_mvar\":\{branch.q_to_mvar},\"p_loss_mw\":\{branch.p_loss_mw},\"q_loss_mvar\":\{branch.q_loss_mvar}}"
  })
  "{\"converged\":true,\"iterations\":\{result.iterations},\"max_mismatch_pu\":\{result.max_mismatch_pu},\"buses\":[\{bus_values.join(",")}],\"branches\":[\{branch_values.join(",")}]}"
}

///|
fn usage() -> String {
  "Usage: gridflow --case FILE [--json] [--enforce-q-limits] [--max-iterations N] [--tolerance PU]"
}

///|
fn main raise {
  let args = @env.args()
  if args.contains("--help") {
    println(usage())
    return
  }
  let options = match parse_cli_args(args) {
    Ok(options) => options
    Err(error) => raise Failure("\{cli_args_error_message(error)}\n\{usage()}")
  }
  let source = @fs.read_file_to_string(options.case_path) catch {
    @fs.IOError::IOError(message) =>
      raise Failure("cannot read case file '\{options.case_path}': \{message}")
  }
  let network = match @matpower.parse_case(source) {
    Ok(network) => network
    Err(error) => raise Failure(parse_error_message(error))
  }
  let result = match
    @gridflow.solve_power_flow(network, options=options.solve_options) {
    Ok(result) => result
    Err(error) => raise Failure(solver_error_message(error))
  }
  if options.json_output {
    println(json_report(result))
  } else {
    println(text_report(result))
  }
}
