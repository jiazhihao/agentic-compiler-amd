	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	kda_step
	.globl	kda_step
	.p2align	8
	.type	kda_step,@function
kda_step:
	s_load_dwordx8 s[12:19], s[0:1], 0x0
	s_load_dwordx4 s[20:23], s[0:1], 0x38
	s_load_dwordx8 s[4:11], s[0:1], 0x20
	s_waitcnt lgkmcnt(0)
	s_load_dword s23, s[0:1], 0x54
	s_ashr_i32 s3, s2, 31
	v_cmp_le_i32_e32 vcc, s20, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_xor_b64 s[0:1], exec, s[0:1]
	s_ashr_i32 s11, s20, 31
	s_mov_b32 s10, s20
	s_or_saveexec_b64 s[0:1], s[0:1]
	s_waitcnt lgkmcnt(0)
	s_and_b32 s33, s23, 0xffff
	v_mov_b64_e32 v[2:3], s[10:11]
	s_xor_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_6
.Lft0:
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, s2
	s_mul_i32 s23, s20, s3
	v_mad_u64_u32 v[2:3], s[24:25], s20, v2, v[0:1]
	s_mov_b32 s11, 0
	v_add_u32_e32 v3, s23, v3
	s_mov_b32 s23, 0x12c00
	s_mov_b32 s10, s20
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	s_lshl_b32 s24, s33, 2
	s_mov_b32 s25, s11
	v_lshl_add_u32 v1, v0, 2, s23
	s_mov_b64 s[26:27], 0
	s_mov_b32 s23, 0x3fb8aa3b
	s_mov_b32 s28, 0xc2ce8ed0
	s_mov_b32 s29, 0x42b17218
	v_mov_b32_e32 v4, 0x7f800000
	v_mov_b32_e32 v5, v0
	.p2align	5, , 4
.LBB0_4:
	v_lshl_add_u64 v[6:7], s[14:15], 0, v[2:3]
	v_lshl_add_u64 v[8:9], s[16:17], 0, v[2:3]
	v_lshl_add_u64 v[10:11], s[6:7], 0, v[2:3]
	global_load_dword v12, v[6:7], off
	global_load_dword v13, v[10:11], off
	global_load_dword v14, v[8:9], off
	v_add_u32_e32 v5, s33, v5
	v_cmp_le_i32_e32 vcc, s20, v5
	s_or_b64 s[26:27], vcc, s[26:27]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[24:25]
	s_waitcnt vmcnt(2)
	v_mul_f32_e32 v6, 0x3fb8aa3b, v12
	v_fma_f32 v8, v12, s23, -v6
	v_rndne_f32_e32 v9, v6
	v_fmac_f32_e32 v8, 0x32a5705f, v12
	v_sub_f32_e32 v6, v6, v9
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v7, s22, v13
	v_add_f32_e32 v6, v6, v8
	s_waitcnt vmcnt(0)
	ds_write2st64_b32 v1, v14, v7 offset1:4
	v_cvt_i32_f32_e32 v7, v9
	v_exp_f32_e32 v6, v6
	v_cmp_ngt_f32_e32 vcc, s28, v12
	v_ldexp_f32 v6, v6, v7
	s_nop 0
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_cmp_nlt_f32_e32 vcc, s29, v12
	s_nop 1
	v_cndmask_b32_e32 v6, v4, v6, vcc
	ds_write_b32 v1, v6 offset:2048
	v_add_u32_e32 v1, s24, v1
	s_andn2_b64 exec, exec, s[26:27]
	s_cbranch_execnz .LBB0_4
.Lft1:
	s_or_b64 exec, exec, s[26:27]
	v_mov_b64_e32 v[2:3], s[10:11]
.LBB0_6:
	s_or_b64 exec, exec, s[0:1]
	s_mul_i32 s6, s2, s21
	v_mad_u64_u32 v[4:5], s[0:1], s6, v2, 0
	s_ashr_i32 s11, s21, 31
	s_lshl_b64 s[0:1], s[2:3], 2
	s_mul_hi_i32 s7, s2, s21
	s_add_u32 s0, s4, s0
	v_mul_lo_u32 v1, s7, v2
	v_mul_lo_u32 v6, s6, v3
	s_addc_u32 s1, s5, s1
	s_mov_b32 s10, s21
	s_cmp_gt_i32 s21, 3
	v_add3_u32 v5, v5, v6, v1
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc0 .LBB0_8
.Lft2:
	v_lshl_add_u64 v[6:7], v[2:3], 0, 16
	v_mul_lo_u32 v1, v7, s10
	v_mul_lo_u32 v8, v6, s11
	v_mad_u64_u32 v[6:7], s[4:5], v6, s10, 0
	v_add3_u32 v7, v7, v8, v1
	s_mov_b64 s[4:5], 0x4b00
	v_cmp_lt_i64_e32 vcc, s[4:5], v[6:7]
	s_mov_b64 s[14:15], -1
	s_orn2_b64 s[4:5], vcc, exec
	s_branch .LBB0_9
.LBB0_8:
	s_mov_b64 s[4:5], -1
	s_mov_b64 s[14:15], 0
.LBB0_9:
	s_load_dword s38, s[0:1], 0x0
	v_lshl_add_u64 v[4:5], v[4:5], 2, s[12:13]
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_xor_b64 s[16:17], exec, s[0:1]
	s_cbranch_execz .LBB0_31
.Lft3:
	v_cmp_gt_i32_e32 vcc, s21, v0
	s_and_saveexec_b64 s[22:23], vcc
	s_cbranch_execz .LBB0_30
.Lft4:
	v_mul_lo_u32 v1, v3, s2
	v_mul_lo_u32 v8, v2, s3
	v_mad_u64_u32 v[16:17], s[28:29], v2, s2, 0
	v_add3_u32 v17, v17, v8, v1
	v_lshlrev_b64 v[14:15], 2, v[16:17]
	v_lshl_add_u64 v[10:11], v[14:15], 0, 4
	v_mov_b64_e32 v[18:19], s[12:13]
	v_mul_lo_u32 v1, v10, s11
	v_mul_lo_u32 v8, v11, s10
	v_mad_u64_u32 v[10:11], s[28:29], v10, s10, v[18:19]
	v_lshl_add_u64 v[12:13], v[14:15], 0, 8
	s_cmp_gt_i32 s20, 0
	v_add3_u32 v11, v8, v11, v1
	v_mul_lo_u32 v1, v12, s11
	v_mul_lo_u32 v8, v13, s10
	v_mad_u64_u32 v[12:13], s[30:31], v12, s10, v[18:19]
	v_lshl_add_u64 v[14:15], v[14:15], 0, 12
	s_cselect_b64 s[0:1], -1, 0
	s_and_b32 s39, s20, 3
	v_add3_u32 v13, v8, v13, v1
	v_mul_lo_u32 v1, v14, s11
	v_mul_lo_u32 v8, v15, s10
	v_mad_u64_u32 v[14:15], s[30:31], v14, s10, v[18:19]
	s_cmp_gt_u32 s20, 3
	v_mov_b32_e32 v9, 0
	v_add3_u32 v15, v8, v15, v1
	v_mul_lo_u32 v1, v17, s10
	v_mul_lo_u32 v8, v16, s11
	v_mad_u64_u32 v[16:17], s[30:31], v16, s10, 0
	s_cselect_b64 s[4:5], -1, 0
	s_and_b32 s40, s20, 0x7ffffffc
	v_lshlrev_b32_e32 v6, 2, v0
	v_mov_b32_e32 v7, v9
	v_add3_u32 v17, v17, v8, v1
	v_cndmask_b32_e64 v1, 0, 1, s[0:1]
	s_cmp_lg_u32 s39, 0
	v_lshl_add_u64 v[16:17], v[16:17], 2, v[6:7]
	v_cmp_ne_u32_e64 s[0:1], 1, v1
	v_cndmask_b32_e64 v1, 0, 1, s[4:5]
	s_mov_b32 s25, 0
	s_cselect_b64 s[26:27], -1, 0
	s_lshl_b32 s24, s33, 2
	s_lshl_b64 s[28:29], s[10:11], 4
	v_lshl_add_u64 v[16:17], s[12:13], 0, v[16:17]
	s_lshl_b64 s[30:31], s[10:11], 2
	s_mov_b64 s[34:35], 0
	v_cmp_ne_u32_e64 s[4:5], 1, v1
	v_mov_b64_e32 v[18:19], v[4:5]
	v_mov_b32_e32 v8, v0
	s_branch .LBB0_14
