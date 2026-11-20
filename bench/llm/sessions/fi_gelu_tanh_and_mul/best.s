	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_gelu_tanh_and_mul
	.globl	fi_gelu_tanh_and_mul
	.p2align	8
	.type	fi_gelu_tanh_and_mul,@function
fi_gelu_tanh_and_mul:
	s_load_dword s8, s[0:1], 0x10
	v_lshl_or_b32 v8, s2, 6, v0
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s9, s8, 31
	s_lshr_b32 s2, s9, 30
	s_add_i32 s2, s8, s2
	s_ashr_i32 s2, s2, 2
	v_cmp_gt_u32_e32 vcc, s2, v8
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_18
.Lft0:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_mul_hi_u32 s0, s3, s8
	s_mul_i32 s1, s3, s9
	s_add_i32 s1, s0, s1
	s_mul_i32 s0, s3, s8
	s_lshl_b64 s[0:1], s[0:1], 3
	s_waitcnt lgkmcnt(0)
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s7, s1
	v_mov_b32_e32 v9, 0
	v_lshl_add_u64 v[4:5], v[8:9], 4, s[0:1]
	global_load_dwordx4 v[0:3], v[4:5], off
	v_lshl_add_u64 v[4:5], s[8:9], 2, v[4:5]
	global_load_dwordx4 v[4:7], v[4:5], off
	s_mov_b32 s0, 0x3f200000
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v10, 0x3d372713, v0
	v_mul_f32_e32 v10, v0, v10
	v_fma_f32 v10, v0, v10, v0
	v_mul_f32_e32 v10, 0x3f4c422a, v10
	v_cmp_nlt_f32_e64 s[0:1], |v10|, s0
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_xor_b64 s[0:1], exec, s[6:7]
	s_cbranch_execz .LBB0_3
.Lft1:
	v_add_f32_e64 v11, |v10|, |v10|
	v_mul_f32_e32 v12, 0x3fb8aa3b, v11
	s_mov_b32 s2, 0x3fb8aa3b
	v_rndne_f32_e32 v13, v12
	v_sub_f32_e32 v14, v12, v13
	v_fma_f32 v12, v11, s2, -v12
	v_fmamk_f32 v12, v11, 0x32a5705f, v12
	v_add_f32_e32 v12, v14, v12
	v_exp_f32_e32 v12, v12
	v_cvt_i32_f32_e32 v13, v13
	s_mov_b32 s2, 0xc2ce8ed0
	v_cmp_ngt_f32_e32 vcc, s2, v11
	s_mov_b32 s2, 0x42b17218
	v_ldexp_f32 v12, v12, v13
	v_cndmask_b32_e32 v12, 0, v12, vcc
	v_mov_b32_e32 v13, 0x7f800000
	v_cmp_nlt_f32_e32 vcc, s2, v11
	s_nop 1
	v_cndmask_b32_e32 v11, v13, v12, vcc
	v_add_f32_e32 v11, 1.0, v11
	v_rcp_f32_e32 v11, v11
	s_nop 0
	v_fma_f32 v11, v11, -2.0, 1.0
.LBB0_3:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	v_mul_f32_e32 v11, v10, v10
	v_mov_b32_e32 v12, 0x3ca908c9
	v_fmac_f32_e32 v12, 0xbbbac73d, v11
	v_fmaak_f32 v12, v11, v12, 0xbd5c1c4e
	v_fmaak_f32 v12, v11, v12, 0x3e088382
	v_fmaak_f32 v12, v11, v12, 0xbeaaaa99
	v_mul_f32_e64 v12, |v10|, v12
	v_fma_f32 v11, v11, v12, |v10|
	s_or_b64 exec, exec, s[0:1]
	v_mul_f32_e32 v12, 0x3d372713, v1
	v_mul_f32_e32 v12, v1, v12
	v_fma_f32 v12, v1, v12, v1
	v_mul_f32_e32 v12, 0x3f4c422a, v12
	s_mov_b32 s0, 0x3f200000
	v_cmp_nlt_f32_e64 s[0:1], |v12|, s0
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_xor_b64 s[0:1], exec, s[6:7]
	s_cbranch_execz .LBB0_7
