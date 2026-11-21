# Knowledge-base entries from `rb_nrm2`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## LDS reservation 40 KB on amdclang's block-512 reduction with 8 KB per workgroup

- **Verdict:** loses
- **Applies when:** Loop-free single-stream reduction at the read floor (headroom ~1.08), block 512, 8 waves each one global_load_dwordx4 per lane (1 KB per wave), 8 KB per workgroup, LDS use of 32 bytes
- **How:** relaunch(id, {"lds": 40960}); no code change
- **Measured:** rb_nrm2 e8e56cdaf9a213ab: 0.9656 (CI 0.959..0.974, 120 pairs) on amdclang's code; 49bed15b8048cc1e (DPP reduce variant) 1.0024 (0.9995..1.011). rb_dot (16 KB per workgroup) had 1.03-1.05 from the same relaunch
- **Session:** 2026-11-21 06:21

## One wave per workgroup with 8 wide loads in flight on a single-stream reduction

- **Verdict:** loses
- **Applies when:** Reduction kernel whose workgroup owns 8 KB in 4 distant 2 KB chunks and combines 8 waves through LDS + s_barrier; candidate for the rb_scal one-wave recipe
- **How:** edit_ir with block [64,1,1]: 4 scalar 64-bit chunk bases (s_lshl_b64, s_add_u32/s_addc_u32), 8 global_load_dwordx4 v[8+4k..], v_lane16, s[base] (offset:1024 for the second half), fix_waits (vmcnt(7)..vmcnt(0)), v_mul + 31 v_fmac_f32 into one accumulator, 4 v_add_f32_dpp + 4 v_readlane_b32, s_mov_b64 exec, 1, global_store_dword; scalar s_sub_u32/s_subb_u32 range test to a masked global_load_dword tail path
- **Measured:** rb_nrm2 60c8966584865361: 0.8738 (CI 0.871..0.882, 120 pairs) with lds 0
- **Session:** 2026-11-21 06:21

## Throttling a one-wave-per-workgroup body to one workgroup per CU with an LDS reservation

- **Verdict:** parity
- **Applies when:** Block-64 body with 8 or more wide loads in flight per wave on a floor-bound kernel, launched on tens of thousands of workgroups, that loses against the multi-wave baseline
- **How:** relaunch(id, {"lds": 40960}) (1 workgroup per CU); 32768 (2 per CU) and 21504 (3 per CU) for the sweep, ranked with compare(a, b, pairs=120)
- **Measured:** rb_nrm2: no LDS 0.874; 40 KB 5af7da68be8b650a 1.0107 (CI 1.0044..1.0132, 240 pairs) over the baseline; 32 KB 0.978 and 21 KB 0.924 relative to the 40 KB state. Recovers parity, not a win
- **Session:** 2026-11-21 06:21

## coarsen on a one-wave-per-workgroup floor-bound reduction

- **Verdict:** loses
- **Applies when:** Block-64 loop-free body with 8 wide loads in flight, with or without a 40 KB LDS reservation; hoping to cut workgroup launches
- **How:** apply(id, "coarsen", {"factor": 2 | 4}) then relaunch(id, {"lds": 40960})
- **Measured:** rb_nrm2: factor 2 without LDS 345ad9aca6aa2683 0.8285; factor 2 + 40 KB 7ae9da3a207f9a36 0.9432 (0.937..0.950); factor 4 + 40 KB ae181293df6f8b7f 0.8758 (0.870..0.884)
- **Session:** 2026-11-21 06:21

## Where the time is in a loop-free x4-load reduction

- **Verdict:** parity
- **Applies when:** Deciding whether to touch the wave reduction, LDS, barrier or address arithmetic of a dot/nrm2-kind kernel with headroom near 1.0
- **How:** probe a state with the global_load_dwordx4 and its wait deleted, and one with s_endpgm inserted right after the squares
- **Measured:** rb_nrm2 at N=2^26: 19.0 us without the load (fddc5a7835036e21), 88.4 us without the reduction (b80db52c25121aa7) against 85 us in full: 66 us is the read at ~4.05 TB/s, the reduction is free
- **Session:** 2026-11-21 06:21

