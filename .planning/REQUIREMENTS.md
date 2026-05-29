# Requirements: StackWise

**Defined:** 2026-05-04  
**Core value:** Trustworthy supplement/medication interaction analysis paired with a personalized smart schedule and reminders  
**Source:** SPEC.md (v1 conceptual spec)

---

## v1 Requirements (Committed Scope)

### Database (Phase 0)

- [ ] **REQ-01**: A single `stackwise.sqlite` file exists with `interactions`, `ingredients`, and `metadata` tables and opens without errors
- [ ] **REQ-02**: Every compound on the 50-supplement reference list has at least one interaction record with confidence ≥ medium
- [ ] **REQ-03**: Every compound on the 20-medication reference list has at least one interaction record with confidence ≥ medium
- [ ] **REQ-04**: `ingredients.canonical_name` values follow NIH ODS lowercase_underscores format; all known aliases captured in `ingredients.aliases` JSON array
- [ ] **REQ-05**: `metadata` table contains exactly one row with `db_version` (semantic versioning, e.g. `"1.0.0"`) and `date_built` (ISO date string)

### Project Foundation (Phase 1)

- [ ] **REQ-06**: Xcode project named StackWise with bundle ID `com.stackwise.app` builds and runs on simulator
- [ ] **REQ-07**: Core Data schema includes UserProfile, StackItem, ScheduledDose, DailyCheckOff, and FeedbackItem entities with all attributes per SPEC.md data model
- [ ] **REQ-08**: Three-tab navigation (Stack / Today / Schedule) renders and tab switching works without crashes

### Stack & User Setup (Phase 2)

- [ ] **REQ-09**: Health profile screen collects age, sex, weight, allergies, and conditions; data persists to Core Data UserProfile singleton
- [ ] **REQ-10**: Add item flow requires two fields (label + active ingredient); app auto-suggests active ingredient from `ingredients` table; user always confirms or overrides
- [ ] **REQ-11**: Stack list shows all active items with edit and delete; items where active ingredient not found in database are visually flagged with `isInDatabase = false`

### Interaction Analysis Engine (Phase 3)

- [ ] **REQ-12**: `stackwise.sqlite` bundled as a read-only app asset; loaded on launch; never written to by the app
- [ ] **REQ-13**: Pairwise lookup engine runs on every stack change and returns all flagged pairs using bidirectional query on `interactions` table
- [ ] **REQ-14**: Severity classification correctly maps database `severity` values (`"advisory"`, `"critical"`) to UI tiers; supplement↔supplement and supplement↔drug only (drug↔drug excluded)
- [ ] **REQ-15**: Interaction analysis screen groups results: critical conflicts → advisory conflicts → positive insights → not-in-database items with external resource links

### Smart Schedule (Phase 4)

- [ ] **REQ-16**: Scheduling algorithm applies 5 priority rules in exact order: (1) prescriptions first, (2) timing-conflict separation, (3) individual timing properties, (4) unconstrained → morning default, (5) 5-item block overflow
- [ ] **REQ-17**: Schedule tab renders Morning / Afternoon / Evening blocks with item lists, suggested time windows, and positive/conflict flags linking to analysis screen

### Functional Onboarding (Phase 5)

- [ ] **REQ-18**: Onboarding coordinator sequences health profile → stack entry → schedule inputs → preview screen; main app tabs hidden until complete
- [ ] **REQ-19**: Trial start trigger fires exactly once at onboarding completion; writes `trialStartDate` to UserProfile; persists locally

### Reminders & Today Tab (Phase 6)

- [x] **REQ-20**: Local notifications scheduled for each time block; notification body lists specific item labels (not generic); tapping opens Today tab
- [x] **REQ-21**: Today tab shows morning / afternoon / evening rows with per-block check-off; completion persists to Core Data DailyCheckOff

### Monetization (Phase 7)

