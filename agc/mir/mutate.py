"""Seeded mutations of a physical kernel, to measure what the static checks catch.

Each mutation is (class, description, mutated module). The classes are the mistakes a pass or an
agent edit can make that give silent wrong results or a broken contract:
  drop_wait      an `s_waitcnt` deleted
  weaken_wait    one counter of an `s_waitcnt` raised by one, or dropped
  drop_nop       an `s_nop` deleted or shortened by one wait state
  wrong_class    a register operand moved to the other register file
  bad_width      a register operand widened or narrowed
  understate     the descriptor or metadata declares fewer registers than the code uses
  never_written  a source register replaced by one nothing writes
"""
from __future__ import annotations

import copy

from .ir import Call, Imm, Inst, Module, Reg


def _clone(m: Module) -> Module:
    return copy.deepcopy(m)


def mutations(m: Module, limits: dict | None = None):
    limits = limits or {"vmcnt": 63, "lgkmcnt": 15, "expcnt": 7}
    k0 = m.kernels[0]
    for bi, b in enumerate(k0.blocks):
        for ii, inst in enumerate(b.insts):
            where = f"{b.label}[{ii}] `{inst}`"

            def edit(fn, bi=bi, ii=ii):
                mm = _clone(m)
                fn(mm.kernels[0].blocks[bi].insts, ii)
                return mm
            if inst.mnemonic == "s_waitcnt":
                yield "drop_wait", where, edit(lambda insts, i: insts.pop(i))
                calls = [o for o in inst.operands if isinstance(o, Call)]
                for ci, c in enumerate(calls):
                    n = int(c.args[0])
                    if n < limits[c.name]:
                        def raise_(insts, i, ci=ci, c=c, n=n):
                            ops = list(insts[i].operands)
                            ops[ops.index(c)] = Call(c.name, (str(n + 1),))
                            insts[i] = Inst(insts[i].mnemonic, ops, list(insts[i].mods))
                        yield "weaken_wait", f"{where}: {c.name}({n}) -> ({n + 1})", edit(raise_)
                    if len(calls) > 1:
                        def drop_(insts, i, c=c):
                            insts[i] = Inst(insts[i].mnemonic, [o for o in insts[i].operands if o != c], [])
                        yield "weaken_wait", f"{where}: {c.name} dropped", edit(drop_)
            elif inst.mnemonic == "s_nop":
                yield "drop_nop", where, edit(lambda insts, i: insts.pop(i))
                n = int(inst.operands[0].value)
                if n > 0:
                    def shorten(insts, i, n=n):
                        insts[i] = Inst("s_nop", [Imm(str(n - 1))])
                    yield "drop_nop", f"{where}: shortened", edit(shorten)
            else:
                regs = [(oi, o) for oi, o in enumerate(inst.operands) if isinstance(o, Reg) and not o.special]
                if regs and (bi * 31 + ii) % 7 == 0:               # a deterministic sample
                    oi, r = regs[(bi + ii) % len(regs)]

                    def set_op(new, oi=oi):
                        def fn(insts, i):
                            ops = list(insts[i].operands)
                            ops[oi] = new
                            insts[i] = Inst(insts[i].mnemonic, ops, list(insts[i].mods))
                        return fn
                    other = {"v": "s", "s": "v", "a": "s"}[r.cls] if r.cls in ("v", "s", "a") else None
                    if other:
                        yield "wrong_class", f"{where}: {r} -> {other}", edit(set_op(Reg(other, r.index, r.count)))
                    yield "bad_width", f"{where}: {r} widened", edit(set_op(Reg(r.cls, r.index, r.count + 1)))
                    if oi > 0 and r.cls == "v" and r.count == 1:
                        yield "never_written", f"{where}: {r} -> v201", edit(set_op(Reg("v", 201)))
    for field in ("next_free_vgpr", "next_free_sgpr"):
        if k0.descriptor.get(field, 0) > 1:
            mm = _clone(m)
            mm.kernels[0].descriptor[field] -= 1
            yield "understate", f"descriptor {field} - 1", mm
    for field in (".vgpr_count", ".sgpr_count"):
        mm = _clone(m)
        mm.kernels[0].metadata[field] -= 1
        yield "understate", f"metadata {field} - 1", mm
