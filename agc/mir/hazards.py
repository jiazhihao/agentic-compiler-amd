"""The hazard checker: data hazards that the hardware does not interlock on gfx950 and that
need wait states (`s_nop`, or any other instructions) between a producer and a consumer.

The rules follow LLVM's GCNHazardRecognizer for gfx950; every number lives in
`agc/arch/gfx950.yaml` (`hazards`, `mfma`). An instruction is one wait state and `s_nop N` is
N + 1. The distance from a producer is the minimum over all control-flow paths.
"""
from __future__ import annotations

import re

from ..arch.model import Arch, load as load_arch
from .analysis import Cfg, Info, cfg, units
from .ir import Kernel

_LANE = ("v_readlane_b32", "v_readfirstlane_b32", "v_writelane_b32")
_WIDE_STORE = re.compile(r"(global|flat|scratch)_store_dwordx[34]$")
# instruction families whose hazards are not modelled: using one is itself a finding
UNMODELLED = re.compile(r"v_permlane|s_setreg|s_getreg|s_rfe|v_movrel|s_movrel|ds_(read|write)_addtid")


class Rules:
    def __init__(self, arch: Arch):
        self.arch = arch
        self.h = {k: v.value for k, v in arch.section("hazards").items()}
        m = arch.data["mfma"]
        self.passes = [(re.compile(p), n) for p, n in m["passes"]["value"]]
        self.fp8 = m["scale_fp8_passes"]["value"]
        self.sgemm, self.dgemm = re.compile(m["sgemm_pattern"]["value"]), re.compile(m["dgemm_pattern"]["value"])
        self.m = {k: v["value"] for k, v in m.items() if isinstance(v, dict) and "value" in v}
        self.d = {k: v["value"] for k, v in m["dgemm"].items()}
        self.window = self.h["window"]

    def mfma(self, info: Info) -> tuple[int, str]:
        """(passes, kind) with kind in xdl | sgemm | dgemm."""
        name = info.name
        n = next(n for p, n in self.passes if p.match(name))
        if "f8f6f4" in name:
            if int(info.inst.mod("cbsz", "0"), 0) <= 1 or int(info.inst.mod("blgp", "0"), 0) <= 1:
                n = next(v for k, v in self.fp8.items() if k in name)
        kind = "dgemm" if self.dgemm.match(name) else "sgemm" if self.sgemm.match(name) else "xdl"
        return n, kind

    def scaled(self, key: str, passes: int) -> int:
        base, extra = self.m[key]
        return passes + base + (extra if passes != 2 else 0)


def _back(g: Cfg, b: int, i: int, limit: int):
    """(producer, wait states between it and the consumer at (b, i)) for every instruction that
    can execute fewer than `limit` wait states before the consumer."""
    stack, best = [(b, i - 1, 0)], {}
    while stack:
        blk, j, dist = stack.pop()
        while j >= 0 and dist < limit:
            info = g.infos[blk][j]
            yield info, dist
            dist += info.wait_states
            j -= 1
        if j < 0 and dist < limit:
            for p in g.pred[blk]:
                if best.get(p, limit) > dist:
                    best[p] = dist
                    stack.append((p, len(g.infos[p]) - 1, dist))


def _reg_units(pairs, classes=("v", "a", "s")) -> set:
    return {u for _, r in pairs for u in units(r) if u[0] in classes}


