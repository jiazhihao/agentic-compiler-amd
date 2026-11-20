	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	vl_moe_align
	.globl	vl_moe_align
	.p2align	8
	.type	vl_moe_align,@function
vl_moe_align:
	s_load_dwordx8 s[12:19], s[0:1], 0x28
	s_load_dwordx8 s[4:11], s[0:1], 0x0
	s_load_dwordx2 s[20:21], s[0:1], 0x20
	s_load_dword s44, s[0:1], 0x48
	s_mov_b32 s3, 0
	s_waitcnt lgkmcnt(0)
	s_abs_i32 s33, s15
	v_cvt_f32_u32_e32 v1, s33
	s_cmp_eq_u32 s2, 0
	v_rcp_iflag_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_nop 0
	v_readfirstlane_b32 s45, v1
	s_cbranch_scc1 .LBB0_14
.Lft0:
	s_load_dword s22, s[0:1], 0x64
	s_add_i32 s2, s2, -1
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, s2
	s_waitcnt lgkmcnt(0)
	s_and_b32 s2, s22, 0xffff
	v_mad_u64_u32 v[2:3], s[22:23], s2, v2, v[0:1]
	v_lshlrev_b64 v[2:3], 2, v[2:3]
	s_max_i32 s2, s44, 0
	v_lshl_add_u64 v[4:5], v[2:3], 0, 4
	v_cmp_ge_u64_e32 vcc, s[2:3], v[4:5]
	s_and_saveexec_b64 s[22:23], vcc
	s_xor_b64 s[22:23], exec, s[22:23]
	s_cbranch_execz .LBB0_3
.Lft1:
	v_mov_b32_e32 v4, s16
	v_mov_b32_e32 v5, s16
	v_mov_b32_e32 v6, s16
	v_mov_b32_e32 v7, s16
	v_lshl_add_u64 v[2:3], v[2:3], 2, s[6:7]
	global_store_dwordx4 v[2:3], v[4:7], off
.LBB0_3:
	s_andn2_saveexec_b64 s[22:23], s[22:23]
	s_cbranch_execz .LBB0_13
.Lft2:
	v_cmp_gt_u64_e32 vcc, s[2:3], v[2:3]
	s_and_saveexec_b64 s[24:25], vcc
	s_cbranch_execz .LBB0_12
.Lft3:
	v_sub_co_u32_e32 v4, vcc, s2, v2
	s_mov_b64 s[28:29], -1
	s_nop 0
	v_subb_co_u32_e32 v5, vcc, 0, v3, vcc
	v_cmp_lt_u64_e32 vcc, 1, v[4:5]
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_9
.Lft4:
	s_and_b32 s28, s2, 1
	v_subrev_co_u32_e32 v4, vcc, s28, v4
	s_mov_b32 s34, s16
	s_nop 0
	v_subbrev_co_u32_e32 v5, vcc, 0, v5, vcc
	s_mov_b32 s35, s16
	s_mov_b32 s29, 0
	v_lshl_add_u64 v[6:7], v[2:3], 2, s[6:7]
	s_mov_b64 s[30:31], 0
	v_mov_b64_e32 v[10:11], s[34:35]
	v_mov_b64_e32 v[8:9], v[4:5]
	.p2align	5, , 4
.LBB0_7:
	v_lshl_add_u64 v[8:9], v[8:9], 0, -2
	v_cmp_eq_u64_e32 vcc, 0, v[8:9]
	global_store_dwordx2 v[6:7], v[10:11], off
	s_or_b64 s[30:31], vcc, s[30:31]
	v_lshl_add_u64 v[6:7], v[6:7], 0, 8
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB0_7
.Lft5:
	s_or_b64 exec, exec, s[30:31]
	s_cmp_lg_u64 s[28:29], 0
	s_cselect_b64 s[28:29], -1, 0
	v_lshl_add_u64 v[2:3], v[2:3], 0, v[4:5]
	s_orn2_b64 s[28:29], s[28:29], exec
.LBB0_9:
	s_or_b64 exec, exec, s[26:27]
	s_and_b64 exec, exec, s[28:29]
	s_cbranch_execz .LBB0_12
.Lft6:
	v_lshl_add_u64 v[4:5], v[2:3], 2, s[6:7]
	s_mov_b64 s[6:7], 0
	v_mov_b32_e32 v1, s16
	.p2align	5, , 4
.LBB0_11:
	v_lshl_add_u64 v[2:3], v[2:3], 0, 1
	v_cmp_le_u64_e32 vcc, s[2:3], v[2:3]
	global_store_dword v[4:5], v1, off
	s_or_b64 s[6:7], vcc, s[6:7]
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_11
.LBB0_12:
	s_or_b64 exec, exec, s[24:25]
.LBB0_13:
	s_or_b64 exec, exec, s[22:23]
	s_cbranch_execz .LBB0_15
.Lft7:
	s_branch .LBB0_92
.LBB0_14:
.LBB0_15:
	s_sub_i32 s22, 0, s33
	s_cmp_lt_i32 s14, 1
	s_mul_i32 s22, s22, s45
	s_cbranch_scc1 .LBB0_50
.Lft8:
	v_lshrrev_b32_e32 v1, 6, v0
	v_mul_lo_u32 v9, s14, v1
	s_cmp_eq_u32 s14, 1
	s_mov_b32 s25, 1
	s_cbranch_scc1 .LBB0_36
