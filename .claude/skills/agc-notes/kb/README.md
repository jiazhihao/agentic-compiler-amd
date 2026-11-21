# Knowledge base

One file per kernel, written from the agent sessions' reports (`report(kb=[...])`): each entry is one optimization
with its verdict (pays, parity, loses), the ISA pattern or kernel property that makes it applicable, how to apply it,
and what it measured. Entries of kernels without a gain are as useful as the wins: they say what has already been
measured at parity on a kernel of that kind. The harness-verified numbers are in `scripts/sessions.py table`;
the per-kernel ISA-level analyses are in `docs/kernels/`.
