# Knowledge-base entries from `fi_silu_and_mul`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## 512 B per stream per one-wave workgroup on a 2-in / 1-out elementwise kernel (second kernel)

- **Verdict:** pays
- **Applies when:** Loop-free touch-once kernel, amdclang build at block 64 with global_load_dwordx4 per lane (1 KB per stream per wave), headroom about 1.05
- **How:** global_load_dwordx2 / global_store_dwordx2 with scalar bases and v8 = index << 3, index = wg_x << 6 | tid, grid [cdiv(D4,32), B], block 64; parent the edit on a 2D-grid source state so that s3 holds workgroup id y
- **Measured:** fi_silu_and_mul b64a030cb47939aa: 1.0266 (1.021..1.037, 120 pairs), 1.0191 (1.012..1.026, 240 pairs), bit-identical to the baseline; fi_gelu_tanh_and_mul gave 1.027
- **Session:** 2026-11-21 08:20

## Half-filled waves to reach 512 B per wave

- **Verdict:** parity
- **Applies when:** Elementwise kernel at 16 B per lane where 512 B per wave is wanted without changing the load width
- **How:** block 32, global_load_dwordx4, index = wg << 5 | tid, grid cdiv(D4,32)
- **Measured:** fi_silu_and_mul 8db12f78882b5f47: 1.0055 (0.996..1.018, 120 pairs) against 1.027 for full waves at 8 B per lane
- **Session:** 2026-11-21 08:20

## Two 512 B loads per stream in flight in a 1 KB wave with a mask-free fast path

- **Verdict:** parity
- **Applies when:** Two read streams and one write stream, one wave per workgroup, memory floor
- **How:** 4 global_load_dwordx2 (second pair at offset:512), vmcnt(3) / vmcnt(2) / store / vmcnt(2) / vmcnt(1) / store offset:512; s_cmp_le_u32 on (wg+1)*128 against n selects the unmasked path
- **Measured:** fi_silu_and_mul a04010a0d5996acd: 1.0071 (0.999..1.018, 120 pairs)
- **Session:** 2026-11-21 08:20

## 4 waves per workgroup at 512 B per stream per wave

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel launched as 262144 one-wave workgroups; empty launch of 131072 workgroups measures 31 us
- **How:** index = wg << 8 | tid, block 256, grid [cdiv(D4,128), B]
- **Measured:** fi_silu_and_mul 19b38d4d55e4e83a: 1.0117 (1.005..1.019, 120 pairs) against 1.027 at block 64
- **Session:** 2026-11-21 08:20

## 1D grid with a scalar division preamble against a 2D grid

- **Verdict:** parity
- **Applies when:** Row x chunk kernel whose amdclang build computes token = blockIdx.x / chunks with the 25-instruction v_rcp_iflag sequence
- **How:** Same body with the preamble kept and grid B*cdiv(D4,32), against grid [cdiv(D4,32), B] reading s2/s3
- **Measured:** fi_silu_and_mul 453fd3b9ca7d7aa8 1.0201 (1.013..1.026) against b64a030cb47939aa 1.0266 (1.021..1.037)
- **Session:** 2026-11-21 08:20

## v_min_u32 clamp in place of the bounds mask

- **Verdict:** parity
- **Applies when:** Entry is v_cmp_gt_u32 + s_and_saveexec + s_cbranch_execz on a per-lane index, output does not alias input, at least one group per row
- **How:** s_sub_u32 s5, n, 1; v_min_u32_e32 v0, s5, v0; delete the compare, saveexec and branch
- **Measured:** fi_silu_and_mul 0ca588471e824eea: 1.0252 (1.012..1.030) against 1.0266 with the mask
- **Session:** 2026-11-21 08:20

## Time split of a 3-stream elementwise kernel by probes

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel, one-wave workgroups, headroom about 1.05
- **How:** probe with the arithmetic deleted, with the store deleted, and with the body after the bounds branch replaced by s_nop
- **Measured:** fi_silu_and_mul: 96.6 us total; empty body 30.9 us; no store 85.6 us; no arithmetic 96.0 us
- **Session:** 2026-11-21 08:20

## Source build of the 512 B per wave geometry against the hand-written body (second kernel)

- **Verdict:** parity
- **Applies when:** Loop-free 2-in / 1-out elementwise kernel whose amdclang build uses global_load_dwordx4 per lane at block 64 (1 KB per stream per wave), headroom about 1.05
- **How:** source(): 2 floats per thread (8-byte memcpy), idx = blockIdx.x * 64 + threadIdx.x, token = blockIdx.y, grid [cdiv(D4,32), B], block 64. Then compare(source_state, hand_written, pairs=240).
- **Measured:** fi_silu_and_mul: source b5a545ec9c6feb8b 1.016 (1.009..1.021, 240 pairs); hand-written 0ca588471e824eea 1.0087 over it (1.004..1.014); block-128 hand-written 100901bab2c367e6 1.0071 over it (1.002..1.012)
- **Session:** 2026-11-21 08:24

## Two waves per workgroup at 512 B per stream per wave

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel at the memory floor on about 262144 one-wave workgroups, index = wg_x << 6 | tid
- **How:** v_lshl_add_u32 v0, s2, 7, v0; relaunch grid [cdiv(D4,64), B], block 128
- **Measured:** fi_silu_and_mul 100901bab2c367e6: 1.0256 (1.021..1.030, 240 pairs) against 1.019 to 1.025 for block 64 on the same body
- **Session:** 2026-11-21 08:24

## Descending address order along a row

- **Verdict:** parity
- **Applies when:** Row x chunk elementwise kernel where grid x walks contiguous chunks
- **How:** chunk = ((n - 1) >> 6) - wg_x before forming the lane index (s_lshr_b32, s_sub_u32)
- **Measured:** fi_silu_and_mul c1b4756209e8aa7e: 1.0255 (1.020..1.034, 120 pairs) against 1.0252 ascending
- **Session:** 2026-11-21 08:24

## 4 B per lane request at 512 B per wave (two 256 B dword loads per stream)

- **Verdict:** parity
- **Applies when:** Elementwise kernel where 8 B per lane x 64 lanes beats 16 B per lane; question whether smaller lane requests help further
- **How:** lane handles floats i and i+64 of a 128-float wave: two offset registers clamped with v_min_u32, 4 global_load_dword with scalar bases, vmcnt(2) then vmcnt(0), 2 global_store_dword
- **Measured:** fi_silu_and_mul 2730141a54e570d9: 1.0022 (0.990..1.016, 120 pairs) against 1.025 for one dwordx2 load per stream
- **Session:** 2026-11-21 08:24

## One scalar kernarg load per wave instead of two

- **Verdict:** parity
- **Applies when:** Short one-wave workgroups (about 262144) that issue s_load_dword + s_load_dwordx4 from the kernarg block
- **How:** s_load_dwordx8 s[16:23], s[0:1], 0x0 and s_mov_b32 into place; only legal when the kernarg block is at least 32 bytes
- **Measured:** fi_silu_and_mul probe 1b468cdee08d3b13: 94.8 us against 95.7 us, single medians, inside the noise
- **Session:** 2026-11-21 08:24
