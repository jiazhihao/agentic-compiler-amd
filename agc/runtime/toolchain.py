"""The ROCm toolchain: amdclang builds of HIP (the reference executable and its assembly),
assembly → code object (`llvm-mc` via `clang -x assembler`, then `ld.lld`), and inspection
(`llvm-readelf --notes` metadata, `llvm-objcopy` sections, `llvm-objdump` disassembly).

Builds are cached on disk keyed by the inputs and the toolchain identity.
"""
from __future__ import annotations

import functools
import hashlib
import json
import os
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

import yaml

ROCM = Path(os.environ.get("ROCM_PATH", "/opt/rocm"))
LLVM = ROCM / "llvm" / "bin"
TARGET_TRIPLE = "amdgcn-amd-amdhsa"
DEFAULT_MCPU = "gfx950"


class ToolchainError(RuntimeError):
    def __init__(self, what: str, cmd: list[str], output: str):
        super().__init__(f"{what} failed:\n{output.strip()[-4000:]}")
        self.what, self.cmd, self.output = what, cmd, output


def tool(name: str) -> str:
    p = LLVM / name
    if not p.exists():
        raise ToolchainError("locate", [name], f"{p} not found (set ROCM_PATH)")
    return str(p)


def _run(what: str, cmd: list[str], cwd: str | None = None) -> str:
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise ToolchainError(what, cmd, r.stdout + r.stderr)
    return r.stdout


@functools.cache
def identity() -> dict:
    """Versions of every tool whose output agc depends on; part of every cache key."""
    clang = _run("clang --version", [tool("clang"), "--version"]).splitlines()[0]
    hip = ""
    for cand in (ROCM / ".info" / "version", ROCM / "include" / "hip" / "hip_version.h"):
        try:
            text = cand.read_text()
        except OSError:
            continue
        m = re.search(r'HIP_VERSION_MAJOR\s+(\d+).*?HIP_VERSION_MINOR\s+(\d+).*?HIP_VERSION_PATCH\s+(\d+)', text, re.S)
        hip = ".".join(m.groups()) if m else text.strip()
        if hip:
            break
    return {"clang": clang, "rocm": hip}


def identity_hash() -> str:
    return hashlib.sha256(json.dumps(identity(), sort_keys=True).encode()).hexdigest()[:16]


def cache_dir() -> Path:
    d = Path(os.environ.get("AGC_CACHE", Path.home() / ".cache" / "agc")) / "build"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _key(*parts) -> str:
    h = hashlib.sha256()
    for p in parts:
        h.update(p if isinstance(p, bytes) else json.dumps(p, sort_keys=True).encode())
        h.update(b"\0")
    h.update(identity_hash().encode())
    return h.hexdigest()[:32]


@dataclass
class HipBuild:
    """amdclang's build of a HIP source: the code object and the assembly it was emitted from."""
    hsaco: bytes
    asm: str
    flags: list[str]
    key: str


HIP_FLAGS = ["-O3"]
_INCLUDE = re.compile(r'^\s*#\s*include\s*"([^"]+)"', re.M)


def _local_includes(path: Path, include_dirs=(), seen: dict | None = None) -> dict[str, str]:
    """Contents of the quoted includes of `path`, recursively: part of the build's cache key."""
    seen = {} if seen is None else seen
    for name in _INCLUDE.findall(path.read_text()):
        for d in (path.parent, *map(Path, include_dirs)):
            f = (d / name).resolve()
            if f.exists() and str(f) not in seen:
                seen[str(f)] = f.read_text()
                _local_includes(f, include_dirs, seen)
                break
    return seen


def hip_key(source: str | Path, flags: list[str] | None = None, mcpu: str = DEFAULT_MCPU, include_dirs=()) -> str:
    """The identity of a HIP build: the source text, the contents of its quoted includes (recursively),
    the flags, the target and the toolchain."""
    path = Path(source)
    flags = list(HIP_FLAGS if flags is None else flags)
    incs = [f"-I{Path(d).resolve()}" for d in (path.resolve().parent, *include_dirs)]
    return _key("hip", path.read_text(), flags, mcpu, incs, _local_includes(path, include_dirs))


