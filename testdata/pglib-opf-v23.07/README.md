# PGLib-OPF v23.07 IEEE-derived fixtures

These files are data-only extracts of three public MATPOWER cases. They are included to exercise GridFlow's parser and AC power-flow calculations on networks larger than the self-authored examples.

## Attribution and license

The upstream case files identify the source as the IEEE Common Data Format cases converted by Richard D. Christie, University of Washington Electrical Engineering. They declare the case data licensed under [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/). PGLib-OPF v23.07's [license notice](https://github.com/power-grid-lib/pglib-opf/blob/v23.07/LICENSE) identifies the data license and provides the applicable attribution details.

PGLib-OPF is curated by the IEEE PES Task Force for AC optimal power-flow studies. Its [README](https://github.com/power-grid-lib/pglib-opf/blob/v23.07/README.md) cautions that applications outside its OPF problem variants require discretion. These files are PGLib **typical-operations** variants. In particular, dispatch, voltage setpoints, and operating assumptions have been altered from the originating records. They are not described here as unmodified canonical IEEE cases or as official IEEE reference operating points.

## Exact sources and transformations

The PGLib release tag `v23.07` is used for all inputs. Original SHA-256 hashes below were calculated from the downloaded raw files at those pinned URLs. The GridFlow case SHA-256 values identify the extracted files checked into this repository.

| Case | Original source | Original SHA-256 | GridFlow fixture SHA-256 |
|---|---|---|---|
| 14 bus | [pglib_opf_case14_ieee.m](https://raw.githubusercontent.com/power-grid-lib/pglib-opf/v23.07/pglib_opf_case14_ieee.m) | `bd5c568621de65e4b0922317010868bc7fa94173807faa10ea8fdbbe77c28106` | `4cb3bc6fd4c072e21bfeee791117403c8821717ba5f86fbf7325d2efedb5d2bb` |
| 30 bus | [pglib_opf_case30_ieee.m](https://raw.githubusercontent.com/power-grid-lib/pglib-opf/v23.07/pglib_opf_case30_ieee.m) | `cae3290639d989731d32428aacf30c0b918bc91db73bc54791f3aa62d3f76c70` | `4d38dc0383f0cab400e604ffe471a882ccc2c48b29fae5accac6a941b86f2ae1` |
| 118 bus | [pglib_opf_case118_ieee.m](https://raw.githubusercontent.com/power-grid-lib/pglib-opf/v23.07/pglib_opf_case118_ieee.m) | `b1af0833849040c04babc3700631cff0d9afa66b79c5d3e13ae79bdf516cec78` | `4f683bf16a648a0af1f1ae4e1d3a6a636123d16e2bf5fc249f8e25dfcce36ad5` |

Each fixture retains the upstream header and attribution, `mpc.version`, `mpc.baseMVA`, and the numeric `mpc.bus`, `mpc.gen`, and `mpc.branch` matrices. The matrix values and row order were checked against the pinned raw files and are unchanged. Generator cost functions, OPF metadata, and unrelated assignments/comments were omitted; a comment in each fixture records this extraction. No MATLAB code is executed or copied into GridFlow.

## Independent power-flow references

The files under `references/` contain bus voltages, both-end branch P/Q flows, and total active losses emitted by the independent [PowerFlow C# solver](https://github.com/aartinian/powerflow/tree/78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a) at commit `78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a`. Its [README](https://github.com/aartinian/powerflow/blob/78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a/README.md) reports validation against MATPOWER `runpf` on five IEEE benchmark cases. The repository reports an MIT license. No reference-solver source is included or required to build or run GridFlow.

Reference settings: flat start, Q-limit enforcement off, tolerance `1e-10 pu`, maximum 50 iterations. Its JSON output rounds voltage magnitudes to six decimals, angles to four decimals, and branch flows and total active loss to two decimals; the reference JSON retains exactly that precision. GridFlow is run with flat initial data, Q-limit enforcement off, tolerance `1e-10 pu`, and maximum 100 iterations. The integration script allows only the rounding differences documented above.

Q-limits are disabled deliberately so the comparison isolates the base AC power-flow solution. An exploratory comparison with Q-limits enabled differs on the 118-bus case: the pinned C# solver includes PQ-to-PV recovery, while GridFlow currently applies aggregate PV-to-PQ conversion without recovery. The large-case Q-limit behavior is therefore not claimed as independently cross-validated; GridFlow's Q-limit conversion remains covered by focused project tests.

Run the regression checks on Linux with:

```sh
bash scripts/check-pglib-benchmarks.sh
```

The PGLib published OPF objective values are not used as power-flow answers. Passing these tests establishes agreement with the pinned independent solver on these specific extracted inputs and options; it does not establish that the source case data are error-free or that these are canonical IEEE results.
