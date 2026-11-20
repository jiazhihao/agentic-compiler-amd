	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	vl_rms_norm
	.globl	vl_rms_norm
	.p2align	8
	.type	vl_rms_norm,@function
vl_rms_norm:
	s_load_dwordx2 s[4:5], s[0:1], 0x10
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_load_dword s3, s[0:1], 0x50
	v_mov_b32_e32 v1, 0
	v_lshlrev_b32_e32 v10, 4, v0
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s5, s5, s2
	s_mul_hi_u32 s6, s4, s2
	s_add_i32 s5, s6, s5
	s_mul_i32 s4, s4, s2
	s_lshl_b64 s[16:17], s[4:5], 2
	s_add_u32 s18, s10, s16
	s_addc_u32 s19, s11, s17
	s_ashr_i32 s22, s3, 31
	s_lshr_b32 s4, s22, 30
	s_add_i32 s4, s3, s4
	s_ashr_i32 s24, s4, 2
	v_cmp_gt_i32_e64 s[4:5], s24, v0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_2
.Lft0:
	global_load_dwordx4 v[2:5], v10, s[18:19]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[8:9], v[2:3], v[2:3]
	v_pk_mul_f32 v[6:7], v[4:5], v[4:5]
	v_add_f32_e32 v1, v8, v9
	v_add_f32_e32 v1, v1, v6
	v_add_f32_e32 v1, v1, v7
.LBB0_2:
	s_or_b64 exec, exec, s[6:7]
	v_or_b32_e32 v6, 0x400, v0
	v_cmp_gt_i32_e64 s[6:7], s24, v6
	s_and_saveexec_b64 s[12:13], s[6:7]
	s_cbranch_execz .LBB0_6
.Lft1:
	s_add_u32 s14, s10, s16
	v_mov_b32_e32 v11, 0
	s_addc_u32 s15, s11, s17
	v_lshl_add_u64 v[8:9], s[14:15], 0, v[10:11]
	s_mov_b64 s[14:15], 0x4000
	v_lshl_add_u64 v[8:9], v[8:9], 0, s[14:15]
	s_mov_b64 s[20:21], 0
	v_mov_b32_e32 v7, v6
	.p2align	5, , 4
.LBB0_4:
	global_load_dwordx4 v[12:15], v[8:9], off
	v_add_u32_e32 v7, 0x400, v7
	v_cmp_le_i32_e32 vcc, s24, v7
	v_lshl_add_u64 v[8:9], v[8:9], 0, s[14:15]
	s_or_b64 s[20:21], vcc, s[20:21]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[12:13], v[12:13], v[12:13]
	v_pk_mul_f32 v[14:15], v[14:15], v[14:15]
	v_add_f32_e32 v1, v1, v12
	v_add_f32_e32 v1, v1, v13
	v_add_f32_e32 v1, v1, v14
	v_add_f32_e32 v1, v1, v15
	s_andn2_b64 exec, exec, s[20:21]
	s_cbranch_execnz .LBB0_4
.Lft2:
	s_or_b64 exec, exec, s[20:21]
.LBB0_6:
	s_or_b64 exec, exec, s[12:13]
	v_add_f32_dpp v1, v1, v1 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_mbcnt_lo_u32_b32 v7, -1, 0
	v_mbcnt_hi_u32_b32 v7, -1, v7
	v_add_f32_dpp v1, v1, v1 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf bound_ctrl:1
	v_bfrev_b32_e32 v8, 0.5
	v_lshl_or_b32 v7, v7, 2, v8
	v_add_f32_dpp v1, v1, v1 row_ror:4 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v1, v1, v1 row_ror:8 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v1, v1, v1 row_bcast:15 row_mask:0xf bank_mask:0xf bound_ctrl:1
	s_nop 1
	v_add_f32_dpp v1, v1, v1 row_bcast:31 row_mask:0xf bank_mask:0xf bound_ctrl:1
	ds_bpermute_b32 v1, v7, v1
	v_and_b32_e32 v7, 63, v0
	v_cmp_eq_u32_e32 vcc, 0, v7
	s_and_saveexec_b64 s[12:13], vcc
	s_cbranch_execz .LBB0_8