- [ ] **REQ-22**: StoreKit 2 subscriptions configured for $4.99/month and $35/year; purchasable in sandbox with correct entitlement verification
- [ ] **REQ-23**: Trial expiry checked on every app launch; compares today against `trialStartDate + 14 days` using `UserProfile.subscriptionStatus`
- [ ] **REQ-24**: Hard paywall blocks all app content on trial expiry — no dismiss button, no degraded free mode; restore purchases flow works in sandbox

### In-App Feedback (Phase 8)

- [ ] **REQ-25**: Feedback entry point on each flagged interaction pair ("Dispute this flag"), on the schedule tab ("Report a scheduling issue"), and in settings (general feedback)
- [ ] **REQ-26**: Feedback form POSTs to Formspree endpoint; only Formspree domain added to NSAppTransportSecurity; no health data sent via feedback
- [ ] **REQ-27**: Failed feedback submissions stored locally in FeedbackItem with `submitted = false`; automatically retried on next app launch

### Polish & Ship (Phase 9)

- [ ] **REQ-28**: Dark mode works correctly across all screens; no hardcoded light-mode colors; severity flag colors reserved for interaction indicators
- [ ] **REQ-29**: Privacy policy publicly hosted and linked from App Store listing and in-app settings; states on-device-only storage, no health data sharing, Formspree feedback handling
- [ ] **REQ-30**: App Store submission accepted; age rating 12+ or 17+ per content questionnaire; TestFlight internal build passes before submission

---

## v2 Requirements (Deferred — post-launch)

- iCloud sync / CloudKit support
- Rich lock-screen notifications with check-off action
- Streak tracking and adherence history
- Multi-profile support
- Additional schedule inputs (workout timing, caffeine habits)
- Third severity tier (if database granularity supports it)
- Automated database update/version-check mechanism
- Onboarding redesign based on user feedback

---

## Out of Scope (v1)

| Feature | Reason |
|---------|--------|
| Drug↔drug interaction analysis | Out of scope per SPEC.md — supplement↔drug and supplement↔supplement only |
| Permanent free tier | Business decision — 14-day trial only, hard paywall after |
| iCloud/cross-device sync | Explicitly deferred post-launch |
| Streak tracking | Deferred post-launch |
| Full onboarding redesign | Designed after app is feature-complete, from user feedback |
| Third severity tier | Added post-launch if database supports it |

---

## Traceability Matrix

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-01 | Phase 0 | Pending |
| REQ-02 | Phase 0 | Pending |
| REQ-03 | Phase 0 | Pending |
| REQ-04 | Phase 0 | Pending |
| REQ-05 | Phase 0 | Pending |
| REQ-06 | Phase 1 | Pending |
| REQ-07 | Phase 1 | Pending |
| REQ-08 | Phase 1 | Pending |
| REQ-09 | Phase 2 | Pending |
| REQ-10 | Phase 2 | Pending |
| REQ-11 | Phase 2 | Pending |
| REQ-12 | Phase 3 | Pending |
| REQ-13 | Phase 3 | Pending |
| REQ-14 | Phase 3 | Pending |
| REQ-15 | Phase 3 | Pending |
| REQ-16 | Phase 4 | Pending |
| REQ-17 | Phase 4 | Pending |
| REQ-18 | Phase 5 | Pending |
| REQ-19 | Phase 5 | Pending |
| REQ-20 | Phase 6 | Complete |
| REQ-21 | Phase 6 | Complete |
| REQ-22 | Phase 7 | Pending |
| REQ-23 | Phase 7 | Pending |
| REQ-24 | Phase 7 | Pending |
| REQ-25 | Phase 8 | Pending |
| REQ-26 | Phase 8 | Pending |
| REQ-27 | Phase 8 | Pending |
| REQ-28 | Phase 9 | Pending |
| REQ-29 | Phase 9 | Pending |
| REQ-30 | Phase 9 | Pending |

**v1 requirements total: 30**
