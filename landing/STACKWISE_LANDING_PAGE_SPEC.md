# STACKWISE_LANDING_PAGE_SPEC.md

## Handoff Specification for Implementation Agent

This document is the complete specification for the StackWise pre-launch marketing landing page. It contains every decision about structure, layout, content direction, visual design, interactions, and implementation notes. The implementing agent should make zero decisions about what the page includes, how it is structured, or what it communicates — those decisions are all made here. The agent's job is purely technical execution: choosing frameworks, writing code, and building what this document describes.

Read this entire document before writing any code.

---

## Table of Contents

1. [Project Context](#1-project-context)
2. [Page Purpose & Goals](#2-page-purpose--goals)
3. [Design System](#3-design-system)
4. [Global Layout & Behavior](#4-global-layout--behavior)
5. [Section-by-Section Specification](#5-section-by-section-specification)
6. [Animation & Interaction Spec](#6-animation--interaction-spec)
7. [Placeholder & Asset Strategy](#7-placeholder--asset-strategy)
8. [Waitlist Tool Integration](#8-waitlist-tool-integration)
9. [Responsive & Mobile Behavior](#9-responsive--mobile-behavior)
10. [SEO & Meta](#10-seo--meta)
11. [Reference Pages for Visual Inspiration](#11-reference-pages-for-visual-inspiration)
12. [Implementation Constraints](#12-implementation-constraints)
13. [Content & Copy Direction](#13-content--copy-direction)
14. [What the App Does NOT Do (Do Not Claim)](#14-what-the-app-does-not-do-do-not-claim)

---

## 1. Project Context

**App Name:** StackWise

**Platform:** iOS (iPhone only)

**Status:** Pre-launch. In active development (~40% complete as of May 2026). No App Store link. No TestFlight link.

**One-sentence description:** StackWise is an iOS app that analyzes interactions between the supplements and medications a user is already taking, then generates a personalized daily schedule with reminders to optimize timing and safety.

**What the app does (core features):**

1. **Interaction & Conflict Analysis** — Cross-references every item in the user's supplement/medication stack pairwise. Flags critical conflicts, advisory conflicts, positive pairings, and items not in the database. Uses a self-built, locally stored interaction database (not AI-generated at runtime). Every flagged interaction includes a mechanism explanation, suggested action, and citation from authoritative medical sources.

2. **Smart Daily Schedule** — Generates a personalized supplement timing schedule split into Morning / Afternoon / Evening based on the user's wake time, meal times, and interaction data. Uses a 4-rule priority algorithm: prescriptions placed first, timing conflicts separated, individual timing properties applied, then overflow balancing. Regenerates automatically on any stack change.

3. **Reminders** — Local notifications tied to the generated schedule. Notification body lists specific items per time block. Tapping opens a Today tab with per-block check-off.

**Target user:** People already taking 4+ supplements and/or medications daily. They are not shopping for new supplements — they are trying to make sure what they already take is safe and timed correctly. They may have tried researching interactions manually and found it overwhelming or unreliable.

**Primary competitor:** SuppCo (supp.co). StackWise differentiates by focusing on interaction safety and timing optimization, NOT supplement discovery, product ratings, or shopping.

**Business model:** 14-day free trial (full access, starts after onboarding), then $4.99/month or $35/year. No free tier. No degraded free experience.

---

## 2. Page Purpose & Goals

This is a pre-launch waitlist landing page. Its goals, in priority order:

1. **Collect waitlist emails** — Primary conversion action. Every visitor should have a clear, frictionless path to entering their email.
2. **Validate interest** — The page itself is a market validation tool. Email signups = demand signal.
3. **Communicate what StackWise does** — Clearly enough that the target user self-identifies within 5 seconds.
4. **Build trust and credibility** — For a health-adjacent app, trust is a prerequisite for any action.
5. **Differentiate from competitors** — Implicitly, through what the page focuses on (interactions, safety, timing) vs. what it doesn't (shopping, product ratings).

The page does NOT need to:
- Close a sale (the app doesn't exist on the App Store yet)
- Explain every feature in detail
- Serve as documentation
- Handle multiple user segments or audiences

---

## 3. Design System

### 3.1 Color Palette

The mood is **clean, approachable, and clinical-but-soft**. Think: a modern wellness clinic, not a hospital. Light, airy, trustworthy.

**Primary color — Clinical Blue:** A light aqua/clinical blue. Not a dark corporate blue. Think of the blue you'd see in a clean medical environment — calming, professional, not cold. Use as primary accent for CTAs, links, highlighted elements, section backgrounds.
- Suggested starting point: somewhere in the HSL range of 190-200° hue, 50-70% saturation, 85-95% lightness for backgrounds; darker (50-60% lightness) for buttons and interactive elements.
- The agent should define the exact hex values, but the direction is: light, aqua-leaning, clinical.

**Secondary accent — Sage Green:** A desaturated, light green. Muted and natural, not vibrant. Use sparingly as a secondary accent — badges, secondary highlights, subtle background tints.
- Suggested starting point: somewhere in the HSL range of 140-160° hue, 20-40% saturation, 70-85% lightness for backgrounds; slightly deeper for text accents.

**Backgrounds:** Predominantly white (#FFFFFF) or very subtle off-white/warm white. Some sections can use a very light tint of the clinical blue or sage green as a background to create visual rhythm between sections (alternating white and tinted backgrounds). Reference how Dropbox and SuppCo alternate between pure white sections and light-tinted sections.

**Text:** Dark gray or near-black for body text. Not pure #000000 — something like #1A1A2E or similar that feels slightly softer. Headings can be darker/bolder.

**Severity/warning colors:** Do NOT use red, amber, or warning colors decoratively on the landing page. Those are reserved for in-app interaction severity indicators. The landing page palette is purely blue, green, white, and dark text.

### 3.2 Typography

**Direction:** Clean, modern, slightly elevated. The page should feel designed, not default. Avoid generic system fonts (Arial, Helvetica, Roboto) and overused AI-aesthetic fonts (Inter, Space Grotesk).

**Recommended approach:** One distinctive display/heading font paired with a clean, highly readable body font. The heading font should feel modern and slightly premium — not playful, not corporate. The body font should be invisible (in the best sense) — easy to read, not distracting.

Good font pairing directions to explore:
- A geometric sans-serif for headings (e.g., DM Sans, Outfit, General Sans, Satoshi) paired with a humanist sans for body (e.g., Source Sans 3, Nunito Sans, or similar)
- Or a single versatile family used at different weights

The agent should choose specific fonts, but the constraint is: it must feel clean and premium, appropriate for a health/wellness context, and NOT generic.

**Typography scale:**
- Hero headline: Large, bold, attention-commanding. Reference Dropbox's hero headline sizing.
- Section headlines: Bold but not as large as hero. Reference Duolingo's feature headlines ("free. fun. effective." / "backed by science").
- Sub-headlines / descriptions: Regular weight, comfortable reading size. Never more than two sentences.
- Small labels / category tags: Uppercase, small, letter-spaced. Reference SuppCo's "PERSONALIZED STACK ANALYSIS" labels above their section headlines.

### 3.3 Spacing & Layout

**Generous white space is mandatory.** This is the single biggest factor in making the page feel premium vs. generic. Every section should breathe. Reference Dropbox's spacing — sections have significant vertical padding between them.

**Max content width:** ~1200px, centered. Content should not stretch edge-to-edge on large screens.

**Section vertical padding:** Generous — at minimum 80-100px top and bottom on desktop. The page should feel unhurried.

**Between-element spacing within sections:** Comfortable gaps between headline, description, and visual. Nothing should feel cramped.

### 3.4 Imagery & Visual Style

**App mockups:** All app screens are placeholders for now. Use realistic iPhone device frames with placeholder UI inside. The placeholder UI should suggest the type of content (an interaction analysis screen, a schedule view, a check-off screen) without needing to be the actual app design. Gray/wireframe style is acceptable, or the agent can create simple illustrative placeholders using the color palette.

**Photography:** No stock photos of people. The page should not look like SuppCo's hero (which uses a stock portrait). If human imagery is ever needed, it will be the creator's actual photo in the Creator Story section. All other visuals should be app mockups, icons, or abstract/illustrative elements.

**Icons:** If icons are used (e.g., in the How It Works steps), they should be simple line icons or filled icons consistent with the clean aesthetic. SF Symbols style is a good reference direction since the app itself uses SF Symbols.

---

## 4. Global Layout & Behavior

### 4.1 Navigation Bar (Sticky Header)

**Structure:** Logo/wordmark on the left, single CTA button on the right.

- **Left:** "StackWise" wordmark (text-based for now; logo asset can replace later). Clean, modern typography.
- **Right:** "Join the Waitlist" button (same style as the primary CTA). This button should scroll the user to the nearest waitlist email capture field (hero if at top, final CTA if they've scrolled past the hero).
- **No other nav links.** This is a single-page marketing site. There is no About, Features, Pricing — the user scrolls through them naturally. A nav with multiple links implies a multi-page site and adds unnecessary complexity.

**Behavior:** Sticky on scroll. Subtle background blur or slight opacity shift on scroll to differentiate from page content. Should not feel heavy or distracting.

**Mobile:** Same structure, compressed. Logo left, button right.

### 4.2 Page Flow

The page is a single continuous scroll. No separate pages, no routing. Sections flow vertically in the order specified in Section 5 below. Each section occupies the full viewport width (even if content is max-width constrained within) to allow for alternating background colors.

### 4.3 CTA Consistency

Every CTA on the page performs the same action: captures an email for the waitlist. The button text may vary slightly by context ("Join the Waitlist," "Get Early Access," "Notify Me at Launch") but the action is always the same. Use a consistent button style for the primary CTA throughout the page.

---

## 5. Section-by-Section Specification

---

### Section 1: Hero

**Purpose:** In under 5 seconds, make the target user think "this is exactly what I need" and capture their email.

**Layout:** Split layout — text content on the left, app mockup visual on the right. Reference: Dropbox hero, SuppCo hero. On mobile, stacks vertically: text on top, visual below.

**Content elements (left side):**

1. **Headline** — Short, clear, benefit-or-problem focused. Under 10 words. Should instantly communicate what StackWise does for the user without using jargon. Copy direction options (the implementing agent should use one of these or a close variation — do not invent a completely different direction):
   - "Your supplements might be working against each other."
   - "Make your supplement stack actually work."
   - "Know exactly what to take, and when."
   - "Stop guessing. Start knowing."
   The headline should resonate with someone who already takes multiple supplements and has wondered whether they're doing it right.

2. **Sub-headline** — One sentence. Expands on the headline with slightly more specificity. Copy direction: "StackWise analyzes interactions between your supplements and medications, then builds a personalized daily schedule so everything works together." Or similar — brief, plain language, one sentence max.

3. **Waitlist CTA** — Email input field + submit button, inline (not a separate page or modal). Placeholder text in the input: "Enter your email." Button text: "Join the Waitlist" or "Get Early Access." Below the input, a small line of text: "Be the first to know when StackWise launches on the App Store."

4. **Pre-launch indicator** — Small text or badge: "Coming soon to the App Store." No App Store badge (Apple doesn't allow the official badge without a live listing). Just clean text.

**Content elements (right side):**

5. **App mockup** — An iPhone device frame showing a placeholder of the app's primary screen (the interaction analysis results screen is the most compelling — it's the core value proposition visualized). This is a placeholder for now. The device frame should be angled slightly or presented with subtle depth/shadow to feel premium, not flat. Reference: SuppCo's hero mockup treatment with floating UI cards around the phone, or Dropbox's product screenshot treatment.

**Visual notes:**
- The hero background should be white or very subtly tinted.
- Generous vertical padding — the hero should feel spacious, not cramped.
- The headline should be the largest text on the entire page.
- The mockup should be large enough to be visually compelling but not so large it pushes the CTA below the fold on standard screens.

---

### Section 2: Credibility Bar

**Purpose:** Immediately establish that the interaction data comes from authoritative, recognized medical sources. This answers the implicit question "where does this information come from?" before the user even asks it.

**Layout:** Full-width section with a light background tint (very subtle clinical blue or sage green tint — reference SuppCo's "As Seen In" bar which uses a light blue background). Content centered.

**Content elements:**

1. **Anchoring text** — A single short line above the source names. Copy direction: "Interaction data built from sources you trust" or "Research-backed analysis from authoritative sources." Keep it under 10 words.

2. **Source names** — Displayed horizontally in a row: **NIH Office of Dietary Supplements**, **PubMed**, **Memorial Sloan Kettering**, **MedlinePlus**, **OpenFDA**. These should be displayed as clean, styled text (not logos — we don't have permission to use their logos, and text names work fine for credibility). The text should be styled distinctly from body copy — slightly larger, possibly medium weight, evenly spaced. If the agent can find official or widely-used representations of these names that are in the public domain, those can be used, but plain text is the safe default.

**Visual notes:**
- This section should be compact — not a full "section" with massive padding, more like a credibility strip. Reference the logo bar sections on Dropbox and Headspace — they're visually distinct but not tall.
- The light background tint differentiates it from the white hero above.

---

### Section 3: How It Works (3 Steps)

**Purpose:** Give the visitor a clear, instant mental model of what using StackWise looks like. Three steps. Visuals do the heavy lifting.

**Layout:** Alternating zigzag — text on one side, visual on the other, alternating per step. Reference: Duolingo's feature sections with the left-right-left pattern. Each step is its own visual "row" within the section.

**Content elements (per step):**

Each step has:
1. **Step number** — Subtle, small (e.g., "01", "02", "03" or "Step 1", "Step 2", "Step 3"). Not the focal point — just orientation.
2. **Headline** — Short, bold, benefit-oriented. 3-6 words.
3. **Description** — One to two sentences max. Plain language.
4. **Visual** — App mockup placeholder showing the relevant screen.

**Step 1: Add Your Stack**
- Headline direction: "Add what you take"
- Description direction: "Enter your supplements and medications. StackWise does the rest."
- Visual: Placeholder of the stack entry / list screen.

**Step 2: See Your Interactions**
- Headline direction: "See what's working — and what's not"
- Description direction: "Every item is automatically cross-referenced. Conflicts, positive pairings, and unknowns — all explained with citations."
- Visual: Placeholder of the interaction analysis results screen showing flagged conflicts and positive pairings.

**Step 3: Get Your Schedule**
- Headline direction: "Your personalized daily schedule"
- Description direction: "Morning, afternoon, evening — timed around your meals and medications. Updated automatically when your stack changes."
- Visual: Placeholder of the schedule screen showing the three time blocks.

**Visual notes:**
- Each step should have generous spacing between it and the next.
- The alternating layout creates visual rhythm — left/right/left or right/left/right. Choose whichever feels better with the content.
- On mobile, each step stacks vertically: visual on top, text below (or vice versa — consistent per step).

---

### Section 4: Feature Deep-Dives (3 Sections)

**Purpose:** Expand on the three core features with more detail and larger, more immersive visuals. These are the "zoom in" after the "overview" of How It Works.

**Layout:** Each feature gets its own full-width section. Centered content. Large app mockup with text above or beside it. Reference: Dropbox's feature sections ("Find it fast, every time" / "Security never comes second") and SuppCo's "Personalized Stack Analysis" section.

**Pattern per feature:**
1. **Category label** — Small, uppercase, letter-spaced, colored (clinical blue or sage green). Sits above the headline. Reference: SuppCo's "PERSONALIZED STACK ANALYSIS" label.
2. **Headline** — Benefit-focused, bold. Under 10 words.
3. **Description** — One to two sentences. What it does and why it matters.
4. **Visual** — Large app mockup (placeholder). This should be the biggest visual element in the section. Can be a phone mockup, or a cropped/zoomed UI element if that shows the feature better.

**Feature 4A: Interaction & Conflict Analysis**
- Category label: "INTERACTION ANALYSIS"
- Headline direction: "Know which supplements work together — and which don't"
- Description direction: "Every pair in your stack is automatically analyzed. Critical conflicts, advisory warnings, and positive combinations — each with an explanation and citation from medical research."
- Visual: Placeholder showing the analysis results screen with flagged interactions, severity indicators, and a citation preview.
- Key details to convey (through copy or visual): conflicts are explained (not just flagged), citations are provided, prescriptions are never modified.

**Feature 4B: Smart Daily Schedule**
- Category label: "PERSONALIZED SCHEDULE"
- Headline direction: "Timed to your day, not a generic chart"
- Description direction: "StackWise builds a morning, afternoon, and evening schedule based on your wake time, meals, and interaction data. It updates automatically whenever your stack changes."
- Visual: Placeholder showing the schedule view with three time blocks, items listed under each, and suggested time windows.
- Key details to convey: personalized to user's actual times, automatic updates, separation of conflicting items.

**Feature 4C: Reminders & Daily Check-Off**
- Category label: "REMINDERS"
- Headline direction: "Never miss a dose, never second-guess timing"
- Description direction: "Get notified at each time block with exactly what to take. Tap to check off — done."
- Visual: Placeholder showing a notification preview and the Today tab check-off screen.
- Key details to convey: notifications tell you *which* items, simple check-off interface, tied to the schedule.

**Visual notes:**
- Alternate background colors between white and very subtle tint to create visual separation between the three feature sections.
- The visuals should be noticeably larger than the How It Works visuals — these are the immersive "see the product" moments.
- On mobile, text stacks above the visual.

---

### Section 5: Trust & Data Section

**Purpose:** Answer the two biggest trust questions for a health app: (1) "Is my data safe?" and (2) "Is this information reliable?" This is a combined section with two subsections.

**Layout:** Full-width section, light background tint. Two subsections stacked vertically, or side-by-side on desktop (two columns). Reference: Dropbox's "Security never comes second" for the privacy subsection's tone and layout.

**Subsection 5A: Privacy & On-Device Architecture**

- Headline direction: "Your health data never leaves your device"
- Description direction: "No cloud accounts. No server-side storage. No health data transmitted — ever. StackWise runs entirely on your iPhone. The only outbound data is optional feedback text you choose to send, which never includes health information."
- Optional visual: A simple, clean icon or minimal illustration suggesting on-device storage (e.g., a phone with a shield, or a lock icon). Keep it simple — not an elaborate infographic.

**Subsection 5B: Database Credibility**

- Headline direction: "Built from research, not algorithms"
- Description direction: "The interaction database was built through structured research from authoritative medical sources — not generated by AI. Every interaction record includes a mechanism explanation and at least one citation. Only medium and high confidence records are included. If an item isn't in the database, StackWise tells you — and links you to external resources."
- **Key credibility signals to surface (as short, scannable callouts or a small stat grid — NOT as a paragraph):**
  - "Covers the most commonly taken supplements and prescribed medications"
  - "Every record citation-backed from NIH, PubMed, MSK, MedlinePlus, or OpenFDA"
  - "Confidence-filtered — low-confidence records excluded"
  - "Human-verified against original sources"
  - "Honest about gaps — items not in the database are clearly flagged"
- **Do NOT include exact database counts (50 supplements, 20 medications, 63 interactions).** The scope is strong for v1 but the numbers don't convey that without context. Use qualitative descriptions instead. Exact numbers may be added later as the database grows.

**Visual notes:**
- The credibility signals should be visually scannable — small cards, icon + text pairs, or a clean grid. Not a wall of text.
- This section should feel substantive but not overwhelming. It's a trust-builder, not a whitepaper.

---

### Section 6: Video / Demo

**Purpose:** Show the app in action. Video walkthroughs build trust and directly increase signups (per the YouTube guide research).

**Layout:** Centered, full-width section. White background.

**Content elements:**

1. **Headline** — Short. Copy direction: "See StackWise in action" or "Watch how it works."
2. **Video embed container** — Placeholder for now. Build the container at a 16:9 aspect ratio, centered, with rounded corners and a subtle shadow. Inside the placeholder, show a play button icon and text like "Video coming soon" or a static thumbnail placeholder.
3. **Below the video** — Optional one-line caption: "From stack entry to personalized schedule in under 2 minutes." (Or similar — communicating that the video is short and demonstrates the full flow.)

**Implementation note:** The video container must be built so that swapping in a real video embed (YouTube, Vimeo, or self-hosted) requires only changing a URL or embed code, not restructuring the layout.

**Visual notes:**
- The video should be large and prominent — this is a key trust element.
- On mobile, the video should scale to full width with maintained aspect ratio.

---

### Section 7: Social Proof (Testimonials)

**Purpose:** Show that real people have reacted positively to StackWise / the idea.

**Layout:** Three testimonial cards in a horizontal row. Reference: Headspace's testimonial section exactly — three cards, clean background, quotes displayed prominently.

**Content elements (per card):**

1. **Quote text** — The testimonial quote. Placeholder text for now. Each quote should be 1-3 sentences. The quotes are from real people reacting to the app concept (not fabricated user reviews).
2. **Attribution** — First name and optional one-line descriptor (e.g., "Sarah M. — takes 6 supplements daily" or just "Sarah M."). No photos required initially — text-only attribution is fine.

**Visual notes:**
- Cards should have a subtle background (light gray or very light tint), rounded corners, and comfortable internal padding. Reference the Headspace testimonial card style.
- Three cards side by side on desktop. On mobile, stack vertically or use a horizontal scroll/carousel.
- The section headline above the cards: "What early supporters are saying" or similar. Honest framing — not "What our users say" (the app hasn't launched).

---

### Section 8: Creator Story

**Purpose:** Personalize the product. Solo dev building something they care about. People support individuals more than faceless companies.

**Layout:** Centered, compact section. Photo on one side, text on the other (or photo above text centered). This should feel personal and warm, not corporate.

**Content elements:**

1. **Photo** — Placeholder for now. Circular crop, medium size. Will be replaced with the creator's actual photo.
2. **Headline** — Copy direction: "Built by someone who had the same problem" or "Why I'm building StackWise" or simply the creator's name.
3. **Text** — Two to three sentences max. Personal, authentic, first-person. Copy direction: Explain the personal connection to the problem (taking multiple supplements, being frustrated by conflicting information, wanting to build something reliable). This is NOT a bio — it's a "why I built this" story.

**Visual notes:**
- This section should feel distinct from the others — more personal, slightly different layout or background treatment.
- Keep it short. This is a trust signal, not an autobiography.

---

### Section 9: Pricing Preview

**Purpose:** Be transparent about the business model. No surprises.

**Layout:** Centered, compact section. Clean and minimal.

**Content elements:**

1. **Headline** — Copy direction: "Simple, transparent pricing" or "Try it free for 14 days."
2. **Pricing display** — This is a single tier, not a comparison grid. Display:
   - "14-day free trial — full access to everything"
   - "$4.99/month" or "$35/year" (display both options, clarify the annual savings)
3. **Small note below** — "No credit card required to join the waitlist." (Reduces friction — clarifies that the waitlist signup is free.)

**Visual notes:**
- Do NOT build an elaborate pricing table or comparison grid. This is one product with one price. Keep it visually simple — a card or clean text block.
- On mobile, everything stacks naturally since it's already compact.

---

### Section 10: Final CTA + Footer

**Purpose:** Recapture visitors who scrolled the full page and are now ready to act.

**Layout:** Two distinct sub-sections stacked: the final CTA block, then the footer below it.

**Final CTA Block:**

1. **Headline** — Reinforcing, closing. Copy direction: "Your stack, optimized." or "Be the first to try StackWise." or "Stop guessing. Start knowing." (Can echo or mirror the hero headline.)
2. **Waitlist email capture** — Same input + button pattern as the hero. Identical functionality.
3. **"Coming soon to the App Store"** text.
4. **Optional stat or trust callout** — If a waitlist count is available and impressive, display it ("Join 500+ people on the waitlist"). If not, omit. Do not display a small number — wait until it's meaningful.

**Footer:**

- **Links:** Privacy Policy (placeholder URL for now — will be hosted on GitHub Pages before App Store submission), Contact/Feedback (mailto or link to a simple form), Terms of Service (placeholder).
- **Social links:** Placeholder slots for social media icons (Twitter/X, Instagram, or whatever the creator uses). Only include links that actually exist — empty social links damage credibility.
- **Copyright line:** "© 2026 StackWise. All rights reserved."
- **Small disclaimer:** "StackWise is not a substitute for professional medical advice. Always consult your healthcare provider before making changes to your supplement or medication regimen."

**Visual notes:**
- The final CTA block should have a distinct background — either the clinical blue tint or a slightly deeper shade — to visually signal "this is the closing moment." Reference Headspace's final CTA section with the sky-blue background.
- The footer below is standard — dark or medium gray background, lighter text, compact.

---

## 6. Animation & Interaction Spec

**Philosophy:** Subtle animations that bring the page to life and create a premium feel. NOT complex animation sequences or heavy libraries. The goal is: "static page elevated to feel dynamic" — not "animated experience."

**Specific animations to implement:**

1. **Scroll-triggered fade-in:** As each section enters the viewport, its content elements (headline, description, visual) fade in with a slight upward slide (translate-y from ~20px to 0, opacity from 0 to 1). Stagger the elements slightly (headline first, then description, then visual — ~100-150ms delays). This is the primary animation pattern used throughout the page.

2. **Hero entrance:** On page load, the hero content fades in with a slightly longer, more deliberate animation than scroll-triggered sections. The mockup on the right can have a subtle float or parallax-lite effect (very gentle, not distracting).

3. **Credibility bar:** Source names can animate in with a subtle sequential fade (left to right, staggered) as the section enters the viewport.

4. **App mockups:** Placeholder mockups can have a very subtle hover effect on desktop (slight scale-up or shadow deepening). Not essential — only if it feels natural.

5. **CTA button:** Subtle hover state (slight color shift, gentle scale, or shadow). Standard interaction feedback.

6. **Sticky nav:** Smooth background transition on scroll (transparent → slightly opaque/blurred).

**What NOT to implement:**
- No parallax scrolling (too complex for the value it adds)
- No scroll-jacking or section-locking
- No complex SVG path animations
- No auto-playing background videos
- No particle effects or floating elements
- No horizontal scroll sections

**Implementation approach:** CSS transitions and animations are strongly preferred over JavaScript animation libraries. If a library is needed, keep it lightweight (e.g., a simple Intersection Observer setup for scroll triggers). Avoid heavy dependencies like GSAP unless the agent determines it's the simplest path — the priority is fast load times.

---

## 7. Placeholder & Asset Strategy

The following elements are placeholders that will be replaced with real assets later. The page structure must accommodate these swaps without any layout restructuring.

| Element | Placeholder Approach | Will Be Replaced With |
|---|---|---|
| App mockups (all sections) | iPhone device frame with gray/wireframe UI placeholder inside, or a simple illustrative representation of each screen using the color palette | Actual app screenshots or high-fidelity mockups |
| Video (Section 6) | Play button + "Video coming soon" + static container at 16:9 | Embedded video (YouTube/Vimeo/self-hosted) |
| Creator photo (Section 8) | Circular gray placeholder with person icon | Actual photo |
| Testimonial quotes (Section 7) | Placeholder quote text (realistic but clearly placeholder — e.g., "This is exactly what I've been looking for...") | Real testimonial quotes from early supporters |
| Logo/wordmark (nav) | Text-based "StackWise" in the heading font | Designed logo asset (if created) |
| Social links (footer) | Icon placeholders, href="#" | Actual social URLs |
| Privacy policy link (footer) | href="#" or placeholder URL | GitHub Pages hosted privacy policy URL |

**Critical implementation note:** All placeholder containers (especially video and mockups) must use realistic sizing. If the placeholder is a tiny gray box and the real asset is a large video, the page will reflow badly when swapped. Size placeholders to the real expected dimensions.

---

## 8. Waitlist Tool Integration

**Decision:** The implementing agent should research and recommend a lightweight, low-cost waitlist/email capture tool. The developer wants to be consulted before a final choice is made.

**Requirements for the tool:**
- Low or zero cost for early stage (under ~1,000 signups)
- Simple embed — either a form action URL, an API endpoint, or a JavaScript embed
- Sends a confirmation or welcome email to the subscriber (ideally)
- Provides a dashboard to view and export collected emails
- Does NOT require a complex setup or paid plan for basic functionality

**Options to research and compare:**
- **FormSpark** (formaction-based, simple)
- **Formspree** (the project already uses Formspree for in-app feedback — consistency advantage)
- **Beehiiv** (newsletter platform, more features but potentially more complex)
- **Mailchimp embedded forms** (well-known, robust, free tier exists)
- **ConvertKit** (creator-focused)
- **Buttondown** (lightweight, dev-friendly)

**Implementation approach:** The waitlist form appears in two places (hero and final CTA). Both should submit to the same backend. If the chosen tool supports it, display a success message inline after submission ("You're on the list! We'll email you when StackWise launches.") rather than redirecting to a separate page.

**The agent should present a brief recommendation (2-3 sentences) with reasoning before implementing.** The developer will approve.

---

## 9. Responsive & Mobile Behavior

Marketing traffic will likely come from social media, meaning a significant portion of visitors will be on phones. Mobile is not an afterthought — it should feel equally polished.

**Breakpoints (suggested):**
- Desktop: 1024px+
- Tablet: 768px - 1023px
- Mobile: < 768px

**Key responsive behaviors:**

- **Hero:** Split layout → stacked (text top, mockup bottom). CTA input may go full-width on mobile.
- **Credibility bar:** Horizontal row → may wrap to two lines, or use smaller text. Should remain a single visual strip, not a grid.
- **How It Works:** Zigzag alternating → stacked vertically per step. Consistent order (visual above text, or text above visual — pick one and keep it consistent).
- **Feature deep-dives:** Text + mockup side-by-side → stacked. Mockup should remain large and prominent.
- **Testimonials:** Three cards side by side → single column stack or horizontal swipe carousel.
- **Pricing:** Already compact, should stack naturally.
- **Nav:** Same structure (logo + button), just compressed spacing. No hamburger menu needed (there are no nav links to hide).

**Touch considerations:**
- CTA buttons should be comfortably tappable (min 44px height)
- Email input fields should be generously sized on mobile
- No hover-dependent interactions (hover effects are desktop enhancements, not functional requirements)

---

## 10. SEO & Meta

**Page title:** "StackWise — Supplement & Medication Interaction Analysis for iPhone"

**Meta description:** "StackWise analyzes interactions between your supplements and medications, then builds a personalized daily schedule. Join the waitlist for early access."

**Open Graph / Social sharing:**
- og:title: "StackWise — Know exactly what to take, and when."
- og:description: "Supplement and medication interaction analysis. Personalized daily scheduling. Coming soon to the App Store."
- og:image: A designed social card (placeholder for now — the agent can generate a simple branded card using the color palette and wordmark).
- og:type: "website"

**Additional SEO considerations:**
- Proper heading hierarchy (single H1 on the page — the hero headline; section headlines as H2; sub-elements as H3)
- Alt text on all images and mockup placeholders
- Fast page load speed (this is both a UX and SEO factor — keep the page lightweight)
- Semantic HTML throughout

---

## 11. Reference Pages for Visual Inspiration

The following live pages were analyzed during the design process. The agent should visit these for visual reference when making implementation decisions about spacing, animation feel, typography weight, and section transitions.

| Page | What to reference |
|---|---|
| **dropbox.com** | Hero layout (headline left, product UI right), section spacing, feature section pattern (headline + short copy + large visual), security/trust section treatment, premium feel through simplicity, scroll animations |
| **headspace.com** | Testimonial card layout (three horizontal), credibility logo bar, final CTA section with background color shift and stats, playful-but-clean aesthetic balance |
| **duolingo.com** | Alternating left-right feature layout (zigzag), minimal copy per section, bold short headlines, bottom CTA with floating phone mockups and app store badges, use of white space |
| **supp.co** | Direct competitor reference — hero layout with person + floating UI cards, "As Seen In" credibility bar style, uppercase category labels above section headlines, feature deep-dive with large phone mockup (SuppCo's "Personalized Stack Analysis" section), overall health/supplement landing page tone |

---

## 12. Implementation Constraints

- **No backend required.** This is a static site with a third-party form submission for the waitlist. No database, no server, no authentication.
- **Fast load time is critical.** Keep dependencies minimal. Optimize images. Avoid heavy JavaScript bundles. The page should score 90+ on Lighthouse performance.
- **Hosting:** The developer likely needs this hosted somewhere simple and cheap/free (GitHub Pages, Netlify, Vercel, Cloudflare Pages). The agent should recommend and set up accordingly. This site does NOT need a CMS.
- **Framework choice:** The agent should choose the most appropriate approach. Options include plain HTML/CSS/JS (simplest, fastest loading), a static site generator (Astro, 11ty), or a lightweight React/Next.js setup if the agent determines it adds value. The priority is: fast to build, fast to load, easy to update when real assets arrive. Plain HTML/CSS/JS is perfectly acceptable if it meets these criteria.
- **No cookie consent banner needed** for v1 (the site doesn't set cookies unless the waitlist tool requires it — if so, address it then).
- **Custom domain:** Assume a custom domain will be connected. The agent should note any DNS/configuration steps needed.

---

## 13. Content & Copy Direction

**Overall tone:** Calm, clear, substantive, slightly warm. Not hype-forward. Not corporate. Not playful/casual. Think: a knowledgeable friend who takes your health seriously and explains things clearly.

**Copy rules:**
- No headline exceeds 10 words
- No description exceeds two short sentences
- No paragraph anywhere on the page
- Write for an 8-year-old reading level (simple words, short sentences)
- Let visuals explain features — copy sets context, not detail
- Do not use medical jargon ("pairwise analysis," "canonical naming," "bidirectional lookup")
- Do not use startup jargon ("disrupting," "revolutionary," "game-changing," "leveraging AI")
- Do not use hype language ("the ultimate," "the only," "the best")
- Every piece of copy should feel like it was written by a real person, not a marketing team

**Voice:** First-person plural is acceptable ("We built..." in the creator section) but most copy should be second-person ("Your supplements," "Your schedule," "You'll see..."). The page speaks to the user about their problem and their solution.

**Competitor differentiation (implicit, never explicit):**
- StackWise focuses on interactions and safety. Do not mention supplement discovery, product ratings, shopping, or protocols.
- StackWise uses a human-built citation-backed database. Do not claim AI-powered analysis (it's not).
- StackWise is on-device only. Emphasize privacy without attacking competitors.
- Never mention SuppCo or any competitor by name.

---

## 14. What the App Does NOT Do (Do Not Claim)

The following are explicitly out of scope per the product spec. The landing page copy must not claim or imply any of these:

- **No drug-to-drug interaction analysis.** Only supplement↔supplement and supplement↔medication.
- **No free tier.** 14-day free trial only, then paid. Do not imply "free" without the trial context.
- **No iCloud/cross-device sync.** All data on-device only.
- **No streak tracking or adherence history.** Daily check-off only.
- **No multi-profile support.** Single user.
- **No AI/LLM-powered analysis.** Static database, not AI-generated. Do not use "AI" anywhere on the page.
- **No server-side infrastructure.** Everything on-device.
- **No prescription recommendations.** Never suggests changing prescriptions — only supplements.
- **No Android version.** iOS (iPhone) only.

---

*End of specification. The implementing agent should have everything needed to build the complete landing page from this document. If any ambiguity remains, err on the side of simplicity, clean execution, and fast load times.*
