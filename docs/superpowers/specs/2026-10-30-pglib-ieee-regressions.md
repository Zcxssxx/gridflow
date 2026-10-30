# PGLib IEEE-derived power-flow regression fixtures

Date: 2026-10-30

## Goal

Add reproducible 14-, 30-, and 118-bus AC power-flow cases to exercise GridFlow's MATPOWER reader, Newton solver, voltage results, and branch-flow calculations on non-synthetic networks.

## Data and legal basis

- Source: IEEE-derived cases in PGLib-OPF release v23.07, pinned by tag and exact source URLs for each case.
- Copyright/attribution in the upstream files: Richard D. Christie, University of Washington Electrical Engineering; original CDF conversion notes are retained in the case headers.
- Redistribution terms: CC BY 4.0 for the case data, as declared by the source files and PGLib `LICENSE`.
- Transformation: retain `mpc.version`, `mpc.baseMVA`, and the numeric `mpc.bus`, `mpc.gen`, and `mpc.branch` matrices unchanged; remove OPF objective/cost data, derived metadata, and unrelated comments. Add a note identifying this extraction. No row values, ordering, or units are edited.
- These are PGLib typical-operations variants prepared for AC optimal power flow. They are not represented as untouched canonical IEEE cases or as official IEEE reference operating points.

## Independent reference

Reference voltages and branch flows are produced by `aartinian/powerflow` at commit `78a7b1a5e4bd4fee35c66b2a2354ae18682e6a7a`, an independently implemented C# AC Newton-Raphson solver whose README reports comparisons against MATPOWER `runpf` on IEEE benchmark cases. It is used only to generate reference values; no code from it is included.

Reference run settings: flat start; reactive-limit enforcement disabled; tolerance `1e-10 pu`; maximum 50 iterations. The runner's JSON reports voltage magnitude to 6 decimal places, voltage angle to 4 decimal places, and branch flows/losses to 2 decimal places. The checked-in references preserve those outputs and record the solver revision and options.

Reactive limits are disabled in this cross-check. An exploratory enabled-limit run differs on case118 because the reference solver includes PQ-to-PV recovery while GridFlow currently performs aggregate PV-to-PQ conversion without recovery. The large-case limit-enforcement mode is outside this regression's claim.

## Acceptance checks

For each case, CI must run the checked-in case through GridFlow's native CLI and verify:

- convergence with residual below `1e-8 pu`;
- expected bus and branch counts;
- positive bus voltage magnitudes;
- every bus voltage magnitude within `1e-6 pu` and angle within `1e-4 degree` of the independent reference;
- both-end active and reactive branch flows within `0.006 MW/MVAr` of the independent reference (which is rounded to cents);
- total active branch losses within `0.01 MW` of the independent system-balance result.

These checks validate agreement on the fixed operating point. PGLib's published OPF objective values are not used as power-flow references, and this test does not claim comparison against an IEEE canonical solution.

## Scope limits

This addition does not expand the solver model or MATPOWER syntax. It does not enable reactive-limit enforcement, perform OPF, or establish that the source cases are error-free. No PGLib code is copied. The separate reference solver is not a runtime or build dependency.
