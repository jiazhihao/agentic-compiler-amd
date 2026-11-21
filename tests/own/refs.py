"""References of the control-flow kernels in `control.hip`."""
import numpy as np


def first_below(x, t, rows, cols):
    hit = x < np.float32(t)
    return {"out": np.where(hit.any(axis=1), hit.argmax(axis=1), -1).astype(np.int32)}


def sum_positive(x, rows, cols):
    acc = np.zeros(x.shape[0], dtype=np.float32)
    for j in range(x.shape[1]):                      # the kernel's order of additions, in float32
        v = x[:, j]
        acc = np.where(v > 0, acc + v, acc).astype(np.float32)
    return {"out": acc}


def halvings(x, n):
    v = np.abs(x).astype(np.float32)
    k = np.zeros(v.shape, dtype=np.int32)
    going = np.ones(v.shape, dtype=bool)
    for _ in range(40):
        v = np.where(going, v * np.float32(0.5), v).astype(np.float32)
        k = np.where(going, k + 1, k)
        going &= (v >= 1) & (k < 40)
    return {"out": k.astype(np.int32)}


def last_above(x, t, rows, cols):
    hit = x >= np.float32(t)
    last = x.shape[1] - 1 - hit[:, ::-1].argmax(axis=1)
    return {"out": np.where(hit.any(axis=1), last, -1).astype(np.int32)}
