# Progress

Newest entries first. Each entry: what was built or fixed, measured numbers, what is open.

## Status

| Phase | Issue | State |
|---|---|---|
| P0 Bootstrap | #2 | in progress |
| P1 Runtime and toolchain | #3 | open |
| P2 HIP corpus and baselines | #4 | open |
| P3 ISA table and `mir` core | #5 | open |
| P4 Static safety | #6 | open |
| P5 Machine model | #7 | open |
| P6 Backend passes | #8 | open |
| P7 Agent interface | #9 | open |
| P8 High-level inputs and generators | #10 | open |
| P9 GEMM on MFMA | #11 | open |
| P10 Attention | #12 | open |
| P11 Agent campaigns and self-improvement | #13 | open |

## Log

### 2026-11-19 — P0 bootstrap
- Repo skeleton, design, roadmap, workflow skill, CI. Host: 8 × MI355X VF, ROCm 7.14.
- Feasibility: amdclang `-S` output for `gfx950` (code object v6) is the import format.
