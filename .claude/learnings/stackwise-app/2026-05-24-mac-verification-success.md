# Session Learnings: Mac Verification — SUCCESS

**Date:** 2026-05-24
**Duration:** ~5 minutes (single prompt, no retries)
**Outcome:** SUCCESS — 50/50 tests passed, commit pushed to main
**Environment:** macOS Sequoia running in a VM (via UTM/Parallels on Windows), Xcode 16, iOS 18.3 simulator

---

## What Worked

### 1. The Learnings File Was the Difference
The previous session's learnings file (`2026-05-23-mac-verification-session.md`) provided every piece of critical knowledge needed to succeed on the first attempt. The user invested time documenting 20 hours of failure, and this session consumed that knowledge in seconds and executed a clean run.

**Key takeaway:** Documenting failures in structured learnings files is extremely high-ROI. The previous agents spent 20 hours failing; this agent spent 5 minutes succeeding because the failures were documented.

### 2. Environment Cleanup First
Killing stale `xcodebuild` and `XCBBuildService` processes before doing anything else ensured a clean slate. In this session there were zero stale processes (the user had likely already cleaned up), but the check took 2 seconds and removed a class of failure.

### 3. Simulator Stability Verification Before Tests
Checking that the simulator was booted and waiting to confirm it stayed alive before running tests prevented the #1 failure mode from the previous sessions (simulator dying mid-test-run). The user had Simulator.app open and visible, which keeps the simulator process alive in this VM environment.

### 4. `test-without-building` Skipped Rebuild
Using `xcodebuild test-without-building` instead of `xcodebuild test` went straight to test execution. The project was already built (confirmed in a prior session), so this avoided 5-10 minutes of unnecessary rebuild time and the risk of the simulator dying during the build phase.

### 5. Single Attempt Policy
The hard rule of "one attempt, then escalate to Xcode GUI" meant there was zero risk of entering a retry loop. The test run succeeded on the first attempt, but having the constraint prevented the failure mode that consumed the previous 20 hours.

---

## Surprises

### Test Count: 50, Not 48
The expected count was 48 tests, but 50 passed. The AnalysisStoreTests file had 4 tests (not the 2 that were expected as new additions). This is a positive surprise — more coverage than expected. Updated test breakdown:

| File | Tests | Phase |
|------|-------|-------|
| CoreDataSchemaTests | 7 | 1 |
| IngredientRepositoryTests | 5 | 2 |
| UserProfileStoreTests | 4 | 2 |
| StackItemFactoryTests | 5 | 2 |
| InteractionRepositoryTests | 5 | 3 |
| AnalysisEngineTests | 6 | 3 |
| AnalysisStoreTests | 4 | 3 |
| ScheduleEngineTests | 9 | 4 |
| ScheduleStoreTests | 5 | 4 |
| **Total** | **50** | |

### Simulator Cloning
The test output showed tests running on "Clone 1 of iPhone 16" — Xcode automatically cloned the simulator for test execution. This is normal Xcode behavior but worth noting since the clone had a different process ID than the main simulator.

---

## What the Prompt Got Right

The user's prompt incorporated every lesson from the previous session into a structured, phased approach:
1. Read learnings first (context before action)
2. Environment cleanup (remove stale state)
3. Simulator stability gate (verify before committing)
4. Single-attempt test run with timeout (no retry loops)
5. Clear escalation path (Xcode GUI as fallback)
6. Hard time limit (30 minutes max)

This is a template for future VM-based test runs.

---

## Recommendations for Future Sessions

1. **Always check `learnings/stackwise-app/` before running tests** — environment-specific knowledge lives here
2. **Keep Simulator.app GUI open** before starting any test run in this VM
3. **Expected test count is now 50** — update any references to 48
4. **The `@MainActor` fix is committed** — `AnalysisStoreTests` now has `@MainActor` for Swift 6 concurrency compliance
5. **Use `test-without-building`** whenever the project is already built — saves significant time in the VM
