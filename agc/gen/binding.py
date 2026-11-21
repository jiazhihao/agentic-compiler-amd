"""Binding a tair program to a manifest: which kernel argument is which program value, where the
runtime sizes come from, and the code that loads the arguments."""
from __future__ import annotations

from dataclasses import dataclass, field

from ..manifest import Manifest
from ..mir import abi
from ..mir.ir import Reg
from ..tair.ir import Program
from .builder import Builder, GenError


@dataclass
class Compiled:
    """What a generator produces: the module, how to launch it, and the knobs that made it."""
    module: object
    launch: dict                       # {"grid": [expr...], "block": [ints], "lds": int} over the manifest's symbols
    template: str
    params: dict = field(default_factory=dict)


@dataclass
class Binding:
    manifest: Manifest
    program: Program
    args: list[abi.Arg]
    offsets: dict[str, int]            # manifest parameter -> kernarg offset
    outputs: dict[str, str]            # program output -> manifest tensor
    sizes: dict[str, str]              # shape symbol of the program -> manifest scalar parameter holding it

    def size_param(self, sym) -> str:
        if sym not in self.sizes:
            raise GenError(f"the kernel needs the size {sym!r} at run time, but no integer scalar parameter of the "
                           f"manifest carries it (add one whose value is the shape expression)")
        return self.sizes[sym]

    def itemsize(self, name: str) -> int:
        return self.manifest.param(name).dtype.itemsize


def bind(m: Manifest, p: Program) -> Binding:
    args, offsets, off = [], {}, 0
    for q in m.params:
        a = abi.Arg("global_buffer", 8) if q.kind == "tensor" else abi.Arg("by_value", q.dtype.itemsize)
        off = -(-off // min(a.size, 8)) * min(a.size, 8)
        offsets[q.name] = off
        off += a.size
        args.append(a)
    names = {q.name for q in m.params}
    for q in p.params:
        if q.name not in names:
            raise GenError(f"program parameter {q.name!r} is not a manifest parameter")
        mp = m.param(q.name)
        if (q.shape is None) != (mp.kind == "scalar"):
            raise GenError(f"{q.name}: the program and the manifest disagree on tensor vs scalar")
        if q.shape is not None and len(q.shape) != len(mp.shape):
            raise GenError(f"{q.name}: rank {len(q.shape)} in the program, {len(mp.shape)} in the manifest")
    outs = m.outputs()
    if len(outs) != len(p.outputs):
        raise GenError(f"the program has {len(p.outputs)} output(s), the manifest {len(outs)}")
    outputs = {o.name: mo.name for o, mo in zip(p.outputs, outs)}
    # a shape symbol of the program is the manifest's expression at the same position; the kernel
    # reads its runtime value from the integer scalar parameter whose value is that expression
    sizes = {}
    for q in list(p.params) + list(p.outputs):
        if q.shape is None:
            continue
        mp = m.param(outputs.get(q.name, q.name))
        for sym, mexpr in zip(q.shape, mp.shape):
            if isinstance(sym, int):
                continue
            holder = next((s.name for s in m.params if s.kind == "scalar" and not s.dtype.is_float
                           and str(s.value).strip() == str(mexpr).strip()), None)
            if holder is None:
                continue                      # the kernel cannot read this size at run time (fine if it never needs to)
            if sizes.setdefault(sym, holder) != holder:
                raise GenError(f"program symbol {sym} maps to two different sizes")
    return Binding(m, p, args, offsets, outputs, sizes)


def load_args(b: Builder, bd: Binding, names: list[str]) -> dict[str, Reg]:
    """Load the named kernel arguments from the kernarg segment (`s[0:1]`): a pointer becomes an
    SGPR pair, a scalar one SGPR. Waits are inserted later, at first use."""
    out = {}
    for n in names:
        q = bd.manifest.param(n)
        if q.kind == "tensor":
            r = b.s(2)
            b.emit("s_load_dwordx2", r, "s[0:1]", bd.offsets[n])
        else:
            if q.dtype.itemsize != 4:
                raise GenError(f"scalar {n}: only 32-bit scalars are supported")
            r = b.s()
            b.emit("s_load_dword", r, "s[0:1]", bd.offsets[n])
        out[n] = r
    return out
