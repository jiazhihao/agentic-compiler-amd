"""`mir` text: the amdclang dialect of AMDGPU assembly.

`parse` reads a module as amdclang (`-S`) or `print_module` writes it; `print_module` writes a
complete assembly file that `llvm-mc` encodes without reordering or re-allocating anything.
What is kept: the target, each kernel's instructions and blocks, its kernel descriptor and its
metadata, and data objects. What is regenerated: section and symbol boilerplate, padding.
"""
from __future__ import annotations

import re

import yaml

from .ir import REG_CLASSES, SPECIAL_WIDTH, Block, Call, Imm, Inst, Kernel, Label, Module, Operand, Reg, Sym


class AsmError(ValueError):
    def __init__(self, message: str, line: int | None = None, text: str | None = None):
        super().__init__(f"line {line}: {message}: {text!r}" if line is not None else message)
        self.message, self.line, self.text = message, line, text


_REG1 = re.compile(r"(v|s|a|ttmp)(\d+)$")
_REGN = re.compile(r"(v|s|a|ttmp)\[(\d+):(\d+)\]$")
_VREG = re.compile(r"%([A-Za-z_][\w.]*)(?::(v|s|a)(\d+)?)?$")
_INT = re.compile(r"-?(0x[0-9a-fA-F]+|\d+)$")
_FLOAT = re.compile(r"-?\d+\.\d*(e[+-]?\d+)?$")
_CALL = re.compile(r"([A-Za-z_]\w*)\((.*)\)$")
_MOD = re.compile(r"([A-Za-z_]\w*):(\S.*)$")
FLAG_MODS = frozenset({"nt", "glc", "gds", "clamp", "sc0", "sc1", "slc", "lds", "idxen", "offen", "tfe", "dlc", "acc_cd",
                       "row_mirror", "row_half_mirror"})


def _split(s: str, sep: str) -> list[str]:
    """Split at `sep` (',' or whitespace) outside brackets, parentheses and |...|."""
    out, cur, depth, bar = [], "", 0, False
    for ch in s:
        if ch in "[(":
            depth += 1
        elif ch in "])":
            depth -= 1
        elif ch == "|":
            bar = not bar
        if depth == 0 and not bar and (ch == sep if sep == "," else ch.isspace()):
            if cur.strip() or sep == ",":
                out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def parse_operand(tok: str) -> Operand:
    t = tok
    neg = abs_ = False
    if t.startswith("-|") or t.startswith("-") and not _INT.match(t) and not _FLOAT.match(t):
        neg, t = True, t[1:]
    if t.startswith("|") and t.endswith("|"):
        abs_, t = True, t[1:-1]
    m = _REG1.match(t)
    if m:
        return Reg(m.group(1), int(m.group(2)), 1, neg, abs_)
    m = _REGN.match(t)
    if m:
        lo, hi = int(m.group(2)), int(m.group(3))
        if hi < lo:
            raise AsmError(f"bad register range {tok!r}")
        return Reg(m.group(1), lo, hi - lo + 1, neg, abs_)
    m = _VREG.match(t)
    if m:
        return Reg(m.group(2) or "v", None, int(m.group(3) or 1), neg, abs_, name=m.group(1))
    if t in SPECIAL_WIDTH:
        return Reg(t, None, 1, neg, abs_)
    if neg or abs_:
        raise AsmError(f"bad operand {tok!r}")
    if _INT.match(t) or _FLOAT.match(t):
        return Imm(t)
    m = _CALL.match(t)
    if m:
        return Call(m.group(1), tuple(a.strip() for a in m.group(2).split(",")) if m.group(2).strip() else ())
    if re.fullmatch(r"\.L[\w.$]+", t):
        return Label(t)
    if re.fullmatch(r"[A-Za-z_.$][\w.$@+\-]*", t):
        return Sym(t)
    raise AsmError(f"bad operand {tok!r}")


