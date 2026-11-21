# Knowledge-base entries from `fi_fused_add_rmsnorm`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Fused add + RMSNorm row kernel with x already in LDS: at the memory floor, ship amdclang

- **Verdict:** parity
- **Applies when:** one workgroup per row, 16 B per lane x4 loads of two cold streams, a store of the sum, LDS copy of the sum reused in the second pass (no global re-read), headroom <= 1.0
- **How:** Check headroom and two probes (delete both global_store_dwordx4; delete reduction+barriers). If stores are ~5 % and the reduction ~0, stop: wait moves, fast paths, DPP and geometry all measured parity or loss.
- **Measured:** fi_fused_add_rmsnorm B=8192 d=4096: baseline 99 us, headroom 0.94-1.0; probes: no stores 94.0 us, no reduction 104 us (within drift); best candidate 0.996
- **Session:** 2026-11-21 07:58

## Registers instead of LDS for the second-pass operand + cache-resident weight load in the cold batch

- **Verdict:** loses
- **Applies when:** one-round row kernel where amdclang does ds_write_b128 of the first-pass value and ds_read_b128 after the barrier, and loads a small weight table after the reduction
- **How:** pk_add results into v[24:27], skip ds_write when rounds<2 (s_cmp_lt_u32 + s_cbranch_scc1), issue global_load_dwordx4 weight before the two cold loads with one vmcnt(0), straight-line masked tail (v_cmp_gt_u32 / s_and_b64 exec / s_cbranch_execz, 6 v_pk ops, store, s_endpgm); fallback to the original loops for rounds>=2.
- **Measured:** fi_fused_add_rmsnorm 476049448c07e917: 0.983 [0.981, 0.987], 240 pairs (bit-identical arithmetic)
- **Session:** 2026-11-21 07:58

## Deferring the first-pass store until after the barrier

- **Verdict:** loses
- **Applies when:** row kernel that loads, stores an intermediate result (residual = input + residual), reduces across waves, then stores a second output
- **How:** Keep the value in registers and issue both global_store_dwordx4 in the tail; put two independent VALU between the store and the first overwrite of its data registers (valu_overwrites_wide_store_data needs 2 wait states).
- **Measured:** fi_fused_add_rmsnorm 1c1a5fc7fe68d593: 0.975 [0.972, 0.980] at 240 pairs vs 0.983 with the store in place; a 60-pair run had read 1.011
- **Session:** 2026-11-21 07:58

## DPP wave reduction + one barrier instead of ds_bpermute tree + two barriers (16-wave workgroup)

- **Verdict:** parity
- **Applies when:** amdclang's shfl_xor reduction (5 ds_bpermute_b32 per level, lane-0 ds_write, barrier, second level in warp 0, barrier) in a kernel whose waves wait on cold loads
- **How:** Zero inactive lanes (s_not_b64 exec / v_mov 0 / exec=-1), 4 v_add_f32_dpp, v_readlane at 0/16/32/48 + 3 v_add; exec=1 ds_write_b32 to slot wave_id*4; one s_barrier; every lane reads slot (lane&15) masked by lane&15 < nwaves, 4 DPP steps, v_readfirstlane; fix_hazards.
- **Measured:** fi_fused_add_rmsnorm 74570e5fc032471b: 0.978 [0.973, 0.981] vs parent 0.975 [0.972, 0.980]: no effect
- **Session:** 2026-11-21 07:58

## Smaller workgroups (512 / 256 threads, multi-round) for a two-input-stream row kernel

- **Verdict:** parity
- **Applies when:** FlashInfer-style norm kernel whose thread loop handles rounds = ceil(d / (4 * threads)); block size is a launch knob
- **How:** relaunch(baseline, block [32, cdiv(min(512, D4), 32), 1], lds formula with the same min). Note the battery shapes only run rounds = 1.
- **Measured:** fi_fused_add_rmsnorm: 512 threads 0.995 [0.986, 1.005]; 256 threads 0.886 [0.883, 0.892] (fi_rmsnorm with one input stream had 1.05x at 512)
- **Session:** 2026-11-21 07:58

## Wait at a loop head moved to the back edge so a cached load is not queued behind a store

- **Verdict:** parity
- **Applies when:** second-pass loop begins with s_waitcnt vmcnt(0) that, on first entry, only waits for the first pass's store
- **How:** Delete the wait at the loop head and insert it in a new block after the loop's s_cbranch_scc1 (back edge only); the wait before the load's first use stays.
- **Measured:** fi_fused_add_rmsnorm bddaafee349b6298: 0.996 [0.977, 1.012], 60 pairs
- **Session:** 2026-11-21 07:58

## coarsen on top of a hand-written fast path with an early s_endpgm under a masked EXEC

- **Verdict:** loses
- **Applies when:** state with several exits, some leaving EXEC masked
- **How:** apply coarsen: the pass saves EXEC at entry (s_mov_b64 s[24:25], exec) and restores it per virtual workgroup, and rewrites every s_endpgm into a branch to its latch, so masked exits are safe.
- **Measured:** fi_fused_add_rmsnorm b65a4937d1c0a91a: battery 77/77, 0.970 [0.965, 0.974] at 240 pairs
- **Session:** 2026-11-21 07:58

## Two rounds' loads in flight on a half-size workgroup (2 KB per wave) loses at the memory floor

- **Verdict:** loses
- **Applies when:** Row kernel launched with 1024 threads per row and one x4 load per lane per stream (1 KB contiguous per wave), headroom about 1.0; the idea is fewer waves per workgroup with each thread loading two strided 16-byte vectors before one wait
- **How:** Source: block (32, cdiv(min(512, D4), 32)); loop i += 2 with both rounds' input/residual vec loads issued under their masks before the arithmetic; same in the second pass. amdclang keeps the 4 x4 loads in flight
- **Measured:** fi_fused_add_rmsnorm 6d6e3ad0: 0.961 [0.956, 0.969], 240 pairs (plain 512-thread relaunch with a wait per round: 0.995, 60 pairs)
- **Session:** 2026-11-21 08:01

## coarsen on a 16-wave LDS/barrier row kernel at the floor

- **Verdict:** parity
- **Applies when:** One workgroup per row, 1024 threads, two barriers, headroom about 1.0, grid of several thousand workgroups
- **How:** apply(baseline, 'coarsen', {factor: 2 | 8}), bench with pairs=240
- **Measured:** fi_fused_add_rmsnorm: factor 2 1.006 [1.001, 1.012]; factor 8 0.952 [0.949, 0.954] (60-pair runs had said 1.015/0.985 and 1.010/0.941)
- **Session:** 2026-11-21 08:01
