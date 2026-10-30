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
- At the initial remote verification, `main` matched `ce21435fa963a1d4681e6ecb0dc7b249ada513e4`. The five commits then present were attributed to `Zcxssxx`; the contributor list contained only `Zcxssxx`.
- At the prior remote audit, CI run `40997983672` completed successfully on `ce21435`. An earlier run failed because a clean runner lacked the MoonBit registry index; adding `moon update` before checks fixed the issue and the follow-up run passed.
- Pushed the CLI error-handling changes as `d1a7d8ceeee632b2fdf989647d0cf3653e58be94`. At the post-push verification, remote `main` matched that SHA. The six commits then present listed `Zcxssxx` as GitHub author; the contributor list contained only `Zcxssxx`.
- Remote CI run `40999609952` completed successfully on `d1a7d8c`; WebAssembly and native Ubuntu, macOS, and Windows jobs passed. The Linux job also passed the missing-file stderr/exit-code integration check.
- Subsequently pushed the delivery-status documentation commit `787b2b427defd476b738914c29b1ce70274e2aa2`; at that verification, seven authentic commits were present and the latest CI run `40999922476` completed successfully on the then-current `main`.
- Current competition site and charter were checked. The site says October 31 is the registration/acceptance deadline; the charter table still says October 24. The supplementary Feishu page is specifically for the August hackathon and was not applied to the October round.
- Prepared `GridFlow-申报书.md` and `GridFlow-赛规核验.md` in the workspace parent, outside the public repository. The proposal leaves contact details for the participant to fill and does not claim external user interviews or IEEE benchmark validation.
- The proposal has not been submitted. The October form's remaining attempt count and accepted file format are not visible from the reviewed pages and must be checked before submission.
- The user's target of more than 10 meaningful commits has not been reached; six authentic commits are present. Continue only when substantive project work justifies new commits.

## Follow-up: PGLib reference coverage (2026-10-30)

- Reviewed the repository contributor rule before adding outside cases: each case needed exact source/version, transformation, redistribution terms, and an independent reference output.
- Added data-only extracts from PGLib-OPF v23.07 cases 14, 30, and 118. Numeric `bus`, `gen`, and `branch` matrices were compared with the three pinned raw files and matched exactly; source and LF-normalized fixture SHA-256 values are in `testdata/pglib-opf-v23.07/README.md`. No upstream full M-file or solver code is bundled.
- Generated references with the MIT-licensed C# solver at commit `78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a`, using flat start, Q-limits disabled, tolerance `1e-10`, and 50 maximum iterations. Reference output precision is recorded in each JSON file.
- Added `scripts/check-pglib-benchmarks.sh` and a Linux CI step. The script checks case hashes, convergence residual, bus/branch counts, every bus voltage and every branch end P/Q flow, and total active loss. Local Git Bash/jq run passed for all three cases.
- Cross-solver observed differences were below `5.0e-7 pu` for voltage magnitude, `5.0e-5 degree` for voltage angle, and `0.005 MW/MVAr` for branch flows; references are rounded to 6/4/2 decimals respectively.
- Enabling Q-limits is not part of the reference claim. The 118-bus outputs diverged in an exploratory comparison because the C# implementation supports PQ-to-PV recovery while GridFlow applies aggregate PV-to-PQ conversion without recovery; focused GridFlow unit tests continue to cover its documented mode.
- Local verification on Moon 0.1.20261028 / moonc 0.10.18: `moon fmt --check`; native `moon check --deny-warn`, `moon test --deny-warn` (22/22), `moon build`; wasm-gc equivalents (22/22); `moon info` and interface diff; `moon package --list`; two-bus text/JSON CLI; missing-file exit 2 without panic; three-case integration script. All passed.
- The proposal draft in the workspace parent now includes the licensed PGLib cases and independent cross-check, with limits stated explicitly. It remains local and has not been submitted.
- Remote update for this follow-up has not yet been pushed; identity confirmation and remote CI/file/history verification remain pending.
