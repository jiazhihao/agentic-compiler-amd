	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	moe_gate_topk
	.globl	moe_gate_topk
	.p2align	8
	.type	moe_gate_topk,@function
moe_gate_topk:
	s_load_dword s3, s[0:1], 0x34
	s_load_dwordx4 s[12:15], s[0:1], 0x18
	s_waitcnt lgkmcnt(0)
	s_and_b32 s3, s3, 0xffff
	s_mul_i32 s2, s2, s3
	v_add_u32_e32 v16, s2, v0
	v_cmp_gt_i32_e32 vcc, s12, v16
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_49
.Lft0:
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_load_dwordx2 s[16:17], s[0:1], 0x10
	v_mad_i64_i32 v[0:1], s[0:1], v16, s13, 0
	v_ashrrev_i32_e32 v17, 31, v16
	s_cmp_eq_u32 s14, 8
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[26:27], v[0:1], 2, s[8:9]
	s_mov_b64 s[0:1], -1
	s_cbranch_scc1 .LBB0_28
.Lft1:
	s_cmp_gt_i32 s13, 0
	s_cselect_b64 s[2:3], -1, 0
	s_cmp_lt_i32 s13, 1
	v_mov_b32_e32 v20, 0xff800000
	s_cbranch_scc1 .LBB0_12
.Lft2:
	s_cmp_eq_u32 s13, 1
	v_mov_b32_e32 v2, 0
	s_cbranch_scc1 .LBB0_7
.Lft3:
	s_mov_b32 s7, 0
	s_and_b32 s12, s13, 0x7ffffffe
	s_mov_b64 s[4:5], 0
	v_mov_b32_e32 v5, 0xff800000
	s_mov_b32 s6, s7
	v_mov_b32_e32 v6, 0xff800000
	.p2align	5, , 4
.LBB0_5:
	v_lshl_add_u64 v[2:3], s[6:7], 2, v[26:27]
	global_load_dwordx2 v[8:9], v[2:3], off
	v_mov_b32_e32 v2, v5
	v_mov_b32_e32 v3, v6
	v_max_f32_e32 v5, v3, v3
	v_max_f32_e32 v7, v2, v2
	s_add_i32 s15, s6, 2
	s_cmp_eq_u32 s15, s12
	s_cselect_b64 s[18:19], -1, 0
	v_mov_b32_e32 v4, s6
	s_mov_b32 s6, s15
	s_waitcnt vmcnt(0)
	v_cmp_u_f32_e32 vcc, v9, v9
	v_max_f32_e32 v6, v9, v9
	v_max_f32_e32 v10, v8, v8
	v_cndmask_b32_e64 v9, 0, 1, vcc
	v_cmp_u_f32_e32 vcc, v8, v8
	v_max_f32_e32 v6, v5, v6
	v_max_f32_e32 v5, v7, v10
	v_cndmask_b32_e64 v8, 0, 1, vcc
	v_lshlrev_b16_e32 v7, 1, v9
	v_bitop3_b16 v7, v8, 3, v7 bitop3:0xc8
	v_cmp_ne_u16_e32 vcc, 0, v7
	s_or_b64 s[18:19], vcc, s[18:19]
	s_and_b64 s[18:19], exec, s[18:19]
	s_or_b64 s[4:5], s[18:19], s[4:5]
	s_andn2_b64 s[0:1], s[0:1], exec
	s_and_b64 s[18:19], vcc, exec
	s_or_b64 s[0:1], s[0:1], s[18:19]
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execnz .LBB0_5
.Lft4:
	s_or_b64 exec, exec, s[4:5]
	v_cndmask_b32_e64 v5, v5, v2, s[0:1]
	v_cndmask_b32_e64 v3, v6, v3, s[0:1]
	v_mov_b32_e32 v2, s12
	s_cmp_lg_u32 s13, s12
	v_cndmask_b32_e64 v2, v2, v4, s[0:1]
	v_max_f32_e32 v3, v3, v3
	v_max_f32_e32 v4, v5, v5
	s_cselect_b64 s[4:5], -1, 0
	v_max_f32_e32 v20, v4, v3
	s_or_b64 s[4:5], s[4:5], s[0:1]
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execnz .LBB0_8
.Lft5:
	s_branch .LBB0_11
.LBB0_7:
	s_mov_b64 s[4:5], -1
	v_mov_b32_e32 v20, 0xff800000
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_11
.LBB0_8:
	v_mov_b32_e32 v3, 0
	v_sub_u32_e32 v4, s13, v2
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	v_lshl_add_u64 v[0:1], v[0:1], 2, v[2:3]
	v_lshl_add_u64 v[0:1], s[8:9], 0, v[0:1]
	s_mov_b64 s[4:5], 0
	.p2align	5, , 4
.LBB0_9:
	global_load_dword v2, v[0:1], off
	v_add_u32_e32 v4, -1, v4
	v_max_f32_e32 v3, v20, v20
	v_cmp_eq_u32_e32 vcc, 0, v4
	v_lshl_add_u64 v[0:1], v[0:1], 0, 4
	s_or_b64 s[4:5], vcc, s[4:5]
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v2, v2, v2
	v_max_f32_e32 v20, v3, v2
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execnz .LBB0_9
.Lft6:
	s_or_b64 exec, exec, s[4:5]
.LBB0_11:
	s_or_b64 exec, exec, s[0:1]
.LBB0_12:
	v_cndmask_b32_e64 v0, 0, 1, s[2:3]
	v_cmp_ne_u32_e64 s[0:1], 1, v0
	s_andn2_b64 vcc, exec, s[2:3]
	v_mov_b32_e32 v21, 0
	s_cbranch_vccnz .LBB0_15
.Lft7:
	v_mov_b32_e32 v21, 0
	s_mov_b32 s2, 0x3fb8aa3b
	s_mov_b32 s3, 0xc2ce8ed0
	s_mov_b32 s4, 0x42b17218
	v_mov_b32_e32 v2, 0x7f800000
	v_mov_b64_e32 v[0:1], v[26:27]
	s_mov_b32 s5, s13
	.p2align	5, , 4
.LBB0_14:
	global_load_dword v3, v[0:1], off
	s_add_i32 s5, s5, -1
	v_lshl_add_u64 v[0:1], v[0:1], 0, 4
	s_cmp_eq_u32 s5, 0
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v3, v3, v20
	v_mul_f32_e32 v4, 0x3fb8aa3b, v3
	v_fma_f32 v5, v3, s2, -v4
	v_rndne_f32_e32 v6, v4
	v_fmac_f32_e32 v5, 0x32a5705f, v3
	v_sub_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v4, v5
	v_cvt_i32_f32_e32 v6, v6
	v_exp_f32_e32 v4, v4
	v_cmp_ngt_f32_e32 vcc, s3, v3
	v_ldexp_f32 v4, v4, v6
	s_nop 0
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_nlt_f32_e32 vcc, s4, v3
	s_nop 1
	v_cndmask_b32_e32 v3, v2, v4, vcc
	v_add_f32_e32 v21, v21, v3
	s_cbranch_scc0 .LBB0_14
.LBB0_15:
	s_cmp_lt_i32 s14, 1
	s_cbranch_scc1 .LBB0_27
.Lft8:
	v_mad_u64_u32 v[18:19], s[2:3], v16, s14, 0
	v_mov_b32_e32 v0, v19
	v_mad_u64_u32 v[0:1], s[2:3], v17, s14, v[0:1]
	s_mov_b32 s7, 0
	v_mov_b32_e32 v19, v0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	s_mov_b32 s12, 0x3fb8aa3b
	s_mov_b32 s15, 0xc2ce8ed0
	s_mov_b32 s20, 0x42b17218
	v_mov_b32_e32 v22, 0x7f800000
	s_mov_b32 s8, s7
	s_branch .LBB0_18
