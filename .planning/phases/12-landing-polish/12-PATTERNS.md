# Phase 12: Visual Polish - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 12 existing component/style files
**Analogs found:** 12 / 12 (all files are existing files being modified — no new files)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `landing/src/styles/global.css` | config/animation | transform-opacity | Self (animation system source) | canonical |
| `landing/src/layouts/Layout.astro` | layout/script | event-driven (IntersectionObserver) | Self (observer source) | canonical |
| `landing/src/components/Nav.astro` | component | event-driven (scroll) | `WaitlistForm.astro` (hover pattern) | role-match |
| `landing/src/components/Hero.astro` | component | request-response | Self (hero-enter pattern) | canonical |
| `landing/src/components/CredibilityBar.astro` | component | transform | `Testimonials.astro` (stagger pattern) | role-match |
| `landing/src/components/HowItWorks.astro` | component | transform | `FeatureSection.astro` (fade-up stagger) | exact |
| `landing/src/components/FeatureSection.astro` | component | transform | Self | canonical |
| `landing/src/components/TrustSection.astro` | component | transform | `FeatureSection.astro` (2-col grid, fade-up) | exact |
| `landing/src/components/VideoSection.astro` | component | transform | `FinalCTA.astro` (centered section) | role-match |
| `landing/src/components/Testimonials.astro` | component | transform | Self | canonical |
| `landing/src/components/CreatorStory.astro` | component | transform | `FinalCTA.astro` (centered, max-w-2xl) | exact |
| `landing/src/components/Pricing.astro` | component | transform | `Testimonials.astro` (card hover candidate) | role-match |

---

## Pattern Assignments

### `landing/src/styles/global.css` (config, animation system)

**Canonical source — do not add new animation types.**

**Current animation parameters** (lines 41-71):
```css
/* Scroll-triggered */
.fade-up {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 0.6s ease, transform 0.6s ease;
}
.fade-up.visible {
  opacity: 1;
  transform: translateY(0);
}
.fade-up.delay-1 { transition-delay: 0.1s; }
.fade-up.delay-2 { transition-delay: 0.2s; }
.fade-up.delay-3 { transition-delay: 0.3s; }
.fade-up.delay-4 { transition-delay: 0.4s; }

/* Hero (load-triggered, no JS dependency) */
.hero-enter {
  opacity: 0;
  animation: heroEnter 0.8s ease forwards;
}
.hero-enter.delay-1 { animation-delay: 0.15s; }
.hero-enter.delay-2 { animation-delay: 0.3s; }
.hero-enter.delay-3 { animation-delay: 0.45s; }
.hero-enter.delay-4 { animation-delay: 0.6s; }

@keyframes heroEnter {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

**Tuning target for sub-plan 12-03** — replace `ease` with custom cubic-bezier:
```css
/* Replace "ease" with this across both fade-up transition and hero-enter */
transition: opacity 0.7s cubic-bezier(0.16, 1, 0.3, 1),
            transform 0.7s cubic-bezier(0.16, 1, 0.3, 1);
```
Source: `design-taste-frontend` SKILL.md Section 6, MOTION_INTENSITY level 4-7 standard.
Rationale: snappier deceleration (spring-like); 0.7s is within D-02 discretion range (0.6-0.8s).

---

### `landing/src/layouts/Layout.astro` (layout, IntersectionObserver)

**Canonical source for the scroll trigger system.**

**Current IntersectionObserver** (lines 46-58):
```javascript
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }
);
document.querySelectorAll('.fade-up').forEach((el) => observer.observe(el));
```

**Threshold tuning** (if sections fail to trigger): Lower to `0.05` or add `rootMargin: "0px 0px -50px 0px"` to fire slightly before the element fully enters. Only change if Playwright audit confirms elements stay invisible.

**Nav scroll listener** (lines 60-69):
```javascript
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
Note: `window.addEventListener('scroll')` is a taste-skill-flagged anti-pattern (continuous reflow risk) per `high-end-visual-design` SKILL.md Section 5. However D-02 bans new libraries and the implementation is lightweight — no action unless scroll jank is observed.

---

### `landing/src/components/Nav.astro` (component, scroll state)

**Analog:** `landing/src/components/WaitlistForm.astro` (hover reference)

