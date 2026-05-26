---
current_phase: "5"
current_phase_name: "Functional Onboarding"
current_plan: "0 of 5"
total_phases: "10"
status: "in_progress"
progress: "[████░░░░░░] 40%"
last_activity: "2026-05-25"
phase_count: 10
plan_count: 27
summary_count: 15
---

## Project Reference

See: SPEC.md (full project specification)

**Core value:** Trustworthy supplement/medication interaction analysis paired with a personalized smart schedule and reminders
**Current focus:** Phase 4 — Smart Schedule (priority-rule scheduling algorithm + schedule tab)

---

## Current Position

Phase: 4 of 10 (Smart Schedule) — COMPLETE
Plan: 4 of 4
Status: Phase 4 complete. 50/50 tests passing, Mac verified 2026-05-24. Deep review fixes applied (8 commits) and verified. All 4 UAT tests passed. Simulator golden path confirmed.
Last activity: 2026-05-24 — Deep review fix verification complete on Mac (50/50 tests, commit fb88540).
Progress: [████░░░░░░] 40%

---

## Accumulated Context

### Decisions

**Phase 0 (locked):** D-01 … D-20 — see `.planning/phases/00-database-build/00-CONTEXT.md`.

**Phase 1 (locked):** D-01 (iOS 17 min) … D-05, D-21 (Windows/Mac split) — see `.planning/phases/01-project-foundation/01-CONTEXT.md`.

**Phase 2 (locked, executed via `~/.claude/plans/stackwise-phase-2-lovely-bachman.md`):**
- D-22: SQLite access via raw `sqlite3` C API wrapped in `@Observable final class` — no GRDB, no FMDB.
- D-23: `UserProfile` is a singleton (`fetchLimit = 1`); `UserProfileStore` enum is the only writer.
- D-24: Onboarding source of truth is Core Data `UserProfile.onboardingComplete`; `AppState.onboardingComplete` mirrors it at launch.
- D-25: Unmatched stack items are saved with `isInDatabase = false` and the user-entered label verbatim. Phase 3 surfaces them in the "not-in-database" group on the analysis screen.

**Phase 4 (locked 2026-05-15, in `.planning/phases/04-smart-schedule/04-CONTEXT.md`):**
- D-36: `IngredientRepository` extended with `timingProperties(for slug:) -> TimingProperties` — no new repository.
- D-37: Schedule persisted to Core Data `ScheduledDose`. `ScheduleStore` (@Observable) writes doses on recompute, caches `ScheduleResult` in memory for the view.
- D-38: Dirty-flag recompute pattern (same as `AnalysisStore`). `invalidate()` called from `AddItemView.onSaved`.
- D-39: `ScheduleView` is a `List` with 3 sections. Section headers show block name + time window from `UserProfile`. Item rows show label, dosage, conflict/synergy badges.
- D-40: 4 scheduling rules — sufficient for all 5 success criteria. No 5th rule.
- D-41: 4 sub-plans: 04-01 (data + skeleton), 04-02 (algorithm + tests), 04-03 (UI), 04-04 (wire + Mac batch).
- D-42: Mac handoff batched once at Phase 4 end.

**Phase 3 (locked 2026-05-14, in `.planning/phases/03-interaction-analysis/03-CONTEXT.md`):**
- D-26: Second `@Observable final class InteractionRepository` opens its own read-only handle to `stackwise.sqlite`. Phase 2's `IngredientRepository` is untouched except for one nit fix (CF-6).
- D-27: Analysis runs lazily with dirty-flag invalidation. `AnalysisStore` (`@Observable`) caches the last result; stack mutations call `invalidate()`; first read after invalidation recomputes.
- D-28: Analysis screen is a NavigationStack push from `StackListView` toolbar. The placeholder at `Features/Stack/AnalysisView.swift` is the implementation site. The locked 3-tab shell is preserved.
- D-29: Analysis results live in memory only — no Core Data entity. Deterministic from stack + bundled DB; recomputed on launch.
- D-30: Severity maps directly from DB `severity` column (`advisory` / `critical`) — no translation layer.
- D-31: "Positive insights" = rows where `interaction_type = 'synergy'` (13 rows in current DB, all advisory severity).
- D-32: Direction handling — directional pairs are matched only in the listed `(compound_a, compound_b)` order; bidirectional pairs match either order. Phase 3's pairwise SQL enforces this in the WHERE clause.
- D-33: Mac handoff batched at end of Phase 3 (one Xcode add-to-target + build + simulator pass across all four plans).

**Plan 03-02 (executed 2026-05-15):**
- D-34: Typed CoreData accessors (`labelValue`, `activeIngredientValue`, direct `isInDatabase`) used instead of KVC in `AnalysisStore.recompute()`.
- D-35: `StackWiseApp` converted to custom `init()` pattern (State(initialValue:)) so `AnalysisStore` can capture the same `InteractionRepository` instance.

### Pending Todos

None.

### Blockers / Concerns

None.

---

## Deferred Items

- Source-of-truth drift between `database/stackwise.sqlite` (build artifact) and `StackWise/stackwise.sqlite` (bundled) — flagged in Phase 3 handoff; not yet addressed.
- `hasSynergy(forSlug:)` on `AnalysisResults` exists but not yet wired to a green badge on stack rows — deferred polish item for Phase 4+.
- `timing_relevant` / `timing_window_hours` fields are captured in `InteractionPair` but not yet surfaced in UI — Phase 4 (Smart Schedule) will use these.
- `displayName(_:)` slug → display name conversion lives in `AnalysisView` locally — may be centralized in a `LabelService` in Phase 4+ if needed elsewhere.

---

## Session Continuity

Last session: 2026-05-25
Stopped at: Phase 5 planning complete (2026-05-25). 5 plans written across 4 waves (00, 01, 02+03 parallel, 04).
Resume: Execute Phase 5 — start with 05-00-PLAN.md (Wave 0 test stubs).
