"""Wave lowering: `kir` (one thread's program) → `wir` (one wave's schedule).

What it decides:

- **Uniformity.** A value computed only from kernel arguments, the workgroup id, launch parameters
  and constants is the same in every lane of a wave. It becomes a `u` value (an SGPR) when the
  machine has a scalar instruction for the operation (the `salu` section of the selection table);
  otherwise it is computed per lane with scalar operands. Everything that depends on the workitem
  id or on loaded data is `v`. (LLVM: UniformityAnalysis and AMDGPUAnnotateUniformValues.)
- **Control flow.** An `if` on a uniform integer comparison becomes a `branch`; any other `if`
  becomes a `where` region over the lanes for which the condition holds, and the values it merges
  become `select`s. (LLVM: StructurizeCFG, SIAnnotateControlFlow, SILowerControlFlow.)
- **Addresses.** A pointer is kept as `base + index * scale + offset` until a load or store uses
  it, so the access carries its base, its index and its constant offset separately.
"""
from __future__ import annotations

from dataclasses import dataclass

from ..kir.ir import Const, Func, I1, I64, If, IRError, Loop, Merge, Namer, Op, Type, U32, Value, operands, results
from ..kir.passes import _dce
from ..wir import ops as wops
from .plan import Plan
from .table import Table


class LowerError(ValueError):
    """The program needs something the lowering does not do yet. `site` names where."""

    def __init__(self, message: str, site: str | None = None):
        super().__init__(message)
        self.message, self.site = message, site


@dataclass
class PtrForm:
    base: Value                  # a wir pointer value
    index: object | None         # a wir i64 operand, or None
    scale: int
    off: int


def lower(f: Func, layout: list[tuple[int, int]], table: Table, plan: Plan) -> Func:
    """`layout`: (kernarg offset, size) of each parameter of `f`, in order."""
    return _Wave(f, layout, table, plan).run()


