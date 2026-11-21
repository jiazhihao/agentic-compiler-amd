"""NumPy interpreter of `kir`: every thread of a launch at once.

    run(func, {"x": array, "y": array, "a": 1.5, "n": 1000}, grid=(4,), block=(256,))

Tensors are modified in place. A value is an array with one element per thread (or a 0-d array
when it is the same for all of them); a region runs under the mask of the threads that entered
it. Threads run in lockstep, so a store is visible to every thread's later loads: the semantics of
a kernel without data races. `eval_op` (shared with the `wir` interpreter) defines each operation.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .ir import Const, Func, If, Loop, Op, Type, Value


class InterpError(RuntimeError):
    pass


def np_dtype(t: Type) -> np.dtype:
    if t.is_bool:
        return np.dtype(np.bool_)
    if t.is_int:
        return np.dtype(f"{'i' if t.signed else 'u'}{t.bits // 8}")
    if t.is_float:
        return np.dtype({"f16": np.float16, "bf16": np.uint16, "f32": np.float32, "f64": np.float64}[t.name])
    raise InterpError(f"no array type for {t}")


@dataclass
class Ptr:
    raw: np.ndarray              # the tensor's bytes (a uint8 view sharing its memory)
    off: np.ndarray              # byte offset, int64, per thread or 0-d
    name: str = ""


def wave_read(x, at, local, size: int, mask):
    """`waveread`: threads are stored a workgroup after another, each in the order of its flat index."""
    n = mask.shape[0]
    t = np.arange(n, dtype=np.int64)
    local = np.broadcast_to(local, mask.shape)
    src = t - local % 64 + ((np.broadcast_to(np.asarray(at), mask.shape).astype(np.int64) >> 2) & 63)
    inside = (src < n) & (src // size == t // size) if size else np.zeros(n, dtype=bool)
    at_src = np.where(inside, src, 0)
    ok = inside & np.broadcast_to(mask, (n,))[at_src]
    x = np.ascontiguousarray(x)
    return np.where(ok, x[at_src], np.zeros((), dtype=x.dtype))


def const(c: Const):
    if c.type.is_ptr:
        return None                                          # the null pointer
    return np.array(c.value, dtype=np_dtype(c.type))


def _cast(x, src: Type, dst: Type):
    dt = np_dtype(dst)
    if dst.is_bool:
        return x != 0
    if src.is_float and dst.is_int:                      # C truncation; out of range saturates, NaN gives 0 (as v_cvt_* does)
        info = np.iinfo(dt)
        y = np.trunc(np.nan_to_num(np.asarray(x, dtype=np.float64), nan=0.0, posinf=float(info.max), neginf=float(info.min)))
        return np.clip(y, float(info.min), float(info.max)).astype(dt) if dst.bits < 64 else \
            np.where(y >= float(info.max), info.max, np.where(y <= float(info.min), info.min, y.astype(dt)))
    return np.asarray(x).astype(dt)


def _bitcast(x, dst: Type):
    dt = np_dtype(dst)
    a = np.ascontiguousarray(x)
    return a.reshape(-1).view(dt).reshape(a.shape) if a.ndim else a.reshape(1).view(dt)[0:1].reshape(())


def _div(a, b, t: Type, rem: bool):
    if t.is_float:
        return a / b
    safe = np.where(b == 0, np.array(1, b.dtype), b)
    q = np.floor_divide(a, safe)
    if t.signed:
        q = q + ((np.remainder(a, safe) != 0) & ((a < 0) != (safe < 0))).astype(q.dtype)
    return (a - q * safe).astype(a.dtype) if rem else q.astype(a.dtype)


def _fma(a, b, c, t: Type):
    if t.bits == 32:                                     # the product of two float32 is exact in float64
        return (a.astype(np.float64) * b.astype(np.float64) + c.astype(np.float64)).astype(np.float32)
    return a * b + c                                     # float64: rounded twice (no exact fma in NumPy)


def eval_op(name: str, args: list, types: list[Type], rtype: Type | None):
    """One pure operation on arrays. `types` are the operand types, `rtype` the result's."""
    t = types[0] if types else None
    with np.errstate(all="ignore"):
        if name in ("add", "sub", "mul"):
            a, b = args
            return {"add": np.add, "sub": np.subtract, "mul": np.multiply}[name](a, b).astype(a.dtype)
        if name in ("div", "rem"):
            return _div(args[0], args[1], t, name == "rem")
        if name in ("and", "or", "xor"):
            f = {"and": np.bitwise_and, "or": np.bitwise_or, "xor": np.bitwise_xor}[name]
            return f(args[0], args[1])
        if name in ("shl", "shr"):
            n = (args[1].astype(np.int64) & (t.bits - 1)).astype(args[0].dtype)
            return (np.left_shift if name == "shl" else np.right_shift)(args[0], n).astype(args[0].dtype)
        if name in ("min", "max"):
            f = (np.fmin if name == "min" else np.fmax) if t.is_float else (np.minimum if name == "min" else np.maximum)
            return f(args[0], args[1])
        if name == "mulhi":
            wide = np.int64 if t.signed else np.uint64
            return ((args[0].astype(wide) * args[1].astype(wide)) >> wide(32)).astype(args[0].dtype)
        if name == "rcp":
            return (np.asarray(1, dtype=args[0].dtype) / args[0]).astype(args[0].dtype)
        if name in ("sqrt", "abs", "rndne", "floor", "trunc", "exp2", "log2", "exp", "tanh", "log"):
            f = {"sqrt": np.sqrt, "abs": np.abs, "rndne": np.rint, "floor": np.floor, "trunc": np.trunc, "exp2": np.exp2,
                 "log2": np.log2, "exp": np.exp, "tanh": np.tanh, "log": np.log}[name]
            return f(args[0]).astype(args[0].dtype)
        if name == "rsqrt":
            return (np.asarray(1, dtype=args[0].dtype) / np.sqrt(args[0])).astype(args[0].dtype)
        if name == "ldexp":
            return np.ldexp(args[0], args[1].astype(np.int32)).astype(args[0].dtype)
        if name == "copysign":
            return np.copysign(args[0], args[1]).astype(args[0].dtype)
        if name == "neg":
            return np.negative(args[0]).astype(args[0].dtype)
        if name == "not":
            return np.logical_not(args[0]) if t.is_bool else np.invert(args[0])
        if name == "fma":
            return _fma(args[0], args[1], args[2], t)
        if name in ("eq", "ne", "lt", "le", "gt", "ge"):
            f = {"eq": np.equal, "ne": np.not_equal, "lt": np.less, "le": np.less_equal, "gt": np.greater, "ge": np.greater_equal}[name]
            return f(args[0], args[1])
        if name == "select":
            return np.where(args[0], args[1], args[2])
        if name == "cast":
            return _cast(args[0], t, rtype)
        if name == "bitcast":
            return _bitcast(args[0], rtype)
    raise InterpError(f"no semantics for operation {name!r}")


