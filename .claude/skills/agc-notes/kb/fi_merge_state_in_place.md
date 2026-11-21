# Knowledge-base entries from `fi_merge_state_in_place`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Speculative row loads before a data-dependent early exit

- **Verdict:** loses
- **Applies when:** Kernel tests a per-workgroup flag (global_load_ubyte + s_waitcnt vmcnt(0) + branch to s_endpgm) before issuing its row loads, the flag skips a large fraction of the workgroups, and the rows are cold (touch-once)
- **How:** Issue the flag load first, then the address arithmetic and all row loads, then s_waitcnt vmcnt(n_row_loads) and the test; masked waves exit with loads outstanding
- **Measured:** fi_merge_state_in_place 31cbd23ae1b82305: 0.634 (0.629..0.641); +270 MB read = +59 us (4.6 TB/s)
- **Session:** 2026-11-21 08:42

## Scalar early-exit test in place of a per-lane byte load

- **Verdict:** parity
- **Applies when:** Wave-uniform u8 flag read with v_mov + global_load_ubyte + vmcnt(0) + v_cmp before an early exit; probe shows the test costs about 1 us over pure dispatch
- **How:** s_and_b32 off, s2, -4; s_load_dword w, s[mask], off; s_and_b32 sh, s2, 3; s_lshl_b32 sh, sh, 3; s_waitcnt lgkmcnt(0); s_lshr_b32 w, w, sh; s_and_b32 w, w, 0xff; s_cmp_lg_u32 w, 0; s_cselect_b64 mask, -1, 0
- **Measured:** fi_merge_state_in_place 69be43699488cbca: 1.004 (0.996..1.011, 60 pairs), bit-identical
- **Session:** 2026-11-21 08:42

## Scalar bases and 32-bit vector offsets instead of per-lane 64-bit addressing

- **Verdict:** parity
- **Applies when:** Loop-free touch-once kernel whose prologue has several v_lshl_add_u64 / v_lshlrev_b64 per stream and whose arithmetic-removed probe equals the baseline
- **How:** s_mul_i32 for the workgroup's first element, s_lshl_b64 by 2, s_add_u32/s_addc_u32 onto each pointer; per-lane offset by v_mul_lo_u32 + v_lshl_add_u32; global_load_dwordx4 v[..], vOff, s[base:base+1]; stores likewise
- **Measured:** fi_merge_state_in_place 47b6629a93c10273: 0.9996 (0.9964..1.0024, 240 pairs); -8 VALU, +20 SALU
- **Session:** 2026-11-21 08:42

## 8 B per lane with one row per wave when it doubles the waves and needs a 2D grid

- **Verdict:** loses
- **Applies when:** amdclang build with two 512 B rows per wave at 16 B per lane, 16 waves per workgroup at the 1024-thread limit, about half of the workgroups exiting early
- **How:** On the 2D-grid source build: tx shift 3, global_load_dwordx2, one v_pk_mul + one v_pk_fma, global_store_dwordx2; relaunch block [64,16], grid [P, cdiv(H,16)]
- **Measured:** fi_merge_state_in_place f3128dab5c8ec389: 0.850 (0.848..0.853, 240 pairs); the 2D grid with amdclang's body alone 0.980
- **Session:** 2026-11-21 08:42

## 32 B per lane (2 KB per stream per wave) to halve the waves

- **Verdict:** loses
- **Applies when:** Touch-once row kernel at 16 B per lane and 1 KB per stream per wave, block (32, H)
- **How:** tx shift 5; second global_load_dwordx4 with offset:16 for each stream into fresh registers; waits vmcnt(5), (4), (2), (0); 4 v_pk_mul + 4 v_pk_fma; two stores; relaunch block [16, H]
- **Measured:** fi_merge_state_in_place 39bb57733684016a: 0.970 (0.962..0.977)
- **Session:** 2026-11-21 08:42

## Request the in/out stream before the read-only stream

- **Verdict:** parity
- **Applies when:** Two-input one-output elementwise kernel that overwrites one of its inputs, at the memory floor
- **How:** Swap the two global_load_dwordx4 and merge the vmcnt(1)/vmcnt(0) waits into one vmcnt(0)
- **Measured:** fi_merge_state_in_place 56190cb5f3390e59: 0.997 (0.991..1.004)
- **Session:** 2026-11-21 08:42

## Traffic model with an early-exit mask

- **Verdict:** parity
- **Applies when:** bench reports headroom below 1 on a kernel with a data-dependent early exit per workgroup
- **How:** Recompute the floor with the live fraction of the bytes: 20 us + live_read / 4.5 TB/s + live_written / 10.7 TB/s
- **Measured:** fi_merge_state_in_place: model 165 us (headroom 0.61); with half of the positions live 93 us against 101.5 us measured (headroom 1.1); split: dispatch 17.3 us, mask test 1.3 us, store 6 us, arithmetic 0 us, reads about 77 us
- **Session:** 2026-11-21 08:42

## Scalar loads for wave-uniform per-row values instead of same-address gathers

- **Verdict:** parity
- **Applies when:** A loop-free elementwise row kernel loads a per-row scalar with global_load_dword in every lane (64 lanes, 1 or 2 distinct addresses per wave) next to wide row loads of about 1 KB per wave
- **How:** v_readfirstlane_b32 of the row index, s_lshl, s_load_dword sX, s[base:base+1], sOff for row y0 and for min(y0+1, H-1) (clamp so that an odd H does not read past the buffer); v_mov_b32 vN, sX for all lanes, then save EXEC, s_and_b64 exec, exec, 0xffffffff00000000, v_mov_b32 vN, sY, restore EXEC. Drop the matching vmcnt waits, add lgkmcnt(0) before the v_mov.
- **Measured:** fi_merge_state_in_place 234d97268e8c9c45: 1.000 (CI 0.9957..1.0036, 240 pairs), bit-identical
- **Session:** 2026-11-21 08:46

## Small loads speculated ahead of a cheap early exit

- **Verdict:** loses
- **Applies when:** A kernel whose waves exit early on a data-dependent mask for a large fraction of the grid (here half of 262144 waves), with later loads whose addresses are known at entry
- **How:** Issue the later loads (here 4 s_load_dword of 16 B per wave) at entry together with the mask load; exiting waves wait for them at the mask's lgkmcnt(0)
- **Measured:** fi_merge_state_in_place d79d64dc6be1dcf0: 0.980 (CI 0.976..0.983, 240 pairs); with the row loads speculated (earlier session, 31cbd23ae1b82305) 0.634
- **Session:** 2026-11-21 08:46

## One looping wave per masked row-group instead of 16 loop-free waves

- **Verdict:** loses
- **Applies when:** Row kernel launched as one workgroup of 16 waves per position with a per-position early exit, 1 KB per stream per wave, time near the memory floor
- **How:** Source: block [64,1], grid [P]; tx = threadIdx.x & 31, each thread loops head = threadIdx.x >> 5; head < H; head += 2 with the original body
- **Measured:** fi_merge_state_in_place 1491be2f40405ab3: 0.885 (CI 0.878..0.889); unroll_loads refuses the multi-block loop
- **Session:** 2026-11-21 08:46
