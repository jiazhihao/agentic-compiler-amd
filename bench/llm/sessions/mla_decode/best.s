	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mla_decode
	.globl	mla_decode
	.p2align	8
	.type	mla_decode,@function
mla_decode:
	s_movk_i32 s5, 0x80
	v_cmp_gt_u32_e64 s[6:7], s5, v0
	v_lshlrev_b32_e32 v102, 4, v0
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_cbranch_execz .LBB0_2
.Lft0:
	s_mov_b32 s12, 0
	s_mov_b32 s13, s12
	s_mov_b32 s14, s12
	s_mov_b32 s15, s12
	v_mov_b64_e32 v[2:3], s[12:13]
	v_mov_b64_e32 v[4:5], s[14:15]
	ds_write_b128 v102, v[2:5] offset:24576
	ds_write_b128 v102, v[2:5] offset:26624
.LBB0_2:
	s_or_b64 exec, exec, s[8:9]
	s_load_dwordx4 s[20:23], s[0:1], 0x20
	s_load_dwordx8 s[12:19], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 2, v0
	s_lshl_b32 s10, s2, 1
	v_and_b32_e32 v2, 0x1fc, v1
	s_lshl_b32 s2, s4, 9
	s_or_b32 s5, s10, 1
	v_or_b32_e32 v34, s2, v2
	s_waitcnt lgkmcnt(0)
	s_mul_hi_i32 s25, s20, s3
	s_mul_i32 s24, s20, s3
	s_cmp_lt_i32 s21, 1
	v_ashrrev_i32_e32 v35, 31, v34
	v_cmp_gt_u32_e64 s[8:9], 2, v0
	s_cbranch_scc1 .LBB0_46
.Lft1:
	s_ashr_i32 s0, s21, 31
	s_mul_hi_i32 s1, s3, 0x900
	s_mulk_i32 s3, 0x900
	s_mul_i32 s0, s3, s0
	s_mul_i32 s1, s1, s21
	s_mul_hi_u32 s23, s3, s21
	s_add_i32 s26, s0, s1
	s_add_i32 s0, s26, s23
	s_add_i32 s23, s20, -1
	s_min_i32 s27, s10, s23
	s_ashr_i32 s28, s27, 31
	s_add_u32 s27, s24, s27
	s_addc_u32 s28, s25, s28
	s_mulk_i32 s28, 0x900
	s_mul_hi_u32 s29, s27, 0x900
	s_add_i32 s29, s29, s28
	s_mulk_i32 s27, 0x900
	s_add_u32 s33, s12, s27
	s_addc_u32 s44, s13, s29
	s_min_i32 s23, s5, s23
	s_ashr_i32 s27, s23, 31
	s_add_u32 s23, s24, s23
	s_addc_u32 s27, s25, s27
	s_mulk_i32 s27, 0x900
	s_mul_hi_u32 s28, s23, 0x900
	s_add_i32 s28, s28, s27
	s_mulk_i32 s23, 0x900
	s_add_u32 s45, s12, s23
	s_mul_i32 s1, s3, s21
	s_addc_u32 s46, s13, s28
	v_lshlrev_b32_e32 v3, 8, v0
	s_add_u32 s12, s14, s1
	v_and_b32_e32 v6, 0x1f00, v3
	v_lshrrev_b32_e32 v3, 3, v0
	s_addc_u32 s13, s15, s0
	v_and_b32_e32 v3, 0x7c, v3
	s_movk_i32 s11, 0x900
	v_lshrrev_b32_e32 v36, 7, v0
	v_or_b32_e32 v7, 0x4000, v3
	v_mov_b32_e32 v3, 0x7000
	v_mov_b64_e32 v[4:5], s[12:13]
	v_lshl_add_u32 v106, v0, 7, v3
	v_lshl_add_u64 v[38:39], v[34:35], 2, s[12:13]
	v_mad_u64_u32 v[40:41], s[12:13], v0, s11, v[4:5]
	v_mul_hi_u32_u24_e32 v5, 0x900, v36
	v_mul_u32_u24_e32 v4, 0x900, v36
	v_mov_b32_e32 v3, s21
	v_mad_u64_u32 v[4:5], s[12:13], s3, v3, v[4:5]
	v_add_u32_e32 v2, s2, v2
	v_add_u32_e32 v5, s26, v5
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[2:3], v[2:3], 2, v[4:5]
	v_lshl_add_u64 v[2:3], s[14:15], 0, v[2:3]
	s_mov_b64 s[12:13], 0x24000
	v_lshlrev_b32_e32 v103, 3, v0
	v_cmp_gt_u32_e64 s[0:1], 64, v0
	s_movk_i32 s47, 0x4000
	v_or_b32_e32 v104, v7, v6
	v_or_b32_e32 v105, 0x7000, v1
	v_add_u32_e32 v107, 0x7110, v1
	v_or_b32_e32 v108, 56, v36
	s_mov_b32 s23, s22
	v_xor_b32_e32 v109, 0xffffffc7, v36
	s_mov_b32 s48, 0
	v_or_b32_e32 v37, 64, v36
	v_lshl_add_u64 v[42:43], v[2:3], 0, s[12:13]
	v_mov_b32_e32 v44, 0
	v_mov_b32_e32 v111, 0xff800000
	v_mov_b32_e32 v110, 0
	v_add_u32_e32 v112, v7, v6
	s_mov_b32 s49, 0xc2aeac50
	s_mov_b32 s50, 0xfffdc000
	s_mov_b32 s51, 0xfffe1000
	s_mov_b32 s52, 0xfffe5000
	s_mov_b32 s53, 0x9000
	s_mov_b32 s54, 0xfffea000
	s_mov_b32 s55, 0xd000
	s_mov_b32 s56, 0xfffee000
	s_mov_b32 s57, 0x12000
	s_mov_b32 s58, 0xffff3000
	s_mov_b32 s59, 0x16000
	s_mov_b32 s60, 0xffff7000
	s_mov_b32 s61, 0x1b000
	s_movk_i32 s62, 0xc000
	s_mov_b32 s63, 0x1f000
	s_mov_b64 s[14:15], 0x48000
	s_mov_b32 s64, 0x24000
	s_mov_b64 s[26:27], 0x1f80c
	s_mov_b32 s28, 0xfffe07f4
	s_mov_b32 s29, -1
	s_mov_b64 s[30:31], 0x4800
	s_mov_b64 s[34:35], 0x9000
	s_movk_i32 s65, 0x4800
	s_mov_b64 s[36:37], 0x240000
	s_mov_b32 s66, s21
	s_mov_b32 s67, 0
	s_branch .LBB0_5
.LBB0_4:
	s_or_b64 exec, exec, s[2:3]
	s_addk_i32 s67, 0x400
	s_add_i32 s48, s48, 1
	s_addk_i32 s66, 0xfc00
	v_lshl_add_u64 v[40:41], v[40:41], 0, s[36:37]
	s_cmp_ge_i32 s67, s21
	v_lshl_add_u64 v[42:43], v[42:43], 0, s[36:37]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc1 .LBB0_45
.LBB0_5:
	v_or_b32_e32 v2, s67, v0
	v_cmp_le_i32_e32 vcc, s21, v2
	v_cmp_gt_i32_e64 s[2:3], s21, v2
	v_mov_b32_e32 v3, 0xff800000
	v_mov_b32_e32 v2, 0xff800000
	s_and_saveexec_b64 s[38:39], s[2:3]
	s_cbranch_execz .LBB0_9
.Lft2:
	s_mov_b64 s[2:3], 0
	s_mov_b32 s40, -4
	v_mov_b32_e32 v22, 0
	v_mov_b32_e32 v23, 0
	.p2align	5, , 4
