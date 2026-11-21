	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_merge_states
	.globl	fi_merge_states
	.p2align	8
	.type	fi_merge_states,@function
fi_merge_states:
	s_load_dword s26, s[0:1], 0x30
	s_mov_b64 s[22:23], exec
	s_mov_b32 s27, s0
	s_mov_b32 s28, s1
	v_mov_b32_e32 v56, v0
	v_mov_b32_e32 v57, v1
	s_lshl_b32 s25, s2, 1
	s_mov_b32 s24, 0
	s_waitcnt lgkmcnt(0)
.Lagc_wg_head:
	s_add_u32 s2, s25, s24
	s_cmp_ge_u32 s2, s26
	s_cbranch_scc1 .Lagc_wg_exit
.Lft7:
	s_mov_b64 exec, s[22:23]
	s_mov_b32 s0, s27
	s_mov_b32 s1, s28
	v_mov_b32_e32 v0, v56
	v_mov_b32_e32 v1, v57
.Lagc_wg_body:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx4 s[12:15], s[0:1], 0x20
	v_and_b32_e32 v16, 0x3ff, v0
	v_bfe_u32 v17, v0, 10, 10
	s_mov_b64 s[18:19], -1
	s_mov_b64 s[0:1], 0
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s12, 1
	s_mov_b64 s[16:17], 0
	s_cbranch_scc0 .LBB0_5
.Lft0:
	s_and_b64 vcc, exec, s[18:19]
	s_cbranch_vccnz .LBB0_10
.LBB0_2:
	s_andn2_b64 vcc, exec, s[16:17]
	v_lshlrev_b32_e32 v2, 4, v16
	s_cbranch_vccz .LBB0_11
.LBB0_3:
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_18
.LBB0_4:
	s_branch .Lagc_wg_latch
.LBB0_5:
	s_cmp_eq_u32 s12, 1
	s_mov_b64 s[16:17], -1
	s_cbranch_scc0 .LBB0_9
.Lft1:
	s_mul_i32 s3, s13, s2
	v_add_u32_e32 v0, s3, v17
	v_mul_lo_u32 v2, v0, s14
	v_mov_b32_e32 v3, 0
	v_lshlrev_b64 v[4:5], 2, v[2:3]
	v_lshl_add_u64 v[6:7], s[4:5], 0, v[4:5]
	v_lshlrev_b32_e32 v2, 4, v16
	v_lshl_add_u64 v[6:7], v[6:7], 0, v[2:3]
	global_load_dwordx4 v[6:9], v[6:7], off
	s_cmp_lg_u64 s[10:11], 0
	v_cmp_eq_u32_e32 vcc, 0, v16
	s_cselect_b64 s[18:19], -1, 0
	v_lshl_add_u64 v[4:5], s[8:9], 0, v[4:5]
	s_mov_b64 s[16:17], 0
	v_lshl_add_u64 v[4:5], v[4:5], 0, v[2:3]
	s_and_b64 s[20:21], vcc, s[18:19]
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[4:5], v[6:9], off
	s_and_saveexec_b64 s[18:19], s[20:21]
	s_cbranch_execz .LBB0_8
.Lft2:
	v_mov_b32_e32 v1, v3
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	v_lshl_add_u64 v[2:3], s[6:7], 0, v[0:1]
	global_load_dword v2, v[2:3], off
	v_lshl_add_u64 v[0:1], s[10:11], 0, v[0:1]
	s_waitcnt vmcnt(0)
	global_store_dword v[0:1], v2, off
.LBB0_8:
	s_or_b64 exec, exec, s[18:19]
.LBB0_9:
	s_branch .LBB0_2
.LBB0_10:
	s_cmp_lg_u32 s12, 0
	s_mov_b64 s[0:1], -1
	s_cselect_b64 s[16:17], -1, 0
	s_andn2_b64 vcc, exec, s[16:17]
	v_lshlrev_b32_e32 v2, 4, v16
	s_cbranch_vccnz .LBB0_3
