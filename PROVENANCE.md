# Provenance and third-party notices

## Project code and included example

GridFlow source code, tests, documentation, and examples/two_bus.m were written
for this repository. The two-bus teaching case is synthetic and is not copied
from MATPOWER, IEEE, UW PSTCA, or another dataset.

The equations are implemented from the standard positive-sequence AC
power-flow model. MATPOWER documentation is used as a convention reference for
bus types, branch charging, off-nominal taps, and phase shifts:

- [MATPOWER runpf reference](https://matpower.org/docs/ref/matpower7.1/lib/runpf.html)
- [MATPOWER case format](https://matpower.org/documentation/ref-manual/legacy/functions/caseformat.html)

No MATPOWER source code or case data is included. The MATPOWER project states
that its case files are not automatically covered by its software license; users
must check the terms attached to any external case they choose to load.

## Runtime and development dependencies

- moonbitlang/core is distributed with the MoonBit toolchain. Its package
  license is Apache-2.0.
- moonbitlang/x@0.5.6 is used by the CLI for file reading through
  moonbitlang/x/fs and a clean nonzero process exit through moonbitlang/x/sys.
  It is an external runtime dependency, is not vendored, and is licensed
  Apache-2.0. The solver library and MATPOWER parser do not depend on it.

There are no copied third-party code snippets or third-party test datasets in
the repository. All test networks are written in the project tests.

## License

Project source and the synthetic example are licensed under Apache-2.0 by the
root LICENSE.
