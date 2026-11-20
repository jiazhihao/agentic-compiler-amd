	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_rope
	.globl	fi_rope
	.p2align	8
	.type	fi_rope,@function
fi_rope:
	s_load_dword s4, s[0:1], 0x94
	s_load_dwordx4 s[36:39], s[0:1], 0x28
	v_bfe_u32 v1, v0, 10, 10
	s_waitcnt lgkmcnt(0)
	s_lshr_b32 s4, s4, 16
	s_mul_i32 s2, s2, s4
	v_add_u32_e32 v8, s2, v1
	v_cmp_gt_u32_e32 vcc, s36, v8
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_53
.Lft0:
	s_add_i32 s38, s38, s37
	s_lshl_b32 s33, s3, 2
	s_cmp_le_u32 s38, s33
	s_cbranch_scc1 .LBB0_53
.Lft1:
	s_load_dwordx2 s[2:3], s[0:1], 0x20
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v9, v7
	s_load_dwordx8 s[24:31], s[0:1], 0x0
	s_load_dwordx16 s[8:23], s[0:1], 0x38
	s_load_dwordx4 s[40:43], s[0:1], 0x78
	s_sub_i32 s54, s38, s33
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], v[8:9], 2, s[2:3]
	global_load_dword v1, v[2:3], off
	v_and_b32_e32 v9, 0x3ff, v0
	s_min_u32 s36, s54, 4
	v_lshlrev_b32_e32 v4, 2, v9
	s_mov_b64 s[0:1], -1
	s_cmpk_eq_i32 s39, 0x80
	v_cmp_eq_f32_e64 s[34:35], s43, 1.0
	s_waitcnt vmcnt(0)
	v_cvt_f32_i32_e32 v5, v1
	s_cbranch_scc1 .LBB0_29
.Lft2:
	s_lshr_b32 s55, s39, 1
	v_cvt_f32_u32_e32 v0, s55
	s_cmp_lg_u32 s38, s33
	v_cvt_f32_u32_e32 v24, s39
	s_cselect_b64 s[46:47], -1, 0
	v_rcp_iflag_f32_e32 v0, v0
	s_sub_i32 s57, 0, s55
	s_mov_b32 s0, 0
	s_mov_b64 s[48:49], -1
	v_mul_f32_e32 v0, 0x4f7ffffe, v0
	v_cvt_u32_f32_e32 v0, v0
	s_mov_b32 s56, 0x3f2aaaab
	s_mov_b32 s44, 0x3f317218
	s_mov_b32 s45, 2.0
	v_mul_lo_u32 v1, s57, v0
	v_mul_hi_u32 v1, v0, v1
	s_max_u32 s58, s36, 1
	v_add_u32_e32 v25, v0, v1
	v_mov_b32_e32 v26, 0x3e91f4c4
	s_movk_i32 s59, 0x204
	s_mov_b32 s60, 0x7f800000
	s_mov_b32 s61, 0x42b17218
	s_mov_b32 s62, 0x3fb8aa3b
	s_mov_b32 s63, 0xc2ce8ed0
	s_brev_b32 s64, -2
	s_brev_b32 s65, 18
	s_mov_b32 s66, 0xfe5163ab
	s_mov_b32 s67, 0x3c439041
	s_mov_b32 s68, 0xdb629599
	s_mov_b32 s69, 0xf534ddc0
	s_mov_b32 s70, 0xfc2757d1
	s_mov_b32 s71, 0x4e441529
	s_mov_b32 s72, 0xa2f9836e
	s_mov_b32 s73, 0x3fc90fda
	s_mov_b32 s74, 0x3f22f983
	s_mov_b32 s75, 0xbfc90fda
	v_mov_b32_e32 v27, 0x3c0881c4
	v_mov_b32_e32 v28, 0xbab64f3b
	s_brev_b32 s76, 1
	s_movk_i32 s77, 0x1f8
	v_mov_b32_e32 v29, 0x37000000
	v_mov_b32_e32 v30, 0x7f800000
	v_mov_b32_e32 v31, 0x7fc00000
	v_not_b32_e32 v32, 63
	v_not_b32_e32 v33, 31
	s_branch .LBB0_5
.LBB0_4:
	s_mov_b32 s0, 64
	s_mov_b64 s[48:49], 0
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_28
.LBB0_5:
	v_add_u32_e32 v6, s0, v4
	v_mov_b32_e32 v15, 0
	v_cmp_gt_u32_e64 s[0:1], s39, v6
	v_mov_b32_e32 v14, v15
	v_mov_b32_e32 v17, v15
	v_mov_b32_e32 v16, v15
	v_mov_b32_e32 v11, v15
	v_mov_b32_e32 v10, v15
	v_mov_b32_e32 v13, v15
	v_mov_b32_e32 v12, v15
	s_and_saveexec_b64 s[50:51], s[0:1]
	s_cbranch_execz .LBB0_23
.Lft3:
	v_mul_hi_u32 v0, v6, v25
	v_mul_lo_u32 v0, v0, s55
	v_sub_u32_e32 v0, v6, v0
	v_subrev_u32_e32 v1, s55, v0
	v_cmp_le_u32_e32 vcc, s55, v0
	v_mov_b32_e32 v3, s43
	s_nop 0
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_subrev_u32_e32 v1, s55, v0
	v_cmp_le_u32_e32 vcc, s55, v0
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_lshlrev_b32_e32 v0, 1, v0
	v_cvt_f32_u32_e32 v0, v0
	v_div_scale_f32 v1, s[2:3], v24, v24, v0
	v_rcp_f32_e32 v2, v1
	v_div_scale_f32 v10, vcc, v0, v24, v0
	v_fma_f32 v11, -v1, v2, 1.0
	v_fmac_f32_e32 v2, v11, v2
	v_mul_f32_e32 v11, v10, v2
	v_fma_f32 v12, -v1, v11, v10
	v_fmac_f32_e32 v11, v12, v2
	v_fma_f32 v1, -v1, v11, v10
	v_div_fmas_f32 v1, v1, v2, v11
	v_div_fixup_f32 v0, v1, v24, v0
	v_cndmask_b32_e64 v36, v0, 1.0, s[34:35]
	v_cmp_neq_f32_e32 vcc, 0, v36
	s_nop 1
	v_cndmask_b32_e32 v37, 1.0, v3, vcc
	v_frexp_mant_f32_e64 v0, |v37|
	v_cmp_gt_f32_e32 vcc, s56, v0
	v_frexp_exp_i32_f32_e32 v16, v37
	v_cmp_ngt_f32_e64 s[4:5], 0, v37
	v_cndmask_b32_e64 v1, 1.0, 2.0, vcc
	v_mul_f32_e32 v0, v0, v1
	v_add_f32_e32 v3, 1.0, v0
	v_rcp_f32_e32 v14, v3
	v_add_f32_e32 v1, -1.0, v3
	v_sub_f32_e32 v11, v0, v1
	v_add_f32_e32 v1, -1.0, v0
	v_mul_f32_e32 v15, v1, v14
	v_mul_f32_e32 v2, v3, v15
	v_fma_f32 v10, v15, v3, -v2
	v_fmac_f32_e32 v10, v15, v11
	v_add_f32_e32 v0, v2, v10
	v_sub_f32_e32 v3, v1, v0
	v_pk_add_f32 v[12:13], v[0:1], v[2:3] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v11, v0
	v_pk_add_f32 v[0:1], v[12:13], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_lt_f32_e64 s[6:7], |v37|, 1.0
	v_add_f32_e32 v0, v0, v1
	v_add_f32_e32 v0, v3, v0
	v_mul_f32_e32 v1, v14, v0
	v_add_f32_e32 v0, v15, v1
	v_sub_f32_e32 v2, v0, v15
	v_sub_f32_e32 v17, v1, v2
	v_mul_f32_e32 v1, v0, v0
	v_fma_f32 v3, v0, v0, -v1
	v_add_f32_e32 v18, v17, v17
	v_fmac_f32_e32 v3, v0, v18
	v_add_f32_e32 v2, v1, v3
	v_fmamk_f32 v10, v2, 0x3e76c4e1, v26
	v_fmaak_f32 v10, v2, v10, 0x3ecccdef
	v_sub_f32_e32 v1, v2, v1
	v_sub_f32_e32 v19, v3, v1
	v_mul_f32_e32 v1, v2, v10
	v_fma_f32 v3, v2, v10, -v1
	v_fmac_f32_e32 v3, v19, v10
	v_add_f32_e32 v10, v1, v3
	v_add_f32_e32 v11, 0x3f2aaaaa, v10
	v_sub_f32_e32 v1, v10, v1
	v_sub_f32_e32 v1, v3, v1
	v_add_f32_e32 v3, 0xbf2aaaaa, v11
	v_add_f32_e32 v1, 0x31739010, v1
	v_sub_f32_e32 v3, v10, v3
	v_pk_mul_f32 v[12:13], v[0:1], v[2:3]
	v_pk_add_f32 v[14:15], v[0:1], v[2:3]
	v_fma_f32 v10, v2, v0, -v12
	v_fmac_f32_e32 v10, v2, v17
	v_mov_b32_e32 v13, v15
	v_fmac_f32_e32 v10, v19, v0
	v_pk_add_f32 v[2:3], v[12:13], v[10:11]
	s_nop 0
	v_sub_f32_e32 v1, v2, v12
	v_sub_f32_e32 v1, v10, v1
	v_sub_f32_e32 v10, v11, v3
	v_mul_f32_e32 v11, v2, v3
	v_add_f32_e32 v10, v15, v10
	v_fma_f32 v12, v2, v3, -v11
	v_fmac_f32_e32 v12, v2, v10
	v_fmac_f32_e32 v12, v1, v3
	v_subbrev_co_u32_e32 v1, vcc, 0, v16, vcc
	v_cvt_f32_i32_e32 v2, v1
	v_add_f32_e32 v1, v11, v12
	v_sub_f32_e32 v3, v1, v11
	v_sub_f32_e32 v3, v12, v3
	v_add_f32_e32 v12, v18, v3
	v_mov_b32_e32 v3, v0
	v_pk_mul_f32 v[10:11], v[2:3], s[44:45]
	s_nop 0
	v_fma_f32 v0, v2, s44, -v10
	v_fmac_f32_e32 v0, 0xb102e308, v2
	v_pk_add_f32 v[2:3], v[10:11], v[0:1]
	s_nop 0
	v_sub_f32_e32 v11, v3, v11
	v_sub_f32_e32 v1, v1, v11
	v_add_f32_e32 v11, v12, v1
	v_pk_add_f32 v[12:13], v[2:3], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[14:15], v[2:3], v[10:11]
	v_mov_b32_e32 v1, v2
	v_mov_b32_e32 v14, v12
	v_pk_add_f32 v[18:19], v[0:1], v[14:15]
	v_mov_b32_e32 v22, v15
	v_pk_add_f32 v[20:21], v[18:19], v[2:3] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v23, v19
	v_pk_mov_b32 v[34:35], v[2:3], v[20:21] op_sel:[1,0]
	v_pk_add_f32 v[16:17], v[0:1], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[22:23], v[22:23], v[34:35] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v10, v11
	v_mov_b32_e32 v11, v2
	v_mov_b32_e32 v1, v15
	v_mov_b32_e32 v13, v20
	v_pk_add_f32 v[2:3], v[10:11], v[22:23] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[0:1], v[0:1], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v17, v19
	v_pk_add_f32 v[0:1], v[0:1], v[2:3]
	s_nop 0
	v_pk_add_f32 v[10:11], v[0:1], v[0:1] op_sel:[0,1] op_sel_hi:[1,0]
	s_nop 0
	v_pk_add_f32 v[12:13], v[18:19], v[10:11] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v1, v12
	v_pk_add_f32 v[14:15], v[0:1], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v3, v10
	v_sub_f32_e32 v0, v0, v14
	v_pk_add_f32 v[2:3], v[2:3], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v0, v16, v0
	v_add_f32_e32 v0, v2, v0
	v_add_f32_e32 v0, v0, v3
	v_add_f32_e32 v1, v12, v0
	v_sub_f32_e32 v2, v1, v12
	v_sub_f32_e32 v0, v0, v2
	v_mul_f32_e32 v2, v36, v1
	v_fma_f32 v1, v36, v1, -v2
	v_fmac_f32_e32 v1, v36, v0
	v_add_f32_e32 v0, v2, v1
	v_cmp_class_f32_e64 vcc, v2, s59
	v_sub_f32_e32 v3, v0, v2
	v_sub_f32_e32 v1, v1, v3
	v_cndmask_b32_e32 v0, v0, v2, vcc
	v_cmp_eq_f32_e32 vcc, s61, v0
	s_nop 1
	v_cndmask_b32_e32 v2, 0, v29, vcc
	v_sub_f32_e32 v3, v0, v2
	v_mul_f32_e32 v10, 0x3fb8aa3b, v3
	v_fma_f32 v11, v3, s62, -v10
	v_rndne_f32_e32 v12, v10
	v_fmac_f32_e32 v11, 0x32a5705f, v3
	v_sub_f32_e32 v10, v10, v12
	v_add_f32_e32 v10, v10, v11
	v_exp_f32_e32 v10, v10
	v_cvt_i32_f32_e32 v11, v12
	v_cmp_neq_f32_e64 vcc, |v0|, s60
	s_nop 1
	v_cndmask_b32_e32 v0, 0, v1, vcc
	v_ldexp_f32 v1, v10, v11
	v_cmp_ngt_f32_e32 vcc, s63, v3
	v_add_f32_e32 v0, v2, v0
	s_nop 0
	v_cndmask_b32_e32 v1, 0, v1, vcc
	v_cmp_nlt_f32_e32 vcc, s61, v3
	s_nop 1
	v_cndmask_b32_e32 v1, v30, v1, vcc
	v_fma_f32 v0, v1, v0, v1
	v_cmp_class_f32_e64 vcc, v1, s59
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_trunc_f32_e32 v1, v36
	v_cmp_eq_f32_e32 vcc, v1, v36
	v_mul_f32_e32 v1, 0.5, v36
	v_trunc_f32_e32 v2, v1
	v_cmp_neq_f32_e64 s[2:3], v2, v1
	s_and_b64 s[2:3], vcc, s[2:3]
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e64 v1, 1.0, v37, s[2:3]
	v_cmp_neq_f32_e64 s[4:5], v36, |v36|
	v_bfi_b32 v0, s64, v0, v1
	s_xor_b64 s[4:5], s[4:5], s[6:7]
	v_cndmask_b32_e32 v0, v31, v0, vcc
	v_cndmask_b32_e64 v1, v30, 0, s[4:5]
	v_cmp_neq_f32_e64 vcc, |v37|, 1.0
	v_cmp_class_f32_e64 s[4:5], v37, s59
	v_cndmask_b32_e64 v2, 0, v37, s[2:3]
	v_cndmask_b32_e32 v1, 1.0, v1, vcc
	v_cmp_class_f32_e64 vcc, v36, s59
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_cmp_eq_f32_e32 vcc, 0, v37
	s_nop 1
	v_cndmask_b32_e64 v1, v30, 0, vcc
	v_bfi_b32 v1, s64, v1, v2
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_cmp_o_f32_e32 vcc, v37, v36
	v_mov_b32_e32 v1, s41
	s_nop 0
	v_cndmask_b32_e32 v0, v31, v0, vcc
	v_fma_f32 v1, s40, v0, v1
	v_min_f32_e32 v1, 1.0, v1
	v_max_f32_e32 v1, 0, v1
	v_sub_f32_e32 v2, 1.0, v1
	v_mul_f32_e32 v3, s42, v0
	v_mul_f32_e32 v2, v3, v2
	v_fmac_f32_e32 v2, v0, v1
	v_mul_f32_e32 v0, v2, v5
	v_cmp_ge_f32_e64 s[2:3], |v0|, s65
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_xor_b64 s[52:53], exec, s[4:5]
	s_cbranch_execz .LBB0_8
.Lft4:
	v_frexp_exp_i32_f32_e32 v2, v0
	v_add_u32_e32 v2, 6, v2
	v_cmp_lt_u32_e32 vcc, 63, v2
	v_frexp_mant_f32_e64 v1, |v0|
	v_mul_f32_e32 v1, 0x4b800000, v1
	v_cndmask_b32_e32 v3, 0, v32, vcc
	v_add_u32_e32 v2, v3, v2
	v_cmp_lt_u32_e64 s[2:3], 31, v2
	v_cvt_u32_f32_e32 v1, v1
	v_mov_b32_e32 v11, v7
	v_cndmask_b32_e64 v3, 0, v33, s[2:3]
	v_add_u32_e32 v2, v3, v2
	v_cmp_lt_u32_e64 s[4:5], 31, v2
	v_mov_b32_e32 v13, v7
	v_mov_b32_e32 v15, v7
	v_cndmask_b32_e64 v3, 0, v33, s[4:5]
	v_add_u32_e32 v22, v3, v2
	v_mad_u64_u32 v[2:3], s[6:7], v1, s66, 0
	v_mov_b32_e32 v10, v3
	v_mad_u64_u32 v[10:11], s[6:7], v1, s67, v[10:11]
	v_mov_b32_e32 v12, v11
	v_mad_u64_u32 v[12:13], s[6:7], v1, s68, v[12:13]
	v_mov_b32_e32 v14, v13
	v_mad_u64_u32 v[14:15], s[6:7], v1, s69, v[14:15]
	v_mov_b32_e32 v16, v15
	v_mov_b32_e32 v17, v7
	v_mad_u64_u32 v[16:17], s[6:7], v1, s70, v[16:17]
	v_mov_b32_e32 v18, v17
	v_mov_b32_e32 v19, v7
	v_mad_u64_u32 v[18:19], s[6:7], v1, s71, v[18:19]
	v_mov_b32_e32 v20, v19
	v_mov_b32_e32 v21, v7
	v_mad_u64_u32 v[20:21], s[6:7], v1, s72, v[20:21]
	v_cndmask_b32_e32 v3, v18, v14, vcc
	v_cndmask_b32_e32 v1, v20, v16, vcc
	v_cndmask_b32_e32 v13, v21, v18, vcc
	v_cndmask_b32_e64 v11, v1, v3, s[2:3]
	v_cndmask_b32_e64 v1, v13, v1, s[2:3]
	v_cndmask_b32_e32 v13, v16, v12, vcc
	v_cndmask_b32_e64 v3, v3, v13, s[2:3]
	v_cndmask_b32_e64 v1, v1, v11, s[4:5]
	v_cndmask_b32_e64 v11, v11, v3, s[4:5]
	v_sub_u32_e32 v15, 32, v22
	v_alignbit_b32 v16, v1, v11, v15
	v_cmp_eq_u32_e64 s[6:7], 0, v22
	v_cndmask_b32_e32 v2, v12, v2, vcc
	s_nop 0
	v_cndmask_b32_e64 v16, v16, v1, s[6:7]
	v_cndmask_b32_e32 v1, v14, v10, vcc
	v_cndmask_b32_e64 v10, v13, v1, s[2:3]
	v_cndmask_b32_e64 v3, v3, v10, s[4:5]
	v_alignbit_b32 v13, v11, v3, v15
	v_cndmask_b32_e64 v11, v13, v11, s[6:7]
	v_bfe_u32 v17, v16, 29, 1
	v_cndmask_b32_e64 v1, v1, v2, s[2:3]
	v_alignbit_b32 v13, v16, v11, 30
	v_sub_u32_e32 v18, 0, v17
	v_cndmask_b32_e64 v1, v10, v1, s[4:5]
	v_xor_b32_e32 v13, v13, v18
	v_alignbit_b32 v2, v3, v1, v15
	v_cndmask_b32_e64 v2, v2, v3, s[6:7]
	v_ffbh_u32_e32 v10, v13
	v_alignbit_b32 v3, v11, v2, 30
	v_min_u32_e32 v10, 32, v10
	v_alignbit_b32 v1, v2, v1, 30
	v_xor_b32_e32 v3, v3, v18
	v_sub_u32_e32 v11, 31, v10
	v_xor_b32_e32 v1, v1, v18
	v_alignbit_b32 v12, v13, v3, v11
	v_alignbit_b32 v1, v3, v1, v11
	v_alignbit_b32 v2, v12, v1, 9
	v_ffbh_u32_e32 v3, v2
	v_min_u32_e32 v3, 32, v3
	v_lshrrev_b32_e32 v14, 29, v16
	v_not_b32_e32 v11, v3
	v_alignbit_b32 v1, v2, v1, v11
	v_lshlrev_b32_e32 v2, 31, v14
	v_or_b32_e32 v11, 0x33000000, v2
	v_add_lshl_u32 v3, v3, v10, 23
	v_lshrrev_b32_e32 v1, 9, v1
	v_sub_u32_e32 v3, v11, v3
	v_or_b32_e32 v2, 0.5, v2
	v_lshlrev_b32_e32 v10, 23, v10
	v_or_b32_e32 v1, v3, v1
	v_lshrrev_b32_e32 v3, 9, v12
	v_sub_u32_e32 v2, v2, v10
	v_or_b32_e32 v2, v3, v2
	v_mul_f32_e32 v3, 0x3fc90fda, v2
	v_fma_f32 v10, v2, s73, -v3
	v_fmac_f32_e32 v10, 0x33a22168, v2
	v_fmac_f32_e32 v10, 0x3fc90fda, v1
	v_lshrrev_b32_e32 v2, 30, v16
	v_add_f32_e32 v1, v3, v10
	v_add_u32_e32 v2, v17, v2
