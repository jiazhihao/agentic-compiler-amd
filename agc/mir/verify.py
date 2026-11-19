"""The `mir` verifier: every instruction and operand of a physical kernel is checked against
the CDNA4 instruction table. A finding is a JSON-able dict (kind, location, message)."""
from __future__ import annotations

import math

from ..arch.model import Arch, load as load_arch
from ..isa import Encoding, Isa, table
from .ir import Call, Imm, Inst, Kernel, Label, Module, Reg, Sym

# a modifier is legal when the encoding has one of these fields (None: checked by the assembler only)
MOD_FIELDS = {"offset": ("OFFSET", "OFFSET0"), "offset0": ("OFFSET0",), "offset1": ("OFFSET1",), "nt": ("NT",),
              "glc": ("GLC", "SC1"), "gds": ("GDS",), "sc0": ("SC0",), "sc1": ("SC1",), "clamp": ("CLAMP",),
              "cbsz": ("CBSZ",), "abid": ("ABID",), "blgp": ("BLGP",), "neg": ("BLGP",), "acc_cd": ("ACC_CD",),
              "op_sel": ("OP_SEL",), "op_sel_hi": ("OP_SEL_HI",), "neg_lo": ("NEG",), "neg_hi": ("NEG_HI",),
              "mul": ("OMOD",), "div": ("OMOD",), "bitop3": None,
              "quad_perm": ("DPP_CTRL",), "row_shl": ("DPP_CTRL",), "row_shr": ("DPP_CTRL",), "row_ror": ("DPP_CTRL",),
              "wave_shl": ("DPP_CTRL",), "wave_shr": ("DPP_CTRL",), "wave_rol": ("DPP_CTRL",), "wave_ror": ("DPP_CTRL",),
              "row_mirror": ("DPP_CTRL",), "row_half_mirror": ("DPP_CTRL",), "row_bcast": ("DPP_CTRL",),
              "row_mask": ("ROW_MASK",), "bank_mask": ("BANK_MASK",), "bound_ctrl": ("BOUND_CTRL",),
              "dst_sel": ("DST_SEL",), "dst_unused": ("DST_UNUSED",), "src0_sel": ("SRC0_SEL",), "src1_sel": ("SRC1_SEL",)}
# instruction-word fields an `offset*` modifier fills, and whether the value is signed
OFFSET_FIELDS = {"offset0": (("OFFSET0",), False), "offset1": (("OFFSET1",), False)}
SIGNED_OFFSET = ("ENC_FLAT_GLBL", "ENC_FLAT_SCRATCH")
# operands of the specification that the assembly syntax leaves out
ASM_OMITS = {"global_load_lds_": ("VDST",)}
COUNTERS = {"vmcnt": "vmcnt", "expcnt": "expcnt", "lgkmcnt": "lgkmcnt"}
_LIMITS = {"v": "max_arch_vgprs", "a": "max_agprs", "s": "max_sgprs"}


