# Knowledge-base entries from `mo_active_fwd`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Mask-free scalar-base fast path on a 1-in / 1-out elementwise kernel already at 1 KB per one-wave workgroup

- **Verdict:** parity
- **Applies when:** Loop-free touch-once kernel; amdclang code has s_and_saveexec bounds mask, 2-3 scalar loads with separate waits, per-lane 64-bit address VALU, vcc compares with s_nop between; block 64 with one global_load_dwordx4 per lane; headroom about 1.0
- **How:** s_load_dwordx8 s[4:11] kernargs; s12 = (wg<<6)+64; s_cmp_le_u32 s12, Q else branch to amdclang's code as tail; bases += wg<<10 with s_add_u32/s_addc_u32; v4 = tid<<4; global_load_dwordx4 v[0:3], v4, s[4:5]; s_waitcnt vmcnt(0); 4 v_mul_f32 by alpha SGPR, 4 v_cmp_ge_f32_e64 into SGPR pairs, 4 v_cndmask_b32_e64; global_store_dwordx4 v4, v[0:3], s[6:7]
- **Measured:** mo_active_fwd 4e6cd70b97733348: 1.0009 (CI 0.9945..1.0043, 240 pairs), 107.8 us
- **Session:** 2026-11-21 07:27

## Two loads in flight within the same 1 KB per wave (rb_scal recipe) when the baseline is already one wave per workgroup

- **Verdict:** parity
- **Applies when:** Elementwise 1-in / 1-out kernel whose amdclang baseline is already block 64 with 16 B per lane (1 KB contiguous per wave)
- **How:** v4 = tid<<3; global_load_dwordx2 at offset 0 and offset:512 from the scalar base; s_waitcnt vmcnt(1); compute + store first half; s_waitcnt vmcnt(1); compute + store second half at offset:512
- **Measured:** mo_active_fwd b0ce91fa40eb3796: 1.0015 (CI 0.9966..1.0034, 60 pairs)
- **Session:** 2026-11-21 07:27

## 2 KB per wave with two dwordx4 loads in flight (half the waves)

- **Verdict:** loses
- **Applies when:** Loop-free streaming kernel at 1 KB per one-wave workgroup; empty-kernel probe shows dispatch is half the time
- **How:** block 64, grid cdiv(Q,128); loads at offset 0 and offset:1024 from scalar base; vmcnt(1); compute/store A; vmcnt(1); compute/store B at offset:1024; masked 2-step loop as tail
- **Measured:** mo_active_fwd cdabba688e4877a4: 0.9312 (CI 0.922..0.939), 117.0 us against 108.9 us, although the dispatch-only probe fell from 58.2 us to 30.7 us
- **Session:** 2026-11-21 07:27

## More waves per workgroup (block 128 / 256) at 1 KB per wave

- **Verdict:** loses
- **Applies when:** Streaming elementwise kernel whose best amdclang build is block 64, one wave per workgroup
- **How:** same mask-free body with shifts changed (end wg<<7 or <<8, base wg<<11 or <<12), relaunch block 128 grid cdiv(Q,128) or block 256 grid cdiv(Q,256)
- **Measured:** mo_active_fwd: block 128 e614415d0c1f1f63 0.9751 (0.971..0.985); block 256 ed89d596c6f3e5e2 0.9829 (0.977..0.990); 60 pairs
- **Session:** 2026-11-21 07:27

## 8 B per lane with two 512 B waves per workgroup instead of 16 B per lane in one wave

- **Verdict:** loses
- **Applies when:** 1-in / 1-out streaming kernel at 16 B per lane, block 64; idea from mo_prelu_bwd where 8 B per lane was the optimum for 4 streams
- **How:** block 128, grid cdiv(Q,64); v4 = tid<<3; one global_load_dwordx2 / global_store_dwordx2 per lane with scalar bases; masked tail on (wg*128+tid)>>1 < Q
- **Measured:** mo_active_fwd 902817841f63d59d: 0.9869 (CI 0.983..0.993, 60 pairs)
- **Session:** 2026-11-21 07:27

## Empty-kernel probe: wave dispatch is not additive with the memory stream

- **Verdict:** parity
- **Applies when:** Loop-free kernel launched as hundreds of thousands of one-wave workgroups; question whether fewer waves would save the dispatch time
- **How:** Replace the fast path after the kernarg wait and bounds compare by s_endpgm and probe; repeat at half the grid
- **Measured:** mo_active_fwd: 58.2 us at 262144 waves, 30.7 us at 131072 (about 0.21 us per 1000 waves); store-only 61.6, load-only 87.0, full 107.8 us; full kernel at half the waves 117 us
- **Session:** 2026-11-21 07:27

## Half-wave workgroups (block 32) on a one-wave elementwise kernel

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel at headroom ~1.0 launched as one 64-lane wave per workgroup with ~1 KB contiguous per wave
- **How:** Change the workgroup shift in the index (v_lshl_add_u32 v0, s2, 6 -> 5) and relaunch with block 32, grid cdiv(Q,32)
- **Measured:** mo_active_fwd edd556f7c25da0a4: 0.9067 (CI 0.9006..0.9119, 60 pairs)
- **Session:** 2026-11-21 07:31

## Two far-apart chunks per wave to halve the wave count

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel at the memory floor whose empty-kernel dispatch probe is half the run time
- **How:** Grid cdiv(G,2); wave i handles chunk i and chunk i + cdiv(G,2): two v_cmp_gt_u32_e64 masks into SGPR pairs, s_mov_b64 exec per chunk, both global_load_dwordx4 issued before the first s_waitcnt vmcnt(1), store, second vmcnt(1), store
- **Measured:** mo_active_fwd 3e9cd2176a4b2bc8: 0.9168 (CI 0.9052..0.9259, 60 pairs); contiguous 2 KB was 0.931, coarsen 2 was 0.966
- **Session:** 2026-11-21 07:31

## Reverse the order in which workgroups walk the arrays

- **Verdict:** parity
- **Applies when:** Streaming elementwise kernel, one contiguous chunk per workgroup
- **How:** In the full-workgroup fast path use chunk = Q/64 - 1 - wg (s_lshr, 2 s_sub) for the scalar base offsets; tail workgroup unchanged
- **Measured:** mo_active_fwd 5fd0a1ab77b48f8e: 0.9940 (CI 0.9908..0.9963, 240 pairs)
- **Session:** 2026-11-21 07:31

## 2-D grid instead of a long 1-D grid

- **Verdict:** parity
- **Applies when:** Kernel launched on a 1-D grid of 10^5 or more one-wave workgroups
- **How:** Source level: tid = (blockIdx.y * 1024 + blockIdx.x) * 64 + threadIdx.x, grid [1024, cdiv(Q,65536)], block 64
- **Measured:** mo_active_fwd 0bfbfcbe2113c99c: 1.0017 (CI 0.9981..1.0037, 60 pairs)
- **Session:** 2026-11-21 07:31
