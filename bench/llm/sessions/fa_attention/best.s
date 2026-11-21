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
	s_lshl_b32 s84, s2, 4
	v_and_b32_e32 v1, 15, v0
	v_lshrrev_b32_e32 v2, 4, v0
	v_and_b32_e32 v2, 3, v2
	v_and_b32_e32 v7, 0x30, v0
	v_readfirstlane_b32 s4, v0
	s_lshr_b32 s4, s4, 6
	s_lshl_b32 s5, s4, 4
	s_waitcnt lgkmcnt(0)
	s_add_i32 s33, s28, -1
	s_add_i32 s0, s84, 15
	s_min_i32 s0, s0, s33
	s_add_i32 s0, s0, 1
	s_min_i32 s0, s0, s29
	s_cmp_eq_u32 s31, 0
	s_cselect_b32 s6, 0x40000000, 0
	s_cselect_b32 s7, s29, s0
	s_add_i32 s8, s29, -1
	s_lshl_b32 s8, s8, 8
	v_add_u32_e32 v4, s84, v1
	v_min_i32_e32 v5, s33, v4
	v_lshlrev_b32_e32 v6, 8, v5
	v_or_b32_e32 v6, v6, v7
	global_load_dwordx4 v[8:11], v6, s[20:21]
	global_load_dwordx4 v[12:15], v6, s[20:21] offset:64
	global_load_dwordx4 v[16:19], v6, s[20:21] offset:128
	global_load_dwordx4 v[20:23], v6, s[20:21] offset:192
	v_mov_b32_e32 v96, s30
	v_mul_f32_e32 v96, 0x3fb8aa3b, v96
	v_add_u32_e32 v97, 1, v5
	v_add_u32_e32 v97, s6, v97
	v_min_i32_e32 v76, s29, v97
	v_add_u32_e32 v77, -1, v76
	v_add_u32_e32 v78, -2, v76
	v_add_u32_e32 v79, -3, v76
	v_lshrrev_b32_e32 v3, 2, v0
	v_and_b32_e32 v80, 0x7c, v3
	v_and_b32_e32 v3, 0x70, v3
	v_or_b32_e32 v3, v3, v1
	v_lshlrev_b32_e32 v3, 8, v3
	v_or_b32_e32 v88, v3, v7
	v_or_b32_e32 v89, s8, v7
	v_lshlrev_b32_e32 v3, 4, v1
	v_lshlrev_b32_e32 v86, 8, v80
	v_or_b32_e32 v86, v86, v3
	v_or_b32_e32 v87, s8, v3
	v_mov_b32_e32 v84, 0xff800000
	v_mov_b32_e32 v81, 0xf149f2ca
	v_mov_b32_e32 v82, 0xf149f2ca
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v60, 0
	v_mov_b32_e32 v61, 0
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v64, 0
	v_mov_b32_e32 v65, 0
	v_mov_b32_e32 v66, 0
	v_mov_b32_e32 v67, 0
	v_mov_b32_e32 v68, 0
	v_mov_b32_e32 v69, 0
	v_mov_b32_e32 v70, 0
	v_mov_b32_e32 v71, 0
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_lshlrev_b32_e32 v98, 2, v0
	v_and_b32_e32 v3, 0x1c0, v0
	v_or_b32_e32 v99, v3, v1
	v_lshlrev_b32_e32 v99, 2, v99
	v_lshlrev_b32_e32 v100, 2, v3
	v_or_b32_e32 v100, v100, v7
	v_lshlrev_b32_e32 v101, 2, v1
	v_or_b32_e32 v101, v101, v3
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v8, v96, v8
	v_mul_f32_e32 v9, v96, v9
	v_mul_f32_e32 v10, v96, v10
	v_mul_f32_e32 v11, v96, v11
	v_mul_f32_e32 v12, v96, v12
	v_mul_f32_e32 v13, v96, v13
	v_mul_f32_e32 v14, v96, v14
	v_mul_f32_e32 v15, v96, v15
	v_mul_f32_e32 v16, v96, v16
	v_mul_f32_e32 v17, v96, v17
	v_mul_f32_e32 v18, v96, v18
	v_mul_f32_e32 v19, v96, v19
	v_mul_f32_e32 v20, v96, v20
	v_mul_f32_e32 v21, v96, v21
	v_mul_f32_e32 v22, v96, v22
	v_mul_f32_e32 v23, v96, v23
	s_cmp_ge_i32 s5, s7
	s_cbranch_scc1 .Ltail
