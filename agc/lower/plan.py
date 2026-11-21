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
                            "of up to 4 (default, `global_load_dwordx4`), 2, or 1 (no merging) elements per lane; a merged "
                            "load puts all of its data in flight under one wait"},
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
