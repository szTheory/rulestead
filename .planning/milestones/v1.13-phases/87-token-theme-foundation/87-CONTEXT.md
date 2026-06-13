# Phase 87: Token Theme Foundation - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Decisions sourced from the user-approved implementation plan (`/Users/jon/.claude/plans/session-recap-inherited-micali.md`); autonomous run, hands-off.

<domain>
## Phase Boundary

Split the existing `rulestead_admin` CSS token layer (`rulestead_admin/priv/static/css/rulestead_admin.css`, `:root` block ~lines 38–178) into **theme-invariant** tokens (declared once) and **theme-variant** tokens (redeclared per theme), and author a complete, on-brand **mineral-dark** token set. After this phase, every later phase re-themes by reading tokens — no component-rule edits.

**In scope:** the token layer + the light/system-dark/explicit-dark/explicit-light cascade blocks + the dark token values. Verified by flipping `data-theme` in devtools and screenshotting representative screens (home, flags index, a detail screen) in both themes.

**Explicitly NOT in this phase:** no visible theme toggle/control (Phase 90), no persistence/JS hook (Phase 90), no component-rule edits or hardcoded-color remediation (Phase 88), no focus-ring unification (Phase 89). Component rules that already consume `var(--rs-*)` re-theme for free; the ~5% hardcoded-color hotspots are deliberately left for Phase 88.
</domain>

<decisions>
## Implementation Decisions

### Token split (invariant vs variant)
- **Theme-invariant** (stay in `:root`, declared once): typography families + scale (`--rs-font-*`, `--rs-text-*`, `--rs-leading-*`, `--rs-weight-*`, `--rs-tracking-*`), radius (`--rs-radius-*`), spacing/layout (`--rs-space-*`, `--rs-shell-max`, `--rs-section-gap`, `--rs-page-gap`), control sizing (`--rs-control-*`, `--rs-touch-target-min`), z-index ladder, motion (`--rs-motion-*`, `--rs-ease-*`), and structural scalars (`--rs-focus-ring-offset`, `--rs-disabled-opacity`).
- **Theme-variant** (redeclared per theme): the full neutral ramp `--rs-neutral-0…900`, all semantic surface/border/text aliases, all hard-hex brand + status colors (primary/accent/success/warning/error/critical families incl. hover/soft/bg-subtle/text/border/border-strong), all `--rs-shadow*`, `--rs-focus-ring` (+ a new `--rs-focus-ring-color`), `--rs-disabled-bg`, `--rs-disabled-text`. Introduce `--rs-overlay-veil` and `--rs-scrim` variant tokens (consumed by Phase 88).

