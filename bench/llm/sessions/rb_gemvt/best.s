	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.text
	.protected	rb_gemvt
	.globl	rb_gemvt
	.p2align	8
	.type	rb_gemvt,@function
rb_gemvt:
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_waitcnt lgkmcnt(0)
	s_load_dword s11, s[0:1], 0x28
	v_cmp_eq_f32_e64 s[4:5], s10, 0
	s_waitcnt lgkmcnt(0)
	v_cmp_eq_f32_e64 s[6:7], s11, 1.0
	s_and_b64 s[6:7], s[4:5], s[6:7]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccnz .LBB0_53
.Lft0:
	s_load_dwordx2 s[6:7], s[0:1], 0x30
	s_lshl_b32 s12, s2, 2
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccz .LBB0_12
.Lft1:
	v_cmp_eq_u32_e32 vcc, 0, v0
	s_mov_b64 s[14:15], 0
	s_mov_b64 s[2:3], 0
	s_and_saveexec_b64 s[16:17], vcc
	s_cbranch_execz .LBB0_13
.Lft2:
	v_cmp_neq_f32_e64 s[2:3], s11, 0
	v_cmp_eq_f32_e64 s[4:5], s11, 0
	s_cmp_ge_i32 s12, s9
	v_cndmask_b32_e64 v1, 0, 1, s[2:3]
	v_cmp_ne_u32_e64 s[2:3], 1, v1
	s_cbranch_scc1 .LBB0_7
.Lft3:
	s_ashr_i32 s13, s12, 31
	v_mov_b32_e32 v1, 0
	s_and_b64 vcc, exec, s[2:3]
	v_mov_b32_e32 v2, 0
	s_cbranch_vccnz .LBB0_6
.Lft4:
	s_lshl_b64 s[18:19], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s18, s6, s18
	s_addc_u32 s19, s7, s19
	s_load_dword s18, s[18:19], 0x0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v2, s18
	v_mul_f32_e32 v2, s11, v2
.LBB0_6:
	s_lshl_b64 s[18:19], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s18, s6, s18
	s_addc_u32 s19, s7, s19
	global_store_dword v1, v2, s[18:19]
.LBB0_7:
	s_or_b32 s13, s12, 1
	v_cndmask_b32_e64 v1, 0, 1, s[4:5]
	s_cmp_ge_i32 s13, s9
	v_cmp_ne_u32_e64 s[4:5], 1, v1
	s_cbranch_scc0 .LBB0_15
.Lft5:
	s_or_b32 s13, s12, 2
	s_cmp_ge_i32 s13, s9
	s_cbranch_scc0 .LBB0_21
.LBB0_9:
	s_or_b32 s4, s12, 3
	s_cmp_ge_i32 s4, s9
	s_cbranch_scc1 .LBB0_27
.LBB0_10:
	s_and_b64 vcc, exec, s[2:3]
	s_ashr_i32 s5, s4, 31
	s_cbranch_vccnz .LBB0_28
.Lft6:
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[2:3], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s2, s6, s2
	s_addc_u32 s3, s7, s3
	v_mov_b32_e32 v1, 0
	global_load_dword v1, v1, s[2:3] offset:12
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v1, s11, v1
	s_branch .LBB0_29
.LBB0_12:
	s_mov_b64 s[2:3], 0
	s_cbranch_execz .LBB0_14
.Lft7:
	s_branch .LBB0_31
.LBB0_13:
	s_or_b64 exec, exec, s[16:17]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccnz .LBB0_31
.LBB0_14:
	v_mov_b64_e32 v[2:3], s[4:5]
	s_and_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execnz .LBB0_52
.Lft8:
	s_branch .LBB0_53
.LBB0_15:
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_17
.Lft9:
	s_ashr_i32 s13, s12, 31
	s_mov_b64 s[18:19], 0
	s_branch .LBB0_18
.LBB0_17:
	s_mov_b64 s[18:19], -1
.LBB0_18:
	v_mov_b32_e32 v1, 0
	s_andn2_b64 vcc, exec, s[18:19]
	v_mov_b32_e32 v2, 0
	s_cbranch_vccnz .LBB0_20
.Lft10:
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[18:19], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s18, s6, s18
	s_addc_u32 s19, s7, s19
	v_mov_b32_e32 v2, 0
	global_load_dword v2, v2, s[18:19] offset:4
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, s11, v2
.LBB0_20:
	s_lshl_b64 s[18:19], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s18, s6, s18
	s_addc_u32 s19, s7, s19
	global_store_dword v1, v2, s[18:19] offset:4
	s_or_b32 s13, s12, 2
	s_cmp_ge_i32 s13, s9
	s_cbranch_scc1 .LBB0_9
.LBB0_21:
	s_and_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_23
