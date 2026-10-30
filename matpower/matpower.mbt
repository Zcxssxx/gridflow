///|
/// Syntax and data errors returned by the restricted MATPOWER case reader.
pub(all) enum ParseError {
  UnsupportedSyntax(Int32, String)
  InvalidNumber(Int32, String)
  InvalidRow(Int32, String)
  UnsupportedBusType(Int32, Int32)
  MissingBaseMva
  MissingMatrix(String)
  UnterminatedMatrix(Int32, String)
}

///|
fn whitespace_tokens(line : String) -> Array[String] {
  let whitespace = @string.Regex::unsafe_from_string("[[:space:]]+")
  whitespace
  .split(line)
  .map(fn(view) { view.to_owned() })
  .filter(fn(token) { !token.is_empty() })
  .collect()
}

///|
fn without_comment(line : String) -> String {
  line.split("%").to_array()[0].trim().to_owned()
}

///|
fn before_semicolon(value : String) -> String {
  value.split(";").to_array()[0].trim().to_owned()
}

///|
fn parse_number(
  token : String,
  line_number : Int32,
) -> Result[Double, ParseError] {
  try {
    let value = @string.parse_double(token)
    if value == value && value - value == 0.0 {
      Ok(value)
    } else {
      Err(InvalidNumber(line_number, token))
    }
  } catch {
    _ => Err(InvalidNumber(line_number, token))
  }
}

///|
fn parse_matrix_rows(
  content : String,
  line_number : Int32,
  rows : Array[Array[Double]],
) -> Result[Unit, ParseError] {
  let segments = content.split(";").to_array()
  for segment in segments {
    let row_text = segment.trim().to_owned()
    if !row_text.is_empty() {
      let tokens = whitespace_tokens(row_text)
      let values = []
      for token in tokens {
        match parse_number(token, line_number) {
          Ok(value) => values.push(value)
          Err(error) => return Err(error)
        }
      }
      if values.length() == 0 {
        return Err(InvalidRow(line_number, row_text))
      }
      rows.push(values)
    }
  }
  Ok(())
}

///|
fn integer_column(
  row : Array[Double],
  column : Int32,
  line_number : Int32,
) -> Result[Int32, ParseError] {
  let value = row[column]
  let integer = value.to_int()
  if integer.to_double() != value {
    Err(InvalidRow(line_number, "expected an integer-valued field"))
  } else {
    Ok(integer)
  }
}

