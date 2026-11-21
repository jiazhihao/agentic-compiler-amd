	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	vl_fused_add_rms_norm
	.globl	vl_fused_add_rms_norm
	.p2align	8
	.type	vl_fused_add_rms_norm,@function
vl_fused_add_rms_norm:
	s_load_dwordx8 s[12:19], s[0:1], 0x0
	s_load_dword s30, s[0:1], 0x28
	s_load_dwordx2 s[4:5], s[0:1], 0x30
	v_lshlrev_b32_e32 v10, 2, v0
	v_or_b32_e32 v1, 3, v10
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s3, s15, s2
	s_mul_hi_u32 s6, s14, s2
	s_add_i32 s7, s6, s3
	s_mul_i32 s6, s14, s2
	s_lshl_b64 s[14:15], s[6:7], 2
	s_add_u32 s22, s12, s14
	s_mul_i32 s3, s5, s2
	s_mul_hi_u32 s5, s4, s2
	s_addc_u32 s23, s13, s15
	s_add_i32 s3, s5, s3
	s_mul_i32 s2, s4, s2
	s_lshl_b64 s[20:21], s[2:3], 2
	s_add_u32 s24, s16, s20
	v_cmp_le_i32_e64 s[4:5], s30, v1
	v_mov_b32_e32 v3, 0
	v_or_b32_e32 v1, 1, v10
	s_addc_u32 s25, s17, s21
	v_lshlrev_b32_e32 v2, 4, v0
	v_cmp_gt_i32_e64 s[2:3], s30, v1
	v_or_b32_e32 v1, 2, v10
	v_lshl_add_u64 v[8:9], s[22:23], 0, v[2:3]
	v_lshl_add_u64 v[6:7], s[24:25], 0, v[2:3]
	v_cmp_gt_i32_e64 s[6:7], s30, v1
	s_and_saveexec_b64 s[8:9], s[4:5]
	s_xor_b64 s[8:9], exec, s[8:9]
	s_cbranch_execz .LBB0_8
.Lft0:
	v_cmp_gt_i32_e32 vcc, s30, v10
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b64 s[10:11], vcc
	s_cbranch_execz .LBB0_7
.Lft1:
	global_load_dword v1, v[8:9], off
	global_load_dword v2, v[6:7], off
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v3, 0
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v2, v1, v2
	v_mul_f32_e32 v1, v2, v2
	global_store_dword v[6:7], v2, off
	s_and_saveexec_b64 s[26:27], s[2:3]
	s_cbranch_execz .LBB0_4
.Lft2:
	global_load_dword v3, v[8:9], off offset:4
	global_load_dword v5, v[6:7], off offset:4
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v3, v3, v5
	v_fmac_f32_e32 v1, v3, v3
	global_store_dword v[6:7], v3, off offset:4
.LBB0_4:
	s_or_b64 exec, exec, s[26:27]
	s_and_saveexec_b64 s[26:27], s[6:7]
	s_cbranch_execz .LBB0_6
.Lft3:
	global_load_dword v4, v[8:9], off offset:8
	global_load_dword v5, v[6:7], off offset:8
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v4, v4, v5
	v_fmac_f32_e32 v1, v4, v4
	global_store_dword v[6:7], v4, off offset:8
.LBB0_6:
	s_or_b64 exec, exec, s[26:27]
.LBB0_7:
	s_or_b64 exec, exec, s[10:11]
.LBB0_8:
	s_or_saveexec_b64 s[8:9], s[8:9]
	v_mov_b32_e32 v5, 0
	s_xor_b64 exec, exec, s[8:9]
	s_cbranch_execz .LBB0_10
.Lft4:
	global_load_dwordx4 v[2:5], v[8:9], off
	global_load_dwordx4 v[12:15], v[6:7], off
	s_waitcnt vmcnt(0)
	v_pk_add_f32 v[2:3], v[2:3], v[12:13]
	v_pk_add_f32 v[4:5], v[4:5], v[14:15]
	v_pk_mul_f32 v[12:13], v[2:3], v[2:3]
	global_store_dwordx4 v[6:7], v[2:5], off
	v_pk_mul_f32 v[6:7], v[4:5], v[4:5]
	v_add_f32_e32 v1, v12, v13
	v_add_f32_e32 v1, v1, v6
	v_add_f32_e32 v1, v1, v7
