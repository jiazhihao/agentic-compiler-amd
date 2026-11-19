"""The MFMA GEMM template: `C[M, N] = A[M, K] @ B[N, K]^T`, bf16 inputs, f32 result.

Both operands are contiguous along K (the linear-layer form), so every lane loads its 8 bf16
elements of A and of B with one `dwordx4` load each, straight into the MFMA operand layout
(`mfma.layouts` in the arch data, measured on the device). One wavefront computes
`tiles x tiles` output tiles of 32 x 32 with `v_mfma_f32_32x32x16_bf16`, accumulating in AccVGPRs:
`tiles` A operands and `tiles` B operands feed `tiles^2` MFMAs, so a loaded element is used
`tiles` times. `unroll` K-steps (16 each) are loaded per wait.

Rows and columns beyond M and N are clamped for the loads (valid memory, results discarded) and
masked for the stores. K must be a multiple of 16.
"""
from __future__ import annotations

from ..manifest import Manifest
from ..mir import abi
from ..tair.ir import Program
from .binding import Compiled, bind, load_args
from .builder import Builder, GenError

MFMA = "v_mfma_f32_32x32x16_bf16"
TILE, KSTEP, LANES = 32, 16, 64
SPEC = "mk,nk->mn"


def matches(p: Program) -> bool:
    return len(p.body) == 1 and p.body[0].einsum == SPEC and len(p.outputs) == 1 and p.outputs[0].name == p.body[0].name