.LBB0_7:
	v_lshl_add_u64 v[32:33], v[40:41], 0, s[2:3]
	global_load_dwordx4 v[2:5], v[32:33], off
	global_load_dwordx4 v[6:9], v[32:33], off offset:16
	global_load_dwordx4 v[10:13], v[32:33], off offset:32
	global_load_dwordx4 v[14:17], v[32:33], off offset:48
	global_load_dwordx4 v[18:21], v[32:33], off offset:64
	global_load_dwordx4 v[24:27], v[32:33], off offset:80
	global_load_dwordx4 v[28:31], v[32:33], off offset:96
	global_load_dwordx4 v[46:49], v[32:33], off offset:112
	global_load_dwordx4 v[50:53], v[32:33], off offset:128
	global_load_dwordx4 v[54:57], v[32:33], off offset:144
	global_load_dwordx4 v[58:61], v[32:33], off offset:160
	global_load_dwordx4 v[62:65], v[32:33], off offset:176
	global_load_dwordx4 v[70:73], v[32:33], off offset:192
	global_load_dwordx4 v[74:77], v[32:33], off offset:208
	global_load_dwordx4 v[78:81], v[32:33], off offset:224
	global_load_dwordx4 v[82:85], v[32:33], off offset:240
	s_add_u32 s42, s33, s2
	s_addc_u32 s43, s44, s3
	s_add_u32 s100, s45, s2
	s_addc_u32 s101, s46, s3
	s_load_dwordx16 s[68:83], s[42:43], 0x0
	s_load_dwordx16 s[84:99], s[100:101], 0x0
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(12)
	v_fmac_f32_e64 v22, s68, v2
	v_fmac_f32_e64 v23, s84, v2
	v_fmac_f32_e64 v22, s69, v3
	v_fmac_f32_e64 v23, s85, v3
	v_fmac_f32_e64 v22, s70, v4
	v_fmac_f32_e64 v23, s86, v4
	v_fmac_f32_e64 v22, s71, v5
	v_fmac_f32_e64 v23, s87, v5
	v_fmac_f32_e64 v22, s72, v6
	v_fmac_f32_e64 v23, s88, v6
	v_fmac_f32_e64 v22, s73, v7
	v_fmac_f32_e64 v23, s89, v7
	v_fmac_f32_e64 v22, s74, v8
	v_fmac_f32_e64 v23, s90, v8
	v_fmac_f32_e64 v22, s75, v9
	v_fmac_f32_e64 v23, s91, v9
	v_fmac_f32_e64 v22, s76, v10
	v_fmac_f32_e64 v23, s92, v10
	v_fmac_f32_e64 v22, s77, v11
	v_fmac_f32_e64 v23, s93, v11
	v_fmac_f32_e64 v22, s78, v12
	v_fmac_f32_e64 v23, s94, v12
	v_fmac_f32_e64 v22, s79, v13
	v_fmac_f32_e64 v23, s95, v13
	v_fmac_f32_e64 v22, s80, v14
	v_fmac_f32_e64 v23, s96, v14
	v_fmac_f32_e64 v22, s81, v15
	v_fmac_f32_e64 v23, s97, v15
	v_fmac_f32_e64 v22, s82, v16
	v_fmac_f32_e64 v23, s98, v16
	v_fmac_f32_e64 v22, s83, v17
	v_fmac_f32_e64 v23, s99, v17
	s_load_dwordx16 s[68:83], s[42:43], 0x40
	s_load_dwordx16 s[84:99], s[100:101], 0x40
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(8)
	v_fmac_f32_e64 v22, s68, v18
	v_fmac_f32_e64 v23, s84, v18
	v_fmac_f32_e64 v22, s69, v19
	v_fmac_f32_e64 v23, s85, v19
	v_fmac_f32_e64 v22, s70, v20
	v_fmac_f32_e64 v23, s86, v20
	v_fmac_f32_e64 v22, s71, v21
	v_fmac_f32_e64 v23, s87, v21
	v_fmac_f32_e64 v22, s72, v24
	v_fmac_f32_e64 v23, s88, v24
	v_fmac_f32_e64 v22, s73, v25
	v_fmac_f32_e64 v23, s89, v25
	v_fmac_f32_e64 v22, s74, v26
	v_fmac_f32_e64 v23, s90, v26
	v_fmac_f32_e64 v22, s75, v27
	v_fmac_f32_e64 v23, s91, v27
	v_fmac_f32_e64 v22, s76, v28
	v_fmac_f32_e64 v23, s92, v28
	v_fmac_f32_e64 v22, s77, v29
	v_fmac_f32_e64 v23, s93, v29
	v_fmac_f32_e64 v22, s78, v30
	v_fmac_f32_e64 v23, s94, v30
	v_fmac_f32_e64 v22, s79, v31
	v_fmac_f32_e64 v23, s95, v31
	v_fmac_f32_e64 v22, s80, v46
	v_fmac_f32_e64 v23, s96, v46
	v_fmac_f32_e64 v22, s81, v47
	v_fmac_f32_e64 v23, s97, v47
	v_fmac_f32_e64 v22, s82, v48
	v_fmac_f32_e64 v23, s98, v48
	v_fmac_f32_e64 v22, s83, v49
	v_fmac_f32_e64 v23, s99, v49
	s_load_dwordx16 s[68:83], s[42:43], 0x80
	s_load_dwordx16 s[84:99], s[100:101], 0x80
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(4)
	v_fmac_f32_e64 v22, s68, v50
	v_fmac_f32_e64 v23, s84, v50
	v_fmac_f32_e64 v22, s69, v51
	v_fmac_f32_e64 v23, s85, v51
	v_fmac_f32_e64 v22, s70, v52
	v_fmac_f32_e64 v23, s86, v52
	v_fmac_f32_e64 v22, s71, v53
	v_fmac_f32_e64 v23, s87, v53
	v_fmac_f32_e64 v22, s72, v54
	v_fmac_f32_e64 v23, s88, v54
	v_fmac_f32_e64 v22, s73, v55
	v_fmac_f32_e64 v23, s89, v55
	v_fmac_f32_e64 v22, s74, v56
	v_fmac_f32_e64 v23, s90, v56
	v_fmac_f32_e64 v22, s75, v57
	v_fmac_f32_e64 v23, s91, v57
	v_fmac_f32_e64 v22, s76, v58
	v_fmac_f32_e64 v23, s92, v58
	v_fmac_f32_e64 v22, s77, v59
	v_fmac_f32_e64 v23, s93, v59
	v_fmac_f32_e64 v22, s78, v60
	v_fmac_f32_e64 v23, s94, v60
	v_fmac_f32_e64 v22, s79, v61
	v_fmac_f32_e64 v23, s95, v61
	v_fmac_f32_e64 v22, s80, v62
	v_fmac_f32_e64 v23, s96, v62
	v_fmac_f32_e64 v22, s81, v63
	v_fmac_f32_e64 v23, s97, v63
	v_fmac_f32_e64 v22, s82, v64
	v_fmac_f32_e64 v23, s98, v64
	v_fmac_f32_e64 v22, s83, v65
	v_fmac_f32_e64 v23, s99, v65
	s_load_dwordx16 s[68:83], s[42:43], 0xc0
	s_load_dwordx16 s[84:99], s[100:101], 0xc0
	s_add_u32 s2, s2, 256
	s_addc_u32 s3, s3, 0
	s_add_i32 s40, s40, 16
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(0)
	v_fmac_f32_e64 v22, s68, v70
	v_fmac_f32_e64 v23, s84, v70
	v_fmac_f32_e64 v22, s69, v71
	v_fmac_f32_e64 v23, s85, v71
	v_fmac_f32_e64 v22, s70, v72
	v_fmac_f32_e64 v23, s86, v72
	v_fmac_f32_e64 v22, s71, v73
	v_fmac_f32_e64 v23, s87, v73
	v_fmac_f32_e64 v22, s72, v74
	v_fmac_f32_e64 v23, s88, v74
	v_fmac_f32_e64 v22, s73, v75
	v_fmac_f32_e64 v23, s89, v75
	v_fmac_f32_e64 v22, s74, v76
	v_fmac_f32_e64 v23, s90, v76
	v_fmac_f32_e64 v22, s75, v77
	v_fmac_f32_e64 v23, s91, v77
	v_fmac_f32_e64 v22, s76, v78
	v_fmac_f32_e64 v23, s92, v78
	v_fmac_f32_e64 v22, s77, v79
	v_fmac_f32_e64 v23, s93, v79
	v_fmac_f32_e64 v22, s78, v80
	v_fmac_f32_e64 v23, s94, v80
	v_fmac_f32_e64 v22, s79, v81
	v_fmac_f32_e64 v23, s95, v81
	v_fmac_f32_e64 v22, s80, v82
	v_fmac_f32_e64 v23, s96, v82
	v_fmac_f32_e64 v22, s81, v83
	v_fmac_f32_e64 v23, s97, v83
	v_fmac_f32_e64 v22, s82, v84
	v_fmac_f32_e64 v23, s98, v84
	v_fmac_f32_e64 v22, s83, v85
	v_fmac_f32_e64 v23, s99, v85
	s_cmpk_lt_u32 s40, 0x8c
	s_cbranch_scc1 .LBB0_7
