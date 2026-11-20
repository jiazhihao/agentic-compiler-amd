	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	vl_rotary_embedding
	.globl	vl_rotary_embedding
	.p2align	8
	.type	vl_rotary_embedding,@function
vl_rotary_embedding:
	s_load_dword s19, s[0:1], 0x20
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx2 s[16:17], s[0:1], 0x40
	s_load_dword s12, s[0:1], 0x6c
	s_mov_b64 s[20:21], 0
	s_waitcnt lgkmcnt(0)
	s_lshr_b32 s13, s19, 31
	s_add_i32 s13, s19, s13
	s_ashr_i32 s18, s13, 1
	s_add_i32 s13, s18, 3
	s_lshr_b32 s28, s13, 2
	s_cmp_lg_u64 s[8:9], 0
	s_cselect_b32 s13, s17, 0
	s_add_i32 s17, s13, s16
	s_add_u32 s24, s0, 0x60
	s_addc_u32 s25, s1, 0
	s_and_b32 s29, s12, 0xffff
	s_mul_i32 s3, s3, s29
	s_mul_i32 s17, s17, s28
	v_add_u32_e32 v6, s3, v0
	v_cmp_gt_u32_e32 vcc, s17, v6
	s_and_saveexec_b64 s[12:13], vcc
	s_cbranch_execz .LBB0_10
.Lft0:
	s_load_dword s3, s[0:1], 0x58
	v_cvt_f32_u32_e32 v0, s28
	v_lshlrev_b32_e32 v8, 2, v6
	v_sub_u32_e32 v9, s18, v8
	v_rcp_iflag_f32_e32 v0, v0
	s_waitcnt lgkmcnt(0)
	s_bitcmp1_b32 s3, 0
	s_cselect_b64 vcc, -1, 0
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[12:13], s[2:3], 3
	s_add_u32 s26, s4, s12
	s_addc_u32 s27, s5, s13
	s_load_dwordx2 s[30:31], s[26:27], 0x0
	s_load_dwordx2 s[4:5], s[0:1], 0x50
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_load_dwordx2 s[22:23], s[0:1], 0x38
	s_ashr_i32 s0, s19, 31
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s1, s30, s0
	s_mul_hi_u32 s26, s30, s19
	s_mul_i32 s27, s31, s19
	s_add_i32 s1, s26, s1
	s_mul_i32 s0, s30, s19
	s_add_i32 s1, s1, s27
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s10, s10, s0
	s_load_dword s0, s[24:25], 0x4
	s_addc_u32 s11, s11, s1
	s_ashr_i32 s19, s18, 31
	s_lshl_b64 s[24:25], s[18:19], 2
	s_add_u32 s26, s10, s24
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s29, s0, s29
	s_mul_hi_u32 s0, s14, s2
	s_mul_i32 s1, s14, s3
	s_addc_u32 s27, s11, s25
	s_add_i32 s0, s0, s1
	s_mul_i32 s1, s15, s2
	s_add_i32 s1, s0, s1
	s_mul_i32 s0, s14, s2
	s_add_i32 s30, s18, -4
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s8, s8, s0
	s_addc_u32 s9, s9, s1
	s_mul_hi_u32 s0, s12, s2
	s_mul_i32 s1, s12, s3
	s_add_i32 s0, s0, s1
	s_mul_i32 s1, s13, s2
	v_mul_f32_e32 v0, 0x4f7ffffe, v0
	s_add_i32 s1, s0, s1
	s_mul_i32 s0, s12, s2
	v_cvt_u32_f32_e32 v0, v0
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s7, s1
	s_sub_i32 s2, 0, s28
	v_mul_lo_u32 v1, s2, v0
	v_mul_hi_u32 v1, v0, v1
	v_add_u32_e32 v7, v0, v1
	s_lshl_b32 s31, s29, 2
	s_lshl_b32 s33, s28, 2
	s_lshl_b64 s[2:3], s[4:5], 2
	s_lshl_b64 s[6:7], s[22:23], 2
	v_mov_b32_e32 v10, s9
	v_mov_b32_e32 v11, s1
	v_mov_b32_e32 v12, s8
	v_mov_b32_e32 v13, s0
	s_branch .LBB0_4
	.p2align	5
