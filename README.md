# agentic-compiler-amd

An agentic compiler for tensor-algebra kernels on **AMD Instinct MI355X** (CDNA4, `gfx950`). A HIP
kernel or a tensor program goes in with a manifest; a verified, measured code object comes out.
agc works on the machine instructions themselves: it owns `s_waitcnt` placement, hazard wait
states and registers, checks every instruction against AMD's machine-readable ISA, and lets
`llvm-mc` only encode. It is the AMD redesign of
[agentic-compiler](https://github.com/jiazhihao/agentic-compiler) (NVIDIA, PTX).

Results against `amdclang -O3` and hipBLASLt: [docs/report.md](docs/report.md).
Design: [docs/design.md](docs/design.md). Roadmap: [docs/roadmap.md](docs/roadmap.md) (issue #1).
Log of what was built and measured: [docs/progress.md](docs/progress.md).

## Use

```
python -m venv .venv && .venv/bin/pip install -e ".[dev]"

.venv/bin/agc optimize tests/kernels/matvec.json            # the default policy: best verified candidate
.venv/bin/agc run tests/kernels/softmax.json --generate     # compile the manifest's tensor program
.venv/bin/agc static tests/kernels/softmax.json             # static checks on amdclang's assembly
.venv/bin/agc check tests/kernels/axpy.json                 # battery; `bench` for timing
```

An agent drives the same operations through the MCP server (`.mcp.json`, `python -m agc.mcp.server`);
the `agc` and `agc-notes` skills in `.claude/skills/` describe the loop and what has been learned.

## Layout

| Path | What |
|---|---|
| `agc/isa` | CDNA4 instruction table generated from AMD's ISA XML, query and decode |
| `agc/arch` | `gfx950.yaml`: resources, hazards, MFMA data, each value with its source |
| `agc/mir` | machine IR: parser/printer, verifier, waitcnt and hazard checkers, passes, emit |
| `agc/tair`, `agc/gen` | tensor programs and the generators that compile them into machine IR |
| `agc/runtime` | HIP driver, toolchain, per-device executor, battery, timing, baselines |
| `agc/store`, `agc/session`, `agc/mcp` | states, the session and its policy, the MCP server |
| `tests/kernels` | the corpus: HIP kernels, manifests, tensor programs, references |

Requires ROCm (`/opt/rocm`) for anything beyond the CPU tests; `make test` runs both.