.Lft3:
	v_pk_mul_f32 v[2:3], v[22:23], s[22:23]
.LBB0_9:
	s_or_b64 exec, exec, s[38:39]
	ds_write_b64 v103, v[2:3] offset:16384
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_11
.Lft4:
	ds_read_b32 v14, v104
	ds_read2_b32 v[4:5], v112 offset0:2 offset1:4
	ds_read2_b32 v[6:7], v112 offset0:6 offset1:8
	ds_read2_b32 v[8:9], v112 offset0:10 offset1:12
	ds_read2_b32 v[10:11], v112 offset0:14 offset1:16
	ds_read2_b32 v[12:13], v112 offset0:18 offset1:20
	ds_read_b32 v16, v112 offset:248
	s_waitcnt lgkmcnt(5)
	v_max_f32_e32 v4, v14, v4
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v4, v4, v7, v8
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v12, v4, v11, v12
	ds_read2_b32 v[4:5], v112 offset0:22 offset1:24
	ds_read2_b32 v[6:7], v112 offset0:26 offset1:28
	ds_read2_b32 v[8:9], v112 offset0:30 offset1:32
	ds_read2_b32 v[10:11], v112 offset0:34 offset1:36
	ds_read2_b32 v[14:15], v112 offset0:38 offset1:40
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
	ds_read2_b32 v[4:5], v112 offset0:42 offset1:44
	ds_read2_b32 v[6:7], v112 offset0:46 offset1:48
	ds_read2_b32 v[8:9], v112 offset0:50 offset1:52
	ds_read2_b32 v[10:11], v112 offset0:54 offset1:56
	ds_read2_b32 v[12:13], v112 offset0:58 offset1:60
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v4, v14, v15, v4
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v4, v7, v8
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v4, v4, v11, v12
	v_max3_f32 v4, v4, v13, v16
	ds_write_b32 v105, v4
.LBB0_11:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[38:39], s[8:9]
	s_cbranch_execz .LBB0_13
.Lft5:
	ds_read_b128 v[4:7], v106
	ds_read_b128 v[8:11], v106 offset:16
	ds_read_b128 v[12:15], v106 offset:32
	ds_read_b128 v[16:19], v106 offset:48
	ds_read_b128 v[20:23], v106 offset:64
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v4, v4, v7, v8
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v4, v11, v12
	v_max3_f32 v4, v4, v13, v14
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v4, v4, v15, v16
	v_max3_f32 v8, v4, v17, v18
	ds_read_b128 v[4:7], v106 offset:80
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v12, v8, v19, v20
	ds_read_b128 v[8:11], v106 offset:96
	v_max3_f32 v16, v12, v21, v22
	ds_read_b128 v[12:15], v106 offset:112
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v4, v16, v23, v4
	v_max3_f32 v4, v4, v5, v6
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v4, v4, v7, v8
	v_max3_f32 v4, v4, v9, v10
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v4, v4, v11, v12
	v_max3_f32 v4, v4, v13, v14
	v_max3_f32 v4, v111, v4, v15
	v_sub_f32_e32 v5, v111, v4
	v_add_f32_e32 v6, 0x42800000, v5
	v_cmp_gt_f32_e64 s[2:3], s49, v5
	v_mov_b32_e32 v111, v4
	s_nop 0
	v_cndmask_b32_e64 v5, v5, v6, s[2:3]
	v_mul_f32_e32 v5, 0x3fb8aa3b, v5
	v_exp_f32_e32 v5, v5
	v_add_u32_e32 v6, 0x7108, v1
	ds_write_b32 v6, v4
	v_mul_f32_e32 v6, 0x114b4ea4, v5
	v_cndmask_b32_e64 v5, v5, v6, s[2:3]
	ds_write_b32 v107, v5
.LBB0_13:
	s_or_b64 exec, exec, s[38:39]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], vcc
	s_xor_b64 s[2:3], exec, s[2:3]
	ds_write_b32 v103, v44 offset:16384
	s_or_saveexec_b64 s[38:39], s[2:3]
	v_mov_b32_e32 v4, 0
	s_xor_b64 exec, exec, s[38:39]
	s_cbranch_execz .LBB0_17
.Lft6:
	ds_read_b64 v[4:5], v44 offset:28936
	s_waitcnt lgkmcnt(0)
	v_sub_f32_e32 v2, v2, v4
	v_add_f32_e32 v4, 0x42800000, v2
	v_cmp_gt_f32_e32 vcc, s49, v2
	v_sub_f32_e32 v3, v3, v5
	v_add_f32_e32 v5, 0x42800000, v3
	v_cndmask_b32_e32 v2, v2, v4, vcc
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e64 s[2:3], s49, v3
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v5, s[2:3]
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v3
	v_mul_f32_e32 v4, 0x114b4ea4, v2
	v_cndmask_b32_e32 v2, v2, v4, vcc
	ds_write_b32 v103, v2 offset:16384
	v_mul_f32_e32 v2, 0x114b4ea4, v3
	v_cndmask_b32_e64 v4, v3, v2, s[2:3]
