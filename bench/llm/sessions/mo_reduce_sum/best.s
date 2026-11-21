	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_reduce_sum
	.globl	mo_reduce_sum
	.p2align	8
	.type	mo_reduce_sum,@function
mo_reduce_sum:
	s_load_dword s3, s[0:1], 0x24
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[8:9], s[0:1], 0x10
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, s2
	s_waitcnt lgkmcnt(0)
	s_and_b32 s0, s3, 0xffff
	v_mad_u64_u32 v[4:5], s[0:1], s0, v2, v[0:1]
	v_lshrrev_b64 v[0:1], 6, v[4:5]
	v_lshlrev_b64 v[2:3], 8, v[0:1]
	v_lshlrev_b32_e32 v5, 2, v4
	s_movk_i32 s0, 0xfc
	v_and_or_b32 v8, v5, s0, v2
	v_mov_b32_e32 v9, v3
	v_lshl_add_u64 v[6:7], v[8:9], 0, 4
	v_cmp_ge_u64_e32 vcc, s[8:9], v[6:7]
	v_lshl_add_u64 v[6:7], v[8:9], 2, s[4:5]
	s_and_saveexec_b64 s[0:1], vcc
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB0_2
.Lft0:
	global_load_dwordx4 v[6:9], v[6:7], off
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v5, v6, v7
	v_add_f32_e32 v6, v8, v9
	v_add_f32_e32 v5, v5, v6
.LBB0_2:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB0_12
.Lft1:
	v_cmp_gt_u64_e32 vcc, s[8:9], v[8:9]
	v_mov_b32_e32 v5, 0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_5
.Lft2:
	global_load_dword v5, v[6:7], off
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v5, 0, v5
.LBB0_5:
	s_or_b64 exec, exec, s[2:3]
	v_or_b32_e32 v10, 1, v8
	v_mov_b32_e32 v11, v9
	v_cmp_gt_u64_e32 vcc, s[8:9], v[10:11]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_7
.Lft3:
	global_load_dword v10, v[6:7], off offset:4
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v5, v5, v10
.LBB0_7:
	s_or_b64 exec, exec, s[2:3]
	v_or_b32_e32 v10, 2, v8
	v_mov_b32_e32 v11, v9
	v_cmp_gt_u64_e32 vcc, s[8:9], v[10:11]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_9
.Lft4:
	global_load_dword v10, v[6:7], off offset:8
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v5, v5, v10
.LBB0_9:
	s_or_b64 exec, exec, s[2:3]
	v_or_b32_e32 v8, 3, v8
	v_cmp_gt_u64_e32 vcc, s[8:9], v[8:9]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_11
.Lft5:
	global_load_dword v6, v[6:7], off offset:12
	s_waitcnt vmcnt(0)
	v_add_f32_e32 v5, v5, v6
.LBB0_11:
	s_or_b64 exec, exec, s[2:3]
.LBB0_12:
	s_or_b64 exec, exec, s[0:1]
	v_mbcnt_lo_u32_b32 v6, -1, 0
	v_mbcnt_hi_u32_b32 v6, -1, v6
	v_mov_b32_e32 v7, 0x80
	v_lshl_or_b32 v7, v6, 2, v7
	ds_bpermute_b32 v7, v7, v5
	v_and_b32_e32 v8, 63, v6
	v_cmp_gt_u32_e32 vcc, 48, v8
	v_cmp_gt_u64_e64 s[0:1], s[8:9], v[2:3]
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v7
	v_cndmask_b32_e64 v9, 0, 16, vcc
	v_add_lshl_u32 v7, v9, v6, 2
	ds_bpermute_b32 v7, v7, v5
	v_cmp_gt_u32_e32 vcc, 56, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v7
	v_cndmask_b32_e64 v9, 0, 8, vcc
	v_add_lshl_u32 v9, v9, v6, 2
	ds_bpermute_b32 v7, v9, v5
	v_cmp_gt_u32_e32 vcc, 60, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v7
	v_cndmask_b32_e64 v9, 0, 4, vcc
	v_add_lshl_u32 v9, v9, v6, 2
	ds_bpermute_b32 v7, v9, v5
	v_cmp_gt_u32_e32 vcc, 62, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v7
	v_cndmask_b32_e64 v9, 0, 2, vcc
	v_add_lshl_u32 v9, v9, v6, 2
	ds_bpermute_b32 v7, v9, v5
	v_cmp_ne_u32_e32 vcc, 63, v8
	v_mov_b32_e32 v9, 0
	v_and_b32_e32 v8, 63, v4
	v_addc_co_u32_e32 v6, vcc, 0, v6, vcc
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v7
	v_lshlrev_b32_e32 v6, 2, v6
	ds_bpermute_b32 v6, v6, v5
	v_cmp_eq_u64_e32 vcc, 0, v[8:9]
	s_and_b64 s[0:1], vcc, s[0:1]
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_14
.Lft6:
	v_mov_b32_e32 v2, s6
	v_mov_b32_e32 v3, s7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v5, v6
	v_lshl_add_u64 v[0:1], v[0:1], 2, v[2:3]
	global_store_dword v[0:1], v4, off
.LBB0_14:
	s_endpgm
.Lfunc_end0:
	.size	mo_reduce_sum, .Lfunc_end0-mo_reduce_sum
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_reduce_sum
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 280
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
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 10
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
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 280
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mo_reduce_sum
  .private_segment_fixed_size: 0
  .sgpr_count: 16
  .sgpr_spill_count: 0
  .symbol: mo_reduce_sum.kd
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
