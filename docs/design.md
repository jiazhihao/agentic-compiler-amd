# agentic-compiler-amd: Design

A tensor-algebra program and a manifest go in; an optimized AMDGPU code object
(`.hsaco`) for **AMD Instinct MI355X (CDNA4, `gfx950`, wave64)** comes out. The input is
a HIP kernel, or a tensor-level program (einsum, TAIR text, a NumPy/PyTorch reference)
with no kernel source at all. The compiler owns semantics, legality, verification and
measurement; an agent (Claude Code through MCP) or a scripted policy chooses the
transformations.

**agc is a harness for an agent, not a general compiler.** The aim is not one fixed
pipeline that beats `amdclang` on arbitrary code. The aim is that an agent, working on
one kernel at a time, can beat `amdclang` on that kernel by specializing and customizing
its optimization: reading the assembly, choosing or parameterizing a pass, generating the
kernel from its tensor program with a schedule fitted to its shapes, changing the launch
geometry, or editing instructions by hand. agc gives the agent the actions to do this
and the checks that make the result trustworthy (static safety, the battery, paired
timing). The unit of result is therefore a kernel with its verified, replayable trace,
and a benchmark result is a set of per-kernel sessions. General passes and the default
policy are what the sessions have shown to pay often enough to automate; they are the
floor an agent starts from, not the product.

