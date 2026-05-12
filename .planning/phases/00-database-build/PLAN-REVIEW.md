# Phase 0 Plan Review — Issues for Claude Code to Understand and Fix

**Scope:** 00-01-PLAN.md through 00-04-PLAN.md  
**Prepared for:** Claude Code executor in VS Code  
**Purpose:** These are real issues found in the plan files. Read each one, understand why it
will cause a problem, and apply the fix before executing the affected task.

---

## Issue 1 — Duplicate entry in the 50-supplement list (00-01-PLAN.md, Task 3)

### What the problem is
In Task 3 of Plan 01, the supplement list used to generate `target_list.json` contains
`vitamin_b_complex` twice. Here is the relevant excerpt:

```
vitamin_d3, magnesium, omega_3_fatty_acids, ..., potassium,
phosphatidylserine, lions_mane, iodine, niacin_vitamin_b3, vitamin_b_complex
```

`vitamin_b_complex` appears earlier in the list AND again at the end. The instruction also
includes this note: *"remove duplicates; final list must be EXACTLY 50 unique entries"* —
but it does not tell you what the 50th unique entry should be when the duplicate is removed.
Counting the list as written (after deduplication) yields only 49 unique entries. The
acceptance criteria and automated verification both assert exactly 50 supplements.

### Why this will cause a failure
The `stage0_setup.py` script generates `target_list.json`. The verification script then runs:
```python
assert supp_count == 50, f'Expected 50 supplements, got {supp_count}'
```
If you deduplicate the list as instructed, you get 49 entries and this assertion fails,
blocking all downstream plans. If you do NOT deduplicate and keep both entries, the assertion
passes but you have a duplicate canonical name in the database, which breaks pairwise
lookups downstream.

### What to fix
Before generating `target_list.json`, resolve which compound fills the 50th slot. The most
likely intended entry based on the broader target list context is `nmn`
(nicotinamide mononucleotide) — it is a high-profile supplement commonly included in top-50
lists alongside the others here. Check `00-RESEARCH.md` for the Tier 2 supplement list;
use whatever compound appears there as the intended 50th entry. Do not add `vitamin_b_complex`
twice. The final list must be 50 unique canonical names.

---

## Issue 2 — `canonical_names.json` alias format becomes inconsistent after timing_properties are added (00-03-PLAN.md, Task 2 / 00-04-PLAN.md, Task 2)

### What the problem is
Plan 01 defines `canonical_names.json` with a simple format:
```json
{ "vitamin_d3": ["cholecalciferol", "vitamin d", "vitamin d3"] }
```
Values are plain arrays.

Plan 03 Task 2 instructs you to add `timing_properties` to compound entries in
`canonical_names.json`. The Plan 04 compile script (`stage3_compile.py`) handles this by
checking `isinstance(value, list)` vs `isinstance(value, dict)` — this is correct and
intentional. However, the `resolve_canonical` function in `utils.py` (Plan 01, Task 2)
**only** handles the simple array format:

```python
for canon_key, aliases in canonical.items():
    if canon_key.startswith("_"):
        continue
    if isinstance(aliases, list) and name_lower in [a.lower() for a in aliases]:
        return canon_key
```

The condition `isinstance(aliases, list)` will be `False` for any compound whose entry has
been upgraded to the dict format `{"aliases": [...], "timing_properties": {...}}`. This means
after Plan 03 Task 2 runs and writes timing_properties, alias resolution will silently fail
for those compounds. `resolve_canonical` will raise a `LookupError` for any alias of a
compound with timing properties, causing Stage 2 to skip records it should write.

### Why this will cause a failure
This is a silent data loss issue. `write_record()` catches `LookupError` and returns
`"skipped_unresolved"` — no crash, just a missing record. You will not notice until the
gap report in Plan 04 shows compounds with 0 records that should have records. The compounds
most at risk are exactly the ones with the most important timing data: `melatonin`, `iron`,
`vitamin_d3`, `magnesium`, `coenzyme_q10`.

### What to fix
Update `resolve_canonical` in `utils.py` to handle both value formats before Stage 2 runs:

