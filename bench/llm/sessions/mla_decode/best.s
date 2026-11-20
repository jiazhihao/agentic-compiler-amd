	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mla_decode
	.globl	mla_decode
	.p2align	8
	.type	mla_decode,@function
mla_decode:
	s_movk_i32 s5, 0x80
	v_cmp_gt_u32_e64 s[8:9], s5, v0
	v_lshlrev_b32_e32 v58, 4, v0
	s_and_saveexec_b64 s[6:7], s[8:9]
	s_cbranch_execz .LBB0_2
.Lft0:
	s_mov_b32 s12, 0
	s_mov_b32 s13, s12
	s_mov_b32 s14, s12
	s_mov_b32 s15, s12
	v_mov_b64_e32 v[2:3], s[12:13]
	v_mov_b64_e32 v[4:5], s[14:15]
	ds_write_b128 v58, v[2:5] offset:24576
	ds_write_b128 v58, v[2:5] offset:26624
.LBB0_2:
	s_or_b64 exec, exec, s[6:7]
	s_load_dwordx4 s[20:23], s[0:1], 0x20
	s_load_dwordx8 s[12:19], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 2, v0
	s_lshl_b32 s24, s2, 1
	v_and_b32_e32 v2, 0x1fc, v1
	s_lshl_b32 s2, s4, 9
	s_or_b32 s5, s24, 1
	v_or_b32_e32 v46, s2, v2
	s_waitcnt lgkmcnt(0)
	s_mul_hi_i32 s27, s20, s3
	s_mul_i32 s26, s20, s3
	s_cmp_lt_i32 s21, 1
	v_ashrrev_i32_e32 v47, 31, v46
	v_cmp_gt_u32_e64 s[10:11], 2, v0
	s_cbranch_scc1 .LBB0_34
.Lft1:
	s_ashr_i32 s0, s21, 31
	s_mul_hi_i32 s1, s3, 0x900
	s_mulk_i32 s3, 0x900
	s_mul_i32 s0, s3, s0
	s_mul_i32 s1, s1, s21
	s_mul_hi_u32 s6, s3, s21
	s_add_i32 s28, s0, s1
	s_add_i32 s0, s28, s6
	s_add_i32 s6, s20, -1
	s_min_i32 s7, s24, s6
	s_ashr_i32 s23, s7, 31
	s_add_u32 s7, s26, s7
	s_addc_u32 s23, s27, s23
	s_mulk_i32 s23, 0x900
	s_mul_hi_u32 s29, s7, 0x900
	s_add_i32 s29, s29, s23
	s_mulk_i32 s7, 0x900
	s_add_u32 s33, s12, s7
	s_addc_u32 s36, s13, s29
	s_min_i32 s6, s5, s6
	s_ashr_i32 s7, s6, 31
	s_add_u32 s6, s26, s6
	s_addc_u32 s7, s27, s7
	s_mulk_i32 s7, 0x900
	s_mul_hi_u32 s23, s6, 0x900
	s_add_i32 s23, s23, s7
	s_mulk_i32 s6, 0x900
	s_add_u32 s37, s12, s6
	s_mul_i32 s1, s3, s21
	s_addc_u32 s38, s13, s23
	v_lshlrev_b32_e32 v3, 8, v0
	s_add_u32 s6, s14, s1
	v_and_b32_e32 v6, 0x1f00, v3
	v_lshrrev_b32_e32 v3, 3, v0
	s_addc_u32 s7, s15, s0
	v_and_b32_e32 v3, 0x7c, v3
	s_movk_i32 s25, 0x900
	v_lshrrev_b32_e32 v59, 7, v0
	v_or_b32_e32 v7, 0x4000, v3
	v_mov_b32_e32 v3, 0x7000
	v_mov_b64_e32 v[4:5], s[6:7]
	v_lshl_add_u32 v63, v0, 7, v3
	v_lshl_add_u64 v[48:49], v[46:47], 2, s[6:7]
	v_mad_u64_u32 v[50:51], s[6:7], v0, s25, v[4:5]
	v_mul_hi_u32_u24_e32 v5, 0x900, v59
	v_mul_u32_u24_e32 v4, 0x900, v59
	v_mov_b32_e32 v3, s21
	v_mad_u64_u32 v[4:5], s[6:7], s3, v3, v[4:5]
	v_add_u32_e32 v2, s2, v2
	v_add_u32_e32 v5, s28, v5
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[2:3], v[2:3], 2, v[4:5]
	v_lshl_add_u64 v[2:3], s[14:15], 0, v[2:3]
	s_mov_b64 s[2:3], 0x1f80c
	v_lshlrev_b32_e32 v60, 3, v0
	v_cmp_gt_u32_e64 s[0:1], 64, v0
	v_or_b32_e32 v61, v7, v6
	v_or_b32_e32 v62, 0x7000, v1
	v_add_u32_e32 v64, 0x7108, v1
	v_add_u32_e32 v65, 0x7110, v1
	v_add_u32_e32 v66, 0x7100, v1
	v_or_b32_e32 v67, 56, v59
	s_mov_b32 s23, s22
	v_lshlrev_b32_e32 v68, 3, v59
	v_lshl_add_u64 v[52:53], v[2:3], 0, s[2:3]
	s_mov_b32 s39, 0
	v_mov_b32_e32 v54, 0
	v_mov_b32_e32 v69, 0xff800000
	v_mov_b32_e32 v70, 0
	v_add_u32_e32 v71, v7, v6
	s_mov_b32 s40, 0x3fb8aa3b
	s_mov_b32 s41, 0xc2ce8ed0
	s_mov_b32 s42, 0x42b17218
	s_mov_b32 s43, 0xfffe1000
	s_mov_b32 s44, 0xfffe5000
	s_mov_b32 s45, 0xfffea000
	s_mov_b32 s46, 0xfffee000
	s_mov_b32 s47, 0xffff3000
	s_mov_b32 s48, 0xffff7000
	s_movk_i32 s49, 0xc000
	s_mov_b64 s[12:13], 0x24000
	s_mov_b64 s[14:15], 0x47f4
	s_mov_b64 s[28:29], 0x4800
	s_mov_b64 s[30:31], 0x240000
	v_mov_b32_e32 v72, 0x7f800000
	s_branch .LBB0_5