## Sweep the LDS reservation to set resident workgroups per CU on a read-bound reduction

- **Verdict:** pays
- **Applies when:** A loop-free multi-wave kernel at the memory floor (headroom 1.0-1.1) whose waves each issue one wide load and wait (block 512 = 8 waves x 1 KB here); the default launch fills the CU (4 workgroups / 32 waves).
- **How:** relaunch(state, {grid, block, lds: X}) with the code unchanged, for X giving every integer workgroups-per-CU value: 21840 (3), 32768 (2), 40960 (1). Bench each with 240 pairs. Do not conclude from one point.
- **Measured:** rb_nrm2: 21.8 KB 1.002 (0.989..1.013); 32 KB 1.0206 (1.018..1.023) and 1.0271 (1.024..1.031) at 240 pairs; 40 KB 0.9656 (0.959..0.974).
- **Session:** 2026-11-21 06:25

## Reads in flight per CU have an optimum near 8-16 KB

- **Verdict:** pays
- **Applies when:** Choosing bytes per wave x waves per CU for a streaming read kernel.
- **How:** Multiply bytes in flight per wave by resident waves per CU (occupancy or LDS-limited). Aim for 8-16 KB: 16 waves x 1 KB, or one wave x 8 KB (8 x4 loads) with a 40 KB reservation.
- **Measured:** rb_nrm2: 16 x 1 KB 1.02; 1 x 8 KB 1.01; 2 x 4 KB 0.996; 32 x 1 KB 1.00 (baseline); 8 x 1 KB 0.966; 32 x 8 KB 0.87.
- **Session:** 2026-11-21 06:25

## DPP wave reduce on top of a throttled launch

- **Verdict:** parity
- **Applies when:** A 6-step ds_bpermute wave reduction after a single wide load in a read-bound kernel.
- **How:** Replace the ds_bpermute tree by 4 v_add_f32_dpp + 4 v_readlane_b32 (fix_hazards), same launch.
- **Measured:** rb_nrm2 with LDS 32 KB: compare bacb24247474c2bf over 23605de723d4eace 1.0038 (1.0002..1.0062), 240 pairs.
- **Session:** 2026-11-21 06:25

## 32 contiguous bytes per lane instead of two 16-byte pieces 1 KB apart

- **Verdict:** parity
- **Applies when:** A one-wave body that reads 2 KB per chunk with two global_load_dwordx4 from a scalar base + lane offset.
- **How:** v1 = lane << 5 and loads at offset 0 and 16 (was lane << 4 and offsets 0 and 1024); masked tail path indexed lane*8 + 0..7.
- **Measured:** rb_nrm2 dac7254f71e2bbb0 1.012 (1.002..1.021) against 1.0107 for the parent layout.
- **Session:** 2026-11-21 06:25

## Two phases of 4 loads instead of 8 loads in flight in a one-wave body

- **Verdict:** parity
- **Applies when:** A one-wave-per-workgroup body with 8 x4 loads in flight, launch throttled by an LDS reservation.
- **How:** Issue 4 loads, pipelined vmcnt(3..0) with the fmac chain, then the other 4 loads; LDS 32 KB so two such waves share a CU.
- **Measured:** rb_nrm2 7358f476c2c9bcee 0.996 (0.986..1.000).
- **Session:** 2026-11-21 06:25

## coarsen on a read-bound reduction, with a throttled launch

- **Verdict:** loses
- **Applies when:** Loop-free 8-wave reduction workgroups at the memory floor.
- **How:** apply(coarsen, factor 2) then relaunch with lds 32768.
- **Measured:** rb_nrm2 43fcbadb8cf217f1 0.938 (0.931..0.945); without the reservation 0.940.
- **Session:** 2026-11-21 06:25

## Occupancy throttle through the VGPR count on a loop-free read-bound reduction

