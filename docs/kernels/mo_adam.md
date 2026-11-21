# `mo_adam`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 07:43

**Harness verdict:** win 1.020x (95% CI 1.018 to 1.021) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 2.05) on 50 cases

# mo_adam: ISA-level analysis

## Case
Memory floor, touch-once. With the manifest's scalars (amsgrad = 0, weight_decay = 0) each lane reads 4 dwords (grad, param, exp_avg, exp_avg_sq) and writes 3 (param, exp_avg, exp_avg_sq). At N = 2^26 that is 1074 MB read and 805 MB written. The cold-stream model gives 20 + 238 + 75 = 333 us; the baseline measures 333 to 342 us. `bench` reports headroom 0.70 only because its traffic model also counts the two max_exp_avg_sq streams and the inout stream that are never touched. 1.5x is not reachable without moving fewer bytes, and there are none to drop.

## What amdclang's code spends instructions on (baseline 479450ef1dc8ae54)
117 instructions, loop-free per element except two f64 square-and-multiply loops (8 instructions each, about 4 iterations for step = 10) that every wave runs before it loads anything. 5 scalar loads in 4 groups (two of them after the pow loops), 5 `global_load_dword`, 4 `global_store_dword`, 8 waits of which 5 wait for everything, 9 `v_lshl_add_u64` for addresses, 3 transcendentals (rsq, sqrt, rcp), 8 fma. The four data loads are issued only after the pow loops and the 64-byte `s_load_dwordx16`.

## Time split (probes, block 256, grid N/256)
| variant | time |
|---|---|
| full kernel | 335 us |
| no stores (reads + arithmetic) 55e3698da520ac43 | 205 us |
| no loads (arithmetic + stores) 8267de4110baa776 | 127 us |
| empty kernel, 2^20 waves 24c4ad9a6d17ec23 | 58 us |
| empty kernel, 2^20 waves at block 1024 36ee4e54b17b5dda | 58 us |
| empty kernel, 2^19 waves f679457deeb945f9 | 31 us |

205 + 127 = 332 us, so reads and stores add up to the whole time and the arithmetic is not visible. Launch is about 55 ns per wave and depends on waves, not workgroups; it overlaps with memory time in the full kernel (halving the waves did not help).

## Best state against amdclang (isa_diff baseline -> 5934ebefbb657d59)
Same launch, same 4 B per lane, same floating-point order (bit-identical to the baseline on 50 cases; within tolerance but not bit-identical to `ref`, as the -ffast-math baseline itself). 96 instructions against 117: salu -9, valu_select -4 (the `v_cndmask_b32` pair in each pow loop replaced by scalar branches), valu_move -4, branch -2, wait -2, waits-for-everything 5 -> 3. What matters is ordering, not count: all four `s_load_*` at entry under one `s_waitcnt lgkmcnt(0)`; the four `global_load_dword` issued right after the bounds mask, before the merged `.Lpow` loop, so they are in flight during it; store addresses computed before the first `vmcnt` wait; `global_store_dword` of exp_avg_sq and exp_avg issued before the `v_rcp_f32` chain.

## Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| loads in flight during prologue + merged pow + early stores | a few us of per-wave latency | 5934ebefbb657d59: 1.013 (1.010..1.015), 1.024 (1.019..1.028), 240 pairs each | marginal win |
| coarsen 2 | fewer waves | f603faea696460f6: 0.9956 (0.993..0.999), 240 pairs | parity |
| coarsen 4 / 8 (earlier session) | fewer waves | 0.9745 / 0.9805 | loss |
| block 64, one wave per workgroup | rb_scal recipe | f11a37d717ff6325: 0.900 (0.896..0.905) | loss |
| block 128 | | 086b9e267a1152d3: 0.951 (0.946..0.956) | loss |
| block 1024 | fewer workgroups | b15cc15332d14663: 0.943 (0.940..0.947), 240 pairs | loss |
| 8 B per lane dwordx2, mask-free fast path, hand-written | half the waves, 31 us less launch | 3d9384c894e2c324: 0.973 (0.968..0.977) | loss |
| two 256 B dword tiles per wave, 8 loads in flight | same, 4-line loads | d60e61e9ffff4811: 0.990 (0.985..0.998) | parity |
| source EPT=2 / EPT=4 (earlier session) | | 0.9775 / 0.9668 | loss |

