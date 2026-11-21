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


def _put(subst: dict, v, new) -> None:
    """Record that `v` is replaced by `new`. The replaced value is kept alive: substitutions are looked up by
    object identity, and an identity must not be reused by a value created later in the same pass."""
    subst[id(v)] = new
    subst.setdefault("alive", []).append(v)


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
        if t.is_bool and isinstance(a[1], Const) and isinstance(a[2], Const) and a[1].value and not a[2].value:
            return a[0]
    if n in ("add", "sub") and t.is_int and a[0] is a[1] and n == "sub":
        return Const(0, t)
    if n in ("cast", "bitcast") and a[0].type == t:
        return a[0]
    if n == "gep" and _is(a[1], 0):
        return a[0]
    return None


def _key(x):
    return ("c", x.value, str(x.type), str(x.value)) if isinstance(x, Const) else ("v", id(x))


_INVERSE = {"lt": "ge", "ge": "lt", "gt": "le", "le": "gt", "eq": "ne", "ne": "eq"}


def simplify(f: Func) -> Func:
    for _ in range(50):
        before = print_len(f)
        subst: dict[int, object] = {}
        ctx = {"defs": {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None},
               "namer": None, "f": f, "changed": False}
        f.body = _rewrite(f.body, subst, {}, ctx)
        _dce(f)
        if print_len(f) == before and not subst and not ctx["changed"]:
            break
    return f


def print_len(f: Func) -> int:
    return _count(f)


def _fresh(ctx: dict, hint: str, t: Type) -> Value:
    if ctx["namer"] is None:
        ctx["namer"] = _namer(ctx["f"])
    return Value(ctx["namer"].fresh(hint), t)


def _negatable(x, defs: dict) -> bool:
    d = defs.get(id(x)) if isinstance(x, Value) else None
    return d is not None and (d.name == "not" or (d.name in _INVERSE and not d.args[0].type.is_float))


def _logic(s: Op, out: list, ctx: dict) -> bool:
    """Rewrites of conditions that need new operations or look through definitions. True when `s`
    was rewritten in place (it is then simplified again)."""
    defs, n, a = ctx["defs"], s.name, s.args
    t = s.result.type
    if not t.is_bool:
        return False

    def emit(name: str, args: list) -> Value:
        v = _fresh(ctx, "c", I1)
        op = Op(name, args, v, loc=s.loc)
        out.append(op)
        defs[id(v)] = op
        return v

    if n == "not":
        d = defs.get(id(a[0])) if isinstance(a[0], Value) else None
        if d is None:
            return False
        if d.name == "not":                                 # !!x: handled by the caller through substitution
            return False
        if d.name in _INVERSE and not d.args[0].type.is_float:
            s.name, s.args = _INVERSE[d.name], list(d.args)       # !(a < b) is a >= b for integers (not for floats: NaN)
            return True
        if d.name in ("or", "and") and all(_negatable(x, defs) for x in d.args):
            s.name, s.args = ("and" if d.name == "or" else "or"), [emit("not", [d.args[0]]), emit("not", [d.args[1]])]
            return True
        return False
    if n == "select":
        c, x, y = a
        tc = lambda v: isinstance(v, Const) and bool(v.value)
        fc = lambda v: isinstance(v, Const) and not v.value
        if fc(x) and tc(y):
            s.name, s.args = "not", [c]
        elif fc(y):
            s.name, s.args = "and", [c, x]
        elif tc(x):
            s.name, s.args = "or", [c, y]
        elif fc(x):
            s.name, s.args = "and", [emit("not", [c]), y]
        elif tc(y):
            s.name, s.args = "or", [emit("not", [c]), x]
        else:
            return False
        return True
    return False


def _count(f: Func) -> int:
    return sum(1 for _ in f.walk())


