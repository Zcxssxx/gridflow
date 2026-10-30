///|
test "CLI parses a case path and output options" {
  match
    parse_cli_args([
      "gridflow", "--case", "examples/two_bus.m", "--json", "--enforce-q-limits",
      "--max-iterations", "35", "--tolerance", "1e-9",
    ]) {
    Ok(options) => {
      assert_eq(options.case_path, "examples/two_bus.m")
      assert_true(options.json_output)
      assert_true(options.solve_options.enforce_q_limits)
      assert_eq(options.solve_options.max_iterations, 35)
      assert_eq(options.solve_options.tolerance_pu, 1.0e-9)
    }
    Err(_) => fail("valid CLI arguments should parse")
  }
}

///|
test "CLI rejects missing case paths and unknown options" {
  assert_true(parse_cli_args(["gridflow", "--case"]) is Err(_))
  assert_true(
    parse_cli_args(["gridflow", "--case", "case.m", "--wat"]) is Err(_),
  )
}

///|
test "CLI returns a readable missing-file error" {
  let missing_path = "__gridflow_missing_cli_test_file__.m"
  match execute_cli(["gridflow", "--case", missing_path]) {
    Err(message) => assert_true(message.contains(missing_path))
    Ok(_) => fail("a missing case file must return an error")
  }
}

///|
test "CLI rejects repeated numeric options" {
  assert_true(
    parse_cli_args([
      "gridflow", "--case", "case.m", "--max-iterations", "5", "--max-iterations",
      "8",
    ])
    is Err(DuplicateOption("--max-iterations")),
  )
  assert_true(
    parse_cli_args([
      "gridflow", "--case", "case.m", "--tolerance", "1e-7", "--tolerance", "1e-9",
    ])
    is Err(DuplicateOption("--tolerance")),
  )
}
