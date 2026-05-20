---
name: suppco-design
description: Design system skill for suppco. Activate when building UI components, pages, or any visual elements. Provides exact color tokens, typography scale, spacing grid, component patterns, and craft rules. Read references/DESIGN.md before writing any CSS or JSX.
---

# suppco Design System

You are building UI for **suppco**. Light-themed, warm palette, sans-serif typography (Aeonik), compact density on a 4px grid, expressive motion.

## Visual Reference

**IMPORTANT**: Study ALL screenshots below before writing any UI. Match colors, typography, spacing, layout, and motion exactly as shown.

### Homepage

![suppco Homepage](screenshots/homepage.png)

> Read `references/DESIGN.md` for full token details.

## Design Philosophy

- **Layered depth** — use shadow tokens to create a sense of physical layering. Each elevation level has a specific shadow.
- **Gradient accents** — gradients are used thoughtfully for emphasis, not decoration.
- **Type pairing** — Aeonik for body/UI text, Graphik for headings/display. Never introduce a third typeface.
- **compact density** — 4px base grid. Every dimension is a multiple of 4.
- **warm palette** — the color temperature runs warm, matching the sans-serif typography.
- **Restrained accent** — `#ff7700` is the only pop of color. Used exclusively for CTAs, links, focus rings, and active states.
- **Expressive motion** — animations are an integral part of the experience. Use spring physics and layout animations.

## Color System

### Core Palette

| Role | Token | Hex | Use |
|------|-------|-----|-----|
| Background | `--background` | `#f9f9f5` | Page/app background |
| Surface | `--surface` | `#fff3e8` | Cards, panels, modals |
| Text Primary | `--text-primary` | `#000000` | Headings, body text |
| Text Muted | `--text-muted` | `#a6a6a6` | Captions, placeholders |
| Accent | `--accent` | `#ff7700` | CTAs, links, focus rings |

### Status Colors

| Status | Hex | Use |
|--------|-----|-----|
| Success | `#29a878` | Confirmations, positive trends |
| Warning | `#faca15` | Caution states, pending items |
| Danger | `#e02424` | Errors, destructive actions |

### Extended Palette

- **color-teal:** `#0a7594`
- **color-teal-wash:** `#e4f9ff` — Light surface or highlight color
- **color-gray:** `#687280`
- **color-gray-lighter:** `#e8ddf4` — Light surface or highlight color
- **color-blue-darker:** `#0e556a`
- `#666666`
- **color-green-darker:** `#1d7554`
- **color-gray-darker:** `#111928` — Deep background layer or shadow color

### CSS Variable Tokens

```css
--color-background-green-lighter: #e5fff5;
--color-background-orange-lighter: #fff3e8;
--color-background-purple-lighter: #f0e5ff;
--color-background-blue-lighter: #e5f9ff;
--color-primary: #0a7594;
--color-primary-dark: #0c3845;
--color-primary-dark-new: #0e556a;
--color-primary-foreground: white;
--color-primary-background-pale: #effafa;
--color-primary-background-hover: #0a7594e6;
--color-secondary-background: #f4f4f4;
--color-secondary-background-hover: #f4f4f4cc;
--color-gray-primary: #111928;
--color-gray-secondary: #687280;
--color-border: #e4e4e7;
--color-card: #fff;
--color-secondary: #0e556a;
--primary: #0a7594;
--color-background: white;
--color-background-warm: #f9f6f4;
```

## Typography

### Font Stack

- **Aeonik** — Heading 1, Heading 2, Heading 3
- **Graphik** — Body, Caption
- **SFMono-Regular** — Code

### Font Sources

```css
@font-face {
  font-family: "Graphik";
  src: url("fonts/Graphik-Regular.woff2") format("woff2");
  font-weight: 400;
}
@font-face {
  font-family: "Graphik";
  src: url("fonts/Graphik-700.woff2") format("woff2");
  font-weight: 700;
}
@font-face {
  font-family: "Aeonik";
  src: url("fonts/Aeonik-Regular.woff2") format("woff2");
  font-weight: 400;
}
@font-face {
  font-family: "Aeonik";
  src: url("fonts/Aeonik-700.woff2") format("woff2");
  font-weight: 700;
}
```

