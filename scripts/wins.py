#!/usr/bin/env python
"""Replay the kernel bodies found in agent sessions (tests/mir/wins/*.s) under the current timing
protocol and rewrite their traces: static check, full battery, paired bench against amdclang.

    .venv/bin/python scripts/wins.py
"""
from __future__ import annotations

import json
import sys
import tempfile

from agc import corpus
from agc.session import Session

WINS = corpus.CORPUS_DIR.parent / "mir" / "wins"


def main() -> int:
    root = tempfile.mkdtemp(prefix="agc-wins-")
    for body in sorted(WINS.glob("*.s")):
        kernel = next(n for n in sorted(corpus.names(), key=len, reverse=True) if body.name.startswith(n + "_"))
        old = json.loads(body.with_suffix("").with_suffix(".trace.json").read_text()) if body.with_suffix("").with_suffix(".trace.json").exists() else []
        note = old[-1]["action"].get("note", "") if old else ""
        s = Session.open(corpus.CORPUS_DIR / f"{kernel}.json", root)
        e = s.edit_ir("ref", body.read_text(), note=note or f"replay of {body.name}")
        b = s.bench(e["id"])
        for n in (old[-1].get("notes", []) if old else []):
            s.note(e["id"], n["text"])
        trace = s.trace(e["id"])
        (WINS / body.name.replace(".s", ".trace.json")).write_text(json.dumps(trace, indent=1) + "\n")
        print(f"{body.name:28s} {b['outcome']} {b['speedup']} {b['speedup_ci95']}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
