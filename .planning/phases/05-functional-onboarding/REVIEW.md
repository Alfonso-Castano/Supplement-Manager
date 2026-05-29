---
phase: 05-functional-onboarding
reviewed: 2026-05-26T00:00:00Z
depth: deep
files_reviewed: 8
files_reviewed_list:
  - StackWise/Features/Onboarding/OnboardingCoordinatorView.swift
  - StackWise/Features/Onboarding/HealthProfileView.swift
  - StackWise/Features/Onboarding/StackEntryStepView.swift
  - StackWise/Features/Onboarding/ScheduleInputsView.swift
  - StackWise/Features/Onboarding/OnboardingPreviewView.swift
  - StackWise/Features/Onboarding/PaywallPlaceholderView.swift
  - StackWise/ContentView.swift
  - StackWiseTests/OnboardingCoordinatorTests.swift
findings:
  critical: 4
  warning: 4
  info: 2
  total: 10
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-05-26
**Depth:** deep
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Eight Phase-5 files were reviewed at deep depth, including cross-file tracing of call chains
into `UserProfileStore`, `AnalysisStore`, `ScheduleStore`, and `AppState`. The smart-resume
and onboarding-completion paths are structurally sound. The test suite covers all four
REQ-18 branches and the REQ-19 idempotency invariant.

Four issues are classified CRITICAL because they can produce incorrect, unreachable, or
silently-dropped behavior in production. Four more are WARNINGs for robustness gaps that
will surface under realistic usage. Two INFO items flag dead code and a minor logic smell.

---

## Critical Issues

### CR-01: Nested `fullScreenCover` — paywall is unreachable on iOS 16/17

**File:** `StackWise/Features/Onboarding/OnboardingCoordinatorView.swift:29-35`

**Issue:** `PaywallPlaceholderView` is presented as a `fullScreenCover` that is _nested
inside_ the `OnboardingPreviewView`'s own `fullScreenCover`. SwiftUI does not support
presenting a sheet or cover from within another cover's view tree when the inner cover is
declared on the _presenting_ view rather than on the _presented_ view. The inner cover
modifier (line 31) is applied to `OnboardingPreviewView(...)`, not to any view inside
`OnboardingPreviewView`'s body. Because the outer cover takes over the presentation
context, the inner `.fullScreenCover` modifier is attached to a view in the dismissed
hierarchy and will silently never fire on iOS 16/17. The "Start Trial" button calls
`showPaywall = true`, which sets state on `OnboardingCoordinatorView`, but that state
drives a cover that is orphaned. The result: tapping "See What You're Getting" does
nothing — the paywall is never shown, and `completeOnboarding()` is never called.

**Fix:** Move the paywall presentation inside `OnboardingPreviewView`'s own body, and
pass a binding or callback so `OnboardingCoordinatorView` still drives the state:

```swift
// OnboardingCoordinatorView.swift
.fullScreenCover(isPresented: $showPreview) {
    OnboardingPreviewView(
        onStartTrial: { showPaywall = true },
        showPaywall: $showPaywall,
        onPaywallComplete: { completeOnboarding() }
    )
}
// No second .fullScreenCover here.

// OnboardingPreviewView.swift — add binding parameters
struct OnboardingPreviewView: View {
    var onStartTrial: () -> Void
    @Binding var showPaywall: Bool
    var onPaywallComplete: () -> Void

    var body: some View {
        NavigationStack { ... }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallPlaceholderView(onComplete: onPaywallComplete)
                    .interactiveDismissDisabled(true)
            }
    }
}
```

---

### CR-02: `ContentView` onboarding gate uses `.task` — creates a race condition on first launch

**File:** `StackWise/ContentView.swift:33-36`

**Issue:** `ContentView.body` evaluates the `if appState.onboardingComplete` branch
_immediately_ on first render. At that moment `appState.onboardingComplete` is `false`
(the default in `AppState`). The `.task` that fetches the persisted flag fires _after_
the first render completes. This means:

