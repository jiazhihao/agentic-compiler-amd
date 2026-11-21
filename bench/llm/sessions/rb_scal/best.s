	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_scal
	.globl	rb_scal
	.p2align	8
	.type	rb_scal,@function
rb_scal:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	v_lshlrev_b32_e32 v0, 1, v0
	v_lshl_or_b32 v0, s2, 8, v0
	v_mov_b32_e32 v1, 0
	s_lshl_b32 s8, s2, 8
	s_add_u32 s8, s8, 0x100
	s_waitcnt lgkmcnt(0)
	s_cmp_eq_u32 s5, 0x3f800000
	s_cbranch_scc1 .Lend
.Lgo:
	v_lshl_add_u64 v[2:3], v[0:1], 2, s[6:7]
	s_cmp_le_u32 s8, s4
	s_cbranch_scc0 .Lslow
.Lfast:
	global_load_dwordx2 v[4:5], v[2:3], off
	global_load_dwordx2 v[6:7], v[2:3], off offset:512
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v4, s5, v4
	v_mul_f32_e32 v5, s5, v5
	global_store_dwordx2 v[2:3], v[4:5], off
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v6, s5, v6
	v_mul_f32_e32 v7, s5, v7
	global_store_dwordx2 v[2:3], v[6:7], off offset:512
	s_endpgm
.Lslow:
	s_mov_b64 s[10:11], exec
	s_mov_b32 s8, 2
	s_add_i32 s9, s4, -1
.Lsloop:
	v_or_b32_e32 v4, 1, v0
	v_cmp_gt_u32_e32 vcc, s4, v4
	s_and_b64 exec, s[10:11], vcc
	global_load_dwordx2 v[4:5], v[2:3], off
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v4, s5, v4
	v_mul_f32_e32 v5, s5, v5
	global_store_dwordx2 v[2:3], v[4:5], off
	s_mov_b64 exec, s[10:11]
	v_cmp_eq_u32_e32 vcc, s9, v0
	s_and_b64 exec, s[10:11], vcc
	global_load_dword v4, v[2:3], off
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v4, s5, v4
	global_store_dword v[2:3], v4, off
	s_mov_b64 exec, s[10:11]
	v_add_u32_e32 v0, 0x80, v0
	v_add_co_u32_e32 v2, vcc, 0x200, v2
	s_nop 1
	v_addc_co_u32_e32 v3, vcc, 0, v3, vcc
	s_add_i32 s8, s8, -1
	s_cmp_lg_u32 s8, 0
	s_cbranch_scc1 .Lsloop
.Lend:
	s_endpgm
.Lfunc_end0:
	.size	rb_scal, .Lfunc_end0-rb_scal
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_scal
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 12
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
  - .offset: 0
    .size: 4
    .value_kind: by_value
  - .offset: 4
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 16
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 256
  .name: rb_scal
  .private_segment_fixed_size: 0
  .sgpr_count: 18
  .sgpr_spill_count: 0
  .symbol: rb_scal.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 8
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
