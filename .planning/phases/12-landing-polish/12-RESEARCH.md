# Phase 12: Visual Polish — Research

**Researched:** 2026-05-19
**Domain:** Astro + Tailwind v4 landing page visual audit, CSS animation, responsive layout
**Confidence:** HIGH

---

## Summary

Phase 12 is a pure audit-and-fix phase on an already-scaffolded Astro landing page. No new
libraries are being introduced — the entire animation system (`fade-up`, `hero-enter`,
Intersection Observer), design tokens (CSS custom properties in `global.css`), and component
structure (standalone `.astro` files) are locked from Phase 10/11. The work is: look at what
the browser actually renders, identify what is visually wrong, fix it in place.

The 1440px screenshot from Phase 11.5 confirms the current state: the hero renders correctly
(split layout, headline, waitlist form, phone mockup), but every section below the hero is
effectively invisible — the sections are present in HTML but appear as nearly-empty color
bands. The phone mockups are not rendering visible content below the fold. This is the primary
audit finding before any task even runs.

The mobile (375px) screenshot shows the same pattern: hero works, everything below is empty
bands. The stacked single-column layout appears to be working structurally, but visual density
is near-zero below the fold.

**Primary recommendation:** The sub-plan execution order (desktop audit first, then mobile,
then animation polish) is correct. Each sub-plan must start with a fresh Playwright screenshot
before touching code — the screenshots from Phase 11.5 are the pre-audit baseline.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Screenshot-first. Each sub-plan starts with Playwright screenshots at the relevant
  breakpoint(s), visual review determines what needs fixing, then targeted code changes are
  made. Audit is driven from what the browser actually renders.

- **D-02:** Tune + add hover states. Phase 12-03 scope: fix broken scroll triggers, tune
  timing/easing/delay on existing `.fade-up` animations, and add meaningful hover states on
  buttons, cards, and nav links. No new animation types beyond what the existing CSS +
  Intersection Observer system supports. No GSAP or other libraries.

- **D-03:** Proactive. Activate `design-taste-frontend` or `high-end-visual-design` at the
  start of each sub-plan. Claude applies taste judgments and surfaces quality suggestions,
  not just obvious bugs. The goal is a high-quality visual result, not a minimum-fix pass.

- **D-04:** Fix as you go. Each sub-plan runs as an audit+fix loop: screenshot → identify
  issue → fix → verify with screenshot. Fixes happen immediately, one section at a time.
  No separate batch-fix pass.

### Claude's Discretion

- Which specific Taste skill variant to activate per task (`design-taste-frontend` vs
  `high-end-visual-design` vs `redesign-existing-projects`) — choose based on the nature of
  the task at hand.
- Specific easing values, transition durations, and hover lift amounts — pick what looks right
  based on the existing design system.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Desktop layout audit | Browser / Client | — | Visual output is what matters; Playwright renders actual browser |
| Mobile responsive audit | Browser / Client | — | Same — browser at viewport width |
| Scroll animation triggers | Browser / Client | — | IntersectionObserver runs in-browser; all state is DOM class toggling |
| Nav scroll transition | Browser / Client | — | `nav-scrolled` class toggled by scroll listener in Layout.astro script |
| Hover states | Browser / Client | — | Pure CSS pseudo-classes; no server involvement |
| CSS token application | Frontend Server (SSR) | — | Astro compiles `.astro` files; tokens in `global.css` via `@theme` |

All capabilities in this phase are browser-side concerns. Astro's build step is only relevant
for `npm run build` verification — execution is pure client-side CSS/JS.

---

## Standard Stack

### Core (already installed — verified against package.json)

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| astro | ^6.3.4 | Static site framework | Installed [VERIFIED: package.json] |
| tailwindcss | ^4.3.0 | Utility CSS | Installed [VERIFIED: package.json] |
| @tailwindcss/vite | ^4.3.0 | Vite integration for Tailwind v4 | Installed [VERIFIED: package.json] |

**No new packages are required for Phase 12.** The entire phase operates on the existing stack.

### Animation System (built-in — no library)

