"""A compiler session on one manifest (design §5): the same operations for an agent (through
MCP), a scripted policy and the CLI.

States are immutable and content-addressed. `ref` is amdclang's build of the HIP source,
imported into machine IR. Transformations (`edit_ir`, `edit`, `apply`) create new states;
`static_check`, `check` (battery) and `bench` (paired against `ref`) attach results to the
exact state. No GPU job runs for a state that fails the static checks, and no timing is reported
for a state that fails the battery. Every refusal is a `SessionError` with a kind, a location,
the offending values and a suggestion.
"""
from __future__ import annotations

import collections
import copy
import difflib
import hashlib
import json
import os
import re
from pathlib import Path

from ..arch.model import load as load_arch
from ..isa import table
from ..manifest import Manifest, ManifestError
from ..mir import abi, asm, check as mircheck, emit
from ..mir.analysis import cfg
from ..mir.ir import Block, Kernel, Module
from ..runtime import harness, toolchain
from ..runtime.executor import ExecutorError
from ..runtime.timing import PROTOCOL_VERSION, TimingProtocol
from ..store import Store

KINDS = ("parse", "parameter", "unknown", "static", "unverified", "verification", "toolchain", "gpu", "internal")
_NUMBERED = re.compile(r"^\s*\[\d+\]\s*")


class SessionError(Exception):
    def __init__(self, kind: str, message: str, *, location=None, values=None, suggestion: str | None = None):
        super().__init__(message)
        assert kind in KINDS, kind
        self.kind, self.message, self.location, self.values, self.suggestion = kind, message, location, values, suggestion

    def to_dict(self) -> dict:
        d = {"error": self.message, "kind": self.kind}
        for k in ("location", "values", "suggestion"):
            if getattr(self, k) is not None:
                d[k] = getattr(self, k)
        return d


TRANSFORMS: dict[str, dict] = {}       # name -> {"fn": fn(module, kernel_name, **params) -> Module, "doc", "params"}


def transform(name: str, doc: str, params: dict | None = None, launch: bool = False):
    """Register a named transformation of a physical module (the passes of `agc.mir.passes`).
    With `launch`, the function also receives the state's launch (`launch=`) and returns
    `(module, new launch)`: a transformation that changes how the kernel is launched."""
    def deco(fn):
        TRANSFORMS[name] = {"fn": fn, "doc": doc, "params": params or {}, "launch": launch}
        return fn
    return deco


