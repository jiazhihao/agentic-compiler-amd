"""Memory accesses in `wir`: loads that need not happen, and adjacent accesses merged.

`forward_loads`: a load of an address already loaded or just stored in the same wave, with no
store in between that can overlap it, takes that value (LLVM: GVN and store-to-load forwarding).

`merge_accesses`, the decision `access.width`:

Two to four accesses of consecutive 32-bit elements with the same base and index become one wide
access (`global_load_dwordx2/x3/x4`): one address, one memory instruction, and for loads all the
data in flight under one wait. amdclang gets the same from its SLP vectorizer and
SILoadStoreOptimizer.

A load may move up to the first load of its group when no store in between can write what it reads;
a store may move down to the last store of its group when nothing in between reads or writes what
it writes. Two accesses with the same base and index and disjoint byte ranges do not overlap. Two
accesses based on different tensor arguments do not overlap either: every tensor of a manifest is
its own allocation (design D17; amdclang needs `__restrict__` to know it).
"""
from __future__ import annotations

from ..kir.ir import Const, Func, If, Loop, Namer, Op, Value, results, vec
from ..kir.passes import _dce
from ..wir import ops as wops
from .plan import Plan


def _key(x):
    return ("c", int(x.value)) if isinstance(x, Const) else ("v", id(x))


class _Access:
    def __init__(self, s: Op, roots: dict):
        self.s = s
        self.base, self.index = roots.get(id(s.args[0]), id(s.args[0])), _key(s.args[1])
        self.scale, self.off = s.attrs["scale"], s.attrs["off"]
        self.size = s.args[0].type.elem.size * s.attrs.get("n", 1)
        self.arg = roots.get(("arg", id(s.args[0])))

    def may_overlap(self, o: "_Access") -> bool:
        if self.s.args[0].type.is_lds != o.s.args[0].type.is_lds:
            return False                                  # shared memory and a global tensor
        if self.base == o.base and self.index == o.index and self.scale == o.scale:
            return self.off < o.off + o.size and o.off < self.off + self.size
        if self.arg is not None and o.arg is not None and self.arg != o.arg:
            return False                                  # two tensors of the manifest
        return True


def arg_roots(w: Func) -> dict:
    """Which pointers are the same base retyped or offset, and which tensor argument each comes from: a
    pointer computed from an argument (`ptradd`, `bitcast`) points into that argument's tensor."""
    roots: dict = {}
    for _ in range(8):                                     # merged and carried pointers: until nothing changes
        before = len(roots)
        for s in w.walk():
            if isinstance(s, Op) and s.result is not None and s.result.type.is_ptr:
                if s.name in ("arg", "region"):
                    roots[("arg", id(s.result))] = id(s.result)
                elif s.name in ("bitcast", "ptradd", "select") and isinstance(s.args[-2 if s.name == "select" else 0], Value):
                    srcs = s.args[1:] if s.name == "select" else s.args[:1]
                    if s.name == "bitcast":
                        roots[id(s.result)] = roots.get(id(srcs[0]), id(srcs[0]))
                    tensors = {roots.get(("arg", id(x))) for x in srcs}
                    if len(tensors) == 1 and None not in tensors:
                        roots[("arg", id(s.result))] = tensors.pop()
            elif isinstance(s, If):
                for m in s.merges:                         # a pointer into the same tensor on both sides
                    tensors = {roots.get(("arg", id(x))) for x in (m.a, m.b)}
                    if m.result.type.is_ptr and len(tensors) == 1 and None not in tensors:
                        roots[("arg", id(m.result))] = tensors.pop()
            elif isinstance(s, Loop):
                for c, i, n, o in zip(s.carried, s.init, s.next, s.out):
                    if c.type.is_ptr and roots.get(("arg", id(i))) is not None:
                        root = roots[("arg", id(i))]
                        if roots.get(("arg", id(n)), root) == root:
                            roots[("arg", id(c))] = roots[("arg", id(o))] = root
        if len(roots) == before:
            break
    return roots


