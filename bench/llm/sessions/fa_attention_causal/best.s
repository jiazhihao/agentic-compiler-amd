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
	v_and_b32_e32 v71, 63, v0
	v_and_b32_e32 v78, 0x3c0, v0
	s_waitcnt lgkmcnt(0)
	s_min_i32 s0, s0, s30
	s_cmp_eq_u32 s3, 0
	s_cselect_b32 s30, s30, s0
	s_ashr_i32 s3, s2, 31
	v_lshrrev_b32_e32 v77, 6, v0
	s_lshl_b64 s[0:1], s[2:3], 6
	v_cmp_gt_i32_e32 vcc, s30, v78
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v70, 0xff800000
	v_lshlrev_b32_e32 v76, 2, v71
	v_mov_b32_e32 v72, 0
	s_and_saveexec_b64 s[34:35], vcc
	s_cbranch_execz .LBB0_14
.Lft0:
	s_lshl_b64 s[4:5], s[0:1], 2
	s_add_u32 s86, s20, s4
	s_addc_u32 s87, s21, s5
	s_load_dwordx16 s[4:19], s[86:87], 0x0
	s_load_dwordx16 s[36:51], s[86:87], 0x40
	s_load_dwordx16 s[52:67], s[86:87], 0x80
	s_load_dwordx16 s[68:83], s[86:87], 0xc0
	v_lshlrev_b32_e32 v0, 8, v0
	s_mov_b32 s20, 0x3c000
	v_lshlrev_b32_e32 v79, 8, v77
	v_and_or_b32 v64, v0, s20, v76
	v_add_u32_e32 v80, 0xc00, v79
	v_lshl_add_u64 v[66:67], s[24:25], 0, v[64:65]
	s_mov_b64 s[20:21], 0xf00
	v_or_b32_e32 v81, v80, v76
	v_sub_u32_e32 v82, s30, v78
	v_lshl_add_u64 v[68:69], v[66:67], 0, s[20:21]
	s_mov_b64 s[20:21], 0
	v_mov_b32_e32 v61, 0xff800000
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v84, 0
	s_mov_b32 s24, 0x3fb8aa3b
	s_mov_b64 s[84:85], 0x1000
	s_mov_b64 s[86:87], 0x100
	s_mov_b64 s[88:89], 0x10000
	s_branch .LBB0_3
.LBB0_2:
	s_or_b64 exec, exec, s[90:91]
	s_waitcnt lgkmcnt(7)
	v_add_f32_e32 v48, v48, v60
	s_waitcnt lgkmcnt(6)
	v_add_f32_e32 v40, v40, v56
	s_waitcnt lgkmcnt(5)
	v_add_f32_e32 v32, v32, v52
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v24, v24, v44
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v16, v16, v36
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v8, v8, v28
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v20
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v12
	v_add_f32_e32 v49, v49, v61
	v_add_f32_e32 v50, v50, v62
	v_add_f32_e32 v51, v51, v63
	v_add_f32_e32 v41, v41, v57
	v_add_f32_e32 v42, v42, v58
	v_add_f32_e32 v43, v43, v59
	v_add_f32_e32 v33, v33, v53
	v_add_f32_e32 v34, v34, v54
	v_add_f32_e32 v35, v35, v55
	v_add_f32_e32 v25, v25, v45
	v_add_f32_e32 v26, v26, v46
	v_add_f32_e32 v27, v27, v47
	v_add_f32_e32 v17, v17, v37
	v_add_f32_e32 v18, v18, v38
	v_add_f32_e32 v19, v19, v39
	v_add_f32_e32 v9, v9, v29
	v_add_f32_e32 v10, v10, v30
	v_add_f32_e32 v11, v11, v31
	v_add_f32_e32 v5, v5, v21
	v_add_f32_e32 v6, v6, v22
	v_add_f32_e32 v7, v7, v23
	v_add_f32_e32 v1, v1, v13
	v_add_f32_e32 v2, v2, v14
	v_add_f32_e32 v3, v3, v15
	v_add_f32_e32 v12, v48, v16
	v_add_f32_e32 v8, v40, v8
	v_add_f32_e32 v4, v32, v4
	v_add_f32_e32 v0, v24, v0
	v_add_f32_e32 v13, v49, v17
	v_add_f32_e32 v14, v50, v18
	v_add_f32_e32 v15, v51, v19
	v_add_f32_e32 v9, v41, v9
	v_add_f32_e32 v10, v42, v10
	v_add_f32_e32 v11, v43, v11
	v_add_f32_e32 v5, v33, v5
	v_add_f32_e32 v6, v34, v6
	v_add_f32_e32 v7, v35, v7
	v_add_f32_e32 v1, v25, v1
	v_add_f32_e32 v2, v26, v2
	v_add_f32_e32 v3, v27, v3
	v_add_f32_e32 v4, v12, v4
	v_add_f32_e32 v0, v8, v0
	v_add_f32_e32 v5, v13, v5
	v_add_f32_e32 v6, v14, v6
	v_add_f32_e32 v7, v15, v7
	v_add_f32_e32 v1, v9, v1
	v_add_f32_e32 v2, v10, v2
	v_add_f32_e32 v3, v11, v3
	v_add_f32_e32 v0, v4, v0
	v_exp_f32_e32 v4, v73
	v_add_f32_e32 v1, v5, v1
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v3, v7, v3
	v_add_f32_e32 v0, v0, v2
	v_add_f32_e32 v1, v1, v3
	v_add_f32_e32 v0, v0, v1
	v_add_u32_e32 v78, 0x100, v78
	v_fmac_f32_e32 v0, v83, v4
	v_fmac_f32_e32 v72, v84, v4
	v_cmp_le_i32_e32 vcc, s30, v78
	v_add_u32_e32 v82, 0xffffff00, v82
	v_lshl_add_u64 v[68:69], v[68:69], 0, s[88:89]
	v_lshl_add_u64 v[66:67], v[66:67], 0, s[88:89]
	s_or_b64 s[20:21], vcc, s[20:21]
	v_mov_b32_e32 v61, v70
	v_mov_b32_e32 v83, v0
	v_mov_b32_e32 v84, v72
	s_andn2_b64 exec, exec, s[20:21]
	s_cbranch_execz .LBB0_13
