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
	s_cbranch_vccnz .LBB0_61
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
	v_cmp_lg_f32_e64 s[2:3], s11, 0
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
	v_mov_b32_e32 v2, s11
	s_waitcnt lgkmcnt(0)
	v_mul_f32_e32 v2, s18, v2
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
	s_cbranch_execnz .LBB0_60
.Lft8:
	s_branch .LBB0_61
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
	s_ashr_i32 s33, s13, 31
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
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v19, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v17, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v2, v1
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_35
.Lft13:
	v_mov_b32_e32 v16, 0
	s_mov_b64 s[28:29], 0
	s_movk_i32 s1, 0x4000
	v_mov_b32_e32 v20, v1
	v_mov_b32_e32 v17, v16
	v_mov_b32_e32 v14, v16
	v_mov_b32_e32 v15, v16
	v_mov_b32_e32 v18, v16
	v_mov_b32_e32 v19, v16
	v_mov_b32_e32 v12, v16
	v_mov_b32_e32 v13, v16
	v_mov_b32_e32 v8, v16
	v_mov_b32_e32 v9, v16
	v_mov_b32_e32 v6, v16
	v_mov_b32_e32 v7, v16
	v_mov_b32_e32 v10, v16
	v_mov_b32_e32 v11, v16
	v_mov_b32_e32 v4, v16
	v_mov_b32_e32 v5, v16
	.p2align	5, , 4
.LBB0_33:
	v_lshlrev_b64 v[2:3], 2, v[20:21]
	v_lshl_add_u64 v[42:43], s[4:5], 0, v[2:3]
	v_add_co_u32_e32 v54, vcc, s1, v42
	v_lshl_add_u64 v[44:45], s[18:19], 0, v[2:3]
	s_nop 0
	v_addc_co_u32_e32 v55, vcc, 0, v43, vcc
	v_add_co_u32_e32 v56, vcc, s1, v44
	v_lshl_add_u64 v[46:47], s[20:21], 0, v[2:3]
	s_nop 0
	v_addc_co_u32_e32 v57, vcc, 0, v45, vcc
	v_add_co_u32_e32 v58, vcc, s1, v46
	v_lshl_add_u64 v[48:49], s[22:23], 0, v[2:3]
	s_nop 0
	v_addc_co_u32_e32 v59, vcc, 0, v47, vcc
	v_add_co_u32_e32 v62, vcc, s1, v48
	v_lshl_add_u64 v[2:3], s[24:25], 0, v[2:3]
	s_nop 0
	v_addc_co_u32_e32 v63, vcc, 0, v49, vcc
	global_load_dwordx4 v[22:25], v[42:43], off
	global_load_dwordx4 v[26:29], v[44:45], off
	global_load_dwordx4 v[30:33], v[46:47], off
	global_load_dwordx4 v[34:37], v[48:49], off
	global_load_dwordx4 v[38:41], v[2:3], off
	v_add_co_u32_e32 v2, vcc, s1, v2
	s_nop 1
	v_addc_co_u32_e32 v3, vcc, 0, v3, vcc
	global_load_dwordx4 v[42:45], v[54:55], off
	global_load_dwordx4 v[46:49], v[58:59], off
	global_load_dwordx4 v[50:53], v[56:57], off
	s_nop 0
	global_load_dwordx4 v[54:57], v[2:3], off
	global_load_dwordx4 v[58:61], v[62:63], off
	s_waitcnt vmcnt(8)
	v_pk_fma_f32 v[16:17], v[26:27], v[22:23], v[16:17]
	v_add_u32_e32 v2, 0x3004, v20
	v_cmp_lt_i32_e32 vcc, s8, v2
	v_add_u32_e32 v2, 0x2000, v20
	s_waitcnt vmcnt(7)
	v_pk_fma_f32 v[18:19], v[30:31], v[22:23], v[18:19]
	v_pk_fma_f32 v[14:15], v[28:29], v[24:25], v[14:15]
	v_pk_fma_f32 v[12:13], v[32:33], v[24:25], v[12:13]
	s_waitcnt vmcnt(6)
	v_pk_fma_f32 v[8:9], v[34:35], v[22:23], v[8:9]
	s_waitcnt vmcnt(5)
	v_pk_fma_f32 v[10:11], v[38:39], v[22:23], v[10:11]
	v_pk_fma_f32 v[6:7], v[36:37], v[24:25], v[6:7]
	v_pk_fma_f32 v[4:5], v[40:41], v[24:25], v[4:5]
	v_mov_b32_e32 v20, v2
	s_or_b64 s[28:29], vcc, s[28:29]
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[12:13], v[48:49], v[44:45], v[12:13]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[14:15], v[52:53], v[44:45], v[14:15]
	v_pk_fma_f32 v[18:19], v[46:47], v[42:43], v[18:19]
	v_pk_fma_f32 v[16:17], v[50:51], v[42:43], v[16:17]
	s_waitcnt vmcnt(1)
	v_pk_fma_f32 v[4:5], v[56:57], v[44:45], v[4:5]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[6:7], v[60:61], v[44:45], v[6:7]
	v_pk_fma_f32 v[10:11], v[54:55], v[42:43], v[10:11]
	v_pk_fma_f32 v[8:9], v[58:59], v[42:43], v[8:9]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB0_33