### Type Scale

| Role | Family | Size | Weight |
|------|--------|------|--------|
| Heading 1 | Aeonik | 125px | 700 |
| Heading 2 | Aeonik | 110px | 700 |
| Heading 3 | Aeonik | 82px | 700 |
| Body | Graphik | 16px | 400 |
| Caption | Graphik | 18px | 400 |
| Code | SFMono-Regular | 14px | 400 |

### Typography Rules

- Body/UI: **Aeonik**, Headings: **Graphik** — these are the only display fonts
- Max 3-4 font sizes per screen
- Headings: weight 600-700, body: weight 400
- Use color and opacity for text hierarchy, not additional font sizes
- Line height: 1.5 for body, 1.2 for headings

## Spacing & Layout

### Base Grid: 4px

Every dimension (margin, padding, gap, width, height) must be a multiple of **4px**.

### Spacing Scale

`2, 4, 6, 8, 10, 14, 16, 18, 20, 22, 24, 26` px

### Spacing as Meaning

| Spacing | Use |
|---------|-----|
| 4-8px | Tight: related items (icon + label, avatar + name) |
| 12-16px | Medium: between groups within a section |
| 24-32px | Wide: between distinct sections |
| 48px+ | Vast: major page section breaks |

### Border Radius

Scale: `.25rem, 2px, 5px, 10px, 10.5px, 16px, 18px, 20px, 22px, 30px, 40px, 48px, 60px, 100%`
Default: `20px`

### Container

Max-width: `1037px`, centered with auto margins.

### Breakpoints

| Name | Value |
|------|-------|
| sm | 40rem |
| md | 48rem |
| lg | 61rem |
| xl | 80rem |
| 2xl | 96rem |
| lg | 850px |

Mobile-first: design for small screens, layer on responsive overrides.

## Component Patterns

### Card

```css
.card {
  background: #fff3e8;
  border-radius: 20px;
  padding: 16px;
  box-shadow: 0 0 8px #00000038;
}
```

```html
<div class="card">
  <h3>Card Title</h3>
  <p>Card content goes here.</p>
</div>
```

### Button

```css
/* Primary */
.btn-primary {
  background: #ff7700;
  color: #000000;
  border-radius: 20px;
  padding: 8px 16px;
  font-weight: 500;
  transition: opacity 150ms ease;
}
.btn-primary:hover { opacity: 0.9; }

/* Ghost */
.btn-ghost {
  background: transparent;
  border: 1px solid #cccccc;
  color: #000000;
  border-radius: 20px;
  padding: 8px 16px;
}
```

```html
<button class="btn-primary">Get Started</button>
<button class="btn-ghost">Learn More</button>
```

### Input

```css
.input {
  background: #f9f9f5;
  border: 1px solid #cccccc;
  border-radius: 20px;
  padding: 8px 10px;
  color: #000000;
  font-size: 14px;
}
.input:focus { border-color: #ff7700; outline: none; }
```

```html
<input class="input" type="text" placeholder="Search..." />
```

### Badge / Chip

```css
.badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 8px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 500;
  background: #fff3e8;
  color: #a6a6a6;
}
```

```html
<span class="badge">New</span>
<span class="badge">Beta</span>
```

### Modal / Dialog

```css
.modal-backdrop { background: rgba(0, 0, 0, 0.6); }
.modal {
  background: #fff3e8;
  border-radius: 100%;
  padding: 24px;
  max-width: 480px;
  width: 90vw;
  box-shadow: 0 0 40px #9993,0 0 20px #66666640,0 0 60px #6666661a;
}
```

```html
<div class="modal-backdrop">
  <div class="modal">
    <h2>Dialog Title</h2>
    <p>Dialog content.</p>
    <button class="btn-primary">Confirm</button>
    <button class="btn-ghost">Cancel</button>
  </div>
</div>
```

### Table

