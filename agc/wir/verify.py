"""The `wir` verifier: the structured-SSA rules, the typing of every operation, and what `wir` adds:
a `where` region is entered on a lane mask (`v i1`) and the values it merges are per-lane; a `branch` is on a uniform condition (`u i1`); vectors are never merged."""
from __future__ import annotations

from ..kir.ir import Const, Func, If, IRError, Loop, Op
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


def safety(w: Func) -> list[dict]:
    """Program safety of the schedule's shared memory and barriers (category `safety`):

    - a barrier inside a loop each lane leaves on its own: the waves of the workgroup would reach it a
      different number of times;
    - an LDS load of a slot other than the one the same lane stored, with no barrier since a store to that
      region: the slot may belong to a wave that has not run yet. (Lanes of one wave do run in step, so a
      shuffle inside a wave would be safe; the verifier cannot tell which wave a slot belongs to and asks for
      the barrier.)
    """
    found: list[dict] = []

    def key(x):
        return ("c", int(x.value)) if isinstance(x, Const) else ("v", id(x))

    def go(stmts: list, dirty: dict, masked_loop: bool) -> None:
        for s in stmts:
            if isinstance(s, If):
                a, b = {k: set(v) for k, v in dirty.items()}, {k: set(v) for k, v in dirty.items()}
                go(s.then, a, masked_loop)
                go(s.orelse, b, masked_loop)
                dirty.clear()
                for d in (a, b):
                    for k, v in d.items():
                        dirty.setdefault(k, set()).update(v)
            elif isinstance(s, Loop):
                per_lane = ops.kind_of(s.cond) == "v"
                for _ in range(2):                         # twice: what one trip leaves is what the next one meets
                    go(s.head, dirty, masked_loop or per_lane)
                    go(s.body, dirty, masked_loop or per_lane)
            elif s.name == "barrier":
                if masked_loop:
                    found.append({"severity": "error", "category": "safety", "where": s.site or "barrier", "site": s.site,
                                  "message": "a barrier inside a loop each lane leaves on its own: the waves of the workgroup "
                                             "would reach it a different number of times"})
                dirty.clear()
            elif s.name in ("load", "store") and s.args[0].type.is_lds:
                region = _root(w, s.args[0])
                slot = (key(s.args[1]), s.attrs.get("scale"), s.attrs.get("off"))
                if s.name == "store":
                    dirty.setdefault(region, set()).add(slot)
                elif region in dirty and slot not in dirty[region]:
                    found.append({"severity": "error", "category": "safety", "where": s.site or "load", "site": s.site,
                                  "message": "an LDS load of a slot this lane did not store, with no barrier since a store to "
                                             "the region: another wave may not have written it yet",
                                  "suggestion": "a `barrier` between the stores and this load"})

    go(w.body, {}, False)
    # one finding per statement (a loop body is walked twice)
    seen, out = set(), []
    for f in found:
        k = (f["where"], f["message"])
        if k not in seen:
            seen.add(k)
            out.append(f)
    return out


def _root(w: Func, p) -> int:
    """The region handle a (possibly retyped) LDS pointer comes from."""
    defs = getattr(w, "_defs", None)
    if defs is None:
        defs = {id(s.result): s for s in w.walk() if isinstance(s, Op) and s.result is not None}
        w._defs = defs
    d = defs.get(id(p))
    while d is not None and d.name == "bitcast":
        p = d.args[0]
        d = defs.get(id(p))
    return id(p)


def assert_ok(w: Func) -> Func:
    w.__dict__.pop("_defs", None)
    found = verify(w) + safety(w)
    w.__dict__.pop("_defs", None)
    if found:
        raise IRError(f"wir {w.name}: {found[0]['where']}: {found[0]['message']}" + (f" (and {len(found) - 1} more)" if len(found) > 1 else ""))
    return w