.Lft9:
	s_add_i32 s3, s14, -2
	s_lshr_b32 s2, s3, 1
	s_add_i32 s2, s2, 1
	s_and_b32 s23, s2, 3
	s_cmp_lt_u32 s3, 6
	s_mov_b32 s24, 0
	s_cbranch_scc1 .LBB0_37
.Lft10:
	v_add_u32_e32 v2, 2, v9
	v_add_u32_e32 v4, 4, v9
	v_add_u32_e32 v6, 6, v9
	s_and_b32 s26, s2, -4
	v_mov_b32_e32 v1, v2
	v_mov_b32_e32 v3, v4
	v_mov_b32_e32 v5, v6
	s_movk_i32 s27, 0x1080
	v_mov_b32_e32 v10, 0
	s_branch .LBB0_20
.LBB0_19:
	s_or_b64 exec, exec, s[2:3]
	s_add_i32 s25, s25, 8
	s_add_i32 s24, s24, 8
	s_add_i32 s26, s26, -4
	s_cmp_lg_u32 s26, 0
	s_cbranch_scc0 .LBB0_38
.LBB0_20:
	v_add_u32_e32 v7, s25, v9
	v_add_u32_e32 v8, s24, v9
	v_cmp_gt_i32_e32 vcc, s13, v7
	v_cmp_gt_i32_e64 s[2:3], s13, v8
	s_and_saveexec_b64 s[6:7], s[2:3]
	v_lshl_add_u32 v8, v8, 2, s27
	ds_write_b32 v8, v10
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[2:3], vcc
	v_lshl_add_u32 v7, v7, 2, s27
	ds_write_b32 v7, v10
	s_or_b64 exec, exec, s[2:3]
	v_add_u32_e32 v7, s25, v1
	v_add_u32_e32 v8, s24, v2
	v_cmp_gt_i32_e32 vcc, s13, v7
	v_cmp_gt_i32_e64 s[2:3], s13, v8
	s_and_saveexec_b64 s[6:7], s[2:3]
	v_lshl_add_u32 v8, v8, 2, s27
	ds_write_b32 v8, v10
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[2:3], vcc
	v_lshl_add_u32 v7, v7, 2, s27
	ds_write_b32 v7, v10
	s_or_b64 exec, exec, s[2:3]
	v_add_u32_e32 v7, s25, v3
	v_add_u32_e32 v8, s24, v4
	v_cmp_gt_i32_e32 vcc, s13, v7
	v_cmp_gt_i32_e64 s[2:3], s13, v8
	s_and_saveexec_b64 s[6:7], s[2:3]
	v_lshl_add_u32 v8, v8, 2, s27
	ds_write_b32 v8, v10
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[2:3], vcc
	v_lshl_add_u32 v7, v7, 2, s27
	ds_write_b32 v7, v10
	s_or_b64 exec, exec, s[2:3]
	v_add_u32_e32 v7, s25, v5
	v_add_u32_e32 v8, s24, v6
	v_cmp_gt_i32_e32 vcc, s13, v7
	v_cmp_gt_i32_e64 s[2:3], s13, v8
	s_and_saveexec_b64 s[6:7], s[2:3]
	v_lshl_add_u32 v8, v8, 2, s27
	ds_write_b32 v8, v10
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_19
.Lft11:
	v_lshl_add_u32 v7, v7, 2, s27
	ds_write_b32 v7, v10
	s_branch .LBB0_19
.LBB0_36:
	s_mov_b32 s7, 0
	s_cbranch_execnz .LBB0_46
.Lft12:
	s_branch .LBB0_50
.LBB0_37:
	s_cbranch_execnz .LBB0_39
.Lft13:
	s_branch .LBB0_45
.LBB0_38:
	s_cmp_lg_u32 s23, 0
	s_cselect_b64 s[2:3], -1, 0
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_45
.LBB0_39:
	s_movk_i32 s26, 0x1080
	v_mov_b32_e32 v3, 0
	s_branch .LBB0_41
.LBB0_40:
	s_or_b64 exec, exec, s[2:3]
	s_add_i32 s25, s25, 2
	s_add_i32 s24, s24, 2
	s_add_i32 s23, s23, -1
	s_cmp_lg_u32 s23, 0
	s_cbranch_scc0 .LBB0_45
.LBB0_41:
	v_add_u32_e32 v1, s25, v9
	v_add_u32_e32 v2, s24, v9
	v_cmp_gt_i32_e32 vcc, s13, v1
	v_cmp_gt_i32_e64 s[2:3], s13, v2
	s_and_saveexec_b64 s[6:7], s[2:3]
	v_lshl_add_u32 v2, v2, 2, s26
	ds_write_b32 v2, v3
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_40
.Lft14:
	v_lshl_add_u32 v1, v1, 2, s26
	ds_write_b32 v1, v3
	s_branch .LBB0_40
.LBB0_45:
	s_and_b32 s7, s14, 0x7ffffffe
	s_cmp_lg_u32 s14, s7
	s_cselect_b64 s[2:3], -1, 0
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_50
.LBB0_46:
	v_add_u32_e32 v1, s7, v9
	s_movk_i32 s2, 0x1080
	s_sub_i32 s6, s14, s7
	v_lshl_add_u32 v2, v1, 2, s2
	v_mov_b32_e32 v3, 0
	s_branch .LBB0_48