.LBB0_17:
	s_or_b64 exec, exec, s[38:39]
	ds_write_b32 v103, v4 offset:16388
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_19
.Lft7:
	ds_read_b32 v10, v104
	ds_read2_b32 v[2:3], v112 offset0:2 offset1:4
	ds_read2_b32 v[4:5], v112 offset0:6 offset1:8
	ds_read2_b32 v[6:7], v112 offset0:10 offset1:12
	ds_read2_b32 v[8:9], v112 offset0:14 offset1:16
	ds_read_b32 v11, v112 offset:248
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v2, v2, v10
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v2, v4, v2
	v_add_f32_e32 v2, v5, v2
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, v6, v2
	ds_read2_b32 v[2:3], v112 offset0:18 offset1:20
	v_add_f32_e32 v4, v7, v4
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v6, v8, v4
	ds_read2_b32 v[4:5], v112 offset0:22 offset1:24
	v_add_f32_e32 v6, v9, v6
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	ds_read2_b32 v[6:7], v112 offset0:26 offset1:28
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v2
	ds_read2_b32 v[2:3], v112 offset0:30 offset1:32
	v_add_f32_e32 v4, v5, v4
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v6, v4
	ds_read2_b32 v[4:5], v112 offset0:34 offset1:36
	v_add_f32_e32 v6, v7, v6
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	ds_read2_b32 v[6:7], v112 offset0:38 offset1:40
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v2
	ds_read2_b32 v[2:3], v112 offset0:42 offset1:44
	v_add_f32_e32 v4, v5, v4
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v6, v4
	ds_read2_b32 v[4:5], v112 offset0:46 offset1:48
	v_add_f32_e32 v6, v7, v6
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v6, v3, v2
	ds_read2_b32 v[2:3], v112 offset0:50 offset1:52
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v6
	ds_read2_b32 v[6:7], v112 offset0:54 offset1:56
	v_add_f32_e32 v8, v5, v4
	ds_read2_b32 v[4:5], v112 offset0:58 offset1:60
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v2, v8
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v2, v7, v2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v4, v2
	v_add_f32_e32 v2, v5, v2
	v_add_f32_e32 v2, v11, v2
	ds_write_b32 v105, v2
.LBB0_19:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[8:9]
	s_cbranch_execz .LBB0_21
.Lft8:
	ds_read_b128 v[2:5], v106
	ds_read_b128 v[6:9], v106 offset:16
	ds_read_b128 v[10:13], v106 offset:32
	ds_read_b128 v[14:17], v106 offset:48
	ds_read_b128 v[18:21], v106 offset:80
	ds_read_b128 v[22:25], v106 offset:64
	ds_read_b128 v[26:29], v106 offset:96
	ds_read_b128 v[30:33], v106 offset:112
	ds_read_b32 v45, v107
	s_waitcnt lgkmcnt(5)
	v_pk_add_f32 v[8:9], v[8:9], v[16:17]
	v_pk_add_f32 v[4:5], v[4:5], v[12:13]
	v_pk_add_f32 v[6:7], v[6:7], v[14:15]
	v_pk_add_f32 v[2:3], v[2:3], v[10:11]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[4:5], v[4:5], v[24:25]
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_pk_add_f32 v[2:3], v[2:3], v[22:23]
	v_pk_add_f32 v[6:7], v[6:7], v[18:19]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[8:9], v[8:9], v[32:33]
	v_pk_add_f32 v[4:5], v[4:5], v[28:29]
	v_pk_add_f32 v[6:7], v[6:7], v[30:31]
	v_pk_add_f32 v[2:3], v[2:3], v[26:27]
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	s_nop 0
	v_pk_add_f32 v[2:3], v[2:3], v[4:5]
	s_nop 0
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e32 v2, v45, v110
	v_add_u32_e32 v3, 0x7100, v1
	v_mov_b32_e32 v110, v2
	ds_write_b32 v3, v2
.LBB0_21:
	s_or_b64 exec, exec, s[2:3]
	s_lshl_b32 s2, s48, 10
	s_sub_i32 s2, s21, s2
	s_min_i32 s70, s2, 0x400
	s_sub_i32 s2, s21, s67
	s_min_i32 s68, s2, 0x400
	v_or_b32_e32 v2, s67, v36
	v_mov_b32_e32 v8, 0
	s_min_i32 s69, s66, 0x400
	v_mad_u64_u32 v[46:47], s[2:3], v2, s11, v[38:39]
	v_cmp_gt_i32_e32 vcc, s68, v108
	v_mov_b32_e32 v10, v36
	v_mov_b32_e32 v9, v8
	v_mov_b32_e32 v6, v8
	v_mov_b32_e32 v7, v8
	v_mov_b32_e32 v4, v8
	v_mov_b32_e32 v5, v8
	v_mov_b32_e32 v2, v8
	v_mov_b32_e32 v3, v8
	s_and_saveexec_b64 s[38:39], vcc
	s_cbranch_execz .LBB0_31
.Lft9:
	v_add_u32_e32 v2, s70, v109
	v_lshrrev_b32_e32 v113, 6, v2
	v_mov_b32_e32 v45, v44
	v_cmp_ne_u32_e32 vcc, 0, v113
	s_mov_b64 s[42:43], -1
	v_mov_b64_e32 v[16:17], v[44:45]
	v_mov_b64_e32 v[18:19], v[44:45]
	v_mov_b64_e32 v[12:13], v[44:45]
	v_mov_b64_e32 v[14:15], v[44:45]
	v_mov_b32_e32 v11, v36
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_26
.Lft10:
	v_add_u32_e32 v2, s69, v109
	v_lshrrev_b32_e32 v2, 6, v2
	v_add_u32_e32 v2, 1, v2
	v_mov_b32_e32 v54, 0
	v_and_b32_e32 v48, 0x7fffffe, v2
	v_mov_b32_e32 v49, v44
	s_mov_b64 s[40:41], 0
	v_mov_b64_e32 v[50:51], v[42:43]
	v_mov_b64_e32 v[52:53], v[36:37]
	v_mov_b32_e32 v55, v54
	v_mov_b32_e32 v56, v54
	v_mov_b32_e32 v57, v54
	v_mov_b32_e32 v58, v54
	v_mov_b32_e32 v59, v54
	v_mov_b32_e32 v60, v54
	v_mov_b32_e32 v61, v54
	v_mov_b32_e32 v62, v54
	v_mov_b32_e32 v63, v54
	v_mov_b32_e32 v64, v54
	v_mov_b32_e32 v65, v54
	v_mov_b32_e32 v66, v54
	v_mov_b32_e32 v67, v54
	v_mov_b32_e32 v68, v54
	v_mov_b32_e32 v69, v54
	s_mov_b32 s100, 0xfffdc000
	s_mov_b32 s101, -1
