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
  src: url("https://supp.co/fonts/Graphik-Regular-Web.woff2") format("woff2");
  font-weight: 400;
}
@font-face {
  font-family: "Graphik";
  src: url("https://supp.co/fonts/Graphik-Bold-Web.woff2") format("woff2");
  font-weight: 700;
}
@font-face {
  font-family: "Aeonik";
  src: url("https://supp.co/fonts/Aeonik-Regular.woff2") format("woff2");
  font-weight: 400;
}
@font-face {
  font-family: "Aeonik";
  src: url("https://supp.co/fonts/Aeonik-Bold.woff2") format("woff2");
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
