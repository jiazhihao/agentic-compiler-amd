"""The MFMA GEMM template: `C[M, N] = A[M, K] @ B[N, K]^T`, f32 result; inputs bf16, or OCP FP8 (`e4m3`,
`e5m2`: the same schedule with 8-byte units, `dwordx2` loads and the `fp8` / `bf8` MFMA). The text below
describes bf16.

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

TILE, KSTEP, LANES = 32, 16, 64


class Format:
    """An input element type: its 32x32x16 MFMA, and how a lane's 8 elements (one unit) are loaded and kept."""

    def __init__(self, mfma: str, element_bytes: int, wide: bool = False, mods: dict | None = None):
        self.mfma, self.eb = mfma, element_bytes
        self.wide, self.mods = wide, mods or {}                 # wide: the 32x32x64 MFMA, 32 bytes per lane
        self.es = element_bytes.bit_length() - 1                # log2 of the element size
        self.ub = 8 * element_bytes                             # a unit: the 8 elements of one lane
        self.sh = self.ub.bit_length() - 1
        self.regs = self.ub // 4
        self.load = f"global_load_dwordx{self.regs}"
        self.lds_load = "global_load_lds_dwordx4" if self.regs == 4 else None
        self.dsr, self.dsw = f"ds_read_b{8 * self.ub}", f"ds_write_b{8 * self.ub}"


FORMATS = {"bf16": Format("v_mfma_f32_32x32x16_bf16", 2), "e4m3": Format("v_mfma_f32_32x32x16_fp8_fp8", 1),
           "e5m2": Format("v_mfma_f32_32x32x16_bf8_bf8", 1)}
# gfx950's FP8 MFMA with K = 64: the same products in half the passes; `cbsz` / `blgp` 1 select E5M2
WIDE = {"e4m3": Format("v_mfma_f32_32x32x64_f8f6f4", 1, True), "e5m2": Format("v_mfma_f32_32x32x64_f8f6f4", 1, True, {"cbsz": 1, "blgp": 1})}
F = FORMATS["bf16"]                                             # the format of the kernel being generated
SPEC = "mk,nk->mn"


def matches(p: Program) -> bool:
    return len(p.body) == 1 and p.body[0].einsum == SPEC and len(p.outputs) == 1 and p.outputs[0].name == p.body[0].name


