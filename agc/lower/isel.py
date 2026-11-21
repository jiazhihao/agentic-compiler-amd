"""Instruction selection: `wir` → virtual `mir` (then the existing allocator, `fix_waits`,
`fix_hazards` and `abi.make_kernel` make it the shipped program).

Which instruction implements an operation comes from the selection table (data); this module knows
the operand rules of the encodings and the shapes of the lowerings:

- a `u` value lives in an SGPR (a pair for 64 bits and pointers), a `v` value in a VGPR (a pair), a
  lane mask in an SGPR pair or, when its only reader is the next statement, in `vcc`;
- VOP2 / VOPC (`_e32`): the first source may be a VGPR, an SGPR or a constant, the second must be
  a VGPR; VOP3: any source may be a VGPR, an SGPR or an inline constant, but only one SGPR and no
  32-bit literal. Operands that do not fit are swapped (commutative or reversed forms) or copied
  into a VGPR;
- `where`: `s_and_saveexec_b64`, the region, `s_andn2_b64` for the else lanes, `s_or_b64` to
  restore (LLVM's SILowerControlFlow); `branch`: `s_cmp_*` and `s_cbranch_scc0`.

Derived here, never written in `wir`: registers, address arithmetic, kernarg offsets, which entry
registers the kernel asks the runtime for.
"""
from __future__ import annotations

import copy
import struct

from ..gen.builder import Builder
from ..kir.ir import Const, Func, If, Loop, Op, Type, Value, operands, walk
from ..mir import abi
from ..mir.ir import Imm, Label, Reg
from .plan import Plan
from .table import Table
from .wave import LowerError

_FLIP = {"lt": "gt", "gt": "lt", "le": "ge", "ge": "le", "eq": "eq", "ne": "ne"}
_COMMUTATIVE = {"add", "mul", "and", "or", "xor", "min", "max"}
_COMPARES = set(_FLIP)


def _bits32(c: Const) -> int:
    if c.type.is_float:
        return struct.unpack("<I", struct.pack("<f", float(c.value)))[0]
    return int(c.value) & 0xFFFFFFFF


