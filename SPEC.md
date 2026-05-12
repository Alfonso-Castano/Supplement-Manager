# StackWise — Conceptual Spec

## What We're Building

**StackWise** (name tentative) is an iOS supplement and medication management app. It helps users who are already taking supplements and/or medications optimize what they're taking — not prescribe new things. The core value is trustworthy interaction analysis paired with a personalized smart schedule and reminders.

---

## The Three Features (shared data layer)

### 1. Interaction & Conflict Analysis
- Cross-references every item in the user's stack against every other item (pairwise)
- Flags supplement↔supplement and supplement↔Rx conflicts only (drug↔drug excluded)
- Analysis runs automatically whenever the stack changes — no trigger needed
- Prescription medications are never touched; solutions always target the supplement
- **Two severity tiers** (advisory / critical) as baseline; expandable to three if database supports it
- Honest about uncertainty: items not in the database are listed with a caveat and external resource links
- Positive insights (well-paired items, optimal timing) surfaced alongside warnings
- Citations and mechanism explanations where the database supports them

### 2. Smart Daily Schedule
- Three time blocks: Morning / Afternoon / Evening
- Inputs: wake/sleep time + meal times (provided during onboarding)
- Presented as a vertically scrollable list of blocks — clean, no timeline, no inline rationale
- Flags on blocks/items link to the analysis screen for depth
- Flags can be positive (good pairing) or negative (conflict)

### 3. Reminders
- Local notifications only — no server infrastructure
- Content: "Time for your morning stack — Magnesium, Vitamin D, Fish Oil" (specific, not generic)
- Tapping opens Today tab for check-off

---

## Navigation (Three Bottom Tabs)

**Stack tab** (two sub-pages via top nav):
- Stack list — all items with inline warning/positive badges
- Interaction analysis screen — grouped by severity (critical → advisory → positive → not-in-database)

