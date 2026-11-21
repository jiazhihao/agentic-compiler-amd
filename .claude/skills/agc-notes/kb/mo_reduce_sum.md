# Knowledge-base entries from `mo_reduce_sum`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## LDS-reservation throttle on a block-64, 1-KB-per-wave read-bound reduction

- **Verdict:** parity
- **Applies when:** Loop-free reduction at headroom ~1.06 launched as one-wave workgroups (block 64), each wave one global_load_dwordx4 per lane, hundreds of thousands of workgroups, no LDS use
- **How:** relaunch(id, {"lds": 2730 | 4096 | 8192}) for 24 / 16 / 8 waves per CU; no code change
- **Measured:** mo_reduce_sum: 9d54bf97e74c9376 1.000 (0.996..1.004), 975593dc4eb5b4a5 0.998 (0.994..1.007), f39988d21cc54fa7 0.864 (0.861..0.868), 60 pairs
- **Session:** 2026-11-21 06:48

## Several outputs per wave with wide loads in flight to cut one-wave workgroups

- **Verdict:** loses
- **Applies when:** Launch-only probe is most of the kernel time (58 of 84 us) on a block-64 reduction that reads 1 KB per wave; tempting to give each wave 2 or 4 KB
- **How:** edit_ir: 16 (or 32) lanes per output, lane offset l*64 (l*32), 4 (2) global_load_dwordx4 v, v_off, s[base] offset 16*i, one s_waitcnt vmcnt(0), pairwise v_add_f32, 4 v_add_f32_dpp (fix_hazards), s_mov_b64 exec, s[16:17] with mask 0x0001000100010001 and one global_store_dword v_(l>>2), v4, s[out]; grid cdiv(N,1024) (cdiv(N,512))
- **Measured:** mo_reduce_sum: 4 KB/wave a264b0e365e1a3bf 0.922 (0.917..0.927); 2 KB/wave 33cdbd815f567a5c 0.972 (0.966..0.981)
- **Session:** 2026-11-21 06:48

## Throttling a 4-KB-per-wave body with an LDS reservation

- **Verdict:** loses
- **Applies when:** One-wave body with 4 wide loads in flight that loses against a 1-KB-per-wave baseline
- **How:** relaunch with lds 8192 / 16384 / 32768 (8 / 4 / 2 waves per CU)
- **Measured:** mo_reduce_sum: 0.922 unthrottled -> 0.962 (34a220e13f0de754), 0.977 (8c6164d3eb3cd2ab), 0.988 (5c03c8f1ab1c66f4, CI 0.983..0.992)
- **Session:** 2026-11-21 06:48

## Launch-only probe overstates what fewer workgroups can give

- **Verdict:** parity
- **Applies when:** A read-bound loop-free kernel on a grid of 10^5 or more one-wave workgroups where s_endpgm-first probes at 50+ us
- **How:** edit: insert s_endpgm at index 0; probe; compare with a real body at 1/2 and 1/4 of the workgroups
- **Measured:** mo_reduce_sum: launch only 58.1 us, no-load 61.5 us, full 84.4 us; 1/4 of the workgroups 91.5 us, 1/2 87.1 us, coarsen 2 85.5 us
- **Session:** 2026-11-21 06:48

## Masked store of DPP row sums without v_readlane

- **Verdict:** parity
- **Applies when:** One wave produces 4 outputs, one per 16-lane DPP row
- **How:** after the row_mirror step every lane holds its row sum: s_mov_b64 exec, s[m:m+1] with m = 0x00010001_00010001 (AND a v_cmp_gt_u32_e64 range mask in the tail), global_store_dword v_off, v4, s[out] with v_off = lane >> 2
- **Measured:** mo_reduce_sum a264b0e365e1a3bf: battery 49/49; timing dominated by bytes per wave (0.922)
- **Session:** 2026-11-21 06:48

## Block-256 DPP body at 16 waves per CU

- **Verdict:** parity
- **Applies when:** Hand-written 4-wave workgroup, each wave one x4 load and its own output, on a read-bound reduction
- **How:** relaunch(da5124c2c397d615, lds 16384)
- **Measured:** mo_reduce_sum 61c206f45a1aa9a7: 0.989 (0.984..0.999) against 0.993 without the reservation
- **Session:** 2026-11-21 06:48

## Larger blocks with one output and 1 KB per wave on a one-wave-per-output reduction

- **Verdict:** loses
- **Applies when:** Loop-free reduction at the read floor where each wave issues one global_load_dwordx4 per lane (1 KB) and writes its own output, launched as one wave per workgroup on a grid of hundreds of thousands of workgroups; launch-only probe is a large share of the time
- **How:** Same hand-written body, output index o = W*wg + (tid >> 6) via v_readfirstlane_b32 + s_lshr_b32 + s_lshl_b32 s2, s2, log2(W) + s_add_u32; relaunch with block 64*W and grid cdiv(outputs, W)
- **Measured:** mo_reduce_sum: W=4 0.993 (earlier), W=8 5cbcb581f60b6bdf 0.963 (0.957..0.967), W=16 692e439d627d0e4c 0.910 (0.901..0.916), 60 pairs
- **Session:** 2026-11-21 06:51

## LDS reservation of 32 to 40 KB on a block-512 body whose waves do not share anything

- **Verdict:** loses
- **Applies when:** Block-512 loop-free read-bound body, 8 waves x 1 KB, no LDS or barrier use; the rb_dot / rb_nrm2 reservation gain is the hope
- **How:** relaunch(id, {grid, block: [512,1,1], lds: 32768 | 40960}), code unchanged
- **Measured:** mo_reduce_sum: 32 KB c7a740daffab5df1 0.956 (0.945..0.964); 40 KB c79df1a08d4f6296 0.965 (0.960..0.972); no reservation 0.963
- **Session:** 2026-11-21 06:51

## Two dwordx2 loads 512 B apart in place of one dwordx4 per lane

- **Verdict:** parity
- **Applies when:** One-wave-per-workgroup body reading 1 KB contiguous with one global_load_dwordx4 v, lane*16, s[base]; read-only kernel (no store stream)
- **How:** v8 = lane << 3; global_load_dwordx2 v[4:5], v8, s[4:5]; global_load_dwordx2 v[6:7], v8, s[4:5] offset:512; one s_waitcnt vmcnt(0)
- **Measured:** mo_reduce_sum 1284a13d4c13e20c: 0.996 (0.989..1.003), 60 pairs
- **Session:** 2026-11-21 06:51

## Streaming a tile through scalar loads

- **Verdict:** loses
- **Applies when:** Considering s_load_dwordx16 as an alternative memory path for contiguous per-wave data that is consumed once
- **How:** exec = 1; 4 rounds of 4 s_load_dwordx16 into s16..s79 (offsets 0..960), s_waitcnt lgkmcnt(0), 64 v_add_f32_e32 v4, sK, v4 per round; store from lane 0
- **Measured:** mo_reduce_sum f3c82af1c511ca08: 0.224 (0.222..0.225), 377 us against 84 us
- **Session:** 2026-11-21 06:51

## 2D grid for a very large one-wave-per-workgroup launch

- **Verdict:** parity
- **Applies when:** Hundreds of thousands of one-wave workgroups in a 1D grid and a launch-only probe that is most of the kernel's time
- **How:** source: o = blockIdx.y * 1024 + blockIdx.x, grid [1024, cdiv(outputs, 1024), 1], body unchanged (out-of-range workgroups fall through the existing guards)
- **Measured:** mo_reduce_sum 1cb52bbe1c23dff2: 1.002 (0.993..1.005), 60 pairs
- **Session:** 2026-11-21 06:51