.LBB0_11:
	s_mul_i32 s15, s12, s2
	s_add_i32 s0, s15, 1
	s_mul_i32 s16, s13, s0
	s_mul_i32 s3, s2, s13
	v_mov_b32_e32 v11, 0
	v_add_u32_e32 v1, s16, v17
	s_mul_i32 s18, s3, s12
	v_mov_b32_e32 v3, v11
	v_mul_lo_u32 v12, s14, v1
	s_mul_i32 s0, s14, s13
	v_add_u32_e32 v1, s18, v17
	v_lshlrev_b32_e32 v0, 2, v16
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[2:3]
	s_and_b32 s4, s12, -2
	s_lshl_b32 s5, s13, 1
	s_lshl_b32 s17, s0, 1
	v_mul_lo_u32 v14, s14, v1
	v_mov_b32_e32 v1, 1.0
	v_mov_b32_e32 v3, 0xff800000
	s_mov_b32 s19, 0xc2fc0000
	v_mov_b32_e32 v19, 0x42800000
	v_not_b32_e32 v20, 63
	v_mov_b32_e32 v18, v17
	v_mov_b32_e32 v4, v11
	v_mov_b32_e32 v5, v11
	v_mov_b32_e32 v6, v11
	v_mov_b32_e32 v7, v11
	s_cmp_lt_u32 s4, 4
	s_cbranch_scc1 .LBB0_12