.Lft11:
	s_ashr_i32 s13, s12, 31
	s_mov_b64 s[4:5], 0
	s_branch .LBB0_24
.LBB0_23:
	s_mov_b64 s[4:5], -1
.LBB0_24:
	v_mov_b32_e32 v1, 0
	s_andn2_b64 vcc, exec, s[4:5]
	v_mov_b32_e32 v2, 0
	s_cbranch_vccnz .LBB0_26
.Lft12:
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[4:5], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s4, s6, s4
	s_addc_u32 s5, s7, s5
	v_mov_b32_e32 v2, 0
	global_load_dword v2, v2, s[4:5] offset:8
	s_waitcnt vmcnt(0)
	v_mul_f32_e32 v2, s11, v2
.LBB0_26:
	s_lshl_b64 s[4:5], s[12:13], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s4, s6, s4
	s_addc_u32 s5, s7, s5
	global_store_dword v1, v2, s[4:5] offset:8
	s_or_b32 s4, s12, 3
	s_cmp_ge_i32 s4, s9
	s_cbranch_scc0 .LBB0_10
.LBB0_27:
	s_mov_b64 s[2:3], 0
	s_branch .LBB0_30
.LBB0_28:
	v_mov_b32_e32 v1, 0
.LBB0_29:
	s_mov_b64 s[2:3], -1
.LBB0_30:
	s_and_b64 s[2:3], s[2:3], exec
	s_or_b64 exec, exec, s[16:17]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_14
.LBB0_31:
	s_load_dword s13, s[0:1], 0x18
	s_load_dwordx2 s[14:15], s[0:1], 0x10
	s_load_dwordx2 s[4:5], s[0:1], 0x20
	s_add_i32 s0, s9, -1
	s_min_i32 s1, s12, s0
	s_waitcnt lgkmcnt(0)
	s_mul_hi_i32 s17, s1, s13
	s_mul_i32 s16, s1, s13
	s_ashr_i32 s30, s13, 31
	s_lshl_b64 s[16:17], s[16:17], 2
	s_add_u32 s18, s14, s16
	s_addc_u32 s19, s15, s17
	s_or_b32 s1, s12, 1
	s_min_i32 s1, s1, s0
	s_mul_hi_i32 s21, s1, s13
	s_mul_i32 s20, s1, s13
	s_lshl_b64 s[20:21], s[20:21], 2
	s_add_u32 s20, s14, s20
	s_addc_u32 s21, s15, s21
	s_or_b32 s1, s12, 2
	s_min_i32 s1, s1, s0
	s_mul_hi_i32 s23, s1, s13
	s_mul_i32 s22, s1, s13
	s_lshl_b64 s[22:23], s[22:23], 2
	s_add_u32 s22, s14, s22
	s_addc_u32 s23, s15, s23
	s_or_b32 s1, s12, 3
	s_min_i32 s1, s1, s0
	s_mul_hi_i32 s25, s1, s13
	s_mul_i32 s24, s1, s13
	s_lshl_b64 s[24:25], s[24:25], 2
	v_lshlrev_b32_e32 v1, 2, v0
	s_add_u32 s24, s14, s24
	v_add_u32_e32 v2, 0x1004, v1
	s_addc_u32 s25, s15, s25
	v_cmp_ge_i32_e32 vcc, s8, v2
	v_mov_b32_e32 v21, 0
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v18, v1
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_35
.Lft13:
	v_mov_b32_e32 v14, 0
	s_mov_b64 s[28:29], 0
	s_movk_i32 s1, 0x4000
	v_mov_b32_e32 v20, v1
	v_mov_b32_e32 v15, v14
	v_mov_b32_e32 v10, v14
	v_mov_b32_e32 v11, v14
	v_mov_b32_e32 v16, v14
	v_mov_b32_e32 v17, v14
	v_mov_b32_e32 v12, v14
	v_mov_b32_e32 v13, v14
	v_mov_b32_e32 v6, v14
	v_mov_b32_e32 v7, v14
	v_mov_b32_e32 v2, v14
	v_mov_b32_e32 v3, v14
	v_mov_b32_e32 v8, v14
	v_mov_b32_e32 v9, v14
	v_mov_b32_e32 v4, v14
	v_mov_b32_e32 v5, v14
	.p2align	5, , 4
