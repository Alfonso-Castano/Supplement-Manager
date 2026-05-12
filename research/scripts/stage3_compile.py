#!/usr/bin/env python3
"""
Stage 3: SQLite Compilation
Reads research/interactions.json + canonical_names.json + target_list.json.
Filters to medium+ confidence records only (D-09).
Writes database/stackwise.sqlite with all three tables.
Run ONLY after gap_report.md shows hard floor PASS.
"""
import json
import re
import sqlite3
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2]))
from research.scripts.utils import RESEARCH_DIR

TARGET_LIST_PATH = RESEARCH_DIR / "target_list.json"
CANONICAL_PATH = RESEARCH_DIR / "canonical_names.json"
INTERACTIONS_PATH = RESEARCH_DIR / "interactions.json"
GAP_REPORT_PATH = RESEARCH_DIR / "gap_report.md"
DB_PATH = Path("database/stackwise.sqlite")

SCHEMA_DDL = """
CREATE TABLE IF NOT EXISTS interactions (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    compound_a          TEXT NOT NULL,
    compound_b          TEXT NOT NULL,
    compound_a_type     TEXT NOT NULL CHECK(compound_a_type IN ('supplement', 'drug')),
    compound_b_type     TEXT NOT NULL CHECK(compound_b_type IN ('supplement', 'drug')),
    interaction_type    TEXT NOT NULL CHECK(interaction_type IN (
                            'absorption_competition', 'timing_conflict',
                            'unsafe_combination', 'synergy')),
    severity            TEXT NOT NULL CHECK(severity IN ('advisory', 'critical')),
    mechanism           TEXT,
    direction           TEXT CHECK(direction IN ('bidirectional', 'directional')),
    effect              TEXT NOT NULL,
    suggested_action    TEXT NOT NULL,
    timing_relevant     INTEGER NOT NULL CHECK(timing_relevant IN (0, 1)),
    timing_window_hours INTEGER,
    citations           TEXT NOT NULL,
    confidence          TEXT NOT NULL CHECK(confidence IN ('high', 'medium', 'low')),
    date_added          TEXT NOT NULL,
    conflict_note       TEXT
);

CREATE INDEX IF NOT EXISTS idx_ab ON interactions(compound_a, compound_b);
CREATE INDEX IF NOT EXISTS idx_ba ON interactions(compound_b, compound_a);

CREATE TABLE IF NOT EXISTS ingredients (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    canonical_name  TEXT NOT NULL UNIQUE,
    item_type       TEXT NOT NULL CHECK(item_type IN ('supplement', 'drug')),
    aliases         TEXT NOT NULL DEFAULT '[]',
    category        TEXT,
    timing_properties TEXT
);

CREATE TABLE IF NOT EXISTS metadata (
    db_version  TEXT NOT NULL,
    date_built  TEXT NOT NULL
);
"""


