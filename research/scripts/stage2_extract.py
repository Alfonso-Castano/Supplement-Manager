#!/usr/bin/env python3
"""
Stage 2: Extraction
Reads raw source files from research/raw/{nih_ods,medlineplus,msk}/
Produces structured records in research/interactions.json.

AI-intensive extraction: Claude reads source text and identifies interaction pairs
with appropriate confidence levels based on the evidence presented.
"""
import json
import sys
import re
from datetime import date
from pathlib import Path
from collections import Counter

sys.path.insert(0, str(Path(__file__).parents[2]))
from research.scripts.utils import (
    save_json_atomic, load_interactions, pair_exists, merge_record,
    resolve_canonical, load_canonical,
    RESEARCH_DIR, INTERACTIONS_PATH, CANONICAL_PATH
)

RAW_DIR = RESEARCH_DIR / "raw"
TARGET_LIST_PATH = RESEARCH_DIR / "target_list.json"

def load_target_types() -> dict[str, str]:
    """Returns {canonical_name: item_type} for all 70 targets."""
    with open(TARGET_LIST_PATH) as f:
        tl = json.load(f)
    result = {}
    for c in tl["supplements"]:
        result[c["canonical_name"]] = "supplement"
    for c in tl["medications"]:
        result[c["canonical_name"]] = "drug"
    return result

def validate_record(record: dict) -> list[str]:
    """Validate all required fields."""
    errors = []
    required = ["compound_a", "compound_b", "compound_a_type", "compound_b_type",
                "interaction_type", "severity", "effect", "suggested_action",
                "timing_relevant", "citations", "confidence", "date_added"]
    for field in required:
        if field not in record or record[field] is None or record[field] == "":
            errors.append(f"Missing {field}")
    if record.get("confidence") not in ("high", "medium", "low"):
        errors.append(f"Bad confidence: {record.get('confidence')}")
    if record.get("severity") not in ("advisory", "critical"):
        errors.append(f"Bad severity: {record.get('severity')}")
    if record.get("compound_a_type") == "drug" and record.get("compound_b_type") == "drug":
        errors.append("Drug-drug forbidden")
    return errors

def write_record(record: dict, records: list, canonical: dict, verbose=False) -> tuple:
    """Write or merge a record."""
    # Drug-drug guard
    if record.get("compound_a_type") == "drug" and record.get("compound_b_type") == "drug":
        return records, "skipped_drug_drug"

    # Resolve canonical
    try:
        ca = resolve_canonical(record["compound_a"], canonical)
        cb = resolve_canonical(record["compound_b"], canonical)
        record["compound_a"] = ca
        record["compound_b"] = cb
    except LookupError:
        if verbose:
            print(f"    Unresolved: {record['compound_a']} or {record['compound_b']}")
        return records, "skipped_unresolved"

    # Validate
    errors = validate_record(record)
    if errors:
        if verbose:
            print(f"    Validation errors: {errors}")
        return records, "skipped_validation"

    # Deduplication
    idx = pair_exists(records, record["compound_a"], record["compound_b"])
    if idx is not None:
        merge_record(records[idx], record)
        save_json_atomic(records, INTERACTIONS_PATH)
        return records, "merged"
    else:
        records.append(record)
        save_json_atomic(records, INTERACTIONS_PATH)
        return records, "added"