.LBB0_3:
	v_or_b32_e32 v64, v78, v71
	v_cmp_gt_i32_e32 vcc, s30, v64
	v_mov_b32_e32 v60, 0xff800000
	s_and_saveexec_b64 s[90:91], vcc
	s_cbranch_execz .LBB0_5
.Lft1:
	v_lshlrev_b64 v[0:1], 8, v[64:65]
	v_lshl_add_u64 v[62:63], s[22:23], 0, v[0:1]
	global_load_dwordx4 v[24:27], v[62:63], off
	global_load_dwordx4 v[56:59], v[62:63], off offset:208
	global_load_dwordx4 v[52:55], v[62:63], off offset:224
	global_load_dwordx4 v[0:3], v[62:63], off offset:240
	global_load_dwordx4 v[48:51], v[62:63], off offset:16
	global_load_dwordx4 v[44:47], v[62:63], off offset:32
	global_load_dwordx4 v[40:43], v[62:63], off offset:48
	global_load_dwordx4 v[32:35], v[62:63], off offset:64
	global_load_dwordx4 v[28:31], v[62:63], off offset:80
	global_load_dwordx4 v[16:19], v[62:63], off offset:96
	global_load_dwordx4 v[12:15], v[62:63], off offset:112
	global_load_dwordx4 v[8:11], v[62:63], off offset:128
	global_load_dwordx4 v[4:7], v[62:63], off offset:144
	global_load_dwordx4 v[20:23], v[62:63], off offset:160
	global_load_dwordx4 v[36:39], v[62:63], off offset:176
	global_load_dwordx4 v[72:75], v[62:63], off offset:192
	s_waitcnt vmcnt(15) lgkmcnt(0)
	v_fma_f32 v24, s4, v24, 0
	v_fmac_f32_e32 v24, s5, v25
	v_fmac_f32_e32 v24, s6, v26
	v_fmac_f32_e32 v24, s7, v27
	s_waitcnt vmcnt(11)
	v_fmac_f32_e32 v24, s8, v48
	v_fmac_f32_e32 v24, s9, v49
	v_fmac_f32_e32 v24, s10, v50
	v_fmac_f32_e32 v24, s11, v51
	s_waitcnt vmcnt(10)
	v_fmac_f32_e32 v24, s12, v44
	v_fmac_f32_e32 v24, s13, v45
	v_fmac_f32_e32 v24, s14, v46
	v_fmac_f32_e32 v24, s15, v47
	s_waitcnt vmcnt(9)
	v_fmac_f32_e32 v24, s16, v40
	v_fmac_f32_e32 v24, s17, v41
	v_fmac_f32_e32 v24, s18, v42
	v_fmac_f32_e32 v24, s19, v43
	s_waitcnt vmcnt(8)
	v_fmac_f32_e32 v24, s36, v32
	v_fmac_f32_e32 v24, s37, v33
	v_fmac_f32_e32 v24, s38, v34
	v_fmac_f32_e32 v24, s39, v35
	s_waitcnt vmcnt(7)
	v_fmac_f32_e32 v24, s40, v28
	v_fmac_f32_e32 v24, s41, v29
	v_fmac_f32_e32 v24, s42, v30
	v_fmac_f32_e32 v24, s43, v31
	s_waitcnt vmcnt(6)
	v_fmac_f32_e32 v24, s44, v16
	v_fmac_f32_e32 v24, s45, v17
	v_fmac_f32_e32 v24, s46, v18
	v_fmac_f32_e32 v24, s47, v19
	s_waitcnt vmcnt(5)
	v_fmac_f32_e32 v24, s48, v12
	v_fmac_f32_e32 v24, s49, v13
	v_fmac_f32_e32 v24, s50, v14
	v_fmac_f32_e32 v24, s51, v15
	s_waitcnt vmcnt(4)
	v_fmac_f32_e32 v24, s52, v8
	v_fmac_f32_e32 v24, s53, v9
	v_fmac_f32_e32 v24, s54, v10
	v_fmac_f32_e32 v24, s55, v11
	s_waitcnt vmcnt(3)
	v_fmac_f32_e32 v24, s56, v4
	v_fmac_f32_e32 v24, s57, v5
	v_fmac_f32_e32 v24, s58, v6
	v_fmac_f32_e32 v24, s59, v7
	s_waitcnt vmcnt(2)
	v_fmac_f32_e32 v24, s60, v20
	v_fmac_f32_e32 v24, s61, v21
	v_fmac_f32_e32 v24, s62, v22
	v_fmac_f32_e32 v24, s63, v23
	s_waitcnt vmcnt(1)
	v_fmac_f32_e32 v24, s64, v36
	v_fmac_f32_e32 v24, s65, v37
	v_fmac_f32_e32 v24, s66, v38
	v_fmac_f32_e32 v24, s67, v39
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v24, s68, v72
	v_fmac_f32_e32 v24, s69, v73
	v_fmac_f32_e32 v24, s70, v74
	v_pk_mul_f32 v[56:57], s[72:73], v[56:57]
	v_fmac_f32_e32 v24, s71, v75
	v_add_f32_e32 v4, v24, v56
	v_pk_mul_f32 v[58:59], s[74:75], v[58:59]
	v_add_f32_e32 v4, v4, v57
	v_add_f32_e32 v4, v4, v58
	v_pk_mul_f32 v[52:53], s[76:77], v[52:53]
	v_add_f32_e32 v4, v4, v59
	v_add_f32_e32 v4, v4, v52
	v_pk_mul_f32 v[54:55], s[78:79], v[54:55]
	v_add_f32_e32 v4, v4, v53
	v_add_f32_e32 v4, v4, v54
	v_pk_mul_f32 v[0:1], s[80:81], v[0:1]
	v_add_f32_e32 v4, v4, v55
	v_add_f32_e32 v0, v4, v0
	v_add_f32_e32 v4, v0, v1
	v_pk_mul_f32 v[0:1], s[82:83], v[2:3]
	s_nop 0
	v_add_f32_e32 v0, v4, v0
	v_add_f32_e32 v0, v0, v1
	v_mul_f32_e32 v60, s31, v0
