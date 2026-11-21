# Knowledge-base entries from `rb_axpy`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## One wave per workgroup with 1 KB per wave and loads in flight does not transfer from scal to axpy

- **Verdict:** loses
- **Applies when:** Elementwise, touch-once, loop-free kernel with two read streams and one in-place write (y = y + a*x), amdclang build at headroom about 0.95
- **How:** edit_ir: block 64, grid cdiv(N,256); per wave global_load_dwordx2 of y and x at offset 0 and offset:512 (4 loads in flight), s_waitcnt vmcnt(2), 2 v_fmac, store, s_waitcnt vmcnt(1), 2 v_fmac, store offset:512; mask-free fast path when (wg+1)*256 <= n, masked 2-step loop otherwise
- **Measured:** rb_axpy d82054e14c14b81c: 0.974 (CI 0.970..0.976, 240 pairs); the same recipe was 1.12x on rb_scal
- **Session:** 2026-11-21 05:41

## Two sequential 512 B tiles per wave (coarsen-2 pattern, hand-written mask-free fast path)

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel launched as one 512 B tile per wave on a grid of more than 100k workgroups, at the memory floor
- **How:** edit_ir: block 256, grid cdiv(N,1024), lane index wg*1024 + 2*tid; load y, x; s_waitcnt vmcnt(0); v_fmac x2; store; then the same at offset:2048; scalar compare (wg+1)*1024 <= n selects the mask-free path
- **Measured:** rb_axpy bde630c55b36bbd2: 1.034 (CI 1.031..1.037) then 1.009 (CI 1.005..1.011); a4cb5c4521756f8f (coarsen 2 + hoisting): 1.040 then 0.983. Baseline time moved 154 to 165 us between runs
- **Session:** 2026-11-21 05:41

## Contiguous 1 KB per wave against two tiles 2 KB apart at block 256

- **Verdict:** loses
- **Applies when:** Two tiles per wave in a 4-wave workgroup on a two-stream read-modify-write kernel
- **How:** lane index wg*1024 + (tid>>6)*256 + 2*(tid&63) (v_and_b32 0x180 on tid<<1, v_add), second tile at offset:512 instead of offset:2048
- **Measured:** rb_axpy 1a9c9971dbfbd0af: 0.962 (CI 0.959..0.965) against 1.009 to 1.034 for the 2 KB-apart placement
- **Session:** 2026-11-21 05:41

## Next tile's loads in flight before the current tile's store

- **Verdict:** parity
- **Applies when:** Two sequential tiles per wave, each load/wait/fma/store
- **How:** issue tile B's two global_load_dwordx2 right after tile A's s_waitcnt vmcnt(0), before A's v_fmac and store; second wait becomes vmcnt(1) so it does not wait for the store
- **Measured:** rb_axpy be86f36bcac4cba2: 1.027 (CI 1.024..1.030), single run, against 1.034 for the sequential form in the same baseline condition
- **Session:** 2026-11-21 05:41

## Block 128 with two tiles per wave

- **Verdict:** parity
- **Applies when:** Same kernel class; keeps amdclang's workgroup count and halves the waves
- **How:** block 128, grid cdiv(N,512), lane index wg*512 + 2*tid, second tile at offset:1024
- **Measured:** rb_axpy 95733e125d8bd9d3: 0.997 (CI 0.994..1.000)
- **Session:** 2026-11-21 05:41

## Fewer instructions and no exec masks at amdclang's geometry

- **Verdict:** parity
- **Applies when:** Loop-free memory-bound kernel whose amdclang code carries 64-bit index compares, two saveexec regions and a VALU test of a scalar argument
- **How:** scalar alpha test (s_lshl_b32 by 1, s_cmp_eq_u32 0), one scalar compare (wg+1)*512 <= n to a mask-free path, v_fmac_f32_e32 with the SGPR alpha instead of v_pk_fma
- **Measured:** rb_axpy 07c7449cdc0ee15a: 1.0004 (CI 0.997..1.002, 240 pairs)
- **Session:** 2026-11-21 05:41

## Repeat small wins: the baseline's time is bimodal between runs

- **Verdict:** parity
- **Applies when:** Any win below about 5 % on a memory-bound kernel in the 150 us class
- **How:** bench the same state twice at pairs=240 and look at reference_ms in both results; trust only the lower speedup
- **Measured:** rb_axpy: reference_ms 153.9 to 164.8 us across runs; a4cb5c4521756f8f 1.040 then 0.983; bde630c55b36bbd2 1.034 then 1.009
- **Session:** 2026-11-21 05:41

## Two far-apart streams per wave on a memory-floor elementwise kernel

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel, one contiguous 512 B tile per wave, headroom about 1.0; idea is to halve the workgroups by giving each wave a second tile from the other half of the array
- **How:** Block 256, grid W/2; scalar loop of 2 over tile base s14 += G*512 (G appended arg = grid); per tile v_add_u32 index, two v_lshl_add_u64, two global_load_dwordx2, s_waitcnt vmcnt(0), two v_fmac_f32_e32, global_store_dwordx2; scalar s_cmp_le_u32 selects a mask-free path
- **Measured:** rb_axpy state 5f6686cd997a9080: 0.945 (CI 0.939..0.950), 240 pairs
- **Session:** 2026-11-21 05:46

