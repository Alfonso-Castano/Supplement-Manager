# CLAUDE_MAC_INSTRUCTIONS.md

This file is designed to be read by Claude Code running on macOS. It provides all context needed to autonomously set up, build, test, and verify the StackWise iOS project.

---

## 1. Project Overview

**StackWise** is an iOS supplement and medication management app built with SwiftUI and Core Data. Its core differentiator is a drug/supplement interaction analysis engine backed by a bundled SQLite database.

### Architecture

- **UI Layer:** SwiftUI with a 3-tab layout (Stack, Today, Schedule)
- **Data Layer:** Core Data for user state (UserProfile, StackItem, ScheduledDose, DailyCheckOff, FeedbackItem) + bundled read-only SQLite database (`stackwise.sqlite`) for ingredient/interaction reference data
- **SQLite Access:** Raw `sqlite3` C API (no GRDB, no FMDB). Two repository classes open read-only handles:
  - `IngredientRepository` — ingredient search + timing properties lookup
  - `InteractionRepository` — pairwise interaction queries
- **Stores:** `@Observable` classes with dirty-flag invalidation pattern:
  - `AnalysisStore` — interaction analysis (Phase 3)
  - `ScheduleStore` — smart scheduling (Phase 4)
- **Schedule Engine:** Pure `enum ScheduleEngine` with a static `schedule(input:)` method. 4 priority rules: (1) prescriptions lock first, (2) timing-conflict separation, (3) timing properties (food/empty stomach/preferred time), (4) default morning + overflow at 5-item block cap
- **Onboarding:** Single-screen `HealthProfileView` that creates a `UserProfile` singleton in Core Data. App presents it as a sheet until `onboardingComplete == true`.
- **Minimum Deployment Target:** iOS 17.0
- **Swift Language Version:** Swift 5 (default Xcode 16.2 toolchain)

### Current State

- **Phases 0-4 complete** (database build, project foundation, stack management, interaction analysis, smart schedule)
- **Phase 4 is awaiting Mac verification** — all code is written and committed, but build/test/simulator verification has not been run yet
- The project has **no Swift Package dependencies** — everything is built-in
- The bundled SQLite database at `StackWise/stackwise.sqlite` contains ~130 ingredients and ~200 interaction pairs

### Known Code Review Issues (from Phase 4 review, non-blocking for verification)

These are documented issues that do NOT need to be fixed before verification. They are informational:

1. **CR-01:** LIKE pattern wildcards (`%`, `_`) in user input are not escaped in `IngredientRepository.search()`. Not a crash risk — parameterized binding prevents SQL injection — but `%` or `_` in search text matches too broadly.
2. **CR-02:** `try? ctx.save()` in `ScheduleStore.recompute()` silently swallows Core Data save failures.
3. **CR-03:** `ScheduleView.schedule` computed property may trigger `recompute()` inside SwiftUI body evaluation (should use `.task` instead).

---

## 2. Environment Context

- **OS:** macOS Sonoma 14.8.7 running in VMware Workstation Pro 26H1 on Windows 11
- **Xcode:** 16.2 installed at `/Applications/Xcode.app`
- **Project location:** `~/Documents/Supplement-Manager`
- **Node.js + Claude Code:** Installed via Homebrew
- **Git:** Configured and authenticated with GitHub
- **Apple Developer Account:** The human has an Apple Developer account and will handle signing tasks manually

---

## 3. Xcode Configuration Tasks

### What Claude Code can verify/do via command line

1. **Verify the project file exists:**
   ```bash
   ls ~/Documents/Supplement-Manager/StackWise.xcodeproj/project.pbxproj
   ```

2. **Verify the deployment target is iOS 17.0:**
   ```bash
   grep -i "IPHONEOS_DEPLOYMENT_TARGET" ~/Documents/Supplement-Manager/StackWise.xcodeproj/project.pbxproj | head -5
   ```