## Untested
- A mask-free 4 B per lane fast path at block 256 with scalar base + 32-bit vector offset addressing (removes seven `v_lshl_add_u64` and the 64-bit compare). Not built: the probes show no measurable arithmetic share, so the expected gain is below 1 %.
- coarsen 2 on 5934 with the pow hoisted out of the tile loop, and the next tile's loads in flight before the current stores: plain coarsen 2 is parity here and the in-flight variant was parity on rb_axpy.
- Block 512 (between the 256 optimum and the 1024 loss).

### Tried

| what | outcome | speedup |
|---|---|---|
| Early kernarg loads, 4 loads in flight during pow, merged scalar-branched pow loop, 2 stores before the rcp chain (state from an earlier session, re-timed twice at 240 pairs) | win (marginal) | 1.0133 (CI 1.0101..1.0151) and 1.0235 (CI 1.0193..1.0275); earlier 60-pair run 1.0104 |
| coarsen factor 2 on the baseline, re-timed at 240 pairs (earlier 60-pair run said 1.026 win) | parity | 0.9956 (CI 0.9931..0.9989) |
| relaunch baseline code at block 64 (one wave per workgroup, grid N/64) | loss | 0.9003 (CI 0.8957..0.9045) |
| relaunch baseline code at block 128 (grid N/128) | loss | 0.9513 (CI 0.9455..0.9556) |
| relaunch of 5934 at block 1024 (grid N/1024), 240 pairs | loss | 0.9425 (CI 0.9399..0.9465) |
| hand-written 8 B per lane: 4 global_load_dwordx2 in flight during pow, mask-free fast path for full default-flag workgroups, 3 dwordx2 stores, generic masked loop for tail/flags; block 256, grid N/512 | loss | 0.9729 (CI 0.9675..0.9773) |
| same hand kernel but two adjacent 256 B tiles per wave as 8 dword loads (off / offset:256) and 6 dword stores, lane l owns elements l and l+64 | parity | 0.9902 (CI 0.9845..0.9978) |
| 8 B/lane hand kernel at block 1024 (created, not timed: both the 8 B/lane kind and block 1024 had already lost) | not timed | None |
| probe: baseline without the 3 stores | diagnostic 205 us | None |
| probe: baseline with constants instead of the loads | diagnostic 127 us | None |
| probe: empty kernel at block 256 grid N/256, block 1024 grid N/1024, block 256 grid N/512 | diagnostic 58 us / 58 us / 31 us | None |
| Earlier sessions (not repeated): coarsen 4 and 8, source EPT=2 and EPT=4, early loads only, early loads at block 1024 | loss / loss / loss / loss / parity / parity | 0.9745 / 0.9805 / 0.9775 / 0.9668 / 1.0087 / 1.0088 |

## Session 2026-11-21 07:52

**Harness verdict:** win 1.025x (95% CI 1.024 to 1.027) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 2.05) on 50 cases

# mo_adam: ISA-level analysis (session 2)

## Case
Memory floor, touch-once. With the manifest's scalars (amsgrad = 0, weight_decay = 0) each lane reads 4 dwords (grad, param, exp_avg, exp_avg_sq) and writes 3. At N = 2^26: 1074 MB read, 805 MB written; the cold-stream model gives 20 + 238 + 75 = 333 us, the baseline measures 333 to 336 us. `bench` reports headroom 0.70 only because its model also counts the three max_exp_avg_sq tensors that are never touched. 1.5x is not reachable without moving fewer bytes, and there are none to drop.

## Baseline mix (479450ef1dc8ae54)
117 instructions, loop-free per element apart from two f64 square-and-multiply loops (8 instructions each) run by every wave before any data load. 5 scalar loads, 5 global_load_dword (4 executed), 4 global_store_dword (3 executed), 8 waits (5 for everything), 9 v_lshl_add_u64, 3 transcendentals, 8 fma.

## Time split (probes of the earlier session, not repeated)
Full 335 us; no stores 205 us; no loads 127 us; empty kernel at 2^20 waves 58 us (overlaps with memory time). Reads + stores = the whole time; arithmetic not visible. This session confirms it directly: deleting all 64-bit address arithmetic and masking is parity (below).

