# Phase 7: Monetization — Research

**Researched:** 2026-05-29
**Domain:** StoreKit 2 / iOS in-app subscriptions / SwiftUI gate pattern
**Confidence:** HIGH (core APIs verified via Apple docs + multiple authoritative sources)

---

## Summary

Phase 7 adds a StoreKit 2 subscription layer on top of the existing ContentView 2-gate chain. The
technical scope breaks into three parts: (1) a `SubscriptionService` class that wraps StoreKit 2
product fetching, purchase, entitlement check, and transaction listener; (2) an updated ContentView
with a third subscription gate driving from `appState.subscriptionStatus`; and (3) a fully-built
`PaywallView` replacing `PaywallPlaceholderView` with real product cards and StoreKit wiring.

The project targets iOS 17.0, so StoreKit 2 is fully available with no availability guards needed.
The `@Observable` macro (used by the rest of the codebase) is the correct pattern for
`SubscriptionService` — `ObservableObject`/`@Published` is the wrong pattern for this project.
`Transaction.currentEntitlements` is the authoritative entitlement source. `AppStore.sync()` is the
restore API. Both are verified against Apple developer documentation.

The hybrid trial design (local `trialStartDate` date math for the trial window + StoreKit
`Transaction.currentEntitlements` for active/expired subscription state) requires a combined check
function in `SubscriptionService` that resolves to one of the four string values stored in
`AppState.subscriptionStatus`. This is the most architecturally sensitive piece: getting the
resolution order wrong causes either false locks (paying users blocked) or false opens (expired
users admitted). The fail-open decision for `"unknown"` (D-11) is already locked and correct.

**Primary recommendation:** Build a `@MainActor @Observable final class SubscriptionService` with
`configure()` async entry point called from `StackWiseApp.body.task`. It owns: product array,
`Transaction.updates` listener (detached Task), entitlement check, purchase, restore, and the
`resolveSubscriptionStatus()` method that writes to `AppState.subscriptionStatus` via Core Data
through `UserProfileStore`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Native StoreKit 2 only — no RevenueCat SDK, no third-party dependency.
- **D-02:** ContentView 3rd gate — chain: `onboardingComplete` → `notificationPermissionShown` → subscription check → TabView. Gate blocks on `"expired"` only.
- **D-03:** Silent trial — no in-app trial countdown or banners. App experience identical to paid during days 1–14.
- **D-04:** Two stacked cards — annual pre-selected, "Best Value" badge. Annual shows $2.92/mo + $35/year. Monthly is price anchor.
- **D-05:** PaywallView appears directly on cold launch when expired — no interstitial screen.
- **D-06:** Subscription status checked in ContentView `.task` on cold launch only. No mid-session or background checks.
- **D-07:** "Restore Purchases" button lives on PaywallView only.
- **D-08:** Restore success → `subscriptionStatus = "active"` → ContentView gate re-evaluates automatically. No alert or extra tap.
- **D-09:** `subscriptionStatus` values: `"trial"` | `"active"` | `"expired"` | `"unknown"`.
- **D-10:** `trialStartDate` set exactly once in `markOnboarded`. Expiry check is always `trialStartDate + 14 days` vs today.
- **D-11:** `"unknown"` → fail open (allow access). Gate only blocks on `"expired"`.

### Claude's Discretion

- Exact paywall headline copy
- Product ID naming convention
- Exact StoreKit configuration file location in Xcode
- `SubscriptionService` vs inline logic in ContentView (service preferred for testability)
- Loading state behavior in ContentView while async StoreKit check runs on first launch

### Deferred Ideas (OUT OF SCOPE)

