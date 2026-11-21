	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_gemvn
	.globl	rb_gemvn
	.p2align	8
	.type	rb_gemvn,@function
rb_gemvn:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_waitcnt lgkmcnt(0)
	s_load_dword s7, s[0:1], 0x28
	s_load_dwordx2 s[8:9], s[0:1], 0x30
	v_and_b32_e32 v6, 0x3ff, v0
	v_bfe_u32 v3, v0, 10, 10
	v_lshl_add_u32 v7, v3, 6, v6
	s_lshl_b32 s22, s2, 6
	v_cmp_eq_f32_e64 s[2:3], s6, 0
	s_and_b64 vcc, exec, s[2:3]
	v_cmp_gt_u32_e64 s[2:3], 64, v7
	s_cbranch_vccz .LBB0_5
.Lft0:
	s_waitcnt lgkmcnt(0)
	v_cmp_neq_f32_e64 s[10:11], s7, 1.0
	s_and_b64 s[14:15], s[10:11], s[2:3]
	s_mov_b64 s[10:11], 0
	s_mov_b64 s[2:3], 0
	s_and_saveexec_b64 s[12:13], s[14:15]
	s_cbranch_execz .LBB0_8
.Lft1:
	v_or_b32_e32 v0, s22, v6
	v_cmp_gt_i32_e32 vcc, s4, v0
	s_mov_b64 s[14:15], 0
	s_and_saveexec_b64 s[2:3], vcc
	s_xor_b64 s[2:3], exec, s[2:3]
	s_cbranch_execz .LBB0_7
.Lft2:
	v_cmp_eq_f32_e64 s[14:15], s7, 0
	v_ashrrev_i32_e32 v1, 31, v0
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccnz .LBB0_6
.Lft3:
	v_lshl_add_u64 v[4:5], v[0:1], 2, s[8:9]
	global_load_dword v2, v[4:5], off
	s_mov_b64 s[14:15], exec
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, s7, v2
	s_branch .LBB0_7
.LBB0_5:
	s_mov_b64 s[2:3], 0
	s_cbranch_execnz .LBB0_9
.Lft4:
	s_branch .LBB0_26
.LBB0_6:
	v_mov_b32_e32 v2, 0
	s_mov_b64 s[14:15], exec
.LBB0_7:
	s_or_b64 exec, exec, s[2:3]
	s_and_b64 s[2:3], s[14:15], exec
.LBB0_8:
	s_or_b64 exec, exec, s[12:13]
	s_and_b64 vcc, exec, s[10:11]
	s_cbranch_vccz .LBB0_26
.LBB0_9:
	v_add_u32_e32 v2, s22, v6
	v_cmp_gt_i32_e32 vcc, s4, v2
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b64 s[10:11], vcc
	s_cbranch_execz .LBB0_19
.Lft5:
	s_load_dwordx2 s[12:13], s[0:1], 0x10
	s_load_dword s14, s[0:1], 0x18
	s_load_dwordx2 s[16:17], s[0:1], 0x20
	v_lshlrev_b32_e32 v0, 3, v3
	v_add_u32_e32 v1, 8, v0
	v_ashrrev_i32_e32 v3, 31, v2
	v_cmp_ge_i32_e32 vcc, s5, v1
	v_mov_b32_e32 v1, 0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_14
.Lft6:
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s15, s14, 31
	v_lshl_add_u64 v[4:5], v[2:3], 2, s[12:13]
	s_lshl_b64 s[20:21], s[14:15], 2
	s_mov_b64 s[18:19], 0
	v_mov_b32_e32 v8, 0
	.p2align	5, , 4
.LBB0_12:
	v_mad_u64_u32 v[20:21], s[24:25], v0, s14, 0
	v_lshl_add_u64 v[18:19], v[0:1], 2, s[16:17]
	v_mov_b32_e32 v22, v21
	global_load_dwordx4 v[10:13], v[18:19], off
	global_load_dwordx4 v[14:17], v[18:19], off offset:16
	v_mad_u64_u32 v[18:19], s[24:25], v0, s15, v[22:23]
	v_mov_b32_e32 v21, v18
	v_lshl_add_u64 v[18:19], v[20:21], 2, v[4:5]
	v_lshl_add_u64 v[20:21], v[18:19], 0, s[20:21]
	global_load_dword v22, v[18:19], off
	global_load_dword v23, v[20:21], off
	v_lshl_add_u64 v[18:19], v[20:21], 0, s[20:21]
	v_lshl_add_u64 v[20:21], v[18:19], 0, s[20:21]
	global_load_dword v24, v[18:19], off
	global_load_dword v25, v[20:21], off
	v_lshl_add_u64 v[18:19], v[20:21], 0, s[20:21]
	v_lshl_add_u64 v[20:21], v[18:19], 0, s[20:21]
	global_load_dword v26, v[18:19], off
	global_load_dword v27, v[20:21], off
	v_lshl_add_u64 v[18:19], v[20:21], 0, s[20:21]
	v_lshl_add_u64 v[20:21], v[18:19], 0, s[20:21]
	global_load_dword v28, v[18:19], off
	global_load_dword v29, v[20:21], off
	v_add_u32_e32 v9, 0x80, v0
	v_add_u32_e32 v0, 0x88, v0
	v_cmp_lt_i32_e32 vcc, s5, v0
	s_or_b64 s[18:19], vcc, s[18:19]
	v_mov_b32_e32 v0, v9
	s_waitcnt vmcnt(6)
	v_pk_mul_f32 v[10:11], v[22:23], v[10:11]
	s_waitcnt vmcnt(4)
	v_pk_mul_f32 v[12:13], v[24:25], v[12:13]
	v_add_f32_e32 v8, v10, v8
	v_add_f32_e32 v8, v11, v8
	v_add_f32_e32 v8, v12, v8
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[10:11], v[26:27], v[14:15]
	v_add_f32_e32 v8, v13, v8
	v_add_f32_e32 v8, v10, v8
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[12:13], v[28:29], v[16:17]
	v_add_f32_e32 v8, v11, v8
	v_add_f32_e32 v8, v12, v8
	v_add_f32_e32 v8, v13, v8
	s_andn2_b64 exec, exec, s[18:19]
	s_cbranch_execnz .LBB0_12