.LBB0_12:
	v_mov_b32_e32 v1, 0
.LBB0_13:
	v_add_u32_e32 v8, s33, v8
	v_cmp_le_i32_e32 vcc, s21, v8
	v_lshl_add_u64 v[20:21], v[20:21], 2, s[8:9]
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[24:25]
	v_lshl_add_u64 v[12:13], v[12:13], 0, s[24:25]
	v_lshl_add_u64 v[14:15], v[14:15], 0, s[24:25]
	v_lshl_add_u64 v[18:19], v[18:19], 0, s[24:25]
	s_or_b64 s[34:35], vcc, s[34:35]
	v_lshl_add_u64 v[16:17], v[16:17], 0, s[24:25]
	global_store_dword v[20:21], v1, off
	s_andn2_b64 exec, exec, s[34:35]
	s_cbranch_execz .LBB0_30
.LBB0_14:
	s_and_b64 vcc, exec, s[0:1]
	v_mov_b32_e32 v1, 0
	s_cbranch_vccnz .LBB0_22
.Lft5:
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_19
.Lft6:
	s_mov_b32 s36, 0
	s_mov_b32 s37, 0x12c00
	v_mov_b32_e32 v1, 0
	v_mov_b64_e32 v[20:21], v[18:19]
	v_mov_b64_e32 v[22:23], v[14:15]
	v_mov_b64_e32 v[24:25], v[12:13]
	v_mov_b64_e32 v[26:27], v[10:11]
	.p2align	5, , 4
.LBB0_17:
	v_lshl_add_u64 v[28:29], v[20:21], 0, v[6:7]
	v_lshl_add_u64 v[30:31], v[26:27], 0, v[6:7]
	v_lshl_add_u64 v[32:33], v[24:25], 0, v[6:7]
	v_lshl_add_u64 v[34:35], v[22:23], 0, v[6:7]
	global_load_dword v36, v[28:29], off
	global_load_dword v37, v[30:31], off
	global_load_dword v38, v[32:33], off
	global_load_dword v39, v[34:35], off
	v_mov_b32_e32 v32, s37
	ds_read_b128 v[28:31], v32 offset:2048
	ds_read_b128 v[32:35], v32
	s_add_i32 s36, s36, 4
	s_add_i32 s37, s37, 16
	v_lshl_add_u64 v[26:27], v[26:27], 0, s[28:29]
	v_lshl_add_u64 v[24:25], v[24:25], 0, s[28:29]
	v_lshl_add_u64 v[22:23], v[22:23], 0, s[28:29]
	v_lshl_add_u64 v[20:21], v[20:21], 0, s[28:29]
	s_cmp_eq_u32 s40, s36
	s_waitcnt vmcnt(3) lgkmcnt(0)
	v_mul_f32_e32 v28, v36, v28
	s_waitcnt vmcnt(2)
	v_mul_f32_e32 v29, v37, v29
	v_fmac_f32_e32 v1, v32, v28
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v30, v38, v30
	v_fmac_f32_e32 v1, v33, v29
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v31, v39, v31
	v_fmac_f32_e32 v1, v34, v30
	v_fmac_f32_e32 v1, v35, v31
	s_cbranch_scc0 .LBB0_17
.Lft7:
	s_mov_b32 s41, s40
	s_mov_b64 s[36:37], s[26:27]
	s_and_b64 vcc, exec, s[36:37]
	s_cbranch_vccnz .LBB0_20
.Lft8:
	s_branch .LBB0_22
.LBB0_19:
	s_mov_b32 s41, 0
	v_mov_b32_e32 v1, 0
	s_cbranch_execz .LBB0_22
.LBB0_20:
	v_mov_b32_e32 v20, s41
	v_mad_u64_u32 v[20:21], s[42:43], s30, v20, v[16:17]
	s_mul_i32 s37, s31, s41
	s_lshl2_add_u32 s36, s41, 0x13400
	v_add_u32_e32 v21, s37, v21
	s_mov_b32 s37, s39
	.p2align	5, , 4
.LBB0_21:
	global_load_dword v22, v[20:21], off
	s_add_i32 s41, s36, 0xfffff800
	v_mov_b32_e32 v23, s36
	v_mov_b32_e32 v24, s41
	ds_read_b32 v24, v24
	ds_read_b32 v23, v23
	s_add_i32 s36, s36, 4
	s_add_i32 s37, s37, -1
	v_lshl_add_u64 v[20:21], v[20:21], 0, s[30:31]
	s_cmp_lg_u32 s37, 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_mul_f32_e32 v22, v22, v23
	v_fmac_f32_e32 v1, v24, v22
	s_cbranch_scc1 .LBB0_21
.LBB0_22:
	s_and_b64 vcc, exec, s[0:1]
	v_lshl_add_u64 v[20:21], s[6:7], 0, v[8:9]
	s_cbranch_vccnz .LBB0_12
.Lft9:
	v_lshl_add_u64 v[22:23], v[20:21], 2, s[18:19]
	global_load_dword v22, v[22:23], off
	s_and_b64 vcc, exec, s[4:5]
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v30, v22, v1
	s_cbranch_vccnz .LBB0_27
.Lft10:
	s_mov_b32 s36, 0
	s_mov_b32 s37, 0x12c00
	v_mov_b32_e32 v1, 0
	v_mov_b64_e32 v[22:23], v[18:19]
	v_mov_b64_e32 v[24:25], v[14:15]
	v_mov_b64_e32 v[26:27], v[12:13]
	v_mov_b64_e32 v[28:29], v[10:11]
	.p2align	5, , 4
