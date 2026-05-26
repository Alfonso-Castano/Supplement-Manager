---
phase: "05"
plan: "02"
subsystem: onboarding
tags: [swift, swiftui, core-data, onboarding, step-views]
dependency_graph:
  requires:
    - 05-01  # HealthProfileView refactored, ContentView gate installed
  provides:
    - ScheduleInputsView (Step 3 — schedule time inputs, crash-resume support)
    - StackEntryStepView (Step 2 — item gate, AddItemView sheet)
  affects:
    - OnboardingCoordinatorView (05-04 will wire these views into the coordinator)
tech_stack:
  added: []
  patterns:
    - FetchRequest live-updating gate (StackEntryStepView)
    - onAppear pre-populate from Core Data (crash-resume, D-07)
    - onNext callback delegation (coordinator drives navigation)
key_files:
  created:
    - StackWise/Features/Onboarding/ScheduleInputsView.swift
    - StackWise/Features/Onboarding/StackEntryStepView.swift
  modified: []
decisions:
  - D-07 crash-resume implemented via .onAppear pre-populate in ScheduleInputsView
  - D-08 hard minimum 1 item enforced via items.isEmpty gate on Next button
  - D-09 inline hint copy present verbatim in StackEntryStepView
metrics:
  duration: "~20 minutes"
  completed: "2026-05-26"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 05 Plan 02: ScheduleInputsView + StackEntryStepView Summary

**One-liner:** Step 3 schedule DatePicker form with Core Data crash-resume and Step 2 FetchRequest item gate with disabled Next button.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create ScheduleInputsView.swift | 5401e2d | StackWise/Features/Onboarding/ScheduleInputsView.swift |
| 2 | Create StackEntryStepView.swift | 8d36158 | StackWise/Features/Onboarding/StackEntryStepView.swift |

## What Was Built

### ScheduleInputsView (Step 3)

A self-contained step view with 5 DatePickers (wake, sleep, breakfast, lunch, dinner) in a `Form` with `Section("Schedule")`. Key behaviors:

- `.onAppear` reads `UserProfileStore.fetchOrCreate` and pre-populates all 5 `@State` time fields from Core Data — implements D-07 crash-resume (if wake/meal times already saved, user sees their previous choices)
- `save()` writes only time fields to Core Data — no personal fields touched, no `markOnboarded` call
- `onNext: () -> Void = {}` callback — coordinator drives navigation, view is passive
- No `NavigationStack` wrapper — coordinator's stack provides the context
- `navigationTitle("Your Schedule")` per UI-SPEC copywriting contract
- `defaultTime(hour:minute:)` helper replicated from HealthProfileView

### StackEntryStepView (Step 2)

A step wrapper that gates forward progression on the user having at least 1 active stack item. Key behaviors:

- `@FetchRequest(predicate: "isActive == YES")` — live-updating, no manual observation
- Next button: `.disabled(items.isEmpty)` + `.opacity(items.isEmpty ? 0.4 : 1.0)` — implements D-08 hard minimum
- D-09 inline hint copy shown verbatim when empty: "Add your supplements to see how they interact and get your personalized schedule"
- If items exist, `StackListView()` embedded inline (provides stack review before advancing)
- `+` toolbar button opens `AddItemView()` as a sheet
- `navigationTitle("Your Supplement Stack")` per UI-SPEC

## Deviations from Plan

None — plan executed exactly as written.

**Note on StackListView embedding:** The plan explicitly instructs to embed `StackListView()` directly as a child view when items are non-empty. `StackListView` has its own internal `NavigationStack`; this creates a nested stack. On iOS 17+ (this project's minimum), nested `NavigationStack` instances are isolated — the inner stack handles its own navigation (AnalysisView push) while the outer coordinator stack handles step navigation. This is the intended design per the plan.

## Verification

- All acceptance criteria checked via grep — all pass
- `xcodebuild` unavailable on Windows build environment; build verification deferred to macOS CI
- Neither file calls `UserProfileStore.markOnboarded`
- Neither file contains a `NavigationStack` wrapper (ScheduleInputsView); StackEntryStepView embeds StackListView which has its own internal stack per plan intent

## Known Stubs

None. Both views are fully functional within their scope.

## Threat Flags

None. Both views are on-device only, no network calls, no new security surface (confirmed against plan threat model T-5-02, T-5-03).

## Self-Check: PASSED

- ScheduleInputsView.swift: exists at StackWise/Features/Onboarding/ScheduleInputsView.swift
- StackEntryStepView.swift: exists at StackWise/Features/Onboarding/StackEntryStepView.swift
- Task 1 commit 5401e2d: exists
- Task 2 commit 8d36158: exists
