	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fi_merge_state
	.globl	fi_merge_state
	.p2align	8
	.type	fi_merge_state,@function
fi_merge_state:
	s_load_dwordx2 s[12:13], s[0:1], 0x34
	v_lshrrev_b32_e32 v1, 5, v0
	v_lshl_add_u32 v2, s2, 1, v1
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_u32_e32 vcc, s13, v2
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_3
.Lft0:
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	v_mov_b32_e32 v3, 0
	v_lshlrev_b64 v[4:5], 2, v[2:3]
	v_and_b32_e32 v12, 31, v0
	v_mul_lo_u32 v0, s12, v2
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[4:5]
	v_lshl_add_u64 v[4:5], s[10:11], 0, v[4:5]
	global_load_dword v14, v[4:5], off
	global_load_dword v15, v[6:7], off
	v_mov_b32_e32 v1, v3
	v_lshlrev_b32_e32 v4, 2, v12
	v_mov_b32_e32 v5, v3
	v_lshl_add_u64 v[0:1], v[0:1], 0, v[4:5]
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	v_lshl_add_u64 v[4:5], s[8:9], 0, v[0:1]
	global_load_dwordx4 v[4:7], v[4:5], off
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[0:1]
	global_load_dwordx4 v[8:11], v[8:9], off
	s_load_dwordx4 s[4:7], s[0:1], 0x20
	v_cmp_eq_u32_e64 s[0:1], 0, v12
	s_mov_b32 s2, 0xc2fc0000
	v_mov_b32_e32 v16, 0x42800000
	v_not_b32_e32 v17, 63
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[12:13], s[4:5], 0, v[0:1]
	s_cmp_lg_u64 s[6:7], 0
	s_cselect_b64 s[4:5], -1, 0
	s_and_b64 s[0:1], s[0:1], s[4:5]
	s_waitcnt vmcnt(3)
	v_max_f32_e32 v0, v14, v14
	s_waitcnt vmcnt(2)
	v_max_f32_e32 v1, v15, v15
	v_max_f32_e32 v0, v1, v0
	v_sub_f32_e32 v1, v15, v0
	v_sub_f32_e32 v14, v14, v0
	v_max_f32_e32 v1, 0xff800000, v1
	v_max_f32_e32 v14, 0xff800000, v14
	v_cmp_gt_f32_e32 vcc, s2, v1
	v_cmp_gt_f32_e64 s[2:3], s2, v14
	s_nop 0
	v_cndmask_b32_e32 v15, 0, v16, vcc
	v_cndmask_b32_e64 v16, 0, v16, s[2:3]
	v_add_f32_e32 v1, v1, v15
	v_add_f32_e32 v14, v14, v16
	v_exp_f32_e32 v1, v1
	v_exp_f32_e32 v14, v14
	v_cndmask_b32_e32 v15, 0, v17, vcc
	v_cndmask_b32_e64 v16, 0, v17, s[2:3]
	v_ldexp_f32 v15, v1, v15
	v_ldexp_f32 v16, v14, v16
	v_add_f32_e32 v1, v15, v16
	v_div_scale_f32 v14, s[2:3], v1, v1, v15
	v_div_scale_f32 v17, s[2:3], v1, v1, v16
	v_rcp_f32_e32 v18, v14
	v_rcp_f32_e32 v19, v17
	v_div_scale_f32 v20, vcc, v15, v1, v15
	v_div_scale_f32 v21, s[2:3], v16, v1, v16
	v_fma_f32 v22, -v14, v18, 1.0
	v_fma_f32 v23, -v17, v19, 1.0
	v_fmac_f32_e32 v18, v22, v18
	v_fmac_f32_e32 v19, v23, v19
	v_mul_f32_e32 v22, v20, v18
	v_mul_f32_e32 v23, v21, v19
	v_fma_f32 v24, -v14, v22, v20
	v_fma_f32 v25, -v17, v23, v21
	v_fmac_f32_e32 v22, v24, v18
	v_fmac_f32_e32 v23, v25, v19
	v_fma_f32 v14, -v14, v22, v20
	v_fma_f32 v17, -v17, v23, v21
	v_div_fmas_f32 v14, v14, v18, v22
	s_mov_b64 vcc, s[2:3]
	v_div_fixup_f32 v14, v14, v1, v15
	v_div_fmas_f32 v15, v17, v19, v23
	v_cmp_lt_f32_e32 vcc, 0, v1
	v_div_fixup_f32 v15, v15, v1, v16
	s_nop 0
	v_cndmask_b32_e32 v16, 0, v15, vcc
	v_cndmask_b32_e32 v14, 0, v14, vcc
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[4:5], v[16:17], v[4:5] op_sel_hi:[0,1]
	v_pk_mul_f32 v[6:7], v[16:17], v[6:7] op_sel_hi:[0,1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[4:5], v[14:15], v[8:9], v[4:5] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[6:7], v[14:15], v[10:11], v[6:7] op_sel_hi:[0,1,1]
	global_store_dwordx4 v[12:13], v[4:7], off
	s_and_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_3
.Lft1:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v1
	v_mov_b32_e32 v4, 0x42000000
	s_nop 0
	v_cndmask_b32_e64 v5, 0, 32, vcc
	v_ldexp_f32 v1, v1, v5
	v_log_f32_e32 v1, v1
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_sub_f32_e32 v1, v1, v4
	v_add_f32_e32 v4, v0, v1
	v_lshl_add_u64 v[0:1], v[2:3], 2, s[6:7]
	global_store_dword v[0:1], v4, off
.LBB0_3:
	s_endpgm
.Lfunc_end0:
	.size	fi_merge_state, .Lfunc_end0-fi_merge_state
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fi_merge_state
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 60
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
		.amdhsa_next_free_vgpr 26
		.amdhsa_next_free_sgpr 14
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
  - .actual_access: read_only
    .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 40
    .size: 8
    .value_kind: global_buffer
  - .offset: 48
    .size: 4
    .value_kind: by_value
  - .offset: 52
    .size: 4
    .value_kind: by_value
  - .offset: 56
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 0
  .kernarg_segment_align: 8
  .kernarg_segment_size: 60
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: fi_merge_state
  .private_segment_fixed_size: 0
  .sgpr_count: 20
  .sgpr_spill_count: 0
  .symbol: fi_merge_state.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 26
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