.LBB0_8:
	s_andn2_saveexec_b64 s[2:3], s[52:53]
	v_mul_f32_e64 v1, |v0|, s74
	v_rndne_f32_e32 v3, v1
	v_cvt_i32_f32_e32 v2, v3
	v_fma_f32 v1, v3, s75, |v0|
	v_fmac_f32_e32 v1, 0xb3a22168, v3
	v_fmac_f32_e32 v1, 0xa7c234c4, v3
	s_or_b64 exec, exec, s[2:3]
	v_or_b32_e32 v3, 1, v6
	v_mul_hi_u32 v10, v3, v25
	v_mul_lo_u32 v10, v10, s55
	v_sub_u32_e32 v3, v3, v10
	v_subrev_u32_e32 v10, s55, v3
	v_cmp_le_u32_e32 vcc, s55, v3
	v_mov_b32_e32 v12, s43
	s_nop 0
	v_cndmask_b32_e32 v3, v3, v10, vcc
	v_subrev_u32_e32 v10, s55, v3
	v_cmp_le_u32_e32 vcc, s55, v3
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v10, vcc
	v_lshlrev_b32_e32 v3, 1, v3
	v_cvt_f32_u32_e32 v3, v3
	v_div_scale_f32 v10, s[2:3], v24, v24, v3
	v_rcp_f32_e32 v11, v10
	v_div_scale_f32 v13, vcc, v3, v24, v3
	v_fma_f32 v14, -v10, v11, 1.0
	v_fmac_f32_e32 v11, v14, v11
	v_mul_f32_e32 v14, v13, v11
	v_fma_f32 v15, -v10, v14, v13
	v_fmac_f32_e32 v14, v15, v11
	v_fma_f32 v10, -v10, v14, v13
	v_div_fmas_f32 v10, v10, v11, v14
	v_div_fixup_f32 v3, v10, v24, v3
	v_cndmask_b32_e64 v3, v3, 1.0, s[34:35]
	v_cmp_neq_f32_e32 vcc, 0, v3
	s_nop 1
	v_cndmask_b32_e32 v40, 1.0, v12, vcc
	v_frexp_mant_f32_e64 v10, |v40|
	v_cmp_gt_f32_e32 vcc, s56, v10
	v_frexp_exp_i32_f32_e32 v20, v40
	v_cmp_ngt_f32_e64 s[4:5], 0, v40
	v_cndmask_b32_e64 v11, 1.0, 2.0, vcc
	v_mul_f32_e32 v10, v10, v11
	v_add_f32_e32 v13, 1.0, v10
	v_rcp_f32_e32 v18, v13
	v_add_f32_e32 v11, -1.0, v13
	v_sub_f32_e32 v15, v10, v11
	v_add_f32_e32 v11, -1.0, v10
	v_mul_f32_e32 v19, v11, v18
	v_mul_f32_e32 v12, v13, v19
	v_fma_f32 v14, v19, v13, -v12
	v_fmac_f32_e32 v14, v19, v15
	v_add_f32_e32 v10, v12, v14
	v_sub_f32_e32 v13, v11, v10
	v_pk_add_f32 v[16:17], v[10:11], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v15, v10
	v_pk_add_f32 v[10:11], v[16:17], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_lt_f32_e64 s[6:7], |v40|, 1.0
	v_add_f32_e32 v10, v10, v11
	v_add_f32_e32 v10, v13, v10
	v_mul_f32_e32 v11, v18, v10
	v_add_f32_e32 v10, v19, v11
	v_sub_f32_e32 v12, v10, v19
	v_sub_f32_e32 v21, v11, v12
	v_mul_f32_e32 v11, v10, v10
	v_fma_f32 v13, v10, v10, -v11
	v_add_f32_e32 v22, v21, v21
	v_fmac_f32_e32 v13, v10, v22
	v_add_f32_e32 v12, v11, v13
	v_fmamk_f32 v14, v12, 0x3e76c4e1, v26
	v_fmaak_f32 v14, v12, v14, 0x3ecccdef
	v_sub_f32_e32 v11, v12, v11
	v_sub_f32_e32 v23, v13, v11
	v_mul_f32_e32 v11, v12, v14
	v_fma_f32 v13, v12, v14, -v11
	v_fmac_f32_e32 v13, v23, v14
	v_add_f32_e32 v14, v11, v13
	v_add_f32_e32 v15, 0x3f2aaaaa, v14
	v_sub_f32_e32 v11, v14, v11
	v_sub_f32_e32 v11, v13, v11
	v_add_f32_e32 v13, 0xbf2aaaaa, v15
	v_add_f32_e32 v11, 0x31739010, v11
	v_sub_f32_e32 v13, v14, v13
	v_pk_mul_f32 v[16:17], v[10:11], v[12:13]
	v_pk_add_f32 v[18:19], v[10:11], v[12:13]
	v_fma_f32 v14, v12, v10, -v16
	v_fmac_f32_e32 v14, v12, v21
	v_mov_b32_e32 v17, v19
	v_fmac_f32_e32 v14, v23, v10
	v_pk_add_f32 v[12:13], v[16:17], v[14:15]
	s_nop 0
	v_sub_f32_e32 v11, v12, v16
	v_sub_f32_e32 v11, v14, v11
	v_sub_f32_e32 v14, v15, v13
	v_mul_f32_e32 v15, v12, v13
	v_add_f32_e32 v14, v19, v14
	v_fma_f32 v16, v12, v13, -v15
	v_fmac_f32_e32 v16, v12, v14
	v_fmac_f32_e32 v16, v11, v13
	v_subbrev_co_u32_e32 v11, vcc, 0, v20, vcc
	v_cvt_f32_i32_e32 v12, v11
	v_add_f32_e32 v11, v15, v16
	v_sub_f32_e32 v13, v11, v15
	v_sub_f32_e32 v13, v16, v13
	v_add_f32_e32 v16, v22, v13
	v_mov_b32_e32 v13, v10
	v_pk_mul_f32 v[14:15], v[12:13], s[44:45]
	s_nop 0
	v_fma_f32 v10, v12, s44, -v14
	v_fmac_f32_e32 v10, 0xb102e308, v12
	v_pk_add_f32 v[12:13], v[14:15], v[10:11]
	s_nop 0
	v_sub_f32_e32 v15, v13, v15
	v_sub_f32_e32 v11, v11, v15
	v_add_f32_e32 v15, v16, v11
	v_pk_add_f32 v[16:17], v[12:13], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[18:19], v[12:13], v[14:15]
	v_mov_b32_e32 v11, v12
	v_mov_b32_e32 v18, v16
	v_pk_add_f32 v[22:23], v[10:11], v[18:19]
	v_mov_b32_e32 v36, v19
	v_pk_add_f32 v[34:35], v[22:23], v[12:13] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v37, v23
	v_pk_mov_b32 v[38:39], v[12:13], v[34:35] op_sel:[1,0]
	v_pk_add_f32 v[20:21], v[10:11], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[36:37], v[36:37], v[38:39] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v14, v15
	v_mov_b32_e32 v15, v12
	v_mov_b32_e32 v11, v19
	v_mov_b32_e32 v17, v34
	v_pk_add_f32 v[12:13], v[14:15], v[36:37] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[10:11], v[10:11], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v21, v23
	v_pk_add_f32 v[10:11], v[10:11], v[12:13]
	s_nop 0
	v_pk_add_f32 v[14:15], v[10:11], v[10:11] op_sel:[0,1] op_sel_hi:[1,0]
	s_nop 0
	v_pk_add_f32 v[16:17], v[22:23], v[14:15] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v11, v16
	v_pk_add_f32 v[18:19], v[10:11], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v13, v14
	v_sub_f32_e32 v10, v10, v18
	v_pk_add_f32 v[12:13], v[12:13], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v10, v20, v10
	v_add_f32_e32 v10, v12, v10
	v_add_f32_e32 v10, v10, v13
	v_add_f32_e32 v11, v16, v10
	v_sub_f32_e32 v12, v11, v16
	v_sub_f32_e32 v10, v10, v12
	v_mul_f32_e32 v12, v3, v11
	v_fma_f32 v11, v3, v11, -v12
	v_fmac_f32_e32 v11, v3, v10
	v_add_f32_e32 v10, v12, v11
	v_cmp_class_f32_e64 vcc, v12, s59
	v_sub_f32_e32 v13, v10, v12
	v_sub_f32_e32 v11, v11, v13
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_cmp_eq_f32_e32 vcc, s61, v10
	s_nop 1
	v_cndmask_b32_e32 v12, 0, v29, vcc
	v_sub_f32_e32 v13, v10, v12
	v_mul_f32_e32 v14, 0x3fb8aa3b, v13
	v_fma_f32 v15, v13, s62, -v14
	v_rndne_f32_e32 v16, v14
	v_fmac_f32_e32 v15, 0x32a5705f, v13
	v_sub_f32_e32 v14, v14, v16
	v_add_f32_e32 v14, v14, v15
	v_exp_f32_e32 v14, v14
	v_cvt_i32_f32_e32 v15, v16
	v_cmp_neq_f32_e64 vcc, |v10|, s60
	s_nop 1
	v_cndmask_b32_e32 v10, 0, v11, vcc
	v_ldexp_f32 v11, v14, v15
	v_cmp_ngt_f32_e32 vcc, s63, v13
	v_add_f32_e32 v10, v12, v10
	s_nop 0
	v_cndmask_b32_e32 v11, 0, v11, vcc
	v_cmp_nlt_f32_e32 vcc, s61, v13
	s_nop 1
	v_cndmask_b32_e32 v11, v30, v11, vcc
	v_fma_f32 v10, v11, v10, v11
	v_cmp_class_f32_e64 vcc, v11, s59
	s_nop 1
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_trunc_f32_e32 v11, v3
	v_cmp_eq_f32_e32 vcc, v11, v3
	v_mul_f32_e32 v11, 0.5, v3
	v_trunc_f32_e32 v12, v11
	v_cmp_neq_f32_e64 s[2:3], v12, v11
	s_and_b64 s[2:3], vcc, s[2:3]
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e64 v11, 1.0, v40, s[2:3]
	v_cmp_neq_f32_e64 s[4:5], v3, |v3|
	v_bfi_b32 v10, s64, v10, v11
	s_xor_b64 s[4:5], s[4:5], s[6:7]
	v_cndmask_b32_e32 v10, v31, v10, vcc
	v_cndmask_b32_e64 v11, v30, 0, s[4:5]
	v_cmp_neq_f32_e64 vcc, |v40|, 1.0
	v_cmp_class_f32_e64 s[4:5], v40, s59
	v_cndmask_b32_e64 v12, 0, v40, s[2:3]
	v_cndmask_b32_e32 v11, 1.0, v11, vcc
	v_cmp_class_f32_e64 vcc, v3, s59
	s_nop 1
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_cmp_eq_f32_e32 vcc, 0, v40
	s_nop 1
	v_cndmask_b32_e64 v11, v30, 0, vcc
	v_bfi_b32 v11, s64, v11, v12
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_cmp_o_f32_e32 vcc, v40, v3
	s_nop 1
	v_cndmask_b32_e32 v3, v31, v10, vcc
	v_mov_b32_e32 v10, s41
	v_fma_f32 v10, s40, v3, v10
	v_min_f32_e32 v10, 1.0, v10
	v_max_f32_e32 v10, 0, v10
	v_sub_f32_e32 v11, 1.0, v10
	v_mul_f32_e32 v12, s42, v3
	v_mul_f32_e32 v11, v12, v11
	v_fmac_f32_e32 v11, v3, v10
	v_mul_f32_e32 v3, v11, v5
	v_cmp_ge_f32_e64 s[2:3], |v3|, s65
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_xor_b64 s[52:53], exec, s[4:5]
	s_cbranch_execz .LBB0_12
.Lft5:
	v_frexp_exp_i32_f32_e32 v11, v3
	v_add_u32_e32 v11, 6, v11
	v_cmp_lt_u32_e32 vcc, 63, v11
	v_frexp_mant_f32_e64 v10, |v3|
	v_mul_f32_e32 v10, 0x4b800000, v10
	v_cndmask_b32_e32 v12, 0, v32, vcc
	v_add_u32_e32 v11, v12, v11
	v_cmp_lt_u32_e64 s[2:3], 31, v11
	v_cvt_u32_f32_e32 v34, v10
	v_mov_b32_e32 v13, v7
	v_cndmask_b32_e64 v12, 0, v33, s[2:3]
	v_add_u32_e32 v11, v12, v11
	v_cmp_lt_u32_e64 s[4:5], 31, v11
	v_mov_b32_e32 v15, v7
	v_mov_b32_e32 v17, v7
	v_cndmask_b32_e64 v10, 0, v33, s[4:5]
	v_add_u32_e32 v35, v10, v11
	v_mad_u64_u32 v[10:11], s[6:7], v34, s66, 0
	v_mov_b32_e32 v12, v11
	v_mad_u64_u32 v[12:13], s[6:7], v34, s67, v[12:13]
	v_mov_b32_e32 v14, v13
	v_mad_u64_u32 v[14:15], s[6:7], v34, s68, v[14:15]
	v_mov_b32_e32 v16, v15
	v_mad_u64_u32 v[16:17], s[6:7], v34, s69, v[16:17]
	v_mov_b32_e32 v18, v17
	v_mov_b32_e32 v19, v7
	v_mad_u64_u32 v[18:19], s[6:7], v34, s70, v[18:19]
	v_mov_b32_e32 v20, v19
	v_mov_b32_e32 v21, v7
	v_mad_u64_u32 v[20:21], s[6:7], v34, s71, v[20:21]
	v_mov_b32_e32 v22, v21
	v_mov_b32_e32 v23, v7
	v_mad_u64_u32 v[22:23], s[6:7], v34, s72, v[22:23]
	v_cndmask_b32_e32 v11, v20, v16, vcc
	v_cndmask_b32_e32 v13, v22, v18, vcc
	v_cndmask_b32_e32 v17, v23, v20, vcc
	v_cndmask_b32_e64 v15, v13, v11, s[2:3]
	v_cndmask_b32_e64 v13, v17, v13, s[2:3]
	v_cndmask_b32_e32 v17, v18, v14, vcc
	v_cndmask_b32_e64 v11, v11, v17, s[2:3]
	v_cndmask_b32_e32 v12, v16, v12, vcc
	v_cndmask_b32_e64 v13, v13, v15, s[4:5]
	v_cndmask_b32_e64 v15, v15, v11, s[4:5]
	v_sub_u32_e32 v18, 32, v35
	v_cndmask_b32_e64 v16, v17, v12, s[2:3]
	v_alignbit_b32 v19, v13, v15, v18
	v_cmp_eq_u32_e64 s[6:7], 0, v35
	v_cndmask_b32_e64 v11, v11, v16, s[4:5]
	v_alignbit_b32 v17, v15, v11, v18
	v_cndmask_b32_e64 v13, v19, v13, s[6:7]
	v_cndmask_b32_e32 v10, v14, v10, vcc
	v_cndmask_b32_e64 v15, v17, v15, s[6:7]
	v_bfe_u32 v20, v13, 29, 1
	v_cndmask_b32_e64 v10, v12, v10, s[2:3]
	v_alignbit_b32 v17, v13, v15, 30
	v_sub_u32_e32 v21, 0, v20
	v_cndmask_b32_e64 v10, v16, v10, s[4:5]
	v_xor_b32_e32 v17, v17, v21
	v_alignbit_b32 v12, v11, v10, v18
	v_cndmask_b32_e64 v11, v12, v11, s[6:7]
	v_ffbh_u32_e32 v14, v17
	v_alignbit_b32 v12, v15, v11, 30
	v_min_u32_e32 v14, 32, v14
	v_alignbit_b32 v10, v11, v10, 30
	v_xor_b32_e32 v12, v12, v21
	v_sub_u32_e32 v15, 31, v14
	v_xor_b32_e32 v10, v10, v21
	v_alignbit_b32 v16, v17, v12, v15
	v_alignbit_b32 v10, v12, v10, v15
	v_alignbit_b32 v11, v16, v10, 9
	v_ffbh_u32_e32 v12, v11
	v_min_u32_e32 v12, 32, v12
	v_lshrrev_b32_e32 v19, 29, v13
	v_not_b32_e32 v15, v12
	v_alignbit_b32 v10, v11, v10, v15
	v_lshlrev_b32_e32 v11, 31, v19
	v_or_b32_e32 v15, 0x33000000, v11
	v_add_lshl_u32 v12, v12, v14, 23
	v_lshrrev_b32_e32 v10, 9, v10
	v_sub_u32_e32 v12, v15, v12
	v_or_b32_e32 v11, 0.5, v11
	v_lshlrev_b32_e32 v14, 23, v14
	v_or_b32_e32 v10, v12, v10
	v_lshrrev_b32_e32 v12, 9, v16
	v_sub_u32_e32 v11, v11, v14
	v_or_b32_e32 v11, v12, v11
	v_mul_f32_e32 v12, 0x3fc90fda, v11
	v_fma_f32 v14, v11, s73, -v12
	v_fmac_f32_e32 v14, 0x33a22168, v11
	v_fmac_f32_e32 v14, 0x3fc90fda, v10
	v_lshrrev_b32_e32 v10, 30, v13
	v_add_f32_e32 v11, v12, v14
	v_add_u32_e32 v13, v20, v10
