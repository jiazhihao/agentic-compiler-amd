# Roadmap

Tracked in GitHub issue #1, one sub-issue per milestone; phase 2 in #77. Revised 2026-11-21
(see "What changed" at the end). Measured results go to [progress](progress.md).

Phase 1 (M0 to M10, done) built the harness around `amdclang`: its assembly is imported and
improved. Phase 2 (M11 to M21) gives agc its own lowering from HIP to CDNA4 assembly, as a set of
transformations and lowering rules whose alternatives an agent chooses among and backtracks over.

## What agc is

agc is a compiler and an agent harness designed together: a collection of IR transformations
and lowering rules, from HIP or a tensor program down to CDNA4 assembly, that an agent applies,
measures and backtracks over on one kernel at a time. It is not a fixed pipeline meant to beat
`amdclang` on its own. For each benchmark kernel an agent session
specializes and customizes the optimization: it picks and parameterizes passes,
generates the kernel from its tensor program with a schedule fitted to its shapes,
changes the launch, or edits the assembly directly, and agc checks and measures every
step. The deliverable per kernel is a verified binary with its replayable trace. The
default policy (`agc optimize`) is the unattended floor and the regression baseline; it
automates what sessions have shown to pay repeatedly.

## Principles

1. **Vertical slices.** Every milestone ends with something that runs on the GPU and a
   number recorded in `progress.md`. No milestone is infrastructure only.
2. **The agent loop comes early.** Importing amdclang's assembly, editing it, checking
   it and timing it against the original is the core of the project, so it is working
   by M5, before any automatic pass exists. Passes are written afterwards, to automate
   what the loop has shown to pay.
3. **Spend effort where the speedup is.** amdclang's lane-level code is already good;
   reordering it is expected to give parity to small wins. The large wins are
   structural (MFMA, LDS tiling, several elements per lane, launch geometry) and come
   from generators, so generators are scheduled before backend automation.
4. **Build on demand.** A component with no measured consumer is not built: the
   interpreter, full machine-model calibration, re-allocation of imported code,
   recipe promotion and the profiler are stretch items, each with a stated trigger.
5. **Honest numbers.** A speedup needs a passing battery and a paired timing whose
   confidence interval excludes 1.0. Every bench run includes an A/A control.
6. **Per-kernel sessions are the unit of work.** A benchmark is worked kernel by kernel
   in agent sessions; a transformation does not have to be general to be used, only
   verified. What recurs across sessions is promoted to a pass, a template or a note,
   and the report states for every kernel whether the result came from the policy or
   from a session.

7. **Lowering is a space, not a pipeline** (phase 2). Every lowering step is a recorded decision
   with alternatives; the default alternative reproduces amdclang, and a departure is named,
   replayable and measured.
8. **A rule is admitted with its analyses** (phase 2): effects, verifier coverage, a cost-model
   term, a note on the hardware behaviour, and a pass over the whole corpus.

## Development host (observed 2026-11-19)

| Item | Value | Source |
|---|---|---|
| GPUs | 8 × AMD Instinct MI355X VF (SR-IOV), `gfx950`, xnack-, sramecc+ | `rocminfo`, `rocm-smi` |
| CUs / wave size | 256 / 64 | `rocminfo` |
| LDS per workgroup | 160 KB | `rocminfo` |
| ROCm | 7.14 (HIP 7.14.60850, AMD clang 23.0.0git), code object v6 | `hipcc --version` |
| Tools | `amdclang`, `llvm-mc`, `ld.lld`, `llvm-objdump`, `llvm-readelf`, `hipify-clang`, `rocprofv3`, `amd-smi` | `/opt/rocm` |
| Libraries | hipBLASLt, MIOpen | `/opt/rocm/lib` |
| ISA spec | `amdgpu_isa_cdna4.xml` (AMD machine-readable ISA, MIT, 2026-02-20) | gpuopen.com |

Constraints that shape the plan: the GPUs are SR-IOV virtual functions, so clocks
cannot be locked (timing is paired and interleaved instead, and the clock state is
recorded); there are 8 devices, so the executor locks per device and tests and
benchmarks can run on several at once.

## Phase 1 milestones (done)

Order is the order of work. Each milestone is one issue and one PR (stacked when the
one below is unmerged).

### M0 — Bootstrap (#2)
- [x] Repo skeleton, design, roadmap, workflow skill, CI (CPU tests), Python env.

### M1 — Measure: runtime, battery, timing (#3)
- [x] `agc/arch/gfx950.yaml` (resources with source tags), loader, occupancy calculator.
- [x] `agc/runtime/hip.py` (HIP module API through ctypes), `toolchain.py` (amdclang
      `.hsaco` and `-S`, assemble, link, inspect; toolchain identity in cache keys).
- [x] `agc/manifest.py`, `agc/dtypes.py`.
- [x] Executor: per-device lock, subprocess workers, accounting.
- [x] Battery: seeded input distributions, hidden seeds, shape variants, NumPy
      reference, output poisoning, rtol/atol/cond tolerances.
- [x] Timing `agc-timing-amd-1`: `hipEvent`s, cache flush, CI-converged medians; paired
      interleaved comparison of two code objects in one process.
- [x] CLI `agc build | check | bench`.

Exit: AXPY builds, passes the battery and is timed; an A/A paired run (the same code
object twice) gives a ratio whose CI contains 1.0 and is within ±2 %.

### M2 — Corpus and amdclang baselines (#4)
- [x] About 12 HIP kernels with manifests and references, chosen to cover the code
      shapes that matter: elementwise (axpy, gelu, bf16 cast), rowwise reductions (sum,
      max/argmax), softmax, rmsnorm, layernorm, transpose, matvec, GEMM naive, GEMM
      tiled through LDS.
- [x] `tests/baselines/amdclang-gfx950.json`: time, registers, LDS, occupancy per kernel.

Exit: every corpus kernel passes the battery and has a baseline; `make test` covers it.

### M3 — Own the assembly: ISA table and `mir` (#5)
- [x] `scripts/gen_isa.py`: CDNA4 XML → `agc/isa/cdna4.json.gz`; query API.
- [x] `agc/mir`: IR, parser and printer for the amdclang dialect, kernel descriptor and
      metadata as data, emit (`.s` → `llvm-mc` → `ld.lld` → `.hsaco`).
- [x] Import of amdclang `-S` output; re-emit is byte-identical in `.text` for the corpus.
- [x] Verifier: every instruction and operand checked against the ISA table.
- [x] One kernel written by hand in `mir` (no amdclang) runs and passes the battery.

Exit: the whole corpus imports, verifies, re-emits identically and passes the battery;
the hand-written kernel passes.

### M4 — Static safety (#6)
- [x] CFG, register def/use from the ISA table, liveness.
- [x] Waitcnt checker (vmcnt / lgkmcnt / expcnt counter dataflow).
- [x] Hazard checker; the wait-state table lives in `gfx950.yaml`.
- [x] Register counts and `accum_offset` recomputed and checked against the descriptor.

