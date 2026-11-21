	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_bn_infer
	.globl	mo_bn_infer
	.p2align	8
	.type	mo_bn_infer,@function
mo_bn_infer:
	s_load_dwordx4 s[20:23], s[0:1], 0x38
	s_waitcnt lgkmcnt(0)
	s_add_i32 s4, s21, 3
	s_lshr_b32 s21, s4, 2
	v_cvt_f32_u32_e32 v1, s21
	v_rcp_iflag_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v2, v1
	v_lshl_or_b32 v1, s2, 6, v0
	s_sub_i32 s2, 0, s21
	v_mul_lo_u32 v0, s2, v2
	v_mul_hi_u32 v0, v2, v0
	v_add_u32_e32 v0, v2, v0
	v_mul_hi_u32 v0, v1, v0
	v_mul_lo_u32 v2, v0, s21
	v_sub_u32_e32 v2, v1, v2
	v_add_u32_e32 v3, 1, v0
	v_cmp_le_u32_e32 vcc, s21, v2
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v3, vcc
	v_subrev_u32_e32 v3, s21, v2
	v_cndmask_b32_e32 v2, v2, v3, vcc
	v_add_u32_e32 v3, 1, v0
	v_cmp_le_u32_e32 vcc, s21, v2
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v3, vcc
	v_cmp_gt_u32_e32 vcc, s20, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_2
.Lft0:
	s_load_dwordx2 s[24:25], s[0:1], 0x48
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx8 s[12:19], s[0:1], 0x20
	v_mul_lo_u32 v2, v0, s21
	v_sub_u32_e32 v7, v1, v2
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[4:5], 2, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], s[8:9], 0, v[4:5]
	s_add_i32 s0, s22, -1
	global_load_dword v6, v[2:3], off
	v_lshl_add_u64 v[2:3], s[10:11], 0, v[4:5]
	s_cmp_lt_u32 s3, s22
	global_load_dword v12, v[2:3], off
	v_mul_lo_u32 v2, s24, v7
	s_cselect_b32 s0, s3, s0
	v_mul_lo_u32 v0, v0, s23
	v_lshlrev_b32_e32 v2, 2, v2
	s_mul_i32 s0, s25, s0
	v_add3_u32 v0, v0, v2, s0
	v_lshlrev_b64 v[8:9], 2, v[0:1]
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[8:9]
	global_load_dwordx4 v[0:3], v[0:1], off
	v_lshl_add_u64 v[10:11], s[12:13], 0, v[4:5]
	v_lshl_add_u64 v[4:5], s[14:15], 0, v[4:5]
	global_load_dword v10, v[10:11], off
	s_waitcnt vmcnt(1)
	v_pk_add_f32 v[0:1], v[0:1], v[6:7] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	global_load_dword v4, v[4:5], off
	v_cvt_f32_f64_e32 v5, s[16:17]
	v_add_f32_e32 v5, v12, v5
	v_rsq_f32_e64 v12, |v5|
	v_pk_add_f32 v[2:3], v[2:3], v[6:7] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_mul_f32 v[0:1], v[12:13], v[0:1] op_sel_hi:[0,1]
	v_pk_mul_f32 v[2:3], v[12:13], v[2:3] op_sel_hi:[0,1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[0:1], v[10:11], v[0:1], v[4:5] op_sel_hi:[0,1,0]
	v_pk_fma_f32 v[2:3], v[10:11], v[2:3], v[4:5] op_sel_hi:[0,1,0]
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[8:9]
	global_store_dwordx4 v[4:5], v[0:3], off
.LBB0_2:
	s_endpgm
.Lfunc_end0:
	.size	mo_bn_infer, .Lfunc_end0-mo_bn_infer
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_bn_infer
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 88
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
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 26
		.amdhsa_accum_offset 16
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
  - .actual_access: write_only
    .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 40
    .size: 8
    .value_kind: global_buffer
  - .offset: 48
    .size: 8
    .value_kind: by_value
  - .offset: 56
    .size: 4
    .value_kind: by_value
  - .offset: 60
    .size: 4
    .value_kind: by_value
  - .offset: 64
    .size: 4
    .value_kind: by_value
  - .offset: 68
    .size: 4
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
  - .offset: 84
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 88
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 64
  .name: mo_bn_infer
  .private_segment_fixed_size: 0
  .sgpr_count: 32
  .sgpr_spill_count: 0
  .symbol: mo_bn_infer.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 14
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
