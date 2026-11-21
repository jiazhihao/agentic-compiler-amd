	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fa_attention
	.globl	fa_attention
	.p2align	8
	.type	fa_attention,@function
fa_attention:
	s_load_dwordx8 s[20:27], s[0:1], 0x0
	s_load_dwordx2 s[28:29], s[0:1], 0x20
	s_load_dwordx2 s[30:31], s[0:1], 0x2c
	s_load_dword s3, s[0:1], 0x34
	s_add_i32 s0, s2, 1
	v_and_b32_e32 v77, 63, v0
	v_and_b32_e32 v68, 0x3c0, v0
	s_waitcnt lgkmcnt(0)
	s_min_i32 s0, s0, s30
	s_cmp_eq_u32 s3, 0
	s_cselect_b32 s30, s30, s0
	s_ashr_i32 s3, s2, 31
	v_lshrrev_b32_e32 v88, 6, v0
	s_lshl_b64 s[0:1], s[2:3], 6
	v_cmp_gt_i32_e32 vcc, s30, v68
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v76, 0xff800000
	v_lshlrev_b32_e32 v64, 2, v77
	v_mov_b32_e32 v78, 0
	s_and_saveexec_b64 s[34:35], vcc
	s_cbranch_execz .LBB0_20
.Lft0:
	s_lshl_b64 s[4:5], s[0:1], 2
	s_add_u32 s86, s20, s4
	s_addc_u32 s87, s21, s5
	v_and_b32_e32 v124, 15, v77
	v_lshlrev_b32_e32 v124, 4, v124
	global_load_dwordx4 v[124:127], v124, s[86:87]
	v_lshlrev_b32_e32 v0, 8, v0
	s_mov_b32 s20, 0x3c000
	v_lshlrev_b32_e32 v89, 8, v88
	v_and_or_b32 v66, v0, s20, v64
	v_add_u32_e32 v90, 0xc00, v89
	v_mov_b32_e32 v65, v67
	v_lshl_add_u64 v[72:73], s[24:25], 0, v[66:67]
	s_mov_b64 s[20:21], 0xf00
	v_or_b32_e32 v91, v90, v64
	v_lshl_add_u64 v[70:71], s[24:25], 0, v[64:65]
	v_sub_u32_e32 v65, s30, v68
	v_lshl_add_u64 v[74:75], v[72:73], 0, s[20:21]
	s_mov_b64 s[20:21], 0
	v_mov_b32_e32 v1, 0xff800000
	v_mov_b32_e32 v92, 0
	v_mov_b32_e32 v93, 0
	s_mov_b64 s[68:69], s[24:25]
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v122, 0
	v_mov_b32_e32 v123, 0
	s_mov_b32 s24, 0x3fb8aa3b
	s_mov_b64 s[84:85], 0x1000
	s_mov_b64 s[86:87], 0x100
	s_mov_b64 s[88:89], 0x10000
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v124, s31, v124
	v_mul_f32_e32 v125, s31, v125
	v_mul_f32_e32 v126, s31, v126
	v_mul_f32_e32 v127, s31, v127
	s_branch .LBB0_4
.LBB0_2:
	s_or_b64 exec, exec, s[92:93]
.LBB0_3:
	v_add_u32_e32 v68, 0x100, v68
	v_cmp_le_i32_e32 vcc, s30, v68
	v_add_u32_e32 v65, 0xffffff00, v65
	s_or_b64 s[20:21], vcc, s[20:21]
	s_andn2_b64 exec, exec, s[20:21]
	s_cbranch_execz .LBB0_19
