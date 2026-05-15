---
phase: 04-smart-schedule
reviewed: 2026-05-15T12:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - StackWise/Schedule/TimingProperties.swift
  - StackWise/Schedule/ScheduleStore.swift
  - StackWise/Schedule/ScheduleResult.swift
  - StackWise/Schedule/ScheduleEngine.swift
  - StackWise/Data/IngredientRepository.swift
  - StackWise/StackWiseApp.swift
  - StackWise/Features/Schedule/ScheduleView.swift
  - StackWise/Features/Stack/AddItemView.swift
  - StackWiseTests/IngredientRepositoryTests.swift
  - StackWiseTests/ScheduleEngineTests.swift
  - StackWiseTests/ScheduleStoreTests.swift
findings:
  critical: 3
  warning: 7
  info: 2
  total: 12
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-05-15T12:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

The Phase 4 smart scheduling feature adds a pure scheduling algorithm (ScheduleEngine), a store layer (ScheduleStore) that bridges Core Data, and UI (ScheduleView). The algorithm logic is reasonable and well-tested for the happy path. However, there are thread-safety issues with the `@Observable` ScheduleStore being called from SwiftUI body computations that trigger Core Data work on the main thread without guarantees, a SQL injection vector in IngredientRepository, and several logic bugs in the scheduling engine's priority/conflict resolution.

## Critical Issues

### CR-01: SQL Injection via LIKE Pattern in IngredientRepository.search()

**File:** `StackWise/Data/IngredientRepository.swift:57-58`
**Issue:** The `search()` method interpolates user input directly into LIKE patterns via string interpolation (`"%\(trimmed)%"` and `"\(trimmed)%"`). While these are bound via `sqlite3_bind_text`, the LIKE metacharacters `%` and `_` within `trimmed` are not escaped. A user typing `%` or `_` in the search field would match unintended rows. More critically, if the search string contains a `'` or a NUL byte, while `sqlite3_bind_text` handles quoting correctly, the LIKE wildcards allow a user to craft a pattern that scans the entire table (e.g., entering `%` returns everything up to the limit). This is a data exposure issue -- not a classic SQL injection since parameterized binding is used, but the LIKE wildcards are still injectable.

**Reclassification note:** The parameterized binding prevents actual SQL injection. Downgrading the immediate SQL injection concern but keeping BLOCKER severity because: the `%` and `_` wildcards in user-controlled LIKE patterns cause incorrect query behavior. A user typing `_` as a search will match all single-character ingredient names unexpectedly.

**Fix:**
```swift
private func escapeLikePattern(_ input: String) -> String {
    input
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "%", with: "\\%")
        .replacingOccurrences(of: "_", with: "\\_")
}
// Then in the SQL add ESCAPE '\\' to each LIKE clause, and use:
let likePattern = "%\(escapeLikePattern(trimmed))%"
let prefixPattern = "\(escapeLikePattern(trimmed))%"
```

### CR-02: ScheduleStore.recompute() Silently Swallows Core Data Save Failures

**File:** `StackWise/Schedule/ScheduleStore.swift:142`
**Issue:** `try? ctx.save()` silently discards Core Data save errors. If the save fails (e.g., validation error, store conflict), the in-memory `cachedResult` is updated to the new schedule but the persistent store retains stale/deleted ScheduledDose records. This creates a divergence between the cached state and persisted state. On next app launch, the persisted ScheduledDose data will be inconsistent with what the user last saw. This is a data integrity/data loss risk.

**Fix:**
```swift
do {
    try ctx.save()
} catch {
    // Roll back context to keep in-memory state consistent with store
    ctx.rollback()
    // Optionally: don't update cachedResult if save failed
    assertionFailure("ScheduleStore save failed: \(error)")
    return
}
cachedResult = result
dirty = false
```

### CR-03: ScheduleView.schedule Computed Property Triggers Recompute Inside SwiftUI Body

