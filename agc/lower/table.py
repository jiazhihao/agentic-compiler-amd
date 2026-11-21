"""The instruction-selection table of an architecture (`agc/arch/<arch>.isel.yaml`), checked against
the ISA table when loaded."""
from __future__ import annotations

import functools
from pathlib import Path

import yaml

from .. import isa
from ..kir.ir import Type


class Table:
    def __init__(self, data: dict):
        self.data = data
        t = isa.table()
        for section in ("valu", "salu", "memory"):
            for op, forms in data[section].items():
                for key, mn in forms.items():
                    if t.resolve(mn) is None and t.resolve(mn + "_e32") is None:
                        raise ValueError(f"isel table: {section}.{op}.{key}: unknown instruction {mn!r}")
        for name, mn in data["control"].items():
            if t.resolve(mn) is None:
                raise ValueError(f"isel table: control.{name}: unknown instruction {mn!r}")

    @staticmethod
    def keys(t: Type) -> list[str]:
        if t.is_ptr:
            return ["u64", "x64"]
        if t.is_int:
            return [str(t), f"x{t.bits}"]
        return [str(t)]

    def find(self, section: str, op: str, t: Type) -> str | None:
        forms = self.data[section].get(op, {})
        for k in self.keys(t):
            if k in forms:
                return forms[k]
        return None

    def valu(self, op: str, t: Type) -> str | None:
        return self.find("valu", op, t)

    def salu(self, op: str, t: Type) -> str | None:
        return self.find("salu", op, t)

    def cast(self, src: Type, dst: Type) -> str | None:
        return self.data["valu"]["cast"].get(f"{src}>{dst}")

    def control(self, name: str) -> str:
        return self.data["control"][name]

    def limit(self, name: str):
        return self.data["limits"][name]

    @staticmethod
    @functools.lru_cache(maxsize=None)
    def has_e32(mnemonic: str) -> bool:
        """Whether the instruction has a 32-bit VOP form (LLVM then spells the forms `_e32` and `_e64`)."""
        return isa.table().resolve(mnemonic + "_e32") is not None


@functools.lru_cache(maxsize=None)
def load(arch: str = "gfx950") -> Table:
    path = Path(__file__).resolve().parent.parent / "arch" / f"{arch}.isel.yaml"
    return Table(yaml.safe_load(path.read_text()))
