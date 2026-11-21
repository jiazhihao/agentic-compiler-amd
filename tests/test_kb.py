"""The knowledge base: the curated catalog parses, the generated files follow the records, the search finds entries."""
from agc import kb


def test_the_catalog_entries_have_every_field():
    c = kb.catalog()
    assert len(c) >= 35
    for e in c:
        assert all(e[k] for k in ("title", "verdict", "applies", "how", "measured")), e["title"]
    ids = [e["title"].split(".")[0] for e in c]
    assert len(ids) == len(set(ids))


def test_generated_files_follow_the_records():
    for name, text in kb.generated().items():
        assert (kb.KB / name).read_text() == text, f"{name} is stale: run scripts/kb.py"


def test_every_session_recipe_is_in_the_recipe_list():
    text = (kb.KB / "RECIPES.md").read_text()
    from agc import agent
    for d in agent.RECIPES.iterdir():
        if (d / "recipe.json").exists():
            assert f"| `{d.name}` |" in text


def test_search_ranks_the_catalog_and_the_kernel_entries():
    hits = kb.search("ds_add_u32 histogram lanes same address")
    assert hits and hits[0]["title"].startswith("E1") and any(h["kernel"] == "vl_moe_align" for h in hits)
    assert kb.search("non-temporal loads copy")[0]["title"].startswith("A9")
    assert kb.search("zzzz qqqq") == []


def test_the_session_tool_returns_hits_with_their_source():
    from agc.mcp import server
    r = server.kb.__wrapped__("LDS reservation workgroups per compute unit") if hasattr(server.kb, "__wrapped__") else None
    if r is not None:
        assert r["hits"] and {"from", "title", "verdict", "applies_when", "how", "measured"} <= set(r["hits"][0])
