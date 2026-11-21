"""Loops in `kir`: recognizing counted loops and unrolling them.

A counted loop is `for (iv = start; iv < stop; iv += step)` with a signed 32-bit `iv`, a constant
`start >= 0`, a constant `step > 0` and a `stop` computed outside the loop. The condition may also be
`base + iv < stop` with a non-negative `base` computed outside the loop (a thread's own offset: each
thread then has its own trip count, and the unrolled loop is a loop under a mask). `unroll(f, site, n)`
turns it into a main loop that runs `n` iterations at a time while at least `n` remain, followed by
the original loop for the remainder. The operations stay in the order of the source, so results
are bit-identical; what changes is that one trip of the main loop holds the work of `n` iterations,
which lets their loads be issued together (the decisions `loop.unroll` and `loop.inflight`).
"""
from __future__ import annotations

from dataclasses import dataclass

from .ir import Const, Func, I1, If, Loop, Namer, Op, Type, Value, operands, results, walk
from .ops import BUILTINS
from .passes import _namer, clone, simplify


@dataclass
class Counted:
    index: int                   # which carried value is the induction variable
    iv: Value
    start: int | None            # the constant the counter starts at; None: a non-negative value such as a thread index
    step: int
    stop: object                 # operand defined outside the loop
    increment: Op
    base: object = None          # the condition is `base + iv < stop` (None: `iv < stop`)


def defined_in(loop: Loop) -> set[int]:
    inside = {id(c) for c in loop.carried}
    for s in walk(loop.head + loop.body):
        inside.update(id(v) for v in results(s))
    return inside


def counted(loop: Loop, defs: dict | None = None) -> Counted | str:
    """The loop's counter, or the reason it is not a counted loop. `defs` (value → defining operation
    of the function) lets an offset in the condition be recognized as non-negative."""
    inside = defined_in(loop)
    cond = next((s for s in loop.head if isinstance(s, Op) and s.result is loop.cond), None)
    if cond is None or cond.name != "lt":
        return "the loop condition is not `iv < stop` computed at the top of the loop"
    iv, stop = cond.args
    base = None
    if isinstance(iv, Value) and not any(iv is c for c in loop.carried):
        d = next((s for s in loop.head if isinstance(s, Op) and s.result is iv), None)
        if d is not None and d.name == "add" and d.attrs.get("nsw"):
            for x, y in ((d.args[0], d.args[1]), (d.args[1], d.args[0])):
                if any(y is c for c in loop.carried) and (isinstance(x, Const) or id(x) not in inside):
                    if not nonneg(x, defs or {}):
                        return "the offset added to the counter in the loop condition is not known to be non-negative"
                    iv, base = y, x
                    break
    if not isinstance(iv, Value) or not any(iv is c for c in loop.carried):
        return "the left side of the loop condition is not a loop-carried counter (or an outside offset plus one)"
    if isinstance(stop, Value) and id(stop) in inside:
        return "the bound of the loop changes inside the loop"
    t = iv.type
    if not (t.is_int and t.signed and t.bits == 32):
        return f"the counter is {t}; only signed 32-bit counters are unrolled"
    i = next(k for k, c in enumerate(loop.carried) if c is iv)
    nxt = loop.next[i]
    inc = next((s for s in walk(loop.body) if isinstance(s, Op) and s.result is nxt), None)
    top_level = any(s is inc for s in loop.body)
    if inc is None or inc.name != "add" or inc.args[0] is not iv or not isinstance(inc.args[1], Const) or not top_level:
        return "the counter is not advanced by a constant once per iteration"
    step = int(inc.args[1].value)
    start = loop.init[i]
    if step <= 0:
        return "the counter does not count up"
    if isinstance(start, Const):
        if not 0 <= int(start.value) <= 1 << 16:
            return "the counter does not start at a small non-negative constant"
    elif not nonneg(start, defs or {}):
        return "the counter does not start at a value known to be non-negative (a constant or a thread index)"
    return Counted(i, iv, int(start.value) if isinstance(start, Const) else None, step, stop, inc, base)