def compile_database():
    # Guard: confirm gap report Hard Floor Check section says PASS
    gap_content = GAP_REPORT_PATH.read_text(encoding="utf-8")
    hard_floor_match = re.search(r'## Hard Floor Check.*?\n\*\*(PASS|FAIL)\*\*', gap_content, re.DOTALL)
    if not hard_floor_match or hard_floor_match.group(1) != "PASS":
        print("ERROR: Hard floor check is not PASS in gap_report.md. Run stage3_validate.py first.")
        sys.exit(1)

    DB_PATH.parent.mkdir(exist_ok=True)

    if DB_PATH.exists():
        DB_PATH.unlink()

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.executescript(SCHEMA_DDL)
    conn.commit()

    # Load and filter interactions (D-09: medium+ only to SQLite)
    with open(INTERACTIONS_PATH, encoding="utf-8") as f:
        records = json.load(f)
    production = [r for r in records if r["confidence"] in ("high", "medium")]

    print(f"Total records in interactions.json: {len(records)}")
    print(f"Production records (medium+): {len(production)}")
    print(f"Low confidence (excluded from SQLite): {len(records) - len(production)}")

    # Insert interactions using parameterized queries (T-0-15 SQL injection mitigation)
    for r in production:
        cur.execute("""
            INSERT INTO interactions
              (compound_a, compound_b, compound_a_type, compound_b_type,
               interaction_type, severity, mechanism, direction, effect,
               suggested_action, timing_relevant, timing_window_hours,
               citations, confidence, date_added, conflict_note)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            r["compound_a"], r["compound_b"],
            r["compound_a_type"], r["compound_b_type"],
            r["interaction_type"], r["severity"],
            r.get("mechanism"), r.get("direction"),
            r["effect"], r["suggested_action"],
            1 if r.get("timing_relevant") else 0,
            r.get("timing_window_hours"),
            json.dumps(r["citations"]) if isinstance(r["citations"], list) else r["citations"],
            r["confidence"], r["date_added"],
            r.get("conflict_note"),
        ))

    conn.commit()
    print(f"Inserted {len(production)} interaction records")

    # Build ingredients table from canonical_names.json + target_list.json
    with open(CANONICAL_PATH, encoding="utf-8") as f:
        canonical = json.load(f)
    with open(TARGET_LIST_PATH, encoding="utf-8") as f:
        target_list = json.load(f)

    compound_meta = {}
    for c in target_list["supplements"]:
        compound_meta[c["canonical_name"]] = {"item_type": "supplement", "category": c.get("category")}
    for c in target_list["medications"]:
        compound_meta[c["canonical_name"]] = {"item_type": "drug", "category": c.get("category")}

    ingredients_count = 0
    for canonical_name, value in canonical.items():
        if canonical_name.startswith("_"):
            continue

        if isinstance(value, list):
            aliases = value
            timing_props = None
        elif isinstance(value, dict):
            aliases = value.get("aliases", [])
            timing_props = value.get("timing_properties")
        else:
            aliases = []
            timing_props = None

        meta = compound_meta.get(canonical_name, {})
        cur.execute("""
            INSERT OR IGNORE INTO ingredients
              (canonical_name, item_type, aliases, category, timing_properties)
            VALUES (?,?,?,?,?)
        """, (
            canonical_name,
            meta.get("item_type", "supplement"),
            json.dumps(aliases),
            meta.get("category"),
            json.dumps(timing_props) if timing_props else None,
        ))
        ingredients_count += 1

    conn.commit()
    print(f"Inserted {ingredients_count} ingredient records")

    cur.execute(
        "INSERT INTO metadata (db_version, date_built) VALUES (?,?)",
        ("1.0.0", date.today().isoformat())
    )
    conn.commit()
    conn.close()

    print(f"\nCompiled: {DB_PATH}")
    print(f"  interactions: {len(production)} rows")
    print(f"  ingredients: {ingredients_count} rows")
    print(f"  metadata: 1 row (db_version=1.0.0, date_built={date.today().isoformat()})")


def verify_requirements():
    """Run REQ-02/REQ-03 check against compiled SQLite. Returns True if pass."""
    conn = sqlite3.connect(DB_PATH)
    with open(TARGET_LIST_PATH, encoding="utf-8") as f:
        targets = json.load(f)

    fails = []
    for compound in targets["supplements"] + targets["medications"]:
        name = compound["canonical_name"]
        count = conn.execute("""
            SELECT COUNT(*) FROM interactions
            WHERE (compound_a = ? OR compound_b = ?)
              AND confidence IN ('high', 'medium')
        """, (name, name)).fetchone()[0]
        if count == 0:
            fails.append(name)
    conn.close()

    if fails:
        print(f"REQ-02/REQ-03 FAIL — {len(fails)} compounds have no medium+ records in SQLite:")
        for f in fails:
            print(f"  - {f}")
        return False
    print("REQ-02 PASS — All 50 supplements have >= 1 medium+ record")
    print("REQ-03 PASS — All 20 medications have >= 1 medium+ record")
    return True


if __name__ == "__main__":
    compile_database()
    passed = verify_requirements()
    sys.exit(0 if passed else 1)