.LBB0_17:
	v_sub_f32_e32 v24, v24, v20
	v_mul_f32_e32 v25, 0x3fb8aa3b, v24
	v_fma_f32 v28, v24, s12, -v25
	v_rndne_f32_e32 v29, v25
	v_fmac_f32_e32 v28, 0x32a5705f, v24
	v_sub_f32_e32 v25, v25, v29
	v_add_f32_e32 v25, v25, v28
	v_cvt_i32_f32_e32 v28, v29
	v_exp_f32_e32 v25, v25
	v_cmp_ngt_f32_e32 vcc, s15, v24
	s_mov_b32 s9, s7
	v_ldexp_f32 v25, v25, v28
	v_cndmask_b32_e32 v25, 0, v25, vcc
	v_cmp_nlt_f32_e32 vcc, s20, v24
	s_nop 1
	v_cndmask_b32_e32 v24, v22, v25, vcc
	v_div_scale_f32 v25, s[2:3], v21, v21, v24
	v_rcp_f32_e32 v28, v25
	s_set_gpr_idx_on s8, gpr_idx(DST)
	v_mov_b32_e32 v0, v23
	s_set_gpr_idx_off
	v_fma_f32 v29, -v25, v28, 1.0
	v_fmac_f32_e32 v28, v29, v28
	v_div_scale_f32 v29, vcc, v24, v21, v24
	v_mul_f32_e32 v30, v29, v28
	v_fma_f32 v31, -v25, v30, v29
	v_fmac_f32_e32 v30, v31, v28
	v_fma_f32 v25, -v25, v30, v29
	v_div_fmas_f32 v25, v25, v28, v30
	v_div_fixup_f32 v30, v25, v21, v24
	v_lshl_add_u64 v[24:25], v[18:19], 0, s[8:9]
	v_lshlrev_b64 v[24:25], 2, v[24:25]
	s_add_i32 s8, s8, 1
	v_lshl_add_u64 v[28:29], s[10:11], 0, v[24:25]
	v_lshl_add_u64 v[24:25], s[16:17], 0, v[24:25]
	s_cmp_eq_u32 s8, s14
	global_store_dword v[28:29], v30, off
	global_store_dword v[24:25], v23, off
	s_cbranch_scc1 .LBB0_27
.LBB0_18:
	s_and_b64 vcc, exec, s[0:1]
	v_mov_b32_e32 v23, -1
	v_mov_b32_e32 v24, 0xff800000
	s_cbranch_vccnz .LBB0_17
.Lft9:
	s_cmp_lg_u32 s8, 0
	s_cselect_b64 s[2:3], -1, 0
	v_cndmask_b32_e64 v25, 0, 1, s[2:3]
	s_mov_b32 s6, 0
	v_mov_b32_e32 v23, -1
	v_mov_b32_e32 v24, 0xff800000
	v_cmp_ne_u32_e64 s[2:3], 1, v25
	s_branch .LBB0_21
.LBB0_20:
	s_or_b64 exec, exec, s[18:19]
	s_add_i32 s6, s6, 1
	s_cmp_eq_u32 s6, s13
	s_cbranch_scc1 .LBB0_17
.LBB0_21:
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_25
.Lft10:
	s_mov_b32 s9, 0
	s_mov_b64 s[18:19], 0
	.p2align	5, , 4
.LBB0_23:
	s_set_gpr_idx_on s9, gpr_idx(SRC0)
	v_mov_b32_e32 v25, v0
	s_set_gpr_idx_off
	v_cmp_eq_u32_e32 vcc, s6, v25
	s_or_b64 s[18:19], s[18:19], vcc
	s_xor_b64 s[22:23], s[18:19], -1
	s_andn2_b64 s[4:5], s[4:5], exec
	s_and_b64 s[22:23], s[22:23], exec
	s_add_i32 s9, s9, 1
	s_or_b64 s[4:5], s[4:5], s[22:23]
	s_cmp_eq_u32 s8, s9
	s_cbranch_scc0 .LBB0_23
.Lft11:
	s_and_saveexec_b64 s[18:19], s[4:5]
	s_cbranch_execz .LBB0_20
.Lft12:
	s_branch .LBB0_26
.LBB0_25:
	s_mov_b64 s[4:5], -1
	s_and_saveexec_b64 s[18:19], s[4:5]
	s_cbranch_execz .LBB0_20
.LBB0_26:
	v_lshl_add_u64 v[28:29], s[6:7], 2, v[26:27]
	global_load_dword v25, v[28:29], off
	v_cmp_gt_i32_e32 vcc, 0, v23
	s_waitcnt vmcnt(0)
	v_cmp_gt_f32_e64 s[4:5], v25, v24
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e32 v24, v24, v25, vcc
	v_mov_b32_e32 v25, s6
	v_cndmask_b32_e32 v23, v23, v25, vcc
	s_branch .LBB0_20
.LBB0_27:
	s_mov_b64 s[0:1], 0
.LBB0_28:
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_49
.Lft13:
	v_mov_b32_e32 v14, 0
	s_cmp_lt_i32 s13, 8
	s_mov_b32 s14, 0
	v_bfrev_b32_e32 v15, 1
	v_mov_b32_e32 v0, 0xff800000
	v_mov_b32_e32 v34, 0
	s_cbranch_scc1 .LBB0_34
.Lft14:
	s_and_b32 s14, s13, 0x7ffffff8
	s_mov_b64 s[18:19], 0xffffffff
	s_mov_b32 s20, 0
	v_bfrev_b32_e32 v33, 1
	v_mov_b32_e32 v30, 0xff800000
	v_mov_b32_e32 v34, 0
	s_mov_b32 s12, 0x3fb8aa3b
	s_brev_b32 s15, -2
	v_mov_b64_e32 v[28:29], v[26:27]
	v_bfrev_b32_e32 v25, 1
	v_bfrev_b32_e32 v21, 1
	v_bfrev_b32_e32 v23, 1
	v_bfrev_b32_e32 v11, 1
	v_bfrev_b32_e32 v13, 1
	v_bfrev_b32_e32 v9, 1
	v_bfrev_b32_e32 v19, 1
	v_mov_b32_e32 v32, v14
	v_mov_b32_e32 v24, v14
	v_mov_b32_e32 v20, v14
	v_mov_b32_e32 v22, v14
	v_mov_b32_e32 v10, v14
	v_mov_b32_e32 v12, v14
	v_mov_b32_e32 v8, v14
	v_mov_b32_e32 v18, v14
	.p2align	5, , 4