.Ltile:
	v_min_u32_e32 v90, v88, v89
	global_load_dwordx4 v[24:27], v90, s[22:23]
	global_load_dwordx4 v[28:31], v90, s[22:23] offset:64
	global_load_dwordx4 v[32:35], v90, s[22:23] offset:128
	global_load_dwordx4 v[36:39], v90, s[22:23] offset:192
	v_min_u32_e32 v91, v86, v87
	global_load_dwordx4 v[40:43], v91, s[24:25]
	v_add_u32_e32 v91, 0x100, v86
	v_min_u32_e32 v91, v91, v87
	global_load_dwordx4 v[44:47], v91, s[24:25]
	v_add_u32_e32 v91, 0x200, v86
	v_min_u32_e32 v91, v91, v87
	global_load_dwordx4 v[48:51], v91, s[24:25]
	v_add_u32_e32 v91, 0x300, v86
	v_min_u32_e32 v91, v91, v87
	global_load_dwordx4 v[52:55], v91, s[24:25]
	s_waitcnt vmcnt(7)
	v_mfma_f32_16x16x4_f32 v[56:59], v24, v8, 0
	v_mfma_f32_16x16x4_f32 v[56:59], v25, v9, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v26, v10, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v27, v11, v[56:59]
	s_waitcnt vmcnt(6)
	v_mfma_f32_16x16x4_f32 v[56:59], v28, v12, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v29, v13, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v30, v14, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v31, v15, v[56:59]
	s_waitcnt vmcnt(5)
	v_mfma_f32_16x16x4_f32 v[56:59], v32, v16, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v33, v17, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v34, v18, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v35, v19, v[56:59]
	s_waitcnt vmcnt(4)
	v_mfma_f32_16x16x4_f32 v[56:59], v36, v20, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v37, v21, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v38, v22, v[56:59]
	v_mfma_f32_16x16x4_f32 v[56:59], v39, v23, v[56:59]
	v_cmp_gt_i32_e64 s[10:11], v76, v80
	v_cmp_gt_i32_e64 s[12:13], v77, v80
	v_cmp_gt_i32_e64 s[14:15], v78, v80
	v_cmp_gt_i32_e64 s[16:17], v79, v80
	s_nop 5
	v_cndmask_b32_e64 v56, v84, v56, s[10:11]
	v_cndmask_b32_e64 v57, v84, v57, s[12:13]
	v_cndmask_b32_e64 v58, v84, v58, s[14:15]
	v_cndmask_b32_e64 v59, v84, v59, s[16:17]
	v_max3_f32 v85, v56, v57, v58
	v_max_f32_e32 v85, v85, v59
	v_cmp_gt_f32_e32 vcc, v85, v82
	s_cbranch_vccnz .Lslow
.Lfast:
	v_sub_f32_e32 v56, v56, v81
	v_sub_f32_e32 v57, v57, v81
	v_sub_f32_e32 v58, v58, v81
	v_sub_f32_e32 v59, v59, v81
	v_exp_f32_e32 v56, v56
	v_exp_f32_e32 v57, v57
	v_exp_f32_e32 v58, v58
	v_exp_f32_e32 v59, v59
	v_add_f32_e32 v83, v83, v56
	v_add_f32_e32 v83, v83, v57
	v_add_f32_e32 v83, v83, v58
	v_add_f32_e32 v83, v83, v59
	s_waitcnt vmcnt(3)
	v_mfma_f32_16x16x4_f32 v[60:63], v56, v40, v[60:63]
	v_mfma_f32_16x16x4_f32 v[64:67], v56, v41, v[64:67]
	v_mfma_f32_16x16x4_f32 v[68:71], v56, v42, v[68:71]
	v_mfma_f32_16x16x4_f32 v[72:75], v56, v43, v[72:75]
	s_waitcnt vmcnt(2)
	v_mfma_f32_16x16x4_f32 v[60:63], v57, v44, v[60:63]
	v_mfma_f32_16x16x4_f32 v[64:67], v57, v45, v[64:67]
	v_mfma_f32_16x16x4_f32 v[68:71], v57, v46, v[68:71]
	v_mfma_f32_16x16x4_f32 v[72:75], v57, v47, v[72:75]
	s_waitcnt vmcnt(1)
	v_mfma_f32_16x16x4_f32 v[60:63], v58, v48, v[60:63]
	v_mfma_f32_16x16x4_f32 v[64:67], v58, v49, v[64:67]
	v_mfma_f32_16x16x4_f32 v[68:71], v58, v50, v[68:71]
	v_mfma_f32_16x16x4_f32 v[72:75], v58, v51, v[72:75]
	s_waitcnt vmcnt(0)
	v_mfma_f32_16x16x4_f32 v[60:63], v59, v52, v[60:63]
	v_mfma_f32_16x16x4_f32 v[64:67], v59, v53, v[64:67]
	v_mfma_f32_16x16x4_f32 v[68:71], v59, v54, v[68:71]
	v_mfma_f32_16x16x4_f32 v[72:75], v59, v55, v[72:75]
	v_add_u32_e32 v88, 0x8000, v88
	v_add_u32_e32 v86, 0x8000, v86
	v_add_u32_e32 v80, 0x80, v80
	s_add_i32 s5, s5, 0x80
	s_cmp_lt_i32 s5, s7
	s_cbranch_scc1 .Ltile