.Lft3:
	v_lshrrev_b32_e32 v7, 4, v0
	s_waitcnt lgkmcnt(0)
	ds_write_b32 v7, v1
.LBB0_8:
	s_or_b64 exec, exec, s[12:13]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v1, 0
	s_barrier
	ds_read_b128 v[12:15], v1
	ds_read_b128 v[16:19], v1 offset:16
	ds_read_b128 v[20:23], v1 offset:32
	ds_read_b128 v[24:27], v1 offset:48
	v_cvt_f32_i32_e32 v7, s3
	s_load_dwordx4 s[12:15], s[0:1], 0x38
	s_load_dword s23, s[0:1], 0x48
	s_mul_hi_u32 s25, s3, s2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, 0, v12
	v_add_f32_e32 v1, v1, v13
	v_add_f32_e32 v1, v1, v14
	v_add_f32_e32 v1, v1, v15
	v_add_f32_e32 v1, v1, v16
	v_add_f32_e32 v1, v1, v17
	v_add_f32_e32 v1, v1, v18
	v_add_f32_e32 v1, v1, v19
	v_add_f32_e32 v1, v1, v20
	v_add_f32_e32 v1, v1, v21
	v_add_f32_e32 v1, v1, v22
	v_add_f32_e32 v1, v1, v23
	v_add_f32_e32 v1, v1, v24
	v_add_f32_e32 v1, v1, v25
	v_add_f32_e32 v1, v1, v26
	v_add_f32_e32 v1, v1, v27
	v_div_scale_f32 v8, s[20:21], v7, v7, v1
	v_rcp_f32_e32 v9, v8
	s_mul_i32 s1, s15, s2
	s_mul_hi_u32 s15, s14, s2
	s_mul_i32 s0, s14, s2
	v_fma_f32 v11, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v11, v9
	v_div_scale_f32 v11, vcc, v1, v7, v1
	v_mul_f32_e32 v12, v11, v9
	v_fma_f32 v13, -v8, v12, v11
	v_fmac_f32_e32 v12, v13, v9
	v_fma_f32 v8, -v8, v12, v11
	v_div_fmas_f32 v8, v8, v9, v12
	v_div_fixup_f32 v1, v8, v7, v1
	s_mul_i32 s22, s22, s2
	s_mul_i32 s20, s3, s2
	v_add_f32_e32 v1, s23, v1
	s_mov_b32 s2, 0x800000
	v_mul_f32_e32 v7, 0x4b800000, v1
	v_cmp_gt_f32_e32 vcc, s2, v1
	s_add_i32 s1, s15, s1
	s_lshl_b64 s[0:1], s[0:1], 2
	v_cndmask_b32_e32 v1, v1, v7, vcc
	v_rsq_f32_e32 v1, v1
	s_add_u32 s14, s12, s0
	s_addc_u32 s15, s13, s1
	s_add_i32 s21, s25, s22
	s_lshl_b64 s[2:3], s[20:21], 2
	s_add_u32 s20, s8, s2
	v_mul_f32_e32 v7, 0x45800000, v1
	s_addc_u32 s21, s9, s3
	v_cndmask_b32_e32 v8, v1, v7, vcc
	s_and_saveexec_b64 s[22:23], s[4:5]
	s_cbranch_execz .LBB0_10
.Lft4:
	global_load_dwordx4 v[12:15], v10, s[14:15]
	v_pk_mul_f32 v[4:5], v[4:5], v[8:9] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], v[8:9] op_sel_hi:[1,0]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[4:5], v[4:5], v[14:15]
	v_pk_mul_f32 v[2:3], v[2:3], v[12:13]
	global_store_dwordx4 v10, v[2:5], s[20:21]
