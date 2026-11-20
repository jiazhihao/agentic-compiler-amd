	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	attn_decode
	.globl	attn_decode
	.p2align	8
	.type	attn_decode,@function
attn_decode:
	s_load_dwordx4 s[84:87], s[0:1], 0x28
	s_load_dwordx2 s[4:5], s[0:1], 0x20
	s_mov_b32 s8, s2
	s_load_dwordx8 s[12:19], s[0:1], 0x0
	s_ashr_i32 s9, s8, 31
	s_waitcnt lgkmcnt(0)
	s_abs_i32 s2, s86
	v_cvt_f32_u32_e32 v1, s2
	v_writelane_b32 v88, s4, 0
	s_lshl_b32 s10, s3, 4
	s_lshl_b64 s[20:21], s[8:9], 7
	v_rcp_iflag_f32_e32 v1, v1
	v_writelane_b32 v88, s5, 1
	s_mov_b32 s29, s3
	s_cmp_lt_i32 s84, 1
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v2, v1
	v_lshlrev_b32_e32 v1, 2, v0
	v_cmp_gt_u32_e64 s[0:1], 16, v0
	v_writelane_b32 v88, s8, 2
	v_readfirstlane_b32 s3, v2
	s_nop 0
	v_writelane_b32 v88, s9, 3
	s_cbranch_scc1 .LBB0_22
.Lft0:
	s_sub_i32 s6, 0, s2
	s_mul_i32 s6, s6, s3
	s_mul_hi_u32 s6, s3, s6
	s_abs_i32 s5, s8
	s_add_i32 s3, s3, s6
	s_mul_hi_u32 s3, s5, s3
	s_mul_i32 s6, s3, s2
	s_ashr_i32 s4, s86, 31
	s_sub_i32 s5, s5, s6
	s_xor_b32 s4, s9, s4
	s_add_i32 s6, s3, 1
	s_sub_i32 s7, s5, s2
	s_cmp_ge_u32 s5, s2
	s_cselect_b32 s3, s6, s3
	s_cselect_b32 s5, s7, s5
	s_add_i32 s6, s3, 1
	s_cmp_ge_u32 s5, s2
	s_cselect_b32 s2, s6, s3
	s_xor_b32 s2, s2, s4
	s_ashr_i32 s7, s85, 31
	s_mov_b32 s6, s85
	s_sub_i32 s2, s2, s4
	s_lshl_b64 s[90:91], s[6:7], 7
	v_writelane_b32 v88, s20, 4
	s_lshl_b64 s[4:5], s[20:21], 2
	s_add_u32 s33, s12, s4
	v_writelane_b32 v88, s21, 5
	s_mov_b32 s4, s10
	s_addc_u32 s30, s13, s5
	v_writelane_b32 v88, s4, 6
	v_and_or_b32 v2, v0, 15, s10
	s_mov_b64 s[10:11], s[18:19]
	v_writelane_b32 v88, s5, 7
	v_writelane_b32 v88, s4, 8
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 9
	v_writelane_b32 v88, s5, 9
	v_writelane_b32 v88, s6, 10
	s_add_u32 s92, s14, s2
	v_writelane_b32 v88, s7, 11
	s_addc_u32 s93, s15, s3
	v_writelane_b32 v88, s8, 12
	s_add_u32 s2, s16, s2
	v_writelane_b32 v88, s9, 13
	v_writelane_b32 v88, s10, 14
	s_addc_u32 s3, s17, s3
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshrrev_b32_e32 v39, 4, v0
	v_writelane_b32 v88, s11, 15
	v_lshl_add_u64 v[34:35], v[2:3], 2, s[2:3]
	s_lshl_b64 s[2:3], s[6:7], 13
	s_mov_b32 s86, 0
	v_or_b32_e32 v40, 0x2000, v1
	v_cmp_gt_u32_e64 s[4:5], 32, v0
	v_lshlrev_b32_e32 v41, 7, v0
	v_or_b32_e32 v42, 0x3000, v1
	v_writelane_b32 v88, s2, 16
	v_or_b32_e32 v43, 0x3c0, v39
	s_lshl_b64 s[94:95], s[6:7], 19
	v_or_b32_e32 v44, 0x1000, v1
	v_or_b32_e32 v45, 0x400, v39
	s_lshl_b64 s[96:97], s[6:7], 16
	s_mul_hi_i32 s99, s85, 0x18000
	s_mul_i32 s98, s85, 0x18000
	v_lshlrev_b32_e32 v46, 2, v39
	s_lshl_b64 s[10:11], s[6:7], 15
	v_mov_b32_e32 v47, 0
	v_mov_b32_e32 v50, 0xff800000
	v_mov_b32_e32 v38, 0
	s_mov_b32 s31, 0x3fb8aa3b
	s_mov_b32 s85, 0xc2ce8ed0
	s_mov_b32 s28, 0x42b17218
	v_mov_b32_e32 v48, 0x7f800000
	v_mov_b32_e32 v49, 0
	v_writelane_b32 v88, s3, 17
	s_branch .LBB0_3
