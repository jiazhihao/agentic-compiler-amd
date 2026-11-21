"""Clang's AST to `kir`: a bounded subset of HIP C++.

Supported (`SUPPORTED` below is the table): one `__global__`
entry with scalar and pointer parameters; scalar and pointer locals; integer and floating-point
arithmetic, comparisons, casts, `__builtin_bit_cast`; `if` / `else`, `for`, `while`, `do`;
subscripts and pointer arithmetic; `threadIdx`, `blockIdx`, `blockDim`, `gridDim`; calls of
functions defined in the same translation unit (inlined; templates as Clang instantiated them).
Anything else is refused with its source location; all refusals of a kernel are reported at once.

Mutable locals become SSA values: an `if` merges the variables its branches assign, a loop carries
the variables its body assigns.
"""
from __future__ import annotations

import re
from pathlib import Path

from ..kir.ir import Const, Func, I1, I64, If, Loop, Merge, Namer, Op, T, Type, Value, number_sites
from ..kir.verify import assert_ok
from . import clang_ast
from .clang_ast import FrontendError
from .objects import Arr, MemVar, Obj, Objects, Rec, leaves, scalar_leaf, size_of

SUPPORTED = {
    "Statements": "compound, declaration, expression, `if`/`else` (with an init statement or a condition variable), `for`, "
                  "`while` (the condition may assign), `do`, `return`, `break`, `continue`",
    "Types": "`bool`, 8- to 64-bit integers, `float`, `double`, pointers and references to them, enumerations, typedefs and "
             "aliases; structs and classes (layouts from Clang), arrays of them, HIP's `float4` family, the compiler's "
             "vector types (`ext_vector_type`)",
    "Expressions": "arithmetic, bitwise, shifts, comparisons, `&&` `||` `!`, `?:`, assignment and compound assignment "
                   "(also as a location), `++` `--`, casts, `__builtin_bit_cast`, subscripts, `*p`, `&x`, pointer arithmetic "
                   "and comparison, member access, braced initializers, constructors, `this`",
    "Builtins": "`threadIdx`, `blockIdx`, `blockDim`, `gridDim` (`.x .y .z`), `warpSize`, `__builtin_assume`, "
                "`__builtin_expect`, `__lane_id`, `__shfl`, `__shfl_up`, `__shfl_down`, `__shfl_xor` (32-bit values), "
                "`std::numeric_limits`, `make_float4` and its family",
    "Math": "`exp`, `tanh`, `sqrt`, `rsqrt`, `log`, `log2`, `exp2`, `fabs`, `floor`, `trunc`, `rint`, `fmax`, `fmin`, "
            "`copysign`, `ldexp` on `float`",
    "Calls": "functions with a body in the translation unit, inlined (parameters by value or by reference, default "
             "arguments, records returned by value, references returned); templates and member templates as instantiated; "
             "member functions, overloaded operators, function objects; captureless lambdas; `__syncthreads`",
    "Objects": "a thread's own structs, arrays and address-taken variables, when every access is at a known place (they "
               "become values; what stays in memory is refused by name); namespace-scope constants",
    "Shared memory": "`__shared__` arrays of scalars (one or more dimensions), `extern __shared__ T x[]` sized by the launch",
    "Not yet": "`double` math, `sin` `cos` `pow`, atomics, lambdas that capture, unions, `switch`, `goto`, "
               "library classes built on storage this frontend cannot see through (hipcub / rocPRIM)",
}
_BASE = {"int": "i32", "unsigned int": "u32", "long": "i64", "unsigned long": "u64", "long long": "i64",
         "unsigned long long": "u64", "short": "i16", "unsigned short": "u16", "char": "i8", "signed char": "i8",
         "unsigned char": "u8", "bool": "i1", "float": "f32", "double": "f64", "_Float16": "f16", "__int128": None,
         # typedefs Clang leaves sugared in some positions
         "int8_t": "i8", "uint8_t": "u8", "int16_t": "i16", "uint16_t": "u16", "int32_t": "i32", "uint32_t": "u32",
         "int64_t": "i64", "uint64_t": "u64", "size_t": "u64", "ptrdiff_t": "i64"}
_BUILTIN_VARS = {"threadIdx": "tid", "blockIdx": "bid", "blockDim": "bdim", "gridDim": "gdim"}
_BINARY = {"+": "add", "-": "sub", "*": "mul", "/": "div", "%": "rem", "&": "and", "|": "or", "^": "xor",
           "<<": "shl", ">>": "shr", "<": "lt", ">": "gt", "<=": "le", ">=": "ge", "==": "eq", "!=": "ne"}
# math calls that are one `kir` operation: C names, their `std::` overloads, and the builtins they reach
_MATH1 = {**{n + s: op for n, op in (("exp", "exp"), ("tanh", "tanh"), ("sqrt", "sqrt"), ("fabs", "abs"), ("floor", "floor"),
                                      ("trunc", "trunc"), ("rint", "rndne"), ("nearbyint", "rndne"), ("log", "log"),
                                      ("log2", "log2"), ("exp2", "exp2"), ("rsqrt", "rsqrt"))
             for s in ("f", "")},
          **{f"__builtin_{n}f": op for n, op in (("exp", "exp"), ("tanh", "tanh"), ("sqrt", "sqrt"), ("fabs", "abs"),
                                                 ("floor", "floor"), ("trunc", "trunc"), ("rint", "rndne"), ("log", "log"),
                                                 ("log2", "log2"), ("exp2", "exp2"))},
          "abs": "abs"}
_MATH2 = {**{n + s: op for n, op in (("fmax", "max"), ("fmin", "min"), ("copysign", "copysign")) for s in ("f", "")},
          "__builtin_fmaxf": "max", "__builtin_fminf": "min", "__builtin_copysignf": "copysign", "max": "max", "min": "min"}
_WRAPPERS = {"ParenExpr", "ConstantExpr", "ExprWithCleanups", "MaterializeTemporaryExpr", "SubstNonTypeTemplateParmExpr",
             "CXXBindTemporaryExpr", "ImplicitValueInitExpr"}
_CASTS = {"ImplicitCastExpr", "CStyleCastExpr", "CXXStaticCastExpr", "CXXFunctionalCastExpr", "CXXReinterpretCastExpr",
          "CXXConstCastExpr"}


def fill_locations(nodes) -> None:
    """Clang's JSON omits a location's `line` when it equals the previous location's: restore it."""
    last = [0]

    def go(n):
        if isinstance(n, dict):
            if "offset" in n and ("col" in n or "line" in n):
                if "line" in n:
                    last[0] = n["line"]
                else:
                    n["line"] = last[0]
            for v in n.values():
                go(v)
        elif isinstance(n, list):
            for v in n:
                go(v)

    go(nodes)


def is_ref(spelled: str) -> bool:
    """Whether a type as Clang prints it is a reference (`float &`, `float &__restrict`, `T &&`)."""
    return re.search(r"&\s*(?:(?:__restrict|restrict|const)\s*)*$", spelled) is not None


def escaping(body: dict) -> set:
    """Declarations whose address the statements take or bind a reference to: every mention that is neither
    a read of the value nor the left side of an assignment."""
    out = set()

    def go(n, plain: bool):
        if not isinstance(n, dict):
            return
        k = n.get("kind")
        if k == "DeclRefExpr":
            if not plain and (n.get("referencedDecl") or {}).get("kind") in ("VarDecl", "ParmVarDecl"):
                out.add(n["referencedDecl"]["id"])
            return
        kids = n.get("inner", [])
        if k == "ParenExpr":
            for c in kids:
                go(c, plain)
            return
        if k == "ImplicitCastExpr" and n.get("castKind") == "LValueToRValue":
            for c in kids:
                go(c, True)
            return
        assign = (k == "BinaryOperator" and n.get("opcode") == "=") or k == "CompoundAssignOperator" or \
            (k == "UnaryOperator" and n.get("opcode") in ("++", "--"))
        for i, c in enumerate(kids):
            go(c, assign and i == 0)

    go(body, False)
    return out


def loc_of(n: dict) -> str:
    for key in ("loc", "range"):
        d = n.get(key) or {}
        d = d.get("begin", d)
        d = d.get("expansionLoc", d)
        if "line" in d:
            return f"{d['line']}:{d.get('col', 0)}"
    return "?"


class _Abort(Exception):
    pass


class Closure:
    """A captureless lambda as a compile-time value: calling it inlines its body."""

    def __init__(self, method: dict):
        self.method = method


