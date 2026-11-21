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


def fix_waits(k: Kernel, arch: Arch | None = None, rewrite: bool = False) -> int:
    """Insert `s_waitcnt` where the waitcnt checker needs one. Returns the number inserted. `rewrite`: drop
    every wait the code has first, so that each one comes back as late and as weak as the checker allows
    (after an edit put more loads in flight, the old waits still wait for all of them)."""
    arch = arch or load_arch()
    if rewrite:
        for b in k.blocks:
            b.insts = [x for x in b.insts if x.mnemonic != "s_waitcnt"]
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

    @transform("fix_waits", "insert the s_waitcnt instructions the waitcnt checker asks for, as late as possible; "
               "rewrite=true first removes every existing wait, so all waits end up as late and as weak as is legal",
               {"rewrite": [False, True]})
    def _fix_waits(m: Module, kernel: str, rewrite: bool = False) -> Module:
        fix_waits(m.kernel(kernel), rewrite=bool(rewrite))
        return m

    @transform("unroll_loads", "unroll a counted loop, or an exec-mask loop driven by a per-lane counter, so that `factor` iterations' loads "
               "are in flight per wait (wide or offset loads; arithmetic in the original order: bit-identical)",
               {"factor": [2, 4, 8, 16], "loop": "label of the loop block (default: the first applicable)", "wide": [True, False]})
    def _unroll(m: Module, kernel: str, factor: int = 4, loop: str | None = None, wide: bool = True) -> Module:
        from . import loops
        loops.unroll_loads(m.kernel(kernel), factor, loop, wide)
        return m

    @transform("fix_hazards", "insert the s_nop wait states the hazard checker asks for")
    def _fix_hazards(m: Module, kernel: str) -> Module:
        fix_hazards(m.kernel(kernel))
        return m

    @transform("throttle", "the same code launched with an LDS reservation that lets only `workgroups_per_cu` workgroups share a "
               "compute unit (bit-identical; fewer waves compete for the memory pipeline: 1.02x to 1.04x measured on "
               "memory-bound reductions, see the knowledge base)", {"workgroups_per_cu": "integer of at least 1 (the policy tries 2 and 4)"},
               launch=True)
    def _throttle(m: Module, kernel: str, launch: dict, workgroups_per_cu: int = 4):
        from ..arch.model import load as load_arch
        arch = load_arch()
        n = int(workgroups_per_cu)
        if n < 1:
            raise ValueError("workgroups_per_cu must be at least 1")
        k = m.kernel(kernel)
        g = arch.res("lds_granule")
        total = min(arch.res("lds_per_cu") // n // g * g, arch.res("lds_per_workgroup"))
        extra = total - k.descriptor.get("group_segment_fixed_size", 0)
        cur = launch.get("lds", 0)
        if not isinstance(cur, int):
            raise ValueError(f"the launch already has a dynamic LDS size ({cur}); set the reservation with relaunch")
        if extra <= cur:
            raise ValueError(f"the kernel already reserves {total - extra + cur} bytes of LDS: {n} workgroups per compute unit is no restriction")
        launch["lds"] = extra
        return m, launch

    @transform("coarsen", "one launched workgroup runs `factor` consecutive workgroups of the original (the kernel body in a "
               "loop over virtual workgroup ids; bit-identical); the launch shrinks to ceil(grid_x / factor) and one "
               "argument carrying the original grid_x is appended", {"factor": "any integer of at least 2 (the policy tries 2, 4, 8)"}, launch=True)
    def _coarsen(m: Module, kernel: str, launch: dict, factor: int = 4):
        from . import coarsen
        k = m.kernel(kernel)
        coarsen.coarsen(k, factor)
        fix_waits(k)
        gx = launch["grid"][0]
        launch["grid"] = [f"cdiv({gx}, {factor})"] + list(launch["grid"][1:])
        launch["args"] = list(launch.get("args", [])) + [{"dtype": "u32", "value": str(gx)}]
        return m, launch