.LBB0_12:
	s_andn2_saveexec_b64 s[2:3], s[52:53]
	v_mul_f32_e64 v10, |v3|, s74
	v_rndne_f32_e32 v10, v10
	v_cvt_i32_f32_e32 v13, v10
	v_fma_f32 v11, v10, s75, |v3|
	v_fmac_f32_e32 v11, 0xb3a22168, v10
	v_fmac_f32_e32 v11, 0xa7c234c4, v10
	s_or_b64 exec, exec, s[2:3]
	v_or_b32_e32 v10, 2, v6
	v_mul_hi_u32 v12, v10, v25
	v_mul_lo_u32 v12, v12, s55
	v_sub_u32_e32 v10, v10, v12
	v_subrev_u32_e32 v12, s55, v10
	v_cmp_le_u32_e32 vcc, s55, v10
	v_mov_b32_e32 v15, s43
	s_nop 0
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_subrev_u32_e32 v12, s55, v10
	v_cmp_le_u32_e32 vcc, s55, v10
	s_nop 1
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_lshlrev_b32_e32 v10, 1, v10
	v_cvt_f32_u32_e32 v10, v10
	v_div_scale_f32 v12, s[2:3], v24, v24, v10
	v_rcp_f32_e32 v14, v12
	v_div_scale_f32 v16, vcc, v10, v24, v10
	v_fma_f32 v17, -v12, v14, 1.0
	v_fmac_f32_e32 v14, v17, v14
	v_mul_f32_e32 v17, v16, v14
	v_fma_f32 v18, -v12, v17, v16
	v_fmac_f32_e32 v17, v18, v14
	v_fma_f32 v12, -v12, v17, v16
	v_div_fmas_f32 v12, v12, v14, v17
	v_div_fixup_f32 v10, v12, v24, v10
	v_cndmask_b32_e64 v10, v10, 1.0, s[34:35]
	v_cmp_neq_f32_e32 vcc, 0, v10
	s_nop 1
	v_cndmask_b32_e32 v12, 1.0, v15, vcc
	v_frexp_mant_f32_e64 v14, |v12|
	v_cmp_gt_f32_e32 vcc, s56, v14
	v_frexp_exp_i32_f32_e32 v34, v12
	v_cmp_ngt_f32_e64 s[4:5], 0, v12
	v_cndmask_b32_e64 v15, 1.0, 2.0, vcc
	v_mul_f32_e32 v14, v14, v15
	v_add_f32_e32 v17, 1.0, v14
	v_rcp_f32_e32 v22, v17
	v_add_f32_e32 v15, -1.0, v17
	v_sub_f32_e32 v19, v14, v15
	v_add_f32_e32 v15, -1.0, v14
	v_mul_f32_e32 v23, v15, v22
	v_mul_f32_e32 v16, v17, v23
	v_fma_f32 v18, v23, v17, -v16
	v_fmac_f32_e32 v18, v23, v19
	v_add_f32_e32 v14, v16, v18
	v_sub_f32_e32 v17, v15, v14
	v_pk_add_f32 v[20:21], v[14:15], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v19, v14
	v_pk_add_f32 v[14:15], v[20:21], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_lt_f32_e64 s[6:7], |v12|, 1.0
	v_add_f32_e32 v14, v14, v15
	v_add_f32_e32 v14, v17, v14
	v_mul_f32_e32 v15, v22, v14
	v_add_f32_e32 v14, v23, v15
	v_sub_f32_e32 v16, v14, v23
	v_sub_f32_e32 v35, v15, v16
	v_mul_f32_e32 v15, v14, v14
	v_fma_f32 v17, v14, v14, -v15
	v_add_f32_e32 v36, v35, v35
	v_fmac_f32_e32 v17, v14, v36
	v_add_f32_e32 v16, v15, v17
	v_fmamk_f32 v18, v16, 0x3e76c4e1, v26
	v_fmaak_f32 v18, v16, v18, 0x3ecccdef
	v_sub_f32_e32 v15, v16, v15
	v_sub_f32_e32 v37, v17, v15
	v_mul_f32_e32 v15, v16, v18
	v_fma_f32 v17, v16, v18, -v15
	v_fmac_f32_e32 v17, v37, v18
	v_add_f32_e32 v18, v15, v17
	v_add_f32_e32 v19, 0x3f2aaaaa, v18
	v_sub_f32_e32 v15, v18, v15
	v_sub_f32_e32 v15, v17, v15
	v_add_f32_e32 v17, 0xbf2aaaaa, v19
	v_add_f32_e32 v15, 0x31739010, v15
	v_sub_f32_e32 v17, v18, v17
	v_pk_mul_f32 v[20:21], v[14:15], v[16:17]
	v_pk_add_f32 v[22:23], v[14:15], v[16:17]
	v_fma_f32 v18, v16, v14, -v20
	v_fmac_f32_e32 v18, v16, v35
	v_mov_b32_e32 v21, v23
	v_fmac_f32_e32 v18, v37, v14
	v_pk_add_f32 v[16:17], v[20:21], v[18:19]
	s_nop 0
	v_sub_f32_e32 v15, v16, v20
	v_sub_f32_e32 v15, v18, v15
	v_sub_f32_e32 v18, v19, v17
	v_mul_f32_e32 v19, v16, v17
	v_add_f32_e32 v18, v23, v18
	v_fma_f32 v20, v16, v17, -v19
	v_fmac_f32_e32 v20, v16, v18
	v_fmac_f32_e32 v20, v15, v17
	v_subbrev_co_u32_e32 v15, vcc, 0, v34, vcc
	v_cvt_f32_i32_e32 v16, v15
	v_add_f32_e32 v15, v19, v20
	v_sub_f32_e32 v17, v15, v19
	v_sub_f32_e32 v17, v20, v17
	v_add_f32_e32 v20, v36, v17
	v_mov_b32_e32 v17, v14
	v_pk_mul_f32 v[18:19], v[16:17], s[44:45]
	s_nop 0
	v_fma_f32 v14, v16, s44, -v18
	v_fmac_f32_e32 v14, 0xb102e308, v16
	v_pk_add_f32 v[16:17], v[18:19], v[14:15]
	s_nop 0
	v_sub_f32_e32 v19, v17, v19
	v_sub_f32_e32 v15, v15, v19
	v_add_f32_e32 v19, v20, v15
	v_pk_add_f32 v[20:21], v[16:17], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[22:23], v[16:17], v[18:19]
	v_mov_b32_e32 v15, v16
	v_mov_b32_e32 v22, v20
	v_pk_add_f32 v[36:37], v[14:15], v[22:23]
	v_mov_b32_e32 v40, v23
	v_pk_add_f32 v[38:39], v[36:37], v[16:17] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v41, v37
	v_pk_mov_b32 v[42:43], v[16:17], v[38:39] op_sel:[1,0]
	v_pk_add_f32 v[34:35], v[14:15], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[40:41], v[40:41], v[42:43] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v18, v19
	v_mov_b32_e32 v19, v16
	v_mov_b32_e32 v15, v23
	v_mov_b32_e32 v21, v38
	v_pk_add_f32 v[16:17], v[18:19], v[40:41] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[14:15], v[14:15], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v35, v37
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	s_nop 0
	v_pk_add_f32 v[18:19], v[14:15], v[14:15] op_sel:[0,1] op_sel_hi:[1,0]
	s_nop 0
	v_pk_add_f32 v[20:21], v[36:37], v[18:19] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v15, v20
	v_pk_add_f32 v[22:23], v[14:15], v[34:35] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v17, v18
	v_sub_f32_e32 v14, v14, v22
	v_pk_add_f32 v[16:17], v[16:17], v[22:23] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v14, v34, v14
	v_add_f32_e32 v14, v16, v14
	v_add_f32_e32 v14, v14, v17
	v_add_f32_e32 v15, v20, v14
	v_sub_f32_e32 v16, v15, v20
	v_sub_f32_e32 v14, v14, v16
	v_mul_f32_e32 v16, v10, v15
	v_fma_f32 v15, v10, v15, -v16
	v_fmac_f32_e32 v15, v10, v14
	v_add_f32_e32 v14, v16, v15
	v_cmp_class_f32_e64 vcc, v16, s59
	v_sub_f32_e32 v17, v14, v16
	v_sub_f32_e32 v15, v15, v17
	v_cndmask_b32_e32 v14, v14, v16, vcc
	v_cmp_eq_f32_e32 vcc, s61, v14
	s_nop 1
	v_cndmask_b32_e32 v16, 0, v29, vcc
	v_sub_f32_e32 v17, v14, v16
	v_mul_f32_e32 v18, 0x3fb8aa3b, v17
	v_fma_f32 v19, v17, s62, -v18
	v_rndne_f32_e32 v20, v18
	v_fmac_f32_e32 v19, 0x32a5705f, v17
	v_sub_f32_e32 v18, v18, v20
	v_add_f32_e32 v18, v18, v19
	v_exp_f32_e32 v18, v18
	v_cvt_i32_f32_e32 v19, v20
	v_cmp_neq_f32_e64 vcc, |v14|, s60
	s_nop 1
	v_cndmask_b32_e32 v14, 0, v15, vcc
	v_ldexp_f32 v15, v18, v19
	v_cmp_ngt_f32_e32 vcc, s63, v17
	v_add_f32_e32 v14, v16, v14
	s_nop 0
	v_cndmask_b32_e32 v15, 0, v15, vcc
	v_cmp_nlt_f32_e32 vcc, s61, v17
	s_nop 1
	v_cndmask_b32_e32 v15, v30, v15, vcc
	v_fma_f32 v14, v15, v14, v15
	v_cmp_class_f32_e64 vcc, v15, s59
	s_nop 1
	v_cndmask_b32_e32 v14, v14, v15, vcc
	v_trunc_f32_e32 v15, v10
	v_cmp_eq_f32_e32 vcc, v15, v10
	v_mul_f32_e32 v15, 0.5, v10
	v_trunc_f32_e32 v16, v15
	v_cmp_neq_f32_e64 s[2:3], v16, v15
	s_and_b64 s[2:3], vcc, s[2:3]
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e64 v15, 1.0, v12, s[2:3]
	v_cmp_neq_f32_e64 s[4:5], v10, |v10|
	v_bfi_b32 v14, s64, v14, v15
	s_xor_b64 s[4:5], s[4:5], s[6:7]
	v_cndmask_b32_e32 v14, v31, v14, vcc
	v_cndmask_b32_e64 v15, v30, 0, s[4:5]
	v_cmp_neq_f32_e64 vcc, |v12|, 1.0
	v_cmp_class_f32_e64 s[4:5], v12, s59
	v_cndmask_b32_e64 v16, 0, v12, s[2:3]
	v_cndmask_b32_e32 v15, 1.0, v15, vcc
	v_cmp_class_f32_e64 vcc, v10, s59
	s_nop 1
	v_cndmask_b32_e32 v14, v14, v15, vcc
	v_cmp_eq_f32_e32 vcc, 0, v12
	s_nop 1
	v_cndmask_b32_e64 v15, v30, 0, vcc
	v_bfi_b32 v15, s64, v15, v16
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e32 v14, v14, v15, vcc
	v_cmp_o_f32_e32 vcc, v12, v10
	v_mov_b32_e32 v12, s41
	s_nop 0
	v_cndmask_b32_e32 v10, v31, v14, vcc
	v_fma_f32 v12, s40, v10, v12
	v_min_f32_e32 v12, 1.0, v12
	v_max_f32_e32 v12, 0, v12
	v_sub_f32_e32 v14, 1.0, v12
	v_mul_f32_e32 v15, s42, v10
	v_mul_f32_e32 v14, v15, v14
	v_fmac_f32_e32 v14, v10, v12
	v_mul_f32_e32 v10, v14, v5
	v_cmp_ge_f32_e64 s[2:3], |v10|, s65
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_xor_b64 s[52:53], exec, s[4:5]
	s_cbranch_execz .LBB0_16
.Lft6:
	v_frexp_exp_i32_f32_e32 v14, v10
	v_add_u32_e32 v14, 6, v14
	v_cmp_lt_u32_e32 vcc, 63, v14
	v_frexp_mant_f32_e64 v12, |v10|
	v_mul_f32_e32 v12, 0x4b800000, v12
	v_cndmask_b32_e32 v15, 0, v32, vcc
	v_add_u32_e32 v14, v15, v14
	v_cmp_lt_u32_e64 s[2:3], 31, v14
	v_cvt_u32_f32_e32 v12, v12
	v_mov_b32_e32 v17, v7
	v_cndmask_b32_e64 v15, 0, v33, s[2:3]
	v_add_u32_e32 v14, v15, v14
	v_cmp_lt_u32_e64 s[4:5], 31, v14
	v_mov_b32_e32 v19, v7
	v_mov_b32_e32 v21, v7
	v_cndmask_b32_e64 v15, 0, v33, s[4:5]
	v_add_u32_e32 v38, v15, v14
	v_mad_u64_u32 v[14:15], s[6:7], v12, s66, 0
	v_mov_b32_e32 v16, v15
	v_mad_u64_u32 v[16:17], s[6:7], v12, s67, v[16:17]
	v_mov_b32_e32 v18, v17
	v_mad_u64_u32 v[18:19], s[6:7], v12, s68, v[18:19]
	v_mov_b32_e32 v20, v19
	v_mad_u64_u32 v[20:21], s[6:7], v12, s69, v[20:21]
	v_mov_b32_e32 v22, v21
	v_mov_b32_e32 v23, v7
	v_mad_u64_u32 v[22:23], s[6:7], v12, s70, v[22:23]
	v_mov_b32_e32 v34, v23
	v_mov_b32_e32 v35, v7
	v_mad_u64_u32 v[34:35], s[6:7], v12, s71, v[34:35]
	v_mov_b32_e32 v36, v35
	v_mov_b32_e32 v37, v7
	v_mad_u64_u32 v[36:37], s[6:7], v12, s72, v[36:37]
	v_cndmask_b32_e32 v15, v34, v20, vcc
	v_cndmask_b32_e32 v12, v36, v22, vcc
	v_cndmask_b32_e32 v19, v37, v34, vcc
	v_cndmask_b32_e64 v17, v12, v15, s[2:3]
	v_cndmask_b32_e64 v12, v19, v12, s[2:3]
	v_cndmask_b32_e32 v19, v22, v18, vcc
	v_cndmask_b32_e64 v15, v15, v19, s[2:3]
	v_cndmask_b32_e64 v12, v12, v17, s[4:5]
	v_cndmask_b32_e64 v17, v17, v15, s[4:5]
	v_sub_u32_e32 v21, 32, v38
	v_alignbit_b32 v22, v12, v17, v21
	v_cmp_eq_u32_e64 s[6:7], 0, v38
	v_cndmask_b32_e32 v14, v18, v14, vcc
	s_nop 0
	v_cndmask_b32_e64 v22, v22, v12, s[6:7]
	v_cndmask_b32_e32 v12, v20, v16, vcc
	v_cndmask_b32_e64 v16, v19, v12, s[2:3]
	v_cndmask_b32_e64 v15, v15, v16, s[4:5]
	v_alignbit_b32 v19, v17, v15, v21
	v_cndmask_b32_e64 v17, v19, v17, s[6:7]
	v_bfe_u32 v23, v22, 29, 1
	v_cndmask_b32_e64 v12, v12, v14, s[2:3]
	v_alignbit_b32 v19, v22, v17, 30
	v_sub_u32_e32 v34, 0, v23
	v_cndmask_b32_e64 v12, v16, v12, s[4:5]
	v_xor_b32_e32 v19, v19, v34
	v_alignbit_b32 v14, v15, v12, v21
	v_cndmask_b32_e64 v14, v14, v15, s[6:7]
	v_ffbh_u32_e32 v16, v19
	v_alignbit_b32 v15, v17, v14, 30
	v_min_u32_e32 v16, 32, v16
	v_alignbit_b32 v12, v14, v12, 30
	v_xor_b32_e32 v15, v15, v34
	v_sub_u32_e32 v17, 31, v16
	v_xor_b32_e32 v12, v12, v34
	v_alignbit_b32 v18, v19, v15, v17
	v_alignbit_b32 v12, v15, v12, v17
	v_alignbit_b32 v14, v18, v12, 9
	v_ffbh_u32_e32 v15, v14
	v_min_u32_e32 v15, 32, v15
	v_lshrrev_b32_e32 v20, 29, v22
	v_not_b32_e32 v17, v15
	v_alignbit_b32 v12, v14, v12, v17
	v_lshlrev_b32_e32 v14, 31, v20
	v_or_b32_e32 v17, 0x33000000, v14
	v_add_lshl_u32 v15, v15, v16, 23
	v_lshrrev_b32_e32 v12, 9, v12
	v_sub_u32_e32 v15, v17, v15
	v_or_b32_e32 v14, 0.5, v14
	v_lshlrev_b32_e32 v16, 23, v16
	v_or_b32_e32 v12, v15, v12
	v_lshrrev_b32_e32 v15, 9, v18
	v_sub_u32_e32 v14, v14, v16
	v_or_b32_e32 v14, v15, v14
	v_mul_f32_e32 v15, 0x3fc90fda, v14
	v_fma_f32 v16, v14, s73, -v15
	v_fmac_f32_e32 v16, 0x33a22168, v14
	v_fmac_f32_e32 v16, 0x3fc90fda, v12
	v_lshrrev_b32_e32 v14, 30, v22
	v_add_f32_e32 v12, v15, v16
	v_add_u32_e32 v14, v23, v14
.LBB0_16:
	s_andn2_saveexec_b64 s[2:3], s[52:53]
	v_mul_f32_e64 v12, |v10|, s74
	v_rndne_f32_e32 v15, v12
	v_cvt_i32_f32_e32 v14, v15
	v_fma_f32 v12, v15, s75, |v10|
	v_fmac_f32_e32 v12, 0xb3a22168, v15
	v_fmac_f32_e32 v12, 0xa7c234c4, v15
	s_or_b64 exec, exec, s[2:3]
	v_or_b32_e32 v15, 3, v6
	v_mul_hi_u32 v16, v15, v25
	v_mul_lo_u32 v16, v16, s55
	v_sub_u32_e32 v15, v15, v16
	v_subrev_u32_e32 v16, s55, v15
	v_cmp_le_u32_e32 vcc, s55, v15
	v_mov_b32_e32 v18, s43
	s_nop 0
	v_cndmask_b32_e32 v15, v15, v16, vcc
	v_subrev_u32_e32 v16, s55, v15
	v_cmp_le_u32_e32 vcc, s55, v15
	s_nop 1
	v_cndmask_b32_e32 v15, v15, v16, vcc
	v_lshlrev_b32_e32 v15, 1, v15
	v_cvt_f32_u32_e32 v15, v15
	v_div_scale_f32 v16, s[2:3], v24, v24, v15
	v_rcp_f32_e32 v17, v16
	v_div_scale_f32 v19, vcc, v15, v24, v15
	v_fma_f32 v20, -v16, v17, 1.0
	v_fmac_f32_e32 v17, v20, v17
	v_mul_f32_e32 v20, v19, v17
	v_fma_f32 v21, -v16, v20, v19
	v_fmac_f32_e32 v20, v21, v17
	v_fma_f32 v16, -v16, v20, v19
	v_div_fmas_f32 v16, v16, v17, v20
	v_div_fixup_f32 v15, v16, v24, v15
	v_cndmask_b32_e64 v15, v15, 1.0, s[34:35]
	v_cmp_neq_f32_e32 vcc, 0, v15
	s_nop 1
	v_cndmask_b32_e32 v46, 1.0, v18, vcc
	v_frexp_mant_f32_e64 v16, |v46|
	v_cmp_gt_f32_e32 vcc, s56, v16
	v_frexp_exp_i32_f32_e32 v36, v46
	v_cmp_ngt_f32_e64 s[4:5], 0, v46
	v_cndmask_b32_e64 v17, 1.0, 2.0, vcc
	v_mul_f32_e32 v16, v16, v17
	v_add_f32_e32 v19, 1.0, v16
	v_rcp_f32_e32 v34, v19
	v_add_f32_e32 v17, -1.0, v19
	v_sub_f32_e32 v21, v16, v17
	v_add_f32_e32 v17, -1.0, v16
	v_mul_f32_e32 v35, v17, v34
	v_mul_f32_e32 v18, v19, v35
	v_fma_f32 v20, v35, v19, -v18
	v_fmac_f32_e32 v20, v35, v21
	v_add_f32_e32 v16, v18, v20
	v_sub_f32_e32 v19, v17, v16
	v_pk_add_f32 v[22:23], v[16:17], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v21, v16
	v_pk_add_f32 v[16:17], v[22:23], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_cmp_lt_f32_e64 s[6:7], |v46|, 1.0
	v_add_f32_e32 v16, v16, v17
	v_add_f32_e32 v16, v19, v16
	v_mul_f32_e32 v17, v34, v16
	v_add_f32_e32 v16, v35, v17
	v_sub_f32_e32 v18, v16, v35
	v_sub_f32_e32 v37, v17, v18
	v_mul_f32_e32 v17, v16, v16
	v_fma_f32 v19, v16, v16, -v17
	v_add_f32_e32 v38, v37, v37
	v_fmac_f32_e32 v19, v16, v38
	v_add_f32_e32 v18, v17, v19
	v_fmamk_f32 v20, v18, 0x3e76c4e1, v26
	v_fmaak_f32 v20, v18, v20, 0x3ecccdef
	v_sub_f32_e32 v17, v18, v17
	v_sub_f32_e32 v39, v19, v17
	v_mul_f32_e32 v17, v18, v20
	v_fma_f32 v19, v18, v20, -v17
	v_fmac_f32_e32 v19, v39, v20
	v_add_f32_e32 v20, v17, v19
	v_add_f32_e32 v21, 0x3f2aaaaa, v20
	v_sub_f32_e32 v17, v20, v17
	v_sub_f32_e32 v17, v19, v17
	v_add_f32_e32 v19, 0xbf2aaaaa, v21
	v_add_f32_e32 v17, 0x31739010, v17
	v_sub_f32_e32 v19, v20, v19
	v_pk_mul_f32 v[22:23], v[16:17], v[18:19]
	v_pk_add_f32 v[34:35], v[16:17], v[18:19]
	v_fma_f32 v20, v18, v16, -v22
	v_fmac_f32_e32 v20, v18, v37
	v_mov_b32_e32 v23, v35
	v_fmac_f32_e32 v20, v39, v16
	v_pk_add_f32 v[18:19], v[22:23], v[20:21]
	s_nop 0
	v_sub_f32_e32 v17, v18, v22
	v_sub_f32_e32 v17, v20, v17
	v_sub_f32_e32 v20, v21, v19
	v_mul_f32_e32 v21, v18, v19
	v_add_f32_e32 v20, v35, v20
	v_fma_f32 v22, v18, v19, -v21
	v_fmac_f32_e32 v22, v18, v20
	v_fmac_f32_e32 v22, v17, v19
	v_subbrev_co_u32_e32 v17, vcc, 0, v36, vcc
	v_cvt_f32_i32_e32 v18, v17
	v_add_f32_e32 v17, v21, v22
	v_sub_f32_e32 v19, v17, v21
	v_sub_f32_e32 v19, v22, v19
	v_add_f32_e32 v22, v38, v19
	v_mov_b32_e32 v19, v16
	v_pk_mul_f32 v[20:21], v[18:19], s[44:45]
	s_nop 0
	v_fma_f32 v16, v18, s44, -v20
	v_fmac_f32_e32 v16, 0xb102e308, v18
	v_pk_add_f32 v[18:19], v[20:21], v[16:17]
	s_nop 0
	v_sub_f32_e32 v21, v19, v21
	v_sub_f32_e32 v17, v17, v21
	v_add_f32_e32 v21, v22, v17
	v_pk_add_f32 v[22:23], v[18:19], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[34:35], v[18:19], v[20:21]
	v_mov_b32_e32 v17, v18
	v_mov_b32_e32 v34, v22
	v_pk_add_f32 v[38:39], v[16:17], v[34:35]
	v_mov_b32_e32 v42, v35
	v_pk_add_f32 v[40:41], v[38:39], v[18:19] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v43, v39
	v_pk_mov_b32 v[44:45], v[18:19], v[40:41] op_sel:[1,0]
	v_pk_add_f32 v[36:37], v[16:17], v[22:23] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[42:43], v[42:43], v[44:45] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v20, v21
	v_mov_b32_e32 v21, v18
	v_mov_b32_e32 v17, v35
	v_mov_b32_e32 v23, v40
	v_pk_add_f32 v[18:19], v[20:21], v[42:43] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[16:17], v[16:17], v[22:23] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v37, v39
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	s_nop 0
	v_pk_add_f32 v[20:21], v[16:17], v[16:17] op_sel:[0,1] op_sel_hi:[1,0]
	s_nop 0
	v_pk_add_f32 v[22:23], v[38:39], v[20:21] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v17, v22
	v_pk_add_f32 v[34:35], v[16:17], v[36:37] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v19, v20
	v_sub_f32_e32 v16, v16, v34
	v_pk_add_f32 v[18:19], v[18:19], v[34:35] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v16, v36, v16
	v_add_f32_e32 v16, v18, v16
	v_add_f32_e32 v16, v16, v19
	v_add_f32_e32 v17, v22, v16
	v_sub_f32_e32 v18, v17, v22
	v_sub_f32_e32 v16, v16, v18
	v_mul_f32_e32 v18, v15, v17
	v_fma_f32 v17, v15, v17, -v18
	v_fmac_f32_e32 v17, v15, v16
	v_add_f32_e32 v16, v18, v17
	v_cmp_class_f32_e64 vcc, v18, s59
	v_sub_f32_e32 v19, v16, v18
	v_sub_f32_e32 v17, v17, v19
	v_cndmask_b32_e32 v16, v16, v18, vcc
	v_cmp_eq_f32_e32 vcc, s61, v16
	s_nop 1
	v_cndmask_b32_e32 v18, 0, v29, vcc
	v_sub_f32_e32 v19, v16, v18
	v_mul_f32_e32 v20, 0x3fb8aa3b, v19
	v_fma_f32 v21, v19, s62, -v20
	v_rndne_f32_e32 v22, v20
	v_fmac_f32_e32 v21, 0x32a5705f, v19
	v_sub_f32_e32 v20, v20, v22
	v_add_f32_e32 v20, v20, v21
	v_exp_f32_e32 v20, v20
	v_cvt_i32_f32_e32 v21, v22
	v_cmp_neq_f32_e64 vcc, |v16|, s60
	s_nop 1
	v_cndmask_b32_e32 v16, 0, v17, vcc
	v_ldexp_f32 v17, v20, v21
	v_cmp_ngt_f32_e32 vcc, s63, v19
	v_add_f32_e32 v16, v18, v16
	s_nop 0
	v_cndmask_b32_e32 v17, 0, v17, vcc
	v_cmp_nlt_f32_e32 vcc, s61, v19
	s_nop 1
	v_cndmask_b32_e32 v17, v30, v17, vcc
	v_fma_f32 v16, v17, v16, v17
	v_cmp_class_f32_e64 vcc, v17, s59
	s_nop 1
	v_cndmask_b32_e32 v16, v16, v17, vcc
	v_trunc_f32_e32 v17, v15
	v_cmp_eq_f32_e32 vcc, v17, v15
	v_mul_f32_e32 v17, 0.5, v15
	v_trunc_f32_e32 v18, v17
	v_cmp_neq_f32_e64 s[2:3], v18, v17
	s_and_b64 s[2:3], vcc, s[2:3]
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e64 v17, 1.0, v46, s[2:3]
	v_cmp_neq_f32_e64 s[4:5], v15, |v15|
	v_bfi_b32 v16, s64, v16, v17
	s_xor_b64 s[4:5], s[4:5], s[6:7]
	v_cndmask_b32_e32 v16, v31, v16, vcc
	v_cndmask_b32_e64 v17, v30, 0, s[4:5]
	v_cmp_neq_f32_e64 vcc, |v46|, 1.0
	v_cmp_class_f32_e64 s[4:5], v46, s59
	v_cndmask_b32_e64 v18, 0, v46, s[2:3]
	v_cndmask_b32_e32 v17, 1.0, v17, vcc
	v_cmp_class_f32_e64 vcc, v15, s59
	s_nop 1
	v_cndmask_b32_e32 v16, v16, v17, vcc
	v_cmp_eq_f32_e32 vcc, 0, v46
	s_nop 1
	v_cndmask_b32_e64 v17, v30, 0, vcc
	v_bfi_b32 v17, s64, v17, v18
	s_or_b64 vcc, vcc, s[4:5]
	v_cndmask_b32_e32 v16, v16, v17, vcc
	v_cmp_o_f32_e32 vcc, v46, v15
	s_nop 1
	v_cndmask_b32_e32 v15, v31, v16, vcc
	v_mov_b32_e32 v16, s41
	v_fma_f32 v16, s40, v15, v16
	v_min_f32_e32 v16, 1.0, v16
	v_max_f32_e32 v16, 0, v16
	v_sub_f32_e32 v17, 1.0, v16
	v_mul_f32_e32 v18, s42, v15
	v_mul_f32_e32 v17, v18, v17
	v_fmac_f32_e32 v17, v15, v16
	v_mul_f32_e32 v18, v17, v5
	v_cmp_ge_f32_e64 s[2:3], |v18|, s65
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_xor_b64 s[52:53], exec, s[4:5]
	s_cbranch_execz .LBB0_20
