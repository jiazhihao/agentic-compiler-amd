"""The kernel manifest: what the kernel is, its parameters and shapes, how to launch it,
what it computes (the reference program), and how strictly to compare.

Shapes are static except symbols listed in `dynamic` (batch-like dimensions, varied by the
battery). Any integer field (shape entries, launch dims, scalar values) may be an expression
over the symbols in `shapes`, e.g. "cdiv(N, 256)".

`source` is a HIP file (compiled by amdclang and imported) or absent: a manifest with no
source is a tensor program, compiled from its reference by a generator (design D4).
"""
from __future__ import annotations

import ast
import json
import math
import operator
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .dtypes import DTYPES, FLOAT_DTYPES, DType, dtype as _dtype_of

# default tolerances per dtype (rtol, atol) for `|cand - ref| <= atol + rtol * |ref| (+ cond * scale)`
DEFAULT_TOL: dict[str, tuple[float, float]] = {
    "f64": (1e-10, 1e-12), "f32": (1e-4, 1e-5), "f16": (1e-2, 1e-3), "bf16": (2e-2, 1e-2),
    "e4m3": (0.13, 0.02), "e5m2": (0.26, 0.02),
    **{t: (0.0, 0.0) for t in ("i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64", "bool")},
}
REFERENCE_KINDS = ("einsum", "python", "torch", "tair", "none")


class ManifestError(ValueError):
    pass


_SAFE_FUNCS = {"ceil": lambda x: int(math.ceil(x)), "floor": lambda x: int(math.floor(x)),
               "min": min, "max": max, "cdiv": lambda a, b: -(-a // b)}
_OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
        ast.Div: operator.truediv, ast.FloorDiv: operator.floordiv, ast.Mod: operator.mod,
        ast.Pow: operator.pow, ast.USub: operator.neg}


def _eval_number(expr: Any, symbols: dict[str, int]) -> int | float:
    if isinstance(expr, bool):
        raise ManifestError(f"boolean is not a numeric expression: {expr!r}")
    if isinstance(expr, (int, float)):
        return expr
    if not isinstance(expr, str):
        raise ManifestError(f"bad numeric expression {expr!r}")
    try:
        tree = ast.parse(expr, mode="eval")
    except SyntaxError as e:
        raise ManifestError(f"cannot parse expression {expr!r}: {e}") from None

    def ev(node):
        if isinstance(node, ast.Expression):
            return ev(node.body)
        if isinstance(node, ast.Constant) and type(node.value) in (int, float):
            return node.value
        if isinstance(node, ast.Name):
            if node.id in symbols:
                return symbols[node.id]
            raise ManifestError(f"unknown symbol {node.id!r} in {expr!r}")
        if isinstance(node, ast.BinOp) and type(node.op) in _OPS:
            return _OPS[type(node.op)](ev(node.left), ev(node.right))
        if isinstance(node, ast.UnaryOp) and type(node.op) in _OPS:
            return _OPS[type(node.op)](ev(node.operand))
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                and node.func.id in _SAFE_FUNCS and not node.keywords):
            return _SAFE_FUNCS[node.func.id](*[ev(a) for a in node.args])
        raise ManifestError(f"unsupported construct in expression {expr!r}")

    try:
        return ev(tree)
    except ManifestError:
        raise
    except (ArithmeticError, TypeError, ValueError) as e:
        raise ManifestError(f"cannot evaluate expression {expr!r}: {e}") from None


def eval_expr(expr: Any, symbols: dict[str, int]) -> int:
    """Integer geometry expressions; a fractional result is an error."""
    value = _eval_number(expr, symbols)
    if isinstance(value, float) and not value.is_integer():
        raise ManifestError(f"expression {expr!r} evaluates to non-integer {value}")
    return int(value)


def eval_scalar(expr: Any, symbols: dict[str, int]) -> float:
    return float(_eval_number(expr, symbols))


@dataclass
class Param:
    name: str
    kind: str                      # "tensor" | "scalar"
    dtype: DType
    shape: list[Any] = field(default_factory=list)   # tensor: expressions
    role: str = "in"               # tensors: "in" | "out" | "inout"
    value: Any = None              # scalar: expression or literal
    init: Any = None               # a distribution name, "zeros", {"kind": "int_range", "lo", "hi"} or {"kind": "constant", "value"}

    def resolved_shape(self, symbols: dict[str, int]) -> tuple[int, ...]:
        return tuple(eval_expr(e, symbols) for e in self.shape)

    def to_dict(self) -> dict:
        d = {"name": self.name, "kind": self.kind, "dtype": str(self.dtype)}
        if self.kind == "tensor":
            d.update(shape=self.shape, role=self.role)
            if self.init is not None:
                d["init"] = self.init
        else:
            d["value"] = self.value
        return d