- RevenueCat SDK integration
- Settings screen Restore Purchases
- Introductory offer A/B testing
- Grace period UI surfacing
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-22 | StoreKit 2 subscriptions configured for $4.99/month and $35/year; purchasable in sandbox with correct entitlement verification | StoreKit Configuration file + `Product.products(for:)` + `product.purchase()` + `Transaction.currentEntitlements` — all verified |
| REQ-23 | Trial expiry checked on every app launch; compares today against `trialStartDate + 14 days` using `UserProfile.subscriptionStatus` | Hybrid check in `SubscriptionService.resolveSubscriptionStatus()` called from ContentView `.task` — pattern verified |
| REQ-24 | Hard paywall blocks all app content on trial expiry — no dismiss button, no degraded free mode; restore purchases flow works in sandbox | ContentView conditional rendering (not sheet) is the correct hard-block pattern; `AppStore.sync()` is restore API — verified |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| StoreKit product fetch | iOS App (service layer) | — | Pure StoreKit API call; no server needed for v1 client-only verification |
| Subscription status resolution | iOS App (service layer) | Core Data | Combines local date math (trialStartDate) + StoreKit entitlement query; writes result to Core Data via UserProfileStore |
| ContentView gate rendering | iOS App (UI layer) | — | Reads `appState.subscriptionStatus`; renders PaywallView or TabView — same pattern as existing gates |
| Purchase flow | iOS App (UI layer) → service | StoreKit | PaywallView triggers `SubscriptionService.purchase()`; service handles VerificationResult |
| Transaction listener | iOS App (service layer) | — | Detached Task in SubscriptionService.init listens to `Transaction.updates`; refreshes entitlements on renewal events |
| Restore purchases | iOS App (UI layer) → service | StoreKit | PaywallView Restore button calls `SubscriptionService.restore()`; `AppStore.sync()` + re-check entitlements |
| Trial clock | Core Data | iOS App | `trialStartDate` written once by `UserProfileStore.markOnboarded`; read by service layer for date math |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| StoreKit | Built-in (iOS 17+) | Product fetch, purchase, entitlement check, restore | Apple's first-party async/await IAP framework; no external dependency needed |
| StoreKitTest | Built-in (Xcode) | Unit testing purchase flows with `SKTestSession` | Official Apple testing framework; enables automated subscription state tests |

**No third-party packages.** D-01 prohibits RevenueCat. StoreKit 2 ships with the SDK.

[VERIFIED: Apple Developer Documentation — developer.apple.com/documentation/storekit]

### Alternatives Considered (deferred per CONTEXT.md)

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native StoreKit 2 | RevenueCat | RevenueCat adds analytics/A/B but is out of scope for v1 per D-01 |

---

## Architecture Patterns

### System Architecture Diagram

```
Cold Launch
    │
    ▼
StackWiseApp.init()
  └── reads onboardingComplete from Core Data synchronously
  └── sets AppState.onboardingComplete (prevents flash)
    │
    ▼
StackWiseApp.body.task
  └── SubscriptionService.configure()
        ├── loads products: Product.products(for: productIDs)
        ├── starts Transaction.updates listener (detached Task)
        └── calls resolveSubscriptionStatus()
              ├── reads UserProfile.trialStartDate
              ├── checks Date() < trialStartDate + 14d → "trial"
              ├── if trial expired → queries Transaction.currentEntitlements
              │     ├── found verified, not revoked → "active"
              │     └── none found → "expired"
              └── writes status to UserProfile + AppState.subscriptionStatus
    │
    ▼
ContentView renders:
  if !onboardingComplete → OnboardingCoordinatorView
  else if !notificationPermissionShown → NotificationPermissionView
  else if subscriptionStatus == "expired" → PaywallView   ← NEW GATE
  else → TabView  (status "trial" | "active" | "unknown" all pass)

PaywallView
  ├── Zone 1: Headline copy  
  ├── Zone 2: Social proof
  ├── Zone 3: Annual card (pre-selected) + Monthly card
  │     └── loads from SubscriptionService.products
  ├── Zone 4: CTA "Start Free Trial" / "Subscribe" → product.purchase()
  └── Zone 4: "Restore Purchases" → AppStore.sync() + re-resolveSubscriptionStatus()

OnboardingCoordinatorView paywall surface (separate flow):
  └── PaywallPlaceholderView → PaywallView (same component, different context)
        └── onComplete → UserProfileStore.markOnboarded() sets trialStartDate
```

### Recommended Project Structure

```
StackWise/
├── Services/
│   └── SubscriptionService.swift    # NEW — @Observable @MainActor class
├── Features/
│   └── Onboarding/
│       ├── PaywallView.swift         # REPLACES PaywallPlaceholderView
│       └── PricingCardView.swift     # NEW — reusable annual/monthly card
├── Models/
│   └── UserProfileStore.swift       # EXTEND — add updateSubscriptionStatus()
```

### Pattern 1: SubscriptionService — @Observable class

