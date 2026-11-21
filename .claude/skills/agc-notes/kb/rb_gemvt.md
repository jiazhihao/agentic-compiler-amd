# Knowledge-base entries from `rb_gemvt`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `rb_gemvt` (matrix-vector, reduction across threads)

- **Verdict:** pays, 1.024x (harness-verified, 95% CI 1.021 to 1.029)
- **Applies when:** the kernel is of this kind: matrix-vector, reduction across threads
- **How:** source + edit + edit + fix_hazards; the recipe is `bench/llm/sessions/rb_gemvt/best.s`.
- **Measured:** State 03d805fc8464654e: 1.0245x over the strongest amdclang build (95% CI 1.022-1.028, 240 pairs, 87.3 us vs 89.5 us; battery 77/77). Two machine-level changes on the baseline: (1) the cross-thread reduction is done per wave with DPP adds + v_readlane, lane 0 of each wave writes its 4 column totals straight into sdata2[c][wave], which removes amdclang's 526-instruction 16-lane LDS stage (128 ds_read2) and one of the two barriers; (2) all 10 global_load_dwordx4 of the unrolled iteration are issued before the first wait (amdclang placed s_waitcnt vmcnt(3) + an FMA between the two batches of 5). The summation order of the reduction changes (within the manifest tolerance; the baseline is -ffast-math already). The 1.5x target is out of reach: this kernel is at the memory floor (headroom 1.12 -> 1.10; every element of A is read exactly once, contiguous columns, 268 MB at ~4.0 TB/s after the 20 us launch against the 4.5 TB/s cold-read rate). No source state of mine beat the baseline.
