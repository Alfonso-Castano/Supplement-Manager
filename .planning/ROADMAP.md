# Roadmap — StackWise

**Project:** StackWise iOS App  
**Core value:** Trustworthy supplement/medication interaction analysis with smart scheduling  
**v1 target:** Local SQLite interaction database + iOS app (Phase 0 → Phase 9)

---

## v1.0 MVP — Phases 0–9

- [x] **Phase 0: Database Build** — Self-built supplement/medication interaction database (pre-app) — COMPLETE; ships as `database/stackwise.sqlite` (63 interactions, 70 ingredients)
- [x] **Phase 1: Project Foundation** — Xcode setup, Core Data schema, three-tab navigation shell — COMPLETE
- [x] **Phase 2: Stack & User Setup** — Health profile entry, add item flow with auto-suggestion — COMPLETE (driven from `~/.claude/plans/stackwise-phase-2-lovely-bachman.md`; no `.planning/phases/02-*` dir was created during execution. Carry-forward nits tracked in `.claude/PHASE-3-HANDOFF.md` and folded into Phase 3 where they touch the same files.)
- [x] **Phase 3: Interaction Analysis Engine** — Bundle database, pairwise lookup, analysis screen — COMPLETE (36 tests passing, Mac verified 2026-05-15)
- [x] **Phase 4: Smart Schedule** — Priority-rule scheduling algorithm, schedule tab with blocks — COMPLETE (50 tests passing, Mac verified 2026-05-24, deep review fixes verified)
- [ ] **Phase 5: Functional Onboarding** — Onboarding coordinator, preview screen, trial trigger
- [ ] **Phase 6: Reminders & Today Tab** — Local notifications, block-level check-off interface
- [ ] **Phase 7: Monetization** — StoreKit 2, 14-day trial, hard paywall, restore purchases
- [ ] **Phase 8: In-App Feedback** — Formspree integration, feedback entry points, local retry
- [ ] **Phase 9: Polish & Ship** — Dark mode, branding, privacy policy, App Store submission

---

## Phase Detail

### Phase 0: Database Build

**Goal**: Build a self-built supplement/medication interaction database (`stackwise.sqlite`) covering 50 supplements + 20 medications before any iOS app code begins. The database is the first deliverable — Phase 3 cannot be implemented without it.

**Depends on**: None

**Requirements**: REQ-01, REQ-02, REQ-03, REQ-04, REQ-05

**Plans:** 4 plans

Plans:
- [x] 00-01-PLAN.md — Stage 0: Pre-flight (target list, canonical_names, action_templates, utils, test scaffolding, D-04 approval gate) — COMPLETE 2026-05-05
- [x] 00-02-PLAN.md — Stage 1: Collection (NIH ODS + MedlinePlus + MSK + OpenFDA raw files) — COMPLETE
- [x] 00-03-PLAN.md — Stage 2: Extraction to interactions.json with canonical resolution + timing_properties — COMPLETE
- [x] 00-04-PLAN.md — Stage 3: Gap analysis, PubMed gap-filling, SQLite compilation, final spot-check — COMPLETE

**Success Criteria:**
1. `stackwise.sqlite` exists with `interactions`, `ingredients`, and `metadata` tables; no schema errors on open
2. All 50 target supplements have ≥1 medium+ confidence interaction record in `interactions` table
3. All 20 target medications have ≥1 medium+ confidence interaction record in `interactions` table
4. `gap_report.md` exists, confirms hard floor met for every target compound, lists remaining gaps with recommended sources
5. Human spot-check: 10 randomly selected records reviewed manually for accuracy of `effect`, `suggested_action`, and `citations`

**Output artifacts:**
```
research/
  raw/
    nih_ods/          ← one .txt per NIH ODS fact sheet
    medlineplus/      ← one .txt per MedlinePlus herb entry
    msk/              ← one .txt per MSK herb page
    openfda/          ← JSON API response files
    pubmed/           ← abstract .txt files
  target_list.json   ← 50 supplements + 20 medications (approved scope anchor)
  canonical_names.json
  action_templates.json
  interactions.json
  gap_report.md
database/
  stackwise.sqlite   ← written only after Phase 0 is fully complete and spot-checked
```

**Key schema decisions (locked in CONTEXT.md):**
- Single combined `stackwise.sqlite` (interactions + ingredients + metadata tables)
- `conflict_note` TEXT column on `interactions` (when severity conflicts exist across sources)
- `timing_properties` JSON blob TEXT column on `ingredients` (required_food, requires_empty_stomach, preferred_time_of_day, avoid_with_caffeine)
- `metadata` table: one row, `db_version` TEXT + `date_built` TEXT
- Minimum confidence for production records: **medium and above**
- Hard floor: every target compound must have ≥1 medium+ record

