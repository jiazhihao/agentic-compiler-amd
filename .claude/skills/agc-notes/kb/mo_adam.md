# Knowledge-base entries from `mo_adam`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Loads in flight during a per-wave scalar prologue, stores issued as soon as their value exists

- **Verdict:** pays
- **Applies when:** Loop-free elementwise kernel at the memory floor whose amdclang code runs a wave-uniform prologue (here two f64 square-and-multiply loops for pow(beta, step)) and late kernarg loads before issuing its global loads, and issues all stores at the end
- **How:** edit_ir on the amdclang build: all s_load_* at entry under one s_waitcnt lgkmcnt(0); address computation and the global_load_dword group moved in front of the prologue loop; the two pow loops merged into one with scalar branches (s_bitcmp0_b32 / s_lshr_b32 + s_cbranch) instead of v_cndmask_b32; store addresses computed before the first vmcnt wait; each global_store_dword placed right after the instruction that produces its value; arithmetic order untouched
- **Measured:** mo_adam 5934ebefbb657d59: 1.0133 (CI 1.0101..1.0151) and 1.0235 (CI 1.0193..1.0275), 240 pairs each; bit-identical to the baseline
- **Session:** 2026-11-21 07:43

## coarsen 2 on a 7-stream elementwise kernel

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel, 4 B per lane, 4 read and 3 write streams, grid of 262144 workgroups, at the memory floor
- **How:** apply(baseline, 'coarsen', {'factor': 2})
- **Measured:** mo_adam f603faea696460f6: 0.9956 (CI 0.9931..0.9989) at 240 pairs; the 60-pair run had said 1.026. Factors 4 and 8: 0.9745 and 0.9805
- **Session:** 2026-11-21 07:43

## Waves per workgroup on a 7-stream elementwise kernel: 4 is the optimum

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel at the memory floor whose code takes the block size from the kernarg (relaunch is enough), 256 B per stream per wave
- **How:** relaunch with block 64 / 128 / 1024 and grid cdiv(N, block)
- **Measured:** mo_adam: block 64 f11a37d717ff6325 0.900 (0.896..0.905); block 128 086b9e267a1152d3 0.951 (0.946..0.956); block 1024 b15cc15332d14663 0.943 (0.940..0.947, 240 pairs)
- **Session:** 2026-11-21 07:43

## 8 B per lane (dwordx2) with a mask-free fast path on a many-stream kernel

- **Verdict:** loses
- **Applies when:** Elementwise touch-once kernel with 4 read and 3 write streams where amdclang moves 4 B per lane; idea is half the waves (31 us less wave launch)
- **How:** edit_ir, block 256, grid cdiv(N,512), index 2*(wg*block+tid); scalar test (wg+1)*block*2 <= N and default flags selects a path with 4 global_load_dwordx2 issued before the pow loop, one s_waitcnt vmcnt(0), arithmetic per component in the baseline's order, 3 global_store_dwordx2; otherwise a masked loop of 2 over the original dword body
- **Measured:** mo_adam 3d9384c894e2c324: 0.9729 (CI 0.9675..0.9773); amdclang's own EPT=2 source 0.9775
- **Session:** 2026-11-21 07:43

## Two dword tiles per wave instead of one dwordx2 per lane

- **Verdict:** parity
- **Applies when:** A wave has to cover 512 B per stream on a memory-floor kernel
- **How:** lane index = wave base + lane (subtract tid & 63 from 2*(wg*block+tid)), then global_load_dword at off and offset:256 into the two registers the dwordx2 pair used; stores likewise
- **Measured:** mo_adam d60e61e9ffff4811: 0.9902 (CI 0.9845..0.9978) against 0.9729 for the dwordx2 form of the same kernel; still below the 256 B per wave baseline
- **Session:** 2026-11-21 07:43

## Wave launch costs 55 ns per wave and overlaps with memory time

- **Verdict:** parity
- **Applies when:** Deciding whether fewer waves can pay on a memory-bound kernel
- **How:** edit_ir to a lone s_endpgm and probe at the candidate geometries
- **Measured:** mo_adam: 58 us for 2^20 waves at block 256 and at block 1024, 31 us for 2^19 waves; halving the waves in the real kernel changed the time by -2.7 % to -1 %, not +9 %
- **Session:** 2026-11-21 07:43

## Check the real traffic when headroom is below 1

