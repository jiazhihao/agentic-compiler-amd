	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_rmsnorm
	.globl	fi_rmsnorm
	.p2align	8
	.type	fi_rmsnorm,@function
fi_rmsnorm:
	s_load_dword s3, s[0:1], 0x3c
	s_load_dwordx4 s[4:7], s[0:1], 0x18
	s_load_dword s22, s[0:1], 0x28
	v_and_b32_e32 v12, 0x3ff, v0
	v_bfe_u32 v4, v0, 10, 10
	s_waitcnt lgkmcnt(0)
	s_lshr_b32 s20, s3, 16
	s_lshl_b32 s3, s20, 7
	v_cvt_f32_u32_e32 v1, s3
	s_sub_i32 s12, 0, s3
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_load_dwordx2 s[14:15], s[0:1], 0x10
	s_add_i32 s0, s4, -1
	v_rcp_iflag_f32_e32 v0, v1
	v_mov_b32_e32 v1, s3
	v_add_co_u32_e64 v1, s[0:1], s0, v1
	v_mul_f32_e32 v0, 0x4f7ffffe, v0
	v_cvt_u32_f32_e32 v0, v0
	v_lshl_add_u32 v2, v4, 5, v12
	s_mov_b32 s17, 0
	v_mov_b32_e32 v5, 0
	v_readfirstlane_b32 s13, v0
	s_mul_i32 s12, s12, s13
	s_mul_hi_u32 s12, s13, s12
	s_add_i32 s13, s13, s12
	v_readfirstlane_b32 s12, v1
	s_mul_hi_u32 s13, s12, s13
	s_mul_i32 s16, s13, s3
	s_sub_i32 s12, s12, s16
	s_add_i32 s16, s13, 1
	s_sub_i32 s18, s12, s3
	s_cmp_ge_u32 s12, s3
	s_cselect_b32 s13, s16, s13
	s_cselect_b32 s12, s18, s12
	s_add_i32 s16, s13, 1
	s_cmp_ge_u32 s12, s3
	s_cselect_b32 s23, s16, s13
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v24, 0
	v_mov_b32_e32 v25, 0
	v_mov_b32_e32 v26, 0
	v_mov_b32_e32 v27, 0
	v_mov_b32_e32 v28, 0
	v_mov_b32_e32 v29, 0
	v_mov_b32_e32 v30, 0
	v_mov_b32_e32 v31, 0
	v_mov_b32_e32 v32, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v34, 0
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v36, 0
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v38, 0
	v_mov_b32_e32 v39, 0
	s_and_b64 vcc, exec, s[0:1]
	s_mul_i32 s12, s5, s2
	v_lshlrev_b32_e32 v0, 4, v2
	v_lshlrev_b32_e32 v13, 7, v4
	s_cbranch_vccnz .LBB0_5
.Lft0:
	s_mov_b32 s13, s17
	s_lshl_b64 s[18:19], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s18, s8, s18
	s_addc_u32 s19, s9, s19
	v_lshl_add_u64 v[2:3], s[18:19], 0, v[0:1]
	s_max_u32 s5, s23, 1
	v_lshl_add_u32 v1, v12, 2, v13
	v_mov_b32_e32 v5, 0
	s_cmp_gt_u32 s23, 4
	s_cbranch_scc1 .Lslow1
.Lfast1:
	s_mov_b64 s[24:25], exec
	s_mov_b32 s16, 0
	v_add_u32_e32 v6, s16, v1
	v_cmp_gt_u32_e32 vcc, s4, v6
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[6:7], s[16:17], 2, v[2:3]
	global_load_dwordx4 v[24:27], v[6:7], off
	s_mov_b64 exec, s[24:25]
	s_add_i32 s16, s16, s3
	v_add_u32_e32 v6, s16, v1
	v_cmp_gt_u32_e32 vcc, s4, v6
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[6:7], s[16:17], 2, v[2:3]
	global_load_dwordx4 v[28:31], v[6:7], off
	s_mov_b64 exec, s[24:25]
	s_add_i32 s16, s16, s3
	v_add_u32_e32 v6, s16, v1
	v_cmp_gt_u32_e32 vcc, s4, v6
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[6:7], s[16:17], 2, v[2:3]
	global_load_dwordx4 v[32:35], v[6:7], off
	s_mov_b64 exec, s[24:25]
	s_add_i32 s16, s16, s3
	v_add_u32_e32 v6, s16, v1
	v_cmp_gt_u32_e32 vcc, s4, v6
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[6:7], s[16:17], 2, v[2:3]
	global_load_dwordx4 v[36:39], v[6:7], off
	s_mov_b64 exec, s[24:25]
	s_add_i32 s16, s16, s3
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[8:9], v[26:27], v[26:27]
	v_pk_fma_f32 v[6:7], v[24:25], v[24:25], v[8:9]
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v5, v5, v6
	v_pk_mul_f32 v[8:9], v[30:31], v[30:31]
	v_pk_fma_f32 v[6:7], v[28:29], v[28:29], v[8:9]
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v5, v5, v6
	v_pk_mul_f32 v[8:9], v[34:35], v[34:35]
	v_pk_fma_f32 v[6:7], v[32:33], v[32:33], v[8:9]
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v5, v5, v6
	v_pk_mul_f32 v[8:9], v[38:39], v[38:39]
	v_pk_fma_f32 v[6:7], v[36:37], v[36:37], v[8:9]
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v5, v5, v6
	s_branch .LBB0_5
