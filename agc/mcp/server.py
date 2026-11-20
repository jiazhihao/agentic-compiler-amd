"""MCP server exposing one compiler Session (design §5). Run: `python -m agc.mcp.server`.

The agent cannot choose the oracle, the inputs, the tolerances or the timing protocol; hidden
seeds are never shown; every refusal comes back as a JSON object with `error` and `kind`.
States live on disk, so `open` on the same manifest resumes the same session.
"""
from __future__ import annotations

import functools
import json
import os
import re
from pathlib import Path
from typing import Any

from mcp.server.mcpserver import MCPServer

from ..arch.model import load as load_arch
from ..isa import table
from ..session import Session, SessionError

ROOT = Path(os.environ.get("AGC_ROOT", ".agc"))
server = MCPServer("agc", instructions=(
    "agc: an agentic compiler session for AMD MI355X (gfx950). Call open(manifest_path) first. States are immutable "
    "and addressed by id, tag or branch; `ref` is amdclang's build imported into machine IR (CDNA4 assembly). "
    "A manifest may also carry a tensor program: program() shows it and generate(template, params) compiles it "
    "straight into machine IR (no HIP involved). "
    "Three levels: source(text, launch) compiles a rewritten HIP source into a new state (restructure the kernel, change "
    "the launch); generate compiles a tensor program; edit / edit_ir / apply work on machine IR. "
    "Loop: state(ref) to read the numbered listing -> edit / edit_ir / apply to make a new state -> static_check "
    "(ISA legality, s_waitcnt, hazards, contract) -> check (battery on the GPU) -> bench (paired against ref; "
    "`win` only if the whole 95% CI is beyond the 1% noise floor). isa(mnemonic) and arch(section) answer questions "
    "about instructions and the machine. A refusal is a JSON object with `error`, `kind` (parse, parameter, unknown, "
    "static, unverified, verification, toolchain, gpu, internal) and usually `location`, `values`, `suggestion`."))
_session: Session | None = None


def _s() -> Session:
    if _session is None:
        raise SessionError("unknown", "no session: call open(manifest_path) first")
    return _session


def _dump(x: Any) -> str:
    return x if isinstance(x, str) else json.dumps(x, indent=1, default=str)


def _wrap(fn):
    @functools.wraps(fn)
    def inner(*a, **kw):
        try:
            return _dump(fn(*a, **kw))
        except SessionError as e:
            return _dump(e.to_dict())
        except Exception as e:  # noqa: BLE001  (reported to the agent, never a crash)
            return _dump({"error": f"{type(e).__name__}: {e}", "kind": "internal"})
    inner.__annotations__ = {**fn.__annotations__, "return": str}
    return inner


def tool(fn):
    return server.tool()(_wrap(fn))


@tool
def open(manifest_path: str, quick: bool = False) -> dict:
    """Open (or resume) the session of a manifest: builds the HIP source with amdclang -O3, imports its assembly as
    state `ref`. quick=True uses one battery case per shape variant (smoke tests; results are marked quick)."""
    global _session
    _session = Session.open(manifest_path, ROOT, quick=quick)
    return _session.info()


@tool
def info() -> dict:
    """The contract: parameters, shapes, launch, tolerances, timing protocol, tags, transforms."""
    return _s().info()


@tool
def state(ref: str = "ref", include_ir: bool = True) -> dict:
    """A state: its action, parent, children, what is known about it (static / check / bench), and the kernel body
    as a numbered listing (`label:` lines and `[index] instruction`), which is how `edit` addresses instructions."""
    return _s().state(ref, include_ir)


@tool
def list_states() -> list:
    """Every state with its action and verdicts."""
    return _s().list_states()


@tool
def features(ref: str = "ref") -> dict:
    """Resources (registers, LDS, occupancy and its limiter) and the shape of the code (instruction classes, loops,
    waits, nop wait states, loads, stores)."""
    return _s().features(ref)


@tool
def actions(ref: str = "ref") -> dict:
    """The action menu for a state: edits, named transforms with their parameters, validation steps."""
    return _s().actions(ref)