class Selector:
    def __init__(self, w: Func, table: Table, plan: Plan, args: list[abi.Arg], hidden_base: int, arch=None):
        self.w, self.t, self.plan, self.args, self.hidden_base = w, table, plan, args, hidden_base
        self.b = Builder(w.name, arch)
        self.loc: dict[int, object] = {}                 # wir value -> Reg (or "vcc" for a mask)
        self.root: dict[int, int] = {}                   # value -> the value whose register it shares
        self.left: dict[int, int] = {}                   # root -> reads still to come
        self.pending: dict[int, Op] = {}                 # uniform conditions, emitted at their branch
        self.addr: list[dict] = [{}]                     # address registers computed in the open regions
        self.negated: dict[int, object] = {}             # a float negation read only by fma -> its operand
        self.direct: dict[int, Reg] = {}                 # value -> the register it must be computed into
        self.regions: dict[int, int] = {}                # LDS region handle -> its byte offset
        self.lds_bytes = 0
        self.depth = 0                                   # loops around the statement being selected
        self.defdepth: dict[int, int] = {}               # value -> the loop depth it was defined at
        self.noskip = 0                                  # open `where` regions entered without the empty-mask branch
        self.hint: dict[int, tuple] = {}                 # value -> (the value owning a register tuple, element)
        self.tuples: dict[int, object] = {}              # tuple owner -> its register
        self.wg: list[str] = []
        self.lanes = 0
        for s in w.walk():
            for x in operands(s):
                if isinstance(x, Value):
                    self.left[id(x)] = self.left.get(id(x), 0) + 1
            if isinstance(s, Op) and s.name.startswith("wg."):
                self.wg.append(s.name[-1])
            if isinstance(s, Op) and s.name in ("lane.x", "lane.y", "lane.z"):
                self.lanes = max(self.lanes, "xyz".index(s.name[-1]))
        self.wg = [d for d in "xyz" if d in self.wg] or ["x"]
        lo, hi = table.limit("inline_int")
        self.inline_int = range(lo, hi + 1)
        self.inline_float = set(table.limit("inline_float"))

    # ---- values and registers ------------------------------------------------------------------
    def rt(self, x) -> int:
        i = id(x)
        while i in self.root:
            i = self.root[i]
        return i

    def use(self, x) -> None:
        if isinstance(x, Value):
            self.left[self.rt(x)] = self.left.get(self.rt(x), 0) - 1

    def last_use(self, x) -> bool:
        return isinstance(x, Value) and self.left.get(self.rt(x), 0) <= 1

    def alias(self, v: Value, src, reg=None) -> None:
        """`v` is `src`'s register (or a part of it): no instruction."""
        self.loc[id(v)] = reg if reg is not None else self.loc[id(src)]
        if isinstance(src, Value):
            self.root[id(v)] = self.rt(src)
            self.left[self.rt(src)] = self.left.get(self.rt(src), 0) + self.left.pop(id(v), 0)

    def wide(self, t: Type) -> bool:
        return t.is_ptr or (not t.is_bool and t.bits == 64)

    def new(self, v: Value) -> Reg:
        """The register an instruction writes `v` into."""
        if id(v) in self.direct:                         # the next value of a loop-carried one: its register
            r = self.direct.pop(id(v))
            self.loc[id(v)] = r
            self.defdepth[id(v)] = self.depth
            return r
        if id(v) in self.hint:                           # an element of a tuple another value owns
            owner, i = self.hint[id(v)]
            r = Builder.part(self.tuple_of(owner), i)
        elif id(v) in self.tuples:
            r = self.tuple_of(v)
        elif v.type.is_bool:
            r = self.b.s(2)
        elif v.type.is_vec:
            r = self.b.v(v.type.count)
        elif v.kind == "u":
            r = self.b.s(2 if self.wide(v.type) else 1)
        else:
            r = self.b.v(2 if self.wide(v.type) else 1)
        self.loc[id(v)] = r
        self.defdepth[id(v)] = self.depth
        return r

    def tuple_of(self, v: Value) -> Reg:
        if id(v) not in self.tuples or self.tuples[id(v)] is None:
            self.tuples[id(v)] = self.b.v(v.type.count if v.type.is_vec else 2)
        return self.tuples[id(v)]

    def hints(self) -> None:
        """Let a value be computed directly into the register tuple that will hold it: the elements
        of a `pack`, and the 32-bit value a cast widens (its register becomes the low half)."""
        defs = {id(s.result): s for s in self.w.walk() if isinstance(s, Op) and s.result is not None}
        writes = lambda d: d is not None and d.name not in ("cast", "bitcast", "extract", "arg", "hidden", "ptradd") \
            and not d.name.startswith("wg.") and d.name not in ("lane.x", "lane.y", "lane.z")
        for s in self.w.walk():
            if not isinstance(s, Op) or s.result is None:
                continue
            if s.name == "pack":
                self.tuples[id(s.result)] = None
                for i, x in enumerate(s.args):
                    if isinstance(x, Value) and x.kind == "v" and id(x) not in self.hint and writes(defs.get(id(x))):
                        self.hint[id(x)] = (s.result, i)
            elif s.name == "cast" and s.result.kind == "v" and self.wide(s.result.type) and isinstance(s.args[0], Value):
                x = s.args[0]
                if x.kind == "v" and x.type.is_int and x.type.bits == 32 and id(x) not in self.hint and writes(defs.get(id(x))):
                    self.tuples[id(s.result)] = None
                    self.hint[id(x)] = (s.result, 0)

    def is_inline(self, c: Const) -> bool:
        if c.type.is_float:
            return float(c.value) in self.inline_float and not (c.value == 0 and str(c.value).startswith("-"))
        return int(c.value) in self.inline_int

    def imm(self, c: Const, half: int | None = None) -> Imm:
        if c.type.is_float and c.type.bits == 32:
            if float(c.value) == 0 and self.is_inline(c):
                return Imm("0")                          # +0.0 is the integer inline constant 0
            return Imm(repr(float(c.value))) if self.is_inline(c) else Imm(hex(_bits32(c)))
        v = int(c.value)
        if half is not None:
            v = (v >> (32 * half)) & 0xFFFFFFFF
            v = v - (1 << 32) if v >= 1 << 31 and (v - (1 << 32)) in self.inline_int else v
        return Imm(str(v) if v in self.inline_int else hex(v & 0xFFFFFFFF))

    def src(self, x, half: int | None = None):
        """The assembly operand of a wir operand (`half`: 0 or 1 of a 64-bit value)."""
        if isinstance(x, Const):
            return self.imm(x, half)
        r = self.loc[id(x)]
        return r if half is None or isinstance(r, str) else Builder.part(r, half)

    @staticmethod
    def is_v(o) -> bool:
        return isinstance(o, Reg) and o.cls == "v"

    @staticmethod
    def is_s(o) -> bool:
        return isinstance(o, Reg) and o.cls == "s"

    def literal(self, o) -> bool:
        return isinstance(o, Imm) and o.text.startswith("0x")

    def to_v(self, o, n: int = 1) -> Reg:
        """A VGPR holding the operand."""
        if self.is_v(o):
            return o
        r = self.b.v(n)
        if n == 1:
            self.b.emit(self.mov_v(), r, o)
        else:
            raise LowerError("a 64-bit operand that is not in VGPRs")
        return r

    def mov_v(self) -> str:
        return self.t.valu("mov", Type("int", 32)) + "_e32"

    def v64(self, x) -> Reg:
        """A 64-bit operand as a VGPR pair."""
        o = self.src(x)
        if self.is_v(o):
            return o
        r = self.b.v(2)
        for h in (0, 1):
            self.b.emit(self.mov_v(), Builder.part(r, h), self.src(x, h))
        return r

    # ---- encodings -----------------------------------------------------------------------------
    def vop2(self, mn: str, dst, a, b, commutative: bool = False, rev: str | None = None):
        """`dst = a OP b` with a VOP2 instruction when it has that form, else VOP3."""
        if self.t.has_e32(mn):
            if not self.is_v(b):
                if commutative and self.is_v(a):
                    a, b = b, a
                elif rev is not None and self.is_v(a):
                    mn, a, b = rev, b, a
                else:
                    b = self.to_v(b)
            self.b.emit(mn + "_e32", dst, a, b)
        else:
            self.vop3(mn, dst, a, b)

    def vop3(self, mn: str, dst, *srcs, tail=(), carry=None):
        srcs, scalars = list(srcs), 0
        for i, o in enumerate(srcs):
            if self.literal(o):
                srcs[i] = self.to_v(o)
            elif self.is_s(o):
                scalars += 1
                if scalars > 1:
                    srcs[i] = self.to_v(o)
        self.b.emit(mn, dst, *([carry] if carry is not None else []), *srcs, *tail)

    # ---- masks ---------------------------------------------------------------------------------
    def compare(self, s: Op, into_vcc: bool):
        a, b = s.args
        t, name, wide = a.type, s.name, self.wide(a.type)
        scalar = lambda x: isinstance(x, Const) or x.kind == "u"
        if scalar(a) and scalar(b) and t.is_int and t.bits == 32 and self.t.salu(name, t):
            # both uniform: the scalar condition code, spread over the lanes
            if isinstance(a, Const):
                a, b, name = b, a, _FLIP[name]
            self.b.emit(self.t.salu(name, t), self.src(a), self.src(b))
            self.b.emit(self.t.control("cond_to_mask"), self.new(s.result), -1, 0)
            return
        mn = self.t.valu(name, t)
        if mn is None:
            raise LowerError(f"no compare `{name}` on {t}", s.site)

        def operand(x):
            if wide and isinstance(x, Const) and not self.is_inline(x):
                return self.v64(x)
            return self.src(x)

        oa, ob = operand(a), operand(b)
        fits_e64 = not self.literal(oa) and not self.literal(ob) and self.is_s(oa) + self.is_s(ob) <= 1
        if fits_e64 and (not into_vcc or not (self.is_v(oa) or self.is_v(ob))):
            self.b.emit(mn + "_e64", self.new(s.result), oa, ob)
            return
        if not self.is_v(ob):
            if self.is_v(oa):
                oa, ob, mn = ob, oa, self.t.valu(_FLIP[name], t)
            else:
                ob = self.v64(b) if wide else self.to_v(ob)
        self.b.emit(mn + "_e32", "vcc", oa, ob)
        if into_vcc:
            self.loc[id(s.result)] = "vcc"
        else:
            self.b.emit(self.t.control("mask_copy"), self.new(s.result), "vcc")

    def mask(self, x):
        o = self.src(x)
        return "vcc" if o == "vcc" else o

    # ---- operations ----------------------------------------------------------------------------
    def op(self, s: Op, nxt) -> None:
        n, r = s.name, s.result
        if n == "arg":
            mn = self.t.data["memory"]["kernarg"][8 if self.wide(r.type) else 4]
            at, size = s.attrs["offset"], s.attrs["size"]
            if r.type.is_bool:                           # a `bool`: its byte, as a lane mask (all lanes or none)
                i32, tmp = Type("int", 32), self.b.s()
                self.b.emit(mn, tmp, self.t.limit("kernarg_pointer"), at - at % 4)
                if at % 4:
                    self.b.emit(self.t.salu("shr", i32), tmp, tmp, 8 * (at % 4))
                self.b.emit(self.t.salu("and", i32), tmp, tmp, 0xFF)
                self.b.emit(self.t.salu("ne", i32), tmp, 0)
                self.b.emit(self.t.control("cond_to_mask"), self.new(r), -1, 0)
                return
            dst = self.new(r)
            self.b.emit(mn, dst, self.t.limit("kernarg_pointer"), at - at % 4 if size < 4 else at)
            if size < 4:                                 # a byte or a short: the part of its aligned dword
                i32 = Type("int", 32)
                if at % 4:
                    self.b.emit(self.t.salu("shr", i32), dst, dst, 8 * (at % 4))
                if r.type.is_int and r.type.signed:
                    self.b.emit(self.t.salu(f"sext{8 * size}", i32), dst, dst)
                else:
                    self.b.emit(self.t.salu("and", i32), dst, dst, (1 << (8 * size)) - 1)
        elif n == "hidden":
            name = "hidden_" + s.attrs["field"]
            off, size = next((o, sz) for k, o, sz in abi.HIDDEN_ARGS if k == name)
            dst = self.new(r)
            at = self.hidden_base + off
            # a scalar load reads whole aligned dwords: a 16-bit field is the low or the high half of one
            self.b.emit(self.t.data["memory"]["kernarg"][4], dst, self.t.limit("kernarg_pointer"), at - at % 4)
            if at % 4:
                self.b.emit(self.t.salu("shr", r.type), dst, dst, 8 * (at % 4))
            if size < 4 and at % 4 + size < 4:
                self.b.emit(self.t.salu("and", r.type), dst, dst, (1 << (8 * size)) - 1)
        elif n == "lane.id":
            dst = self.new(r)
            self.b.emit(self.t.control("lane_count_lo"), dst, -1, 0)
            self.b.emit(self.t.control("lane_count_hi"), dst, -1, dst)
        elif n == "lane.read":
            at, x = self.to_v(self.src(s.args[1])), self.to_v(self.src(s.args[0]))
            self.b.emit(self.t.control("lane_read"), self.new(r), at, x)
        elif n == "lane.reduce":
            rd = self.t.data["reduce_dpp"]
            mn = self.t.valu(s.attrs["op"], r.type)
            if mn is None or not self.t.has_e32(mn):
                raise LowerError(f"no DPP form of `{s.attrs['op']}` on {r.type}", s.site)
            cur = self.to_v(self.src(s.args[0]))
            for step in rd["steps"]:
                nxt = self.b.v()
                self.b.emit(mn + "_dpp", nxt, cur, cur, **step, **rd["masks"])
                cur = nxt
            rows = [self.b.s() for _ in range(64 // rd["row"])]
            for i, row in enumerate(rows):
                self.b.emit(self.t.control("readlane"), row, cur, rd["row"] * i)
            dst = self.new(r)
            self.b.emit(self.mov_v(), dst, rows[0])
            for row in rows[1:]:
                self.b.emit(mn + "_e32", dst, row, dst)
        elif n == "region":
            self.loc[id(r)] = None                       # a handle, not a register
            self.regions[id(r)] = self.lds_bytes         # the region's byte offset in the workgroup's LDS
            self.lds_bytes += -(-s.attrs["bytes"] // 4) * 4   # (a dynamic region has 0 bytes here: the launch sizes it)
        elif n == "barrier":
            self.b.emit(self.t.control("barrier"))
        elif n in ("load", "store") and s.args[0].type.is_lds:
            self.lds_access(s)
        elif n.startswith("wg."):
            self.loc[id(r)] = Builder.S(self.t.limit("first_workgroup_id_sgpr") + self.wg.index(n[-1]))
        elif n in ("lane.x", "lane.y", "lane.z"):
            v0, d = Builder.V(self.t.limit("first_workitem_id_vgpr")), "xyz".index(n[-1])
            bits = self.t.limit("workitem_id_bits")
            if self.lanes == 0:
                self.loc[id(r)] = v0
            elif d == 0:
                self.vop2(self.t.valu("and", r.type), self.new(r), Imm(hex((1 << bits) - 1)), v0)
            else:
                self.vop3(self.t.valu("bfe", Type("int", 32)), self.new(r), v0, Imm(str(bits * d)), Imm(str(bits)))
        elif n == "load" and r.kind == "u":
            self.scalar_load(s)
        elif n == "mulw":
            a32, b32 = self.src(s.args[0]), self.src(s.args[1])
            t32 = s.args[0].type
            if r.kind == "u":
                dst = self.new(r)
                self.b.emit(self.t.salu("mul", t32), Builder.part(dst, 0), a32, b32)
                self.b.emit(self.t.salu("mulhi", t32), Builder.part(dst, 1), a32, b32)
            else:
                self.vop3(self.t.valu("mulw", t32), self.new(r), a32, b32, Imm("0"), carry=self.b.s(2))
        elif n in ("load", "store", "ptradd"):
            self.memory(s)
        elif n == "extract":
            self.alias(r, s.args[0], Builder.part(self.loc[id(s.args[0])], s.attrs["i"]))
        elif n == "pack":
            dst = self.new(r)
            for i, x in enumerate(s.args):
                ox = self.src(x)
                if not (self.is_v(ox) and ox.name is not None and ox.name == dst.name and ox.index == i):
                    self.b.emit(self.mov_v(), Builder.part(dst, i), ox)
        elif r.type.is_bool:
            self.bool_op(s, nxt)
        elif r.kind == "u":
            self.scalar(s)
        else:
            self.vector(s)
        for a in s.args:
            self.use(a)

    def bool_op(self, s: Op, nxt) -> None:
        n, r = s.name, s.result
        if n in _COMPARES:
            if r.kind == "u":
                self.pending[id(r)] = s
                for a in s.args:                         # read at the branch
                    if isinstance(a, Value):
                        self.left[self.rt(a)] = self.left.get(self.rt(a), 0) + 1
                return
            only_next = self.left.get(id(r), 0) == 1 and nxt is not None and any(x is r for x in operands(nxt)) and \
                ((isinstance(nxt, If) and not nxt.merges) or (isinstance(nxt, Op) and nxt.name in ("select", "and", "or", "not")))
            self.compare(s, only_next)
            return
        if n in ("and", "or", "xor"):
            self.b.emit(self.t.salu(n, Type("int", 64)), self.new(r), self.mask(s.args[0]), self.mask(s.args[1]))
        elif n == "not":
            self.b.emit("s_not_b64", self.new(r), self.mask(s.args[0]))
        elif n == "select":
            raise LowerError("select between conditions", s.site)
        else:
            raise LowerError(f"`{n}` giving a condition", s.site)

    def scalar(self, s: Op) -> None:
        n, r, a = s.name, s.result, s.args
        t, wide = r.type, self.wide(r.type)
        if n in ("cast", "bitcast"):
            st = a[0].type
            if isinstance(a[0], Const):
                raise LowerError("a constant cast survived simplification", s.site)
            sw = self.wide(st)
            if n == "bitcast" or (sw == wide and (t.bits >= st.bits or t.bits == 32)) and not (t.bits < 32 and st.bits > t.bits):
                if n == "bitcast" or t.bits >= 32 or st.bits <= t.bits:
                    self.alias(r, a[0])
                    return
            if sw and not wide and t.bits == 32:
                self.alias(r, a[0], Builder.part(self.loc[id(a[0])], 0))
                return
            if not sw and wide:
                dst = self.new(r)
                self.b.emit(self.t.salu("mov", Type("int", 32)), Builder.part(dst, 0), self.src(a[0]))
                if st.signed:
                    self.b.emit(self.t.salu("shr", Type("int", 32, True)), Builder.part(dst, 1), Builder.part(dst, 0), 31)
                else:
                    self.b.emit(self.t.salu("mov", Type("int", 32)), Builder.part(dst, 1), 0)
                return
            low = self.src(a[0], 0) if sw else self.src(a[0])
            if t.bits < 32:
                if t.signed:
                    self.b.emit(self.t.salu(f"sext{t.bits}", Type("int", 32)), self.new(r), low)
                else:
                    self.b.emit(self.t.salu("and", Type("int", 32)), self.new(r), low, (1 << t.bits) - 1)
                return
            raise LowerError(f"scalar cast {st} to {t}", s.site)
        if wide:
            dst = self.new(r)
            if n in ("add", "sub"):
                lo, hi = (("add", "addc") if n == "add" else ("sub", "subb"))
                self.b.emit(self.t.salu(lo, Type("int", 32)), Builder.part(dst, 0), self.src(a[0], 0), self.src(a[1], 0))
                self.b.emit(self.t.salu(hi, Type("int", 32)), Builder.part(dst, 1), self.src(a[0], 1), self.src(a[1], 1))
            elif n in ("shl", "shr"):
                self.b.emit(self.t.salu(n, t), dst, self.src(a[0]), self.src(a[1], 0))
            elif n in ("and", "or", "xor"):
                for h in (0, 1):
                    self.b.emit(self.t.salu(n, Type("int", 32)), Builder.part(dst, h), self.src(a[0], h), self.src(a[1], h))
            elif n == "mul":
                u32 = Type("int", 32)
                a0, a1, b0, b1 = self.src(a[0], 0), self.src(a[0], 1), self.src(a[1], 0), self.src(a[1], 1)
                hi, t1 = self.b.s(), self.b.s()
                self.b.emit(self.t.salu("mulhi", u32), hi, a0, b0)
                self.b.emit(self.t.salu("mul", u32), t1, a0, b1)
                self.b.emit(self.t.salu("add", u32), hi, hi, t1)
                self.b.emit(self.t.salu("mul", u32), t1, a1, b0)
                self.b.emit(self.t.salu("mul", u32), Builder.part(dst, 0), a0, b0)
                self.b.emit(self.t.salu("add", u32), Builder.part(dst, 1), hi, t1)
            else:
                raise LowerError(f"scalar `{n}` on {t}", s.site)
            return
        if n == "neg":
            self.b.emit(self.t.salu("sub", t), self.new(r), 0, self.src(a[0]))
            return
        if n == "mul" and isinstance(a[1], Const) and int(a[1].value) > 0 and int(a[1].value) & (int(a[1].value) - 1) == 0:
            self.b.emit(self.t.salu("shl", t), self.new(r), self.src(a[0]), int(a[1].value).bit_length() - 1)
            return
        mn = self.t.salu(n, t)
        if mn is None:
            raise LowerError(f"scalar `{n}` on {t}", s.site)
        self.b.emit(mn, self.new(r), *[self.src(x) for x in a])

    def vector(self, s: Op) -> None:
        n, r, a = s.name, s.result, s.args
        t, wide = r.type, self.wide(r.type)
        if n in ("cast", "bitcast"):
            return self.vcast(s)
        if n == "select":
            m = self.mask(a[0])
            dst = self.new(r)
            for h in ((0, 1) if wide else (None,)):
                x, y = self.src(a[1], h), self.src(a[2], h)
                d = dst if h is None else Builder.part(dst, h)
                # the mask is the instruction's scalar operand: the sources are VGPRs or inline constants
                x = self.to_v(x) if self.is_s(x) or self.literal(x) else x
                y = self.to_v(y) if self.is_s(y) or self.literal(y) else y
                self.b.emit(self.t.valu("select", Type("int", 32)) + "_e64", d, y, x, m)
            return
        if n == "fma" and any(id(x) in self.negated for x in a):
            # a negated operand is the VOP3 source modifier, not an instruction
            ops3 = []
            for x in a:
                if id(x) in self.negated:
                    o = self.src(self.negated[id(x)])
                    o = self.to_v(o) if not self.is_v(o) else o
                    ops3.append(Reg(o.cls, o.index, o.count, True, o.abs, o.name))
                else:
                    ops3.append(self.src(x))
            self.vop3(self.t.valu("fma", t), self.new(r), *ops3)
            return
        if n == "fma":
            oa, ob, c = self.src(a[0]), self.src(a[1]), a[2]
            tied = self.t.valu("fma.tied", t)
            oc = self.src(c)
            # the tied form overwrites `c`: only when this is its last read and it was not defined outside the
            # loop being selected (the next trip would read the overwritten register)
            if tied and self.is_v(oc) and oc.name is not None and self.last_use(c) and id(r) not in self.hint \
                    and self.defdepth.get(self.rt(c), -1) == self.depth \
                    and (id(r) not in self.direct or self.same_reg(self.direct[id(r)], oc)):
                self.direct.pop(id(r), None)
                if not self.is_v(ob):
                    oa, ob = ob, oa
                if not self.is_v(ob):
                    ob = self.to_v(ob)
                self.b.emit(tied + "_e32", oc, oa, ob)
                self.alias(r, c)
                return
            self.vop3(self.t.valu("fma", t), self.new(r), oa, ob, oc)
            return
        if wide:
            return self.vector64(s)
        if t.is_int and t.bits < 32:
            raise LowerError(f"arithmetic on {t} (C promotes to int; narrow types only through casts)", s.site)
        if n == "neg":
            readers = self.readers.get(id(r), [])
            if t.is_float and isinstance(a[0], Value) and readers and all(isinstance(u, Op) and u.name == "fma" for u in readers):
                self.negated[id(r)] = a[0]
                self.left[self.rt(a[0])] = self.left.get(self.rt(a[0]), 0) + len(readers)
                return
            if t.is_float:
                self.vop2(self.t.valu("xor", Type("int", 32)), self.new(r), Imm(hex(self.t.limit("float_sign_bit")[str(t)])), self.src(a[0]))
            else:
                self.vop2(self.t.valu("sub", t), self.new(r), Imm("0"), self.src(a[0]))
            return
        if n in ("not", "rcp", "rndne", "floor", "trunc", "exp2", "log2", "rsqrt"):
            mn = self.t.valu(n, t)
            if mn is None:
                raise LowerError(f"no per-lane `{n}` on {t} yet", s.site)
            self.b.emit(mn + "_e32", self.new(r), self.src(a[0]))
            return
        if n == "abs":                                   # clear the sign bit
            self.vop2(self.t.valu("and", Type("int", 32)), self.new(r), Imm(hex(self.t.limit("float_sign_bit")[str(t)] - 1)),
                      self.src(a[0]))
            return
        if n == "ldexp":
            self.vop3(self.t.valu("ldexp", t), self.new(r), self.src(a[0]), self.src(a[1]))
            return
        if n == "copysign":                              # the magnitude bits of a[0], the sign bit of a[1]
            mask = self.to_v(Imm(hex(self.t.limit("float_sign_bit")[str(t)] - 1)))
            x, y = (self.to_v(self.src(v)) for v in a)
            self.b.emit(self.t.valu("bfi", t), self.new(r), mask, x, y)
            return
        if n == "sqrt":
            return self.sqrt(s)
        if n == "div" and t.is_float:
            return self.fdiv(s)
        if n == "mul" and t.is_int and isinstance(a[1], Const) and int(a[1].value) > 0 and int(a[1].value) & (int(a[1].value) - 1) == 0:
            self.vop2(self.t.valu("shl.rev", t), self.new(r), Imm(str(int(a[1].value).bit_length() - 1)), self.src(a[0]))
            return
        if n in ("shl", "shr"):
            self.vop2(self.t.valu(n + ".rev", t), self.new(r), self.src(a[1]), self.src(a[0]))
            return
        mn = self.t.valu(n, t)
        if mn is None:
            raise LowerError(f"no per-lane `{n}` on {t} yet", s.site)
        self.vop2(mn, self.new(r), self.src(a[0]), self.src(a[1]), n in _COMMUTATIVE, self.t.valu(n + ".rev", t))

    @staticmethod
    def negated_reg(o: Reg) -> Reg:
        return Reg(o.cls, o.index, o.count, True, o.abs, o.name)

    def fdiv(self, s: Op) -> None:
        """Floating-point division. `exact`: LLVM's correctly rounded sequence (both operands scaled, the
        reciprocal of the denominator refined by three fma steps, the scaling undone, special values fixed up);
        `rcp`: the numerator times the machine's reciprocal."""
        r, (a, b) = s.result, s.args
        t = r.type
        if t.bits != 32:
            raise LowerError(f"division on {t}", s.site)
        how = self.plan.choose(s.site or "div", "fp.div", ["exact", "rcp"])
        fit = lambda x: (lambda o: o if self.is_v(o) or (isinstance(x, Const) and self.is_inline(x)) else self.to_v(o))(self.src(x))
        oa, ob = fit(a), fit(b)
        if how == "rcp":
            rc = self.b.v()
            self.b.emit(self.t.valu("rcp", t) + "_e32", rc, ob)
            self.vop2(self.t.valu("mul", t), self.new(r), oa, rc, True)
            return
        fma, fmac, mul = self.t.valu("fma", t), self.t.valu("fma.tied", t) + "_e32", self.t.valu("mul", t)
        bs, rc, as_, e, q, tmp = (self.b.v() for _ in range(6))
        self.b.emit(self.t.valu("div_scale", t), bs, self.b.s(2), ob, ob, oa)
        self.b.emit(self.t.valu("rcp", t) + "_e32", rc, bs)
        self.b.emit(self.t.valu("div_scale", t), as_, "vcc", oa, ob, oa)         # its flag stays in vcc for div_fmas
        nbs = self.negated_reg(bs)
        self.b.emit(fma, e, nbs, rc, 1.0)
        self.b.emit(fmac, rc, e, rc)
        self.b.emit(mul + "_e32", q, as_, rc)
        self.b.emit(fma, e, nbs, q, as_)
        self.b.emit(fmac, q, e, rc)
        self.b.emit(fma, e, nbs, q, as_)
        self.b.emit(self.t.valu("div_fmas", t), tmp, e, rc, q)
        self.b.emit(self.t.valu("div_fixup", t), self.new(r), tmp, ob, oa)

    def sqrt(self, s: Op) -> None:
        """Square root. `exact`: `v_sqrt_f32`, then the neighbours one unit below and above are tried and the one
        whose square does not exceed the operand is kept (LLVM's lowerFSQRTF32); `hw`: `v_sqrt_f32` alone."""
        r, x = s.result, s.args[0]
        t = r.type
        raw = self.t.valu("sqrt.hw", t)
        if raw is None:
            raise LowerError(f"square root on {t}", s.site)
        ox = self.to_v(self.src(x))
        if self.plan.choose(s.site or "sqrt", "math.sqrt", ["exact", "hw"]) == "hw":
            self.b.emit(raw + "_e32", self.new(r), ox)
            return
        k = self.t.limit("sqrt_f32")
        i32, sel = Type("int", 32), self.t.valu("select", Type("int", 32)) + "_e64"
        fma, mul = self.t.valu("fma", t), self.t.valu("mul", t) + "_e32"
        tiny, small, cmask = self.b.s(), self.b.s(2), self.b.s(2)
        up, x1, root, below, above, rb, ra, down, cls = (self.b.v() for _ in range(9))
        self.b.emit(self.t.salu("mov", i32), tiny, k["tiny"])
        self.b.emit(self.t.valu("gt", t) + "_e64", small, tiny, ox)              # the operand is below 2^-96: scale it
        self.b.emit(mul, up, Imm(hex(k["up"])), ox)
        self.b.emit(sel, x1, ox, up, small)
        self.b.emit(raw + "_e32", root, x1)
        self.b.emit(self.t.valu("add", i32) + "_e32", below, -1, root)
        self.b.emit(self.t.valu("add", i32) + "_e32", above, 1, root)
        self.b.emit(fma, rb, self.negated_reg(below), root, x1)
        self.b.emit(fma, ra, self.negated_reg(above), root, x1)
        self.b.emit(self.t.valu("ge", t) + "_e64", cmask, 0, rb)
        self.b.emit(sel, root, root, below, cmask)
        self.b.emit(self.t.valu("lt", t) + "_e64", cmask, 0, ra)
        self.b.emit(sel, root, root, above, cmask)
        self.b.emit(mul, down, Imm(hex(k["down"])), root)
        self.b.emit(sel, root, root, down, small)
        self.b.emit(self.mov_v(), cls, k["keep_class"])
        self.b.emit(self.t.valu("class", t) + "_e64", cmask, x1, cls)            # zeros and +infinity: the operand itself
        self.b.emit(sel, self.new(r), root, x1, cmask)

    def vector64(self, s: Op) -> None:
        n, r, a = s.name, s.result, s.args
        t = r.type
        dst = self.new(r)
        if n == "add" or (n == "sub" and isinstance(a[1], Const)):
            x, y = a[0], a[1] if n == "add" else Const(-int(a[1].value), a[1].type)
            if isinstance(x, Const):
                x, y = y, x
            oy = self.src(y) if not isinstance(y, Const) or self.is_inline(y) else self.v64(y)
            self.vop3(self.t.valu("lshl_add", t), dst, self.src(x) if not isinstance(x, Const) else self.v64(x), Imm("0"), oy)
        elif n in ("shl", "shr") or (n == "mul" and isinstance(a[1], Const) and int(a[1].value) > 0
                                      and int(a[1].value) & (int(a[1].value) - 1) == 0):
            count = Imm(str(int(a[1].value).bit_length() - 1)) if n == "mul" else self.src(a[1], 0)
            self.vop3(self.t.valu(("shl" if n == "mul" else n) + ".rev", t), dst, count, self.v64(a[0]))
        elif n in ("and", "or", "xor"):
            for h in (0, 1):
                self.vop2(self.t.valu(n, Type("int", 32)), Builder.part(dst, h), self.src(a[0], h), self.src(a[1], h), True)
        elif n == "mul":
            # the low 64 bits of a 64 x 64 product: lo(a0 b0), hi(a0 b0) + lo(a0 b1) + lo(a1 b0)
            u32 = Type("int", 32)
            a0, a1, b0, b1 = self.src(a[0], 0), self.src(a[0], 1), self.src(a[1], 0), self.src(a[1], 1)
            if not self.is_v(a0) and not self.is_v(b0):
                a0 = self.to_v(a0)
            hi, t1, t2 = self.b.v(), self.b.v(), self.b.v()
            self.vop3(self.t.valu("mulhi", u32), hi, a0, b0)
            self.vop3(self.t.valu("mul", u32), t1, a0, b1)
            self.vop3(self.t.valu("mul", u32), t2, a1, b0)
            self.vop3(self.t.valu("mul", u32), Builder.part(dst, 0), a0, b0)
            self.vop2(self.t.valu("add", u32), hi, hi, t1, True)
            self.vop2(self.t.valu("add", u32), Builder.part(dst, 1), hi, t2, True)
        else:
            raise LowerError(f"no per-lane `{n}` on {t} yet (roadmap M13)", s.site)

    def vcast(self, s: Op) -> None:
        r, x = s.result, s.args[0]
        t, st = r.type, x.type
        ox = self.src(x)
        if st.is_bool:                                   # a condition as 0 / 1
            self.b.emit(self.t.valu("select", Type("int", 32)) + "_e64", self.new(r), 0, 1, self.mask(x))
            if self.wide(t):
                raise LowerError("a condition converted to a 64-bit integer", s.site)
            return
        if s.name == "bitcast" or (st.is_int and t.is_int):
            sw, dw = self.wide(st), self.wide(t)
            if s.name == "bitcast" or (sw == dw and not (t.bits < 32 and st.bits > t.bits)):
                if self.is_v(ox):
                    self.alias(r, x)
                else:
                    dst = self.new(r)
                    for h in ((0, 1) if dw else (None,)):
                        self.b.emit(self.mov_v(), dst if h is None else Builder.part(dst, h), self.src(x, h))
                return
            if sw and not dw:
                low = self.src(x, 0)
                if t.bits == 32:
                    if self.is_v(low):
                        self.alias(r, x, low)
                    else:
                        self.b.emit(self.mov_v(), self.new(r), low)
                    return
                ox = low
            if not sw and dw:
                dst = self.new(r)
                if not (self.is_v(ox) and ox.name is not None and ox.name == dst.name and ox.index == 0):
                    self.b.emit(self.mov_v(), Builder.part(dst, 0), ox)
                if st.signed:
                    self.vop2(self.t.valu("shr.rev", Type("int", 32, True)), Builder.part(dst, 1), Imm("31"), Builder.part(dst, 0))
                else:
                    self.b.emit(self.mov_v(), Builder.part(dst, 1), 0)
                return
            # narrowing to 8 or 16 bits: keep the register canonical (zero- or sign-extended)
            if all(self.is_store_of(u, r) for u in self.readers.get(id(r), [])) and self.is_v(ox):
                self.alias(r, x, ox)                     # only stored: the store takes the low bits
                return
            if t.signed:
                self.vop3(self.t.valu("bfe", Type("int", 32, True)), self.new(r), ox, Imm("0"), Imm(str(t.bits)))
            else:
                self.vop2(self.t.valu("and", Type("int", 32)), self.new(r), Imm(hex((1 << t.bits) - 1)), ox)
            return
        mn = self.t.cast(st, t)
        if mn is None:
            raise LowerError(f"no conversion {st} to {t} yet", s.site)
        self.b.emit(mn + "_e32", self.new(r), ox)

    @staticmethod
    def is_store_of(u, r) -> bool:
        return isinstance(u, Op) and u.name == "store" and u.args[2] is r

    # ---- memory --------------------------------------------------------------------------------
    def address(self, s: Op) -> tuple[Reg, int]:
        """The VGPR pair holding the access's address and the immediate offset left over."""
        base, idx = s.args[0], s.args[1]
        scale, off = s.attrs["scale"], s.attrs["off"]
        lo, hi = self.t.limit("flat_offset")
        if isinstance(idx, Const):
            off += int(idx.value) * scale
            idx = None
        key = (self.rt(base), self.rt(idx) if idx is not None else None, scale)
        reg = next((d[key] for d in reversed(self.addr) if key in d), None)
        if reg is None:
            ob = self.src(base)
            if idx is None:
                reg = ob if self.is_v(ob) else self.v64(base)
            else:
                shift = scale.bit_length() - 1
                if scale & (scale - 1) or shift > self.t.limit("max_lshl_add"):
                    raise LowerError(f"an index scaled by {scale}", s.site)
                oi = self.src(idx)
                if not self.is_v(oi) and not self.is_v(ob):
                    oi = self.v64(idx)
                reg = self.b.v(2)
                self.vop3(self.t.valu("lshl_add", Type("int", 64)), reg, oi, Imm(str(shift)), ob)
            self.addr[-1][key] = reg
        if not lo <= off <= hi:
            r2 = self.b.v(2)
            self.vop3(self.t.valu("lshl_add", Type("int", 64)), r2, reg, Imm("0"), self.v64(Const(off, Type("int", 64, True))))
            reg, off = r2, 0
        return reg, off

    def memory(self, s: Op) -> None:
        n = s.name
        if n == "ptradd" and s.result.kind == "u":           # a uniform address: scalar arithmetic
            base, idx, scale, off = s.args[0], s.args[1], s.attrs["scale"], s.attrs["off"]
            i32 = Type("int", 32)
            dst = self.new(s.result)
            if isinstance(idx, Const):
                c = Const(int(idx.value) * scale + off, Type("int", 64, True))
                self.b.emit(self.t.salu("add", i32), Builder.part(dst, 0), self.src(base, 0), self.src(c, 0))
                self.b.emit(self.t.salu("addc", i32), Builder.part(dst, 1), self.src(base, 1), self.src(c, 1))
                return
            if scale & (scale - 1):
                raise LowerError(f"an index scaled by {scale}", s.site)
            self.b.emit(self.t.salu("shl", Type("int", 64)), dst, self.src(idx), scale.bit_length() - 1)
            self.b.emit(self.t.salu("add", i32), Builder.part(dst, 0), Builder.part(dst, 0), self.src(base, 0))
            self.b.emit(self.t.salu("addc", i32), Builder.part(dst, 1), Builder.part(dst, 1), self.src(base, 1))
            if off:
                c = Const(off, Type("int", 64, True))
                self.b.emit(self.t.salu("add", i32), Builder.part(dst, 0), Builder.part(dst, 0), self.src(c, 0))
                self.b.emit(self.t.salu("addc", i32), Builder.part(dst, 1), Builder.part(dst, 1), self.src(c, 1))
            return
        if n == "ptradd":
            reg, off = self.address(s)
            if off:
                r2 = self.b.v(2)
                self.vop3(self.t.valu("lshl_add", Type("int", 64)), r2, reg, Imm("0"), Imm(str(off)) if off in self.inline_int
                          else self.v64(Const(off, Type("int", 64, True))))
                reg = r2
            self.loc[id(s.result)] = reg
            return
        elem = s.args[0].type.elem
        reg, off = self.address(s)
        mods = {"offset": off} if off else {}
        count = s.attrs.get("n", 1)
        if count > 1:
            if n == "load":
                self.b.emit(self.t.data["memory"]["load_wide"][count], self.new(s.result), reg, "off", **mods)
            else:
                self.b.emit(self.t.data["memory"]["store_wide"][count], reg, self.loc[id(s.args[2])], "off", **mods)
            return
        if n == "load":
            mn = self.t.find("memory", "load", elem)
            if mn is None:
                raise LowerError(f"no load of {elem}", s.site)
            self.b.emit(mn, self.new(s.result), reg, "off", **mods)
        else:
            mn = self.t.find("memory", "store", elem)
            if mn is None:
                raise LowerError(f"no store of {elem}", s.site)
            x = s.args[2]
            data = self.v64(x) if self.wide(elem) else self.to_v(self.src(x))
            self.b.emit(mn, reg, data, "off", **mods)

    def lds_access(self, s: Op) -> None:
        """`ds_read_*` / `ds_write_*`: the address is the lane's byte offset in a VGPR plus an immediate."""
        base, idx = s.args[0], s.args[1]
        scale, off = s.attrs["scale"], s.attrs["off"] + self.regions[self.rt(base)]
        elem = base.type.elem
        if isinstance(idx, Const):
            off += int(idx.value) * scale
            idx = None
        lo, hi = self.t.limit("lds_offset")
        key = ("l", self.rt(idx) if idx is not None else None, scale)
        addr = next((d[key] for d in reversed(self.addr) if key in d), None)
        if addr is None:
            if idx is None:
                addr = self.b.v()
                self.b.emit(self.mov_v(), addr, 0)
            else:
                oi = self.src(idx)
                if scale == 1:
                    addr = self.to_v(oi)
                else:
                    if scale & (scale - 1):
                        raise LowerError(f"an LDS index scaled by {scale}", s.site)
                    addr = self.b.v()
                    self.vop2(self.t.valu("shl.rev", Type("int", 32)), addr, Imm(str(scale.bit_length() - 1)), oi)
            self.addr[-1][key] = addr
        if not lo <= off <= hi:
            a2 = self.b.v()
            self.vop2(self.t.valu("add", Type("int", 32)), a2, Imm(hex(off & 0xFFFFFFFF)), addr)
            addr, off = a2, 0
        mods = {"offset": off} if off else {}
        count = s.attrs.get("n", 1)
        if count > 1:                                    # consecutive dwords in one access
            if s.name == "load":
                self.b.emit(self.t.data["memory"]["lds_load_wide"][count], self.new(s.result), addr, **mods)
            else:
                self.b.emit(self.t.data["memory"]["lds_store_wide"][count], addr, self.loc[id(s.args[2])], **mods)
            return
        if s.name == "load":
            mn = self.t.find("memory", "lds_load", elem)
            if mn is None:
                raise LowerError(f"no LDS load of {elem}", s.site)
            self.b.emit(mn, self.new(s.result), addr, **mods)
        else:
            mn = self.t.find("memory", "lds_store", elem)
            if mn is None:
                raise LowerError(f"no LDS store of {elem}", s.site)
            x = s.args[2]
            self.b.emit(mn, addr, self.v64(x) if self.wide(elem) else self.to_v(self.src(x)), **mods)

    def scalar_load(self, s: Op) -> None:
        """A load at a uniform address: one `s_load_dword*` for the wave. It runs whatever the mask is, so
        every `where` around it must be entered through the empty-mask branch (then some lane reads the
        address in the source too, and it is valid)."""
        if self.noskip:
            raise LowerError("a scalar load inside a region entered without the empty-mask branch: choose "
                             "`branch.skip_empty: branch` for the regions around it, or `load.uniform: vector`", s.site)
        base, idx = s.args[0], s.args[1]
        scale, off = s.attrs["scale"], s.attrs["off"]
        if isinstance(idx, Const):
            off += int(idx.value) * scale
            idx = None
        lo, hi = self.t.limit("scalar_offset")
        key = ("s", self.rt(base), self.rt(idx) if idx is not None else None, scale)
        addr = next((d[key] for d in reversed(self.addr) if key in d), None)
        i32 = Type("int", 32)
        if addr is None:
            if idx is None:
                addr = self.src(base)
            else:
                shift = scale.bit_length() - 1
                if scale & (scale - 1):
                    raise LowerError(f"an index scaled by {scale}", s.site)
                addr = self.b.s(2)
                self.b.emit(self.t.salu("shl", Type("int", 64)), addr, self.src(idx), shift)
                self.b.emit(self.t.salu("add", i32), Builder.part(addr, 0), Builder.part(addr, 0), self.src(base, 0))
                self.b.emit(self.t.salu("addc", i32), Builder.part(addr, 1), Builder.part(addr, 1), self.src(base, 1))
            self.addr[-1][key] = addr
        if not lo <= off <= hi:
            a2 = self.b.s(2)
            c = Const(off, Type("int", 64, True))
            self.b.emit(self.t.salu("add", i32), Builder.part(a2, 0), Builder.part(addr, 0), self.src(c, 0))
            self.b.emit(self.t.salu("addc", i32), Builder.part(a2, 1), Builder.part(addr, 1), self.src(c, 1))
            addr, off = a2, 0
        elem = s.args[0].type.elem
        dwords = s.attrs.get("n", 1) * (2 if elem.size == 8 else 1)
        mn = self.t.data["memory"]["scalar"].get(dwords)
        if mn is None or elem.size not in (4, 8):
            raise LowerError(f"no scalar load of {dwords} dwords of {elem}", s.site)
        r = s.result
        if r.type.is_vec:
            dst = self.b.s(r.type.count)
            self.loc[id(r)] = dst
            self.defdepth[id(r)] = self.depth
        else:
            dst = self.new(r)
        self.b.emit(mn, dst, addr, off)

    # ---- loops ---------------------------------------------------------------------------------
    def copy(self, dst: Reg, v: Value, x) -> None:
        """`dst` (the register of a value shaped like `v`) = `x`."""
        if v.type.is_bool:
            src = self.mask(x) if not isinstance(x, Const) else (-1 if x.value else 0)
            self.b.emit(self.t.control("mask_copy"), dst, src)
            return
        wide = self.wide(v.type)
        mn = self.mov_v() if v.kind == "v" else self.t.salu("mov", Type("int", 32))
        for h in ((0, 1) if wide else (None,)):
            self.b.emit(mn, dst if h is None else Builder.part(dst, h), self.src(x, h))

    def same_reg(self, a, b) -> bool:
        return isinstance(a, Reg) and isinstance(b, Reg) and a.name is not None and (a.name, a.index, a.count) == (b.name, b.index, b.count)

    def loop(self, s: Loop) -> None:
        uniform = (s.cond.kind if isinstance(s.cond, Value) else "u") == "u"
        regs = []
        for c, i in zip(s.carried, s.init):
            r = self.new(c)
            self.copy(r, c, i)
            self.use(i)
            regs.append(r)
        save = None
        if not uniform:
            save = self.b.s(2)
            self.b.emit(self.t.control("mask_copy"), save, "exec")
        head, done = self.b.new_label(), self.b.new_label()
        self.depth += 1
        for c in s.carried:
            self.defdepth[id(c)] = self.depth
        # a next value nothing else reads, defined after the last read of the carried value, is computed
        # straight into the carried register (no copy at the end of the trip)
        top = {id(x.result): i for i, x in enumerate(s.body) if isinstance(x, Op) and x.result is not None}
        for r, c, n in zip(regs, s.carried, s.next):
            if isinstance(n, Value) and id(n) in top and self.left.get(id(n), 0) == 1 and id(n) not in self.hint \
                    and n.kind == c.kind and n.type == c.type and not c.type.is_bool:
                later = [x for st in s.body[top[id(n)]:] for x in ([st] + list(walk(st.then + st.orelse if isinstance(st, If)
                         else st.head + st.body if isinstance(st, Loop) else [])))]
                if not any(a is c for x in later[1:] for a in operands(x)) and not any(a is c for a in s.body[top[id(n)]].args
                                                                                     if s.body[top[id(n)]].name == "fma" and False):
                    self.direct[id(n)] = r
        # the test: once before the loop and again at the bottom (one branch per trip, as amdclang's loops),
        # when the head is straight-line code; otherwise at the top, with a jump back
        rotate = all(isinstance(x, Op) for x in s.head)
        if not rotate:
            self.b.label(head)
        self.addr.append({})
        mark = (len(self.b.blocks), len(self.b.blocks[-1].insts))
        self.body(s.head, False)
        if uniform:
            if isinstance(s.cond, Const):
                if not s.cond.value:
                    self.b.emit(self.t.control("jump"), done)
            else:
                self.scalar_condition(s.cond, s.site)
                self.b.emit(self.t.control("branch_false"), done)
        else:
            self.b.emit(self.t.control("mask_and"), "exec", "exec", self.mask(s.cond))
            self.use(s.cond)
            self.b.emit(self.t.control("skip_empty"), done)
        test = None
        if rotate and mark[0] == len(self.b.blocks) and not (uniform and isinstance(s.cond, Const)):
            test = [copy.deepcopy(x) for x in self.b.blocks[-1].insts[mark[1]:]]
            self.b.label(head)
        elif rotate:
            rotate = False                                   # the head opened a block after all: keep the top test
            raise LowerError("a loop head that is not straight-line code", s.site)
        self.body(s.body, False)
        # the next values into the carried registers: through temporaries when one carried value feeds another
        srcs = [self.src(n) for n in s.next]
        todo = [(r, c, n, o) for r, c, n, o in zip(regs, s.carried, s.next, srcs) if not self.same_reg(r, o)]
        crossed = any(isinstance(n, Value) and any(self.rt(n) == self.rt(c2) for c2 in s.carried) for _, _, n, _ in todo)
        if crossed:
            temps = []
            for r, c, n, _ in todo:
                tmp = self.b.s(2) if c.type.is_bool else (self.b.v if c.kind == "v" else self.b.s)(2 if self.wide(c.type) else 1)
                self.copy(tmp, c, n)
                temps.append(tmp)
            for (r, c, n, _), tmp in zip(todo, temps):
                if c.type.is_bool:
                    self.b.emit(self.t.control("mask_copy"), r, tmp)
                else:
                    mn = self.mov_v() if c.kind == "v" else self.t.salu("mov", Type("int", 32))
                    for h in ((0, 1) if self.wide(c.type) else (None,)):
                        self.b.emit(mn, r if h is None else Builder.part(r, h), tmp if h is None else Builder.part(tmp, h))
        else:
            for r, c, n, _ in todo:
                self.copy(r, c, n)
        for n in s.next:
            self.use(n)
        self.addr.pop()
        if test is not None:
            test[-1].mnemonic = self.t.control("branch_true" if uniform else "continue_nonempty")
            test[-1].operands = [Label(head)]
            self.b.blocks[-1].insts += test
        else:
            self.b.emit(self.t.control("jump"), head)
        self.b.label(done)
        self.depth -= 1
        if save is not None:
            self.b.emit(self.t.control("where_leave"), "exec", "exec", save)
        for o, c in zip(s.out, s.carried):
            self.alias(o, c)

    def scalar_condition(self, cond, site) -> None:
        """Set the scalar condition code from a uniform integer comparison."""
        c = self.pending.get(id(cond))
        if c is None:
            # a boolean held as a lane mask (the same in every lane): "some running lane says yes"
            self.b.emit(self.t.control("mask_and"), self.b.s(2), self.mask(cond), "exec")
            self.use(cond)
            return
        a, b, name = c.args[0], c.args[1], c.name
        if isinstance(a, Const):
            a, b, name = b, a, _FLIP[name]
        if a.type.is_int and a.type.bits == 32 and self.t.salu(name, a.type):
            self.b.emit(self.t.salu(name, a.type), self.src(a), self.src(b))
        else:
            # no scalar compare for this type: every lane computes the same answer, and the condition code is
            # "some running lane says yes" (amdclang: v_cmp, s_and_b64 with exec, a branch on the result)
            wide = self.wide(a.type)
            oa = self.v64(a) if wide else self.to_v(self.src(a))
            ob = self.src(b) if not isinstance(b, Const) or self.is_inline(b) else (self.v64(b) if wide else self.to_v(self.src(b)))
            if self.is_s(ob) and wide:
                ob = self.v64(b)
            mn = self.t.valu(name, a.type)
            if mn is None:
                raise LowerError(f"no compare `{name}` on {a.type}", site)
            self.b.emit(mn + "_e64", "vcc", oa, ob)
            self.b.emit(self.t.control("mask_and"), self.b.s(2), "vcc", "exec")
        self.use(a), self.use(b), self.use(cond)

    # ---- regions -------------------------------------------------------------------------------
    def where(self, s: If, tail: bool) -> None:
        m = self.mask(s.cond)
        self.use(s.cond)
        tail = tail and not s.merges
        save = self.b.s(2)
        # a wave that branched over a barrier would leave the others waiting: such a region is always entered
        has_barrier = any(isinstance(x, Op) and x.name == "barrier" for x in walk(s.then + s.orelse))
        skip = self.plan.choose(s.site or "if", "branch.skip_empty", ["none"] if has_barrier else ["branch", "none"]) == "branch"
        end = self.b.new_label()
        other = self.b.new_label() if s.orelse else end
        # A merged value is one register: it holds the else-side value before the region (when that value
        # exists there), and each side copies its value into it at its end. The copies run under the side's
        # mask, so each lane gets the value of the side it took, and no path reads a register it did not write.
        from ..kir.ir import results
        inside = {id(v) for part in (s.then, s.orelse) for x in walk(part) for v in results(x)}
        merged = []
        for mg in s.merges:
            dst = self.new(mg.result)
            early = isinstance(mg.b, Const) or id(mg.b) not in inside
            rt = mg.result.type
            self.copy(dst, mg.result, mg.b if early else Const(False if rt.is_bool else 0.0 if rt.is_float else 0, rt))
            merged.append((mg, dst, early))
        self.b.emit(self.t.control("where_enter"), save, m)
        if skip:
            self.b.emit(self.t.control("skip_empty"), other)
        self.noskip += not skip

        def copies(side: str):
            for mg, dst, early in merged:
                if side == "b" and early:
                    self.use(mg.b)
                    continue
                x = getattr(mg, side)
                if mg.result.type.is_bool:                   # the side's lanes take the bits of `x`
                    tmp = self.b.s(2)
                    self.b.emit(self.t.control("where_else"), dst, dst, "exec")
                    self.b.emit(self.t.control("mask_and"), tmp, "exec", self.mask(x) if not isinstance(x, Const) else (-1 if x.value else 0))
                    self.b.emit(self.t.salu("or", Type("int", 64)), dst, dst, tmp)
                else:
                    for h in ((0, 1) if self.wide(mg.result.type) else (None,)):
                        self.b.emit(self.mov_v(), dst if h is None else Builder.part(dst, h), self.src(x, h))
                self.use(x)

        self.addr.append({})
        self.body(s.then, tail and not s.orelse)
        copies("a")
        self.addr.pop()
        if s.orelse or any(not early for _, _, early in merged):
            self.b.label(other)
            self.b.emit(self.t.control("where_else"), "exec", save, "exec")
            if skip:
                self.b.emit(self.t.control("skip_empty"), end)
            self.addr.append({})
            self.body(s.orelse, tail)
            copies("b")
            self.addr.pop()
        else:
            for mg, _, _ in merged:
                self.use(mg.b)
        self.noskip -= not skip
        self.b.label(end)
        if not tail:
            self.b.emit(self.t.control("where_leave"), "exec", "exec", save)

    def branch(self, s: If, tail: bool) -> None:
        self.scalar_condition(s.cond, s.site)
        end = self.b.new_label()
        other = self.b.new_label() if (s.orelse or s.merges) else end
        self.b.emit(self.t.control("branch_false"), other)
        dsts = [self.new(m.result) for m in s.merges]

        def copies(side: str):
            for m, d in zip(s.merges, dsts):
                x = getattr(m, side)
                if m.result.type.is_bool:                    # a lane mask
                    self.copy(d, m.result, x)
                    self.use(x)
                    continue
                wide = self.wide(m.result.type)
                for h in ((0, 1) if wide else (None,)):
                    dd = d if h is None else Builder.part(d, h)
                    self.b.emit(self.mov_v() if m.result.kind == "v" else self.t.salu("mov", Type("int", 32)), dd, self.src(x, h))
                self.use(x)

        self.addr.append({})
        self.body(s.then, tail and not s.merges)
        copies("a")
        self.addr.pop()
        if other != end:
            self.b.emit(self.t.control("jump"), end)
            self.b.label(other)
            self.addr.append({})
            self.body(s.orelse, tail and not s.merges)
            copies("b")
            self.addr.pop()
        self.b.label(end)

    def body(self, stmts: list, tail: bool) -> None:
        for i, s in enumerate(stmts):
            nxt = stmts[i + 1] if i + 1 < len(stmts) else None
            last = tail and nxt is None
            if isinstance(s, Op):
                self.op(s, nxt)
            elif isinstance(s, If):
                if s.mode == "where":
                    self.where(s, last)
                else:
                    self.branch(s, last)
            else:
                self.loop(s)

    def run(self):
        self.readers: dict[int, list] = {}
        for s in self.w.walk():
            for x in operands(s):
                if isinstance(x, Value):
                    self.readers.setdefault(id(x), []).append(s)
        self.hints()
        self.body(self.w.body, True)
        self.b.emit(self.t.control("end"))
        return self.b.finish(self.args, workgroup_id="".join(self.wg), workitem_id=self.lanes, hidden_args=True,
                             lds_bytes=self.lds_bytes)


def select(w: Func, table: Table, plan: Plan, args: list[abi.Arg], hidden_base: int, arch=None):
    """The kernel (physical `mir`, waits and hazards placed, descriptor derived) of a `wir` function."""
    return Selector(w, table, plan, args, hidden_base, arch).run()
