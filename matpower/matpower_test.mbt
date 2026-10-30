///|
test "safe MATPOWER subset parses a two-bus case" {
  let source =
    #|function mpc = case_two_bus
    #|mpc.version = '2';
    #|mpc.baseMVA = 100;
    #|mpc.bus = [
    #|1 3 0 0 0 0 1 1 0 230 1 1.1 0.9;
    #|2 1 100 50 0 0 1 1 0 230 1 1.1 0.9;
    #|];
    #|mpc.gen = [
    #|1 0 0 300 -300 1 100 1 300 0;
    #|];
    #|mpc.branch = [
    #|1 2 0.01 0.1 0 0 0 0 0 0 1 -360 360;
    #|];
    #|end
  match @matpower.parse_case(source) {
    Ok(network) => {
      assert_eq(network.base_mva, 100.0)
      assert_eq(network.buses.length(), 2)
      assert_eq(network.generators.length(), 1)
      assert_eq(network.branches.length(), 1)
      assert_true(@gridflow.validate_network(network) is Ok(_))
    }
    Err(_) => fail("valid numeric case statements should parse")
  }
}

///|
test "safe MATPOWER subset rejects executable statements" {
  let source =
    #|function mpc = case_bad
    #|mpc.baseMVA = 100;
    #|system('erase important-file');
    #|end
  match @matpower.parse_case(source) {
    Err(@matpower.UnsupportedSyntax(_)) => ()
    _ => fail("function calls must never be interpreted or ignored")
  }
}

///|
test "safe MATPOWER subset requires exact field assignments" {
  let source =
    #|function mpc = case_bad_field
    #|mpc.baseMVAevil = 100;
    #|mpc.bus = [];
    #|mpc.gen = [];
    #|mpc.branch = [];
    #|end
  match @matpower.parse_case(source) {
    Err(@matpower.UnsupportedSyntax(_)) => ()
    _ => fail("field names that only share a prefix must be rejected")
  }
}

///|
test "safe MATPOWER subset accepts ignored numeric cost matrices" {
  let source =
    #|function mpc = case_with_cost
    #|mpc.version = '2';
    #|mpc.baseMVA = 100;
    #|mpc.bus = [
    #|1 3 0 0 0 0 1 1 0 230 1 1.1 0.9;
    #|2 1 10 5 0 0 1 1 0 230 1 1.1 0.9;
    #|];
    #|mpc.gen = [
    #|1 10 0 300 -300 1 100 1 300 0;
    #|];
    #|mpc.branch = [
    #|1 2 0.01 0.1 0 0 0 0 0 0 1;
    #|];
    #|mpc.gencost = [
    #|2 0 0 3 0.01 1 0;
    #|];
    #|end
  match @matpower.parse_case(source) {
    Ok(network) => assert_eq(network.buses.length(), 2)
    Err(_) => fail("numeric generator cost matrix should be safely ignored")
  }
}