.LBB0_24:
	v_lshl_add_u64 v[126:127], v[50:51], 0, s[100:101]
	v_lshlrev_b32_e32 v45, 3, v52
	global_load_dwordx4 v[2:5], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[6:9], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[10:13], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[14:17], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[18:21], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[22:25], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[26:29], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[30:33], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[70:73], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[74:77], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[78:81], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[82:85], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[86:89], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[90:93], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[94:97], v[126:127], off
	v_lshl_add_u64 v[126:127], v[126:127], 0, s[30:31]
	global_load_dwordx4 v[98:101], v[126:127], off
	v_add_u32_e32 v45, 0x4000, v45
	ds_read2_b64 v[114:117], v45 offset1:8
	ds_read2_b64 v[118:121], v45 offset0:16 offset1:24
	ds_read2_b64 v[122:125], v45 offset0:32 offset1:40
	v_lshl_add_u64 v[48:49], v[48:49], 0, -2
	v_add_u32_e32 v52, 0x80, v52
	v_add_u32_e32 v53, 0x80, v53
	v_cmp_eq_u64_e32 vcc, 0, v[48:49]
	v_lshl_add_u64 v[50:51], v[50:51], 0, s[14:15]
	s_or_b64 s[40:41], vcc, s[40:41]
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(14)
	v_pk_fma_f32 v[68:69], v[2:3], v[114:115], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[4:5], v[114:115], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[2:3], v[114:115], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[4:5], v[114:115], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[68:69], v[6:7], v[116:117], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[8:9], v[116:117], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[6:7], v[116:117], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[8:9], v[116:117], v[56:57] op_sel:[0,1,0]
	ds_read2_b64 v[114:117], v45 offset0:48 offset1:56
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(12)
	v_pk_fma_f32 v[68:69], v[10:11], v[118:119], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[12:13], v[118:119], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[10:11], v[118:119], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[12:13], v[118:119], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[68:69], v[14:15], v[120:121], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[16:17], v[120:121], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[14:15], v[120:121], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[16:17], v[120:121], v[56:57] op_sel:[0,1,0]
	ds_read2_b64 v[118:121], v45 offset0:64 offset1:72
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(10)
	v_pk_fma_f32 v[68:69], v[18:19], v[122:123], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[20:21], v[122:123], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[18:19], v[122:123], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[20:21], v[122:123], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[68:69], v[22:23], v[124:125], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[24:25], v[124:125], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[22:23], v[124:125], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[24:25], v[124:125], v[56:57] op_sel:[0,1,0]
	ds_read2_b64 v[122:125], v45 offset0:80 offset1:88
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(8)
	v_pk_fma_f32 v[68:69], v[26:27], v[114:115], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[28:29], v[114:115], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[26:27], v[114:115], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[28:29], v[114:115], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[68:69], v[30:31], v[116:117], v[68:69] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[64:65], v[32:33], v[116:117], v[64:65] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[30:31], v[116:117], v[60:61] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[32:33], v[116:117], v[56:57] op_sel:[0,1,0]
	ds_read2_b64 v[114:117], v45 offset0:96 offset1:104
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(6)
	v_pk_fma_f32 v[66:67], v[70:71], v[118:119], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[72:73], v[118:119], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[70:71], v[118:119], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[72:73], v[118:119], v[54:55] op_sel:[0,1,0]
	v_pk_fma_f32 v[66:67], v[74:75], v[120:121], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[76:77], v[120:121], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[74:75], v[120:121], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[76:77], v[120:121], v[54:55] op_sel:[0,1,0]
	ds_read2_b64 v[118:121], v45 offset0:112 offset1:120
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(4)
	v_pk_fma_f32 v[66:67], v[78:79], v[122:123], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[80:81], v[122:123], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[78:79], v[122:123], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[80:81], v[122:123], v[54:55] op_sel:[0,1,0]
	v_pk_fma_f32 v[66:67], v[82:83], v[124:125], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[84:85], v[124:125], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[82:83], v[124:125], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[84:85], v[124:125], v[54:55] op_sel:[0,1,0]
	s_waitcnt lgkmcnt(1)
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[66:67], v[86:87], v[114:115], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[88:89], v[114:115], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[86:87], v[114:115], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[88:89], v[114:115], v[54:55] op_sel:[0,1,0]
	v_pk_fma_f32 v[66:67], v[90:91], v[116:117], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[92:93], v[116:117], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[90:91], v[116:117], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[92:93], v[116:117], v[54:55] op_sel:[0,1,0]
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[66:67], v[94:95], v[118:119], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[96:97], v[118:119], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[94:95], v[118:119], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[96:97], v[118:119], v[54:55] op_sel:[0,1,0]
	v_pk_fma_f32 v[66:67], v[98:99], v[120:121], v[66:67] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[62:63], v[100:101], v[120:121], v[62:63] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[58:59], v[98:99], v[120:121], v[58:59] op_sel:[0,1,0]
	v_pk_fma_f32 v[54:55], v[100:101], v[120:121], v[54:55] op_sel:[0,1,0]
	s_andn2_b64 exec, exec, s[40:41]
	s_cbranch_execnz .LBB0_24
.Lft11:
	s_or_b64 exec, exec, s[40:41]
	v_add_u32_e32 v2, 1, v113
	v_mov_b32_e32 v3, v44
	v_and_b32_e32 v4, 0x7fffffe, v2
	v_mov_b32_e32 v5, v44
	v_lshl_or_b32 v10, v4, 6, v36
	v_pk_add_f32 v[68:69], v[68:69], v[66:67]
	v_pk_add_f32 v[64:65], v[64:65], v[62:63]
	v_pk_add_f32 v[60:61], v[60:61], v[58:59]
	v_pk_add_f32 v[56:57], v[56:57], v[54:55]
	v_mov_b32_e32 v14, v68
	v_mov_b32_e32 v15, v68
	v_mov_b32_e32 v6, v69
	v_mov_b32_e32 v7, v69
	v_mov_b32_e32 v12, v64
	v_mov_b32_e32 v13, v64
	v_mov_b32_e32 v8, v65
	v_mov_b32_e32 v9, v65
	v_mov_b32_e32 v18, v60
	v_mov_b32_e32 v19, v60
	v_mov_b32_e32 v20, v61
	v_mov_b32_e32 v21, v61
	v_mov_b32_e32 v16, v56
	v_mov_b32_e32 v17, v56
	v_mov_b32_e32 v22, v57
	v_mov_b32_e32 v23, v57
	v_cmp_ne_u64_e32 vcc, v[4:5], v[2:3]
	v_mad_u64_u32 v[46:47], s[40:41], v4, s64, v[46:47]
	v_mov_b32_e32 v19, v20
	v_mov_b32_e32 v17, v22
	v_mov_b32_e32 v15, v6
	v_mov_b32_e32 v13, v8
	s_orn2_b64 s[42:43], vcc, exec
	v_mov_b32_e32 v3, v20
	v_mov_b32_e32 v2, v18
	v_mov_b32_e32 v5, v22
	v_mov_b32_e32 v4, v16
	v_mov_b32_e32 v7, v6
	v_mov_b32_e32 v6, v14
	v_mov_b32_e32 v9, v8
	v_mov_b32_e32 v8, v12
	v_mov_b32_e32 v11, v10
.LBB0_26:
	s_or_b64 exec, exec, s[2:3]
	s_and_saveexec_b64 s[40:41], s[42:43]
	s_cbranch_execz .LBB0_30
.Lft12:
	v_lshlrev_b32_e32 v28, 3, v11
	v_lshl_add_u64 v[6:7], v[46:47], 0, s[26:27]
	s_mov_b64 s[42:43], 0
	.p2align	5, , 4
