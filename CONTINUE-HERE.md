# Continue Here — StackWise Landing Page

**Last session:** 2026-05-20
**Branch:** main
**Last commit:** `238d8da` — fix(12-02): marquee CSS to global.css + Google favicon logos

---

## What this project is

StackWise is an iOS supplement/medication interaction app. This repo has two parts:
- `StackWise/` — iOS app (Swift)
- `landing/` — Astro + Tailwind v4 landing page (the active work area)

The landing page dev server: `cd landing && npm run dev -- --port 4321`

---

## Active workflow: GSD (Get Shit Done)

Phase-based execution system. Plans live in `.planning/phases/`. Each phase has:
- `CONTEXT.md` — decisions and constraints
- `PLAN.md` (or numbered plans like `12-01-PLAN.md`) — atomic tasks
- Execute via `/gsd:execute-phase <N>` skill

**Current phase: 12 — Landing Visual Polish**
- Wave 1 (12-01): COMPLETE — bug fixes + desktop text/icon audit
- Wave 2 (12-02): IN PROGRESS — visual + motion tweaks (see below for remaining item)
- Wave 3 (12-03): PENDING — animation polish (hover states, Playwright scroll verification)
- Wave 4 (mobile): PENDING — mobile responsive audit (375px, 390px, 768px)

---

## Immediate next task (do this first)

**CredibilityBar source pills — make them larger**

File: `landing/src/styles/global.css` (the `.cred-marquee-pill` and `.cred-logo` rules)
File: `landing/src/components/CredibilityBar.astro` (section padding)

Current sizes:
- Font: `13px`, weight `600`
- Logo: `20px × 20px`
- Pill padding: `7px 16px 7px 10px`
- Gap between logo and text: `8px`
- Section vertical padding: `py-10`

Target: approximately 3–4× more prominent. Suggested values to try:
- Font: `17px`, weight `700`
- Logo: `36px × 36px`
- Pill padding: `12px 24px 12px 16px`
- Gap: `12px`
- Section padding: increase to `py-14` or `py-16` so the bar feels substantial

After applying, take a Playwright screenshot at 1440×900 to verify pills are prominent. Commit with message: `feat(12-02): larger credibility source pills`

---

## What was built in this session (Phase 12 Wave 2)

Full visual + motion overhaul across two subagent phases + several inline tweaks:

| Change | File |
|--------|------|
| 3D Duolingo-style buttons (bottom shadow, press effect) | `WaitlistForm.astro`, `FinalCTA.astro` |
| Bolder typography — h1 `font-800`, h2 `font-800 tracking-tighter` | `global.css` + all section components |
| iOS number badges on HowItWorks steps (01/02/03) | `HowItWorks.astro` |
| Removed blue-tint card bg from HowItWorks text blocks | `HowItWorks.astro` |
| iOS number badges on FeatureSection (04/05) | `FeatureSection.astro` (new `number` prop) |
| Zigzag layout on FeatureSections (flip prop) | `index.astro` |
| Hero headline → "Your supplements / may be working / against each other" (3 lines, 60px) | `Hero.astro` |
| Screen flow: 01 Stack Entry → 02 Analysis Results → 03 Interaction Analysis → 04 Daily Schedule → 05 Reminders | `HowItWorks.astro`, `index.astro` |
| CredibilityBar: single-row animated marquee with Google Favicon logos | `CredibilityBar.astro`, `global.css` |
| Re-triggering scroll animations (fade-up re-arms on scroll-out) | `Layout.astro` |

---

## Design system (locked from Phase 10)

**File:** `landing/src/styles/global.css`

```
--color-blue-tint:   #E8F4F8   (light blue surfaces)
--color-blue-accent: #2B9EB3   (CTAs, links, focus rings)
--color-blue-dark:   #1E7A8C   (hover states)
--color-green-tint:  #E8F0EC
--color-green-accent:#6B9E7F
--color-heading:     #1A1A2E   (dark navy — also used for dark sections)
--color-body:        #4A4A60
--color-muted:       #8888A0
Font heading: Outfit
Font body:    DM Sans
```

---

## SkillUI — how it works

SkillUI reverse-engineers a design system from any live URL.

**Run:**
```bash
cd landing
npx skillui --url https://example.com/ --name site-name --out ".agents/skills/frontend-references/site-name/site-name-design"
```

**Already extracted:**
- `suppco` — https://supp.co/ → dark theme, spring easing, cinematic shadows
- `duolingo` — https://www.duolingo.com/ → 70 animations, bold section contrast

---

## Playwright MCP (for visual verification)

Already configured in `.mcp.json`. Tools available as `mcp__playwright__browser_*`.

Standard screenshot flow:
```
resize(1440, 900) → navigate(http://localhost:4321) → evaluate(force-reveal) → take_screenshot(fullPage: true)
```

Force-reveal all animations for screenshots:
```js
document.querySelectorAll('.fade-up, .hero-enter, .reveal-in').forEach(el => {
  el.style.opacity = '1';
  el.style.transform = 'none';
  el.classList.add('visible');
});
```

---

## Wave 3 — Animation polish (next after Wave 2 is done)

Goals:
- Hover states on buttons, cards, phone mockups (subtle lift/glow)
- Verify scroll animations work correctly across the full page using Playwright
- Any remaining motion refinements

---

## Wave 4 — Mobile responsive audit

Viewports to test: 375px, 390px, 768px

Known risks:
- Hero headline line breaks (`<br>` tags) may look odd on mobile — may need to remove them at small viewports and let text flow naturally
- HowItWorks grid collapses to single column — verify badge + content stacking order
- FeatureSection flip layout — verify phone mockup doesn't disappear or misalign
- CredibilityBar marquee — verify it doesn't overflow or look too small on mobile

---

## Post-Vercel deployment workflow

- Small tweaks: edit locally → `npm run dev` to verify → `git push origin main` → Vercel auto-deploys (~1 min)
- Larger changes: open a new GSD phase, plan → execute → push
- Rollback: `git revert <commit>` → push → Vercel redeploys previous version
