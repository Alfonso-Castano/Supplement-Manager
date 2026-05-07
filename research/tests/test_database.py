"""
Database integration tests for StackWise Phase 0.
Covers REQ-01 through REQ-05.

These tests are SKIPPED until Stage 3 removes the skip markers —
they require a compiled stackwise.sqlite file that does not exist yet.
"""
import json
import sqlite3
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

DB_PATH = Path("database/stackwise.sqlite")
TARGET_LIST_PATH = Path("research/target_list.json")


def test_schema():
    """REQ-01: stackwise.sqlite opens without error and has tables interactions/ingredients/metadata."""
    assert DB_PATH.exists(), f"Database not found at {DB_PATH}"
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = {row[0] for row in cur.fetchall()}
    conn.close()
    assert "interactions" in tables, "interactions table missing"
    assert "ingredients" in tables, "ingredients table missing"
    assert "metadata" in tables, "metadata table missing"


def test_supplement_coverage():
    """REQ-02: Every supplement in target_list.json has ≥1 medium+ confidence record."""
    with open(TARGET_LIST_PATH) as f:
        target = json.load(f)
    conn = sqlite3.connect(DB_PATH)
    missing = []
    for compound in target["supplements"]:
        name = compound["canonical_name"]
        count = conn.execute(
            """SELECT COUNT(*) FROM interactions
               WHERE (compound_a = ? OR compound_b = ?)
               AND confidence IN ('high', 'medium')""",
            (name, name),
        ).fetchone()[0]
        if count == 0:
            missing.append(name)
    conn.close()
    assert not missing, f"Supplements with no medium+ records: {missing}"


def test_medication_coverage():
    """REQ-03: Every medication in target_list.json has ≥1 medium+ confidence record."""
    with open(TARGET_LIST_PATH) as f:
        target = json.load(f)
    conn = sqlite3.connect(DB_PATH)
    missing = []
    for compound in target["medications"]:
        name = compound["canonical_name"]
        count = conn.execute(
            """SELECT COUNT(*) FROM interactions
               WHERE (compound_a = ? OR compound_b = ?)
               AND confidence IN ('high', 'medium')""",
            (name, name),
        ).fetchone()[0]
        if count == 0:
            missing.append(name)
    conn.close()
    assert not missing, f"Medications with no medium+ records: {missing}"


def test_canonical_format():
    """REQ-04: canonical_name values are lowercase_underscores; aliases is valid JSON array."""
    import re

    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("SELECT canonical_name, aliases FROM ingredients").fetchall()
    conn.close()
    pattern = re.compile(r"^[a-z0-9_]+$")
    bad_names = []
    bad_aliases = []
    for name, aliases_json in rows:
        if not pattern.match(name):
            bad_names.append(name)
        try:
            aliases = json.loads(aliases_json)
            assert isinstance(aliases, list), f"aliases for {name} is not a list"
        except (json.JSONDecodeError, AssertionError):
            bad_aliases.append(name)
    assert not bad_names, f"Non-lowercase_underscores canonical names: {bad_names}"
    assert not bad_aliases, f"Invalid aliases JSON for: {bad_aliases}"


def test_metadata():
    """REQ-05: metadata table has exactly one row with db_version and date_built."""
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("SELECT db_version, date_built FROM metadata").fetchall()
    conn.close()
    assert len(rows) == 1, f"Expected 1 metadata row, got {len(rows)}"
    db_version, date_built = rows[0]
    assert db_version, "db_version must not be empty"
    assert date_built, "date_built must not be empty"
    # Verify semantic version format (e.g. "1.0.0")
    parts = db_version.split(".")
    assert len(parts) == 3, f"db_version must be semantic (X.Y.Z), got {db_version}"
    # Verify ISO date format (YYYY-MM-DD)
    import re
    assert re.match(r"^\d{4}-\d{2}-\d{2}$", date_built), f"date_built must be ISO date, got {date_built}"
