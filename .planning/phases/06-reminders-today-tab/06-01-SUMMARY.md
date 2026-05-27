---
phase: 06-reminders-today-tab
plan: 01
subsystem: notifications, state
tags: [UserNotifications, UNUserNotificationCenterDelegate, AppDelegate, UIApplicationDelegateAdaptor, CoreData, XCTest]

# Dependency graph
requires:
  - phase: 05-functional-onboarding
    provides: AppState @Observable, ContentView gate pattern, ScheduleResult types
provides:
  - AppDelegate with UNUserNotificationCenterDelegate + pendingTab cold-start routing
  - AppState.selectedTab property for programmatic TabView switching
  - NotificationScheduler pure service (buildRequests + reschedule)
  - 6 RED test stubs for REQ-20 and REQ-21
affects: [06-02 (wiring), 06-03 (permission view), 06-04 (TodayView), 06-05 (tests GREEN)]

# Tech tracking
tech-stack:
  added: [UserNotifications framework (system)]
  patterns: [caseless enum service (NotificationScheduler), pendingTab cold-start pattern, stable notification identifiers]

key-files:
  created:
    - StackWise/AppDelegate.swift
    - StackWise/Notifications/NotificationScheduler.swift
    - StackWiseTests/NotificationSchedulerTests.swift
    - StackWiseTests/DailyCheckOffTests.swift
    - StackWiseTests/TodayViewModelTests.swift
  modified:
    - StackWise/Models/AppState.swift

key-decisions:
  - "AppDelegate uses @preconcurrency UNUserNotificationCenterDelegate conformance to suppress Swift concurrency warnings"
  - "NotificationScheduler split into buildRequests (pure, testable) and reschedule (async wrapper) for testability"
  - "pendingTab pattern handles cold-start notification taps when appState is nil"

patterns-established:
  - "Caseless enum with static methods for pure services (NotificationScheduler, same as UserProfileStore)"
  - "pendingTab didSet pattern for deferred state application on cold-start"
  - "Stable notification identifiers (morning_reminder, afternoon_reminder, evening_reminder) instead of UUID"

requirements-completed: []

# Metrics
duration: 2min
completed: 2026-05-27
---

# Phase 6 Plan 01: Foundation Summary

**AppDelegate with pendingTab cold-start routing, NotificationScheduler pure service with buildRequests/reschedule split, AppState.selectedTab, and 6 RED test stubs for REQ-20/REQ-21**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-27T15:22:50Z
- **Completed:** 2026-05-27T15:24:39Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Created AppDelegate with UIApplicationDelegate + UNUserNotificationCenterDelegate, pendingTab cold-start pattern, and foreground notification display
- Extended AppState with selectedTab: Int = 0 for programmatic TabView switching
- Implemented NotificationScheduler as caseless enum with pure buildRequests(for:) builder and async reschedule(for:) wrapper
- Created 6 RED test stubs across 3 test files matching exact method names from RESEARCH.md

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AppDelegate + extend AppState.selectedTab** - `ee04910` (feat)
2. **Task 2: Implement NotificationScheduler pure service** - `976410a` (feat)
3. **Task 3: Create six RED test stubs** - `782bc18` (test)

## Files Created/Modified
- `StackWise/AppDelegate.swift` - UNUserNotificationCenterDelegate with pendingTab cold-start routing
- `StackWise/Models/AppState.swift` - Added selectedTab: Int = 0 property
- `StackWise/Notifications/NotificationScheduler.swift` - Pure notification scheduling service
- `StackWiseTests/NotificationSchedulerTests.swift` - 3 RED stubs for REQ-20
- `StackWiseTests/DailyCheckOffTests.swift` - 2 RED stubs for REQ-21 with in-memory Core Data container
- `StackWiseTests/TodayViewModelTests.swift` - 1 RED stub for REQ-21 past-block logic

## Decisions Made
- AppDelegate uses `@preconcurrency` on UNUserNotificationCenterDelegate conformance (standard workaround for Swift concurrency as of 2025)
- NotificationScheduler split into buildRequests(for:) (pure, synchronous, testable) and reschedule(for:) (async wrapper with auth check) for maximum testability
- pendingTab pattern stores tab intent when appState is nil (cold-start), applies via didSet when appState is assigned

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AppDelegate ready for wiring via @UIApplicationDelegateAdaptor in Plan 06-02
- AppState.selectedTab ready for TabView(selection:) binding in Plan 06-02
- NotificationScheduler ready for ScheduleStore.recompute() hook in Plan 06-02
- All 6 test stubs ready to be filled GREEN in Plan 06-05

---
*Phase: 06-reminders-today-tab*
*Completed: 2026-05-27*