| Asset | Location | What It Does |
|-------|----------|--------------|
| `.fade-up` + `.visible` | `global.css` | Scroll-triggered fade + Y-axis slide |
| `.delay-1` through `.delay-4` | `global.css` | Stagger delays (0.1s–0.4s) |
| `.hero-enter` + `.delay-1`–`.delay-4` | `global.css` | Load-triggered hero entrance |
| IntersectionObserver | `Layout.astro` `<script>` | Adds `.visible` class at 15% threshold |
| Nav scroll listener | `Layout.astro` `<script>` | Toggles `nav-scrolled` after 20px scroll |

### Tailwind v4 Notes (critical for implementation)

Tailwind v4 uses `@theme` blocks in CSS instead of `tailwind.config.js`. Design tokens are
defined as CSS custom properties. [VERIFIED: global.css, package.json]

- Token syntax: `--color-blue-accent: #2B9EB3` inside `@theme {}`
- Consumed in templates as: `text-[var(--color-blue-accent)]` or via generated utilities
- Do NOT use `tailwind.config.js` — it does not exist in this project
- Do NOT use `postcss.config.js` with `tailwindcss` plugin — v4 uses `@tailwindcss/vite`

---

## Architecture Patterns

### Section Order (locked — from index.astro)

```
Nav (fixed overlay)
Hero
CredibilityBar
HowItWorks (3 steps, alternating flip)
FeatureSection × 3 (Interaction Analysis / Schedule / Reminders)
TrustSection (Privacy + Data Integrity, 2-col)
VideoSection (placeholder)
Testimonials (3-col grid)
CreatorStory (centered, photo placeholder)
Pricing (single centered card)
FinalCTA (centered, waitlist form)
Footer
```

### Per-Section Code Patterns

**FeatureSection:** Accepts `label`, `headline`, `description`, `screen`, `accent`, `flip`,
`bg` props. Uses `lg:grid-cols-2` with optional `[&>*:first-child]:order-2` for flip.
Text side has three `.fade-up` elements staggered at delay-1, delay-2. Mockup at delay-3.

**PhoneMockup:** Has a subtle 3D perspective transform baked in as an inline style
(`perspective(1200px) rotateY(-4deg) rotateX(2deg)`). Has `hover:scale-[1.02]` on the
frame. The label sits 8px below the frame with `absolute -bottom-8`. This means sections
containing PhoneMockup need `pb-10` on the mockup wrapper to clear the label.

**HowItWorks:** Three steps in a `flex flex-col gap-24`. Each step is a 2-col grid alternating
flip (odd index flips). Step numbers use `opacity-20` on the accent color for a ghost effect.

**Testimonials:** Three-column grid `md:grid-cols-3`. Cards use `shadow-sm border border-gray-100`.
Each card staggered with `.fade-up delay-1` through `.delay-3`. The quote SVG uses `opacity-30`.

**CredibilityBar:** Each source is BOTH inside a `.fade-up delay-1` wrapper AND individually
given a `.fade-up delay-${i+1}`. This means source items are nested inside an already-animating
parent — a potential conflict where the outer fires before all children have their observer
attached. [VERIFIED: CredibilityBar.astro]

**CreatorStory:** Contains mojibake in the rendered text — the em-dash character (`—`) and
the author line (`Alfonso C.`) appear to have encoding artifacts (`â€"`) in the raw source.
[VERIFIED: CreatorStory.astro lines 18-23] This must be fixed.

**VideoSection:** Also contains a mojibake character in the video placeholder comment
(`â€"` instead of `—`). [VERIFIED: VideoSection.astro line 11] Minor but should be fixed.

**TrustSection:** Uses emoji icons (📚 ✅ 🔍 💊 🔔) in the credibility signals list.
The `design-taste-frontend` and `minimalist-ui` skills both prohibit emojis — they must be
replaced with SVG primitives or inline SVGs. [VERIFIED: TrustSection.astro]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scroll animation library | Custom scroll event listeners | Existing IntersectionObserver in Layout.astro | Already implemented; `window.addEventListener('scroll')` causes continuous reflows |
| New animation library | GSAP, Framer Motion | Existing `.fade-up` CSS system | D-02 explicitly bans new libraries |
| CSS preprocessor | SASS/LESS mixins | Tailwind v4 `@theme` custom properties | Already the project standard |
| New icon library | Lucide, Feather import | Inline SVG primitives | No icon library in package.json; Tailwind v4 project has no `shadcn` or similar |
| Custom easing functions via JS | requestAnimationFrame loops | CSS `transition-timing-function` with cubic-bezier | GPU-accelerated, consistent with existing system |

