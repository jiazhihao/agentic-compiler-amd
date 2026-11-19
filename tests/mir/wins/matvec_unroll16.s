; matvec: state 'unroll16' of the M5 agent session (docs/progress.md). Kernel body only; apply with
;   agc run tests/kernels/matvec.json --edit tests/mir/wins/matvec_unroll16.s
matvec:
	s_load_dword s3, s[0:1], 0x2c
	s_load_dwordx2 s[8:9], s[0:1], 0x18
	s_waitcnt lgkmcnt(0)
	s_and_b32 s3, s3, 0xffff
	s_mul_i32 s2, s2, s3
	v_add_u32_e32 v0, s2, v0
	v_cmp_gt_i32_e32 vcc, s8, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .LBB0_6
.Lft0:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	s_cmp_lt_i32 s9, 1
	v_ashrrev_i32_e32 v1, 31, v0
	s_cbranch_scc1 .LBB0_4
.Lft1:
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v2, s4
	v_mov_b32_e32 v3, s5
	v_mad_i64_i32 v[4:5], s[0:1], v0, s9, 0
	v_lshl_add_u64 v[2:3], v[4:5], 2, v[2:3]
	v_mov_b32_e32 v4, 0
	s_cmp_lt_u32 s9, 16
	s_cbranch_scc1 .Ltail
.Lloop16:
	global_load_dwordx4 v[6:9], v[2:3], off
	global_load_dwordx4 v[10:13], v[2:3], off offset:16
	global_load_dwordx4 v[14:17], v[2:3], off offset:32
	global_load_dwordx4 v[18:21], v[2:3], off offset:48
	s_load_dwordx16 s[12:27], s[6:7], 0x0
	s_add_i32 s9, s9, -16
	s_add_u32 s6, s6, 64
	s_addc_u32 s7, s7, 0
	v_lshl_add_u64 v[2:3], v[2:3], 0, 64
	s_cmp_lt_u32 s9, 16
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v4, s12, v6
	v_fmac_f32_e32 v4, s13, v7
	v_fmac_f32_e32 v4, s14, v8
	v_fmac_f32_e32 v4, s15, v9
	v_fmac_f32_e32 v4, s16, v10
	v_fmac_f32_e32 v4, s17, v11
	v_fmac_f32_e32 v4, s18, v12
	v_fmac_f32_e32 v4, s19, v13
	v_fmac_f32_e32 v4, s20, v14
	v_fmac_f32_e32 v4, s21, v15
	v_fmac_f32_e32 v4, s22, v16
	v_fmac_f32_e32 v4, s23, v17
	v_fmac_f32_e32 v4, s24, v18
	v_fmac_f32_e32 v4, s25, v19
	v_fmac_f32_e32 v4, s26, v20
	v_fmac_f32_e32 v4, s27, v21
	s_cbranch_scc0 .Lloop16
.Ltail:
	s_cmp_eq_u32 s9, 0
	s_cbranch_scc1 .LBB0_5
.LBB0_3:
	global_load_dword v5, v[2:3], off
	s_load_dword s0, s[6:7], 0x0
	s_add_i32 s9, s9, -1
	s_add_u32 s6, s6, 4
	s_addc_u32 s7, s7, 0
	v_lshl_add_u64 v[2:3], v[2:3], 0, 4
	s_cmp_eq_u32 s9, 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_fmac_f32_e32 v4, s0, v5
	s_cbranch_scc0 .LBB0_3
.Lft2:
	s_branch .LBB0_5
.LBB0_4:
	v_mov_b32_e32 v4, 0
.LBB0_5:
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v2, s2
	v_mov_b32_e32 v3, s3
	v_lshl_add_u64 v[0:1], v[0:1], 2, v[2:3]
	global_store_dword v[0:1], v4, off
.LBB0_6:
	s_endpgm
