#!/usr/bin/env python3
"""
Stage 1: OpenFDA Adverse Events Collection
Queries OpenFDA drug/event endpoint for each target supplement.
All results get confidence='low' — used only as co-occurrence signals (D-09).
Requires OPENFDA_API_KEY environment variable.
"""
import json
import os
import sys
import time
from pathlib import Path
import requests

sys.path.insert(0, str(Path(__file__).parents[2]))
from research.scripts.utils import already_collected as _already_collected
from research.scripts.utils import load_checkpoint, save_checkpoint

RESEARCH_DIR = Path("research")
RAW_OPENFDA_DIR = RESEARCH_DIR / "raw" / "openfda"
TARGET_LIST_PATH = RESEARCH_DIR / "target_list.json"
CANONICAL_PATH = RESEARCH_DIR / "canonical_names.json"
OPENFDA_BASE = "https://api.fda.gov/drug/event.json"

HEADERS = {"User-Agent": "StackWise-Research/1.0 (supplement interaction database)"}


def get_api_key() -> str:
    key = os.environ.get("OPENFDA_API_KEY", "")
    if not key:
        print("WARNING: OPENFDA_API_KEY not set. Using no-key limit (1,000 req/day).")
    return key


def build_query_variants(canonical_name: str, aliases: list) -> list:
    """Build list of query strings for this supplement (canonical + top aliases).
    OpenFDA medicinalproduct values are user-reported — need multiple variants."""
    # Use canonical name (replace underscores with spaces, uppercase)
    variants = [canonical_name.replace("_", " ").upper()]
    # Add top 3 aliases (most common consumer names)
    for alias in aliases[:3]:
        variants.append(alias.upper())
    return list(dict.fromkeys(variants))  # deduplicate, preserve order


def fetch_openfda(name_variant: str, api_key: str, session: requests.Session) -> list:
    """Query OpenFDA for a supplement name variant. Returns list of drug reports."""
    params = {
        "search": f'patient.drug.medicinalproduct:"{name_variant}"',
        "limit": 100,
    }
    if api_key:
        params["api_key"] = api_key

    try:
        resp = session.get(OPENFDA_BASE, params=params, headers=HEADERS, timeout=30)
        if resp.status_code == 404:
            return []  # No results for this query
        resp.raise_for_status()
        data = resp.json()
        return data.get("results", [])
    except Exception as e:
        print(f"  ERROR querying OpenFDA for '{name_variant}': {e}")
        return []


def extract_co_occurrences(reports: list) -> list:
    """Extract multi-drug adverse event reports (co-occurrence signals).
    Only reports where patient.drug has 2+ entries are useful (D-05 co-occurrence detection)."""
    co_occurrences = []
    for report in reports:
        drugs = report.get("patient", {}).get("drug", [])
        if len(drugs) > 1:
            reactions = [r.get("reactionmeddrapt", "") for r in report.get("patient", {}).get("reaction", [])]
            co_occurrences.append({
                "drugs": [d.get("medicinalproduct", "").upper() for d in drugs],
                "reactions": reactions,
                "report_id": report.get("safetyreportid", ""),
            })
    return co_occurrences


def already_collected_openfda(canonical_name: str) -> bool:
    return _already_collected(RAW_OPENFDA_DIR, f"{canonical_name}_openfda", extension=".json")


if __name__ == "__main__":
    RAW_OPENFDA_DIR.mkdir(parents=True, exist_ok=True)

    with open(TARGET_LIST_PATH) as f:
        target_list = json.load(f)
    with open(CANONICAL_PATH) as f:
        canonical = json.load(f)

    api_key = get_api_key()
    session = requests.Session()

    print("=== Stage 1: OpenFDA Collection ===")
    collected = []
    skipped = []
    errors = []

    for compound in target_list["supplements"]:
        name = compound["canonical_name"]

        if already_collected_openfda(name):
            skipped.append(name)
            print(f"  SKIP (exists): {name}_openfda.json")
            continue

        raw_val = canonical.get(name, [])
        aliases = raw_val.get("aliases", []) if isinstance(raw_val, dict) else raw_val
        variants = build_query_variants(name, aliases)

        all_reports = []
        for variant in variants:
            print(f"  Querying OpenFDA: '{variant}'")
            reports = fetch_openfda(variant, api_key, session)
            all_reports.extend(reports)
            time.sleep(0.3)  # 240 req/min limit; 0.3s = ~200 req/min (safe margin)

        co_occurrences = extract_co_occurrences(all_reports)

        # Save: include query metadata + co_occurrences
        output = {
            "canonical_name": name,
            "query_variants": variants,
            "total_reports_fetched": len(all_reports),
            "co_occurrence_reports": len(co_occurrences),
            "co_occurrences": co_occurrences,
            "confidence": "low",  # D-09: all OpenFDA data is low confidence
            "note": "Co-occurrence signals only. Not a confirmed interaction source. Verify against NIH ODS, MedlinePlus, or PubMed before using.",
        }

        out_path = RAW_OPENFDA_DIR / f"{name}_openfda.json"
        tmp = out_path.with_suffix(".tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2)
        os.replace(tmp, out_path)

        collected.append(name)

    print(f"\n=== OpenFDA Collection Complete ===")
    print(f"Collected: {len(collected)}")
    print(f"Skipped (existed): {len(skipped)}")
    print(f"Errors: {len(errors)}")
    print(f"Files in research/raw/openfda/: {len(list(RAW_OPENFDA_DIR.glob('*.json')))}")
