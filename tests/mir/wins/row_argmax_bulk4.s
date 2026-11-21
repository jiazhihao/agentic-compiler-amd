; row_argmax: state 'bulk4' of the M9 agent session (docs/progress.md). Kernel body only; apply with
;   agc run tests/kernels/row_argmax.json --edit tests/mir/wins/row_argmax_bulk4.s
row_argmax:
	s_load_dword s12, s[0:1], 0x14
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_mov_b32 s3, 0
	v_mov_b32_e32 v2, 0xff800000
	v_bfrev_b32_e32 v3, -2
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_i32_e32 vcc, s12, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_4
.Lft0:
	s_ashr_i32 s4, s12, 31
	s_mul_hi_u32 s5, s12, s2
	s_mul_i32 s4, s4, s2
	s_add_i32 s5, s5, s4
	s_mul_i32 s4, s12, s2
	s_lshl_b64 s[4:5], s[4:5], 2
	s_add_u32 s4, s8, s4
	v_lshlrev_b32_e32 v2, 2, v0
	v_mov_b32_e32 v3, 0
	s_addc_u32 s5, s9, s5
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	s_mov_b64 s[4:5], 0
	v_bfrev_b32_e32 v3, -2
	v_mov_b32_e32 v2, 0xff800000
	s_mov_b64 s[6:7], 0x400
	v_mov_b32_e32 v1, v0
	s_lshr_b32 s13, s12, 8
	s_mov_b64 s[14:15], 0x1000
	s_cmp_lt_u32 s13, 4
	s_cbranch_scc1 .Lrest
.Lbulk:
	global_load_dword v6, v[4:5], off
	global_load_dword v7, v[4:5], off offset:1024
	global_load_dword v8, v[4:5], off offset:2048
	global_load_dword v9, v[4:5], off offset:3072
	s_add_i32 s13, s13, -4
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[14:15]
	s_cmp_lt_u32 s13, 4
	s_waitcnt vmcnt(3)
	v_cmp_gt_f32_e32 vcc, v6, v2
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v1, vcc
	v_cndmask_b32_e32 v2, v2, v6, vcc
	v_add_u32_e32 v1, 0x100, v1
	s_waitcnt vmcnt(2)
	v_cmp_gt_f32_e32 vcc, v7, v2
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v1, vcc
	v_cndmask_b32_e32 v2, v2, v7, vcc
	v_add_u32_e32 v1, 0x100, v1
	s_waitcnt vmcnt(1)
	v_cmp_gt_f32_e32 vcc, v8, v2
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v1, vcc
	v_cndmask_b32_e32 v2, v2, v8, vcc
	v_add_u32_e32 v1, 0x100, v1
	s_waitcnt vmcnt(0)
	v_cmp_gt_f32_e32 vcc, v9, v2
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v1, vcc
	v_cndmask_b32_e32 v2, v2, v9, vcc
	v_add_u32_e32 v1, 0x100, v1
	s_cbranch_scc0 .Lbulk
.Lrest:
	v_cmp_le_i32_e32 vcc, s12, v1
	s_or_b64 s[4:5], vcc, s[4:5]
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execz .Lft1
	.p2align 5, , 4
.LBB0_2:
	global_load_dword v6, v[4:5], off
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[6:7]
	s_waitcnt vmcnt(0)
	v_cmp_gt_f32_e32 vcc, v6, v2
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v1, vcc
	v_add_u32_e32 v1, 0x100, v1
	v_cndmask_b32_e32 v2, v2, v6, vcc
	v_cmp_le_i32_e32 vcc, s12, v1
	s_or_b64 s[4:5], vcc, s[4:5]
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execnz .LBB0_2
.Lft1:
	s_or_b64 exec, exec, s[4:5]
.LBB0_4:
	s_or_b64 exec, exec, s[0:1]
	s_movk_i32 s0, 0x80
	v_lshlrev_b32_e32 v1, 3, v0
	v_cmp_gt_u32_e32 vcc, s0, v0
	ds_write_b64 v1, v[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_6
.Lft2:
	ds_read2st64_b64 v[2:5], v1 offset1:2
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_6:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_8
.Lft3:
	ds_read2st64_b64 v[2:5], v1 offset1:1
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_8:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_10
.Lft4:
	ds_read2_b64 v[2:5], v1 offset1:32
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_10:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_12
.Lft5:
	ds_read2_b64 v[2:5], v1 offset1:16
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_12:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_14
.Lft6:
	ds_read2_b64 v[2:5], v1 offset1:8
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_14:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_16
.Lft7:
	ds_read2_b64 v[2:5], v1 offset1:4
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_16:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_18
.Lft8:
	ds_read2_b64 v[2:5], v1 offset1:2
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[0:1], v2, v4
	v_cmp_lt_i32_e64 s[4:5], v5, v3
	v_cmp_lt_f32_e32 vcc, v2, v4
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_or_b64 vcc, vcc, s[0:1]
	v_cndmask_b32_e32 v3, v3, v5, vcc
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b64 v1, v[2:3]
.LBB0_18:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_20
.Lft9:
	ds_read2_b64 v[2:5], v1 offset1:1
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[4:5], v2, v4
	v_cmp_lt_i32_e64 s[6:7], v5, v3
	v_cmp_lt_f32_e64 s[0:1], v2, v4
	s_and_b64 s[4:5], s[4:5], s[6:7]
	s_or_b64 s[0:1], s[0:1], s[4:5]
	v_cndmask_b32_e64 v3, v3, v5, s[0:1]
	v_cndmask_b32_e64 v2, v2, v4, s[0:1]
	ds_write_b64 v1, v[2:3]
.LBB0_20:
	s_or_b64 exec, exec, s[8:9]
	v_mov_b32_e32 v0, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v1, v0 offset:4
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_22
.Lft10:
	s_lshl_b64 s[0:1], s[2:3], 2
	s_add_u32 s0, s10, s0
	s_addc_u32 s1, s11, s1
	global_store_dword v0, v1, s[0:1]
.LBB0_22:
	s_endpgm
