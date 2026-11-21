	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_t5_layernorm
	.globl	mo_t5_layernorm
	.p2align	8
	.type	mo_t5_layernorm,@function
mo_t5_layernorm:
	s_load_dwordx2 s[26:27], s[0:1], 0x28
	s_load_dwordx8 s[12:19], s[0:1], 0x0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v1, v9
	v_lshlrev_b32_e32 v6, 4, v0
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s3, s27, s2
	s_mul_hi_u32 s4, s26, s2
	s_add_i32 s21, s4, s3
	s_mul_i32 s20, s26, s2
	s_lshl_b64 s[24:25], s[20:21], 2
	s_add_u32 s28, s12, s24
	s_addc_u32 s29, s13, s25
	s_lshr_b64 s[10:11], s[26:27], 2
	v_cmp_gt_u64_e64 s[4:5], s[10:11], v[0:1]
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_2
.Lft0:
	global_load_dwordx4 v[2:5], v6, s[28:29]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[12:13], v[2:3], v[2:3]
	v_pk_mul_f32 v[10:11], v[4:5], v[4:5]
	v_add_f32_e32 v7, v12, v13
	v_add_f32_e32 v7, v10, v7
	v_add_f32_e32 v14, v11, v7
.LBB0_2:
	s_or_b64 exec, exec, s[6:7]
	v_add_u32_e32 v8, 0x100, v0
	s_mov_b32 s3, 0
	v_cmp_gt_u64_e64 s[6:7], s[10:11], v[8:9]
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_cbranch_execz .LBB0_6
.Lft1:
	s_add_u32 s22, s12, s24
	v_mov_b32_e32 v7, 0
	s_addc_u32 s23, s13, s25
	v_lshl_add_u64 v[10:11], s[22:23], 0, v[6:7]
	s_mov_b64 s[22:23], 0x1000
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[22:23]
	s_mov_b64 s[30:31], 0
	s_mov_b64 s[34:35], 0x100
	v_mov_b64_e32 v[12:13], v[8:9]
	.p2align	5, , 4
.LBB0_4:
	global_load_dwordx4 v[16:19], v[10:11], off
	v_lshl_add_u64 v[12:13], v[12:13], 0, s[34:35]
	v_cmp_le_u64_e32 vcc, s[10:11], v[12:13]
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[22:23]
	s_or_b64 s[30:31], vcc, s[30:31]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[16:17], v[16:17], v[16:17]
	v_pk_mul_f32 v[18:19], v[18:19], v[18:19]
	v_add_f32_e32 v7, v16, v17
	v_add_f32_e32 v7, v18, v7
	v_add_f32_e32 v7, v19, v7
	v_add_f32_e32 v14, v14, v7
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB0_4
.Lft2:
	s_or_b64 exec, exec, s[30:31]
.LBB0_6:
	s_or_b64 exec, exec, s[8:9]
	s_and_b32 s8, s26, -4
	s_mov_b32 s9, s27
	v_lshl_add_u64 v[10:11], s[8:9], 0, v[0:1]
	v_cmp_gt_u32_e32 vcc, 3, v0
	v_cmp_gt_u64_e64 s[8:9], s[26:27], v[10:11]
	s_and_b64 s[22:23], vcc, s[8:9]
	v_mov_b32_e32 v22, 0
	s_and_saveexec_b64 s[8:9], s[22:23]
	s_cbranch_execz .LBB0_8
.Lft3:
	v_lshl_add_u64 v[12:13], v[10:11], 2, s[28:29]
	global_load_dword v22, v[12:13], off
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v14, v22, v22
.LBB0_8:
	s_or_b64 exec, exec, s[8:9]
	s_movk_i32 s8, 0x80
	v_lshlrev_b32_e32 v1, 2, v0
	v_cmp_gt_u32_e32 vcc, s8, v0
	ds_write_b32 v1, v14
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_10
.Lft4:
	ds_read2st64_b32 v[12:13], v1 offset1:2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_10:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_gt_u32_e32 vcc, 64, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_12
.Lft5:
	ds_read2st64_b32 v[12:13], v1 offset1:1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_12:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_gt_u32_e32 vcc, 32, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_14
.Lft6:
	ds_read2_b32 v[12:13], v1 offset1:32
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_14:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_16
.Lft7:
	ds_read2_b32 v[12:13], v1 offset1:16
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_16:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_18
.Lft8:
	ds_read2_b32 v[12:13], v1 offset1:8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_18:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_20
