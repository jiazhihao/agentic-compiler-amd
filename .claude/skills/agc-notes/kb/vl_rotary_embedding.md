# Knowledge-base entries from `vl_rotary_embedding`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Cold in-place loads issued before the scalar wait for the row index

- **Verdict:** loses
- **Applies when:** Per-token kernel whose data addresses do not depend on a scalar-loaded index (positions[token]) but whose cached table loads do; prologue is scalar loads and about 60 SALU, no heavy math; headroom about 0.95
- **How:** Load positions into fresh SGPRs, delete the lgkmcnt wait in the prologue, issue the x and y global_load_dwordx4 first, then s_waitcnt lgkmcnt(0), compute the table pointers into fresh SGPRs, issue the table loads; fix_waits
- **Measured:** vl_rotary_embedding 5a0cabb1c90a9c87: 0.968 (0.965-0.971, 120 pairs)
- **Session:** 2026-11-21 09:07

## Cached table loads first, cold data loads staggered behind them

- **Verdict:** parity
- **Applies when:** Loop-free lane body with two cached loads (table row) and two cold loads (in-place data), amdclang order mixes them (sin, y, cos, wait, x)
- **How:** Reorder in the hot block: sin, cos loads; after sin arrives issue y (or x); after the sign-select issue the other; fix_waits. FP order untouched, bit-identical
- **Measured:** vl_rotary_embedding 11fb96fbe9cfe730: 1.012 at 120 pairs, 1.0007 (0.997-1.004) at 240 pairs; ascending variant f26363dc20e75fbf 1.012 (1.008-1.015, 120 pairs); fully serialized 06fd62161fedb1ad 0.985
- **Session:** 2026-11-21 09:07

## Smaller workgroups on a per-token kernel with a heavy per-wave prologue

- **Verdict:** loses
- **Applies when:** amdclang build launched as one multi-wave workgroup per token (block 640) whose code takes its stride from gridDim.y*blockDim.x, so relaunch alone changes the split; each wave pays 10 scalar loads and a per-lane division
- **How:** relaunch block 320 with grid [N, cdiv(groups,320)] and block 64 with grid [N, cdiv(groups,64)]
- **Measured:** vl_rotary_embedding: block 320 0164b8e3c0d470f7 0.933 (0.929-0.941); block 64 b29e439d91c2933d 0.780 (0.777-0.784); coarsen 2/4/8 0.972/0.921/0.873
- **Session:** 2026-11-21 09:07

## Time split of an in-place 2-table rotation kernel by probes

- **Verdict:** parity
- **Applies when:** Loop-free in-place elementwise kernel with cached table re-reads, headroom below 1.0
- **How:** probe with: s_endpgm after the bounds mask; stores deleted; arithmetic replaced by storing the loaded x/y back; table loads deleted
- **Measured:** vl_rotary_embedding: 118.4 us total; empty 12.5 us; stores about 13 us; arithmetic about 0; 40x cached cos/sin re-read about 0; cold reads about 93 us
- **Session:** 2026-11-21 09:07

## Flat row-spanning 1024-thread workgroups with a per-lane metadata load

- **Verdict:** loses
- **Applies when:** One workgroup per row (token) smaller than 1024 threads, a per-row scalar (`s_load_dwordx2` of positions[row]) feeding the addresses of cold loads; the idea is to flatten (row, group) so workgroups are full
- **How:** source: flat = blockIdx.x*blockDim.x + threadIdx.x; row = flat / groups_per_row; per-lane load of the row's metadata; grid cdiv(N*groups, 1024), block 1024, N appended as kernarg
- **Measured:** vl_rotary_embedding 63899d655d6793bf: 0.936 (CI 0.933-0.944, 120 pairs) against block 640 one workgroup per token
- **Session:** 2026-11-21 09:11

## Block rounded up to 1024 with idle waves

- **Verdict:** loses
- **Applies when:** Per-row work fills fewer waves than the block (here 10 of 16); waves beyond the work exit at the bounds mask
- **How:** relaunch(baseline, block 1024, grid (N, cdiv(groups, 1024)))
- **Measured:** vl_rotary_embedding 684997e59c19b517: 0.9575 (CI 0.955-0.961); 98k idle waves = 5.4 us
- **Session:** 2026-11-21 09:11

## Two 16-byte groups per thread on an in-place rotate (32 B per lane)

- **Verdict:** loses
- **Applies when:** Elementwise in-place kernel already moving 16 B per lane per stream with x4 loads, at headroom about 1.0
- **How:** source: per-thread loop over 2 adjacent groups, block halved (320), same workgroups per row
- **Measured:** vl_rotary_embedding 00c54b7c353b6c98: 0.831 (CI 0.829-0.833)
- **Session:** 2026-11-21 09:11

## Swap the order of a wave's two wide stores

- **Verdict:** parity
- **Applies when:** Straight-line body ending in two global_store_dwordx4 to different halves of the same row
- **How:** edit: exchange the two store instructions (.Lft1[37:38])
- **Measured:** vl_rotary_embedding ffd17771307230ac: 1.0017 (CI 0.996-1.006)
- **Session:** 2026-11-21 09:11

## Cached loads first, cold loads staggered in ascending address order

- **Verdict:** parity
- **Applies when:** Loop-free body with two cached loads (table row) and two cold loads (in-place data), amdclang issuing three before the first wait
- **How:** edit: issue sin, cos loads; x load after sin arrives; y load after the sign-select; fix_waits
- **Measured:** vl_rotary_embedding f26363dc20e75fbf: 1.012 at 120 pairs, 1.0054 (CI 1.0008-1.0109) at 240 pairs
- **Session:** 2026-11-21 09:11
