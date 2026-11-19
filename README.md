# agentic-compiler-amd

An *agentic compiler* for tensor-algebra kernels on **AMD Instinct MI355X (CDNA4,
`gfx950`)**. A HIP kernel or a tensor-level program plus a manifest goes in; an
optimized code object (`.hsaco`) of directly emitted CDNA4 assembly comes out, verified
and measured against `amdclang -O3` on the same workload.

The compiler owns semantics, legality (from AMD's machine-readable ISA specification),
verification and timing; an agent (Claude Code through MCP) or a scripted policy owns
the decisions. It trades compile time for performance.

This is the AMD redesign of [agentic-compiler](https://github.com/jiazhihao/agentic-compiler)
(NVIDIA Hopper, PTX). The main difference: agc emits final machine instructions and owns
scheduling, register allocation, `s_waitcnt` and hazard handling itself, instead of
handing a virtual ISA to a vendor assembler.

Docs: [design](docs/design.md), [roadmap](docs/roadmap.md) (GitHub issue #1),
[progress](docs/progress.md).

## Quickstart

Python 3.12+, ROCm 7.x at `/opt/rocm` (with `amdrocm-core-dev` for HIP headers):

```sh
python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"
make test
```