.Lft7:
	v_frexp_exp_i32_f32_e32 v16, v18
	v_add_u32_e32 v16, 6, v16
	v_cmp_lt_u32_e32 vcc, 63, v16
	v_frexp_mant_f32_e64 v15, |v18|
	v_mul_f32_e32 v15, 0x4b800000, v15
	v_cndmask_b32_e32 v17, 0, v32, vcc
	v_add_u32_e32 v16, v17, v16
	v_cmp_lt_u32_e64 s[2:3], 31, v16
	v_cvt_u32_f32_e32 v15, v15
	v_mov_b32_e32 v21, v7
	v_cndmask_b32_e64 v17, 0, v33, s[2:3]
	v_add_u32_e32 v16, v17, v16
	v_cmp_lt_u32_e64 s[4:5], 31, v16
	v_mov_b32_e32 v23, v7
	v_mov_b32_e32 v35, v7
	v_cndmask_b32_e64 v17, 0, v33, s[4:5]
	v_add_u32_e32 v19, v17, v16
	v_mad_u64_u32 v[16:17], s[6:7], v15, s66, 0
	v_mov_b32_e32 v20, v17
	v_mad_u64_u32 v[20:21], s[6:7], v15, s67, v[20:21]
	v_mov_b32_e32 v22, v21
	v_mad_u64_u32 v[22:23], s[6:7], v15, s68, v[22:23]
	v_mov_b32_e32 v34, v23
	v_mad_u64_u32 v[34:35], s[6:7], v15, s69, v[34:35]
	v_mov_b32_e32 v36, v35
	v_mov_b32_e32 v37, v7
	v_mad_u64_u32 v[36:37], s[6:7], v15, s70, v[36:37]
	v_mov_b32_e32 v38, v37
	v_mov_b32_e32 v39, v7
	v_mad_u64_u32 v[38:39], s[6:7], v15, s71, v[38:39]
	v_mov_b32_e32 v40, v39
	v_mov_b32_e32 v41, v7
	v_mad_u64_u32 v[40:41], s[6:7], v15, s72, v[40:41]
	v_cndmask_b32_e32 v17, v38, v34, vcc
	v_cndmask_b32_e32 v15, v40, v36, vcc
	v_cndmask_b32_e32 v23, v41, v38, vcc
	v_cndmask_b32_e64 v21, v15, v17, s[2:3]
	v_cndmask_b32_e64 v15, v23, v15, s[2:3]
	v_cndmask_b32_e32 v23, v36, v22, vcc
	v_cndmask_b32_e64 v17, v17, v23, s[2:3]
	v_sub_u32_e32 v35, 32, v19
	v_cmp_eq_u32_e64 s[6:7], 0, v19
	v_cndmask_b32_e32 v19, v34, v20, vcc
	v_cndmask_b32_e64 v15, v15, v21, s[4:5]
	v_cndmask_b32_e64 v21, v21, v17, s[4:5]
	v_cndmask_b32_e64 v20, v23, v19, s[2:3]
	v_alignbit_b32 v36, v15, v21, v35
	v_cndmask_b32_e64 v17, v17, v20, s[4:5]
	v_cndmask_b32_e64 v15, v36, v15, s[6:7]
	v_alignbit_b32 v23, v21, v17, v35
	v_cndmask_b32_e32 v16, v22, v16, vcc
	v_cndmask_b32_e64 v21, v23, v21, s[6:7]
	v_bfe_u32 v36, v15, 29, 1
	v_cndmask_b32_e64 v16, v19, v16, s[2:3]
	v_alignbit_b32 v23, v15, v21, 30
	v_sub_u32_e32 v37, 0, v36
	v_cndmask_b32_e64 v16, v20, v16, s[4:5]
	v_xor_b32_e32 v23, v23, v37
	v_alignbit_b32 v19, v17, v16, v35
	v_cndmask_b32_e64 v17, v19, v17, s[6:7]
	v_ffbh_u32_e32 v20, v23
	v_alignbit_b32 v19, v21, v17, 30
	v_min_u32_e32 v20, 32, v20
	v_alignbit_b32 v16, v17, v16, 30
	v_xor_b32_e32 v19, v19, v37
	v_sub_u32_e32 v21, 31, v20
	v_xor_b32_e32 v16, v16, v37
	v_alignbit_b32 v22, v23, v19, v21
	v_alignbit_b32 v16, v19, v16, v21
	v_alignbit_b32 v17, v22, v16, 9
	v_ffbh_u32_e32 v19, v17
	v_min_u32_e32 v19, 32, v19
	v_lshrrev_b32_e32 v34, 29, v15
	v_not_b32_e32 v21, v19
	v_alignbit_b32 v16, v17, v16, v21
	v_lshlrev_b32_e32 v17, 31, v34
	v_or_b32_e32 v21, 0x33000000, v17
	v_add_lshl_u32 v19, v19, v20, 23
	v_lshrrev_b32_e32 v16, 9, v16
	v_sub_u32_e32 v19, v21, v19
	v_or_b32_e32 v17, 0.5, v17
	v_lshlrev_b32_e32 v20, 23, v20
	v_or_b32_e32 v16, v19, v16
	v_lshrrev_b32_e32 v19, 9, v22
	v_sub_u32_e32 v17, v17, v20
	v_or_b32_e32 v17, v19, v17
	v_mul_f32_e32 v19, 0x3fc90fda, v17
	v_fma_f32 v20, v17, s73, -v19
	v_fmac_f32_e32 v20, 0x33a22168, v17
	v_fmac_f32_e32 v20, 0x3fc90fda, v16
	v_lshrrev_b32_e32 v15, 30, v15
	v_add_f32_e32 v19, v19, v20
	v_add_u32_e32 v20, v36, v15
.LBB0_20:
	s_andn2_saveexec_b64 s[2:3], s[52:53]
	v_mul_f32_e64 v15, |v18|, s74
	v_rndne_f32_e32 v15, v15
	v_cvt_i32_f32_e32 v20, v15
	v_fma_f32 v19, v15, s75, |v18|
	v_fmac_f32_e32 v19, 0xb3a22168, v15
	v_fmac_f32_e32 v19, 0xa7c234c4, v15
	s_or_b64 exec, exec, s[2:3]
	v_mul_f32_e32 v22, v12, v12
	v_fmamk_f32 v23, v22, 0xb94c1982, v27
	v_fmaak_f32 v23, v22, v23, 0xbe2aaa9d
	v_mul_f32_e32 v23, v22, v23
	v_fmac_f32_e32 v12, v12, v23
	v_fmamk_f32 v23, v22, 0x37d75334, v28
	v_fmaak_f32 v23, v22, v23, 0x3d2aabf7
	v_fmaak_f32 v23, v22, v23, 0xbf000004
	v_fma_f32 v22, v22, v23, 1.0
	v_lshlrev_b32_e32 v23, 30, v14
	v_and_b32_e32 v14, 1, v14
	v_and_b32_e32 v17, 0x7fffffff, v10
	v_cmp_eq_u32_e32 vcc, 0, v14
	v_xor_b32_e32 v17, v17, v10
	v_and_b32_e32 v34, 0x80000000, v23
	v_cndmask_b32_e32 v14, v22, v12, vcc
	v_xor_b32_e32 v12, 0x80000000, v12
	v_xor_b32_e32 v14, v17, v14
	v_cndmask_b32_e32 v12, v12, v22, vcc
	v_xor_b32_e32 v14, v14, v34
	v_bitop3_b32 v12, v12, v23, s76 bitop3:0x78
	v_cmp_class_f32_e64 vcc, v10, s77
	v_and_b32_e32 v15, 0x7fffffff, v3
	v_xor_b32_e32 v15, v15, v3
	v_cndmask_b32_e32 v10, v31, v12, vcc
	v_cndmask_b32_e32 v12, v31, v14, vcc
	v_mul_f32_e32 v14, v11, v11
	v_fmamk_f32 v17, v14, 0xb94c1982, v27
	v_fmaak_f32 v17, v14, v17, 0xbe2aaa9d
	v_mul_f32_e32 v17, v14, v17
	v_fmac_f32_e32 v11, v11, v17
	v_fmamk_f32 v17, v14, 0x37d75334, v28
	v_fmaak_f32 v17, v14, v17, 0x3d2aabf7
	v_fmaak_f32 v17, v14, v17, 0xbf000004
	v_fma_f32 v14, v14, v17, 1.0
	v_lshlrev_b32_e32 v17, 30, v13
	v_and_b32_e32 v13, 1, v13
	v_cmp_eq_u32_e32 vcc, 0, v13
	v_and_b32_e32 v22, 0x80000000, v17
	v_and_b32_e32 v16, 0x7fffffff, v0
	v_cndmask_b32_e32 v13, v14, v11, vcc
	v_xor_b32_e32 v11, 0x80000000, v11
	v_cndmask_b32_e32 v11, v11, v14, vcc
	v_bitop3_b32 v11, v11, v17, s76 bitop3:0x78
	v_cmp_class_f32_e64 vcc, v3, s77
	v_mul_f32_e32 v3, v1, v1
	v_xor_b32_e32 v13, v15, v13
	v_cndmask_b32_e32 v15, v31, v11, vcc
	v_fmamk_f32 v11, v3, 0xb94c1982, v27
	v_fmaak_f32 v11, v3, v11, 0xbe2aaa9d
	v_mul_f32_e32 v11, v3, v11
	v_fmac_f32_e32 v1, v1, v11
	v_fmamk_f32 v11, v3, 0x37d75334, v28
	v_fmaak_f32 v11, v3, v11, 0x3d2aabf7
	v_fmaak_f32 v11, v3, v11, 0xbf000004
	v_xor_b32_e32 v13, v13, v22
	v_fma_f32 v3, v3, v11, 1.0
	v_lshlrev_b32_e32 v11, 30, v2
	v_and_b32_e32 v2, 1, v2
	v_cndmask_b32_e32 v17, v31, v13, vcc
	v_cmp_eq_u32_e32 vcc, 0, v2
	v_xor_b32_e32 v14, v16, v0
	v_and_b32_e32 v13, 0x80000000, v11
	v_cndmask_b32_e32 v2, v3, v1, vcc
	v_xor_b32_e32 v1, 0x80000000, v1
	v_cndmask_b32_e32 v1, v1, v3, vcc
	v_bitop3_b32 v1, v1, v11, s76 bitop3:0x78
	v_cmp_class_f32_e64 vcc, v0, s77
	v_mul_f32_e32 v0, v19, v19
	v_xor_b32_e32 v2, v14, v2
	v_cndmask_b32_e32 v14, v31, v1, vcc
	v_fmamk_f32 v1, v0, 0xb94c1982, v27
	v_fmaak_f32 v1, v0, v1, 0xbe2aaa9d
	v_mul_f32_e32 v1, v0, v1
	v_fmac_f32_e32 v19, v19, v1
	v_fmamk_f32 v1, v0, 0x37d75334, v28
	v_fmaak_f32 v1, v0, v1, 0x3d2aabf7
	v_xor_b32_e32 v2, v2, v13
	v_fmaak_f32 v1, v0, v1, 0xbf000004
	v_and_b32_e32 v3, 1, v20
	v_and_b32_e32 v21, 0x7fffffff, v18
	v_cndmask_b32_e32 v16, v31, v2, vcc
	v_fma_f32 v0, v0, v1, 1.0
	v_cmp_eq_u32_e32 vcc, 0, v3
	v_lshlrev_b32_e32 v1, 30, v20
	v_xor_b32_e32 v11, v21, v18
	v_cndmask_b32_e32 v3, v0, v19, vcc
	v_and_b32_e32 v2, 0x80000000, v1
	v_xor_b32_e32 v3, v11, v3
	v_xor_b32_e32 v2, v3, v2
	v_xor_b32_e32 v3, 0x80000000, v19
	v_cndmask_b32_e32 v0, v3, v0, vcc
	v_bitop3_b32 v0, v0, v1, s76 bitop3:0x78
	v_cmp_class_f32_e64 vcc, v18, s77
	s_nop 1
	v_cndmask_b32_e32 v11, v31, v0, vcc
	v_cndmask_b32_e32 v13, v31, v2, vcc
.LBB0_23:
	s_or_b64 exec, exec, s[50:51]
	s_xor_b64 s[2:3], s[48:49], -1
	s_andn2_b64 vcc, exec, s[46:47]
	s_cbranch_vccnz .LBB0_4
.Lft8:
	v_cmp_gt_u32_e32 vcc, s55, v6
	v_mov_b32_e32 v0, s57
	v_mov_b32_e32 v1, s55
	v_cndmask_b32_e64 v18, 1.0, -1.0, vcc
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_add_u32_e32 v20, v0, v6
	v_mov_b32_e32 v21, v7
	v_mov_b32_e32 v19, v18
	s_mov_b32 s48, 0
	s_branch .LBB0_26
.LBB0_25:
	s_or_b64 exec, exec, s[6:7]
	s_and_b64 s[4:5], s[4:5], exec
	s_cselect_b32 s4, s29, s31
	s_cselect_b32 s5, s28, s30
	v_mov_b32_e32 v23, s4
	s_cselect_b32 s4, s16, s20
	v_mov_b32_e32 v22, s5
	v_mad_u64_u32 v[34:35], s[4:5], s4, v8, 0
	s_cselect_b32 s6, s17, s21
	v_mov_b32_e32 v36, v35
	v_mad_u64_u32 v[36:37], s[4:5], s6, v8, v[36:37]
	s_cselect_b32 s4, s18, s22
	s_cselect_b32 s5, s19, s23
	v_mov_b32_e32 v35, v36
	s_mul_i32 s5, s5, s49
	s_mul_hi_u32 s6, s4, s49
	v_lshl_add_u64 v[22:23], v[34:35], 2, v[22:23]
	s_add_i32 s5, s6, s5
	s_mul_i32 s4, s4, s49
	v_lshl_add_u64 v[22:23], s[4:5], 2, v[22:23]
	s_add_i32 s48, s48, 1
	v_lshl_add_u64 v[22:23], v[6:7], 2, v[22:23]
	s_cmp_eq_u32 s48, s58
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[22:23], v[0:3], off
	s_cbranch_scc1 .LBB0_4
.LBB0_26:
	s_add_i32 s4, s48, s33
	s_sub_i32 s5, s4, s37
	s_min_u32 s49, s4, s5
	s_cmp_lt_u32 s4, s37
	s_cselect_b64 s[4:5], -1, 0
	s_and_b64 s[6:7], s[4:5], exec
	s_cselect_b32 s6, s25, s27
	s_cselect_b32 s7, s24, s26
	v_mov_b32_e32 v1, s6
	s_cselect_b32 s6, s8, s12
	v_mov_b32_e32 v0, s7
	v_mad_u64_u32 v[2:3], s[6:7], s6, v8, 0
	s_cselect_b32 s50, s9, s13
	v_mov_b32_e32 v22, v3
	v_mad_u64_u32 v[22:23], s[6:7], s50, v8, v[22:23]
	s_cselect_b32 s6, s10, s14
	s_cselect_b32 s7, s11, s15
	v_mov_b32_e32 v3, v22
	s_mul_i32 s7, s7, s49
	s_mul_hi_u32 s50, s6, s49
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	s_add_i32 s7, s50, s7
	s_mul_i32 s6, s6, s49
	v_lshl_add_u64 v[22:23], s[6:7], 2, v[0:1]
	v_lshl_add_u64 v[0:1], v[6:7], 2, v[22:23]
	global_load_dwordx4 v[0:3], v[0:1], off
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_cbranch_execz .LBB0_25
.Lft9:
	v_lshl_add_u64 v[22:23], v[20:21], 2, v[22:23]
	global_load_dwordx4 v[34:37], v[22:23], off
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[22:23], v[18:19], v[34:35]
	v_pk_mul_f32 v[34:35], v[18:19], v[36:37]
	v_pk_mul_f32 v[22:23], v[16:17], v[22:23]
	v_pk_mul_f32 v[34:35], v[12:13], v[34:35]
	v_pk_fma_f32 v[0:1], v[14:15], v[0:1], v[22:23]
	v_pk_fma_f32 v[2:3], v[10:11], v[2:3], v[34:35]
	s_branch .LBB0_25
.LBB0_28:
	s_mov_b64 s[0:1], 0
