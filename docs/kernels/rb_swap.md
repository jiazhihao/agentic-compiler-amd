# `rb_swap`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 05:56

**Harness verdict:** fallback: the session named no state faster than the baseline

## rb_swap: ISA-level analysis

**Case:** memory floor, touch-once. Each element of x and y is read once and written once (536.9 MB read, 536.9 MB written at N = 2^26). Baseline 180 us in its fast mode (5.97 TB/s, headroom 0.95), 195-199 us in its slow mode (headroom 1.04-1.06). 1.5x is not reachable; no bytes can be saved in a swap.

### amdclang's code (36 instructions, loop-free, block 256, grid cdiv(N,512))
Per wave: `s_load_dword` + `s_load_dwordx4` (n, x, y), one `s_waitcnt lgkmcnt(0)`, lane index `v_lshl_or_b32`, 64-bit `v_cmp_gt_i64` + `s_and_saveexec_b64`, two `v_lshl_add_u64` addresses, two `global_load_dwordx2` (8 B per lane, 512 B per wave per stream), `s_waitcnt vmcnt(1)`, `global_store_dwordx2` to y, `s_waitcnt vmcnt(1)`, `global_store_dwordx2` to x; then a second saveexec region for the odd tail element (dword load/store pair), taken by one lane of one wave. Waits are already pipelined (vmcnt(1), not 0); the loads are already wide and both in flight. There is no loop, no LDS, no arithmetic.

### Time split (probes on the hand-written twin A, c584821cb31c13da)
| variant | median | above launch |
|---|---|---|
| empty fast path (708c77e406e35ce0) | 30.8 us | - |
| stores only (96cda36c4a53e3e8) | 81.9 us | 51 us |
| loads only (bc1dcbfe53e62774) | 132.3 us | 101 us |
| full kernel | 180 us | 149 us |

31 + 51 + 101 = 183 us: launch plus memory accounts for all of it. Loads 5.3 TB/s, stores 10.5 TB/s: the device's cold-read and write rates.

### Opportunities and what they measured (all 240 pairs, against baseline)
| what | expected | state | speedup (CI) | reference_ms | verdict |
|---|---|---|---|---|---|
| A: fewer instructions, no masks, scalar-base addressing, same geometry | <= 1 % (no VALU time in the split) | c584821cb31c13da | 1.0022 (0.9995..1.005) | 180.4 | parity |
| B: two tiles per wave 2 KB apart, half the workgroups (hand coarsen 2) | up to 15 us of launch | 522364198a9d1729 | 0.9575 (0.952..0.961) | 180.0 | loss |
| D: B + next tile's loads in flight | latency of second tile | 37911d49d9787da9 | 0.9693 (0.966..0.974) | 180.4 | loss |
| C: one wave per workgroup, 1 KB per wave, 4 loads in flight (rb_scal recipe) | 1.12x on scal | 06907dae9df9cfe5 | 0.9529 (0.950..0.955) | 180.7 | loss |
| F: 16 B per lane (dwordx4), 1 KB per wave | fewer waves | 2c9e0169434b4aff | 0.9703 (0.965..0.974) | 181.2 | loss |
| E: block 128, grid cdiv(N,256), 512 B per wave | geometry | 184b78d512949827 | 1.093 / 0.995 / 1.097 / 0.973 | 197.7 / 180.6 / 198.9 / 179.5 | parity to loss in the baseline's fast mode; candidate 180.7-183.9 us in all runs |
| H: E with one merged wait | 0 | 877d62c8bd36c8ed | 1.0017 vs E (0.999..1.004) | - | parity |
| I: block 128, two tiles per wave 1 KB apart | geometry | f658dc1fad22b214 | 0.9812 (0.978..0.986) | 180.6 | loss |
| coarsen 2 (earlier best) re-timed | launch | d271da3154283301 | 1.0445, 1.0464 | 197.1, 194.8 | slow-mode win only; candidate 187-188.5 us > 180 us |

