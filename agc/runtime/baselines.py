"""Vendor-library baselines, measured through the executor like everything else.

hipBLASLt GEMM: `native/hipblaslt_bench.cpp`, compiled once per toolchain into the build cache.
"""
from __future__ import annotations

import hashlib
import subprocess
from pathlib import Path

from . import toolchain
from .executor import default_root, run_job

_SRC = Path(__file__).parent / "native" / "hipblaslt_bench.cpp"


def hipblaslt_available() -> bool:
    return (toolchain.ROCM / "lib" / "libhipblaslt.so").exists() and (toolchain.ROCM / "include" / "hipblaslt" / "hipblaslt.h").exists()


def hipblaslt_bench_binary() -> Path:
    key = hashlib.sha256(_SRC.read_bytes() + toolchain.identity_hash().encode()).hexdigest()[:16]
    out = toolchain.cache_dir() / f"hipblaslt_bench-{key}"
    if not out.exists():
        tmp = out.with_suffix(".tmp")
        r = subprocess.run([toolchain.tool("clang++"), "-O2", "-std=c++17", "-D__HIP_PLATFORM_AMD__", str(_SRC), "-o", str(tmp),
                            f"-I{toolchain.ROCM / 'include'}", f"-L{toolchain.ROCM / 'lib'}", "-lhipblaslt", "-lamdhip64",
                            f"-Wl,-rpath,{toolchain.ROCM / 'lib'}"], capture_output=True, text=True)
        if r.returncode != 0:
            raise toolchain.ToolchainError("hipblaslt_bench build", [], r.stdout + r.stderr)
        tmp.replace(out)
    return out


def hipblaslt_gemm(M: int, N: int, K: int, in_dtype: str = "bf16", out_dtype: str = "f32", samples: int = 60,
                   flush: bool = True, **run) -> dict:
    """Median time of hipBLASLt on C[M,N] = A[M,K] @ B[N,K]^T; {"ok": False, "error"} when the library has
    no solution for the type combination."""
    job = {"kind": "external", "argv": [str(hipblaslt_bench_binary()), M, N, K, in_dtype, out_dtype, samples, int(flush)]}
    return run_job(job, root=run.pop("root", None) or default_root(), **run)
