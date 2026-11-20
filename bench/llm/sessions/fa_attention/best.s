	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	fa_attention
	.globl	fa_attention
	.p2align	8
	.type	fa_attention,@function
fa_attention:
	s_load_dwordx4 s[28:31], s[0:1], 0x28
	s_load_dwordx2 s[34:35], s[0:1], 0x20
	s_load_dwordx8 s[20:27], s[0:1], 0x0
	s_lshl_b32 s84, s2, 2
	s_or_b32 s86, s84, 3
	s_waitcnt lgkmcnt(0)
	s_add_i32 s33, s28, -1
	s_min_i32 s0, s86, s33
	s_add_i32 s0, s0, 1
	s_min_i32 s2, s0, s29
	s_cmp_eq_u32 s31, 0
	s_cselect_b64 s[88:89], -1, 0
	s_and_b64 s[0:1], s[88:89], exec
	s_cselect_b32 s31, s29, s2
	s_cmp_gt_i32 s31, 0
	v_lshlrev_b32_e32 v72, 2, v0
	s_cbranch_scc1 .LBB0_2
.Lft0:
	v_lshlrev_b32_e32 v1, 5, v0
	s_mov_b64 s[0:1], 0
	s_branch .LBB0_3
.LBB0_2:
	s_mov_b64 s[0:1], -1
.LBB0_3:
	v_and_b32_e32 v2, 15, v0
	v_mov_b32_e32 v89, 0
	v_mov_b32_e32 v41, 0xff800000
	s_andn2_b64 vcc, exec, s[0:1]
	v_cmp_gt_u32_e64 s[0:1], 32, v0
	v_lshlrev_b32_e32 v88, 4, v2
	s_cbranch_vccnz .LBB0_27
.Lft1:
	v_and_b32_e32 v93, 0x3f0, v0
	s_mov_b32 s2, 0x8080
	v_add_u32_e32 v73, 0x80, v72
	v_add_u32_e32 v92, 0xa080, v72
	v_lshlrev_b32_e32 v1, 5, v0
	v_lshl_add_u64 v[90:91], s[24:25], 0, v[88:89]
	v_lshl_add_u32 v94, v93, 2, s2
	s_mov_b32 s25, 0
	v_mov_b32_e32 v95, 0xff800000
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v84, 0
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	s_mov_b32 s24, 0x3fb8aa3b
	s_mov_b32 s85, 0xc2ce8ed0
	s_mov_b32 s87, 0x42b17218
	v_mov_b32_e32 v96, 0x7f800000
	v_mov_b32_e32 v100, 0xff800000
	v_mov_b32_e32 v99, 0xff800000
	v_mov_b32_e32 v98, 0xff800000
	v_mov_b32_e32 v97, 0xff800000
	s_branch .LBB0_6
.LBB0_5:
	s_addk_i32 s25, 0x800
	s_cmp_ge_i32 s25, s31
	v_mov_b32_e32 v100, v42
	v_mov_b32_e32 v99, v43
	v_mov_b32_e32 v98, v40
	v_mov_b32_e32 v97, v41
	s_cbranch_scc1 .LBB0_28
.LBB0_6:
	s_sub_i32 s2, s31, s25
	s_min_i32 s92, s2, 0x800
	s_cmp_gt_i32 s2, 0
	s_cselect_b64 s[90:91], -1, 0
	s_cmp_lt_i32 s2, 1
	s_cbranch_scc1 .LBB0_13
.Lft2:
	s_add_i32 s93, s92, -1
	s_mov_b32 s94, 0
	v_mov_b32_e32 v101, v73
.LBB0_8:
	v_add_u32_e32 v102, s94, v0
	v_min_i32_e32 v8, s93, v102
	v_add_u32_e32 v8, s25, v8
	v_ashrrev_i32_e32 v9, 31, v8
	v_lshlrev_b64 v[8:9], 8, v[8:9]
	v_lshl_add_u64 v[68:69], s[22:23], 0, v[8:9]
	global_load_dwordx4 v[8:11], v[68:69], off
	global_load_dwordx4 v[12:15], v[68:69], off offset:16
	global_load_dwordx4 v[16:19], v[68:69], off offset:32
	global_load_dwordx4 v[20:23], v[68:69], off offset:48
	global_load_dwordx4 v[24:27], v[68:69], off offset:64
	global_load_dwordx4 v[28:31], v[68:69], off offset:80
	global_load_dwordx4 v[32:35], v[68:69], off offset:96
	global_load_dwordx4 v[36:39], v[68:69], off offset:112
	global_load_dwordx4 v[40:43], v[68:69], off offset:128
	global_load_dwordx4 v[44:47], v[68:69], off offset:144
	global_load_dwordx4 v[48:51], v[68:69], off offset:160
	global_load_dwordx4 v[52:55], v[68:69], off offset:176
	global_load_dwordx4 v[56:59], v[68:69], off offset:192
	global_load_dwordx4 v[60:63], v[68:69], off offset:208
	global_load_dwordx4 v[64:67], v[68:69], off offset:224
	s_nop 0
	global_load_dwordx4 v[68:71], v[68:69], off offset:240
	v_add_u32_e32 v102, s25, v102
	s_movk_i32 s95, 0x8000
	s_mov_b32 s96, s84