.LBB0_4:
	s_or_b64 exec, exec, s[2:3]
	s_addk_i32 s39, 0x400
	v_lshl_add_u64 v[50:51], v[50:51], 0, s[30:31]
	s_cmp_ge_i32 s39, s21
	v_lshl_add_u64 v[52:53], v[52:53], 0, s[30:31]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc1 .LBB0_33
.LBB0_5:
	v_or_b32_e32 v2, s39, v0
	v_cmp_le_i32_e32 vcc, s21, v2
	v_cmp_gt_i32_e64 s[2:3], s21, v2
	v_mov_b32_e32 v3, 0xff800000
	v_mov_b32_e32 v2, 0xff800000
	s_and_saveexec_b64 s[6:7], s[2:3]
	s_cbranch_execz .LBB0_9
.Lft2:
	v_mov_b32_e32 v56, 0
	s_mov_b32 s34, -4
	s_mov_b64 s[2:3], 0
	v_mov_b32_e32 v57, v56
	.p2align	5, , 4
.LBB0_7:
	v_lshl_add_u64 v[94:95], v[50:51], 0, s[2:3]
	s_add_u32 s50, s33, s2
	s_addc_u32 s51, s36, s3
	s_add_u32 s34, s37, s2
	s_addc_u32 s35, s38, s3
	global_load_dwordx4 v[2:5], v[94:95], off
	global_load_dwordx4 v[6:9], v[94:95], off offset:16
	global_load_dwordx4 v[10:13], v[94:95], off offset:32
	global_load_dwordx4 v[14:17], v[94:95], off offset:48
	global_load_dwordx4 v[18:21], v[94:95], off offset:64
	global_load_dwordx4 v[22:25], v[94:95], off offset:80
	global_load_dwordx4 v[26:29], v[94:95], off offset:96
	global_load_dwordx4 v[30:33], v[94:95], off offset:112
	global_load_dwordx4 v[34:37], v[94:95], off offset:128
	global_load_dwordx4 v[38:41], v[94:95], off offset:144
	global_load_dwordx4 v[42:45], v[94:95], off offset:160
	global_load_dwordx4 v[74:77], v[94:95], off offset:176
	global_load_dwordx4 v[78:81], v[94:95], off offset:192
	global_load_dwordx4 v[82:85], v[94:95], off offset:208
	global_load_dwordx4 v[86:89], v[94:95], off offset:224
	global_load_dwordx4 v[90:93], v[94:95], off offset:240
	s_load_dwordx16 s[52:67], s[50:51], 0x0
	s_load_dwordx16 s[68:83], s[34:35], 0x0
	s_load_dwordx16 s[84:99], s[50:51], 0x40
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(15)
	v_fmac_f32_e64 v56, s52, v2
	v_fmac_f32_e64 v56, s53, v3
	v_fmac_f32_e64 v56, s54, v4
	v_fmac_f32_e64 v56, s55, v5
	s_waitcnt vmcnt(14)
	v_fmac_f32_e64 v56, s56, v6
	v_fmac_f32_e64 v56, s57, v7
	v_fmac_f32_e64 v56, s58, v8
	v_fmac_f32_e64 v56, s59, v9
	s_waitcnt vmcnt(13)
	v_fmac_f32_e64 v56, s60, v10
	v_fmac_f32_e64 v56, s61, v11
	v_fmac_f32_e64 v56, s62, v12
	v_fmac_f32_e64 v56, s63, v13
	s_waitcnt vmcnt(12)
	v_fmac_f32_e64 v56, s64, v14
	v_fmac_f32_e64 v56, s65, v15
	v_fmac_f32_e64 v56, s66, v16
	v_fmac_f32_e64 v56, s67, v17
	s_load_dwordx16 s[52:67], s[34:35], 0x40
	v_fmac_f32_e64 v57, s68, v2
	v_fmac_f32_e64 v57, s69, v3
	v_fmac_f32_e64 v57, s70, v4
	v_fmac_f32_e64 v57, s71, v5
	v_fmac_f32_e64 v57, s72, v6
	v_fmac_f32_e64 v57, s73, v7
	v_fmac_f32_e64 v57, s74, v8
	v_fmac_f32_e64 v57, s75, v9
	v_fmac_f32_e64 v57, s76, v10
	v_fmac_f32_e64 v57, s77, v11
	v_fmac_f32_e64 v57, s78, v12
	v_fmac_f32_e64 v57, s79, v13
	v_fmac_f32_e64 v57, s80, v14
	v_fmac_f32_e64 v57, s81, v15
	v_fmac_f32_e64 v57, s82, v16
	v_fmac_f32_e64 v57, s83, v17
	s_load_dwordx16 s[68:83], s[50:51], 0x80
	s_waitcnt vmcnt(11)
	v_fmac_f32_e64 v56, s84, v18
	v_fmac_f32_e64 v56, s85, v19
	v_fmac_f32_e64 v56, s86, v20
	v_fmac_f32_e64 v56, s87, v21
	s_waitcnt vmcnt(10)
	v_fmac_f32_e64 v56, s88, v22
	v_fmac_f32_e64 v56, s89, v23
	v_fmac_f32_e64 v56, s90, v24
	v_fmac_f32_e64 v56, s91, v25
	s_waitcnt vmcnt(9)
	v_fmac_f32_e64 v56, s92, v26
	v_fmac_f32_e64 v56, s93, v27
	v_fmac_f32_e64 v56, s94, v28
	v_fmac_f32_e64 v56, s95, v29
	s_waitcnt vmcnt(8)
	v_fmac_f32_e64 v56, s96, v30
	v_fmac_f32_e64 v56, s97, v31
	v_fmac_f32_e64 v56, s98, v32
	v_fmac_f32_e64 v56, s99, v33
	s_load_dwordx16 s[84:99], s[34:35], 0x80
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e64 v57, s52, v18
	v_fmac_f32_e64 v57, s53, v19
	v_fmac_f32_e64 v57, s54, v20
	v_fmac_f32_e64 v57, s55, v21
	v_fmac_f32_e64 v57, s56, v22
	v_fmac_f32_e64 v57, s57, v23
	v_fmac_f32_e64 v57, s58, v24
	v_fmac_f32_e64 v57, s59, v25
	v_fmac_f32_e64 v57, s60, v26
	v_fmac_f32_e64 v57, s61, v27
	v_fmac_f32_e64 v57, s62, v28
	v_fmac_f32_e64 v57, s63, v29
	v_fmac_f32_e64 v57, s64, v30
	v_fmac_f32_e64 v57, s65, v31
	v_fmac_f32_e64 v57, s66, v32
	v_fmac_f32_e64 v57, s67, v33
	s_load_dwordx16 s[52:67], s[50:51], 0xc0
	s_waitcnt vmcnt(7)
	v_fmac_f32_e64 v56, s68, v34
	v_fmac_f32_e64 v56, s69, v35
	v_fmac_f32_e64 v56, s70, v36
	v_fmac_f32_e64 v56, s71, v37
	s_waitcnt vmcnt(6)
	v_fmac_f32_e64 v56, s72, v38
	v_fmac_f32_e64 v56, s73, v39
	v_fmac_f32_e64 v56, s74, v40
	v_fmac_f32_e64 v56, s75, v41
	s_waitcnt vmcnt(5)
	v_fmac_f32_e64 v56, s76, v42
	v_fmac_f32_e64 v56, s77, v43
	v_fmac_f32_e64 v56, s78, v44
	v_fmac_f32_e64 v56, s79, v45
	s_waitcnt vmcnt(4)
	v_fmac_f32_e64 v56, s80, v74
	v_fmac_f32_e64 v56, s81, v75
	v_fmac_f32_e64 v56, s82, v76
	v_fmac_f32_e64 v56, s83, v77
	s_load_dwordx16 s[68:83], s[34:35], 0xc0
	v_fmac_f32_e64 v57, s84, v34
	v_fmac_f32_e64 v57, s85, v35
	v_fmac_f32_e64 v57, s86, v36
	v_fmac_f32_e64 v57, s87, v37
	v_fmac_f32_e64 v57, s88, v38
	v_fmac_f32_e64 v57, s89, v39
	v_fmac_f32_e64 v57, s90, v40
	v_fmac_f32_e64 v57, s91, v41
	v_fmac_f32_e64 v57, s92, v42
	v_fmac_f32_e64 v57, s93, v43
	v_fmac_f32_e64 v57, s94, v44
	v_fmac_f32_e64 v57, s95, v45
	v_fmac_f32_e64 v57, s96, v74
	v_fmac_f32_e64 v57, s97, v75
	v_fmac_f32_e64 v57, s98, v76
	v_fmac_f32_e64 v57, s99, v77
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(3)
	v_fmac_f32_e64 v56, s52, v78
	v_fmac_f32_e64 v56, s53, v79
	v_fmac_f32_e64 v56, s54, v80
	v_fmac_f32_e64 v56, s55, v81
	s_waitcnt vmcnt(2)
	v_fmac_f32_e64 v56, s56, v82
	v_fmac_f32_e64 v56, s57, v83
	v_fmac_f32_e64 v56, s58, v84
	v_fmac_f32_e64 v56, s59, v85
	s_waitcnt vmcnt(1)
	v_fmac_f32_e64 v56, s60, v86
	v_fmac_f32_e64 v56, s61, v87
	v_fmac_f32_e64 v56, s62, v88
	v_fmac_f32_e64 v56, s63, v89
	s_waitcnt vmcnt(0)
	v_fmac_f32_e64 v56, s64, v90
	v_fmac_f32_e64 v56, s65, v91
	v_fmac_f32_e64 v56, s66, v92
	v_fmac_f32_e64 v56, s67, v93
	v_fmac_f32_e64 v57, s68, v78
	v_fmac_f32_e64 v57, s69, v79
	v_fmac_f32_e64 v57, s70, v80
	v_fmac_f32_e64 v57, s71, v81
	v_fmac_f32_e64 v57, s72, v82
	v_fmac_f32_e64 v57, s73, v83
	v_fmac_f32_e64 v57, s74, v84
	v_fmac_f32_e64 v57, s75, v85
	v_fmac_f32_e64 v57, s76, v86
	v_fmac_f32_e64 v57, s77, v87
	v_fmac_f32_e64 v57, s78, v88
	v_fmac_f32_e64 v57, s79, v89
	v_fmac_f32_e64 v57, s80, v90
	v_fmac_f32_e64 v57, s81, v91
	v_fmac_f32_e64 v57, s82, v92
	v_fmac_f32_e64 v57, s83, v93
	s_add_u32 s2, s2, 0x100
	s_addc_u32 s3, s3, 0
	s_cmpk_lt_u32 s2, 0x900
	s_cbranch_scc1 .LBB0_7