@tool
def edit(parent: str, ops: list, note: str = "") -> dict:
    """Structured edits → a new state. ops: [{"op": "replace"|"insert"|"delete", "block": label, "index": i,
    "text": "one instruction per line", "expect": "the instruction now at block[index]" (optional, checked)}].
    `insert` places text before index (index == block length appends). Addresses refer to the parent's listing."""
    return _s().edit(parent, ops, note)


@tool
def edit_ir(parent: str, ir: str, note: str = "", launch: dict | None = None) -> dict:
    """Replace the whole kernel body with `ir` (instructions and `label:` lines, amdclang dialect; a numbered
    listing is accepted) → a new, unverified state. Register counts in the descriptor follow the code.
    `launch` (optional) changes how the state is launched: {"grid": [...], "block": [...], "lds": bytes,
    "args": [{"dtype": "u32", "value": "expression over the shape symbols"}]}; appended args get kernarg slots after
    the existing arguments (their offsets are returned in the state's action as `arg_offsets`)."""
    return _s().edit_ir(parent, ir, note, launch)


@tool
def source(text: str, launch: dict | None = None, note: str = "") -> dict:
    """The source level: compile a rewritten HIP source with amdclang (the baseline's flags) and import it as a new
    root state. Keep the entry name and the manifest's parameters in order; further parameters must be appended and
    supplied through launch["args"]. `launch` may change grid and block (expressions over the shape symbols, e.g.
    "cdiv(N, 1024)"). Includes resolve next to the manifest. The state is unverified: static_check, check, bench.
    Use this to restructure a kernel (several elements per thread, another work split, another block size), then
    refine the result at the machine level with edit / apply."""
    return _s().source(text, launch, note)


@tool
def hip_source() -> dict:
    """The manifest's HIP source text (the baseline) and its path."""
    m = _s().manifest
    if m.source is None:
        return {"error": "the manifest has no HIP source", "kind": "unknown"}
    return {"path": str(m.source), "text": Path(m.source).read_text()}


@tool
def relaunch(ref: str, launch: dict, note: str = "") -> dict:
    """The same code with another launch geometry → a new state (grid, block, lds, appended args)."""
    return _s().relaunch(ref, launch, note)


@tool
def report(best: str, summary: str, tried: list | None = None, friction: list | None = None) -> dict:
    """End of a session: name the state to ship (`ref` if nothing beat amdclang), summarize what was done, list what
    was tried with its measured outcome, and list friction: what was missing or awkward in the tools, transforms or
    IR, and what would have let you go further. The harness re-verifies the named state itself."""
    s = _s()
    sid = s.resolve(best)
    out = {"best": sid, "summary": summary, "tried": tried or [], "friction": friction or []}
    (s.store.root / "report.json").write_text(json.dumps(out, indent=1))
    return {"recorded": str(s.store.root / "report.json"), "best": sid}


@tool
def apply(ref: str, transform: str, params: dict | None = None) -> dict:
    """Apply a named transform (see `actions`) → a new state."""
    return _s().apply(ref, transform, params)


@tool
def program() -> dict:
    """The manifest's tensor program (tair text) and the schedule templates that can compile it, with their
    parameters (the knobs to search)."""
    return _s().program()


@tool
def generate(template: str | None = None, params: dict | None = None) -> dict:
    """Compile the tensor program straight into machine IR with a template (default: the first that matches) → a new
    state with its own launch geometry. No HIP source is used; `bench` then compares with amdclang's build of the HIP
    source when the manifest has one."""
    return _s().generate(template, params)


@tool
def static_check(ref: str) -> dict:
    """ISA verifier, kernel contract, undefined reads, s_waitcnt checker, hazard checker, encode + decode cross-check.
    Each finding has a kind, block, index, instruction and a message that says what is needed."""
    return _s().static_check(ref)


@tool
def check(ref: str) -> dict:
    """The battery on the GPU: several input distributions, hidden seeds, shape variants, poisoned outputs, compared
    with the reference program. Refused for a state that fails static_check."""
    return _s().check(ref)