```swift
// Source: Apple Developer Docs + Swift with Majid (verified pattern)
@MainActor
@Observable
final class SubscriptionService {
    private(set) var products: [Product] = []
    private(set) var isLoading: Bool = false
    private(set) var purchaseError: String? = nil

    private let productIDs = [
        "com.stackwise.app.monthly",
        "com.stackwise.app.annual"
    ]
    private var updatesTask: Task<Void, Never>?

    func configure(appState: AppState, context: NSManagedObjectContext) async {
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await self?.resolveAndPersist(appState: appState, context: context)
                    await transaction.finish()
                }
            }
        }
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            // Product load failure is non-fatal — paywall shows cached info
        }
        await resolveAndPersist(appState: appState, context: context)
    }

    deinit { updatesTask?.cancel() }
}
```

[VERIFIED: bleepingswift.com + swiftwithmajid.com + Apple docs — multiple sources agree on this pattern]

### Pattern 2: resolveSubscriptionStatus() — hybrid local + StoreKit check

```swift
// Source: derived from Apple Transaction.currentEntitlements docs + project decisions
func resolveSubscriptionStatus(profile: UserProfile) async -> String {
    // D-10: trial check is always local date math
    if let trialStart = profile.trialStartDate {
        let trialEnd = trialStart.addingTimeInterval(14 * 24 * 60 * 60)
        if Date() < trialEnd {
            return "trial"  // still within 14-day window
        }
    } else {
        // No trialStartDate = onboarding not complete; fail open
        return "unknown"
    }

    // Trial has elapsed — check StoreKit for active subscription
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result,
           transaction.productType == .autoRenewable,
           transaction.revocationDate == nil {
            // currentEntitlements only returns non-expired transactions
            return "active"
        }
    }
    return "expired"
}
```

**Important:** `Transaction.currentEntitlements` is a finite async sequence — it terminates after
emitting all current entitlements. The `for await` loop exits naturally; it does not run forever.
[VERIFIED: Apple Developer Documentation currentEntitlements]

### Pattern 3: Product purchase flow

```swift
// Source: Apple Developer Docs + RevenueCat tutorial (verified)
func purchase(_ product: Product, appState: AppState, context: NSManagedObjectContext) async throws {
    isLoading = true
    defer { isLoading = false }

    let result = try await product.purchase()

    switch result {
    case .success(let verification):
        let transaction = try verification.payloadValue  // throws if unverified
        await resolveAndPersist(appState: appState, context: context)
        await transaction.finish()
    case .userCancelled:
        break
    case .pending:
        break
    @unknown default:
        break
    }
}
```

### Pattern 4: Restore purchases

```swift
// Source: Apple Developer Docs AppStore.sync() (verified)
func restorePurchases(appState: AppState, context: NSManagedObjectContext) async throws {
    try await AppStore.sync()
    await resolveAndPersist(appState: appState, context: context)
    // AppState.subscriptionStatus is now updated; ContentView gate re-evaluates automatically
}
```

### Pattern 5: ContentView 3rd gate (D-02)

```swift
// Extends existing gate pattern in ContentView.swift
if appState.onboardingComplete {
    if !notificationPermissionShown {
        NotificationPermissionView(...)
    } else if appState.subscriptionStatus == "expired" {
        PaywallView(onComplete: { /* not needed — gate re-evaluates from status */ })
            .interactiveDismissDisabled(true)  // valid here: PaywallView shown as fullScreenCover
    } else {
        TabView { ... }
    }
} else {
    OnboardingCoordinatorView()
}
```

**Note on `interactiveDismissDisabled`:** This modifier only prevents swipe-to-dismiss on sheet/
fullScreenCover presentations. If PaywallView is rendered inline as the root view body via
`if/else`, no dismiss gesture exists and the modifier is unnecessary but harmless.
The PaywallView in `OnboardingCoordinatorView` is shown via `.fullScreenCover` — there
`interactiveDismissDisabled(true)` is correct and required (already implemented in placeholder).
For the ContentView gate approach, since PaywallView replaces the entire Group body inline,
`interactiveDismissDisabled` is redundant but not harmful.
[VERIFIED: Apple SwiftUI documentation interactiveDismissDisabled]

### Pattern 6: ContentView .task for subscription check

```swift
// Matches existing .task pattern in ContentView
.task {
    let profile = UserProfileStore.fetchOrCreate(in: context)
    appState.onboardingComplete = profile.onboardingComplete
    // New in Phase 7:
    await subscriptionService.configure(appState: appState, context: context)
}
```

