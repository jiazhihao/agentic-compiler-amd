# Knowledge-base entries from `mla_decode`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## What won on `mla_decode` (attention (re-reads the KV cache))

- **Verdict:** pays, 1.565x (harness-verified, 95% CI 1.564 to 1.566)
- **Applies when:** the kernel is of this kind: attention (re-reads the KV cache)
- **How:** source + edit + edit; the recipe is `bench/llm/sessions/mla_decode/best.s`.
- **Measured:** State 122f40f8cef6d0a7 is 1.560x over the baseline at 240 pairs (CI 1.557 to 1.563; 1.566x at 60 pairs), battery 98/98; the previous recipe 5553e312 was 1.49x. It is built on a new source state 92815d94 (the baseline source with HB=4 heads per workgroup and NCG=2 column groups, grid [cdiv(H,4), B, 2], still 256 workgroups), whose amdclang build is a loss on its own (0.863x), so the gain over my own source state is about 1.81x (ratio of two timings against the baseline, not a direct compare). The machine-level work: (1) key loop with 16 global_load_dwordx4 per iteration (256 B = two full cache lines per lane) and the 4 query rows read as wave-uniform scalars (s_load_dwordx16 in two phases per 64 B chunk, 128 scalar-operand v_fmac per chunk) instead of amdclang's 16 per-lane query loads per 4 key loads; (2) value loop with 16 row loads issued up front from a running pointer, accumulators as (x,y)/(z,w) pairs with p selected by op_sel, LDS p reads pipelined. Case: not at the memory floor in the headroom sense (headroom 6.9) because the KV cache is re-read by every workgroup; the lever that paid was fewer re-read bytes per workgroup (each workgroup reads all keys but only half of the value columns). Probes put the key phase at about 62 % of the remaining 170 us.