---

## Common Pitfalls

### Pitfall 1: Fade-Up Elements Not Triggering Below the Fold

**What goes wrong:** Sections with multiple `.fade-up` elements remain invisible because the
IntersectionObserver threshold is `0.15` — meaning 15% of the element must be visible to
trigger. On long sections (like HowItWorks with 3 steps at `gap-24`), the 3rd step's elements
may be far enough down that they never trigger if the user doesn't scroll far enough, OR they
fail to trigger if the element is already past the viewport when the observer is attached.

**Why it happens:** `document.querySelectorAll('.fade-up').forEach(el => observer.observe(el))`
runs on DOMContentLoaded. If the page is very long and the browser renders slowly, some elements
may already be in the viewport but the observer fires after the scroll position has moved past
them.

**How to avoid:** Verify each section fires correctly by scrolling through the full page in
Playwright after the screenshot. If elements stay invisible, reduce threshold or add a
`rootMargin` to trigger earlier.

**Warning signs:** Empty-looking sections in screenshots that have content in the HTML.

### Pitfall 2: CredibilityBar Nested Fade-Up Conflict

**What goes wrong:** The `.fade-up delay-1` wrapper fires, making the container visible, but
individual source `<span>` elements also have `.fade-up delay-${i+1}`. The individual spans
may never get `.visible` added if their IntersectionObserver callback fires while they're
already inside an invisible parent (opacity: 0).

**Why it happens:** IntersectionObserver measures DOM visibility, which can be affected by
parent opacity. If the parent fades in during the same frame the observer checks the children,
the children may already be marked as observed-and-intersecting before they become visually
visible.

**How to avoid:** Either remove the `.fade-up` classes from individual source spans (let the
parent handle the animation), or ensure the spans don't inherit the parent's animation class
in a conflicting way.

### Pitfall 3: PhoneMockup Label Clipping

**What goes wrong:** The label below PhoneMockup uses `absolute -bottom-8` positioning
relative to the mockup wrapper. If the parent section doesn't have enough bottom padding,
the label clips into the next section's top area.

**Why it happens:** All FeatureSection and HowItWorks wrappers use `pb-10` on the mockup
wrapper div, which provides 40px clearance. If any new wrapper is added without this padding,
the label overlaps content below.

**How to avoid:** Always use `pb-10` (or `pb-12` for extra safety) on the div containing
`<PhoneMockup>`.

### Pitfall 4: Tailwind v4 Utility Generation

**What goes wrong:** Custom token values set in `@theme {}` generate Tailwind utilities
automatically, but arbitrary values referencing CSS custom properties (e.g.,
`text-[var(--color-blue-accent)]`) bypass the utility system entirely and are always valid.
However, if a token is renamed in `@theme`, the arbitrary references still work but generated
utilities (e.g., `text-blue-accent`) would break.

**How to avoid:** The project consistently uses `[var(--color-*)]` arbitrary syntax throughout
all components. Do not introduce new utility class references to tokens — use the same
`[var(--color-name)]` pattern.

### Pitfall 5: Astro Static Rendering and JS Animations

**What goes wrong:** Astro renders components at build time. The `<script>` tag in
`Layout.astro` runs client-side after hydration. If a `.fade-up` element has already scrolled
past the viewport before the script loads (e.g., in a very short page or when navigating with
`#anchor`), the IntersectionObserver never fires for it.

**Why it happens:** `observer.unobserve(entry.target)` means once-and-done observation. If
the element enters the viewport before the script runs, the callback fires on attach with
`isIntersecting: true` — this should be fine. But if the element is above the initial fold
and has already been scrolled past before the script loads, it won't fire at all.

**How to avoid:** For elements that should always be visible (like the hero), use `.hero-enter`
(CSS animation, no JS dependency) instead of `.fade-up`. The current code already does this
correctly for the hero section.

### Pitfall 6: Emoji in TrustSection (Taste Skill Violation)

**What goes wrong:** TrustSection uses emoji icons (📚 ✅ 🔍 💊 🔔) in a `<ul>` list. Both
`design-taste-frontend` and `minimalist-ui` skills explicitly ban emojis. They will be flagged
immediately during taste-skill-activated audit.