3. **Verify the bundled SQLite database is present:**
   ```bash
   ls -la ~/Documents/Supplement-Manager/StackWise/stackwise.sqlite
   ```

4. **Check the Xcode build settings:**
   ```bash
   cd ~/Documents/Supplement-Manager && xcodebuild -project StackWise.xcodeproj -scheme StackWise -showBuildSettings 2>/dev/null | grep -E "(PRODUCT_BUNDLE_IDENTIFIER|DEVELOPMENT_TEAM|CODE_SIGN|SWIFT_VERSION|IPHONEOS_DEPLOYMENT_TARGET)"
   ```

5. **List all targets:**
   ```bash
   cd ~/Documents/Supplement-Manager && xcodebuild -project StackWise.xcodeproj -list
   ```

### File synchronization (important)

The project uses **`PBXFileSystemSynchronizedRootGroup`** for the `StackWise/` source directory. This means new `.swift` files added to the filesystem are **automatically included** in the Xcode target — no manual "Add to Target" step is needed.

### What requires human interaction

- **[HUMAN REQUIRED] Signing & Capabilities:** The human must open Xcode, go to the StackWise target > Signing & Capabilities, and:
  1. Check "Automatically manage signing"
  2. Select their Team from the dropdown
  3. Verify the Bundle Identifier is set (e.g., `com.yourname.StackWise`)
  
  This cannot be done from the command line because it requires Apple ID authentication.

### No Swift Package Dependencies

This project has **zero** Swift package dependencies. There is no `Package.resolved` or SPM manifest. All code uses Apple frameworks only (SwiftUI, CoreData, Foundation, SQLite3).

---

## 4. Build and Run Instructions

### Prerequisites check

```bash
# Verify Xcode command line tools
xcode-select -p
# Expected: /Applications/Xcode.app/Contents/Developer

# Verify Xcode version
xcodebuild -version
# Expected: Xcode 16.2 (or similar)

# Verify available simulators
xcrun simctl list devices available | grep "iPhone 16"
```

### Clean build

```bash
cd ~/Documents/Supplement-Manager
xcodebuild clean \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Build only (no tests)

```bash
cd ~/Documents/Supplement-Manager
xcodebuild build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Build and run tests