def merge_accesses(w: Func, plan: Plan) -> Func:
    namer = Namer({v.name for s in w.walk() for v in results(s)})
    roots = arg_roots(w)

    def block(stmts: list) -> list:
        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = block(s.then), block(s.orelse)
            elif isinstance(s, Loop):
                s.head, s.body = block(s.head), block(s.body)
        return _stores(_loads(stmts))

    def mergeable(s) -> bool:
        return isinstance(s, Op) and s.attrs.get("n", 1) == 1 and s.args[0].type.elem.size == 4 and not s.args[0].type.elem.is_bool

    def scalar(a: _Access) -> bool:
        return a.s.name == "load" and a.s.result.kind == "u"

    def group(cands: list[_Access]) -> list[list[_Access]]:
        """Runs of accesses at consecutive offsets with one base, index, scale and element type."""
        out, used = [], set()
        for a in cands:
            if id(a) in used:
                continue
            run = [a]
            while len(run) < (16 if scalar(a) else 4):
                nxt = next((c for c in cands if id(c) not in used and c is not a and c not in run and c.base == a.base
                            and c.index == a.index and c.scale == a.scale and scalar(c) == scalar(a)
                            and c.s.args[0].type == a.s.args[0].type and c.off == run[-1].off + 4), None)
                if nxt is None:
                    break
                run.append(nxt)
            if len(run) > 1:
                out.append(run)
                used.update(id(c) for c in run)
        return out

    def limit(run: list[_Access]) -> list[_Access]:
        """As many of the run as the decision allows and one access can hold (a scalar load: 2, 4, 8 or 16)."""
        allowed = (16, 8, 4, 2) if scalar(run[0]) else (4, 3, 2)
        width = plan.choose(run[0].s.site or "access", "access.width", [16, 8, 4, 2, 1] if scalar(run[0]) else [4, 2, 1])
        n = next((k for k in allowed if k <= width and k <= len(run)), 0)
        return run[:n]

    def _loads(stmts: list) -> list:
        pos = {id(s): i for i, s in enumerate(stmts)}
        loads = [_Access(s, roots) for s in stmts if isinstance(s, Op) and s.name == "load" and mergeable(s)]
        loads.sort(key=lambda a: (pos[id(a.s)]))
        drop, insert = set(), {}
        for run in group(sorted(loads, key=lambda a: a.off)):
            run.sort(key=lambda a: a.off)
            first = min(run, key=lambda a: pos[id(a.s)])
            ok = []
            for a in run:                                 # each member must be movable up to the first one
                between = stmts[pos[id(first.s)] + 1:pos[id(a.s)]]
                if all(_safe_for_load(x, a, roots) for x in between):
                    ok.append(a)
                else:
                    break
            if len(ok) < 2 or ok[0].off != run[0].off:
                continue
            ok = limit(ok)
            if len(ok) < 2:
                continue
            lead = ok[0].s
            wide = Value(namer.fresh("w"), vec(lead.result.type, len(ok)), lead.result.kind)
            new = [Op("load", list(lead.args), wide, {**lead.attrs, "n": len(ok)}, lead.site, lead.loc)]
            new += [Op("extract", [wide], a.s.result, {"i": i}) for i, a in enumerate(ok)]
            insert[id(first.s)] = new
            drop.update(id(a.s) for a in ok)
        out = []
        for s in stmts:
            if id(s) in insert:
                out += insert[id(s)]
            if id(s) not in drop:
                out.append(s)
        return out

    def _stores(stmts: list) -> list:
        pos = {id(s): i for i, s in enumerate(stmts)}
        stores = [_Access(s, roots) for s in stmts if isinstance(s, Op) and s.name == "store" and mergeable(s)]
        drop, insert = set(), {}
        for run in group(sorted(stores, key=lambda a: a.off)):
            last = max(run, key=lambda a: pos[id(a.s)])
            ok = []
            for a in run:                                 # each member must be movable down to the last one
                between = stmts[pos[id(a.s)] + 1:pos[id(last.s)]]
                if all(_safe_for_store(x, a, roots, run) for x in between):
                    ok.append(a)
                else:
                    break
            if len(ok) < 2:
                continue
            ok = limit(ok)
            if len(ok) < 2:
                continue
            end = max(ok, key=lambda a: pos[id(a.s)])
            lead = ok[0].s
            packed = Value(namer.fresh("w"), vec(lead.args[2].type, len(ok)), "v")
            insert[id(end.s)] = [Op("pack", [a.s.args[2] for a in ok], packed),
                                 Op("store", [lead.args[0], lead.args[1], packed], None, {**lead.attrs, "n": len(ok)}, lead.site, lead.loc)]
            drop.update(id(a.s) for a in ok)
        out = []
        for s in stmts:
            if id(s) in insert:
                out += insert[id(s)]
            if id(s) not in drop:
                out.append(s)
        return out

    w.body = block(w.body)
    _dce(w)
    from ..wir.verify import assert_ok
    return assert_ok(w)


