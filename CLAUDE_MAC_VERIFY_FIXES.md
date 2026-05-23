# Mac Verification: Deep Review Fixes

**Date:** 2026-05-23
**Context:** 8 code review fixes were applied after a deep review of Phase 4. These changes modify source files that previously passed 48/48 tests. This verification confirms nothing regressed and the fixes work correctly.

---

## Step 1: Pull and Build

```bash
cd ~/Documents/Supplement-Manager
git pull origin main
```

Verify you see these commits (newest first):
```
e5ffaba fix(04): cache DateFormatter in ScheduleView as static property
15fb077 fix(04): add second-pass conflict validation and populate hasTimingConflict flag
1219cbd fix(04): pin fallback times to same base date in ScheduleStore.recompute
63a386b fix(04): show error alert when AddItemView save fails instead of silent swallow
48f842e fix(04): nil cachedResult on invalidate to trigger ScheduleView re-render
4b9d5d2 fix(04): make textPrimary and textSecondary adaptive for dark mode
e7e2dc0 fix(04): mark repositories @unchecked Sendable for Swift 6 concurrency
796b52c fix(04): add @MainActor to AnalysisStore for thread safety
```

Then clean build:
```bash
xcodebuild clean build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Expected:** 0 errors, 0 warnings related to our code.

---

## Step 2: Run Full Test Suite

```bash
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(Test Suite|Test Case|Executed|FAIL|\*\* TEST)"
```

**Expected:** >= 48 tests passing, 0 failures. The same count as before the fixes.

If any tests fail, investigate and report the exact failure name and message. The most likely causes:
- `@MainActor` on `AnalysisStore` may require `@MainActor` on test methods in `AnalysisStoreTests.swift` — add it if needed
- `@MainActor` on `ScheduleStore` may require the same in `ScheduleStoreTests.swift` — add it if needed
- The `cachedResult = nil` change in `invalidate()` may affect `ScheduleStoreTests` assertions — check if tests expect non-nil after invalidate

---

## Step 3: Simulator Smoke Test

This is a quick smoke test, not the full golden path (that already passed).

1. Erase simulator: Device > Erase All Content and Settings
2. Launch app, complete onboarding (any values)
3. Add "iron" from DB suggestions
4. Add "calcium" from DB suggestions
5. Tap Schedule tab — verify items appear in blocks
6. Add "vitamin_c" — return to Schedule tab — verify it appears (tests WR-01 reactive update fix)
7. Toggle dark mode (Settings > Developer > Dark Appearance, or via Simulator menu) — verify text is readable in Schedule tab and Add Item view (tests WR-05 dark mode fix)

---

## Step 4: Report Results

After all steps, commit results:

```bash
cd ~/Documents/Supplement-Manager
git add -A
git commit -m "test(04): Mac verification of deep review fixes — [PASS/FAIL]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin main
```

---

## What Changed (for context)

| Commit | File | Change |
|--------|------|--------|
| `796b52c` | AnalysisStore.swift | Added `@MainActor` annotation |
| `e7e2dc0` | IngredientRepository.swift, InteractionRepository.swift | Added `: @unchecked Sendable` |
| `4b9d5d2` | DesignSystem.swift | `textPrimary`/`textSecondary` now use `Color(lightHex:darkHex:)` |
| `48f842e` | ScheduleStore.swift | `invalidate()` now sets `cachedResult = nil` |
| `63a386b` | AddItemView.swift | Save error shows `.alert` instead of silent `assertionFailure` |
| `1219cbd` | ScheduleStore.swift | Fallback times use `pinned()` helper on same base date |
| `15fb077` | ScheduleEngine.swift | Rule 2b second-pass conflict validation; `hasTimingConflict` now populated; removed unused `allAssignments` param |
| `e5ffaba` | ScheduleView.swift | Static `DateFormatter` cache |

## Known Risk: @MainActor on Tests

The `@MainActor` additions to `AnalysisStore` and `ScheduleStore` may cause test compilation errors if test methods access these stores without main actor isolation. If you see errors like:

```
Call to main actor-isolated instance method 'currentResults()' in a synchronous nonisolated context
```

Fix by adding `@MainActor` to the test class:
```swift
@MainActor
final class AnalysisStoreTests: XCTestCase {
```

Same for `ScheduleStoreTests` if it doesn't already have it.
