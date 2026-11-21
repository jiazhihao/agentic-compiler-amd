# `fi_merge_state_in_place`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 08:42

**Harness verdict:** fallback: the session named no state faster than the baseline

## fi_merge_state_in_place: at the memory floor (explained parity)

### Case
Touch-once elementwise row kernel with a per-position early exit. The traffic model assumes all positions are processed (541 MB read, 270 MB written, floor 165 us, headroom 0.61). The mask is 0/1 at random, so about half of the workgroups exit after one byte load: real traffic about 270 MB read + 135 MB written, floor = 20 + 270/4.5 + 135/10.7 = 93 us against 101.5 us measured, i.e. headroom about 1.1. Nothing is re-read; fewer bytes cannot be touched.

### Time split (bench shapes P=16384, H=32; probes)
| phase | us |
|---|---|
| total (baseline) | 101.5 |
| dispatch of 16384 workgroups x 16 waves (immediate exit, 829f2a2a4da4ca6c) | 17.3 |
| + mask byte load and test (2e12100dca337e75) | 18.6 (+1.3) |
| arithmetic (exp2, division, log) replaced by an add (528e6a8e32284105) | 101.7 (0) |
| row store deleted (96fb6a94009c26a4) | 95.8 (store about 6) |
| row reads (remainder) | about 77 |

Check on the read rate: the speculative state reads the masked rows as well (+270 MB) and takes 160.2 us, +59 us = 4.6 TB/s, the cold-read rate of the device.

### amdclang's code
112 instructions, loop-free. Per wave (2 heads x 32 lanes): s_load of the mask pointer, global_load_ubyte + vmcnt(0), exit; else two more s_loads, 8 VALU of 64-bit addressing, two global_load_dword (s, s_other), two global_load_dwordx4 (1 KB per stream per wave), 46 VALU of scale arithmetic done while the row loads are in flight (waits vmcnt(3), (2), (1), (0), already late and weak), 2 v_pk_mul + 2 v_pk_fma, one global_store_dwordx4, and the s store from lane tx == 0. There is no loop, no LDS, no barrier, and the waits are already where the data is needed.

### isa_diff baseline -> 47b6629a93c10273 (the leanest hand state)
+20 SALU (scalar bases, mask word shift), +1 scalar_load_4B, -1 vector_load_4B (global_load_ubyte), -6 valu_add_sub (v_lshl_add_u64), -1 bit op, -1 compare, -1 move, -1 wait (the vmcnt(0) after the mask load). Timing 0.9996 (CI 0.9964..1.0024, 240 pairs): the instructions are not where the time is.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| Row loads in flight before the mask result | shortens the load chain of live waves; costs the masked rows' reads | 31cbd23ae1b82305: 0.634 (0.629..0.641) | loses: +270 MB of cold reads |
| Scalar mask test (s_load_dword + shift) | at most 1.3 us | 69be43699488cbca: 1.004 (0.996..1.011), bit-identical | parity |
| Scalar bases + 32-bit vector offsets | 0 (arithmetic probe) | 47b6629a93c10273: 0.9996 (0.996..1.002), 240 pairs | parity |
| 8 B per lane, one head per wave (2D grid, block [64,16]) | 1.01..1.04 on fi_merge_state | f3128dab5c8ec389: 0.850 (0.848..0.853), 240 pairs; the 2D grid alone (fe73bf54aa5f7f79) 0.980 | loses |
| 32 B per lane, 2 KB per stream per wave, block [16,H] | fewer waves | 39bb57733684016a: 0.970 (0.962..0.977) | loses |
| Load order (in/out stream first) | unknown | 56190cb5f3390e59: 0.997 (0.991..1.004) | parity |
| coarsen 2/4/8 (earlier session) | fewer workgroups | 0.969 / 0.941 / 0.927 | loses |
| kernargs loaded at entry (earlier session) | one wait less | 59ede479ce0efcea: 1.000 | parity |
| source: 2D grid HPB=2 / 8, -ffast-math (earlier session) | | 0.963 / 0.988 / 1.002 | loss / parity |

### Untested
- Half-wave workgroups and several rows per wave with pipelined loads: measured parity or loss on the unmasked sibling fi_merge_state, and both bytes-per-lane directions lost here.
- A workgroup-level skip of masked positions cannot be expressed: the mask is data, the grid is fixed at launch, and the exit already costs only 1.3 us over pure dispatch.

Equivalence: 69be43699488cbca is bit-identical to the original binary on 78 cases; the state shipped is the baseline itself.

### Tried

| what | outcome | speedup |
|---|---|---|
| Speculative row loads: mask byte load + 4 row loads in flight before the mask is tested (vmcnt(4)), masked waves exit with loads outstanding | loss | 0.634 |
| Scalar mask test: s_load_dword of the aligned mask word + s_lshr/s_and, no global_load_ubyte / vmcnt(0) before the early exit (on top of kernargs loaded at entry) | parity | 1.004 |
| 8 B per lane: one head per 64-lane wave, dwordx2, block [64,16], grid [P, cdiv(H,16)] (edit of amdclang's 2D-grid build) | loss | 0.85 |
| amdclang's 2D-grid source build HPB=16 (earlier session's source, unmodified; timed to attribute the 8 B/lane loss) | loss | 0.98 |
| 32 B per lane: block [16,H], 4 heads / 2 KB per stream per wave, two dwordx4 per stream per lane, 6 loads in flight | loss | 0.97 |
| Scalar bases (s_mul_i32, s_lshl_b64, s_add/s_addc) + 32-bit vector offsets for all loads and stores, plus scalar mask test: 6 v_lshl_add_u64 + 2 v_lshlrev_b64 removed | parity | 1 |
| Load order swapped (in/out stream v requested before v_other), one vmcnt(0) | parity | 0.997 |
| probe: row store deleted (95.8 us against 101.5 us) | probe | None |
| Earlier sessions (kept, not repeated): coarsen 2/4/8 0.969/0.941/0.927; kernargs at entry 1.000; source 2D grid HPB=2 0.963, HPB=8 0.988; -ffast-math 1.002 | loss | 0.969 |

