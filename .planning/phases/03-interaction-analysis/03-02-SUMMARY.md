---
phase: "03"
plan: "02"
subsystem: "Analysis Engine"
tags: [analysis, observable, core-data, tdd]
dependency_graph:
  requires: [03-01]
  provides: [AnalysisEngine, AnalysisStore, AnalysisResults]
  affects: [StackWiseApp, AddItemView, StackItemFactory]
tech_stack:
  added: []
  patterns: [@Observable cache with dirty-flag invalidation, pure enum analysis engine, #if DEBUG test-seam init]
key_files:
  created:
    - StackWise/Analysis/AnalysisResults.swift
    - StackWise/Analysis/AnalysisEngine.swift
    - StackWise/Analysis/AnalysisStore.swift
    - StackWiseTests/AnalysisEngineTests.swift
    - StackWiseTests/AnalysisStoreTests.swift
  modified:
    - StackWise/Features/Stack/StackItemFactory.swift
    - StackWise/Features/Stack/AddItemView.swift
    - StackWise/StackWiseApp.swift
decisions:
  - "Used typed accessors (labelValue, activeIngredientValue, isInDatabase) from StackItem+CoreDataClass.swift instead of KVC in AnalysisStore.recompute()"
  - "StackWiseApp rewritten with custom init() pattern so AnalysisStore can capture InteractionRepository instance before State wrapping"
metrics:
  duration: "~2 minutes"
  completed: "2026-05-15"
  tasks_completed: 1
  files_changed: 8
---

# Phase 03 Plan 02: AnalysisEngine + AnalysisStore Summary

**One-liner:** Pure AnalysisEngine enum + @Observable AnalysisStore with dirty-flag cache, #if DEBUG test-seam, and invalidation hook wired through StackItemFactory.

## Files Created

| File | Purpose |
|------|---------|
| `StackWise/Analysis/AnalysisResults.swift` | Pure value type grouping critical/advisory/synergy/notInDatabase pairs with severity and synergy query helpers |
| `StackWise/Analysis/AnalysisEngine.swift` | Pure enum with `analyze(activeItems:pairFetcher:)` static method — no imports, no side effects |
| `StackWise/Analysis/AnalysisStore.swift` | @Observable cache layer; dirty-flag invalidation; #if DEBUG test-seam init bypassing InteractionRepository |
| `StackWiseTests/AnalysisEngineTests.swift` | 6 synthetic unit tests covering routing, empty stack, single item, and notInDatabase ordering |
| `StackWiseTests/AnalysisStoreTests.swift` | 4 tests using in-memory Core Data; exercises dirty flag, cache hit, invalidate, and nil clearing |

## Files Modified

| File | Change |
|------|--------|
| `StackWise/Features/Stack/StackItemFactory.swift` | Added `onSaved: (() -> Void)? = nil` parameter to `create(_:in:)`; called after `context.save()` |
| `StackWise/Features/Stack/AddItemView.swift` | Added `@Environment(AnalysisStore.self) private var analysisStore`; passed `onSaved: { analysisStore.invalidate() }` to factory |
| `StackWise/StackWiseApp.swift` | Rewrote with custom `init()` pattern so `AnalysisStore(repo: inter, ...)` can reference the same `InteractionRepository` instance |

## Implementation Notes

**Typed accessors vs KVC:** `StackItem+CoreDataClass.swift` has typed computed properties (`labelValue`, `activeIngredientValue`) and a direct `Bool` property (`isInDatabase`). `AnalysisStore.recompute()` uses these typed accessors — no `value(forKey:)` KVC calls.

**#if DEBUG test-seam:** `AnalysisStore` has a second `init(pairFetcher:context:)` available only in DEBUG builds. This lets tests inject a mock pair fetcher without touching `InteractionRepository` (which opens a real SQLite handle). The production `repo.pairwise(for:)` is still used in release builds.

**AnalysisEngine short-circuits:** When the active stack has fewer than 2 in-database items, `AnalysisEngine` returns early without calling `pairFetcher`. Tests that pass an empty context will never invoke the fetcher closure — this is expected and documented in `AnalysisStoreTests`.

**StackWiseApp rewrite rationale:** Wave 1 (03-01) added `interactionRepo` as a property-wrapper init (`@State private var interactionRepo = InteractionRepository()`). `AnalysisStore` requires a reference to that same instance. The property-wrapper init form cannot reference sibling `@State` properties, so the entire `StackWiseApp` was converted to the custom `init()` pattern using `State(initialValue:)`.

## Deviations from Plan

None — plan executed exactly as written. All verification checks passed.

## Self-Check: PASSED

- `StackWise/Analysis/AnalysisResults.swift` — found
- `StackWise/Analysis/AnalysisEngine.swift` — found
- `StackWise/Analysis/AnalysisStore.swift` — found
- `StackWiseTests/AnalysisEngineTests.swift` — found
- `StackWiseTests/AnalysisStoreTests.swift` — found
- Commit `1afbdba` — feat(03-02): AnalysisEngine + AnalysisStore + invalidation hook
- No SwiftUI import in AnalysisEngine.swift — confirmed (0 matches)
- No SwiftUI import in AnalysisResults.swift — confirmed (0 matches)
- `onSaved` in StackItemFactory.swift — 2 matches (signature + call site)
- `analysisStore.invalidate` in AddItemView.swift — 1 match
- `analysisStore` in StackWiseApp.swift — 3 matches