**Current nav-scrolled CSS** (lines 4-13):
```css
#main-nav {
  transition: background 0.3s ease, box-shadow 0.3s ease;
}
#main-nav.nav-scrolled {
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 0 1px 0 rgba(0,0,0,0.06);
}
```

**Current CTA button** (lines 31-36):
```astro
class="bg-[var(--color-blue-accent)] hover:bg-[var(--color-blue-dark)] text-white
       text-sm font-heading font-600 px-5 py-2.5 rounded-full
       transition-all duration-200 hover:scale-[1.02] active:scale-[0.98]"
```
Touch target note: `py-2.5` on an `<a>` tag may render below 44px minimum touch target. Add `min-h-[44px] flex items-center` if Playwright audit at 375px confirms the height is below 44px.

**Transition tuning for 12-03**: Replace `duration-200` with `duration-300` and `ease` with `cubic-bezier(0.16, 1, 0.3, 1)` to match the polished animation system.

---

### `landing/src/components/Hero.astro` (component, hero-enter pattern)

**Canonical — uses `.hero-enter` (CSS animation, no JS dependency).**

**Current structure** (lines 6-43):
```astro
<section class="relative pt-32 pb-24 px-6 overflow-hidden bg-white">
  <div class="max-w-6xl mx-auto">
    <div class="grid lg:grid-cols-2 gap-16 items-center">
      <!-- Text side -->
      <div class="flex flex-col gap-6">
        <div class="hero-enter delay-1">...</div>
        <p class="hero-enter delay-2 ...">...</p>
        <div class="hero-enter delay-3 ..."><WaitlistForm /></div>
      </div>
      <!-- Mockup side -->
      <div class="hero-enter delay-4 flex justify-center lg:justify-end pb-10">
        <PhoneMockup />
      </div>
    </div>
  </div>
  <!-- Subtle radial background -->
  <div class="absolute inset-0 -z-10 pointer-events-none"
       style="background: radial-gradient(ellipse 70% 60% at 80% 20%, #E8F4F8 0%, transparent 70%);">
  </div>
</section>
```

**Pattern note:** Hero is the only section using `.hero-enter`. All sections below the hero use `.fade-up`. Do not mix the two systems. The hero is the reference for load-triggered animation; everything else is scroll-triggered.

---

### `landing/src/components/CredibilityBar.astro` (component, nested fade-up — conflict zone)

**Analog:** `landing/src/components/Testimonials.astro` (stagger pattern without nesting conflict)

**Current problematic pattern** (lines 12-25):
```astro
<!-- CONFLICT: outer wrapper has .fade-up AND individual spans have .fade-up -->
<div class="fade-up delay-1 flex flex-wrap ...">
  {sources.map((source, i) => (
    <span class={`text-sm ... fade-up delay-${i + 1}`}>
      {source}
    </span>
  ))}
</div>
```

**Correct pattern to copy from Testimonials.astro** (lines 29-43): Each card gets its own `.fade-up delay-N` directly — no nested fade-up parent wrapping individually-animated children:
```astro
<div class="grid md:grid-cols-3 gap-6">
  {items.map((item, i) => (
    <div class={`fade-up delay-${i + 1} ...`}>...</div>
  ))}
</div>
```

**Fix for CredibilityBar:** Remove `.fade-up delay-1` from the wrapper `<div>`. Keep `.fade-up delay-${i+1}` only on the individual `<span>` elements so each has its own clean observer target.

---

### `landing/src/components/HowItWorks.astro` (component, fade-up stagger)

**Analog:** `landing/src/components/FeatureSection.astro` (exact stagger pattern)

**Current stagger pattern** (lines 44-56):
```astro
<div class="flex flex-col gap-4">
  <span class="fade-up text-5xl font-heading font-800 ...opacity-20...">{step.number}</span>
  <h3 class="fade-up delay-1 text-2xl sm:text-3xl ...">...</h3>
  <p class="fade-up delay-2 text-base ...">...</p>
</div>
<div class="fade-up delay-3 flex justify-center pb-10">
  <PhoneMockup />
</div>
```
This matches `FeatureSection.astro` exactly. Pattern is correct. `pb-10` on the mockup wrapper clears the `-bottom-8` label from `PhoneMockup.astro`.

**PhoneMockup label clearance pattern** (from `PhoneMockup.astro` line 65):
```astro
<!-- Label uses absolute -bottom-8 — parent wrapper MUST have pb-10 minimum -->
<div class="absolute -bottom-8 left-1/2 -translate-x-1/2 text-center whitespace-nowrap">
```

