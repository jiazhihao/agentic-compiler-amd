"""Independent NumPy references for the tensor-program manifests (no kernel source exists for these)."""
import numpy as np


def temperature_softmax(x, t, cols):
    v = x.astype(np.float64)
    e = np.exp((v - v.max(axis=1, keepdims=True)) * np.float64(np.float32(t)))
    return e / e.sum(axis=1, keepdims=True)