This project reuses the design and infrastructure of the NVIDIA reference implementation
([jiazhihao/agentic-compiler](https://github.com/jiazhihao/agentic-compiler), Hopper/PTX)
and changes the bottom of the stack. On NVIDIA the compiler emitted PTX and `ptxas`
did scheduling and register allocation. AMD publishes a complete, machine-readable
specification of the CDNA4 ISA, so here **agc emits final machine instructions itself**.
It owns instruction scheduling, register allocation, `s_waitcnt` placement and hazard
avoidance. LLVM's assembler (`llvm-mc`) only encodes, and `ld.lld` only links; neither
reorders or reallocates anything.

**Success metric.** Measured kernel time against what the ROCm stack produces for the
same workload: `amdclang -O3` on the same HIP source first (paired, same timing
protocol), then the vendor libraries (hipBLASLt, Composable Kernel, AITER) where they
cover the operation. A speedup is reported only with a passing verification and a
statistically separated timing.

## 1. Goals and non-goals

**Goal.** For a given workload (operation, shapes, dtypes, numerical contract), let an
agent produce a binary faster than the ROCm compiler's build of the same program, and as
close as possible to (or faster than) the best hand-tuned vendor kernel, by optimizing
that kernel specifically. The manifest's shapes, dtypes, launch and numerical contract
are the specialization context: a session may fix a schedule, an unroll factor, a tile
size or a launch geometry that is right for this workload and wrong in general. Compile
time is traded for performance: a session may spend minutes to hours of agent and GPU
time on one kernel. Every result is a verified, replayable trace of named decisions.

**Kept from the reference design.** The manifest as the contract (entry point, tensors,
shapes, launch, reference program, numerical contract); immutable, content-addressed
states; readable custom IRs, each with a parser, printer, verifier and (where it pays)
an interpreter; compiler-owned checking and timing; one serialized GPU executor; an
agent action menu with legible rejections; trace reuse, recipe promotion and knowledge
notes.

**Non-goals.** A general-purpose optimizing compiler that is better than `amdclang` on
every program with no agent in the loop (the default policy is measured and reported,
but a fallback to amdclang's build is an accepted outcome of it); general HIP C++ (the HIP path goes through `amdclang` and is bounded by
what can be imported), a drop-in `hipcc` replacement, RDNA/wave32, other CDNA generations
(possible later through arch data), multi-GPU collectives, multi-kernel fusion.

## 2. Key decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Machine IR (`mir`) is the optimization level that owns the output.** Its physical form is the shipped program, instruction for instruction. | The large MI355X wins (MFMA/LDS/VMEM interleaving, AGPR placement, `s_waitcnt` placement, wave ping-pong, direct-to-LDS loads) are instruction-level decisions. Owning them makes them visible, searchable and agent-editable. |
| D2 | **Operand legality comes from AMD's machine-readable ISA XML** (`amdgpu_isa_cdna4.xml`, MIT), compiled into `agc/isa/cdna4.json.gz` by `scripts/gen_isa.py`. | The specification is concrete and complete; no hand-written opcode tables. `llvm-mc` is a second, independent check (it must encode every instruction). |
| D3 | **HIP enters through `amdclang -O3 -S` and is imported into physical `mir`.** | Reusing Clang for HIP parsing, template instantiation and lane-level selection gives every HIP kernel a parity starting point; agc's passes and the agent improve from there instead of starting from scratch. (The reference's Clang-AST → `kir` frontend is deliberately not ported first; see D9.) |
| D4 | **Tensor programs enter at `tair` and are generated straight into virtual `mir`** by schedule templates (elementwise, rowwise, reduction, GEMM/MFMA, attention), then register-allocated by agc. | High-level inputs have no HIP to import. Generators produce MFMA/LDS code that the lane-level path cannot reach (e.g. a naive HIP GEMM can be replaced by an MFMA kernel because the spec, not the source, is the contract). |
| D5 | **A machine model as data**, `agc/arch/gfx950.yaml`, every field tagged `isa-doc`, `rocminfo` or `measured`; measured fields come from on-device microbenchmarks. | Without a vendor scheduler, agc's scheduler needs latencies, issue rules and hazard windows. Python code holds no architecture constants. |
| D6 | **Independent static checkers** (verifier, hazard checker, waitcnt checker, encode round-trip) run on every physical `mir` before any GPU job, separately from the passes that produced it. They are validated on every `amdclang` output in the corpus (zero violations) and by seeded mutations. | A missing wait or `s_nop` produces silent wrong results, not crashes. A candidate must not be able to skip the checker. |
| D7 | **Compiler-owned verification and timing.** The candidate cannot choose its oracle, inputs, tolerance or measurement. Protocol `agc-timing-amd-2` (versions and what changed: `agc/runtime/timing.py`). | Unchanged from the reference. Speedups are paired against amdclang under the same protocol. |
| D8 | **One machine-wide GPU executor** (subprocess workers, a lock, interactive before batch), using the HIP module API through `libamdhip64` via ctypes. | Isolation, reproducibility and accounting; no HIP headers needed at runtime. |
| D9 | **`kir` (lane-level IR) and the Clang-AST frontend are deferred**, not dropped. | `amdclang` + import covers HIP inputs at parity; generators cover high-level inputs. A lane-level IR returns only if a measured case needs a lane-level transformation that neither path provides. |
| D10 | **Agent and scripted policy share one action menu.** | The default policy is the regression baseline; the agent explores. |
| D11 | **Per-kernel specialization through the agent is the product; general passes are its by-product.** Every optimization is available as an action on one kernel's state (a parameterized pass, a generator template with its knobs, a launch change, a free-form `mir` edit), and nothing has to be general to be used. | The wins differ by kernel (loads in flight for one, coarsening for another, MFMA or a DPP reduction for a third) and depend on shapes and launch. A fixed pipeline has to be right for all kernels; an agent with a harness only has to be right for the one in front of it, and the checks, not the generality of the transformation, make the result safe. A customization that recurs is promoted to a pass or a template and enters the default policy. |

## 3. The IR stack

```text
 HIP + manifest ──amdclang -O3 -S──► asm ──import──────────────► mir (physical)
                                                                   │  deallocate (liveness)
 einsum / tair / NumPy ref ──► tair ──template──► mir (virtual) ◄──┘
                                                       │ schedule, regalloc,
                                                       │ waitcnt, hazards, peephole
                                                       ▼
                                               mir (physical) ──► checkers
                                                       │ emit + kernel descriptor + metadata
                                                       ▼
                                         llvm-mc → ld.lld → .hsaco
                                                       ▼
                            check (battery) / bench (paired timing) / profile (rocprofv3)
```

### 3.1 `tair`: the specification

A shape-typed dataflow graph over whole tensors: maps, reductions, contractions,
casts and layout ops, with a NumPy interpreter and an error model that derives
tolerances. It is the language-neutral entry point; a manifest whose reference is an
einsum or TAIR text is compiled with no kernel source.

### 3.2 `mir`: Machine IR

One **wavefront's** program in real CDNA4 mnemonics, in two forms sharing one text
syntax:

- **Virtual:** values of class `s` (SGPR), `v` (VGPR), `a` (AGPR) and tuples
  (`v[4]`, `a[16]`) as `%name`; explicit `exec`/`vcc`/`scc`; basic blocks.
- **Physical:** concrete registers, `s_waitcnt`/`s_nop` present, the kernel descriptor
  resolved. This is exactly the shipped program.

Every instruction is checked against the ISA table (operand count, register class and
width per operand, encoding). The kernel carries its descriptor (`.amdhsa_*` fields)
and code-object metadata (arguments, segment sizes, register counts) as data, and agc
recomputes register counts and `accum_offset` from the instruction stream.

**Backend passes** (each a named action with parameters):

| Pass | Responsibility | Agent-visible knobs |
|---|---|---|
| `schedule` | List scheduling per block on the machine model; software pipelining of single-block loops | interleave groups, priorities, fixed orders |
| `regalloc` | VGPR/AGPR/SGPR allocation, tuple alignment, occupancy target | waves-per-SIMD target, AGPR use, pinning |
| `waitcnt` | Minimal `s_waitcnt vmcnt/lgkmcnt/expcnt` from a counter dataflow analysis | relax to a named use, merge, split |
| `hazards` | `s_nop` insertion for required wait states from the arch hazard table | none: mandatory and checked |
| `peephole` | Fusions (`v_lshl_add`, `v_fmac`, `v_pk_*`), scalarization, dead code | rule selection |
| `descriptor` | Kernel descriptor, metadata, kernarg preload, LDS size | preload count |

**Transformations of an imported kernel** (`apply`), bit-identical by construction:
`unroll_loads` (several iterations' loads in flight per wait in a counted loop) and `coarsen`
(one launched workgroup runs `factor` consecutive workgroups of the original: the kernel body
becomes a loop over virtual workgroup ids that starts every iteration from the entry state, the
launch shrinks to `ceil(grid_x / factor)`, and one appended argument carries the original
`grid_x`). A transformation that changes the launch records the new launch (grid, block,
appended arguments) with the state; the runtime launches the state that way.

**Checks** before any GPU job: verifier, hazard checker, waitcnt checker, and
`llvm-mc` encode plus `llvm-objdump` round-trip to the same instruction stream.

**Feedback.** Build records keep register counts, LDS, scratch, occupancy and the
instruction stream; `asm_diff(a, b)` compares two kernels; `rocprofv3` counters and
thread trace give per-instruction stall evidence.

## 4. Inputs

1. **HIP** (primary): `amdclang -x hip --offload-arch=gfx950 -O3 -S`, imported.
2. **CUDA**: `hipify-clang`, then as HIP; the CUDA original is provenance only.
3. **Tensor programs**: einsum / TAIR text / NumPy reference in the manifest.
4. **Existing assembly** (hand-written or library kernels): imported into `mir`.

## 5. The agent interface

A `Session` exposes the same operations through Python, MCP and the CLI. It is the
interface the agent optimizes one kernel through: inspect the state, try a
transformation specific to this kernel, get it checked and measured, keep or discard
it. The harness never trusts the agent: whatever the agent produces passes the same
static checks, battery and paired timing as a built-in pass.

| Group | Operations |
|---|---|
| Inspect | `state`, `actions`, `features`, `analyze`, `diff`, `asm_diff`, `trace` |
| Transform | `source` (a rewritten HIP source, compiled and imported), `generate` (template from `tair`), `apply` (any pass by name), `edit` / `edit_ir` (free-form `mir` text), `relaunch` (grid, block, appended arguments) |
| Validate and measure | `static_check` (verifier + hazards + waitcnt + encode), `check` (battery), `bench` (paired timing, memory traffic and headroom), `compare` (two states against each other) |
| Organize | `branch`, `tag`, `notes`, `search_memory` |

The actions range from general to fully custom, and a session mixes them freely:

| Level | Action | What is specialized |
|---|---|---|
| Automated | `optimize` (the default policy) | Nothing: tries the built-in candidates and keeps the best verified one |
| Parameterized | `apply(pass, params)`, `generate(template, params)` | Factors, tiles, elements per lane, which loop, launch geometry |
| Custom | `edit` / `edit_ir` on `mir` text | Anything expressible in CDNA4 assembly for this kernel and these shapes |
| Restructuring | `source(text, launch)` | The algorithm's split over threads and workgroups, elements per thread, block size, reductions: a rewritten HIP source that amdclang lowers, then refined at the `mir` level |

Transformations create immutable, content-addressed states; verification and
measurement attach to the exact state. Free-form edits start unverified and must pass
the static checks before any GPU job. Rejections are JSON objects with a `kind`, the
offending location and values, and a suggestion.

### The per-kernel harness (`agc.agent`)

`agc agent MANIFEST` runs one optimization session on one kernel:

1. The default policy runs first; its results stay in the session's store.
2. A headless agent (Claude Code) gets the agc MCP tools as its only way to change anything,
   read access to the repository, the `agc` and `agc-notes` skills, a budget and a target
   (1.5x over the baseline, or the memory floor when the kernel is bound by memory). It works
   across the levels: restructure at the source level, generate from a tensor program, apply
   passes, edit `mir`.
3. The agent ends with `report(best, summary, tried, friction, lessons)`. Nothing in it is
   trusted. The harness reruns the static check and the full battery on the named state and
   times it with 240 pairs until two timings are valid (a timing whose 95 % CI is wider than
   4 % was disturbed and is discarded, whatever its direction). The state is a win only when
   both are wins; the lower one is recorded.
4. A verified win becomes a recipe (`bench/llm/sessions/<kernel>/`: module text, launch, the
   verified numbers). `agc replay` rebuilds and re-measures every recipe without the agent.
   A later session replaces a recipe only by beating it.
5. `friction` (what the tools, transforms or IR lacked) becomes compiler work; `lessons`
   (measured facts) go into the `agc-notes` skill, which the next session reads.

**The baseline is the strongest amdclang build, not `-O3` on the source as shipped.** The first
round of sessions showed that most of their speedups were source restructurings that amdclang
compiles by itself, and that `-ffast-math` alone is worth up to 2x on some kernels. A manifest
therefore names a `baseline` (`source`, `flags`, `defines`, `launch`): the best amdclang build
found for the kernel, chosen by `scripts/strong_baseline.py` among the shipped and the
restructured source, each with and without `-ffast-math`, each passing the battery. The session
imports it as state `baseline`; `bench`, the default policy and the harness measure against it,
and `ref` stays `-O3` on the shipped source for orientation. A session may still rewrite the
source, but the harness credits that to amdclang: when the session's own `source` state beats
the baseline it becomes a baseline candidate, and the final state is a win only if it beats
that build too. What is reported as agc's result is the gain at its own levels.

`bench` reports a kernel's memory traffic against a copy model measured on the device
(`time = 20 us + bytes / 5.95 TB/s`). Its ratio to the kernel's time, the headroom, says
whether a speedup target is reachable: a kernel at headroom 1.0 moves bytes as fast as a copy
does, and only moving fewer bytes can help.

### Verification layers

| Layer | Contract |
|---|---|
| 1 Legality | `mir` verifier, hazard checker, waitcnt checker, encode round-trip |
| 2 Interpreter (stretch, see roadmap) | A wave64 `mir` interpreter on reduced shapes; built only if a class of bug reaches the GPU that layers 1 and 3 miss |
| 3 Battery | Several input distributions, hidden seeds, shape variants, output poisoning, error-model tolerances, the reference computed independently (NumPy or torch) |
| 4 Timing (`agc-timing-amd-2`) | `hipEvent`s around a single prepared launch, L2 + MALL flush by a buffer larger than both, CI-converged medians, the amdclang reference timed the same way and interleaved (paired); clock state recorded (SR-IOV VFs cannot lock clocks) |

## 6. Self-improvement

Verified traces are stored with a fingerprint of the spec; schedule/interleave recipes
discovered at `mir` level are promotion candidates for the generators, gated on
held-out kernels; knowledge notes are rendered into the `agc-notes` skill.

## 7. Hardware model

`agc/arch/gfx950.yaml`: resources (256 CUs in 8 XCDs, 4 SIMDs per CU, wave64, 512-entry
unified VGPR+AGPR file per lane, SGPR limits, 160 KB LDS per workgroup, MFMA
shapes/types, cache sizes, peaks) and a machine model (latency/throughput per
instruction class, MFMA pass counts, hazard wait states, waitcnt counter widths, LDS
banks). Fields are tagged by source; `measured` fields are regenerated by
`agc/arch/microbench`.

## 8. Package layout

| Package | Responsibility |
|---|---|
| `agc/arch` | `gfx950.yaml`, the model loader, occupancy, microbenchmarks |
| `agc/isa` | The generated CDNA4 instruction table and its query API |
| `agc/manifest.py`, `agc/dtypes.py` | The contract and element types |
| `agc/runtime` | HIP driver (ctypes), toolchain wrappers, executor + worker, inputs, reference evaluation, battery, timing, profiler, baselines |
| `agc/mir` | IR, parser/printer, descriptor/metadata, emit, import, verifier, CFG/liveness, hazard and waitcnt checkers, interpreter, passes |
| `agc/tair` | Specifications and their interpreter |
| `agc/gen` | Template generators from `tair` to virtual `mir` |
| `agc/store`, `agc/session`, `agc/mcp`, `agc/cli.py` | States, actions, the agent interface |
| `agc/agent` | The per-kernel harness: session prompt, agent runner, independent verification, recipes, replay |
| `agc/memory` | Traces, retrieval, notes, recipe promotion |

## 9. Implementation plan

The roadmap is tracked in GitHub issue #1 with one sub-issue per milestone; the details
are in [roadmap](roadmap.md) and measured results in [progress](progress.md). The order
of work puts the agent loop on imported assembly first, generators second and automatic
backend passes third; components without a measured consumer are stretch items.
