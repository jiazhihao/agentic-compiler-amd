	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_nrm2
	.globl	rb_nrm2
	.p2align	8
	.type	rb_nrm2,@function
rb_nrm2:
	s_load_dwordx2 s[8:9], s[0:1], 0x0
	s_load_dwordx4 s[4:7], s[0:1], 0x8
	s_mov_b32 s3, 0
	v_lshlrev_b32_e32 v2, 2, v0
	s_lshl_b64 s[0:1], s[2:3], 9
	v_and_b32_e32 v2, 0x1fc, v2
	s_waitcnt lgkmcnt(0)
	s_lshl_b32 s10, s9, 9
	v_lshrrev_b32_e32 v1, 7, v0
	v_or_b32_e32 v2, s0, v2
	v_mov_b32_e32 v3, s1
	v_mad_i64_i32 v[4:5], s[0:1], s10, v1, v[2:3]
	s_ashr_i32 s9, s8, 31
	v_lshl_add_u64 v[2:3], v[4:5], 0, 4
	v_cmp_ge_i64_e32 vcc, s[8:9], v[2:3]
	v_lshl_add_u64 v[2:3], v[4:5], 2, s[4:5]
	s_and_saveexec_b64 s[0:1], vcc
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB0_2
.Lft0:
	global_load_dwordx4 v[2:5], v[2:3], off
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[4:5], v[4:5], v[4:5]
	v_pk_mul_f32 v[2:3], v[2:3], v[2:3]
	s_nop 0
	v_add_f32_e32 v1, v2, v3
	v_add_f32_e32 v2, v4, v5
	v_add_f32_e32 v1, v1, v2
.LBB0_2:
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB0_12
.Lft1:
	v_cmp_gt_i64_e32 vcc, s[8:9], v[4:5]
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_5
.Lft2:
	global_load_dword v1, v[2:3], off
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, v1, v1
.LBB0_5:
	s_or_b64 exec, exec, s[4:5]
	v_or_b32_e32 v6, 1, v4
	v_mov_b32_e32 v7, v5
	v_cmp_gt_i64_e32 vcc, s[8:9], v[6:7]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_7
.Lft3:
	global_load_dword v6, v[2:3], off offset:4
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, v6, v6
.LBB0_7:
	s_or_b64 exec, exec, s[4:5]
	v_or_b32_e32 v6, 2, v4
	v_mov_b32_e32 v7, v5
	v_cmp_gt_i64_e32 vcc, s[8:9], v[6:7]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_9
.Lft4:
	global_load_dword v6, v[2:3], off offset:8
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, v6, v6
.LBB0_9:
	s_or_b64 exec, exec, s[4:5]
	v_or_b32_e32 v4, 3, v4
	v_cmp_gt_i64_e32 vcc, s[8:9], v[4:5]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_11
.Lft5:
	global_load_dword v2, v[2:3], off offset:12
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, v2, v2
.LBB0_11:
	s_or_b64 exec, exec, s[4:5]
.LBB0_12:
	s_or_b64 exec, exec, s[0:1]
	v_mbcnt_lo_u32_b32 v2, -1, 0
	v_mbcnt_hi_u32_b32 v2, -1, v2
	v_mov_b32_e32 v3, 0x80
	v_lshl_or_b32 v3, v2, 2, v3
	ds_bpermute_b32 v3, v3, v1
	v_and_b32_e32 v4, 63, v2
	v_cmp_gt_u32_e32 vcc, 48, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v3
	v_cndmask_b32_e64 v5, 0, 16, vcc
	v_add_lshl_u32 v3, v5, v2, 2
	ds_bpermute_b32 v3, v3, v1
	v_cmp_gt_u32_e32 vcc, 56, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v3
	v_cndmask_b32_e64 v5, 0, 8, vcc
	v_add_lshl_u32 v5, v5, v2, 2
	ds_bpermute_b32 v3, v5, v1
	v_cmp_gt_u32_e32 vcc, 60, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v3
	v_cndmask_b32_e64 v5, 0, 4, vcc
	v_add_lshl_u32 v5, v5, v2, 2
	ds_bpermute_b32 v3, v5, v1
	v_cmp_gt_u32_e32 vcc, 62, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v3
	v_cndmask_b32_e64 v5, 0, 2, vcc
	v_add_lshl_u32 v5, v5, v2, 2
	ds_bpermute_b32 v3, v5, v1
	v_cmp_ne_u32_e32 vcc, 63, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v3
	v_addc_co_u32_e32 v2, vcc, 0, v2, vcc
	v_lshlrev_b32_e32 v2, 2, v2
	ds_bpermute_b32 v2, v2, v1
	v_and_b32_e32 v3, 63, v0
	v_cmp_eq_u32_e32 vcc, 0, v3
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_14
.Lft6:
	v_lshrrev_b32_e32 v3, 4, v0
	v_and_b32_e32 v3, 28, v3
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_write_b32 v3, v1
.LBB0_14:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_16
.Lft7:
	v_mov_b32_e32 v8, 0
	ds_read_b128 v[0:3], v8
	ds_read_b128 v[4:7], v8 offset:16
	s_lshl_b64 s[0:1], s[2:3], 2
	s_add_u32 s0, s6, s0
	s_addc_u32 s1, s7, s1
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v0, 0, v0
	v_add_f32_e32 v0, v0, v1
	v_add_f32_e32 v0, v0, v2
	v_add_f32_e32 v0, v0, v3
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v4
	v_add_f32_e32 v0, v0, v5
	v_add_f32_e32 v0, v0, v6
	v_add_f32_e32 v0, v0, v7
	global_store_dword v8, v0, s[0:1]
.LBB0_16:
	s_endpgm
.Lfunc_end0:
	.size	rb_nrm2, .Lfunc_end0-rb_nrm2
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_nrm2
		.amdhsa_group_segment_fixed_size 32
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
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
		.amdhsa_next_free_sgpr 11
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
  - .offset: 4
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  .gfx1250_revision: B0
  .group_segment_fixed_size: 32
  .kernarg_segment_align: 8
  .kernarg_segment_size: 24
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 512
  .name: rb_nrm2
  .private_segment_fixed_size: 0
  .sgpr_count: 17
  .sgpr_spill_count: 0
  .symbol: rb_nrm2.kd
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