.Lft14:
	s_or_b64 exec, exec, s[28:29]
	v_mov_b32_e32 v21, v5
.LBB0_35:
	s_or_b64 exec, exec, s[26:27]
	v_add_u32_e32 v3, 4, v2
	v_mov_b32_e32 v5, v21
	v_cmp_ge_i32_e32 vcc, s8, v3
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_39
.Lft15:
	s_mov_b64 s[28:29], 0
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v5, v21
	.p2align	5, , 4
.LBB0_37:
	v_lshlrev_b64 v[20:21], 2, v[2:3]
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
	v_add_u32_e32 v20, 0x1000, v2
	v_add_u32_e32 v2, 0x1004, v2
	v_cmp_lt_i32_e32 vcc, s8, v2
	v_mov_b32_e32 v2, v20
	s_or_b64 s[28:29], vcc, s[28:29]
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[12:13], v[28:29], v[24:25], v[12:13]
	v_pk_fma_f32 v[18:19], v[26:27], v[22:23], v[18:19]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[14:15], v[32:33], v[24:25], v[14:15]
	v_pk_fma_f32 v[16:17], v[30:31], v[22:23], v[16:17]
	s_waitcnt vmcnt(1)
	v_pk_fma_f32 v[4:5], v[36:37], v[24:25], v[4:5]
	v_pk_fma_f32 v[10:11], v[34:35], v[22:23], v[10:11]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[6:7], v[40:41], v[24:25], v[6:7]
	v_pk_fma_f32 v[8:9], v[38:39], v[22:23], v[8:9]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB0_37
.Lft16:
	s_or_b64 exec, exec, s[28:29]
	v_mov_b32_e32 v2, v20
.LBB0_39:
	s_or_b64 exec, exec, s[26:27]
	v_mov_b32_e32 v20, v18
	v_mov_b32_e32 v21, v16
	v_mov_b32_e32 v16, v19
	v_mov_b32_e32 v18, v13
	v_mov_b32_e32 v19, v15
	v_mov_b32_e32 v13, v14
	v_mov_b32_e32 v14, v10
	v_mov_b32_e32 v15, v8
	v_mov_b32_e32 v8, v11
	v_pk_add_f32 v[16:17], v[20:21], v[16:17]
	v_pk_add_f32 v[8:9], v[14:15], v[8:9]
	v_mov_b32_e32 v10, v5
	v_mov_b32_e32 v11, v7
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	v_pk_add_f32 v[8:9], v[8:9], v[10:11]
	v_mov_b32_e32 v5, v6
	v_pk_add_f32 v[12:13], v[16:17], v[12:13]
	v_pk_add_f32 v[4:5], v[8:9], v[4:5]
	v_cmp_gt_i32_e32 vcc, s8, v2
	s_and_saveexec_b64 s[26:27], vcc
	s_cbranch_execz .LBB0_51
