---
phase: 00-database-build
plan: "01"
subsystem: database
tags: [python, pytest, json, sqlite, pipeline, canonical-names, tdd]

# Dependency graph
requires: []
provides:
  - "research/target_list.json — approved 50-supplement / 20-medication scope anchor"
  - "research/canonical_names.json — single normalization authority for all 70 compounds"
  - "research/action_templates.json — 7 baseline D-12 suggested-action templates"
  - "research/scripts/utils.py — shared pipeline utilities (atomic write, resumption, canonical resolution, deduplication, conflict resolution)"
  - "research/scripts/stage0_setup.py — idempotent artifact generator"
  - "research/tests/ — pytest suite (31 unit tests passing; 5 integration tests scaffolded for Stage 3)"
  - "research/checkpoint.json — stage0_complete = true"
  - "research/raw/{nih_ods,medlineplus,msk,openfda,pubmed}/ and database/ directories"
affects:
  - "00-02 Stage 1 collection (reads target_list.json, writes to research/raw/)"
  - "00-03 Stage 2 extraction (reads canonical_names.json via resolve_canonical, uses merge_record/pair_exists)"
  - "00-04 Stage 3 compile (activates test_database.py skip markers, reads all artifacts)"

# Tech tracking
tech-stack:
  added: [pytest 9.0.2]
  patterns:
    - "Atomic JSON write via os.replace() on .tmp file (D-08, T-0-02)"
    - "TDD RED/GREEN cycle for pipeline utilities"
    - "Canonical name resolution: key match → alias match → LookupError"
    - "D-15 conflict resolution: higher confidence wins; equal confidence → higher severity wins"
    - "D-16 conflict_note: populated when severity changes during merge"
    - "Idempotent setup script with --force and --verify flags"

key-files:
  created:
    - "research/scripts/utils.py"
    - "research/scripts/stage0_setup.py"
    - "research/scripts/__init__.py"
    - "research/tests/__init__.py"
    - "research/tests/conftest.py"
    - "research/tests/test_canonical.py"
    - "research/tests/test_pipeline.py"
    - "research/tests/test_database.py"
    - "research/target_list.json"
    - "research/canonical_names.json"
    - "research/action_templates.json"
    - "research/checkpoint.json"
  modified: []

key-decisions:
  - "Added chromium, resveratrol, quercetin to reach exactly 50 supplements (plan listed 47 unique names; all three additions have known drug interactions and NIH ODS/MSK coverage)"
  - "Target list approved by user with no modifications at D-04 gate"
  - "API keys registered: OPENFDA_API_KEY and NCBI_API_KEY confirmed set in terminal session"

patterns-established:
  - "save_json_atomic: all JSON writes in the pipeline use .tmp → os.replace() pattern"
  - "already_collected: resumption check at start of every Stage 1 fetch loop"
  - "resolve_canonical: called before every record write in Stage 2 — raises LookupError for unknown compounds"
  - "pair_exists + merge_record: deduplication protocol for Stage 2 interaction records"

requirements-completed: [REQ-04, REQ-05]

# Metrics
duration: 532min
completed: 2026-05-05
---

# Phase 0, Plan 01: Stage 0 Pre-flight Summary

**pytest suite (31 unit tests), shared pipeline utilities (utils.py), and approved 50-supplement / 20-medication JSON data contracts establishing the complete scope anchor and normalization authority for Stages 1-3**

## Performance

- **Duration:** ~532 min (includes human checkpoint pauses for API key registration and D-04 target list review)
- **Started:** 2026-05-05T18:33:02Z
- **Completed:** 2026-05-05T19:05:58Z (wall clock; pauses excluded from active execution)
- **Tasks:** 4 (1 checkpoint:human-action, 2 auto [TDD], 1 checkpoint:human-verify)
- **Files modified:** 14 created, 0 modified

## Accomplishments

- Implemented `research/scripts/utils.py` with all 8 required pipeline functions (save_json_atomic, already_collected, resolve_canonical, load_interactions, pair_exists, merge_record, load_checkpoint, save_checkpoint) — all unit tested and passing
- Generated the approved Stage 0 data contracts: target_list.json (50 supplements + 20 medications), canonical_names.json (70 entries with aliases), action_templates.json (7 D-12 templates) — user reviewed and approved at D-04 gate
- Built test scaffolding: 17 canonical tests + 14 pipeline tests pass green; 5 database integration tests scaffolded with skip markers for Stage 3 activation
- Created folder structure: research/raw/{nih_ods,medlineplus,msk,openfda,pubmed}/, research/scripts/, research/tests/, database/
- Both API keys registered: OPENFDA_API_KEY (OpenFDA) and NCBI_API_KEY (PubMed E-utilities)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create folder structure + verify pytest** — `6483ed8` (chore)
2. **Task 2 RED: Failing tests for utils** — `38c65c5` (test)
3. **Task 2 GREEN: Implement shared pipeline utilities** — `5459236` (feat)
4. **Task 3: Generate Stage 0 working artifacts** — `46b0b05` (feat)

**Plan metadata:** _(this commit)_ (docs: complete plan summary)

_Note: Task 2 followed TDD RED → GREEN cycle with separate commits. Task 4 (D-04 gate) is a human-verify checkpoint — no code commit; approval recorded in this summary._

## Files Created/Modified

