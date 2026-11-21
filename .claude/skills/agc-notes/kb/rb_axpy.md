# Knowledge-base entries from `rb_axpy`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## One wave per workgroup with 1 KB per wave and loads in flight does not transfer from scal to axpy

- **Verdict:** loses
- **Applies when:** Elementwise, touch-once, loop-free kernel with two read streams and one in-place write (y = y + a*x), amdclang build at headroom about 0.95
- **How:** edit_ir: block 64, grid cdiv(N,256); per wave global_load_dwordx2 of y and x at offset 0 and offset:512 (4 loads in flight), s_waitcnt vmcnt(2), 2 v_fmac, store, s_waitcnt vmcnt(1), 2 v_fmac, store offset:512; mask-free fast path when (wg+1)*256 <= n, masked 2-step loop otherwise
- **Measured:** rb_axpy d82054e14c14b81c: 0.974 (CI 0.970..0.976, 240 pairs); the same recipe was 1.12x on rb_scal
- **Session:** 2026-11-21 05:41

## Two sequential 512 B tiles per wave (coarsen-2 pattern, hand-written mask-free fast path)

- **Verdict:** parity
- **Applies when:** Loop-free elementwise kernel launched as one 512 B tile per wave on a grid of more than 100k workgroups, at the memory floor
- **How:** edit_ir: block 256, grid cdiv(N,1024), lane index wg*1024 + 2*tid; load y, x; s_waitcnt vmcnt(0); v_fmac x2; store; then the same at offset:2048; scalar compare (wg+1)*1024 <= n selects the mask-free path
- **Measured:** rb_axpy bde630c55b36bbd2: 1.034 (CI 1.031..1.037) then 1.009 (CI 1.005..1.011); a4cb5c4521756f8f (coarsen 2 + hoisting): 1.040 then 0.983. Baseline time moved 154 to 165 us between runs
- **Session:** 2026-11-21 05:41

## Contiguous 1 KB per wave against two tiles 2 KB apart at block 256

- **Verdict:** loses
- **Applies when:** Two tiles per wave in a 4-wave workgroup on a two-stream read-modify-write kernel
- **How:** lane index wg*1024 + (tid>>6)*256 + 2*(tid&63) (v_and_b32 0x180 on tid<<1, v_add), second tile at offset:512 instead of offset:2048
- **Measured:** rb_axpy 1a9c9971dbfbd0af: 0.962 (CI 0.959..0.965) against 1.009 to 1.034 for the 2 KB-apart placement
- **Session:** 2026-11-21 05:41

## Next tile's loads in flight before the current tile's store

- **Verdict:** parity
- **Applies when:** Two sequential tiles per wave, each load/wait/fma/store
- **How:** issue tile B's two global_load_dwordx2 right after tile A's s_waitcnt vmcnt(0), before A's v_fmac and store; second wait becomes vmcnt(1) so it does not wait for the store
- **Measured:** rb_axpy be86f36bcac4cba2: 1.027 (CI 1.024..1.030), single run, against 1.034 for the sequential form in the same baseline condition
- **Session:** 2026-11-21 05:41

## Block 128 with two tiles per wave

- **Verdict:** parity
- **Applies when:** Same kernel class; keeps amdclang's workgroup count and halves the waves
- **How:** block 128, grid cdiv(N,512), lane index wg*512 + 2*tid, second tile at offset:1024
- **Measured:** rb_axpy 95733e125d8bd9d3: 0.997 (CI 0.994..1.000)
- **Session:** 2026-11-21 05:41

## Fewer instructions and no exec masks at amdclang's geometry

- **Verdict:** parity
- **Applies when:** Loop-free memory-bound kernel whose amdclang code carries 64-bit index compares, two saveexec regions and a VALU test of a scalar argument
- **How:** scalar alpha test (s_lshl_b32 by 1, s_cmp_eq_u32 0), one scalar compare (wg+1)*512 <= n to a mask-free path, v_fmac_f32_e32 with the SGPR alpha instead of v_pk_fma
- **Measured:** rb_axpy 07c7449cdc0ee15a: 1.0004 (CI 0.997..1.002, 240 pairs)
- **Session:** 2026-11-21 05:41

## Repeat small wins: the baseline's time is bimodal between runs

- **Verdict:** parity
- **Applies when:** Any win below about 5 % on a memory-bound kernel in the 150 us class
- **How:** bench the same state twice at pairs=240 and look at reference_ms in both results; trust only the lower speedup
- **Measured:** rb_axpy: reference_ms 153.9 to 164.8 us across runs; a4cb5c4521756f8f 1.040 then 0.983; bde630c55b36bbd2 1.034 then 1.009
- **Session:** 2026-11-21 05:41
