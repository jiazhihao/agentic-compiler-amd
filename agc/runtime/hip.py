"""A minimal HIP runtime binding through ctypes (`libamdhip64.so`), with explicit signatures.

Only the module API is used: code objects are loaded from bytes (`hipModuleLoadData`) and
launched with a packed kernel-argument buffer (`hipModuleLaunchKernel` with `extra`), so no
HIP headers or host compiler are needed. The HIP runtime appends the hidden arguments
(block counts, group sizes, ...) that the code object's metadata declares.

Only the executor's worker subprocess imports this module (design D8).
"""
from __future__ import annotations

import ctypes as C
import os
from dataclasses import dataclass

import numpy as np


class HipError(RuntimeError):
    def __init__(self, call: str, code: int, message: str):
        super().__init__(f"{call} failed: {message} ({code})")
        self.call, self.code, self.message = call, code, message


_LIB_CANDIDATES = [os.environ.get("AGC_LIBAMDHIP64", ""), "/opt/rocm/lib/libamdhip64.so", "libamdhip64.so"]

_vp, _sz, _i, _u, _f = C.c_void_p, C.c_size_t, C.c_int, C.c_uint, C.c_float
_SIGS = {
    "hipInit": [_u],
    "hipGetDeviceCount": [C.POINTER(_i)],
    "hipSetDevice": [_i],
    "hipGetDevice": [C.POINTER(_i)],
    "hipDeviceGetName": [C.c_char_p, _i, _i],
    "hipDeviceGetPCIBusId": [C.c_char_p, _i, _i],
    "hipDeviceSynchronize": [],
    "hipMalloc": [C.POINTER(_vp), _sz],
    "hipFree": [_vp],
    "hipMemcpy": [_vp, _vp, _sz, _i],
    "hipMemsetD8": [_vp, C.c_ubyte, _sz],
    "hipMemsetD32Async": [_vp, _i, _sz, _vp],
    "hipMemsetAsync": [_vp, _i, _sz, _vp],
    "hipModuleLoadData": [C.POINTER(_vp), _vp],
    "hipModuleUnload": [_vp],
    "hipModuleGetFunction": [C.POINTER(_vp), _vp, C.c_char_p],
    "hipModuleLaunchKernel": [_vp, _u, _u, _u, _u, _u, _u, _u, _vp, C.POINTER(_vp), C.POINTER(_vp)],
    "hipFuncGetAttribute": [C.POINTER(_i), _i, _vp],
    "hipStreamCreate": [C.POINTER(_vp)],
    "hipStreamDestroy": [_vp],
    "hipStreamSynchronize": [_vp],
    "hipEventCreate": [C.POINTER(_vp)],
    "hipEventDestroy": [_vp],
    "hipEventRecord": [_vp, _vp],
    "hipEventSynchronize": [_vp],
    "hipEventElapsedTime": [C.POINTER(_f), _vp, _vp],
    "hipGetLastError": [],
    "hipMemGetInfo": [C.POINTER(_sz), C.POINTER(_sz)],
    "hipRuntimeGetVersion": [C.POINTER(_i)],
    "hipDriverGetVersion": [C.POINTER(_i)],
}

MEMCPY_H2D, MEMCPY_D2H, MEMCPY_D2D = 1, 2, 3
_LAUNCH_BUFFER_POINTER, _LAUNCH_BUFFER_SIZE, _LAUNCH_END = 1, 2, 3

# hipFunction_attribute
FUNC_ATTRS = {"max_threads_per_block": 0, "shared_size_bytes": 1, "const_size_bytes": 2,
              "local_size_bytes": 3, "num_regs": 4, "binary_version": 6,
              "max_dynamic_shared_size_bytes": 8}


