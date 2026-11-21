	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_silu_and_mul
	.globl	fi_silu_and_mul
	.p2align	8
	.type	fi_silu_and_mul,@function
fi_silu_and_mul:
	s_load_dword s4, s[0:1], 0x10
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	v_lshl_add_u32 v0, s2, 7, v0
	s_waitcnt lgkmcnt(0)
	s_lshr_b32 s5, s4, 1
	s_sub_u32 s5, s5, 1
	v_min_u32_e32 v0, s5, v0
.Lbody:
	s_mul_hi_u32 s1, s4, s3
	s_mul_i32 s0, s4, s3
	s_lshl_b64 s[12:13], s[0:1], 3
	s_add_u32 s10, s10, s12
	s_addc_u32 s11, s11, s13
	s_mov_b32 s5, 0
	s_lshl_b64 s[14:15], s[4:5], 2
	s_add_u32 s12, s10, s14
	s_addc_u32 s13, s11, s15
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s8, s8, s0
	s_addc_u32 s9, s9, s1
	v_lshlrev_b32_e32 v8, 3, v0
	global_load_dwordx2 v[0:1], v8, s[10:11]
	global_load_dwordx2 v[4:5], v8, s[12:13]
	s_mov_b32 s2, 0xbfb8aa3b
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v10, s2, v0
	v_mul_f32_e32 v11, s2, v1
	v_exp_f32_e32 v10, v10
	v_exp_f32_e32 v11, v11
	v_add_f32_e64 v10, 1.0, v10
	v_add_f32_e64 v11, 1.0, v11
	v_rcp_f32_e32 v10, v10
	v_rcp_f32_e32 v11, v11
	v_mul_f32_e32 v0, v0, v10
	v_mul_f32_e32 v1, v1, v11
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v0, v4, v0
	v_mul_f32_e32 v1, v5, v1
	global_store_dwordx2 v8, v[0:1], s[8:9]
.Lend:
	s_endpgm
.Lfunc_end0:
	.size	fi_silu_and_mul, .Lfunc_end0-fi_silu_and_mul
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_silu_and_mul
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 20
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
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 16
		.amdhsa_accum_offset 12
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
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 20
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 256
  .name: fi_silu_and_mul
  .private_segment_fixed_size: 0
  .sgpr_count: 22
  .sgpr_spill_count: 0
  .symbol: fi_silu_and_mul.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 12
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
