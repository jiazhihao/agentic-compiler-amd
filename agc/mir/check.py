"""The static checks every physical `mir` module must pass before any GPU job (design D6):
the ISA verifier, the kernel's contract with the runtime, undefined register reads, the waitcnt
checker, the hazard checker, and (with `encode=True`) the assembler plus the decode cross-check.
They are independent of the passes that produced the module.
"""
from __future__ import annotations

from ..arch.model import Arch, load as load_arch
from ..isa import table
from . import abi, hazards, waitcnt
from .analysis import cfg, entry_defined, undefined_reads
from .emit import EmitError, build
from .ir import Kernel, Module, Reg
from .verify import verify_kernel


def check_contract(k: Kernel, arch: Arch) -> list[dict]:
    """The descriptor and metadata must cover what the code uses."""
    out = []

    def bad(message, **extra):
        out.append({"kind": "contract", "kernel": k.name, "message": message, **extra})
    need, d, md = abi.resources(k, arch), k.descriptor, k.metadata
    use = abi.register_use(k)
    if use["a"]:
        if d.get("accum_offset", 0) < arch.accum_offset(max(use["v"], 1)) or d["accum_offset"] % arch.res("accum_offset_granule"):
            bad(f"accum_offset {d.get('accum_offset')} overlaps the {use['v']} VGPRs in use or is unaligned",
                field="accum_offset", needs=need["accum_offset"])
        if d.get("next_free_vgpr", 0) < d.get("accum_offset", 0) + use["a"]:
            bad(f"next_free_vgpr {d.get('next_free_vgpr')} does not cover {use['a']} AGPRs after accum_offset",
                field="next_free_vgpr", needs=d.get("accum_offset", 0) + use["a"])
    elif d.get("next_free_vgpr", 0) < need["next_free_vgpr"]:
        bad(f"next_free_vgpr {d.get('next_free_vgpr')} is below the {need['next_free_vgpr']} VGPRs the code uses",
            field="next_free_vgpr", needs=need["next_free_vgpr"])
    if d.get("next_free_sgpr", 0) < need["next_free_sgpr"]:
        bad(f"next_free_sgpr {d.get('next_free_sgpr')} is below the {need['next_free_sgpr']} SGPRs the code uses",
            field="next_free_sgpr", needs=need["next_free_sgpr"])
    for key in ("vgpr_count", "agpr_count", "sgpr_count"):
        if md.get("." + key, 0) < need[key]:
            bad(f"metadata {key} {md.get('.' + key)} is below the {need[key]} the code uses", field=key, needs=need[key])
    vg = arch.vgpr_alloc(max(use["v"], 1), use["a"])
    if vg > arch.res("vgprs_per_simd"):
        bad(f"{use['v']} VGPRs + {use['a']} AGPRs exceed the {arch.res('vgprs_per_simd')}-register file")
    lds = d.get("group_segment_fixed_size", 0)
    if lds != md.get(".group_segment_fixed_size", lds):
        bad("descriptor and metadata disagree on the LDS size")
    if lds > arch.res("lds_per_workgroup"):
        bad(f"LDS size {lds} exceeds {arch.res('lds_per_workgroup')} bytes")
    if d.get("kernarg_size", 0) != md.get(".kernarg_segment_size", d.get("kernarg_size", 0)):
        bad("descriptor and metadata disagree on the kernarg segment size")
    end = max((a[".offset"] + a[".size"] for a in md.get(".args", [])), default=0)
    if end > d.get("kernarg_size", 0):
        bad(f"arguments end at byte {end}, beyond the kernarg segment of {d.get('kernarg_size')} bytes")
    return out


def check_kernel(k: Kernel, arch: Arch | None = None, strict: bool = False) -> list[dict]:
    """`strict`: a read of a register that is undefined on some path is an error, not a warning.
    Code agc generates must be strict; code imported from a compiler cannot be (see below)."""
    arch = arch or load_arch()
    isa = table()
    findings = verify_kernel(k, isa, arch)
    findings += check_contract(k, arch)
    if any(f["kind"] == "illegal_instruction" for f in findings):
        return findings                       # the analyses below need legal instructions
    g = cfg(k, isa, arch)
    written = entry_defined(k).union(*(info.defs for block in g.infos for info in block))
    for b, i, u in undefined_reads(g):
        name = "m0" if u[0] == "m0" else f"{u[0]}{u[1]}"
        never = u not in written
        # the other half of a register pair that is written: the unused half of a 64-bit operand
        # (amdclang's v_mad_u64_u32 addends, widened indices)
        inst = g.infos[b][i].inst
        half = any(isinstance(op, Reg) and op.count > 1 and not op.special and op.cls == u[0]
                   and op.index <= u[1] < op.index + op.count
                   and any((op.cls, j) in written for j in range(op.index, op.index + op.count) if j != u[1])
                   for op in inst.operands)
        if half and not strict:
            never = False
        # compilers legitimately read registers that are undefined on some path (the unused half of
        # a 64-bit operand, a loop-carried mask before the first iteration): that is a warning.
        # A register nothing ever writes is an error.
        findings.append({"kind": "undefined_read", "severity": "error" if never or strict else "warning", "kernel": k.name,
                         "block": k.blocks[b].label, "index": i, "inst": str(g.infos[b][i].inst), "register": name,
                         "message": f"reads {name}, which " + ("is never written" if never else
                                                                "is not written on every path from the entry")})
    findings += waitcnt.check(k, g, arch)
    findings += hazards.check(k, g, arch)
    return findings


def static_check(m: Module, encode: bool = True, strict: bool = False) -> dict:
    """{"ok", "findings", "built" (when encoded)}. `ok`: no finding other than warnings."""
    arch = load_arch()
    findings = [f for k in m.kernels for f in check_kernel(k, arch, strict)]
    result = {"ok": all(f.get("severity") == "warning" for f in findings), "findings": findings}
    if encode and not any(f["kind"] in ("illegal_instruction", "structure") for f in findings):
        try:
            result["built"] = build(m)
        except EmitError as e:
            findings.append({"kind": "encode", "message": e.message, "detail": e.detail[-2000:]})
            result["ok"] = False
    return result