---

### `landing/src/components/FeatureSection.astro` (component, 2-col feature layout)

**Canonical — reference for all 2-col section patterns.**

**Import pattern** (lines 1-26):
```astro
---
import PhoneMockup from './PhoneMockup.astro';

interface Props {
  label: string;
  headline: string;
  description: string;
  screen: string;
  accent?: 'blue' | 'green';
  flip?: boolean;
  bg?: 'white' | 'tint';
}
---
```

**Core 2-col + flip pattern** (lines 28-52):
```astro
<section class={`py-24 px-6 ${bgClass}`}>
  <div class="max-w-6xl mx-auto">
    <div class={`grid lg:grid-cols-2 gap-12 lg:gap-20 items-center
                 ${flip ? 'lg:[&>*:first-child]:order-2' : ''}`}>
      <div class="flex flex-col gap-5">
        <span class={`fade-up text-xs font-heading font-600 uppercase tracking-widest ${labelColor}`}></span>
        <h2 class="fade-up delay-1 text-3xl sm:text-4xl font-heading font-700 ..."></h2>
        <p class="fade-up delay-2 text-base text-[var(--color-body)] leading-relaxed max-w-md"></p>
      </div>
      <div class="fade-up delay-3 flex justify-center pb-10">
        <PhoneMockup />
      </div>
    </div>
  </div>
</section>
```

---

### `landing/src/components/TrustSection.astro` (component, 2-col + emoji fix required)

**Analog:** `landing/src/components/FeatureSection.astro` (2-col grid, fade-up)

**Current emoji pattern** (lines 2-8) — MUST BE REPLACED:
```astro
const credibilitySignals = [
  { icon: '📚', text: '...' },
  { icon: '✅', text: '...' },
  { icon: '🔍', text: '...' },
  { icon: '💊', text: '...' },
  { icon: '🔔', text: '...' },
];
```
Emoji are banned by both `design-taste-frontend` (Section 2, ANTI-EMOJI POLICY) and `redesign-existing-projects` (Iconography section). Replace each with a single-color inline SVG.

**SVG replacement pattern** — copy structure from `CreatorStory.astro` (lines 9-11) which already uses inline SVG:
```astro
<!-- Pattern: single-color SVG at consistent size, color via currentColor -->
<svg class="w-4 h-4 text-[var(--color-blue-accent)] flex-shrink-0 mt-0.5"
     fill="currentColor" viewBox="0 0 24 24">
  <path d="..."/>
</svg>
```

Also: the `🔒` emoji in the privacy card (line 27) must be replaced with the same SVG pattern:
```astro
<!-- Current (line 27) -->
<div class="w-10 h-10 ... text-lg">🔒</div>

<!-- Replace with inline SVG lock icon -->
<div class="w-10 h-10 rounded-xl bg-[var(--color-blue-accent)]/10 flex items-center justify-center flex-shrink-0">
  <svg class="w-5 h-5 text-[var(--color-blue-accent)]" fill="currentColor" viewBox="0 0 24 24">
    <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
  </svg>
</div>
```

---

### `landing/src/components/VideoSection.astro` (component, centered section + mojibake fix)

**Analog:** `landing/src/components/FinalCTA.astro` (centered `max-w-*` section structure)

**Current mojibake** (line 10) — MUST BE FIXED FIRST before any screenshot:
```astro
<!-- Current (broken) -->
<!-- Video container â€" swap src for real embed later -->

<!-- Fix: replace â€" with — -->
<!-- Video container — swap src for real embed later -->
```

**Current play button** (lines 14-18) — hover state missing, add for 12-03:
```astro
<!-- Current -->
<div class="w-16 h-16 rounded-full bg-[var(--color-blue-accent)] flex items-center justify-center shadow-lg">

<!-- Add hover state (12-03) -->
<div class="w-16 h-16 rounded-full bg-[var(--color-blue-accent)] flex items-center justify-center shadow-lg
            transition-transform duration-200 hover:scale-110 cursor-pointer">
```

**Reference pattern from WaitlistForm.astro** (lines 28-30) for consistent transition syntax:
```astro
transition-all duration-200 hover:scale-[1.02] active:scale-[0.98]
```

---

### `landing/src/components/Testimonials.astro` (component, 3-col card grid)

