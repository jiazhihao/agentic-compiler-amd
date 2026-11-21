"""The MFMA attention template: `out[q] = softmax_k(scale * Q[q] . K[k]) V[k]` for one head, f32.

    tair attention(Q: f32[NQ, 64], K: f32[NK, 64], V: f32[NK, 64], scale: f32) -> (out: f32[NQ, 64], lse: f32[NQ]) {
      S = einsum "qd,kd->qk"(Q, K)
      m = reduce max(S * scale)
      P = exp(S * scale - m)
      s = reduce sum(P)
      W = P / s
      out = einsum "qk,kd->qd"(W, V)
      lse = m + log(s)            # optional
    }

The schedule is the one an agent session found on `fa_attention` (2.09x over amdclang, issue #36),
made general over the row width D (a multiple of 64) and the sizes:

- One wave computes 16 queries against 16 keys per tile with `v_mfma_f32_16x16x4_f32`, so K and V are
  read once per 16 queries. Scores: A = K, B = Q (premultiplied by scale * log2 e); the result
  register r of lane l is the score of query `l % 16` and key `4 (l // 16) + r`. Value update:
  A = the exponentiated scores in place, B = V with the row width across the lanes: lane l holds
  columns `4 (l % 16) + c` (c = 0..3) of each 64-column block as one `dwordx4`, and the result
  register r of lane l is `out[4 (l // 16) + r][4 (l % 16) + c]`.
- Operand loads go straight into the operand layout: lane l reads `K[key][16 (l // 16) + 4 x + r]`
  as one `dwordx4` per x, so one load covers 16 rows of 16 contiguous bytes per lane group and a row
  is read contiguously across the four lane groups.
- Online softmax with a lazily updated reference: the weights are `2^(score - ref)`; the reference
  moves (and the running sum and the accumulators are rescaled) only when a score exceeds it by more
  than 2^64, which the first tile always does. The exact per-query maximum is only needed on that
  slow path, where it crosses lane groups through `ds_bpermute_b32`.
- With `waves` > 1 the waves of a workgroup take the key tiles in turn and merge their references,
  sums and accumulators once at the end through LDS.

Keys beyond NK get the score -inf (weight 0) and load a clamped row; queries beyond NQ load a clamped
row and are masked at the stores.
"""
from __future__ import annotations

from ..manifest import Manifest, eval_expr
from ..mir import abi
from ..tair.ir import Call, Program, Var
from ..tair.text import print_expr
from .binding import Compiled, bind, load_args
from .builder import Builder, GenError

MFMA = "v_mfma_f32_16x16x4_f32"
TILE, LANES = 16, 64
NEG_INF, LOG2E, LN2, THRESHOLD = 0xFF800000, 0x3FB8AA3B, 0x3F317218, 0x42800000      # f32 bits; 64.0


def _shape(p: Program) -> dict | None:
    """The roles of the program's values when it is the attention pattern, else None."""
    b = p.body
    if len(b) not in (6, 7) or b[0].einsum is None or b[5].einsum is None:
        return None

    def canon(spec: str) -> str:
        names: dict[str, str] = {}
        return "".join(c if not c.isalpha() else names.setdefault(c, "abcdefgh"[len(names)]) for c in spec)
    if canon(b[0].einsum) != "ab,cb->ac" or canon(b[5].einsum) != "ab,bc->ac":
        return None
    q, k = (v.name for v in b[0].expr)
    w, v = (x.name for x in b[5].expr)
    S, m, P, s, W = (b[i].name for i in range(5))
    scale = None
    e = b[1].expr
    if b[1].reduce != "max":
        return None
    if isinstance(e, Call) and e.fn == "mul":
        names = [a.name for a in e.args if isinstance(a, Var)]
        if len(names) != 2 or S not in names:
            return None
        scale = next(n for n in names if n != S)
        if p.param(scale) is None or p.param(scale).shape is not None:
            return None
    elif not (isinstance(e, Var) and e.name == S):
        return None
    score = print_expr(e)
    ok = (b[2].reduce is None and print_expr(b[2].expr) in (f"exp({score} - {m})", f"exp(({score}) - {m})")
          and b[3].reduce == "sum" and print_expr(b[3].expr) == P
          and b[4].reduce is None and print_expr(b[4].expr) == f"{P} / {s}" and w == W)
    if not ok:
        return None
    lse = None
    if len(b) == 7:
        if b[6].reduce is not None or print_expr(b[6].expr) != f"{m} + log({s})":
            return None
        lse = b[6].name
    outs = [o.name for o in p.outputs]
    if outs != ([b[5].name] + ([lse] if lse else [])):
        return None
    return {"Q": q, "K": k, "V": v, "scale": scale, "out": b[5].name, "lse": lse}


