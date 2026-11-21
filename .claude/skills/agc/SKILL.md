---
name: agc
description: Optimize a kernel for AMD MI355X (gfx950) with the agc compiler session - import amdclang's assembly, edit the machine IR, static-check, verify on the GPU, and measure against amdclang. Use when asked to speed up, inspect or verify a kernel in this repository.
---

# Optimizing a kernel with agc

The session is reached through the `agc` MCP server (`.mcp.json`), or from a shell with
`scripts/agc_mcp.py MANIFEST TOOL ['{json args}'] ...` (same tools; states persist in `.agc/`).

## The loop

1. `open(manifest_path)`: amdclang's `-O3` build is imported as state `ref`.
2. `state("ref")`: the kernel as a numbered listing (`label:` lines, `[index] instruction`).
   `features("ref")`: registers, occupancy and its limiter, loops, waits, loads/stores.
3. Make a new state:
   - `edit(parent, ops)`: `{"op": "replace"|"insert"|"delete", "block", "index", "text", "expect"}`.
     Always pass `expect` (the instruction now at that address). Addresses refer to the parent.
   - `edit_ir(parent, ir)`: the whole body (a numbered listing is accepted).
   - Unrolled code is written once: `%rep i 16` ... `%end` in edit text repeats its lines with
     `{20 + 4*i}` evaluated per copy (`%rep i 4 12`: 4..11; a third number is the step; blocks nest).
     A whole block is `{"op": "replace", "block": L, "index": 0, "count": "end", "text": ...}`.
   - `liveness(id, block)` lists the registers that are dead across a block (temporaries for an
     edit inside it) under the classical rule; read its condition for vector registers.
   - `apply(ref, transform, params)`: a named pass from `actions(ref)`.
4. `static_check(id)`: must pass before any GPU job. Findings say what is needed, for example
   "needs `s_waitcnt vmcnt(1)` first" or "insert `s_nop 0`".
5. `check(id)`: the battery (hidden seeds, shape variants). A state that fails is never timed.
6. `bench(id)`: paired against `ref` (`compare(a, b)` ranks two candidates directly; `traffic` in
   the result says how close the kernel is to the memory rates measured on this device). `win` needs the whole 95 % CI above 1.01; anything inside
   ±1 % is `parity`. Report `parity` and `loss` as such; never report a fallback as a win.
7. `note(id, text)` what was tried and what happened; `tag` / `fork` / `checkpoint` to organize.

## agc's own lowering (`lower`)

`lower(overrides)` compiles the manifest's HIP source without amdclang's optimizer or code generator
(Clang only parses): source → `kir` (one thread's program) → `wir` (one wave's schedule: uniform and
per-lane values, `where` / `branch` regions, loads with base, index and offset) → assembly. The
result is a new root state; check and time it like any other.

- Every lowering step is a recorded decision whose default does what amdclang does. `plan(id)` lists
  them: site (`kernel`, `if0`, `load1`, ...), chosen alternative, the others, what the decision means.
- `replan(id, {"site.decision": alternative})` lowers again with those decisions changed and the rest
  kept: this is how to try an alternative and how to go back. `{"decision": alternative}` applies to
  every site that takes the decision.
- `ir(id, "kir" | "wir")` shows the program above the assembly; `explain(id, site)` one site.
- Decisions so far: `fp.contract` (fma or separate multiply and add), `access.width` (merge accesses
  of consecutive elements into `dwordx2/x4`, scalar loads up to `s_load_dwordx16`), `load.uniform`
  (a load at a uniform address as one scalar load), `loop.unroll` (1, 2, 4, 8, 16 iterations per
  trip, remainder loop kept, bit-identical), `loop.inflight` (`first`: all loads of a trip before any
  arithmetic, so one wait covers them), `branch.skip_empty`. More arrive with each roadmap milestone
  (`docs/roadmap.md`, phase 2).
- The loop pair is the first thing to try on a kernel whose loop waits for every load:
  `replan(id, {"loop.unroll": 16, "loop.inflight": "first"})` gave `matvec` 2.78x and `gemm_naive`
  2.15x over amdclang, bit-identical. A decision that does not exist in the kernel is refused with
  the list of those that do.
- A kernel outside the supported subset is refused with kind `frontend` (every unsupported construct
  with its source location) or `unsupported` (a lowering not built yet). `ref`, amdclang's build,
  stays available: `tests/baselines/own-gfx950.json` says how far each kernel gets.

## The source level

`source(text, launch)` compiles a rewritten HIP source with amdclang and imports it as a new root
state; `hip_source()` gives the baseline's text. Use it to restructure (elements per thread, the
split over threads and workgroups, block size, a loop-free body), then work on the result at the
machine level. Rules: the entry name and the manifest's parameters stay, in order; extra
parameters are appended and supplied by `launch["args"]` (`{"dtype": "u32", "value": "cdiv(N, 4)"}`);
`grid` and `block` may have up to three dimensions and are expressions over the shape symbols.
`relaunch(ref, launch)` changes only the launch. `__builtin_amdgcn_rcpf`, `__builtin_exp2f` and
friends lower to the single instructions (`v_rcp_f32`, `v_exp_f32` plus range handling) when the
tolerance allows replacing a libm call or a division.

