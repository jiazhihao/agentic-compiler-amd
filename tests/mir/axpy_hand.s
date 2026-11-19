; y[i] = a * x[i] + y[i], written directly in mir: no HIP source, no hidden arguments.
; In: s[0:1] kernarg pointer, s2 workgroup id x, v0 workitem id x. Workgroup size 256.
	s_load_dwordx4 s[4:7], s[0:1], 0x0        ; x, y
	s_load_dwordx2 s[8:9], s[0:1], 0x10       ; a, n
	s_lshl_b32 s2, s2, 8
	v_add_u32_e32 v0, s2, v0                  ; i
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_i32_e32 vcc, s9, v0
	s_and_saveexec_b64 s[2:3], vcc
	s_cbranch_execz .Lend
	v_mov_b32_e32 v1, 0
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
	v_lshl_add_u64 v[0:1], s[6:7], 0, v[0:1]
	global_load_dword v4, v[2:3], off
	global_load_dword v5, v[0:1], off
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v5, s8, v4
	global_store_dword v[0:1], v5, off
.Lend:
	s_endpgm
