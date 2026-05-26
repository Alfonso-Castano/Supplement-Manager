# Phase 6: Reminders & Today Tab - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the discussion.

**Date:** 2026-05-26
**Phase:** 06-reminders-today-tab
**Mode:** discuss (standard)
**Areas discussed:** Notification permission UX, Today tab data source, Notification reschedule trigger, Check-off display & daily reset, Missed block handling, Notification tap routing

---

## Area: Notification Permission UX

| Question | Options presented | User selection |
|---|---|---|
| Where does the notification permission prompt appear? | Sheet on first Today tab visit / Dedicated screen pushed on first launch | **Dedicated screen pushed on first launch** |

**Notes:** User emphasized the full-screen approach is intentional and premium — matches high-acceptance-rate patterns from successful health/fitness apps. Screen should match main app aesthetic, not look like a system sheet. Phase 6 owns full implementation (Phase 5 D-10 deferred this).

---

## Area: Today Tab Data Source

| Question | Options presented | User selection |
|---|---|---|
| TodayView data source | ScheduleStore.cachedResult / ScheduledDose Core Data fetch | **ScheduleStore.cachedResult** |

**Notes:** Simpler, consistent with Schedule tab. No extra fetch needed.

---

## Area: Notification Reschedule Trigger

| Question | Options presented | User selection |
|---|---|---|
| When to reschedule notifications | On every ScheduleStore recompute / Once at onboarding / Daily background task | **On every ScheduleStore recompute** |

**Notes:** NotificationScheduler service hooked into end of ScheduleStore.recompute(). Notifications always reflect current schedule.

---

## Area: Check-off Display & Daily Reset

| Question | Options presented | User selection |
|---|---|---|
| Check-off display + reset timing | Items listed + block toggle, reset at midnight / Items listed + block toggle, reset on first new-day launch | **Items listed + single block toggle; reset at midnight** |

**Notes:** DailyCheckOff keyed by date + timeBlock. No explicit cleanup needed — next-day date has no records.

---

## Area: Missed Block Handling

| Question | Options presented | User selection |
|---|---|---|
| Past time blocks | Gray out + dimmed items, toggle disabled / Keep fully active all day / Hide past blocks | **Gray out the block + dimmed items, no action** |

**Notes:** Block stays visible for context (user can see what their day looked like), but toggle is disabled and UI is dimmed to signal time has passed.

---

## Area: Notification Tap Routing

| Question | Options presented | User selection |
|---|---|---|
| Notification tap behavior | Open Today tab only / Deep-link to specific block | **Open Today tab, no deep-link** |

**Notes:** UNUserNotificationCenterDelegate sets appState.selectedTab = 1. Simple tab switch — no ScrollViewReader or NavigationPath needed.

---

## Claude's Discretion Items

- Exact copy for notification permission value-framing screen
- Visual design of block rows and check toggle
- Optional completion summary ("2/3 blocks done today") at top of Today tab
- Animation when check-off state changes

## Deferred Ideas

- Rich lock-screen notifications with inline check-off — v2 (already in REQUIREMENTS.md deferred)
- Streak tracking — v2
