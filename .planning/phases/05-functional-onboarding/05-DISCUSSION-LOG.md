# Phase 5: Functional Onboarding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the discussion reasoning.

**Date:** 2026-05-25
**Phase:** 05-functional-onboarding
**Mode:** discuss (default)
**Areas discussed:** Navigation style, Preview screen scope, Mid-onboarding crash recovery, Empty stack behavior, Notification permission timing, Paywall screen shape

---

## Discussion Log

### Navigation style

**Options presented:**
- NavigationStack (back arrow free)
- Forward-only pager / stepper
- NavigationStack but selective (chosen)

**User selection:** NavigationStack but selective

**Rationale:** StackWise collects real health data (age, weight, conditions, allergies, meal times) — users will make typos and second-guess inputs. Forward-only would trade deliberation friction for error-correction frustration. Selective gives: early steps freely navigable (high data accuracy), preview onward as one-way gate (reinforces commitment after sunk-cost investment). Aligns with onboarding research on sunk-cost psychology.

---

**Options presented (step indicator):**
- Yes — progress dots or step counter
- No — clean screens (chosen)
- You decide

**User selection:** No global indicator; phase-scoped only

**Rationale:** The onboarding is intentionally long (health profile + full stack build + meal timing). A global "Step 4 of 14" counter makes the flow feel like a chore. Phase-scoped indicators within bounded sub-tasks (e.g., health profile fields) are acceptable — they show progress without revealing total onboarding length.

---

### Preview screen scope

**Options presented:**
- Reuse AnalysisView + ScheduleView as-is
- New simplified preview card
- Hybrid — summary card + expandable detail (chosen)

**User selection:** Hybrid

**Rationale:** The preview is the highest-leverage moment in onboarding — the "Aha" moment where the user sees payoff for time invested. Summary card with headline numbers (e.g. "2 critical interactions found", "Your 3-block schedule is ready") creates immediate impact. "See full analysis" satisfies skeptical users who want to verify value before paying. Reusing AnalysisView as-is was explicitly ruled out — it drops users into the full product UI cold, killing psychological momentum.

---

**Options presented (CTA):**
- "Start Free Trial" → fires trigger directly
- "Start Free Trial" → navigates to paywall screen placeholder (chosen)
- "Unlock StackWise" (paywall framing)

**User selection:** Navigates to paywall placeholder

**Notes:** Trial mechanism is Apple's native StoreKit flow (likely RevenueCat in Phase 7). No manual card entry. Phase 5 placeholder fires trigger directly; Phase 7 inserts real StoreKit purchase flow.

---

### Mid-onboarding crash recovery

**Options presented:**
- Resume from last completed step (explicit cursor)
- Restart from beginning
- Smart partial resume — infer from entity state (chosen)

**User selection:** Smart partial resume

**Rationale:** No additional Core Data cursor field needed. Existing entities are the source of truth. Inference logic: no UserProfile → step 1; UserProfile filled + no StackItems → step 2; StackItems exist + meal/wake times empty → step 3; all data present + `onboardingComplete = false` → step 4 (preview directly).

---

### Empty stack behavior

**Options presented:**
- At least 1 item required (chosen)
- Empty stack allowed — advance freely
- Soft gate with warning

**User selection:** Hard minimum of 1 StackItem

**Rationale:** An empty preview screen undermines the entire conversion strategy. Users need to have invested real data to feel value before hitting the paywall. The disabled Next button copy encourages adding more: "Add your supplements to see how they interact and get your personalized schedule."

---

### Notification permission timing

**Options presented:**
- After trial start — first app launch post-onboarding (chosen)
- Before preview — in the onboarding flow
- Phase 5 reserves the slot, Phase 6 owns the screen

**User selection:** After trial start — entirely outside Phase 5 onboarding

**Rationale:** Notification ask in the middle of onboarding would interrupt the preview → paywall momentum sequence. Post-trial-start, the user has seen their real schedule and the framing ("StackWise will remind you at the right time for each supplement") has full context. Keeping the ask out of onboarding protects the highest-leverage conversion sequence. Phase 6 owns this entirely.

---

### Paywall screen shape

**Options presented:**
- Minimal placeholder — just fires the trigger
- Wireframe with key conversion zones (chosen)
- You decide

**User selection:** Wireframe with 4 structural zones

**Rationale:** Zone structure established in Phase 5 gives the design workflow a structural brief (rather than blank canvas) when full paywall is designed before Phase 7. Four zones in order: hero/value prop → social proof → pricing → CTA ("Start Free Trial" + "Restore Purchases"). Sections are stubbed placeholder text only — no real copy, no real design.

---

## Claude's Discretion Items

- Exact animation/transition between onboarding steps
- Error state handling and validation copy within individual steps
- Exact visual layout of the summary card counts on the preview screen (design workflow handles in Phase 7)

---

## Deferred Ideas

- Notification permission value-framing screen → Phase 6
- StoreKit 2 / RevenueCat integration → Phase 7
- Full paywall visual design → design workflow before Phase 7
- Onboarding redesign from user feedback → post-launch