.LBB0_29:
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_53
.Lft10:
	v_lshlrev_b32_e32 v0, 3, v9
	v_and_b32_e32 v3, 0x78, v0
	v_cvt_f32_ubyte0_e32 v0, v3
	v_mul_f32_e32 v0, 0x3c000000, v0
	v_cmp_eq_f32_e64 s[6:7], s43, 1.0
	s_mov_b32 s2, 0x3f2aaaab
	s_mov_b32 s0, 0x3f317218
	v_cndmask_b32_e64 v2, v0, 1.0, s[6:7]
	v_mov_b32_e32 v0, s43
	v_cmp_lg_f32_e32 vcc, 0, v2
	s_mov_b32 s1, 2.0
	s_movk_i32 s4, 0x204
	v_cndmask_b32_e32 v9, 1.0, v0, vcc
	v_frexp_mant_f32_e64 v0, |v9|
	v_cmp_gt_f32_e32 vcc, s2, v0
	v_frexp_exp_i32_f32_e32 v16, v9
	s_mov_b32 s2, 0x3fb8aa3b
	v_cndmask_b32_e64 v1, 1.0, 2.0, vcc
	v_mul_f32_e32 v0, v0, v1
	v_add_f32_e32 v7, 1.0, v0
	v_rcp_f32_e32 v14, v7
	v_add_f32_e32 v1, -1.0, v7
	v_sub_f32_e32 v11, v0, v1
	v_add_f32_e32 v1, -1.0, v0
	v_mul_f32_e32 v15, v1, v14
	v_mul_f32_e32 v6, v7, v15
	v_fma_f32 v10, v15, v7, -v6
	v_fmac_f32_e32 v10, v15, v11
	v_add_f32_e32 v0, v6, v10
	v_sub_f32_e32 v7, v1, v0
	v_pk_add_f32 v[12:13], v[0:1], v[6:7] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v11, v0
	v_pk_add_f32 v[0:1], v[12:13], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v10, 0x3e91f4c4
	v_add_f32_e32 v0, v0, v1
	v_add_f32_e32 v0, v7, v0
	v_mul_f32_e32 v1, v14, v0
	v_add_f32_e32 v0, v15, v1
	v_sub_f32_e32 v6, v0, v15
	v_sub_f32_e32 v17, v1, v6
	v_mul_f32_e32 v1, v0, v0
	v_fma_f32 v7, v0, v0, -v1
	v_add_f32_e32 v18, v17, v17
	v_fmac_f32_e32 v7, v0, v18
	v_add_f32_e32 v6, v1, v7
	v_fmac_f32_e32 v10, 0x3e76c4e1, v6
	v_fmaak_f32 v10, v6, v10, 0x3ecccdef
	v_sub_f32_e32 v1, v6, v1
	v_sub_f32_e32 v19, v7, v1
	v_mul_f32_e32 v1, v6, v10
	v_fma_f32 v7, v6, v10, -v1
	v_fmac_f32_e32 v7, v19, v10
	v_add_f32_e32 v10, v1, v7
	v_add_f32_e32 v11, 0x3f2aaaaa, v10
	v_sub_f32_e32 v1, v10, v1
	v_sub_f32_e32 v1, v7, v1
	v_add_f32_e32 v7, 0xbf2aaaaa, v11
	v_add_f32_e32 v1, 0x31739010, v1
	v_sub_f32_e32 v7, v10, v7
	v_pk_mul_f32 v[12:13], v[0:1], v[6:7]
	v_pk_add_f32 v[14:15], v[0:1], v[6:7]
	v_fma_f32 v10, v6, v0, -v12
	v_fmac_f32_e32 v10, v6, v17
	v_mov_b32_e32 v13, v15
	v_fmac_f32_e32 v10, v19, v0
	v_pk_add_f32 v[6:7], v[12:13], v[10:11]
	s_brev_b32 s5, -2
	v_sub_f32_e32 v1, v6, v12
	v_sub_f32_e32 v1, v10, v1
	v_sub_f32_e32 v10, v11, v7
	v_mul_f32_e32 v11, v6, v7
	v_add_f32_e32 v10, v15, v10
	v_fma_f32 v12, v6, v7, -v11
	v_fmac_f32_e32 v12, v6, v10
	v_fmac_f32_e32 v12, v1, v7
	v_subbrev_co_u32_e32 v1, vcc, 0, v16, vcc
	v_cvt_f32_i32_e32 v6, v1
	v_add_f32_e32 v1, v11, v12
	v_sub_f32_e32 v7, v1, v11
	v_sub_f32_e32 v7, v12, v7
	v_add_f32_e32 v12, v18, v7
	v_mov_b32_e32 v7, v0
	v_pk_mul_f32 v[10:11], v[6:7], s[0:1]
	s_mov_b32 s1, 0x42b17218
	v_fma_f32 v0, v6, s0, -v10
	v_fmamk_f32 v0, v6, 0xb102e308, v0
	v_pk_add_f32 v[6:7], v[10:11], v[0:1]
	s_mov_b32 s0, 0x7f800000
	v_sub_f32_e32 v11, v7, v11
	v_sub_f32_e32 v1, v1, v11
	v_add_f32_e32 v11, v12, v1
	v_pk_add_f32 v[12:13], v[6:7], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[14:15], v[6:7], v[10:11]
	v_mov_b32_e32 v1, v6
	v_mov_b32_e32 v14, v12
	v_pk_add_f32 v[18:19], v[0:1], v[14:15]
	v_mov_b32_e32 v22, v15
	v_pk_add_f32 v[20:21], v[18:19], v[6:7] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v23, v19
	v_pk_mov_b32 v[24:25], v[6:7], v[20:21] op_sel:[1,0]
	v_pk_add_f32 v[16:17], v[0:1], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[22:23], v[22:23], v[24:25] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v10, v11
	v_mov_b32_e32 v11, v6
	v_mov_b32_e32 v1, v15
	v_mov_b32_e32 v13, v20
	v_pk_add_f32 v[6:7], v[10:11], v[22:23] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[0:1], v[0:1], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v17, v19
	v_pk_add_f32 v[0:1], v[0:1], v[6:7]
	s_nop 0
	v_pk_add_f32 v[10:11], v[0:1], v[0:1] op_sel:[0,1] op_sel_hi:[1,0]
	s_nop 0
	v_pk_add_f32 v[12:13], v[18:19], v[10:11] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v1, v12
	v_pk_add_f32 v[14:15], v[0:1], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v7, v10
	v_sub_f32_e32 v0, v0, v14
	v_pk_add_f32 v[6:7], v[6:7], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v0, v16, v0
	v_add_f32_e32 v0, v6, v0
	v_add_f32_e32 v0, v0, v7
	v_add_f32_e32 v1, v12, v0
	v_sub_f32_e32 v6, v1, v12
	v_sub_f32_e32 v0, v0, v6
	v_mul_f32_e32 v6, v2, v1
	v_fma_f32 v1, v2, v1, -v6
	v_fmac_f32_e32 v1, v2, v0
	v_add_f32_e32 v0, v6, v1
	v_cmp_class_f32_e64 vcc, v6, s4
	v_sub_f32_e32 v7, v0, v6
	v_sub_f32_e32 v1, v1, v7
	v_cndmask_b32_e32 v0, v0, v6, vcc
	v_mov_b32_e32 v6, 0x37000000
	v_cmp_eq_f32_e32 vcc, s1, v0
	s_nop 1
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_sub_f32_e32 v7, v0, v6
	v_mul_f32_e32 v10, 0x3fb8aa3b, v7
	v_fma_f32 v11, v7, s2, -v10
	v_rndne_f32_e32 v12, v10
	v_fmamk_f32 v11, v7, 0x32a5705f, v11
	v_sub_f32_e32 v10, v10, v12
	v_add_f32_e32 v10, v10, v11
	v_exp_f32_e32 v10, v10
	v_cvt_i32_f32_e32 v11, v12
	v_cmp_neq_f32_e64 vcc, |v0|, s0
	s_mov_b32 s0, 0xc2ce8ed0
	v_cmp_ngt_f32_e64 s[2:3], 0, v9
	v_cndmask_b32_e32 v0, 0, v1, vcc
	v_ldexp_f32 v1, v10, v11
	v_cmp_ngt_f32_e32 vcc, s0, v7
	v_add_f32_e32 v0, v6, v0
	v_mov_b32_e32 v6, 0x7f800000
	v_cndmask_b32_e32 v1, 0, v1, vcc
	v_cmp_nlt_f32_e32 vcc, s1, v7
	s_nop 1
	v_cndmask_b32_e32 v1, v6, v1, vcc
	v_fma_f32 v0, v1, v0, v1
	v_cmp_class_f32_e64 vcc, v1, s4
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_trunc_f32_e32 v1, v2
	v_cmp_eq_f32_e32 vcc, v1, v2
	v_mul_f32_e32 v1, 0.5, v2
	v_trunc_f32_e32 v2, v1
	v_cmp_lg_f32_e64 s[0:1], v2, v1
	s_and_b64 s[0:1], vcc, s[0:1]
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e64 v1, 1.0, v9, s[0:1]
	v_bfi_b32 v0, s5, v0, v1
	v_mov_b32_e32 v1, 0x7fc00000
	v_cndmask_b32_e32 v0, v1, v0, vcc
	v_cmp_eq_f32_e32 vcc, 0, v9
	v_cmp_class_f32_e64 s[2:3], v9, s4
	s_nop 0
	v_cndmask_b32_e64 v2, v6, 0, vcc
	v_cndmask_b32_e64 v6, 0, v9, s[0:1]
	v_bfi_b32 v2, s5, v2, v6
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e32 v0, v0, v2, vcc
	v_cmp_o_f32_e32 vcc, v9, v9
	s_brev_b32 s0, 18
	s_nop 0
	v_cndmask_b32_e32 v0, v1, v0, vcc
	v_mov_b32_e32 v1, s41
	v_fma_f32 v1, s40, v0, v1
	v_min_f32_e32 v1, 1.0, v1
	v_max_f32_e32 v1, 0, v1
	v_sub_f32_e32 v2, 1.0, v1
	v_mul_f32_e32 v6, s42, v0
	v_mul_f32_e32 v2, v6, v2
	v_fmac_f32_e32 v2, v0, v1
	v_mul_f32_e32 v0, v2, v5
	v_cmp_ge_f32_e64 s[0:1], |v0|, s0
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_xor_b64 s[34:35], exec, s[2:3]
	s_cbranch_execz .LBB0_32
.Lft11:
	v_frexp_exp_i32_f32_e32 v2, v0
	v_add_u32_e32 v2, 6, v2
	v_not_b32_e32 v6, 63
	v_cmp_lt_u32_e32 vcc, 63, v2
	v_frexp_mant_f32_e64 v1, |v0|
	v_mul_f32_e32 v1, 0x4b800000, v1
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_add_u32_e32 v2, v6, v2
	v_not_b32_e32 v6, 31
	v_cmp_lt_u32_e64 s[0:1], 31, v2
	v_cvt_u32_f32_e32 v1, v1
	s_mov_b32 s4, 0xfe5163ab
	v_cndmask_b32_e64 v9, 0, v6, s[0:1]
	v_add_u32_e32 v2, v9, v2
	v_cmp_lt_u32_e64 s[2:3], 31, v2
	v_mad_u64_u32 v[10:11], s[4:5], v1, s4, 0
	v_mov_b32_e32 v7, 0
	v_cndmask_b32_e64 v6, 0, v6, s[2:3]
	v_add_u32_e32 v2, v6, v2
	v_mov_b32_e32 v6, v11
	s_mov_b32 s4, 0x3c439041
	v_mad_u64_u32 v[12:13], s[4:5], v1, s4, v[6:7]
	v_mov_b32_e32 v6, v13
	s_mov_b32 s4, 0xdb629599
	v_mad_u64_u32 v[14:15], s[4:5], v1, s4, v[6:7]
	v_mov_b32_e32 v6, v15
	s_mov_b32 s4, 0xf534ddc0
	v_mad_u64_u32 v[16:17], s[4:5], v1, s4, v[6:7]
	v_mov_b32_e32 v6, v17
	s_mov_b32 s4, 0xfc2757d1
	v_mad_u64_u32 v[18:19], s[4:5], v1, s4, v[6:7]
	v_mov_b32_e32 v6, v19
	s_mov_b32 s4, 0x4e441529
	v_mad_u64_u32 v[20:21], s[4:5], v1, s4, v[6:7]
	v_mov_b32_e32 v6, v21
	s_mov_b32 s4, 0xa2f9836e
	v_mad_u64_u32 v[6:7], s[4:5], v1, s4, v[6:7]
	v_cndmask_b32_e32 v9, v20, v16, vcc
	v_cndmask_b32_e32 v1, v6, v18, vcc
	v_cndmask_b32_e32 v7, v7, v20, vcc
	v_cndmask_b32_e64 v6, v1, v9, s[0:1]
	v_cndmask_b32_e64 v1, v7, v1, s[0:1]
	v_cndmask_b32_e32 v7, v18, v14, vcc
	v_cndmask_b32_e64 v9, v9, v7, s[0:1]
	v_cndmask_b32_e64 v1, v1, v6, s[2:3]
	v_cndmask_b32_e64 v6, v6, v9, s[2:3]
	v_sub_u32_e32 v11, 32, v2
	v_alignbit_b32 v13, v1, v6, v11
	v_cmp_eq_u32_e64 s[4:5], 0, v2
	v_cndmask_b32_e32 v10, v14, v10, vcc
	s_nop 0
	v_cndmask_b32_e64 v2, v13, v1, s[4:5]
	v_cndmask_b32_e32 v1, v16, v12, vcc
	v_cndmask_b32_e64 v7, v7, v1, s[0:1]
	v_cndmask_b32_e64 v9, v9, v7, s[2:3]
	v_alignbit_b32 v12, v6, v9, v11
	v_cndmask_b32_e64 v6, v12, v6, s[4:5]
	v_bfe_u32 v15, v2, 29, 1
	v_cndmask_b32_e64 v1, v1, v10, s[0:1]
	v_alignbit_b32 v12, v2, v6, 30
	v_sub_u32_e32 v16, 0, v15
	v_cndmask_b32_e64 v1, v7, v1, s[2:3]
	v_xor_b32_e32 v12, v12, v16
	v_alignbit_b32 v7, v9, v1, v11
	v_cndmask_b32_e64 v7, v7, v9, s[4:5]
	v_ffbh_u32_e32 v9, v12
	v_alignbit_b32 v6, v6, v7, 30
	v_min_u32_e32 v9, 32, v9
	v_alignbit_b32 v1, v7, v1, 30
	v_xor_b32_e32 v6, v6, v16
	v_sub_u32_e32 v10, 31, v9
	v_xor_b32_e32 v1, v1, v16
	v_alignbit_b32 v11, v12, v6, v10
	v_alignbit_b32 v1, v6, v1, v10
	v_alignbit_b32 v6, v11, v1, 9
	v_ffbh_u32_e32 v7, v6
	v_min_u32_e32 v7, 32, v7
	v_lshrrev_b32_e32 v13, 29, v2
	v_not_b32_e32 v10, v7
	v_alignbit_b32 v1, v6, v1, v10
	v_lshlrev_b32_e32 v6, 31, v13
	v_or_b32_e32 v10, 0x33000000, v6
	v_add_lshl_u32 v7, v7, v9, 23
	v_lshrrev_b32_e32 v1, 9, v1
	v_sub_u32_e32 v7, v10, v7
	v_or_b32_e32 v6, 0.5, v6
	v_lshlrev_b32_e32 v9, 23, v9
	v_or_b32_e32 v1, v7, v1
	v_lshrrev_b32_e32 v7, 9, v11
	v_sub_u32_e32 v6, v6, v9
	v_or_b32_e32 v6, v7, v6
	s_mov_b32 s0, 0x3fc90fda
	v_mul_f32_e32 v7, 0x3fc90fda, v6
	v_fma_f32 v9, v6, s0, -v7
	v_fmamk_f32 v6, v6, 0x33a22168, v9
	v_fmac_f32_e32 v6, 0x3fc90fda, v1
	v_lshrrev_b32_e32 v2, 30, v2
	v_add_f32_e32 v1, v7, v6
	v_add_u32_e32 v2, v15, v2
.LBB0_32:
	s_andn2_saveexec_b64 s[0:1], s[34:35]
	s_cbranch_execz .LBB0_34
.Lft12:
	s_mov_b32 s2, 0x3f22f983
	v_mul_f32_e64 v1, |v0|, s2
	v_rndne_f32_e32 v1, v1
	s_mov_b32 s2, 0xbfc90fda
	v_cvt_i32_f32_e32 v2, v1
	v_fma_f32 v6, v1, s2, |v0|
	v_fmamk_f32 v6, v1, 0xb3a22168, v6
	v_fmamk_f32 v1, v1, 0xa7c234c4, v6
.LBB0_34:
	s_or_b64 exec, exec, s[0:1]
	v_or_b32_e32 v6, 2, v3
	v_cvt_f32_ubyte0_e32 v6, v6
	v_mul_f32_e32 v6, 0x3c000000, v6
	v_cndmask_b32_e64 v9, v6, 1.0, s[6:7]
	v_mov_b32_e32 v6, s43
	v_cmp_lg_f32_e32 vcc, 0, v9
	s_mov_b32 s2, 0x3f2aaaab
	s_mov_b32 s0, 0x3f317218
	v_cndmask_b32_e32 v28, 1.0, v6, vcc
	v_frexp_mant_f32_e64 v6, |v28|
	v_cmp_gt_f32_e32 vcc, s2, v6
	v_frexp_exp_i32_f32_e32 v18, v28
	s_mov_b32 s1, 2.0
	v_cndmask_b32_e64 v7, 1.0, 2.0, vcc
	v_mul_f32_e32 v6, v6, v7
	v_add_f32_e32 v11, 1.0, v6
	v_rcp_f32_e32 v16, v11
	v_add_f32_e32 v7, -1.0, v11
	v_sub_f32_e32 v13, v6, v7
	v_add_f32_e32 v7, -1.0, v6
	v_mul_f32_e32 v17, v7, v16
	v_mul_f32_e32 v10, v11, v17
	v_fma_f32 v12, v17, v11, -v10
	v_fmac_f32_e32 v12, v17, v13
	v_add_f32_e32 v6, v10, v12
	v_sub_f32_e32 v11, v7, v6
	v_pk_add_f32 v[14:15], v[6:7], v[10:11] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v13, v6
	v_pk_add_f32 v[6:7], v[14:15], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v12, 0x3e91f4c4
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v6, v11, v6
	v_mul_f32_e32 v7, v16, v6
	v_add_f32_e32 v6, v17, v7
	v_sub_f32_e32 v10, v6, v17
	v_sub_f32_e32 v19, v7, v10
	v_mul_f32_e32 v7, v6, v6
	v_fma_f32 v11, v6, v6, -v7
	v_add_f32_e32 v20, v19, v19
	v_fmac_f32_e32 v11, v6, v20
	v_add_f32_e32 v10, v7, v11
	v_fmac_f32_e32 v12, 0x3e76c4e1, v10
	v_fmaak_f32 v12, v10, v12, 0x3ecccdef
	v_sub_f32_e32 v7, v10, v7
	v_sub_f32_e32 v21, v11, v7
	v_mul_f32_e32 v7, v10, v12
	v_fma_f32 v11, v10, v12, -v7
	v_fmac_f32_e32 v11, v21, v12
	v_add_f32_e32 v12, v7, v11
	v_add_f32_e32 v13, 0x3f2aaaaa, v12
	v_sub_f32_e32 v7, v12, v7
	v_sub_f32_e32 v7, v11, v7
	v_add_f32_e32 v11, 0xbf2aaaaa, v13
	v_add_f32_e32 v7, 0x31739010, v7
	v_sub_f32_e32 v11, v12, v11
	v_pk_mul_f32 v[14:15], v[6:7], v[10:11]
	v_pk_add_f32 v[16:17], v[6:7], v[10:11]
	v_fma_f32 v12, v10, v6, -v14
	v_fmac_f32_e32 v12, v10, v19
	v_mov_b32_e32 v15, v17
	v_fmac_f32_e32 v12, v21, v6
	v_pk_add_f32 v[10:11], v[14:15], v[12:13]
	s_movk_i32 s4, 0x204
	v_sub_f32_e32 v7, v10, v14
	v_sub_f32_e32 v7, v12, v7
	v_sub_f32_e32 v12, v13, v11
	v_mul_f32_e32 v13, v10, v11
	v_add_f32_e32 v12, v17, v12
	v_fma_f32 v14, v10, v11, -v13
	v_fmac_f32_e32 v14, v10, v12
	v_fmac_f32_e32 v14, v7, v11
	v_subbrev_co_u32_e32 v7, vcc, 0, v18, vcc
	v_cvt_f32_i32_e32 v10, v7
	v_add_f32_e32 v7, v13, v14
	v_sub_f32_e32 v11, v7, v13
	v_sub_f32_e32 v11, v14, v11
	v_add_f32_e32 v14, v20, v11
	v_mov_b32_e32 v11, v6
	v_pk_mul_f32 v[12:13], v[10:11], s[0:1]
	s_mov_b32 s1, 0x42b17218
	v_fma_f32 v6, v10, s0, -v12
	v_fmamk_f32 v6, v10, 0xb102e308, v6
	v_pk_add_f32 v[10:11], v[12:13], v[6:7]
	s_mov_b32 s2, 0x3fb8aa3b
	v_sub_f32_e32 v13, v11, v13
	v_sub_f32_e32 v7, v7, v13
	v_add_f32_e32 v13, v14, v7
	v_pk_add_f32 v[14:15], v[10:11], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[16:17], v[10:11], v[12:13]
	v_mov_b32_e32 v7, v10
	v_mov_b32_e32 v16, v14
	v_pk_add_f32 v[20:21], v[6:7], v[16:17]
	v_mov_b32_e32 v24, v17
	v_pk_add_f32 v[22:23], v[20:21], v[10:11] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v25, v21
	v_pk_mov_b32 v[26:27], v[10:11], v[22:23] op_sel:[1,0]
	v_pk_add_f32 v[18:19], v[6:7], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[24:25], v[24:25], v[26:27] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v12, v13
	v_mov_b32_e32 v13, v10
	v_mov_b32_e32 v7, v17
	v_mov_b32_e32 v15, v22
	v_pk_add_f32 v[10:11], v[12:13], v[24:25] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[6:7], v[6:7], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v19, v21
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	s_mov_b32 s0, 0x7f800000
	v_pk_add_f32 v[12:13], v[6:7], v[6:7] op_sel:[0,1] op_sel_hi:[1,0]
	s_brev_b32 s5, -2
	v_pk_add_f32 v[14:15], v[20:21], v[12:13] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v7, v14
	v_pk_add_f32 v[16:17], v[6:7], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v11, v12
	v_sub_f32_e32 v6, v6, v16
	v_pk_add_f32 v[10:11], v[10:11], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v6, v18, v6
	v_add_f32_e32 v6, v10, v6
	v_add_f32_e32 v6, v6, v11
	v_add_f32_e32 v7, v14, v6
	v_sub_f32_e32 v10, v7, v14
	v_sub_f32_e32 v6, v6, v10
	v_mul_f32_e32 v10, v9, v7
	v_fma_f32 v7, v9, v7, -v10
	v_fmac_f32_e32 v7, v9, v6
	v_add_f32_e32 v6, v10, v7
	v_cmp_class_f32_e64 vcc, v10, s4
	v_sub_f32_e32 v11, v6, v10
	v_sub_f32_e32 v7, v7, v11
	v_cndmask_b32_e32 v6, v6, v10, vcc
	v_mov_b32_e32 v10, 0x37000000
	v_cmp_eq_f32_e32 vcc, s1, v6
	s_nop 1
	v_cndmask_b32_e32 v10, 0, v10, vcc
	v_sub_f32_e32 v11, v6, v10
	v_mul_f32_e32 v12, 0x3fb8aa3b, v11
	v_fma_f32 v13, v11, s2, -v12
	v_rndne_f32_e32 v14, v12
	v_fmamk_f32 v13, v11, 0x32a5705f, v13
	v_sub_f32_e32 v12, v12, v14
	v_add_f32_e32 v12, v12, v13
	v_exp_f32_e32 v12, v12
	v_cvt_i32_f32_e32 v13, v14
	v_cmp_neq_f32_e64 vcc, |v6|, s0
	s_mov_b32 s0, 0xc2ce8ed0
	v_cmp_ngt_f32_e64 s[2:3], 0, v28
	v_cndmask_b32_e32 v6, 0, v7, vcc
	v_ldexp_f32 v7, v12, v13
	v_cmp_ngt_f32_e32 vcc, s0, v11
	v_add_f32_e32 v6, v10, v6
	v_mov_b32_e32 v10, 0x7f800000
	v_cndmask_b32_e32 v7, 0, v7, vcc
	v_cmp_nlt_f32_e32 vcc, s1, v11
	s_nop 1
	v_cndmask_b32_e32 v7, v10, v7, vcc
	v_fma_f32 v6, v7, v6, v7
	v_cmp_class_f32_e64 vcc, v7, s4
	s_nop 1
	v_cndmask_b32_e32 v6, v6, v7, vcc
	v_trunc_f32_e32 v7, v9
	v_cmp_eq_f32_e32 vcc, v7, v9
	v_mul_f32_e32 v7, 0.5, v9
	v_trunc_f32_e32 v9, v7
	v_cmp_lg_f32_e64 s[0:1], v9, v7
	s_and_b64 s[0:1], vcc, s[0:1]
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e64 v7, 1.0, v28, s[0:1]
	v_bfi_b32 v6, s5, v6, v7
	v_mov_b32_e32 v7, 0x7fc00000
	v_cndmask_b32_e32 v6, v7, v6, vcc
	v_cmp_eq_f32_e32 vcc, 0, v28
	v_cmp_class_f32_e64 s[2:3], v28, s4
	s_nop 0
	v_cndmask_b32_e64 v9, v10, 0, vcc
	v_cndmask_b32_e64 v10, 0, v28, s[0:1]
	v_bfi_b32 v9, s5, v9, v10
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e32 v6, v6, v9, vcc
	v_cmp_o_f32_e32 vcc, v28, v28
	s_brev_b32 s0, 18
	s_nop 0
	v_cndmask_b32_e32 v6, v7, v6, vcc
	v_mov_b32_e32 v7, s41
	v_fma_f32 v7, s40, v6, v7
	v_min_f32_e32 v7, 1.0, v7
	v_max_f32_e32 v7, 0, v7
	v_sub_f32_e32 v9, 1.0, v7
	v_mul_f32_e32 v10, s42, v6
	v_mul_f32_e32 v9, v10, v9
	v_fmac_f32_e32 v9, v6, v7
	v_mul_f32_e32 v6, v9, v5
	v_cmp_ge_f32_e64 s[0:1], |v6|, s0
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_xor_b64 s[34:35], exec, s[2:3]
	s_cbranch_execz .LBB0_36
