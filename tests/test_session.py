"""M5: the agent loop. Store, session actions and their refusals, the MCP server over stdio."""
import asyncio
import json
import os
import sys

import pytest

from agc.runtime.timing import PROTOCOL_VERSION

from agc import corpus
from agc.store import Store, content_id
from conftest import KERNELS, gpu, needs_toolchain

AXPY = str(KERNELS / "axpy.json")


# ---- store ---------------------------------------------------------------------------------
def test_store(tmp_path):
    st = Store(tmp_path)
    a = st.put("mir", "A", None, {"name": "import"})
    assert a.id == content_id("mir", "A", None, {"name": "import"}) and st.put("mir", "A", None, {"name": "import"}).id == a.id
    b = st.put("mir", "B", a.id, {"name": "edit"})
    c = st.put("mir", "C", b.id, {"name": "edit"})
    assert [s.id for s in st.ancestry(c.id)] == [a.id, b.id, c.id] and [s.id for s in st.children(a.id)] == [b.id]
    assert "-A" in st.diff(a.id, b.id) and "+B" in st.diff(a.id, b.id)
    with pytest.raises(KeyError):
        st.put("mir", "X", "0" * 16, {})
    st.put_result(b.id, "static", {"ok": True, "findings": []})
    st.put_result(b.id, "bench", {"ok": True, "outcome": "win", "speedup": 1.1, "speedup_ci95": [1.05, 1.15]})
    assert st.result_kinds(b.id) == ["bench", "static"] and st.record(b.id)["bench"]["outcome"] == "win"
    st.tag("good", b.id)
    assert st.resolve("good") == b.id and st.resolve(b.id[:8]) == b.id
    with pytest.raises(KeyError):
        st.resolve("nope")
    with pytest.raises(ValueError):
        st.tag("9bad", b.id)
    st.fork("try", a.id)
    st.checkpoint("try", b.id)
    st.checkpoint("try", c.id)
    assert st.resolve("try") == c.id and st.rollback("try")["head"] == b.id
    other = st.put("mir", "D", a.id, {"name": "edit"})
    with pytest.raises(ValueError, match="descend"):
        st.checkpoint("try", other.id)
    with pytest.raises(ValueError):
        st.rollback("try", 5)
    st.note(c.id, "tried hoisting the load")
    t = st.export_trace(c.id)
    assert t["schema"] == "agc-amd-trace-1" and [s["action"]["name"] for s in t["steps"]] == ["import", "edit", "edit"]
    assert t["steps"][-1]["notes"][0]["text"] == "tried hoisting the load"
    assert Store(tmp_path).get(c.id).ir == "C"                       # persistent


# ---- session (no GPU) ----------------------------------------------------------------------
@pytest.fixture
def session(tmp_path):
    from agc.session import Session
    return Session.open(AXPY, tmp_path, quick=True)


@needs_toolchain
def test_open_state_and_features(session, tmp_path):
    from agc.session import Session
    info = session.info()
    assert info["manifest"] == "axpy" and info["ref"] == session.ref_id and info["tags"] == {"ref": session.ref_id, "baseline": session.ref_id}
    assert info["tolerance"]["y"]["cond"] == 4e-7 and info["timing_protocol"] == PROTOCOL_VERSION
    st = session.state("ref")
    assert st["action"]["name"] == "import" and "axpy:\n  [0] s_load_dword s3, s[0:1], 0x24" in st["listing"]
    assert ".Lft0:\n  [0] s_load_dwordx4" in st["listing"]
    f = session.features("ref")
    assert f["instructions"] == 21 and f["waits"] == 3 and f["loads"] == 5 and f["stores"] == 1
    assert f["registers"] == {"vgprs": 6, "agprs": 0, "sgprs": 6} and f["occupancy"]["waves_per_simd"] == 8
    assert session.static_check("ref")["ok"]
    assert Session.open(AXPY, tmp_path).ref_id == session.ref_id      # reopening resumes the same session