```css
.table { width: 100%; border-collapse: collapse; }
.table th {
  text-align: left;
  padding: 8px 10px;
  font-weight: 500;
  font-size: 12px;
  color: #a6a6a6;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 1px solid #cccccc;
}
.table td {
  padding: 10px;
  border-bottom: 1px solid #cccccc;
}
```

```html
<table class="table">
  <thead><tr><th>Name</th><th>Status</th><th>Date</th></tr></thead>
  <tbody>
    <tr><td>Item One</td><td>Active</td><td>Jan 1</td></tr>
    <tr><td>Item Two</td><td>Pending</td><td>Jan 2</td></tr>
  </tbody>
</table>
```

### Navigation

```css
.nav {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
}
.nav-link {
  color: #a6a6a6;
  padding: 8px 10px;
  border-radius: 20px;
  transition: color 150ms;
}
.nav-link:hover { color: #000000; }
.nav-link.active { color: #ff7700; }
```

```html
<nav class="nav">
  <a href="/" class="nav-link active">Home</a>
  <a href="/about" class="nav-link">About</a>
  <a href="/pricing" class="nav-link">Pricing</a>
  <button class="btn-primary" style="margin-left: auto">Get Started</button>
</nav>
```

### Extracted Components

These components were found in the codebase:

**Button** (`html`)

**Card** (`html`)
- Variants: `light`

**Navigation** (`html`)

**Badge** (`html`)

## Page Structure

The following page sections were detected:

- **Navigation** — Top navigation bar (29 items)
- **Hero** — Hero section (detected from heading structure)
- **Faq** — FAQ/accordion section
- **Footer** — Page footer with links and info (17 items)
- **Cards** — Grid of 8 card elements (8 items)

When building pages, follow this section order and structure.

## Animation & Motion

This project uses **expressive motion**. Animations are part of the design language.

### CSS Animations

- `reveal-in`
- `spin`
- `pulse`
- `fade-in`
- `fade-up`

### Motion Tokens

- **Duration scale:** `.1s`, `.15s`, `.2s`, `.3s`, `.4s`, `.5s`, `.6s`, `.7s`, `.75s`, `100ms`, `200ms`, `600ms`
- **Easing functions:** `cubic-bezier(.19,1,.22,1)`, `cubic-bezier(.77,0,.175,1)`, `cubic-bezier(.165,.84,.44,1)`, `cubic-bezier(.215,.61,.355,1)`, `ease`
- **Animated properties:** `transform`

### Motion Guidelines

- **Duration:** Use values from the duration scale above. Short (.1s) for micro-interactions, long (600ms) for page transitions
- **Easing:** Use `cubic-bezier(.19,1,.22,1)` as the default easing curve
- **Direction:** Elements enter from bottom/right, exit to top/left
- **Reduced motion:** Always respect `prefers-reduced-motion` — disable animations when set

## Depth & Elevation

### Shadow Tokens

- Subtle: `inset 0 2px 2px #ffffff80,inset 0-2px 2px #00000014`
- Subtle: `0 0 0 2px var(--color-gray-lighter)`
- Raised (cards, buttons): `0 0 8px #00000038`
- Raised (cards, buttons): `var(--shadow-badge)`
- Overlay (modals, dialogs): `0 0 40px #9993,0 0 20px #66666640,0 0 60px #6666661a`

### Z-Index Scale

`0, 1, 2, 10, 20, 30, 40, 50, 101, 102`

Use these exact values — never invent z-index values.

## Anti-Patterns (Never Do)

- **No blur effects** — no backdrop-blur, no filter: blur()
- **No zebra striping** — tables and lists use borders for separation
- **No invented colors** — every hex value must come from the palette above
- **No arbitrary spacing** — every dimension is a multiple of 4px
- **No extra fonts** — only Aeonik and Graphik and SFMono-Regular are allowed
- **No arbitrary border-radius** — use the scale: .25rem, 2px, 5px, 10px, 10.5px, 16px, 18px, 20px, 22px, 30px
- **No opacity for disabled states** — use muted colors instead
- **No pill shapes** — this design doesn't use rounded-full / 9999px radius