.Lft13:
	v_frexp_exp_i32_f32_e32 v9, v6
	v_add_u32_e32 v9, 6, v9
	v_not_b32_e32 v10, 63
	v_cmp_lt_u32_e32 vcc, 63, v9
	v_frexp_mant_f32_e64 v7, |v6|
	v_mul_f32_e32 v7, 0x4b800000, v7
	v_cndmask_b32_e32 v10, 0, v10, vcc
	v_add_u32_e32 v9, v10, v9
	v_not_b32_e32 v10, 31
	v_cmp_lt_u32_e64 s[0:1], 31, v9
	v_cvt_u32_f32_e32 v7, v7
	s_mov_b32 s4, 0xfe5163ab
	v_cndmask_b32_e64 v12, 0, v10, s[0:1]
	v_add_u32_e32 v9, v12, v9
	v_cmp_lt_u32_e64 s[2:3], 31, v9
	v_mad_u64_u32 v[12:13], s[4:5], v7, s4, 0
	v_mov_b32_e32 v11, 0
	v_cndmask_b32_e64 v10, 0, v10, s[2:3]
	v_add_u32_e32 v9, v10, v9
	v_mov_b32_e32 v10, v13
	s_mov_b32 s4, 0x3c439041
	v_mad_u64_u32 v[14:15], s[4:5], v7, s4, v[10:11]
	v_mov_b32_e32 v10, v15
	s_mov_b32 s4, 0xdb629599
	v_mad_u64_u32 v[16:17], s[4:5], v7, s4, v[10:11]
	v_mov_b32_e32 v10, v17
	s_mov_b32 s4, 0xf534ddc0
	v_mad_u64_u32 v[18:19], s[4:5], v7, s4, v[10:11]
	v_mov_b32_e32 v10, v19
	s_mov_b32 s4, 0xfc2757d1
	v_mad_u64_u32 v[20:21], s[4:5], v7, s4, v[10:11]
	v_mov_b32_e32 v10, v21
	s_mov_b32 s4, 0x4e441529
	v_mad_u64_u32 v[22:23], s[4:5], v7, s4, v[10:11]
	v_mov_b32_e32 v10, v23
	s_mov_b32 s4, 0xa2f9836e
	v_mad_u64_u32 v[10:11], s[4:5], v7, s4, v[10:11]
	v_cndmask_b32_e32 v13, v22, v18, vcc
	v_cndmask_b32_e32 v7, v10, v20, vcc
	v_cndmask_b32_e32 v11, v11, v22, vcc
	v_cndmask_b32_e64 v10, v7, v13, s[0:1]
	v_cndmask_b32_e64 v7, v11, v7, s[0:1]
	v_cndmask_b32_e32 v11, v20, v16, vcc
	v_cndmask_b32_e64 v13, v13, v11, s[0:1]
	v_cndmask_b32_e64 v7, v7, v10, s[2:3]
	v_cndmask_b32_e64 v10, v10, v13, s[2:3]
	v_sub_u32_e32 v15, 32, v9
	v_alignbit_b32 v17, v7, v10, v15
	v_cmp_eq_u32_e64 s[4:5], 0, v9
	v_cndmask_b32_e32 v12, v16, v12, vcc
	s_nop 0
	v_cndmask_b32_e64 v9, v17, v7, s[4:5]
	v_cndmask_b32_e32 v7, v18, v14, vcc
	v_cndmask_b32_e64 v11, v11, v7, s[0:1]
	v_cndmask_b32_e64 v13, v13, v11, s[2:3]
	v_alignbit_b32 v14, v10, v13, v15
	v_cndmask_b32_e64 v10, v14, v10, s[4:5]
	v_bfe_u32 v18, v9, 29, 1
	v_cndmask_b32_e64 v7, v7, v12, s[0:1]
	v_alignbit_b32 v14, v9, v10, 30
	v_sub_u32_e32 v19, 0, v18
	v_cndmask_b32_e64 v7, v11, v7, s[2:3]
	v_xor_b32_e32 v14, v14, v19
	v_alignbit_b32 v11, v13, v7, v15
	v_cndmask_b32_e64 v11, v11, v13, s[4:5]
	v_ffbh_u32_e32 v12, v14
	v_alignbit_b32 v10, v10, v11, 30
	v_min_u32_e32 v12, 32, v12
	v_alignbit_b32 v7, v11, v7, 30
	v_xor_b32_e32 v10, v10, v19
	v_sub_u32_e32 v13, 31, v12
	v_xor_b32_e32 v7, v7, v19
	v_alignbit_b32 v14, v14, v10, v13
	v_alignbit_b32 v7, v10, v7, v13
	v_alignbit_b32 v10, v14, v7, 9
	v_ffbh_u32_e32 v11, v10
	v_min_u32_e32 v11, 32, v11
	v_lshrrev_b32_e32 v17, 29, v9
	v_not_b32_e32 v13, v11
	v_alignbit_b32 v7, v10, v7, v13
	v_lshlrev_b32_e32 v10, 31, v17
	v_or_b32_e32 v13, 0x33000000, v10
	v_add_lshl_u32 v11, v11, v12, 23
	v_lshrrev_b32_e32 v7, 9, v7
	v_sub_u32_e32 v11, v13, v11
	v_or_b32_e32 v10, 0.5, v10
	v_lshlrev_b32_e32 v12, 23, v12
	v_or_b32_e32 v7, v11, v7
	v_lshrrev_b32_e32 v11, 9, v14
	v_sub_u32_e32 v10, v10, v12
	v_or_b32_e32 v10, v11, v10
	s_mov_b32 s0, 0x3fc90fda
	v_mul_f32_e32 v11, 0x3fc90fda, v10
	v_fma_f32 v12, v10, s0, -v11
	v_fmamk_f32 v10, v10, 0x33a22168, v12
	v_fmac_f32_e32 v10, 0x3fc90fda, v7
	v_lshrrev_b32_e32 v9, 30, v9
	v_add_f32_e32 v7, v11, v10
	v_add_u32_e32 v9, v18, v9
.LBB0_36:
	s_andn2_saveexec_b64 s[0:1], s[34:35]
	s_cbranch_execz .LBB0_38
.Lft14:
	s_mov_b32 s2, 0x3f22f983
	v_mul_f32_e64 v7, |v6|, s2
	v_rndne_f32_e32 v7, v7
	s_mov_b32 s2, 0xbfc90fda
	v_cvt_i32_f32_e32 v9, v7
	v_fma_f32 v10, v7, s2, |v6|
	v_fmamk_f32 v10, v7, 0xb3a22168, v10
	v_fmamk_f32 v7, v7, 0xa7c234c4, v10
.LBB0_38:
	s_or_b64 exec, exec, s[0:1]
	v_or_b32_e32 v10, 4, v3
	v_cvt_f32_ubyte0_e32 v10, v10
	v_mul_f32_e32 v10, 0x3c000000, v10
	v_cndmask_b32_e64 v30, v10, 1.0, s[6:7]
	v_mov_b32_e32 v10, s43
	v_cmp_lg_f32_e32 vcc, 0, v30
	s_mov_b32 s2, 0x3f2aaaab
	s_mov_b32 s0, 0x3f317218
	v_cndmask_b32_e32 v31, 1.0, v10, vcc
	v_frexp_mant_f32_e64 v10, |v31|
	v_cmp_gt_f32_e32 vcc, s2, v10
	v_frexp_exp_i32_f32_e32 v20, v31
	s_mov_b32 s1, 2.0
	v_cndmask_b32_e64 v11, 1.0, 2.0, vcc
	v_mul_f32_e32 v10, v10, v11
	v_add_f32_e32 v13, 1.0, v10
	v_rcp_f32_e32 v18, v13
	v_add_f32_e32 v11, -1.0, v13
	v_sub_f32_e32 v15, v10, v11
	v_add_f32_e32 v11, -1.0, v10
	v_mul_f32_e32 v19, v11, v18
	v_mul_f32_e32 v12, v13, v19
	v_fma_f32 v14, v19, v13, -v12
	v_fmac_f32_e32 v14, v19, v15
	v_add_f32_e32 v10, v12, v14
	v_sub_f32_e32 v13, v11, v10
	v_pk_add_f32 v[16:17], v[10:11], v[12:13] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v15, v10
	v_pk_add_f32 v[10:11], v[16:17], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v14, 0x3e91f4c4
	v_add_f32_e32 v10, v10, v11
	v_add_f32_e32 v10, v13, v10
	v_mul_f32_e32 v11, v18, v10
	v_add_f32_e32 v10, v19, v11
	v_sub_f32_e32 v12, v10, v19
	v_sub_f32_e32 v21, v11, v12
	v_mul_f32_e32 v11, v10, v10
	v_fma_f32 v13, v10, v10, -v11
	v_add_f32_e32 v22, v21, v21
	v_fmac_f32_e32 v13, v10, v22
	v_add_f32_e32 v12, v11, v13
	v_fmac_f32_e32 v14, 0x3e76c4e1, v12
	v_fmaak_f32 v14, v12, v14, 0x3ecccdef
	v_sub_f32_e32 v11, v12, v11
	v_sub_f32_e32 v23, v13, v11
	v_mul_f32_e32 v11, v12, v14
	v_fma_f32 v13, v12, v14, -v11
	v_fmac_f32_e32 v13, v23, v14
	v_add_f32_e32 v14, v11, v13
	v_add_f32_e32 v15, 0x3f2aaaaa, v14
	v_sub_f32_e32 v11, v14, v11
	v_sub_f32_e32 v11, v13, v11
	v_add_f32_e32 v13, 0xbf2aaaaa, v15
	v_add_f32_e32 v11, 0x31739010, v11
	v_sub_f32_e32 v13, v14, v13
	v_pk_mul_f32 v[16:17], v[10:11], v[12:13]
	v_pk_add_f32 v[18:19], v[10:11], v[12:13]
	v_fma_f32 v14, v12, v10, -v16
	v_fmac_f32_e32 v14, v12, v21
	v_mov_b32_e32 v17, v19
	v_fmac_f32_e32 v14, v23, v10
	v_pk_add_f32 v[12:13], v[16:17], v[14:15]
	s_movk_i32 s4, 0x204
	v_sub_f32_e32 v11, v12, v16
	v_sub_f32_e32 v11, v14, v11
	v_sub_f32_e32 v14, v15, v13
	v_mul_f32_e32 v15, v12, v13
	v_add_f32_e32 v14, v19, v14
	v_fma_f32 v16, v12, v13, -v15
	v_fmac_f32_e32 v16, v12, v14
	v_fmac_f32_e32 v16, v11, v13
	v_subbrev_co_u32_e32 v11, vcc, 0, v20, vcc
	v_cvt_f32_i32_e32 v12, v11
	v_add_f32_e32 v11, v15, v16
	v_sub_f32_e32 v13, v11, v15
	v_sub_f32_e32 v13, v16, v13
	v_add_f32_e32 v16, v22, v13
	v_mov_b32_e32 v13, v10
	v_pk_mul_f32 v[14:15], v[12:13], s[0:1]
	s_mov_b32 s1, 0x42b17218
	v_fma_f32 v10, v12, s0, -v14
	v_fmamk_f32 v10, v12, 0xb102e308, v10
	v_pk_add_f32 v[12:13], v[14:15], v[10:11]
	s_mov_b32 s2, 0x3fb8aa3b
	v_sub_f32_e32 v15, v13, v15
	v_sub_f32_e32 v11, v11, v15
	v_add_f32_e32 v15, v16, v11
	v_pk_add_f32 v[16:17], v[12:13], v[14:15] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[18:19], v[12:13], v[14:15]
	v_mov_b32_e32 v11, v12
	v_mov_b32_e32 v18, v16
	v_pk_add_f32 v[22:23], v[10:11], v[18:19]
	v_mov_b32_e32 v26, v19
	v_pk_add_f32 v[24:25], v[22:23], v[12:13] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v27, v23
	v_pk_mov_b32 v[28:29], v[12:13], v[24:25] op_sel:[1,0]
	v_pk_add_f32 v[20:21], v[10:11], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[26:27], v[26:27], v[28:29] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v14, v15
	v_mov_b32_e32 v15, v12
	v_mov_b32_e32 v11, v19
	v_mov_b32_e32 v17, v24
	v_pk_add_f32 v[12:13], v[14:15], v[26:27] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[10:11], v[10:11], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v21, v23
	v_pk_add_f32 v[10:11], v[10:11], v[12:13]
	s_mov_b32 s0, 0x7f800000
	v_pk_add_f32 v[14:15], v[10:11], v[10:11] op_sel:[0,1] op_sel_hi:[1,0]
	s_brev_b32 s5, -2
	v_pk_add_f32 v[16:17], v[22:23], v[14:15] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v11, v16
	v_pk_add_f32 v[18:19], v[10:11], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v13, v14
	v_sub_f32_e32 v10, v10, v18
	v_pk_add_f32 v[12:13], v[12:13], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v10, v20, v10
	v_add_f32_e32 v10, v12, v10
	v_add_f32_e32 v10, v10, v13
	v_add_f32_e32 v11, v16, v10
	v_sub_f32_e32 v12, v11, v16
	v_sub_f32_e32 v10, v10, v12
	v_mul_f32_e32 v12, v30, v11
	v_fma_f32 v11, v30, v11, -v12
	v_fmac_f32_e32 v11, v30, v10
	v_add_f32_e32 v10, v12, v11
	v_cmp_class_f32_e64 vcc, v12, s4
	v_sub_f32_e32 v13, v10, v12
	v_sub_f32_e32 v11, v11, v13
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_mov_b32_e32 v12, 0x37000000
	v_cmp_eq_f32_e32 vcc, s1, v10
	s_nop 1
	v_cndmask_b32_e32 v12, 0, v12, vcc
	v_sub_f32_e32 v13, v10, v12
	v_mul_f32_e32 v14, 0x3fb8aa3b, v13
	v_fma_f32 v15, v13, s2, -v14
	v_rndne_f32_e32 v16, v14
	v_fmamk_f32 v15, v13, 0x32a5705f, v15
	v_sub_f32_e32 v14, v14, v16
	v_add_f32_e32 v14, v14, v15
	v_exp_f32_e32 v14, v14
	v_cvt_i32_f32_e32 v15, v16
	v_cmp_neq_f32_e64 vcc, |v10|, s0
	s_mov_b32 s0, 0xc2ce8ed0
	v_cmp_ngt_f32_e64 s[2:3], 0, v31
	v_cndmask_b32_e32 v10, 0, v11, vcc
	v_ldexp_f32 v11, v14, v15
	v_cmp_ngt_f32_e32 vcc, s0, v13
	v_add_f32_e32 v10, v12, v10
	v_mov_b32_e32 v12, 0x7f800000
	v_cndmask_b32_e32 v11, 0, v11, vcc
	v_cmp_nlt_f32_e32 vcc, s1, v13
	s_nop 1
	v_cndmask_b32_e32 v11, v12, v11, vcc
	v_fma_f32 v10, v11, v10, v11
	v_cmp_class_f32_e64 vcc, v11, s4
	s_nop 1
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_trunc_f32_e32 v11, v30
	v_cmp_eq_f32_e32 vcc, v11, v30
	v_mul_f32_e32 v11, 0.5, v30
	v_trunc_f32_e32 v13, v11
	v_cmp_lg_f32_e64 s[0:1], v13, v11
	s_and_b64 s[0:1], vcc, s[0:1]
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e64 v11, 1.0, v31, s[0:1]
	v_bfi_b32 v10, s5, v10, v11
	v_mov_b32_e32 v11, 0x7fc00000
	v_cndmask_b32_e32 v10, v11, v10, vcc
	v_cmp_eq_f32_e32 vcc, 0, v31
	v_cmp_class_f32_e64 s[2:3], v31, s4
	v_cndmask_b32_e64 v13, 0, v31, s[0:1]
	v_cndmask_b32_e64 v12, v12, 0, vcc
	v_bfi_b32 v12, s5, v12, v13
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_cmp_o_f32_e32 vcc, v31, v31
	s_brev_b32 s0, 18
	s_nop 0
	v_cndmask_b32_e32 v10, v11, v10, vcc
	v_mov_b32_e32 v11, s41
	v_fma_f32 v11, s40, v10, v11
	v_min_f32_e32 v11, 1.0, v11
	v_max_f32_e32 v11, 0, v11
	v_sub_f32_e32 v12, 1.0, v11
	v_mul_f32_e32 v13, s42, v10
	v_mul_f32_e32 v12, v13, v12
	v_fmac_f32_e32 v12, v10, v11
	v_mul_f32_e32 v10, v12, v5
	v_cmp_ge_f32_e64 s[0:1], |v10|, s0
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_xor_b64 s[34:35], exec, s[2:3]
	s_cbranch_execz .LBB0_40
.Lft15:
	v_frexp_exp_i32_f32_e32 v12, v10
	v_add_u32_e32 v12, 6, v12
	v_not_b32_e32 v14, 63
	v_cmp_lt_u32_e32 vcc, 63, v12
	v_frexp_mant_f32_e64 v11, |v10|
	v_mul_f32_e32 v11, 0x4b800000, v11
	v_cndmask_b32_e32 v14, 0, v14, vcc
	v_add_u32_e32 v12, v14, v12
	v_not_b32_e32 v14, 31
	v_cmp_lt_u32_e64 s[0:1], 31, v12
	v_cvt_u32_f32_e32 v11, v11
	s_mov_b32 s4, 0xfe5163ab
	v_cndmask_b32_e64 v15, 0, v14, s[0:1]
	v_add_u32_e32 v12, v15, v12
	v_cmp_lt_u32_e64 s[2:3], 31, v12
	v_mov_b32_e32 v13, 0
	s_nop 0
	v_cndmask_b32_e64 v14, 0, v14, s[2:3]
	v_add_u32_e32 v26, v14, v12
	v_mad_u64_u32 v[14:15], s[4:5], v11, s4, 0
	v_mov_b32_e32 v12, v15
	s_mov_b32 s4, 0x3c439041
	v_mad_u64_u32 v[16:17], s[4:5], v11, s4, v[12:13]
	v_mov_b32_e32 v12, v17
	s_mov_b32 s4, 0xdb629599
	v_mad_u64_u32 v[18:19], s[4:5], v11, s4, v[12:13]
	v_mov_b32_e32 v12, v19
	s_mov_b32 s4, 0xf534ddc0
	v_mad_u64_u32 v[20:21], s[4:5], v11, s4, v[12:13]
	v_mov_b32_e32 v12, v21
	s_mov_b32 s4, 0xfc2757d1
	v_mad_u64_u32 v[22:23], s[4:5], v11, s4, v[12:13]
	v_mov_b32_e32 v12, v23
	s_mov_b32 s4, 0x4e441529
	v_mad_u64_u32 v[24:25], s[4:5], v11, s4, v[12:13]
	v_mov_b32_e32 v12, v25
	s_mov_b32 s4, 0xa2f9836e
	v_mad_u64_u32 v[12:13], s[4:5], v11, s4, v[12:13]
	v_cndmask_b32_e32 v15, v24, v20, vcc
	v_cndmask_b32_e32 v11, v12, v22, vcc
	v_cndmask_b32_e32 v13, v13, v24, vcc
	v_cndmask_b32_e64 v12, v11, v15, s[0:1]
	v_cndmask_b32_e64 v11, v13, v11, s[0:1]
	v_cndmask_b32_e32 v13, v22, v18, vcc
	v_cndmask_b32_e64 v15, v15, v13, s[0:1]
	v_cndmask_b32_e64 v11, v11, v12, s[2:3]
	v_cndmask_b32_e64 v12, v12, v15, s[2:3]
	v_sub_u32_e32 v17, 32, v26
	v_alignbit_b32 v19, v11, v12, v17
	v_cmp_eq_u32_e64 s[4:5], 0, v26
	v_cndmask_b32_e32 v14, v18, v14, vcc
	s_nop 0
	v_cndmask_b32_e64 v19, v19, v11, s[4:5]
	v_cndmask_b32_e32 v11, v20, v16, vcc
	v_cndmask_b32_e64 v13, v13, v11, s[0:1]
	v_cndmask_b32_e64 v15, v15, v13, s[2:3]
	v_alignbit_b32 v16, v12, v15, v17
	v_cndmask_b32_e64 v12, v16, v12, s[4:5]
	v_bfe_u32 v21, v19, 29, 1
	v_cndmask_b32_e64 v11, v11, v14, s[0:1]
	v_alignbit_b32 v16, v19, v12, 30
	v_sub_u32_e32 v22, 0, v21
	v_cndmask_b32_e64 v11, v13, v11, s[2:3]
	v_xor_b32_e32 v16, v16, v22
	v_alignbit_b32 v13, v15, v11, v17
	v_cndmask_b32_e64 v13, v13, v15, s[4:5]
	v_ffbh_u32_e32 v14, v16
	v_alignbit_b32 v12, v12, v13, 30
	v_min_u32_e32 v14, 32, v14
	v_alignbit_b32 v11, v13, v11, 30
	v_xor_b32_e32 v12, v12, v22
	v_sub_u32_e32 v15, 31, v14
	v_xor_b32_e32 v11, v11, v22
	v_alignbit_b32 v16, v16, v12, v15
	v_alignbit_b32 v11, v12, v11, v15
	v_alignbit_b32 v12, v16, v11, 9
	v_ffbh_u32_e32 v13, v12
	v_min_u32_e32 v13, 32, v13
	v_lshrrev_b32_e32 v20, 29, v19
	v_not_b32_e32 v15, v13
	v_alignbit_b32 v11, v12, v11, v15
	v_lshlrev_b32_e32 v12, 31, v20
	v_or_b32_e32 v15, 0x33000000, v12
	v_add_lshl_u32 v13, v13, v14, 23
	v_lshrrev_b32_e32 v11, 9, v11
	v_sub_u32_e32 v13, v15, v13
	v_or_b32_e32 v12, 0.5, v12
	v_lshlrev_b32_e32 v14, 23, v14
	v_or_b32_e32 v11, v13, v11
	v_lshrrev_b32_e32 v13, 9, v16
	v_sub_u32_e32 v12, v12, v14
	v_or_b32_e32 v12, v13, v12
	s_mov_b32 s0, 0x3fc90fda
	v_mul_f32_e32 v13, 0x3fc90fda, v12
	v_fma_f32 v14, v12, s0, -v13
	v_fmamk_f32 v12, v12, 0x33a22168, v14
	v_fmac_f32_e32 v12, 0x3fc90fda, v11
	v_add_f32_e32 v11, v13, v12
	v_lshrrev_b32_e32 v12, 30, v19
	v_add_u32_e32 v12, v21, v12
