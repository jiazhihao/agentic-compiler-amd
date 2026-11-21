	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_ger
	.globl	rb_ger
	.p2align	8
	.type	rb_ger,@function
rb_ger:
	s_mov_b32 s12, s3
	s_load_dwordx4 s[16:19], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x10
	s_lshl_b32 s15, s2, 8
	v_lshlrev_b32_e32 v9, 2, v0
	v_or_b32_e32 v2, s15, v9
	s_ashr_i32 s13, s12, 31
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshlrev_b64 v[0:1], 2, v[2:3]
	s_waitcnt lgkmcnt(0)
	s_mov_b32 s14, s16
	s_mov_b32 s3, s18
	v_cmp_eq_f32_e64 s[16:17], s3, 0
	s_and_b64 vcc, exec, s[16:17]
	s_cbranch_vccnz .LBB0_12
.Lft0:
	v_cmp_gt_i32_e32 vcc, s14, v2
	s_and_saveexec_b64 s[16:17], vcc
	s_cbranch_execz .LBB0_12
.Lft1:
	s_mul_hi_u32 s1, s10, s12
	s_mul_i32 s2, s10, s13
	s_mul_i32 s11, s11, s12
	s_add_i32 s1, s1, s2
	s_mul_i32 s0, s10, s12
	s_add_i32 s1, s1, s11
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s10, s8, s0
	s_addc_u32 s11, s9, s1
	s_lshl_b64 s[12:13], s[12:13], 2
	s_add_u32 s6, s6, s12
	s_addc_u32 s7, s7, s13
	s_load_dword s16, s[6:7], 0x0
	v_lshl_add_u64 v[4:5], s[10:11], 0, v[0:1]
	v_lshl_add_u64 v[6:7], s[4:5], 0, v[0:1]
	v_mov_b32_e32 v0, s3
	v_add_u32_e32 v1, 4, v2
	v_cmp_ge_i32_e32 vcc, s14, v1
	s_and_saveexec_b64 s[2:3], vcc
	s_xor_b64 s[2:3], exec, s[2:3]
	s_cbranch_execz .LBB0_4
.Lft2:
	global_load_dwordx4 v[8:11], v[6:7], off
	global_load_dwordx4 v[12:15], v[4:5], off
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v0, s16, v0
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[6:7], v[8:9], v[0:1], v[12:13] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[10:11], v[0:1], v[14:15] op_sel_hi:[1,0,1]
	global_store_dwordx4 v[4:5], v[6:9], off
.LBB0_4:
	s_andn2_saveexec_b64 s[2:3], s[2:3]
	s_cbranch_execz .LBB0_12
.Lft3:
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v0, s16, v0
	v_sub_u32_e32 v1, s14, v2
	v_cmp_lt_u32_e32 vcc, 1, v1
	s_mov_b64 s[6:7], -1
	v_mov_b32_e32 v8, 0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_9
.Lft4:
	s_and_b32 s10, s14, 1
	v_subrev_u32_e32 v8, s10, v1
	v_mov_b32_e32 v1, v0
	s_mov_b64 s[6:7], 0
	v_mov_b32_e32 v10, v8
	.p2align	5, , 4
.LBB0_7:
	global_load_dwordx2 v[12:13], v[6:7], off
	global_load_dwordx2 v[14:15], v[4:5], off
	v_add_u32_e32 v10, -2, v10
	v_cmp_eq_u32_e32 vcc, 0, v10
	s_or_b64 s[6:7], vcc, s[6:7]
	v_lshl_add_u64 v[6:7], v[6:7], 0, 8
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[12:13], v[12:13], v[0:1], v[14:15]
	global_store_dwordx2 v[4:5], v[12:13], off
	v_lshl_add_u64 v[4:5], v[4:5], 0, 8
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_7
.Lft5:
	s_or_b64 exec, exec, s[6:7]
	s_cmp_lg_u32 s10, 0
	s_cselect_b64 s[6:7], -1, 0
	s_orn2_b64 s[6:7], s[6:7], exec
.LBB0_9:
	s_or_b64 exec, exec, s[2:3]
	s_and_b64 exec, exec, s[6:7]
	s_cbranch_execz .LBB0_12
.Lft6:
	v_add3_u32 v1, v8, s15, v9
	v_mov_b32_e32 v9, 0
	v_lshlrev_b64 v[4:5], 2, v[8:9]
	s_add_u32 s0, s8, s0
	v_lshl_add_u64 v[4:5], v[2:3], 2, v[4:5]
	s_addc_u32 s1, s9, s1
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[4:5]
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[4:5]
	s_mov_b64 s[0:1], 0
	.p2align	5, , 4
.LBB0_11:
	global_load_dword v6, v[2:3], off
	global_load_dword v7, v[4:5], off
	v_add_u32_e32 v1, 1, v1
	v_cmp_le_i32_e32 vcc, s14, v1
	v_lshl_add_u64 v[2:3], v[2:3], 0, 4
	s_or_b64 s[0:1], vcc, s[0:1]
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v7, v6, v0
	global_store_dword v[4:5], v7, off
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB0_11
.LBB0_12:
	s_endpgm
.Lfunc_end0:
	.size	rb_ger, .Lfunc_end0-rb_ger
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_ger
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 48
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
		.amdhsa_next_free_vgpr 16
		.amdhsa_next_free_sgpr 20
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
  - .offset: 4
    .size: 4
    .value_kind: by_value
  - .offset: 8
    .size: 4
    .value_kind: by_value
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
  - .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .offset: 40
    .size: 8
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 48
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 64
  .name: rb_ger
  .private_segment_fixed_size: 0
  .sgpr_count: 26
  .sgpr_spill_count: 0
  .symbol: rb_ger.kd
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