**Execution model:** 3 stages with human gate at each boundary (hybrid automated + manual spot-check). Checkpoint-based multi-session architecture — each stage writes to disk, next stage reads from files.

---

### Phase 1: Project Foundation

**Goal:** Establish the Xcode project with the correct bundle ID, Core Data schema, three-tab navigation shell, and basic app icon so all subsequent phases have a working skeleton to build on.

**Depends on:** Phase 0

**Requirements:** REQ-06, REQ-07, REQ-08

**Success Criteria:**
1. Xcode project named StackWise with bundle ID `com.stackwise.app` builds without errors
2. Core Data schema includes all 5 entities: UserProfile, StackItem, ScheduledDose, DailyCheckOff, FeedbackItem
3. Three-tab navigation shell (Stack / Today / Schedule) renders and navigates without crashes
4. App icon and launch screen appear on device/simulator

**Plans:** 3 plans

Plans:
- [x] 01-01-PLAN.md — Xcode project creation (GUI), bundle ID, deployment target, XCTest target verification — COMPLETE
- [x] 01-02-PLAN.md — Core Data schema (5 entities), NSManagedObject subclasses, PersistenceController, CoreDataSchemaTests — COMPLETE
- [x] 01-03-PLAN.md — AppState (@Observable), ContentView (TabView + NavigationStack), placeholder tab views, icon, launch screen — COMPLETE

---

### Phase 2: Stack & User Setup

**Goal:** Allow users to enter their health profile, set schedule inputs, and add supplement/medication items with active ingredient auto-suggestion from the database.

**Depends on:** Phase 1

**Requirements:** REQ-09, REQ-10, REQ-11

**Success Criteria:**
1. Health profile screen collects age, sex, weight, allergies, conditions and persists to Core Data UserProfile
2. Schedule inputs (wake, sleep, meal times) save to UserProfile
3. Add item flow: label entry → auto-suggestion from `ingredients.canonical_name` / aliases → user confirms or overrides
4. Items where active ingredient not found are added with `isInDatabase = false` and visually flagged
5. Stack list displays all items; edit and delete work correctly

---

### Phase 3: Interaction Analysis Engine

**Goal:** Bundle the Phase 0 database as a local read-only asset, implement the pairwise lookup engine, severity classification, and the full analysis screen.

**Depends on:** Phase 2

**Requirements:** REQ-12, REQ-13, REQ-14, REQ-15

**Success Criteria:**
1. `stackwise.sqlite` bundled as app asset; opens read-only at launch — **already satisfied in Phase 2 via `IngredientRepository`**; Phase 3 adds `InteractionRepository` against the same bundled file.
2. Pairwise lookup returns all flagged pairs for a given stack.
3. Severity classification returns advisory / critical correctly per database records.
4. Analysis screen groups results: critical → advisory → positive insights → not-in-database.
5. Inline badges on stack item cards reflect current analysis state.

**Plans:** 4 plans

Plans:
- [x] 03-01-PLAN.md — `InteractionRepository` (read-only SQLite layer for `interactions` table) + tests + `StackWiseApp` injection + carry-forward `sqlite3_close_v2` fix — COMPLETE
- [x] 03-02-PLAN.md — `AnalysisEngine` (pure, pairwise) + `AnalysisStore` (`@Observable`, dirty-flag cache) + tests + invalidation hook in `StackItemFactory` — COMPLETE
- [x] 03-03-PLAN.md — `AnalysisView` UI (critical → advisory → synergy → not-in-database) + push from `StackListView` toolbar — COMPLETE
- [x] 03-04-PLAN.md — Inline badges on `StackListView` rows reflecting current analysis state — COMPLETE

**Mac verification:** 36 tests passing, simulator golden path confirmed 2026-05-15.

---

### Phase 4: Smart Schedule

**Goal:** Implement the 5-rule priority scheduling algorithm and schedule tab showing Morning / Afternoon / Evening blocks.

**Depends on:** Phase 3

**Requirements:** REQ-16, REQ-17

**Plans:** 4 plans

