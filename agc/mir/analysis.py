"""Program analysis of a physical `mir` kernel: what each instruction is, which registers it
reads and writes (from the ISA table), the control-flow graph, liveness and definite assignment.

A register *unit* is `(class, index)`: `("v", 3)`, `("s", 0)`, `("a", 12)`, and one unit each for
`("vcc", 0)`, `("exec", 0)`, `("scc", 0)`, `("m0", 0)`. `("lds", 0)` stands for LDS contents
written by a direct-to-LDS load.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from ..arch.model import Arch, load as load_arch
from ..isa import Instruction, Isa, table
from .ir import Call, Imm, Inst, Kernel, Label, Reg
from .verify import ASM_OMITS, select

Unit = tuple[str, int]
_SPECIAL_UNIT = {"vcc": "vcc", "vcc_lo": "vcc", "vcc_hi": "vcc", "exec": "exec", "exec_lo": "exec", "exec_hi": "exec",
                 "m0": "m0", "scc": "scc", "src_scc": "scc", "src_vccz": "vcc", "src_execz": "exec"}
_IMPLICIT_UNIT = {"OPR_SDST_EXEC": "exec", "OPR_SSRC_SPECIAL_SCC": "scc", "OPR_VCC": "vcc"}
# instructions whose destination is also read (the specification lists it as an output only)
_ACCUMULATING = re.compile(r"v_(fmac|mac|smfmac|dot\w*c)_|v_writelane_|.*_d16_hi$|v_movrel")


def units(op: Reg) -> tuple[Unit, ...]:
    if op.special:
        u = _SPECIAL_UNIT.get(op.cls)
        return ((u, 0),) if u else ()
    return tuple((op.cls, op.index + i) for i in range(op.count))


@dataclass
class Info:
    """One instruction, classified."""
    inst: Inst
    ins: Instruction | None
    form: str = ""
    uses: frozenset = frozenset()
    defs: frozenset = frozenset()
    explicit_uses: tuple = ()        # ((field, Reg), ...) in operand order
    explicit_defs: tuple = ()
    wait_states: int = 1
    # classification (LLVM's terms): VALU includes MFMA and DOT; VMEM excludes LDS (DS) operations
    valu: bool = False
    vmem: bool = False
    ds: bool = False
    smem: bool = False
    salu: bool = False
    mfma: bool = False
    dot: bool = False
    trans: bool = False
    dpp: bool = False
    sdwa: bool = False
    lds_dma: bool = False
    load: bool = False
    store: bool = False
    branch: bool = False
    cond_branch: bool = False
    terminator: bool = False
    targets: tuple = ()

    @property
    def name(self) -> str:
        return self.ins.name if self.ins else self.inst.mnemonic


def classify(inst: Inst, isa: Isa | None = None, arch: Arch | None = None) -> Info:
    isa, arch = isa or table(), arch or load_arch()
    r = isa.resolve(inst.mnemonic)
    if r is None:
        return Info(inst, None)
    ins, form, _ = r
    info = Info(inst, ins, form)
    name = ins.name
    info.ds = "DATA_SHARE" in ins.subgroups
    info.lds_dma = name.startswith(("global_load_lds_", "buffer_load_lds_"))
    info.vmem = ins.group == "VMEM" and not info.ds
    info.valu = ins.group == "VALU"
    info.smem, info.salu = ins.group == "SMEM", ins.group == "SALU"
    info.mfma = "MFMA" in ins.subgroups
    info.dot = name.startswith("v_dot")
    info.trans = "TRANSCENDENTAL" in ins.subgroups
    info.dpp, info.sdwa = form in ("dpp", "e64_dpp"), form == "sdwa"
    info.branch, info.cond_branch = "branch" in ins.flags, "cond_branch" in ins.flags
    info.terminator = "terminator" in ins.flags
    info.targets = tuple(o.name for o in inst.operands if isinstance(o, Label)) if info.branch else ()
    if name == "s_nop" and inst.operands and isinstance(inst.operands[0], Imm):
        info.wait_states = int(inst.operands[0].value) + 1
    is_mem = ins.group in ("VMEM", "SMEM")
    info.store = is_mem and ("store" in name or "write" in name)
    info.load = is_mem and not info.store and ("load" in name or "read" in name or "ATOMIC" in ins.subgroups
                                               or name in ("s_memtime", "s_memrealtime"))   # asynchronous SGPR results

    enc, specs, why = select(inst, isa, arch)
    uses, defs, xu, xd = set(), set(), [], []
    if why is None:
        for op, spec in zip(inst.operands, specs):
            if not isinstance(op, Reg):
                continue
            us = units(op)
            if spec.is_in:
                uses.update(us)
                xu.append((spec.field, op))
            if spec.is_out:
                defs.update(us)
                xd.append((spec.field, op))
                if _ACCUMULATING.match(name):
                    uses.update(us)
        for spec in enc.implicit:
            u = _IMPLICIT_UNIT.get(spec.type)
            if u:
                (uses if spec.is_in else defs).add((u, 0))
        if info.lds_dma:
            uses.add(("m0", 0))
            defs.add(("lds", 0))
        if info.ds and (info.load or info.store):
            uses.add(("lds", 0))            # a DS read or write races with a direct-to-LDS load still in flight
    else:                               # not a legal instruction: every register it names is read and written
        for op in inst.operands:
            if isinstance(op, Reg):
                uses.update(units(op))
                defs.update(units(op))
    if ins.group in ("VALU", "VMEM") and not name.startswith(("v_readlane", "v_readfirstlane", "v_writelane")):
        uses.add(("exec", 0))           # every vector operation is masked by EXEC
    info.uses, info.defs = frozenset(uses), frozenset(defs)
    info.explicit_uses, info.explicit_defs = tuple(xu), tuple(xd)
    return info


@dataclass
class Cfg:
    kernel: Kernel
    infos: list[list[Info]]                       # per block, per instruction
    succ: list[list[int]] = field(default_factory=list)
    pred: list[list[int]] = field(default_factory=list)

    @property
    def nblocks(self) -> int:
        return len(self.infos)


def cfg(k: Kernel, isa: Isa | None = None, arch: Arch | None = None) -> Cfg:
    isa, arch = isa or table(), arch or load_arch()
    index = {b.label: i for i, b in enumerate(k.blocks)}
    infos = [[classify(inst, isa, arch) for inst in b.insts] for b in k.blocks]
    succ = []
    for i, block in enumerate(infos):
        out = []
        for info in block:
            out += [index[t] for t in info.targets if t in index]
        last = block[-1] if block else None
        falls = last is None or not (last.terminator or (last.branch and not last.cond_branch))
        if falls and i + 1 < len(infos):
            out.append(i + 1)
        succ.append(list(dict.fromkeys(out)))
    pred = [[] for _ in infos]
    for i, ss in enumerate(succ):
        for s in ss:
            pred[s].append(i)
    return Cfg(k, infos, succ, pred)


def entry_defined(k: Kernel) -> frozenset:
    """Register units the runtime has set when the kernel starts (from the kernel descriptor)."""
    d = k.descriptor
    n = d.get("user_sgpr_count", 0)
    n += sum(int(bool(d.get(f"system_sgpr_workgroup_id_{x}", 0))) for x in "xyz") + int(bool(d.get("system_sgpr_workgroup_info", 0)))
    out = {("s", i) for i in range(n)} | {("v", i) for i in range(d.get("system_vgpr_workitem_id", 0) + 1)}
    return frozenset(out | {("exec", 0)})


def undefined_reads(g: Cfg) -> list[tuple[int, int, Unit]]:
    """(block, index, unit) of every read of a register that is not written on all paths from
    the entry. Flags (`scc`, `vcc`) and LDS contents are not tracked."""
    tracked = lambda u: u[0] in ("v", "s", "a", "m0")
    n = g.nblocks
    gen = []
    for block in g.infos:
        d = set()
        for info in block:
            d |= info.defs
        gen.append(d)
    universe = set().union(*gen, entry_defined(g.kernel)) if gen else set()
    inn = [set(universe) for _ in range(n)]
    inn[0] = set(entry_defined(g.kernel))
    changed = True
    while changed:
        changed = False
        for b in range(1, n):
            new = set(universe)
            for p in g.pred[b]:
                new &= inn[p] | gen[p]
            if not g.pred[b]:
                new = set(universe)              # unreachable: nothing to report
            if new != inn[b]:
                inn[b], changed = new, True
    found = []
    for b, block in enumerate(g.infos):
        have = set(inn[b])
        for i, info in enumerate(block):
            for u in sorted(info.uses):
                if tracked(u) and u not in have:
                    found.append((b, i, u))
                    have.add(u)
            have |= info.defs
    return found


def liveness(g: Cfg, masked_defs_kill: bool = False) -> list[list[frozenset]]:
    """Units live *after* each instruction. A vector write happens under EXEC, so by default it
    does not end the liveness of the register (lanes outside EXEC keep the old value);
    `masked_defs_kill=True` gives the classical analysis, valid where EXEC is known to be full."""
    n = g.nblocks
    live_in = [frozenset() for _ in range(n)]

    def kills(info: Info) -> frozenset:
        if masked_defs_kill:
            return info.defs
        return frozenset(u for u in info.defs if u[0] not in ("v", "a", "lds"))

    def walk(b: int, out: frozenset, record=None):
        live = set(out)
        for i in range(len(g.infos[b]) - 1, -1, -1):
            info = g.infos[b][i]
            if record is not None:
                record[i] = frozenset(live)
            live -= kills(info)
            live |= info.uses
        return frozenset(live)

    changed = True
    while changed:
        changed = False
        for b in range(n - 1, -1, -1):
            out = frozenset().union(*(live_in[s] for s in g.succ[b])) if g.succ[b] else frozenset()
            new = walk(b, out)
            if new != live_in[b]:
                live_in[b], changed = new, True
    result = []
    for b in range(n):
        out = frozenset().union(*(live_in[s] for s in g.succ[b])) if g.succ[b] else frozenset()
        rec = [frozenset()] * len(g.infos[b])
        walk(b, out, rec)
        result.append(rec)
    return result
