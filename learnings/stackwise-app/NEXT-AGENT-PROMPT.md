# Prompt for Next Agent

Copy everything below the line into your next Claude Code session on the Mac VM.

---

## PROMPT START

You are picking up a failed verification task. Before doing ANYTHING, read this file:

```
/Users/alfonso/Documents/Supplement-Manager/.learnings/stackwise-app/2026-05-23-mac-verification-session.md
```

That file documents 20 hours of failed attempts and contains critical environment-specific knowledge about this VM. The previous agents wasted all that time because the iOS Simulator keeps shutting down in this VM environment. Read it fully before proceeding.

**Your task:** Run the StackWise test suite (48 unit tests) and verify they all pass.

**What's already done:**
- All code changes are applied and committed except one: `@MainActor` on `AnalysisStoreTests` (already in the working tree)
- The project builds successfully (`build-for-testing` confirmed)

**What you need to do:**

PHASE 1 — Environment cleanup (do this FIRST, no exceptions):
```bash
pkill -9 -f xcodebuild
pkill -9 -f XCBBuildService
ps aux | grep -E "xcodebuild|XCBBuild" | grep -v grep
```
Verify zero stale processes before continuing.

PHASE 2 — Simulator stability test:
The user has already opened Simulator.app for you. Verify the simulator is alive:
```bash
xcrun simctl list devices | grep "Booted"
```
If no device is booted, boot iPhone 16 (UUID: F3BED3A7-B964-42E9-B4FB-1EE31226239F):
```bash
xcrun simctl boot F3BED3A7-B964-42E9-B4FB-1EE31226239F
```
Then WAIT and check it's still alive after 60 seconds. If it dies, STOP — tell the user to run tests via Xcode GUI (Product → Test or Ctrl+U) and skip to Phase 4.

PHASE 3 — Run tests (ONE attempt only, if Phase 2 passed):
```bash
xcodebuild test-without-building \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,id=F3BED3A7-B964-42E9-B4FB-1EE31226239F' \
  -only-testing:StackWiseTests \
  2>&1 | tee /tmp/test_results.txt | grep -E "(Test Case|Executed|FAIL|\*\* TEST)"
```
Set a 10-minute timeout. If it hangs or fails, DO NOT RETRY. Tell the user to run via Xcode GUI instead.

PHASE 4 — Report and commit:
Once you have test results (from terminal or from the user running via GUI):
- Report pass/fail count
- If all 48 pass, commit the `@MainActor` fix and push:
```bash
cd /Users/alfonso/Documents/Supplement-Manager
git add StackWiseTests/AnalysisStoreTests.swift
git commit -m "test(04): add @MainActor to AnalysisStoreTests for Swift 6 concurrency

Mac verification of deep review fixes — [PASS_COUNT]/48 tests passing.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin main
```

**HARD RULES:**
1. Read the learnings file FIRST
2. Maximum 2 attempts at running tests from terminal. After that, ask the user to run via Xcode GUI
3. If the simulator dies, don't keep rebooting it — that's the trap the previous agents fell into
4. If no test has executed within 5 minutes of starting, something is wrong — stop and diagnose
5. Total session should take under 30 minutes. If you're past that, you're in a loop

## PROMPT END
