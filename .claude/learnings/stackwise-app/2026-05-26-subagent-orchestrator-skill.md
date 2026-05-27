# Session Learnings: Subagent + agent team strategy, orchestrator skill built

Date: 2026-05-26
Duration: ~3 hours
Outcome: SUCCESS
Category: stackwise-app
Phase: N/A (workflow tooling session)

## What Was Done

Continued the "Maximizing Claude" discussion series, covering Topic 2 (subagents and
agent teams). Wrote the 02-subagents-parallelization.md strategy doc, built and evaluated
the orchestrator skill (.claude/skills/orchestrator/SKILL.md), and updated CLAUDE.md
section 2 with a full decision ladder and pointer to the new skill. The orchestrator
skill scored 100% on all 3 evals (vs 0% baseline), using real StackWise tasks.

## What Went Right

- Fetching the official agent teams docs (code.claude.com/docs/en/agent-teams) before
  finalizing the skill design — it corrected several near-misses and confirmed the
  experimental flag, mailbox mechanism, and split-pane limitations on VS Code/Windows.
- Spawning a research subagent for agent prompting best practices kept the main context
  clean and returned a focused, actionable summary rather than raw doc dumps.
- Running all 6 eval runs (with-skill + baseline × 3 evals) in a single parallel spawn
  call — completed in ~160s total, results came back staggered rather than blocking.
- The orchestrator skill's codebase-first behavior was the standout: on eval-0 it
  explored the repo, found onboarding already implemented, and correctly chose single
  session instead of spawning subagents — a better answer than the assertion expected.

## What Went Wrong / Could Have Been Done Better

- Initially hedged on whether agent teams support true peer-to-peer communication — the
  user was right, I was wrong. Should have fetched the docs earlier in the discussion
  rather than qualifying it as "partially right." When the user asserts something specific
  about a documented feature, verify it before pushing back.
- Flagged the user-provided docs URL (code.claude.com/docs/en/agent-teams) as
  potentially invalid before checking it. The URL was real and correct. Don't pre-emptively
  doubt URLs a user provides for their own tools.
- The research subagent step happened after the Q&A round rather than in parallel with it.
  For future discuss-then-build sessions, research and targeted questions can run
  concurrently to save a round-trip.

## Key Lessons

- Agent teams ≠ subagents. Agent teams have a real mailbox for peer-to-peer teammate
  messaging, a shared task list, and require CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1.
  Subagents are one-directional only. Use teams only when peer coordination is the
  specific requirement — they cost significantly more tokens and are experimental.
- The orchestrator skill is now the decision gateway for any multi-agent work. CLAUDE.md
  section 2 points to it. The trigger is principle-based: scope too large for single
  context, or clear specialization benefit.
- Split-pane agent team mode does not work in VS Code integrated terminal or Windows
  Terminal. In-process mode (Shift+Down to cycle teammates) is the only option here.

## Environment Notes

- Python for skill-creator scripts: use the PyCharm venv python.exe — the py.exe
  launcher routes to a Windows Store stub that fails silently.
  Path: C:\Users\alfon\Desktop\Computer Science Programs\PyCharm 2025.2.0.1\
  Programming Fundementals\.venv\Scripts\python.exe
- Eval viewer: always pass --static <path> and open with Start-Process. Server mode
  has no display to bind to in this VS Code + Windows setup.