.LBB0_47:
	s_or_b64 exec, exec, s[2:3]
	s_add_i32 s6, s6, -1
	v_add_u32_e32 v2, 4, v2
	s_cmp_eq_u32 s6, 0
	v_add_u32_e32 v1, 1, v1
	s_cbranch_scc1 .LBB0_50
.LBB0_48:
	v_cmp_gt_i32_e32 vcc, s13, v1
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_47
.Lft15:
	ds_write_b32 v2, v3
	s_branch .LBB0_47
.LBB0_50:
	s_load_dword s2, s[0:1], 0x50
	s_load_dword s6, s[0:1], 0x64
	s_max_i32 s14, s12, 0
	s_mul_hi_u32 s46, s45, s22
	s_mov_b32 s3, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s0, s2, 1
	s_and_b32 s2, s6, 0xffff
	s_cmp_eq_u32 s0, 0
	v_mov_b32_e32 v1, 0
	s_mov_b64 s[0:1], -1
	s_barrier
	s_cbranch_scc0 .LBB0_62
.Lft16:
	s_max_i32 s0, s13, 0
	s_mul_i32 s22, s2, 7
	s_max_u32 s13, s14, s0
	s_lshr_b64 s[0:1], s[16:17], 2
	v_add_u32_e32 v10, s22, v0
	v_mov_b32_e32 v11, v1
	v_cmp_gt_u64_e32 vcc, s[0:1], v[10:11]
	v_mov_b64_e32 v[6:7], v[0:1]
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_55
.Lft17:
	s_mov_b32 s23, 0
	v_lshlrev_b32_e32 v2, 4, v0
	v_mov_b32_e32 v3, 0
	s_lshl_b32 s24, s2, 5
	s_mov_b32 s25, s23
	s_mul_i32 s26, s2, 48
	s_mov_b32 s27, s23
	s_lshl_b32 s28, s2, 3
	s_mov_b32 s29, s23
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[2:3]
	s_lshl_b32 s30, s2, 7
	s_mov_b32 s31, s23
	s_lshl_b32 s34, s2, 4
	s_mov_b32 s35, s23
	s_lshl_b32 s36, s2, 6
	s_mov_b32 s37, s23
	s_mul_i32 s38, s2, 0x60
	s_mov_b32 s39, s23
	s_mul_i32 s40, s2, 0x50
	s_mov_b32 s41, s23
	s_mov_b64 s[42:43], 0
	s_movk_i32 s47, 0x1080
	v_mov_b32_e32 v12, 1
	v_mov_b64_e32 v[6:7], v[0:1]
	.p2align	5, , 4