.LQ:
	v_mov_b32_e32 v15, v11
	v_mov_b32_e32 v13, v11
	v_lshl_add_u64 v[48:49], v[14:15], 2, v[8:9]
	v_lshl_add_u64 v[50:51], v[12:13], 2, v[8:9]
	v_add_u32_e32 v14, s17, v14
	v_add_u32_e32 v12, s17, v12
	v_lshl_add_u64 v[52:53], v[14:15], 2, v[8:9]
	v_lshl_add_u64 v[54:55], v[12:13], 2, v[8:9]
	v_add_u32_e32 v14, s17, v14
	v_add_u32_e32 v12, s17, v12
	v_add_u32_e32 v10, s18, v18
	v_lshl_add_u64 v[22:23], v[10:11], 2, s[6:7]
	v_add_u32_e32 v10, s16, v18
	v_lshl_add_u64 v[30:31], v[10:11], 2, s[6:7]
	v_add_u32_e32 v18, s5, v18
	v_add_u32_e32 v10, s18, v18
	v_lshl_add_u64 v[32:33], v[10:11], 2, s[6:7]
	v_add_u32_e32 v10, s16, v18
	v_lshl_add_u64 v[46:47], v[10:11], 2, s[6:7]
	v_add_u32_e32 v18, s5, v18
	global_load_dword v15, v[22:23], off
	global_load_dword v10, v[30:31], off
	global_load_dword v35, v[32:33], off
	global_load_dword v36, v[46:47], off
	global_load_dwordx4 v[22:25], v[48:49], off
	global_load_dwordx4 v[26:29], v[50:51], off
	global_load_dwordx4 v[38:41], v[52:53], off
	global_load_dwordx4 v[42:45], v[54:55], off
	s_add_i32 s4, s4, -4
	v_max_f32_e32 v13, v3, v3
	s_waitcnt vmcnt(7)
	v_max_f32_e32 v21, v15, v15
	v_max_f32_e32 v13, v13, v21
	s_waitcnt vmcnt(6)
	v_max_f32_e32 v21, v10, v10
	v_sub_f32_e32 v30, v3, v13
	v_sub_f32_e32 v15, v15, v13
	v_max_f32_e32 v3, v13, v21
	v_max_f32_e32 v21, 0xff800000, v30
	v_max_f32_e32 v15, 0xff800000, v15
	v_sub_f32_e32 v13, v13, v3
	v_sub_f32_e32 v10, v10, v3
	v_cmp_gt_f32_e32 vcc, s19, v21
	v_cmp_gt_f32_e64 s[0:1], s19, v15
	v_max_f32_e32 v13, 0xff800000, v13
	v_cndmask_b32_e32 v30, 0, v19, vcc
	v_cndmask_b32_e64 v31, 0, v19, s[0:1]
	v_max_f32_e32 v10, 0xff800000, v10
	v_add_f32_e32 v21, v21, v30
	v_cndmask_b32_e32 v30, 0, v20, vcc
	v_add_f32_e32 v15, v15, v31
	v_cndmask_b32_e64 v31, 0, v20, s[0:1]
	v_cmp_gt_f32_e32 vcc, s19, v13
	v_cmp_gt_f32_e64 s[0:1], s19, v10
	v_exp_f32_e32 v21, v21
	v_cndmask_b32_e32 v32, 0, v19, vcc
	v_cndmask_b32_e64 v33, 0, v19, s[0:1]
	v_exp_f32_e32 v15, v15
	v_add_f32_e32 v13, v13, v32
	v_add_f32_e32 v10, v10, v33
	v_exp_f32_e32 v13, v13
	v_exp_f32_e32 v34, v10
	v_cndmask_b32_e32 v32, 0, v20, vcc
	v_cndmask_b32_e64 v33, 0, v20, s[0:1]
	v_ldexp_f32 v10, v21, v30
	v_ldexp_f32 v30, v15, v31
	v_fma_f32 v1, v1, v10, v30
	s_waitcnt vmcnt(3)
	v_pk_mul_f32 v[22:23], v[22:23], v[30:31] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[24:25], v[30:31] op_sel_hi:[1,0]
	v_ldexp_f32 v30, v13, v32
	v_ldexp_f32 v32, v34, v33
	v_pk_fma_f32 v[6:7], v[6:7], v[10:11], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[10:11], v[24:25] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[22:23], v[26:27], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[28:29], v[32:33] op_sel_hi:[1,0]
	v_fma_f32 v1, v1, v30, v32
	v_pk_fma_f32 v[6:7], v[6:7], v[30:31], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[30:31], v[24:25] op_sel_hi:[1,0,1]
	v_max_f32_e32 v13, v3, v3
	v_max_f32_e32 v21, v35, v35
	v_max_f32_e32 v13, v13, v21
	v_max_f32_e32 v21, v36, v36
	v_sub_f32_e32 v30, v3, v13
	v_sub_f32_e32 v35, v35, v13
	v_max_f32_e32 v3, v13, v21
	v_max_f32_e32 v21, 0xff800000, v30
	v_max_f32_e32 v35, 0xff800000, v35
	v_sub_f32_e32 v13, v13, v3
	v_sub_f32_e32 v36, v36, v3
	v_cmp_gt_f32_e32 vcc, s19, v21
	v_cmp_gt_f32_e64 s[0:1], s19, v35
	v_max_f32_e32 v13, 0xff800000, v13
	v_cndmask_b32_e32 v30, 0, v19, vcc
	v_cndmask_b32_e64 v31, 0, v19, s[0:1]
	v_max_f32_e32 v36, 0xff800000, v36
	v_add_f32_e32 v21, v21, v30
	v_cndmask_b32_e32 v30, 0, v20, vcc
	v_add_f32_e32 v35, v35, v31
	v_cndmask_b32_e64 v31, 0, v20, s[0:1]
	v_cmp_gt_f32_e32 vcc, s19, v13
	v_cmp_gt_f32_e64 s[0:1], s19, v36
	v_exp_f32_e32 v21, v21
	v_cndmask_b32_e32 v32, 0, v19, vcc
	v_cndmask_b32_e64 v33, 0, v19, s[0:1]
	v_exp_f32_e32 v35, v35
	v_add_f32_e32 v13, v13, v32
	v_add_f32_e32 v36, v36, v33
	v_exp_f32_e32 v13, v13
	v_exp_f32_e32 v34, v36
	v_cndmask_b32_e32 v32, 0, v20, vcc
	v_cndmask_b32_e64 v33, 0, v20, s[0:1]
	v_ldexp_f32 v10, v21, v30
	v_ldexp_f32 v30, v35, v31
	v_fma_f32 v1, v1, v10, v30
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[22:23], v[38:39], v[30:31] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[40:41], v[30:31] op_sel_hi:[1,0]
	v_ldexp_f32 v30, v13, v32
	v_ldexp_f32 v32, v34, v33
	v_pk_fma_f32 v[6:7], v[6:7], v[10:11], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[10:11], v[24:25] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[22:23], v[42:43], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[44:45], v[32:33] op_sel_hi:[1,0]
	v_fma_f32 v1, v1, v30, v32
	v_pk_fma_f32 v[6:7], v[6:7], v[30:31], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[30:31], v[24:25] op_sel_hi:[1,0,1]
	s_cmp_lt_u32 s4, 4
	s_cbranch_scc0 .LQ