## Four sequential tiles per wave with hoisting (hand-written coarsen 4)

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel at the memory floor where coarsen 2 measured parity and unhoisted coarsen 4 lost
- **How:** Block 256, grid N/2048, kernargs, alpha test and lane index computed once, scalar loop of 4 over tiles 2048 B apart with a mask-free fast path
- **Measured:** rb_axpy state b059a03a9465b17c: 0.954 (CI 0.951..0.957), 240 pairs; unhoisted coarsen 4 was 0.953 to 0.976
- **Session:** 2026-11-21 05:46

## Interleaving the waves of a workgroup within cache lines

- **Verdict:** loses
- **Applies when:** Any kernel where the thread-to-address mapping could be permuted so that several waves share cache lines (thread t -> slot (t%64)*4 + t/64)
- **How:** v_and_b32 v1, 63, v0; v_lshrrev_b32 v0, 6, v0; v_lshl_or_b32 v0, v1, 2, v0 before the index computation
- **Measured:** rb_axpy state 3fe9c8f68072ef9c: 0.814 (CI 0.810..0.816), 240 pairs
- **Session:** 2026-11-21 05:46

## Software prefetch by unwaited loads far ahead

- **Verdict:** loses
- **Applies when:** Streaming kernel at the memory floor; idea is to issue loads into dead registers for a tile several MB ahead and never wait for them
- **How:** After the store: scalar bound test, s_add_u32/s_addc_u32 bases + 0x800000, exec &= 0x0101010101010101 (one lane per 64 B line), two v_lshl_add_u64, two global_load_dword into dead VGPRs, restore exec, s_endpgm with the loads outstanding (static_check accepts it)
- **Measured:** rb_axpy state b67ce4c1ae992e62: 0.939 (CI 0.937..0.942), 240 pairs
- **Session:** 2026-11-21 05:46

## Load order and traversal direction on a two-stream elementwise kernel

- **Verdict:** parity
- **Applies when:** Kernel issues two loads (x and y) under one wait; or workgroup id maps ascending to addresses
- **How:** Swap the two global_load_dwordx2; or s_sub_u32 s2, sW1, s2 with appended arg W-1 so workgroup g owns tile W-1-g
- **Measured:** rb_axpy: load order c6115720d1996b05 0.997 (0.994..0.999); reversed traversal e4a7cf8b78f8551d 0.998 (0.996..1.001), 240 pairs each
- **Session:** 2026-11-21 05:46

## Bimodal baseline: check reference_ms before trusting a few-percent win

- **Verdict:** parity
- **Applies when:** Memory-floor kernel whose baseline time differs by 4 to 5 % between bench invocations (rb_axpy: 155.5 us or 162.6 us)
- **How:** Compare reference_ms across runs; a candidate with a different launch geometry may not follow the baseline's mode and then reads as a win only in slow-mode runs. Repeat until a fast-mode run is obtained, or use a candidate at the baseline's geometry as a control
- **Measured:** rb_axpy: baseline 155.3/155.5/155.6 us and 162.5/162.6/162.7 us across six 240-pair runs; G (same geometry) 163.1 us in a slow run
- **Session:** 2026-11-21 05:46

## 4 B per lane (256 B per wave) on a two-stream read-modify-write kernel

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel where amdclang moves 8 B per lane (global_load_dwordx2, 512 B per wave) at the memory floor; idea is smaller tiles per wave with more waves
- **How:** edit_ir: block 256, grid cdiv(N,256); v_lshl_or_b32 idx, s2, 8, tid; v_cmp_gt_u32 vcc, n, idx + s_and_saveexec_b64; two v_lshl_add_u64; global_load_dword y and x; s_waitcnt vmcnt(0); v_fmac_f32_e32 y, alpha, x; global_store_dword
- **Measured:** rb_axpy 5809ddf0996ec51a: 0.9345 (CI 0.9327..0.9368, 240 pairs), 166.1 us against 155.1 us
- **Session:** 2026-11-21 05:49

## Waves of one workgroup on address streams far apart

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel, 4 waves per workgroup on 4 adjacent 512 B tiles; idea is to give each wave of a workgroup its own stream (tile g + w*G) so that a workgroup drives 4 distant regions
- **How:** edit_ir with appended arg G = grid (s_load_dword at kernarg offset 24): v_lshrrev_b32 w, 6, tid; v_and_b32 lane, 63, tid; v_mul_lo_u32 w, w, sG; v_add_u32 tile, s2, w; v_lshl_or_b32 idx, tile, 7, lane<<1; rest as amdclang (the n compare masks tiles past the end)
- **Measured:** rb_axpy 980fae379c9a6549: 0.9772 (CI 0.9746..0.9804, 240 pairs) with the baseline in its slow mode (161.5 us)
- **Session:** 2026-11-21 05:49

## Block above the source's __launch_bounds__ and 2D grids are not reachable by machine-level edits

- **Verdict:** parity
- **Applies when:** A session wants to test more waves per workgroup than the source's launch bound, or a 2D grid, on an imported amdclang state
- **How:** Do not use edit_ir/relaunch for it (hip launch failure 719 at block 512 on a __launch_bounds__(256) code object; reading s3 as workgroup id y is an undefined_read); make a source state with the larger bound or with blockIdx.y instead
- **Measured:** rb_axpy 97f5f39000af8fa1 (check refused, error 719) and 299e94c91b8f7ce6 (static_check undefined_read s3); no timing
- **Session:** 2026-11-21 05:49
