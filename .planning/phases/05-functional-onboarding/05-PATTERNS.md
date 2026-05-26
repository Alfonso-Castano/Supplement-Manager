# Phase 5: Functional Onboarding - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 8 (6 new, 2 modified)
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `StackWise/Features/Onboarding/OnboardingCoordinatorView.swift` | coordinator/view | request-response + event-driven | `StackWise/ContentView.swift` + `StackWise/StackWiseApp.swift` | role-match (navigation + environment) |
| `StackWise/Features/Onboarding/StackEntryStepView.swift` | view (wrapper) | event-driven | `StackWise/Features/Stack/StackListView.swift` | exact (FetchRequest gate + sheet for AddItemView) |
| `StackWise/Features/Onboarding/ScheduleInputsView.swift` | view (form step) | CRUD | `StackWise/Features/Onboarding/HealthProfileView.swift` | exact (same DatePicker fields, same Core Data save pattern) |
| `StackWise/Features/Onboarding/OnboardingPreviewView.swift` | view (summary) | request-response | `StackWise/Features/Stack/AnalysisView.swift` | role-match (reads from @Observable store, NavigationLink push) |
| `StackWise/Features/Onboarding/PaywallPlaceholderView.swift` | view (CTA screen) | request-response | `StackWise/Features/Onboarding/HealthProfileView.swift` | partial-match (onComplete closure, Core Data write on action) |
| `StackWiseTests/OnboardingCoordinatorTests.swift` | test | — | `StackWiseTests/UserProfileStoreTests.swift` + `StackWiseTests/StackItemFactoryTests.swift` | exact (PersistenceController(inMemory:) setup, XCTestCase pattern) |
| `StackWise/ContentView.swift` *(modified)* | view (gate) | event-driven | self — modify in place | exact |
| `StackWise/Features/Onboarding/HealthProfileView.swift` *(modified)* | view (form step) | CRUD | self — surgical removal | exact |

---

## Pattern Assignments

### `OnboardingCoordinatorView.swift` (coordinator, event-driven)

**Primary analog:** `StackWise/ContentView.swift`
**Secondary analog:** `StackWise/StackWiseApp.swift`

**Imports pattern** (`ContentView.swift` lines 1–2, `StackWiseApp.swift` lines 1–2):
```swift
import SwiftUI
import CoreData
```

**Environment injection pattern** (`ContentView.swift` lines 4–6):
```swift
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context
```

**@Bindable for @Observable mutation in body** (`ContentView.swift` line 8):
```swift
// Required when you need to pass a Binding into a child from an @Observable environment object
@Bindable var appState = appState
```

**Core Data fetch in .task** (`ContentView.swift` lines 27–30):
```swift
.task {
    let profile = UserProfileStore.fetchOrCreate(in: context)
    appState.onboardingComplete = profile.onboardingComplete
}
```

**Coordinator structure to build** (from RESEARCH.md Pattern 1 — verified against codebase APIs):
```swift
// OnboardingCoordinatorView.swift
import SwiftUI
import CoreData

enum OnboardingStep: Hashable {
    case stackEntry
    case scheduleInputs
}

struct OnboardingCoordinatorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context

    @State private var path: [OnboardingStep] = []
    @State private var showPreview: Bool = false
    @State private var showPaywall: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            HealthProfileView(onNext: { path.append(.stackEntry) })
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .stackEntry:
                        StackEntryStepView(onNext: { path.append(.scheduleInputs) })
                    case .scheduleInputs:
                        ScheduleInputsView(onNext: { showPreview = true })
                    }
                }
        }
        .fullScreenCover(isPresented: $showPreview) {
            OnboardingPreviewView(onStartTrial: { showPaywall = true })
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallPlaceholderView(onComplete: { completeOnboarding() })
                        .interactiveDismissDisabled(true)
                }
        }
        .task { applySmartResume() }
    }

    private func applySmartResume() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        let itemRequest = StackItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isActive == YES")
        let itemCount = (try? context.count(for: itemRequest)) ?? 0

        if profile.age == 0 || profile.weightKg == 0 {
            path = []                                              // Step 1
        } else if itemCount == 0 {
            path = [.stackEntry]                                   // Step 2
        } else if profile.wakeTime == nil {
            path = [.stackEntry, .scheduleInputs]                  // Step 3
        } else {
            path = [.stackEntry, .scheduleInputs]
            showPreview = true                                     // Step 4
        }
    }

    private func completeOnboarding() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        UserProfileStore.markOnboarded(profile, in: context)
        @Bindable var appState = appState
        appState.onboardingComplete = true
    }
}
```