.LQX:
	s_cmp_eq_u32 s4, 0
	s_cbranch_scc1 .Lft3
.LBB0_12:
	v_add_u32_e32 v10, s18, v18
	v_mov_b32_e32 v15, v11
	v_lshl_add_u64 v[22:23], v[10:11], 2, s[6:7]
	v_lshl_add_u64 v[30:31], v[14:15], 2, v[8:9]
	v_add_u32_e32 v10, s16, v18
	global_load_dword v15, v[22:23], off
	v_lshl_add_u64 v[22:23], v[10:11], 2, s[6:7]
	global_load_dword v10, v[22:23], off
	v_mov_b32_e32 v13, v11
	v_lshl_add_u64 v[32:33], v[12:13], 2, v[8:9]
	global_load_dwordx4 v[22:25], v[30:31], off
	global_load_dwordx4 v[26:29], v[32:33], off
	v_max_f32_e32 v13, v3, v3
	s_add_i32 s4, s4, -2
	v_add_u32_e32 v18, s5, v18
	v_add_u32_e32 v12, s17, v12
	v_add_u32_e32 v14, s17, v14
	s_cmp_eq_u32 s4, 0
	s_waitcnt vmcnt(3)
	v_max_f32_e32 v21, v15, v15
	v_max_f32_e32 v13, v13, v21
	s_waitcnt vmcnt(2)
	v_max_f32_e32 v21, v10, v10
	v_sub_f32_e32 v30, v3, v13
	v_sub_f32_e32 v15, v15, v13
	v_max_f32_e32 v3, v13, v21
	v_max_f32_e32 v21, 0xff800000, v30
	v_max_f32_e32 v15, 0xff800000, v15
	v_sub_f32_e32 v13, v13, v3
	v_sub_f32_e32 v10, v10, v3
	v_cmp_gt_f32_e32 vcc, s19, v21
	v_cmp_gt_f32_e64 s[0:1], s19, v15
	v_max_f32_e32 v13, 0xff800000, v13
	v_cndmask_b32_e32 v30, 0, v19, vcc
	v_cndmask_b32_e64 v31, 0, v19, s[0:1]
	v_max_f32_e32 v10, 0xff800000, v10
	v_add_f32_e32 v21, v21, v30
	v_cndmask_b32_e32 v30, 0, v20, vcc
	v_add_f32_e32 v15, v15, v31
	v_cndmask_b32_e64 v31, 0, v20, s[0:1]
	v_cmp_gt_f32_e32 vcc, s19, v13
	v_cmp_gt_f32_e64 s[0:1], s19, v10
	v_exp_f32_e32 v21, v21
	v_cndmask_b32_e32 v32, 0, v19, vcc
	v_cndmask_b32_e64 v33, 0, v19, s[0:1]
	v_exp_f32_e32 v15, v15
	v_add_f32_e32 v13, v13, v32
	v_add_f32_e32 v10, v10, v33
	v_exp_f32_e32 v13, v13
	v_exp_f32_e32 v34, v10
	v_cndmask_b32_e32 v32, 0, v20, vcc
	v_cndmask_b32_e64 v33, 0, v20, s[0:1]
	v_ldexp_f32 v10, v21, v30
	v_ldexp_f32 v30, v15, v31
	v_fma_f32 v1, v1, v10, v30
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[22:23], v[22:23], v[30:31] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[24:25], v[30:31] op_sel_hi:[1,0]
	v_ldexp_f32 v30, v13, v32
	v_ldexp_f32 v32, v34, v33
	v_pk_fma_f32 v[6:7], v[6:7], v[10:11], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[10:11], v[24:25] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[22:23], v[26:27], v[32:33] op_sel_hi:[1,0]
	v_pk_mul_f32 v[24:25], v[28:29], v[32:33] op_sel_hi:[1,0]
	v_fma_f32 v1, v1, v30, v32
	v_pk_fma_f32 v[6:7], v[6:7], v[30:31], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[30:31], v[24:25] op_sel_hi:[1,0,1]
	s_cbranch_scc0 .LBB0_12