.LBB0_4:
	v_lshrrev_b32_e32 v94, 4, v77
	v_and_b32_e32 v95, 15, v77
	v_lshlrev_b32_e32 v95, 4, v95
	v_add_u32_e32 v96, v68, v94
	v_mov_b32_e32 v97, s30
	v_add_u32_e32 v97, -1, v97
	v_sub_u32_e32 v98, v65, v94
	v_lshl_add_u32 v99, v94, 2, v90
	v_min_u32_e32 v66, v96, v97
	v_lshl_or_b32 v66, v66, 8, v95
	global_load_dwordx4 v[0:3], v66, s[22:23]
	v_add_u32_e32 v69, 4, v96
	v_min_u32_e32 v69, v69, v97
	v_lshl_or_b32 v69, v69, 8, v95
	global_load_dwordx4 v[4:7], v69, s[22:23]
	v_add_u32_e32 v70, 8, v96
	v_min_u32_e32 v70, v70, v97
	v_lshl_or_b32 v70, v70, 8, v95
	global_load_dwordx4 v[8:11], v70, s[22:23]
	v_add_u32_e32 v71, 12, v96
	v_min_u32_e32 v71, v71, v97
	v_lshl_or_b32 v71, v71, 8, v95
	global_load_dwordx4 v[12:15], v71, s[22:23]
	v_add_u32_e32 v72, 16, v96
	v_min_u32_e32 v72, v72, v97
	v_lshl_or_b32 v72, v72, 8, v95
	global_load_dwordx4 v[16:19], v72, s[22:23]
	v_add_u32_e32 v73, 20, v96
	v_min_u32_e32 v73, v73, v97
	v_lshl_or_b32 v73, v73, 8, v95
	global_load_dwordx4 v[20:23], v73, s[22:23]
	v_add_u32_e32 v74, 24, v96
	v_min_u32_e32 v74, v74, v97
	v_lshl_or_b32 v74, v74, 8, v95
	global_load_dwordx4 v[24:27], v74, s[22:23]
	v_add_u32_e32 v75, 28, v96
	v_min_u32_e32 v75, v75, v97
	v_lshl_or_b32 v75, v75, 8, v95
	global_load_dwordx4 v[28:31], v75, s[22:23]
	v_add_u32_e32 v78, 32, v96
	v_min_u32_e32 v78, v78, v97
	v_lshl_or_b32 v78, v78, 8, v95
	global_load_dwordx4 v[32:35], v78, s[22:23]
	v_add_u32_e32 v79, 36, v96
	v_min_u32_e32 v79, v79, v97
	v_lshl_or_b32 v79, v79, 8, v95
	global_load_dwordx4 v[36:39], v79, s[22:23]
	v_add_u32_e32 v80, 40, v96
	v_min_u32_e32 v80, v80, v97
	v_lshl_or_b32 v80, v80, 8, v95
	global_load_dwordx4 v[40:43], v80, s[22:23]
	v_add_u32_e32 v81, 44, v96
	v_min_u32_e32 v81, v81, v97
	v_lshl_or_b32 v81, v81, 8, v95
	global_load_dwordx4 v[44:47], v81, s[22:23]
	v_add_u32_e32 v82, 48, v96
	v_min_u32_e32 v82, v82, v97
	v_lshl_or_b32 v82, v82, 8, v95
	global_load_dwordx4 v[48:51], v82, s[22:23]
	v_add_u32_e32 v83, 52, v96
	v_min_u32_e32 v83, v83, v97
	v_lshl_or_b32 v83, v83, 8, v95
	global_load_dwordx4 v[52:55], v83, s[22:23]
	v_add_u32_e32 v84, 56, v96
	v_min_u32_e32 v84, v84, v97
	v_lshl_or_b32 v84, v84, 8, v95
	global_load_dwordx4 v[56:59], v84, s[22:23]
	v_add_u32_e32 v85, 60, v96
	v_min_u32_e32 v85, v85, v97
	v_lshl_or_b32 v85, v85, 8, v95
	global_load_dwordx4 v[60:63], v85, s[22:23]
