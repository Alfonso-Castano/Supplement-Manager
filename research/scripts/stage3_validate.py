#!/usr/bin/env python3
"""
Stage 3: Gap analysis — generates research/gap_report.md
Counts medium+ confidence records per target compound.
Hard floor check (D-10): every target compound must have >= 1 medium+ record.
"""
import json
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2]))
from research.scripts.utils import RESEARCH_DIR

TARGET_LIST_PATH = RESEARCH_DIR / "target_list.json"
INTERACTIONS_PATH = RESEARCH_DIR / "interactions.json"
GAP_REPORT_PATH = RESEARCH_DIR / "gap_report.md"


def generate_gap_report():
    with open(TARGET_LIST_PATH) as f:
        targets = json.load(f)
    with open(INTERACTIONS_PATH) as f:
        interactions = json.load(f)

    # D-09/D-10: only medium+ records count toward hard floor
    production = [r for r in interactions if r["confidence"] in ("high", "medium")]

    coverage = defaultdict(int)
    for r in production:
        coverage[r["compound_a"]] += 1
        coverage[r["compound_b"]] += 1

    all_targets = (
        [(c["canonical_name"], "supplement") for c in targets["supplements"]] +
        [(c["canonical_name"], "drug") for c in targets["medications"]]
    )

    well_covered = [(c, t, coverage[c]) for c, t in all_targets if coverage[c] >= 5]
    partial = [(c, t, coverage[c]) for c, t in all_targets if 1 <= coverage[c] < 5]
    not_covered = [(c, t) for c, t in all_targets if coverage[c] == 0]

    # D-10 hard floor check
    hard_floor_fail = [c for c, t in all_targets if coverage[c] == 0]

    lines = [
        f"# Database Gap Report\n\n",
        f"**Generated:** {date.today().isoformat()}\n",
        f"**Total production records (medium+):** {len(production)}\n\n",
    ]

    # Hard floor check block
    lines.append("## Hard Floor Check (D-10)\n\n")
    if hard_floor_fail:
        lines.append(f"**FAIL** — {len(hard_floor_fail)} compounds have 0 medium+ records:\n\n")
        for c in hard_floor_fail:
            lines.append(f"- `{c}`\n")
        lines.append("\n**Phase 0 cannot proceed until these compounds have >= 1 medium+ record.**\n")
        lines.append("Run targeted PubMed searches for each compound listed above.\n")
    else:
        lines.append("**PASS** — All target compounds have >= 1 medium+ record.\n")

    lines.append(f"\n## Well-covered compounds ({len(well_covered)} with 5+ records)\n\n")
    for c, t, n in sorted(well_covered, key=lambda x: -x[2]):
        lines.append(f"- `{c}` ({t}): {n} records\n")

    lines.append(f"\n## Partially covered compounds ({len(partial)} with 1-4 records)\n\n")
    for c, t, n in sorted(partial, key=lambda x: x[2]):
        lines.append(f"- `{c}` ({t}): {n} records\n")

    lines.append(f"\n## Not covered ({len(not_covered)} with 0 medium+ records)\n\n")
    for c, t in not_covered:
        lines.append(f"- `{c}` ({t})\n")

    lines.append("\n## Recommended PubMed searches for gap compounds\n\n")
    for c, t in not_covered:
        human_name = c.replace("_", " ")
        lines.append(
            f"- **{c}**: "
            f'`https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?'
            f'db=pubmed&term="{human_name}"[Title/Abstract]+AND+interaction[Title/Abstract]'
            f'&retmax=20&retmode=json`\n'
        )

    with open(GAP_REPORT_PATH, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(f"Gap report written to: {GAP_REPORT_PATH}")
    print(f"Well-covered: {len(well_covered)}")
    print(f"Partial: {len(partial)}")
    print(f"Not covered: {len(not_covered)}")
    print(f"Hard floor: {'PASS' if not hard_floor_fail else f'FAIL ({len(hard_floor_fail)} compounds)'}")

    return hard_floor_fail


if __name__ == "__main__":
    fails = generate_gap_report()
    sys.exit(1 if fails else 0)