.LBB0_40:
	s_andn2_saveexec_b64 s[0:1], s[34:35]
	s_cbranch_execz .LBB0_42
.Lft16:
	s_mov_b32 s2, 0x3f22f983
	v_mul_f32_e64 v11, |v10|, s2
	v_rndne_f32_e32 v11, v11
	s_mov_b32 s2, 0xbfc90fda
	v_cvt_i32_f32_e32 v12, v11
	v_fma_f32 v13, v11, s2, |v10|
	v_fmamk_f32 v13, v11, 0xb3a22168, v13
	v_fmamk_f32 v11, v11, 0xa7c234c4, v13
.LBB0_42:
	s_or_b64 exec, exec, s[0:1]
	v_or_b32_e32 v3, 6, v3
	v_cvt_f32_ubyte0_e32 v3, v3
	v_mul_f32_e32 v3, 0x3c000000, v3
	v_cndmask_b32_e64 v3, v3, 1.0, s[6:7]
	v_mov_b32_e32 v13, s43
	v_cmp_lg_f32_e32 vcc, 0, v3
	s_mov_b32 s2, 0x3f2aaaab
	s_mov_b32 s0, 0x3f317218
	v_cndmask_b32_e32 v13, 1.0, v13, vcc
	v_frexp_mant_f32_e64 v14, |v13|
	v_cmp_gt_f32_e32 vcc, s2, v14
	v_frexp_exp_i32_f32_e32 v24, v13
	s_mov_b32 s1, 2.0
	v_cndmask_b32_e64 v15, 1.0, 2.0, vcc
	v_mul_f32_e32 v14, v14, v15
	v_add_f32_e32 v17, 1.0, v14
	v_rcp_f32_e32 v22, v17
	v_add_f32_e32 v15, -1.0, v17
	v_sub_f32_e32 v19, v14, v15
	v_add_f32_e32 v15, -1.0, v14
	v_mul_f32_e32 v23, v15, v22
	v_mul_f32_e32 v16, v17, v23
	v_fma_f32 v18, v23, v17, -v16
	v_fmac_f32_e32 v18, v23, v19
	v_add_f32_e32 v14, v16, v18
	v_sub_f32_e32 v17, v15, v14
	v_pk_add_f32 v[20:21], v[14:15], v[16:17] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v19, v14
	v_pk_add_f32 v[14:15], v[20:21], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v18, 0x3e91f4c4
	v_add_f32_e32 v14, v14, v15
	v_add_f32_e32 v14, v17, v14
	v_mul_f32_e32 v15, v22, v14
	v_add_f32_e32 v14, v23, v15
	v_sub_f32_e32 v16, v14, v23
	v_sub_f32_e32 v25, v15, v16
	v_mul_f32_e32 v15, v14, v14
	v_fma_f32 v17, v14, v14, -v15
	v_add_f32_e32 v26, v25, v25
	v_fmac_f32_e32 v17, v14, v26
	v_add_f32_e32 v16, v15, v17
	v_fmac_f32_e32 v18, 0x3e76c4e1, v16
	v_fmaak_f32 v18, v16, v18, 0x3ecccdef
	v_sub_f32_e32 v15, v16, v15
	v_sub_f32_e32 v27, v17, v15
	v_mul_f32_e32 v15, v16, v18
	v_fma_f32 v17, v16, v18, -v15
	v_fmac_f32_e32 v17, v27, v18
	v_add_f32_e32 v18, v15, v17
	v_add_f32_e32 v19, 0x3f2aaaaa, v18
	v_sub_f32_e32 v15, v18, v15
	v_sub_f32_e32 v15, v17, v15
	v_add_f32_e32 v17, 0xbf2aaaaa, v19
	v_add_f32_e32 v15, 0x31739010, v15
	v_sub_f32_e32 v17, v18, v17
	v_pk_mul_f32 v[20:21], v[14:15], v[16:17]
	v_pk_add_f32 v[22:23], v[14:15], v[16:17]
	v_fma_f32 v18, v16, v14, -v20
	v_fmac_f32_e32 v18, v16, v25
	v_mov_b32_e32 v21, v23
	v_fmac_f32_e32 v18, v27, v14
	v_pk_add_f32 v[16:17], v[20:21], v[18:19]
	s_movk_i32 s4, 0x204
	v_sub_f32_e32 v15, v16, v20
	v_sub_f32_e32 v15, v18, v15
	v_sub_f32_e32 v18, v19, v17
	v_mul_f32_e32 v19, v16, v17
	v_add_f32_e32 v18, v23, v18
	v_fma_f32 v20, v16, v17, -v19
	v_fmac_f32_e32 v20, v16, v18
	v_fmac_f32_e32 v20, v15, v17
	v_subbrev_co_u32_e32 v15, vcc, 0, v24, vcc
	v_cvt_f32_i32_e32 v16, v15
	v_add_f32_e32 v15, v19, v20
	v_sub_f32_e32 v17, v15, v19
	v_sub_f32_e32 v17, v20, v17
	v_add_f32_e32 v20, v26, v17
	v_mov_b32_e32 v17, v14
	v_pk_mul_f32 v[18:19], v[16:17], s[0:1]
	s_mov_b32 s1, 0x42b17218
	v_fma_f32 v14, v16, s0, -v18
	v_fmamk_f32 v14, v16, 0xb102e308, v14
	v_pk_add_f32 v[16:17], v[18:19], v[14:15]
	s_mov_b32 s2, 0x3fb8aa3b
	v_sub_f32_e32 v19, v17, v19
	v_sub_f32_e32 v15, v15, v19
	v_add_f32_e32 v19, v20, v15
	v_pk_add_f32 v[20:21], v[16:17], v[18:19] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[22:23], v[16:17], v[18:19]
	v_mov_b32_e32 v15, v16
	v_mov_b32_e32 v22, v20
	v_pk_add_f32 v[26:27], v[14:15], v[22:23]
	v_mov_b32_e32 v30, v23
	v_pk_add_f32 v[28:29], v[26:27], v[16:17] op_sel:[1,0] op_sel_hi:[0,1] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v31, v27
	v_pk_mov_b32 v[32:33], v[16:17], v[28:29] op_sel:[1,0]
	v_pk_add_f32 v[24:25], v[14:15], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[30:31], v[30:31], v[32:33] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v18, v19
	v_mov_b32_e32 v19, v16
	v_mov_b32_e32 v15, v23
	v_mov_b32_e32 v21, v28
	v_pk_add_f32 v[16:17], v[18:19], v[30:31] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[14:15], v[14:15], v[20:21] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v25, v27
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	s_mov_b32 s0, 0x7f800000
	v_pk_add_f32 v[18:19], v[14:15], v[14:15] op_sel:[0,1] op_sel_hi:[1,0]
	s_brev_b32 s5, -2
	v_pk_add_f32 v[20:21], v[26:27], v[18:19] op_sel:[1,0] op_sel_hi:[0,1]
	v_mov_b32_e32 v15, v20
	v_pk_add_f32 v[22:23], v[14:15], v[24:25] neg_lo:[0,1] neg_hi:[0,1]
	v_mov_b32_e32 v17, v18
	v_sub_f32_e32 v14, v14, v22
	v_pk_add_f32 v[16:17], v[16:17], v[22:23] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_f32_e32 v14, v24, v14
	v_add_f32_e32 v14, v16, v14
	v_add_f32_e32 v14, v14, v17
	v_add_f32_e32 v15, v20, v14
	v_sub_f32_e32 v16, v15, v20
	v_sub_f32_e32 v14, v14, v16
	v_mul_f32_e32 v16, v3, v15
	v_fma_f32 v15, v3, v15, -v16
	v_fmac_f32_e32 v15, v3, v14
	v_add_f32_e32 v14, v16, v15
	v_cmp_class_f32_e64 vcc, v16, s4
	v_sub_f32_e32 v17, v14, v16
	v_sub_f32_e32 v15, v15, v17
	v_cndmask_b32_e32 v14, v14, v16, vcc
	v_mov_b32_e32 v16, 0x37000000
	v_cmp_eq_f32_e32 vcc, s1, v14
	s_nop 1
	v_cndmask_b32_e32 v16, 0, v16, vcc
	v_sub_f32_e32 v17, v14, v16
	v_mul_f32_e32 v18, 0x3fb8aa3b, v17
	v_fma_f32 v19, v17, s2, -v18
	v_rndne_f32_e32 v20, v18
	v_fmamk_f32 v19, v17, 0x32a5705f, v19
	v_sub_f32_e32 v18, v18, v20
	v_add_f32_e32 v18, v18, v19
	v_exp_f32_e32 v18, v18
	v_cvt_i32_f32_e32 v19, v20
	v_cmp_neq_f32_e64 vcc, |v14|, s0
	s_mov_b32 s0, 0xc2ce8ed0
	v_cmp_ngt_f32_e64 s[2:3], 0, v13
	v_cndmask_b32_e32 v14, 0, v15, vcc
	v_ldexp_f32 v15, v18, v19
	v_cmp_ngt_f32_e32 vcc, s0, v17
	v_add_f32_e32 v14, v16, v14
	v_mov_b32_e32 v16, 0x7f800000
	v_cndmask_b32_e32 v15, 0, v15, vcc
	v_cmp_nlt_f32_e32 vcc, s1, v17
	s_nop 1
	v_cndmask_b32_e32 v15, v16, v15, vcc
	v_fma_f32 v14, v15, v14, v15
	v_cmp_class_f32_e64 vcc, v15, s4
	s_nop 1
	v_cndmask_b32_e32 v14, v14, v15, vcc
	v_trunc_f32_e32 v15, v3
	v_cmp_eq_f32_e32 vcc, v15, v3
	v_mul_f32_e32 v3, 0.5, v3
	v_trunc_f32_e32 v15, v3
	v_cmp_lg_f32_e64 s[0:1], v15, v3
	s_and_b64 s[0:1], vcc, s[0:1]
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e64 v3, 1.0, v13, s[0:1]
	v_bfi_b32 v3, s5, v14, v3
	v_mov_b32_e32 v14, 0x7fc00000
	v_cndmask_b32_e32 v3, v14, v3, vcc
	v_cmp_eq_f32_e32 vcc, 0, v13
	v_cmp_class_f32_e64 s[2:3], v13, s4
	s_nop 0
	v_cndmask_b32_e64 v15, v16, 0, vcc
	v_cndmask_b32_e64 v16, 0, v13, s[0:1]
	v_bfi_b32 v15, s5, v15, v16
	s_or_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e32 v3, v3, v15, vcc
	v_cmp_o_f32_e32 vcc, v13, v13
	v_mov_b32_e32 v13, s41
	s_brev_b32 s0, 18
	v_cndmask_b32_e32 v3, v14, v3, vcc
	v_fma_f32 v13, s40, v3, v13
	v_min_f32_e32 v13, 1.0, v13
	v_max_f32_e32 v13, 0, v13
	v_sub_f32_e32 v14, 1.0, v13
	v_mul_f32_e32 v15, s42, v3
	v_mul_f32_e32 v14, v15, v14
	v_fmac_f32_e32 v14, v3, v13
	v_mul_f32_e32 v3, v14, v5
	v_cmp_ge_f32_e64 s[0:1], |v3|, s0
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_xor_b64 s[6:7], exec, s[2:3]
	s_cbranch_execz .LBB0_44
.Lft17:
	v_frexp_exp_i32_f32_e32 v13, v3
	v_add_u32_e32 v13, 6, v13
	v_not_b32_e32 v14, 63
	v_cmp_lt_u32_e32 vcc, 63, v13
	v_frexp_mant_f32_e64 v5, |v3|
	v_mul_f32_e32 v5, 0x4b800000, v5
	v_cndmask_b32_e32 v14, 0, v14, vcc
	v_add_u32_e32 v13, v14, v13
	v_not_b32_e32 v14, 31
	v_cmp_lt_u32_e64 s[0:1], 31, v13
	v_cvt_u32_f32_e32 v5, v5
	s_mov_b32 s4, 0xfe5163ab
	v_cndmask_b32_e64 v16, 0, v14, s[0:1]
	v_add_u32_e32 v13, v16, v13
	v_cmp_lt_u32_e64 s[2:3], 31, v13
	v_mad_u64_u32 v[16:17], s[4:5], v5, s4, 0
	v_mov_b32_e32 v15, 0
	v_cndmask_b32_e64 v14, 0, v14, s[2:3]
	v_add_u32_e32 v13, v14, v13
	v_mov_b32_e32 v14, v17
	s_mov_b32 s4, 0x3c439041
	v_mad_u64_u32 v[18:19], s[4:5], v5, s4, v[14:15]
	v_mov_b32_e32 v14, v19
	s_mov_b32 s4, 0xdb629599
	v_mad_u64_u32 v[20:21], s[4:5], v5, s4, v[14:15]
	v_mov_b32_e32 v14, v21
	s_mov_b32 s4, 0xf534ddc0
	v_mad_u64_u32 v[22:23], s[4:5], v5, s4, v[14:15]
	v_mov_b32_e32 v14, v23
	s_mov_b32 s4, 0xfc2757d1
	v_mad_u64_u32 v[24:25], s[4:5], v5, s4, v[14:15]
	v_mov_b32_e32 v14, v25
	s_mov_b32 s4, 0x4e441529
	v_mad_u64_u32 v[26:27], s[4:5], v5, s4, v[14:15]
	v_mov_b32_e32 v14, v27
	s_mov_b32 s4, 0xa2f9836e
	v_mad_u64_u32 v[14:15], s[4:5], v5, s4, v[14:15]
	v_cndmask_b32_e32 v17, v26, v22, vcc
	v_cndmask_b32_e32 v5, v14, v24, vcc
	v_cndmask_b32_e32 v15, v15, v26, vcc
	v_cndmask_b32_e64 v14, v5, v17, s[0:1]
	v_cndmask_b32_e64 v5, v15, v5, s[0:1]
	v_cndmask_b32_e32 v15, v24, v20, vcc
	v_cndmask_b32_e64 v17, v17, v15, s[0:1]
	v_cndmask_b32_e64 v5, v5, v14, s[2:3]
	v_cndmask_b32_e64 v14, v14, v17, s[2:3]
	v_sub_u32_e32 v19, 32, v13
	v_alignbit_b32 v21, v5, v14, v19
	v_cmp_eq_u32_e64 s[4:5], 0, v13
	v_cndmask_b32_e32 v16, v20, v16, vcc
	s_nop 0
	v_cndmask_b32_e64 v13, v21, v5, s[4:5]
	v_cndmask_b32_e32 v5, v22, v18, vcc
	v_cndmask_b32_e64 v15, v15, v5, s[0:1]
	v_cndmask_b32_e64 v17, v17, v15, s[2:3]
	v_alignbit_b32 v18, v14, v17, v19
	v_cndmask_b32_e64 v14, v18, v14, s[4:5]
	v_bfe_u32 v22, v13, 29, 1
	v_cndmask_b32_e64 v5, v5, v16, s[0:1]
	v_alignbit_b32 v18, v13, v14, 30
	v_sub_u32_e32 v23, 0, v22
	v_cndmask_b32_e64 v5, v15, v5, s[2:3]
	v_xor_b32_e32 v18, v18, v23
	v_alignbit_b32 v15, v17, v5, v19
	v_cndmask_b32_e64 v15, v15, v17, s[4:5]
	v_ffbh_u32_e32 v16, v18
	v_alignbit_b32 v14, v14, v15, 30
	v_min_u32_e32 v16, 32, v16
	v_alignbit_b32 v5, v15, v5, 30
	v_xor_b32_e32 v14, v14, v23
	v_sub_u32_e32 v17, 31, v16
	v_xor_b32_e32 v5, v5, v23
	v_alignbit_b32 v18, v18, v14, v17
	v_alignbit_b32 v5, v14, v5, v17
	v_alignbit_b32 v14, v18, v5, 9
	v_ffbh_u32_e32 v15, v14
	v_min_u32_e32 v15, 32, v15
	v_lshrrev_b32_e32 v21, 29, v13
	v_not_b32_e32 v17, v15
	v_alignbit_b32 v5, v14, v5, v17
	v_lshlrev_b32_e32 v14, 31, v21
	v_or_b32_e32 v17, 0x33000000, v14
	v_add_lshl_u32 v15, v15, v16, 23
	v_lshrrev_b32_e32 v5, 9, v5
	v_sub_u32_e32 v15, v17, v15
	v_or_b32_e32 v14, 0.5, v14
	v_lshlrev_b32_e32 v16, 23, v16
	v_or_b32_e32 v5, v15, v5
	v_lshrrev_b32_e32 v15, 9, v18
	v_sub_u32_e32 v14, v14, v16
	v_or_b32_e32 v14, v15, v14
	s_mov_b32 s0, 0x3fc90fda
	v_mul_f32_e32 v15, 0x3fc90fda, v14
	v_fma_f32 v16, v14, s0, -v15
	v_fmamk_f32 v14, v14, 0x33a22168, v16
	v_fmac_f32_e32 v14, 0x3fc90fda, v5
	v_lshrrev_b32_e32 v13, 30, v13
	v_add_f32_e32 v5, v15, v14
	v_add_u32_e32 v13, v22, v13
.LBB0_44:
	s_or_saveexec_b64 s[0:1], s[6:7]
	v_and_b32_e32 v14, 0x7fffffff, v0
	v_and_b32_e32 v15, 0x7fffffff, v6
	v_and_b32_e32 v16, 0x7fffffff, v10
	v_and_b32_e32 v18, 0x7fffffff, v3
	s_xor_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_46
.Lft18:
	s_mov_b32 s2, 0x3f22f983
	v_mul_f32_e64 v5, |v3|, s2
	v_rndne_f32_e32 v5, v5
	s_mov_b32 s2, 0xbfc90fda
	v_cvt_i32_f32_e32 v13, v5
	v_fma_f32 v17, v5, s2, |v3|
	v_fmamk_f32 v17, v5, 0xb3a22168, v17
	v_fmamk_f32 v5, v5, 0xa7c234c4, v17
