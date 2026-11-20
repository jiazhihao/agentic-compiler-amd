"""The CDNA4 instruction table (generated from AMD's machine-readable ISA specification by
`scripts/gen_isa.py`) and its query API.

Assembly mnemonics follow LLVM: an ISA name plus an encoding suffix where an instruction has
several encodings (`_e32` VOP1/VOP2/VOPC, `_e64` VOP3, `_dpp`, `_sdwa`).
"""
from __future__ import annotations

import functools
import gzip
import json
import re
from dataclasses import dataclass
from pathlib import Path

_PATH = Path(__file__).parent / "cdna4.json.gz"
_SUFFIX = re.compile(r"_(e64_dpp|e32|e64|dpp|sdwa)$")
_E32 = ("ENC_VOP1", "ENC_VOP2", "ENC_VOPC", "VOP1_INST_LITERAL", "VOP2_INST_LITERAL", "VOPC_INST_LITERAL")
_E64 = ("ENC_VOP3", "VOP3_SDST_ENC")
# instructions LLVM prints (and accepts) without a suffix although they have both forms: the 32-bit one
_UNSUFFIXED_E32 = ("v_readfirstlane_b32",)
LITERAL, DPP, SDWA = 255, 250, 249       # source-field values that announce a second word


@dataclass(frozen=True)
class Operand:
    field: str | None
    fmt: str
    type: str
    size: int
    is_in: bool
    is_out: bool
    implicit: bool
    coded: bool


@dataclass(frozen=True)
class Encoding:
    enc: str
    cond: str
    op: int
    operands: tuple[Operand, ...]

    @property
    def explicit(self) -> tuple[Operand, ...]:
        """The operands written in assembly, in order."""
        return tuple(o for o in self.operands if not o.implicit)

    @property
    def implicit(self) -> tuple[Operand, ...]:
        return tuple(o for o in self.operands if o.implicit)


@dataclass(frozen=True)
class Instruction:
    name: str
    group: str                       # VALU | VMEM | SALU | SMEM | WAVE_CONTROL | TRAP | MESSAGE
    subgroups: tuple[str, ...]       # MFMA, TRANSCENDENTAL, FLAT, DATA_SHARE, LOAD, STORE, ATOMIC, ...
    flags: frozenset[str]            # branch, cond_branch, indirect_branch, terminator, immediate
    encodings: tuple[Encoding, ...]
    desc: str