.Lft17:
	v_sub_u32_e32 v16, s8, v2
	v_cmp_lt_u32_e32 vcc, 1, v16
	s_mov_b64 s[30:31], -1
	s_and_saveexec_b64 s[28:29], vcc
	s_cbranch_execz .LBB0_46
.Lft18:
	v_and_b32_e32 v3, -2, v16
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v6, v4
	v_mov_b32_e32 v8, v5
	v_mov_b32_e32 v9, v7
	v_mov_b32_e32 v10, v12
	v_mov_b32_e32 v11, v7
	v_mov_b32_e32 v14, v13
	v_mov_b32_e32 v15, v7
	s_mov_b64 s[30:31], 0
	v_mov_b64_e32 v[4:5], v[6:7]
	v_mov_b32_e32 v6, v2
	v_mov_b32_e32 v12, v3
	.p2align	5, , 4
.LBB0_42:
	v_lshlrev_b64 v[18:19], 2, v[6:7]
	v_lshl_add_u64 v[20:21], s[4:5], 0, v[18:19]
	v_lshl_add_u64 v[22:23], s[18:19], 0, v[18:19]
	v_lshl_add_u64 v[24:25], s[20:21], 0, v[18:19]
	v_lshl_add_u64 v[26:27], s[22:23], 0, v[18:19]
	v_lshl_add_u64 v[18:19], s[24:25], 0, v[18:19]
	global_load_dwordx2 v[28:29], v[20:21], off
	global_load_dwordx2 v[30:31], v[22:23], off
	global_load_dwordx2 v[32:33], v[24:25], off
	global_load_dwordx2 v[34:35], v[26:27], off
	global_load_dwordx2 v[36:37], v[18:19], off
	v_add_u32_e32 v12, -2, v12
	v_cmp_eq_u32_e32 vcc, 0, v12
	v_add_u32_e32 v6, 2, v6
	s_or_b64 s[30:31], vcc, s[30:31]
	s_waitcnt vmcnt(3)
	v_pk_fma_f32 v[14:15], v[30:31], v[28:29], v[14:15]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[10:11], v[32:33], v[28:29], v[10:11]
	s_waitcnt vmcnt(1)
	v_pk_fma_f32 v[8:9], v[34:35], v[28:29], v[8:9]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[4:5], v[36:37], v[28:29], v[4:5]
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB0_42
.Lft19:
	s_or_b64 exec, exec, s[30:31]
	v_add_f32_e32 v4, v4, v5
	v_add_f32_e32 v5, v8, v9
	v_add_f32_e32 v12, v10, v11
	v_add_f32_e32 v13, v14, v15
	v_cmp_ne_u32_e32 vcc, v16, v3
	s_mov_b64 s[18:19], 0
	s_and_saveexec_b64 s[20:21], vcc
	v_add_u32_e32 v2, v2, v3
	s_mov_b64 s[18:19], exec
	v_sub_u32_e32 v16, s8, v2
	s_or_b64 exec, exec, s[20:21]
	s_orn2_b64 s[30:31], s[18:19], exec
.LBB0_46:
	s_or_b64 exec, exec, s[28:29]
	s_and_saveexec_b64 s[18:19], s[30:31]
	s_cbranch_execz .LBB0_50