## Best state against amdclang (5934ebefbb657d59)
Same launch, same bytes per lane, same FP order (bit-identical to the baseline; within tolerance of `ref`, 6 of 50 cases bit-identical, max rel diff 2.05 on a large_exponent case that the tolerance's cond term covers). 96 instructions against 117. What matters is order: four `s_load_*` at entry under one `s_waitcnt lgkmcnt(0)`; four `global_load_dword` right after the bounds mask, in flight during the merged `.Lpow` loop (scalar branches instead of `v_cndmask_b32` pairs); store addresses before the first vmcnt wait; `global_store_dword` of exp_avg_sq and exp_avg before the `v_rcp_f32` chain.

## Opportunities measured this session (all against baseline 479450ef1dc8ae54)
| what | expected | measured | verdict |
|---|---|---|---|
| 5934 re-timed | - | 1.0248 (1.0226..1.0263), 240 pairs | win, shipped |
| block 512 on 5934 | between 256 and 1024 | d9c24aeafd41853f: 1.0131 (1.0115..1.017), 60 pairs | below 5934 |
| coarsen 2 on 5934 | fewer waves | 7cc2bd44169aa08a: 1.0072 (1.0026..1.0119) | parity |
| mask-free fast path, scalar base + 32-bit offset addressing (-7 v_lshl_add_u64, -v_mad_u64_u32, -v_cmp_gt_u64, -2 cndmask, -max) | < 1 % (arithmetic invisible) | 3b3367d0fd053fc0: 1.0234 (1.0226..1.0249); compare vs 5934 0.9983 (0.9974..1.0003) | parity with 5934 |
| loads reordered g, v, m, p + pipelined weak waits vmcnt(2) x3 | earlier stores | 013c3c8b1022c950: 1.0184 (1.0167..1.0203), 240 pairs | no gain, slightly lower |
| coarsen 2 + fast path, 8 loads of two 1 KB-apart tiles in flight, pow once per wave | half the waves, shared prologue | eb5338064d46b05b: 0.9974 (0.9954..1.0004), 240 pairs | parity vs baseline, 2.5 % below 5934 |

Together with session 1 (block 64 / 128 / 1024, coarsen 2 / 4 / 8, 8 B per lane dwordx2, two adjacent tiles per wave, source EPT 2 / 4): every geometry other than 4 B per lane, block 256, one tile per wave is at or below the baseline; only the load/store ordering pays, by 2.5 %.

## Untested
- Nothing with an expected gain above noise. A different split of streams over waves (e.g. separate waves for the exp_avg_sq and exp_avg updates, which do not need param) would add waves without removing bytes; not built.
- Block sizes that are not a multiple of 64 (partial waves) were not tried; they add waves per byte.

### Tried

| what | outcome | speedup |
|---|---|---|
| 5934 (early kernargs, 4 loads in flight during merged scalar-branched pow, 2 stores before rcp chain) re-timed at 240 pairs against the current baseline | win | 1.0248 |
| relaunch 5934 at block 512, grid N/512 (8 waves per workgroup) | win vs baseline (60 pairs, CI 1.0115..1.017) but below 5934 | 1.0131 |
| coarsen factor 2 on 5934 | parity (CI 1.0026..1.0119, 60 pairs) | 1.0072 |
| mask-free fast path on 5934 for full workgroups with default flags: scalar base + 32-bit vector offset global_load/store, no v_lshl_add_u64 / v_mad_u64_u32 / 64-bit compare / cndmask / max; slow path unchanged | win vs baseline (CI 1.0226..1.0249, 240 pairs); parity vs 5934 by compare: 0.9983 (0.9974..1.0003) | 1.0234 |
| fast path with loads ordered g, v, m, p and pipelined weak waits (vmcnt(2) before each of es / ea / param, each store issued as soon as its inputs arrive) | win vs baseline (CI 1.0167..1.0203, 240 pairs), below 5934 | 1.0184 |
| coarsen 2 + hand fast path: both 1 KB-apart tiles' 8 dword loads in flight (offset:1024 on a single 32-bit offset register), pow computed once per wave, tile A computed+stored then tile B; grid N/512 block 256 | parity (CI 0.9954..1.0004, 240 pairs) | 0.9974 |
| fix_waits rewrite=true on 5934 | no change: nothing to repair, returns the parent | None |
