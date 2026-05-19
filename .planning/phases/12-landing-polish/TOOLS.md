# TOOLS.md — Landing Page Polish (Phases 12–15)

**Status:** Verified 2026-05-19  
**Scope:** Tools available to Claude Code during Phases 12–15 (visual polish, responsive, QA, deploy)

---

## Selected Tools

### Playwright MCP
- **Config:** `.mcp.json` at project root (already wired)
- **Invocation:** Tools available as `mcp__playwright__browser_*` — navigate, screenshot, resize, snapshot, form interaction
- **Verified:** 2026-05-19 — full-page screenshots taken at 1440px and 375px against `localhost:4322`
- **Primary use:**
  - Phase 12: Desktop layout audit, mobile responsive review at 375px / 390px / 768px
  - Phase 12: Animation verification (scroll-triggered fade-ins, nav transition)
  - Phase 14: Cross-browser smoke tests, form submission end-to-end
- **Start dev server:** `npm run dev -- --port 4321` from `landing/` (falls back to 4322 if port taken)

### Taste Skills (design-taste-frontend + 11 variants)
- **Installed:** `landing/.agents/skills/` — 12 skill files, symlinked to Claude Code
- **Key skills for Phase 12:**
  - `design-taste-frontend` — layout, typography, motion, spacing guidance
  - `high-end-visual-design` — visual quality elevation
  - `redesign-existing-projects` — audit-and-improve mode (not greenfield)
  - `minimalist-ui` — reference for clean, purposeful aesthetics
- **Source:** https://github.com/Leonxlnx/taste-skill (18.2k stars, MIT)
- **Use:** Activate relevant skill when doing visual audit or suggesting layout improvements in Phase 12

---

## Rejected Tools

| Tool | Reason |
|---|---|
| UI/UX Pro Max | Greenfield design-system generator — StackWise already has tokens/colors/fonts locked from Phase 10. Python CLI overhead not worth it for an audit-and-polish job. |
| Lighthouse MCP | Unnecessary — Playwright can drive a Lighthouse run programmatically. Phase 14's ≥90 performance check doesn't need a separate install. |
| axe accessibility MCP | Phase 14 QA doesn't include a formal a11y audit. Skip unless a specific a11y issue surfaces during Phase 12 review. |

---

## Quick Reference

```bash
# Start dev server
cd landing && npm run dev -- --port 4321
# (Falls back to 4322 if 4321 is taken)

# Playwright screenshots (via MCP tools in Claude)
# 1440px desktop: mcp__playwright__browser_resize(1440, 900) → navigate → screenshot
# 375px mobile:   mcp__playwright__browser_resize(375, 812)  → screenshot
# 390px iPhone14: mcp__playwright__browser_resize(390, 844)  → screenshot
# 768px tablet:   mcp__playwright__browser_resize(768, 1024) → screenshot
```
