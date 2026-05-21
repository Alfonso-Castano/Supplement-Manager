---
phase: "12"
plan: "03"
subsystem: "landing-page"
tags: [animation, hover-states, easing, css, polish]
requires:
  - "12-02 complete: responsive layout correct at all breakpoints"
  - "high-end-visual-design skill"
provides:
  - ".fade-up animations with spring cubic-bezier easing (0.7s) replacing generic ease"
  - ".hero-enter animation with spring easing (0.9s)"
  - "Nav scroll transition tuned (0.4s cubic-bezier)"
  - "Hover states on Testimonial cards, Pricing tiers, VideoSection play button"
  - "All animations verified firing via Playwright scroll-through"
affects:
  - "landing/src/styles/global.css (.fade-up and .hero-enter easing)"
  - "landing/src/components/Nav.astro (nav scroll transition)"
  - "landing/src/components/Testimonials.astro (card hover lift)"
  - "landing/src/components/Pricing.astro (tier border hover)"
  - "landing/src/components/VideoSection.astro (play button hover scale)"
  - "landing/src/layouts/Layout.astro (IntersectionObserver threshold tuned if needed)"
tech-stack:
  added: []
  patterns:
    - "cubic-bezier(0.16, 1, 0.3, 1) — spring deceleration used by Linear, Vercel, Apple"
    - "hover:shadow-md hover:-translate-y-0.5 — card lift pattern"
    - "hover:border-[var(--color-blue-accent)]/40 — border intensification on pricing tiers"
    - "transition-transform hover:scale-110 — play button scale"
    - "CSS-only animation (no GSAP or new libraries)"
key-files:
  modified:
    - "landing/src/styles/global.css (.fade-up transition, .hero-enter animation)"
    - "landing/src/components/Nav.astro (nav-scrolled transition duration + easing)"
    - "landing/src/components/Testimonials.astro (card hover classes)"
    - "landing/src/components/Pricing.astro (monthly + annual tier hover)"
    - "landing/src/components/VideoSection.astro (play button hover)"
decisions:
  - "high-end-visual-design skill activated; Section 5 (Motion Choreography) rules applied"
  - "cubic-bezier(0.16, 1, 0.3, 1): snappy start, near-instant stop — reference tier easing"
  - "0.7s for fade-up (up from 0.6s), 0.9s for hero-enter (cinematic), 0.4s for nav"
  - "CSS-only constraint honored — no GSAP or animation libraries added"
  - "Do not change existing hover states on Nav CTA, WaitlistForm, PhoneMockup, Footer links"
metrics:
  completed: "2026-05-20"
---

# Phase 12 Plan 03: Animation & Interaction Polish Summary

One-liner: Replaced generic `ease` easing with Apple-tier `cubic-bezier(0.16, 1, 0.3, 1)` on all scroll animations and the nav transition, added hover states to Testimonial cards, Pricing tiers, and the VideoSection play button — all CSS-only, verified via Playwright scroll-through.

## Animation Easing Changes

| Target | Before | After |
|--------|--------|-------|
| `.fade-up` transition | `0.6s ease` | `0.7s cubic-bezier(0.16, 1, 0.3, 1)` |
| `.hero-enter` animation | `0.8s ease` | `0.9s cubic-bezier(0.16, 1, 0.3, 1)` |
| Nav scroll transition | `0.3s ease` | `0.4s cubic-bezier(0.16, 1, 0.3, 1)` |

## Hover States Added

| Component | Hover Behavior |
|-----------|---------------|
| Testimonial cards | `hover:shadow-md hover:-translate-y-0.5` (lift + deeper shadow) |
| Pricing monthly tier | `hover:border-[var(--color-blue-accent)]/40 hover:shadow-sm` |
| Pricing annual tier | `hover:border-[var(--color-blue-accent)]/60 hover:shadow-sm` |
| VideoSection play button | `hover:scale-110 cursor-pointer` |

## Hover States Left Unchanged (canonical — do not modify)

- Nav CTA: `hover:bg-[var(--color-blue-dark)] hover:scale-[1.02] active:scale-[0.98]`
- WaitlistForm submit: same pattern as Nav CTA
- PhoneMockup: `hover:scale-[1.02]`
- Footer links: `hover:text-white transition-colors`

## Verification

| Check | Result |
|-------|--------|
| `grep "cubic-bezier(0.16, 1, 0.3, 1)" global.css` | 3 matches — PASS |
| `grep "0.6s ease\|0.8s ease" global.css` | 0 matches — PASS |
| `grep "hover:shadow-md" Testimonials.astro` | 1 match — PASS |
| `grep "hover:border-\[var(--color-blue-accent)\]" Pricing.astro` | 2 matches — PASS |
| `grep "hover:scale-110" VideoSection.astro` | 1 match — PASS |
| Playwright scroll-through: fade-up fires section by section | PASS |
| Nav frosted glass after 100px scroll | PASS |
| `npm run build` exits 0 | PASS |

## Phase 13 Notes

- All hover states are CSS-only and do not interfere with asset swaps in Phase 13
- PhoneMockup components (all sections) are ready for screenshot replacement
- No animation changes needed for Phase 13 asset integration
