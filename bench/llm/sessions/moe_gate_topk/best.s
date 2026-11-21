	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	moe_gate_topk
	.globl	moe_gate_topk
	.p2align	8
	.type	moe_gate_topk,@function
moe_gate_topk:
	s_load_dword s3, s[0:1], 0x34
	s_load_dwordx4 s[8:11], s[0:1], 0x18
	s_waitcnt lgkmcnt(0)
	s_and_b32 s3, s3, 0xffff
	s_mul_i32 s2, s2, s3
	v_add_u32_e32 v16, s2, v0
	v_cmp_gt_i32_e32 vcc, s8, v16
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_49
.Lft0:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[12:13], s[0:1], 0x10
	v_mad_i64_i32 v[0:1], s[0:1], v16, s9, 0
	v_ashrrev_i32_e32 v17, 31, v16
	s_cmp_eq_u32 s10, 8
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[18:19], v[0:1], 2, s[4:5]
	s_mov_b64 s[0:1], -1
	s_cbranch_scc1 .LBB0_28
.Lft1:
	s_cmp_gt_i32 s9, 0
	s_cselect_b64 s[2:3], -1, 0
	s_cmp_lt_i32 s9, 1
	v_mov_b32_e32 v22, 0xff800000
	s_cbranch_scc1 .LBB0_12
.Lft2:
	s_cmp_eq_u32 s9, 1
	v_mov_b32_e32 v2, 0
	s_cbranch_scc1 .LBB0_7
.Lft3:
	s_mov_b32 s17, 0
	s_and_b32 s8, s9, 0x7ffffffe
	s_mov_b64 s[14:15], 0
	v_mov_b32_e32 v5, 0xff800000
	s_mov_b32 s16, s17
	v_mov_b32_e32 v6, 0xff800000
	.p2align	5, , 4
.LBB0_5:
	v_lshl_add_u64 v[2:3], s[16:17], 2, v[18:19]
	global_load_dwordx2 v[8:9], v[2:3], off
	v_mov_b32_e32 v2, v5
	v_mov_b32_e32 v3, v6
	v_max_f32_e32 v5, v3, v3
	v_max_f32_e32 v7, v2, v2
	s_add_i32 s11, s16, 2
	s_cmp_eq_u32 s11, s8
	s_cselect_b64 s[18:19], -1, 0
	v_mov_b32_e32 v4, s16
	s_mov_b32 s16, s11
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
	s_or_b64 s[14:15], s[18:19], s[14:15]
	s_andn2_b64 s[0:1], s[0:1], exec
	s_and_b64 s[18:19], vcc, exec
	s_or_b64 s[0:1], s[0:1], s[18:19]
	s_andn2_b64 exec, exec, s[14:15]
	s_cbranch_execnz .LBB0_5
.Lft4:
	s_or_b64 exec, exec, s[14:15]
	v_cndmask_b32_e64 v5, v5, v2, s[0:1]
	v_cndmask_b32_e64 v3, v6, v3, s[0:1]
	v_mov_b32_e32 v2, s8
	s_cmp_lg_u32 s9, s8
	v_cndmask_b32_e64 v2, v2, v4, s[0:1]
	v_max_f32_e32 v3, v3, v3
	v_max_f32_e32 v4, v5, v5
	s_cselect_b64 s[14:15], -1, 0
	v_max_f32_e32 v22, v4, v3
	s_or_b64 s[14:15], s[14:15], s[0:1]
	s_and_saveexec_b64 s[0:1], s[14:15]
	s_cbranch_execnz .LBB0_8
.Lft5:
	s_branch .LBB0_11
.LBB0_7:
	s_mov_b64 s[14:15], -1
	v_mov_b32_e32 v22, 0xff800000
	s_and_saveexec_b64 s[0:1], s[14:15]
	s_cbranch_execz .LBB0_11
.LBB0_8:
	v_mov_b32_e32 v3, 0
	v_sub_u32_e32 v4, s9, v2
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	v_lshl_add_u64 v[0:1], v[0:1], 2, v[2:3]
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[0:1]
	s_mov_b64 s[4:5], 0
	.p2align	5, , 4
.LBB0_9:
	global_load_dword v2, v[0:1], off
	v_add_u32_e32 v4, -1, v4
	v_max_f32_e32 v3, v22, v22
	v_cmp_eq_u32_e32 vcc, 0, v4
	v_lshl_add_u64 v[0:1], v[0:1], 0, 4
	s_or_b64 s[4:5], vcc, s[4:5]
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v2, v2, v2
	v_max_f32_e32 v22, v3, v2
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
	v_mov_b32_e32 v23, 0
	s_cbranch_vccnz .LBB0_15
.Lft7:
	v_mov_b32_e32 v23, 0
	s_mov_b32 s2, 0x3fb8aa3b
	s_mov_b32 s3, 0xc2ce8ed0
	s_mov_b32 s4, 0x42b17218
	v_mov_b32_e32 v2, 0x7f800000
	v_mov_b64_e32 v[0:1], v[18:19]
	s_mov_b32 s5, s9
	.p2align	5, , 4