.Lft2:
	v_add_f32_e64 v13, |v12|, |v12|
	v_mul_f32_e32 v14, 0x3fb8aa3b, v13
	s_mov_b32 s2, 0x3fb8aa3b
	v_rndne_f32_e32 v15, v14
	v_sub_f32_e32 v16, v14, v15
	v_fma_f32 v14, v13, s2, -v14
	v_fmamk_f32 v14, v13, 0x32a5705f, v14
	v_add_f32_e32 v14, v16, v14
	v_exp_f32_e32 v14, v14
	v_cvt_i32_f32_e32 v15, v15
	s_mov_b32 s2, 0xc2ce8ed0
	v_cmp_ngt_f32_e32 vcc, s2, v13
	s_mov_b32 s2, 0x42b17218
	v_ldexp_f32 v14, v14, v15
	v_cndmask_b32_e32 v14, 0, v14, vcc
	v_mov_b32_e32 v15, 0x7f800000
	v_cmp_nlt_f32_e32 vcc, s2, v13
	s_nop 1
	v_cndmask_b32_e32 v13, v15, v14, vcc
	v_add_f32_e32 v13, 1.0, v13
	v_rcp_f32_e32 v13, v13
	s_nop 0
	v_fma_f32 v13, v13, -2.0, 1.0
.LBB0_7:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	v_mul_f32_e32 v13, v12, v12
	v_mov_b32_e32 v14, 0x3ca908c9
	v_fmac_f32_e32 v14, 0xbbbac73d, v13
	v_fmaak_f32 v14, v13, v14, 0xbd5c1c4e
	v_fmaak_f32 v14, v13, v14, 0x3e088382
	v_fmaak_f32 v14, v13, v14, 0xbeaaaa99
	v_mul_f32_e64 v14, |v12|, v14
	v_fma_f32 v13, v13, v14, |v12|
	s_or_b64 exec, exec, s[0:1]
	v_mul_f32_e32 v14, 0x3d372713, v2
	v_mul_f32_e32 v14, v2, v14
	v_fma_f32 v14, v2, v14, v2
	v_mul_f32_e32 v14, 0x3f4c422a, v14
	s_mov_b32 s0, 0x3f200000
	v_cmp_nlt_f32_e64 s[0:1], |v14|, s0
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_xor_b64 s[0:1], exec, s[6:7]
	s_cbranch_execz .LBB0_11
.Lft3:
	v_add_f32_e64 v15, |v14|, |v14|
	v_mul_f32_e32 v16, 0x3fb8aa3b, v15
	s_mov_b32 s2, 0x3fb8aa3b
	v_rndne_f32_e32 v17, v16
	v_sub_f32_e32 v18, v16, v17
	v_fma_f32 v16, v15, s2, -v16
	v_fmamk_f32 v16, v15, 0x32a5705f, v16
	v_add_f32_e32 v16, v18, v16
	v_exp_f32_e32 v16, v16
	v_cvt_i32_f32_e32 v17, v17
	s_mov_b32 s2, 0xc2ce8ed0
	v_cmp_ngt_f32_e32 vcc, s2, v15
	s_mov_b32 s2, 0x42b17218
	v_ldexp_f32 v16, v16, v17
	v_cndmask_b32_e32 v16, 0, v16, vcc
	v_mov_b32_e32 v17, 0x7f800000
	v_cmp_nlt_f32_e32 vcc, s2, v15
	s_nop 1
	v_cndmask_b32_e32 v15, v17, v16, vcc
	v_add_f32_e32 v15, 1.0, v15
	v_rcp_f32_e32 v15, v15
	s_nop 0
	v_fma_f32 v15, v15, -2.0, 1.0
.LBB0_11:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	v_mul_f32_e32 v15, v14, v14
	v_mov_b32_e32 v16, 0x3ca908c9
	v_fmac_f32_e32 v16, 0xbbbac73d, v15
	v_fmaak_f32 v16, v15, v16, 0xbd5c1c4e
	v_fmaak_f32 v16, v15, v16, 0x3e088382
	v_fmaak_f32 v16, v15, v16, 0xbeaaaa99
	v_mul_f32_e64 v16, |v14|, v16
	v_fma_f32 v15, v15, v16, |v14|
	s_or_b64 exec, exec, s[0:1]
	v_mul_f32_e32 v16, 0x3d372713, v3
	v_mul_f32_e32 v16, v3, v16
	v_fma_f32 v16, v3, v16, v3
	v_mul_f32_e32 v16, 0x3f4c422a, v16
	s_mov_b32 s0, 0x3f200000
	v_cmp_nlt_f32_e64 s[0:1], |v16|, s0
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_xor_b64 s[0:1], exec, s[6:7]
	s_cbranch_execz .LBB0_15
