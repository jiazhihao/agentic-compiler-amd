# Roadmap

Tracked in GitHub issue #1, one sub-issue per milestone. Revised 2026-11-19 (see
"What changed" at the end). Measured results go to [progress](progress.md).

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

## Milestones

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
- [ ] CFG, register def/use from the ISA table, liveness.
- [ ] Waitcnt checker (vmcnt / lgkmcnt / expcnt counter dataflow).
- [ ] Hazard checker; the wait-state table lives in `gfx950.yaml`.
- [ ] Register counts and `accum_offset` recomputed and checked against the descriptor.

Exit: zero violations on every amdclang output in the corpus; a seeded mutation suite
(dropped or weakened waits, removed `s_nop`, wrong register class, clobbered live
register) is caught at ≥ 95 %, with the misses listed.

### M5 — The agent loop on assembly (#9)
- [ ] Content-addressed store of immutable states; trace of actions.
- [ ] Session actions: `import`, `edit_ir`, `static_check`, `check`, `bench` (paired
      against the amdclang build), `asm_diff`, `state`, `branch`; rejections as JSON.
- [ ] MCP server and the `agc` skill; CLI `agc run`.
- [ ] A GPU job is refused for a state that has not passed `static_check`.

Exit: an agent session through MCP takes three corpus kernels from import to a paired
result. The outcome (win, parity or loss, with the edit that caused it) is recorded
for each; these observations decide the pass list of M8.

### M6 — Tensor programs in, binaries out (#10)
- [ ] `tair`: a small specification (maps, rowwise reductions, einsum contractions),
      text format, NumPy interpreter; manifests whose reference is the program.
- [ ] `mir` builder with virtual registers; for generated code: linear-scan register
      allocation, waitcnt insertion, hazard insertion (each checked by M4's checkers).
- [ ] Generators: elementwise (several elements per lane, wide loads), rowwise
      reduction, softmax, rmsnorm/layernorm.
- [ ] Session action `generate`; generator parameters are agent-visible knobs.

Exit: the tensor-program versions of the corpus kernels compile with no kernel
source, pass the battery, and are paired against the amdclang build of the HIP
version. Expectation: about parity on memory-bound elementwise kernels, wins on the
reductions and normalizations; the measured geomean is reported either way.

### M7 — GEMM on MFMA (#11)
- [ ] MFMA operand and accumulator layouts in arch data; the microbenchmarks this
      needs (MFMA issue rate, LDS read bandwidth, global load latency), written in `mir`.
- [ ] bf16 / f16 GEMM generator: LDS tiles, MFMA inner loop, AGPR accumulators.
- [ ] Tuning knobs as agent actions: tile sizes, unroll, load/MFMA interleave,
      direct-to-LDS loads, workgroup shape.
- [ ] Baselines: amdclang naive and tiled HIP GEMM; hipBLASLt.

Exit: verified bf16 GEMM at three shapes (square 4096, wide, tall), faster than the
amdclang tiled HIP build by a CI-separated margin; time relative to hipBLASLt reported
with an analysis of the gap. Target: within 1.5× of hipBLASLt on at least one shape.

### M8 — Backend passes for imported code (#8)
The pass list is fixed by the M5 observations; candidates:
- [ ] Waitcnt minimization (re-derive waits; relax to the first real use).
- [ ] Peepholes; kernarg preload.
- [ ] Block-local scheduling (hoist loads, interleave independent chains).
- [ ] Default policy: import → pass pipelines → static check → battery → paired bench →
      keep the fastest verified state, else the amdclang build (reported as a fallback).

Exit: the default policy is never slower than amdclang on the corpus (CI), and every
win is reported with its pass.

### M9 — Campaigns and report (#13)
- [ ] Agent sessions on the corpus and GEMM, with traces kept.
- [ ] Knowledge notes from the sessions rendered into the `agc-notes` skill.
- [ ] Final report: per-kernel paired speedup against amdclang and, for GEMM, hipBLASLt;
      A/A controls; what did not work.

## Stretch (not scheduled; opened as an issue when the trigger occurs)

| Item | Trigger |
|---|---|
| Machine-model calibration beyond M7's microbenchmarks (#7) | A scheduler decision needs a latency that is not measured |
| Attention, prefill and decode (#12) | M7's exit is met |
| FP8 GEMM | M7's exit is met |
| Re-allocation of imported code (physical → virtual → physical) | An imported kernel is measured to be occupancy-limited |
| Wave64 `mir` interpreter | A class of bug reaches the GPU that the static checkers and the battery miss |
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
| MFMA GEMM does not reach hipBLASLt | The exit is relative to amdclang; the hipBLASLt gap is reported and analysed, not hidden |

## What changed in this revision

- The agent interface moved from tenth to sixth place (M5), before any automatic pass.
- Backend passes moved after the generators and are scoped by what M5 measures; full
  re-allocation of imported code became a stretch item.
- The interpreter, standalone machine-model calibration, attention, FP8, the profiler
  and recipe promotion became stretch items with triggers.
- Every milestone has a measurable exit criterion; the corpus is sized at about 12 kernels.
- Risks are listed.
