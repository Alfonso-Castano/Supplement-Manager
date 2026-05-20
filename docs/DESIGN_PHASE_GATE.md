# StackWise Design Phase Gate
Last updated: 2026-05-20

## Rule
A screen is DESIGN READY only when its functional implementation is complete,
all data flows are working, and it has been reviewed in the simulator.

## Screen Status

| Screen | Phase | Functional Status | Design Status | Notes |
|---|---|---|---|---|
| Stack tab | 2–3 | ✅ Complete | 🔄 In progress | Translation applied — pending simulator review |
| Analysis screen | 3 | ✅ Complete | ⏳ Not started | Ready for Claude Design |
| Schedule tab | 4 | ✅ Complete | ⏳ Not started | Ready for Claude Design |
| Today tab | 5 | ❌ Not started | 🔒 Blocked | Placeholder only — wait for Phase 5 |
| Onboarding | 6 | ✅ Complete | ⏳ Not started | HealthProfileView functional; ready for Claude Design |
| Paywall | 7 | ❌ Not started | 🔒 Blocked | |
| Settings | 8 | ❌ Not started | 🔒 Blocked | |

## Design Status Key
✅ Complete — Design applied and reviewed in simulator
🔄 In progress — Claude Design session open or translation in progress
⏳ Not started — Functionally ready, design work not yet begun
🔒 Blocked — Functional implementation not complete

## DesignSystem.swift Status
[x] File created
[x] Color tokens populated with brand values
[x] Typography tokens populated
[x] Severity tokens populated
[x] Adaptive light/dark tokens applied (backgroundPage, backgroundCard, borderDefault, textTertiary)
[x] Applied to Stack tab
[x] Applied to Analysis screen
[x] Applied to Schedule tab
[ ] Applied to Today tab
[x] Applied to Onboarding (no color refs present — Form uses system defaults)
[ ] Applied to Paywall
[ ] Applied to Settings
[ ] All hardcoded colors removed (Phase 9 complete)

## App Icon Status
[x] Canvas: 1024×1024, diagonal gradient #0F9BBF→#1272A8→#0F6B48
[x] White radial gloss ellipse at top-left (30% opacity)
[x] Five right-aligned capsule pills with per-pill white gradient opacity
[x] Inner highlight strip on each pill
[x] "SW" bitmap text on top pill (93% white)
[x] All sizes generated: 1024, 512, 180, 120, 87, 80, 60, 58, 40, 29, 20
[x] Contents.json populated with all iPhone idiom entries
[ ] Reviewed in Xcode / simulator