def parse_inst(text: str) -> Inst:
    """One instruction: `mnemonic op, op, op mod:value flag`."""
    text = text.strip()
    mnemonic, _, rest = text.partition(" ") if " " in text or "\t" not in text else text.partition("\t")
    mnemonic, rest = mnemonic.strip(), rest.strip()
    if not re.fullmatch(r"[a-z][a-z0-9_]*", mnemonic):
        raise AsmError(f"bad mnemonic {mnemonic!r}")
    inst = Inst(mnemonic)
    for fld in _split(rest, ",") if rest else []:
        if not fld:
            raise AsmError("empty operand")
        for i, tok in enumerate(_split(fld, " ")):
            m = _MOD.match(tok)
            if m and not tok.startswith("%"):
                inst.mods.append((m.group(1), m.group(2)))
            elif tok in FLAG_MODS and (i > 0 or inst.operands):
                inst.mods.append((tok, None))
            elif i > 0 and not isinstance(inst.operands[-1] if inst.operands else None, Call):
                raise AsmError(f"unexpected token {tok!r}")
            else:
                inst.operands.append(parse_operand(tok))
    return inst


_BRANCH = re.compile(r"s_c?branch")


def split_at_branches(blocks: list[Block]) -> list[Block]:
    """Make every block a basic block: amdclang prints no label for the fall-through of a
    conditional branch, so a new block (with a generated label) starts after each branch that is
    followed by more instructions. Labels emit no bytes, so the code is unchanged."""
    taken = {b.label for b in blocks}
    out, n = [], 0
    for b in blocks:
        cur = Block(b.label, [], b.align)
        out.append(cur)
        for i, inst in enumerate(b.insts):
            cur.insts.append(inst)
            if _BRANCH.match(inst.mnemonic) and i + 1 < len(b.insts):
                while f".Lft{n}" in taken:
                    n += 1
                taken.add(f".Lft{n}")
                cur = Block(f".Lft{n}")
                out.append(cur)
    return out


def _strip_comment(line: str) -> str:
    out, quote = "", False
    for ch in line:
        if ch == '"':
            quote = not quote
        if ch == ";" and not quote:
            break
        out += ch
    return out.rstrip()


def parse(text: str) -> Module:
    target, version = None, None
    functions: dict[str, list[Block]] = {}
    descriptors: dict[str, dict[str, int]] = {}
    metadata: dict = {}
    data: list[str] = []
    lines = text.splitlines()
    i, n = 0, len(lines)
    func_types: set[str] = set()
    last_section = "\t.text"
    while i < n:
        raw = lines[i]
        s = _strip_comment(raw).strip()
        i += 1
        if not s:
            continue
        if s.startswith(".amdgcn_target"):
            target = s.split('"')[1]
        elif s.startswith(".amdhsa_code_object_version"):
            version = int(s.split()[1])
        elif s.startswith(".section") or s in (".text", ".data", ".bss"):
            last_section = "\t" + s
        elif s.startswith(".type"):
            name, kind = [x.strip() for x in s[5:].split(",")]
            if kind == "@function":
                func_types.add(name)
            elif kind == "@object" and not name.startswith("__hip_cuid_"):
                obj = [last_section, "\t" + s]
                while i < n:
                    t = _strip_comment(lines[i]).rstrip()
                    i += 1
                    if t.strip():
                        obj.append(t)
                    if t.strip().startswith(".size"):
                        break
                data.append("\n".join(obj))
        elif s.endswith(":") and s[:-1] in func_types:
            name = s[:-1]
            blocks = [Block(name)]
            pending_align = None
            while True:
                if i >= n:
                    raise AsmError(f"function {name} has no end", i)
                t = _strip_comment(lines[i]).strip()
                i += 1
                if not t:
                    continue
                if re.fullmatch(r"\.Lfunc_end\d+:", t):
                    break
                if t.endswith(":"):
                    blocks.append(Block(t[:-1], align=pending_align))
                    pending_align = None
                elif pending_align is not None:
                    raise AsmError("alignment that is not followed by a label", i, t)
                elif t.startswith(".p2align"):
                    pending_align = t[len(".p2align"):].strip()
                elif t.startswith("."):
                    raise AsmError("directive inside a function body is not supported", i, t)
                else:
                    try:
                        blocks[-1].insts.append(parse_inst(t))
                    except AsmError as e:
                        raise AsmError(e.message, i, t) from None
            functions[name] = split_at_branches(blocks)
        elif s.startswith(".amdhsa_kernel "):
            name, desc = s.split()[1], {}
            while i < n:
                t = _strip_comment(lines[i]).strip()
                i += 1
                if t == ".end_amdhsa_kernel":
                    break
                if t:
                    key, _, value = t.partition(" ")
                    if not key.startswith(".amdhsa_"):
                        raise AsmError("unexpected line in kernel descriptor", i, t)
                    try:
                        desc[key[len(".amdhsa_"):]] = int(value.strip(), 0)
                    except ValueError:
                        raise AsmError("kernel descriptor value is not a number", i, t) from None
            descriptors[name] = desc
        elif s == ".amdgpu_metadata":
            body = []
            while i < n and lines[i].strip() != ".end_amdgpu_metadata":
                body.append(lines[i])
                i += 1
            i += 1
            metadata = yaml.safe_load("\n".join(l for l in body if l.strip() != "...")) or {}
    if target is None:
        raise AsmError("no .amdgcn_target directive")
    kmeta = {k[".name"]: k for k in metadata.get("amdhsa.kernels", [])}
    kernels = []
    for name, blocks in functions.items():
        if name not in descriptors:
            raise AsmError(f"function {name} is not a kernel (calls between functions are not supported)")
        if name not in kmeta:
            raise AsmError(f"kernel {name} has no metadata")
        kernels.append(Kernel(name, blocks, descriptors[name], kmeta[name]))
    if not kernels:
        raise AsmError("no kernel in the module")
    return Module(target, version if version is not None else 6, kernels,
                  {k: v for k, v in metadata.items() if k != "amdhsa.kernels"}, data)