class Session:
    def __init__(self, manifest: Manifest, store: Store, root: Path, quick: bool = False):
        self.manifest, self.store, self.root, self.quick = manifest, store, root, quick
        self.arch = load_arch(manifest.arch)
        self._modules: dict[str, Module] = {}
        self.ref_id: str | None = None

    # ---- opening ---------------------------------------------------------------
    @classmethod
    def open(cls, manifest_path: str | Path, root: str | Path | None = None, quick: bool = False) -> "Session":
        try:
            m = Manifest.load(manifest_path)
        except (ManifestError, OSError) as e:
            raise SessionError("parameter", f"cannot load the manifest: {e}") from None
        base = Path(root) if root else Path(os.environ.get("AGC_ROOT", ".agc"))
        ident = cls.identity(m)
        sroot = base / "sessions" / f"{m.name}-{ident}"
        s = cls(m, Store(sroot), base, quick)
        if m.source is None:
            return s                                        # a tensor program: states come from `generate`
        try:
            b = harness.reference_build(m)
            module = emit.import_asm(b.asm)
        except (toolchain.ToolchainError, asm.AsmError) as e:
            raise SessionError("toolchain", f"cannot build or import the amdclang reference: {e}") from None
        s._kernel(module)                                   # the entry exists
        st = s.store.put("mir", asm.print_module(module), None,
                         {"name": "import", "source": "amdclang", "flags": b.flags, "toolchain": toolchain.identity()["clang"]})
        s.ref_id = st.id
        s.store.tag("ref", st.id)
        return s

    @staticmethod
    def identity(m: Manifest) -> str:
        """Everything cached results depend on: the manifest, the toolchain, the contents of the HIP
        source and its includes (the baseline and, without a reference program, the oracle), and the
        contents of file-backed reference and tensor programs. A change of any of them is a new session."""
        parts: list = [m.to_dict(), toolchain.identity(), PROTOCOL_VERSION]
        if m.source is not None:
            parts.append(toolchain.hip_key(m.source, [*toolchain.HIP_FLAGS, *m.hip_flags], m.arch))
        for spec in (m.reference, m.program):
            if spec is not None and spec.file:
                try:
                    parts.append(hashlib.sha256((m.path.parent / spec.file).read_bytes()).hexdigest())
                except OSError as e:
                    raise SessionError("parameter", f"cannot read {spec.file}: {e}") from None
        return hashlib.sha256(json.dumps(parts, sort_keys=True, default=str).encode()).hexdigest()[:10]

    @property
    def id(self) -> str:
        return self.store.root.name

    def info(self) -> dict:
        m = self.manifest
        return {"session": self.id, "manifest": m.name, "entry": m.entry, "arch": m.arch, "ref": self.ref_id,
                "params": [p.to_dict() for p in m.params], "shapes": m.shapes, "bench_shapes": m.timing_symbols(),
                "launch": {"grid": m.grid, "block": m.block, "lds": m.lds},
                "tolerance": {p.name: {"rtol": m.tolerance_for(p.name)[0], "atol": m.tolerance_for(p.name)[1],
                                       "cond": m.cond_for(p.name)} for p in m.outputs()},
                "timing_protocol": PROTOCOL_VERSION, "noise_floor": TimingProtocol().noise_floor,
                "states": len(self.store.all_states()), "tags": self.store.tags(), "branches": list(self.store.branches()),
                "transforms": sorted(TRANSFORMS), "toolchain": toolchain.identity(),
                "program": bool(m.program), "hip_source": bool(m.source)}

    # ---- helpers ---------------------------------------------------------------
    def resolve(self, ref: str) -> str:
        try:
            return self.store.resolve(ref)
        except KeyError as e:
            raise SessionError("unknown", str(e).strip("'\""), suggestion="list_states() shows ids, tags and branches") from None

    def module(self, ref: str) -> Module:
        sid = self.resolve(ref)
        if sid not in self._modules:
            self._modules[sid] = asm.parse(self.store.get(sid).ir)
        return self._modules[sid]

    def _kernel(self, module: Module) -> Kernel:
        entry = self.manifest.entry
        for k in module.kernels:
            if k.name == entry or re.match(rf"_Z\w*?{len(entry)}{re.escape(entry)}", k.name):
                return k
        raise SessionError("parameter", f"kernel {entry!r} is not in the module (kernels: {[k.name for k in module.kernels]})")

    def generated(self, sid: str) -> bool:
        """The state descends from a generator's output (not from amdclang's import)."""
        return any(st.action.get("name") == "generate" or st.action.get("strict") for st in self.store.ancestry(sid))

    def launch_of(self, sid: str) -> dict | None:
        """The launch geometry a generated kernel (or a state derived from one) carries; None: the manifest's."""
        for st in reversed(self.store.ancestry(sid)):
            if "launch" in st.action:
                return st.action["launch"]
        return None

    def _launch(self, parent: str | None, launch) -> dict:
        """A launch given by the caller, checked and completed from the parent's (or the manifest's)."""
        m = self.manifest
        cur = (self.launch_of(parent) if parent else None) or {"grid": list(m.grid), "block": list(m.block), "lds": m.lds}
        if not isinstance(launch, dict) or set(launch) - {"grid", "block", "lds", "args"}:
            raise SessionError("parameter", "launch is an object with any of `grid`, `block`, `lds`, `args`", values={"given": launch},
                               suggestion='for example {"grid": ["cdiv(N, 1024)"], "block": [256]}; args: [{"dtype": "u32", "value": "N"}]')
        out = {**copy.deepcopy(cur), **copy.deepcopy(launch)}
        from ..manifest import eval_expr
        try:
            for syms in (m.shapes, m.timing_symbols()):
                for key in ("grid", "block"):
                    dims = out[key] if isinstance(out[key], list) else [out[key]]
                    if not 1 <= len(dims) <= 3 or any(eval_expr(d, syms) < 1 for d in dims):
                        raise SessionError("parameter", f"launch {key} {dims} must be 1 to 3 positive dimensions at {syms}")
                    out[key] = dims
                eval_expr(out.get("lds", 0), syms)
                for a in out.get("args", []):
                    if not isinstance(a, dict) or set(a) != {"dtype", "value"}:
                        raise SessionError("parameter", 'each launch argument is {"dtype": ..., "value": expression}', values={"given": a})
                    eval_expr(a["value"], syms)
        except ManifestError as e:
            raise SessionError("parameter", f"launch: {e}", values={"symbols": sorted(m.shapes)}) from None
        return out

    def source(self, text: str, launch: dict | None = None, note: str = "") -> dict:
        """A new root state from a rewritten HIP source: compiled with amdclang (same flags as the
        baseline), imported into machine IR. The kernel must keep the manifest's entry name and
        parameters; `launch` may change the grid and block and append arguments. The state starts
        unverified and can be edited like any other."""
        m = self.manifest
        d = self.store.root / "src"
        d.mkdir(parents=True, exist_ok=True)
        path = d / f"{hashlib.sha256(text.encode()).hexdigest()[:16]}.hip"
        path.write_text(text)
        inc = [m.path.parent] + ([Path(m.source).resolve().parent] if m.source else [])
        try:
            b = toolchain.hip_build(path, [*toolchain.HIP_FLAGS, *m.hip_flags], mcpu=m.arch, include_dirs=inc)
            module = emit.import_asm(b.asm)
        except toolchain.ToolchainError as e:
            raise SessionError("toolchain", f"amdclang rejected the source: {e}"[:3000]) from None
        except asm.AsmError as e:
            raise SessionError("toolchain", f"cannot import amdclang's assembly: {e.message}", location={"line": e.line, "text": e.text}) from None
        self._kernel(module)
        action = {"name": "source", "note": note, "file": str(path), "sha": path.stem}
        if launch is not None:
            action["launch"] = self._launch(None, launch)
        return self._put(None, module, action)

    def relaunch(self, parent: str, launch: dict, note: str = "") -> dict:
        """The same code with another launch (grid, block, LDS size, appended arguments)."""
        pid = self.resolve(parent)
        m = self.manifest
        new = self._launch(pid, launch)
        if new == (self.launch_of(pid) or {"grid": list(m.grid), "block": list(m.block), "lds": m.lds}):
            raise SessionError("parameter", "the launch is identical to the parent's", suggestion="nothing to do")
        return self._put(pid, copy.deepcopy(self.module(pid)), {"name": "relaunch", "note": note, "launch": new})

    def adopt(self, text: str, launch: dict | None = None, strict: bool = False, note: str = "") -> dict:
        """A root state from a whole module's text (what `export` gives): a recorded result rebuilt here."""
        try:
            module = asm.parse(text)
        except asm.AsmError as e:
            raise SessionError("parse", e.message, location={"line": e.line, "text": e.text}) from None
        self._kernel(module)
        action = {"name": "adopt", "note": note, "strict": bool(strict)}
        if launch is not None:
            action["launch"] = self._launch(None, launch)
        return self._put(None, module, action)

    def traffic(self, ms: float) -> dict:
        """Memory traffic at the bench shapes if every tensor element is touched once (an upper bound for
        kernels that read only part of a tensor), and the rate that implies for a run of `ms`."""
        from ..dtypes import dtype
        from ..manifest import eval_expr
        m, sym = self.manifest, self.manifest.timing_symbols()
        rd = wr = 0
        for p in m.tensors():
            n = dtype(p.dtype).itemsize
            for d in p.shape:
                n *= eval_expr(d, sym)
            rd += n * (p.role in ("in", "inout"))
            wr += n * (p.role in ("out", "inout"))
        mem = {k: v for k, v in self.arch.section("memory").items()} if "memory" in self.arch.data else {}
        return {"read_mb": round(rd / 1e6, 1), "written_mb": round(wr / 1e6, 1),
                "tb_per_s": round((rd + wr) / 1e12 / (ms * 1e-3), 2) if ms else None,
                "measured_ceilings_tb_per_s": {k: getattr(v, "value", v) for k, v in mem.items()},
                "note": "upper bound: assumes every tensor element is read or written once"}

    def compare(self, a: str, b: str, pairs: int | None = None) -> dict:
        """Paired timing of state `b` against state `a` (both must have passed the battery): which of two
        candidates is faster, when both are compared with `ref` too coarsely to tell."""
        ia, ib = self.resolve(a), self.resolve(b)
        for sid in (ia, ib):
            ck = self.store.get_result(sid, "check")
            if sid != self.ref_id and not (ck and ck.get("ok")):
                raise SessionError("unverified", f"state {sid} has no passing battery", suggestion="check it first")
        try:
            r = harness.paired(self.manifest, self._hsaco(ia), self._hsaco(ib), root=self.root,
                               protocol=TimingProtocol(pairs=pairs) if pairs else None, reference_launch=self.launch_of(ia), candidate_launch=self.launch_of(ib))
        except ExecutorError as e:
            raise SessionError("gpu", str(e)[:1500]) from None
        if not r.get("ok"):
            return {"ok": False, "error": r.get("error"), "failed": r.get("failed")}
        return {"ok": True, "a": ia, "b": ib, "outcome_b_vs_a": r["outcome"], "speedup_b_over_a": round(r["speedup"], 4),
                "ci95": [round(x, 4) for x in r["speedup_ci95"]], "a_ms": round(r["reference"]["median_ms"], 5),
                "b_ms": round(r["candidate"]["median_ms"], 5)}

    def verify(self, ref: str, pairs: int | None = None) -> dict:
        """Static check, full battery and paired timing of a state, all run again (no cached result is trusted)."""
        sid = self.resolve(ref)
        for kind in ("static", "check", "bench"):
            p = self.store.root / "results" / sid / f"{kind}.json"
            if p.exists():
                p.unlink()
        quick, self.quick = self.quick, False
        try:
            st = self.static_check(sid)
            if not st["ok"]:
                return {"id": sid, "ok": False, "stage": "static", "errors": st["errors"][:5]}
            ck = self.check(sid)
            if not ck["ok"]:
                return {"id": sid, "ok": False, "stage": "battery", "failures": ck.get("failures"), "error": ck.get("error")}
            b = self.bench(sid, pairs)
            return {"id": sid, "ok": bool(b.get("ok")), "stage": "bench", "cases": ck.get("cases_total"), **{k: b.get(k) for k in
                    ("outcome", "speedup", "speedup_ci95", "reference_ms", "candidate_ms", "protocol_version", "error")}}
        finally:
            self.quick = quick

    def export(self, ref: str) -> dict:
        """Everything needed to rebuild a state elsewhere: the module text, the launch, how it was made."""
        sid = self.resolve(ref)
        return {"id": sid, "asm": self.store.get(sid).ir, "launch": self.launch_of(sid), "strict": self.generated(sid),
                "trace": self.trace(sid)}

    def _put(self, parent: str | None, module: Module, action: dict) -> dict:
        text = asm.print_module(module)
        if parent is not None and text == self.store.get(parent).ir and action.get("name") != "relaunch":
            raise SessionError("parameter", "the result is identical to the parent state", suggestion="nothing to do")
        st = self.store.put("mir", text, parent, action)
        self._modules[st.id] = module
        return self.state(st.id, include_ir=False)

    @staticmethod
    def listing(k: Kernel) -> str:
        """The kernel body with each instruction's index in its block: the addresses `edit` uses."""
        out = []
        for j, b in enumerate(k.blocks):
            if b.align:
                out.append(f"\t.p2align {b.align}")
            out.append(f"{b.label}:")
            out += [f"  [{i}] {inst}" for i, inst in enumerate(b.insts)]
        return "\n".join(out)

    # ---- inspect ---------------------------------------------------------------
    def state(self, ref: str = "ref", include_ir: bool = True) -> dict:
        sid = self.resolve(ref)
        rec = self.store.record(sid)
        if self.launch_of(sid):
            rec["launch"] = self.launch_of(sid)
        rec["names"] = [n for n, v in self.store.tags().items() if v == sid] + \
                       [n for n, b in self.store.branches().items() if b["head"] == sid]
        rec["children"] = [c.id for c in self.store.children(sid)]
        if include_ir:
            rec["listing"] = self.listing(self._kernel(self.module(sid)))
        return rec

    def list_states(self) -> list[dict]:
        out = []
        for s in self.store.all_states():
            r = self.store.record(s.id)
            out.append({"id": s.id, "parent": s.parent, "action": s.action.get("name"), "note": s.action.get("note", ""),
                        "static": (r.get("static") or {}).get("ok"), "check": (r.get("check") or {}).get("ok"),
                        "bench": {k: (r.get("bench") or {}).get(k) for k in ("outcome", "speedup")} if r.get("bench") else None,
                        "names": [n for n, v in self.store.tags().items() if v == s.id]})
        return out

    def features(self, ref: str = "ref") -> dict:
        """The stable observation of a state: resources, occupancy, shape of the code."""
        sid = self.resolve(ref)
        k = self._kernel(self.module(sid))
        g = cfg(k, table(), self.arch)
        use = abi.register_use(k)
        block = self.manifest.resolve(self.manifest.timing_symbols()).block
        lds = k.descriptor.get("group_segment_fixed_size", 0)
        occ = self.arch.occupancy(arch_vgprs=max(use["v"], 1), agprs=use["a"], sgprs=use["s"] + self.arch.res("sgpr_reserved"),
                                  lds_bytes=lds, workgroup_size=block[0] * block[1] * block[2])
        infos = [i for b in g.infos for i in b]
        groups = collections.Counter(("mfma" if i.mfma else "ds" if i.ds else i.ins.group.lower()) if i.ins else "unknown" for i in infos)
        loops = sorted({k.blocks[s].label for b, ss in enumerate(g.succ) for s in ss if s <= b})
        return {"id": sid, "instructions": len(infos), "blocks": len(k.blocks), "loop_headers": loops,
                "by_group": dict(sorted(groups.items())),
                "waits": sum(i.name == "s_waitcnt" for i in infos),
                "nop_wait_states": sum(i.wait_states for i in infos if i.name == "s_nop"),
                "loads": sum(i.load for i in infos), "stores": sum(i.store for i in infos),
                "registers": {"vgprs": use["v"], "agprs": use["a"], "sgprs": use["s"]}, "lds_bytes": lds,
                "occupancy": {"waves_per_simd": occ["waves_per_simd"], "limiter": occ["limiter"]},
                "mnemonics": dict(collections.Counter(i.inst.mnemonic for i in infos).most_common(12))}

    def actions(self, ref: str = "ref") -> dict:
        """What can be done to a state."""
        self.resolve(ref)
        return {"levels": {"source": "a rewritten HIP source compiled by amdclang into a new root state (may change the launch)",
                           "program": "the manifest's tensor program compiled by a generator template (generate)",
                           "mir": "machine IR: edit, edit_ir, apply"},
                "launch": "relaunch(ref, launch) or the `launch` argument of source / edit_ir: grid, block, lds, appended args",
                "edits": {"edit_ir": "replace the kernel body with new mir text (instructions and block labels)",
                          "edit": "replace / insert / delete instructions addressed by block label and index"},
                "transforms": {n: {"doc": t["doc"], "params": t["params"]} for n, t in sorted(TRANSFORMS.items())},
                "validate": ["static_check", "check", "bench"], "inspect": ["state", "features", "asm_diff", "trace"]}

    def asm_diff(self, a: str, b: str) -> dict:
        ia, ib = self.resolve(a), self.resolve(b)
        ka, kb = self._kernel(self.module(ia)), self._kernel(self.module(ib))
        ta, tb = asm.print_kernel_body(ka).splitlines(), asm.print_kernel_body(kb).splitlines()
        fa, fb = self.features(ia), self.features(ib)
        return {"a": ia, "b": ib, "diff": "\n".join(difflib.unified_diff(ta, tb, ia, ib, n=2, lineterm="")),
                "delta": {key: fb[key] - fa[key] for key in ("instructions", "waits", "nop_wait_states", "loads", "stores")},
                "registers": {"a": fa["registers"], "b": fb["registers"]},
                "occupancy": {"a": fa["occupancy"], "b": fb["occupancy"]}}

    def trace(self, ref: str) -> list[dict]:
        return self.store.export_trace(self.resolve(ref))["steps"]

    # ---- transform -------------------------------------------------------------
    def _with_body(self, parent_module: Module, blocks: list[Block]) -> Module:
        new = copy.deepcopy(parent_module)
        k = self._kernel(new)
        blocks[0].label = k.name
        k.blocks = blocks
        abi.sync_resources(k, self.arch)
        return new

    def edit_ir(self, parent: str, text: str, note: str = "", launch: dict | None = None) -> dict:
        """A new state whose kernel body is `text`: instructions and block labels in the amdclang
        dialect (a numbered listing is accepted). Register counts in the descriptor follow the code.
        The state starts unverified."""
        pid = self.resolve(parent)
        if ".amdgcn_target" in text:
            try:
                module = asm.parse(text)
            except asm.AsmError as e:
                raise SessionError("parse", e.message, location={"line": e.line, "text": e.text}) from None
            self._kernel(module)
        else:
            body = "\n".join(_NUMBERED.sub("\t", l) for l in text.splitlines())
            name = self._kernel(self.module(pid)).name
            lines = body.splitlines()
            for n, l in enumerate(lines):                 # the entry label may open the body (after comments)
                code = l.split(";")[0].strip()
                if code:
                    if code == f"{name}:":
                        lines[n] = ""
                    break
            body = "\n".join(lines)
            try:
                blocks = asm.parse_body(body, name)
            except asm.AsmError as e:
                raise SessionError("parse", e.message, location={"line": e.line, "text": e.text},
                                   suggestion="one instruction per line, `label:` lines for blocks, no directives") from None
            if not any(b.insts for b in blocks):
                raise SessionError("parse", "the body has no instructions")
            module = self._with_body(self.module(pid), blocks)
        action = {"name": "edit_ir", "note": note}
        if launch is not None:
            action["launch"] = self._launch(pid, launch)
            # arguments the launch appends that the kernel does not declare yet get their kernarg slots
            from ..dtypes import dtype
            k = self._kernel(module)
            if module is self.module(pid):
                module = copy.deepcopy(module)
                k = self._kernel(module)
            explicit = [a for a in k.metadata.get(".args", []) if not a[".value_kind"].startswith("hidden_")]
            extra = action["launch"].get("args", [])
            for e in extra[max(0, len(explicit) - len(self.manifest.params)):]:
                try:
                    action.setdefault("arg_offsets", []).append(abi.append_arg(k, dtype(e["dtype"]).itemsize))
                except ValueError as err:
                    raise SessionError("parameter", str(err)) from None
        return self._put(pid, module, action)

    def edit(self, parent: str, ops: list[dict], note: str = "") -> dict:
        """Structured edits. Each op: {"op": "replace" | "insert" | "delete", "block": label, "index": i,
        "text": instructions (replace / insert; one per line), "expect": the instruction now at that
        address (optional, checked), "count": instructions to delete (delete only, default 1)}. `insert` places
        the text before `index` (index = length appends). Addresses refer to the parent state; ops are applied from the last address backwards."""
        pid = self.resolve(parent)
        k0 = self._kernel(self.module(pid))
        blocks = copy.deepcopy(k0.blocks)
        index = {b.label: b for b in blocks}
        if not isinstance(ops, list) or not ops:
            raise SessionError("parameter", "ops must be a non-empty list")
        order = {b.label: n for n, b in enumerate(blocks)}
        parsed = []
        for n, op in enumerate(ops):
            kind, label, i = op.get("op"), op.get("block"), op.get("index")
            if kind not in ("replace", "insert", "delete"):
                raise SessionError("parameter", f"ops[{n}]: op must be replace, insert or delete", values=op)
            if label not in index:
                raise SessionError("parameter", f"ops[{n}]: no block {label!r}", values={"blocks": list(index)})
            size = len(index[label].insts)
            if type(i) is not int or not 0 <= i <= size - (kind != "insert"):
                raise SessionError("parameter", f"ops[{n}]: index {i!r} is outside block {label} ({size} instructions)", values=op)
            if "expect" in op and kind != "insert" and str(index[label].insts[i]) != " ".join(str(op["expect"]).split()):
                raise SessionError("parameter", f"ops[{n}]: {label}[{i}] is `{index[label].insts[i]}`, not the expected instruction",
                                   values={"expect": op["expect"], "found": str(index[label].insts[i])},
                                   suggestion="re-read the state's listing: addresses refer to the parent state")
            new = []
            if kind != "delete":
                try:
                    new = [asm.parse_inst(l) for l in str(op.get("text", "")).splitlines() if l.strip()]
                except asm.AsmError as e:
                    raise SessionError("parse", f"ops[{n}]: {e.message}", location={"op": n, "text": e.text}) from None
                if not new:
                    raise SessionError("parameter", f"ops[{n}]: {kind} needs `text`")
            count = op.get("count", 1) if kind == "delete" else 1
            if type(count) is not int or count < 1 or i + count > size:
                raise SessionError("parameter", f"ops[{n}]: count {count!r} runs past the end of block {label} ({size} instructions)", values=op)
            parsed.append((order[label], i, kind, label, new, count))
        seen = set()
        for o, i, kind, label, new, count in parsed:
            if kind != "insert":
                for j in range(i, i + count):
                    if (o, j) in seen:
                        raise SessionError("parameter", f"two ops change {label}[{j}]")
                    seen.add((o, j))
        # from the last address backwards; at one address the replacement or deletion of the original
        # instruction comes first, then the insertion in front of it
        for o, i, kind, label, new, count in sorted(parsed, key=lambda t: (t[0], t[1], t[2] != "insert"), reverse=True):
            insts = index[label].insts
            if kind == "insert":
                insts[i:i] = new
            elif kind == "delete":
                del insts[i:i + count]
            else:
                insts[i:i + 1] = new
        blocks = asm.split_at_branches(blocks)
        if not any(b.insts for b in blocks):
            raise SessionError("parameter", "the edit leaves no instructions")
        return self._put(pid, self._with_body(self.module(pid), blocks), {"name": "edit", "ops": ops, "note": note})

    def program(self) -> dict:
        """The tensor program of the manifest and the templates that can compile it."""
        from .. import gen
        from ..tair import print_program
        try:
            p = gen.program_of(self.manifest)
            names = gen.applicable(self.manifest)
        except gen.GenError as e:
            raise SessionError("parameter", str(e)) from None
        return {"program": print_program(p),
                "templates": {n: {"doc": gen.TEMPLATES[n]["doc"], "params": copy.deepcopy(gen.TEMPLATES[n]["params"]),
                                  "default": dict(gen.TEMPLATES[n]["default"])} for n in names}}

    def generate(self, template: str | None = None, params: dict | None = None) -> dict:
        """Compile the manifest's tensor program with a schedule template → a new root state. The HIP
        source, if any, is not used: it is only the baseline `bench` compares with."""
        from .. import gen
        try:
            c = gen.generate(self.manifest, template, params)
        except gen.GenError as e:
            raise SessionError("parameter", str(e), suggestion="program() lists the templates and their parameters") from None
        return self._put(None, c.module, {"name": "generate", "template": c.template, "params": c.params, "launch": c.launch})

    def apply(self, ref: str, name: str, params: dict | None = None) -> dict:
        pid = self.resolve(ref)
        if name not in TRANSFORMS:
            raise SessionError("unknown", f"no transform {name!r}", values={"transforms": sorted(TRANSFORMS)})
        params = dict(params or {})
        unknown = set(params) - set(TRANSFORMS[name]["params"])
        if unknown:
            raise SessionError("parameter", f"{name}: unknown parameter(s) {sorted(unknown)}", values=TRANSFORMS[name]["params"])
        module = copy.deepcopy(self.module(pid))
        action = {"name": name, "params": params}
        try:
            if TRANSFORMS[name].get("launch"):
                m = self.manifest
                current = self.launch_of(pid) or {"grid": list(m.grid), "block": list(m.block), "lds": m.lds}
                out, action["launch"] = TRANSFORMS[name]["fn"](module, self._kernel(module).name, launch=copy.deepcopy(current), **params)
            else:
                out = TRANSFORMS[name]["fn"](module, self._kernel(module).name, **params)
        except SessionError:
            raise
        except ValueError as e:
            raise SessionError("parameter", f"{name}: {e}") from None
        abi.sync_resources(self._kernel(out), self.arch)
        return self._put(pid, out, action)

    # ---- validate and measure --------------------------------------------------
    def static_check(self, ref: str) -> dict:
        sid = self.resolve(ref)
        cached = self.store.get_result(sid, "static")
        if cached is None:
            # code agc generated (and anything derived from it) must not read undefined registers
            r = mircheck.static_check(self.module(sid), strict=self.generated(sid))
            cached = {"ok": r["ok"], "findings": r["findings"]}
            self.store.put_result(sid, "static", cached)
        errors = [f for f in cached["findings"] if f.get("severity") != "warning"]
        return {"id": sid, "ok": cached["ok"], "errors": errors,
                "warnings": [f for f in cached["findings"] if f.get("severity") == "warning"]}

    def _hsaco(self, sid: str) -> bytes:
        st = self.static_check(sid)
        if not st["ok"]:
            raise SessionError("static", f"state {sid} fails the static checks ({len(st['errors'])} error(s)); no GPU job is run for it",
                               values={"errors": st["errors"][:5]}, suggestion="fix the findings of static_check, then retry")
        try:
            return emit.build(self.module(sid), check=False).hsaco
        except emit.EmitError as e:
            raise SessionError("toolchain", e.message, values={"detail": e.detail[-1500:]}) from None

    def check(self, ref: str) -> dict:
        """The battery (all cases, hidden seeds included) on the GPU. Refused when static checks fail."""
        sid = self.resolve(ref)
        hsaco = self._hsaco(sid)
        cached = self.store.get_result(sid, "check")
        if cached is None or cached.get("quick") != self.quick:
            try:
                r = harness.check(self.manifest, hsaco, quick=self.quick, root=self.root, launch=self.launch_of(sid))
            except ExecutorError as e:
                raise SessionError("gpu", str(e)[:1500], suggestion="a hang usually means a loop that never ends or a missing s_endpgm path") from None
            cached = {"ok": bool(r.get("ok")), "quick": self.quick, "cases_run": r.get("cases_run"),
                      "cases_total": r.get("cases_total"), "failures": (r.get("failures") or [])[:5],
                      "error": r.get("error"), "resources": r.get("resources")}
            self.store.put_result(sid, "check", cached)
        return {"id": sid, **{k: v for k, v in cached.items() if k != "t"}}

    def bench(self, ref: str, pairs: int | None = None) -> dict:
        """Paired timing against `ref` (amdclang) at the manifest's bench shapes. Needs a passing
        battery. For `ref` itself this is the A/A control. `pairs`: more launches per code object than
        the protocol's default, for effects of a few percent (the CI narrows with the square root)."""
        if pairs is not None and (type(pairs) is not int or not 60 <= pairs <= 1000):
            raise SessionError("parameter", "pairs must be an integer from 60 to 1000")
        proto = TimingProtocol(pairs=pairs) if pairs else None
        sid = self.resolve(ref)
        hsaco = self._hsaco(sid)
        ck = self.store.get_result(sid, "check")
        if ck is None or ck.get("quick") != self.quick:
            ck = self.check(sid)
        if not ck["ok"]:
            raise SessionError("verification", f"state {sid} fails the battery; it is not timed",
                               values={"failures": ck.get("failures"), "error": ck.get("error")},
                               suggestion="a wrong kernel has no speedup: fix it or roll back")
        if self.ref_id is None:                             # no HIP baseline: an absolute timing only
            try:
                r = harness.bench(self.manifest, hsaco, root=self.root, launch=self.launch_of(sid))
            except ExecutorError as e:
                raise SessionError("gpu", str(e)[:1500]) from None
            data = {"ok": bool(r.get("ok")), "outcome": "no_baseline", "against": None,
                    "candidate_ms": round(r["timing"]["median_ms"], 5) if r.get("ok") else None,
                    "protocol_version": PROTOCOL_VERSION, "error": r.get("error")}
            self.store.put_result(sid, "bench", data)
            return {"id": sid, **data}
        try:
            r = harness.paired(self.manifest, self._hsaco(self.ref_id), hsaco, root=self.root, protocol=proto,
                               reference_launch=self.launch_of(self.ref_id), candidate_launch=self.launch_of(sid))
        except ExecutorError as e:
            raise SessionError("gpu", str(e)[:1500]) from None
        if not r.get("ok"):
            data = {"ok": False, "against": self.ref_id, "failed": r.get("failed"), "error": r.get("error"),
                    "verification": r.get("verification")}
        else:
            data = {"ok": True, "against": self.ref_id, "outcome": "control" if sid == self.ref_id else r["outcome"],
                    "speedup": round(r["speedup"], 4), "speedup_ci95": [round(x, 4) for x in r["speedup_ci95"]],
                    "reference_ms": round(r["reference"]["median_ms"], 5), "candidate_ms": round(r["candidate"]["median_ms"], 5),
                    "pairs": r["pairs"], "case": r["case"], "protocol_version": r["protocol"]["version"],
                    "noise_floor": r["protocol"]["noise_floor"], "device": r["gpu"]["device"], "clocks": r["clocks"]["levels"],
                    "traffic": self.traffic(r["candidate"]["median_ms"])}
        self.store.put_result(sid, "bench", data)
        return {"id": sid, **data}

    # ---- organize --------------------------------------------------------------
    def tag(self, ref: str, name: str) -> dict:
        if name == "ref":
            raise SessionError("parameter", "`ref` is reserved for the amdclang build")
        try:
            self.store.tag(name, self.resolve(ref))
        except ValueError as e:
            raise SessionError("parameter", str(e)) from None
        return {"tags": self.store.tags()}

    def fork(self, ref: str, name: str, note: str = "") -> dict:
        try:
            return self.store.fork(name, self.resolve(ref), note)
        except ValueError as e:
            raise SessionError("parameter", str(e)) from None

    def checkpoint(self, ref: str, branch: str) -> dict:
        try:
            return self.store.checkpoint(branch, self.resolve(ref))
        except (KeyError, ValueError) as e:
            raise SessionError("parameter", str(e).strip("'\"")) from None

    def rollback(self, branch: str, steps: int = 1) -> dict:
        try:
            return self.store.rollback(branch, steps)
        except (KeyError, ValueError) as e:
            raise SessionError("parameter", str(e).strip("'\"")) from None

    def note(self, ref: str, text: str) -> dict:
        return {"notes": self.store.notes(self.resolve(ref)) if not text else self.store.note(self.resolve(ref), text)}

    def best(self) -> dict | None:
        """The verified state with the highest CI lower bound among measured wins (None if no win)."""
        wins = []
        for s in self.store.all_states():
            b = self.store.get_result(s.id, "bench")
            c = self.store.get_result(s.id, "check")
            if b and c and b.get("ok") and c.get("ok") and not c.get("quick") and b.get("outcome") == "win":
                wins.append((b["speedup_ci95"][0], s.id, b))
        if not wins:
            return None
        lo, sid, b = max(wins)
        return {"id": sid, "speedup": b["speedup"], "speedup_ci95": b["speedup_ci95"]}


def _register_builtin_transforms() -> None:
    from ..mir import passes
    passes.register_transforms()


_register_builtin_transforms()
