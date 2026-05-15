---
phase: 04-smart-schedule
plan: "04"
subsystem: schedule
tags: [swiftui, coredata, observable, invalidation]

requires:
  - phase: 04-smart-schedule/04-02
    provides: ScheduleStore with recompute() and ScheduleEngine
  - phase: 04-smart-schedule/04-03
    provides: ScheduleView UI consuming ScheduleStore

provides:
  - ScheduleStore.invalidate() wired into AddItemView save callback
  - Verified ScheduledDose Core Data writes in recompute()
  - Mac test handoff document for Phase 4 batch verification

affects: [phase-5-onboarding]

tech-stack:
  added: []
  patterns: [dual-store-invalidation-on-save]

key-files:
  created:
    - .claude/MAC-TEST-HANDOFF-04.md
  modified:
    - StackWise/Features/Stack/AddItemView.swift

key-decisions:
  - "Task 2 verification: recompute() writes are complete -- no fixes needed"

patterns-established:
  - "Dual invalidation: AddItemView.save() invalidates both AnalysisStore and ScheduleStore"

requirements-completed: []

duration: 1min
completed: 2026-05-15
---

# Plan 04-04: Wire Invalidation + Core Data Writes + Mac Batch Summary

**ScheduleStore.invalidate() wired into AddItemView onSaved alongside AnalysisStore; ScheduledDose Core Data writes verified correct; Mac handoff doc created**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-15T05:46:01Z
- **Completed:** 2026-05-15T05:47:08Z
- **Tasks:** 3 (Task 4 skipped -- orchestrator handles GSD closure)
- **Files modified:** 2

## Accomplishments
- Wired `scheduleStore.invalidate()` into AddItemView save callback alongside existing `analysisStore.invalidate()`
- Verified ScheduleStore.recompute() correctly deletes old ScheduledDose records, creates new ones with all required fields (id, position, suggestedTime, timeBlock, stackItem), and saves context
- Created MAC-TEST-HANDOFF-04.md with build/test instructions and 7-step simulator golden path

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire ScheduleStore.invalidate() into AddItemView** - `014e4eb` (feat)
2. **Task 2: Verify ScheduledDose Core Data writes** - verification only, no code changes needed
3. **Task 3: Mac batch verification handoff doc** - `455a703` (docs)

## Files Created/Modified
- `StackWise/Features/Stack/AddItemView.swift` - Added @Environment(ScheduleStore.self) injection and scheduleStore.invalidate() call in onSaved
- `.claude/MAC-TEST-HANDOFF-04.md` - Phase 4 Mac test handoff with build, test, and simulator golden path instructions

## Decisions Made
- Task 2 verification confirmed recompute() writes are complete and correct as implemented in 04-02. No fixes needed -- all 5 checks pass (fetch, delete, create with fields, relationship assignment, save).

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None -- no external service configuration required.

## Next Phase Readiness
- Phase 4 code is complete pending Mac verification (build + tests + simulator golden path)
- Mac handoff document ready at `.claude/MAC-TEST-HANDOFF-04.md`
- After Mac verification passes, Phase 4 can be closed and Phase 5 (Functional Onboarding) begins

---
*Phase: 04-smart-schedule*
*Completed: 2026-05-15*