```bash
cd ~/Documents/Supplement-Manager
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Expected result:** >= 48 tests passing (36 from Phases 1-3 + 12 from Phase 4), 0 failures.

### If "iPhone 16" simulator is not available

Try listing what is available and pick the closest match:
```bash
xcrun simctl list devices available | grep iPhone
```

Then substitute the device name in the `-destination` flag, e.g.:
```bash
-destination 'platform=iOS Simulator,name=iPhone 15'
```

### VM-specific notes

- The iOS Simulator should work in VMware with hardware acceleration enabled
- If you see `Metal` errors, try a non-Pro iPhone simulator (e.g., iPhone SE) which uses less GPU
- If the simulator fails to boot, try:
  ```bash
  xcrun simctl shutdown all
  xcrun simctl erase all
  ```

---

## 5. Apple Developer Account Tasks

These ALL require human interaction. Claude Code cannot perform any of these.

### [HUMAN REQUIRED] Step 1: Sign in to Xcode with Apple ID

1. Open **Xcode** (double-click `/Applications/Xcode.app` or run `open /Applications/Xcode.app`)
2. Go to **Xcode > Settings** (Cmd+,)
3. Click the **Accounts** tab
4. Click the **+** button in the bottom-left corner
5. Select **Apple ID**
6. Enter your Apple ID email and password
7. Complete any 2FA prompts

### [HUMAN REQUIRED] Step 2: Configure Signing for StackWise target

1. In Xcode, open `StackWise.xcodeproj` (File > Open > navigate to `~/Documents/Supplement-Manager/StackWise.xcodeproj`)
2. In the left sidebar, click the **StackWise** project (blue icon at the top)
3. Select the **StackWise** target (not the test target)
4. Click the **Signing & Capabilities** tab
5. Check **Automatically manage signing**
6. From the **Team** dropdown, select your personal team or developer account
7. If the Bundle Identifier field is empty, set it to something like `com.yourname.StackWise`
8. Xcode should show a green checkmark if signing is configured correctly

### [HUMAN REQUIRED] Step 3: Configure Signing for StackWiseTests target

1. Same as above but select the **StackWiseTests** target
2. Enable **Automatically manage signing**
3. Select the same **Team**

### Notes

- **Provisioning profiles** are automatically managed by Xcode when "Automatically manage signing" is checked
- **No device UDID registration** is needed for simulator-only testing
- **No App Store Connect setup** is needed at this stage
- **No entitlements** are needed — the app uses no special capabilities (no push notifications, no HealthKit, no iCloud)

---

## 6. Known Issues and Fixes

### Issue 1: Missing signing configuration

**Symptom:** `xcodebuild` fails with "Signing requires a development team"
**Fix:** This is expected before the human configures signing in Xcode (Section 5). After they do, builds should work. For test-only runs on simulator, you can try:
```bash
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=NO
```

### Issue 2: Simulator not found

**Symptom:** `xcodebuild` fails with "Unable to find a destination matching the provided destination specifier"
**Fix:** List available simulators and use an available one:
```bash
xcrun simctl list devices available | grep iPhone
```

### Issue 3: Build fails with Core Data model errors

**Symptom:** Errors about Core Data entities not being found
**Fix:** The Core Data model is at `StackWise/StackWise.xcdatamodeld/StackWise.xcdatamodel/contents`. It defines 5 entities: UserProfile, StackItem, ScheduledDose, DailyCheckOff, FeedbackItem. If this file is missing or corrupt, re-pull from git:
```bash
cd ~/Documents/Supplement-Manager && git checkout -- StackWise/StackWise.xcdatamodeld/
```

### Issue 4: SQLite database not found at runtime

**Symptom:** App crashes or assertionFailure about "Bundled stackwise.sqlite not found"
**Fix:** Verify the file exists: `ls -la StackWise/stackwise.sqlite`. It should be ~500KB+. If missing, re-pull from git.

---

## 7. Claude Code Autonomous Task List

Execute these tasks in order. Stop and prompt the human at any `[HUMAN REQUIRED]` step.

### Task 1: Pull latest code

```bash
cd ~/Documents/Supplement-Manager
git pull origin main
git log --oneline -5
```

Verify the latest commits include Phase 4 schedule work.

### Task 2: Verify project structure

```bash
cd ~/Documents/Supplement-Manager
ls -la StackWise.xcodeproj/
ls -la StackWise/Schedule/
ls -la StackWise/stackwise.sqlite
ls -la StackWiseTests/Schedule*.swift
```

Expected: `ScheduleEngine.swift`, `ScheduleStore.swift`, `ScheduleResult.swift`, `TimingProperties.swift` all exist in `StackWise/Schedule/`. Test files `ScheduleEngineTests.swift` and `ScheduleStoreTests.swift` exist in `StackWiseTests/`.

### Task 3: Check Xcode and simulator availability

```bash
xcodebuild -version
xcrun simctl list devices available | grep "iPhone"
```

### Task 4: [HUMAN REQUIRED] Configure Xcode signing

Tell the human:
> "Please open Xcode, open the StackWise.xcodeproj, and configure signing for both the StackWise and StackWiseTests targets. Select your team under Signing & Capabilities with 'Automatically manage signing' checked. Let me know when done."

Wait for human confirmation before proceeding.

### Task 5: Attempt a clean build

```bash
cd ~/Documents/Supplement-Manager
xcodebuild clean build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tail -20
```

If this fails with signing errors, try the `CODE_SIGNING_ALLOWED=NO` workaround from Section 6, Issue 1.

If this fails with compilation errors, read the error output carefully and fix the issue.

### Task 6: Run the full test suite

```bash
cd ~/Documents/Supplement-Manager
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(Test Suite|Test Case|Executed|FAIL|PASS|\*\* TEST)"
```

**Expected:** >= 48 tests passing, 0 failures. The test breakdown should include:
- `CoreDataSchemaTests` (Phase 1)
- `UserProfileStoreTests` (Phase 2)
- `StackItemFactoryTests` (Phase 2)
- `IngredientRepositoryTests` (Phase 2 + Phase 4 timing test)
- `InteractionRepositoryTests` (Phase 3)
- `AnalysisEngineTests` (Phase 3)
- `AnalysisStoreTests` (Phase 3)
- `ScheduleEngineTests` (Phase 4, 7 tests)
- `ScheduleStoreTests` (Phase 4, 4 tests)

If any tests fail, investigate and report the exact failure. DO NOT modify test files unless the fix is clearly a build environment issue (e.g., path difference between macOS and Windows).

### Task 7: Record test results

After running tests, save the results to a file:

```bash
cd ~/Documents/Supplement-Manager
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tee /tmp/stackwise-test-results.txt

