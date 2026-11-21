# Knowledge-base entries from `rb_ger`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `rb_ger` (rank-1 update, touch-once)

- **Verdict:** pays, 1.015x (harness-verified, 95% CI 1.012 to 1.018)
- **Applies when:** the kernel is of this kind: rank-1 update, touch-once
- **How:** source + edit + edit; the recipe is `bench/llm/sessions/rb_ger/best.s`.
- **Measured:** rb_ger is at the memory floor: the baseline (loop-free, 16 bytes per lane, one 1 KB-contiguous wave per workgroup) has headroom 0.89-0.90 against the copy model (268 MB read + 268 MB written in 94 us, 5.7 TB/s), and every element of A must be read and written exactly once, so 1.5x is out of reach; x (32 KB) is re-read per column but from cache. The shipped state 119155ff4a28c113 only shortens the per-wave latency chain in the prologue: amdclang makes four sequential scalar-load round trips (alpha, m, pointers, y[col]) before the vector loads are issued; here all kernargs are fetched by two scalar loads issued together with one wait, and the y[col] load is in flight together with the x/A global_load_dwordx4 (its lgkmcnt wait and the res_y multiply moved after the vector loads, duplicated into the tail path). Bit-identical arithmetic, battery 77/77, 1.016x over the baseline (CI 1.0125-1.0182, 240 pairs). No source state was made.