.Lexit:
	s_branch .Ltail
.Lslow:
	ds_write_b32 v98, v85
	ds_read2_b32 v[90:91], v99 offset0:0 offset1:16
	ds_read2_b32 v[92:93], v99 offset0:32 offset1:48
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v85, v90, v91, v92
	v_max3_f32 v85, v85, v93, v81
	v_sub_f32_e32 v90, v81, v85
	v_exp_f32_e32 v90, v90
	v_mov_b32_e32 v81, v85
	v_add_f32_e32 v82, 0x42000000, v85
	v_mul_f32_e32 v83, v83, v90
	ds_write_b32 v98, v90
	ds_read2_b32 v[90:91], v100 offset0:0 offset1:1
	ds_read2_b32 v[92:93], v100 offset0:2 offset1:3
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v60, v60, v90
	v_mul_f32_e32 v61, v61, v91
	v_mul_f32_e32 v62, v62, v92
	v_mul_f32_e32 v63, v63, v93
	v_mul_f32_e32 v64, v64, v90
	v_mul_f32_e32 v65, v65, v91
	v_mul_f32_e32 v66, v66, v92
	v_mul_f32_e32 v67, v67, v93
	v_mul_f32_e32 v68, v68, v90
	v_mul_f32_e32 v69, v69, v91
	v_mul_f32_e32 v70, v70, v92
	v_mul_f32_e32 v71, v71, v93
	v_mul_f32_e32 v72, v72, v90
	v_mul_f32_e32 v73, v73, v91
	v_mul_f32_e32 v74, v74, v92
	v_mul_f32_e32 v75, v75, v93
	s_branch .Lfast
