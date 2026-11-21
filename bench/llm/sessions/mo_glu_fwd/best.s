	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_glu_fwd
	.globl	mo_glu_fwd
	.p2align	8
	.type	mo_glu_fwd,@function
mo_glu_fwd:
	s_load_dword s10, s[0:1], 0x118
	s_mov_b64 s[6:7], exec
	s_mov_b32 s11, s0
	s_mov_b32 s12, s1
	v_mov_b32_e32 v5, v0
	s_lshl_b32 s9, s2, 2
	s_mov_b32 s8, 0
	s_waitcnt lgkmcnt(0)
.Lagc_wg_head:
	s_add_u32 s2, s9, s8
	s_cmp_ge_u32 s2, s10
	s_cbranch_scc1 .Lagc_wg_exit
.Lft1:
	s_mov_b64 exec, s[6:7]
	s_mov_b32 s0, s11
	s_mov_b32 s1, s12
	v_mov_b32_e32 v0, v5
.Lagc_wg_body:
	s_load_dword s3, s[0:1], 0x24
	s_load_dwordx2 s[4:5], s[0:1], 0x10
	v_mov_b32_e32 v1, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s3, s3, 0xffff
	s_mul_i32 s2, s2, s3
	v_add_u32_e32 v0, s2, v0
	v_cmp_gt_u64_e32 vcc, s[4:5], v[0:1]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_2
.Lft0:
	s_load_dwordx4 s[0:3], s[0:1], 0x0
	s_lshl_b64 s[4:5], s[4:5], 2
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	s_waitcnt lgkmcnt(0)
	s_add_u32 s4, s0, s4
	s_addc_u32 s5, s1, s5
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
	global_load_dword v4, v[2:3], off
	v_lshl_add_u64 v[2:3], s[0:1], 0, v[0:1]
	global_load_dword v2, v[2:3], off
	s_mov_b32 s0, 0x42aeac50
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[0:1]
	s_waitcnt vmcnt(1)
	v_add_f32_e32 v3, 0xc2800000, v4
	v_cmp_lt_f32_e32 vcc, s0, v4
	s_nop 1
	v_cndmask_b32_e32 v3, v4, v3, vcc
	v_mul_f32_e32 v3, 0xbfb8aa3b, v3
	v_exp_f32_e32 v3, v3
	s_nop 0
	v_mul_f32_e32 v4, 0x114b4ea4, v3
	v_cndmask_b32_e32 v3, v3, v4, vcc
	v_add_f32_e32 v3, 1.0, v3
	v_rcp_f32_e32 v3, v3
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, v3, v2
	global_store_dword v[0:1], v2, off
.LBB0_2:
.Lagc_wg_latch:
	s_add_u32 s8, s8, 1
	s_cmp_lt_u32 s8, 4
	s_cbranch_scc1 .Lagc_wg_head
.Lagc_wg_exit:
	s_endpgm
.Lfunc_end0:
	.size	mo_glu_fwd, .Lfunc_end0-mo_glu_fwd
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_glu_fwd
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 288
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
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 13
		.amdhsa_accum_offset 8
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
  - .offset: 16
    .size: 8
    .value_kind: by_value
  - .offset: 24
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 28
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 32
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 36
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 38
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 40
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 42
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 44
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 46
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 64
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 72
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 80
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 88
    .size: 2
    .value_kind: hidden_grid_dims
  - .offset: 280
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 288
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mo_glu_fwd
  .private_segment_fixed_size: 0
  .sgpr_count: 19
  .sgpr_spill_count: 0
  .symbol: mo_glu_fwd.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 6
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
