"""Clang as the parser: the JSON AST of the declarations a kernel needs (design D12).

`amdclang++ -x hip --cuda-device-only -fsyntax-only -Xclang -ast-dump=json -Xclang
-ast-dump-filter=NAME`: semantic analysis only, no LLVM IR, no code generation. The filter keeps
the dump to the declarations named NAME (a whole HIP translation unit with its headers is hundreds
of megabytes); functions the entry calls are fetched by name in further runs. Results are cached
under the same identity as a HIP build.

Clang names AST nodes by their address, and the addresses differ between two runs (even with
address randomization off: the filter string itself moves the heap). A call in one dump is
therefore matched to its callee in another by name and signature, never by id.
"""
from __future__ import annotations

import json
import os
import shutil
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
    key = toolchain._key("ast-paged", toolchain.hip_key(path, flags, mcpu, include_dirs), name)
    cached = toolchain.cache_dir() / f"ast-{key}.json"
    if cached.exists():
        return json.loads(cached.read_text())
    incs = [f"-I{Path(d).resolve()}" for d in (path.resolve().parent, *include_dirs)]
    cmd = [toolchain.tool("clang"), "-x", "hip", f"--offload-arch={mcpu}", "--cuda-device-only", "-fsyntax-only",
           *incs, *flags, "-Xclang", "-ast-dump=json", "-Xclang", "-ast-dump-filter", "-Xclang", name, str(path)]
    # Node ids are addresses, and differ from one run of Clang to the next. With address randomization off and
    # the AST's memory taken from the system a page at a time, the place of a node inside its page is the same in
    # every run over the same source: `page_offset` of an id identifies an instantiation across two dumps.
    env = dict(os.environ, MALLOC_MMAP_THRESHOLD_="4096")
    setarch = shutil.which("setarch")
    p = subprocess.run([setarch, "-R", *cmd] if setarch else cmd, capture_output=True, text=True, env=env)
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


def page_offset(node_id: str) -> int:
    return int(node_id, 16) & 0xFFF


_LAYOUT = None


def layouts(source: str | Path, flags: list[str] | None = None, mcpu: str = toolchain.DEFAULT_MCPU, include_dirs=()) -> dict:
    """Clang's layout of every record the translation unit completes: {type: {"size", "align", "offsets"}}
    in bytes, keyed by the type as Clang prints it without `struct` / `class` (`flashinfer::vec_t<float, 4>`).
    From `-fdump-record-layouts-simple`: the frontend never computes a layout itself."""
    import re
    path = Path(source)
    flags = [f for f in (flags or []) if not f.startswith("-O")]
    key = toolchain._key("layouts", toolchain.hip_key(path, flags, mcpu, include_dirs))
    cached = toolchain.cache_dir() / f"layouts-{key}.json"
    if cached.exists():
        return json.loads(cached.read_text())
    incs = [f"-I{Path(d).resolve()}" for d in (path.resolve().parent, *include_dirs)]
    cmd = [toolchain.tool("clang"), "-x", "hip", f"--offload-arch={mcpu}", "--cuda-device-only", "-fsyntax-only",
           *incs, *flags, "-Xclang", "-fdump-record-layouts-simple", str(path)]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise FrontendError(f"clang rejected {path.name}: {p.stderr.strip()[-1500:]}")
    out = {}
    for m in re.finditer(r"^Type: (?:struct |class |union )?(.+?)\n\nLayout: <ASTRecordLayout\n\s*Size:(\d+)\n\s*DataSize:\d+\n"
                         r"\s*Alignment:(\d+)\n(?:.*\n)*?\s*FieldOffsets: \[([^\]]*)\]", p.stdout, re.M):
        out[m.group(1).strip()] = {"size": int(m.group(2)) // 8, "align": int(m.group(3)) // 8,
                                   "offsets": [int(x) // 8 for x in m.group(4).split(",") if x.strip()]}
    with tempfile.NamedTemporaryFile("w", dir=cached.parent, delete=False, suffix=".tmp") as t:
        json.dump(out, t)
    os.replace(t.name, cached)
    return out
