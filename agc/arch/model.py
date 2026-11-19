"""The architecture model: `gfx950.yaml` loaded into an `Arch`, plus the occupancy calculator.

Every architecture fact used by the compiler comes from the YAML file; each value keeps the
source it was taken from (`isa-doc`, `rocminfo`, `llvm`, `measured`).
"""
from __future__ import annotations

import functools
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

_DIR = Path(__file__).parent


def _align(x: int, a: int) -> int:
    return -(-x // a) * a


@dataclass(frozen=True)
class Value:
    value: Any
    source: str


class Arch:
    def __init__(self, data: dict):
        self.data = data
        self.name: str = data["name"]
        self.target: str = data["target"]

    def section(self, name: str) -> dict[str, Value]:
        return {k: Value(v["value"], v["source"]) for k, v in self.data.get(name, {}).items()}

    def __getitem__(self, key: str) -> Any:
        """`arch["resources.lds_per_workgroup"]` -> the value."""
        sec, _, leaf = key.partition(".")
        node = self.data[sec]
        for part in leaf.split("."):
            node = node[part]
        return node["value"] if isinstance(node, dict) and "value" in node else node

    def res(self, key: str) -> Any:
        return self["resources." + key]

    # ---- register budgets ----------------------------------------------------
    def vgpr_alloc(self, arch_vgprs: int, agprs: int) -> int:
        """Registers allocated per lane for a wave using `arch_vgprs` ArchVGPRs and `agprs` AccVGPRs
        (gfx90a+ unified file: AGPRs start at accum_offset = align(arch_vgprs, 4))."""
        g = self.res("vgpr_granule")
        if agprs == 0:
            return _align(max(arch_vgprs, 1), g)
        return _align(self.accum_offset(arch_vgprs) + agprs, g)

    def accum_offset(self, arch_vgprs: int) -> int:
        return max(_align(max(arch_vgprs, 1), self.res("accum_offset_granule")), self.res("accum_offset_granule"))

    def waves_per_simd_vgpr(self, arch_vgprs: int, agprs: int) -> int:
        return min(self.res("max_waves_per_simd"), self.res("vgprs_per_simd") // self.vgpr_alloc(arch_vgprs, agprs))

    def waves_per_simd_sgpr(self, sgprs: int) -> int:
        # AMDGPUBaseInfo::getOccupancyWithNumSGPRs for gfx8+ (TotalNumSgprs including vcc etc.)
        for limit, waves in ((80, 10), (88, 9), (100, 8), (112, 7), (128, 6), (144, 5), (176, 4), (232, 3)):
            if sgprs <= limit:
                return min(waves, self.res("max_waves_per_simd"))
        return 2

    def occupancy(self, *, arch_vgprs: int, agprs: int = 0, sgprs: int = 0, lds_bytes: int = 0,
                  workgroup_size: int = 256) -> dict:
        """Resident waves per SIMD and the limiting resource."""
        wave = self.res("wave_size")
        simds = self.res("simds_per_cu")
        waves_per_wg = -(-workgroup_size // wave)
        limits = {"hardware": self.res("max_waves_per_simd"),
                  "vgpr": self.waves_per_simd_vgpr(arch_vgprs, agprs),
                  "sgpr": self.waves_per_simd_sgpr(sgprs)}
        if lds_bytes:
            wgs = self.res("lds_per_cu") // _align(lds_bytes, self.res("lds_granule"))
            limits["lds"] = (wgs * waves_per_wg) // simds
        # whole workgroups must fit on a CU
        per_cu_waves = min(limits.values()) * simds
        wgs_per_cu = per_cu_waves // waves_per_wg
        limits["workgroup"] = max(0, (wgs_per_cu * waves_per_wg) // simds) if waves_per_wg <= per_cu_waves else 0
        waves = min(limits.values())
        limiter = min(limits, key=lambda k: (limits[k], k != "hardware"))
        return {"waves_per_simd": waves, "limiter": limiter, "limits": limits,
                "vgpr_alloc": self.vgpr_alloc(arch_vgprs, agprs)}


@functools.cache
def load(name: str = "gfx950") -> Arch:
    path = _DIR / f"{name}.yaml"
    if not path.exists():
        raise ValueError(f"no architecture data for {name!r} (expected {path})")
    return Arch(yaml.safe_load(path.read_text()))