.Lft3:
	v_pk_mul_f32 v[2:3], s[22:23], v[56:57]
.LBB0_9:
	s_or_b64 exec, exec, s[6:7]
	ds_write_b64 v60, v[2:3] offset:16384
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_11
.Lft4:
	ds_read2_b32 v[4:5], v71 offset0:2 offset1:4
	ds_read_b32 v12, v61
	ds_read2_b32 v[6:7], v71 offset0:6 offset1:8
	ds_read2_b32 v[8:9], v71 offset0:10 offset1:12
	ds_read2_b32 v[10:11], v71 offset0:14 offset1:16
	s_waitcnt lgkmcnt(4)
	v_max_f32_e32 v4, v4, v4
	s_waitcnt lgkmcnt(3)
	v_max_f32_e32 v14, v12, v12
	ds_read2_b32 v[12:13], v71 offset0:18 offset1:20
	v_max_f32_e32 v4, v14, v4
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v4, v7, v8
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v12, v4, v11, v12
	ds_read2_b32 v[4:5], v71 offset0:22 offset1:24
	ds_read2_b32 v[6:7], v71 offset0:26 offset1:28
	ds_read2_b32 v[8:9], v71 offset0:30 offset1:32
	ds_read2_b32 v[10:11], v71 offset0:34 offset1:36
	ds_read2_b32 v[14:15], v71 offset0:38 offset1:40
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v4, v12, v13, v4
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v4, v7, v8
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v14, v4, v11, v14
	ds_read2_b32 v[4:5], v71 offset0:42 offset1:44
	ds_read2_b32 v[6:7], v71 offset0:46 offset1:48
	ds_read2_b32 v[8:9], v71 offset0:50 offset1:52
	ds_read2_b32 v[10:11], v71 offset0:54 offset1:56
	ds_read2_b32 v[12:13], v71 offset0:58 offset1:60
	ds_read_b32 v16, v71 offset:248
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v4, v14, v15, v4
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v4, v4, v7, v8
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v4, v4, v11, v12
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v4, v4, v13, v16
	ds_write_b32 v62, v4
