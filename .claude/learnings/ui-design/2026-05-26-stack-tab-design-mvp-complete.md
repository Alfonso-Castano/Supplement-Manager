# Session Learnings: Stack Tab Design — MVP Complete

Date: 2026-05-26
Duration: ~3 hours
Outcome: SUCCESS
Category: ui-design
Phase: N/A (design iteration, not a GSD phase)

## What Was Done

Reviewed the Stack tab in the simulator against the Claude Design reference. Classified
all issues into functional, structural, and cosmetic buckets. Generated fix prompts for
the coding agent using the new `prompt-engineer` skill. After functional fixes landed,
applied cosmetic fixes directly (pill icon, title rename) and generated a structural fix
prompt (Add Item button, sticky Analyze footer, severity badge layout). Verified the
result in simulator and marked Stack tab ✅ Complete in DESIGN_PHASE_GATE.md.

## What Went Right

- The three-bucket classification (functional / structural / cosmetic) gave the session
  clear lanes — no ambiguity about what goes to a coding agent vs. what gets fixed here
  vs. what goes to Claude Design
- Skipping Claude Design for structural changes when the design reference already existed
  saved a full round-trip (4–7 min generation + token budget + handoff translation); the
  coding agent translated the existing reference directly to SwiftUI
- The new `prompt-engineer` skill produced a well-structured, self-contained fix prompt
  that the coding agent executed without back-and-forth
- Onboarding → Stack data carryover was verified via a quick subagent trace; confirmed
  working before it became a question in a future session

## What Went Wrong / Blockers

- The `senior-prompt-engineer` skill was wired into Stage 6 of the design skill but
  loaded a generic ML/Python SKILL.md — completely wrong context. The user replaced it
  with a new `prompt-engineer` skill. The first fix prompt was written manually as a
  result; the second was generated correctly via the new skill.
- The `pill.fill` SF Symbol on the Analyze My Stack button appeared to render as a
  pencil-like icon in the simulator. Not investigated further (user accepted it as MVP).
  If this reappears, check `pills` (plural) as an alternative SF Symbol name.

## Key Lessons

- When the Claude Design reference already exists for a screen, do NOT go back to Claude
  Design for structural changes — implement from the reference directly. Only return to
  Claude Design if the design intent is genuinely unresolved.
- Always classify visual feedback into functional / structural / cosmetic before acting.
  Functional issues go to a coding agent prompt. Structural go to Claude Design (or direct
  implementation if reference exists). Cosmetic get fixed inline.
- The `prompt-engineer` skill (not `senior-prompt-engineer`) is the correct skill to
  invoke from Stage 6 of the stackwise-design skill for generating coding agent prompts.
- Analysis screen is next in the design order and already marked ⏳ Not started /
  functionally ready in DESIGN_PHASE_GATE.md. Start fresh context with `/stackwise-design`.
