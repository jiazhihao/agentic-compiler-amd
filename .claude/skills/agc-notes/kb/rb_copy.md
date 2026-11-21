# Knowledge-base entries from `rb_copy`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `rb_copy` (copy, touch-once)

- **Verdict:** pays, 1.019x (harness-verified, 95% CI 1.017 to 1.023)
- **Applies when:** the kernel is of this kind: copy, touch-once
- **How:** import + coarsen; the recipe is `bench/llm/sessions/rb_copy/best.s`.
- **Measured:** rb_copy is at the memory floor (baseline headroom 1.05-1.07 against the copy model, each element touched exactly once: 268 MB read + 268 MB written at 4.84 TB/s), so 1.5x is out of reach; no bytes can be saved in a copy. The shipped state 77237b7fd663ab44 is `coarsen` factor 2 on amdclang's code: each launched workgroup runs two consecutive original workgroups, so each wave copies one 512 B tile (load, wait, store) and then the tile 2048 B further, halving the workgroup count while keeping the short-contiguous-tile access pattern. Two 240-pair timings: 1.0355 (CI 1.031-1.039) and 1.0186 (CI 1.015-1.022), both wins; an earlier 60-pair timing was 1.0175 (parity by CI). No source state of mine was made (source variants from earlier sessions were all parity or loss).
