"""`kir` → `kir` transformations. Each keeps the program's meaning exactly unless it says otherwise.

- `simplify`: constant folding, algebraic identities, branches on constants, common subexpressions,
  dead code.
- `unroll_constant_loops`: a loop whose trip count is a compile-time constant becomes straight-line
  code (what amdclang does to `for (j = 0; j < 2; ++j)`).
- `contract`: `a * b + c` becomes one `fma` (rounded once instead of twice). amdclang does this for
  HIP by default (`-ffp-contract=fast`); it is the decision `fp.contract`.
"""
from __future__ import annotations

import numpy as np

from .interp import InterpError, eval_op, np_dtype
from .ir import Const, Func, I1, If, Loop, Merge, Namer, Op, Type, Value, operands, walk
from .ops import BUILTINS, COMMUTATIVE, PURE


def fold_const(name: str, args: list[Const], t: Type) -> Const | None:
    """The constant an operation on constants computes, or None when it is not foldable."""
    if name in BUILTINS or name in ("gep", "load", "store") or any(a.type.is_ptr for a in args) or t.is_ptr:
        return None
    if name in ("div", "rem") and not args[1].type.is_float and args[1].value == 0:
        return None
    try:
        r = eval_op(name, [np.array(a.value, dtype=np_dtype(a.type)) for a in args], [a.type for a in args], t)
    except (InterpError, TypeError, ValueError, KeyError):
        return None
    r = np.asarray(r)
    return Const(bool(r) if t.is_bool else float(r) if t.is_float else int(r), t)


def _is(x, v) -> bool:
    return isinstance(x, Const) and not x.type.is_bool and x.value == v and not (x.type.is_float and v == 0 and str(x.value).startswith("-"))


def _identity(s: Op):
    """A simpler operand equal to the operation's result, or None."""
    n, a, t = s.name, s.args, s.result.type if s.result is not None else None
    if n in ("add", "or", "xor", "shl", "shr") and t.is_int and _is(a[1], 0):
        return a[0]
    if n in ("add", "or", "xor") and t.is_int and _is(a[0], 0):
        return a[1]
    if n == "sub" and t.is_int and _is(a[1], 0):
        return a[0]
    if n == "mul" and _is(a[1], 1):
        return a[0]
    if n == "mul" and _is(a[0], 1):
        return a[1]
    if n == "mul" and t.is_int and (_is(a[0], 0) or _is(a[1], 0)):
        return Const(0, t)
    if n == "div" and _is(a[1], 1):
        return a[0]
    if n in ("and", "or") and a[0] is a[1]:
        return a[0]
    if n in ("and", "or") and t.is_bool:
        for x, y in ((a[0], a[1]), (a[1], a[0])):
            if isinstance(x, Const):
                return y if bool(x.value) == (n == "and") else x
    if n == "select":
        if isinstance(a[0], Const):
            return a[1] if a[0].value else a[2]
        if a[1] is a[2] or (isinstance(a[1], Const) and a[1] == a[2]):
            return a[1]
    if n in ("cast", "bitcast") and a[0].type == t:
        return a[0]
    if n == "gep" and _is(a[1], 0):
        return a[0]
    return None


def _key(x):
    return ("c", x.value, str(x.type), str(x.value)) if isinstance(x, Const) else ("v", id(x))


def simplify(f: Func) -> Func:
    for _ in range(50):
        before = _count(f)
        subst: dict[int, object] = {}
        f.body = _rewrite(f.body, subst, {})
        _dce(f)
        if _count(f) == before and not subst:
            break
    return f


def _count(f: Func) -> int:
    return sum(1 for _ in f.walk())


