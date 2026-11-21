"""NumPy interpreter of `wir`: every lane of every wave of a launch.

It shares the operation semantics with the `kir` interpreter, and checks what `wir` adds: a value
declared `u` must be the same in all lanes of a wave that are running. A wave is 64 consecutive
workitems of a workgroup (flat workitem id // 64).
"""
from __future__ import annotations

import numpy as np

from ..kir.interp import Interp as _KirInterp, InterpError, Memory, Ptr, bind_args, const, eval_op, np_dtype, thread_ids
from ..kir.ir import Const, Func, If, Op, Value

WAVE = 64


class Interp(_KirInterp):
    def __init__(self, f: Func, args: dict, grid, block, arg_values: dict[int, object], wave: int = WAVE):
        """`arg_values`: kernarg offset → the argument's value (an array for a tensor)."""
        self.f, self.ids = f, thread_ids(grid, block)
        self.n = self.ids["threads"]
        self.env = {}
        self.arg_values = arg_values
        nb = int(np.prod(tuple(block)))
        self.wave_id = self.ids["group"].astype(np.int64) * ((nb + wave - 1) // wave) + self.ids["flat_local"] // wave
        self.first = np.unique(self.wave_id, return_index=True)[1]          # each wave's first lane
        self.ptrs: dict[int, Ptr] = {}
        self.lds: dict[str, np.ndarray] = {}

    def check_uniform(self, s: Op, x, mask: np.ndarray):
        if isinstance(x, list):                              # a vector: each element
            for e in x:
                self.check_uniform(s, e, mask)
            return
        if isinstance(x, Ptr):
            x = x.off
        x = np.asarray(x)
        if x.ndim == 0 or x.size == 1:
            return
        lead = np.empty(self.first.size, dtype=np.int64)
        # the first running lane of each wave
        idx = np.where(mask, np.arange(self.n), self.n)
        lead = np.minimum.reduceat(idx, self.first)
        ok = lead < self.n
        ref = np.zeros(self.n, dtype=x.dtype)
        per_wave = np.where(ok, lead, 0)
        ref = x[per_wave][np.searchsorted(self.first, np.arange(self.n), side="right") - 1]
        bad = mask & (x != ref) & ~((x != x) & (ref != ref))
        if bad.any():
            i = int(np.argmax(bad))
            raise InterpError(f"%{s.result.name} is declared uniform but differs within a wave "
                              f"(lane {i}: {x[i]!r}, the wave's first running lane: {ref[i]!r})")

    def address(self, s: Op) -> Ptr:
        base, idx = self.val(s.args[0]), self.val(s.args[1])
        return Ptr(base.raw, base.off + idx.astype(np.int64) * s.attrs["scale"] + s.attrs["off"], base.name)

    def op(self, s: Op, mask: np.ndarray):
        n = s.name
        if n == "arg":
            a = self.arg_values[s.attrs["offset"]]
            if s.result.type.is_ptr:
                arr = np.asarray(a)
                self.env[id(s.result)] = Ptr(arr.reshape(-1).view(np.uint8), np.array(0, dtype=np.int64), f"arg@{s.attrs['offset']}")
            else:
                self.env[id(s.result)] = np.array(a, dtype=np_dtype(s.result.type))
        elif n == "hidden":
            f = s.attrs["field"]
            self.env[id(s.result)] = self.ids[("gdim." if f.startswith("block_count") else "bdim.") + f[-1]]
        elif n.startswith("wg."):
            self.env[id(s.result)] = self.ids["bid." + n[-1]]
        elif n in ("lane.x", "lane.y", "lane.z"):
            self.env[id(s.result)] = self.ids["tid." + n[-1]]
        elif n == "ptradd":
            self.env[id(s.result)] = self.address(s)
        elif n == "load" and s.attrs.get("n", 1) > 1:
            p, e = self.address(s), s.result.type.elem
            self.env[id(s.result)] = [Memory.load(Ptr(p.raw, p.off + i * e.size, p.name), e, mask, s.site or "")
                                      for i in range(s.attrs["n"])]
        elif n == "store" and s.attrs.get("n", 1) > 1:
            p, e = self.address(s), s.args[2].type.elem
            for i, x in enumerate(self.val(s.args[2])):
                Memory.store(Ptr(p.raw, p.off + i * e.size, p.name), x, e, mask, s.site or "")
        elif n == "lane.id":
            self.env[id(s.result)] = (self.flat_local() & 63).astype(np_dtype(s.result.type))
        elif n == "lane.read":
            from ..kir.interp import wave_read
            self.env[id(s.result)] = wave_read(np.broadcast_to(self.val(s.args[0]), mask.shape), self.val(s.args[1]),
                                               self.flat_local(), self.workgroup_size(), mask)
        elif n == "lane.reduce":
            from ..kir.idioms import WAVE as W, wave_reduce
            if self.n % W or not mask.all():
                raise InterpError("lane.reduce in a wave that is not whole and running")
            x = np.ascontiguousarray(np.broadcast_to(self.val(s.args[0]), mask.shape))
            self.env[id(s.result)] = np.repeat(wave_reduce(x.reshape(-1, W), s.attrs["op"]), W)
        elif n == "mulw":
            wide = np.int64 if s.args[0].type.signed else np.uint64
            a, b = (self.val(x).astype(wide) for x in s.args)
            with np.errstate(all="ignore"):
                self.env[id(s.result)] = (a * b).astype(np_dtype(s.result.type))
        elif n == "extract":
            self.env[id(s.result)] = self.val(s.args[0])[s.attrs["i"]]
        elif n == "pack":
            self.env[id(s.result)] = [self.val(a) for a in s.args]
        elif n == "load":
            self.env[id(s.result)] = Memory.load(self.address(s), s.result.type, mask, s.site or "")
        elif n == "store":
            Memory.store(self.address(s), self.val(s.args[2]), s.args[2].type, mask, s.site or "")
        else:
            super().op(s, mask)
        if s.result is not None and s.result.kind == "u":
            self.check_uniform(s, self.env[id(s.result)], mask)


def run(f: Func, grid, block, arg_values: dict[int, object], lds: int = 0) -> None:
    it = Interp(f, {}, grid, block, arg_values)
    it.launch_lds = lds
    it.run()