def _rewrite(stmts: list, subst: dict, table: dict, ctx: dict) -> list:
    defs = ctx["defs"]

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
            if new is None and s.name == "not" and isinstance(s.args[0], Value):
                d = defs.get(id(s.args[0]))
                if d is not None and d.name == "not":
                    new = r(d.args[0])
            if new is None and s.name == "cast" and s.result.type.is_float and s.args[0].type.is_int and s.args[0].type.bits == 64:
                d = defs.get(id(s.args[0])) if isinstance(s.args[0], Value) else None
                while d is not None and d.name == "cast" and d.args[0].type.is_int and d.args[0].type.bits == 64:
                    d = defs.get(id(d.args[0])) if isinstance(d.args[0], Value) else None
                if d is not None and d.name == "cast" and d.args[0].type.is_int and d.args[0].type.bits == 32:
                    src = d.args[0]
                    # extend, then convert: the value of the 32-bit integer, when the 64-bit type reads it the same way
                    if not src.type.signed or s.args[0].type.signed:
                        s.args = [src]
                        ctx["changed"] = True
            if new is None and _logic(s, out, ctx):
                ctx["changed"] = True
            if new is None and s.name == "add" and s.result.type.is_int and isinstance(s.args[1], Const) and isinstance(s.args[0], Value):
                d = defs.get(id(s.args[0]))                 # (x + c1) + c2 is x + (c1 + c2)
                if d is not None and d.name == "add" and isinstance(d.args[1], Const):
                    c = fold_const("add", [d.args[1], s.args[1]], s.result.type)
                    if c is not None:
                        s.args = [d.args[0], c]
                        s.attrs = {"nsw": True} if s.attrs.get("nsw") and d.attrs.get("nsw") and \
                            (int(d.args[1].value) >= 0) == (int(s.args[1].value) >= 0) else {}
                        ctx["changed"] = True
            if new is None and s.name == "add" and s.result.type.is_int and not any(isinstance(x, Const) for x in s.args):
                for i in (0, 1):                             # x + (y + c) is (x + y) + c: the constant last
                    d = defs.get(id(s.args[i]))
                    if d is not None and d.name == "add" and isinstance(d.args[1], Const) and isinstance(d.args[0], Value):
                        v = _fresh(ctx, "s", s.result.type)
                        op = Op("add", [s.args[1 - i], d.args[0]], v, loc=s.loc)
                        defs[id(v)] = op
                        out.append(op)
                        s.args, s.attrs = [v, d.args[1]], {}
                        ctx["changed"] = True
                        break
            if new is None and s.name in PURE:
                args = sorted(s.args, key=lambda a: repr(_key(a))) if s.name in COMMUTATIVE else s.args
                key = (s.name, tuple(_key(a) for a in args), str(s.result.type), tuple(sorted(s.attrs.items())))
                if key in table:
                    new = table[key]
                else:
                    table[key] = s.result
            if new is not None:
                _put(subst, s.result, new)
            else:
                out.append(s)
        elif isinstance(s, If):
            s.cond = r(s.cond)
            if isinstance(s.cond, Const):
                taken = s.then if s.cond.value else s.orelse
                out += _rewrite(taken, subst, table, ctx)
                for m in s.merges:
                    _put(subst, m.result, r(m.a if s.cond.value else m.b))
                continue
            s.then = _rewrite(s.then, subst, dict(table), ctx)
            s.orelse = _rewrite(s.orelse, subst, dict(table), ctx)
            keep = []
            for m in s.merges:
                m.a, m.b = r(m.a), r(m.b)
                if m.a is m.b or (isinstance(m.a, Const) and m.a == m.b):
                    _put(subst, m.result, m.a)
                else:
                    keep.append(m)
            s.merges = keep
            if not s.then and not s.orelse and s.mode is None:      # nothing runs: the merges are selects
                for m in s.merges:
                    op = Op("select", [s.cond, m.a, m.b], m.result, loc=s.loc)
                    defs[id(m.result)] = op
                    out.append(op)
                    ctx["changed"] = True
                continue
            out.append(s)
        else:
            s.init = [r(x) for x in s.init]
            for i, (c, nx) in enumerate(zip(s.carried, s.next)):     # carried but never changed: its initial value
                if nx is c:
                    _put(subst, c, s.init[i])
                    _put(subst, s.out[i], s.init[i])
            keep = [i for i, (c, nx) in enumerate(zip(s.carried, s.next)) if nx is not c]
            if len(keep) != len(s.carried):
                ctx["changed"] = True
                for name in ("carried", "init", "next", "out"):
                    setattr(s, name, [getattr(s, name)[i] for i in keep])
            inner = dict(table)
            s.head = _rewrite(s.head, subst, inner, ctx)
            s.cond = r(s.cond)
            s.body = _rewrite(s.body, subst, inner, ctx)
            s.next = [r(x) for x in s.next]
            if isinstance(s.cond, Const) and not s.cond.value:      # never runs
                for o, i in zip(s.out, s.init):
                    _put(subst, o, i)
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
                        _put(subst, o, v)
                    out += go(stmts2)
        return out

    for _ in range(4):                                     # a loop's bound may be the result of another constant loop
        before = sum(isinstance(s, Loop) for s in f.walk())
        f.body = go(f.body)
        simplify(f)
        if not 0 < sum(isinstance(s, Loop) for s in f.walk()) < before:
            break
    return f


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
            elif s.name == "mul" and s.result.type.is_int and s.result.type.bits == 64:
                # (x + c) * y is x * y + c * y: the index of iteration k + c is that of iteration k plus a
                # loop-invariant stride
                for i, a in enumerate(s.args):
                    d = defs.get(id(a)) if isinstance(a, Value) else None
                    other = s.args[1 - i]
                    if d is not None and d.name == "add" and isinstance(d.args[1], Const) and not isinstance(other, Const):
                        t64 = s.result.type
                        base, stride = Value(namer.fresh("m"), t64), Value(namer.fresh("stride"), t64)
                        o1 = Op("mul", [d.args[0], other], base, loc=s.loc)
                        o2 = Op("mul", [Const(int(d.args[1].value), t64), other], stride, loc=s.loc)
                        out += [o1, o2]
                        defs[id(base)], defs[id(stride)] = o1, o2
                        s.name, s.args, s.attrs = "add", [base, stride], {}
                        break
            out.append(s)
        return out

    f.body = go(f.body)
    return simplify(f)