.Lft9:
	ds_read2_b32 v[12:13], v1 offset1:4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_20:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_22
.Lft10:
	ds_read2_b32 v[12:13], v1 offset1:2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v7, v13, v12
	ds_write_b32 v1, v7
.LBB0_22:
	s_or_b64 exec, exec, s[8:9]
	v_cmp_eq_u32_e64 s[8:9], 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[28:29], s[8:9]
	s_cbranch_execz .LBB0_24
.Lft11:
	ds_read2_b32 v[12:13], v1 offset1:1
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v13, v12
	ds_write_b32 v1, v0
.LBB0_24:
	s_or_b64 exec, exec, s[28:29]
	s_flbit_i32_b32 s28, s27
	s_min_u32 s28, s28, 32
	s_lshl_b64 s[26:27], s[26:27], s28
	s_min_u32 s26, s26, 1
	v_mov_b32_e32 v7, 0
	s_or_b32 s26, s27, s26
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b32 v0, v7
	v_cvt_f32_u32_e32 v1, s26
	s_sub_i32 s26, 32, s28
	s_cmp_lg_u64 s[18:19], 0
	v_ldexp_f32 v1, v1, s26
	s_waitcnt lgkmcnt(0)
	v_div_scale_f32 v12, s[26:27], v1, v1, v0
	v_rcp_f32_e32 v13, v12
	s_load_dword s26, s[0:1], 0x20
	s_mov_b32 s27, 0x3fd80000
	v_fma_f32 v14, -v12, v13, 1.0
	v_fmac_f32_e32 v13, v14, v13
	v_div_scale_f32 v14, vcc, v0, v1, v0
	v_mul_f32_e32 v15, v14, v13
	v_fma_f32 v16, -v12, v15, v14
	v_fmac_f32_e32 v15, v16, v13
	v_fma_f32 v12, -v12, v15, v14
	v_div_fmas_f32 v12, v12, v13, v15
	v_div_fixup_f32 v0, v12, v1, v0
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, s26, v0
	v_cvt_f64_f32_e32 v[0:1], v0
	v_rsq_f64_e32 v[12:13], v[0:1]
	v_mov_b32_e32 v14, 0x260
	v_cmp_class_f64_e32 vcc, v[0:1], v14
	s_mov_b32 s26, 0
	s_nop 0
	v_cndmask_b32_e32 v1, v1, v13, vcc
	v_cndmask_b32_e32 v0, v0, v12, vcc
	v_mul_f64 v[0:1], v[0:1], -v[12:13]
	v_fma_f64 v[0:1], v[0:1], v[12:13], 1.0
	v_mul_f64 v[14:15], v[12:13], v[0:1]
	v_fma_f64 v[0:1], v[0:1], s[26:27], 0.5
	v_fmac_f64_e32 v[12:13], v[14:15], v[0:1]
	s_cselect_b64 s[26:27], -1, 0
	v_cvt_f32_f64_e32 v12, v[12:13]
	s_and_b64 s[26:27], s[8:9], s[26:27]
	s_and_saveexec_b64 s[8:9], s[26:27]
	s_cbranch_execz .LBB0_26
.Lft12:
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s2, s18, s2
	s_addc_u32 s3, s19, s3
	global_store_dword v7, v12, s[2:3]
.LBB0_26:
	s_or_b64 exec, exec, s[8:9]
	s_load_dword s0, s[0:1], 0x30
	s_add_u32 s2, s16, s24
	s_addc_u32 s3, s17, s25
	v_mov_b32_e32 v13, v12
	s_waitcnt lgkmcnt(0)
	s_cmp_lg_u32 s0, 4
	s_cselect_b64 s[0:1], -1, 0
	v_cndmask_b32_e64 v0, 0, 1, s[0:1]
	v_cmp_ne_u32_e64 s[0:1], 1, v0
	s_and_saveexec_b64 s[8:9], s[4:5]
	s_cbranch_execz .LBB0_30
.Lft13:
	v_mov_b32_e32 v0, v12
	v_mov_b32_e32 v1, v12
	v_pk_mul_f32 v[4:5], v[4:5], v[0:1]
	s_and_b64 vcc, exec, s[0:1]
	v_pk_mul_f32 v[2:3], v[2:3], v[12:13]
	s_cbranch_vccnz .LBB0_29
