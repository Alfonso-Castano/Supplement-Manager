---
phase: 0
slug: database-build
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-04
---

# Phase 0 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (Python 3.13 — pre-installed in environment) |
| **Config file** | `pytest.ini` or `pyproject.toml [tool.pytest.ini_options]` — Wave 0 creates |
| **Quick run command** | `python -m pytest research/tests/ -x -q` |
| **Full suite command** | `python -m pytest research/tests/ -v` |
| **Estimated runtime** | ~10 seconds (data pipeline tests, no network) |

---

## Sampling Rate

- **After every task commit:** Run `python -m pytest research/tests/ -x -q`
- **After every plan wave:** Run `python -m pytest research/tests/ -v`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 0-01-01 | 01 | 1 | REQ-04 | — | canonical_names.json has no duplicate keys | unit | `python -m pytest research/tests/test_canonical.py` | ❌ W0 | ⬜ pending |
| 0-02-01 | 02 | 2 | REQ-01 | — | Each source file has URL as first line | unit | `python -m pytest research/tests/test_stage1.py` | ❌ W0 | ⬜ pending |
| 0-03-01 | 03 | 3 | REQ-02, REQ-03 | — | interactions.json records have all required fields | unit | `python -m pytest research/tests/test_stage2.py` | ❌ W0 | ⬜ pending |
| 0-04-01 | 04 | 4 | REQ-01, REQ-05 | — | stackwise.sqlite opens, all tables exist, metadata row present | unit | `python -m pytest research/tests/test_stage3.py` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `research/tests/__init__.py` — test package init
- [ ] `research/tests/test_canonical.py` — stubs for canonical_names.json structure validation
- [ ] `research/tests/test_stage1.py` — stubs for raw file URL-header validation
- [ ] `research/tests/test_stage2.py` — stubs for interactions.json schema validation
- [ ] `research/tests/test_stage3.py` — stubs for SQLite schema + metadata validation
- [ ] `research/tests/conftest.py` — shared fixtures (paths, test data)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 50 target supplements have ≥1 medium+ record | REQ-02 | Requires human judgment on coverage completeness | Review gap_report.md; check each supplement row has status "partially covered" or "well-covered" |
| 20 target medications have ≥1 medium+ record | REQ-03 | Same as above | Same |
| 10 random records spot-checked for accuracy | REQ-01 | Semantic accuracy cannot be automated | Pick 10 random rows from interactions.json; verify effect, suggested_action, and citations are accurate |
| gap_report.md "Not covered" section is empty or has plan | REQ-02, REQ-03 | Requires human decision on whether to continue or ship | Read gap_report.md; all compounds in "Not covered" must either have additional PubMed queries run or be justified |
| Human gate sign-off at each stage boundary | REQ-01 | Defined workflow checkpoint — not automatable | User reviews Stage 1 raw files, Stage 2 interactions.json, Stage 3 SQLite before proceeding |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
