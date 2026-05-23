---
phase: 04-smart-schedule
reviewed: 2026-05-22T12:00:00Z
depth: deep
files_reviewed: 17
files_reviewed_list:
  - StackWise/Schedule/TimingProperties.swift
  - StackWise/Schedule/ScheduleStore.swift
  - StackWise/Schedule/ScheduleResult.swift
  - StackWise/Schedule/ScheduleEngine.swift
  - StackWise/Data/IngredientRepository.swift
  - StackWise/StackWiseApp.swift
  - StackWise/Features/Schedule/ScheduleView.swift
  - StackWise/Features/Stack/AddItemView.swift
  - StackWiseTests/ScheduleEngineTests.swift
  - StackWiseTests/ScheduleStoreTests.swift
  - StackWiseTests/IngredientRepositoryTests.swift
  - StackWise/ContentView.swift
  - StackWise/Persistence.swift
  - StackWise/Models/StackItem+CoreDataClass.swift
  - StackWise/Models/ScheduledDose+CoreDataClass.swift
  - StackWise/Analysis/AnalysisStore.swift
  - StackWise/DesignSystem.swift
findings:
  critical: 3
  warning: 5
  info: 2
  total: 10
status: issues_found
---

# Phase 4: Code Review Report (Deep)

**Reviewed:** 2026-05-22
**Depth:** deep
**Files Reviewed:** 17
**Status:** issues_found

## Summary

This is a second-pass deep review after 9 fixes were applied from the standard-depth review. The core schedule engine logic is sound and well-tested. However, cross-file analysis reveals several remaining issues: a missing `@MainActor` annotation on `AnalysisStore` that creates a data race when called from `@MainActor`-isolated `ScheduleView`, a synchronous SQLite call on the main thread within `ScheduleStore.recompute()`, and a silent failure path in `AddItemView.save()` that swallows errors in production builds. These are the most significant findings.

## Critical Issues

### CR-01: AnalysisStore missing @MainActor -- data race from ScheduleView

**File:** `StackWise/Analysis/AnalysisStore.swift:3-4`
**Issue:** `AnalysisStore` is `@Observable` but NOT `@MainActor`-isolated. Meanwhile, `ScheduleStore` IS `@MainActor`. Both are injected into the SwiftUI environment from `StackWiseApp`. `ScheduleItemRow` (in `ScheduleView.swift:101`) calls `analysisStore.currentResults()` from the view body (main actor). `currentResults()` calls `recompute()` which accesses Core Data's `viewContext`. Since `AnalysisStore` has no actor isolation, nothing prevents concurrent access to its mutable `results` and `dirty` properties from different contexts. With Swift 6 strict concurrency, this will be a compile error. Even on Swift 5, this is a runtime data race on `results`/`dirty`.

**Cross-file trace:** `ScheduleView.body` -> `ScheduleItemRow.badges` -> `analysisStore.currentResults()` -> `AnalysisStore.recompute()` -> `context().fetch()` (viewContext on unknown actor).

**Fix:**
```swift
@MainActor
@Observable
final class AnalysisStore {
    // ... rest unchanged
}
```

### CR-02: ScheduleStore.recompute() calls SQLite on main actor

**File:** `StackWise/Schedule/ScheduleStore.swift:74-76`
**Issue:** `ScheduleStore` is `@MainActor`. `recompute()` is called synchronously from `currentSchedule()` (line 33). Inside `recompute()`, line 74-76 calls `ingredientRepo.timingProperties(for:)` in a loop, which executes raw `sqlite3_prepare_v2`/`sqlite3_step` against the bundled SQLite database. Similarly, line 62 calls `interactionRepo.pairwise(for:)` which does the same. Both are synchronous SQLite I/O on the main thread. For typical stacks (5-15 items, small slug sets), this is likely under 16ms, but it is still blocking the main thread with disk I/O. The previous fix (WR-07) moved SQLite search off main actor in `AddItemView`, but this call path in `ScheduleStore` was not addressed.