class _Lib:
    _inst = None

    def __init__(self):
        last = None
        for name in _LIB_CANDIDATES:
            if not name:
                continue
            try:
                self.lib = C.CDLL(name)
                break
            except OSError as e:
                last = e
        else:
            raise HipError("dlopen", -1, f"cannot load libamdhip64: {last}")
        for fn, args in _SIGS.items():
            f = getattr(self.lib, fn)
            f.argtypes, f.restype = args, C.c_int
        self.lib.hipGetErrorString.argtypes, self.lib.hipGetErrorString.restype = [C.c_int], C.c_char_p

    @classmethod
    def get(cls) -> "_Lib":
        if cls._inst is None:
            cls._inst = _Lib()
        return cls._inst

    def __call__(self, fn: str, *args):
        code = getattr(self.lib, fn)(*args)
        if code != 0:
            raise HipError(fn, code, self.lib.hipGetErrorString(code).decode())


def lib() -> _Lib:
    return _Lib.get()


@dataclass
class Buffer:
    ptr: int
    nbytes: int

    def free(self):
        if self.ptr:
            lib()("hipFree", C.c_void_p(self.ptr))
            self.ptr = 0


class Kernel:
    def __init__(self, module: "Module", name: str):
        self.module, self.name = module, name
        h = C.c_void_p()
        lib()("hipModuleGetFunction", C.byref(h), module.handle, name.encode())
        self.handle = h

    def attribute(self, attr: str) -> int:
        v = C.c_int()
        lib()("hipFuncGetAttribute", C.byref(v), FUNC_ATTRS[attr], self.handle)
        return v.value

    def attributes(self) -> dict[str, int]:
        return {k: self.attribute(k) for k in FUNC_ATTRS}

    def prepare(self, grid, block, args: bytes, stream=None, lds_bytes: int = 0):
        """A zero-argument callable that submits this launch. All host-side work (argument buffer,
        ctypes conversion) is done here, so that a timed interval contains only the submission call."""
        buf = C.create_string_buffer(args, max(len(args), 1))
        size = C.c_size_t(len(args))
        extra = (C.c_void_p * 5)(C.c_void_p(_LAUNCH_BUFFER_POINTER), C.cast(buf, C.c_void_p),
                                 C.c_void_p(_LAUNCH_BUFFER_SIZE), C.cast(C.byref(size), C.c_void_p),
                                 C.c_void_p(_LAUNCH_END))
        g = [C.c_uint(int(x)) for x in list(grid) + [1] * (3 - len(grid))]
        b = [C.c_uint(int(x)) for x in list(block) + [1] * (3 - len(block))]
        fn, handle, lds = lib().lib.hipModuleLaunchKernel, self.handle, C.c_uint(lds_bytes)
        err = lib().lib.hipGetErrorString
        keep = (buf, size, extra)                       # referenced by the closure: alive as long as it is

        def submit():
            code = fn(handle, g[0], g[1], g[2], b[0], b[1], b[2], lds, stream, None, extra)
            if code != 0:
                raise HipError("hipModuleLaunchKernel", code, err(code).decode())
        submit.keep = keep
        return submit

    def launch(self, grid, block, args: bytes, stream=None, lds_bytes: int = 0):
        buf = C.create_string_buffer(args, max(len(args), 1))
        size = C.c_size_t(len(args))
        extra = (C.c_void_p * 5)(C.c_void_p(_LAUNCH_BUFFER_POINTER), C.cast(buf, C.c_void_p),
                                 C.c_void_p(_LAUNCH_BUFFER_SIZE), C.cast(C.byref(size), C.c_void_p),
                                 C.c_void_p(_LAUNCH_END))
        g = [int(x) for x in grid] + [1] * (3 - len(grid))
        b = [int(x) for x in block] + [1] * (3 - len(block))
        lib()("hipModuleLaunchKernel", self.handle, *g, *b, lds_bytes, stream, None, extra)


class Module:
    def __init__(self, image: bytes):
        self._image = C.create_string_buffer(image, len(image))   # keep alive while loaded
        h = C.c_void_p()
        lib()("hipModuleLoadData", C.byref(h), C.cast(self._image, C.c_void_p))
        self.handle = h

    def kernel(self, name: str) -> Kernel:
        return Kernel(self, name)

    def unload(self):
        if self.handle:
            lib()("hipModuleUnload", self.handle)
            self.handle = None