.LBB0_33:
	v_lshlrev_b64 v[18:19], 2, v[20:21]
	v_lshl_add_u64 v[42:43], s[4:5], 0, v[18:19]
	v_add_co_u32_e32 v54, vcc, s1, v42
	v_lshl_add_u64 v[44:45], s[18:19], 0, v[18:19]
	s_nop 0
	v_addc_co_u32_e32 v55, vcc, 0, v43, vcc
	v_add_co_u32_e32 v56, vcc, s1, v44
	v_lshl_add_u64 v[46:47], s[20:21], 0, v[18:19]
	s_nop 0
	v_addc_co_u32_e32 v57, vcc, 0, v45, vcc
	v_add_co_u32_e32 v58, vcc, s1, v46
	v_lshl_add_u64 v[48:49], s[22:23], 0, v[18:19]
	s_nop 0
	v_addc_co_u32_e32 v59, vcc, 0, v47, vcc
	v_add_co_u32_e32 v62, vcc, s1, v48
	v_lshl_add_u64 v[18:19], s[24:25], 0, v[18:19]
	s_nop 0
	v_addc_co_u32_e32 v63, vcc, 0, v49, vcc
	global_load_dwordx4 v[22:25], v[42:43], off
	global_load_dwordx4 v[26:29], v[44:45], off
	global_load_dwordx4 v[30:33], v[46:47], off
	global_load_dwordx4 v[34:37], v[48:49], off
	global_load_dwordx4 v[38:41], v[18:19], off
	v_add_co_u32_e32 v18, vcc, s1, v18
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[14:15], v[26:27], v[22:23], v[14:15]
	v_addc_co_u32_e32 v19, vcc, 0, v19, vcc
	global_load_dwordx4 v[42:45], v[54:55], off
	global_load_dwordx4 v[46:49], v[58:59], off
	global_load_dwordx4 v[50:53], v[56:57], off
	s_nop 0
	global_load_dwordx4 v[54:57], v[18:19], off
	global_load_dwordx4 v[58:61], v[62:63], off
	v_add_u32_e32 v18, 0x3004, v20
	v_cmp_lt_i32_e32 vcc, s8, v18
	v_add_u32_e32 v18, 0x2000, v20
	s_waitcnt vmcnt(7)
	v_pk_fma_f32 v[16:17], v[30:31], v[22:23], v[16:17]
	v_pk_fma_f32 v[10:11], v[28:29], v[24:25], v[10:11]
	v_pk_fma_f32 v[12:13], v[32:33], v[24:25], v[12:13]
	s_waitcnt vmcnt(6)
	v_pk_fma_f32 v[6:7], v[34:35], v[22:23], v[6:7]
	s_waitcnt vmcnt(5)
	v_pk_fma_f32 v[8:9], v[38:39], v[22:23], v[8:9]
	v_pk_fma_f32 v[2:3], v[36:37], v[24:25], v[2:3]
	v_pk_fma_f32 v[4:5], v[40:41], v[24:25], v[4:5]
	v_mov_b32_e32 v20, v18
	s_or_b64 s[28:29], vcc, s[28:29]
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[12:13], v[48:49], v[44:45], v[12:13]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[10:11], v[52:53], v[44:45], v[10:11]
	v_pk_fma_f32 v[16:17], v[46:47], v[42:43], v[16:17]
	v_pk_fma_f32 v[14:15], v[50:51], v[42:43], v[14:15]
	s_waitcnt vmcnt(1)
	v_pk_fma_f32 v[4:5], v[56:57], v[44:45], v[4:5]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[2:3], v[60:61], v[44:45], v[2:3]
	v_pk_fma_f32 v[8:9], v[54:55], v[42:43], v[8:9]
	v_pk_fma_f32 v[6:7], v[58:59], v[42:43], v[6:7]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB0_33
.Lft14:
	s_or_b64 exec, exec, s[28:29]
	v_mov_b32_e32 v21, v5
.LBB0_35:
	s_or_b64 exec, exec, s[26:27]
	v_add_u32_e32 v19, 4, v18
	v_mov_b32_e32 v5, v21
	v_cmp_ge_i32_e32 vcc, s8, v19
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_39
.Lft15:
	s_mov_b64 s[28:29], 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v5, v21
	.p2align	5, , 4
.LBB0_37:
	v_lshlrev_b64 v[20:21], 2, v[18:19]
	v_lshl_add_u64 v[42:43], s[4:5], 0, v[20:21]
	v_lshl_add_u64 v[44:45], s[18:19], 0, v[20:21]
	v_lshl_add_u64 v[46:47], s[20:21], 0, v[20:21]
	v_lshl_add_u64 v[48:49], s[22:23], 0, v[20:21]
	v_lshl_add_u64 v[20:21], s[24:25], 0, v[20:21]
	global_load_dwordx4 v[22:25], v[42:43], off
	global_load_dwordx4 v[26:29], v[46:47], off
	global_load_dwordx4 v[30:33], v[44:45], off
	global_load_dwordx4 v[34:37], v[20:21], off
	global_load_dwordx4 v[38:41], v[48:49], off
	v_add_u32_e32 v20, 0x1000, v18
	v_add_u32_e32 v18, 0x1004, v18
	v_cmp_lt_i32_e32 vcc, s8, v18
	v_mov_b32_e32 v18, v20
	s_or_b64 s[28:29], vcc, s[28:29]
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[12:13], v[24:25], v[28:29], v[12:13]
	v_pk_fma_f32 v[16:17], v[22:23], v[26:27], v[16:17]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[10:11], v[24:25], v[32:33], v[10:11]
	v_pk_fma_f32 v[14:15], v[22:23], v[30:31], v[14:15]
	s_waitcnt vmcnt(1)
	v_pk_fma_f32 v[4:5], v[24:25], v[36:37], v[4:5]
	v_pk_fma_f32 v[8:9], v[22:23], v[34:35], v[8:9]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[2:3], v[24:25], v[40:41], v[2:3]
	v_pk_fma_f32 v[6:7], v[22:23], v[38:39], v[6:7]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB0_37
