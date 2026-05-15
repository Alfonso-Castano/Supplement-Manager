---
phase: 04-smart-schedule
plan: 01
subsystem: database, schedule
tags: [sqlite, observable, core-data, json-decoding, timing-properties]

# Dependency graph
requires:
  - phase: 03-interaction-analysis
    provides: InteractionRepository, IngredientRepository, AnalysisStore injection pattern
provides:
  - TimingProperties struct with JSON blob decoding
  - IngredientRepository.timingProperties(for:) query method
  - ScheduleStore skeleton with dirty-flag pattern
  - ScheduleResult and ScheduledItem stub types
  - ScheduleStore injected into StackWiseApp environment
affects: [04-02-schedule-engine, 04-03-schedule-view, 04-04-wire-invalidation]

# Tech tracking
tech-stack:
  added: []
  patterns: [dirty-flag-recompute for ScheduleStore, JSON blob decoding via JSONSerialization]

key-files:
  created:
    - StackWise/Schedule/TimingProperties.swift
    - StackWise/Schedule/ScheduleStore.swift
  modified:
    - StackWise/Data/IngredientRepository.swift
    - StackWise/StackWiseApp.swift
    - StackWiseTests/IngredientRepositoryTests.swift

key-decisions:
  - "No new decisions -- followed plan as specified using D-36 through D-38"

patterns-established:
  - "TimingProperties.decode(from:) safe JSON blob parsing with .none fallback"
  - "ScheduleStore follows same @Observable dirty-flag pattern as AnalysisStore"

requirements-completed: []

# Metrics
duration: 2min
completed: 2026-05-15
---

# Phase 4 Plan 01: Data Layer + ScheduleStore Skeleton Summary

**TimingProperties JSON decoder, IngredientRepository timing query, and ScheduleStore skeleton with dirty-flag recompute pattern injected into app**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-15T05:31:28Z
- **Completed:** 2026-05-15T05:33:09Z
- **Tasks:** 5
- **Files modified:** 5

## Accomplishments
- TimingProperties value type that safely decodes timing_properties JSON blobs from the ingredients table
- IngredientRepository extended with timingProperties(for:) method using raw sqlite3 C API
- ScheduleStore skeleton with @Observable dirty-flag pattern, ready for algorithm in 04-02
- ScheduleStore injected into StackWiseApp environment for view access
- New test added for timingProperties query (total: 37 tests)

## Task Commits

Each task was committed atomically:

1. **Task 1: TimingProperties struct** - `463eb4d` (feat)
2. **Task 2: IngredientRepository.timingProperties(for:)** - `a01cb91` (feat)
3. **Task 3: ScheduleStore skeleton** - `c8a5216` (feat)
4. **Task 4: Inject ScheduleStore into StackWiseApp** - `b662e68` (feat)
5. **Task 5: Extend IngredientRepositoryTests** - `0f9bf91` (test)

## Files Created/Modified
- `StackWise/Schedule/TimingProperties.swift` - Value type wrapping timing_properties JSON blob with decode(from:) static method
- `StackWise/Schedule/ScheduleStore.swift` - @Observable store with dirty-flag, invalidate(), currentSchedule(), plus ScheduleResult/ScheduledItem stubs
- `StackWise/Data/IngredientRepository.swift` - Added timingProperties(for:) method querying by canonical_name
- `StackWise/StackWiseApp.swift` - Added ScheduleStore creation in init() and .environment injection
- `StackWiseTests/IngredientRepositoryTests.swift` - Added testTimingPropertiesForKnownSlug test

## Decisions Made
None - followed plan as specified.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs

| File | Location | Stub | Reason |
|------|----------|------|--------|
| ScheduleStore.swift | recompute() | Empty method body (TODO 04-02) | Algorithm logic deferred to Plan 04-02 per plan design |
| ScheduleStore.swift | Bottom of file | ScheduleResult/ScheduledItem structs | Temporary stubs replaced by full definitions in Plan 04-02 |

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Data layer complete: TimingProperties + timingProperties(for:) ready for ScheduleEngine
- ScheduleStore skeleton ready to receive recompute logic in Plan 04-02
- Environment injection done; views can access ScheduleStore immediately
- Cannot run xcodebuild on Windows; Mac verification deferred to D-42 batch

---
*Phase: 04-smart-schedule*
*Completed: 2026-05-15*
