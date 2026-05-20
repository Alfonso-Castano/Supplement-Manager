# Continue Here — StackWise Landing Page

**Last session:** 2026-05-20
**Branch:** main
**Last commit:** `096fca3` — feat(12-03): hover states — button 3D lift, card lift, phone glow

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

**Current phase: 12 — Landing Visual Polish — COMPLETE**
- Wave 1 (12-01): COMPLETE — bug fixes + desktop text/icon audit
- Wave 2 (12-02): COMPLETE — visual + motion tweaks (pills, 3D buttons, hero, sections)
- Wave 3 (12-03): COMPLETE — hover states (button 3D lift, card lift, phone glow)
- Wave 4 (mobile): COMPLETE — mobile responsive audit (375px, 390px, 768px) — no fixes needed

---

## Phase 12 is done. What's next?

**Recommended next work:**
1. **Real assets swap** — replace phone mockups with actual app screenshots once they exist
2. **Creator photo** — add Alfonso's face to CreatorStory section (currently placeholder avatar)
3. **Video section** — VideoSection.astro says "Video coming soon" — record a demo
4. **Vercel deploy** — push to production if not already deployed (`git push origin main`)
5. **Analytics** — add Vercel Analytics or Plausible for tracking waitlist signups

---

## What was built in Phase 12

| Change | File |
|--------|------|
| 3D Duolingo-style buttons (bottom shadow, press + hover lift) | `WaitlistForm.astro`, `FinalCTA.astro` |
| Bolder typography — h1 `font-800`, h2 `font-800 tracking-tighter` | `global.css` + all sections |
| iOS number badges on HowItWorks steps (01/02/03) | `HowItWorks.astro` |
| iOS number badges on FeatureSection (04/05) | `FeatureSection.astro` |
| Zigzag layout on FeatureSections (flip prop) | `index.astro` |
| Hero headline → 3-line format (60px) | `Hero.astro` |
| CredibilityBar: animated marquee with Google Favicon logos, larger pills (17px/36px) | `CredibilityBar.astro`, `global.css` |
| Hover states: card lift, phone glow, button 3D lift | `Testimonials.astro`, `PhoneMockup.astro`, `WaitlistForm.astro` |
| Re-triggering scroll animations | `Layout.astro` |

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

## Post-Vercel deployment workflow

- Small tweaks: edit locally → `npm run dev` to verify → `git push origin main` → Vercel auto-deploys (~1 min)
- Larger changes: open a new GSD phase, plan → execute → push
- Rollback: `git revert <commit>` → push → Vercel redeploys previous version
