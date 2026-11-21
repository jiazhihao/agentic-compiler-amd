# `vl_rotary_embedding`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 09:07

**Harness verdict:** fallback: the named state 100168c99c55c164 did not verify as a win: parity; outputs bit-identical to the original binary on 99 cases

## vl_rotary_embedding: at the memory floor, no machine-level win

**Case:** touch-once. Every query/key element is read once and written once in place (337.8 MB read, 335.5 MB written); only the cos/sin cache row is re-read (40x per token, 512 B, cached). Baseline 118.4 us, 5.7 TB/s, headroom 0.92-0.94 against the copy model. 1.5x is not reachable without moving fewer bytes, and there are none to remove.

### Baseline hot path (state `baseline`, block 640 = one workgroup per token, 10 waves, 16 B per lane per stream)
- Prologue per wave: 10 scalar loads in 4 round trips (kernargs, then `positions[token]`, then hidden grid size), about 70 SALU, a per-lane unsigned division by groups-per-head (`v_rcp_iflag_f32` + 2 correction steps, about 25 VALU).
- `.Lft1` (the only block executed at the bench shape, once per lane): 14 `v_lshl_add_u64`/`v_mad_u64_u32` for addresses, 4 `global_load_dwordx4` (sin, y, cos, then x after `s_waitcnt vmcnt(2)`), 4 `v_xor` + 4 `v_cndmask` for `inverse`, 4 `v_pk_mul_f32`, 4 `v_pk_fma_f32`, 2 `global_store_dwordx4`. Waits are already weakened (vmcnt 2/2/1/0).
- The scalar tail loop `.LBB0_9` (dword loads, wait per iteration) never runs for rot_dim = 128.

### Time split (probes, single medians)
| variant | us | meaning |
|---|---|---|
| baseline | 118.4 | |
| empty body after the bounds mask (2102c74015378ca8) | 12.5 | launch + dispatch |
| stores removed (568f553ffbb4795b) | 105.6 | stores about 13 us |
| arithmetic removed, x/y copied back (3c1871cf2a31815b) | 120.5 | arithmetic about 0 |
| cos/sin loads removed (b1b73a78f7e655c4) | 120.3 | cached re-read about 0 |
| remainder | about 93 | cold x/y reads (3.6 TB/s) |

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| x/y loads issued before the wait for `positions[token]` (fi_rope recipe) | up to 3 % | 5a0cabb1c90a9c87: 0.968 (0.965-0.971, 120 pairs) | loses |
| 4 loads in flight before the first wait (earlier session) | 1-2 % | 2502b21712dc4ba7: 0.989 | loses |
| cached cos/sin first, cold y then x staggered | unknown | 11fb96fbe9cfe730: 1.012 (120 pairs), 1.0007 (0.997-1.004, 240 pairs) | parity |
| same, cold loads ascending (x then y) | unknown | f26363dc20e75fbf: 1.012 (1.008-1.015, 120 pairs; not repeated at 240) | parity |
| cold loads serialized (x after y arrived) | unknown | 06fd62161fedb1ad: 0.985 (0.981-0.986) | loses |
| one-round kernarg prologue (earlier session) | 1 % | 89add66e5750614d: 1.000 | parity |
| block 320, 2 workgroups per token | few % | 0164b8e3c0d470f7: 0.933 (0.929-0.941) | loses |
| block 64, one wave per workgroup | few % | b29e439d91c2933d: 0.780 (0.777-0.784) | loses |
| coarsen 2 / 4 / 8 (earlier session) | few % | 0.972 / 0.921 / 0.873 | loses |
| drop the cos/sin re-read (SGPR row or DPP broadcast) | 0 by probe | not built | no headroom |
| cheaper index arithmetic (shift instead of division, loop-free) | 0 by probe | not built | no headroom |

### ISA-level difference of the closest candidates to amdclang's code
Same instruction mix as the baseline (4 x 16 B loads, 2 x 16 B stores, identical VALU, FP order unchanged); only the order of the four `global_load_dwordx4` and the `s_waitcnt vmcnt` values differ. No state differs from amdclang's code in a way that pays.

### Untested
- 8 B per lane / 512 B per wave: needs 1280 threads per token (limit 1024) or two workgroups per token, which costs 7 % by itself (block 320).
- A flat (token, group) index with 1024-thread workgroups spanning 1.6 tokens: saves at most about 1.5 us of dispatch by the empty-launch probe.
- `equivalent` was not run: the shipped state is the baseline itself.

### Tried

