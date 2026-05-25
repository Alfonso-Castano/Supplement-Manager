# Phase 5: Functional Onboarding — Research

**Researched:** 2026-05-25
**Domain:** SwiftUI NavigationStack coordinator, Core Data state inference, third-party library evaluation, paywall placeholder structural requirements
**Confidence:** HIGH (all critical claims verified against codebase or official documentation; third-party library sizing verified via GitHub discussion)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** NavigationStack for steps 1–3 — back arrow active
- **D-02:** Preview screen onward is a one-way gate — no back navigation after "Start Free Trial" tap
- **D-03:** No global step indicator; phase-scoped indicators (dots within a sub-task) acceptable
- **D-04:** Preview screen is a hybrid summary card (headline stats + "See full analysis" affordance)
- **D-05:** "Start Free Trial" CTA on preview navigates to paywall placeholder (trigger fires on paywall, not preview)
- **D-06:** Reusing AnalysisView + ScheduleView as-is without conversion framing is ruled out
- **D-07:** Smart partial resume — infer step from Core Data entity state, no explicit cursor field
- **D-08:** Hard minimum of 1 StackItem before advancing from stack entry; Next button disabled until count > 0
- **D-09:** Inline hint copy when Next is disabled
- **D-10:** Notification permission is entirely outside Phase 5
- **D-11:** Paywall placeholder with 4 structural zones (hero, social proof, pricing, CTA); wireframe only
- **D-12:** Phase 5 placeholder fires trigger directly without StoreKit
- **D-13:** REQ-19 enforced by checking `trialStartDate == nil` before writing

### Claude's Discretion
- Exact animation/transition between onboarding steps
- Error state handling within individual steps
- Exact visual layout of the summary card counts on the preview screen

### Deferred Ideas (OUT OF SCOPE)
- Notification permission value-framing screen (Phase 6)
- StoreKit 2 / RevenueCat integration and real paywall design (Phase 7)
- Full paywall visual design (Phase 7 + design workflow)
- Onboarding redesign based on user feedback (post-launch)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-18 | Onboarding coordinator sequences health profile → stack entry → schedule inputs → preview screen; main app tabs hidden until complete | NavigationStack path-based coordinator with `@Observable` state; ContentView gate via `appState.onboardingComplete`; D-07 smart resume logic |
| REQ-19 | Trial start trigger fires exactly once; writes `trialStartDate` to UserProfile; persists locally | `UserProfileStore.markOnboarded()` already guards `trialStartDate == nil`; paywall CTA calls this method; `AppState.onboardingComplete` updated in sync |
</phase_requirements>

---

## Summary

Phase 5 wires together four already-built ingredients (HealthProfileView, AddItemView, StackListView, AnalysisView/ScheduleView) into a sequenced onboarding coordinator and adds two new screens (OnboardingPreviewView and PaywallPlaceholderView). The coordinator itself is the primary deliverable — roughly 150–200 lines of SwiftUI. No net-new data layer is required; all persistence already exists in Core Data via `UserProfile` and `StackItem`.

**Critical architectural discovery:** `HealthProfileView.swift` currently contains both the personal data fields (step 1) AND the schedule inputs (DatePickers for wake/sleep/meals). The UI-SPEC designates schedule inputs as a separate step 3 (`ScheduleInputsView`). This means step 3 must either be extracted from `HealthProfileView` into its own reusable view, or the coordinator embeds `HealthProfileView` with the schedule section hidden in step 1 and visible in step 3. The planner must decide: **extract or filter**. Research recommendation is extraction — a `ScheduleInputsView` that shares the same `@State` bindings pattern is 30 lines and eliminates conditional complexity.

The one-way gate (step 4 → paywall) is correctly implemented via `.fullScreenCover` on `OnboardingPreviewView`, with `interactiveDismissDisabled(true)` on the paywall. The `NavigationStack` back arrow for steps 1–3 is left native with no additional code; the coordinator simply does not push step 4 onto the NavigationStack — it presents it as a full-screen cover, making back navigation structurally impossible.