class Memory:
    """Loads and stores under a mask, bounds-checked for the threads that execute them."""

    @staticmethod
    def load(p: Ptr, t: Type, mask: np.ndarray, where: str = ""):
        dt = np_dtype(t)
        view = p.raw.view(dt) if p.raw.size % dt.itemsize == 0 else None
        off = np.broadcast_to(p.off, mask.shape)
        act = off[mask]
        if act.size and (view is None or (act % dt.itemsize).any() or act.min() < 0 or act.max() + dt.itemsize > p.raw.size):
            raise InterpError(f"load out of bounds or unaligned in tensor {p.name!r} {where}: byte offsets "
                              f"{int(act.min())}..{int(act.max())}, tensor has {p.raw.size} bytes")
        if view is None or not view.size:
            return np.zeros(mask.shape, dt)
        return view[np.where(mask, off // dt.itemsize, 0)]

    @staticmethod
    def store(p: Ptr, x, t: Type, mask: np.ndarray, where: str = ""):
        dt = np_dtype(t)
        off = np.broadcast_to(p.off, mask.shape)[mask]
        if not off.size:
            return
        if p.raw.size % dt.itemsize or (off % dt.itemsize).any() or off.min() < 0 or off.max() + dt.itemsize > p.raw.size:
            raise InterpError(f"store out of bounds or unaligned in tensor {p.name!r} {where}: byte offsets "
                              f"{int(off.min())}..{int(off.max())}, tensor has {p.raw.size} bytes")
        p.raw.view(dt)[off // dt.itemsize] = np.broadcast_to(np.asarray(x, dtype=dt), mask.shape)[mask]


def thread_ids(grid, block) -> dict[str, np.ndarray]:
    """`tid`, `bid` per thread, in launch order: workgroups in x-fastest order, then local ids x-fastest."""
    g = tuple(grid) + (1,) * (3 - len(grid))
    b = tuple(block) + (1,) * (3 - len(block))
    nb, ng = b[0] * b[1] * b[2], g[0] * g[1] * g[2]
    local = np.arange(nb, dtype=np.uint32)
    group = np.arange(ng, dtype=np.uint32)
    tid = (local % b[0], (local // b[0]) % b[1], local // (b[0] * b[1]))
    bid = (group % g[0], (group // g[0]) % g[1], group // (g[0] * g[1]))
    out = {}
    for i, d in enumerate("xyz"):
        out[f"tid.{d}"] = np.tile(tid[i], ng).astype(np.uint32)
        out[f"bid.{d}"] = np.repeat(bid[i], nb).astype(np.uint32)
        out[f"bdim.{d}"] = np.array(b[i], dtype=np.uint32)
        out[f"gdim.{d}"] = np.array(g[i], dtype=np.uint32)
    out["threads"] = ng * nb
    out["flat_local"] = np.tile(local, ng)
    out["group"] = np.repeat(group, nb)
    return out


def bind_args(f_params: list[Value], args: dict) -> dict:
    """Kernel arguments as interpreter values: tensors become pointers into their memory."""
    env = {}
    for p in f_params:
        if p.name not in args:
            raise InterpError(f"no argument for parameter {p.name!r}")
        a = args[p.name]
        if p.type.is_ptr:
            arr = np.asarray(a)
            if not arr.flags.c_contiguous or not arr.flags.writeable:
                raise InterpError(f"tensor {p.name!r} must be a writeable C-contiguous array")
            env[id(p)] = Ptr(arr.reshape(-1).view(np.uint8), np.array(0, dtype=np.int64), p.name)
        else:
            env[id(p)] = np.array(a, dtype=np_dtype(p.type))
    return env


MAX_ITERATIONS = 1 << 24


class Interp:
    def __init__(self, f: Func, args: dict, grid, block):
        self.f, self.ids = f, thread_ids(grid, block)
        self.n = self.ids["threads"]
        self.env = bind_args(f.params, args)
        self.lds: dict[str, np.ndarray] = {}

    def val(self, x):
        return const(x) if isinstance(x, Const) else self.env[id(x)]

    def op(self, s: Op, mask: np.ndarray):
        n = s.name
        if n in self.ids:
            self.env[id(s.result)] = self.ids[n]
        elif n == "gep":
            p, i = self.val(s.args[0]), self.val(s.args[1])
            self.env[id(s.result)] = Ptr(p.raw, p.off + i.astype(np.int64) * s.args[0].type.elem.size, p.name)
        elif n == "bitcast" and s.result.type.is_ptr:
            self.env[id(s.result)] = self.val(s.args[0])
        elif n in ("eq", "ne") and s.args[0].type.is_ptr:
            # a pointer into a tensor is never null; two pointers are equal when they address the same byte
            a, b = (self.val(x) for x in s.args)
            if isinstance(a, Ptr) and isinstance(b, Ptr):
                same = (a.off == b.off) if a.raw is b.raw else np.zeros(mask.shape, dtype=bool)
            else:
                same = np.array(not isinstance(a, Ptr) and not isinstance(b, Ptr))
            self.env[id(s.result)] = same if n == "eq" else ~np.asarray(same)
        elif n in ("shared", "region"):                      # the workgroup's shared memory: one copy per workgroup
            name, size = s.attrs["name"], s.attrs["bytes"]
            if s.attrs.get("dynamic"):                       # as large as the launch makes the LDS
                size = max(int(getattr(self, "launch_lds", 0)), 4)
            groups = int(self.ids["group"].max()) + 1 if self.n else 1
            if name not in self.lds:
                self.lds[name] = np.full(groups * size, 0xDA, dtype=np.uint8)
            self.env[id(s.result)] = Ptr(self.lds[name], self.ids["group"].astype(np.int64) * size, f"lds:{name}")
        elif n == "local":                                   # one copy per thread
            size = s.attrs["bytes"]
            key = ("local", s.attrs["name"])
            if key not in self.lds:
                self.lds[key] = np.full(self.n * size, 0xDA, dtype=np.uint8)
            self.env[id(s.result)] = Ptr(self.lds[key], np.arange(self.n, dtype=np.int64) * size, f"local:{s.attrs['name']}")
        elif n == "barrier":
            pass                                             # threads run in lockstep here: every statement is a barrier
        elif n == "laneid":
            self.env[id(s.result)] = (self.flat_local() & 63).astype(np_dtype(s.result.type))
        elif n == "waveread":
            self.env[id(s.result)] = wave_read(np.broadcast_to(self.val(s.args[0]), mask.shape), self.val(s.args[1]),
                                               self.flat_local(), self.workgroup_size(), mask)
        elif n == "wgreduce":
            from .idioms import workgroup_reduce
            x = np.broadcast_to(self.val(s.args[0]), mask.shape)
            size = s.attrs["size"]
            if self.n % size or int(self.ids["bdim.x"]) * int(self.ids["bdim.y"]) * int(self.ids["bdim.z"]) != size:
                raise InterpError(f"wgreduce over {size} threads in a workgroup of another size")
            self.env[id(s.result)] = workgroup_reduce(np.ascontiguousarray(x), s.attrs["op"], size)
        elif n == "load":
            self.env[id(s.result)] = Memory.load(self.val(s.args[0]), s.result.type, mask, s.site or "")
        elif n == "store":
            Memory.store(self.val(s.args[0]), self.val(s.args[1]), s.args[1].type, mask, s.site or "")
        else:
            self.env[id(s.result)] = eval_op(n, [self.val(a) for a in s.args], [a.type for a in s.args],
                                             s.result.type if s.result is not None else None)

    def workgroup_size(self) -> int:
        return int(self.ids["bdim.x"]) * int(self.ids["bdim.y"]) * int(self.ids["bdim.z"])

    def flat_local(self):
        """Each thread's flat index in its workgroup."""
        i = self.ids
        return (i["tid.x"].astype(np.int64) + int(i["bdim.x"]) * (i["tid.y"].astype(np.int64) + int(i["bdim.y"]) * i["tid.z"].astype(np.int64)))

    def merge(self, cond, a, b):
        if isinstance(a, Ptr) or isinstance(b, Ptr):
            if a.raw is not b.raw:
                raise InterpError("a merged pointer may point into one tensor only")
            return Ptr(a.raw, np.where(cond, a.off, b.off), a.name)
        return np.where(cond, a, b)

    def body(self, stmts, mask: np.ndarray):
        for s in stmts:
            if isinstance(s, Op):
                self.op(s, mask)
            elif isinstance(s, If):
                c = np.broadcast_to(np.asarray(self.val(s.cond), dtype=bool), mask.shape)
                self.body(s.then, mask & c)
                self.body(s.orelse, mask & ~c)
                for m in s.merges:
                    self.env[id(m.result)] = self.merge(c, self.val(m.a), self.val(m.b))
            else:
                self.loop(s, mask)

    def loop(self, s: Loop, mask: np.ndarray):
        cur = [self.val(i) for i in s.init]
        active = mask
        for _ in range(MAX_ITERATIONS):
            for c, v in zip(s.carried, cur):
                self.env[id(c)] = v
            self.body(s.head, active)
            active = active & np.broadcast_to(np.asarray(self.val(s.cond), dtype=bool), mask.shape)
            if not active.any():
                break
            self.body(s.body, active)
            cur = [self.merge(active, self.val(nx), v) for nx, v in zip(s.next, cur)]
        else:
            raise InterpError(f"loop {s.site or ''} did not end after {MAX_ITERATIONS} iterations")
        for o, v in zip(s.out, cur):
            self.env[id(o)] = v

    def run(self):
        self.body(self.f.body, np.ones(self.n, dtype=bool))


def run(f: Func, args: dict, grid, block, lds: int = 0) -> None:
    it = Interp(f, args, grid, block)
    it.launch_lds = lds
    it.run()