.LBB0_25:
	v_lshl_add_u64 v[44:45], v[22:23], 0, v[6:7]
	global_load_dword v31, v[44:45], off
	v_mov_b32_e32 v40, s37
	ds_read_b128 v[32:35], v40
	ds_read_b128 v[36:39], v40 offset:2048
	ds_read_b128 v[40:43], v40 offset:1024
	v_lshl_add_u64 v[46:47], v[28:29], 0, v[6:7]
	s_add_i32 s36, s36, 4
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v32, s38, v32
	v_mul_f32_e32 v48, v30, v32
	v_mul_f32_e32 v32, s38, v33
	v_mul_f32_e32 v34, s38, v34
	v_mul_f32_e32 v34, v30, v34
	v_mul_f32_e32 v35, s38, v35
	v_mul_f32_e32 v35, v30, v35
	s_add_i32 s37, s37, 16
	v_lshl_add_u64 v[28:29], v[28:29], 0, s[28:29]
	v_lshl_add_u64 v[22:23], v[22:23], 0, s[28:29]
	s_cmp_eq_u32 s40, s36
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v48, v31, v36
	global_store_dword v[44:45], v48, off
	global_load_dword v31, v[46:47], off
	v_mul_f32_e32 v36, v30, v32
	v_lshl_add_u64 v[44:45], v[26:27], 0, v[6:7]
	v_lshl_add_u64 v[32:33], v[24:25], 0, v[6:7]
	v_fmac_f32_e32 v1, v40, v48
	v_lshl_add_u64 v[26:27], v[26:27], 0, s[28:29]
	v_lshl_add_u64 v[24:25], v[24:25], 0, s[28:29]
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v36, v31, v37
	global_store_dword v[46:47], v36, off
	global_load_dword v31, v[44:45], off
	v_fmac_f32_e32 v1, v41, v36
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v34, v31, v38
	global_store_dword v[44:45], v34, off
	global_load_dword v31, v[32:33], off
	v_fmac_f32_e32 v1, v42, v34
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v35, v31, v39
	v_fmac_f32_e32 v1, v43, v35
	global_store_dword v[32:33], v35, off
	s_cbranch_scc0 .LBB0_25
.Lft11:
	s_mov_b32 s41, s40
	s_mov_b64 s[36:37], s[26:27]
	s_and_b64 vcc, exec, s[36:37]
	s_cbranch_vccz .LBB0_13
.Lft12:
	s_branch .LBB0_28
.LBB0_27:
	s_mov_b32 s41, 0
	v_mov_b32_e32 v1, 0
	s_cbranch_execz .LBB0_13
.LBB0_28:
	v_mov_b32_e32 v22, s41
	v_mad_u64_u32 v[22:23], s[42:43], s30, v22, v[16:17]
	s_mul_i32 s37, s31, s41
	s_lshl2_add_u32 s36, s41, 0x12c00
	v_add_u32_e32 v23, s37, v23
	s_mov_b32 s37, s39
	.p2align	5, , 4
.LBB0_29:
	global_load_dword v26, v[22:23], off
	v_mov_b32_e32 v27, s36
	ds_read2st64_b32 v[24:25], v27 offset1:4
	ds_read_b32 v27, v27 offset:2048
	s_add_i32 s36, s36, 4
	s_add_i32 s37, s37, -1
	s_cmp_lg_u32 s37, 0
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v24, s38, v24
	v_mul_f32_e32 v24, v30, v24
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v24, v26, v27
	global_store_dword v[22:23], v24, off
	v_fmac_f32_e32 v1, v25, v24
	v_lshl_add_u64 v[22:23], v[22:23], 0, s[30:31]
	s_cbranch_scc1 .LBB0_29
.Lft13:
	s_branch .LBB0_13
.LBB0_30:
	s_or_b64 exec, exec, s[22:23]
	s_andn2_b64 s[14:15], s[14:15], exec
.LBB0_31:
	s_or_b64 exec, exec, s[16:17]
	s_and_saveexec_b64 s[0:1], s[14:15]
	s_cbranch_execz .LBB0_57
.Lft14:
	s_add_i32 s0, s21, 3
	s_lshr_b32 s34, s0, 2
	v_cvt_f32_u32_e32 v1, s34
	s_lshl_b32 s35, s34, 3
	s_mul_i32 s0, s21, s20
	s_lshl_b32 s36, s0, 2
	v_rcp_iflag_f32_e32 v67, v1
	s_lshl_b32 s37, s21, 5
	v_cmp_gt_u32_e32 vcc, s35, v0
	v_lshlrev_b32_e32 v1, 2, v0
	v_mul_lo_u32 v3, v3, s2
	v_mul_lo_u32 v66, v2, s3
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_47
.Lft15:
	v_mul_f32_e32 v6, 0x4f7ffffe, v67
	v_cvt_u32_f32_e32 v6, v6
	s_sub_i32 s0, 0, s34
	s_add_i32 s14, s21, -4
	s_lshl_b32 s3, s33, 2
	v_mul_lo_u32 v7, s0, v6
	v_mul_hi_u32 v7, v6, v7
	v_add_u32_e32 v68, v6, v7
	v_mad_u64_u32 v[6:7], s[0:1], v2, s2, 0
	v_add3_u32 v7, v7, v66, v3
	v_lshlrev_b64 v[6:7], 2, v[6:7]
	s_lshl_b32 s39, s34, 2
	s_lshl_b32 s40, s21, 2
	s_ashr_i32 s15, s14, 31
	s_lshl_b64 s[16:17], s[10:11], 5
	v_lshl_add_u64 v[8:9], v[6:7], 0, 4
	v_lshl_add_u64 v[10:11], v[6:7], 0, 8
	v_lshl_add_u64 v[12:13], v[6:7], 0, 12
	v_lshl_add_u64 v[14:15], v[6:7], 0, 28
	v_lshl_add_u64 v[16:17], v[6:7], 0, 16
	v_lshl_add_u64 v[18:19], v[6:7], 0, 24
	v_lshl_add_u64 v[20:21], v[6:7], 0, 20
	s_lshl_b32 s41, s21, 3
	s_lshl_b64 s[22:23], s[10:11], 3
	s_mov_b64 s[24:25], 0
	s_mov_b32 s42, 0x12c00
	v_mov_b32_e32 v69, v1
	v_mov_b32_e32 v70, v0
	s_branch .LBB0_36
	.p2align	5
.LBB0_34:
	s_or_b64 exec, exec, s[28:29]
.LBB0_35:
	s_or_b64 exec, exec, s[26:27]
	v_mul_lo_u32 v22, v71, s21
	v_add_u32_e32 v70, s33, v70
	v_lshl_add_u32 v22, v22, 2, s36
	v_cmp_le_u32_e64 s[0:1], s35, v70
	v_lshl_add_u32 v22, v24, 2, v22
	s_or_b64 s[24:25], s[0:1], s[24:25]
	v_add_u32_e32 v69, s3, v69
	ds_write2_b32 v22, v37, v39 offset1:1
	ds_write2_b32 v22, v33, v35 offset0:2 offset1:3
	s_andn2_b64 exec, exec, s[24:25]
	s_cbranch_execz .LBB0_47
