# Phase 4 Mac Test Handoff

**Phase:** 4 -- Smart Schedule
**Date:** 2026-05-15
**Plans:** 04-01, 04-02, 04-03, 04-04

---

## Prerequisites

```bash
git pull origin main
```

All new files in `StackWise/Schedule/` are auto-included via `PBXFileSystemSynchronizedRootGroup`. No manual Xcode target membership changes needed.

---

## 1. Build + Test

```bash
xcodebuild test \
  -project StackWise.xcodeproj \
  -scheme StackWise \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Expected:** >= 48 tests passing (36 from Phase 1-3 + 12 Phase 4).

---

## 2. Simulator Golden Path

### a. Erase simulator
Device > Erase All Content and Settings.

### b. Launch and complete onboarding
Use any values. Set:
- Wake: 7:00 AM
- Breakfast: 8:00 AM
- Lunch: 12:00 PM
- Dinner: 6:00 PM
- Sleep: 10:00 PM

### c. Add warfarin and vitamin_k2
- Tap "+" to add "warfarin" -- confirm DB suggestion.
- Tap "+" to add "vitamin_k2" -- confirm DB suggestion.

### d. Verify Schedule tab (2 items)
- Tap Schedule tab.
- Verify: both items appear in a block.
- Verify: at least one block section renders with a header.

### e. Add iron and vitamin_c
- Add "iron" -- confirm DB suggestion.
- Add "vitamin_c" -- confirm DB suggestion.
- Return to Schedule tab.
- Verify: 4 items distributed across blocks.

### f. Verify section headers
- Section headers show time windows (e.g., "Morning -- 7:00 AM - 12:00 PM").

### g. Verify empty state
- Erase simulator again (Device > Erase All Content and Settings).
- Re-launch app, complete onboarding without adding any items.
- Tap Schedule tab.
- Verify: `ContentUnavailableView` is shown (no crash).

---

## Pass Criteria

- [ ] xcodebuild test: >= 48 tests pass, 0 failures
- [ ] Golden path steps a-g: all pass, no crashes
- [ ] Schedule tab renders blocks with correct time windows
- [ ] Empty state shows ContentUnavailableView
