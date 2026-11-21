"""NumPy references of the ROCm library kernels in this directory.

Tensors arrive in their compute dtype (float32, int64 for the index arrays), scalars by name. Sums are
accumulated in float64; float scalars are rounded to float32 first, as the kernel receives them.
Every output is defined everywhere (the battery poisons outputs and compares whole tensors).

A `<name>_scale` function is the magnitude the `cond` tolerance is relative to, for the kernels whose
terms can cancel on |inputs| (`c*y - s*x`): it is called with the absolute values of the float inputs
and returns the sum of the magnitudes of the terms.
"""
import numpy as np

f32 = np.float32


def _f64(a):
    return np.asarray(a, np.float64)


def _block_partials(terms, nb, blocks):
    """rocBLAS first-stage reduction: block b owns the elements i with (i // nb) % blocks == b."""
    owner = (np.arange(terms.size) // nb) % blocks
    return np.bincount(owner, weights=_f64(terms), minlength=blocks)


# ---- rocBLAS ---------------------------------------------------------------------------------------

def rb_copy(x, n):
    return {"y": x}


def rb_scal(x, n, alpha):
    return {"x": f32(alpha) * x}


def rb_axpy(x, y, n, alpha):
    return {"y": _f64(y) + _f64(f32(alpha)) * x}


def rb_swap(x, y, n):
    return {"x": y, "y": x}


def rb_rot(x, y, n, c, s):
    c, s, x, y = _f64(f32(c)), _f64(f32(s)), _f64(x), _f64(y)
    return {"x": c * x + s * y, "y": c * y - s * x}


def rb_rot_scale(x, y, n, c, s):
    c, s = abs(_f64(f32(c))), abs(_f64(f32(s)))
    return {"x": c * x + s * y, "y": c * y + s * x}


def rb_dot(x, y, workspace, out, n):
    blocks = workspace.size                     # cdiv(n, NB * WIN), NB = 512, WIN = 4
    part = _block_partials(_f64(x) * _f64(y), 512, blocks)
    if blocks == 1:                             # gridDim.x == 1: the sum goes to `out`, workspace is untouched
        return {"workspace": workspace, "out": part}
    return {"workspace": part, "out": out}


def rb_nrm2(x, n, nblocks):
    return {"workspace": _block_partials(_f64(x) ** 2, 512, nblocks)}


def rb_gemvn(A, x, y, m, n, alpha, lda, beta):
    # A is column-major with lda = m: the tensor is [n, m], A[j, i] = a(i, j)
    return {"y": _f64(f32(alpha)) * (_f64(A).T @ _f64(x)) + _f64(f32(beta)) * y}


def rb_gemvt(A, x, y, m, n, alpha, lda, beta):
    return {"y": _f64(f32(alpha)) * (_f64(A) @ _f64(x)) + _f64(f32(beta)) * y}


def rb_ger(x, y, A, m, n, alpha, lda):
    return {"A": _f64(A) + _f64(f32(alpha)) * np.outer(_f64(y), _f64(x))}


# ---- MIOpen ----------------------------------------------------------------------------------------

def mo_glu_fwd(input, N):
    a, b = _f64(input[0]), _f64(input[1])
    with np.errstate(over="ignore"):
        return {"output": a / (1.0 + np.exp(-b))}


def mo_rope_fwd(x, cos, sin, output_numel, rotary_numel):
    v = _f64(x).reshape(-1)
    pair = v.reshape(-1, 2)
    rot = np.stack([-pair[:, 1], pair[:, 0]], axis=1).reshape(-1)       # even: -x[i + 1], odd: x[i - 1]
    f = np.arange(v.size) % rotary_numel
    return {"y": (v * _f64(cos).reshape(-1)[f] + rot * _f64(sin).reshape(-1)[f]).reshape(x.shape)}


def mo_rope_fwd_scale(x, cos, sin, output_numel, rotary_numel):
    v = _f64(x).reshape(-1)
    rot = v.reshape(-1, 2)[:, ::-1].reshape(-1)
    f = np.arange(v.size) % rotary_numel
    return {"y": (v * _f64(cos).reshape(-1)[f] + rot * _f64(sin).reshape(-1)[f]).reshape(x.shape)}


def mo_reduce_sum(input, N):
    blocks = -(-input.size // 256)
    padded = np.zeros(blocks * 256)
    padded[:input.size] = input
    return {"output": padded.reshape(blocks, 256).sum(axis=1)}


def mo_bn_infer(estimatedMean, estimatedVariance, scale, bias, epsilon, c, hw, batchSize, cStride, hwStride,
                batchStride, alpha, beta, **tensors):
    x = _f64(tensors["in"])                                             # [n, c, hw]
    inv = 1.0 / np.sqrt(np.abs(_f64(estimatedVariance + f32(epsilon))))  # the sum is rounded to float32, as in the kernel
    inhat = (x - _f64(estimatedMean)[None, :, None]) * inv[None, :, None]
    return {"out": _f64(scale)[None, :, None] * inhat + _f64(bias)[None, :, None]}


def mo_t5_layernorm(x, weight, eps, inner_size, mode):
    v = _f64(x)
    rstd = 1.0 / np.sqrt(_f64(f32((v * v).mean(axis=1))) + _f64(f32(eps)))
    w = 1.0 if mode == 4 else _f64(weight)                              # MIOPEN_ELEMENTWISE_AFFINE_T5 == 4
    return {"y": v * rstd[:, None] * w, "rstd": rstd}


def mo_active_fwd(bot, map_size_aligned, gamma, beta, alpha):
    return {"top": bot * np.where(bot > 0, f32(1), f32(alpha))}        # leaky ReLU, as the kernel writes it


def _adam(param_in, grad_in, exp_avg_in, exp_avg_sq_in, lr, beta1, beta2, weight_decay, eps, step, amsgrad,
          maximize, adamw, magnitude):
    lr, beta1, beta2, wd, eps = (_f64(f32(v)) for v in (lr, beta1, beta2, weight_decay, eps))
    assert not amsgrad, "the reference covers the launcher's plain Adam (amsgrad = false)"
    sub = 1.0 if magnitude else -1.0             # the sign of the terms that are subtracted
    param, grad, m, v = _f64(param_in), _f64(grad_in), _f64(exp_avg_in), _f64(exp_avg_sq_in)
    bc1, bc2 = 1.0 - beta1 ** step, 1.0 - beta2 ** step
    if maximize:
        grad = grad if magnitude else -grad
    if wd != 0:
        if adamw:
            param = param + sub * lr * wd * param
        else:
            grad = grad + param * wd
    m = m * beta1 + grad * (1.0 - beta1)
    v = v * beta2 + grad * grad * (1.0 - beta2)
    denom = np.sqrt(v) / np.sqrt(bc2) + eps
    param = param + sub * (lr / bc1) * m / denom
    return param, m, v


def mo_adam(param_in, grad_in, exp_avg_in, exp_avg_sq_in, max_exp_avg_sq_in, max_exp_avg_sq_out, lr, beta1, beta2,
            weight_decay, eps, step, amsgrad, maximize, adamw, input_size, magnitude=False):
    param, m, v = _adam(param_in, grad_in, exp_avg_in, exp_avg_sq_in, lr, beta1, beta2, weight_decay, eps, step,
                        amsgrad, maximize, adamw, magnitude)
    # amsgrad = false: max_exp_avg_sq_out is not written
    return {"param_out": param, "exp_avg_out": m, "exp_avg_sq_out": v, "max_exp_avg_sq_out": max_exp_avg_sq_out}


def mo_adam_scale(**kw):
    return mo_adam(**kw, magnitude=True)


def mo_prelu_bwd(input, weight, output_grad, N):
    pos = input > 0
    return {"input_grad": np.where(pos, output_grad, weight[0] * output_grad),
            "weight_grad_collector": np.where(pos, f32(0), input * output_grad)}


# ---- FlashInfer ------------------------------------------------------------------------------------

def _rms_rcp(v, eps):
    """1 / sqrt(mean(v^2) + eps) per row; the mean and the sum with eps are rounded to float32 as in the kernels."""
    return 1.0 / np.sqrt(_f64(f32((v * v).mean(axis=1)) + f32(eps)))[:, None]


def fi_rmsnorm(input, weight, d, stride_input, stride_output, weight_bias, eps):
    v = _f64(input)
    return {"output": v * _rms_rcp(v, eps) * (_f64(f32(weight_bias)) + _f64(weight))}


def fi_fused_add_rmsnorm(input, residual, weight, d, stride_input, stride_residual, weight_bias, eps):
    x = input + residual                        # float32, as the kernel adds and stores it
    v = _f64(x)
    return {"residual": x, "input": v * _rms_rcp(v, eps) * (_f64(f32(weight_bias)) + _f64(weight))}


def fi_silu_and_mul(input, d):
    x, y = _f64(input[:, :d]), _f64(input[:, d:])
    with np.errstate(over="ignore"):
        return {"out": x / (1.0 + np.exp(-x)) * y}


def fi_gelu_tanh_and_mul(input, d):
    x, y = _f64(input[:, :d]), _f64(input[:, d:])
    return {"out": x * 0.5 * (1.0 + np.tanh(0.7978845608028654 * (x + 0.044715 * x * x * x))) * y}


def _merge(v, s, axis):
    """Merge attention states along `axis`: weights 2^(s - max s); returns (v, s) merged. The differences
    s - max are rounded to float32 as in the kernel."""
    m = s.max(axis=axis, keepdims=True)
    w = np.exp2(_f64(s - m))
    d = w.sum(axis=axis, keepdims=True)
    vm = (np.expand_dims(w / d, -1) * _f64(v)).sum(axis=axis)
    return vm, (_f64(m) + np.log2(d)).squeeze(axis)


def fi_merge_state(v_a, s_a, v_b, s_b, num_heads, head_dim):
    v, s = _merge(np.stack([v_a, v_b]), np.stack([s_a, s_b]), 0)
    return {"v_merged": v, "s_merged": s}


def fi_merge_state_scale(v_a, s_a, v_b, s_b, num_heads, head_dim):
    return {"v_merged": v_a + v_b, "s_merged": s_a + s_b}       # the weights are in [0, 1]


def fi_merge_state_in_place(v, s, v_other, s_other, mask, num_heads, head_dim):
    vm, sm = _merge(np.stack([v, v_other]), np.stack([s, s_other]), 0)
    keep = mask == 0                             # positions whose mask is 0 are left untouched
    return {"v": np.where(keep[:, None, None], v, vm), "s": np.where(keep[:, None], s, sm)}


def fi_merge_state_in_place_scale(v, s, v_other, s_other, mask, num_heads, head_dim):
    return {"v": v + v_other, "s": s + s_other}


def fi_merge_states(V, S, num_index_sets, num_heads, head_dim):
    if num_index_sets == 1:
        return {"v_merged": V[:, 0], "s_merged": S[:, 0]}
    v, s = _merge(V, S, 1)
    return {"v_merged": v, "s_merged": s}


def fi_merge_states_scale(V, S, num_index_sets, num_heads, head_dim):
    return {"v_merged": V.sum(axis=1), "s_merged": S.sum(axis=1)}


def _fi_rope(x, pos_ids, rotary_dim, rcp_scale, rcp_theta, magnitude):
    j = np.arange(rotary_dim)
    expo = (2 * (j % (rotary_dim // 2))).astype(f32) / f32(rotary_dim)
    freq = np.power(_f64(f32(rcp_theta)), _f64(expo)).astype(f32) * f32(rcp_scale)   # powf, correctly rounded
    embed = _f64(pos_ids.astype(f32)[:, None] * freq[None, :])          # float32 product, as in the kernel
    cos, sin = np.cos(embed)[:, None, :], np.sin(embed)[:, None, :]
    v, h = _f64(x), rotary_dim // 2
    out = v.copy()
    if magnitude:
        out[..., :rotary_dim] = v[..., :rotary_dim] + np.concatenate([v[..., h:rotary_dim], v[..., :h]], axis=-1)
        return out
    out[..., :h] = v[..., :h] * cos[..., :h] - v[..., h:rotary_dim] * sin[..., :h]
    out[..., h:rotary_dim] = v[..., h:rotary_dim] * cos[..., h:] + v[..., :h] * sin[..., h:]
    return out


def fi_rope(q, k, pos_ids, nnz, num_qo_heads, num_kv_heads, rotary_dim, smooth_a, smooth_b, rope_rcp_scale,
            rope_rcp_theta, magnitude=False, **strides):
    assert smooth_a == 0 and smooth_b == 0, "the reference covers smooth_a = smooth_b = 0 (plain llama RoPE)"
    return {n + "_rope": _fi_rope(x, pos_ids, rotary_dim, rope_rcp_scale, rope_rcp_theta, magnitude)
            for n, x in (("q", q), ("k", k))}


def fi_rope_scale(**kw):
    return fi_rope(**kw, magnitude=True)


# ---- vLLM ------------------------------------------------------------------------------------------

def vl_rms_norm(input, weight, epsilon, num_tokens, hidden_size, **strides):
    v = _f64(input)
    return {"out": v * _rms_rcp(v, epsilon) * _f64(weight)}


def vl_fused_add_rms_norm(input, residual, weight, epsilon, num_tokens, hidden_size, **strides):
    x = input + residual                        # float32, as the kernel adds and stores it
    v = _f64(x)
    return {"residual": x, "input": v * _rms_rcp(v, epsilon) * _f64(weight)}


def vl_rotary_embedding(positions, query, key, cos_sin_cache, rot_dim, inverse, magnitude=False, **geometry):
    e = rot_dim // 2
    cache = _f64(cos_sin_cache)[positions]                              # [n, rot_dim]: cos | sin
    cos, sin = cache[:, None, :e], cache[:, None, e:]
    sin = sin if (magnitude or not inverse) else -sin
    out = {}
    for name, t in (("query", query), ("key", key)):
        v = _f64(t)
        x, y, o = v[..., :e], v[..., e:rot_dim], v.copy()
        o[..., :e] = x * cos + y * sin if magnitude else x * cos - y * sin
        o[..., e:rot_dim] = y * cos + x * sin
        out[name] = o
    return out


def vl_rotary_embedding_scale(**kw):
    return vl_rotary_embedding(**kw, magnitude=True)


def vl_moe_align(topk_ids, expert_map, num_experts, padded_num_experts, experts_per_warp, block_size, numel,
                 max_num_tokens_padded, topk_num, has_expert_map):
    ids = topk_ids[(topk_ids >= 0) & (topk_ids < num_experts)]
    counts = np.bincount(ids, minlength=num_experts)
    padded = -(-counts // block_size) * block_size
    cumsum = np.concatenate([[0], np.cumsum(padded)])
    blocks = -(-max_num_tokens_padded // block_size)
    expert_ids = np.full(blocks, -1)
    expert_ids[:cumsum[-1] // block_size] = np.repeat(np.arange(num_experts), padded // block_size)
    return {"sorted_token_ids": np.full(max_num_tokens_padded, numel), "expert_ids": expert_ids,
            "total_tokens_post_pad": cumsum[-1:], "cumsum": cumsum}


# ---- ports -----------------------------------------------------------------------------------------

def _attend(scores, values):
    """softmax(scores) @ values and logsumexp(scores) per row; scores [..., n] (masked entries -inf)."""
    m = scores.max(axis=-1, keepdims=True)
    w = np.exp(scores - m)
    l = w.sum(axis=-1, keepdims=True)
    return (w / l) @ values, (m + np.log(l))[..., 0]


def fa_attention(Q, K, V, n_q, n_k, scale, causal):
    s = _f64(f32(scale)) * (_f64(Q) @ _f64(K).T)
    if causal:
        s = np.where(np.arange(n_k)[None, :] <= np.arange(n_q)[:, None], s, -np.inf)
    out, lse = _attend(s, _f64(V))
    return {"out": out, "lse": lse}


def fa_attention_scale(Q, K, V, n_q, n_k, scale, causal):
    # the weights sum to 1: every output column is bounded by the largest |V| of that column
    return {"out": np.broadcast_to(V.max(axis=0), (n_q, V.shape[1])), "lse": np.zeros(n_q)}


def attn_decode(q, k, v, kv_len, num_kv_heads, group_size, scale):
    head = np.arange(q.shape[0]) // group_size
    s = _f64(f32(scale)) * np.einsum("hd,shd->hs", _f64(q), _f64(k)[:, head])
    w_m = s.max(axis=1, keepdims=True)
    w = np.exp(s - w_m)
    l = w.sum(axis=1, keepdims=True)
    return {"o": np.einsum("hs,shd->hd", w / l, _f64(v)[:, head]), "lse": (w_m + np.log(l))[:, 0]}


def attn_decode_scale(q, k, v, kv_len, num_kv_heads, group_size, scale):
    head = np.arange(q.shape[0]) // group_size
    return {"o": v.max(axis=0)[head], "lse": np.zeros(q.shape[0])}


def mla_decode(q, kv_cache, num_heads, kv_len, scale):
    kv = _f64(kv_cache)
    out, lse = _attend(_f64(f32(scale)) * (_f64(q) @ kv.transpose(0, 2, 1)), kv[:, :, :512])
    return {"out": out, "lse": lse}


def mla_decode_scale(q, kv_cache, num_heads, kv_len, scale):
    top = kv_cache[:, :, :512].max(axis=1)                              # [b, 512]
    return {"out": np.broadcast_to(top[:, None, :], (q.shape[0], num_heads, 512)), "lse": np.zeros(q.shape[:2])}


def kda_step(S, g, k, v, beta, q, dk, dv, scale, magnitude=False):
    S, g, k, v, beta, q = (_f64(a) for a in (S, g, k, v, beta, q))
    sub = 1.0 if magnitude else -1.0             # the delta rule subtracts the prediction k^T S
    S = S * np.exp(g)[:, :, None]                # (on |inputs| exp(|g|) >= exp(g): an upper bound)
    u = v + sub * np.einsum("hk,hkv->hv", k, S)
    S = S + (beta[:, None] * k)[:, :, None] * u[:, None, :]
    return {"S": S, "o": np.einsum("hk,hkv->hv", _f64(f32(scale)) * q, S)}


def kda_step_scale(**kw):
    return kda_step(**kw, magnitude=True)


def moe_gate_topk(logits, num_tokens, num_experts, k):
    x = _f64(logits)
    e = np.exp(x - x.max(axis=1, keepdims=True))
    p = e / e.sum(axis=1, keepdims=True)
    idx = np.argsort(-logits, axis=1, kind="stable")[:, :k]             # ties: the lower index first
    return {"weights": np.take_along_axis(p, idx, axis=1), "indices": idx}
