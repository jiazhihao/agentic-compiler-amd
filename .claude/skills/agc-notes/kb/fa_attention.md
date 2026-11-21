# Knowledge-base entries from `fa_attention`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `fa_attention` (attention (re-reads K and V))

- **Verdict:** pays, 2.085x (harness-verified, 95% CI 2.082 to 2.090)
- **Applies when:** the kernel is of this kind: attention (re-reads K and V)
- **How:** source + edit_ir + fix_waits + fix_hazards; the recipe is `bench/llm/sessions/fa_attention/best.s`.
- **Measured:** State 24806d22981b1909 is 2.088x over the strongest amdclang build (26.3 us against 55.0 us, 240 pairs, CI 2.084 to 2.094; full battery 77/77; 106 VGPRs; no source state involved, so the whole gain is machine-level). It is a complete rewrite of the kernel body with a new launch (grid cdiv(NQ,16), block 512): each wave computes 16 queries x 16 keys per tile with v_mfma_f32_16x16x4_f32, 16 MFMAs for the scores (A = K, B = Q pre-multiplied by scale*log2e, lanes laid out so every x4 load touches 16 cache lines) and 16 MFMAs for the value update (A = the exponentiated score registers used in place, B = V rows across lanes), so K and V are read once per 16 queries instead of once per 4. The softmax is a per-wave online softmax with a lazily updated reference max (a rare slow path through the wave's private LDS slice, no barrier), the 8 waves of a workgroup interleave key tiles and merge max / sum / output once at the end through LDS with 2 barriers. Case: not at the memory floor in the model's sense (headroom 2.7 before, 1.3 now, but the model counts 1.6 MB while the kernel now reads K and V 128 times, 128 MB); what bounds it now is MFMA time on the SIMDs of the one CU a workgroup runs on together with the load round trip per tile, and only half of the CUs are used (128 workgroups).