# Extract summary
grep -E "(Executed|FAIL|Test Suite.*started|Test Suite.*passed)" /tmp/stackwise-test-results.txt
```

### Task 8: Launch the app in the simulator for manual verification

```bash
# Boot the simulator
xcrun simctl boot "iPhone 16" 2>/dev/null || true
open -a Simulator

# Build and install the app
cd ~/Documents/Supplement-Manager
xcodebuild build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Get the app bundle path and install it
APP_PATH=$(xcodebuild build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | awk '{print $3}')
xcrun simctl install booted "$APP_PATH/StackWise.app" 2>/dev/null || true
xcrun simctl launch booted $(xcodebuild build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -showBuildSettings 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | awk '{print $3}') 2>/dev/null || true
```

### Task 9: [HUMAN REQUIRED] Simulator Golden Path Testing

Tell the human to perform these steps in the iOS Simulator:

> **Test A: Golden Path**
> 1. If the app is running, go to Simulator > Device > Erase All Content and Settings, then relaunch the app
> 2. Complete onboarding with: Wake=7:00 AM, Breakfast=8:00 AM, Lunch=12:00 PM, Dinner=6:00 PM, Sleep=10:00 PM
> 3. Tap "+" and add "warfarin" — select the DB suggestion (should show as prescription)
> 4. Tap "+" and add "vitamin_k2" — select the DB suggestion
> 5. Tap "+" and add "iron" — select the DB suggestion
> 6. Tap "+" and add "vitamin_c" — select the DB suggestion
> 7. Tap the **Schedule** tab (calendar icon)
> 8. **Verify:** Items are distributed across Morning/Afternoon/Evening blocks
> 9. **Verify:** Section headers show time windows (e.g., "Morning - 7:00 AM - 12:00 PM")
> 10. **Verify:** Warfarin appears first in its block (prescription priority)
> 11. **Verify:** No crashes
>
> **Test B: Empty Schedule State**
> 1. Erase the simulator again (Device > Erase All Content and Settings)
> 2. Relaunch the app, complete onboarding (any values), but do NOT add any items
> 3. Tap the **Schedule** tab
> 4. **Verify:** A "No schedule yet" message with a calendar icon is shown (ContentUnavailableView)
>
> **Test C: Reactive Update**
> 1. After Test A golden path, add a new item (e.g., "magnesium")
> 2. Return to the Schedule tab
> 3. **Verify:** The new item appears in one of the blocks
>
> Please report: PASS or FAIL for each test, and describe any issues you see.

### Task 10: Record human verification results

After the human reports results, update the file `.planning/phases/04-smart-schedule/04-HUMAN-UAT.md` with the test results. For each test, change `result: [pending]` to `result: PASS` or `result: FAIL — [description]`.

### Task 11: Commit results

```bash
cd ~/Documents/Supplement-Manager
git add .planning/phases/04-smart-schedule/04-HUMAN-UAT.md
git commit -m "test(04): record Mac human verification results

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin main
```

---

## 8. Project File Structure

```
Supplement-Manager/
├── StackWise.xcodeproj/           # Xcode project file
│   └── project.pbxproj            # Build configuration (PBXFileSystemSynchronizedRootGroup)
│
├── StackWise/                     # Main app target (auto-synced to Xcode)
│   ├── StackWiseApp.swift         # @main App entry point, environment injection
│   ├── ContentView.swift          # 3-tab TabView (Stack, Today, Schedule) + onboarding sheet
│   ├── Persistence.swift          # Core Data stack (PersistenceController.shared)
│   ├── DesignSystem.swift         # Color palette, hex initializer, brand constants
│   ├── stackwise.sqlite           # Bundled read-only SQLite DB (~130 ingredients, ~200 interactions)
│   │
│   ├── Models/                    # Core Data entity classes + app state
│   │   ├── UserProfile+CoreDataClass.swift      # User profile entity
│   │   ├── StackItem+CoreDataClass.swift        # Supplement/medication item entity
│   │   ├── ScheduledDose+CoreDataClass.swift    # Scheduled dose entity (Phase 4)
│   │   ├── FeedbackItem+CoreDataClass.swift     # Feedback entity
│   │   ├── DailyCheckOff+CoreDataClass.swift    # Daily check-off entity
│   │   ├── AppState.swift                       # Observable app state (onboardingComplete)
│   │   └── UserProfileStore.swift               # UserProfile CRUD operations
│   │
│   ├── StackWise.xcdatamodeld/    # Core Data model definition
│   │   └── StackWise.xcdatamodel/contents       # 5 entities: UserProfile, StackItem, ScheduledDose, DailyCheckOff, FeedbackItem
│   │
│   ├── Data/                      # SQLite repository layer
│   │   ├── IngredientRepository.swift   # Ingredient search + timing properties (raw sqlite3 C API)
│   │   └── InteractionRepository.swift  # Pairwise interaction queries (raw sqlite3 C API)
│   │
│   ├── Analysis/                  # Interaction analysis engine (Phase 3)
│   │   ├── AnalysisEngine.swift   # Pure analysis logic
│   │   ├── AnalysisResults.swift  # Result types
│   │   └── AnalysisStore.swift    # @Observable store with dirty-flag pattern
│   │
│   ├── Schedule/                  # Smart scheduling (Phase 4) — THE NEW CODE
│   │   ├── ScheduleEngine.swift   # Pure 4-rule scheduling algorithm (178 lines)
│   │   ├── ScheduleResult.swift   # ScheduledItem + ScheduleResult value types
│   │   ├── ScheduleStore.swift    # @Observable store, Core Data writes, dirty-flag
│   │   └── TimingProperties.swift # JSON decoder for timing_properties blob
│   │
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   └── HealthProfileView.swift   # Onboarding form (wake/sleep/meal times, health info)
│   │   ├── Stack/
│   │   │   ├── StackListView.swift       # Main stack list with add/delete
│   │   │   ├── AddItemView.swift         # Add item sheet with search + DB suggestions
│   │   │   ├── StackItemFactory.swift    # Creates StackItem from IngredientMatch
│   │   │   └── AnalysisView.swift        # Interaction analysis results screen
│   │   ├── Schedule/
│   │   │   └── ScheduleView.swift        # 3-section schedule (Morning/Afternoon/Evening)
│   │   └── Today/
│   │       └── TodayView.swift           # Today/check-off view (placeholder)
│   │
│   └── Assets.xcassets/           # App icons, colors
│       ├── AppIcon.appiconset/    # All icon sizes (20-1024px)
│       ├── AccentColor.colorset/
│       └── LaunchBackground.colorset/
│
├── StackWiseTests/                # Test target
│   ├── StackWiseTests.swift               # Base test (Phase 1)
│   ├── CoreDataSchemaTests.swift          # Core Data entity tests (Phase 1)
│   ├── UserProfileStoreTests.swift        # UserProfile CRUD tests (Phase 2)
│   ├── StackItemFactoryTests.swift        # Item creation tests (Phase 2)
│   ├── IngredientRepositoryTests.swift    # Ingredient search + timing tests (Phase 2+4)
│   ├── InteractionRepositoryTests.swift   # Interaction query tests (Phase 3)
│   ├── AnalysisEngineTests.swift          # Analysis engine tests (Phase 3)
│   ├── AnalysisStoreTests.swift           # Analysis store tests (Phase 3)
│   ├── ScheduleEngineTests.swift          # Schedule engine tests (Phase 4, 7 tests)
│   └── ScheduleStoreTests.swift           # Schedule store tests (Phase 4, 4 tests)
│
├── .planning/                     # GSD planning framework
│   ├── STATE.md                   # Current project state tracker
│   ├── ROADMAP.md                 # 10-phase roadmap
│   └── phases/
│       └── 04-smart-schedule/     # Phase 4 planning artifacts
│           ├── 04-CONTEXT.md      # Decisions and constraints
│           ├── 04-VERIFICATION.md # Verification report (5/5 automated, human_needed)
│           ├── 04-REVIEW.md       # Code review (3 critical, 7 warning, 2 info)
│           └── 04-HUMAN-UAT.md    # Human UAT tracking (4 pending tests)
│
├── .claude/                       # Claude Code configuration
│   ├── CLAUDE.md                  # Project instructions
│   └── MAC-TEST-HANDOFF-04.md    # Phase 4 Mac handoff document
│
├── database/                      # SQLite DB build artifacts (source of truth for DB)
└── landing/                       # Landing page (separate from iOS app)
```

---

## 9. Git Workflow

### Branch

All work is on `main`. No feature branches are used for this project currently.

### Pull before starting

```bash
cd ~/Documents/Supplement-Manager
git pull origin main
```

### Commit format

```bash
git commit -m "type(scope): description

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

