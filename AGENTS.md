# GridFlow contributor guide

GridFlow is a MoonBit implementation of balanced positive-sequence AC power flow.

## Scope and modeling rules

- Keep the public library independent of file I/O. The native CLI owns filesystem access.
- The MATPOWER reader accepts only the documented data-only subset and must never evaluate M-file code.
- Keep unsupported network models and solver failures explicit. Do not return a partial or non-finite result as converged.
- Do not describe GridFlow as suitable for dispatch, protection, real-time control, or safety-critical grid operation.
- Do not add external benchmark cases until their exact source, version, transformation, independent reference result, and redistribution terms are documented.

## Local verification

Run formatting, strict checking, and tests on both declared backends:

- moon fmt --check
- moon check --deny-warn --target native
- moon test --deny-warn --target native
- moon build --target native
- moon check --deny-warn --target wasm-gc
- moon test --deny-warn --target wasm-gc
- moon build --target wasm-gc

Run moon info after public API changes and inspect every generated .mbti diff. The CLI example is:

    moon run --target native cmd/main -- --case examples/two_bus.m