Wave reduction without LDS (one wave per row; `agc/gen/rowwise.py` `wave_reduce` is the reference):
four DPP steps fold the 16 lanes of each row, then the four row results are read with
`v_readlane_b32` at lanes 0, 16, 32, 48 and combined:

```
v_add_f32_dpp v1, v0, v0 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
v_add_f32_dpp v2, v1, v1 quad_perm:[2,3,0,1] row_mask:0xf bank_mask:0xf
v_add_f32_dpp v3, v2, v2 row_half_mirror row_mask:0xf bank_mask:0xf
v_add_f32_dpp v4, v3, v3 row_mirror row_mask:0xf bank_mask:0xf
```

A DPP instruction that reads a VGPR written by the instruction just before it needs 2 wait states
(`dpp_reads_vgpr_after_write`), and `v_readlane` needs 1: `apply(id, "fix_hazards")` inserts
`s_nop 1` between the steps above. Interleave two independent chains (or other work) instead and
no nop is needed; that was worth 4 % on `attn_decode`. `row_bcast:15` / `row_bcast:31` and
`v_cmpx_*` (the compare writes EXEC) are accepted.

A 64-bit unsigned scalar compare is `s_sub_u32` / `s_subb_u32` and a branch on the borrow in SCC.

## Tensor programs

When the manifest has a `program` (tair), `program()` shows it with the templates that can
compile it and their parameters, and `generate(template, params)` compiles it straight into
machine IR: a new state with its own launch geometry, no HIP involved. Sweep the parameters
(`elements_per_lane`, `unroll`), `check` and `bench` each, keep the best. Generated states can
be edited like any other; `apply(id, "fix_waits")` and `apply(id, "fix_hazards")` repair waits
and wait states after an edit. Generated kernels meet the manifest's tolerance, not
bit-identity with amdclang: say so when reporting.

## Rules of the machine (checked for you, but know them)

- One wavefront = 64 lanes. `v*` are per-lane 32-bit registers, `s*` are scalars, `a*` are
  AccVGPRs (MFMA accumulators), `exec` masks lanes, `vcc` holds a per-lane comparison.
- At entry: `s[0:1]` = kernarg pointer, then the enabled workgroup ids (`s2`, ...), `v0..v2` =
  workitem ids. Arguments are read with `s_load_dword*` from `s[0:1]` at the metadata offsets.
- Memory results arrive asynchronously. `s_waitcnt vmcnt(n)` waits until at most `n` vector
  memory operations are outstanding (in order: the oldest completes first, stores count);
  `lgkmcnt(n)` covers LDS (in order) and scalar loads (out of order: use `lgkmcnt(0)`).
  A wait can be *later* (just before the first use) or *weaker* (`vmcnt(1)` when only the older
  load is needed); both are legal and are where latency hides.
- Hazards need wait states (any instruction is one; `s_nop N` is N + 1): a VALU reading an SGPR
  or VCC written by a VALU needs 2; a VALU reading a transcendental's result (`v_exp`, `v_rcp`,
  `v_sqrt`, ...) needs 1; a memory instruction using an SGPR written by a VALU needs 5; MFMA
  results need 4 to 20 depending on passes (see `arch("mfma")`). `arch("hazards")` lists all.
- `isa(mnemonic)` gives operands and encodings from AMD's specification. `_e32` forms take one
  literal or scalar in SRC0 only; `_e64` (VOP3) forms take scalars and inline constants
  (0..64, -1..-16, ±0.5, ±1.0, ±2.0, ±4.0) anywhere but no literal. Constant bus: one VALU
  instruction may name at most one distinct SGPR or literal among its sources, the mask pair of a
  `v_cndmask_b32_e64` included (`v_max3_f32 v3, v76, s4, s5` is refused by the assembler): move
  the second scalar into a VGPR first.

## What tends to pay (measure; do not assume)

- Issue loads as early as their addresses are known and wait as late as possible; independent
  work between a load and its wait is free.
- Wider loads (`global_load_dwordx2/x4`) when one lane reads consecutive elements.
- Fewer instructions in a loop body: fused forms (`v_fmac`, `v_lshl_add_u64`, `v_mad_u64_u32`),
  scalar work hoisted out of the loop, compare-and-branch on a decremented counter.
- Occupancy only matters when `features` says the limiter is `vgpr`, `sgpr` or `lds`.
- Memory-bound kernels (elementwise over large arrays) are at the bandwidth limit already:
  expect parity. Record it and move on.

## Reporting

State the state id, the edit, the battery verdict and the paired result with its CI, for wins,
parities and losses alike. `trace(id)` is the replayable record.
