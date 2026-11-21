# Knowledge-base entries from `mo_prelu_bwd`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Mask-free scalar-base rewrite with one wait and shared compare masks on a 2-in / 2-out elementwise kernel

- **Verdict:** parity
- **Applies when:** Loop-free touch-once kernel whose amdclang code has two global_load_dwordx2, two selects per output behind 64-bit per-lane compares and s_and_saveexec, and an s_waitcnt vmcnt(0) between the first store and the second output's arithmetic; headroom about 1.0
- **How:** Prepend to amdclang's code: s_load_dwordx8 + s_load_dwordx4 kernargs, (wg+1)<<8 against N with s_sub_u32/s_subb_u32 -> branch to the original code as tail; else add wg<<10 to the four bases (s_add_u32/s_addc_u32), v1 = tid<<3, global_load_dwordx2 v, v1, s[base] x2, s_waitcnt vmcnt(0) lgkmcnt(0), v_cmp_lt_f32_e64 into two SGPR pairs, 4 v_mul_f32, 4 v_cndmask_b32_e64 reusing the masks (0 as the true operand for the collector), two global_store_dwordx2, s_endpgm
- **Measured:** mo_prelu_bwd e1625937d632e9c5: 0.9941 (CI 0.9927..0.9973, 240 pairs), 193.5 us against 191.9 us
- **Session:** 2026-11-21 07:18

## One wave per workgroup, 1 KB per wave, 4 loads in flight on a 4-stream kernel

- **Verdict:** loses
- **Applies when:** Elementwise touch-once kernel with two read streams and two write streams at headroom about 1.0 (the rb_scal recipe)
- **How:** block 64, grid cdiv(N,256); x and g loaded with global_load_dwordx2 at offset 0 and offset:512; s_waitcnt vmcnt(2); compute and two stores; s_waitcnt vmcnt(2); compute and two stores at offset:512; tail from amdclang's EPT=4/BLK=64 build
- **Measured:** mo_prelu_bwd a0d53e99825fd815: 0.9658 (CI 0.9635..0.9674, 240 pairs)
- **Session:** 2026-11-21 07:18

## Block size at constant 512 B per wave on a 4-stream elementwise kernel

- **Verdict:** loses
- **Applies when:** Loop-free memory-floor kernel where amdclang's best build is block 128 with 8 B per lane; idea is more or fewer waves per workgroup
- **How:** same mask-free body with the shifts changed: block 256 / grid cdiv(N,512) (end <<9, base <<11) or block 64 / grid cdiv(N,128) (end <<7, base <<9), each prepended to the amdclang build with the matching BLK as tail
- **Measured:** mo_prelu_bwd: block 256 71dc08f919e3e9da 0.9472 (0.9454..0.9493); block 64 8950d60ea26a622b 0.9623 (0.9596..0.9664); block 128 e1625937d632e9c5 0.9941; 240 pairs each
- **Session:** 2026-11-21 07:18

## 16 B per lane (dwordx4) on a 4-stream kernel that moves 8 B per lane

- **Verdict:** loses
- **Applies when:** amdclang uses global_load_dwordx2 per lane on a memory-floor kernel with two inputs and two outputs
- **How:** block 128, grid cdiv(N,512), v1 = tid<<4, global_load_dwordx4 v[4:7] / v[8:11] with scalar bases, 4 v_cmp_lt_f32_e64 into SGPR pairs, 8 v_mul, 8 v_cndmask_e64, two global_store_dwordx4
- **Measured:** mo_prelu_bwd cba6b92d4c71048a: 0.8954 (CI 0.8934..0.8983, 240 pairs); the same idea was 1.01 on copy and 0.97 on swap: it degrades with the number of streams
- **Session:** 2026-11-21 07:18

## Two tiles per wave with the next tile's loads in flight before the current stores (4 streams)

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel, one 512 B tile per wave per stream, two inputs and two outputs, at the memory floor
- **How:** block 128, grid cdiv(N,512); load tile A; s_waitcnt vmcnt(0); issue tile B's two global_load_dwordx2 at offset:1024; compute and store A (2 stores); s_waitcnt vmcnt(2); compute and store B at offset:1024
- **Measured:** mo_prelu_bwd 79d2b718c36c8484: 0.9498 (CI 0.9451..0.9535, 240 pairs)
- **Session:** 2026-11-21 07:18

## Additive probe split identifies a pure memory-floor kernel

- **Verdict:** parity
- **Applies when:** Elementwise kernel with headroom near 1.0; question is whether any arithmetic, wait or mask time is hidden
- **How:** On a hand-written fast path, probe three variants: one store deleted, all stores deleted, loads replaced by v_mov constants. If launch (20 us) + loads-only + stores-only adds up to the full time, nothing overlaps and only fewer bytes can help
- **Measured:** mo_prelu_bwd: 193.5 us complete, 160.2 us minus one store, 126.6 us no stores, 83.9 us no loads: 20 + 107 + 2 x 33 = 193
- **Session:** 2026-11-21 07:18

## Bytes per lane on a 2-in / 2-out streaming elementwise kernel: 8 B is the optimum

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel with several contiguous read and write streams, headroom near 1.0, amdclang build already at global_load_dwordx2 per stream
- **How:** Source defines EPT=1 / 3 with block 128 (global_load_dword / global_load_dwordx3 per stream), grid cdiv(N, EPT*128)
- **Measured:** mo_prelu_bwd: 4 B/lane 0.8473 (0.8445..0.8495); 12 B/lane 0.8839 (0.8776..0.8886); 16 B/lane 0.895 (earlier session)
- **Session:** 2026-11-21 07:22

## Three waves per workgroup (block 192)

- **Verdict:** loses
- **Applies when:** Streaming elementwise kernel whose best block is 128 with 512 B per wave; question whether a non-power-of-two block between 128 and 256 helps
- **How:** Source define BLK=192, grid cdiv(N, 2*192), block 192
- **Measured:** mo_prelu_bwd: 0.9319 (0.9242..0.9381), 60 pairs
- **Session:** 2026-11-21 07:22

## Workgroup-id interleave (two streaming fronts)

- **Verdict:** loses
- **Applies when:** Streaming kernel at the memory floor whose address is workgroup_id * tile; idea of spreading consecutive workgroups over two distant regions
- **How:** At entry after the N kernarg arrives: H = (N + 511) >> 9 via s_add_u32/s_addc_u32/s_lshr_b64; s2 = (s2 >> 1) + ((s2 & 1) ? H : 0) via s_and_b32, s_lshr_b32, s_cmp_eq_u32, s_cselect_b32, s_add_u32; body unchanged; bijection for any N
- **Measured:** mo_prelu_bwd: d48c7485b1aa97e4, 0.9808 (0.9798..0.9837), 240 pairs
- **Session:** 2026-11-21 07:22