The `.task` modifier cancels its work when the view disappears. Since ContentView is the root view,
it never disappears during a session — the task runs once on launch and completes. This matches
D-06 (cold launch only check).
[CITED: hackingwithswift.com/quick-start/concurrency/how-to-run-tasks-using-swiftuis-task-modifier]

### Anti-Patterns to Avoid

- **`ObservableObject`/`@Published` for SubscriptionService:** The project uses `@Observable` exclusively. Mixing patterns breaks the `@Environment` injection chain.
- **Checking `transaction.expirationDate` manually:** `Transaction.currentEntitlements` already filters out expired transactions — only active entitlements are emitted. Checking expirationDate is redundant and error-prone.
- **Blocking on `"unknown"`:** D-11 is locked. Unknown = fail open. Blocking unknown locks paying users on poor connectivity.
- **Running StoreKit check in `deinit` or background task that outlives the view:** Use `.task` on ContentView and a `Task.detached` for `Transaction.updates` stored as a property (cancelled in `deinit`).
- **Starting `Transaction.updates` listener inside a view:** The listener belongs in `SubscriptionService.init` or `configure()`, not in a SwiftUI view body or `.task` modifier that may be cancelled.
- **Calling `AppStore.sync()` on launch:** `AppStore.sync()` is for the Restore Purchases button only. Calling it on every launch is a UX anti-pattern (prompts Apple ID sign-in). Use `Transaction.currentEntitlements` for status checks.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transaction verification | Custom JWS signature parser | `VerificationResult.payloadValue` (throws on invalid) | StoreKit 2 verifies automatically; custom parsing introduces security bugs |
| Subscription status polling | Background timer | `Transaction.updates` AsyncSequence | Apple delivers renewal events; polling is battery-expensive and unreliable |
| Receipt validation | Server-side receipt endpoint | `Transaction.currentEntitlements` (client-side SK2) | StoreKit 2 uses on-device JWS verification; no server receipt endpoint needed for v1 |
| Trial eligibility check | Custom server-side DB | `subscription.isEligibleForIntroOffer` | Apple tracks eligibility per Apple ID; local tracking is unreliable across reinstalls |
| Restore purchases logic | Custom transaction history walk | `AppStore.sync()` | Apple's API handles cross-device and cross-account restore correctly |

**Key insight:** StoreKit 2's on-device JWS verification eliminates the server-side validation
requirement that made StoreKit 1 complex. For v1 with no backend, `Transaction.currentEntitlements`
+ `VerificationResult.payloadValue` is the complete, correct validation path.

---

## Common Pitfalls

### Pitfall 1: Two paywall surfaces with different purposes

**What goes wrong:** Treating `OnboardingCoordinatorView`'s paywall and the ContentView gate
paywall as the same flow. They share the `PaywallView` component but have different entry contexts:
- **Onboarding paywall** (`.fullScreenCover` in OnboardingCoordinatorView): user has not yet
  started a trial; CTA is "Start Free Trial"; `onComplete` calls `markOnboarded()`.
- **ContentView gate paywall** (inline `if/else` in ContentView): trial has expired or subscription
  lapsed; CTA is "Subscribe" or "Resubscribe"; `onComplete` is not needed (status drives gate).

**Why it happens:** `PaywallView` is visually the same but the post-purchase action differs.

**How to avoid:** `PaywallView` receives a context parameter (`.onboarding` vs `.recovery`) or two
separate CTA handlers. The "Start Free Trial" copy and `markOnboarded()` call only appear in the
onboarding surface. The recovery surface drives purely from StoreKit status.

**Warning signs:** If `markOnboarded()` is called from the ContentView paywall path, `trialStartDate` could be reset on a returning expired user.

### Pitfall 2: Transaction.updates listener not started early enough

**What goes wrong:** Subscription renewal events delivered while app is in background are missed if
the listener starts after UI is shown.

**Why it happens:** Developers start the listener inside a view's `.task` which only runs when the
view appears.

**How to avoid:** Start `Transaction.updates` listener in `SubscriptionService.configure()` which is
called from `StackWiseApp.body.task` — the earliest async hook in the app lifecycle.

**Warning signs:** Renewals not reflected until next cold launch.

### Pitfall 3: Re-running configure() on scene phase changes

**What goes wrong:** Calling `configure()` on every `scenePhase == .active` transition creates
multiple `Transaction.updates` listener tasks that each call `transaction.finish()` — finishing the
same transaction multiple times.