.LBB0_14:
	global_load_dword v3, v[0:1], off
	s_add_i32 s5, s5, -1
	v_lshl_add_u64 v[0:1], v[0:1], 0, 4
	s_cmp_eq_u32 s5, 0
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v3, v3, v22
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
	v_add_f32_e32 v23, v23, v3
	s_cbranch_scc0 .LBB0_14
.LBB0_15:
	s_cmp_lt_i32 s10, 1
	s_cbranch_scc1 .LBB0_27
.Lft8:
	v_mad_u64_u32 v[20:21], s[2:3], v16, s10, 0
	v_mov_b32_e32 v0, v21
	v_mad_u64_u32 v[0:1], s[2:3], v17, s10, v[0:1]
	s_mov_b32 s15, 0
	v_mov_b32_e32 v21, v0
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
	s_mov_b32 s8, 0x3fb8aa3b
	s_mov_b32 s11, 0xc2ce8ed0
	s_mov_b32 s20, 0x42b17218
	v_mov_b32_e32 v24, 0x7f800000
	s_mov_b32 s16, s15
	s_branch .LBB0_18
.LBB0_17:
	v_sub_f32_e32 v26, v26, v22
	v_mul_f32_e32 v27, 0x3fb8aa3b, v26
	v_fma_f32 v28, v26, s8, -v27
	v_rndne_f32_e32 v29, v27
	v_fmac_f32_e32 v28, 0x32a5705f, v26
	v_sub_f32_e32 v27, v27, v29
	v_add_f32_e32 v27, v27, v28
	v_cvt_i32_f32_e32 v28, v29
	v_exp_f32_e32 v27, v27
	v_cmp_ngt_f32_e32 vcc, s11, v26
	s_mov_b32 s17, s15
	v_ldexp_f32 v27, v27, v28
	v_cndmask_b32_e32 v27, 0, v27, vcc
	v_cmp_nlt_f32_e32 vcc, s20, v26
	s_nop 1
	v_cndmask_b32_e32 v26, v24, v27, vcc
	v_div_scale_f32 v27, s[2:3], v23, v23, v26
	v_rcp_f32_e32 v28, v27
	s_set_gpr_idx_on s16, gpr_idx(DST)
	v_mov_b32_e32 v0, v25
	s_set_gpr_idx_off
	v_fma_f32 v29, -v27, v28, 1.0
	v_fmac_f32_e32 v28, v29, v28
	v_div_scale_f32 v29, vcc, v26, v23, v26
	v_mul_f32_e32 v30, v29, v28
	v_fma_f32 v31, -v27, v30, v29
	v_fmac_f32_e32 v30, v31, v28
	v_fma_f32 v27, -v27, v30, v29
	v_div_fmas_f32 v27, v27, v28, v30
	v_div_fixup_f32 v30, v27, v23, v26
	v_lshl_add_u64 v[26:27], v[20:21], 0, s[16:17]
	v_lshlrev_b64 v[26:27], 2, v[26:27]
	s_add_i32 s16, s16, 1
	v_lshl_add_u64 v[28:29], s[6:7], 0, v[26:27]
	v_lshl_add_u64 v[26:27], s[12:13], 0, v[26:27]
	s_cmp_eq_u32 s16, s10
	global_store_dword v[28:29], v30, off
	global_store_dword v[26:27], v25, off
	s_cbranch_scc1 .LBB0_27
.LBB0_18:
	s_and_b64 vcc, exec, s[0:1]
	v_mov_b32_e32 v25, -1
	v_mov_b32_e32 v26, 0xff800000
	s_cbranch_vccnz .LBB0_17
.Lft9:
	s_cmp_lg_u32 s16, 0
	s_cselect_b64 s[2:3], -1, 0
	v_cndmask_b32_e64 v27, 0, 1, s[2:3]
	s_mov_b32 s14, 0
	v_mov_b32_e32 v25, -1
	v_mov_b32_e32 v26, 0xff800000
	v_cmp_ne_u32_e64 s[2:3], 1, v27
	s_branch .LBB0_21
.LBB0_20:
	s_or_b64 exec, exec, s[18:19]
	s_add_i32 s14, s14, 1
	s_cmp_eq_u32 s14, s9
	s_cbranch_scc1 .LBB0_17
.LBB0_21:
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_25
.Lft10:
	s_mov_b32 s17, 0
	s_mov_b64 s[18:19], 0
	.p2align	5, , 4
.LBB0_23:
	s_set_gpr_idx_on s17, gpr_idx(SRC0)
	v_mov_b32_e32 v27, v0
	s_set_gpr_idx_off
	v_cmp_eq_u32_e32 vcc, s14, v27
	s_or_b64 s[18:19], s[18:19], vcc
	s_xor_b64 s[22:23], s[18:19], -1
	s_andn2_b64 s[4:5], s[4:5], exec
	s_and_b64 s[22:23], s[22:23], exec
	s_add_i32 s17, s17, 1
	s_or_b64 s[4:5], s[4:5], s[22:23]
	s_cmp_eq_u32 s16, s17
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
	v_lshl_add_u64 v[28:29], s[14:15], 2, v[18:19]
	global_load_dword v27, v[28:29], off
	v_cmp_gt_i32_e32 vcc, 0, v25
	s_waitcnt vmcnt(0)
	v_cmp_gt_f32_e64 s[4:5], v27, v26
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e32 v26, v26, v27, vcc
	v_mov_b32_e32 v27, s14
	v_cndmask_b32_e32 v25, v25, v27, vcc
	s_branch .LBB0_20
