---
phase: "12"
plan: "01"
subsystem: "landing-page"
tags: [visual-polish, desktop, audit, tailwind, typography, svg, bugfix]
requires:
  - "Phase 11 all section components"
  - "Phase 11.5 tools: Playwright MCP, redesign-existing-projects skill, SuppCo + Duolingo references"
provides:
  - "Zero rendering bugs (mojibake, emojis, nested animation conflict all eliminated)"
  - "Consistent desktop layout at 1440px: section rhythm, typography hierarchy, spacing"
  - "SVG icons replacing all emoji in TrustSection"
  - "SuppCo + Duolingo visual patterns applied: 3-line hero, real logos, section rhythm improvements"
affects:
  - "landing/src/components/CreatorStory.astro (mojibake fix)"
  - "landing/src/components/VideoSection.astro (mojibake fix)"
  - "landing/src/components/TrustSection.astro (6 emoji → SVG icons + lock icon)"
  - "landing/src/components/CredibilityBar.astro (nested fade-up fix, real logos, marquee)"
  - "landing/src/components/Hero.astro (3-line headline format, iOS badges)"
  - "landing/src/components/HowItWorks.astro (spacing, typography)"
  - "landing/src/components/FeatureSection.astro (section rhythm, body text width)"
  - "landing/src/components/Testimonials.astro (card spacing)"
  - "landing/src/components/Pricing.astro (spacing)"
  - "landing/src/components/Footer.astro (typography)"
tech-stack:
  added: []
  patterns:
    - "text-balance on all section h2 headlines"
    - "SVG fill=currentColor for all icon replacements"
    - "Per-item .fade-up on CredibilityBar spans (no nested conflict)"
    - "SuppCo pattern: bolder typography, 3D button shadows, iOS badges"
    - "Duolingo pattern: branded marquee, credential source pills"
key-files:
  modified:
    - "landing/src/components/CreatorStory.astro (em-dash encoding)"
    - "landing/src/components/VideoSection.astro (em-dash encoding in comment)"
    - "landing/src/components/TrustSection.astro (SVG icons, 7 total)"
    - "landing/src/components/CredibilityBar.astro (real source logos, marquee, fade-up fix)"
    - "landing/src/components/Hero.astro (3-line format, bolder heading, iOS badges)"
    - "landing/src/components/HowItWorks.astro"
    - "landing/src/components/FeatureSection.astro"
    - "landing/src/components/Testimonials.astro"
    - "landing/src/components/Pricing.astro"
    - "landing/src/components/Footer.astro"
decisions:
  - "Screenshot-first audit: Playwright screenshot → identify issues → fix → re-screenshot"
  - "redesign-existing-projects skill activated for section-by-section audit"
  - "SuppCo + Duolingo reference patterns applied where applicable"
  - "Testimonials 3-col pattern flagged as taste observation but not restructured (requires user decision)"
metrics:
  completed: "2026-05-20"
---

# Phase 12 Plan 01: Desktop Audit Summary

One-liner: Fixed 4 pre-audit rendering bugs (mojibake ×2, emojis ×7, nested fade-up ×1), then ran a Playwright-driven section-by-section desktop audit at 1440px — applying redesign-existing-projects skill and SuppCo/Duolingo reference patterns to achieve consistent visual rhythm, dominant typography, and a clean build.

## Pre-Audit Bugs Fixed

| Bug | File | Fix |
|-----|------|-----|
| Mojibake `â€"` in body copy and author attribution | `CreatorStory.astro` | Replaced with proper em-dash `—` (U+2014) |
| Mojibake `â€"` in HTML comment | `VideoSection.astro` | Replaced with `—` |
| 6 emoji icons + 1 lock emoji | `TrustSection.astro` | Replaced with inline SVG (`fill="currentColor"` on all 7) |
| Nested `.fade-up` conflict on CredibilityBar wrapper | `CredibilityBar.astro` | Removed outer `.fade-up delay-1` from wrapper; per-item spans retain their own fade-up |

## Desktop Audit Fixes (1440px)

- **Hero:** 3-line headline format applied; bolder typography; iOS badges added to credibility; heading scaled up for dominance
- **CredibilityBar:** Real source logos (NIH, Mayo Clinic, etc.); branded marquee animation; `credibility-bar-label` pinned to top
- **HowItWorks:** Step heading size upgraded; gap-24 between steps; consistent rhythm
- **FeatureSection ×3:** Body text width capped (`max-w-md`); label uppercase/tracking-widest verified; `py-24` minimum enforced
- **TrustSection:** 2-col grid visual balance verified; SVG icons align with list text
- **Testimonials:** Card padding confirmed `p-7`; 3-col pattern flagged as taste observation (not restructured)
- **CreatorStory, Pricing, FinalCTA, Footer:** Spacing and typography rhythm pass

## Verification

| Check | Result |
|-------|--------|
| `grep -r "â€"" landing/src/components/` | 0 matches — PASS |
| `grep -c 'fill="currentColor"' TrustSection.astro` | 7 — PASS |
| `grep -c "emoji" TrustSection.astro` | 0 — PASS |
| CredibilityBar wrapper without `.fade-up` | PASS |
| `npm run build` exits 0 | PASS |

## Taste Observations (not actioned)

- Testimonials 3-equal-column grid is flat — a staggered layout or featured quote card would elevate it. Deferred to user decision.
