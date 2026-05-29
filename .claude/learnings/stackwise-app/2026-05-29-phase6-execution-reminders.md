# Session Learnings: Phase 6 execution — reminders and today tab

Date: 2026-05-29
Duration: ~25 minutes
Outcome: SUCCESS
Category: stackwise-app
Phase: Phase 6

## What Was Done

Executed all 5 plans of Phase 6 (Reminders & Today Tab) across 4 waves. Wave 1 built foundation types (AppDelegate, NotificationScheduler, AppState.selectedTab, 6 RED test stubs). Wave 2 wired them into the app (ContentView two-gate, AppDelegate bridge, ScheduleStore hook). Wave 3 ran two plans in parallel via worktree isolation (NotificationPermissionView + TodayView). Wave 4 filled tests GREEN and hit the human simulator checkpoint, which was approved. All 5 plans complete, REQ-20 and REQ-21 satisfied.

## What Went Right

- **Parallel worktree execution worked on Windows** — Wave 3 ran 06-03 and 06-04 simultaneously in git worktrees with no file overlap. Both completed successfully and merged cleanly. Sequential dispatch (one `Task()` per message with `run_in_background: true`) avoided the `.git/config.lock` contention issue.
- **Plan 04 executor was more thorough than expected** — it filled TodayViewModelTests with 7 real tests instead of leaving RED stubs. Plan 05 correctly adapted by skipping that file rather than overwriting good work.
- **Stub-then-replace pattern** — Plan 02 created a NotificationPermissionView stub to unblock compilation; Plan 03 replaced it with the full implementation. Clean deviation handling.
- **Model set to Opus 4.6 at project level** — set in `.claude/settings.json` before execution began, ensuring all subagents inherited the same model.

## What Went Wrong / Blockers

- **Worktree merge blocked by untracked file** — Plan 04's worktree somehow left an untracked `06-04-SUMMARY.md` in the main working tree, blocking the merge. Required `git add` + `git stash` to clear the path. Root cause unclear — may be a Claude Code worktree isolation edge case where the agent writes to both the worktree and the main tree.
- **Worktree lock removal required unlock step** — After agents completed, `git worktree remove --force` failed because worktrees were locked by the Claude agent PID. Had to `git worktree unlock` first, then remove. This is expected behavior but adds a step to the cleanup flow.

## Key Lessons

- **Always `git worktree unlock` before `git worktree remove`** on Windows after Claude Code agents — the lock persists after the agent process exits. The two-step sequence (unlock → remove --force) is reliable.
- **Stash untracked files before worktree merges** — if a worktree agent creates a file that also appears untracked in the main tree, `git merge` refuses. Quick fix: `git add <file> && git stash` before merge, then `git stash drop` after.
- **Check for pre-filled test stubs** — when a later plan expects RED stubs, the executor should read the file first. An earlier plan may have already filled them GREEN (as Plan 04 did for TodayViewModelTests). The plan's deviation handling caught this correctly.

## Environment Notes

- Windows 11 + git worktrees: works, but lock cleanup is manual. Budget an extra step in the merge flow.
- `git merge --no-ff --no-edit` produces CRLF warnings on Windows — these are cosmetic and don't affect the merge.