.LBB0_53:
	global_load_dwordx4 v[2:5], v[8:9], off
	v_lshl_add_u64 v[42:43], v[8:9], 0, s[34:35]
	v_lshl_add_u64 v[44:45], v[8:9], 0, s[24:25]
	v_lshl_add_u64 v[46:47], v[8:9], 0, s[26:27]
	v_lshl_add_u64 v[48:49], v[8:9], 0, s[36:37]
	v_lshl_add_u64 v[50:51], v[8:9], 0, s[40:41]
	v_lshl_add_u64 v[52:53], v[8:9], 0, s[38:39]
	v_lshl_add_u64 v[10:11], v[10:11], 4, s[4:5]
	global_load_dwordx4 v[14:17], v[42:43], off
	global_load_dwordx4 v[18:21], v[44:45], off
	global_load_dwordx4 v[22:25], v[46:47], off
	global_load_dwordx4 v[26:29], v[48:49], off
	global_load_dwordx4 v[30:33], v[50:51], off
	global_load_dwordx4 v[34:37], v[52:53], off
	global_load_dwordx4 v[38:41], v[10:11], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[28:29]
	v_lshl_add_u64 v[8:9], v[8:9], 0, s[30:31]
	s_waitcnt vmcnt(7)
	v_min_u32_e32 v2, s13, v2
	v_min_u32_e32 v3, s13, v3
	v_lshl_add_u32 v2, v2, 2, s47
	v_min_u32_e32 v4, s13, v4
	v_min_u32_e32 v5, s13, v5
	v_lshl_add_u32 v3, v3, 2, s47
	s_waitcnt vmcnt(6)
	v_min_u32_e32 v10, s13, v14
	v_min_u32_e32 v11, s13, v15
	v_min_u32_e32 v13, s13, v16
	v_min_u32_e32 v14, s13, v17
	s_waitcnt vmcnt(5)
	v_min_u32_e32 v15, s13, v18
	v_min_u32_e32 v16, s13, v19
	v_min_u32_e32 v17, s13, v20
	v_min_u32_e32 v18, s13, v21
	s_waitcnt vmcnt(4)
	v_min_u32_e32 v19, s13, v22
	v_min_u32_e32 v20, s13, v23
	v_min_u32_e32 v21, s13, v24
	v_min_u32_e32 v22, s13, v25
	s_waitcnt vmcnt(3)
	v_min_u32_e32 v23, s13, v26
	v_min_u32_e32 v24, s13, v27
	v_min_u32_e32 v25, s13, v28
	v_min_u32_e32 v26, s13, v29
	s_waitcnt vmcnt(2)
	v_min_u32_e32 v27, s13, v30
	v_min_u32_e32 v28, s13, v31
	v_min_u32_e32 v29, s13, v32
	v_min_u32_e32 v30, s13, v33
	s_waitcnt vmcnt(1)
	v_min_u32_e32 v31, s13, v34
	v_min_u32_e32 v32, s13, v35
	v_min_u32_e32 v33, s13, v36
	v_min_u32_e32 v34, s13, v37
	s_waitcnt vmcnt(0)
	v_min_u32_e32 v35, s13, v38
	v_min_u32_e32 v36, s13, v39
	v_min_u32_e32 v37, s13, v40
	v_min_u32_e32 v38, s13, v41
	ds_add_u32 v2, v12
	v_lshl_add_u32 v4, v4, 2, s47
	v_lshl_add_u32 v5, v5, 2, s47
	v_lshl_add_u32 v2, v10, 2, s47
	v_lshl_add_u32 v10, v11, 2, s47
	v_lshl_add_u32 v11, v13, 2, s47
	v_lshl_add_u32 v13, v14, 2, s47
	v_lshl_add_u32 v14, v15, 2, s47
	v_lshl_add_u32 v15, v16, 2, s47
	v_lshl_add_u32 v16, v17, 2, s47
	v_lshl_add_u32 v17, v18, 2, s47
	v_lshl_add_u32 v18, v19, 2, s47
	v_lshl_add_u32 v19, v20, 2, s47
	v_lshl_add_u32 v20, v21, 2, s47
	v_lshl_add_u32 v21, v22, 2, s47
	v_lshl_add_u32 v22, v23, 2, s47
	v_lshl_add_u32 v23, v24, 2, s47
	v_lshl_add_u32 v24, v25, 2, s47
	v_lshl_add_u32 v25, v26, 2, s47
	v_lshl_add_u32 v26, v27, 2, s47
	v_lshl_add_u32 v27, v28, 2, s47
	v_lshl_add_u32 v28, v29, 2, s47
	v_lshl_add_u32 v29, v30, 2, s47
	v_lshl_add_u32 v30, v31, 2, s47
	v_lshl_add_u32 v31, v32, 2, s47
	v_lshl_add_u32 v32, v33, 2, s47
	v_lshl_add_u32 v33, v34, 2, s47
	v_lshl_add_u32 v34, v35, 2, s47
	v_lshl_add_u32 v35, v36, 2, s47
	v_lshl_add_u32 v36, v37, 2, s47
	v_lshl_add_u32 v37, v38, 2, s47
	ds_add_u32 v3, v12
	ds_add_u32 v4, v12
	ds_add_u32 v5, v12
	ds_add_u32 v2, v12
	ds_add_u32 v10, v12
	ds_add_u32 v11, v12
	ds_add_u32 v13, v12
	ds_add_u32 v14, v12
	ds_add_u32 v15, v12
	ds_add_u32 v16, v12
	ds_add_u32 v17, v12
	ds_add_u32 v18, v12
	ds_add_u32 v19, v12
	ds_add_u32 v20, v12
	ds_add_u32 v21, v12
	ds_add_u32 v22, v12
	ds_add_u32 v23, v12
	ds_add_u32 v24, v12
	ds_add_u32 v25, v12
	ds_add_u32 v26, v12
	ds_add_u32 v27, v12
	ds_add_u32 v28, v12
	ds_add_u32 v29, v12
	ds_add_u32 v30, v12
	ds_add_u32 v31, v12
	ds_add_u32 v32, v12
	ds_add_u32 v33, v12
	ds_add_u32 v34, v12
	ds_add_u32 v35, v12
	ds_add_u32 v36, v12
	ds_add_u32 v37, v12
	v_lshl_add_u64 v[10:11], v[6:7], 0, s[22:23]
	v_cmp_le_u64_e32 vcc, s[0:1], v[10:11]
	s_or_b64 s[42:43], vcc, s[42:43]
	s_andn2_b64 exec, exec, s[42:43]
	s_cbranch_execnz .LBB0_53
.Lft18:
	s_or_b64 exec, exec, s[42:43]
.LBB0_55:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_u64_e32 vcc, s[0:1], v[6:7]
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_58
.Lft19:
	v_lshl_add_u64 v[2:3], v[6:7], 4, s[4:5]
	s_lshl_b32 s22, s2, 4
	s_mov_b32 s23, 0
	s_mov_b64 s[24:25], 0
	s_movk_i32 s26, 0x1080
	v_mov_b32_e32 v4, 1
	.p2align	5, , 4
.LBB0_57:
	global_load_dwordx4 v[8:11], v[2:3], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[2:3]
	v_cmp_le_u64_e32 vcc, s[0:1], v[6:7]
	s_or_b64 s[24:25], vcc, s[24:25]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[22:23]
	s_waitcnt vmcnt(0)
	v_min_u32_e32 v5, s13, v8
	v_min_u32_e32 v8, s13, v9
	v_min_u32_e32 v9, s13, v10
	v_min_u32_e32 v10, s13, v11
	v_lshl_add_u32 v5, v5, 2, s26
	v_lshl_add_u32 v8, v8, 2, s26
	v_lshl_add_u32 v9, v9, 2, s26
	v_lshl_add_u32 v10, v10, 2, s26
	ds_add_u32 v5, v4
	ds_add_u32 v8, v4
	ds_add_u32 v9, v4
	ds_add_u32 v10, v4
	s_andn2_b64 exec, exec, s[24:25]
	s_cbranch_execnz .LBB0_57
