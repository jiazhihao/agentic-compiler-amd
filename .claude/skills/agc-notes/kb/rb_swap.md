# Knowledge-base entries from `rb_swap`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Mask-free, scalar-base addressing rewrite of a loop-free swap at amdclang's geometry

- **Verdict:** parity
- **Applies when:** Loop-free touch-once kernel whose amdclang code is two wide loads, pipelined vmcnt(1) waits and two wide stores, wrapped in 64-bit index compares, s_and_saveexec regions and v_lshl_add_u64 addresses; headroom about 1.0
- **How:** edit_ir: s_lshl_b32 base, wg, 9; add base*4 to both pointers with s_add_u32/s_addc_u32; v_lshlrev_b32 v0, 3, tid; global_load_dwordx2 v[2:3], v0, s[4:5] / v[4:5], v0, s[6:7]; vmcnt(1); store; vmcnt(1); store; s_cmp_le_u32 (base+512), n selects this path, else a dword two-step path under a cumulative exec mask
- **Measured:** rb_swap c584821cb31c13da: 1.0022 (CI 0.9995..1.005, 240 pairs), bit-identical
- **Session:** 2026-11-21 05:56

## Two tiles per wave (hand-written coarsen 2) on a two-stream swap

- **Verdict:** loses
- **Applies when:** Loop-free kernel with one 512 B tile per wave per stream, two read+write streams, >100k workgroups, at the memory floor
- **How:** block 256, grid cdiv(N,1024); second tile through offset:2048 on the scalar-base loads/stores; sequential (522364198a9d1729) or all 4 loads in flight with vmcnt(2) waits (37911d49d9787da9)
- **Measured:** rb_swap: 0.9575 (CI 0.952..0.961) sequential, 0.9693 (CI 0.966..0.974) with loads in flight, baseline at 180 us; the `coarsen` pass at factor 2 (d271da3154283301) reads 1.045 only in runs where the baseline is at 195-197 us
- **Session:** 2026-11-21 05:56

## One wave per workgroup with 1 KB per wave and 4 loads in flight on swap

- **Verdict:** loses
- **Applies when:** Two-stream read+write elementwise kernel at headroom about 0.95-1.05 (the rb_scal recipe)
- **How:** block 64, grid cdiv(N,256); global_load_dwordx2 of x, y at offset 0 and offset:512; s_waitcnt vmcnt(2); two stores; vmcnt(2); two stores
- **Measured:** rb_swap 06907dae9df9cfe5: 0.9529 (CI 0.950..0.955, 240 pairs)
- **Session:** 2026-11-21 05:56

## 16 B per lane (dwordx4) on a swap that moves 8 B per lane

- **Verdict:** loses
- **Applies when:** amdclang already uses global_load_dwordx2 per lane on a memory-floor kernel; idea is 1 KB contiguous per wave
- **How:** block 256, grid cdiv(N,1024), v0 = tid<<4, global_load_dwordx4 v[4:7] / v[8:11] with scalar bases, vmcnt(1) pipelined stores
- **Measured:** rb_swap 2c9e0169434b4aff: 0.9703 (CI 0.965..0.974, 240 pairs); the source-level version a22eb67e0dc1168b was 0.9445
- **Session:** 2026-11-21 05:56

## Block 128 with the grid doubled, 512 B per wave kept

- **Verdict:** parity
- **Applies when:** Loop-free memory-floor kernel at block 256; idea is fewer waves per workgroup with the same bytes per wave
- **How:** same body, s_lshl_b32 base, wg, 8; launch block 128, grid cdiv(N,256)
- **Measured:** rb_swap 184b78d512949827: 1.093 / 0.995 / 1.097 / 0.973 over four 240-pair runs; candidate 180.7-183.9 us in all, baseline 198 / 181 / 199 / 180 us
- **Session:** 2026-11-21 05:56

## Block 128 with two tiles per wave 1 KB apart

- **Verdict:** loses
- **Applies when:** Same class; keeps amdclang's workgroup count and halves the waves
- **How:** block 128, grid cdiv(N,512), second tile at offset:1024, sequential load/wait/store per tile
- **Measured:** rb_swap f658dc1fad22b214: 0.9812 (CI 0.978..0.986, 240 pairs)
- **Session:** 2026-11-21 05:56

