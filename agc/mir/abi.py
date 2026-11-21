"""The kernel's contract with the runtime: resources recomputed from the instruction stream,
the kernel descriptor and the code-object metadata of a kernel agc writes itself."""
from __future__ import annotations

from dataclasses import dataclass

from ..arch.model import Arch, load as load_arch
from .ir import Block, Kernel, Module, Reg

# amdclang's descriptor for a kernel that takes its arguments through the kernarg segment pointer
# in s[0:1] and reads the workgroup id from the following SGPRs and the workitem id from v0..v2
DESCRIPTOR_DEFAULTS = {
    "group_segment_fixed_size": 0, "private_segment_fixed_size": 0, "kernarg_size": 0, "user_sgpr_count": 2,
    "user_sgpr_dispatch_ptr": 0, "user_sgpr_queue_ptr": 0, "user_sgpr_kernarg_segment_ptr": 1,
    "user_sgpr_dispatch_id": 0, "user_sgpr_kernarg_preload_length": 0, "user_sgpr_kernarg_preload_offset": 0,
    "user_sgpr_private_segment_size": 0, "uses_dynamic_stack": 0, "enable_private_segment": 0,
    "system_sgpr_workgroup_id_x": 1, "system_sgpr_workgroup_id_y": 0, "system_sgpr_workgroup_id_z": 0,
    "system_sgpr_workgroup_info": 0, "system_vgpr_workitem_id": 0, "next_free_vgpr": 0, "next_free_sgpr": 0,
    "accum_offset": 4, "reserve_vcc": 1, "float_round_mode_32": 0, "float_round_mode_16_64": 0,
    "float_denorm_mode_32": 3, "float_denorm_mode_16_64": 3, "dx10_clamp": 1, "ieee_mode": 1,
    "fp16_overflow": 0, "tg_split": 0, "exception_fp_ieee_invalid_op": 0, "exception_fp_denorm_src": 0,
    "exception_fp_ieee_div_zero": 0, "exception_fp_ieee_overflow": 0, "exception_fp_ieee_underflow": 0,
    "exception_fp_ieee_inexact": 0, "exception_int_div_zero": 0,
}
# the implicit argument block amdclang appends for HIP kernels: (value kind, offset in the block, size)
HIDDEN_ARGS = [("hidden_block_count_x", 0, 4), ("hidden_block_count_y", 4, 4), ("hidden_block_count_z", 8, 4),
               ("hidden_group_size_x", 12, 2), ("hidden_group_size_y", 14, 2), ("hidden_group_size_z", 16, 2),
               ("hidden_remainder_x", 18, 2), ("hidden_remainder_y", 20, 2), ("hidden_remainder_z", 22, 2),
               ("hidden_global_offset_x", 40, 8), ("hidden_global_offset_y", 48, 8), ("hidden_global_offset_z", 56, 8),
               ("hidden_grid_dims", 64, 2)]
HIDDEN_BLOCK_SIZE = 256


@dataclass(frozen=True)
class Arg:
    kind: str            # "global_buffer" | "by_value"
    size: int = 8        # bytes


