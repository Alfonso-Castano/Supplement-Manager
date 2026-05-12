# Phase 1: Project Foundation - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the Xcode project with bundle ID com.stackwise.app, Core Data schema (5 entities per SPEC.md data model), three-tab navigation shell (Stack / Today / Schedule), and basic app icon. No feature logic — only the skeleton that all subsequent phases build on.

</domain>

<decisions>
## Implementation Decisions

### iOS Deployment Target
- **D-01:** Minimum deployment target is **iOS 17**
  - Rationale: Enables @Observable macro, SwiftUI Navigation APIs (NavigationStack), TipKit. Covers all modern iPhones back to iPhone XS (2018). Solo dev, one-month timeline — no reason to carry iOS 16 compatibility burden.

### Xcode Project Setup
- **D-02:** Create the Xcode project **manually via Xcode GUI** — do NOT use XcodeGen or any project generation tooling
  - Rationale: Solo developer, no CI/CD pipeline, no team merge conflicts, first-time Xcode user, one-month ship target. XcodeGen's benefits don't apply; it adds tooling friction with no payoff.
  - Note: GUI runs on cloud Mac rental — not local machine (D-21).

### State Management Pattern
- **D-03:** Use **@Observable macro + .environment()** for all state management throughout the app. Do NOT use ObservableObject or @Published.
  - This convention applies to all 9 remaining phases — when Phase 2+ add ViewModels or service objects, they use @Observable.
  - Rationale: iOS 17 target is set so no tradeoff. Less boilerplate, fine-grained view updates, Apple's forward direction. Better pattern for a new Swift developer since there's less to get wrong.

### App Icon
- **D-04:** Solid color placeholder icon — single flat color fill, no artwork, no text. Replace in Phase 9 with real branding.
  - Rationale: Meets the Phase 1 success criterion; commits to nothing visually; takes 5 minutes.

### Navigation Shell Behavior During Development
- **D-05:** During Phase 1, all three tabs (Stack / Today / Schedule) are always visible and navigable — **no onboarding gate in this phase**. Phase 5 wires `UserProfile.onboardingComplete` to hide tabs on first launch. Building without the gate means all three tabs are reachable during development of Phases 2–4.

### Development Environment
- **D-21:** Developer is on Windows 11 — Xcode cannot run locally. Cloud Mac rental (MacInCloud or equivalent, ~$1/hr) is required for all Xcode GUI tasks: project creation, Core Data schema definition, xcodebuild runs, and simulator verification. All Swift file writing, asset generation, and plist editing is done on Windows. Git is the bridge between environments (Windows pushes, cloud Mac pulls; cloud Mac pushes updated .pbxproj after adding files to Xcode target). This constraint also applies to Phase 9 (TestFlight upload, code signing, App Store submission).
  - See: `CLOUD-MAC-WORKFLOW.md` in this directory for the task split and git bridge workflow.

### Claude's Discretion
- Core Data stack: PersistenceController singleton (standard Xcode template pattern), shared via .environment(\.managedObjectContext) — not revisited
- Launch screen: simple colored background matching placeholder icon
- Tab bar icons: SF Symbols (e.g. pill, calendar, clock.fill)
- Swift file/folder structure within the Xcode project

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product specification
- `SPEC.md` §Data Model — Full Core Data schema: all 5 entities, all attributes, types, relationships, and design notes. Planner MUST implement exactly this schema — do not invent attributes.
- `SPEC.md` §Navigation — Three bottom tabs; Stack tab has two sub-pages via top nav (Stack list + Analysis screen)
- `SPEC.md` §Data & Architecture — Core Data confirmed, SwiftData explicitly excluded, SQLite is read-only bundle asset

### Phase 0 output (database dependency)
- `database/stackwise.sqlite` — Production-ready SQLite database (63 interactions, 70 ingredients). Bundled as read-only app asset in Phase 3, but schema must be understood now for Core Data ↔ SQLite bridge design (StackItem.activeIngredient ↔ ingredients.canonical_name)

### Requirements
- `.planning/REQUIREMENTS.md` — REQ-06, REQ-07, REQ-08 define the Phase 1 acceptance criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No reusable Swift assets exist yet — Phase 1 is the first iOS code in the project
- `database/stackwise.sqlite` (77 KB) — Schema: interactions table (63 records) + ingredients table (70 compounds with timing_properties JSON blob) + metadata table. Ready to bundle as a read-only Xcode resource in Phase 3.

### Established Patterns
- None yet — Phase 1 establishes the codebase conventions that all subsequent phases follow
- The @Observable + .environment() pattern (D-03) IS the founding convention; all future phases must follow it

### Integration Points
- Core Data ↔ SQLite bridge: `StackItem.activeIngredient` (String) maps to `ingredients.canonical_name` and `interactions.compound_a`/`compound_b`. Phase 3 implements the live bridge; Phase 1 only needs the Core Data schema attributes to be correct.
- `UserProfile.onboardingComplete` (Boolean) will gate tab navigation in Phase 5. Phase 1 leaves tabs ungated for development convenience (D-05).

</code_context>

<specifics>
## Specific Ideas

- User is a first-time Xcode/Swift developer — Phase 1 should set clean, learnable patterns, not clever abstractions
- One-month ship target — avoid over-engineering the skeleton; get to a building green light as fast as possible
- @Observable is Apple's forward direction; starting with it now avoids a migration in Phase 4–9

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 1 scope.

</deferred>

---

*Phase: 01-project-foundation*
*Context gathered: 2026-05-07*
