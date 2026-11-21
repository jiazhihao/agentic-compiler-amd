#!/usr/bin/env python
"""Call tools of the agc MCP server from the shell (a client over stdio), for sessions driven from
a terminal or by an agent that has no MCP connection of its own.

    scripts/agc_mcp.py MANIFEST.json TOOL ['{"json": "arguments"}'] [TOOL ARGS ...]

Each invocation starts the server, calls `open(MANIFEST)` and then the tools in order. Session
states persist under $AGC_ROOT (default .agc), so consecutive invocations continue one session.
An argument of the form @path is replaced by the contents of that file (for `edit_ir`).
"""
from __future__ import annotations

import asyncio
import json
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def run(manifest: str, calls: list[tuple[str, dict]], quiet_open: bool = True) -> int:
    params = StdioServerParameters(command=sys.executable, args=["-m", "agc.mcp.server"])
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            r = await session.call_tool("open", {"manifest_path": manifest})
            text = r.content[0].text
            if '"error"' in text[:40] or not quiet_open:
                print(text)
            for name, args in calls:
                r = await session.call_tool(name, args)
                print(r.content[0].text)
    return 0


def main(argv) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    manifest, rest = argv[0], argv[1:]
    calls = []
    i = 0
    while i < len(rest):
        name = rest[i]
        args = {}
        if i + 1 < len(rest) and rest[i + 1].lstrip().startswith("{"):
            args = json.loads(rest[i + 1])
            i += 1
        for k, v in list(args.items()):
            if isinstance(v, str) and v.startswith("@"):
                args[k] = open(v[1:]).read()
        calls.append((name, args))
        i += 1
    return asyncio.run(run(manifest, calls))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
