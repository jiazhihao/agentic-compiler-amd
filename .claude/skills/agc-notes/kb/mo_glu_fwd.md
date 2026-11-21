# Knowledge-base entries from `mo_glu_fwd`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `mo_glu_fwd` (elementwise, touch-once)

- **Verdict:** pays, 1.038x (harness-verified, 95% CI 1.035 to 1.042)
- **Applies when:** the kernel is of this kind: elementwise, touch-once
- **How:** source + coarsen; the recipe is `bench/llm/sessions/mo_glu_fwd/best.s`.
- **Measured:** Memory-floor case: the kernel reads 537 MB and writes 268 MB once each, and the baseline already runs at headroom 1.06 (0.175 ms against a 0.164 ms floor), so 1.5x is out of reach without touching fewer bytes, which an elementwise kernel cannot do. The shipped state is amdclang's -ffast-math code with `coarsen` factor 4 (one launched workgroup runs four consecutive original workgroups, bit-identical arithmetic): 1.045x over the baseline (240 pairs, CI 1.0425 to 1.0482), headroom 1.01. No source rewrite of my own was made; one launch-only variant of amdclang's build (block 1024) measured 1.032x and is below the shipped state.
