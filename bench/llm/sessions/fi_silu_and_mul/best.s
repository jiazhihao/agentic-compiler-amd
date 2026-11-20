	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_silu_and_mul
	.globl	fi_silu_and_mul
	.p2align	8
	.type	fi_silu_and_mul,@function
fi_silu_and_mul:
	s_load_dwordx2 s[4:5], s[0:1], 0x10
	s_waitcnt lgkmcnt(0)
	v_cvt_f32_u32_e32 v1, s5
	s_sub_i32 s3, 0, s5
	s_lshr_b32 s6, s4, 2
	v_rcp_iflag_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_nop 0
	v_readfirstlane_b32 s7, v1
	s_mul_i32 s3, s3, s7
	s_mul_hi_u32 s3, s7, s3
	s_add_i32 s7, s7, s3
	s_mul_hi_u32 s3, s2, s7
	s_mul_i32 s7, s3, s5
	s_sub_i32 s7, s2, s7
	s_add_i32 s8, s3, 1
	s_sub_i32 s9, s7, s5
	s_cmp_ge_u32 s7, s5
	s_cselect_b32 s3, s8, s3
	s_cselect_b32 s7, s9, s7
	s_add_i32 s8, s3, 1
	s_cmp_ge_u32 s7, s5
	s_cselect_b32 s3, s8, s3
	s_mul_i32 s5, s3, s5
	s_sub_i32 s2, s2, s5
	v_lshl_or_b32 v0, s2, 8, v0
	v_cmp_gt_u32_e32 vcc, s6, v0
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_2
.Lft0:
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_ashr_i32 s5, s4, 31
	s_mul_hi_u32 s0, s3, s4
	s_mul_i32 s1, s3, s5
	s_add_i32 s1, s0, s1
	s_mul_i32 s0, s3, s4
	s_lshl_b64 s[2:3], s[0:1], 3
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s10, s2
	v_mov_b32_e32 v1, 0
	s_addc_u32 s3, s11, s3
	v_lshlrev_b64 v[8:9], 4, v[0:1]
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[8:9]
	global_load_dwordx4 v[0:3], v[0:1], off
	s_lshl_b64 s[4:5], s[4:5], 2
	s_add_u32 s2, s2, s4
	s_addc_u32 s3, s3, s5
	v_lshl_add_u64 v[4:5], s[2:3], 0, v[8:9]
	global_load_dwordx4 v[4:7], v[4:5], off
	s_mov_b32 s2, 0xbfb8aa3b
	s_mov_b32 s4, 0xc2fc0000
	v_mov_b32_e32 v14, 0x42800000
	s_lshl_b64 s[6:7], s[0:1], 2
	v_not_b32_e32 v15, 63
	s_add_u32 s6, s8, s6
	s_addc_u32 s7, s9, s7
	v_lshl_add_u64 v[8:9], s[6:7], 0, v[8:9]
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[10:11], v[0:1], s[2:3] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[2:3], s[2:3] op_sel_hi:[1,0]
	v_cmp_gt_f32_e32 vcc, s4, v11
	v_cmp_gt_f32_e64 s[0:1], s4, v10
	v_cmp_gt_f32_e64 s[2:3], s4, v13
	v_cmp_gt_f32_e64 s[4:5], s4, v12
	v_cndmask_b32_e32 v16, 0, v14, vcc
	v_cndmask_b32_e64 v17, 0, v14, s[0:1]
	v_cndmask_b32_e64 v18, 0, v14, s[2:3]
	v_cndmask_b32_e64 v14, 0, v14, s[4:5]
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v10, v10, v17
	v_add_f32_e32 v13, v13, v18
	v_add_f32_e32 v12, v12, v14
	v_exp_f32_e32 v11, v11
	v_exp_f32_e32 v10, v10
	v_exp_f32_e32 v13, v13
	v_exp_f32_e32 v12, v12
	v_cndmask_b32_e32 v16, 0, v15, vcc
	v_cndmask_b32_e64 v17, 0, v15, s[0:1]
	v_cndmask_b32_e64 v18, 0, v15, s[2:3]
	v_cndmask_b32_e64 v14, 0, v15, s[4:5]
	v_ldexp_f32 v11, v11, v16
	v_ldexp_f32 v10, v10, v17
	v_ldexp_f32 v13, v13, v18
	v_ldexp_f32 v12, v12, v14
	v_pk_add_f32 v[10:11], v[10:11], 1.0 op_sel_hi:[1,0]
	v_pk_add_f32 v[12:13], v[12:13], 1.0 op_sel_hi:[1,0]
	v_rcp_f32_e32 v10, v10
	v_rcp_f32_e32 v11, v11
	v_rcp_f32_e32 v12, v12
	v_rcp_f32_e32 v13, v13
	v_pk_mul_f32 v[0:1], v[0:1], v[10:11]
	v_pk_mul_f32 v[2:3], v[2:3], v[12:13]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[0:1], v[4:5], v[0:1]
	v_pk_mul_f32 v[2:3], v[6:7], v[2:3]
	global_store_dwordx4 v[8:9], v[0:3], off
.LBB0_2:
	s_endpgm
.Lfunc_end0:
	.size	fi_silu_and_mul, .Lfunc_end0-fi_silu_and_mul
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_silu_and_mul
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
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
		.amdhsa_next_free_vgpr 19
		.amdhsa_next_free_sgpr 12
		.amdhsa_accum_offset 20
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
    .size: 4
    .value_kind: by_value
  - .offset: 20
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 24
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 256
  .name: fi_silu_and_mul
  .private_segment_fixed_size: 0
  .sgpr_count: 18
  .sgpr_spill_count: 0
  .symbol: fi_silu_and_mul.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 19
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