@needs_toolchain
def test_edits_and_refusals(session):
    from agc.session import SessionError
    ref = session.ref_id
    # a harmless reorder: the two address computations swap
    e = session.edit("ref", [{"op": "replace", "block": ".Lft0", "index": 4, "text": "v_lshl_add_u64 v[2:3], s[0:1], 0, v[0:1]\ns_nop 0",
                              "expect": "v_lshl_add_u64 v[2:3], s[0:1], 0, v[0:1]"}], note="add a nop")
    assert e["parent"] == ref and e["action"]["name"] == "edit" and session.static_check(e["id"])["ok"]
    d = session.asm_diff("ref", e["id"])
    assert "+\ts_nop 0" in d["diff"] and d["delta"]["instructions"] == 1 and d["delta"]["nop_wait_states"] == 1
    assert [s["action"]["name"] for s in session.trace(e["id"])] == ["import", "edit"]
    # dropping a wait is caught statically and the GPU job is refused
    bad = session.edit("ref", [{"op": "delete", "block": ".Lft0", "index": 8, "expect": "s_waitcnt vmcnt(0)"}])
    st = session.static_check(bad["id"])
    assert not st["ok"] and st["errors"][0]["kind"] == "waitcnt" and "vmcnt(1)" in st["errors"][0]["message"]
    with pytest.raises(SessionError) as x:
        session.check(bad["id"])
    assert x.value.kind == "static" and "no GPU job" in x.value.message and x.value.to_dict()["suggestion"]
    with pytest.raises(SessionError) as x:
        session.bench(bad["id"])
    assert x.value.kind == "static"
    # a new register raises the descriptor's counts with the code
    more = session.edit("ref", [{"op": "insert", "block": ".LBB0_2", "index": 0, "text": "v_mov_b32_e32 v9, 0"}])
    k = session.module(more["id"]).kernel()
    assert k.descriptor["next_free_vgpr"] == 10 and k.metadata[".vgpr_count"] == 10 and session.static_check(more["id"])["ok"]
    # refusals are legible
    cases = [
        (lambda: session.edit("ref", [{"op": "delete", "block": ".Lft0", "index": 8, "expect": "s_nop 0"}]), "parameter", "not the expected"),
        (lambda: session.edit("ref", [{"op": "delete", "block": ".Lnope", "index": 0}]), "parameter", "no block"),
        (lambda: session.edit("ref", [{"op": "replace", "block": ".Lft0", "index": 99, "text": "s_nop 0"}]), "parameter", "outside block"),
        (lambda: session.edit("ref", [{"op": "replace", "block": ".Lft0", "index": 1, "text": "v_mov_b32_e32 v0, ,"}]), "parse", "ops[0]"),
        (lambda: session.edit("ref", [{"op": "frob", "block": ".Lft0", "index": 1}]), "parameter", "replace, insert or delete"),
        (lambda: session.edit("ref", []), "parameter", "non-empty"),
        (lambda: session.edit_ir("ref", "s_endpgm\n.section foo\n"), "parse", "directives"),
        (lambda: session.edit_ir("ref", session.state("ref")["listing"]), "parameter", "identical"),
        (lambda: session.state("deadbeef"), "unknown", "unknown state"),
        (lambda: session.apply("ref", "no_such_pass"), "unknown", "no transform"),
        (lambda: session.tag("ref", "ref"), "parameter", "reserved"),
    ]
    for fn, kind, text in cases:
        with pytest.raises(SessionError) as x:
            fn()
        assert x.value.kind == kind and text in x.value.message, x.value.message
    # edit_ir with a numbered listing round-trips an edited body
    listing = session.state("ref")["listing"].replace("[9] v_fmac_f32_e32 v5, s4, v4", "[9] v_fmac_f32_e32 v5, s4, v4\n  s_nop 0")
    again = session.edit_ir("ref", listing, note="via listing")
    assert session.features(again["id"])["instructions"] == 22
    session.tag(again["id"], "with_nop")
    session.fork("ref", "exp")
    session.checkpoint(again["id"], "exp")
    assert session.resolve("exp") == session.resolve("with_nop") == again["id"]
    assert session.rollback("exp")["head"] == ref and session.note(again["id"], "a nop costs nothing here")["notes"]


# ---- on the GPU ----------------------------------------------------------------------------
@pytest.mark.parametrize("_", [pytest.param(0, marks=gpu)])
def test_loop_on_the_gpu(_, tmp_path):
    from agc.session import Session, SessionError
    s = Session.open(AXPY, tmp_path)
    ok = s.edit("ref", [{"op": "insert", "block": ".Lft0", "index": 9, "text": "s_nop 0"}], note="a nop before the fmac")
    c = s.check(ok["id"])
    assert c["ok"] and c["cases_run"] == c["cases_total"] > 20
    b = s.bench(ok["id"])
    assert b["ok"] and b["outcome"] == "parity" and b["against"] == s.ref_id and b["protocol_version"] == PROTOCOL_VERSION
    assert s.bench("ref")["outcome"] == "control"
    # statically clean but wrong: the battery refuses it and it is never timed
    wrong = s.edit("ref", [{"op": "replace", "block": ".Lft0", "index": 9, "text": "v_fmac_f32_e32 v5, s4, v5",
                            "expect": "v_fmac_f32_e32 v5, s4, v4"}], note="wrong operand")
    assert s.static_check(wrong["id"])["ok"] and not s.check(wrong["id"])["ok"]
    with pytest.raises(SessionError) as x:
        s.bench(wrong["id"])
    assert x.value.kind == "verification" and s.store.get_result(wrong["id"], "bench") is None
    rows = {r["id"]: r for r in s.list_states()}
    assert rows[ok["id"]]["bench"]["outcome"] == "parity" and rows[wrong["id"]]["check"] is False
    assert s.best() is None                                          # parity is not a win