.LBB0_31:
	global_load_dwordx4 v[4:7], v[28:29], off
	global_load_dwordx4 v[0:3], v[28:29], off offset:16
	s_xor_b32 s3, s20, -2
	s_xor_b32 s5, s20, -4
	s_xor_b32 s0, s20, -6
	s_xor_b32 s2, s20, -8
	s_xor_b32 s6, s20, -3
	s_xor_b32 s1, s20, -5
	s_xor_b32 s4, s20, -7
	v_mov_b32_e32 v38, s3
	v_mov_b32_e32 v40, s5
	v_mov_b32_e32 v46, s0
	v_mov_b32_e32 v48, s2
	v_mov_b32_e32 v36, s6
	v_mov_b32_e32 v56, s5
	v_mov_b32_e32 v57, s3
	v_mov_b32_e32 v42, s1
	v_mov_b32_e32 v44, s4
	v_mov_b32_e32 v61, s2
	v_mov_b32_e32 v62, s0
	v_mov_b32_e32 v35, s18
	v_mov_b32_e32 v58, s6
	v_mov_b32_e32 v59, s4
	v_mov_b32_e32 v60, s1
	v_lshl_add_u64 v[28:29], v[28:29], 0, 32
	s_waitcnt vmcnt(1)
	v_pk_add_f32 v[50:51], v[4:5], 0 op_sel_hi:[1,0]
	v_max3_f32 v45, v4, v5, v6
	v_mov_b32_e32 v31, v4
	v_ashrrev_i32_e32 v4, 31, v50
	v_max_f32_e32 v49, v7, v7
	v_ashrrev_i32_e32 v37, 31, v51
	v_bitop3_b32 v15, v4, v50, s15 bitop3:0x6c
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v5, v6
	v_mov_b32_e32 v50, v7
	v_pk_add_f32 v[6:7], v[6:7], 0 op_sel_hi:[1,0]
	v_bitop3_b32 v39, v37, v51, s15 bitop3:0x6c
	v_ashrrev_i32_e32 v37, 31, v6
	v_bitop3_b32 v37, v37, v6, s15 bitop3:0x6c
	v_ashrrev_i32_e32 v6, 31, v7
	v_bitop3_b32 v41, v6, v7, s15 bitop3:0x6c
	s_waitcnt vmcnt(0)
	v_pk_add_f32 v[6:7], v[0:1], 0 op_sel_hi:[1,0]
	v_max3_f32 v52, v0, v1, v2
	v_mov_b32_e32 v51, v0
	v_ashrrev_i32_e32 v0, 31, v6
	v_bitop3_b32 v43, v0, v6, s15 bitop3:0x6c
	v_ashrrev_i32_e32 v0, 31, v7
	v_max_f32_e32 v53, v3, v3
	v_bitop3_b32 v47, v0, v7, s15 bitop3:0x6c
	v_mov_b32_e32 v6, v1
	v_pk_add_f32 v[0:1], v[2:3], 0 op_sel_hi:[1,0]
	v_mov_b32_e32 v7, v2
	v_max_f32_e32 v49, v45, v49
	v_max_f32_e32 v2, v52, v53
	v_ashrrev_i32_e32 v45, 31, v0
	v_ashrrev_i32_e32 v52, 31, v1
	v_bitop3_b32 v45, v45, v0, s15 bitop3:0x6c
	v_max3_f32 v0, v30, v49, v2
	v_bitop3_b32 v49, v52, v1, s15 bitop3:0x6c
	v_pk_add_f32 v[52:53], v[30:31], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[50:51], v[50:51], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v1, v3, v0
	v_lshl_add_u64 v[2:3], s[18:19], 0, v[14:15]
	v_cmp_gt_i64_e32 vcc, v[38:39], v[40:41]
	v_cmp_gt_i64_e64 s[2:3], v[46:47], v[48:49]
	v_cmp_gt_i64_e64 s[0:1], v[42:43], v[44:45]
	v_cndmask_b32_e32 v55, v41, v39, vcc
	v_cndmask_b32_e32 v39, v39, v41, vcc
	v_cndmask_b32_e32 v54, v56, v57, vcc
	v_cndmask_b32_e32 v38, v57, v56, vcc
	v_cndmask_b32_e64 v57, v49, v47, s[2:3]
	s_add_u32 s18, s18, -8
	v_pk_mul_f32 v[52:53], v[52:53], s[12:13] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], s[12:13] op_sel_hi:[1,0]
	v_pk_mul_f32 v[50:51], v[50:51], s[12:13] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], s[12:13] op_sel_hi:[1,0]
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_cmp_gt_i64_e32 vcc, v[2:3], v[36:37]
	v_cndmask_b32_e64 v56, v61, v62, s[2:3]
	v_cndmask_b32_e64 v41, v45, v43, s[0:1]
	v_cndmask_b32_e32 v3, v37, v15, vcc
	v_cndmask_b32_e64 v43, v43, v45, s[0:1]
	v_cndmask_b32_e64 v40, v59, v60, s[0:1]
	v_cndmask_b32_e64 v42, v60, v59, s[0:1]
	v_cndmask_b32_e64 v45, v47, v49, s[2:3]
	v_cndmask_b32_e64 v44, v62, v61, s[2:3]
	s_addc_u32 s19, s19, -1
	s_add_i32 s2, s20, 8
	s_add_i32 s3, s20, 16
	v_exp_f32_e32 v46, v53
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v48, v5
	v_exp_f32_e32 v50, v50
	v_exp_f32_e32 v47, v51
	v_exp_f32_e32 v5, v6
	v_exp_f32_e32 v49, v7
	v_exp_f32_e32 v51, v1
	v_cndmask_b32_e32 v7, v15, v37, vcc
	v_cndmask_b32_e32 v2, v58, v35, vcc
	v_cndmask_b32_e32 v6, v35, v58, vcc
	v_cmp_gt_i64_e32 vcc, v[54:55], v[56:57]
	v_cmp_gt_i64_e64 s[0:1], v[38:39], v[44:45]
	s_cmp_le_i32 s3, s13
	v_cndmask_b32_e32 v37, v57, v55, vcc
	s_mov_b32 s20, s2
	v_cmp_gt_i64_e64 s[2:3], v[2:3], v[40:41]
	v_cndmask_b32_e32 v55, v55, v57, vcc
	v_cndmask_b32_e32 v36, v56, v54, vcc
	v_cndmask_b32_e32 v54, v54, v56, vcc
	v_cmp_gt_i64_e32 vcc, v[6:7], v[42:43]
	v_exp_f32_e32 v31, v52
	v_cndmask_b32_e64 v53, v45, v39, s[0:1]
	v_cndmask_b32_e64 v59, v41, v3, s[2:3]
	v_cndmask_b32_e32 v57, v43, v7, vcc
	v_cndmask_b32_e64 v52, v44, v38, s[0:1]
	v_cndmask_b32_e64 v3, v3, v41, s[2:3]
	v_cndmask_b32_e64 v58, v40, v2, s[2:3]
	v_cndmask_b32_e64 v2, v2, v40, s[2:3]
	v_cndmask_b32_e32 v56, v42, v6, vcc
	v_cndmask_b32_e64 v39, v39, v45, s[0:1]
	v_cndmask_b32_e64 v38, v38, v44, s[0:1]
	v_cmp_gt_i64_e64 s[0:1], v[56:57], v[52:53]
	v_cmp_gt_i64_e64 s[2:3], v[2:3], v[54:55]
	v_cndmask_b32_e32 v7, v7, v43, vcc
	v_cndmask_b32_e32 v6, v6, v42, vcc
	v_cmp_gt_i64_e32 vcc, v[58:59], v[36:37]
	v_cndmask_b32_e64 v43, v53, v57, s[0:1]
	v_cndmask_b32_e64 v45, v55, v3, s[2:3]
	v_pk_add_f32 v[4:5], v[46:47], v[4:5]
	v_pk_add_f32 v[46:47], v[48:49], v[50:51]
	v_cndmask_b32_e64 v49, v57, v53, s[0:1]
	v_cndmask_b32_e64 v42, v52, v56, s[0:1]
	v_cndmask_b32_e64 v48, v56, v52, s[0:1]
	v_cndmask_b32_e64 v3, v3, v55, s[2:3]
	v_cndmask_b32_e64 v44, v54, v2, s[2:3]
	v_cndmask_b32_e64 v2, v2, v54, s[2:3]
	v_cndmask_b32_e32 v41, v37, v59, vcc
	v_cmp_gt_i64_e64 s[4:5], v[6:7], v[38:39]
	v_cndmask_b32_e32 v37, v59, v37, vcc
	v_cndmask_b32_e32 v40, v36, v58, vcc
	v_cndmask_b32_e32 v36, v58, v36, vcc
	v_pk_add_f32 v[4:5], v[4:5], v[46:47]
	v_cmp_gt_i64_e32 vcc, v[42:43], v[44:45]
	v_cmp_gt_i64_e64 s[0:1], v[48:49], v[2:3]
	v_cndmask_b32_e64 v61, v39, v7, s[4:5]
	v_cndmask_b32_e64 v7, v7, v39, s[4:5]
	v_cndmask_b32_e64 v60, v38, v6, s[4:5]
	v_cndmask_b32_e64 v6, v6, v38, s[4:5]
	v_cndmask_b32_e64 v47, v3, v49, s[0:1]
	v_add_f32_e32 v15, v4, v5
	v_cndmask_b32_e32 v5, v43, v45, vcc
	v_cndmask_b32_e32 v4, v42, v44, vcc
	v_cndmask_b32_e64 v46, v2, v48, s[0:1]
	v_cndmask_b32_e32 v39, v45, v43, vcc
	v_cmp_gt_i64_e64 s[2:3], v[32:33], v[6:7]
	v_cmp_gt_i64_e64 s[4:5], v[18:19], v[40:41]
	v_cndmask_b32_e32 v38, v44, v42, vcc
	v_cndmask_b32_e64 v3, v49, v3, s[0:1]
	v_cndmask_b32_e64 v2, v48, v2, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[36:37], v[4:5]
	v_cmp_gt_i64_e64 s[0:1], v[46:47], v[60:61]
	v_cndmask_b32_e64 v7, v7, v33, s[2:3]
	v_cndmask_b32_e64 v19, v41, v19, s[4:5]
	v_cndmask_b32_e64 v6, v6, v32, s[2:3]
	v_cndmask_b32_e64 v18, v40, v18, s[4:5]
	v_cndmask_b32_e32 v33, v5, v37, vcc
	v_cndmask_b32_e64 v41, v61, v47, s[0:1]
	v_cndmask_b32_e32 v5, v37, v5, vcc
	v_cndmask_b32_e32 v32, v4, v36, vcc
	v_cndmask_b32_e32 v4, v36, v4, vcc
	v_cndmask_b32_e64 v37, v47, v61, s[0:1]
	v_cndmask_b32_e64 v40, v60, v46, s[0:1]
	v_cndmask_b32_e64 v36, v46, v60, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[32:33], v[38:39]
	v_cmp_gt_i64_e64 s[0:1], v[40:41], v[4:5]
	v_cmp_gt_i64_e64 s[2:3], v[2:3], v[36:37]
	v_mul_f32_e32 v1, v34, v31
	v_cmp_gt_f32_e64 s[6:7], v0, v30
	v_cndmask_b32_e32 v43, v39, v33, vcc
	v_cndmask_b32_e64 v45, v5, v41, s[0:1]
	v_cndmask_b32_e64 v47, v37, v3, s[2:3]
	v_cndmask_b32_e32 v33, v33, v39, vcc
	v_cndmask_b32_e32 v42, v38, v32, vcc
	v_cndmask_b32_e32 v32, v32, v38, vcc
	v_cndmask_b32_e64 v5, v41, v5, s[0:1]
	v_cndmask_b32_e64 v44, v4, v40, s[0:1]
	v_cndmask_b32_e64 v4, v40, v4, s[0:1]
	v_cndmask_b32_e64 v3, v3, v37, s[2:3]
	v_cndmask_b32_e64 v46, v36, v2, s[2:3]
	v_cndmask_b32_e64 v2, v2, v36, s[2:3]
	v_cndmask_b32_e64 v1, v34, v1, s[6:7]
	v_cmp_gt_i64_e32 vcc, v[24:25], v[2:3]
	v_cmp_gt_i64_e64 s[0:1], v[20:21], v[46:47]
	v_cmp_gt_i64_e64 s[2:3], v[22:23], v[4:5]
	v_cmp_gt_i64_e64 s[4:5], v[10:11], v[44:45]
	v_cmp_gt_i64_e64 s[6:7], v[12:13], v[32:33]
	v_cmp_gt_i64_e64 s[8:9], v[8:9], v[42:43]
	v_cndmask_b32_e32 v3, v3, v25, vcc
	v_cndmask_b32_e64 v21, v47, v21, s[0:1]
	v_cndmask_b32_e64 v5, v5, v23, s[2:3]
	v_cndmask_b32_e64 v11, v45, v11, s[4:5]
	v_cndmask_b32_e64 v13, v33, v13, s[6:7]
	v_cndmask_b32_e64 v9, v43, v9, s[8:9]
	v_cndmask_b32_e32 v2, v2, v24, vcc
	v_cndmask_b32_e64 v4, v4, v22, s[2:3]
	v_cndmask_b32_e64 v20, v46, v20, s[0:1]
	v_cndmask_b32_e64 v12, v32, v12, s[6:7]
	v_cndmask_b32_e64 v10, v44, v10, s[4:5]
	v_cndmask_b32_e64 v8, v42, v8, s[8:9]
	v_cmp_gt_i64_e32 vcc, v[2:3], v[12:13]
	v_cmp_gt_i64_e64 s[0:1], v[6:7], v[10:11]
	v_cmp_gt_i64_e64 s[2:3], v[4:5], v[18:19]
	v_cmp_gt_i64_e64 s[4:5], v[20:21], v[8:9]
	v_cndmask_b32_e32 v23, v13, v3, vcc
	v_cndmask_b32_e64 v25, v11, v7, s[0:1]
	v_cndmask_b32_e64 v33, v19, v5, s[2:3]
	v_cndmask_b32_e64 v37, v9, v21, s[4:5]
	v_cndmask_b32_e32 v3, v3, v13, vcc
	v_cndmask_b32_e64 v7, v7, v11, s[0:1]
	v_cndmask_b32_e32 v22, v12, v2, vcc
	v_cndmask_b32_e64 v24, v10, v6, s[0:1]
	v_cndmask_b32_e32 v2, v2, v12, vcc
	v_cndmask_b32_e64 v6, v6, v10, s[0:1]
	v_cndmask_b32_e64 v5, v5, v19, s[2:3]
	v_cndmask_b32_e64 v9, v21, v9, s[4:5]
	v_cndmask_b32_e64 v32, v18, v4, s[2:3]
	v_cndmask_b32_e64 v36, v8, v20, s[4:5]
	v_cndmask_b32_e64 v4, v4, v18, s[2:3]
	v_cndmask_b32_e64 v8, v20, v8, s[4:5]
	v_cmp_gt_i64_e32 vcc, v[24:25], v[36:37]
	v_cmp_gt_i64_e64 s[0:1], v[22:23], v[32:33]
	v_cmp_gt_i64_e64 s[2:3], v[6:7], v[8:9]
	v_cmp_gt_i64_e64 s[4:5], v[2:3], v[4:5]
	v_cndmask_b32_e32 v12, v36, v24, vcc
	v_cndmask_b32_e64 v19, v33, v23, s[0:1]
	v_cndmask_b32_e64 v38, v8, v6, s[2:3]
	v_cndmask_b32_e64 v41, v5, v3, s[4:5]
	v_cndmask_b32_e32 v36, v24, v36, vcc
	v_cndmask_b32_e32 v13, v37, v25, vcc
	v_cndmask_b32_e64 v23, v23, v33, s[0:1]
	v_cndmask_b32_e32 v37, v25, v37, vcc
	v_cndmask_b32_e64 v18, v32, v22, s[0:1]
	v_cndmask_b32_e64 v22, v22, v32, s[0:1]
	v_cndmask_b32_e64 v6, v6, v8, s[2:3]
	v_cndmask_b32_e64 v39, v9, v7, s[2:3]
	v_cndmask_b32_e64 v3, v3, v5, s[4:5]
	v_cndmask_b32_e64 v7, v7, v9, s[2:3]
	v_cndmask_b32_e64 v40, v4, v2, s[4:5]
	v_cndmask_b32_e64 v2, v2, v4, s[4:5]
	v_cmp_gt_i64_e32 vcc, v[12:13], v[18:19]
	v_cmp_gt_i64_e64 s[0:1], v[36:37], v[22:23]
	v_cmp_gt_i64_e64 s[2:3], v[38:39], v[40:41]
	v_cmp_gt_i64_e64 s[4:5], v[6:7], v[2:3]
	v_mov_b32_e32 v30, v0
	v_add_f32_e32 v34, v1, v15
	v_cndmask_b32_e32 v33, v19, v13, vcc
	v_cndmask_b32_e64 v21, v23, v37, s[0:1]
	v_cndmask_b32_e64 v11, v41, v39, s[2:3]
	v_cndmask_b32_e64 v9, v3, v7, s[4:5]
	v_cndmask_b32_e32 v25, v13, v19, vcc
	v_cndmask_b32_e32 v32, v18, v12, vcc
	v_cndmask_b32_e32 v24, v12, v18, vcc
	v_cndmask_b32_e64 v23, v37, v23, s[0:1]
	v_cndmask_b32_e64 v20, v22, v36, s[0:1]
	v_cndmask_b32_e64 v22, v36, v22, s[0:1]
	v_cndmask_b32_e64 v13, v39, v41, s[2:3]
	v_cndmask_b32_e64 v10, v40, v38, s[2:3]
	v_cndmask_b32_e64 v12, v38, v40, s[2:3]
	v_cndmask_b32_e64 v19, v7, v3, s[4:5]
	v_cndmask_b32_e64 v8, v2, v6, s[4:5]
	v_cndmask_b32_e64 v18, v6, v2, s[4:5]
	s_cbranch_scc1 .LBB0_31
