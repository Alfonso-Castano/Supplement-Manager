# MARKETING_BRIEF.md — StackWise

This document contains only factual information extracted from the project's spec, requirements, and planning documents. It is intended for a downstream agent building the marketing website.

---

## App Identity

- **Name:** StackWise
- **Platform:** iOS (iPhone)
- **Current status:** Pre-launch. In active development (approximately 40% complete as of May 2026). No App Store link exists yet. No TestFlight link exists yet.
- **One-sentence description:** StackWise is an iOS app that analyzes interactions between the supplements and medications a user is already taking, then generates a personalized daily schedule with reminders to optimize timing and safety.

---

## Core Features

### 1. Interaction & Conflict Analysis

What it does: Cross-references every item in the user's supplement/medication stack against every other item (pairwise analysis). Flags supplement-to-supplement and supplement-to-medication conflicts. Analysis runs automatically whenever the stack changes — no manual trigger needed.

How it works:
- Uses a self-built, locally stored interaction database (SQLite) shipped with the app as a read-only asset
- Produces grouped results displayed on a dedicated analysis screen:
  1. **Critical conflicts** — flagged pairs with mechanism explanation, suggested fix, and citation
  2. **Advisory conflicts** — same structure, lower severity
  3. **Positive insights** — well-paired items and optimal timing confirmations (data-backed only)
  4. **Not in database** — items with no interaction data, listed with a caveat and links to external research resources
- Prescription medications are never recommended to be changed; suggested fixes always target the supplement side
- Severity uses two tiers: advisory and critical
- Inline badges appear on stack item cards reflecting analysis state (conflict/positive indicators)
- Citations and mechanism explanations are surfaced where the database supports them

What the user experiences: After entering their supplements and medications, the user sees an automatically updated analysis screen showing which items conflict, which pair well, and which items the app cannot analyze. Each flagged pair includes an explanation of why it matters, what to do about it, and a citation for where the information came from.

### 2. Smart Daily Schedule

What it does: Generates a personalized supplement timing schedule split into three time blocks (Morning / Afternoon / Evening) based on the user's wake time, meal times, and interaction data.

How it works:
- 4-rule priority scheduling algorithm applied in strict order:
  1. Prescriptions placed first (never moved for supplement conflicts)
  2. Timing-conflict pairs separated by required hours
  3. Individual timing properties applied (requires food, requires empty stomach, preferred time of day)
  4. Unconstrained items default to morning; overflow rule at 5 items per block
- Uses the user's actual wake time, breakfast time, lunch time, and dinner time (entered during onboarding) to compute suggested times
- Schedule regenerates automatically on every stack change
- Persisted to Core Data (ScheduledDose records)

What the user experiences: A vertically scrollable list of three time blocks (Morning / Afternoon / Evening), each showing which items to take, a suggested time window, and flags linking to the analysis screen for context. The schedule updates automatically whenever items are added or removed.

### 3. Reminders

What it does: Sends local notifications tied to the generated schedule, then provides a check-off interface on the Today tab.

How it works:
- Local notifications only — no server infrastructure
- Notification body lists specific item names per time block (e.g., "Time for your morning stack — Magnesium, Vitamin D, Fish Oil")
- Tapping the notification opens the Today tab
- Today tab shows morning / afternoon / evening blocks with per-block check-off
- Check-off state persists to Core Data (DailyCheckOff records)

What the user experiences: A notification at each scheduled time block telling them exactly which items to take. Tapping opens the app to a simple check-off screen where they confirm they've taken that block's items.

---

## What the App Does NOT Do

These are explicitly ruled out or deferred per the spec. The marketing site must not claim or imply these:

- **No drug-to-drug interaction analysis.** Only supplement↔supplement and supplement↔medication. Drug↔drug is explicitly out of scope.
- **No free tier.** There is a 14-day free trial only, followed by a hard paywall. There is no permanent free mode and no degraded free experience.
- **No iCloud/cross-device sync.** Explicitly deferred post-launch. All data is on-device only.
- **No streak tracking or adherence history.** Deferred post-launch. The Today tab is a simple daily check-off only.
- **No multi-profile support.** Single user profile only in v1.
- **No AI/LLM-powered analysis.** The interaction database is a static, self-built, locally stored asset. There is no AI generating answers at runtime, no chatbot, no GPT integration.
- **No server-side infrastructure.** All analysis, scheduling, and data storage happen on-device. The only outbound network call is feedback submission (to Formspree), which sends no health data.
- **No prescription recommendations.** The app never suggests changing or stopping a prescription medication. Suggested actions always target the supplement.
- **No additional schedule inputs beyond wake/meal times.** Workout timing, caffeine habits, etc. are deferred post-launch.
- **No third severity tier.** Only advisory and critical in v1.
- **No lock-screen notification actions.** Rich notifications with check-off from lock screen are deferred.

