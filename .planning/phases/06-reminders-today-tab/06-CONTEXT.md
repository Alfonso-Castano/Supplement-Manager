# Phase 6: Reminders & Today Tab - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Schedule local notifications per the generated schedule and build the Today tab block-level check-off interface. Covers: notification permission UX (full-screen value-framing screen), NotificationScheduler service, TodayView UI with block rows and check-off toggles, DailyCheckOff persistence, and notification tap routing. Subscription paywalling, dark mode, and feedback forms are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Notification Permission UX
- **D-01:** Dedicated full-screen value-framing screen appears after onboarding completes, before the TabView loads — inserted as a gate in ContentView between `onboardingComplete = true` and the main TabView
- **D-02:** Screen design matches the main app aesthetic (not a generic system-style sheet); copy communicates specific supplement reminders at the right time, not generic alerts
- **D-03:** One new flag tracks whether permission has been requested (e.g. `@AppStorage("notificationPermissionShown") var notificationPermissionShown = false`); screen shows once, then never again
- **D-04:** After user taps the CTA on the value-framing screen, the system `UNUserNotificationCenter.requestAuthorization` alert fires immediately
- **D-05:** Phase 6 owns the full implementation of this screen — Phase 5 deferred it here (D-10 from 05-CONTEXT.md)

### Today Tab Data Source
- **D-06:** `TodayView` reads from `ScheduleStore.cachedResult` via `@Environment(ScheduleStore.self)` — same data source as the Schedule tab; calls `currentSchedule()` to get the `ScheduleResult`
- **D-07:** No separate Core Data fetch in TodayView for items — `ScheduledItem` labels/dosages come from the cached `ScheduleResult`

### Notification Scheduling
- **D-08:** A new `NotificationScheduler` service is introduced; called at the end of `ScheduleStore.recompute()` so notifications always reflect the current schedule
- **D-09:** `NotificationScheduler` cancels all pending notifications (`removeAllPendingNotificationRequests`) and re-schedules one per non-empty block using each block's `suggestedTime` on today's date
- **D-10:** Notification body lists all item labels for the block (e.g. "Time for your morning supplements: Vitamin D, Magnesium"); `categoryIdentifier` = block name (e.g. `"morning_reminder"`)
- **D-11:** If notification permission has not been granted, `NotificationScheduler` skips silently — no crash, no retry logic needed at this layer
- **D-12:** No background task (BGAppRefreshTask) — recompute-triggered scheduling is sufficient

### Check-off Display & Daily Reset
- **D-13:** Each block row shows its items (label + dosage) listed for context, then a single "Mark complete" toggle/button at the bottom of the block
- **D-14:** Tapping "Mark complete" writes a `DailyCheckOff` record with `timeBlock` = block name, `checkOffDate` normalized to midnight of today, `completed = true`, `completedAt = now`
- **D-15:** Daily reset is implicit — DailyCheckOff is keyed by date + timeBlock; next-day date has no records, so state is fresh automatically; no explicit cleanup/delete logic needed
- **D-16:** A block is "checked off today" if a `DailyCheckOff` record exists with matching `timeBlock` and `checkOffDate == today midnight`

### Missed Block Handling
- **D-17:** A time block is "past" if its `suggestedTime` is before `Date.now`
- **D-18:** Past blocks render with reduced opacity (items and toggle dimmed), toggle is disabled; block remains visible for full-day context — no hiding, no deletion
- **D-19:** Past blocks that were checked off render normally (green/completed state, not dimmed)

### Notification Tap Routing
- **D-20:** Tapping a notification switches the TabView to the Today tab (tab index 1); no deep-link to a specific block
- **D-21:** `UNUserNotificationCenterDelegate` (implemented in `StackWiseApp`) handles `userNotificationCenter(_:didReceive:)` and sets a shared `AppState` property (e.g. `appState.selectedTab = 1`) to trigger the tab switch

### Claude's Discretion
- Exact copy for the value-framing notification permission screen
- Visual design of block rows (spacing, font sizes, icon choices for the check toggle)
- Whether to show a completion summary at the top of Today tab ("2/3 blocks done today")
- Animation/transition when check-off state changes

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §REQ-20, REQ-21 — Notification and Today tab requirements (locked)

### Prior Phase Context
- `.planning/phases/05-functional-onboarding/05-CONTEXT.md` — D-10: notification permission deferred to Phase 6; D-12: trial mechanism placeholder; ContentView gate pattern

### Project Spec
- `SPEC.md` — Full project specification

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StackWise/Features/Today/TodayView.swift` — Placeholder (`Text("Today")`); Phase 6 implements the full view here
- `StackWise/Schedule/ScheduleStore.swift` — `currentSchedule() -> ScheduleResult` available via `@Environment`; `recompute()` is where `NotificationScheduler` call hooks in
- `StackWise/Schedule/ScheduleResult.swift` — `ScheduleResult.morning/afternoon/evening: [ScheduledItem]`; `ScheduledItem` has `label`, `dosage`, `suggestedTime`
- `StackWise/Models/DailyCheckOff+CoreDataClass.swift` — Schema: `id UUID`, `checkOffDate Date` (midnight), `timeBlock String`, `completed Bool`, `completedAt Date?`
- `StackWise/Models/AppState.swift` — Already has `onboardingComplete`; extend with `selectedTab: Int = 0` for notification routing
- `StackWise/ContentView.swift` — Already gates on `appState.onboardingComplete`; Phase 6 adds a second gate for `notificationPermissionShown`

### Established Patterns
- `@Observable` + `.environment()` only — no `ObservableObject`/`@Published`
- `@AppStorage` for simple boolean flags (used elsewhere in the project)
- Dirty-flag recompute pattern: `scheduleStore.invalidate()` called on stack mutations; Phase 6 adds `NotificationScheduler.reschedule(for:)` inside `recompute()`
- ContentView gate pattern from Phase 5: `if appState.onboardingComplete { ... } else { OnboardingCoordinatorView() }`

### Integration Points
- `StackWise/ContentView.swift` — Add `notificationPermissionShown` gate between `onboardingComplete = true` and TabView
- `StackWise/Schedule/ScheduleStore.swift` — Add `NotificationScheduler.reschedule(for: result)` call at end of `recompute()`, after `cachedResult = result`
- `StackWise/StackWiseApp.swift` — Implement `UNUserNotificationCenterDelegate` for tab-switch routing on notification tap
- `StackWise/Models/AppState.swift` — Add `selectedTab: Int` property for notification tap routing

</code_context>

<specifics>
## Specific Ideas

- Notification permission screen: high-acceptance-rate full-screen pattern used by successful health/fitness apps; intentional and premium feel — not incidental
- Notification copy example: "Time for your morning supplements: Vitamin D, Magnesium"
- Today tab value-add: user sees their daily schedule context (items per block) even without tapping into the Schedule tab

</specifics>

<deferred>
## Deferred Ideas

- Rich lock-screen notifications with inline check-off action — listed in REQUIREMENTS.md v2 deferred section
- Streak tracking / adherence history — v2 deferred
- Block completion summary banner at top of Today tab — Claude's discretion; not a locked requirement

</deferred>

---

*Phase: 06-reminders-today-tab*
*Context gathered: 2026-05-26*