.Lft15:
	v_mov_b32_e32 v15, v33
	v_mov_b32_e32 v14, v32
	s_cmp_ge_i32 s14, s13
	s_cbranch_scc0 .LBB0_35
.LBB0_33:
	v_mov_b32_e32 v7, v14
	v_mov_b32_e32 v5, v20
	v_mov_b32_e32 v3, v10
	v_mov_b32_e32 v1, v8
	s_branch .LBB0_48
.LBB0_34:
	v_bfrev_b32_e32 v25, 1
	v_bfrev_b32_e32 v21, 1
	v_bfrev_b32_e32 v23, 1
	v_bfrev_b32_e32 v11, 1
	v_bfrev_b32_e32 v13, 1
	v_bfrev_b32_e32 v9, 1
	v_bfrev_b32_e32 v19, 1
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v20, 0
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v18, 0
	s_cmp_ge_i32 s14, s13
	s_cbranch_scc1 .LBB0_33
.LBB0_35:
	s_mov_b32 s15, 0
	v_lshl_add_u64 v[4:5], s[14:15], 2, v[26:27]
	global_load_dword v1, v[4:5], off
	v_max_f32_e32 v2, v0, v0
	s_mov_b32 s0, 0x3fb8aa3b
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v3, v1, v1
	v_max_f32_e32 v2, v2, v3
	v_pk_add_f32 v[6:7], v[0:1], v[2:3] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v2, v0
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	s_or_b32 s1, s14, 1
	v_exp_f32_e32 v3, v6
	v_exp_f32_e32 v6, v7
	s_cmp_ge_u32 s1, s13
	v_mul_f32_e32 v3, v34, v3
	v_cndmask_b32_e32 v0, v34, v3, vcc
	v_add_f32_e32 v34, v6, v0
	v_bfrev_b32_e32 v3, 1
	s_cbranch_scc1 .LBB0_41