**Fix:** This is a structural issue. The cleanest fix is to make `recompute()` async and call SQLite work off the main actor:
```swift
func currentSchedule() async -> ScheduleResult {
    if dirty || cachedResult == nil {
        await recompute()
    }
    return cachedResult ?? ScheduleResult.empty
}

private func recompute() async {
    // ... Core Data fetch on main actor ...
    let timingProps = await Task.detached {
        var props: [String: TimingProperties] = [:]
        for slug in slugs {
            props[slug] = self.ingredientRepo.timingProperties(for: slug)
        }
        return props
    }.value
    // ... etc
}
```
If the async refactor is too invasive for this phase, document this as a known tech debt item with a maximum acceptable slug count (e.g., 20 slugs) and add a performance assertion.

### CR-03: AddItemView.save() silently swallows errors in production

**File:** `StackWise/Features/Stack/AddItemView.swift:131-135`
**Issue:** The `save()` function catches the error from `StackItemFactory.create()` but only calls `assertionFailure()` in the catch block. In a Release build, `assertionFailure` is a no-op. The user taps "Add", the save fails, and the user sees no feedback at all. The item simply does not appear and the sheet remains open. There is no error alert, no toast, no retry mechanism. This is a data loss scenario: the user believes they added an item but nothing happened.

**Fix:**
```swift
@State private var errorMessage: String?

private func save() {
    let input = StackItemFactory.Input(...)
    do {
        _ = try StackItemFactory.create(input, in: context, onSaved: {
            analysisStore.invalidate()
            scheduleStore.invalidate()
        })
        dismiss()
    } catch {
        errorMessage = "Could not save item. Please try again."
    }
}
// In body, add:
.alert("Error", isPresented: Binding(
    get: { errorMessage != nil },
    set: { if !$0 { errorMessage = nil } }
)) {
    Button("OK") { errorMessage = nil }
} message: {
    Text(errorMessage ?? "")
}
```

## Warnings

### WR-01: ScheduleView reads cachedResult without triggering recompute on dirty

**File:** `StackWise/Features/Schedule/ScheduleView.swift:8-9`
**Issue:** The computed property `schedule` reads `scheduleStore.cachedResult ?? .empty` directly, bypassing `currentSchedule()`. The `.task` modifier on line 57 calls `scheduleStore.currentSchedule()` once on appear. But if another view (e.g., `AddItemView`) calls `scheduleStore.invalidate()` while `ScheduleView` is already displayed, `invalidate()` only sets `dirty = true` without changing `cachedResult`. The `@Observable` tracking on `cachedResult` will NOT trigger a re-render because `cachedResult` was not mutated. The view continues showing stale data. The user must navigate away and back to trigger `.task` again.

**Fix:** Either nil out `cachedResult` in `invalidate()` to trigger the observation:
```swift
func invalidate() {
    dirty = true
    cachedResult = nil
}
```
Or eagerly recompute:
```swift
func invalidate() {
    dirty = true
    recompute()
}
```

### WR-02: ScheduleEngine Rule 2 only moves one item per conflict pair -- multi-pair conflicts ignored

**File:** `StackWise/Schedule/ScheduleEngine.swift:95-134`
**Issue:** Rule 2 iterates over conflict pairs sequentially and moves items. But if item A conflicts with both B and C, the loop processes pairs independently. A move to resolve one conflict might place an item into a block that violates another conflict that was already processed. For real supplement stacks (iron + calcium + zinc is extremely common), this single-pass approach can produce schedules where timing-relevant conflicts remain unresolved. Additionally, `hasTimingConflict` is hardcoded to `false` (line 188), so the UI cannot even warn users about unresolved conflicts.

**Fix:** Add a second validation pass after all Rule 2 moves that checks all conflict pairs against final assignments and sets `hasTimingConflict = true` on items that still violate their timing windows.

### WR-03: IngredientRepository and InteractionRepository are not Sendable

