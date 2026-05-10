# Mac Workflow — All Phases

## Environment

**Primary:** Personal Mac laptop (free; use when available)
**Fallback:** MacInCloud (~$1/hr) when laptop is unavailable

Git is the bridge between Windows (file writing) and Mac (Xcode tasks).
The workflow below is identical for both environments.

---

## When Mac Is Required

Mac is needed for three categories of tasks across all phases:

1. **Xcode GUI actions** — project creation, Core Data model editor, StoreKit config setup, signing
2. **Adding new Swift files to Xcode target** — files written on Windows exist on disk but are not
   referenced in `project.pbxproj` until added via Xcode ("Add Files to StackWise")
3. **Build verification + simulator testing** — `xcodebuild build/test`, running on iOS simulator

---

## Phase Task Split

### Phase 1: Project Foundation

| Plan  | Task                                               | Environment |
|-------|----------------------------------------------------|-------------|
| 01-01 | Task 1: Verify Xcode toolchain                     | Mac         |
| 01-01 | Task 2: Create Xcode project via GUI               | Mac         |
| 01-01 | Task 3: Verify bundle ID + build from CLI          | Mac         |
| 01-02 | Task 1: Add Core Data model + define entities GUI  | Mac         |
| 01-02 | Task 2: Write NSManagedObject subclasses +         | Windows     |
|       |         PersistenceController + CoreDataSchemaTests |             |
| 01-03 | Task 1: Create AppState, ContentView,              | Windows     |
|       |         placeholder tab views                       |             |
| 01-03 | Task 2: Add app icon + launch screen plist         | Windows     |
| 01-03 | Task 3: Visual + functional simulator verify       | Mac         |

### Phase 2: Stack & User Setup

| Task category                                | Environment |
|----------------------------------------------|-------------|
| All Swift file writing (views, ViewModels)   | Windows     |
| Add Swift files to Xcode target              | Mac         |
| `xcodebuild test` — all tests pass           | Mac         |
| Simulator: health profile, add item, stack   | Mac         |

Est Mac time: ~45–60 min

### Phase 3: Interaction Analysis Engine

| Task category                                     | Environment |
|---------------------------------------------------|-------------|
| All Swift file writing (engine, views)            | Windows     |
| **Bundle stackwise.sqlite** — drag into Xcode,   | Mac         |
| check "Copy items if needed", add to target       |             |
| Add Swift files to Xcode target                   | Mac         |
| `xcodebuild test` — interaction engine tests pass | Mac         |
| Simulator: add items, open Analysis, verify pairs | Mac         |

Est Mac time: ~45–60 min
Note: SQLite bundling requires Xcode GUI (drag file into project navigator).

### Phase 4: Smart Schedule

| Task category                                    | Environment |
|--------------------------------------------------|-------------|
| All Swift file writing (algorithm, views)        | Windows     |
| Add Swift files to Xcode target                  | Mac         |
| `xcodebuild test` — scheduling tests pass        | Mac         |
| Simulator: verify 3 schedule blocks render       | Mac         |

Est Mac time: ~30–45 min

### Phase 5: Functional Onboarding

| Task category                                    | Environment |
|--------------------------------------------------|-------------|
| All Swift file writing (coordinator, views)      | Windows     |
| Add Swift files to Xcode target                  | Mac         |
| `xcodebuild test`                                | Mac         |
| Simulator: onboarding flow end-to-end            | Mac         |

Est Mac time: ~30–45 min

### Phase 6: Reminders & Today Tab

| Task category                                    | Environment |
|--------------------------------------------------|-------------|
| All Swift file writing (notifications, views)    | Windows     |
| Add Swift files to Xcode target                  | Mac         |
| `xcodebuild test`                                | Mac         |
| Simulator: notification permission, check-off UI | Mac         |

Est Mac time: ~30–45 min

### Phase 7: Monetization

| Task category                                              | Environment |
|------------------------------------------------------------|-------------|
| All Swift file writing (StoreKit, paywall UI)              | Windows     |
| Create StoreKit configuration file in Xcode (GUI)         | Mac         |
| Add Swift files to Xcode target                            | Mac         |
| `xcodebuild test` — StoreKit sandbox tests                 | Mac         |
| Simulator: StoreKit sandbox purchase, trial expiry         | Mac         |

Est Mac time: ~45–60 min

### Phase 8: In-App Feedback

| Task category                                      | Environment |
|----------------------------------------------------|-------------|
| All Swift file writing (Formspree, retry logic)    | Windows     |
| Add Swift files to Xcode target                    | Mac         |
| `xcodebuild test`                                  | Mac         |
| Simulator: form submission, network test           | Mac         |

Est Mac time: ~30–45 min

### Phase 9: Polish & Ship (Extended Session)

| Task category                                | Environment |
|----------------------------------------------|-------------|
| Dark mode fixes, color audit (code)          | Windows     |
| Dark mode visual audit in simulator          | Mac         |
| App Store screenshots in simulator           | Mac         |
| Code signing + provisioning profiles         | Mac         |
| TestFlight upload                            | Mac         |
| App Store submission                         | Mac         |

Est Mac time: ~3–4 hrs (plan a dedicated MacInCloud session for Phase 9 regardless)

---

## Git Bridge Workflow

### After a Mac task (Mac → Windows)
1. Mac: `git add -A && git commit -m "..." && git push`
2. Windows: `git pull`

### After a Windows file-writing task (Windows → Mac)
1. Windows: `git add -A && git commit -m "..." && git push`
2. Mac: `git pull`

### IMPORTANT — Adding new Swift files to Xcode target

When Windows creates Swift files via Claude Code, those files are on disk but
NOT yet referenced in `project.pbxproj`. After pulling on Mac:

1. Open `StackWise.xcodeproj` in Xcode
2. In the Project Navigator, right-click the correct group folder
3. Select **Add Files to "StackWise"...**
4. Select all newly added `.swift` files
5. Ensure **Add to targets: StackWise** (or StackWiseTests for test files) is checked
6. Click **Add**
7. Build (Cmd+B) — confirm no missing symbol errors before committing
8. `git add StackWise.xcodeproj/project.pbxproj && git commit -m "chore: add swift files to xcode target" && git push`
9. Windows: `git pull` (to get the updated `.pbxproj`)

---

## MacInCloud Setup (Fallback)

1. Create a MacInCloud account at macincloud.com (pay-as-you-go, ~$1/hr)
2. Start a macOS instance with Xcode 15 or 16 pre-installed
3. In the cloud Mac terminal, clone the repo:
   ```
   git clone <repo-url> ~/Supplement-Manager
   cd ~/Supplement-Manager
   ```
4. Follow the same git bridge workflow above

MacInCloud is expected for: Phase 8 verification, Phase 9 (full extended session).
See `.planning/MAC-WINDOW-PLAN.md` for the day-by-day laptop window plan.
