"""Math-library functions in `kir`: the decisions `math.<fn>`.

A call such as `expf(x)` is one operation (`exp`) after the frontend. Before lowering it is
expanded into operations the machine has; which expansion is the decision `math.exp` at that call:

- `exact`: the sequence amdclang emits for the same call (read from its assembly for `gelu` and
  `softmax`; LLVM's `lowerFEXP` and the ROCm device library's `tanh`), so the result is the same,
  bit for bit, as amdclang's build of the source;
- `hw`: the shortest form on the machine's own instructions (`exp x = exp2(x * log2 e)`), a few
  units in the last place away; the manifest's tolerance decides whether a session may use it.

Square root and division need no expansion here: they are single `kir` operations with exact
(correctly rounded) meaning, and the decisions `math.sqrt` and `fp.div` choose their instruction
sequences at selection.
"""
from __future__ import annotations

import struct

from .ir import Const, Func, I1, If, Loop, Merge, Op, T, Value, number_sites
from .ops import LIBRARY
from .passes import _namer, simplify

F32, I32 = T("f32"), T("i32")


def _f(bits: int) -> Const:
    return Const(struct.unpack("<f", struct.pack("<I", bits))[0], F32)


LOG2E_HI, LOG2E_LO = _f(0x3FB8AA3B), _f(0x32A5705F)
EXP_UNDERFLOW, EXP_OVERFLOW = _f(0xC2CE8ED0), _f(0x42B17218)       # exp(x) is 0 below -103.97 and inf above 88.72
TANH_SMALL = _f(0x3F200000)                                        # 0.625
TANH_POLY = [_f(0xBBBAC73D), _f(0x3CA908C9), _f(0xBD5C1C4E), _f(0x3E088382), _f(0xBEAAAA99)]
LN2 = _f(0x3F317218)
ALTERNATIVES = {"exp": ["exact", "hw"], "tanh": ["exact"], "log": ["hw"]}       # `log` has no amdclang-identical form yet


class _B:
    """Emit operations into a list."""

    def __init__(self, out: list, namer, loc):
        self.out, self.namer, self.loc = out, namer, loc

    def __call__(self, name: str, args: list, t=F32, **attrs) -> Value:
        v = Value(self.namer.fresh(name[:3]), t)
        self.out.append(Op(name, list(args), v, attrs, loc=self.loc))
        return v


def exp_exact(b: _B, x) -> Value:
    """LLVM's f32 exp: x * log2(e) as a rounded part and a remainder (the product's low bits and the low
    bits of log2 e), `exp2` of the remainder, `ldexp` by the rounded part, then the two ends of the range."""
    ph = b("mul", [x, LOG2E_HI])
    e = b("rndne", [ph])
    pl = b("fma", [x, LOG2E_HI, b("neg", [ph])])
    pl = b("fma", [x, LOG2E_LO, pl])
    y = b("ldexp", [b("exp2", [b("add", [b("sub", [ph, e]), pl])]), b("cast", [e], I32)])
    y = b("select", [b("lt", [x, EXP_UNDERFLOW], I1), Const(0.0, F32), y])
    return b("select", [b("gt", [x, EXP_OVERFLOW], I1), Const(float("inf"), F32), y])


def exp_hw(b: _B, x) -> Value:
    return b("exp2", [b("mul", [x, LOG2E_HI])])


def tanh_exact(b: _B, x, namer, result: Value) -> list:
    """The device library's tanh: for |x| >= 0.625, 1 - 2 / (exp(2 |x|) + 1) with the machine's reciprocal;
    below, an odd polynomial; the sign of x restored at the end. Returns the statements."""
    ax = b("abs", [x])
    small = b("lt", [ax, TANH_SMALL], I1)
    s = If(small, loc=b.loc)
    lo = _B(s.then, namer, b.loc)
    x2 = lo("mul", [x, x])
    p = lo("fma", [x2, TANH_POLY[0], TANH_POLY[1]])
    for c in TANH_POLY[2:]:
        p = lo("fma", [x2, p, c])
    z_small = lo("fma", [x2, lo("mul", [ax, p]), ax])
    hi = _B(s.orelse, namer, b.loc)
    t = exp_exact(hi, hi("add", [ax, ax]))
    z_big = hi("fma", [hi("rcp", [hi("add", [t, Const(1.0, F32)])]), Const(-2.0, F32), Const(1.0, F32)])
    z = Value(namer.fresh("tanh"), F32)
    s.merges.append(Merge(z, z_small, z_big))
    b.out.append(s)
    b.out.append(Op("copysign", [z, x], result, loc=b.loc))
    return b.out


def expand(f: Func, plan) -> Func:
    """Replace every library call by the expansion its decision selects."""
    namer = _namer(f)
    counts: dict[str, int] = {}

    def go(stmts: list) -> list:
        out = []
        for s in stmts:
            if isinstance(s, If):
                s.then, s.orelse = go(s.then), go(s.orelse)
            elif isinstance(s, Loop):
                s.head, s.body = go(s.head), go(s.body)
            elif s.name in LIBRARY:
                if s.result.type != F32:
                    from .ir import IRError
                    raise IRError(f"{s.name} on {s.result.type}: only f32 has a lowering")
                n = counts.get(s.name, 0)
                counts[s.name] = n + 1
                site = s.site or f"{s.name}{n}"
                how = plan.choose(site, f"math.{s.name}", ALTERNATIVES[s.name])
                b = _B(out, namer, s.loc)
                if s.name == "exp":
                    v = (exp_exact if how == "exact" else exp_hw)(b, s.args[0])
                    out.append(Op("bitcast", [v], s.result, loc=s.loc))
                elif s.name == "log":                        # log x = log2 x * ln 2
                    out.append(Op("mul", [b("log2", [s.args[0]]), LN2], s.result, loc=s.loc))
                else:
                    tanh_exact(b, s.args[0], namer, s.result)
                continue
            out.append(s)
        return out

    f.body = go(f.body)
    return simplify(f)