.LBB0_27:
	s_mov_b64 s[0:1], 0
.LBB0_28:
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_49
.Lft13:
	v_mov_b32_e32 v24, -1
	v_mov_b32_e32 v25, 0xff900000
	s_mov_b32 s0, 0
	s_cmp_lt_i32 s9, 8
	v_mov_b32_e32 v0, 0xff800000
	v_mov_b32_e32 v34, 0
	v_mov_b64_e32 v[2:3], v[24:25]
	v_mov_b64_e32 v[22:23], v[24:25]
	v_mov_b64_e32 v[20:21], v[24:25]
	v_mov_b64_e32 v[14:15], v[24:25]
	v_mov_b64_e32 v[12:13], v[24:25]
	v_mov_b64_e32 v[10:11], v[24:25]
	v_mov_b64_e32 v[8:9], v[24:25]
	s_cbranch_scc1 .LBB0_33
.Lft14:
	s_mov_b32 s1, 0
	v_mov_b32_e32 v28, 0xff800000
	v_mov_b32_e32 v34, 0
	s_mov_b32 s0, 0x3fb8aa3b
	v_mov_b64_e32 v[26:27], v[18:19]
	v_mov_b64_e32 v[30:31], v[24:25]
	v_mov_b64_e32 v[20:21], v[24:25]
	v_mov_b64_e32 v[22:23], v[24:25]
	v_mov_b64_e32 v[12:13], v[24:25]
	v_mov_b64_e32 v[14:15], v[24:25]
	v_mov_b64_e32 v[8:9], v[24:25]
	v_mov_b64_e32 v[10:11], v[24:25]
	global_load_dwordx4 v[60:63], v[26:27], off
	global_load_dwordx4 v[64:67], v[26:27], off offset:16
	.p2align	5, , 4
