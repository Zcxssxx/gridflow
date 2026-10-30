# GridFlow progress

## 2026-10-30

- Implemented a MoonBit library and native CLI for balanced positive-sequence AC power flow: network validation, Ybus, polar Newton-Raphson, analytic Jacobian, pivoted dense solve, bus injections, branch terminal flows/losses, and optional generator-Q-limit conversion.
- Added a safe numeric MATPOWER subset reader. It treats case files as data and rejects unsupported statements rather than executing MATLAB code.
- Added the synthetic two-bus example, README, Apache-2.0 license, provenance/dependency notices, and CI for native Linux/macOS/Windows plus wasm-gc.
- Reproduced and fixed a PV-to-PQ iteration-count issue. Added finite-difference checks for the analytic Jacobian under phase shift and shunt conditions.
- Current local stable toolchain: Moon 0.1.20261028, moonc 0.10.18, moonrun 0.1.20261028.
- Latest local checks passed: `moon fmt --check`; native and wasm-gc `moon check --deny-warn`, `moon test --deny-warn` (22 tests per target), and `moon build`; `moon info` left all three generated interfaces unchanged; `moon package --list` succeeded. The native text example converged in four iterations and JSON output parsed with the expected two buses and one branch.
- Fixed the CLI error path after the missing-file run exposed a runtime panic trace. Errors now go to stderr with exit code 2; the native binary test confirmed empty stdout, a path-specific message, and no panic trace. Added a CLI unit test for missing files and tests for rejecting repeated `--max-iterations` / `--tolerance` flags.
- GitHub identity was verified using only `gh api user --jq .login`; it returned `Zcxssxx`. The public repository is `https://github.com/Zcxssxx/gridflow`, with `main` as its default branch and Apache-2.0 detected by GitHub.
- Remote `main` matches local commit `ce21435fa963a1d4681e6ecb0dc7b249ada513e4`. The five commits then present were attributed to `Zcxssxx`; the contributor list contained only `Zcxssxx`.
- At the prior remote audit, CI run `40997983672` completed successfully on `ce21435`. An earlier run failed because a clean runner lacked the MoonBit registry index; adding `moon update` before checks fixed the issue and the follow-up run passed. The CLI error-handling changes and their new CI integration check are validated locally and are pending push/remote CI verification.
- Current competition site and charter were checked. The site says October 31 is the registration/acceptance deadline; the charter table still says October 24. The supplementary Feishu page is specifically for the August hackathon and was not applied to the October round.
- Prepared `GridFlow-申报书.md` and `GridFlow-赛规核验.md` in the workspace parent, outside the public repository. The proposal leaves contact details for the participant to fill and does not claim external user interviews or IEEE benchmark validation.
- The proposal has not been submitted. The October form's remaining attempt count and accepted file format are not visible from the reviewed pages and must be checked before submission.
