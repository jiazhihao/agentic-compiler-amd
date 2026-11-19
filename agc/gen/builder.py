"""Building a kernel with virtual registers.

    b = Builder("axpy")
    x = b.v()                      # a virtual VGPR; b.v(4) is a 4-register tuple, b.s(2) an SGPR pair
    b.emit("v_add_u32_e32", x, b.S(2), b.V(0))     # b.S / b.V / b.reg name physical registers
    b.label(".Lloop")
    kernel = b.finish(args, ...)   # allocate registers, insert waits and hazard nops, make the kernel

Virtual registers are `Reg`s with a `name`; `part(r, i, n)` is a view of `n` registers of tuple
`r` starting at `i`. `finish` runs linear-scan allocation (tuples aligned as the ISA requires,
intervals extended across loops), then the checker-driven `fix_waits` / `fix_hazards`.
"""
from __future__ import annotations

from ..arch.model import Arch, load as load_arch
from ..mir import abi, passes
from ..mir.asm import parse_operand, split_at_branches
from ..mir.ir import Block, Call, Imm, Inst, Kernel, Label, Reg


class GenError(ValueError):
    pass


class Builder:
    def __init__(self, name: str, arch: Arch | None = None):
        self.name, self.arch = name, arch or load_arch()
        self.blocks = [Block(name)]
        self.sizes: dict[str, tuple[str, int]] = {}
        self._n = 0
        self._labels = 0

    # ---- registers -------------------------------------------------------------
    def _new(self, cls: str, n: int) -> Reg:
        self._n += 1
        name = f"{cls}{self._n}"
        self.sizes[name] = (cls, n)
        return Reg(cls, 0, n, name=name)

    def v(self, n: int = 1) -> Reg:
        return self._new("v", n)

    def s(self, n: int = 1) -> Reg:
        return self._new("s", n)

    def a(self, n: int = 1) -> Reg:
        return self._new("a", n)

    @staticmethod
    def part(r: Reg, i: int, n: int = 1) -> Reg:
        return Reg(r.cls, r.index + i, n, name=r.name)

    @staticmethod
    def reg(text: str) -> Reg:
        return parse_operand(text)

    @staticmethod
    def V(i: int, n: int = 1) -> Reg:
        return Reg("v", i, n)

    @staticmethod
    def S(i: int, n: int = 1) -> Reg:
        return Reg("s", i, n)

    # ---- code ------------------------------------------------------------------
    def emit(self, mnemonic: str, *ops, comment: str = "", **mods) -> Inst:
        operands = []
        for o in ops:
            if isinstance(o, (Reg, Imm, Label, Call)):
                operands.append(o)
            elif isinstance(o, bool):
                raise GenError("bool operand")
            elif isinstance(o, int):
                operands.append(Imm(str(o) if -16 <= o <= 64 else hex(o & 0xFFFFFFFF)))
            elif isinstance(o, float):
                operands.append(Imm(repr(o)))
            elif isinstance(o, str):
                operands.append(Label(o) if o.startswith(".") else parse_operand(o))
            else:
                raise GenError(f"bad operand {o!r}")
        inst = Inst(mnemonic, operands, [(k, None if v is True else str(v)) for k, v in mods.items()], comment)
        self.blocks[-1].insts.append(inst)
        return inst

    def label(self, name: str | None = None, align: str | None = None) -> str:
        if name is None:
            self._labels += 1
            name = f".L{self.name}_{self._labels}"
        self.blocks.append(Block(name, align=align))
        return name

    def new_label(self) -> str:
        self._labels += 1
        return f".L{self.name}_{self._labels}"

    # ---- finish ----------------------------------------------------------------
    def finish(self, args: list[abi.Arg], *, workgroup_id: str = "x", workitem_id: int = 0, lds_bytes: int = 0,
               hidden_args: bool = False) -> Kernel:
        blocks = split_at_branches(self.blocks)
        allocate(blocks, self.sizes, self.arch)
        blocks[0].label = self.name
        k = abi.make_kernel(self.name, blocks, args, workgroup_id=workgroup_id, workitem_id=workitem_id,
                            lds_bytes=lds_bytes, hidden_args=hidden_args, arch=self.arch)
        passes.legalize(k, self.arch)
        abi.sync_resources(k, self.arch)
        from ..mir.analysis import cfg, undefined_reads
        g = cfg(k, arch=self.arch)
        bad = undefined_reads(g)
        if bad:                                              # a generator bug, never a property of the program
            bi, ii, u = bad[0]
            raise GenError(f"generated code reads {u[0]}{u[1]} before it is written on some path: "
                           f"{k.blocks[bi].label}[{ii}] `{g.infos[bi][ii].inst}`")
        return k