def _requirements(c: Info, p: Info, R: Rules):
    """(rule, wait states required between producer `p` and consumer `c`)."""
    h = R.h
    p_valu = p.valu and not p.lds_dma
    c_use = _reg_units(c.explicit_uses)
    c_def = _reg_units(c.explicit_defs)
    c_sgpr = {u for u in c_use if u[0] == "s"}
    vcc, exec_, m0 = ("vcc", 0), ("exec", 0), ("m0", 0)

    if c.vmem and p_valu and p.defs & (c_sgpr | ({m0} & c.uses)):
        yield "vmem_reads_sgpr_after_valu_write", h["vmem_reads_sgpr_after_valu_write"]
    if c.valu:
        if not c.trans and p.trans and _reg_units(p.explicit_defs) & c_use:
            yield "valu_reads_trans_result", h["valu_reads_trans_result"]
        if ((p.sdwa and p.inst.mod("dst_sel", "DWORD") != "DWORD") or p.name.startswith("v_cvt_scalef32")) \
                and _reg_units(p.explicit_defs) & (c_use | c_def):
            yield "valu_reads_dst_sel_result", h["valu_reads_dst_sel_result"]
        if p_valu and p.defs & (c_sgpr | ({vcc} & c.uses)):
            yield "valu_reads_sgpr_after_valu_write", h["valu_reads_sgpr_after_valu_write"]
        if c.name in _LANE:
            if c.name != "v_writelane_b32" and p_valu and p.defs & {u for f, r in c.explicit_uses if f == "SRC0" for u in units(r)}:
                yield "readlane_src_after_valu_write", h["readlane_src_after_valu_write"]
            if p_valu and exec_ in p.defs:
                yield "rwlane_after_valu_exec_write", h["rwlane_after_valu_exec_write"]
            if p_valu and p.defs & {u for f, r in c.explicit_uses if f == "SRC1" for u in units(r) if u[0] == "s"}:
                yield "rwlane_select_after_valu_write", h["rwlane_select_after_valu_write"]
        if p.vmem and p.store and _WIDE_STORE.match(p.name) and \
                {u for f, r in p.explicit_uses if f == "DATA" for u in units(r)} & c_def:
            yield "valu_overwrites_wide_store_data", h["valu_overwrites_wide_store_data"]
        if c.name.startswith("v_div_fmas") and p_valu and vcc in p.defs:
            yield "div_fmas_after_valu_vcc_write", h["div_fmas_after_valu_vcc_write"]
    if c.dpp:
        if p.defs & {u for u in c_use if u[0] == "v"}:
            yield "dpp_reads_vgpr_after_write", h["dpp_reads_vgpr_after_write"]
        if p_valu and exec_ in p.defs:
            yield "dpp_after_valu_exec_write", h["dpp_after_valu_exec_write"]
    if c.lds_dma and p.salu and m0 in p.defs:
        yield "lds_dma_after_salu_m0_write", h["lds_dma_after_salu_m0_write"]

    p_dst = _reg_units(p.explicit_defs, ("v", "a")) if (p.mfma or p.dot) else set()
    if c.mfma:
        if p_valu and not p.mfma and exec_ in p.defs:
            yield "mfma_after_valu_exec_write", h["mfma_after_valu_exec_write"]
        if p_valu and not p.mfma and not p.dot and p.defs & c_use:
            yield "mfma_reads_vgpr_after_valu_write", h["mfma_reads_vgpr_after_valu_write"]
        if p.mfma:
            cp, ck = R.mfma(c)
            pp, pk = R.mfma(p)
            p_reg = p.explicit_defs[0][1].plain()
            for fld, reg in c.explicit_uses:
                if not set(units(reg)) & p_dst:
                    continue
                if fld == "SRC2":
                    def overlapped():
                        if ck == "xdl" and pk != "xdl":
                            return 0
                        if pk == "dgemm":
                            return R.d["result_read_as_c"][pp]
                        if pk == "sgemm":
                            return R.scaled("sgemm_result_read_as_c", pp) if False else pp
                        return R.scaled("xdl_result_read_as_c_by_xdl" if ck == "xdl" else "xdl_result_read_as_c_by_other", pp)
                    if reg.plain() == p_reg:                       # the accumulator chain
                        need = R.m["same_accumulator_2pass"] if pp == 2 else 0
                        if c.name == "v_mfma_f64_4x4x4_4b_f64" and p.name == c.name:
                            need = R.d["result_read_as_c"][4]
                        if p.name != c.name:
                            need = max(need, overlapped())
                    else:
                        need = overlapped()
                    yield "mfma_result_read_as_c", need
                else:
                    need = (R.d["result_read_as_ab"][pp] if pk == "dgemm" else
                            R.scaled("xdl_result_read_as_ab" if pk == "xdl" else "sgemm_result_read_as_ab", pp))
                    yield "mfma_result_read_as_ab", need
    elif (c.valu and not c.lds_dma) or c.vmem or c.ds:
        is_mem = c.vmem or c.ds
        if p.mfma:
            pp, pk = R.mfma(p)
            if p_dst & c_use:
                need = (R.d["result_read_by_mem" if is_mem else "result_read_by_valu"][pp] if pk == "dgemm" else
                        R.scaled("xdl_result_read_by_valu_or_mem" if pk == "xdl" else "sgemm_result_read_by_valu_or_mem", pp))
                yield "mfma_result_read", need
            if p_dst & c_def:
                need = (R.d["result_overwritten"][pp] if pk == "dgemm" else
                        R.scaled("xdl_result_overwritten" if pk == "xdl" else "sgemm_result_overwritten", pp))
                yield "mfma_result_overwritten", need
            if pk == "xdl" and {u for f, r in p.explicit_uses if f == "SRC2" for u in units(r)} & c_def:
                yield "mfma_src_c_overwritten", R.m["xdl_src_c_overwritten"][pp]
            if pk == "dgemm" and re.match(r"v_fmac?_f64", c.name):
                yield "fma_f64_after_dgemm", h["fma_f64_after_dgemm"]
        if p.dot:
            if p_dst & c_use and not (p.name == c.name and not
                                      {u for f, r in c.explicit_uses if f != "SRC2" for u in units(r)} & p_dst):
                yield "dot_result_read", h["dot_result_read"]
            if p_dst & c_def and p.name != c.name:
                yield "dot_result_overwrite", h["dot_result_overwrite"]


def check(k: Kernel, g: Cfg | None = None, arch: Arch | None = None) -> list[dict]:
    arch = arch or load_arch()
    g = g or cfg(k, arch=arch)
    R = Rules(arch)
    findings = []
    for b, block in enumerate(g.infos):
        for i, c in enumerate(block):
            if c.ins is None:
                continue
            where = {"kernel": k.name, "block": k.blocks[b].label, "index": i, "inst": str(c.inst)}
            if UNMODELLED.match(c.name):
                findings.append({"kind": "hazard", "rule": "unmodelled", **where,
                                 "message": f"the hazards of {c.name} are not modelled; it cannot be checked"})
                continue
            if not (c.valu or c.vmem or c.ds):
                continue
            worst: dict[str, tuple[int, Info, int]] = {}
            for p, dist in _back(g, b, i, R.window):
                if p.ins is None:
                    continue
                for rule, need in _requirements(c, p, R):
                    if need - dist > worst.get(rule, (0, None, 0))[0]:
                        worst[rule] = (need - dist, p, need)
            for rule, (deficit, p, need) in sorted(worst.items()):
                findings.append({"kind": "hazard", "rule": rule, **where, "producer": str(p.inst), "needs": deficit,
                                 "message": f"{rule}: {need} wait state(s) required after `{p.inst}`, "
                                            f"{need - deficit} present; insert `s_nop {deficit - 1}`"})
    return findings