.LBB0_10:
	s_or_b64 exec, exec, s[22:23]
	s_and_saveexec_b64 s[4:5], s[6:7]
	s_cbranch_execz .LBB0_20
.Lft5:
	v_sub_u32_e32 v0, s24, v0
	v_add_u32_e32 v0, 0xfffffbff, v0
	v_lshrrev_b32_e32 v0, 10, v0
	v_cmp_ne_u32_e32 vcc, 0, v0
	s_mov_b64 s[6:7], 0
	s_and_saveexec_b64 s[4:5], vcc
	s_xor_b64 s[4:5], exec, s[4:5]
	s_cbranch_execnz .LBB0_14
.Lft6:
	s_andn2_saveexec_b64 s[4:5], s[4:5]
	s_cbranch_execnz .LBB0_17
.LBB0_13:
	s_or_b64 exec, exec, s[4:5]
	s_and_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_18
.Lft7:
	s_branch .LBB0_20
.LBB0_14:
	v_add_u32_e32 v4, 1, v0
	v_and_b32_e32 v5, 0x7ffffe, v4
	v_add_u32_e32 v7, 0x400, v6
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v9, v5
	v_mov_b64_e32 v[2:3], v[6:7]
.LBB0_15:
	v_mov_b32_e32 v0, v2
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v11, v1
	v_lshlrev_b64 v[18:19], 4, v[0:1]
	v_lshlrev_b64 v[20:21], 4, v[10:11]
	v_lshl_add_u64 v[22:23], s[18:19], 0, v[18:19]
	v_lshl_add_u64 v[24:25], s[18:19], 0, v[20:21]
	v_lshl_add_u64 v[26:27], s[14:15], 0, v[18:19]
	v_lshl_add_u64 v[28:29], s[14:15], 0, v[20:21]
	global_load_dwordx4 v[30:33], v[22:23], off
	global_load_dwordx4 v[10:13], v[24:25], off
	global_load_dwordx4 v[34:37], v[26:27], off
	global_load_dwordx4 v[14:17], v[28:29], off
	v_add_u32_e32 v9, -2, v9
	v_cmp_eq_u32_e32 vcc, 0, v9
	v_add_u32_e32 v3, 0x800, v3
	v_add_u32_e32 v2, 0x800, v2
	v_lshl_add_u64 v[18:19], s[20:21], 0, v[18:19]
	s_or_b64 s[6:7], vcc, s[6:7]
	v_lshl_add_u64 v[20:21], s[20:21], 0, v[20:21]
	s_waitcnt vmcnt(3)
	v_mov_b32_e32 v22, v30
	s_waitcnt vmcnt(2)
	v_mov_b32_e32 v23, v10
	v_mov_b32_e32 v10, v31
	v_mov_b32_e32 v24, v32
	v_mov_b32_e32 v25, v12
	v_mov_b32_e32 v12, v33
	s_waitcnt vmcnt(1)
	v_mov_b32_e32 v26, v34
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v27, v14
	v_mov_b32_e32 v14, v35
	v_mov_b32_e32 v28, v36
	v_mov_b32_e32 v29, v16
	v_mov_b32_e32 v16, v37
	v_pk_mul_f32 v[22:23], v[8:9], v[22:23] op_sel_hi:[0,1]
	v_pk_mul_f32 v[10:11], v[8:9], v[10:11] op_sel_hi:[0,1]
	v_pk_mul_f32 v[24:25], v[8:9], v[24:25] op_sel_hi:[0,1]
	v_pk_mul_f32 v[12:13], v[8:9], v[12:13] op_sel_hi:[0,1]
	v_pk_mul_f32 v[22:23], v[22:23], v[26:27]
	v_pk_mul_f32 v[10:11], v[10:11], v[14:15]
	v_pk_mul_f32 v[24:25], v[24:25], v[28:29]
	v_pk_mul_f32 v[12:13], v[12:13], v[16:17]
	v_mov_b32_e32 v14, v22
	v_mov_b32_e32 v15, v10
	v_mov_b32_e32 v16, v24
	v_mov_b32_e32 v17, v12
	v_mov_b32_e32 v10, v23
	v_mov_b32_e32 v12, v25
	global_store_dwordx4 v[18:19], v[14:17], off
	global_store_dwordx4 v[20:21], v[10:13], off
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_15
.Lft8:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_ne_u32_e32 vcc, v4, v5
	v_lshl_or_b32 v6, v5, 10, v6
	s_and_b64 s[6:7], vcc, exec
	s_andn2_saveexec_b64 s[4:5], s[4:5]
	s_cbranch_execz .LBB0_13