def _align(x: int, a: int) -> int:
    return -(-x // a) * a


def register_use(k: Kernel) -> dict[str, int]:
    """One past the highest register of each class the instruction stream names."""
    top = {"v": 0, "s": 0, "a": 0}
    for inst in k.insts():
        for op in inst.operands:
            if isinstance(op, Reg) and op.cls in top and op.index is not None:
                top[op.cls] = max(top[op.cls], op.index + op.count)
    return top


def resources(k: Kernel, arch: Arch | None = None) -> dict:
    """What the descriptor and metadata must say about registers, recomputed from the code."""
    arch = arch or load_arch()
    use = register_use(k)
    vgprs, agprs = max(use["v"], 1), use["a"]
    sgprs = use["s"]
    return {"next_free_vgpr": arch.accum_offset(vgprs) + agprs if agprs else vgprs, "next_free_sgpr": sgprs,
            "accum_offset": arch.accum_offset(vgprs), "vgpr_count": vgprs, "agpr_count": agprs,
            "sgpr_count": sgprs + arch.res("sgpr_reserved")}


def arg_layout(args: list[Arg], hidden: bool) -> tuple[list[dict], int]:
    """Metadata `.args` and the kernarg segment size, with amdclang's layout."""
    out, off = [], 0
    for a in args:
        off = _align(off, min(a.size, 8))
        entry = {".offset": off, ".size": a.size, ".value_kind": a.kind}
        if a.kind == "global_buffer":
            entry = {".address_space": "global", **entry}
        out.append(entry)
        off += a.size
    if hidden:
        base = _align(off, 8)
        out += [{".offset": base + o, ".size": size, ".value_kind": kind} for kind, o, size in HIDDEN_ARGS]
        off = base + HIDDEN_BLOCK_SIZE
    return out, _align(off, 8) if not hidden else off


def make_kernel(name: str, blocks: list[Block], args: list[Arg], *, hidden_args: bool = False, lds_bytes: int = 0,
                workgroup_id: str = "x", workitem_id: int = 0, descriptor: dict | None = None,
                arch: Arch | None = None) -> Kernel:
    """A kernel with its descriptor and metadata derived from the code and the argument list.
    `workgroup_id`: which of x, y, z arrive in the SGPRs after the kernarg pointer (s2, s3, s4 in
    that order). `workitem_id`: 0 → v0 = x; 1 → v0, v1; 2 → v0, v1, v2."""
    arch = arch or load_arch()
    meta_args, kernarg = arg_layout(args, hidden_args)
    k = Kernel(name, blocks, {}, {})
    res = resources(k, arch)
    desc = {**DESCRIPTOR_DEFAULTS, "group_segment_fixed_size": lds_bytes, "kernarg_size": kernarg,
            **{f"system_sgpr_workgroup_id_{d}": int(d in workgroup_id) for d in "xyz"},
            "system_vgpr_workitem_id": workitem_id,
            "next_free_vgpr": res["next_free_vgpr"], "next_free_sgpr": res["next_free_sgpr"],
            "accum_offset": res["accum_offset"], **(descriptor or {})}
    k.descriptor = desc
    k.metadata = {".name": name, ".symbol": f"{name}.kd", ".args": meta_args,
                  ".kernarg_segment_align": 8, ".kernarg_segment_size": kernarg,
                  ".group_segment_fixed_size": lds_bytes, ".private_segment_fixed_size": 0,
                  ".max_flat_workgroup_size": arch.res("max_workgroup_size"), ".wavefront_size": arch.res("wave_size"),
                  ".uniform_work_group_size": 1, ".uses_dynamic_stack": False,
                  ".vgpr_count": res["vgpr_count"], ".agpr_count": res["agpr_count"], ".sgpr_count": res["sgpr_count"],
                  ".vgpr_spill_count": 0, ".sgpr_spill_count": 0, ".language": "OpenCL C", ".language_version": [2, 0]}
    return k


def append_arg(k: Kernel, size: int) -> int:
    """Declare one more by-value argument after everything the kernel takes now (hidden arguments
    included). Returns its byte offset in the kernarg segment."""
    off = _align(k.descriptor.get("kernarg_size", 0), 8)
    k.metadata.setdefault(".args", []).append({".offset": off, ".size": size, ".value_kind": "by_value"})
    k.descriptor["kernarg_size"] = off + 8
    k.metadata[".kernarg_segment_size"] = off + 8
    return off


def make_module(kernels: list[Kernel], arch: Arch | None = None) -> Module:
    arch = arch or load_arch()
    return Module(arch.target, 6, kernels, {"amdhsa.target": arch.target, "amdhsa.version": [1, 2]})


def sync_resources(k: Kernel, arch: Arch | None = None) -> Kernel:
    """Set the descriptor's and metadata's register fields to what the code uses now (after an
    edit or a pass changed the registers). Registers the runtime sets at entry stay covered."""
    arch = arch or load_arch()
    res = resources(k, arch)
    d = k.descriptor
    entry_sgprs = d.get("user_sgpr_count", 0) + sum(int(bool(d.get(f"system_sgpr_workgroup_id_{x}", 0))) for x in "xyz") \
        + int(bool(d.get("system_sgpr_workgroup_info", 0)))
    entry_vgprs = d.get("system_vgpr_workitem_id", 0) + 1
    sgprs = max(res["next_free_sgpr"], entry_sgprs)
    vgprs = max(res["vgpr_count"], entry_vgprs)
    accum = arch.accum_offset(vgprs)
    d["next_free_vgpr"] = accum + res["agpr_count"] if res["agpr_count"] else vgprs
    d["next_free_sgpr"], d["accum_offset"] = sgprs, accum
    k.metadata[".vgpr_count"], k.metadata[".agpr_count"] = vgprs, res["agpr_count"]
    k.metadata[".sgpr_count"] = sgprs + arch.res("sgpr_reserved")
    return k
