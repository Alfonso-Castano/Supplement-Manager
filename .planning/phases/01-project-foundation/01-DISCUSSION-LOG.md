# Phase 1: Project Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 01-CONTEXT.md — this log preserves the discussion.

**Date:** 2026-05-07
**Phase:** 01-project-foundation
**Mode:** discuss (interactive)
**Areas discussed:** iOS deployment target, Xcode project setup, state management pattern, app icon, navigation shell behavior during development

---

## Gray Areas Presented

The following areas were identified as unspecified by SPEC.md and presented for discussion. All other implementation details (Core Data entities, attribute schemas, bundle ID, app name, Core Data vs. SwiftData) were already locked by SPEC.md and were not re-asked.

---

## Q1 — iOS Deployment Target

**Question:** What's the minimum iOS deployment target?

**Options presented:**
| Option | Description |
|--------|-------------|
| iOS 17 | @Observable, NavigationStack, TipKit. Excludes ~15% of devices but covers all iPhones back to XS (2018). |
| iOS 16 | Wider coverage; no @Observable — ObservableObject required everywhere. |
| iOS 18 | Latest APIs but narrowest reach; SPEC flagged iOS 18 stability risk for SwiftData. |

**Decision:** iOS 17 minimum

---

## Q2 — Xcode Project Setup

**Question:** Create via Xcode GUI or XcodeGen + project.yml? (ROADMAP mentioned XcodeGen as a task item.)

**Options presented:**
| Option | Description |
|--------|-------------|
| Manual Xcode GUI | No extra tooling, simpler for solo dev. .xcodeproj is binary XML but not a problem for one developer. |
| XcodeGen + project.yml | Reproducible, version-control friendly. Requires brew install. Pays off for CI/CD or teams. |

**Decision:** Manual Xcode GUI

**User rationale:** Solo developer, no CI/CD pipeline, no team merge conflict concerns, first-time Xcode user, one-month ship target. XcodeGen's benefits don't apply here and the added tooling is pure friction.

---

## Q3 — State Management Pattern

**Question:** @Observable + .environment() (iOS 17) or ObservableObject + EnvironmentObject (iOS 15+)?

**Options presented:**
| Option | Description |
|--------|-------------|
| @Observable + .environment() | iOS 17+ macro. No @Published boilerplate, smarter updates, Apple's direction. |
| ObservableObject + EnvironmentObject | Works on iOS 15+. More verbose but more documented. Required if iOS 16 target. |

**Decision:** @Observable + .environment() throughout the entire app — all 9 remaining phases follow this convention.

**User rationale:** iOS 17 target is already set, so this is available with no tradeoffs. Less boilerplate, cleaner syntax, smarter view updates. Better pattern for a new Swift developer to learn since it's where Apple is heading and has less to get wrong.

---

## Q4 — App Icon

**Question:** Placeholder treatment for Phase 1? (Branding is officially deferred to Phase 9.)

**Options presented:**
| Option | Description |
|--------|-------------|
| Solid color placeholder | Single flat color fill — no artwork, no text. Meets criterion, commits to nothing. |
| SF Symbol icon | SF Symbol on colored background — more polished, still easily replaced. |
| Skip / use Xcode default | Default Xcode placeholder. Looks unfinished on simulator. |

**Decision:** Solid color placeholder

---

## Corrections Applied During Review

**Issue flagged by user:** D-05 as originally written (Core Data stack initialization) was a non-decision — it labeled itself "Claude's discretion" then immediately answered its own question. Redundant.

**Resolution:** Dropped D-05 as a numbered decision. PersistenceController singleton moved to Claude's Discretion as a concrete (not discretionary) call.

**Issue flagged by user:** The `UserProfile.onboardingComplete` / tabs-visible-during-development note was buried in `<specifics>` prose. Planner could miss it and create awkward tab gating during development.

**Resolution:** Promoted to explicit named decision D-05: all three tabs visible and navigable in Phase 1, no onboarding gate. Phase 5 adds the gate.

---

## Deferred Ideas

None raised during discussion.

---

## Items Left to Claude's Discretion

- Core Data stack: PersistenceController singleton pattern
- Launch screen: colored background matching placeholder icon
- Tab bar icon symbols (SF Symbols)
- Swift file/folder structure