.LBB0_9:
	s_min_i32 s2, s96, s33
	s_add_i32 s4, s2, 1
	s_ashr_i32 s3, s2, 31
	s_min_i32 s97, s4, s29
	s_lshl_b64 s[2:3], s[2:3], 8
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	s_load_dwordx16 s[68:83], s[2:3], 0x0
	s_load_dwordx16 s[52:67], s[2:3], 0x40
	s_load_dwordx16 s[36:51], s[2:3], 0x80
	s_load_dwordx16 s[4:19], s[2:3], 0xc0
	s_and_b64 s[2:3], s[88:89], exec
	s_waitcnt vmcnt(15) lgkmcnt(0)
	v_fma_f32 v104, s68, v8, 0
	v_fmac_f32_e32 v104, s69, v9
	v_fmac_f32_e32 v104, s70, v10
	v_fmac_f32_e32 v104, s71, v11
	s_waitcnt vmcnt(14)
	v_fmac_f32_e32 v104, s72, v12
	v_fmac_f32_e32 v104, s73, v13
	v_fmac_f32_e32 v104, s74, v14
	v_fmac_f32_e32 v104, s75, v15
	s_waitcnt vmcnt(13)
	v_fmac_f32_e32 v104, s76, v16
	v_fmac_f32_e32 v104, s77, v17
	v_fmac_f32_e32 v104, s78, v18
	v_fmac_f32_e32 v104, s79, v19
	s_waitcnt vmcnt(12)
	v_fmac_f32_e32 v104, s80, v20
	v_fmac_f32_e32 v104, s81, v21
	v_fmac_f32_e32 v104, s82, v22
	v_fmac_f32_e32 v104, s83, v23
	s_waitcnt vmcnt(11)
	v_fmac_f32_e32 v104, s52, v24
	v_fmac_f32_e32 v104, s53, v25
	v_fmac_f32_e32 v104, s54, v26
	v_fmac_f32_e32 v104, s55, v27
	s_waitcnt vmcnt(10)
	v_fmac_f32_e32 v104, s56, v28
	v_fmac_f32_e32 v104, s57, v29
	v_fmac_f32_e32 v104, s58, v30
	v_fmac_f32_e32 v104, s59, v31
	s_waitcnt vmcnt(9)
	v_fmac_f32_e32 v104, s60, v32
	v_fmac_f32_e32 v104, s61, v33
	v_fmac_f32_e32 v104, s62, v34
	v_fmac_f32_e32 v104, s63, v35
	s_waitcnt vmcnt(8)
	v_fmac_f32_e32 v104, s64, v36
	v_fmac_f32_e32 v104, s65, v37
	v_fmac_f32_e32 v104, s66, v38
	v_fmac_f32_e32 v104, s67, v39
	s_waitcnt vmcnt(7)
	v_fmac_f32_e32 v104, s36, v40
	v_fmac_f32_e32 v104, s37, v41
	v_fmac_f32_e32 v104, s38, v42
	v_fmac_f32_e32 v104, s39, v43
	s_waitcnt vmcnt(6)
	v_fmac_f32_e32 v104, s40, v44
	v_fmac_f32_e32 v104, s41, v45
	v_fmac_f32_e32 v104, s42, v46
	v_fmac_f32_e32 v104, s43, v47
	s_waitcnt vmcnt(5)
	v_fmac_f32_e32 v104, s44, v48
	v_fmac_f32_e32 v104, s45, v49
	v_fmac_f32_e32 v104, s46, v50
	v_fmac_f32_e32 v104, s47, v51
	s_waitcnt vmcnt(4)
	v_fmac_f32_e32 v104, s48, v52
	v_fmac_f32_e32 v104, s49, v53
	v_fmac_f32_e32 v104, s50, v54
	v_fmac_f32_e32 v104, s51, v55
	s_waitcnt vmcnt(3)
	v_fmac_f32_e32 v104, s4, v56
	v_fmac_f32_e32 v104, s5, v57
	v_fmac_f32_e32 v104, s6, v58
	v_fmac_f32_e32 v104, s7, v59
	s_waitcnt vmcnt(2)
	v_fmac_f32_e32 v104, s8, v60
	v_fmac_f32_e32 v104, s9, v61
	v_fmac_f32_e32 v104, s10, v62
	v_fmac_f32_e32 v104, s11, v63
	s_waitcnt vmcnt(1)
	v_fmac_f32_e32 v104, s12, v64
	v_fmac_f32_e32 v104, s13, v65
	v_fmac_f32_e32 v104, s14, v66
	v_fmac_f32_e32 v104, s15, v67
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v104, s16, v68
	v_fmac_f32_e32 v104, s17, v69
	v_fmac_f32_e32 v104, s18, v70
	s_cselect_b32 s2, s29, s97
	v_fmac_f32_e32 v104, s19, v71
	v_add_u32_e32 v103, s95, v101
	s_addk_i32 s95, 0x2000
	s_add_i32 s96, s96, 1
	v_mul_f32_e32 v104, s30, v104
	v_cmp_gt_i32_e32 vcc, s2, v102
	s_cmp_eq_u32 s95, 0
	s_nop 0
	v_cndmask_b32_e32 v104, v95, v104, vcc
	ds_write_b32 v103, v104 offset:32768
	s_cbranch_scc0 .LBB0_9
.Lft3:
	s_addk_i32 s94, 0x100
	s_cmp_lt_i32 s94, s92
	v_add_u32_e32 v101, 0x400, v101
	s_cbranch_scc1 .LBB0_8
.Lft4:
	s_mov_b32 s2, 0
	v_mov_b32_e32 v10, 0xff800000
	v_mov_b32_e32 v11, 0xff800000
	v_mov_b32_e32 v9, 0xff800000
	v_mov_b32_e32 v8, 0xff800000
	.p2align	5, , 4
.LBB0_12:
	v_lshl_add_u32 v12, s2, 2, v73
	v_max_f32_e32 v13, v10, v10
	v_max_f32_e32 v14, v11, v11
	v_max_f32_e32 v15, v9, v9
	v_max_f32_e32 v16, v8, v8
	ds_read2st64_b32 v[8:9], v12 offset1:32
	ds_read2st64_b32 v[10:11], v12 offset0:64 offset1:96
	s_addk_i32 s2, 0x100
	s_cmp_ge_i32 s2, s92
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v8, v8, v8
	v_max_f32_e32 v9, v9, v9
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v12, v10, v10
	v_max_f32_e32 v17, v11, v11
	v_max_f32_e32 v10, v13, v8
	v_max_f32_e32 v11, v14, v9
	v_max_f32_e32 v9, v15, v12
	v_max_f32_e32 v8, v16, v17
	s_cbranch_scc0 .LBB0_12
.Lft5:
	s_branch .LBB0_14
.LBB0_13:
	v_mov_b32_e32 v8, 0xff800000
	v_mov_b32_e32 v9, 0xff800000
	v_mov_b32_e32 v11, 0xff800000
	v_mov_b32_e32 v10, 0xff800000
.LBB0_14:
	ds_write_b32 v92, v10
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_16
.Lft6:
	ds_read_b128 v[12:15], v1 offset:41088
	ds_read_b128 v[16:19], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v10, v13, v13
	v_max_f32_e32 v12, v12, v12
	v_max_f32_e32 v10, v12, v10
	v_max3_f32 v10, v10, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v10, v10, v16, v17
	v_max3_f32 v10, v10, v18, v19
	ds_write_b32 v72, v10
.LBB0_16:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v89 offset:112
	ds_read_b128 v[16:19], v89 offset:96
	ds_read_b128 v[20:23], v89
	ds_read_b128 v[24:27], v89 offset:16
	ds_read_b128 v[28:31], v89 offset:80
	ds_read_b128 v[32:35], v89 offset:64
	ds_read_b128 v[36:39], v89 offset:32
	ds_read_b128 v[40:43], v89 offset:48
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v10, v20, v21, v22
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v10, v10, v23, v24
	v_max3_f32 v10, v10, v25, v26
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v10, v10, v27, v36
	v_max3_f32 v10, v10, v37, v38
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v10, v10, v39, v40
	v_max3_f32 v10, v10, v41, v42
	v_max3_f32 v10, v10, v43, v32
	v_max3_f32 v10, v10, v33, v34
	v_max3_f32 v10, v10, v35, v28
	v_max3_f32 v10, v10, v29, v30
	v_max3_f32 v10, v10, v31, v16
	v_max3_f32 v10, v10, v17, v18
	v_max3_f32 v10, v10, v19, v12
	v_max3_f32 v10, v10, v13, v14
	v_max3_f32 v42, v100, v10, v15
	v_sub_f32_e32 v10, v100, v42
	v_cmp_ngt_f32_e32 vcc, s85, v10
	v_cmp_nlt_f32_e64 s[2:3], s87, v10
	s_barrier
	ds_write_b32 v92, v11
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], s[0:1]
	s_cbranch_execz .LBB0_18
.Lft7:
	ds_read_b128 v[12:15], v1 offset:41088
	ds_read_b128 v[16:19], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v11, v13, v13
	v_max_f32_e32 v12, v12, v12
	v_max_f32_e32 v11, v12, v11
	v_max3_f32 v11, v11, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v11, v11, v16, v17
	v_max3_f32 v11, v11, v18, v19
	ds_write_b32 v72, v11