- **Verdict:** loses
- **Applies when:** Loop-free multi-wave kernel at the read floor where an LDS reservation (whole workgroups per CU) paid a few percent and a finer waves-per-CU setting is wanted
- **How:** edit: insert one dead `v_mov_b32_e32 vK, 0` at the top with K = 95 / 127 / 167 so the wave needs 96 / 128 / 168 VGPRs (5 / 4 / 3 waves per SIMD), lds 0
- **Measured:** rb_nrm2: c36496efde5d2c6a 0.9105 (0.906..0.916), 69c30efa98e7e787 0.7695 (0.764..0.775), 7851b8d06b439e5d 0.5873 (0.584..0.590), 120 pairs each; the LDS route to a similar wave count measured 1.00 to 1.02
- **Session:** 2026-11-21 06:31

## Block 256 with a whole 2 KB chunk per wave, at 2 workgroups per CU

- **Verdict:** parity
- **Applies when:** Reduction whose workgroup owns 4 chunks of 2 KB and amdclang's build uses 8 waves x 1 KB with one global_load_dwordx4 per lane; a 32 KB LDS reservation already paid
- **How:** edit_ir with block [256,1,1], lds 32768: lane index g*512 + j*inc + lane*8 (v_mad_i64_i32 with j = tid >> 6), two global_load_dwordx4 at offset 0 and 16, s_waitcnt vmcnt(1) / vmcnt(0), v_mul + 7 v_fmac, 8-step masked dword tail, ds_read_b128 of 4 partial sums
- **Measured:** rb_nrm2 aacdfffa24c1e947: 1.0279 (1.021..1.034) over the baseline; 0.9978 (0.995..0.999, 240 pairs) against amdclang's block-512 code with the same reservation. Launch-only probe 10.6 us against 17.4 us, not visible in the total
- **Session:** 2026-11-21 06:31

## LDS reservation sweep on a block-256 body: 2 workgroups per CU again

- **Verdict:** pays
- **Applies when:** Hand-written block-256 read-bound body (4 waves x 2 KB) on a grid of tens of thousands of workgroups
- **How:** relaunch with lds 21840 (3 per CU), 32768 (2), 40960 (1); rank with compare(pairs=120)
- **Measured:** rb_nrm2: 3 per CU 09f4d8c283f6282e 0.925 (0.921..0.932), 1 per CU d0b0d8089d94d632 0.948 (0.945..0.953), both against 2 per CU
- **Session:** 2026-11-21 06:31

## DPP wave reduce on a block-256 body under a throttled launch

- **Verdict:** parity
- **Applies when:** ds_bpermute wave reduction after the loads in a read-bound kernel launched with 2 workgroups per CU
- **How:** 4 v_add_f32_dpp (quad_perm, quad_perm, row_half_mirror, row_mirror) with s_nop 1 between, 4 v_readlane_b32 at lanes 0/16/32/48, s_mov_b64 exec, 1 before ds_write_b32
- **Measured:** rb_nrm2 3dcf47e375b4f914: 1.0236 (1.0187..1.0259) and 1.0256 (1.0207..1.0295) over the baseline, 240 pairs; 1.0014 (0.997..1.006) against the plain 32 KB relaunch
- **Session:** 2026-11-21 06:31

## Staggering two wide loads inside a wave

- **Verdict:** loses
- **Applies when:** A wave issues two global_load_dwordx4 for contiguous data and waits once; idea is fewer bytes in flight per CU
- **How:** Move the second global_load_dwordx4 after an s_waitcnt vmcnt(0) on the first
- **Measured:** rb_nrm2 dbea8df1a3f326ba: 0.957 (0.952..0.961, 120 pairs) against the two-in-flight parent
- **Session:** 2026-11-21 06:31

## Launch-only probe is not additive on a read-bound kernel

- **Verdict:** parity
- **Applies when:** Estimating what fewer waves or a shorter body can give from a no-load or empty-kernel probe
- **How:** edit: insert s_endpgm at index 0 of the entry block for each block size; probe
- **Measured:** rb_nrm2: 17.4 us at block 512, 10.6 us at block 256 and block 64, while the full kernels at block 512 and 256 both take 83.7 us
- **Session:** 2026-11-21 06:31
