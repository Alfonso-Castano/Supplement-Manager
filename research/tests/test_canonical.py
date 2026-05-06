"""
Unit tests for canonical name resolution logic in research/scripts/utils.py.
Tests cover: save_json_atomic, already_collected, resolve_canonical.
"""
import json
import os
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

# Allow importing research.scripts.utils from the project root
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from research.scripts.utils import (
    already_collected,
    resolve_canonical,
    save_json_atomic,
)


# ---------------------------------------------------------------------------
# save_json_atomic
# ---------------------------------------------------------------------------


def test_save_json_atomic_writes_correct_content(tmp_path):
    """Write data to a path; verify file contents equal input."""
    data = {"key": "value", "num": 42}
    target = tmp_path / "out.json"
    save_json_atomic(data, target)
    assert target.exists()
    with open(target, encoding="utf-8") as f:
        loaded = json.load(f)
    assert loaded == data


def test_save_json_atomic_no_tmp_file_remains(tmp_path):
    """After successful write, no .tmp file should remain."""
    data = {"a": 1}
    target = tmp_path / "out.json"
    save_json_atomic(data, target)
    assert not target.with_suffix(".tmp").exists()


def test_save_json_atomic_is_crash_safe(tmp_path):
    """If os.replace raises, the original file must remain unchanged."""
    original_content = {"original": True}
    target = tmp_path / "out.json"
    # Write an original file first
    target.write_text(json.dumps(original_content), encoding="utf-8")

    new_data = {"original": False, "new": "data"}

    with patch("os.replace", side_effect=OSError("simulated crash")):
        with pytest.raises(OSError):
            save_json_atomic(new_data, target)

    # Original file should be unchanged
    with open(target, encoding="utf-8") as f:
        loaded = json.load(f)
    assert loaded == original_content


# ---------------------------------------------------------------------------
# already_collected
# ---------------------------------------------------------------------------


def test_already_collected_true(tmp_path):
    """Non-empty file exists → returns True."""
    output_dir = tmp_path / "raw"
    output_dir.mkdir()
    (output_dir / "vitamin_d3.txt").write_text("some content", encoding="utf-8")
    assert already_collected(output_dir, "vitamin_d3") is True


def test_already_collected_false_missing(tmp_path):
    """No file exists → returns False."""
    output_dir = tmp_path / "raw"
    output_dir.mkdir()
    assert already_collected(output_dir, "vitamin_d3") is False


def test_already_collected_false_empty(tmp_path):
    """Empty file exists → returns False."""
    output_dir = tmp_path / "raw"
    output_dir.mkdir()
    (output_dir / "vitamin_d3.txt").write_text("", encoding="utf-8")
    assert already_collected(output_dir, "vitamin_d3") is False


# ---------------------------------------------------------------------------
# resolve_canonical
# ---------------------------------------------------------------------------


def test_resolve_canonical_direct_key(tmp_canonical):
    """Exact canonical key match returns itself."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("vitamin_d3", canonical) == "vitamin_d3"


def test_resolve_canonical_alias(tmp_canonical):
    """Alias lookup resolves to the correct canonical key."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("cholecalciferol", canonical) == "vitamin_d3"


def test_resolve_canonical_case_insensitive(tmp_canonical):
    """Case-insensitive alias match works."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("CHOLECALCIFEROL", canonical) == "vitamin_d3"
    assert resolve_canonical("Lipitor", canonical) == "atorvastatin"


def test_resolve_canonical_direct_key_case_insensitive(tmp_canonical):
    """Direct key match is also case-insensitive."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("MAGNESIUM", canonical) == "magnesium"


def test_resolve_canonical_not_found(tmp_canonical):
    """Unknown name raises LookupError with informative message."""
    canonical, _ = tmp_canonical
    with pytest.raises(LookupError, match="not found in canonical_names.json"):
        resolve_canonical("unknown_compound_xyz", canonical)


def test_resolve_canonical_strips_whitespace(tmp_canonical):
    """Leading/trailing whitespace in name is stripped before lookup."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("  vitamin_d3  ", canonical) == "vitamin_d3"


def test_resolve_canonical_comment_key_skipped(tmp_canonical):
    """The _comment key is never returned as a canonical match."""
    canonical, _ = tmp_canonical
    with pytest.raises(LookupError):
        resolve_canonical("_comment", canonical)


def test_resolve_canonical_alias_with_space(tmp_canonical):
    """Alias containing spaces resolves correctly."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("vitamin d", canonical) == "vitamin_d3"


def test_resolve_canonical_alias_hyphen(tmp_canonical):
    """Alias with hyphen (vitamin d-3) resolves correctly."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("vitamin d-3", canonical) == "vitamin_d3"


def test_resolve_canonical_mag_alias(tmp_canonical):
    """Short alias 'mag' resolves to magnesium."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("mag", canonical) == "magnesium"


def test_resolve_canonical_brand_name(tmp_canonical):
    """Brand alias 'atorvastatin calcium' resolves to generic canonical."""
    canonical, _ = tmp_canonical
    assert resolve_canonical("atorvastatin calcium", canonical) == "atorvastatin"