### isa_diff baseline -> E (184b78d512949827, bit-identical on 50 cases)
E has no `v_lshl_add_u64` (valu_add_sub -2), no `v_mov`/`v_lshlrev_b64` (64-bit index), no `s_and_saveexec_b64` on the fast path, 6 VGPRs instead of 12; it adds 3 SALU (`s_lshl_b32`/`s_lshr_b32`/`s_add_u32`/`s_addc_u32` for the per-workgroup base) and addresses memory as `global_load_dwordx2 v[2:3], v0, s[4:5]`. Its tail path uses dword loads/stores under a cumulative exec mask (vector_load_4B +2, vector_store_4B +2). Block 128 instead of 256. None of this changes the time.

### The measurement problem
The baseline's time is bimodal per bench invocation (about 180 us or 197 us). Candidates at other geometries do not follow it (E 181-184 us, coarsen 2 187-188.5 us, B 188.5 us), so a paired speedup of an unchanged candidate swings by up to 10 %. Judged against the baseline's fast mode, nothing beats amdclang's build.

### Untested
Block 512/1024 (needs a source state with a larger launch bound; earlier block-1024 edit failed the check), 2D grids, reversed traversal and stream order (parity on rb_axpy), far-apart streams per wave and software prefetch (losses on rb_axpy). None addresses anything in the split: the kernel's 149 us above launch is the two cold reads and two writes.

### Tried

