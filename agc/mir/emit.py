"""`mir` → code object. `llvm-mc` encodes exactly the printed instructions and `ld.lld` links;
the result is cross-checked by decoding it with the ISA table, independently of LLVM."""
from __future__ import annotations

from dataclasses import dataclass

from ..isa import table
from ..runtime import toolchain
from .asm import parse, print_module
from .ir import Module


class EmitError(ValueError):
    def __init__(self, message: str, detail: str = ""):
        super().__init__(message + (f"\n{detail}" if detail else ""))
        self.message, self.detail = message, detail


@dataclass
class Built:
    hsaco: bytes
    asm: str


def build(m: Module, check: bool = True) -> Built:
    text = print_module(m)
    try:
        hsaco = toolchain.assemble(text, mcpu=m.target.rsplit("-", 1)[-1])
    except toolchain.ToolchainError as e:
        raise EmitError("the assembler rejected the module", e.output) from None
    if check:
        diffs = crosscheck(m, hsaco)
        if diffs:
            raise EmitError("the encoded instruction stream differs from the module", "\n".join(diffs))
    return Built(hsaco, text)


def crosscheck(m: Module, hsaco: bytes) -> list[str]:
    """Differences between each kernel's instructions and its machine code decoded from the
    specification. Alignment padding (`s_nop` before an aligned block) is allowed."""
    isa = table()
    text = toolchain.section(hsaco, ".text")
    funcs = {s["name"]: s for s in toolchain.symbols(hsaco) if s["type"] == "FUNC"}
    base = min((s["value"] for s in funcs.values()), default=0)
    diffs = []
    for k in m.kernels:
        if k.name not in funcs:
            diffs.append(f"{k.name}: no function symbol in the code object")
            continue
        f = funcs[k.name]
        decoded = isa.decode(text[f["value"] - base:f["value"] - base + f["size"]])
        if sum(d[3] for d in decoded) != f["size"]:
            diffs.append(f"{k.name}: undecodable word at offset {sum(d[3] for d in decoded)}")
            continue
        names = [d[1] for d in decoded]
        pos = 0
        for b in k.blocks:
            if b.align:
                while pos < len(names) and names[pos] == "s_nop" and not (b.insts and b.insts[0].mnemonic == "s_nop"
                                                                          and names[pos + 1:pos + 2] != ["s_nop"]):
                    pos += 1
            for inst in b.insts:
                want = isa.resolve(inst.mnemonic)
                want = want[0].name if want else inst.mnemonic
                if pos >= len(names) or names[pos] != want:
                    diffs.append(f"{k.name}/{b.label}: `{inst}` is encoded as {names[pos] if pos < len(names) else 'nothing'}")
                    break
                pos += 1
            else:
                continue
            break
        else:
            if pos != len(names):
                diffs.append(f"{k.name}: {len(names) - pos} extra instruction(s) in the code object")
    return diffs


def import_asm(text: str) -> Module:
    """amdclang's `-S` output (or agc's own) as a module."""
    return parse(text)
