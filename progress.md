# GridFlow progress

## 2026-10-30

- Selected balanced AC transmission power flow after screening MoonBit packages and adjacent repositories. Recorded mature alternatives and the limits of public IEEE/PSTCA case data.
- Created a separate gridflow/ module and local Git repo on main. No remote is configured yet.
- Implemented public network/result types, topology and numeric validation, Ybus with branch charging and complex transformer taps, polar Newton-Raphson, analytic Jacobian, pivoted dense solve, branch terminal powers/losses, and optional PV-to-PQ reactive limit handling.
- Implemented a safe MATPOWER numeric-matrix subset parser and native CLI with text and JSON output. The included examples/two_bus.m is synthetic and self-authored.
- Added README, MoonBit module metadata, Apache-2.0 root license, provenance/dependency notices, design specification, implementation plan, and CI for native targets on Linux/macOS/Windows plus WebAssembly.
- Fixed iteration-count reporting after a PV-to-PQ restart. The regression test failed with the old behavior and passed with the fix. Added a finite-difference Jacobian test with phase shift and shunts.
- Current toolchain: Moon 0.1.20261028 / moonc 0.10.18 / moonrun 0.1.20261028.
- Final local validation passed: moon fmt --check; native and wasm-gc moon check --deny-warn, moon test --deny-warn (20 passed, 0 failed each), and moon build; moon info left all 3 generated interfaces unchanged; the native text CLI converged in 4 iterations, JSON parsed with expected bus/branch counts, and missing-file input returned a path-specific nonzero diagnostic; moon package --list passed.
- Current gh identity check returned Zcxssxx. No token, prior login, or global Git identity was inspected.
- Next: set repository-local author/committer metadata, commit the complete tested baseline, then create/push and verify the remote. Also recheck current hackathon rules and prepare any required application material before calling the entry ready.