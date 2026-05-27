# Phase 6: Reminders & Today Tab - Research

**Researched:** 2026-05-26
**Domain:** iOS UserNotifications framework, SwiftUI TabView programmatic navigation, Core Data date-keyed persistence
**Confidence:** HIGH (all core APIs verified via official Apple documentation and Apple Developer Forums)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Notification Permission UX**
- D-01: Dedicated full-screen value-framing screen appears after onboarding completes, before the TabView loads — inserted as a gate in ContentView between `onboardingComplete = true` and the main TabView
- D-02: Screen design matches the main app aesthetic; copy communicates specific supplement reminders at the right time, not generic alerts
- D-03: `@AppStorage("notificationPermissionShown")` tracks whether permission screen has been shown; screen shows once, then never again
- D-04: After user taps the CTA on the value-framing screen, the system `UNUserNotificationCenter.requestAuthorization` alert fires immediately
- D-05: Phase 6 owns the full implementation of this screen

**Today Tab Data Source**
- D-06: `TodayView` reads from `ScheduleStore.cachedResult` via `@Environment(ScheduleStore.self)` — same data source as Schedule tab; calls `currentSchedule()` to get the `ScheduleResult`
- D-07: No separate Core Data fetch in TodayView for items — `ScheduledItem` labels/dosages come from the cached `ScheduleResult`

**Notification Scheduling**
- D-08: New `NotificationScheduler` service; called at end of `ScheduleStore.recompute()`
- D-09: Cancels all pending notifications (`removeAllPendingNotificationRequests`) and re-schedules one per non-empty block using each block's `suggestedTime` on today's date
- D-10: Notification body lists all item labels for the block; `categoryIdentifier` = block name (e.g. `"morning_reminder"`)
- D-11: If notification permission not granted, `NotificationScheduler` skips silently — no crash, no retry
- D-12: No background task (BGAppRefreshTask) — recompute-triggered scheduling is sufficient

**Check-off Display & Daily Reset**
- D-13: Each block row shows items (label + dosage) listed for context, then a single "Mark complete" toggle/button at the bottom of the block
- D-14: Tapping "Mark complete" writes a `DailyCheckOff` record with `timeBlock` = block name, `checkOffDate` normalized to midnight of today, `completed = true`, `completedAt = now`
- D-15: Daily reset is implicit — keyed by date + timeBlock; next-day date has no records
- D-16: A block is "checked off today" if a `DailyCheckOff` record exists with matching `timeBlock` and `checkOffDate == today midnight`

**Missed Block Handling**
- D-17: A time block is "past" if its `suggestedTime` is before `Date.now`
- D-18: Past blocks render with reduced opacity (items and toggle dimmed), toggle is disabled; block remains visible for full-day context
- D-19: Past blocks that were checked off render normally (green/completed state, not dimmed)

**Notification Tap Routing**
- D-20: Tapping a notification switches the TabView to the Today tab (tab index 1); no deep-link to a specific block
- D-21: `UNUserNotificationCenterDelegate` (implemented in `StackWiseApp`) handles `userNotificationCenter(_:didReceive:)` and sets `appState.selectedTab = 1`

### Claude's Discretion
- Exact copy for the value-framing notification permission screen
- Visual design of block rows (spacing, font sizes, icon choices for the check toggle)
- Whether to show a completion summary at the top of Today tab ("2/3 blocks done today")
- Animation/transition when check-off state changes

