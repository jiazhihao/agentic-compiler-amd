"""`wir`: one wave's schedule. Values are `u` (uniform over the wave: an SGPR) or `v` (one per lane:
a VGPR); a lane mask is a `v i1`. Regions are `where` (run by the lanes of a mask) and `branch`
(a uniform condition). What a `wir` program does not say, lowering derives: register numbers,
`s_waitcnt`, `s_nop`, address arithmetic, kernarg offsets, the kernel descriptor."""
from .ops import check
from .interp import run
from .verify import assert_ok, verify

__all__ = ["assert_ok", "check", "run", "verify"]
