"""Ordering of loads (`wir` → `wir`): the decisions `loop.inflight` (per loop) and `order.loads`
(the code outside loops).

`first` (the default: amdclang's scheduler clusters the loads of a block too): the loads of a
straight-line run, with the address arithmetic they need, move to the top of the run, ahead of the
arithmetic that consumes them. Waits are placed at the first use of a
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
            taken[base] = plan.choose(base, "loop.inflight", ["first", "as_written"])
        return taken[base]

    outside = plan.choose("kernel", "order.loads", ["first", "as_written"]) == "first"

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

    def go(stmts: list, first: bool) -> list:
        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = go(s.then, first), go(s.orelse, first)
            elif isinstance(s, Loop):
                inner = choice(s.site) == "first"
                s.head = go(s.head, False)
                s.body = go(s.body, inner)
        return reorder(stmts) if first else stmts

    w.body = go(w.body, outside)
    return w


def _run(ops: list[Op], roots: dict) -> list[Op]:
    defs = {id(o.result): o for o in ops if o.result is not None}
    stores: list[_Access] = []
    blocked: set[int] = set()                              # loads that follow a store they may read
    barrier = False
    for o in ops:
        if o.name == "store":
            stores.append(_Access(o, roots))
        elif o.name == "barrier":
            barrier = True                                 # what other waves stored is visible only after it
        elif o.name == "load" and (any(_Access(o, roots).may_overlap(st) for st in stores) or (barrier and o.args[0].type.is_lds)):
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
