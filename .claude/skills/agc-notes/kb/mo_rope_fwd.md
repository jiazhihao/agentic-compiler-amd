# Knowledge-base entries from `mo_rope_fwd`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `mo_rope_fwd` (elementwise, touch-once)

- **Verdict:** pays, 1.013x (harness-verified, 95% CI 1.010 to 1.017)
- **Applies when:** the kernel is of this kind: elementwise, touch-once
- **How:** source + relaunch; the recipe is `bench/llm/sessions/mo_rope_fwd/best.s`.
- **Measured:** Machine-level gain: none (parity). The shipped state d5f5aa80fb92d7a5 is an amdclang build of a rewritten source plus a launch change, so its 1.68x over the shipped baseline (240 pairs, CI 1.679-1.688; 0.1116 ms vs 0.1880 ms) is credited to amdclang, not to machine-IR work. The rewrite handles two rotation pairs (16 bytes) per thread: x is read once with one global_load_dwordx4 instead of twice with dword loads (the baseline re-read x[gid+-1], so this was the 're-reads a tensor' case, reference headroom 1.79), cos/sin are dwordx4, the store is dwordx4, with a slow path for tails and the rotary wrap; block 64 instead of 256 adds 1.026x. The result sits at headroom 1.06 of the memory floor; on top of it, the hand-written machine IR (x load issued before the modulo, args loaded once, compact slow path) measured 1.0009 (CI 0.9993-1.0025, 240 pairs) and coarsen lost, so the kernel is at the memory floor and no machine-level win exists over the new amdclang build.
