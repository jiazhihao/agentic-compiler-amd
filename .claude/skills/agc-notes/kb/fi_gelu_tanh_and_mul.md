# Knowledge-base entries from `fi_gelu_tanh_and_mul`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## 512 B per stream per one-wave workgroup on a 2-in / 1-out elementwise kernel

- **Verdict:** pays
- **Applies when:** Loop-free touch-once kernel with two contiguous read streams and one write stream, amdclang build at block 64 with global_load_dwordx4 per lane (1 KB per stream per wave), headroom about 1.05
- **How:** Halve the bytes per lane: global_load_dwordx2 / global_store_dwordx2, lane offset tid<<3, grid doubled (cdiv(D4,32) x B, block 64). At the source level: a 2-float struct per thread instead of 4. Check the source build first: the gain is the geometry.
- **Measured:** fi_gelu_tanh_and_mul: source build 797081167de59acb 1.0223 (CI 1.015..1.028, 240 pairs, bit-identical); hand-written 67706bf328c6b217 1.0268 (1.021..1.031) vs baseline and 0.998 (0.994..1.003) vs the source build
- **Session:** 2026-11-21 08:08

## Hand-written mask-free scalar-base body against amdclang's code at the same geometry

- **Verdict:** parity
- **Applies when:** Elementwise kernel at headroom about 1.05 whose amdclang code has s_and_saveexec bounds mask, per-lane 64-bit addresses and an inlined libm tanh with exec-mask branches (150 VALU)
- **How:** s_load_dwordx4 + s_load_dword, scalar compare for full workgroups, bases with s_add_u32/s_addc_u32, global_load v, v_off32, s[base], branchless 0.5(1+tanh z) = rcp(1+exp2(-2.885 z)), amdclang-style masked tail
- **Measured:** fi_gelu_tanh_and_mul: 3699e7b9d2e03c2d 1.0051 (0.997..1.012) at 1 KB per wave; 67706bf328c6b217 against amdclang's build at 512 B per wave 0.998 (0.994..1.003, 240 pairs); probe with all gelu arithmetic removed 98.0 us against 96.3 us
- **Session:** 2026-11-21 08:08

## Bytes per wave sweep on a 3-stream elementwise kernel

- **Verdict:** pays
- **Applies when:** Loop-free elementwise kernel, one wave per workgroup, two read streams and one write stream at the memory floor
- **How:** Same body with dword / dwordx2 / dwordx4 per lane and grid cdiv(D4,16) / cdiv(D4,32) / cdiv(D4,64); 2 KB as two dwordx4 per stream at offset:1024 with grid cdiv(D4,128)
- **Measured:** fi_gelu_tanh_and_mul: 256 B 0.8355 (03a12b019986c1ca), 512 B 1.0268 (67706bf328c6b217), 1 KB 1.0051 (3699e7b9d2e03c2d), 2 KB 0.9841 (86983a05cc1045ab)
- **Session:** 2026-11-21 08:08

## Two 512 B loads per stream in flight within one 1 KB wave (rb_scal recipe) on a 3-stream kernel

- **Verdict:** parity
- **Applies when:** Elementwise kernel with two read streams where 512 B per wave beats 1 KB per wave; question whether it is bytes per lane or bytes per wave
- **How:** v8 = tid<<3; global_load_dwordx2 x0, y0, then x1, y1 at offset:512; vmcnt(3), compute, vmcnt(2), store; vmcnt(2), compute, vmcnt(1), store at offset:512
- **Measured:** fi_gelu_tanh_and_mul a7f7e86903945c90: 1.0055 (0.995..1.018, 60 pairs): the gain of 512 B is per wave, not per lane
- **Session:** 2026-11-21 08:08

## coarsen on a hand-written elementwise fast path

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel at the memory floor, one-wave workgroups of 512 B or 1 KB per stream
- **How:** apply(id, 'coarsen', {'factor': 2})
- **Measured:** fi_gelu_tanh_and_mul: 13ae3eac0966d9b9 0.9897 (0.979..0.995) at 1 KB; 051d1964fb7634ef 1.0047 (0.997..1.013) at 512 B, against 1.027 uncoarsened
- **Session:** 2026-11-21 08:08