Plans:
- [x] 04-01-PLAN.md — `TimingProperties` struct + `IngredientRepository.timingProperties(for:)` + `ScheduleStore` skeleton + `StackWiseApp` injection — COMPLETE
- [x] 04-02-PLAN.md — `ScheduleEngine` (pure 4-rule algorithm) + `ScheduleResult` / `ScheduledItem` types + `ScheduleStore.recompute()` + tests (7 engine + 4 store) — COMPLETE
- [x] 04-03-PLAN.md — `ScheduleView` UI (3 `List` sections, time window headers, conflict/synergy row badges) — COMPLETE
- [x] 04-04-PLAN.md — Wire `ScheduleStore.invalidate()` into `AddItemView` + `ScheduledDose` Core Data writes verified + Mac batch (build + ≥48 tests + simulator golden path) — COMPLETE (code; Mac verification pending)

**Success Criteria:**
1. Prescriptions always placed first; never moved for supplement conflicts
2. Timing-conflict pairs separated by ≥ `timing_window_hours` using user's actual meal/wake times
3. `timing_properties` (requires_food, requires_empty_stomach, preferred_time_of_day) applied correctly
4. Unconstrained items default to morning; overflow rule applied at 5-item block limit
5. Schedule tab renders all 3 blocks with items, time windows, and conflict/positive flags

---

### Phase 5: Functional Onboarding

**Goal:** Sequence existing screens into a working onboarding flow and wire the trial start trigger.

**Depends on:** Phase 4

**Requirements:** REQ-18, REQ-19

**Success Criteria:**
1. Onboarding coordinator sequences health profile → stack entry → schedule inputs → preview screen
2. Preview screen shows analysis results and schedule before trial starts
3. Trial start trigger fires at onboarding completion; writes `trialStartDate` to UserProfile
4. Main app tabs hidden until onboarding complete flag set

**Plans:** 5 plans

Plans:

**Wave 0**
- [x] 05-00-PLAN.md — Wave 0: OnboardingCoordinatorTests.swift stubs (REQ-18, REQ-19 — RED until Wave 3) — COMPLETE 2026-05-25

**Wave 1** *(blocked on Wave 0 completion)*
- [x] 05-01-PLAN.md — HealthProfileView surgery (remove schedule section + markOnboarded) + ContentView coordinator gate — COMPLETE 2026-05-25

**Wave 2** *(blocked on Wave 1 completion — plans 02 and 03 run in parallel)*
- [ ] 05-02-PLAN.md — ScheduleInputsView (step 3, time fields only) + StackEntryStepView (step 2, item gate)
- [ ] 05-03-PLAN.md — OnboardingPreviewView (summary card, force-recompute) + PaywallPlaceholderView (4 zones)

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 05-04-PLAN.md — OnboardingCoordinatorView (full coordinator, smart resume) + fill stubs GREEN + simulator checkpoint

Cross-cutting constraints:
- `@Observable` + `.environment()` only — no `ObservableObject`/`@Published` (Phase 1 lock, all plans)
- `UserProfileStore.fetchOrCreate` is the only valid UserProfile writer — no `UserProfile(context:)` direct init

---

### Phase 6: Reminders & Today Tab

**Goal:** Schedule local notifications per the generated schedule and build the Today tab block-level check-off UI.

**Depends on:** Phase 5

**Requirements:** REQ-20, REQ-21

**Success Criteria:**
1. Local notifications scheduled for each time block; body lists specific items by label
2. Tapping notification opens Today tab
3. Today tab shows morning / afternoon / evening rows with items and check-off state
4. Mark-complete persists to Core Data DailyCheckOff; UI updates immediately

---

### Phase 7: Monetization

**Goal:** Implement StoreKit 2 subscription, trial expiry check, and hard paywall.

**Depends on:** Phase 6

**Requirements:** REQ-22, REQ-23, REQ-24

**Success Criteria:**
1. StoreKit 2 products ($4.99/month and $35/year) configured and purchasable in sandbox
2. Trial expiry check on launch compares today vs. trialStartDate + 14 days
3. Hard paywall blocks all app content on trial expiry — no dismiss, no degraded mode
4. Restore purchases flow works correctly in sandbox
5. `subscriptionStatus` in UserProfile updates on launch and on StoreKit transaction events

---

### Phase 8: In-App Feedback

**Goal:** Implement Formspree-backed feedback forms with local retry logic at all three entry points.

**Depends on:** Phase 7

**Requirements:** REQ-25, REQ-26, REQ-27

**Success Criteria:**
1. "Dispute this flag" entry point on each interaction pair; form submits to Formspree
2. "Report a scheduling issue" entry on schedule tab; form submits to Formspree
3. General feedback form accessible from settings
4. Failed submissions stored locally in FeedbackItem (`submitted = false`); retried on next launch
5. NSAppTransportSecurity allows Formspree domain only; no other outbound exceptions

