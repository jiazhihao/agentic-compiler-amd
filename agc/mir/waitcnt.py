"""The waitcnt checker: no instruction may touch a register (or LDS contents) that a memory
operation is still going to write, and no barrier may be reached with memory operations
outstanding.

Counters on gfx950: `vmcnt` counts vector memory operations (loads and stores, in order);
`lgkmcnt` counts LDS operations (in order) and scalar loads, which can return out of order, so
while a scalar load is outstanding only `lgkmcnt(0)` proves anything about that counter.

The analysis is a forward dataflow over the CFG. For every pending destination it keeps the
largest counter value `n` such that `s_waitcnt cnt(n)` proves the operation complete: 0 for the
newest operation, growing by one with each later operation on the same counter.
"""
from __future__ import annotations

from ..arch.model import Arch, load as load_arch
from ..isa import Isa, table
from .analysis import Cfg, Info, cfg
from .ir import Call, Imm, Kernel

COUNTERS = ("vmcnt", "lgkmcnt", "expcnt")


class State:
    __slots__ = ("pending", "out", "ooo")

    def __init__(self):
        self.pending = {c: {} for c in COUNTERS}       # counter -> {unit: n}
        self.out = {c: 0 for c in COUNTERS}            # upper bound of outstanding operations
        self.ooo = {c: False for c in COUNTERS}        # an out-of-order operation is outstanding

    def copy(self) -> "State":
        s = State()
        s.pending = {c: dict(p) for c, p in self.pending.items()}
        s.out, s.ooo = dict(self.out), dict(self.ooo)
        return s

    def join(self, other: "State") -> bool:
        """Merge `other` in (the conservative union); True if this state changed."""
        changed = False
        for c in COUNTERS:
            mine = self.pending[c]
            for u, n in other.pending[c].items():
                if u not in mine or n < mine[u]:
                    mine[u], changed = n, True
            if other.out[c] > self.out[c]:
                self.out[c], changed = other.out[c], True
            if other.ooo[c] and not self.ooo[c]:
                self.ooo[c], changed = True, True
                for u in mine:
                    mine[u] = 0
        return changed


def wait_values(info: Info, limits: dict) -> dict:
    """Counter values an `s_waitcnt` waits for; counters it does not name are not waited on."""
    vals = {}
    for op in info.inst.operands:
        if isinstance(op, Call) and op.name in COUNTERS:
            vals[op.name] = int(op.args[0])
        elif isinstance(op, Imm):                        # the raw 16-bit operand
            v = int(op.value)
            vals = {"vmcnt": (v & 0xF) | ((v >> 14) & 0x3) << 4, "expcnt": (v >> 4) & 0x7, "lgkmcnt": (v >> 8) & 0xF}
            vals = {c: n for c, n in vals.items() if n < limits[c]}
    return vals


def event(info: Info):
    """(counter, destination units, out_of_order) of a memory operation, or None."""
    if info.smem and (info.load or info.store):
        return "lgkmcnt", info.defs, True
    if info.ds:
        return "lgkmcnt", frozenset(u for u in info.defs if u[0] in ("v", "a")), False
    if info.vmem and (info.load or info.store or info.lds_dma):
        return "vmcnt", frozenset(u for u in info.defs if u[0] in ("v", "a", "lds")), False
    return None


def _fmt(u) -> str:
    return "LDS contents" if u[0] == "lds" else f"{u[0]}{u[1]}" if u[0] in ("v", "s", "a") else u[0]


def step(state: State, info: Info, limits: dict, report=None) -> None:
    """Advance `state` over one instruction; `report(counter, unit, n, message)` on a violation."""
    name = info.name
    if name == "s_waitcnt":
        for c, w in wait_values(info, limits).items():
            state.pending[c] = {u: n for u, n in state.pending[c].items() if n < w}
            state.out[c] = min(state.out[c], w)
            if w == 0:
                state.ooo[c] = False
        return
    touched = info.uses | info.defs
    for c in COUNTERS:
        hit = [u for u in state.pending[c] if u in touched]
        for u in sorted(hit):
            n = state.pending[c].pop(u)
            if report:
                verb = "reads" if u in info.uses else "overwrites"
                report(c, u, n, f"{verb} {_fmt(u)} before the memory operation that writes it has completed: "
                                f"needs `s_waitcnt {c}({n})` first")
    if name == "s_barrier":
        for c in COUNTERS:
            if state.out[c] > 0 and report:
                report(c, None, 0, f"barrier with memory operations outstanding: needs `s_waitcnt {c}(0)` first")
            state.pending[c], state.out[c], state.ooo[c] = {}, 0, False
        return
    ev = event(info)
    if ev:
        c, dsts, ooo = ev
        state.ooo[c] = state.ooo[c] or ooo
        if state.ooo[c]:
            state.pending[c] = {u: 0 for u in state.pending[c]}
        else:
            state.pending[c] = {u: n + 1 for u, n in state.pending[c].items()}
        for u in dsts:
            state.pending[c][u] = 0
        state.out[c] = min(state.out[c] + 1, limits[c])


def analyze(g: Cfg, arch: Arch | None = None):
    """Block-entry states at the fixed point."""
    arch = arch or load_arch()
    limits = {c: arch[f"waitcnt.{c}"] for c in COUNTERS}
    states = [None] * g.nblocks
    states[0] = State()
    work = [0]
    while work:
        b = work.pop()
        s = states[b].copy()
        for info in g.infos[b]:
            step(s, info, limits)
        for nxt in g.succ[b]:
            if states[nxt] is None:
                states[nxt] = s.copy()
                work.append(nxt)
            elif states[nxt].join(s):
                work.append(nxt)
    return states, limits


def check(k: Kernel, g: Cfg | None = None, arch: Arch | None = None) -> list[dict]:
    g = g or cfg(k)
    states, limits = analyze(g, arch)
    findings = []
    for b, block in enumerate(g.infos):
        if states[b] is None:
            continue
        s = states[b].copy()
        for i, info in enumerate(block):
            def report(c, u, n, message, b=b, i=i, info=info):
                findings.append({"kind": "waitcnt", "kernel": k.name, "block": k.blocks[b].label, "index": i,
                                 "inst": str(info.inst), "counter": c, "needs": n, "message": message})
            step(s, info, limits, report)
    return findings
