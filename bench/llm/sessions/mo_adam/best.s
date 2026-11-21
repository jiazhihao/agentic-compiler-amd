	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_adam
	.globl	mo_adam
	.p2align	8
	.type	mo_adam,@function
mo_adam:
	s_load_dword s3, s[0:1], 0x7c
	s_load_dwordx2 s[28:29], s[0:1], 0x68
	s_load_dwordx16 s[4:19], s[0:1], 0x0
	s_load_dwordx8 s[20:27], s[0:1], 0x48
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, s2
	s_waitcnt lgkmcnt(0)
	s_and_b32 s3, s3, 0xffff
	v_mad_u64_u32 v[0:1], s[2:3], s3, v2, v[0:1]
	v_cmp_gt_u64_e32 vcc, s[28:29], v[0:1]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_21
.Lft0:
	v_lshlrev_b64 v[18:19], 2, v[0:1]
	v_lshl_add_u64 v[12:13], s[8:9], 0, v[18:19]
	v_lshl_add_u64 v[14:15], s[4:5], 0, v[18:19]
	v_lshl_add_u64 v[16:17], s[10:11], 0, v[18:19]
	global_load_dword v20, v[12:13], off
	global_load_dword v21, v[14:15], off
	global_load_dword v22, v[16:17], off
	v_lshl_add_u64 v[12:13], s[14:15], 0, v[18:19]
	global_load_dword v23, v[12:13], off
	v_cvt_f64_f32_e32 v[4:5], s21
	v_cvt_f64_f32_e32 v[6:7], s22
	v_mov_b64_e32 v[2:3], 1.0
	v_mov_b64_e32 v[8:9], 1.0
	s_cmp_eq_u32 s25, 0
	s_cbranch_scc1 .Lpowdone
.Lpow:
	s_bitcmp0_b32 s25, 0
	s_cbranch_scc1 .Lsq
.Lmul:
	v_mul_f64 v[2:3], v[2:3], v[4:5]
	v_mul_f64 v[8:9], v[8:9], v[6:7]
.Lsq:
	s_lshr_b32 s25, s25, 1
	s_cbranch_scc0 .Lpowdone
.Lsq2:
	v_mul_f64 v[4:5], v[4:5], v[4:5]
	v_mul_f64 v[6:7], v[6:7], v[6:7]
	s_branch .Lpow
.Lpowdone:
	v_add_f64 v[8:9], -v[8:9], 1.0
	v_cvt_f32_f64_e32 v4, v[8:9]
	v_rsq_f32_e32 v4, v4
	v_add_f64 v[2:3], v[2:3], -1.0
	v_cvt_f32_f64_e32 v2, v[2:3]
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[18:19]
	v_lshl_add_u64 v[14:15], s[12:13], 0, v[18:19]
	v_lshl_add_u64 v[16:17], s[16:17], 0, v[18:19]
	s_bitcmp1_b32 s26, 0
	s_cselect_b64 s[2:3], -1, 0
	s_bitcmp0_b32 s26, 0
	s_cbranch_scc1 .LBB0_11
.Lft4:
	v_mov_b32_e32 v12, s18
	v_mov_b32_e32 v13, s19
	v_lshl_add_u64 v[12:13], v[0:1], 2, v[12:13]
	global_load_dword v24, v[12:13], off
	s_branch .LBB0_12
.LBB0_11:
.LBB0_12:
	s_bitcmp1_b32 s26, 8
	v_cmp_lg_f32_e64 s[4:5], s23, 0
	s_cselect_b64 s[8:9], -1, 0
	s_waitcnt vmcnt(3)
	v_cndmask_b32_e64 v20, v20, -v20, s[8:9]
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccz .LBB0_18
.Lft5:
	s_bfe_u32 s4, s26, 0x10010
	s_cbranch_scc1 .LBB0_15
.Lft6:
	s_waitcnt vmcnt(2)
	v_fma_f32 v13, s23, v21, v20
	s_cbranch_execz .LBB0_16
.Lft7:
	s_branch .LBB0_17
.LBB0_15:
.LBB0_16:
	v_mov_b32_e32 v13, s20
	v_mul_f32_e32 v13, s23, v13
	s_waitcnt vmcnt(2)
	v_fma_f32 v21, -v13, v21, v21
	v_mov_b32_e32 v13, v20
.LBB0_17:
	v_mov_b32_e32 v20, v13
.LBB0_18:
	v_mul_f32_e32 v13, v20, v20
	s_waitcnt vmcnt(0)
	v_fma_f32 v23, -v20, v20, v23
	v_fmac_f32_e32 v13, s22, v23
	v_max_f32_e32 v11, v24, v13
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_20
.Lft8:
	s_load_dwordx2 s[0:1], s[0:1], 0x40
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 2, s[0:1]
	global_store_dword v[0:1], v11, off
.LBB0_20:
	v_cndmask_b32_e64 v0, v13, v11, s[2:3]
	v_sqrt_f32_e32 v5, v0
	global_store_dword v[16:17], v13, off
	v_sub_f32_e32 v1, v22, v20
	v_fmac_f32_e32 v20, s21, v1
	global_store_dword v[14:15], v20, off
	v_fma_f32 v3, v5, v4, s24
	v_mul_f32_e32 v0, v3, v2
	v_rcp_f32_e32 v0, v0
	v_mul_f32_e32 v1, s20, v20
	v_fmac_f32_e32 v21, v0, v1
	global_store_dword v[6:7], v21, off
.LBB0_21:
	s_endpgm
.Lfunc_end0:
	.size	mo_adam, .Lfunc_end0-mo_adam
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_adam
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 368
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
		.amdhsa_next_free_vgpr 25
		.amdhsa_next_free_sgpr 30
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
  - .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 40
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 48
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 56
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 64
    .size: 8
    .value_kind: global_buffer
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
  - .offset: 88
    .size: 4
    .value_kind: by_value
  - .offset: 92
    .size: 4
    .value_kind: by_value
  - .offset: 96
    .size: 1
    .value_kind: by_value
  - .offset: 97
    .size: 1
    .value_kind: by_value
  - .offset: 98
    .size: 1
    .value_kind: by_value
  - .offset: 104
    .size: 8
    .value_kind: by_value
  - .offset: 112
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 116
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 120
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 124
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 126
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 128
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 130
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 132
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 134
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 152
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 160
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 168
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 176
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 368
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mo_adam
  .private_segment_fixed_size: 0
  .sgpr_count: 36
  .sgpr_spill_count: 0
  .symbol: mo_adam.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 25
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
