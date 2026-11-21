	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	mla_decode
	.globl	mla_decode
	.p2align	8
	.type	mla_decode,@function
mla_decode:
	v_cmp_gt_u32_e32 vcc, 64, v0
	v_lshlrev_b32_e32 v2, 4, v0
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_2
.Lft0:
	s_mov_b32 s8, 0
	s_mov_b32 s9, s8
	s_mov_b32 s10, s8
	s_mov_b32 s11, s8
	v_mov_b64_e32 v[4:5], s[8:9]
	v_mov_b64_e32 v[6:7], s[10:11]
	ds_write_b128 v2, v[4:7] offset:32768
	ds_write_b128 v2, v[4:7] offset:33792
	ds_write_b128 v2, v[4:7] offset:34816
	ds_write_b128 v2, v[4:7] offset:35840
.LBB0_2:
	s_or_b64 exec, exec, s[6:7]
	s_load_dwordx4 s[16:19], s[0:1], 0x20
	s_load_dwordx8 s[8:15], s[0:1], 0x0
	v_lshlrev_b32_e32 v1, 2, v0
	s_lshl_b32 s20, s2, 2
	v_and_b32_e32 v3, 0xfc, v1
	s_lshl_b32 s6, s4, 8
	s_or_b32 s33, s20, 1
	s_or_b32 s21, s20, 2
	s_or_b32 s5, s20, 3
	v_or_b32_e32 v6, s6, v3
	s_waitcnt lgkmcnt(0)
	s_mul_hi_i32 s23, s16, s3
	s_mul_i32 s22, s16, s3
	s_cmp_lt_i32 s17, 1
	v_ashrrev_i32_e32 v7, 31, v6
	v_cmp_gt_u32_e64 s[0:1], 4, v0
	s_cbranch_scc1 .LBB0_48
.Lft1:
	s_ashr_i32 s2, s17, 31
	s_mul_hi_i32 s7, s3, 0x900
	s_mul_i32 s19, s3, 0x900
	s_mul_i32 s2, s19, s2
	s_mul_i32 s7, s7, s17
	s_add_i32 s24, s16, -1
	s_mul_hi_u32 s3, s19, s17
	s_add_i32 s7, s2, s7
	s_min_i32 s25, s20, s24
	s_add_i32 s2, s7, s3
	s_ashr_i32 s26, s25, 31
	s_add_u32 s25, s22, s25
	s_addc_u32 s26, s23, s26
	s_mulk_i32 s26, 0x900
	s_mul_hi_u32 s27, s25, 0x900
	s_add_i32 s27, s27, s26
	s_mulk_i32 s25, 0x900
	s_add_u32 s41, s8, s25
	s_addc_u32 s42, s9, s27
	s_min_i32 s25, s33, s24
	s_ashr_i32 s26, s25, 31
	s_add_u32 s25, s22, s25
	s_addc_u32 s26, s23, s26
	s_mulk_i32 s26, 0x900
	s_mul_hi_u32 s27, s25, 0x900
	s_add_i32 s27, s27, s26
	s_mulk_i32 s25, 0x900
	s_add_u32 s43, s8, s25
	s_addc_u32 s44, s9, s27
	s_min_i32 s25, s21, s24
	s_ashr_i32 s26, s25, 31
	s_add_u32 s25, s22, s25
	s_addc_u32 s26, s23, s26
	s_mulk_i32 s26, 0x900
	s_mul_hi_u32 s27, s25, 0x900
	s_add_i32 s27, s27, s26
	s_mulk_i32 s25, 0x900
	s_add_u32 s45, s8, s25
	s_addc_u32 s46, s9, s27
	s_min_i32 s24, s5, s24
	s_ashr_i32 s25, s24, 31
	s_add_u32 s24, s22, s24
	s_addc_u32 s25, s23, s25
	s_mulk_i32 s25, 0x900
	s_mul_hi_u32 s26, s24, 0x900
	s_add_i32 s26, s26, s25
	s_mulk_i32 s24, 0x900
	s_add_u32 s47, s8, s24
	s_mul_i32 s3, s19, s17
	s_addc_u32 s48, s9, s26
	v_lshlrev_b32_e32 v4, 9, v0
	s_add_u32 s8, s10, s3
	v_and_b32_e32 v50, 0x3e00, v4
	v_lshrrev_b32_e32 v4, 3, v0
	s_addc_u32 s9, s11, s2
	v_and_b32_e32 v51, 0x7c, v4
	v_mov_b32_e32 v4, 0x9000
	s_movk_i32 s40, 0x900
	v_lshrrev_b32_e32 v116, 6, v0
	v_lshl_add_u32 v122, v0, 7, v4
	v_mov_b64_e32 v[4:5], s[8:9]
	v_lshl_add_u64 v[106:107], v[6:7], 2, s[8:9]
	v_or_b32_e32 v124, 0x4000, v2
	v_or_b32_e32 v125, 0x8000, v2
	v_mad_u64_u32 v[108:109], s[8:9], v0, s40, v[4:5]
	v_mul_hi_u32_u24_e32 v5, 0x900, v116
	v_mul_u32_u24_e32 v4, 0x900, v116
	v_mov_b32_e32 v2, s17
	v_mad_u64_u32 v[4:5], s[8:9], s19, v2, v[4:5]
	v_add_u32_e32 v2, s6, v3
	v_add_u32_e32 v5, s7, v5
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[2:3], v[2:3], 2, v[4:5]
	s_movk_i32 s2, 0x80
	v_lshl_add_u64 v[2:3], s[10:11], 0, v[2:3]
	s_mov_b64 s[6:7], 0x3f00c
	v_lshlrev_b32_e32 v117, 2, v1
	v_cmp_gt_u32_e64 s[2:3], s2, v0
	v_or_b32_e32 v54, v51, v50
	s_mov_b32 s49, 0x9000
	v_or_b32_e32 v55, 0x9000, v1
	v_add_u32_e32 v56, 0x9220, v1
	s_mov_b32 s24, s18
	s_mov_b32 s25, s18
	s_mov_b32 s26, s18
	s_mov_b32 s27, s18
	v_lshl_add_u64 v[110:111], v[2:3], 0, s[6:7]
	v_mov_b32_e32 v59, 0
	s_mov_b32 s50, 0
	v_mov_b32_e32 v103, 0xff800000
	v_mov_b32_e32 v57, 0
	s_mov_b32 s51, 0xc2aeac50
	s_mov_b32 s52, 0xfffc1000
	s_mov_b32 s53, 0xfffca000
	s_mov_b32 s54, 0xfffd3000
	s_mov_b32 s55, 0xfffdc000
	s_mov_b32 s56, 0xfffe5000
	s_mov_b32 s57, 0xfffee000
	s_mov_b32 s58, 0xffff7000
	s_mov_b64 s[18:19], 0x48000
	s_mov_b64 s[28:29], 0x8ff4
	s_mov_b64 s[30:31], 0x9000
	s_mov_b64 s[34:35], 0x12000
	s_mov_b64 s[36:37], 0x240000
	s_mov_b32 s59, s17
	s_mov_b32 s60, 0
	scratch_store_dwordx2 off, v[6:7], off offset:52
	scratch_store_dword off, v1, off offset:24
	scratch_store_dword off, v51, off offset:28
	scratch_store_dword off, v54, off offset:32
	scratch_store_dword off, v55, off offset:36
	scratch_store_dword off, v56, off offset:40
	scratch_store_dwordx2 off, v[106:107], off offset:44
	s_branch .LBB0_5
.LBB0_4:
	s_or_b64 exec, exec, s[6:7]
	s_addk_i32 s60, 0x400
	s_add_i32 s50, s50, 1
	s_addk_i32 s59, 0xfc00
	s_waitcnt vmcnt(4)
	v_lshl_add_u64 v[108:109], v[108:109], 0, s[36:37]
	s_cmp_ge_i32 s60, s17
	s_waitcnt vmcnt(3)
	v_lshl_add_u64 v[110:111], v[110:111], 0, s[36:37]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_cbranch_scc1 .LBB0_47
.LBB0_5:
	v_or_b32_e32 v2, s60, v0
	v_cmp_le_i32_e64 s[6:7], s17, v2
	v_cmp_gt_i32_e64 s[8:9], s17, v2
	v_mov_b32_e32 v5, 0xff800000
	v_mov_b32_e32 v4, 0xff800000
	v_mov_b32_e32 v3, 0xff800000
	v_mov_b32_e32 v2, 0xff800000
	s_and_saveexec_b64 s[10:11], s[8:9]
	s_cbranch_execz .LBB0_9
.Lft2:
	v_mov_b32_e32 v13, 0
	s_mov_b64 s[8:9], 0
	s_mov_b32 s61, -4
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, v13
	.p2align	5, , 4