---

### Phase 9: Polish & Ship

**Goal:** Dark mode, visual branding, privacy policy, and App Store submission.

**Depends on:** Phase 8

**Requirements:** REQ-28, REQ-29, REQ-30

**Success Criteria:**
1. Dark mode renders correctly across all screens with no hardcoded light-mode colors
2. Color palette, typography, and icons applied consistently; severity colors reserved for flags
3. Privacy policy published at a public URL; linked from App Store listing and in-app settings
4. App Store metadata complete: description, screenshots, keywords, age rating (12+ or 17+)
5. TestFlight internal build passes; App Store submission accepted

---

---

## v1.1 — Pre-Launch Landing Page

- [x] **Phase 10: Landing Page Foundation** — Astro scaffold, Tailwind design system, shared components (Nav, PhoneMockup, WaitlistForm) — COMPLETE
- [x] **Phase 11: Page Sections** — All 10 sections built (Hero, Credibility, How It Works, 3 Feature Deep-Dives, Trust, Video, Testimonials, Creator Story, Pricing, Final CTA + Footer) — COMPLETE
- [x] **Phase 11.5: Tool Selection** — Review available tools/plugins, decide what Claude will use during polish phases, document in TOOLS.md — COMPLETE
- [x] **Phase 12: Visual Polish** — Desktop layout audit, mobile/responsive pass, animation & interaction polish — COMPLETE
- [ ] **Phase 13: Asset Integration** — Replace phone mockup placeholders with real app screenshots, creator photo, content finalization
- [ ] **Phase 14: Pre-Deploy QA** — Lighthouse audit (≥90 mobile), cross-browser check, final form test
- [ ] **Phase 15: Deploy** — Vercel root directory config, Kit env var, push to main, verify live URL

---

### Phase 10: Landing Page Foundation

**Goal:** Scaffold the Astro project inside `landing/`, configure the full design system (colors, fonts, animations), and build the two shared components used across every section.

**Depends on:** None (independent of iOS app phases)

**Spec:** `STACKWISE_LANDING_PAGE_SPEC.md`

**Plans:** 1 plan

Plans:
- [x] 10-01-PLAN.md — Scaffold Astro + Tailwind, design tokens, Layout.astro, Nav.astro, PhoneMockup.astro, WaitlistForm.astro — COMPLETE

**Success Criteria:**
1. `landing/` Astro project builds without errors (`npm run build`)
2. Design tokens (color palette, fonts) defined in `global.css` via Tailwind v4 `@theme`
3. `Nav.astro` renders sticky header with scroll-triggered background transition
4. `WaitlistForm.astro` submits to Kit API with inline success state
5. `PhoneMockup.astro` renders reusable iPhone placeholder with accent color prop

---

### Phase 11: Page Sections

**Goal:** Build all 10 page sections per `STACKWISE_LANDING_PAGE_SPEC.md` and assemble them in `index.astro`.

**Depends on:** Phase 10

**Plans:** 1 plan

Plans:
- [x] 11-01-PLAN.md — All 10 sections: Hero, CredibilityBar, HowItWorks, 3× FeatureSection, TrustSection, VideoSection, Testimonials, CreatorStory, Pricing, FinalCTA, Footer — COMPLETE

**Success Criteria:**
1. All 10 sections render correctly at desktop breakpoint
2. Scroll-triggered fade-in animations fire correctly via Intersection Observer
3. Hero entrance animation plays on page load
4. Both waitlist forms (hero + final CTA) submit to same Kit form ID 9457828
5. No broken layouts or missing content relative to spec

---

### Phase 11.5: Tool Selection

**Goal:** Before any polish work begins, review available tools and decide what Claude will have access to during Phases 12–14. Output a `TOOLS.md` doc so every future session knows exactly what's available.

**Depends on:** Phase 11

**Plans:** 1 plan

Plans:
- [x] 11.5-01-PLAN.md — User presents tool list, Claude evaluates each, selected tools installed and configured, TOOLS.md written — COMPLETE

**Success Criteria:**
1. `TOOLS.md` exists in `.planning/phases/12-landing-polish/`
2. At minimum, Playwright MCP is installed and verified working against `localhost:4321`
3. Any additional tools are installed and accessible to Claude Code

---

### Phase 12: Visual Polish

**Goal:** Make the site look exactly right before any real assets are swapped in. Desktop layout, mobile responsive behavior, and animation quality.

