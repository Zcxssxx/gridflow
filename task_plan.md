# GridFlow delivery plan

- [x] Screen the balanced AC power-flow topic against MoonBit packages and adjacent repositories; record the scope and overlap caveats.
- [x] Define the public network model, solver options, typed errors, and input validation.
- [x] Implement Ybus construction, polar Newton-Raphson, an analytic Jacobian, pivoted dense solve, branch flows, and optional PV reactive-limit conversion.
- [x] Cross-check the analytic Jacobian with finite differences and test PV-to-PQ iteration reporting.
- [x] Implement a safe numeric MATPOWER subset parser and native text/JSON CLI.
- [x] Return CLI failures as standard-error messages with exit code 2; reject repeated numeric options and cover both paths with tests.
- [x] Add a self-authored synthetic example, README, provenance notes, Apache-2.0 license, and multi-platform CI.
- [x] Validate native and wasm-gc on the current locally installed stable MoonBit toolchain; inspect generated interfaces and run both CLI success and failure cases.
- [x] Create and push the public repository as Zcxssxx/gridflow; verify its initial remote main branch, files, authorship, license, contributors, and CI.
- [x] Check current October hackathon rules and prepare a local Markdown proposal draft outside this repository.
- [x] Push the CLI error-handling changes and verify the resulting remote commit and CI run.
- [ ] Continue toward the user's target of more than 10 meaningful commits only through independently useful work; do not add commits solely to meet the count.
- [ ] Before submitting the entry, verify the participant's remaining October submission count and confirm the form's accepted document format with the organizer if needed.

## Current constraints

- The October event site states October 31, 2026 as the registration and acceptance deadline. The formal charter's schedule table still says October 24; treat the date discrepancy as requiring official confirmation.
- No IEEE/PSTCA benchmark results are claimed. No external case data is bundled because the archive/source terms and reference values need case-specific validation.
- The current test evidence uses self-authored networks, closed-form values, invariants, parser rejection cases, and finite-difference Jacobian checks.
- No Mooncakes publication requirement was found in the October event site or the reviewed charter sections; no package has been published.
- The user requested a natural development history. Do not create empty, backdated, misattributed, or mechanically split commits to reach a target count.
- The active GitHub CLI identity was checked immediately before remote verification and returned `Zcxssxx`. No token, prior login, or global Git author configuration was inspected.
