"""NumPy reference programs of the corpus. Tensors arrive in their compute dtype; scalars by name.
Reductions accumulate in float64 (the comparison allows for the kernel's float32 order)."""
import numpy as np


def axpy(x, y, a, n):
    return {"y": np.float32(a) * x + y}


def gelu(x, n):
    v = x.astype(np.float64)
    return 0.5 * v * (1.0 + np.tanh(0.7978845608 * (v + 0.044715 * v ** 3)))


def cast_bf16(x, n):
    return x


def row_sum(x, rows, cols):
    return x.sum(axis=1, dtype=np.float64)


def row_argmax(x, rows, cols):
    return np.argmax(x, axis=1)


def softmax(x, rows, cols):
    v = x.astype(np.float64)
    e = np.exp(v - v.max(axis=1, keepdims=True))
    return e / e.sum(axis=1, keepdims=True)


def rmsnorm(x, w, eps, rows, cols):
    v = x.astype(np.float64)
    return v / np.sqrt((v * v).mean(axis=1, keepdims=True) + eps) * w


def layernorm(x, g, b, eps, rows, cols):
    v = x.astype(np.float64)
    mean = v.mean(axis=1, keepdims=True)
    var = ((v - mean) ** 2).mean(axis=1, keepdims=True)
    return (v - mean) / np.sqrt(var + eps) * g + b


def transpose(x, rows, cols):
    return x.T
