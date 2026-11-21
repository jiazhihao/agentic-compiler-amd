	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mo_prelu_bwd
	.globl	mo_prelu_bwd
	.p2align	8
	.type	mo_prelu_bwd,@function
mo_prelu_bwd:
	s_load_dwordx4 s[12:15], s[0:1], 0x20
	s_mov_b32 s3, 0
	s_lshl_b64 s[4:5], s[2:3], 8
	v_lshlrev_b32_e32 v2, 1, v0
	v_mov_b32_e32 v3, 0
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[2:3]
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_u64_e32 vcc, s[14:15], v[2:3]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_13
.Lft0:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	v_lshl_add_u64 v[4:5], v[2:3], 0, 2
	v_cmp_ge_u64_e32 vcc, s[14:15], v[4:5]
	s_and_saveexec_b64 s[0:1], vcc
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB0_6
.Lft1:
	v_lshlrev_b64 v[0:1], 2, v[2:3]
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[0:1]
	v_lshl_add_u64 v[0:1], s[8:9], 0, v[0:1]
	global_load_dwordx2 v[4:5], v[4:5], off
	s_cmp_eq_u64 s[10:11], 0
	global_load_dwordx2 v[6:7], v[0:1], off
	s_cbranch_scc1 .LBB0_4
.Lft2:
	s_load_dword s16, s[6:7], 0x0
	s_waitcnt vmcnt(1)
	v_cmp_lt_f32_e32 vcc, 0, v5
	v_lshl_add_u64 v[8:9], v[2:3], 2, s[10:11]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_pk_mul_f32 v[0:1], s[16:17], v[6:7] op_sel_hi:[0,1]
	v_cndmask_b32_e32 v1, v1, v7, vcc
	v_cmp_lt_f32_e32 vcc, 0, v4
	s_nop 1
	v_cndmask_b32_e32 v0, v0, v6, vcc
	global_store_dwordx2 v[8:9], v[0:1], off
.LBB0_4:
	s_cmp_eq_u64 s[12:13], 0
	s_cbranch_scc1 .LBB0_6
.Lft3:
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[0:1], v[4:5], v[6:7]
	v_cmp_nlt_f32_e32 vcc, 0, v5
	v_lshl_add_u64 v[2:3], v[2:3], 2, s[12:13]
	s_nop 0
	v_cndmask_b32_e32 v1, 0, v1, vcc
	v_cmp_nlt_f32_e32 vcc, 0, v4
	s_nop 1
	v_cndmask_b32_e32 v0, 0, v0, vcc
	global_store_dwordx2 v[2:3], v[0:1], off
.LBB0_6:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB0_13
.Lft4:
	s_waitcnt lgkmcnt(0)
	s_cmp_lg_u64 s[10:11], 0
	s_cselect_b64 s[0:1], -1, 0
	s_cmp_lg_u64 s[12:13], 0
	s_cselect_b64 s[18:19], -1, 0
	s_lshl_b64 s[2:3], s[2:3], 10
	v_lshlrev_b32_e32 v0, 3, v0
	v_mov_b32_e32 v1, 0
	v_cndmask_b32_e64 v10, 0, 1, s[0:1]
	v_lshl_add_u64 v[8:9], s[2:3], 0, v[0:1]
	v_cmp_ne_u32_e64 s[0:1], 1, v10
	v_cndmask_b32_e64 v10, 0, 1, s[18:19]
	s_mov_b64 s[16:17], 0
	v_lshl_add_u64 v[0:1], s[12:13], 0, v[8:9]
	s_waitcnt vmcnt(1)
	v_lshl_add_u64 v[4:5], s[10:11], 0, v[8:9]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[6:7], s[8:9], 0, v[8:9]
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[8:9]
	v_cmp_ne_u32_e64 s[2:3], 1, v10
	s_branch .LBB0_9
	.p2align	5, , 4
.LBB0_8:
	v_lshl_add_u64 v[2:3], v[2:3], 0, 1
	v_cmp_le_u64_e32 vcc, s[14:15], v[2:3]
	v_lshl_add_u64 v[0:1], v[0:1], 0, 4
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	v_lshl_add_u64 v[6:7], v[6:7], 0, 4
	s_or_b64 s[16:17], vcc, s[16:17]
	v_lshl_add_u64 v[8:9], v[8:9], 0, 4
	s_andn2_b64 exec, exec, s[16:17]
	s_cbranch_execz .LBB0_13
.LBB0_9:
	global_load_dword v10, v[8:9], off
	global_load_dword v11, v[6:7], off
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_11
.Lft5:
	s_load_dword s4, s[6:7], 0x0
	s_waitcnt vmcnt(1)
	v_cmp_lt_f32_e32 vcc, 0, v10
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_mul_f32_e32 v12, s4, v11
	v_cndmask_b32_e32 v12, v12, v11, vcc
	global_store_dword v[4:5], v12, off
.LBB0_11:
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_8
.Lft6:
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v11, v10, v11
	v_cmp_nlt_f32_e32 vcc, 0, v10
	s_nop 1
	v_cndmask_b32_e32 v10, 0, v11, vcc
	global_store_dword v[0:1], v10, off
	s_branch .LBB0_8
.LBB0_13:
	s_endpgm
.Lfunc_end0:
	.size	mo_prelu_bwd, .Lfunc_end0-mo_prelu_bwd
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mo_prelu_bwd
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
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 13
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
  - .actual_access: write_only
    .address_space: global
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
  .max_flat_workgroup_size: 1024
  .name: mo_prelu_bwd
  .private_segment_fixed_size: 0
  .sgpr_count: 26
  .sgpr_spill_count: 0
  .symbol: mo_prelu_bwd.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 13
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