- **Verdict:** parity
- **Applies when:** bench reports headroom well under 1.0 on a kernel with optional tensors (flags that disable a stream)
- **How:** count the global loads and stores actually executed for the manifest's scalars and recompute 20 us + read/4.5 TB/s + written/10.7 TB/s
- **Measured:** mo_adam: reported headroom 0.70 (6 read + 4 written tensors); real 4 read + 3 written gives 333 us against 335 us measured, headroom 1.0
- **Session:** 2026-11-21 07:43

## Loads in flight during a per-wave scalar prologue, stores before the transcendental chain

- **Verdict:** pays
- **Applies when:** Loop-free elementwise kernel whose every wave runs a prologue (kernarg s_loads in several groups, a small pow/setup loop) before issuing its global loads, and whose stores all sit after the last VALU
- **How:** Load all kernargs at entry under one s_waitcnt lgkmcnt(0); issue the global_load_dword right after the bounds mask, before the setup loop; merge the two f64 pow loops into one with scalar branches; compute store addresses before the first vmcnt wait; issue each global_store_dword as soon as its value exists (before v_rcp/v_sqrt of the last output). FP order unchanged.
- **Measured:** mo_adam 5934ebefbb657d59: 1.0248 (CI 1.0226..1.0263, 240 pairs) over the strongest amdclang build; earlier runs 1.013 and 1.024
- **Session:** 2026-11-21 07:52

## Mask-free fast path with scalar base + 32-bit vector offset addressing

- **Verdict:** parity
- **Applies when:** Memory-bound loop-free body with one v_lshl_add_u64 per stream, a v_mad_u64_u32 + v_cmp_gt_u64 bounds mask, and flag-dependent cndmask/max that are identities for the default flags
- **How:** Scalar test at entry (N < 2^29, wg_base + block <= N, flag bits zero), then v_add_u32 / v_lshlrev_b32 one offset register and `global_load_dword vD, vOff, s[base:base+1]` / `global_store_dword vOff, vS, s[base:base+1]`; original code kept as slow path
- **Measured:** mo_adam 3b3367d0fd053fc0 vs 5934: compare 0.9983 (CI 0.9974..1.0003, 240 pairs); 1.0234 vs baseline, all of it inherited
- **Session:** 2026-11-21 07:52

## Pipelined weak waits in a straight-line multi-stream body

- **Verdict:** parity
- **Applies when:** Loop-free body with 4 loads in flight and 3 stores whose inputs arrive at different times
- **How:** Order loads by first use (g, v, m, p); s_waitcnt vmcnt(2) before each output's arithmetic instead of vmcnt(3) + vmcnt(0), each store issued immediately
- **Measured:** mo_adam 013c3c8b1022c950: 1.0184 (CI 1.0167..1.0203) against 1.0234 for the same body with a full wait
- **Session:** 2026-11-21 07:52

## Block 512 for a 7-stream elementwise kernel

- **Verdict:** loses
- **Applies when:** 4 B per lane elementwise kernel, block 256 baseline, grid N/block
- **How:** relaunch(id, {grid: [cdiv(N, 512)], block: [512]})
- **Measured:** mo_adam d9c24aeafd41853f: 1.0131 (CI 1.0115..1.017) against 1.025 at block 256; block 64 0.90, 128 0.95, 1024 0.94
- **Session:** 2026-11-21 07:52

## coarsen 2 on a state that already has loads in flight during the prologue

- **Verdict:** parity
- **Applies when:** Loop-free tuned elementwise state at the memory floor (headroom about 1.0 on real traffic)
- **How:** apply(id, 'coarsen', {factor: 2})
- **Measured:** mo_adam 7cc2bd44169aa08a: 1.0072 (CI 1.0026..1.0119) against 1.025 for the parent
- **Session:** 2026-11-21 07:52

## Two tiles per wave, 8 loads in flight, shared per-wave prologue

- **Verdict:** loses
- **Applies when:** Coarsened elementwise kernel with a per-wave scalar prologue and 4 read + 3 write streams
- **How:** On the coarsen-2 state, a fast path before .Lagc_wg_head: one 32-bit offset register, loads at `off` and `offset:1024` for both tiles before the prologue, s_waitcnt vmcnt(4) for tile A, its 3 stores, vmcnt(3) for tile B, its stores; grid N/512, block 256
- **Measured:** mo_adam eb5338064d46b05b: 0.9974 (CI 0.9954..1.0004, 240 pairs) vs baseline; 2.5 % below the one-tile state
- **Session:** 2026-11-21 07:52
