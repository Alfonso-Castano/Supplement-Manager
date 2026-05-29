---
phase: 6
reviewers: [claude]
reviewed_at: 2026-05-26T00:00:00Z
plans_reviewed:
  - 06-01-PLAN.md
  - 06-02-PLAN.md
  - 06-03-PLAN.md
  - 06-04-PLAN.md
  - 06-05-PLAN.md
note: Gemini CLI installed but requires API key authentication (not configured). Review performed by Claude in an independent analysis pass.
---

# Cross-AI Plan Review — Phase 6: Reminders & Today Tab

## Claude Review

### Summary

The Phase 6 plans are well-structured and demonstrate strong familiarity with iOS notification and Core Data patterns. The wave-based decomposition is logical, the architectural decisions (AppDelegate adaptor, pendingTab cold-start pattern, @AppStorage gate) are correct and well-justified, and the research document is unusually thorough. However, there is one significant logic gap in the notification scheduling lifecycle — **notifications will not fire for existing users who grant permission** — plus a few implementation inconsistencies in the test stubs that will produce compile errors. The plans are executable with targeted fixes.

### Strengths

- **Wave decomposition is sound.** Wave 1 (pure services, no UI) → Wave 2 (wiring) → Wave 3 (UI, parallelizable) → Wave 4 (tests + gate) is the right order. Each wave has clean dependency boundaries.
- **AppDelegate `pendingTab` pattern is correct and explicitly planned.** Cold-start notification tap handling is a well-known iOS gotcha; the research identified and the plan resolves it proactively.
- **`@AppStorage` for the notification permission gate is the right call.** Synchronous UserDefaults read prevents the race-condition flash (Pitfall 2 in RESEARCH.md) that a Core Data flag would cause.
- **Stable notification identifiers (not UUIDs) are correctly specified.** Using `"morning_reminder"` etc. prevents unbounded accumulation of pending requests.
- **Midnight normalization (`startOfDay`) is enforced at both write and predicate sites.** Pitfall 3 would be a silent data loss bug; the plan specifically addresses it.
- **DesignSystem token usage is consistently enforced** — no hardcoded hex anywhere in the plans.
- **Security posture is minimal and appropriate.** No attack surface is added; the threat model correctly marks all threats as low/accept.
- **Human checkpoint is a blocking gate (Plan 05, Task 3).** This is the right pattern for UI phases — automated tests are necessary but not sufficient.
- **`UNCalendarNotificationTrigger(repeats: true)` correctly chosen** over `UNTimeIntervalNotificationTrigger`. Daily repetition at the same time is exactly what supplement reminders need.
- **`@preconcurrency` on UNUserNotificationCenterDelegate conformance** is correctly applied — this prevents Swift concurrency warnings that would otherwise require ongoing suppression.

### Concerns

#### [HIGH] Notifications not scheduled after permission is granted

**Plans affected:** 06-03 (NotificationPermissionView), 06-02 (ScheduleStore integration)

The notification scheduling lifecycle has a gap:

