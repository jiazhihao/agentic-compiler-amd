"""The rowwise template: reductions over the last axis of a 2-D tensor and a per-row map.

One wavefront (64 lanes) per row, so no cross-wave synchronization is needed: a reduction is
accumulated per lane and combined inside the wave with DPP and `v_readlane` (no LDS, no barrier).
Each lane reads 4 consecutive elements per 256-column chunk with one `dwordx4` load; `unroll`
chunks are loaded per wait (1, 2 or 4). Columns after the last full chunk are handled one per lane
under EXEC. Every statement of the program that reduces is one pass over the row; the final map,
if the output is a tensor, is one more.

The order of a floating-point reduction differs from a serial loop (per lane, then across lanes);
the manifest's `cond` tolerance is the contract for that.
"""
from __future__ import annotations

from ..manifest import Manifest
from ..mir import abi
from ..mir.ir import Reg
from ..tair.ir import Call, Const, Expr, Program, Var, free_vars
from .binding import Compiled, bind, load_args
from .builder import Builder, GenError
from .expr import ExprCompiler

LANES, E, CHUNK = 64, 4, 256                 # one wave; elements per lane per chunk; columns per chunk
_RED = {"sum": ("v_add_f32", 0x00000000), "mean": ("v_add_f32", 0x00000000),
        "max": ("v_max_f32", 0xFF800000), "min": ("v_min_f32", 0x7F800000)}
_FN = {"v_add_f32": "add", "v_max_f32": "max", "v_min_f32": "min"}


def matches(p: Program) -> bool:
    if any(s.einsum for s in p.body):
        return False
    ranks = p.ranks()
    full = [q for q in p.params if q.shape is not None and len(q.shape) == 2]
    return (bool(full) and len(p.outputs) == 1 and any(s.reduce for s in p.body)
            and all(s.reduce in (None, "sum", "mean", "max", "min") for s in p.body)
            and ranks[p.outputs[0].name] in ("row", "full"))


def _subst(e: Expr, defs: dict) -> Expr:
    if isinstance(e, Var):
        return defs.get(e.name, e)
    if isinstance(e, Call):
        return Call(e.fn, tuple(_subst(a, defs) for a in e.args))
    return e


def _hoist(e: Expr, per_element: set, out: list) -> Expr:
    """Replace the maximal subexpressions that do not depend on the element by fresh variables
    (`out` collects (name, expr)); they are computed once per row."""
    if not isinstance(e, Call):
        return e
    if not (set(free_vars(e)) & per_element):
        name = f"_row{len(out)}"
        out.append((name, e))
        return Var(name)
    return Call(e.fn, tuple(_hoist(a, per_element, out) for a in e.args))


