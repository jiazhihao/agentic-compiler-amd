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

SUPPORTED = {
    "Statements": "compound, declaration, expression, `if`/`else`, `for`, `while`, `do`, `return` as the last statement",
    "Types": "`bool`, 8- to 64-bit integers, `float`, `double`, pointers to them (typedefs resolved by Clang)",
    "Expressions": "arithmetic, bitwise, shifts, comparisons, `&&` `||` `!`, `?:`, assignment and compound assignment, "
                   "`++` `--`, casts, `__builtin_bit_cast`, subscripts, `*p`, pointer plus integer",
    "Builtins": "`threadIdx`, `blockIdx`, `blockDim`, `gridDim` (`.x .y .z`), `__builtin_assume`, `__builtin_expect`",
    "Calls": "functions with a body in the translation unit, inlined (parameters by value; templates as instantiated)",
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


class Lowerer:
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
                return ("var", d["id"])
            self.refuse(n, f"reference to `{d.get('name')}` ({d.get('kind')})")
            raise _Abort
        if k == "ArraySubscriptExpr":
            base, idx = self.rvalue(n["inner"][0]), self.rvalue(n["inner"][1])
            if not base.type.is_ptr:
                base, idx = idx, base
            return ("mem", self.emit("gep", [base, self.cast(idx, I64, n)], base.type, n, "p"))
        if k == "UnaryOperator" and n.get("opcode") == "*":
            return ("mem", self.rvalue(n["inner"][0]))
        if k in _CASTS and n.get("castKind") == "NoOp":
            return self.lvalue(n["inner"][0])
        self.refuse(n, f"`{k}` as an assignable location")
        raise _Abort

    def read(self, lv, node=None):
        if lv[0] == "var":
            return self.vars[lv[1]]
        return self.emit("load", [lv[1]], lv[1].type.elem, node, "v")

    def write(self, lv, x, node=None):
        if lv[0] == "var":
            self.vars[lv[1]] = x
        else:
            self.emit("store", [lv[1], self.cast(x, lv[1].type.elem, node)], None, node)

    def lvalue_type(self, lv) -> Type:
        return self.vars[lv[1]].type if lv[0] == "var" else lv[1].type.elem

    # ---- expressions ---------------------------------------------------------------------------
    def rvalue(self, n: dict):
        k = n.get("kind")
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
        if k == "CharacterLiteral":
            return Const(int(n["value"]), self.type_of(n))
        if k == "DeclRefExpr":                              # an lvalue used where its address is not needed
            return self.read(self.lvalue(n), n)
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
            return self.call(n)
        if k == "ArraySubscriptExpr":
            return self.read(self.lvalue(n), n)
        self.refuse(n, f"expression `{k}`")
        raise _Abort

    def bitcast(self, x, t: Type, n):
        if x.type == t:
            return x
        if isinstance(x, Const):
            return Const(_fold_bitcast(x.value, x.type, t), t)
        return self.emit("bitcast", [x], t, n)

    def cast_expr(self, n: dict):
        ck, inner = n.get("castKind"), n["inner"][-1]
        if ck == "LValueToRValue":
            return self.read(self.lvalue(inner), n)
        if ck in ("FunctionToPointerDecay", "BuiltinFnToFnPtr"):
            self.refuse(n, "a function used as a value")
            raise _Abort
        x = self.rvalue(inner)
        if ck in ("NoOp", "ConstructorConversion", "UserDefinedConversion") and x.type == self.type_of(n):
            return x
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
            if k in ("CallExpr", "CompoundAssignOperator", "ArraySubscriptExpr", "CXXOperatorCallExpr") or \
                    (k == "BinaryOperator" and x.get("opcode") in ("=", ",")) or \
                    (k == "UnaryOperator" and x.get("opcode") in ("++", "--", "*")):
                return False
        return True

    def binary(self, n: dict):
        op, (a, b) = n["opcode"], n["inner"]
        if op == "=":
            lv = self.lvalue(a)
            x = self.cast(self.rvalue(b), self.lvalue_type(lv), n)
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
                return self.emit("gep", [x, i], x.type, n, "p")
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
                new = self.fold("add" if op == "++" else "sub", [cur, one], cur.type, n)
            self.write(lv, new, n)
            return cur if n.get("isPostfix") else new
        if op == "*":
            return self.read(self.lvalue(n), n)
        if op == "&":
            lv = self.lvalue(a)
            if lv[0] == "mem":
                return lv[1]
            self.refuse(n, "the address of a local variable")
            raise _Abort
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
        sig = (name, ref.get("type", {}).get("qualType"))
        if sig not in self.funcs:
            self.fetch(name)
        found = self.funcs.get(sig, [])
        if not found:
            self.refuse(n, f"call of `{name}`, which has no body in this translation unit")
            raise _Abort
        if len({x.get("mangledName") for x in found}) > 1:
            self.refuse(n, f"call of `{name}`: several functions have this name and signature")
            raise _Abort
        f = found[0]
        if self.depth > 32:
            self.refuse(n, f"recursion through `{name}`")
            raise _Abort
        params = [c for c in f.get("inner", []) if c.get("kind") == "ParmVarDecl"]
        if len(params) != len(args):
            self.refuse(n, f"call of `{name}` with default or variadic arguments")
            raise _Abort
        values = []
        for p, a in zip(params, args):
            if "&" in (p.get("type", {}).get("qualType", "")):
                self.refuse(a, f"a reference parameter of `{name}`")
                raise _Abort
            values.append(self.rvalue(a))
        saved = {}
        for p, v in zip(params, values):
            saved[p["id"]] = self.vars.get(p["id"])
            self.vars[p["id"]] = v
            self.names[p["id"]] = p.get("name", "a")
        self.depth += 1
        body = next(c for c in f["inner"] if c.get("kind") == "CompoundStmt")
        result = self.function_body(body)
        self.depth -= 1
        for d, v in saved.items():
            if v is None:
                self.vars.pop(d, None)
            else:
                self.vars[d] = v
        rt = self.ctype(re.sub(r"\(.*$", "", f.get("type", {}).get("desugaredQualType") or f.get("type", {}).get("qualType", "void")).strip())
        if rt is None:
            return Const(0, T("i32"))
        if result is None:
            self.refuse(n, f"`{name}` does not end with a return")
            raise _Abort
        return self.cast(result, rt, n)

    # ---- statements ----------------------------------------------------------------------------
    def function_body(self, body: dict):
        """Lower a function's statements; returns the value of a trailing `return`, if any."""
        stmts = body.get("inner", [])
        result = None
        for i, s in enumerate(stmts):
            if s.get("kind") == "ReturnStmt":
                if i != len(stmts) - 1:
                    self.refuse(s, "a `return` that is not the last statement")
                    continue
                if s.get("inner"):
                    try:
                        result = self.rvalue(s["inner"][0])
                    except _Abort:
                        pass
                continue
            self.stmt(s)
        return result

    def stmt(self, n: dict):
        try:
            self._stmt(n)
        except _Abort:
            pass

    def _stmt(self, n: dict):
        k = n.get("kind")
        if k == "CompoundStmt":
            for s in n.get("inner", []):
                self.stmt(s)
        elif k == "NullStmt":
            pass
        elif k == "DeclStmt":
            for d in n.get("inner", []):
                self.decl(d)
        elif k == "IfStmt":
            self.if_stmt(n)
        elif k in ("ForStmt", "WhileStmt", "DoStmt"):
            self.loop_stmt(n)
        elif k in ("ReturnStmt", "BreakStmt", "ContinueStmt", "SwitchStmt", "GotoStmt", "LabelStmt"):
            self.refuse(n, {"ReturnStmt": "a `return` that is not the last statement of its function"}.get(k, f"`{k}`"))
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
        t = self.type_of(d)
        if t is None:
            return
        self.names[d["id"]] = d.get("name", "t")
        inits = [c for c in d.get("inner", []) if "Attr" not in c.get("kind", "")]
        if inits:
            x = self.cast(self.rvalue(inits[0]), t, d)
            if isinstance(x, Value) and x.name.startswith("t") and x.name[1:].isdigit() and self.blocks[-1] and \
                    isinstance(self.blocks[-1][-1], Op) and self.blocks[-1][-1].result is x:
                x.name = self.namer.fresh(d.get("name", "t"))    # name the value after the variable it initializes
        else:
            x = Const(0.0 if t.is_float else 0, t)               # uninitialized: any value
        self.vars[d["id"]] = x

    def if_stmt(self, n: dict):
        parts = list(n["inner"])
        if n.get("hasInit") or n.get("hasVar"):
            self.refuse(n, "`if` with an init statement or a condition variable")
            raise _Abort
        cond = self.cast(self.rvalue(parts[0]), I1, n)
        if isinstance(cond, Const):
            if cond.value:
                self.stmt(parts[1])
            elif len(parts) > 2:
                self.stmt(parts[2])
            return
        s, before = If(cond, loc=loc_of(n)), dict(self.vars)
        self.blocks.append(s.then)
        self.stmt(parts[1])
        after_then, self.vars = self.vars, dict(before)
        self.blocks[-1] = s.orelse
        if len(parts) > 2:
            self.stmt(parts[2])
        after_else = self.vars
        self.blocks.pop()
        self.blocks[-1].append(s)
        self.join(s, before, {d: after_then[d] for d in before}, {d: after_else[d] for d in before})

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
        if any(x.get("kind") in ("BreakStmt", "ContinueStmt", "ReturnStmt") for x in _collect(body)):
            self.refuse(n, "`break`, `continue` or `return` inside a loop")
            raise _Abort
        if k == "DoStmt":                                   # the body once, then a `while` loop
            self.stmt(body)
        s = Loop(loc=loc_of(n))
        carried = self.assigned([x for x in (cond, inc, body) if x])
        for d in carried:
            c = Value(self.namer.fresh(self.names.get(d, "t")), self.vars[d].type)
            s.carried.append(c)
            s.init.append(self.vars[d])
            self.vars[d] = c
        at_head = dict(self.vars)
        self.blocks.append(s.head)
        s.cond = self.cast(self.rvalue(cond), I1, n) if cond else Const(True, I1)
        if any(self.vars.get(d) is not at_head.get(d) for d in at_head):
            self.blocks.pop()
            self.refuse(cond, "an assignment in a loop condition")
            raise _Abort
        self.blocks[-1] = s.body
        self.stmt(body)
        if inc:
            self.stmt(inc)
        self.blocks.pop()
        for d, c in zip(carried, s.carried):
            s.next.append(self.vars[d])
            o = Value(self.namer.fresh(self.names.get(d, "t")), c.type)
            s.out.append(o)
            self.vars[d] = o
        self.blocks[-1].append(s)
        for d in set(self.vars) - scope:                    # the loop's own declarations end with it
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
        self.function_body(next(c for c in fn["inner"] if c.get("kind") == "CompoundStmt"))
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
