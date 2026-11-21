# Knowledge-base entries from `fi_rmsnorm`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `fi_rmsnorm` (row normalisation (reduction + second pass))

- **Verdict:** pays, 1.081x (harness-verified, 95% CI 1.077 to 1.084)
- **Applies when:** the kernel is of this kind: row normalisation (reduction + second pass)
- **How:** source + relaunch + edit_ir + fix_hazards; the recipe is `bench/llm/sessions/fi_rmsnorm/best.s`.
- **Measured:** Best verified state 158e86783f0ad7d4: 1.071x over the baseline (240 pairs, CI [1.066, 1.077], 0.1171 ms vs 0.1253 ms). Most of that is NOT machine-level: relaunching amdclang's unchanged code with 512 threads per workgroup instead of 1024 (8 waves, 2 rounds per thread at the bench shape; state c58877b909110425) is already ~1.05-1.06x. The machine-level part, measured directly with compare(c58877b909110425, 158e86783f0ad7d4, 240 pairs), is 1.021x (CI [1.017, 1.025]): a straight-line fast path for rounds<=4 that issues all rounds' masked input loads before one wait, keeps them in v[24:39] across the LDS reduction so the second pass does not re-read the input, puts the weight loads in flight together, and stores without a loop; rounds>4 falls back to amdclang's loops. Case: memory floor. Each element is read once and written once (the second input read in the baseline is a cache hit and removing it measured parity); reference headroom 1.17-1.20, final headroom 1.12; a probe with the whole cross-wave reduction and barrier removed was only 0.8% faster. 1.5x is out of reach without moving fewer bytes, and there are none to save. Correctness note: the battery at the shipped launch only ever runs rounds=1, so I verified the multi-round fast path (rounds=3 with a tail, eb8e69637301f073) and the fallback (rounds=8, ced1eadc5fbb2e07) with test-only relaunches of the same code; both pass 77/77.
