"""The `wir` verifier: the structured-SSA rules, the typing of every operation, and what `wir` adds:
a `where` region is entered on a lane mask (`v i1`) and the values it merges are per-lane; a `branch` is on a uniform condition (`u i1`); vectors are never merged."""
from __future__ import annotations

from ..kir.ir import Const, Func, If, IRError, Loop
from ..kir.verify import verify as _verify
from . import ops


def verify(w: Func) -> list[dict]:
    found = _verify(w, ops.check)
    for s in w.walk():
        if isinstance(s, Loop):
            for c, nx, o in zip(s.carried, s.next, s.out):
                if c.kind == "u" and ops.kind_of(nx) == "v" or o.kind != c.kind or c.type.is_vec or (c.type.is_bool and c.kind != "v"):
                    found.append({"severity": "error", "where": s.site or "loop", "site": s.site,
                                  "message": f"loop-carried %{c.name}: a uniform value cannot become per-lane, a carried "
                                             "condition is a lane mask, and vectors are not carried"})
            continue
        if not isinstance(s, If):
            continue
        kind = ops.kind_of(s.cond)
        if s.mode not in ("where", "branch"):
            found.append({"severity": "error", "where": s.site or "if", "site": s.site, "message": "a wir region is `where` or `branch`"})
        elif s.mode == "where" and (kind != "v" or any(m.result.kind != "v" for m in s.merges)):
            found.append({"severity": "error", "where": s.site or "where", "site": s.site,
                          "message": "`where` takes a lane mask (v i1) and its merged values are per-lane"})
        elif s.mode == "branch" and (kind != "u" or isinstance(s.cond, Const)):
            found.append({"severity": "error", "where": s.site or "branch", "site": s.site,
                          "message": "`branch` takes a uniform condition (u i1)"})
        if any(m.result.type.is_vec for m in s.merges):
            found.append({"severity": "error", "where": s.site or "if", "site": s.site, "message": "a vector cannot be merged"})
    return found


def assert_ok(w: Func) -> Func:
    found = verify(w)
    if found:
        raise IRError(f"wir {w.name}: {found[0]['where']}: {found[0]['message']}" + (f" (and {len(found) - 1} more)" if len(found) > 1 else ""))
    return w
