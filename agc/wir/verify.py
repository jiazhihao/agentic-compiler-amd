"""The `wir` verifier: the structured-SSA rules, the typing of every operation, and what `wir` adds:
a `where` region is entered on a lane mask (`v i1`) and merges nothing (its values are `select`ed
after it); a `branch` is on a uniform condition (`u i1`); vectors are never merged."""
from __future__ import annotations

from ..kir.ir import Const, Func, If, IRError
from ..kir.verify import verify as _verify
from . import ops


def verify(w: Func) -> list[dict]:
    found = _verify(w, ops.check)
    for s in w.walk():
        if not isinstance(s, If):
            continue
        kind = ops.kind_of(s.cond)
        if s.mode not in ("where", "branch"):
            found.append({"severity": "error", "where": s.site or "if", "site": s.site, "message": "a wir region is `where` or `branch`"})
        elif s.mode == "where" and (kind != "v" or s.merges):
            found.append({"severity": "error", "where": s.site or "where", "site": s.site,
                          "message": "`where` takes a lane mask (v i1) and merges no value"})
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
