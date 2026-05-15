---
current_phase: "4"
current_phase_name: "Smart Schedule"
current_plan: "0 of 0"
total_phases: "10"
status: "pending"
progress: "[████░░░░░░] 40%"
last_activity: "2026-05-15"
phase_count: 10
plan_count: 18
summary_count: 15
---

## Project Reference

See: SPEC.md (full project specification)

**Core value:** Trustworthy supplement/medication interaction analysis paired with a personalized smart schedule and reminders
**Current focus:** Phase 4 — Smart Schedule (priority-rule scheduling algorithm + schedule tab)

---

## Current Position

Phase: 4 of 10 (Smart Schedule) — not yet planned
Plan: 0 of 0 (Phase 4 plans not yet written)
Status: Phase 3 verified and complete (2026-05-15). Phase 4 discussion pending.
Last activity: 2026-05-15 — Phase 3 complete. All 4 plans executed on Windows, Mac batch verified: 36 tests passing, simulator golden path confirmed (warfarin+vitamin_k2 critical pair, vitamin_c+iron synergy, Banana extract not-in-DB). Phase 3 closed.
Progress: [███░░░░░░░] 30%

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

- Phase 4 discussion: surface gray areas (scheduling algorithm rules, schedule tab layout, timing_properties usage from DB).
- Phase 4 planning: write `04-CONTEXT.md` and plan files under `.planning/phases/04-smart-schedule/`.

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

Last session: 2026-05-15
Stopped at: Phase 3 verified and closed. Phase 4 not yet discussed or planned.
Resume: Start Phase 4 discussion. Read `.planning/ROADMAP.md` Phase 4 section for goal, requirements (REQ-16, REQ-17), and success criteria before opening the discussion.
