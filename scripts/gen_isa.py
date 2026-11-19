#!/usr/bin/env python
"""Compile AMD's machine-readable CDNA4 ISA specification into `agc/isa/cdna4.json.gz`.

    .venv/bin/python scripts/gen_isa.py [path/to/amdgpu_isa_cdna4.xml]

The XML (`amdgpu_isa_cdna4.xml`, MIT, from gpuopen.com) is not kept in the repository; the default
path is `$AGC_ISA_XML` or `~/isa-spec/amdgpu_isa_cdna4.xml`. The output is deterministic.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "agc" / "isa" / "cdna4.json.gz"


def _bits(e) -> int:
    return int(e.text, int(e.get("Radix", "10")))


def _fields(bitmap) -> dict:
    """FieldName -> [[offset, count], ...], least significant range first."""
    out = {}
    for f in bitmap.findall("Field"):
        out[f.findtext("FieldName")] = [[int(r.findtext("BitOffset")), int(r.findtext("BitCount"))]
                                        for r in f.findall("BitLayout/Range")]
    return out


def _flag(e, name) -> bool:
    return e.findtext(f"InstructionFlags/{name}") == "TRUE"


def convert(xml_path: Path) -> dict:
    raw = xml_path.read_bytes()
    root = ET.fromstring(raw)
    doc, isa = root.find("Document"), root.find("ISA")
    encodings = {}
    for e in isa.find("Encodings"):
        encodings[e.findtext("EncodingName")] = {
            "bits": int(e.findtext("BitCount")), "mask": _bits(e.find("EncodingIdentifierMask")),
            "ids": sorted(_bits(i) for i in e.find("EncodingIdentifiers")),
            "fields": _fields(e.find("MicrocodeFormat/BitMap")),
            "conditions": [c.findtext("ConditionName") for c in e.findall("EncodingConditions/EncodingCondition")],
        }
    operand_types = {}
    for o in isa.find("OperandTypes"):
        t = {"values": {p.findtext("Name"): int(p.findtext("Value"))
                        for p in o.findall("OperandPredefinedValues/PredefinedValue")},
             "subtypes": [s.text for s in o.findall("Subtypes/Subtype")]}
        mf = o.find("MicrocodeFormat/BitMap")
        if mf is not None:
            t["fields"] = _fields(mf)
            named = {f.findtext("FieldName"): {p.findtext("Name"): int(p.findtext("Value"))
                                               for p in f.findall("FieldPredefinedValues/PredefinedValue")}
                     for f in mf.findall("Field")}
            if any(named.values()):
                t["field_values"] = {k: v for k, v in named.items() if v}
        operand_types[o.findtext("OperandTypeName")] = t
    formats = {d.findtext("DataFormatName"): {"type": d.findtext("DataType"), "bits": int(d.findtext("BitCount")),
                                              "components": int(d.findtext("ComponentCount"))}
               for d in isa.find("DataFormats")}
    instructions = {}
    for i in isa.find("Instructions"):
        encs = []
        for e in i.findall("InstructionEncodings/InstructionEncoding"):
            ops = []
            for o in sorted(e.findall("Operands/Operand"), key=lambda o: int(o.get("Order"))):
                ops.append({"field": o.findtext("FieldName"), "fmt": o.findtext("DataFormatName"),
                            "type": o.findtext("OperandType"), "size": int(o.findtext("OperandSize")),
                            "in": o.get("Input") == "true", "out": o.get("Output") == "true",
                            "implicit": o.get("IsImplicit") == "true",
                            "coded": o.get("IsBinaryMicrocodeRequired") == "true"})
            encs.append({"enc": e.findtext("EncodingName"), "cond": e.findtext("EncodingCondition"),
                         "op": _bits(e.find("Opcode")), "operands": ops})
        flags = [n for n, x in (("branch", "IsBranch"), ("cond_branch", "IsConditionalBranch"),
                                ("indirect_branch", "IsIndirectBranch"), ("terminator", "IsProgramTerminator"),
                                ("immediate", "IsImmediatelyExecuted")) if _flag(i, x)]
        instructions[i.findtext("InstructionName").lower()] = {
            "flags": flags, "group": i.findtext("FunctionalGroup/Name"),
            "subgroups": [s.text for s in i.findall("FunctionalGroup/FunctionalSubgroups/Subgroup") if s.text != "NOT_ASSIGNED"],
            "aliases": [a.text.lower() for a in i.findall("AliasedInstructionNames/InstructionName")],
            "desc": " ".join((i.findtext("Description") or "").split()), "encodings": encs}
    return {"source": {"file": xml_path.name, "sha256": hashlib.sha256(raw).hexdigest(),
                       "release": doc.findtext("ReleaseDate"), "schema": doc.findtext("SchemaVersion"),
                       "license": doc.findtext("License"), "copyright": doc.findtext("Copyright"),
                       "architecture": isa.findtext("Architecture/ArchitectureName")},
            "encodings": encodings, "operand_types": operand_types, "formats": formats,
            "instructions": dict(sorted(instructions.items()))}


def main(argv) -> int:
    xml = Path(argv[0] if argv else os.environ.get("AGC_ISA_XML", Path.home() / "isa-spec" / "amdgpu_isa_cdna4.xml"))
    data = json.dumps(convert(xml), sort_keys=True, separators=(",", ":")).encode()
    with open(OUT, "wb") as f, gzip.GzipFile(fileobj=f, mode="wb", mtime=0, filename="") as g:
        g.write(data)
    print(f"{OUT}: {len(json.loads(data)['instructions'])} instructions, {OUT.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