Types: `feat`, `fix`, `test`, `docs`, `chore`, `refactor`
Scope: phase number or feature area (e.g., `04`, `schedule`, `core-data`)

### Push

```bash
git push origin main
```

### Important

- Do NOT force push
- Do NOT amend existing commits
- Do NOT create new branches unless explicitly asked
- The git user on Mac may differ from the Windows user (Alfonso-Castano) — that's fine

---

## 10. Success Criteria

When Claude Code has finished all autonomous tasks and the human has completed manual verification, the following should all be true:

1. **Build succeeds:** `xcodebuild build` completes with 0 errors
2. **Tests pass:** `xcodebuild test` shows >= 48 tests passing, 0 failures
3. **Simulator runs:** The app launches in iOS Simulator without crashes
4. **Onboarding works:** User can complete the health profile form
5. **Stack management works:** User can add items (warfarin, vitamin_k2, iron, vitamin_c) from DB suggestions
6. **Schedule tab renders:** Morning/Afternoon/Evening blocks with items distributed by the 4-rule algorithm
7. **Section headers show time windows** based on the user's onboarding meal times
8. **Empty state works:** Schedule tab shows ContentUnavailableView when no items are in the stack
9. **Reactive updates work:** Adding a new item and returning to Schedule tab shows the new item
10. **04-HUMAN-UAT.md is updated** with PASS/FAIL results for all 4 test items
11. **Results are committed and pushed** to the main branch

### Verification command (run after everything)

```bash
cd ~/Documents/Supplement-Manager
echo "=== Git Status ===" && git status
echo "=== Last 3 Commits ===" && git log --oneline -3
echo "=== UAT Status ===" && cat .planning/phases/04-smart-schedule/04-HUMAN-UAT.md | grep -E "(result:|passed:|pending:)"
```

Expected: clean git status, recent commit with test results, all 4 tests showing `result: PASS`, `passed: 4`, `pending: 0`.
