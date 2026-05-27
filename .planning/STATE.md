---
current_phase: "6"
current_phase_name: "Reminders & Today Tab"
current_plan: "2 of 5"
total_phases: "10"
status: "executing"
progress: "[█████░░░░░] 50%"
last_activity: "2026-05-26"
phase_count: 10
plan_count: 32
summary_count: 20
---

## Project Reference

See: SPEC.md (full project specification)

**Core value:** Trustworthy supplement/medication interaction analysis paired with a personalized smart schedule and reminders
**Current focus:** Phase 6 — Reminders & Today Tab (local notifications, block-level check-off interface)

---

## Current Position

Phase: 6 of 10 (Reminders & Today Tab) — executing
Plan: 2 of 5
Status: Phase 6 executing — Plan 02 (Wiring) complete.
Last activity: 2026-05-27 — Plan 06-02 complete (ContentView two-gate, TabView selection, AppDelegate bridge, ScheduleStore hook).
Progress: [█████░░░░░] 50%

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

**Phase 5 Plan 01 (2026-05-25):**
- D-43: HealthProfileView removes @Environment(AppState.self) entirely — no remaining references after markOnboarded and appState mutation removed from save().
- D-44: ContentView wraps if/else gate in Group{} so .task modifier attaches to both branches (not just the TabView).
- D-45: Temporary OnboardingCoordinatorView stub created in Plan 01 to keep build green; Plan 04 overwrites with real coordinator.

**Phase 5 Plan 03 (2026-05-25):**
- D-46: OnboardingPreviewView positions "See What You're Getting" CTA via .safeAreaInset(edge: .bottom) so button floats persistently above safe area without disrupting ScrollView content.
- D-47: Block count computed as [s.morning, s.afternoon, s.evening].filter { !$0.isEmpty }.count — matches ScheduleResult's actual property names (confirmed morning/afternoon/evening as [ScheduledItem]).

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

Last session: 2026-05-27
Stopped at: Plan 06-02 complete. ContentView two-gate (c984899), AppDelegate bridge + ScheduleStore hook (2088d3e) committed.
Resume: Execute Plan 06-03 — NotificationPermissionView (full UI replacing stub).

**Phase 5 decisions:**
- D-48: appState.onboardingComplete = true works directly in function scope on iOS 17+ @Observable — no @Bindable unwrap required.
- D-49: Smart resume uses age==0 || weightKg==0 as step-1 sentinel (no new Core Data column needed, aligns with D-24).