.Lft1:
	s_waitcnt vmcnt(15)
	v_pk_mul_f32 v[0:1], v[0:1], v[124:125]
	s_waitcnt vmcnt(14)
	v_pk_mul_f32 v[4:5], v[4:5], v[124:125]
	s_waitcnt vmcnt(13)
	v_pk_mul_f32 v[8:9], v[8:9], v[124:125]
	s_waitcnt vmcnt(12)
	v_pk_mul_f32 v[12:13], v[12:13], v[124:125]
	v_pk_fma_f32 v[0:1], v[2:3], v[126:127], v[0:1]
	v_pk_fma_f32 v[4:5], v[6:7], v[126:127], v[4:5]
	v_pk_fma_f32 v[8:9], v[10:11], v[126:127], v[8:9]
	v_pk_fma_f32 v[12:13], v[14:15], v[126:127], v[12:13]
	v_add_f32_e32 v0, v0, v1
	v_add_f32_e32 v4, v4, v5
	v_add_f32_e32 v8, v8, v9
	v_add_f32_e32 v12, v12, v13
	v_add_f32_dpp v1, v0, v0 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v5, v4, v4 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v9, v8, v8 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v13, v12, v12 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v0, v1, v1 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v4, v5, v5 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v8, v9, v9 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v12, v13, v13 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v1, v0, v0 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v5, v4, v4 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v9, v8, v8 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v13, v12, v12 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v0, v1, v1 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v4, v5, v5 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v8, v9, v9 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v12, v13, v13 row_mirror row_mask:0xf bank_mask:0xf
	s_waitcnt vmcnt(11)
	v_pk_mul_f32 v[16:17], v[16:17], v[124:125]
	s_waitcnt vmcnt(10)
	v_pk_mul_f32 v[20:21], v[20:21], v[124:125]
	s_waitcnt vmcnt(9)
	v_pk_mul_f32 v[24:25], v[24:25], v[124:125]
	s_waitcnt vmcnt(8)
	v_pk_mul_f32 v[28:29], v[28:29], v[124:125]
	v_pk_fma_f32 v[16:17], v[18:19], v[126:127], v[16:17]
	v_pk_fma_f32 v[20:21], v[22:23], v[126:127], v[20:21]
	v_pk_fma_f32 v[24:25], v[26:27], v[126:127], v[24:25]
	v_pk_fma_f32 v[28:29], v[30:31], v[126:127], v[28:29]
	v_add_f32_e32 v16, v16, v17
	v_add_f32_e32 v20, v20, v21
	v_add_f32_e32 v24, v24, v25
	v_add_f32_e32 v28, v28, v29
	v_add_f32_dpp v17, v16, v16 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v21, v20, v20 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v25, v24, v24 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v29, v28, v28 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v16, v17, v17 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v20, v21, v21 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v24, v25, v25 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v28, v29, v29 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v17, v16, v16 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v21, v20, v20 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v25, v24, v24 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v29, v28, v28 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v16, v17, v17 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v20, v21, v21 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v24, v25, v25 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v28, v29, v29 row_mirror row_mask:0xf bank_mask:0xf
	s_waitcnt vmcnt(7)
	v_pk_mul_f32 v[32:33], v[32:33], v[124:125]
	s_waitcnt vmcnt(6)
	v_pk_mul_f32 v[36:37], v[36:37], v[124:125]
	s_waitcnt vmcnt(5)
	v_pk_mul_f32 v[40:41], v[40:41], v[124:125]
	s_waitcnt vmcnt(4)
	v_pk_mul_f32 v[44:45], v[44:45], v[124:125]
	v_pk_fma_f32 v[32:33], v[34:35], v[126:127], v[32:33]
	v_pk_fma_f32 v[36:37], v[38:39], v[126:127], v[36:37]
	v_pk_fma_f32 v[40:41], v[42:43], v[126:127], v[40:41]
	v_pk_fma_f32 v[44:45], v[46:47], v[126:127], v[44:45]
	v_add_f32_e32 v32, v32, v33
	v_add_f32_e32 v36, v36, v37
	v_add_f32_e32 v40, v40, v41
	v_add_f32_e32 v44, v44, v45
	v_add_f32_dpp v33, v32, v32 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v37, v36, v36 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v41, v40, v40 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v45, v44, v44 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v32, v33, v33 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v36, v37, v37 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v40, v41, v41 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v44, v45, v45 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v33, v32, v32 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v37, v36, v36 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v41, v40, v40 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v45, v44, v44 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v32, v33, v33 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v36, v37, v37 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v40, v41, v41 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v44, v45, v45 row_mirror row_mask:0xf bank_mask:0xf
	s_waitcnt vmcnt(3)
	v_pk_mul_f32 v[48:49], v[48:49], v[124:125]
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[52:53], v[52:53], v[124:125]
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[56:57], v[56:57], v[124:125]
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[60:61], v[60:61], v[124:125]
	v_pk_fma_f32 v[48:49], v[50:51], v[126:127], v[48:49]
	v_pk_fma_f32 v[52:53], v[54:55], v[126:127], v[52:53]
	v_pk_fma_f32 v[56:57], v[58:59], v[126:127], v[56:57]
	v_pk_fma_f32 v[60:61], v[62:63], v[126:127], v[60:61]
	v_add_f32_e32 v48, v48, v49
	v_add_f32_e32 v52, v52, v53
	v_add_f32_e32 v56, v56, v57
	v_add_f32_e32 v60, v60, v61
	v_add_f32_dpp v49, v48, v48 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v53, v52, v52 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v57, v56, v56 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v61, v60, v60 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v48, v49, v49 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v52, v53, v53 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v56, v57, v57 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v60, v61, v61 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v49, v48, v48 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v53, v52, v52 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v57, v56, v56 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v61, v60, v60 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v48, v49, v49 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v52, v53, v53 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v56, v57, v57 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v60, v61, v61 row_mirror row_mask:0xf bank_mask:0xf