**File:** `StackWise/Features/Schedule/ScheduleView.swift:8-10`
**Issue:** The `schedule` computed property calls `scheduleStore.currentSchedule()`, which may trigger `recompute()` -- a method that performs Core Data fetches, deletes all ScheduledDose records, creates new ones, and calls `ctx.save()`. This all happens synchronously during SwiftUI's `body` evaluation. SwiftUI may call `body` multiple times, on any thread (though typically main). Performing destructive Core Data writes (delete + insert + save) as a side effect of a view's body computation is dangerous: (1) it can cause infinite re-render loops since the `@Observable` store mutates `cachedResult` which triggers another body evaluation, (2) body should be pure and free of side effects.

**Fix:** Move the schedule computation out of the body. Use `.task` or `.onAppear` to trigger computation, and have the view only read `cachedResult`:
```swift
var body: some View {
    NavigationStack {
        // read cachedResult directly, never trigger recompute from body
        let schedule = scheduleStore.cachedResult ?? .empty
        // ... rest of view
    }
    .task {
        scheduleStore.currentSchedule() // trigger recompute outside body
    }
}
```

## Warnings

### WR-01: ScheduleEngine Rule 2 Conflict Resolution Can Override Prescription Placement

**File:** `StackWise/Schedule/ScheduleEngine.swift:89-118`
**Issue:** Rule 2 (timing-conflict separation) can move a prescription to a different block than where Rule 1 placed it. The priority logic on line 103 says "supplement over prescription" but the condition `!itemA.isPrescription && (itemB.isPrescription || ...)` only determines *which* item moves -- it does not prevent moving the prescription if `itemB` is the prescription and `itemA` has higher priority. Specifically: if both items are prescriptions, the one with higher `sortOrder` gets moved. If only one is a prescription, the supplement moves. But this means the supplement could be moved to a block that conflicts with its own `requiresEmptyStomach` or `requiredFood` constraint from Rule 3, since Rule 2 runs after Rule 3 without re-checking those constraints.

**Fix:** After Rule 2 reassignment, re-validate that the moved item's timing constraints (from `timingProps`) are still satisfied. If not, skip the move.

### WR-02: avoidWithCaffeine Property Is Decoded But Never Used

**File:** `StackWise/Schedule/TimingProperties.swift:7`, `StackWise/Schedule/ScheduleEngine.swift:40-177`
**Issue:** `TimingProperties.avoidWithCaffeine` is parsed from JSON and stored, but `ScheduleEngine.schedule()` never references it. Items that should avoid caffeine (e.g., iron) are not separated from caffeine-containing items. This is dead logic that gives users a false sense of safety if the DB marks an ingredient as `avoidWithCaffeine: true`.

**Fix:** Either implement caffeine avoidance logic (move such items away from morning if caffeine is typically consumed then) or remove the property to avoid misleading the data model.

### WR-03: ScheduleStore Is Not Thread-Safe

**File:** `StackWise/Schedule/ScheduleStore.swift:6-9`
**Issue:** `ScheduleStore` is an `@Observable` class with mutable state (`dirty`, `cachedResult`) but no synchronization. `invalidate()` can be called from `AddItemView.save()` (main thread), while `currentSchedule()` could be called from body evaluation. If a background task or concurrent view ever calls these methods, there is a data race on `dirty` and `cachedResult`. The `@Observable` macro does not provide thread safety. Currently this may work if everything stays on the main thread, but the code has no `@MainActor` annotation to enforce that invariant.

**Fix:** Add `@MainActor` to the class:
```swift
@MainActor
@Observable
final class ScheduleStore {
```

### WR-04: ScheduleView.profile Computed Property Fetches Core Data in Body

**File:** `StackWise/Features/Schedule/ScheduleView.swift:12-16`
**Issue:** The `profile` computed property executes a Core Data fetch (`context.fetch(request)`) every time `sectionHeader()` is called during body evaluation. This is called up to 3 times per body evaluation (once per section header). While not a crash risk, it is wasteful and violates the principle that SwiftUI body should be side-effect-free. The `try?` also silently swallows fetch errors.