.Ltail:
	ds_write_b32 v101, v81 offset:2048
	v_add_u32_e32 v102, 0x800, v101
	v_and_b32_e32 v102, 0xffffe3f, v102
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read2_b32 v[24:25], v102 offset0:0 offset1:16
	ds_read2_b32 v[26:27], v102 offset0:32 offset1:48
	ds_read2_b32 v[28:29], v102 offset0:64 offset1:80
	ds_read2_b32 v[30:31], v102 offset0:96 offset1:112
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v94, v24, v25, v26
	v_max3_f32 v94, v94, v27, v28
	v_max3_f32 v94, v94, v29, v30
	v_max_f32_e32 v94, v94, v31
	v_sub_f32_e32 v95, v81, v94
	v_exp_f32_e32 v95, v95
	s_nop 0
	v_mul_f32_e32 v83, v83, v95
	ds_write_b32 v98, v83
	ds_read2_b32 v[24:25], v99 offset0:0 offset1:16
	ds_read2_b32 v[26:27], v99 offset0:32 offset1:48
	ds_write_b32 v98, v95
	ds_read2_b32 v[28:29], v100 offset0:0 offset1:1
	ds_read2_b32 v[30:31], v100 offset0:2 offset1:3
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v24, v24, v25
	v_add_f32_e32 v26, v26, v27
	v_add_f32_e32 v24, v24, v26
	ds_write_b32 v101, v24 offset:2560
	v_mul_f32_e32 v60, v60, v28
	v_mul_f32_e32 v61, v61, v29
	v_mul_f32_e32 v62, v62, v30
	v_mul_f32_e32 v63, v63, v31
	v_mul_f32_e32 v64, v64, v28
	v_mul_f32_e32 v65, v65, v29
	v_mul_f32_e32 v66, v66, v30
	v_mul_f32_e32 v67, v67, v31
	v_mul_f32_e32 v68, v68, v28
	v_mul_f32_e32 v69, v69, v29
	v_mul_f32_e32 v70, v70, v30
	v_mul_f32_e32 v71, v71, v31
	v_mul_f32_e32 v72, v72, v28
	v_mul_f32_e32 v73, v73, v29
	v_mul_f32_e32 v74, v74, v30
	v_mul_f32_e32 v75, v75, v31
	ds_write_b32 v98, v60 offset:3072
	ds_write_b32 v98, v61 offset:5120
	ds_write_b32 v98, v62 offset:7168
	ds_write_b32 v98, v63 offset:9216
	ds_write_b32 v98, v64 offset:11264
	ds_write_b32 v98, v65 offset:13312
	ds_write_b32 v98, v66 offset:15360
	ds_write_b32 v98, v67 offset:17408
	ds_write_b32 v98, v68 offset:19456
	ds_write_b32 v98, v69 offset:21504
	ds_write_b32 v98, v70 offset:23552
	ds_write_b32 v98, v71 offset:25600
	ds_write_b32 v98, v72 offset:27648
	ds_write_b32 v98, v73 offset:29696
	ds_write_b32 v98, v74 offset:31744
	ds_write_b32 v98, v75 offset:33792
	v_add_u32_e32 v103, 0x200, v102
	v_lshrrev_b32_e32 v104, 3, v0
	v_and_b32_e32 v104, 8, v104
	v_add_u32_e32 v104, v104, v100
	v_lshrrev_b32_e32 v105, 6, v0
	v_lshlrev_b32_e32 v105, 12, v105
	v_and_b32_e32 v3, 63, v0
	v_lshl_add_u32 v105, v3, 2, v105
	v_add_u32_e32 v105, 0xc00, v105
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read2_b32 v[24:25], v103 offset0:0 offset1:16
	ds_read2_b32 v[26:27], v103 offset0:32 offset1:48
	ds_read2_b32 v[28:29], v103 offset0:64 offset1:80
	ds_read2_b32 v[30:31], v103 offset0:96 offset1:112
	ds_read2st64_b32 v[40:41], v105 offset0:0 offset1:1
	ds_read2st64_b32 v[42:43], v105 offset0:2 offset1:3
	ds_read2st64_b32 v[44:45], v105 offset0:4 offset1:5
	ds_read2st64_b32 v[46:47], v105 offset0:6 offset1:7
	ds_read2st64_b32 v[48:49], v105 offset0:8 offset1:9
	ds_read2st64_b32 v[50:51], v105 offset0:10 offset1:11
	ds_read2st64_b32 v[52:53], v105 offset0:12 offset1:13
	ds_read2st64_b32 v[54:55], v105 offset0:14 offset1:15
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v24, v24, v25
	v_add_f32_e32 v26, v26, v27
	v_add_f32_e32 v28, v28, v29
	v_add_f32_e32 v30, v30, v31
	v_add_f32_e32 v24, v24, v26
	v_add_f32_e32 v28, v28, v30
	v_add_f32_e32 v32, v24, v28
	ds_write_b32 v98, v32
	ds_read2_b32 v[34:35], v104 offset0:0 offset1:1
	v_add_f32_e32 v40, v40, v41
	v_add_f32_e32 v42, v42, v43
	v_add_f32_e32 v44, v44, v45
	v_add_f32_e32 v46, v46, v47
	v_add_f32_e32 v48, v48, v49
	v_add_f32_e32 v50, v50, v51
	v_add_f32_e32 v52, v52, v53
	v_add_f32_e32 v54, v54, v55
	v_add_f32_e32 v40, v40, v42
	v_add_f32_e32 v44, v44, v46
	v_add_f32_e32 v48, v48, v50
	v_add_f32_e32 v52, v52, v54
	v_add_f32_e32 v40, v40, v44
	v_add_f32_e32 v48, v48, v52
	v_lshrrev_b32_e32 v36, 5, v0
	v_and_b32_e32 v36, 2, v36
	v_lshl_add_u32 v36, v2, 2, v36
	v_add_u32_e32 v36, s84, v36
	v_add_u32_e32 v39, 1, v36
	v_lshrrev_b32_e32 v38, 7, v0
	v_lshl_add_u32 v38, v1, 2, v38
	v_lshlrev_b32_e32 v38, 2, v38
	v_lshlrev_b32_e32 v37, 8, v36
	v_add_u32_e32 v37, v37, v38
	v_cmp_gt_i32_e64 s[8:9], s28, v36
	v_cmp_gt_i32_e64 s[10:11], s28, v39
	s_waitcnt lgkmcnt(0)
	v_rcp_f32_e32 v34, v34
	v_rcp_f32_e32 v35, v35
	s_nop 0
	v_mul_f32_e32 v40, v40, v34
	v_mul_f32_e32 v48, v48, v35
	s_mov_b64 s[6:7], exec
	s_and_b64 exec, s[6:7], s[8:9]
	global_store_dword v37, v40, s[26:27]
	s_and_b64 exec, s[6:7], s[10:11]
	global_store_dword v37, v48, s[26:27] offset:256
	s_mov_b64 exec, s[6:7]
	v_log_f32_e32 v33, v32
	v_cmp_gt_i32_e64 s[8:9], s28, v4
	v_cmp_gt_u32_e64 s[10:11], 16, v0
	v_add_f32_e32 v33, v33, v94
	v_mul_f32_e32 v33, 0x3f317218, v33
	v_lshlrev_b32_e32 v25, 2, v4
	s_and_b64 s[8:9], s[8:9], s[10:11]
	s_and_b64 exec, s[6:7], s[8:9]
	global_store_dword v25, v33, s[34:35]
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
		.amdhsa_next_free_vgpr 106
		.amdhsa_next_free_sgpr 85
		.amdhsa_accum_offset 108
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
  .sgpr_count: 91
  .sgpr_spill_count: 0
  .symbol: fa_attention.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 106
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
