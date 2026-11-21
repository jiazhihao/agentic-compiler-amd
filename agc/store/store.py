"""Content-addressed state tree (design §5).

A state's id hashes (level, ir, parent, action), so identical work dedupes. States are immutable;
verification and measurement results are attached to a state id in a separate directory and
never affect the id. Tags name states; branches are named movable heads with a history, so a
harness can fork, checkpoint and roll back. Notes are attached to a state. A file lock serializes
writes, so several sessions can share one store. `record(sid)` is the trace record of a state.
"""
from __future__ import annotations

import contextlib
import difflib
import fcntl
import hashlib
import json
import os
import re
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

TRACE_SCHEMA = "agc-amd-trace-1"
_NAME = re.compile(r"[A-Za-z][\w.\-]{0,63}$")


@dataclass(frozen=True)
class State:
    id: str
    level: str                     # "mir" (physical machine IR); later "tair", "mir-virtual"
    ir: str
    parent: str | None
    action: dict[str, Any]
    meta: dict[str, Any] = field(default_factory=dict)
    created: float = 0.0

    def to_dict(self) -> dict:
        return asdict(self)


def content_id(level: str, ir: str, parent: str | None, action: dict[str, Any]) -> str:
    payload = json.dumps({"level": level, "ir": ir, "parent": parent, "action": action},
                         sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()[:16]


class Store:
    def __init__(self, root: Path):
        self.root = Path(root)
        for d in ("states", "results", "branches", "notes"):
            (self.root / d).mkdir(parents=True, exist_ok=True)

    @contextlib.contextmanager
    def lock(self):
        fd = os.open(self.root / "lock", os.O_RDWR | os.O_CREAT, 0o644)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX)
            yield
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)

    @staticmethod
    def _write(path: Path, data) -> None:
        tmp = path.with_suffix(path.suffix + f".tmp{os.getpid()}")
        tmp.write_text(json.dumps(data, indent=1, default=str))
        os.replace(tmp, path)

    # ---- states ----------------------------------------------------------------
    def put(self, level: str, ir: str, parent: str | None, action: dict, meta: dict | None = None) -> State:
        sid = content_id(level, ir, parent, action)
        path = self.root / "states" / f"{sid}.json"
        with self.lock():
            if path.exists():
                return self.get(sid)
            if parent is not None and not self.exists(parent):
                raise KeyError(f"parent state {parent} does not exist")
            s = State(sid, level, ir, parent, action, dict(meta or {}), time.time())
            self._write(path, s.to_dict())
            return s

    def get(self, sid: str) -> State:
        try:
            return State(**json.loads((self.root / "states" / f"{sid}.json").read_text()))
        except FileNotFoundError:
            raise KeyError(f"no state {sid!r}") from None

    def exists(self, sid: str) -> bool:
        return (self.root / "states" / f"{sid}.json").exists()

    def all_states(self) -> list[State]:
        return sorted((self.get(p.stem) for p in (self.root / "states").glob("*.json")), key=lambda s: s.created)

    def children(self, sid: str) -> list[State]:
        return [s for s in self.all_states() if s.parent == sid]

    def ancestry(self, sid: str) -> list[State]:
        """Root first, `sid` last."""
        chain = []
        cur: str | None = sid
        while cur is not None:
            s = self.get(cur)
            chain.append(s)
            cur = s.parent
        return chain[::-1]

    def diff(self, a: str, b: str) -> str:
        x, y = self.get(a), self.get(b)
        return "".join(difflib.unified_diff(x.ir.splitlines(True), y.ir.splitlines(True), a, b, n=2))

    # ---- results ---------------------------------------------------------------
    def put_result(self, sid: str, kind: str, data: dict) -> None:
        if not self.exists(sid):
            raise KeyError(f"no state {sid!r}")
        d = self.root / "results" / sid
        d.mkdir(parents=True, exist_ok=True)
        with self.lock():
            self._write(d / f"{kind}.json", {"t": time.time(), **data})

    def get_result(self, sid: str, kind: str) -> dict | None:
        p = self.root / "results" / sid / f"{kind}.json"
        return json.loads(p.read_text()) if p.exists() else None

    def result_kinds(self, sid: str) -> list[str]:
        d = self.root / "results" / sid
        return sorted(p.stem for p in d.glob("*.json")) if d.exists() else []

    # ---- tags and branches -----------------------------------------------------
    @staticmethod
    def _check_name(name: str, what: str) -> None:
        if not _NAME.match(name) or re.fullmatch(r"[0-9a-f]{16}", name):
            raise ValueError(f"bad {what} name {name!r}")

    def tags(self) -> dict[str, str]:
        p = self.root / "tags.json"
        return json.loads(p.read_text()) if p.exists() else {}

    def tag(self, name: str, sid: str) -> None:
        self._check_name(name, "tag")
        if not self.exists(sid):
            raise KeyError(f"no state {sid!r}")
        with self.lock():
            t = self.tags()
            t[name] = sid
            self._write(self.root / "tags.json", t)

    def resolve(self, ref: str) -> str:
        """A state id, a unique id prefix (at least 6 characters), a tag or a branch name → the id."""
        if self.exists(ref):
            return ref
        t = self.tags()
        if ref in t:
            return t[ref]
        b = self.root / "branches" / f"{ref}.json"
        if _NAME.match(ref) and b.exists():
            return json.loads(b.read_text())["head"]
        if len(ref) >= 6:
            hits = [p.stem for p in (self.root / "states").glob(f"{ref}*.json")] if re.fullmatch(r"[0-9a-f]+", ref) else []
            if len(hits) == 1:
                return hits[0]
        raise KeyError(f"unknown state, tag or branch {ref!r}")

    def branches(self) -> dict[str, dict]:
        return {p.stem: json.loads(p.read_text()) for p in sorted((self.root / "branches").glob("*.json"))}

    def fork(self, name: str, sid: str, note: str = "") -> dict:
        self._check_name(name, "branch")
        p = self.root / "branches" / f"{name}.json"
        with self.lock():
            if p.exists():
                raise ValueError(f"branch {name!r} exists")
            b = {"name": name, "head": self.resolve(sid), "history": [self.resolve(sid)], "note": note}
            self._write(p, b)
            return b

    def checkpoint(self, name: str, sid: str) -> dict:
        """Move the branch head to `sid` (which must descend from the current head)."""
        p = self.root / "branches" / f"{name}.json"
        with self.lock():
            if not p.exists():
                raise KeyError(f"no branch {name!r}")
            b = json.loads(p.read_text())
            if b["head"] not in [s.id for s in self.ancestry(sid)]:
                raise ValueError(f"{sid} does not descend from the head of {name!r} ({b['head']})")
            if sid != b["head"]:
                b["head"] = sid
                b["history"].append(sid)
                self._write(p, b)
            return b

    def rollback(self, name: str, steps: int = 1) -> dict:
        p = self.root / "branches" / f"{name}.json"
        with self.lock():
            if not p.exists():
                raise KeyError(f"no branch {name!r}")
            b = json.loads(p.read_text())
            if not 0 < steps < len(b["history"]):
                raise ValueError(f"branch {name!r} has {len(b['history']) - 1} checkpoint(s) to roll back")
            b["history"] = b["history"][:-steps]
            b["head"] = b["history"][-1]
            self._write(p, b)
            return b

    # ---- notes and traces ------------------------------------------------------
    def note(self, sid: str, text: str, meta: dict | None = None) -> list:
        if not self.exists(sid):
            raise KeyError(f"no state {sid!r}")
        p = self.root / "notes" / f"{sid}.json"
        with self.lock():
            notes = json.loads(p.read_text()) if p.exists() else []
            notes.append({"t": time.time(), "text": text, **(meta or {})})
            self._write(p, notes)
            return notes

    def notes(self, sid: str) -> list:
        p = self.root / "notes" / f"{sid}.json"
        return json.loads(p.read_text()) if p.exists() else []

    def record(self, sid: str) -> dict:
        """The trace record of a state: its action and what is known about it."""
        s = self.get(sid)
        rec = {"id": s.id, "parent": s.parent, "level": s.level, "action": s.action, "meta": s.meta,
               "created": s.created, "notes": self.notes(sid)}
        st = self.get_result(sid, "static")
        if st:
            rec["static"] = {"ok": st["ok"], "errors": sum(f.get("severity") != "warning" for f in st["findings"]),
                             "warnings": sum(f.get("severity") == "warning" for f in st["findings"])}
        ck = self.get_result(sid, "check")
        if ck:
            rec["check"] = {"ok": ck.get("ok", False), "cases_run": ck.get("cases_run"), "cases_total": ck.get("cases_total")}
        bn = self.get_result(sid, "bench")
        if bn:
            rec["bench"] = {k: bn.get(k) for k in ("ok", "outcome", "speedup", "speedup_ci95", "against", "protocol_version",
                                                   "candidate_ms", "reference_ms")}
        return rec

    def export_trace(self, sid: str) -> dict:
        return {"schema": TRACE_SCHEMA, "final": sid, "steps": [self.record(s.id) for s in self.ancestry(sid)]}