.LBB0_2:
	s_or_b64 exec, exec, s[12:13]
.LBB0_3:
	s_or_b64 exec, exec, s[8:9]
	v_add_u32_e32 v6, s29, v6
	v_cmp_le_u32_e64 s[0:1], s17, v6
	v_subrev_u32_e32 v9, s31, v9
	s_or_b64 s[20:21], s[0:1], s[20:21]
	v_add_u32_e32 v8, s31, v8
	s_andn2_b64 exec, exec, s[20:21]
	s_cbranch_execz .LBB0_10
.LBB0_4:
	v_mul_hi_u32 v0, v6, v7
	v_mul_lo_u32 v1, v0, s28
	v_sub_u32_e32 v1, v6, v1
	v_add_u32_e32 v2, 1, v0
	v_cmp_le_u32_e64 s[0:1], s28, v1
	s_nop 1
	v_cndmask_b32_e64 v0, v0, v2, s[0:1]
	v_subrev_u32_e32 v2, s28, v1
	v_cndmask_b32_e64 v1, v1, v2, s[0:1]
	v_add_u32_e32 v2, 1, v0
	v_cmp_le_u32_e64 s[0:1], s28, v1
	s_nop 1
	v_cndmask_b32_e64 v5, v0, v2, s[0:1]
	v_mul_lo_u32 v0, v5, s28
	v_sub_u32_e32 v0, v6, v0
	v_lshlrev_b32_e32 v4, 2, v0
	v_subrev_u32_e32 v0, s16, v5
	v_cmp_gt_u32_e64 s[0:1], s16, v5
	v_min_u32_e32 v0, v5, v0
	s_nop 0
	v_cndmask_b32_e64 v3, v10, v11, s[0:1]
	v_cndmask_b32_e64 v2, v12, v13, s[0:1]
	v_cmp_ge_i32_e64 s[0:1], s30, v4
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_xor_b64 s[0:1], exec, s[8:9]
	s_cbranch_execz .LBB0_6