.Lft16:
	global_load_dword v3, v[4:5], off offset:4
	v_max_f32_e32 v0, v2, v2
	s_brev_b32 s1, -2
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v6, v3, v3
	v_max_f32_e32 v0, v0, v6
	v_pk_add_f32 v[6:7], v[2:3], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_add_f32_e32 v26, 0, v3
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	v_cmp_gt_f32_e32 vcc, v0, v2
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_ashrrev_i32_e32 v3, 31, v26
	v_bitop3_b32 v3, v3, v26, s1 bitop3:0x6c
	v_mul_f32_e32 v6, v34, v6
	v_cndmask_b32_e32 v2, v34, v6, vcc
	v_add_f32_e32 v34, v7, v2
	s_xor_b32 s0, s14, -2
	s_or_b32 s1, s14, 2
	s_cmp_ge_u32 s1, s13
	v_bfrev_b32_e32 v7, 1
	s_cbranch_scc0 .LBB0_42
.LBB0_37:
	v_mov_b32_e32 v27, v7
	s_or_b32 s1, s14, 3
	s_cmp_ge_u32 s1, s13
	s_mov_b32 s1, 0
	s_cbranch_scc0 .LBB0_43
.LBB0_38:
	s_mov_b32 s2, 0
	s_or_b32 s3, s14, 4
	s_cmp_ge_u32 s3, s13
	v_bfrev_b32_e32 v29, 1
	s_cbranch_scc0 .LBB0_44
.LBB0_39:
	v_mov_b32_e32 v31, v29
	s_or_b32 s3, s14, 5
	s_cmp_ge_u32 s3, s13
	s_mov_b32 s4, 0
	s_cbranch_scc0 .LBB0_45
.LBB0_40:
	s_mov_b32 s3, 0
	s_or_b32 s5, s14, 6
	s_cmp_ge_u32 s5, s13
	v_bfrev_b32_e32 v33, 1
	s_cbranch_scc0 .LBB0_46
.Lft17:
	s_branch .LBB0_47
.LBB0_41:
	s_mov_b32 s0, 0
	v_mov_b32_e32 v0, v2
	s_or_b32 s1, s14, 2
	s_cmp_ge_u32 s1, s13
	v_bfrev_b32_e32 v7, 1
	s_cbranch_scc1 .LBB0_37
.LBB0_42:
	global_load_dword v27, v[4:5], off offset:8
	v_max_f32_e32 v2, v0, v0
	v_mov_b32_e32 v26, v0
	s_mov_b32 s2, 0x3fb8aa3b
	s_brev_b32 s1, -2
	s_xor_b32 s15, s14, -3
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v6, v27, v27
	v_max_f32_e32 v2, v2, v6
	v_add_f32_e32 v30, 0, v27
	v_pk_add_f32 v[26:27], v[26:27], v[2:3] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v2, v0
	v_pk_mul_f32 v[28:29], v[26:27], s[2:3] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v26, 31, v30
	v_exp_f32_e32 v6, v28
	v_bitop3_b32 v27, v26, v30, s1 bitop3:0x6c
	v_exp_f32_e32 v26, v29
	v_mul_f32_e32 v6, v34, v6
	v_cndmask_b32_e32 v0, v34, v6, vcc
	v_add_f32_e32 v34, v26, v0
	v_mov_b32_e32 v0, v2
	s_or_b32 s1, s14, 3
	s_cmp_ge_u32 s1, s13
	s_mov_b32 s1, 0
	s_cbranch_scc1 .LBB0_38
.LBB0_43:
	global_load_dword v7, v[4:5], off offset:12
	v_max_f32_e32 v2, v0, v0
	v_mov_b32_e32 v6, v0
	s_mov_b32 s4, 0x3fb8aa3b
	s_brev_b32 s3, -2
	s_xor_b32 s2, s14, -4
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v26, v7, v7
	v_max_f32_e32 v2, v2, v26
	v_add_f32_e32 v30, 0, v7
	v_pk_add_f32 v[6:7], v[6:7], v[2:3] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v2, v0
	v_pk_mul_f32 v[28:29], v[6:7], s[4:5] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v7, 31, v30
	v_exp_f32_e32 v6, v28
	v_exp_f32_e32 v26, v29
	v_bitop3_b32 v7, v7, v30, s3 bitop3:0x6c
	v_mul_f32_e32 v6, v34, v6
	v_cndmask_b32_e32 v0, v34, v6, vcc
	v_add_f32_e32 v34, v26, v0
	v_mov_b32_e32 v0, v2
	s_or_b32 s3, s14, 4
	s_cmp_ge_u32 s3, s13
	v_bfrev_b32_e32 v29, 1
	s_cbranch_scc1 .LBB0_39