---

## Pricing and Trial

- **Trial:** 14 days, full access to all features
- **Trial start trigger:** Fires once at onboarding completion (after the user has entered their health profile, supplements, and seen their personalized analysis + schedule)
- **What happens when the trial ends:** Hard paywall blocks all app content. No dismiss button. No degraded free mode. The user must subscribe to continue using the app.
- **Subscription pricing:**
  - $4.99/month
  - $35/year
- **Restore purchases:** Available on the paywall screen for users who have already subscribed

---

## Target User

Based on the spec's description of who this is for:

- **Who:** People who are already taking multiple supplements and/or medications. Not people shopping for new supplements — people optimizing what they already take.
- **Problem they have:** They don't know which of their supplements interact with each other or with their medications. They don't know the optimal time of day to take each one. They may be taking items that cancel each other out, reduce absorption, or create safety risks without knowing it.
- **Stage they're at:** They already have a "stack" — multiple supplements and potentially prescription medications. They want to make sure what they're taking is safe and timed correctly. They may have started researching interactions manually and found it overwhelming or unreliable.
- **What they care about:** Safety, optimization of what they already take, trustworthiness of information, clear actionable guidance (not just raw data).

---

## Differentiators

Based on what the spec explicitly states makes this different:

1. **Self-built, locally stored interaction database with citations.** No third-party API dependency. No ongoing licensing costs. Full ownership of the data. Every interaction record includes citations from public medical sources (NIH ODS, PubMed, Memorial Sloan Kettering, MedlinePlus, OpenFDA). The database is not generated by AI at runtime — it was built through a structured research and extraction process from authoritative public medical sources.

2. **On-device only architecture.** All health data stays on the user's device. No cloud accounts, no server-side storage, no health data transmission. The only outbound call is optional feedback submission (which explicitly sends no health data).

3. **Interaction analysis is the core, not an add-on.** The interaction database was the first thing built (before any app code). The scheduling and reminders are downstream of the analysis — they use interaction data to determine timing separation. This is not a reminder app with an interaction feature bolted on.

4. **Automatic, not manual.** Analysis runs on every stack change with no user action required. The schedule regenerates automatically. No "run analysis" button to remember to press.

5. **Honest about limitations.** Items not found in the database are explicitly surfaced with a caveat and external resource links. The app does not pretend to cover everything — it tells the user what it can and cannot analyze.

6. **Prescriptions are respected, not modified.** The app never suggests changing a prescription medication. All suggested actions target the supplement side only.

---

## Technical Credibility Signals

Facts about the data layer that build trust:

- **Database scope:** 50 supplements + 20 commonly prescribed medications. 70 total ingredients. 63 interaction records in the production database.
- **Confidence filtering:** Only medium and high confidence records are included in the production database. Low confidence records (animal studies, theoretical mechanisms, adverse event co-occurrence only) are excluded.
- **Sources used to build the database:**
  - NIH Office of Dietary Supplements (ODS) fact sheets
  - Memorial Sloan Kettering (MSK) About Herbs database
  - MedlinePlus supplement/herb entries
  - OpenFDA adverse event data (used only as a signal for further research, never as sole source)
  - PubMed research abstracts (human clinical trials and observational studies)
- **Citation system:** Every interaction record includes at least one citation URL pointing to the original source. Citations are surfaced to the user in the analysis screen.
- **Human-verified:** The database underwent a manual spot-check of 10 randomly selected records verifying accuracy of effects, suggested actions, and citations before being finalized.
- **Severity conflict resolution:** When sources disagree on severity, the higher-confidence source wins. When confidence is equal, the higher severity wins (erring on the side of user safety). Conflicts are documented internally.
- **Canonical naming:** All compound names follow NIH ODS naming conventions. Prescription medications always use generic names as canonical (brand names are aliases).
- **Structured data, not free-text matching:** The interaction database uses normalized canonical names with bidirectional lookup, not fuzzy text matching.
- **Timing properties:** Individual supplement timing properties (requires food, requires empty stomach, preferred time of day, avoid with caffeine) are captured per ingredient and used by the scheduling algorithm.
- **Update path:** Database updates are gap-report driven, not on a fixed cadence. A gap report documents remaining coverage gaps and recommended next sources.