def _safe_for_load(x, a: _Access, roots: dict) -> bool:
    """Moving load `a` above statement `x` does not change what it reads."""
    if isinstance(x, (If, Loop)):
        return False                                      # a region may store anything
    if x.name == "barrier" and a.s.args[0].type.is_lds:
        return False                                      # other waves' stores become visible at the barrier
    if x.name == "store":
        return not _Access(x, roots).may_overlap(a)
    return True


def _safe_for_store(x, a: _Access, roots: dict, run: list) -> bool:
    """Moving store `a` below statement `x` changes neither what `x` reads nor the final memory."""
    if isinstance(x, (If, Loop)):
        return False
    if x.name == "barrier" and a.s.args[0].type.is_lds:
        return False                                      # the other waves must see the store before they continue
    if x.name in ("load", "store"):
        if any(x is r.s for r in run):
            return True                                   # the group's own stores: disjoint
        return not _Access(x, roots).may_overlap(a)
    return True


def forward_loads(w: Func) -> Func:
    """Remove loads whose value is already in a register: an earlier load of the same address, or
    the value an earlier store wrote there, when no store in between can overlap."""
    roots = arg_roots(w)
    subst: dict[int, object] = {}

    def r(x):
        while isinstance(x, Value) and id(x) in subst:
            x = subst[id(x)]
        return x

    def stores_in(stmts) -> list[_Access]:
        from ..kir.ir import walk
        return [_Access(x, roots) for x in walk(stmts) if isinstance(x, Op) and x.name == "store"]

    def kill(avail: dict, accesses: list[_Access]) -> None:
        for k in [k for k, (a, _) in avail.items() if any(a.may_overlap(st) for st in accesses)]:
            del avail[k]

    def block(stmts: list, avail: dict) -> list:
        out = []
        for s in stmts:
            if isinstance(s, Op):
                s.args = [r(a) for a in s.args]
                if s.name == "barrier":                       # other waves run: nothing known about shared memory survives
                    for k in [k for k, (a, _) in avail.items() if a.s.args[0].type.is_lds]:
                        del avail[k]
                elif s.name in ("load", "store") and s.args[0].type.is_lds:
                    pass                                     # LDS is shared with other lanes and waves: never forwarded
                elif s.name in ("load", "store") and s.attrs.get("n", 1) == 1:
                    a = _Access(s, roots)
                    key = (a.base, a.index, a.scale, a.off, str(s.args[0].type.elem))
                    if s.name == "load":
                        if key in avail:
                            subst[id(s.result)] = avail[key][1]
                            continue
                        avail[key] = (a, s.result)
                    else:
                        kill(avail, [a])
                        avail[key] = (a, s.args[2])
                elif s.name == "store":
                    kill(avail, [_Access(s, roots)])
                out.append(s)
            elif isinstance(s, If):
                s.cond = r(s.cond)
                s.then = block(s.then, dict(avail))
                s.orelse = block(s.orelse, dict(avail))
                for m in s.merges:
                    m.a, m.b = r(m.a), r(m.b)
                kill(avail, stores_in(s.then) + stores_in(s.orelse))
                out.append(s)
            else:
                kill(avail, stores_in(s.head) + stores_in(s.body))
                s.init = [r(x) for x in s.init]
                s.head = block(s.head, dict(avail))
                s.cond = r(s.cond)
                s.body = block(s.body, dict(avail))
                s.next = [r(x) for x in s.next]
                out.append(s)
        return out

    w.body = block(w.body, {})
    _dce(w)
    from ..wir.verify import assert_ok
    return assert_ok(w)