.LBB0_18:
	s_or_b64 exec, exec, s[4:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v89 offset:112
	ds_read_b128 v[16:19], v89 offset:96
	ds_read_b128 v[20:23], v89
	ds_read_b128 v[24:27], v89 offset:16
	ds_read_b128 v[28:31], v89 offset:80
	ds_read_b128 v[32:35], v89 offset:64
	ds_read_b128 v[36:39], v89 offset:32
	ds_read_b128 v[44:47], v89 offset:48
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v11, v20, v21, v22
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v11, v11, v23, v24
	v_max3_f32 v11, v11, v25, v26
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v11, v11, v27, v36
	v_max3_f32 v11, v11, v37, v38
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v11, v11, v39, v44
	v_max3_f32 v11, v11, v45, v46
	v_max3_f32 v11, v11, v47, v32
	v_max3_f32 v11, v11, v33, v34
	v_max3_f32 v11, v11, v35, v28
	v_max3_f32 v11, v11, v29, v30
	v_max3_f32 v11, v11, v31, v16
	v_max3_f32 v11, v11, v17, v18
	v_max3_f32 v11, v11, v19, v12
	v_max3_f32 v11, v11, v13, v14
	v_max3_f32 v43, v99, v11, v15
	v_sub_f32_e32 v11, v99, v43
	v_cmp_ngt_f32_e64 s[4:5], s85, v11
	v_cmp_nlt_f32_e64 s[6:7], s87, v11
	s_barrier
	ds_write_b32 v92, v9
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_cbranch_execz .LBB0_20
.Lft8:
	ds_read_b128 v[12:15], v1 offset:41088
	ds_read_b128 v[16:19], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v9, v13, v13
	v_max_f32_e32 v12, v12, v12
	v_max_f32_e32 v9, v12, v9
	v_max3_f32 v9, v9, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v9, v9, v16, v17
	v_max3_f32 v9, v9, v18, v19
	ds_write_b32 v72, v9
.LBB0_20:
	s_or_b64 exec, exec, s[8:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v89 offset:112
	ds_read_b128 v[16:19], v89 offset:96
	ds_read_b128 v[20:23], v89
	ds_read_b128 v[24:27], v89 offset:16
	ds_read_b128 v[28:31], v89 offset:80
	ds_read_b128 v[32:35], v89 offset:64
	ds_read_b128 v[36:39], v89 offset:32
	ds_read_b128 v[44:47], v89 offset:48
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v9, v20, v21, v22
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v9, v9, v23, v24
	v_max3_f32 v9, v9, v25, v26
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v9, v9, v27, v36
	v_max3_f32 v9, v9, v37, v38
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v9, v9, v39, v44
	v_max3_f32 v9, v9, v45, v46
	v_max3_f32 v9, v9, v47, v32
	v_max3_f32 v9, v9, v33, v34
	v_max3_f32 v9, v9, v35, v28
	v_max3_f32 v9, v9, v29, v30
	v_max3_f32 v9, v9, v31, v16
	v_max3_f32 v9, v9, v17, v18
	v_max3_f32 v9, v9, v19, v12
	v_max3_f32 v9, v9, v13, v14
	v_max3_f32 v40, v98, v9, v15
	v_sub_f32_e32 v9, v98, v40
	v_cmp_ngt_f32_e64 s[8:9], s85, v9
	v_cmp_nlt_f32_e64 s[10:11], s87, v9
	s_barrier
	ds_write_b32 v92, v8
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[12:13], s[0:1]
	s_cbranch_execz .LBB0_22
.Lft9:
	ds_read_b128 v[12:15], v1 offset:41088
	ds_read_b128 v[16:19], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v8, v13, v13
	v_max_f32_e32 v12, v12, v12
	v_max_f32_e32 v8, v12, v8
	v_max3_f32 v8, v8, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v8, v8, v16, v17
	v_max3_f32 v8, v8, v18, v19
	ds_write_b32 v72, v8
.LBB0_22:
	s_or_b64 exec, exec, s[12:13]
	v_mul_f32_e32 v8, 0x3fb8aa3b, v10
	v_fma_f32 v12, v10, s24, -v8
	v_fmac_f32_e32 v12, 0x32a5705f, v10
	v_rndne_f32_e32 v10, v8
	v_sub_f32_e32 v8, v8, v10
	v_add_f32_e32 v8, v8, v12
	v_cvt_i32_f32_e32 v10, v10
	v_exp_f32_e32 v8, v8
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_ldexp_f32 v8, v8, v10
	v_mul_f32_e32 v10, 0x3fb8aa3b, v11
	v_fma_f32 v12, v11, s24, -v10
	v_fmac_f32_e32 v12, 0x32a5705f, v11
	v_rndne_f32_e32 v11, v10
	v_sub_f32_e32 v10, v10, v11
	v_add_f32_e32 v10, v10, v12
	v_mul_f32_e32 v12, 0x3fb8aa3b, v9
	v_fma_f32 v13, v9, s24, -v12
	v_fmac_f32_e32 v13, 0x32a5705f, v9
	v_rndne_f32_e32 v9, v12
	v_sub_f32_e32 v12, v12, v9
	v_add_f32_e32 v12, v12, v13
	v_exp_f32_e32 v10, v10
	v_cvt_i32_f32_e32 v11, v11
	v_exp_f32_e32 v12, v12
	v_cvt_i32_f32_e32 v9, v9
	v_cndmask_b32_e32 v8, 0, v8, vcc
	v_ldexp_f32 v10, v10, v11
	v_cndmask_b32_e64 v10, 0, v10, s[4:5]
	v_ldexp_f32 v9, v12, v9
	v_cndmask_b32_e64 v9, 0, v9, s[8:9]
	v_cndmask_b32_e64 v8, v96, v8, s[2:3]
	v_cndmask_b32_e64 v10, v96, v10, s[6:7]
	v_cndmask_b32_e64 v9, v96, v9, s[10:11]
	v_mul_f32_e32 v4, v4, v8
	v_mul_f32_e32 v86, v86, v8
	v_mul_f32_e32 v84, v84, v8
	v_mul_f32_e32 v82, v82, v8
	v_mul_f32_e32 v6, v6, v8
	v_mul_f32_e32 v5, v5, v10
	v_mul_f32_e32 v87, v87, v10
	v_mul_f32_e32 v85, v85, v10
	v_mul_f32_e32 v83, v83, v10
	v_mul_f32_e32 v7, v7, v10
	v_mul_f32_e32 v74, v74, v9
	v_mul_f32_e32 v80, v80, v9
	v_mul_f32_e32 v2, v2, v9
	v_mul_f32_e32 v78, v78, v9
	v_mul_f32_e32 v76, v76, v9
	ds_read_b128 v[8:11], v89 offset:112
	ds_read_b128 v[12:15], v89 offset:96
	ds_read_b128 v[16:19], v89
	ds_read_b128 v[20:23], v89 offset:16
	ds_read_b128 v[24:27], v89 offset:80
	ds_read_b128 v[28:31], v89 offset:64
	ds_read_b128 v[32:35], v89 offset:32
	ds_read_b128 v[36:39], v89 offset:48
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v16, v16, v17, v18
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v16, v16, v19, v20
	v_max3_f32 v16, v16, v21, v22
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v16, v16, v23, v32
	v_max3_f32 v16, v16, v33, v34
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v16, v16, v35, v36
	v_max3_f32 v16, v16, v37, v38
	v_max3_f32 v16, v16, v39, v28
	v_max3_f32 v16, v16, v29, v30
	v_max3_f32 v16, v16, v31, v24
	v_max3_f32 v16, v16, v25, v26
	v_max3_f32 v12, v16, v27, v12
	v_max3_f32 v12, v12, v13, v14
	v_max3_f32 v8, v12, v15, v8
	v_max3_f32 v8, v8, v9, v10
	v_max3_f32 v41, v97, v8, v11
	v_sub_f32_e32 v8, v97, v41
	v_mul_f32_e32 v9, 0x3fb8aa3b, v8
	v_fma_f32 v10, v8, s24, -v9
	v_rndne_f32_e32 v11, v9
	v_fmac_f32_e32 v10, 0x32a5705f, v8
	v_sub_f32_e32 v9, v9, v11
	v_add_f32_e32 v9, v9, v10
	v_exp_f32_e32 v9, v9
	v_cvt_i32_f32_e32 v10, v11
	v_cmp_ngt_f32_e32 vcc, s85, v8
	s_barrier
	v_ldexp_f32 v9, v9, v10
	v_cndmask_b32_e32 v9, 0, v9, vcc
	v_cmp_nlt_f32_e32 vcc, s87, v8
	s_nop 1
	v_cndmask_b32_e32 v8, v96, v9, vcc
	v_mul_f32_e32 v75, v75, v8
	v_mul_f32_e32 v81, v81, v8
	v_mul_f32_e32 v3, v3, v8
	v_mul_f32_e32 v79, v79, v8
	v_mul_f32_e32 v77, v77, v8
	s_and_b64 vcc, exec, s[90:91]
	s_cbranch_vccz .LBB0_5
.Lft10:
	s_add_i32 s4, s25, s92
	s_add_i32 s4, s4, -1
	v_or_b32_e32 v20, s25, v93
	s_mov_b32 s5, 0
	.p2align	5, , 4
.LBB0_24:
	v_lshl_add_u32 v10, s5, 2, v73
	ds_read2st64_b32 v[8:9], v10 offset1:32
	ds_read2st64_b32 v[10:11], v10 offset0:64 offset1:96
	v_add_u32_e32 v21, s5, v20
	s_mov_b64 s[2:3], -1
	s_mov_b32 s6, 0
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[8:9], v[8:9], v[42:43] neg_lo:[0,1] neg_hi:[0,1]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[10:11], v[10:11], v[40:41] neg_lo:[0,1] neg_hi:[0,1]
	v_pk_mul_f32 v[8:9], v[8:9], s[24:25] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], s[24:25] op_sel_hi:[1,0]
	v_exp_f32_e32 v16, v8
	v_exp_f32_e32 v17, v9
	v_exp_f32_e32 v18, v10
	v_exp_f32_e32 v19, v11
	ds_write2st64_b32 v73, v16, v17 offset0:128 offset1:132
	ds_write2st64_b32 v73, v18, v19 offset0:136 offset1:140
	s_waitcnt lgkmcnt(0)
	s_barrier
.LBB0_25:
	v_or_b32_e32 v9, s6, v21
	v_min_i32_e32 v38, s4, v9
	v_or_b32_e32 v52, 1, v9
	v_or_b32_e32 v53, 2, v9
	v_ashrrev_i32_e32 v39, 31, v38
	v_or_b32_e32 v55, 3, v9
	v_min_i32_e32 v52, s4, v52
	v_min_i32_e32 v54, s4, v53
	v_lshlrev_b64 v[38:39], 8, v[38:39]
	v_min_i32_e32 v56, s4, v55
	v_ashrrev_i32_e32 v53, 31, v52
	v_ashrrev_i32_e32 v55, 31, v54
	v_lshl_add_u64 v[38:39], v[90:91], 0, v[38:39]
	v_lshlrev_b64 v[66:67], 8, v[52:53]
	v_lshlrev_b64 v[68:69], 8, v[54:55]
	global_load_dwordx4 v[52:55], v[38:39], off
	v_or_b32_e32 v57, 4, v9
	v_or_b32_e32 v59, 5, v9
	v_or_b32_e32 v61, 6, v9
	v_or_b32_e32 v63, 7, v9
	v_min_i32_e32 v58, s4, v57
	v_min_i32_e32 v60, s4, v59
	v_min_i32_e32 v62, s4, v61
	v_min_i32_e32 v64, s4, v63
	v_ashrrev_i32_e32 v57, 31, v56
	v_ashrrev_i32_e32 v59, 31, v58
	v_ashrrev_i32_e32 v61, 31, v60
	v_ashrrev_i32_e32 v63, 31, v62
	v_ashrrev_i32_e32 v65, 31, v64
	v_lshlrev_b64 v[56:57], 8, v[56:57]
	v_lshlrev_b64 v[58:59], 8, v[58:59]
	v_lshlrev_b64 v[60:61], 8, v[60:61]
	v_lshlrev_b64 v[62:63], 8, v[62:63]
	v_lshlrev_b64 v[64:65], 8, v[64:65]
	v_lshl_add_u64 v[38:39], v[90:91], 0, v[66:67]
	v_lshl_add_u64 v[66:67], v[90:91], 0, v[68:69]
	v_lshl_add_u64 v[68:69], v[90:91], 0, v[56:57]
	v_lshl_add_u64 v[70:71], v[90:91], 0, v[58:59]
	v_lshl_add_u64 v[98:99], v[90:91], 0, v[60:61]
	v_lshl_add_u64 v[102:103], v[90:91], 0, v[62:63]
	v_lshl_add_u64 v[106:107], v[90:91], 0, v[64:65]
	global_load_dwordx4 v[56:59], v[38:39], off
	global_load_dwordx4 v[60:63], v[66:67], off
	s_nop 0
	global_load_dwordx4 v[64:67], v[68:69], off
	s_nop 0
	global_load_dwordx4 v[68:71], v[70:71], off
	s_nop 0
	global_load_dwordx4 v[98:101], v[98:99], off
	s_nop 0
	global_load_dwordx4 v[102:105], v[102:103], off
	s_nop 0
	global_load_dwordx4 v[106:109], v[106:107], off
	v_cndmask_b32_e64 v8, 0, 1, s[2:3]
	v_lshl_add_u32 v12, s6, 2, v94
	v_cmp_ne_u32_e32 vcc, 1, v8
	ds_read_b128 v[22:25], v12
	ds_read_b128 v[26:29], v12 offset:16
	ds_read_b128 v[30:33], v12 offset:1024
	ds_read_b128 v[8:11], v12 offset:1040
	ds_read_b128 v[34:37], v12 offset:2048
	ds_read_b128 v[44:47], v12 offset:2064
	ds_read_b128 v[48:51], v12 offset:3072
	ds_read_b128 v[12:15], v12 offset:3088
	s_waitcnt lgkmcnt(7)
	v_mov_b32_e32 v38, v22
	s_waitcnt lgkmcnt(5)
	v_mov_b32_e32 v39, v30
	v_mov_b32_e32 v30, v23
	v_mov_b32_e32 v22, v24
	v_mov_b32_e32 v23, v32
	v_mov_b32_e32 v32, v25
	v_mov_b32_e32 v24, v26
	s_waitcnt lgkmcnt(4)
	v_mov_b32_e32 v25, v8
	v_mov_b32_e32 v8, v27
	v_mov_b32_e32 v26, v28
	v_mov_b32_e32 v27, v10
	v_mov_b32_e32 v10, v29
	s_waitcnt lgkmcnt(3)
	v_mov_b32_e32 v28, v34
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v29, v48
	v_mov_b32_e32 v48, v35
	v_mov_b32_e32 v34, v36
	v_mov_b32_e32 v35, v50
	v_mov_b32_e32 v50, v37
	v_mov_b32_e32 v36, v44
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v37, v12
	v_mov_b32_e32 v12, v45
	v_mov_b32_e32 v44, v46
	v_mov_b32_e32 v45, v14
	v_mov_b32_e32 v14, v47
	s_mov_b32 s6, 8
	s_mov_b64 s[2:3], 0
	s_and_b64 vcc, exec, vcc
	s_waitcnt vmcnt(7)
	v_pk_fma_f32 v[46:47], v[38:39], v[52:53], v[86:87] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[80:81], v[28:29], v[52:53], v[80:81] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[84:85], v[38:39], v[52:53], v[84:85] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[28:29], v[52:53], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[52:53], v[38:39], v[54:55], v[82:83] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[78:79], v[28:29], v[54:55], v[78:79] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v54, v55
	v_pk_fma_f32 v[6:7], v[38:39], v[54:55], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[28:29], v[54:55], v[76:77] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(6)
	v_mov_b32_e32 v38, v59
	v_pk_fma_f32 v[80:81], v[48:49], v[56:57], v[80:81] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[46:47], v[30:31], v[56:57], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[48:49], v[56:57], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[30:31], v[56:57], v[84:85] op_sel:[0,1,0]
	v_pk_fma_f32 v[78:79], v[48:49], v[58:59], v[78:79] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[52:53], v[30:31], v[58:59], v[52:53] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(5)
	v_mov_b32_e32 v54, v63
	v_pk_fma_f32 v[28:29], v[48:49], v[38:39], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[30:31], v[38:39], v[6:7] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(4)
	v_mov_b32_e32 v58, v67
	v_pk_fma_f32 v[46:47], v[22:23], v[60:61], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[80:81], v[34:35], v[60:61], v[80:81] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[56:57], v[22:23], v[60:61], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[34:35], v[60:61], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[52:53], v[22:23], v[62:63], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[34:35], v[62:63], v[78:79] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[22:23], v[54:55], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[34:35], v[54:55], v[28:29] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(3)
	v_mov_b32_e32 v76, v71
	v_pk_fma_f32 v[30:31], v[50:51], v[64:65], v[80:81] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[38:39], v[32:33], v[64:65], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[50:51], v[64:65], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[46:47], v[32:33], v[64:65], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[48:49], v[50:51], v[66:67], v[60:61] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[52:53], v[32:33], v[66:67], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[50:51], v[58:59], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[32:33], v[58:59], v[6:7] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(2)
	v_mov_b32_e32 v82, v101
	v_pk_fma_f32 v[28:29], v[24:25], v[68:69], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[30:31], v[36:37], v[68:69], v[30:31] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[34:35], v[24:25], v[68:69], v[46:47] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[36:37], v[68:69], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[38:39], v[24:25], v[70:71], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[46:47], v[36:37], v[70:71], v[48:49] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[24:25], v[76:77], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[36:37], v[76:77], v[22:23] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(1)
	v_mov_b32_e32 v110, v105
	v_pk_fma_f32 v[30:31], v[12:13], v[98:99], v[30:31] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[8:9], v[98:99], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[12:13], v[98:99], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[32:33], v[8:9], v[98:99], v[34:35] op_sel:[0,1,0]
	v_pk_fma_f32 v[34:35], v[12:13], v[100:101], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[38:39], v[8:9], v[100:101], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[12:13], v[12:13], v[82:83], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[8:9], v[82:83], v[6:7] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v112, v109
	v_pk_fma_f32 v[24:25], v[26:27], v[102:103], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[44:45], v[102:103], v[30:31] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[30:31], v[26:27], v[102:103], v[32:33] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[44:45], v[102:103], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[32:33], v[26:27], v[104:105], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[34:35], v[44:45], v[104:105], v[34:35] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[26:27], v[110:111], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[44:45], v[110:111], v[12:13] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[80:81], v[14:15], v[106:107], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[86:87], v[10:11], v[106:107], v[24:25] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[14:15], v[106:107], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[84:85], v[10:11], v[106:107], v[30:31] op_sel:[0,1,0]
	v_pk_fma_f32 v[78:79], v[14:15], v[108:109], v[34:35] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[82:83], v[10:11], v[108:109], v[32:33] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[76:77], v[14:15], v[112:113], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[10:11], v[112:113], v[6:7] op_sel_hi:[1,0,1]
	s_cbranch_vccz .LBB0_25
.Lft11:
	s_addk_i32 s5, 0x100
	v_pk_add_f32 v[74:75], v[74:75], v[18:19]
	v_pk_add_f32 v[4:5], v[4:5], v[16:17]
	s_cmp_ge_i32 s5, s92
	s_barrier
	s_cbranch_scc0 .LBB0_24
.Lft12:
	s_branch .LBB0_5
.LBB0_27:
	v_mov_b32_e32 v40, v41
	v_mov_b32_e32 v43, v41
	v_mov_b32_e32 v42, v41
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v74, v89
	v_mov_b32_e32 v5, v89
	v_mov_b32_e32 v4, v89
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v76, v89
	v_mov_b32_e32 v7, v89
	v_mov_b32_e32 v6, v89
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v78, v89
	v_mov_b32_e32 v83, v89
	v_mov_b32_e32 v82, v89
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v2, v89
	v_mov_b32_e32 v85, v89
	v_mov_b32_e32 v84, v89
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v80, v89
	v_mov_b32_e32 v87, v89
	v_mov_b32_e32 v86, v89
.LBB0_28:
	v_add_u32_e32 v47, 0xa080, v72
	v_cmp_gt_u32_e64 s[4:5], 32, v0
	ds_write_b32 v72, v4 offset:41088
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_30
.Lft13:
	ds_read_b128 v[8:11], v1 offset:41088
	ds_read_b128 v[12:15], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v8, v9
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v4, v12
	v_add_f32_e32 v4, v4, v13
	v_add_f32_e32 v4, v4, v14
	v_add_f32_e32 v4, v4, v15
	ds_write_b32 v72, v4
.LBB0_30:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v73, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[36:39], v73
	ds_read_b128 v[32:35], v73 offset:16
	ds_read_b128 v[28:31], v73 offset:32
	ds_read_b128 v[24:27], v73 offset:48
	ds_read_b128 v[20:23], v73 offset:64
	ds_read_b128 v[16:19], v73 offset:80
	ds_read_b128 v[12:15], v73 offset:96
	ds_read_b128 v[8:11], v73 offset:112
	v_and_b32_e32 v4, 0xfc0, v72
	s_mov_b32 s0, 0x9080
	s_cmp_lt_i32 s84, s28
	v_lshl_add_u32 v4, v4, 2, s0
	v_cmp_gt_u32_e64 s[2:3], 64, v0
	s_cselect_b64 s[6:7], -1, 0
	v_add_u32_e32 v46, 0xfffff000, v47
	v_lshl_add_u64 v[44:45], s[26:27], 0, v[72:73]
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	v_add_u32_e32 v0, v4, v88
	v_mov_b32_e32 v48, v86
	v_mov_b32_e32 v49, v84
	v_mov_b32_e32 v50, v82
	v_mov_b32_e32 v51, v6
	s_and_b64 s[8:9], s[2:3], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[48:51]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[8:9]
	s_cbranch_execz .LBB0_33
.Lft14:
	v_add_f32_e32 v4, v36, v37
	v_add_f32_e32 v4, v4, v38
	v_add_f32_e32 v4, v4, v39
	v_add_f32_e32 v4, v4, v32
	v_add_f32_e32 v4, v4, v33
	v_add_f32_e32 v4, v4, v34
	v_add_f32_e32 v4, v4, v35
	v_add_f32_e32 v4, v4, v28
	v_add_f32_e32 v4, v4, v29
	v_add_f32_e32 v4, v4, v30
	v_add_f32_e32 v4, v4, v31
	v_add_f32_e32 v4, v4, v24
	v_add_f32_e32 v4, v4, v25
	v_add_f32_e32 v4, v4, v26
	v_add_f32_e32 v4, v4, v27
	v_add_f32_e32 v4, v4, v20
	v_add_f32_e32 v4, v4, v21
	v_add_f32_e32 v4, v4, v22
	v_add_f32_e32 v4, v4, v23
	v_add_f32_e32 v4, v4, v16
	v_add_f32_e32 v4, v4, v17
	v_add_f32_e32 v4, v4, v18
	v_add_f32_e32 v4, v4, v19
	v_add_f32_e32 v4, v4, v12
	v_add_f32_e32 v4, v4, v13
	v_add_f32_e32 v4, v4, v14
	v_add_f32_e32 v4, v4, v15
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	ds_read2st64_b32 v[8:9], v46 offset1:1
	ds_read2st64_b32 v[12:13], v46 offset0:2 offset1:3
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	ds_read2st64_b32 v[10:11], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[14:15], v46 offset0:6 offset1:7
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v6, v8, v9
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v6, v6, v12
	v_add_f32_e32 v6, v6, v13
	ds_read2st64_b32 v[8:9], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v6, v6, v10
	v_add_f32_e32 v6, v6, v11
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v6, v14
	v_add_f32_e32 v6, v6, v15
	ds_read2st64_b32 v[10:11], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[12:13], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[14:15], v46 offset0:14 offset1:15
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v6, v9
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v6, v6, v10
	v_add_f32_e32 v6, v6, v11
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v6, v12
	v_add_f32_e32 v6, v6, v13
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v6, v6, v14
	v_add_f32_e32 v6, v6, v15
	v_div_scale_f32 v8, s[8:9], v4, v4, v6
	v_rcp_f32_e32 v9, v8
	s_ashr_i32 s85, s84, 31
	s_lshl_b64 s[8:9], s[84:85], 8
	v_fma_f32 v10, -v8, v9, 1.0
	v_fmac_f32_e32 v9, v10, v9
	v_div_scale_f32 v10, vcc, v6, v4, v6
	v_mul_f32_e32 v11, v10, v9
	v_fma_f32 v12, -v8, v11, v10
	v_fmac_f32_e32 v11, v12, v9
	v_fma_f32 v8, -v8, v11, v10
	v_div_fmas_f32 v8, v8, v9, v11
	v_div_fixup_f32 v6, v8, v4, v6
	v_lshl_add_u64 v[8:9], v[44:45], 0, s[8:9]
	global_store_dword v[8:9], v6, off
	s_and_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_33
.Lft15:
	s_mov_b32 s8, 0x800000
	v_cmp_gt_f32_e32 vcc, s8, v4
	s_and_b64 s[8:9], vcc, exec
	s_cselect_b32 s8, 32, 0
	v_ldexp_f32 v4, v4, s8
	v_log_f32_e32 v4, v4
	s_mov_b32 s8, 0x3f317217
	v_mov_b32_e32 v6, 0x41b17218
	v_cndmask_b32_e32 v6, 0, v6, vcc
	v_mul_f32_e32 v8, 0x3f317217, v4
	v_fma_f32 v9, v4, s8, -v8
	v_fmamk_f32 v9, v4, 0x3377d1cf, v9
	s_mov_b32 s8, 0x7f800000
	v_add_f32_e32 v8, v8, v9
	v_cmp_lt_f32_e64 vcc, |v4|, s8
	s_lshl_b64 s[8:9], s[84:85], 2
	s_add_u32 s8, s34, s8
	v_cndmask_b32_e32 v4, v4, v8, vcc
	v_sub_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v42, v4
	s_addc_u32 s9, s35, s9
	v_mov_b32_e32 v6, 0
	global_store_dword v6, v4, s[8:9]
.LBB0_33:
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	ds_write_b32 v47, v5
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_35
.Lft16:
	ds_read_b128 v[8:11], v1 offset:41088
	ds_read_b128 v[12:15], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v8, v9
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v4, v12
	v_add_f32_e32 v4, v4, v13
	v_add_f32_e32 v4, v4, v14
	v_add_f32_e32 v4, v4, v15
	ds_write_b32 v72, v4
.LBB0_35:
	s_or_b64 exec, exec, s[6:7]
	v_mov_b32_e32 v4, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[36:39], v4
	ds_read_b128 v[32:35], v4 offset:16
	ds_read_b128 v[28:31], v4 offset:32
	ds_read_b128 v[24:27], v4 offset:48
	ds_read_b128 v[20:23], v4 offset:64
	ds_read_b128 v[16:19], v4 offset:80
	ds_read_b128 v[12:15], v4 offset:96
	ds_read_b128 v[8:11], v4 offset:112
	s_or_b32 s8, s84, 1
	s_cmp_lt_i32 s8, s28
	s_cselect_b64 s[6:7], -1, 0
	v_mov_b32_e32 v4, v87
	v_mov_b32_e32 v5, v85
	v_mov_b32_e32 v6, v83
	s_and_b64 s[10:11], s[2:3], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[4:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[10:11]
	s_cbranch_execz .LBB0_38
.Lft17:
	v_add_f32_e32 v4, v36, v37
	v_add_f32_e32 v4, v4, v38
	v_add_f32_e32 v4, v4, v39
	v_add_f32_e32 v4, v4, v32
	v_add_f32_e32 v4, v4, v33
	v_add_f32_e32 v4, v4, v34
	v_add_f32_e32 v4, v4, v35
	v_add_f32_e32 v4, v4, v28
	v_add_f32_e32 v4, v4, v29
	v_add_f32_e32 v4, v4, v30
	v_add_f32_e32 v4, v4, v31
	v_add_f32_e32 v4, v4, v24
	v_add_f32_e32 v4, v4, v25
	v_add_f32_e32 v4, v4, v26
	v_add_f32_e32 v4, v4, v27
	v_add_f32_e32 v4, v4, v20
	v_add_f32_e32 v4, v4, v21
	v_add_f32_e32 v4, v4, v22
	v_add_f32_e32 v4, v4, v23
	v_add_f32_e32 v4, v4, v16
	v_add_f32_e32 v4, v4, v17
	v_add_f32_e32 v4, v4, v18
	v_add_f32_e32 v4, v4, v19
	v_add_f32_e32 v4, v4, v12
	v_add_f32_e32 v4, v4, v13
	v_add_f32_e32 v4, v4, v14
	v_add_f32_e32 v4, v4, v15
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	ds_read2st64_b32 v[6:7], v46 offset1:1
	ds_read2st64_b32 v[8:9], v46 offset0:2 offset1:3
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	ds_read2st64_b32 v[10:11], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[12:13], v46 offset0:6 offset1:7
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v5, v6, v7
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v5, v5, v8
	v_add_f32_e32 v5, v5, v9
	ds_read2st64_b32 v[6:7], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v5, v5, v10
	v_add_f32_e32 v5, v5, v11
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v5, v5, v12
	v_add_f32_e32 v5, v5, v13
	ds_read2st64_b32 v[8:9], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[10:11], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[12:13], v46 offset0:14 offset1:15
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v5, v5, v6
	v_add_f32_e32 v5, v5, v7
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v5, v5, v8
	v_add_f32_e32 v5, v5, v9
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v5, v5, v10
	v_add_f32_e32 v5, v5, v11
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v5, v5, v12
	v_add_f32_e32 v5, v5, v13
	v_div_scale_f32 v6, s[10:11], v4, v4, v5
	v_rcp_f32_e32 v7, v6
	s_ashr_i32 s9, s8, 31
	s_lshl_b64 s[8:9], s[8:9], 8
	v_fma_f32 v8, -v6, v7, 1.0
	v_fmac_f32_e32 v7, v8, v7
	v_div_scale_f32 v8, vcc, v5, v4, v5
	v_mul_f32_e32 v9, v8, v7
	v_fma_f32 v10, -v6, v9, v8
	v_fmac_f32_e32 v9, v10, v7
	v_fma_f32 v6, -v6, v9, v8
	v_div_fmas_f32 v6, v6, v7, v9
	v_div_fixup_f32 v5, v6, v4, v5
	v_lshl_add_u64 v[6:7], v[44:45], 0, s[8:9]
	global_store_dword v[6:7], v5, off
	s_and_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_38
.Lft18:
	s_mov_b32 s8, 0x800000
	v_cmp_gt_f32_e32 vcc, s8, v4
	s_and_b64 s[8:9], vcc, exec
	s_cselect_b32 s8, 32, 0
	v_ldexp_f32 v4, v4, s8
	v_log_f32_e32 v4, v4
	s_mov_b32 s8, 0x3f317217
	v_mov_b32_e32 v5, 0x41b17218
	v_cndmask_b32_e32 v5, 0, v5, vcc
	v_mul_f32_e32 v6, 0x3f317217, v4
	v_fma_f32 v7, v4, s8, -v6
	v_fmamk_f32 v7, v4, 0x3377d1cf, v7
	s_mov_b32 s8, 0x7f800000
	v_add_f32_e32 v6, v6, v7
	v_cmp_lt_f32_e64 vcc, |v4|, s8
	s_ashr_i32 s85, s84, 31
	s_lshl_b64 s[8:9], s[84:85], 2
	v_cndmask_b32_e32 v4, v4, v6, vcc
	v_sub_f32_e32 v4, v4, v5
	s_add_u32 s8, s34, s8
	v_add_f32_e32 v4, v43, v4
	s_addc_u32 s9, s35, s9
	v_mov_b32_e32 v5, 0
	global_store_dword v5, v4, s[8:9] offset:4
.LBB0_38:
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	ds_write_b32 v47, v74
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_40
.Lft19:
	ds_read_b128 v[4:7], v1 offset:41088
	ds_read_b128 v[8:11], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v5
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v4, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	ds_write_b32 v72, v4
.LBB0_40:
	s_or_b64 exec, exec, s[6:7]
	v_mov_b32_e32 v4, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[32:35], v4
	ds_read_b128 v[28:31], v4 offset:16
	ds_read_b128 v[24:27], v4 offset:32
	ds_read_b128 v[20:23], v4 offset:48
	ds_read_b128 v[16:19], v4 offset:64
	ds_read_b128 v[12:15], v4 offset:80
	ds_read_b128 v[8:11], v4 offset:96
	ds_read_b128 v[4:7], v4 offset:112
	s_or_b32 s8, s84, 2
	s_cmp_lt_i32 s8, s28
	s_cselect_b64 s[6:7], -1, 0
	v_mov_b32_e32 v36, v80
	v_mov_b32_e32 v37, v2
	v_mov_b32_e32 v38, v78
	v_mov_b32_e32 v39, v76
	s_and_b64 s[10:11], s[2:3], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[36:39]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[10:11]
	s_cbranch_execz .LBB0_43
.Lft20:
	v_add_f32_e32 v2, v32, v33
	v_add_f32_e32 v2, v2, v34
	v_add_f32_e32 v2, v2, v35
	v_add_f32_e32 v2, v2, v28
	v_add_f32_e32 v2, v2, v29
	v_add_f32_e32 v2, v2, v30
	v_add_f32_e32 v2, v2, v31
	v_add_f32_e32 v2, v2, v24
	v_add_f32_e32 v2, v2, v25
	v_add_f32_e32 v2, v2, v26
	v_add_f32_e32 v2, v2, v27
	v_add_f32_e32 v2, v2, v20
	v_add_f32_e32 v2, v2, v21
	v_add_f32_e32 v2, v2, v22
	v_add_f32_e32 v2, v2, v23
	v_add_f32_e32 v2, v2, v16
	v_add_f32_e32 v2, v2, v17
	v_add_f32_e32 v2, v2, v18
	v_add_f32_e32 v2, v2, v19
	v_add_f32_e32 v2, v2, v12
	v_add_f32_e32 v2, v2, v13
	v_add_f32_e32 v2, v2, v14
	v_add_f32_e32 v2, v2, v15
	v_add_f32_e32 v2, v2, v8
	v_add_f32_e32 v2, v2, v9
	v_add_f32_e32 v2, v2, v10
	v_add_f32_e32 v2, v2, v11
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	ds_read2st64_b32 v[4:5], v46 offset1:1
	ds_read2st64_b32 v[8:9], v46 offset0:2 offset1:3
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	ds_read2st64_b32 v[6:7], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[10:11], v46 offset0:6 offset1:7
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v4, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v6, v4, v10
	ds_read2st64_b32 v[4:5], v46 offset0:8 offset1:9
	v_add_f32_e32 v12, v6, v11
	ds_read2st64_b32 v[6:7], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[8:9], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[10:11], v46 offset0:14 offset1:15
	s_ashr_i32 s9, s8, 31
	s_lshl_b64 s[8:9], s[8:9], 8
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v4, v12, v4
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v4, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	v_div_scale_f32 v5, s[10:11], v2, v2, v4
	v_rcp_f32_e32 v6, v5
	s_nop 0
	v_fma_f32 v7, -v5, v6, 1.0
	v_fmac_f32_e32 v6, v7, v6
	v_div_scale_f32 v7, vcc, v4, v2, v4
	v_mul_f32_e32 v8, v7, v6
	v_fma_f32 v9, -v5, v8, v7
	v_fmac_f32_e32 v8, v9, v6
	v_fma_f32 v5, -v5, v8, v7
	v_div_fmas_f32 v5, v5, v6, v8
	v_div_fixup_f32 v6, v5, v2, v4
	v_lshl_add_u64 v[4:5], v[44:45], 0, s[8:9]
	global_store_dword v[4:5], v6, off
	s_and_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_43
.Lft21:
	s_mov_b32 s8, 0x800000
	v_cmp_gt_f32_e32 vcc, s8, v2
	s_and_b64 s[8:9], vcc, exec
	s_cselect_b32 s8, 32, 0
	v_ldexp_f32 v2, v2, s8
	v_log_f32_e32 v2, v2
	s_mov_b32 s8, 0x3f317217
	v_mov_b32_e32 v4, 0x41b17218
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_mul_f32_e32 v5, 0x3f317217, v2
	v_fma_f32 v6, v2, s8, -v5
	v_fmamk_f32 v6, v2, 0x3377d1cf, v6
	s_mov_b32 s8, 0x7f800000
	v_add_f32_e32 v5, v5, v6
	v_cmp_lt_f32_e64 vcc, |v2|, s8
	s_ashr_i32 s85, s84, 31
	s_lshl_b64 s[8:9], s[84:85], 2
	v_cndmask_b32_e32 v2, v2, v5, vcc
	v_sub_f32_e32 v2, v2, v4
	s_add_u32 s8, s34, s8
	v_add_f32_e32 v2, v40, v2
	s_addc_u32 s9, s35, s9
	v_mov_b32_e32 v4, 0
	global_store_dword v4, v2, s[8:9] offset:8
.LBB0_43:
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	ds_write_b32 v47, v75
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_45
.Lft22:
	ds_read_b128 v[4:7], v1 offset:41088
	ds_read_b128 v[8:11], v1 offset:41104
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v1, v4, v5
	v_add_f32_e32 v1, v1, v6
	v_add_f32_e32 v1, v1, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v8
	v_add_f32_e32 v1, v1, v9
	v_add_f32_e32 v1, v1, v10
	v_add_f32_e32 v1, v1, v11
	ds_write_b32 v72, v1
.LBB0_45:
	s_or_b64 exec, exec, s[6:7]
	v_mov_b32_e32 v1, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[34:37], v1
	ds_read_b128 v[30:33], v1 offset:16
	ds_read_b128 v[26:29], v1 offset:32
	ds_read_b128 v[22:25], v1 offset:48
	ds_read_b128 v[18:21], v1 offset:64
	ds_read_b128 v[14:17], v1 offset:80
	ds_read_b128 v[10:13], v1 offset:96
	ds_read_b128 v[6:9], v1 offset:112
	s_cmp_lt_i32 s86, s28
	s_cselect_b64 s[4:5], -1, 0
	v_mov_b32_e32 v2, v81
	v_mov_b32_e32 v4, v79
	v_mov_b32_e32 v5, v77
	s_and_b64 s[4:5], s[2:3], s[4:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[4:5]
	s_cbranch_execz .LBB0_48
.Lft23:
	v_add_f32_e32 v0, v34, v35
	v_add_f32_e32 v0, v0, v36
	v_add_f32_e32 v0, v0, v37
	v_add_f32_e32 v0, v0, v30
	v_add_f32_e32 v0, v0, v31
	v_add_f32_e32 v0, v0, v32
	v_add_f32_e32 v0, v0, v33
	v_add_f32_e32 v0, v0, v26
	v_add_f32_e32 v0, v0, v27
	v_add_f32_e32 v0, v0, v28
	v_add_f32_e32 v0, v0, v29
	v_add_f32_e32 v0, v0, v22
	v_add_f32_e32 v0, v0, v23
	v_add_f32_e32 v0, v0, v24
	v_add_f32_e32 v0, v0, v25
	v_add_f32_e32 v0, v0, v18
	v_add_f32_e32 v0, v0, v19
	v_add_f32_e32 v0, v0, v20
	v_add_f32_e32 v0, v0, v21
	v_add_f32_e32 v0, v0, v14
	v_add_f32_e32 v0, v0, v15
	v_add_f32_e32 v0, v0, v16
	v_add_f32_e32 v0, v0, v17
	v_add_f32_e32 v0, v0, v10
	v_add_f32_e32 v0, v0, v11
	v_add_f32_e32 v0, v0, v12
	v_add_f32_e32 v0, v0, v13
	v_add_f32_e32 v0, v0, v6
	ds_read2st64_b32 v[2:3], v46 offset1:1
	ds_read2st64_b32 v[4:5], v46 offset0:2 offset1:3
	v_add_f32_e32 v0, v0, v7
	v_add_f32_e32 v0, v0, v8
	v_add_f32_e32 v0, v0, v9
	ds_read2st64_b32 v[6:7], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[8:9], v46 offset0:6 offset1:7
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v1, v2, v3
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v1, v1, v4
	v_add_f32_e32 v1, v1, v5
	ds_read2st64_b32 v[2:3], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v1, v1, v6
	v_add_f32_e32 v1, v1, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v1, v1, v8
	v_add_f32_e32 v1, v1, v9
	ds_read2st64_b32 v[4:5], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[6:7], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[8:9], v46 offset0:14 offset1:15
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v1, v1, v2
	v_add_f32_e32 v1, v1, v3
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v1, v1, v4
	v_add_f32_e32 v1, v1, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v1, v1, v6
	v_add_f32_e32 v1, v1, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v8
	v_add_f32_e32 v1, v1, v9
	v_div_scale_f32 v2, s[4:5], v0, v0, v1
	v_rcp_f32_e32 v3, v2
	s_ashr_i32 s87, s86, 31
	s_lshl_b64 s[4:5], s[86:87], 8
	v_fma_f32 v4, -v2, v3, 1.0
	v_fmac_f32_e32 v3, v4, v3
	v_div_scale_f32 v4, vcc, v1, v0, v1
	v_mul_f32_e32 v5, v4, v3
	v_fma_f32 v6, -v2, v5, v4
	v_fmac_f32_e32 v5, v6, v3
	v_fma_f32 v2, -v2, v5, v4
	v_div_fmas_f32 v2, v2, v3, v5
	v_div_fixup_f32 v1, v2, v0, v1
	v_lshl_add_u64 v[2:3], v[44:45], 0, s[4:5]
	global_store_dword v[2:3], v1, off
	s_and_b64 exec, exec, s[0:1]
	s_cbranch_execz .LBB0_48
.Lft24:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v0
	s_and_b64 s[0:1], vcc, exec
	s_cselect_b32 s0, 32, 0
	v_ldexp_f32 v0, v0, s0
	v_log_f32_e32 v0, v0
	s_mov_b32 s0, 0x3f317217
	v_mov_b32_e32 v1, 0x41b17218
	v_cndmask_b32_e32 v1, 0, v1, vcc
	v_mul_f32_e32 v2, 0x3f317217, v0
	v_fma_f32 v3, v0, s0, -v2
	v_fmamk_f32 v3, v0, 0x3377d1cf, v3
	s_mov_b32 s0, 0x7f800000
	v_add_f32_e32 v2, v2, v3
	v_cmp_lt_f32_e64 vcc, |v0|, s0
	s_ashr_i32 s85, s84, 31
	s_lshl_b64 s[0:1], s[84:85], 2
	v_cndmask_b32_e32 v0, v0, v2, vcc
	v_sub_f32_e32 v0, v0, v1
	s_add_u32 s0, s34, s0
	v_add_f32_e32 v0, v41, v0
	s_addc_u32 s1, s35, s1
	v_mov_b32_e32 v1, 0
	global_store_dword v1, v0, s[0:1] offset:12
.LBB0_48:
	s_or_b64 exec, exec, s[2:3]
	s_barrier
	s_endpgm
.Lfunc_end0:
	.size	fa_attention, .Lfunc_end0-fa_attention
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel fa_attention
		.amdhsa_group_segment_fixed_size 42112
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
		.amdhsa_next_free_vgpr 114
		.amdhsa_next_free_sgpr 98
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
  .group_segment_fixed_size: 42112
  .kernarg_segment_align: 8
  .kernarg_segment_size: 56
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: fa_attention
  .private_segment_fixed_size: 0
  .sgpr_count: 104
  .sgpr_spill_count: 0
  .symbol: fa_attention.kd
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