1. User completes onboarding → `ScheduleStore.recompute()` runs (triggered by stack mutations during onboarding) → `NotificationScheduler.reschedule(for:)` is called → authorization status is **not yet granted** (permission screen hasn't appeared yet) → `NotificationScheduler` skips silently per D-11.
2. User sees `NotificationPermissionView`, taps "Enable Reminders" → permission granted → `onComplete()` called → `notificationPermissionShown = true` → ContentView switches to TabView.
3. At this point, **no code triggers another `ScheduleStore.recompute()`**. The `NotificationScheduler` has never successfully scheduled any requests.
4. Result: notifications are only scheduled the next time the user modifies their supplement stack (which triggers `invalidate()` → `recompute()` → `NotificationScheduler.reschedule()`). A user who never touches their stack after onboarding will never receive a reminder.

**Fix:** After `requestAuthorization` returns in `NotificationPermissionView`, explicitly call `NotificationScheduler.reschedule(for: scheduleStore.currentSchedule())` before calling `onComplete()`. Requires injecting `ScheduleStore` into `NotificationPermissionView`:

```swift
struct NotificationPermissionView: View {
    var onComplete: () -> Void
    @Environment(ScheduleStore.self) private var scheduleStore

    Button("Enable Reminders") {
        Task {
            try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            // Reschedule now that permission may have been granted
            NotificationScheduler.reschedule(for: scheduleStore.currentSchedule())
            onComplete()
        }
    }
}
```

---

#### [HIGH] `testSkipsWhenNotAuthorized` is a no-op test

**Plan affected:** 06-05, Task 1

The test body is:
```swift
NotificationScheduler.reschedule(for: result)
XCTAssertTrue(true, "reschedule(for:) must not crash...")
```

`XCTAssertTrue(true, ...)` always passes regardless of what `reschedule` does. This provides **zero behavioral coverage** for REQ-20's "skip when not authorized" requirement. It will pass even if `NotificationScheduler` throws a fatal error or schedules notifications without checking authorization.

**Fix option A (quick):** Rename to `testRescheduleIsCallSafe` and add a code comment that is honest about the limitation. Update REQ-20 coverage note to reflect this is a crash-safety smoke test, not an authorization-guard test.

**Fix option B (better):** Extract an internal overload that accepts a mocked `UNAuthorizationStatus`:
```swift
// internal — testable
static func reschedule(for result: ScheduleResult, authStatus: UNAuthorizationStatus) {
    guard authStatus == .authorized else { return }
    // ... block filtering and scheduling
}
// public entry point
static func reschedule(for result: ScheduleResult) {
    Task {
        let status = await UNUserNotificationCenter.current()
            .notificationSettings().authorizationStatus
        reschedule(for: result, authStatus: status)
    }
}
```
Then `testSkipsWhenNotAuthorized` can call the internal overload with `.denied` and verify no scheduling logic executes.

---

#### [MEDIUM] `ScheduledItem` test helper uses `activeIngredient:` parameter not shown in struct interface

**Plan affected:** 06-05, Tasks 1 and 2

The `makeItem` helpers in both `NotificationSchedulerTests` and `TodayViewModelTests` initialize `ScheduledItem` with `activeIngredient: ""`. But the `ScheduledItem` struct shown in Plans 06-01, 06-04, and 06-05 has no `activeIngredient` property. If the real struct lacks this property, all 6 tests fail to build — they will be RED at compile time, not just at run time.

**Fix:** In Plan 06-05 Task 1's `read_first` list, add `StackWise/Schedule/ScheduleResult.swift` and read it before writing test helpers. Use only properties that exist in the actual struct definition.

---

#### [MEDIUM] `scheduleStore.currentSchedule()` called 3+ times per render cycle

**Plan affected:** 06-04, TodayView

`TodayView.body` calls `scheduleStore.currentSchedule()` at the top, `completedCount` calls it again, and `totalBlockCount` calls it a third time. With the dirty-flag cache this is cheap when clean, but it creates 3 independent `ScheduleResult` copies per render and could trigger 3 recomputes if the dirty flag is set between calls.

**Fix:** Hoist to a single call at the top of `body` and pass it into helpers:
```swift
var body: some View {
    let schedule = scheduleStore.currentSchedule()
    // pass schedule into completedCount(for: schedule) and totalBlockCount(for: schedule)
}
```

---

#### [MEDIUM] Completed (non-past) toggle can still be tapped — confusing flicker

**Plan affected:** 06-04, BlockRow

The `disabled` condition is `isPast && !isComplete`. A block that is `isComplete == true` but not past has an **enabled** toggle. Tapping it triggers the one-way set closure (which ignores `newValue == false`), causing the toggle to animate to OFF then snap back to ON. This looks like a bug.

**Fix:** Change condition to `isComplete || (isPast && !isComplete)` to disable the toggle once a block is completed:
```swift
.disabled(isComplete || (isPast && !isComplete))
```

---

#### [MEDIUM] No automated test for notification tap routing

**Plan affected:** 06-05

REQ-20 requires "tapping opens Today tab." The only verification is the manual simulator golden path. The `pendingTab` cold-start pattern and `AppState.selectedTab` state change have no automated tests.

**Fix (optional, recommended):** Add `AppDelegateTests.swift` with 2 tests:
1. Call `userNotificationCenter(_:didReceive:)` before `appState` is set → verify `pendingTab == 1`
2. Assign `appState` → verify `appState.selectedTab == 1` and `pendingTab == nil`

---

#### [LOW] `displayName()` function availability needs pre-read verification

**Plan affected:** 06-04

`BlockRow` calls `displayName(item.label)` as a free function. The executor must read `StackWise/DesignSystem.swift` before using this function to confirm its exact signature and that it is accessible from `TodayView.swift`.

---

#### [LOW] Color token availability (`sagePrimary`, `positiveFG`, `positiveBG`, `textTertiary`) needs verification

**Plan affected:** 06-03, 06-04

These tokens are listed in the Plan 06-04 interface section but were not verified in the reviewed context. Plan 06-04's `read_first` correctly lists `StackWise/DesignSystem.swift` — the executor must honor this and verify each token exists before use.

---

#### [LOW] `.animation(_:value:)` with `let` property may require parent re-render to trigger

**Plan affected:** 06-04, BlockRow

```swift
.animation(.easeIn(duration: 0.3), value: isComplete)
```

`isComplete` is a `let` constant passed into `BlockRow`. The animation triggers when SwiftUI diffs the old vs new `BlockRow` with different `isComplete` values during a parent re-render. Since `@FetchRequest` on `TodayView` observes Core Data changes, this should work correctly — but the executor should verify the animation plays during manual testing in the human checkpoint.

---

### Suggestions

1. **[06-03]** Add `@Environment(ScheduleStore.self)` to `NotificationPermissionView` and call `NotificationScheduler.reschedule(for: scheduleStore.currentSchedule())` after `requestAuthorization` returns. This closes the HIGH notification scheduling gap.

2. **[06-05, Task 1]** Read `StackWise/Schedule/ScheduleResult.swift` before writing `makeItem()` helpers. Remove `activeIngredient:` if the property doesn't exist in the struct.

3. **[06-05, Task 1]** Rename `testSkipsWhenNotAuthorized` → `testRescheduleIsCallSafe` and add an honest comment about the authorization guard not being testable without protocol abstraction.

4. **[06-04]** Compute `scheduleStore.currentSchedule()` once in `body` and thread the result through to `completedCount`/`totalBlockCount` helpers.

5. **[06-04]** Fix `BlockRow` `disabled` condition: `isComplete || (isPast && !isComplete)`.

6. **[06-05]** Consider adding `AppDelegateTests.swift` with 2 lightweight `pendingTab` tests.

---

## Consensus Summary

Only one reviewer (Claude) was invoked. Gemini CLI was installed but requires API key authentication not currently configured.

### Agreed Strengths

- Wave decomposition and dependency ordering are correct
- AppDelegate `pendingTab` cold-start pattern is explicitly planned and architecturally sound
- `@AppStorage` gate prevents race-condition flash
- Midnight normalization enforced at both write and read sites
- Research quality is high; all major iOS pitfalls are pre-identified

### Agreed Concerns

- **[HIGH]** Notification scheduling gap: first-time users who grant permission won't get notifications until next stack modification
- **[HIGH]** `testSkipsWhenNotAuthorized` is a no-op assertion — provides false REQ-20 coverage confidence
- **[MEDIUM]** `ScheduledItem` test helper may have a `activeIngredient` property that doesn't exist in the real struct
- **[MEDIUM]** `scheduleStore.currentSchedule()` called redundantly in the same render cycle
- **[MEDIUM]** Completed toggle is still tappable (flicker UX)
- **[MEDIUM]** No automated test for `AppDelegate` notification routing (REQ-20 critical path)

### Divergent Views

N/A — single reviewer.

---

## Action Items Before Execution

| Priority | Plan | Change |
|----------|------|--------|
| REQUIRED | 06-03 | Inject `ScheduleStore` into `NotificationPermissionView`; call `reschedule` after auth |
| REQUIRED | 06-05 | Read actual `ScheduledItem` struct before writing `makeItem()` helpers |
| RECOMMENDED | 06-05 | Rename `testSkipsWhenNotAuthorized` + add honest comment |
| RECOMMENDED | 06-04 | Hoist `currentSchedule()` to single call in `body` |
| RECOMMENDED | 06-04 | Fix `disabled` condition on toggle |
| OPTIONAL | 06-05 | Add `AppDelegateTests.swift` for `pendingTab` routing |

---

*To incorporate this feedback into planning:*
```
/gsd:plan-phase 6 --reviews
```