.LBB0_28:
	v_add_co_u32_e32 v8, vcc, 0xfffe1000, v6
	v_add_u32_e32 v20, 0x4000, v28
	s_nop 0
	v_addc_co_u32_e32 v9, vcc, -1, v7, vcc
	v_add_co_u32_e32 v54, vcc, 0xfffe5000, v6
	ds_read2_b64 v[30:33], v20 offset1:8
	ds_read2_b64 v[46:49], v20 offset0:16 offset1:24
	ds_read2_b64 v[2:5], v20 offset0:32 offset1:40
	ds_read2_b64 v[50:53], v20 offset0:48 offset1:56
	v_addc_co_u32_e32 v55, vcc, -1, v7, vcc
	v_add_co_u32_e32 v58, vcc, 0xfffea000, v6
	global_load_dwordx4 v[78:81], v[8:9], off offset:-2060
	s_nop 0
	global_load_dwordx4 v[54:57], v[54:55], off offset:-12
	v_addc_co_u32_e32 v59, vcc, -1, v7, vcc
	v_add_co_u32_e32 v8, vcc, 0xfffee000, v6
	s_waitcnt lgkmcnt(2)
	v_mov_b32_e32 v74, v46
	v_addc_co_u32_e32 v9, vcc, -1, v7, vcc
	v_add_co_u32_e32 v62, vcc, 0xffff3000, v6
	global_load_dwordx4 v[82:85], v[58:59], off offset:-2060
	s_nop 0
	global_load_dwordx4 v[58:61], v[8:9], off offset:-12
	v_addc_co_u32_e32 v63, vcc, -1, v7, vcc
	v_add_co_u32_e32 v8, vcc, 0xffff7000, v6
	global_load_dwordx4 v[90:93], v[62:63], off offset:-2060
	s_nop 0
	v_addc_co_u32_e32 v9, vcc, -1, v7, vcc
	v_add_co_u32_e32 v66, vcc, 0xffffc000, v6
	global_load_dwordx4 v[62:65], v[8:9], off offset:-12
	s_nop 0
	v_addc_co_u32_e32 v67, vcc, -1, v7, vcc
	global_load_dwordx4 v[66:69], v[66:67], off offset:-2060
	s_nop 0
	global_load_dwordx4 v[70:73], v[6:7], off offset:-12
	v_mov_b32_e32 v75, v48
	v_mov_b32_e32 v48, v47
	v_mov_b32_e32 v76, v30
	v_mov_b32_e32 v77, v32
	v_mov_b32_e32 v32, v31
	v_mov_b32_e32 v21, v14
	v_mov_b32_e32 v23, v12
	v_mov_b32_e32 v25, v18
	v_mov_b32_e32 v27, v16
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v30, v2
	v_mov_b32_e32 v31, v4
	v_mov_b32_e32 v4, v3
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v2, v50
	v_mov_b32_e32 v3, v52
	v_add_u32_e32 v10, 64, v11
	v_add_u32_e32 v11, 0x78, v11
	v_cmp_le_i32_e64 s[2:3], s68, v11
	v_add_u32_e32 v28, 0x200, v28
	v_mov_b32_e32 v11, v10
	s_or_b64 s[42:43], s[2:3], s[42:43]
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[12:13]
	s_waitcnt vmcnt(7)
	v_mov_b32_e32 v8, v78
	v_mov_b32_e32 v46, v80
	s_waitcnt vmcnt(6)
	v_mov_b32_e32 v9, v54
	v_mov_b32_e32 v54, v79
	v_mov_b32_e32 v47, v56
	v_mov_b32_e32 v56, v81
	s_waitcnt vmcnt(5)
	v_mov_b32_e32 v78, v82
	v_mov_b32_e32 v80, v84
	s_waitcnt vmcnt(4)
	v_mov_b32_e32 v79, v58
	v_mov_b32_e32 v81, v60
	v_mov_b32_e32 v58, v83
	v_pk_mul_f32 v[82:83], v[78:79], v[74:75]
	v_pk_mul_f32 v[86:87], v[80:81], v[74:75]
	v_pk_mul_f32 v[78:79], v[78:79], v[48:49]
	v_pk_mul_f32 v[80:81], v[80:81], v[48:49]
	v_mov_b32_e32 v60, v85
	v_pk_fma_f32 v[82:83], v[8:9], v[76:77], v[82:83]
	v_pk_fma_f32 v[86:87], v[46:47], v[76:77], v[86:87]
	v_pk_fma_f32 v[8:9], v[8:9], v[32:33], v[78:79]
	v_pk_fma_f32 v[46:47], v[46:47], v[32:33], v[80:81]
	v_pk_mul_f32 v[84:85], v[58:59], v[74:75]
	v_pk_mul_f32 v[74:75], v[60:61], v[74:75]
	v_pk_mul_f32 v[58:59], v[58:59], v[48:49]
	v_pk_mul_f32 v[48:49], v[60:61], v[48:49]
	s_waitcnt vmcnt(3)
	v_mov_b32_e32 v60, v90
	v_mov_b32_e32 v88, v92
	s_waitcnt vmcnt(2)
	v_mov_b32_e32 v61, v62
	v_mov_b32_e32 v89, v64
	v_add_f32_e32 v20, v82, v83
	v_add_f32_e32 v22, v86, v87
	v_add_f32_e32 v24, v8, v9
	v_add_f32_e32 v26, v46, v47
	v_pk_fma_f32 v[78:79], v[54:55], v[76:77], v[84:85]
	v_pk_fma_f32 v[74:75], v[56:57], v[76:77], v[74:75]
	v_pk_fma_f32 v[54:55], v[54:55], v[32:33], v[58:59]
	v_pk_fma_f32 v[32:33], v[56:57], v[32:33], v[48:49]
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v8, v70, v52
	v_mov_b32_e32 v46, v67
	v_mov_b32_e32 v47, v71
	v_mul_f32_e32 v48, v72, v52
	v_mov_b32_e32 v56, v69
	v_mov_b32_e32 v57, v73
	v_mov_b32_e32 v52, v51
	v_pk_fma_f32 v[20:21], v[60:61], v[30:31], v[20:21]
	v_pk_fma_f32 v[22:23], v[88:89], v[30:31], v[22:23]
	v_pk_fma_f32 v[24:25], v[60:61], v[4:5], v[24:25]
	v_pk_fma_f32 v[26:27], v[88:89], v[4:5], v[26:27]
	v_mov_b32_e32 v62, v91
	v_mov_b32_e32 v64, v93
	v_mul_f32_e32 v14, v66, v50
	v_mul_f32_e32 v12, v68, v50
	v_add_f32_e32 v29, v78, v79
	v_add_f32_e32 v45, v74, v75
	v_mul_f32_e32 v50, v70, v53
	v_add_f32_e32 v55, v54, v55
	v_mul_f32_e32 v54, v72, v53
	v_add_f32_e32 v58, v32, v33
	v_pk_mul_f32 v[32:33], v[46:47], v[2:3]
	v_pk_mul_f32 v[2:3], v[56:57], v[2:3]
	v_pk_mul_f32 v[46:47], v[46:47], v[52:53]
	v_pk_mul_f32 v[52:53], v[56:57], v[52:53]
	v_pk_add_f32 v[20:21], v[20:21], v[20:21] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[22:23], v[22:23], v[22:23] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[24:25], v[24:25], v[24:25] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[26:27], v[26:27], v[26:27] op_sel:[0,1] op_sel_hi:[1,0]
	v_mul_f32_e32 v18, v66, v51
	v_mul_f32_e32 v16, v68, v51
	v_pk_fma_f32 v[32:33], v[62:63], v[30:31], v[32:33]
	v_pk_fma_f32 v[2:3], v[64:65], v[30:31], v[2:3]
	v_pk_fma_f32 v[30:31], v[62:63], v[4:5], v[46:47]
	v_pk_fma_f32 v[4:5], v[64:65], v[4:5], v[52:53]
	v_mov_b32_e32 v21, v29
	v_mov_b32_e32 v23, v45
	v_mov_b32_e32 v25, v55
	v_mov_b32_e32 v27, v58
	v_add_f32_e32 v9, v32, v33
	v_add_f32_e32 v49, v2, v3
	v_add_f32_e32 v51, v30, v31
	v_add_f32_e32 v55, v4, v5
	v_pk_add_f32 v[2:3], v[20:21], v[14:15]
	v_pk_add_f32 v[4:5], v[22:23], v[12:13]
	v_pk_add_f32 v[18:19], v[24:25], v[18:19]
	v_pk_add_f32 v[16:17], v[26:27], v[16:17]
	v_pk_add_f32 v[14:15], v[2:3], v[8:9]
	v_pk_add_f32 v[12:13], v[4:5], v[48:49]
	v_pk_add_f32 v[18:19], v[18:19], v[50:51]
	v_pk_add_f32 v[16:17], v[16:17], v[54:55]
	s_andn2_b64 exec, exec, s[42:43]
	s_cbranch_execnz .LBB0_28
.Lft13:
	s_or_b64 exec, exec, s[42:43]
	v_lshl_add_u64 v[46:47], v[6:7], 0, s[28:29]
	v_mov_b32_e32 v3, v19
	v_mov_b32_e32 v2, v18
	v_mov_b32_e32 v5, v17
	v_mov_b32_e32 v4, v16
	v_mov_b32_e32 v7, v15
	v_mov_b32_e32 v6, v14
	v_mov_b32_e32 v9, v13
	v_mov_b32_e32 v8, v12
.LBB0_30:
	s_or_b64 exec, exec, s[40:41]
