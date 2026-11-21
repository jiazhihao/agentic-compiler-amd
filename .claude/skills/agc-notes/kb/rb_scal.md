# Knowledge-base entries from `rb_scal`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `rb_scal` (elementwise, touch-once, loop-free)

- **Verdict:** pays, 1.124x (harness-verified, 95% CI 1.119 to 1.128)
- **Applies when:** the kernel is of this kind: elementwise, touch-once, loop-free
- **How:** import + edit_ir; the recipe is `bench/llm/sessions/rb_scal/best.s`.
- **Measured:** State c5620b21f742aea0 is a hand-written kernel launched as one wave per workgroup (block 64, grid cdiv(N,256)), measured 1.122x over the baseline (CI 1.1185..1.1242, 240 pairs, 92.4 us against 103.8 us). Each wave owns 1 KB contiguous of x, read as two 512 B dwordx2 loads in flight (the second through the load's offset:512) with pipelined vmcnt(1) waits; the arguments come from one s_load_dwordx4, alpha==1 is a scalar compare, and full workgroups take a mask-free fast path while a masked two-step path handles the tail workgroup. Results are bit-identical (same single multiply per element). This is the memory-floor case: every element is read once and written once, the baseline's headroom is 0.99 and the winner's is 0.88 (5.8 TB/s), so the 1.5x target is out of reach; the gain comes from launch geometry and bytes per wave, not from arithmetic. amdclang's own build of the source at block 64 (f51abd628f21c5f3, 512 B per wave) is a loss at 0.873x, so the gain is not available from the source as written.