**Key note on path construction:** Step 1 (`HealthProfileView`) is the root of the NavigationStack, not a value in the path array. Path only contains steps 2 and 3. Smart resume for "step 2" = `[.stackEntry]`, not `[.healthProfile, .stackEntry]`.

---

### `StackEntryStepView.swift` (view wrapper, event-driven)

**Primary analog:** `StackWise/Features/Stack/StackListView.swift`

**FetchRequest pattern** (`StackListView.swift` lines 5–9):
```swift
@FetchRequest(
    sortDescriptors: [SortDescriptor(\StackItem.sortOrder, order: .forward)],
    predicate: NSPredicate(format: "isActive == YES")
)
private var items: FetchedResults<StackItem>
```

**Sheet for AddItemView pattern** (`StackListView.swift` lines 12–13, 45–48):
```swift
@State private var showAddItem = false

// ...
.sheet(isPresented: $showAddItem) {
    AddItemView()
}
```

**Environment pattern for stores** (`StackListView.swift` line 11):
```swift
@Environment(AnalysisStore.self) private var analysisStore
```

**Item gate (disabled Next button) — build from FetchRequest count:**
```swift
// StackEntryStepView.swift — gate pattern uses items.isEmpty from @FetchRequest
struct StackEntryStepView: View {
    var onNext: () -> Void

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\StackItem.sortOrder, order: .forward)],
        predicate: NSPredicate(format: "isActive == YES")
    )
    private var items: FetchedResults<StackItem>

    @State private var showAddItem = false

    var body: some View {
        VStack {
            // Embed StackListView inline or reimplement card list here
            // ...

            if items.isEmpty {
                Text("Add your supplements to see how they interact and get your personalized schedule")
                    .font(.swBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button("Next", action: onNext)
                .disabled(items.isEmpty)          // D-08: hard minimum 1 item
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
        .navigationTitle("Your Stack")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddItem = true } label: {
                    Image(systemName: "plus").foregroundStyle(.aquaPrimary)
                }
            }
        }
    }
}
```

---

### `ScheduleInputsView.swift` (form step, CRUD)

**Primary analog:** `StackWise/Features/Onboarding/HealthProfileView.swift`

**Imports + Environment pattern** (`HealthProfileView.swift` lines 1–7):
```swift
import SwiftUI
import CoreData

struct HealthProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context
```

**DatePicker @State fields** (`HealthProfileView.swift` lines 11–15):
```swift
@State private var wakeTime: Date = Self.defaultTime(hour: 7)
@State private var sleepTime: Date = Self.defaultTime(hour: 23)
@State private var breakfastTime: Date = Self.defaultTime(hour: 8)
@State private var lunchTime: Date = Self.defaultTime(hour: 12, minute: 30)
@State private var dinnerTime: Date = Self.defaultTime(hour: 19)
```

**DatePicker Section block** (`HealthProfileView.swift` lines 43–49) — this entire block moves to ScheduleInputsView:
```swift
Section("Schedule") {
    DatePicker("Wake", selection: $wakeTime, displayedComponents: .hourAndMinute)
    DatePicker("Sleep", selection: $sleepTime, displayedComponents: .hourAndMinute)
    DatePicker("Breakfast", selection: $breakfastTime, displayedComponents: .hourAndMinute)
    DatePicker("Lunch", selection: $lunchTime, displayedComponents: .hourAndMinute)
    DatePicker("Dinner", selection: $dinnerTime, displayedComponents: .hourAndMinute)
}
```

**defaultTime helper** (`HealthProfileView.swift` lines 92–94):
```swift
private static func defaultTime(hour: Int, minute: Int = 0) -> Date {
    Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
}
```

**Core Data save pattern** (`HealthProfileView.swift` lines 70–84) — ScheduleInputsView save writes ONLY the time fields (not personal fields; not markOnboarded):
```swift
private func save() {
    let profile = UserProfileStore.fetchOrCreate(in: context)
    // Write time fields only — personal fields written by HealthProfileView.save()
    profile.wakeTime = wakeTime
    profile.sleepTime = sleepTime
    profile.breakfastTime = breakfastTime
    profile.lunchTime = lunchTime
    profile.dinnerTime = dinnerTime
    do {
        try context.save()
    } catch {
        assertionFailure("ScheduleInputsView save failed: \(error)")
    }
}
```

