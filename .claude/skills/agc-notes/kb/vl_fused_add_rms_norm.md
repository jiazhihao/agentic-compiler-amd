# Knowledge-base entries from `vl_fused_add_rms_norm`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Fused add + RMSNorm with z kept in registers (vLLM variant): at the memory floor, ship amdclang

- **Verdict:** parity
- **Applies when:** one workgroup per row, 16 waves, each lane issues two cold global_load_dwordx4 (two streams), stores the sum, reduces through ds_bpermute + 2 barriers, then one cached weight x4 load and a second x4 store; headroom <= 1.0; no re-read of either stream
- **How:** Probe first: delete the two cold loads + wait; delete both stores; delete both s_barrier. If only the loads move the time, stop.
- **Measured:** vl_fused_add_rms_norm B=8192 D=4096: full 100-102 us; no loads 51.4 us; no stores 95.8 us; no barriers 105.4 us
- **Session:** 2026-11-21 08:58

## LDS-reservation throttle on a two-stream 16-wave row kernel

- **Verdict:** parity
- **Applies when:** block 1024, 68 B of LDS, two cold x4 loads per lane, headroom ~1.0
- **How:** relaunch(baseline, {grid:[B,1,1], block:[1024,1,1], lds:40960})
- **Measured:** vl_fused_add_rms_norm b5dfcfe1103db7d4: 0.997 [0.991, 1.007], 120 pairs
- **Session:** 2026-11-21 08:58

## Scalar mask-free fast path past amdclang's chunk-mask saveexec chain

- **Verdict:** parity
- **Applies when:** loop-free hot path guarded by v_cmp + s_and_saveexec + s_xor + s_cbranch_execz for partial chunks, kernel at the memory floor
- **How:** Before the first s_and_saveexec: s_cmp_eq_u32 sD, 0x1000 / s_cbranch_scc1 .Lfast; .Lfast = the two x4 loads, s_mov_b64 0 into every saved-exec pair the join block ORs into EXEC or tests later (s[8:9], s[10:11]), wait, same arithmetic in the same order, s_branch to the reduction block
- **Measured:** vl_fused_add_rms_norm 6cbe8de3eec39a15: 1.001 [0.994, 1.009], 120 pairs, battery 77/77
- **Session:** 2026-11-21 08:58

## Deferring the first-pass store past the barriers (copy the value, store next to the second store)

- **Verdict:** parity
- **Applies when:** row kernel that stores an intermediate (residual = input + residual) right after the cold loads, then reduces and stores a second output
- **How:** Replace the store by v_mov copies of the address pair and the 4 data registers into free VGPRs (the originals are overwritten by the second pass: check before reusing them), issue global_store_dwordx4 from the copies at the head of the final store block
- **Measured:** vl_fused_add_rms_norm ea277ad93635316b: 1.005 [1.000, 1.010], 120 pairs (fi_fused_add_rmsnorm: 0.975)
- **Session:** 2026-11-21 08:58

## 8 waves x 2 KB per row instead of 16 waves x 1 KB on a two-stream row kernel

- **Verdict:** loses
- **Applies when:** source has BLK/KCH defines; row 16 KB, two cold streams
- **How:** source(like=baseline, defines={BLK:512, KCH:2})
- **Measured:** vl_fused_add_rms_norm 957672a1bf35761a: 0.970 [0.965, 0.974], 120 pairs
- **Session:** 2026-11-21 08:58

## DPP wave reduction in place of cub's bpermute tree on a 16-wave fused add + RMSNorm row kernel

- **Verdict:** loses
- **Applies when:** one workgroup per row, block 1024 always full, cub BlockReduce lowered to 6 ds_bpermute_b32 + lgkmcnt(0) per wave and a 4-step bpermute second level in wave 0, two barriers; kernel at headroom ~1.0 with cold x4 loads before the reduction
- **How:** replace the per-wave tree by v_add_f32_dpp quad_perm:[1,0,3,2] / quad_perm:[2,3,0,1] / row_half_mirror / row_mirror, v_readlane_b32 at lanes 0,16,32,48 into SGPRs, v_mov + 3 v_add_f32 with a scalar operand; in wave 0: ds_read_b32 of the 16 partials then the same 4 DPP steps; apply fix_hazards
- **Measured:** vl_fused_add_rms_norm 1ee5395954dca26d: 0.981 [0.974, 0.989], 120 pairs (B=8192, D=4096)
- **Session:** 2026-11-21 09:01

## s_setprio after the cold loads return

- **Verdict:** parity
- **Applies when:** memory-bound row kernel where a wave loads, then stores and waits at a barrier; idea is to let waves that already hold their data finish first
- **How:** insert `s_setprio 3` right after the s_waitcnt vmcnt(0) of the cold global_load_dwordx4 pair
- **Measured:** vl_fused_add_rms_norm 280b6a3498a9394e: 0.994 [0.990, 1.003], 120 pairs
- **Session:** 2026-11-21 09:01

## Order of two cold x4 loads from different streams

- **Verdict:** parity
- **Applies when:** a lane issues two global_load_dwordx4 from two cold tensors before one vmcnt(0) wait
- **How:** swap the two load instructions (residual first, input second)
- **Measured:** vl_fused_add_rms_norm d73ebf0ff1e51e72: 0.996 [0.993, 1.001], 120 pairs
- **Session:** 2026-11-21 09:01