def generate(m: Manifest, p: Program, tiles: int = 2, unroll: int = 1) -> Compiled:
    T, U = tiles, unroll
    if not matches(p):
        raise GenError(f'not a GEMM program (one statement `C = einsum "{SPEC}"(A, B)`)')
    if T not in (1, 2, 4) or U not in (1, 2):
        raise GenError("tiles must be 1, 2 or 4 and unroll 1 or 2")
    bd = bind(m, p)
    an, bn = (v.name for v in p.body[0].expr)
    cn = bd.outputs[p.outputs[0].name]
    if str(m.param(an).dtype) != "bf16" or str(m.param(bn).dtype) != "bf16" or str(m.param(cn).dtype) != "f32":
        raise GenError("the MFMA GEMM template takes bf16 inputs and an f32 output")
    msym, ksym = p.param(an).shape
    nsym = p.param(bn).shape[0]
    kexpr = m.param(an).shape[1]
    for shapes in (m.shapes, m.timing_symbols()):
        from ..manifest import eval_expr
        if eval_expr(kexpr, shapes) % KSTEP or kexpr in m.dynamic:
            raise GenError(f"K must be a fixed multiple of {KSTEP} (it is {kexpr} = {eval_expr(kexpr, shapes)})")
    b = Builder(m.entry)
    A = load_args(b, bd, [an, bn, cn, bd.size_param(msym), bd.size_param(nsym), bd.size_param(ksym)])
    Mr, Nr, Kr = A[bd.size_param(msym)], A[bd.size_param(nsym)], A[bd.size_param(ksym)]
    shift = (TILE * T).bit_length() - 1
    n0, m0 = b.s(), b.s()
    b.emit("s_lshl_b32", n0, "s2", shift)                     # first column and row of this wave's tiles
    b.emit("s_lshl_b32", m0, "s3", shift)
    last_m, last_n = b.s(), b.s()
    b.emit("s_sub_u32", last_m, Mr, 1)
    b.emit("s_sub_u32", last_n, Nr, 1)
    r, g8 = b.v(), b.v(2)
    b.emit("v_and_b32_e32", r, TILE - 1, "v0")                # lane % 32: the row (A) / column (B, C) in a tile
    b.emit("v_lshrrev_b32_e32", b.part(g8, 0), 5, "v0")       # lane // 32
    g4 = b.v()
    b.emit("v_lshlrev_b32_e32", g4, 2, b.part(g8, 0))         # 4 * (lane // 32): the row offset of the result
    b.emit("v_lshlrev_b32_e32", b.part(g8, 0), 3, b.part(g8, 0))   # 8 * (lane // 32): the k offset of the operands
    b.emit("v_mov_b32_e32", b.part(g8, 1), 0)
    carry = b.s(2)

    def operand_address(ptr, origin, t, last, count):
        """Per-lane address of the lane's 8 elements of row/column `origin + 32 t + lane % 32` (clamped)."""
        idx, off, addr = b.v(), b.v(2), b.v(2)
        base = b.s()
        b.emit("s_add_u32", base, origin, TILE * t)
        b.emit("v_add_u32_e32", idx, base, r)
        b.emit("v_min_u32_e32", idx, last, idx)
        b.emit("v_mad_u64_u32", off, carry, idx, count, 0)   # index * K
        b.emit("v_lshl_add_u64", off, off, 0, g8)            # + 8 * (lane // 32)
        b.emit("v_lshl_add_u64", addr, off, 1, ptr)          # * 2 bytes + the pointer
        return addr
    addr_a = [operand_address(A[an], m0, t, last_m, Kr) for t in range(T)]
    addr_b = [operand_address(A[bn], n0, t, last_n, Kr) for t in range(T)]
    acc = [[b.a(16) for _ in range(T)] for _ in range(T)]
    zero = b.v()
    b.emit("v_mov_b32_e32", zero, 0)
    for row in acc:
        for a16 in row:
            for i in range(16):
                b.emit("v_accvgpr_write_b32", b.part(a16, i), zero)

    def body(u_count: int):
        ops_a = [[b.v(4) for _ in range(T)] for _ in range(u_count)]
        ops_b = [[b.v(4) for _ in range(T)] for _ in range(u_count)]
        for u in range(u_count):
            off = {"offset": 2 * KSTEP * u} if u else {}
            for t in range(T):
                b.emit("global_load_dwordx4", ops_a[u][t], addr_a[t], "off", **off)
                b.emit("global_load_dwordx4", ops_b[u][t], addr_b[t], "off", **off)
        for u in range(u_count):
            for tr in range(T):
                for tc in range(T):
                    b.emit(MFMA, acc[tr][tc], ops_a[u][tr], ops_b[u][tc], acc[tr][tc])
        for adr in addr_a + addr_b:
            b.emit("v_lshl_add_u64", adr, adr, 0, 2 * KSTEP * u_count)

    cnt = b.s()
    single, done = b.new_label(), b.new_label()
    b.emit("s_lshr_b32", cnt, Kr, 4)                          # K / 16 steps
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
    b.emit("s_cbranch_scc1", done)
    loop1 = b.label(align="5, , 4")
    body(1)
    b.emit("s_sub_u32", cnt, cnt, 1)
    b.emit("s_cmp_eq_u32", cnt, 0)
    b.emit("s_cbranch_scc0", loop1)
    b.label(done)
    # ---- store: register q of a tile holds row 8 (q // 4) + 4 (lane // 32) + q % 4, column lane % 32
    step1, step5 = b.s(2), b.s(2)                             # 1 and 5 rows of C in bytes
    b.emit("s_lshl_b32", b.part(step1, 0), Nr, 2)
    b.emit("s_mov_b32", b.part(step1, 1), 0)
    b.emit("s_mul_i32", b.part(step5, 0), Nr, 20)
    b.emit("s_mul_hi_u32", b.part(step5, 1), Nr, 20)
    for tr in range(T):
        for tc in range(T):
            rowbase, col, mask = b.v(), b.v(2), b.s(2)
            sb = b.s()
            b.emit("s_add_u32", sb, m0, TILE * tr)
            b.emit("v_add_u32_e32", rowbase, sb, g4)
            b.emit("s_add_u32", sb, n0, TILE * tc)
            b.emit("v_add_u32_e32", b.part(col, 0), sb, r)
            b.emit("v_mov_b32_e32", b.part(col, 1), 0)
            b.emit("v_cmp_gt_u32_e64", mask, Nr, b.part(col, 0))          # the column exists
            off, addr = b.v(2), b.v(2)
            b.emit("v_mad_u64_u32", off, carry, rowbase, Nr, col)         # row * N + column
            b.emit("v_lshl_add_u64", addr, off, 2, A[cn])
            for q in range(16):
                rowq = b.v()
                b.emit("v_add_u32_e32", rowq, 8 * (q // 4) + q % 4, rowbase)
                b.emit("v_cmp_gt_u32_e32", "vcc", Mr, rowq)                # the row exists
                b.emit("s_and_b64", "exec", mask, "vcc")
                b.emit("global_store_dword", addr, b.part(acc[tr][tc], q), "off")
                b.emit("s_mov_b64", "exec", -1)
                if q < 15:
                    b.emit("v_lshl_add_u64", addr, addr, 0, step5 if q % 4 == 3 else step1)
    b.emit("s_endpgm")
    k = b.finish(bd.args, workgroup_id="xy")
    span = TILE * T
    return Compiled(abi.make_module([k]),
                    {"grid": [f"cdiv({m.param(cn).shape[1]}, {span})", f"cdiv({m.param(cn).shape[0]}, {span})"],
                     "block": [LANES], "lds": 0}, "gemm_mfma", {"tiles": T, "unroll": U})