async def _mcp(root, calls):
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client
    params = StdioServerParameters(command=sys.executable, args=["-m", "agc.mcp.server"], env={**os.environ, "AGC_ROOT": str(root)})
    out = []
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = {t.name for t in (await session.list_tools()).tools}
            for name, args in calls:
                out.append(json.loads((await session.call_tool(name, args)).content[0].text))
    return tools, out


@needs_toolchain
def test_mcp_server_over_stdio(tmp_path):
    tools, out = asyncio.run(_mcp(tmp_path, [
        ("state", {}),                                                # before open: a refusal, not a crash
        ("open", {"manifest_path": AXPY, "quick": True}),
        ("state", {"ref": "ref"}),
        ("edit", {"parent": "ref", "ops": [{"op": "delete", "block": ".Lft0", "index": 3, "expect": "s_waitcnt lgkmcnt(0)"}]}),
        ("isa", {"mnemonic": "v_fmac_f32_e32"}),
        ("isa", {"mnemonic": "mfma_f32_32x32x16"}),
        ("arch", {"section": "hazards"}),
        ("actions", {}),
    ]))
    assert {"open", "state", "edit", "edit_ir", "apply", "static_check", "check", "bench", "asm_diff", "features",
            "trace", "isa", "arch", "tag", "fork", "checkpoint", "rollback", "note", "best", "list_states"} <= tools
    assert out[0]["kind"] == "unknown" and "open" in out[0]["error"]
    assert out[1]["manifest"] == "axpy" and "[0] s_load_dword" in out[2]["listing"]
    assert out[4]["name"] == "v_fmac_f32" and out[4]["encodings"][0]["operands"][0].startswith("VDST: 32 bits out")
    assert "v_mfma_f32_32x32x16_bf16" in out[5]["values"]["similar"]
    assert out[6]["valu_reads_sgpr_after_valu_write"] == {"value": 2, "source": "llvm"} and "edit" in out[7]["edits"]
    # a second connection resumes the session and sees the state made by the first
    _, out2 = asyncio.run(_mcp(tmp_path, [("open", {"manifest_path": AXPY, "quick": True}), ("list_states", {}),
                                          ("static_check", {"ref": out[3]["id"]})]))
    assert out2[0]["states"] == 2 and not out2[2]["ok"] and out2[2]["errors"][0]["kind"] == "waitcnt"


WINS = {"matvec": ("matvec_unroll16.s", 2.0), "gemm_naive": ("gemm_naive_unroll8.s", 1.7), "row_sum": ("row_sum_bulk4.s", 1.1),
        "row_argmax": ("row_argmax_bulk4.s", 1.15)}


@pytest.mark.parametrize("name", [pytest.param(n, marks=gpu) for n in WINS])
def test_agent_session_wins_reproduce(name, tmp_path):
    """The edits found in the M5 agent sessions (through MCP): each is statically clean, passes the
    full battery and is a paired win over amdclang."""
    from agc.session import Session
    body, at_least = WINS[name]
    s = Session.open(KERNELS / f"{name}.json", tmp_path)
    e = s.edit_ir("ref", (KERNELS.parent / "mir" / "wins" / body).read_text(), note="replay")
    st = s.static_check(e["id"])
    assert st["ok"], st["errors"]
    c = s.check(e["id"])
    assert c["ok"] and c["cases_run"] == c["cases_total"], c
    b = s.bench(e["id"])
    assert b["outcome"] == "win" and b["speedup_ci95"][0] > at_least, b
    assert s.best()["id"] == e["id"]
    recorded = json.loads((KERNELS.parent / "mir" / "wins" / body.replace(".s", ".trace.json")).read_text())
    assert recorded[-1]["bench"]["outcome"] == "win" and recorded[-1]["check"]["ok"]