**How to avoid:** Replace each emoji with a simple inline SVG or a styled Unicode character
that carries no color. A single-color filled circle or check-mark SVG is sufficient.

### Pitfall 7: Character Encoding Artifacts in Content

**What goes wrong:** `CreatorStory.astro` and `VideoSection.astro` contain mojibake — the
em-dash `—` appears as `â€"` in the raw source. This renders as garbage characters in the
browser.

**Why it happens:** The `.astro` files were likely saved with incorrect encoding or pasted
from a context that introduced encoding issues.

**How to avoid:** Fix the raw string in both files before screenshot review. The affected
lines are:
- `CreatorStory.astro` line 18: body copy ending in `â€"`
- `CreatorStory.astro` line 22: author line `Alfonso C. â€" iOS developer`
- `VideoSection.astro` line 11: comment `â€"` in placeholder text

---

## Code Examples

### Correct Tailwind v4 Token Usage Pattern
```astro
<!-- CORRECT — arbitrary var() reference -->
<p class="text-[var(--color-body)] leading-relaxed">...</p>

<!-- CORRECT — inline style for complex gradients -->
<div style="background: radial-gradient(ellipse 70% 60% at 80% 20%, #E8F4F8 0%, transparent 70%);">

<!-- WRONG in this project — generated utility (only works if token generates it) -->
<p class="text-body">...</p>
```
[VERIFIED: inspecting global.css and all component files]

### Correct Hover State Pattern (from WaitlistForm.astro — reference implementation)
```astro
<!-- Button hover pattern used in Nav and WaitlistForm -->
class="bg-[var(--color-blue-accent)] hover:bg-[var(--color-blue-dark)] text-white
       transition-all duration-200 hover:scale-[1.02] active:scale-[0.98]"
```
[VERIFIED: WaitlistForm.astro line 28-30, Nav.astro line 32-34]