.LBB0_44:
	global_load_dword v31, v[4:5], off offset:16
	v_max_f32_e32 v2, v0, v0
	v_mov_b32_e32 v30, v0
	s_mov_b32 s4, 0x3fb8aa3b
	s_brev_b32 s3, -2
	s_xor_b32 s1, s14, -5
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v6, v31, v31
	v_max_f32_e32 v2, v2, v6
	v_add_f32_e32 v26, 0, v31
	v_pk_add_f32 v[30:31], v[30:31], v[2:3] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_ashrrev_i32_e32 v28, 31, v26
	v_pk_mul_f32 v[32:33], v[30:31], s[4:5] op_sel_hi:[1,0]
	v_bitop3_b32 v31, v28, v26, s3 bitop3:0x6c
	v_exp_f32_e32 v6, v32
	v_exp_f32_e32 v26, v33
	v_cmp_gt_f32_e32 vcc, v2, v0
	v_mul_f32_e32 v6, v34, v6
	s_nop 0
	v_cndmask_b32_e32 v0, v34, v6, vcc
	v_add_f32_e32 v34, v26, v0
	v_mov_b32_e32 v0, v2
	s_or_b32 s3, s14, 5
	s_cmp_ge_u32 s3, s13
	s_mov_b32 s4, 0
	s_cbranch_scc1 .LBB0_40
.LBB0_45:
	global_load_dword v29, v[4:5], off offset:20
	v_max_f32_e32 v2, v0, v0
	v_mov_b32_e32 v28, v0
	s_mov_b32 s6, 0x3fb8aa3b
	s_brev_b32 s5, -2
	s_xor_b32 s3, s14, -6
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v6, v29, v29
	v_max_f32_e32 v2, v2, v6
	v_add_f32_e32 v26, 0, v29
	v_pk_add_f32 v[28:29], v[28:29], v[2:3] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v2, v0
	v_pk_mul_f32 v[32:33], v[28:29], s[6:7] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v28, 31, v26
	v_exp_f32_e32 v6, v32
	v_bitop3_b32 v29, v28, v26, s5 bitop3:0x6c
	v_exp_f32_e32 v26, v33
	v_mul_f32_e32 v6, v34, v6
	v_cndmask_b32_e32 v0, v34, v6, vcc
	v_add_f32_e32 v34, v26, v0
	v_mov_b32_e32 v0, v2
	s_or_b32 s5, s14, 6
	s_cmp_ge_u32 s5, s13
	v_bfrev_b32_e32 v33, 1
	s_cbranch_scc1 .LBB0_47
.LBB0_46:
	global_load_dword v5, v[4:5], off offset:24
	v_max_f32_e32 v2, v0, v0
	v_mov_b32_e32 v4, v0
	s_mov_b32 s6, 0x3fb8aa3b
	s_brev_b32 s5, -2
	s_xor_b32 s4, s14, -7
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v6, v5, v5
	v_max_f32_e32 v2, v2, v6
	v_add_f32_e32 v26, 0, v5
	v_pk_add_f32 v[4:5], v[4:5], v[2:3] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v2, v0
	v_pk_mul_f32 v[4:5], v[4:5], s[6:7] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v6, 31, v26
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v5, v5
	v_bitop3_b32 v33, v6, v26, s5 bitop3:0x6c
	v_mul_f32_e32 v4, v34, v4
	v_cndmask_b32_e32 v0, v34, v4, vcc
	v_add_f32_e32 v34, v5, v0
	v_mov_b32_e32 v0, v2