.Lslow1:
	s_mov_b32 s16, s17
	s_branch .LBB0_3
.LBB0_2:
	s_or_b64 exec, exec, s[18:19]
	s_add_i32 s5, s5, -1
	s_add_i32 s16, s16, s3
	s_cmp_eq_u32 s5, 0
	s_cbranch_scc1 .LBB0_5
.LBB0_3:
	v_add_u32_e32 v6, s16, v1
	v_cmp_gt_u32_e32 vcc, s4, v6
	s_and_saveexec_b64 s[18:19], vcc
	s_cbranch_execz .LBB0_2
.Lft1:
	v_lshl_add_u64 v[6:7], s[16:17], 2, v[2:3]
	global_load_dwordx4 v[6:9], v[6:7], off
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[8:9], v[8:9], v[8:9]
	s_nop 0
	v_pk_fma_f32 v[6:7], v[6:7], v[6:7], v[8:9]
	s_nop 0
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v5, v5, v6
	s_branch .LBB0_2
.LBB0_5:
	v_mbcnt_lo_u32_b32 v1, -1, 0
	v_mbcnt_hi_u32_b32 v6, -1, v1
	v_add_u32_e32 v1, 64, v6
	v_and_b32_e32 v8, 0xc0, v1
	v_xor_b32_e32 v1, 16, v6
	v_cmp_lt_u32_e32 vcc, v1, v8
	v_xor_b32_e32 v3, 8, v6
	v_xor_b32_e32 v7, 4, v6
	v_cndmask_b32_e32 v1, v6, v1, vcc
	v_lshlrev_b32_e32 v1, 2, v1
	ds_bpermute_b32 v2, v1, v5
	v_cmp_lt_u32_e32 vcc, v3, v8
	v_xor_b32_e32 v9, 2, v6
	v_xor_b32_e32 v10, 1, v6
	s_xor_b64 s[16:17], s[0:1], -1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v2
	v_cndmask_b32_e32 v2, v6, v3, vcc
	v_lshlrev_b32_e32 v2, 2, v2
	ds_bpermute_b32 v3, v2, v5
	v_cmp_lt_u32_e32 vcc, v7, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v3
	v_cndmask_b32_e32 v3, v6, v7, vcc
	v_lshlrev_b32_e32 v3, 2, v3
	ds_bpermute_b32 v7, v3, v5
	v_cmp_lt_u32_e32 vcc, v9, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v5, v7
	v_cndmask_b32_e32 v5, v6, v9, vcc
	v_lshlrev_b32_e32 v5, 2, v5
	ds_bpermute_b32 v9, v5, v7
	v_cmp_lt_u32_e32 vcc, v10, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v7, v9
	v_cndmask_b32_e32 v6, v6, v10, vcc
	v_lshlrev_b32_e32 v6, 2, v6
	ds_bpermute_b32 v8, v6, v7
	v_cmp_eq_u32_e32 vcc, 0, v12
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_7
.Lft2:
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v7, v8
	v_lshl_add_u32 v8, v4, 2, 0
	ds_write_b32 v8, v7
.LBB0_7:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_eq_u32_e64 s[0:1], 0, v4
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[18:19], s[0:1]
	s_cbranch_execz .LBB0_12
.Lft3:
	v_cmp_gt_u32_e64 s[0:1], s20, v12
	v_mov_b32_e32 v4, 0
	s_and_saveexec_b64 s[20:21], s[0:1]
	v_lshl_add_u32 v4, v12, 2, 0
	ds_read_b32 v4, v4
	s_or_b64 exec, exec, s[20:21]
	s_waitcnt lgkmcnt(0)
	ds_bpermute_b32 v1, v1, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v4, v1
	ds_bpermute_b32 v2, v2, v1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_bpermute_b32 v2, v3, v1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_bpermute_b32 v2, v5, v1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_bpermute_b32 v2, v6, v1
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_12
.Lft4:
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	v_mov_b32_e32 v2, 0
	ds_write_b32 v2, v1
