# Phase 10 Context — Landing Page Foundation

## What This Phase Is

Scaffold and configure the Astro project that powers the StackWise pre-launch waitlist landing page. The landing page lives at `landing/` inside the main iOS repo (not a separate repository) so Claude Code retains access to all app planning context.

## Key Decisions

**File organization:** `landing/` subfolder inside `Supplement-Manager/` repo. Vercel is configured to build from that subdirectory via Root Directory setting. Xcode and iOS tooling ignore non-iOS files.

**Framework:** Astro (not Next.js). Zero JS by default = fastest possible page loads. Purpose-built for static marketing sites. No React hydration overhead for a single-page static site.

**Styling:** Tailwind CSS v4 via `@astrojs/tailwind`. Design tokens defined in `global.css` using `@theme` block. Font utilities generated as `font-heading` / `font-body`.

**Fonts:** Outfit (headings) + DM Sans (body). Both from Google Fonts. Imported at top of `global.css`.

**Waitlist backend:** ConvertKit (Kit). Free up to 10,000 subscribers. Sends confirmation emails. Form ID: `9457828`. API key stored in `PUBLIC_KIT_API_KEY` env var.

**Hosting:** Vercel Hobby plan (free). Auto-deploys on push to `main`.

## Color Palette

| Token | Hex | Usage |
|---|---|---|
| `--color-blue-tint` | `#E8F4F8` | Section background tints |
| `--color-blue-accent` | `#2B9EB3` | CTAs, interactive elements |
| `--color-blue-dark` | `#1E7A8C` | Hover state for buttons |
| `--color-green-tint` | `#E8F0EC` | Secondary tints |
| `--color-green-accent` | `#6B9E7F` | Secondary highlights |
| `--color-off-white` | `#F8FAFB` | Alternate section backgrounds |
| `--color-heading` | `#1A1A2E` | All headings |
| `--color-body` | `#4A4A60` | Body text |
| `--color-muted` | `#8888A0` | Labels, captions |

## Animation System

- **Scroll-triggered:** `.fade-up` class + Intersection Observer in `Layout.astro`. Elements fade in with upward slide as they enter viewport. Stagger delays via `.delay-1` through `.delay-4`.
- **Hero entrance:** `.hero-enter` class with CSS `@keyframes heroEnter`. Fires on page load with staggered delays.
- **Nav:** `nav-scrolled` class toggled via scroll listener. Adds backdrop blur + shadow after 20px scroll.

## Spec Reference

Full marketing and content decisions in `STACKWISE_LANDING_PAGE_SPEC.md` at repo root.
