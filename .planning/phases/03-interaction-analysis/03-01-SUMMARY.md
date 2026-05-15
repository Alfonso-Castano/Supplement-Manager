---
phase: "03"
plan: "01"
subsystem: "interaction-analysis"
tags: [sqlite, repository, interactions, observable, tests]
requires:
  - "Phase 2 IngredientRepository pattern (open/close/prepare/finalize)"
  - "Bundled stackwise.sqlite with interactions table (63 rows, verified 2026-05-14)"
provides:
  - "Read-only SQLite layer for the interactions table"
  - "Pairwise interaction lookup over a set of canonical-name slugs"
  - "InteractionPair value type for downstream AnalysisEngine consumption"
affects:
  - "StackWiseApp environment composition (adds interactionRepo)"
  - "IngredientRepository.deinit close-API (CF-6 carry-forward fix)"
tech-stack:
  added: []
  patterns:
    - "Read-only sqlite3_open_v2 with SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX"
    - "sqlite3_close_v2 in deinit (Phase 3 close pattern)"
    - "Pairwise IN/IN SQL filter with twice-bound slugs"
key-files:
  created:
    - "StackWise/Data/InteractionRepository.swift"
    - "StackWiseTests/InteractionRepositoryTests.swift"
    - ".planning/phases/03-interaction-analysis/03-01-SUMMARY.md"
  modified:
    - "StackWise/Data/IngredientRepository.swift (1 line: sqlite3_close → sqlite3_close_v2)"
    - "StackWise/StackWiseApp.swift (2 lines: @State + .environment)"
decisions:
  - "D-26 honored: separate InteractionRepository class, no shared handle with IngredientRepository"
  - "D-26a / CF-6 applied: IngredientRepository.deinit upgraded to sqlite3_close_v2"
  - "D-32 honored: IN/IN SQL filter; no direction-column predicate needed (canonical ordering in DB)"
  - "D-33 honored: Mac handoff deferred to end-of-phase batch (Plan 03-04)"
metrics:
  completed: "2026-05-14"
---

# Phase 3 Plan 01: InteractionRepository Summary

One-liner: Adds a read-only `@Observable InteractionRepository` over the bundled `stackwise.sqlite` `interactions` table, exposing `pairwise(for: Set<String>) -> [InteractionPair]`, wired into the SwiftUI environment, with 5 XCTest cases (3 dynamic-discovery + 2 known-pair probes) — plus the CF-6 carry-forward (`sqlite3_close_v2`) on `IngredientRepository.deinit`.

## Files Added / Modified

| Path | Status | Notes |
|------|--------|-------|
| `StackWise/Data/InteractionRepository.swift` | added | New `@Observable final class`, mirrors `IngredientRepository` open/close pattern. |
| `StackWiseTests/InteractionRepositoryTests.swift` | added | 5 tests: empty-input short-circuit, dynamic real-pair probe, single-sided rejection, warfarin/vitamin_k2 critical pair, vitamin_c/iron synergy pair. |
| `StackWise/Data/IngredientRepository.swift` | modified | CF-6: line 33 only — `sqlite3_close(db)` → `sqlite3_close_v2(db)`. No other change. |
| `StackWise/StackWiseApp.swift` | modified | Added `@State private var interactionRepo = InteractionRepository()` and `.environment(interactionRepo)` directly after the ingredientRepo injection. |

## Public Surface of `InteractionRepository`

```swift
enum InteractionSeverity: String { case advisory, critical }

enum InteractionType: String {
    case absorptionCompetition = "absorption_competition"
    case timingConflict        = "timing_conflict"
    case unsafeCombination     = "unsafe_combination"
    case synergy
}

enum InteractionDirection: String { case bidirectional, directional }

struct InteractionPair: Equatable, Identifiable {
    let id: Int64
    let compoundA: String
    let compoundB: String
    let compoundAType: String
    let compoundBType: String
    let interactionType: InteractionType
    let severity: InteractionSeverity
    let direction: InteractionDirection?
    let mechanism: String?
    let effect: String
    let suggestedAction: String
    let timingRelevant: Bool
    let timingWindowHours: Int?
    let citations: String
    let confidence: String
    let conflictNote: String?
}

@Observable
final class InteractionRepository {
    init(bundle: Bundle = .main, resource: String = "stackwise", ext: String = "sqlite")
    deinit
    func pairwise(for slugs: Set<String>) -> [InteractionPair]
}
```

Signatures match 03-01-PLAN.md Task 1 verbatim.

## CF-6 Fold-In

`IngredientRepository.deinit` now calls `sqlite3_close_v2(db)` instead of `sqlite3_close(db)`. One-line change at line 33. No other Phase-2 carry-forward items (CF-3, CF-4, CF-5) were touched.

## Verification (Windows, mandatory)

| Check | Expected | Result |
|-------|----------|--------|
| Glob `StackWise/Data/InteractionRepository.swift` | file present | PASS |
| Glob `StackWiseTests/InteractionRepositoryTests.swift` | file present | PASS |
| Grep `sqlite3_close_v2` in `IngredientRepository.swift` | exactly 1 match | PASS (line 33) |
| Grep `sqlite3_close_v2` in `InteractionRepository.swift` | exactly 1 match | PASS (line 56, deinit) |
| Grep `interactionRepo` in `StackWiseApp.swift` | ≥2 matches | PASS (line 8 decl + line 16 injection) |

Build / `xcodebuild test` verification is batched to the end-of-phase Mac handoff per D-33 (Plan 03-04 closing checkpoint).

## Deviations from Plan

**No deviations.** Public surface, SQL shape (IN/IN with twice-bound slugs), enum cases, struct fields, and CF-6 line-33 edit all match 03-01-PLAN.md as written.

Notes on implementation choices that fall under "Claude's discretion":
- For nullable text columns (`citations`, `confidence`), the DB schema marks them NOT NULL but the Swift code defensively defaults to empty string if a NULL ever appears. This matches the "do not crash on unexpected NULL" tone of Task 1.
- `compound_a_type` / `compound_b_type` are surfaced as raw `String` (`"supplement"` | `"drug"`) rather than a Swift enum — the plan's struct definition specified `String`, and Phase 3 has no immediate consumer that needs enum exhaustiveness.

## Known Stubs

None. `pairwise(for:)` is fully wired against the real bundled DB. No placeholder data.

## Phase-3 Follow-Ups

- **Plan 03-02** will rewrite `StackWiseApp.init()` to construct `interactionRepo` and `analysisStore` together (the `analysisStore` depends on `interactionRepo`). The current `@State private var interactionRepo = InteractionRepository()` declaration will be replaced by an explicit `init()` initializer at that time. This is intentional — 03-01 keeps the structure minimal per the executor brief.
- **Plan 03-04** owns the Mac handoff: add `InteractionRepository.swift` to the `StackWise` Xcode target and `InteractionRepositoryTests.swift` to the `StackWiseTests` target, then run `xcodebuild test`. Expected new test count: ≥5 (project total ≥26).
- Out-of-scope Phase-2 carry-forward items CF-3, CF-4, CF-5 remain deferred — they are not folded into Plan 03-01 by design.

## Self-Check: PASSED

- `StackWise/Data/InteractionRepository.swift`: FOUND
- `StackWiseTests/InteractionRepositoryTests.swift`: FOUND
- `sqlite3_close_v2` in `IngredientRepository.swift`: exactly 1 match (deinit, line 33)
- `sqlite3_close_v2` in `InteractionRepository.swift`: exactly 1 match (deinit, line 56)
- `interactionRepo` in `StackWiseApp.swift`: 2 matches (decl + injection)