def _rewrite(stmts: list, subst: dict, table: dict) -> list:
    def r(x):
        while isinstance(x, Value) and id(x) in subst:
            x = subst[id(x)]
        return x

    out = []
    for s in stmts:
        if isinstance(s, Op):
            s.args = [r(a) for a in s.args]
            if s.result is None:
                out.append(s)
                continue
            new = None
            if s.args and all(isinstance(a, Const) for a in s.args):
                new = fold_const(s.name, s.args, s.result.type)
            if new is None:
                new = _identity(s)
            if new is None and s.name in PURE:
                args = sorted(s.args, key=lambda a: repr(_key(a))) if s.name in COMMUTATIVE else s.args
                key = (s.name, tuple(_key(a) for a in args), str(s.result.type), tuple(sorted(s.attrs.items())))
                if key in table:
                    new = table[key]
                else:
                    table[key] = s.result
            if new is not None:
                subst[id(s.result)] = new
            else:
                out.append(s)
        elif isinstance(s, If):
            s.cond = r(s.cond)
            if isinstance(s.cond, Const):
                taken = s.then if s.cond.value else s.orelse
                out += _rewrite(taken, subst, table)
                for m in s.merges:
                    subst[id(m.result)] = r(m.a if s.cond.value else m.b)
                continue
            s.then = _rewrite(s.then, subst, dict(table))
            s.orelse = _rewrite(s.orelse, subst, dict(table))
            keep = []
            for m in s.merges:
                m.a, m.b = r(m.a), r(m.b)
                if m.a is m.b or (isinstance(m.a, Const) and m.a == m.b):
                    subst[id(m.result)] = m.a
                else:
                    keep.append(m)
            s.merges = keep
            out.append(s)
        else:
            s.init = [r(x) for x in s.init]
            inner = dict(table)
            s.head = _rewrite(s.head, subst, inner)
            s.cond = r(s.cond)
            s.body = _rewrite(s.body, subst, inner)
            s.next = [r(x) for x in s.next]
            if isinstance(s.cond, Const) and not s.cond.value:      # never runs
                for o, i in zip(s.out, s.init):
                    subst[id(o)] = i
                continue
            out.append(s)
    return out


def _dce(f: Func) -> None:
    """Remove operations whose result nothing reads, carried values nothing reads, empty regions."""
    for _ in range(100):
        used: set[int] = set()
        for s in f.walk():
            for x in operands(s):
                if isinstance(x, Value):
                    used.add(id(x))
        changed = [False]

        def prune(stmts: list) -> list:
            out = []
            for s in stmts:
                if isinstance(s, Op):
                    if s.result is not None and id(s.result) not in used and s.name != "store":
                        changed[0] = True
                        continue
                elif isinstance(s, If):
                    s.then, s.orelse = prune(s.then), prune(s.orelse)
                    n = len(s.merges)
                    s.merges = [m for m in s.merges if id(m.result) in used]
                    changed[0] |= len(s.merges) != n
                    if not s.then and not s.orelse and not s.merges:
                        changed[0] = True
                        continue
                else:
                    s.head, s.body = prune(s.head), prune(s.body)
                    inside = set()
                    for x in walk(s.head + s.body):
                        for o in operands(x):
                            if isinstance(o, Value):
                                inside.add(id(o))
                    if isinstance(s.cond, Value):
                        inside.add(id(s.cond))
                    # a carried value is needed when the loop reads it (other than to compute its own next
                    # value) or something after the loop reads its output
                    keep = [i for i, (c, o) in enumerate(zip(s.carried, s.out)) if id(o) in used or id(c) in inside]
                    if len(keep) != len(s.carried):
                        changed[0] = True
                        for name in ("carried", "init", "next", "out"):
                            setattr(s, name, [getattr(s, name)[i] for i in keep])
                out.append(s)
            return out

        f.body = prune(f.body)
        if not changed[0]:
            return


# ---- cloning ---------------------------------------------------------------------------------------
def clone(stmts: list, mapping: dict, namer: Namer, fold: bool = True) -> list:
    """A copy of `stmts` with fresh result values. `mapping` (id of a value → operand) gives the
    replacement of values defined outside and receives the copies' results. With `fold`, operations
    whose operands became constants are folded away."""
    def r(x):
        return mapping.get(id(x), x) if isinstance(x, Value) else x

    def new(v: Value) -> Value:
        n = Value(namer.fresh(v.name), v.type, v.kind)
        mapping[id(v)] = n
        return n

    out = []
    for s in stmts:
        if isinstance(s, Op):
            args = [r(a) for a in s.args]
            if fold and s.result is not None and args and all(isinstance(a, Const) for a in args):
                c = fold_const(s.name, args, s.result.type)
                if c is not None:
                    mapping[id(s.result)] = c
                    continue
            out.append(Op(s.name, args, new(s.result) if s.result is not None else None, dict(s.attrs), s.site, s.loc))
        elif isinstance(s, If):
            c = r(s.cond)
            if fold and isinstance(c, Const):
                out += clone(s.then if c.value else s.orelse, mapping, namer, fold)
                for m in s.merges:
                    mapping[id(m.result)] = r(m.a if c.value else m.b)
                continue
            n = If(c, clone(s.then, mapping, namer, fold), clone(s.orelse, mapping, namer, fold), [], s.mode, s.site, s.loc)
            n.merges = [Merge(new(m.result), r(m.a), r(m.b)) for m in [Merge(m.result, r(m.a), r(m.b)) for m in s.merges]]
            out.append(n)
        else:
            n = Loop(site=s.site, loc=s.loc)
            n.init = [r(x) for x in s.init]
            n.carried = [new(c) for c in s.carried]
            n.head = clone(s.head, mapping, namer, fold)
            n.cond = r(s.cond)
            n.body = clone(s.body, mapping, namer, fold)
            n.next = [r(x) for x in s.next]
            n.out = [new(o) for o in s.out]
            out.append(n)
    return out


