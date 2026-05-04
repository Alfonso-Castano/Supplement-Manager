# Phase 0: Database Build - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 00-CONTEXT.md — this log preserves the discussion.

**Date:** 2026-05-04
**Phase:** 00-database-build
**Mode:** discuss (default, interactive)
**Areas discussed:** Database format, Collection scope, Execution model, timing_properties structure, Confidence threshold, Suggested actions, Record count target, Update strategy, Canonical name authority, Brand vs generic naming, Conflict resolution, Regional supplement scope

---

## Areas Discussed

### Database Format

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Working format during Phase 0? | JSON→SQLite at end (rec), SQLite directly, JSON throughout | JSON→SQLite at end (after spot-check) |
| One file or two? | One combined (rec), Two separate files | One combined: `stackwise.sqlite` |

**Rationale:** JSON is human-readable and diffable — errors caught before touching binary format. Spot-check step only practical in JSON. Independent update argument for two files not compelling at v1 scale.

---

### Collection Scope

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Broad crawl vs target list first? | Target list first then broaden (rec), Comprehensive crawl, Hard stop | Target list first, broaden if time allows |
| Who defines the target list? | Claude researches (rec), You provide it, Derive from canonical_names.json | Claude researches → user approves → saved as `research/target_list.json` |

**Rationale:** Comprehensive crawl wastes time on compounds that won't appear in real stacks. Adjacent-entry broadening kept (not hard stop) because adjacent pages often contain data relevant to target compounds.

---

### Execution Model

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Stage execution approach? | Interactive (Claude proposes each step), Automated (minimal review), Hybrid (rec) | Hybrid: automated stages, human gate at each boundary |
| Single session or multi-session? | Checkpoint-based multi-session (rec), Single long session | Checkpoint-based multi-session |

**Rationale:** Full interactivity too slow for a pipeline processing hundreds of pages. Full automation too risky — errors in Stage 1 compound into Stage 2/3. Hybrid balances speed and quality. Single session risks context exhaustion at Stage 1 scale.

---

### timing_properties Structure

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Storage format? | JSON blob column (rec), Explicit separate columns | JSON blob column — consistent with `aliases` pattern |
| Which fields needed for Phase 4? | requires_food, requires_empty_stomach, preferred_time_of_day, avoid_with_caffeine | All four |

**Rationale:** JSON blob avoids schema migration for new timing fields post-launch. Phase 4 scheduling reads properties in Swift after deserialization — no SQL query difference. `avoid_with_caffeine` included because many users drink coffee without logging it.

---

### Confidence Threshold

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Minimum confidence for production? | Medium+ (rec), All three tiers, High only | Medium and above |

**Rationale:** App's core differentiator is trustworthy analysis. Low-confidence (OpenFDA co-occurrence, animal studies) creates false flags that undermine trust. Risk is asymmetric: a gap is better than a confidently wrong flag. Low records preserved in JSON for future promotion.

---

### Suggested Action Generation

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Free-form or templated? | Templated (rec), Free-form per record | Templated — 7 baseline templates in `research/action_templates.json` |

**Rationale:** Free-form generates inconsistent tone/phrasing across extraction sessions. Templates ensure uniform quality, are auditable, and allow global corrections. Template 7 (monitor and consult) is the Rx interaction fallback.

---

### Record Count Target

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Minimum records per compound? | At least 1 (SPEC baseline), At least 3 for common supplements, Gap-report driven | Gap-report driven; hard floor is 1 medium+ per target compound |

**Rationale:** Setting minimums before seeing data is premature. Magnesium has different evidence density than NMN. Gap report reveals real coverage after Stage 2 — thresholds set with actual data.

---

### Update Strategy & Versioning

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| DB version field? | Yes — metadata table (decided), No | Yes — metadata table: `db_version`, `date_built`. Semantic versioning from "1.0.0". |
| Update frequency? | On-demand gap-report driven (rec), Monthly cadence, Post-launch critical-only | On-demand; gap_report.md is a living document |

**Rationale:** Monthly cadence creates unnecessary app updates. Critical-only treats database as finished when it won't be. On-demand means reviewing the gap report after launch and updating when real users are underserved.

---

### Canonical Name Authority

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Naming convention? | NIH ODS primary, consumer fallback (rec), IUPAC scientific, Consumer names throughout | NIH ODS primary; consumer name fallback; lowercase_underscores |

**Rationale:** IUPAC is unrecognizable to developers and maintainers. Consumer-names-throughout introduces ambiguity (fish_oil covers EPA, DHA, combinations). NIH ODS resolves this with specific ingredient names.

---

### Brand vs Generic Naming (Medications)

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Generic or brand as canonical? | Generic canonical, brand alias (rec), Allow either | Generic always canonical; brand always alias. Brand alias collection required sub-task during target list research. |

**Rationale:** Mixed canonical forms cause silent pairwise lookup misses. One form per compound is a hard requirement for the lookup engine. Generic is used by every authoritative source the database draws from.

---

### Conflict Resolution

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Which source wins on severity conflict? | Higher severity wins, Higher confidence wins, Higher confidence + tie→higher severity (rec) | Higher confidence wins; ties go to higher severity; both sources always cited; `conflict_note` field added |

**Rationale:** Allowing a low-confidence source to override a high-confidence source on severity would let a single adverse event report override a clinical trial finding. Confidence is the primary tiebreaker. `conflict_note` makes the disagreement visible during spot-check.

---

### Regional Supplement Scope

| Question | Options Presented | User Decision |
|----------|-------------------|---------------|
| Traditional medicine compounds? | US retail only, Include if found in target sources | Include if found in approved sources (NIH ODS, MedlinePlus, MSK); don't add new Ayurvedic/TCM source databases |

**Rationale:** Ashwagandha, berberine, turmeric appear in US retail and in approved sources — excluding by origin would leave real gaps. Scope boundary is the approved source list, not compound origin.

---

## Corrections Applied

None — all decisions were new (no prior context to override).

---

## Deferred Ideas

- Third severity tier — post-launch if database granularity supports it
- Ayurvedic / TCM source databases — future update cycle candidates
- Automated update/version-check mechanism — post-launch

---

## Claude's Discretion Items

- Stage resumption logic implementation
- Stage 2 deduplication implementation details
- OpenFDA query parameter tuning
- Exact format of human gate summaries