def _fit(op, spec, enc: Encoding, isa: Isa, arch: Arch, narrow_addr: bool = False) -> str | None:
    """Why `op` cannot be the operand `spec`, or None."""
    classes = isa.type_classes(spec.type)
    words = max(1, math.ceil(spec.size / 32))
    if narrow_addr and spec.field == "ADDR":     # with a scalar base register the vector address is a 32-bit offset
        words = 1
    fields = isa.encodings[enc.enc]["fields"]
    if isinstance(op, Reg):
        if op.name is not None:
            return "virtual register in physical code"
        if op.cls == "off":
            return None if spec.field in ("SADDR", "SOFFSET") else "`off` is only a memory base/offset"
        if (op.neg or op.abs) and not (("NEG" in fields or "SRC0_NEG" in fields) and spec.is_in):
            return "neg/abs modifier is not available in this encoding"
        cls = {"vcc_lo": "vcc", "exec_lo": "exec"}.get(op.cls, op.cls)
        if cls not in classes:
            return f"a {op.cls} register is not allowed here ({spec.type})"
        if not op.special:
            if op.index + op.count > arch.res(_LIMITS.get(op.cls, "max_sgprs")):
                return f"register index out of range"
            if op.count != words:
                return f"operand is {spec.size} bits ({words} register{'s' * (words > 1)}), got {op.count}"
            if op.count > 1:
                align = (arch.res("vgpr_tuple_align") if op.cls in ("v", "a")
                         else min(op.count, arch.res("sgpr_tuple_align_max")))
                if op.index % align:
                    return f"a {op.count}-register {op.cls} tuple must start at a multiple of {align}, not {op.cls}{op.index}"
        elif spec.size >= 32 and op.width and op.width != words:
            return f"operand is {spec.size} bits, {op.cls} is {32 * op.width}"
        return None
    if isinstance(op, Imm):
        if spec.type.startswith("OPR_SIMM") or spec.type in ("OPR_SMEM_OFFSET", "OPR_WAITCNT", "OPR_HWREG", "OPR_SENDMSG"):
            if op.is_float:
                return "integer immediate expected"
            bits = 21 if spec.type == "OPR_SMEM_OFFSET" else spec.size
            return None if -(1 << (bits - 1)) <= op.value < (1 << bits) else f"immediate does not fit in {bits} bits"
        if "const" in classes and op.text in isa.inline_constants(spec.type):
            return None
        if "literal" in classes:
            if not op.is_float and not -(1 << 31) <= op.value < (1 << 32):
                return "literal does not fit in 32 bits"
            return None
        return "this operand takes no literal constant (only the inline constants)"
    if isinstance(op, Label):
        return None if spec.type == "OPR_LABEL" else "label where a value is expected"
    if isinstance(op, Sym):
        return None if spec.type == "OPR_LABEL" or "literal" in classes else "symbol where no literal is allowed"
    if isinstance(op, Call):
        if spec.type == "OPR_WAITCNT":
            if op.name not in COUNTERS or len(op.args) != 1 or not op.args[0].isdigit():
                return f"unknown wait counter {op}"
            limit = arch[f"waitcnt.{op.name}"]
            return None if int(op.args[0]) <= limit else f"{op.name} is at most {limit}"
        return None if spec.type in ("OPR_HWREG", "OPR_SENDMSG") else f"{op.name}(...) is not an operand here"
    return "unknown operand"


def _offset_range(name: str, value: str, enc: str, fields: dict) -> str | None:
    try:
        v = int(value, 0)
    except (TypeError, ValueError):
        return None                                   # a symbol expression: left to the assembler
    if name == "offset":
        names = ("OFFSET",) if "OFFSET" in fields else ("OFFSET0", "OFFSET1")
    else:
        names = OFFSET_FIELDS[name][0]
    bits = sum(count for f in names for _, count in fields[f])
    lo, hi = (-(1 << (bits - 1)), (1 << (bits - 1)) - 1) if enc in SIGNED_OFFSET else (0, (1 << bits) - 1)
    return None if lo <= v <= hi else f"{name} {v} is outside {lo}..{hi}"


def check_inst(inst: Inst, isa: Isa, arch: Arch, labels: set[str] | None = None) -> str | None:
    """Why `inst` is not a legal CDNA4 instruction, or None."""
    return select(inst, isa, arch, labels)[2]


def select(inst: Inst, isa: Isa, arch: Arch, labels: set[str] | None = None):
    """(encoding, the specification operand of each assembly operand, None) for a legal
    instruction; (None, (), why) otherwise. For `s_waitcnt` every operand maps to the one
    counter operand."""
    enc, specs, why = _select(inst, isa, arch, labels)
    return (enc, specs, None) if why is None else (None, (), why)


