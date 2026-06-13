# Phase 90: Tri-State Theme Control + Persistence + FOUC - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Decisions sourced from the user-approved plan (`/Users/jon/.claude/plans/session-recap-inherited-micali.md` §Approach 2). Autonomous, hands-off.

<domain>
## Phase Boundary

Add the user-facing tri-state theme control + per-device persistence + FOUC handling to the mounted `rulestead_admin` shell. Phases 87-89 made the tokens/cascade/focus theme-aware (toggled via `data-theme` in devtools); this phase lets a real operator pick **System / Light / Dark** and have it persist and apply correctly on the next load.

**In scope:**
- A **segmented control** (`role="radiogroup"`, 3 options System/Light/Dark, arrow-key nav, `aria-checked`) in the shell header context cluster (`shell.ex`, near the Access/Environment chips).
- A **colocated LiveView JS hook** (following the EXISTING `.CmdK` ColocatedHook runtime pattern at `shell.ex:231`) that: reads/writes `localStorage["rulestead_admin.theme"]` (`system|light|dark`); sets/removes `data-theme` on `.rs-shell` accordingly; updates `aria-checked`; subscribes to `matchMedia('(prefers-color-scheme: dark)')` and live-updates ONLY while in System mode.
- **FOUC handling:** System users already flash-free (CSS `@media` resolves at first paint, Phases 87-88). For pinned users, mark the scope `data-theme-pending` until the hook sets the real value; under `[data-theme-pending]` suppress transitions so the correction is an instant snap (no animated wipe). Set `data-theme` synchronously in `mounted()` before rAF.
- Optional `attr :theme_default, :string, default: "system"` on the shell `page/1` so a host with a global theme can supply an initial value (used by the optional host fast-path).
- Document an **optional** copy-paste host `<head>` script (reads localStorage, sets an early attribute) for adopters who want zero flash on pinned-mismatch — documented, NOT required.
- CSS for the segmented control + the `[data-theme-pending] * { transition: none }` suppression (using existing tokens).

**OUT OF SCOPE:** changing token values or the cascade (87 owns); focus ring (89 done); design-system docs/fixture (91); IA/home (92); per-screen polish (93); motion/animation polish (94) — though the no-transition-snap here must not fight Phase 94's real animations (note the interaction).
</domain>

<decisions>
## Implementation Decisions

### Persistence + control
- localStorage key `rulestead_admin.theme`, values `system|light|dark`. Per-device, client-only — NO cookies, NO host session, NO server round-trip (pure client preference).
- Colocated `ColocatedHook` runtime hook (mirror the `.CmdK` hook in shell.ex:231) named e.g. `.ThemeControl`, attached to the segmented control element via `phx-hook=".ThemeControl"`.
- Segmented control: `role="radiogroup"`, three `role="radio"`/button options, roving tabindex + arrow-key nav, `aria-checked` on the active option, accessible label "Theme". Reuse the existing `.rs-flag-subnav__tab`/segmented visual pattern for consistency.
- On select: write localStorage → set/remove `data-theme` on `.rs-shell` (remove for `system`) → update aria-checked. On `system`: remove `data-theme` and let `matchMedia` drive; add a matchMedia listener that no-ops unless current mode is `system`.

### FOUC
- Baseline (no host action): layers 1-2 from the plan. System = flash-free via CSS `@media`. Pinned = `data-theme-pending` + transition-suppression → instant snap in `mounted()`. The hook removes `data-theme-pending` after applying.
- Layer 3 (optional, documented): a host `<head>` snippet + a bridge rule (e.g. `:root[data-rs-theme="dark"] .rs-shell:not([data-theme])`) — documented in the integration guide, NOT shipped as required.

### Claude's Discretion
- Exact hook name, element ids/data-attrs, and the precise markup of the segmented control (match shell.ex conventions).
- Whether `data-theme-pending` is set in the HEEx (server render) and cleared by the hook, vs set/cleared entirely client-side — pick whatever gives the cleanest no-flash for pinned users given the hook runs post-mount.
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`shell.ex:231`** — `<script :type={Phoenix.LiveView.ColocatedHook} name=".CmdK" runtime>` — the PROVEN pattern for shipping self-contained JS from the mounted package (no host build step, no host LiveSocket wiring needed for `.`-prefixed colocated hooks). Mirror it for `.ThemeControl`.
- **`shell.ex:42`** — `<div class="rs-shell" data-env-tone={@env_tone}>` — the scope root; `data-theme`/`data-theme-pending` go here. Header context cluster (~lines 55-105) is where the control mounts.
- Phase 87-89 tokens + cascade: `data-theme="dark|light"` already fully themes the UI; `:not([data-theme])` system-dark works.
- Static harness already exercises `setTheme`/`clearTheme` + matchMedia emulation; Playwright `theme-cascade.spec.ts` covers the cascade. New behavior to test: persistence across reload + the control's a11y + no-flash snap.

### Established Patterns
- Colocated `.Name` runtime hooks; data-attribute-driven JS (`data-rs-cmdk-*`); Navigation as single source for nav/cmdk.
- BEM `rs-*` CSS; segmented/subnav tab styling exists.

### Integration Points
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` (control markup + colocated hook + `theme_default` attr).
- `rulestead_admin/priv/static/css/rulestead_admin.css` (segmented-control styling + `[data-theme-pending]` transition suppression).
- Integration guide (`prompts/rulestead-admin-ux-and-operator-ia.md` §9 or a Phoenix-integration guide) — document the optional host head-script + `theme_default`.
</code_context>

<specifics>
## Specific Ideas
- Verify in the REAL mounted admin if reachable (the hook only runs when LiveView mounts) OR via a Playwright test that loads a page including the control + the hook's JS logic and asserts: selecting Dark sets `data-theme=dark` + persists across reload (localStorage); selecting System removes `data-theme` and follows `matchMedia`; pinned-mismatch shows no animated wipe (transitions suppressed during snap). Keyboard: arrow keys move selection, aria-checked tracks.
- The local demo has the DB-conflict gotcha; prefer a focused Playwright harness that includes the control markup + an inlined copy of the hook logic, OR boot the demo if it comes up cleanly. Document whichever path is used.
- WCAG: control meets focus (Phase 89 ring), labels, aria-checked; contrast AA both themes.
</specifics>

<deferred>
## Deferred Ideas
- Per-host theme branding palette → Future (THM-07).
- Motion choreography of the theme switch beyond the no-flash snap → Phase 94 (must not conflict with `[data-theme-pending]` suppression).
- Design-system documentation of the control → Phase 91.
</deferred>