.LBB0_10:
	s_or_b64 exec, exec, s[8:9]
	v_or_b32_e32 v6, 0x1000, v0
	v_cmp_gt_i32_e64 s[8:9], s30, v6
	s_and_saveexec_b64 s[10:11], s[8:9]
	s_cbranch_execz .LBB0_14
.Lft5:
	s_add_u32 s26, s12, s14
	s_addc_u32 s27, s13, s15
	s_add_u32 s28, s16, s20
	v_mov_b32_e32 v11, 0
	s_addc_u32 s29, s17, s21
	v_lshl_add_u64 v[12:13], s[26:27], 0, v[10:11]
	s_mov_b64 s[26:27], 0x4000
	v_lshl_add_u64 v[14:15], s[28:29], 0, v[10:11]
	v_lshl_add_u64 v[12:13], v[12:13], 0, s[26:27]
	v_lshl_add_u64 v[14:15], v[14:15], 0, s[26:27]
	s_mov_b64 s[26:27], 0
	s_mov_b64 s[28:29], 0x1000
	v_mov_b32_e32 v7, v6
	.p2align	5, , 4
.LBB0_12:
	global_load_dword v11, v[12:13], off
	global_load_dword v16, v[14:15], off
	v_add_u32_e32 v7, 0x400, v7
	v_cmp_le_i32_e32 vcc, s30, v7
	v_lshl_add_u64 v[12:13], v[12:13], 0, s[28:29]
	s_or_b64 s[26:27], vcc, s[26:27]
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v11, v11, v16
	v_fmac_f32_e32 v1, v11, v11
	global_store_dword v[14:15], v11, off
	v_lshl_add_u64 v[14:15], v[14:15], 0, s[28:29]
	s_andn2_b64 exec, exec, s[26:27]
	s_cbranch_execnz .LBB0_12
.Lft6:
	s_or_b64 exec, exec, s[26:27]