def matches(p: Program) -> bool:
    return _shape(p) is not None


def generate(m: Manifest, p: Program, waves: int = 1, ahead: int = 1) -> Compiled:
    r = _shape(p)
    if r is None:
        raise GenError("not an attention program (see the template's documentation for the pattern)")
    W = waves
    if W not in (1, 2, 4, 8):
        raise GenError("waves must be 1, 2, 4 or 8")
    bd = bind(m, p)
    qn, kn, vn = r["Q"], r["K"], r["V"]
    on = bd.outputs[r["out"]]
    ln = bd.outputs[r["lse"]] if r["lse"] else None
    for n in (qn, kn, vn, on) + ((ln,) if ln else ()):
        if str(m.param(n).dtype) != "f32":
            raise GenError("the attention template takes f32 tensors")
    nq_sym, d_sym = p.param(qn).shape
    nk_sym = p.param(kn).shape[0]
    dexpr = m.param(qn).shape[1]
    try:
        D = int(dexpr) if isinstance(dexpr, int) or str(dexpr).isdigit() else None
    except ValueError:
        D = None
    if D is None or D % 64 or not 64 <= D <= 128:
        raise GenError(f"the row width must be a fixed 64 or 128 (it is {dexpr!r})")
    for t in (kn, vn, on):
        if eval_expr(m.param(t).shape[1], m.shapes) != D:
            raise GenError(f"{t}: the row width must be {D} like {qn}'s")
    n64 = D // 64
    col = lambda c: 256 * (c // 4) + 4 * (c % 4)       # byte offset of output chunk c in the lane's part of a row
    XS, CH = 4 * n64, 4 * n64                 # dwordx4 loads per operand row; 16-column chunks of the output
    xoff = [16 * (x % 4) + 256 * (x // 4) for x in range(XS)]

    b = Builder(m.entry)
    names = [qn, kn, vn, on] + ([ln] if ln else []) + [bd.size_param(nq_sym), bd.size_param(nk_sym)] + ([r["scale"]] if r["scale"] else [])
    A = load_args(b, bd, names)
    NQ, NK = A[bd.size_param(nq_sym)], A[bd.size_param(nk_sym)]
    lane = "v0"                                # the workitem id: lane + 64 * wave
    c16, g, wave = b.v(), b.v(), b.v()
    if W > 1:
        b.emit("v_lshrrev_b32_e32", wave, 6, lane)
        ln_ = b.v()
        b.emit("v_and_b32_e32", ln_, LANES - 1, lane)
        lane = ln_
    b.emit("v_and_b32_e32", c16, TILE - 1, lane)                      # lane % 16
    b.emit("v_lshrrev_b32_e32", g, 4, lane)                           # lane // 16
    g64, c4 = b.v(2), b.v(2)                                          # byte offsets inside a row, as 64-bit addends
    b.emit("v_lshlrev_b32_e32", b.part(g64, 0), 6, g)
    b.emit("v_mov_b32_e32", b.part(g64, 1), 0)
    b.emit("v_lshlrev_b32_e32", b.part(c4, 0), 4, c16)             # the lane's 4 columns of a 64-column block: 4 (lane % 16) ..
    b.emit("v_mov_b32_e32", b.part(c4, 1), 0)
    g4r = [b.v() for _ in range(4)]                                   # 4 (lane // 16) + r
    for i in range(4):
        b.emit("v_lshlrev_b32_e32", g4r[i], 2, g)
        if i:
            b.emit("v_add_u32_e32", g4r[i], i, g4r[i])
    idx16, idx32 = b.v(), b.v()                                       # ds_bpermute indices: the lane 16 / 32 further (mod 64)
    b.emit("v_xor_b32_e32", idx16, 16, lane)
    b.emit("v_lshlrev_b32_e32", idx16, 2, idx16)
    b.emit("v_xor_b32_e32", idx32, 32, lane)
    b.emit("v_lshlrev_b32_e32", idx32, 2, idx32)
    idxq = [b.v() for _ in range(4)]                                  # the lane (in the first group) of query 4 (lane // 16) + r
    for i in range(4):
        b.emit("v_lshlrev_b32_e32", idxq[i], 2, g4r[i])
    rb, q0, lastq, lastk = b.s(), b.s(), b.s(), b.s()
    b.emit("s_mov_b32", rb, 4 * D)
    b.emit("s_lshl_b32", q0, "s2", 4)                                 # the workgroup's first query
    b.emit("s_sub_u32", lastq, NQ, 1)
    b.emit("s_sub_u32", lastk, NK, 1)
    carry = b.s(2)

    def row_address(ptr, index, addend):
        off, addr = b.v(2), b.v(2)
        b.emit("v_mad_u64_u32", off, carry, index, rb, addend)        # row * 4 D + the lane's offset in the row
        b.emit("v_lshl_add_u64", addr, off, 0, ptr)
        return addr

    # ---- Q: loaded once, premultiplied by scale * log2(e)
    sc, qi = b.v(), b.v()
    if r["scale"]:
        b.emit("v_mov_b32_e32", sc, A[r["scale"]])
        b.emit("v_mul_f32_e32", sc, LOG2E, sc)
    else:
        b.emit("v_mov_b32_e32", sc, LOG2E)
    b.emit("v_add_u32_e32", qi, q0, c16)
    b.emit("v_min_u32_e32", qi, lastq, qi)
    aq = row_address(A[qn], qi, g64)
    Qr = [b.v(4) for _ in range(XS)]
    for x in range(XS):
        b.emit("global_load_dwordx4", Qr[x], aq, "off", **({"offset": xoff[x]} if xoff[x] else {}))
    for x in range(XS):
        for i in range(4):
            b.emit("v_mul_f32_e32", b.part(Qr[x], i), sc, b.part(Qr[x], i))
    acc = [b.v(4) for _ in range(CH)]
    for a4 in acc:
        for i in range(4):
            b.emit("v_mov_b32_e32", b.part(a4, i), 0)
    ref, lsum, ninf = b.v(), b.v(), b.v()
    b.emit("v_mov_b32_e32", ninf, NEG_INF)
    b.emit("v_mov_b32_e32", ref, NEG_INF)
    b.emit("v_mov_b32_e32", lsum, 0)

    # ---- the tiles of keys: wave w takes tiles w, w + W, ...
    kb = b.s()
    done = b.new_label()
    if W > 1:
        wv = b.s()
        b.emit("v_readfirstlane_b32", wv, wave)
        b.emit("s_lshl_b32", kb, wv, 4)
        b.emit("s_cmp_lt_u32", kb, NK)
        b.emit("s_cbranch_scc0", done)
    else:
        b.emit("s_mov_b32", kb, 0)

    def issue(base, into=None):
        """The loads of the tile at key `base` (rows beyond the last key are clamped): K in operand layout, V per result
        register; into fresh registers, or into the registers of an earlier tile."""
        ki = b.v()
        b.emit("v_add_u32_e32", ki, base, c16)
        b.emit("v_min_u32_e32", ki, lastk, ki)
        ak = row_address(A[kn], ki, g64)
        Kr, Vr = into or ([b.v(4) for _ in range(XS)], [[b.v(4) for _ in range(n64)] for _ in range(4)])
        for x in range(XS):
            b.emit("global_load_dwordx4", Kr[x], ak, "off", **({"offset": xoff[x]} if xoff[x] else {}))
        for i in range(4):
            vi = b.v()
            b.emit("v_add_u32_e32", vi, base, g4r[i])
            b.emit("v_min_u32_e32", vi, lastk, vi)
            av = row_address(A[vn], vi, c4)
            for h in range(n64):
                b.emit("global_load_dwordx4", Vr[i][h], av, "off", **({"offset": 256 * h} if h else {}))
        return Kr, Vr

    def compute(Kr, Vr):
        keyv = [b.v() for _ in range(4)]
        for i in range(4):
            b.emit("v_add_u32_e32", keyv[i], kb, g4r[i])              # the key of result register i in this lane
        S = b.v(4)
        first = True
        for x in range(XS):
            for i in range(4):
                b.emit(MFMA, S, b.part(Kr[x], i), b.part(Qr[x], i), 0 if first else S)
                first = False
        d = [b.v() for _ in range(4)]
        for i in range(4):
            b.emit("v_cmp_gt_u32_e32", "vcc", NK, keyv[i])                # the key exists
            b.emit("v_cndmask_b32_e32", b.part(S, i), ninf, b.part(S, i), "vcc")
        for i in range(4):
            b.emit("v_sub_f32_e32", d[i], b.part(S, i), ref)
        top = b.v()
        b.emit("v_max_f32_e32", top, d[0], d[1])
        b.emit("v_max_f32_e32", top, top, d[2])
        b.emit("v_max_f32_e32", top, top, d[3])
        fast = b.new_label()
        b.emit("v_cmp_lt_f32_e32", "vcc", THRESHOLD, top)                 # a score far above the reference (always in the first tile)
        b.emit("s_cbranch_vccz", fast)
        # slow path: the exact maximum per query becomes the reference; the sum and the accumulators follow
        tm, t2, alpha = b.v(), b.v(), b.v()
        b.emit("v_max_f32_e32", tm, b.part(S, 0), b.part(S, 1))
        b.emit("v_max_f32_e32", tm, tm, b.part(S, 2))
        b.emit("v_max_f32_e32", tm, tm, b.part(S, 3))
        b.emit("ds_bpermute_b32", t2, idx16, tm)
        b.emit("v_max_f32_e32", tm, tm, t2)
        b.emit("ds_bpermute_b32", t2, idx32, tm)
        b.emit("v_max_f32_e32", tm, tm, t2)
        b.emit("v_max_f32_e32", tm, tm, ref)
        b.emit("v_sub_f32_e32", alpha, ref, tm)
        b.emit("v_exp_f32_e32", alpha, alpha)
        b.emit("v_mov_b32_e32", ref, tm)
        b.emit("v_mul_f32_e32", lsum, lsum, alpha)
        for i in range(4):
            ai = b.v()
            b.emit("ds_bpermute_b32", ai, idxq[i], alpha)
            for a4 in acc:
                b.emit("v_mul_f32_e32", b.part(a4, i), b.part(a4, i), ai)
        for i in range(4):
            b.emit("v_sub_f32_e32", d[i], b.part(S, i), ref)
        b.label(fast)
        for i in range(4):
            b.emit("v_exp_f32_e32", d[i], d[i])
        for i in range(4):
            b.emit("v_add_f32_e32", lsum, lsum, d[i])
        for i in range(4):
            for c in range(CH):
                b.emit(MFMA, acc[c], d[i], b.part(Vr[i][c // 4], c % 4), acc[c])

    step = TILE * W
    if ahead:
        nxt = b.s()
        sets = [issue(kb), None]
        loop = b.label(align="5, , 4")
        for cur in (0, 1):
            b.emit("s_add_u32", nxt, kb, step)
            sets[1 - cur] = issue(nxt, sets[1 - cur])                  # the next tile's loads are in flight during this tile's work
            compute(*sets[cur])
            b.emit("s_mov_b32", kb, nxt)
            b.emit("s_cmp_lt_u32", kb, NK)
            if cur == 0:
                b.emit("s_cbranch_scc0", done)
            else:
                b.emit("s_cbranch_scc1", loop)
    else:
        loop = b.label(align="5, , 4")
        compute(*issue(kb))
        b.emit("s_add_u32", kb, kb, step)
        b.emit("s_cmp_lt_u32", kb, NK)
        b.emit("s_cbranch_scc1", loop)
    b.label(done)

    lds = 0
    if W > 1:
        # ---- merge the waves: common reference, then sums and accumulators added up by wave 0
        slot = 4 * (2 + 4 * CH) * LANES                                # bytes per wave: ref, sum, accumulators (256 B each)
        lds = slot * W
        sbase = b.s()
        mine, la, t = b.v(), b.v(), b.v()
        b.emit("s_mul_i32", sbase, wv, slot)
        b.emit("v_lshlrev_b32_e32", mine, 2, lane)                     # this lane's place in wave 0's area
        b.emit("v_add_u32_e32", la, sbase, mine)                       # and in this wave's
        b.emit("ds_write_b32", la, ref)
        b.emit("s_barrier")
        best = b.v()
        other = [mine] + [b.v() for _ in range(1, W)]
        for w in range(1, W):
            b.emit("v_add_u32_e32", other[w], slot * w, mine)
        b.emit("ds_read_b32", best, mine)
        for w in range(1, W):
            b.emit("ds_read_b32", t, other[w])
            b.emit("v_max_f32_e32", best, best, t)                     # a wave without tiles has -inf: its weight below is 0
        alpha = b.v()
        b.emit("v_sub_f32_e32", alpha, ref, best)
        b.emit("v_exp_f32_e32", alpha, alpha)
        b.emit("v_mul_f32_e32", lsum, lsum, alpha)
        b.emit("ds_write_b32", la, lsum, offset=4 * LANES)
        for i in range(4):
            ai = b.v()
            b.emit("ds_bpermute_b32", ai, idxq[i], alpha)
            for c, a4 in enumerate(acc):
                b.emit("v_mul_f32_e32", b.part(a4, i), b.part(a4, i), ai)
                b.emit("ds_write_b32", la, b.part(a4, i), offset=4 * LANES * (2 + 4 * c + i))
        b.emit("s_barrier")
        end = b.new_label()
        b.emit("s_cmp_eq_u32", wv, 0)
        b.emit("s_cbranch_scc0", end)                                  # wave 0 adds the others up and stores
        b.emit("v_mov_b32_e32", ref, best)
        for w in range(1, W):
            b.emit("ds_read_b32", t, other[w], offset=4 * LANES)
            b.emit("v_add_f32_e32", lsum, lsum, t)
            for c, a4 in enumerate(acc):
                for i in range(4):
                    b.emit("ds_read_b32", t, other[w], offset=4 * LANES * (2 + 4 * c + i))
                    b.emit("v_add_f32_e32", b.part(a4, i), b.part(a4, i), t)
    # ---- normalize and store
    t2 = b.v()
    b.emit("ds_bpermute_b32", t2, idx16, lsum)
    b.emit("v_add_f32_e32", lsum, lsum, t2)
    b.emit("ds_bpermute_b32", t2, idx32, lsum)
    b.emit("v_add_f32_e32", lsum, lsum, t2)
    for i in range(4):
        inv, qv, mask = b.v(), b.v(), b.s(2)
        b.emit("ds_bpermute_b32", inv, idxq[i], lsum)
        b.emit("v_rcp_f32_e32", inv, inv)
        b.emit("v_add_u32_e32", qv, q0, g4r[i])
        b.emit("v_cmp_gt_u32_e64", mask, NQ, qv)                       # the query exists
        ao = row_address(A[on], qv, c4)
        for a4 in acc:
            b.emit("v_mul_f32_e32", b.part(a4, i), b.part(a4, i), inv)
        b.emit("s_mov_b64", "exec", mask)
        for c, a4 in enumerate(acc):
            b.emit("global_store_dword", ao, b.part(a4, i), "off", **({"offset": col(c)} if col(c) else {}))
        b.emit("s_mov_b64", "exec", -1)
    if ln:
        lv, qv, off, addr, mask = b.v(), b.v(2), b.v(2), b.v(2), b.s(2)
        b.emit("v_log_f32_e32", lv, lsum)
        b.emit("v_add_f32_e32", lv, ref, lv)
        b.emit("v_mul_f32_e32", lv, LN2, lv)
        b.emit("v_add_u32_e32", b.part(qv, 0), q0, c16)
        b.emit("v_mov_b32_e32", b.part(qv, 1), 0)
        b.emit("v_lshl_add_u64", addr, qv, 2, A[ln])
        b.emit("v_cmp_gt_u32_e64", mask, 16, lane)                     # one lane per query
        b.emit("v_cmp_gt_u32_e32", "vcc", NQ, b.part(qv, 0))
        b.emit("s_and_b64", "exec", mask, "vcc")
        b.emit("global_store_dword", addr, lv, "off")
        b.emit("s_mov_b64", "exec", -1)
    if W > 1:
        b.label(end)
    b.emit("s_endpgm")
    k = b.finish(bd.args, lds_bytes=lds)
    return Compiled(abi.make_module([k]), {"grid": [f"cdiv({m.param(qn).shape[0]}, {TILE})"], "block": [LANES * W], "lds": 0},
                    "attention_mfma", {"waves": W, "ahead": ahead})