**Depends on:** Phase 11.5

**Plans:** 3 plans

Plans:
- [x] 12-01-PLAN.md — Desktop layout audit: spacing, typography scale, section rhythm, color consistency — COMPLETE
- [x] 12-02-PLAN.md — Mobile & responsive pass: all breakpoints, touch targets, stacked layouts — COMPLETE
- [x] 12-03-PLAN.md — Animation & interaction polish: scroll triggers, hero entrance, nav transition, hover states — COMPLETE

**Success Criteria:**
1. All sections have consistent spacing and visual rhythm at 1440px desktop
2. Page renders correctly at 375px (iPhone SE), 390px (iPhone 14), and 768px (tablet)
3. All touch targets ≥44px height on mobile
4. Scroll-triggered animations fire correctly and feel smooth
5. Nav background transition and button hover states work as designed

---

### Phase 13: Asset Integration

**Goal:** Replace every placeholder element with real assets once the app GUI design is finalized.

**Depends on:** Phase 12

**Plans:** 3 plans

Plans:
- [ ] 13-01-PLAN.md — App screenshots: replace all `PhoneMockup.astro` placeholders with actual iPhone screenshots (one per section)
- [ ] 13-02-PLAN.md — Creator assets: real photo in `CreatorStory.astro`, finalize personal copy
- [ ] 13-03-PLAN.md — Content finalization: real testimonials, video embed when ready, social links, update `siteUrl` in `Layout.astro`

**Success Criteria:**
1. No `PhoneMockup.astro` placeholder components remain — all replaced with real `<img>` elements
2. Creator photo shows correctly in circular crop
3. All testimonial quotes are real (not placeholder text)
4. Footer social links are real URLs or removed entirely

---

### Phase 14: Pre-Deploy QA

**Goal:** Verify the fully-polished, asset-complete site meets the quality bar before going live.

**Depends on:** Phase 13

**Plans:** 1 plan

Plans:
- [ ] 14-01-PLAN.md — Lighthouse audit (≥90 performance on mobile), Chrome + Safari + Safari iOS, form submission end-to-end test

**Success Criteria:**
1. Lighthouse performance score ≥90 on mobile (tested via Chrome DevTools)
2. Page renders correctly in Chrome, Safari desktop, and Safari iOS
3. Waitlist form submits successfully and confirmation email is received
4. No console errors on page load

---

### Phase 15: Deploy

**Goal:** Push the finished site live on Vercel.

**Depends on:** Phase 14

**Plans:** 1 plan

Plans:
- [ ] 15-01-PLAN.md — Vercel Root Directory → `landing/`, `PUBLIC_KIT_API_KEY` env var, push to `main`, verify live URL, update `siteUrl`

**Success Criteria:**
1. Vercel project Root Directory set to `landing/`
2. `PUBLIC_KIT_API_KEY` added to Vercel environment variables (not hardcoded)
3. Live Vercel URL loads and all sections render correctly
4. Waitlist form submission works on live URL
5. All files committed to `main` branch

---

## Progress

**v1.0 iOS App**

| Phase | Status | Plans | Completed |
|-------|--------|-------|-----------|
| 0 | Complete | 4/4 | 00-01, 00-02, 00-03, 00-04 |
| 1 | Complete | 3/3 | 01-01, 01-02, 01-03 |
| 2 | Complete | 4/4 | 02-01, 02-02, 02-03, 02-04 (executed via `~/.claude/plans/stackwise-phase-2-lovely-bachman.md`; no `.planning/phases/02-*` dir) |
| 3 | Complete | 4/4 | 03-01, 03-02, 03-03, 03-04 |
| 4 | In Progress | 4/4 | 04-01, 04-02, 04-03, 04-04 (Mac verification pending) |
| 5 | In Progress | 5/5 plans written | 05-00, 05-01 |
| 6 | Not started | 0/0 | — |
| 7 | Not started | 0/0 | — |
| 8 | Not started | 0/0 | — |
| 9 | Not started | 0/0 | — |

**v1.1 Landing Page**

| Phase | Status | Plans | Completed |
|-------|--------|-------|-----------|
| 10 | Complete | 1/1 | 10-01 |
| 11 | Complete | 1/1 | 11-01 |
| 11.5 | Complete | 1/1 | 11.5-01 |
| 12 | Complete | 3/3 | 12-01, 12-02, 12-03 |
| 13 | Not started | 3/3 plans written | — |
| 14 | Not started | 1/1 plan written | — |
| 15 | Not started | 1/1 plan written | — |