.LBB0_14:
	s_or_b64 exec, exec, s[10:11]
	v_mbcnt_lo_u32_b32 v7, -1, 0
	v_mbcnt_hi_u32_b32 v7, -1, v7
	v_and_b32_e32 v12, 63, v7
	v_cmp_ne_u32_e32 vcc, 63, v12
	s_load_dword s10, s[0:1], 0x44
	v_and_b32_e32 v13, 0x3c0, v0
	v_addc_co_u32_e32 v11, vcc, 0, v7, vcc
	v_lshlrev_b32_e32 v11, 2, v11
	ds_bpermute_b32 v11, v11, v1
	s_waitcnt lgkmcnt(0)
	s_and_b32 s28, s10, 0xffff
	v_sub_u32_e64 v13, s28, v13 clamp
	v_add_u32_e32 v14, 1, v12
	v_cmp_gt_u32_e64 s[10:11], 62, v12
	v_add_f32_e32 v11, v1, v11
	v_cmp_lt_u32_e32 vcc, v14, v13
	v_cndmask_b32_e64 v14, 0, 2, s[10:11]
	v_add_lshl_u32 v14, v14, v7, 2
	v_cndmask_b32_e32 v11, v1, v11, vcc
	ds_bpermute_b32 v14, v14, v11
	v_add_u32_e32 v15, 2, v12
	v_cmp_lt_u32_e64 s[10:11], v15, v13
	v_add_u32_e32 v15, 4, v12
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v14, v11, v14
	v_cndmask_b32_e64 v11, v11, v14, s[10:11]
	v_cmp_gt_u32_e64 s[10:11], 60, v12
	s_nop 1
	v_cndmask_b32_e64 v14, 0, 4, s[10:11]
	v_add_lshl_u32 v14, v14, v7, 2
	ds_bpermute_b32 v14, v14, v11
	v_cmp_lt_u32_e64 s[10:11], v15, v13
	v_add_u32_e32 v15, 8, v12
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v14, v11, v14
	v_cndmask_b32_e64 v11, v11, v14, s[10:11]
	v_cmp_gt_u32_e64 s[10:11], 56, v12
	s_nop 1
	v_cndmask_b32_e64 v14, 0, 8, s[10:11]
	v_add_lshl_u32 v14, v14, v7, 2
	ds_bpermute_b32 v14, v14, v11
	v_cmp_lt_u32_e64 s[10:11], v15, v13
	v_add_u32_e32 v15, 16, v12
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v14, v11, v14
	v_cndmask_b32_e64 v11, v11, v14, s[10:11]
	v_cmp_gt_u32_e64 s[10:11], 48, v12
	v_add_u32_e32 v12, 32, v12
	s_nop 0
	v_cndmask_b32_e64 v14, 0, 16, s[10:11]
	v_add_lshl_u32 v14, v14, v7, 2
	ds_bpermute_b32 v14, v14, v11
	v_cmp_lt_u32_e64 s[10:11], v15, v13
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v14, v11, v14
	v_cndmask_b32_e64 v14, v11, v14, s[10:11]
	v_lshlrev_b32_e32 v11, 2, v7
	v_or_b32_e32 v15, 0x80, v11
	ds_bpermute_b32 v15, v15, v14
	v_cmp_lt_u32_e64 s[10:11], v12, v13
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v15, v14, v15
	v_cndmask_b32_e64 v12, v14, v15, s[10:11]
	v_cndmask_b32_e32 v1, v1, v12, vcc
	v_cmp_eq_u32_e32 vcc, 0, v7
	s_and_saveexec_b64 s[10:11], vcc
	v_lshrrev_b32_e32 v12, 4, v0
	v_and_b32_e32 v12, 60, v12
	ds_write_b32 v12, v1
	s_or_b64 exec, exec, s[10:11]
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_18
.Lft7:
	ds_read_b32 v1, v11
	v_and_b32_e32 v12, 15, v7
	v_cmp_ne_u32_e32 vcc, 15, v12
	s_add_i32 s28, s28, 63
	s_lshr_b32 s28, s28, 6
	v_addc_co_u32_e32 v13, vcc, 0, v7, vcc
	v_lshlrev_b32_e32 v13, 2, v13
	s_waitcnt lgkmcnt(0)
	ds_bpermute_b32 v13, v13, v1
	v_add_u32_e32 v14, 1, v12
	v_cmp_gt_u32_e64 s[10:11], 14, v12
	v_cmp_gt_u32_e32 vcc, s28, v14
	v_add_u32_e32 v15, 2, v12
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v13, v1, v13
	v_cndmask_b32_e64 v14, 0, 2, s[10:11]
	v_cndmask_b32_e32 v13, v1, v13, vcc
	v_add_lshl_u32 v14, v14, v7, 2
	ds_bpermute_b32 v14, v14, v13
	v_cmp_gt_u32_e64 s[10:11], s28, v15
	v_or_b32_e32 v11, 32, v11
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v14, v13, v14
	v_cndmask_b32_e64 v13, v13, v14, s[10:11]
	v_cmp_gt_u32_e64 s[10:11], 12, v12
	s_nop 1
	v_cndmask_b32_e64 v14, 0, 4, s[10:11]
	v_add_lshl_u32 v7, v14, v7, 2
	ds_bpermute_b32 v7, v7, v13
	v_add_u32_e32 v14, 4, v12
	v_cmp_gt_u32_e64 s[10:11], s28, v14
	v_add_u32_e32 v12, 8, v12
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v7
	v_cndmask_b32_e64 v7, v13, v7, s[10:11]
	ds_bpermute_b32 v11, v11, v7
	v_cmp_gt_u32_e64 s[10:11], s28, v12
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v11, v7, v11
	v_cndmask_b32_e64 v7, v7, v11, s[10:11]
	v_cndmask_b32_e32 v1, v1, v7, vcc
