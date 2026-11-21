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
	s_cbranch_scc1 .LBB0_2
.Lft0:
	v_lshlrev_b32_e32 v1, 5, v0
	s_mov_b64 s[0:1], 0
	s_branch .LBB0_3
.LBB0_2:
	s_mov_b64 s[0:1], -1
.LBB0_3:
	v_and_b32_e32 v2, 15, v0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v41, 0xff800000
	s_andn2_b64 vcc, exec, s[0:1]
	v_lshlrev_b32_e32 v88, 2, v0
	v_cmp_gt_u32_e64 s[0:1], 32, v0
	v_lshlrev_b32_e32 v4, 4, v2
	s_cbranch_vccnz .LBB0_27
.Lft1:
	v_and_b32_e32 v89, 0x3f0, v0
	v_mov_b32_e32 v2, 0x8000
	v_lshlrev_b32_e32 v1, 5, v0
	v_lshl_add_u64 v[90:91], s[24:25], 0, v[4:5]
	v_lshl_or_b32 v92, v89, 2, v2
	s_mov_b32 s25, 0
	v_mov_b32_e32 v93, 0xff800000
	v_mov_b32_e32 v80, 0
	v_mov_b32_e32 v81, 0
	v_mov_b32_e32 v72, 0
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v74, 0
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v82, 0
	v_mov_b32_e32 v83, 0
	v_mov_b32_e32 v76, 0
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v84, 0
	v_mov_b32_e32 v85, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v86, 0
	v_mov_b32_e32 v87, 0
	v_mov_b32_e32 v78, 0
	v_mov_b32_e32 v79, 0
	s_mov_b32 s85, 0xc2aeac50
	s_mov_b32 s24, 0x3fb8aa3b
	v_mov_b32_e32 v97, 0xff800000
	v_mov_b32_e32 v96, 0xff800000
	v_mov_b32_e32 v95, 0xff800000
	v_mov_b32_e32 v94, 0xff800000
	v_mov_b32_e32 v113, 0
	v_lshl_add_u64 v[152:153], s[22:23], 0, v[4:5]
	v_lshrrev_b32_e32 v116, 4, v0
	v_and_b32_e32 v116, 3, v116
	v_and_b32_e32 v162, 0xffffffc0, v0
	v_add_u32_e32 v116, v162, v116
	v_and_b32_e32 v163, 3, v0
	v_sub_u32_e32 v163, 3, v163
	v_lshlrev_b32_e32 v118, 13, v163
	v_lshl_add_u32 v118, v116, 2, v118
	v_add_u32_e32 v164, s84, v163
	v_min_i32_e32 v164, s33, v164
	v_add_u32_e32 v164, 1, v164
	s_and_b64 s[2:3], s[88:89], exec
	s_cselect_b32 s2, 0x40000000, 0
	v_add_u32_e32 v164, s2, v164
	v_min_i32_e32 v164, s29, v164
	s_add_i32 s2, s84, 0
	s_min_i32 s2, s2, s33
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 8
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	v_lshl_add_u64 v[114:115], s[2:3], 0, v[4:5]
	global_load_dwordx4 v[120:123], v[114:115], off
	s_add_i32 s2, s84, 1
	s_min_i32 s2, s2, s33
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 8
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	v_lshl_add_u64 v[114:115], s[2:3], 0, v[4:5]
	global_load_dwordx4 v[124:127], v[114:115], off
	s_add_i32 s2, s84, 2
	s_min_i32 s2, s2, s33
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 8
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	v_lshl_add_u64 v[114:115], s[2:3], 0, v[4:5]
	global_load_dwordx4 v[128:131], v[114:115], off
	s_add_i32 s2, s84, 3
	s_min_i32 s2, s2, s33
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 8
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	v_lshl_add_u64 v[114:115], s[2:3], 0, v[4:5]
	global_load_dwordx4 v[132:135], v[114:115], off
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v120, s30, v120
	v_mul_f32_e32 v121, s30, v121
	v_mul_f32_e32 v122, s30, v122
	v_mul_f32_e32 v123, s30, v123
	v_mul_f32_e32 v124, s30, v124
	v_mul_f32_e32 v125, s30, v125
	v_mul_f32_e32 v126, s30, v126
	v_mul_f32_e32 v127, s30, v127
	v_mul_f32_e32 v128, s30, v128
	v_mul_f32_e32 v129, s30, v129
	v_mul_f32_e32 v130, s30, v130
	v_mul_f32_e32 v131, s30, v131
	v_mul_f32_e32 v132, s30, v132
	v_mul_f32_e32 v133, s30, v133
	v_mul_f32_e32 v134, s30, v134
	v_mul_f32_e32 v135, s30, v135
	s_branch .LBB0_6
.LBB0_5:
	s_addk_i32 s25, 0x800
	s_cmp_ge_i32 s25, s31
	v_mov_b32_e32 v97, v42
	v_mov_b32_e32 v96, v43
	v_mov_b32_e32 v95, v40
	v_mov_b32_e32 v94, v41
	s_cbranch_scc1 .LBB0_28
.LBB0_6:
	s_sub_i32 s2, s31, s25
	s_min_i32 s87, s2, 0x800
	s_cmp_gt_i32 s2, 0
	s_cselect_b64 s[90:91], -1, 0
	s_cmp_lt_i32 s2, 1
	s_cbranch_scc1 .LBB0_13
.Lft2:
	s_add_i32 s92, s87, -1
	s_mov_b32 s93, 0
	s_add_i32 s32, s92, s25
	s_mov_b32 s36, 0x42424242
	s_mov_b32 s37, 0x42424242
	s_mov_b32 s38, 0x24242424
	s_mov_b32 s39, 0x24242424
	s_mov_b32 s40, 0x18181818
	s_mov_b32 s41, 0x18181818
	s_mov_b32 s42, 0xf000f000
	s_mov_b32 s43, 0xf000f000
