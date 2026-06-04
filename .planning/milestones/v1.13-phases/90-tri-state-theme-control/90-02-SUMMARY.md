---
phase: 90-tri-state-theme-control
plan: "02"
subsystem: ui
tags: [theme, localStorage, colocated-hook, aria, radiogroup, FOUC, shell, CSS]

requires:
  - phase: 90-tri-state-theme-control
    plan: "01"
    provides: "file:// fixture + 11-test Playwright spec covering THM-02/THM-04 behaviors"
provides:
  - shell.ex .ThemeControl ColocatedHook (mounted+updated+destroyed) with localStorage persistence
  - segmented System/Light/Dark radiogroup in shell header (always-visible 4th context section)
  - data-theme-pending FOUC suppression wired end-to-end (HEEx attr + CSS + hook removal)
  - attr :theme_default passed through to hook via data-theme-default
affects: [90-03, phase-91-design-system-docs, phase-94-micro-animations]

tech-stack:
  added: []
  patterns:
    - "Runtime ColocatedHook (.ThemeControl) mirroring .CmdK structure exactly"
    - "localStorage VALID whitelist guard: VALID.includes(v) ? v : themeDefault (T-90-01)"
    - "system mode = removeAttribute(data-theme); never setAttribute(data-theme, system)"
    - "data-theme-pending removed synchronously in mounted() after applyTheme — FOUC snap"
    - "updated() re-syncs aria-checked/tabindex after LiveView morphdom patches"
    - "closest('.rs-shell') traversal for data-theme + data-theme-pending operations"

key-files:
  created: []
  modified:
    - rulestead_admin/lib/rulestead_admin/components/shell.ex
    - rulestead_admin/priv/static/css/rulestead_admin.css

key-decisions:
  - "Hook placed as last child of .rs-shell, outside :if={@palette_groups != []} guard — always in DOM for ColocatedHook registration"
  - "readTheme() falls back to ctrl.dataset.themeDefault (from @theme_default attr) when localStorage empty or invalid — lets host seed corporate default"
  - "CSS grid extended from repeat(3, auto) to repeat(4, auto) at 900px+ to accommodate 4th context section"
  - "FOUC suppression: [data-theme-pending] and [data-theme-pending] * { transition: none !important } — Phase 94 micro-animations unaffected (attr gone before animation CSS applied)"

metrics:
  duration: ~15min
  completed: 2026-06-04T09:02:30Z
  tasks: 3
  files_modified: 2
---

# Phase 90 Plan 02: ThemeControl ColocatedHook + Shell Integration Summary

**Delivered .ThemeControl runtime ColocatedHook with localStorage persistence, segmented radiogroup in shell header, and FOUC suppression via data-theme-pending — all 11 theme-control + 5 theme-cascade Playwright tests pass**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-04T08:47:00Z
- **Completed:** 2026-06-04T09:02:30Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added `attr :theme_default, :string, default: "system"` to `Shell.page/1` and rendered it as `data-theme-default` on the radiogroup so the hook can use a host-supplied default when localStorage is empty.
- Added `data-theme-pending` as a static valueless attribute on `.rs-shell` in HEEx — present from first paint, removed synchronously by the hook in `mounted()` after applying `data-theme`, so pinned-theme corrections are instant snaps with no visible animated wipe.
- Added a new always-visible 4th `<section class="rs-shell__context" aria-label="Theme">` to the shell header context cluster containing a `role="radiogroup"` segmented control with three `role="radio"` buttons (System / Light / Dark) wired via `phx-hook=".ThemeControl"`.
- Added `.ThemeControl` ColocatedHook script (mirroring `.CmdK` structure exactly) as the last child inside `.rs-shell`, outside any `:if` guard:
  - `mounted()`: reads localStorage with VALID whitelist → applyTheme (system=removeAttribute, light/dark=setAttribute) → removeAttribute("data-theme-pending") synchronously → syncAria → registers matchMedia listener (no-ops unless mode==="system") → wires click + roving-tabindex keydown handlers
  - `updated()`: calls `this._syncAria()` — re-syncs aria-checked/tabindex after LiveView morphdom patches reset child state
  - `destroyed()`: removes matchMedia listener via stored `this._mqListener` reference
- Extended shell header CSS grid from `repeat(3, auto)` to `repeat(4, auto)` at the 900px breakpoint.
- Added `.rs-theme-control__group` and `.rs-theme-control__opt` pill styles using only `--rs-*` tokens (border, surface, text-muted inactive; primary fill + primary-soft bg when `aria-checked="true"`; focus-visible ring).
- Added `[data-theme-pending], [data-theme-pending] * { transition: none !important }` FOUC suppression rule.

## Task Commits

1. **Task 1: shell.ex** — `93141d5` (feat)
2. **Task 2: rulestead_admin.css** — `a8af6a6` (feat)
3. **Task 3: Playwright verification** — (no commit; spec suite is green against existing files from plan 01)

## Files Modified

- `/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/components/shell.ex` — attr :theme_default, data-theme-pending on .rs-shell, Theme context section, .ThemeControl ColocatedHook script
- `/Users/jon/projects/rulestead/rulestead_admin/priv/static/css/rulestead_admin.css` — repeat(4, auto) grid, .rs-theme-control__opt pill styles, [data-theme-pending] transition suppression

## Decisions Made

- **Hook placement outside `:if` guard:** The ColocatedHook `<script>` tag must always be in the DOM for runtime hook registration. Placed as the final child of `.rs-shell`, after `<div :if={@palette_groups != []}>...</div>`.
- **`theme_default` fallback in readTheme():** `ctrl.dataset.themeDefault || "system"` used as the fallback when localStorage is empty or contains an invalid value. Allows host to seed a corporate default without requiring the layer-3 head script.
- **`data-theme-pending` cleared synchronously:** No `requestAnimationFrame` wrapper — removal happens in the same JS task as `applyTheme()`, before the browser can paint an intermediate state.
- **repeat(4, auto) at 900px+:** Added 4th auto column to accommodate the always-visible Theme context section alongside the conditionally rendered Access, Environment, and Tenant sections.

## Deviations from Plan

None — plan executed exactly as written. All four shell.ex edits (A-D) and both CSS edits (A-B) applied in order.

## Known Stubs

None — the hook reads live localStorage and applies real `data-theme` values. No placeholder data.

## Threat Flags

No new network endpoints, auth paths, or file access patterns introduced. The localStorage whitelist guard (T-90-01 mitigation: `VALID.includes(v) ? v : ...`) is present in `readTheme()` as specified by the threat model.

## Self-Check: PASSED

- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — modified (confirmed)
- `rulestead_admin/priv/static/css/rulestead_admin.css` — modified (confirmed)
- Task 1 commit `93141d5` — confirmed
- Task 2 commit `a8af6a6` — confirmed
- `mix compile --warnings-as-errors` — exit 0
- `grep -c '\.ThemeControl' shell.ex` — 2
- `grep -c 'data-theme-pending' shell.ex` — 2
- `grep -c 'theme_default' shell.ex` — 2
- `grep -c 'rs-theme-control__opt' rulestead_admin.css` — 4
- `grep -c 'data-theme-pending' rulestead_admin.css` — 3
- `grep -c 'repeat(4, auto)' rulestead_admin.css` — 1
- `data-theme="system"` occurrences — 0
- `grep -c 'updated()' shell.ex` — 1
- Playwright theme-control.spec.ts — 11/11 pass
- Playwright theme-cascade.spec.ts — 5/5 pass
- Total: 16/16 pass

---

*Phase: 90-tri-state-theme-control*
*Completed: 2026-06-04*