HOISTABLE = PURE | {"ptradd", "mulw", "extract", "pack"}


def licm(f: Func) -> Func:
    """Loop-invariant code motion: an operation without side effects whose operands are all defined
    outside a loop is computed once, before the loop. Works on `kir` and on `wir`. Only statements
    directly in the loop's head or body move (not those inside its regions)."""
    from .ir import results

    def go(stmts: list) -> list:
        out = []
        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = go(s.then), go(s.orelse)
                out.append(s)
            elif isinstance(s, Loop):
                s.head, s.body = go(s.head), go(s.body)
                inside = {id(c) for c in s.carried}
                for x in walk(s.head + s.body):
                    inside.update(id(v) for v in results(x))
                hoisted = []
                changed = True
                while changed:
                    changed = False
                    for part in ("head", "body"):
                        keep = []
                        for x in getattr(s, part):
                            if isinstance(x, Op) and x.result is not None and x.name in HOISTABLE and x.result is not s.cond and \
                                    all(isinstance(a, Const) or id(a) not in inside for a in x.args):
                                hoisted.append(x)
                                inside.discard(id(x.result))
                                changed = True
                            else:
                                keep.append(x)
                        setattr(s, part, keep)
                out += hoisted
                out.append(s)
            else:
                out.append(s)
        return out

    f.body = go(f.body)
    return f