| what | outcome | speedup |
|---|---|---|
| A: hand-written body at amdclang's geometry (block 256, grid cdiv(N,512)): scalar base + 32-bit vector offset loads/stores, scalar full-workgroup compare to a mask-free path, dword two-step masked tail | parity | 1.0022 |
| B: two sequential 512 B tiles per wave 2048 B apart, block 256, grid cdiv(N,1024), hoisted (hand-written coarsen 2) | loss | 0.9575 |
| C: one wave per workgroup, block 64, grid cdiv(N,256), 1 KB contiguous per wave per stream, 4 dwordx2 loads in flight, vmcnt(2) pipelined (rb_scal recipe) | loss | 0.9529 |
| D: B with the second tile's loads in flight before the first tile's stores | loss | 0.9693 |
| F: 16 B per lane (global_load/store_dwordx4), block 256, grid cdiv(N,1024) | loss | 0.9703 |
| E: A at block 128, grid cdiv(N,256) (two waves per workgroup, 512 B per wave); four 240-pair runs 1.093 / 0.995 / 1.097 / 0.973, lower taken | loss (mode-dependent: win only when the baseline runs at 198 us) | 0.9729 |
| H: E with one merged wait (both loads, vmcnt(0), both stores) compared directly against E | parity vs E (compare 1.0017, CI 0.999..1.004); not benched against baseline | 1.0017 |
| I: block 128, grid cdiv(N,512), two sequential 512 B tiles per wave 1024 B apart | loss | 0.9812 |
| coarsen factor 2 (earlier session's tagged best), re-timed twice at 240 pairs: 1.0445 and 1.0464, both with the baseline at 195-197 us; candidate 187-188.5 us, i.e. slower than the baseline's 180 us mode | win in the paired runs, not robust (baseline slow mode) | 1.0445 |
| probes on A: loads only 132 us, stores only 82 us, empty fast path 31 us | diagnostic | None |
| earlier sessions (not repeated): coarsen 4 0.878, coarsen 8 0.860, block 64 grid cdiv(N,128) 0.964, source 16 B per lane 0.9445, block 1024 failed check | loss | None |

## Session 2026-11-21 06:00

**Harness verdict:** fallback: the session named no state faster than the baseline

## rb_swap: ISA-level analysis (session 2)

**Case:** memory floor, touch-once. x and y are each read once and written once (536.9 MB read, 536.9 MB written at N = 2^26). Baseline 178-180 us in its fast mode (6.0 TB/s, headroom 0.94-0.95), 193-202 us in its slow mode (headroom 1.02-1.07). 1.5x is out of reach: a swap cannot move fewer bytes.

### amdclang's code and the split (unchanged from session 1)
36 instructions, loop-free: scalar arg loads, one `s_waitcnt lgkmcnt(0)`, 64-bit lane index compare + `s_and_saveexec_b64`, two `v_lshl_add_u64`, two `global_load_dwordx2` in flight, `s_waitcnt vmcnt(1)` / `global_store_dwordx2` twice, plus a one-lane odd-tail region. Session 1's probes: launch 31 us, stores 51 us, loads 101 us = 183 us; no ALU, wait or LDS time to remove.

### What this session measured (kinds left untested by session 1)
| what | expected | state | speedup (CI), pairs | candidate / reference us | verdict |
|---|---|---|---|---|---|
| source, block 512, grid cdiv(N,1024) | fewer workgroups, same waves | 9b7179c706ad2972 | 0.962 (0.952..0.970), 60 | 202.4 / 194.8 | loss |
| source, block 1024, grid cdiv(N,2048) | same | 17b8efbb67b72614 | 1.011 (1.007..1.017), 60 | 190.2 / 193.2 | parity (slow-mode run; above the 180 us fast mode) |
| J: hand-written mask-free scalar-base body at block 1024 | <= launch share | 1c360c132130ac8b | 0.984 (0.981..0.988), 240 | 197.4 / 194.3 | loss |
| K: 2D grid (256, cdiv(N,131072)), tile = y*256 + x, hand body | dispatch order | f43156d133ed139d | 0.9993 (0.996..1.003), 240 | 179.6 / 179.6 | parity |
| L: load y then x, store x then y | 0 | b3474645d7f2202a | 1.0022 (0.998..1.006), 240 | 201.1 / 201.9 | parity |
| M: reversed traversal (tile G-1-i) | 0 | cf6dd1fe3524ab4e | 0.9973 (0.995..0.999), 240 | 178.3 / 177.8 | parity |

### ISA differences of the hand-written variants against amdclang
Same as session 1's A/E: no `v_lshl_add_u64`, no 64-bit `v_cmp_gt_i64`, no `s_and_saveexec_b64` on the full-workgroup path; `global_load_dwordx2 v[2:3], v0, s[4:5]` with a per-workgroup scalar base built by `s_lshl_b32`/`s_add_u32`/`s_addc_u32`; 6 VGPRs instead of 12. K adds `s_lshl_b32 s9, s3, 8` / `s_add_u32 s9, s9, s2`; M adds 4 SALU after the kernarg wait. None changes the time: the kernel's time is two cold reads and two writes.

### Measurement note
The slow/fast mode is per bench invocation and, at the baseline's geometry, hits both code objects alike (L 201 vs 202 us; K, M 178-180 vs 178-180 us). Only the paired ratio at 240 pairs is trustworthy; a 60-pair ratio of a different geometry against a slow-mode baseline is not.

### Untested
Nothing of a new kind remains that addresses the split. Over two sessions: bytes per lane (4/8/16), bytes per wave (512 B / 1 KB / 2 tiles), waves per workgroup (1, 2, 4, 8, 16), coarsen 2/4/8, loads in flight, merged waits, mask-free path, 2D grid, stream order, traversal order: all parity or loss against amdclang's fast mode.

### Tried

| what | outcome | speedup |
|---|---|---|
| source: block 512, grid cdiv(N,1024), same 8 B per lane (amdclang body, launch bound 512) | loss (60 pairs, CI 0.952..0.970; candidate 202.4 us vs 194.8 us) | 0.962 |
| source: block 1024, grid cdiv(N,2048), same 8 B per lane | parity (60 pairs, CI 1.007..1.017, baseline in slow mode 193 us, candidate 190 us; not above the 180 us fast mode) | 1.0111 |
| J: hand-written mask-free scalar-base body on the block-1024 source build (16 waves per workgroup) | loss (240 pairs, CI 0.981..0.988; 197.4 us vs 194.3 us) | 0.9836 |
| J via relaunch of the ref-derived state to block 1024 | check refused: hipModuleLaunchKernel 719 (launch bound 256 in the imported descriptor) | None |
| K: hand-written body on a 2D grid (256, cdiv(N,131072)), tile = y*256 + x, block 256 (built on a 2D source state so that s3 is enabled) | parity (240 pairs, CI 0.996..1.003; 179.6 us vs 179.6 us) | 0.9993 |
| L: stream order reversed (load y then x, store x then y) on the hand-written body A | parity (240 pairs, CI 0.998..1.006; 201.1 vs 201.9 us, slow mode) | 1.0022 |
| M: reversed traversal (workgroup i takes tile G-1-i, G = (n+511)>>9) on A | parity (240 pairs, CI 0.995..0.999; 178.3 vs 177.8 us) | 0.9973 |
| 2D source build as compiled by amdclang (parent of K) | not timed (only used as descriptor carrier for K) | None |
