# Progress

Newest entries first. Each entry: what was built or fixed, measured numbers, what is open.

## Status

| Milestone | Issue | State |
|---|---|---|
| M0 Bootstrap | #2 | PR #14 open |
| M1 Measure: runtime, battery, timing | #3 | in progress |
| M2 Corpus and amdclang baselines | #4 | open |
| M3 Own the assembly: ISA table and `mir` | #5 | open |
| M4 Static safety | #6 | open |
| M5 The agent loop on assembly | #9 | open |
| M6 Tensor programs in, binaries out | #10 | open |
| M7 GEMM on MFMA | #11 | open |
| M8 Backend passes for imported code | #8 | open |
| M9 Campaigns and report | #13 | open |
| Stretch: machine-model calibration, attention | #7, #12 | not scheduled |

## Log

### 2026-11-19 — Roadmap revision
- Reordered into milestones M0 to M9 with measurable exits: agent loop (M5) before
  automatic passes (M8), generators (M6, M7) before passes; interpreter, standalone
  calibration, attention, FP8, profiler and recipe promotion moved to stretch.

### 2026-11-19 — P0 bootstrap
- Repo skeleton, design, roadmap, workflow skill, CI. Host: 8 × MI355X VF, ROCm 7.14.
- Feasibility: amdclang `-S` output for `gfx950` (code object v6) is the import format.
