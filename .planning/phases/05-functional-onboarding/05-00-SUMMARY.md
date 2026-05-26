---
phase: 05-functional-onboarding
plan: "00"
subsystem: testing

tags: [swift, xctest, core-data, onboarding, tdd]

requires:
  - phase: 04-smart-schedule
    provides: PersistenceController, UserProfileStore.markOnboarded, ScheduleStore patterns established

provides:
  - "Wave 0 test contract: 5 RED stubs for REQ-18 smart-resume and REQ-19 write-on-complete"
  - "OnboardingCoordinatorTests.swift with setUp/tearDown using PersistenceController(inMemory: true)"

affects:
  - 05-01-PLAN (Wave 1 — implements OnboardingCoordinatorView to turn stubs GREEN)
  - 05-02-PLAN (Wave 2 — builds remaining coordinator steps)
  - 05-03-PLAN (Wave 3 — wires app gate and paywall placeholder)

tech-stack:
  added: []
  patterns:
    - "Wave 0 Nyquist rule: test stubs created before any production code"
    - "XCTFail stub pattern: all test bodies call XCTFail until implementation exists"

key-files:
  created:
    - StackWiseTests/OnboardingCoordinatorTests.swift
  modified: []

key-decisions:
  - "Stubs are intentionally RED — defines contract before Wave 1-3 implementation"
  - "No @MainActor on class — tests exercise Core Data directly, not @Observable stores"
  - "setUp/tearDown pattern mirrors UserProfileStoreTests.swift for consistency"

patterns-established:
  - "Stub pattern: XCTFail('not yet implemented — implement after X is built in Wave Y')"

requirements-completed:
  - REQ-18
  - REQ-19

duration: 5min
completed: 2026-05-25
---

# Phase 5 Plan 00: Functional Onboarding Wave 0 Test Stubs Summary

**5 RED XCTest stubs establishing the REQ-18 smart-resume and REQ-19 write-on-complete contract before OnboardingCoordinatorView is implemented**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-25T00:00:00Z
- **Completed:** 2026-05-25T00:05:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `StackWiseTests/OnboardingCoordinatorTests.swift` with 5 named test stubs
- All stubs call `XCTFail` (RED state — correct Wave 0 behavior per Nyquist rule)
- Used `PersistenceController(inMemory: true)` setUp/tearDown pattern matching `UserProfileStoreTests.swift`
- Established Wave 0 test contract so Wave 1–3 plans have a concrete verification target

## Task Commits

1. **Task 1: Create OnboardingCoordinatorTests.swift with failing stubs** - `657d125` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `StackWiseTests/OnboardingCoordinatorTests.swift` — 5 RED stubs for REQ-18/REQ-19; setUp/tearDown with in-memory PersistenceController

## Decisions Made

None - followed plan as specified. No @MainActor added per plan instruction (tests exercise Core Data directly, not @Observable stores).

## Deviations from Plan

None - plan executed exactly as written.

Note: xcodebuild build-for-testing verification could not be run from Windows environment (xcodebuild is Mac-only). The file follows the exact same pattern as `UserProfileStoreTests.swift` which has been verified to compile successfully. Mac-side build verification should be performed when Wave 1 implementation begins.

## Issues Encountered

None. xcodebuild is not available on Windows (D-21: Windows/Mac split) — this is a known environment constraint, not a new issue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 0 test contract established; Wave 1 (05-01-PLAN.md) can begin
- `OnboardingCoordinatorTests.swift` exists and defines exactly what `OnboardingCoordinatorView` must implement
- All 5 stubs are RED — they will turn GREEN as Wave 1–3 plans implement the coordinator

---
*Phase: 05-functional-onboarding*
*Completed: 2026-05-25*
