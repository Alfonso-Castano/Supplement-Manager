---
phase: 06-reminders-today-tab
plan: 02
subsystem: state, ui, notifications
tags: [TabView, AppStorage, UIApplicationDelegateAdaptor, NotificationScheduler, ContentView]

# Dependency graph
requires:
  - phase: 06-reminders-today-tab/01
    provides: AppDelegate, AppState.selectedTab, NotificationScheduler
provides:
  - ContentView two-gate pattern (onboarding -> notification permission -> TabView)
  - TabView(selection:) with programmatic tab switching via AppState.selectedTab
  - AppDelegate bridged into SwiftUI lifecycle via @UIApplicationDelegateAdaptor
  - NotificationScheduler.reschedule triggered on every schedule recompute
affects: [06-03 (NotificationPermissionView replaces stub), 06-04 (TodayView at tab 1), 06-05 (tests GREEN)]

# Tech tracking
tech-stack:
  added: []
  patterns: [two-gate ContentView pattern (@AppStorage + @Observable), .task AppDelegate bridge]

key-files:
  created:
    - StackWise/Features/Today/NotificationPermissionView.swift (stub, replaced in 06-03)
  modified:
    - StackWise/ContentView.swift
    - StackWise/StackWiseApp.swift
    - StackWise/Schedule/ScheduleStore.swift

key-decisions:
  - "NotificationPermissionView stub created as Rule 3 deviation to unblock ContentView compilation; Plan 06-03 replaces with full UI"
  - "@AppStorage for notificationPermissionShown gate provides synchronous UserDefaults read, avoiding flash on re-launch"

patterns-established:
  - "Two-gate ContentView: onboardingComplete (outer) -> notificationPermissionShown (inner) -> TabView"
  - "TabView tag convention: Stack=0, Today=1, Schedule=2"
  - ".task { appDelegate.appState = appState } bridge pattern for UIApplicationDelegateAdaptor"

requirements-completed: [REQ-20, REQ-21]

# Metrics
duration: 2min
completed: 2026-05-27
---

# Phase 6 Plan 02: Wiring Summary

**Two-gate ContentView with @AppStorage permission gate, TabView(selection:) binding, AppDelegate bridge, and ScheduleStore notification hook**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-27T15:26:53Z
- **Completed:** 2026-05-27T15:29:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Rewrote ContentView with two-gate pattern: onboardingComplete (outer), notificationPermissionShown via @AppStorage (inner), then TabView with selection binding
- Wired AppDelegate into SwiftUI App struct via @UIApplicationDelegateAdaptor and .task bridge
- Hooked NotificationScheduler.reschedule(for:) into ScheduleStore.recompute() after cache update
- Created NotificationPermissionView stub to keep build green until Plan 06-03

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite ContentView with two-gate pattern and TabView(selection:)** - `c984899` (feat)
2. **Task 2: Wire AppDelegate into StackWiseApp + hook NotificationScheduler into ScheduleStore** - `2088d3e` (feat)

## Files Created/Modified
- `StackWise/ContentView.swift` - Two-gate pattern with @AppStorage notificationPermissionShown, TabView(selection: $appState.selectedTab) with tags 0/1/2
- `StackWise/StackWiseApp.swift` - @UIApplicationDelegateAdaptor(AppDelegate.self) + .task appState bridge
- `StackWise/Schedule/ScheduleStore.swift` - NotificationScheduler.reschedule(for: result) after cache update
- `StackWise/Features/Today/NotificationPermissionView.swift` - Stub view (replaced by Plan 06-03)

## Decisions Made
- Created NotificationPermissionView stub as Rule 3 deviation to unblock ContentView compilation; Plan 06-03 replaces with full UI
- Used @AppStorage("notificationPermissionShown") for synchronous UserDefaults read, preventing flash on re-launch (per RESEARCH.md Pattern 5)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created NotificationPermissionView stub**
- **Found during:** Task 1 (ContentView rewrite)
- **Issue:** ContentView references NotificationPermissionView which does not exist yet (created in Plan 06-03)
- **Fix:** Created minimal stub at StackWise/Features/Today/NotificationPermissionView.swift with correct interface (var onComplete: () -> Void)
- **Files modified:** StackWise/Features/Today/NotificationPermissionView.swift
- **Verification:** ContentView compiles with the stub in place
- **Committed in:** c984899 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Stub necessary to keep build green. Plan 06-03 overwrites with full implementation. No scope creep.

## Known Stubs

| File | Description | Resolved By |
|------|-------------|-------------|
| StackWise/Features/Today/NotificationPermissionView.swift | Minimal stub with correct interface, no permission request logic | Plan 06-03 |

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ContentView gate pattern ready for NotificationPermissionView full implementation (Plan 06-03)
- TabView(selection:) ready for notification tap -> Today tab routing
- ScheduleStore notification hook active - reminders will auto-schedule when permission is granted
- AppDelegate bridge complete - cold-start and warm-start notification taps will route correctly

---
*Phase: 06-reminders-today-tab*
*Completed: 2026-05-27*

## Self-Check: PASSED