**Primary recommendation:** Build `OnboardingCoordinatorView` with a `NavigationPath`-bound `NavigationStack` for steps 1–3, present step 4 as `.fullScreenCover`, and let `ContentView` gate on `appState.onboardingComplete` (which it already reads from Core Data on `.task`). No third-party libraries are needed for Phase 5.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Onboarding gate (show coordinator vs TabView) | iOS App Layer (ContentView) | Core Data (UserProfile) | Gate is a conditional render based on persisted flag; no server involvement |
| Step sequencing (1→2→3) | OnboardingCoordinatorView | NavigationPath | Coordinator owns the path; individual step views are stateless about sequence |
| Step 1: Health profile data entry | HealthProfileView (reused) | UserProfile Core Data | View already exists; coordinator wraps it |
| Step 2: Stack entry + 1-item gate | StackEntryStepView (new) | AddItemView + StackListView (reused) | New thin wrapper enforces the item minimum gate |
| Step 3: Schedule inputs | ScheduleInputsView (extracted or new) | UserProfile Core Data | Extracted from HealthProfileView or new mirror; writes wake/meal DatePickers |
| Step 4: Preview summary card | OnboardingPreviewView (new) | AnalysisStore + ScheduleStore | New screen reads live computed stores; no new data layer |
| Paywall placeholder | PaywallPlaceholderView (new) | UserProfileStore | Writes trialStartDate + sets onboardingComplete |
| Trial trigger idempotency | UserProfileStore.markOnboarded() | UserProfile.trialStartDate | Already enforced: `if profile.trialStartDate == nil` guard exists |
| Smart resume detection | OnboardingCoordinatorView.onAppear | Core Data fetch | Inferred from entity state, no cursor field |

---

## Standard Stack

### Core (already in project — no installation needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI | Project lock (Phase 1 D-01) |
| Observation (`@Observable`) | iOS 17+ | State management | Project lock (Phase 1) |
| Core Data | iOS 17+ | UserProfile + StackItem persistence | Project lock (Phase 1) |
| XCTest | Xcode built-in | Unit tests for coordinator logic | Already used in 10 test files |

### No New Libraries Required for Phase 5

The evaluation below confirms no third-party libraries are needed. The coordinator, smart resume, gate logic, and paywall placeholder are all achievable with SwiftUI primitives in < 300 lines total.

### Third-Party Library Evaluation

