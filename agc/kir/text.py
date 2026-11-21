"""Text form of the structured SSA core (both `kir` and `wir`).

    kir func axpy(%x: ptr<f32>, %y: ptr<f32>, %a: f32, %n: i32) {
      %t: u32 = bid.x
      %c: i1 = lt %i, %n
      if %c @if0 {
        %v: f32 = load %p @load0
        store %p, %v @store0
      } else {
      }
      merge %z: i32 = %a, %b
      loop @loop0 {
        carry %j: i32 = 0:i32, %j2 -> %jend
        %more: i1 = lt %j, %n
        while %more
        %j2: i32 = add %j, 1:i32
      }
    }

A value is `%name`; a constant is `value:type`. `[key=value, ...]` after the operation name are its
attributes; `@name` is the statement's decision site. In a loop the statements before `while` run at
the start of every iteration and compute its condition; `carry %c = init, next -> %out` is a
loop-carried value and its value after the loop. In `wir` a result carries its kind
(`%t: u i32`), and a region is `where %mask {` (lanes) or `branch %cond {` (a uniform condition).
"""
from __future__ import annotations

import re

from .ir import Const, Func, If, IRError, Loop, Merge, Op, T, Value, fmt_const


def _operand(x) -> str:
    return f"%{x.name}" if isinstance(x, Value) else f"{fmt_const(x.value, x.type)}:{x.type}"


def _decl(v: Value) -> str:
    return f"%{v.name}: {v.kind + ' ' if v.kind else ''}{v.type}"


def _attr(v) -> str:
    return "true" if v is True else "false" if v is False else str(v)


def print_func(f: Func) -> str:
    out = [f"{f.dialect} func {f.name}({', '.join(_decl(p) for p in f.params)}) {{"]

    def site(s) -> str:
        return f" @{s.site}" if s.site else ""

    def body(stmts, ind):
        pad = "  " * ind
        for s in stmts:
            if isinstance(s, Op):
                attrs = f"[{', '.join(f'{k}={_attr(v)}' for k, v in s.attrs.items())}]" if s.attrs else ""
                args = (" " + ", ".join(_operand(a) for a in s.args)) if s.args else ""
                head = f"{_decl(s.result)} = " if s.result is not None else ""
                out.append(f"{pad}{head}{s.name}{attrs}{args}{site(s)}")
            elif isinstance(s, If):
                out.append(f"{pad}{s.mode or 'if'} {_operand(s.cond)}{site(s)} {{")
                body(s.then, ind + 1)
                if s.orelse:
                    out.append(f"{pad}}} else {{")
                    body(s.orelse, ind + 1)
                out.append(f"{pad}}}")
                for m in s.merges:
                    out.append(f"{pad}merge {_decl(m.result)} = {_operand(m.a)}, {_operand(m.b)}")
            else:
                out.append(f"{pad}loop{site(s)} {{")
                for c, i, n, o in zip(s.carried, s.init, s.next, s.out):
                    out.append(f"{pad}  carry {_decl(c)} = {_operand(i)}, {_operand(n)} -> %{o.name}")
                body(s.head, ind + 1)
                out.append(f"{pad}  while {_operand(s.cond)}")
                body(s.body, ind + 1)
                out.append(f"{pad}}}")

    body(f.body, 1)
    out.append("}")
    return "\n".join(out) + "\n"


_HEAD = re.compile(r"^(kir|wir)\s+func\s+([A-Za-z_][\w.]*)\s*\((.*)\)\s*\{$")
_DECL = re.compile(r"^%([\w.]+)\s*:\s*(?:([uv])\s+)?(\S.*)$")
_OPLINE = re.compile(r"^(?:(%[\w.]+\s*:\s*[^=]+?)\s*=\s*)?([a-z][\w.]*)(\[[^\]]*\])?\s*(.*?)(?:\s+@([\w.]+))?$")
_REGION = re.compile(r"^(if|where|branch)\s+(\S+)(?:\s+@([\w.]+))?\s*\{$")
_LOOP = re.compile(r"^loop(?:\s+@([\w.]+))?\s*\{$")
_WHILE = re.compile(r"^while\s+(\S+)$")
_CARRY = re.compile(r"^carry\s+(%[\w.]+\s*:\s*[^=]+?)\s*=\s*(.+?)\s*->\s*%([\w.]+)$")
_MERGE = re.compile(r"^merge\s+(%[\w.]+\s*:\s*[^=]+?)\s*=\s*(.+)$")