def generate(m: Manifest, p: Program, unroll: int = 2) -> Compiled:
    U = unroll
    if U not in (1, 2, 4):
        raise GenError("unroll must be 1, 2 or 4")
    if not matches(p):
        raise GenError("not a rowwise program (reductions over the last axis of a 2-D tensor, one output)")
    bd = bind(m, p)
    ranks = p.ranks()
    out = p.outputs[0]
    out_tensor = bd.outputs[out.name]
    full = [q.name for q in p.params if ranks[q.name] == "full"]
    vecs = [q.name for q in p.params if ranks[q.name] == "vec"]
    scalars = [q.name for q in p.params if q.shape is None]
    if any(bd.itemsize(t) != 4 for t in full + vecs + [out_tensor]):
        raise GenError("the rowwise template handles 32-bit elements")
    rsym, csym = next(q.shape for q in p.params if q.name == full[0])
    b = Builder(m.entry)
    ex = ExprCompiler(b)
    A = load_args(b, bd, list(dict.fromkeys(full + vecs + [out_tensor] + scalars + [bd.size_param(csym)])))
    C = A[bd.size_param(csym)]
    # ---- per-row setup --------------------------------------------------------------------------
    rowoff = b.s(2)                                           # row * C * 4 bytes (64-bit)
    b.emit("s_mul_hi_u32", b.part(rowoff, 1), "s2", C)
    b.emit("s_mul_i32", b.part(rowoff, 0), "s2", C)
    b.emit("s_lshl_b64", rowoff, rowoff, 2)
    base = {}
    for t in dict.fromkeys(full + ([out_tensor] if ranks[out.name] == "full" else [])):
        r = b.s(2)
        b.emit("s_add_u32", b.part(r, 0), b.part(A[t], 0), b.part(rowoff, 0))
        b.emit("s_addc_u32", b.part(r, 1), b.part(A[t], 1), b.part(rowoff, 1))
        base[t] = r
    for t in vecs:
        base[t] = A[t]
    chunks, rem, c0 = b.s(), b.s(), b.s()
    b.emit("s_lshr_b32", chunks, C, 8)                        # full 256-column chunks
    b.emit("s_and_b32", rem, C, CHUNK - 1)                    # columns after them
    b.emit("s_lshl_b32", c0, chunks, 8)
    step = {u: b.s(2) for u in sorted({U, 1})}                # address advance per loop iteration
    for u, r in step.items():
        b.emit("s_mov_b64", r, CHUNK * 4 * u)
    tstep = b.s(2)                                            # address advance of the tail loop (one wave of columns)
    b.emit("s_mov_b64", tstep, LANES * 4)
    lane16 = b.v(2)                                           # byte offset of the lane's 4 elements in a chunk
    b.emit("v_lshlrev_b32_e32", b.part(lane16, 0), 4, "v0")
    b.emit("v_mov_b32_e32", b.part(lane16, 1), 0)
    tailoff = b.v(2)                                          # byte offset of the lane's tail column
    b.emit("v_add_u32_e32", b.part(tailoff, 0), c0, "v0")
    b.emit("v_lshlrev_b32_e32", b.part(tailoff, 0), 2, b.part(tailoff, 0))
    b.emit("v_mov_b32_e32", b.part(tailoff, 1), 0)
    env = {s: A[s] for s in scalars}                          # values known per row: scalars and reduction results
    inv_c = None

    def interleaved(fns):
        """Run the code generators one after another, then interleave their instructions."""
        seqs, results = [], []
        for fn in fns:
            start = len(b.blocks[-1].insts)
            results.append(fn())
            seqs.append(b.blocks[-1].insts[start:])
            del b.blocks[-1].insts[start:]
        for i in range(max(map(len, seqs), default=0)):
            b.blocks[-1].insts += [q[i] for q in seqs if i < len(q)]
        return results

    def row_pass(expr: Expr, tensors: list[str], consume, store_to: str | None):
        """One pass over the row. `expr` is evaluated for every element; `consume(values)` gets the
        VGPRs of a group of elements (reductions accumulate; a map returns nothing and stores)."""
        hoisted = []
        expr = _hoist(expr, set(tensors), hoisted)
        local = dict(env)
        memo = {}
        for name, he in hoisted:
            local[name] = ex.compile(he, local, memo)
        used = [t for t in tensors if t in free_vars(expr)]
        touched = used + ([store_to] if store_to else [])
        addr = {}
        for t in touched:
            r = b.v(2)
            b.emit("v_lshl_add_u64", r, base[t], 0, lane16)
            addr[t] = r

        def body(u_count: int):
            data = {(t, u): b.v(E) for t in used for u in range(u_count)}
            for (t, u), r in data.items():
                b.emit("global_load_dwordx4", r, addr[t], "off", **({"offset": CHUNK * 4 * u} if u else {}))

            def one(u, e):
                return lambda: ex.vec(ex.compile(expr, {**local, **{t: b.part(data[(t, u)], e) for t in used}}, {}))
            vals = interleaved([one(u, e) for u in range(u_count) for e in range(E)])
            if store_to:
                for u in range(u_count):
                    packed = b.v(E)
                    for e in range(E):
                        b.emit("v_mov_b32_e32", b.part(packed, e), vals[u * E + e])
                    b.emit("global_store_dwordx4", addr[store_to], packed, "off", **({"offset": CHUNK * 4 * u} if u else {}))
            else:
                consume(vals)
            for t in touched:
                b.emit("v_lshl_add_u64", addr[t], addr[t], 0, step[u_count])

        cnt = b.s()
        single, tail, done = b.new_label(), b.new_label(), b.new_label()
        b.emit("s_mov_b32", cnt, chunks)
        if U > 1:
            b.emit("s_cmp_lt_u32", cnt, U)
            b.emit("s_cbranch_scc1", single)
            loop = b.label(align="5, , 4")
            body(U)
            b.emit("s_sub_u32", cnt, cnt, U)
            b.emit("s_cmp_lt_u32", cnt, U)
            b.emit("s_cbranch_scc0", loop)
        b.label(single)
        b.emit("s_cmp_eq_u32", cnt, 0)
        b.emit("s_cbranch_scc1", tail)
        loop1 = b.label()
        body(1)
        b.emit("s_sub_u32", cnt, cnt, 1)
        b.emit("s_cmp_eq_u32", cnt, 0)
        b.emit("s_cbranch_scc0", loop1)
        # ---- the columns after the last full chunk: lane l takes column c0 + l + 64 t ----------
        b.label(tail)
        b.emit("s_cmp_eq_u32", rem, 0)
        b.emit("s_cbranch_scc1", done)
        col = b.v()
        b.emit("v_add_u32_e32", col, c0, "v0")
        taddr = {}
        for t in touched:
            r = b.v(2)
            b.emit("v_lshl_add_u64", r, base[t], 0, tailoff)
            taddr[t] = r
        tloop = b.label()
        b.emit("v_cmp_gt_u32_e32", "vcc", C, col)             # the lane's column exists
        b.emit("s_and_b64", "exec", "exec", "vcc")
        b.emit("s_cbranch_execz", done)
        tdata = {t: b.v() for t in used}
        for t, r in tdata.items():
            b.emit("global_load_dword", r, taddr[t], "off")
        v = ex.vec(ex.compile(expr, {**local, **tdata}, {}))
        if store_to:
            b.emit("global_store_dword", taddr[store_to], v, "off")
        else:
            consume([v])
        b.emit("v_add_u32_e32", col, LANES, col)
        for t in touched:
            b.emit("v_lshl_add_u64", taddr[t], taddr[t], 0, tstep)
        b.emit("s_branch", tloop)
        b.label(done)
        b.emit("s_mov_b64", "exec", -1)                       # all 64 lanes again

    def wave_reduce(op: str, acc: Reg) -> Reg:
        """Combine the 64 lane values: within each row of 16 lanes by DPP, across the 4 rows through
        SGPRs. The result is in every lane."""
        cur = acc
        for perm in ({"quad_perm": "[1,0,3,2]"}, {"quad_perm": "[2,3,0,1]"}, {"row_half_mirror": True}, {"row_mirror": True}):
            nxt = b.v()
            b.emit(op + "_dpp", nxt, cur, cur, **perm, row_mask="0xf", bank_mask="0xf")
            cur = nxt
        parts = [b.s() for _ in range(4)]
        for i, s in enumerate(parts):
            b.emit("v_readlane_b32", s, cur, 16 * i)
        res = b.v()
        b.emit("v_mov_b32_e32", res, parts[0])
        for s in parts[1:]:
            b.emit(op + "_e32", res, s, res)
        return res

    defs = {}                                                 # full-rank maps that are not the output: inlined
    for s in p.body:
        expr = _subst(s.expr, defs)
        if s.reduce:
            op, identity = _RED[s.reduce]
            acc = b.v()
            b.emit("v_mov_b32_e32", acc, identity if identity else 0)

            def consume(vals, op=op, acc=acc):
                for v in vals:
                    b.emit(op + "_e32", acc, acc, v)
            row_pass(expr, full + vecs, consume, None)
            r = wave_reduce(op, acc)
            if s.reduce == "mean":
                if inv_c is None:
                    f = b.v()
                    inv_c = b.v()
                    b.emit("v_cvt_f32_u32_e32", f, C)
                    b.emit("v_rcp_f32_e32", inv_c, f)
                mean = b.v()
                b.emit("v_mul_f32_e32", mean, r, inv_c)
                r = mean
            env[s.name] = r
        elif ranks[s.name] == "full":
            if s.name == out.name:
                row_pass(expr, full + vecs, None, out_tensor)
            else:
                defs[s.name] = expr
        else:
            env[s.name] = ex.compile(expr, env, {})
    if ranks[out.name] == "row":                              # one value per row: lane 0 stores it
        dst = b.s(2)
        b.emit("s_mov_b32", b.part(dst, 1), 0)
        b.emit("s_lshl_b32", b.part(dst, 0), "s2", 2)         # row * 4 (rows < 2^30)
        b.emit("s_add_u32", b.part(dst, 0), b.part(A[out_tensor], 0), b.part(dst, 0))
        b.emit("s_addc_u32", b.part(dst, 1), b.part(A[out_tensor], 1), 0)
        zero = b.v()
        b.emit("v_mov_b32_e32", zero, 0)
        b.emit("s_mov_b64", "exec", 1)
        b.emit("global_store_dword", zero, ex.vec(env[out.name]), dst)
    b.emit("s_endpgm")
    k = b.finish(bd.args)
    rows_expr = m.param(full[0]).shape[0]                     # the grid is evaluated by the runtime, per case
    return Compiled(abi.make_module([k]), {"grid": [str(rows_expr)], "block": [LANES], "lds": 0}, "rowwise", {"unroll": U})