```python
def resolve_canonical(name: str, canonical: dict) -> str:
    name_lower = name.lower().strip()
    for key in canonical:
        if key.startswith("_"):
            continue
        if key == name_lower:
            return key
    for canon_key, value in canonical.items():
        if canon_key.startswith("_"):
            continue
        # Handle both simple list and extended dict format
        if isinstance(value, list):
            aliases = value
        elif isinstance(value, dict):
            aliases = value.get("aliases", [])
        else:
            continue
        if name_lower in [a.lower() for a in aliases]:
            return canon_key
    raise LookupError(
        f"'{name}' not found in canonical_names.json — add it before writing a record"
    )
```

Also update `load_canonical` and any other function that reads alias arrays to handle
both formats consistently. Make this change in `utils.py` before running Stage 2.

---

## Issue 3 — `merge_record` conflict_note uses stale confidence label after update (00-01-PLAN.md, Task 2)

### What the problem is
In `merge_record`, when the new source has higher confidence and the severity changes, the
`conflict_note` is built using `existing_conf_label`:

```python
existing_conf_label = existing.get("confidence", "unknown")
existing["conflict_note"] = (
    f"Severity conflict: original source ({existing_conf_label}) rated {old_sev}; "
    f"new source ({new_conf_label}) rated {new_sev}. "
    f"Resolution: {existing['severity']} (per D-15 rules)."
)
```

But this code runs **after** the line `existing["confidence"] = new_record["confidence"]`
(line ~331 in the plan). By the time `conflict_note` is written, `existing["confidence"]`
has already been updated to the new value. So `existing_conf_label = existing.get("confidence")`
returns the NEW confidence, not the original. The conflict note will say both the original
and new source had the same confidence tier, which is wrong and makes the note misleading
for manual spot-checking.

### Why this matters
The conflict_note's purpose (D-16) is to make disagreements visible during the human
spot-check gate. A note that misreports confidence levels defeats that purpose. It won't
break the pipeline, but it will produce inaccurate audit trail data.

### What to fix
Capture the original confidence label before any mutation. Move the capture to the top
of the function, before the confidence update block:

```python
# Capture originals before any mutation
original_conf_label = existing.get("confidence", "unknown")
original_sev = existing.get("severity", "advisory")
```

Then use `original_conf_label` (not `existing.get("confidence")`) when building the
`conflict_note` string. The variable `existing_conf_label` is currently assigned mid-function
after mutations have already occurred — move it up.

---

## Issue 4 — Gap report hard floor check guard in `stage3_compile.py` is fragile (00-04-PLAN.md, Task 2)

### What the problem is
The compile script guards against compiling with a failing hard floor using this check:

```python
if "FAIL" in gap_content and "PASS" not in gap_content:
    print("ERROR: gap_report.md shows FAIL on hard floor check.")
    sys.exit(1)
```

The condition requires BOTH `"FAIL"` to be present AND `"PASS"` to be absent. But after
PubMed gap-filling closes all gaps, the gap report will contain the text `"PASS"` (the
hard floor verdict) AND may still contain the word `"FAIL"` in historical context — for
example if the recommended PubMed search URLs contain the word "fail" in a log note, or
if the report was written iteratively and has both "FAIL" and "PASS" sections from
multiple runs. More concretely: `gap_report.md` is a living document (D-20) that appends
entries. If it was ever written with a FAIL verdict and then updated to PASS, both words
exist in the file. The guard passes, which is correct — but the logic is fragile and
depends on `"PASS"` being present, which it only is after a successful gap-fill run.

More importantly: the guard checks the raw file for the string `"PASS"` anywhere in the
document. The gap report format has the verdict as `**PASS**` (with markdown bold markers).
The string `"PASS"` still matches inside `**PASS**` so this works — but it's worth
understanding that the actual assertion logic relies on substring presence, not a structured
field.

### Why this matters
This is a correctness risk: if the gap report is malformed or generated with unexpected
content, the guard silently passes and you compile a database that fails REQ-02/REQ-03.
The compile then exits with code 0, the test suite runs against the SQLite file, and
`test_supplement_coverage` or `test_medication_coverage` fails — which is a late, noisy
failure instead of an early, clean one.