- `research/scripts/utils.py` — 8 shared pipeline functions: atomic write, resumption check, canonical resolution, pair lookup, D-15 conflict merge
- `research/scripts/stage0_setup.py` — idempotent artifact generator; `--force` to overwrite, `--verify` to validate counts
- `research/scripts/__init__.py` — package marker (empty)
- `research/tests/conftest.py` — `tmp_canonical` and `sample_record` pytest fixtures
- `research/tests/test_canonical.py` — 17 tests: save_json_atomic (3), already_collected (3), resolve_canonical (11)
- `research/tests/test_pipeline.py` — 14 tests: pair_exists (5), merge_record (9)
- `research/tests/test_database.py` — 5 REQ-01–REQ-05 tests, all `@pytest.mark.skip` until Stage 3
- `research/target_list.json` — 50 supplements + 20 medications with canonical names, categories, NIH ODS/MSK URLs, brand aliases
- `research/canonical_names.json` — 70 canonical entries with alias arrays; `_comment` header key
- `research/action_templates.json` — 7 baseline D-12 templates (IDs 1–7)
- `research/checkpoint.json` — `stage0_complete: true`
- `database/.gitkeep`, `research/raw/*/gitkeep` — directory trackers

## Decisions Made

- **Added chromium, resveratrol, quercetin to reach 50 supplements.** The plan's explicit supplement enumeration contained only 47 unique canonical names despite stating "50 supplements." Chromium (mineral, NIH ODS covered, metformin/berberine interactions), resveratrol (antioxidant, MSK covered, warfarin/statin interactions), and quercetin (botanical, MSK covered, warfarin/antibiotic interactions) were selected — all have documented drug interactions and established sources.
- **User approved target list at D-04 gate with no modifications.** The 50-supplement / 20-medication list is now locked as the permanent scope anchor for Stage 1 collection.
- **API keys confirmed registered.** Both OPENFDA_API_KEY and NCBI_API_KEY are set in the user's terminal session. Key values were not recorded anywhere per T-0-01.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added 3 supplements to reach exactly 50**
- **Found during:** Task 3 (artifact generation)
- **Issue:** The plan's supplement enumeration listed 47 unique canonical names but specified "exactly 50 supplements." The plan's note "nmn fills the 50th slot" was inconsistent with the actual count of 47 unique names in the enumeration.
- **Fix:** Added `chromium` (mineral, ODS), `resveratrol` (antioxidant, MSK), `quercetin` (botanical, MSK) — all with known drug interactions and reputable source coverage. User approved the complete 50-item list at the D-04 gate.
- **Files modified:** `research/scripts/stage0_setup.py`, `research/target_list.json`, `research/canonical_names.json`
- **Verification:** `python research/scripts/stage0_setup.py --verify` reports all checks PASS; JSON validation asserts exactly 50 supplements
- **Committed in:** `46b0b05` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing critical count)
**Impact on plan:** Necessary to meet the stated 50-supplement acceptance criterion. All three additions are clinically relevant with known supplement-drug interactions. Approved by user at D-04 gate.

## Issues Encountered

None beyond the supplement count deviation above.

## User Setup Required

**API keys registered at Task 1 checkpoint.**

Both keys were registered manually by the user:
- `OPENFDA_API_KEY` — registered at https://open.fda.gov/apis/authentication/
- `NCBI_API_KEY` — registered at https://www.ncbi.nlm.nih.gov/account/

Keys are stored in the terminal session environment only. They are **not** written to any file (T-0-01 compliance). Before running Stage 1 collection (Plan 00-02), ensure both environment variables are set.

Verification commands:
```
echo %OPENFDA_API_KEY%
echo %NCBI_API_KEY%
```

## Known Stubs

None. All pipeline functions are fully implemented and tested. JSON artifacts contain real compound data (not placeholder values). `test_database.py` skip markers are intentional scaffolding — they are activated in Plan 00-04 (Stage 3 compile), not stubs.

## Threat Flags

No new threat surface introduced beyond the plan's threat model. API keys are stored in environment variables only (T-0-01 mitigated). All JSON writes use atomic `os.replace()` pattern (T-0-02, T-0-03 mitigated). No network calls in this plan.

## Next Phase Readiness

- **Plan 00-02 (Stage 1 — Collection) is unblocked.** target_list.json is approved; canonical_names.json is pre-populated; folder structure exists; API keys are registered.
- **Blocker check:** OPENFDA_API_KEY and NCBI_API_KEY must be set in terminal before running Stage 1 scripts. Set once at session start.
- **test_database.py** activates automatically in Plan 00-04 when Stage 3 removes the skip markers — no action needed before then.

---
*Phase: 00-database-build*
*Completed: 2026-05-05*

## Self-Check: PASSED

Files verified present:
- research/scripts/utils.py: FOUND
- research/scripts/stage0_setup.py: FOUND
- research/tests/conftest.py: FOUND
- research/tests/test_canonical.py: FOUND
- research/tests/test_pipeline.py: FOUND
- research/tests/test_database.py: FOUND
- research/target_list.json: FOUND
- research/canonical_names.json: FOUND
- research/action_templates.json: FOUND
- research/checkpoint.json: FOUND

Commits verified present:
- 6483ed8: FOUND (chore: folder structure)
- 38c65c5: FOUND (test: RED phase)
- 5459236: FOUND (feat: GREEN phase)
- 46b0b05: FOUND (feat: Stage 0 artifacts)

Test suite: 31 passed, 0 failed, 5 skipped (expected — test_database.py skip markers)
