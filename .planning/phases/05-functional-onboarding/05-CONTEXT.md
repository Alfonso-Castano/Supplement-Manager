# Phase 5: Functional Onboarding - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Sequence existing screens into a working onboarding coordinator: health profile → stack entry → schedule inputs → preview screen. Wire the trial start trigger to fire exactly once at onboarding completion. Main app tabs hidden until `onboardingComplete` is set. Creating individual screens and the subscription payment flow are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Navigation Style
- **D-01:** NavigationStack for steps 1–3 (health profile, stack entry, schedule inputs) — back arrow active, user can revise earlier data freely
- **D-02:** Preview screen onward is a one-way gate — once "Start Free Trial" is tapped, no back navigation
- **D-03:** No global step indicator across the full onboarding sequence; phase-scoped progress indicators (e.g. dots within health profile sub-task) are acceptable

### Preview Screen
- **D-04:** Hybrid layout — summary card leading with headline counts ("2 critical interactions found", "Your 3-block schedule is ready") + "See full analysis" affordance that expands or pushes to the existing AnalysisView
- **D-05:** Explicit "Start Free Trial" CTA on the preview screen; tapping it navigates to the paywall placeholder screen (does not fire the trigger directly)
- **D-06:** Reusing AnalysisView + ScheduleView as-is (without conversion framing) is ruled out — the preview screen needs value-prop structure before the paywall

### Mid-Onboarding Crash Recovery
- **D-07:** Smart partial resume on relaunch — infer step from Core Data entity state, no explicit cursor field needed
  - No UserProfile data → start at health profile (step 1)
  - UserProfile filled, zero StackItems → start at stack entry (step 2)
  - StackItems exist, wake/meal times empty → start at schedule inputs (step 3)
  - All data present, `onboardingComplete = false` → go directly to preview (step 4)

### Empty Stack Behavior
- **D-08:** Hard minimum of 1 StackItem required before advancing from stack entry; Next button disabled until count > 0
- **D-09:** Inline copy when disabled: "Add your supplements to see how they interact and get your personalized schedule"

### Notification Permission
- **D-10:** Notification permission is entirely outside the Phase 5 onboarding flow — Phase 6 owns a value-framing screen + UNUserNotificationCenter request on first main app launch post-trial-start; Phase 5 does not reserve a slot for this in the coordinator

### Paywall Placeholder Screen
- **D-11:** Phase 5 builds a wireframe paywall with 4 structural zones (stubbed content, no real copy or design):
  1. Hero / value prop zone
  2. Social proof zone
  3. Pricing zone ("14-day free trial, $X/month after")
  4. CTA zone ("Start Free Trial" button that writes `trialStartDate` + sets `onboardingComplete = true`; "Restore Purchases" link)
- **D-12:** Trial mechanism is Apple's native StoreKit flow (likely RevenueCat in Phase 7); Phase 5 placeholder fires the trigger directly without StoreKit integration
- **D-13:** REQ-19 (trigger fires exactly once) is enforced by checking `trialStartDate == nil` before writing

### Claude's Discretion
- Exact animation/transition between onboarding steps
- Error state handling within individual steps (e.g., form validation copy)
- Exact visual layout of the summary card counts on the preview screen (design workflow handles this in Phase 7)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §REQ-18, REQ-19 — Onboarding coordinator sequence and trial trigger requirements (locked)

### Project Spec
- `SPEC.md` — Full project specification; onboarding section defines expected coordinator behavior and UserProfile fields

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StackWise/Features/Onboarding/HealthProfileView.swift` — Step 1 screen already exists; coordinator wraps it
- `StackWise/Features/Stack/AddItemView.swift` — Used for stack entry step; existing add-item flow
- `StackWise/Features/Stack/StackListView.swift` — May be embedded in the stack entry step for review before advancing
- `StackWise/Analysis/AnalysisView.swift` — Pushed from "See full analysis" on preview screen
- `StackWise/Analysis/AnalysisStore.swift` — Available for preview summary counts (critical/advisory/synergy)
- `StackWise/Schedule/ScheduleStore.swift` — Available for preview "schedule ready" count
- `StackWise/Features/Stack/StackItemFactory.swift` — Coordinates item adds; already calls `analysisStore.invalidate()`

### Established Patterns
- `@Observable` + `.environment()` only — no `ObservableObject`/`@Published` (Phase 1 lock)
- Dirty-flag invalidation pattern: `analysisStore.invalidate()` and `scheduleStore.invalidate()` called on stack mutations (Phase 3/4 pattern)
- Core Data singleton: `UserProfile` is the single persistent source of truth for user state
- `AppState.swift` — already has `onboardingComplete` flag that mirrors Core Data at launch

### Integration Points
- `ContentView.swift` — 3-tab shell; needs onboarding gate: `if appState.onboardingComplete { TabView } else { OnboardingCoordinatorView }`
- `UserProfile.onboardingComplete` (Core Data) — set to true when paywall placeholder fires the trigger
- `AppState.onboardingComplete` — must be updated in sync with Core Data after trigger fires
- `UserProfile.trialStartDate` — written exactly once by the paywall placeholder CTA; nil-guard enforces REQ-19

</code_context>

<specifics>
## Specific Ideas

- Preview screen summary card: "2 critical interactions found" + "Your 3-block schedule is ready" as headline stats — full detail behind "See full analysis" push
- Onboarding research framing: sunk-cost psychology — by preview, user has invested real data, so one-way gate feels natural not restrictive
- Paywall zone structure established in Phase 5 gives the design workflow a structural brief rather than a blank canvas
- Trial framing: 14-day free, then auto-billed via StoreKit; no manual card entry; Face ID/Touch ID confirmation (Phase 7 implementation detail)

</specifics>

<deferred>
## Deferred Ideas

- Notification permission value-framing screen — Phase 6 (first main app launch post-trial-start, outside coordinator)
- StoreKit 2 / RevenueCat integration and real paywall design — Phase 7
- Full paywall visual design (hero image, social proof copy, real pricing) — design workflow before Phase 7
- Onboarding redesign based on user feedback — explicitly post-launch per REQUIREMENTS.md

</deferred>

---

*Phase: 05-functional-onboarding*
*Context gathered: 2026-05-25*
