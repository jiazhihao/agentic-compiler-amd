# `vl_moe_align`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 09:22

**Harness verdict:** win 1.546x (95% CI 1.539 to 1.555) over the strongest amdclang build; outputs bit-identical to the original binary on 78 cases

## vl_moe_align: ISA-level analysis (bench NT=524288, E=256; baseline 45.5 us)

**Case:** not at the memory floor (reference headroom 2.2). The kernel is one counting workgroup (16 waves, one CU) that reads 2 MB and does 524288 LDS atomic adds, plus 132 loop-free fill workgroups that finish early. Each tensor element is touched once; the bound is what one CU can do.

### Time split (probes, us)
| variant | time |
|---|---|
| baseline | 45.5 |
| count workgroup exits at once (fill only) | 6.2 |
| count loops skipped (fill + zero + scan + expert_ids) | 8.6 |
| cold loads, no ds_add | 42.6 |
| cached loads, ds_add kept | 43.3 |
| cached loads, no ds_add | 23.2 |
| cached loads, lane-distinct ds_add addresses | 27.7 |
| prefetch by fill workgroups, no ds_add | 26.6 |
| pipelined loop, no ds_add (no prefetch) | 42.5 |

So on top of 8.6 us there are two independent bounds of the same size: cold reads through one CU (about 34 us) and ds_add collisions (about 35 us). Removing one alone gives nothing, which is why the earlier session's single-lever attempts measured parity or loss.

### Hot loop of amdclang (.LBB0_53, 126 instructions per iteration)
8 `global_load_dwordx4` (1 KB contiguous per wave each, 16 KB stride), 7 `v_lshl_add_u64` addresses, staged `s_waitcnt vmcnt(7..0)`, 32 `v_min_u32` (clamp to the dummy bin), 32 `v_lshl_add_u32 x, 2, s47`, 32 `ds_add_u32` into shared bins, exec-mask loop control. Nothing is in flight during the ds_adds.

### Differences in the best state (isa_diff baseline -> 4716127942de2487)
- +9 `vector_load_16B`: one prefetch load in the fill path (`.Lft0`: `v_cmp_ge_u64 vcc, s[16:17], v[4:5]` / `s_and_saveexec` / `v_lshl_add_u64 v[54:55], v[2:3], 2, s[4:5]` / `global_load_dwordx4 v[56:59]` / restore exec), and the 8 loads of the first tile in the preheader of the pipelined loop.
- +32 `valu_min_max`: the preheader's clamps (pipelining duplicates the clamp phase once).
- `v_lshl_add_u32 m, 6, v60` with `v60 = 0x1080 + 4*(lane & 15)` in place of `v_lshl_add_u32 m, 2, s47`: 16 slots per bin.
- +1 loop `.Lzero` (ds_write_b32 per 4 KB) before the barrier; +7 `ds_read2_b32` and 16 `v_add_u32` in `.Lft25` to merge the slots; tail loops and the expert_map path add into slot 0 (shift 6).
- Loop `.LBB0_53`: 129 instructions, +3 SALU (`s_mov_b64 s[50:51], exec`, `s_mov_b64 exec, s[50:51]`, `s_andn2_b64 exec, s[50:51], s[42:43]`).
- VGPRs 54 -> 94, LDS dynamic 1280 B -> 20544 B (E=256).

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| pipelined loop alone | up to 1.6x if bounds were latency | ac6029e1d5e4eebb 1.013 (1.005-1.021) | parity: both bounds are throughput |
| prefetch by fill workgroups | memory bound 34 -> ~18 us, visible only up to the LDS bound | d7d08a725d54d9b0 1.039 (1.033-1.047) | pays |
| + 64 slots per bin | ~31 us predicted | 0775c401e33b8e0b 1.235 (1.223-1.244) | pays, large LDS costs ~6 us |
| + pipelined loop | few % | 1ff5aa5e26f2be5f 1.263 (1.255-1.271) | pays a little |
| 16 slots per bin | less LDS, 0.4 collisions per instruction | 4716127942de2487 1.538 (1.530-1.544, 240 pairs) | best |
| 8 slots | | 90e4fb2c16bd6531 0.895 of best | loses to 16 |
| 32 slots | | ac1541b26554c4e1 0.919 of best | loses to 16 |
| wave-contiguous 8 KB reads | TLB locality | probe 88 us | loses (64 lines per load) |

### What bounds the best state
Best 30.0 us; without ds_adds 27.8; with cached loads 28.6; without ds_adds and 32 VALU 27.8. Memory and ALU are no longer the bound: the loop runs at the CU's load-instruction rate (2048 x4 loads in about 19 us) on top of the 8.6 us base. The ds_adds cost 2.3 us.

### Untested
- The pipelining contribution on the 16-slot state was not isolated (measured only on the 64-slot state: 1.235 -> 1.263).
- Collision cost depends on the id distribution; timing is on the bench case `normal/seed0` only. A heavily skewed distribution collides more in both baseline and best.
- The prefetch relies on the fill workgroups running concurrently with the counting workgroup (133 workgroups on 256 CUs); correctness does not depend on it.
- Several counting workgroups (the real structural lever) need cross-workgroup communication, which one launch with poisoned outputs cannot do soundly; not attempted.
- Fewer load instructions per byte is impossible with 16 B per lane; scalar-base loads or fewer waits were not tried because ALU measured free.

### Tried

| what | outcome | speedup |
|---|---|---|
| software-pipelined count loop alone on the baseline (next tile's 8 loads in flight during lshl+ds_add) | parity | 1.0134 |
| prefetch of topk_ids by the fill workgroups (one discarded x4 load per thread) | win | 1.0389 |
| prefetch + 64 slots per bin (fully collision-free ds_add, 70 KB LDS) | win | 1.2352 |
| prefetch + 64 slots + pipelined loop | win | 1.2633 |
| prefetch + 16 slots per bin (21 KB LDS) + pipelined loop | win | 1.538 |
| 8 slots per bin (12 KB LDS), same otherwise | loss against the 16-slot state (compare 0.895, CI 0.890-0.898), still a win over baseline (~1.37 derived) | 0.8948 |
| 32 slots per bin (37 KB LDS), same otherwise | loss against the 16-slot state (compare 0.919, CI 0.915-0.922), ~1.41 over baseline derived | 0.9194 |
| PROBE: wave-contiguous 8 KB (each lane reads 128 contiguous bytes, 64 cache lines per load instruction) instead of 8 x 1 KB at a 16 KB stride | probe only: 88 us against 45.5 us (2x slower), not pursued | None |
| PROBES for the time split (not results): cached loads + ds 43.3 us; cold + no ds 42.6; cached + no ds 23.2; cached + lane-distinct ds addresses 27.7; prefetch + no ds 26.6; pipelined + no ds 42.5; best without ds 27.8; best with cached loads 28.6; best without ds and without 32 lshl_add 27.8 | diagnostic | None |