.Lft3:
	s_bitcmp0_b32 s12, 0
	s_cbranch_scc1 .LBB0_15
.Lft4:
	s_add_i32 s15, s15, -1
	s_mul_i32 s0, s13, s15
	s_add_i32 s0, s13, s0
	v_add_u32_e32 v10, s0, v18
	v_mov_b32_e32 v11, 0
	v_lshl_add_u64 v[12:13], v[10:11], 2, s[6:7]
	global_load_dword v12, v[12:13], off
	v_mul_lo_u32 v10, v10, s14
	v_lshl_add_u64 v[8:9], v[10:11], 2, v[8:9]
	global_load_dwordx4 v[8:11], v[8:9], off
	v_max_f32_e32 v13, v3, v3
	s_mov_b32 s0, 0xc2fc0000
	v_mov_b32_e32 v14, 0x42800000
	v_not_b32_e32 v15, 63
	s_waitcnt vmcnt(1)
	v_max_f32_e32 v18, v12, v12
	v_max_f32_e32 v13, v13, v18
	v_sub_f32_e32 v3, v3, v13
	v_sub_f32_e32 v12, v12, v13
	v_max_f32_e32 v3, 0xff800000, v3
	v_max_f32_e32 v12, 0xff800000, v12
	v_cmp_gt_f32_e32 vcc, s0, v3
	v_cmp_gt_f32_e64 s[0:1], s0, v12
	s_nop 0
	v_cndmask_b32_e32 v18, 0, v14, vcc
	v_cndmask_b32_e64 v14, 0, v14, s[0:1]
	v_add_f32_e32 v12, v12, v14
	v_add_f32_e32 v3, v3, v18
	v_exp_f32_e32 v14, v12
	v_exp_f32_e32 v3, v3
	v_cndmask_b32_e32 v12, 0, v15, vcc
	v_cndmask_b32_e64 v15, 0, v15, s[0:1]
	v_ldexp_f32 v14, v14, v15
	v_ldexp_f32 v12, v3, v12
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[8:9], v[8:9], v[14:15] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], v[14:15] op_sel_hi:[1,0]
	v_fma_f32 v1, v1, v12, v14
	v_pk_fma_f32 v[6:7], v[6:7], v[12:13], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[4:5], v[12:13], v[10:11] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v3, v13