.LBB0_2:
	s_or_b64 exec, exec, s[6:7]
	v_add_f32_e32 v30, v30, v31
	v_add_f32_e32 v30, v30, v32
	v_add_f32_e32 v30, v30, v33
	v_add_f32_e32 v26, v30, v26
	v_add_f32_e32 v26, v26, v27
	v_add_f32_e32 v26, v26, v28
	v_add_f32_e32 v26, v26, v29
	v_add_f32_e32 v22, v26, v22
	v_add_f32_e32 v22, v22, v23
	v_add_f32_e32 v22, v22, v24
	v_add_f32_e32 v22, v22, v25
	v_add_f32_e32 v18, v22, v18
	v_add_f32_e32 v18, v18, v19
	v_add_f32_e32 v18, v18, v20
	v_add_f32_e32 v18, v18, v21
	v_add_f32_e32 v14, v18, v14
	v_add_f32_e32 v14, v14, v15
	v_add_f32_e32 v14, v14, v16
	v_add_f32_e32 v14, v14, v17
	v_add_f32_e32 v10, v14, v10
	v_add_f32_e32 v10, v10, v11
	v_add_f32_e32 v10, v10, v12
	v_add_f32_e32 v10, v10, v13
	v_add_f32_e32 v6, v10, v6
	v_add_f32_e32 v6, v6, v7
	v_add_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v6, v9
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v2, v2, v3
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	v_fmac_f32_e32 v2, v49, v36
	s_addk_i32 s86, 0x400
	s_cmp_ge_i32 s86, s84
	v_mov_b32_e32 v50, v51
	v_mov_b32_e32 v49, v2
	s_cbranch_scc1 .LBB0_21
.LBB0_3:
	v_or_b32_e32 v3, s86, v0
	v_cmp_gt_i32_e64 s[6:7], s84, v3
	v_mov_b32_e32 v2, 0xff800000
	s_and_saveexec_b64 s[88:89], s[6:7]
	s_cbranch_execz .LBB0_7
.Lft1:
	v_mad_u64_u32 v[4:5], s[8:9], s90, v3, 0
	v_mov_b32_e32 v2, v5
	v_mad_u64_u32 v[2:3], s[8:9], s91, v3, v[2:3]
	v_mov_b32_e32 v5, v2
	v_lshl_add_u64 v[2:3], v[4:5], 2, s[92:93]
	s_mov_b64 s[34:35], 0
	s_mov_b64 s[8:9], -1
	v_mov_b32_e32 v4, 0
