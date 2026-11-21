# Knowledge-base entries from `fi_merge_states`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `fi_merge_states` (row merge with a short loop, touch-once)

- **Verdict:** pays, 1.105x (harness-verified, 95% CI 1.100 to 1.109)
- **Applies when:** the kernel is of this kind: row merge with a short loop, touch-once
- **How:** import + edit_ir + fix_waits + coarsen; the recipe is `bench/llm/sessions/fi_merge_states/best.s`.
- **Measured:** Best state d8824aa510a8974b: 1.136x over the baseline (240 pairs, CI 1.130..1.142; 0.0957 ms vs 0.1084 ms), battery 105/105. It adds a fast path to amdclang's 2x-unrolled merge loop: when at least 4 index sets remain, all 4 S dword loads and all 4 V dwordx4 loads are issued before any arithmetic (8 loads in flight, weakened vmcnt(7/6/3/2/1/0) waits), with the four merges computed in the original order (bit-identical); amdclang's loop keeps 4 loads in flight and waits to zero each iteration. On top, coarsen factor 2 (one launched workgroup runs two positions). No source state was made. Memory case: every element is touched exactly once; baseline headroom was 1.24, the best state is at 1.11 (3.54 TB/s), so 1.5x is out of reach in principle (the floor allows about 1.25x) and the remainder is at the memory floor.
