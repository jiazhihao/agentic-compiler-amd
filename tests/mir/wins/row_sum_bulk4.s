; row_sum: state 'bulk4' of the M5 agent session (docs/progress.md). Kernel body only; apply with
;   agc run tests/kernels/row_sum.json --edit tests/mir/wins/row_sum_bulk4.s
row_sum:
	s_load_dword s10, s[0:1], 0x14
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_mov_b32 s3, 0
	v_mov_b32_e32 v3, 0
	v_lshlrev_b32_e32 v2, 2, v0
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_i32_e32 vcc, s10, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_4
.Lft0:
	s_ashr_i32 s8, s10, 31
	s_mul_hi_u32 s9, s10, s2
	s_mul_i32 s8, s8, s2
	s_add_i32 s9, s9, s8
	s_mul_i32 s8, s10, s2
	s_lshl_b64 s[8:9], s[8:9], 2
	s_add_u32 s4, s4, s8
	s_addc_u32 s5, s5, s9
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	s_mov_b64 s[4:5], 0
	v_mov_b32_e32 v3, 0
	s_mov_b64 s[8:9], 0x400
	v_mov_b32_e32 v1, v0
	s_lshr_b32 s11, s10, 8
	s_mov_b64 s[12:13], 0x1000
	s_cmp_lt_u32 s11, 4
	s_cbranch_scc1 .Lrest
.Lbulk:
	global_load_dword v6, v[4:5], off
	global_load_dword v7, v[4:5], off offset:1024
	global_load_dword v8, v[4:5], off offset:2048
	global_load_dword v9, v[4:5], off offset:3072
	s_add_i32 s11, s11, -4
	v_add_u32_e32 v1, 0x400, v1
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[12:13]
	s_cmp_lt_u32 s11, 4
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v3, v3, v6
	v_add_f32_e32 v3, v3, v7
	v_add_f32_e32 v3, v3, v8
	v_add_f32_e32 v3, v3, v9
	s_cbranch_scc0 .Lbulk
.Lrest:
	v_cmp_le_i32_e32 vcc, s10, v1
	s_or_b64 s[4:5], vcc, s[4:5]
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execz .Lft1
	.p2align 5, , 4
.LBB0_2:
	global_load_dword v6, v[4:5], off
	v_add_u32_e32 v1, 0x100, v1
	v_cmp_le_i32_e32 vcc, s10, v1
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[8:9]
	s_or_b64 s[4:5], vcc, s[4:5]
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v3, v3, v6
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execnz .LBB0_2
.Lft1:
	s_or_b64 exec, exec, s[4:5]
.LBB0_4:
	s_or_b64 exec, exec, s[0:1]
	s_movk_i32 s0, 0x80
	v_cmp_gt_u32_e32 vcc, s0, v0
	ds_write_b32 v2, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_6
.Lft2:
	ds_read2st64_b32 v[4:5], v2 offset1:2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_6:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_8
.Lft3:
	ds_read2st64_b32 v[4:5], v2 offset1:1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_8:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_10
.Lft4:
	ds_read2_b32 v[4:5], v2 offset1:32
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_10:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_12
.Lft5:
	ds_read2_b32 v[4:5], v2 offset1:16
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_12:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_14
.Lft6:
	ds_read2_b32 v[4:5], v2 offset1:8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_14:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_16
.Lft7:
	ds_read2_b32 v[4:5], v2 offset1:4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_16:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_18
.Lft8:
	ds_read2_b32 v[4:5], v2 offset1:2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v2, v1
.LBB0_18:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_20
.Lft9:
	ds_read2_b32 v[0:1], v2 offset1:1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v1
	ds_write_b32 v2, v0
.LBB0_20:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v0, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v1, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_22
.Lft10:
	s_lshl_b64 s[0:1], s[2:3], 2
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s7, s1
	global_store_dword v0, v1, s[0:1]
.LBB0_22:
	s_endpgm