.LBB0_18:
	s_or_b64 exec, exec, s[26:27]
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[10:11], vcc
	s_cbranch_execz .LBB0_20
.Lft8:
	v_cvt_f32_i32_e32 v7, s30
	s_load_dword s0, s[0:1], 0x20
	s_mov_b32 s1, 0x800000
	v_div_scale_f32 v11, s[26:27], v7, v7, v1
	v_rcp_f32_e32 v12, v11
	v_div_scale_f32 v13, vcc, v1, v7, v1
	v_fma_f32 v14, -v11, v12, 1.0
	v_fmac_f32_e32 v12, v14, v12
	v_mul_f32_e32 v14, v13, v12
	v_fma_f32 v15, -v11, v14, v13
	v_fmac_f32_e32 v14, v15, v12
	v_fma_f32 v11, -v11, v14, v13
	v_div_fmas_f32 v11, v11, v12, v14
	v_div_fixup_f32 v1, v11, v7, v1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, s0, v1
	v_mul_f32_e32 v7, 0x4b800000, v1
	v_cmp_gt_f32_e32 vcc, s1, v1
	s_nop 1
	v_cndmask_b32_e32 v1, v1, v7, vcc
	v_rsq_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v7, 0x45800000, v1
	v_cndmask_b32_e32 v1, v1, v7, vcc
	v_mov_b32_e32 v7, 0
	ds_write_b32 v7, v1 offset:64
.LBB0_20:
	s_or_b64 exec, exec, s[10:11]
	v_mov_b32_e32 v15, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v12, v15 offset:64
	v_lshlrev_b32_e32 v14, 2, v10
	v_lshl_add_u64 v[14:15], s[18:19], 0, v[14:15]
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[16:17], v[2:3], v[12:13] op_sel_hi:[1,0]
	v_mul_f32_e32 v2, v4, v12
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execnz .LBB0_23
.Lft9:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execnz .LBB0_29
.LBB0_22:
	s_or_b64 exec, exec, s[0:1]
	s_and_saveexec_b64 s[0:1], s[8:9]
	s_cbranch_execnz .LBB0_30
.Lft10:
	s_branch .LBB0_37
.LBB0_23:
	v_cmp_gt_i32_e32 vcc, s30, v10
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_28
.Lft11:
	global_load_dword v1, v[14:15], off
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, v16, v1
	global_store_dword v[8:9], v1, off
	s_and_saveexec_b64 s[10:11], s[2:3]
	s_cbranch_execz .LBB0_26
.Lft12:
	global_load_dword v1, v[14:15], off offset:4
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, v17, v1
	global_store_dword v[8:9], v1, off offset:4
.LBB0_26:
	s_or_b64 exec, exec, s[10:11]
	s_and_b64 exec, exec, s[6:7]
	s_cbranch_execz .LBB0_28
.Lft13:
	global_load_dword v1, v[14:15], off offset:8
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, v2, v1
	global_store_dword v[8:9], v1, off offset:8
.LBB0_28:
	s_or_b64 exec, exec, s[4:5]
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB0_22
.LBB0_29:
	global_load_dwordx4 v[18:21], v[14:15], off
	v_mul_f32_e32 v3, v5, v12
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[14:15], v[16:17], v[18:19]
	v_pk_mul_f32 v[16:17], v[2:3], v[20:21]
	global_store_dwordx4 v[8:9], v[14:17], off
	s_or_b64 exec, exec, s[0:1]
	s_and_saveexec_b64 s[0:1], s[8:9]
	s_cbranch_execz .LBB0_37
.LBB0_30:
	v_sub_u32_e32 v0, s30, v0
	v_add_u32_e32 v0, 0xffffefff, v0
	v_lshrrev_b32_e32 v0, 10, v0
	v_cmp_ne_u32_e32 vcc, 0, v0
	s_mov_b64 s[2:3], -1
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_34
.Lft14:
	v_add_u32_e32 v4, 1, v0
	v_and_b32_e32 v5, 0x7ffffe, v4
	v_or_b32_e32 v7, 0x400, v6
	v_mov_b32_e32 v13, v12
	s_mov_b64 s[2:3], 0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v8, v5
	v_mov_b64_e32 v[2:3], v[6:7]