Exit: zero violations on every amdclang output in the corpus; a seeded mutation suite
(dropped or weakened waits, removed or shortened `s_nop`, wrong register class or width,
understated register counts, a read of a register nothing writes) is caught at ≥ 95 %,
with the misses listed. (A clobbered live register is a semantic change, not a static
property: it is the battery's job and was removed from this list.)

### M5 — The agent loop on assembly (#9)
- [x] Content-addressed store of immutable states; trace of actions.
- [x] Session actions: `import`, `edit_ir`, `static_check`, `check`, `bench` (paired
      against the amdclang build), `asm_diff`, `state`, `branch`; rejections as JSON.
- [x] MCP server and the `agc` skill; CLI `agc run`.
- [x] A GPU job is refused for a state that has not passed `static_check`.

Exit: an agent session through MCP takes three corpus kernels from import to a paired
result. The outcome (win, parity or loss, with the edit that caused it) is recorded
for each; these observations decide the pass list of M8.

### M6 — Tensor programs in, binaries out (#10)
- [x] `tair`: a small specification (maps, rowwise reductions, einsum contractions),
      text format, NumPy interpreter; manifests whose reference is the program.
- [x] `mir` builder with virtual registers; for generated code: linear-scan register
      allocation, waitcnt insertion, hazard insertion (each checked by M4's checkers).
- [x] Generators: elementwise (several elements per lane, wide loads), rowwise
      reduction, softmax, rmsnorm/layernorm.
- [x] Session action `generate`; generator parameters are agent-visible knobs.

Exit: the tensor-program versions of the corpus kernels compile with no kernel
source, pass the battery, and are paired against the amdclang build of the HIP
version. Expectation: about parity on memory-bound elementwise kernels, wins on the
reductions and normalizations; the measured geomean is reported either way.

### M7 — GEMM on MFMA (#11)
- [x] MFMA operand and accumulator layouts in arch data; the microbenchmarks this
      needs (MFMA issue rate, LDS read bandwidth, global load latency), written in `mir`.
- [x] bf16 / f16 GEMM generator: LDS tiles, MFMA inner loop, AGPR accumulators.
- [x] Tuning knobs as agent actions: tile sizes, unroll, load/MFMA interleave,
      direct-to-LDS loads, workgroup shape.
- [x] Baselines: amdclang's build of the HIP bf16 GEMM; hipBLASLt.

Not done here: direct-to-LDS loads and LDS-shared operands (follow-up #23); f16.

Exit: verified bf16 GEMM at three shapes (square 4096, wide, tall), faster than the
amdclang tiled HIP build by a CI-separated margin; time relative to hipBLASLt reported
with an analysis of the gap. Target: within 1.5× of hipBLASLt on at least one shape.

### M8 — Backend passes for imported code (#8)
The pass list comes from the M5 sessions (see progress): amdclang waits for every load in a
loop, so the measured wins were all "more loads in flight per wait".
- [x] Loop analysis: single-block counted loops, induction registers, contiguous and strided
      load streams.
- [x] `unroll_loads`: unroll such a loop by N with wide (`dwordx4`) or offset loads issued
      before one wait, the arithmetic kept in the original order (bit-identical); remainder
      loop kept. Parameters: factor, wide loads on/off.
- [ ] `bulk_unmasked`: for a masked per-lane loop, a prefix loop for the iterations in which
      every lane is active. (Not built: the rowwise generator already beats amdclang on every
      kernel with such a loop; the hand edit is kept as `tests/mir/wins/row_sum_bulk4.s`.)
- [x] Waitcnt re-derivation (`fix_waits`: waits at the first real use, as weak as legal).
      Merging argument loads at entry was measured as parity on AXPY and not built.
- [x] Default policy: import → pass pipelines → static check → battery → paired bench →
      keep the fastest verified state, else the amdclang build (reported as a fallback).

Exit: the default policy is never slower than amdclang on the corpus (CI), and every
win is reported with its pass.

### M9 — Campaigns and report (#13)
- [x] Agent sessions on the corpus with traces kept (`tests/mir/wins/`); GEMM is covered by the
      generator's parameter sweep.
- [x] Knowledge notes from the sessions, as the `agc-notes` skill.
- [x] Final report: per-kernel paired speedup against amdclang and, for GEMM, hipBLASLt;
      A/A controls; what did not work.

### M10 — Per-kernel agent sessions on the LLM-kernel benchmark (#29)
- [x] Benchmark of LLM kernels (FlashInfer, vLLM, attention, MLA, KDA, MoE, rocBLAS, MIOpen)
      with amdclang baselines: `bench/llm`, 36 kernels.
- [x] The default policy on every kernel (the floor): 10 wins, 26 fallbacks.
- [x] The harness (`agc.agent`, #34): headless agent session per kernel, independent
      verification, recipes, replay; source level, launch changes, traffic and headroom.
- [x] An agent session per fallback kernel (#35 to #60), first round: against `-O3` on the
      shipped source. The audit showed these wins to be amdclang's own on a rewritten source.
- [x] Stronger baseline (#62): the strongest amdclang build per kernel (restructured source,
      `-ffast-math`, own launch); sessions, policy and report measure against it.
- [x] Second round of sessions against the stronger baseline: machine-level gain. 4 kernels
      at or above 1.5x, 11 more with a gain, 21 without (memory floor or parity, explained).
- [x] ISA-level campaign over the 21 kernels without a gain (#64): differential check against
      the original binary in the verification, per-kernel analyses (`docs/kernels/`), knowledge
      base (`.claude/skills/agc-notes/kb/`), 44 sessions. `vl_moe_align` 1.55x; four more with
      about 1.02x; 16 measured at the memory floor (touch-once), without a gain.
- [x] Customizations promoted to passes: `coarsen` (#30), `throttle` (#64), `stream_loads` (#67); to a
      template: `attention_mfma` (#71). Further ones as sessions find them.
- [x] Placement-aware paired timing (#66); knowledge base with catalog, recipes and search (#67);
      fusion of two tensor programs into one kernel (#73).
- **Exit:** per-kernel table (policy and session results against amdclang, fallbacks
  reported as fallbacks) in the report and on #29.

## Phase 2: agc owns the lowering from HIP to assembly (#77)

### Summary

Phase 1 (M0 to M10) made agc a harness around `amdclang`: HIP is compiled by `amdclang -O3 -S`,
the assembly is imported into `mir`, and passes and agent edits improve it. Phase 2 removes
`amdclang`'s optimizer and code generator from the product path. agc gets its own lowering from
HIP to CDNA4 assembly, built as a **collection of IR transformations and lowering rules with
alternatives**. Every lowering step is a recorded decision; an agent (or the unattended policy)
can choose another alternative at any decision, measure it, and backtrack. The compiler and the
agent harness are designed together, in the sense of
[CAKE](https://arxiv.org/abs/2608.12629) (Ye, Huang et al., 2026), with one difference that shapes
everything below: CAKE lowers to PTX and leaves the machine code to the NVIDIA toolchain, while agc
lowers to the final CDNA4 assembly, so the decisions an agent can take reach down to registers,
instruction order and waits.

`amdclang` keeps four roles, none of them in the product path: the **parser** (Clang's semantic
analysis, `-fsyntax-only`, no LLVM IR, no optimizer, no backend), the **baseline** to beat, the
**differential oracle** (`equivalent`, fuzzing), and the **reference implementation** whose
source (LLVM's AMDGPU backend) the first version of each lowering is written from.

### Why: what phase 1 measured

| Observation (36 LLM kernels unless noted) | Consequence for phase 2 |
|---|---|
| Source restructuring compiled by amdclang: geomean 1.54 over `-O3` on the shipped source, up to 20x. The agent had to express it as rewritten HIP text and could not see or steer what amdclang did with it. | Work mapping (elements per lane, bytes per wave, lanes across a row, waves per workgroup) becomes lowering decisions on an IR agc owns. |
| `-ffast-math` alone: up to 1.98x (`fi_rope`), all or nothing per translation unit. | Floating-point freedoms become per-site decisions admitted by the manifest's tolerance. |
| Passes on imported assembly: 8 wins of 1.02 to 1.06. Each pass first has to recover structure from assembly (`unroll_loads` refuses masked multi-block loops, loops unrolled by 2, kernels with indexed registers; `coarsen` refuses workitem-dependent exits). | The same transformations are simple and total on a structured IR above the assembly. |
| All five results at or above 1.5x (`fa_attention` 2.10, `fa_attention_causal` 1.98, `mla_decode` 1.56, `attn_decode` 1.55, `vl_moe_align` 1.55) are whole-kernel rewrites typed as raw `mir`: up to 500 hand-expanded lines, register renames by hand, 99 friction items, most of them mechanical. | The agent needs a level where it states the schedule (who loads what, how many loads in flight, which MFMA form, which LDS region, which wave does what) and lowering derives registers, waits, nops, addresses and the descriptor. |
| Promotion recovers most of a hand win: `unroll_loads` 2.74 against 2.70 by hand on `matvec`; template `attention_mfma` 1.96 against 2.10 by hand. | Hand wins are re-expressed in the new IR and become rules; the gate is at least 0.97 of the hand-written time. |
| Prose knowledge transfers poorly: the `rb_scal` recipe (1.12) lost on every second kernel (0.97, 0.98). | A knowledge-base entry becomes a rule whose `applies_when` is code (a precondition that refuses with a reason). |

### What is taken from CAKE, and where agc differs

Read in full: sections 1 to 8, appendices A to F.

| CAKE | agc phase 2 |
|---|---|
| Agents author a typed, hardware-explicit schedule IR instead of raw CUDA/PTX; a tile DSL hides too much, a low-level DSL makes errors likely and hard to localize. | `wir`, a typed wave-level schedule IR between the thread-level program and the assembly. It is the default editing level; raw `mir` becomes the escape hatch. |
| "A schedule states what is to happen and lowering derives how": barrier addresses, phase bits, offsets, descriptors are derived, not authored. | Authored in `wir`: wave roles, LDS regions, barriers, load streams and their depth, access widths and cache hints, MFMA forms and accumulators, reductions across lanes, masks. Derived: register numbers and classes, `s_waitcnt`, `s_nop`, address arithmetic, kernarg offsets, the kernel descriptor and metadata. |
| Layout is not a first-class algebra: the agent writes concrete commitments, the compiler checks producer/consumer consistency. | MFMA operand and result layouts stay concrete (lane `l` reads element ...); the verifier checks them against the measured layouts in `gfx950.yaml`. No layout calculus. |
| Harness contract: pre-compile gates in four categories (program safety, hardware conformance, data consistency, schedule semantics) with a localized finding; an execution gate; a performance report; non-blocking hints. Missing analysis coverage is reported, not treated as a pass. | The existing `mir` static check, battery and paired timing stay. New: the same four gate categories on `kir` and `wir` with site-addressed findings; `actions` as the hint channel; a cost report with bottleneck attribution. |
| A calibrated cost model ranks and filters candidates before GPU time and declines to predict outside its calibration. | `agc/cost`, calibrated from the timed states already in the stores; used by `actions`, `sweep` and the policy. |
| The harness is itself evolved: a runtime crash becomes a verifier rule, a repeated illegal lowering a static check, a systematic misprediction a calibration target; changes are test-gated across the kernel corpus; a primitive and its analyses evolve together; humans gate merges. | `report(friction)` is routed (candidate, verifier, cost model, vocabulary or rule, tool); a rule is admitted only with its effects, checks, cost term and corpus gate (`make gate`); PRs stay human-merged. |
| The IR was grown bottom-up from production kernels and must reproduce their physical schedules and performance. | `wir`'s vocabulary grows by porting: amdclang's outputs on the corpus, the five hand-written recipes, the four generator templates. Nothing enters the IR without a kernel that needs it. |
| Evaluation with matched arms (typed IR against direct CUDA/PTX, same model, scaffold, oracle and token budget, three runs). | M20 runs the same protocol: lowering decisions and `wir` against raw `mir` edits. |
| A tuned shape is not a library: generalization and dispatch are a separate stage with a declared shape domain and held-out shapes. | Kept separate here too (stretch, with the same rules). The battery's shape variants stay mandatory for every state. |

**The key difference: CAKE targets PTX, agc targets the machine's assembly.** CAKE lowers its
schedule IR to CUDA/PTX and hands it to the NVIDIA toolchain, so `ptxas` still chooses the
instructions' order, the registers and the final encoding, and CAKE's analyses and cost model
reason about a program one opaque step away from what runs. agc emits CDNA4 instructions itself;
`llvm-mc` only encodes and `ld.lld` only links. Consequences for the design:

| Consequence | In the roadmap |
|---|---|
| The decision space goes all the way down: instruction selection and operand forms, scheduling within a block, register allocation and occupancy, `s_waitcnt` placement, hazard handling, kernarg loading. None of these is reachable from PTX. | The `mir`-level rows of the decision catalog; `regalloc.target`, `hazard.policy`, `wait.policy`, `kernarg.load` |
| Nothing below agc repairs a weak lowering: there is no vendor optimizer or scheduler behind it. | Parity with amdclang is its own milestone (M16), driven by an instruction-level diff against amdclang's output |
| What the checkers and the cost model see is exactly what ships, instruction for instruction. | Legality is decided statically on the final program (the M4 checkers); the cost model has instruction-level terms; `attribute` maps time to sites through to instructions |
| agc owns machine-level correctness (a missing wait or wait state is a silent wrong result, which `ptxas` would never let a PTX author produce). | Derived by lowering, never authored: waits, nops, register classes and alignment; independent checkers on every state; a `mir` interpreter validated against the device (M13) |
| The escape hatch is the assembly itself, not generated source. | `edit` / `edit_ir` on `mir` stay; a result that needed them names the missing rule |
| The machine model is agc's to build, as data. | `gfx950.yaml` and the selection table (`gfx950.isel.yaml`), every field tagged with its source; LLVM's AMDGPU backend is the reference for the first version |

Other differences:

- **The input program exists.** CAKE's agent writes the schedule; agc's default lowering derives a
  correct one from HIP, so every session starts from a verified parity point and changes decisions.
- **Backtracking is a first-class operation** over recorded decisions (below), not only a property
  of the agent's own search.
- **A bit-identical default.** The default plan keeps amdclang's floating-point order, which gives
  an exact differential oracle while the lowering is built.

### Decisions (continue D1 to D11 of `docs/design.md`)

| # | Decision | Rationale |
|---|---|---|
| D3' | **HIP enters through agc's own lowering**: Clang AST → `kir` → `wir` → `mir`. Importing `amdclang -S` output stays as an input kind (existing assembly, baselines), not as the HIP path. Replaces D3. | The measurements above. |
| D9' | **`kir` and the Clang-AST frontend are built now** (D9 deferred them until a measured case needed a lane-level transformation: 22 of 23 first-round recipes were such cases). | |
| D12 | **Clang is the parser, and only the parser**: `amdclang++ -x hip --cuda-device-only -fsyntax-only -Xclang -ast-dump=json`. Measured on `axpy.hip`: 0.6 s, 150 KB. Templates, overloads and constant expressions arrive resolved. No LLVM IR is consumed. | Parsing C++ is not where the performance is. Rejected: `-O0 -emit-llvm` as input (loses loops and array structure, ties agc to LLVM IR, brings the ABI's alloca code); an own parser (stretch, with a trigger). |
| D13 | **Three IRs with one contract each**: `kir` says what one thread computes (the semantics of the HIP source); `wir` says how a wave is driven (the schedule); `mir` is the shipped program. Each has text, a parser, a verifier and a NumPy interpreter. | An interpreter per level makes every lowering step checkable on the CPU (CI has no GPU). `wir` is the level the five big wins were missing. |
| D14 | **Lowering is a set of rules with alternatives, and a compilation is a plan**: an ordered record of decisions `(site, decision, alternative, parameters)`. The default alternative of every decision reproduces what amdclang does. | Parity by default; every departure is named, replayable and attributable. |
| D15 | **Backtracking is replanning**: change one decision and agc re-derives the program from the earliest affected level, replaying the other decisions. States stay immutable and content-addressed; the store is the search tree. | The agent should not redo by hand what did not change. |
| D16 | **Rules are admitted, not just written**: a rule ships with its effects (what it reads, writes, requires), verifier coverage, a hardware-behaviour note, a cost-model term and a pass over the whole corpus. | CAKE's P4 to P8. A primitive without analyses makes the IR less analyzable. |
| D17 | **The manifest is specialization context for the compiler**: tensors declared distinct give alias information, shape ranges give value ranges, the tolerance admits floating-point alternatives. | amdclang cannot know any of this from the source. |
| D18 | **The first implementation of each lowering is written from LLVM's AMDGPU backend** (the reference map below), then diverges where measurements say so. Ported logic names its source file. | The legality knowledge is there (control-flow lowering, i1 handling, division expansion, operand folding). |

### The IR stack

```text
 HIP + manifest ──Clang (parse, -fsyntax-only)──► AST (JSON)
                                                    │ frontend: bounded subset, inlining
                                                    ▼
                kir   one thread's program: SSA, structured control flow, typed memory,
                 │    HIP builtins. kir → kir: simplify, loops, work mapping, idioms, fusion
                 │
                 │ wave lowering: uniformity, masks, reductions, access forms   ◄─ decisions
                 ▼
 tair ─templates► wir   one wave's schedule: uniform / varying / mask values, declared
                 │      resources (LDS regions, barriers, wave roles, load streams),
                 │      MFMA forms. wir → wir: pipelining, unrolling, widening   ◄─ decisions
                 │
                 │ selection, scheduling, register allocation, waits, hazards   ◄─ decisions
                 ▼
                mir (virtual → physical) ──► static check ──► llvm-mc, ld.lld ──► .hsaco
                                                                │
 amdclang -O3 -S ──import──► mir   (baseline, oracle, existing assembly)   battery, paired timing
```

**`kir`** (thread level). Ported from the reference implementation (`~/agentic-compiler/agc/kir`:
IR, text, verifier, interpreter, passes; the PTX-specific operations dropped). Types `i1`, `i8` to
`i64`, `u8` to `u64`, `f16`, `bf16`, `f32`, `f64`, pointers with an address space (global, LDS,
private). SSA scalars, structured `if` / `for` / `while`, `load` / `store` / `atomic`, builtins
(`threadIdx`, `blockIdx`, `blockDim`, `gridDim`, `barrier`, lane shuffles), math calls. Interpreter:
all threads of a launch, vectorized in NumPy, with barrier phases.

**`wir`** (wave level; new). One wave's program, structured.

- Values: `u` (wave-uniform, will live in an SGPR), `v` (per lane, VGPR), `m` (lane mask), `acc`
  (MFMA accumulator, AccVGPR), tuples.
- Declared once: the launch (grid, block), wave roles within a workgroup, LDS regions (shape,
  dtype, owner), barriers, load and store streams (base, stride, width, depth in flight, hint).
- Operations, close to instruction families so that cost stays visible: arithmetic and compares per
  class, `select`, `load` / `store` on a stream or an explicit `(base u, offset v, width)`,
  `lds.get` / `lds.put` / `lds.atomic`, `barrier`, `lane.reduce` / `lane.shuffle` (with the
  mechanism named: DPP, `v_readlane`, `ds_bpermute`), `mfma(form, a, b, acc)`, `where mask:`
  regions, uniform loops with their unroll.
- Not written, derived by lowering: register numbers, `s_waitcnt`, `s_nop`, address arithmetic and
  immediate folding, kernarg offsets, hidden arguments, descriptor and metadata, LDS offsets.
- Interpreter: 64 lanes per wave, the waves of a workgroup in barrier phases.

**`mir`** stays as it is (virtual and physical, static checks). It gains an interpreter for the
instructions agc's selector can emit, validated instruction by instruction against the device.

### The lowering space

A **site** is a stable name for a program element (a loop, a load group, a reduction, a branch, a
math call, a private array, the kernel). Sites carry their source location and survive
transformations, so a decision, a checker finding, a cost-model term and a probe all address the
same thing.

Session operations added (the existing ones stay):

| Operation | What it does |
|---|---|
| `lower(id, overrides)` | Runs the remaining lowering to physical `mir`; returns the plan with every decision taken |
| `actions(id)` | The open and taken decisions: per site the alternatives, whether each applies (or the refusal reason) and the cost model's estimate |
| `apply(id, rule, site, params)` | One transformation at the state's level |
| `replan(id, {site.decision: alternative})` | Backtrack: re-derive from the earliest affected level, replay the rest; reports decisions that no longer apply |
| `sweep(id, decisions, budget)` | The harness runs a set of alternatives: cost-model ranking, static gates, battery, a 20-pair screen, 240 pairs for the survivors |
| `attribute(id)` | Time per site from automated probes (single and paired, since two equal bounds hide each other) |
| `explain(id, site)` | Why the default was chosen, why an alternative is refused |
| `plan_diff(a, b)` | The decisions in which two states differ |
| `edit_kir`, `edit_wir` | Free-form text at those levels; recorded in the plan as a custom decision and reported as a promotion candidate |

The decision catalog (first version; "KB" is the entry in `kb/OPTIMIZATIONS.md` that measured it;
the first alternative is the default and is what amdclang does):

| Level | Site | Decision | Alternatives | KB | Milestone |
|---|---|---|---|---|---|
| kir | kernel | `map.elements_per_lane` | 1 as written, 2, 4 | B4 | M17 |
| kir | kernel | `map.bytes_per_wave` | as written, 512 B, 1 KB per stream | B3 | M17 |
| kir | kernel | `map.lanes_across_row` | one row per lane, lanes span a row | A4 | M17 |
| kir | kernel | `map.waves_per_workgroup` | as written, 1, 2, 4, 8 | B5, B6 | M17 |
| kir | kernel | `launch.coarsen` | 1, 2, 4, 8 | B1 | M17 |
| kir | kernel | `launch.throttle` | none, workgroups per CU | B2 | M17 |
| kir | loop | `loop.unroll` | 1, 2, 4, 8, 16 | A1 | M12 |
| kir | loop | `loop.bulk` | masked loop, unmasked bulk loop and masked tail | F4 | M12 |
| kir | branch | `branch.form` | mask region, if-conversion (`v_cndmask`), uniform branch | | M12 |
| kir | math call | `math.<fn>` | exact (port of the device library), hardware instruction, polynomial | D4 | M14 |
| kir | fp expression | `fp.contract`, `fp.reassoc`, `fp.recip` | as amdclang `-O3`, relaxed under the tolerance | G1 | M14 |
| kir | private array | `array.home` | registers, LDS slot per thread | E3 | M13 |
| kir | region | `idiom.contract` | loops as written, MFMA tiles (form, tiles, unroll, waves, ahead, share) | D1, D2 | M19 |
| kir | region | `idiom.histogram` | shared atomics, per-lane slots merged after the barrier | E1 | M17 |
| kir | two kernels | `fuse` | separate, one kernel | #73 | M19 |
| wave | reduction | `reduce.form` | LDS tree as written, DPP per wave and one LDS merge, `v_readlane` | C1, C2 | M13 |
| wave | reduction | `reduce.order` | source order (bit-identical), per-lane partials (tolerance) | | M13 |
| wave | uniform load | `load.uniform` | vector load, `s_load_dwordxN` | A3 | M13 |
| wave | load | `load.addr` | 64-bit per lane, scalar base and 32-bit lane offset, immediate offset | A2 | M13 |
| wave | load, store | `access.width` | 1, 2, 3, 4 dwords per lane | A2 | M13 |
| wave | load | `load.hint` | none, `nt`, `sc0 sc1 nt` | A9 | M13 |
| wave | branch | `branch.skip_empty` | execute under an empty mask, branch over | F3 | M12 |
| wir | loop | `loop.inflight` | 1, N iterations' loads before one wait | A1 | M12 |
| wir | loop | `pipe.ahead` | 0, the next tile's loads before this tile's work | A6 | M17 |
| wir | block | `order.loads_first`, `order.store_asap` | source order, loads before the scalar prologue, stores when ready | F1 | M17 |
| wir | idle workgroups | `prefetch.idle` | exit, one discarded load each | A7 | M17 |
| mir | kernel | `kernarg.load` | per use, one wide load at entry, preload in SGPRs | | M13 |
| mir | kernel | `wait.policy` | at first use and weakest (the only policy; the knob is which use) | F2 | M11 |
| mir | block | `hazard.policy` | `s_nop`, interleave an independent chain | | M16 |
| mir | kernel | `regalloc.target` | waves per SIMD, AGPR use, SGPR overflow (`vcc` as a scalar, VGPR broadcast) | E4 | M16 |

### The harness around it

- **Gates** (before any GPU job): on `kir`, type and structure; on `wir`, the four categories
  (program safety: an LDS write read by another wave with no barrier between, a barrier under a
  divergent mask; hardware conformance: LDS size, register budgets, MFMA forms, occupancy; data
  consistency: dtype, shape and layout between producer and consumer; schedule semantics: every
  stream and region used as declared); on `mir`, the existing static check. A finding names the
  site, the category and a suggestion. An analysis that does not cover a construct says so.
- **Translation checks on the CPU** (in CI): `kir` interpreter against the NumPy reference;
  every `kir` → `kir` rule before against after; `wir` against `kir`; `mir` against `wir`, on
  reduced shapes from the battery's generators.
- **Execution gates** (unchanged): the full battery, `equivalent` against the original binary,
  paired timing over placements.
- **Cost model** (`agc/cost`): launch, memory traffic per stream kind (contiguous, strided,
  non-temporal), latency-bound loops (loads in flight per wait), LDS and barriers, MFMA issue,
  arithmetic; returns a time and the binding term. Calibrated on the timed states in the stores;
  outside the calibrated domain it returns "no estimate". A verified state mispredicted by more
  than 15 % becomes a calibration item.
- **Evolution loop.** Each friction item of a session report is routed to one of: the candidate
  (agent error), a verifier rule, a cost-model calibration, the IR vocabulary or a lowering rule,
  a tool. `scripts/evolve.py` aggregates over sessions into ranked proposals. A proposal becomes
  a PR that passes `make gate` (every kernel: all levels' checks, CPU translation checks, battery
  on the GPU, no time regression beyond the noise floor) and is merged by a human.
- **Escape hatch.** `edit` / `edit_ir` on `mir` stay. The report counts raw-`mir` instructions per
  result; a result that needed them names the missing rule.

### What is reused, and the reference map

Reused unchanged: manifest, executor, battery, timing, store, static checks, `abi.make_kernel`,
`fix_waits`, `fix_hazards`, the virtual-register builder and linear-scan allocator
(`agc/gen/builder.py`), `tair`, the knowledge base, the agent runner.

Reused from the reference implementation (`~/agentic-compiler`, read-only): `agc/kir` (about
5 k lines), `agc/frontend` (Clang JSON AST to `kir`, about 9 k lines for a much wider C++ subset
than this benchmark needs), `agc/tair/recover.py` (idiom lifting).

LLVM sources to write each lowering from (`llvm-project`, ROCm branch; paths under
`llvm/lib/Target/AMDGPU` unless noted):

| agc component | Read |
|---|---|
| HIP builtins, kernel entry | `clang/lib/Headers/__clang_hip_math.h`, `__clang_hip_libdevice_declares.h`, `__clang_cuda_builtin_vars.h`; HIP's `amd_detail` headers; `AMDGPULowerKernelArguments.cpp`, `AMDGPULowerKernelAttributes.cpp`, `AMDGPUHSAMetadataStreamer.cpp`, `AMDGPUAsmPrinter.cpp` |
| Uniformity and control flow | `llvm/lib/Analysis/UniformityAnalysis.cpp`, `llvm/lib/Transforms/Scalar/StructurizeCFG.cpp`, `AMDGPUAnnotateUniformValues.cpp`, `SIAnnotateControlFlow.cpp`, `SILowerControlFlow.cpp`, `SILowerI1Copies.cpp`, `SIOptimizeExecMasking.cpp`, `SIOptimizeExecMaskingPreRA.cpp` |
| Instruction selection | `AMDGPUISelDAGToDAG.cpp`, `SIISelLowering.cpp`, `AMDGPUInstructionSelector.cpp`, `SIInstructions.td`, `VOP*Instructions.td`, `SOPInstructions.td`, `SMInstructions.td`, `FLATInstructions.td`, `DSInstructions.td` |
| Integer division, 64-bit arithmetic, casts | `AMDGPUCodeGenPrepare.cpp` (`expandDivRem32`), `SIISelLowering.cpp` |
| Private arrays | `AMDGPUPromoteAlloca.cpp`, `SIFrameLowering.cpp` |
| Math | ROCm device libraries (`ocml`), `AMDGPULibCalls.cpp` |
| Peepholes | `SIFoldOperands.cpp`, `SIShrinkInstructions.cpp`, `SIPeepholeSDWA.cpp`, `SILoadStoreOptimizer.cpp` |
| Registers and scheduling | `SIRegisterInfo.td`, `SIRegisterInfo.cpp`, `SIFixSGPRCopies.cpp`, `GCNSchedStrategy.cpp`, `GCNRegPressure.cpp` |
| Waits and hazards (already used in M4) | `SIInsertWaitcnts.cpp`, `GCNHazardRecognizer.cpp` |

### Milestones

Order is the order of work. One issue and one stackable PR per milestone (larger ones split into
the listed slices). Every milestone ends on the GPU with a number in `progress.md`. Sizes are
estimates of non-test Python; the total, about 30 k lines, is roughly 2.5 times today's `agc/`.

#### M11: tracer bullet, straight-line kernels from HIP to the GPU with no amdclang code generation

- [x] `agc/frontend`: Clang JSON AST (cached under the same key as HIP builds) to `kir`, subset
      v0: one `extern "C" __global__` entry, scalar and pointer parameters, locals, arithmetic,
      casts, `if`, subscripts, `threadIdx` / `blockIdx` / `blockDim` / `gridDim`. An unsupported
      construct is a structured refusal (kind `frontend`, source location, every unsupported node
      listed at once).
- [x] `agc/kir`: types, IR, text, verifier, interpreter (ported).
- [x] `agc/wir` v0: `u` / `v` / `m` values, arithmetic, compare, `select`, `load` / `store`,
      `where`; text, verifier, interpreter.
- [x] Wave lowering v0: uniformity lattice (constant, workgroup-uniform, wave-uniform, affine in
      the lane with a stride, varying); `if` to a mask region.
- [x] Selection v0, table-driven; the patterns are data (`agc/arch/gfx950.isel.yaml`, checked
      against the ISA table), not Python. Then the existing allocator, `fix_waits`, `fix_hazards`,
      `abi.make_kernel` (hidden arguments for the grid and block sizes).
- [x] Plan framework: decision registry, sites, the plan stored with the state; session and MCP
      `lower`, `plan` (the decisions of a state, with alternatives), `replan`, `explain`, `ir`.
- [x] Session: state `src` (the `kir` of the source) next to `ref` and `baseline`.
- [x] `scripts/own_path.py` → `tests/baselines/own-gfx950.json`: per kernel, how far it gets
      (frontend, `kir` check, lowered, static check, battery) and its time over amdclang `-O3`.
- [x] Brought forward because parity on the first kernels needed them: constant-trip loops in the
      frontend and `kir` (unrolled), inlining of functions and template instantiations, `access.width`
      (adjacent accesses merged into `dwordx2/x4`, from M13), redundant-load elimination and
      store-to-load forwarding in `wir`, `extend(x + c)` → `extend(x) + c` from `nsw` and known bits.
- [x] CPU translation checks (`agc/lower/checks.py`): `kir` against the reference, `wir` against `kir`;
      the frontend's output is recorded as `tests/kir/*.kir`, so CI lowers and checks without Clang.

Exit: at least five straight-line elementwise kernels (candidates `axpy`, `cast_bf16`, `rb_copy`,
`rb_scal`, `rb_swap`; the frontend's coverage report decides) pass the full battery through the own
path; bit-identical to amdclang by `equivalent`; each at 0.90 of amdclang's speed or better; the
CPU translation checks run in CI. Size: about 3.5 k.

Done (#79): seven kernels (`axpy`, `cast_bf16`, `rb_axpy`, `rb_copy`, `rb_rot`, `rb_scal`, `rb_swap`),
all bit-identical to amdclang; numbers in `progress.md`.

#### M12: control flow, loops, the first decisions that beat amdclang

- [ ] Frontend: `for` / `while` / `do`, `break`, `continue`, early `return`, ternaries, compound
      assignment, mutated locals (SSA construction), `__builtin_assume`.
- [ ] `kir` passes: constant folding, DCE, CSE, simplification, LICM, induction variables.
- [ ] Wave lowering of control flow: uniform conditions to scalar branches; varying conditions to
      mask regions (`s_and_saveexec_b64`, `s_andn2_b64`, `s_or_b64`); varying loops with an active
      mask that end when it is empty; `break` / `continue` / `return` as masks; mask values in
      SGPR pairs.
- [ ] Decisions: `loop.unroll`, `loop.inflight`, `loop.bulk`, `branch.form`, `branch.skip_empty`.
- [ ] `replan`, `plan_diff`; the policy tries the loop decisions.

Exit: every corpus and LLM kernel with loops and no LDS or transcendental math passes the battery
through the own path. Default plan at 0.90 of amdclang or better on each. With `loop.inflight`
chosen by the policy: `matvec` at 2.5x and `gemm_naive` at 2.0x over amdclang `-O3` (the pass on
imported assembly reached 2.79 and 2.19), bit-identical. Size: about 3 k.

#### M13: memory, LDS, barriers, cross-lane operations

- [ ] Frontend: `__shared__` arrays, `__syncthreads`, `atomicAdd`, `__shfl_xor` / `__shfl_down`,
      fixed local arrays, records of scalars, pointer arithmetic, 64-bit integers, integer division
      and remainder, `reinterpret_cast` and `__builtin_bit_cast` views.
- [ ] `wir`: LDS regions, barriers, wave roles, `lds.*`, `lane.reduce`, `lane.shuffle`, streams.
- [ ] `wir` gates in the four categories, each validated by a seeded mutation suite as in M4.
- [ ] Lowering: 64-bit integers on register pairs; division (the expansion of
      `AMDGPUCodeGenPrepare`, constants by multiplication); private arrays to registers or an LDS
      slot per thread (scratch memory is refused with a reason; stretch).
- [ ] Decisions: `reduce.form`, `reduce.order`, `load.uniform`, `load.addr`, `access.width`,
      `load.hint`, `kernarg.load`, `array.home`.
- [ ] `mir` interpreter for the instructions the selector emits; each instruction's semantics
      checked against the device by generated single-instruction probe kernels through the executor.

Exit: all corpus kernels without transcendental math, including `gemm_tiled`, `row_sum`,
`row_argmax` and `transpose`, pass through the own path; default plan at 0.90 or better each;
`reduce.form = dpp` on `row_sum` at 1.2x over amdclang (template `rowwise`: 1.25 to 1.30); the
`mir` interpreter agrees with the device on every probe. Size: about 4 k.

#### M14: math and numerics

- [ ] The math functions the benchmark uses (`exp`, `exp2`, `log`, `log2`, `sqrt`, `rsqrt`,
      `tanh`, `sin`, `cos`, `sincos`, `pow`, `fabs`, `fmax`, `fmin`), each with up to three
      lowerings: `exact` (the device library's algorithm, written once in `kir` text; what
      amdclang emits per function is read from its assembly first), `hw` (`v_exp_f32`,
      `v_log_f32`, `v_sin_f32`, `v_cos_f32`, `v_rsq_f32`, `v_rcp_f32`, `v_sqrt_f32` with range
      reduction where needed), `poly` (a polynomial with a stated error).
- [ ] Error tables: every unary `f32` lowering measured on all 2^32 inputs on the device against
      a float64 reference (maximum and distribution of the error in ULP), stored in `gfx950.yaml`
      as `measured`.
- [ ] Error model: the manifest's tolerance and the expression's condition decide which
      alternatives `actions` offers; `fp.contract`, `fp.reassoc`, `fp.recip` per site.
- [ ] `f16`, `bf16`, `f64` conversions and arithmetic.

Exit: `gelu`, `softmax`, `rmsnorm`, `layernorm` and the LLM kernels with math covered so far pass
the battery; `exact` is bit-identical to amdclang on those; on the kernels where `-ffast-math`
paid, the policy with tolerance-admitted alternatives is at least as fast as amdclang's
`-ffast-math` build (reported per kernel either way). Size: about 2.5 k.

#### M15: frontend breadth, the whole benchmark through the own path

- [ ] Templates (instantiated bodies as Clang resolved them), helper functions inlined, classes
      with methods, references, `constexpr`, the benchmark's headers (`flashinfer_common.h`,
      `miopen_common.h`, `attn_port.h`, `rowwise.h`). Ported from the reference frontend, bounded
      by what the benchmark uses; the supported subset is a table generated from the checker.
- [ ] `source(text)` compiles through the own frontend (an amdclang build of the same text stays
      available as a baseline candidate).
- [ ] A guard test: no call to amdclang's code generation outside baseline, oracle and fuzz code.

Exit: every kernel of `tests/kernels` and `bench/llm` compiles through the own path, passes the
CPU translation checks and the full battery with the default plan. Coverage table in the report.
Size: about 4 k.

#### M16: parity, the default plan as fast as amdclang -O3

- [ ] `scripts/parity.py`: per kernel `isa_diff` of own against amdclang, time ratio, the gaps
      ranked. This list, not a plan made in advance, orders the work below.
- [ ] `kir`: GVN, strength reduction of addresses, SROA, value ranges from the manifest's shapes
      and `__builtin_assume` (narrower integer arithmetic), alias information from the manifest.
- [ ] `wir` / `mir`: operand and immediate folding, the constant-bus rule at selection,
      `v_fmac` / `v_mad` fusion, SDWA for 8-bit and 16-bit, short encodings, load and store
      merging, mask optimizations, a list scheduler, live-range splitting, SGPR overflow,
      `hazard.policy`, `regalloc.target`.
- [ ] Fuzzing: random `kir` programs and a `kir` → HIP printer, so that amdclang is an oracle for
      programs outside the benchmark.

Exit: default plan, no search: geomean speed over amdclang `-O3` on the shipped sources at least
0.97 over all kernels, none below 0.90, median instruction count within 1.15x; fuzzing finds no
mismatch in 10 000 programs. Size: about 4 k.

#### M17: the phase-1 wins as decisions

Can start after M13, in parallel with M14 to M16.

- [ ] `launch.coarsen` (a loop over virtual workgroups in `kir`), `launch.throttle`, the `map.*`
      decisions with a dependence test on the `kir` as their precondition, `pipe.ahead`,
      `order.*`, `prefetch.idle`, `idiom.histogram`.
- [ ] Every entry of `kb/OPTIMIZATIONS.md` linked to a rule (its `applies_when` implemented as the
      rule's precondition), or marked edit-only, or marked as a measurement fact. `kb(query)`
      returns the rules that apply to the current state.
- [ ] Recipes re-expressed in `wir`: `attn_decode`, `mla_decode`, `vl_moe_align`, `rb_scal`,
      `fi_merge_states`. Each gap is a vocabulary or rule proposal.

Exit: with no raw `mir` edit, decisions reproduce the corpus results (elementwise 1.5x to 1.6x,
rowwise 1.2x to 1.5x) and at least three of the five recipes at 0.97 of their recorded time or
better. Size: about 3 k.

#### M18: search harness and cost model

The cost model can start any time: it uses the existing records.

- [ ] `agc/cost` with attribution and "no estimate"; calibration script over the stores; held-out
      evaluation by kernel.
- [ ] `sweep`, `attribute`, estimates in `actions`, the search tree in `list_states`.
- [ ] The default policy becomes a budgeted search over decisions ranked by the model.
- [ ] `report` routes friction; `scripts/evolve.py`; the admission checklist in the `dev-workflow`
      skill; `make gate`.
- [ ] The session prompt follows four stages: structurally distinct candidates, filter (gates and
      model), evaluate survivors, route the evidence.

Exit: rank correlation of predicted and measured time at least 0.8 on held-out kernels; on a
10-kernel sample the model's filter halves the GPU timings needed to reach the same best state;
the policy's geomean over amdclang `-O3` is reported for all kernels and is not below phase 1's
policy on any kernel beyond the noise floor. Size: about 3 k.

#### M19: the tensor-core path from HIP

- [ ] Idiom lifting from `kir` regions to `tair` (maps, row reductions, contractions), each lift
      checked by interpreter equivalence and then by the battery.
- [ ] The templates (`elementwise`, `rowwise`, `gemm_mfma` with LDS sharing, `attention_mfma`) emit
      `wir`: LDS tiles, wave roles, accumulators and MFMA forms declared, layouts as checked
      commitments.
- [ ] `idiom.contract` and `fuse` as decisions.

Exit: from the HIP sources, by decisions only, `gemm_bf16` reaches the template's result (200x
amdclang) and `fa_attention` 1.9x over the strongest amdclang build; `mir` from the `wir`
templates is within 3 % of today's templates. Size: about 2.5 k.

#### M20: campaign and the co-design experiment

- [ ] The whole benchmark: default plan, policy and agent sessions through the own path, against
      amdclang `-O3` on the shipped source and against the strongest amdclang build.
- [ ] Matched experiment: arm A, decisions and `wir`; arm B, raw `mir` edits on amdclang's
      assembly (the phase-1 harness). Same model, prompt scaffold, oracle and token budget; three
      runs per arm on at least six kernels (two re-reading, two LDS-bound, two latency-bound); the
      target kernel's recipe and knowledge-base file withheld in both arms. Reported: best speedup
      at the budget as median [min, max], tokens to the first verified win, static refusals, GPU
      seconds, raw-`mir` instructions in the result.
- [ ] Report, knowledge base and progress updated.

Exit: both tables published; the co-design claim is reported whichever way it comes out.

#### M21: amdclang leaves the product path

- [ ] `agc build`, `agc optimize` and `agc agent` use the own path for HIP; amdclang remains as
      parser, baseline, oracle and reference; import remains for existing assembly.
- [ ] Recipes of phase 1 that are still the best result are kept and labelled by path.

Exit: a clean run of the benchmark with amdclang's code generator used only for baselines.

### Dependencies and parallel work

```text
M11 ─► M12 ─► M13 ─► M14 ─► M15 ─► M16 ─┐
               │                        ├─► M20 ─► M21
               ├─► M17 ─► M19 ──────────┤
        M18 (cost model from day one; tools after M12) ┘
```

Three tracks can run side by side after M12: frontend breadth (M15 slices), lowering and back end
(M13, M14, M16), harness (M17, M18).

### How results are reported in phase 2

- Three columns per kernel until M21: the own path's default plan, the own path's best verified
  state (policy or session), and phase 1's best state (import path). A slower own-path result is a
  loss with its ratio, never hidden behind the import path.
- The baselines do not change: amdclang `-O3` on the shipped source, and the strongest amdclang
  build. A restructuring done through decisions is agc's gain; the strongest amdclang build still
  gets the rewritten source when a session writes one.
- Every result names its plan; `agc replay` rebuilds from HIP and the plan.

### Risks

| Risk | Mitigation |
|---|---|
| The own path stays slower than amdclang on plain code for a long time | Parity is its own milestone with a worklist from `isa_diff`; the import path remains until M21; losses are reported |
| Frontend scope grows without bound | The subset is bounded by the benchmark; the coverage table comes from the checker; a refusal is a result |
| A new code generator produces silently wrong code | Four independent checks: interpreters at three levels on the CPU, the `mir` static check, the battery, `equivalent` against amdclang's binary; fuzzing against amdclang |
| Three IRs are too much to maintain | Each has one contract and one interpreter; `wir` starts with what M11 needs and grows only by porting a kernel that needs more |
| The decision space is too large to search | Defaults reproduce amdclang; the cost model filters; `sweep` uses a 20-pair screen; decisions are per site, so `attribute` says where to look |
| Math differs from amdclang in the last bit | `exact` ports the same algorithms and is compared on all inputs; the tolerance, not bit-identity, is the contract for the other alternatives |
| The cost model misleads | It filters and ranks only; the GPU is the ground truth; a misprediction is a calibration item; it declines outside its domain |
| Decisions do not beat raw edits | M20 measures it with matched arms; raw `mir` stays available |

### Not in this phase

| Item | Trigger |
|---|---|
| An own parser for the HIP subset (no Clang at all) | Clang's AST is unavailable or unstable on a target ROCm |
| Scratch (private memory) code generation | A kernel's private array fits neither registers nor LDS |
| Shape portfolios and dispatch (a declared shape domain, variants behind guards with a fallback, held-out shapes) | A recipe wins at the bench shape and loses at another shape of the battery |
| Other targets (`gfx942`) through arch data and a second selection table | Requested |
| General C++, separate compilation, device function calls that are not inlined | Not planned |

## Stretch (not scheduled; opened as an issue when the trigger occurs)

| Item | Trigger |
|---|---|
| Machine-model calibration beyond M7's microbenchmarks (#7) | Partly scheduled: the cost model of M18; the rest when a scheduler decision needs a latency that is not measured |
| Attention, prefill and decode (#12) | M7's exit is met |
| GEMM with LDS-shared macro-tiles (#23): **done**, 1.4x to 1.6x hipBLASLt's time (was 2.5x to 2.8x) | M7 measured a 2.8x gap to hipBLASLt, bound by operand loads |
| FP8 GEMM (#75): **done**, 1.2x to 1.3x hipBLASLt's FP8 time | M7's exit is met |
| Re-allocation of imported code (physical → virtual → physical) | An imported kernel is measured to be occupancy-limited |
| Wave64 `mir` interpreter | Scheduled in M13 (the own code generator needs it for CPU-side checks) |
| `rocprofv3` profiler action | The agent loop lacks stall evidence that timing alone cannot give |
| Trace retrieval and recipe promotion | M9 produces enough traces to reuse |
| CUDA input through `hipify-clang` | Requested |

## Risks

| Risk | Mitigation |
|---|---|
| Timing noise on SR-IOV VFs hides small wins | Paired interleaved timing, A/A control in every run, wins need a separated CI |
| A missing wait or `s_nop` gives silent wrong results | M4 before any edited code runs; mutation suite; battery with poisoning and hidden seeds |
| The hazard list for gfx950 is incomplete in public documents | Derived from the ISA document and LLVM's `GCNHazardRecognizer`, validated by zero violations on amdclang output |
| Import path yields no wins over amdclang | Expected for some kernels and reported as such; the generator path (M6, M7) carries the headline |
| No general pass wins on a kernel | Not required: an agent session customizes that kernel (M10); the result is reported as a session result with its trace |
| MFMA GEMM does not reach hipBLASLt | The exit is relative to amdclang; the hipBLASLt gap is reported and analysed, not hidden |

## What changed in this revision

- (2026-11-21) Phase 2 added (#77): agc's own lowering from HIP to assembly through `kir` and
  `wir`, lowering as recorded decisions with alternatives and replanning, a cost model, the
  evolution loop, a matched experiment against raw `mir` edits; modelled on CAKE
  (arXiv 2608.12629), with the difference that agc targets the machine's assembly and not PTX.
  D3 and D9 of the design are replaced; principles 7 and 8 added; the `mir` interpreter is
  scheduled.

- (2026-11-20) Positioning made explicit: agc is a harness for per-kernel agent
  optimization, not a general compiler; principle 6 and M10 added.

- The agent interface moved from tenth to sixth place (M5), before any automatic pass.
- Backend passes moved after the generators and are scoped by what M5 measures; full
  re-allocation of imported code became a stretch item.
- The interpreter, standalone machine-model calibration, attention, FP8, the profiler
  and recipe promotion became stretch items with triggers.
- Every milestone has a measurable exit criterion; the corpus is sized at about 12 kernels.
- Risks are listed.