## Session 2026-11-21 08:46

**Harness verdict:** fallback: the session named no state faster than the baseline

## fi_merge_state_in_place: at the memory floor (explained parity), second machine-level session

### Case
Touch-once elementwise row kernel with a per-position early exit on `mask[pos]`. `bench`'s model assumes all positions are processed (541 MB read, 270 MB written, floor 165 us, headroom 0.61), which is wrong here: the mask is 0/1 at random, so about half of the workgroups exit after one byte. Real traffic is about 270 MB read + 135 MB written; floor = 20 + 270/4.5 + 135/10.7 = 93 us against 101 us measured (headroom about 1.1). Nothing is re-read, so fewer bytes cannot be touched.

### Time split (earlier session's probes, bench shapes P=16384, H=32)
| phase | us |
|---|---|
| total | 101.5 |
| dispatch of 16384 x 16 waves | 17.3 |
| mask byte load + test | 1.3 |
| scale arithmetic (exp2, 2 divisions, log2) | 0 |
| row store | about 6 |
| row reads | about 77 |

### amdclang's code
112 instructions, loop-free; per live wave 2 `global_load_dword` (s, s_other: 64 lanes gathering 2 addresses), 2 `global_load_dwordx4` (1 KB per stream), 46 VALU of scale arithmetic executed while the row loads are in flight, 2 `v_pk_mul` + 2 `v_pk_fma`, 1 `global_store_dwordx4`. Waits are already late and weak (vmcnt(3), (2), (1), (0)).

### isa_diff baseline -> 234d97268e8c9c45 (leanest state of this session)
+30 SALU, +5 scalar_load_4B (mask word, 4 x s/s_other), -3 vector_load_4B (no `global_load_ubyte`, no `global_load_dword`), -6 valu_add_sub (`v_lshl_add_u64`), +4 valu_move (`v_mov` of the scalars, twice under EXEC = upper 32 lanes), -2 waits. Only the two `global_load_dwordx4` remain as vector loads. Timing 1.000 (0.9957..1.0036, 240 pairs), bit-identical on 78 cases: the instructions and the small loads are not where the time is.

### Opportunities measured in this session
| what | expected | measured | verdict |
|---|---|---|---|
| Scalar loads for the wave-uniform s / s_other (s_load_dword x4 + half-wave EXEC v_mov) | <= 1 us (two gathers and two waits removed) | 234d97268e8c9c45: 1.000 (0.996..1.004), 240 pairs, bit-identical | parity |
| One wave per position looping over heads (source, block [64,1]); masked positions cost 1 wave instead of 16 | saves dispatch of masked waves, lengthens live waves | 1491be2f40405ab3: 0.885 (0.878..0.889) | loses |
| Scalar s loads in flight before the mask result | shorter chain in live waves, 16 B extra per masked wave | d79d64dc6be1dcf0: 0.980 (0.976..0.983), 240 pairs | loses |

### Earlier sessions (kept)
Speculative row loads 0.634; scalar mask test 1.004; scalar bases + 32-bit offsets 1.000; 8 B per lane 0.850; 32 B per lane 0.970; load order 0.997; coarsen 2/4/8 0.969/0.941/0.927; kernargs at entry 1.000; 2D-grid sources 0.963/0.988/0.980; -ffast-math 1.002.

### Untested
- A hand-pipelined version of the looped wave (loads of the next 1 KB tile in flight): `unroll_loads` refused amdclang's multi-block loop; both ingredients (more bytes in flight per wave: 0.970; fewer, longer workgroups: 0.93..0.97 and 0.885) lost on their own.
- A workgroup-level skip of masked positions is not expressible: the mask is data and the grid is fixed at launch; the exit costs 1.3 us in total.

Equivalence: 234d97268e8c9c45 is bit-identical to the original binary on 78 cases; the state shipped is the baseline itself.

### Tried

| what | outcome | speedup |
|---|---|---|
| Scalar s / s_other loads: v_readfirstlane of ty, 4 s_load_dword (head y0 and min(y0+1,H-1)) + v_mov under a half-wave EXEC mask, replacing the two global_load_dword that gather 64 lanes from 2 addresses; on top of scalar mask test and scalar bases (no vector 4-byte load left, 2 waits fewer) | parity | 1 |
| Source: one wave per position, block [64,1], each thread loops over heads hh, hh+2, ... (16 iterations of 1 KB per stream at H=32); masked positions cost one wave instead of 16 | loss | 0.885 |
| unroll_loads factor 2 on the looped source state | refused: no single-block loop | None |
| Scalar bases and the 4 scalar s loads issued at entry, in flight with the mask word load (speculative for masked waves, 16 B per wave) | loss | 0.98 |
| Earlier sessions (not repeated): speculative row loads 0.634; scalar mask test 1.004; scalar bases 1.000; 8 B/lane 0.850; 32 B/lane 0.970; load order 0.997; coarsen 2/4/8 0.969/0.941/0.927; kernargs at entry 1.000; 2D-grid sources 0.963/0.988/0.980; -ffast-math 1.002 | parity/loss | 1 |