@tool
def bench(ref: str) -> dict:
    """Paired timing against `ref` (amdclang) at the bench shapes: both code objects alternate in one process;
    speedup with a 95% CI; outcome win / parity / loss (beyond the 1% noise floor). Needs a passing battery;
    for `ref` itself it is the A/A control."""
    return _s().bench(ref)


@tool
def asm_diff(a: str, b: str) -> dict:
    """Unified diff of two states' kernel bodies with the change in instruction counts, registers and occupancy."""
    return _s().asm_diff(a, b)


@tool
def trace(ref: str) -> list:
    """The chain of actions from `ref` (amdclang) to this state, with each step's verdicts."""
    return _s().trace(ref)


@tool
def best() -> dict:
    """The verified state with the best measured win so far (or none)."""
    return _s().best() or {"best": None}


@tool
def tag(ref: str, name: str) -> dict:
    """Name a state."""
    return _s().tag(ref, name)


@tool
def fork(ref: str, name: str, note: str = "") -> dict:
    """Start a branch (a named movable head with a history) at a state."""
    return _s().fork(ref, name, note)


@tool
def checkpoint(ref: str, branch: str) -> dict:
    """Move a branch head forward to a descendant state."""
    return _s().checkpoint(ref, branch)


@tool
def rollback(branch: str, steps: int = 1) -> dict:
    """Move a branch head back by `steps` checkpoints."""
    return _s().rollback(branch, steps)


@tool
def note(ref: str, text: str = "") -> dict:
    """Attach a note to a state (what was tried, what was learned); empty text reads the notes."""
    return _s().note(ref, text)


@tool
def isa(mnemonic: str) -> dict:
    """An instruction from AMD's CDNA4 specification: description, class, and for each encoding the operands in
    assembly order (field, type, bits, in/out) plus implicit operands. Accepts LLVM suffixes (_e32, _e64, _dpp, _sdwa);
    without an exact match, returns the names containing the text."""
    t = table()
    r = t.resolve(mnemonic) or (t.resolve(mnemonic + "_e32") if mnemonic in t else None)
    if r is None and mnemonic in t:
        ins, encs = t.instruction(mnemonic), t.instruction(mnemonic).encodings
    elif r is None:
        hits = [n for n in t.names() if mnemonic.lower() in n][:60]
        return {"error": f"no instruction {mnemonic!r}", "kind": "unknown", "values": {"similar": hits}}
    else:
        ins, encs = r[0], r[2] if t.resolve(mnemonic) else r[0].encodings
    main = ("v", "a", "s", "const", "literal", "vcc", "exec", "m0", "scc")

    def operand(o):
        accepts = [c for c in main if c in t.type_classes(o.type)]
        return f"{o.field or '-'}: {o.size} bits {'in' * o.is_in}{'out' * o.is_out}, accepts {'/'.join(accepts) or o.type[4:].lower()}"
    return {"name": ins.name, "group": ins.group, "subgroups": list(ins.subgroups), "flags": sorted(ins.flags),
            "description": ins.desc,
            "encodings": [{"encoding": e.enc, "condition": e.cond, "operands": [operand(o) for o in e.explicit],
                           "implicit": [f"{o.type[4:].lower()} {'in' * o.is_in}{'out' * o.is_out}" for o in e.implicit]}
                          for e in encs]}


@tool
def arch(section: str = "") -> dict:
    """Machine facts from agc/arch/gfx950.yaml, each with its source: sections `resources`, `peaks`, `waitcnt`,
    `hazards` (wait states between producer and consumer), `mfma` (passes and MFMA hazard windows)."""
    data = load_arch(_session.manifest.arch if _session else "gfx950").data
    if not section:
        return {"sections": [k for k, v in data.items() if isinstance(v, dict)]}
    if section not in data or not isinstance(data[section], dict):
        return {"error": f"no section {section!r}", "kind": "unknown", "values": {"sections": [k for k, v in data.items() if isinstance(v, dict)]}}
    return data[section]


def main() -> None:
    server.run("stdio")


if __name__ == "__main__":
    main()
