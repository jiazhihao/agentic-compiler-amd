# Patterns across kernels

Read this before the per-kernel files. It is the curated summary of what the campaign over the LLM
benchmark measured (issue #64, 2026-11-21): which ISA-level optimization transfers between kernels,
when, and which pass does it. Numbers are harness-verified gains over the strongest amdclang build
unless marked "session" (the session's own 240-pair timing).

The complete catalog is `OPTIMIZATIONS.md`; every verified result with its recipe is `RECIPES.md`.

## Decide first: which kind of kernel is this

| kind | how to tell | what 1.5x needs | examples |
|---|---|---|---|
| re-reading | a tensor is read once per head, query or pass; traffic is above the touch-once model | read it once: wave-uniform rows through scalar loads, MFMA tiles, values kept in registers | `fa_attention` 2.09, `fa_attention_causal` 1.99, `mla_decode` 1.57, `attn_decode` 1.55 |
| serialized on one resource | one workgroup does the work, the others idle; probes show two bounds of equal size | remove both bounds (cold reads, LDS atomics on shared addresses) | `vl_moe_align` 1.55 |
| touch-once, memory floor | every element read once and written once; `reference_headroom` 0.9 to 1.1 | body rewrites do not help: best 1.12 (`rb_scal`), most at parity. Non-temporal loads (`stream_loads`) give 1.2 to 1.7 under the cold-cache protocol and parity with warm caches: report both | all `rb_*` level 1, `mo_*`, `fi_*` elementwise, row norms |

On a touch-once kernel the instruction count of the body is free: hand-written bodies with 25 % to
60 % fewer instructions measured 0.99 to 1.00 on `rb_axpy`, `rb_dot`, `fi_gelu_tanh_and_mul`,
`mo_t5_layernorm`, `mo_bn_infer`. What moves the time is how many bytes are in flight per wave and
per compute unit, and nothing else.

## What transfers, and the pass or recipe for it

1. **Bytes per stream per wave: 512 B to 1 KB.** Below (256 B) loses 6 % to 16 %, above (2 KB and
   more) loses 2 % to 13 %. Measured on `fi_gelu_tanh_and_mul`, `fi_silu_and_mul`, `fi_merge_state`,
   `rb_dot`, `rb_nrm2`, `mo_prelu_bwd`, `mo_bn_infer`, `mo_active_fwd`. amdclang gets the same gain
   from a source with that geometry, so try it as a `source` state first; the machine-level part on
   top is under 1 %.
2. **Workgroups resident per compute unit: `apply(id, "throttle", {"workgroups_per_cu": n})`.**
   An LDS reservation the code does not use limits how many workgroups share a CU. Bit-identical,
   no code change. Swept over all 36 kernels at 4, 2 and 1 per CU (120 pairs): it wins only on the
   two memory-bound reductions with 8 waves per workgroup (`rb_dot` 1.021, `rb_nrm2` 1.018 at 4
   per CU); parity at 4 per CU on the other kernels with 4 or more waves per workgroup (row norms,
   attention, `rb_gemvn`, `rb_gemvt`, `kda_step`); and a loss of 1.3x to 10x on every kernel
   launched with one or two waves per workgroup, where it starves the CU. Never apply it to those.
   The default policy tries 4 per CU. Hand-tuned reservations (`relaunch` with `lds`) reached 1.02
   to 1.05 on the same two kernels; the optimum is sharp (`rb_nrm2`: 32 KB 1.02, 40 KB 0.97).
3. **Loads in flight before a wait** (`unroll_loads`, or by hand in a fast path): pays where
   amdclang waits per iteration (`fi_merge_states` 1.11, `attn_decode`), nothing on loop-free
   kernels, which already issue everything under one wait.
4. **Order within a wave**: kernarg loads at entry under one wait, vector loads issued before a
   scalar prologue or a transcendental chain, stores issued as soon as their value exists.
   1.025 on `mo_adam` (7 streams); parity with 3 streams or fewer (`mo_bn_infer`, `kda_step`).
5. **One wave per workgroup with two tiles' loads in flight** (the `rb_scal` recipe, 1.12): did not
   transfer to any second kernel (`rb_axpy` 0.97, `rb_dot` 0.98, `rb_swap`, `mo_active_fwd`).
   Treat it as specific to one read stream and one write stream.
6. **DPP reduction in place of an LDS tree or `ds_bpermute`**: pays on `rb_gemvt` (1.02) where the
   tree had barriers per level; parity or loss where amdclang's reduction is one level
   (`rb_dot`, `vl_fused_add_rms_norm` 0.98).
7. **Strided matrix reads** (`rb_gemvn`): one workgroup per CU with about 4 KB of fragments in
   flight is the optimum; half or double the workgroups loses 4 % to 54 %.
8. **LDS histogram atomics**: `ds_add_u32` from 64 lanes to shared addresses serializes. Give each
   bin 16 slots indexed by `lane & 15` and merge after the barrier: 8192 adds went from 20 us to
   4.5 us (`vl_moe_align`).
9. **Prefetch through idle workgroups**: when one workgroup does the work and the rest of the grid
   exits early, let the others issue one discarded in-bounds load each (`vl_moe_align`, 16 us of 42).
10. **A branch over memory instructions with an empty EXEC**: a store executed by waves whose mask
    is empty still costs 1.4 % (`mo_t5_layernorm`); branch over it.

## Measuring

- **Two equal bounds hide each other.** Removing one phase in a probe may show nothing because the
  other bound takes over (`vl_moe_align`: 45.5 us, 43.3 without cold loads, 42.6 without atomics,
  23.2 without both). Probe pairs of phases when single probes add up to less than the total.
- **Time depends on where the tensors were allocated** (up to 6 %, differently for each code
  object, stable for the life of the allocation). One allocation measures one placement: on
  `rb_axpy` a candidate measured 0.97 to 1.05 across allocations. `bench` and `compare` now spread
  the pairs over several allocations and take the CI over them; a result near 1.02 needs
  `pairs=240`. Single-allocation wins of the campaign (`fi_gelu_tanh_and_mul` 1.019,
  `fi_merge_state` 1.039, `rb_axpy` 1.029) were this.
- **Check which path the battery takes** before trusting a fast path: on `kda_step` all battery
  shapes run the slow loop.
- **Differential check** (`equivalent`): states built on a `-ffast-math` baseline are within
  tolerance of the original binary, not bit-identical; say which it is.
