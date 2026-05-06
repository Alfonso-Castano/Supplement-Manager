"""
Unit tests for pipeline deduplication and conflict resolution logic.
Tests cover: pair_exists, merge_record (D-15 conflict resolution, D-16 conflict_note).
"""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from research.scripts.utils import merge_record, pair_exists


# ---------------------------------------------------------------------------
# pair_exists
# ---------------------------------------------------------------------------


def test_pair_exists_ab_order(sample_record):
    """Record for (a, b) is found when queried as (a, b)."""
    records = [sample_record]
    idx = pair_exists(records, "vitamin_d3", "atorvastatin")
    assert idx == 0


def test_pair_exists_ba_order(sample_record):
    """Record for (a, b) is found when queried as (b, a) — bidirectional lookup."""
    records = [sample_record]
    idx = pair_exists(records, "atorvastatin", "vitamin_d3")
    assert idx == 0


def test_pair_exists_none():
    """No matching record → returns None."""
    records = [
        {
            "compound_a": "vitamin_d3",
            "compound_b": "atorvastatin",
        }
    ]
    result = pair_exists(records, "magnesium", "metformin")
    assert result is None


def test_pair_exists_empty_list():
    """Empty records list → returns None."""
    assert pair_exists([], "vitamin_d3", "atorvastatin") is None


def test_pair_exists_multiple_records(sample_record):
    """Finds correct record in a list with multiple entries."""
    other = {
        "compound_a": "magnesium",
        "compound_b": "metformin",
    }
    records = [other, sample_record]
    idx = pair_exists(records, "vitamin_d3", "atorvastatin")
    assert idx == 1


# ---------------------------------------------------------------------------
# merge_record — D-15 conflict resolution, D-16 conflict_note
# ---------------------------------------------------------------------------


def _make_record(compound_a, compound_b, confidence, severity, citations):
    return {
        "compound_a": compound_a,
        "compound_b": compound_b,
        "confidence": confidence,
        "severity": severity,
        "citations": citations,
        "conflict_note": None,
    }


def test_merge_record_higher_confidence_wins():
    """Higher-confidence source's severity wins (D-15)."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "high", "critical", ["url2"])
    merge_record(existing, new_rec)
    assert existing["confidence"] == "high"
    assert existing["severity"] == "critical"


def test_merge_record_lower_confidence_does_not_overwrite():
    """Lower-confidence new record does not overwrite existing severity."""
    existing = _make_record("vitamin_d3", "atorvastatin", "high", "critical", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "low", "advisory", ["url2"])
    merge_record(existing, new_rec)
    assert existing["confidence"] == "high"
    assert existing["severity"] == "critical"


def test_merge_record_higher_severity_on_tie():
    """Equal confidence + severity disagreement → higher severity wins (D-15)."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "medium", "critical", ["url2"])
    merge_record(existing, new_rec)
    assert existing["severity"] == "critical"


def test_merge_record_adds_citation():
    """New URL is added to citations list without duplicating existing URLs."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url2"])
    merge_record(existing, new_rec)
    assert "url1" in existing["citations"]
    assert "url2" in existing["citations"]
    assert len(existing["citations"]) == 2


def test_merge_record_no_duplicate_citation():
    """Same URL not added twice."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "high", "critical", ["url1"])
    merge_record(existing, new_rec)
    assert existing["citations"].count("url1") == 1


def test_merge_record_adds_conflict_note_on_severity_change():
    """When severity changes via higher-confidence source, conflict_note is populated (D-16)."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "high", "critical", ["url2"])
    merge_record(existing, new_rec)
    assert existing["conflict_note"] is not None
    assert len(existing["conflict_note"]) > 0


def test_merge_record_adds_conflict_note_on_tie_severity_change():
    """When severity changes via tie-break rule, conflict_note is populated (D-16)."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "medium", "critical", ["url2"])
    merge_record(existing, new_rec)
    assert existing["conflict_note"] is not None


def test_merge_record_no_conflict_note_when_severity_unchanged():
    """No conflict_note when severity does not change."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "high", "advisory", ["url2"])
    merge_record(existing, new_rec)
    assert existing["conflict_note"] is None


def test_merge_record_conflict_note_contains_original_severity():
    """conflict_note describes the pre-merge severity for auditability (D-16)."""
    existing = _make_record("vitamin_d3", "atorvastatin", "medium", "advisory", ["url1"])
    new_rec = _make_record("vitamin_d3", "atorvastatin", "high", "critical", ["url2"])
    merge_record(existing, new_rec)
    assert "advisory" in existing["conflict_note"]
    assert "critical" in existing["conflict_note"]
