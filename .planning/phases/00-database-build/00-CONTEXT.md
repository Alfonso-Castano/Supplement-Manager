# Phase 0: Database Build - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the self-built supplement/medication interaction database before any iOS app code begins.
Output is a single `stackwise.sqlite` file (plus `canonical_names.json` and `interactions.json`
working artifacts) that the app bundles as a read-only asset. The database must cover every
compound on the approved 50-supplement / 20-medication target list before Phase 0 is complete.
App implementation starts in Phase 1.

</domain>

<decisions>
## Implementation Decisions

### Database Format
- **D-01:** Working format is JSON throughout Stages 1–2. Extract all records into `research/interactions.json`. Compile to SQLite once, after the manual spot-check passes. Never write to SQLite during extraction — JSON is the reviewable intermediate.
- **D-02:** Production asset is a single combined file: `stackwise.sqlite`. Contains both the `interactions` table and the `ingredients` table. Do not create separate files per table.
- **D-03:** Add a `metadata` table to `stackwise.sqlite` with columns `db_version` (TEXT, e.g. `"1.0.0"`) and `date_built` (TEXT, ISO date). One row, never written by the app. Semantic versioning: patch = record additions/corrections, minor = schema changes, major = breaking schema changes.

### Collection Scope
- **D-04:** Before Stage 1 begins, Claude researches and generates the 50-supplement / 20-medication target list. You review and approve it. The approved list is saved as `research/target_list.json` — a permanent Phase 0 artifact, not a throwaway file.
- **D-05:** Stage 1 collects source pages for target list compounds first. Broadens to adjacent entries only if time allows after target coverage is complete. Hard stop is not enforced — adjacent entries that contain relevant data on target compounds are collected.
- **D-06:** During target list research, collecting the top brand-name aliases for each of the 20 medications is a required sub-task (e.g., Lipitor → atorvastatin). These aliases are pre-populated into `canonical_names.json`.

### Execution Model
- **D-07:** Hybrid automated pipeline with human gate at each stage boundary. Each stage runs as an automated agent. Execution pauses at stage end; a summary is presented (files collected, records extracted, anomalies). You approve before the next stage launches.
- **D-08:** Checkpoint-based multi-session. Each stage writes all output to disk before the session ends. Stage N reads Stage (N-1)'s output from files on disk, never from context window. Every stage is resumable — if interrupted, it checks existing output files and continues from where it left off rather than restarting from scratch.

### Confidence & Record Rules
- **D-09:** Minimum confidence for production database: **medium and above**. High and medium confidence records compile to `stackwise.sqlite`. Low confidence records are retained in `interactions.json` as research artifacts only — they are not compiled to SQLite. Low records are promotable in future update cycles if stronger sources are found.
- **D-10:** Hard floor: every compound on the target list must have at least one medium+ confidence record before Phase 0 is complete. Beyond that, per-compound minimums are determined by the Stage 3 gap report, not set in advance.

### Suggested Actions
- **D-11:** Suggested actions are templated. Claude selects the best-fit template during extraction and fills in compound names and values. Templates are stored in `research/action_templates.json` so all extraction sessions read from the same reference. New templates are added to the file (not written inline) when no existing template fits.
- **D-12:** The seven baseline templates:
  1. `"Take [compound_a] at least [N] hours away from [compound_b]."`
  2. `"Take [compound_a] with food to reduce interaction risk with [compound_b]."`
  3. `"Avoid combining [compound_a] with [compound_b]. Consider replacing [compound_a] with [alternative] if possible."`
  4. `"Consider reducing your [compound_a] dose when taking alongside [compound_b]."`
  5. `"[compound_a] and [compound_b] are well-paired. No timing adjustment needed."`
  6. `"Take [compound_a] in the morning and [compound_b] in the evening to minimize conflict."`
  7. `"Monitor for [effect] when combining [compound_a] with [compound_b]. Consult your doctor if concerned."` ← fallback for Rx interactions and unresolvable conflicts

### Canonical Names & Naming Rules
- **D-13:** Canonical name authority: NIH ODS fact sheet titles define canonical names where available. For compounds not covered by NIH ODS, use the most common US consumer-facing name. Format: lowercase, underscores for spaces. Concrete examples: `vitamin_d3`, `zinc`, `omega_3_fatty_acids`, `coenzyme_q10`, `ashwagandha`. The naming rule is documented in a header comment in `canonical_names.json`.
- **D-14:** Prescription medications: generic name is always canonical, brand names are always aliases. No exceptions. e.g., canonical: `atorvastatin`, aliases: `["Lipitor"]`.

### Conflict Resolution
- **D-15:** When two sources disagree on severity: the higher-confidence source's severity wins. When two sources have equal confidence but disagree on severity: higher severity wins (user safety over precision). Both source URLs are always added to `citations` regardless.
- **D-16:** When a severity conflict exists, add a `conflict_note` field to the record (plain text describing the disagreement). This makes the conflict visible during manual spot-check and to future database maintainers. Note: `conflict_note` is an addendum to the SPEC data model — add it to the `interactions` table schema.