.Lft16:
	s_or_b64 exec, exec, s[28:29]
	v_mov_b32_e32 v18, v20
.LBB0_39:
	s_or_b64 exec, exec, s[26:27]
	v_mov_b32_e32 v20, v16
	v_mov_b32_e32 v21, v14
	v_mov_b32_e32 v14, v17
	v_mov_b32_e32 v16, v12
	v_mov_b32_e32 v17, v10
	v_mov_b32_e32 v10, v13
	v_mov_b32_e32 v12, v8
	v_mov_b32_e32 v13, v6
	v_mov_b32_e32 v6, v9
	v_mov_b32_e32 v8, v4
	v_mov_b32_e32 v9, v2
	v_mov_b32_e32 v2, v5
	v_pk_add_f32 v[14:15], v[20:21], v[14:15]
	v_pk_add_f32 v[10:11], v[16:17], v[10:11]
	v_pk_add_f32 v[6:7], v[12:13], v[6:7]
	v_pk_add_f32 v[2:3], v[8:9], v[2:3]
	v_pk_add_f32 v[10:11], v[14:15], v[10:11]
	v_pk_add_f32 v[2:3], v[6:7], v[2:3]
	v_cmp_gt_i32_e32 vcc, s8, v18
	s_and_saveexec_b64 s[18:19], vcc
	s_cbranch_execz .LBB0_43
.Lft17:
	v_mov_b32_e32 v19, 0
	s_add_u32 s16, s14, s16
	v_sub_u32_e32 v16, s8, v18
	v_lshlrev_b64 v[14:15], 2, v[18:19]
	s_addc_u32 s17, s15, s17
	s_ashr_i32 s8, s12, 31
	v_lshl_add_u64 v[4:5], s[16:17], 0, v[14:15]
	s_add_u32 s16, s12, 1
	s_addc_u32 s17, s8, 0
	s_ashr_i32 s1, s0, 31
	v_mov_b64_e32 v[12:13], s[0:1]
	v_cmp_lt_i64_e32 vcc, s[16:17], v[12:13]
	s_and_b64 s[20:21], vcc, exec
	s_cselect_b32 s16, s16, s0
	s_cselect_b32 s17, s17, s1
	s_mul_i32 s20, s16, s30
	s_mul_hi_u32 s21, s16, s13
	s_add_i32 s20, s21, s20
	s_mul_i32 s17, s17, s13
	s_add_i32 s17, s20, s17
	s_mul_i32 s16, s16, s13
	s_lshl_b64 s[16:17], s[16:17], 2
	s_add_u32 s16, s14, s16
	s_addc_u32 s17, s15, s17
	v_lshl_add_u64 v[6:7], s[16:17], 0, v[14:15]
	s_add_u32 s16, s12, 2
	s_addc_u32 s17, s8, 0
	v_cmp_lt_i64_e32 vcc, s[16:17], v[12:13]
	s_and_b64 s[20:21], vcc, exec
	s_cselect_b32 s16, s16, s0
	s_cselect_b32 s17, s17, s1
	s_mul_i32 s20, s16, s30
	s_mul_hi_u32 s21, s16, s13
	s_add_i32 s20, s21, s20
	s_mul_i32 s17, s17, s13
	s_add_i32 s17, s20, s17
	s_mul_i32 s16, s16, s13
	s_lshl_b64 s[16:17], s[16:17], 2
	s_add_u32 s16, s14, s16
	s_addc_u32 s17, s15, s17
	v_lshl_add_u64 v[8:9], s[16:17], 0, v[14:15]
	s_add_u32 s16, s12, 3
	s_addc_u32 s17, s8, 0
	v_cmp_lt_i64_e32 vcc, s[16:17], v[12:13]
	s_and_b64 s[20:21], vcc, exec
	s_cselect_b32 s0, s16, s0
	s_cselect_b32 s1, s17, s1
	s_mul_i32 s8, s0, s30
	s_mul_hi_u32 s16, s0, s13
	s_add_i32 s8, s16, s8
	s_mul_i32 s1, s1, s13
	s_add_i32 s1, s8, s1
	s_mul_i32 s0, s0, s13
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s14, s0
	s_addc_u32 s1, s15, s1
	v_lshl_add_u64 v[12:13], s[0:1], 0, v[14:15]
	v_lshl_add_u64 v[14:15], s[4:5], 0, v[14:15]
	s_mov_b64 s[0:1], 0
	.p2align	5, , 4