.LBB0_7:
	v_lshl_add_u64 v[2:3], v[108:109], 0, s[8:9]
	global_load_dwordx4 v[14:17], v[2:3], off offset:0
	global_load_dwordx4 v[18:21], v[2:3], off offset:16
	global_load_dwordx4 v[22:25], v[2:3], off offset:32
	global_load_dwordx4 v[26:29], v[2:3], off offset:48
	global_load_dwordx4 v[30:33], v[2:3], off offset:64
	global_load_dwordx4 v[34:37], v[2:3], off offset:80
	global_load_dwordx4 v[38:41], v[2:3], off offset:96
	global_load_dwordx4 v[42:45], v[2:3], off offset:112
	global_load_dwordx4 v[60:63], v[2:3], off offset:128
	global_load_dwordx4 v[64:67], v[2:3], off offset:144
	global_load_dwordx4 v[68:71], v[2:3], off offset:160
	global_load_dwordx4 v[72:75], v[2:3], off offset:176
	global_load_dwordx4 v[76:79], v[2:3], off offset:192
	global_load_dwordx4 v[80:83], v[2:3], off offset:208
	global_load_dwordx4 v[84:87], v[2:3], off offset:224
	global_load_dwordx4 v[88:91], v[2:3], off offset:240
	s_add_u32 s96, s41, s8
	s_addc_u32 s97, s42, s9
	s_add_u32 s98, s43, s8
	s_addc_u32 s99, s44, s9
	s_add_u32 s100, s45, s8
	s_addc_u32 s101, s46, s9
	s_add_u32 s62, s47, s8
	s_addc_u32 s63, s48, s9
	s_load_dwordx16 s[64:79], s[96:97], 0
	s_load_dwordx16 s[80:95], s[98:99], 0
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(12)
	v_fmac_f32_e64 v12, s64, v14
	v_fmac_f32_e64 v13, s80, v14
	v_fmac_f32_e64 v12, s65, v15
	v_fmac_f32_e64 v13, s81, v15
	v_fmac_f32_e64 v12, s66, v16
	v_fmac_f32_e64 v13, s82, v16
	v_fmac_f32_e64 v12, s67, v17
	v_fmac_f32_e64 v13, s83, v17
	v_fmac_f32_e64 v12, s68, v18
	v_fmac_f32_e64 v13, s84, v18
	v_fmac_f32_e64 v12, s69, v19
	v_fmac_f32_e64 v13, s85, v19
	v_fmac_f32_e64 v12, s70, v20
	v_fmac_f32_e64 v13, s86, v20
	v_fmac_f32_e64 v12, s71, v21
	v_fmac_f32_e64 v13, s87, v21
	v_fmac_f32_e64 v12, s72, v22
	v_fmac_f32_e64 v13, s88, v22
	v_fmac_f32_e64 v12, s73, v23
	v_fmac_f32_e64 v13, s89, v23
	v_fmac_f32_e64 v12, s74, v24
	v_fmac_f32_e64 v13, s90, v24
	v_fmac_f32_e64 v12, s75, v25
	v_fmac_f32_e64 v13, s91, v25
	v_fmac_f32_e64 v12, s76, v26
	v_fmac_f32_e64 v13, s92, v26
	v_fmac_f32_e64 v12, s77, v27
	v_fmac_f32_e64 v13, s93, v27
	v_fmac_f32_e64 v12, s78, v28
	v_fmac_f32_e64 v13, s94, v28
	v_fmac_f32_e64 v12, s79, v29
	v_fmac_f32_e64 v13, s95, v29
	s_load_dwordx16 s[64:79], s[100:101], 0
	s_load_dwordx16 s[80:95], s[62:63], 0
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e64 v10, s64, v14
	v_fmac_f32_e64 v11, s80, v14
	v_fmac_f32_e64 v10, s65, v15
	v_fmac_f32_e64 v11, s81, v15
	v_fmac_f32_e64 v10, s66, v16
	v_fmac_f32_e64 v11, s82, v16
	v_fmac_f32_e64 v10, s67, v17
	v_fmac_f32_e64 v11, s83, v17
	v_fmac_f32_e64 v10, s68, v18
	v_fmac_f32_e64 v11, s84, v18
	v_fmac_f32_e64 v10, s69, v19
	v_fmac_f32_e64 v11, s85, v19
	v_fmac_f32_e64 v10, s70, v20
	v_fmac_f32_e64 v11, s86, v20
	v_fmac_f32_e64 v10, s71, v21
	v_fmac_f32_e64 v11, s87, v21
	v_fmac_f32_e64 v10, s72, v22
	v_fmac_f32_e64 v11, s88, v22
	v_fmac_f32_e64 v10, s73, v23
	v_fmac_f32_e64 v11, s89, v23
	v_fmac_f32_e64 v10, s74, v24
	v_fmac_f32_e64 v11, s90, v24
	v_fmac_f32_e64 v10, s75, v25
	v_fmac_f32_e64 v11, s91, v25
	v_fmac_f32_e64 v10, s76, v26
	v_fmac_f32_e64 v11, s92, v26
	v_fmac_f32_e64 v10, s77, v27
	v_fmac_f32_e64 v11, s93, v27
	v_fmac_f32_e64 v10, s78, v28
	v_fmac_f32_e64 v11, s94, v28
	v_fmac_f32_e64 v10, s79, v29
	v_fmac_f32_e64 v11, s95, v29
	s_load_dwordx16 s[64:79], s[96:97], 64
	s_load_dwordx16 s[80:95], s[98:99], 64
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(8)
	v_fmac_f32_e64 v12, s64, v30
	v_fmac_f32_e64 v13, s80, v30
	v_fmac_f32_e64 v12, s65, v31
	v_fmac_f32_e64 v13, s81, v31
	v_fmac_f32_e64 v12, s66, v32
	v_fmac_f32_e64 v13, s82, v32
	v_fmac_f32_e64 v12, s67, v33
	v_fmac_f32_e64 v13, s83, v33
	v_fmac_f32_e64 v12, s68, v34
	v_fmac_f32_e64 v13, s84, v34
	v_fmac_f32_e64 v12, s69, v35
	v_fmac_f32_e64 v13, s85, v35
	v_fmac_f32_e64 v12, s70, v36
	v_fmac_f32_e64 v13, s86, v36
	v_fmac_f32_e64 v12, s71, v37
	v_fmac_f32_e64 v13, s87, v37
	v_fmac_f32_e64 v12, s72, v38
	v_fmac_f32_e64 v13, s88, v38
	v_fmac_f32_e64 v12, s73, v39
	v_fmac_f32_e64 v13, s89, v39
	v_fmac_f32_e64 v12, s74, v40
	v_fmac_f32_e64 v13, s90, v40
	v_fmac_f32_e64 v12, s75, v41
	v_fmac_f32_e64 v13, s91, v41
	v_fmac_f32_e64 v12, s76, v42
	v_fmac_f32_e64 v13, s92, v42
	v_fmac_f32_e64 v12, s77, v43
	v_fmac_f32_e64 v13, s93, v43
	v_fmac_f32_e64 v12, s78, v44
	v_fmac_f32_e64 v13, s94, v44
	v_fmac_f32_e64 v12, s79, v45
	v_fmac_f32_e64 v13, s95, v45
	s_load_dwordx16 s[64:79], s[100:101], 64
	s_load_dwordx16 s[80:95], s[62:63], 64
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e64 v10, s64, v30
	v_fmac_f32_e64 v11, s80, v30
	v_fmac_f32_e64 v10, s65, v31
	v_fmac_f32_e64 v11, s81, v31
	v_fmac_f32_e64 v10, s66, v32
	v_fmac_f32_e64 v11, s82, v32
	v_fmac_f32_e64 v10, s67, v33
	v_fmac_f32_e64 v11, s83, v33
	v_fmac_f32_e64 v10, s68, v34
	v_fmac_f32_e64 v11, s84, v34
	v_fmac_f32_e64 v10, s69, v35
	v_fmac_f32_e64 v11, s85, v35
	v_fmac_f32_e64 v10, s70, v36
	v_fmac_f32_e64 v11, s86, v36
	v_fmac_f32_e64 v10, s71, v37
	v_fmac_f32_e64 v11, s87, v37
	v_fmac_f32_e64 v10, s72, v38
	v_fmac_f32_e64 v11, s88, v38
	v_fmac_f32_e64 v10, s73, v39
	v_fmac_f32_e64 v11, s89, v39
	v_fmac_f32_e64 v10, s74, v40
	v_fmac_f32_e64 v11, s90, v40
	v_fmac_f32_e64 v10, s75, v41
	v_fmac_f32_e64 v11, s91, v41
	v_fmac_f32_e64 v10, s76, v42
	v_fmac_f32_e64 v11, s92, v42
	v_fmac_f32_e64 v10, s77, v43
	v_fmac_f32_e64 v11, s93, v43
	v_fmac_f32_e64 v10, s78, v44
	v_fmac_f32_e64 v11, s94, v44
	v_fmac_f32_e64 v10, s79, v45
	v_fmac_f32_e64 v11, s95, v45
	s_load_dwordx16 s[64:79], s[96:97], 128
	s_load_dwordx16 s[80:95], s[98:99], 128
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(4)
	v_fmac_f32_e64 v12, s64, v60
	v_fmac_f32_e64 v13, s80, v60
	v_fmac_f32_e64 v12, s65, v61
	v_fmac_f32_e64 v13, s81, v61
	v_fmac_f32_e64 v12, s66, v62
	v_fmac_f32_e64 v13, s82, v62
	v_fmac_f32_e64 v12, s67, v63
	v_fmac_f32_e64 v13, s83, v63
	v_fmac_f32_e64 v12, s68, v64
	v_fmac_f32_e64 v13, s84, v64
	v_fmac_f32_e64 v12, s69, v65
	v_fmac_f32_e64 v13, s85, v65
	v_fmac_f32_e64 v12, s70, v66
	v_fmac_f32_e64 v13, s86, v66
	v_fmac_f32_e64 v12, s71, v67
	v_fmac_f32_e64 v13, s87, v67
	v_fmac_f32_e64 v12, s72, v68
	v_fmac_f32_e64 v13, s88, v68
	v_fmac_f32_e64 v12, s73, v69
	v_fmac_f32_e64 v13, s89, v69
	v_fmac_f32_e64 v12, s74, v70
	v_fmac_f32_e64 v13, s90, v70
	v_fmac_f32_e64 v12, s75, v71
	v_fmac_f32_e64 v13, s91, v71
	v_fmac_f32_e64 v12, s76, v72
	v_fmac_f32_e64 v13, s92, v72
	v_fmac_f32_e64 v12, s77, v73
	v_fmac_f32_e64 v13, s93, v73
	v_fmac_f32_e64 v12, s78, v74
	v_fmac_f32_e64 v13, s94, v74
	v_fmac_f32_e64 v12, s79, v75
	v_fmac_f32_e64 v13, s95, v75
	s_load_dwordx16 s[64:79], s[100:101], 128
	s_load_dwordx16 s[80:95], s[62:63], 128
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e64 v10, s64, v60
	v_fmac_f32_e64 v11, s80, v60
	v_fmac_f32_e64 v10, s65, v61
	v_fmac_f32_e64 v11, s81, v61
	v_fmac_f32_e64 v10, s66, v62
	v_fmac_f32_e64 v11, s82, v62
	v_fmac_f32_e64 v10, s67, v63
	v_fmac_f32_e64 v11, s83, v63
	v_fmac_f32_e64 v10, s68, v64
	v_fmac_f32_e64 v11, s84, v64
	v_fmac_f32_e64 v10, s69, v65
	v_fmac_f32_e64 v11, s85, v65
	v_fmac_f32_e64 v10, s70, v66
	v_fmac_f32_e64 v11, s86, v66
	v_fmac_f32_e64 v10, s71, v67
	v_fmac_f32_e64 v11, s87, v67
	v_fmac_f32_e64 v10, s72, v68
	v_fmac_f32_e64 v11, s88, v68
	v_fmac_f32_e64 v10, s73, v69
	v_fmac_f32_e64 v11, s89, v69
	v_fmac_f32_e64 v10, s74, v70
	v_fmac_f32_e64 v11, s90, v70
	v_fmac_f32_e64 v10, s75, v71
	v_fmac_f32_e64 v11, s91, v71
	v_fmac_f32_e64 v10, s76, v72
	v_fmac_f32_e64 v11, s92, v72
	v_fmac_f32_e64 v10, s77, v73
	v_fmac_f32_e64 v11, s93, v73
	v_fmac_f32_e64 v10, s78, v74
	v_fmac_f32_e64 v11, s94, v74
	v_fmac_f32_e64 v10, s79, v75
	v_fmac_f32_e64 v11, s95, v75
	s_load_dwordx16 s[64:79], s[96:97], 192
	s_load_dwordx16 s[80:95], s[98:99], 192
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(0)
	v_fmac_f32_e64 v12, s64, v76
	v_fmac_f32_e64 v13, s80, v76
	v_fmac_f32_e64 v12, s65, v77
	v_fmac_f32_e64 v13, s81, v77
	v_fmac_f32_e64 v12, s66, v78
	v_fmac_f32_e64 v13, s82, v78
	v_fmac_f32_e64 v12, s67, v79
	v_fmac_f32_e64 v13, s83, v79
	v_fmac_f32_e64 v12, s68, v80
	v_fmac_f32_e64 v13, s84, v80
	v_fmac_f32_e64 v12, s69, v81
	v_fmac_f32_e64 v13, s85, v81
	v_fmac_f32_e64 v12, s70, v82
	v_fmac_f32_e64 v13, s86, v82
	v_fmac_f32_e64 v12, s71, v83
	v_fmac_f32_e64 v13, s87, v83
	v_fmac_f32_e64 v12, s72, v84
	v_fmac_f32_e64 v13, s88, v84
	v_fmac_f32_e64 v12, s73, v85
	v_fmac_f32_e64 v13, s89, v85
	v_fmac_f32_e64 v12, s74, v86
	v_fmac_f32_e64 v13, s90, v86
	v_fmac_f32_e64 v12, s75, v87
	v_fmac_f32_e64 v13, s91, v87
	v_fmac_f32_e64 v12, s76, v88
	v_fmac_f32_e64 v13, s92, v88
	v_fmac_f32_e64 v12, s77, v89
	v_fmac_f32_e64 v13, s93, v89
	v_fmac_f32_e64 v12, s78, v90
	v_fmac_f32_e64 v13, s94, v90
	v_fmac_f32_e64 v12, s79, v91
	v_fmac_f32_e64 v13, s95, v91
	s_load_dwordx16 s[64:79], s[100:101], 192
	s_load_dwordx16 s[80:95], s[62:63], 192
	s_add_u32 s8, s8, 256
	s_addc_u32 s9, s9, 0
	s_add_i32 s61, s61, 16
	s_waitcnt lgkmcnt(0)
	v_fmac_f32_e64 v10, s64, v76
	v_fmac_f32_e64 v11, s80, v76
	v_fmac_f32_e64 v10, s65, v77
	v_fmac_f32_e64 v11, s81, v77
	v_fmac_f32_e64 v10, s66, v78
	v_fmac_f32_e64 v11, s82, v78
	v_fmac_f32_e64 v10, s67, v79
	v_fmac_f32_e64 v11, s83, v79
	v_fmac_f32_e64 v10, s68, v80
	v_fmac_f32_e64 v11, s84, v80
	v_fmac_f32_e64 v10, s69, v81
	v_fmac_f32_e64 v11, s85, v81
	v_fmac_f32_e64 v10, s70, v82
	v_fmac_f32_e64 v11, s86, v82
	v_fmac_f32_e64 v10, s71, v83
	v_fmac_f32_e64 v11, s87, v83
	v_fmac_f32_e64 v10, s72, v84
	v_fmac_f32_e64 v11, s88, v84
	v_fmac_f32_e64 v10, s73, v85
	v_fmac_f32_e64 v11, s89, v85
	v_fmac_f32_e64 v10, s74, v86
	v_fmac_f32_e64 v11, s90, v86
	v_fmac_f32_e64 v10, s75, v87
	v_fmac_f32_e64 v11, s91, v87
	v_fmac_f32_e64 v10, s76, v88
	v_fmac_f32_e64 v11, s92, v88
	v_fmac_f32_e64 v10, s77, v89
	v_fmac_f32_e64 v11, s93, v89
	v_fmac_f32_e64 v10, s78, v90
	v_fmac_f32_e64 v11, s94, v90
	v_fmac_f32_e64 v10, s79, v91
	v_fmac_f32_e64 v11, s95, v91
	s_cmpk_lt_u32 s61, 0x8c
	s_cbranch_scc1 .LBB0_7