def allocate(blocks: list[Block], sizes: dict[str, tuple[str, int]], arch: Arch) -> dict[str, int]:
    """Linear-scan allocation of the virtual registers in `blocks` (rewritten in place). Returns
    the base physical register of each virtual one."""
    order = [(bi, ii, inst) for bi, b in enumerate(blocks) for ii, inst in enumerate(b.insts)]
    pos_of_block, n = {}, 0
    for bi, b in enumerate(blocks):
        pos_of_block[b.label] = n
        n += len(b.insts)
    first, last = {}, {}
    reserved = {"v": set(), "s": set(), "a": set()}
    for p, (_, _, inst) in enumerate(order):
        for op in inst.operands:
            if not isinstance(op, Reg):
                continue
            if op.name is not None:
                if op.name not in sizes:
                    raise GenError(f"unknown virtual register %{op.name}")
                first.setdefault(op.name, p)
                last[op.name] = p
            elif op.cls in reserved:
                reserved[op.cls].update(range(op.index, op.index + op.count))
    # a value live into, out of, or around a loop occupies its register for the whole loop
    loops = []
    for p, (_, _, inst) in enumerate(order):
        for op in inst.operands:
            if isinstance(op, Label) and op.name in pos_of_block and pos_of_block[op.name] <= p:
                loops.append((pos_of_block[op.name], p))
    changed = True
    while changed:
        changed = False
        for lo, hi in loops:
            for name in first:
                if first[name] <= hi and last[name] >= lo and (first[name] < lo or last[name] > hi or True):
                    inside_only = first[name] >= lo and last[name] <= hi
                    if inside_only and not _carried(order, name, lo, hi):
                        continue
                    f2, l2 = min(first[name], lo if first[name] >= lo else first[name]), max(last[name], hi)
                    if first[name] >= lo:
                        f2 = lo
                    if (f2, l2) != (first[name], last[name]):
                        first[name], last[name], changed = f2, l2, True
    limit = {"v": arch.res("max_arch_vgprs"), "a": arch.res("max_agprs"), "s": arch.res("max_sgprs")}
    busy = {c: {} for c in limit}                      # class -> {unit: release position}
    base = {}
    for name in sorted(first, key=lambda x: (first[x], x)):
        cls, cnt = sizes[name]
        align = 1 if cnt == 1 else (arch.res("vgpr_tuple_align") if cls in ("v", "a") else min(cnt, arch.res("sgpr_tuple_align_max")))
        start = first[name]
        for b in range(0, limit[cls] - cnt + 1, align):
            units = range(b, b + cnt)
            if all(u not in reserved[cls] and busy[cls].get(u, -1) < start for u in units):
                for u in units:
                    busy[cls][u] = last[name]
                base[name] = b
                break
        else:
            raise GenError(f"out of {cls} registers for %{name} ({cnt} wide)")
    for _, _, inst in order:
        inst.operands = [Reg(o.cls, base[o.name] + o.index, o.count, o.neg, o.abs) if isinstance(o, Reg) and o.name is not None else o
                         for o in inst.operands]
    return base


def _carried(order, name: str, lo: int, hi: int) -> bool:
    """Whether a register used only inside a loop is read before it is written there (so its
    value comes from the previous iteration). Conservative: any operand position other than the
    first of the instruction counts as a read."""
    for p in range(lo, hi + 1):
        inst = order[p][2]
        for oi, op in enumerate(inst.operands):
            if isinstance(op, Reg) and op.name == name:
                return oi != 0 or inst.mnemonic.startswith(("v_fmac", "global_store", "ds_write", "v_cmp", "s_cmp"))
    return False