def nonneg(x, defs: dict, depth: int = 0) -> bool:
    """Whether a signed integer is known to be at least 0: a thread, block or grid index, a non-negative
    constant, or a non-wrapping sum or product of such."""
    if isinstance(x, Const):
        return int(x.value) >= 0
    d = defs.get(id(x))
    if d is None or depth > 8:
        return False
    if d.name in BUILTINS:
        return True
    if d.name == "cast" and d.args[0].type.is_int:
        src = d.args[0].type
        if d.name == "cast" and isinstance(d.args[0], Value) and defs.get(id(d.args[0])) is not None \
                and defs[id(d.args[0])].name in BUILTINS:
            return True                                    # an index of the launch: far below 2^31
        return src.bits <= d.result.type.bits and nonneg(d.args[0], defs, depth + 1) if src.signed else src.bits < d.result.type.bits
    if d.name in ("add", "mul") and d.attrs.get("nsw"):
        return all(nonneg(a, defs, depth + 1) for a in d.args)
    if d.name in ("and",):
        return any(nonneg(a, defs, depth + 1) for a in d.args)
    return False


class UnrollError(ValueError):
    pass


def find_loop(f: Func, site: str) -> tuple[list, int, Loop]:
    def go(stmts):
        for i, s in enumerate(stmts):
            if isinstance(s, Loop) and s.site == site:
                return stmts, i, s
            for sub in ((s.then, s.orelse) if isinstance(s, If) else (s.head, s.body) if isinstance(s, Loop) else ()):
                r = go(sub)
                if r:
                    return r
        return None

    r = go(f.body)
    if r is None:
        raise UnrollError(f"no loop {site!r}")
    return r


def unroll(f: Func, site: str, factor: int) -> Func:
    """Unroll the counted loop at `site` by `factor` (a main loop, then the original for the remainder)."""
    if factor < 2:
        return f
    stmts, at, loop = find_loop(f, site)
    c = counted(loop, {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None})
    if isinstance(c, str):
        raise UnrollError(f"{site}: {c}")
    if any(isinstance(s, Loop) for s in walk(loop.body)):
        raise UnrollError(f"{site}: the loop contains another loop")
    namer = _namer(f)
    t = c.iv.type
    main = Loop(site=f"{site}.x{factor}", loc=loop.loc)
    main.init = list(loop.init)
    main.carried = [Value(namer.fresh(v.name), v.type) for v in loop.carried]
    main.out = [Value(namer.fresh(v.name), v.type) for v in loop.carried]
    # the main loop runs while at least `factor` iterations remain: stop - iv > (factor - 1) * step, with
    # `stop` clamped at 0 so that the subtraction cannot overflow (the counter starts at a constant >= 0)
    stop0 = Value(namer.fresh("stop"), t)
    pre = [Op("max", [c.stop, Const(0, t)], stop0)]
    if c.base is not None:                                 # base + iv < stop is iv < max(stop, 0) - base, clamped at 0
        own, own0 = Value(namer.fresh("stop"), t), Value(namer.fresh("stop"), t)
        pre += [Op("sub", [stop0, c.base], own, {"nsw": True}), Op("max", [own, Const(0, t)], own0)]
        stop0 = own0
    left = Value(namer.fresh("left"), t)
    more = Value(namer.fresh("more"), I1)
    main.head = [Op("sub", [stop0, main.carried[c.index]], left, {"nsw": True}),
                 Op("gt", [left, Const((factor - 1) * c.step, t)], more)]
    main.cond = more
    cur = list(main.carried)
    for k in range(factor):
        mapping = {id(old): new for old, new in zip(loop.carried, cur)}
        copy = clone(loop.head, mapping, namer, fold=False) + clone(loop.body, mapping, namer, fold=False)
        for s in walk(copy):                               # the copies are one site each
            if s.site:
                s.site = f"{s.site}.{k}"
        main.body += copy
        cur = [mapping.get(id(n), n) if isinstance(n, Value) else n for n in loop.next]
    main.next = cur
    loop.init = list(main.out)
    stmts[at:at] = pre + [main]
    return simplify(f)