---

## Launch Context

- **Status:** Pre-launch. The app is in active development.
- **Phase:** Currently in Phase 4 of 10 (Smart Schedule). Phases 0–3 are complete (database, project foundation, stack/user setup, interaction analysis engine).
- **No App Store link exists.** The app has not been submitted to the App Store.
- **No TestFlight link exists.** External testing has not begun.
- **Waitlist:** The spec does not mention a waitlist system. If the marketing site implements a waitlist, that is a marketing decision not specified in the product documentation.
- **Privacy policy:** Will be publicly hosted (likely GitHub Pages) before App Store submission. Will state: all data stored on-device only, never sold or shared, feedback text sent to Formspree (no health data), age rating 12+ or 17+.
- **App Store age rating:** Expected 12+ or 17+ (determined during App Store Connect submission based on medical content characterization).

---

## Supplement Categories Covered

The 50 supplements in the database span these categories:
- Vitamins (D3, C, A, E, K2, B6, B12, B-complex, biotin, folic acid, niacin/B3)
- Minerals (magnesium, zinc, iron, calcium, selenium, copper, potassium, iodine, chromium)
- Botanicals (ashwagandha, turmeric/curcumin, green tea extract, berberine, ginkgo biloba, St. John's wort, milk thistle, valerian, black cohosh, echinacea, garlic, saw palmetto, rhodiola rosea, elderberry, lion's mane, quercetin, resveratrol)
- Amino acids/proteins (collagen, glucosamine, chondroitin, creatine, NAC, phosphatidylserine, 5-HTP)
- Fatty acids (omega-3 fatty acids)
- Antioxidants (CoQ10, alpha-lipoic acid, NMN)
- Hormones (melatonin)
- Probiotics

## Medication Categories Covered

The 20 medications in the database span these categories:
- Statins (atorvastatin/Lipitor, rosuvastatin/Crestor)
- Antidiabetics (metformin/Glucophage)
- Thyroid hormones (levothyroxine/Synthroid)
- ACE inhibitors (lisinopril/Zestril)
- Calcium channel blockers (amlodipine/Norvasc)
- Beta blockers (metoprolol/Lopressor)
- PPIs (omeprazole/Prilosec, pantoprazole/Protonix)
- ARBs (losartan/Cozaar)
- SSRIs/Antidepressants (sertraline/Zoloft, escitalopram/Lexapro, fluoxetine/Prozac, bupropion/Wellbutrin)
- Anticonvulsants (gabapentin/Neurontin)
- Diuretics (hydrochlorothiazide/Microzide)
- Anticoagulants (warfarin/Coumadin)
- GLP-1 agonists (semaglutide/Ozempic/Wegovy)
- Antibiotics (amoxicillin/Amoxil)
- Leukotriene inhibitors (montelukast/Singulair)

---

## Navigation Structure

Three bottom tabs:
1. **Stack** — List of all user's supplements/medications with inline interaction badges. Analysis screen accessible from here.
2. **Today** — Daily check-off per time block (Morning / Afternoon / Evening).
3. **Schedule** — The generated timing schedule showing all three blocks with items and time windows.

---

## Onboarding Flow (v1 — functional, not polished)

Sequence: Health profile → Stack entry → Schedule inputs → "Your stack is ready" preview (shows analysis results and schedule) → Trial starts.

Main app tabs are hidden until onboarding is complete. The polished onboarding redesign is explicitly deferred to post-launch (will be designed based on user feedback).

---

## Visual Design (stated intentions)

- Apple Human Interface Guidelines as foundation
- Native iOS components, SF Symbols, system fonts
- Distinct but restrained branding — not stock iOS, not visually adventurous
- Minimalism, white space, functional color use
- Severity colors reserved for interaction flags (not used decoratively)
- Dark mode from day one
- Specific color palette and branding: TBD (noted as pending in spec)

---

## Data Privacy Summary

- All user health data stored on-device only (Core Data)
- No cloud accounts, no server-side user data storage
- No health data leaves the device
- The interaction database is a read-only bundled asset (no network calls to fetch interaction data)
- Feedback submissions (optional, user-initiated) go to Formspree — contain only user-written text and report type, never health data
- Privacy policy will be publicly hosted and linked from App Store listing and in-app settings
