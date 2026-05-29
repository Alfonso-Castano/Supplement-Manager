---
REVIEW RESULT: FAIL
MODE: gsd-automated
PHASE: 5
TIMESTAMP: 2026-05-26T00:00:00Z
---

## Summary
Three HIGH findings trip the mechanical FAIL threshold (≥3 HIGH = FAIL), even though no CRITICAL issues exist and all 11 requirements are ✓ or ⚠. The HIGH findings are: missing numeric range validation on age/weight, missing max-length cap on allergies/conditions free text, and test bodies absent from the diff (REQ-6 GREEN status unverifiable). Not safe to proceed without remediation on at least the input-validation findings; REQ-6 needs the full test bodies in the diff or a CI green log attached.

## Findings

### [FINDING-01] HIGH: Numeric inputs not range-validated before persistence
Lens: Security
Location: StackWise/Features/Onboarding/HealthProfileView.swift (save())
What went wrong: `age` (Int) and `weightKg` (Double) are written directly to the Core Data profile with no positive-range check or upper bound. The diff shows `profile.age = Int16(age)` and `profile.weightKg = weightKg` with no guard. The `canSave` predicate that backs the Next button's `.disabled` modifier is not shown in the diff, so it cannot be verified to enforce numeric ranges.
Why it matters: Health-domain numeric inputs without validation can corrupt downstream interaction analysis (a 600 kg weight or negative age silently persists), and Int16 narrowing of an out-of-range Int is undefined behavior risk. Per checklist, numeric inputs must be validated as positive and within reasonable range.
Possible solutions:
  1. Add explicit guards in `save()`: `guard age > 0, age < 120, weightKg > 0, weightKg < 500 else { return }`.
  2. Bind both fields through `Stepper`/bounded `TextField` formatters with in-range clamps, and assert the bounds in `canSave`.

### [FINDING-02] HIGH: Free-text fields lack max-length cap
Lens: Security
Location: StackWise/Features/Onboarding/HealthProfileView.swift (save())
What went wrong: `allergiesText` and `conditionsText` are parsed via `Self.parseList(...)` and persisted with no max-length check on the raw input or the resulting array. Diff shows only an empty-check (`.isEmpty ? nil : ...`), no length cap.
Why it matters: Unbounded free-text persisted to Core Data can be abused to bloat storage, degrade fetch performance, and produce oversized payloads for any future export/sync. Per checklist, free-text inputs must enforce a non-empty check AND a max-length cap before persistence.
Possible solutions:
  1. Cap both inputs (e.g., 500 chars raw, 20 entries parsed) in `save()` before assignment.
  2. Add a `TextField`-level `.onChange` truncation plus a documented contract in `parseList`.

### [FINDING-03] HIGH: Test GREEN status cannot be verified from diff
Lens: Requirements
Location: StackWiseTests/OnboardingCoordinatorTests.swift
What went wrong: The diff for the test file shows only comment headers describing each test (`// Test 1:`, `// Test 2:`, ...) and a brief prose description of what each "asserts." No actual `func testXxx()` bodies, no `XCTAssert*` calls, and no removal of XCTFail stubs are visible in the diff. REQ-6 explicitly requires "all 5 tests pass GREEN, no XCTFail stubs remaining."
Why it matters: Per the operating constraint, only what is in the diff can be evaluated. The diff does not demonstrate that tests assert real behavior or that XCTFail stubs were removed — REQ-6 is therefore at best PARTIAL based on diff evidence.
Possible solutions:
  1. Include the full test bodies (setUp, Act, Assert) in the diff so REQ-6 can be confirmed.
  2. Attach a CI test-run log showing 5/5 GREEN as supplementary evidence; mark REQ-6 ⚠ until provided.

### [FINDING-04] MEDIUM: Silent `try?` on Core Data persistence
Lens: Code Quality
Location: StackWise/Features/Onboarding/HealthProfileView.swift (save()), StackWise/Features/Onboarding/ScheduleInputsView.swift (save())
What went wrong: Both `save()` methods use `try? context.save()`, silently discarding any Core Data error.
Why it matters: A failed save during onboarding means the user proceeds to the next step believing data was persisted, but the next step's smart-resume or downstream fetch will see nothing. The user then completes onboarding with partial state. Per checklist, `try?` on data persistence is a MEDIUM antipattern.
Possible solutions:
  1. Replace with `do { try context.save() } catch { /* log non-PII, surface user-facing error */ }`.
  2. Route saves through a `UserProfileStore.save(_:in:)` helper that throws and is handled at the call site.