.LBB0_58:
	s_or_b64 exec, exec, s[6:7]
	s_and_b32 s6, s16, -4
	s_mov_b32 s7, s17
	v_lshl_add_u64 v[2:3], s[6:7], 0, v[0:1]
	v_cmp_gt_u64_e32 vcc, s[16:17], v[2:3]
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_61
.Lft20:
	s_lshl_b64 s[0:1], s[0:1], 4
	s_add_u32 s0, s4, s0
	v_lshlrev_b32_e32 v4, 2, v0
	v_mov_b32_e32 v5, 0
	s_addc_u32 s1, s5, s1
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[4:5]
	s_lshl_b32 s0, s2, 2
	s_mov_b32 s1, 0
	s_mov_b64 s[22:23], 0
	s_movk_i32 s24, 0x1080
	v_mov_b32_e32 v6, 1
	.p2align	5, , 4
.LBB0_60:
	global_load_dword v7, v[4:5], off
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	v_cmp_le_u64_e32 vcc, s[16:17], v[2:3]
	s_or_b64 s[22:23], vcc, s[22:23]
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[0:1]
	s_waitcnt vmcnt(0)
	v_min_u32_e32 v7, s13, v7
	v_lshl_add_u32 v7, v7, 2, s24
	ds_add_u32 v7, v6
	s_andn2_b64 exec, exec, s[22:23]
	s_cbranch_execnz .LBB0_60
.LBB0_61:
	s_or_b64 exec, exec, s[6:7]
	s_mov_b64 s[0:1], 0
.LBB0_62:
	s_add_i32 s45, s45, s46
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_70
.Lft21:
	v_cmp_gt_u64_e32 vcc, s[16:17], v[0:1]
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_69
.Lft22:
	v_lshlrev_b32_e32 v2, 2, v0
	v_mov_b32_e32 v3, 0
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	s_lshl_b32 s4, s2, 2
	s_mov_b32 s5, 0
	s_mov_b64 s[6:7], 0
	s_movk_i32 s13, 0x1080
	v_mov_b32_e32 v8, 1
	v_mov_b64_e32 v[6:7], v[0:1]
	s_branch .LBB0_66
	.p2align	5
.LBB0_65:
	s_or_b64 exec, exec, s[22:23]
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[2:3]
	v_cmp_le_u64_e32 vcc, s[16:17], v[6:7]
	s_or_b64 s[6:7], vcc, s[6:7]
	v_lshl_add_u64 v[4:5], v[4:5], 0, s[4:5]
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execz .LBB0_69
.LBB0_66:
	global_load_dword v2, v[4:5], off
	s_waitcnt vmcnt(0)
	v_cmp_gt_u32_e32 vcc, s14, v2
	s_and_saveexec_b64 s[22:23], vcc
	s_cbranch_execz .LBB0_65
.Lft23:
	v_lshl_add_u64 v[10:11], v[2:3], 2, s[20:21]
	global_load_dword v1, v[10:11], off
	s_waitcnt vmcnt(0)
	v_cmp_ne_u32_e32 vcc, -1, v1
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_65
.Lft24:
	v_lshl_add_u32 v1, v1, 2, s13
	ds_add_u32 v1, v8
	s_branch .LBB0_65
.LBB0_69:
	s_or_b64 exec, exec, s[0:1]
.LBB0_70:
	s_add_i32 s4, s15, -1
	v_cmp_gt_i32_e32 vcc, s12, v0
	v_mov_b32_e32 v1, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_72
.Lft25:
	s_movk_i32 s5, 0x1080
	v_lshl_add_u32 v1, v0, 2, s5
	ds_read_b32 v1, v1
	s_waitcnt lgkmcnt(0)
	v_add_u32_e32 v1, s4, v1
	v_sub_u32_e32 v3, 0, v1
	v_max_i32_e32 v3, v3, v1
	v_mul_hi_u32 v4, v3, s45
	v_mul_lo_u32 v4, v4, s33
	v_sub_u32_e32 v3, v3, v4
	v_subrev_u32_e32 v4, s33, v3
	v_cmp_le_u32_e32 vcc, s33, v3
	v_ashrrev_i32_e32 v2, 31, v1
	s_nop 0
	v_cndmask_b32_e32 v3, v3, v4, vcc
	v_subrev_u32_e32 v4, s33, v3
	v_cmp_le_u32_e32 vcc, s33, v3
	s_nop 1
	v_cndmask_b32_e32 v3, v3, v4, vcc
	v_xor_b32_e32 v3, v3, v2
	v_sub_u32_e32 v2, v2, v3
	v_add_u32_e32 v1, v1, v2
