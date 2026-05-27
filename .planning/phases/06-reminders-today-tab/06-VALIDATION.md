---
phase: 6
slug: reminders-today-tab
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-26
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | StackWise.xcodeproj (no separate config) |
| **Quick run command** | `xcodebuild test-without-building -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test-without-building -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test-without-building -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'`
- **After every plan wave:** Run full suite (same command)
- **Before `/gsd-verify-work`:** Full suite must be green (≥56 tests passing — 50 existing + 6 new)
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Behavior | Test Type | File | Status |
|---------|------|------|-------------|----------|-----------|------|--------|
| 06-01-T3 | 06-01 | 1 | REQ-20 | NotificationScheduler skips when not authorized | unit | `StackWiseTests/NotificationSchedulerTests.swift` | ❌ W0 |
| 06-01-T3 | 06-01 | 1 | REQ-20 | NotificationScheduler schedules 1 request per non-empty block | unit | `StackWiseTests/NotificationSchedulerTests.swift` | ❌ W0 |
| 06-01-T3 | 06-01 | 1 | REQ-20 | Notification body lists item labels | unit | `StackWiseTests/NotificationSchedulerTests.swift` | ❌ W0 |
| 06-01-T3 | 06-01 | 1 | REQ-21 | DailyCheckOff write persists with midnight date + timeBlock | unit | `StackWiseTests/DailyCheckOffTests.swift` | ❌ W0 |
| 06-01-T3 | 06-01 | 1 | REQ-21 | DailyCheckOff fetch predicate returns correct record for today | unit | `StackWiseTests/DailyCheckOffTests.swift` | ❌ W0 |
| 06-05-T1 | 06-05 | 4 | REQ-21 | Block "past" determination: suggestedTime < Date.now | unit | `StackWiseTests/TodayViewModelTests.swift` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `StackWiseTests/NotificationSchedulerTests.swift` — stubs for REQ-20 (3 tests: testSkipsWhenNotAuthorized, testSchedulesOneRequestPerNonEmptyBlock, testNotificationBodyListsItemLabels)
- [ ] `StackWiseTests/DailyCheckOffTests.swift` — stubs for REQ-21 (2 tests: testWritePersistsToMidnightDate, testFetchPredicateMatchesToday)
- [ ] `StackWiseTests/TodayViewModelTests.swift` — stubs for REQ-21 past-block logic (1 test: testPastBlockDetermination)

**Note on NotificationScheduler testability:** Tests assert on the pure logic of building UNNotificationRequest content (title, body, identifier, trigger hour/minute) without calling the live UNUserNotificationCenter. This matches the project's existing test philosophy (behavior over mock interactions).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| System permission dialog fires on CTA tap | REQ-20 | Cannot automate system modal | Run on simulator: tap "Enable Reminders", confirm system dialog appears |
| Notification delivered at block suggestedTime | REQ-20 | Requires time-travel or real wait | Test with simulator date override or short-interval trigger |
| Notification tap switches to Today tab from background | REQ-20 | Requires backgrounded app state | Background app, tap notification from notification center |
| Notification tap switches to Today tab from cold start | REQ-20 | Requires killed app state + pendingTab pattern | Kill app, tap notification, confirm Today tab selected |
| Past block dimming visible at correct time | REQ-21 | Requires real-time or simulator date override | Set simulator time to afternoon, confirm morning block dimmed |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