.Lft3:
	v_pk_mul_f32 v[4:5], v[10:11], s[26:27]
	v_pk_mul_f32 v[2:3], v[12:13], s[24:25]
.LBB0_9:
	s_or_b64 exec, exec, s[10:11]
	v_add_u32_e32 v6, v51, v50
	ds_write_b128 v117, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], s[2:3]
	s_cbranch_execz .LBB0_11
.Lft4:
	ds_read_b32 v7, v54
	ds_read2_b32 v[8:9], v6 offset0:4 offset1:8
	ds_read2_b32 v[10:11], v6 offset0:12 offset1:16
	ds_read2_b32 v[12:13], v6 offset0:20 offset1:24
	ds_read2_b32 v[14:15], v6 offset0:28 offset1:32
	ds_read2_b32 v[16:17], v6 offset0:36 offset1:40
	ds_read_b32 v20, v6 offset:496
	s_waitcnt lgkmcnt(5)
	v_max_f32_e32 v7, v7, v8
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v7, v7, v9, v10
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v7, v7, v11, v12
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v7, v7, v13, v14
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v7, v7, v15, v16
	ds_read2_b32 v[8:9], v6 offset0:44 offset1:48
	ds_read2_b32 v[10:11], v6 offset0:52 offset1:56
	ds_read2_b32 v[12:13], v6 offset0:60 offset1:64
	ds_read2_b32 v[14:15], v6 offset0:68 offset1:72
	ds_read2_b32 v[18:19], v6 offset0:76 offset1:80
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v7, v7, v17, v8
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v7, v7, v9, v10
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v7, v7, v11, v12
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v7, v7, v13, v14
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v7, v7, v15, v18
	ds_read2_b32 v[8:9], v6 offset0:84 offset1:88
	ds_read2_b32 v[10:11], v6 offset0:92 offset1:96
	ds_read2_b32 v[12:13], v6 offset0:100 offset1:104
	ds_read2_b32 v[14:15], v6 offset0:108 offset1:112
	ds_read2_b32 v[16:17], v6 offset0:116 offset1:120
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v7, v7, v19, v8
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v7, v7, v9, v10
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v7, v7, v11, v12
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v7, v7, v13, v14
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v7, v7, v15, v16
	v_max3_f32 v7, v7, v17, v20
	ds_write_b32 v55, v7