def _select(inst: Inst, isa: Isa, arch: Arch, labels):
    r = isa.resolve(inst.mnemonic)
    if r is None:
        return None, (), f"unknown instruction {inst.mnemonic!r}"
    _, _, encodings = r
    ops = list(inst.operands)
    best = None
    omit = next((f for prefix, f in ASM_OMITS.items() if inst.mnemonic.startswith(prefix)), ())
    for enc in encodings:
        specs = tuple(s for s in enc.explicit if s.field not in omit)
        if specs and specs[-1].type == "OPR_WAITCNT" or any(s.type == "OPR_WAITCNT" for s in specs):
            if not ops or not all(isinstance(o, (Call, Imm)) for o in ops):
                why = "s_waitcnt takes counters"
            else:
                why = next((w for w in (_fit(o, specs[0], enc, isa, arch) for o in ops) if w), None)
                if why is None and len({o.name for o in ops if isinstance(o, Call)}) != len(ops) and len(ops) > 1:
                    why = "a wait counter is named twice"
        elif len(ops) != len(specs):
            why = f"takes {len(specs)} operand{'s' * (len(specs) != 1)}, got {len(ops)}"
        else:
            based = any(s.field == "SADDR" and isinstance(o, Reg) and o.cls != "off" for o, s in zip(ops, specs))
            why = next((f"operand {i + 1} ({s.field or s.type}): {w}" for i, (o, s) in enumerate(zip(ops, specs))
                        if (w := _fit(o, s, enc, isa, arch, based))), None)
            if why is None and sum(isinstance(o, (Imm, Sym)) and "literal" in isa.type_classes(s.type)
                                   and str(o) not in isa.inline_constants(s.type)
                                   for o, s in zip(ops, specs)) > 1:
                why = "more than one literal constant"
        if why is None:
            fields = isa.encodings[enc.enc]["fields"]
            for name, value in inst.mods:
                if name not in MOD_FIELDS:
                    why = f"unknown modifier {name!r}"
                elif MOD_FIELDS[name] is not None and not any(f in fields for f in MOD_FIELDS[name]):
                    why = f"modifier {name!r} does not exist in encoding {enc.enc}"
                elif name.startswith("offset"):
                    why = _offset_range(name, value, enc.enc, fields)
                if why:
                    break
        if why is None:
            if labels is not None:
                for o in ops:
                    if isinstance(o, Label) and o.name not in labels:
                        return None, (), f"branch to undefined label {o.name}"
            if any(s.type == "OPR_WAITCNT" for s in specs):
                specs = tuple(specs[0] for _ in ops)
            return enc, tuple(specs), None
        best = best or why
    return None, (), best


def verify_kernel(k: Kernel, isa: Isa | None = None, arch: Arch | None = None) -> list[dict]:
    isa, arch = isa or table(), arch or load_arch()
    findings = []
    labels = [b.label for b in k.blocks]
    if len(set(labels)) != len(labels):
        findings.append({"kind": "structure", "kernel": k.name, "message": "duplicate block label"})
    for b in k.blocks:
        for i, inst in enumerate(b.insts):
            why = check_inst(inst, isa, arch, set(labels))
            if why:
                findings.append({"kind": "illegal_instruction", "kernel": k.name, "block": b.label, "index": i,
                                 "inst": str(inst), "message": why})
    last = next((b.insts[-1] for b in reversed(k.blocks) if b.insts), None)
    if last is None:
        findings.append({"kind": "structure", "kernel": k.name, "message": "kernel has no instructions"})
    else:
        r = isa.resolve(last.mnemonic)
        if r and not ({"terminator", "branch"} & r[0].flags) or r and "cond_branch" in r[0].flags:
            findings.append({"kind": "structure", "kernel": k.name, "inst": str(last),
                             "message": "control falls off the end of the kernel"})
    return findings


def verify(m: Module) -> list[dict]:
    isa, arch = table(), load_arch()
    return [f for k in m.kernels for f in verify_kernel(k, isa, arch)]
