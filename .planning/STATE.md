---
current_phase: "0"
current_phase_name: "Database Build"
current_plan: "3 of 4"
total_phases: "10"
status: "in_progress"
progress: "[██░░░░░░░░] 6%"
last_activity: "2026-05-07"
phase_count: 10
plan_count: 7
summary_count: 2
---

## Project Reference

See: SPEC.md (full project specification)

**Core value:** Trustworthy supplement/medication interaction analysis paired with a personalized smart schedule and reminders  
**Current focus:** Phase 0 — Database Build (pre-app, first deliverable)

---

## Current Position

Phase: 0 of 10 (Database Build)  
Plan: 3 of 4 complete in current phase  
Status: In progress  
Last activity: 2026-05-06 — Plan 00-03 (Stage 2 Extraction) complete; 31 validated interaction records + timing_properties on 16 compounds  
Progress: [██░░░░░░░░] 6%

---

## Accumulated Context

### Decisions

**Phase 0 (locked):**
- D-01: Working format is JSON (Stages 1–2); compile to SQLite after manual spot-check
- D-02: Single combined `stackwise.sqlite` (interactions + ingredients + metadata)
- D-03: metadata table with db_version (semantic) + date_built (ISO string)
- D-04: Target list researched by Claude, user-approved, saved as `research/target_list.json`
- D-05: Stage 1 collects target compounds first; broadens only if time allows
- D-06: Collect top brand-name aliases for all 20 target medications
- D-07: Hybrid execution — automated stages with human gate at each boundary
- D-08: Checkpoint-based multi-session (each stage reads prior stage output from disk)
- D-09: Minimum confidence for production records: medium and above
- D-10: Hard floor — every target compound must have ≥1 medium+ confidence record
- D-11/D-12: 7 baseline action templates in `research/action_templates.json`
- D-13: NIH ODS fact sheet titles as primary canonical name authority (lowercase_underscores)
- D-14: Generic name is canonical for medications; brand names are aliases
- D-15: Higher-confidence source's severity wins; ties favor higher severity; both sources cited
- D-16: `conflict_note` TEXT field added to interactions table when severity conflicts exist
- D-17: `timing_properties` as JSON blob TEXT column in ingredients table
- D-18: Four optional timing fields: requires_food, requires_empty_stomach, preferred_time_of_day, avoid_with_caffeine
- D-19: Regional scope is US retail; include traditional medicine if in approved sources
- D-20: Post-launch updates are on-demand, gap-report driven

### Execution Decisions (Plan 00-02)

- NIH ODS only has 43 HealthProfessional factsheets total — melatonin, CoQ10, ginkgo, St. John's Wort, echinacea, glucosamine, chondroitin, and garlic are NOT covered; MSK/MedlinePlus (NCCIH) fill the gap
- MedlinePlus herb index links to nccih.nih.gov/health/ and ODS Consumer pages (not /druginfo/natural/ as assumed in research)
- 3 compounds completely missing from all HTML sources: vitamin_b_complex (composite product), chondroitin, phosphatidylserine — Stage 3 PubMed gap-fill required
- phosphatidylserine: MSK URL in target_list.json was wrong (404); NCCIH has no dedicated page; only OpenFDA coverage

### Execution Decisions (Plan 00-01)

- Added chromium, resveratrol, quercetin to reach exactly 50 supplements (plan enumerated 47 unique names; all three additions have known drug interactions and NIH ODS/MSK coverage)
- Target list approved by user at D-04 gate with no modifications — scope is now locked
- OPENFDA_API_KEY and NCBI_API_KEY confirmed registered in terminal session (not stored in files per T-0-01)
- pytest 9.0.2 already installed (not a new install)

### Execution Decisions (Plan 00-03)

- OpenFDA low-confidence records excluded — user preference: no record is better than an inaccurate one; co-occurrence data without mechanism doesn't qualify
- 31 records accepted below 50-record plan target — genuine absence of credibly-sourced interactions for 8 medications; Stage 3 PubMed gap-fill is the correct path
- `timing_conflict` type requires `timing_relevant=true` — 9 records reclassified to `unsafe_combination` (pharmacological interactions regardless of timing)
- PPI class-effect records (omeprazole, pantoprazole) added at medium confidence — NIH ODS + FDA communication clearly documents the class mechanism

**Environment constraint (locked):**
- D-21: Developer on Windows 11 — Mac required for all Xcode GUI steps. Primary: personal Mac laptop (4-day window available). Fallback: MacInCloud (~$1/hr) for anything that spills over, and Phase 9 (TestFlight, signing, App Store — ~3–4 hr extended session). All Swift file writing on Windows; Mac only for Xcode GUI, add-to-target, build verification, and simulator testing. See `CLOUD-MAC-WORKFLOW.md` (phase task split) and `MAC-WINDOW-PLAN.md` (4-day schedule) in `.planning/`.

### Pending Todos

- None. Plan 00-03 complete. Next: Plan 00-04 (Stage 3: Gap Analysis + SQLite Compilation).

### Blockers / Concerns

None.

---

## Deferred Items

None carried forward from previous milestone.

---

## Session Continuity

Last session: 2026-05-06  
Stopped at: Completed 00-03-PLAN.md (Stage 2 Extraction); 31 validated interaction records; human gate approved  
Resume file: None — next plan is 00-04-PLAN.md (Stage 3: Gap Analysis + SQLite Compilation)
