	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_rope_fwd
	.globl	mo_rope_fwd
	.p2align	8
	.type	mo_rope_fwd,@function
mo_rope_fwd:
	s_load_dword s3, s[0:1], 0x3c
	s_load_dwordx4 s[12:15], s[0:1], 0x20
	v_mov_b32_e32 v1, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s3, s3, 0xffff
	s_mul_i32 s2, s2, s3
	v_add_u32_e32 v0, s2, v0
	v_lshlrev_b64 v[2:3], 2, v[0:1]
	v_cmp_gt_u64_e32 vcc, s[12:13], v[2:3]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_9
.Lft0:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_lshr_b64 s[2:3], s[14:15], 1
	v_lshlrev_b32_e32 v0, 1, v0
	v_cmp_le_u64_e32 vcc, s[2:3], v[0:1]
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_3
.Lft1:
	s_flbit_i32_b32 s14, s3
	s_min_u32 s16, s14, 32
	s_lshl_b64 s[14:15], s[2:3], s16
	s_min_u32 s14, s14, 1
	s_or_b32 s14, s15, s14
	v_cvt_f32_u32_e32 v1, s14
	s_sub_i32 s14, 32, s16
	v_ldexp_f32 v1, v1, s14
	v_rcp_f32_e32 v1, v1
	s_sub_i32 s14, 0, s2
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_mul_lo_u32 v4, s14, v1
	v_mul_hi_u32 v4, v1, v4
	v_add_u32_e32 v1, v1, v4
	v_mul_hi_u32 v1, v1, v0
	v_mul_lo_u32 v1, v1, s2
	v_sub_u32_e32 v0, v0, v1
	v_subrev_u32_e32 v1, s2, v0
	v_cmp_le_u32_e32 vcc, s2, v0
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_subrev_u32_e32 v1, s2, v0
	v_cmp_le_u32_e32 vcc, s2, v0
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_mov_b32_e32 v1, 0
.LBB0_3:
	s_or_b64 exec, exec, s[0:1]
	v_lshl_add_u64 v[6:7], v[2:3], 0, 4
	v_cmp_ge_u64_e64 s[0:1], s[12:13], v[6:7]
	v_lshl_add_u64 v[6:7], v[0:1], 0, 1
	v_cmp_gt_u64_e32 vcc, s[2:3], v[6:7]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v4, s4
	v_mov_b32_e32 v5, s5
	s_and_b64 s[2:3], s[0:1], vcc
	v_lshlrev_b64 v[8:9], 3, v[0:1]
	s_xor_b64 s[2:3], s[2:3], -1
	v_lshl_add_u64 v[4:5], v[2:3], 2, v[4:5]
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[8:9]
	v_lshl_add_u64 v[8:9], s[8:9], 0, v[8:9]
	v_lshl_add_u64 v[2:3], v[2:3], 2, s[10:11]
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_xor_b64 s[2:3], exec, s[4:5]
	s_cbranch_execz .LBB0_7
.Lft2:
	global_load_dwordx2 v[10:11], v[4:5], off
	global_load_dwordx2 v[12:13], v[8:9], off
	global_load_dwordx2 v[14:15], v[6:7], off
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[6:7], v[10:11], v[12:13] op_sel:[1,0] op_sel_hi:[0,1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[8:9], v[10:11], v[14:15], v[6:7] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[6:7], v[10:11], v[14:15], v[6:7]
	s_nop 0
	v_mov_b32_e32 v9, v7
	global_store_dwordx2 v[2:3], v[8:9], off
	s_and_saveexec_b64 s[4:5], s[0:1]
	s_cbranch_execz .LBB0_6
.Lft3:
	v_add_u32_e32 v0, 1, v0
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[0:1], 1, v[0:1]
	v_cndmask_b32_e32 v1, 0, v1, vcc
	v_cndmask_b32_e32 v0, 0, v0, vcc
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	global_load_dwordx2 v[4:5], v[4:5], off offset:8
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[0:1]
	v_lshl_add_u64 v[0:1], s[8:9], 0, v[0:1]
	global_load_dwordx2 v[8:9], v[0:1], off
	global_load_dwordx2 v[10:11], v[6:7], off
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[0:1], v[4:5], v[8:9] op_sel:[1,0] op_sel_hi:[0,1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[6:7], v[4:5], v[10:11], v[0:1] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[0:1], v[4:5], v[10:11], v[0:1]
	s_nop 0
	v_mov_b32_e32 v7, v1
	global_store_dwordx2 v[2:3], v[6:7], off offset:8
.LBB0_6:
	s_or_b64 exec, exec, s[4:5]
.LBB0_7:
	s_andn2_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execz .LBB0_9
.Lft4:
	global_load_dwordx4 v[10:13], v[4:5], off
	global_load_dwordx4 v[14:17], v[6:7], off
	global_load_dwordx4 v[18:21], v[8:9], off
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[0:1], v[12:13], v[16:17]
	v_pk_mul_f32 v[6:7], v[10:11], v[14:15]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[4:5], v[10:11], v[18:19], v[6:7] op_sel:[1,0,0] op_sel_hi:[0,1,1] neg_lo:[1,0,0] neg_hi:[1,0,0]
	v_pk_fma_f32 v[8:9], v[10:11], v[18:19], v[6:7] op_sel:[1,0,0] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[6:7], v[12:13], v[20:21], v[0:1] op_sel:[1,0,0] op_sel_hi:[0,1,1] neg_lo:[1,0,0] neg_hi:[1,0,0]
	v_pk_fma_f32 v[0:1], v[12:13], v[20:21], v[0:1] op_sel:[1,0,0] op_sel_hi:[0,1,1]
	v_mov_b32_e32 v5, v9
	v_mov_b32_e32 v7, v1
	global_store_dwordx4 v[2:3], v[4:7], off
.LBB0_9:
	s_endpgm
.Lfunc_end0:
	.size	mo_rope_fwd, .Lfunc_end0-mo_rope_fwd
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_rope_fwd
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 304
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
		.amdhsa_next_free_vgpr 22
		.amdhsa_next_free_sgpr 17
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
  - .offset: 32
    .size: 8
    .value_kind: by_value
  - .offset: 40
    .size: 8
    .value_kind: by_value
  - .offset: 48
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 52
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 56
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 60
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 62
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 64
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 66
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 68
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 70
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 88
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 96
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 104
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 112
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 304
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mo_rope_fwd
  .private_segment_fixed_size: 0
  .sgpr_count: 23
  .sgpr_spill_count: 0
  .symbol: mo_rope_fwd.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 22
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
