# Phase 3: Interaction Analysis Engine - Context

**Gathered:** 2026-05-14
**Status:** Ready for execution (pending ExitPlanMode approval)

<domain>
## Phase Boundary

Implement the differentiator: a local pairwise interaction analysis engine over the bundled `stackwise.sqlite`. Produce grouped results (critical → advisory → synergy → not-in-database) on a dedicated analysis screen and reflect per-item analysis state as inline badges on the stack list.

In scope:
- A second `@Observable` repository (`InteractionRepository`) for the `interactions` table.
- A pure `AnalysisEngine` that turns `[StackItem]` into grouped `AnalysisResults`.
- An `@Observable AnalysisStore` with dirty-flag caching, invalidated on stack mutation.
- The `AnalysisView` UI (replacing the Phase 2 placeholder at `Features/Stack/AnalysisView.swift`).
- Inline badges on `StackListView` rows.

Out of scope:
- Timing-aware scheduling (Phase 4 — `timing_relevant` / `timing_window_hours` are surfaced but not acted on).
- "Dispute this flag" feedback flow (Phase 8).
- Persisting analysis results to Core Data (D-29 forbids it).
- Touching the source-of-truth drift between `database/stackwise.sqlite` and `StackWise/stackwise.sqlite`.

</domain>

<decisions>
## Implementation Decisions

### Repository architecture
- **D-26:** Build a second `@Observable final class InteractionRepository` with its own read-only handle to the bundled `stackwise.sqlite`. Phase 2's `IngredientRepository` is untouched except for the carry-forward fix below.
  - Rationale: clean single-responsibility boundary; Phase 2 file just passed review; SQLite read-only access does not contend on a 77 KB bundled file. Shared-handle refactor is real risk for theoretical gain at this scale.
- **D-26a (carry-forward fix CF-6):** Convert `IngredientRepository.deinit` from `sqlite3_close(db)` to `sqlite3_close_v2(db)`. Apply this in Plan 03-01 because the new `InteractionRepository` will copy the same close-pattern; bringing both to the preferred API once costs one line.

### Analysis timing
- **D-27:** Analysis runs lazily with dirty-flag invalidation.
  - `AnalysisStore` (`@Observable`) holds `results: AnalysisResults?` and `dirty: Bool`.
  - Stack mutations (add / edit / delete / `isActive` change) call `analysisStore.invalidate()` which sets `dirty = true` and clears `results`.
  - The first read of `results` after `dirty` is true triggers `recompute()`. Subsequent reads return the cache.
  - Rationale: the eager option pays cost on every mutation regardless of whether the user opens the analysis screen; the lazy-only option can't drive live row badges. Hybrid keeps both surfaces in sync via one flag and one cache.
  - Cost envelope: at n=20 items, 190 pairs × prepared-statement step ≈ sub-millisecond. Recompute is cheap; this isn't a perf decision, it's a freshness-coherence decision.

