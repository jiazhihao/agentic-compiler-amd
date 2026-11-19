"""NumPy reference programs of the corpus. Inputs arrive in their compute dtype."""
import numpy as np


def axpy(x, y, a, n):
    return {"y": np.float32(a) * x + y}