.LBB0_6:
	v_max3_f32 v2, v0, v4, v8
	v_max3_f32 v6, v12, v16, v20
	v_max3_f32 v10, v24, v28, v32
	v_max3_f32 v14, v36, v40, v44
	v_max3_f32 v18, v48, v52, v56
	v_max3_f32 v2, v2, v6, v60
	v_max3_f32 v10, v10, v14, v18
	v_max_f32_e32 v2, v2, v10
	s_nop 0
	v_readlane_b32 s4, v2, 0
	v_readlane_b32 s5, v2, 16
	v_readlane_b32 s6, v2, 32
	v_readlane_b32 s7, v2, 48
	v_max_f32_e64 v3, s4, v76
	v_max_f32_e64 v3, s5, v3
	v_max_f32_e64 v3, s6, v3
	v_max_f32_e64 v3, s7, v3
	v_sub_f32_e32 v93, v76, v3
	v_mul_f32_e32 v93, s24, v93
	v_mov_b32_e32 v76, v3
	v_sub_f32_e32 v102, v0, v76
	v_sub_f32_e32 v103, v4, v76
	v_sub_f32_e32 v104, v8, v76
	v_sub_f32_e32 v105, v12, v76
	v_sub_f32_e32 v106, v16, v76
	v_sub_f32_e32 v107, v20, v76
	v_sub_f32_e32 v108, v24, v76
	v_sub_f32_e32 v109, v28, v76
	v_sub_f32_e32 v110, v32, v76
	v_sub_f32_e32 v111, v36, v76
	v_sub_f32_e32 v112, v40, v76
	v_sub_f32_e32 v113, v44, v76
	v_sub_f32_e32 v114, v48, v76
	v_sub_f32_e32 v115, v52, v76
	v_sub_f32_e32 v116, v56, v76
	v_sub_f32_e32 v117, v60, v76
	global_load_dwordx4 v[0:3], v66, s[68:69]
	global_load_dwordx4 v[4:7], v69, s[68:69]
	global_load_dwordx4 v[8:11], v70, s[68:69]
	global_load_dwordx4 v[12:15], v71, s[68:69]
	global_load_dwordx4 v[16:19], v72, s[68:69]
	global_load_dwordx4 v[20:23], v73, s[68:69]
	global_load_dwordx4 v[24:27], v74, s[68:69]
	global_load_dwordx4 v[28:31], v75, s[68:69]
	global_load_dwordx4 v[32:35], v78, s[68:69]
	global_load_dwordx4 v[36:39], v79, s[68:69]
	global_load_dwordx4 v[40:43], v80, s[68:69]
	global_load_dwordx4 v[44:47], v81, s[68:69]
	global_load_dwordx4 v[48:51], v82, s[68:69]
	global_load_dwordx4 v[52:55], v83, s[68:69]
	global_load_dwordx4 v[56:59], v84, s[68:69]
	global_load_dwordx4 v[60:63], v85, s[68:69]
	v_exp_f32_e32 v101, v93
	v_mul_f32_e32 v102, s24, v102
	v_mul_f32_e32 v103, s24, v103
	v_mul_f32_e32 v104, s24, v104
	v_mul_f32_e32 v105, s24, v105
	v_mul_f32_e32 v106, s24, v106
	v_mul_f32_e32 v107, s24, v107
	v_mul_f32_e32 v108, s24, v108
	v_mul_f32_e32 v109, s24, v109
	v_mul_f32_e32 v110, s24, v110
	v_mul_f32_e32 v111, s24, v111
	v_mul_f32_e32 v112, s24, v112
	v_mul_f32_e32 v113, s24, v113
	v_mul_f32_e32 v114, s24, v114
	v_mul_f32_e32 v115, s24, v115
	v_mul_f32_e32 v116, s24, v116
	v_mul_f32_e32 v117, s24, v117
	v_exp_f32_e32 v102, v102
	v_exp_f32_e32 v103, v103
	v_exp_f32_e32 v104, v104
	v_exp_f32_e32 v105, v105
	v_exp_f32_e32 v106, v106
	v_exp_f32_e32 v107, v107
	v_exp_f32_e32 v108, v108
	v_exp_f32_e32 v109, v109
	v_exp_f32_e32 v110, v110
	v_exp_f32_e32 v111, v111
	v_exp_f32_e32 v112, v112
	v_exp_f32_e32 v113, v113
	v_exp_f32_e32 v114, v114
	v_exp_f32_e32 v115, v115
	v_exp_f32_e32 v116, v116
	v_exp_f32_e32 v117, v117
	v_cmp_lt_i32_e64 s[36:37], 0, v98
	v_cmp_lt_i32_e64 s[38:39], 4, v98
	v_cmp_lt_i32_e64 s[40:41], 8, v98
	v_cmp_lt_i32_e64 s[42:43], 12, v98
	v_cmp_lt_i32_e64 s[44:45], 16, v98
	v_cmp_lt_i32_e64 s[46:47], 20, v98
	v_cmp_lt_i32_e64 s[48:49], 24, v98
	v_cmp_lt_i32_e64 s[50:51], 28, v98
	v_cmp_lt_i32_e64 s[52:53], 32, v98
	v_cmp_lt_i32_e64 s[54:55], 36, v98
	v_cmp_lt_i32_e64 s[56:57], 40, v98
	v_cmp_lt_i32_e64 s[58:59], 44, v98
	v_cmp_lt_i32_e64 s[60:61], 48, v98
	v_cmp_lt_i32_e64 s[62:63], 52, v98
	v_cmp_lt_i32_e64 s[64:65], 56, v98
	v_cmp_lt_i32_e64 s[66:67], 60, v98
	v_cndmask_b32_e64 v102, 0, v102, s[36:37]
	v_cndmask_b32_e64 v103, 0, v103, s[38:39]
	v_cndmask_b32_e64 v104, 0, v104, s[40:41]
	v_cndmask_b32_e64 v105, 0, v105, s[42:43]
	v_cndmask_b32_e64 v106, 0, v106, s[44:45]
	v_cndmask_b32_e64 v107, 0, v107, s[46:47]
	v_cndmask_b32_e64 v108, 0, v108, s[48:49]
	v_cndmask_b32_e64 v109, 0, v109, s[50:51]
	v_cndmask_b32_e64 v110, 0, v110, s[52:53]
	v_cndmask_b32_e64 v111, 0, v111, s[54:55]
	v_cndmask_b32_e64 v112, 0, v112, s[56:57]
	v_cndmask_b32_e64 v113, 0, v113, s[58:59]
	v_cndmask_b32_e64 v114, 0, v114, s[60:61]
	v_cndmask_b32_e64 v115, 0, v115, s[62:63]
	v_cndmask_b32_e64 v116, 0, v116, s[64:65]
	v_cndmask_b32_e64 v117, 0, v117, s[66:67]
	v_mul_f32_e32 v86, v101, v86
	v_mul_f32_e32 v87, v101, v87
	v_mul_f32_e32 v122, v101, v122
	v_mul_f32_e32 v123, v101, v123
	v_mul_f32_e32 v92, v101, v92
	s_waitcnt vmcnt(15)
	v_fmac_f32_e32 v86, v102, v0
	v_fmac_f32_e32 v87, v102, v1
	v_fmac_f32_e32 v122, v102, v2
	v_fmac_f32_e32 v123, v102, v3
	s_waitcnt vmcnt(14)
	v_fmac_f32_e32 v86, v103, v4
	v_fmac_f32_e32 v87, v103, v5
	v_fmac_f32_e32 v122, v103, v6
	v_fmac_f32_e32 v123, v103, v7
	s_waitcnt vmcnt(13)
	v_fmac_f32_e32 v86, v104, v8
	v_fmac_f32_e32 v87, v104, v9
	v_fmac_f32_e32 v122, v104, v10
	v_fmac_f32_e32 v123, v104, v11
	s_waitcnt vmcnt(12)
	v_fmac_f32_e32 v86, v105, v12
	v_fmac_f32_e32 v87, v105, v13
	v_fmac_f32_e32 v122, v105, v14
	v_fmac_f32_e32 v123, v105, v15
	s_waitcnt vmcnt(11)
	v_fmac_f32_e32 v86, v106, v16
	v_fmac_f32_e32 v87, v106, v17
	v_fmac_f32_e32 v122, v106, v18
	v_fmac_f32_e32 v123, v106, v19
	s_waitcnt vmcnt(10)
	v_fmac_f32_e32 v86, v107, v20
	v_fmac_f32_e32 v87, v107, v21
	v_fmac_f32_e32 v122, v107, v22
	v_fmac_f32_e32 v123, v107, v23
	s_waitcnt vmcnt(9)
	v_fmac_f32_e32 v86, v108, v24
	v_fmac_f32_e32 v87, v108, v25
	v_fmac_f32_e32 v122, v108, v26
	v_fmac_f32_e32 v123, v108, v27
	s_waitcnt vmcnt(8)
	v_fmac_f32_e32 v86, v109, v28
	v_fmac_f32_e32 v87, v109, v29
	v_fmac_f32_e32 v122, v109, v30
	v_fmac_f32_e32 v123, v109, v31
	s_waitcnt vmcnt(7)
	v_fmac_f32_e32 v86, v110, v32
	v_fmac_f32_e32 v87, v110, v33
	v_fmac_f32_e32 v122, v110, v34
	v_fmac_f32_e32 v123, v110, v35
	s_waitcnt vmcnt(6)
	v_fmac_f32_e32 v86, v111, v36
	v_fmac_f32_e32 v87, v111, v37
	v_fmac_f32_e32 v122, v111, v38
	v_fmac_f32_e32 v123, v111, v39
	s_waitcnt vmcnt(5)
	v_fmac_f32_e32 v86, v112, v40
	v_fmac_f32_e32 v87, v112, v41
	v_fmac_f32_e32 v122, v112, v42
	v_fmac_f32_e32 v123, v112, v43
	s_waitcnt vmcnt(4)
	v_fmac_f32_e32 v86, v113, v44
	v_fmac_f32_e32 v87, v113, v45
	v_fmac_f32_e32 v122, v113, v46
	v_fmac_f32_e32 v123, v113, v47
	s_waitcnt vmcnt(3)
	v_fmac_f32_e32 v86, v114, v48
	v_fmac_f32_e32 v87, v114, v49
	v_fmac_f32_e32 v122, v114, v50
	v_fmac_f32_e32 v123, v114, v51
	s_waitcnt vmcnt(2)
	v_fmac_f32_e32 v86, v115, v52
	v_fmac_f32_e32 v87, v115, v53
	v_fmac_f32_e32 v122, v115, v54
	v_fmac_f32_e32 v123, v115, v55
	s_waitcnt vmcnt(1)
	v_fmac_f32_e32 v86, v116, v56
	v_fmac_f32_e32 v87, v116, v57
	v_fmac_f32_e32 v122, v116, v58
	v_fmac_f32_e32 v123, v116, v59
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v86, v117, v60
	v_fmac_f32_e32 v87, v117, v61
	v_fmac_f32_e32 v122, v117, v62
	v_fmac_f32_e32 v123, v117, v63
	v_add_f32_e32 v102, v102, v103
	v_add_f32_e32 v104, v104, v105
	v_add_f32_e32 v106, v106, v107
	v_add_f32_e32 v108, v108, v109
	v_add_f32_e32 v110, v110, v111
	v_add_f32_e32 v112, v112, v113
	v_add_f32_e32 v114, v114, v115
	v_add_f32_e32 v116, v116, v117
	v_add_f32_e32 v102, v102, v104
	v_add_f32_e32 v106, v106, v108
	v_add_f32_e32 v110, v110, v112
	v_add_f32_e32 v114, v114, v116
	v_add_f32_e32 v102, v102, v106
	v_add_f32_e32 v110, v110, v114
	v_add_f32_e32 v102, v102, v110
	v_add_f32_e32 v92, v92, v102
	s_branch .LBB0_3
