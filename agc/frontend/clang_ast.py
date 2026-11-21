"""Clang as the parser: the JSON AST of the declarations a kernel needs (design D12).

`amdclang++ -x hip --cuda-device-only -fsyntax-only -Xclang -ast-dump=json -Xclang
-ast-dump-filter=NAME`: semantic analysis only, no LLVM IR, no code generation. The filter keeps
the dump to the declarations named NAME (a whole HIP translation unit with its headers is hundreds
of megabytes); functions the entry calls are fetched by name in further runs. Results are cached
under the same identity as a HIP build.
"""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
from pathlib import Path

from ..runtime import toolchain


class FrontendError(ValueError):
    """The source uses something outside the supported subset, or Clang rejected it. `items` lists
    every unsupported construct found, each with its source location."""

    def __init__(self, message: str, items: list[dict] | None = None):
        super().__init__(message)
        self.message, self.items = message, items or []


def dump(source: str | Path, name: str, flags: list[str] | None = None, mcpu: str = toolchain.DEFAULT_MCPU,
         include_dirs=()) -> list[dict]:
    """The top-level declarations whose name matches `name`, as Clang's JSON AST nodes."""
    path = Path(source)
    flags = [f for f in (flags or []) if not f.startswith("-O")]
    key = toolchain._key("ast", toolchain.hip_key(path, flags, mcpu, include_dirs), name)
    cached = toolchain.cache_dir() / f"ast-{key}.json"
    if cached.exists():
        return json.loads(cached.read_text())
    incs = [f"-I{Path(d).resolve()}" for d in (path.resolve().parent, *include_dirs)]
    cmd = [toolchain.tool("clang"), "-x", "hip", f"--offload-arch={mcpu}", "--cuda-device-only", "-fsyntax-only",
           *incs, *flags, "-Xclang", "-ast-dump=json", "-Xclang", "-ast-dump-filter", "-Xclang", name, str(path)]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise FrontendError(f"clang rejected {path.name}: {p.stderr.strip()[-1500:]}")
    out, dec, i, text = [], json.JSONDecoder(), 0, p.stdout
    while True:                                              # the dump is a sequence of JSON objects
        while i < len(text) and text[i].isspace():
            i += 1
        if i >= len(text):
            break
        obj, i = dec.raw_decode(text, i)
        out.append(obj)
    with tempfile.NamedTemporaryFile("w", dir=cached.parent, delete=False, suffix=".tmp") as t:
        json.dump(out, t)
    os.replace(t.name, cached)
    return out