class Isa:
    def __init__(self, data: dict):
        self.source = data["source"]
        self.encodings = data["encodings"]
        self.operand_types = data["operand_types"]
        self.formats = data["formats"]
        self._raw = data["instructions"]
        self.aliases = {a: n for n, i in self._raw.items() for a in i["aliases"]}
        self._by_code: dict | None = None

    def __contains__(self, name: str) -> bool:
        return name in self._raw or name in self.aliases

    def names(self) -> list[str]:
        return list(self._raw)

    @functools.lru_cache(maxsize=None)
    def instruction(self, name: str) -> Instruction:
        name = self.aliases.get(name, name)
        r = self._raw[name]
        encs = tuple(Encoding(e["enc"], e["cond"], e["op"], tuple(
            Operand(o["field"], o["fmt"], o["type"], o["size"], o["in"], o["out"], o["implicit"], o["coded"])
            for o in e["operands"])) for e in r["encodings"])
        return Instruction(name, r["group"], tuple(r["subgroups"]), frozenset(r["flags"]), encs, r["desc"])

    @functools.lru_cache(maxsize=None)
    def resolve(self, mnemonic: str) -> tuple[Instruction, str, tuple[Encoding, ...]] | None:
        """An assembly mnemonic → (instruction, form, the encodings that form selects); None if unknown."""
        m = _SUFFIX.search(mnemonic)
        form = m.group(1) if m else ""
        base = mnemonic[:m.start()] if m else mnemonic
        if base not in self:
            if form and mnemonic in self:           # a name that merely ends like a suffix
                base, form = mnemonic, ""
            else:
                return None
        ins = self.instruction(base)
        # LLVM adds a suffix exactly when an instruction has both a 32-bit VOP form and a VOP3 form
        has_e32 = any(e.enc in _E32 for e in ins.encodings) and any(e.enc in _E64 for e in ins.encodings)
        if form == "e32":
            encs = [e for e in ins.encodings if e.enc in _E32]
        elif form == "e64":
            encs = [e for e in ins.encodings if e.enc in _E64] if has_e32 else []
        elif form in ("dpp", "e64_dpp"):
            encs = [e for e in ins.encodings if e.enc.endswith("_DPP")]
        elif form == "sdwa":
            encs = [e for e in ins.encodings if "SDWA" in e.enc]
        else:                                        # no suffix: only for instructions with no 32-bit VOP form
            if has_e32:
                encs = [e for e in ins.encodings if e.enc in _E32] if base in _UNSUFFIXED_E32 else []
            else:
                encs = [e for e in ins.encodings if "SDWA" not in e.enc and not e.enc.endswith("_DPP")]
        return (ins, form, tuple(encs)) if encs else None

    # ---- operand types ---------------------------------------------------------
    @functools.lru_cache(maxsize=None)
    def type_classes(self, type_name: str) -> frozenset[str]:
        """What an operand of this type may be: a subset of
        {v, a, s, ttmp, vcc, exec, m0, scc, const, literal, <other lower-case special names>}."""
        vals = self.operand_types[type_name]["values"]
        out = set()
        for name in vals:
            if re.fullmatch(r"v\d+", name):
                out.add("v")
            elif re.fullmatch(r"acc\d+", name):
                out.add("a")
            elif re.fullmatch(r"s\d+", name):
                out.add("s")
            elif re.fullmatch(r"TTMP\d+", name):
                out.add("ttmp")
            elif re.fullmatch(r"-?\d+(\.\d+)?", name):
                out.add("const")
            elif name in ("VCC_LO", "vcc"):
                out.add("vcc")
            elif name == "EXEC_LO":
                out.add("exec")
            elif name == "SRC_LITERAL":
                out.add("literal")
            elif name == "SRC_SCC":
                out.add("scc")
            elif name.endswith("_HI"):
                continue
            else:
                out.add(name.lower().removeprefix("src_").removesuffix("_lo"))
        return frozenset(out)

    @functools.lru_cache(maxsize=None)
    def inline_constants(self, type_name: str) -> frozenset[str]:
        return frozenset(n for n in self.operand_types[type_name]["values"] if re.fullmatch(r"-?\d+(\.\d+)?", n))

    # ---- decoding ----------------------------------------------------------------
    def _index(self) -> dict:
        if self._by_code is None:
            idx: dict = {}
            for name in self._raw:
                for e in self.instruction(name).encodings:
                    idx.setdefault((e.enc, e.op), []).append((name, e))
            self._by_code = idx
        return self._by_code

    @staticmethod
    def field(word: int, ranges) -> int:
        """Extract a (possibly split) field from an instruction word."""
        value, shift = 0, 0
        for off, count in ranges:
            value |= ((word >> off) & ((1 << count) - 1)) << shift
            shift += count
        return value

    def decode(self, code: bytes) -> list[tuple[int, str, str, int]]:
        """Machine code → [(byte offset, instruction name, encoding, size in bytes)], from the
        specification alone (independent of LLVM's disassembler). `code` is one function's bytes;
        decoding stops at a word that is not an instruction."""
        words = [int.from_bytes(code[i:i + 4], "little") for i in range(0, len(code) - len(code) % 4, 4)]
        out, i, idx = [], 0, self._index()
        sources = ("SRC0", "SRC1", "SRC2", "SSRC0", "SSRC1")
        while i < len(words):
            w = words[i]
            w64 = w | (words[i + 1] << 32 if i + 1 < len(words) else 0)
            found = None
            for enc_name, enc in self.encodings.items():
                if (w & enc["mask"]) not in enc["ids"]:
                    continue
                hits = idx.get((enc_name, self.field(w64, enc["fields"]["OP"])))
                if not hits:
                    continue
                marks = {f: self.field(w64, r) for f, r in enc["fields"].items() if f in sources}
                literal = any(v == LITERAL for v in marks.values())
                second = marks.get("SRC0") if enc_name.startswith(("ENC_VOP1", "ENC_VOP2", "ENC_VOPC", "VOP1", "VOP2", "VOPC")) else None
                for name, e in hits:
                    if e.cond.startswith("has_lit"):
                        ok = literal
                    elif e.cond == "has_dpp":
                        ok = second == DPP
                    elif e.cond == "has_sdwa":
                        ok = second == SDWA
                    elif enc_name.endswith("_LITERAL"):          # the literal is part of the instruction itself
                        ok = True
                    else:
                        ok = not literal and second not in (DPP, SDWA)
                    if ok:
                        found = (name, enc_name, enc["bits"] // 8)
                        break
                if found:
                    break
            if found is None:
                break
            out.append((4 * i, *found))
            i += found[2] // 4
        return out


@functools.cache
def table() -> Isa:
    with gzip.open(_PATH) as f:
        return Isa(json.load(f))