.LBB0_8:
	s_add_i32 s97, s93, s25
	v_add_u32_e32 v117, s97, v116
	s_lshl_b32 s98, s93, 2
	v_add_u32_e32 v119, s98, v118
	v_add_u32_e32 v112, 0, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[8:11], v[114:115], off
	v_add_u32_e32 v112, 4, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[12:15], v[114:115], off
	v_add_u32_e32 v112, 8, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[16:19], v[114:115], off
	v_add_u32_e32 v112, 12, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[20:23], v[114:115], off
	v_add_u32_e32 v112, 16, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[24:27], v[114:115], off
	v_add_u32_e32 v112, 20, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[28:31], v[114:115], off
	v_add_u32_e32 v112, 24, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[32:35], v[114:115], off
	v_add_u32_e32 v112, 28, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[36:39], v[114:115], off
	v_add_u32_e32 v112, 32, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[40:43], v[114:115], off
	v_add_u32_e32 v112, 36, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[44:47], v[114:115], off
	v_add_u32_e32 v112, 40, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[48:51], v[114:115], off
	v_add_u32_e32 v112, 44, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[52:55], v[114:115], off
	v_add_u32_e32 v112, 48, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[56:59], v[114:115], off
	v_add_u32_e32 v112, 52, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[60:63], v[114:115], off
	v_add_u32_e32 v112, 56, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[64:67], v[114:115], off
	v_add_u32_e32 v112, 60, v117
	v_min_i32_e32 v112, s32, v112
	v_lshlrev_b32_e32 v112, 8, v112
	v_lshl_add_u64 v[114:115], v[112:113], 0, v[152:153]
	global_load_dwordx4 v[68:71], v[114:115], off
	s_waitcnt vmcnt(15)
	v_pk_mul_f32 v[154:155], v[120:121], v[8:9]
	v_pk_fma_f32 v[154:155], v[122:123], v[10:11], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[8:9]
	v_pk_fma_f32 v[156:157], v[126:127], v[10:11], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[8:9]
	v_pk_fma_f32 v[158:159], v[130:131], v[10:11], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[8:9]
	v_pk_fma_f32 v[160:161], v[134:135], v[10:11], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 0, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v136, v93, v154, vcc
	s_waitcnt vmcnt(14)
	v_pk_mul_f32 v[154:155], v[120:121], v[12:13]
	v_pk_fma_f32 v[154:155], v[122:123], v[14:15], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[12:13]
	v_pk_fma_f32 v[156:157], v[126:127], v[14:15], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[12:13]
	v_pk_fma_f32 v[158:159], v[130:131], v[14:15], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[12:13]
	v_pk_fma_f32 v[160:161], v[134:135], v[14:15], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 4, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v137, v93, v154, vcc
	s_waitcnt vmcnt(13)
	v_pk_mul_f32 v[154:155], v[120:121], v[16:17]
	v_pk_fma_f32 v[154:155], v[122:123], v[18:19], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[16:17]
	v_pk_fma_f32 v[156:157], v[126:127], v[18:19], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[16:17]
	v_pk_fma_f32 v[158:159], v[130:131], v[18:19], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[16:17]
	v_pk_fma_f32 v[160:161], v[134:135], v[18:19], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 8, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v138, v93, v154, vcc
	s_waitcnt vmcnt(12)
	v_pk_mul_f32 v[154:155], v[120:121], v[20:21]
	v_pk_fma_f32 v[154:155], v[122:123], v[22:23], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[20:21]
	v_pk_fma_f32 v[156:157], v[126:127], v[22:23], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[20:21]
	v_pk_fma_f32 v[158:159], v[130:131], v[22:23], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[20:21]
	v_pk_fma_f32 v[160:161], v[134:135], v[22:23], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 12, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v139, v93, v154, vcc
	s_waitcnt vmcnt(11)
	v_pk_mul_f32 v[154:155], v[120:121], v[24:25]
	v_pk_fma_f32 v[154:155], v[122:123], v[26:27], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[24:25]
	v_pk_fma_f32 v[156:157], v[126:127], v[26:27], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[24:25]
	v_pk_fma_f32 v[158:159], v[130:131], v[26:27], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[24:25]
	v_pk_fma_f32 v[160:161], v[134:135], v[26:27], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 16, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v140, v93, v154, vcc
	s_waitcnt vmcnt(10)
	v_pk_mul_f32 v[154:155], v[120:121], v[28:29]
	v_pk_fma_f32 v[154:155], v[122:123], v[30:31], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[28:29]
	v_pk_fma_f32 v[156:157], v[126:127], v[30:31], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[28:29]
	v_pk_fma_f32 v[158:159], v[130:131], v[30:31], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[28:29]
	v_pk_fma_f32 v[160:161], v[134:135], v[30:31], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 20, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v141, v93, v154, vcc
	s_waitcnt vmcnt(9)
	v_pk_mul_f32 v[154:155], v[120:121], v[32:33]
	v_pk_fma_f32 v[154:155], v[122:123], v[34:35], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[32:33]
	v_pk_fma_f32 v[156:157], v[126:127], v[34:35], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[32:33]
	v_pk_fma_f32 v[158:159], v[130:131], v[34:35], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[32:33]
	v_pk_fma_f32 v[160:161], v[134:135], v[34:35], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 24, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v142, v93, v154, vcc
	s_waitcnt vmcnt(8)
	v_pk_mul_f32 v[154:155], v[120:121], v[36:37]
	v_pk_fma_f32 v[154:155], v[122:123], v[38:39], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[36:37]
	v_pk_fma_f32 v[156:157], v[126:127], v[38:39], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[36:37]
	v_pk_fma_f32 v[158:159], v[130:131], v[38:39], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[36:37]
	v_pk_fma_f32 v[160:161], v[134:135], v[38:39], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 28, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v143, v93, v154, vcc
	s_waitcnt vmcnt(7)
	v_pk_mul_f32 v[154:155], v[120:121], v[40:41]
	v_pk_fma_f32 v[154:155], v[122:123], v[42:43], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[40:41]
	v_pk_fma_f32 v[156:157], v[126:127], v[42:43], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[40:41]
	v_pk_fma_f32 v[158:159], v[130:131], v[42:43], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[40:41]
	v_pk_fma_f32 v[160:161], v[134:135], v[42:43], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 32, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v144, v93, v154, vcc
	s_waitcnt vmcnt(6)
	v_pk_mul_f32 v[154:155], v[120:121], v[44:45]
	v_pk_fma_f32 v[154:155], v[122:123], v[46:47], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[44:45]
	v_pk_fma_f32 v[156:157], v[126:127], v[46:47], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[44:45]
	v_pk_fma_f32 v[158:159], v[130:131], v[46:47], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[44:45]
	v_pk_fma_f32 v[160:161], v[134:135], v[46:47], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 36, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v145, v93, v154, vcc
	s_waitcnt vmcnt(5)
	v_pk_mul_f32 v[154:155], v[120:121], v[48:49]
	v_pk_fma_f32 v[154:155], v[122:123], v[50:51], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[48:49]
	v_pk_fma_f32 v[156:157], v[126:127], v[50:51], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[48:49]
	v_pk_fma_f32 v[158:159], v[130:131], v[50:51], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[48:49]
	v_pk_fma_f32 v[160:161], v[134:135], v[50:51], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 40, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v146, v93, v154, vcc
	s_waitcnt vmcnt(4)
	v_pk_mul_f32 v[154:155], v[120:121], v[52:53]
	v_pk_fma_f32 v[154:155], v[122:123], v[54:55], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[52:53]
	v_pk_fma_f32 v[156:157], v[126:127], v[54:55], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[52:53]
	v_pk_fma_f32 v[158:159], v[130:131], v[54:55], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[52:53]
	v_pk_fma_f32 v[160:161], v[134:135], v[54:55], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 44, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v147, v93, v154, vcc
	s_waitcnt vmcnt(3)
	v_pk_mul_f32 v[154:155], v[120:121], v[56:57]
	v_pk_fma_f32 v[154:155], v[122:123], v[58:59], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[56:57]
	v_pk_fma_f32 v[156:157], v[126:127], v[58:59], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[56:57]
	v_pk_fma_f32 v[158:159], v[130:131], v[58:59], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[56:57]
	v_pk_fma_f32 v[160:161], v[134:135], v[58:59], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 48, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v148, v93, v154, vcc
	s_waitcnt vmcnt(2)
	v_pk_mul_f32 v[154:155], v[120:121], v[60:61]
	v_pk_fma_f32 v[154:155], v[122:123], v[62:63], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[60:61]
	v_pk_fma_f32 v[156:157], v[126:127], v[62:63], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[60:61]
	v_pk_fma_f32 v[158:159], v[130:131], v[62:63], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[60:61]
	v_pk_fma_f32 v[160:161], v[134:135], v[62:63], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 52, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v149, v93, v154, vcc
	s_waitcnt vmcnt(1)
	v_pk_mul_f32 v[154:155], v[120:121], v[64:65]
	v_pk_fma_f32 v[154:155], v[122:123], v[66:67], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[64:65]
	v_pk_fma_f32 v[156:157], v[126:127], v[66:67], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[64:65]
	v_pk_fma_f32 v[158:159], v[130:131], v[66:67], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[64:65]
	v_pk_fma_f32 v[160:161], v[134:135], v[66:67], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 56, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v150, v93, v154, vcc
	s_waitcnt vmcnt(0)
	v_pk_mul_f32 v[154:155], v[120:121], v[68:69]
	v_pk_fma_f32 v[154:155], v[122:123], v[70:71], v[154:155]
	v_pk_mul_f32 v[156:157], v[124:125], v[68:69]
	v_pk_fma_f32 v[156:157], v[126:127], v[70:71], v[156:157]
	v_pk_mul_f32 v[158:159], v[128:129], v[68:69]
	v_pk_fma_f32 v[158:159], v[130:131], v[70:71], v[158:159]
	v_pk_mul_f32 v[160:161], v[132:133], v[68:69]
	v_pk_fma_f32 v[160:161], v[134:135], v[70:71], v[160:161]
	v_add_f32_e32 v154, v154, v155
	v_add_f32_e32 v156, v156, v157
	v_add_f32_e32 v158, v158, v159
	v_add_f32_e32 v160, v160, v161
	v_add_f32_dpp v155, v154, v154 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v157, v156, v156 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v159, v158, v158 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v161, v160, v160 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v154, v155, v155 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v156, v157, v157 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v158, v159, v159 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v160, v161, v161 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e64 v154, v154, v156, s[36:37]
	v_cndmask_b32_e64 v154, v154, v158, s[38:39]
	v_cndmask_b32_e64 v154, v154, v160, s[40:41]
	v_add_u32_e32 v112, 60, v117
	v_cmp_gt_i32_e32 vcc, v164, v112
	v_add_f32_dpp v155, v154, v154 row_half_mirror row_mask:0xf bank_mask:0xf
	s_nop 1
	v_add_f32_dpp v154, v155, v155 row_mirror row_mask:0xf bank_mask:0xf
	v_cndmask_b32_e32 v151, v93, v154, vcc