.LBB0_17:
	s_or_b64 s[6:7], s[6:7], exec
	s_or_b64 exec, exec, s[4:5]
	s_and_b64 exec, exec, s[6:7]
	s_cbranch_execz .LBB0_20
.LBB0_18:
	v_mov_b32_e32 v7, 0
	s_add_u32 s2, s8, s2
	v_lshlrev_b64 v[4:5], 4, v[6:7]
	s_addc_u32 s3, s9, s3
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[4:5]
	s_add_u32 s2, s10, s16
	s_addc_u32 s3, s11, s17
	s_add_u32 s0, s12, s0
	s_addc_u32 s1, s13, s1
	v_lshl_add_u64 v[2:3], s[2:3], 0, v[4:5]
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[4:5]
	v_mov_b32_e32 v9, v8
	v_lshl_add_u64 v[2:3], v[2:3], 0, 8
	v_lshl_add_u64 v[4:5], v[4:5], 0, 8
	s_mov_b64 s[0:1], 0
	s_mov_b64 s[2:3], 0x4000
	.p2align	5, , 4
.LBB0_19:
	global_load_dwordx4 v[10:13], v[2:3], off offset:-8
	global_load_dwordx4 v[14:17], v[4:5], off offset:-8
	v_add_u32_e32 v6, 0x400, v6
	v_cmp_le_i32_e32 vcc, s24, v6
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[2:3]
	s_or_b64 s[0:1], vcc, s[0:1]
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[10:11], v[8:9], v[10:11]
	v_pk_mul_f32 v[12:13], v[8:9], v[12:13]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[10:11], v[10:11], v[14:15]
	v_pk_mul_f32 v[12:13], v[12:13], v[16:17]
	global_store_dwordx4 v[0:1], v[10:13], off
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[2:3]
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB0_19
.LBB0_20:
	s_endpgm
.Lfunc_end0:
	.size	vl_rms_norm, .Lfunc_end0-vl_rms_norm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel vl_rms_norm
		.amdhsa_group_segment_fixed_size 64
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 84
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
		.amdhsa_next_free_vgpr 38
		.amdhsa_next_free_sgpr 26
		.amdhsa_accum_offset 40
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
  - .actual_access: write_only
    .address_space: global
    .offset: 0
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .offset: 16
    .size: 8
    .value_kind: by_value
  - .offset: 24
    .size: 8
    .value_kind: by_value
  - .offset: 32
    .size: 8
    .value_kind: by_value
  - .offset: 40
    .size: 8
    .value_kind: by_value
  - .offset: 48
    .size: 8
    .value_kind: by_value
  - .actual_access: read_only
    .address_space: global
    .offset: 56
    .size: 8
    .value_kind: global_buffer
  - .offset: 64
    .size: 8
    .value_kind: by_value
  - .offset: 72
    .size: 4
    .value_kind: by_value
  - .offset: 76
    .size: 4
    .value_kind: by_value
  - .offset: 80
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 64
  .kernarg_segment_align: 8
  .kernarg_segment_size: 84
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: vl_rms_norm
  .private_segment_fixed_size: 0
  .sgpr_count: 32
  .sgpr_spill_count: 0
  .symbol: vl_rms_norm.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 38
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