.LBB0_11:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[10:11]
	s_cbranch_execz .LBB0_13
.Lft5:
	ds_read_b128 v[4:7], v63 offset:112
	ds_read_b128 v[8:11], v63 offset:96
	ds_read_b128 v[12:15], v63
	ds_read_b128 v[16:19], v63 offset:16
	ds_read_b128 v[20:23], v63 offset:80
	ds_read_b128 v[24:27], v63 offset:64
	ds_read_b128 v[28:31], v63 offset:32
	ds_read_b128 v[32:35], v63 offset:48
	s_waitcnt lgkmcnt(5)
	v_max3_f32 v12, v12, v13, v14
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v12, v12, v15, v16
	v_max3_f32 v12, v12, v17, v18
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v12, v12, v19, v28
	v_max3_f32 v12, v12, v29, v30
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v12, v12, v31, v32
	v_max3_f32 v12, v12, v33, v34
	v_max3_f32 v12, v12, v35, v24
	v_max3_f32 v12, v12, v25, v26
	v_max3_f32 v12, v12, v27, v20
	v_max3_f32 v12, v12, v21, v22
	v_max3_f32 v8, v12, v23, v8
	v_max3_f32 v8, v8, v9, v10
	v_max3_f32 v4, v8, v11, v4
	v_max3_f32 v4, v4, v5, v6
	v_max3_f32 v4, v69, v4, v7
	v_sub_f32_e32 v5, v69, v4
	v_mul_f32_e32 v6, 0x3fb8aa3b, v5
	v_fma_f32 v7, v5, s40, -v6
	v_rndne_f32_e32 v8, v6
	v_fmac_f32_e32 v7, 0x32a5705f, v5
	v_sub_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v6, v7
	v_exp_f32_e32 v6, v6
	v_cvt_i32_f32_e32 v7, v8
	v_cmp_ngt_f32_e64 s[2:3], s41, v5
	v_mov_b32_e32 v69, v4
	ds_write_b32 v64, v4
	v_ldexp_f32 v6, v6, v7
	v_cndmask_b32_e64 v6, 0, v6, s[2:3]
	v_cmp_nlt_f32_e64 s[2:3], s42, v5
	s_nop 1
	v_cndmask_b32_e64 v5, v72, v6, s[2:3]
	ds_write_b32 v65, v5
.LBB0_13:
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], vcc
	s_xor_b64 s[2:3], exec, s[2:3]
	ds_write_b32 v60, v54 offset:16384
	s_or_saveexec_b64 s[2:3], s[2:3]
	v_mov_b32_e32 v4, 0
	s_xor_b64 exec, exec, s[2:3]
	s_cbranch_execz .LBB0_17