.LBB0_9:
	s_and_saveexec_b64 s[44:45], s[42:43]
	ds_write_b32 v119, v136 offset:0
	ds_write_b32 v119, v137 offset:16
	ds_write_b32 v119, v138 offset:32
	ds_write_b32 v119, v139 offset:48
	ds_write_b32 v119, v140 offset:64
	ds_write_b32 v119, v141 offset:80
	ds_write_b32 v119, v142 offset:96
	ds_write_b32 v119, v143 offset:112
	ds_write_b32 v119, v144 offset:128
	ds_write_b32 v119, v145 offset:144
	ds_write_b32 v119, v146 offset:160
	ds_write_b32 v119, v147 offset:176
	ds_write_b32 v119, v148 offset:192
	ds_write_b32 v119, v149 offset:208
	ds_write_b32 v119, v150 offset:224
	ds_write_b32 v119, v151 offset:240
	s_mov_b64 exec, s[44:45]
.Lft3:
	s_addk_i32 s93, 0x100
	s_cmp_lt_i32 s93, s87
	s_cbranch_scc1 .LBB0_8
.Lft4:
	s_mov_b32 s2, 0
	v_mov_b32_e32 v10, 0xff800000
	v_mov_b32_e32 v11, 0xff800000
	v_mov_b32_e32 v9, 0xff800000
	v_mov_b32_e32 v8, 0xff800000
	.p2align	5, , 4
.LBB0_12:
	v_lshl_add_u32 v14, s2, 2, v88
	ds_read2st64_b32 v[12:13], v14 offset1:32
	ds_read2st64_b32 v[14:15], v14 offset0:64 offset1:96
	s_addk_i32 s2, 0x100
	s_cmp_ge_i32 s2, s87
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v10, v10, v12
	v_max_f32_e32 v11, v11, v13
	s_waitcnt lgkmcnt(0)
	v_max_f32_e32 v9, v9, v14
	v_max_f32_e32 v8, v8, v15
	s_cbranch_scc0 .LBB0_12
.Lft5:
	s_branch .LBB0_14
.LBB0_13:
	v_mov_b32_e32 v8, 0xff800000
	v_mov_b32_e32 v9, 0xff800000
	v_mov_b32_e32 v11, 0xff800000
	v_mov_b32_e32 v10, 0xff800000
.LBB0_14:
	ds_write_b32 v88, v10 offset:40960
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_16
.Lft6:
	ds_read_b128 v[12:15], v1 offset:40960
	ds_read_b128 v[16:19], v1 offset:40976
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v10, v12, v13
	v_max3_f32 v10, v10, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v10, v10, v16, v17
	v_max3_f32 v10, v10, v18, v19
	ds_write_b32 v88, v10 offset:41984
