# Continue Here — StackWise Landing Page

**Last session:** 2026-05-20
**Branch:** main
**Last commit:** `cc1d6b2` — feat(12): SkillUI visual polish

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
- Wave 2 (12-02): PENDING — mobile responsive audit (375px, 390px, 768px)
- Wave 3 (12-03): PENDING — animation polish (hover states, Playwright scroll verification)

---

## What was just built (this session)

8 visual changes inspired by SkillUI extraction of SuppCo + Duolingo:

| Change | File |
|--------|------|
| Hero headline 52→72px | `landing/src/components/Hero.astro` |
| Warm hero bg `#FAFAF8` | `landing/src/components/Hero.astro` |
| 2-blob visible gradient behind hero | `landing/src/components/Hero.astro` |
| Ambient blue glow + cinematic shadow on phone mockup | `landing/src/components/Hero.astro` |
| `reveal-in` scale+translate entrance on hero mockup | `landing/src/components/Hero.astro` |
| Spring easing `cubic-bezier(.19,1,.22,1)` on all animations | `landing/src/styles/global.css` |
| Dark section FinalCTA (`bg-[var(--color-heading)]`, white text) | `landing/src/components/FinalCTA.astro` |
| Blue-tinted card surface on HowItWorks step text blocks | `landing/src/components/HowItWorks.astro` |
| `WaitlistForm` dark variant (glassmorphism input) | `landing/src/components/WaitlistForm.astro` |
| `@layer base` fix — Tailwind color utilities now override heading defaults | `landing/src/styles/global.css` |

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

**Install (already done on this machine):**
```bash
npm install -g skillui
npm install -g playwright && npx playwright install chromium
```

**Run:**
```bash
cd landing
npx skillui --url https://example.com/ --name site-name --out ".agents/skills/frontend-references/site-name/site-name-design"
```

**Output lands in:** `landing/.agents/skills/frontend-references/{site}/`
**Bridge skill file:** `landing/.agents/skills/frontend-references.md` — read this to know what references exist and their key signals.

**Already extracted:**
- `suppco` — https://supp.co/ → dark theme, spring easing, cinematic shadows, `reveal-in` keyframe
- `duolingo` — https://www.duolingo.com/ → 70 animations, bold section contrast, `#ddf4ff` surface

**When to use:** Any time the user says "make this feel more like X" or references another website for inspiration — run SkillUI on it first, then apply the extracted tokens directly.

---

## Playwright MCP (for visual verification)

Already configured in `.mcp.json`. Tools available as `mcp__playwright__browser_*`.

Standard screenshot flow:
```
resize(1440, 900) → navigate(http://localhost:4321) → evaluate(force-reveal animations) → take_screenshot(fullPage: true)
```

Force-reveal all animations for screenshots:
```js
document.querySelectorAll('.fade-up, .hero-enter, .reveal-in').forEach(el => {
  el.style.cssText += '; opacity: 1 !important; transform: none !important; animation: none !important;';
  el.classList.add('visible');
});
```

---

## Pending tweaks (user has more changes to make)

User mentioned additional tweaks — gather them at the start of the next session before executing.

---

## Post-Vercel deployment workflow

When the site is live on Vercel:
- Small tweaks: edit locally → `npm run dev` to verify → `git push origin main` → Vercel auto-deploys (~1 min)
- Larger changes: open a new GSD phase (e.g., Phase 13), plan → execute → push
- Preview deployments: push to a branch → Vercel creates a preview URL automatically
- Rollback: `git revert <commit>` → push → Vercel redeploys previous version