def _namer(f: Func) -> Namer:
    names = {p.name for p in f.params}
    for s in f.walk():
        from .ir import results
        names.update(v.name for v in results(s))
    return Namer(names)


def unroll_constant_loops(f: Func, limit: int = 64) -> Func:
    """Replace every loop that provably runs a constant number of iterations (at most `limit`) by
    its iterations in sequence."""
    namer = _namer(f)
    subst: dict[int, object] = {}

    def r(x):
        while isinstance(x, Value) and id(x) in subst:
            x = subst[id(x)]
        return x

    def go(stmts: list) -> list:
        out = []
        for s in stmts:
            if isinstance(s, Op):
                s.args = [r(a) for a in s.args]
                out.append(s)
            elif isinstance(s, If):
                s.cond = r(s.cond)
                s.then, s.orelse = go(s.then), go(s.orelse)
                for m in s.merges:
                    m.a, m.b = r(m.a), r(m.b)
                out.append(s)
            else:
                s.init = [r(x) for x in s.init]
                flat = _unroll(s, namer, limit, r)
                if flat is None:
                    s.head, s.body = go(s.head), go(s.body)
                    s.cond, s.next = r(s.cond), [r(x) for x in s.next]
                    out.append(s)
                else:
                    stmts2, outs = flat
                    for o, v in zip(s.out, outs):
                        subst[id(o)] = v
                    out += go(stmts2)
        return out

    f.body = go(f.body)
    return simplify(f)


def _unroll(s: Loop, namer: Namer, limit: int, r) -> tuple[list, list] | None:
    cur = list(s.init)
    out: list = []
    for _ in range(limit + 1):
        mapping = {id(c): v for c, v in zip(s.carried, cur)}
        head = clone(s.head, mapping, namer)
        cond = mapping.get(id(s.cond), s.cond) if isinstance(s.cond, Value) else s.cond
        cond = r(cond)
        if not isinstance(cond, Const):
            return None
        if not cond.value:
            return out, cur
        out += head + clone(s.body, mapping, namer)
        cur = [mapping.get(id(n), n) if isinstance(n, Value) else n for n in s.next]
    return None


def contract(f: Func) -> Func:
    """`a * b + c` → `fma(a, b, c)`; `a * b - c` → `fma(a, b, -c)`; `c - a * b` → `fma(-a, b, c)`,
    whether or not the product has other uses (LLVM's AMDGPU backend fuses aggressively)."""
    defs: dict[int, Op] = {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None}
    namer = _namer(f)

    def mul(x):
        d = defs.get(id(x)) if isinstance(x, Value) else None
        return d if d is not None and d.name == "mul" and d.result.type.is_float else None

    def go(stmts: list) -> list:
        out = []
        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = go(s.then), go(s.orelse)
            elif isinstance(s, Loop):
                s.head, s.body = go(s.head), go(s.body)
            elif s.name in ("add", "sub") and s.result.type.is_float:
                a, b = s.args
                t = s.result.type
                ma, mb = mul(a), mul(b)

                def neg(x):
                    if isinstance(x, Const):
                        return Const(-x.value, x.type)
                    v = Value(namer.fresh("neg"), t)
                    out.append(Op("neg", [x], v, loc=s.loc))
                    return v

                if s.name == "add" and (ma or mb):
                    m, c = (ma, b) if ma else (mb, a)
                    s.name, s.args = "fma", [m.args[0], m.args[1], c]
                elif s.name == "sub" and ma:
                    s.name, s.args = "fma", [ma.args[0], ma.args[1], neg(b)]
                elif s.name == "sub" and mb:
                    s.name, s.args = "fma", [neg(mb.args[0]), mb.args[1], a]
            out.append(s)
        return out

    f.body = go(f.body)
    from .ir import number_sites
    number_sites(f)
    return simplify(f)


