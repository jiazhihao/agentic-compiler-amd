	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_copy
	.globl	rb_copy
	.p2align	8
	.type	rb_copy,@function
rb_copy:
	s_load_dword s14, s[0:1], 0x18
	s_mov_b64 s[10:11], exec
	s_mov_b32 s15, s0
	s_mov_b32 s16, s1
	v_mov_b32_e32 v8, v0
	s_lshl_b32 s13, s2, 1
	s_mov_b32 s12, 0
	s_waitcnt lgkmcnt(0)
.Lagc_wg_head:
	s_add_u32 s2, s13, s12
	s_cmp_ge_u32 s2, s14
	s_cbranch_scc1 .Lagc_wg_exit
.Lft2:
	s_mov_b64 exec, s[10:11]
	s_mov_b32 s0, s15
	s_mov_b32 s1, s16
	v_mov_b32_e32 v0, v8
.Lagc_wg_body:
	s_load_dword s8, s[0:1], 0x0
	s_load_dwordx4 s[4:7], s[0:1], 0x8
	v_lshlrev_b32_e32 v0, 1, v0
	v_lshl_or_b32 v2, s2, 9, v0
	v_mov_b32_e32 v3, 0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s0, s8, -1
	s_ashr_i32 s1, s0, 31
	v_cmp_gt_i64_e32 vcc, s[0:1], v[2:3]
	v_lshlrev_b64 v[0:1], 2, v[2:3]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_2
.Lft0:
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[0:1]
	global_load_dwordx2 v[6:7], v[4:5], off
	v_lshl_add_u64 v[4:5], s[6:7], 0, v[0:1]
	s_waitcnt vmcnt(0)
	global_store_dwordx2 v[4:5], v[6:7], off
.LBB0_2:
	s_or_b64 exec, exec, s[2:3]
	s_bitcmp1_b32 s8, 0
	s_cselect_b64 s[2:3], -1, 0
	v_cmp_eq_u64_e32 vcc, s[0:1], v[2:3]
	s_and_b64 s[0:1], vcc, s[2:3]
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_4
.Lft1:
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
	global_load_dword v2, v[2:3], off
	v_lshl_add_u64 v[0:1], s[6:7], 0, v[0:1]
	s_waitcnt vmcnt(0)
	global_store_dword v[0:1], v2, off
.LBB0_4:
.Lagc_wg_latch:
	s_add_u32 s12, s12, 1
	s_cmp_lt_u32 s12, 2
	s_cbranch_scc1 .Lagc_wg_head
.Lagc_wg_exit:
	s_endpgm
.Lfunc_end0:
	.size	rb_copy, .Lfunc_end0-rb_copy
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_copy
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 32
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
		.amdhsa_next_free_vgpr 9
		.amdhsa_next_free_sgpr 17
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
  - .offset: 0
    .size: 4
    .value_kind: by_value
  - .actual_access: read_only
    .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .offset: 24
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 32
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 256
  .name: rb_copy
  .private_segment_fixed_size: 0
  .sgpr_count: 23
  .sgpr_spill_count: 0
  .symbol: rb_copy.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 9
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
