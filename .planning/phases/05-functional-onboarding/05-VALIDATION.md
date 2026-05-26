---
phase: 5
slug: functional-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in Xcode) |
| **Config file** | None — Xcode target `StackWiseTests` |
| **Quick run command** | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StackWiseTests/OnboardingCoordinatorTests -only-testing:StackWiseTests/UserProfileStoreTests` |
| **Full suite command** | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~45 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run quick command (OnboardingCoordinatorTests + UserProfileStoreTests)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green (all 50 existing + new onboarding tests)
- **Max feedback latency:** ~45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 5-W0-01 | W0 | 0 | REQ-18 | — | N/A | unit stub | quick run | ❌ W0 | ⬜ pending |
| 5-01-01 | 01 | 1 | REQ-18 | — | N/A | unit | quick run | ❌ W0 | ⬜ pending |
| 5-01-02 | 01 | 1 | REQ-18 | — | N/A | unit | quick run | ❌ W0 | ⬜ pending |
| 5-01-03 | 01 | 1 | REQ-18 | — | N/A | unit | quick run | ❌ W0 | ⬜ pending |
| 5-01-04 | 01 | 1 | REQ-19 | T-5-02 | trialStartDate guard enforced | unit | quick run | ✅ existing | ⬜ pending |
| 5-02-01 | 02 | 1 | REQ-18 | T-5-01 | onboardingComplete gate read from Core Data | manual | simulator | N/A | ⬜ pending |
| 5-02-02 | 02 | 1 | REQ-18 | — | N/A | manual | simulator | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `StackWiseTests/OnboardingCoordinatorTests.swift` — stubs for REQ-18 resume branches (4 branches) and REQ-19 write-on-complete

*Existing infrastructure covers all other phase requirements — 50 tests already green.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ContentView gate: coordinator vs TabView | REQ-18 | SwiftUI conditional render; XCTest cannot inspect view hierarchy without ViewInspector | Launch simulator; wipe app data; confirm coordinator appears; complete flow; confirm TabView appears |
| fullScreenCover for preview step (one-way gate) | REQ-18 (D-02) | SwiftUI presentation API not unit-testable | On preview screen, verify back swipe is blocked; confirm `interactiveDismissDisabled(true)` in code |
| "See full analysis" NavigationLink push | REQ-18 (D-04) | NavigationLink push requires live stack | Tap "See full analysis" on preview; confirm AnalysisView pushes; back returns to preview |
| Smart resume across crash | REQ-18 (D-07) | Requires app relaunch | Kill app mid-step 2 (with items); relaunch; confirm lands at step 2 (not step 1) |

---

## Threat Model

| Threat ID | Threat | STRIDE | Mitigation | ASVS |
|-----------|--------|--------|------------|------|
| T-5-01 | Bypass onboarding gate to access tabs | Elevation of Privilege | `onboardingComplete` read from Core Data on launch — cannot be set without Core Data write | V4 |
| T-5-02 | Trial trigger fires more than once | Tampering | `if profile.trialStartDate == nil` guard in `UserProfileStore.markOnboarded()` — already implemented and tested | V5 |
| T-5-03 | Malformed health input (allergies free-text) | Tampering | Stored as `[String]` via NSSecureUnarchiveFromData transformable — no SQL surface | V5 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
