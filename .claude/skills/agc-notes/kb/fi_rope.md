# Knowledge-base entries from `fi_rope`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `fi_rope` (elementwise with heavy math before the loads)

- **Verdict:** pays, 1.037x (harness-verified, 95% CI 1.030 to 1.041)
- **Applies when:** the kernel is of this kind: elementwise with heavy math before the loads
- **How:** source + edit + edit + fix_hazards + edit; the recipe is `bench/llm/sessions/fi_rope/best.s`.
- **Measured:** Memory-floor case: the baseline already reads and writes every element exactly once (83.9 MB each way) and sits at headroom 1.06-1.08, so 1.5x is not reachable; the shipped state 585cffcc3a1ab1fa is 1.046x over the baseline (240 pairs, CI 1.041-1.049, 47.4 us vs 49.5 us), leaving headroom 1.02. amdclang issues the 8 global_load_dwordx4 of the 4 heads only after ~1000 instructions of powf/sincosf; the winning state computes the source addresses and issues all 8 loads at the top of the kernel, before the wait for pos_ids (weakened to vmcnt(8)) and before the pow/sincos math, into registers the kernel never used (v56..v87), with the head index clamped to total-1 so the speculative loads stay in bounds on tail head groups. The final rotation keeps amdclang's operation order (v_pk_mul then v_pk_fma), so results are bit-identical; no source state was made.
