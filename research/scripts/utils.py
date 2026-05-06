"""
Shared pipeline utilities for StackWise Phase 0 data pipeline.
All stages import from this module — changes here affect all stages.
"""
import json
import os
import tempfile
from pathlib import Path

RESEARCH_DIR = Path("research")
CANONICAL_PATH = RESEARCH_DIR / "canonical_names.json"
INTERACTIONS_PATH = RESEARCH_DIR / "interactions.json"
CHECKPOINT_PATH = RESEARCH_DIR / "checkpoint.json"


def save_json_atomic(data: object, path: Path) -> None:
    """Write JSON atomically: write to temp file in same dir, then os.replace().
    Prevents corrupt JSON if process is killed mid-write (D-08, T-0-02)."""
    path = Path(path)
    tmp = path.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    os.replace(tmp, path)


def already_collected(output_dir: Path, canonical_name: str, extension: str = ".txt") -> bool:
    """Return True if the source file already exists and is non-empty.
    Used by Stage 1 resumption logic (D-08) to skip already-fetched compounds."""
    target = Path(output_dir) / f"{canonical_name}{extension}"
    return target.exists() and target.stat().st_size > 0


def load_canonical() -> dict:
    """Load canonical_names.json from disk. Must exist before Stage 2 begins."""
    with open(CANONICAL_PATH, encoding="utf-8") as f:
        return json.load(f)


def resolve_canonical(name: str, canonical: dict) -> str:
    """Resolve a compound name to its canonical form.
    1. Check if name is already a canonical key (exact match, case-insensitive)
    2. Check if name appears in any alias array (case-insensitive)
    3. If not found: raise LookupError — caller must add entry before proceeding.
    Never write a record for an unregistered compound (D-13)."""
    name_lower = name.lower().strip()
    # Direct key match (skip _comment and other metadata keys)
    for key in canonical:
        if key.startswith("_"):
            continue
        if key == name_lower:
            return key
    # Alias match (handles both simple list and extended dict format)
    for canon_key, value in canonical.items():
        if canon_key.startswith("_"):
            continue
        if isinstance(value, list):
            aliases = value
        elif isinstance(value, dict):
            aliases = value.get("aliases", [])
        else:
            continue
        if name_lower in [a.lower() for a in aliases]:
            return canon_key
    raise LookupError(
        f"'{name}' not found in canonical_names.json — add it before writing a record"
    )


def load_interactions() -> list:
    """Load existing interactions.json or return empty list (Stage 2 resumption, D-08)."""
    if INTERACTIONS_PATH.exists():
        with open(INTERACTIONS_PATH, encoding="utf-8") as f:
            return json.load(f)
    return []


def pair_exists(records: list, a: str, b: str):
    """Return index of existing record for compound pair (either direction), or None.
    One record per compound pair (deduplication rule from SPEC Stage 2)."""
    for i, r in enumerate(records):
        if (r["compound_a"] == a and r["compound_b"] == b) or \
           (r["compound_a"] == b and r["compound_b"] == a):
            return i
    return None


def merge_record(existing: dict, new_record: dict) -> None:
    """Merge new_record into existing record in-place. Implements D-15 conflict resolution.

    Rules (D-15):
    - Higher-confidence source's severity wins.
    - Equal confidence + severity disagreement → higher severity wins.
    - Both source URLs always added to citations.
    - When severity changes: populate conflict_note (D-16).

    Confidence ranking: high > medium > low.
    Severity ranking: critical > advisory.
    """
    CONFIDENCE_RANK = {"high": 2, "medium": 1, "low": 0}
    SEVERITY_RANK = {"critical": 1, "advisory": 0}

    # Capture originals before any mutation (D-16: conflict_note must log pre-merge state)
    original_conf_label = existing.get("confidence", "unknown")
    original_sev = existing.get("severity", "advisory")

    existing_conf = CONFIDENCE_RANK.get(existing.get("confidence", "low"), 0)
    new_conf = CONFIDENCE_RANK.get(new_record.get("confidence", "low"), 0)

    # Add new citation(s) without duplicates
    existing_citations = existing.get("citations", [])
    for url in new_record.get("citations", []):
        if url not in existing_citations:
            existing_citations.append(url)
    existing["citations"] = existing_citations

    # Resolve severity conflict per D-15
    existing_sev = existing.get("severity", "advisory")
    new_sev = new_record.get("severity", "advisory")
    severity_changed = False

    if new_conf > existing_conf:
        # Higher-confidence source wins on both confidence and severity
        if existing_sev != new_sev:
            severity_changed = True
        existing["confidence"] = new_record["confidence"]
        existing["severity"] = new_sev
    elif new_conf == existing_conf and existing_sev != new_sev:
        # Equal confidence: higher severity wins (user safety over precision, D-15)
        new_severity_rank = SEVERITY_RANK.get(new_sev, 0)
        old_severity_rank = SEVERITY_RANK.get(existing_sev, 0)
        if new_severity_rank > old_severity_rank:
            existing["severity"] = new_sev
            severity_changed = True

    # Add conflict_note when severity changed (D-16)
    if severity_changed:
        new_conf_label = new_record.get("confidence", "unknown")
        existing["conflict_note"] = (
            f"Severity conflict: original source ({original_conf_label}) rated {original_sev}; "
            f"new source ({new_conf_label}) rated {new_sev}. "
            f"Resolution: {existing['severity']} (per D-15 rules)."
        )


def load_checkpoint() -> dict:
    """Load checkpoint.json or return fresh checkpoint state."""
    if CHECKPOINT_PATH.exists():
        with open(CHECKPOINT_PATH, encoding="utf-8") as f:
            return json.load(f)
    return {
        "stage0_complete": False,
        "stage1_complete": False,
        "stage2_complete": False,
        "stage3_gap_report_complete": False,
        "stage3_compile_complete": False,
        "stage3_verify_complete": False,
        "hard_floor_passed": False,
        "human_spot_check_passed": False,
    }


def save_checkpoint(checkpoint: dict) -> None:
    """Persist checkpoint state to disk atomically (D-08)."""
    save_json_atomic(checkpoint, CHECKPOINT_PATH)