.LBB0_36:
	v_mul_hi_u32 v22, v70, v68
	v_mul_lo_u32 v23, v22, s34
	v_sub_u32_e32 v23, v70, v23
	v_add_u32_e32 v24, 1, v22
	v_cmp_le_u32_e64 s[0:1], s34, v23
	v_mov_b32_e32 v37, 0
	v_mov_b32_e32 v39, 0
	v_cndmask_b32_e64 v22, v22, v24, s[0:1]
	v_subrev_u32_e32 v24, s34, v23
	v_cndmask_b32_e64 v23, v23, v24, s[0:1]
	v_add_u32_e32 v24, 1, v22
	v_cmp_le_u32_e64 s[0:1], s34, v23
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v35, 0
	v_cndmask_b32_e64 v71, v22, v24, s[0:1]
	v_mul_lo_u32 v22, v71, s20
	v_ashrrev_i32_e32 v24, 31, v22
	v_add_u32_e32 v23, s20, v22
	v_lshrrev_b32_e32 v24, 29, v24
	v_add_u32_e32 v22, v22, v24
	v_ashrrev_i32_e32 v24, 31, v23
	v_lshrrev_b32_e32 v24, 29, v24
	v_ashrrev_i32_e32 v22, 3, v22
	v_add_u32_e32 v23, v23, v24
	v_ashrrev_i32_e32 v72, 3, v23
	v_add_u32_e32 v23, 8, v22
	v_cmp_le_i32_e64 s[0:1], v23, v72
	s_and_saveexec_b64 s[26:27], s[0:1]
	s_cbranch_execz .LBB0_40
.Lft16:
	v_mul_lo_u32 v24, s39, v71
	v_sub_u32_e32 v40, v69, v24
	v_lshlrev_b32_e32 v73, 2, v22
	v_min_i32_e32 v24, s14, v40
	v_add_u32_e32 v23, 4, v73
	v_lshlrev_b32_e32 v38, 2, v24
	v_mad_u64_u32 v[24:25], s[0:1], s21, v23, v[38:39]
	v_add_u32_e32 v23, 8, v73
	v_mad_u64_u32 v[26:27], s[0:1], s21, v23, v[38:39]
	v_add_u32_e32 v23, 12, v73
	v_mad_u64_u32 v[28:29], s[0:1], s21, v23, v[38:39]
	v_add_u32_e32 v23, 16, v73
	v_mad_u64_u32 v[30:31], s[0:1], s21, v23, v[38:39]
	v_add_u32_e32 v23, 20, v73
	v_mad_u64_u32 v[32:33], s[0:1], s21, v23, v[38:39]
	v_add_u32_e32 v23, 24, v73
	v_mad_u64_u32 v[34:35], s[0:1], s21, v23, v[38:39]
	v_add_u32_e32 v23, 28, v73
	v_mad_u64_u32 v[36:37], s[0:1], s21, v23, v[38:39]
	v_mad_u64_u32 v[38:39], s[0:1], s40, v22, v[38:39]
	v_ashrrev_i32_e32 v41, 31, v40
	v_mov_b32_e32 v23, s15
	v_cmp_gt_i64_e64 s[0:1], s[14:15], v[40:41]
	v_mov_b64_e32 v[58:59], s[12:13]
	s_mov_b64 s[28:29], 0
	v_cndmask_b32_e64 v41, v23, v41, s[0:1]
	v_mov_b32_e32 v23, s14
	v_cndmask_b32_e64 v40, v23, v40, s[0:1]
	v_ashrrev_i32_e32 v23, 31, v22
	v_lshlrev_b64 v[56:57], 2, v[22:23]
	v_lshl_add_u64 v[42:43], v[6:7], 0, v[56:57]
	v_mul_lo_u32 v23, s10, v43
	v_mul_lo_u32 v25, s11, v42
	v_mad_u64_u32 v[42:43], s[0:1], s10, v42, v[58:59]
	v_lshl_add_u64 v[44:45], v[8:9], 0, v[56:57]
	v_add3_u32 v43, v25, v43, v23
	v_mul_lo_u32 v23, s10, v45
	v_mul_lo_u32 v25, s11, v44
	v_mad_u64_u32 v[44:45], s[0:1], s10, v44, v[58:59]
	v_lshl_add_u64 v[46:47], v[10:11], 0, v[56:57]
	v_add3_u32 v45, v25, v45, v23
	v_mul_lo_u32 v23, s10, v47
	v_mul_lo_u32 v25, s11, v46
	v_mad_u64_u32 v[46:47], s[0:1], s10, v46, v[58:59]
	v_lshl_add_u64 v[48:49], v[12:13], 0, v[56:57]
	v_add3_u32 v47, v25, v47, v23
	v_mul_lo_u32 v23, s10, v49
	v_mul_lo_u32 v25, s11, v48
	v_mad_u64_u32 v[48:49], s[0:1], s10, v48, v[58:59]
	v_lshl_add_u64 v[50:51], v[14:15], 0, v[56:57]
	v_add3_u32 v49, v25, v49, v23
	v_mul_lo_u32 v23, s10, v51
	v_mul_lo_u32 v25, s11, v50
	v_mad_u64_u32 v[50:51], s[0:1], s10, v50, v[58:59]
	v_lshl_add_u64 v[52:53], v[16:17], 0, v[56:57]
	v_add3_u32 v51, v25, v51, v23
	v_mul_lo_u32 v23, s10, v53
	v_mul_lo_u32 v25, s11, v52
	v_mad_u64_u32 v[52:53], s[0:1], s10, v52, v[58:59]
	v_lshl_add_u64 v[54:55], v[18:19], 0, v[56:57]
	v_add3_u32 v53, v25, v53, v23
	v_mul_lo_u32 v23, s10, v55
	v_mul_lo_u32 v25, s11, v54
	v_mad_u64_u32 v[54:55], s[0:1], s10, v54, v[58:59]
	v_lshl_add_u64 v[56:57], v[20:21], 0, v[56:57]
	v_add3_u32 v55, v25, v55, v23
	v_mul_lo_u32 v23, s10, v57
	v_mul_lo_u32 v25, s11, v56
	v_mad_u64_u32 v[56:57], s[0:1], s10, v56, v[58:59]
	v_lshlrev_b64 v[40:41], 2, v[40:41]
	v_add3_u32 v57, v25, v57, v23
	v_mov_b32_e32 v35, 0
	v_mov_b32_e32 v33, 0
	v_mov_b32_e32 v39, 0
	v_mov_b32_e32 v37, 0
	.p2align	5, , 4
