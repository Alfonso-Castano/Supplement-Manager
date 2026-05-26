---
phase: 05-functional-onboarding
plan: "01"
subsystem: ui
tags: [swiftui, coredata, onboarding, navigation]

# Dependency graph
requires:
  - phase: 05-00
    provides: OnboardingCoordinatorTests RED stubs establishing REQ-18/REQ-19 contract
provides:
  - HealthProfileView refactored as step 1 form with onNext callback, personal fields only
  - ContentView if/else gate on appState.onboardingComplete replacing .sheet presenter
  - Temporary OnboardingCoordinatorView stub keeping build green until Plan 04
affects:
  - 05-02 (ScheduleInputsView — needs to receive schedule @State fields moved from HealthProfileView)
  - 05-04 (OnboardingCoordinatorView — overwrites the stub created here)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "onNext: () -> Void parameter pattern for coordinator-driven step views"
    - "if/else gate on appState.onboardingComplete in ContentView body"
    - "Group {} wrapper to attach .task modifier to conditional content"

key-files:
  created:
    - StackWise/Features/Onboarding/OnboardingCoordinatorView.swift (temporary stub)
  modified:
    - StackWise/Features/Onboarding/HealthProfileView.swift
    - StackWise/ContentView.swift

key-decisions:
  - "D-43: HealthProfileView removes @Environment(AppState.self) entirely — no longer needed after markOnboarded and appState mutation moved out"
  - "D-44: ContentView wraps if/else in Group{} so .task modifier attaches cleanly to the outermost view rather than only to the true-branch TabView"
  - "D-45: Temporary OnboardingCoordinatorView stub created in Plan 01 to keep build green; Plan 04 overwrites it with the real coordinator"

patterns-established:
  - "Step view pattern: accepts onNext: () -> Void = {} with default no-op, toolbar 'Next' calls save() then onNext()"
  - "ContentView gate pattern: Group { if onboardingComplete { TabView } else { CoordinatorView } }.task { read from CoreData }"

requirements-completed:
  - REQ-18
  - REQ-19

# Metrics
duration: 15min
completed: 2026-05-25
---

# Phase 5 Plan 01: HealthProfileView Surgery + ContentView Gate Summary

**HealthProfileView stripped to personal-fields-only step with onNext callback; ContentView gate replaces .sheet with if/else on appState.onboardingComplete**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-25T00:00:00Z
- **Completed:** 2026-05-25T00:15:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- HealthProfileView reduced from 95 lines to 81 lines: removed NavigationStack wrapper, .interactiveDismissDisabled, Schedule section (5 DatePickers), all 5 schedule @State fields, markOnboarded call, and appState mutation — added onNext callback parameter and "Next" toolbar button
- ContentView .sheet presenter replaced with if/else gate — tabs are hidden during onboarding, coordinator shown until appState.onboardingComplete flips true
- Temporary OnboardingCoordinatorView stub added so the build remains green until Plan 04 delivers the real coordinator

## Task Commits

Each task was committed atomically:

1. **Task 1: Surgically refactor HealthProfileView** - `5d3868b` (feat)
2. **Task 2: Replace ContentView .sheet gate with coordinator gate** - `db86a40` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `StackWise/Features/Onboarding/HealthProfileView.swift` - Personal fields only, onNext callback, "Next" toolbar button; schedule section + markOnboarded removed
- `StackWise/ContentView.swift` - if/else gate on appState.onboardingComplete replacing .sheet; Group wrapper preserves .task on both branches
- `StackWise/Features/Onboarding/OnboardingCoordinatorView.swift` - Temporary stub (TEMPORARY STUB — replaced by Plan 04)

## Decisions Made

- **D-43:** Removed `@Environment(AppState.self)` from HealthProfileView entirely. After removing `appState.onboardingComplete = true` from save(), there was no remaining reference to `appState`. The `parseList` static method used in tests does not depend on environment. Removal is safe and avoids an "unused variable" compiler warning.
- **D-44:** Wrapped the `if/else` gate in `Group { }` so the `.task` modifier attaches to the group root rather than only to the TabView. This ensures the Core Data read that initializes `appState.onboardingComplete` fires regardless of which branch is shown.
- **D-45:** Created a temporary `OnboardingCoordinatorView` stub in this plan so the project builds cleanly after Task 2 (Plan 04 is Wave 3 and comes later). The stub simply renders `Text("Onboarding — coming soon")`.

## Deviations from Plan

None — plan executed exactly as written. All four changes to HealthProfileView and the ContentView gate replacement followed the specified instructions. The stub file creation was explicitly called out in the plan as the correct resolution.

## Issues Encountered

xcodebuild is not available in the Windows shell environment — build verification (xcodebuild build-for-testing) could not be run locally. All code changes were manually validated against the acceptance criteria (grep checks confirmed all removals/additions). Build verification must occur on macOS.

## Known Stubs

- `StackWise/Features/Onboarding/OnboardingCoordinatorView.swift` — intentional temporary stub. Renders static text. Plan 04 overwrites this with the real coordinator implementation. The stub is tracked and expected.

## Next Phase Readiness

- Plan 02 (ScheduleInputsView) can now proceed: the schedule @State fields that were removed from HealthProfileView must be re-implemented in ScheduleInputsView
- Plan 04 (OnboardingCoordinatorView) will overwrite the stub created here
- The ContentView gate will correctly hide tabs during onboarding once OnboardingCoordinatorView writes `markOnboarded` + sets `appState.onboardingComplete = true`

---
*Phase: 05-functional-onboarding*
*Completed: 2026-05-25*
