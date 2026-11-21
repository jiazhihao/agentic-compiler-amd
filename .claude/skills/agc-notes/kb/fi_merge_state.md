# Knowledge-base entries from `fi_merge_state`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## One row per wave at 8 B per lane (512 B per stream per wave) with an exact grid and scalar addressing (third kernel)

- **Verdict:** pays
- **Applies when:** Loop-free touch-once row kernel whose amdclang build puts two 32-lane rows in a wave with global_load_dwordx4 per lane (1 KB per stream per wave), row length 512 B, per-row scalars loaded per lane with global_load_dword, headroom about 1.1
- **How:** edit_ir, block 64, grid = rows: row = s2; scalar bases by s_mul_i32 row*head_dim, s_lshl_b64 by 2, s_add_u32/s_addc_u32 onto each pointer; v8 = tid << 3; global_load_dwordx2 v[4:5], v8, s[base] for each stream; per-row scalars by s_load_dword from base + row*4 then v_mov_b32 into VGPRs; amdclang's arithmetic unchanged (one v_pk_mul + one v_pk_fma instead of two each); global_store_dwordx2 v8, v[4:5], s[base]; per-row output from lane 0 after s_mov_b64 exec, 1. No bounds mask because the grid is exact.
- **Measured:** fi_merge_state 912225486e161830: 1.039 (CI 1.035..1.044, 240 pairs), 1.037 (120 pairs); bit-identical to the baseline
- **Session:** 2026-11-21 08:30

## Waves per workgroup on the one-row-per-wave body

- **Verdict:** parity
- **Applies when:** Wave-uniform row body launched as one wave per workgroup on about 262144 workgroups, memory floor
- **How:** v_lshrrev_b32 v1, 6, v0; v_readfirstlane_b32 s20, v1; row = (s2 << k) + s20; s_cmp_lt_u32 row, total + s_cbranch_scc0 to the end; relaunch block 128 (k=1) or 256 (k=2), grid cdiv(rows, 2 or 4)
- **Measured:** fi_merge_state: block 128 744c49e670e2b8b3 1.028 (1.023..1.031, 240 pairs); block 256 c7c98abb4218e736 1.030 (1.025..1.037); block 64 1.039
- **Session:** 2026-11-21 08:30

## amdclang's two-rows-per-wave body at block 128 and 256

- **Verdict:** parity
- **Applies when:** Loop-free row kernel compiled with row = blockIdx.x * (BLK/32) + (t >> 5); only the shift in v_lshl_add_u32 depends on BLK
- **How:** edit the shift (1 -> 2 or 3) and relaunch with block 128 / 256 and grid cdiv(P*H*32, block)
- **Measured:** fi_merge_state: d2d97f12f13a6e7d 0.999 (0.992..1.005); 2e73d186c5c6dce5 0.990 (0.984..1.001), 120 pairs
- **Session:** 2026-11-21 08:30

## coarsen 2 on a hand-written one-row-per-wave body

- **Verdict:** loses
- **Applies when:** One 512 B tile per stream per wave, exact grid, memory floor; idea is to halve the 262144 workgroups
- **How:** apply(coarsen, factor 2)
- **Measured:** fi_merge_state 667139cf7cf3bdd9: 0.971 (0.963..0.977, 120 pairs); on amdclang's body coarsen 2/4/8 were 0.978 / 0.950 / 0.955
- **Session:** 2026-11-21 08:30

## Issue the row loads before the per-row scalar loads

- **Verdict:** parity
- **Applies when:** Short wave that needs two s_load_dword for per-row scalars and two wide row loads; idea is to get the large loads in flight a few instructions earlier
- **How:** move the s_add/s_addc + s_load_dword group after the two global_load_dwordx2
- **Measured:** fi_merge_state d9194c01399ea06c: 1.028 (1.021..1.034, 240 pairs) against 1.039 for the parent
- **Session:** 2026-11-21 08:30

## Time split of a row merge with per-row transcendental scale

- **Verdict:** parity
- **Applies when:** Loop-free 2-in / 1-out row kernel with exp2 / rcp / log per row, headroom about 1.1
- **How:** probe with the body after the bounds branch replaced by s_nop; with the store deleted; with the per-row loads and the scale arithmetic deleted
- **Measured:** fi_merge_state: total 101..103 us; empty 31.2 us; no store 90.4 us; no scale math and no s loads 98.9 us: the arithmetic is 3 us, the row loads about 57 us
- **Session:** 2026-11-21 08:30

## Half-wave workgroups: one 512 B row per 32-lane workgroup with dwordx4