.Lft6:
	ds_read_b64 v[4:5], v54 offset:28936
	s_waitcnt lgkmcnt(0)
	v_sub_f32_e32 v2, v2, v4
	v_mul_f32_e32 v4, 0x3fb8aa3b, v2
	v_fma_f32 v6, v2, s40, -v4
	v_rndne_f32_e32 v7, v4
	v_fmac_f32_e32 v6, 0x32a5705f, v2
	v_sub_f32_e32 v4, v4, v7
	v_add_f32_e32 v4, v4, v6
	v_cvt_i32_f32_e32 v7, v7
	v_exp_f32_e32 v4, v4
	v_sub_f32_e32 v3, v3, v5
	v_mul_f32_e32 v5, 0x3fb8aa3b, v3
	v_fma_f32 v6, v3, s40, -v5
	v_ldexp_f32 v4, v4, v7
	v_rndne_f32_e32 v7, v5
	v_fmac_f32_e32 v6, 0x32a5705f, v3
	v_sub_f32_e32 v5, v5, v7
	v_add_f32_e32 v5, v5, v6
	v_exp_f32_e32 v5, v5
	v_cvt_i32_f32_e32 v6, v7
	v_cmp_ngt_f32_e32 vcc, s41, v2
	s_nop 1
	v_cndmask_b32_e32 v4, 0, v4, vcc
	v_cmp_nlt_f32_e32 vcc, s42, v2
	s_nop 1
	v_cndmask_b32_e32 v2, v72, v4, vcc
	ds_write_b32 v60, v2 offset:16384
	v_ldexp_f32 v2, v5, v6
	v_cmp_ngt_f32_e32 vcc, s41, v3
	s_nop 1
	v_cndmask_b32_e32 v2, 0, v2, vcc
	v_cmp_nlt_f32_e32 vcc, s42, v3
	s_nop 1
	v_cndmask_b32_e32 v4, v72, v2, vcc
.LBB0_17:
	s_or_b64 exec, exec, s[2:3]
	ds_write_b32 v60, v4 offset:16388
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_19
.Lft7:
	ds_read_b32 v10, v61
	ds_read2_b32 v[2:3], v71 offset0:2 offset1:4
	ds_read2_b32 v[4:5], v71 offset0:6 offset1:8
	ds_read2_b32 v[6:7], v71 offset0:10 offset1:12
	ds_read2_b32 v[8:9], v71 offset0:14 offset1:16
	ds_read_b32 v11, v71 offset:248
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v2, v10, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, v2, v6
	ds_read2_b32 v[2:3], v71 offset0:18 offset1:20
	v_add_f32_e32 v4, v4, v7
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v6, v4, v8
	ds_read2_b32 v[4:5], v71 offset0:22 offset1:24
	v_add_f32_e32 v6, v6, v9
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	ds_read2_b32 v[6:7], v71 offset0:26 offset1:28
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v71 offset0:30 offset1:32
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v71 offset0:34 offset1:36
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	ds_read2_b32 v[6:7], v71 offset0:38 offset1:40
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v71 offset0:42 offset1:44
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v71 offset0:46 offset1:48
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v6, v2, v3
	ds_read2_b32 v[2:3], v71 offset0:50 offset1:52
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v71 offset0:54 offset1:56
	v_add_f32_e32 v8, v4, v5
	ds_read2_b32 v[4:5], v71 offset0:58 offset1:60
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v8, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	v_add_f32_e32 v2, v2, v11
	ds_write_b32 v62, v2
.LBB0_19:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[10:11]
	s_cbranch_execz .LBB0_21
.Lft8:
	ds_read_b128 v[2:5], v63 offset:112
	ds_read_b128 v[6:9], v63 offset:96
	ds_read_b128 v[10:13], v63
	ds_read_b128 v[14:17], v63 offset:80
	ds_read_b128 v[18:21], v63 offset:64
	ds_read_b128 v[22:25], v63 offset:16
	ds_read_b128 v[26:29], v63 offset:32
	ds_read_b128 v[30:33], v63 offset:48
	s_waitcnt lgkmcnt(5)
	v_add_f32_e32 v10, v10, v11
	v_add_f32_e32 v10, v10, v12
	v_add_f32_e32 v10, v10, v13
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v10, v10, v22
	v_add_f32_e32 v10, v10, v23
	v_add_f32_e32 v10, v10, v24
	v_add_f32_e32 v10, v10, v25
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v10, v10, v26
	v_add_f32_e32 v10, v10, v27
	v_add_f32_e32 v10, v10, v28
	v_add_f32_e32 v10, v10, v29
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v10, v10, v30
	v_add_f32_e32 v10, v10, v31
	v_add_f32_e32 v10, v10, v32
	v_add_f32_e32 v10, v10, v33
	v_add_f32_e32 v10, v10, v18
	v_add_f32_e32 v10, v10, v19
	v_add_f32_e32 v10, v10, v20
	v_add_f32_e32 v10, v10, v21
	v_add_f32_e32 v10, v10, v14
	v_add_f32_e32 v10, v10, v15
	v_add_f32_e32 v10, v10, v16
	v_add_f32_e32 v10, v10, v17
	v_add_f32_e32 v6, v10, v6
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v6, v9
	ds_read_b32 v7, v65
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v2, v2, v3
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e32 v2, v70, v7
	v_mov_b32_e32 v70, v2
	ds_write_b32 v66, v2
.LBB0_21:
	s_or_b64 exec, exec, s[2:3]
	s_sub_i32 s2, s21, s39
	s_min_i32 s50, s2, 0x400
	v_or_b32_e32 v2, s39, v59
	v_mov_b32_e32 v55, v54
	v_mad_u64_u32 v[10:11], s[2:3], v2, s25, v[48:49]
	v_cmp_gt_i32_e32 vcc, s50, v67
	v_mov_b64_e32 v[8:9], v[54:55]
	v_mov_b64_e32 v[6:7], v[54:55]
	v_mov_b64_e32 v[4:5], v[54:55]
	v_mov_b64_e32 v[2:3], v[54:55]
	v_mov_b32_e32 v36, v59
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_25
.Lft9:
	v_mov_b32_e32 v4, 0
	s_mov_b64 s[34:35], 0
	v_mov_b64_e32 v[20:21], v[52:53]
	v_mov_b32_e32 v34, v68
	v_mov_b32_e32 v35, v59
	v_mov_b32_e32 v5, v4
	v_mov_b32_e32 v2, v4
	v_mov_b32_e32 v3, v4
	v_mov_b32_e32 v8, v4
	v_mov_b32_e32 v9, v4
	v_mov_b32_e32 v6, v4
	v_mov_b32_e32 v7, v4
