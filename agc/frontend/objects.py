"""The frontend's object model: structs, classes and arrays as thread-local objects.

A variable of record or array type, and any variable whose address is taken or that is bound to a
reference, lives in a `local` object of `kir`; member access, subscripts, `this`, references and
by-value copies are pointer arithmetic, loads and stores on it, as the source says. Nothing here
decides what stays in memory: `kir/locals.py` turns the objects back into SSA values afterwards.

Layouts (sizes, field offsets) come from Clang (`clang_ast.layouts`); field names, methods and
constructors from the record's AST. A record whose fields Clang does not list (HIP's `float4`,
built from unions) is opaque: it has a size and is copied word by word.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from ..kir.ir import Const, I64, Op, T, Type, Value
from . import clang_ast


@dataclass
class Rec:
    name: str
    size: int
    fields: list = field(default_factory=list)      # (name, description, byte offset)
    word: str = "u32"                               # element type of an opaque record's words


@dataclass
class Arr:
    elem: object                                    # Type | Rec | Arr
    n: int


@dataclass
class Obj:
    """A value of record or array type: where it is."""
    ptr: Value
    desc: object


@dataclass
class MemVar:
    """A variable that lives in memory (an object, an address-taken scalar, a reference)."""
    ptr: Value


def size_of(d) -> int:
    if isinstance(d, Rec):
        return d.size
    if isinstance(d, Arr):
        return d.n * size_of(d.elem)
    return d.size


def leaves(d, base: int = 0) -> list[tuple[int, Type]]:
    """Every scalar of a description with its byte offset."""
    if isinstance(d, Arr):
        s = size_of(d.elem)
        return [x for i in range(d.n) for x in leaves(d.elem, base + i * s)]
    if isinstance(d, Rec):
        if not d.fields:
            return [(base + 4 * i, T(d.word)) for i in range(d.size // 4)]
        return [x for _, fd, off in d.fields for x in leaves(fd, base + off)]
    return [(base, d)]


def scalar_leaf(d):
    """The scalar type an array of arrays ... of scalars is made of, or None."""
    while isinstance(d, Arr):
        d = d.elem
    return d if isinstance(d, Type) else None


def _walk(n: dict):
    yield n
    for c in n.get("inner", []):
        if isinstance(c, dict):
            yield from _walk(c)


class Objects:
    """Mixed into the lowering: record descriptions, objects, copies."""

    def init_objects(self):
        self.records: dict[str, Rec] = {}
        self.methods: dict[tuple, list] = {}             # (record name, method name) -> method declarations with a body
        self.ctors: dict[str, list] = {}                 # record name -> constructor declarations
        self.desc: dict[int, object] = {}                # pointer value -> the description of what it points to
        self._layouts = None
        self.globals: dict[str, object] = {}
        self.aliases: dict[str, str | None] = {}
        self.enums: dict[tuple, int] = {}

    # ---- descriptions ------------------------------------------------------------------------------
    def layouts(self) -> dict:
        if self._layouts is None:
            self._layouts = clang_ast.layouts(self.source, **self.dump_args)
        return self._layouts

    @staticmethod
    def clean(s: str) -> str:
        s = re.sub(r"\b(const|volatile|__restrict|restrict|struct|class)\b", "", s)
        return re.sub(r"\s+", " ", s).strip()

    def describe(self, spelled: str, node: dict | None = None):
        """A type as: a `kir` type (scalars and pointers to scalars), `Rec`, `Arr`, ("ptr", description) for a
        pointer or reference to an aggregate, or None (unsupported; refused at `node`)."""
        s = self.clean(spelled)
        m = re.fullmatch(r"(.+?)\s*([*&]?)\s*__attribute__\(\(ext_vector_type\((\d+)\)\)\)\s*([*&]?)", s)
        if m:                                              # a vector type of the compiler: its elements in order
            s = f"{m.group(1).strip()}[{m.group(3)}]"
            if m.group(2) or m.group(4):
                inner = self.describe(s, node)
                return ("ptr", inner) if inner is not None else None
        m = re.fullmatch(r"(.+?)\s*\[(\d+)\]((?:\[\d+\])*)", s)
        if m:                                              # T[n][m]: an array of n arrays of m
            inner = self.describe(m.group(1) + m.group(3), node)
            return Arr(inner, int(m.group(2))) if inner is not None else None
        if s.endswith(("*", "&")):
            if self.clean(s[:-1]) == "void":
                return T("ptr<u8>")
            inner = self.describe(s[:-1], None)
            if inner is None:
                return self.ctype(s, node)                 # reports the unsupported type
            return T(f"ptr<{inner}>") if isinstance(inner, Type) else ("ptr", inner)
        t = self.ctype(s, None)
        if t is not None:
            return t
        if re.fullmatch(r"[\w:]+", s):                      # a typedef or alias the text search did not resolve
            target = self.alias(s)
            if target and self.clean(target) != s:
                return self.describe(target, node)
        rec = self.record(s)
        if rec is None and node is not None:
            self.refuse(node, f"type `{s}`")
        return rec

    def alias(self, name: str) -> str | None:
        """What Clang says the typedef or alias `name` stands for."""
        if name not in self.aliases:
            self.aliases[name] = None
            ident = name.split("::")[-1]
            stack = list(clang_ast.dump(self.source, ident, **self.dump_args))
            while stack:
                x = stack.pop()
                if x.get("kind") in ("TypedefDecl", "TypeAliasDecl") and x.get("name") == ident:
                    q = x.get("type") or {}
                    self.aliases[name] = q.get("desugaredQualType") or q.get("qualType")
                    break
                stack += [c for c in x.get("inner", []) if isinstance(c, dict)]
        return self.aliases[name]

    def enum_constant(self, ref: dict, node: dict):
        """The value of an enumerator."""
        owner = self.clean((ref.get("type") or {}).get("qualType", "")).split("::")[-1]
        key = (owner, ref.get("name"))
        if key not in self.enums:
            stack = list(clang_ast.dump(self.source, owner, **self.dump_args)) if owner else []
            while stack:
                x = stack.pop()
                if x.get("kind") == "EnumDecl" and x.get("name") == owner:
                    nxt = 0
                    for c in x.get("inner", []):
                        if c.get("kind") != "EnumConstantDecl":
                            continue
                        val = next((int(v["value"]) for v in _walk(c) if v.get("kind") == "ConstantExpr" and "value" in v), None)
                        if val is None:
                            val = next((int(v["value"]) for v in _walk(c) if v.get("kind") == "IntegerLiteral" and "value" in v), nxt) \
                                if len(list(_walk(c))) <= 3 else None
                        if val is None:
                            break
                        self.enums[(owner, c.get("name"))] = val
                        nxt = val + 1
                stack += [c for c in x.get("inner", []) if isinstance(c, dict)]
        if key not in self.enums:
            self.refuse(node, f"the enumerator `{ref.get('name')}`, whose value Clang does not print")
            return None
        t = self.ctype(owner, node)
        return Const(self.enums[key], t) if t is not None else None

    def record(self, name: str) -> Rec | None:
        """The record type Clang prints as `name` (with its fields and methods), or None."""
        name = self.clean(name)
        m = re.fullmatch(r"(float|double|int|uint|short|ushort|char|uchar|long|ulong)([1234])", name)
        if m:                                              # HIP's vector types are typedefs of one class template
            base = {"uint": "unsigned int", "ushort": "unsigned short", "uchar": "unsigned char", "ulong": "unsigned long"}.get(m.group(1), m.group(1))
            name = f"HIP_vector_type<{base}, {m.group(2)}>"
        if name in self.records:
            return self.records[name]
        lay = self.layouts()
        flat = self.clean(name).replace(" ", "")
        key = name if name in lay else next((k for k in lay if k.endswith("::" + name) or
                                             self.clean(k).replace(" ", "") == flat), None)
        if key is None:
            return None
        rec = Rec(name, lay[key]["size"], word="f32" if re.search(r"\bfloat\b", name) else "u32")
        self.records[name] = rec                           # before the fields: a record may refer to itself by pointer
        ident = re.split(r"<", name, 1)[0].split("::")[-1].strip()
        node = self.record_node(ident, name) if not name.startswith("HIP_vector_") else None     # opaque: built from unions
        if node is not None:
            fields = [c for c in node.get("inner", []) if c.get("kind") == "FieldDecl"]
            offs = lay[key]["offsets"]
            if len(fields) == len(offs):
                for fd, off in zip(fields, offs):
                    q = fd.get("type", {})
                    d = self.describe(q.get("desugaredQualType") or q.get("qualType") or "", None)
                    if d is None or isinstance(d, tuple):
                        rec.fields = []                    # a field this model does not describe: the record is opaque
                        break
                    rec.fields.append((fd.get("name"), d, off))
            members = []
            for c in node.get("inner", []):
                members += c.get("inner", []) if c.get("kind") == "FunctionTemplateDecl" else [c]   # and a member template's instantiations
            for c in members:
                if c.get("kind") == "CXXMethodDecl" and any(x.get("kind") == "CompoundStmt" for x in c.get("inner", [])):
                    self.methods.setdefault((name, c.get("name")), []).append(c)
                elif c.get("kind") == "CXXConstructorDecl":
                    self.ctors.setdefault(name, []).append(c)
        return rec

    def record_node(self, ident: str, name: str) -> dict | None:
        """The AST node that defines the record `name` (a class, or the specialization of a class template whose
        arguments are those in `name`)."""
        from .lower import fill_locations
        nodes = clang_ast.dump(self.source, ident, **self.dump_args)
        fill_locations(nodes)
        want = re.sub(r"\s+", "", name.split("::")[-1] if "<" not in name else name[name.rfind("::", 0, name.find("<")) + 2
                                                                                  if "::" in name[:name.find("<")] else 0:])
        found, loose = [], []

        def split(s: str) -> list[str]:
            parts, depth, cur = [], 0, ""
            for ch in s:
                depth += ch in "<(" 
                depth -= ch in ">)"
                if ch == "," and depth == 0:
                    parts.append(cur)
                    cur = ""
                else:
                    cur += ch
            return parts + [cur]

        def args_of(n) -> str:
            parts = []
            for a in n.get("inner", []):
                if a.get("kind") == "TemplateArgument":
                    if "value" in a:
                        parts.append(str(a["value"]))
                    elif a.get("type"):
                        parts.append(a["type"].get("qualType", ""))
            return ",".join(parts)

        def go(n):
            if isinstance(n, dict):
                k = n.get("kind")
                if k == "ClassTemplatePartialSpecializationDecl":
                    return                                 # a pattern, not a class
                if k in ("CXXRecordDecl", "ClassTemplateSpecializationDecl") and n.get("name") == ident and n.get("completeDefinition"):
                    printed = ident + (f"<{args_of(n)}>" if k == "ClassTemplateSpecializationDecl" else "")
                    got = re.sub(r"\s+", "", self.clean(printed))
                    if got == want:
                        found.append(n)
                    elif k == "ClassTemplateSpecializationDecl" and "<" in want:
                        # an enumerator among the arguments is printed here as its number
                        a, b = split(got[got.find("<") + 1:-1]), split(want[want.find("<") + 1:-1])
                        if len(a) == len(b) and all(x == y or (re.fullmatch(r"-?\d+", x) and re.fullmatch(r"[A-Za-z_][\w:]*", y)) for x, y in zip(a, b)):
                            loose.append(n)
                for c in n.get("inner", []):
                    go(c)

        for n in nodes:
            go(n)
        if not found and len(loose) == 1:
            found = loose
        # a specialization whose members were instantiated has the bodies; prefer the one with most of them
        return max(found, key=lambda n: sum(1 for c in n.get("inner", []) if any(x.get("kind") == "CompoundStmt"
                                                                              for x in c.get("inner", []))), default=None)

    # ---- pointers and objects ----------------------------------------------------------------------
    @staticmethod
    def space_of(p: Value) -> str:
        return p.type.name or "ptr"

    def retype(self, p: Value, elem: Type, node=None) -> Value:
        t = Type("ptr", 64, elem=elem, name=p.type.name)
        return p if p.type == t else self.emit("bitcast", [p], t, node, "p")

    def at(self, p: Value, offset: int, d, node=None) -> Value:
        """A pointer `offset` bytes into the object `p` points to, described by `d`."""
        q = self.retype(p, T("u8"), node)
        if offset or not isinstance(d, Type):              # a value of its own: its description is not `p`'s
            q = self.emit("gep", [q, Const(offset, I64)], q.type, node, "p")
        if isinstance(d, Type):
            q = self.retype(q, d, node)
        else:
            self.desc[id(q)] = d
        return q

    def new_object(self, d, name: str, node=None) -> Value:
        """A fresh local object described by `d`; the pointer is typed for scalars and arrays of scalars."""
        self.serial += 1
        leaf = scalar_leaf(d)
        elem = leaf if leaf is not None else T("u8")
        v = Value(self.namer.fresh(name), Type("ptr", 64, elem=elem, name="loc"))
        size = max(size_of(d), 1)
        self.entry_block.insert(0, Op("local", [], v, {"name": f"{name}{self.serial}", "bytes": size}))
        if leaf is not None and isinstance(d, Arr):
            dims, x = [], d
            while isinstance(x, Arr):
                dims.append(x.n)
                x = x.elem
            self.dims[id(v)] = tuple(dims)
        elif leaf is None:
            self.desc[id(v)] = d
        return v

    def copy_object(self, dst: Value, src: Value, d, node=None) -> None:
        for off, t in leaves(d):
            x = self.emit("load", [self.at(src, off, t, node)], t, node, "v")
            self.emit("store", [self.at(dst, off, t, node), x], None, node)

    def demote(self, decl_id: str, node=None) -> MemVar:
        """Move a scalar variable into memory (its address is taken, or a reference is bound to it)."""
        cur = self.vars[decl_id]
        if isinstance(cur, MemVar):
            return cur
        p = self.new_object(cur.type, self.names.get(decl_id, "var"), node)
        self.emit("store", [p, cur], None, node)
        self.vars[decl_id] = MemVar(p)
        return self.vars[decl_id]

    def temporary(self, x, node=None) -> Value:
        """A scalar value in a fresh object (to bind a reference to it)."""
        p = self.new_object(x.type, "tmp", node)
        self.emit("store", [p, x], None, node)
        return p

    def init_list(self, p: Value, d, n: dict) -> None:
        """Store the elements of a braced initializer into the object at `p`."""
        items = [c for c in n.get("inner", [])]
        if isinstance(d, Arr):
            es = size_of(d.elem)
            for i, it in enumerate(items[:d.n]):
                self.init_value(self.at(p, i * es, d.elem, n), d.elem, it)
        elif isinstance(d, Rec):
            for (fname, fd, off), it in zip(d.fields, items):
                self.init_value(self.at(p, off, fd, n), fd, it)
        else:
            self.emit("store", [p, self.cast(self.rvalue(items[0]), d, n)], None, n)

    def init_value(self, p: Value, d, n: dict) -> None:
        if isinstance(d, Type):
            self.emit("store", [p, self.cast(self.rvalue(n), d, n)], None, n)
            return
        inner = n
        while inner.get("kind") in ("ExprWithCleanups", "MaterializeTemporaryExpr", "CXXBindTemporaryExpr", "CXXFunctionalCastExpr",
                                     "ImplicitCastExpr") and len(inner.get("inner", [])) == 1 and inner.get("castKind") in (None, "NoOp"):
            inner = inner["inner"][0]
        if inner.get("kind") == "InitListExpr":
            self.init_list(p, d, inner)
        elif inner.get("kind") in ("CXXConstructExpr", "CXXTemporaryObjectExpr"):
            self.construct(p, d, inner)
        else:
            x = self.rvalue(n)
            if not isinstance(x, Obj):
                self.refuse(n, "an initializer of a record that is not a record")
                raise self.Abort
            self.copy_object(p, x.ptr, d, n)

    def construct(self, p: Value, d, n: dict) -> None:
        """Run a constructor on the object at `p`."""
        args = [c for c in n.get("inner", [])]
        if not isinstance(d, Rec):
            if args:
                self.init_value(p, d, args[0])
            return
        ctype = (n.get("ctorType") or {}).get("qualType", "")
        if len(args) == 1 and re.search(r"\(\s*(const\s+)?[\w:<>, ]+\s*&&?\s*\)", ctype):     # a copy or a move
            src = self.rvalue(args[0])
            if isinstance(src, Obj):
                self.copy_object(p, src.ptr, d, n)
                return
        cands = [c for c in self.ctors.get(d.name, []) if any(x.get("kind") == "CompoundStmt" for x in c.get("inner", []))
                 and len([x for x in c.get("inner", []) if x.get("kind") == "ParmVarDecl"]) == len(args)]
        if cands:
            self.inline(cands[0], args, n, f"the constructor of `{d.name}`", this=p, this_desc=d)
        elif args:
            self.refuse(n, f"a constructor of `{d.name}` with arguments and no body in this translation unit")
            raise self.Abort

    def method(self, d, name: str, nargs: int, n: dict, ref: dict | None = None) -> dict | None:
        """The body of the member function `name` of record `d` that takes `nargs` arguments. `ref`: what the call
        refers to (its type and node id tell overloads and instantiations apart)."""
        if not isinstance(d, Rec):
            return None
        self.record(d.name)
        cands = [c for c in self.methods.get((d.name, name), [])
                 if len([x for x in c.get("inner", []) if x.get("kind") == "ParmVarDecl"]) == nargs]
        cands = [c for c in cands if c.get("mangledName")] or cands
        ref = ref or {}
        if len(cands) > 1 and (ref.get("type") or {}).get("qualType"):
            same = [c for c in cands if (c.get("type") or {}).get("qualType") == ref["type"]["qualType"]]
            cands = same or cands
        if len(cands) > 1 and ref.get("id"):
            same = [c for c in cands if c.get("id") and clang_ast.page_offset(c["id"]) == clang_ast.page_offset(ref["id"])]
            cands = same or cands
        if len(cands) > 1:
            self.refuse(n, f"member function `{name}` of `{d.name}`: several have this name and take {nargs} argument(s)")
            return None
        return cands[0] if cands else None