.LBB0_5:
	s_lshl_b64 s[12:13], s[34:35], 4
	v_lshl_add_u64 v[36:37], v[2:3], 0, s[12:13]
	global_load_dwordx4 v[6:9], v[36:37], off offset:240
	global_load_dwordx4 v[10:13], v[36:37], off offset:224
	global_load_dwordx4 v[14:17], v[36:37], off offset:208
	global_load_dwordx4 v[18:21], v[36:37], off offset:192
	global_load_dwordx4 v[22:25], v[36:37], off offset:144
	global_load_dwordx4 v[26:29], v[36:37], off offset:128
	global_load_dwordx4 v[30:33], v[36:37], off offset:112
	global_load_dwordx4 v[52:55], v[36:37], off offset:96
	global_load_dwordx4 v[56:59], v[36:37], off offset:80
	global_load_dwordx4 v[60:63], v[36:37], off offset:64
	global_load_dwordx4 v[64:67], v[36:37], off offset:48
	global_load_dwordx4 v[68:71], v[36:37], off offset:32
	global_load_dwordx4 v[72:75], v[36:37], off offset:16
	global_load_dwordx4 v[76:79], v[36:37], off
	global_load_dwordx4 v[80:83], v[36:37], off offset:160
	global_load_dwordx4 v[84:87], v[36:37], off offset:176
	s_add_u32 s2, s33, s12
	s_addc_u32 s3, s30, s13
	s_load_dwordx16 s[68:83], s[2:3], 0xc0
	s_load_dwordx16 s[12:27], s[2:3], 0x0
	s_load_dwordx16 s[36:51], s[2:3], 0x40
	s_load_dwordx16 s[52:67], s[2:3], 0x80
	v_cndmask_b32_e64 v5, 0, 1, s[8:9]
	v_cmp_ne_u32_e32 vcc, 1, v5
	s_mov_b64 s[34:35], 16
	s_mov_b64 s[8:9], 0
	s_and_b64 vcc, exec, vcc
	s_waitcnt vmcnt(15) lgkmcnt(0)
	v_pk_mul_f32 v[6:7], s[80:81], v[6:7]
	s_waitcnt vmcnt(14)
	v_pk_mul_f32 v[10:11], s[76:77], v[10:11]
	s_waitcnt vmcnt(13)
	v_pk_mul_f32 v[14:15], s[72:73], v[14:15]
	s_waitcnt vmcnt(12)
	v_pk_mul_f32 v[18:19], s[68:69], v[18:19]
	s_waitcnt vmcnt(11)
	v_pk_mul_f32 v[22:23], s[56:57], v[22:23]
	s_waitcnt vmcnt(10)
	v_pk_mul_f32 v[26:27], s[52:53], v[26:27]
	s_waitcnt vmcnt(9)
	v_pk_mul_f32 v[30:31], s[48:49], v[30:31]
	s_waitcnt vmcnt(8)
	v_pk_mul_f32 v[52:53], s[44:45], v[52:53]
	s_waitcnt vmcnt(7)
	v_pk_mul_f32 v[56:57], s[40:41], v[56:57]
	s_waitcnt vmcnt(6)
	v_pk_mul_f32 v[60:61], s[36:37], v[60:61]
	s_waitcnt vmcnt(5)
	v_pk_mul_f32 v[64:65], s[24:25], v[64:65]
	s_waitcnt vmcnt(4)
	v_pk_mul_f32 v[68:69], s[20:21], v[68:69]
	s_waitcnt vmcnt(3)
	v_pk_mul_f32 v[72:73], s[16:17], v[72:73]
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[76:77], s[12:13], v[76:77]
	v_pk_mul_f32 v[78:79], s[14:15], v[78:79]
	v_add_f32_e32 v4, v4, v76
	v_add_f32_e32 v4, v4, v77
	v_add_f32_e32 v4, v4, v78
	v_add_f32_e32 v4, v4, v79
	v_add_f32_e32 v4, v4, v72
	v_pk_mul_f32 v[74:75], s[18:19], v[74:75]
	v_add_f32_e32 v4, v4, v73
	v_add_f32_e32 v4, v4, v74
	v_add_f32_e32 v4, v4, v75
	v_add_f32_e32 v4, v4, v68
	v_pk_mul_f32 v[70:71], s[22:23], v[70:71]
	v_add_f32_e32 v4, v4, v69
	v_add_f32_e32 v4, v4, v70
	v_add_f32_e32 v4, v4, v71
	v_add_f32_e32 v4, v4, v64
	v_pk_mul_f32 v[66:67], s[26:27], v[66:67]
	v_add_f32_e32 v4, v4, v65
	v_add_f32_e32 v4, v4, v66
	v_add_f32_e32 v4, v4, v67
	v_add_f32_e32 v4, v4, v60
	v_pk_mul_f32 v[62:63], s[38:39], v[62:63]
	v_add_f32_e32 v4, v4, v61
	v_add_f32_e32 v4, v4, v62
	v_add_f32_e32 v4, v4, v63
	v_add_f32_e32 v4, v4, v56
	v_pk_mul_f32 v[58:59], s[42:43], v[58:59]
	v_add_f32_e32 v4, v4, v57
	v_add_f32_e32 v4, v4, v58
	v_add_f32_e32 v4, v4, v59
	v_add_f32_e32 v4, v4, v52
	v_pk_mul_f32 v[54:55], s[46:47], v[54:55]
	v_add_f32_e32 v4, v4, v53
	v_add_f32_e32 v4, v4, v54
	v_add_f32_e32 v4, v4, v55
	v_add_f32_e32 v4, v4, v30
	v_pk_mul_f32 v[32:33], s[50:51], v[32:33]
	v_add_f32_e32 v4, v4, v31
	v_add_f32_e32 v4, v4, v32
	v_add_f32_e32 v4, v4, v33
	v_add_f32_e32 v4, v4, v26
	v_pk_mul_f32 v[28:29], s[54:55], v[28:29]
	v_add_f32_e32 v4, v4, v27
	v_add_f32_e32 v4, v4, v28
	v_add_f32_e32 v4, v4, v29
	v_add_f32_e32 v4, v4, v22
	v_pk_mul_f32 v[24:25], s[58:59], v[24:25]
	v_add_f32_e32 v4, v4, v23
	v_add_f32_e32 v4, v4, v24
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[80:81], s[60:61], v[80:81]
	v_add_f32_e32 v4, v4, v25
	v_add_f32_e32 v4, v4, v80
	v_pk_mul_f32 v[82:83], s[62:63], v[82:83]
	v_add_f32_e32 v4, v4, v81
	v_add_f32_e32 v4, v4, v82
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[84:85], s[64:65], v[84:85]
	v_add_f32_e32 v4, v4, v83
	v_add_f32_e32 v4, v4, v84
	v_pk_mul_f32 v[36:37], s[66:67], v[86:87]
	v_add_f32_e32 v4, v4, v85
	v_add_f32_e32 v4, v4, v36
	v_add_f32_e32 v4, v4, v37
	v_add_f32_e32 v4, v4, v18
	v_pk_mul_f32 v[20:21], s[70:71], v[20:21]
	v_add_f32_e32 v4, v4, v19
	v_add_f32_e32 v4, v4, v20
	v_add_f32_e32 v4, v4, v21
	v_add_f32_e32 v4, v4, v14
	v_pk_mul_f32 v[16:17], s[74:75], v[16:17]
	v_add_f32_e32 v4, v4, v15
	v_add_f32_e32 v4, v4, v16
	v_add_f32_e32 v4, v4, v17
	v_add_f32_e32 v4, v4, v10
	v_pk_mul_f32 v[12:13], s[78:79], v[12:13]
	v_add_f32_e32 v4, v4, v11
	v_add_f32_e32 v4, v4, v12
	v_add_f32_e32 v4, v4, v13
	v_add_f32_e32 v4, v4, v6
	v_pk_mul_f32 v[8:9], s[82:83], v[8:9]
	v_add_f32_e32 v4, v4, v7
	v_add_f32_e32 v4, v4, v8
	v_add_f32_e32 v4, v4, v9
	s_cbranch_vccz .LBB0_5