**onAppear pre-populate pattern** (self-contained view — read from Core Data on appear):
```swift
// Pre-populate @State from Core Data if previously saved (supports crash resume)
.onAppear {
    let profile = UserProfileStore.fetchOrCreate(in: context)
    if let wake = profile.wakeTime { wakeTime = wake }
    if let sleep = profile.sleepTime { sleepTime = sleep }
    if let breakfast = profile.breakfastTime { breakfastTime = breakfast }
    if let lunch = profile.lunchTime { lunchTime = lunch }
    if let dinner = profile.dinnerTime { dinnerTime = dinner }
}
```

**Toolbar Next button pattern** (`HealthProfileView.swift` lines 61–65):
```swift
.toolbar {
    ToolbarItem(placement: .confirmationAction) {
        Button("Next") {
            save()
            onNext()
        }
    }
}
```

---

### `OnboardingPreviewView.swift` (summary view, request-response)

**Primary analog:** `StackWise/Features/Stack/AnalysisView.swift`

**Environment store access pattern** (`AnalysisView.swift` lines 4–5):
```swift
struct AnalysisView: View {
    @Environment(AnalysisStore.self) private var store
```

**currentResults() call pattern** (`AnalysisView.swift` line 7):
```swift
let results = store.currentResults()
```

**Secondary analog for ScheduleStore:** `StackWise/Schedule/ScheduleStore.swift`

**currentSchedule() call pattern** (`ScheduleStore.swift` line 32):
```swift
func currentSchedule() -> ScheduleResult
```

**ScheduleResult shape** (`StackWise/Schedule/ScheduleResult.swift`) — access `cachedResult?.morning.count + .afternoon.count + .evening.count` for block count, or use the existing `.allItems()` count.

**NavigationLink push to AnalysisView** (`StackListView.swift` lines 62–69):
```swift
NavigationLink {
    AnalysisView()
} label: {
    // label view
}
```

**fullScreenCover wrap requirement** (from RESEARCH.md Pitfall 5): `OnboardingPreviewView` must be wrapped in its own `NavigationStack` so the "See full analysis" NavigationLink has a stack to push onto:
```swift
// In OnboardingPreviewView.body
NavigationStack {
    ScrollView {
        // summary card content
        NavigationLink("See full analysis") { AnalysisView() }
    }
    .navigationTitle("Your Results")
}
```

**Store force-recompute on appear** (from RESEARCH.md Pitfall 4):
```swift
.task {
    _ = analysisStore.currentResults()     // force recompute before render
    _ = scheduleStore.currentSchedule()
}
```

**Typography tokens to use** (`DesignSystem.swift` lines 103–111):
```swift
// Available font tokens
Font.swLargeTitle  // 34pt bold
Font.swTitle1      // 28pt bold
Font.swTitle2      // 22pt bold
Font.swHeadline    // 17pt semibold
Font.swBody        // 17pt regular
Font.swFootnote    // 13pt regular
```

---

### `PaywallPlaceholderView.swift` (CTA screen, request-response)

**Primary analog:** `StackWise/Features/Onboarding/HealthProfileView.swift` (closure callback + Core Data write)

**Closure callback pattern** — view accepts a completion closure, same as step views receive `onNext`:
```swift
struct PaywallPlaceholderView: View {
    var onComplete: () -> Void  // called after writing Core Data — coordinator handles appState update
```

**interactiveDismissDisabled placement** (`HealthProfileView.swift` line 67) — place on the view root, not the modifier chain:
```swift
// HealthProfileView uses this — PaywallPlaceholderView inherits the same placement convention
.interactiveDismissDisabled(true)
```

**Background color pattern** (`StackListView.swift` line 27, `DesignSystem.swift` lines 57–58):
```swift
Color.backgroundPage.ignoresSafeArea()
// or
.background(Color.backgroundPage.ignoresSafeArea())
```

**Zone structure to build** (D-11 — 4 zones, each a separate VStack with comment boundary):
```swift
struct PaywallPlaceholderView: View {
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: Zone 1 — Hero / value prop
                // Phase 7: replace with hero image + headline
                Text("[Hero / value prop zone]")
                    .font(.swTitle2)

                // MARK: Zone 2 — Social proof
                // Phase 7: replace with review stars, quote, attribution
                Text("[Social proof zone]")
                    .font(.swBody)

                // MARK: Zone 3 — Pricing
                // Phase 7: replace with StoreKit ProductView / RevenueCat offering
                Text("14-day free trial, then $4.99/month")
                    .font(.swBody)

                // MARK: Zone 4 — CTA
                // Phase 7: replace Button action with RevenueCat purchase flow
                VStack(spacing: 12) {
                    Button("Start Free Trial", action: onComplete)

                    Button("Restore Purchases") { /* Phase 7 */ }
                        .font(.swBody)
                        .foregroundStyle(.aquaPrimary)

                    Text("No commitment. Cancel anytime.")
                        .font(.swFootnote)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(24)
        }
        .background(Color.backgroundPage.ignoresSafeArea())
        .interactiveDismissDisabled(true)
    }
}
```

