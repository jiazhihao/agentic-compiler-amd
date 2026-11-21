	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_dot
	.globl	rb_dot
	.p2align	8
	.type	rb_dot,@function
rb_dot:
	s_load_dword s12, s[0:1], 0x0
	s_load_dword s16, s[0:1], 0x28
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	v_readfirstlane_b32 s20, v0
	v_and_b32_e32 v1, 63, v0
	v_lshlrev_b32_e32 v1, 4, v1
	v_mov_b32_e32 v2, 0
	s_lshr_b32 s20, s20, 6
	s_lshl_b32 s21, s2, 9
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s14, s16, 9
	s_mul_i32 s15, s14, 3
	s_add_u32 s15, s15, s21
	s_add_u32 s15, s15, 0x200
	s_and_b32 s22, s20, 1
	s_lshl_b32 s22, s22, 8
	s_lshr_b32 s23, s20, 1
	s_mul_i32 s23, s23, s14
	s_add_u32 s22, s22, s23
	s_add_u32 s22, s22, s21
	s_mov_b32 s31, s22
	s_mov_b32 s23, 0
	s_lshl_b64 s[22:23], s[22:23], 2
	s_add_u32 s24, s4, s22
	s_addc_u32 s25, s5, s23
	s_add_u32 s26, s6, s22
	s_addc_u32 s27, s7, s23
	s_cmp_le_u32 s15, s12
	s_cbranch_scc0 .Lslow
.Lfast:
	global_load_dwordx4 v[8:11], v1, s[24:25]
	global_load_dwordx4 v[12:15], v1, s[26:27]
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, v8, v12
	v_fmac_f32_e32 v2, v9, v13
	v_fmac_f32_e32 v2, v10, v14
	v_fmac_f32_e32 v2, v11, v15
	s_branch .Lred
.Lslow:
	v_lshrrev_b32_e32 v3, 2, v1
	v_add_u32_e32 v3, s31, v3
	v_add_u32_e32 v5, 0, v3
	v_cmp_gt_u32_e32 vcc, s12, v5
	s_and_saveexec_b64 s[34:35], vcc
	global_load_dword v6, v1, s[24:25] offset:0
	global_load_dword v7, v1, s[26:27] offset:0
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, v6, v7
	s_or_b64 exec, exec, s[34:35]
	v_add_u32_e32 v5, 1, v3
	v_cmp_gt_u32_e32 vcc, s12, v5
	s_and_saveexec_b64 s[34:35], vcc
	global_load_dword v6, v1, s[24:25] offset:4
	global_load_dword v7, v1, s[26:27] offset:4
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, v6, v7
	s_or_b64 exec, exec, s[34:35]
	v_add_u32_e32 v5, 2, v3
	v_cmp_gt_u32_e32 vcc, s12, v5
	s_and_saveexec_b64 s[34:35], vcc
	global_load_dword v6, v1, s[24:25] offset:8
	global_load_dword v7, v1, s[26:27] offset:8
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, v6, v7
	s_or_b64 exec, exec, s[34:35]
	v_add_u32_e32 v5, 3, v3
	v_cmp_gt_u32_e32 vcc, s12, v5
	s_and_saveexec_b64 s[34:35], vcc
	global_load_dword v6, v1, s[24:25] offset:12
	global_load_dword v7, v1, s[26:27] offset:12
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, v6, v7
	s_or_b64 exec, exec, s[34:35]
.Lred:
	s_nop 0
	v_add_f32_dpp v3, v2, v2 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v4, v3, v3 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v3, v4, v4 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v4, v3, v3 row_mirror row_mask:0xf bank_mask:0xf
	s_nop 0
	v_readlane_b32 s22, v4, 16
	v_readlane_b32 s23, v4, 32
	v_readlane_b32 s24, v4, 48
	v_add_f32_e32 v4, s22, v4
	v_add_f32_e32 v4, s23, v4
	v_add_f32_e32 v4, s24, v4
	s_mov_b64 exec, 1
	v_lshrrev_b32_e32 v3, 4, v0
	ds_write_b32 v3, v4
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cmp_lg_u32 s20, 0
	s_cbranch_scc1 .Lend
.Lfin:
	v_mov_b32_e32 v0, 0
	ds_read_b128 v[4:7], v0
	ds_read_b128 v[8:11], v0 offset:16
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v4, v5
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v4, v7
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	s_cmp_lg_u32 s16, 1
	s_cbranch_scc1 .Lws
.Lout:
	global_store_dword v0, v4, s[10:11]
	s_endpgm
.Lws:
	s_mov_b32 s3, 0
	s_lshl_b64 s[0:1], s[2:3], 2
	s_add_u32 s0, s8, s0
	s_addc_u32 s1, s9, s1
	global_store_dword v0, v4, s[0:1]
.Lend:
	s_endpgm
.Lfunc_end0:
	.size	rb_dot, .Lfunc_end0-rb_dot
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_dot
		.amdhsa_group_segment_fixed_size 32
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 296
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
		.amdhsa_next_free_vgpr 16
		.amdhsa_next_free_sgpr 36
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
  - .offset: 0
    .size: 4
    .value_kind: by_value
  - .actual_access: read_only
    .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .offset: 40
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 44
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 48
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 52
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 54
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 56
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 58
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 60
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 62
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 80
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 88
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 96
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 104
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 32
  .kernarg_segment_align: 8
  .kernarg_segment_size: 296
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 512
  .name: rb_dot
  .private_segment_fixed_size: 0
  .sgpr_count: 42
  .sgpr_spill_count: 0
  .symbol: rb_dot.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 16
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