def cse(f: Func) -> Func:
    """Common subexpressions only (no folding, no rewriting): an operation without side effects that
    repeats one visible at that point takes its value. Works on `kir` and on `wir` (where the kind of
    the result is part of what must match)."""
    subst: dict[int, object] = {}

    def r(x):
        while isinstance(x, Value) and id(x) in subst:
            x = subst[id(x)]
        return x

    def go(stmts: list, table: dict) -> list:
        out = []
        for s in stmts:
            if isinstance(s, Op):
                s.args = [r(a) for a in s.args]
                if s.result is not None and s.name in HOISTABLE:
                    args = sorted(s.args, key=lambda a: repr(_key(a))) if s.name in COMMUTATIVE else s.args
                    key = (s.name, tuple(_key(a) for a in args), str(s.result.type), s.result.kind, tuple(sorted(s.attrs.items())))
                    if key in table:
                        _put(subst, s.result, table[key])
                        continue
                    table[key] = s.result
                out.append(s)
            elif isinstance(s, If):
                s.cond = r(s.cond)
                s.then, s.orelse = go(s.then, dict(table)), go(s.orelse, dict(table))
                for m in s.merges:
                    m.a, m.b = r(m.a), r(m.b)
                out.append(s)
            else:
                s.init = [r(x) for x in s.init]
                inner = dict(table)
                s.head = go(s.head, inner)
                s.cond = r(s.cond)
                s.body = go(s.body, inner)
                s.next = [r(x) for x in s.next]
                out.append(s)
        return out

    f.body = go(f.body, {})
    return f


