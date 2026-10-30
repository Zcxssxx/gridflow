# GridFlow task plan

- [x] Screen the power-flow topic for MoonBit overlap and record adjacent projects.
- [x] Document benchmark-source caveats and avoid redistributing unclear case data.
- [x] Create isolated MoonBit module and local Git repository.
- [x] Define the public network model, validation errors, and solver options.
- [x] Implement topology/numeric validation and tests.
- [x] Implement Ybus, polar Newton-Raphson, pivoted dense solve, branch flows, and PV Q-limit conversion.
- [x] Cross-check the analytic Jacobian against finite differences.
- [x] Implement a safe numeric MATPOWER subset parser and native CLI.
- [x] Add a self-authored two-bus example, API/CLI docs, provenance, and Apache-2.0 license.
- [x] Add native multi-OS and WebAssembly GitHub Actions checks.
- [x] Verify the package contents with moon package --list.
- [x] Validate native and wasm-gc on the latest locally installed stable MoonBit toolchain.
- [ ] Make truthful, attributable local commits; do not mechanically split work to inflate the count.
- [ ] Recheck the current hackathon rules and prepare any required application material for GridFlow.
- [ ] Create/push Zcxssxx/gridflow and independently verify remote files, branch, commit history, contributors, and CI.

## Current constraints

- Do not claim an IEEE/PSTCA reference benchmark: UW warns that several archived inputs are unvalidated or have questionable fields, and case-data licensing is separate from MATPOWER software licensing.
- No third-party case data or source code is included. External cases need a case-specific license check and an independent reference solution before they can become fixtures.
- The active GitHub CLI identity was checked after local validation and matched Zcxssxx. Git author settings must be scoped to this repository.
- Do not read GitHub tokens, other accounts, or global Git author configuration.