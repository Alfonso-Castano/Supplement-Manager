---
phase: "00"
plan: "04"
status: complete
completed: "2026-05-07"
---

# 00-04 Summary: Stage 3 — Gap Analysis + SQLite Compilation

## What was built

`database/stackwise.sqlite` — the production database for the StackWise app. Three tables: `interactions`, `ingredients`, `metadata`. All 5 REQs pass. Human spot-check passed.

## Record counts

| Source | Count |
|--------|-------|
| Total records in interactions.json | 65 |
| High confidence | 8 |
| Medium confidence | 55 |
| Low confidence (excluded from SQLite) | 2 |
| **Production records in SQLite** | **63** |

### By severity (SQLite)
| Severity | Count |
|----------|-------|
| critical | 5 |
| advisory | 58 |

### By interaction_type (SQLite)
| Type | Count |
|------|-------|
| unsafe_combination | 48 |
| synergy | 9 |
| absorption_competition | 5 |
| timing_conflict | 1 |

## SQLite row counts

| Table | Rows |
|-------|------|
| interactions | 63 |
| ingredients | 70 |
| metadata | 1 (db_version=1.0.0, date_built=2026-05-06) |

## Gap report summary

- Well-covered (5+ records): 6 compounds
- Partially covered (1–4 records): 64 compounds
- Not covered (0 records): 0 compounds
- Hard floor check (D-10): **PASS**

## Gap-filling compounds (Stage 3 additions)

31 records existed after Stage 2. 34 new records were added during Stage 3 gap-filling to meet the hard floor requirement for all 70 target compounds. The 37 compounds that had 0 medium+ records before gap-fill:

**Supplements (28):** probiotic, ashwagandha, vitamin_a, collagen, biotin, folic_acid, vitamin_b6, vitamin_b_complex, berberine, alpha_lipoic_acid, valerian, black_cohosh, echinacea, glucosamine, chondroitin, saw_palmetto, rhodiola_rosea, elderberry, creatine, nac, selenium, copper, phosphatidylserine, lions_mane, iodine, niacin_vitamin_b3, nmn, chromium

**Medications (9):** lisinopril, amlodipine, metoprolol, gabapentin, escitalopram, bupropion, semaglutide, amoxicillin, montelukast

Two compounds required PubMed citations due to no NIH ODS or MSK pages:
- `lions_mane`: PMID 31842490 (mushroom platelet study, Nutrients 2019)
- `nmn`: PMID 35527512 (NMN renal transport / OCT2 study, Drug Metab Dispos 2022)

Raw abstracts saved to `research/raw/pubmed/`.

## Scripts produced

| Script | Purpose |
|--------|---------|
| `research/scripts/stage3_validate.py` | Gap analysis — generates gap_report.md |
| `research/scripts/stage3_compile.py` | SQLite compilation — reads interactions.json, writes stackwise.sqlite |

## Human spot-check

10 randomly selected production records reviewed by user. No corrections required. All records had specific clinical effects, actionable suggested_action fields, and valid citation URLs from approved sources (ods.od.nih.gov, mskcc.org).

## Test results

```
36 passed in 0.12s
```

All 36 tests pass: 5 test_database.py + 17 test_canonical.py + 14 test_pipeline.py. No failures, no skips.

## Checkpoint flags

All 8 flags set to `true`:
- stage0_complete, stage1_complete, stage2_complete
- stage3_gap_report_complete, stage3_compile_complete, stage3_verify_complete
- hard_floor_passed, human_spot_check_passed