.LBB0_11:
	s_or_b64 exec, exec, s[8:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB0_13
.Lft5:
	ds_read_b128 v[8:11], v122
	ds_read_b128 v[12:15], v122 offset:16
	ds_read_b128 v[16:19], v122 offset:32
	ds_read_b128 v[20:23], v122 offset:48
	ds_read_b128 v[24:27], v122 offset:64
	s_waitcnt lgkmcnt(4)
	v_max3_f32 v7, v8, v9, v10
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v7, v7, v11, v12
	v_max3_f32 v7, v7, v13, v14
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v7, v7, v15, v16
	v_max3_f32 v7, v7, v17, v18
	ds_read_b128 v[8:11], v122 offset:80
	ds_read_b128 v[12:15], v122 offset:96
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v7, v7, v19, v20
	v_max3_f32 v7, v7, v21, v22
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v7, v7, v23, v24
	v_max3_f32 v7, v7, v25, v26
	ds_read_b128 v[16:19], v122 offset:112
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v7, v7, v27, v8
	v_max3_f32 v7, v7, v9, v10
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v7, v7, v11, v12
	v_max3_f32 v7, v7, v13, v14
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v7, v7, v15, v16
	v_max3_f32 v7, v7, v17, v18
	s_waitcnt vmcnt(1)
	v_max3_f32 v7, v103, v7, v19
	v_sub_f32_e32 v8, v103, v7
	v_add_f32_e32 v9, 0x42800000, v8
	v_cmp_gt_f32_e64 s[8:9], s51, v8
	v_mov_b32_e32 v103, v7
	s_nop 0
	v_cndmask_b32_e64 v8, v8, v9, s[8:9]
	v_mul_f32_e32 v8, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v8
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v9, 0x9210, v1
	ds_write_b32 v9, v7
	v_mul_f32_e32 v9, 0x114b4ea4, v8
	v_cndmask_b32_e64 v8, v8, v9, s[8:9]
	ds_write_b32 v56, v8
.LBB0_13:
	s_or_b64 exec, exec, s[10:11]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_xor_b64 s[8:9], exec, s[8:9]
	ds_write_b32 v117, v59
	s_or_saveexec_b64 s[38:39], s[8:9]
	v_mov_b32_e32 v7, 0
	s_xor_b64 exec, exec, s[38:39]
	s_cbranch_execz .LBB0_17
.Lft6:
	ds_read_b64 v[8:9], v59 offset:37392
	s_waitcnt lgkmcnt(0)
	v_sub_f32_e32 v2, v2, v8
	v_add_f32_e32 v7, 0x42800000, v2
	v_cmp_gt_f32_e64 s[8:9], s51, v2
	v_sub_f32_e32 v3, v3, v9
	v_add_f32_e32 v8, 0x42800000, v3
	v_cndmask_b32_e64 v2, v2, v7, s[8:9]
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e64 s[10:11], s51, v3
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v8, s[10:11]
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v3
	v_mul_f32_e32 v7, 0x114b4ea4, v2
	v_cndmask_b32_e64 v2, v2, v7, s[8:9]
	ds_write_b32 v117, v2
	v_mul_f32_e32 v2, 0x114b4ea4, v3
	v_cndmask_b32_e64 v7, v3, v2, s[10:11]
.LBB0_17:
	s_or_b64 exec, exec, s[38:39]
	ds_write_b32 v117, v7 offset:4
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_xor_b64 s[6:7], exec, s[8:9]
	ds_write_b32 v117, v59 offset:8
	s_or_saveexec_b64 s[10:11], s[6:7]
	v_mov_b32_e32 v2, 0
	s_xor_b64 exec, exec, s[10:11]
	s_cbranch_execz .LBB0_21
.Lft7:
	ds_read_b64 v[2:3], v59 offset:37400
	s_waitcnt lgkmcnt(0)
	v_sub_f32_e32 v2, v4, v2
	v_add_f32_e32 v4, 0x42800000, v2
	v_cmp_gt_f32_e64 s[6:7], s51, v2
	v_sub_f32_e32 v3, v5, v3
	v_add_f32_e32 v5, 0x42800000, v3
	v_cndmask_b32_e64 v2, v2, v4, s[6:7]
	v_mul_f32_e32 v2, 0x3fb8aa3b, v2
	v_cmp_gt_f32_e64 s[8:9], s51, v3
	v_exp_f32_e32 v2, v2
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v5, s[8:9]
	v_mul_f32_e32 v3, 0x3fb8aa3b, v3
	v_exp_f32_e32 v3, v3
	v_mul_f32_e32 v4, 0x114b4ea4, v2
	v_cndmask_b32_e64 v2, v2, v4, s[6:7]
	ds_write_b32 v117, v2 offset:8
	v_mul_f32_e32 v2, 0x114b4ea4, v3
	v_cndmask_b32_e64 v2, v3, v2, s[8:9]
.LBB0_21:
	s_or_b64 exec, exec, s[10:11]
	ds_write_b32 v117, v2 offset:12
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[2:3]
	s_cbranch_execz .LBB0_23
.Lft8:
	ds_read_b32 v7, v54
	ds_read2_b32 v[2:3], v6 offset0:4 offset1:8
	ds_read2_b32 v[4:5], v6 offset0:12 offset1:16
	ds_read2_b32 v[8:9], v6 offset0:20 offset1:24
	ds_read_b32 v10, v6 offset:496
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v2, v2, v7
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, v4, v2
	ds_read2_b32 v[2:3], v6 offset0:28 offset1:32
	v_add_f32_e32 v4, v5, v4
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v7, v8, v4
	ds_read2_b32 v[4:5], v6 offset0:36 offset1:40
	v_add_f32_e32 v7, v9, v7
	ds_read2_b32 v[8:9], v6 offset0:44 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v2, v7
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v2
	ds_read2_b32 v[2:3], v6 offset0:52 offset1:56
	v_add_f32_e32 v4, v5, v4
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v7, v8, v4
	ds_read2_b32 v[4:5], v6 offset0:60 offset1:64
	v_add_f32_e32 v7, v9, v7
	ds_read2_b32 v[8:9], v6 offset0:68 offset1:72
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v2, v7
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v4, v2
	ds_read2_b32 v[2:3], v6 offset0:76 offset1:80
	v_add_f32_e32 v4, v5, v4
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v7, v8, v4
	ds_read2_b32 v[4:5], v6 offset0:84 offset1:88
	v_add_f32_e32 v7, v9, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v7
	ds_read2_b32 v[8:9], v6 offset0:92 offset1:96
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	v_add_f32_e32 v4, v5, v2
	ds_read2_b32 v[2:3], v6 offset0:100 offset1:104
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v7, v8, v4
	ds_read2_b32 v[4:5], v6 offset0:108 offset1:112
	v_add_f32_e32 v8, v9, v7
	ds_read2_b32 v[6:7], v6 offset0:116 offset1:120
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v2, v8
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	v_add_f32_e32 v2, v5, v2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v2, v7, v2
	v_add_f32_e32 v2, v10, v2
	ds_write_b32 v55, v2
.LBB0_23:
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_cbranch_execz .LBB0_25
.Lft9:
	ds_read_b128 v[2:5], v122
	ds_read_b128 v[6:9], v122 offset:16
	ds_read_b128 v[10:13], v122 offset:32
	ds_read_b128 v[14:17], v122 offset:48
	ds_read_b128 v[18:21], v122 offset:80
	ds_read_b128 v[22:25], v122 offset:64
	ds_read_b128 v[26:29], v122 offset:96
	ds_read_b128 v[30:33], v122 offset:112
	ds_read_b32 v34, v56
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
	s_waitcnt vmcnt(2) lgkmcnt(0)
	v_fmac_f32_e32 v2, v34, v57
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v3, 0x9200, v1
	v_mov_b32_e32 v57, v2
	ds_write_b32 v3, v2
.LBB0_25:
	s_or_b64 exec, exec, s[6:7]
	s_sub_i32 s6, s17, s60
	v_or_b32_e32 v2, s60, v116
	s_min_i32 s61, s6, 0x400
	v_mad_u64_u32 v[20:21], s[6:7], v2, s40, v[106:107]
	v_or_b32_e32 v2, 0xf0, v116
	v_cmp_gt_i32_e64 s[6:7], s61, v2
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v43, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v18, v116
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_cbranch_execz .LBB0_29
.Lft10:
	v_mov_b32_e32 v43, 0
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v1, v50
	s_mov_b64 s[10:11], 0
	s_mov_b32 s62, 0xfffc0ff4
	s_mov_b32 s63, -1
	v_lshl_add_u64 v[60:61], v[110:111], 0, s[62:63]
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v16, 0
	v_lshlrev_b32_e32 v58, 4, v116
	v_mov_b32_e32 v123, v116
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v45, 0
	v_mov_b32_e32 v3, v43
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v49, 0
	v_mov_b32_e32 v7, v43
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v11, v43
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v15, v43
	scratch_store_dword off, v103, off offset:20
	scratch_store_dword off, v57, off offset:16
	scratch_store_dwordx2 off, v[108:109], off
	scratch_store_dwordx2 off, v[110:111], off offset:8
.LBB0_27:
	global_load_dwordx4 v[22:25], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[26:29], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[30:33], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[34:37], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[38:41], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[42:45], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[62:65], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[66:69], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[70:73], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[74:77], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[46:49], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[50:53], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[78:81], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[82:85], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[86:89], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	global_load_dwordx4 v[54:57], v[60:61], off
	v_lshl_add_u64 v[60:61], v[60:61], 0, s[30:31]
	ds_read_b128 v[90:93], v58 offset:0
	ds_read_b128 v[94:97], v58 offset:256
	ds_read_b128 v[98:101], v58 offset:512
	ds_read_b128 v[102:105], v58 offset:768
	ds_read_b128 v[106:109], v58 offset:1024
	ds_read_b128 v[110:113], v58 offset:1280
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(12)
	v_pk_fma_f32 v[14:15], v[22:23], v[90:91], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[24:25], v[90:91], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[22:23], v[90:91], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[24:25], v[90:91], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[22:23], v[92:93], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[24:25], v[92:93], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[22:23], v[92:93], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[24:25], v[92:93], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[26:27], v[94:95], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[28:29], v[94:95], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[26:27], v[94:95], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[28:29], v[94:95], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[26:27], v[96:97], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[28:29], v[96:97], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[26:27], v[96:97], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[28:29], v[96:97], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[30:31], v[98:99], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[32:33], v[98:99], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[30:31], v[98:99], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[32:33], v[98:99], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[30:31], v[100:101], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[32:33], v[100:101], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[30:31], v[100:101], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[32:33], v[100:101], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[34:35], v[102:103], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[36:37], v[102:103], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[34:35], v[102:103], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[36:37], v[102:103], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[34:35], v[104:105], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[36:37], v[104:105], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[34:35], v[104:105], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[36:37], v[104:105], v[4:5] op_sel:[0,1,0]
	ds_read_b128 v[90:93], v58 offset:1536
	ds_read_b128 v[94:97], v58 offset:1792
	ds_read_b128 v[98:101], v58 offset:2048
	ds_read_b128 v[102:105], v58 offset:2304
	s_waitcnt lgkmcnt(4)
	s_waitcnt vmcnt(10)
	v_pk_fma_f32 v[14:15], v[38:39], v[106:107], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[40:41], v[106:107], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[38:39], v[106:107], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[40:41], v[106:107], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[38:39], v[108:109], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[40:41], v[108:109], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[38:39], v[108:109], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[40:41], v[108:109], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[42:43], v[110:111], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[44:45], v[110:111], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[42:43], v[110:111], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[44:45], v[110:111], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[42:43], v[112:113], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[44:45], v[112:113], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[42:43], v[112:113], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[44:45], v[112:113], v[4:5] op_sel:[0,1,0]
	ds_read_b128 v[106:109], v58 offset:2560
	ds_read_b128 v[110:113], v58 offset:2816
	s_waitcnt lgkmcnt(2)
	s_waitcnt vmcnt(6)
	v_pk_fma_f32 v[14:15], v[62:63], v[90:91], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[64:65], v[90:91], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[62:63], v[90:91], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[64:65], v[90:91], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[62:63], v[92:93], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[64:65], v[92:93], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[62:63], v[92:93], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[64:65], v[92:93], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[66:67], v[94:95], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[68:69], v[94:95], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[66:67], v[94:95], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[68:69], v[94:95], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[66:67], v[96:97], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[68:69], v[96:97], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[66:67], v[96:97], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[68:69], v[96:97], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[70:71], v[98:99], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[72:73], v[98:99], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[70:71], v[98:99], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[72:73], v[98:99], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[70:71], v[100:101], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[72:73], v[100:101], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[70:71], v[100:101], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[72:73], v[100:101], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[74:75], v[102:103], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[76:77], v[102:103], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[74:75], v[102:103], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[76:77], v[102:103], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[74:75], v[104:105], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[76:77], v[104:105], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[74:75], v[104:105], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[76:77], v[104:105], v[4:5] op_sel:[0,1,0]
	ds_read_b128 v[90:93], v58 offset:3072
	ds_read_b128 v[94:97], v58 offset:3328
	ds_read_b128 v[98:101], v58 offset:3584
	ds_read_b128 v[102:105], v58 offset:3840
	s_waitcnt lgkmcnt(4)
	s_waitcnt vmcnt(4)
	v_pk_fma_f32 v[14:15], v[46:47], v[106:107], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[48:49], v[106:107], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[46:47], v[106:107], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[48:49], v[106:107], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[46:47], v[108:109], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[48:49], v[108:109], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[46:47], v[108:109], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[48:49], v[108:109], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[50:51], v[110:111], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[52:53], v[110:111], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[50:51], v[110:111], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[52:53], v[110:111], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[50:51], v[112:113], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[52:53], v[112:113], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[50:51], v[112:113], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[52:53], v[112:113], v[4:5] op_sel:[0,1,0]
	s_waitcnt lgkmcnt(0)
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[14:15], v[78:79], v[90:91], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[80:81], v[90:91], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[78:79], v[90:91], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[80:81], v[90:91], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[78:79], v[92:93], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[80:81], v[92:93], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[78:79], v[92:93], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[80:81], v[92:93], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[82:83], v[94:95], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[84:85], v[94:95], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[82:83], v[94:95], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[84:85], v[94:95], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[82:83], v[96:97], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[84:85], v[96:97], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[82:83], v[96:97], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[84:85], v[96:97], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[86:87], v[98:99], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[88:89], v[98:99], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[86:87], v[98:99], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[88:89], v[98:99], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[86:87], v[100:101], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[88:89], v[100:101], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[86:87], v[100:101], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[88:89], v[100:101], v[4:5] op_sel:[0,1,0]
	v_pk_fma_f32 v[14:15], v[54:55], v[102:103], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[56:57], v[102:103], v[16:17] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[10:11], v[54:55], v[102:103], v[10:11] op_sel:[0,1,0]
	v_pk_fma_f32 v[12:13], v[56:57], v[102:103], v[12:13] op_sel:[0,1,0]
	v_pk_fma_f32 v[6:7], v[54:55], v[104:105], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[56:57], v[104:105], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[54:55], v[104:105], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[4:5], v[56:57], v[104:105], v[4:5] op_sel:[0,1,0]
	v_add_u32_e32 v19, 0x1f0, v116
	v_add_u32_e32 v18, 0x100, v116
	v_cmp_le_i32_e64 s[6:7], s61, v19
	v_add_u32_e32 v58, 0x1000, v58
	v_mov_b32_e32 v116, v18
	s_nop 0
	s_or_b64 s[10:11], s[6:7], s[10:11]
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB0_27
.Lft11:
	s_or_b64 exec, exec, s[10:11]
	scratch_load_dword v51, off, off offset:28
	scratch_load_dword v54, off, off offset:32
	scratch_load_dword v55, off, off offset:36
	scratch_load_dword v56, off, off offset:40
	scratch_load_dwordx2 v[106:107], off, off offset:44
	scratch_load_dwordx2 v[108:109], off, off
	scratch_load_dwordx2 v[110:111], off, off offset:8
	scratch_load_dword v57, off, off offset:16
	scratch_load_dword v103, off, off offset:20
	v_mov_b32_e32 v50, v1
	scratch_load_dword v1, off, off offset:24
	v_mov_b64_e32 v[20:21], v[60:61]
	v_mov_b32_e32 v45, v2
	v_mov_b32_e32 v43, v4
	v_mov_b32_e32 v49, v6
	v_mov_b32_e32 v47, v8
	v_mov_b32_e32 v69, v10
	v_mov_b32_e32 v67, v12
	v_mov_b32_e32 v77, v14
	v_mov_b32_e32 v71, v16
	v_mov_b32_e32 v116, v123
.LBB0_29:
	s_or_b64 exec, exec, s[8:9]
	v_mov_b32_e32 v2, v45
	v_mov_b32_e32 v4, v43
	v_mov_b32_e32 v6, v49
	v_mov_b32_e32 v8, v47
	v_mov_b32_e32 v10, v69
	v_mov_b32_e32 v12, v67
	v_mov_b32_e32 v14, v77
	v_mov_b32_e32 v16, v71
	v_cmp_gt_i32_e64 s[6:7], s61, v18
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_cbranch_execz .LBB0_39
.Lft12:
	s_lshl_b32 s6, s50, 10
	s_sub_i32 s6, s17, s6
	s_min_i32 s6, s6, 0x400
	v_xad_u32 v2, v18, -1, s6
	v_lshrrev_b32_e32 v44, 4, v2
	v_cmp_ne_u32_e64 s[6:7], 0, v44
	s_mov_b64 s[38:39], -1
	s_and_saveexec_b64 s[10:11], s[6:7]
	s_cbranch_execz .LBB0_34
.Lft13:
	s_min_i32 s6, s59, 0x400
	v_xad_u32 v36, v18, -1, s6
	v_lshrrev_b32_e32 v36, 4, v36
	v_mov_b32_e32 v58, v77
	v_add_u32_e32 v19, 16, v18
	v_add_u32_e32 v36, 1, v36
	v_mov_b32_e32 v14, v15
	v_mov_b32_e32 v15, v59
	v_mov_b32_e32 v22, v71
	v_mov_b32_e32 v23, v59
	v_mov_b32_e32 v16, v17
	v_mov_b32_e32 v17, v59
	v_mov_b32_e32 v24, v69
	v_mov_b32_e32 v25, v59
	v_mov_b32_e32 v10, v11
	v_mov_b32_e32 v11, v59
	v_mov_b32_e32 v26, v67
	v_mov_b32_e32 v27, v59
	v_mov_b32_e32 v12, v13
	v_mov_b32_e32 v13, v59
	v_mov_b32_e32 v28, v49
	v_mov_b32_e32 v29, v59
	v_mov_b32_e32 v6, v7
	v_mov_b32_e32 v7, v59
	v_mov_b32_e32 v30, v47
	v_mov_b32_e32 v31, v59
	v_mov_b32_e32 v8, v9
	v_mov_b32_e32 v9, v59
	v_mov_b32_e32 v32, v45
	v_mov_b32_e32 v33, v59
	v_mov_b32_e32 v2, v3
	v_mov_b32_e32 v3, v59
	v_mov_b32_e32 v34, v43
	v_mov_b32_e32 v35, v59
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v5, v59
	v_and_b32_e32 v36, 0x1ffffffe, v36
	v_mov_b32_e32 v37, v59
	v_lshl_add_u64 v[38:39], v[20:21], 0, s[30:31]
	s_mov_b64 s[38:39], 0
	v_mov_b64_e32 v[40:41], v[58:59]
	v_mov_b64_e32 v[42:43], v[18:19]
	.p2align	5, , 4
.LBB0_32:
	v_add_co_u32_e64 v60, s[6:7], s58, v38
	global_load_dwordx4 v[46:49], v[38:39], off
	s_nop 0
	v_addc_co_u32_e64 v61, s[6:7], -1, v39, s[6:7]
	global_load_dwordx4 v[72:75], v[60:61], off
	v_lshlrev_b32_e32 v45, 4, v42
	v_lshlrev_b32_e32 v19, 4, v43
	ds_read_b128 v[66:69], v45
	ds_read_b128 v[60:63], v19
	v_lshl_add_u64 v[36:37], v[36:37], 0, -2
	v_cmp_eq_u64_e64 s[6:7], 0, v[36:37]
	v_add_u32_e32 v43, 32, v43
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v64, v66
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v65, v60
	v_mov_b32_e32 v60, v67
	v_mov_b32_e32 v66, v68
	v_mov_b32_e32 v67, v62
	v_mov_b32_e32 v62, v69
	v_add_u32_e32 v42, 32, v42
	v_lshl_add_u64 v[38:39], v[38:39], 0, s[34:35]
	s_or_b64 s[38:39], s[6:7], s[38:39]
	s_waitcnt vmcnt(1)
	v_mov_b32_e32 v69, v46
	v_mov_b32_e32 v71, v48
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v68, v72
	v_mov_b32_e32 v46, v73
	v_mov_b32_e32 v70, v74
	v_mov_b32_e32 v48, v75
	v_pk_fma_f32 v[40:41], v[64:65], v[68:69], v[40:41]
	v_pk_fma_f32 v[14:15], v[64:65], v[46:47], v[14:15]
	v_pk_fma_f32 v[22:23], v[64:65], v[70:71], v[22:23]
	v_pk_fma_f32 v[16:17], v[64:65], v[48:49], v[16:17]
	v_pk_fma_f32 v[24:25], v[60:61], v[68:69], v[24:25]
	v_pk_fma_f32 v[10:11], v[60:61], v[46:47], v[10:11]
	v_pk_fma_f32 v[26:27], v[60:61], v[70:71], v[26:27]
	v_pk_fma_f32 v[12:13], v[60:61], v[48:49], v[12:13]
	v_pk_fma_f32 v[28:29], v[66:67], v[68:69], v[28:29]
	v_pk_fma_f32 v[6:7], v[66:67], v[46:47], v[6:7]
	v_pk_fma_f32 v[30:31], v[66:67], v[70:71], v[30:31]
	v_pk_fma_f32 v[8:9], v[66:67], v[48:49], v[8:9]
	v_pk_fma_f32 v[32:33], v[62:63], v[68:69], v[32:33]
	v_pk_fma_f32 v[2:3], v[62:63], v[46:47], v[2:3]
	v_pk_fma_f32 v[34:35], v[62:63], v[70:71], v[34:35]
	v_pk_fma_f32 v[4:5], v[62:63], v[48:49], v[4:5]
	s_andn2_b64 exec, exec, s[38:39]
	s_cbranch_execnz .LBB0_32
.Lft14:
	s_or_b64 exec, exec, s[38:39]
	v_add_u32_e32 v58, 1, v44
	v_and_b32_e32 v42, 0x1ffffffe, v58
	v_mov_b32_e32 v43, v59
	v_mad_u64_u32 v[20:21], s[6:7], v42, s49, v[20:21]
	v_pk_add_f32 v[38:39], v[40:41], v[40:41] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[14:15], v[14:15], v[14:15] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[60:61], v[22:23], v[22:23] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[16:17], v[16:17], v[16:17] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[36:37], v[24:25], v[24:25] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[10:11], v[10:11], v[10:11] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[40:41], v[26:27], v[26:27] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[12:13], v[12:13], v[12:13] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[24:25], v[28:29], v[28:29] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[6:7], v[6:7], v[6:7] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[28:29], v[30:31], v[30:31] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[8:9], v[8:9], v[8:9] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[22:23], v[32:33], v[32:33] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[2:3], v[2:3], v[2:3] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[26:27], v[34:35], v[34:35] op_sel:[0,1] op_sel_hi:[1,0]
	v_pk_add_f32 v[4:5], v[4:5], v[4:5] op_sel:[0,1] op_sel_hi:[1,0]
	v_cmp_ne_u64_e64 s[6:7], v[42:43], v[58:59]
	v_lshl_add_u32 v18, v42, 4, v18
	v_mov_b32_e32 v23, v2
	v_mov_b32_e32 v27, v4
	v_mov_b32_e32 v25, v6
	v_mov_b32_e32 v29, v8
	v_mov_b32_e32 v37, v10
	v_mov_b32_e32 v41, v12
	v_mov_b32_e32 v39, v14
	v_mov_b32_e32 v61, v16
	s_orn2_b64 s[38:39], s[6:7], exec
	v_mov_b32_e32 v3, v2
	v_mov_b32_e32 v45, v22
	v_mov_b32_e32 v5, v4
	v_mov_b32_e32 v43, v26
	v_mov_b32_e32 v7, v6
	v_mov_b32_e32 v49, v24
	v_mov_b32_e32 v9, v8
	v_mov_b32_e32 v47, v28
	v_mov_b32_e32 v11, v10
	v_mov_b32_e32 v69, v36
	v_mov_b32_e32 v13, v12
	v_mov_b32_e32 v67, v40
	v_mov_b32_e32 v15, v14
	v_mov_b32_e32 v77, v38
	v_mov_b32_e32 v17, v16
	v_mov_b32_e32 v71, v60
.LBB0_34:
	s_or_b64 exec, exec, s[10:11]
	s_and_saveexec_b64 s[10:11], s[38:39]
	s_cbranch_execz .LBB0_38
.Lft15:
	v_lshlrev_b32_e32 v19, 4, v18
	v_lshl_add_u64 v[20:21], v[20:21], 0, 8
	s_mov_b64 s[38:39], 0
	v_mov_b32_e32 v16, v71
	v_mov_b32_e32 v14, v77
	v_mov_b32_e32 v12, v67
	v_mov_b32_e32 v10, v69
	v_mov_b32_e32 v8, v47
	v_mov_b32_e32 v6, v49
	v_mov_b32_e32 v4, v43
	v_mov_b32_e32 v2, v45
	.p2align	5, , 4
.LBB0_36:
	global_load_dwordx4 v[22:25], v[20:21], off offset:-8
	ds_read_b128 v[26:29], v19
	v_add_u32_e32 v18, 16, v18
	v_cmp_le_i32_e64 s[6:7], s61, v18
	v_add_u32_e32 v19, 0x100, v19
	v_lshl_add_u64 v[20:21], v[20:21], 0, s[30:31]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v30, v29
	s_or_b64 s[38:39], s[6:7], s[38:39]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[14:15], v[26:27], v[22:23], v[14:15] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[10:11], v[26:27], v[22:23], v[10:11] op_sel:[1,0,0]
	v_pk_fma_f32 v[6:7], v[28:29], v[22:23], v[6:7] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[2:3], v[30:31], v[22:23], v[2:3] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[16:17], v[26:27], v[24:25], v[16:17] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[12:13], v[26:27], v[24:25], v[12:13] op_sel:[1,0,0]
	v_pk_fma_f32 v[8:9], v[28:29], v[24:25], v[8:9] op_sel_hi:[0,1,1]
	v_pk_fma_f32 v[4:5], v[30:31], v[24:25], v[4:5] op_sel_hi:[0,1,1]
	s_andn2_b64 exec, exec, s[38:39]
	s_cbranch_execnz .LBB0_36
.Lft16:
	s_or_b64 exec, exec, s[38:39]
	v_mov_b64_e32 v[22:23], v[2:3]
	v_mov_b64_e32 v[26:27], v[4:5]
	v_mov_b64_e32 v[24:25], v[6:7]
	v_mov_b64_e32 v[28:29], v[8:9]
	v_mov_b64_e32 v[36:37], v[10:11]
	v_mov_b64_e32 v[40:41], v[12:13]
	v_mov_b64_e32 v[38:39], v[14:15]
	v_mov_b64_e32 v[60:61], v[16:17]
.LBB0_38:
	s_or_b64 exec, exec, s[10:11]
	v_mov_b64_e32 v[16:17], v[60:61]
	v_mov_b64_e32 v[14:15], v[38:39]
	v_mov_b64_e32 v[12:13], v[40:41]
	v_mov_b64_e32 v[10:11], v[36:37]
	v_mov_b64_e32 v[8:9], v[28:29]
	v_mov_b64_e32 v[6:7], v[24:25]
	v_mov_b64_e32 v[4:5], v[26:27]
	v_mov_b64_e32 v[2:3], v[22:23]
.LBB0_39:
	s_or_b64 exec, exec, s[8:9]
	ds_write_b128 v124, v[14:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_41
.Lft17:
	ds_read_b128 v[14:17], v124
	ds_read_b128 v[18:21], v124 offset:1024
	ds_read_b128 v[22:25], v124 offset:2048
	ds_read_b128 v[26:29], v124 offset:3072
	ds_read_b128 v[30:33], v124 offset:4096
	ds_read_b128 v[34:37], v124 offset:5120
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[14:15], v[18:19], v[14:15]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[14:15], v[22:23], v[14:15]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[14:15], v[26:27], v[14:15]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[14:15], v[30:31], v[14:15]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[22:23], v[34:35], v[14:15]
	v_pk_add_f32 v[14:15], v[20:21], v[16:17]
	s_nop 0
	v_pk_add_f32 v[18:19], v[24:25], v[14:15]
	ds_read_b128 v[14:17], v124 offset:6144
	v_pk_add_f32 v[18:19], v[28:29], v[18:19]
	s_nop 0
	v_pk_add_f32 v[18:19], v[32:33], v[18:19]
	s_nop 0
	v_pk_add_f32 v[52:53], v[36:37], v[18:19]
	ds_read_b128 v[18:21], v124 offset:7168
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[14:15], v[14:15], v[22:23]
	ds_read_b128 v[22:25], v124 offset:8192
	ds_read_b128 v[26:29], v124 offset:9216
	ds_read_b128 v[30:33], v124 offset:10240
	ds_read_b128 v[34:37], v124 offset:11264
	v_pk_add_f32 v[16:17], v[16:17], v[52:53]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[14:15], v[18:19], v[14:15]
	v_pk_add_f32 v[16:17], v[20:21], v[16:17]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[14:15], v[22:23], v[14:15]
	v_pk_add_f32 v[16:17], v[24:25], v[16:17]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[14:15], v[26:27], v[14:15]
	v_pk_add_f32 v[16:17], v[28:29], v[16:17]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[14:15], v[30:31], v[14:15]
	v_pk_add_f32 v[16:17], v[32:33], v[16:17]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[14:15], v[34:35], v[14:15]
	ds_read_b128 v[38:41], v124 offset:12288
	ds_read_b128 v[42:45], v124 offset:13312
	ds_read_b128 v[46:49], v124 offset:14336
	ds_read_b128 v[60:63], v124 offset:15360
	ds_read_b32 v18, v59 offset:37408
	ds_read_b128 v[64:67], v125
	v_pk_add_f32 v[16:17], v[36:37], v[16:17]
	s_waitcnt lgkmcnt(5)
	v_pk_add_f32 v[14:15], v[38:39], v[14:15]
	v_pk_add_f32 v[16:17], v[40:41], v[16:17]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[14:15], v[42:43], v[14:15]
	v_pk_add_f32 v[16:17], v[44:45], v[16:17]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[14:15], v[46:47], v[14:15]
	v_pk_add_f32 v[16:17], v[48:49], v[16:17]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[14:15], v[60:61], v[14:15]
	v_pk_add_f32 v[16:17], v[62:63], v[16:17]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[14:15], v[64:65], v[18:19], v[14:15] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[16:17], v[66:67], v[18:19], v[16:17] op_sel_hi:[1,0,1]
	ds_write_b128 v125, v[14:17]
.LBB0_41:
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v124, v[10:13]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_43
.Lft18:
	ds_read_b128 v[10:13], v124
	ds_read_b128 v[14:17], v124 offset:1024
	ds_read_b128 v[18:21], v124 offset:2048
	ds_read_b128 v[22:25], v124 offset:3072
	ds_read_b128 v[26:29], v124 offset:4096
	ds_read_b128 v[30:33], v124 offset:5120
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[10:11], v[14:15], v[10:11]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[10:11], v[18:19], v[10:11]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[10:11], v[22:23], v[10:11]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[10:11], v[26:27], v[10:11]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[18:19], v[30:31], v[10:11]
	v_pk_add_f32 v[10:11], v[16:17], v[12:13]
	s_nop 0
	v_pk_add_f32 v[14:15], v[20:21], v[10:11]
	ds_read_b128 v[10:13], v124 offset:6144
	v_pk_add_f32 v[14:15], v[24:25], v[14:15]
	s_nop 0
	v_pk_add_f32 v[14:15], v[28:29], v[14:15]
	s_nop 0
	v_pk_add_f32 v[52:53], v[32:33], v[14:15]
	ds_read_b128 v[14:17], v124 offset:7168
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[10:11], v[10:11], v[18:19]
	ds_read_b128 v[18:21], v124 offset:8192
	ds_read_b128 v[22:25], v124 offset:9216
	ds_read_b128 v[26:29], v124 offset:10240
	ds_read_b128 v[30:33], v124 offset:11264
	v_pk_add_f32 v[12:13], v[12:13], v[52:53]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[10:11], v[14:15], v[10:11]
	v_pk_add_f32 v[12:13], v[16:17], v[12:13]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[10:11], v[18:19], v[10:11]
	v_pk_add_f32 v[12:13], v[20:21], v[12:13]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[10:11], v[22:23], v[10:11]
	v_pk_add_f32 v[12:13], v[24:25], v[12:13]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[10:11], v[26:27], v[10:11]
	v_pk_add_f32 v[12:13], v[28:29], v[12:13]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[10:11], v[30:31], v[10:11]
	ds_read_b128 v[34:37], v124 offset:12288
	ds_read_b128 v[38:41], v124 offset:13312
	ds_read_b128 v[42:45], v124 offset:14336
	ds_read_b128 v[46:49], v124 offset:15360
	ds_read_b32 v14, v59 offset:37412
	ds_read_b128 v[60:63], v125 offset:1024
	v_pk_add_f32 v[12:13], v[32:33], v[12:13]
	s_waitcnt lgkmcnt(5)
	v_pk_add_f32 v[10:11], v[34:35], v[10:11]
	v_pk_add_f32 v[12:13], v[36:37], v[12:13]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[10:11], v[38:39], v[10:11]
	v_pk_add_f32 v[12:13], v[40:41], v[12:13]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[10:11], v[42:43], v[10:11]
	v_pk_add_f32 v[12:13], v[44:45], v[12:13]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[10:11], v[46:47], v[10:11]
	v_pk_add_f32 v[12:13], v[48:49], v[12:13]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[10:11], v[60:61], v[14:15], v[10:11] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[12:13], v[62:63], v[14:15], v[12:13] op_sel_hi:[1,0,1]
	ds_write_b128 v125, v[10:13] offset:1024
.LBB0_43:
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v124, v[6:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_45
.Lft19:
	ds_read_b128 v[6:9], v124
	ds_read_b128 v[10:13], v124 offset:1024
	ds_read_b128 v[14:17], v124 offset:2048
	ds_read_b128 v[18:21], v124 offset:3072
	ds_read_b128 v[22:25], v124 offset:4096
	ds_read_b128 v[26:29], v124 offset:5120
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[10:11], v[6:7]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[14:15], v[6:7]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[18:19], v[6:7]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[6:7], v[22:23], v[6:7]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[14:15], v[26:27], v[6:7]
	v_pk_add_f32 v[6:7], v[12:13], v[8:9]
	s_nop 0
	v_pk_add_f32 v[10:11], v[16:17], v[6:7]
	ds_read_b128 v[6:9], v124 offset:6144
	v_pk_add_f32 v[10:11], v[20:21], v[10:11]
	s_nop 0
	v_pk_add_f32 v[10:11], v[24:25], v[10:11]
	s_nop 0
	v_pk_add_f32 v[52:53], v[28:29], v[10:11]
	ds_read_b128 v[10:13], v124 offset:7168
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[6:7], v[6:7], v[14:15]
	ds_read_b128 v[14:17], v124 offset:8192
	ds_read_b128 v[18:21], v124 offset:9216
	ds_read_b128 v[22:25], v124 offset:10240
	ds_read_b128 v[26:29], v124 offset:11264
	v_pk_add_f32 v[8:9], v[8:9], v[52:53]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[10:11], v[6:7]
	v_pk_add_f32 v[8:9], v[12:13], v[8:9]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[14:15], v[6:7]
	v_pk_add_f32 v[8:9], v[16:17], v[8:9]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[18:19], v[6:7]
	v_pk_add_f32 v[8:9], v[20:21], v[8:9]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[6:7], v[22:23], v[6:7]
	v_pk_add_f32 v[8:9], v[24:25], v[8:9]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[6:7], v[26:27], v[6:7]
	ds_read_b128 v[30:33], v124 offset:12288
	ds_read_b128 v[34:37], v124 offset:13312
	ds_read_b128 v[38:41], v124 offset:14336
	ds_read_b128 v[42:45], v124 offset:15360
	ds_read_b32 v10, v59 offset:37416
	ds_read_b128 v[46:49], v125 offset:2048
	v_pk_add_f32 v[8:9], v[28:29], v[8:9]
	s_waitcnt lgkmcnt(5)
	v_pk_add_f32 v[6:7], v[30:31], v[6:7]
	v_pk_add_f32 v[8:9], v[32:33], v[8:9]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[6:7], v[34:35], v[6:7]
	v_pk_add_f32 v[8:9], v[36:37], v[8:9]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[6:7], v[38:39], v[6:7]
	v_pk_add_f32 v[8:9], v[40:41], v[8:9]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[6:7], v[42:43], v[6:7]
	v_pk_add_f32 v[8:9], v[44:45], v[8:9]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[6:7], v[46:47], v[10:11], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[48:49], v[10:11], v[8:9] op_sel_hi:[1,0,1]
	ds_write_b128 v125, v[6:9] offset:2048
.LBB0_45:
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v124, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_4
.Lft20:
	ds_read_b128 v[2:5], v124
	ds_read_b128 v[6:9], v124 offset:1024
	ds_read_b128 v[10:13], v124 offset:2048
	ds_read_b128 v[14:17], v124 offset:3072
	ds_read_b128 v[18:21], v124 offset:4096
	ds_read_b128 v[22:25], v124 offset:5120
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[6:7], v[2:3]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[10:11], v[2:3]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[14:15], v[2:3]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[2:3], v[18:19], v[2:3]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[10:11], v[22:23], v[2:3]
	v_pk_add_f32 v[2:3], v[8:9], v[4:5]
	s_nop 0
	v_pk_add_f32 v[6:7], v[12:13], v[2:3]
	ds_read_b128 v[2:5], v124 offset:6144
	v_pk_add_f32 v[6:7], v[16:17], v[6:7]
	s_nop 0
	v_pk_add_f32 v[6:7], v[20:21], v[6:7]
	s_nop 0
	v_pk_add_f32 v[46:47], v[24:25], v[6:7]
	ds_read_b128 v[6:9], v124 offset:7168
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[2:3], v[2:3], v[10:11]
	ds_read_b128 v[10:13], v124 offset:8192
	ds_read_b128 v[14:17], v124 offset:9216
	ds_read_b128 v[18:21], v124 offset:10240
	ds_read_b128 v[22:25], v124 offset:11264
	v_pk_add_f32 v[4:5], v[4:5], v[46:47]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[6:7], v[2:3]
	v_pk_add_f32 v[4:5], v[8:9], v[4:5]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[10:11], v[2:3]
	v_pk_add_f32 v[4:5], v[12:13], v[4:5]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[14:15], v[2:3]
	v_pk_add_f32 v[4:5], v[16:17], v[4:5]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[2:3], v[18:19], v[2:3]
	v_pk_add_f32 v[4:5], v[20:21], v[4:5]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[2:3], v[22:23], v[2:3]
	ds_read_b128 v[26:29], v124 offset:12288
	ds_read_b128 v[30:33], v124 offset:13312
	ds_read_b128 v[34:37], v124 offset:14336
	ds_read_b128 v[38:41], v124 offset:15360
	ds_read_b32 v6, v59 offset:37420
	ds_read_b128 v[42:45], v125 offset:3072
	v_pk_add_f32 v[4:5], v[24:25], v[4:5]
	s_waitcnt lgkmcnt(5)
	v_pk_add_f32 v[2:3], v[26:27], v[2:3]
	v_pk_add_f32 v[4:5], v[28:29], v[4:5]
	s_waitcnt lgkmcnt(4)
	v_pk_add_f32 v[2:3], v[30:31], v[2:3]
	v_pk_add_f32 v[4:5], v[32:33], v[4:5]
	s_waitcnt lgkmcnt(3)
	v_pk_add_f32 v[2:3], v[34:35], v[2:3]
	v_pk_add_f32 v[4:5], v[36:37], v[4:5]
	s_waitcnt lgkmcnt(2)
	v_pk_add_f32 v[2:3], v[38:39], v[2:3]
	v_pk_add_f32 v[4:5], v[40:41], v[4:5]
	s_waitcnt lgkmcnt(0)
	v_pk_fma_f32 v[2:3], v[42:43], v[6:7], v[2:3] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[4:5], v[44:45], v[6:7], v[4:5] op_sel_hi:[1,0,1]
	ds_write_b128 v125, v[2:5] offset:3072
	s_branch .LBB0_4
.LBB0_47:
	scratch_load_dwordx2 v[6:7], off, off offset:52
	s_mov_b32 s0, 0x800000
	s_waitcnt vmcnt(3)
	v_cmp_gt_f32_e64 s[0:1], s0, v57
	v_mov_b32_e32 v2, 0xc1b17218
	s_nop 0
	v_cndmask_b32_e64 v3, 0, 32, s[0:1]
	v_ldexp_f32 v3, v57, v3
	v_log_f32_e32 v3, v3
	v_cndmask_b32_e64 v2, 0, v2, s[0:1]
	v_fmamk_f32 v2, v3, 0x3f317218, v2
	s_waitcnt vmcnt(2)
	v_add_f32_e32 v4, v103, v2
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execnz .LBB0_49
.Lft21:
	s_branch .LBB0_54
.LBB0_48:
	v_mov_b32_e32 v4, 0xff800000
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_54
.LBB0_49:
	s_ashr_i32 s3, s20, 31
	s_add_u32 s2, s22, s20
	v_mov_b32_e32 v2, s12
	v_mov_b32_e32 v3, s13
	v_mov_b32_e32 v5, 0x8000
	s_addc_u32 s3, s23, s3
	v_lshl_or_b32 v5, v0, 4, v5
	s_cmp_lt_i32 s20, s16
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[2:3], v[6:7], 2, v[2:3]
	s_cbranch_scc1 .LBB0_57
.Lft22:
	s_cmp_ge_i32 s33, s16
	s_cbranch_scc0 .LBB0_58
.LBB0_51:
	s_cmp_ge_i32 s21, s16
	s_cbranch_scc0 .LBB0_59
.LBB0_52:
	s_cmp_ge_i32 s5, s16
	s_cbranch_scc1 .LBB0_54
.LBB0_53:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v10, v6 offset:37388
	ds_read_b128 v[6:9], v5 offset:3072
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
	v_add_co_u32_e32 v2, vcc, 0x1000, v2
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[6:7], v[6:7], v[10:11] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[10:11] op_sel_hi:[1,0]
	v_addc_co_u32_e32 v3, vcc, 0, v3, vcc
	global_store_dwordx4 v[2:3], v[6:9], off offset:2048
.LBB0_54:
	s_or_b64 exec, exec, s[0:1]
	s_cmp_eq_u32 s4, 0
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_cselect_b64 s[0:1], -1, 0
	v_or_b32_e32 v0, s20, v0
	s_and_b64 s[0:1], vcc, s[0:1]
	v_cmp_gt_i32_e32 vcc, s16, v0
	s_and_b64 s[0:1], s[0:1], vcc
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_56
.Lft23:
	s_ashr_i32 s21, s20, 31
	s_lshl_b64 s[0:1], s[22:23], 2
	s_add_u32 s2, s14, s0
	s_addc_u32 s3, s15, s1
	s_lshl_b64 s[0:1], s[20:21], 2
	s_add_u32 s0, s2, s0
	s_addc_u32 s1, s3, s1
	s_waitcnt vmcnt(1)
	global_store_dword v1, v4, s[0:1]
.LBB0_56:
	s_endpgm
.LBB0_57:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v12, v6 offset:37376
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
	s_cmp_ge_i32 s33, s16
	s_cbranch_scc1 .LBB0_51
.LBB0_58:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v12, v6 offset:37380
	ds_read_b128 v[6:9], v5 offset:1024
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
	global_store_dwordx4 v[10:11], v[6:9], off offset:2048
	s_cmp_ge_i32 s21, s16
	s_cbranch_scc1 .LBB0_52
.LBB0_59:
	v_mov_b32_e32 v6, 0
	ds_read_b32 v12, v6 offset:37384
	ds_read_b128 v[6:9], v5 offset:2048
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
	v_add_co_u32_e32 v10, vcc, 0x1000, v10
	s_waitcnt lgkmcnt(0)
	v_pk_mul_f32 v[6:7], v[6:7], v[12:13] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], v[12:13] op_sel_hi:[1,0]
	v_addc_co_u32_e32 v11, vcc, 0, v11, vcc
	global_store_dwordx4 v[10:11], v[6:9], off
	s_cmp_ge_i32 s5, s16
	s_cbranch_scc0 .LBB0_53
.Lft24:
	s_branch .LBB0_54
.Lfunc_end0:
	.size	mla_decode, .Lfunc_end0-mla_decode
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel mla_decode
		.amdhsa_group_segment_fixed_size 37424
		.amdhsa_private_segment_fixed_size 64
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
		.amdhsa_enable_private_segment 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 126
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
  .group_segment_fixed_size: 37424
  .kernarg_segment_align: 8
  .kernarg_segment_size: 44
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: mla_decode
  .private_segment_fixed_size: 64
  .sgpr_count: 108
  .sgpr_spill_count: 0
  .symbol: mla_decode.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 126
  .vgpr_spill_count: 15
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