.LBB0_12:
	s_or_b64 exec, exec, s[18:19]
	s_andn2_b64 vcc, exec, s[16:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_vccnz .LBB0_19
.Lft5:
	v_cvt_f32_u32_e32 v2, s4
	v_mov_b32_e32 v1, 0
	ds_read_b32 v3, v1
	s_mov_b32 s5, 0x800000
	v_rcp_iflag_f32_e32 v2, v2
	s_mov_b32 s13, 0
	s_lshl_b64 s[0:1], s[12:13], 2
	s_add_u32 s0, s8, s0
	s_waitcnt lgkmcnt(0)
	v_fma_f32 v2, v2, v3, s22
	v_mul_f32_e32 v3, 0x4b800000, v2
	v_cmp_gt_f32_e32 vcc, s5, v2
	s_addc_u32 s1, s9, s1
	s_mul_i32 s12, s6, s2
	v_cndmask_b32_e32 v2, v2, v3, vcc
	v_rsq_f32_e32 v2, v2
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[0:1]
	s_lshl_b64 s[0:1], s[12:13], 2
	s_add_u32 s0, s14, s0
	v_mul_f32_e32 v3, 0x45800000, v2
	v_cndmask_b32_e32 v6, v2, v3, vcc
	s_addc_u32 s1, s15, s1
	v_lshl_add_u64 v[8:9], s[10:11], 0, v[0:1]
	v_lshl_add_u64 v[10:11], s[0:1], 0, v[0:1]
	s_max_u32 s2, s23, 1
	v_mov_b32_e32 v7, v6
	s_mov_b32 s6, s7
	v_lshl_add_u32 v12, v12, 2, v13
	s_mov_b32 s12, s13
	s_cmp_gt_u32 s23, 4
	s_cbranch_scc1 .LBB0_15
.Lfast2:
	s_mov_b64 s[24:25], exec
	v_add_u32_e32 v0, s12, v12
	v_cmp_gt_u32_e32 vcc, s4, v0
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[18:19], s[12:13], 2, v[8:9]
	global_load_dwordx4 v[40:43], v[18:19], off
	v_lshl_add_u64 v[56:57], s[12:13], 2, v[10:11]
	s_mov_b64 s[26:27], exec
	s_mov_b64 exec, s[24:25]
	s_add_i32 s12, s12, s3
	v_add_u32_e32 v0, s12, v12
	v_cmp_gt_u32_e32 vcc, s4, v0
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[18:19], s[12:13], 2, v[8:9]
	global_load_dwordx4 v[44:47], v[18:19], off
	v_lshl_add_u64 v[58:59], s[12:13], 2, v[10:11]
	s_mov_b64 s[28:29], exec
	s_mov_b64 exec, s[24:25]
	s_add_i32 s12, s12, s3
	v_add_u32_e32 v0, s12, v12
	v_cmp_gt_u32_e32 vcc, s4, v0
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[18:19], s[12:13], 2, v[8:9]
	global_load_dwordx4 v[48:51], v[18:19], off
	v_lshl_add_u64 v[60:61], s[12:13], 2, v[10:11]
	s_mov_b64 s[30:31], exec
	s_mov_b64 exec, s[24:25]
	s_add_i32 s12, s12, s3
	v_add_u32_e32 v0, s12, v12
	v_cmp_gt_u32_e32 vcc, s4, v0
	s_and_b64 exec, s[24:25], vcc
	v_lshl_add_u64 v[18:19], s[12:13], 2, v[8:9]
	global_load_dwordx4 v[52:55], v[18:19], off
	v_lshl_add_u64 v[62:63], s[12:13], 2, v[10:11]
	s_mov_b64 s[32:33], exec
	s_mov_b64 exec, s[24:25]
	s_add_i32 s12, s12, s3
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[0:1], v[24:25], v[6:7]
	v_pk_mul_f32 v[2:3], v[26:27], v[6:7]
	v_pk_add_f32 v[14:15], v[40:41], s[6:7]
	v_pk_add_f32 v[16:17], v[42:43], s[6:7]
	v_pk_mul_f32 v[0:1], v[0:1], v[14:15]
	v_pk_mul_f32 v[2:3], v[2:3], v[16:17]
	s_mov_b64 exec, s[26:27]
	global_store_dwordx4 v[56:57], v[0:3], off
	s_mov_b64 exec, s[24:25]
	s_nop 0
	v_pk_mul_f32 v[0:1], v[28:29], v[6:7]
	v_pk_mul_f32 v[2:3], v[30:31], v[6:7]
	v_pk_add_f32 v[14:15], v[44:45], s[6:7]
	v_pk_add_f32 v[16:17], v[46:47], s[6:7]
	v_pk_mul_f32 v[0:1], v[0:1], v[14:15]
	v_pk_mul_f32 v[2:3], v[2:3], v[16:17]
	s_mov_b64 exec, s[28:29]
	global_store_dwordx4 v[58:59], v[0:3], off
	s_mov_b64 exec, s[24:25]
	s_nop 0
	v_pk_mul_f32 v[0:1], v[32:33], v[6:7]
	v_pk_mul_f32 v[2:3], v[34:35], v[6:7]
	v_pk_add_f32 v[14:15], v[48:49], s[6:7]
	v_pk_add_f32 v[16:17], v[50:51], s[6:7]
	v_pk_mul_f32 v[0:1], v[0:1], v[14:15]
	v_pk_mul_f32 v[2:3], v[2:3], v[16:17]
	s_mov_b64 exec, s[30:31]
	global_store_dwordx4 v[60:61], v[0:3], off
	s_mov_b64 exec, s[24:25]
	s_nop 0
	v_pk_mul_f32 v[0:1], v[36:37], v[6:7]
	v_pk_mul_f32 v[2:3], v[38:39], v[6:7]
	v_pk_add_f32 v[14:15], v[52:53], s[6:7]
	v_pk_add_f32 v[16:17], v[54:55], s[6:7]
	v_pk_mul_f32 v[0:1], v[0:1], v[14:15]
	v_pk_mul_f32 v[2:3], v[2:3], v[16:17]
	s_mov_b64 exec, s[32:33]
	global_store_dwordx4 v[62:63], v[0:3], off
	s_mov_b64 exec, s[24:25]
	s_branch .LBB0_19
.LBB0_14:
	s_or_b64 exec, exec, s[0:1]
	s_add_i32 s2, s2, -1
	s_add_i32 s12, s12, s3
	s_cmp_eq_u32 s2, 0
	s_cbranch_scc1 .LBB0_19
.LBB0_15:
	v_add_u32_e32 v0, s12, v12
	v_cmp_gt_u32_e32 vcc, s4, v0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_17
.Lft6:
	s_lshl_b64 s[8:9], s[12:13], 2
	v_lshl_add_u64 v[18:19], v[4:5], 0, s[8:9]
	v_lshl_add_u64 v[20:21], v[8:9], 0, s[8:9]
	global_load_dwordx4 v[0:3], v[18:19], off
	global_load_dwordx4 v[14:17], v[20:21], off
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[0:1], v[0:1], v[6:7]
	s_waitcnt vmcnt(0)
	v_pk_add_f32 v[14:15], v[14:15], s[6:7]
	v_pk_mul_f32 v[2:3], v[2:3], v[6:7]
	v_pk_add_f32 v[16:17], v[16:17], s[6:7]
	v_pk_mul_f32 v[0:1], v[0:1], v[14:15]
	v_pk_mul_f32 v[2:3], v[2:3], v[16:17]
.LBB0_17:
	s_or_b64 exec, exec, s[0:1]
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_14
.Lft7:
	v_lshl_add_u64 v[14:15], s[12:13], 2, v[10:11]
	global_store_dwordx4 v[14:15], v[0:3], off
	s_branch .LBB0_14
.LBB0_19:
	s_endpgm
.Lfunc_end0:
	.size	fi_rmsnorm, .Lfunc_end0-fi_rmsnorm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_rmsnorm
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 304
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
		.amdhsa_next_free_vgpr 64
		.amdhsa_next_free_sgpr 34
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
  - .offset: 24
    .size: 4
    .value_kind: by_value
  - .offset: 28
    .size: 4
    .value_kind: by_value
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
    .value_kind: hidden_block_count_x
  - .offset: 52
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 56
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 60
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 62
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 64
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 66
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 68
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 70
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 88
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 96
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 104
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 112
    .size: 2
    .value_kind: hidden_grid_dims
  - .offset: 168
    .size: 4
    .value_kind: hidden_dynamic_lds_size
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 304
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: fi_rmsnorm
  .private_segment_fixed_size: 0
  .sgpr_count: 40
  .sgpr_spill_count: 0
  .symbol: fi_rmsnorm.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 64
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
