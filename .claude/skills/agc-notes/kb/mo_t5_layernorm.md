# Knowledge-base entries from `mo_t5_layernorm`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Row normalisation already single-read: nothing left at the machine level

- **Verdict:** parity
- **Applies when:** one workgroup per row, 4 waves, each lane does one global_load_dwordx4 and one global_store_dwordx4 with a cross-wave reduction between them; headroom <= 1.05; the input is kept in registers across the reduction
- **How:** Check with two probes before editing: delete the output store (here 64.9 -> 46.4 us, store = 18.5 us) and delete all s_barrier (64.9 -> 64.66 us). If the barrier probe moves by < 1 %, skip DPP/LDS/rsqrt/fast-path edits.
- **Measured:** mo_t5_layernorm R=32768 D=1024: DPP+1 barrier 0.9991 [0.995,1.003]; weight in flight + v_rsq_f32 0.989 [0.985,0.994]; scalar fast path 1.0012 [0.997,1.006]
- **Session:** 2026-11-21 06:56

## Bytes per wave sweep for a one-row-per-workgroup kernel

- **Verdict:** loses
- **Applies when:** row of 4 KB handled by one workgroup; the block size and elements per lane are free (source defines BLK/NC or a vector width)
- **How:** source(like=baseline, defines={BLK:64,NC:4} block 64; {BLK:128,NC:2} block 128; a 2-float vector with block 512). Keep 16 B per lane and 1 KB contiguous per wave (block 256, one x4 load per lane).
- **Measured:** mo_t5_layernorm: 512 B/wave (8 B per lane, 8 waves) 0.710; 1 KB/wave 1.00; 2 KB/wave 0.968; 4 KB/wave (one wave, no barriers) 0.883
- **Session:** 2026-11-21 06:56

## Two rows per workgroup in parallel (8 waves) instead of coarsen

- **Verdict:** loses
- **Applies when:** one row per 4-wave workgroup with an LDS/DPP reduction; idea is to halve the workgroup count without serialising rows as coarsen does
- **How:** edit_ir with launch grid cdiv(R,2), block 512, appended u32 R (kernarg slot 0x38): s_row = 2*s2 + (v_readfirstlane(v0) >> 8), clamped with s_min_u32 to R-1; v0 &= 0xff; per-row LDS slots at 16*(lid>>8).
- **Measured:** mo_t5_layernorm: 0.953 [0.944,0.961] (coarsen 2, serial: 0.961)
- **Session:** 2026-11-21 06:56

## Scalar fast path past dead chunk/tail tests

- **Verdict:** parity
- **Applies when:** amdclang's loop-free hot path still runs 64-bit v_cmp + s_and_saveexec + s_cbranch_execz for a second chunk and a tail that the bench shape never takes
- **How:** After the first chunk: s_and_b32 s6,D,3; s_add_u32 s7,D,-1; s_lshr_b32 s7,s7,10; or with the high word; s_cbranch_scc0 to the general path; else zero the later masks (s[4:5], s[22:23], v22) and s_branch to the reduction.
- **Measured:** mo_t5_layernorm: 1.0012 [0.997,1.006], 60 pairs
- **Session:** 2026-11-21 06:56

## Branch over memory instructions that most waves execute with an empty EXEC

- **Verdict:** pays
- **Applies when:** A store or load is masked to one lane of the workgroup (lid == 0 result store, tail element) and the kernel is short and memory-bound, so that 3 of 4 (or more) waves reach it with EXEC == 0.
- **How:** Keep or add `s_and_saveexec_b64` / `s_mov_b64 exec, mask` followed by `s_cbranch_execz` around the `global_store_dword`; do not rely on EXEC == 0 making it a no-op.
- **Measured:** mo_t5_layernorm: unbranched rstd store 0.980 [0.975, 0.982] (61efc4b353548285) vs branched 0.994 [0.990, 0.998] (239a159b01db0561), otherwise identical code: 1.4 %.
- **Session:** 2026-11-21 07:01

## Hand-written mask-free straight-line fast path for the bench shape on a one-chunk row kernel at the memory floor

- **Verdict:** parity
- **Applies when:** Row kernel (load 1 KB per wave, cross-wave reduction, store 1 KB per wave) with headroom <= 1.1 where amdclang's body is loop-free at the bench shape but full of masks, 64-bit compares, an LDS tree with log2(block)+1 barriers and full waits.
- **How:** Scalar test at entry (D == 1024, mode, non-null pointer) branching to a new block: scalar-base `global_load_dwordx4 v, v_off, s[base]`, DPP wave reduce + 4 `v_readlane_b32`, one `ds_write_b32` per wave under EXEC=1, one `s_barrier`, 2 `ds_read2_b32`, `v_rsq_f32`, plain `v_mul_f32`, scalar-base store; fallback to the imported code; `fix_hazards`.
- **Measured:** mo_t5_layernorm: 0.994 [0.990, 0.998], 240 pairs (239a159b01db0561); ~63 executed instructions vs ~150, 1 barrier vs 9.
- **Session:** 2026-11-21 07:01

## Cache-resident operand load in flight with the cold load

- **Verdict:** parity
- **Applies when:** A small per-lane operand table (weight, 4 KB) is loaded by every wave after a reduction, with a full wait, in a kernel at the memory floor.
- **How:** Issue the operand `global_load_dwordx4` right after the main load and wait `vmcnt(1)` for the main load, `vmcnt(0)` before the operand's first use; compared with issuing it after the barrier.
- **Measured:** mo_t5_layernorm: 0.982 (4a2e214686bf85da) vs 0.980 (61efc4b353548285), no difference; probe without the load 65.2 us vs 65 us (3e2fb7db7ada044a).
- **Session:** 2026-11-21 07:01