**Fix:** Cache the profile in a `@State` variable, loaded via `.task` or `.onAppear`.

### WR-05: ScheduleStore.recompute() Generates New UUID for Items with nil id

**File:** `StackWise/Schedule/ScheduleStore.swift:93`
**Issue:** `item.id ?? UUID()` generates a fresh UUID for any StackItem that has a nil `id`. This means: (1) the generated UUID will not match any key in `itemLookup` (line 119-124), so the `ScheduledDose.stackItem` relationship will be nil for that dose; (2) a new random UUID is generated on every recompute call, so the ScheduledItem identity changes each time, potentially causing SwiftUI `ForEach` identity thrashing.

**Fix:** StackItems with nil `id` should be filtered out before scheduling, or `id` should be made non-optional with a default value at creation time. At minimum, log a warning:
```swift
let projections: [ScheduleEngine.ItemProjection] = items.compactMap { item in
    guard let id = item.id else {
        assertionFailure("StackItem missing id")
        return nil
    }
    return ScheduleEngine.ItemProjection(
        id: id, ...
    )
}
```

### WR-06: Evening Overflow Not Handled in Rule 4

**File:** `StackWise/Schedule/ScheduleEngine.swift:137-144`
**Issue:** The overflow logic spills morning overflow into afternoon, and afternoon overflow into evening, but if evening exceeds 5 items there is no further spill. With enough items (e.g., 16+ total, or many evening-constrained items), the evening block could have far more than 5 items. The block limit of 5 becomes unenforced for the last block.

**Fix:** Either document that evening has no cap, or handle it (e.g., split into multiple evening sub-blocks, or warn the user).

### WR-07: IngredientRepository Accessed from Main Thread for SQLite I/O

**File:** `StackWise/Features/Stack/AddItemView.swift:105`
**Issue:** `repo.search(trimmed)` is called inside a `Task { @MainActor in ... }` block. Despite the 200ms debounce, the SQLite query itself runs on the main actor, blocking the UI thread. The `IngredientRepository` opens the database with `SQLITE_OPEN_FULLMUTEX` (serialized mode), which means all SQLite calls are serialized. If the database is large or the query is complex, this blocks the main thread.

**Fix:** Run the search on a background task and hop back to main for UI update:
```swift
searchTask = Task {
    try? await Task.sleep(nanoseconds: 200_000_000)
    guard !Task.isCancelled else { return }
    let results = repo.search(trimmed) // runs off main actor
    guard !Task.isCancelled else { return }
    await MainActor.run { suggestions = results }
}
```

## Info

### IN-01: ScheduleEngine Synergy Flag Only Checks Pair Existence, Not Co-location

**File:** `StackWise/Schedule/ScheduleEngine.swift:155-156`
**Issue:** The `hasSynergyFlag` checks if any synergy pair exists for the ingredient across all pairs, regardless of whether the synergy partner is actually in the same block. The comment on `ScheduledItem.hasSynergy` says "true if a synergy pair partner is in any block" which is accurate, but the flag is misleading -- it does not indicate the items are co-located to benefit from synergy. A user might think synergy is "active" when the partner is in a different time block.

**Fix:** Consider checking that the synergy partner is in the same block, or rename the flag to clarify its meaning (e.g., `hasSynergyPartnerInStack`).

### IN-02: DateFormatter Created on Every sectionHeader Call

**File:** `StackWise/Features/Schedule/ScheduleView.swift:89-90`
**Issue:** A new `DateFormatter` is created each time `sectionHeader()` is called (up to 3 times per body evaluation). `DateFormatter` is expensive to create. This should be a static or cached instance.

**Fix:**
```swift
private static let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()
```

---

_Reviewed: 2026-05-15T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
