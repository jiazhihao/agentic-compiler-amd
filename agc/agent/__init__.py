"""The per-kernel optimization harness (design D11): an agent drives one compiler session, the
harness verifies and records what it found.

    agc agent MANIFEST.json            one session: default policy, agent, verification, recipe
    agc replay [KERNEL ...]            rebuild and re-measure the recorded recipes

A session is a headless Claude Code run with the agc MCP server as its only way to change
anything. What it reports is not trusted: the harness rebuilds the named state and runs the static
check, the full battery and the paired timing again. A recipe (`bench/llm/sessions/<kernel>/`) is
the module text and the launch of a verified win, enough to rebuild it without the agent.
"""
from .runner import RECIPES, record, replay, run, verify  # noqa: F401