.LBB0_47:
	v_add_f32_e32 v1, 0, v1
	v_ashrrev_i32_e32 v2, 31, v1
	s_brev_b32 s5, -2
	v_bitop3_b32 v5, v2, v1, s5 bitop3:0x6c
	s_not_b32 s5, s14
	v_mov_b32_e32 v4, s5
	v_mov_b32_e32 v26, s15
	v_cmp_gt_i64_e32 vcc, v[4:5], v[26:27]
	v_mov_b32_e32 v1, s15
	v_mov_b32_e32 v2, s5
	v_cndmask_b32_e32 v36, v1, v2, vcc
	v_cndmask_b32_e32 v4, v2, v1, vcc
	v_mov_b32_e32 v2, s0
	v_mov_b32_e32 v6, s2
	v_cndmask_b32_e32 v37, v27, v5, vcc
	v_cndmask_b32_e32 v5, v5, v27, vcc
	v_cmp_gt_i64_e32 vcc, v[2:3], v[6:7]
	v_mov_b32_e32 v1, s2
	v_mov_b32_e32 v30, s1
	v_mov_b32_e32 v32, s4
	v_cndmask_b32_e32 v27, v7, v3, vcc
	v_cndmask_b32_e32 v3, v3, v7, vcc
	v_cndmask_b32_e32 v26, v1, v2, vcc
	v_cndmask_b32_e32 v2, v2, v1, vcc
	v_cmp_gt_i64_e32 vcc, v[30:31], v[32:33]
	v_mov_b32_e32 v1, s4
	v_mov_b32_e32 v28, s1
	s_mov_b32 s6, 0
	s_brev_b32 s7, 1
	v_cndmask_b32_e32 v6, v1, v28, vcc
	v_cndmask_b32_e32 v30, v28, v1, vcc
	v_mov_b32_e32 v28, s3
	v_cndmask_b32_e32 v7, v33, v31, vcc
	v_cndmask_b32_e32 v31, v31, v33, vcc
	v_bfrev_b32_e32 v1, 1
	v_cmp_eq_u64_e32 vcc, s[6:7], v[28:29]
	s_nop 1
	v_cndmask_b32_e32 v33, v29, v1, vcc
	v_cndmask_b32_e32 v29, v1, v29, vcc
	v_mov_b32_e32 v1, s3
	v_cndmask_b32_e32 v28, 0, v1, vcc
	v_cndmask_b32_e64 v32, v1, 0, vcc
	v_cmp_gt_i64_e64 s[2:3], v[4:5], v[30:31]
	v_cmp_gt_i64_e64 s[4:5], v[2:3], v[28:29]
	v_cmp_gt_i64_e32 vcc, v[36:37], v[6:7]
	v_cmp_gt_i64_e64 s[0:1], v[26:27], v[32:33]
	v_cndmask_b32_e64 v45, v31, v5, s[2:3]
	v_cndmask_b32_e64 v44, v30, v4, s[2:3]
	v_cndmask_b32_e64 v47, v29, v3, s[4:5]
	v_cndmask_b32_e64 v46, v28, v2, s[4:5]
	v_cndmask_b32_e32 v41, v37, v7, vcc
	v_cndmask_b32_e32 v40, v36, v6, vcc
	v_cndmask_b32_e64 v43, v27, v33, s[0:1]
	v_cndmask_b32_e64 v42, v26, v32, s[0:1]
	v_cmp_gt_i64_e64 s[6:7], v[44:45], v[46:47]
	v_cndmask_b32_e32 v39, v7, v37, vcc
	v_cndmask_b32_e64 v7, v33, v27, s[0:1]
	v_cndmask_b32_e64 v49, v47, v45, s[6:7]
	v_cndmask_b32_e64 v45, v45, v47, s[6:7]
	v_cndmask_b32_e64 v48, v46, v44, s[6:7]
	v_cndmask_b32_e64 v44, v44, v46, s[6:7]
	v_cmp_gt_i64_e64 s[6:7], v[40:41], v[42:43]
	v_cndmask_b32_e32 v38, v6, v36, vcc
	v_cndmask_b32_e64 v6, v32, v26, s[0:1]
	v_cndmask_b32_e64 v47, v43, v41, s[6:7]
	v_cndmask_b32_e64 v46, v42, v40, s[6:7]
	v_cndmask_b32_e64 v5, v5, v31, s[2:3]
	v_cndmask_b32_e64 v3, v3, v29, s[4:5]
	v_cndmask_b32_e64 v41, v41, v43, s[6:7]
	v_cndmask_b32_e64 v40, v40, v42, s[6:7]
	v_cmp_gt_i64_e64 s[6:7], v[48:49], v[46:47]
	v_cndmask_b32_e64 v2, v2, v28, s[4:5]
	v_cmp_gt_i64_e32 vcc, v[38:39], v[6:7]
	v_cndmask_b32_e64 v4, v4, v30, s[2:3]
	v_cndmask_b32_e64 v43, v49, v47, s[6:7]
	v_cndmask_b32_e64 v42, v48, v46, s[6:7]
	v_cmp_gt_i64_e64 s[8:9], v[44:45], v[40:41]
	v_cndmask_b32_e32 v33, v39, v7, vcc
	v_cndmask_b32_e32 v32, v38, v6, vcc
	v_cmp_gt_i64_e64 s[0:1], v[4:5], v[2:3]
	v_cndmask_b32_e64 v51, v41, v45, s[8:9]
	v_cndmask_b32_e64 v50, v40, v44, s[8:9]
	v_cndmask_b32_e64 v31, v3, v5, s[0:1]
	v_cndmask_b32_e64 v30, v2, v4, s[0:1]
	v_cmp_gt_i64_e64 s[2:3], v[32:33], v[42:43]
	v_cndmask_b32_e64 v27, v47, v49, s[6:7]
	v_cndmask_b32_e64 v29, v45, v41, s[8:9]
	v_cndmask_b32_e64 v37, v43, v33, s[2:3]
	v_cndmask_b32_e64 v33, v33, v43, s[2:3]
	v_cndmask_b32_e64 v36, v42, v32, s[2:3]
	v_cndmask_b32_e64 v32, v32, v42, s[2:3]
	v_cmp_gt_i64_e64 s[2:3], v[50:51], v[30:31]
	v_cndmask_b32_e64 v28, v44, v40, s[8:9]
	v_cndmask_b32_e64 v26, v46, v48, s[6:7]
	v_cndmask_b32_e64 v41, v31, v51, s[2:3]
	v_cndmask_b32_e64 v31, v51, v31, s[2:3]
	v_cndmask_b32_e64 v40, v30, v50, s[2:3]
	v_cndmask_b32_e64 v30, v50, v30, s[2:3]
	v_cmp_gt_i64_e64 s[2:3], v[36:37], v[26:27]
	v_cmp_gt_i64_e64 s[4:5], v[40:41], v[32:33]
	v_cmp_gt_i64_e64 s[6:7], v[28:29], v[30:31]
	v_cndmask_b32_e32 v7, v7, v39, vcc
	v_cndmask_b32_e64 v39, v27, v37, s[2:3]
	v_cndmask_b32_e64 v27, v37, v27, s[2:3]
	v_cndmask_b32_e64 v37, v33, v41, s[4:5]
	v_cndmask_b32_e64 v33, v41, v33, s[4:5]
	v_cndmask_b32_e64 v41, v31, v29, s[6:7]
	v_cndmask_b32_e64 v29, v29, v31, s[6:7]
	v_cndmask_b32_e64 v3, v5, v3, s[0:1]
	v_cndmask_b32_e32 v6, v6, v38, vcc
	v_cndmask_b32_e64 v38, v26, v36, s[2:3]
	v_cndmask_b32_e64 v26, v36, v26, s[2:3]
	v_cndmask_b32_e64 v36, v32, v40, s[4:5]
	v_cndmask_b32_e64 v32, v40, v32, s[4:5]
	v_cndmask_b32_e64 v40, v30, v28, s[6:7]
	v_cndmask_b32_e64 v28, v28, v30, s[6:7]
	v_cndmask_b32_e64 v2, v4, v2, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[24:25], v[28:29]
	v_cmp_gt_i64_e64 s[0:1], v[14:15], v[2:3]
	s_nop 0
	v_cndmask_b32_e32 v5, v29, v25, vcc
	v_cndmask_b32_e64 v3, v3, v15, s[0:1]
	v_cndmask_b32_e32 v4, v28, v24, vcc
	v_cndmask_b32_e64 v2, v2, v14, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[22:23], v[32:33]
	v_cmp_gt_i64_e64 s[0:1], v[20:21], v[40:41]
	s_nop 0
	v_cndmask_b32_e32 v15, v33, v23, vcc
	v_cndmask_b32_e64 v21, v41, v21, s[0:1]
	v_cndmask_b32_e32 v14, v32, v22, vcc
	v_cndmask_b32_e64 v20, v40, v20, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[12:13], v[26:27]
	v_cmp_gt_i64_e64 s[0:1], v[10:11], v[36:37]
	s_nop 0
	v_cndmask_b32_e32 v13, v27, v13, vcc
	v_cndmask_b32_e64 v11, v37, v11, s[0:1]
	v_cndmask_b32_e32 v12, v26, v12, vcc
	v_cndmask_b32_e64 v10, v36, v10, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[18:19], v[6:7]
	v_cmp_gt_i64_e64 s[0:1], v[8:9], v[38:39]
	s_nop 0
	v_cndmask_b32_e32 v7, v7, v19, vcc
	v_cndmask_b32_e64 v9, v39, v9, s[0:1]
	v_cndmask_b32_e32 v6, v6, v18, vcc
	v_cndmask_b32_e64 v8, v38, v8, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[4:5], v[12:13]
	v_cmp_gt_i64_e64 s[0:1], v[2:3], v[10:11]
	s_nop 0
	v_cndmask_b32_e32 v19, v13, v5, vcc
	v_cndmask_b32_e64 v23, v11, v3, s[0:1]
	v_cndmask_b32_e32 v5, v5, v13, vcc
	v_cndmask_b32_e64 v3, v3, v11, s[0:1]
	v_cndmask_b32_e32 v18, v12, v4, vcc
	v_cndmask_b32_e64 v22, v10, v2, s[0:1]
	v_cndmask_b32_e32 v4, v4, v12, vcc
	v_cndmask_b32_e64 v2, v2, v10, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[14:15], v[6:7]
	v_cmp_gt_i64_e64 s[0:1], v[20:21], v[8:9]
	s_nop 0
	v_cndmask_b32_e32 v11, v7, v15, vcc
	v_cndmask_b32_e64 v13, v9, v21, s[0:1]
	v_cndmask_b32_e32 v10, v6, v14, vcc
	v_cndmask_b32_e64 v12, v8, v20, s[0:1]
	v_cndmask_b32_e32 v7, v15, v7, vcc
	v_cndmask_b32_e64 v9, v21, v9, s[0:1]
	v_cndmask_b32_e32 v6, v14, v6, vcc
	v_cndmask_b32_e64 v8, v20, v8, s[0:1]
	v_cmp_gt_i64_e32 vcc, v[18:19], v[10:11]
	v_cmp_gt_i64_e64 s[0:1], v[22:23], v[12:13]
	s_nop 0
	v_cndmask_b32_e32 v21, v11, v19, vcc
	v_cndmask_b32_e64 v25, v13, v23, s[0:1]
	v_cndmask_b32_e32 v11, v19, v11, vcc
	v_cndmask_b32_e32 v20, v10, v18, vcc
	v_cndmask_b32_e64 v24, v12, v22, s[0:1]
	v_cndmask_b32_e32 v10, v18, v10, vcc
	v_cmp_gt_i64_e32 vcc, v[4:5], v[6:7]
	v_cndmask_b32_e64 v13, v23, v13, s[0:1]
	v_cndmask_b32_e64 v12, v22, v12, s[0:1]
	v_cndmask_b32_e32 v19, v7, v5, vcc
	v_cmp_gt_i64_e64 s[0:1], v[2:3], v[8:9]
	v_cndmask_b32_e32 v29, v5, v7, vcc
	v_cndmask_b32_e32 v18, v6, v4, vcc
	v_cndmask_b32_e32 v28, v4, v6, vcc
	v_cmp_gt_i64_e32 vcc, v[24:25], v[20:21]
	v_cndmask_b32_e64 v27, v9, v3, s[0:1]
	v_cndmask_b32_e64 v26, v8, v2, s[0:1]
	v_cndmask_b32_e32 v15, v21, v25, vcc
	v_cndmask_b32_e32 v25, v25, v21, vcc
	v_cndmask_b32_e32 v7, v20, v24, vcc
	v_cndmask_b32_e32 v24, v24, v20, vcc
	v_cmp_gt_i64_e32 vcc, v[12:13], v[10:11]
	v_cndmask_b32_e64 v31, v3, v9, s[0:1]
	v_cndmask_b32_e64 v30, v2, v8, s[0:1]
	v_cndmask_b32_e32 v21, v11, v13, vcc
	v_cndmask_b32_e32 v23, v13, v11, vcc
	v_cndmask_b32_e32 v5, v10, v12, vcc
	v_cndmask_b32_e32 v22, v12, v10, vcc
	v_cmp_gt_i64_e32 vcc, v[26:27], v[18:19]
	s_nop 1
	v_cndmask_b32_e32 v11, v19, v27, vcc
	v_cndmask_b32_e32 v13, v27, v19, vcc
	v_cndmask_b32_e32 v3, v18, v26, vcc
	v_cndmask_b32_e32 v12, v26, v18, vcc
	v_cmp_gt_i64_e32 vcc, v[30:31], v[28:29]
	s_nop 1
	v_cndmask_b32_e32 v9, v29, v31, vcc
	v_cndmask_b32_e32 v19, v31, v29, vcc
	v_cndmask_b32_e32 v1, v28, v30, vcc
	v_cndmask_b32_e32 v18, v30, v28, vcc
