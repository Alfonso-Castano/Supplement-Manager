# Phase 7: Monetization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 07-CONTEXT.md — this log preserves the discussion.

**Date:** 2026-05-29
**Phase:** 07-monetization
**Mode:** default (interactive)
**Areas discussed:** StoreKit approach, Paywall gate placement, In-trial UX, Pricing plan layout, Trial expiry transition UX, Restore purchases flow, subscriptionStatus values

---

## Discussion Log

### Area 1 — StoreKit Integration Approach

| Question | Options | Selected |
|----------|---------|----------|
| Which StoreKit approach? | Native StoreKit 2 / RevenueCat SDK | Native StoreKit 2 |

**User rationale:** For v1, use Apple's native StoreKit 2 API directly — no external SDK, no RevenueCat account or API key needed. RevenueCat will be added post-launch once there are real paying users and the analytics dashboard becomes valuable. RevenueCat can be integrated after launch without affecting existing subscribers since it sits on top of StoreKit and reads from App Store Connect. For now, keep dependencies minimal and ship with native StoreKit 2 as the ROADMAP specifies.

---

### Area 2 — Paywall Gate Placement

| Question | Options | Selected |
|----------|---------|----------|
| Where does the hard paywall gate live? | ContentView 3rd gate / fullScreenCover on TabView | ContentView 3rd gate |

**User rationale:** Consistent with the existing onboarding and notification permission gate pattern. Produces no visual flicker. Ensures the paywall is a true hard gate with zero possibility of app content briefly rendering behind it. fullScreenCover approach was explicitly rejected — the frame-delay flicker on a no-dismiss hard paywall is poor experience and architecturally messier.

---

### Area 3 — In-Trial UX

| Question | Options | Selected |
|----------|---------|----------|
| What does the app show during the trial? | Silent / Settings screen only / Trial countdown banner | Silent — no trial UI anywhere |

**User rationale:** The app runs identically during the trial with no countdown banners, no persistent indicators, and no difference from a paid subscription experience. In the standard StoreKit flow, users who confirmed the trial are auto-billed by Apple at day 14 and never see the paywall. The gate exists only as a fallback for cancelled, failed, or lapsed subscriptions.

---

### Area 4 — Pricing Plan Layout

| Question | Options | Selected |
|----------|---------|----------|
| How are two plans displayed? | Two stacked cards / Segmented toggle | Two stacked cards, annual highlighted |

**User rationale:** Annual card pre-selected with "Best Value" badge. Displays effective monthly cost ($2.92/mo) prominently alongside total ($35/year). The monthly card's role is to anchor perception and make the annual plan feel like an obvious deal — not to drive monthly conversions.

---

### Area 5 — Trial Expiry Transition UX

| Question | Options | Selected |
|----------|---------|----------|
| Intermediate screen before paywall? | Paywall directly / Trial ended interstitial | Paywall directly |
| Check trigger timing? | Cold launch only / On foreground + cold launch | Cold launch only |

**User rationale:** No interstitial — fewer transitions, less friction in conversion funnel. Paywall headline communicates the situation. Cold launch only is simple, predictable, and no background tasks needed. The realistic expiry scenario is always caught on the next cold launch.

---

### Area 6 — Restore Purchases Flow

| Question | Options | Selected |
|----------|---------|----------|
| Where does Restore button live? | Paywall only / Paywall + Settings | Paywall only |
| During/after restore UX? | Spinner + gate re-evaluates / Alert on success | Spinner + gate auto-re-evaluates |

**User rationale:** Paywall only satisfies App Store Review requirement. Gate re-evaluation on success means no extra tap — AppState updates and ContentView gate re-renders automatically.

---

### Supplementary Questions

| Question | Options | Selected |
|----------|---------|----------|
| subscriptionStatus string values? | "trial"\|"active"\|"expired"\|"unknown" / Pure StoreKit live query | "trial"\|"active"\|"expired"\|"unknown" |

**Additional clarifications from user (closing notes):**
- `trialStartDate` set once at `markOnboarded`, never overwritten — expiry = `trialStartDate + 14 days` vs today. Already guarded in `UserProfileStore`.
- `"unknown"` status → fail open (allow access). Gate only blocks on `"expired"`. Blocking on unknown would lock legitimate paying users out on poor connectivity.

---

## Claude's Discretion (User Delegated)

- Exact paywall headline copy
- Product ID naming convention
- StoreKit configuration file location in Xcode
- `SubscriptionService` structure (service vs inline)
- Loading state while async StoreKit check runs on launch
