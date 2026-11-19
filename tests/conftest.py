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
