# End-Session — Session Learning Capture

Write a structured learning file at the close of a meaningful session. Run this manually
when you decide real work was done. The file is written to the correct `learnings/`
subfolder and committed. Future agents read these files before starting work.

---

## Step 1 — Parse Arguments

Check `$ARGUMENTS`:

- If a category is explicitly passed (e.g., `/end-session stackwise-app`) → use it directly,
  skip Step 2
- Valid categories: `stackwise-app`, `landing-page`, `ui-design`
- Otherwise → run category detection in Step 2

---

## Step 2 — Detect Category (if not passed explicitly)

Run these checks in order, stopping at the first conclusive result:

### Check 1: Active GSD phase

```bash
ACTIVE_PHASE=$(grep "Current phase\|current_phase\|Active phase" .planning/STATE.md 2>/dev/null | head -1 || echo "")
```

Infer from the phase name or description:
- Phase references iOS app code, tests, architecture, Xcode, Swift → `stackwise-app`
- Phase references landing page, web, Next.js, Vercel, deployment → `landing-page`
- Phase references design, UI, Claude Design, design system, visual → `ui-design`

### Check 2: Git diff

```bash
CHANGED_FILES=$(git diff --name-only HEAD~10 HEAD 2>/dev/null | head -30)
```

File path rules:
- `StackWise/`, `StackWiseTests/`, `StackWise.xcodeproj/`, `*.swift`, `*.xcworkspace` → `stackwise-app`
- `landing/`, `pages/`, `components/`, `*.tsx`, `*.jsx`, `vercel.json`, `next.config.*` → `landing-page`
- `references/DESIGN.md`, `assets/`, `*.figma`, design token files → `ui-design`

If files span multiple categories → note it; write to the most active category and add a
cross-reference note in the file.

### Check 3: Ask user

If still ambiguous after both checks, ask with a single question:

"Which category does this session's work belong to?
1. stackwise-app (iOS app code, tests, architecture)
2. landing-page (landing page code, design, deployment)
3. ui-design (design system, visual decisions)
4. Multiple — write separate files"

If "Multiple": determine the two most relevant categories and offer to write one file per
category, or a single file in the primary category with a note.

---

## Step 3 — Generate File Name

Construct: `YYYY-MM-DD-[slug].md`

- Date: today's date in YYYY-MM-DD format
- Slug: 3-5 word kebab-case description of the session's main activity
  - Derive from: what the session accomplished, what phase was active, what the key deliverable was
  - Examples: `phase-4-test-verification`, `interaction-analysis-refactor`, `landing-hero-section`
  - Keep it specific enough to be useful when scanning a file list

Full path: `learnings/[category]/[filename]`

---

## Step 4 — Draft the Learning File

Write the file content into the chat for the user to review. Follow this format exactly:

```markdown
# Session Learnings: [Brief description of what was done]

Date: YYYY-MM-DD
Duration: [estimate if known, e.g., "~2 hours" — write "unknown" if not clear]
Outcome: [SUCCESS | PARTIAL | FAILED | PLANNING]
Category: [stackwise-app | landing-page | ui-design]
Phase: [GSD phase number if applicable, e.g., "Phase 4" — write "N/A" if not in a GSD phase]

## What Was Done

[3-5 sentences max. Factual summary. What was attempted, what was completed, what was left
open. No command logs, no code snippets unless the pattern IS the lesson.]

## What Went Right

- [Specific approach, decision, or technique that worked and should be repeated]
- [Focus on non-obvious wins — things the next agent wouldn't naturally do without being told]
- [2-6 items]

## What Went Wrong / Blockers

- [Specific failure, dead end, or blocker. For each: what happened, why, better approach.]
- [Be concrete: not "tests were slow" but "xcodebuild test rebuilds from scratch every run
  in this VM; use test-without-building instead."]
- [2-6 items. If nothing went wrong, write a single item: "No significant blockers."]

## Key Lessons

- [The most important takeaway — what a future agent MUST know before starting similar work]
- [This section is read first. Keep it tight and actionable.]
- [2-5 items]

## Environment Notes

[Only include this section if environment-specific quirks were discovered.]
[VM behavior, simulator issues, macOS-specific behavior, Xcode version quirks, etc.]
[Omit this section entirely if not relevant.]
```

### Content rules

- Distilled, not comprehensive. Target 30-80 lines.
- No step-by-step command logs.
- No code snippets unless the specific pattern is the lesson (paste it if so, briefly).
- No decisions already captured in PLAN.md, CONTEXT.md, or CLAUDE.md.
- No general programming knowledge — only project/environment-specific learnings.
- Outcome meanings: SUCCESS = goal fully achieved, PARTIAL = partial progress made,
  FAILED = work attempted but not completed, PLANNING = discuss/plan session only.

---

## Step 5 — Confirmation Gate

After presenting the draft, ask:

"Write this to `learnings/[category]/[filename].md`?

- **yes** → write and commit
- **edit** → describe what to change, I'll revise and ask again
- **skip** → discard, session ends normally"

Wait for the user's response.

### If "edit"

Apply the user's corrections to the draft. Show the revised content. Ask the confirmation
question again. Repeat until "yes" or "skip".

### If "skip"

Print: "Session learnings discarded. Nothing written." STOP.

---

## Step 6 — Write and Commit

On "yes":

1. Write the file to `learnings/[category]/[filename].md`
2. Commit:
   ```bash
   git add learnings/[category]/[filename].md
   git commit -m "docs(learnings): [YYYY-MM-DD] [category] — [brief outcome in 5-8 words]"
   ```
   Example commit message: `docs(learnings): 2026-05-24 stackwise-app — phase 4 test verification complete`

3. Confirm to user:
   ```
   Session learnings written to learnings/[category]/[filename].md
   
   Future agents working on [category] will read this before starting.
   ```

---

## Notes for the Agent Writing the File

- You have full session context. Use it. The file is your distillation of what actually
  happened, not a template fill-in.
- If the session was entirely planning (no execution), Outcome = PLANNING and Key Lessons
  should cover what was clarified, decided, or ruled out.
- If the session failed to complete its goal, be direct about why. The next agent needs
  to know what doesn't work, not just what does.
- The Key Lessons section is the most important part. A future agent reads it first.
  Make it earn its place.