**Canonical — reference stagger pattern for card grids.**

**Current card pattern** (lines 29-43):
```astro
<div class="grid md:grid-cols-3 gap-6">
  {testimonials.map((t, i) => (
    <div class={`fade-up delay-${i + 1} bg-white rounded-2xl p-7 shadow-sm border border-gray-100
                 flex flex-col gap-5`}>
      ...
    </div>
  ))}
</div>
```

**Hover state to add in 12-03** (derived from WaitlistForm pattern + RESEARCH.md line 481):
```astro
<!-- Add to existing card class list -->
transition-all duration-200 hover:shadow-md hover:-translate-y-0.5
```

**Taste observation (flag, do not fix without approval):** `redesign-existing-projects` SKILL.md bans "3 equal card columns as feature row". Testimonials uses exactly this. Flag as a taste observation for the user — do not restructure in Phase 12 unless explicitly approved (per RESEARCH.md line 432-433 interpretation in 12-RESEARCH.md).

---

### `landing/src/components/CreatorStory.astro` (component, centered section + mojibake fix)

**Analog:** `landing/src/components/FinalCTA.astro` (centered `max-w-2xl` pattern)

**Current mojibake** (lines 18-23) — MUST BE FIXED FIRST:
```astro
<!-- Current (broken — lines 18-19) -->
...I had no idea if they were safe to take together â€" or when to take them...

<!-- Current (broken — lines 22-23) -->
Alfonso C. â€" iOS developer

<!-- Fix both: replace â€" with — (em dash, U+2014) -->
...I had no idea if they were safe to take together — or when to take them...
Alfonso C. — iOS developer
```

**Centered section structure** (lines 4-25) — already correct, copy this pattern for any new centered sections:
```astro
<section class="py-24 px-6 bg-white">
  <div class="max-w-2xl mx-auto text-center">
    <div class="fade-up mx-auto mb-8 ..."><!-- visual --></div>
    <h2 class="fade-up delay-1 ...">...</h2>
    <p class="fade-up delay-2 ...">...</p>
    <p class="fade-up delay-3 ...">...</p>
  </div>
</section>
```

---

### `landing/src/components/Pricing.astro` (component, single card + plan tiles)

**Analog:** `landing/src/components/Testimonials.astro` (card hover candidate)

**Current pricing tile pattern** (lines 20-30):
```astro
<!-- Monthly tier (no hover) -->
<div class="flex-1 rounded-2xl border border-gray-100 px-5 py-5 text-center">

<!-- Annual tier (highlighted, no hover) -->
<div class="flex-1 rounded-2xl border-2 border-[var(--color-blue-accent)]/30
            bg-[var(--color-blue-tint)]/50 px-5 py-5 text-center relative">
```

**Hover state to add in 12-03** (from RESEARCH.md line 484):
```astro
<!-- Monthly tier — add hover border highlight -->
transition-all duration-200 hover:border-[var(--color-blue-accent)]/40 hover:shadow-sm

<!-- Annual tier — add hover border intensification -->
transition-all duration-200 hover:border-[var(--color-blue-accent)]/60 hover:shadow-sm
```

---

## Shared Patterns

### Hover State (canonical — copy from WaitlistForm.astro + Nav.astro)

**Source:** `landing/src/components/WaitlistForm.astro` lines 28-30, `landing/src/components/Nav.astro` lines 31-36

**Apply to:** All interactive elements (buttons, plan tiles, cards, video play button)

```astro
<!-- Button hover (blue CTA) — the canonical pattern -->
transition-all duration-200 hover:bg-[var(--color-blue-dark)] hover:scale-[1.02] active:scale-[0.98]

<!-- Card hover lift — derived pattern -->
transition-all duration-200 hover:shadow-md hover:-translate-y-0.5

<!-- Border intensification (pricing tiles) -->
transition-all duration-200 hover:border-[var(--color-blue-accent)]/60
```

For 12-03 animation polish: upgrade `duration-200` to `duration-300` and add `ease-[cubic-bezier(0.16,1,0.3,1)]` on all new hover additions (not on existing already-working hovers, to avoid regression).

---

### Tailwind v4 Token Usage

**Source:** `landing/src/styles/global.css` lines 4-17, all component files

**Apply to:** All new classes added in Phase 12 — never use generated utilities