.Lft20:
	v_mov_b32_e32 v3, 0
	s_add_u32 s16, s14, s16
	v_lshlrev_b64 v[14:15], 2, v[2:3]
	s_addc_u32 s17, s15, s17
	s_ashr_i32 s8, s12, 31
	v_lshl_add_u64 v[2:3], s[16:17], 0, v[14:15]
	s_add_u32 s16, s12, 1
	s_addc_u32 s17, s8, 0
	s_ashr_i32 s1, s0, 31
	v_mov_b64_e32 v[10:11], s[0:1]
	v_cmp_lt_i64_e32 vcc, s[16:17], v[10:11]
	s_and_b64 s[20:21], vcc, exec
	s_cselect_b32 s16, s16, s0
	s_cselect_b32 s17, s17, s1
	s_mul_i32 s20, s16, s33
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
	v_cmp_lt_i64_e32 vcc, s[16:17], v[10:11]
	s_and_b64 s[20:21], vcc, exec
	s_cselect_b32 s16, s16, s0
	s_cselect_b32 s17, s17, s1
	s_mul_i32 s20, s16, s33
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
	v_cmp_lt_i64_e32 vcc, s[16:17], v[10:11]
	s_and_b64 s[20:21], vcc, exec
	s_cselect_b32 s0, s16, s0
	s_cselect_b32 s1, s17, s1
	s_mul_i32 s8, s0, s33
	s_mul_hi_u32 s16, s0, s13
	s_add_i32 s8, s16, s8
	s_mul_i32 s1, s1, s13
	s_add_i32 s1, s8, s1
	s_mul_i32 s0, s0, s13
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s14, s0
	s_addc_u32 s1, s15, s1
	v_lshl_add_u64 v[10:11], s[0:1], 0, v[14:15]
	v_lshl_add_u64 v[14:15], s[4:5], 0, v[14:15]
	s_mov_b64 s[0:1], 0
	.p2align	5, , 4
.LBB0_48:
	global_load_dword v18, v[14:15], off
	global_load_dword v21, v[2:3], off
	global_load_dword v20, v[6:7], off
	global_load_dword v23, v[8:9], off
	global_load_dword v22, v[10:11], off
	v_add_u32_e32 v16, -1, v16
	v_cmp_eq_u32_e32 vcc, 0, v16
	v_lshl_add_u64 v[2:3], v[2:3], 0, 4
	v_lshl_add_u64 v[6:7], v[6:7], 0, 4
	v_lshl_add_u64 v[8:9], v[8:9], 0, 4
	v_lshl_add_u64 v[10:11], v[10:11], 0, 4
	v_lshl_add_u64 v[14:15], v[14:15], 0, 4
	s_or_b64 s[0:1], vcc, s[0:1]
	s_waitcnt vmcnt(2)
	v_pk_fma_f32 v[12:13], v[20:21], v[18:19], v[12:13] op_sel_hi:[1,0,1]
	s_waitcnt vmcnt(0)
	v_pk_fma_f32 v[4:5], v[22:23], v[18:19], v[4:5] op_sel_hi:[1,0,1]
	s_andn2_b64 exec, exec, s[0:1]
	s_cbranch_execnz .LBB0_48
.Lft21:
	s_or_b64 exec, exec, s[0:1]
.LBB0_50:
	s_or_b64 exec, exec, s[18:19]