---

### `StackWiseTests/OnboardingCoordinatorTests.swift` (test file)

**Primary analog:** `StackWiseTests/UserProfileStoreTests.swift`
**Secondary analog:** `StackWiseTests/StackItemFactoryTests.swift`

**Test file header + imports** (`UserProfileStoreTests.swift` lines 1–4):
```swift
import XCTest
import CoreData
@testable import StackWise

final class OnboardingCoordinatorTests: XCTestCase {
```

**setUp/tearDown with in-memory store** (`UserProfileStoreTests.swift` lines 6–17):
```swift
var controller: PersistenceController!
var context: NSManagedObjectContext!

override func setUpWithError() throws {
    controller = PersistenceController(inMemory: true)
    context = controller.container.viewContext
}

override func tearDownWithError() throws {
    controller = nil
    context = nil
}
```

**StackItem insertion helper** (`StackItemFactoryTests.swift` lines 20–40) — use `StackItemFactory.create()` to seed items, same pattern as existing tests:
```swift
let input = StackItemFactory.Input(label: "Vitamin D3", dosage: "2000 IU",
                                    frequency: "daily", isPrescription: false, match: nil)
_ = try StackItemFactory.create(input, in: context)
```

**UserProfile fetch pattern in tests** (`UserProfileStoreTests.swift` lines 21–24):
```swift
let profile = UserProfileStore.fetchOrCreate(in: context)
```

**What to test** (from RESEARCH.md Validation Architecture — all pure logic, no UI):
```swift
// REQ-18: smart resume branches
func testResumeWithNoProfile_startsAtStepOne() { ... }
func testResumeWithProfileAndNoItems_startsAtStepTwo() { ... }
func testResumeWithItemsAndNoWakeTime_startsAtStepThree() { ... }
func testResumeWithAllData_showsPreview() { ... }

// D-08: item gate
func testNextDisabledWhenZeroItems() { ... }  // test via items.isEmpty logic

// REQ-19: trial trigger idempotency (already in UserProfileStoreTests — reference only)
// testMarkOnboardedFlipsFlagAndPersists — DO NOT duplicate
```

**@MainActor annotation** — needed only if testing `@MainActor @Observable` stores directly. For coordinator state tests using `UserProfileStore` (no MainActor), annotation is not required. See `AnalysisStoreTests.swift` line 6 for when it is needed:
```swift
@MainActor
final class AnalysisStoreTests: XCTestCase {
```

---

### `ContentView.swift` (modified — gate replacement)

**Self-analog** — modify in place. Current code to remove (`ContentView.swift` lines 31–36):
```swift
// REMOVE THIS BLOCK ENTIRELY:
.sheet(isPresented: Binding(
    get: { !appState.onboardingComplete },
    set: { _ in /* dismissal is driven by the save action, not the user */ }
)) {
    HealthProfileView()
}
```

**Replacement gate pattern** (`ContentView.swift` body, after the `.task` is retained):
```swift
var body: some View {
    @Bindable var appState = appState

    if appState.onboardingComplete {
        TabView {
            StackListView().tabItem { Label("Stack", systemImage: "pills") }
            TodayView().tabItem { Label("Today", systemImage: "checkmark.circle") }
            ScheduleView().tabItem { Label("Schedule", systemImage: "calendar") }
        }
        .tint(.aquaPrimary)
    } else {
        OnboardingCoordinatorView()
    }
}
// Retain the existing .task { } that reads profile.onboardingComplete — it sets the gate
```

---

### `HealthProfileView.swift` (modified — surgical removal)

**Self-analog** — four surgical changes to existing file.

**Change 1 — Remove schedule @State fields** (`HealthProfileView.swift` lines 11–15): Remove the five `@State private var *Time` declarations.

**Change 2 — Remove Schedule Section** (`HealthProfileView.swift` lines 43–49): Remove the entire `Section("Schedule") { ... }` block.

**Change 3 — Remove markOnboarded + appState write from save()** (`HealthProfileView.swift` lines 82–83):
```swift
// REMOVE:
UserProfileStore.markOnboarded(profile, in: context)
appState.onboardingComplete = true

// Also remove the time field writes from save() (lines 75–79):
profile.wakeTime = wakeTime
profile.sleepTime = sleepTime
profile.breakfastTime = breakfastTime
profile.lunchTime = lunchTime
profile.dinnerTime = dinnerTime
```

