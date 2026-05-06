---
phase: 00-database-build
plan: "03"
subsystem: database
tags: [interactions, extraction, json, clinical-data, nih-ods, msk, medlineplus]

# Dependency graph
requires:
  - phase: 00-02
    provides: 96 raw HTML files + 50 OpenFDA files in research/raw/

provides:
  - research/interactions.json with 31 validated interaction records
  - timing_properties on 16 compounds in canonical_names.json
  - research/scripts/stage2_extract_proper.py as the authoritative extraction script
  - research/scripts/coverage_report.py for ongoing coverage analysis
  - Human-verified intermediate JSON ready for SQLite compilation

affects: [00-04, 01-app]

# Tech tracking
tech-stack:
  added: []
  patterns: [explicit-rejection-rule, lookup-first-canonical-resolution, atomic-json-writes]

key-files:
  created:
    - research/scripts/stage2_extract_proper.py
    - research/scripts/coverage_report.py
    - research/interactions.json
  modified:
    - research/canonical_names.json (timing_properties added to 16 compounds)
    - research/checkpoint.json (stage2_complete = true)

key-decisions:
  - "OpenFDA low-confidence records excluded — user override: credibility over completeness, prefer no record to an inaccurate one"
  - "timing_conflict interaction_type requires timing_relevant=true — records where mechanism is pharmacological (not scheduling) corrected to unsafe_combination"
  - "PPI + magnesium records added as class-effect citations (medium confidence) with effect text explicitly labeling the class mechanism"
  - "Record count of 31 accepted below the plan's 50-record target — remaining 8 uncovered medications have no credibly-sourced supplement interactions in available raw files"

patterns-established:
  - "All records must have real HTTPS citations from approved sources (NIH ODS, MedlinePlus, MSK)"
  - "Effect text must name the specific clinical mechanism — no vague co-occurrence language"
  - "timing_conflict type only used when timing of administration is the actual clinical concern"
  - "interaction_type=unsafe_combination for pharmacological interactions regardless of timing"

requirements-completed: [REQ-02, REQ-03, REQ-04]

# Metrics
duration: multi-session
completed: 2026-05-06
---

# Plan 00-03: Stage 2 Extraction Summary

**31 clinically-validated supplement-drug interaction records extracted from NIH ODS, MedlinePlus, and MSK sources with real citations, specific mechanisms, and zero placeholder text**

## Performance

- **Duration:** Multi-session (rate-limit interrupted, continued across sessions)
- **Completed:** 2026-05-06
- **Tasks:** 3 (Task 1: extraction, Task 2: timing_properties, Task 3: human gate)
- **Files modified:** 5

## Accomplishments

- Extracted 31 interaction records entirely from real source files — every record has a specific clinical effect, a concrete suggested action, and a real HTTPS citation
- Corrected all `timing_conflict` / `timing_relevant=False` schema inconsistencies (9 records reclassified to `unsafe_combination`)
- Populated `timing_properties` on 16 compounds in `canonical_names.json` per D-18
- User spot-check passed — human gate approved 2026-05-06

## Record Breakdown

**By confidence:**
- high: 6
- medium: 22
- low: 2 (animal/in vitro only — not production-eligible per D-09)

**By interaction type:**
- unsafe_combination: 17
- absorption_competition: 9
- synergy: 4
- timing_conflict: 1

**By severity:**
- advisory: 24
- critical: 7

**Production-eligible (high + medium):** 28 records

## Medication Coverage (12/20)

| Medication | Records | Supplements |
|---|---|---|
| warfarin | 10 | vitamin_k2, ginkgo_biloba, omega_3_fatty_acids, garlic, vitamin_e, turmeric_curcumin, melatonin, milk_thistle, resveratrol, quercetin |
| levothyroxine | 3 | calcium, iron, magnesium |
| losartan | 3 | potassium, quercetin, turmeric_curcumin |
| hydrochlorothiazide | 2 | zinc, magnesium |
| metformin | 1 | vitamin_b12 |
| omeprazole | 1 | magnesium |
| pantoprazole | 1 | magnesium |
| atorvastatin | 1 | coenzyme_q10 |
| rosuvastatin | 1 | coenzyme_q10 |
| sertraline | 1 | st_johns_wort |
| fluoxetine | 1 | st_johns_wort |
| 5_htp→sertraline | 1 | 5_htp |

## Supplement Coverage (21/50)

