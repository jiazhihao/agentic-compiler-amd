"""tair text: parser and printer. Expressions use infix `+ - * /`, unary minus, calls and numbers."""
from __future__ import annotations

import re

from .ir import Call, Const, Expr, Param, Program, Stmt, TairError, Var

_TOK = re.compile(r"\s*(?:(\d+\.\d*(?:[eE][+-]?\d+)?|\d+(?:[eE][+-]?\d+)?|\.\d+)|([A-Za-z_]\w*)|(.))")
_INFIX = {"+": "add", "-": "sub", "*": "mul", "/": "div"}
_PREC = {"+": 1, "-": 1, "*": 2, "/": 2}


def _tokens(s: str):
    out = []
    for num, name, op in _TOK.findall(s):
        if num:
            out.append(("num", num))
        elif name:
            out.append(("name", name))
        elif op.strip():
            out.append(("op", op))
    return out


class _P:
    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else ("end", "")

    def take(self, kind=None, value=None):
        k, v = self.peek()
        if (kind and k != kind) or (value is not None and v != value):
            raise TairError(f"expected {value or kind}, got {v!r}")
        self.i += 1
        return v

    def expr(self, prec=0) -> Expr:
        k, v = self.peek()
        if k == "op" and v == "-":
            self.take()
            left = self.expr(3)
            left = Const(-left.value) if isinstance(left, Const) else Call("neg", (left,))
        elif k == "op" and v == "(":
            self.take()
            left = self.expr()
            self.take("op", ")")
        elif k == "num":
            left = Const(float(self.take()))
        elif k == "name":
            name = self.take()
            if self.peek() == ("op", "("):
                self.take()
                args = []
                if self.peek() != ("op", ")"):
                    args.append(self.expr())
                    while self.peek() == ("op", ","):
                        self.take()
                        args.append(self.expr())
                self.take("op", ")")
                left = Call(name, tuple(args))
            else:
                left = Var(name)
        else:
            raise TairError(f"unexpected {v!r} in expression")
        while True:
            k, v = self.peek()
            if k != "op" or v not in _PREC or _PREC[v] <= prec:
                return left
            self.take()
            left = Call(_INFIX[v], (left, self.expr(_PREC[v])))


def _params(text: str) -> list[Param]:
    out = []
    for part in re.split(r",(?![^\[]*\])", text):
        if not part.strip():
            continue
        m = re.fullmatch(r"\s*(\w+)\s*:\s*(\w+)\s*(?:\[([^\]]*)\])?\s*", part)
        if not m:
            raise TairError(f"bad parameter {part.strip()!r}")
        shape = None
        if m.group(3) is not None:
            shape = tuple(int(x) if x.strip().isdigit() else x.strip() for x in m.group(3).split(","))
        out.append(Param(m.group(1), m.group(2), shape))
    return out


def parse(text: str) -> Program:
    text = re.sub(r"#[^\n]*", "", text)
    m = re.fullmatch(r"\s*tair\s+(\w+)\s*\((.*?)\)\s*->\s*\((.*?)\)\s*\{(.*)\}\s*", text, re.S)
    if not m:
        raise TairError("expected `tair name(params) -> (outputs) { statements }`")
    prog = Program(m.group(1), _params(m.group(2)), _params(m.group(3)))
    for line in m.group(4).splitlines():
        line = line.strip()
        if not line:
            continue
        sm = re.fullmatch(r"(\w+)\s*=\s*(?:reduce\s+(\w+)\s*\((.*)\)|(.*))", line)
        if not sm:
            raise TairError(f"bad statement {line!r}")
        body = sm.group(3) if sm.group(2) else sm.group(4)
        p = _P(_tokens(body))
        e = p.expr()
        if p.peek()[0] != "end":
            raise TairError(f"trailing text in {line!r}")
        prog.body.append(Stmt(sm.group(1), e, sm.group(2)))
    prog.validate()
    return prog


def print_expr(e: Expr, prec: int = 0) -> str:
    if isinstance(e, Var):
        return e.name
    if isinstance(e, Const):
        return repr(e.value)
    op = {v: k for k, v in _INFIX.items()}.get(e.fn)
    if op:
        s = f"{print_expr(e.args[0], _PREC[op] - 1)} {op} {print_expr(e.args[1], _PREC[op])}"
        return f"({s})" if _PREC[op] <= prec else s
    return f"{e.fn}({', '.join(print_expr(a) for a in e.args)})"


def print_program(p: Program) -> str:
    def params(ps):
        return ", ".join(f"{q.name}: {q.dtype}" + (f"[{', '.join(map(str, q.shape))}]" if q.shape is not None else "") for q in ps)
    lines = [f"tair {p.name}({params(p.params)}) -> ({params(p.outputs)}) {{"]
    for s in p.body:
        lines.append(f"  {s.name} = " + (f"reduce {s.reduce}({print_expr(s.expr)})" if s.reduce else print_expr(s.expr)))
    return "\n".join(lines + ["}"]) + "\n"