.Lft4:
	v_add_f32_e64 v17, |v16|, |v16|
	v_mul_f32_e32 v18, 0x3fb8aa3b, v17
	s_mov_b32 s2, 0x3fb8aa3b
	v_rndne_f32_e32 v19, v18
	v_sub_f32_e32 v20, v18, v19
	v_fma_f32 v18, v17, s2, -v18
	v_fmamk_f32 v18, v17, 0x32a5705f, v18
	v_add_f32_e32 v18, v20, v18
	v_exp_f32_e32 v18, v18
	v_cvt_i32_f32_e32 v19, v19
	s_mov_b32 s2, 0xc2ce8ed0
	v_cmp_ngt_f32_e32 vcc, s2, v17
	s_mov_b32 s2, 0x42b17218
	v_ldexp_f32 v18, v18, v19
	v_cndmask_b32_e32 v18, 0, v18, vcc
	v_mov_b32_e32 v19, 0x7f800000
	v_cmp_nlt_f32_e32 vcc, s2, v17
	s_nop 1
	v_cndmask_b32_e32 v17, v19, v18, vcc
	v_add_f32_e32 v17, 1.0, v17
	v_rcp_f32_e32 v17, v17
	s_nop 0
	v_fma_f32 v17, v17, -2.0, 1.0
.LBB0_15:
	s_or_saveexec_b64 s[0:1], s[0:1]
	v_lshlrev_b64 v[8:9], 2, v[8:9]
	s_xor_b64 exec, exec, s[0:1]
	v_mul_f32_e32 v17, v16, v16
	v_mov_b32_e32 v18, 0x3ca908c9
	v_fmac_f32_e32 v18, 0xbbbac73d, v17
	v_fmaak_f32 v18, v17, v18, 0xbd5c1c4e
	v_fmaak_f32 v18, v17, v18, 0x3e088382
	v_fmaak_f32 v18, v17, v18, 0xbeaaaa99
	v_mul_f32_e64 v18, |v16|, v18
	v_fma_f32 v17, v17, v18, |v16|
	s_or_b64 exec, exec, s[0:1]
	s_brev_b32 s2, -2
	v_bfi_b32 v14, s2, v15, v14
	v_add_f32_e32 v14, 1.0, v14
	v_mul_f32_e32 v14, 0.5, v14
	v_mul_f32_e32 v2, v2, v14
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, v6, v2
	v_bfi_b32 v6, s2, v13, v12
	v_add_f32_e32 v6, 1.0, v6
	v_mul_f32_e32 v6, 0.5, v6
	v_mul_f32_e32 v1, v1, v6
	s_mul_i32 s0, s9, s3
	s_mul_hi_u32 s1, s8, s3
	v_mul_f32_e32 v1, v5, v1
	v_bfi_b32 v5, s2, v11, v10
	s_add_i32 s1, s1, s0
	s_mul_i32 s0, s8, s3
	v_bfi_b32 v6, s2, v17, v16
	v_add_f32_e32 v5, 1.0, v5
	s_lshl_b64 s[0:1], s[0:1], 2
	v_add_f32_e32 v6, 1.0, v6
	v_mul_f32_e32 v5, 0.5, v5
	s_add_u32 s0, s4, s0
	v_mul_f32_e32 v6, 0.5, v6
	v_mul_f32_e32 v0, v0, v5
	s_addc_u32 s1, s5, s1
	v_mul_f32_e32 v3, v3, v6
	v_mul_f32_e32 v0, v4, v0
	v_lshl_add_u64 v[4:5], v[8:9], 2, s[0:1]
	v_mul_f32_e32 v3, v7, v3
	global_store_dwordx4 v[4:5], v[0:3], off
.LBB0_18:
	s_endpgm
.Lfunc_end0:
	.size	fi_gelu_tanh_and_mul, .Lfunc_end0-fi_gelu_tanh_and_mul
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_gelu_tanh_and_mul
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
		.amdhsa_next_free_vgpr 21
		.amdhsa_next_free_sgpr 10
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
  .max_flat_workgroup_size: 64
  .name: fi_gelu_tanh_and_mul
  .private_segment_fixed_size: 0
  .sgpr_count: 16
  .sgpr_spill_count: 0
  .symbol: fi_gelu_tanh_and_mul.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 21
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