.Lft7:
	s_or_b64 exec, exec, s[18:19]
	v_mov_b32_e32 v0, v9
	v_mov_b32_e32 v1, v8
.LBB0_14:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_i32_e32 vcc, s5, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_18
.Lft8:
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v4, v0
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[4:5], v[4:5], 2, s[16:17]
	v_mad_u64_u32 v[10:11], s[16:17], s14, v0, 0
	s_ashr_i32 s15, s14, 31
	v_mov_b32_e32 v12, v11
	v_mad_u64_u32 v[12:13], s[16:17], s15, v0, v[12:13]
	v_mov_b32_e32 v11, v12
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	v_lshl_add_u64 v[2:3], v[10:11], 2, v[2:3]
	v_sub_u32_e32 v8, s5, v0
	v_lshl_add_u64 v[2:3], s[12:13], 0, v[2:3]
	s_lshl_b64 s[14:15], s[14:15], 2
	s_mov_b64 s[12:13], 0
	.p2align	5, , 4
.LBB0_16:
	global_load_dword v0, v[4:5], off
	global_load_dword v9, v[2:3], off
	v_add_u32_e32 v8, -1, v8
	v_cmp_eq_u32_e32 vcc, 0, v8
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[14:15]
	s_or_b64 s[12:13], vcc, s[12:13]
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, v0, v9
	s_andn2_b64 exec, exec, s[12:13]
	s_cbranch_execnz .LBB0_16
.Lft9:
	s_or_b64 exec, exec, s[12:13]
.LBB0_18:
	s_or_b64 exec, exec, s[0:1]
.LBB0_19:
	s_or_b64 exec, exec, s[10:11]
	v_lshlrev_b32_e32 v0, 2, v7
	v_cmp_gt_u32_e32 vcc, 64, v7
	ds_write_b32 v0, v1
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_25
.Lft10:
	v_or_b32_e32 v0, s22, v6
	v_cmp_gt_i32_e32 vcc, s4, v0
	s_mov_b64 s[10:11], s[2:3]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_24
.Lft11:
	v_lshlrev_b32_e32 v1, 2, v6
	ds_read2st64_b32 v[2:3], v1 offset1:1
	ds_read2st64_b32 v[4:5], v1 offset0:2 offset1:3
	ds_read2st64_b32 v[6:7], v1 offset0:4 offset1:5
	ds_read2st64_b32 v[8:9], v1 offset0:6 offset1:7
	ds_read2st64_b32 v[10:11], v1 offset0:8 offset1:9
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v2, 0, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v8
	v_add_f32_e32 v8, v2, v9
	ds_read2st64_b32 v[2:3], v1 offset0:10 offset1:11
	ds_read2st64_b32 v[4:5], v1 offset0:12 offset1:13
	ds_read2st64_b32 v[6:7], v1 offset0:14 offset1:15
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v1, v8, v10
	v_add_f32_e32 v1, v1, v11
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v1, v1, v2
	v_add_f32_e32 v1, v1, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v1, v1, v4
	v_add_f32_e32 v1, v1, v5
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v6
	v_add_f32_e32 v1, v1, v7
	v_cmp_eq_f32_e64 s[10:11], s7, 0
	v_mul_f32_e32 v2, s6, v1
	v_ashrrev_i32_e32 v1, 31, v0
	s_and_b64 vcc, exec, s[10:11]
	s_cbranch_vccnz .LBB0_23
.Lft12:
	v_lshl_add_u64 v[4:5], v[0:1], 2, s[8:9]
	global_load_dword v3, v[4:5], off
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, s7, v3
.LBB0_23:
	s_or_b64 s[10:11], s[2:3], exec
.LBB0_24:
	s_or_b64 exec, exec, s[4:5]
	s_andn2_b64 s[2:3], s[2:3], exec
	s_and_b64 s[4:5], s[10:11], exec
	s_or_b64 s[2:3], s[2:3], s[4:5]
.LBB0_25:
	s_or_b64 exec, exec, s[0:1]
.LBB0_26:
	s_and_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execnz .LBB0_28
.Lft13:
	s_endpgm
.LBB0_28:
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 2, s[8:9]
	global_store_dword v[0:1], v2, off
	s_endpgm
.Lfunc_end0:
	.size	rb_gemvn, .Lfunc_end0-rb_gemvn
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_gemvn
		.amdhsa_group_segment_fixed_size 4096
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
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
		.amdhsa_system_vgpr_workitem_id 1
		.amdhsa_next_free_vgpr 30
		.amdhsa_next_free_sgpr 26
		.amdhsa_accum_offset 32
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
  - .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .offset: 24
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .offset: 40
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 48
    .size: 8
    .value_kind: global_buffer
  .gfx1250_revision: B0
  .group_segment_fixed_size: 4096
  .kernarg_segment_align: 8
  .kernarg_segment_size: 56
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: rb_gemvn
  .private_segment_fixed_size: 0
  .sgpr_count: 32
  .sgpr_spill_count: 0
  .symbol: rb_gemvn.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 30
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
