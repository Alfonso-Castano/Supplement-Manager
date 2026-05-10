# Mac Window Plan — 4-Day Execution Window

## Situation

Mac laptop available for 4 consecutive days (~1–3 hrs/day = 4–12 hrs total).
Claude Code does all implementation on Windows. Mac is used exclusively for Xcode-required tasks.

**Strategy:** Complete all Windows file-writing tasks BEFORE each Mac session.
Mac time is a limited resource — it must never sit idle waiting for code to be written.

---

## Pre-Window Windows Prep (Do Before Day 1)

Complete these on Windows and push to git BEFORE opening the Mac:

| Plan | Task | What to write |
|------|------|----------------|
| 01-02 | Task 2 | 5 NSManagedObject subclasses, Persistence.swift, CoreDataSchemaTests.swift |
| 01-03 | Task 1 | AppState.swift, StackWiseApp.swift, ContentView.swift, all 4 placeholder views |
| 01-03 | Task 2 | AppIcon PNG script, LaunchBackground.colorset/Contents.json, Info.plist UILaunchScreen |

All files must be on disk and pushed before Day 1 Mac session opens.
Mac Day 1 is then pure Xcode — no waiting on code.

---

## Day-by-Day Schedule

### Day 1 — Phase 1 Complete (~2–2.5 hrs Mac)

**Before session:** Pre-window Windows prep complete and pushed.

| Time | Task | Plan |
|------|------|------|
| 0:00 | `git pull` — get all pre-written files | — |
| 0:05 | Verify Xcode toolchain (`xcodebuild -version`, iOS 17 SDK check) | 01-01 Task 1 |
| 0:15 | Create Xcode project via GUI (bundle ID, iOS 17, test target, Cmd+B) | 01-01 Task 2 |
| 0:35 | **Restore overwritten stubs:** `git checkout StackWise/StackWiseApp.swift StackWise/ContentView.swift StackWise/Assets.xcassets/AppIcon.appiconset/Contents.json` | — |
| 0:40 | CLI verify (grep bundle ID, deployment target, xcodebuild build) | 01-01 Task 3 |
| 0:50 | Add Core Data model file (.xcdatamodeld) + define all 5 entities in model editor | 01-02 Task 1 |
| 1:30 | Add pre-written Swift files to Xcode target (Models/ + Features/ + StackWiseTests) | 01-02 Task 2 step |
| 1:45 | Run CoreDataSchemaTests (`xcodebuild test`) — confirm all 6 pass | 01-02 verify |
| 1:55 | Add UILaunchScreen key to Info.plist (LaunchBackground color name) | 01-03 Task 2 |
| 2:05 | Build (Cmd+B) — confirm clean build with all files in target | — |
| 2:15 | Simulator visual verification (3 tabs, icon, launch screen, nav, console) | 01-03 Task 3 |
| 2:35 | Push all changes (project.pbxproj, new files, icon PNG) | — |

**Day 1 outcome:** Phase 1 complete. Git has StackWise.xcodeproj with 5 Core Data entities, 3-tab shell, teal icon.

**If time remains (Day 1 buffer):**
Start Phase 2 on Windows immediately — the longer Phase 2 has to cook on Windows,
the more Mac time Day 2 can use for Phase 2 + Phase 3 verification.

---

### Day 2 — Phase 2 Verification + Phase 3 SQLite Bundling (~1.5–2.5 hrs Mac)

**Before session (Windows work between Day 1 and Day 2):**
- Implement Phase 2 completely: health profile screen, add-item flow, Core Data fetch, auto-suggestion from database
- Push all Swift files

| Time | Task | Phase |
|------|------|-------|
| 0:00 | `git pull` Phase 2 files | — |
| 0:05 | Add Phase 2 Swift files to Xcode target | Phase 2 |
| 0:15 | `xcodebuild test` — all tests pass | Phase 2 |
| 0:25 | Simulator: health profile entry, add item, auto-suggestion, stack list | Phase 2 |
| 0:55 | Push .pbxproj + any Phase 2 fixes | — |
| 1:05 | Pull Phase 3 files (if Windows work done) | — |
| 1:10 | Bundle stackwise.sqlite: drag into StackWise group, check "Add to target" | Phase 3 |
| 1:20 | Add Phase 3 Swift files to target | Phase 3 |
| 1:30 | `xcodebuild test` — interaction engine tests pass | Phase 3 |
| 1:40 | Simulator: add 2+ items, open Analysis tab, verify pairs + severity display | Phase 3 |
| 2:10 | Push | — |

