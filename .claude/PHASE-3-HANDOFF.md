# StackWise — Phase 3 Discussion Handoff

## What you are

You are the StackWise development agent. You are starting the **discussion phase for Phase 3**. Before discussing Phase 3, run the **review skill** on the Phase 2 deliverables listed below to confirm the current state, then proceed to the Phase 3 discussion.

## Project overview

StackWise is an iOS supplement and medication management app. The core feature — and the product's differentiator — is a local interaction analysis engine that cross-references a user's supplement/medication stack and flags conflicts, timing issues, and unsafe combinations.

**Phase 3 is where that differentiator gets built.** Phases 1 and 2 produced the skeleton; Phase 3 makes the app actually do its job.

## Locked decisions (do not re-discuss)

- iOS deployment target: **iOS 17 minimum**
- Xcode project: manual GUI creation (no XcodeGen)
- State management: **`@Observable` + `.environment()` throughout** — NO `ObservableObject` / `@Published` for app-owned types (Apple's `NSManagedObject` via `@ObservedObject` is the accepted exception)
- Storage: **Core Data** for user data, **SQLite read-only** for interaction DB — NO SwiftData
- App name: StackWise, bundle ID: `com.stackwise.app`
- Navigation: TabView with 3 bottom tabs — Stack / Today / Schedule
- SQLite access: **Raw SQLite3 C API** wrapped in `@Observable final class` — no GRDB, no FMDB
- Development workflow: code written on Windows in VS Code with Claude Code, Mac used only for Xcode GUI tasks and build verification; git is the bridge

## Phases 1 + 2 — What is already built

### Phase 1 (complete, reviewed PASS)

- Xcode 26.5 project, bundle ID `com.stackwise.app`, iOS 17.6 minimum, XCTest target
- Core Data schema in [StackWise/StackWise.xcdatamodeld/StackWise.xcdatamodel/contents](StackWise/StackWise.xcdatamodeld/StackWise.xcdatamodel/contents):
  - 5 entities: `UserProfile`, `StackItem`, `ScheduledDose`, `DailyCheckOff`, `FeedbackItem`
  - All entities have `codeGenerationType="none"` directly in XML
  - All `NSManagedObject` subclasses have `@objc(EntityName)` and are written manually
  - StackItem ↔ ScheduledDose has cascade delete
- Navigation shell: TabView with 3 tabs, all always visible
- `AppState` is `@Observable`, injected via `.environment(appState)`
- 7/7 `CoreDataSchemaTests` passing

### Phase 2 (complete, reviewed PASS WITH WARNINGS)

Files added or modified:

- [StackWise/Data/IngredientRepository.swift](StackWise/Data/IngredientRepository.swift) — `@Observable final class`, opens `stackwise.sqlite` read-only via `sqlite3_open_v2`, exposes `search(_:limit:) -> [IngredientMatch]` matching `canonical_name` OR `aliases` with `LIKE NOCASE`. Prefix matches rank above substring matches.
- [StackWise/Models/UserProfileStore.swift](StackWise/Models/UserProfileStore.swift) — `enum` helper with `fetchOrCreate(in:)` (singleton with `fetchLimit=1`, creates on first launch with `onboardingComplete=false`) and `markOnboarded(_:in:)` (also stamps `trialStartDate`).
- [StackWise/Features/Onboarding/HealthProfileView.swift](StackWise/Features/Onboarding/HealthProfileView.swift) — Form collecting age, sex, weight, wake/sleep/breakfast/lunch/dinner times, allergies, conditions. Save writes to the `UserProfile` singleton and flips `appState.onboardingComplete`.
- [StackWise/ContentView.swift](StackWise/ContentView.swift) — TabView unchanged; adds `.task` that hydrates `appState.onboardingComplete` from Core Data, and `.sheet` bound to `!appState.onboardingComplete` presenting `HealthProfileView`. Source of truth for onboarding: Core Data `UserProfile.onboardingComplete` (permanent); AppState mirrors it at launch.
- [StackWise/Features/Stack/AddItemView.swift](StackWise/Features/Stack/AddItemView.swift) — Form with debounced (200 ms) auto-suggest powered by `IngredientRepository.search`. Tapping a suggestion locks in `canonicalName`. Saving without a match stores the raw user input and flags `isInDatabase = false`.
- [StackWise/Features/Stack/StackItemFactory.swift](StackWise/Features/Stack/StackItemFactory.swift) — pure helper that builds and saves a `StackItem` from form input. Extracted from the view so field invariants are unit-testable without SwiftUI.
- [StackWise/Features/Stack/StackListView.swift](StackWise/Features/Stack/StackListView.swift) — `@FetchRequest` on `StackItem` filtered to `isActive == YES`, sorted by `sortOrder` ascending. Renders rows with label, dosage, type badge (drug=red, supplement=blue), and an orange warning icon for `isInDatabase == false`. NavigationStack toolbar "+" presents `AddItemView`. Empty state uses `ContentUnavailableView`. No edit/delete UI (out of scope for Phase 2).
- [StackWise/StackWiseApp.swift](StackWise/StackWiseApp.swift) — now injects `appState`, `ingredientRepo`, and `\.managedObjectContext`.
- [StackWise/stackwise.sqlite](StackWise/stackwise.sqlite) — 77 KB bundled DB, 70 ingredients + 63 interactions, registered in Copy Bundle Resources.

Test files (all in [StackWiseTests/](StackWiseTests/)):
- `CoreDataSchemaTests.swift` (Phase 1, 7 tests)
- `IngredientRepositoryTests.swift` (5 tests, including a dynamic alias-discovery test)
- `UserProfileStoreTests.swift` (4 tests including idempotency)
- `StackItemFactoryTests.swift` (5 tests covering matched/unmatched/prescription/match-wins/sortOrder)

**Total: 21 tests passing.**

### Phase 2 review — carry-forward items (not blockers)

The Phase 2 review flagged two minor items and several incidental findings. None are bugs; they are stylistic cleanups to fold in when those files are next touched in Phase 3 or later:

1. **REQ-11 warning** — `.interactiveDismissDisabled(true)` is applied inside `HealthProfileView` (line 67) rather than on the `.sheet` modifier in [ContentView.swift](StackWise/ContentView.swift). Functionally equivalent; literal-reading nit.
2. **REQ-22 warning** — `StackItemRow` (private struct in StackListView.swift) uses `@ObservedObject var item: StackItem`. This is idiomatic SwiftUI for `NSManagedObject` (which conforms to `ObservableObject` automatically), but the project's locked decision prefers Observation framework. Leave as-is for now — the alternative requires bridging `NSManagedObject` change notifications into `@Observable`, which is overkill for a row that just reads scalar fields.
3. **ContentView.swift:8** — `@Bindable var appState = appState` is declared but unused. Dead line — remove next time ContentView is edited.
4. **ContentView.swift:30-33** — the `.sheet` Binding's setter is a deliberate no-op (dismissal is driven by the save action). Worth a one-line comment next time the file is touched.
5. **AddItemView.swift:34-41** — `onChange` clear-selection logic uses nested optional + double negation that is hard to read. Functionally correct based on the StackItemFactoryTests, but could be simplified.
6. **IngredientRepository.swift:33** — `deinit` calls `sqlite3_close(db)`; `sqlite3_close_v2` is preferred. Not a bug because all prepared statements are finalized via `defer` in `search`.

## Hard-won lessons from prior phases — DO NOT RE-LEARN

1. **Xcode 26 auto-generates Core Data classes despite Manual/None GUI setting.** Fix: `codeGenerationType="none"` lives directly in the .xcdatamodeld XML. All 5 entities already have it. Do not remove.
2. **Reserved property names crash NSManagedObject subclasses.** Forbidden attribute names: `type`, `context`, `date`, `description`, `entity`, `objectID`, `managedObjectContext`. Past renames in the schema: `feedbackType`, `feedbackContext`, `checkOffDate`. Phase 3 must not introduce new attributes that violate this list.
3. **The model XML has corrupted multiple times during edits.** If Phase 3 modifies the schema, write the whole file at once and verify with `grep "codeGenerationType" contents` after the edit.
4. **Xcode 26 auto-includes Swift files it finds in the project folder.** After adding new files on Mac, verify Build Phases → Compile Sources shows each file exactly once for both `StackWise` and `StackWiseTests` targets.
5. **Two copies of the SQLite DB exist** — `database/stackwise.sqlite` (source artifact) and `StackWise/stackwise.sqlite` (bundled into the app). The bundled one is what the app reads. They will drift if the DB is ever regenerated. Out of scope to fix in Phase 3, but flag if you regenerate the DB.

## Current file structure (top-level summary)

```
StackWise/
  Data/
    IngredientRepository.swift       ← SQLite read access
  Models/
    AppState.swift                   ← @Observable runtime state
    UserProfileStore.swift           ← Core Data singleton helper
    UserProfile+CoreDataClass.swift
    StackItem+CoreDataClass.swift
    ScheduledDose+CoreDataClass.swift
    DailyCheckOff+CoreDataClass.swift
    FeedbackItem+CoreDataClass.swift
  Features/
    Stack/
      StackListView.swift            ← @FetchRequest list, "+" toolbar
      AddItemView.swift              ← form + auto-suggest
      StackItemFactory.swift         ← testable Core Data write helper
      AnalysisView.swift             ← placeholder for Phase 3
    Today/
      TodayView.swift                ← placeholder
    Schedule/
      ScheduleView.swift             ← placeholder
    Onboarding/
      HealthProfileView.swift        ← modal sheet
  Assets.xcassets/
  ContentView.swift                  ← TabView + onboarding sheet
  Persistence.swift                  ← NSPersistentContainer
  StackWiseApp.swift                 ← @main, injects state + repo + context
  StackWise.xcdatamodeld/            ← Core Data model (do not edit unless needed)
  stackwise.sqlite                   ← bundled read-only ingredient DB
StackWiseTests/
  CoreDataSchemaTests.swift
  IngredientRepositoryTests.swift
  UserProfileStoreTests.swift
  StackItemFactoryTests.swift
  StackWiseTests.swift               ← default scaffolding
StackWiseUITests/
database/
  stackwise.sqlite                   ← source-of-truth copy (not bundled directly)
```

## Phase 3 scope — Interaction Analysis Engine

From [.planning/ROADMAP.md](.planning/ROADMAP.md):

**Goal:** Implement the pairwise lookup engine, severity classification, and the full analysis screen using the already-bundled `stackwise.sqlite`.

**Success criteria:**
1. `stackwise.sqlite` bundled as app asset; opens read-only at launch — **already done in Phase 2 via `IngredientRepository`**, so Phase 3 likely needs a second repository (`InteractionRepository`) targeting the `interactions` table.
2. Pairwise lookup returns all flagged pairs for a given stack; runs on every stack change.
3. Severity classification returns advisory / critical correctly per database records.
4. Analysis screen groups results: critical → advisory → positive insights → not-in-database.
5. Inline badges on stack item cards reflect current analysis state.

## Bundled DB — `interactions` table (known)

From the Phase 0 build artifacts (`research/scripts/stage3_compile.py` and `.planning/phases/00-database-build/00-04-SUMMARY.md`):

- `interactions` table: 63 rows. Columns include `compound_a`, `compound_b`, `interaction_type`, `severity`, `effect`, `suggested_action`, `citations`, `confidence`, plus a `conflict_note` column where source severities disagreed.
- `ingredients` table: 70 rows, already used by `IngredientRepository`. Columns: `id`, `canonical_name`, `item_type`, `aliases` (JSON), `category`, `timing_properties` (JSON).
- `metadata` table: 1 row, `db_version` + `date_built`.
- Compound matching in `interactions` uses `canonical_name` strings, which matches the `activeIngredient` Phase 2 writes to each `StackItem` whenever the item was matched against the DB. Items with `isInDatabase = false` will never appear in pairwise results — Phase 3 must surface them in the "not-in-database" group on the analysis screen.

## Gray areas to surface during Phase 3 discussion

Bring these up before planning. Do NOT pre-decide them.

1. **`InteractionRepository` design** — second `@Observable` class opening the same `stackwise.sqlite` file? Or extend `IngredientRepository`? Single source of `OpaquePointer` is cleaner; two repositories duplicate connection state.
2. **When does analysis run?** Every stack mutation (eager), on-demand when the user opens the analysis tab (lazy), or both via cache invalidation?
3. **Where do results live?** Pure in-memory `@Observable` model, or persisted to Core Data for offline-after-launch consistency? Affects whether `AnalysisResult` needs an entity.
4. **Analysis screen placement** — the current TabView has 3 tabs (Stack / Today / Schedule). The roadmap mentions an "analysis screen" but does not specify whether it is its own tab, a sheet over Stack, or a NavigationStack push from Stack. There is already a [StackWise/Features/Stack/AnalysisView.swift](StackWise/Features/Stack/AnalysisView.swift) placeholder under Stack — suggesting it may live there.
5. **Severity classification rules** — "critical" and "advisory" terms come from the roadmap; verify they match the `severity` values actually present in the DB (likely "high"/"medium"/"low" or similar). Run a quick `SELECT DISTINCT severity FROM interactions` mentally before proposing the mapping.
6. **"Positive insights"** — the roadmap mentions grouping results into critical / advisory / positive / not-in-database. What is a positive insight in this DB? Verify whether the `interactions` table has rows where `interaction_type` indicates a beneficial pairing (e.g., synergy) or whether positives are derived elsewhere.
7. **Plan granularity** — likely 3 or 4 sub-plans for Phase 3: (a) InteractionRepository + tests, (b) pairwise analysis engine + tests, (c) AnalysisView UI + grouping, (d) inline badges on stack rows. Confirm with the user before locking.

## Mac ↔ Windows workflow

All Swift writing on Windows. Mac is used only for:
- Adding new `.swift` files to the Xcode target (File → Add Files to "StackWise")
- Running `xcodebuild test` and simulator verification
- Any Xcode GUI actions

The user prefers **batching Mac handoffs** when plans are independent (see Phase 2 history) — write all plans on Windows, then one Mac verification at the end. Confirm whether to batch or per-plan during the discussion.

## Phase 2 review instructions (run this first)

Before discussing Phase 3, run the **review** skill against these files to confirm the current state matches what this handoff claims:

```
StackWise/Data/IngredientRepository.swift
StackWise/StackWiseApp.swift
StackWise/Models/AppState.swift
StackWise/Models/UserProfileStore.swift
StackWise/Features/Onboarding/HealthProfileView.swift
StackWise/ContentView.swift
StackWise/Features/Stack/AddItemView.swift
StackWise/Features/Stack/StackItemFactory.swift
StackWise/Features/Stack/StackListView.swift
StackWise/StackWise.xcdatamodeld/StackWise.xcdatamodel/contents
StackWiseTests/IngredientRepositoryTests.swift
StackWiseTests/UserProfileStoreTests.swift
StackWiseTests/StackItemFactoryTests.swift
```

Key things to verify:
- All 24 Phase 2 requirements from the prior review still hold (see the prior plan file at `C:\Users\alfon\.claude\plans\stackwise-phase-2-lovely-bachman.md`)
- No new `ObservableObject` types of our own were introduced (Apple's `NSManagedObject` via `@ObservedObject` is the documented exception)
- `stackwise.sqlite` is still in `Copy Bundle Resources`
- The `.xcdatamodeld` still has all 5 entities with `codeGenerationType="none"` and no reserved-name attributes

After the review, surface any findings, then proceed to the Phase 3 discussion using the gray areas above as the opening question set.

## Git state at handoff

- Branch: `main`
- HEAD: `37a5d7c feat(02-04): stack list with live Core Data fetch`
- Remote: `https://github.com/Alfonso-Castano/Supplement-Manager.git` — in sync
- Working tree: clean

## What to do first

1. Read [.claude/CLAUDE.md](.claude/CLAUDE.md) and [.claude/lessons.md](.claude/lessons.md) for current workflow rules.
2. Run the review skill on the Phase 2 file list above.
3. Open the Phase 3 discussion. Use the **Gray areas** section to drive the question set. Do not pre-commit to any of those decisions before the user weighs in.
4. Write the Phase 3 plan to your plan file path. Get the user's approval via `ExitPlanMode` before any Swift is written.