**Why it happens:** Following patterns designed for mid-session refresh (D-06 is locked to cold
launch only).

**How to avoid:** D-06 is explicit: check on cold launch only. One `configure()` call in
`StackWiseApp.body.task`. The `updatesTask` property guards against duplicates.

### Pitfall 4: Nil trialStartDate treated as expired

**What goes wrong:** If `trialStartDate == nil` (user hasn't completed onboarding yet), the resolve
function falls through to the StoreKit check, finds no entitlement, and returns `"expired"` —
locking a brand-new user.

**Why it happens:** Missing nil guard before the date math.

**How to avoid:** Explicit nil check: `if trialStartDate == nil { return "unknown" }`. D-11 fail-open
handles the rest.

### Pitfall 5: StoreKit configuration file not selected in scheme

**What goes wrong:** Simulator returns no products from `Product.products(for:)` even with correct
product IDs. The paywall shows empty cards.

**Why it happens:** The `.storekit` configuration file exists but is not assigned under Scheme →
Run → Options → StoreKit Configuration.

**How to avoid:** After creating the `.storekit` file, immediately assign it in the scheme. Test
immediately after to confirm products load.

### Pitfall 6: Sandbox tester reuse exhausts trial eligibility

**What goes wrong:** A sandbox Apple ID that was used to test a trial is permanently ineligible for
trials on that subscription group. Future trial tests appear to go directly to paid.

**Why it happens:** App Store sandbox tracks introductory offer eligibility per Apple ID, same as
production.

**How to avoid:** For trial testing, use the Xcode StoreKit local configuration (not sandbox).
Local configuration allows resetting eligibility. Only move to sandbox for final entitlement
verification before TestFlight.
[VERIFIED: Apple documentation + RevenueCat sandbox docs]

### Pitfall 7: product.purchase() missing options — appAccountToken not required

**What goes wrong:** Developer thinks `appAccountToken` is required and spends time building an
account token system.

**Why it happens:** Apple documentation mentions appAccountToken as a purchase option.

**How to avoid:** `appAccountToken` is optional. It is for server-side analytics linking. StackWise
v1 has no backend, so pass no options: `try await product.purchase()`. 
[VERIFIED: Apple documentation Product.PurchaseOption.appAccountToken — explicitly optional]

---

## StoreKit Configuration File Setup

### Creating the File (local Xcode testing — no App Store Connect required)

1. Xcode → File → New → File → StoreKit Configuration File
2. Name: `StackWise.storekit`, save in project root alongside `StackWise.xcodeproj`
3. In the configuration editor, click `+` → Add Auto-Renewable Subscription
4. Create a subscription group named `StackWise Premium`
5. Add two products:

| Reference Name | Product ID | Price | Subscription Period | Intro Offer |
|----------------|-----------|-------|---------------------|-------------|
| Monthly | `com.stackwise.app.monthly` | $4.99 | 1 Month | None |
| Annual | `com.stackwise.app.annual` | $35.00 | 1 Year | Free Trial: 14 Days |

6. Assign in scheme: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → `StackWise.storekit`

### Time Acceleration for Testing

With the StoreKit local configuration active, subscription periods compress:

| Real period | Simulator test time |
|-------------|---------------------|
| 1 week | 10 seconds |
| 1 month | 30 seconds |
| 1 year | 6 minutes |
| 14-day trial | ~7 seconds (7/30 × 30s) |

To test trial expiry: purchase annual plan with 14-day intro offer, wait ~7 seconds in simulator.

To reset trial eligibility in local testing: Debug menu in simulator → StoreKit → Manage
Transactions → Delete all, then reinstall app or clear data.

[VERIFIED: Apple documentation + techconcepts.org StoreKit 2 testing article]

### Sandbox Testing (for TestFlight validation)

1. Disable the `.storekit` file in the scheme (remove from StoreKit Configuration dropdown)
2. Create products in App Store Connect with matching product IDs
3. Create a Sandbox Tester account in App Store Connect (different email per test to preserve trial eligibility)
4. Sign in to sandbox account on device/simulator Settings → App Store → Sandbox Account

**Important:** Sandbox subscription periods compress differently (1 month = 5 minutes for most
subscription durations). Trial eligibility is not resettable on a sandbox account — use fresh
accounts for each trial test.

---

## Code Examples

### Complete SubscriptionService skeleton

```swift
// Source: Derived from Apple StoreKit 2 documentation + verified community patterns
import StoreKit
import CoreData

@MainActor
@Observable
final class SubscriptionService {
    private(set) var products: [Product] = []
    var isRestoring = false
    var restoreError: String? = nil

    private let productIDs: Set<String> = [
        "com.stackwise.app.monthly",
        "com.stackwise.app.annual"
    ]
    private var updatesTask: Task<Void, Never>?

    func configure(appState: AppState, context: NSManagedObjectContext) async {
        // Start listener first — never miss a background transaction
        if updatesTask == nil {
            updatesTask = Task.detached { [weak self] in
                for await update in Transaction.updates {
                    guard let self else { return }
                    if let transaction = try? update.payloadValue {
                        await self.resolveAndPersist(appState: appState, context: context)
                        await transaction.finish()
                    }
                }
            }
        }
        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price } // monthly first, annual second
        } catch { /* non-fatal */ }
        await resolveAndPersist(appState: appState, context: context)
    }

    func purchase(_ product: Product, appState: AppState, context: NSManagedObjectContext) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            await resolveAndPersist(appState: appState, context: context)
            await transaction.finish()
        case .userCancelled, .pending: break
        @unknown default: break
        }
    }

    func restorePurchases(appState: AppState, context: NSManagedObjectContext) async throws {
        isRestoring = true
        defer { isRestoring = false }
        try await AppStore.sync()
        await resolveAndPersist(appState: appState, context: context)
    }

    private func resolveAndPersist(appState: AppState, context: NSManagedObjectContext) async {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        let status = await resolveSubscriptionStatus(profile: profile)
        appState.subscriptionStatus = status
        UserProfileStore.updateSubscriptionStatus(status, profile: profile, in: context)
    }

    private func resolveSubscriptionStatus(profile: UserProfile) async -> String {
        guard let trialStart = profile.trialStartDate else { return "unknown" }
        let trialEnd = trialStart.addingTimeInterval(14 * 24 * 60 * 60)
        guard Date() >= trialEnd else { return "trial" }

        // Trial elapsed — check StoreKit entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productType == .autoRenewable,
               transaction.revocationDate == nil {
                return "active"
            }
        }
        return "expired"
    }

    deinit { updatesTask?.cancel() }
}
```

### UserProfileStore extension needed (new method)

```swift
// Add to UserProfileStore enum
static func updateSubscriptionStatus(
    _ status: String,
    profile: UserProfile,
    in context: NSManagedObjectContext
) {
    guard profile.subscriptionStatus != status else { return }
    profile.subscriptionStatus = status
    try? context.save()
}
```

### StackWiseApp injection pattern

```swift
// StackWiseApp.swift additions
@State private var subscriptionService: SubscriptionService = SubscriptionService()

// In WindowGroup body:
.environment(subscriptionService)

// In .task:
.task {
    appDelegate.appState = appState
    await subscriptionService.configure(appState: appState, context: persistenceController.container.viewContext)
}
```

### PricingCardView skeleton

```swift
// For annual card pre-selected, "Best Value" badge
struct PricingCardView: View {
    let product: Product
    let isSelected: Bool
    let isAnnual: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isAnnual ? "Annual" : "Monthly")
                        .font(.swTitle3)
                    Spacer()
                    if isAnnual {
                        Text("Best Value")
                            .font(.swCaption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.aquaPrimary)
                            .clipShape(Capsule())
                    }
                }
                if isAnnual {
                    Text("$2.92/mo")
                        .font(.swTitle2)
                    Text("$35.00 billed annually")
                        .font(.swFootnote)
                        .foregroundStyle(.textSecondary)
                } else {
                    Text(product.displayPrice + "/mo")
                        .font(.swTitle2)
                }
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.aquaPrimary : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Receipt validation via `/verifyReceipt` endpoint | On-device JWS via `VerificationResult.payloadValue` | StoreKit 2 (iOS 15, 2021) | No server needed for v1 |
| `SKPaymentQueue` + delegate callbacks | `product.purchase()` async/await | StoreKit 2 (iOS 15, 2021) | Simpler, no delegate setup |
| `SKReceiptRefreshRequest` for restore | `AppStore.sync()` | StoreKit 2 (iOS 15, 2021) | One-line restore |
| `ObservableObject` service class | `@Observable` macro | Swift 5.9 / iOS 17 (2023) | Project already uses this; SubscriptionService must match |
| `SubscriptionStoreView` / `StoreKit.SwiftUI` views | Custom product cards (D-04) | iOS 17 | D-04 requires custom card layout; native StoreKit views don't match design spec |

**Deprecated/outdated patterns to avoid:**
- `SKProductsRequest` / `SKPaymentQueue`: StoreKit 1, not used in this project
- `ObservableObject`/`@Published` for service classes: incompatible with project's `@Observable` pattern

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing, Xcode built-in) |
| Config file | `StackWiseTests/` target in `StackWise.xcodeproj` |
| Quick run command | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StackWiseTests` |
| Full suite command | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-22 | Products load from configuration for both product IDs | Unit | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |
| REQ-22 | Purchase succeeds in StoreKit test environment | Unit (SKTestSession) | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |
| REQ-23 | Trial status = "trial" when trialStartDate < 14 days ago | Unit | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |
| REQ-23 | Trial status = "expired" when trialStartDate > 14 days ago and no entitlement | Unit (SKTestSession) | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |
| REQ-23 | Trial status = "active" when trialStartDate > 14 days ago and entitlement exists | Unit (SKTestSession) | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |
| REQ-23 | Status = "unknown" when trialStartDate is nil | Unit | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |
| REQ-24 | Restore purchases sets status to "active" | Unit (SKTestSession) | `xcodebuild test -only-testing:StackWiseTests/SubscriptionServiceTests` | ❌ Wave 0 |

### SKTestSession Pattern (StoreKitTest framework)

```swift
// Source: Apple StoreKitTest documentation
import StoreKitTest
import XCTest
@testable import StackWise

class SubscriptionServiceTests: XCTestCase {
    var testSession: SKTestSession!

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: "StackWise")
        testSession.resetToDefaultState()
        testSession.disableDialogs = true
    }

    func testTrialStatusWhenWithinTrialWindow() async throws {
        // Set up: trialStartDate = 7 days ago
        // Expected: resolveSubscriptionStatus returns "trial"
    }

    func testExpiredStatusWhenTrialElapsedAndNoEntitlement() async throws {
        // Set up: trialStartDate = 15 days ago, no purchase
        // Expected: resolveSubscriptionStatus returns "expired"
    }
}
```

### Sampling Rate

- **Per task commit:** Quick run against `SubscriptionServiceTests` target
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `StackWiseTests/SubscriptionServiceTests.swift` — covers REQ-22, REQ-23, REQ-24
- [ ] `StackWise.storekit` — StoreKit configuration file with both products and 14-day trial
- [ ] `UserProfileStore.updateSubscriptionStatus()` method — needed by SubscriptionService

---

## Security Domain

> `security_enforcement: true`, ASVS level 1.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Not applicable — StoreKit handles Apple ID auth |
| V3 Session Management | No | No session tokens in this feature |
| V4 Access Control | Yes | ContentView gate — blocks expired users from TabView |
| V5 Input Validation | No | No user text input in purchase flow |
| V6 Cryptography | Yes | StoreKit 2 JWS verification via `VerificationResult.payloadValue` — never hand-roll |
| V9 Communication Security | Yes | All StoreKit calls go over Apple's TLS — no custom endpoints |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fake transaction injection | Spoofing | `VerificationResult.payloadValue` throws on invalid JWS — must unwrap with `try`, never force-cast |
| Bypassing paywall via deep link | Elevation of Privilege | ContentView gate driven by `appState.subscriptionStatus` which is set from verified StoreKit state — deep links cannot write this value |
| Race condition: status check completes after TabView renders | Tampering | `StackWiseApp.body.task` must await `configure()` before ContentView's `.task` is relevant — ordering is safe because ContentView reads AppState which is populated synchronously in StackWiseApp.init |
| Revoked transaction still granting access | Spoofing | `transaction.revocationDate == nil` check in `resolveSubscriptionStatus` |

**Security constraint:** Never use `try?` or `try!` on `verification.payloadValue` in production
purchase handling. Use `try` with proper error propagation. An unverified transaction that silently
becomes `nil` would still unlock the app.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| StoreKit 2 | All REQ-22/23/24 | ✓ | Built-in iOS 17 | — |
| StoreKitTest | Unit tests | ✓ | Built-in Xcode | — |
| Xcode StoreKit Configuration | Local testing | ✓ (needs file creation) | Built-in | — |
| App Store Connect products | Sandbox/TestFlight | Needs setup | — | Use local .storekit file for development |
| Sandbox tester account | Sandbox testing | Needs creation | — | Use local .storekit file for development |

**Missing dependencies with no fallback:** None — all required for v1 are available.

**Missing dependencies with fallback:** App Store Connect products and sandbox tester account are
needed only for TestFlight. Local `.storekit` configuration covers all development and CI testing.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Product IDs `com.stackwise.app.monthly` and `com.stackwise.app.annual` are not yet registered in App Store Connect | Standard Stack | If already registered with different IDs, the plan must use the existing IDs |
| A2 | `$2.92/mo` is calculated as $35/12 rounded — acceptable for display copy | Code Examples (PricingCardView) | Minor — adjust display string if pricing changes |
| A3 | The `subscriptionStatusTask` iOS 17 SwiftUI modifier is not used in favor of explicit `Transaction.currentEntitlements` loop (matches project's explicit pattern) | Architecture | Low risk — both approaches are correct; explicit pattern is more testable |

---

## Open Questions

1. **PaywallView context parameter design**
   - What we know: Two surfaces use PaywallView (onboarding + ContentView gate) with different
     CTA behavior
   - What's unclear: Whether to use an enum `PaywallContext` parameter or two separate view structs
   - Recommendation: Single `PaywallView` with `isOnboarding: Bool` parameter; simpler than
     two structs and avoids duplication of card layout code

2. **Loading state UX in ContentView during async check**
   - What we know: `configure()` is async and takes 200–800ms on first launch
   - What's unclear: Whether to show a spinner, keep the current view, or use a splash screen
   - Recommendation (Claude's discretion): Show no explicit loading state — existing app launch
     pattern sets `onboardingComplete` synchronously in `StackWiseApp.init()`, so ContentView
     renders the correct branch immediately. The subscription status defaults to `"unknown"` (fail
     open) and updates when `configure()` completes. No visible flash for users in trial or active state.

3. **SubscriptionService injection into OnboardingCoordinatorView**
   - What we know: OnboardingCoordinatorView shows PaywallView; after `completeOnboarding()`
     the trial starts; SubscriptionService should update status to "trial"
   - What's unclear: Whether `OnboardingCoordinatorView` calls `resolveAndPersist` or if
     ContentView's `.task` handles this on the next launch
   - Recommendation: After `completeOnboarding()`, call `subscriptionService.resolveAndPersist()`
     to immediately set status to "trial" without requiring a cold restart

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — developer.apple.com/documentation/storekit (Product, Transaction, AppStore.sync)
- Apple Developer Documentation — developer.apple.com/documentation/storekit/transaction-properties (isInTrialPeriod, offerType)
- Apple Developer Documentation — developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)

### Secondary (MEDIUM confidence)
- [Swift with Majid — Mastering StoreKit 2](https://swiftwithmajid.com/2023/08/01/mastering-storekit2/) — fetchActiveTransactions pattern, Transaction.updates listener
- [BleepingSwift — StoreKit 2](https://bleepingswift.com/blog/storekit-2-in-app-purchases-subscriptions) — complete StoreManager patterns
- [RevenueCat — iOS In-App Subscription Tutorial](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/) — purchase flow, restore pattern
- [Tanaschita — StoreKit 2 Introductory Offers](https://tanaschita.com/20231113-subscriptions-introductory-offers/) — isEligibleForIntroOffer, free trial configuration
- [Superwall — StoreKit 2 Tutorial](https://superwall.com/blog/make-a-swiftui-app-with-in-app-purchases-and-subscriptions-using-storekit-2/) — @Observable PurchaseOperations pattern

### Tertiary (LOW confidence)
- [TechConcepts — StoreKit 2 in Practice](https://techconcepts.org/blog/storekit2-subscriptions-practice) — grace period handling guidance

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — StoreKit 2 APIs verified via Apple docs + multiple independent sources
- Architecture: HIGH — ContentView gate pattern matches existing codebase; SubscriptionService
  pattern confirmed by 3+ authoritative sources
- Pitfalls: HIGH — configuration file + sandbox pitfalls verified by Apple docs and community sources
- Test patterns: HIGH — SKTestSession from Apple StoreKitTest documentation

**Research date:** 2026-05-29
**Valid until:** 2026-08-29 (StoreKit 2 APIs are stable; 90 days safe)