### Deferred Ideas (OUT OF SCOPE)
- Rich lock-screen notifications with inline check-off action
- Streak tracking / adherence history
- Block completion summary banner at top of Today tab (Claude's discretion — not a locked requirement)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-20 | Local notifications scheduled for each time block; notification body lists specific item labels (not generic); tapping opens Today tab | NotificationScheduler pattern, UNCalendarNotificationTrigger with hour/minute from suggestedTime, UNUserNotificationCenterDelegate + AppState.selectedTab routing — all verified |
| REQ-21 | Today tab shows morning / afternoon / evening rows with per-block check-off; completion persists to Core Data DailyCheckOff | TodayView reading ScheduleStore.cachedResult, DailyCheckOff write pattern with midnight normalization, NSPredicate for today's check-off lookup — all verified |
</phase_requirements>

---

## Summary

Phase 6 has three distinct technical domains: (1) iOS `UserNotifications` framework for scheduling and routing notification taps, (2) SwiftUI TabView programmatic control from outside the view hierarchy via shared `@Observable` state, and (3) Core Data date-keyed DailyCheckOff persistence with midnight normalization.

All three domains are well-understood iOS APIs with clear implementation patterns. The main complexity is structural rather than algorithmic: the `UNUserNotificationCenterDelegate` must be set in an `AppDelegate` class wired via `@UIApplicationDelegateAdaptor` — the `StackWiseApp` struct cannot directly conform to `UNUserNotificationCenterDelegate`. This is the single biggest architectural decision the planner must handle correctly. The CONTEXT.md decision D-21 says "implemented in StackWiseApp" but the actual iOS constraint is that the delegate must be on a separate `NSObject` subclass; the implementation will live in a new `AppDelegate` class introduced by Phase 6, wired to `StackWiseApp` via `@UIApplicationDelegateAdaptor`.

The rest of the phase is straightforward: `NotificationScheduler` is a pure service with no state, TodayView reads from the already-injected `ScheduleStore`, and `DailyCheckOff` writes follow the same Core Data pattern established in Phases 1-5. No new frameworks are required. No new Core Data migrations are needed — the `DailyCheckOff` entity already exists in the schema with all required attributes.

**Primary recommendation:** Introduce a dedicated `AppDelegate` class for `UNUserNotificationCenterDelegate`; implement `NotificationScheduler` as a simple enum with a static `reschedule(for:)` function (same pattern as `UserProfileStore`); use `@Bindable` with `appState.selectedTab` binding for TabView programmatic switching.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Notification permission request | iOS system (UserNotifications framework) | SwiftUI UI gate (ContentView) | System dialog fires on behalf of the app; app only gates display once via @AppStorage |
| Notification scheduling | iOS system (UNUserNotificationCenter) | NotificationScheduler service (local) | System manages delivery; NotificationScheduler translates ScheduleResult → UNNotificationRequest objects |
| Notification tap routing | AppDelegate (UNUserNotificationCenterDelegate) | AppState (shared observable) | iOS requires an NSObject subclass as the delegate; AppState bridges to SwiftUI |
| Today tab data display | TodayView (SwiftUI) | ScheduleStore (in-memory cache) | ScheduledItems come from ScheduleStore; DailyCheckOff status fetched from Core Data |
| Check-off persistence | Core Data (DailyCheckOff entity) | TodayView (writes on tap) | Persistence is Core Data's job; the view triggers the write directly |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications (Apple) | iOS 17 built-in | Schedule local notifications, handle delegate callbacks | Only official iOS mechanism for local notifications |
| SwiftUI | iOS 17 built-in | TodayView, NotificationPermissionView UI | Project standard (locked Phase 1) |
| CoreData | iOS 17 built-in | DailyCheckOff persistence | Project standard (locked Phase 1) |
| Foundation | iOS 17 built-in | Calendar, DateComponents, date normalization | Built-in; no alternatives |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UIKit (UIApplicationDelegateAdaptor) | iOS 17 built-in | Bridge AppDelegate into SwiftUI @main App | Required for UNUserNotificationCenterDelegate |

**No third-party libraries required for Phase 6.** [VERIFIED: codebase inspection]

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AppDelegate + @UIApplicationDelegateAdaptor | App struct as delegate | App struct cannot conform to UNUserNotificationCenterDelegate — NSObject inheritance required. AppDelegate approach is the only valid pattern. |
| UNCalendarNotificationTrigger (repeats: true) | UNTimeIntervalNotificationTrigger | Calendar trigger fires at the same time daily without code involvement; interval trigger fires once from "now + N seconds" requiring manual rescheduling. Calendar trigger is correct for daily supplement reminders. |
| Midnight normalization via Calendar.startOfDay | Storing raw Date | startOfDay is deterministic and timezone-safe; raw Date comparison across midnight boundaries causes missed records |

**Installation:** No new packages. All frameworks are built-in.

---

## Architecture Patterns

### System Architecture Diagram

```
User completes onboarding
          |
          v
ContentView gate: onboardingComplete == true
          |
          v
@AppStorage("notificationPermissionShown") == false?
     yes  |  no
          v     \
NotificationPermissionView  \
 (full-screen gate)          \
  user taps CTA              |
          |                  |
          v                  |
UNUserNotificationCenter     |
  .requestAuthorization()    |
          |                  |
          v                  |
  @AppStorage set true       |
          |                  /
          v                 /
     TabView (3 tabs) <----
      [0: Stack] [1: Today] [2: Schedule]
          |
          |
          +-- ScheduleStore.recompute()
          |         |
          |         v
          |   NotificationScheduler.reschedule(for: ScheduleResult)
          |         |
          |         v
          |   UNUserNotificationCenter
          |     .removeAllPendingNotificationRequests()
          |     .add(UNNotificationRequest) x N non-empty blocks
          |         |
          |         v  (fires at suggestedTime each day)
          |   System delivers notification
          |         |
          |         v (user taps)
          |   AppDelegate.userNotificationCenter(_:didReceive:)
          |         |
          |         v
          |   appState.selectedTab = 1
          |         |
          |         v
          |   TabView switches to Today tab
          |
          +-- TodayView reads ScheduleStore.currentSchedule()
                    |
                    v
            BlockRow x 3 (morning/afternoon/evening)
              items from ScheduleResult
              check-off state from DailyCheckOff (Core Data)
                    |
                    v (user taps "Mark complete")
            DailyCheckOff.create(timeBlock:, date: midnight)
            context.save()
            UI updates immediately (@FetchRequest observes changes)
```

### Recommended Project Structure

```
StackWise/
├── AppDelegate.swift                          # NEW — UNUserNotificationCenterDelegate
├── StackWiseApp.swift                         # MODIFY — add @UIApplicationDelegateAdaptor
├── Models/
│   └── AppState.swift                         # MODIFY — add selectedTab: Int = 0
├── ContentView.swift                          # MODIFY — add notificationPermissionShown gate
├── Notifications/
│   └── NotificationScheduler.swift            # NEW — pure service, no state
├── Features/
│   └── Today/
│       ├── TodayView.swift                    # IMPLEMENT (currently placeholder)
│       └── NotificationPermissionView.swift   # NEW — value-framing full-screen gate
```

### Pattern 1: UNUserNotificationCenterDelegate via AppDelegate

**What:** An `AppDelegate` class (conforming to both `UIApplicationDelegate` and `UNUserNotificationCenterDelegate`) is the only valid way to set up notification tap handling in an iOS app. The `App` struct cannot be the delegate.

**When to use:** Required for all SwiftUI apps that handle notification taps.

```swift
// Source: Apple Developer Forums thread/762217, createwithswift.com (VERIFIED)

// AppDelegate.swift
import UIKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {

    var appState: AppState?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when user taps notification (app backgrounded or killed)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            appState?.selectedTab = 1
        }
    }

    // Called when notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
}

// StackWiseApp.swift — add to existing init():
// @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
// In body, after environment injection, assign: appDelegate.appState = appState
```

**Critical implementation note:** `@preconcurrency` on the `UNUserNotificationCenterDelegate` conformance is required to suppress Swift concurrency warnings for these delegate methods, which have not been updated for strict concurrency. This is the standard workaround as of 2025. [VERIFIED: Apple Developer Forums thread/762217]

### Pattern 2: TabView Programmatic Selection via @Observable

**What:** `TabView(selection:)` takes a binding to an `Int` (or `Hashable` value). When the bound value changes from outside the view (e.g., from AppDelegate), the tab switches immediately.

**When to use:** Whenever a non-view action needs to drive tab navigation (notification tap, deep link, etc.)

```swift
// Source: hackingwithswift.com, sarunw.com/posts/swiftui-tabview (VERIFIED pattern)

// AppState.swift
@Observable
final class AppState {
    var onboardingComplete: Bool = false
    var subscriptionStatus: String = "unknown"
    var selectedTab: Int = 0   // ADD THIS
}

// ContentView.swift
struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Group {
            if appState.onboardingComplete {
                if !appState.notificationPermissionShown {
                    NotificationPermissionView()
                } else {
                    TabView(selection: $appState.selectedTab) {
                        StackListView()
                            .tabItem { Label("Stack", systemImage: "pills") }
                            .tag(0)
                        TodayView()
                            .tabItem { Label("Today", systemImage: "checkmark.circle") }
                            .tag(1)
                        ScheduleView()
                            .tabItem { Label("Schedule", systemImage: "calendar") }
                            .tag(2)
                    }
                    .tint(.aquaPrimary)
                }
            } else {
                OnboardingCoordinatorView()
            }
        }
        .task { ... }
    }
}
```

**Note on gate ordering:** D-01 specifies the NotificationPermissionView as a gate BEFORE the TabView. This means `notificationPermissionShown` is checked inside the `onboardingComplete == true` branch. The `@AppStorage` flag value is available immediately (it reads from UserDefaults, not async Core Data), so no additional bootstrap complexity is needed.

### Pattern 3: Notification Scheduling — NotificationScheduler Service

**What:** A pure enum (no state, no instances) that translates `ScheduleResult` → `UNNotificationRequest` objects, cancels old requests, and schedules new ones. Called at the end of `ScheduleStore.recompute()`.

**When to use:** Every time the schedule is recomputed.

```swift
// Source: donnywals.com scheduling article, createwithswift.com notifications tutorial (VERIFIED pattern)

import UserNotifications

enum NotificationScheduler {

    static func reschedule(for result: ScheduleResult) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }

            center.removeAllPendingNotificationRequests()

            let blocks: [(name: String, items: [ScheduledItem], identifier: String)] = [
                ("morning", result.morning, "morning_reminder"),
                ("afternoon", result.afternoon, "afternoon_reminder"),
                ("evening", result.evening, "evening_reminder"),
            ]

            for block in blocks where !block.items.isEmpty {
                let content = UNMutableNotificationContent()
                content.title = "Time for your \(block.name) supplements"
                content.body = block.items.map(\.label).joined(separator: ", ")
                content.sound = .default
                content.categoryIdentifier = block.identifier

                // Extract hour/minute from the first item's suggestedTime
                let cal = Calendar.current
                var components = cal.dateComponents([.hour, .minute], from: block.items[0].suggestedTime)
                // repeats: true — fires daily at the same time
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

                let request = UNNotificationRequest(
                    identifier: block.identifier,
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }
}
```

**Key details:**
- Use the first item's `suggestedTime` for the trigger time (all items in a block share the same block time window)
- Use the stable block identifier string (e.g., `"morning_reminder"`) as the `UNNotificationRequest.identifier` — this ensures `removeAllPendingNotificationRequests()` followed by re-add works correctly without duplicate accumulation
- `repeats: true` fires daily at the same time; rescheduling on recompute resets the trigger with updated times if the user changes their schedule inputs

### Pattern 4: DailyCheckOff Core Data Write and Lookup

**What:** On "Mark complete" tap, look up or create a `DailyCheckOff` for `(today midnight, timeBlock)`, set `completed = true`, save context.

**When to use:** Every block check-off toggle.

```swift
// Source: Core Data fetch predicate pattern from medium.com/@jakir (VERIFIED pattern)

// Date normalization — midnight of today
let today = Calendar.current.startOfDay(for: Date())

// Fetch predicate for "is this block checked off today?"
let predicate = NSPredicate(
    format: "checkOffDate == %@ AND timeBlock == %@",
    today as NSDate,
    "morning"  // or "afternoon" / "evening"
)

// Write pattern — upsert (fetch or create)
func markComplete(timeBlock: String, in context: NSManagedObjectContext) {
    let today = Calendar.current.startOfDay(for: Date())
    let request = DailyCheckOff.fetchRequest()
    request.predicate = NSPredicate(
        format: "checkOffDate == %@ AND timeBlock == %@",
        today as NSDate,
        timeBlock
    )
    request.fetchLimit = 1

    let existing = try? context.fetch(request).first
    let record = existing ?? DailyCheckOff(context: context)
    record.id = record.id ?? UUID()
    record.checkOffDate = today
    record.timeBlock = timeBlock
    record.completed = true
    record.completedAt = Date()

    try? context.save()
}
```

**SPEC.md note:** DailyCheckOff records are created lazily — no pre-generation. The upsert pattern above handles both first-time creation and subsequent updates correctly.

### Pattern 5: ContentView Multi-Gate Pattern

**What:** The existing ContentView gate pattern (from Phase 5) is extended with a second gate for `notificationPermissionShown`.

**Important:** `notificationPermissionShown` should be an `@AppStorage` property on `ContentView` itself (or on `AppState` if it needs to be read elsewhere), NOT stored in Core Data. `@AppStorage` reads from UserDefaults synchronously — no async load needed.

```swift
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("notificationPermissionShown") private var notificationPermissionShown = false

    var body: some View {
        @Bindable var appState = appState

        Group {
            if appState.onboardingComplete {
                if !notificationPermissionShown {
                    NotificationPermissionView(onComplete: {
                        notificationPermissionShown = true
                    })
                } else {
                    TabView(selection: $appState.selectedTab) { ... }
                }
            } else {
                OnboardingCoordinatorView()
            }
        }
        .task { ... }  // existing task stays
    }
}
```

**Gate ordering:** onboardingComplete → notificationPermissionShown → TabView. Each gate is an `if/else` branch, not nested `.fullScreenCover`.

### Pattern 6: Notification Permission Request

**What:** The async/await form of `requestAuthorization` is available since iOS 15. At iOS 17 min target, use it directly.

```swift
// Source: createwithswift.com/notifications-tutorial-requesting-user-authorization (VERIFIED)

struct NotificationPermissionView: View {
    var onComplete: () -> Void

    var body: some View {
        // ... value-framing UI ...
        Button("Enable Reminders") {
            Task {
                let center = UNUserNotificationCenter.current()
                let granted = try? await center.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                // Whether granted or denied, we mark shown and proceed
                onComplete()
            }
        }
    }
}
```

**Behavior when already denied:** `requestAuthorization` returns `false` but does NOT crash or show a dialog. The `@AppStorage` flag marks the screen as shown regardless of outcome — the user cannot be prompted again by the app (must go to Settings). This is correct per D-04.

### Anti-Patterns to Avoid

- **App struct as UNUserNotificationCenterDelegate:** `StackWiseApp` cannot directly conform to `UNUserNotificationCenterDelegate` — it does not inherit from `NSObject`. Always use `AppDelegate` + `@UIApplicationDelegateAdaptor`.
- **Storing raw `Date()` as checkOffDate:** Using raw `Date.now` instead of `Calendar.current.startOfDay(for: Date())` means records keyed to millisecond-precision timestamps; predicates for "today" will never match. Always normalize to midnight.
- **Using notification identifier = UUID():** Random UUIDs accumulate infinitely. Use a stable identifier (e.g., `"morning_reminder"`) so `removeAllPendingNotificationRequests()` + re-add on recompute is idempotent.
- **Scheduling notifications before checking authorization status:** Always call `center.notificationSettings()` and check `.authorizationStatus` before scheduling. If not `.authorized`, skip silently (D-11).
- **Over-scheduling:** iOS hard-caps pending notifications at 64. With 3 blocks and `repeats: true`, we use 3 slots — well within the limit. [VERIFIED: Apple Developer Forums thread/811171]
- **Deep-linking to a specific block from notification tap:** D-20 explicitly specifies tab switch only, no block deep-link. Do not add `userInfo` block keys or scroll-to logic in Phase 6.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date normalization to midnight | Custom date arithmetic | `Calendar.current.startOfDay(for: Date())` | Built-in, DST-safe, timezone-correct |
| Notification delivery at a specific time | Timer-based workarounds | `UNCalendarNotificationTrigger(dateMatching:repeats:)` | System-managed delivery, works in background/terminated state |
| Checking notification auth status | Storing granted Bool locally | `await center.notificationSettings().authorizationStatus` | System is authoritative; user can change in Settings at any time |

**Key insight:** The UserNotifications framework handles all delivery mechanics. The app's job is only to register requests correctly; everything else (delivery timing, lock screen display, notification center grouping) is the system's responsibility.

---

## Common Pitfalls

### Pitfall 1: AppDelegate Reference Not Bridged to AppState

**What goes wrong:** `AppDelegate.userNotificationCenter(_:didReceive:)` fires but cannot update `appState.selectedTab` because `AppDelegate` has no reference to the `AppState` instance.

**Why it happens:** `StackWiseApp` creates the `AppState` instance in its `init()`, but `AppDelegate` is a separate class instantiated by UIKit before `StackWiseApp.init()` runs.

**How to avoid:** Assign the reference in `StackWiseApp.body` using `.onAppear` or by passing it in the `StackWiseApp.init()` after creating both objects. Concretely:

```swift
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

var body: some Scene {
    WindowGroup {
        ContentView()
            .environment(appState)
            // ...
            .task { appDelegate.appState = appState }
    }
}
```

**Warning signs:** Notification tap does nothing; Today tab never switches even when a notification is tapped.

### Pitfall 2: Notification Permission Screen Shows After Tab Switch

**What goes wrong:** If `notificationPermissionShown` is read after an async Core Data load (instead of from `@AppStorage`), there may be a frame where onboardingComplete is true but notificationPermissionShown hasn't been read yet, causing the TabView to flash briefly.

**Why it happens:** Mixing async Core Data state with synchronous UserDefaults state.

**How to avoid:** Use `@AppStorage` (synchronous UserDefaults) for `notificationPermissionShown` — it is available on the first render frame, no async loading required.

**Warning signs:** Brief flash of TabView before permission screen appears.

### Pitfall 3: DailyCheckOff Not Found Due to Date Mismatch

**What goes wrong:** A DailyCheckOff record is written at 2:00 PM on Monday. The fetch predicate for "is Monday's morning block done?" returns empty even though the record exists.

**Why it happens:** `checkOffDate` was stored as `Date.now` (2:00 PM) rather than `Calendar.current.startOfDay(for: Date.now)` (midnight). The predicate `checkOffDate == midnight` fails.

**How to avoid:** Normalize to `Calendar.current.startOfDay(for: Date())` on every write AND every predicate. Never store raw `Date.now` in `checkOffDate`.

**Warning signs:** Check-off toggles reset on every app relaunch even though records exist in Core Data.

### Pitfall 4: ScheduleStore.recompute() Calls NotificationScheduler on Main Actor

**What goes wrong:** `NotificationScheduler.reschedule(for:)` calls `UNUserNotificationCenter.add()` which is async. If called directly (synchronously) inside `ScheduleStore.recompute()`, it blocks or causes concurrency issues.

**Why it happens:** `ScheduleStore` is `@MainActor`. Awaiting async calls directly inside `recompute()` would require it to be `async`, breaking the existing call sites (`currentSchedule()` is called synchronously from views).

**How to avoid:** Wrap the `NotificationScheduler.reschedule(for:)` call in a detached `Task` inside `recompute()`:

```swift
// Inside ScheduleStore.recompute(), after cachedResult = result:
Task.detached(priority: .utility) {
    await NotificationScheduler.reschedule(for: result)
}
```

Or, since `NotificationScheduler.reschedule` already wraps its body in `Task { }` (see Pattern 3 above), simply call it synchronously — the `Task { }` inside it will execute asynchronously without blocking `recompute()`.

**Warning signs:** Build error "expression is 'async' but is not marked with 'await'".

### Pitfall 5: Swift Concurrency Warnings on UNUserNotificationCenterDelegate

**What goes wrong:** The compiler emits errors about `UNUserNotificationCenterDelegate` methods not being isolated to the main actor, or about `Sendable` conformance violations.

**Why it happens:** Apple has not fully audited `UNUserNotificationCenterDelegate` for Swift strict concurrency as of 2025.

**How to avoid:** Add `@preconcurrency` to the conformance declaration:

```swift
final class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate
```

**Warning signs:** Build errors mentioning "conformance to @preconcurrency protocol" or "Sendable".

### Pitfall 6: Cold-Start Notification Tap Not Handled

**What goes wrong:** User taps a notification while the app is fully killed. The app launches but never navigates to Today tab.

**Why it happens:** `userNotificationCenter(_:didReceive:)` is called, but `appDelegate.appState` is still `nil` if the assignment in `.task {}` hasn't run yet.

**How to avoid:** Store the `selectedTab` intent in a local variable in `AppDelegate` and apply it lazily once `appState` is set:

```swift
final class AppDelegate: NSObject, ... {
    var appState: AppState? {
        didSet {
            if let pending = pendingTab {
                appState?.selectedTab = pending
                pendingTab = nil
            }
        }
    }
    private var pendingTab: Int?

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            if appState != nil {
                appState?.selectedTab = 1
            } else {
                pendingTab = 1
            }
        }
    }
}
```

**Warning signs:** Notification tap works when app is backgrounded but not when app is killed.

---

## Code Examples

### Full NotificationScheduler Service

```swift
// Source: donnywals.com scheduling article + createwithswift.com (VERIFIED pattern)
import UserNotifications
import Foundation

enum NotificationScheduler {

    static func reschedule(for result: ScheduleResult) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }

            center.removeAllPendingNotificationRequests()

            let cal = Calendar.current
            let blocks: [(name: String, items: [ScheduledItem], identifier: String)] = [
                ("morning",   result.morning,   "morning_reminder"),
                ("afternoon", result.afternoon, "afternoon_reminder"),
                ("evening",   result.evening,   "evening_reminder"),
            ]

            for block in blocks {
                guard !block.items.isEmpty,
                      let firstItem = block.items.first else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Time for your \(block.name) supplements"
                content.body = block.items.map(\.label).joined(separator: ", ")
                content.sound = .default
                content.categoryIdentifier = block.identifier

                let components = cal.dateComponents([.hour, .minute], from: firstItem.suggestedTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

                let request = UNNotificationRequest(
                    identifier: block.identifier,
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }
}
```

### DailyCheckOff Upsert

```swift
// Source: Core Data upsert pattern (ASSUMED based on existing project Core Data patterns)
static func markComplete(timeBlock: String, in context: NSManagedObjectContext) {
    let today = Calendar.current.startOfDay(for: Date())
    let request = DailyCheckOff.fetchRequest()
    request.predicate = NSPredicate(
        format: "checkOffDate == %@ AND timeBlock == %@",
        today as NSDate, timeBlock
    )
    request.fetchLimit = 1

    let existing = (try? context.fetch(request))?.first
    let record = existing ?? DailyCheckOff(context: context)
    record.id = record.id ?? UUID()
    record.checkOffDate = today
    record.timeBlock = timeBlock
    record.completed = true
    record.completedAt = Date()

    try? context.save()
}
```

### TodayView Block "Is Checked Off" Fetch

```swift
// Source: Core Data @FetchRequest pattern (VERIFIED via existing project @FetchRequest usage)
@FetchRequest private var checkOffs: FetchedResults<DailyCheckOff>

// Initialize in init():
let today = Calendar.current.startOfDay(for: Date())
_checkOffs = FetchRequest(
    sortDescriptors: [],
    predicate: NSPredicate(format: "checkOffDate == %@", today as NSDate)
)

// Check if a block is complete:
func isComplete(block: String) -> Bool {
    checkOffs.contains { $0.timeBlockValue == block && $0.completed }
}
```

### ScheduleStore Integration Point

```swift
// Inside ScheduleStore.recompute(), AFTER cachedResult = result AND dirty = false:
// Source: CONTEXT.md D-08 + async-Task wrapper pattern

// Existing at end of recompute():
cachedResult = result
dirty = false

// ADD:
NotificationScheduler.reschedule(for: result)
// (NotificationScheduler.reschedule wraps itself in Task { } internally)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UNCalendarNotificationTrigger` with completion handler | async/await `center.add(request)` | iOS 15 / Swift 5.5 | Cleaner error handling; can use `try await` |
| AppDelegate-only apps | `@UIApplicationDelegateAdaptor` for SwiftUI apps needing UIKit delegate | SwiftUI from iOS 14 | SwiftUI App can still get UIKit delegate lifecycle without reverting to full AppDelegate |
| `UNNotificationPresentationOptions.alert` | `UNNotificationPresentationOptions.banner` | iOS 14 | `.alert` is deprecated; use `.banner` for foreground notification display |

**Deprecated / avoid:**
- `.alert` in `UNNotificationPresentationOptions`: use `.banner` instead (deprecated as of iOS 14, but not yet removed as of iOS 17; still compiles but generates deprecation warning)
- `completionHandler:` form of `UNUserNotificationCenter.add(_:withCompletionHandler:)`: prefer `try await center.add(request)` at iOS 15+ target

---

## Project Constraints (from CLAUDE.md)

- `@Observable` + `.environment()` only — no `ObservableObject`/`@Published`. AppState must remain `@Observable`, not converted to `ObservableObject` for the tab binding.
- `UserProfileStore.fetchOrCreate` is the only valid `UserProfile` writer — `DailyCheckOff` writes do NOT go through `UserProfileStore` (different entity); the pattern is direct `DailyCheckOff(context:)` creation, consistent with other entities.
- Simplicity first — no retry logic in `NotificationScheduler` (D-11 is explicit on this).
- No background refresh task (D-12 is explicit).
- Swift 5.0 project setting (confirmed from `.pbxproj`); iOS 17.0 minimum deployment target.
- `@MainActor` on `ScheduleStore` must be respected — `NotificationScheduler` call from `recompute()` must not block the main thread.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `DailyCheckOff` upsert pattern (fetch-or-create) is correct for toggling completion | Code Examples | Low — pattern is consistent with all other Core Data writes in this project |
| A2 | `Task.detached` or inner `Task {}` inside `NotificationScheduler.reschedule()` is sufficient to avoid blocking `recompute()` on MainActor | Common Pitfalls #4 | Medium — if compiler rejects, the fix is adding `Task { }` at the call site in `ScheduleStore` instead |
| A3 | `willPresent` returning `[.banner, .sound, .badge]` is the correct behavior for foreground notification display in a health/supplement app | Pattern 1 | Low — this is the standard choice; app could also return `[]` to suppress foreground banner, but showing it is the expected behavior |

---

## Open Questions

1. **AppDelegate reference bridging timing**
   - What we know: `AppDelegate` is instantiated by UIKit before `StackWiseApp.init()` runs; `AppState` is created in `StackWiseApp.init()`.
   - What's unclear: The safest moment to assign `appDelegate.appState = appState` — `.task {}` on the root view may run slightly after first render.
   - Recommendation: Use the `pendingTab` pattern (Pitfall 6 above) so that cold-start notification taps are never lost regardless of assignment timing.

2. **NotificationPermissionView gate placement — fullScreenCover vs if/else branch**
   - What we know: D-01 specifies the screen "appears as a gate" between onboarding completion and the TabView.
   - What's unclear: Whether to use `.fullScreenCover(isPresented:)` (animated, modal) or an `if/else` branch in the ContentView body (instant switch). The Phase 5 onboarding used `.fullScreenCover` for the preview step.
   - Recommendation: Use the `if/else` branch pattern consistent with how Phase 5 gates the onboarding. A `fullScreenCover` modal would allow dismissal without action; an `if/else` branch is non-dismissible by default, matching the "gate" intent of D-01. The planner should decide and document.

---

## Environment Availability

Step 2.6: SKIPPED — No new external dependencies. All frameworks (`UserNotifications`, `CoreData`, `SwiftUI`) are built-in iOS system frameworks. No new packages, CLIs, or services required.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | StackWise.xcodeproj (no separate pytest.ini) |
| Quick run command | `xcodebuild test-without-building -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same — all tests run together in the StackWiseTests target |

**Current test count:** 50 tests passing (verified 2026-05-24). Phase 6 will add new tests.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-20 | NotificationScheduler skips when not authorized | unit | `xcodebuild test-without-building ... -only-testing StackWiseTests/NotificationSchedulerTests/testSkipsWhenNotAuthorized` | ❌ Wave 0 |
| REQ-20 | NotificationScheduler schedules 1 request per non-empty block | unit | `xcodebuild test-without-building ... -only-testing StackWiseTests/NotificationSchedulerTests/testSchedulesOneRequestPerNonEmptyBlock` | ❌ Wave 0 |
| REQ-20 | NotificationScheduler notification body lists item labels | unit | `xcodebuild test-without-building ... -only-testing StackWiseTests/NotificationSchedulerTests/testNotificationBodyListsItemLabels` | ❌ Wave 0 |
| REQ-21 | DailyCheckOff write persists with correct timeBlock and midnight date | unit | `xcodebuild test-without-building ... -only-testing StackWiseTests/DailyCheckOffTests/testWritePersiststoMidnightDate` | ❌ Wave 0 |
| REQ-21 | DailyCheckOff fetch predicate returns correct record for today | unit | `xcodebuild test-without-building ... -only-testing StackWiseTests/DailyCheckOffTests/testFetchPredicateMatchesToday` | ❌ Wave 0 |
| REQ-21 | Block "past" determination: suggestedTime < Date.now | unit | `xcodebuild test-without-building ... -only-testing StackWiseTests/TodayViewModelTests/testPastBlockDetermination` | ❌ Wave 0 |

**Note on NotificationScheduler testability:** `UNUserNotificationCenter` has no public initializer and cannot be directly instantiated in tests. The standard workaround is protocol abstraction — define a `NotificationCenterProtocol` with the methods used (`add(_:)`, `removeAllPendingNotificationRequests()`, `notificationSettings()`), make `NotificationScheduler` accept the protocol via dependency injection, and use a mock in tests. [VERIFIED: Apple Developer Forums thread/54187, onmyway133.com]

Alternatively, for a simpler approach matching the project's existing pattern (which tests behavior rather than mock interactions), `NotificationSchedulerTests` can test the **pure logic** of building `UNNotificationRequest` content (title, body, identifier, trigger hour/minute) without ever calling the actual `UNUserNotificationCenter`. This is simpler and avoids the protocol overhead.

### Sampling Rate
- **Per task commit:** `xcodebuild test-without-building -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Per wave merge:** Full suite (same command)
- **Phase gate:** Full suite green (≥56 tests, 50 existing + 6 new) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `StackWiseTests/NotificationSchedulerTests.swift` — covers REQ-20 (3 tests)
- [ ] `StackWiseTests/DailyCheckOffTests.swift` — covers REQ-21 (2 tests)
- [ ] `StackWiseTests/TodayViewModelTests.swift` — covers past-block logic REQ-21 (1 test)

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high`

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No user auth in this phase |
| V3 Session Management | No | No sessions in this phase |
| V4 Access Control | No | All data is single-user, on-device |
| V5 Input Validation | Yes (low exposure) | Notification body content comes from `ScheduledItem.label` (user-entered string, already stored in Core Data — no new input path) |
| V6 Cryptography | No | No encryption required for local notifications or DailyCheckOff data |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Health data leakage via notification body | Information Disclosure | Notification body lists supplement labels only (user's own data, no PII beyond supplement names). Standard iOS notification privacy controls (Face ID notification preview) apply at the OS level. |
| Core Data injection via timeBlock predicate | Tampering | `timeBlock` is an app-controlled string enum value (`"morning"`, `"afternoon"`, `"evening"`), never user-typed. No injection risk. |

**Security summary:** Phase 6 has a very low attack surface. All data is on-device, notification content is the user's own supplement labels, and no new network calls are introduced. ASVS Level 1 requirements are met by design.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: `UNCalendarNotificationTrigger`, `UNUserNotificationCenter.requestAuthorization`, `UNNotificationRequest` — verified via WebFetch and WebSearch
- Apple Developer Forums thread/762217 — UNUserNotificationCenterDelegate in SwiftUI, AppDelegate requirement, @preconcurrency pattern
- createwithswift.com/notifications-tutorial-* — async/await notification scheduling pattern
- swiftwithmajid.com/2024/04/09/deep-linking-for-local-notifications-in-swiftui/ — SwiftUI + AppDelegate + @UIApplicationDelegateAdaptor pattern
- Existing codebase (`ScheduleStore.swift`, `DailyCheckOff+CoreDataClass.swift`, `AppState.swift`, `ContentView.swift`, `StackWiseApp.swift`, `OnboardingCoordinatorTests.swift`) — VERIFIED via direct file reads

### Secondary (MEDIUM confidence)
- donnywals.com/scheduling-daily-notifications — repeats:true pattern for daily reminders
- medium.com/@jakir — Core Data NSPredicate date range pattern
- Apple Developer Forums thread/811171 — 64 pending notification limit confirmed

### Tertiary (LOW confidence)
- None — all substantive claims have been verified at MEDIUM or HIGH level.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all built-in frameworks, verified in codebase
- Architecture: HIGH — UNUserNotificationCenterDelegate AppDelegate requirement verified in Apple forums; TabView selection pattern verified via official docs
- Pitfalls: HIGH — cold-start notification tap (#6), date normalization (#3), and stable identifier (#3 in anti-patterns) are all well-documented iOS gotchas verified via official sources
- Test patterns: MEDIUM — NotificationScheduler testability via protocol abstraction is the community-standard pattern; Apple has no official docs specifically on mocking UNUserNotificationCenter

**Research date:** 2026-05-26
**Valid until:** 2026-06-26 (UserNotifications API is stable; no breaking changes expected in minor iOS releases)