.Lft14:
	v_lshl_add_u64 v[0:1], s[14:15], 0, v[6:7]
	global_load_dwordx4 v[14:17], v[0:1], off
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[4:5], v[4:5], v[16:17]
	v_pk_mul_f32 v[2:3], v[2:3], v[14:15]
.LBB0_29:
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[6:7]
	global_store_dwordx4 v[0:1], v[2:5], off
.LBB0_30:
	s_or_b64 exec, exec, s[8:9]
	s_and_saveexec_b64 s[4:5], s[6:7]
	s_cbranch_execz .LBB0_36
.Lft15:
	v_lshl_add_u64 v[0:1], s[20:21], 2, v[6:7]
	s_mov_b64 s[6:7], 0x1000
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[6:7]
	v_lshl_add_u64 v[2:3], s[14:15], 0, v[6:7]
	v_lshl_add_u64 v[14:15], s[12:13], 0, v[0:1]
	v_lshl_add_u64 v[16:17], v[2:3], 0, s[6:7]
	v_lshl_add_u64 v[18:19], s[16:17], 0, v[0:1]
	s_mov_b64 s[8:9], 0
	v_mov_b32_e32 v20, v12
	v_mov_b32_e32 v21, v12
	s_mov_b64 s[12:13], 0x100
	s_branch .LBB0_34
	.p2align	5, , 4
.LBB0_32:
	global_load_dwordx4 v[0:3], v[16:17], off
.LBB0_33:
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[6:7], v[20:21], v[6:7]
	v_pk_mul_f32 v[4:5], v[12:13], v[4:5]
	v_lshl_add_u64 v[8:9], v[8:9], 0, s[12:13]
	v_pk_mul_f32 v[0:1], v[4:5], v[0:1]
	v_pk_mul_f32 v[2:3], v[6:7], v[2:3]
	v_cmp_le_u64_e32 vcc, s[10:11], v[8:9]
	global_store_dwordx4 v[18:19], v[0:3], off
	v_lshl_add_u64 v[14:15], v[14:15], 0, s[6:7]
	v_lshl_add_u64 v[16:17], v[16:17], 0, s[6:7]
	s_or_b64 s[8:9], vcc, s[8:9]
	v_lshl_add_u64 v[18:19], v[18:19], 0, s[6:7]
	s_andn2_b64 exec, exec, s[8:9]
	s_cbranch_execz .LBB0_36
.LBB0_34:
	global_load_dwordx4 v[4:7], v[14:15], off
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_32
.Lft16:
	v_mov_b32_e32 v0, 1.0
	v_mov_b32_e32 v1, v0
	v_mov_b32_e32 v2, v0
	v_mov_b32_e32 v3, v0
	s_branch .LBB0_33
.LBB0_36:
	s_or_b64 exec, exec, s[4:5]
	s_and_saveexec_b64 s[4:5], s[22:23]
	s_cbranch_execz .LBB0_40
.Lft17:
	s_and_b64 vcc, exec, s[0:1]
	v_mov_b32_e32 v0, 1.0
	s_cbranch_vccnz .LBB0_39
.Lft18:
	v_lshl_add_u64 v[0:1], v[10:11], 2, s[14:15]
	global_load_dword v0, v[0:1], off
.LBB0_39:
	v_mul_f32_e32 v1, v22, v12
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, v1, v0
	v_lshl_add_u64 v[0:1], v[10:11], 2, s[2:3]
	global_store_dword v[0:1], v2, off
.LBB0_40:
	s_endpgm
.Lfunc_end0:
	.size	mo_t5_layernorm, .Lfunc_end0-mo_t5_layernorm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_t5_layernorm
		.amdhsa_group_segment_fixed_size 1024
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 52
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
		.amdhsa_next_free_vgpr 23
		.amdhsa_next_free_sgpr 36
		.amdhsa_accum_offset 24
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
  - .offset: 40
    .size: 8
    .value_kind: by_value
  - .offset: 48
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 1024
  .kernarg_segment_align: 8
  .kernarg_segment_size: 52
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mo_t5_layernorm
  .private_segment_fixed_size: 0
  .sgpr_count: 42
  .sgpr_spill_count: 0
  .symbol: mo_t5_layernorm.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 23
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
