# Knowledge-base entries from `rb_dot`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Instruction cleanup on a loop-free two-stream reduction at the read floor

- **Verdict:** parity
- **Applies when:** Loop-free reduction kernel (dot, nrm2 kind) where amdclang already issues one global_load_dwordx4 per stream per lane under one wait, headroom about 1.0, and the code carries 64-bit per-lane addresses, saveexec tail regions and a ds_bpermute wave reduction
- **How:** edit_ir: scalar tile base (s_mul_i32, s_lshl_b64, s_add_u32/s_addc_u32) with global_load_dwordx4 v, v_lane16, s[base]; scalar s_cmp_le_u32 on the workgroup's last element to a mask-free path; 4 v_fmac_f32; 4 v_add_f32_dpp + 3 v_readlane_b32; s_mov_b64 exec, 1 before the LDS write; fix_hazards
- **Measured:** rb_dot 172e4fb8c0ee2e5a: 0.9923 (CI 0.9892..0.9997, 240 pairs); 114 instructions against 157; a probe without loads is 18 us of 135 us
- **Session:** 2026-11-21 06:07

## Bytes per wave at a fixed grid on a two-stream reduction

- **Verdict:** loses
- **Applies when:** Each workgroup owns a fixed amount of input (here 16 KB over two streams) and the block size decides how many waves share it
- **How:** Same hand-written body, T tiles of 1 KB per stream per wave unrolled with %rep, 2T global_load_dwordx4 in flight, pipelined s_waitcnt vmcnt(2*(T-1-i)); block 256 (T=2), 128 (T=4), 64 (T=8, no LDS); block 1024 as a source build with 2 floats per lane
- **Measured:** rb_dot: block 1024 0.903; 512 1.000 (baseline); 256 0.945; 128 0.935; 64 0.983 (0.976 with 4 loads per wait); 240 pairs each
- **Session:** 2026-11-21 06:07

## One wave per workgroup without LDS or barrier on a reduction

- **Verdict:** loses
- **Applies when:** Reduction kernel whose cross-wave sum goes through LDS and s_barrier, where one wave could do the whole workgroup with loads in flight (the rb_scal recipe)
- **How:** Block 64, 16 global_load_dwordx4 into v8..v71, pipelined waits, serial v_fmac into one accumulator, DPP reduce, direct global_store_dword from lane 0
- **Measured:** rb_dot 0345179cb0de235b: 0.983 (CI 0.980..0.987); the wave then reads 8 KB per stream, against 1 KB in the baseline
- **Session:** 2026-11-21 06:07

## Wave-to-stream mapping inside a workgroup

- **Verdict:** parity
- **Applies when:** A workgroup reads several distant streams and the waves could be assigned so that neighbours share a chunk or not
- **How:** Two scalar instructions: chunk = w & 3, half = w >> 2 in place of half = w & 1, chunk = w >> 1
- **Measured:** rb_dot 8a5b42c9e18c5142: 0.9932 (CI 0.9915..0.9965), the same as the unchanged mapping (0.9923)
- **Session:** 2026-11-21 06:07

## Cost of the LDS + barrier cross-wave sum

- **Verdict:** parity
- **Applies when:** Deciding whether to remove a one-level LDS reduction (one ds_write per wave, one s_barrier, one or two ds_read_b128) from a memory-bound kernel
- **How:** probe a state that ends with s_endpgm before the reduction, and one without the loads
- **Measured:** rb_dot: 137.1 us without the reduction against 135 us in full; 18.4 us without loads. The reduction is not in the time
- **Session:** 2026-11-21 06:07

## LDS reservation of 40 to 45 KB per workgroup on a memory-bound reduction

- **Verdict:** pays
- **Applies when:** Loop-free or short kernel at the read floor (headroom about 1.0), launched on a large grid (tens of thousands of workgroups), each workgroup reading about 16 KB, with little or no LDS use of its own
- **How:** relaunch(id, {"lds": 40960}); no code change. Sweep 32768 to 46080 with compare(a, b, pairs=240); stay below 50 KB
- **Measured:** rb_dot 6c518e7f4aa338a1: 1.051 (CI 1.043..1.056) and 1.035 (1.029..1.041) over the baseline at 240 pairs; 1.043 (1.041..1.048) in compare against the same code with lds 32 B. 45 KB 1.036; 32.5 KB 1.016; 20 and 26.5 KB 1.00. On amdclang's code b2052d9534a00909: 1.016 (1.011..1.019)
- **Session:** 2026-11-21 06:13

## LDS reservation above 50 KB per workgroup

- **Verdict:** loses
- **Applies when:** Same kernels; deciding how far to push the reservation
- **How:** relaunch(id, {"lds": 53760}) and {"lds": 81920}
- **Measured:** rb_dot: 52.5 KB df5a833ebcfca63a 0.974 (0.970..0.977); 80 KB 18b744a11d6f855a 0.868 (0.863..0.870), 240 pairs
- **Session:** 2026-11-21 06:13

## Block size once the LDS reservation is in place