.Lft2:
	s_mov_b32 s25, 0
	s_mov_b64 s[92:93], 0
	v_mov_b32_e32 v78, 0
	v_mov_b64_e32 v[84:85], v[74:75]
	v_mov_b32_e32 v69, v89
	.p2align	5, , 4
.LBB0_8:
	global_load_dword v86, v[84:85], off offset:-3840
	global_load_dword v87, v[84:85], off offset:-3584
	global_load_dword v110, v[84:85], off offset:-3328
	global_load_dword v111, v[84:85], off offset:-3072
	global_load_dword v112, v[84:85], off offset:-2816
	global_load_dword v113, v[84:85], off offset:-2560
	global_load_dword v114, v[84:85], off offset:-2304
	global_load_dword v115, v[84:85], off offset:-2048
	global_load_dword v116, v[84:85], off offset:-256
	global_load_dword v117, v[84:85], off
	global_load_dword v118, v[84:85], off offset:-1280
	global_load_dword v119, v[84:85], off offset:-1024
	global_load_dword v120, v[84:85], off offset:-768
	global_load_dword v121, v[84:85], off offset:-512
	global_load_dword v122, v[84:85], off offset:-1792
	global_load_dword v123, v[84:85], off offset:-1536
	ds_read_b128 v[94:97], v69 offset:3072
	ds_read_b128 v[98:101], v69 offset:3088
	ds_read_b128 v[102:105], v69 offset:3104
	ds_read_b128 v[106:109], v69 offset:3120
	s_mov_b32 s33, s25
	s_add_i32 s33, s33, 32
	s_add_i32 s25, s25, 16
	v_cmp_gt_i32_e32 vcc, s33, v66
	v_add_u32_e32 v69, 64, v69
	v_lshl_add_u64 v[84:85], v[84:85], 0, s[84:85]
	v_mov_b32_e32 v82, s25
	s_or_b64 s[92:93], vcc, s[92:93]
	s_waitcnt vmcnt(8) lgkmcnt(2)
	v_pk_mul_f32 v[100:101], v[100:101], v[114:115]
	s_waitcnt vmcnt(6) lgkmcnt(0)
	v_pk_mul_f32 v[108:109], v[108:109], v[116:117]
	v_pk_fma_f32 v[96:97], v[96:97], v[110:111], v[100:101]
	s_waitcnt vmcnt(4)
	v_pk_fma_f32 v[100:101], v[104:105], v[118:119], v[108:109]
	v_pk_fma_f32 v[96:97], v[98:99], v[112:113], v[96:97]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[98:99], v[106:107], v[120:121], v[100:101]
	v_pk_fma_f32 v[86:87], v[94:95], v[86:87], v[96:97]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[94:95], v[102:103], v[122:123], v[98:99]
	v_add_f32_e32 v79, v86, v87
	v_add_f32_e32 v80, v94, v95
	v_add_f32_e32 v78, v78, v79
	v_add_f32_e32 v78, v78, v80
	s_andn2_b64 exec, exec, s[92:93]
	s_cbranch_execnz .LBB0_8