# ---- integer division ----------------------------------------------------------------------------
def _magic_unsigned(d: int) -> tuple[int, int, bool]:
    """(multiplier, shift, add): x // d for 32-bit unsigned x is `mulhi(x, m) >> s`, or with `add`
    `(((x - q) >> 1) + q) >> (s - 1)` where q = mulhi(x, m) (the multiplier needed 33 bits)."""
    top = (d - 1).bit_length()
    for s in range(top + 1):
        m = -(-(1 << (32 + s)) // d)
        if m < 1 << 32 and m * d - (1 << (32 + s)) <= 1 << s:
            return m, s, False
    m = -(-(1 << (32 + top)) // d)
    return m - (1 << 32), top, True


def expand_division(f: Func) -> Func:
    """Integer `div` and `rem` in terms of operations the machine has (it has no integer divide).

    - by a power of two: shifts and masks;
    - by another constant: a multiply-high by a precomputed reciprocal;
    - by a variable: a reciprocal estimate in floating point (`rcp`), one Newton step and two corrections in
      integers (LLVM's AMDGPUCodeGenPrepare::expandDivRem32; exact for every operand pair with a non-zero
      divisor);
    - 64-bit: as 32-bit when both operands are zero-extended 32-bit values, refused otherwise.
    Signed forms divide the magnitudes and fix the sign (C truncates toward zero)."""
    from .ir import I32, U32, T as _T
    namer = _namer(f)
    defs = {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None}
    F32 = _T("f32")

    def zext32(x):
        """The 32-bit unsigned value a 64-bit operand is the zero-extension of, or None."""
        if isinstance(x, Const):
            return Const(int(x.value), U32) if 0 <= int(x.value) < 1 << 32 else None
        d = defs.get(id(x))
        while d is not None and d.name == "cast" and d.args[0].type.is_int and d.args[0].type.bits == 64 and d.result.type.bits == 64:
            d = defs.get(id(d.args[0]))                    # i64 <-> u64
        if d is not None and d.name == "cast" and d.args[0].type.is_int and d.args[0].type.bits == 32 and isinstance(d.args[0], Value):
            src = d.args[0]
            if not src.type.signed:
                return src
            from .loops import nonneg
            if nonneg(src, defs):
                return ("bits", src)
        return None

    def go(stmts: list) -> list:
        out = []

        def E(name, args, t, **attrs):
            if all(isinstance(a, Const) for a in args):
                c = fold_const(name, list(args), t)
                if c is not None:
                    return c
            v = Value(namer.fresh("d"), t)
            op = Op(name, list(args), v, attrs)
            out.append(op)
            defs[id(v)] = op
            return v

        def udivrem(x, y):
            """Quotient and remainder of two u32 values."""
            if isinstance(y, Const):
                d = int(y.value)
                if d & (d - 1) == 0:
                    k = d.bit_length() - 1
                    return E("shr", [x, Const(k, U32)], U32), E("and", [x, Const(d - 1, U32)], U32)
                m, s, add = _magic_unsigned(d)
                q = E("mulhi", [x, Const(m, U32)], U32)
                if add:
                    q = E("add", [E("shr", [E("sub", [x, q], U32), Const(1, U32)], U32), q], U32)
                    s -= 1
                if s:
                    q = E("shr", [q, Const(s, U32)], U32)
                return q, E("sub", [x, E("mul", [q, y], U32)], U32)
            z = E("cast", [E("mul", [E("rcp", [E("cast", [y], F32)], F32), Const(4294966784.0, F32)], F32)], U32)
            z = E("add", [z, E("mulhi", [z, E("mul", [E("sub", [Const(0, U32), y], U32), z], U32)], U32)], U32)
            q = E("mulhi", [x, z], U32)
            r = E("sub", [x, E("mul", [q, y], U32)], U32)
            for _ in range(2):
                c = E("ge", [r, y], I1)
                q = E("select", [c, E("add", [q, Const(1, U32)], U32), q], U32)
                r = E("select", [c, E("sub", [r, y], U32), r], U32)
            return q, r

        def magnitude(x):
            """(|x| as u32, the sign word of x: 0 or -1) of an i32."""
            if isinstance(x, Const):
                v = int(x.value)
                return Const(abs(v), U32), Const(-1 if v < 0 else 0, I32)
            sx = E("shr", [x, Const(31, I32)], I32)
            return E("bitcast", [E("xor", [E("add", [x, sx], I32), sx], I32)], U32), sx

        def signed(v, s):
            """`v` (u32 magnitude) negated where the sign word `s` is -1, as i32."""
            v = E("bitcast", [v], I32) if isinstance(v, Value) else Const(_wrap(int(v.value)), I32)
            if isinstance(s, Const) and int(s.value) == 0:
                return v
            return E("sub", [E("xor", [v, s], I32), s], I32)

        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = go(s.then), go(s.orelse)
            elif isinstance(s, Loop):
                s.head, s.body = go(s.head), go(s.body)
            elif s.name in ("div", "rem") and s.result.type.is_int:
                t, (x, y) = s.result.type, s.args
                final = None
                if t.bits == 64:
                    nx, ny = zext32(x), zext32(y)
                    low = lambda v: E("bitcast", [v[1]], U32) if isinstance(v, tuple) else v
                    if isinstance(y, Const) and int(y.value) > 0 and int(y.value) & (int(y.value) - 1) == 0 and not t.signed:
                        k = int(y.value).bit_length() - 1      # an unsigned power of two: a shift or a mask
                        s.name, s.args, s.attrs = ("shr", [x, Const(k, t)], {}) if s.name == "div" else \
                            ("and", [x, Const(int(y.value) - 1, t)], {})
                    elif nx is not None and ny is not None:
                        q, r = udivrem(low(nx), low(ny))
                        final = ("cast", q if s.name == "div" else r)
                    elif nx is not None and not t.signed:
                        # x fits in 32 bits: when y > x the quotient is 0 and the remainder x; otherwise y fits too
                        # (amdclang's code for the same source does this)
                        y32 = E("cast", [y], U32)
                        q, r = udivrem(low(nx), y32)
                        big = E("gt", [y, x], I1)
                        v = E("cast", [q if s.name == "div" else r], t)
                        s.name, s.args, s.attrs = "select", [big, Const(0, t) if s.name == "div" else x, v], {}
                elif t.bits == 32 and not t.signed:
                    q, r = udivrem(x, y)
                    final = ("copy", q if s.name == "div" else r)
                elif t.bits == 32:
                    (ax, sx), (ay, sy) = magnitude(x), magnitude(y)
                    q, r = udivrem(ax, ay)
                    both = E("xor", [sx, sy], I32)
                    final = ("copy", signed(q, both) if s.name == "div" else signed(r, sx))
                if final is not None:
                    kind, v = final
                    if kind == "cast":
                        s.name, s.args, s.attrs = "cast", [v], {}
                    elif isinstance(v, Const):
                        s.name, s.args, s.attrs = "bitcast", [v], {}
                        s.name, s.args = "add", [v, Const(0, t)]
                    else:
                        s.name, s.args, s.attrs = "bitcast", [v], {}
            out.append(s)
        return out

    f.body = go(f.body)
    return simplify(f)


def _wrap(v: int) -> int:
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v >= 1 << 31 else v