class _Wave:
    def __init__(self, f: Func, layout, table: Table, plan: Plan):
        self.f, self.table, self.plan = f, table, plan
        self.out = Func(f.name, [], [], "wir")
        self.namer = Namer()
        self.entry: list = self.out.body
        self.blocks: list[list] = [self.out.body]
        self.m: dict[int, object] = {}                     # kir value -> wir operand or PtrForm
        self.sources: dict[str, Value] = {}
        self.defs: dict[int, Op] = {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None}
        # compares read only as the condition of regions may stay scalar conditions
        cond_uses, other_uses = set(), set()
        for s in f.walk():
            if isinstance(s, Op):
                other_uses.update(id(a) for a in s.args)
            elif isinstance(s, If):
                cond_uses.add(id(s.cond))
                other_uses.update(id(x) for m in s.merges for x in (m.a, m.b))
            else:
                other_uses.update(id(x) for x in (*s.init, *s.next, s.cond))
        self.cond_only = cond_uses - other_uses
        for p, (off, size) in zip(f.params, layout):
            v = self.emit_entry("arg", p.type, "u", p.name, offset=off, size=size)
            self.m[id(p)] = PtrForm(v, None, 1, 0) if p.type.is_ptr else v

    # ---- emission ------------------------------------------------------------------------------
    def new(self, t: Type, kind: str, hint: str = "t") -> Value:
        return Value(self.namer.fresh(hint), t, kind)

    def emit(self, name: str, args: list, t: Type | None, kind: str | None, hint: str = "t", src: Op | None = None, **attrs):
        r = self.new(t, kind, hint) if t is not None else None
        self.blocks[-1].append(Op(name, list(args), r, attrs, src.site if src else None, src.loc if src else None))
        return r

    def emit_entry(self, name: str, t: Type, kind: str, hint: str, **attrs) -> Value:
        r = self.new(t, kind, hint)
        n = sum(1 for s in self.entry if isinstance(s, Op) and (s.name in wops.SOURCES_U or s.name in wops.SOURCES_V))
        self.entry.insert(n, Op(name, [], r, attrs))
        return r

    def source(self, name: str, kind: str, **attrs) -> Value:
        key = name + str(sorted(attrs.items()))
        if key not in self.sources:
            hint = (attrs.get("field") or name).replace(".", "_")
            self.sources[key] = self.emit_entry(name, U32, kind, hint, **attrs)
        return self.sources[key]

    # ---- operands ------------------------------------------------------------------------------
    def val(self, x):
        """The wir operand of a kir operand; a pointer is materialized as an address value."""
        if isinstance(x, Const):
            return x
        w = self.m[id(x)]
        return self.materialize(w) if isinstance(w, PtrForm) else w

    def ptr(self, x) -> PtrForm:
        w = self.m[id(x)]
        return w if isinstance(w, PtrForm) else PtrForm(w, None, 1, 0)

    def materialize(self, p: PtrForm) -> Value:
        if p.index is None and p.off == 0:
            return p.base
        idx = p.index if p.index is not None else Const(0, I64)
        kind = "v" if "v" in (p.base.kind, wops.kind_of(idx)) else "u"
        return self.emit("ptradd", [p.base, idx], p.base.type, kind, "p", scale=p.scale, off=p.off)

    def retyped(self, p: PtrForm, t: Type) -> PtrForm:
        if p.base.type == t:
            return p
        return PtrForm(self.emit("bitcast", [p.base], t, p.base.kind, "p"), p.index, p.scale, p.off)

    # ---- operations ----------------------------------------------------------------------------
    def scalar_ok(self, s: Op, args: list) -> bool:
        """Whether a uniform result of `s` can be computed in SGPRs."""
        n, t = s.name, s.result.type
        at = args[0].type if args else t
        if n in ("eq", "ne", "lt", "le", "gt", "ge"):
            return id(s.result) in self.cond_only and at.is_int and at.bits == 32 and self.table.salu(n, at) is not None
        if t.is_bool or at.is_bool or t.is_float or at.is_float:
            return n == "bitcast" and t.size == 4 and at.size == 4
        if n in ("cast", "bitcast"):
            return True
        if n == "neg":
            return t.bits == 32
        if n in ("add", "sub"):
            return t.bits in (32, 64) and self.table.salu(n, Type("int", 32)) is not None
        if n == "select":
            return False
        return self.table.salu(n, t) is not None

    def op(self, s: Op):
        n = s.name
        if n[:3] in ("tid", "bid") or n[:4] in ("bdim", "gdim"):
            d = n[-1]
            self.m[id(s.result)] = (self.source(f"lane.{d}", "v") if n.startswith("tid") else
                                    self.source(f"wg.{d}", "u") if n.startswith("bid") else
                                    self.source("hidden", "u", field=("group_size_" if n.startswith("bdim") else "block_count_") + d))
            return
        if n == "gep":
            p, size = self.ptr(s.args[0]), s.args[0].type.elem.size
            i, extra = s.args[1], 0
            if isinstance(i, Const):
                self.m[id(s.result)] = PtrForm(p.base, p.index, p.scale, p.off + int(i.value) * size)
                return
            d = self.defs.get(id(i))
            if d is not None and d.name == "add" and isinstance(d.args[1], Const) and d.result.type.bits == 64:
                i, extra = d.args[0], int(d.args[1].value) * size       # the constant part goes into the offset
            if p.index is not None:
                p = PtrForm(self.materialize(p), None, 1, 0)
            wi = self.val(i)
            if wi.type != I64:
                wi = wi if isinstance(wi, Const) else self.emit("cast", [wi], I64, wops.kind_of(wi))
            self.m[id(s.result)] = PtrForm(p.base, wi, size, p.off + extra)
            return
        if n == "bitcast" and s.result.type.is_ptr:
            self.m[id(s.result)] = self.retyped(self.ptr(s.args[0]), s.result.type)
            return
        if n in ("load", "store"):
            p = self.retyped(self.ptr(s.args[0]), s.args[0].type)
            idx = p.index if p.index is not None else Const(0, I64)
            if n == "load":
                self.m[id(s.result)] = self.emit("load", [p.base, idx], s.result.type, "v", s.result.name, s, scale=p.scale, off=p.off)
            else:
                self.emit("store", [p.base, idx, self.val(s.args[1])], None, None, src=s, scale=p.scale, off=p.off)
            return
        args = [self.val(a) for a in s.args]
        uniform = all(wops.kind_of(a) == "u" for a in args) and self.scalar_ok(s, args)
        self.m[id(s.result)] = self.emit(n, args, s.result.type, "u" if uniform else "v", s.result.name, s, **s.attrs)

    def region(self, s: If):
        cond = self.val(s.cond)
        mode = "branch" if wops.kind_of(cond) == "u" else "where"
        w = If(cond, mode=mode, site=s.site, loc=s.loc)
        self.blocks.append(w.then)
        self.body(s.then)
        self.blocks[-1] = w.orelse
        self.body(s.orelse)
        self.blocks.pop()
        # the merged values are evaluated where their definitions are visible
        merged = []
        for m in s.merges:
            self.blocks.append(w.then)
            a = self.val(m.a)
            self.blocks[-1] = w.orelse
            b = self.val(m.b)
            self.blocks.pop()
            merged.append((m, a, b))
        self.blocks[-1].append(w)
        for m, a, b in merged:
            t = m.result.type
            if mode == "where":
                r = self.emit("select", [cond, a, b], t, "v", m.result.name)
            else:
                r = self.new(t, "u" if wops.kind_of(a) == wops.kind_of(b) == "u" else "v", m.result.name)
                w.merges.append(Merge(r, a, b))
            self.m[id(m.result)] = PtrForm(r, None, 1, 0) if t.is_ptr else r

    def body(self, stmts: list):
        for s in stmts:
            if isinstance(s, Op):
                self.op(s)
            elif isinstance(s, If):
                self.region(s)
            else:
                raise LowerError("loops are not lowered yet (roadmap M12); a loop with a constant trip count is "
                                 "unrolled before this point", s.site)

    def run(self) -> Func:
        self.body(self.f.body)
        _dce(self.out)
        from ..wir.verify import assert_ok
        return assert_ok(self.out)