.LBB0_5:
	s_or_b64 exec, exec, s[90:91]
	ds_write_b32 v81, v60
	ds_read_b128 v[0:3], v80 offset:240
	ds_read_b128 v[4:7], v80 offset:224
	ds_read_b128 v[8:11], v80 offset:208
	ds_read_b128 v[12:15], v80 offset:192
	ds_read_b128 v[16:19], v80
	ds_read_b128 v[20:23], v80 offset:16
	ds_read_b128 v[24:27], v80 offset:32
	ds_read_b128 v[28:31], v80 offset:48
	ds_read_b128 v[32:35], v80 offset:80
	ds_read_b128 v[36:39], v80 offset:64
	ds_read_b128 v[40:43], v80 offset:144
	ds_read_b128 v[44:47], v80 offset:128
	ds_read_b128 v[48:51], v80 offset:112
	ds_read_b128 v[52:55], v80 offset:96
	ds_read_b128 v[56:59], v80 offset:176
	ds_read_b128 v[72:75], v80 offset:160
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v16, v16, v44, v36
	v_max3_f32 v18, v18, v46, v38
	v_max3_f32 v20, v20, v40, v32
	v_max3_f32 v22, v22, v42, v34
	v_max3_f32 v24, v24, v72, v52
	v_max3_f32 v26, v26, v74, v54
	v_max3_f32 v28, v28, v56, v48
	v_max3_f32 v30, v30, v58, v50
	v_max3_f32 v17, v17, v45, v37
	v_max3_f32 v19, v19, v47, v39
	v_max3_f32 v21, v21, v41, v33
	v_max3_f32 v23, v23, v43, v35
	v_max3_f32 v25, v25, v73, v53
	v_max3_f32 v27, v27, v75, v55
	v_max3_f32 v29, v29, v57, v49
	v_max3_f32 v31, v31, v59, v51
	v_max3_f32 v12, v16, v12, v24
	v_max3_f32 v14, v18, v14, v26
	v_max3_f32 v8, v20, v8, v28
	v_max3_f32 v10, v22, v10, v30
	v_max3_f32 v13, v17, v13, v25
	v_max3_f32 v15, v19, v15, v27
	v_max3_f32 v9, v21, v9, v29
	v_max3_f32 v11, v23, v11, v31
	v_max3_f32 v4, v12, v4, v8
	v_max3_f32 v6, v14, v6, v10
	v_max3_f32 v5, v13, v5, v9
	v_max3_f32 v7, v15, v7, v11
	v_max3_f32 v0, v4, v0, v6
	v_max_f32_e32 v2, v2, v2
	v_max_f32_e32 v0, v0, v2
	v_max3_f32 v1, v5, v1, v7
	v_max_f32_e32 v2, v3, v3
	v_max_f32_e32 v1, v1, v2
	v_max3_f32 v70, v61, v0, v1
	v_pk_add_f32 v[0:1], v[60:61], v[70:71] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_sub_u32_e32 v64, s30, v78
	v_pk_mul_f32 v[72:73], v[0:1], s[24:25] op_sel_hi:[1,0]
	v_min_i32_e32 v85, 64, v64
	v_exp_f32_e32 v0, v72
	v_mov_b32_e32 v72, 0
	v_cndmask_b32_e32 v0, 0, v0, vcc
	ds_write_b32 v81, v0
	ds_read_b128 v[48:51], v80
	ds_read_b128 v[40:43], v80 offset:16
	ds_read_b128 v[32:35], v80 offset:32
	ds_read_b128 v[24:27], v80 offset:48
	ds_read_b128 v[16:19], v80 offset:64
	ds_read_b128 v[8:11], v80 offset:80
	ds_read_b128 v[4:7], v80 offset:96
	ds_read_b128 v[0:3], v80 offset:112
	ds_read_b128 v[60:63], v80 offset:128
	ds_read_b128 v[56:59], v80 offset:144
	ds_read_b128 v[52:55], v80 offset:160
	ds_read_b128 v[44:47], v80 offset:176
	ds_read_b128 v[36:39], v80 offset:192
	ds_read_b128 v[28:31], v80 offset:208
	ds_read_b128 v[20:23], v80 offset:224
	ds_read_b128 v[12:15], v80 offset:240
	v_cmp_lt_i32_e32 vcc, 15, v64
	v_mov_b32_e32 v64, 0
	s_and_saveexec_b64 s[90:91], vcc
	s_cbranch_execz .LBB0_9
