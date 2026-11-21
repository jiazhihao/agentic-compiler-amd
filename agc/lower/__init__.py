"""agc's own lowering from HIP to CDNA4 assembly (roadmap phase 2).

    HIP ──Clang (parse only)──► AST ──frontend──► kir ──normalize──► kir
        ──wave lowering──► wir ──selection──► mir (virtual) ──allocation, waits, hazards──► mir

`compile_hip(manifest, overrides)` runs it and returns the module together with the plan: every
decision the lowering took, with its alternatives. `overrides` selects other alternatives
(`{"if0.branch.skip_empty": "none"}`); lowering again with a changed override is how a session
backtracks (design D14, D15).
"""
from __future__ import annotations

from dataclasses import dataclass, field

from ..kir import print_func
from ..kir.ir import Func, number_sites
from ..kir.passes import contract, cse, expand_division, licm, reduce_strength, simplify, unroll_constant_loops, widen_indices
from ..kir.verify import assert_ok
from ..manifest import Manifest
from ..mir import abi
from ..wir import ops as wops
from . import isel, sched, wave, widen
from .plan import DECISIONS, Plan, PlanError
from .table import load as load_table
from .wave import LowerError


@dataclass
class Lowered:
    module: object                       # mir Module
    plan: list[dict]                     # every decision taken
    kir: str                             # the normalized thread-level program the decisions refer to
    wir: str                             # the wave-level schedule
    overrides: dict = field(default_factory=dict)
    kir_func: object = None              # the same two programs as objects (for the interpreters)
    wir_func: object = None
    layout: list = field(default_factory=list)      # (kernarg offset, size) per parameter


def normalize(f: Func, plan: Plan) -> Func:
    """The canonical `kir` of a kernel: simplified, constant loops unrolled, floating point contracted
    as the plan says, decision sites named. Sites are stable: they depend on the source only."""
    simplify(f)
    unroll_constant_loops(f)
    from ..kir import locals as local_objects
    left = local_objects.promote(f)                        # structs, arrays, address-taken variables: back to values
    if left:
        unroll_constant_loops(f)
        left = local_objects.promote(f)
    if left:
        raise LowerError("a thread-local object stays in memory, which the lowering does not provide: " + "; ".join(left[:4]))
    if plan.choose("kernel", "fp.contract", ["on", "off"]) == "on":
        contract(f)
    from ..kir import mathlib
    mathlib.expand(f, plan)                                # after contraction: the expansions are not refused
    reduce_strength(f)
    expand_division(f)
    widen_indices(f)
    licm(f)
    for s in f.walk():
        s.site = None
    number_sites(f)
    from ..kir import idioms
    idioms.reductions(f, plan)
    # loop decisions, on the numbered sites; the copies an unrolling makes are sites `load0.1`, `loop0.x4`
    from ..kir import loops
    from ..kir.ir import Loop
    defs = {id(s.result): s for s in f.walk() if getattr(s, "result", None) is not None}
    for s in [s for s in f.walk() if isinstance(s, Loop)]:
        if isinstance(loops.counted(s, defs), loops.Counted) and not any(isinstance(x, Loop) for x in loops.walk(s.body)):
            n = plan.choose(s.site, "loop.unroll", [1, 2, 4, 8, 16])
            if n > 1:
                loops.unroll(f, s.site, n)
                widen_indices(f)
                licm(f)
    return assert_ok(f)


def abi_of(f: Func) -> tuple[list[abi.Arg], list[tuple[int, int]], int]:
    """The kernel arguments, each one's (offset, size) in the kernarg segment, and the offset of the
    hidden launch parameters (amdclang's layout, so a kernel is launched the same way either way)."""
    args = [abi.Arg("global_buffer", 8) if p.type.is_ptr else abi.Arg("by_value", p.type.size) for p in f.params]
    meta, _ = abi.arg_layout(args, True)
    layout = [(e[".offset"], e[".size"]) for e in meta[:len(args)]]
    hidden = next(e[".offset"] for e in meta if e[".value_kind"] == "hidden_block_count_x")
    return args, layout, hidden


def check_signature(m: Manifest, f: Func) -> None:
    if len(f.params) != len(m.params):
        raise LowerError(f"the kernel has {len(f.params)} parameters, the manifest {len(m.params)}")
    for p, q in zip(f.params, m.params):
        if p.type.is_ptr != (q.kind == "tensor"):
            raise LowerError(f"parameter {p.name}: {p.type} in the source, a {q.kind} in the manifest")
        if q.kind == "tensor" and p.type.elem.size != q.dtype.itemsize:
            raise LowerError(f"parameter {p.name}: elements of {p.type.elem.size} bytes in the source, {q.dtype} in the manifest")
        if q.kind == "scalar" and p.type.size != q.dtype.itemsize:
            raise LowerError(f"parameter {p.name}: {p.type} in the source, {q.dtype} in the manifest")


def lower_kir(f: Func, overrides: dict | None = None, arch: str = "gfx950", plan: Plan | None = None) -> Lowered:
    """From a `kir` function (as the frontend made it) to the module."""
    plan = plan or Plan(dict(overrides or {}))
    f = normalize(f, plan)
    table = load_table(arch)
    args, layout, hidden = abi_of(f)
    w = wave.lower(f, layout, table, plan)
    w = cse(licm(w))
    w = widen.forward_loads(w)
    w = sched.loads_first(w, plan)
    w = widen.merge_accesses(w, plan)
    k = isel.select(w, table, plan, args, hidden)
    plan.finish()
    return Lowered(abi.make_module([k]), plan.to_list(), print_func(f), print_func(w), dict(plan.overrides), f, w, layout)


def compile_hip(m: Manifest, overrides: dict | None = None, source: str | None = None, flags: list | None = None) -> Lowered:
    """The manifest's HIP source (or another text of the same kernel, `source`: its includes are found next to
    the manifest's source) through agc's own path. Raises `FrontendError`, `LowerError` or `PlanError`."""
    from pathlib import Path
    from ..frontend import lower_hip
    src = source or m.source
    if src is None:
        raise LowerError(f"manifest {m.name} has no HIP source")
    dirs = (Path(m.source).resolve().parent,) if source and m.source else ()
    f = lower_hip(src, m.entry, flags=[*m.hip_flags, *(flags or [])], mcpu=m.arch, include_dirs=dirs)
    check_signature(m, f)
    return lower_kir(f, overrides, m.arch)


__all__ = ["DECISIONS", "Lowered", "LowerError", "Plan", "PlanError", "compile_hip", "lower_kir", "normalize"]
