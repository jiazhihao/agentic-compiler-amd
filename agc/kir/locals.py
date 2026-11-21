"""Local objects back into values (`kir` → `kir`): what LLVM's SROA and mem2reg do.

The frontend puts every struct, array and address-taken variable of a thread in a `local` object and
reads and writes it through pointers, exactly as the source says. Here each object becomes one SSA
value per element: a store sets the element's current value, a load takes it, an `if` merges the
elements its sides store, a loop carries the elements its body stores.

An element indexed by a value known only at run time (`picked[k]`) is read as a chain of selects
over the object's elements and written as a conditional update of each. An object is left in memory
(and the lowering then refuses the kernel, naming it) when a pointer into it is merged, compared or
stored, when its elements are accessed with overlapping layouts, or when it is indexed at run time
and has more than `MAX_DYNAMIC` elements.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from .ir import Const, Func, I1, If, IRError, Loop, Merge, Op, Type, Value, operands, results, walk
from .passes import _dce, _namer, _put, simplify

MAX_DYNAMIC = 64


@dataclass
class _Ptr:
    obj: int                     # id of the `local` operation's result
    off: int                     # constant byte offset
    index: object = None         # a run-time index operand (elements of `scale` bytes from `off`), or None
    scale: int = 0


@dataclass
class _Obj:
    op: Op
    ok: bool = True
    why: str = ""
    slots: dict = field(default_factory=dict)       # byte offset -> (size, type)
    dynamic: bool = False


def promote(f: Func) -> list[str]:
    """Promote every local object that can be; returns the names (with reasons) of those that cannot."""
    objs: dict[int, _Obj] = {}
    ptrs: dict[int, _Ptr] = {}
    for s in f.walk():
        if isinstance(s, Op) and s.name == "local":
            objs[id(s.result)] = _Obj(s)
            ptrs[id(s.result)] = _Ptr(id(s.result), 0)
    if not objs:
        return []

    def fail(p: _Ptr | None, why: str):
        if p is not None and objs[p.obj].ok:
            objs[p.obj].ok, objs[p.obj].why = False, why

    # ---- which pointer is which element ------------------------------------------------------------
    for s in f.walk():
        if isinstance(s, Op):
            if s.name == "gep" and id(s.args[0]) in ptrs:
                p, size = ptrs[id(s.args[0])], s.args[0].type.elem.size
                if isinstance(s.args[1], Const):
                    ptrs[id(s.result)] = _Ptr(p.obj, p.off + int(s.args[1].value) * size, p.index, p.scale)
                elif p.index is None:
                    ptrs[id(s.result)] = _Ptr(p.obj, p.off, s.args[1], size)
                    objs[p.obj].dynamic = True
                else:
                    fail(p, "indexed at run time twice")
            elif s.name == "bitcast" and id(s.args[0]) in ptrs:
                ptrs[id(s.result)] = ptrs[id(s.args[0])]
            elif s.name == "load" and id(s.args[0]) in ptrs:
                pass
            elif s.name == "store" and id(s.args[0]) in ptrs:
                if isinstance(s.args[1], Value) and id(s.args[1]) in ptrs:
                    fail(ptrs[id(s.args[1])], "its address is stored")
            else:
                for a in s.args:
                    if isinstance(a, Value) and id(a) in ptrs:
                        fail(ptrs[id(a)], f"a pointer into it is used by `{s.name}`")
        else:
            for a in operands(s):
                if isinstance(a, Value) and id(a) in ptrs:
                    fail(ptrs[id(a)], "a pointer into it is merged or carried by a loop")
    # ---- the elements of each object -----------------------------------------------------------------
    for s in f.walk():
        if isinstance(s, Op) and s.name in ("load", "store") and id(s.args[0]) in ptrs:
            p = ptrs[id(s.args[0])]
            o = objs[p.obj]
            t = s.args[0].type.elem
            if p.index is not None:
                if p.scale != t.size or (o.op.attrs["bytes"] - p.off) // t.size > MAX_DYNAMIC:
                    fail(p, "indexed at run time over too many elements")
                    continue
                offs = range(p.off, o.op.attrs["bytes"] - t.size + 1, t.size)
            else:
                offs = [p.off]
            for off in offs:
                if off in o.slots and o.slots[off][0] != t.size:
                    fail(p, "its elements are accessed with overlapping layouts")
                o.slots.setdefault(off, (t.size, t))
    for o in objs.values():
        ends = sorted((off, off + size) for off, (size, _) in o.slots.items())
        if any(a[1] > b[0] for a, b in zip(ends, ends[1:])):
            o.ok, o.why = False, "its elements are accessed with overlapping layouts"
    good = {k for k, o in objs.items() if o.ok}
    if not good:
        return [f"{o.op.attrs['name']}: {o.why}" for o in objs.values()]
    namer = _namer(f)
    subst: dict[int, object] = {}

    def r(x):
        while isinstance(x, Value) and id(x) in subst:
            x = subst[id(x)]
        return x

    def conv(x, t: Type, out: list):
        """`x` as type `t` (same size): what a load of another type reads."""
        if x.type == t:
            return x
        if isinstance(x, Const):
            from .passes import fold_const
            c = fold_const("bitcast", [x], t)
            if c is not None:
                return c
        v = Value(namer.fresh("b"), t)
        out.append(Op("bitcast", [x], v))
        return v

    def cur(env: dict, key, t: Type, out: list):
        if key not in env:
            size, st = objs[key[0]].slots[key[1]]
            env[key] = Const(False if st.is_bool else 0.0 if st.is_float else 0, st)     # never written: any value
        return conv(env[key], t, out)

    def stored(stmts) -> set:
        """The elements the statements may store."""
        out = set()
        for s in walk(stmts):
            if isinstance(s, Op) and s.name == "store" and id(s.args[0]) in ptrs and ptrs[id(s.args[0])].obj in good:
                p = ptrs[id(s.args[0])]
                size = s.args[0].type.elem.size
                offs = range(p.off, objs[p.obj].op.attrs["bytes"] - size + 1, size) if p.index is not None else [p.off]
                out.update((p.obj, off) for off in offs)
        return out

    def go(stmts: list, env: dict) -> list:
        out = []
        for s in stmts:
            if isinstance(s, Op):
                s.args = [r(a) for a in s.args]
                p = ptrs.get(id(s.args[0])) if s.name in ("load", "store") and s.args else None
                if p is not None and p.obj in good:
                    t = s.args[0].type.elem
                    if s.name == "load":
                        if p.index is None:
                            _put(subst, s.result, cur(env, (p.obj, p.off), t, out))
                        else:                              # the element the index names: a chain of selects
                            offs = list(range(p.off, objs[p.obj].op.attrs["bytes"] - t.size + 1, t.size))
                            v = cur(env, (p.obj, offs[-1]), t, out)
                            for k in range(len(offs) - 2, -1, -1):
                                c = Value(namer.fresh("is"), I1)
                                out.append(Op("eq", [p.index, Const(k, p.index.type)], c))
                                nv = Value(namer.fresh("e"), t)
                                out.append(Op("select", [c, cur(env, (p.obj, offs[k]), t, out), v], nv))
                                v = nv
                            _put(subst, s.result, v)
                    else:
                        x = s.args[1]
                        if p.index is None:
                            env[(p.obj, p.off)] = x
                        else:                              # each element takes the value where the index names it
                            offs = list(range(p.off, objs[p.obj].op.attrs["bytes"] - t.size + 1, t.size))
                            for k, off in enumerate(offs):
                                c = Value(namer.fresh("is"), I1)
                                out.append(Op("eq", [p.index, Const(k, p.index.type)], c))
                                nv = Value(namer.fresh("e"), t)
                                out.append(Op("select", [c, x, cur(env, (p.obj, off), t, out)], nv))
                                env[(p.obj, off)] = nv
                    continue
                out.append(s)
            elif isinstance(s, If):
                s.cond = r(s.cond)
                ea, eb = dict(env), dict(env)
                s.then, s.orelse = go(s.then, ea), go(s.orelse, eb)
                for m in s.merges:
                    m.a, m.b = r(m.a), r(m.b)
                for key in sorted(set(ea) | set(eb), key=lambda k: (objs[k[0]].op.attrs["name"], k[1])):
                    t = objs[key[0]].slots[key[1]][1]
                    a, b = cur(ea, key, t, s.then), cur(eb, key, t, s.orelse)
                    if a is b or (isinstance(a, Const) and a == b):
                        env[key] = a
                    else:
                        v = Value(namer.fresh(objs[key[0]].op.attrs["name"]), t)
                        s.merges.append(Merge(v, a, b))
                        env[key] = v
                out.append(s)
            else:
                s.init = [r(x) for x in s.init]
                keys = sorted(stored(s.head) | stored(s.body), key=lambda k: (objs[k[0]].op.attrs["name"], k[1]))
                carried = []
                for key in keys:                           # an element the loop stores is carried by it
                    t = objs[key[0]].slots[key[1]][1]
                    c = Value(namer.fresh(objs[key[0]].op.attrs["name"]), t)
                    s.carried.append(c)
                    s.init.append(cur(env, key, t, out))
                    carried.append((key, c, t))
                    env[key] = c
                inner = dict(env)
                s.head = go(s.head, inner)
                s.cond = r(s.cond)
                s.body = go(s.body, inner)
                s.next = [r(x) for x in s.next]
                for key, c, t in carried:
                    s.next.append(cur(inner, key, t, s.body))
                    o = Value(namer.fresh(c.name), t)
                    s.out.append(o)
                    env[key] = o
                out.append(s)
        return out

    f.body = go(f.body, {})
    # the objects themselves and the pointer arithmetic into them are dead now
    for s in f.walk():
        if isinstance(s, Op):
            s.args = [r(a) for a in s.args]
        elif isinstance(s, If):
            s.cond = r(s.cond)
            for m in s.merges:
                m.a, m.b = r(m.a), r(m.b)
        else:
            s.init, s.next, s.cond = [r(x) for x in s.init], [r(x) for x in s.next], r(s.cond)
    _dce(f)
    simplify(f)
    return [f"{o.op.attrs['name']}: {o.why}" for o in objs.values() if not o.ok]