.LBB0_38:
	v_lshl_add_u64 v[58:59], v[42:43], 0, v[40:41]
	v_lshl_add_u64 v[62:63], v[46:47], 0, v[40:41]
	v_lshl_add_u64 v[64:65], v[48:49], 0, v[40:41]
	v_lshl_add_u64 v[86:87], v[52:53], 0, v[40:41]
	v_lshl_add_u64 v[90:91], v[56:57], 0, v[40:41]
	v_lshl_add_u64 v[94:95], v[54:55], 0, v[40:41]
	v_lshl_add_u64 v[98:99], v[50:51], 0, v[40:41]
	v_lshl_add_u64 v[60:61], v[44:45], 0, v[40:41]
	global_load_dwordx4 v[74:77], v[58:59], off
	global_load_dwordx4 v[78:81], v[60:61], off
	global_load_dwordx4 v[82:85], v[62:63], off
	s_nop 0
	global_load_dwordx4 v[62:65], v[64:65], off
	s_nop 0
	global_load_dwordx4 v[86:89], v[86:87], off
	s_nop 0
	global_load_dwordx4 v[90:93], v[90:91], off
	s_nop 0
	global_load_dwordx4 v[94:97], v[94:95], off
	s_nop 0
	global_load_dwordx4 v[98:101], v[98:99], off
	v_add_u32_e32 v25, 0x13400, v73
	v_add_u32_e32 v106, 0x12c00, v73
	v_add_u32_e32 v27, 0x12c08, v73
	v_add_u32_e32 v29, 0x13408, v73
	ds_read2_b32 v[102:103], v25 offset1:1
	ds_read2_b32 v[104:105], v29 offset1:1
	ds_read2_b32 v[60:61], v27 offset1:1
	ds_read2_b32 v[106:107], v106 offset1:1
	v_add_u32_e32 v31, 0x13410, v73
	v_add_u32_e32 v112, 0x12c18, v73
	v_add_u32_e32 v110, 0x13418, v73
	v_add_u32_e32 v113, 0x12c10, v73
	ds_read2_b32 v[108:109], v31 offset1:1
	ds_read2_b32 v[110:111], v110 offset1:1
	ds_read2_b32 v[58:59], v112 offset1:1
	ds_read2_b32 v[112:113], v113 offset1:1
	v_add_u32_e32 v23, 8, v22
	v_add_u32_e32 v22, 16, v22
	v_cmp_gt_i32_e64 s[0:1], v22, v72
	v_add_u32_e32 v73, 32, v73
	v_lshl_add_u64 v[42:43], v[42:43], 0, s[16:17]
	v_lshl_add_u64 v[44:45], v[44:45], 0, s[16:17]
	v_lshl_add_u64 v[46:47], v[46:47], 0, s[16:17]
	v_lshl_add_u64 v[48:49], v[48:49], 0, s[16:17]
	v_lshl_add_u64 v[50:51], v[50:51], 0, s[16:17]
	v_lshl_add_u64 v[52:53], v[52:53], 0, s[16:17]
	v_lshl_add_u64 v[54:55], v[54:55], 0, s[16:17]
	v_lshl_add_u64 v[56:57], v[56:57], 0, s[16:17]
	v_mov_b32_e32 v22, v23
	s_or_b64 s[28:29], s[0:1], s[28:29]
	s_waitcnt vmcnt(7) lgkmcnt(0)
	v_mul_f32_e32 v25, v102, v74
	v_mul_f32_e32 v27, v102, v75
	v_mul_f32_e32 v29, v102, v76
	v_mul_f32_e32 v31, v102, v77
	s_waitcnt vmcnt(6)
	v_mul_f32_e32 v74, v103, v78
	v_mul_f32_e32 v75, v103, v79
	v_mul_f32_e32 v76, v103, v80
	v_mul_f32_e32 v77, v103, v81
	v_fmac_f32_e32 v37, v106, v25
	v_fmac_f32_e32 v39, v106, v27
	v_fmac_f32_e32 v33, v106, v29
	v_fmac_f32_e32 v35, v106, v31
	s_waitcnt vmcnt(5)
	v_mul_f32_e32 v78, v104, v82
	v_mul_f32_e32 v79, v104, v83
	v_mul_f32_e32 v80, v104, v84
	v_mul_f32_e32 v81, v104, v85
	v_fmac_f32_e32 v37, v107, v74
	v_fmac_f32_e32 v39, v107, v75
	v_fmac_f32_e32 v33, v107, v76
	v_fmac_f32_e32 v35, v107, v77
	s_waitcnt vmcnt(4)
	v_mul_f32_e32 v62, v105, v62
	v_mul_f32_e32 v63, v105, v63
	v_mul_f32_e32 v64, v105, v64
	v_mul_f32_e32 v65, v105, v65
	v_fmac_f32_e32 v37, v60, v78
	v_fmac_f32_e32 v39, v60, v79
	v_fmac_f32_e32 v33, v60, v80
	v_fmac_f32_e32 v35, v60, v81
	s_waitcnt vmcnt(3)
	v_mul_f32_e32 v82, v108, v86
	v_mul_f32_e32 v83, v108, v87
	v_mul_f32_e32 v84, v108, v88
	v_mul_f32_e32 v85, v108, v89
	v_fmac_f32_e32 v37, v61, v62
	v_fmac_f32_e32 v39, v61, v63
	v_fmac_f32_e32 v33, v61, v64
	v_fmac_f32_e32 v35, v61, v65
	s_waitcnt vmcnt(2)
	v_mul_f32_e32 v86, v109, v90
	v_mul_f32_e32 v87, v109, v91
	v_mul_f32_e32 v88, v109, v92
	v_mul_f32_e32 v89, v109, v93
	v_fmac_f32_e32 v37, v112, v82
	v_fmac_f32_e32 v39, v112, v83
	v_fmac_f32_e32 v33, v112, v84
	v_fmac_f32_e32 v35, v112, v85
	s_waitcnt vmcnt(1)
	v_mul_f32_e32 v90, v110, v94
	v_mul_f32_e32 v91, v110, v95
	v_mul_f32_e32 v92, v110, v96
	v_mul_f32_e32 v93, v110, v97
	v_fmac_f32_e32 v37, v113, v86
	v_fmac_f32_e32 v39, v113, v87
	v_fmac_f32_e32 v33, v113, v88
	v_fmac_f32_e32 v35, v113, v89
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v94, v111, v98
	v_mul_f32_e32 v95, v111, v99
	v_mul_f32_e32 v96, v111, v100
	v_mul_f32_e32 v97, v111, v101
	v_fmac_f32_e32 v37, v58, v90
	v_fmac_f32_e32 v39, v58, v91
	v_fmac_f32_e32 v33, v58, v92
	v_fmac_f32_e32 v35, v58, v93
	ds_write2_b32 v38, v25, v27 offset1:1
	ds_write2_b32 v38, v29, v31 offset0:2 offset1:3
	ds_write2_b32 v24, v74, v75 offset1:1
	ds_write2_b32 v24, v76, v77 offset0:2 offset1:3
	ds_write2_b32 v26, v78, v79 offset1:1
	ds_write2_b32 v26, v80, v81 offset0:2 offset1:3
	ds_write2_b32 v28, v62, v63 offset1:1
	ds_write2_b32 v28, v64, v65 offset0:2 offset1:3
	ds_write2_b32 v30, v82, v83 offset1:1
	ds_write2_b32 v30, v84, v85 offset0:2 offset1:3
	ds_write2_b32 v32, v86, v87 offset1:1
	ds_write2_b32 v32, v88, v89 offset0:2 offset1:3
	ds_write2_b32 v34, v90, v91 offset1:1
	ds_write2_b32 v34, v92, v93 offset0:2 offset1:3
	ds_write2_b32 v36, v94, v95 offset1:1
	ds_write2_b32 v36, v96, v97 offset0:2 offset1:3
	v_add_u32_e32 v24, s37, v24
	v_add_u32_e32 v26, s37, v26
	v_add_u32_e32 v28, s37, v28
	v_add_u32_e32 v30, s37, v30
	v_add_u32_e32 v32, s37, v32
	v_add_u32_e32 v34, s37, v34
	v_add_u32_e32 v36, s37, v36
	v_add_u32_e32 v38, s37, v38
	v_fmac_f32_e32 v37, v59, v94
	v_fmac_f32_e32 v39, v59, v95
	v_fmac_f32_e32 v33, v59, v96
	v_fmac_f32_e32 v35, v59, v97
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB0_38
.Lft17:
	s_or_b64 exec, exec, s[28:29]
	v_mov_b32_e32 v22, v23
.LBB0_40:
	s_or_b64 exec, exec, s[26:27]
	v_mul_lo_u32 v23, v71, s34
	v_sub_u32_e32 v23, v70, v23
	v_lshlrev_b32_e32 v23, 2, v23
	v_min_i32_e32 v24, s14, v23
	v_cmp_gt_i32_e64 s[0:1], v72, v22
	s_and_saveexec_b64 s[26:27], s[0:1]
	s_cbranch_execz .LBB0_35
