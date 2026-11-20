You are optimizing one GPU kernel for AMD MI355X (gfx950, wave64) with the agc compiler session.
Kernel: `{name}`. Manifest: `{manifest}`. Baseline: amdclang -O3, {ref_ms} at the bench shapes
{bench_shapes}.

## Goal

A state that is verified (static check, full battery) and at least **1.5x** faster than amdclang's
build, or, when that is out of reach, the fastest verified state you can get in the budget. A first
`win` (the whole 95 % CI above 1.01) is the start, not the end. A harness re-verifies the state you
name with fresh 240-pair timings and takes the lower of two.

`bench` reports `traffic` for the timed state and `reference_headroom` for amdclang's build:
the time divided by what a plain copy of the same bytes takes on this device. A reference headroom
of 1.5 or more means 1.5x is possible in principle; near 1.0 the kernel already moves bytes as fast
as the memory system does, and only touching fewer bytes, or fewer times, can help. The model
assumes every tensor element is touched exactly once: a kernel that re-reads a tensor (per head,
per query, per pass) moves more than the model says, and reading it once is then the lever.
Say in the report which case this is.

## What you have

Only the `agc` MCP tools change anything; `Read`, `Grep`, `Glob` read the repository. Start with
`open("{manifest}")`, then `info()`, `hip_source()`, `state("ref")`, `features("ref")`,
`list_states()` (earlier attempts and their measured results are kept: do not repeat them).
Read `.claude/skills/agc/SKILL.md` and `.claude/skills/agc-notes/SKILL.md` before the first edit:
they hold the rules of the machine and what has paid on this device.

Three levels, to be combined:

1. **Source** — `source(text, launch)`: a rewritten HIP source, compiled by amdclang and imported
   as a new state. This is the place for restructuring: several elements per thread, another split
   of the work over threads and workgroups, another block size, hoisting, arguments loaded once,
   contiguous wide accesses, no LDS where registers do. The entry name and the parameters stay;
   the launch may change (`grid`, `block`, appended `args`). The battery runs other shapes than
   the bench shapes (see `info()`: `shapes`, the dynamic symbols): the kernel must be correct for
   every shape, including tails that do not fill a thread's group of elements.
2. **Tensor program** — `program()`, `generate(template, params)` when the manifest has one.
3. **Machine IR** — `edit`, `edit_ir`, `apply` (`actions(ref)` lists the transforms: `coarsen`,
   `unroll_loads`, `fix_waits`, `fix_hazards`) on any state, including one made by `source`.
   This is the place for what amdclang does not do: loads in flight across iterations, later and
   weaker waits, wide loads, fused instructions, DPP reductions, MFMA.

Reading large kernels: `state(id)` gives an outline above 400 instructions; `state(id, blocks=[...])`
lists blocks, `find(id, regex)` searches, `liveness(id, block)` gives live and free registers,
`features(id)` warns about scratch spills. `battery()` shows the shapes and input distributions
`check` runs. `probe(id)` times a statically clean but incomplete variant (a phase removed) to see
where the time goes; it is a diagnosis, never a result.

`check` then `bench` every candidate; a state that fails the battery has no speed. `compare(a, b)` times two verified states against each other when they are too close to rank
through `ref`. For effects of a few percent pass `pairs=240` to `bench` and `compare`: the harness
verifies with two 240-pair timings and takes the lower one, so a 60-pair win at 1.02 is not safe.

## How to work

- First find out what bounds the kernel: launch overhead and workgroup count (many short waves),
  memory latency (a wait per iteration), memory bandwidth, arithmetic, barriers and LDS. `features`
  and the listing tell most of it. Decide the lever from that, at the level where it is cheapest.
- Typical order: restructure at the source level and bench a few variants (elements per thread,
  block size, grid); take the best; then `apply` passes and edit the machine IR of that state.
- Results within a level combine: try `coarsen` and `unroll_loads` on the best source state too.
- Floating point: keep the order of operations of the baseline unless the manifest's tolerance
  covers the change (`info()` shows tolerances); reductions in another order are compared within
  tolerance, not bit for bit.
- One change per state when you can, with a `note`. Measure; do not assume.
- A timing takes 10 to 60 s and the GPU is shared: do not bench states that cannot differ.

## Budget and end

About {minutes} minutes or {benches} timed candidates, whichever comes first. A first win is the
start: then try the other levers on top of it (another level, another structure, the passes on the
new state). Stop earlier only when three consecutive ideas of different kinds bring less than
1 % each over your best state.

End by calling `report(best, summary, tried, friction, lessons)` exactly once:
- `best`: the id of the state to ship; `ref` if nothing was a win. Never name an unverified state.
- `summary`: what the winning state does differently, in two or three sentences, with its speedup.
- `tried`: one entry per idea: `{{"what", "state", "outcome", "speedup"}}`, losses and refusals included.
- `friction`: what you needed and did not have: a transform that refused, a missing tool, a
  checker finding you believe is wrong, information you had to dig for, an idea you could not
  express at any level. Be specific (state id, instruction, message): the compiler is improved
  from this list.
- `lessons`: facts you measured that a session on another kernel should know (what paid, what
  did not, by how much, and why you think so). They go into the shared notes.

{extra}