**Change 4 — Replace NavigationStack wrapper + toolbar Save with onNext callback:**
```swift
// Add parameter:
struct HealthProfileView: View {
    var onNext: () -> Void = {}   // default no-op preserves reusability outside coordinator

// Replace toolbar button:
ToolbarItem(placement: .confirmationAction) {
    Button("Next") {
        save()
        onNext()
    }.disabled(!canSave)
}

// Remove the NavigationStack { } wrapper — coordinator provides its own
// Remove .interactiveDismissDisabled(true) — coordinator handles this
// Remove @Environment(AppState.self) if no longer used after markOnboarded removal
```

---

## Shared Patterns

### @Observable + .environment() — Project-wide lock

**Source:** `StackWise/StackWiseApp.swift` lines 6–11, `StackWise/Models/AppState.swift`
**Apply to:** All new view files
```swift
// Store declaration (in StackWiseApp.swift — do not add new @State stores for Phase 5)
@State private var appState: AppState

// Consumer pattern (all views)
@Environment(AppState.self) private var appState
@Environment(AnalysisStore.self) private var analysisStore
@Environment(ScheduleStore.self) private var scheduleStore
```
**Rule:** Never use `@ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject`. Use `@Observable` + `.environment()` only. No new stores are needed for Phase 5.

### Core Data Singleton Fetch

**Source:** `StackWise/Models/UserProfileStore.swift` lines 8–24
**Apply to:** `OnboardingCoordinatorView`, `ScheduleInputsView`, `PaywallPlaceholderView`
```swift
let profile = UserProfileStore.fetchOrCreate(in: context)
```
Never instantiate `UserProfile(context:)` directly — always go through `fetchOrCreate`.

### Core Data Save Pattern

**Source:** `StackWise/Models/UserProfileStore.swift` lines 16–23
**Apply to:** `ScheduleInputsView.save()`
```swift
do {
    try context.save()
} catch {
    assertionFailure("Description of what failed: \(error)")
}
```

### Design System Token Usage

**Source:** `StackWise/DesignSystem.swift`
**Apply to:** All new view files
```swift
// Colors — use dot-syntax tokens, never raw hex
.foregroundStyle(.textPrimary)
.foregroundStyle(.textSecondary)
.background(Color.backgroundPage.ignoresSafeArea())
.background(Color.backgroundCard)
.foregroundStyle(.aquaPrimary)

// Typography — use sw* tokens, never .system(size:)
.font(.swTitle2)
.font(.swBody)
.font(.swHeadline)
.font(.swFootnote)
```

### FetchRequest for Live Item Count

**Source:** `StackWise/Features/Stack/StackListView.swift` lines 5–9
**Apply to:** `StackEntryStepView.swift`
```swift
@FetchRequest(
    sortDescriptors: [SortDescriptor(\StackItem.sortOrder, order: .forward)],
    predicate: NSPredicate(format: "isActive == YES")
)
private var items: FetchedResults<StackItem>
```
`@FetchRequest` is live-updating — no manual observation needed for the item gate.

### invalidate() Before Reading Stores in New Screen

**Source:** `StackWise/Features/Stack/StackItemFactory.swift` line 35
**Apply to:** `OnboardingPreviewView`
```swift
// Called by StackItemFactory.create() already:
analysisStore.invalidate()
scheduleStore.invalidate()

// But OnboardingPreviewView must force recompute on appear (from RESEARCH.md Pitfall 4):
.task {
    _ = analysisStore.currentResults()
    _ = scheduleStore.currentSchedule()
}
```

---

## No Analog Found

No files are without analog. All 6 new files have direct codebase matches.

---

## Metadata

**Analog search scope:** `StackWise/Features/`, `StackWise/Models/`, `StackWise/Analysis/`, `StackWise/Schedule/`, `StackWiseTests/`
**Files scanned:** 27 Swift source files
**Key source files read:** `HealthProfileView.swift`, `ContentView.swift`, `StackWiseApp.swift`, `AppState.swift`, `UserProfileStore.swift`, `UserProfile+CoreDataClass.swift`, `StackListView.swift`, `AddItemView.swift`, `StackItemFactory.swift`, `AnalysisStore.swift`, `ScheduleStore.swift`, `AnalysisView.swift`, `DesignSystem.swift`, `Persistence.swift`, `UserProfileStoreTests.swift`, `StackItemFactoryTests.swift`, `AnalysisStoreTests.swift`
**Pattern extraction date:** 2026-05-25
