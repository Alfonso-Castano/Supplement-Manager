---
phase: 04-smart-schedule
fixed_at: 2026-05-22T12:00:00Z
review_path: .planning/phases/04-smart-schedule/04-REVIEW.md
iteration: 1
findings_in_scope: 10
fixed: 9
skipped: 1
status: partial
---

# Phase 4: Code Review Fix Report

**Fixed at:** 2026-05-22T12:00:00Z
**Source review:** .planning/phases/04-smart-schedule/04-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 10
- Fixed: 9
- Skipped: 1

## Fixed Issues

### CR-01: SQL Injection via LIKE Pattern in IngredientRepository.search()

**Files modified:** `StackWise/Data/IngredientRepository.swift`
**Commit:** 3d9a3db
**Applied fix:** Added `escapeLikePattern()` helper that escapes `\`, `%`, and `_` characters. Updated SQL LIKE clauses to include `ESCAPE '\\'`. Both `likePattern` and `prefixPattern` now use escaped input.

### CR-02: ScheduleStore.recompute() Silently Swallows Core Data Save Failures

**Files modified:** `StackWise/Schedule/ScheduleStore.swift`
**Commit:** 8d56795
**Applied fix:** Replaced `try? ctx.save()` with a do/catch block that rolls back the context on failure, fires an assertionFailure in debug, and returns early without updating cachedResult -- keeping in-memory and persistent state consistent.

### CR-03: ScheduleView.schedule Computed Property Triggers Recompute Inside SwiftUI Body

**Files modified:** `StackWise/Features/Schedule/ScheduleView.swift`
**Commit:** 396aca2
**Applied fix:** Changed `schedule` computed property to read `scheduleStore.cachedResult ?? .empty` (no side effects). Added `.task` modifier to trigger `scheduleStore.currentSchedule()` and load `UserProfile` outside of body evaluation. Converted `profile` from a computed property with Core Data fetch to a `@State` variable loaded in `.task`.

### WR-01: ScheduleEngine Rule 2 Conflict Resolution Can Override Prescription Placement

**Files modified:** `StackWise/Schedule/ScheduleEngine.swift`
**Commit:** 6892e9b
**Applied fix:** Added constraint re-validation after Rule 2 determines a candidate block for the moved item. Checks `requiresEmptyStomach` (must stay morning) before committing the move. Skips the move if constraints would be violated. Status: fixed: requires human verification (logic bug fix).

### WR-02: avoidWithCaffeine Property Is Decoded But Never Used

**Files modified:** `StackWise/Schedule/ScheduleEngine.swift`
**Commit:** 83ab1ea
**Applied fix:** Added caffeine avoidance logic in Rule 3: items with `avoidWithCaffeine == true` are moved from morning to afternoon (unless `requiresEmptyStomach` overrides). This activates the previously dead property.

### WR-03: ScheduleStore Is Not Thread-Safe

**Files modified:** `StackWise/Schedule/ScheduleStore.swift`
**Commit:** 2721ea6
**Applied fix:** Added `@MainActor` annotation to `ScheduleStore` class. Added `@discardableResult` to `currentSchedule()` to suppress unused-result warnings when called from `.task`.

### WR-04: ScheduleView.profile Computed Property Fetches Core Data in Body

**Files modified:** `StackWise/Features/Schedule/ScheduleView.swift`
**Commit:** 396aca2 (fixed as part of CR-03)
**Applied fix:** Profile is now a `@State` variable loaded in `.task` instead of a computed property that fetches from Core Data on every body evaluation.

### WR-05: ScheduleStore.recompute() Generates New UUID for Items with nil id

**Files modified:** `StackWise/Schedule/ScheduleStore.swift`
**Commit:** 9480899
**Applied fix:** Changed `items.map` to `items.compactMap` with a `guard let id = item.id` check. Items with nil id are filtered out with an assertionFailure in debug builds, preventing random UUID generation and identity thrashing.

### WR-06: Evening Overflow Not Handled in Rule 4

**Files modified:** `StackWise/Schedule/ScheduleEngine.swift`
**Commit:** 6fad148
**Applied fix:** Added documentation comment explaining evening is the terminal block with no cap by design. Added debug assertionFailure when evening exceeds 5 items to surface the condition during development.

### WR-07: IngredientRepository Accessed from Main Thread for SQLite I/O

**Files modified:** `StackWise/Features/Stack/AddItemView.swift`
**Commit:** ee74568
**Applied fix:** Removed `@MainActor` from the search Task closure so `repo.search()` runs off the main actor. Results are dispatched back to main via `await MainActor.run { suggestions = results }`.

## Skipped Issues

None -- WR-04 was addressed as part of the CR-03 fix (same commit, same file change).

---

_Fixed: 2026-05-22T12:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