### Correct Card Hover Extension Pattern
```astro
<!-- Extend existing card with hover lift — consistent with WaitlistForm pattern -->
class="bg-white rounded-2xl p-7 shadow-sm border border-gray-100
       transition-all duration-200 hover:shadow-md hover:-translate-y-0.5"
```
[ASSUMED — pattern derived from existing hover conventions; specific values are Claude's discretion per D-02]

### Correct Fade-Up Usage (stagger delay pattern)
```astro
<!-- First element — no delay -->
<span class="fade-up text-xs ...">Label</span>

<!-- Subsequent elements — stagger by 0.1s increments -->
<h2 class="fade-up delay-1 text-3xl ...">Headline</h2>
<p class="fade-up delay-2 text-base ...">Description</p>
<div class="fade-up delay-3 ...">Visual</div>
```
[VERIFIED: FeatureSection.astro, HowItWorks.astro, Testimonials.astro]

### IntersectionObserver Threshold (current — do not change without reason)
```javascript
// Source: Layout.astro <script> block
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }  // 15% of element must be visible
);
```
[VERIFIED: Layout.astro lines 46-58]

### Nav Scroll State Pattern
```javascript
// Source: Layout.astro <script> block
const nav = document.getElementById('main-nav');
if (nav) {
  window.addEventListener('scroll', () => {
    if (window.scrollY > 20) {
      nav.classList.add('nav-scrolled');
    } else {
      nav.classList.remove('nav-scrolled');
    }
  });
}
```
[VERIFIED: Layout.astro lines 60-69]
Note: This uses `window.addEventListener('scroll')` — the taste skills flag this as a
performance anti-pattern. However, D-02 prohibits introducing new animation libraries and
this is the existing implementation. The nav scroll listener fires infrequently and is
lightweight — no action needed unless scroll jank is observed.

---

## Current State Inventory (from Phase 11.5 screenshots)

### What the 1440px Screenshot Reveals
[VERIFIED: playwright-verify-1440.png]

- **Hero:** Renders correctly. Split layout (text left, phone right). Headline visible.
  Form visible. Phone mockup visible. Nav visible with CTA button.
- **CredibilityBar:** Renders as a very thin blue band — sources not clearly visible in
  the screenshot (may be too small at full-page scale, or animation not triggered).
- **All sections below CredibilityBar:** Appear as near-empty alternating color bands.
  No text or phone mockup content is visible at the full-page screenshot scale. This is
  likely a combination of: (a) the fade-up elements are at opacity:0 waiting for scroll
  trigger, and (b) sections are very tall with sparse content at 1440px viewport.
- **Footer:** Visible as a dark band at the bottom.

### What the 375px Screenshot Reveals
[VERIFIED: playwright-verify-375.png]

- **Hero:** Renders as a stacked single-column layout. Headline wraps to 3 lines.
  Phone mockup appears below the text. This is correct mobile behavior.
- **Everything below:** Same as desktop — alternating color bands with no visible content.
  All content is in the HTML but opacity:0 (awaiting scroll trigger from Playwright navigation).
- **Footer:** Visible as a dark band at the very bottom.

### Key Insight for Planning
The full-page screenshot captures the page before any user scrolling occurs. The `fade-up`
elements are correctly opacity:0 on initial load — they're waiting for the IntersectionObserver
to fire as the user scrolls. This means **the screenshots in Phase 12 sub-plans should be
taken after simulating scroll**, not just after navigation. The audit methodology must account
for this:

```
# Phase 12 screenshot workflow (per section):
1. Navigate to page
2. Use Playwright scroll to bring section into view
3. Screenshot the section
4. Review → fix → re-scroll → re-screenshot
```

Alternatively: take a screenshot with `fullPage: true` and review the rendered HTML source
to identify issues, then manually trigger `.visible` classes via Playwright `evaluate()` to
check layout with visible content.

---

## Taste Skill Application Guide

### Per Sub-Plan Skill Recommendation

| Sub-Plan | Primary Skill | Rationale |
|----------|--------------|-----------|
| 12-01 Desktop audit | `redesign-existing-projects` | Provides the structured audit checklist (typography, color, layout, spacing) — exactly what desktop audit needs |
| 12-02 Mobile/responsive | `design-taste-frontend` | MOBILE_OVERRIDE rules and responsive breakpoint conventions are its strength |
| 12-03 Animation polish | `high-end-visual-design` | Motion choreography section (Section 5) defines cubic-bezier standards and scroll entry patterns |

### Key Rules from Taste Skills Applicable to This Phase

**From `design-taste-frontend`:**
- `MOTION_INTENSITY: 6` = "Fluid CSS" level: `transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1)`. Focus on `transform` and `opacity` only.
- Hero sections must use `min-h-[100dvh]` not `h-screen`. Current Hero uses `pt-32 pb-24` — not a full-viewport hero, so this rule doesn't apply.
- Anti-pattern: 3-column card layouts (equal width). Testimonials section uses exactly this pattern. Taste skill recommends replacing with zig-zag, horizontal scroll, or masonry. **However** — changing layout is a structural change, not a polish fix. Flag as a taste observation; don't restructure unless user approves.
- Anti-emoji policy: TrustSection uses emojis. Replace with SVGs.

**From `high-end-visual-design`:**
- Custom cubic-bezier for all transitions: `cubic-bezier(0.32, 0.72, 0, 1)` (Apple-tier easing)
- `py-24` to `py-40` section padding. Current sections use `py-24` — already at the minimum.
- Scroll entry: `translate-y-16 blur-md opacity-0` resolving over 800ms. Current system uses `translateY(24px)` over `0.6s` — tuning duration from 600ms to 700-800ms is within Claude's discretion (D-02).
- Double-bezel architecture for cards — adds a subtle outer shell. The Pricing card and Testimonial cards are candidates.

**From `redesign-existing-projects` — high-priority items for this page:**
- Random dark sections in an otherwise light page: the CredibilityBar uses `bg-[var(--color-blue-tint)]` and TrustSection uses the same. These tint bands provide rhythm; they're intentional, not accidents.
- Empty flat sections with no visual depth: VideoSection has a placeholder div — it should feel like a composed empty state, not just a colored box.
- Orphaned words: check headlines with `text-wrap: balance`.
- Buttons not bottom-aligned in card groups: Testimonial cards have no button, so not applicable.

---

## Animation Polish Reference

### Current Animation Parameters (verified)
```css
.fade-up {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 0.6s ease, transform 0.6s ease;
}
/* delays: .delay-1 = 0.1s, .delay-2 = 0.2s, .delay-3 = 0.3s, .delay-4 = 0.4s */

.hero-enter {
  animation: heroEnter 0.8s ease forwards;
}
/* delays: .delay-1 = 0.15s, .delay-2 = 0.3s, .delay-3 = 0.45s, .delay-4 = 0.6s */
```

### Tuning Candidates (Claude's discretion per D-02)
| Parameter | Current | Suggested Range | Rationale |
|-----------|---------|----------------|-----------|
| `fade-up` duration | 0.6s | 0.6s–0.8s | Slightly longer feels weightier |
| `fade-up` easing | `ease` | `cubic-bezier(0.16, 1, 0.3, 1)` | Snappier deceleration — high-end standard |
| `translateY` distance | 24px | 16px–28px | 24px is within good range |
| `hero-enter` duration | 0.8s | 0.8s–1.0s | Hero entrance can be slightly cinematic |
| `delay-4` max stagger | 0.4s | 0.4s–0.5s | Fine as-is |

### Hover State Targets (to be added in 12-03)
| Element | Recommended Hover | Pattern Source |
|---------|------------------|---------------|
| Nav CTA button | Already has `hover:bg-[var(--color-blue-dark)] hover:scale-[1.02]` | Nav.astro — no change needed |
| Waitlist submit button | Already has `hover:bg-[var(--color-blue-dark)] hover:scale-[1.02]` | WaitlistForm.astro — no change needed |
| Testimonial cards | Add `hover:shadow-md hover:-translate-y-0.5` | Derived from existing patterns |
| PhoneMockup frame | Already has `hover:scale-[1.02]` | PhoneMockup.astro — no change needed |
| Footer nav links | Already has `hover:text-white transition-colors` | Footer.astro — fine |
| Pricing plan tiles | Add `hover:border-[var(--color-blue-accent)]/60` | Makes tiers feel interactive |
| Video play button | Add `hover:scale-110 transition-transform` | Standard play button convention |

---

## Responsive Audit Reference

### Breakpoints in Use (Tailwind defaults)
| Prefix | Width | Use |
|--------|-------|-----|
| `sm:` | 640px | Typography size steps, flex-row for form |
| `md:` | 768px | Grid columns (testimonials 3-col, footer 2-col) |
| `lg:` | 1024px | Primary 2-col grids (hero, features, HowItWorks, trust) |

### Mobile-Specific Issues to Audit at 375px
- Hero phone mockup appears below text on mobile — verify it has enough top clearance
- CredibilityBar source names wrap at mobile — check `gap-x-8 gap-y-3` is comfortable
- HowItWorks steps: on mobile, the step number `text-5xl` may dominate too much; verify
- FeatureSection flip: `lg:[&>*:first-child]:order-2` only applies at `lg:`. On mobile,
  all feature sections stack in the same order (text first, mockup second) — this is correct
- WaitlistForm: `flex flex-col sm:flex-row` — on 375px it's vertical, which is correct
- Touch targets: nav CTA is `h-8` (px-5 py-2.5 on an `<a>` tag) — approximately 40px tall.
  Minimum recommended is 44px. May need `min-h-[44px]` addition.
- Footer: `sm:flex-row` means on mobile (375px) it stacks vertically — verify text sizes
  are legible at xs

### Tablet (768px) — Quick Check Points
- At 768px, testimonials switch to `md:grid-cols-3` — verify cards don't clip content
- Footer at 768px: `sm:flex-row justify-between` — verify no overflow
- HowItWorks at 768px is still single-column (needs `lg:` for 2-col) — verify step layout looks intentional

---

## Security Domain

No security-relevant changes in this phase. Phase 12 is CSS/HTML/JS polish only. No data
flows, no authentication, no external API changes. The existing ConvertKit form submission
in `WaitlistForm.astro` is untouched.

ASVS assessment: not applicable to visual polish work. `security_enforcement: true` in config
does not add any requirements for this phase beyond the existing implementation.

---

## Validation Architecture

`nyquist_validation: true` in config, but this phase has no automated test suite equivalent.
Visual quality cannot be tested with unit tests. The verification mechanism is:

| Check | Method | When |
|-------|--------|------|
| Playwright screenshot review | Manual visual review after each fix | Per section, per sub-plan |
| Build passes | `cd landing && npm run build` | After each sub-plan completes |
| No runtime errors | Check browser console via Playwright | After each sub-plan |

**Wave 0 gaps:** No test files needed. Visual audit is inherently manual.

**Per-task commit command:** `npm run build` from `landing/` directory.
**Per-wave gate:** Build green + visual screenshot confirms fix.

---

## Environment Availability

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Node.js | Astro dev server | Required | Project has `"node": ">=22.12.0"` engine constraint |
| Astro dev server | All screenshot work | Must be running | `cd landing && npm run dev -- --port 4321` |
| Playwright MCP | Screenshot audit | Verified (Phase 11.5) | `mcp__playwright__browser_*` tools available |
| `localhost:4321` / `4322` | Playwright navigate | Requires dev server running | Falls back to 4322 if 4321 taken |

**No missing dependencies.** All tools verified in Phase 11.5.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Fade-up elements are invisible in screenshots because of opacity:0 waiting for scroll, not a broken animation system | Current State Inventory | Low — if animation system is broken, sub-plan 12-01 screenshot will reveal it immediately |
| A2 | Testimonials 3-col layout is intentional and should not be restructured in Phase 12 | Taste Skill Application | Low — flagged as observation, not a planned fix |
| A3 | Nav CTA `py-2.5` gives approximately 40px height (may be below 44px touch target minimum) | Responsive Audit Reference | Low — exact pixel height depends on font rendering; Playwright can verify |
| A4 | Character encoding issues in CreatorStory/VideoSection render as visible garbage in the browser | Common Pitfalls | Low — Playwright screenshot will confirm immediately |

---

## Open Questions

1. **Should sub-plans 12-02 and 12-03 be written before 12-01 starts, or after?**
   - What we know: Plan 12-01 already exists. Plans 12-02 and 12-03 do not yet exist.
   - What's unclear: Whether the planner should pre-generate all three plans or generate them sequentially after each sub-plan's audit findings.
   - Recommendation: Generate all three plan files upfront with current knowledge, since the structure of each sub-plan is already clear from the CONTEXT.md. The screenshot-driven audit loop is the execution methodology; the plan skeleton can exist before the first screenshot.

2. **Should the emoji replacement in TrustSection happen in 12-01 (desktop audit) or 12-03 (polish)?**
   - What we know: Emojis are flagged by taste skills; they affect visual quality at all breakpoints.
   - Recommendation: Fix in 12-01 (desktop audit) since it's a content/rendering issue that affects visual review immediately. No reason to defer.

---

## Sources

### Primary (HIGH confidence)
- `landing/src/styles/global.css` — All animation parameters, token values verified
- `landing/src/layouts/Layout.astro` — IntersectionObserver logic, nav scroll logic verified
- `landing/src/components/*.astro` — All component markup verified by direct read
- `landing/package.json` — All installed package versions verified
- `.planning/phases/10-landing-page/CONTEXT.md` — Color tokens, font choices, animation system
- `.planning/phases/12-landing-polish/12-CONTEXT.md` — All locked decisions
- `.planning/phases/12-landing-polish/TOOLS.md` — Playwright MCP invocation verified
- `playwright-verify-1440.png` — Current 1440px page state (Phase 11.5 baseline)
- `playwright-verify-375.png` — Current 375px page state (Phase 11.5 baseline)

### Secondary (MEDIUM confidence)
- `landing/.agents/skills/design-taste-frontend/SKILL.md` — Taste rules for audit
- `landing/.agents/skills/high-end-visual-design/SKILL.md` — Motion choreography reference
- `landing/.agents/skills/redesign-existing-projects/SKILL.md` — Audit checklist
- `landing/.agents/skills/minimalist-ui/SKILL.md` — Emoji/typography constraints

### Tertiary (LOW confidence — training knowledge)
- Tailwind v4 `@theme` token behavior described from training knowledge; verified consistent with what's in global.css [ASSUMED behavior matches docs]

---

## Metadata

**Confidence breakdown:**
- Current code state: HIGH — all files read directly
- Animation system behavior: HIGH — logic is simple and readable in Layout.astro
- Screenshot interpretation: MEDIUM — full-page screenshots compress detail; sub-plan screenshots will be definitive
- Taste skill application: HIGH — SKILL.md files read directly

**Research date:** 2026-05-19
**Valid until:** This phase's code state is static until Phase 12 execution begins. Research is valid for the duration of Phase 12.