### Screen placement
- **D-28:** `AnalysisView` is reached via a NavigationStack push from `StackListView`'s toolbar (a button to the left of the existing "+").
  - Respects the locked 3-tab decision (D-05 from Phase 1's CONTEXT and the bundle-id-era locked decisions).
  - Matches the existing file layout — the placeholder is already at `Features/Stack/AnalysisView.swift`.
  - More discoverable than a sheet, less invasive than a fourth tab.

### Persistence model
- **D-29:** Analysis results live in memory only. No new Core Data entity.
  - Deterministic from `[active StackItem]` + bundled DB. Recomputed on launch (the first read sees `dirty == true` because `results` starts nil).
  - Avoids a write path on every stack change.

### Severity & grouping
- **D-30:** Severity values come directly from the DB `severity` column (`advisory` / `critical`) — exposed via a Swift enum, no remapping. The DB schema enforces the only-two-values invariant via `CHECK`.
- **D-31:** "Positive insights" = rows where `interaction_type = 'synergy'` (13 rows in current DB, all advisory severity). Synergy rows are routed to the synergy section regardless of severity column — they do not appear under "advisory."
- **Grouping (rendered top-down):**
  1. **Critical** — `severity = 'critical'` AND `interaction_type != 'synergy'` (9 rows today).
  2. **Advisory** — `severity = 'advisory'` AND `interaction_type != 'synergy'` (41 rows today).
  3. **Synergy / positive insights** — `interaction_type = 'synergy'` (13 rows today, regardless of severity).
  4. **Not in database** — stack items with `isInDatabase == false`, surfaced as a flat list with a note that no analysis is possible.

### Direction handling
- **D-32:** The pairwise SQL query reads:
  ```sql
  SELECT * FROM interactions
  WHERE (compound_a IN (?slugs) AND compound_b IN (?slugs))
    AND (
        direction = 'bidirectional'
        OR (direction = 'directional')
        OR direction IS NULL
    );
  ```
  Bidirectional pairs match regardless of order. Directional pairs are stored in canonical order `(compound_a, compound_b)` by Phase 0; our `IN/IN` filter naturally only matches when both slugs are present in the user's stack — order does not need to be enforced again because each interaction row already lists the ordered pair, and we're not duplicating rows. The Swift layer is responsible for not double-rendering a pair if the user's stack contains both slugs (i.e., each interaction row maps to exactly one `AnalysisResult.Pair`).

### Mac handoff cadence
- **D-33:** Batch Mac handoff at the end of the phase — one add-to-target session covering all new Swift files, one `xcodebuild test` run, one simulator pass. Matches the Phase 2 cadence.

### Claude's discretion
- Internal naming (`AnalysisEngine.Result`, `Pair`, `Group`, etc.).
- Whether `AnalysisView` uses `List` with sections or a `ScrollView` + `LazyVStack`.
- Whether the toolbar "Analyze" button uses a label, an SF Symbol, or both.
- Test fixture style for `AnalysisEngine` tests (in-memory pairs vs. an in-memory SQLite copy with a curated subset).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before implementing.**

### Bundled DB (read-only at runtime; read-only at planning)
- `database/stackwise.sqlite` — Source-of-truth copy. Verified 2026-05-14 against the actual schema (see DB facts below). Use only for inspection during planning; the runtime app reads `StackWise/stackwise.sqlite`.

### DB facts verified 2026-05-14 (do not re-discover)
- `interactions` table: 63 rows, columns: `id, compound_a, compound_b, compound_a_type, compound_b_type, interaction_type, severity, mechanism, direction, effect, suggested_action, timing_relevant, timing_window_hours, citations, confidence, date_added, conflict_note`.
- `severity` ∈ {`advisory` (54), `critical` (9)}.
- `interaction_type` ∈ {`absorption_competition` (7), `synergy` (13), `timing_conflict` (2), `unsafe_combination` (41)}.
- `direction` ∈ {`bidirectional`, `directional`}.
- `conflict_note`: 0 non-null rows in the current DB.
- `compound_a` / `compound_b` are snake_case slugs (`vitamin_k2`, `warfarin`, `omega_3_fatty_acids`) that match `ingredients.canonical_name` and `StackItem.activeIngredient` written by Phase 2.

### Phase 2 surface
- `StackWise/Data/IngredientRepository.swift` — pattern reference for `InteractionRepository` (open flags, `defer { sqlite3_finalize }`, `SQLITE_TRANSIENT`, search method shape).
- `StackWise/Features/Stack/StackItemFactory.swift` — point where stack mutations originate; analysis invalidation hook lives here.
- `StackWise/Features/Stack/StackListView.swift` — host of the Analyze toolbar button (Plan 03-03) and inline badges (Plan 03-04).
- `StackWise/Features/Stack/AnalysisView.swift` — Phase 2 placeholder file; Plan 03-03 replaces its body.

### Architectural locks still in force
- iOS 17 minimum (Phase 1 D-01).
- `@Observable` + `.environment()` only — no `ObservableObject` / `@Published` for our types (Phase 1 D-03). Apple's `NSManagedObject` via `@ObservedObject` remains the accepted exception.
- 3-tab navigation shell (Stack / Today / Schedule) — no fourth tab.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `IngredientRepository` SQLite open/close/prepare/finalize pattern — copy into `InteractionRepository`.
- `StackItemFactory.create` — the single insertion point for new stack items. Adding an `AnalysisStore.invalidate()` call here covers add. Delete and isActive-flip are out of scope for Phase 3 (no edit/delete UI exists yet — Phase 2 left it explicitly out).
- `@FetchRequest` in `StackListView` — Plan 03-04 reads `item.activeIngredient` and `item.isInDatabase` on each row to drive badges.

### Integration points
- `StackWiseApp` injects `appState`, `ingredientRepo`, and `\.managedObjectContext`. Plan 03-01 adds `interactionRepo` to that line; Plan 03-02 adds `analysisStore` (built around `interactionRepo`).
- `AnalysisStore` depends on `InteractionRepository` (read source) and `NSManagedObjectContext` (to fetch the current `[active StackItem]` when recomputing). Both come from `@Environment`.

### Patterns NOT to break
- Reserved Core Data attribute names — Phase 3 introduces no new Core Data attributes (D-29), so the forbidden-name list is moot for this phase.
- Manual `NSManagedObject` subclasses with `@objc(EntityName)` — also moot; no schema changes.
- The two-copies-of-the-DB constraint — Phase 3 reads only; no regeneration risk.

</code_context>

<specifics>
## Specific Ideas

- `AnalysisResults` is a single value type with four slices (`critical`, `advisory`, `synergy`, `notInDatabase`). Keep it `Equatable` so SwiftUI diffing is cheap.
- For inline badges (Plan 03-04): each badge is derived from `AnalysisStore.results?.worstSeverity(for: stackItem.activeIngredient)`. Keep that lookup on `AnalysisResults`, not on the view.
- Tests for `AnalysisEngine` should NOT require the bundled DB at all — pass an injected `PairFetching` protocol (or closure) so tests provide a curated pair set. Bundled-DB integration is covered by `InteractionRepositoryTests`.
- The "Analyze" toolbar button is always enabled. When the user's stack is empty, `AnalysisView` shows a `ContentUnavailableView` mirroring the empty stack treatment.

</specifics>

<deferred>
## Deferred Ideas

- Surface `timing_window_hours` graphically (clock-based UI) — deferred to Phase 4, which owns timing.
- "Dispute this flag" affordance on each pair — deferred to Phase 8 (feedback).
- Analysis-on-mutation eager mode (D-27 alternative) — revisit if real-world stacks exceed n=50 and lazy recompute feels slow.
- Filtering / sorting controls inside `AnalysisView` — out of scope; current data volume (≤ ~60 results per stack) does not warrant it.

</deferred>

---

*Phase: 03-interaction-analysis*
*Context gathered: 2026-05-14*
*Supersedes:* `.claude/PHASE-3-HANDOFF.md` (handoff document retained for history; this CONTEXT is the source of truth going forward).
