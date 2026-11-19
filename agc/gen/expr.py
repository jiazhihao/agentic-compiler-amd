"""Compile a tair expression into per-lane f32 instructions.

A value is a VGPR (per lane), an SGPR (the same for every lane) or a constant. VOP2 forms take any
source in SRC0 and a VGPR in SRC1; VOP3 forms take VGPRs, SGPRs and inline constants but no literal,
so a literal that must feed a VOP3 form is materialized once in an SGPR (`Builder` constant pool).

Math under the manifest's numerical contract (not IEEE-exact, like amdclang's library calls):
`exp(x)` is `v_exp_f32(x * log2 e)`, `a / b` is `a * v_rcp_f32(b)`, `tanh(x)` is
`1 - 2 / (exp(2x) + 1)`. The battery decides whether that meets the tolerance.
"""
from __future__ import annotations

import struct

from ..mir.ir import Reg
from ..tair.ir import Call, Const, Expr, Var
from .builder import Builder, GenError

INLINE = {0.0: 0, 0.5: 0.5, 1.0: 1.0, 2.0: 2.0, 4.0: 4.0, -0.5: -0.5, -1.0: -1.0, -2.0: -2.0, -4.0: -4.0}
LOG2E = 1.4426950408889634


def f32_bits(x: float) -> int:
    return struct.unpack("<I", struct.pack("<f", x))[0]


class ExprCompiler:
    def __init__(self, b: Builder, const_block_index: int = 0):
        self.b = b
        self.consts: dict[int, Reg] = {}
        self.const_block = const_block_index         # literals are materialized at the end of this block

    # ---- operands --------------------------------------------------------------
    def const_s(self, bits: int) -> Reg:
        """An SGPR holding the 32-bit pattern (materialized once, in the prologue)."""
        if bits not in self.consts:
            r = self.b.s()
            cur = self.b.blocks
            self.b.blocks = cur[:self.const_block + 1]
            inst = self.b.emit("s_mov_b32", r, bits if bits > 64 else int(bits))
            self.b.blocks = cur
            blk = cur[self.const_block].insts            # at the very start: it must dominate every use
            blk.insert(0, blk.pop(blk.index(inst)))
            self.consts[bits] = r
        return self.consts[bits]

    def src0(self, x):
        """Anything VOP2's SRC0 takes: VGPR, SGPR, inline constant or a literal."""
        if isinstance(x, float):
            return INLINE[x] if x in INLINE else f32_bits(x)
        return x

    def nolit(self, x):
        """Anything a VOP3 source takes."""
        if isinstance(x, float):
            return INLINE[x] if x in INLINE else self.const_s(f32_bits(x))
        return x

    def vec(self, x) -> Reg:
        """A VGPR holding `x`."""
        if isinstance(x, Reg) and x.cls == "v":
            return x
        r = self.b.v()
        self.b.emit("v_mov_b32_e32", r, self.src0(x))
        return r

    @staticmethod
    def is_v(x) -> bool:
        return isinstance(x, Reg) and x.cls == "v"

    # ---- instruction selection -------------------------------------------------
    def _vop2(self, op: str, a, c, commutative: bool) -> Reg:
        """dst = op(a, c) with VOP2: SRC0 = a (any), SRC1 = c (VGPR)."""
        d = self.b.v()
        if commutative and not self.is_v(c) and self.is_v(a):
            a, c = c, a
        self.b.emit(op, d, self.src0(a), self.vec(c))
        return d

    def compile(self, e: Expr, env: dict, memo: dict | None = None):
        memo = {} if memo is None else memo
        key = e
        if key in memo:
            return memo[key]
        r = self._compile(e, env, memo)
        memo[key] = r
        return r

    def _compile(self, e: Expr, env: dict, memo: dict):
        b = self.b
        if isinstance(e, Var):
            if e.name not in env:
                raise GenError(f"value {e.name!r} is not available here")
            return env[e.name]
        if isinstance(e, Const):
            return float(e.value)
        f, args = e.fn, e.args
        if f == "add":                                   # fused multiply-add where one side is a product
            for i in (0, 1):
                if isinstance(args[i], Call) and args[i].fn == "mul":
                    x, y = (self.compile(t, env, memo) for t in args[i].args)
                    z = self.compile(args[1 - i], env, memo)
                    d = b.v()
                    b.emit("v_fma_f32", d, self.nolit(x), self.nolit(y), self.nolit(z))
                    return d
        a = [self.compile(t, env, memo) for t in args]
        if all(isinstance(x, float) for x in a):
            import numpy as np
            from ..tair.interp import _eval
            return float(_eval(Call(f, tuple(Const(x) for x in a)), {}, np.float32))
        if f == "add":
            return self._vop2("v_add_f32_e32", a[0], a[1], True)
        if f == "mul":
            return self._vop2("v_mul_f32_e32", a[0], a[1], True)
        if f == "max":
            return self._vop2("v_max_f32_e32", a[0], a[1], True)
        if f == "min":
            return self._vop2("v_min_f32_e32", a[0], a[1], True)
        if f == "sub":
            if self.is_v(a[1]):
                return self._vop2("v_sub_f32_e32", a[0], a[1], False)
            d = b.v()
            b.emit("v_subrev_f32_e32", d, self.src0(a[1]), self.vec(a[0]))      # d = SRC1 - SRC0
            return d
        if f == "div":
            r = b.v()
            b.emit("v_rcp_f32_e32", r, self.src0(a[1]))
            return self._vop2("v_mul_f32_e32", a[0], r, True)
        if f == "fma":
            d = b.v()
            b.emit("v_fma_f32", d, *(self.nolit(x) for x in a))
            return d
        d = b.v()
        x = a[0]
        if f == "neg":
            b.emit("v_xor_b32_e32", d, 0x80000000, self.vec(x))
        elif f == "abs":
            b.emit("v_and_b32_e32", d, 0x7FFFFFFF, self.vec(x))
        elif f == "sqrt":
            b.emit("v_sqrt_f32_e32", d, self.src0(x))
        elif f == "rsqrt":
            b.emit("v_rsq_f32_e32", d, self.src0(x))
        elif f == "rcp":
            b.emit("v_rcp_f32_e32", d, self.src0(x))
        elif f == "exp":
            t = b.v()
            b.emit("v_mul_f32_e32", t, f32_bits(LOG2E), self.vec(x))
            b.emit("v_exp_f32_e32", d, t)
        elif f == "tanh":                               # 1 - 2 / (exp(2x) + 1)
            t, u, r = b.v(), b.v(), b.v()
            b.emit("v_mul_f32_e32", t, f32_bits(2 * LOG2E), self.vec(x))
            b.emit("v_exp_f32_e32", u, t)
            b.emit("v_add_f32_e32", u, 1.0, u)
            b.emit("v_rcp_f32_e32", r, u)
            b.emit("v_fma_f32", d, r, -2.0, 1.0)
        elif f == "cast_bf16":                          # round to nearest even into the low 16 bits
            t = b.v()
            b.emit("v_bfe_u32", t, self.vec(x), 16, 1)
            b.emit("v_add3_u32", t, self.vec(x), t, self.const_s(0x7FFF))
            b.emit("v_lshrrev_b32_e32", d, 16, t)
        elif f == "cast_f32":
            return x
        else:
            raise GenError(f"no instruction selection for {f}")
        return d
