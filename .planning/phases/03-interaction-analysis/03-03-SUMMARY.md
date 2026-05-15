---
phase: "03"
plan: "03"
subsystem: analysis-ui
tags: [swiftui, analysis, navigation, toolbar]
dependency_graph:
  requires: [03-01, 03-02]
  provides: [analysis-view-ui]
  affects: [StackListView, AnalysisView]
tech_stack:
  added: []
  patterns: [observable-environment, grouped-list-sections, navigation-link-push]
key_files:
  created: []
  modified:
    - StackWise/Features/Stack/AnalysisView.swift
    - StackWise/Features/Stack/StackListView.swift
decisions:
  - results == .empty comparison works because AnalysisResults conforms to Equatable and .empty is a static property
  - Empty sections suppressed with if !results.X.isEmpty guards — no empty stubs rendered
  - SF Symbol clock.badge.exclamationmark is iOS 17+ which is within the project's minimum deployment target
metrics:
  duration: "~5 minutes"
  completed: "2026-05-15"
  tasks_completed: 2
  files_modified: 2
---

# Phase 03 Plan 03: AnalysisView Grouped Screen + Analyze Toolbar Button Summary

Replaced Phase 2 placeholder `AnalysisView` with a fully-functional grouped List screen driven by `AnalysisStore`, and wired a stethoscope toolbar button in `StackListView` that pushes to it via `NavigationLink`.

## What Was Built

### Task 1 — Rewrite AnalysisView.swift

The existing file was a pure placeholder (`Text("Analysis")` only, 7 lines, zero logic). It was replaced in full.

The new `AnalysisView`:
- Reads results from `@Environment(AnalysisStore.self)` — no `@Bindable`, just `private var store`
- Shows `ContentUnavailableView` when `results == .empty` (works because `AnalysisResults: Equatable`)
- Renders a `List` with up to four sections: Critical, Advisory, Positive insights, Not in our database
- Each section is guard-wrapped (`if !results.X.isEmpty`) so empty sections are suppressed entirely
- `PairRow` (private) displays the compound pair name, effect text, and suggested action with a type-specific SF Symbol and accent color
- `displayName(_:)` converts snake_case slugs to Title Case for display

### Task 2 — Edit StackListView.swift

Added a second `ToolbarItem` with `.topBarLeading` placement containing a `NavigationLink` that pushes `AnalysisView()`. The existing `.primaryAction` Add button was not touched. `StackItemRow` was not touched (Wave 4's responsibility).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. `AnalysisView` reads live data from `AnalysisStore.currentResults()` which runs `AnalysisEngine.analyze(...)` against the real Core Data stack via `InteractionRepository`.

## Self-Check
- `StackWise/Features/Stack/AnalysisView.swift` — written and committed
- `StackWise/Features/Stack/StackListView.swift` — edited and committed
- Commit `6ede987` confirmed in git log
- All 5 grep verification checks passed