class Event:
    def __init__(self):
        h = C.c_void_p()
        lib()("hipEventCreate", C.byref(h))
        self.handle = h

    def record(self, stream=None):
        lib()("hipEventRecord", self.handle, stream)

    def synchronize(self):
        lib()("hipEventSynchronize", self.handle)

    def elapsed_ms(self, end: "Event") -> float:
        v = C.c_float()
        lib()("hipEventElapsedTime", C.byref(v), self.handle, end.handle)
        return float(v.value)

    def destroy(self):
        if self.handle:
            lib()("hipEventDestroy", self.handle)
            self.handle = None


class Device:
    """One GPU, selected by ordinal (`HIP_VISIBLE_DEVICES` is respected by the runtime)."""

    def __init__(self, ordinal: int = 0):
        lib()("hipInit", 0)
        lib()("hipSetDevice", ordinal)
        self.ordinal = ordinal
        s = C.c_void_p()
        lib()("hipStreamCreate", C.byref(s))
        self.stream = s

    @staticmethod
    def count() -> int:
        lib()("hipInit", 0)
        n = C.c_int()
        lib()("hipGetDeviceCount", C.byref(n))
        return n.value

    def info(self) -> dict:
        name = C.create_string_buffer(256)
        lib()("hipDeviceGetName", name, 256, self.ordinal)
        bus = C.create_string_buffer(64)
        lib()("hipDeviceGetPCIBusId", bus, 64, self.ordinal)
        free, total = C.c_size_t(), C.c_size_t()
        lib()("hipMemGetInfo", C.byref(free), C.byref(total))
        rt, drv = C.c_int(), C.c_int()
        lib()("hipRuntimeGetVersion", C.byref(rt))
        lib()("hipDriverGetVersion", C.byref(drv))
        return {"ordinal": self.ordinal, "name": name.value.decode(), "pci_bus_id": bus.value.decode(),
                "mem_free": free.value, "mem_total": total.value, "runtime_version": rt.value,
                "driver_version": drv.value}

    # memory
    def alloc(self, nbytes: int) -> Buffer:
        p = C.c_void_p()
        lib()("hipMalloc", C.byref(p), max(int(nbytes), 1))
        return Buffer(p.value, int(nbytes))

    def upload(self, array: np.ndarray) -> Buffer:
        a = np.ascontiguousarray(array)
        buf = self.alloc(a.nbytes)
        self.copy_in(buf, a)
        return buf

    def copy_in(self, buf: Buffer, array: np.ndarray):
        a = np.ascontiguousarray(array)
        if a.nbytes:
            lib()("hipMemcpy", C.c_void_p(buf.ptr), a.ctypes.data_as(C.c_void_p), a.nbytes, MEMCPY_H2D)

    def copy(self, dst: Buffer, src: Buffer):
        if src.nbytes:
            lib()("hipMemcpy", C.c_void_p(dst.ptr), C.c_void_p(src.ptr), src.nbytes, MEMCPY_D2D)

    def download(self, buf: Buffer, dtype, shape) -> np.ndarray:
        out = np.empty(shape, dtype=dtype)
        if out.nbytes:
            lib()("hipMemcpy", out.ctypes.data_as(C.c_void_p), C.c_void_p(buf.ptr), out.nbytes, MEMCPY_D2H)
        return out

    def memset(self, buf: Buffer, byte: int, nbytes: int | None = None, stream=None):
        lib()("hipMemsetAsync", C.c_void_p(buf.ptr), int(byte), buf.nbytes if nbytes is None else nbytes,
              self.stream if stream is None else stream)

    def synchronize(self):
        lib()("hipStreamSynchronize", self.stream)
        lib()("hipDeviceSynchronize")

    def load(self, image: bytes) -> Module:
        return Module(image)