.LBB0_16:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v5 offset:41984
	ds_read_b128 v[16:19], v5 offset:42000
	ds_read_b128 v[20:23], v5 offset:42016
	ds_read_b128 v[24:27], v5 offset:42032
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v10, v12, v13, v14
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v10, v10, v15, v16
	v_max3_f32 v10, v10, v17, v18
	ds_read_b128 v[12:15], v5 offset:42048
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v10, v10, v19, v20
	v_max3_f32 v10, v10, v21, v22
	ds_read_b128 v[16:19], v5 offset:42064
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v10, v10, v23, v24
	v_max3_f32 v10, v10, v25, v26
	ds_read_b128 v[20:23], v5 offset:42080
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v10, v10, v27, v12
	v_max3_f32 v10, v10, v13, v14
	ds_read_b128 v[24:27], v5 offset:42096
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v10, v10, v15, v16
	v_max3_f32 v10, v10, v17, v18
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v10, v10, v19, v20
	v_max3_f32 v10, v10, v21, v22
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v10, v10, v23, v24
	v_max3_f32 v10, v10, v25, v26
	v_max3_f32 v42, v97, v10, v27
	v_sub_f32_e32 v10, v97, v42
	v_cmp_gt_f32_e32 vcc, s85, v10
	s_barrier
	ds_write_b32 v88, v11 offset:40960
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_18
.Lft7:
	ds_read_b128 v[12:15], v1 offset:40960
	ds_read_b128 v[16:19], v1 offset:40976
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v11, v12, v13
	v_max3_f32 v11, v11, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v11, v11, v16, v17
	v_max3_f32 v11, v11, v18, v19
	ds_write_b32 v88, v11 offset:41984
.LBB0_18:
	s_or_b64 exec, exec, s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v5 offset:41984
	ds_read_b128 v[16:19], v5 offset:42000
	ds_read_b128 v[20:23], v5 offset:42016
	ds_read_b128 v[24:27], v5 offset:42032
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v11, v12, v13, v14
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v11, v11, v15, v16
	v_max3_f32 v11, v11, v17, v18
	ds_read_b128 v[12:15], v5 offset:42048
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v11, v11, v19, v20
	v_max3_f32 v11, v11, v21, v22
	ds_read_b128 v[16:19], v5 offset:42064
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v11, v11, v23, v24
	v_max3_f32 v11, v11, v25, v26
	ds_read_b128 v[20:23], v5 offset:42080
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v11, v11, v27, v12
	v_max3_f32 v11, v11, v13, v14
	ds_read_b128 v[24:27], v5 offset:42096
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v11, v11, v15, v16
	v_max3_f32 v11, v11, v17, v18
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v11, v11, v19, v20
	v_max3_f32 v11, v11, v21, v22
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v11, v11, v23, v24
	v_max3_f32 v11, v11, v25, v26
	v_max3_f32 v43, v96, v11, v27
	v_sub_f32_e32 v11, v96, v43
	v_cmp_gt_f32_e64 s[2:3], s85, v11
	s_barrier
	ds_write_b32 v88, v9 offset:40960
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], s[0:1]
	s_cbranch_execz .LBB0_20
.Lft8:
	ds_read_b128 v[12:15], v1 offset:40960
	ds_read_b128 v[16:19], v1 offset:40976
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v9, v12, v13
	v_max3_f32 v9, v9, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v9, v9, v16, v17
	v_max3_f32 v9, v9, v18, v19
	ds_write_b32 v88, v9 offset:41984