## Workflow

1. **Read** `references/DESIGN.md` before writing any UI code
2. **Pick colors** from the Color System section — never invent new ones
3. **Set typography** — Aeonik, Graphik, SFMono-Regular only, using the type scale
4. **Build layout** on the 4px grid — check every margin, padding, gap
5. **Match components** to patterns above before creating new ones
6. **Apply elevation** — use shadow tokens
7. **Validate** — every value traces back to a design token. No magic numbers.

## Brand Spec

- **Favicon:** `./favicon.png`
- **Site URL:** `https://supp.co/`
- **Brand color:** `#ff7700`
- **Brand typeface:** Aeonik

## Quick Reference

```
Background:     #f9f9f5
Surface:        #fff3e8
Text:           #000000 / #a6a6a6
Accent:         #ff7700
Border:         (not extracted)
Font:           Aeonik
Spacing:        4px grid
Radius:         20px
Components:     8 detected
```

## When to Trigger

Activate this skill when:
- Creating new components, pages, or visual elements for suppco
- Writing CSS, Tailwind classes, styled-components, or inline styles
- Building page layouts, templates, or responsive designs
- Reviewing UI code for design consistency
- The user mentions "suppco" design, style, UI, or theme
- Generating mockups, wireframes, or visual prototypes

---

# Full Reference Files

> Every output file is embedded below. Claude has full design system context from /skills alone.

## Design System Tokens (DESIGN.md)

# suppco DESIGN.md

> Auto-generated design system — reverse-engineered via static analysis by skillui.
> Frameworks: None detected
> Colors: 20 · Fonts: 3 · Components: 8
> Icon library: not detected · State: not detected
> Primary theme: light · Dark mode toggle: no · Motion: expressive

## Visual Reference

**Match this design exactly** — study colors, fonts, spacing, and component shapes before writing any UI code.

![suppco Homepage](../screenshots/homepage.png)

---

## 1. Visual Theme & Atmosphere

This is a **light-themed** interface with a warm, approachable feel. The light background emphasizes content clarity. Typography pairs **Graphik** for display/headings with **Aeonik** for body text, creating clear visual hierarchy through type contrast. Spacing follows a **4px base grid** (compact density), with scale: 2, 4, 6, 8, 10, 14, 16, 18px. The accent color **#ff7700** anchors interactive elements (buttons, links, focus rings). Motion is expressive — spring physics, layout animations, and staggered reveals are part of the visual language.

---

## 2. Color Palette & Roles

| Token | Hex | Role | Use |
|---|---|---|---|
| color-seasalt | `#f9f9f5` | background | Page background, darkest surface |
| color-background-orange-lighter | `#fff3e8` | surface | Card and panel backgrounds |
| color-black | `#000000` | text-primary | Headings and body text |
| color-gray-light | `#a6a6a6` | text-muted | Captions, placeholders, secondary info |
| color-warn | `#ff7700` | accent | CTAs, links, focus rings, active states |
| color-red-600 | `#e02424` | danger | Error states, destructive actions |
| color-green | `#29a878` | success | Success states, positive indicators |
| color-yellow-300 | `#faca15` | warning | Warning states, caution indicators |
| color-teal | `#0a7594` | info | Informational highlights |
| color-teal-wash | `#e4f9ff` | unknown | Palette color |
| color-gray | `#687280` | unknown | Palette color |
| color-gray-lighter | `#e8ddf4` | unknown | Palette color |
| color-blue-darker | `#0e556a` | unknown | Palette color |
| unknown | `#666666` | unknown | Palette color |
| color-green-darker | `#1d7554` | unknown | Palette color |
| color-gray-darker | `#111928` | unknown | Palette color |
| color-grape-ultradark | `#34345a` | unknown | Palette color |
| color-blue | `#25709a` | unknown | Palette color |
| color-red | `#ff453a` | unknown | Palette color |
| color-purple-400 | `#ac94fa` | unknown | Palette color |

### CSS Variable Tokens