def parse_body(text: str, entry: str = "entry") -> list[Block]:
    """Instructions and block labels only (a kernel body written by hand or by an agent)."""
    blocks = [Block(entry)]
    pending = None
    for no, raw in enumerate(text.splitlines(), 1):
        t = _strip_comment(raw).strip()
        if not t:
            continue
        if t.endswith(":"):
            blocks.append(Block(t[:-1], align=pending))
            pending = None
        elif t.startswith(".p2align"):
            pending = t[len(".p2align"):].strip()
        elif t.startswith("."):
            raise AsmError("directives are not part of a kernel body", no, t)
        else:
            try:
                blocks[-1].insts.append(parse_inst(t))
            except AsmError as e:
                raise AsmError(e.message, no, t) from None
    return split_at_branches(blocks)


S_CODE_END = 0xBF800000        # the padding word amdclang emits after the last kernel


def print_kernel_body(k: Kernel) -> str:
    out = []
    for j, b in enumerate(k.blocks):
        if j or b.label != k.name:                      # the first block's own label, if any, is an alias of the entry
            if b.align:
                out.append(f"\t.p2align\t{b.align}")
            out.append(f"{b.label}:")
        out.extend(f"\t{inst}" + (f"\t; {inst.comment}" if inst.comment else "") for inst in b.insts)
    return "\n".join(out)


def print_module(m: Module) -> str:
    out = [f'\t.amdgcn_target "{m.target}"', f"\t.amdhsa_code_object_version {m.code_object_version}"]
    for idx, k in enumerate(m.kernels):
        out += ["\t.text", f"\t.protected\t{k.name}", f"\t.globl\t{k.name}", "\t.p2align\t8",
                f"\t.type\t{k.name},@function", f"{k.name}:", print_kernel_body(k), f".Lfunc_end{idx}:",
                f"\t.size\t{k.name}, .Lfunc_end{idx}-{k.name}",
                '\t.section\t.rodata,"a",@progbits', "\t.p2align\t6, 0x0", f"\t.amdhsa_kernel {k.name}"]
        out += [f"\t\t.amdhsa_{key} {value}" for key, value in k.descriptor.items()]
        out += ["\t.end_amdhsa_kernel"]
    out += ["\t.text", f"\t.p2alignl 6, {S_CODE_END}", f"\t.fill 256, 4, {S_CODE_END}"]
    out += m.data
    meta = {"amdhsa.kernels": [k.metadata for k in m.kernels], **m.metadata}
    out += ['\t.section\t".note.GNU-stack","",@progbits', "\t.amdgpu_metadata", "---",
            yaml.safe_dump(meta, sort_keys=False, default_flow_style=False).rstrip(), "...", "\t.end_amdgpu_metadata", ""]
    return "\n".join(out)