.LBB0_15:
	v_div_scale_f32 v8, s[0:1], v1, v1, 1.0
	v_rcp_f32_e32 v9, v8
	v_div_scale_f32 v10, vcc, 1.0, v1, 1.0
	s_cmp_lg_u64 s[10:11], 0
	s_cselect_b64 s[4:5], -1, 0
	v_fma_f32 v11, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v11, v9
	v_mul_f32_e32 v11, v10, v9
	v_fma_f32 v12, -v8, v11, v10
	v_fmac_f32_e32 v11, v12, v9
	v_fma_f32 v8, -v8, v11, v10
	v_div_fmas_f32 v8, v8, v9, v11
	v_div_fixup_f32 v8, v8, v1, 1.0
	v_cmp_lt_f32_e32 vcc, 0, v1
	v_mov_b32_e32 v11, 0
	s_mov_b64 s[0:1], 0
	v_cndmask_b32_e32 v14, 0, v8, vcc
	v_add_u32_e32 v8, s3, v17
	v_mul_lo_u32 v10, v8, s14
	v_lshl_add_u64 v[12:13], v[10:11], 2, s[8:9]
	v_lshlrev_b32_e32 v10, 2, v0
	v_cmp_eq_u32_e32 vcc, 0, v16
	v_lshl_add_u64 v[18:19], v[12:13], 0, v[10:11]
	v_pk_mul_f32 v[12:13], v[6:7], v[14:15] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[4:5], v[14:15] op_sel_hi:[1,0]
	s_and_b64 s[6:7], vcc, s[4:5]
	global_store_dwordx4 v[18:19], v[12:15], off
	s_and_saveexec_b64 s[4:5], s[6:7]
	s_cbranch_execz .LBB0_17
.Lft5:
	s_mov_b32 s3, 0x800000
	v_cmp_gt_f32_e32 vcc, s3, v1
	v_mov_b32_e32 v0, 0x42000000
	v_mov_b32_e32 v9, v11
	v_cndmask_b32_e64 v4, 0, 32, vcc
	v_ldexp_f32 v1, v1, v4
	v_log_f32_e32 v1, v1
	v_cndmask_b32_e32 v0, 0, v0, vcc
	v_sub_f32_e32 v0, v1, v0
	v_add_f32_e32 v3, v3, v0
	v_lshl_add_u64 v[0:1], v[8:9], 2, s[10:11]
	global_store_dword v[0:1], v3, off
.LBB0_17:
	s_or_b64 exec, exec, s[4:5]
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_4
.LBB0_18:
	s_mul_i32 s0, s13, s2
	v_add_u32_e32 v4, s0, v17
	v_mul_lo_u32 v0, v4, s14
	v_mov_b32_e32 v1, 0
	s_cmp_lg_u64 s[10:11], 0
	v_lshl_add_u64 v[6:7], v[0:1], 2, s[8:9]
	v_mov_b32_e32 v3, v1
	v_cmp_eq_u32_e32 vcc, 0, v16
	s_cselect_b64 s[0:1], -1, 0
	v_lshl_add_u64 v[6:7], v[6:7], 0, v[2:3]
	v_mov_b32_e32 v0, v1
	v_mov_b32_e32 v2, v1
	s_and_b64 s[0:1], vcc, s[0:1]
	global_store_dwordx4 v[6:7], v[0:3], off
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_4
.Lft6:
	v_mov_b32_e32 v5, v1
	v_lshl_add_u64 v[0:1], v[4:5], 2, s[10:11]
	v_mov_b32_e32 v2, 0xff800000
	global_store_dword v[0:1], v2, off
.Lagc_wg_latch:
	s_add_u32 s24, s24, 1
	s_cmp_lt_u32 s24, 2
	s_cbranch_scc1 .Lagc_wg_head
.Lagc_wg_exit:
	s_endpgm
.Lfunc_end0:
	.size	fi_merge_states, .Lfunc_end0-fi_merge_states
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_merge_states
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 1
		.amdhsa_next_free_vgpr 58
		.amdhsa_next_free_sgpr 29
		.amdhsa_accum_offset 60
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
- .agpr_count: 0
  .args:
  - .actual_access: read_only
    .address_space: global
    .offset: 0
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .offset: 32
    .size: 4
    .value_kind: by_value
  - .offset: 36
    .size: 4
    .value_kind: by_value
  - .offset: 40
    .size: 4
    .value_kind: by_value
  - .offset: 48
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 56
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: fi_merge_states
  .private_segment_fixed_size: 0
  .sgpr_count: 35
  .sgpr_spill_count: 0
  .symbol: fi_merge_states.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 58
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
