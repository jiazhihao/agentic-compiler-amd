"""M9: the report is generated from the records, and the knowledge notes are a skill."""
from pathlib import Path

from conftest import _load_script

ROOT = Path(__file__).parent.parent


def test_report_is_generated_from_the_records(tmp_path, monkeypatch):
    import sys
    _load_script("report")
    report = sys.modules["scripts_report"]
    current = (ROOT / "docs" / "report.md").read_text()
    monkeypatch.setattr(report, "ROOT", tmp_path)
    (tmp_path / "docs").mkdir()
    (tmp_path / "tests").symlink_to(ROOT / "tests")
    assert report.main() == 0
    assert (tmp_path / "docs" / "report.md").read_text() == current           # docs/report.md is not edited by hand
    assert "fallback" in current and "hipBLASLt" in current and "What did not work" in current
    assert "The target of 1.5x is met on 1 of 4 shapes" in current            # where the bf16 GEMM misses the target is stated
    assert "FP8 GEMM against hipBLASLt" in current and "less precise than an f32 sum" in current


def test_skills_exist():
    for name in ("agc", "agc-notes", "dev-workflow"):
        text = (ROOT / ".claude" / "skills" / name / "SKILL.md").read_text()
        assert text.startswith("---\nname: " + name)
    notes = (ROOT / ".claude" / "skills" / "agc-notes" / "SKILL.md").read_text()
    assert "What does not pay" in notes and "#23" in notes
