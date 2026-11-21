"""Fusing two tair programs: the second consumes an output of the first, and the composition is one
program (one kernel) in which that intermediate tensor is never stored or loaded.

    fused = fuse(rmsnorm, gelu, link={"x": "y"})       # gelu's input x is rmsnorm's output y

A kernel that touches every element once runs at the rate memory delivers and stores it, so two such
kernels in a row pay for the intermediate tensor twice (the first writes it, the second reads it).
The fused program reads the inputs of the first and writes the outputs of the second.

`fuse_manifests` does the same for two manifests: the fused manifest has the first one's shapes and
inputs, the second one's outputs, the fused program as its `program` and as its reference.
"""
from __future__ import annotations

from .ir import Call, Const, Expr, Param, Program, Stmt, TairError, Var
from .text import print_program


def _rename(e: Expr, names: dict) -> Expr:
    if isinstance(e, Var):
        return Var(names.get(e.name, e.name))
    if isinstance(e, Call):
        return Call(e.fn, tuple(_rename(a, names) for a in e.args))
    return e


def fuse(a: Program, b: Program, link: dict[str, str], name: str | None = None) -> Program:
    """`link`: {input of b: output of a}. Values of b that share a name with a value of a are renamed
    (`<b>_<name>`); shapes of b equal to a linked input's shape take the shape of a's output."""
    a_out = {o.name: o for o in a.outputs}
    for bi, ao in link.items():
        if b.param(bi) is None or b.param(bi).shape is None:
            raise TairError(f"{bi!r} is not a tensor parameter of {b.name}")
        if ao not in a_out:
            raise TairError(f"{ao!r} is not an output of {a.name}")
        if b.param(bi).dtype != a_out[ao].dtype:
            raise TairError(f"{b.name}.{bi} is {b.param(bi).dtype}, {a.name}.{ao} is {a_out[ao].dtype}")
    if not link:
        raise TairError("nothing to fuse: `link` is empty")
    shapes = {}
    for bi, ao in link.items():
        bs, as_ = b.param(bi).shape, a_out[ao].shape
        if len(bs) != len(as_) and len(bs) != 1:
            raise TairError(f"{b.name}.{bi} has rank {len(bs)}, {a.name}.{ao} rank {len(as_)}")
        if shapes.setdefault(bs, as_) != as_:
            raise TairError(f"shape {bs} of {b.name} is linked to two different shapes")
    used = {p.name for p in a.params} | {s.name for s in a.body}
    names = dict(link)
    for n in [p.name for p in b.params if p.name not in link] + [s.name for s in b.body]:
        names[n] = f"{b.name}_{n}" if n in used else n
    params = list(a.params) + [Param(names[p.name], p.dtype, None if p.shape is None else shapes.get(p.shape, p.shape))
                               for p in b.params if p.name not in link]
    body = list(a.body)
    for s in b.body:
        expr = tuple(Var(names.get(v.name, v.name)) for v in s.expr) if s.einsum is not None else _rename(s.expr, names)
        body.append(Stmt(names[s.name], expr, s.reduce, s.einsum))
    outputs = [Param(names[o.name], o.dtype, shapes.get(o.shape, o.shape)) for o in b.outputs]
    p = Program(name or f"{a.name}_{b.name}", params, outputs, body)
    p.validate()
    return p


def fuse_manifests(ma, mb, link: dict[str, str], name: str | None = None, gain: float = 1.25) -> dict:
    """The manifest (as a dict) of the fused kernel of two manifests that carry tair programs. Sizes come
    from the first manifest; integer scalars of the second that carry its own sizes are dropped.

    Tolerance: relative tolerances add. When the first manifest has a `cond` allowance (a reduction that can
    cancel), the fused kernel keeps it, scaled by the first stage's magnitude: the fused program on |inputs|
    is no bound for an error made before the second stage. `gain` is how much the second stage may amplify
    an absolute error (1.13 for gelu, 1 for a cast); the caller asserts it for the second program."""
    from .reference import load_text
    pa, pb = load_text(ma, ma.program), load_text(mb, mb.program)
    f = fuse(pa, pb, link, name)
    a_outs = {po.name: mo for po, mo in zip(pa.outputs, ma.outputs())}
    b_outs = {po.name: mo for po, mo in zip(pb.outputs, mb.outputs())}
    linked_a = {a_outs[ao].name for ao in link.values()}
    by_shape = {}
    for bi, ao in link.items():
        by_shape[tuple(map(str, mb.param(bi).shape))] = list(a_outs[ao].shape)
    taken = {q.name for q in ma.params}
    fused_names = {p.name for p in f.params} | {o.name for o in f.outputs}
    params = [q.to_dict() for q in ma.params if q.name not in linked_a]
    b_prog_out = {mo.name: po for po, mo in b_outs.items()}
    for q in mb.params:
        if q.name in link:
            continue
        d = q.to_dict()
        if q.kind == "scalar" and not q.dtype.is_float and isinstance(q.value, str):
            continue                                        # a size of the second kernel: the fused one has the first's
        prog_name = b_prog_out.get(q.name, q.name)
        new = prog_name if prog_name in fused_names and prog_name not in taken else f"{pb.name}_{prog_name}"
        if q.kind == "tensor":
            d["shape"] = by_shape.get(tuple(map(str, q.shape)), list(q.shape))
        d["name"] = new if new not in taken else f"{pb.name}_{q.name}"
        taken.add(d["name"])
        params.append(d)
    text = print_program(f)
    out_names = [d["name"] for d in params if d.get("role") in ("out", "inout")]
    # errors of the first stage pass through the second: relative tolerances add; rounding the result to bf16
    # can move it by one unit in the last place (up to 2^-7 relative) when the first stage is not exact
    ta = [ma.tolerance.get(a_outs[ao].name) or ma.tolerance.get("*") or {} for ao in link.values()]
    ra, aa = max((x.get("rtol", 0) for x in ta), default=0), max((x.get("atol", 0) for x in ta), default=0)
    tol = {}
    for n, mo in zip(out_names, mb.outputs()):
        tb = mb.tolerance.get(mo.name) or mb.tolerance.get("*") or {}
        tol[n] = {"rtol": ra + tb.get("rtol", 0) + (2 ** -7 if str(mo.dtype) == "bf16" and (ra or aa) else 0),
                  "atol": max(aa, tb.get("atol", 0))}
        cond = max([x.get("cond", 0) for x in ta] + [tb.get("cond", 0)])
        if cond:
            tol[n]["cond"] = cond * gain
    reference = {"kind": "tair", "text": text}
    if any("cond" in v for v in tol.values()) and len(link) == len(out_names) == len(pa.outputs):
        reference["magnitude"] = print_program(pa)
    return {"name": f.name, "entry": f.name, "shapes": dict(ma.shapes), "bench_shapes": dict(ma.timing_symbols()),
            "dynamic": list(ma.dynamic), "launch": {"grid": list(ma.grid), "block": list(ma.block)},
            "params": params, "reference": reference, "program": {"text": text},
            "tolerance": tol, "tags": ["fused"]}
