---
phase: "03"
plan: "04"
subsystem: stack-ui
tags: [severity-badge, analysis-store, stack-list]
dependency_graph:
  requires: [03-03]
  provides: [inline-severity-badges]
  affects: [StackListView]
tech_stack:
  added: []
  patterns: ["@Environment injection into NSManagedObject-backed row view"]
key_files:
  created: []
  modified:
    - StackWise/Features/Stack/StackListView.swift
decisions:
  - "Used typed accessor activeIngredientValue (from StackItem+CoreDataClass.swift) instead of KVC — avoids stringly-typed key lookup"
  - "severityForRow returns nil for custom items (isInDatabase == false) — consistent with database-only interaction scope"
  - "Severity badge placed after Phase 2 custom-item triangle in the label HStack — both icons can coexist without conflict because custom items always return nil from severityForRow"
metrics:
  duration: "< 5 minutes"
  completed: "2026-05-15"
  tasks_completed: 1
  files_modified: 1
---

# Phase 03 Plan 04: Inline Severity Badges on Stack Rows Summary

## One-liner

`StackItemRow` reads `AnalysisStore` from environment and renders a red octagon (critical) or orange circle (advisory) severity badge next to items with active interactions.

## What Changed

**File modified:** `StackWise/Features/Stack/StackListView.swift`

Inside the private `StackItemRow` struct:

1. Added `@Environment(AnalysisStore.self) private var store` — injects the shared analysis cache.
2. Added `severityForRow: InteractionSeverity?` computed property — guards on `isInDatabase`, reads `item.activeIngredientValue` (typed accessor), delegates to `store.currentResults().worstSeverity(forSlug:)`.
3. Added severity badge `Image` in the label `HStack` after the existing Phase 2 custom-item triangle icon.

## Implementation Notes

- **Typed accessor used:** `item.activeIngredientValue` (defined in `StackItem+CoreDataClass.swift`). KVC was not needed.
- **Custom items receive no badge:** The `guard item.isInDatabase else { return nil }` in `severityForRow` enforces this. Custom items already show the orange triangle warning; adding a severity badge would be meaningless since they have no DB slug.
- **Phase 2 triangle unchanged:** The `if !item.isInDatabase { Label("Custom", ...) }` block was not modified.
- **Type badge (capsule) unchanged:** The drug/supplement pill badge was not touched.
- **Toolbar and NavigationLink unchanged:** Wave 3 additions left as-is.

## Deviations from Plan

None — plan executed exactly as written, using the typed accessor path as the plan anticipated.

## Pending: Task 2 (Mac Batch Verification Gate)

Task 2 is a BLOCKING human gate. It requires:
- Full Xcode build on Mac
- 36 tests passing (21 Phase 2 + 15 Phase 3)
- Visual verification of severity badges rendering on the stack list

This gate is NOT automated and must be completed manually on the Mac before Phase 4 begins.

## Self-Check

- [x] `StackWise/Features/Stack/StackListView.swift` modified — confirmed via Read
- [x] Commit `f72b8f2` exists — `feat(03-04): inline severity badges on stack rows`
- [x] All 4 grep checks passed before commit
