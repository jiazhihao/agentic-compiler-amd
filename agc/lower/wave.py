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
  it, so the access carries its base, its index and its constant offset separately. A load whose
  base and index are uniform is one scalar load for the wave (the decision `load.uniform`).
- **Loops.** A loop whose condition is a uniform integer comparison is a counted jump; any other
  loop runs under a mask from which each lane drops out when its own condition fails. A carried
  value stays uniform when its initial and next values are; a carried condition is a lane mask.
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
        self.chosen: dict[tuple, object] = {}
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
                cond_uses.add(id(s.cond))
                other_uses.update(id(x) for x in (*s.init, *s.next))
        self.cond_only = cond_uses - other_uses
        self.used = cond_uses | other_uses
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

    def emit_entry(self, opname: str, t: Type, kind: str, hint: str, **attrs) -> Value:
        r = self.new(t, kind, hint)
        n = sum(1 for s in self.entry if isinstance(s, Op) and (s.name in wops.SOURCES_U or s.name in wops.SOURCES_V))
        self.entry.insert(n, Op(opname, [], r, attrs))
        return r

    def source(self, opname: str, kind: str, t: Type = U32, **attrs) -> Value:
        key = opname + str(sorted(attrs.items()))
        if key not in self.sources:
            hint = str(attrs.get("field") or attrs.get("name") or opname).replace(".", "_")
            self.sources[key] = self.emit_entry(opname, t, kind, hint, **attrs)
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
        if p.base.type.is_lds:
            t = Type("ptr", 64, elem=t.elem, name="lds")
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
        if n == "shared":
            self.m[id(s.result)] = PtrForm(self.source("region", "u", t=s.result.type, **s.attrs), None, 1, 0)
            return
        if n == "barrier":
            self.emit("barrier", [], None, None, src=s)
            return
        if n == "wgreduce":
            # each wave combines its lanes without memory; the waves meet through one LDS slot each
            x, t, opn = self.val(s.args[0]), s.result.type, s.attrs["op"]
            x = x if wops.kind_of(x) == "v" and not isinstance(x, Const) else self.emit("bitcast", [x], t, "v")
            w = self.emit("lane.reduce", [x], t, "v", s.result.name, s, op=opn)
            waves = s.attrs["size"] // 64
            if waves > 1:
                slots = self.source("region", "u", t=Type("ptr", 64, elem=t, name="lds"), name=f"{s.site or 'reduce'}.waves",
                                    bytes=4 * waves)
                slot = self.emit("shr", [self.source("lane.x", "v"), Const(6, U32)], U32, "v")
                self.emit("store", [slots, slot, w], None, None, scale=4, off=0)
                self.emit("barrier", [], None, None)
                w = self.emit("load", [slots, Const(0, U32)], t, "v", scale=4, off=0)
                for k in range(1, waves):
                    v = self.emit("load", [slots, Const(0, U32)], t, "v", scale=4, off=4 * k)
                    w = self.emit(opn, [w, v], t, "v")
            self.m[id(s.result)] = w
            return
        if n == "gep" and s.args[0].type.is_lds:
            # an LDS index is 32 bits: the low half of what the source computed
            p, size = self.ptr(s.args[0]), s.args[0].type.elem.size
            i = s.args[1]
            if isinstance(i, Const):
                self.m[id(s.result)] = PtrForm(p.base, p.index, p.scale, p.off + int(i.value) * size)
                return
            d = self.defs.get(id(i))
            extra = 0
            if d is not None and d.name == "add" and isinstance(d.args[1], Const):
                i, extra = d.args[0], int(d.args[1].value) * size
                d = self.defs.get(id(i))
            if d is not None and d.name == "cast" and d.args[0].type.is_int and d.args[0].type.bits == 32 and isinstance(d.args[0], Value):
                wi = self.val(d.args[0])
            else:
                wi = self.val(i)
                if not (wi.type.is_int and wi.type.bits == 32):
                    wi = self.emit("cast", [wi], U32, wops.kind_of(wi))
            if p.index is not None:                          # two indices: one sum, in bytes
                first = p.index if p.scale == 1 else self.emit("mul", [p.index, Const(p.scale, p.index.type)], p.index.type,
                                                                wops.kind_of(p.index))
                second = wi if size == 1 else self.emit("mul", [wi, Const(size, wi.type)], wi.type, wops.kind_of(wi))
                if second.type != first.type:
                    second = self.emit("bitcast", [second], first.type, wops.kind_of(second))
                both = self.emit("add", [first, second], first.type, "v" if "v" in (wops.kind_of(first), wops.kind_of(second)) else "u")
                self.m[id(s.result)] = PtrForm(p.base, both, 1, p.off + extra)
            else:
                self.m[id(s.result)] = PtrForm(p.base, wi, size, p.off + extra)
            return
        if n == "gep":
            p, size = self.ptr(s.args[0]), s.args[0].type.elem.size
            i, extra = s.args[1], 0
            if isinstance(i, Const):
                self.m[id(s.result)] = PtrForm(p.base, p.index, p.scale, p.off + int(i.value) * size)
                return
            d = self.defs.get(id(i))
            while d is not None and d.name == "cast" and d.result.type.is_int and d.result.type.bits == 64 \
                    and d.args[0].type.is_int and d.args[0].type.bits == 64 and isinstance(d.args[0], Value):
                i = d.args[0]                                # i64 and u64 are the same index
                d = self.defs.get(id(i))
            if d is not None and d.name == "add" and isinstance(d.args[1], Const) and d.result.type.bits == 64:
                c = int(d.args[1].value)
                c = c - (1 << 64) if c >= 1 << 63 else c
                i, extra = d.args[0], c * size                          # the constant part goes into the offset
            if p.index is not None:
                p = PtrForm(self.materialize(p), None, 1, 0)
            wi = self.val(i)
            if not (wi.type.is_int and wi.type.bits == 64):
                wi = wi if isinstance(wi, Const) else self.emit("cast", [wi], I64, wops.kind_of(wi))
            self.m[id(s.result)] = PtrForm(p.base, wi, size, p.off + extra)
            return
        if n == "bitcast" and s.result.type.is_ptr:
            self.m[id(s.result)] = self.retyped(self.ptr(s.args[0]), s.result.type)
            return
        if n in ("load", "store"):
            p = self.retyped(self.ptr(s.args[0]), s.args[0].type)
            idx = p.index if p.index is not None else Const(0, U32 if p.base.type.is_lds else I64)
            if n == "load":
                kind = "v"
                if p.base.kind == "u" and wops.kind_of(idx) == "u" and s.result.type.size in (4, 8) and not s.result.type.is_bool \
                        and not p.base.type.is_lds:
                    if self.choose(s.site or "load", "load.uniform", ["scalar", "vector"]) == "scalar":
                        kind = "u"
                self.m[id(s.result)] = self.emit("load", [p.base, idx], s.result.type, kind, s.result.name, s, scale=p.scale, off=p.off)
            else:
                self.emit("store", [p.base, idx, self.val(s.args[1])], None, None, src=s, scale=p.scale, off=p.off)
            return
        if n == "mul" and s.result.type.is_int and s.result.type.bits == 64:
            pair = self.narrow(s.args[0]), self.narrow(s.args[1])
            if None not in pair:
                (x, sx), (y, sy) = pair
                signed = sx if sx is not None else sy
                if (sx is None or sy is None or sx == sy) and signed is not None:
                    t32 = Type("int", 32, signed)
                    x, y = (Const(int(v.value), t32) if isinstance(v, Const) else v for v in (x, y))
                    if x.type == t32 and y.type == t32:
                        if isinstance(x, Const):
                            x, y = y, x
                        uniform = wops.kind_of(x) == wops.kind_of(y) == "u" and self.table.salu("mulhi", t32) is not None
                        self.m[id(s.result)] = self.emit("mulw", [x, y], s.result.type, "u" if uniform else "v", s.result.name, s)
                        return
        args = [self.val(a) for a in s.args]
        uniform = all(wops.kind_of(a) == "u" for a in args) and self.scalar_ok(s, args)
        self.m[id(s.result)] = self.emit(n, args, s.result.type, "u" if uniform else "v", s.result.name, s, **s.attrs)

    def choose(self, site: str, decision: str, alternatives: list):
        """A decision of this lowering; taken once per site (a loop body may be lowered more than once)."""
        key = (site, decision)
        if key not in self.chosen:
            self.chosen[key] = self.plan.choose(site, decision, alternatives)
        return self.chosen[key]

    def narrow(self, x):
        """A 64-bit operand as (the 32-bit value it extends, that value's signedness), or None. A constant
        that fits in 31 bits extends either way (signedness None)."""
        if isinstance(x, Const):
            return (x, None) if 0 <= int(x.value) < 1 << 31 else None
        d = self.defs.get(id(x))
        if d is not None and d.name == "cast" and d.args[0].type.is_int and d.args[0].type.bits == 32 and isinstance(d.args[0], Value):
            return self.val(d.args[0]), d.args[0].type.signed
        return None

    def loop(self, s: Loop):
        """Lower a loop, deciding which carried values stay uniform: assume they all do, lower the loop,
        and start again with those whose next value turned out per-lane (or that are read after a loop
        each lane leaves on its own)."""
        inits = [self.val(i) for i in s.init]
        force = ["v" if c.type.is_bool or wops.kind_of(i) == "v" else None for c, i in zip(s.carried, inits)]
        for _ in range(len(s.carried) + 2):
            saved = dict(self.m)
            w = Loop(site=s.site, loc=s.loc)
            for c, k in zip(s.carried, force):
                v = self.new(c.type, k or "u", c.name)
                w.carried.append(v)
                self.m[id(c)] = PtrForm(v, None, 1, 0) if c.type.is_ptr else v
            self.blocks.append(w.head)
            self.body(s.head)
            w.cond = self.val(s.cond)
            self.blocks[-1] = w.body
            self.body(s.body)
            w.next = [self.val(n) for n in s.next]
            self.blocks.pop()
            per_lane = wops.kind_of(w.cond) == "v"
            wrong = [i for i, (c, nx) in enumerate(zip(w.carried, w.next)) if c.kind == "u" and
                     (wops.kind_of(nx) == "v" or (per_lane and id(s.out[i]) in self.used))]
            if not wrong:
                break
            for i in wrong:
                force[i] = "v"
            self.m = saved
        w.init = inits
        for c, o in zip(w.carried, s.out):
            v = self.new(c.type, c.kind, o.name)
            w.out.append(v)
            self.m[id(o)] = PtrForm(v, None, 1, 0) if c.type.is_ptr else v
        self.blocks[-1].append(w)

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
            r = self.new(t, "u" if mode == "branch" and wops.kind_of(a) == wops.kind_of(b) == "u" and not t.is_bool else "v",
                         m.result.name)
            w.merges.append(Merge(r, a, b))
            self.m[id(m.result)] = PtrForm(r, None, 1, 0) if t.is_ptr else r

    def body(self, stmts: list):
        for s in stmts:
            if isinstance(s, Op):
                self.op(s)
            elif isinstance(s, If):
                self.region(s)
            else:
                self.loop(s)

    def run(self) -> Func:
        self.body(self.f.body)
        _dce(self.out)
        from ..wir.verify import assert_ok
        return assert_ok(self.out)