.LBB0_72:
	s_or_b64 exec, exec, s[0:1]
	v_lshrrev_b32_e32 v2, 3, v0
	v_and_b32_e32 v2, 0x7c, v2
	v_lshl_add_u32 v2, v0, 2, v2
	v_cmp_gt_u32_e32 vcc, 64, v0
	ds_write_b32 v2, v1
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_74
.Lft26:
	v_lshlrev_b32_e32 v2, 1, v0
	v_and_b32_e32 v2, 0x7fc, v2
	v_lshl_add_u32 v14, v0, 6, v2
	ds_read2_b32 v[2:3], v14 offset1:1
	ds_read2_b32 v[4:5], v14 offset0:2 offset1:3
	ds_read2_b32 v[6:7], v14 offset0:4 offset1:5
	ds_read2_b32 v[8:9], v14 offset0:6 offset1:7
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v3, v3, v2
	s_waitcnt lgkmcnt(2)
	v_add3_u32 v3, v3, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add3_u32 v3, v3, v6, v7
	ds_read2_b32 v[4:5], v14 offset0:8 offset1:9
	ds_read2_b32 v[6:7], v14 offset0:10 offset1:11
	ds_read2_b32 v[10:11], v14 offset0:12 offset1:13
	ds_read2_b32 v[12:13], v14 offset0:14 offset1:15
	s_waitcnt lgkmcnt(4)
	v_add3_u32 v3, v3, v8, v9
	s_waitcnt lgkmcnt(3)
	v_add3_u32 v3, v3, v4, v5
	s_waitcnt lgkmcnt(2)
	v_add3_u32 v3, v3, v6, v7
	v_mbcnt_lo_u32_b32 v4, -1, 0
	s_waitcnt lgkmcnt(1)
	v_add3_u32 v3, v3, v10, v11
	v_mbcnt_hi_u32_b32 v4, -1, v4
	s_waitcnt lgkmcnt(0)
	v_add3_u32 v3, v3, v12, v13
	v_and_b32_e32 v5, 15, v4
	v_cmp_ne_u32_e32 vcc, 0, v5
	v_mov_b32_dpp v6, v3 row_shr:1 row_mask:0xf bank_mask:0xf
	s_nop 0
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_add_u32_e32 v3, v6, v3
	v_cmp_lt_u32_e32 vcc, 1, v5
	s_nop 0
	v_mov_b32_dpp v6, v3 row_shr:2 row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_add_u32_e32 v3, v3, v6
	v_cmp_lt_u32_e32 vcc, 3, v5
	s_nop 0
	v_mov_b32_dpp v6, v3 row_shr:4 row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_add_u32_e32 v3, v3, v6
	v_cmp_lt_u32_e32 vcc, 7, v5
	s_nop 0
	v_mov_b32_dpp v6, v3 row_shr:8 row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v5, 0, v6, vcc
	v_add_u32_e32 v3, v3, v5
	v_bfe_i32 v6, v4, 4, 1
	v_cmp_lt_u32_e32 vcc, 31, v4
	v_mov_b32_dpp v5, v3 row_bcast:15 row_mask:0xf bank_mask:0xf
	v_and_b32_e32 v5, v6, v5
	v_add_u32_e32 v3, v3, v5
	s_nop 1
	v_mov_b32_dpp v5, v3 row_bcast:31 row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v5, 0, v5, vcc
	v_add_u32_e32 v3, v3, v5
	v_and_b32_e32 v5, 63, v4
	v_cmp_ne_u32_e32 vcc, 0, v5
	s_nop 1
	v_subbrev_co_u32_e32 v4, vcc, 0, v4, vcc
	v_lshlrev_b32_e32 v4, 2, v4
	ds_bpermute_b32 v3, v4, v3
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_waitcnt lgkmcnt(0)
	v_add_u32_e32 v2, v3, v2
	v_cndmask_b32_e32 v1, v2, v1, vcc
	ds_write_b32 v14, v1
	ds_read2_b32 v[2:3], v14 offset0:1 offset1:2
	ds_read2_b32 v[4:5], v14 offset0:3 offset1:4
	ds_read2_b32 v[6:7], v14 offset0:5 offset1:6
	ds_read2_b32 v[8:9], v14 offset0:7 offset1:8
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v1, v2, v1
	v_add_u32_e32 v2, v3, v1
	ds_write2_b32 v14, v1, v2 offset0:1 offset1:2
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v1, v4, v2
	v_add_u32_e32 v2, v5, v1
	ds_write2_b32 v14, v1, v2 offset0:3 offset1:4
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v1, v6, v2
	v_add_u32_e32 v2, v7, v1
	ds_write2_b32 v14, v1, v2 offset0:5 offset1:6
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v1, v8, v2
	ds_read2_b32 v[2:3], v14 offset0:9 offset1:10
	v_add_u32_e32 v8, v9, v1
	ds_write2_b32 v14, v1, v8 offset0:7 offset1:8
	ds_read2_b32 v[4:5], v14 offset0:11 offset1:12
	ds_read2_b32 v[6:7], v14 offset0:13 offset1:14
	ds_read_b32 v1, v14 offset:60
	s_waitcnt lgkmcnt(4)
	v_add_u32_e32 v2, v2, v8
	v_add_u32_e32 v3, v3, v2
	ds_write2_b32 v14, v2, v3 offset0:9 offset1:10
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v2, v4, v3
	v_add_u32_e32 v3, v5, v2
	ds_write2_b32 v14, v2, v3 offset0:11 offset1:12
	s_waitcnt lgkmcnt(3)
	v_add_u32_e32 v2, v6, v3
	v_add_u32_e32 v3, v7, v2
	s_waitcnt lgkmcnt(2)
	v_add_u32_e32 v1, v1, v3
	ds_write2_b32 v14, v2, v3 offset0:13 offset1:14
	ds_write_b32 v14, v1 offset:60
.LBB0_74:
	s_or_b64 exec, exec, s[0:1]
	s_add_i32 s4, s4, s44
	v_mov_b32_e32 v2, 0
	v_cmp_ne_u32_e32 vcc, 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	v_add_u32_e32 v1, -1, v0
	v_lshrrev_b32_e32 v2, 3, v1
	v_and_b32_e32 v2, 0x1ffffffc, v2
	v_lshl_add_u32 v1, v1, 2, v2
	ds_read_b32 v2, v1
	s_or_b64 exec, exec, s[0:1]
	s_abs_i32 s13, s4
	v_cmp_ge_i32_e32 vcc, s12, v0
	v_lshlrev_b32_e32 v1, 2, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_78
