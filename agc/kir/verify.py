"""Verifier of the structured SSA core: every value defined once and before its uses, regions
closed (a value defined inside a region is visible after it only through a merge or a loop
output), every operation well-typed by the dialect's rules. Returns findings; empty is clean."""
from __future__ import annotations

from .ir import Const, Func, If, IRError, Loop, Op, Value


def verify(f: Func, check_op=None) -> list[dict]:
    if check_op is None:
        from . import ops
        check_op = ops.check
    findings: list[dict] = []
    defined: set[int] = set()
    names: set[str] = set()

    def bad(where: str, msg: str, site=None):
        findings.append({"severity": "error", "where": where, "message": msg, **({"site": site} if site else {})})

    def define(v: Value, where: str, scope: set):
        if id(v) in defined or v.name in names:
            bad(where, f"%{v.name} is defined twice")
        defined.add(id(v))
        names.add(v.name)
        scope.add(id(v))

    def use(x, where: str, scope: set):
        if isinstance(x, Const):
            return
        if not isinstance(x, Value):
            bad(where, f"operand {x!r} is neither a value nor a constant")
        elif id(x) not in scope:
            bad(where, f"%{x.name} is used where it is not defined")

    def body(stmts, scope: set, path: str):
        for i, s in enumerate(stmts):
            where = f"{path}[{i}]"
            if isinstance(s, Op):
                for a in s.args:
                    use(a, where, scope)
                try:
                    check_op(s)
                except IRError as e:
                    bad(where, str(e), s.site)
                if s.result is not None:
                    define(s.result, where, scope)
            elif isinstance(s, If):
                use(s.cond, where, scope)
                if isinstance(s.cond, (Value, Const)) and not s.cond.type.is_bool:
                    bad(where, f"the condition is {s.cond.type}, not i1", s.site)
                st, se = set(scope), set(scope)
                body(s.then, st, f"{where}.then")
                body(s.orelse, se, f"{where}.else")
                for m in s.merges:
                    use(m.a, where, st)
                    use(m.b, where, se)
                    if m.a.type != m.result.type or m.b.type != m.result.type:
                        bad(where, f"merge %{m.result.name}: {m.a.type} and {m.b.type} into {m.result.type}", s.site)
                    define(m.result, where, scope)
            elif isinstance(s, Loop):
                for x in s.init:
                    use(x, where, scope)
                if not (len(s.carried) == len(s.init) == len(s.next) == len(s.out)):
                    bad(where, "loop: carried, init, next and out differ in length", s.site)
                inner = set(scope)
                for c, i in zip(s.carried, s.init):
                    if c.type != i.type:
                        bad(where, f"carry %{c.name}: {i.type} into {c.type}", s.site)
                    define(c, where, inner)
                body(s.head, inner, f"{where}.head")
                use(s.cond, where, inner)
                if isinstance(s.cond, (Value, Const)) and not s.cond.type.is_bool:
                    bad(where, f"the loop condition is {s.cond.type}, not i1", s.site)
                after_head = set(inner)
                body(s.body, inner, f"{where}.body")
                for c, n in zip(s.carried, s.next):
                    use(n, where, inner)
                    if isinstance(n, (Value, Const)) and n.type != c.type:
                        bad(where, f"carry %{c.name}: next is {n.type}", s.site)
                for c, o in zip(s.carried, s.out):
                    if o.type != c.type:
                        bad(where, f"loop output %{o.name}: {o.type}, carried {c.type}", s.site)
                    define(o, where, scope)
            else:
                bad(where, f"not a statement: {s!r}")

    scope: set = set()
    for p in f.params:
        define(p, "params", scope)
    body(f.body, scope, f.name)
    return findings


def assert_ok(f: Func, check_op=None) -> Func:
    found = verify(f, check_op)
    if found:
        raise IRError(f"{f.dialect} {f.name}: {found[0]['where']}: {found[0]['message']}"
                      + (f" (and {len(found) - 1} more)" if len(found) > 1 else ""))
    return f
