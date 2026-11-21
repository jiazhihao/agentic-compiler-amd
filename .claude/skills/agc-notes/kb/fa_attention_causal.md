# Knowledge-base entries from `fa_attention_causal`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `fa_attention_causal` (attention (re-reads K and V))

- **Verdict:** pays, 1.992x (harness-verified, 95% CI 1.987 to 1.995)
- **Applies when:** the kernel is of this kind: attention (re-reads K and V)
- **How:** source + edit + edit + fix_waits + fix_hazards + edit + edit + fix_waits + fix_hazards; the recipe is `bench/llm/sessions/fa_attention_causal/best.s`.
- **Measured:** State 0b098c783edb33f3 is 1.99x over the strongest amdclang build (43.9 us against 87.4 us, 240 pairs, CI 1.987 to 1.996; full battery 49/49; 128 VGPRs, same launch, no source state involved, so the whole gain is machine-level). It rewrites the whole tile loop of the baseline: K and V rows are laid across lanes (16 lanes cover one 256-byte row, 4 keys per global_load_dwordx4 with scalar base + 32-bit clamped vector offset, so a load instruction touches 16 cache lines instead of 64 different rows), the query sits per lane in 4 VGPRs pre-multiplied by scale, the dot product is 2 v_pk ops + 4 DPP steps, the tile max goes through 4 v_readlane, probabilities stay in registers with the same lane layout as V so the value update is plain v_fmac into 4 per-lane partial accumulators, and both LDS reduction trees (32 ds_read_b128 + 100 VALU per tile), the LDS probability buffer and amdclang's three masked value loops are gone. l and the output stay partial per lane and are folded once at loop exit (readlane for l, one ds_write_b128 + two ds_read2st64 through the wave's private LDS slices for the output); amdclang's cross-wave merge tail is unchanged. Case: not at the memory floor (headroom 4.3 before, 2.15 now); the kernel re-reads K and V once per query (about 1 GB of cached traffic against the 1.6 MB the model counts), and reading them once for several queries is the lever that remains.
