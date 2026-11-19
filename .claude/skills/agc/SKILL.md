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
   - `apply(ref, transform, params)`: a named pass from `actions(ref)`.
4. `static_check(id)`: must pass before any GPU job. Findings say what is needed, for example
   "needs `s_waitcnt vmcnt(1)` first" or "insert `s_nop 0`".
5. `check(id)`: the battery (hidden seeds, shape variants). A state that fails is never timed.
6. `bench(id)`: paired against `ref`. `win` needs the whole 95 % CI above 1.01; anything inside
   ±1 % is `parity`. Report `parity` and `loss` as such; never report a fallback as a win.
7. `note(id, text)` what was tried and what happened; `tag` / `fork` / `checkpoint` to organize.

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
  (0..64, -1..-16, ±0.5, ±1.0, ±2.0, ±4.0) anywhere but no literal.

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