.LBB0_23:
	v_mov_b64_e32 v[18:19], v[20:21]
	v_add_u32_e32 v14, 0x4000, v34
	v_add_co_u32_e32 v10, vcc, s43, v18
	s_nop 1
	v_addc_co_u32_e32 v11, vcc, -1, v19, vcc
	global_load_dwordx4 v[22:25], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[26:29], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[30:33], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[38:41], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[42:45], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[74:77], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[78:81], v[10:11], off offset:-2060
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	global_load_dwordx4 v[82:85], v[10:11], off offset:-2060
	ds_read_b64 v[12:13], v14
	ds_read_b64 v[16:17], v14 offset:64
	ds_read_b64 v[86:87], v14 offset:128
	ds_read_b64 v[88:89], v14 offset:192
	ds_read_b64 v[90:91], v14 offset:256
	ds_read_b64 v[92:93], v14 offset:320
	ds_read_b64 v[94:95], v14 offset:384
	ds_read_b64 v[96:97], v14 offset:448
	v_add_u32_e32 v20, 0x78, v35
	v_add_u32_e32 v36, 64, v35
	v_cmp_le_i32_e64 s[6:7], s50, v20
	v_add_u32_e32 v34, 0x200, v34
	v_lshl_add_u64 v[20:21], v[18:19], 0, s[12:13]
	v_mov_b32_e32 v35, v36
	s_or_b64 s[34:35], s[6:7], s[34:35]
	s_waitcnt vmcnt(7) lgkmcnt(0)
	v_pk_fma_f32 v[6:7], v[22:23], v[12:13], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[22:23], v[12:13], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[24:25], v[12:13], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[24:25], v[12:13], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(6)
	v_pk_fma_f32 v[6:7], v[26:27], v[16:17], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[26:27], v[16:17], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[28:29], v[16:17], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[28:29], v[16:17], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(5)
	v_pk_fma_f32 v[6:7], v[30:31], v[86:87], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[30:31], v[86:87], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[32:33], v[86:87], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[32:33], v[86:87], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(4)
	v_pk_fma_f32 v[6:7], v[38:39], v[88:89], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[38:39], v[88:89], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[40:41], v[88:89], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[40:41], v[88:89], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[6:7], v[42:43], v[90:91], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[42:43], v[90:91], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[44:45], v[90:91], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[44:45], v[90:91], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[6:7], v[74:75], v[92:93], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[74:75], v[92:93], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[76:77], v[92:93], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[76:77], v[92:93], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(1)
	v_pk_fma_f32 v[6:7], v[78:79], v[94:95], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[78:79], v[94:95], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[80:81], v[94:95], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[80:81], v[94:95], v[4:5] op_sel:[0,1,0]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[6:7], v[82:83], v[96:97], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[82:83], v[96:97], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[84:85], v[96:97], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[84:85], v[96:97], v[4:5] op_sel:[0,1,0]
	s_andn2_b64 exec, exec, s[34:35]
	s_cbranch_execnz .LBB0_23
.Lft10:
	s_or_b64 exec, exec, s[34:35]
	v_lshl_add_u64 v[10:11], v[18:19], 0, s[14:15]
.LBB0_25:
	s_or_b64 exec, exec, s[2:3]
	v_cmp_gt_i32_e32 vcc, s50, v36
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_29
.Lft11:
	v_lshlrev_b32_e32 v12, 3, v36
	v_lshl_add_u64 v[10:11], v[10:11], 0, 8
	s_mov_b64 s[6:7], 0
	.p2align	5, , 4
.LBB0_27:
	global_load_dwordx4 v[14:17], v[10:11], off offset:-8
	ds_read_b64 v[18:19], v12 offset:16384
	v_add_u32_e32 v36, 8, v36
	v_cmp_le_i32_e32 vcc, s50, v36
	v_add_u32_e32 v12, 64, v12
	v_lshl_add_u64 v[10:11], v[10:11], 0, s[28:29]
	s_or_b64 s[6:7], vcc, s[6:7]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_pk_fma_f32 v[6:7], v[14:15], v[18:19], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[14:15], v[18:19], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[8:9], v[16:17], v[18:19], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[16:17], v[18:19], v[4:5] op_sel:[0,1,0]
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_27
.Lft12:
	s_or_b64 exec, exec, s[6:7]
