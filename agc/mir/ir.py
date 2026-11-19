"""Machine IR: one kernel's program in CDNA4 mnemonics, as data.

Physical form: every register is a concrete register and the instruction list is exactly the
shipped program. (The virtual form, with named values in place of registers, is used by the
generators and shares these classes: a `Reg` then carries a `name` instead of an `index`.)
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

REG_CLASSES = ("v", "s", "a", "ttmp")
# registers named as a whole, and their width in 32-bit words on wave64
SPECIAL_WIDTH = {"vcc": 2, "exec": 2, "vcc_lo": 1, "vcc_hi": 1, "exec_lo": 1, "exec_hi": 1, "m0": 1, "scc": 0,
                 "flat_scratch": 2, "flat_scratch_lo": 1, "flat_scratch_hi": 1, "xnack_mask": 2,
                 "xnack_mask_lo": 1, "xnack_mask_hi": 1, "off": 0, "src_vccz": 0, "src_execz": 0, "src_scc": 0,
                 "src_shared_base": 2, "src_shared_limit": 2, "src_private_base": 2, "src_private_limit": 2,
                 "src_pops_exiting_wave_id": 1, "null": 0}


@dataclass(frozen=True)
class Reg:
    """`v3`, `s[4:5]`, `a[0:15]`, `vcc`, `exec`, `off`; `neg` / `abs` are the VOP3 source modifiers."""
    cls: str                   # v | s | a | ttmp | a special name
    index: int | None = None   # first register; None for specials
    count: int = 1             # consecutive 32-bit registers
    neg: bool = False
    abs: bool = False
    name: str | None = None    # virtual form only

    @property
    def special(self) -> bool:
        return self.cls not in REG_CLASSES

    @property
    def width(self) -> int:
        """32-bit words."""
        return SPECIAL_WIDTH[self.cls] if self.special else self.count

    def regs(self) -> tuple[tuple[str, int], ...]:
        """The individual (class, index) registers this operand covers; specials as (name, 0)."""
        if self.special:
            return ((self.cls, 0),)
        return tuple((self.cls, self.index + i) for i in range(self.count))

    def plain(self) -> "Reg":
        return Reg(self.cls, self.index, self.count, name=self.name)

    def __str__(self) -> str:
        if self.name is not None:
            core = f"%{self.name}"
        elif self.special:
            core = self.cls
        elif self.count == 1:
            core = f"{self.cls}{self.index}"
        else:
            core = f"{self.cls}[{self.index}:{self.index + self.count - 1}]"
        if self.abs:
            core = f"|{core}|"
        return f"-{core}" if self.neg else core


@dataclass(frozen=True)
class Imm:
    """An immediate, kept as written (`0x400`, `-2.0`, `31`) so re-emission is exact."""
    text: str

    @property
    def is_float(self) -> bool:
        return bool(re.fullmatch(r"-?\d+\.\d*(e[+-]?\d+)?", self.text))

    @property
    def value(self) -> int | float:
        return float(self.text) if self.is_float else int(self.text, 0)

    def __str__(self) -> str:
        return self.text


@dataclass(frozen=True)
class Label:
    name: str

    def __str__(self) -> str:
        return self.name


@dataclass(frozen=True)
class Sym:
    """A symbol expression the assembler resolves (`table@rel32@lo+4`)."""
    text: str

    def __str__(self) -> str:
        return self.text


@dataclass(frozen=True)
class Call:
    """`vmcnt(0)`, `lgkmcnt(1)`, `hwreg(HW_REG_MODE, 0, 2)`."""
    name: str
    args: tuple[str, ...]

    def __str__(self) -> str:
        return f"{self.name}({', '.join(self.args)})"


Operand = Reg | Imm | Label | Sym | Call


@dataclass
class Inst:
    mnemonic: str
    operands: list[Operand] = field(default_factory=list)
    mods: list[tuple[str, str | None]] = field(default_factory=list)   # `offset:16`, `nt`, `bitop3:0xc8`, ...
    comment: str = ""

    def __str__(self) -> str:
        s = self.mnemonic
        if self.operands:
            sep = " " if all(isinstance(o, Call) for o in self.operands) else ", "
            s += " " + sep.join(str(o) for o in self.operands)
        for k, v in self.mods:
            s += f" {k}" if v is None else f" {k}:{v}"
        return s

    def mod(self, name: str, default=None):
        for k, v in self.mods:
            if k == name:
                return v
        return default

    def copy(self) -> "Inst":
        return Inst(self.mnemonic, list(self.operands), list(self.mods), self.comment)


@dataclass
class Block:
    label: str
    insts: list[Inst] = field(default_factory=list)
    align: str | None = None     # arguments of a `.p2align` before the label (`5, , 4`: pad with nops to 32 bytes if at most 4 bytes)


@dataclass
class Kernel:
    name: str
    blocks: list[Block]
    descriptor: dict[str, int]          # `.amdhsa_*` fields without the prefix, in order
    metadata: dict                      # this kernel's entry of `amdhsa.kernels`

    def insts(self):
        for b in self.blocks:
            yield from b.insts

    def block(self, label: str) -> Block:
        for b in self.blocks:
            if b.label == label:
                return b
        raise KeyError(label)


@dataclass
class Module:
    target: str                          # "amdgcn-amd-amdhsa--gfx950"
    code_object_version: int
    kernels: list[Kernel]
    metadata: dict                       # the module-level metadata without `amdhsa.kernels`
    data: list[str] = field(default_factory=list)   # raw assembly of data sections the code refers to

    def kernel(self, name: str | None = None) -> Kernel:
        if name is None and len(self.kernels) == 1:
            return self.kernels[0]
        for k in self.kernels:
            if k.name == name:
                return k
        raise KeyError(name)
