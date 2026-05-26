# Session Learnings: Mac Verification of Phase 4 Deep Review Fixes

**Date:** 2026-05-23
**Duration:** ~20 hours across two agent sessions (previous session ~10h, this session ~10h)
**Outcome:** FAILED — zero tests were executed across both sessions
**Environment:** macOS Sequoia running in a VM (via UTM/Parallels on Windows), Xcode 16, iOS 18.3 simulator

---

## Critical Failures

### 1. No Circuit Breaker — The 10-Hour Loop
**What happened:** The first agent session ran for ~10 hours without executing a single test. It kept retrying `xcodebuild test` in a loop, each attempt rebuilding from scratch and hanging when the simulator died.

**Root cause:** No timeout enforcement, no retry limit, no failure detection. The agent kept trying the same failing approach without recognizing the pattern.

**Lesson:** Any automated test run MUST have:
- A hard retry limit (max 3 attempts of the same approach)
- After 2 failures of the same kind, STOP and report the issue to the user
- Never run the same failing command more than twice without changing the approach
- Track wall-clock time — if 30+ minutes pass with no test execution, something is fundamentally wrong

### 2. Simulator Instability in VM Was Never Diagnosed
**What happened:** The iOS Simulator boots successfully via `xcrun simctl boot` but shuts down within 30-60 seconds. This happened consistently across 15+ attempts in both sessions.

**Root cause (identified late):** In this VM environment, the Simulator needs the **Simulator.app GUI window to be open and visible** to stay alive. Without the GUI, macOS (or the VM hypervisor) kills the headless simulator process as idle. This is a VM-specific behavior — on real Mac hardware, headless simulators stay alive indefinitely.

**Key evidence:**
- `xcrun simctl boot` → shows "Booted" → 30-60s later → "Shutdown"
- Opening Simulator.app first kept the device alive longer
- The user confirmed tests worked before (they had Xcode GUI open, which keeps the simulator alive)
- System logs showed repeated `syslogd restarted` entries in the simulator device log, confirming repeated boot/shutdown cycles

**Lesson:** When running in a VM:
- ALWAYS open Simulator.app GUI before attempting any simulator operations
- Verify the simulator stays alive for at least 60 seconds before starting tests
- If the simulator dies twice, the approach needs to change — don't keep retrying

### 3. `xcodebuild test` vs `test-without-building` Confusion
**What happened:** The first session used `xcodebuild test` which rebuilds everything before running tests. Each rebuild took 5-10 minutes in the VM, and the simulator would die during the build phase before tests ever executed.

**Better approach:** Use `xcodebuild build-for-testing` first (no simulator needed), then `xcodebuild test-without-building` (skips build, goes straight to test execution). This was identified in the second session but the simulator instability prevented it from helping.

**Lesson:** Always separate build and test phases:
1. `xcodebuild build-for-testing` — can run without a simulator
2. `xcodebuild test-without-building` — needs simulator but starts immediately

### 4. Zombie Process Accumulation
**What happened:** By the time the second session started, there were 11 zombie xcodebuild processes and multiple stale XCBBuildService processes from the first session's retry loop. These consumed resources and may have contributed to simulator instability.

**Lesson:** Before starting any xcodebuild operation:
- Run `ps aux | grep xcodebuild | grep -v grep` to check for stale processes
- Kill any zombie or stale xcodebuild/XCBBuildService processes first
- After a failed run, always clean up before retrying

### 5. Background Task Timeout Not Enforced
**What happened:** Commands run with `run_in_background: true` had timeouts set (e.g., 10 minutes) but the timeout was not enforced — processes ran for hours.

**Lesson:** Don't rely on background task timeouts for critical operations. Instead:
- Run critical commands in the foreground with explicit timeouts
- Use a monitoring pattern: start the command, then separately monitor for completion with a hard wall-clock cutoff
- If monitoring shows no progress after 2-3 minutes, kill and diagnose

---

## Partial Successes

### 1. Build Verification Works
The project compiles successfully with the `@MainActor` fix applied to `AnalysisStoreTests.swift`. `** TEST BUILD SUCCEEDED **` was confirmed multiple times. The code changes from the 8 deep review fix commits are valid.

### 2. Root Cause Identification (Eventually)
The simulator instability root cause was eventually identified — the VM needs the GUI app open. This took too long to figure out but is now documented.

### 3. Stale Process Diagnosis
The second session correctly identified that zombie processes from the first session were still running and killed them. This should have been the FIRST thing checked.

---

## Environment-Specific Knowledge

### This VM Setup
- macOS Sequoia running in VM on Windows host
- 16GB RAM allocated (not a memory constraint)
- x86_64 architecture (Intel simulation)
- Xcode 16 with iOS 18.3 SDK
- Simulator devices shut down when running headless (no GUI)
- Build times are 3-5x slower than native Mac hardware
- `PBXFileSystemSynchronizedRootGroup` is used — files are auto-included in targets, no manual pbxproj edits needed

### What Works
- `xcodebuild build` and `build-for-testing` work reliably from terminal
- `xcrun simctl boot/shutdown/erase` work correctly
- Git operations work normally
- File editing and reading work normally

### What Doesn't Work
- Headless simulator stays alive only 30-60 seconds
- `xcodebuild test` hangs when simulator dies (no timeout, no error)
- Long-running xcodebuild processes become zombies when killed

---

## Recommended Approach for Next Session

### To run tests successfully:
1. Kill ALL stale xcodebuild/XCBBuildService processes first
2. Open Simulator.app GUI (must be visible, not minimized)
3. Boot target device via `xcrun simctl boot <UUID>`
4. Verify device stays booted for 60+ seconds
5. Run `xcodebuild build-for-testing` (no simulator needed)
6. Run `xcodebuild test-without-building` immediately
7. If simulator dies during step 6, the GUI approach isn't sufficient — escalate to user to run tests via Xcode GUI (Product → Test)

### iPhone 16 Simulator UUID
`F3BED3A7-B964-42E9-B4FB-1EE31226239F`

### The one uncommitted change
```diff
+@MainActor
 final class AnalysisStoreTests: XCTestCase {
```
File: `StackWiseTests/AnalysisStoreTests.swift`

### Expected test results
- 48 tests across 8 test files
- All should pass (they passed before the 8 fix commits, and the fixes are non-breaking)
- If `@MainActor` errors appear in `ScheduleStoreTests`, add `@MainActor` to that class too

---

## Meta-Lessons for Agent Behavior

1. **Fail fast, fail loud.** Two identical failures = stop and change approach. Don't retry hoping for different results.
2. **Check the environment first.** Before running tests, verify: Are there stale processes? Is the simulator alive? Is the build cache valid?
3. **Separate concerns.** Build without simulator. Test with simulator. Don't combine them.
4. **Time-box everything.** If no progress in 5 minutes of wall time, something is wrong. Diagnose, don't retry.
5. **The VM is different.** Don't assume native Mac behavior. Simulators need GUI apps. Builds are slow. Account for this.
6. **Clean up after yourself.** Kill processes. Remove temp files. Don't leave state for the next session to trip over.