## Swapping the grid axes of a row x chunk elementwise kernel

- **Verdict:** loses
- **Applies when:** 2-D grid where grid x walks contiguous chunks of a row and grid y the rows
- **How:** relaunch grid [B, cdiv(D4,64)] and swap s2/s3 at entry (three s_mov_b32)
- **Measured:** fi_gelu_tanh_and_mul 5f03a31af3111802: 0.8783 (0.870..0.888): consecutive workgroups 131 KB apart instead of 1 KB
- **Session:** 2026-11-21 08:08

## rcp(1+exp2) in place of 0.5*(1+tanh) is not a neutral rewrite

- **Verdict:** parity
- **Applies when:** gelu_tanh or any 0.5*(1+tanh z) cdf multiplied by x, where a cheaper form is wanted within tolerance
- **How:** v_mul by -2.8853900 (0xc0135761), v_exp_f32, v_add 1.0, v_rcp_f32; run equivalent() against the original
- **Measured:** fi_gelu_tanh_and_mul 67706bf328c6b217: battery 77/77, but equivalent() max relative difference 0.498, max absolute 0.375 on large_exponent (the original cancels for large negative x); no time gained (parity)
- **Session:** 2026-11-21 08:08

## Mask-free tail by clamping the lane start (v_min_u32) instead of a bounds mask

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel whose entry is `v_cmp_gt_u32` + `s_and_saveexec` + `s_cbranch_execz` on a per-lane index, with output not aliasing input and at least one full group of elements per row
- **How:** Compute the lane's start element, `v_min_u32_e32 v, s(n - E), v`, shift to a byte offset and use it with scalar bases (`global_load_dwordxN vdst, voff, s[base:base+1]`); out-of-range lanes recompute and rewrite the last group. Drop the compare, saveexec and branch.
- **Measured:** fi_gelu_tanh_and_mul 90cda7e313ab60af: 1.0011 (CI 0.992..1.009, 120 pairs), bit-identical to the baseline, full battery passes
- **Session:** 2026-11-21 08:15

## Branchless libm tanhf: both ranges for every lane, selected with v_cndmask

- **Verdict:** parity
- **Applies when:** amdclang inlined a libm function as `s_and_saveexec` / `s_xor` / `s_cbranch_execz` blocks per element in a memory-bound kernel
- **How:** Emit the exp-range and polynomial-range sequences unmasked into separate registers, then `v_cmp_ge_f32_e64 vcc, |z|, s` and `v_cndmask_b32_e32`; keep 2 wait states between a compare and its v_cndmask and 1 after v_exp/v_rcp
- **Measured:** fi_gelu_tanh_and_mul 90cda7e313ab60af: 132 -> 104 instructions, 3 -> 0 branches, 1.0011 (parity), bit-identical to the baseline
- **Session:** 2026-11-21 08:15

## 12 B per lane (dwordx3) between the 8 B and 16 B geometries

- **Verdict:** loses
- **Applies when:** Two-stream elementwise kernel already at 8 B per lane / 512 B per stream per wave, headroom about 1.03
- **How:** `global_load_dwordx3` / `global_store_dwordx3`, lane start = 3 * index clamped to n - 3, grid cdiv(D4, 48)
- **Measured:** fi_gelu_tanh_and_mul f2c89a90a71b1f20: 0.9351 (CI 0.923..0.941, 120 pairs)
- **Session:** 2026-11-21 08:15

## Waves per workgroup at 512 B per stream per wave

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel at the memory floor launched with one wave per workgroup on a grid of about 260k workgroups
- **How:** Same body, index = wg << log2(block) | tid, block 128 / 256 / 512 / 1024 with the grid divided accordingly; the root source needs a matching __launch_bounds__ or the launch fails with 719
- **Measured:** fi_gelu_tanh_and_mul: block 128 88e1399bae561aae 1.0062 (240 pairs), block 256 38c9788c65b7ace6 1.0099 (240 pairs), block 512 5823f9c679e27c62 1.0028, block 1024 afbff8206ade418e 0.9752; the 128 and 256 states read 1.019 and 1.017 at 120 pairs
- **Session:** 2026-11-21 08:15