.Lft18:
	v_ashrrev_i32_e32 v25, 31, v24
	v_lshl_add_u64 v[26:27], v[24:25], 2, v[4:5]
	v_sub_u32_e32 v25, v72, v22
	v_and_b32_e32 v25, 1, v25
	v_add_u32_e32 v23, 1, v22
	v_cmp_eq_u32_e64 s[0:1], 1, v25
	s_and_saveexec_b64 s[28:29], s[0:1]
	s_cbranch_execz .LBB0_43
.Lft19:
	v_mad_i64_i32 v[28:29], s[0:1], v22, s10, 0
	v_lshl_add_u64 v[28:29], v[28:29], 2, v[26:27]
	global_load_dwordx4 v[28:31], v[28:29], off
	v_lshl_add_u32 v25, v22, 2, s42
	ds_read2st64_b32 v[40:41], v25 offset1:8
	v_mul_lo_u32 v22, v22, s21
	v_lshlrev_b32_e32 v22, 2, v22
	v_lshl_add_u32 v22, v24, 2, v22
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_mul_f32_e32 v25, v41, v28
	v_mul_f32_e32 v28, v41, v29
	v_mul_f32_e32 v29, v41, v30
	v_mul_f32_e32 v30, v41, v31
	v_fmac_f32_e32 v37, v40, v25
	v_fmac_f32_e32 v39, v40, v28
	v_fmac_f32_e32 v33, v40, v29
	v_fmac_f32_e32 v35, v40, v30
	ds_write2_b32 v22, v25, v28 offset1:1
	ds_write2_b32 v22, v29, v30 offset0:2 offset1:3
	v_mov_b32_e32 v22, v23
.LBB0_43:
	s_or_b64 exec, exec, s[28:29]
	v_cmp_ne_u32_e64 s[0:1], v72, v23
	s_and_saveexec_b64 s[28:29], s[0:1]
	s_cbranch_execz .LBB0_34
.Lft20:
	v_mul_lo_u32 v28, s39, v71
	v_sub_u32_e32 v40, v69, v28
	v_lshlrev_b32_e32 v34, 2, v22
	v_min_i32_e32 v28, s14, v40
	v_add_u32_e32 v23, 4, v34
	v_lshlrev_b32_e32 v30, 2, v28
	v_mad_u64_u32 v[28:29], s[0:1], s21, v23, v[30:31]
	v_mad_u64_u32 v[30:31], s[0:1], s40, v22, v[30:31]
	v_ashrrev_i32_e32 v41, 31, v40
	v_mov_b32_e32 v29, s15
	v_cmp_gt_i64_e64 s[0:1], s[14:15], v[40:41]
	v_ashrrev_i32_e32 v23, 31, v22
	v_add_u32_e32 v32, 1, v22
	v_cndmask_b32_e64 v41, v29, v41, s[0:1]
	v_mov_b32_e32 v29, s14
	v_cndmask_b32_e64 v40, v29, v40, s[0:1]
	v_lshl_add_u64 v[22:23], v[22:23], 2, v[6:7]
	v_lshlrev_b64 v[40:41], 2, v[40:41]
	v_mad_u64_u32 v[40:41], s[0:1], s10, v22, v[40:41]
	v_mul_lo_u32 v23, s10, v23
	v_mul_lo_u32 v22, s11, v22
	v_add3_u32 v41, v22, v41, v23
	v_sub_u32_e32 v25, 0, v72
	v_lshl_add_u64 v[22:23], s[12:13], 0, v[40:41]
	s_mov_b64 s[30:31], 0
	.p2align	5, , 4
.LBB0_45:
	v_mad_i64_i32 v[44:45], s[0:1], v32, s10, 0
	global_load_dwordx4 v[40:43], v[22:23], off
	v_lshl_add_u64 v[44:45], v[44:45], 2, v[26:27]
	global_load_dwordx4 v[44:47], v[44:45], off
	v_add_u32_e32 v31, 0x13400, v34
	v_add_u32_e32 v29, 0x12c00, v34
	ds_read2_b32 v[48:49], v31 offset1:1
	ds_read2_b32 v[50:51], v29 offset1:1
	v_add_u32_e32 v32, 2, v32
	v_add_u32_e32 v29, v25, v32
	v_cmp_eq_u32_e64 s[0:1], 1, v29
	v_add_u32_e32 v34, 8, v34
	v_lshl_add_u64 v[22:23], v[22:23], 0, s[22:23]
	s_or_b64 s[30:31], s[0:1], s[30:31]
	s_waitcnt vmcnt(1) lgkmcnt(0)
	v_mul_f32_e32 v29, v48, v40
	v_mul_f32_e32 v31, v48, v41
	v_mul_f32_e32 v36, v48, v42
	v_mul_f32_e32 v38, v48, v43
	v_fmac_f32_e32 v37, v50, v29
	v_fmac_f32_e32 v39, v50, v31
	v_fmac_f32_e32 v33, v50, v36
	v_fmac_f32_e32 v35, v50, v38
	ds_write2_b32 v30, v29, v31 offset1:1
	ds_write2_b32 v30, v36, v38 offset0:2 offset1:3
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v29, v49, v44
	v_mul_f32_e32 v31, v49, v45
	v_mul_f32_e32 v36, v49, v46
	v_mul_f32_e32 v38, v49, v47
	v_add_u32_e32 v30, s41, v30
	v_fmac_f32_e32 v37, v51, v29
	v_fmac_f32_e32 v39, v51, v31
	v_fmac_f32_e32 v33, v51, v36
	v_fmac_f32_e32 v35, v51, v38
	ds_write2_b32 v28, v29, v31 offset1:1
	ds_write2_b32 v28, v36, v38 offset0:2 offset1:3
	v_add_u32_e32 v28, s41, v28
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB0_45
.Lft21:
	s_or_b64 exec, exec, s[30:31]
	s_branch .LBB0_34
.LBB0_47:
	s_or_b64 exec, exec, s[4:5]
	s_add_i32 s24, s36, s37
	s_mul_i32 s25, s21, 12
	s_mul_i32 s26, s21, 20
	s_mul_i32 s27, s21, 24
	s_mul_i32 s28, s21, 28
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_54
.Lft22:
	v_mul_f32_e32 v4, 0x4f7ffffe, v67
	v_cvt_u32_f32_e32 v4, v4
	s_add_i32 s4, s21, -4
	s_lshl_b64 s[14:15], s[6:7], 2
	s_add_u32 s14, s18, s14
	s_addc_u32 s15, s19, s15
	s_sub_i32 s3, 0, s34
	v_mul_lo_u32 v5, s3, v4
	v_mul_hi_u32 v5, v4, v5
	v_add_u32_e32 v8, v4, v5
	v_mad_u64_u32 v[4:5], s[2:3], v2, s2, 0
	v_add3_u32 v5, v5, v66, v3
	s_lshl_b32 s29, s21, 3
	s_lshl_b32 s30, s21, 4
	s_lshl_b32 s31, s21, 2
	s_lshl_b32 s37, s33, 2
	s_lshl_b32 s39, s34, 2
	v_lshlrev_b64 v[2:3], 2, v[4:5]
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[2:3], s[10:11], 2
	s_mov_b64 s[16:17], 0
	s_mov_b32 s40, 0x12c00
	v_mov_b32_e32 v9, v1
	v_mov_b32_e32 v10, v0
	s_branch .LBB0_50
	.p2align	5
