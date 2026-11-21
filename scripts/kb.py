#!/usr/bin/env python
"""The generated parts of the knowledge base (`.claude/skills/agc-notes/kb/`).

    .venv/bin/python scripts/kb.py            write RECIPES.md and INDEX.md
    .venv/bin/python scripts/kb.py --check    exit 1 if they are not what the records give

RECIPES.md: every verified performance result with the recipe that reproduces it (session recipes, default
policy results, generator templates, GEMM, hand-written corpus wins), from the records under `tests/baselines`
and `bench/llm/sessions`. INDEX.md: every entry of the per-kernel files, by verdict. The curated files
(OPTIMIZATIONS.md, PATTERNS.md) are written by hand and name the recipes here.
"""
from __future__ import annotations

import sys

from agc import kb


def main(argv) -> int:
    if argv[:1] == ["--check"]:
        bad = [n for n, t in kb.generated().items() if not (kb.KB / n).exists() or (kb.KB / n).read_text() != t]
        print("stale: " + ", ".join(bad) if bad else "current")
        return 1 if bad else 0
    for n, lines in kb.write().items():
        print(f"{n}: {lines} lines")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
