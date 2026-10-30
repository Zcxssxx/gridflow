# PGLib IEEE-derived power-flow regression fixtures Implementation Plan

> **For agentic workers:** Execute each task in order with its test-first check. Keep generated references traceable to the pinned external solver revision.

**Goal:** Add licensed IEEE-derived 14-, 30-, and 118-bus cases with independently generated AC power-flow reference values and continuous regression checks.

**Architecture:** Preserve only three original numeric MATPOWER matrices per case, with attribution and transformation notes. A small Bash/JQ integration script runs GridFlow's existing native CLI and compares bus voltages, branch flows, convergence residual, and losses against checked-in output from an independent C# solver.

**Tech Stack:** MoonBit CLI, Bash, jq, PGLib-OPF v23.07 data under CC BY 4.0, reference values generated with `aartinian/powerflow` revision `78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a`.

## Global Constraints

- Preserve numeric bus, generator, and branch matrix values and row order exactly from the pinned PGLib files.
- Attribute Richard D. Christie and University of Washington Electrical Engineering; document PGLib v23.07, source URLs, CC BY 4.0, and exact extraction changes.
- Describe these as PGLib OPF typical-operations variants; do not call them canonical IEEE reference operating points.
- Do not compare against PGLib OPF objective values as if they were power-flow outputs.
- Do not bundle third-party solver code or add it as a project dependency.
- Run native and wasm-gc MoonBit checks/tests/builds, and inspect generated interfaces for unintended differences.

---

### Task 1: Add a failing benchmark integration check

**Files:**
- Create: `scripts/check-pglib-benchmarks.sh`
- Test: run the script before adding its input data

**Interfaces:**
- Consumes: `moon run --target native cmd/main -- --case PATH --json --tolerance 1e-10 --max-iterations 100`.
- Produces: a nonzero exit with a clear missing-fixture message until Task 2 adds all inputs; after Task 2, zero only when every result agrees with its independent reference.

- [ ] Write the script to iterate over exactly `case14_ieee`, `case30_ieee`, and `case118_ieee`, with expected counts `(14,20)`, `(30,41)`, `(118,186)` and matching reference JSON filenames.
- [ ] Before any fixture files existed, run `bash scripts/check-pglib-benchmarks.sh`; it failed at the expected missing `case14_ieee.m` input.
- [ ] Keep the assertion thresholds in `docs/superpowers/specs/2026-10-30-pglib-ieee-regressions.md` and use the same values in the script: voltage magnitude `<1e-6`, angle `<1e-4`, branch P/Q `<0.006`, total loss `<0.01`, residual `<1e-8`; verify case fixture SHA-256 values in the same script.

### Task 2: Add attributed cases and independent reference JSON

**Files:**
- Create: `testdata/pglib-opf-v23.07/case14_ieee.m`
- Create: `testdata/pglib-opf-v23.07/case30_ieee.m`
- Create: `testdata/pglib-opf-v23.07/case118_ieee.m`
- Create: `testdata/pglib-opf-v23.07/references/case14_ieee.json`
- Create: `testdata/pglib-opf-v23.07/references/case30_ieee.json`
- Create: `testdata/pglib-opf-v23.07/references/case118_ieee.json`
- Create: `testdata/pglib-opf-v23.07/README.md`
- Modify: `scripts/check-pglib-benchmarks.sh`

**Interfaces:**
- Case files use only the syntax already accepted by `matpower.parse_case`.
- Reference JSON stores bus rows (`bus_id`, `vm_pu`, `va_degree`), branch rows (`from_bus`, `to_bus`, both-end P/Q), solver identity/options, and total active losses.

- [ ] Extract version, base MVA, and the three numeric matrices without changing any values or row order; retain upstream attribution and document removed fields.
- [ ] Record source URLs and SHA-256 hashes for original and derived case files; record the CC BY 4.0 source declaration.
- [ ] Generate reference values with the pinned C# runner, `--no-limits --flat-start --tol 1e-10 --max-iter 50 --output json`; normalize without increasing its reported precision.
- [ ] Run the benchmark script; all three cases pass and the script checks every bus and branch flow, not only aggregate counts.

### Task 3: Integrate the regression check and document limitations

**Files:**
- Modify: `.github/workflows/test.yml`
- Modify: `README.md`
- Modify: `PROVENANCE.md`
- Modify: `task_plan.md`
- Modify: `progress.md`

**Interfaces:**
- Linux native CI runs the benchmark script after the existing CLI smoke tests; native cross-platform and wasm-gc build/test jobs remain unchanged.
- README names the case sizes, comparison evidence, and PGLib-specific caveat.
- Provenance identifies both data and reference-result sources without implying endorsement or a canonical IEEE solution.

- [ ] Add a Linux-only CI step running `bash scripts/check-pglib-benchmarks.sh`.
- [ ] Document the exact validation claim and its scope in README and provenance notes.
- [ ] Run formatting, strict native and wasm-gc checks/tests/builds, `moon info`, interface-diff check, examples, CLI benchmark integration, source/fixture hash verification, and reference-result comparisons.
- [ ] Review the final diff for accidental upstream full-case files, unrelated generated output, and license/attribution omissions.