```css
--tw-border-style: solid;
--color-background-green-lighter: #e5fff5;
--color-background-orange-lighter: #fff3e8;
--color-background-purple-lighter: #f0e5ff;
--color-background-blue-lighter: #e5f9ff;
--color-primary: #0a7594;
--color-primary-dark: #0c3845;
--color-primary-dark-new: #0e556a;
--color-primary-foreground: white;
--color-primary-background-pale: #effafa;
--color-primary-background-hover: #0a7594e6;
--color-secondary-background: #f4f4f4;
--color-secondary-background-hover: #f4f4f4cc;
--color-gray-primary: #111928;
--color-gray-secondary: #687280;
--color-border: #e4e4e7;
--color-card: #fff;
--color-secondary: #0e556a;
--primary: #0a7594;
--color-background: white;
```


---

## 3. Typography Rules

**Font Stack:**
- **Aeonik** — Heading 1, Heading 2, Heading 3
- **Graphik** — Body, Caption
- **SFMono-Regular** — Code

**Font Sources:**

```css
@font-face {
  font-family: "Graphik";
  src: url("fonts/Graphik-Regular.woff2") format("woff2");
  font-weight: 400;
}
@font-face {
  font-family: "Graphik";
  src: url("fonts/Graphik-700.woff2") format("woff2");
  font-weight: 700;
}
@font-face {
  font-family: "Aeonik";
  src: url("fonts/Aeonik-Regular.woff2") format("woff2");
  font-weight: 400;
}
@font-face {
  font-family: "Aeonik";
  src: url("fonts/Aeonik-700.woff2") format("woff2");
  font-weight: 700;
}
```

| Role | Font | Size | Weight |
|---|---|---|---|
| Heading 1 | Aeonik | 125px | 700 |
| Heading 2 | Aeonik | 110px | 700 |
| Heading 3 | Aeonik | 82px | 700 |
| Body | Graphik | 16px | 400 |
| Caption | Graphik | 18px | 400 |
| Code | SFMono-Regular | 14px | 400 |

**Typographic Rules:**
- Limit to 3 font families max per screen
- Use **Aeonik** for body/UI text, **Graphik** for display/headings
- Maintain consistent hierarchy: no more than 3-4 font sizes per screen
- Headings use bold (600-700), body uses regular (400)
- Line height: 1.5 for body text, 1.2 for headings
- Use color and opacity for secondary hierarchy, not additional font sizes


---

## 4. Component Stylings

### Layout (1)

**Footer** — `html`

### Navigation (1)

**Navigation** — `html`

### Data Display (2)

**Card** — `html`
- Variants: `light`

**Badge** — `html`

### Data Input (2)

**Button** — `html`

**Input** — `html`
- State: :focus, :placeholder

### Media (2)

**Image** — `html`

**Icon** — `html`



---

## 5. Layout Principles

- **Base spacing unit:** 4px
- **Spacing scale:** 2, 4, 6, 8, 10, 14, 16, 18, 20, 22, 24, 26
- **Border radius:** .25rem, 2px, 5px, 10px, 10.5px, 16px, 18px, 20px, 22px, 30px, 40px, 48px, 60px, 100%
- **Max content width:** 1037px

**Spacing as Meaning:**
| Spacing | Use |
|---|---|
| 4-8px | Tight: related items within a group |
| 12-16px | Medium: between groups |
| 24-32px | Wide: between sections |
| 48px+ | Vast: major section breaks |


---

## 6. Depth & Elevation

### Flat — subtle depth hints

- `inset 0 2px 2px #ffffff80,inset 0-2px 2px #00000014`
- `0 0 0 2px var(--color-gray-lighter)`

### Raised — cards, buttons, interactive elements

- `0 0 8px #00000038`
- `var(--shadow-badge)`

### Overlay — full-screen overlays, top-level dialogs

- `0 0 40px #9993,0 0 20px #66666640,0 0 60px #6666661a`

### Z-Index Scale

`0, 1, 2, 10, 20, 30, 40, 50, 101, 102`



---

## 7. Animation & Motion