.LBB0_31:
	s_waitcnt vmcnt(0)
	v_mov_b64_e32 v[4:5], v[60:61]
	v_mov_b64_e32 v[6:7], v[62:63]
	v_mov_b64_e32 v[0:1], v[64:65]
	v_mov_b64_e32 v[2:3], v[66:67]
	s_add_i32 s15, s1, 16
	s_cmp_le_i32 s15, s9
	s_cselect_b32 s16, 32, 0
	s_mov_b32 s17, 0
	v_lshl_add_u64 v[58:59], v[26:27], 0, s[16:17]
	global_load_dwordx4 v[60:63], v[58:59], off
	global_load_dwordx4 v[64:67], v[58:59], off offset:16
	s_xor_b32 s2, s1, -3
	s_xor_b32 s3, s1, -2
	s_xor_b32 s4, s1, -4
	s_xor_b32 s5, s1, -5
	s_xor_b32 s8, s1, -7
	s_xor_b32 s10, s1, -6
	s_xor_b32 s11, s1, -8
	s_add_i32 s14, s1, 8
	s_add_i32 s15, s1, 16
	v_lshl_add_u64 v[26:27], v[26:27], 0, 32
	s_cmp_le_i32 s15, s9
	v_max3_f32 v35, v4, v5, v6
	v_max_f32_e32 v42, v7, v7
	v_max3_f32 v43, v0, v1, v2
	v_max_f32_e32 v44, v3, v3
	v_mov_b32_e32 v29, v4
	v_mov_b32_e32 v68, v5
	v_mov_b32_e32 v69, v6
	v_mov_b32_e32 v36, v7
	v_mov_b32_e32 v37, v0
	v_mov_b32_e32 v38, v1
	v_pk_add_f32 v[40:41], v[2:3], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[0:1], v[0:1], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[6:7], v[6:7], 0 op_sel_hi:[1,0]
	v_pk_add_f32 v[4:5], v[4:5], 0 op_sel_hi:[1,0]
	v_mov_b32_e32 v39, v2
	v_max_f32_e32 v2, v35, v42
	v_max_f32_e32 v35, v43, v44
	v_add_u32_e32 v43, 0x100000, v4
	v_add_u32_e32 v45, 0x100000, v6
	v_add_u32_e32 v47, 0x100000, v5
	v_add_u32_e32 v49, 0x100000, v7
	v_add_u32_e32 v53, 0x100000, v40
	v_add_u32_e32 v55, 0x100000, v1
	v_add_u32_e32 v57, 0x100000, v41
	v_ashrrev_i32_e32 v4, 31, v4
	v_ashrrev_i32_e32 v41, 31, v41
	v_ashrrev_i32_e32 v1, 31, v1
	v_ashrrev_i32_e32 v40, 31, v40
	v_ashrrev_i32_e32 v42, 31, v0
	v_ashrrev_i32_e32 v7, 31, v7
	v_ashrrev_i32_e32 v5, 31, v5
	v_ashrrev_i32_e32 v6, 31, v6
	v_add_u32_e32 v51, 0x100000, v0
	v_max3_f32 v0, v28, v2, v35
	v_xor_b32_e32 v44, s2, v6
	v_xor_b32_e32 v46, s3, v5
	v_xor_b32_e32 v48, s4, v7
	v_xor_b32_e32 v50, s5, v42
	v_xor_b32_e32 v52, s8, v40
	v_xor_b32_e32 v54, s10, v1
	v_xor_b32_e32 v56, s11, v41
	v_xnor_b32_e32 v42, s1, v4
	v_pk_add_f32 v[4:5], v[28:29], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[6:7], v[68:69], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[68:69], v[36:37], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[36:37], v[38:39], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v1, v3, v0
	s_mov_b32 s1, s14
	v_pk_mul_f32 v[4:5], v[4:5], s[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], s[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[68:69], v[68:69], s[0:1] op_sel_hi:[1,0]
	v_pk_mul_f32 v[36:37], v[36:37], s[0:1] op_sel_hi:[1,0]
	v_mul_f32_e32 v1, 0x3fb8aa3b, v1
	v_max_f64 v[70:71], v[42:43], v[44:45]
	v_min_f64 v[2:3], v[42:43], v[44:45]
	v_max_f64 v[38:39], v[46:47], v[48:49]
	v_min_f64 v[40:41], v[46:47], v[48:49]
	v_max_f64 v[42:43], v[50:51], v[52:53]
	v_min_f64 v[44:45], v[50:51], v[52:53]
	v_max_f64 v[46:47], v[54:55], v[56:57]
	v_min_f64 v[48:49], v[54:55], v[56:57]
	v_exp_f32_e32 v29, v4
	v_exp_f32_e32 v4, v5
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v50, v7
	v_exp_f32_e32 v68, v68
	v_exp_f32_e32 v5, v69
	v_exp_f32_e32 v7, v36
	v_exp_f32_e32 v51, v37
	v_exp_f32_e32 v69, v1
	v_max_f64 v[36:37], v[70:71], v[42:43]
	v_min_f64 v[42:43], v[70:71], v[42:43]
	v_max_f64 v[52:53], v[38:39], v[46:47]
	v_min_f64 v[38:39], v[38:39], v[46:47]
	v_max_f64 v[46:47], v[2:3], v[44:45]
	v_min_f64 v[2:3], v[2:3], v[44:45]
	v_max_f64 v[44:45], v[40:41], v[48:49]
	v_min_f64 v[40:41], v[40:41], v[48:49]
	v_max_f64 v[48:49], v[36:37], v[52:53]
	v_min_f64 v[36:37], v[36:37], v[52:53]
	v_max_f64 v[52:53], v[46:47], v[44:45]
	v_min_f64 v[44:45], v[46:47], v[44:45]
	v_max_f64 v[46:47], v[42:43], v[38:39]
	v_min_f64 v[38:39], v[42:43], v[38:39]
	v_max_f64 v[42:43], v[2:3], v[40:41]
	v_min_f64 v[2:3], v[2:3], v[40:41]
	v_max_f64 v[40:41], v[52:53], v[46:47]
	v_min_f64 v[46:47], v[52:53], v[46:47]
	v_max_f64 v[52:53], v[44:45], v[38:39]
	v_min_f64 v[38:39], v[44:45], v[38:39]
	v_max_f64 v[2:3], v[24:25], v[2:3]
	v_max_f64 v[32:33], v[36:37], v[46:47]
	v_min_f64 v[36:37], v[36:37], v[46:47]
	v_max_f64 v[44:45], v[52:53], v[42:43]
	v_min_f64 v[42:43], v[52:53], v[42:43]
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	v_pk_add_f32 v[6:7], v[50:51], v[68:69]
	v_max_f64 v[68:69], v[32:33], v[40:41]
	v_min_f64 v[32:33], v[32:33], v[40:41]
	v_max_f64 v[40:41], v[44:45], v[36:37]
	v_min_f64 v[36:37], v[44:45], v[36:37]
	v_max_f64 v[44:45], v[38:39], v[42:43]
	v_min_f64 v[38:39], v[38:39], v[42:43]
	v_max_f64 v[10:11], v[10:11], v[48:49]
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	v_max_f64 v[6:7], v[30:31], v[38:39]
	v_max_f64 v[20:21], v[20:21], v[44:45]
	v_max_f64 v[22:23], v[22:23], v[36:37]
	v_max_f64 v[12:13], v[12:13], v[40:41]
	v_max_f64 v[14:15], v[14:15], v[32:33]
	v_max_f64 v[8:9], v[8:9], v[68:69]
	v_mul_f32_e32 v1, v34, v29
	v_cmp_gt_f32_e32 vcc, v0, v28
	v_add_f32_e32 v24, v4, v5
	v_max_f64 v[4:5], v[2:3], v[12:13]
	v_min_f64 v[2:3], v[2:3], v[12:13]
	v_max_f64 v[12:13], v[6:7], v[14:15]
	v_min_f64 v[6:7], v[6:7], v[14:15]
	v_max_f64 v[14:15], v[20:21], v[8:9]
	v_min_f64 v[8:9], v[20:21], v[8:9]
	v_max_f64 v[20:21], v[22:23], v[10:11]
	v_min_f64 v[10:11], v[22:23], v[10:11]
	v_cndmask_b32_e32 v1, v34, v1, vcc
	v_max_f64 v[22:23], v[4:5], v[14:15]
	v_min_f64 v[4:5], v[4:5], v[14:15]
	v_max_f64 v[14:15], v[12:13], v[20:21]
	v_min_f64 v[12:13], v[12:13], v[20:21]
	v_max_f64 v[32:33], v[2:3], v[8:9]
	v_min_f64 v[2:3], v[2:3], v[8:9]
	v_max_f64 v[8:9], v[6:7], v[10:11]
	v_min_f64 v[6:7], v[6:7], v[10:11]
	v_mov_b32_e32 v28, v0
	v_add_f32_e32 v34, v1, v24
	v_max_f64 v[24:25], v[22:23], v[14:15]
	v_min_f64 v[30:31], v[22:23], v[14:15]
	v_max_f64 v[20:21], v[4:5], v[12:13]
	v_min_f64 v[22:23], v[4:5], v[12:13]
	v_max_f64 v[12:13], v[32:33], v[8:9]
	v_min_f64 v[14:15], v[32:33], v[8:9]
	v_max_f64 v[8:9], v[2:3], v[6:7]
	v_min_f64 v[10:11], v[2:3], v[6:7]
	s_cbranch_scc1 .LBB0_31
.Lft15:
	s_and_b32 s0, s9, 0x7ffffff8
	v_mov_b64_e32 v[2:3], v[24:25]
	v_mov_b64_e32 v[24:25], v[30:31]
.LBB0_33:
	s_cmp_ge_i32 s0, s9
	s_cbranch_scc1 .LBB0_48
.Lft16:
	s_mov_b32 s1, 0
	v_lshl_add_u64 v[6:7], s[0:1], 2, v[18:19]
	global_load_dword v1, v[6:7], off
	v_max_f32_e32 v4, v0, v0
	s_mov_b32 s2, 0x3fb8aa3b
	s_or_b32 s1, s0, 1
	s_cmp_ge_u32 s1, s9
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v5, v1, v1
	v_max_f32_e32 v18, v4, v5
	v_pk_add_f32 v[4:5], v[0:1], v[18:19] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v18, v0
	v_pk_mul_f32 v[4:5], v[4:5], s[2:3] op_sel_hi:[1,0]
	s_nop 0
	v_exp_f32_e32 v19, v4
	v_exp_f32_e32 v5, v5
	v_mov_b32_e32 v4, -1
	v_mul_f32_e32 v19, v34, v19
	v_cndmask_b32_e32 v0, v34, v19, vcc
	v_add_f32_e32 v34, v5, v0
	v_mov_b32_e32 v5, 0xff900000
	s_cbranch_scc1 .LBB0_36
.Lft17:
	global_load_dword v19, v[6:7], off offset:4
	v_max_f32_e32 v0, v18, v18
	s_xor_b32 s1, s0, -2
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v4, v19, v19
	v_max_f32_e32 v0, v0, v4
	v_pk_add_f32 v[4:5], v[18:19], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_add_f32_e32 v28, 0, v19
	v_pk_mul_f32 v[26:27], v[4:5], s[2:3] op_sel_hi:[1,0]
	v_cmp_gt_f32_e32 vcc, v0, v18
	v_exp_f32_e32 v4, v26
	v_exp_f32_e32 v26, v27
	v_ashrrev_i32_e32 v19, 31, v28
	v_add_u32_e32 v5, 0x100000, v28
	v_mul_f32_e32 v4, v34, v4
	v_cndmask_b32_e32 v4, v34, v4, vcc
	v_add_f32_e32 v34, v26, v4
	v_xor_b32_e32 v4, s1, v19
	s_branch .LBB0_37
.LBB0_36:
	v_mov_b32_e32 v0, v18
.LBB0_37:
	s_or_b32 s1, s0, 2
	v_mov_b32_e32 v18, -1
	s_cmp_ge_u32 s1, s9
	v_mov_b32_e32 v19, 0xff900000
	s_cbranch_scc1 .LBB0_39
.Lft18:
	global_load_dword v29, v[6:7], off offset:8
	v_max_f32_e32 v26, v0, v0
	v_mov_b32_e32 v28, v0
	s_xor_b32 s1, s0, -3
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v27, v29, v29
	v_max_f32_e32 v30, v26, v27
	v_add_f32_e32 v31, 0, v29
	v_pk_add_f32 v[28:29], v[28:29], v[30:31] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v30, v0
	v_pk_mul_f32 v[28:29], v[28:29], s[2:3] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v26, 31, v31
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_add_u32_e32 v27, 0x100000, v31
	v_xor_b32_e32 v26, s1, v26
	v_mul_f32_e32 v28, v34, v28
	v_cndmask_b32_e32 v0, v34, v28, vcc
	v_add_f32_e32 v34, v29, v0
	v_mov_b32_e32 v0, v30
	s_or_b32 s1, s0, 3
	s_cmp_ge_u32 s1, s9
	s_cbranch_scc0 .LBB0_40
.Lft19:
	s_branch .LBB0_41
.LBB0_39:
	v_mov_b64_e32 v[26:27], v[18:19]
	s_or_b32 s1, s0, 3
	s_cmp_ge_u32 s1, s9
	s_cbranch_scc1 .LBB0_41
.LBB0_40:
	global_load_dword v29, v[6:7], off offset:12
	v_max_f32_e32 v18, v0, v0
	v_mov_b32_e32 v28, v0
	s_xor_b32 s1, s0, -4
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v19, v29, v29
	v_max_f32_e32 v30, v18, v19
	v_add_f32_e32 v31, 0, v29
	v_pk_add_f32 v[28:29], v[28:29], v[30:31] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v30, v0
	v_pk_mul_f32 v[28:29], v[28:29], s[2:3] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v18, 31, v31
	v_exp_f32_e32 v28, v28
	v_exp_f32_e32 v29, v29
	v_add_u32_e32 v19, 0x100000, v31
	v_xor_b32_e32 v18, s1, v18
	v_mul_f32_e32 v28, v34, v28
	v_cndmask_b32_e32 v0, v34, v28, vcc
	v_add_f32_e32 v34, v29, v0
	v_mov_b32_e32 v0, v30
.LBB0_41:
	s_or_b32 s1, s0, 4
	v_mov_b32_e32 v28, -1
	s_cmp_ge_u32 s1, s9
	v_mov_b32_e32 v29, 0xff900000
	s_cbranch_scc1 .LBB0_43
.Lft20:
	global_load_dword v33, v[6:7], off offset:16
	v_max_f32_e32 v30, v0, v0
	v_mov_b32_e32 v32, v0
	s_xor_b32 s1, s0, -5
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v31, v33, v33
	v_max_f32_e32 v36, v30, v31
	v_add_f32_e32 v35, 0, v33
	v_pk_add_f32 v[32:33], v[32:33], v[36:37] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v36, v0
	v_pk_mul_f32 v[32:33], v[32:33], s[2:3] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v30, 31, v35
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	v_add_u32_e32 v31, 0x100000, v35
	v_xor_b32_e32 v30, s1, v30
	v_mul_f32_e32 v32, v34, v32
	v_cndmask_b32_e32 v0, v34, v32, vcc
	v_add_f32_e32 v34, v33, v0
	v_mov_b32_e32 v0, v36
	s_or_b32 s1, s0, 5
	s_cmp_ge_u32 s1, s9
	s_cbranch_scc0 .LBB0_44
.Lft21:
	s_branch .LBB0_45
.LBB0_43:
	v_mov_b64_e32 v[30:31], v[28:29]
	s_or_b32 s1, s0, 5
	s_cmp_ge_u32 s1, s9
	s_cbranch_scc1 .LBB0_45
.LBB0_44:
	global_load_dword v33, v[6:7], off offset:20
	v_max_f32_e32 v28, v0, v0
	v_mov_b32_e32 v32, v0
	s_xor_b32 s1, s0, -6
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v29, v33, v33
	v_max_f32_e32 v36, v28, v29
	v_add_f32_e32 v35, 0, v33
	v_pk_add_f32 v[32:33], v[32:33], v[36:37] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v36, v0
	v_pk_mul_f32 v[32:33], v[32:33], s[2:3] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v28, 31, v35
	v_exp_f32_e32 v32, v32
	v_exp_f32_e32 v33, v33
	v_add_u32_e32 v29, 0x100000, v35
	v_xor_b32_e32 v28, s1, v28
	v_mul_f32_e32 v32, v34, v32
	v_cndmask_b32_e32 v0, v34, v32, vcc
	v_add_f32_e32 v34, v33, v0
	v_mov_b32_e32 v0, v36
.LBB0_45:
	s_or_b32 s1, s0, 6
	s_mov_b32 s2, -1
	s_mov_b32 s3, 0xff900000
	v_mov_b32_e32 v32, -1
	s_cmp_ge_u32 s1, s9
	v_mov_b32_e32 v33, 0xff900000
	s_cbranch_scc1 .LBB0_47
.Lft22:
	global_load_dword v7, v[6:7], off offset:24
	v_max_f32_e32 v32, v0, v0
	v_mov_b32_e32 v6, v0
	s_mov_b32 s4, 0x3fb8aa3b
	s_xor_b32 s1, s0, -7
	s_waitcnt vmcnt(0)
	v_max_f32_e32 v33, v7, v7
	v_max_f32_e32 v36, v32, v33
	v_add_f32_e32 v35, 0, v7
	v_pk_add_f32 v[6:7], v[6:7], v[36:37] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_gt_f32_e32 vcc, v36, v0
	v_pk_mul_f32 v[6:7], v[6:7], s[4:5] op_sel_hi:[1,0]
	v_ashrrev_i32_e32 v32, 31, v35
	v_exp_f32_e32 v6, v6
	v_exp_f32_e32 v7, v7
	v_add_u32_e32 v33, 0x100000, v35
	v_xor_b32_e32 v32, s1, v32
	v_mul_f32_e32 v6, v34, v6
	v_cndmask_b32_e32 v0, v34, v6, vcc
	v_add_f32_e32 v34, v7, v0
	v_mov_b32_e32 v0, v36
.LBB0_47:
	v_add_f32_e32 v1, 0, v1
	v_add_u32_e32 v7, 0x100000, v1
	v_ashrrev_i32_e32 v1, 31, v1
	v_xnor_b32_e32 v6, s0, v1
	v_max_f64 v[6:7], v[6:7], v[6:7]
	v_max_f64 v[26:27], v[26:27], v[26:27]
	v_max_f64 v[18:19], v[18:19], v[18:19]
	v_max_f64 v[4:5], v[4:5], v[4:5]
	v_max_f64 v[36:37], v[6:7], v[26:27]
	v_min_f64 v[6:7], v[6:7], v[26:27]
	v_max_f64 v[26:27], v[4:5], v[18:19]
	v_min_f64 v[4:5], v[4:5], v[18:19]
	v_max_f64 v[18:19], v[32:33], v[32:33]
	v_max_f64 v[30:31], v[30:31], v[30:31]
	v_max_f64 v[28:29], v[28:29], v[28:29]
	v_max_f64 v[32:33], v[30:31], v[18:19]
	v_min_f64 v[18:19], v[30:31], v[18:19]
	v_max_f64 v[30:31], v[28:29], s[2:3]
	v_min_f64 v[28:29], v[28:29], s[2:3]
	v_max_f64 v[38:39], v[36:37], v[32:33]
	v_min_f64 v[32:33], v[36:37], v[32:33]
	v_max_f64 v[36:37], v[26:27], v[30:31]
	v_min_f64 v[26:27], v[26:27], v[30:31]
	v_max_f64 v[30:31], v[6:7], v[18:19]
	v_min_f64 v[6:7], v[6:7], v[18:19]
	v_max_f64 v[18:19], v[4:5], v[28:29]
	v_min_f64 v[4:5], v[4:5], v[28:29]
	v_max_f64 v[28:29], v[38:39], v[36:37]
	v_min_f64 v[36:37], v[38:39], v[36:37]
	v_max_f64 v[38:39], v[30:31], v[18:19]
	v_min_f64 v[18:19], v[30:31], v[18:19]
	v_max_f64 v[30:31], v[32:33], v[26:27]
	v_min_f64 v[26:27], v[32:33], v[26:27]
	v_max_f64 v[32:33], v[6:7], v[4:5]
	v_min_f64 v[4:5], v[6:7], v[4:5]
	v_max_f64 v[6:7], v[38:39], v[30:31]
	v_min_f64 v[30:31], v[38:39], v[30:31]
	v_max_f64 v[38:39], v[18:19], v[26:27]
	v_min_f64 v[18:19], v[18:19], v[26:27]
	v_max_f64 v[26:27], v[36:37], v[30:31]
	v_min_f64 v[30:31], v[36:37], v[30:31]
	v_max_f64 v[36:37], v[38:39], v[32:33]
	v_min_f64 v[32:33], v[38:39], v[32:33]
	v_max_f64 v[2:3], v[2:3], v[2:3]
	v_max_f64 v[38:39], v[26:27], v[6:7]
	v_min_f64 v[6:7], v[26:27], v[6:7]
	v_max_f64 v[26:27], v[36:37], v[30:31]
	v_min_f64 v[30:31], v[36:37], v[30:31]
	v_max_f64 v[36:37], v[18:19], v[32:33]
	v_min_f64 v[18:19], v[18:19], v[32:33]
	v_max_f64 v[2:3], v[2:3], v[4:5]
	v_max_f64 v[4:5], v[24:25], v[24:25]
	v_max_f64 v[4:5], v[4:5], v[18:19]
	v_max_f64 v[18:19], v[20:21], v[20:21]
	v_max_f64 v[20:21], v[22:23], v[22:23]
	v_max_f64 v[12:13], v[12:13], v[12:13]
	v_max_f64 v[14:15], v[14:15], v[14:15]
	v_max_f64 v[8:9], v[8:9], v[8:9]
	v_max_f64 v[10:11], v[10:11], v[10:11]
	v_max_f64 v[18:19], v[18:19], v[36:37]
	v_max_f64 v[20:21], v[20:21], v[30:31]
	v_max_f64 v[12:13], v[12:13], v[26:27]
	v_max_f64 v[6:7], v[14:15], v[6:7]
	v_max_f64 v[8:9], v[8:9], v[38:39]
	v_max_f64 v[10:11], v[10:11], v[28:29]
	v_max_f64 v[14:15], v[2:3], v[12:13]
	v_min_f64 v[2:3], v[2:3], v[12:13]
	v_max_f64 v[12:13], v[4:5], v[6:7]
	v_min_f64 v[4:5], v[4:5], v[6:7]
	v_max_f64 v[6:7], v[18:19], v[8:9]
	v_min_f64 v[8:9], v[18:19], v[8:9]
	v_max_f64 v[18:19], v[20:21], v[10:11]
	v_min_f64 v[10:11], v[20:21], v[10:11]
	v_max_f64 v[20:21], v[14:15], v[6:7]
	v_min_f64 v[6:7], v[14:15], v[6:7]
	v_max_f64 v[14:15], v[12:13], v[18:19]
	v_min_f64 v[12:13], v[12:13], v[18:19]
	v_max_f64 v[18:19], v[2:3], v[8:9]
	v_min_f64 v[26:27], v[2:3], v[8:9]
	v_max_f64 v[8:9], v[4:5], v[10:11]
	v_min_f64 v[4:5], v[4:5], v[10:11]
	v_max_f64 v[2:3], v[20:21], v[14:15]
	v_min_f64 v[24:25], v[20:21], v[14:15]
	v_max_f64 v[20:21], v[6:7], v[12:13]
	v_min_f64 v[22:23], v[6:7], v[12:13]
	v_max_f64 v[12:13], v[18:19], v[8:9]
	v_min_f64 v[14:15], v[18:19], v[8:9]
	v_max_f64 v[8:9], v[26:27], v[4:5]
	v_min_f64 v[10:11], v[26:27], v[4:5]
.LBB0_48:
	v_div_scale_f32 v1, s[0:1], v34, v34, 1.0
	v_rcp_f32_e32 v6, v1
	v_lshlrev_b64 v[4:5], 5, v[16:17]
	v_lshl_add_u64 v[26:27], s[6:7], 0, v[4:5]
	v_lshl_add_u64 v[28:29], s[12:13], 0, v[4:5]
	v_fma_f32 v4, -v1, v6, 1.0
	v_fmac_f32_e32 v6, v4, v6
	v_div_scale_f32 v4, vcc, 1.0, v34, 1.0
	v_mul_f32_e32 v5, v4, v6
	v_fma_f32 v7, -v1, v5, v4
	v_fmac_f32_e32 v5, v7, v6
	v_fma_f32 v1, -v1, v5, v4
	v_div_fmas_f32 v1, v1, v6, v5
	v_add_u32_e32 v5, 0xfff00000, v25
	v_div_fixup_f32 v30, v1, v34, 1.0
	v_add_u32_e32 v4, 0xfff00000, v3
	v_ashrrev_i32_e32 v1, 31, v5
	v_ashrrev_i32_e32 v3, 31, v4
	v_xor_b32_e32 v1, v1, v24
	v_pk_add_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	s_mov_b32 s0, 0x3fb8aa3b
	v_pk_mul_f32 v[4:5], v[4:5], s[0:1] op_sel_hi:[1,0]
	v_xor_b32_e32 v2, v3, v2
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v5, v5
	v_xor_b32_e32 v3, -1, v1
	v_xor_b32_e32 v2, -1, v2
	v_pk_mul_f32 v[16:17], v[30:31], v[4:5] op_sel_hi:[0,1]
	v_add_u32_e32 v5, 0xfff00000, v23
	v_add_u32_e32 v4, 0xfff00000, v21
	v_ashrrev_i32_e32 v1, 31, v5
	v_ashrrev_i32_e32 v18, 31, v4
	v_xor_b32_e32 v1, v1, v22
	v_pk_add_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	s_nop 0
	v_pk_mul_f32 v[4:5], v[4:5], s[0:1] op_sel_hi:[1,0]
	s_nop 0
	v_exp_f32_e32 v6, v4
	v_exp_f32_e32 v7, v5
	v_xor_b32_e32 v4, v18, v20
	v_xor_b32_e32 v5, -1, v1
	v_xor_b32_e32 v4, -1, v4
	v_pk_mul_f32 v[18:19], v[30:31], v[6:7] op_sel_hi:[0,1]
	global_store_dwordx4 v[26:27], v[16:19], off
	global_store_dwordx4 v[28:29], v[2:5], off
	s_nop 1
	v_add_u32_e32 v3, 0xfff00000, v15
	v_add_u32_e32 v2, 0xfff00000, v13
	v_ashrrev_i32_e32 v1, 31, v3
	v_ashrrev_i32_e32 v6, 31, v2
	v_xor_b32_e32 v1, v1, v14
	v_pk_add_f32 v[2:3], v[2:3], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	s_nop 0
	v_pk_mul_f32 v[2:3], v[2:3], s[0:1] op_sel_hi:[1,0]
	s_nop 0
	v_exp_f32_e32 v4, v2
	v_exp_f32_e32 v5, v3
	v_xor_b32_e32 v2, v6, v12
	v_xor_b32_e32 v3, -1, v1
	v_xor_b32_e32 v2, -1, v2
	v_pk_mul_f32 v[6:7], v[30:31], v[4:5] op_sel_hi:[0,1]
	v_add_u32_e32 v5, 0xfff00000, v11
	v_add_u32_e32 v4, 0xfff00000, v9
	v_ashrrev_i32_e32 v1, 31, v5
	v_xor_b32_e32 v10, v1, v10
	v_pk_add_f32 v[0:1], v[4:5], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_ashrrev_i32_e32 v9, 31, v4
	v_pk_mul_f32 v[0:1], v[0:1], s[0:1] op_sel_hi:[1,0]
	v_xor_b32_e32 v4, v9, v8
	v_exp_f32_e32 v0, v0
	v_exp_f32_e32 v1, v1
	v_xor_b32_e32 v5, -1, v10
	v_xor_b32_e32 v4, -1, v4
	v_pk_mul_f32 v[8:9], v[30:31], v[0:1] op_sel_hi:[0,1]
	global_store_dwordx4 v[26:27], v[6:9], off offset:16
	global_store_dwordx4 v[28:29], v[2:5], off offset:16
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
		.amdhsa_next_free_vgpr 72
		.amdhsa_next_free_sgpr 24
		.amdhsa_accum_offset 72
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
  .vgpr_count: 72
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
