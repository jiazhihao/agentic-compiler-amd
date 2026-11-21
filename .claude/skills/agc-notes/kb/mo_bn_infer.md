# Knowledge-base entries from `mo_bn_infer`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Per-channel gathers and arithmetic are free on a memory-floor elementwise kernel

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel, one x4 load and one x4 store per lane, plus several global_load_dword gathers of small per-channel tables and a per-lane integer division; headroom about 1.0
- **How:** Probe first: edit out the gather loads and the VALU between load and store (copy at the same geometry) and compare with the full kernel before writing scalar-load or cheaper-math variants
- **Measured:** mo_bn_infer probe a69105dc03e74785: 88.2 us against 88.3 us for the full kernel (4 gathers, v_rsq, 4 v_pk_add/mul, 2 v_pk_fma removed)
- **Session:** 2026-11-21 07:06

## Empty-kernel probe gives the dispatch share of a many-workgroup launch

- **Verdict:** parity
- **Applies when:** Grid above about 100k one-wave workgroups; bench headroom near 1.0 and the question is whether fewer workgroups could help
- **How:** edit: insert s_endpgm at index 0 of the entry block, probe; compare with the full time and with no-load / no-store probes
- **Measured:** mo_bn_infer 90ed32da70c1cc5c: 45.1 us empty against 88.3 us full at 200704 workgroups; no-store 65.4 us, no-load 50.1 us. Yet fewer workgroups were slower (block 256: 0.969, NPT=2: 0.960, coarsen 2/4/8: 0.983/0.905/0.859)
- **Session:** 2026-11-21 07:06

## Splitting a dwordx4 load into two dwordx2 loads in flight

- **Verdict:** parity
- **Applies when:** One global_load_dwordx4 per lane on a contiguous stream at the memory floor
- **How:** replace with global_load_dwordx2 v[2:3], addr, off offset:8 and global_load_dwordx2 v[0:1], addr, off; waits unchanged
- **Measured:** mo_bn_infer 8b67e295e30702dc: 0.994 (CI 0.984..0.999, 60 pairs)
- **Session:** 2026-11-21 07:06

## Fastest grid dimension across far-apart images instead of along contiguous tiles

- **Verdict:** loses
- **Applies when:** 2D grid where one dimension walks contiguous 1 KB tiles and the other steps by a large stride (here 200 KB per batch image)
- **How:** swap the roles of s2 and s3 in the code and relaunch with the grid dims exchanged, so workgroup id x steps across images
- **Measured:** mo_bn_infer 9cb6a15b6a876a79: 0.813 (CI 0.806..0.821, 60 pairs), throughput 3.8 TB/s against 4.65
- **Session:** 2026-11-21 07:06

## More waves per workgroup or two images per wave on a 1 KB-per-wave elementwise kernel

- **Verdict:** loses
- **Applies when:** Baseline already one wave per workgroup, 16 B per lane, 1 KB contiguous per wave, headroom about 1.03
- **How:** source defines BLK=256 (4 waves per workgroup) or NPT=2 (two x4 loads 200 KB apart in flight, then two stores, grid y halved)
- **Measured:** mo_bn_infer d99fdbd3d7223f7c: 0.969 (0.961..0.976); 02cc8af4a240bd1b: 0.960 (0.947..0.966)
- **Session:** 2026-11-21 07:06

## Half a wave per workgroup (512 B per wave) on a 1 KB-per-wave elementwise kernel

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel, one wave per workgroup, 16 B per lane, tid built as (workgroup id << 6) | lane, headroom about 1.0
- **How:** edit the tid shift to 5 (v_lshl_or_b32 v1, s2, 5, v0) and relaunch with grid cdiv(C*HW4, 32) and block 32
- **Measured:** mo_bn_infer 423cb9304444a6c1: 0.846 (CI 0.840..0.848, 60 pairs), 3.93 TB/s against 4.66
- **Session:** 2026-11-21 07:11

## Two contiguous 1 KB tiles per wave with all loads in flight before the stores

- **Verdict:** loses
- **Applies when:** Loop-free elementwise kernel at the memory floor where an empty-kernel probe shows a large dispatch share (45 of 88 us) and coarsen already lost
- **How:** edit_ir: tid A = (wg << 7) | lane, tid B = A + 64; duplicate index computation with registers +40; EXEC mask per tile (s_and_saveexec twice, mask B saved with s_mov_b64); issue both tiles' loads, then arithmetic + store A, then B; apply fix_waits; relaunch grid cdiv(C*HW4, 128), block 64
- **Measured:** mo_bn_infer 38fa0bcf52e54dd7: 0.942 (CI 0.937..0.955, 60 pairs)
- **Session:** 2026-11-21 07:11

## Scalar-load fast path for wave-uniform per-channel parameters

- **Verdict:** parity
- **Applies when:** Per-lane global_load_dword gathers from small tables whose index is the same for all lanes of most waves; kernel at the memory floor and a probe shows the gathers cost nothing
- **How:** v_readfirstlane_b32 of the index, v_cmp_eq_u32_e64 against all lanes, s_and_b64 with the bounds mask, s_cmp_eq_u64 -1, branch to a path with s_load_dword base, s_offset and scalar operands (v_subrev_f32, v_fma_f32 with one SGPR); original body as the slow path
- **Measured:** mo_bn_infer d863fb176d93a338: 0.976 (CI 0.970..0.991, 60 pairs)
- **Session:** 2026-11-21 07:11

## Kernarg scalar loads merged into one batch at entry

- **Verdict:** parity
- **Applies when:** Loop-free kernel that loads some kernargs at entry and the rest after an early-exit branch, with two lgkmcnt(0) waits
- **How:** move the later s_load_dwordxN to the entry before the first wait, rename scalar temporaries that collide, delete the second s_waitcnt lgkmcnt(0)
- **Measured:** mo_bn_infer cfa1ef93f7483414: 1.0005 (CI 0.987..1.009, 60 pairs)
- **Session:** 2026-11-21 07:11

## Relaunch with a block above the code's launch bound fails at launch

- **Verdict:** loses
- **Applies when:** Imported amdclang code built with __launch_bounds__(B) and a relaunch that raises the block size
- **How:** do not relaunch; rebuild with source and the larger bound
- **Measured:** mo_bn_infer eeb0d5e170b45609 (block 128 on a 64-bound build): hipModuleLaunchKernel 719, static_check passed
- **Session:** 2026-11-21 07:11
