# Knowledge-base entries from `kda_step`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## All loads of a register-array batch in flight before the first wait

- **Verdict:** parity
- **Applies when:** Straight-line block where amdclang already issues most of a batch of global_load_dwordx4 before the first wait (here 10 of 16) with descending vmcnt waits, and the kernel streams each byte once (headroom about 1.0)
- **How:** Move the remaining loads (with their s_nop separators) above the first s_waitcnt, renumber the pipelined waits to vmcnt(N-1..0), add waits before the uses that the old vmcnt(0) covered; arithmetic untouched
- **Measured:** kda_step 9decbb45ae7a8d6b: 0.995x [0.983, 1.000], 60 pairs, bit-identical; loads-only probe had bounded it at about 1 us of 109
- **Session:** 2026-11-21 09:28

## One wave per workgroup to drop phase barriers, at the price of fragmented loads

- **Verdict:** loses
- **Applies when:** Multi-wave workgroup with barriers between a read phase and a write phase, where making the reduction wave-local changes the lane mapping so that one load instruction covers several short row fragments instead of one or two long ones
- **How:** Source: block 64, grid rows * column tiles; lane = (row part, column group) with 8 x 8 per wave, partials through LDS with no __syncthreads
- **Measured:** kda_step 20e9b76a6ac2301b: 0.662x [0.658, 0.666]; 8 fragments of 128 B per x4 load against 2 of 512 B; barriers were worth at most 2.5 us; 36 VGPR spills in the build
- **Session:** 2026-11-21 09:28

## Fewer registers per lane for occupancy on a memory-bound kernel

- **Verdict:** loses
- **Applies when:** features says limiter vgpr (4 waves/SIMD) and the kernel is at headroom about 1.0 with a large register-held tile per lane
- **How:** Source knobs: twice the row parts, half the rows per thread, block 512 (64 VGPRs, 8 waves/SIMD)
- **Measured:** kda_step c446eb9304aa0f8d: 0.939x [0.934, 0.946]; loads-only probe at <=80 VGPRs was 3 % faster than at 125 VGPRs
- **Session:** 2026-11-21 09:28

## Check which path the battery takes before trusting a pass

- **Verdict:** pays
- **Applies when:** Kernel with a shape-dependent fast path (condition on block size, divisibility or bounds) and battery shapes unlike the bench shapes
- **How:** Evaluate the fast-path condition for every shape in battery(); if none takes it, rely on equivalent(id, 'baseline'), which includes one bench-shape case, and report the gap
- **Measured:** kda_step: all 13 battery shape variants give ncg*8 > 256 or DV < 4, so 105 of 105 cases run the slow loop
- **Session:** 2026-11-21 09:28

## Main loads issued before a setup loop and its barrier

- **Verdict:** parity
- **Applies when:** A workgroup first fills LDS from small per-row inputs (a loop with its own global loads and a full wait), passes an s_barrier, and only then issues the large loads; the large loads' addresses do not depend on LDS; the kernel is at copy-model headroom about 1.0.
- **How:** Duplicate the address computation at kernel entry under the same scalar condition as the fast path, issue all global_load_dwordx4 there (address built in the destination registers), rename the setup loop's registers out of the destination range, add `s_waitcnt vmcnt(0)` before the barrier, delete the loads from the later phase and set its waits to vmcnt(15..0).
- **Measured:** kda_step, state 05b45e2d96e4cff3: 0.995 [0.992, 0.998] at 240 pairs, bit-identical to the baseline on 106 cases.
- **Session:** 2026-11-21 09:35

## Load address built in the load's own destination registers

- **Verdict:** parity
- **Applies when:** Many wide loads are kept in flight and address registers push the VGPR count toward an occupancy step.
- **How:** v_mad_u64_u32 v[T:T+1], s[tmp:tmp+1], v_row, s_stride, 0; v_lshl_add_u64 v[T:T+1], v[T:T+1], 2, v[base:base+1]; global_load_dwordx4 v[T:T+3], v[T:T+1], off. static_check asked for no extra wait state.
- **Measured:** kda_step, state 05b45e2d96e4cff3: legal and bit-identical; no timing effect by itself (VGPR count stayed 125 because phase 2 sets it).
- **Session:** 2026-11-21 09:35
