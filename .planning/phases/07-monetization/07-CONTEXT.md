# Phase 7: Monetization - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement StoreKit 2 subscription with 14-day free trial, trial expiry check on cold launch, hard paywall gate for expired/lapsed subscriptions, and restore purchases flow. Products: $4.99/month and $35/year. No RevenueCat for v1. Feedback forms, dark mode, and App Store submission are separate phases.

</domain>

<decisions>
## Implementation Decisions

### StoreKit Integration
- **D-01:** Native StoreKit 2 only — no RevenueCat SDK, no third-party dependency. Uses Apple's async/await StoreKit 2 API with App Store Connect for product configuration. RevenueCat may be layered in post-launch once there are real paying users and analytics become valuable.

### Paywall Gate Architecture
- **D-02:** ContentView 3rd gate pattern — same architecture as onboarding and notification permission gates. Gate chain: `onboardingComplete` → `notificationPermissionShown` → subscription check → TabView. If trial expired and not subscribed, ContentView renders `PaywallView` instead of the TabView. `interactiveDismissDisabled(true)` — true hard block.
- **D-11:** `"unknown"` subscription status → **fail open** (allow access to TabView). Gate only blocks on `"expired"`. StoreKit occasionally returns unknown on first launch or poor connectivity; blocking on unknown would lock legitimate paying users out.

### In-Trial UX
- **D-03:** Silent trial — no countdown, no banners, no persistent indicators anywhere in the app during days 1–14. The app experience is identical to a paid subscription during the trial period. The hard paywall gate is a fallback for cancelled, failed, or lapsed subscriptions — users who auto-renew never encounter it.

### Trial Expiry and Status Check
- **D-05:** PaywallView appears directly on cold launch when trial is expired — no intermediate "Your trial has ended" interstitial screen. The PaywallView headline communicates the situation.
- **D-06:** Subscription status checked in ContentView `.task` on cold launch only. No mid-session or foreground checks. No background tasks (BGAppRefreshTask) needed.
- **D-09:** `subscriptionStatus` string values: `"trial"` | `"active"` | `"expired"` | `"unknown"`. Stored in `UserProfile.subscriptionStatus` (Core Data) and mirrored in `AppState.subscriptionStatus`. `UserProfileStore` is the only writer.
- **D-10:** `trialStartDate` is set exactly once in `UserProfileStore.markOnboarded` (already guarded by `if profile.trialStartDate == nil`) and never overwritten. Expiry check is always `trialStartDate + 14 days` compared to today's date. No re-install or data quirk can reset the trial clock.

### Pricing Plan Layout
- **D-04:** Two stacked cards — monthly card + annual card stacked vertically. Annual card pre-selected by default with a "Best Value" badge. Annual card displays both effective monthly rate ($2.92/mo) and total price ($35/year) prominently. Monthly card at $4.99/month serves as the price anchor to make the annual plan feel like an obvious deal. Monthly conversions are not the goal.

### Restore Purchases
- **D-07:** "Restore Purchases" button lives on the PaywallView only (already stubbed in `PaywallPlaceholderView`). Satisfies App Store Review requirement with minimal complexity. Settings screen is a future phase.
- **D-08:** During restore: button shows `ProgressView`, all other interactive elements disabled. On success: `subscriptionStatus` updated to `"active"`, `AppState.subscriptionStatus` mirrors it, ContentView gate re-evaluates automatically — PaywallView disappears and TabView appears without an alert or extra tap. On failure: brief non-blocking error state on the restore button.

### Claude's Discretion
- Exact paywall headline copy (should communicate trial status situation and value prop)
- Product ID naming convention (e.g., `com.stackwise.app.monthly`, `com.stackwise.app.annual`)
- Exact StoreKit configuration file location in Xcode
- `SubscriptionService` vs inline logic in ContentView (service preferred for testability)
- Loading state behavior in ContentView while async StoreKit check runs on first launch

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §REQ-22, REQ-23, REQ-24 — StoreKit products, trial expiry check, hard paywall requirements (locked)

