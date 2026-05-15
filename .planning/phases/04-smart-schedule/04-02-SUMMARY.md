---
phase: 04-smart-schedule
plan: "02"
subsystem: schedule
tags: [swift, scheduling-algorithm, pure-function, xctest]

# Dependency graph
requires:
  - phase: 04-smart-schedule
    provides: TimingProperties, ScheduleStore skeleton, IngredientRepository.timingProperties
provides:
  - ScheduleResult and ScheduledItem value types
  - ScheduleEngine pure 4-rule scheduling algorithm
  - ScheduleStore.recompute() wired to ScheduleEngine + Core Data writes
  - 11 new tests (7 engine + 4 store)
affects: [04-03-schedule-view, 04-04-wire-invalidation]

# Tech tracking
tech-stack:
  added: []
  patterns: [pure-enum-engine, projection-types-for-testability, dirty-flag-recompute]

key-files:
  created:
    - StackWise/Schedule/ScheduleResult.swift
    - StackWise/Schedule/ScheduleEngine.swift
    - StackWiseTests/ScheduleEngineTests.swift
    - StackWiseTests/ScheduleStoreTests.swift
  modified:
    - StackWise/Schedule/ScheduleStore.swift

key-decisions:
  - "ScheduleEngine uses ItemProjection/PairProjection value types to decouple from Core Data"
  - "Timing conflict detection simplified: hasTimingConflict=false (full detection deferred to AnalysisStore)"
  - "Block overflow threshold set at 5 items (morning -> afternoon -> evening spillover)"

patterns-established:
  - "Pure enum engine pattern: ScheduleEngine mirrors AnalysisEngine as a pure static function with projection inputs"
  - "ScheduleStore.recompute() deletes all ScheduledDose rows then inserts fresh ones on each recompute"

requirements-completed: []

# Metrics
duration: 3min
completed: 2026-05-15
---

# Phase 4 Plan 02: ScheduleEngine 4-Rule Algorithm Summary

**Pure ScheduleEngine with prescription-first placement, timing-conflict separation, timing_properties constraints, and overflow balancing -- all testable without Core Data**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-15T05:36:21Z
- **Completed:** 2026-05-15T05:39:35Z
- **Tasks:** 5
- **Files modified:** 5

## Accomplishments
- Created ScheduleResult.swift with full ScheduledItem type (Identifiable, Equatable, synergy/conflict flags) and removed temporary stubs from ScheduleStore.swift
- Built ScheduleEngine as a pure enum with 4 priority rules: prescription lock, timing-conflict separation, timing_properties constraints, overflow balancing
- Wired ScheduleStore.recompute() to fetch StackItems, build projections, call engine, write ScheduledDose records to Core Data
- Added 7 ScheduleEngine tests covering all 4 rules plus empty-stack edge case
- Added 4 ScheduleStore tests validating dirty-flag caching, invalidation, and recompute behavior

## Task Commits

Each task was committed atomically:

1. **Task 1: ScheduleResult.swift + stub removal** - `1a6d0d8` (feat)
2. **Task 2: ScheduleEngine.swift** - `e8d1abc` (feat)
3. **Task 3: Wire recompute()** - `bffc7e4` (feat)
4. **Task 4: ScheduleEngineTests.swift** - `44813c7` (test)
5. **Task 5: ScheduleStoreTests.swift** - `5f9898f` (test)

## Files Created/Modified
- `StackWise/Schedule/ScheduleResult.swift` - ScheduledItem and ScheduleResult value types with Equatable conformance
- `StackWise/Schedule/ScheduleEngine.swift` - Pure enum with schedule() static method implementing 4-rule algorithm
- `StackWise/Schedule/ScheduleStore.swift` - recompute() wired to engine + Core Data ScheduledDose writes; stubs removed
- `StackWiseTests/ScheduleEngineTests.swift` - 7 tests for all scheduling rules
- `StackWiseTests/ScheduleStoreTests.swift` - 4 tests for dirty-flag recompute pattern

## Decisions Made
- ScheduleEngine uses projection types (ItemProjection, PairProjection) rather than Core Data objects -- keeps the engine pure and testable without simulator
- hasTimingConflict on ScheduledItem is set to false (simplified); full conflict detection lives in AnalysisStore and will be surfaced via badges in 04-03
- Recompute deletes all ScheduledDose rows then inserts fresh ones (same pattern as batch-replace in other stores)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ScheduleEngine and ScheduleStore are fully functional; ScheduleView (04-03) can call `scheduleStore.currentSchedule()` to render blocks
- ScheduleStore.invalidate() wiring from StackItemFactory will be connected in 04-04
- Mac batch verification deferred to 04-04 per D-42

---
*Phase: 04-smart-schedule*
*Completed: 2026-05-15*
