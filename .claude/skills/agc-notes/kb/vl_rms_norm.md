# Knowledge-base entries from `vl_rms_norm`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## RMSNorm row kernel with the input kept in registers: at the memory floor, ship amdclang

- **Verdict:** parity
- **Applies when:** one workgroup per row, 16 waves, each lane does one global_load_dwordx4 and one global_store_dwordx4 with a DPP wave reduction + one s_barrier + ds_read_b128 between them; headroom 1.10-1.12; no second read of the input
- **How:** Probe before editing: delete the output store, delete s_barrier, delete the weight load, delete the whole LDS reduction. If only the store moves the time, stop.
- **Measured:** vl_rms_norm B=16384 hidden=4096: baseline 116-117 us; no store 92.3 us; no barrier 117.5; no weight load 117.6; no reduction 117.4
- **Session:** 2026-11-21 08:50

## Scalar fast path past the first-chunk mask and strided-loop tests

- **Verdict:** parity
- **Applies when:** amdclang's loop-free hot path still runs v_cmp + s_and_saveexec + s_cbranch_execz for a first-chunk mask and for strided loops that the bench shape never enters; kernel at headroom ~1.1
- **How:** After NV is in a scalar: s_cmp_eq_u32 sNV, 0x400 / s_cbranch_scc1 .Lfast; .Lfast = the unmasked load, s_mov_b64 of the loop masks to 0, wait, the same v_pk_mul / v_pk_fma / v_add, s_branch to the reduction block.
- **Measured:** vl_rms_norm 17e4b5068f46dbb4: 1.0003 [0.996, 1.006], 240 pairs; ~12 of ~120 executed instructions removed
- **Session:** 2026-11-21 08:50

## Waves per row sweep for a 16 KB row (bytes per wave 1 / 2 / 4 KB)

- **Verdict:** parity
- **Applies when:** row kernel whose source has BLK (threads per row) and KCH (16-byte chunks per thread kept in registers) as defines; row = 16 KB
- **How:** source(like=baseline, defines={BLK:512,KCH:2}) and {BLK:256,KCH:4}; block follows BLK
- **Measured:** vl_rms_norm: 2 KB/wave 1.0085 [0.994, 1.015] (fe2b0b2c6c39e12c, 60 pairs); 4 KB/wave 0.955 [0.944, 0.966] (4e3920d1ba65bda4)
- **Session:** 2026-11-21 08:50

## coarsen on an 8-wave row kernel at the floor

- **Verdict:** loses
- **Applies when:** one workgroup per row, 8 waves, one barrier, 16384 workgroups, headroom ~1.1
- **How:** apply(state, 'coarsen', {factor: 2})
- **Measured:** vl_rms_norm 46781e01b9d8a93e: 0.984 [0.976, 0.988]; on the 16-wave build 0.9725 / 0.966 / 0.932 for factor 2 / 4 / 8
- **Session:** 2026-11-21 08:50

## LDS-reservation throttle on a 16-wave load-reduce-barrier-store row kernel

- **Verdict:** parity
- **Applies when:** One workgroup per row with block 1024 (16 waves, one global_load_dwordx4 per lane, 1 KB per wave), a barrier and a global_store_dwordx4 after it, headroom 1.07-1.12; the default launch already holds only 2 workgroups (32 KB in flight) per CU
- **How:** relaunch(baseline, {grid: [B,1,1], block: [1024,1,1], lds: 40960}) for 1 workgroup per CU; no code change; bench with 120 pairs
- **Measured:** vl_rms_norm 49766e205243e177: 0.997 (CI 0.993..1.004, 120 pairs). rb_nrm2 gained 1.02-1.03 and rb_dot 1.03-1.05 from the same relaunch, but those are block-512 pure reductions with 4 workgroups per CU by default
- **Session:** 2026-11-21 08:54

## LDS-reservation throttle on the 8-wave, 2 KB-per-wave build of a row kernel

- **Verdict:** parity
- **Applies when:** Source geometry with block 512 and two x4 loads per lane (8 waves x 2 KB per row, 4 workgroups = 64 KB in flight per CU by default) on a row-normalisation kernel at the floor
- **How:** relaunch(state, {grid: [B,1,1], block: [512,1,1], lds: 32768}) for 2 workgroups per CU
- **Measured:** vl_rms_norm 9113d543a603f893: 1.0026 (CI 0.997..1.006, 120 pairs) against the baseline; the unthrottled parent measured 1.0085 (0.994..1.015)
- **Session:** 2026-11-21 08:54

## Two rows per 1024-thread workgroup in parallel on a 4 KB-row normalisation kernel

- **Verdict:** loses
- **Applies when:** One row per 16-wave workgroup, one barrier, input kept in registers; idea is to halve workgroups and barriers without serialising rows as coarsen does
- **How:** source: tid = threadIdx.x & 511, half = threadIdx.x >> 9, row = 2*blockIdx.x + half, NV = row < num_tokens ? hidden/4 : 0, two chunks per lane (KCH=2, BLK=512), s_part[2][8] LDS slots, launch grid cdiv(B,2) block 1024, -ffast-math
- **Measured:** vl_rms_norm 8eb7f0d92b34df0a: 0.9774 (CI 0.973..0.985, 60 pairs); same idea on mo_t5_layernorm 0.953; coarsen 2 on the baseline 0.9725
- **Session:** 2026-11-21 08:54

## Three-probe split for a row kernel before any edit

- **Verdict:** parity
- **Applies when:** Loop-free row kernel (load, cross-wave reduce, barrier, store) with headroom near 1.1, deciding whether any machine-level edit can pay
- **How:** probe three edits of the baseline: delete the input global_load_dwordx4 and its s_waitcnt; delete that plus the weight load and the store block; delete only the store. The differences give read, store and launch + ALU; they overlap and do not sum
- **Measured:** vl_rms_norm at B=16384, hidden 4096: 45.4 us without the input load (5ac47d5c1e592a6e), 27.9 us with no global memory at all (64bb46a53b6f6f6d), 92.3 us without the store, 112-116 us in full: read ~70 us at 3.8 TB/s, store ~17-25 us, launch + ALU 28 us
- **Session:** 2026-11-21 08:54
