import importlib.util
import sys
from pathlib import Path

import pytest

from agc.runtime import executor, toolchain

KERNELS = Path(__file__).parent / "kernels"

HAS_TOOLCHAIN = (toolchain.LLVM / "clang").exists()
HAS_GPU = HAS_TOOLCHAIN and executor.device_count() > 0

# availability controls skipping; the marker makes the CPU-only selection independent of hardware
gpu = [pytest.mark.gpu, pytest.mark.skipif(not HAS_GPU, reason="needs an AMD gfx950 GPU and ROCm")]
needs_toolchain = pytest.mark.skipif(not HAS_TOOLCHAIN, reason="needs the ROCm LLVM toolchain")


@pytest.fixture
def agc_root(tmp_path, monkeypatch):
    """A private session root (hidden-seed secret, GPU account) and build cache."""
    monkeypatch.setenv("AGC_ROOT", str(tmp_path / "root"))
    return tmp_path / "root"


def _load_script(name: str):
    path = Path(__file__).parent.parent / "scripts" / f"{name}.py"
    spec = importlib.util.spec_from_file_location(f"scripts_{name}", path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)


_load_script("gen_isa")