.LBB0_49:
	s_or_b64 exec, exec, s[18:19]
	v_mul_lo_u32 v5, v11, s21
	v_add_u32_e32 v10, s33, v10
	v_lshl_add_u32 v5, v5, 2, s24
	v_cmp_le_u32_e32 vcc, s35, v10
	v_lshl_add_u32 v4, v4, 2, v5
	s_or_b64 s[16:17], vcc, s[16:17]
	v_add_u32_e32 v9, s37, v9
	ds_write2_b32 v4, v14, v17 offset1:1
	ds_write2_b32 v4, v15, v16 offset0:2 offset1:3
	s_andn2_b64 exec, exec, s[16:17]
	s_cbranch_execz .LBB0_54
.LBB0_50:
	v_mul_hi_u32 v4, v10, v8
	v_mul_lo_u32 v5, v4, s34
	v_sub_u32_e32 v5, v10, v5
	v_add_u32_e32 v6, 1, v4
	v_cmp_le_u32_e32 vcc, s34, v5
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v17, 0
	v_cndmask_b32_e32 v4, v4, v6, vcc
	v_subrev_u32_e32 v6, s34, v5
	v_cndmask_b32_e32 v5, v5, v6, vcc
	v_add_u32_e32 v6, 1, v4
	v_cmp_le_u32_e32 vcc, s34, v5
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v16, 0
	v_cndmask_b32_e32 v11, v4, v6, vcc
	v_mul_lo_u32 v5, v11, s20
	v_ashrrev_i32_e32 v6, 31, v5
	v_lshrrev_b32_e32 v6, 29, v6
	v_add_u32_e32 v7, s20, v5
	v_add_u32_e32 v5, v5, v6
	v_ashrrev_i32_e32 v6, 3, v5
	v_ashrrev_i32_e32 v5, 31, v7
	v_mul_lo_u32 v4, v11, s34
	v_lshrrev_b32_e32 v5, 29, v5
	v_sub_u32_e32 v4, v10, v4
	v_add_u32_e32 v5, v7, v5
	v_lshlrev_b32_e32 v4, 2, v4
	v_ashrrev_i32_e32 v7, 3, v5
	v_min_i32_e32 v4, s4, v4
	v_cmp_gt_i32_e32 vcc, v7, v6
	s_and_saveexec_b64 s[18:19], vcc
	s_cbranch_execz .LBB0_49
.Lft23:
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[12:13], v[4:5], 2, s[14:15]
	global_load_dwordx4 v[14:17], v[12:13], off
	v_lshl_add_u32 v13, v4, 2, s36
	v_mul_lo_u32 v18, s39, v11
	v_lshl_add_u32 v19, s21, 2, v13
	v_add_u32_e32 v30, s29, v13
	v_add_u32_e32 v34, s25, v13
	v_add_u32_e32 v38, s30, v13
	v_add_u32_e32 v42, s26, v13
	v_add_u32_e32 v46, s27, v13
	v_add_u32_e32 v50, s28, v13
	v_sub_u32_e32 v18, v9, v18
	ds_read2_b32 v[20:21], v13 offset1:1
	ds_read2_b32 v[22:23], v13 offset0:2 offset1:3
	ds_read2_b32 v[24:25], v19 offset1:1
	ds_read2_b32 v[26:27], v19 offset0:2 offset1:3
	ds_read2_b32 v[28:29], v30 offset1:1
	ds_read2_b32 v[30:31], v30 offset0:2 offset1:3
	ds_read2_b32 v[32:33], v34 offset1:1
	ds_read2_b32 v[34:35], v34 offset0:2 offset1:3
	ds_read2_b32 v[36:37], v38 offset1:1
	ds_read2_b32 v[38:39], v38 offset0:2 offset1:3
	ds_read2_b32 v[40:41], v42 offset1:1
	ds_read2_b32 v[42:43], v42 offset0:2 offset1:3
	ds_read2_b32 v[44:45], v46 offset1:1
	ds_read2_b32 v[46:47], v46 offset0:2 offset1:3
	ds_read2_b32 v[48:49], v50 offset1:1
	ds_read2_b32 v[50:51], v50 offset0:2 offset1:3
	v_ashrrev_i32_e32 v19, 31, v18
	v_mov_b32_e32 v53, s5
	v_mov_b32_e32 v54, s4
	v_cmp_gt_i64_e32 vcc, s[4:5], v[18:19]
	v_sub_u32_e32 v5, v7, v6
	v_ashrrev_i32_e32 v7, 31, v6
	v_min_i32_e32 v13, s4, v18
	v_cndmask_b32_e32 v19, v53, v19, vcc
	v_cndmask_b32_e32 v18, v54, v18, vcc
	v_lshl_add_u32 v12, v6, 2, s40
	v_mul_lo_u32 v52, s31, v6
	v_lshl_add_u64 v[6:7], v[6:7], 2, v[2:3]
	v_lshlrev_b64 v[18:19], 2, v[18:19]
	s_waitcnt lgkmcnt(14)
	v_add_f32_e32 v20, 0, v20
	v_add_f32_e32 v21, 0, v21
	v_add_f32_e32 v22, 0, v22
	v_add_f32_e32 v23, 0, v23
	v_mul_lo_u32 v55, s10, v7
	v_mul_lo_u32 v56, s11, v6
	v_mad_u64_u32 v[6:7], s[22:23], s10, v6, v[18:19]
	s_waitcnt lgkmcnt(13)
	v_add_f32_e32 v18, v20, v24
	v_add_f32_e32 v19, v21, v25
	s_waitcnt lgkmcnt(12)
	v_add_f32_e32 v20, v22, v26
	v_add_f32_e32 v21, v23, v27
	s_waitcnt lgkmcnt(11)
	v_add_f32_e32 v18, v18, v28
	v_add_f32_e32 v19, v19, v29
	s_waitcnt lgkmcnt(10)
	v_add_f32_e32 v20, v20, v30
	v_add_f32_e32 v21, v21, v31
	s_waitcnt lgkmcnt(9)
	v_add_f32_e32 v18, v18, v32
	v_add_f32_e32 v19, v19, v33
	s_waitcnt lgkmcnt(8)
	v_add_f32_e32 v20, v20, v34
	v_add_f32_e32 v21, v21, v35
	s_waitcnt lgkmcnt(7)
	v_add_f32_e32 v18, v18, v36
	v_add_f32_e32 v19, v19, v37
	s_waitcnt lgkmcnt(6)
	v_add_f32_e32 v20, v20, v38
	v_add_f32_e32 v21, v21, v39
	s_waitcnt lgkmcnt(5)
	v_add_f32_e32 v18, v18, v40
	v_add_f32_e32 v19, v19, v41
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v20, v20, v42
	v_add_f32_e32 v21, v21, v43
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v18, v18, v44
	v_add_f32_e32 v19, v19, v45
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v20, v20, v46
	v_add_f32_e32 v21, v21, v47
	v_add3_u32 v7, v56, v7, v55
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v18, v18, v48
	v_add_f32_e32 v19, v19, v49
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v20, v20, v50
	v_add_f32_e32 v21, v21, v51
	v_lshl_add_u32 v13, v13, 2, v52
	v_lshl_add_u64 v[6:7], s[12:13], 0, v[6:7]
	s_mov_b64 s[22:23], 0
	s_waitcnt vmcnt(0)
	v_sub_f32_e32 v18, v14, v18
	v_sub_f32_e32 v19, v15, v19
	v_sub_f32_e32 v20, v16, v20
	v_sub_f32_e32 v21, v17, v21
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v14, 0
	.p2align	5, , 4