| what | outcome | speedup |
|---|---|---|
| relaunch block 320, 2 workgroups per token (same code, step = gridDim.y*blockDim.x) | loss | 0.9329 |
| relaunch block 64, one wave per workgroup, 10 workgroups per token | loss | 0.7796 |
| x/y cold loads issued before the s_waitcnt for positions[token]; cos/sin pointers computed afterwards and cos/sin loaded last (on top of the one-round kernarg prologue 89add66e5750614d) | loss | 0.968 |
| S1: cached sin and cos loads first, y load after sin arrives, x load after the sin sign-select | parity | 1.0007 |
| S2: cold loads serialized, x issued only after y arrived | loss | 0.9847 |
| S3: as S1 with the cold loads in ascending address order (x then y) | parity | 1.0118 |
| earlier session: one-round kernarg prologue with positions load in the entry block | parity | 1 |
| earlier session: 4th global load issued before the first wait (4 in flight) | loss | 0.9886 |
| earlier session: coarsen factor 2 / 4 / 8 | loss | 0.9719 |
| probes (not results): no cos/sin loads 120.3 us, no arithmetic 120.5 us, no stores 105.6 us, empty body 12.5 us against 118.4 us | diagnostic | None |

## Session 2026-11-21 09:11

**Harness verdict:** fallback: the named state 100168c99c55c164 did not verify as a win: parity; outputs bit-identical to the original binary on 99 cases

## Session 2 summary: still at the memory floor (touch-once), no machine-level win

**Case:** touch-once. Query and key are read once and written once in place (337.8 MB read, 335.5 MB written); the 512-byte cos/sin row is the only re-read and is cached (0 us by the earlier probe). Baseline 118.5 us, 5.68 TB/s, headroom 0.94: it already beats the copy model. The earlier split stands (launch + dispatch 12.5 us, stores about 13 us, cold x/y reads about 93 us, arithmetic and cos/sin about 0); this session did not re-probe it.

### What this session measured (all against `baseline`, 120 pairs unless stated)
| what | kind | expected | measured | verdict |
|---|---|---|---|---|
| S3 load order (cos/sin first, cold x then y staggered), re-timed | wait/load order | 1 % | f26363dc20e75fbf: 1.0054 (1.0008-1.0109, 240 pairs) | parity |
| flat (token, group) index, 1024-thread workgroups, per-lane `positions` load (source) | launch geometry: fewer workgroups | up to 1.5 us dispatch | 63899d655d6793bf: 0.936 (0.933-0.944) | loses |
| block 1024, one workgroup per token, 6 idle waves | launch geometry: waves per workgroup | unknown | 684997e59c19b517: 0.9575 (0.955-0.961) | loses |
| two 16-byte groups per thread, block 320 (source) | bytes per lane / waves per token | -4 us of wave launch at best | 00c54b7c353b6c98: 0.831 (0.829-0.833) | loses |
| stores swapped (y then x) | store order | 0 | ffd17771307230ac: 1.0017 (0.996-1.006) | parity |

Together with the earlier session (4 loads in flight 0.989, loads before the positions wait 0.968, serialized cold loads 0.985, one-round prologue 1.000, block 320 0.933, block 64 0.780, coarsen 2/4/8 0.972/0.921/0.873) every lever family has been timed: load/wait order, prologue, workgroup size up and down, bytes per lane, coarsening, store order. The geometry optimum is exactly the baseline's: one 640-thread workgroup per token, 16 B per lane per stream, no idle waves.

### ISA-level difference from amdclang's code
None that pays. The closest candidates (S3, store swap) have the same instruction mix as the baseline (4 `global_load_dwordx4`, 2 `global_store_dwordx4`, 4 `v_pk_mul_f32`, 4 `v_pk_fma_f32`, same `v_lshl_add_u64` address chain) and differ only in the order of the vector memory instructions and the `s_waitcnt vmcnt` values. The flat-index build replaces the scalar `s_load_dwordx2` of `positions[token]` by a per-lane `global_load_dwordx2` and adds a second per-lane division (`v_rcp_iflag_f32` chain); that dependent vector load ahead of the cold loads is what loses.

### Derived machine fact
6 idle waves per workgroup x 16384 workgroups cost 5.4 us: wave launch is roughly 55 ns of wall time per 1000 waves, so the 164k working waves of the baseline cost about 9 us, consistent with the 12.5 us empty-body probe.

### Untested, and why
- 8 B per lane (512 B per wave per stream): needs 1280 threads per token or the flat index, which lost 6 % on its own.
- cos/sin row in SGPRs or by DPP broadcast, shift instead of division: 0 us available by the earlier probes.
- `equivalent` not run: the shipped state is the baseline (bit-identical to the original binary on 99 cases per the earlier harness verification).

### Tried

| what | outcome | speedup |
|---|---|---|
| S3 from the earlier session (cached cos/sin loads first, cold x then y staggered) re-timed at 240 pairs | parity | 1.0054 |
| source: flat (token, group) index, 1024-thread workgroups spanning 1.6 tokens, loop-free, per-lane positions[token] vector load, N appended as kernarg | loss | 0.9364 |
| machine edit: the two global_store_dwordx4 swapped (y half before x half) | parity | 1.0017 |
| relaunch block 1024, one workgroup per token (16 waves, 6 exit at the bounds mask) | loss | 0.9575 |
| source: two adjacent 16-byte groups per thread (32 B per lane per stream), block 320, 5 waves per token | loss | 0.8307 |