### Timing Properties
- **D-17:** `timing_properties` is a JSON blob column (TEXT) in the `ingredients` table. App deserializes it on launch alongside `aliases`. Schema is extensible without SQLite migration.
- **D-18:** Four optional timing properties. Only populate when the source clearly supports the property — do not fill with `false` if the source is silent:
  - `requires_food` (bool): must be taken with a meal
  - `requires_empty_stomach` (bool): must be taken away from food
  - `preferred_time_of_day` ("morning" | "evening" | "any"): compound has a natural time-of-day preference
  - `avoid_with_caffeine` (bool): should not be taken near caffeine intake (surfaced even when caffeine is not in user's stack)

### Regional Scope
- **D-19:** Scope is US retail common supplements. Traditional medicine compounds (Ayurvedic, TCM) are included if they appear in the approved sources (NIH ODS, MedlinePlus, MSK) during normal collection. Phase 0 does not add Ayurvedic or TCM databases as new sources.

### Update Strategy
- **D-20:** Post-launch database updates are on-demand and gap-report driven — no fixed monthly cadence. Updates ship when the gap report identifies meaningful gaps or when user feedback flags an incorrect/missing interaction. `research/gap_report.md` is a living document: each update cycle appends a dated entry showing what was added, what gaps were closed, and what gaps remain.

### Claude's Discretion
- Stage 1 resumption logic (which files to skip, how to detect already-collected sources)
- Stage 2 deduplication implementation details
- OpenFDA query parameter tuning
- Exact format of Stage 1 collection summary presented at the human gate

</decisions>

<specifics>
## Specific Ideas

- "The manual spot-check step that gates Phase 0 completion is only practical if the data is in a reviewable format. JSON is that format. SQLite is the final compilation step, not the working format."
- "The template set is a living list that grows during Phase 0 if needed" — when no template fits, add a new template to `action_templates.json` rather than writing a one-off free-form action.
- "avoid_with_caffeine is worth including even though caffeine is not always in the user's stack. Many users drink coffee habitually without logging it."
- conflict_note field: "A conflict between two high-confidence sources on severity is a signal that the interaction is genuinely complex and may warrant a cautious note in the suggested action."
- Brand aliases: "During the target list research step, collecting the top brand name aliases for each of the 20 target medications is a required sub-task, not an optional one."

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Spec
- `SPEC.md` — Full product specification. **Primary reference for all Phase 0 work.**
  - Phase 0 execution plan: section `## Feature Roadmap — v1 › Phase 0: Database Build` and `#### Phase 0 — Detailed Execution Plan` (folder structure, Stage 0 tool inventory, Stage 1–3, definition of done)
  - Data model: section `## Data Model › Part 1: Local SQLite Database` (tables: `interactions`, `ingredients`)

### Data Model Addendum (from this discussion)
- **`conflict_note` field** — Add to `interactions` table. Schema: `conflict_note TEXT` — optional, null when absent. Populated only when D-15 conflict resolution was applied (two sources disagree on severity). Plain English description of the disagreement, e.g. `"NIH ODS (high) rates advisory; PubMed abstract (medium) rates critical — higher confidence source wins, higher severity on tie."` Not in SPEC.md — this discussion locks it.
- **`metadata` table** — Add to `stackwise.sqlite`. Columns: `db_version` TEXT, `date_built` TEXT. One row. Not in SPEC.md — this discussion locks it.

### Working Artifacts (created during Phase 0, not yet existing)
- `research/target_list.json` — Approved 50-supplement / 20-medication scope anchor. Created before Stage 1 begins.
- `research/canonical_names.json` — Normalization reference. Created before Stage 2 begins.
- `research/action_templates.json` — Suggested action template set. Created before Stage 2 begins.
- `research/interactions.json` — Extracted records (output of Stage 2).
- `research/gap_report.md` — Coverage analysis (output of Stage 3). Living document post-launch.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — this project has no source code yet. Phase 0 produces data assets, not code.

### Established Patterns
- None established yet. Phase 0 establishes the data layer conventions that Phase 1+ will inherit.

### Integration Points
- `stackwise.sqlite` → bundled as a read-only asset in the iOS app (Phase 3)
- `interactions` table → queried by pairwise lookup engine (Phase 3)
- `ingredients` table → queried by active ingredient auto-suggestion (Phase 2)
- `ingredients.timing_properties` → read by scheduling algorithm (Phase 4)
- `ingredients.aliases` → matched against user label input (Phase 2)

</code_context>

<deferred>
## Deferred Ideas

- Third severity tier (if database granularity supports it) — explicitly post-launch per SPEC
- Ayurvedic / TCM source databases — out of Phase 0 scope; candidates for future update cycles
- Automated update mechanism / version checking between app and bundled database — post-launch once update cadence is established

</deferred>

---

*Phase: 00-database-build*
*Context gathered: 2026-05-04*
