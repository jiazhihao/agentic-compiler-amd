You are optimizing one GPU kernel for AMD MI355X (gfx950, wave64) with the agc compiler session.
Kernel: `{name}`. Manifest: `{manifest}`.
Baseline: {baseline}, {ref_ms} at the bench shapes {bench_shapes}.

## Goal

The baseline is the strongest amdclang build known for this kernel: where an earlier session found
a restructured source, better flags or a better launch, amdclang's build of that is the baseline.
`bench` times every state against it. What counts here is the **machine-level gain**: a verified
state (static check, full battery) that is faster than the strongest amdclang build, made with what
amdclang does not do. The target is **1.5x** over the baseline, or, when that is out of reach, the
fastest verified state you can get in the budget. A first `win` (the whole 95 % CI above 1.01) is
the start, not the end. A harness re-verifies the state you name with fresh 240-pair timings and
takes the lower of two.

A rewritten source is still worth trying, but its result is credited to amdclang, not to you: if
your `source` state beats the baseline, the harness makes it the new baseline candidate and
measures your final state against it. So restructure at the source level when the structure is the
obstacle (two or three variants, `-ffast-math` in `flags` if the baseline does not have it), then
spend the budget on the machine IR of the best amdclang build: loads in flight where amdclang waits
per iteration, scalar loads for wave-uniform rows, DPP reductions in place of LDS trees, waits
moved later and weakened, wide loads, fused instructions, exec-mask tricks, MFMA, registers in
place of scratch or LDS, fewer instructions in the hot loop.

`bench` reports `traffic` for the timed state and `reference_headroom` for the baseline: the time
divided by what a plain copy of the same bytes takes on this device. A headroom of 1.5 or more
means 1.5x is possible in principle; near 1.0 the kernel already moves bytes as fast as the memory
system does, and only touching fewer bytes, or fewer times, can help. The model assumes every
tensor element is touched exactly once: a kernel that re-reads a tensor (per head, per query, per
pass) moves more than the model says, and reading it once is then the lever. Say in the report
which case this is. At the memory floor, say so early and stop: a parity that is explained is a
result.

## What you have

Only the `agc` MCP tools change anything; `Read`, `Grep`, `Glob` read the repository. Start with
`open("{manifest}")`, then `info()`, `hip_source()`, `state("baseline")`, `features("baseline")`,
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
3. **Machine IR** — `edit`, `edit_ir`, `apply` (`actions(id)` lists the transforms: `coarsen`,
   `unroll_loads`, `fix_waits`, `fix_hazards`) on any state: `baseline`, or one made by `source`.
   This is the place for what amdclang does not do, and the level your result is measured at.

Reading large kernels: `state(id)` gives an outline above 400 instructions; `state(id, blocks=[...])`
lists blocks, `find(id, regex)` searches, `liveness(id, block)` gives live and free registers,
`features(id)` warns about scratch spills. `battery()` shows the shapes and input distributions
`check` runs. `probe(id)` times a statically clean but incomplete variant (a phase removed) to see
where the time goes; it is a diagnosis, never a result.

`check` then `bench` every candidate; a state that fails the battery has no speed. `compare(a, b)` times two verified states against each other when they are too close to rank
through the baseline. For effects of a few percent pass `pairs=240` to `bench` and `compare`: the harness
verifies with two 240-pair timings and takes the lower one, so a 60-pair win at 1.02 is not safe.

## Analysis first

The result of a session is also an ISA-level analysis that the next session and other kernels reuse.
Before the first edit:

1. `mix("baseline")` and the listing: what the hot path spends instructions on (loads by width,
   waits and which wait for everything, LDS and barriers, VALU by family). For a kernel with a loop,
   the loop block; for a loop-free kernel, the whole body.
2. Where the time goes, measured: `probe` variants with one phase removed (the arithmetic, the
   reduction, the store, the loads), and `bench`'s traffic numbers. State the split in microseconds.
3. A list of ISA-level opportunities, each with what it would remove and what it could give at most
   according to the split. Take them from the code in front of you and from the knowledge base:
   `Glob(".claude/skills/agc-notes/kb/*.md")`, read the entries of kernels of the same kind (their
   `applies_when` says when an entry transfers), and what paid there first.

Then measure every opportunity on the list as its own verified state, largest expected gain first.
Unless the target is reached, do not stop before six timed machine-level candidates of different
kinds, the launch geometry family included (bytes per lane, bytes per wave, waves per workgroup,
workgroups, `coarsen` factors, loads of the next tile in flight before the current tile is stored,
a mask-free fast path for full workgroups): on `rb_scal`, which runs at the copy model's rate, a
hand-written one-wave-per-workgroup body with two loads in flight still gained 1.12x. A parity is a
result when it is measured; "at the memory floor" from `headroom` alone is not.

`isa_diff(a, b)` gives the instruction-mix difference of two states; use it in the analysis to say
how your best state differs from amdclang's code. `equivalent(id)` runs the original binary and
yours on the same inputs and compares the outputs: run it on the state you report and say whether
it is bit-identical.

## How to work

- First find out what bounds the kernel: launch overhead and workgroup count (many short waves),
  memory latency (a wait per iteration), memory bandwidth, arithmetic, barriers and LDS. `features`
  and the listing tell most of it. Decide the lever from that, at the level where it is cheapest.
- Typical order: read the baseline's hot loop instruction by instruction and say what each wait,
  load and branch costs; `probe` phases when it is unclear where the time goes; `apply` the passes
  on the baseline; then edit its machine IR. A source variant when the structure is the obstacle.
- Results combine: try `coarsen` and `unroll_loads` on every new amdclang build too.
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
- `best`: the id of the state to ship; `baseline` if nothing was a win. Never name an unverified state.
- `summary`: what the winning state does differently from amdclang's code, in two or three sentences,
  with its speedup over the baseline (and over your own source state, if you made one).
- `tried`: one entry per idea: `{{"what", "state", "outcome", "speedup"}}`, losses and refusals included.
- `friction`: what you needed and did not have: a transform that refused, a missing tool, a
  checker finding you believe is wrong, information you had to dig for, an idea you could not
  express at any level. Be specific (state id, instruction, message): the compiler is improved
  from this list.
- `lessons`: facts you measured that a session on another kernel should know (what paid, what
  did not, by how much, and why you think so). They go into the shared notes.
- `analysis`: Markdown. The time split you measured; the ISA-level differences between amdclang's
  code and your best state (from `isa_diff`, with the instructions that matter named); a table of
  the opportunities: what, expected, measured (state id, speedup, CI), verdict; what remains
  untested and why. It is kept as the kernel's analysis and given to the next session.
- `kb`: reusable entries, one per optimization you measured (wins, parities and losses alike):
  `{{"title", "applies_when", "how", "measured", "verdict"}}`. `applies_when` names the ISA pattern
  or kernel property that makes it applicable, so that a session on another kernel can decide by
  looking at its own code; `how` is concrete enough to repeat (instructions, pass and parameters).

{extra}
