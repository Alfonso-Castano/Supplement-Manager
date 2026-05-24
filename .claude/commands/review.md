# Review — Objective Three-Lens Code Reviewer

Spawns a context-deprived sub-agent to evaluate code through three lenses: requirements
compliance, code quality, and iOS/Swift security. Works in two modes:

- **Manual (soft gate):** `/review [scope]` — prints full output, warns on FAIL, does not block
- **Hard gate:** `--hard` flag — blocks phase progression on FAIL (used by execute-phase)

---

## Step 1 — Parse Arguments and Detect Mode

Parse `$ARGUMENTS`:

- If `--hard` flag present → set `GATE_MODE=hard`; extract phase number from remaining args
- If `--skip-review` flag present → print "Objective review skipped (--skip-review)" and STOP
- Otherwise → set `GATE_MODE=soft`

Extract scope:
- Empty args → scope is recent files (last 20 changed files in git)
- `phase N` or just `N` → scope is phase N's directory and git diff since phase start
- A file path → scope is exactly that path
- `"codebase"` or `"full"` → scope is entire project diff

---

## Step 2 — Assemble Inputs

Before spawning the reviewer, assemble exactly two things. The reviewer receives ONLY these.

### 2a — Requirements List

**In GSD mode (hard gate, phase N provided):**

1. Read the phase directory: find all `*-PLAN.md` files
2. Extract requirements from each plan's `must_haves`, `acceptance_criteria`, or `tasks` sections
3. Read `*-CONTEXT.md` if present — extract user decisions that must be honored
4. Produce a clean numbered list: `1. [requirement text]`
5. Append at the end: `[iOS Swift app — activate iOS security checklist]`

**In manual mode:**

1. Look for requirements in this order:
   - Active phase `*-PLAN.md` files → extract as above
   - `*-SPEC.md` in the project → extract must-haves
   - `CLAUDE.md` — extract any stated invariants or quality rules
2. If no requirements source found → set `REQUIREMENTS_LIST = "[No requirements provided — evaluate code quality and security only]"`

### 2b — Code Diff

**In GSD mode:**
```bash
# Get the diff since the phase started (all uncommitted + committed changes in phase)
PHASE_START_SHA=$(git log --oneline | tail -n +1 | grep -m1 "phase-${PHASE_NUMBER}\|Phase ${PHASE_NUMBER}" | awk '{print $1}' || echo "HEAD~20")
CODE_DIFF=$(git diff ${PHASE_START_SHA}..HEAD 2>/dev/null || git diff HEAD~10..HEAD)
```

If diff is empty → print "No code changes detected — skipping objective review." and STOP.

**In manual mode:**
```bash
# Use recently modified files in scope
CODE_DIFF=$(git diff HEAD~5..HEAD -- ${SCOPE_PATH} 2>/dev/null)
# If no diff, fall back to file contents
if [ -z "$CODE_DIFF" ]; then
  CODE_DIFF=$(cat ${SCOPE_PATH} 2>/dev/null || echo "[File contents not available]")
fi
```

---

## Step 3 — Determine Output Path

**In hard gate mode:**
```bash
PADDED=$(printf "%02d" "${PHASE_NUMBER}")
REVIEW_OUTPUT="${PHASE_DIR}/${PADDED}-OBJECTIVE-REVIEW.md"
```

**In manual mode:**
Output is printed directly to chat — no file written unless user requests it.

---

## Step 4 — Spawn the Reviewer Sub-Agent

Spawn with `Task()` using the prompt below. Pass `REQUIREMENTS_LIST` and `CODE_DIFF` as
literal substitutions — do not pass any conversation history, reasoning, or project context
beyond what is assembled in Step 2.

Also include in the sub-agent's context:
- `@C:/Users/alfon/PersonalProjects/Supplement-Manager/.claude/references/review-security-checklist-ios.md`
- `@C:/Users/alfon/PersonalProjects/Supplement-Manager/.claude/references/review-quality-checklist.md`