```astro
<!-- CORRECT: arbitrary var() reference -->
text-[var(--color-blue-accent)]
bg-[var(--color-blue-dark)]
border-[var(--color-blue-accent)]/30

<!-- WRONG in this project: generated utility -->
text-blue-accent
```

Token reference:
```css
--color-blue-tint: #E8F4F8
--color-blue-accent: #2B9EB3
--color-blue-dark: #1E7A8C
--color-green-tint: #E8F0EC
--color-green-accent: #6B9E7F
--color-off-white: #F8FAFB
--color-heading: #1A1A2E
--color-body: #4A4A60
--color-muted: #8888A0
```

---

### Fade-Up Stagger Sequence

**Source:** `landing/src/components/FeatureSection.astro` (canonical usage)

**Apply to:** Any new content elements added to existing sections

```astro
<!-- Standard 4-element stagger -->
<span class="fade-up ...">Label (no delay)</span>
<h2  class="fade-up delay-1 ...">Headline</h2>
<p   class="fade-up delay-2 ...">Body copy</p>
<div class="fade-up delay-3 ...">Visual / mockup wrapper (pb-10 if contains PhoneMockup)</div>
```

Rule: never nest `.fade-up` inside another `.fade-up` parent — this causes the CredibilityBar conflict. Each `.fade-up` element must be a direct child of a non-animated parent.

---

### PhoneMockup Clearance

**Source:** `landing/src/components/PhoneMockup.astro` line 65, `FeatureSection.astro` line 46

**Apply to:** Any div containing `<PhoneMockup>`

```astro
<!-- Label sits at absolute -bottom-8 — always add pb-10 to the containing div -->
<div class="fade-up delay-3 flex justify-center pb-10">
  <PhoneMockup screenLabel="..." accent="blue" />
</div>
```

---

### Inline SVG Pattern (replaces emojis)

**Source:** `landing/src/components/CreatorStory.astro` lines 9-11, `landing/src/components/VideoSection.astro` lines 15-17

**Apply to:** `TrustSection.astro` (all 5 list icons + 1 privacy card icon)

```astro
<!-- Single-color, fill="currentColor", sized with Tailwind w-* h-* -->
<svg class="w-4 h-4 text-[var(--color-blue-accent)] flex-shrink-0 mt-0.5"
     fill="currentColor" viewBox="0 0 24 24">
  <path d="..."/>
</svg>
```

Rule: no color on the SVG element itself — only `text-[var(--color-*)]` via `currentColor`. This ensures the icon inherits the design system color correctly.

---

### Section Structure Archetypes

Two archetypes used throughout the page — always use one of these, never invent a third:

**Archetype A — 2-col grid** (use `FeatureSection.astro` as template):
```astro
<section class="py-24 px-6 bg-[var(--color-...)]">
  <div class="max-w-6xl mx-auto">
    <div class="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
      <!-- text side + mockup side -->
    </div>
  </div>
</section>
```

**Archetype B — centered narrow** (use `CreatorStory.astro` / `FinalCTA.astro` as template):
```astro
<section class="py-24 px-6 bg-[var(--color-...)]">
  <div class="max-w-2xl mx-auto text-center">
    <!-- stacked content -->
  </div>
</section>
```

---

## Pre-Fix Priority List (from RESEARCH.md + taste skills)

These must be resolved before or during sub-plan 12-01 screenshot review. They are bugs, not polish:

| # | File | Issue | Fix Pattern |
|---|------|-------|-------------|
| 1 | `CreatorStory.astro` lines 18, 22 | Mojibake `â€"` | Replace with `—` (em dash) |
| 2 | `VideoSection.astro` line 10 | Mojibake `â€"` in comment | Replace with `—` |
| 3 | `TrustSection.astro` lines 3-8, 27 | 6 emojis | Replace with inline SVGs (see Shared Patterns above) |
| 4 | `CredibilityBar.astro` lines 16-23 | Nested `.fade-up` conflict | Remove outer `.fade-up delay-1` from wrapper div |

---

## No Analog Found

All files in Phase 12 are existing files being modified. No new files are being created. No "no analog" entries.

---

## Metadata

**Analog search scope:** `landing/src/components/`, `landing/src/layouts/`, `landing/src/styles/`, `landing/.agents/skills/`
**Files read:** 14 source files + 3 skill files
**Pattern extraction date:** 2026-05-19
