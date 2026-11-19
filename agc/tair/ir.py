"""The tair data model.

    tair softmax(x: f32[R, C]) -> (y: f32[R, C]) {
      m = reduce max(x)
      s = reduce sum(exp(x - m))
      y = exp(x - m) / s
    }

A statement is `name = expr` (an elementwise map; operands broadcast) or `name = reduce KIND(expr)`
(over the last axis, keeping it as size 1). Parameters are tensors (`x: f32[R, C]`) or scalars
(`a: f32`); shape entries are symbols or integers. Every float value is computed in f32 unless a
`cast` says otherwise.
"""
from __future__ import annotations

from dataclasses import dataclass, field

FUNCS = {  # name -> arity
    "add": 2, "sub": 2, "mul": 2, "div": 2, "neg": 1, "max": 2, "min": 2, "abs": 1,
    "exp": 1, "tanh": 1, "sqrt": 1, "rsqrt": 1, "rcp": 1, "fma": 3, "cast_bf16": 1, "cast_f32": 1,
}
REDUCTIONS = ("sum", "max", "min", "mean", "argmax")


class TairError(ValueError):
    pass


@dataclass(frozen=True)
class Var:
    name: str


@dataclass(frozen=True)
class Const:
    value: float


@dataclass(frozen=True)
class Call:
    fn: str
    args: tuple

    def __post_init__(self):
        if self.fn not in FUNCS:
            raise TairError(f"unknown function {self.fn!r} (known: {', '.join(FUNCS)})")
        if len(self.args) != FUNCS[self.fn]:
            raise TairError(f"{self.fn} takes {FUNCS[self.fn]} argument(s), got {len(self.args)}")


Expr = Var | Const | Call


@dataclass(frozen=True)
class Param:
    name: str
    dtype: str
    shape: tuple | None            # None: a scalar


@dataclass(frozen=True)
class Stmt:
    name: str
    expr: Expr
    reduce: str | None = None      # None: a map


@dataclass
class Program:
    name: str
    params: list[Param]
    outputs: list[Param]
    body: list[Stmt] = field(default_factory=list)

    def param(self, name: str) -> Param | None:
        return next((p for p in self.params if p.name == name), None)

    def validate(self) -> None:
        known = {p.name for p in self.params}
        if len(known) != len(self.params):
            raise TairError("duplicate parameter names")
        for s in self.body:
            if s.reduce is not None and s.reduce not in REDUCTIONS:
                raise TairError(f"unknown reduction {s.reduce!r}")
            for v in free_vars(s.expr):
                if v not in known:
                    raise TairError(f"statement {s.name}: {v!r} is not defined")
            if s.name in known:
                raise TairError(f"{s.name!r} is assigned twice")
            known.add(s.name)
        for o in self.outputs:
            if o.name not in {s.name for s in self.body}:
                raise TairError(f"output {o.name!r} is never assigned")

    def ranks(self) -> dict[str, str]:
        """name -> 'scalar' | 'row' (one value per row: a reduction result) | 'full' (the tensor shape)."""
        r = {p.name: ("scalar" if p.shape is None else "vec" if len(p.shape) == 1 and self._is_row_vector(p) else "full")
             for p in self.params}
        for s in self.body:
            ins = {r[v] for v in free_vars(s.expr)}
            if s.reduce:
                r[s.name] = "row"
            else:
                r[s.name] = "full" if ins & {"full", "vec"} else "row" if "row" in ins else "scalar"
        return r

    def _is_row_vector(self, p: Param) -> bool:
        """A rank-1 parameter next to rank-2 ones is a per-column vector (`w: f32[C]`)."""
        return any(q.shape is not None and len(q.shape) == 2 for q in self.params)


def free_vars(e: Expr) -> list[str]:
    if isinstance(e, Var):
        return [e.name]
    if isinstance(e, Call):
        out = []
        for a in e.args:
            out += free_vars(a)
        return out
    return []
