---
phase: 1
slug: project-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-07
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built into Xcode, no install required) |
| **Config file** | StackWiseTests target in the Xcode project |
| **Quick run command** | `xcodebuild build -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StackWiseTests` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Build succeeds (no compile errors)
- **After every plan wave:** `xcodebuild build -scheme StackWise` green + manual simulator tab switching
- **Before `/gsd-verify-work`:** All three tabs visible and switchable, Core Data stack loads without console warnings, bundle ID confirmed
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | REQ-06 | — | N/A | build + manual | `xcodebuild build -scheme StackWise` + manual bundle ID check in Project settings | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 1 | REQ-07 | — | N/A | unit | `xcodebuild test -scheme StackWise -only-testing:StackWiseTests/CoreDataSchemaTests` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 1 | REQ-08 | — | N/A | manual | Run on simulator, switch all three tabs; confirm no crash | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `StackWiseTests/CoreDataSchemaTests.swift` — stubs for REQ-07 (Core Data entity insertion + save)
- [ ] XCTest target included at project creation ("Include Tests" checkbox checked during Xcode project wizard)

*Note: REQ-06 (bundle ID) and REQ-08 (tab switching) require manual verification — documented in plan task acceptance criteria.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bundle ID is exactly `com.stackwise.app` | REQ-06 | XCTest cannot read Xcode project settings | Open Project > Signing & Capabilities; confirm Bundle Identifier = `com.stackwise.app` (all lowercase) |
| Three-tab navigation renders and switches | REQ-08 | UI rendering requires simulator | Run app on iOS 17 simulator; tap each tab (Stack / Today / Schedule); confirm no crash |
| App icon and launch screen appear | Phase 1 success criterion | Visual verification only | Cold launch in simulator; observe launch screen background color; confirm icon in springboard |
| No `NSKeyedUnarchiveFromData` warnings | REQ-07 (quality) | Runtime console check | Launch app; open Xcode console; confirm no "NSKeyedUnarchiveFromData is deprecated" warnings |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
