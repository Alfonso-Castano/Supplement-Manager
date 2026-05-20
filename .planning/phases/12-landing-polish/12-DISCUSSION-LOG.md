# Phase 12: Visual Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 12-CONTEXT.md — this log preserves the discussion.

**Date:** 2026-05-19
**Phase:** 12-landing-polish
**Mode:** discuss (default)
**Areas discussed:** Audit methodology, Animation quality bar, Taste skill activation, Fix batching strategy

---

## Questions & Answers

### Audit Methodology
| Question | Options | Selected |
|---|---|---|
| How should the desktop and mobile audits be driven? | Screenshot-first / Code-review-first / Mixed | Screenshot-first |

**Notes:** Audit is driven from what the browser actually renders via Playwright screenshots, not from code review.

---

### Animation Quality Bar
| Question | Options | Selected |
|---|---|---|
| What does 'animation polish' mean for Phase 12-03? | Tune only / Tune + hover states / Full micro-interaction pass | Tune + add hover states |

**Notes:** Fix broken scroll triggers, tune timing/easing on `.fade-up` animations, add hover states on buttons/cards/nav links. No new animation libraries.

---

### Taste Skill Activation
| Question | Options | Selected |
|---|---|---|
| How should the Taste design skills be used during the visual audit? | Proactive / Reactive | Proactive — activate and apply judgment |

**Notes:** Activate `design-taste-frontend` or `high-end-visual-design` at the start of each sub-plan. Claude surfaces quality suggestions proactively, not just fixes for obvious bugs.

---

### Fix Batching Strategy
| Question | Options | Selected |
|---|---|---|
| When the audit finds issues, should fixes happen immediately or be batched? | Fix as you go / Audit first then fix | Fix as you go |

**Notes:** Each sub-plan is an audit+fix loop: screenshot → identify → fix → verify. No separate batch-fix pass.

---

## Deferred Ideas

None.

## Claude's Discretion Items

- Which specific Taste skill variant to activate per task
- Specific easing values, transition durations, hover lift amounts