.LBB0_31:
	s_or_b64 exec, exec, s[38:39]
	v_cmp_gt_i32_e32 vcc, s68, v10
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_41
.Lft14:
	v_xad_u32 v11, v10, -1, s70
	v_lshrrev_b32_e32 v26, 3, v11
	v_cmp_ne_u32_e32 vcc, 0, v26
	s_mov_b64 s[40:41], -1
	s_and_saveexec_b64 s[38:39], vcc
	s_cbranch_execz .LBB0_36
.Lft15:
	v_xad_u32 v20, v10, -1, s69
	v_lshrrev_b32_e32 v20, 3, v20
	v_add_u32_e32 v11, 8, v10
	v_add_u32_e32 v20, 1, v20
	v_mov_b32_e32 v12, v6
	v_mov_b32_e32 v13, v44
	v_mov_b32_e32 v6, v7
	v_mov_b32_e32 v7, v44
	v_mov_b32_e32 v14, v8
	v_mov_b32_e32 v15, v44
	v_mov_b32_e32 v8, v9
	v_mov_b32_e32 v9, v44
	v_mov_b32_e32 v16, v2
	v_mov_b32_e32 v17, v44
	v_mov_b32_e32 v2, v3
	v_mov_b32_e32 v3, v44
	v_mov_b32_e32 v18, v4
	v_mov_b32_e32 v19, v44
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v5, v44
	v_and_b32_e32 v20, 0x3ffffffe, v20
	v_mov_b32_e32 v21, v44
	v_lshl_add_u64 v[22:23], v[46:47], 0, s[30:31]
	s_mov_b64 s[40:41], 0
	v_mov_b64_e32 v[24:25], v[10:11]
	.p2align	5, , 4
.LBB0_34:
	v_add_co_u32_e32 v32, vcc, 0xffffc000, v22
	global_load_dwordx4 v[28:31], v[22:23], off
	s_nop 0
	v_addc_co_u32_e32 v33, vcc, -1, v23, vcc
	global_load_dwordx4 v[54:57], v[32:33], off offset:-2048
	v_lshlrev_b32_e32 v27, 3, v24
	v_lshlrev_b32_e32 v11, 3, v25
	ds_read_b64 v[32:33], v27 offset:16384
	ds_read_b64 v[48:49], v11 offset:16384
	v_lshl_add_u64 v[20:21], v[20:21], 0, -2
	v_cmp_eq_u64_e32 vcc, 0, v[20:21]
	v_add_u32_e32 v25, 16, v25
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v50, v32
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v51, v48
	v_mov_b32_e32 v48, v33
	v_add_u32_e32 v24, 16, v24
	v_lshl_add_u64 v[22:23], v[22:23], 0, s[34:35]
	s_or_b64 s[40:41], vcc, s[40:41]
	s_waitcnt vmcnt(1)
	v_mov_b32_e32 v33, v28
	v_mov_b32_e32 v53, v30
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v32, v54
	v_mov_b32_e32 v28, v55
	v_mov_b32_e32 v52, v56
	v_mov_b32_e32 v30, v57
	v_pk_fma_f32 v[12:13], v[50:51], v[32:33], v[12:13]
	v_pk_fma_f32 v[6:7], v[50:51], v[28:29], v[6:7]
	v_pk_fma_f32 v[14:15], v[50:51], v[52:53], v[14:15]
	v_pk_fma_f32 v[8:9], v[50:51], v[30:31], v[8:9]
	v_pk_fma_f32 v[16:17], v[48:49], v[32:33], v[16:17]
	v_pk_fma_f32 v[2:3], v[48:49], v[28:29], v[2:3]
	v_pk_fma_f32 v[18:19], v[48:49], v[52:53], v[18:19]
	v_pk_fma_f32 v[4:5], v[48:49], v[30:31], v[4:5]
	s_andn2_b64 exec, exec, s[40:41]
	s_cbranch_execnz .LBB0_34
.Lft16:
	s_or_b64 exec, exec, s[40:41]
	v_add_u32_e32 v24, 1, v26
	v_mov_b32_e32 v25, v44
	v_and_b32_e32 v26, 0x3ffffffe, v24
	v_mov_b32_e32 v27, v44
	v_mad_u64_u32 v[46:47], s[40:41], v26, s65, v[46:47]
	v_pk_add_f32 v[20:21], v[12:13], v[12:13] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[6:7], v[6:7], v[6:7] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[22:23], v[14:15], v[14:15] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[8:9], v[8:9], v[8:9] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[12:13], v[16:17], v[16:17] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[2:3], v[2:3], v[2:3] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[14:15], v[18:19], v[18:19] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[4:5], v[4:5], v[4:5] op_sel:[0,1] op_sel_hi:[1,0]
	v_cmp_ne_u64_e32 vcc, v[26:27], v[24:25]
	v_lshl_add_u32 v10, v26, 3, v10
	v_mov_b32_e32 v13, v2
	v_mov_b32_e32 v15, v4
	v_mov_b32_e32 v21, v6
	v_mov_b32_e32 v23, v8
	s_orn2_b64 s[40:41], vcc, exec
	v_mov_b32_e32 v3, v2
	v_mov_b32_e32 v2, v12
	v_mov_b32_e32 v5, v4
	v_mov_b32_e32 v4, v14
	v_mov_b32_e32 v7, v6
	v_mov_b32_e32 v6, v20
	v_mov_b32_e32 v9, v8
	v_mov_b32_e32 v8, v22
.LBB0_36:
	s_or_b64 exec, exec, s[38:39]
	s_and_saveexec_b64 s[38:39], s[40:41]
	s_cbranch_execz .LBB0_40
.Lft17:
	v_lshlrev_b32_e32 v11, 3, v10
	v_lshl_add_u64 v[12:13], v[46:47], 0, 8
	s_mov_b64 s[40:41], 0
	.p2align	5, , 4
.LBB0_38:
	global_load_dwordx4 v[14:17], v[12:13], off offset:-8
	ds_read_b64 v[18:19], v11 offset:16384
	v_add_u32_e32 v10, 8, v10
	v_cmp_le_i32_e32 vcc, s68, v10
	v_add_u32_e32 v11, 64, v11
	v_lshl_add_u64 v[12:13], v[12:13], 0, s[30:31]
	s_or_b64 s[40:41], vcc, s[40:41]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_pk_fma_f32 v[6:7], v[18:19], v[14:15], v[6:7] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[2:3], v[18:19], v[14:15], v[2:3] op_sel:[1,0,0]
	v_pk_fma_f32 v[8:9], v[18:19], v[16:17], v[8:9] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[4:5], v[18:19], v[16:17], v[4:5] op_sel:[1,0,0]
	s_andn2_b64 exec, exec, s[40:41]
	s_cbranch_execnz .LBB0_38
.Lft18:
	s_or_b64 exec, exec, s[40:41]
	v_mov_b64_e32 v[12:13], v[2:3]
	v_mov_b64_e32 v[14:15], v[4:5]
	v_mov_b64_e32 v[20:21], v[6:7]
	v_mov_b64_e32 v[22:23], v[8:9]
.LBB0_40:
	s_or_b64 exec, exec, s[38:39]
	v_mov_b64_e32 v[8:9], v[22:23]
	v_mov_b64_e32 v[6:7], v[20:21]
	v_mov_b64_e32 v[4:5], v[14:15]
	v_mov_b64_e32 v[2:3], v[12:13]
