"""The HIP frontend: Clang parses, agc lowers the AST to `kir` (design D12)."""
from .clang_ast import FrontendError
from .lower import SUPPORTED, lower_hip

__all__ = ["FrontendError", "SUPPORTED", "lower_hip"]