| Library | Category | Pros | Cons | Verdict |
|---------|----------|------|------|---------|
| **lottie-spm** (Airbnb) v4.6.0 | Animation | Polished, well-maintained, iOS 13+ min, lottie-spm binary is ~500KB download | Requires After Effects JSON assets (none exist yet); Phase 5 uses default NavigationStack transitions (Claude's discretion, already decided); adds build dependency for zero functional gain in Phase 5 | **SKIP for Phase 5.** Revisit in Phase 9 (polish). [VERIFIED: github.com/airbnb/lottie-ios/discussions/1807] |
| **ConcentricOnboarding** (exyte) v1.1.1 | Onboarding flow framework | Zero dependencies, SPM available, MIT | Tap-based circular animation — not the right interaction model for a data-collection wizard flow; forces a specific visual paradigm that conflicts with form-based steps 1–3 | **SKIP.** Onboarding here is a data-entry wizard, not a marketing carousel. [VERIFIED: swiftpackageindex.com/exyte/ConcentricOnboarding] |
| **RevenueCatUI / PaywallView** | Paywall UI | One-liner paywall, remote config, built-in localization | Requires RevenueCat SDK init + active account + StoreKit product config to render anything useful; cannot render a wireframe placeholder without that setup; Phase 7 decision (D-12 explicit) | **SKIP Phase 5. PLAN for Phase 7.** The Phase 5 placeholder is intentionally custom and content-free. Phase 7 will add RevenueCat. [CITED: revenuecat.com/docs/tools/paywalls] |
| **SuperwallKit** | Paywall remote config | Remote paywall configuration without app updates | Heavier SDK than RevenueCat for subscription management; duplication if RevenueCat is Phase 7 choice; Phase 5 has no need for remote config | **SKIP.** REQUIREMENTS.md REQ-22–REQ-24 describe StoreKit 2 + RevenueCat (implied by sandbox entitlement verification language). [ASSUMED] |
| **ViewInspector** | Testing | Makes SwiftUI views inspectable in unit tests | Navigation state testing via XCTest works fine by testing the coordinator's `@Observable` state directly (no view inspection needed); adds a test-only dependency | **SKIP.** Test the coordinator state model, not the view tree. [CITED: XCTest documentation] |
| **FlowStacks** | Navigation | Unified push/sheet/cover API | Phase 5 has a simple linear flow (3 pushes + 1 cover); FlowStacks is designed for complex multi-modal navigation; overkill; adds a dependency for a problem that doesn't exist here | **SKIP.** [VERIFIED: swiftpackageindex.com/johnpatrickmorgan/flowstacks] |
| **TabView dot-indicator** (native) | Progress indicator | Zero-cost, system API | D-03 disables a global step indicator; no progress dots needed across the coordinator | **Use native if any indicator is added within a sub-step; no indicator at coordinator level.** [VERIFIED: codebase D-03] |

**SPM URLs (for Phase 7 reference only):**
- RevenueCat: `https://github.com/RevenueCat/purchases-ios` (tag: 5.27.1+)
- lottie-spm: `https://github.com/airbnb/lottie-spm.git` (tag: 4.6.0)

---

## Architecture Patterns

### System Architecture Diagram

```
App Launch
    │
    ▼
StackWiseApp.init()
    │  injects: AppState, AnalysisStore, ScheduleStore into environment
    ▼
ContentView
    │
    ├─ appState.onboardingComplete == false ──► OnboardingCoordinatorView
    │                                               │
    │                                               │  NavigationPath (steps 1–3)
    │                                               ├─► Step 1: HealthProfileView
    │                                               │       └─ "Next" push → Step 2
    │                                               │
    │                                               ├─► Step 2: StackEntryStepView
    │                                               │       ├─ embeds AddItemView (sheet)
    │                                               │       ├─ embeds StackListView (inline)
    │                                               │       └─ "Next" disabled if items == 0
    │                                               │          enabled → push Step 3
    │                                               │
    │                                               ├─► Step 3: ScheduleInputsView
    │                                               │       └─ "Next" push → present cover
    │                                               │
    │                                               └─► .fullScreenCover ──► OnboardingPreviewView
    │                                                                             │
    │                                                                             ├─ reads AnalysisStore.results
    │                                                                             ├─ reads ScheduleStore.cachedResult
    │                                                                             ├─ "See full analysis" ──► NavigationLink → AnalysisView
    │                                                                             └─ "See What You're Getting" ──► .fullScreenCover(PaywallPlaceholderView)
    │                                                                                                                     │
    │                                                                                                                     └─ "Start Free Trial" CTA
    │                                                                                                                           │
    │                                                                                                                           ▼
    │                                                                                              UserProfileStore.markOnboarded()
    │                                                                                              AppState.onboardingComplete = true
    │
    └─ appState.onboardingComplete == true ──► TabView (Stack / Today / Schedule)
```

### Recommended Project Structure

```
StackWise/Features/Onboarding/
├── OnboardingCoordinatorView.swift    # New — NavigationStack + smart resume
├── HealthProfileView.swift            # Existing — Step 1 (reused as-is)
├── StackEntryStepView.swift           # New — Step 2 wrapper (item gate)
├── ScheduleInputsView.swift           # New — Step 3 (extracted from HealthProfileView)
├── OnboardingPreviewView.swift        # New — Step 4 (summary card)
└── PaywallPlaceholderView.swift       # New — Wireframe paywall
```

Existing files modified:
- `StackWise/ContentView.swift` — add onboarding gate
- `StackWise/Features/Onboarding/HealthProfileView.swift` — remove schedule section (extracted to ScheduleInputsView) and remove `markOnboarded` call (coordinator calls it)

### Pattern 1: NavigationStack Coordinator with Path Enum

**What:** A coordinator view owns a `NavigationPath` (or typed enum path). Step views are pushed programmatically. Back arrow is free because NavigationStack manages it.

**When to use:** Any linear multi-step flow where steps are pushes and the data entry model (form-based) requires back-and-forth revision.

**Key iOS 17 constraint:** Do not mix `NavigationLink` declarative destinations with programmatic path manipulation on the same stack — they fight for path ownership. Use one or the other. For this phase: use the programmatic path everywhere since smart resume requires setting an initial path. [CITED: Advanced NavigationStack Patterns — buczel.com/blog/swift-navigation-stack-patterns]

```swift
// Source: NavigationStack programmatic coordinator pattern [ASSUMED — SwiftUI standard]
enum OnboardingStep: Hashable {
    case healthProfile
    case stackEntry
    case scheduleInputs
}

@Observable
final class OnboardingCoordinator {
    var path: [OnboardingStep] = []
    var showPreview: Bool = false
    var showPaywall: Bool = false

    func resumePoint(profile: UserProfile?, itemCount: Int) -> [OnboardingStep] {
        guard let profile, profile.age > 0, profile.weightKg > 0 else { return [] }
        guard itemCount > 0 else { return [.healthProfile, .stackEntry] }
        guard profile.wakeTime != nil else { return [.healthProfile, .stackEntry, .scheduleInputs] }
        return [.healthProfile, .stackEntry, .scheduleInputs]  // will trigger showPreview = true
    }
}

struct OnboardingCoordinatorView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(\.managedObjectContext) private var context
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding(
            get: { coordinator.path },
            set: { coordinator.path = $0 }
        )) {
            HealthProfileView(onNext: { coordinator.path.append(.stackEntry) })
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .healthProfile: HealthProfileView(onNext: { coordinator.path.append(.stackEntry) })
                    case .stackEntry: StackEntryStepView(onNext: { coordinator.path.append(.scheduleInputs) })
                    case .scheduleInputs: ScheduleInputsView(onNext: { coordinator.showPreview = true })
                    }
                }
        }
        .fullScreenCover(isPresented: $coordinator.showPreview) {
            OnboardingPreviewView(
                onStartTrial: { coordinator.showPaywall = true }
            )
            .fullScreenCover(isPresented: $coordinator.showPaywall) {
                PaywallPlaceholderView(onComplete: {
                    completeOnboarding()
                })
                .interactiveDismissDisabled(true)
            }
        }
        .task { applySmartResume() }
    }

    private func completeOnboarding() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        UserProfileStore.markOnboarded(profile, in: context)
        appState.onboardingComplete = true
    }
}
```

> Note: The actual coordinator can be simpler — an `@Observable` class is optional. Since this is a one-time linear flow with no deep-linking requirement, `@State var path: [OnboardingStep]` directly on the coordinator view is sufficient.

### Pattern 2: One-Way Gate via fullScreenCover + interactiveDismissDisabled

**What:** Present the preview screen as `.fullScreenCover` from the coordinator. Set `.interactiveDismissDisabled(true)` on the paywall. This makes back-swipe structurally impossible without any UIKit hacks.

**Why not push step 4 onto the NavigationStack?** Pushing step 4 would leave the back arrow active to step 3 (the schedule inputs), allowing users to skip the paywall. Using fullScreenCover removes the navigation bar entirely and the coordinator controls dismissal explicitly.

**The iOS 17 behavior:** NavigationStack + fullScreenCover works correctly in iOS 17+. The previously reported bug (navigation push animation breaks after fullScreenCover) was an iOS 16 issue. [CITED: github.com/pointfreeco/swift-composable-architecture/issues/3833]

```swift
// Source: Apple Developer Documentation — fullScreenCover(isPresented:) [CITED]
.fullScreenCover(isPresented: $showPreview) {
    OnboardingPreviewView(...)
        .interactiveDismissDisabled(true)  // no bottom-swipe dismiss
}
```

### Pattern 3: Smart Resume Detection (Core Data State Inference)

**What:** On `.task` in the coordinator, fetch UserProfile and StackItem count, then compute the correct initial path from Core Data state.

**Implementation:** D-07 maps exactly to a switch on four observable Core Data states.

```swift
// Source: Codebase — UserProfileStore.fetchOrCreate pattern [VERIFIED: codebase]
private func applySmartResume() {
    let profile = UserProfileStore.fetchOrCreate(in: context)
    let itemRequest = StackItem.fetchRequest()
    itemRequest.predicate = NSPredicate(format: "isActive == YES")
    let itemCount = (try? context.count(for: itemRequest)) ?? 0

    // D-07 resume logic
    if profile.age == 0 || profile.weightKg == 0 {
        // Step 1: no health profile data
        coordinator.path = []
    } else if itemCount == 0 {
        // Step 2: profile filled, no stack items
        coordinator.path = [.healthProfile, .stackEntry]
    } else if profile.wakeTime == nil {
        // Step 3: items exist, no schedule set
        coordinator.path = [.healthProfile, .stackEntry, .scheduleInputs]
    } else {
        // Step 4: all data present, go directly to preview
        coordinator.path = [.healthProfile, .stackEntry, .scheduleInputs]
        coordinator.showPreview = true
    }
}
```

**Edge case — wakeTime default:** `HealthProfileView` currently sets `wakeTime` default to `Self.defaultTime(hour: 7)` in `@State`. If the view was never saved (crash before "Save"), `UserProfile.wakeTime` remains `nil` in Core Data. This is the correct "not yet saved" signal. However, if the user completes step 1 (which currently saves ALL fields including wakeTime), they will never land on step 3 again via resume. The coordinator must **not** rely on `wakeTime` being nil after step 1 is saved. The UI-SPEC's resume condition ("wakeTime is nil or default-untouched") needs a more reliable signal.

**Recommended resolution:** After step 1 save, the coordinator saves only the personal fields (age, sex, weight, allergies, conditions) but NOT wakeTime. Step 3 saves wakeTime. This requires splitting `HealthProfileView.save()` so it no longer saves schedule times — the schedule save moves to `ScheduleInputsView`. [VERIFIED: HealthProfileView.swift line 70–84 — current save() writes all fields including wakeTime]

### Pattern 4: HealthProfileView Refactor (Required)

**What:** `HealthProfileView` currently does two things in one view: (1) collects personal data and (2) collects schedule times. It also currently calls `UserProfileStore.markOnboarded()` in `save()` — which would fire REQ-19 at step 1, not at the paywall.

**This is the most important code surgery in Phase 5.** The existing `HealthProfileView.save()` sets `onboardingComplete = true` via `markOnboarded`. This will conflict with the coordinator's gate unless it is removed.

**Required changes to HealthProfileView:**
1. Remove the `Section("Schedule")` DatePicker block → moves to `ScheduleInputsView`
2. Remove the call to `UserProfileStore.markOnboarded()` in `save()` — the coordinator handles completion
3. The `save()` function writes personal fields only (age, sex, weight, allergies, conditions)
4. Remove the `NavigationStack` wrapper (the coordinator provides its own NavigationStack)
5. Remove `.interactiveDismissDisabled(true)` — the coordinator handles this
6. Add an `onNext: () -> Void` closure parameter to signal the coordinator to push step 2

[VERIFIED: HealthProfileView.swift lines 44–48 (schedule section), 70–84 (save function with markOnboarded)]

### Pattern 5: ContentView Gate

**What:** ContentView already reads `appState.onboardingComplete` from Core Data on `.task`. The gate is a simple conditional:

```swift
// Required ContentView modification [VERIFIED: ContentView.swift]
var body: some View {
    if appState.onboardingComplete {
        TabView { ... }
    } else {
        OnboardingCoordinatorView()
    }
}
```

The existing `.sheet(isPresented:)` that presents `HealthProfileView` must be removed — it is replaced by the full-screen `OnboardingCoordinatorView`. [VERIFIED: ContentView.swift lines 31–36]

### Anti-Patterns to Avoid

- **Pushing step 4 onto the NavigationStack:** This leaves the back arrow active to step 3, allowing paywall bypass. Always present the preview as `.fullScreenCover`.
- **Storing navigation step as an enum in Core Data:** D-07 explicitly rejects an explicit cursor field. Use entity state inference only.
- **Using NavigationLink declarative destinations AND path manipulation on the same stack:** These fight for path ownership in iOS 17. Use one pattern. [CITED: buczel.com/blog/swift-navigation-stack-patterns]
- **Calling `UserProfileStore.markOnboarded()` from HealthProfileView:** Would fire REQ-19 at step 1 instead of the paywall. Must be removed from HealthProfileView.save().
- **Hiding back button with .navigationBarBackButtonHidden on the NavigationStack steps:** Not needed — back navigation is allowed for steps 1–3. Only the paywall needs `interactiveDismissDisabled(true)`.
- **Setting `navigationBarBackButtonHidden` on step 4:** Step 4 is a fullScreenCover — it has no NavigationStack back button by default. No code needed.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Trial write guard (REQ-19) | Custom idempotency logic | `UserProfileStore.markOnboarded()` — already has `if profile.trialStartDate == nil` guard | Already implemented and tested in `UserProfileStoreTests.testMarkOnboardedFlipsFlagAndPersists` |
| Step-minimum button disable | Complex item-count observer | `@FetchRequest` count + `.disabled(items.isEmpty)` | FetchRequest is live-updating; no manual observation needed |
| One-way navigation gate | Custom UINavigationController subclass | `.fullScreenCover` + `.interactiveDismissDisabled(true)` | Standard SwiftUI — no UIKit bridge needed |
| Core Data singleton fetch | Custom fetch-or-insert pattern | `UserProfileStore.fetchOrCreate(in:)` | Already implemented, tested, and used throughout the app |
| In-memory analysis count for preview | New data fetch | `analysisStore.currentResults()` | Already computed and cached; returns `AnalysisResults` with `.critical.count` |
| In-memory schedule count for preview | New schedule fetch | `scheduleStore.currentSchedule()` | Already computed; returns `ScheduleResult` with `.blockCount` or similar |

**Key insight:** Phase 5 introduces zero new data layer components. Every piece of data the preview screen needs is already computed by existing stores. The coordinator's job is sequencing and presenting, not computing.

---

## Common Pitfalls

### Pitfall 1: HealthProfileView Already Fires the Onboarding Trigger
**What goes wrong:** HealthProfileView.save() calls `UserProfileStore.markOnboarded()`, which sets `onboardingComplete = true` and writes `trialStartDate`. If the coordinator wraps this view unchanged, REQ-19 will fire at step 1 instead of the paywall, and ContentView will switch to TabView after step 1 completes.
**Why it happens:** HealthProfileView was the original onboarding screen before Phase 5 introduced a coordinator.
**How to avoid:** Remove `UserProfileStore.markOnboarded()` from HealthProfileView.save() as the first task. Replace with a plain Core Data save of personal fields only.
**Warning signs:** If the simulator switches to TabView after completing step 1, the markOnboarded call was not removed.
[VERIFIED: HealthProfileView.swift lines 80–83]

### Pitfall 2: wakeTime Is Written in Step 1 (Current Behavior)
**What goes wrong:** HealthProfileView.save() currently writes ALL fields including wakeTime, sleepTime, breakfastTime, etc. If these are written at step 1, the D-07 resume condition "wakeTime is nil → go to step 3" will never be true after step 1 is completed.
**Why it happens:** Schedule inputs lived in HealthProfileView before the step split.
**How to avoid:** Step 1 save writes only personal fields (age, sex, weight, allergies, conditions). Step 3's ScheduleInputsView.save() writes the time fields. This is a hard requirement for resume detection to work correctly.
**Warning signs:** After completing step 1 and force-quitting the app, relaunch skips step 3.
[VERIFIED: HealthProfileView.swift line 77 writes wakeTime in same save()]

### Pitfall 3: ContentView .sheet Conflict
**What goes wrong:** ContentView currently presents a `.sheet(isPresented: Binding(get: { !appState.onboardingComplete }...))` showing HealthProfileView. If the gate is not replaced, both the sheet and the OnboardingCoordinatorView will compete for presentation.
**Why it happens:** The sheet was the Phase 1 placeholder for the onboarding flow.
**How to avoid:** Remove the `.sheet` modifier from ContentView entirely. Replace with `if appState.onboardingComplete { TabView } else { OnboardingCoordinatorView() }`.
**Warning signs:** Onboarding appears twice, or the sheet appears on top of the coordinator.
[VERIFIED: ContentView.swift lines 31–36]

### Pitfall 4: AnalysisStore / ScheduleStore State on Preview Screen
**What goes wrong:** The preview screen reads `analysisStore.currentResults()` and `scheduleStore.currentSchedule()`. If neither has been invalidated since the user added stack items, results may be cached from a previous (pre-stack) state, showing "0 interactions" incorrectly.
**Why it happens:** Dirty-flag recompute only triggers after `invalidate()` is called, which happens on stack mutations via `StackItemFactory`. If items were added within the onboarding flow and the stores were not invalidated afterward, the preview will show stale zeros.
**How to avoid:** `StackItemFactory.create()` already calls `analysisStore.invalidate()` and `scheduleStore.invalidate()` in the `onSaved` callback. Confirm this callback fires correctly within the onboarding context (stores are in environment via StackWiseApp — they will be available). No additional action needed if environments are threaded through correctly.
**Warning signs:** Preview shows "0 critical interactions found" even when items with known interactions exist in the stack.
[VERIFIED: StackItemFactory.swift line 35; StackWiseApp.swift environment injection]

### Pitfall 5: NavigationStack Inside fullScreenCover Navigation Breaks
**What goes wrong:** If `OnboardingPreviewView` (presented via fullScreenCover) contains a `NavigationLink` to `AnalysisView` without its own `NavigationStack`, the push will fail silently.
**Why it happens:** fullScreenCover severs the parent NavigationStack context. A NavigationLink inside a fullScreenCover has no stack to push onto.
**How to avoid:** Wrap the fullScreenCover content in its own `NavigationStack`, or use a sheet for the "See full analysis" push instead of a NavigationLink.
**Recommended:** Wrap `OnboardingPreviewView` in a `NavigationStack` so the "See full analysis" push works correctly.
[CITED: Apple Developer Documentation — NavigationStack context scoping; ASSUMED pattern]

### Pitfall 6: Back-Swipe Disabling Not Needed (Common Misimplementation)
**What goes wrong:** Developers add `.navigationBarBackButtonHidden()` to step 4 to prevent back navigation, then need to add UIKit gesture recognizer hacks to restore swipe. This creates unnecessary complexity.
**Why it happens:** Misunderstanding of the one-way gate mechanism.
**How to avoid:** Step 4 is a `.fullScreenCover`, not a pushed view. It has no NavigationStack back button and no swipe-back gesture by default. No `.navigationBarBackButtonHidden()` needed. The only required modifier is `.interactiveDismissDisabled(true)` on the PaywallPlaceholderView.
[CITED: SwiftUI fullScreenCover documentation — no navigation bar by default]

---

## Paywall Placeholder Structural Requirements

The Phase 5 placeholder must preserve structural zones that Phase 7's RevenueCat integration will populate. Understanding Phase 7 constraints now prevents rework.

### What Phase 7 Needs from Phase 5

Phase 7 will introduce RevenueCat (confirmed by REQUIREMENTS.md REQ-22 language "entitlement verification"). RevenueCat's `PaywallView` requires:
1. RevenueCat SDK initialized with API key
2. At least one Offering configured in RevenueCat dashboard
3. StoreKit products configured in App Store Connect
4. `RevenueCatUI` package (5.27.1+, iOS 15+)

**None of these will exist in Phase 5.** Therefore:

Phase 5's `PaywallPlaceholderView` must NOT use `RevenueCatUI.PaywallView`. It is a pure SwiftUI placeholder with hardcoded zone labels.

### Structural Zones (D-11)

Phase 7 will replace each zone's content. The placeholder establishes the scaffold:

```swift
// PaywallPlaceholderView — wireframe skeleton [ASSUMED structure based on D-11]
struct PaywallPlaceholderView: View {
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Zone 1: Hero / value prop
                // Phase 7 will replace with: hero image, headline, subheadline
                Text("[Hero / value prop zone]").font(.swTitle2)

                // Zone 2: Social proof
                // Phase 7 will replace with: review stars, quote, attribution
                Text("[Social proof zone]").font(.swBody)

                // Zone 3: Pricing
                // Phase 7 will replace with: ProductView / SubscriptionStoreView or RevenueCat offering
                Text("14-day free trial, then $4.99/month").font(.swBody)

                // Zone 4: CTA
                // Phase 7 will replace button action with RevenueCat purchase flow
                VStack(spacing: 12) {
                    Button("Start Free Trial") { onComplete() }
                        .buttonStyle(PrimaryButtonStyle())

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

**Zone integrity rule:** Each zone should be a separate `VStack` or `Group` with a clear comment boundary. Phase 7 replaces content within each zone without structural changes.

**The "Start Free Trial" CTA in Phase 5** calls `onComplete()` directly (no StoreKit). Phase 7 wraps this with `Task { try await Purchases.shared.purchase(package:) }`. The zone scaffold survives unchanged.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) |
| Config file | None — Xcode target StackWiseTests |
| Quick run command | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StackWiseTests` |
| Full suite command | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File | Exists? |
|--------|----------|-----------|------|---------|
| REQ-18 (resume step 1) | No UserProfile → coordinator starts at step 1 | Unit | `OnboardingCoordinatorTests.swift` | Wave 0 |
| REQ-18 (resume step 2) | Profile filled, 0 items → coordinator starts at step 2 | Unit | `OnboardingCoordinatorTests.swift` | Wave 0 |
| REQ-18 (resume step 3) | Items exist, wakeTime nil → step 3 | Unit | `OnboardingCoordinatorTests.swift` | Wave 0 |
| REQ-18 (resume step 4) | All data, onboardingComplete false → preview shown | Unit | `OnboardingCoordinatorTests.swift` | Wave 0 |
| REQ-18 (item gate) | 0 items → Next button disabled (StackEntryStepView) | Unit | `OnboardingCoordinatorTests.swift` | Wave 0 |
| REQ-19 (once only) | trialStartDate already set → markOnboarded is no-op for date | Unit | `UserProfileStoreTests.swift` | Exists (testMarkOnboardedFlipsFlagAndPersists) |
| REQ-19 (write on complete) | completeOnboarding() writes trialStartDate + sets onboardingComplete | Unit | `OnboardingCoordinatorTests.swift` | Wave 0 |
| ContentView gate | appState.onboardingComplete = false → coordinator shown; true → TabView | Manual (simulator) | — | Manual UAT |

**What is testable in pure unit tests (no UI, no simulator):**
- `OnboardingCoordinator.resumePoint(profile:itemCount:)` → returns correct `[OnboardingStep]`
- `completeOnboarding()` logic → UserProfile.trialStartDate written, onboardingComplete set
- All four resume detection branches
- REQ-19 idempotency (already tested in UserProfileStoreTests)

**What is not unit-testable:**
- Visual rendering of the coordinator (manual/Xcode preview)
- fullScreenCover presentation (UI test or manual)
- "See full analysis" NavigationLink push (manual)

### Sampling Rate
- **Per task commit:** Run `StackWiseTests/OnboardingCoordinatorTests.swift` + `StackWiseTests/UserProfileStoreTests.swift`
- **Per wave merge:** Full test suite (all 50 existing + new onboarding tests)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `StackWiseTests/OnboardingCoordinatorTests.swift` — covers REQ-18 resume branches and REQ-19 write logic
- The existing `UserProfileStoreTests.testMarkOnboardedFlipsFlagAndPersists` already covers the REQ-19 idempotency case and will continue to pass without modification

---

## Security Domain

`security_enforcement: true` in config.json; `security_asvs_level: 1` (ASVS Level 1).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Paywall is local trial trigger — no auth |
| V3 Session Management | No | Onboarding is a one-shot local flow |
| V4 Access Control | Yes (minor) | `onboardingComplete` gate in ContentView prevents tab access; enforced in-memory + Core Data |
| V5 Input Validation | Yes | HealthProfileView form fields (age, weight, text inputs); existing `canSave` guard already enforces `age > 0 && weightKg > 0`; schedule inputs are DatePickers (no free-text) |
| V6 Cryptography | No | No sensitive data encrypted; all data stored on-device in Core Data (iOS sandbox enforces confidentiality) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Bypassing onboarding gate | Elevation of Privilege | `onboardingComplete` read from Core Data at app launch (not just memory); cannot be set without Core Data write |
| Firing trial trigger twice | Tampering | `if profile.trialStartDate == nil` guard in `UserProfileStore.markOnboarded()` — already implemented |
| Injecting malformed health input | Tampering | All fields are typed (Int16, Double, DatePicker) — no SQL injection surface; allergies/conditions are free-text stored as `[String]` via NSSecureUnarchiveFromData transformable |

**No new security surface introduced.** Phase 5 adds no network calls, no user authentication, and no new data at rest beyond what Core Data already manages.

---

## Open Questions

1. **ScheduleInputsView extraction approach**
   - What we know: `HealthProfileView` contains the schedule DatePickers; step 3 needs them as a separate screen
   - What's unclear: Whether to (a) extract into a new `ScheduleInputsView` that creates its own `@State` bindings and saves directly to Core Data, or (b) pass bindings down from the coordinator
   - Recommendation: Option (a) — `ScheduleInputsView` is self-contained, reads from Core Data on `onAppear` (pre-populate if previously saved), and saves on "Next". Same pattern as `HealthProfileView`. No binding threading required.

2. **HealthProfileView onNext callback vs toolbar Save button**
   - What we know: HealthProfileView currently has a "Save" toolbar button that writes and flips onboardingComplete
   - What's unclear: Whether to keep "Save" and use `.onReceive` to detect the save, or replace with "Next" button
   - Recommendation: Replace "Save" label with "Next" in the coordinator context. Pass `onNext: () -> Void` as a parameter; the button calls `save()` then `onNext()`. The view stays reusable (it can accept a nil onNext for the non-coordinator context if ever needed).

3. **Preview screen invalidation timing**
   - What we know: `analysisStore.invalidate()` is called from `StackItemFactory.create()` via the `onSaved` callback; stores use dirty-flag lazy recompute
   - What's unclear: Whether the stores are definitely recomputed before `OnboardingPreviewView` renders its counts, given that `currentResults()` triggers recompute on first read
   - Recommendation: Call `analysisStore.currentResults()` explicitly in `OnboardingPreviewView.onAppear` or use a `.task` — this forces recompute synchronously on the main actor before the view draws. Since both stores are `@MainActor @Observable`, this is safe.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 5 is purely code/SwiftUI changes with no new external dependencies. No CLI tools, services, databases, or runtimes beyond the existing Xcode + iOS Simulator stack are introduced.

---

## Runtime State Inventory

Step 2.5: SKIPPED — Phase 5 is not a rename/refactor/migration phase. No stored data, live service config, OS-registered state, secrets, or build artifacts are being renamed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SuperwallKit is not the Phase 7 choice; RevenueCat is implied by REQUIREMENTS.md REQ-22 language | Library Evaluation | Low — D-12 defers StoreKit entirely to Phase 7; Phase 5 placeholder is custom regardless of Phase 7 choice |
| A2 | `OnboardingPreviewView` needs its own `NavigationStack` wrapper to support the "See full analysis" NavigationLink push | Common Pitfalls / Architecture | Medium — if wrong, "See full analysis" push silently fails in simulator; caught immediately in manual verification |
| A3 | `ScheduleInputsView` should be a self-contained view with its own `@State` bindings (option a) rather than receiving bindings from the coordinator | Open Questions | Low — either approach works; self-contained is simpler and follows existing HealthProfileView pattern |

**Three assumptions total. All are LOW-MEDIUM risk and will be caught during simulator verification.**

---

## Sources

### Primary (HIGH confidence)
- `StackWise/Features/Onboarding/HealthProfileView.swift` — confirmed schedule inputs + markOnboarded in save()
- `StackWise/ContentView.swift` — confirmed .sheet conflict requiring removal
- `StackWise/Models/UserProfileStore.swift` — confirmed trialStartDate nil-guard exists
- `StackWise/Models/UserProfile+CoreDataClass.swift` — confirmed all required fields present (onboardingComplete, trialStartDate)
- `StackWise/StackWiseApp.swift` — confirmed environment injection pattern
- `.planning/phases/05-functional-onboarding/05-CONTEXT.md` — all decisions verified
- `.planning/phases/05-functional-onboarding/05-UI-SPEC.md` — screen inventory, interaction contracts, copywriting

### Secondary (MEDIUM confidence)
- [airbnb/lottie-ios Discussion #1807](https://github.com/airbnb/lottie-ios/discussions/1807) — lottie-spm binary size (~500KB vs 300MB); VERIFIED against maintainer response
- [RevenueCat Paywalls Documentation](https://www.revenuecat.com/docs/tools/paywalls) — PaywallView requires SDK init + offerings config; iOS 15+ minimum
- [Advanced NavigationStack Patterns — Kamil Buczel](https://buczel.com/blog/swift-navigation-stack-patterns) — programmatic path vs declarative NavigationLink conflict
- [pointfreeco/swift-composable-architecture Issue #3833](https://github.com/pointfreeco/swift-composable-architecture/issues/3833) — iOS 17 fixes NavigationStack + fullScreenCover push animation bug

### Tertiary (LOW confidence — informational only)
- [ConcentricOnboarding — Swift Package Index](https://swiftpackageindex.com/exyte/ConcentricOnboarding) — v1.1.1, zero dependencies; evaluated and rejected

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all existing dependencies verified in codebase; no new libraries required
- Architecture: HIGH — patterns derived from verified codebase inspection + Apple documentation
- Library evaluation: HIGH — size figures verified via GitHub maintainer; RevenueCat requirements verified via official docs
- Pitfalls: HIGH — pitfalls 1–4 derived from direct codebase inspection; pitfalls 5–6 derived from documentation

**Research date:** 2026-05-25
**Valid until:** 2026-08-25 (stable SwiftUI APIs; lottie version may change but evaluation verdict will not)
