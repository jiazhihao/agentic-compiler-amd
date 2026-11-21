# Knowledge-base entries from `attn_decode`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `attn_decode` (attention (re-reads keys per workgroup))

- **Verdict:** pays, 1.549x (harness-verified, 95% CI 1.548 to 1.551)
- **Applies when:** the kernel is of this kind: attention (re-reads keys per workgroup)
- **How:** source + edit; the recipe is `bench/llm/sessions/attn_decode/best.s`.
- **Measured:** State a4109addcd127ff0 (machine-IR edit of the baseline, static check clean, battery 98/98) is 1.561x over the strongest amdclang build (CI 1.557-1.565, 240 pairs; 105 us against 164 us). amdclang's key phase gives every lane its own key row, so each global_load_dwordx4 touches 64 rows 4 KB apart; the rewritten key phase lets 32 lanes span one 512 B key row (each x4 load reads two contiguous rows), keeps the query parts in 4 VGPRs per lane (no s_load_dwordx16 per batch), sums the 32 per-lane partial dots with DPP (4 row folds + row_bcast:15), writes each score from lanes 16/48 to s_red[key] and lets each thread read its own score back, so the rest of amdclang's code is untouched. Loads are pipelined (16 in flight, the second 16 reissued into freed registers), partial tiles are masked with v_cmpx. Case: not at a memory floor - the kernel re-reads keys 32x (1 GB real traffic vs 67 MB in the model) and was bound by the access pattern of those re-reads per workgroup, not by bytes; my own source variant (4 queries sharing one key load) was a loss (0.91x) and is not part of the result.