**Day 2 outcome:** Phase 2 verified. Phase 3 complete if Windows work was ready.

---

### Day 3 — Phase 4 + Phase 5 (~1.5–2.5 hrs Mac)

**Before session (Windows work between Day 2 and Day 3):**
- Implement Phase 4: scheduling algorithm, schedule tab UI
- Implement Phase 5: onboarding coordinator, preview screen, trial trigger

| Time | Task | Phase |
|------|------|-------|
| 0:00 | `git pull` | — |
| 0:05 | Add Phase 4 files to target, `xcodebuild test`, simulator verify schedule rendering | Phase 4 |
| 0:45 | Add Phase 5 files to target, `xcodebuild test`, simulator verify onboarding flow end-to-end | Phase 5 |
| 1:30 | Push | — |

**Day 3 outcome:** Phases 4 and 5 verified if Windows work was complete.

---

### Day 4 — Phase 6 + Phase 7 Setup (~1.5–3 hrs Mac)

**Before session (Windows work between Day 3 and Day 4):**
- Implement Phase 6: local notification scheduling, Today tab check-off UI
- Implement Phase 7: StoreKit 2 products, paywall, trial expiry

| Time | Task | Phase |
|------|------|-------|
| 0:00 | `git pull` | — |
| 0:05 | Add Phase 6 files to target, `xcodebuild test`, simulator verify notifications + check-off | Phase 6 |
| 0:55 | Add Phase 7 files to target, create StoreKit config file in Xcode, sandbox test | Phase 7 |
| 2:00 | Push | — |

**Day 4 outcome:** Phases 6 and 7 verified if Windows work was complete.

---

## What Spills to MacInCloud

| Phase | Mac time needed | Likely spill? |
|-------|-----------------|---------------|
| Phase 8 (Feedback) | ~30–45 min | Yes — if Day 4 runs out |
| Phase 9 (Polish & Ship) | ~3–4 hrs | Yes — always. Phase 9 is a full extended session. |

Phase 9 notes:
- Dark mode audit in simulator (~30 min)
- Simulator screenshots for App Store (~45 min)
- Code signing, provisioning profiles, TestFlight upload (~60–90 min)
- App Store submission (~30–60 min)

MacInCloud at ~$1/hr handles Phase 8 (~$0.50) and Phase 9 (~$3–4) with no friction.
Total estimated MacInCloud cost if laptop covers Phases 1–7: ~$3.50–4.50.

---

## Mac Time Summary by Phase

| Phase | Mac Tasks | Est Mac Time | Environment |
|-------|-----------|--------------|-------------|
| 1 | Project GUI, schema GUI, add-to-target ×2, simulator verify | ~2–2.5 hrs | Day 1 laptop |
| 2 | Add files to target, build, test, simulator verify | ~45–60 min | Day 2 laptop |
| 3 | Bundle SQLite (Xcode drag), add files, build, test, simulator verify | ~45–60 min | Day 2 laptop |
| 4 | Add files, build, test, simulator verify schedule | ~30–45 min | Day 3 laptop |
| 5 | Add files, build, test, simulator verify onboarding | ~30–45 min | Day 3 laptop |
| 6 | Add files, build, test, simulator verify notifications | ~30–45 min | Day 4 laptop |
| 7 | Add files, StoreKit config, sandbox test, build | ~45–60 min | Day 4 laptop |
| 8 | Add files, build, test, Formspree network test | ~30–45 min | MacInCloud |
| 9 | Dark mode, screenshots, signing, TestFlight, submission | ~3–4 hrs | MacInCloud |

**Total Mac time across all phases: ~9–12 hrs**
**4-day laptop window covers: Phases 1–7 (conservative) to Phases 1–7 (optimistic)**
**MacInCloud covers: Phases 8–9 (~$3.50–4.50)**

---

## Critical Path Warning

The bottleneck is NOT Mac time — it's Windows implementation time.
Each phase requires substantial Swift code before Mac verification can happen.

Rule: Never open a Mac session without Windows code pushed and ready.
Wasted Mac time (waiting for code) is worse than any other inefficiency.

If a phase isn't ready for Mac verification, skip it and push to the next ready phase.
Phases can be verified out of order if their Windows dependencies are met.

---

## Git Bridge Workflow (Unchanged)

See: `.planning/phases/01-project-foundation/CLOUD-MAC-WORKFLOW.md`
The git bridge workflow is identical for personal Mac laptop and MacInCloud.
