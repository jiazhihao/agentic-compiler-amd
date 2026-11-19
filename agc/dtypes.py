"""Element types, defined once.

A `DType` is its name (a `str`) and carries its storage dtype (the bytes of a buffer), its
compute dtype (what a reference or interpreter computes in), and conversions. bf16 and the
OCP FP8 formats (gfx950 implements OCP `e4m3fn` and `e5m2`) use `ml_dtypes`.
"""
from __future__ import annotations

import ml_dtypes
import numpy as np


class DType(str):
    kind: str          # float | int | uint | bool
    bits: int
    storage: np.dtype  # buffer bytes (bf16 / fp8 as their ml_dtypes types)
    compute: np.dtype  # reference compute type
    c: str             # HIP C type

    def __new__(cls, name: str, kind: str, bits: int, storage, compute, c: str):
        self = str.__new__(cls, name)
        self.kind, self.bits, self.c = kind, bits, c
        self.storage, self.compute = np.dtype(storage), np.dtype(compute)
        return self

    def __reduce__(self):
        return (dtype, (str(self),))

    @property
    def itemsize(self) -> int:
        return self.storage.itemsize

    @property
    def is_float(self) -> bool:
        return self.kind == "float"

    def to_storage(self, x) -> np.ndarray:
        """Values → buffer contents (round to nearest even for the narrow floats)."""
        return np.asarray(x).astype(self.storage)

    def to_compute(self, a) -> np.ndarray:
        return np.asarray(a).astype(self.compute)

    def from_storage(self, a) -> np.ndarray:
        """Buffer contents → values for comparison (float64 for floats, the integers unchanged)."""
        a = np.asarray(a)
        return a.astype(np.float64) if self.is_float else a

    def bits_view(self) -> np.dtype:
        """An unsigned integer dtype of the same width (to compare / poison raw bits)."""
        return np.dtype(f"u{self.itemsize}")


_F32, _F64 = np.float32, np.float64
DTYPES: dict[str, DType] = {d: d for d in (
    DType("f64", "float", 64, np.float64, _F64, "double"),
    DType("f32", "float", 32, np.float32, _F32, "float"),
    DType("f16", "float", 16, np.float16, _F32, "_Float16"),
    DType("bf16", "float", 16, ml_dtypes.bfloat16, _F32, "__bf16"),
    DType("e4m3", "float", 8, ml_dtypes.float8_e4m3fn, _F32, "__hip_fp8_e4m3"),
    DType("e5m2", "float", 8, ml_dtypes.float8_e5m2, _F32, "__hip_fp8_e5m2"),
    DType("i64", "int", 64, np.int64, np.int64, "long long"),
    DType("i32", "int", 32, np.int32, np.int64, "int"),
    DType("i16", "int", 16, np.int16, np.int64, "short"),
    DType("i8", "int", 8, np.int8, np.int64, "signed char"),
    DType("u64", "uint", 64, np.uint64, np.uint64, "unsigned long long"),
    DType("u32", "uint", 32, np.uint32, np.int64, "unsigned int"),
    DType("u16", "uint", 16, np.uint16, np.int64, "unsigned short"),
    DType("u8", "uint", 8, np.uint8, np.int64, "unsigned char"),
    DType("bool", "bool", 8, np.bool_, np.bool_, "bool"),
)}
FLOAT_DTYPES = frozenset(n for n, d in DTYPES.items() if d.is_float)


def dtype(name: str) -> DType:
    try:
        return DTYPES[str(name)]
    except KeyError:
        raise ValueError(f"unknown dtype {name!r}; known: {', '.join(DTYPES)}") from None
