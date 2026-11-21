# Knowledge-base entries from `moe_gate_topk`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `moe_gate_topk` (top-k per row, launch-dominated)

- **Verdict:** pays, 1.015x (harness-verified, 95% CI 1.012 to 1.021)
- **Applies when:** the kernel is of this kind: top-k per row, launch-dominated
- **How:** source + edit; the recipe is `bench/llm/sessions/moe_gate_topk/best.s`.
- **Measured:** Best state ea498c783e5bd552: 1.148x over the baseline (240 pairs, CI 1.146..1.151; 31.3 us against 35.9 us). Most of it is a source rewrite (state a3f1f14b4b217381, 1.116x at 60 pairs, credited to amdclang): each (value, index) pair is packed into one finite double (high word = float bits + 0x00100000, low word = ~index for positive values / index for negative ones), so a compare-exchange of the top-8 sorting network is v_max_f64 + v_min_f64 instead of v_cmp_gt_i64 + four v_cndmask (hot loop 276 -> 173 instructions). The machine-level gain on top of that amdclang build is 1.027x (compare, 240 pairs, CI 1.023..1.031): the next iteration's two x4 loads are issued at the top of the loop and waited one iteration later (branch-free, last iteration re-reads its own chunk through an s_cselect step), and the 16 `v_max_f64 x, x` sNaN canonicalizations amdclang emits per iteration are removed (operands are finite by construction). 1.5x was not reached: the kernel is at 31 us with about 20 us of launch, and already below the copy-model floor (headroom 0.89); the model is touched-once and the kernel reads logits exactly once, so this is the 'at the floor / launch-dominated' case, with the remaining time in per-CU ALU throughput rather than bytes.
