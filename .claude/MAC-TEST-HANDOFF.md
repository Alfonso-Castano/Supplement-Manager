# StackWise — Phase 3 Mac Test Handoff

**For:** Claude Code instance running in the Mac terminal  
**Date written:** 2026-05-15  
**Branch:** `main`  
**First commit to pull:** `d476dd6` through `a9dd79c` (8 new commits)

---

## What you are doing

Phase 3 of the StackWise iOS app was fully written on Windows. You are on a Mac and need to:

1. Pull the new commits.
2. Build the project.
3. Run the full test suite (target: ≥ 36 tests passing).
4. Report the complete results — pass/fail counts, any failing test names, any compiler errors verbatim.

There is one step that **cannot be done in the terminal** and requires the human: a visual simulator golden path. You will instruct the human on exactly what to do after tests pass.

---

## Critical project facts

- **Xcode project:** `StackWise.xcodeproj` in the repo root.
- **Scheme:** `StackWise`
- **iOS deployment target:** iOS 17.6 minimum
- **Project uses `PBXFileSystemSynchronizedRootGroup`** (Xcode 16+ automatic folder sync). This means **every `.swift` file in `StackWise/` and `StackWiseTests/` is auto-included in its target** — you do NOT need to open Xcode and manually add files to Compile Sources. `git pull` + build is sufficient.
- **SQLite DB:** `StackWise/stackwise.sqlite` is a bundled read-only resource (63 interactions, 70 ingredients). Several tests query it at runtime via the app bundle — they need a simulator target to resolve `Bundle.main`.

---

## Step-by-step terminal commands

### Step 1 — Pull all Phase 3 commits

```bash
cd /path/to/Supplement-Manager   # adjust to your actual clone path
git pull origin main
git log --oneline -10             # confirm the 8 commits are present
```

Expected top of log:
```
a9dd79c docs(03-04): complete plan 03-04 and phase 3 summaries
f72b8f2 feat(03-04): inline severity badges on stack rows
c97d931 docs(03-03): complete AnalysisView grouped screen plan
6ede987 feat(03-03): AnalysisView grouped screen + Analyze toolbar button
a35d6ad docs(03-02): complete AnalysisEngine + AnalysisStore plan
1afbdba feat(03-02): AnalysisEngine + AnalysisStore + invalidation hook
d476dd6 feat(03-01): InteractionRepository + tests + CF-6 fix
```

### Step 2 — Verify new files are present

```bash
ls StackWise/Data/InteractionRepository.swift
ls StackWise/Analysis/AnalysisResults.swift
ls StackWise/Analysis/AnalysisEngine.swift
ls StackWise/Analysis/AnalysisStore.swift
ls StackWiseTests/InteractionRepositoryTests.swift
ls StackWiseTests/AnalysisEngineTests.swift
ls StackWiseTests/AnalysisStoreTests.swift
```

All seven should exist. If any are missing, stop and report which ones are absent.

### Step 3 — Find an available simulator

```bash
xcrun simctl list devices available | grep -E "iPhone 1[5-9]|iPhone 2" | head -10
```

Pick the first available iPhone 15 or newer. Note the exact device name (e.g. `iPhone 16`).

If no iPhones appear, run:
```bash
xcrun simctl list devices available | grep iPhone | head -10
```
and pick the most recent available one.

### Step 4 — Build

Replace `iPhone 16` with your chosen device name from Step 3.

```bash
xcodebuild build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  2>&1 | tail -30
```

**Expected:** `** BUILD SUCCEEDED **` at the end with zero errors.

**If build fails:** Capture the full error output (not just the tail) and report it. Do NOT attempt to fix Xcode project structure issues — those require human intervention. Do report the exact compiler error lines.

To get the full error output if it fails:
```bash
xcodebuild build \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  2>&1 | grep -E "error:|warning:|BUILD" | head -50
```

### Step 5 — Run the full test suite

```bash
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  2>&1 | grep -E "Test Case|PASSED|FAILED|error:|** TEST"
```

**Expected:**
- `** TEST SUCCEEDED **` at the end
- ≥ 36 test cases passing (21 from Phase 2 + 15 new from Phase 3)
- Zero failures

**Full output if any test fails:**
```bash
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  2>&1 | grep -E "Test Case|PASSED|FAILED|error:|warning:|** TEST|fatal" | head -80
```