### Prior Phase Context
- `.planning/phases/05-functional-onboarding/05-CONTEXT.md` — D-12: trial mechanism placeholder; `completeOnboarding()` flow
- `.planning/phases/06-reminders-today-tab/06-CONTEXT.md` — ContentView gate pattern established here; D-03 (notificationPermissionShown flag); Phase 7 adds a third gate after notification

### Existing Code — Key Files
- `StackWise/ContentView.swift` — Current 2-gate chain; Phase 7 inserts subscription check as 3rd gate
- `StackWise/Features/Onboarding/PaywallPlaceholderView.swift` — 4-zone placeholder; Phase 7 replaces with real StoreKit implementation
- `StackWise/Features/Onboarding/OnboardingCoordinatorView.swift` — Shows PaywallPlaceholderView as fullScreenCover during onboarding; this is the initial trial sign-up (separate from the hard paywall gate in ContentView)
- `StackWise/Models/UserProfile+CoreDataClass.swift` — Already has `trialStartDate: Date?` and `subscriptionStatus: String?`
- `StackWise/Models/AppState.swift` — Already has `subscriptionStatus: String = "unknown"`
- `StackWise/Models/UserProfileStore.swift` — `markOnboarded` already guards `trialStartDate == nil` and sets it once

### Project Spec
- `SPEC.md` — Full project specification

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StackWise/Features/Onboarding/PaywallPlaceholderView.swift` — Phase 7 implementation target. Has `onComplete: () -> Void` callback, "Restore Purchases" button stub, and 4 zones with MARK comments ready for replacement.
- `StackWise/Models/AppState.swift` — `subscriptionStatus: String` already exists; Phase 7 drives the ContentView gate from this property.
- `StackWise/ContentView.swift` — Established gate chain with Group{} + if/else pattern; Phase 7 adds one more `if` branch.

### Established Patterns
- `@Observable` + `.environment()` only — no `ObservableObject`/`@Published`
- ContentView gate pattern: `if condition { ViewA } else { ViewB }` — same pattern for subscription gate
- `@AppStorage` for simple boolean flags; `UserProfileStore.fetchOrCreate` is the only UserProfile writer
- `UserProfileStore` enum is the only valid UserProfile writer — subscription status updates must go through it or a new parallel service that saves to the same context

### Integration Points
- `StackWise/ContentView.swift` — Add 3rd gate after `notificationPermissionShown` check; drive from `appState.subscriptionStatus`
- `StackWise/StackWiseApp.swift` — Good place to run async StoreKit product fetch on launch; inject into environment
- `StackWise/Models/AppState.swift` — No new properties needed; `subscriptionStatus` already present
- `StackWise/Features/Onboarding/PaywallPlaceholderView.swift` — Replace Zone 3 with StoreKit `Product.products(for:)` loaded cards; Zone 4 CTA wires to `Product.purchase()`

</code_context>

<specifics>
## Specific Ideas

- Annual card anchoring strategy: $2.92/mo shown prominently next to $35/year — the per-month comparison is the conversion driver, not the raw annual price
- Fail open on "unknown" status: legitimate paying users on poor connectivity must never be locked out
- Two paywall surfaces exist: (1) `OnboardingCoordinatorView` paywall (initial trial sign-up), (2) `ContentView` 3rd gate (expired/lapsed recovery) — these are different flows and may share the same `PaywallView` component but serve different entry points

</specifics>

<deferred>
## Deferred Ideas

- RevenueCat SDK integration — post-launch, once real subscriber analytics are needed
- Settings screen with "Restore Purchases" — Phase 9 (Polish & Ship) or post-launch
- Introductory offer variants / A/B testing — post-launch
- Grace period handling for failed renewals — v2 (StoreKit handles this automatically with billing grace period, but surfacing it in UI is post-launch)

</deferred>

---

*Phase: 07-monetization*
*Context gathered: 2026-05-29*
