#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

check_case() {
  local name="$1"
  local expected_buses="$2"
  local expected_branches="$3"
  local expected_sha256="$4"
  local case_file="testdata/pglib-opf-v23.07/${name}.m"
  local reference_file="testdata/pglib-opf-v23.07/references/${name}.json"

  if [[ ! -f "$case_file" ]]; then
    printf 'missing PGLib case file: %s\n' "$case_file" >&2
    return 1
  fi
  if [[ ! -f "$reference_file" ]]; then
    printf 'missing independent reference file: %s\n' "$reference_file" >&2
    return 1
  fi
  if ! printf '%s  %s\n' "$expected_sha256" "$case_file" | sha256sum --check --status; then
    printf 'fixture SHA-256 mismatch: %s\n' "$case_file" >&2
    return 1
  fi

  local result
  result="$(moon run --target native cmd/main -- --case "$case_file" --json --max-iterations 100 --tolerance 1e-10)"
  printf '%s\n' "$result" | jq -e \
    --argjson expected_buses "$expected_buses" \
    --argjson expected_branches "$expected_branches" \
    --slurpfile reference "$reference_file" \
    '
      . as $actual
      | $reference[0] as $expected
      | if ($actual.buses | length) != $expected_buses
          or ($actual.branches | length) != $expected_branches
          or ($expected.buses | length) != $expected_buses
          or ($expected.branches | length) != $expected_branches
        then false
        else
          ([range(0; $expected_buses) as $i |
            {
              bus_id_matches: ($actual.buses[$i].bus_id == $expected.buses[$i].bus_id),
              vm_matches: (((($actual.buses[$i].vm_pu - $expected.buses[$i].vm_pu) | abs) < 0.000001)),
              va_matches: (((($actual.buses[$i].va_degree - $expected.buses[$i].va_degree) | abs) < 0.0001))
            }
          ]) as $bus_checks
          | ([range(0; $expected_branches) as $i |
            {
              endpoints_match: (
                $actual.branches[$i].from_bus == $expected.branches[$i].from_bus
                and $actual.branches[$i].to_bus == $expected.branches[$i].to_bus
              ),
              p_from_matches: (((($actual.branches[$i].p_from_mw - $expected.branches[$i].p_from_mw) | abs) < 0.006)),
              q_from_matches: (((($actual.branches[$i].q_from_mvar - $expected.branches[$i].q_from_mvar) | abs) < 0.006)),
              p_to_matches: (((($actual.branches[$i].p_to_mw - $expected.branches[$i].p_to_mw) | abs) < 0.006)),
              q_to_matches: (((($actual.branches[$i].q_to_mvar - $expected.branches[$i].q_to_mvar) | abs) < 0.006))
            }
          ]) as $branch_checks
          | $actual.converged == true
          and $expected.converged == true
          and $actual.max_mismatch_pu < 1e-8
          and all($actual.buses[]; .vm_pu > 0)
          and all($bus_checks[]; .bus_id_matches and .vm_matches and .va_matches)
          and all($branch_checks[]; .endpoints_match and .p_from_matches and .q_from_matches and .p_to_matches and .q_to_matches)
          and ((([$actual.branches[].p_loss_mw] | add) - $expected.total_active_losses_mw) | abs) < 0.01
        end
    ' > /dev/null

  printf '%s: converged; %s buses, %s branches; reference voltages, P/Q flows, and losses match\n' \
    "$name" "$expected_buses" "$expected_branches"
}

check_case case14_ieee 14 20 4cb3bc6fd4c072e21bfeee791117403c8821717ba5f86fbf7325d2efedb5d2bb
check_case case30_ieee 30 41 4d38dc0383f0cab400e604ffe471a882ccc2c48b29fae5accac6a941b86f2ae1
check_case case118_ieee 118 186 4f683bf16a648a0af1f1ae4e1d3a6a636123d16e2bf5fc249f8e25dfcce36ad5