.Lft3:
	s_or_b64 exec, exec, s[92:93]
.LBB0_10:
	s_or_b64 exec, exec, s[90:91]
	v_cmp_lt_i32_e32 vcc, v82, v66
	s_and_saveexec_b64 s[90:91], vcc
	s_cbranch_execz .LBB0_3
.Lft4:
	v_min_i32_e32 v80, 64, v65
	v_sub_u32_e32 v94, v80, v82
	v_cmp_lt_u32_e32 vcc, 1, v94
	s_mov_b64 s[94:95], -1
	s_and_saveexec_b64 s[92:93], vcc
	s_cbranch_execz .LBB0_15
.Lft5:
	v_mov_b32_e32 v69, v67
	v_lshlrev_b64 v[84:85], 8, v[68:69]
	v_and_b32_e32 v69, 1, v80
	v_or_b32_e32 v83, 1, v82
	v_add_u32_e32 v66, v82, v69
	v_lshl_add_u64 v[84:85], v[70:71], 0, v[84:85]
	v_lshl_add_u32 v95, v82, 2, v89
	v_sub_u32_e32 v96, v66, v80
	v_mov_b32_e32 v79, 0
	s_mov_b64 s[94:95], 0
	v_mov_b64_e32 v[86:87], v[82:83]
.LBB0_13:
	v_mov_b32_e32 v66, v86
	v_mov_b32_e32 v98, v87
	v_mov_b32_e32 v99, v67
	v_lshlrev_b64 v[100:101], 8, v[66:67]
	v_lshlrev_b64 v[98:99], 8, v[98:99]
	v_lshl_add_u64 v[100:101], v[84:85], 0, v[100:101]
	v_lshl_add_u64 v[98:99], v[84:85], 0, v[98:99]
	global_load_dword v100, v[100:101], off
	s_nop 0
	global_load_dword v101, v[98:99], off
	v_add_u32_e32 v66, 0xc00, v95
	ds_read2_b32 v[98:99], v66 offset1:1
	v_add_u32_e32 v96, 2, v96
	v_cmp_eq_u32_e32 vcc, 0, v96
	v_add_u32_e32 v87, 2, v87
	v_add_u32_e32 v86, 2, v86
	v_add_u32_e32 v95, 8, v95
	s_or_b64 s[94:95], vcc, s[94:95]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_pk_fma_f32 v[78:79], v[100:101], v[98:99], v[78:79]
	s_andn2_b64 exec, exec, s[94:95]
	s_cbranch_execnz .LBB0_13