.LBB0_32:
	v_mov_b32_e32 v0, v2
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v11, v1
	v_lshlrev_b64 v[14:15], 2, v[0:1]
	v_lshlrev_b64 v[10:11], 2, v[10:11]
	v_lshl_add_u64 v[16:17], s[24:25], 0, v[14:15]
	v_lshl_add_u64 v[18:19], s[24:25], 0, v[10:11]
	v_lshl_add_u64 v[20:21], s[18:19], 0, v[14:15]
	v_lshl_add_u64 v[22:23], s[18:19], 0, v[10:11]
	global_load_dword v24, v[16:17], off
	global_load_dword v25, v[18:19], off
	global_load_dword v26, v[20:21], off
	global_load_dword v27, v[22:23], off
	v_add_u32_e32 v8, -2, v8
	v_cmp_eq_u32_e32 vcc, 0, v8
	v_add_u32_e32 v3, 0x800, v3
	v_add_u32_e32 v2, 0x800, v2
	v_lshl_add_u64 v[14:15], s[22:23], 0, v[14:15]
	s_or_b64 s[2:3], vcc, s[2:3]
	v_lshl_add_u64 v[10:11], s[22:23], 0, v[10:11]
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[16:17], v[12:13], v[24:25]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[16:17], v[16:17], v[26:27]
	global_store_dword v[14:15], v16, off
	global_store_dword v[10:11], v17, off
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB0_32
.Lft15:
	s_or_b64 exec, exec, s[2:3]
	v_cmp_ne_u32_e32 vcc, v4, v5
	v_lshl_add_u32 v6, v5, 10, v6
	s_orn2_b64 s[2:3], vcc, exec
.LBB0_34:
	s_or_b64 exec, exec, s[0:1]
	s_and_b64 exec, exec, s[2:3]
	s_cbranch_execz .LBB0_37
.Lft16:
	v_mov_b32_e32 v7, 0
	s_add_u32 s0, s16, s20
	v_lshlrev_b64 v[4:5], 2, v[6:7]
	s_addc_u32 s1, s17, s21
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[4:5]
	s_add_u32 s0, s12, s14
	s_addc_u32 s1, s13, s15
	v_lshl_add_u64 v[2:3], s[18:19], 0, v[4:5]
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[4:5]
	s_mov_b64 s[0:1], 0
	s_mov_b64 s[2:3], 0x1000
	.p2align	5, , 4
.LBB0_36:
	global_load_dword v7, v[0:1], off
	global_load_dword v8, v[2:3], off
	v_add_u32_e32 v6, 0x400, v6
	v_cmp_le_i32_e32 vcc, s30, v6
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[2:3]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	s_or_b64 s[0:1], vcc, s[0:1]
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v7, v12, v7
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v7, v7, v8
	global_store_dword v[4:5], v7, off
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[2:3]
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB0_36
.LBB0_37:
	s_endpgm
.Lfunc_end0:
	.size	vl_fused_add_rms_norm, .Lfunc_end0-vl_fused_add_rms_norm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel vl_fused_add_rms_norm
		.amdhsa_group_segment_fixed_size 68
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 312
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
		.amdhsa_next_free_vgpr 28
		.amdhsa_next_free_sgpr 31
		.amdhsa_accum_offset 28
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
  - .offset: 8
    .size: 8
    .value_kind: by_value
  - .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
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
    .size: 8
    .value_kind: by_value
  - .offset: 56
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 60
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 64
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 68
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 70
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 72
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 74
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 76
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 78
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 96
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 104
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 112
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 120
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 68
  .kernarg_segment_align: 8
  .kernarg_segment_size: 312
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: vl_fused_add_rms_norm
  .private_segment_fixed_size: 0
  .sgpr_count: 37
  .sgpr_spill_count: 0
  .symbol: vl_fused_add_rms_norm.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 28
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