## Merged wait before both stores of a swap

- **Verdict:** parity
- **Applies when:** Two loads followed by two stores with pipelined s_waitcnt vmcnt(1) between them
- **How:** replace vmcnt(1) / store / vmcnt(1) / store by vmcnt(0) / store / store
- **Measured:** rb_swap 877d62c8bd36c8ed against 184b78d512949827: 1.0017 (CI 0.999..1.004, compare, 240 pairs)
- **Session:** 2026-11-21 05:56

## Check candidate_ms and reference_ms across runs before trusting a sub-10 % win

- **Verdict:** parity
- **Applies when:** Memory-floor kernel in the 150-200 us class whose baseline reference_ms differs by more than 3 % between bench invocations
- **How:** Repeat bench at pairs=240 three or four times; a candidate whose own time is constant while the speedup flips with reference_ms is not a win. Judge against the lowest reference_ms seen in the session
- **Measured:** rb_swap: baseline 179.5-181.2 us in 9 runs and 194.8-198.9 us in 5 runs; E constant at 180.7-183.9 us gave 0.973 to 1.097; coarsen 2 at 187-188.5 us gave 1.045 only in slow-mode runs
- **Session:** 2026-11-21 05:56

## Block 512 / 1024 at constant bytes per wave on a loop-free two-stream swap

- **Verdict:** loses
- **Applies when:** Loop-free memory-floor kernel at block 256 with one 512 B tile per wave per stream; idea is fewer, larger workgroups with the same waves
- **How:** source with __launch_bounds__(BLK) and tid = (blockIdx.x*BLK + threadIdx.x)*2, launch block BLK, grid cdiv(N, 2*BLK); optionally edit_ir the mask-free scalar-base body on that state (a relaunch of a 256-bound state to block 1024 fails with launch error 719)
- **Measured:** rb_swap: block 512 9b7179c706ad2972 0.962 (CI 0.952..0.970, 60 pairs); block 1024 source 17b8efbb67b72614 1.011 (CI 1.007..1.017, 60 pairs, slow-mode run, 190 us > 180 us fast mode); block 1024 hand body 1c360c132130ac8b 0.984 (CI 0.981..0.988, 240 pairs)
- **Session:** 2026-11-21 06:00

## 2D grid with the same linear tile order

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel on a 1D grid of >100k workgroups at the memory floor; idea is that dispatch order or grid shape matters
- **How:** source state with blockIdx.y*256 + blockIdx.x as tile index (enables s3 in the descriptor), grid (256, cdiv(N,131072)), block 256; then the hand body with s_lshl_b32 s9, s3, 8 / s_add_u32 s9, s9, s2 / s_lshl_b32 s9, s9, 9
- **Measured:** rb_swap f43156d133ed139d: 0.9993 (CI 0.996..1.003, 240 pairs), 179.6 vs 179.6 us
- **Session:** 2026-11-21 06:00

## Reversed stream order in a swap (load y first, store x first)

- **Verdict:** parity
- **Applies when:** Two loads then two stores with pipelined vmcnt(1) waits, two inout streams
- **How:** swap the order of the two global_load_dwordx2 and of the two stores, keeping vmcnt(1) before each store
- **Measured:** rb_swap b3474645d7f2202a: 1.0022 (CI 0.998..1.006, 240 pairs)
- **Session:** 2026-11-21 06:00

## Reversed traversal of the workgroup tiles

- **Verdict:** parity
- **Applies when:** Loop-free touch-once kernel whose workgroup i owns tile i; idea is descending address order
- **How:** after the kernarg wait: s_add_u32 s9, n, 511; s_lshr_b32 s9, s9, 9; s_sub_u32 s9, s9, s2; s_add_u32 s9, s9, -1; s_lshl_b32 s9, s9, 9 as the tile base (tail tile lands in workgroup 0)
- **Measured:** rb_swap cf6dd1fe3524ab4e: 0.9973 (CI 0.995..0.999, 240 pairs), 178.3 vs 177.8 us
- **Session:** 2026-11-21 06:00