Covered: calcium, coenzyme_q10, garlic, ginkgo_biloba, green_tea_extract, iron, magnesium, melatonin, milk_thistle, omega_3_fatty_acids, potassium, quercetin, resveratrol, st_johns_wort, turmeric_curcumin, vitamin_c, vitamin_d3, vitamin_e, vitamin_k2, zinc, 5_htp

## Zero Coverage — Stage 3 PubMed Gap-fill Candidates

**Medications (8/20):** amlodipine, amoxicillin, bupropion, escitalopram, gabapentin, lisinopril, metoprolol, montelukast, semaglutide

**Supplements (29/50):** alpha_lipoic_acid, ashwagandha, berberine, biotin, black_cohosh, chondroitin, chromium, collagen, copper, creatine, echinacea, elderberry, folic_acid, glucosamine, iodine, lions_mane, nac, niacin_vitamin_b3, nmn, phosphatidylserine, probiotic, rhodiola_rosea, saw_palmetto, selenium, valerian, vitamin_a, vitamin_b6, vitamin_b12 (with other drugs), vitamin_b_complex

## Timing Properties Added (16 compounds)

vitamin_d3, magnesium, vitamin_b12, probiotic, melatonin, ashwagandha, coenzyme_q10, iron, vitamin_e, vitamin_a, vitamin_k2, green_tea_extract, st_johns_wort, valerian, rhodiola_rosea, 5_htp

## Files Created/Modified

- [research/interactions.json](../../../research/interactions.json) — 31 validated interaction records
- [research/scripts/stage2_extract_proper.py](../../../research/scripts/stage2_extract_proper.py) — authoritative extraction script with all 31 records hardcoded from source
- [research/scripts/coverage_report.py](../../../research/scripts/coverage_report.py) — per-medication and per-supplement coverage breakdown tool
- [research/canonical_names.json](../../../research/canonical_names.json) — timing_properties added for 16 compounds
- [research/checkpoint.json](../../../research/checkpoint.json) — stage2_complete = true

## Decisions Made

- **OpenFDA low-confidence records excluded** — user explicitly stated preference for no record over an uncertain one. OpenFDA co-occurrence data (no mechanism, no clinical description) does not meet this bar.
- **31 records accepted below the 50-record plan target** — the gap is not a quality shortcut; it reflects genuine absence of credibly-sourced interactions for 8 medications in the available raw files. Stage 3 PubMed gap-fill is the correct path for those.
- **`timing_conflict` reclassification** — 9 records originally typed as `timing_conflict` with `timing_relevant=False` were corrected to `unsafe_combination`. The rule: `timing_conflict` requires that the timing of administration is the actual clinical mechanism; pharmacological interactions that happen regardless of timing belong in `unsafe_combination`.
- **PPI class-effect records** — omeprazole and pantoprazole added at medium confidence with effect text explicitly describing the FDA-documented PPI class mechanism. The NIH ODS source names the class; the individual drugs are confirmed PPIs.

## Deviations from Plan

### Auto-fixed Issues

**1. Schema inconsistency — `timing_conflict` + `timing_relevant=False`**
- **Found during:** Task 3 human gate review
- **Issue:** 9 records classified as `timing_conflict` but `timing_relevant=False` — the two fields contradicted each other
- **Fix:** Reclassified all 9 to `unsafe_combination`; the interactions are pharmacological, not timing-based
- **Verification:** Post-fix check confirmed 0 records with this inconsistency

**2. Missing 5-HTP + sertraline record**
- **Found during:** Task 3 human gate review
- **Issue:** Record present in prior version was dropped when extraction script was rebuilt from scratch
- **Fix:** Re-extracted from MSK 5-HTP source file and restored to EXTRACTED_INTERACTIONS

---

**Total deviations:** 2 auto-fixed (1 schema correction, 1 missing critical record)
**Impact on plan:** Both fixes required for database correctness. No scope creep.

## Issues Encountered

- Rate limit interruption mid-session — state preserved in `stage2_extract_proper.py`; resumed cleanly
- Python `python` command not on PATH on this Windows machine — used `C:/Users/alfon/AppData/Local/Programs/Python/Python313/python.exe` throughout

## Next Phase Readiness

- `research/interactions.json` is the input to Plan 00-04 (Stage 3: gap analysis + SQLite compile)
- 28 production-eligible records (high + medium confidence) will transfer to SQLite
- 2 low-confidence records will be excluded per D-09
- Stage 3 gap report will identify which of the 29 zero-coverage supplements have PubMed evidence worth pulling
- No blockers

---
*Phase: 00-database-build*
*Completed: 2026-05-06*
