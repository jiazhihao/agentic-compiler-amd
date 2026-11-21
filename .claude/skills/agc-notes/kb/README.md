# Knowledge base

What has been measured about optimizing kernels for MI355X (gfx950) with agc, kept so that the next
agent session, policy or generator starts from it. `kb(query)` (a session tool) searches all of it.

| file | what | written by |
|---|---|---|
| `PATTERNS.md` | Which kind of kernel is this, and what can it gain: the short decision guide | hand |
| `OPTIMIZATIONS.md` | The catalog: every optimization by technique, with when it applies, how to apply it (pass, template, edit), what it measured, and its recipe. Losses and parities included | hand |
| `RECIPES.md` | Every verified performance result and the recipe that reproduces it: session recipes, default-policy results, generator templates, GEMM, hand-written wins | `scripts/kb.py`, from the records |
| `INDEX.md` | Every entry of the per-kernel files, by verdict (pays, parity, loses) | `scripts/kb.py` |
| `<kernel>.md` | Entries from the agent sessions on that kernel (`report(kb=[...])`): one optimization each, with verdict, `applies_when`, `how`, `measured` | the harness, after each session |

Rules:

- Numbers in `RECIPES.md` are harness-verified (static checks, full battery, differential check, paired
  timings over several allocations of the tensors). Numbers in the per-kernel files are the sessions' own
  measurements; several small "wins" there were measured on one allocation and did not hold (see
  `OPTIMIZATIONS.md`, H1).
- An optimization that recurs is promoted: to a pass (`coarsen`, `unroll_loads`, `throttle`, `stream_loads`),
  to a generator template (`elementwise`, `rowwise`, `gemm_mfma`, `attention_mfma`), and into
  `OPTIMIZATIONS.md` with the kernels it was measured on.
- After changing records or recipes: `.venv/bin/python scripts/kb.py` (a test checks the generated files).
- The per-kernel ISA-level analyses (time split, opportunities, what was tried) are in `docs/kernels/`.