1. On first launch (profile doesn't exist yet): the view correctly shows `OnboardingCoordinatorView`.
   No problem here.
2. On a returning user whose `profile.onboardingComplete == true`: there is a visible
   flash where `OnboardingCoordinatorView` is rendered for one frame (the `.task` has
   not run yet), before `appState.onboardingComplete` flips to `true` and the `TabView`
   replaces it. Worse, `applySmartResume()` in `OnboardingCoordinatorView` also fires
   during that frame via _its own_ `.task`, calling `UserProfileStore.fetchOrCreate` and
   potentially triggering a `NavigationStack` push. If the task completes before
   `ContentView`'s task, the coordinator may push into the stack before the host view
   knows it should not be showing at all.
3. `appState.onboardingComplete` is mutated from the `.task` closure, which runs on the
   `@MainActor` by default in SwiftUI. However, `AppState` is a plain `@Observable`
   class with no explicit `@MainActor` annotation. If any callsite ever mutates it off
   the main actor, there is a data race on `onboardingComplete`.

**Fix:** Initialize `appState.onboardingComplete` synchronously at app-startup time
(in the `@main` app struct or a dedicated bootstrap function called before the window
is shown), not lazily inside a view. This eliminates the race entirely:

```swift
// StackWiseApp.swift (or wherever the app entry point is)
@main struct StackWiseApp: App {
    @State private var appState = AppState()
    let persistence = PersistenceController.shared

    init() {
        // Synchronous bootstrap — no race.
        let profile = UserProfileStore.fetchOrCreate(
            in: PersistenceController.shared.container.viewContext
        )
        _appState = State(initialValue: AppState())
        _appState.wrappedValue.onboardingComplete = profile.onboardingComplete
    }
    ...
}
```

---

### CR-03: `HealthProfileView.save()` calls `parseList` twice per field, then silently drops Core Data save errors

**File:** `StackWise/Features/Onboarding/HealthProfileView.swift:62-64`

**Issue — double computation:** Lines 62–63 call `Self.parseList(allergiesText)` twice
each time `save()` runs (once for the `.isEmpty` guard, once to assign). For long allergy
or conditions strings this is harmless in practice, but it is an unambiguous code defect
— the expression is computed twice with no guarantee the result is identical (it is
here, because it is a pure function, but the pattern invites future bugs if the function
ever gains side effects or is replaced).

**Issue — silent save failure:** Line 64 calls `try? context.save()`. If the Core Data
save fails (e.g., a validation rule fires, disk is full), the failure is silently swallowed.
The user sees no error, taps "Next", and advances through the onboarding flow with unsaved
data. On the next app launch, `applySmartResume()` will fail to read the data and drop
the user back to Step 1, corrupting their onboarding experience.

**Fix:**

```swift
private func save() {
    let profile = UserProfileStore.fetchOrCreate(in: context)
    profile.age = Int16(age)
    profile.sex = sex
    profile.weightKg = weightKg
    let parsedAllergies = Self.parseList(allergiesText)
    let parsedConditions = Self.parseList(conditionsText)
    profile.allergies = parsedAllergies.isEmpty ? nil : parsedAllergies
    profile.conditions = parsedConditions.isEmpty ? nil : parsedConditions
    do {
        try context.save()
    } catch {
        // Surface to user — at minimum log; ideally set @State var saveError
        print("HealthProfileView: Core Data save failed: \(error)")
    }
}
```

---

### CR-04: `ScheduleInputsView` "Next" button is always enabled — schedule can be saved with logically invalid times

**File:** `StackWise/Features/Onboarding/ScheduleInputsView.swift:27-33`

**Issue:** The "Next" toolbar button has no `disabled()` modifier and performs no
validation before calling `save()` and `onNext()`. The user can set `sleepTime` earlier
than `wakeTime` (e.g., wake at 23:00, sleep at 07:00), or set `breakfastTime` before
`wakeTime`. `ScheduleStore.recompute()` consumes these times directly and will produce
a schedule with negative time windows, placing `suggestedTime` values before the user's
wakeTime. `ScheduleEngine.schedule()` does not guard against inverted wake/sleep times.

Additionally, `ScheduleInputsView.save()` (line 44-52) also swallows errors via
`try? context.save()`, same defect pattern as CR-03.

**Fix:** Add a `canSave` guard and expose a validation error to the user:

```swift
private var canSave: Bool {
    wakeTime < sleepTime &&
    wakeTime <= breakfastTime &&
    breakfastTime <= lunchTime &&
    lunchTime <= dinnerTime &&
    dinnerTime <= sleepTime
}

// In toolbar:
Button("Next") {
    save()
    onNext()
}
.disabled(!canSave)
```

---

## Warnings

### WR-01: `OnboardingPreviewView` navigates to `AnalysisView` from inside a `fullScreenCover` — NavigationStack collision

**File:** `StackWise/Features/Onboarding/OnboardingPreviewView.swift:13, 39-45`

**Issue:** `OnboardingPreviewView` wraps its own `NavigationStack` (line 13). It is
presented via a `fullScreenCover` on `OnboardingCoordinatorView`, which is itself inside
_another_ `NavigationStack` (lines 18-28 of `OnboardingCoordinatorView`). The inner
`NavigationStack` is necessary because the outer one's path is not accessible from inside
a `fullScreenCover`. However, the `NavigationLink` to `AnalysisView()` (line 39) pushes
into this inner stack. If `AnalysisView` itself contains a `NavigationStack`, there will
be a nested `NavigationStack` warning at runtime and navigation behavior will be
undefined. Even if `AnalysisView` does not contain its own stack, once the user navigates
to `AnalysisView` and then taps "See What You're Getting", the `onStartTrial()` callback
fires on `OnboardingCoordinatorView`, setting `showPaywall = true` — but the user is no
longer on the cover's root view, so the paywall trigger may be invisible.

**Fix:** Remove the `NavigationStack` wrapper from `OnboardingPreviewView` and rely on
the host to provide navigation context, or ensure `AnalysisView` is presented as a sheet
rather than a push navigation.

---

### WR-02: `applySmartResume()` runs on every appear via `.task` — will re-execute if the view is pushed off and returns

**File:** `StackWise/Features/Onboarding/OnboardingCoordinatorView.swift:36`

**Issue:** `.task` is tied to the view's lifetime. If `OnboardingCoordinatorView` is
presented, the user goes forward, and SwiftUI ever destroys and recreates the view
(e.g., low memory, scene lifecycle), `.task` re-fires. `applySmartResume()` unconditionally
overwrites `path` and `showPreview`, stomping whatever navigation state the user had
manually built up. For Step 4 (`showPreview = true`), this is especially disruptive: if
the user is mid-paywall and the coordinator view is recreated, `showPreview` flips back
to `true` from the task, creating a presentation conflict with the live paywall sheet.

**Fix:** Guard the resume with a flag so it only runs once:

```swift
@State private var hasResumed = false

private func applySmartResume() {
    guard !hasResumed else { return }
    hasResumed = true
    // ... existing logic
}
```

---

### WR-03: `OnboardingPreviewView` computes `blockCount` from `ScheduleStore.currentSchedule()` at `.task` time — stale if schedule has not yet been built

**File:** `StackWise/Features/Onboarding/OnboardingPreviewView.swift:69-75`

**Issue:** `ScheduleStore.currentSchedule()` returns `ScheduleResult.empty` when
`cachedResult == nil` (see `ScheduleStore.swift:36`). The schedule is only populated
once `ScheduleStore.recompute()` has run _and_ a Core Data save has completed. There is
no explicit invalidation or recompute call in the onboarding flow after the user saves
schedule times in `ScheduleInputsView`. If the user reaches `OnboardingPreviewView`
before `ScheduleStore` has been primed (which is the case on first onboarding run,
because no external trigger calls `scheduleStore.invalidate()` after schedule times are
saved), `currentSchedule()` will return `empty` and `blockCount` will be `0`, showing
"Your 0-block schedule is ready" — a confusing and incorrect message.

**Fix:** Call `scheduleStore.invalidate()` in `ScheduleInputsView.save()` before calling
`onNext()`, so that when `OnboardingPreviewView`'s `.task` fires and calls
`currentSchedule()`, the store recomputes with the freshly saved schedule data.

---

### WR-04: Tests duplicate the coordinator logic verbatim instead of testing the coordinator — the tests cannot catch a regression in the real code

**File:** `StackWiseTests/OnboardingCoordinatorTests.swift:35-38, 56-62, 86-93, 118-131`

**Issue:** Every test in `OnboardingCoordinatorTests` hand-rolls the same `if/else if`
chain from `applySmartResume()` in local variables. This is a copy-paste of the
implementation, not a test of it. If a developer changes the resume logic in
`OnboardingCoordinatorView.applySmartResume()` — e.g., adds a new condition, reorders
branches, or changes the `age == 0` guard to `age < 0` — all four tests will still
pass because they test their own embedded copy of the old logic, not the live function.
The tests provide a false sense of coverage for REQ-18.

**Fix:** Extract `applySmartResume()` into a pure, testable helper (e.g., a static
function on `OnboardingCoordinatorView` or a free function in the Onboarding module)
that takes the profile state and item count as parameters and returns the desired
`(path: [OnboardingStep], showPreview: Bool)` tuple. The view then calls this function;
the tests call the same function directly.

---

## Info

### IN-01: Dead function `defaultTime(hour:minute:)` in `HealthProfileView`

**File:** `StackWise/Features/Onboarding/HealthProfileView.swift:73-75`

**Issue:** `HealthProfileView` defines a `private static func defaultTime(hour:minute:)`
(lines 73–75) that is never called anywhere in the file. `ScheduleInputsView` has its
own identical copy of this function. The one in `HealthProfileView` is dead code.

**Fix:** Remove it from `HealthProfileView.swift`.

---

### IN-02: `ScheduleInputsView.onAppear` calls `UserProfileStore.fetchOrCreate` on every appear — creates/fetches a Core Data object for a read-only operation

**File:** `StackWise/Features/Onboarding/ScheduleInputsView.swift:34-41`

**Issue:** `onAppear` calls `UserProfileStore.fetchOrCreate(in: context)` to read
schedule times. `fetchOrCreate` is documented as a write path — it inserts a new
`UserProfile` row if none exists and immediately saves the context. Using a write
function for a read-only pre-fill is semantically wrong and risks creating a phantom
`UserProfile` with default values if this view is somehow shown before `HealthProfileView`
has run (e.g., in a preview or test harness). On a normal flow the side effect is
harmless, but the pattern is fragile.

**Fix:** Use a plain `UserProfile.fetchRequest()` with `fetchLimit = 1` for the read,
and only call `fetchOrCreate` in `save()` where a write is intentional.

---

_Reviewed: 2026-05-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
