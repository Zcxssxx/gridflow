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

No code or case data from the MATPOWER repository is included. The MATPOWER
project states that its case files are not automatically covered by its software
license; users must check the terms attached to any external case they choose to
load. The separate PGLib data license for GridFlow's included extracts is
recorded below.

## Bundled third-party case data

`testdata/pglib-opf-v23.07/` contains data-only extracts from three PGLib-OPF
v23.07 IEEE-derived typical-operations cases (14, 30, and 118 buses). The source
files attribute the underlying CDF conversion to Richard D. Christie,
University of Washington Electrical Engineering, and declare the case data
under CC BY 4.0. The source URLs, source and extracted-file SHA-256 hashes,
transformation, and limitations are recorded in that directory's README. Only
`version`, `baseMVA`, and unchanged numeric `bus`, `gen`, and `branch` matrices
are retained; no PGLib solver/tooling implementation code or OPF cost model
is copied.

The corresponding files under `references/` are numeric outputs from the
independent MIT-licensed `aartinian/powerflow` C# implementation, pinned to
commit `78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a`. Its project README reports
comparisons against MATPOWER `runpf` for five IEEE benchmark cases. No code from
that solver is bundled or used at runtime; the reference data preserve the
runner's published JSON precision. The test-data README describes the solver
options and comparison tolerances.

## Runtime and development dependencies

- moonbitlang/core is distributed with the MoonBit toolchain. Its package
  license is Apache-2.0.
- moonbitlang/x@0.5.6 is used by the CLI for file reading through
  moonbitlang/x/fs and a clean nonzero process exit through moonbitlang/x/sys.
  It is an external runtime dependency, is not vendored, and is licensed
  Apache-2.0. The solver library and MATPOWER parser do not depend on it.

No third-party solver implementation code is bundled in the repository. The
PGLib-derived `.m` fixtures retain the case-file wrapper and numeric matrix
assignments needed to identify and parse the licensed data extracts; their
upstream source, retained fields, transformation, and license are documented
above and in their accompanying notice. The synthetic test networks and
two-bus example are authored for this project, and the independently generated
reference outputs are identified above and in their accompanying notice.

## License

Project source and the synthetic example are licensed under Apache-2.0 by the
root LICENSE.
