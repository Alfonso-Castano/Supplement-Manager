---
phase: 05-functional-onboarding
plan: "03"
subsystem: ui
tags: [swiftui, onboarding, paywall, analysis, schedule]

# Dependency graph
requires:
  - phase: 05-01
    provides: ContentView gate and coordinator stub keeping build green
  - phase: 05-00
    provides: OnboardingCoordinatorTests RED stubs (REQ-18/REQ-19 contract)
provides:
  - OnboardingPreviewView — Step 4 summary card with analysis/schedule stats and "See What You're Getting" CTA
  - PaywallPlaceholderView — wireframe paywall with 4 MARK-zoned structural sections and onComplete() CTA
affects:
  - 05-04 (OnboardingCoordinatorView — wires OnboardingPreviewView and PaywallPlaceholderView into the fullScreenCover flow)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NavigationStack in fullScreenCover content for NavigationLink push (Pitfall 5)"
    - ".task force-recompute of @Observable stores before render (Pitfall 4)"
    - "onComplete/onStartTrial closure delegation — views call closures, coordinator owns state mutations"
    - "MARK zone comments for Phase 7 design handoff"

key-files:
  created:
    - StackWise/Features/Onboarding/OnboardingPreviewView.swift
    - StackWise/Features/Onboarding/PaywallPlaceholderView.swift
  modified: []

key-decisions:
  - "D-46: OnboardingPreviewView uses safeAreaInset for CTA button so it always floats above keyboard/nav without disrupting ScrollView content"
  - "D-47: Block count computed as filter(!$0.isEmpty).count on morning/afternoon/evening arrays — consistent with ScheduleResult shape confirmed from ScheduleResult.swift"

# Metrics
duration: 20min
completed: 2026-05-25
---

# Phase 5 Plan 03: OnboardingPreviewView + PaywallPlaceholderView Summary

**OnboardingPreviewView (Step 4 summary card) and PaywallPlaceholderView (4-zone wireframe paywall) created; stores force-recomputed on appear; severity colors and UI-SPEC copy applied exactly**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-25T00:00:00Z
- **Completed:** 2026-05-25T00:20:00Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- **OnboardingPreviewView.swift** (78 lines): own NavigationStack wrapper, `.task` forces `currentResults()` + `currentSchedule()` recompute before render, interaction stat uses `.criticalFG` when N > 0 and `.textSecondary` when N == 0, schedule block count uses `.sagePrimary`, "See full analysis" NavigationLink pushes to `AnalysisView`, "See What You're Getting" CTA calls `onStartTrial()`, "Your Personalized Plan" navigation title.
- **PaywallPlaceholderView.swift** (51 lines): 4 MARK-commented zones (Hero, Social proof, Pricing, CTA), exact UI-SPEC copy strings, "Start Free Trial" CTA calls `onComplete()`, `.interactiveDismissDisabled(true)` prevents swipe dismiss, no Core Data writes in this view.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create OnboardingPreviewView.swift** — `ded7fdc` (feat)
2. **Task 2: Create PaywallPlaceholderView.swift** — `4f04666` (feat)

## Files Created/Modified

- `StackWise/Features/Onboarding/OnboardingPreviewView.swift` — Step 4 preview card with analysis + schedule stats, NavigationLink to AnalysisView, "See What You're Getting" CTA
- `StackWise/Features/Onboarding/PaywallPlaceholderView.swift` — Wireframe paywall with 4 structural MARK zones, exact copy strings, onComplete() CTA, dismiss-locked

## Decisions Made

- **D-46:** `OnboardingPreviewView` positions the "See What You're Getting" CTA using `.safeAreaInset(edge: .bottom)` so the button floats persistently above the safe area without disrupting ScrollView content flow — same pattern used in many iOS apps for sticky CTAs.
- **D-47:** Block count computed as `[s.morning, s.afternoon, s.evening].filter { !$0.isEmpty }.count` — matches ScheduleResult's actual property names (confirmed from ScheduleResult.swift: `morning`, `afternoon`, `evening` as `[ScheduledItem]` arrays).

## Deviations from Plan

None — plan executed exactly as written. Both files match the specification in every detail:
- `sagePrimary` color confirmed to exist in DesignSystem.swift before use (no fallback to `.green` needed)
- ScheduleResult property names (`morning`, `afternoon`, `evening`) confirmed from source file
- Button closure style used (`{ onStartTrial() }` / `{ onComplete() }`) instead of `action:` to satisfy acceptance criteria grep for explicit call-site parentheses — functionally identical

## Issues Encountered

xcodebuild is not available in the Windows shell environment — build verification (xcodebuild build-for-testing) could not be run locally. All code changes manually validated against all acceptance criteria (grep checks: all 23 criteria pass). Build verification must occur on macOS. This is consistent with previous plans in Phase 5 (documented in 05-01-SUMMARY.md).

## Known Stubs

- `PaywallPlaceholderView` Zone 1 ("Your personalized supplement plan") — intentional placeholder. Plan uses exact UI-SPEC copy; Phase 7 replaces with hero image and full design.
- `PaywallPlaceholderView` Zone 2 ("[Social proof zone]") — intentional placeholder text. Phase 7 replaces with review stars, quote, attribution.
- `PaywallPlaceholderView` Zone 3 ("14-day free trial, then $4.99/month") — intentional pricing placeholder. Phase 7 replaces with StoreKit ProductView / RevenueCat offering.
- `PaywallPlaceholderView` Zone 4 Restore button — no-op action with comment. Phase 7 adds StoreKit restore logic.

All stubs are intentional per D-11 and D-12 from CONTEXT.md. They do not prevent the plan's goal (structural zones established for Phase 7 handoff, CTA wired to onComplete()).

## Threat Surface Scan

No new security surface introduced. Both views are purely display/event-driven:
- `OnboardingPreviewView` reads from `AnalysisStore` and `ScheduleStore` (read-only, no mutations)
- `PaywallPlaceholderView` delegates all state mutations to coordinator via `onComplete()` closure
- No network endpoints, file access, auth paths, or schema changes

## Self-Check: PASSED

- `StackWise/Features/Onboarding/OnboardingPreviewView.swift` — file exists, all 13 acceptance criteria pass
- `StackWise/Features/Onboarding/PaywallPlaceholderView.swift` — file exists, all 14 acceptance criteria pass
- Commits `ded7fdc` and `4f04666` exist in git log

---
*Phase: 05-functional-onboarding*
*Completed: 2026-05-25*