@dataclass
class Reference:
    kind: str                       # einsum | python | torch | tair | none
    expr: str | None = None         # einsum expression
    inputs: list[str] = field(default_factory=list)
    output: str | None = None
    file: str | None = None         # python / torch: path relative to the manifest; tair: a .tair file
    function: str | None = None     # python / torch: fn(**inputs_and_scalars) -> array or {name: array}
    text: str | None = None         # tair: the module text inline

    def to_dict(self) -> dict:
        return {k: v for k, v in self.__dict__.items() if v not in (None, [])}


@dataclass
class Manifest:
    name: str
    entry: str
    params: list[Param]
    grid: list[Any]
    block: list[Any]
    shapes: dict[str, int]
    path: Path
    source: Path | None = None
    arch: str = "gfx950"
    lds: Any = 0                    # dynamic LDS bytes passed at launch
    dynamic: list[str] = field(default_factory=list)
    tolerance: dict[str, dict[str, float]] = field(default_factory=dict)
    reference: Reference = field(default_factory=lambda: Reference("none"))
    hip_flags: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    bench_shapes: dict[str, int] = field(default_factory=dict)   # symbols overridden for timing (larger than the battery's)
    program: Reference | None = None   # the high-level input: a tair program (`{"file" | "text"}`) a generator compiles

    def timing_symbols(self) -> dict[str, int]:
        return {**self.shapes, **self.bench_shapes}

    @classmethod
    def load(cls, path: str | Path) -> "Manifest":
        path = Path(path).resolve()
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            raise ManifestError(f"{path}: invalid JSON: {e}") from None
        return cls.from_dict(data, path)

    @classmethod
    def from_dict(cls, d: dict, path: str | Path) -> "Manifest":
        path = Path(path)
        for key in ("name", "entry", "params") + (("launch",) if d.get("source") else ()):
            if key not in d:
                raise ManifestError(f"manifest missing required field {key!r}")
        params = []
        for p in d["params"]:
            if not all(k in p for k in ("name", "kind", "dtype")):
                raise ManifestError(f"param needs name, kind, dtype: {p}")
            if p["kind"] not in ("tensor", "scalar"):
                raise ManifestError(f"param {p['name']}: kind must be tensor or scalar")
            if p["dtype"] not in DTYPES:
                raise ManifestError(f"param {p['name']}: unknown dtype {p['dtype']!r}")
            if p.get("role", "in") not in ("in", "out", "inout"):
                raise ManifestError(f"param {p['name']}: role must be in, out or inout")
            params.append(Param(name=p["name"], kind=p["kind"], dtype=_dtype_of(p["dtype"]),
                                shape=list(p.get("shape", [])), role=p.get("role", "in"),
                                value=p.get("value"), init=p.get("init")))
        names = [p.name for p in params]
        if len(set(names)) != len(names):
            raise ManifestError("duplicate parameter names")
        launch = d.get("launch") or {}

        def dims(key):
            v = list(launch.get(key, [1]))
            if not 1 <= len(v) <= 3:
                raise ManifestError(f"launch.{key} needs 1 to 3 dims")
            return v + [1] * (3 - len(v))
        ref = d.get("reference") or {"kind": "none"}
        unknown = set(ref) - {"kind", "expr", "inputs", "output", "file", "function", "text"}
        if unknown:
            raise ManifestError(f"reference: unknown field(s) {sorted(unknown)}")
        reference = Reference(**{**ref, "kind": ref.get("kind", "none"), "inputs": list(ref.get("inputs", []))})
        if reference.kind not in REFERENCE_KINDS:
            raise ManifestError(f"reference.kind must be one of {REFERENCE_KINDS}, got {reference.kind!r}")
        if reference.kind in ("python", "torch") and not (reference.file and reference.function):
            raise ManifestError(f"{reference.kind} reference needs `file` and `function`")
        if reference.kind == "einsum" and not (reference.expr and reference.inputs and reference.output):
            raise ManifestError("einsum reference needs `expr`, `inputs` and `output`")
        if reference.kind == "tair" and not (reference.text or reference.file):
            raise ManifestError("tair reference needs `text` or `file`")
        shapes = {k: int(v) for k, v in d.get("shapes", {}).items()}
        dynamic = list(d.get("dynamic", []))
        for s in dynamic:
            if s not in shapes:
                raise ManifestError(f"dynamic symbol {s!r} is not in shapes")
        source = (path.parent / d["source"]).resolve() if d.get("source") else None
        if source is not None and not source.exists():
            raise ManifestError(f"source file not found: {source}")
        if source is None and reference.kind == "none":
            raise ManifestError("a manifest without a source needs a reference program")
        program = None
        if d.get("program"):
            pr = d["program"]
            if set(pr) - {"file", "text"} or not (pr.get("file") or pr.get("text")):
                raise ManifestError("program needs `file` or `text` (a tair program)")
            program = Reference("tair", file=pr.get("file"), text=pr.get("text"))
        if source is None and program is None:
            raise ManifestError("a manifest needs a HIP `source`, a tair `program`, or both")
        m = cls(name=d["name"], entry=d["entry"], params=params, grid=dims("grid"), block=dims("block"),
                lds=launch.get("lds", 0), shapes=shapes, dynamic=dynamic, path=path, source=source,
                arch=d.get("arch", "gfx950"), tolerance=d.get("tolerance", {}), reference=reference,
                hip_flags=list(d.get("hip_flags", [])), tags=list(d.get("tags", [])),
                bench_shapes={k: int(v) for k, v in d.get("bench_shapes", {}).items()}, program=program)
        for s in m.bench_shapes:
            if s not in shapes:
                raise ManifestError(f"bench_shapes names an unknown symbol {s!r}")
        m.resolve(m.timing_symbols())
        for name in m.tolerance:
            if name != "*" and name not in [p.name for p in m.outputs()]:
                raise ManifestError(f"tolerance names {name!r}, which is not an output tensor")
        m.resolve(m.shapes)   # every expression resolves at the default shapes
        return m

    # ---- resolution ----------------------------------------------------------
    def resolve(self, symbols: dict[str, int]) -> "Resolved":
        from .arch.model import load
        arch = load(self.arch)
        tensors, scalars = {}, {}
        for p in self.params:
            if p.kind == "tensor":
                tensors[p.name] = p.resolved_shape(symbols)
                if any(x < 0 for x in tensors[p.name]):
                    raise ManifestError(f"param {p.name}: negative dimension in {tensors[p.name]}")
            else:
                if p.value is None:
                    raise ManifestError(f"scalar param {p.name} needs a value")
                scalars[p.name] = (eval_scalar(p.value, symbols) if p.dtype in FLOAT_DTYPES
                                   else eval_expr(p.value, symbols))
        grid = tuple(eval_expr(e, symbols) for e in self.grid)
        block = tuple(eval_expr(e, symbols) for e in self.block)
        lds = eval_expr(self.lds, symbols)
        if any(g <= 0 for g in grid) or any(b <= 0 for b in block):
            raise ManifestError(f"launch dims must be positive: grid={grid} block={block}")
        if math.prod(block) > arch.res("max_workgroup_size"):
            raise ManifestError(f"block has more than {arch.res('max_workgroup_size')} threads: {block}")
        if not 0 <= lds <= arch.res("lds_per_workgroup"):
            raise ManifestError(f"launch.lds {lds} outside 0..{arch.res('lds_per_workgroup')}")
        return Resolved(symbols=dict(symbols), tensors=tensors, scalars=scalars, grid=grid, block=block, lds=lds)

    def outputs(self) -> list[Param]:
        return [p for p in self.params if p.kind == "tensor" and p.role in ("out", "inout")]

    def inputs(self) -> list[Param]:
        return [p for p in self.params if p.kind == "tensor" and p.role in ("in", "inout")]

    def tensors(self) -> list[Param]:
        return [p for p in self.params if p.kind == "tensor"]

    def param(self, name: str) -> Param:
        for p in self.params:
            if p.name == name:
                return p
        raise ManifestError(f"no parameter named {name!r}")

    def _tol(self, name: str) -> dict:
        return self.tolerance.get(name) or self.tolerance.get("*") or {}

    def tolerance_for(self, name: str) -> tuple[float, float]:
        t, default = self._tol(name), DEFAULT_TOL[str(self.param(name).dtype)]
        return float(t.get("rtol", default[0])), float(t.get("atol", default[1]))

    def cond_for(self, name: str) -> float:
        """Backward-error allowance for reductions: `cond` times the reference evaluated on the
        absolute values of its inputs is added to the tolerance (the classical bound for sums and
        matrix products accumulated in finite precision, in any order). 0 adds nothing."""
        return float(self._tol(name).get("cond", 0.0))

    def needs_scale(self) -> bool:
        return any(self.cond_for(p.name) > 0 for p in self.outputs())

    def to_dict(self) -> dict:
        return {"name": self.name, **({"source": str(self.source)} if self.source else {}),
                "entry": self.entry, "arch": self.arch, "params": [p.to_dict() for p in self.params],
                "launch": {"grid": self.grid, "block": self.block, "lds": self.lds},
                "shapes": self.shapes, "dynamic": self.dynamic, "tolerance": self.tolerance,
                "reference": self.reference.to_dict(), "hip_flags": self.hip_flags, "tags": self.tags,
                **({"bench_shapes": self.bench_shapes} if self.bench_shapes else {}),
                **({"program": {k: v for k, v in self.program.to_dict().items() if k != "kind"}} if self.program else {})}


@dataclass
class Resolved:
    symbols: dict[str, int]
    tensors: dict[str, tuple[int, ...]]
    scalars: dict[str, Any]
    grid: tuple[int, int, int]
    block: tuple[int, int, int]
    lds: int

    def to_dict(self) -> dict:
        return {"symbols": self.symbols, "tensors": {k: list(v) for k, v in self.tensors.items()},
                "scalars": self.scalars, "grid": list(self.grid), "block": list(self.block), "lds": self.lds}