.Lft2:
	v_mul_f32_e32 v2, s87, v4
.LBB0_7:
	s_or_b64 exec, exec, s[88:89]
	ds_write_b32 v40, v2
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], s[4:5]
	s_cbranch_execz .LBB0_9
.Lft3:
	ds_read_b128 v[4:7], v41 offset:8304
	ds_read_b128 v[8:11], v41 offset:8288
	ds_read_b128 v[12:15], v41 offset:8192
	ds_read_b128 v[16:19], v41 offset:8272
	ds_read_b128 v[20:23], v41 offset:8256
	ds_read_b128 v[24:27], v41 offset:8208
	ds_read_b128 v[28:31], v41 offset:8224
	ds_read_b128 v[52:55], v41 offset:8240
	s_waitcnt lgkmcnt(5)
	v_max_f32_e32 v3, v13, v13
	v_max_f32_e32 v12, v12, v12
	v_max_f32_e32 v3, v12, v3
	v_max3_f32 v3, v3, v14, v15
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v3, v3, v24, v25
	v_max3_f32 v3, v3, v26, v27
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v3, v3, v28, v29
	v_max3_f32 v3, v3, v30, v31
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v3, v3, v52, v53
	v_max3_f32 v3, v3, v54, v55
	v_max3_f32 v3, v3, v20, v21
	v_max3_f32 v3, v3, v22, v23
	v_max3_f32 v3, v3, v16, v17
	v_max3_f32 v3, v3, v18, v19
	v_max3_f32 v3, v3, v8, v9
	v_max3_f32 v3, v3, v10, v11
	v_max3_f32 v3, v3, v4, v5
	v_max3_f32 v3, v3, v6, v7
	ds_write_b32 v42, v3