def parse_func(text: str) -> Func:
    lines = [(i + 1, ln.split(";", 1)[0].strip()) for i, ln in enumerate(text.splitlines())]
    lines = [(i, ln) for i, ln in lines if ln]
    if not lines:
        raise IRError("empty program")
    env: dict[str, Value] = {}
    pending: list[tuple[int, str, list, int]] = []       # (line, name, container, index): uses before the definition (loop `next`)

    def err(no: int, msg: str):
        raise IRError(f"line {no}: {msg}")

    def decl(no: int, s: str) -> Value:
        m = _DECL.match(s.strip())
        if not m:
            err(no, f"bad value declaration {s!r}")
        if m.group(1) in env:
            err(no, f"%{m.group(1)} is defined twice")
        try:
            v = Value(m.group(1), T(m.group(3)), m.group(2))
        except IRError as e:
            err(no, str(e))
        env[v.name] = v
        return v

    def operand(no: int, s: str, later: tuple[list, int] | None = None):
        s = s.strip()
        if s.startswith("%"):
            if s[1:] not in env:
                if later is not None:
                    pending.append((no, s[1:], later[0], later[1]))
                    return None
                err(no, f"{s} is used before it is defined")
            return env[s[1:]]
        if ":" not in s:
            err(no, f"bad operand {s!r} (a value is %name, a constant is value:type)")
        val, ty = s.rsplit(":", 1)
        try:
            t = T(ty)
            if t.is_bool:
                if val not in ("true", "false"):
                    raise ValueError(val)
                return Const(val == "true", t)
            return Const(float(val) if t.is_float else int(val, 0), t)
        except (IRError, ValueError) as e:
            err(no, f"bad constant {s!r}: {e}")

    def split(s: str) -> list[str]:
        return [x for x in (p.strip() for p in s.split(",")) if x]

    no, head = lines[0]
    m = _HEAD.match(head)
    if not m:
        err(no, "expected `kir func name(%p: type, ...) {`")
    f = Func(m.group(2), [decl(no, p) for p in split(m.group(3))], [], m.group(1))
    pos = 1

    def block(stop_at_while: bool = False) -> list:
        nonlocal pos
        out = []
        while True:
            if pos >= len(lines):
                err(lines[-1][0], "missing `}`")
            no, ln = lines[pos]
            if ln == "}" or ln == "} else {" or (stop_at_while and _WHILE.match(ln)):
                return out
            pos += 1
            m = _REGION.match(ln)
            if m:
                s = If(operand(no, m.group(2)), mode=None if m.group(1) == "if" else m.group(1), site=m.group(3))
                s.then = block()
                if lines[pos][1] == "} else {":
                    pos += 1
                    s.orelse = block()
                pos += 1
                while pos < len(lines) and (mm := _MERGE.match(lines[pos][1])):
                    n2 = lines[pos][0]
                    ab = split(mm.group(2))
                    if len(ab) != 2:
                        err(n2, "merge takes two operands")
                    a, b = operand(n2, ab[0]), operand(n2, ab[1])
                    s.merges.append(Merge(decl(n2, mm.group(1)), a, b))
                    pos += 1
                out.append(s)
                continue
            m = _LOOP.match(ln)
            if m:
                s = Loop(site=m.group(1))
                outs = []
                while pos < len(lines) and (mm := _CARRY.match(lines[pos][1])):
                    n2 = lines[pos][0]
                    ab = split(mm.group(2))
                    if len(ab) != 2:
                        err(n2, "carry takes init, next")
                    s.init.append(operand(n2, ab[0]))
                    s.carried.append(decl(n2, mm.group(1)))
                    s.next.append(None)
                    nx = operand(n2, ab[1], later=(s.next, len(s.next) - 1))
                    if nx is not None:
                        s.next[-1] = nx
                    outs.append((n2, mm.group(3)))
                    pos += 1
                s.head = block(stop_at_while=True)
                mm = _WHILE.match(lines[pos][1]) if pos < len(lines) else None
                if not mm:
                    err(no, "a loop needs a `while %cond` line")
                s.cond = operand(lines[pos][0], mm.group(1))
                pos += 1
                s.body = block()
                pos += 1
                for (n2, name), c in zip(outs, s.carried):
                    s.out.append(decl(n2, f"%{name}: {c.kind + ' ' if c.kind else ''}{c.type}"))
                out.append(s)
                continue
            m = _OPLINE.match(ln)
            if not m:
                err(no, f"cannot parse {ln!r}")
            attrs = {}
            if m.group(3):
                for kv in split(m.group(3)[1:-1]):
                    if "=" not in kv:
                        err(no, f"bad attribute {kv!r}")
                    k, v = (x.strip() for x in kv.split("=", 1))
                    attrs[k] = True if v == "true" else False if v == "false" else int(v, 0) if re.fullmatch(r"-?(0x[0-9a-fA-F]+|\d+)", v) else v
            args = [operand(no, a) for a in split(m.group(4))]
            out.append(Op(m.group(2), args, decl(no, m.group(1)) if m.group(1) else None, attrs, m.group(5)))

    f.body = block()
    if pos != len(lines) - 1 or lines[pos][1] != "}":
        err(lines[pos][0], "text after the end of the function")
    for no, name, container, index in pending:
        if name not in env:
            err(no, f"%{name} is never defined")
        container[index] = env[name]
    return f
