# Phase 4 Context — Smart Schedule

**Locked:** 2026-05-15  
**Status:** Planning complete — ready for execution

---

## Goal

Implement the 4-rule priority scheduling algorithm and the Schedule tab showing Morning / Afternoon / Evening blocks. The algorithm consumes data already available from Phase 3's data layer and Phase 2's `UserProfile` meal/wake times.

---

## Locked Decisions

**D-36**: `timing_properties` accessed by adding `timingProperties(for slug: String) -> TimingProperties?` to the existing `IngredientRepository`. No new repository class. Reuses the existing read-only DB handle.

**D-37**: Schedule persisted to Core Data `ScheduledDose`. `ScheduleStore` is `@Observable final class`, writes `ScheduledDose` records on recompute, and caches a `ScheduleResult` value in memory for the view to read. Phase 6 (Today tab) reads `ScheduledDose` directly as FK anchors for `DailyCheckOff`.

**D-38**: Dirty-flag recompute pattern — same as `AnalysisStore`. `ScheduleStore.invalidate()` is called in `StackItemFactory.onSaved`; first read after invalidation recomputes (deletes old `ScheduledDose` rows, inserts new ones, updates cached `ScheduleResult`). Recomputes once on launch.

**D-39**: Schedule tab (`ScheduleView.swift`) is a SwiftUI `List` with 3 sections (Morning / Afternoon / Evening). Each section header shows the block name and time window (e.g., "Morning · 7:00–12:00"). Each item row shows label, dosage, and a conflict badge (red for timing-conflict pair in the same block or insufficient separation warning) or synergy badge (green).

**D-40**: 4 scheduling rules — sufficient to satisfy all 5 success criteria. No 5th rule needed.

**D-41**: 4 sub-plans: 04-01 (data layer + ScheduleStore skeleton), 04-02 (ScheduleEngine pure algorithm + tests), 04-03 (ScheduleView UI), 04-04 (wire invalidation + Core Data writes + Mac batch).

**D-42**: Mac handoff batched once at the end of Phase 4 (same pattern as Phase 3 D-33).

---

## Scheduling Algorithm — 4 Rules (Priority Order)

Rules are evaluated in order. Higher-priority rules win over lower-priority ones.

**Rule 1 — Prescriptions lock first.**  
Items where `isPrescription = true` are placed before any supplement conflicts are resolved. Their block is determined by `timing_properties.preferredTimeOfDay`. If no preference: Morning. Within their block they receive `position = 0, 1, 2, ...` before supplements.

**Rule 2 — Timing-conflict separation.**  
For each `InteractionPair` where `timingRelevant = true`, the two items must be in blocks whose suggested times differ by ≥ `timingWindowHours`. The higher-priority item (prescription > DB-matched supplement > unmatched) stays in its preferred block; the other is pushed to the nearest qualifying block.  
Block suggested times (for separation math):
- Morning: `userProfile.breakfastTime` (fallback: `wakeTime + 30min`)
- Afternoon: `userProfile.lunchTime`
- Evening: `userProfile.dinnerTime`

**Rule 3 — `timing_properties` constraints.**  
Applied after prescription placement, before default assignment:
- `required_food = true` → must be in Morning (breakfast), Afternoon (lunch), or Evening (dinner) — the block anchored to a meal. Preference: `preferredTimeOfDay` if it maps to a meal block, else Morning.
- `requires_empty_stomach = true` → must be placed ≥ 1 hour before the nearest meal. In practice: Morning (at `wakeTime`), or 1h before breakfast if wake is close to breakfast.
- `preferred_time_of_day` (`"morning"` / `"afternoon"` / `"evening"`) → place in that block.
- `avoid_with_caffeine` → informational only in Phase 4; no placement logic (Phase 6+).

**Rule 4 — Default + overflow.**  
Items with no constraint from Rules 1–3 default to Morning. If a block reaches 5 items, additional items overflow to Afternoon, then Evening. `position` within a block is sequential by sort order.

---

## Data Flow

```
StackItem[] (Core Data, isActive=true)
    ↓
IngredientRepository.timingProperties(for slug) → TimingProperties?
    ↓
InteractionRepository.pairwise(for slugs) → [InteractionPair] (timingRelevant filter)
    ↓
UserProfile (wakeTime, breakfastTime, lunchTime, dinnerTime, sleepTime)
    ↓
ScheduleEngine.schedule(items:pairs:timingProps:profile:) → ScheduleResult
    ↓
ScheduleStore → writes ScheduledDose to Core Data + caches ScheduleResult
    ↓
ScheduleView reads ScheduleStore.currentSchedule()
```

---

## New File Structure

```
StackWise/
  Schedule/                          ← new folder
    TimingProperties.swift           ← struct + JSON decoding
    ScheduleResult.swift             ← value type: morning/afternoon/evening arrays
    ScheduleEngine.swift             ← pure enum, no SwiftUI/CoreData imports
    ScheduleStore.swift              ← @Observable, dirty-flag, Core Data writes
  Features/
    Schedule/
      ScheduleView.swift             ← REWRITE placeholder
StackWiseTests/
  ScheduleEngineTests.swift          ← pure algorithm tests (no DB dependency)
  ScheduleStoreTests.swift           ← dirty-flag + recompute tests (debug seam)
```

`IngredientRepository.swift` gains one new method. `StackItemFactory.swift` gains an additional `onSaved` call site for `ScheduleStore`. `StackWiseApp.swift` gains `ScheduleStore` injection.

---

## Carry-forward From Phase 3

- `InteractionPair.timingRelevant: Bool` and `timingWindowHours: Int?` — captured in `InteractionRepository`, consumed by `ScheduleEngine`.
- `hasSynergy(forSlug:)` on `AnalysisResults` — still not wired to UI (carry-forward deferred again; Phase 4 adds synergy badge in `ScheduleView` via `AnalysisStore`, so it gets wired implicitly).
- `displayName(_:)` slug → label helper in `AnalysisView` — may be needed in `ScheduleView`; extract to shared helper in 04-03 if needed.

---

## Mac Handoff (D-42)

One batch at Phase 4 end, same pattern as D-33:
1. Verify new `StackWise/Schedule/*.swift` files are auto-included (PBXFileSystemSynchronizedRootGroup).
2. `xcodebuild test` — target ≥ 36 + new Phase 4 tests.
3. Simulator golden path: onboarding → add warfarin + vitamin_k2 + iron + vitamin_c → Schedule tab → verify 3 blocks render with items and correct placement.