### Theme scope (mounted-package discipline)
- Theme tokens live on `.rs-shell` and `[data-rulestead]` — **never** `:root` or `<html>`. The admin must not theme the host app.
- Set `color-scheme: light|dark` on the scope element per theme so native controls/scrollbars match without leaking to the host.
- Keep theme-invariant tokens on `:root` (harmless to the host — they're non-color and only consumed by `.rs-shell` descendants).

### Cascade (system-default, explicit-wins)
- Light is the default token set, declared on `.rs-shell, [data-rulestead]`.
- `@media (prefers-color-scheme: dark) { .rs-shell:not([data-theme]), [data-rulestead]:not([data-theme]) { …dark… } }` — system dark applies only when no explicit choice is pinned.
- `.rs-shell[data-theme="dark"], [data-rulestead][data-theme="dark"]` — pinned dark, beats system in both directions.
- `.rs-shell[data-theme="light"], [data-rulestead][data-theme="light"]` — pinned light, re-asserts light over a dark OS.
- The dark token set appears in two blocks (system `@media` + explicit `[data-theme="dark"]`); duplicate it verbatim and mark the pair with a CSS comment as synced (plain CSS has no `@apply`; ~110 lines once is acceptable, no build step).

### Dark palette (on-brand mineral-dark; from plan transformation rules)
- Neutral ramp purpose-built (not inverted): base `--rs-neutral-0` ~`#10161f` (deepest surface), ramp direction flips (0 darkest → 900 lightest), luminance steps compressed to avoid banding. `--rs-bg` darkest; `--rs-surface` one step up; `--rs-surface-muted/-faint` progressively lighter (elevation = lighter surface).
- Text: `--rs-text` off-white ~`#e8edf3` (not pure white — cuts halation); `--rs-text-muted` must clear 4.5:1 on `--rs-surface`; `--rs-text-placeholder` clears 3:1.
- Brand/status hard-hex re-tuned three ways each: (a) base/`text` lighten to 4.5:1 on dark (success → ~`#4ade80`/`#34d399` region, error → ~`#f87171`, warning → ~`#fbbf24`); (b) `-soft` fills become low-opacity (~10–14%) hue tints over the dark surface (not pale near-white); (c) `-border` tones darken/desaturate to a quiet edge. Keep `--rs-primary` saturated enough that white-on-primary stays ≥4.5:1 (likely ~`#3b82f6`, not darker).
- Shadows: `--rs-shadow*` redefined as deeper black + a 1px inset light hairline so elevation reads on dark.
- `--rs-focus-ring-color` lighter/higher-alpha on dark (consumed by Phase 89's unified ring).
- AA is a hard gate: every text/pill/border pair verified against the actual dark surface it renders on.

### Claude's Discretion
- Exact per-stop hex values of the dark neutral ramp and the precise desaturated brand/status hexes — chosen to satisfy the anchors above and WCAG AA, then verified. The plan gives transformation rules and anchors, not every hex.
- Internal ordering/comment structure of the refactored token blocks.
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead_admin/priv/static/css/rulestead_admin.css` — the single hand-authored static stylesheet (~4000 lines). Token `:root` block at ~38–178. BEM-ish `rs-` classes consume `var(--rs-*)` throughout. No build step; do not add Tailwind/CSS-in-JS.
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — `.rs-shell` scope root (~line 42), already carries a `data-env-tone` attribute (precedent for attribute-driven theming).
- `rulestead_admin/lib/rulestead_admin/status_tone.ex` — single source of status tone vocabulary (positive/warning/critical/neutral/muted/accent) consumed by `.rs-badge[data-tone]`.

### Established Patterns
- All color flows through CSS custom properties; redeclaring tokens re-themes ~95% of the UI with no component edits.
- `@media (prefers-reduced-motion)` already respected (~line 3718) — leave intact.

### Integration Points
- Token blocks are the only files touched this phase. The `--rs-overlay-veil`/`--rs-scrim`/`--rs-focus-ring-color` tokens introduced here are consumed by Phases 88 and 89.
- Hardcoded-color hotspots to LEAVE for Phase 88: inline `box-shadow rgba(26,35,50,…)` (~12 sites), gradient veils (~853, 2426), cmdk backdrop (~3859), input focus `outline` (~904), inline focus tints `rgba(37,99,235,…)`.

</code_context>

<specifics>
## Specific Ideas

- Authoritative spec: `/Users/jon/.claude/plans/session-recap-inherited-micali.md` (§Approach 1 + dark-value rules) and the design-agent doc it summarizes.
- Brand: "calm, infrastructure-grade" — mineral neutrals + controlled blue (#2563eb light) + restrained ember accent (#c45c26 light); Sora/Inter/IBM Plex Mono.
- Verification: flip `data-theme="dark"` on `.rs-shell` in devtools across home + flags index + a detail screen; screenshot both themes; confirm `:root`/`<html>` carry no dark color overrides; first contrast pass on representative token pairs.
</specifics>

<deferred>
## Deferred Ideas

- Visible tri-state theme control + localStorage persistence + FOUC handling → Phase 90.
- Routing the hardcoded-color hotspots through tokens → Phase 88.
- Unified `:focus-visible` two-stop ring → Phase 89.
- Token-contract documentation + the full contrast reference fixture → Phase 91.
- Per-host theme branding overrides, forced-colors mode → Future (THM-07 / A11Y-04).
</deferred>