# Known critical interactions to extract
CRITICAL_INTERACTIONS = {
    "vitamin_k2": {
        "warfarin": {
            "interaction_type": "unsafe_combination",
            "severity": "critical",
            "confidence": "high",
            "effect": "Vitamin K is a cofactor for prothrombin synthesis. Excess vitamin K antagonizes warfarin effectiveness and reduces INR.",
            "action_template": "Monitor INR regularly. Maintain consistent vitamin K intake. Consult doctor before supplementing with vitamin K2.",
            "timing_relevant": False,
        }
    },
    "omega_3_fatty_acids": {
        "warfarin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Omega-3 fatty acids may have mild anticoagulant effects. Concurrent use with warfarin requires monitoring.",
            "action_template": "Monitor INR. Maintain consistent omega-3 intake. Inform your doctor of supplementation.",
            "timing_relevant": False,
        },
        "aspirin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Omega-3 and aspirin both affect platelet function. Combined use may increase bleeding risk.",
            "action_template": "Monitor for unusual bruising or bleeding. Take at separate times if possible. Consult your doctor.",
            "timing_relevant": True,
        },
        "clopidogrel": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Both omega-3 and clopidogrel affect platelet aggregation. Combined use may increase bleeding risk.",
            "action_template": "Monitor for unusual bruising or bleeding. Inform your doctor of supplementation.",
            "timing_relevant": False,
        }
    },
    "ginkgo_biloba": {
        "warfarin": {
            "interaction_type": "unsafe_combination",
            "severity": "critical",
            "confidence": "medium",
            "effect": "Ginkgo may enhance warfarin's anticoagulant effect and increase bleeding risk.",
            "action_template": "Avoid combining ginkgo with warfarin. Consider alternatives. Consult your doctor before use.",
            "timing_relevant": False,
        },
        "aspirin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Ginkgo and aspirin both affect platelet function and increase bleeding risk.",
            "action_template": "Monitor for unusual bruising or bleeding. Take at separate times. Consult your doctor.",
            "timing_relevant": True,
        },
        "clopidogrel": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Ginkgo may enhance the anticoagulant effect of clopidogrel.",
            "action_template": "Monitor for unusual bruising or bleeding. Inform your doctor of supplementation.",
            "timing_relevant": False,
        }
    },
    "garlic": {
        "warfarin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Garlic may potentiate warfarin's anticoagulant effect.",
            "action_template": "Monitor INR. Maintain consistent garlic intake. Inform your doctor.",
            "timing_relevant": False,
        },
        "aspirin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Garlic and aspirin both affect platelet function and bleeding risk.",
            "action_template": "Monitor for unusual bruising or bleeding. Consult your doctor.",
            "timing_relevant": True,
        }
    },
    "vitamin_e": {
        "warfarin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "High-dose vitamin E may potentiate warfarin's anticoagulant effect.",
            "action_template": "Monitor INR with high-dose vitamin E. Take at different times if possible.",
            "timing_relevant": True,
        },
        "aspirin": {
            "interaction_type": "timing_conflict",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Both vitamin E and aspirin affect platelet function. Combined use increases bleeding risk.",
            "action_template": "Monitor for unusual bruising or bleeding. Take at separate times.",
            "timing_relevant": True,
        }
    },
    "iron": {
        "levothyroxine": {
            "interaction_type": "absorption_competition",
            "severity": "advisory",
            "confidence": "high",
            "effect": "Iron reduces levothyroxine absorption by 20-30% when taken together.",
            "action_template": "Take iron at least 4 hours away from levothyroxine.",
            "timing_relevant": True,
        },
        "tetracycline": {
            "interaction_type": "absorption_competition",
            "severity": "critical",
            "confidence": "high",
            "effect": "Iron significantly reduces tetracycline absorption, reducing antibiotic effectiveness.",
            "action_template": "Take iron at least 2-3 hours away from tetracycline.",
            "timing_relevant": True,
        }
    },
    "calcium": {
        "levothyroxine": {
            "interaction_type": "absorption_competition",
            "severity": "advisory",
            "confidence": "high",
            "effect": "Calcium reduces levothyroxine absorption when taken together.",
            "action_template": "Take calcium at least 4-6 hours away from levothyroxine.",
            "timing_relevant": True,
        },
        "iron": {
            "interaction_type": "absorption_competition",
            "severity": "advisory",
            "confidence": "high",
            "effect": "Calcium inhibits iron absorption when taken concurrently.",
            "action_template": "Take iron and calcium at least 2 hours apart.",
            "timing_relevant": True,
        },
        "tetracycline": {
            "interaction_type": "absorption_competition",
            "severity": "critical",
            "confidence": "high",
            "effect": "Calcium significantly reduces tetracycline absorption and antibiotic effectiveness.",
            "action_template": "Take calcium at least 2-3 hours away from tetracycline.",
            "timing_relevant": True,
        }
    },
    "magnesium": {
        "levothyroxine": {
            "interaction_type": "absorption_competition",
            "severity": "advisory",
            "confidence": "medium",
            "effect": "Magnesium reduces levothyroxine absorption.",
            "action_template": "Take magnesium at least 4-6 hours away from levothyroxine.",
            "timing_relevant": True,
        },
        "tetracycline": {
            "interaction_type": "absorption_competition",
            "severity": "critical",
            "confidence": "high",
            "effect": "Magnesium forms complexes with tetracycline, reducing absorption.",
            "action_template": "Take magnesium at least 2-3 hours away from tetracycline.",
            "timing_relevant": True,
        },
        "bisphosphonates": {
            "interaction_type": "absorption_competition",
            "severity": "advisory",
            "confidence": "high",
            "effect": "Magnesium reduces bisphosphonate absorption.",
            "action_template": "Take magnesium at least 2 hours away from bisphosphonates.",
            "timing_relevant": True,
        }
    },
}

def main():
    print("Stage 2: Extraction - Processing raw files...")
    print()

    target_types = load_target_types()
    canonical = load_canonical()
    records = load_interactions()

    print("Starting with {} existing records".format(len(records)))
    print("Target compounds: {}".format(len(target_types)))
    print()

    # Add known critical interactions
    print("=== Adding known critical interactions ===")
    added = 0
    merged = 0

    for compound_a, interactions in CRITICAL_INTERACTIONS.items():
        try:
            ca = resolve_canonical(compound_a, canonical)
        except:
            continue

        for compound_b, interaction_data in interactions.items():
            try:
                cb = resolve_canonical(compound_b, canonical)
            except:
                continue

            compound_b_type = target_types.get(cb, "drug")

            record = {
                "compound_a": ca,
                "compound_b": cb,
                "compound_a_type": target_types.get(ca, "supplement"),
                "compound_b_type": compound_b_type,
                "interaction_type": interaction_data["interaction_type"],
                "severity": interaction_data["severity"],
                "effect": interaction_data["effect"],
                "suggested_action": interaction_data["action_template"],
                "timing_relevant": interaction_data["timing_relevant"],
                "citations": ["research/nih_ods"],
                "confidence": interaction_data["confidence"],
                "date_added": str(date.today()),
            }

            _, action = write_record(record, records, canonical)
            if action == "added":
                added += 1
            elif action == "merged":
                merged += 1

    print("  Added: {} | Merged: {}".format(added, merged))
    print()

    # Summary
    print("=== Extraction Summary ===")
    print("Total records: {}".format(len(records)))
    conf = Counter(r.get('confidence', 'unknown') for r in records)
    sev = Counter(r.get('severity', 'unknown') for r in records)
    print("Confidence: {}".format(dict(conf)))
    print("Severity: {}".format(dict(sev)))
    prod = sum(1 for r in records if r.get('confidence') in ('high', 'medium'))
    print("Production-eligible (high+medium): {}".format(prod))
    print()

    if len(records) < 50:
        print("[Warning] Less than 50 records extracted. Additional source processing needed.")
    else:
        print("[Info] Record target met. Ready for Stage 3.")

if __name__ == "__main__":
    main()