.Lft6:
	s_or_b64 exec, exec, s[94:95]
	v_sub_u32_e32 v66, v94, v69
	v_cmp_eq_u32_e32 vcc, 1, v69
	v_add_u32_e32 v82, v82, v66
	v_add_f32_e32 v78, v78, v79
	s_orn2_b64 s[94:95], vcc, exec
.LBB0_15:
	s_or_b64 exec, exec, s[92:93]
	s_and_saveexec_b64 s[92:93], s[94:95]
	s_cbranch_execz .LBB0_2
.Lft7:
	v_mov_b32_e32 v83, v67
	v_lshlrev_b64 v[84:85], 8, v[82:83]
	v_sub_u32_e32 v66, v82, v80
	v_lshl_add_u64 v[84:85], v[72:73], 0, v[84:85]
	v_lshl_add_u32 v69, v82, 2, v89
	s_mov_b64 s[94:95], 0
	.p2align	5, , 4
.LBB0_17:
	global_load_dword v79, v[84:85], off
	ds_read_b32 v80, v69 offset:3072
	v_add_co_u32_e32 v66, vcc, 1, v66
	v_lshl_add_u64 v[84:85], v[84:85], 0, s[86:87]
	v_add_u32_e32 v69, 4, v69
	s_or_b64 s[94:95], vcc, s[94:95]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v78, v79, v80
	s_andn2_b64 exec, exec, s[94:95]
	s_cbranch_execnz .LBB0_17