.Lft2:
	s_mov_b32 s25, 0
	s_mov_b64 s[92:93], 0
	v_mov_b32_e32 v72, 0
	v_mov_b64_e32 v[74:75], v[68:69]
	v_mov_b32_e32 v86, v79
	.p2align	5, , 4
.LBB0_7:
	global_load_dword v104, v[74:75], off offset:-3840
	global_load_dword v105, v[74:75], off offset:-3584
	global_load_dword v106, v[74:75], off offset:-3328
	global_load_dword v107, v[74:75], off offset:-3072
	global_load_dword v108, v[74:75], off offset:-2816
	global_load_dword v109, v[74:75], off offset:-2560
	global_load_dword v110, v[74:75], off offset:-2304
	global_load_dword v111, v[74:75], off offset:-2048
	global_load_dword v112, v[74:75], off offset:-1792
	global_load_dword v113, v[74:75], off offset:-1536
	global_load_dword v114, v[74:75], off offset:-1280
	global_load_dword v115, v[74:75], off offset:-1024
	global_load_dword v116, v[74:75], off offset:-768
	global_load_dword v117, v[74:75], off offset:-512
	global_load_dword v118, v[74:75], off offset:-256
	global_load_dword v119, v[74:75], off
	ds_read_b128 v[88:91], v86 offset:3072
	ds_read_b128 v[92:95], v86 offset:3088
	ds_read_b128 v[96:99], v86 offset:3104
	ds_read_b128 v[100:103], v86 offset:3120
	s_mov_b32 s33, s25
	s_add_i32 s33, s33, 32
	s_add_i32 s25, s25, 16
	v_cmp_gt_i32_e32 vcc, s33, v85
	v_add_u32_e32 v86, 64, v86
	v_lshl_add_u64 v[74:75], v[74:75], 0, s[84:85]
	v_mov_b32_e32 v64, s25
	s_or_b64 s[92:93], vcc, s[92:93]
	s_waitcnt vmcnt(14) lgkmcnt(3)
	v_pk_mul_f32 v[88:89], v[104:105], v[88:89]
	s_waitcnt vmcnt(12)
	v_pk_mul_f32 v[90:91], v[106:107], v[90:91]
	v_add_f32_e32 v72, v72, v88
	v_add_f32_e32 v72, v72, v89
	v_add_f32_e32 v72, v72, v90
	s_waitcnt vmcnt(10) lgkmcnt(2)
	v_pk_mul_f32 v[92:93], v[108:109], v[92:93]
	v_add_f32_e32 v72, v72, v91
	v_add_f32_e32 v72, v72, v92
	s_waitcnt vmcnt(8)
	v_pk_mul_f32 v[94:95], v[110:111], v[94:95]
	v_add_f32_e32 v72, v72, v93
	v_add_f32_e32 v72, v72, v94
	s_waitcnt vmcnt(6) lgkmcnt(1)
	v_pk_mul_f32 v[96:97], v[112:113], v[96:97]
	v_add_f32_e32 v72, v72, v95
	v_add_f32_e32 v72, v72, v96
	s_waitcnt vmcnt(4)
	v_pk_mul_f32 v[98:99], v[114:115], v[98:99]
	v_add_f32_e32 v72, v72, v97
	v_add_f32_e32 v72, v72, v98
	s_waitcnt vmcnt(2) lgkmcnt(0)
	v_pk_mul_f32 v[100:101], v[116:117], v[100:101]
	v_add_f32_e32 v72, v72, v99
	v_add_f32_e32 v72, v72, v100
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[102:103], v[118:119], v[102:103]
	v_add_f32_e32 v72, v72, v101
	v_add_f32_e32 v72, v72, v102
	v_add_f32_e32 v72, v72, v103
	s_andn2_b64 exec, exec, s[92:93]
	s_cbranch_execnz .LBB0_7