.LBB0_20:
	s_or_b64 exec, exec, s[4:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[12:15], v5 offset:41984
	ds_read_b128 v[16:19], v5 offset:42000
	ds_read_b128 v[20:23], v5 offset:42016
	ds_read_b128 v[24:27], v5 offset:42032
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v9, v12, v13, v14
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v9, v9, v15, v16
	v_max3_f32 v9, v9, v17, v18
	ds_read_b128 v[12:15], v5 offset:42048
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v9, v9, v19, v20
	v_max3_f32 v9, v9, v21, v22
	ds_read_b128 v[16:19], v5 offset:42064
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v9, v9, v23, v24
	v_max3_f32 v9, v9, v25, v26
	ds_read_b128 v[20:23], v5 offset:42080
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v9, v9, v27, v12
	v_max3_f32 v9, v9, v13, v14
	ds_read_b128 v[24:27], v5 offset:42096
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v9, v9, v15, v16
	v_max3_f32 v9, v9, v17, v18
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v9, v9, v19, v20
	v_max3_f32 v9, v9, v21, v22
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v9, v9, v23, v24
	v_max3_f32 v9, v9, v25, v26
	v_max3_f32 v40, v95, v9, v27
	v_sub_f32_e32 v9, v95, v40
	v_cmp_gt_f32_e64 s[4:5], s85, v9
	s_barrier
	ds_write_b32 v88, v8 offset:40960
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_cbranch_execz .LBB0_22
.Lft9:
	ds_read_b128 v[12:15], v1 offset:40960
	ds_read_b128 v[16:19], v1 offset:40976
	s_waitcnt lgkmcnt(1)
	v_max_f32_e32 v8, v12, v13
	v_max3_f32 v8, v8, v14, v15
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v8, v8, v16, v17
	v_max3_f32 v8, v8, v18, v19
	ds_write_b32 v88, v8 offset:41984
.LBB0_22:
	s_or_b64 exec, exec, s[6:7]
	v_add_f32_e32 v8, 0x42800000, v10
	v_cndmask_b32_e32 v8, v10, v8, vcc
	v_add_f32_e32 v10, 0x42800000, v11
	v_mul_f32_e32 v8, 0x3fb8aa3b, v8
	v_cndmask_b32_e64 v10, v11, v10, s[2:3]
	v_add_f32_e32 v12, 0x42800000, v9
	v_exp_f32_e32 v8, v8
	v_mul_f32_e32 v10, 0x3fb8aa3b, v10
	v_cndmask_b32_e64 v9, v9, v12, s[4:5]
	v_exp_f32_e32 v10, v10
	v_mul_f32_e32 v9, 0x3fb8aa3b, v9
	v_exp_f32_e32 v9, v9
	v_mul_f32_e32 v11, 0x114b4ea4, v8
	v_cndmask_b32_e32 v8, v8, v11, vcc
	v_mul_f32_e32 v11, 0x114b4ea4, v10
	v_cndmask_b32_e64 v10, v10, v11, s[2:3]
	v_mul_f32_e32 v11, 0x114b4ea4, v9
	v_cndmask_b32_e64 v16, v9, v11, s[4:5]
	v_mul_f32_e32 v80, v8, v80
	v_mul_f32_e32 v86, v8, v86
	v_mul_f32_e32 v84, v8, v84
	v_mul_f32_e32 v82, v8, v82
	v_mul_f32_e32 v6, v8, v6
	v_mul_f32_e32 v81, v10, v81
	v_mul_f32_e32 v87, v10, v87
	v_mul_f32_e32 v85, v10, v85
	v_mul_f32_e32 v83, v10, v83
	v_mul_f32_e32 v7, v10, v7
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[8:11], v5 offset:41984
	ds_read_b128 v[12:15], v5 offset:42000
	v_mul_f32_e32 v72, v16, v72
	v_mul_f32_e32 v78, v16, v78
	v_mul_f32_e32 v2, v16, v2
	v_mul_f32_e32 v76, v16, v76
	v_mul_f32_e32 v74, v16, v74
	ds_read_b128 v[16:19], v5 offset:42016
	ds_read_b128 v[20:23], v5 offset:42032
	s_waitcnt lgkmcnt(3)
	v_max3_f32 v8, v8, v9, v10
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v8, v8, v11, v12
	v_max3_f32 v8, v8, v13, v14
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v12, v8, v15, v16
	ds_read_b128 v[8:11], v5 offset:42048
	v_max3_f32 v12, v12, v17, v18
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v12, v12, v19, v20
	v_max3_f32 v16, v12, v21, v22
	ds_read_b128 v[12:15], v5 offset:42064
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v8, v16, v23, v8
	ds_read_b128 v[16:19], v5 offset:42080
	ds_read_b128 v[20:23], v5 offset:42096
	v_max3_f32 v8, v8, v9, v10
	s_waitcnt lgkmcnt(2)
	v_max3_f32 v8, v8, v11, v12
	v_max3_f32 v8, v8, v13, v14
	s_waitcnt lgkmcnt(1)
	v_max3_f32 v8, v8, v15, v16
	v_max3_f32 v8, v8, v17, v18
	s_waitcnt lgkmcnt(0)
	v_max3_f32 v8, v8, v19, v20
	v_max3_f32 v8, v8, v21, v22
	v_max3_f32 v41, v94, v8, v23
	v_sub_f32_e32 v8, v94, v41
	v_add_f32_e32 v9, 0x42800000, v8
	v_cmp_gt_f32_e32 vcc, s85, v8
	s_barrier
	s_nop 0
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_mul_f32_e32 v8, 0x3fb8aa3b, v8
	v_exp_f32_e32 v8, v8
	s_nop 0
	v_mul_f32_e32 v9, 0x114b4ea4, v8
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_mul_f32_e32 v73, v8, v73
	v_mul_f32_e32 v79, v8, v79
	v_mul_f32_e32 v3, v8, v3
	v_mul_f32_e32 v77, v8, v77
	v_mul_f32_e32 v75, v8, v75
	s_and_b64 vcc, exec, s[90:91]
	s_cbranch_vccz .LBB0_5
.Lft10:
	s_add_i32 s4, s25, s87
	s_add_i32 s4, s4, -1
	v_or_b32_e32 v20, s25, v89
	s_mov_b32 s5, 0
	.p2align	5, , 4
.LBB0_24:
	v_lshl_add_u32 v10, s5, 2, v88
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
	ds_write2st64_b32 v88, v16, v17 offset0:128 offset1:132
	ds_write2st64_b32 v88, v18, v19 offset0:136 offset1:140
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
	v_lshl_add_u64 v[94:95], v[90:91], 0, v[60:61]
	v_lshl_add_u64 v[98:99], v[90:91], 0, v[62:63]
	v_lshl_add_u64 v[102:103], v[90:91], 0, v[64:65]
	global_load_dwordx4 v[56:59], v[38:39], off
	global_load_dwordx4 v[60:63], v[66:67], off
	s_nop 0
	global_load_dwordx4 v[64:67], v[68:69], off
	s_nop 0
	global_load_dwordx4 v[68:71], v[70:71], off
	s_nop 0
	global_load_dwordx4 v[94:97], v[94:95], off
	s_nop 0
	global_load_dwordx4 v[98:101], v[98:99], off
	s_nop 0
	global_load_dwordx4 v[102:105], v[102:103], off
	v_cndmask_b32_e64 v8, 0, 1, s[2:3]
	v_lshl_add_u32 v12, s6, 2, v92
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
	v_pk_fma_f32 v[78:79], v[28:29], v[52:53], v[78:79] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[84:85], v[38:39], v[52:53], v[84:85] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[28:29], v[52:53], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[52:53], v[38:39], v[54:55], v[82:83] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[76:77], v[28:29], v[54:55], v[76:77] op_sel_hi:[1,0,1]
	v_mov_b32_e32 v54, v55
	v_pk_fma_f32 v[6:7], v[38:39], v[54:55], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[28:29], v[54:55], v[74:75] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(6)
	v_mov_b32_e32 v38, v59
	v_pk_fma_f32 v[78:79], v[48:49], v[56:57], v[78:79] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[46:47], v[30:31], v[56:57], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[48:49], v[56:57], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[56:57], v[30:31], v[56:57], v[84:85] op_sel:[0,1,0]
	v_pk_fma_f32 v[76:77], v[48:49], v[58:59], v[76:77] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[52:53], v[30:31], v[58:59], v[52:53] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(5)
	v_mov_b32_e32 v54, v63
	v_pk_fma_f32 v[28:29], v[48:49], v[38:39], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[30:31], v[38:39], v[6:7] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(4)
	v_mov_b32_e32 v58, v67
	v_pk_fma_f32 v[46:47], v[22:23], v[60:61], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[78:79], v[34:35], v[60:61], v[78:79] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[56:57], v[22:23], v[60:61], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[34:35], v[60:61], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[52:53], v[22:23], v[62:63], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[60:61], v[34:35], v[62:63], v[76:77] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[22:23], v[54:55], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[34:35], v[54:55], v[28:29] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(3)
	v_mov_b32_e32 v74, v71
	v_pk_fma_f32 v[30:31], v[50:51], v[64:65], v[78:79] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[38:39], v[32:33], v[64:65], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[50:51], v[64:65], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[46:47], v[32:33], v[64:65], v[56:57] op_sel:[0,1,0]
	v_pk_fma_f32 v[48:49], v[50:51], v[66:67], v[60:61] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[52:53], v[32:33], v[66:67], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[50:51], v[58:59], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[32:33], v[58:59], v[6:7] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(2)
	v_mov_b32_e32 v82, v97
	v_pk_fma_f32 v[28:29], v[24:25], v[68:69], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[30:31], v[36:37], v[68:69], v[30:31] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[34:35], v[24:25], v[68:69], v[46:47] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[36:37], v[68:69], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[38:39], v[24:25], v[70:71], v[52:53] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[46:47], v[36:37], v[70:71], v[48:49] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[24:25], v[74:75], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[22:23], v[36:37], v[74:75], v[22:23] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(1)
	v_mov_b32_e32 v106, v101
	v_pk_fma_f32 v[30:31], v[12:13], v[94:95], v[30:31] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[8:9], v[94:95], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[12:13], v[94:95], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[32:33], v[8:9], v[94:95], v[34:35] op_sel:[0,1,0]
	v_pk_fma_f32 v[34:35], v[12:13], v[96:97], v[46:47] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[38:39], v[8:9], v[96:97], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[12:13], v[12:13], v[82:83], v[22:23] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[8:9], v[82:83], v[6:7] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v108, v105
	v_pk_fma_f32 v[24:25], v[26:27], v[98:99], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[28:29], v[44:45], v[98:99], v[30:31] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[30:31], v[26:27], v[98:99], v[32:33] op_sel:[0,1,0]
	v_pk_fma_f32 v[2:3], v[44:45], v[98:99], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[32:33], v[26:27], v[100:101], v[38:39] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[34:35], v[44:45], v[100:101], v[34:35] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[26:27], v[106:107], v[6:7] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[8:9], v[44:45], v[106:107], v[12:13] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[78:79], v[14:15], v[102:103], v[28:29] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[86:87], v[10:11], v[102:103], v[24:25] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[2:3], v[14:15], v[102:103], v[2:3] op_sel:[0,1,0]
	v_pk_fma_f32 v[84:85], v[10:11], v[102:103], v[30:31] op_sel:[0,1,0]
	v_pk_fma_f32 v[76:77], v[14:15], v[104:105], v[34:35] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[82:83], v[10:11], v[104:105], v[32:33] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[74:75], v[14:15], v[108:109], v[8:9] op_sel_hi:[1,0,1]
	v_pk_fma_f32 v[6:7], v[10:11], v[108:109], v[6:7] op_sel_hi:[1,0,1]
	s_cbranch_vccz .LBB0_25
.Lft11:
	s_addk_i32 s5, 0x100
	v_pk_add_f32 v[72:73], v[18:19], v[72:73]
	v_pk_add_f32 v[80:81], v[16:17], v[80:81]
	s_cmp_ge_i32 s5, s87
	s_barrier
	s_cbranch_scc0 .LBB0_24
.Lft12:
	s_branch .LBB0_5
.LBB0_27:
	v_mov_b32_e32 v40, v41
	v_mov_b32_e32 v43, v41
	v_mov_b32_e32 v42, v41
	v_mov_b32_e32 v73, 0
	v_mov_b32_e32 v72, v5
	v_mov_b32_e32 v81, v5
	v_mov_b32_e32 v80, v5
	v_mov_b32_e32 v75, 0
	v_mov_b32_e32 v74, v5
	v_mov_b32_e32 v7, v5
	v_mov_b32_e32 v6, v5
	v_mov_b32_e32 v77, 0
	v_mov_b32_e32 v76, v5
	v_mov_b32_e32 v83, v5
	v_mov_b32_e32 v82, v5
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v2, v5
	v_mov_b32_e32 v85, v5
	v_mov_b32_e32 v84, v5
	v_mov_b32_e32 v79, 0
	v_mov_b32_e32 v78, v5
	v_mov_b32_e32 v87, v5
	v_mov_b32_e32 v86, v5
.LBB0_28:
	v_or_b32_e32 v47, 0xa000, v88
	v_cmp_gt_u32_e64 s[2:3], 32, v0
	ds_write_b32 v88, v80 offset:40960
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execz .LBB0_30
.Lft13:
	ds_read_b128 v[8:11], v1 offset:40960
	ds_read_b128 v[12:15], v1 offset:40976
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	s_nop 0
	v_pk_add_f32 v[8:9], v[8:9], v[10:11]
	s_nop 0
	v_add_f32_e32 v5, v8, v9
	ds_write_b32 v47, v5 offset:1024
.LBB0_30:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v89, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[36:39], v89 offset:41984
	ds_read_b128 v[32:35], v89 offset:42000
	ds_read_b128 v[28:31], v89 offset:42016
	ds_read_b128 v[24:27], v89 offset:42032
	ds_read_b128 v[20:23], v89 offset:42048
	ds_read_b128 v[16:19], v89 offset:42064
	ds_read_b128 v[12:15], v89 offset:42080
	ds_read_b128 v[8:11], v89 offset:42096
	v_lshlrev_b32_e32 v5, 4, v0
	v_and_b32_e32 v5, 0x3f00, v5
	s_cmp_lt_i32 s84, s28
	v_add_u32_e32 v5, 0x9000, v5
	v_cmp_gt_u32_e64 s[0:1], 64, v0
	s_cselect_b64 s[4:5], -1, 0
	v_add_u32_e32 v46, 0xfffff000, v47
	v_lshl_add_u64 v[44:45], s[26:27], 0, v[88:89]
	v_cmp_eq_u32_e32 vcc, 0, v0
	v_or_b32_e32 v0, v5, v4
	v_mov_b32_e32 v48, v86
	v_mov_b32_e32 v49, v84
	v_mov_b32_e32 v50, v82
	v_mov_b32_e32 v51, v6
	s_and_b64 s[4:5], s[0:1], s[4:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[48:51]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_33
.Lft14:
	v_add_f32_e32 v0, v37, v36
	v_add_f32_e32 v0, v0, v38
	v_add_f32_e32 v0, v0, v39
	v_add_f32_e32 v0, v0, v32
	v_add_f32_e32 v0, v0, v33
	v_add_f32_e32 v0, v0, v34
	v_add_f32_e32 v0, v0, v35
	v_add_f32_e32 v0, v0, v28
	v_add_f32_e32 v0, v0, v29
	v_add_f32_e32 v0, v0, v30
	v_add_f32_e32 v0, v0, v31
	v_add_f32_e32 v0, v0, v24
	v_add_f32_e32 v0, v0, v25
	v_add_f32_e32 v0, v0, v26
	v_add_f32_e32 v0, v0, v27
	v_add_f32_e32 v0, v0, v20
	v_add_f32_e32 v0, v0, v21
	v_add_f32_e32 v0, v0, v22
	v_add_f32_e32 v0, v0, v23
	v_add_f32_e32 v0, v0, v16
	v_add_f32_e32 v0, v0, v17
	v_add_f32_e32 v0, v0, v18
	v_add_f32_e32 v0, v0, v19
	v_add_f32_e32 v0, v0, v12
	v_add_f32_e32 v0, v0, v13
	v_add_f32_e32 v0, v0, v14
	v_add_f32_e32 v0, v0, v15
	v_add_f32_e32 v0, v0, v8
	v_add_f32_e32 v0, v0, v9
	v_add_f32_e32 v0, v0, v10
	v_add_f32_e32 v0, v0, v11
	ds_read2st64_b32 v[8:9], v46 offset0:6 offset1:7
	ds_read2st64_b32 v[10:11], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[12:13], v46 offset0:2 offset1:3
	ds_read2st64_b32 v[14:15], v46 offset1:1
	ds_read2st64_b32 v[16:17], v46 offset0:14 offset1:15
	ds_read2st64_b32 v[18:19], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[20:21], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[22:23], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v14, v15, v14
	v_add_f32_e32 v12, v12, v14
	v_add_f32_e32 v12, v13, v12
	v_add_f32_e32 v10, v10, v12
	v_add_f32_e32 v10, v11, v10
	v_add_f32_e32 v8, v8, v10
	v_add_f32_e32 v8, v9, v8
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v8, v22, v8
	v_add_f32_e32 v8, v23, v8
	v_add_f32_e32 v8, v20, v8
	v_add_f32_e32 v8, v21, v8
	v_rcp_f32_e32 v6, v0
	v_add_f32_e32 v8, v18, v8
	v_add_f32_e32 v8, v19, v8
	v_add_f32_e32 v8, v16, v8
	s_ashr_i32 s85, s84, 31
	v_add_f32_e32 v8, v17, v8
	s_lshl_b64 s[4:5], s[84:85], 8
	v_mul_f32_e32 v6, v6, v8
	v_lshl_add_u64 v[8:9], v[44:45], 0, s[4:5]
	global_store_dword v[8:9], v6, off
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_33
.Lft15:
	s_mov_b32 s4, 0x800000
	v_mov_b32_e32 v6, 0xc1b17218
	v_cmp_gt_f32_e64 s[4:5], s4, v0
	s_nop 1
	v_cndmask_b32_e64 v6, 0, v6, s[4:5]
	s_and_b64 s[4:5], s[4:5], exec
	s_cselect_b32 s4, 32, 0
	v_ldexp_f32 v0, v0, s4
	v_log_f32_e32 v0, v0
	s_lshl_b64 s[4:5], s[84:85], 2
	s_add_u32 s4, s34, s4
	s_addc_u32 s5, s35, s5
	v_fmamk_f32 v0, v0, 0x3f317218, v6
	v_add_f32_e32 v0, v0, v42
	v_mov_b32_e32 v6, 0
	global_store_dword v6, v0, s[4:5]
.LBB0_33:
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	ds_write_b32 v47, v81
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_cbranch_execz .LBB0_35
.Lft16:
	ds_read_b128 v[8:11], v1 offset:40960
	ds_read_b128 v[12:15], v1 offset:40976
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	s_nop 0
	v_pk_add_f32 v[8:9], v[8:9], v[10:11]
	s_nop 0
	v_add_f32_e32 v0, v8, v9
	ds_write_b32 v47, v0 offset:1024
.LBB0_35:
	s_or_b64 exec, exec, s[4:5]
	v_mov_b32_e32 v0, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[36:39], v0 offset:41984
	ds_read_b128 v[32:35], v0 offset:42000
	ds_read_b128 v[28:31], v0 offset:42016
	ds_read_b128 v[24:27], v0 offset:42032
	ds_read_b128 v[20:23], v0 offset:42048
	ds_read_b128 v[16:19], v0 offset:42064
	ds_read_b128 v[12:15], v0 offset:42080
	ds_read_b128 v[8:11], v0 offset:42096
	s_or_b32 s4, s84, 1
	s_cmp_lt_i32 s4, s28
	s_cselect_b64 s[6:7], -1, 0
	v_add_u32_e32 v0, v5, v4
	v_mov_b32_e32 v4, v87
	v_mov_b32_e32 v5, v85
	v_mov_b32_e32 v6, v83
	s_and_b64 s[8:9], s[0:1], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[4:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[8:9]
	s_cbranch_execz .LBB0_38
.Lft17:
	v_add_f32_e32 v4, v37, v36
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
	v_add_f32_e32 v4, v4, v10
	v_add_f32_e32 v4, v4, v11
	ds_read2st64_b32 v[6:7], v46 offset0:6 offset1:7
	ds_read2st64_b32 v[8:9], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[10:11], v46 offset0:2 offset1:3
	ds_read2st64_b32 v[12:13], v46 offset1:1
	ds_read2st64_b32 v[14:15], v46 offset0:14 offset1:15
	ds_read2st64_b32 v[16:17], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[18:19], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[20:21], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v12, v13, v12
	v_add_f32_e32 v10, v10, v12
	v_add_f32_e32 v10, v11, v10
	v_add_f32_e32 v8, v8, v10
	v_add_f32_e32 v8, v9, v8
	v_add_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v7, v6
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v6, v20, v6
	v_add_f32_e32 v6, v21, v6
	v_add_f32_e32 v6, v18, v6
	v_add_f32_e32 v6, v19, v6
	v_rcp_f32_e32 v5, v4
	v_add_f32_e32 v6, v16, v6
	v_add_f32_e32 v6, v17, v6
	v_add_f32_e32 v6, v14, v6
	s_ashr_i32 s5, s4, 31
	v_add_f32_e32 v6, v15, v6
	s_lshl_b64 s[4:5], s[4:5], 8
	v_mul_f32_e32 v5, v5, v6
	v_lshl_add_u64 v[6:7], v[44:45], 0, s[4:5]
	global_store_dword v[6:7], v5, off
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_38
.Lft18:
	s_mov_b32 s4, 0x800000
	v_mov_b32_e32 v5, 0xc1b17218
	v_cmp_gt_f32_e64 s[4:5], s4, v4
	s_nop 1
	v_cndmask_b32_e64 v5, 0, v5, s[4:5]
	s_and_b64 s[4:5], s[4:5], exec
	s_cselect_b32 s4, 32, 0
	v_ldexp_f32 v4, v4, s4
	v_log_f32_e32 v4, v4
	s_ashr_i32 s85, s84, 31
	s_lshl_b64 s[4:5], s[84:85], 2
	s_add_u32 s4, s34, s4
	v_fmamk_f32 v4, v4, 0x3f317218, v5
	v_add_f32_e32 v4, v4, v43
	s_addc_u32 s5, s35, s5
	v_mov_b32_e32 v5, 0
	global_store_dword v5, v4, s[4:5] offset:4
.LBB0_38:
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	ds_write_b32 v47, v72
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_cbranch_execz .LBB0_40
.Lft19:
	ds_read_b128 v[4:7], v1 offset:40960
	ds_read_b128 v[8:11], v1 offset:40976
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	s_nop 0
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	s_nop 0
	v_add_f32_e32 v4, v4, v5
	ds_write_b32 v47, v4 offset:1024
.LBB0_40:
	s_or_b64 exec, exec, s[4:5]
	v_mov_b32_e32 v4, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[32:35], v4 offset:41984
	ds_read_b128 v[28:31], v4 offset:42000
	ds_read_b128 v[24:27], v4 offset:42016
	ds_read_b128 v[20:23], v4 offset:42032
	ds_read_b128 v[16:19], v4 offset:42048
	ds_read_b128 v[12:15], v4 offset:42064
	ds_read_b128 v[8:11], v4 offset:42080
	ds_read_b128 v[4:7], v4 offset:42096
	s_or_b32 s4, s84, 2
	s_cmp_lt_i32 s4, s28
	s_cselect_b64 s[6:7], -1, 0
	v_mov_b32_e32 v36, v78
	v_mov_b32_e32 v37, v2
	v_mov_b32_e32 v38, v76
	v_mov_b32_e32 v39, v74
	s_and_b64 s[8:9], s[0:1], s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[36:39]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[8:9]
	s_cbranch_execz .LBB0_43
.Lft20:
	v_add_f32_e32 v2, v33, v32
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
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	ds_read2st64_b32 v[4:5], v46 offset0:6 offset1:7
	ds_read2st64_b32 v[6:7], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[8:9], v46 offset0:2 offset1:3
	ds_read2st64_b32 v[10:11], v46 offset1:1
	ds_read2st64_b32 v[12:13], v46 offset0:14 offset1:15
	ds_read2st64_b32 v[14:15], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[16:17], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[18:19], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v10, v11, v10
	v_add_f32_e32 v8, v8, v10
	v_add_f32_e32 v8, v9, v8
	v_add_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v7, v6
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v5, v4
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v18, v4
	v_add_f32_e32 v4, v19, v4
	v_add_f32_e32 v4, v16, v4
	v_add_f32_e32 v4, v17, v4
	v_rcp_f32_e32 v20, v2
	v_add_f32_e32 v4, v14, v4
	v_add_f32_e32 v4, v15, v4
	v_add_f32_e32 v4, v12, v4
	s_ashr_i32 s5, s4, 31
	v_add_f32_e32 v4, v13, v4
	s_lshl_b64 s[4:5], s[4:5], 8
	v_mul_f32_e32 v6, v20, v4
	v_lshl_add_u64 v[4:5], v[44:45], 0, s[4:5]
	global_store_dword v[4:5], v6, off
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_43
.Lft21:
	s_mov_b32 s4, 0x800000
	v_mov_b32_e32 v4, 0xc1b17218
	v_cmp_gt_f32_e64 s[4:5], s4, v2
	s_nop 1
	v_cndmask_b32_e64 v4, 0, v4, s[4:5]
	s_and_b64 s[4:5], s[4:5], exec
	s_cselect_b32 s4, 32, 0
	v_ldexp_f32 v2, v2, s4
	v_log_f32_e32 v2, v2
	s_ashr_i32 s85, s84, 31
	s_lshl_b64 s[4:5], s[84:85], 2
	s_add_u32 s4, s34, s4
	v_fmamk_f32 v2, v2, 0x3f317218, v4
	v_add_f32_e32 v2, v2, v40
	s_addc_u32 s5, s35, s5
	v_mov_b32_e32 v4, 0
	global_store_dword v4, v2, s[4:5] offset:8
.LBB0_43:
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	ds_write_b32 v47, v73
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], s[2:3]
	s_cbranch_execz .LBB0_45
.Lft22:
	ds_read_b128 v[4:7], v1 offset:40960
	ds_read_b128 v[8:11], v1 offset:40976
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	s_nop 0
	v_pk_add_f32 v[4:5], v[4:5], v[6:7]
	s_nop 0
	v_add_f32_e32 v1, v4, v5
	ds_write_b32 v47, v1 offset:1024
.LBB0_45:
	s_or_b64 exec, exec, s[4:5]
	v_mov_b32_e32 v1, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[34:37], v1 offset:41984
	ds_read_b128 v[30:33], v1 offset:42000
	ds_read_b128 v[26:29], v1 offset:42016
	ds_read_b128 v[22:25], v1 offset:42032
	ds_read_b128 v[18:21], v1 offset:42048
	ds_read_b128 v[14:17], v1 offset:42064
	ds_read_b128 v[10:13], v1 offset:42080
	ds_read_b128 v[6:9], v1 offset:42096
	s_cmp_lt_i32 s86, s28
	s_cselect_b64 s[2:3], -1, 0
	v_mov_b32_e32 v2, v79
	v_mov_b32_e32 v4, v77
	v_mov_b32_e32 v5, v75
	s_and_b64 s[2:3], s[0:1], s[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write_b128 v0, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execz .LBB0_48
.Lft23:
	v_add_f32_e32 v0, v35, v34
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
	v_add_f32_e32 v0, v0, v7
	v_add_f32_e32 v0, v0, v8
	v_add_f32_e32 v0, v0, v9
	ds_read2st64_b32 v[2:3], v46 offset0:6 offset1:7
	ds_read2st64_b32 v[4:5], v46 offset0:4 offset1:5
	ds_read2st64_b32 v[6:7], v46 offset0:2 offset1:3
	ds_read2st64_b32 v[8:9], v46 offset1:1
	ds_read2st64_b32 v[10:11], v46 offset0:14 offset1:15
	ds_read2st64_b32 v[12:13], v46 offset0:12 offset1:13
	ds_read2st64_b32 v[14:15], v46 offset0:10 offset1:11
	ds_read2st64_b32 v[16:17], v46 offset0:8 offset1:9
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v8, v9, v8
	v_add_f32_e32 v6, v6, v8
	v_add_f32_e32 v6, v7, v6
	v_add_f32_e32 v4, v4, v6
	v_add_f32_e32 v4, v5, v4
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v3, v2
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v16, v2
	v_add_f32_e32 v2, v17, v2
	v_add_f32_e32 v2, v14, v2
	v_add_f32_e32 v2, v15, v2
	v_rcp_f32_e32 v1, v0
	v_add_f32_e32 v2, v12, v2
	v_add_f32_e32 v2, v13, v2
	v_add_f32_e32 v2, v10, v2
	s_ashr_i32 s87, s86, 31
	v_add_f32_e32 v2, v11, v2
	s_lshl_b64 s[2:3], s[86:87], 8
	v_mul_f32_e32 v1, v1, v2
	v_lshl_add_u64 v[2:3], v[44:45], 0, s[2:3]
	global_store_dword v[2:3], v1, off
	s_and_b64 exec, exec, vcc
	s_cbranch_execz .LBB0_48
.Lft24:
	s_mov_b32 s2, 0x800000
	v_cmp_gt_f32_e32 vcc, s2, v0
	s_and_b64 s[2:3], vcc, exec
	s_cselect_b32 s2, 32, 0
	v_ldexp_f32 v0, v0, s2
	v_log_f32_e32 v0, v0
	v_mov_b32_e32 v1, 0xc1b17218
	s_ashr_i32 s85, s84, 31
	v_cndmask_b32_e32 v1, 0, v1, vcc
	s_lshl_b64 s[2:3], s[84:85], 2
	v_fmamk_f32 v0, v0, 0x3f317218, v1
	s_add_u32 s2, s34, s2
	v_add_f32_e32 v0, v0, v41
	s_addc_u32 s3, s35, s3
	v_mov_b32_e32 v1, 0
	global_store_dword v1, v0, s[2:3] offset:12
.LBB0_48:
	s_or_b64 exec, exec, s[0:1]
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
		.amdhsa_next_free_vgpr 165
		.amdhsa_next_free_sgpr 99
		.amdhsa_accum_offset 168
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
  .sgpr_count: 105
  .sgpr_spill_count: 0
  .symbol: fa_attention.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 165
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
