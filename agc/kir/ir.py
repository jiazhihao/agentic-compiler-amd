"""The structured SSA core shared by `kir` (one thread's program) and `wir` (one wave's schedule).

A function is a list of statements: `Op` (an operation with at most one result), `If` (two regions
and the values merged after them) and `Loop`. Values are defined once. The two IRs differ in their
operation vocabulary (`ops.py` of each package) and in what a value's `kind` says: `kir` values
have no kind (every value is per thread); `wir` values are `u` (uniform over the wave) or `v` (one
per lane).

Types: `i1`, `i8`..`i64`, `u8`..`u64`, `f16`, `bf16`, `f32`, `f64`, `ptr<T>` (a pointer into a
global tensor), `lds<T>` (a pointer into the workgroup's shared memory).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Iterator, Union


class IRError(ValueError):
    pass


@dataclass(frozen=True)
class Type:
    kind: str                    # "int" | "float" | "bool" | "ptr" | "vec"
    bits: int = 0
    signed: bool = False
    elem: "Type | None" = None   # pointee, or the element of a vector
    name: str = ""               # spelling of float types ("bf16" differs from "f16")
    count: int = 0               # elements of a vector (`f32x2`: what one wide load gives a lane)

    def __str__(self) -> str:
        if self.kind == "bool":
            return "i1"
        if self.kind == "int":
            return f"{'i' if self.signed else 'u'}{self.bits}"
        if self.kind == "float":
            return self.name
        if self.kind == "vec":
            return f"{self.elem}x{self.count}"
        return f"{self.name or 'ptr'}<{self.elem}>"

    @property
    def is_lds(self) -> bool:
        return self.kind == "ptr" and self.name == "lds"

    @property
    def is_int(self) -> bool:
        return self.kind == "int"

    @property
    def is_float(self) -> bool:
        return self.kind == "float"

    @property
    def is_bool(self) -> bool:
        return self.kind == "bool"

    @property
    def is_ptr(self) -> bool:
        return self.kind == "ptr"

    @property
    def is_vec(self) -> bool:
        return self.kind == "vec"

    @property
    def size(self) -> int:
        """Bytes in memory."""
        if self.is_vec:
            return self.elem.size * self.count
        return 8 if self.is_ptr else 1 if self.is_bool else self.bits // 8


_T = re.compile(r"^(?:(i1)|([iu])(8|16|32|64)|(f16|bf16|f32|f64)|ptr<(.+)>|([iuf]\d+)x(\d+)|lds<(.+)>)$")
_FLOAT_BITS = {"f16": 16, "bf16": 16, "f32": 32, "f64": 64}


def T(text: "str | Type") -> Type:
    if isinstance(text, Type):
        return text
    m = _T.match(text.strip())
    if not m:
        raise IRError(f"bad type {text!r}")
    if m.group(1):
        return Type("bool", 1)
    if m.group(2):
        return Type("int", int(m.group(3)), m.group(2) == "i")
    if m.group(4):
        return Type("float", _FLOAT_BITS[m.group(4)], True, name=m.group(4))
    if m.group(6):
        e = T(m.group(6))
        return Type("vec", e.bits * int(m.group(7)), elem=e, count=int(m.group(7)))
    if m.group(8):
        return Type("ptr", 64, elem=T(m.group(8)), name="lds")
    return Type("ptr", 64, elem=T(m.group(5)))


def vec(elem: Type, n: int) -> Type:
    return Type("vec", elem.bits * n, elem=elem, count=n)


I1, I32, U32, I64, U64, F32 = T("i1"), T("i32"), T("u32"), T("i64"), T("u64"), T("f32")


@dataclass(eq=False)
class Value:
    name: str
    type: Type
    kind: str | None = None      # wir: "u" | "v"

    def __repr__(self) -> str:
        return f"%{self.name}"


@dataclass(frozen=True)
class Const:
    value: "int | float | bool"
    type: Type

    def __repr__(self) -> str:
        return f"{fmt_const(self.value, self.type)}:{self.type}"


Operand = Union[Value, Const]


def fmt_const(value, t: Type) -> str:
    if t.is_bool:
        return "true" if value else "false"
    if t.is_float:
        return repr(float(value))            # a float32 value is exact in a Python float, so this round-trips
    return str(int(value))


@dataclass(eq=False)
class Op:
    name: str
    args: list[Operand]
    result: Value | None = None
    attrs: dict = field(default_factory=dict)
    site: str | None = None      # the decision site this operation belongs to
    loc: str | None = None       # source line:col


@dataclass(eq=False)
class Merge:
    """The value after an `If`: `a` when the region `then` ran, `b` otherwise."""
    result: Value
    a: Operand
    b: Operand


@dataclass(eq=False)
class If:
    cond: Operand
    then: list = field(default_factory=list)
    orelse: list = field(default_factory=list)
    merges: list[Merge] = field(default_factory=list)
    mode: str | None = None      # wir: "where" (a lane mask) | "branch" (a uniform condition)
    site: str | None = None
    loc: str | None = None


@dataclass(eq=False)
class Loop:
    """A loop with loop-carried values. `carried[i]` holds `init[i]` in the first iteration and
    `next[i]` (a value defined in `head` or `body`) afterwards. Every iteration first runs `head`,
    which computes `cond`; when it is true `body` runs, otherwise the loop ends and `out[i]` is the
    value `carried[i]` has at that point. Each thread leaves the loop on its own."""
    carried: list[Value] = field(default_factory=list)
    init: list[Operand] = field(default_factory=list)
    next: list[Operand] = field(default_factory=list)
    out: list[Value] = field(default_factory=list)
    head: list = field(default_factory=list)
    cond: Operand | None = None
    body: list = field(default_factory=list)
    site: str | None = None
    loc: str | None = None


Stmt = Union[Op, If, Loop]


@dataclass(eq=False)
class Func:
    name: str
    params: list[Value]
    body: list = field(default_factory=list)
    dialect: str = "kir"

    def walk(self) -> Iterator[Stmt]:
        yield from walk(self.body)


def walk(body: list) -> Iterator[Stmt]:
    for s in body:
        yield s
        if isinstance(s, If):
            yield from walk(s.then)
            yield from walk(s.orelse)
        elif isinstance(s, Loop):
            yield from walk(s.head)
            yield from walk(s.body)


def operands(s: Stmt) -> list[Operand]:
    """The values a statement reads itself (not those its regions read)."""
    if isinstance(s, Op):
        return list(s.args)
    if isinstance(s, If):
        return [s.cond] + [x for m in s.merges for x in (m.a, m.b)]
    return [*s.init, *s.next, s.cond]


def results(s: Stmt) -> list[Value]:
    if isinstance(s, Op):
        return [s.result] if s.result is not None else []
    if isinstance(s, If):
        return [m.result for m in s.merges]
    return [*s.carried, *s.out]


class Namer:
    """Fresh value names."""

    def __init__(self, taken=()):
        self.taken = set(taken)
        self.n = 0

    def fresh(self, hint: str = "t") -> str:
        hint = re.sub(r"[^A-Za-z0-9_.]", "_", hint) or "t"
        if hint not in self.taken and not hint[-1].isdigit():
            self.taken.add(hint)
            return hint
        while True:
            name = f"{hint}{self.n}" if not hint[-1].isdigit() else f"{hint}_{self.n}"
            self.n += 1
            if name not in self.taken:
                self.taken.add(name)
                return name


def number_sites(f: Func) -> None:
    """Give every statement that carries decisions a stable site name: `if0`, `loop0`, `load0`,
    `store0`, ... in program order. Statements that already have one keep it."""
    counts: dict[str, int] = {}
    taken = {s.site for s in f.walk() if s.site}

    def name(kind: str) -> str:
        while True:
            n = counts.get(kind, 0)
            counts[kind] = n + 1
            if f"{kind}{n}" not in taken:
                return f"{kind}{n}"

    for s in f.walk():
        if s.site:
            continue
        if isinstance(s, If):
            s.site = name("if")
        elif isinstance(s, Loop):
            s.site = name("loop")
        elif s.name in ("load", "store", "fma", "call"):
            s.site = name(s.name)