.Lft3:
	s_or_b64 exec, exec, s[92:93]
.LBB0_9:
	s_or_b64 exec, exec, s[90:91]
	v_cmp_lt_i32_e32 vcc, v64, v85
	s_and_saveexec_b64 s[90:91], vcc
	s_cbranch_execz .LBB0_2
.Lft4:
	v_min_i32_e32 v74, 64, v82
	v_sub_u32_e32 v85, v64, v74
	v_lshlrev_b64 v[74:75], 8, v[64:65]
	v_lshl_add_u64 v[74:75], v[66:67], 0, v[74:75]
	v_lshl_add_u32 v64, v64, 2, v79
	s_mov_b64 s[92:93], 0
	.p2align	5, , 4
.LBB0_11:
	global_load_dword v86, v[74:75], off
	ds_read_b32 v87, v64 offset:3072
	v_add_co_u32_e32 v85, vcc, 1, v85
	v_lshl_add_u64 v[74:75], v[74:75], 0, s[86:87]
	v_add_u32_e32 v64, 4, v64
	s_or_b64 s[92:93], vcc, s[92:93]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v72, v87, v86
	s_andn2_b64 exec, exec, s[92:93]
	s_cbranch_execnz .LBB0_11
.Lft5:
	s_or_b64 exec, exec, s[92:93]
	s_branch .LBB0_2
.LBB0_13:
	s_or_b64 exec, exec, s[20:21]
	v_mov_b32_e32 v65, v0
