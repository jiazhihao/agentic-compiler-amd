"""What one MFMA computes, lane by lane, from the layouts in `agc/arch/gfx950.yaml` (the model the
probe kernel is checked against on the device)."""
import numpy as np

from agc.arch.model import load


def _mfma(name, a, b):
    lay = load().data["mfma"]["layouts"][name]["value"]
    T, K, nd = lay["tile"], lay["k"], lay["dst_regs"]
    A, B = np.zeros((T, K)), np.zeros((K, T))
    for l in range(64):
        for e in range(lay["src_elements"]):
            env = {"l": l, "e": e}
            exec(lay["a"], {}, env)
            A[env["i"], env["k"]] = a[l, e]
            exec(lay["b"], {}, env)
            B[env["k"], env["j"]] = b[l, e]
    D = A @ B
    out = np.zeros((64, 16), np.float32)
    for l in range(64):
        for r in range(nd):
            env = {"l": l, "r": r}
            exec(lay["d"], {}, env)
            out[l, r] = D[env["i"], env["j"]]
    return out


def mfma_32x32x16(a, b):
    return _mfma("v_mfma_f32_32x32x16_bf16", a, b)


def mfma_16x16x32(a, b):
    return _mfma("v_mfma_f32_16x16x32_bf16", a, b)