**File:** `StackWise/Data/IngredientRepository.swift:14`, `StackWise/Data/InteractionRepository.swift:37`
**Issue:** Both repositories are reference types holding raw `OpaquePointer` (sqlite3 handle) and are not marked `Sendable`. They are created in `StackWiseApp.init()` and passed across actor boundaries (into `@MainActor` `ScheduleStore`, and via `Task` in `AddItemView.scheduleSearch()`). The `SQLITE_OPEN_FULLMUTEX` flag provides thread safety at the SQLite level, so concurrent access won't corrupt data. However, Swift strict concurrency checking will flag these as sendability violations, and this will become a hard error with Swift 6.

**Fix:** Conform both repositories to `@unchecked Sendable`:
```swift
final class IngredientRepository: @unchecked Sendable {
```

### WR-04: ScheduleStore.recompute() uses date(bySettingHour:) which can return unexpected dates

**File:** `StackWise/Schedule/ScheduleStore.swift:85-89`
**Issue:** `Calendar.date(bySettingHour:minute:second:of:)` with the default `.forward` direction may return tomorrow's date if the specified time has already passed today. If called at 1 PM: `wakeTime` (7 AM) could resolve to tomorrow, while `dinnerTime` (6 PM) resolves to today. Since the engine uses these dates only for `abs(timeA.timeIntervalSince(timeB)) / 3600` separation math, cross-day dates would still produce correct absolute separations. However, the behavior is fragile and non-obvious -- a subtle change to the separation logic (e.g., removing `abs()`) would silently break.

**Fix:** Pin all times to the same base date:
```swift
let cal = Calendar.current
let baseComponents = cal.dateComponents([.year, .month, .day], from: now)
func makeTime(hour: Int, minute: Int) -> Date {
    var c = baseComponents
    c.hour = hour; c.minute = minute; c.second = 0
    return cal.date(from: c)!
}
let wakeTime = profile?.wakeTime ?? makeTime(hour: 7, minute: 0)
```

### WR-05: textPrimary and textSecondary colors are not adaptive -- unreadable in dark mode

**File:** `StackWise/DesignSystem.swift:61-62`
**Issue:** `textPrimary` uses `Color(hex: "#3A3830")` (dark brown) and `textSecondary` uses `Color(hex: "#706C60")` (medium gray-brown). These are non-adaptive single-color definitions. In dark mode on a near-black background (`#1C1C1E`), these dark text colors become nearly invisible. Other neutral colors in the same file correctly use `Color(lightHex:darkHex:)`. These colors are used for user-facing text in `ScheduleItemRow` (lines 113, 119) and `AddItemView` (lines 57-58, 69).

**Fix:**
```swift
static let textPrimary   = Color(lightHex: "#3A3830", darkHex: "#F5F5F5")
static let textSecondary = Color(lightHex: "#706C60", darkHex: "#AEAEB2")
```

## Info

### IN-01: hasTimingConflict flag is always false -- dead field

**File:** `StackWise/Schedule/ScheduleEngine.swift:188`
**Issue:** `hasTimingConflict` is hardcoded to `false` for all scheduled items. The field exists on `ScheduledItem` but is never populated with actual conflict detection results. The comment says "simplified: conflict detection in AnalysisStore" but `AnalysisResults` does not expose per-item timing conflict data either.

**Fix:** Either implement the conflict detection or remove the field. If keeping for a future phase, add a `// TODO Phase N:` comment.

### IN-02: Unused allAssignments parameter in makeItems

**File:** `StackWise/Schedule/ScheduleEngine.swift:173`
**Issue:** The `allAssignments` parameter of the local `makeItems` function is declared but never referenced inside the function body. It is passed on lines 195-197 but serves no purpose.

**Fix:** Remove the parameter:
```swift
func makeItems(
    _ projections: [ItemProjection],
    block: Block,
    pairs: [PairProjection]
) -> [ScheduledItem] {
```

---

_Reviewed: 2026-05-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