.Lft8:
	s_or_b64 exec, exec, s[94:95]
	s_branch .LBB0_2
.LBB0_19:
	s_or_b64 exec, exec, s[20:21]
	v_readlane_b32 s4, v92, 0
	v_readlane_b32 s5, v92, 16
	v_readlane_b32 s6, v92, 32
	v_readlane_b32 s7, v92, 48
	v_mov_b32_e32 v0, v86
	v_mov_b32_e32 v1, v87
	v_mov_b32_e32 v2, v122
	v_mov_b32_e32 v3, v123
	v_lshl_or_b32 v4, v94, 10, v89
	v_or_b32_e32 v4, v4, v95
	v_or_b32_e32 v5, v89, v64
	ds_write_b128 v4, v[0:3]
	ds_read2st64_b32 v[6:7], v5 offset1:4
	ds_read2st64_b32 v[8:9], v5 offset0:8 offset1:12
	v_mov_b32_e32 v67, s4
	v_add_f32_e64 v67, s5, v67
	v_add_f32_e64 v67, s6, v67
	v_add_f32_e64 v67, s7, v67
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v8, v8, v9
	v_add_f32_e32 v78, v6, v8
.LBB0_20:
	s_or_b64 exec, exec, s[34:35]
	v_lshl_or_b32 v0, v88, 8, v64
	v_cmp_eq_u32_e32 vcc, 0, v88
	ds_write_b32 v0, v78 offset:2048
	ds_write2st64_b32 v0, v67, v76 offset1:4
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_23
.Lft9:
	ds_read2st64_b32 v[2:3], v64 offset0:4 offset1:5
	ds_read2st64_b32 v[4:5], v64 offset0:6 offset1:7
	s_mov_b32 s4, 0x3fb8aa3b
	ds_read2st64_b32 v[6:7], v64 offset1:1
	ds_read2st64_b32 v[8:9], v64 offset0:2 offset1:3
	s_lshl_b64 s[0:1], s[0:1], 2
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v0, v2, v3
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v0, v0, v4, v5
	v_pk_add_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_add_f32 v[2:3], v[2:3], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_mul_f32 v[4:5], v[4:5], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[2:3], v[2:3], s[4:5] op_sel_hi:[1,0]
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v5, v5
	v_exp_f32_e32 v11, v2
	v_exp_f32_e32 v10, v3
	ds_read2st64_b32 v[2:3], v64 offset0:8 offset1:9
	ds_read2st64_b32 v[12:13], v64 offset0:10 offset1:11
	s_waitcnt lgkmcnt(2)
	v_pk_mul_f32 v[8:9], v[8:9], v[4:5]
	v_mov_b32_e32 v14, v7
	v_mov_b32_e32 v15, v6
	v_pk_fma_f32 v[6:7], v[14:15], v[10:11], v[8:9]
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[4:5], v[12:13], v[4:5]
	v_add_f32_e32 v1, v6, v7
	v_rcp_f32_e32 v8, v1
	v_mov_b32_e32 v6, v3
	v_mov_b32_e32 v7, v2
	v_pk_fma_f32 v[2:3], v[6:7], v[10:11], v[4:5]
	s_add_u32 s0, s26, s0
	v_add_f32_e32 v2, v2, v3
	v_mul_f32_e32 v2, v8, v2
	s_addc_u32 s1, s27, s1
	v_cmp_eq_u32_e32 vcc, 0, v77
	global_store_dword v64, v2, s[0:1]
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_23
.Lft10:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v1
	v_mov_b32_e32 v2, 0xc1b17218
	s_lshl_b64 s[0:1], s[2:3], 2
	v_cndmask_b32_e64 v3, 0, 32, vcc
	v_ldexp_f32 v1, v1, v3
	v_log_f32_e32 v1, v1
	v_cndmask_b32_e32 v2, 0, v2, vcc
	s_add_u32 s0, s28, s0
	s_addc_u32 s1, s29, s1
	v_fmamk_f32 v1, v1, 0x3f317218, v2
	v_add_f32_e32 v0, v1, v0
	v_mov_b32_e32 v1, 0
	global_store_dword v1, v0, s[0:1]
.LBB0_23:
	s_endpgm
.Lfunc_end0:
	.size	fa_attention, .Lfunc_end0-fa_attention
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fa_attention
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
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 128
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 128
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
  .gfx1250_revision: B0
  .group_segment_fixed_size: 4096
  .kernarg_segment_align: 8
  .kernarg_segment_size: 56
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: fa_attention
  .private_segment_fixed_size: 0
  .sgpr_count: 102
  .sgpr_spill_count: 0
  .symbol: fa_attention.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 128
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