.LBB0_48:
	v_div_scale_f32 v2, s[0:1], v34, v34, 1.0
	v_rcp_f32_e32 v4, v2
	v_xor_b32_e32 v26, -1, v7
	s_mov_b32 s0, 0x3fb8aa3b
	v_lshlrev_b64 v[16:17], 5, v[16:17]
	v_fma_f32 v6, -v2, v4, 1.0
	v_fmac_f32_e32 v4, v6, v4
	v_div_scale_f32 v6, vcc, 1.0, v34, 1.0
	v_mul_f32_e32 v8, v6, v4
	v_fma_f32 v10, -v2, v8, v6
	v_fmac_f32_e32 v8, v10, v4
	v_fma_f32 v2, -v2, v8, v6
	v_div_fmas_f32 v2, v2, v4, v8
	v_ashrrev_i32_e32 v4, 31, v15
	v_and_b32_e32 v4, 0x7fffffff, v4
	v_ashrrev_i32_e32 v6, 31, v25
	v_and_b32_e32 v6, 0x7fffffff, v6
	v_xor_b32_e32 v4, v4, v15
	v_mov_b32_e32 v8, 0xff800000
	v_cmp_gt_i32_e32 vcc, 0, v7
	v_xor_b32_e32 v6, v6, v25
	v_lshl_add_u64 v[30:31], s[10:11], 0, v[16:17]
	v_cndmask_b32_e32 v7, v8, v4, vcc
	v_cmp_gt_i32_e32 vcc, 0, v24
	v_ashrrev_i32_e32 v4, 31, v21
	v_and_b32_e32 v4, 0x7fffffff, v4
	v_cndmask_b32_e32 v6, v8, v6, vcc
	v_pk_add_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_xor_b32_e32 v4, v4, v21
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	v_cmp_gt_i32_e32 vcc, 0, v5
	v_exp_f32_e32 v15, v6
	v_ashrrev_i32_e32 v6, 31, v23
	v_and_b32_e32 v6, 0x7fffffff, v6
	v_exp_f32_e32 v14, v7
	v_xor_b32_e32 v6, v6, v23
	v_cndmask_b32_e32 v7, v8, v4, vcc
	v_cmp_gt_i32_e32 vcc, 0, v22
	v_lshl_add_u64 v[32:33], s[16:17], 0, v[16:17]
	v_div_fixup_f32 v2, v2, v34, 1.0
	v_cndmask_b32_e32 v6, v8, v6, vcc
	v_pk_add_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_i32_e32 vcc, 0, v3
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[2:3], v[14:15] op_sel_hi:[0,1]
	v_exp_f32_e32 v17, v6
	v_ashrrev_i32_e32 v6, 31, v11
	v_exp_f32_e32 v16, v7
	v_and_b32_e32 v6, 0x7fffffff, v6
	v_ashrrev_i32_e32 v7, 31, v13
	v_and_b32_e32 v7, 0x7fffffff, v7
	v_xor_b32_e32 v6, v6, v11
	v_xor_b32_e32 v10, v7, v13
	v_cndmask_b32_e32 v7, v8, v6, vcc
	v_cmp_gt_i32_e32 vcc, 0, v12
	v_pk_mul_f32 v[16:17], v[2:3], v[16:17] op_sel_hi:[0,1]
	v_xor_b32_e32 v4, -1, v3
	v_cndmask_b32_e32 v6, v8, v10, vcc
	v_pk_add_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_ashrrev_i32_e32 v3, 31, v9
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	v_and_b32_e32 v3, 0x7fffffff, v3
	v_exp_f32_e32 v11, v6
	v_ashrrev_i32_e32 v6, 31, v19
	v_and_b32_e32 v6, 0x7fffffff, v6
	v_xor_b32_e32 v3, v3, v9
	v_cmp_gt_i32_e32 vcc, 0, v1
	v_exp_f32_e32 v10, v7
	v_xor_b32_e32 v6, v6, v19
	v_cndmask_b32_e32 v7, v8, v3, vcc
	v_cmp_gt_i32_e32 vcc, 0, v18
	v_xor_b32_e32 v28, -1, v5
	v_xor_b32_e32 v5, -1, v12
	v_cndmask_b32_e32 v6, v8, v6, vcc
	v_pk_add_f32 v[6:7], v[6:7], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_mul_f32 v[8:9], v[2:3], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	v_xor_b32_e32 v27, -1, v24
	v_exp_f32_e32 v12, v7
	v_exp_f32_e32 v13, v6
	v_xor_b32_e32 v29, -1, v22
	global_store_dwordx4 v[30:31], v[14:17], off
	global_store_dwordx4 v[32:33], v[26:29], off
	v_xor_b32_e32 v6, -1, v1
	v_pk_mul_f32 v[10:11], v[2:3], v[12:13] op_sel_hi:[0,1]
	v_xor_b32_e32 v7, -1, v18
	global_store_dwordx4 v[30:31], v[8:11], off offset:16
	global_store_dwordx4 v[32:33], v[4:7], off offset:16
.LBB0_49:
	s_endpgm
.Lfunc_end0:
	.size	moe_gate_topk, .Lfunc_end0-moe_gate_topk
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel moe_gate_topk
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 296
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
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 63
		.amdhsa_next_free_sgpr 24
		.amdhsa_accum_offset 64
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
  - .address_space: global
    .offset: 0
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .offset: 24
    .size: 4
    .value_kind: by_value
  - .offset: 28
    .size: 4
    .value_kind: by_value
  - .offset: 32
    .size: 4
    .value_kind: by_value
  - .offset: 40
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 44
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 48
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 52
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 54
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 56
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 58
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 60
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 62
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 80
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 88
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 96
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 104
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 296
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: moe_gate_topk
  .private_segment_fixed_size: 0
  .sgpr_count: 30
  .sgpr_spill_count: 0
  .symbol: moe_gate_topk.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 63
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
