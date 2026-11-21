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


def divmod(a, b, n):
    x, y = a.astype(np.int64), b.astype(np.int64)
    ux, uy = x & 0xFFFFFFFF, y & 0xFFFFFFFF

    def tdiv(p, q):                                  # C division truncates toward zero
        return np.sign(p) * np.sign(q) * (np.abs(p) // np.abs(q))

    def trem(p, q):
        return p - tdiv(p, q) * q

    i32 = lambda v: (v & 0xFFFFFFFF).astype(np.uint32).view(np.int32).astype(np.int64)
    qq = tdiv(x, y) + tdiv(x, 7) - tdiv(x, 16) + i32(ux // uy) + i32(ux // 641) + i32(ux // uy)
    rr = trem(x, y) - trem(x, 13) + trem(x, 8) + i32(ux % uy) + i32(ux % 10) + i32(ux % 1000)
    return {"q": i32(qq).astype(np.int32), "r": i32(rr).astype(np.int32)}