### What to fix
Replace the fragile string-presence check with a more explicit check that reads the actual
`generate_gap_report()` function's return value. Since you already have
`stage3_validate.py` and it exits with code 1 on FAIL, the cleanest fix is to run it as a
subprocess check before compiling, OR check the gap report for the specific section string:

```python
# More specific: check that the Hard Floor Check section says PASS
import re
hard_floor_match = re.search(r'## Hard Floor Check.*?\n\*\*(PASS|FAIL)\*\*', gap_content, re.DOTALL)
if not hard_floor_match or hard_floor_match.group(1) != "PASS":
    print("ERROR: Hard floor check is not PASS in gap_report.md. Run stage3_validate.py first.")
    sys.exit(1)
```

This is more robust because it anchors the check to the specific section and verdict marker
rather than checking for any occurrence of "PASS" anywhere in the file.

---

## Issue 5 — `already_collected` in `utils.py` uses `.txt` extension by default, but OpenFDA files are `.json` — and Plan 02 reimplements this check rather than using the shared function (00-02-PLAN.md, Task 2)

### What the problem is
`already_collected` in `utils.py` has signature:
```python
def already_collected(output_dir: Path, canonical_name: str, extension: str = ".txt") -> bool:
```

The function supports an `extension` parameter. However, `stage1_collect_openfda.py`
(Plan 02, Task 2) does not use `already_collected` at all. Instead it defines its own
local function:

```python
def already_collected_openfda(canonical_name: str) -> bool:
    path = RAW_OPENFDA_DIR / f"{canonical_name}_openfda.json"
    return path.exists() and path.stat().st_size > 0
```

This works correctly, but it also diverges from the shared utility pattern. If
`already_collected` in `utils.py` is ever updated (e.g., to add a minimum file size
threshold or a timestamp check), the OpenFDA script won't benefit from the update.
This is a maintainability issue, not a correctness issue right now.

More importantly: the `already_collected_openfda` function constructs the filename as
`{canonical_name}_openfda.json`, but the verification step in Plan 02 checks for files
matching `*.json` in the openfda directory without the `_openfda` suffix check. This is
consistent internally, so it won't break — but note that the file naming convention
(`vitamin_d3_openfda.json`) differs from the HTML source convention (`vitamin_d3.txt`).
The Stage 2 extraction script needs to account for this naming difference when reading
OpenFDA files.

### What to fix
In `stage1_collect_openfda.py`, replace the local function with a call to the shared utility:

```python
from research.scripts.utils import already_collected

# In the main loop:
if already_collected(RAW_OPENFDA_DIR, f"{name}_openfda", extension=".json"):
    ...
```

This is a minor consistency fix. More importantly: confirm that Plan 03's
`stage2_extract.py` reads OpenFDA files using the `{name}_openfda.json` pattern when
iterating over `research/raw/openfda/` — the filename includes the `_openfda` suffix,
not just `{name}.json`.

---

## Summary Table

| # | Issue | Plan | Task | Severity | Will it break execution? |
|---|-------|------|------|----------|--------------------------|
| 1 | Duplicate `vitamin_b_complex` leaves only 49 unique supplements | 00-01 | Task 3 | **High** | Yes — assertion failure on count check |
| 2 | `resolve_canonical` breaks for compounds with timing_properties (dict format) | 00-01 / 00-03 | utils.py / Task 2 | **High** | Yes — silent record loss, gap report FAIL |
| 3 | `conflict_note` logs wrong confidence label due to mutation order | 00-01 | Task 2 | Medium | No crash, but produces inaccurate audit data |
| 4 | `stage3_compile.py` hard floor guard is fragile string-match | 00-04 | Task 2 | Medium | Possible silent compile on bad gap report |
| 5 | OpenFDA uses local `already_collected` clone instead of shared utility | 00-02 | Task 2 | Low | No — works correctly, consistency issue only |

---

## Execution Recommendation

Fix Issues 1 and 2 before running any plan. They will cause hard failures.

Fix Issue 3 in `utils.py` at the same time as Issue 2 — you're already editing that file.

Fix Issue 4 in `stage3_compile.py` before running Plan 04 Task 2.

Issue 5 can be fixed opportunistically when writing `stage1_collect_openfda.py`.