### [FINDING-05] MEDIUM: Smart resume uses sentinel values that collide with defaults
Lens: Code Quality
Location: StackWise/Features/Onboarding/OnboardingCoordinatorView.swift (applySmartResume())
What went wrong: Step 1 detection uses `profile.age == 0 || profile.weightKg == 0` to mean "no profile data entered." But `HealthProfileView` initializes `age = 30` and `weightKg = 70` and persists those defaults if the user taps Next without changing anything (the diff does not show `canSave` rejecting defaults). The "no profile" branch will therefore never trigger after the user passes step 1 once, but more importantly, a freshly-created `UserProfile` from `fetchOrCreate` likely has `age=0` and `weightKg=0`, which is the intended signal — but this couples coordinator logic to model defaults rather than an explicit `hasCompletedHealthProfile` flag.
Why it matters: This is fragile — any change to default Int16/Double initialization (e.g., adding a migration that backfills age=18) silently breaks smart resume. D-07 should be driven by an explicit signal, not by detecting sentinel zeros.
Possible solutions:
  1. Add a boolean `healthProfileEntered` attribute on `UserProfile`, set explicitly in `HealthProfileView.save()`, and key step-1 detection off it.
  2. Use `profile.sex == nil` or another optional field genuinely unset by `fetchOrCreate` as the signal, and document the contract.

### [FINDING-06] MEDIUM: REQ-9 (D-13 trialStartDate guard) not directly verifiable in diff
Lens: Requirements
Location: StackWise/Features/Onboarding/OnboardingCoordinatorView.swift (completeOnboarding())
What went wrong: The coordinator calls `UserProfileStore.markOnboarded(profile, in: context)` and a comment claims "markOnboarded already guards trialStartDate == nil (REQ-19)." The implementation of `markOnboarded` is not in this diff. Test 5's prose claims to assert idempotency, but Test 5's body is also not in the diff.
Why it matters: Per the operating constraint, comments are not evidence. REQ-9 is marked ⚠ rather than ✓ because the guard cannot be observed in the diff.
Possible solutions:
  1. Include the `UserProfileStore.markOnboarded` implementation in the diff so the `trialStartDate == nil` guard is visible.
  2. Include Test 5's body so the idempotency assertion is reviewable.

## Requirements Compliance Table
| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | OnboardingCoordinatorView sequences HealthProfile → StackEntry → ScheduleInputs via NavigationStack push (REQ-18) | ✓ | NavigationStack with `path: [OnboardingStep]`, HealthProfile is root, two push destinations via `path.append`. |
| 2 | Coordinator presents OnboardingPreviewView as `.fullScreenCover` one-way gate (REQ-18) | ✓ | `.fullScreenCover(isPresented: $showPreview)` wraps OnboardingPreviewView. |
| 3 | PaywallPlaceholderView presented inside preview fullScreenCover with `interactiveDismissDisabled` (REQ-18) | ✓ | Nested `.fullScreenCover(isPresented: $showPaywall)` on the preview cover with `.interactiveDismissDisabled(true)`; PaywallPlaceholderView itself also sets `.interactiveDismissDisabled(true)`. |
| 4 | Smart resume D-07: infer step from Core Data on launch (REQ-18) | ⚠ | Logic present in `applySmartResume()`, but step-1 detection relies on sentinel zeros (FINDING-05). Behaviorally satisfies the four branches stated in the requirement. |
| 5 | completeOnboarding() calls markOnboarded then sets `appState.onboardingComplete = true` (REQ-19) | ✓ | Both calls present in `completeOnboarding()`. |
| 6 | OnboardingCoordinatorTests — all 5 tests pass GREEN, no XCTFail stubs remaining (REQ-18/REQ-19) | ⚠ | Diff shows only comment skeletons for 5 tests, not assertion bodies; GREEN status not verifiable from diff alone (FINDING-03). |
| 7 | ContentView gates TabView behind `appState.onboardingComplete` | ✓ | `Group { if appState.onboardingComplete { TabView } else { OnboardingCoordinatorView() } }`. |
| 8 | D-08: Hard minimum of 1 StackItem; Next disabled until items.count > 0 | ✓ | StackEntryStepView Next button `.disabled(items.isEmpty)`, plus `.opacity` cue. |
| 9 | D-13: Trial trigger fires exactly once — trialStartDate == nil guard (REQ-19) | ⚠ | Coordinator calls markOnboarded; guard is claimed in a comment but `markOnboarded` implementation is outside the diff (FINDING-06). |
| 10 | @Observable + .environment() only — no ObservableObject/@Published in new code | ✓ | All new views use `@Environment(AppState.self)`, `@Environment(AnalysisStore.self)`, `@Environment(ScheduleStore.self)`. No ObservableObject/@Published introduced in the diff. |
| 11 | UserProfileStore.fetchOrCreate is the only valid UserProfile writer | ✓ | HealthProfileView, ScheduleInputsView, OnboardingCoordinatorView all obtain profile via `UserProfileStore.fetchOrCreate(in: context)`. No `UserProfile(context:)` calls in diff. |