.LBB0_46:
	s_or_b64 exec, exec, s[0:1]
	v_mul_f32_e32 v17, v11, v11
	v_mov_b32_e32 v19, 0x3c0881c4
	v_fmamk_f32 v20, v17, 0xb94c1982, v19
	v_fmaak_f32 v20, v17, v20, 0xbe2aaa9d
	v_mul_f32_e32 v20, v17, v20
	v_fmac_f32_e32 v11, v11, v20
	v_mov_b32_e32 v20, 0xbab64f3b
	v_fmamk_f32 v22, v17, 0x37d75334, v20
	v_fmaak_f32 v22, v17, v22, 0x3d2aabf7
	v_fmaak_f32 v22, v17, v22, 0xbf000004
	v_fma_f32 v17, v17, v22, 1.0
	v_lshlrev_b32_e32 v22, 30, v12
	v_and_b32_e32 v12, 1, v12
	v_cmp_eq_u32_e32 vcc, 0, v12
	s_brev_b32 s0, 1
	s_movk_i32 s1, 0x1f8
	v_cndmask_b32_e32 v12, v17, v11, vcc
	v_xor_b32_e32 v11, 0x80000000, v11
	v_cndmask_b32_e32 v11, v11, v17, vcc
	v_and_b32_e32 v25, 0x80000000, v22
	v_bitop3_b32 v11, v11, v22, s0 bitop3:0x78
	v_mov_b32_e32 v22, 0x7fc00000
	v_cmp_class_f32_e64 vcc, v10, s1
	v_xor_b32_e32 v16, v16, v10
	v_xor_b32_e32 v12, v16, v12
	v_cndmask_b32_e32 v10, v22, v11, vcc
	v_mul_f32_e32 v11, v7, v7
	v_fmamk_f32 v16, v11, 0xb94c1982, v19
	v_fmaak_f32 v16, v11, v16, 0xbe2aaa9d
	v_mul_f32_e32 v16, v11, v16
	v_fmac_f32_e32 v7, v7, v16
	v_fmamk_f32 v16, v11, 0x37d75334, v20
	v_fmaak_f32 v16, v11, v16, 0x3d2aabf7
	v_fmaak_f32 v16, v11, v16, 0xbf000004
	v_xor_b32_e32 v12, v12, v25
	v_fma_f32 v11, v11, v16, 1.0
	v_lshlrev_b32_e32 v16, 30, v9
	v_and_b32_e32 v9, 1, v9
	v_cndmask_b32_e32 v12, v22, v12, vcc
	v_cmp_eq_u32_e32 vcc, 0, v9
	v_xor_b32_e32 v15, v15, v6
	v_and_b32_e32 v17, 0x80000000, v16
	v_cndmask_b32_e32 v9, v11, v7, vcc
	v_xor_b32_e32 v7, 0x80000000, v7
	v_cndmask_b32_e32 v7, v7, v11, vcc
	v_bitop3_b32 v7, v7, v16, s0 bitop3:0x78
	v_cmp_class_f32_e64 vcc, v6, s1
	v_mul_f32_e32 v6, v1, v1
	v_xor_b32_e32 v9, v15, v9
	v_cndmask_b32_e32 v15, v22, v7, vcc
	v_fmamk_f32 v7, v6, 0xb94c1982, v19
	v_fmaak_f32 v7, v6, v7, 0xbe2aaa9d
	v_mul_f32_e32 v7, v6, v7
	v_fmac_f32_e32 v1, v1, v7
	v_fmamk_f32 v7, v6, 0x37d75334, v20
	v_fmaak_f32 v7, v6, v7, 0x3d2aabf7
	v_fmaak_f32 v7, v6, v7, 0xbf000004
	v_xor_b32_e32 v9, v9, v17
	v_fma_f32 v6, v6, v7, 1.0
	v_lshlrev_b32_e32 v7, 30, v2
	v_and_b32_e32 v2, 1, v2
	v_cndmask_b32_e32 v17, v22, v9, vcc
	v_cmp_eq_u32_e32 vcc, 0, v2
	v_xor_b32_e32 v11, v14, v0
	v_mov_b32_e32 v21, 0xbe2aaa9d
	v_cndmask_b32_e32 v2, v6, v1, vcc
	v_xor_b32_e32 v1, 0x80000000, v1
	v_cndmask_b32_e32 v1, v1, v6, vcc
	v_cmp_class_f32_e64 vcc, v0, s1
	v_mul_f32_e32 v0, v5, v5
	v_mov_b32_e32 v23, 0x3d2aabf7
	v_fmac_f32_e32 v19, 0xb94c1982, v0
	v_fmac_f32_e32 v20, 0x37d75334, v0
	v_mov_b32_e32 v24, 0xbf000004
	v_and_b32_e32 v9, 0x80000000, v7
	v_xor_b32_e32 v2, v11, v2
	v_bitop3_b32 v1, v1, v7, s0 bitop3:0x78
	v_fmac_f32_e32 v21, v0, v19
	v_fmac_f32_e32 v23, v0, v20
	v_xor_b32_e32 v2, v2, v9
	v_cndmask_b32_e32 v14, v22, v1, vcc
	v_mul_f32_e32 v1, v0, v21
	v_fmac_f32_e32 v24, v0, v23
	v_and_b32_e32 v6, 1, v13
	v_cndmask_b32_e32 v16, v22, v2, vcc
	v_fmac_f32_e32 v5, v5, v1
	v_fma_f32 v0, v0, v24, 1.0
	v_cmp_eq_u32_e32 vcc, 0, v6
	v_lshlrev_b32_e32 v1, 30, v13
	v_xor_b32_e32 v7, v18, v3
	v_cndmask_b32_e32 v6, v0, v5, vcc
	v_xor_b32_e32 v5, 0x80000000, v5
	v_and_b32_e32 v2, 0x80000000, v1
	v_xor_b32_e32 v6, v7, v6
	v_cndmask_b32_e32 v0, v5, v0, vcc
	v_xor_b32_e32 v2, v6, v2
	v_bitop3_b32 v0, v0, v1, s0 bitop3:0x78
	v_cmp_class_f32_e64 vcc, v3, s1
	s_cmp_gt_u32 s54, 3
	s_mov_b64 s[0:1], -1
	v_cndmask_b32_e32 v11, v22, v0, vcc
	v_cndmask_b32_e32 v13, v22, v2, vcc
	s_cbranch_scc1 .LBB0_51
.Lft19:
	s_cmp_eq_u32 s38, s33
	s_cbranch_scc1 .LBB0_50
.Lft20:
	v_mov_b32_e32 v1, 0
	s_mov_b32 s0, 0
	v_lshlrev_b32_e32 v0, 2, v4
.LBB0_49:
	s_add_i32 s1, s0, s33
	s_sub_i32 s2, s1, s37
	s_min_u32 s6, s1, s2
	s_cmp_lt_u32 s1, s37
	s_cselect_b32 s2, s24, s26
	s_cselect_b32 s3, s8, s12
	v_mov_b32_e32 v2, s2
	v_mad_u64_u32 v[6:7], s[2:3], s3, v8, 0
	s_cselect_b32 s1, s25, s27
	s_cselect_b32 s4, s9, s13
	s_cselect_b32 s5, s10, s14
	v_mov_b32_e32 v18, v7
	s_cselect_b32 s7, s11, s15
	v_mov_b32_e32 v3, s1
	s_mul_hi_u32 s1, s5, s6
	s_mul_i32 s2, s5, s6
	v_mad_u64_u32 v[18:19], s[4:5], s4, v8, v[18:19]
	s_mul_i32 s7, s7, s6
	v_mov_b32_e32 v7, v18
	s_cselect_b32 s34, s29, s31
	s_cselect_b32 s35, s28, s30
	s_cselect_b32 s38, s17, s21
	s_cselect_b32 s39, s16, s20
	s_cselect_b32 s40, s18, s22
	s_cselect_b32 s41, s19, s23
	s_add_i32 s3, s1, s7
	v_lshl_add_u64 v[2:3], v[6:7], 2, v[2:3]
	v_lshl_add_u64 v[2:3], s[2:3], 2, v[2:3]
	v_lshl_add_u64 v[2:3], v[2:3], 0, v[0:1]
	global_load_dwordx4 v[18:21], v[2:3], off offset:256
	global_load_dwordx4 v[22:25], v[2:3], off
	v_mad_u64_u32 v[6:7], s[2:3], s39, v8, 0
	v_mov_b32_e32 v26, v7
	v_mad_u64_u32 v[26:27], s[4:5], s38, v8, v[26:27]
	v_mov_b32_e32 v2, s35
	v_mov_b32_e32 v3, s34
	s_mul_i32 s41, s41, s6
	s_mul_hi_u32 s1, s40, s6
	v_mov_b32_e32 v7, v26
	s_mul_i32 s2, s40, s6
	s_add_i32 s3, s1, s41
	v_lshl_add_u64 v[2:3], v[6:7], 2, v[2:3]
	s_add_i32 s0, s0, 1
	v_lshl_add_u64 v[2:3], s[2:3], 2, v[2:3]
	s_cmp_eq_u32 s0, s36
	v_lshl_add_u64 v[2:3], v[2:3], 0, v[0:1]
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[6:7], v[16:17], v[18:19]
	v_pk_mul_f32 v[26:27], v[12:13], v[20:21]
	v_pk_mul_f32 v[28:29], v[14:15], v[18:19]
	v_pk_mul_f32 v[30:31], v[10:11], v[20:21]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[18:19], v[14:15], v[22:23], v[6:7] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[20:21], v[10:11], v[24:25], v[26:27] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[22:23], v[16:17], v[22:23], v[28:29]
	v_pk_fma_f32 v[24:25], v[12:13], v[24:25], v[30:31]
	global_store_dwordx4 v[2:3], v[18:21], off
	global_store_dwordx4 v[2:3], v[22:25], off offset:256
	s_cbranch_scc0 .LBB0_49
.LBB0_50:
	s_mov_b64 s[0:1], 0
.LBB0_51:
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_53
.Lft21:
	s_sub_i32 s0, s33, s37
	s_min_u32 s0, s33, s0
	s_cmp_lt_u32 s33, s37
	s_cselect_b32 s2, s24, s26
	v_mov_b32_e32 v0, s2
	s_cselect_b32 s2, s8, s12
	s_cselect_b32 s1, s25, s27
	v_mad_u64_u32 v[2:3], s[2:3], s2, v8, 0
	v_mov_b32_e32 v1, s1
	s_cselect_b32 s1, s9, s13
	v_mov_b32_e32 v6, v3
	v_mad_u64_u32 v[6:7], s[2:3], s1, v8, v[6:7]
	s_cselect_b32 s1, s10, s14
	s_cselect_b32 s2, s11, s15
	s_mul_i32 s3, s2, s0
	s_mul_hi_u32 s5, s1, s0
	s_cselect_b32 s6, s29, s31
	s_cselect_b32 s7, s28, s30
	s_cselect_b32 s4, s17, s21
	s_cselect_b32 s34, s16, s20
	s_cselect_b32 s2, s18, s22
	s_cselect_b32 s35, s19, s23
	s_add_i32 s39, s5, s3
	s_or_b32 s3, s33, 1
	s_mul_i32 s38, s1, s0
	s_mul_i32 s35, s35, s0
	s_mul_hi_u32 s1, s2, s0
	s_sub_i32 s5, s3, s37
	v_mov_b32_e32 v3, v6
	s_add_i32 s1, s1, s35
	s_min_u32 s35, s3, s5
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	s_cmp_lt_u32 s3, s37
	v_lshl_add_u64 v[0:1], s[38:39], 2, v[0:1]
	v_lshlrev_b32_e32 v18, 2, v4
	v_mov_b32_e32 v19, 0
	s_cselect_b32 s5, s24, s26
	v_lshl_add_u64 v[20:21], v[0:1], 0, v[18:19]
	v_mov_b32_e32 v0, s5
	s_cselect_b32 s5, s8, s12
	s_cselect_b32 s3, s25, s27
	v_mad_u64_u32 v[2:3], s[38:39], s5, v8, 0
	v_mov_b32_e32 v1, s3
	s_cselect_b32 s3, s9, s13
	v_mov_b32_e32 v4, v3
	v_mad_u64_u32 v[4:5], s[38:39], s3, v8, v[4:5]
	s_cselect_b32 s3, s10, s14
	s_cselect_b32 s5, s11, s15
	v_mov_b32_e32 v3, v4
	s_mul_i32 s5, s5, s35
	s_mul_hi_u32 s42, s3, s35
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	s_cselect_b32 s39, s29, s31
	s_cselect_b32 s40, s28, s30
	s_cselect_b32 s38, s17, s21
	s_cselect_b32 s41, s16, s20
	s_cselect_b32 s36, s18, s22
	s_cselect_b32 s44, s19, s23
	s_add_i32 s43, s42, s5
	s_mul_i32 s42, s3, s35
	s_or_b32 s5, s33, 2
	v_lshl_add_u64 v[0:1], s[42:43], 2, v[0:1]
	s_mul_i32 s44, s44, s35
	s_mul_hi_u32 s3, s36, s35
	s_sub_i32 s42, s5, s37
	s_add_i32 s3, s3, s44
	s_min_u32 s42, s5, s42
	s_cmp_lt_u32 s5, s37
	s_cselect_b32 s43, s24, s26
	v_lshl_add_u64 v[22:23], v[0:1], 0, v[18:19]
	v_mov_b32_e32 v0, s43
	s_cselect_b32 s43, s8, s12
	s_cselect_b32 s5, s25, s27
	v_mad_u64_u32 v[2:3], s[44:45], s43, v8, 0
	v_mov_b32_e32 v1, s5
	s_cselect_b32 s5, s9, s13
	v_mov_b32_e32 v4, v3
	v_mad_u64_u32 v[4:5], s[44:45], s5, v8, v[4:5]
	s_cselect_b32 s5, s10, s14
	s_cselect_b32 s43, s11, s15
	s_mul_i32 s43, s43, s42
	s_mul_hi_u32 s44, s5, s42
	s_cselect_b32 s46, s29, s31
	s_cselect_b32 s47, s28, s30
	s_cselect_b32 s48, s17, s21
	s_cselect_b32 s49, s16, s20
	s_cselect_b32 s50, s18, s22
	s_cselect_b32 s51, s19, s23
	s_or_b32 s33, s33, 3
	s_add_i32 s45, s44, s43
	s_mul_i32 s44, s5, s42
	s_mul_i32 s51, s51, s42
	s_mul_hi_u32 s5, s50, s42
	s_sub_i32 s43, s33, s37
	v_mov_b32_e32 v3, v4
	s_add_i32 s5, s5, s51
	s_min_u32 s43, s33, s43
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	s_cmp_lt_u32 s33, s37
	v_lshl_add_u64 v[0:1], s[44:45], 2, v[0:1]
	s_cselect_b32 s8, s8, s12
	v_lshl_add_u64 v[36:37], v[0:1], 0, v[18:19]
	global_load_dwordx4 v[0:3], v[20:21], off
	global_load_dwordx4 v[4:7], v[20:21], off offset:256
	s_cselect_b32 s13, s9, s13
	v_mad_u64_u32 v[20:21], s[8:9], s8, v8, 0
	v_mov_b32_e32 v24, v21
	v_mad_u64_u32 v[24:25], s[8:9], s13, v8, v[24:25]
	s_cselect_b32 s25, s25, s27
	s_cselect_b32 s24, s24, s26
	s_cselect_b32 s8, s10, s14
	s_cselect_b32 s9, s11, s15
	v_mov_b32_e32 v32, s24
	v_mov_b32_e32 v33, s25
	v_mov_b32_e32 v21, v24
	global_load_dwordx4 v[24:27], v[22:23], off
	global_load_dwordx4 v[28:31], v[22:23], off offset:256
	s_mul_i32 s9, s9, s43
	s_mul_hi_u32 s10, s8, s43
	v_lshl_add_u64 v[38:39], v[20:21], 2, v[32:33]
	s_cselect_b32 s11, s29, s31
	s_cselect_b32 s12, s28, s30
	s_cselect_b32 s13, s17, s21
	s_cselect_b32 s14, s16, s20
	s_cselect_b32 s15, s18, s22
	s_cselect_b32 s16, s19, s23
	s_add_i32 s9, s10, s9
	s_mul_i32 s8, s8, s43
	global_load_dwordx4 v[20:23], v[36:37], off
	global_load_dwordx4 v[32:35], v[36:37], off offset:256
	v_lshl_add_u64 v[36:37], s[8:9], 2, v[38:39]
	v_lshl_add_u64 v[44:45], v[36:37], 0, v[18:19]
	global_load_dwordx4 v[36:39], v[44:45], off offset:256
	global_load_dwordx4 v[40:43], v[44:45], off
	v_mov_b32_e32 v44, s7
	v_mov_b32_e32 v45, s6
	v_mad_u64_u32 v[46:47], s[6:7], s34, v8, 0
	v_mov_b32_e32 v48, v47
	v_mad_u64_u32 v[48:49], s[6:7], s4, v8, v[48:49]
	v_mov_b32_e32 v47, v48
	v_lshl_add_u64 v[44:45], v[46:47], 2, v[44:45]
	s_mul_i32 s0, s2, s0
	v_lshl_add_u64 v[44:45], s[0:1], 2, v[44:45]
	v_mad_u64_u32 v[48:49], s[0:1], s41, v8, 0
	v_mov_b32_e32 v50, v49
	v_mad_u64_u32 v[50:51], s[0:1], s38, v8, v[50:51]
	v_mov_b32_e32 v49, v50
	v_mad_u64_u32 v[50:51], s[0:1], s49, v8, 0
	v_mov_b32_e32 v52, v51
	v_mov_b32_e32 v46, s40
	v_mov_b32_e32 v47, s39
	v_mad_u64_u32 v[52:53], s[0:1], s48, v8, v[52:53]
	v_lshl_add_u64 v[46:47], v[48:49], 2, v[46:47]
	s_mul_i32 s2, s36, s35
	v_mov_b32_e32 v51, v52
	v_mad_u64_u32 v[52:53], s[0:1], s14, v8, 0
	v_lshl_add_u64 v[48:49], s[2:3], 2, v[46:47]
	v_mov_b32_e32 v46, s47
	v_mov_b32_e32 v47, s46
	v_mov_b32_e32 v55, 0
	v_mov_b32_e32 v54, v53
	v_lshl_add_u64 v[46:47], v[50:51], 2, v[46:47]
	s_mul_i32 s4, s50, s42
	v_mad_u64_u32 v[8:9], s[0:1], s13, v8, v[54:55]
	v_lshl_add_u64 v[50:51], s[4:5], 2, v[46:47]
	v_mov_b32_e32 v46, s12
	v_mov_b32_e32 v47, s11
	v_mov_b32_e32 v53, v8
	v_lshl_add_u64 v[8:9], v[52:53], 2, v[46:47]
	v_lshl_add_u64 v[52:53], v[44:45], 0, v[18:19]
	s_mul_i32 s16, s16, s43
	s_mul_hi_u32 s0, s15, s43
	s_add_i32 s1, s0, s16
	s_mul_i32 s0, s15, s43
	v_lshl_add_u64 v[8:9], s[0:1], 2, v[8:9]
	v_lshl_add_u64 v[48:49], v[48:49], 0, v[18:19]
	v_lshl_add_u64 v[50:51], v[50:51], 0, v[18:19]
	v_lshl_add_u64 v[8:9], v[8:9], 0, v[18:19]
	s_waitcnt vmcnt(6)
	v_pk_mul_f32 v[44:45], v[16:17], v[4:5]
	v_pk_mul_f32 v[4:5], v[14:15], v[4:5]
	v_pk_fma_f32 v[44:45], v[14:15], v[0:1], v[44:45] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_mul_f32 v[46:47], v[12:13], v[6:7]
	v_pk_fma_f32 v[0:1], v[16:17], v[0:1], v[4:5]
	v_pk_mul_f32 v[4:5], v[10:11], v[6:7]
	v_pk_fma_f32 v[46:47], v[10:11], v[2:3], v[46:47] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[2:3], v[12:13], v[2:3], v[4:5]
	s_waitcnt vmcnt(4)
	v_pk_mul_f32 v[4:5], v[16:17], v[28:29]
	v_pk_mul_f32 v[28:29], v[14:15], v[28:29]
	v_pk_fma_f32 v[4:5], v[14:15], v[24:25], v[4:5] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_mul_f32 v[6:7], v[12:13], v[30:31]
	v_pk_fma_f32 v[24:25], v[16:17], v[24:25], v[28:29]
	v_pk_mul_f32 v[28:29], v[10:11], v[30:31]
	v_pk_fma_f32 v[6:7], v[10:11], v[26:27], v[6:7] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[26:27], v[12:13], v[26:27], v[28:29]
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[28:29], v[16:17], v[32:33]
	v_pk_mul_f32 v[32:33], v[14:15], v[32:33]
	v_pk_fma_f32 v[28:29], v[14:15], v[20:21], v[28:29] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_mul_f32 v[30:31], v[12:13], v[34:35]
	v_pk_fma_f32 v[20:21], v[16:17], v[20:21], v[32:33]
	v_pk_mul_f32 v[32:33], v[10:11], v[34:35]
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[18:19], v[16:17], v[36:37]
	v_pk_fma_f32 v[30:31], v[10:11], v[22:23], v[30:31] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[22:23], v[12:13], v[22:23], v[32:33]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[32:33], v[14:15], v[40:41], v[18:19] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_mul_f32 v[18:19], v[12:13], v[38:39]
	s_nop 0
	v_pk_fma_f32 v[34:35], v[10:11], v[42:43], v[18:19] neg_lo:[0,0,1] neg_hi:[0,0,1]
	global_store_dwordx4 v[52:53], v[44:47], off
	global_store_dwordx4 v[52:53], v[0:3], off offset:256
	global_store_dwordx4 v[48:49], v[4:7], off
	global_store_dwordx4 v[48:49], v[24:27], off offset:256
	global_store_dwordx4 v[50:51], v[28:31], off
	global_store_dwordx4 v[50:51], v[20:23], off offset:256
	global_store_dwordx4 v[8:9], v[32:35], off
	v_pk_mul_f32 v[0:1], v[14:15], v[36:37]
	v_pk_mul_f32 v[2:3], v[10:11], v[38:39]
	v_pk_fma_f32 v[0:1], v[16:17], v[40:41], v[0:1]
	v_pk_fma_f32 v[2:3], v[12:13], v[42:43], v[2:3]
	global_store_dwordx4 v[8:9], v[0:3], off offset:256
.LBB0_53:
	s_endpgm
.Lfunc_end0:
	.size	fi_rope, .Lfunc_end0-fi_rope
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_rope
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 392
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 1
		.amdhsa_next_free_vgpr 56
		.amdhsa_next_free_sgpr 78
		.amdhsa_accum_offset 56
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
  - .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .offset: 40
    .size: 4
    .value_kind: by_value
  - .offset: 44
    .size: 4
    .value_kind: by_value
  - .offset: 48
    .size: 4
    .value_kind: by_value
  - .offset: 52
    .size: 4
    .value_kind: by_value
  - .offset: 56
    .size: 8
    .value_kind: by_value
  - .offset: 64
    .size: 8
    .value_kind: by_value
  - .offset: 72
    .size: 8
    .value_kind: by_value
  - .offset: 80
    .size: 8
    .value_kind: by_value
  - .offset: 88
    .size: 8
    .value_kind: by_value
  - .offset: 96
    .size: 8
    .value_kind: by_value
  - .offset: 104
    .size: 8
    .value_kind: by_value
  - .offset: 112
    .size: 8
    .value_kind: by_value
  - .offset: 120
    .size: 4
    .value_kind: by_value
  - .offset: 124
    .size: 4
    .value_kind: by_value
  - .offset: 128
    .size: 4
    .value_kind: by_value
  - .offset: 132
    .size: 4
    .value_kind: by_value
  - .offset: 136
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 140
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 144
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 148
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 150
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 152
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 154
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 156
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 158
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 176
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 184
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 192
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 200
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 392
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: fi_rope
  .private_segment_fixed_size: 0
  .sgpr_count: 84
  .sgpr_spill_count: 0
  .symbol: fi_rope.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 56
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