**Today tab:**
- Lite check-off per time block (did you take this block's items?)
- No streaks, no history in v1

**Schedule tab:**
- Morning / Afternoon / Evening blocks showing items + suggested time window
- Flags linking to analysis; no inline rationale

---

## Item Entry Model

- **Two fields per item**: user-facing label (brand name, nickname) + active ingredient (what the engine uses)
- App auto-suggests active ingredient from label if straightforward; user always confirms
- If active ingredient not found in database: item added, clearly flagged as outside analysis coverage
- Temporary items (e.g., 10-day antibiotics): manual add/remove, no special type
- Single user profile only (v1)

---

## User Profile (collected during onboarding)

Exact fields finalized after interaction database is selected. Likely: age, sex, weight, known allergies, existing health conditions. Every field must have a plausible use in interaction analysis or scheduling — no data theater.

---

## Interaction Analysis Screen Layout

1. **Critical conflicts** — flagged pairs with mechanism explanation + suggested fix + citation
2. **Advisory conflicts** — same structure, lower severity
3. **Positive insights** — well-paired items, optimal timing confirmations (data-backed only)
4. **Not in database** — items with no interaction data + external research resources

---

## Data & Architecture

- **Storage**: On-device only, Core Data (not SwiftData — iOS 18 stability risk)
- **Credentials**: Keychain
- **Interaction database**: Local curated database (primary approach). Third-party API not ruled out pending pricing research (cost ceiling: ~$1/month per paid user at $4.99 tier). Hybrid (local DB + lightweight update backend) is an option.
- **Notifications**: iOS local notifications, scheduled on-device
- **iCloud sync**: Explicitly deferred post-launch

---

## Monetization

- **Trial**: 14-day full-access free trial (not a permanent free tier)
- **Paywall**: Hard block after trial expires — no dismiss, no degraded mode
- **Pricing**: $4.99/month or $35/year
- **Paywall timing**: After onboarding is complete and user has seen their personalized analysis + schedule
- **Onboarding flow**: Designed after app is feature-complete; studied against SuppCo and comparable health apps

---

## Visual Design

- Foundation: Apple Human Interface Guidelines (native components, SF Symbols, system fonts)
- Distinct but restrained branding — not a stock iOS look, not visually adventurous
- Minimalism, white space, functional color use
- Severity colors reserved for interaction flags
- Dark mode from day one
- Smooth, purposeful transitions
- Specific palette/branding: TBD after name is finalized

---

## What's Deferred (explicitly post-launch)

- iCloud sync / cross-device support
- Rich notifications with lock-screen check-off action
- Streak tracking and adherence history
- Additional schedule inputs (workout timing, caffeine habits)
- Multi-profile support
- Full onboarding flow design (designed after app is built)
- Third-tier severity (if database supports it)

---

## App Name

**Working name: StackWise.** Treated as locked for all technical setup — Xcode project name, bundle identifier (e.g. `com.stackwise.app`), App Store listing, and branding. Bundle identifiers and Xcode project names are painful to rename mid-build. If the name changes, it requires a deliberate rename pass — acceptable, but better to decide before Phase 1. Treat StackWise as locked unless explicitly changed before development begins.

---

## Interaction Database — Locked Decision

**Self-built, locally shipped database.** No third-party API, no licensing dependency.

- **Why not third-party**: RxNorm interaction API discontinued 2024. DrugBank full dataset is CC BY-NC 4.0 (non-commercial only; enterprise license required commercially). Natural Medicines Database is institutionally paywalled. No single usable off-the-shelf option exists.
- **Build process**: AI-assisted multi-stage research and extraction workflow — gather from public sources → AI parses and structures → outputs JSON or SQLite interaction records with citations.
- **Sources**: NIH ODS fact sheets, PubMed research, OpenFDA adverse event data, publicly accessible DrugBank (naming/ID only), MedlinePlus supplement entries, Memorial Sloan Kettering About Herbs database.
- **Format**: JSON or SQLite (TBD at technical spec stage based on query performance needs)
- **Full ownership**: No ongoing cost, no external dependency, can expand over time
- **Citations**: Embedded in database, surfaced to users — serves both attribution and trust

## Open / Appropriately Deferred

- **Exact user profile fields**: Finalized once database is built (fields must map to actual database variables)
- **Third severity tier**: Added post-launch if database granularity supports it
- **Onboarding sequence**: Designed after core features exist; studied against SuppCo + comparable health apps
- **Visual branding**: Color palette and brand identity developed once name is finalized (StackWise, tentative)

---

## Feature Roadmap — v1

### Phase 0: Database Build (before any app code)

The self-built interaction database must exist before the analysis feature can be implemented. This is the first deliverable. Full detail below.

---

#### Phase 0 — Detailed Execution Plan

**Folder structure**

Two subfolders created before Phase 0 begins. Nothing else lives in either.

```
supplement-manager/
  research/               ← all Phase 0 working files
    raw/
      nih_ods/            ← one .txt file per NIH ODS fact sheet
      medlineplus/        ← one .txt file per MedlinePlus herb entry
      msk/                ← one .txt file per MSK herb page
      openfda/            ← JSON response files from API queries
      pubmed/             ← abstract .txt files for targeted searches
    canonical_names.json  ← normalization reference (built before Stage 2)
    interactions.json     ← extracted records (output of Stage 2)
    gap_report.md         ← coverage analysis (output of Stage 3)
  database/               ← production output only, written after Phase 0 is complete
    interactions.sqlite
    ingredients.sqlite    ← or combined into one file; decide at implementation
```

`database/` receives files only after Phase 0 is fully complete and manually spot-checked. Nothing is copied there during working stages.

---

**Step 0 — Tool inventory (runs before anything else)**

Check what tools are available in the current environment and document results before proceeding. The answers determine how automated the workflow can be.

- **WebFetch available?** → Yes: Stage 1 crawls index pages autonomously and follows links. No: URLs must be provided manually per batch.
- **WebSearch available?** → Useful for targeted PubMed abstract retrieval.
- **Sub-agents supported?** → Yes: Stages 1, 2, and 3 run as separate spawned agents. No: stages run sequentially in the same context.
- **Skills supported?** → Yes: create a reusable `extract-interaction` skill so extraction behavior is identical across all source files.

---

**Pre-Stage 2 — Create `canonical_names.json`**

This step runs before any extraction begins. It is the most important quality control step in Phase 0.

Create `supplement-manager/research/canonical_names.json`. This file defines the exact canonical name for every compound expected to appear during extraction. Without it, different extraction passes will normalize the same compound differently (`"vitamin_d"` vs `"vitamin_d3"` vs `"cholecalciferol"`) and pairwise lookups will silently miss matches.

**File structure:**
```json
{
  "vitamin_d3": ["cholecalciferol", "vitamin d", "vitamin d3", "vitamin d-3"],
  "zinc": ["zinc picolinate", "zinc gluconate", "zinc sulfate", "elemental zinc"],
  "magnesium": ["magnesium glycinate", "magnesium citrate", "magnesium oxide", "mag"],
  ...
}
```

Keys are canonical names. Values are arrays of known aliases, alternate spellings, brand forms, and IUPAC names that map to that canonical name.

**Rule during extraction**: Every time a compound is encountered in a source file, check `canonical_names.json` first. If it appears as a value (alias), use the corresponding key (canonical name). If it appears as a key, use it directly. If it appears under a name not yet in the file, add it as a new entry (with the new name as the canonical key) before writing the record. This file is the single source of truth. Any compound not in it does not get written to the database until it is added.

This file also becomes the source for building the `ingredients` table at the end of Stage 2. Aliases are captured here rather than reconstructed afterward.

---

**Stage 1 — Collection**

Goal: Save raw source content to `research/raw/{source}/`. No extraction happens in this stage. Keeping collection and extraction separate means if extraction logic needs to change, sources do not need to be re-fetched.

Each saved file must include the source URL as its first line so citations can be generated accurately during Stage 2.

Sources in priority order:

| Source | Index URL | What to collect |
|---|---|---|
| NIH ODS | `https://ods.od.nih.gov/factsheets/list-all/` | Crawl index, follow every supplement link, save each fact sheet as `.txt` |
| MedlinePlus | `https://medlineplus.gov/druginfo/herb_All.html` | Crawl index, follow every herb link, save each entry as `.txt` |
| MSK About Herbs | `https://www.mskcc.org/cancer-care/diagnosis-treatment/symptom-management/integrative-medicine/herbs/search` | Crawl search results, follow individual herb pages, save each as `.txt` |
| OpenFDA | `https://api.fda.gov/drug/event.json` | See query strategy below |
| PubMed | `https://pubmed.ncbi.nlm.nih.gov/` | Targeted searches for gaps identified in Stage 3 |

**OpenFDA query strategy**: OpenFDA adverse event data is noisy — it contains self-reported adverse event reports, not structured interaction records. Use it only to surface potential compound pairs, not as a primary interaction source.

- Query by supplement name using the `patient.drug.medicinalproduct` field
- Filter results where two or more substances appear together in the same adverse event report
- Treat co-occurrence as a low-confidence signal only — a reason to look further, not a confirmed interaction
- Every OpenFDA-sourced record gets `confidence = "low"` regardless of co-occurrence frequency
- Do not use OpenFDA as the sole source for any record; always verify against NIH ODS, MedlinePlus, or PubMed before including the record

---

**Stage 2 — Extraction**

Goal: Read each file in `research/raw/` and output structured records into `research/interactions.json`.

For each source file:
1. Check `canonical_names.json` for every compound name encountered. Resolve to canonical form before writing. If a name is missing from the file, add it first.
2. Log every alias encountered during extraction into `canonical_names.json` — this builds the ingredients alias list as a byproduct of extraction rather than requiring a separate pass.
3. Identify sections that describe an interaction between two specific compounds.
4. Apply the **explicit rejection rule**: if a source mentions two compounds together but does not describe a specific effect or mechanism — for example, both appearing in the same supplement label or an article that lists them without describing how they interact — do not extract a record. Only extract records where a specific effect is described.
5. For each valid interaction found, populate every required field per schema. Leave `mechanism` and `direction` empty only if the source does not clearly support them.
6. Set `confidence` per the following rules:
   - **high**: human clinical trial data with a clearly described effect and mechanism
   - **medium**: interaction clearly described in a reputable source but mechanism is unclear or indirect
   - **low**: co-occurrence in adverse event data, animal/in vitro study, or theoretical mechanism paper with no human data
7. Add the source URL to `citations`. All records must have at least one citation.

**PubMed-specific confidence rules**: PubMed abstracts vary widely in relevance.
- Human clinical trial with confirmed interaction → `"high"`
- Observational human study or case report → `"medium"`
- Animal study, in vitro study, or theoretical mechanism paper → `"low"`
- Only use abstracts where the interaction between two specific named compounds is explicitly described

**Deduplication rule**: Before writing a record, check if a record for that compound pair already exists (in either direction). If it does: merge by adding the new source URL to `citations` and updating `confidence` upward if the new source is stronger. Do not create a duplicate row. One record per compound pair.

**Drug-drug exclusion**: Do not extract any record where both `compound_a_type` and `compound_b_type` would be `"drug"`. Skip and move on.

**Output**: `research/interactions.json` — complete extracted records. Review this file before generating SQLite. Easier to catch errors in JSON than in a binary database.

---

**Stage 3 — Validation and gap analysis**

Goal: Confirm coverage and identify gaps. Run after `interactions.json` is complete.

**Coverage check**: Research and generate a list of the 50 most commonly taken supplements and 20 most commonly prescribed medications (do not assume — look these up). For each, count how many records exist in `interactions.json` where that compound appears as `compound_a` or `compound_b`.

**Gap report format** (`research/gap_report.md`):
```
# Database Gap Report

## Well-covered compounds (5+ records)
- magnesium: 12 records
- vitamin_d3: 9 records

## Partially covered compounds (1–4 records)
- ashwagandha: 2 records

## Not covered (0 records)
- berberine
- nmn

## Recommended next sources
[Specific PubMed search queries or URLs to address each gap]
```

Use the gap report to drive a second round of targeted PubMed searches. Add newly extracted records to `interactions.json` and regenerate the report until no common supplement has zero records.

**SQLite generation**: Once `interactions.json` is validated and gaps are addressed:
```sql
CREATE INDEX idx_ab ON interactions(compound_a, compound_b);
CREATE INDEX idx_ba ON interactions(compound_b, compound_a);
```
Build the `ingredients` table from `canonical_names.json` — keys become `canonical_name`, value arrays become `aliases` (stored as JSON TEXT per the schema).

---

**Definition of done for Phase 0**

Quantitative:
- Every compound on the 50-supplement / 20-medication reference list has at least one interaction record
- Every record has all required fields populated and at least one citation
- `interactions.json` and `interactions.sqlite` are consistent with each other
- `gap_report.md` exists and identifies remaining gaps with recommended next sources

Qualitative (done by you, not Claude Code):
- Manually review 10 randomly selected records from `interactions.json`
- Verify that `effect`, `suggested_action`, and `citations` are accurate and make sense for each
- This human spot-check catches systematic extraction errors that pass all quantitative criteria
- Phase 0 is not complete until this step is done

Only after both quantitative and qualitative criteria are met: copy `interactions.sqlite` and the compiled `ingredients` data to `supplement-manager/database/`.

### Phase 1: Project Foundation
- [ ] Xcode project setup (XcodeGen + project.yml)
- [ ] Core Data schema (User, StackItem, Schedule, CheckOffLog)
- [ ] Three-tab navigation shell (Stack / Today / Schedule)
- [ ] Basic app icon and launch screen

### Phase 2: Stack & User Setup
- [ ] Health profile entry screens (age, sex, weight, allergies, conditions)
- [ ] Schedule input screens (wake time, sleep time, meal times)
- [ ] Add item flow: label entry → **active ingredient auto-suggestion against database** → user confirms or overrides
- [ ] Active ingredient matching logic: fuzzy match label input against known ingredient names in the database
- [ ] Stack list view with inline badge placeholder
- [ ] Edit / delete items

### Phase 3: Interaction Analysis Engine
- [ ] Bundle interaction database as local asset (SQLite or JSON)
- [ ] Pairwise lookup engine: given a stack, return all flagged pairs
- [ ] Severity classification (advisory / critical)
- [ ] Positive insight detection (well-paired, timing-confirmed)
- [ ] Auto-trigger on every stack change
- [ ] Analysis screen: grouped by severity, conflict pairs with explanation + citation
- [ ] "Not in database" section with external resource links
- [ ] Inline badges on stack item cards

### Phase 4: Smart Schedule

**Scheduling rules (must be implemented in this exact priority order):**

1. **Prescriptions are placed first.** Their time block is fixed and is never moved to resolve a conflict with a supplement. If a prescription has no timing constraints in the database, it defaults to morning.
2. **Timing-conflict pairs are separated.** For any pair where `timing_relevant = true`, the two items must be placed in blocks that are at least `timing_window_hours` apart. Use the user's wake/meal times to compute actual clock separation between blocks.
3. **Individual supplement timing properties are applied next.** The `ingredients` table includes a `timing_properties` field (added during Phase 0 — see note below) with: `requires_food` (boolean), `requires_empty_stomach` (boolean), `preferred_time_of_day` ("morning" | "evening" | "any"). Items with `requires_food = true` are placed in the block closest to a meal time. Items with `requires_empty_stomach = true` are placed at the start of morning (furthest from breakfast) or evening (furthest from dinner). Items with `preferred_time_of_day = "evening"` (e.g. melatonin) are placed in the evening block.
4. **Unconstrained items default to morning.**
5. **Block overflow rule.** If any block exceeds 5 items, overflow to the next block in order (morning → afternoon → evening). If all blocks are full, morning overflow wraps back to afternoon (do not create a fourth block).

**Conflict resolution when two items both require the same block and cannot coexist:**
- Keep the item with the stricter constraint (larger `timing_window_hours`, or `requires_food`/`requires_empty_stomach` = true)
- Move the less-constrained item to the nearest viable block
- Never move a prescription

**Note on `timing_properties` in the `ingredients` table:** Individual supplement timing behavior (with food, empty stomach, morning vs evening) is a property of individual compounds, not of pairs. This must be researched and added to the `ingredients` table during Phase 0 as an additional column. Phase 0 should be updated to capture this data during Stage 1/2 collection and extraction. Without it, the scheduling algorithm can only use pairwise interaction data and will miss important individual timing constraints.

- [ ] Confirm `ingredients` table has `timing_properties` column populated from Phase 0
- [ ] Implement scheduling algorithm per priority rules above
- [ ] Schedule tab: Morning / Afternoon / Evening blocks with item lists and time windows
- [ ] Analysis flags on time blocks (positive and conflict indicators)
- [ ] Link from schedule flags to analysis screen

### Phase 5: Functional Onboarding
A minimal but working onboarding flow that sequences the existing screens and starts the trial. Not the final polished onboarding design — that is post-launch. This version must exist for trial logic to function correctly.

- [ ] Onboarding coordinator: sequences health profile → stack entry → schedule inputs → preview screen
- [ ] "Your stack is ready" preview: shows analysis results and schedule before trial starts
- [ ] **Trial start trigger**: fires at onboarding completion, writes start date to UserDefaults, persists locally
- [ ] Main app tabs hidden until onboarding is complete

### Phase 6: Reminders & Today Tab
- [ ] Local notification scheduling tied to generated schedule
- [ ] Notification content: specific item list per time block (e.g., "Time for your morning stack — Magnesium, Vitamin D")
- [ ] Today tab: morning / afternoon / evening check-off rows
- [ ] Mark time block as complete; persist to Core Data

### Phase 7: Monetization
- [ ] StoreKit 2 subscription setup ($4.99/month and $35/year)
- [ ] Trial expiry check on app launch (compare today vs. stored trial start date + 14 days)
- [ ] Hard block paywall screen on trial expiry — no dismiss, no degraded mode
- [ ] Restore purchases flow
- [ ] Active subscription check gates the app past the paywall

### Phase 8: In-App Feedback
Users must be able to flag incorrect interactions, report schedule issues, and submit general feedback from multiple places in the app. This is a trust and trust-maintenance feature, not a polish feature.

**Submission mechanism: Formspree (decided).** Free tier, no backend infrastructure required, submissions land in a spreadsheet. Feedback volume at launch will be low enough that a spreadsheet is sufficient. Formspree sends data to a third-party server — this must be disclosed in the privacy policy. Note: no health data is sent via feedback forms. Feedback contains only user-written text and the type/context of the report.

- [ ] Feedback entry point on each flagged interaction pair ("Dispute this flag")
- [ ] Feedback entry point on the schedule ("Report a scheduling issue")
- [ ] General feedback accessible from settings/profile
- [ ] Feedback form: type selector + text field + submit button
- [ ] POST to Formspree endpoint on submit; store locally and retry on next launch if submission fails
- [ ] Add `NSAppTransportSecurity` and outbound network entitlement for Formspree domain only

### Phase 9: Polish & Ship
- [ ] Dark mode
- [ ] Visual branding (color palette, typography, icons)
- [ ] **Privacy policy** — required by Apple before submission. Must clearly state: what data is collected (age, sex, weight, health conditions, allergies, medication names), that all data is stored on-device only and never sold or shared, how feedback submissions are handled (text sent to Formspree), and that no health data leaves the device. Host publicly (GitHub Pages or similar) and link from the App Store listing and in-app settings.
- [ ] App Store metadata, screenshots, App Store description
- [ ] **Age rating** — health apps dealing with medication data typically receive 12+ or 17+ depending on how medical content is characterized during App Store Connect setup. Fill out the content questionnaire accurately; do not under-rate to improve discoverability.
- [ ] **TestFlight** — use internal TestFlight (up to 100 devices on the developer account, no Apple review required) for initial testing. If external beta testers are needed, submit for external TestFlight review early — Apple review takes 1–3 days and can block the launch timeline if done last-minute.
- [ ] App Store submission

---

### Explicitly Deferred (post-v1)
- Onboarding screen sequence redesign (designed from user feedback)
- iCloud sync / CloudKit
- Rich lock-screen check-off notifications
- Streak tracking and adherence history
- Multi-profile support
- Additional schedule inputs (workout timing, caffeine)
- Third severity tier
- User-submitted interaction feedback pipeline

---

---

## Data Model

Two completely separate data stores. The local SQLite database ships with the app as a read-only bundle asset and powers analysis. Core Data is the user's persistent app state.

---

### Part 1: Local SQLite Database (read-only, ships as bundle asset)

Two tables. The app never writes to this file — it's a static asset updated only via app updates.

#### Table: `interactions`

The primary interaction records. One row per compound pair.

| Column | Type | Required | Notes |
|---|---|---|---|
| `id` | INTEGER PK | yes | Auto-increment |
| `compound_a` | TEXT | yes | Normalized active ingredient, e.g. `"zinc"` |
| `compound_b` | TEXT | yes | Normalized active ingredient, e.g. `"copper"` |
| `compound_a_type` | TEXT | yes | `"supplement"` or `"drug"` |
| `compound_b_type` | TEXT | yes | `"supplement"` or `"drug"` |
| `interaction_type` | TEXT | yes | `absorption_competition`, `timing_conflict`, `unsafe_combination`, `synergy` |
| `severity` | TEXT | yes | `"advisory"` or `"critical"` |
| `mechanism` | TEXT | optional | Plain English. Omit if unclear or unsupported. |
| `direction` | TEXT | optional | `"bidirectional"` or `"directional"`. Omit if unclear. |
| `effect` | TEXT | yes | What actually happens if both are taken |
| `suggested_action` | TEXT | yes | Always targets the supplement, never the prescription |
| `timing_relevant` | INTEGER | yes | Boolean (0/1). Does timing separation help? |
| `timing_window_hours` | INTEGER | optional | Hours of separation recommended. Null if `timing_relevant = 0` |
| `citations` | TEXT | yes | JSON array of source URLs/references. Minimum one. |
| `confidence` | TEXT | yes | `"high"`, `"medium"`, `"low"`. Internal only — never shown to user. |
| `date_added` | TEXT | yes | ISO date string, e.g. `"2026-05-01"` |

**Pairwise lookup query** (used by the analysis engine):
```sql
SELECT * FROM interactions
WHERE (compound_a = ? AND compound_b = ?)
   OR (compound_a = ? AND compound_b = ?)
```
Two parameters passed twice (A,B then B,A) to handle non-directional storage.

**Indexes needed**: compound on `(compound_a, compound_b)` and `(compound_b, compound_a)` for fast pairwise lookups.

**Known limitation — alias search**: Aliases are stored as a JSON TEXT column. Do NOT use a SQL LIKE query against raw JSON text — false matches and missed results. At implementation time, load the `ingredients` table into memory on app launch and do substring matching in Swift on the deserialized `[String]` alias arrays. The table is small enough that a full in-memory scan is fast.

---

#### Table: `ingredients`

Powers the active ingredient auto-suggestion during item entry. One row per known compound.

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `canonical_name` | TEXT | The normalized name used in `interactions` (e.g. `"iron"`, `"vitamin_d3"`) |
| `item_type` | TEXT | `"supplement"` or `"drug"` |
| `aliases` | TEXT | JSON array of alternative names, spellings, brand forms (e.g. `["ferrous sulfate", "ferric", "iron bisglycinate"]`) |
| `category` | TEXT | e.g. `"mineral"`, `"vitamin"`, `"amino_acid"`, `"medication"` |

**Auto-suggestion query**: When a user types a label, search `aliases` for a match, return `canonical_name`. If auto-suggestion is implemented as simple substring matching this is a LIKE query on the aliases column. Confirm or override step always shown to the user regardless.

---

### Part 2: Core Data Schema (user's persistent state)

Four entities. The app reads and writes this data. The interaction SQLite database is never written to.

#### Entity: `UserProfile` (singleton — one record ever)

| Attribute | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `age` | Integer 16 | |
| `sex` | String | `"male"`, `"female"`, `"other"` |
| `weightKg` | Double | |
| `allergies` | Transformable | `[String]` array |
| `conditions` | Transformable | `[String]` array |
| `wakeTime` | Date | Time component only; date portion ignored |
| `sleepTime` | Date | Same |
| `breakfastTime` | Date | Optional |
| `lunchTime` | Date | Optional |
| `dinnerTime` | Date | Optional |
| `onboardingComplete` | Boolean | Gates tab navigation on first launch |
| `trialStartDate` | Date | Set once at onboarding completion. Nil until then. |
| `subscriptionStatus` | String | Cached StoreKit 2 state: `"trial_active"`, `"trial_expired"`, `"subscribed"`, `"unknown"`. Updated on launch and on StoreKit transaction events. App gates access from this field — no StoreKit query on every screen load. |

---

#### Entity: `StackItem` (one per supplement or medication)

| Attribute | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `label` | String | User-facing display name — any format, brand or nickname |
| `activeIngredient` | String | Normalized canonical name matching `ingredients.canonical_name`. This is what the analysis engine uses. |
| `itemType` | String | `"supplement"` or `"drug"` — maps to `compound_a_type` in interactions |
| `isPrescription` | Boolean | Drives "never suggest changing this" logic |
| `isInDatabase` | Boolean | False = no match found; item tracked but excluded from analysis |
| `dosage` | String | Optional; user reference only, not used in analysis |
| `frequency` | String | Optional; user reference only |
| `addedDate` | Date | |
| `isActive` | Boolean | Soft delete; allows removal without data loss |
| `sortOrder` | Integer 16 | User-defined display order in stack list |

**Relationships**: `StackItem` → `ScheduledDose` (one-to-many, cascade delete)

---

#### Entity: `ScheduledDose` (generated by scheduling algorithm, regenerated on every stack change)

| Attribute | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `timeBlock` | String | `"morning"`, `"afternoon"`, `"evening"` |
| `suggestedTime` | Date | Computed time within the block based on user's wake/meal times |
| `position` | Integer 16 | Display order within the block |

**Relationship**: `ScheduledDose` → `StackItem` (many-to-one)

On any stack change: all `ScheduledDose` records are deleted and regenerated. This keeps the schedule always consistent with the current stack without merge/diff logic.

---

#### Entity: `DailyCheckOff` (lite logging — one per time block per calendar day)

| Attribute | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `date` | Date | Normalized to midnight (calendar day key) |
| `timeBlock` | String | `"morning"`, `"afternoon"`, `"evening"` |
| `completed` | Boolean | |
| `completedAt` | Date | Optional; when the user tapped complete |

Records are created lazily — a `DailyCheckOff` for a given (date, timeBlock) is created when the user first views the Today tab for that day. No pre-generation needed.

**Fetch predicate** for Today tab: `date == [today's midnight] AND timeBlock == "morning"` etc.

**Join with ScheduledDose**: The Today tab must show each time block's items AND its check-off state. `ScheduledDose` and `DailyCheckOff` share no Core Data relationship — they are joined in code by matching `timeBlock` string values. This is intentional. Do not add a Core Data relationship between them.

---

#### Entity: `FeedbackItem` (user-submitted feedback, stored locally before transmission)

| Attribute | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `type` | String | `"incorrect_interaction"`, `"schedule_issue"`, `"general"` |
| `context` | String | Optional. The specific interaction pair, schedule block, or screen the report is about. |
| `body` | String | The user's message |
| `createdAt` | Date | |
| `submitted` | Boolean | False until successfully transmitted |

**Submission mechanism**: On submission, attempt to POST to a lightweight no-code endpoint (e.g., Formspree, or a simple email via `MFMailComposeViewController`). On success, mark `submitted = true`. On failure, retain locally and retry on next launch. This ensures no feedback is silently lost.

**Entry points in the app** (v1):
- Each flagged interaction pair on the analysis screen: "Dispute this flag"
- Schedule tab: "Report a scheduling issue"
- Settings/Profile: general feedback form

---

### How the Two Data Stores Connect

The bridge is `StackItem.activeIngredient` ↔ `ingredients.canonical_name` / `interactions.compound_a` / `interactions.compound_b`.

**Analysis flow:**
1. Fetch all active `StackItem` records from Core Data
2. Extract `activeIngredient` strings from items where `isInDatabase = true`
3. Run pairwise queries against the SQLite `interactions` table
4. Return `InteractionResult` structs (in-memory only — not persisted to Core Data)
5. Update UI; inline badges on stack cards, full analysis screen

**Scheduling flow:**
1. Fetch all active `StackItem` records
2. Fetch `InteractionResult` for the current stack (from step above)
3. Apply scheduling rules: use `timing_relevant`, `timing_window_hours`, and `interaction_type` to assign items to time blocks
4. Use `UserProfile.wakeTime`, `.breakfastTime`, `.lunchTime`, `.dinnerTime` to compute `suggestedTime` per dose
5. Delete all existing `ScheduledDose` records, write new ones
6. Schedule local notifications from the new `ScheduledDose` set

**Reminder flow:**
1. On schedule generation, cancel all pending local notifications
2. Re-schedule notifications for each `ScheduledDose`, grouped by `timeBlock`
3. Notification body lists all items in that block by `label`

---

## Next Steps (user-defined sequence)

1. ~~Conceptual discussion~~ ✓
2. ~~Feature roadmap~~ ✓
3. ~~Data model~~ ✓
4. Technical specs
5. Build