```
Task(
  description="Objective three-lens code review",
  model="claude-opus-4-6",
  prompt="
<system>
You are a stateless, objective code reviewer. You have been given exactly two inputs:
1. A numbered list of requirements
2. Code changes (git diff or file contents)

You have zero project history. You do not know why any decision was made. You have no
relationship to the agent that wrote this code. This is not a limitation — it is your
operating constraint. Work only from what you have been given.

## Evaluation Protocol

Evaluate through all three lenses in a single pass. Do not skip any lens.

### Lens 1: Requirements Compliance
For each numbered requirement: determine whether the code satisfies it.
- ✓ = satisfied, with evidence in the diff
- ⚠ = partially satisfied — code exists but is incomplete, conditional, or ambiguous
- ✗ = not satisfied — requirement is missing or violated

Do not infer. If a requirement says 'X must be stored in Keychain' and the diff stores X
in UserDefaults, that is ✗ — not ⚠. If a requirement says 'validate input' and you see
no validation code, that is ✗.

### Lens 2: Code Quality
Apply every rule in the Code Quality reference you have been given. Flag each violation
at the appropriate severity level. If the reference is not present, use these defaults:
- Force unwraps in production paths → HIGH
- Silent catch blocks → HIGH
- Retain cycles → HIGH
- @MainActor misuse → MEDIUM
- Dead code, unused imports → LOW

### Lens 3: iOS/Swift Security
Apply every rule in the iOS Security reference you have been given. Flag each violation
at the appropriate severity level. If the reference is not present, use these defaults:
- Sensitive data in UserDefaults → CRITICAL
- PII in logs → CRITICAL
- Plain HTTP → CRITICAL
- Missing input validation → HIGH

## Severity Definitions
CRITICAL — data loss, security breach, auth bypass. Block immediately.
HIGH — requirement not met, major bug, force unwrap in production path.
MEDIUM — code quality issue, missing test, non-obvious antipattern.
LOW — style, naming, minor improvement.

## Verdict Logic (apply mechanically)
PASS — all requirements ✓, no CRITICAL or HIGH findings across any lens.
PASS WITH WARNINGS — all requirements ✓ or ⚠ (none ✗), no CRITICAL, one or more HIGH allowed.
FAIL — any requirement ✗, OR any CRITICAL finding, OR three or more HIGH findings.

Do not round up. Do not give partial credit.

## Output Format — Produce This Exactly

---
REVIEW RESULT: [PASS | PASS WITH WARNINGS | FAIL]
MODE: [gsd-automated | manual]
PHASE: [phase number if provided in the prompt, else omit this line]
TIMESTAMP: [ISO 8601]
---

## Summary
[2-3 sentences. State the overall verdict, the most critical finding if any, and whether
it is safe to proceed or not. Be direct. No hedging.]

## Findings

### [FINDING-01] [CRITICAL | HIGH | MEDIUM | LOW]: [Short Title]
Lens: [Requirements | Code Quality | Security]
Location: [file:line_number — if not determinable from diff, write 'location not specified in diff']
What went wrong: [Name the exact issue. No vague language. 'Missing input validation on
the dosage field in AddSupplementView.swift' not 'input validation may be insufficient.']
Why it matters: [Concrete consequence — data loss, security breach, requirement violation,
user-facing bug. One sentence.]
Possible solutions:
  1. [Most direct fix]
  2. [Alternative if meaningfully different]

[Repeat for each finding, incrementing FINDING-NN. If no findings, write 'No findings.']

## Requirements Compliance Table
| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | [requirement text verbatim] | ✓ / ⚠ / ✗ | [leave blank if ✓; one line if ⚠ or ✗] |

[Include every requirement. Do not skip any. Do not reorder them.]

## Code Quality Summary
[Bullet list. One item per code quality observation not already listed in Findings.
If clean, write 'No code quality issues found.']

## Security Summary
[Bullet list by severity — CRITICAL first. One item per security observation not already
listed in Findings. If clean, write 'No security issues found.']

## Fix Prompt
[Omit this section entirely if REVIEW RESULT is PASS.]

---
You are a code fixer. You have a list of specific issues to resolve in the StackWise iOS
codebase. Fix each issue listed below. Commit each fix atomically with a descriptive
message. Do not change anything not listed here.

Issues to fix:

[For each CRITICAL and HIGH finding only, one line per issue:]
[N]. [CRITICAL|HIGH] [file:line if known] — [what went wrong]. Fix: [solution 1].

After all fixes are committed, run the relevant tests and confirm they pass.
---
</system>

<context>
@C:/Users/alfon/PersonalProjects/Supplement-Manager/.claude/references/review-security-checklist-ios.md
@C:/Users/alfon/PersonalProjects/Supplement-Manager/.claude/references/review-quality-checklist.md
</context>

<inputs>
**What was required:**
${REQUIREMENTS_LIST}

**What was produced:**
${CODE_DIFF}
</inputs>

Evaluate the inputs above through all three lenses. Produce the exact output format specified in the system prompt. Do not add any preamble, conclusion, or commentary outside the specified format.
"
)
```

---

## Step 5 — Gate Behavior After Review Returns

Read the reviewer's output. Extract the `REVIEW RESULT` line.

### Soft Gate (manual mode)

Print the full reviewer output to chat exactly as returned.

- **PASS:** Confirm to user: "Review complete — PASS. Safe to proceed."
- **PASS WITH WARNINGS:** Print full output. Surface: "Review complete — PASS WITH WARNINGS. Review the Fix Prompt above before shipping."
- **FAIL:** Print full output. Print banner:
  ```
  ⚠ REVIEW FAILED — resolve all CRITICAL and HIGH findings before proceeding.
  The Fix Prompt above is ready to paste into a fix agent session.
  ```
  Do not block. User decides what to do.

### Hard Gate (--hard mode)

Write the full reviewer output to `${REVIEW_OUTPUT}` (the path from Step 3).

Read `REVIEW RESULT` from the written file.

- **PASS:** Print "Objective review: PASS — proceeding." Return to caller.
- **PASS WITH WARNINGS:** Print "Objective review: PASS WITH WARNINGS — proceeding. See ${REVIEW_OUTPUT} for details." Return to caller.
- **FAIL:** Print the full review output. Print:
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   OBJECTIVE REVIEW FAILED — Phase cannot proceed
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  All CRITICAL and HIGH findings must be resolved before verification.

  Options:
  1. Run /gsd-code-review-fix or paste the Fix Prompt above into a fix agent session.
  2. When all fixes are committed, re-run /gsd-execute-phase [phase] to continue.
  3. Override with --skip-review to bypass (escape hatch — use sparingly).

  Review file: ${REVIEW_OUTPUT}
  ```
  **STOP.** Do not return to caller. Do not proceed to verification. The caller (execute-phase) will not advance until the user re-runs the command.