def hip_build(source: str | Path, flags: list[str] | None = None, mcpu: str = DEFAULT_MCPU,
              include_dirs: list[str | Path] = ()) -> HipBuild:
    """Compile a HIP translation unit for the device only (`.hsaco` and `-S` assembly)."""
    path = Path(source)
    text = path.read_text()
    flags = list(HIP_FLAGS if flags is None else flags)
    incs = [f"-I{Path(d).resolve()}" for d in (path.resolve().parent, *include_dirs)]
    key = hip_key(path, flags, mcpu, include_dirs)
    incs = [f"-I{Path(d).resolve()}" for d in (path.resolve().parent, *include_dirs)]
    d = cache_dir() / key
    if (d / "out.s").exists() and (d / "out.hsaco").exists():
        return HipBuild((d / "out.hsaco").read_bytes(), (d / "out.s").read_text(), flags, key)
    d.mkdir(parents=True, exist_ok=True)
    # The source is published under a stable path (amdclang derives a symbol from the path, so the
    # path is part of what makes a build reproducible); the outputs are written in a directory of
    # this process's own and published atomically, so concurrent builds of the same source (xdist
    # workers, several sessions) never share a half-written file. The assembly is published last:
    # its presence means the build is complete.
    src = d / "in.hip"
    with tempfile.TemporaryDirectory(dir=d, prefix="build-") as t:
        if not src.exists():
            (Path(t) / "in.hip").write_text(text)
            os.replace(Path(t) / "in.hip", src)
        # -cuid: clang otherwise hashes the command line (including the output path) into the
        # compilation-unit symbol, which would make two builds of one source differ
        base = [tool("clang"), "-x", "hip", f"--offload-arch={mcpu}", "--cuda-device-only",
                "--no-gpu-bundle-output", f"-cuid={key[:16]}", *incs, *flags]
        _run("amdclang (code object)", [*base, "-c", str(src), "-o", str(Path(t) / "out.hsaco")])
        _run("amdclang (assembly)", [*base, "-S", str(src), "-o", str(Path(t) / "out.s")])
        hsaco, asm = (Path(t) / "out.hsaco").read_bytes(), (Path(t) / "out.s").read_text()
        os.replace(Path(t) / "out.hsaco", d / "out.hsaco")
        os.replace(Path(t) / "out.s", d / "out.s")
    return HipBuild(hsaco, asm, flags, key)


def assemble(asm: str, mcpu: str = DEFAULT_MCPU) -> bytes:
    """Assembly text → linked code object. The assembler only encodes: instruction order and
    registers are exactly those of the text."""
    key = _key("asm", asm, mcpu)
    out = cache_dir() / key / "asm.hsaco"
    if out.exists():
        return out.read_bytes()
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=out.parent) as t:
        s, o, h = Path(t) / "k.s", Path(t) / "k.o", Path(t) / "k.hsaco"
        s.write_text(asm)
        _run("assemble", [tool("clang"), "-target", TARGET_TRIPLE, f"-mcpu={mcpu}", "-c", "-x", "assembler",
                          str(s), "-o", str(o)])
        _run("link", [tool("ld.lld"), "-shared", str(o), "-o", str(h)])
        os.replace(h, out)
    return out.read_bytes()


def _with_file(data: bytes, fn):
    with tempfile.NamedTemporaryFile(suffix=".hsaco", dir=cache_dir()) as f:
        f.write(data)
        f.flush()
        return fn(f.name)


def metadata(hsaco: bytes) -> dict:
    """The code object's `amdhsa.*` metadata note as a dict."""
    out = _with_file(hsaco, lambda p: _run("readelf --notes", [tool("llvm-readelf"), "--notes", p]))
    m = re.search(r"AMDGPU Metadata:\s*\n(.*?)\n\s*\.\.\.", out, re.S)
    if not m:
        raise ToolchainError("metadata", [], "no AMDGPU metadata note in code object")
    lines = m.group(1).splitlines()
    indent = min((len(l) - len(l.lstrip()) for l in lines if l.strip() and l.strip() != "---"), default=0)
    body = "\n".join(l[indent:] if l.strip() != "---" else "---" for l in lines)
    return yaml.safe_load(body)


def kernel_metadata(hsaco: bytes, name: str) -> dict:
    for k in metadata(hsaco).get("amdhsa.kernels", []):
        if k.get(".name") == name:
            return k
    raise ToolchainError("metadata", [], f"kernel {name!r} not in code object")


def section(hsaco: bytes, name: str = ".text") -> bytes:
    def go(p):
        with tempfile.NamedTemporaryFile(dir=cache_dir()) as o:
            _run("objcopy", [tool("llvm-objcopy"), "-O", "binary", f"--only-section={name}", p, o.name])
            return Path(o.name).read_bytes()
    return _with_file(hsaco, go)


def disassemble(hsaco: bytes, mcpu: str = DEFAULT_MCPU) -> str:
    return _with_file(hsaco, lambda p: _run("objdump", [tool("llvm-objdump"), "-d", f"--mcpu={mcpu}",
                                                        "--no-show-raw-insn", p]))


def symbols(hsaco: bytes) -> list[dict]:
    """ELF symbols: name, value, size, type."""
    out = _with_file(hsaco, lambda p: _run("readelf -s", [tool("llvm-readelf"), "-s", "-W", p]))
    rows = []
    for line in out.splitlines():
        f = line.split()
        if len(f) >= 8 and f[0].rstrip(":").isdigit():
            rows.append({"value": int(f[1], 16), "size": int(f[2]), "type": f[3], "name": f[7]})
    return rows