This project uses **expressive motion**. Animations are an integral part of the experience.

### CSS Animations

- `@keyframes reveal-in`
- `@keyframes spin`
- `@keyframes pulse`
- `@keyframes fade-in`
- `@keyframes fade-up`
- `@keyframes rotate-wobble`
- `@keyframes svelte-lj3zw6-scroll`

### Motion Guidelines

- Duration: 150-300ms for micro-interactions, 300-500ms for page transitions
- Easing: `ease-out` for enters, `ease-in` for exits
- Always respect `prefers-reduced-motion`


---

## 8. Do's and Don'ts

### Do's

- Use `#ff7700` for interactive elements (buttons, links, focus rings)
- Use `#f9f9f5` as the primary page background
- Pair **Aeonik** (body) with **Graphik** (display) — these are the only allowed fonts
- Follow the **4px** spacing grid for all margins, padding, and gaps
- Use the defined shadow tokens for elevation — see Section 6
- Use border-radius from the scale: .25rem, 2px, 5px, 10px, 10.5px
- Reuse existing components from Section 4 before creating new ones

### Don'ts

- Don't introduce colors outside this palette — extend the design tokens first
- Don't introduce additional font families beyond Aeonik and Graphik and SFMono-Regular
- Don't use arbitrary spacing values — stick to multiples of 4px
- Don't create custom box-shadow values outside the system tokens
- Don't use arbitrary border-radius values — pick from the defined scale
- Don't duplicate component patterns — check Section 4 first
- Don't use backdrop-blur or blur effects

### Anti-Patterns (detected from codebase)

- No blur or backdrop-blur effects
- No zebra striping on tables/lists


---

## 9. Responsive Behavior

| Name | Value | Source |
|---|---|---|
| sm | 40rem | css |
| md | 48rem | css |
| lg | 61rem | css |
| xl | 80rem | css |
| 2xl | 96rem | css |
| lg | 850px | css |

**Approach:** Use `@media (min-width: ...)` queries matching the breakpoints above.


---

## 10. Agent Prompt Guide

Use these as starting points when building new UI:

### Build a Card

```
Background: #fff3e8
Border: 1px solid var(--border)
Radius: 20px
Padding: 16px
Font: Aeonik
Use shadow tokens from Section 6.
```

### Build a Button

```
Primary: bg #ff7700, text white
Ghost: bg transparent, border var(--border)
Padding: 8px 16px
Radius: 20px
Hover: opacity 0.9 or lighter shade
Focus: ring with #ff7700
```

### Build a Page Layout

```
Background: #f9f9f5
Max-width: 1037px, centered
Grid: 4px base
Responsive: mobile-first, breakpoints from Section 9
```

### Build a Stats Card

```
Surface: #fff3e8
Label: #a6a6a6 (muted, 12px, uppercase)
Value: #000000 (primary, 24-32px, bold)
Status: use success/warning/danger from Section 2
```

### Build a Form

```
Input bg: #f9f9f5
Input border: 1px solid var(--border)
Focus: border-color #ff7700
Label: #a6a6a6 12px
Spacing: 16px between fields
Radius: 20px
```

### General Component

```
1. Read DESIGN.md Sections 2-6 for tokens
2. Colors: only from palette
3. Font: Aeonik, type scale from Section 3
4. Spacing: 4px grid
5. Components: match patterns from Section 4
6. Elevation: shadow tokens
```

## Bundled Fonts (fonts/)

The following font files are bundled in the `fonts/` directory:

- `fonts/Aeonik-500.woff2`
- `fonts/Aeonik-600.woff2`
- `fonts/Aeonik-700.woff2`
- `fonts/Aeonik-Regular.woff2`
- `fonts/Graphik-500.woff2`
- `fonts/Graphik-600.woff2`
- `fonts/Graphik-700.woff2`
- `fonts/Graphik-Regular.woff2`

Use these local font files in `@font-face` declarations instead of fetching from Google Fonts.

## Homepage Screenshots (screenshots/)

![homepage.png](screenshots/homepage.png)

