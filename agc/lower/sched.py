"""Ordering within a loop body (`wir` → `wir`): the decision `loop.inflight`.

`first`: the loads of one trip of the loop, with the address arithmetic they need, move to the top
of the body, ahead of the arithmetic that consumes them. Waits are placed at the first use of a
loaded value, so all of those loads are then in flight under one wait: the loop runs at the rate
memory delivers data instead of at one round trip per load. The arithmetic keeps its order, so the
result is bit-identical. A load does not move above a store that may write what it reads.
"""
from __future__ import annotations

from ..kir.ir import Func, If, Loop, Op, Value, walk
from ..kir.passes import HOISTABLE
from .plan import Plan
from .widen import _Access, arg_roots


def loads_first(w: Func, plan: Plan) -> Func:
    roots = arg_roots(w)
    taken: dict[str, str] = {}

    def choice(site: str | None) -> str:
        base = (site or "loop").split(".x")[0]             # the main loop of an unrolled loop and its remainder: one site
        if base not in taken:
            taken[base] = plan.choose(base, "loop.inflight", ["as_written", "first"])
        return taken[base]

    def reorder(stmts: list) -> list:
        """Each run of operations between regions, with its movable loads first."""
        out, run = [], []

        def flush():
            if run:
                out.extend(_run(run, roots))
                run.clear()

        for s in stmts:
            if isinstance(s, Op):
                run.append(s)
            else:
                flush()
                out.append(s)
        flush()
        return out

    def go(stmts: list) -> None:
        for s in stmts:
            if isinstance(s, If):
                go(s.then), go(s.orelse)
            elif isinstance(s, Loop):
                go(s.head), go(s.body)
                if choice(s.site) == "first":
                    s.body = reorder(s.body)

    go(w.body)
    return w


def _run(ops: list[Op], roots: dict) -> list[Op]:
    defs = {id(o.result): o for o in ops if o.result is not None}
    stores: list[_Access] = []
    blocked: set[int] = set()                              # loads that follow a store they may read
    for o in ops:
        if o.name == "store":
            stores.append(_Access(o, roots))
        elif o.name == "load" and any(_Access(o, roots).may_overlap(st) for st in stores):
            blocked.add(id(o))
    memo: dict[int, bool] = {}

    def movable(o: Op) -> bool:
        if id(o) not in memo:
            memo[id(o)] = False                            # a cycle cannot occur in SSA; this guards recursion
            ok = (o.name == "load" and id(o) not in blocked) or (o.name in HOISTABLE and o.result is not None)
            memo[id(o)] = ok and all(movable(defs[id(a)]) for a in o.args if isinstance(a, Value) and id(a) in defs)
        return memo[id(o)]

    first: set[int] = set()

    def need(o: Op) -> None:
        if id(o) in first:
            return
        first.add(id(o))
        for a in o.args:
            if isinstance(a, Value) and id(a) in defs:
                need(defs[id(a)])

    for o in ops:
        if o.name == "load" and movable(o):
            need(o)
    return [o for o in ops if id(o) in first] + [o for o in ops if id(o) not in first]