.LBB0_14:
	s_or_b64 exec, exec, s[34:35]
	v_lshl_or_b32 v0, v77, 8, v76
	v_cmp_eq_u32_e32 vcc, 0, v77
	ds_write_b32 v0, v72 offset:2048
	ds_write2st64_b32 v0, v65, v70 offset1:4
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_17
.Lft6:
	ds_read2st64_b32 v[2:3], v76 offset0:4 offset1:5
	ds_read2st64_b32 v[4:5], v76 offset0:6 offset1:7
	s_mov_b32 s4, 0xff800000
	ds_read2st64_b32 v[6:7], v76 offset1:1
	ds_read2st64_b32 v[8:9], v76 offset0:2 offset1:3
	ds_read2st64_b32 v[12:13], v76 offset0:8 offset1:9
	ds_read2st64_b32 v[14:15], v76 offset0:10 offset1:11
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v0, v2, s4, v3
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v0, v0, v4, v5
	v_pk_add_f32 v[2:3], v[2:3], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	s_mov_b32 s4, 0x3fb8aa3b
	v_pk_mul_f32 v[2:3], v[2:3], s[4:5] op_sel_hi:[1,0]
	v_pk_add_f32 v[4:5], v[4:5], v[0:1] op_sel_hi:[1,0] neg_lo:[0,1] neg_hi:[0,1]
	v_exp_f32_e32 v2, v2
	v_exp_f32_e32 v10, v3
	v_pk_mul_f32 v[4:5], v[4:5], s[4:5] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v18, v12
	v_exp_f32_e32 v4, v4
	v_exp_f32_e32 v16, v5
	v_mov_b32_e32 v19, v6
	v_pk_fma_f32 v[2:3], v[2:3], v[18:19], 0 op_sel_hi:[0,1,0]
	v_mov_b32_e32 v6, v13
	v_pk_fma_f32 v[2:3], v[10:11], v[6:7], v[2:3] op_sel_hi:[0,1,1]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v6, v14
	v_mov_b32_e32 v7, v8
	v_pk_fma_f32 v[2:3], v[4:5], v[6:7], v[2:3] op_sel_hi:[0,1,1]
	v_mov_b32_e32 v8, v15
	v_pk_fma_f32 v[2:3], v[16:17], v[8:9], v[2:3] op_sel_hi:[0,1,1]
	v_div_scale_f32 v1, s[4:5], v3, v3, v2
	v_rcp_f32_e32 v4, v1
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s26, s0
	s_addc_u32 s1, s27, s1
	v_fma_f32 v5, -v1, v4, 1.0
	v_fmac_f32_e32 v4, v5, v4
	v_div_scale_f32 v5, vcc, v2, v3, v2
	v_mul_f32_e32 v6, v5, v4
	v_fma_f32 v7, -v1, v6, v5
	v_fmac_f32_e32 v6, v7, v4
	v_fma_f32 v1, -v1, v6, v5
	v_div_fmas_f32 v1, v1, v4, v6
	v_div_fixup_f32 v1, v1, v3, v2
	v_cmp_eq_u32_e32 vcc, 0, v71
	global_store_dword v76, v1, s[0:1]
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_17
.Lft7:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v3
	s_mov_b32 s0, 0x3f317217
	s_mov_b32 s1, 0x7f800000
	v_cndmask_b32_e64 v1, 0, 32, vcc
	v_ldexp_f32 v1, v3, v1
	v_log_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v2, 0x3f317217, v1
	v_fma_f32 v3, v1, s0, -v2
	v_fmamk_f32 v3, v1, 0x3377d1cf, v3
	v_add_f32_e32 v2, v2, v3
	v_cmp_lt_f32_e64 s[0:1], |v1|, s1
	s_nop 1
	v_cndmask_b32_e64 v1, v1, v2, s[0:1]
	v_mov_b32_e32 v2, 0x41b17218
	v_cndmask_b32_e32 v2, 0, v2, vcc
	s_lshl_b64 s[0:1], s[2:3], 2
	v_sub_f32_e32 v1, v1, v2
	s_add_u32 s0, s28, s0
	v_add_f32_e32 v0, v0, v1
	s_addc_u32 s1, s29, s1
	v_mov_b32_e32 v1, 0
	global_store_dword v1, v0, s[0:1]
.LBB0_17:
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
		.amdhsa_next_free_vgpr 120
		.amdhsa_next_free_sgpr 94
		.amdhsa_accum_offset 120
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
  .sgpr_count: 100
  .sgpr_spill_count: 0
  .symbol: fa_attention.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 120
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