.LBB0_51:
	s_or_b64 exec, exec, s[26:27]
	v_add_f32_dpp v20, v13, v13 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v24, v12, v12 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v28, v5, v5 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v32, v4, v4 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v21, v20, v20 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v25, v24, v24 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v29, v28, v28 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v33, v32, v32 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v22, v21, v21 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v26, v25, v25 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v30, v29, v29 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v34, v33, v33 row_half_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v23, v22, v22 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v27, v26, v26 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v31, v30, v30 row_mirror row_mask:0xf bank_mask:0xf
	v_add_f32_dpp v35, v34, v34 row_mirror row_mask:0xf bank_mask:0xf
	v_readlane_b32 s14, v23, 16
	v_readlane_b32 s15, v23, 32
	v_readlane_b32 s16, v23, 48
	v_readlane_b32 s17, v27, 16
	v_readlane_b32 s18, v27, 32
	v_readlane_b32 s19, v27, 48
	v_readlane_b32 s20, v31, 16
	v_readlane_b32 s21, v31, 32
	v_readlane_b32 s22, v31, 48
	v_readlane_b32 s23, v35, 16
	v_readlane_b32 s24, v35, 32
	v_readlane_b32 s25, v35, 48
	v_lshrrev_b32_e32 v1, 4, v0
	v_add_u32_e32 v1, 0x4000, v1
	s_mov_b64 exec, 1
	v_add_f32_e32 v23, s14, v23
	v_add_f32_e32 v27, s17, v27
	v_add_f32_e32 v31, s20, v31
	v_add_f32_e32 v35, s23, v35
	v_add_f32_e32 v23, s15, v23
	v_add_f32_e32 v27, s18, v27
	v_add_f32_e32 v31, s21, v31
	v_add_f32_e32 v35, s24, v35
	v_add_f32_e32 v23, s16, v23
	v_add_f32_e32 v27, s19, v27
	v_add_f32_e32 v31, s22, v31
	v_add_f32_e32 v35, s25, v35
	ds_write2_b32 v1, v23, v27 offset1:16
	ds_write2_b32 v1, v31, v35 offset0:32 offset1:48
	s_mov_b64 exec, -1
	s_waitcnt lgkmcnt(0)
	s_barrier
.Lft22:
.LBB0_53:
	v_cmp_gt_u32_e32 vcc, 4, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_59
.Lft23:
	v_or_b32_e32 v2, s12, v0
	v_cmp_gt_i32_e32 vcc, s9, v2
	s_mov_b64 s[8:9], s[2:3]
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_58
.Lft24:
	v_lshlrev_b32_e32 v0, 6, v0
	ds_read_b128 v[4:7], v0 offset:16384
	ds_read_b128 v[8:11], v0 offset:16400
	ds_read_b128 v[12:15], v0 offset:16432
	ds_read_b128 v[16:19], v0 offset:16416
	v_cmp_eq_f32_e64 s[8:9], s11, 0
	v_ashrrev_i32_e32 v3, 31, v2
	s_and_b64 vcc, exec, s[8:9]
	s_waitcnt lgkmcnt(1)
	v_pk_add_f32 v[0:1], v[10:11], v[14:15]
	s_waitcnt lgkmcnt(0)
	v_pk_add_f32 v[6:7], v[6:7], v[18:19]
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_pk_add_f32 v[4:5], v[4:5], v[16:17]
	v_pk_add_f32 v[0:1], v[6:7], v[0:1]
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	s_nop 0
	v_pk_add_f32 v[0:1], v[4:5], v[0:1]
	s_nop 0
	v_add_f32_e32 v0, v0, v1
	v_mul_f32_e32 v1, s10, v0
	s_cbranch_vccnz .LBB0_57
.Lft25:
	v_lshl_add_u64 v[4:5], v[2:3], 2, s[6:7]
	global_load_dword v0, v[4:5], off
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v1, s11, v0
.LBB0_57:
	s_or_b64 s[8:9], s[2:3], exec
.LBB0_58:
	s_or_b64 exec, exec, s[4:5]
	s_andn2_b64 s[2:3], s[2:3], exec
	s_and_b64 s[4:5], s[8:9], exec
	s_or_b64 s[2:3], s[2:3], s[4:5]
.LBB0_59:
	s_or_b64 exec, exec, s[0:1]
	s_and_saveexec_b64 s[0:1], s[2:3]
	s_cbranch_execz .LBB0_61
.LBB0_60:
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[2:3], v[2:3], 2, s[6:7]
	global_store_dword v[2:3], v1, off
.LBB0_61:
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
		.amdhsa_next_free_sgpr 34
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
  .sgpr_count: 40
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
