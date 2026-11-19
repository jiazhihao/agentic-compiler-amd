"""Backend passes on physical `mir`. Each is also a session transform (an agent action).

`fix_waits` and `fix_hazards` are driven by the checkers themselves: they insert exactly what a
finding asks for, at the latest legal point (immediately before the first use), and repeat until
the checker is silent. So generated code and agent edits need not place waits or nops by hand.
"""
from __future__ import annotations

from ..arch.model import Arch, load as load_arch
from . import hazards, waitcnt
from .analysis import cfg
from .ir import Call, Imm, Inst, Kernel, Module

_LIMIT = 10_000


def fix_waits(k: Kernel, arch: Arch | None = None) -> int:
    """Insert `s_waitcnt` where the waitcnt checker needs one. Returns the number inserted."""
    arch = arch or load_arch()
    added = 0
    for _ in range(_LIMIT):
        found = waitcnt.check(k, cfg(k, arch=arch), arch)
        if not found:
            return added
        f = found[0]
        insts = k.block(f["block"]).insts
        i = f["index"]
        same = [g for g in found if g["block"] == f["block"] and g["index"] == i]
        need = {}
        for g in same:
            need[g["counter"]] = min(need.get(g["counter"], g["needs"]), g["needs"])
        if i > 0 and insts[i - 1].mnemonic == "s_waitcnt" and all(isinstance(o, Call) for o in insts[i - 1].operands):
            for o in insts[i - 1].operands:
                need[o.name] = min(need.get(o.name, int(o.args[0])), int(o.args[0]))
            insts[i - 1] = _wait(need)
        else:
            insts.insert(i, _wait(need))
            added += 1
    raise RuntimeError("fix_waits did not converge")


def _wait(need: dict) -> Inst:
    return Inst("s_waitcnt", [Call(c, (str(need[c]),)) for c in ("vmcnt", "expcnt", "lgkmcnt") if c in need])


def fix_hazards(k: Kernel, arch: Arch | None = None) -> int:
    """Insert `s_nop` where the hazard checker needs wait states. Returns the wait states added."""
    arch = arch or load_arch()
    added = 0
    for _ in range(_LIMIT):
        found = [f for f in hazards.check(k, cfg(k, arch=arch), arch) if f["rule"] != "unmodelled"]
        if not found:
            return added
        f = found[0]
        insts = k.block(f["block"]).insts
        i = f["index"]
        n = max(g["needs"] for g in found if g["block"] == f["block"] and g["index"] == i)
        if i > 0 and insts[i - 1].mnemonic == "s_nop":
            n += int(insts[i - 1].operands[0].value) + 1
            insts[i - 1] = Inst("s_nop", [Imm(str(min(n, 16) - 1))])
            if n > 16:
                insts.insert(i, Inst("s_nop", [Imm(str(n - 17))]))
        else:
            insts.insert(i, Inst("s_nop", [Imm(str(n - 1))]))
        added += f["needs"]
    raise RuntimeError("fix_hazards did not converge")


def legalize(k: Kernel, arch: Arch | None = None) -> dict:
    """Waits, then hazards (a wait is itself a wait state, so hazards are fixed last)."""
    arch = arch or load_arch()
    w = fix_waits(k, arch)
    h = fix_hazards(k, arch)
    w += fix_waits(k, arch)          # nops never create a need for waits; this is a no-op kept as a guard
    return {"waits_added": w, "wait_states_added": h}


def register_transforms() -> None:
    from ..session.session import transform

    @transform("fix_waits", "insert the s_waitcnt instructions the waitcnt checker asks for, as late as possible")
    def _fix_waits(m: Module, kernel: str) -> Module:
        fix_waits(m.kernel(kernel))
        return m

    @transform("fix_hazards", "insert the s_nop wait states the hazard checker asks for")
    def _fix_hazards(m: Module, kernel: str) -> Module:
        fix_hazards(m.kernel(kernel))
        return m