class Lowerer(Objects):
    Abort = _Abort

    def __init__(self, source: str | Path, entry: str, flags=None, mcpu: str = "gfx950", include_dirs=()):
        self.source, self.entry = Path(source), entry
        self.dump_args = dict(flags=flags, mcpu=mcpu, include_dirs=include_dirs)
        # functions with a body, by (name, type): node ids differ between Clang runs, so a callee found
        # in another dump is matched by its name and signature
        self.funcs: dict[tuple, list] = {}
        self.fetched: set[str] = set()
        self.unsupported: list[dict] = []
        self.namer = Namer()
        self.blocks: list[list] = []
        self.vars: dict[str, object] = {}                  # declaration id -> its current SSA value
        self.names: dict[str, str] = {}
        self.depth = 0
        # the functions being lowered (the entry, then inlined calls): the key of the "has returned" flag, of
        # the returned value, and the (break, continue) flag keys of the loops around the current statement
        self.ctx: list[dict] = []
        self.serial = 0
        self.dims: dict[int, tuple] = {}                   # pointer value -> the dimensions of the array it points into
        self.entry_block: list | None = None
        self.typedefs: dict[str, str] | None = None
        self.init_objects()

    # ---- declarations --------------------------------------------------------------------------
    def fetch(self, name: str) -> None:
        if name in self.fetched:
            return
        self.fetched.add(name)
        nodes = clang_ast.dump(self.source, name, **self.dump_args)
        fill_locations(nodes)

        def index(n):
            if isinstance(n, dict):
                if n.get("kind") in ("FunctionDecl", "CXXMethodDecl") and any(c.get("kind") == "CompoundStmt" for c in n.get("inner", [])):
                    self.funcs.setdefault((n.get("name"), n.get("type", {}).get("qualType")), []).append(n)
                for c in n.get("inner", []):
                    index(c)

        for n in nodes:
            index(n)

    def refuse(self, n: dict, what: str):
        self.unsupported.append({"loc": loc_of(n), "what": what})

    def type_of(self, n: dict, key: str = "type") -> Type | None:
        q = n.get(key) or {}
        return self.ctype(q.get("desugaredQualType") or q.get("qualType") or "", n)

    def ctype(self, s: str, n: dict | None = None) -> Type | None:
        s = re.sub(r"\b(const|volatile|__restrict|restrict)\b", "", s).strip()
        s = re.sub(r"\s+", " ", s)
        if s.endswith("*"):
            e = self.ctype(s[:-1], n)
            return T(f"ptr<{e}>") if e is not None else None
        if s == "void":
            return None
        if _BASE.get(s):
            return T(_BASE[s])
        if self.typedefs is None:                           # `typedef float T;` and `using T = float;` in the source and its
            self.typedefs = {}                              # includes: Clang leaves such names inside pointer types
            from ..runtime.toolchain import _local_includes
            texts = [self.source.read_text(), *_local_includes(self.source, self.dump_args.get("include_dirs") or ()).values()]
            for text in texts:
                for m in re.finditer(r"\btypedef\s+([\w\s:]+?)\s+(\w+)\s*;", text):
                    self.typedefs.setdefault(m.group(2), m.group(1).strip())
                for m in re.finditer(r"\busing\s+(\w+)\s*=\s*([\w\s:]+?)\s*;", text):
                    self.typedefs.setdefault(m.group(1), m.group(2).strip())
                for m in re.finditer(r"\benum\s+(?:class\s+|struct\s+)?(\w+)\s*(?::\s*([\w\s:]+?))?\s*\{", text):
                    self.typedefs.setdefault(m.group(1), (m.group(2) or "int").strip())      # an enumeration: its integer
        if s in self.typedefs and self.typedefs[s] != s:
            return self.ctype(self.typedefs[s], n)
        if n is not None:
            self.refuse(n, f"type `{s}`")
        return None

    # ---- emission ------------------------------------------------------------------------------
    def emit(self, name: str, args: list, t: Type | None, node: dict | None = None, hint: str = "t", **attrs):
        r = Value(self.namer.fresh(hint), t) if t is not None else None
        self.blocks[-1].append(Op(name, list(args), r, attrs, loc=loc_of(node) if node else None))
        return r

    def cast(self, x, t: Type, node=None):
        if x.type == t:
            return x
        if isinstance(x, Const) and not x.type.is_ptr and not t.is_ptr:
            return Const(_fold_cast(x.value, x.type, t), t)
        if t.is_bool:
            return self.emit("ne", [x, Const(0, x.type)], I1, node)
        if x.type.is_ptr or t.is_ptr:
            if x.type.is_ptr and t.is_ptr:
                return self.emit("bitcast", [x], t, node)
            self.refuse(node or {}, f"conversion between {x.type} and {t}")
            raise _Abort
        return self.emit("cast", [x], t, node)

    # ---- lvalues -------------------------------------------------------------------------------
    def lvalue(self, n: dict):
        k = n.get("kind")
        if k in _WRAPPERS:
            return self.lvalue(n["inner"][0])
        if k == "DeclRefExpr":
            d = n.get("referencedDecl", {})
            if d.get("id") in self.vars:
                v = self.vars[d["id"]]
                return ("mem", v.ptr) if isinstance(v, MemVar) else ("var", d["id"])
            self.refuse(n, f"reference to `{d.get('name')}` ({d.get('kind')})")
            raise _Abort
        if k == "ArraySubscriptExpr":
            base, idx = self.rvalue(n["inner"][0]), self.rvalue(n["inner"][1])
            if not base.type.is_ptr:
                base, idx = idx, base
            i = self.cast(idx, I64, n)
            d = self.desc.get(id(base))
            if d is not None:                               # elements that are records or arrays: by their size
                elem = d
                i = self.fold("mul", [i, Const(size_of(elem), I64)], I64, n)
                q = self.emit("gep", [self.retype(base, T("u8"), n), i], Type("ptr", 64, elem=T("u8"), name=base.type.name), n, "p")
                if isinstance(elem, Type):
                    q = self.retype(q, elem, n)
                else:
                    self.desc[id(q)] = elem
                return ("mem", q)
            dims = self.dims.get(id(base), ())
            if len(dims) > 1:                               # a row of an array of rows: the address of its first element
                step = 1
                for dd in dims[1:]:
                    step *= dd
                i = self.fold("mul", [i, Const(step, I64)], I64, n)
            p = self.emit("gep", [base, i], base.type, n, "p")
            if len(dims) > 1:
                self.dims[id(p)] = dims[1:]
            return ("mem", p)
        if k == "UnaryOperator" and n.get("opcode") == "*":
            return ("mem", self.rvalue(n["inner"][0]))
        if k == "MemberExpr":
            p = self.object_pointer(n["inner"][0], bool(n.get("isArrow")))
            d = self.desc.get(id(p))
            f = next((x for x in d.fields if x[0] == n.get("name")), None) if isinstance(d, Rec) else None
            if f is None:
                self.refuse(n, f"member `{n.get('name')}` of a value this frontend does not describe as a record")
                raise _Abort
            return ("mem", self.at(p, f[2], f[1], n))
        if k in ("CallExpr", "CXXMemberCallExpr", "CXXOperatorCallExpr"):       # a call that returns a reference
            x = self.call_any(n)
            if isinstance(x, tuple):
                return x
            if isinstance(x, Obj):
                return ("mem", x.ptr)
            self.refuse(n, "a call used as an assignable location that does not return a reference")
            raise _Abort
        if k in _CASTS and n.get("castKind") in ("NoOp", "DerivedToBase", "UncheckedDerivedToBase"):
            return self.lvalue(n["inner"][0])
        if k in ("CXXConstructExpr", "CXXTemporaryObjectExpr", "InitListExpr", "ConditionalOperator"):
            x = self.rvalue(n)
            if isinstance(x, Obj):
                return ("mem", x.ptr)
        if (k == "BinaryOperator" and n.get("opcode") == "=") or k == "CompoundAssignOperator" or \
                (k == "UnaryOperator" and n.get("opcode") in ("++", "--") and not n.get("isPostfix")):
            self.rvalue(n)                                  # the assignment, then its left side as the location
            return self.lvalue(n["inner"][0])
        self.refuse(n, f"`{k}` as an assignable location")
        raise _Abort

    def object_pointer(self, base: dict, arrow: bool) -> Value:
        """The address of the object a member access or member call is made on."""
        if arrow:
            return self.rvalue(base)
        inner = base
        while inner.get("kind") in _WRAPPERS or (inner.get("kind") in _CASTS and inner.get("castKind") in ("NoOp", "DerivedToBase")):
            inner = inner["inner"][0]
        if inner.get("valueCategory") == "lvalue" or inner.get("kind") in ("DeclRefExpr", "MemberExpr", "ArraySubscriptExpr"):
            lv = self.lvalue(inner)
            if lv[0] == "var":
                return self.demote(lv[1], base).ptr
            return lv[1]
        x = self.rvalue(inner)
        if isinstance(x, Obj):
            return x.ptr
        self.refuse(base, "a member of a value that is not an object")
        raise _Abort

    def read(self, lv, node=None):
        if lv[0] == "var":
            return self.vars[lv[1]]
        d = self.desc.get(id(lv[1]))
        if d is not None:
            return Obj(lv[1], d)
        if id(lv[1]) in self.dims:                          # an array of scalars: used through its pointer
            return lv[1]
        return self.emit("load", [lv[1]], lv[1].type.elem, node, "v")

    def write(self, lv, x, node=None):
        if lv[0] == "var":
            self.vars[lv[1]] = x
        elif isinstance(x, Obj):
            self.copy_object(lv[1], x.ptr, x.desc, node)
        else:
            self.emit("store", [lv[1], self.cast(x, lv[1].type.elem, node)], None, node)

    def lvalue_type(self, lv) -> Type:
        return self.vars[lv[1]].type if lv[0] == "var" else lv[1].type.elem

    def is_object(self, lv) -> bool:
        return lv[0] == "mem" and id(lv[1]) in self.desc

    # ---- expressions ---------------------------------------------------------------------------
    def rvalue(self, n: dict):
        k = n.get("kind")
        if k == "SubstNonTypeTemplateParmExpr":             # a template's value parameter: its argument
            return self.rvalue(n["inner"][-1])
        if k in _WRAPPERS:
            return self.rvalue(n["inner"][0])
        if k in _CASTS:
            return self.cast_expr(n)
        if k == "IntegerLiteral":
            return Const(int(n["value"]), self.type_of(n))
        if k == "FloatingLiteral":
            t = self.type_of(n)
            return Const(_fold_cast(float(n["value"]), T("f64"), t), t)
        if k == "CXXBoolLiteralExpr":
            return Const(bool(n["value"]), I1)
        if k in ("CXXNullPtrLiteralExpr", "GNUNullExpr"):
            t = self.type_of(n)
            return Const(0, t if t is not None and t.is_ptr else T("ptr<u8>"))
        if k == "CharacterLiteral":
            return Const(int(n["value"]), self.type_of(n))
        if k == "DeclRefExpr":                              # an lvalue used where its address is not needed
            d = n.get("referencedDecl", {})
            if d.get("id") not in self.vars and d.get("kind") == "VarDecl":
                return self.global_constant(d, n)
            if d.get("kind") == "EnumConstantDecl":
                v = self.enum_constant(d, n)
                if v is None:
                    raise _Abort
                return v
            return self.read(self.lvalue(n), n)
        if k == "CXXThisExpr":
            return self.ctx[-1]["this"]
        if k == "MemberExpr":
            return self.read(self.lvalue(n), n)
        if k in ("CXXMemberCallExpr",):
            x = self.call_any(n)
            return self.read(x, n) if isinstance(x, tuple) else x
        if k == "CXXConstructExpr" and "(lambda" in ((n.get("type") or {}).get("qualType") or "") and n.get("inner"):
            return self.rvalue(n["inner"][0])                # a closure copied: the same compile-time value
        if k in ("CXXConstructExpr", "CXXTemporaryObjectExpr", "InitListExpr", "CXXScalarValueInitExpr"):
            q = n.get("type") or {}
            d = self.describe(q.get("desugaredQualType") or q.get("qualType") or "", None)
            if isinstance(d, (Rec, Arr)):
                p = self.new_object(d, "tmp", n)
                if k == "InitListExpr":
                    self.init_list(p, d, n)
                else:
                    self.construct(p, d, n)
                return Obj(p, d)
            if k == "CXXScalarValueInitExpr" and isinstance(d, Type):
                return Const(0.0 if d.is_float else 0, d)
            if k == "InitListExpr" and isinstance(d, Type) and len(n.get("inner", [])) == 1:
                return self.cast(self.rvalue(n["inner"][0]), d, n)
        if k == "_Lowered":                                  # an operand this frontend already computed
            return n["value"]
        if k == "PseudoObjectExpr":
            return self.builtin_var(n)
        if k == "BuiltinBitCastExpr":
            return self.bitcast(self.rvalue(n["inner"][0]), self.type_of(n), n)
        if k == "BinaryOperator":
            return self.binary(n)
        if k == "CompoundAssignOperator":
            return self.compound_assign(n)
        if k == "UnaryOperator":
            return self.unary(n)
        if k == "ConditionalOperator":
            return self.conditional(n)
        if k == "CallExpr":
            x = self.call_any(n)
            return self.read(x, n) if isinstance(x, tuple) else x
        if k == "ArraySubscriptExpr":
            return self.read(self.lvalue(n), n)
        if k == "LambdaExpr":
            return self.closure(n)
        if k == "CXXConstructExpr" and len(n.get("inner", [])) == 1:      # a copy or a move of a value
            return self.rvalue(n["inner"][0])
        if k == "CXXOperatorCallExpr":
            x = self.call_any(n)
            return self.read(x, n) if isinstance(x, tuple) else x
        self.refuse(n, f"expression `{k}`")
        raise _Abort

    def call_any(self, n: dict):
        """A call of any kind. Its value: an operand, an object (`Obj`), or ("mem", pointer) when the callee
        returns a reference."""
        k = n.get("kind")
        if k == "CallExpr":
            return self.call(n)
        if k == "CXXMemberCallExpr":
            callee, args = n["inner"][0], n["inner"][1:]
            while callee.get("kind") in _WRAPPERS or callee.get("kind") in _CASTS:
                callee = callee["inner"][0]
            if callee.get("kind") != "MemberExpr":
                self.refuse(n, "a member call through something other than a member")
                raise _Abort
            base = callee["inner"][0]
            while base.get("kind") in _WRAPPERS or base.get("kind") in _CASTS:
                base = base["inner"][0]
            if base.get("kind") == "DeclRefExpr" and (base.get("referencedDecl") or {}).get("name") == "warpSize":
                return self.cast(self.global_constant({"name": "warpSize"}, n), self.type_of(n) or T("i32"), n)   # its conversion to int
            obj = self.object_pointer(callee["inner"][0], bool(callee.get("isArrow")))
            d = self.desc.get(id(obj))
            m = self.method(d, callee.get("name"), len(args), n, {"id": callee.get("referencedMemberDecl"), "type": None})
            if m is None:
                self.refuse(n, f"member function `{callee.get('name')}` (no body for it in this translation unit)")
                raise _Abort
            return self.inline(m, args, n, f"`{callee.get('name')}`", this=obj, this_desc=d)
        # an overloaded operator: a lambda's call, or a member operator of a record
        ref = next((x.get("referencedDecl") for x in _collect(n["inner"][0]) if x.get("kind") == "DeclRefExpr"), None) or {}
        name, target_node, args = ref.get("name", "?"), n["inner"][1], n["inner"][2:]
        probe = target_node
        while probe.get("kind") in _WRAPPERS or (probe.get("kind") in _CASTS and probe.get("castKind") in ("NoOp", "LValueToRValue")):
            probe = probe["inner"][0]
        held = self.vars.get((probe.get("referencedDecl") or {}).get("id")) if probe.get("kind") == "DeclRefExpr" else None
        if isinstance(held, Closure) or probe.get("kind") == "LambdaExpr":
            target = held if isinstance(held, Closure) else self.closure(probe)
            return self.inline(target.method, args, n, "a lambda")
        obj = self.object_pointer(target_node, False)
        d = self.desc.get(id(obj))
        m = self.method(d, name, len(args), n, ref) if isinstance(d, Rec) and (d.fields or name == "operator()") else None
        if m is not None:
            return self.inline(m, args, n, f"`{name}`", this=obj, this_desc=d)
        if name == "operator=" and len(args) == 1 and d is not None:        # the implicit assignment: a copy
            src = self.rvalue(args[0])
            if isinstance(src, Obj):
                self.copy_object(obj, src.ptr, d, n)
                return ("mem", obj)
        self.refuse(n, f"the overloaded `{name}`")
        raise _Abort

    def global_constant(self, ref: dict, n: dict):
        """A namespace-scope constant (`constexpr float inf = ...;`): its initializer, which must fold."""
        name = ref.get("name")
        if name == "warpSize":                               # HIP's name for the wave size
            from ..arch.model import load as load_arch
            return Const(int(load_arch(self.dump_args.get("mcpu") or "gfx950").res("wave_size")), T("i32"))
        if name not in self.globals:
            self.globals[name] = None
            nodes = clang_ast.dump(self.source, name, **self.dump_args)
            fill_locations(nodes)
            decl = next((x for x in (y for top in nodes for y in _collect(top)) if x.get("kind") == "VarDecl"
                         and x.get("name") == name and x.get("inner")), None)
            if decl is not None:
                saved, self.blocks = self.blocks, [[]]
                try:
                    inits = [c for c in decl.get("inner", []) if "Attr" not in c.get("kind", "") and c.get("kind") != "TemplateArgument"]
                    if not inits:
                        raise _Abort
                    v = self.rvalue(inits[0])
                    t = self.type_of(decl)
                    v = self.cast(v, t, n) if t is not None and not isinstance(v, (Obj, Closure)) else v
                    self.globals[name] = v if isinstance(v, Const) else None
                except _Abort:
                    pass
                finally:
                    self.blocks = saved
        if self.globals[name] is None:
            self.refuse(n, f"reference to `{name}`, which is not a local variable or a constant this frontend can evaluate")
            raise _Abort
        return self.globals[name]

    def closure(self, n: dict) -> Closure:
        record = next((c for c in n.get("inner", []) if c.get("kind") == "CXXRecordDecl"), None)
        if record is None or any(c.get("kind") == "FieldDecl" for c in record.get("inner", [])):
            self.refuse(n, "a lambda that captures")
            raise _Abort
        method = next((c for c in record.get("inner", []) if c.get("kind") == "CXXMethodDecl" and c.get("name") == "operator()"
                       and any(x.get("kind") == "CompoundStmt" for x in c.get("inner", []))), None)
        if method is None:
            self.refuse(n, "a lambda without a body (a generic lambda)")
            raise _Abort
        return Closure(method)

    def bitcast(self, x, t: Type, n):
        if x.type == t:
            return x
        if isinstance(x, Const):
            return Const(_fold_bitcast(x.value, x.type, t), t)
        return self.emit("bitcast", [x], t, n)

    def cast_expr(self, n: dict):
        ck, inner = n.get("castKind"), n["inner"][-1]
        if ck == "LValueToRValue":
            probe = inner
            while probe.get("kind") in _WRAPPERS:
                probe = probe["inner"][0]
            ref = probe.get("referencedDecl") or {}
            if probe.get("kind") == "DeclRefExpr" and ref.get("id") not in self.vars and ref.get("kind") == "VarDecl":
                return self.global_constant(ref, n)          # a namespace-scope constant
            if probe.get("kind") == "ConditionalOperator":   # `c ? a : b` of two variables: the value of the one chosen
                return self.rvalue(probe)
            return self.read(self.lvalue(inner), n)
        if ck in ("FunctionToPointerDecay", "BuiltinFnToFnPtr"):
            self.refuse(n, "a function used as a value")
            raise _Abort
        if ck == "NullToPointer":
            t = self.type_of(n)
            return Const(0, t if t is not None else T("ptr<u8>"))
        if ck == "ArrayToPointerDecay":                     # an array (or a row of one) used as a pointer to its elements
            lv = self.lvalue(inner)
            p = self.vars[lv[1]] if lv[0] == "var" else lv[1]
            d = self.desc.get(id(p))
            if isinstance(d, Arr):                          # an array of records or of arrays: a pointer to the first one
                return self.at(p, 0, d.elem, n)
            return p
        x = self.rvalue(inner)
        if isinstance(x, (Closure, Obj)):
            if ck in ("NoOp", "ConstructorConversion", "UserDefinedConversion", "DerivedToBase", "UncheckedDerivedToBase"):
                return x
            self.refuse(n, f"cast `{ck}` of an object")
            raise _Abort
        if ck == "BitCast" and x.type.is_ptr:               # a pointer seen as a pointer to something else
            q = n.get("type") or {}
            d = self.describe(q.get("desugaredQualType") or q.get("qualType") or "", n)
            if isinstance(d, tuple):                        # ... to a record or an array
                y = self.emit("gep", [self.retype(x, T("u8"), n), Const(0, I64)], Type("ptr", 64, elem=T("u8"), name=x.type.name), n, "p")
                self.desc[id(y)] = d[1]
                return y
            if isinstance(d, Type) and d.is_ptr:
                return self.retype(x, d.elem, n)
            raise _Abort
        if ck == "NoOp" and x.type.is_ptr and (id(x) in self.desc or "[" in ((n.get("type") or {}).get("qualType") or "")):
            return x                                        # an array or a record, with `const` added
        if ck in ("NoOp", "ConstructorConversion", "UserDefinedConversion") and x.type == self.type_of(n):
            return x
        if ck == "PointerToBoolean":                        # `if (p)`: a pointer into a tensor is not null
            return self.emit("ne", [x, Const(0, x.type)], I1, n) if isinstance(x, Value) else Const(False, I1)
        if ck in ("IntegralCast", "IntegralToFloating", "FloatingToIntegral", "FloatingCast", "IntegralToBoolean",
                  "FloatingToBoolean", "BitCast", "NoOp", "BooleanToSignedIntegral"):
            t = self.type_of(n)
            if t is None:
                raise _Abort
            if ck == "BooleanToSignedIntegral":
                return self.emit("neg", [self.cast(x, t, n)], t, n)
            return self.cast(x, t, n)
        if ck == "ToVoid":
            return x
        self.refuse(n, f"cast `{ck}`")
        raise _Abort

    def builtin_var(self, n: dict):
        text = _collect(n)
        var = next((_BUILTIN_VARS[x["referencedDecl"]["name"]] for x in text
                    if x.get("kind") == "DeclRefExpr" and x.get("referencedDecl", {}).get("name") in _BUILTIN_VARS), None)
        comp = next((x["name"][-1] for x in text if x.get("kind") == "MemberExpr" and str(x.get("name", "")).startswith("__get_")), None)
        if var is None or comp not in ("x", "y", "z"):
            self.refuse(n, "a property access that is not threadIdx / blockIdx / blockDim / gridDim")
            raise _Abort
        return self.emit(f"{var}.{comp}", [], T("u32"), n, f"{var}_{comp}")

    def pure(self, n: dict) -> bool:
        """An expression with no memory access, assignment or call: safe to evaluate when C would skip it."""
        for x in _collect(n):
            k = x.get("kind")
            if k in ("CallExpr", "CompoundAssignOperator", "ArraySubscriptExpr", "CXXOperatorCallExpr", "CXXMemberCallExpr",
                     "CXXConstructExpr", "MemberExpr", "LambdaExpr") or \
                    (k == "BinaryOperator" and x.get("opcode") in ("=", ",")) or \
                    (k == "UnaryOperator" and x.get("opcode") in ("++", "--", "*")):
                return False
        return True

    def binary(self, n: dict):
        op, (a, b) = n["opcode"], n["inner"]
        if op == "=":
            lv = self.lvalue(a)
            x = self.rvalue(b)
            if isinstance(x, Obj) or self.is_object(lv):    # a record assigned as a whole
                if not isinstance(x, Obj):
                    self.refuse(n, "a record assigned from something that is not a record")
                    raise _Abort
                self.copy_object(lv[1], x.ptr, x.desc, n)
                return x
            x = self.cast(x, self.lvalue_type(lv), n)
            self.write(lv, x, n)
            return x
        if op == ",":
            self.rvalue(a)
            return self.rvalue(b)
        if op in ("&&", "||"):
            x = self.cast(self.rvalue(a), I1, n)
            if self.pure(b):
                return self.emit("and" if op == "&&" else "or", [x, self.cast(self.rvalue(b), I1, n)], I1, n, "c")
            return self.branch_value(x, lambda: self.cast(self.rvalue(b), I1, n), lambda: Const(False, I1), n) if op == "&&" else \
                self.branch_value(x, lambda: Const(True, I1), lambda: self.cast(self.rvalue(b), I1, n), n)
        x, y = self.rvalue(a), self.rvalue(b)
        return self.arith(op, x, y, self.type_of(n), n)

    def arith(self, op: str, x, y, t: Type | None, n):
        if x.type.is_ptr or y.type.is_ptr:
            if op == "+" and y.type.is_ptr:
                x, y = y, x
            if op in ("+", "-") and x.type.is_ptr and y.type.is_int:
                i = self.cast(y, I64, n)
                if op == "-":
                    i = self.fold("neg", [i], I64, n)
                d = self.desc.get(id(x))
                if d is not None:                           # a pointer to records: in steps of their size
                    q = self.emit("gep", [self.retype(x, T("u8"), n), self.fold("mul", [i, Const(size_of(d), I64)], I64, n)],
                                  Type("ptr", 64, elem=T("u8"), name=x.type.name), n, "p")
                    self.desc[id(q)] = d
                    return q
                p = self.emit("gep", [x, i], x.type, n, "p")
                if id(x) in self.dims:
                    self.dims[id(p)] = self.dims[id(x)]
                return p
            if op in ("==", "!=") and x.type.is_ptr and y.type.is_ptr:
                if x.type != y.type:
                    y = y if not isinstance(y, Const) else Const(0, x.type)
                    x = x if not isinstance(x, Const) else Const(0, y.type)
                if isinstance(x, Const) and isinstance(y, Const):
                    return Const(op == "==", I1)
                if x.type != y.type:
                    y = self.emit("bitcast", [y], x.type, n, "p")
                return self.emit("eq" if op == "==" else "ne", [x, y], I1, n, "c")
            self.refuse(n, f"`{op}` on pointers")
            raise _Abort
        name = _BINARY[op]
        if name in ("shl", "shr"):
            y = self.cast(y, x.type, n)
        elif x.type != y.type:
            self.refuse(n, f"`{op}` on {x.type} and {y.type}")
            raise _Abort
        rt = I1 if name in ("lt", "gt", "le", "ge", "eq", "ne") else x.type
        # signed overflow is undefined in C: the lowering may assume it does not happen
        r = self.fold(name, [x, y], rt, n, **({"nsw": True} if name in ("add", "sub", "mul") and x.type.is_int and x.type.signed else {}))
        return self.cast(r, t, n) if t is not None and t != rt else r

    def fold(self, name: str, args: list, t: Type, n, **attrs):
        if all(isinstance(a, Const) for a in args):
            from ..kir.passes import fold_const
            c = fold_const(name, args, t)
            if c is not None:
                return c
        return self.emit(name, args, t, n, **attrs)

    def compound_assign(self, n: dict):
        op = n["opcode"][:-1]
        lv = self.lvalue(n["inner"][0])
        cur, rhs = self.read(lv, n), self.rvalue(n["inner"][1])
        if cur.type.is_ptr:
            x = self.arith(op, cur, rhs, None, n)
        else:
            ct = self.type_of(n, "computeLHSType") or cur.type
            x = self.cast(self.arith(op, self.cast(cur, ct, n), rhs, None, n), cur.type, n)
        self.write(lv, x, n)
        return x

    def unary(self, n: dict):
        op, a = n["opcode"], n["inner"][0]
        if op in ("++", "--"):
            lv = self.lvalue(a)
            cur = self.read(lv, n)
            if cur.type.is_ptr:
                new = self.emit("gep", [cur, Const(1 if op == "++" else -1, I64)], cur.type, n, "p")
            else:
                one = Const(1.0 if cur.type.is_float else 1, cur.type)
                new = self.fold("add" if op == "++" else "sub", [cur, one], cur.type, n,
                                **({"nsw": True} if cur.type.is_int and cur.type.signed else {}))
            self.write(lv, new, n)
            return cur if n.get("isPostfix") else new
        if op == "*":
            return self.read(self.lvalue(n), n)
        if op == "&":
            lv = self.lvalue(a)
            if lv[0] == "mem":
                return lv[1]
            return self.demote(lv[1], n).ptr                # the variable now lives in memory
        x = self.rvalue(a)
        if op == "+":
            return x
        if op == "-":
            return self.fold("neg", [x], x.type, n)
        if op == "~":
            return self.fold("not", [x], x.type, n)
        if op == "!":
            return self.fold("not", [self.cast(x, I1, n)], I1, n)
        self.refuse(n, f"unary `{op}`")
        raise _Abort

    def conditional(self, n: dict):
        c, a, b = n["inner"]
        cond = self.cast(self.rvalue(c), I1, n)
        q = n.get("type") or {}
        d = self.describe(q.get("desugaredQualType") or q.get("qualType") or "", None) if q else None
        if isinstance(d, (Rec, Arr)):                       # a record chosen by a condition: a copy of the chosen one
            tmp = self.new_object(d, "sel", n)

            def take(e):
                x = self.rvalue(e)
                self.copy_object(tmp, x.ptr, d, n)

            self.region(cond, lambda: take(a), lambda: take(b), n)
            return Obj(tmp, d)
        if self.pure(a) and self.pure(b):
            x, y = self.rvalue(a), self.rvalue(b)
            return self.emit("select", [cond, x, y], x.type, n)
        return self.branch_value(cond, lambda: self.rvalue(a), lambda: self.rvalue(b), n)

    def branch_value(self, cond, then, orelse, n):
        """`cond ? then() : orelse()` where a side must not run unless selected."""
        if isinstance(cond, Const):
            return then() if cond.value else orelse()
        s, before = If(cond, loc=loc_of(n)), dict(self.vars)
        self.blocks.append(s.then)
        x = then()
        after_then, self.vars = self.vars, dict(before)
        self.blocks[-1] = s.orelse
        y = orelse()
        after_else = self.vars
        self.blocks.pop()
        self.blocks[-1].append(s)
        self.join(s, before, after_then, after_else)
        r = Value(self.namer.fresh("t"), x.type)
        s.merges.append(Merge(r, x, y))
        return r

    def join(self, s: If, before: dict, a: dict, b: dict):
        self.vars = dict(before)
        for d in before:
            if a[d] is None or b[d] is None:                # a pointer result, set on one path only
                self.vars[d] = a[d] if a[d] is not None else b[d]
                continue
            if a[d] is not b[d] and a[d] != b[d]:
                r = Value(self.namer.fresh(self.names.get(d, "t")), a[d].type)
                s.merges.append(Merge(r, a[d], b[d]))
                self.vars[d] = r

    def call(self, n: dict):
        callee, args = n["inner"][0], n["inner"][1:]
        ref = next((x.get("referencedDecl") for x in _collect(callee) if x.get("kind") == "DeclRefExpr"), None) or {}
        name = ref.get("name", "?")
        if name == "__builtin_assume":
            return Const(0, T("i32"))
        if name == "__builtin_expect":
            return self.rvalue(args[0])
        if name == "__lane_id" and not args:
            return self.cast(self.emit("laneid", [], T("u32"), n, "lane"), T("i32"), n)
        if name == "__builtin_amdgcn_ds_bpermute" and len(args) == 2:
            at, x = self.rvalue(args[0]), self.rvalue(args[1])
            return self.emit("waveread", [x, at], x.type, n, "other")
        if name in ("__shfl", "__shfl_up", "__shfl_down", "__shfl_xor") and args:
            x = self.rvalue(args[0])
            if isinstance(x, (Value, Const)) and x.type.size == 4 and x.type != T("i32"):
                # the `int` overload on the same bits (HIP's own overloads go through a union)
                self.fetch(name)
                ints = [f for (nm, q), fs in self.funcs.items() if nm == name and q and q.startswith("int (int,") for f in fs]
                if len(ints) == 1:
                    bits = self.bitcast(x, T("i32"), n)
                    rest = list(args[1:])
                    params = [c for c in ints[0].get("inner", []) if c.get("kind") == "ParmVarDecl"]
                    rest += [{"kind": "CXXDefaultArgExpr"}] * (len(params) - 1 - len(rest))
                    y = self.inline(ints[0], [{"kind": "_Lowered", "value": bits, "valueCategory": "prvalue"}, *rest], n, f"`{name}`")
                    return self.bitcast(y, x.type, n)
            args = [{"kind": "_Lowered", "value": x, "valueCategory": "prvalue"}, *args[1:]]
        if name == "__syncthreads":
            self.emit("barrier", [], None, n)
            return Const(0, T("i32"))
        if name in ("__builtin_inff", "__builtin_huge_valf", "__builtin_inf", "__builtin_huge_val"):
            return Const(float("inf"), self.type_of(n))
        if name in ("__builtin_amdgcn_ldexpf", "ldexpf", "__builtin_ldexpf", "scalbnf") and len(args) == 2:
            x, e = self.rvalue(args[0]), self.rvalue(args[1])
            return self.emit("ldexp", [x, self.cast(e, T("i32"), n)], x.type, n, "ldexp")
        rt = self.type_of(n) if (n.get("type") or {}).get("qualType") in ("float", "double", "int", "unsigned int") else None
        if rt is not None and ((name in _MATH1 and len(args) == 1) or (name in _MATH2 and len(args) == 2)):
            xs = [self.rvalue(a) for a in args]
            if all(x.type == rt for x in xs) and (rt.is_float or name in ("max", "min", "abs") and False):
                op = (_MATH1 if len(xs) == 1 else _MATH2)[name]
                return self.emit(op, xs, rt, n, op)
            if all(x.type == rt for x in xs) and rt.is_int and name in ("max", "min"):
                return self.emit(name, xs, rt, n, name)
        m = re.fullmatch(r"make_(float|int|uint)([234])", name)
        if m and len(args) == int(m.group(2)):               # HIP's vector constructors: the components in order
            d = self.describe(f"{'unsigned int' if m.group(1) == 'uint' else m.group(1)}[{m.group(2)}]", n)
            rec = self.record({"float": "float", "int": "int", "uint": "uint"}[m.group(1)] + m.group(2)) or d
            p = self.new_object(rec, "vec", n)
            for i, a in enumerate(args):
                self.emit("store", [self.at(p, 4 * i, d.elem, n), self.cast(self.rvalue(a), d.elem, n)], None, n)
            return Obj(p, rec)
        if ref.get("kind") == "CXXMethodDecl" and not args and name in ("infinity", "max", "min", "lowest", "epsilon", "quiet_NaN"):
            t0 = self.type_of(n)                             # std::numeric_limits<T>::...
            if t0 is not None and t0.is_float:
                import numpy as np
                fi = np.finfo(np.float32 if t0.bits == 32 else np.float64)
                return Const({"infinity": float("inf"), "max": float(fi.max), "min": float(fi.tiny), "lowest": float(fi.min),
                              "epsilon": float(fi.eps), "quiet_NaN": float("nan")}[name], t0)
            if t0 is not None and t0.is_int and name in ("max", "min", "lowest"):
                hi = (1 << (t0.bits - (1 if t0.signed else 0))) - 1
                return Const(hi if name == "max" else (-hi - 1 if t0.signed else 0), t0)
        sig = (name, ref.get("type", {}).get("qualType"))
        if sig not in self.funcs:
            self.fetch(name)
        found = self.funcs.get(sig, [])
        # a template's own body is not a callee (it has no mangled name); its instantiations are
        found = [x for x in found if x.get("mangledName")] or found
        if not found:
            self.refuse(n, f"call of `{name}`, which has no body in this translation unit")
            raise _Abort
        if len({x.get("mangledName") for x in found}) > 1:
            if ref.get("id"):                                # the one at the same place in its page (see clang_ast.dump)
                at = clang_ast.page_offset(ref["id"])
                found = [x for x in found if x.get("id") and clang_ast.page_offset(x["id"]) == at]
        if len({x.get("mangledName") for x in found}) != 1:
            self.refuse(n, f"call of `{name}`: several instantiations have this name and signature")
            raise _Abort
        return self.inline(found[0], args, n, f"`{name}`")

    def inline(self, f: dict, args: list, n: dict, what: str, this: Value | None = None, this_desc=None):
        """The body of function `f` with its parameters bound to the arguments. Its value: an operand, an
        `Obj` (a record returned by value), or ("mem", pointer) when it returns a reference."""
        if self.depth > 32:
            self.refuse(n, f"recursion through {what}")
            raise _Abort
        params = [c for c in f.get("inner", []) if c.get("kind") == "ParmVarDecl"]
        if len(params) != len(args):
            self.refuse(n, f"call of {what} with default or variadic arguments")
            raise _Abort
        bound = []
        for p, a in zip(params, args):
            if a.get("kind") == "CXXDefaultArgExpr":         # the parameter's default value
                default = [c for c in p.get("inner", []) if "Attr" not in c.get("kind", "")]
                if not default:
                    self.refuse(n, f"a default argument of {what} that Clang does not print")
                    raise _Abort
                a = default[0]
            q = p.get("type", {})
            spelled = q.get("desugaredQualType") or q.get("qualType", "")
            if is_ref(spelled):              # a reference: the parameter is the argument's location
                inner = a
                while inner.get("kind") in _WRAPPERS or (inner.get("kind") in _CASTS and inner.get("castKind") == "NoOp"):
                    inner = inner["inner"][0]
                if inner.get("valueCategory") == "lvalue":
                    lv = self.lvalue(inner)
                    bound.append(MemVar(self.demote(lv[1], a).ptr if lv[0] == "var" else lv[1]))
                else:                                       # bound to a temporary
                    x = self.rvalue(a)
                    bound.append(MemVar(x.ptr if isinstance(x, Obj) else self.temporary(x, a)))
                continue
            x = self.rvalue(a)
            if isinstance(x, Obj):                          # a record by value: the callee's own copy
                cp = self.new_object(x.desc, p.get("name") or "arg", a)
                self.copy_object(cp, x.ptr, x.desc, a)
                x = MemVar(cp)
            bound.append(x)
        saved = {}
        for p, v in zip(params, bound):
            saved[p["id"]] = self.vars.get(p["id"])
            self.vars[p["id"]] = v
            self.names[p["id"]] = p.get("name", "a")
        self.depth += 1
        spelled = f.get("type", {}).get("desugaredQualType") or f.get("type", {}).get("qualType", "void")
        ret = spelled[:spelled.index("(")].strip() if "(" in spelled else "void"
        if f.get("kind") == "CXXConstructorDecl" or self.clean(ret) == "void":
            rt = None
        elif is_ref(ret):
            rt = ("ref", self.describe(ret[:ret.rindex("&")], n))
        else:
            rt = self.describe(ret, n)
        if this is not None:
            self.desc.setdefault(id(this), this_desc)
        if f.get("kind") == "CXXConstructorDecl":            # member initializers, then the body
            for init in [c for c in f.get("inner", []) if c.get("kind") == "CXXCtorInitializer"]:
                fname = (init.get("anyInit") or {}).get("name")
                fd = next((x for x in this_desc.fields if x[0] == fname), None) if isinstance(this_desc, Rec) else None
                if fd is not None and init.get("inner"):
                    self.init_value(self.at(this, fd[2], fd[1], n), fd[1], init["inner"][0])
        body = next(c for c in f["inner"] if c.get("kind") == "CompoundStmt")
        result = self.function_body(body, rt, this)
        self.depth -= 1
        for d, v in saved.items():
            if v is None:
                self.vars.pop(d, None)
            else:
                self.vars[d] = v
        if rt is None:
            return Const(0, T("i32"))
        if isinstance(rt, tuple):
            if result is None:
                self.refuse(n, f"{what} returns a reference from more than one place, or none")
                raise _Abort
            return ("mem", result)
        if isinstance(rt, (Rec, Arr)):
            return result
        return self.cast(result, rt, n)

    # ---- statements ----------------------------------------------------------------------------
    def function_body(self, body: dict, rt, this: Value | None = None):
        """Lower a function's statements. `rt`: None (`void`), a scalar type, a record description (the
        result is an `Obj` in a fresh object), or ("ref", description) (the result is the pointer returned)."""
        self.serial += 1
        c = {"ret": f"$ret{self.serial}", "val": f"$val{self.serial}" if isinstance(rt, Type) else None, "loops": [], "rt": rt,
             "this": this, "obj": None, "ref": None}
        self.vars[c["ret"]] = Const(False, I1)
        c["escaping"] = escaping(body)
        for d in list(self.vars):                           # parameters whose address the body takes
            if d in c["escaping"] and isinstance(self.vars[d], (Value, Const)) and not self.vars[d].type.is_ptr:
                self.demote(d, body)
        if isinstance(rt, Type):
            self.vars[c["val"]] = Const(0.0 if rt.is_float else 0, rt) if not rt.is_ptr else None
        elif isinstance(rt, (Rec, Arr)):
            c["obj"] = self.new_object(rt, "ret", body)
        self.ctx.append(c)
        self.seq(body.get("inner", []))
        self.ctx.pop()
        del self.vars[c["ret"]]
        if isinstance(rt, Type):
            return self.vars.pop(c["val"], None)
        if isinstance(rt, (Rec, Arr)):
            return Obj(c["obj"], rt)
        return c["ref"]

    def left(self):
        """Whether control has left the statement sequence being lowered (a `return`, or a `break` or
        `continue` of the innermost loop): None (it has not), a constant true, or a condition."""
        c = self.ctx[-1]
        vals = [self.vars[k] for k in [c["ret"], *(c["loops"][-1] if c["loops"] else ())]]
        if any(isinstance(v, Const) and v.value for v in vals):
            return Const(True, I1)
        vals = [v for v in vals if not isinstance(v, Const)]
        if not vals:
            return None
        r = vals[0]
        for v in vals[1:]:
            r = self.emit("or", [r, v], I1)
        return r

    def seq(self, stmts: list):
        """Statements in order; what follows a statement that may leave runs only where it did not."""
        for i, s in enumerate(stmts):
            self.stmt(s)
            g = self.left()
            if g is None:
                continue
            rest = stmts[i + 1:]
            if isinstance(g, Const) or not rest:
                return
            keys = [self.ctx[-1]["ret"], *(self.ctx[-1]["loops"][-1] if self.ctx[-1]["loops"] else ())]

            def remaining():
                for key in keys:                            # where the rest runs, nothing has left
                    self.vars[key] = Const(False, I1)
                self.seq(rest)

            self.region(self.fold("not", [g], I1, s), remaining, None, s)
            return

    def region(self, cond, then, orelse, n):
        """`if (cond) then() else orelse()` with the variables both sides assign merged."""
        if isinstance(cond, Const):
            if cond.value:
                then()
            elif orelse:
                orelse()
            return
        s, before = If(cond, loc=loc_of(n)), dict(self.vars)
        self.blocks.append(s.then)
        then()
        after_then, self.vars = self.vars, dict(before)
        self.blocks[-1] = s.orelse
        if orelse:
            orelse()
        after_else = self.vars
        self.blocks.pop()
        self.blocks[-1].append(s)
        self.join(s, before, {d: after_then[d] for d in before}, {d: after_else[d] for d in before})

    def stmt(self, n: dict):
        try:
            self._stmt(n)
        except _Abort:
            pass

    def _stmt(self, n: dict):
        k = n.get("kind")
        if k == "CompoundStmt":
            self.seq(n.get("inner", []))
        elif k == "NullStmt":
            pass
        elif k == "DeclStmt":
            for d in n.get("inner", []):
                self.decl(d)
        elif k == "IfStmt":
            self.if_stmt(n)
        elif k in ("ForStmt", "WhileStmt", "DoStmt"):
            self.loop_stmt(n)
        elif k == "ReturnStmt":
            c = self.ctx[-1]
            rt = c["rt"]
            if n.get("inner") and rt is not None:
                e = n["inner"][0]
                if isinstance(rt, tuple):                   # a reference: the location itself
                    if c["ref"] is not None:
                        self.refuse(n, "a reference returned from more than one place")
                        raise _Abort
                    lv = self.lvalue(e)
                    c["ref"] = self.demote(lv[1], n).ptr if lv[0] == "var" else lv[1]
                elif isinstance(rt, (Rec, Arr)):            # a record by value: into the result object
                    self.init_value(c["obj"], rt, e)
                else:
                    x = self.rvalue(e)
                    if x.type.is_ptr or rt.is_ptr:
                        if self.vars[c["ret"]] is not None and not (isinstance(self.vars[c["ret"]], Const) and not self.vars[c["ret"]].value):
                            self.refuse(n, "a pointer returned from more than one place")
                        self.vars[c["val"]] = x
                    else:
                        self.vars[c["val"]] = self.cast(x, rt, n)
            self.vars[c["ret"]] = Const(True, I1)
        elif k in ("BreakStmt", "ContinueStmt"):
            c = self.ctx[-1]
            if not c["loops"]:
                self.refuse(n, f"`{k}` outside a loop")
                return
            self.vars[c["loops"][-1][0 if k == "BreakStmt" else 1]] = Const(True, I1)
        elif k in ("SwitchStmt", "GotoStmt", "LabelStmt"):
            self.refuse(n, f"`{k}`")
        elif k == "AttributedStmt":
            self.stmt(n["inner"][-1])
        else:
            self.rvalue(n)

    def decl(self, d: dict):
        if d.get("kind") in ("TypedefDecl", "TypeAliasDecl", "StaticAssertDecl", "UsingDecl"):
            return
        if d.get("kind") != "VarDecl":
            self.refuse(d, f"declaration `{d.get('kind')}`")
            return
        q = (d.get("type") or {})
        spelled = q.get("desugaredQualType") or q.get("qualType") or ""
        name = d.get("name", "t")
        inits = [c for c in d.get("inner", []) if "Attr" not in c.get("kind", "")]
        if "(lambda" in spelled:                            # `auto f = [](...) { ... };`: a compile-time value
            self.vars[d["id"]] = self.rvalue(inits[0])
            self.names[d["id"]] = name
            return
        shared = any(c.get("kind") == "CUDASharedAttr" for c in d.get("inner", []))
        if shared and re.search(r"\[\]\s*$", spelled):         # `extern __shared__ T x[]`: as large as the launch makes it
            elem = self.ctype(re.sub(r"\[\]\s*$", "", spelled), d)
            if elem is None:
                return
            self.serial += 1
            v = Value(self.namer.fresh(name), Type("ptr", 64, elem=elem, name="lds"))
            self.entry_block.insert(0, Op("shared", [], v, {"name": f"{name}{self.serial}", "bytes": 0, "dynamic": True}, loc=loc_of(d)))
            self.vars[d["id"]], self.names[d["id"]] = v, name
            self.dims[id(v)] = (0,)
            return
        desc = self.describe(spelled, d)
        if desc is None:
            return
        self.names[d["id"]] = name
        if isinstance(desc, tuple):                         # a pointer (or a reference) to a record or an array
            if is_ref(spelled):
                lv = self.lvalue(inits[0])
                self.vars[d["id"]] = MemVar(self.demote(lv[1], d).ptr if lv[0] == "var" else lv[1])
            else:
                self.vars[d["id"]] = self.rvalue(inits[0]) if inits else Const(0, T("ptr<u8>"))
            return
        if is_ref(spelled) and isinstance(desc, Type) and inits:      # a reference to a scalar
            inner = inits[0]
            while inner.get("kind") in _WRAPPERS:
                inner = inner["inner"][0]
            if inner.get("valueCategory") == "lvalue":
                lv = self.lvalue(inner)
                self.vars[d["id"]] = MemVar(self.demote(lv[1], d).ptr if lv[0] == "var" else lv[1])
            else:
                self.vars[d["id"]] = MemVar(self.temporary(self.rvalue(inits[0]), d))
            return
        if isinstance(desc, (Rec, Arr)):
            leaf = scalar_leaf(desc)
            if shared:                                      # shared memory of the workgroup
                size = size_of(desc)
                self.serial += 1
                v = Value(self.namer.fresh(name), Type("ptr", 64, elem=leaf if leaf is not None else T("u8"), name="lds"))
                self.entry_block.insert(0, Op("shared", [], v, {"name": f"{name}{self.serial}", "bytes": size}, loc=loc_of(d)))
                self.vars[d["id"]] = v
                if leaf is not None:
                    dims, x = [], desc
                    while isinstance(x, Arr):
                        dims.append(x.n)
                        x = x.elem
                    self.dims[id(v)] = tuple(dims)
                else:
                    self.desc[id(v)] = desc
                return
            p = self.new_object(desc, name, d)              # a thread's own object
            self.vars[d["id"]] = MemVar(p)
            if inits:
                self.init_value(p, desc, inits[0])
            return
        t = desc
        if inits:
            x = self.rvalue(inits[0])
            if isinstance(x, tuple):
                x = self.read(x, d)
            x = self.cast(x, t, d)
            if isinstance(x, Value) and x.name.startswith("t") and x.name[1:].isdigit() and self.blocks[-1] and \
                    isinstance(self.blocks[-1][-1], Op) and self.blocks[-1][-1].result is x:
                x.name = self.namer.fresh(name)             # name the value after the variable it initializes
        else:
            x = Const(0.0 if t.is_float else 0, t)          # uninitialized: any value
        self.vars[d["id"]] = x
        if d["id"] in self.ctx[-1].get("escaping", ()) and not t.is_ptr:
            self.demote(d["id"], d)                         # its address is taken somewhere: in memory from the start

    def if_stmt(self, n: dict):
        parts = list(n["inner"])
        if n.get("hasInit"):                                # `if (init; cond)`
            self.stmt(parts.pop(0))
        if n.get("hasVar"):                                 # `if (T x = e)`: the declaration, then x as the condition
            self.stmt(parts.pop(0))
        cond = self.cast(self.rvalue(parts[0]), I1, n)
        self.region(cond, lambda: self.stmt(parts[1]), (lambda: self.stmt(parts[2])) if len(parts) > 2 else None, n)

    def assigned(self, nodes: list[dict]) -> list[str]:
        """Declarations (already in scope) that the given subtrees assign."""
        out = []
        for root in nodes:
            for x in _collect(root):
                k, target = x.get("kind"), None
                if (k == "BinaryOperator" and x.get("opcode") == "=") or k == "CompoundAssignOperator" or \
                        (k == "UnaryOperator" and x.get("opcode") in ("++", "--")):
                    target = x["inner"][0]
                    while target.get("kind") in _WRAPPERS:
                        target = target["inner"][0]
                if target is not None and target.get("kind") == "DeclRefExpr":
                    d = target.get("referencedDecl", {}).get("id")
                    if d in self.vars and d not in out:
                        out.append(d)
        return out

    def loop_stmt(self, n: dict):
        k, parts = n["kind"], n["inner"]
        scope = set(self.vars)
        if k == "ForStmt":
            init, condvar, cond, inc, body = parts
            if condvar:
                self.refuse(n, "`for` with a condition variable")
                raise _Abort
            if init:
                self.stmt(init)
        elif k == "WhileStmt":
            (cond, body), inc = parts[-2:], {}
        else:
            (body, cond), inc = parts, {}
        c = self.ctx[-1]
        self.serial += 1
        brk, cnt, first = f"$brk{self.serial}", f"$cnt{self.serial}", f"$first{self.serial}"
        self.vars[brk] = self.vars[cnt] = Const(False, I1)
        kinds = set()                                       # the loop's own statements: not those of a lambda's body

        def own(x):
            if isinstance(x, dict) and x.get("kind") != "LambdaExpr":
                kinds.add(x.get("kind"))
                for ch in x.get("inner", []):
                    own(ch)

        own(body)
        carried = self.assigned([x for x in (cond, inc, body) if x])
        if "BreakStmt" in kinds:
            carried.append(brk)
        if "ReturnStmt" in kinds:
            carried.append(c["ret"])
            if c["val"] is not None and self.vars.get(c["val"]) is not None:
                carried.append(c["val"])
        if k == "DoStmt":                                   # the body runs before the first test
            self.vars[first] = Const(True, I1)
            carried.append(first)
        effects = bool(cond) and k != "DoStmt" and any(
            (x.get("kind") == "BinaryOperator" and x.get("opcode") == "=") or x.get("kind") in ("CompoundAssignOperator", "CallExpr")
            or (x.get("kind") == "UnaryOperator" and x.get("opcode") in ("++", "--")) for x in _collect(cond))
        if effects and any(x.get("kind") == "CallExpr" for x in _collect(cond)) and not self.assigned([cond]):
            effects = False                                 # a call that assigns nothing in scope is tested at the top
        stay = f"$stay{self.serial}"
        if effects:
            # `while (x op= e) body`: what the condition assigns must be seen by the body and after the loop, so
            # the test moves into the body: loop while `stay` { stay = cond; if (stay) { body; inc } }
            self.vars[stay] = Const(True, I1)
            carried.append(stay)
        s = Loop(loc=loc_of(n))
        for d in carried:
            v = Value(self.namer.fresh(self.names.get(d, d.strip("$").rstrip("0123456789") or "t")), self.vars[d].type)
            s.carried.append(v)
            s.init.append(self.vars[d])
            self.vars[d] = v
        at_head = dict(self.vars)
        self.blocks.append(s.head)
        try:
            go = self.vars[stay] if effects else self.cast(self.rvalue(cond), I1, n) if cond else Const(True, I1)
        except _Abort:
            self.blocks.pop()
            raise
        if any(self.vars.get(d) is not at_head.get(d) for d in at_head):
            self.blocks.pop()
            self.refuse(cond, "an assignment in a loop condition")
            raise _Abort
        if k == "DoStmt":
            go = self.fold("or", [self.vars[first], go], I1, n)
        for d in (brk, c["ret"]):                           # a thread that broke out or returned stops iterating
            if d in carried:
                go = self.fold("and", [go, self.fold("not", [self.vars[d]], I1, n)], I1, n)
        s.cond = go
        self.blocks[-1] = s.body
        c["loops"].append((brk, cnt))
        if k == "DoStmt":
            self.vars[first] = Const(False, I1)

        def iteration():
            self.stmt(body)
            if inc:                                         # `continue` reaches the increment; `break` and `return` do not
                gone = [self.vars[d] for d in (brk, c["ret"]) if not (isinstance(self.vars[d], Const) and not self.vars[d].value)]
                if not gone:
                    self.stmt(inc)
                elif not any(isinstance(g, Const) for g in gone):
                    g = gone[0] if len(gone) == 1 else self.emit("or", gone, I1, n)
                    self.region(self.fold("not", [g], I1, n), lambda: self.stmt(inc), None, n)

        if effects:
            test = self.cast(self.rvalue(cond), I1, n)
            self.vars[stay] = test
            self.region(test, iteration, None, n)
        else:
            iteration()
        c["loops"].pop()
        self.blocks.pop()
        for d, v in zip(carried, s.carried):
            s.next.append(self.vars[d])
            o = Value(self.namer.fresh(v.name), v.type)
            s.out.append(o)
            self.vars[d] = o
        self.blocks[-1].append(s)
        for d in set(self.vars) - scope:                    # the loop's own declarations and flags end with it
            del self.vars[d]

    # ---- the entry -----------------------------------------------------------------------------
    def lower(self) -> Func:
        self.fetch(self.entry)
        cands = [f for fs in self.funcs.values() for f in fs if f.get("name") == self.entry
                 and any(c.get("kind") == "CUDAGlobalAttr" for c in f.get("inner", []))]
        if not cands:
            raise FrontendError(f"no `__global__` function named {self.entry!r} with a body in {self.source.name}")
        fn = cands[-1]
        params = []
        for p in fn["inner"]:
            if p.get("kind") != "ParmVarDecl":
                continue
            t = self.type_of(p)
            if t is None:
                continue
            v = Value(self.namer.fresh(p.get("name") or "arg"), t)
            params.append(v)
            self.vars[p["id"]] = v
            self.names[p["id"]] = v.name
        f = Func(self.entry, params, [])
        self.blocks = [f.body]
        self.entry_block = f.body
        self.function_body(next(c for c in fn["inner"] if c.get("kind") == "CompoundStmt"), None)
        if self.unsupported:
            seen, items = set(), []
            for u in self.unsupported:
                if (u["loc"], u["what"]) not in seen:
                    seen.add((u["loc"], u["what"]))
                    items.append(u)
            raise FrontendError(f"{self.source.name}: {len(items)} construct(s) outside the supported subset: "
                                + "; ".join(f"{u['what']} at {u['loc']}" for u in items[:6])
                                + (" ..." if len(items) > 6 else ""), items)
        number_sites(f)
        return assert_ok(f)


def _collect(n) -> list[dict]:
    out = []

    def go(x):
        if isinstance(x, dict):
            if "kind" in x:
                out.append(x)
            for c in x.get("inner", []):
                go(c)

    go(n)
    return out


def _fold_cast(v, src: Type, dst: Type):
    import numpy as np
    from ..kir.interp import _cast, np_dtype
    r = _cast(np.array(v, dtype=np_dtype(src)), src, dst)
    return bool(r) if dst.is_bool else float(r) if dst.is_float else int(r)


def _fold_bitcast(v, src: Type, dst: Type):
    import numpy as np
    from ..kir.interp import _bitcast, np_dtype
    r = _bitcast(np.array(v, dtype=np_dtype(src)), dst)
    return float(r) if dst.is_float else int(r)


def lower_hip(source: str | Path, entry: str, flags=None, mcpu: str = "gfx950", include_dirs=()) -> Func:
    """The `kir` of the kernel `entry` in a HIP source."""
    return Lowerer(source, entry, flags, mcpu, include_dirs).lower()