.Lft27:
	s_waitcnt lgkmcnt(0)
	global_store_dword v1, v2, s[18:19]
.LBB0_78:
	s_or_b64 exec, exec, s[0:1]
	s_mul_hi_u32 s14, s13, s45
	v_cmp_eq_u32_e32 vcc, s12, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_80
.Lft28:
	v_mov_b32_e32 v3, 0
	s_waitcnt lgkmcnt(0)
	global_store_dword v3, v2, s[10:11]
.LBB0_80:
	s_or_b64 exec, exec, s[0:1]
	s_ashr_i32 s11, s4, 31
	s_ashr_i32 s10, s15, 31
	v_cmp_gt_u32_e32 vcc, s12, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_89
.Lft29:
	global_load_dwordx2 v[2:3], v1, s[18:19]
	s_waitcnt vmcnt(0)
	v_cmp_lt_i32_e32 vcc, v2, v3
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_89
.Lft30:
	v_sub_u32_e32 v4, 0, v2
	v_max_i32_e32 v4, v4, v2
	v_mul_hi_u32 v5, v4, s45
	v_mul_lo_u32 v6, v5, s33
	v_sub_u32_e32 v4, v4, v6
	v_add_u32_e32 v6, 1, v5
	v_cmp_le_u32_e32 vcc, s33, v4
	v_cvt_f32_u32_e32 v7, s15
	v_ashrrev_i32_e32 v1, 31, v2
	v_cndmask_b32_e32 v5, v5, v6, vcc
	v_subrev_u32_e32 v6, s33, v4
	v_cndmask_b32_e32 v4, v4, v6, vcc
	v_add_u32_e32 v6, 1, v5
	v_cmp_le_u32_e32 vcc, s33, v4
	v_xor_b32_e32 v1, s10, v1
	s_mov_b64 s[6:7], -1
	v_cndmask_b32_e32 v4, v5, v6, vcc
	v_xor_b32_e32 v4, v4, v1
	v_sub_u32_e32 v4, v4, v1
	v_rcp_iflag_f32_e32 v1, v7
	v_add_u32_e32 v5, s15, v2
	v_mov_b32_e32 v7, s15
	v_cmp_lt_i32_e32 vcc, v5, v3
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_max_i32_e32 v6, v3, v5
	v_addc_co_u32_e64 v5, s[0:1], v2, v7, vcc
	s_sub_i32 s0, 0, s15
	v_sub_u32_e32 v5, v6, v5
	v_mul_lo_u32 v6, s0, v1
	v_mul_hi_u32 v6, v1, v6
	v_add_u32_e32 v1, v1, v6
	v_mul_hi_u32 v1, v5, v1
	v_mul_lo_u32 v6, v1, s15
	v_sub_u32_e32 v5, v5, v6
	v_add_u32_e32 v6, 1, v1
	v_cmp_le_u32_e64 s[0:1], s15, v5
	s_nop 1
	v_cndmask_b32_e64 v1, v1, v6, s[0:1]
	v_subrev_u32_e32 v6, s15, v5
	v_cndmask_b32_e64 v5, v5, v6, s[0:1]
	v_add_u32_e32 v6, 1, v1
	v_cmp_le_u32_e64 s[0:1], s15, v5
	s_nop 1
	v_cndmask_b32_e64 v1, v1, v6, s[0:1]
	v_addc_co_u32_e32 v5, vcc, 1, v1, vcc
	v_cmp_lt_u32_e32 vcc, 1, v5
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_86
.Lft31:
	v_and_b32_e32 v8, -2, v5
	v_mov_b32_e32 v1, v0
	s_mov_b64 s[6:7], 0
	v_mov_b32_e32 v6, v4
	v_mov_b32_e32 v9, v8
.LBB0_84:
	v_add_u32_e32 v9, -2, v9
	v_ashrrev_i32_e32 v7, 31, v6
	v_cmp_eq_u32_e32 vcc, 0, v9
	v_lshl_add_u64 v[10:11], v[6:7], 2, s[8:9]
	s_or_b64 s[6:7], vcc, s[6:7]
	v_add_u32_e32 v6, 2, v6
	global_store_dwordx2 v[10:11], v[0:1], off
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_84
.Lft32:
	s_or_b64 exec, exec, s[6:7]
	v_mad_u64_u32 v[6:7], s[6:7], v8, s15, v[2:3]
	v_cmp_ne_u32_e32 vcc, v5, v8
	v_add_u32_e32 v4, v4, v8
	s_orn2_b64 s[6:7], vcc, exec
	v_mov_b32_e32 v2, v6
.LBB0_86:
	s_or_b64 exec, exec, s[0:1]
	s_and_b64 exec, exec, s[6:7]
	s_cbranch_execz .LBB0_89
.Lft33:
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[4:5], v[4:5], 2, s[8:9]
	s_mov_b64 s[0:1], 0