- **Verdict:** parity
- **Applies when:** A fixed amount of input per workgroup and hand-written bodies for several block sizes that lost without the reservation
- **How:** relaunch each body (block 64 / 128 / 256 with 16 / 8 / 4 wide loads in flight per wave) with lds 40960
- **Measured:** rb_dot: block 256 0.945 -> 1.039 (26e41fb8b266759c), block 128 0.935 -> 1.028 (a1a1833513eb8b6f), block 64 0.983 -> 1.027 (2799a7ff4e1be2b8), 60 pairs each; block 256 vs block 512 at 40 KB compares 1.003 (1.000..1.007, 240 pairs). With 20 KB: block 256 0.982, block 64 0.991; block 64 at 10 KB 0.939
- **Session:** 2026-11-21 06:13

## Occupancy throttle through the VGPR count

- **Verdict:** loses
- **Applies when:** Trying to reduce the waves resident per SIMD on a memory-bound kernel without touching the launch
- **How:** One dead write to a high register (v_mov_b32_e32 v140, 0) so the wave needs 144 VGPRs: 3 waves per SIMD instead of 8
- **Measured:** rb_dot 675677e2def0444a: 0.950 (CI 0.944..0.965, 60 pairs)
- **Session:** 2026-11-21 06:13

## Reversed workgroup traversal on a two-stream reduction

- **Verdict:** parity
- **Applies when:** Each workgroup owns a fixed slice of the inputs and the workgroup id can be mirrored without changing which output it writes
- **How:** After the kernarg wait: s_sub_u32 s2, s16(gridDim), s2; s_sub_u32 s2, s2, 1; all addresses and the workspace index derive from the new s2
- **Measured:** rb_dot 4897b896c87cdcd0: 1.0007 (CI 0.993..1.006, 60 pairs)
- **Session:** 2026-11-21 06:13

## LDS reservation plateau for a floor-bound reduction: 40 to 48 KB per workgroup

- **Verdict:** pays
- **Applies when:** Loop-free reduction or elementwise kernel at the memory floor (headroom about 1.0), block 512 with 8 waves each reading about 1 KB per stream, tens of thousands of workgroups, LDS use of a few bytes
- **How:** relaunch(id, {"lds": 40960}) on the verified state; anything from 40960 to 49152 is equal. Do not go below 40 KB (36 KB is 2 % slower, 20 to 26 KB no effect) or above 50 KB (52.5 KB 0.974, 80 KB 0.868).
- **Measured:** rb_dot: 6c518e7f4aa338a1 1.0275 (1.0247..1.0314, 240 pairs) over the strongest amdclang build; earlier runs 1.023 to 1.051; 48 KB state benched 1.009 in another run though compare calls it equal (1.002)
- **Session:** 2026-11-21 06:16

## coarsen on top of an LDS reservation

- **Verdict:** loses
- **Applies when:** Floor-bound loop-free reduction with LDS + barrier, already launched with a 40 KB reservation
- **How:** apply(id, "coarsen", {"factor": 2})
- **Measured:** rb_dot: 00416048fd491841 0.934 (0.927..0.942) against the 40 KB state, 120 pairs
- **Session:** 2026-11-21 06:16

## Splitting a wide load into two narrower loads per stream

- **Verdict:** loses
- **Applies when:** A wave reads 1 KB contiguous per stream with one global_load_dwordx4 per lane
- **How:** Replace each global_load_dwordx4 by two global_load_dwordx2 (offset 0 and 8), x and y interleaved, same single s_waitcnt vmcnt(0)
- **Measured:** rb_dot: 4c5b6b0c14a27153 0.988 (0.985..0.992) against the x4 state, 120 pairs
- **Session:** 2026-11-21 06:16

## s_setprio around the loads

- **Verdict:** parity
- **Applies when:** Floor-bound loop-free kernel, many short waves
- **How:** s_setprio 3 before the first global_load
- **Measured:** rb_dot: d711c1963c3b408a 0.9995 (0.996..1.003), 120 pairs
- **Session:** 2026-11-21 06:16

## Wave-to-stream remapping with an LDS reservation

- **Verdict:** parity
- **Applies when:** Workgroup whose waves read several distant streams (rocBLAS dot WIN chunks); adjacent waves can be put on different streams
- **How:** chunk = w & 3, half = w >> 2 in the scalar tile-base computation, plus lds 40960
- **Measured:** rb_dot: feea7ca19ec05f83 1.004 (0.995..1.011) against the plain 40 KB state, 120 pairs
- **Session:** 2026-11-21 06:16

## Block 256 against block 512 at the reservation plateau

- **Verdict:** parity
- **Applies when:** Same floor-bound reduction; choice of 4 waves x 2 KB or 8 waves x 1 KB per stream per workgroup
- **How:** Block 256 body with 4 wide loads in flight per wave, lds 49152
- **Measured:** rb_dot: 3333386fd0e731fe compare 1.004 (0.999..1.012) against block 512 at 40 KB; bench 1.013 (1.009..1.018, 240 pairs)
- **Session:** 2026-11-21 06:16