- **Verdict:** parity
- **Applies when:** Loop-free touch-once row kernel, row = 512 B, amdclang packs two 32-lane rows per wave with global_load_dwordx4; headroom about 1.1
- **How:** Hand-written body with scalar bases (s_mul_i32 row*head_dim, s_lshl_b64 2, s_add_u32/s_addc_u32), v8 = tid << 4, global_load_dwordx4 v[4:7]/v[20:23], v8, s[base]; 2 v_pk_mul + 2 v_pk_fma; global_store_dwordx4; relaunch block 32, grid = rows (exact, no bounds mask)
- **Measured:** fi_merge_state 25295ae0ece47d67: 1.014 (1.008..1.022, 240 pairs) over the amdclang baseline; 0.993 (0.989..1.002) against the 64-lane dwordx2 body
- **Session:** 2026-11-21 08:37

## Two rows per wave with all four row loads in flight (1 KB per stream per wave as two 512 B tiles)

- **Verdict:** loses
- **Applies when:** One-row-per-wave body at the memory floor with 2 input streams; idea is to halve the waves and keep loads in flight (rb_scal recipe)
- **How:** row1 = s_min_u32(row0+1, total-1); second set of bases; 4 global_load_dwordx2 + 4 s_load_dword before the first wait; math twice in disjoint registers; waits vmcnt(3), (2), store, vmcnt(2), (1), store; grid cdiv(rows, 2)
- **Measured:** fi_merge_state 5e66eafb5ea75e97: 0.980 (0.974..0.989, 120 pairs)
- **Session:** 2026-11-21 08:37

## Software-pipelined rows in one wave (next rows' loads issued before the current store)

- **Verdict:** loses
- **Applies when:** Loop-free touch-once row kernel at the memory floor where an empty-body probe shows a large dispatch share (58 us of 99 us at 262144 one-wave workgroups)
- **How:** 4 rows per wave unrolled with %rep: loads of rows 0,1 up front, then per row: math, pk_mul/pk_fma, loads of row i+2, store row i; fix_waits places vmcnt(3)/(2), (4)/(3), (5)/(4), (3)/(2); rows clamped with s_min_u32; grid cdiv(rows, 4)
- **Measured:** fi_merge_state c08165ec0e64d11b: 0.937 (0.928..0.948, 120 pairs); coarsen 2 on the same body was 0.971
- **Session:** 2026-11-21 08:37

## 16 waves per workgroup to cut workgroup dispatch

- **Verdict:** parity
- **Applies when:** Wave-uniform row body launched as one wave per workgroup; empty-body probe 58 us at 262144 workgroups against 17 us at 16384 x 16 waves
- **How:** row = (s2 << 4) + v_readfirstlane(tid >> 6); s_cmp_lt_u32 row, total; relaunch block 1024, grid cdiv(rows, 16)
- **Measured:** fi_merge_state 8ef7112bced026c9: 1.004 (0.996..1.015, 120 pairs): the dispatch time overlaps the memory time and is not recovered
- **Session:** 2026-11-21 08:37

## 4 B per lane (256 B per stream per wave)

- **Verdict:** loses
- **Applies when:** Touch-once row kernel at the memory floor; idea is that shorter waves stream better than 512 B
- **How:** v8 = tid << 2 over 128 threads, global_load_dword x2, v_mul_f32 + v_fmac_f32, global_store_dword; block 128, grid = rows
- **Measured:** fi_merge_state 858d4ad0debbfd46: 0.963 (0.957..0.968, 120 pairs)
- **Session:** 2026-11-21 08:37

## One s_load_dwordx16 for all kernel arguments

- **Verdict:** parity
- **Applies when:** Short wave whose prologue issues 3 kernarg scalar loads (x8 + x4 + dword) and the kernarg block is <= 64 B
- **How:** s_load_dwordx16 s[36:51], s[0:1], 0x0 and rename the users
- **Measured:** fi_merge_state ee584bdc981f8d5f: 0.999 (0.993..1.007, 240 pairs) against its parent
- **Session:** 2026-11-21 08:37

## One row per wave at 8 B per lane: earlier 1.039 not reproduced

- **Verdict:** parity
- **Applies when:** Same as the earlier entry (two 32-lane rows per wave in amdclang's build, 512 B rows, headroom 1.1)
- **How:** Re-timed 912225486e161830 unchanged
- **Measured:** fi_merge_state: 1.011 (1.003..1.024, 120 pairs) this session, 1.006 (1.001..1.009) in the harness verification, against 1.039 in the session that wrote it
- **Session:** 2026-11-21 08:37