.Lft1:
	v_mad_u64_u32 v[18:19], s[8:9], s22, v0, 0
	v_mov_b32_e32 v20, v19
	v_mad_u64_u32 v[0:1], s[8:9], s23, v0, v[20:21]
	v_ashrrev_i32_e32 v5, 31, v4
	v_mov_b32_e32 v19, v0
	v_lshlrev_b64 v[4:5], 2, v[4:5]
	v_lshl_add_u64 v[0:1], v[18:19], 2, v[2:3]
	v_lshl_add_u64 v[14:15], s[26:27], 0, v[4:5]
	v_lshl_add_u64 v[22:23], s[4:5], 2, v[0:1]
	global_load_dwordx4 v[14:17], v[14:15], off
	v_lshl_add_u64 v[0:1], s[18:19], 2, v[22:23]
	v_lshl_add_u64 v[26:27], v[0:1], 0, v[4:5]
	global_load_dwordx4 v[0:3], v[26:27], off
	v_lshl_add_u64 v[18:19], s[10:11], 0, v[4:5]
	v_lshl_add_u64 v[4:5], v[22:23], 0, v[4:5]
	global_load_dwordx4 v[18:21], v[18:19], off
	s_waitcnt vmcnt(2)
	v_xor_b32_e32 v28, 0x80000000, v16
	global_load_dwordx4 v[22:25], v[4:5], off
	v_xor_b32_e32 v29, 0x80000000, v17
	v_xor_b32_e32 v30, 0x80000000, v14
	v_xor_b32_e32 v31, 0x80000000, v15
	v_cndmask_b32_e32 v15, v15, v31, vcc
	v_cndmask_b32_e32 v14, v14, v30, vcc
	v_cndmask_b32_e32 v17, v17, v29, vcc
	v_cndmask_b32_e32 v16, v16, v28, vcc
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[28:29], v[16:17], v[2:3]
	v_pk_mul_f32 v[30:31], v[14:15], v[0:1]
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[32:33], v[20:21], v[2:3]
	v_pk_mul_f32 v[34:35], v[18:19], v[0:1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[2:3], v[20:21], v[24:25], v[28:29] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[0:1], v[18:19], v[22:23], v[30:31] neg_lo:[0,0,1] neg_hi:[0,0,1]
	v_pk_fma_f32 v[16:17], v[24:25], v[16:17], v[32:33]
	v_pk_fma_f32 v[14:15], v[22:23], v[14:15], v[34:35]
	global_store_dwordx4 v[4:5], v[0:3], off
	global_store_dwordx4 v[26:27], v[14:17], off
.LBB0_6:
	s_andn2_saveexec_b64 s[8:9], s[0:1]
	s_cbranch_execz .LBB0_3
.Lft2:
	v_cmp_gt_i32_e64 s[0:1], s18, v4
	s_and_saveexec_b64 s[12:13], s[0:1]
	s_cbranch_execz .LBB0_2
.Lft3:
	v_mul_lo_u32 v1, s33, v5
	v_sub_u32_e32 v4, v8, v1
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshlrev_b64 v[16:17], 2, v[4:5]
	v_lshl_add_u64 v[4:5], s[10:11], 0, v[16:17]
	v_mad_u64_u32 v[16:17], s[0:1], s6, v0, v[16:17]
	v_mov_b32_e32 v18, v17
	v_add_u32_e32 v14, v9, v1
	v_mad_u64_u32 v[0:1], s[0:1], s7, v0, v[18:19]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	v_mov_b32_e32 v17, v0
	v_lshl_add_u64 v[0:1], v[2:3], 0, v[16:17]
	s_mov_b64 s[14:15], 0
	.p2align	5, , 4
.LBB0_9:
	v_lshl_add_u64 v[2:3], v[4:5], 0, s[24:25]
	global_load_dword v15, v[4:5], off
	global_load_dword v16, v[2:3], off
	v_lshl_add_u64 v[2:3], v[0:1], 0, s[24:25]
	global_load_dword v17, v[2:3], off
	global_load_dword v18, v[0:1], off
	v_add_u32_e32 v14, -1, v14
	v_cmp_eq_u32_e64 s[0:1], 0, v14
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	s_or_b64 s[14:15], s[0:1], s[14:15]
	s_waitcnt vmcnt(2)
	v_cndmask_b32_e64 v16, v16, -v16, vcc
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v19, v15, v17
	v_mul_f32_e32 v17, v16, v17
	s_waitcnt vmcnt(0)
	v_fma_f32 v15, v15, v18, -v17
	v_fmac_f32_e32 v19, v18, v16
	global_store_dword v[0:1], v15, off
	global_store_dword v[2:3], v19, off
	v_lshl_add_u64 v[0:1], v[0:1], 0, 4
	s_andn2_b64 exec, exec, s[14:15]
	s_cbranch_execnz .LBB0_9
.Lft4:
	s_branch .LBB0_2
.LBB0_10:
	s_endpgm
.Lfunc_end0:
	.size	vl_rotary_embedding, .Lfunc_end0-vl_rotary_embedding
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel vl_rotary_embedding
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 352
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
		.amdhsa_next_free_vgpr 36
		.amdhsa_next_free_sgpr 34
		.amdhsa_accum_offset 36
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
  - .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
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
    .size: 8
    .value_kind: by_value
  - .offset: 56
    .size: 8
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
  - .offset: 80
    .size: 8
    .value_kind: by_value
  - .offset: 88
    .size: 1
    .value_kind: by_value
  - .offset: 96
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 100
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 104
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 108
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 110
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 112
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 114
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 116
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 118
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 136
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 144
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 152
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 160
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 352
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: vl_rotary_embedding
  .private_segment_fixed_size: 0
  .sgpr_count: 40
  .sgpr_spill_count: 0
  .symbol: vl_rotary_embedding.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 36
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