.LBB0_41:
	global_load_dword v18, v[14:15], off
	global_load_dword v21, v[4:5], off
	global_load_dword v20, v[6:7], off
	global_load_dword v23, v[8:9], off
	global_load_dword v22, v[12:13], off
	v_add_u32_e32 v16, -1, v16
	v_cmp_eq_u32_e32 vcc, 0, v16
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	v_lshl_add_u64 v[6:7], v[6:7], 0, 4
	v_lshl_add_u64 v[8:9], v[8:9], 0, 4
	v_lshl_add_u64 v[12:13], v[12:13], 0, 4
	v_lshl_add_u64 v[14:15], v[14:15], 0, 4
	s_or_b64 s[0:1], vcc, s[0:1]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[10:11], v[18:19], v[20:21], v[10:11] op_sel_hi:[0,1,1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[2:3], v[18:19], v[22:23], v[2:3] op_sel_hi:[0,1,1]
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB0_41
.Lft18:
	s_or_b64 exec, exec, s[0:1]
.LBB0_43:
	s_or_b64 exec, exec, s[18:19]
	v_cmp_gt_u32_e32 vcc, 16, v0
	ds_write2st64_b32 v1, v11, v10 offset1:16
	ds_write2st64_b32 v1, v3, v2 offset0:32 offset1:48
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_45
.Lft19:
	ds_read2_b32 v[2:3], v1 offset1:16
	ds_read2_b32 v[4:5], v1 offset0:32 offset1:48
	ds_read2_b32 v[6:7], v1 offset0:64 offset1:80
	ds_read2_b32 v[8:9], v1 offset0:96 offset1:112
	ds_read2_b32 v[10:11], v1 offset0:128 offset1:144
	s_waitcnt lgkmcnt(4)
	v_add_f32_e32 v2, 0, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v2, v2, v4
	v_add_f32_e32 v2, v2, v5
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v2, v8
	ds_read2_b32 v[2:3], v1 offset0:160 offset1:176
	v_add_f32_e32 v4, v4, v9
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v10
	ds_read2_b32 v[4:5], v1 offset0:192 offset1:208
	v_add_f32_e32 v6, v6, v11
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v6, v2, v3
	ds_read2_b32 v[2:3], v1 offset0:224 offset1:240
	v_add_u32_e32 v8, 0x400, v1
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset1:16
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	ds_read2_b32 v[4:5], v8 offset0:32 offset1:48
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v2, v6
	ds_read2_b32 v[2:3], v8 offset0:64 offset1:80
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset0:96 offset1:112
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	ds_read2_b32 v[4:5], v8 offset0:128 offset1:144
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v2, v6
	ds_read2_b32 v[2:3], v8 offset0:160 offset1:176
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset0:192 offset1:208
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	v_add_f32_e32 v4, v2, v3
	ds_read2_b32 v[2:3], v8 offset0:224 offset1:240
	v_add_u32_e32 v8, 0x800, v1
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v8 offset1:16
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	ds_read2_b32 v[6:7], v8 offset0:32 offset1:48
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v8 offset0:64 offset1:80
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v8 offset0:96 offset1:112
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v6, v2, v3
	ds_read2_b32 v[2:3], v8 offset0:128 offset1:144
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset0:160 offset1:176
	v_add_f32_e32 v9, v4, v5
	ds_read2_b32 v[4:5], v8 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v9, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v8 offset0:224 offset1:240
	v_add_u32_e32 v11, 0xc00, v1
	ds_read2_b32 v[6:7], v11 offset1:16
	v_add_f32_e32 v8, v4, v5
	ds_read2_b32 v[4:5], v11 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v8, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v2, v4
	v_add_u32_e32 v22, 0x1000, v1
	v_add_f32_e32 v10, v2, v5
	ds_read2_b32 v[16:17], v22 offset1:16
	ds_read2_b32 v[14:15], v11 offset0:160 offset1:176
	ds_read2_b32 v[8:9], v11 offset0:192 offset1:208
	ds_read2_b32 v[18:19], v22 offset0:32 offset1:48
	ds_read2_b32 v[4:5], v11 offset0:224 offset1:240
	ds_read2_b32 v[20:21], v22 offset0:64 offset1:80
	ds_read2_b32 v[12:13], v11 offset0:64 offset1:80
	ds_read2_b32 v[6:7], v11 offset0:96 offset1:112
	ds_read2_b32 v[2:3], v11 offset0:128 offset1:144
	s_waitcnt lgkmcnt(8)
	v_add_f32_e32 v11, 0, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:96 offset1:112
	s_waitcnt lgkmcnt(6)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v22 offset0:128 offset1:144
	s_waitcnt lgkmcnt(5)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v22 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v22 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_u32_e32 v22, 0x1400, v1
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v22 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v22 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v22 offset0:96 offset1:112
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:128 offset1:144
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v22 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v22 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_u32_e32 v22, 0x1800, v1
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v22 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v22 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v11, v11, v20
	ds_read2_b32 v[18:19], v22 offset0:96 offset1:112
	v_add_f32_e32 v11, v11, v21
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:128 offset1:144
	ds_read2_b32 v[20:21], v22 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v22 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	ds_read2_b32 v[16:17], v22 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_u32_e32 v26, 0x1c00, v1
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v26 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v26 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v16
	v_add_f32_e32 v11, v11, v17
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[16:17], v26 offset0:64 offset1:80
	ds_read2_b32 v[18:19], v26 offset0:96 offset1:112
	ds_read2_b32 v[20:21], v26 offset0:128 offset1:144
	ds_read2_b32 v[22:23], v26 offset0:160 offset1:176
	ds_read2_b32 v[24:25], v26 offset0:192 offset1:208
	ds_read2_b32 v[26:27], v26 offset0:224 offset1:240
	v_mov_b32_e32 v28, v12
	s_waitcnt lgkmcnt(5)
	v_mov_b32_e32 v29, v16
	v_pk_add_f32 v[10:11], v[10:11], v[28:29]
	v_mov_b32_e32 v16, v13
	v_pk_add_f32 v[10:11], v[10:11], v[16:17]
	v_mov_b32_e32 v12, v6
	s_waitcnt lgkmcnt(4)
	v_mov_b32_e32 v13, v18
	v_pk_add_f32 v[10:11], v[10:11], v[12:13]
	v_mov_b32_e32 v18, v7
	v_pk_add_f32 v[6:7], v[10:11], v[18:19]
	v_mov_b32_e32 v10, v2
	s_waitcnt lgkmcnt(3)
	v_mov_b32_e32 v11, v20
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_mov_b32_e32 v20, v3
	v_pk_add_f32 v[2:3], v[6:7], v[20:21]
	v_mov_b32_e32 v6, v14
	s_waitcnt lgkmcnt(2)
	v_mov_b32_e32 v7, v22
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	v_mov_b32_e32 v22, v15
	v_pk_add_f32 v[2:3], v[2:3], v[22:23]
	v_mov_b32_e32 v6, v8
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v7, v24
	v_add_u32_e32 v8, 0x2000, v1
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	v_mov_b32_e32 v24, v9
	v_mov_b32_e32 v6, v4
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v7, v26
	v_mov_b32_e32 v26, v5
	ds_read2_b32 v[4:5], v8 offset1:16
	v_pk_add_f32 v[2:3], v[2:3], v[24:25]
	v_add_u32_e32 v16, 0x4000, v1
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	ds_read2_b32 v[6:7], v8 offset0:32 offset1:48
	v_pk_add_f32 v[2:3], v[2:3], v[26:27]
	ds_write2_b32 v16, v2, v3 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v4, 0, v4
	ds_read2_b32 v[2:3], v8 offset0:64 offset1:80
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v8 offset0:96 offset1:112
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	ds_read2_b32 v[6:7], v8 offset0:128 offset1:144
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v8 offset0:160 offset1:176
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v8 offset0:192 offset1:208
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v6, v2, v3
	ds_read2_b32 v[2:3], v8 offset0:224 offset1:240
	v_add_u32_e32 v8, 0x2400, v1
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset1:16
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	ds_read2_b32 v[4:5], v8 offset0:32 offset1:48
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v2, v6
	ds_read2_b32 v[2:3], v8 offset0:64 offset1:80
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset0:96 offset1:112
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	ds_read2_b32 v[4:5], v8 offset0:128 offset1:144
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v2, v6
	ds_read2_b32 v[2:3], v8 offset0:160 offset1:176
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset0:192 offset1:208
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v4, v2
	v_add_f32_e32 v4, v2, v3
	ds_read2_b32 v[2:3], v8 offset0:224 offset1:240
	v_add_u32_e32 v8, 0x2800, v1
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v8 offset1:16
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	ds_read2_b32 v[6:7], v8 offset0:32 offset1:48
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v8 offset0:64 offset1:80
	v_add_f32_e32 v4, v4, v5
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v6, v4, v6
	ds_read2_b32 v[4:5], v8 offset0:96 offset1:112
	v_add_f32_e32 v6, v6, v7
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v6, v2
	v_add_f32_e32 v6, v2, v3
	ds_read2_b32 v[2:3], v8 offset0:128 offset1:144
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v4, v6, v4
	ds_read2_b32 v[6:7], v8 offset0:160 offset1:176
	v_add_f32_e32 v9, v4, v5
	ds_read2_b32 v[4:5], v8 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v9, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v4, v2, v4
	ds_read2_b32 v[2:3], v8 offset0:224 offset1:240
	v_add_u32_e32 v11, 0x2c00, v1
	ds_read2_b32 v[6:7], v11 offset1:16
	v_add_f32_e32 v8, v4, v5
	ds_read2_b32 v[4:5], v11 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v2, v8, v2
	v_add_f32_e32 v2, v2, v3
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v2, v2, v6
	v_add_f32_e32 v2, v2, v7
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v2, v2, v4
	v_add_u32_e32 v17, 0x3000, v1
	v_add_f32_e32 v10, v2, v5
	ds_read2_b32 v[18:19], v17 offset1:16
	ds_read2_b32 v[14:15], v11 offset0:160 offset1:176
	ds_read2_b32 v[8:9], v11 offset0:192 offset1:208
	ds_read2_b32 v[20:21], v17 offset0:32 offset1:48
	ds_read2_b32 v[4:5], v11 offset0:224 offset1:240
	ds_read2_b32 v[22:23], v17 offset0:64 offset1:80
	ds_read2_b32 v[12:13], v11 offset0:64 offset1:80
	ds_read2_b32 v[6:7], v11 offset0:96 offset1:112
	ds_read2_b32 v[2:3], v11 offset0:128 offset1:144
	s_waitcnt lgkmcnt(8)
	v_add_f32_e32 v11, 0, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:96 offset1:112
	s_waitcnt lgkmcnt(6)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v17 offset0:128 offset1:144
	s_waitcnt lgkmcnt(5)
	v_add_f32_e32 v11, v11, v22
	v_add_f32_e32 v11, v11, v23
	ds_read2_b32 v[22:23], v17 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v17 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v22
	v_add_u32_e32 v17, 0x3400, v1
	v_add_f32_e32 v11, v11, v23
	ds_read2_b32 v[22:23], v17 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v17 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v22
	v_add_f32_e32 v11, v11, v23
	ds_read2_b32 v[22:23], v17 offset0:96 offset1:112
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:128 offset1:144
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v17 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v22
	v_add_f32_e32 v11, v11, v23
	ds_read2_b32 v[22:23], v17 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_u32_e32 v17, 0x3800, v1
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v17 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v22
	v_add_f32_e32 v11, v11, v23
	ds_read2_b32 v[22:23], v17 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:64 offset1:80
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v11, v11, v22
	ds_read2_b32 v[20:21], v17 offset0:96 offset1:112
	v_add_f32_e32 v11, v11, v23
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:128 offset1:144
	ds_read2_b32 v[22:23], v17 offset0:160 offset1:176
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v17 offset0:192 offset1:208
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	ds_read2_b32 v[18:19], v17 offset0:224 offset1:240
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v22
	v_add_u32_e32 v1, 0x3c00, v1
	v_add_f32_e32 v11, v11, v23
	ds_read2_b32 v[22:23], v1 offset1:16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[20:21], v1 offset0:32 offset1:48
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v11, v11, v18
	v_add_f32_e32 v11, v11, v19
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v11, v11, v22
	v_add_f32_e32 v11, v11, v23
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v11, v11, v20
	v_add_f32_e32 v11, v11, v21
	ds_read2_b32 v[18:19], v1 offset0:64 offset1:80
	ds_read2_b32 v[20:21], v1 offset0:96 offset1:112
	ds_read2_b32 v[22:23], v1 offset0:128 offset1:144
	ds_read2_b32 v[24:25], v1 offset0:160 offset1:176
	ds_read2_b32 v[26:27], v1 offset0:192 offset1:208
	ds_read2_b32 v[28:29], v1 offset0:224 offset1:240
	v_mov_b32_e32 v30, v12
	s_waitcnt lgkmcnt(5)
	v_mov_b32_e32 v31, v18
	v_pk_add_f32 v[10:11], v[10:11], v[30:31]
	v_mov_b32_e32 v18, v13
	v_pk_add_f32 v[10:11], v[10:11], v[18:19]
	v_mov_b32_e32 v12, v6
	s_waitcnt lgkmcnt(4)
	v_mov_b32_e32 v13, v20
	v_pk_add_f32 v[10:11], v[10:11], v[12:13]
	v_mov_b32_e32 v20, v7
	v_pk_add_f32 v[6:7], v[10:11], v[20:21]
	v_mov_b32_e32 v10, v2
	s_waitcnt lgkmcnt(3)
	v_mov_b32_e32 v11, v22
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_mov_b32_e32 v22, v3
	v_pk_add_f32 v[2:3], v[6:7], v[22:23]
	v_mov_b32_e32 v6, v14
	s_waitcnt lgkmcnt(2)
	v_mov_b32_e32 v7, v24
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	v_mov_b32_e32 v24, v15
	v_pk_add_f32 v[2:3], v[2:3], v[24:25]
	v_mov_b32_e32 v6, v8
	s_waitcnt lgkmcnt(1)
	v_mov_b32_e32 v7, v26
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	v_mov_b32_e32 v26, v9
	v_pk_add_f32 v[2:3], v[2:3], v[26:27]
	v_mov_b32_e32 v6, v4
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v7, v28
	v_pk_add_f32 v[2:3], v[2:3], v[6:7]
	v_mov_b32_e32 v28, v5
	v_pk_add_f32 v[2:3], v[2:3], v[28:29]
	ds_write2_b32 v16, v2, v3 offset0:32 offset1:48
.LBB0_45:
	s_or_b64 exec, exec, s[0:1]
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_51
.Lft20:
	v_or_b32_e32 v2, s12, v0
	v_cmp_gt_i32_e32 vcc, s9, v2
	s_mov_b64 s[8:9], s[2:3]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_50
.Lft21:
	v_lshlrev_b32_e32 v0, 6, v0
	ds_read_b128 v[4:7], v0 offset:16384
	ds_read_b128 v[8:11], v0 offset:16400
	ds_read_b128 v[12:15], v0 offset:16416
	ds_read_b128 v[16:19], v0 offset:16432
	v_cmp_eq_f32_e64 s[8:9], s11, 0
	v_ashrrev_i32_e32 v3, 31, v2
	s_and_b64 vcc, exec, s[8:9]
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v0, 0, v4
	v_add_f32_e32 v0, v0, v5
	v_add_f32_e32 v0, v0, v6
	v_add_f32_e32 v0, v0, v7
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v0, v0, v8
	v_add_f32_e32 v0, v0, v9
	v_add_f32_e32 v0, v0, v10
	v_add_f32_e32 v0, v0, v11
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v0, v0, v12
	v_add_f32_e32 v0, v0, v13
	v_add_f32_e32 v0, v0, v14
	v_add_f32_e32 v0, v0, v15
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v0, v0, v16
	v_add_f32_e32 v0, v0, v17
	v_add_f32_e32 v0, v0, v18
	v_add_f32_e32 v0, v0, v19
	v_mul_f32_e32 v1, s10, v0
	s_cbranch_vccnz .LBB0_49
.Lft22:
	v_lshl_add_u64 v[4:5], v[2:3], 2, s[6:7]
	global_load_dword v0, v[4:5], off
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, s11, v0
.LBB0_49:
	s_or_b64 s[8:9], s[2:3], exec
.LBB0_50:
	s_or_b64 exec, exec, s[4:5]
	s_andn2_b64 s[2:3], s[2:3], exec
	s_and_b64 s[4:5], s[8:9], exec
	s_or_b64 s[2:3], s[2:3], s[4:5]
.LBB0_51:
	s_or_b64 exec, exec, s[0:1]
	s_and_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execz .LBB0_53
.LBB0_52:
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], v[2:3], 2, s[6:7]
	global_store_dword v[2:3], v1, off