.LBB0_29:
	s_or_b64 exec, exec, s[2:3]
	ds_write_b128 v58, v[6:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[8:9]
	s_cbranch_execz .LBB0_31
.Lft13:
	ds_read_b128 v[6:9], v58
	ds_read_b128 v[10:13], v58 offset:2048
	ds_read_b128 v[14:17], v58 offset:4096
	ds_read_b128 v[18:21], v58 offset:6144
	ds_read_b32 v42, v54 offset:28944
	ds_read_b128 v[22:25], v58 offset:8192
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[6:7], v[14:15]
	v_pk_add_f32 v[8:9], v[8:9], v[16:17]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[6:7], v[18:19]
	ds_read_b128 v[26:29], v58 offset:10240
	ds_read_b128 v[30:33], v58 offset:12288
	ds_read_b128 v[34:37], v58 offset:14336
	ds_read_b128 v[38:41], v58 offset:24576
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[6:7], v[22:23]
	v_pk_add_f32 v[8:9], v[8:9], v[24:25]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[6:7], v[26:27]
	v_pk_add_f32 v[8:9], v[8:9], v[28:29]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[6:7], v[30:31]
	v_pk_add_f32 v[8:9], v[8:9], v[32:33]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[6:7], v[6:7], v[34:35]
	v_pk_add_f32 v[8:9], v[8:9], v[36:37]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[6:7], v[42:43], v[38:39], v[6:7] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[8:9], v[42:43], v[40:41], v[8:9] op_sel_hi:[0,1,1]
	ds_write_b128 v58, v[6:9] offset:24576
.LBB0_31:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v58, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[8:9]
	s_cbranch_execz .LBB0_4
.Lft14:
	ds_read_b128 v[2:5], v58
	ds_read_b128 v[6:9], v58 offset:2048
	ds_read_b128 v[10:13], v58 offset:4096
	ds_read_b128 v[14:17], v58 offset:6144
	ds_read_b32 v38, v54 offset:28948
	ds_read_b128 v[18:21], v58 offset:8192
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[2:3], v[10:11]
	v_pk_add_f32 v[4:5], v[4:5], v[12:13]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[2:3], v[14:15]
	ds_read_b128 v[22:25], v58 offset:10240
	ds_read_b128 v[26:29], v58 offset:12288
	ds_read_b128 v[30:33], v58 offset:14336
	ds_read_b128 v[34:37], v58 offset:26624
	v_pk_add_f32 v[4:5], v[4:5], v[16:17]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[2:3], v[18:19]
	v_pk_add_f32 v[4:5], v[4:5], v[20:21]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[2:3], v[22:23]
	v_pk_add_f32 v[4:5], v[4:5], v[24:25]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[2:3], v[26:27]
	v_pk_add_f32 v[4:5], v[4:5], v[28:29]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[2:3], v[2:3], v[30:31]
	v_pk_add_f32 v[4:5], v[4:5], v[32:33]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[2:3], v[38:39], v[34:35], v[2:3] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[4:5], v[38:39], v[36:37], v[4:5] op_sel_hi:[0,1,1]
	ds_write_b128 v58, v[2:5] offset:26624
	s_branch .LBB0_4
.LBB0_33:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v70
	s_mov_b32 s0, 0x3f317217
	s_mov_b32 s1, 0x7f800000
	v_cndmask_b32_e64 v2, 0, 32, vcc
	v_ldexp_f32 v2, v70, v2
	v_log_f32_e32 v2, v2
	s_nop 0
	v_mul_f32_e32 v3, 0x3f317217, v2
	v_fma_f32 v4, v2, s0, -v3
	v_fmamk_f32 v4, v2, 0x3377d1cf, v4
	v_add_f32_e32 v3, v3, v4
	v_cmp_lt_f32_e64 s[0:1], |v2|, s1
	s_nop 1
	v_cndmask_b32_e64 v2, v2, v3, s[0:1]
	v_mov_b32_e32 v3, 0x41b17218
	v_cndmask_b32_e32 v3, 0, v3, vcc
	v_sub_f32_e32 v2, v2, v3
	v_add_f32_e32 v4, v69, v2
	s_and_saveexec_b64 s[0:1], s[8:9]
	s_cbranch_execnz .LBB0_35
.Lft15:
	s_branch .LBB0_39
.LBB0_34:
	v_mov_b32_e32 v4, 0xff800000
	s_and_saveexec_b64 s[0:1], s[8:9]
	s_cbranch_execz .LBB0_39
.LBB0_35:
	s_movk_i32 s2, 0x6000
	s_ashr_i32 s3, s24, 31
	v_lshl_add_u32 v5, v0, 4, s2
	s_add_u32 s2, s26, s24
	v_mov_b32_e32 v2, s16
	v_mov_b32_e32 v3, s17
	s_addc_u32 s3, s27, s3
	s_cmp_lt_i32 s24, s20
	v_lshl_add_u64 v[2:3], v[46:47], 2, v[2:3]
	s_cbranch_scc0 .LBB0_37
.Lft16:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v12, v6 offset:28928
	ds_read_b128 v[6:9], v5
	s_lshl_b64 s[6:7], s[2:3], 11
	v_lshl_add_u64 v[10:11], v[2:3], 0, s[6:7]
	s_waitcnt lgkmcnt(0)
	v_div_scale_f32 v13, s[6:7], v12, v12, v7
	v_rcp_f32_e32 v14, v13
	v_div_scale_f32 v15, vcc, v7, v12, v7
	v_div_scale_f32 v16, s[6:7], v12, v12, v6
	v_rcp_f32_e32 v17, v16
	v_fma_f32 v18, -v13, v14, 1.0
	v_fmac_f32_e32 v14, v18, v14
	v_mul_f32_e32 v18, v15, v14
	v_fma_f32 v19, -v13, v18, v15
	v_fmac_f32_e32 v18, v19, v14
	v_fma_f32 v13, -v13, v18, v15
	v_div_fmas_f32 v13, v13, v14, v18
	v_div_fixup_f32 v7, v13, v12, v7
	v_fma_f32 v13, -v16, v17, 1.0
	v_fmac_f32_e32 v17, v13, v17
	v_div_scale_f32 v13, vcc, v6, v12, v6
	v_mul_f32_e32 v14, v13, v17
	v_fma_f32 v15, -v16, v14, v13
	v_fmac_f32_e32 v14, v15, v17
	v_div_scale_f32 v15, s[6:7], v12, v12, v9
	v_fma_f32 v13, -v16, v14, v13
	v_rcp_f32_e32 v16, v15
	v_div_fmas_f32 v13, v13, v17, v14
	v_div_fixup_f32 v6, v13, v12, v6
	v_fma_f32 v13, -v15, v16, 1.0
	v_fmac_f32_e32 v16, v13, v16
	v_div_scale_f32 v13, vcc, v9, v12, v9
	v_mul_f32_e32 v14, v13, v16
	v_fma_f32 v17, -v15, v14, v13
	v_fmac_f32_e32 v14, v17, v16
	v_fma_f32 v13, -v15, v14, v13
	v_div_scale_f32 v15, s[6:7], v12, v12, v8
	v_rcp_f32_e32 v17, v15
	v_div_fmas_f32 v13, v13, v16, v14
	v_div_fixup_f32 v9, v13, v12, v9
	v_fma_f32 v13, -v15, v17, 1.0
	v_fmac_f32_e32 v17, v13, v17
	v_div_scale_f32 v13, vcc, v8, v12, v8
	v_mul_f32_e32 v14, v13, v17
	v_fma_f32 v16, -v15, v14, v13
	v_fmac_f32_e32 v14, v16, v17
	v_fma_f32 v13, -v15, v14, v13
	v_div_fmas_f32 v13, v13, v17, v14
	v_div_fixup_f32 v8, v13, v12, v8
	global_store_dwordx4 v[10:11], v[6:9], off
.LBB0_37:
	s_cmp_ge_i32 s5, s20
	s_cbranch_scc1 .LBB0_39
.Lft17:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v10, v6 offset:28932
	ds_read_b128 v[6:9], v5 offset:2048
	s_lshl_b64 s[2:3], s[2:3], 11
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	s_waitcnt lgkmcnt(0)
	v_div_scale_f32 v5, s[2:3], v10, v10, v7
	v_rcp_f32_e32 v11, v5
	v_div_scale_f32 v12, vcc, v7, v10, v7
	v_div_scale_f32 v13, s[2:3], v10, v10, v6
	v_rcp_f32_e32 v14, v13
	v_fma_f32 v15, -v5, v11, 1.0
	v_fmac_f32_e32 v11, v15, v11
	v_mul_f32_e32 v15, v12, v11
	v_fma_f32 v16, -v5, v15, v12
	v_fmac_f32_e32 v15, v16, v11
	v_fma_f32 v5, -v5, v15, v12
	v_div_fmas_f32 v5, v5, v11, v15
	v_div_fixup_f32 v7, v5, v10, v7
	v_fma_f32 v5, -v13, v14, 1.0
	v_fmac_f32_e32 v14, v5, v14
	v_div_scale_f32 v5, vcc, v6, v10, v6
	v_mul_f32_e32 v11, v5, v14
	v_fma_f32 v12, -v13, v11, v5
	v_fmac_f32_e32 v11, v12, v14
	v_div_scale_f32 v12, s[2:3], v10, v10, v9
	v_fma_f32 v5, -v13, v11, v5
	v_rcp_f32_e32 v13, v12
	v_div_fmas_f32 v5, v5, v14, v11
	v_div_fixup_f32 v6, v5, v10, v6
	v_fma_f32 v5, -v12, v13, 1.0
	v_fmac_f32_e32 v13, v5, v13
	v_div_scale_f32 v5, vcc, v9, v10, v9
	v_mul_f32_e32 v11, v5, v13
	v_fma_f32 v14, -v12, v11, v5
	v_fmac_f32_e32 v11, v14, v13
	v_fma_f32 v5, -v12, v11, v5
	v_div_scale_f32 v12, s[2:3], v10, v10, v8
	v_rcp_f32_e32 v14, v12
	v_div_fmas_f32 v5, v5, v13, v11
	v_div_fixup_f32 v9, v5, v10, v9
	v_fma_f32 v5, -v12, v14, 1.0
	v_fmac_f32_e32 v14, v5, v14
	v_div_scale_f32 v5, vcc, v8, v10, v8
	v_mul_f32_e32 v11, v5, v14
	v_fma_f32 v13, -v12, v11, v5
	v_fmac_f32_e32 v11, v13, v14
	v_fma_f32 v5, -v12, v11, v5
	v_div_fmas_f32 v5, v5, v14, v11
	v_div_fixup_f32 v8, v5, v10, v8
	global_store_dwordx4 v[2:3], v[6:9], off offset:2048
.LBB0_39:
	s_or_b64 exec, exec, s[0:1]
	s_cmp_eq_u32 s4, 0
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_cselect_b64 s[0:1], -1, 0
	v_or_b32_e32 v0, s24, v0
	s_and_b64 s[0:1], vcc, s[0:1]
	v_cmp_gt_i32_e32 vcc, s20, v0
	s_and_b64 s[0:1], s[0:1], vcc
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_41
.Lft18:
	s_ashr_i32 s25, s24, 31
	s_lshl_b64 s[0:1], s[26:27], 2
	s_add_u32 s2, s18, s0
	s_addc_u32 s3, s19, s1
	s_lshl_b64 s[0:1], s[24:25], 2
	s_add_u32 s0, s2, s0
	s_addc_u32 s1, s3, s1
	global_store_dword v1, v4, s[0:1]
.LBB0_41:
	s_endpgm
.Lfunc_end0:
	.size	mla_decode, .Lfunc_end0-mla_decode
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mla_decode
		.amdhsa_group_segment_fixed_size 28952
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 44
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 98
		.amdhsa_next_free_sgpr 100
		.amdhsa_accum_offset 100
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
  - .offset: 32
    .size: 4
    .value_kind: by_value
  - .offset: 36
    .size: 4
    .value_kind: by_value
  - .offset: 40
    .size: 4
    .value_kind: by_value
  .gfx1250_revision: B0
  .group_segment_fixed_size: 28952
  .kernarg_segment_align: 8
  .kernarg_segment_size: 44
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mla_decode
  .private_segment_fixed_size: 0
  .sgpr_count: 106
  .sgpr_spill_count: 0
  .symbol: mla_decode.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 98
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