.LBB0_41:
	s_or_b64 exec, exec, s[2:3]
	ds_write_b128 v102, v[6:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[6:7]
	s_cbranch_execz .LBB0_43
.Lft19:
	ds_read_b128 v[6:9], v102
	ds_read_b128 v[10:13], v102 offset:2048
	ds_read_b128 v[14:17], v102 offset:4096
	ds_read_b128 v[18:21], v102 offset:6144
	ds_read_b32 v54, v44 offset:28944
	ds_read_b128 v[22:25], v102 offset:8192
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[10:11], v[6:7]
	v_pk_add_f32 v[8:9], v[12:13], v[8:9]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[14:15], v[6:7]
	v_pk_add_f32 v[8:9], v[16:17], v[8:9]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[18:19], v[6:7]
	ds_read_b128 v[26:29], v102 offset:10240
	ds_read_b128 v[30:33], v102 offset:12288
	ds_read_b128 v[46:49], v102 offset:14336
	ds_read_b128 v[50:53], v102 offset:24576
	v_pk_add_f32 v[8:9], v[20:21], v[8:9]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[22:23], v[6:7]
	v_pk_add_f32 v[8:9], v[24:25], v[8:9]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[26:27], v[6:7]
	v_pk_add_f32 v[8:9], v[28:29], v[8:9]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[30:31], v[6:7]
	v_pk_add_f32 v[8:9], v[32:33], v[8:9]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[6:7], v[46:47], v[6:7]
	v_pk_add_f32 v[8:9], v[48:49], v[8:9]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[6:7], v[50:51], v[54:55], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[52:53], v[54:55], v[8:9] op_sel_hi:[1,0,1]
	ds_write_b128 v102, v[6:9] offset:24576
.LBB0_43:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v102, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[6:7]
	s_cbranch_execz .LBB0_4
.Lft20:
	ds_read_b128 v[2:5], v102
	ds_read_b128 v[6:9], v102 offset:2048
	ds_read_b128 v[10:13], v102 offset:4096
	ds_read_b128 v[14:17], v102 offset:6144
	ds_read_b32 v50, v44 offset:28948
	ds_read_b128 v[18:21], v102 offset:8192
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[6:7], v[2:3]
	v_pk_add_f32 v[4:5], v[8:9], v[4:5]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[10:11], v[2:3]
	v_pk_add_f32 v[4:5], v[12:13], v[4:5]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[14:15], v[2:3]
	ds_read_b128 v[22:25], v102 offset:10240
	ds_read_b128 v[26:29], v102 offset:12288
	ds_read_b128 v[30:33], v102 offset:14336
	ds_read_b128 v[46:49], v102 offset:26624
	v_pk_add_f32 v[4:5], v[16:17], v[4:5]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[18:19], v[2:3]
	v_pk_add_f32 v[4:5], v[20:21], v[4:5]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[22:23], v[2:3]
	v_pk_add_f32 v[4:5], v[24:25], v[4:5]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[26:27], v[2:3]
	v_pk_add_f32 v[4:5], v[28:29], v[4:5]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[2:3], v[30:31], v[2:3]
	v_pk_add_f32 v[4:5], v[32:33], v[4:5]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[2:3], v[46:47], v[50:51], v[2:3] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[48:49], v[50:51], v[4:5] op_sel_hi:[1,0,1]
	ds_write_b128 v102, v[2:5] offset:26624
	s_branch .LBB0_4
.LBB0_45:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v110
	v_mov_b32_e32 v2, 0xc1b17218
	s_nop 0
	v_cndmask_b32_e64 v3, 0, 32, vcc
	v_ldexp_f32 v3, v110, v3
	v_log_f32_e32 v3, v3
	v_cndmask_b32_e32 v2, 0, v2, vcc
	v_fmamk_f32 v2, v3, 0x3f317218, v2
	v_add_f32_e32 v4, v111, v2
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_cbranch_execnz .LBB0_47
.Lft21:
	s_branch .LBB0_51
.LBB0_46:
	v_mov_b32_e32 v4, 0xff800000
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_cbranch_execz .LBB0_51
.LBB0_47:
	s_movk_i32 s2, 0x6000
	s_ashr_i32 s3, s10, 31
	v_lshl_add_u32 v5, v0, 4, s2
	s_add_u32 s2, s24, s10
	v_mov_b32_e32 v2, s16
	v_mov_b32_e32 v3, s17
	s_addc_u32 s3, s25, s3
	s_cmp_lt_i32 s10, s20
	v_lshl_add_u64 v[2:3], v[34:35], 2, v[2:3]
	s_cbranch_scc0 .LBB0_49
.Lft22:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v12, v6 offset:28928
	ds_read_b128 v[6:9], v5
	s_waitcnt lgkmcnt(1)
	v_div_scale_f32 v13, s[6:7], v12, v12, 1.0
	v_rcp_f32_e32 v14, v13
	v_div_scale_f32 v15, vcc, 1.0, v12, 1.0
	s_lshl_b64 s[6:7], s[2:3], 11
	v_lshl_add_u64 v[10:11], v[2:3], 0, s[6:7]
	v_fma_f32 v16, -v13, v14, 1.0
	v_fmac_f32_e32 v14, v16, v14
	v_mul_f32_e32 v16, v15, v14
	v_fma_f32 v17, -v13, v16, v15
	v_fmac_f32_e32 v16, v17, v14
	v_fma_f32 v13, -v13, v16, v15
	v_div_fmas_f32 v13, v13, v14, v16
	v_div_fixup_f32 v12, v13, v12, 1.0
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[6:7], v[6:7], v[12:13] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[12:13] op_sel_hi:[1,0]
	global_store_dwordx4 v[10:11], v[6:9], off
.LBB0_49:
	s_cmp_ge_i32 s5, s20
	s_cbranch_scc1 .LBB0_51
.Lft23:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v10, v6 offset:28932
	ds_read_b128 v[6:9], v5 offset:2048
	s_lshl_b64 s[2:3], s[2:3], 11
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	s_waitcnt lgkmcnt(1)
	v_div_scale_f32 v5, s[6:7], v10, v10, 1.0
	v_rcp_f32_e32 v11, v5
	v_div_scale_f32 v12, vcc, 1.0, v10, 1.0
	v_fma_f32 v13, -v5, v11, 1.0
	v_fmac_f32_e32 v11, v13, v11
	v_mul_f32_e32 v13, v12, v11
	v_fma_f32 v14, -v5, v13, v12
	v_fmac_f32_e32 v13, v14, v11
	v_fma_f32 v5, -v5, v13, v12
	v_div_fmas_f32 v5, v5, v11, v13
	v_div_fixup_f32 v10, v5, v10, 1.0
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[6:7], v[6:7], v[10:11] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[10:11] op_sel_hi:[1,0]
	global_store_dwordx4 v[2:3], v[6:9], off offset:2048
.LBB0_51:
	s_or_b64 exec, exec, s[0:1]
	s_cmp_eq_u32 s4, 0
	v_cmp_gt_u32_e32 vcc, 2, v0
	s_cselect_b64 s[0:1], -1, 0
	v_or_b32_e32 v0, s10, v0
	s_and_b64 s[0:1], vcc, s[0:1]
	v_cmp_gt_i32_e32 vcc, s20, v0
	s_and_b64 s[0:1], s[0:1], vcc
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_53
.Lft24:
	s_ashr_i32 s11, s10, 31
	s_lshl_b64 s[0:1], s[24:25], 2
	s_add_u32 s2, s18, s0
	s_addc_u32 s3, s19, s1
	s_lshl_b64 s[0:1], s[10:11], 2
	s_add_u32 s0, s2, s0
	s_addc_u32 s1, s3, s1
	global_store_dword v1, v4, s[0:1]
.LBB0_53:
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
		.amdhsa_next_free_vgpr 128
		.amdhsa_next_free_sgpr 102
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
  .sgpr_count: 108
  .sgpr_spill_count: 0
  .symbol: mla_decode.kd
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
