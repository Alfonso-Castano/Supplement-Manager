# Frontend Reference Skills (SkillUI extractions)

These are live design system references reverse-engineered from real websites using SkillUI.
Activate when the user asks to take inspiration from a reference site, or when making visual
decisions that should match the feel of a competitor or aspirational site.

## How to use

1. Identify the relevant reference below
2. Read its `SKILL.md` for the full design system (colors, motion, shadows, components)
3. Read `references/DESIGN.md` for extended tokens
4. Apply patterns directly — don't approximate, use the actual extracted values

## Available references

### SuppCo (`suppco`) — https://supp.co/
**Path:** `landing/.agents/skills/frontend-references/suppco/suppco-design/`
**Character:** Dark-themed product landing. Near-black bg `#09090b`, warm cream text `#f9f9f5`.
**Key signals to borrow:**
- Easing: `cubic-bezier(.19,1,.22,1)` — snappy spring curve
- Overlay shadow: `0 0 40px #9993, 0 0 20px #66666640, 0 0 60px #6666661a` — cinematic ambient glow
- Animations: `reveal-in` (scale+translate entrance), `rotate-wobble`, `pulse`, `fade-up`
- Card: `background: #fff3e8; border-radius: 20px; box-shadow: 0 0 8px #00000038`
- Border radius scale up to 60px, 100%

### Duolingo (`duolingo`) — https://www.duolingo.com/
**Path:** `landing/.agents/skills/frontend-references/duolingo/duolingo-design/`
**Character:** Light-themed, expressive motion as core personality. 70 CSS animations detected.
**Key signals to borrow:**
- Bold section contrast: dark navy `#000437` / `#042c60` against white
- Surface color: `#ddf4ff` (light blue) for card/panel backgrounds
- Motion principle: animations ARE the personality — use them liberally
- Button radius: 16px consistent
- Brand color: `#58cc02` (green), `#1cb0f6` (blue)

## Adding a new reference

```bash
cd landing
npx skillui --url https://example.com/ --name site-name --out ".agents/skills/frontend-references/site-name/site-name-design"
```

Then add a summary entry to this file.

**Requires:** `npm install -g playwright && npx playwright install chromium` for computed-style extraction.
Without Playwright, SPAs (React/Next.js sites) yield very few colors — always install first.
