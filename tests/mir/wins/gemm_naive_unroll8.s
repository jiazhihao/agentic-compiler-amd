; gemm_naive: state 'unroll8' of the M5 agent session (docs/progress.md). Kernel body only; apply with
;   agc run tests/kernels/gemm_naive.json --edit tests/mir/wins/gemm_naive_unroll8.s
gemm_naive:
	s_load_dword s8, s[0:1], 0x34
	s_load_dwordx4 s[4:7], s[0:1], 0x18
	v_and_b32_e32 v1, 0x3ff, v0
	v_bfe_u32 v0, v0, 10, 10
	s_waitcnt lgkmcnt(0)
	s_lshr_b32 s7, s8, 16
	s_and_b32 s8, s8, 0xffff
	s_mul_i32 s2, s2, s8
	s_mul_i32 s3, s3, s7
	v_add_u32_e32 v2, s2, v1
	v_add_u32_e32 v0, s3, v0
	v_cmp_gt_i32_e32 vcc, s4, v0
	v_cmp_gt_i32_e64 s[2:3], s5, v2
	s_and_b64 s[2:3], s[2:3], vcc
	s_and_saveexec_b64 s[8:9], s[2:3]
	s_cbranch_execz .LBB0_8
.Lft0:
	s_load_dwordx4 s[8:11], s[0:1], 0x0
	s_load_dwordx2 s[2:3], s[0:1], 0x10
	s_cmp_gt_i32 s6, 0
	v_ashrrev_i32_e32 v1, 31, v0
	v_ashrrev_i32_e32 v3, 31, v2
	s_cbranch_scc1 .LBB0_4
.Lft1:
	s_ashr_i32 s1, s5, 31
	s_mov_b32 s0, s5
	s_cbranch_execz .LBB0_5
.Lft2:
	v_mov_b32_e32 v8, 0
	s_branch .LBB0_7
.LBB0_4:
.LBB0_5:
	v_mad_u64_u32 v[8:9], s[0:1], v0, s6, 0
	v_mov_b32_e32 v10, v9
	v_mad_u64_u32 v[10:11], s[0:1], v1, s6, v[10:11]
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v4, s8
	v_mov_b32_e32 v5, s9
	v_mov_b32_e32 v6, s10
	v_mov_b32_e32 v7, s11
	v_mov_b32_e32 v9, v10
	s_ashr_i32 s1, s5, 31
	s_mov_b32 s0, s5
	v_lshl_add_u64 v[4:5], v[8:9], 2, v[4:5]
	v_lshl_add_u64 v[6:7], v[2:3], 2, v[6:7]
	s_lshl_b64 s[4:5], s[0:1], 2
	v_mov_b32_e32 v8, 0
	s_cmp_lt_i32 s6, 8
	s_cbranch_scc1 .Ltail
.Lloop8:
	global_load_dwordx4 v[12:15], v[4:5], off
	global_load_dwordx4 v[16:19], v[4:5], off offset:16
	global_load_dword v20, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v21, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v22, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v23, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v24, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v25, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v26, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	global_load_dword v27, v[6:7], off
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	s_add_i32 s6, s6, -8
	v_lshl_add_u64 v[4:5], v[4:5], 0, 32
	s_cmp_lt_i32 s6, 8
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v8, v12, v20
	v_fmac_f32_e32 v8, v13, v21
	v_fmac_f32_e32 v8, v14, v22
	v_fmac_f32_e32 v8, v15, v23
	v_fmac_f32_e32 v8, v16, v24
	v_fmac_f32_e32 v8, v17, v25
	v_fmac_f32_e32 v8, v18, v26
	v_fmac_f32_e32 v8, v19, v27
	s_cbranch_scc0 .Lloop8
.Ltail:
	s_cmp_eq_u32 s6, 0
	s_cbranch_scc1 .LBB0_7
	.p2align 5, , 4
.LBB0_6:
	global_load_dword v9, v[4:5], off
	global_load_dword v10, v[6:7], off
	s_add_i32 s6, s6, -1
	v_lshl_add_u64 v[4:5], v[4:5], 0, 4
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[4:5]
	s_cmp_eq_u32 s6, 0
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v8, v9, v10
	s_cbranch_scc0 .LBB0_6
.LBB0_7:
	v_mul_lo_u32 v6, s1, v0
	v_mul_lo_u32 v7, s0, v1
	v_mad_u64_u32 v[0:1], s[0:1], s0, v0, 0
	s_waitcnt lgkmcnt(0)
	v_mov_b32_e32 v4, s2
	v_mov_b32_e32 v5, s3
	v_add3_u32 v1, v1, v7, v6
	v_lshl_add_u64 v[0:1], v[0:1], 2, v[4:5]
	v_lshl_add_u64 v[0:1], v[2:3], 2, v[0:1]
	global_store_dword v[0:1], v8, off
.LBB0_8:
	s_endpgm