///|
fn parse_bus_rows(
  rows : Array[Array[Double]],
) -> Result[Array[@gridflow.Bus], ParseError] {
  let buses = []
  for row_index in 0..<rows.length() {
    let row = rows[row_index]
    if row.length() < 13 {
      return Err(InvalidRow(row_index + 1, "bus row requires 13 columns"))
    }
    let bus_id = match integer_column(row, 0, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let bus_type = match integer_column(row, 1, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let kind = match bus_type {
      1 => @gridflow.PQ
      2 => @gridflow.PV
      3 => @gridflow.Slack
      _ => return Err(UnsupportedBusType(row_index + 1, bus_type))
    }
    buses.push(
      @gridflow.Bus::new(
        id=bus_id,
        kind~,
        p_load_mw=row[2],
        q_load_mvar=row[3],
        shunt_g_mw=row[4],
        shunt_b_mvar=row[5],
        vm_pu=row[7],
        va_degree=row[8],
      ),
    )
  }
  Ok(buses)
}

///|
fn parse_generator_rows(
  rows : Array[Array[Double]],
) -> Result[Array[@gridflow.Generator], ParseError] {
  let generators = []
  for row_index in 0..<rows.length() {
    let row = rows[row_index]
    if row.length() < 10 {
      return Err(InvalidRow(row_index + 1, "generator row requires 10 columns"))
    }
    let bus_id = match integer_column(row, 0, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let status = match integer_column(row, 7, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    generators.push(
      @gridflow.Generator::new(
        bus_id~,
        p_mw=row[1],
        q_mvar=row[2],
        q_min_mvar=row[4],
        q_max_mvar=row[3],
        v_set_pu=row[5],
        in_service=status > 0,
      ),
    )
  }
  Ok(generators)
}

///|
fn parse_branch_rows(
  rows : Array[Array[Double]],
) -> Result[Array[@gridflow.Branch], ParseError] {
  let branches = []
  for row_index in 0..<rows.length() {
    let row = rows[row_index]
    if row.length() < 11 {
      return Err(InvalidRow(row_index + 1, "branch row requires 11 columns"))
    }
    let from_bus = match integer_column(row, 0, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let to_bus = match integer_column(row, 1, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let status = match integer_column(row, 10, row_index + 1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let tap = if row[8] == 0.0 { 1.0 } else { row[8] }
    branches.push(
      @gridflow.Branch::new(
        from_bus~,
        to_bus~,
        r_pu=row[2],
        x_pu=row[3],
        b_pu=row[4],
        tap_ratio=tap,
        phase_shift_degree=row[9],
        in_service=status > 0,
      ),
    )
  }
  Ok(branches)
}

///|
/// Parse a safe subset of MATPOWER case M-files as data only.
/// Supported statements are a function header, version 2, baseMVA, and
/// numeric bus/gen/branch matrices. No MATLAB expression or function is run.
pub fn parse_case(source : String) -> Result[@gridflow.Network, ParseError] {
  let mut base_mva : Double? = None
  let mut bus_rows : Array[Array[Double]] = []
  let mut generator_rows : Array[Array[Double]] = []
  let mut branch_rows : Array[Array[Double]] = []
  let mut has_bus_matrix = false
  let mut has_generator_matrix = false
  let mut has_branch_matrix = false
  let mut current_matrix : String? = None
  let mut current_rows : Array[Array[Double]] = []
  let mut line_number = 0

  for original_line in source.split("\n") {
    line_number += 1
    let line = without_comment(original_line.to_owned())
    if line.is_empty() {
      continue
    }

    match current_matrix {
      Some(matrix_name) => {
        let close_parts = line.split("]").to_array()
        let matrix_content = close_parts[0].to_owned()
        match parse_matrix_rows(matrix_content, line_number, current_rows) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
        if close_parts.length() > 1 {
          let trailing = close_parts[1].trim().to_owned()
          if !trailing.is_empty() && trailing != ";" {
            return Err(UnsupportedSyntax(line_number, trailing))
          }
          match matrix_name {
            "bus" => {
              bus_rows = current_rows
              has_bus_matrix = true
            }
            "gen" => {
              generator_rows = current_rows
              has_generator_matrix = true
            }
            "branch" => {
              branch_rows = current_rows
              has_branch_matrix = true
            }
            "gencost" | "areas" => ()
            _ => return Err(UnsupportedSyntax(line_number, matrix_name))
          }
          current_matrix = None
          current_rows = []
        }
      }
      None =>
        if line.has_prefix("function ") {
          let tokens = whitespace_tokens(line)
          if tokens.length() != 4 || tokens[1] != "mpc" || tokens[2] != "=" {
            return Err(UnsupportedSyntax(line_number, line))
          }
        } else if line == "end" {
          ()
        } else if line.has_prefix("mpc.version") {
          let pieces = line.split("=").to_array()
          if pieces.length() != 2 || pieces[0].trim() != "mpc.version" {
            return Err(UnsupportedSyntax(line_number, line))
          }
          let version = before_semicolon(pieces[1].to_owned())
          if version != "'2'" && version != "2" {
            return Err(UnsupportedSyntax(line_number, line))
          }
        } else if line.has_prefix("mpc.baseMVA") {
          let pieces = line.split("=").to_array()
          if pieces.length() != 2 || pieces[0].trim() != "mpc.baseMVA" {
            return Err(UnsupportedSyntax(line_number, line))
          }
          match
            parse_number(before_semicolon(pieces[1].to_owned()), line_number) {
            Ok(value) => base_mva = Some(value)
            Err(error) => return Err(error)
          }
        } else if line.has_prefix("mpc.bus") ||
          line.has_prefix("mpc.gen") ||
          line.has_prefix("mpc.branch") ||
          line.has_prefix("mpc.gencost") ||
          line.has_prefix("mpc.areas") {
          let pieces = line.split("=").to_array()
          if pieces.length() != 2 || !pieces[1].trim().has_prefix("[") {
            return Err(UnsupportedSyntax(line_number, line))
          }
          let matrix_name = if pieces[0].trim() == "mpc.bus" {
            "bus"
          } else if pieces[0].trim() == "mpc.gen" {
            "gen"
          } else if pieces[0].trim() == "mpc.branch" {
            "branch"
          } else if pieces[0].trim() == "mpc.gencost" {
            "gencost"
          } else if pieces[0].trim() == "mpc.areas" {
            "areas"
          } else {
            return Err(UnsupportedSyntax(line_number, line))
          }
          current_matrix = Some(matrix_name)
          current_rows = []
          let open_parts = pieces[1].split("[").to_array()
          if open_parts.length() < 2 {
            return Err(UnsupportedSyntax(line_number, line))
          }
          let remainder = open_parts[1].to_owned()
          let close_parts = remainder.split("]").to_array()
          match
            parse_matrix_rows(
              close_parts[0].to_owned(),
              line_number,
              current_rows,
            ) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
          if close_parts.length() > 1 {
            let trailing = close_parts[1].trim().to_owned()
            if !trailing.is_empty() && trailing != ";" {
              return Err(UnsupportedSyntax(line_number, trailing))
            }
            match matrix_name {
              "bus" => {
                bus_rows = current_rows
                has_bus_matrix = true
              }
              "gen" => {
                generator_rows = current_rows
                has_generator_matrix = true
              }
              "branch" => {
                branch_rows = current_rows
                has_branch_matrix = true
              }
              "gencost" | "areas" => ()
              _ => return Err(UnsupportedSyntax(line_number, matrix_name))
            }
            current_matrix = None
            current_rows = []
          }
        } else {
          return Err(UnsupportedSyntax(line_number, line))
        }
    }
  }

  if current_matrix is Some(matrix_name) {
    return Err(UnterminatedMatrix(line_number, matrix_name))
  }
  let base_mva = match base_mva {
    Some(value) => value
    None => return Err(MissingBaseMva)
  }
  if !has_bus_matrix {
    return Err(MissingMatrix("bus"))
  }
  if !has_generator_matrix {
    return Err(MissingMatrix("gen"))
  }
  if !has_branch_matrix {
    return Err(MissingMatrix("branch"))
  }
  let buses = match parse_bus_rows(bus_rows) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let generators = match parse_generator_rows(generator_rows) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let branches = match parse_branch_rows(branch_rows) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(@gridflow.Network::new(base_mva~, buses~, generators~, branches~))
}