### Step 6 — Report results

After running tests, report back:
1. Whether build succeeded or failed (include error lines if failed).
2. The exact count of tests passed/failed.
3. Names of any failing tests.
4. Any compiler warnings that look like they could be real problems (not just deprecation notices).

Paste the last 30 lines of the test run verbatim.

---

## Expected test breakdown (for reference)

| File | Tests | Phase |
|------|-------|-------|
| `CoreDataSchemaTests.swift` | 7 | 1 |
| `IngredientRepositoryTests.swift` | 5 | 2 |
| `UserProfileStoreTests.swift` | 4 | 2 |
| `StackItemFactoryTests.swift` | 5 | 2 |
| `InteractionRepositoryTests.swift` | 5 | 3 |
| `AnalysisEngineTests.swift` | 6 | 3 |
| `AnalysisStoreTests.swift` | 4 | 3 |
| **Total** | **36** | |

---

## If tests pass — human gate (simulator golden path)

Once `** TEST SUCCEEDED **` with ≥ 36 tests, **you cannot complete the simulator golden path from the terminal** — it requires human eyes and touch interaction. Tell the human to do the following in the iOS Simulator:

> **Instructions for the human:**
>
> 1. Open Xcode. Product → Run (Cmd+R) on an iPhone 16 simulator.
> 2. If the app has prior data: Device → Erase All Content and Settings, then re-launch.
> 3. Complete the onboarding form (any values) and tap Save.
> 4. On the Stack tab, tap **+** and add "warfarin" — it should auto-suggest from the DB. Confirm the suggestion, save.
> 5. Tap **+** and add "vitamin_k2" — same, confirm the DB suggestion, save.
> 6. **Verify:** Both stack rows now show a **red octagon** icon (critical severity badge).
> 7. Tap the **stethoscope icon** (top-left toolbar). The Analysis screen should open.
> 8. **Verify:** A **Critical** section appears showing "Warfarin ↔ Vitamin K2" with effect and suggested action text. No Advisory, Positive insights, or Not in database sections (they should be absent, not empty).
> 9. Go back. Tap **+** and add "iron". Tap **+** and add "vitamin_c".
> 10. Tap the stethoscope. **Verify:** A **Positive insights** section now appears showing "Iron ↔ Vitamin C" (synergy pair).
> 11. Go back. Tap **+** and type "Banana extract" — do NOT select any suggestion. Save with the raw text.
> 12. **Verify:** The "Banana extract" row shows the **orange triangle** (Phase 2 custom-item icon) but NO severity badge.
> 13. Tap the stethoscope. **Verify:** A **Not in our database** section appears listing "Banana extract".
>
> If all 13 checks pass, type **"phase 3 verified"** in the Claude Code session on Windows.  
> If any check fails, describe exactly which step failed and what you saw instead.

---

## What you (the terminal agent) do NOT need to do

- Open Xcode GUI at all — `PBXFileSystemSynchronizedRootGroup` handles file registration automatically.
- Manually edit `.pbxproj` — do not touch it.
- Add files to targets — already done by the file system sync.
- Run UITests — `StackWiseUITests` target is a placeholder; skip it.
- Fix any issues that require Xcode GUI (report them instead).

---

## If something goes wrong

| Problem | What to do |
|---------|-----------|
| `xcodebuild: error: Unable to find a destination` | Run `xcrun simctl list devices available` and use a different device name |
| Build error: `cannot find type 'AnalysisStore' in scope` | The Analysis/ folder files may not be auto-included — report this; it means the project may not be using file system sync as expected |
| Build error: `'sqlite3_open_v2' is unavailable` | Report verbatim — unexpected |
| Test crash in `AnalysisStoreTests` | The `#if DEBUG` init may have a Swift visibility issue — report the exact error |
| `testKnownWarfarinVitaminKCriticalPair` fails | The bundled DB may differ from expected — report the failure message |
| `** BUILD SUCCEEDED **` but `** TEST FAILED **` | Report every failing test name and error message |

---

## Where to send results

Return results to the Windows Claude Code session. The Windows agent will diagnose any issues or write patches as needed. For anything that requires Xcode GUI (like modifying build settings or resolving a pbxproj conflict), escalate to the human.
