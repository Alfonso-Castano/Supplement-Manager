# CLAUDE.md — StackWise

## Project Context

StackWise is an iOS supplement and medication management app. Core features: interaction
analysis, smart daily schedule, reminders. The interaction analysis is the product's
differentiator — it powers everything.

**Before starting any session:**
1. Read the active phase plan file(s) in `.claude/` for current scope, decisions, and constraints. Do not rely on prior context window memory.
2. Read recent learnings: check `.claude/learnings/[relevant-category]/` — read the 1-2 most recent files (sorted by filename date). These capture environment-specific knowledge and failure patterns from prior sessions. Infer the relevant category from the task you are about to begin: `stackwise-app` for iOS app work, `landing-page` for web/deployment work, `ui-design` for design system work. If the folder is empty or the category is unclear, skip this step.

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep the main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent — focused execution only

### 3. Self-Improvement Loop
- **At session start:** Read `.claude/learnings/[relevant-category]/` — the 1-2 most recent
  files tell you what prior agents learned the hard way. Do not skip this if files exist.
- **During session:** After ANY correction from the user, note the pattern internally.
- **At session end:** When the user runs `/end-session`, write a learning file to
  `.claude/learnings/[relevant-category]/YYYY-MM-DD-[slug].md` capturing what went right,
  what went wrong, and the key lessons. Follow the format in `.claude/commands/end-session.md`.
- Categories: `stackwise-app` (iOS code/tests), `landing-page` (web/deployment), `ui-design` (design)
- Learning files capture environment-specific and session-specific knowledge. General
  workflow behavior mistakes go in `.claude/lessons.md` (for cross-session behavioral rules).
- Rules you write must be specific enough to prevent recurrence — vague lessons are useless.

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Run tests, check logs, demonstrate correctness
- Ask yourself: "Would a staff engineer approve this?"
- Diff behavior between before and after your changes when relevant

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI without being told how

---

## Task Management

### 1. Discuss First
- Clarify requirements, edge cases, and constraints before planning
- Capture decisions in the phase `CONTEXT.md`
- Eliminate ambiguity before execution begins

### 2. Plan Phase
- Break work into atomic, verifiable tasks in the phase `PLAN.md`
- Each task needs: a clear action, defined files touched, explicit verification steps
- Tasks should be small enough for isolated execution

### 3. Execute in Isolation
- Execute tasks in clean, fresh contexts — avoid context rot
- Prefer parallel execution where tasks are independent
- One task = one focused execution unit

### 4. Verify Rigorously
- Validate against requirements, not assumptions
- Confirm behavior works end-to-end, not just code correctness
- Use tests, logs, and real usage scenarios

### 5. Track State
- Persist decisions, progress, and blockers in `.claude/STATE.md`
- Maintain system-level awareness of where the project stands across sessions

### 6. Iterate Until Correct
- If verification fails: diagnose root cause, generate fix plan, re-execute immediately
- Continue until requirements are satisfied — no partial done

---

## Human Gates

Human approval is required at stage boundaries. The specific gate triggers and what
to present at each gate are defined in the active phase plan file — defer to those.
General rule: never proceed past a stage boundary without an explicit approval from
the user. When in doubt, stop and check in.

---

## Core Principles

- **Simplicity first.** Make every change as simple as possible. Minimal code impact.
- **No laziness.** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal impact.** Only touch what's necessary. Avoid introducing new surface area.
- **Efficiency over optimization.** Ship working software. Don't over-engineer for
  problems that don't exist yet. User feedback drives iteration, not speculation.
- **Brutal honesty.** Flag problems directly. Don't bury issues in qualifications.
  If something is wrong, say so clearly and say what the fix is.