.LBB0_9:
	s_or_b64 exec, exec, s[8:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[4:7], v47 offset:12288
	ds_read_b128 v[8:11], v47 offset:12304
	ds_read_b128 v[12:15], v47 offset:12320
	ds_read_b128 v[16:19], v47 offset:12336
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v3, v4, v5, v6
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v3, v3, v7, v8
	v_max3_f32 v3, v3, v9, v10
	ds_read_b128 v[4:7], v47 offset:12352
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v3, v3, v11, v12
	v_max3_f32 v3, v3, v13, v14
	ds_read_b128 v[8:11], v47 offset:12368
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v3, v3, v15, v16
	v_max3_f32 v3, v3, v17, v18
	ds_read_b128 v[12:15], v47 offset:12384
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v3, v3, v19, v4
	v_max3_f32 v3, v3, v5, v6
	ds_read_b128 v[16:19], v47 offset:12400
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v3, v3, v7, v8
	v_max3_f32 v3, v3, v9, v10
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v3, v3, v11, v12
	v_max3_f32 v3, v3, v13, v14
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v3, v3, v15, v16
	v_max3_f32 v3, v3, v17, v18
	v_max3_f32 v51, v50, v3, v19
	v_mov_b32_e32 v3, 0
	s_and_saveexec_b64 s[8:9], s[6:7]
	s_cbranch_execz .LBB0_11
.Lft4:
	v_sub_f32_e32 v2, v2, v51
	v_mul_f32_e32 v3, 0x3fb8aa3b, v2
	v_fma_f32 v4, v2, s31, -v3
	v_rndne_f32_e32 v5, v3
	v_fmac_f32_e32 v4, 0x32a5705f, v2
	v_sub_f32_e32 v3, v3, v5
	v_add_f32_e32 v3, v3, v4
	v_cvt_i32_f32_e32 v4, v5
	v_exp_f32_e32 v3, v3
	v_cmp_ngt_f32_e32 vcc, s85, v2
	v_ldexp_f32 v3, v3, v4
	s_nop 0
	v_cndmask_b32_e32 v3, 0, v3, vcc
	v_cmp_nlt_f32_e32 vcc, s28, v2
	s_nop 1
	v_cndmask_b32_e32 v3, v48, v3, vcc
.LBB0_11:
	s_or_b64 exec, exec, s[8:9]
	ds_write_b32 v1, v3
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_13
.Lft5:
	ds_read_b128 v[2:5], v41 offset:112
	ds_read_b128 v[6:9], v41 offset:96
	ds_read_b128 v[10:13], v41
	ds_read_b128 v[14:17], v41 offset:80
	ds_read_b128 v[18:21], v41 offset:64
	ds_read_b128 v[22:25], v41 offset:16
	ds_read_b128 v[26:29], v41 offset:32
	ds_read_b128 v[30:33], v41 offset:48
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
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v2, v2, v3
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	ds_write_b32 v42, v2
.LBB0_13:
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[30:33], v47 offset:12288
	ds_read_b128 v[26:29], v47 offset:12304
	ds_read_b128 v[22:25], v47 offset:12320
	ds_read_b128 v[18:21], v47 offset:12336
	ds_read_b128 v[14:17], v47 offset:12352
	ds_read_b128 v[10:13], v47 offset:12368
	ds_read_b128 v[6:9], v47 offset:12384
	ds_read_b128 v[2:5], v47 offset:12400
	s_sub_i32 s2, s84, s86
	v_or_b32_e32 v53, s86, v39
	s_min_i32 s12, s2, 0x400
	v_mad_u64_u32 v[36:37], s[2:3], s90, v53, 0
	v_mov_b32_e32 v52, v37
	v_mad_u64_u32 v[52:53], s[2:3], s91, v53, v[52:53]
	v_mov_b32_e32 v37, v52
	v_lshl_add_u64 v[36:37], v[36:37], 2, v[34:35]
	v_cmp_gt_i32_e32 vcc, s12, v43
	v_mov_b32_e32 v52, 0
	v_mov_b32_e32 v53, v39
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_15
.Lft6:
	global_load_dword v52, v[36:37], off
	v_readlane_b32 s2, v88, 16
	v_lshl_add_u64 v[56:57], v[36:37], 0, s[96:97]
	v_readlane_b32 s3, v88, 17
	v_lshl_add_u64 v[58:59], v[36:37], 0, s[98:99]
	v_lshl_add_u64 v[60:61], v[56:57], 0, s[96:97]
	v_lshl_add_u64 v[54:55], s[2:3], 2, v[36:37]
	v_lshl_add_u64 v[62:63], v[58:59], 0, s[96:97]
	v_lshl_add_u64 v[64:65], v[60:61], 0, s[96:97]
	v_lshl_add_u64 v[66:67], v[62:63], 0, s[96:97]
	v_lshl_add_u64 v[68:69], v[64:65], 0, s[96:97]
	global_load_dword v53, v[54:55], off
	s_nop 0
	global_load_dword v54, v[56:57], off
	global_load_dword v55, v[58:59], off
	s_nop 0
	global_load_dword v56, v[60:61], off
	global_load_dword v57, v[62:63], off
	global_load_dword v58, v[64:65], off
	global_load_dword v59, v[66:67], off
	global_load_dword v76, v[68:69], off
	v_lshl_add_u64 v[60:61], v[66:67], 0, s[96:97]
	v_lshl_add_u64 v[62:63], v[68:69], 0, s[96:97]
	v_lshl_add_u64 v[64:65], v[60:61], 0, s[96:97]
	v_lshl_add_u64 v[66:67], v[62:63], 0, s[96:97]
	v_lshl_add_u64 v[68:69], v[64:65], 0, s[96:97]
	v_lshl_add_u64 v[70:71], v[66:67], 0, s[96:97]
	v_lshl_add_u64 v[72:73], v[68:69], 0, s[96:97]
	global_load_dword v77, v[60:61], off
	global_load_dword v78, v[62:63], off
	global_load_dword v79, v[64:65], off
	global_load_dword v80, v[66:67], off
	global_load_dword v81, v[68:69], off
	global_load_dword v82, v[70:71], off
	global_load_dword v83, v[72:73], off
	ds_read2st64_b32 v[60:61], v46 offset1:1
	ds_read2st64_b32 v[62:63], v46 offset0:2 offset1:3
	ds_read2st64_b32 v[64:65], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[66:67], v46 offset0:6 offset1:7
	ds_read2st64_b32 v[68:69], v46 offset0:8 offset1:9
	ds_read2st64_b32 v[70:71], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[72:73], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[74:75], v46 offset0:14 offset1:15
	v_lshl_add_u64 v[36:37], v[36:37], 0, s[94:95]
	s_waitcnt vmcnt(14) lgkmcnt(7)
	v_pk_mul_f32 v[52:53], v[52:53], v[60:61]
	s_waitcnt vmcnt(12) lgkmcnt(6)
	v_pk_mul_f32 v[54:55], v[54:55], v[62:63]
	v_add_f32_e32 v52, 0, v52
	v_add_f32_e32 v52, v52, v53
	v_add_f32_e32 v52, v52, v54
	s_waitcnt vmcnt(10) lgkmcnt(5)
	v_pk_mul_f32 v[56:57], v[56:57], v[64:65]
	v_add_f32_e32 v52, v52, v55
	v_add_f32_e32 v52, v52, v56
	s_waitcnt vmcnt(8) lgkmcnt(4)
	v_pk_mul_f32 v[58:59], v[58:59], v[66:67]
	v_add_f32_e32 v52, v52, v57
	v_add_f32_e32 v52, v52, v58
	v_add_f32_e32 v52, v52, v59
	s_waitcnt vmcnt(7) lgkmcnt(3)
	v_fmac_f32_e32 v52, v76, v68
	s_waitcnt vmcnt(6)
	v_fmac_f32_e32 v52, v77, v69
	s_waitcnt vmcnt(5) lgkmcnt(2)
	v_fmac_f32_e32 v52, v78, v70
	s_waitcnt vmcnt(4)
	v_fmac_f32_e32 v52, v79, v71
	s_waitcnt vmcnt(3) lgkmcnt(1)
	v_fmac_f32_e32 v52, v80, v72
	s_waitcnt vmcnt(2)
	v_fmac_f32_e32 v52, v81, v73
	s_waitcnt vmcnt(1) lgkmcnt(0)
	v_fmac_f32_e32 v52, v82, v74
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v52, v83, v75
	v_mov_b32_e32 v53, v45
.LBB0_15:
	s_or_b64 exec, exec, s[6:7]
	v_cmp_gt_i32_e32 vcc, s12, v53
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB0_19
.Lft7:
	v_lshlrev_b32_e32 v54, 2, v53
	s_mov_b64 s[8:9], 0
	.p2align	5, , 4
.LBB0_17:
	global_load_dword v55, v[36:37], off
	ds_read_b32 v56, v54
	v_add_u32_e32 v53, 64, v53
	v_cmp_le_i32_e32 vcc, s12, v53
	v_add_u32_e32 v54, 0x100, v54
	v_lshl_add_u64 v[36:37], v[36:37], 0, s[10:11]
	s_or_b64 s[8:9], vcc, s[8:9]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v52, v56, v55
	s_andn2_b64 exec, exec, s[8:9]
	s_cbranch_execnz .LBB0_17
.Lft8:
	s_or_b64 exec, exec, s[8:9]
.LBB0_19:
	s_or_b64 exec, exec, s[6:7]
	v_sub_f32_e32 v36, v50, v51
	v_mul_f32_e32 v37, 0x3fb8aa3b, v36
	v_fma_f32 v50, v36, s31, -v37
	v_rndne_f32_e32 v53, v37
	v_fmac_f32_e32 v50, 0x32a5705f, v36
	v_sub_f32_e32 v37, v37, v53
	v_add_f32_e32 v37, v37, v50
	v_cvt_i32_f32_e32 v50, v53
	v_exp_f32_e32 v37, v37
	v_cmp_ngt_f32_e32 vcc, s85, v36
	ds_write_b32 v44, v52
	s_waitcnt lgkmcnt(0)
	v_ldexp_f32 v37, v37, v50
	v_cndmask_b32_e32 v37, 0, v37, vcc
	v_cmp_nlt_f32_e32 vcc, s28, v36
	s_barrier
	s_nop 0
	v_cndmask_b32_e32 v36, v48, v37, vcc
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_cbranch_execz .LBB0_2
.Lft9:
	ds_read2_b32 v[52:53], v44 offset1:16
	ds_read2_b32 v[54:55], v44 offset0:32 offset1:48
	ds_read2_b32 v[56:57], v44 offset0:64 offset1:80
	ds_read2_b32 v[58:59], v44 offset0:96 offset1:112
	ds_read2_b32 v[60:61], v44 offset0:128 offset1:144
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v37, v52, v53
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	ds_read2_b32 v[52:53], v44 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v58
	v_add_f32_e32 v37, v37, v59
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v60
	ds_read2_b32 v[54:55], v44 offset0:192 offset1:208
	v_add_f32_e32 v37, v37, v61
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v44 offset0:224 offset1:240
	v_add_u32_e32 v50, 0x400, v44
	ds_read2_b32 v[56:57], v50 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	ds_read2_b32 v[54:55], v50 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	ds_read2_b32 v[56:57], v50 offset0:96 offset1:112
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	ds_read2_b32 v[54:55], v50 offset0:128 offset1:144
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v54
	ds_read2_b32 v[56:57], v50 offset0:192 offset1:208
	v_add_f32_e32 v37, v37, v55
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:224 offset1:240
	v_add_u32_e32 v50, 0x800, v44
	ds_read2_b32 v[54:55], v50 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	ds_read2_b32 v[56:57], v50 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	ds_read2_b32 v[54:55], v50 offset0:96 offset1:112
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	ds_read2_b32 v[56:57], v50 offset0:128 offset1:144
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v56
	ds_read2_b32 v[54:55], v50 offset0:192 offset1:208
	v_add_f32_e32 v37, v37, v57
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:224 offset1:240
	v_add_u32_e32 v50, 0xc00, v44
	ds_read2_b32 v[56:57], v50 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	ds_read2_b32 v[54:55], v50 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	ds_read2_b32 v[56:57], v50 offset0:96 offset1:112
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	ds_read2_b32 v[54:55], v50 offset0:128 offset1:144
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	ds_read2_b32 v[52:53], v50 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	ds_read2_b32 v[56:57], v50 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	ds_read2_b32 v[54:55], v50 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v37, v37, v52
	v_add_f32_e32 v37, v37, v53
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v37, v37, v56
	v_add_f32_e32 v37, v37, v57
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v37, v37, v54
	v_add_f32_e32 v37, v37, v55
	v_fmac_f32_e32 v37, v38, v36
	v_mov_b32_e32 v38, v37
	s_branch .LBB0_2
.LBB0_21:
	v_readlane_b32 s12, v88, 8
	v_readlane_b32 s10, v88, 6
	v_readlane_b32 s20, v88, 4
	v_readlane_b32 s13, v88, 9
	v_readlane_b32 s14, v88, 10
	v_readlane_b32 s15, v88, 11
	v_readlane_b32 s16, v88, 12
	v_readlane_b32 s17, v88, 13
	v_readlane_b32 s18, v88, 14
	v_readlane_b32 s19, v88, 15
	v_readlane_b32 s11, v88, 7
	v_readlane_b32 s21, v88, 5
	s_branch .LBB0_23
.LBB0_22:
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v51, 0xff800000
	v_mov_b32_e32 v38, 0
.LBB0_23:
	v_cmp_gt_u32_e32 vcc, 16, v0
	s_and_saveexec_b64 s[0:1], vcc
	v_readlane_b32 s6, v88, 2
	v_readlane_b32 s7, v88, 3
	s_cbranch_execz .LBB0_25
.Lft10:
	v_div_scale_f32 v3, s[2:3], v2, v2, v38
	v_rcp_f32_e32 v4, v3
	v_div_scale_f32 v5, vcc, v38, v2, v38
	s_ashr_i32 s11, s10, 31
	s_lshl_b64 s[2:3], s[20:21], 2
	v_fma_f32 v6, -v3, v4, 1.0
	v_fmac_f32_e32 v4, v6, v4
	v_mul_f32_e32 v6, v5, v4
	v_fma_f32 v7, -v3, v6, v5
	v_fmac_f32_e32 v6, v7, v4
	s_add_u32 s4, s18, s2
	v_fma_f32 v3, -v3, v6, v5
	s_addc_u32 s5, s19, s3
	s_lshl_b64 s[2:3], s[10:11], 2
	v_div_fmas_f32 v3, v3, v4, v6
	s_add_u32 s2, s4, s2
	v_div_fixup_f32 v3, v3, v2, v38
	s_addc_u32 s3, s5, s3
	global_store_dword v1, v3, s[2:3]
.LBB0_25:
	s_or_b64 exec, exec, s[0:1]
	v_or_b32_e32 v0, s29, v0
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_27
.Lft11:
	s_mov_b32 s0, 0x800000
	v_cmp_gt_f32_e32 vcc, s0, v2
	s_and_b64 s[0:1], vcc, exec
	s_cselect_b32 s0, 32, 0
	v_ldexp_f32 v1, v2, s0
	v_log_f32_e32 v1, v1
	s_mov_b32 s0, 0x3f317217
	v_mov_b32_e32 v0, 0x41b17218
	v_cndmask_b32_e32 v0, 0, v0, vcc
	v_mul_f32_e32 v2, 0x3f317217, v1
	v_fma_f32 v3, v1, s0, -v2
	v_fmamk_f32 v3, v1, 0x3377d1cf, v3
	s_mov_b32 s0, 0x7f800000
	v_add_f32_e32 v2, v2, v3
	v_cmp_lt_f32_e64 vcc, |v1|, s0
	s_lshl_b64 s[0:1], s[6:7], 2
	v_readlane_b32 s2, v88, 0
	v_cndmask_b32_e32 v1, v1, v2, vcc
	v_sub_f32_e32 v0, v1, v0
	v_readlane_b32 s3, v88, 1
	s_add_u32 s0, s2, s0
	v_add_f32_e32 v0, v51, v0
	s_addc_u32 s1, s3, s1
	v_mov_b32_e32 v1, 0
	global_store_dword v1, v0, s[0:1]
.LBB0_27:
	s_endpgm
.Lfunc_end0:
	.size	attn_decode, .Lfunc_end0-attn_decode
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel attn_decode
		.amdhsa_group_segment_fixed_size 12416
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
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 89
		.amdhsa_next_free_sgpr 100
		.amdhsa_accum_offset 92
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
  .group_segment_fixed_size: 12416
  .kernarg_segment_align: 8
  .kernarg_segment_size: 56
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: attn_decode
  .private_segment_fixed_size: 0
  .sgpr_count: 106
  .sgpr_spill_count: 18
  .symbol: attn_decode.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 89
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