## Code Quality Summary
- `try? context.save()` used in two places — silently swallows persistence errors (see FINDING-04).
- `applySmartResume()` couples to model sentinel defaults rather than an explicit completion flag (see FINDING-05).
- `StackEntryStepView` uses `@FetchRequest` with a `predicate: NSPredicate(format: "isActive == YES")`; SwiftLint-style nit (LOW): prefer a typed key path or constant for the predicate string to avoid stringly-typed Core Data predicates — not a blocker.
- `OnboardingPreviewView.task` reads from two stores and writes two `@State` counts — fine, but consider a single computed view-model to avoid drift if stores update mid-presentation.
- No retain-cycle risk: closures (`onNext`, `onStartTrial`, `onComplete`) are value-type captures, no `self` capture in escaping contexts visible in the diff.
- No `@MainActor` issues: all code in the diff is SwiftUI View bodies, implicitly main-actor isolated.

## Security Summary
- HIGH: Numeric input validation missing on age/weight (FINDING-01).
- HIGH: Free-text max-length cap missing on allergies/conditions (FINDING-02).
- No Keychain/UserDefaults misuse observed in diff — no sensitive data written to UserDefaults; persistence is via Core Data which is acceptable for the data shown.
- No network code in diff — HTTPS/ATS rules not applicable here.
- No `print(...)`/`debugPrint`/`dump` of health data in diff — logging-PII rule not violated.
- No force unwraps, no `try!`, no hardcoded API keys in diff.
- No biometric/auth gates in diff — not applicable.

## Fix Prompt
You are fixing three HIGH findings in Phase 5 (Functional Onboarding). No CRITICAL findings exist. Work in order; commit each fix atomically.

**FIX-01 (HIGH, FINDING-01): Add numeric range validation in HealthProfileView**
- File: `StackWise/Features/Onboarding/HealthProfileView.swift`
- In `save()`, guard before any write: `guard age > 0, age < 120, weightKg > 0, weightKg < 500 else { return }`.
- Update `canSave` so the Next button is `.disabled` when these bounds fail, so the user sees the gate before tapping.
- Add a unit test in `StackWiseTests/HealthProfileViewTests.swift` (or extend existing) that calls a testable `save`/validator with age=0, age=200, weightKg=-1, weightKg=900 and asserts no Core Data write occurred.

**FIX-02 (HIGH, FINDING-02): Cap free-text length in HealthProfileView**
- File: `StackWise/Features/Onboarding/HealthProfileView.swift`
- Before persisting, truncate raw inputs: `let safeAllergies = String(allergiesText.prefix(500))`, same for conditions. Cap parsed array to 20 entries.
- Add `.onChange(of: allergiesText) { _, new in if new.count > 500 { allergiesText = String(new.prefix(500)) } }` on the TextField, same for conditions.
- Add a test that feeds a 10,000-char string and asserts persisted length ≤ 500 and parsed entries ≤ 20.

**FIX-03 (HIGH, FINDING-03): Ship full test bodies for OnboardingCoordinatorTests**
- File: `StackWiseTests/OnboardingCoordinatorTests.swift`
- Replace the five comment skeletons with real test methods. Each must:
  - Arrange state in the in-memory `context` (seed UserProfile fields and StackItems explicitly).
  - Act by invoking the same logic `applySmartResume()` uses (extract that logic into a pure helper `OnboardingCoordinatorView.resolveResume(profile:itemCount:) -> (path: [OnboardingStep], showPreview: Bool)` so it is unit-testable without SwiftUI).
  - Assert on returned `path` and `showPreview` values for each of the four resume branches, plus the markOnboarded idempotency case.
- Remove any `XCTFail("not implemented")` stubs.
- Run the test target and confirm 5/5 GREEN locally; attach the log to the phase summary.

**Verification steps after all three fixes:**
1. `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 15'` — all tests pass.
2. Manually run onboarding with deliberately invalid inputs (age=0, weight=0, 5000-char allergy string) and confirm Next stays disabled / inputs truncate.
3. Re-run this review against the new diff and confirm verdict becomes PASS or PASS WITH WARNINGS.

Do NOT change the FINDING-05 sentinel-zero smart-resume logic or FINDING-06 trialStartDate guard as part of this fix prompt — those are MEDIUM and out of scope for the FAIL-to-PASS gate.
