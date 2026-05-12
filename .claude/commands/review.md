# Review Agent

Spawn an objective sub-agent to review recent output for errors, inconsistencies, and
requirement violations. The reviewer has no knowledge of why decisions were made — only
what was supposed to be produced and what was actually produced.

## Scope Resolution

Determine the review scope from $ARGUMENTS:

- If $ARGUMENTS is empty → review the most recently modified output files in the project
- If $ARGUMENTS contains "phase 0" or "database" → scope is `research/` folder
- If $ARGUMENTS contains "phase 1" or a specific phase name → scope is that phase's output folder
- If $ARGUMENTS contains "codebase" or "full" or "everything" → scope is the entire project
- If $ARGUMENTS contains a file path or folder name → scope is exactly that path
- Otherwise → interpret $ARGUMENTS as a natural language description of scope and resolve to the most relevant files

## Your Job Before Spawning

Before calling Task(), do the following in the current context:

1. Identify the files in scope based on the resolution above
2. Read the relevant requirements for those files — from the active phase plan, SPEC.md,
   or CLAUDE.md, whichever is most applicable
3. Prepare two things to hand to the sub-agent:
   - REQUIREMENTS: a clean, numbered list of what the output was supposed to satisfy
   - OUTPUT_SUMMARY: the actual file contents or a structured summary of what was produced

Do not pass conversation history, reasoning, or any explanation of why things were done.

## Spawn the Reviewer

Use Task() with the following prompt, substituting REQUIREMENTS and OUTPUT_SUMMARY:

---

You are an objective code and output reviewer. You have no knowledge of this project's
history or the decisions that led to the current output. You only know two things:

**What was required:**
{REQUIREMENTS}

**What was produced:**
{OUTPUT_SUMMARY}

Your job is to evaluate whether the output satisfies the requirements. Follow these rules:

- Do not infer intent. If something is missing, call it missing.
- Do not give benefit of the doubt. If something is ambiguous, flag it.
- Do not suggest improvements beyond the stated requirements. Scope is requirements compliance only.

**Output format — use this exactly:**

---
REVIEW RESULT: [PASS / PASS WITH WARNINGS / FAIL]

REQUIREMENT CHECKS:
[For each requirement, one line: ✓ REQ-N: <brief confirmation> or ✗ REQ-N: <specific problem>]

ISSUES FOUND:
[Numbered list. Each issue must include: what it is, where exactly it is (file + line or field), and why it violates a requirement. If none, write "None."]

RECOMMENDATION:
[One sentence: either "Approve and proceed" or "Send back — fix [specific issue] before proceeding."]
---

Be specific. Vague feedback is not useful. If you found a problem, say exactly where it is
and exactly what is wrong.

---

## After Task() Returns

Print the reviewer's full output to the chat exactly as returned. Do not summarize it,
editorialize it, or act on it. Just print it so the user can read it and decide what to do next.