.LBB0_52:
	ds_read2_b32 v[22:23], v13 offset1:1
	ds_read2_b32 v[24:25], v13 offset0:2 offset1:3
	ds_read2st64_b32 v[26:27], v12 offset1:4
	v_add_u32_e32 v5, -1, v5
	v_cmp_eq_u32_e32 vcc, 0, v5
	v_add_u32_e32 v12, 4, v12
	v_add_u32_e32 v13, s31, v13
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v26, s38, v26
	v_fma_f32 v22, v26, v18, v22
	v_fmac_f32_e32 v23, v26, v19
	v_fma_f32 v24, v26, v20, v24
	v_fmac_f32_e32 v25, v26, v21
	s_or_b64 s[22:23], vcc, s[22:23]
	v_fmac_f32_e32 v14, v27, v22
	v_fmac_f32_e32 v17, v27, v23
	v_fmac_f32_e32 v15, v27, v24
	v_fmac_f32_e32 v16, v27, v25
	global_store_dwordx4 v[6:7], v[22:25], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[2:3]
	s_andn2_b64 exec, exec, s[22:23]
	s_cbranch_execnz .LBB0_52
.Lft24:
	s_or_b64 exec, exec, s[22:23]
	s_branch .LBB0_49
.LBB0_54:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, s34, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_57
.Lft25:
	s_add_i32 s4, s21, -4
	s_lshl_b64 s[0:1], s[6:7], 2
	s_add_u32 s0, s8, s0
	s_addc_u32 s1, s9, s1
	s_lshl_b32 s5, s21, 3
	s_lshl_b32 s6, s21, 4
	s_lshl_b32 s7, s33, 2
	s_mov_b64 s[2:3], 0
.LBB0_56:
	v_min_i32_e32 v2, s4, v1
	v_lshl_add_u32 v4, v2, 2, s24
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u32 v10, s21, 2, v4
	v_add_u32_e32 v14, s5, v4
	v_add_u32_e32 v18, s25, v4
	v_add_u32_e32 v22, s6, v4
	v_add_u32_e32 v26, s26, v4
	v_add_u32_e32 v30, s27, v4
	v_add_u32_e32 v34, s28, v4
	v_lshl_add_u64 v[6:7], v[2:3], 2, s[0:1]
	ds_read2_b32 v[2:3], v4 offset1:1
	ds_read2_b32 v[4:5], v4 offset0:2 offset1:3
	ds_read2_b32 v[8:9], v10 offset1:1
	ds_read2_b32 v[10:11], v10 offset0:2 offset1:3
	ds_read2_b32 v[12:13], v14 offset1:1
	ds_read2_b32 v[14:15], v14 offset0:2 offset1:3
	ds_read2_b32 v[16:17], v18 offset1:1
	ds_read2_b32 v[18:19], v18 offset0:2 offset1:3
	ds_read2_b32 v[20:21], v22 offset1:1
	ds_read2_b32 v[22:23], v22 offset0:2 offset1:3
	ds_read2_b32 v[24:25], v26 offset1:1
	ds_read2_b32 v[26:27], v26 offset0:2 offset1:3
	ds_read2_b32 v[28:29], v30 offset1:1
	ds_read2_b32 v[30:31], v30 offset0:2 offset1:3
	ds_read2_b32 v[32:33], v34 offset1:1
	ds_read2_b32 v[34:35], v34 offset0:2 offset1:3
	s_waitcnt lgkmcnt(14)
	v_add_f32_e32 v2, 0, v2
	v_add_f32_e32 v3, 0, v3
	v_add_f32_e32 v4, 0, v4
	v_add_f32_e32 v5, 0, v5
	s_waitcnt lgkmcnt(13)
	v_add_f32_e32 v2, v8, v2
	v_add_f32_e32 v3, v9, v3
	s_waitcnt lgkmcnt(12)
	v_add_f32_e32 v4, v10, v4
	v_add_f32_e32 v5, v11, v5
	s_waitcnt lgkmcnt(11)
	v_add_f32_e32 v2, v12, v2
	v_add_f32_e32 v3, v13, v3
	s_waitcnt lgkmcnt(10)
	v_add_f32_e32 v4, v14, v4
	v_add_f32_e32 v5, v15, v5
	s_waitcnt lgkmcnt(9)
	v_add_f32_e32 v2, v16, v2
	v_add_f32_e32 v3, v17, v3
	s_waitcnt lgkmcnt(8)
	v_add_f32_e32 v4, v18, v4
	v_add_f32_e32 v5, v19, v5
	s_waitcnt lgkmcnt(7)
	v_add_f32_e32 v2, v20, v2
	v_add_f32_e32 v3, v21, v3
	s_waitcnt lgkmcnt(6)
	v_add_f32_e32 v4, v22, v4
	v_add_f32_e32 v5, v23, v5
	v_add_u32_e32 v0, s33, v0
	s_waitcnt lgkmcnt(5)
	v_add_f32_e32 v2, v24, v2
	v_add_f32_e32 v3, v25, v3
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v4, v26, v4
	v_add_f32_e32 v5, v27, v5
	v_cmp_le_u32_e32 vcc, s34, v0
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v2, v28, v2
	v_add_f32_e32 v3, v29, v3
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, v30, v4
	v_add_f32_e32 v5, v31, v5
	v_add_u32_e32 v1, s7, v1
	s_or_b64 s[2:3], vcc, s[2:3]
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v32, v2
	v_add_f32_e32 v3, v33, v3
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v34, v4
	v_add_f32_e32 v5, v35, v5
	global_store_dwordx4 v[6:7], v[2:5], off
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB0_56
.LBB0_57:
	s_endpgm
.Lfunc_end0:
	.size	kda_step, .Lfunc_end0-kda_step
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel kda_step
		.amdhsa_group_segment_fixed_size 79872
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 328
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
		.amdhsa_next_free_vgpr 114
		.amdhsa_next_free_sgpr 44
		.amdhsa_accum_offset 116
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
  - .address_space: global
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
  - .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 40
    .size: 8
    .value_kind: global_buffer
  - .address_space: global
    .offset: 48
    .size: 8
    .value_kind: global_buffer
  - .offset: 56
    .size: 4
    .value_kind: by_value
  - .offset: 60
    .size: 4
    .value_kind: by_value
  - .offset: 64
    .size: 4
    .value_kind: by_value
  - .offset: 72
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 76
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 80
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 84
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 86
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 88
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 90
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 92
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 94
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 112
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 120
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 128
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 136
    .size: 2
    .value_kind: hidden_grid_dims
  .gfx1250_revision: B0
  .group_segment_fixed_size: 79872
  .kernarg_segment_align: 8
  .kernarg_segment_size: 328
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: kda_step
  .private_segment_fixed_size: 0
  .sgpr_count: 50
  .sgpr_spill_count: 0
  .symbol: kda_step.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 114
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
