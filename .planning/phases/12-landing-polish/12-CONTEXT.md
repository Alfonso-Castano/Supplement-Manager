# Phase 12: Visual Polish - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the landing page look exactly right before real assets (app screenshots, creator photo) are swapped in. Three sub-plans: desktop layout audit at 1440px, mobile/responsive pass at 375px/390px/768px, and animation & interaction polish. Design tokens, colors, and fonts are locked from Phase 10 — this phase audits and fixes how they're applied, not what they are.

</domain>

<decisions>
## Implementation Decisions

### Audit Methodology
- **D-01:** Screenshot-first. Each sub-plan starts with Playwright screenshots at the relevant breakpoint(s), visual review determines what needs fixing, then targeted code changes are made. Audit is driven from what the browser actually renders.

### Animation Quality Bar
- **D-02:** Tune + add hover states. Phase 12-03 scope: fix broken scroll triggers, tune timing/easing/delay on existing `.fade-up` animations, and add meaningful hover states on buttons, cards, and nav links. No new animation types beyond what the existing CSS + Intersection Observer system supports. No GSAP or other libraries.

### Taste Skill Activation
- **D-03:** Proactive. Activate `design-taste-frontend` or `high-end-visual-design` at the start of each sub-plan. Claude applies taste judgments and surfaces quality suggestions, not just obvious bugs. The goal is a high-quality visual result, not a minimum-fix pass.

### Fix Batching
- **D-04:** Fix as you go. Each sub-plan runs as an audit+fix loop: screenshot → identify issue → fix → verify with screenshot. Fixes happen immediately, one section at a time. No separate batch-fix pass.

### Claude's Discretion
- Which specific Taste skill variant to activate per task (`design-taste-frontend` vs `high-end-visual-design` vs `redesign-existing-projects`) — choose based on the nature of the task at hand.
- Specific easing values, transition durations, and hover lift amounts — pick what looks right based on the existing design system.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Tools and workflow
- `.planning/phases/12-landing-polish/TOOLS.md` — Playwright MCP invocation, viewport sizes, dev server startup command

### Design system (locked — do not re-open)
- `.planning/phases/10-landing-page/CONTEXT.md` — Color tokens, font choices, animation class names (`.fade-up`, `.hero-enter`, stagger delays)

### Taste skills
- `landing/.agents/skills/design-taste-frontend/SKILL.md` — Primary skill for desktop audit and mobile pass
- `landing/.agents/skills/high-end-visual-design/SKILL.md` — Visual quality elevation for animation polish
- `landing/.agents/skills/redesign-existing-projects/SKILL.md` — Audit-and-improve mode reference

### Prior phase context
- `.planning/phases/11.5-tool-selection/11.5-CONTEXT.md` — Tool decisions locked in Phase 11.5

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `landing/src/layouts/Layout.astro` — Animation system: `.fade-up` class + Intersection Observer, stagger delay classes `.delay-1` through `.delay-4`, `.hero-enter` keyframes
- `landing/src/components/Nav.astro` — `nav-scrolled` class added after 20px scroll; already has a background/shadow transition
- `landing/src/components/WaitlistForm.astro` — CTA button already has hover styles; use as reference for consistent hover patterns

### Established Patterns
- All section components are standalone `.astro` files in `landing/src/components/`
- Tailwind v4 utility classes throughout; design tokens via CSS custom properties in `global.css`
- Dev server: `cd landing && npm run dev -- --port 4321` (falls back to 4322)
- Playwright screenshots: `mcp__playwright__browser_resize(width, height)` → navigate → `browser_take_screenshot(fullPage: true)`

### Integration Points
- Each sub-plan starts with a Playwright navigate + screenshot before any code changes
- `landing/src/pages/index.astro` assembles all section components in order — the page structure is fixed for Phase 12

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond the decisions above — open to Claude's taste judgment during the audit.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 12-landing-polish*
*Context gathered: 2026-05-19*