def generate(m: Manifest, p: Program, tiles: int = 2, unroll: int = 1, share: int = 0, ahead: int = 1, wide: int = 0) -> Compiled:
    T, U = tiles, unroll
    if not matches(p):
        raise GenError(f'not a GEMM program (one statement `C = einsum "{SPEC}"(A, B)`)')
    if T not in (1, 2, 4) or U not in (1, 2) or share not in (0, 1, 2, 3):
        raise GenError("tiles must be 1, 2 or 4, unroll 1 or 2, share 0 to 3")
    if ahead not in (1, 2, 3) or (ahead != 1 and share != 2):
        raise GenError("ahead is 1, 2 or 3 macro steps of loads in flight, and only share=2 has it")
    if share >= 2 and T == 1:
        raise GenError("share=2 and 3 (both operands through LDS) need tiles of 2 or 4")
    bd = bind(m, p)
    an, bn = (v.name for v in p.body[0].expr)
    cn = bd.outputs[p.outputs[0].name]
    global F
    kind = str(m.param(an).dtype)
    if kind not in FORMATS or str(m.param(bn).dtype) != kind or str(m.param(cn).dtype) != "f32":
        raise GenError(f"the MFMA GEMM template takes two inputs of one of {sorted(FORMATS)} and an f32 output")
    F = FORMATS[kind]
    if wide:
        if kind not in WIDE or share != 2:
            raise GenError("wide=1 (the 32x32x64 FP8 MFMA) is for FP8 inputs with share=2")
        F = WIDE[kind]
    if share == 3 and F.lds_load is None:
        raise GenError("share=3 (loads straight into LDS) needs 16-byte units: bf16 only")
    msym, ksym = p.param(an).shape
    nsym = p.param(bn).shape[0]
    kexpr = m.param(an).shape[1]
    import ast
    from ..manifest import eval_expr
    names = {n.id for n in ast.walk(ast.parse(str(kexpr), mode="eval")) if isinstance(n, ast.Name)}
    if names & set(m.dynamic):
        raise GenError(f"K must be fixed: its expression {kexpr!r} depends on the dynamic symbol(s) {sorted(names & set(m.dynamic))}")
    for shapes in (m.shapes, m.timing_symbols()):
        if eval_expr(kexpr, shapes) % (64 if wide else KSTEP):
            raise GenError(f"K must be a multiple of {64 if wide else KSTEP} (it is {kexpr} = {eval_expr(kexpr, shapes)})")
    b = Builder(m.entry)
    A = load_args(b, bd, [an, bn, cn, bd.size_param(msym), bd.size_param(nsym), bd.size_param(ksym)])
    Mr, Nr, Kr = A[bd.size_param(msym)], A[bd.size_param(nsym)], A[bd.size_param(ksym)]
    shift = (TILE * T).bit_length() - 1
    n0, m0 = b.s(), b.s()
    lane = "v0"
    if share:
        # four waves per workgroup: wave 2 i + j computes the (i, j) quarter of a 2 span x 2 span block
        wave, lane = b.v(), b.v()
        wv, wi, wj = b.s(), b.s(), b.s()
        b.emit("v_lshrrev_b32_e32", wave, 6, "v0")
        b.emit("v_and_b32_e32", lane, LANES - 1, "v0")
        b.emit("v_readfirstlane_b32", wv, wave)
        b.emit("s_lshr_b32", wi, wv, 1)
        b.emit("s_and_b32", wj, wv, 1)
        tmp = b.s()
        b.emit("s_lshl_b32", n0, "s2", shift + 1)
        b.emit("s_lshl_b32", tmp, wj, shift)
        b.emit("s_add_u32", n0, n0, tmp)
        b.emit("s_lshl_b32", m0, "s3", shift + 1)
        b.emit("s_lshl_b32", tmp, wi, shift)
        b.emit("s_add_u32", m0, m0, tmp)
    else:
        b.emit("s_lshl_b32", n0, "s2", shift)                 # first column and row of this wave's tiles
        b.emit("s_lshl_b32", m0, "s3", shift)
    last_m, last_n = b.s(), b.s()
    b.emit("s_sub_u32", last_m, Mr, 1)
    b.emit("s_sub_u32", last_n, Nr, 1)
    r, g8 = b.v(), b.v(2)
    b.emit("v_and_b32_e32", r, TILE - 1, lane)                # lane % 32: the row (A) / column (B, C) in a tile
    b.emit("v_lshrrev_b32_e32", b.part(g8, 0), 5, lane)       # lane // 32
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
        b.emit("v_lshl_add_u64", addr, off, F.es, ptr)       # * the element size + the pointer
        return addr
    if not share:
        addr_a = [operand_address(A[an], m0, t, last_m, Kr) for t in range(T)]
        addr_b = [operand_address(A[bn], n0, t, last_n, Kr) for t in range(T)]
    acc = [[b.a(16) for _ in range(T)] for _ in range(T)]
    zero = b.v()
    b.emit("v_mov_b32_e32", zero, 0)
    for row in acc:
        for a16 in row:
            for i in range(16):
                b.emit("v_accvgpr_write_b32", b.part(a16, i), zero)

    lds = 0
    if share >= 2:
        lds = _panel_loop(b, T, 16 // U, A[an], A[bn], m0, n0, last_m, last_n, Kr, wv, wi, wj, lane, acc, direct=share == 3, ahead=ahead)
    elif share:
        lds = _shared_loop(b, T, A[an], A[bn], m0, n0, last_m, last_n, Kr, wi, wj, lane, operand_address, acc)
    else:
        def body(u_count: int):
            ops_a = [[b.v(F.regs) for _ in range(T)] for _ in range(u_count)]
            ops_b = [[b.v(F.regs) for _ in range(T)] for _ in range(u_count)]
            for u in range(u_count):
                off = {"offset": F.eb * KSTEP * u} if u else {}
                for t in range(T):
                    b.emit(F.load, ops_a[u][t], addr_a[t], "off", **off)
                    b.emit(F.load, ops_b[u][t], addr_b[t], "off", **off)
            for u in range(u_count):
                for tr in range(T):
                    for tc in range(T):
                        b.emit(F.mfma, acc[tr][tc], ops_a[u][tr], ops_b[u][tc], acc[tr][tc])
            for adr in addr_a + addr_b:
                b.emit("v_lshl_add_u64", adr, adr, 0, F.eb * KSTEP * u_count)

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
    k = b.finish(bd.args, workgroup_id="xy", lds_bytes=lds)
    span = TILE * T * (2 if share else 1)
    return Compiled(abi.make_module([k]),
                    {"grid": [f"cdiv({m.param(cn).shape[1]}, {span})", f"cdiv({m.param(cn).shape[0]}, {span})"],
                     "block": [LANES * (4 if share else 1)], "lds": 0}, "gemm_mfma", {"tiles": T, "unroll": U, "share": share, "ahead": ahead, "wide": wide})


def _shared_loop(b: Builder, T: int, a_ptr, b_ptr, m0, n0, last_m, last_n, Kr, wi, wj, lane, operand_address, acc) -> int:
    """The K loop of the LDS-shared variant; returns the LDS bytes per workgroup.

    The four waves of a workgroup need two halves of the A panel (rows) and two halves of the B panel (columns);
    wave (i, j) needs A half i and B half j. Each half is loaded from memory by exactly one wave: A half i by
    wave (i, i), B half j by wave (1 - j, j). A wave keeps the half it loaded in registers, writes it to LDS,
    and after the barrier reads the half it did not load from there. So a workgroup loads each operand element
    once (the plain template loads it twice) and the other copy travels through LDS.

    One barrier per K step. Two LDS buffers alternate by step, so a wave may write the next step while another
    still reads the current one; the loads of the next step are in flight during this step's MFMAs."""
    step_bytes = F.ub * LANES                                   # one operand tile: 64 lanes x one unit
    half = T * step_bytes                                       # one half panel of one step
    buf = 4 * half                                              # A0, A1, B0, B1
    diag = b.s()
    b.emit("s_xor_b32", diag, wi, wj)                           # 0: this wave loads its A half; 1: its B half
    own_ptr, own_origin, own_last, own_slot, other_slot, tmp = b.s(2), b.s(), b.s(), b.s(), b.s(), b.s()
    b.emit("s_add_u32", tmp, wj, 2)
    b.emit("s_cmp_eq_u32", diag, 0)
    b.emit("s_cselect_b64", own_ptr, a_ptr, b_ptr)
    b.emit("s_cselect_b32", own_origin, m0, n0)
    b.emit("s_cselect_b32", own_last, last_m, last_n)
    b.emit("s_cselect_b32", own_slot, wi, tmp)
    b.emit("s_cselect_b32", other_slot, tmp, wi)
    addr = [operand_address(own_ptr, own_origin, t, own_last, Kr) for t in range(T)]
    lw, lr, l16 = b.v(), b.v(), b.v()
    so = b.s()
    b.emit("v_lshlrev_b32_e32", l16, F.sh, lane)
    b.emit("s_mul_i32", so, own_slot, half)
    b.emit("v_add_u32_e32", lw, so, l16)
    b.emit("s_mul_i32", so, other_slot, half)
    b.emit("v_add_u32_e32", lr, so, l16)
    sets = [[b.v(F.regs) for _ in range(T)] for _ in range(2)]
    other = [b.v(F.regs) for _ in range(T)]
    cnt = b.s()
    done = b.new_label()
    b.emit("s_lshr_b32", cnt, Kr, 4)                            # K / 16 steps
    for t in range(T):
        b.emit(F.load, sets[0][t], addr[t], "off")
    second = b.new_label()
    b.emit("s_cmp_eq_u32", diag, 0)
    b.emit("s_cbranch_scc0", second)
    def work(h: int, loads_a: bool):
        """After the writes of buffer h: the barrier, the other half from LDS, the MFMAs of this step."""
        cur = sets[h]
        b.emit("s_barrier")
        for t in range(T):
            b.emit(F.dsr, other[t], lr, offset=h * buf + t * step_bytes)
        for tr in range(T):
            for tc in range(T):
                b.emit(F.mfma, acc[tr][tc], (cur if loads_a else other)[tr], (other if loads_a else cur)[tc], acc[tr][tc])

    for loads_a in (True, False):
        if not loads_a:
            b.label(second)
        last = [b.new_label(), b.new_label()]
        loop = b.label(align="5, , 4")
        for h in (0, 1):
            for t in range(T):
                b.emit(F.dsw, lw, sets[h][t], offset=h * buf + t * step_bytes)
            b.emit("s_sub_u32", cnt, cnt, 1)
            b.emit("s_cmp_eq_u32", cnt, 0)
            b.emit("s_cbranch_scc1", last[h])                   # the last step: nothing more to load
            for t in range(T):
                b.emit("v_lshl_add_u64", addr[t], addr[t], 0, F.eb * KSTEP)
                b.emit(F.load, sets[1 - h][t], addr[t], "off")
            work(h, loads_a)
        b.emit("s_branch", loop)
        for h in (0, 1):
            b.label(last[h])
            work(h, loads_a)
            b.emit("s_branch", done)
    b.label(done)
    return 2 * buf


def _panel_loop(b: Builder, T: int, R: int, a_ptr, b_ptr, m0, n0, last_m, last_n, Kr, wv, wi, wj, lane, acc, direct: bool = False, ahead: int = 1) -> int:
    """The K loop with both operands through LDS; returns the LDS bytes per workgroup.

    Measured on the half-shared variant: the loads from memory are the bound (about 130 of 187 us at 4096^3), a
    load that touches fewer cache lines is faster, and LDS reads of the same volume cost about 5 %. So here no
    wave keeps what it loaded: wave w loads half w of the panels (A rows 0, A rows 1, B columns 0, B columns 1)
    in the pattern memory likes, `R` rows per load with 1024 / R contiguous bytes of each row, writes it to LDS
    unit by unit (16 bytes: 8 elements of one row), and every wave reads its two halves from LDS in MFMA layout.
    One macro step is 32 / R K-steps; its loads are issued a whole macro step ahead of its MFMAs; one barrier per
    macro step; two LDS buffers alternate."""
    # A load is always 16 bytes per lane (measured on FP8: the loads from memory cost per instruction, not per
    # byte): one piece of a row. A K-step of a row is 2 pieces in bf16 (one per lane group of the MFMA) and
    # 1 piece in FP8 (both lane groups).
    ppk = 4 if F.wide else F.ub // 8                            # pieces per K-step of a row (the wide MFMA's K-step is 64)
    P = LANES // R                                              # pieces of a row per macro step
    G = P // ppk                                                # K-steps per macro step
    rows = T * TILE                                             # rows of a half panel
    Q = rows // R                                               # loads per macro step
    half = T * G * 32 * ppk * 16                                   # LDS holds a half in MFMA layout: tile, K-step, lane
    buf = 4 * half
    per_tile = TILE // R                                        # loads per operand tile
    # ---- the loader's side: wave w loads half w
    is_b = b.s()
    own_ptr, own_origin, own_last, tmp = b.s(2), b.s(), b.s(), b.s()
    b.emit("s_lshr_b32", is_b, wv, 1)
    b.emit("s_cmp_eq_u32", is_b, 0)
    b.emit("s_cselect_b64", own_ptr, a_ptr, b_ptr)
    b.emit("s_cselect_b32", own_last, last_m, last_n)
    # the first row of half w: A half i starts at this workgroup's row i * rows, B half j at its column j * rows
    wg_m, wg_n, hsel = b.s(), b.s(), b.s()
    b.emit("s_lshl_b32", tmp, wi, rows.bit_length() - 1)
    b.emit("s_sub_u32", wg_m, m0, tmp)                          # m0, n0 are this wave's quarter: back to the workgroup's origin
    b.emit("s_lshl_b32", tmp, wj, rows.bit_length() - 1)
    b.emit("s_sub_u32", wg_n, n0, tmp)
    b.emit("s_and_b32", hsel, wv, 1)
    b.emit("s_lshl_b32", hsel, hsel, rows.bit_length() - 1)
    b.emit("s_cmp_eq_u32", is_b, 0)
    b.emit("s_cselect_b32", own_origin, wg_m, wg_n)
    b.emit("s_add_u32", own_origin, own_origin, hsel)
    lr_, lu = b.v(), b.v()                                      # lane % R: the row of a load; lane // R: its unit
    b.emit("v_and_b32_e32", lr_, R - 1, lane)
    b.emit("v_lshrrev_b32_e32", lu, R.bit_length() - 1, lane)
    u16 = b.v()
    b.emit("v_lshlrev_b32_e32", u16, 4, lu)                     # the unit's byte offset in the macro step
    carry = b.s(2)
    rowbytes = b.s()
    if F.es:
        b.emit("s_lshl_b32", rowbytes, Kr, F.es)
    else:
        b.emit("s_mov_b32", rowbytes, Kr)
    rowbase = []
    for q in range(Q):
        idx, off, base = b.v(), b.v(2), b.v(2)
        sb = b.s()
        b.emit("s_add_u32", sb, own_origin, q * R)
        b.emit("v_add_u32_e32", idx, sb, lr_)
        b.emit("v_min_u32_e32", idx, own_last, idx)
        b.emit("v_mad_u64_u32", off, carry, idx, rowbytes, 0)
        b.emit("v_lshl_add_u64", base, off, 0, own_ptr)
        rowbase.append(base)
    kbase, kmax = b.s(), b.s()
    b.emit("s_mov_b32", kbase, 0)
    b.emit("s_sub_u32", kmax, rowbytes, 16)                     # the last unit of a row: lanes past the end reread it
    ko = b.v(2)
    b.emit("v_mov_b32_e32", b.part(ko, 1), 0)
    wbase = [b.v(), b.v()]                                      # LDS address of this lane's unit of load 0, per buffer
    so = b.s()
    b.emit("s_mul_i32", so, wv, half)
    # piece j of row r goes to slot 32 j + r (16 bytes each): in bf16 that is where the readers' lane
    # r + 32 (j % 2) of K-step j // 2 looks, in FP8 the two halves of the slot are lanes r and r + 32 of K-step j.
    # Either way a read covers 64 consecutive units, which spreads it over all LDS banks (a row-major layout put
    # the 64 lanes of a read on 2 to 4 banks: 120 us of LDS reads at 4096^3)
    b.emit("v_lshlrev_b32_e32", wbase[0], 5, lu)
    b.emit("v_add_u32_e32", wbase[0], wbase[0], lr_)
    b.emit("v_lshlrev_b32_e32", wbase[0], 4, wbase[0])
    b.emit("v_add_u32_e32", wbase[0], so, wbase[0])
    b.emit("v_add_u32_e32", wbase[1], buf, wbase[0])
    # ---- the reader's side: A half wi and B half 2 + wj, in MFMA layout
    rd = b.v()
    if ppk == 2:
        b.emit("v_lshlrev_b32_e32", rd, 4, lane)                # bf16: lane l reads slot l
    elif ppk == 4:                                              # wide FP8: slots 64 (l // 32) + l % 32 and 32 further
        half_ = b.v()
        b.emit("v_and_b32_e32", rd, TILE - 1, lane)
        b.emit("v_lshlrev_b32_e32", rd, 4, rd)
        b.emit("v_lshrrev_b32_e32", half_, 5, lane)
        b.emit("v_lshlrev_b32_e32", half_, 10, half_)
        b.emit("v_add_u32_e32", rd, rd, half_)
    else:                                                       # FP8: lane l reads half l // 32 of slot l % 32
        half_ = b.v()
        b.emit("v_and_b32_e32", rd, TILE - 1, lane)
        b.emit("v_lshlrev_b32_e32", rd, 4, rd)
        b.emit("v_lshrrev_b32_e32", half_, 5, lane)
        b.emit("v_lshlrev_b32_e32", half_, 3, half_)
        b.emit("v_add_u32_e32", rd, rd, half_)
    ra, rb = [b.v(), b.v()], [b.v(), b.v()]
    b.emit("s_mul_i32", so, wi, half)
    b.emit("v_add_u32_e32", ra[0], so, rd)
    b.emit("v_add_u32_e32", ra[1], buf, ra[0])
    b.emit("s_add_u32", so, wj, 2)
    b.emit("s_mul_i32", so, so, half)
    b.emit("v_add_u32_e32", rb[0], so, rd)
    b.emit("v_add_u32_e32", rb[1], buf, rb[0])
    rem = b.s()
    done = b.new_label()
    b.emit("s_lshr_b32", rem, Kr, 6 if F.wide else 4)           # K-steps left
    if direct:
        _direct_loop(b, T, R, G, Q, half, buf, wv, wi, wj, lane, acc, rem, done, kbase, kmax, u16, ko, rowbase)
        b.label(done)
        return 2 * buf
    NB = ahead + 1                                              # register sets: the loads run `ahead` macro steps ahead
    sets = [[b.v(4) for _ in range(Q)] for _ in range(NB)]
    nreg = 8 if F.wide else F.regs
    ops_a, ops_b = [b.v(nreg) for _ in range(T)], [b.v(nreg) for _ in range(T)]

    def issue(dst):
        """The loads of the next macro step not yet issued. Past the end of K every lane rereads the row's last
        unit, so the lookahead needs no condition."""
        b.emit("v_add_u32_e32", b.part(ko, 0), kbase, u16)
        b.emit("v_min_u32_e32", b.part(ko, 0), kmax, b.part(ko, 0))
        for q in range(Q):
            adr = b.v(2)
            b.emit("v_lshl_add_u64", adr, ko, 0, rowbase[q])
            b.emit("global_load_dwordx4", dst[q], adr, "off")
        b.emit("s_add_u32", kbase, kbase, 16 * P)

    def kstep(h: int, g: int):
        for t in range(T):
            off = (t * G + g) * 32 * ppk * 16
            if F.wide:                                          # a lane's 32 bytes are two slots 32 apart
                for part in (0, 1):
                    o = off + 512 * part
                    b.emit("ds_read_b128", b.part(ops_a[t], 4 * part, 4), ra[h], **({"offset": o} if o else {}))
                    b.emit("ds_read_b128", b.part(ops_b[t], 4 * part, 4), rb[h], **({"offset": o} if o else {}))
            else:
                b.emit(F.dsr, ops_a[t], ra[h], **({"offset": off} if off else {}))
                b.emit(F.dsr, ops_b[t], rb[h], **({"offset": off} if off else {}))
        for tr in range(T):
            for tc in range(T):
                b.emit(F.mfma, acc[tr][tc], ops_a[tr], ops_b[tc], acc[tr][tc], **F.mods)

    for d in range(ahead):
        issue(sets[d])
    period = NB if NB % 2 == 0 else 2 * NB                      # sets rotate by NB, LDS buffers by 2
    last = [b.new_label() for _ in range(period)]
    loop = b.label(align="5, , 4")
    for i in range(period):
        h = i % 2
        for q in range(Q):
            off = ((q // per_tile) * G * 32 * ppk + R * (q % per_tile)) * 16
            b.emit("ds_write_b128", wbase[h], sets[i % NB][q], **({"offset": off} if off else {}))
        issue(sets[(i + ahead) % NB])                           # into the set written to LDS one macro step ago
        b.emit("s_cmp_le_u32", rem, G)
        b.emit("s_cbranch_scc1", last[i])                       # the last macro step
        b.emit("s_barrier")
        for g in range(G):
            kstep(h, g)
        b.emit("s_sub_u32", rem, rem, G)
    b.emit("s_branch", loop)
    for i in range(period):
        b.label(last[i])
        b.emit("s_barrier")
        for g in range(G):
            kstep(i % 2, g)
            if g < G - 1:
                b.emit("s_sub_u32", rem, rem, 1)
                b.emit("s_cmp_eq_u32", rem, 0)
                b.emit("s_cbranch_scc1", done)
        b.emit("s_branch", done)
    b.label(done)
    return 2 * buf


def _const(b: Builder, value: int):
    """A VGPR holding a small constant (`v_mul_lo_u32` takes no literal)."""
    r = b.v()
    b.emit("v_mov_b32_e32", r, value)
    return r


def _direct_loop(b: Builder, T, R, G, Q, half, buf, wv, wi, wj, lane, acc, rem, done, kbase, kmax, u16, ko, rowbase) -> None:
    """The macro-step loop with loads straight into LDS (`global_load_lds_dwordx4`): the data never passes through
    the loading wave's registers, so it arrives while that wave runs MFMAs (with loads into registers the MFMA
    time added to the load time instead of hiding behind it).

    A direct load puts lane l's 16 bytes at M0 + 16 l: the LDS holds each load as it was loaded (row l % R of
    the load, unit l // R), and the readers address it per lane. Any permutation of 64 slots of 16 bytes still
    spreads a read evenly over the LDS banks. All operands of a macro step are read into registers before the
    next macro step's loads are issued (the checker lets no LDS read overlap a load into LDS), then the MFMAs
    run with those loads in flight."""
    chunk = LANES * F.ub                                          # one load in LDS
    own = [b.s(), b.s()]                                        # LDS base of this wave's half, per buffer
    b.emit("s_mul_i32", own[0], wv, half)
    b.emit("s_add_u32", own[1], own[0], buf)
    # reader lane l (row p = l % 32 of a tile, lane group l // 32) finds its unit of K-step g of tile t at
    # chunk (32 / R) t + p // R, slot p % R + R (2 g + l // 32)
    p, grp, rd = b.v(), b.v(), b.v()
    b.emit("v_and_b32_e32", p, TILE - 1, lane)
    b.emit("v_lshrrev_b32_e32", grp, 5, lane)
    b.emit("v_and_b32_e32", rd, R - 1, p)                       # p % R
    b.emit("v_lshlrev_b32_e32", grp, R.bit_length() - 1, grp)   # R (l // 32)
    b.emit("v_add_u32_e32", rd, rd, grp)
    b.emit("v_lshlrev_b32_e32", rd, F.sh, rd)
    b.emit("v_lshrrev_b32_e32", p, R.bit_length() - 1, p)       # p // R: the chunk within the tile
    b.emit("v_lshlrev_b32_e32", p, chunk.bit_length() - 1, p)
    b.emit("v_add_u32_e32", rd, rd, p)
    ra, rb = [b.v(), b.v()], [b.v(), b.v()]
    so = b.s()
    b.emit("s_mul_i32", so, wi, half)
    b.emit("v_add_u32_e32", ra[0], so, rd)
    b.emit("v_add_u32_e32", ra[1], buf, ra[0])
    b.emit("s_add_u32", so, wj, 2)
    b.emit("s_mul_i32", so, so, half)
    b.emit("v_add_u32_e32", rb[0], so, rd)
    b.emit("v_add_u32_e32", rb[1], buf, rb[0])
    ops_a = [[b.v(F.regs) for _ in range(T)] for _ in range(G)]
    ops_b = [[b.v(F.regs) for _ in range(T)] for _ in range(G)]

    def issue(h: int):
        b.emit("v_add_u32_e32", b.part(ko, 0), kbase, u16)
        b.emit("v_min_u32_e32", b.part(ko, 0), kmax, b.part(ko, 0))
        for q in range(Q):
            adr = b.v(2)
            b.emit("v_lshl_add_u64", adr, ko, 0, rowbase[q])
            if q:
                b.emit("s_add_u32", "m0", own[h], q * chunk)
            else:
                b.emit("s_mov_b32", "m0", own[h])
            b.emit(F.lds_load, adr, "off")
        b.emit("s_add_u32", kbase, kbase, F.ub * 2 * G)

    def reads(h: int):
        for g in range(G):
            for t in range(T):
                off = (TILE // R) * t * chunk + 2 * R * g * F.ub
                b.emit(F.dsr, ops_a[g][t], ra[h], **({"offset": off} if off else {}))
                b.emit(F.dsr, ops_b[g][t], rb[h], **({"offset": off} if off else {}))

    def mfmas(g: int):
        for tr in range(T):
            for tc in range(T):
                b.emit(F.mfma, acc[tr][tc], ops_a[g][tr], ops_b[g][tc], acc[tr][tc])

    issue(0)
    last = [b.new_label(), b.new_label()]
    loop = b.label(align="5, , 4")
    for h in (0, 1):
        b.emit("s_barrier")                                     # every wave's loads of this macro step are in LDS
        reads(h)
        b.emit("s_cmp_le_u32", rem, G)
        b.emit("s_cbranch_scc1", last[h])                       # the last macro step: nothing more to load
        issue(1 - h)
        for g in range(G):
            mfmas(g)
        b.emit("s_sub_u32", rem, rem, G)
    b.emit("s_branch", loop)
    for h in (0, 1):
        b.label(last[h])
        for g in range(G):
            mfmas(g)
            if g < G - 1:
                b.emit("s_sub_u32", rem, rem, 1)
                b.emit("s_cmp_eq_u32", rem, 0)
                b.emit("s_cbranch_scc1", done)
        b.emit("s_branch", done)