.LBB0_53:
	s_endpgm
.Lfunc_end0:
	.size	rb_gemvt, .Lfunc_end0-rb_gemvt
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel rb_gemvt
		.amdhsa_group_segment_fixed_size 16640
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
		.amdhsa_next_free_vgpr 64
		.amdhsa_next_free_sgpr 31
		.amdhsa_accum_offset 64
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
  - .offset: 0
    .size: 4
    .value_kind: by_value
  - .offset: 4
    .size: 4
    .value_kind: by_value
  - .offset: 8
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 16
    .size: 8
    .value_kind: global_buffer
  - .offset: 24
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 32
    .size: 8
    .value_kind: global_buffer
  - .offset: 40
    .size: 4
    .value_kind: by_value
  - .address_space: global
    .offset: 48
    .size: 8
    .value_kind: global_buffer
  .gfx1250_revision: B0
  .group_segment_fixed_size: 16640
  .kernarg_segment_align: 8
  .kernarg_segment_size: 56
  .language: OpenCL C
  .language_version:
  - 2
  - 0
  .max_flat_workgroup_size: 1024
  .name: rb_gemvt
  .private_segment_fixed_size: 0
  .sgpr_count: 37
  .sgpr_spill_count: 0
  .symbol: rb_gemvt.kd
  .uniform_work_group_size: 1
  .uses_dynamic_stack: false
  .vgpr_count: 64
  .vgpr_spill_count: 0
  .wavefront_size: 64
amdhsa.target: amdgcn-amd-amdhsa--gfx950
amdhsa.version:
- 1
- 2
...
	.end_amdgpu_metadata
