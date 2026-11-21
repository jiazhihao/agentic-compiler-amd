"""Lowering as recorded decisions (design D14, D15).

A lowering rule asks the plan what to do at a site: `plan.choose(site, decision, alternatives)`.
The first alternative is the default and reproduces what amdclang does. An override
(`{"if0.branch.skip_empty": "none"}`, or `{"branch.skip_empty": "none"}` for every site) selects
another one. The plan records every decision taken, so a compiled kernel names all of its
decisions, and changing one of them and lowering again is how a session backtracks.
"""
from __future__ import annotations

from dataclasses import dataclass, field

# decision -> where it is taken, what it means, the knowledge-base entry that measured it
DECISIONS: dict[str, dict] = {
    "fp.contract": {"level": "kir", "site": "kernel", "kb": "G1",
                    "doc": "fuse `a * b + c` into one fma (`on`: as amdclang does for HIP, one rounding) or keep the "
                           "multiply and the add (`off`: two roundings, the result of the source as written)"},
    "access.width": {"level": "wir", "site": "load / store", "kb": "A2",
                     "doc": "merge accesses of consecutive 32-bit elements with one base and index into one wide access "
                            "of up to 4 (default, `global_load_dwordx4`), 2, or 1 (no merging) elements per lane, or up to "
                            "16 elements for a scalar load (`s_load_dwordx16`); a merged load puts all of its data in "
                            "flight under one wait"},
    "load.uniform": {"level": "wir", "site": "load", "kb": "A3",
                     "doc": "a load whose address is the same for every lane of the wave: one `scalar` load into an SGPR "
                            "(amdclang; the value is then a scalar operand), or a per-lane `vector` load"},
    "loop.unroll": {"level": "kir", "site": "loop", "kb": "A1",
                    "doc": "run a counted loop 1 (as written), 2, 4, 8 or 16 iterations per trip, with the original loop for "
                           "the remainder; the operations keep the order of the source, so results are bit-identical"},
    "loop.inflight": {"level": "wir", "site": "loop", "kb": "A1",
                      "doc": "the loads of one trip of a loop: all `first`, ahead of the arithmetic that consumes them, so "
                             "that one wait covers them (amdclang's scheduler also clusters the loads of a block); or "
                             "`as_written`, where the source reads them. With `loop.unroll` the first form puts several "
                             "iterations' loads in flight"},
    "order.loads": {"level": "wir", "site": "kernel", "kb": "F1",
                    "doc": "outside loops: the loads of each straight-line run `first` (amdclang), or `as_written`"},
    "reduce.form": {"level": "kir", "site": "reduce", "kb": "C1",
                    "doc": "a tree reduction over the workgroup through shared memory: `lds_tree` as written (a barrier "
                           "per level), or `dpp`: each wave combines its 64 lanes with DPP and `v_readlane`, the waves "
                           "meet through one LDS slot each and one barrier. The order of combination changes: a "
                           "floating-point sum differs in the last bits (the tolerance is the contract)"},
    "branch.skip_empty": {"level": "mir", "site": "if", "kb": "F3",
                          "doc": "at a `where` region: `branch` over it when no lane of the wave enters (amdclang), "
                                 "or `none`: run it under the empty mask (one branch fewer; costs when the region has "
                                 "memory instructions)"},
}


class PlanError(ValueError):
    def __init__(self, message: str, **values):
        super().__init__(message)
        self.message, self.values = message, values


@dataclass
class Plan:
    overrides: dict = field(default_factory=dict)
    entries: list[dict] = field(default_factory=list)
    used: set = field(default_factory=set)

    def choose(self, site: str, decision: str, alternatives: list, why: str = ""):
        """The alternative to use for `decision` at `site`; the first is the default."""
        if decision not in DECISIONS:
            raise KeyError(f"unregistered decision {decision!r}")
        chosen, by = alternatives[0], "default"
        for key in (f"{site}.{decision}", decision):
            if key in self.overrides:
                v = self.overrides[key]
                if v not in alternatives:
                    raise PlanError(f"{key}: {v!r} is not an alternative here", alternatives=alternatives, site=site)
                chosen, by = v, "override"
                self.used.add(key)
                break
        self.entries.append({"site": site, "decision": decision, "chosen": chosen, "default": alternatives[0],
                             "alternatives": list(alternatives), "by": by, "level": DECISIONS[decision]["level"],
                             **({"why": why} if why else {})})
        return chosen

    def finish(self) -> None:
        """Every override must have matched a decision that was actually taken."""
        unused = sorted(set(self.overrides) - self.used)
        if unused:
            sites = sorted({f"{e['site']}.{e['decision']}" for e in self.entries})
            raise PlanError(f"no such decision in this kernel: {', '.join(unused)}", decisions=sites)

    def to_list(self) -> list[dict]:
        return [dict(e) for e in self.entries]