def reduce_strength(f: Func) -> Func:
    """Operations the machine has no instruction for, rewritten when that is exact: an unsigned
    remainder by a power of two is a mask, and so is a signed one that is only compared with zero."""
    readers: dict[int, list] = {}
    for s in f.walk():
        for x in operands(s):
            if isinstance(x, Value):
                readers.setdefault(id(x), []).append(s)
    for s in f.walk():
        if isinstance(s, Op) and s.name == "rem" and isinstance(s.args[1], Const) and s.result.type.is_int:
            c = int(s.args[1].value)
            if c <= 0 or c & (c - 1):
                continue
            uses = readers.get(id(s.result), [])
            zero_tests = all(isinstance(u, Op) and u.name in ("eq", "ne") and any(isinstance(a, Const) and a.value == 0 for a in u.args)
                             for u in uses)
            if not s.result.type.signed or zero_tests:
                s.name, s.args = "and", [s.args[0], Const(c - 1, s.result.type)]
    return simplify(f)


def _low_zero_bits(x, defs: dict, depth: int = 0) -> int:
    """How many low bits of an integer value are known to be zero."""
    if isinstance(x, Const):
        v = int(x.value)
        return 64 if v == 0 else (v & -v).bit_length() - 1
    d = defs.get(id(x))
    if d is None or depth > 8:
        return 0
    if d.name == "mul":
        return min(63, _low_zero_bits(d.args[0], defs, depth + 1) + _low_zero_bits(d.args[1], defs, depth + 1))
    if d.name == "shl" and isinstance(d.args[1], Const):
        return min(63, _low_zero_bits(d.args[0], defs, depth + 1) + int(d.args[1].value))
    if d.name in ("add", "sub", "or", "xor"):
        return min(_low_zero_bits(d.args[0], defs, depth + 1), _low_zero_bits(d.args[1], defs, depth + 1))
    if d.name == "and":
        return max(_low_zero_bits(d.args[0], defs, depth + 1), _low_zero_bits(d.args[1], defs, depth + 1))
    if d.name == "cast" and d.args[0].type.is_int and d.result.type.is_int:
        return _low_zero_bits(d.args[0], defs, depth + 1)
    return 0


def widen_indices(f: Func) -> Func:
    """`extend(x + c)` → `extend(x) + c` when the 32-bit addition cannot wrap, so that `p[i]` and
    `p[i + 1]` have one index and differ by a constant offset. It cannot wrap when the addition is
    signed (overflow is undefined in C: the frontend marks it `nsw`) or when `x` has enough low zero
    bits to absorb `c` (`x = 2 * k`, `c = 1`). LLVM does the same from `nsw` and known bits."""
    defs = {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None}
    namer = _namer(f)

    def go(stmts: list) -> list:
        out = []
        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = go(s.then), go(s.orelse)
            elif isinstance(s, Loop):
                s.head, s.body = go(s.head), go(s.body)
            elif s.name == "cast" and s.result.type.is_int and s.result.type.bits == 64 and isinstance(s.args[0], Value):
                d = defs.get(id(s.args[0]))
                st = s.args[0].type
                if d is not None and d.name == "add" and st.is_int and st.bits == 32 and isinstance(d.args[1], Const):
                    c = int(d.args[1].value)
                    safe = (st.signed and d.attrs.get("nsw")) or (not st.signed and 0 <= c < (1 << _low_zero_bits(d.args[0], defs)))
                    if safe:
                        x = Value(namer.fresh(s.result.name), s.result.type)
                        cast = Op("cast", [d.args[0]], x, loc=s.loc)
                        out.append(cast)
                        defs[id(x)] = cast
                        s.name, s.args, s.attrs = "add", [x, Const(c, s.result.type)], {}
            out.append(s)
        return out

    f.body = go(f.body)
    return simplify(f)