.LBB0_88:
	v_add_u32_e32 v2, s15, v2
	v_cmp_ge_i32_e32 vcc, v2, v3
	global_store_dword v[4:5], v0, off
	s_or_b64 s[0:1], vcc, s[0:1]
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB0_88
.LBB0_89:
	s_or_b64 exec, exec, s[4:5]
	s_mul_i32 s1, s14, s33
	s_sub_i32 s1, s13, s1
	s_xor_b32 s0, s11, s10
	s_add_i32 s4, s14, 1
	s_sub_i32 s5, s1, s33
	s_cmp_ge_u32 s1, s33
	s_cselect_b32 s4, s4, s14
	s_cselect_b32 s1, s5, s1
	s_add_i32 s5, s4, 1
	s_cmp_ge_u32 s1, s33
	s_cselect_b32 s1, s5, s4
	s_xor_b32 s1, s1, s0
	s_ashr_i32 s13, s12, 31
	s_sub_i32 s0, s1, s0
	s_lshl_b64 s[4:5], s[12:13], 2
	s_add_u32 s4, s18, s4
	s_addc_u32 s5, s19, s5
	v_mov_b32_e32 v1, 0
	global_load_dword v2, v1, s[4:5]
	s_waitcnt vmcnt(0)
	v_readfirstlane_b32 s1, v2
	s_abs_i32 s1, s1
	s_mul_hi_u32 s4, s1, s45
	s_mul_i32 s5, s4, s33
	s_sub_i32 s1, s1, s5
	s_add_i32 s6, s4, 1
	s_sub_i32 s5, s1, s33
	s_cmp_ge_u32 s1, s33
	s_cselect_b32 s4, s6, s4
	s_cselect_b32 s1, s5, s1
	s_add_i32 s5, s4, 1
	v_ashrrev_i32_e32 v3, 31, v2
	s_cmp_ge_u32 s1, s33
	v_xor_b32_e32 v2, s10, v3
	s_cselect_b32 s1, s5, s4
	v_xor_b32_e32 v3, s1, v2
	v_sub_u32_e32 v2, v3, v2
	v_add_u32_e32 v0, v2, v0
	s_ashr_i32 s1, s0, 31
	v_cmp_gt_u64_e32 vcc, s[0:1], v[0:1]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_92
.Lft34:
	v_lshl_add_u64 v[2:3], v[0:1], 2, s[8:9]
	s_lshl_b32 s4, s2, 2
	s_mov_b32 s5, 0
	s_mov_b64 s[6:7], 0
	v_mov_b32_e32 v4, -1
	.p2align	5, , 4
.LBB0_91:
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[2:3]
	v_cmp_le_u64_e32 vcc, s[0:1], v[0:1]
	global_store_dword v[2:3], v4, off
	s_or_b64 s[6:7], vcc, s[6:7]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[4:5]
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_91
.LBB0_92:
	s_endpgm
.Lfunc_end0:
	.size	vl_moe_align, .Lfunc_end0-vl_moe_align
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel vl_moe_align
		.amdhsa_group_segment_fixed_size 4224
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 344
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
		.amdhsa_next_free_vgpr 54
		.amdhsa_next_free_sgpr 48
		.amdhsa_accum_offset 56
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
  - .actual_access: write_only
    .address_space: global
    .offset: 8
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .actual_access: write_only
    .address_space: global
    .offset: 24
    .size: 8
    .value_kind: global_buffer
  - .actual_access: read_only
    .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .offset: 40
    .size: 4
    .value_kind: by_value
  - .offset: 44
    .size: 4
    .value_kind: by_value
  - .offset: 48
    .size: 4
    .value_kind: by_value
  - .offset: 52
    .size: 4
    .value_kind: by_value
  - .offset: 56
    .size: 8
    .value_kind: by_value
  - .address_space: global
    .offset: 64
    .size: 8
    .value_kind: global_buffer
  - .offset: 72
    .size: 4
    .value_kind: by_value
  - .offset: 76
    .size: 4
    .value_kind: by_value
  - .offset: 80
    .size: 1
    .value_kind: by_value
  - .offset: 88
    .size: 4
    .value_kind: hidden_block_count_x
  - .offset: 92
    .size: 4
    .value_kind: hidden_block_count_y
  - .offset: 96
    .size: 4
    .value_kind: hidden_block_count_z
  - .offset: 100
    .size: 2
    .value_kind: hidden_group_size_x
  - .offset: 102
    .size: 2
    .value_kind: hidden_group_size_y
  - .offset: 104
    .size: 2
    .value_kind: hidden_group_size_z
  - .offset: 106
    .size: 2
    .value_kind: hidden_remainder_x
  - .offset: 108
    .size: 2
    .value_kind: hidden_remainder_y
  - .offset: 110
    .size: 2
    .value_kind: hidden_remainder_z
  - .offset: 128
    .size: 8
    .value_kind: hidden_global_offset_x
  - .offset: 136
    .size: 8
    .value_kind: hidden_global_offset_y
  - .offset: 144
    .size: 8
    .value_kind: hidden_global_offset_z
  - .offset: 152
    .size: 2
    .value_kind: hidden_grid_dims
  - .offset: 208
    .size: 4
    .value_kind: hidden_dynamic_lds_size
  .gfx1250_revision: B0
  .group_segment_fixed_size: 4224
  .kernarg_segment_align: 8
  .kernarg_segment_size: 344
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: vl_moe_align
  .private_segment_fixed_size: 0
  .sgpr_count: 54
  .sgpr_spill_count: 0
  .symbol: vl_moe_align.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 54
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
