# Knowledge-base entries from `rb_gemvn`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## More strided loads in flight loses: the optimum is the baseline's 16 fragments per wave

- **Verdict:** loses
- **Applies when:** The hot loop reads a column-major matrix by rows (short fragments, here 128 B, at a stride of tens of KB), one fragment per load and lane group, and the code already issues a full iteration's loads before one s_waitcnt vmcnt(0).
- **How:** Hand-written loop with U steps of global_load_dwordx4 (8 fragments each) issued before the first use, waits placed by fix_waits; U = 1, 2, 3, 4, 8, 15.
- **Measured:** rb_gemvn, 256 workgroups x 8 waves: U=1 0.948, U=2 1.0015 (CI 0.992-1.013), U=3 0.929, U=4 0.913, U=8 0.899, U=15 0.883 against the strongest amdclang build (0.095 ms).
- **Session:** 2026-11-21 06:40

## 16 bytes per lane (dwordx4 over consecutive rows) on a strided matrix read

- **Verdict:** parity
- **Applies when:** One lane loads one dword per column from a column-major matrix and neighbouring lanes read neighbouring rows, so 4 rows per lane with global_load_dwordx4 and 4 accumulators per lane is possible.
- **How:** Lane l: column group l >> 3, rows 4 (l & 7) .. +3; global_load_dwordx4 per step, v_fmac_f32 x4 with a per-lane x dword; block (64,8); per-lane partials to LDS (ds_write2_b32 x2), 32 lanes of wave 0 sum 64 partials each (32 ds_read2_b32). Masked dword loads for partial row groups.
- **Measured:** rb_gemvn state 211aac966291dc33: 1.0015x (CI 0.992-1.013, 60 pairs), 20 instead of 41 loop instructions per 2 KB.
- **Session:** 2026-11-21 06:40

## More or longer waves per workgroup on a strided matrix-vector kernel

- **Verdict:** loses
- **Applies when:** Matrix-vector kernel with one workgroup per CU (256) and 8 waves each, the reduction across threads through LDS.
- **How:** Source define WAV=32 (block (32,32), 16 waves per workgroup, half as many columns per wave); or hand-written 64 rows per workgroup with 256 B fragments, block (64,16), grid M/64.
- **Measured:** rb_gemvn: b603d75d4c36b576 0.893 (CI 0.889-0.906); 03b7c88fca27e151 0.932 (CI 0.922-0.941).
- **Session:** 2026-11-21 06:40

## Contiguous column range per wave instead of interleaved columns

- **Verdict:** loses
- **Applies when:** The waves of a workgroup share the columns of a column-major matrix and the source interleaves them (wave w takes columns w*8 + 64 j).
- **How:** Wave w takes columns [w*C, (w+1)*C) with C = 8*ceil(n/64), 8 consecutive columns per load, pointer stride 8*lda*4.
- **Measured:** rb_gemvn state f1676fee591cd6f5: 0.972 (CI 0.960-0.980).
- **Session:** 2026-11-21 06:40

## Cached per-lane loads of the vector operand are free

- **Verdict:** parity
- **Applies when:** A matrix-vector loop loads the small vector x (32 KB, cached) per lane next to cold matrix loads, and scalar loads of x look like a saving.
- **How:** Probe: replace the x loads by v_mov_b32 v, 1.0 in the bulk loop and time with probe.
- **Measured:** rb_gemvn probe 0c2948648c0685c8: 94.7 us against 95.1 us with the loads.
- **Session:** 2026-11-21 06:40

## Strided matrix reads: launch exactly one workgroup per CU

- **Verdict:** pays
- **Applies when:** A kernel whose workgroups each own a row range of a column-major matrix and read it in short fragments at a large stride (8 or more `global_load_dword` per iteration at a 32 KB stride), with the grid a free choice of rows per workgroup.
- **How:** Choose rows per workgroup so the grid equals the 256 CUs (BXX=32 at M=8192). Sweep with `source(like=baseline, defines={BXX, WAV, CPI}, launch={grid: cdiv(M, BXX), block: [BXX, WAV, 1]})`.
- **Measured:** rb_gemvn: 256 workgroups 1.00; 128 workgroups 0.962 (0.957-0.968); 512 workgroups 0.822 and 0.792; 32 workgroups 0.465.
- **Session:** 2026-11-21 06:44

## Waves per workgroup against loads per wait: no gain at a fixed workgroup count

- **Verdict:** parity
- **Applies when:** Load-bound loop already issuing all of an iteration's loads before one `s_waitcnt vmcnt(0)`, workgroup count already at 256.
- **How:** Halve the waves per workgroup (block (32,8) instead of (32,16)) and double the columns per iteration (CPI 16 instead of 8), so each wave has 32 fragments in flight instead of 16.
- **Measured:** rb_gemvn 522f8bdc69f84df7: 0.996 (CI 0.989-1.000), 60 pairs.
- **Session:** 2026-11-21 06:44

## Contiguous 1 KB per wave load by giving each thread 4 consecutive rows

- **Verdict:** loses
- **Applies when:** Column-major matrix-vector product where a `global_load_dwordx4` per lane could read 4 consecutive rows of one column, making each wave load 1 KB contiguous; the row range per workgroup then grows to 256 and the grid shrinks to M/256.
- **How:** Source: r = (blockIdx.x*BXX + tx)*4, 4 accumulators per thread, block (64,16), grid cdiv(M,256), 4 columns per iteration (amdclang emits 4 dwordx4 of A + 1 of x per iteration).
- **Measured:** rb_gemvn fc1a42e5ee817f68: 0.465 (0.462-0.470), 1.31 TB/s against 2.8 TB/s.
- **Session:** 2026-11-21 06:44

## One-cache-line fragments with twice the workgroups

- **Verdict:** loses
- **Applies when:** Strided-read kernel where halving the rows per workgroup (16 rows = 64 B per fragment) would double the workgroups beyond the CU count.
- **How:** BXX=16 with block (16,16) CPI=8 (512 workgroups x 4 waves) or block (16,32) CPI=4 (512 x 8 waves).
- **Measured:** rb_gemvn: 1aa437e70602347a 0.822 (0.818-0.832); f620bee2adddb7e6 0.792 (0.777-0.804).
- **Session:** 2026-11-21 06:44

## 256 B fragments with half the workgroups

- **Verdict:** loses
- **Applies when:** Strided-read kernel where a full wave of 64 lanes could read 64 consecutive rows of one column (256 B) at the price of 128 workgroups.
- **How:** BXX=64, WAV=8, CPI=16, block (64,8), grid cdiv(M,64).
- **Measured:** rb_gemvn e98059d85cc48077: 0.962 (0.957-0.968).
- **Session:** 2026-11-21 06:44
