---
phase: 90-tri-state-theme-control
plan: "03"
subsystem: docs
tags: [theme, integration-guide, theme_default, FOUC, CSP, optional-head-script]

requires:
  - phase: 90-tri-state-theme-control
    plan: "02"
    provides: "shell.ex .ThemeControl ColocatedHook + theme_default attr + data-theme-pending FOUC handling"
provides:
  - integration guide section 20 documenting theme persistence, theme_default attr, optional layer-3 head script, and CSP note
affects: [phase-91-design-system-docs]

tech-stack:
  added: []
  patterns:
    - "Integration guide extended with optional-feature documentation pattern (clearly marked optional, copy-paste ready)"

key-files:
  created: []
  modified:
    - prompts/rulestead-host-app-integration-seam.md

key-decisions:
  - "Section numbered 20 (next sequential after existing 19 TL;DR) to preserve guide ordering"
  - "system/pinned distinction leads the section — frames accurate baseline (no host action needed) before optional fast-path"
  - "theme_default documented as pure-server attr (no JS required for host seeding); localStorage precedence stated explicitly"
  - "CSP section covers both the colocated hook script-src requirement and the optional head snippet nonce"

metrics:
  duration: ~5min
  completed: 2026-06-04T09:15:00Z
  tasks: 1
  files_modified: 1
---

# Phase 90 Plan 03: Integration Guide — Theme Persistence Documentation Summary

**Added section 20 (Theme Persistence and Dark Mode) to the host integration guide: covers the theme_default attr on Shell.page/1, the optional layer-3 head script for pinned-mismatch fast-path, and CSP/nonce requirements for the runtime ColocatedHook**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-04T09:10:00Z
- **Completed:** 2026-06-04T09:15:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Appended section 20 "Theme Persistence and Dark Mode" to `prompts/rulestead-host-app-integration-seam.md`.
- Section covers four sub-topics:
  1. **How it works (no host action required):** system mode is flash-free via CSS `@media`; pinned mode uses `localStorage["rulestead_admin.theme"]` + `data-theme-pending` for an instant hook snap.
  2. **`theme_default` attribute:** `attr :theme_default, :string, default: "system"` on `Shell.page/1`; valid values `system | light | dark`; `localStorage` takes precedence over the attr; usage example with `<Shell.page theme_default="dark" ...>`.
  3. **Optional layer-3 `<head>` fast-path:** copy-paste `<script>` clearly marked "Optional"; explains it only improves pinned-mismatch on slow connections/devices; no-ops for system users and users with no stored preference; does not interfere with the hook.
  4. **CSP considerations:** documents `script-src` nonce requirement for the runtime ColocatedHook `<script>` tag; shows how to pass `script_csp_nonce` via session assigns; also covers adding `nonce=` to the optional head snippet.

## Task Commits

1. **Task 1: integration guide** — `303468b` (docs)

## Files Modified

- `/Users/jon/projects/rulestead/prompts/rulestead-host-app-integration-seam.md` — appended section 20 (101 lines added)

## Decisions Made

- **Section 20 (not 21):** Inserted after the existing section 19 TL;DR, maintaining sequential numbering.
- **Accurate framing of baseline:** System users are already flash-free with zero host action; the optional head script only covers the pinned-mismatch + slow-connection edge case. This framing prevents hosts from thinking they must add the fast-path.
- **CSP note covers both surfaces:** The colocated hook is the primary surface (always present); the optional head snippet is secondary (only if adopted). Both nonce paths documented.

## Deviations from Plan

None — plan executed exactly as written. All content specified in the plan's `<action>` block was incorporated; heading levels and document conventions match the existing guide style.

## Known Stubs

None — documentation only; no placeholder content.

## Threat Flags

No new network endpoints, auth paths, or file access patterns introduced. This plan modifies a documentation prompt file only (no code changes).

## Self-Check: PASSED

- `prompts/rulestead-host-app-integration-seam.md` — modified (confirmed)
- Task commit `303468b` — confirmed
- `grep -c 'theme_default' prompts/rulestead-host-app-integration-seam.md` — 6 (>= 2 required)
- `grep -c 'data-theme-pending' prompts/rulestead-host-app-integration-seam.md` — 2 (>= 1 required)
- `grep -c 'rulestead_admin\.theme' prompts/rulestead-host-app-integration-seam.md` — 2 (>= 1 required)
- `grep -c 'Optional' prompts/rulestead-host-app-integration-seam.md` — 2 (>= 1 required)
- `grep -cE 'CSP|nonce' prompts/rulestead-host-app-integration-seam.md` — 9 (>= 1 required)
- All five plan verification criteria: PASS

---

*Phase: 90-tri-state-theme-control*
*Completed: 2026-06-04*
