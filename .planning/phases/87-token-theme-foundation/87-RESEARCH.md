# Phase 87: Token Theme Foundation — Research

**Researched:** 2026-06-04
**Domain:** CSS custom-property theming, WCAG AA contrast, mounted-package scope discipline
**Confidence:** HIGH — all findings verified directly from the source CSS file and authoritative plan documents

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Token split — invariant:** typography families + scale, radius, spacing/layout, control sizing, z-index ladder, motion/easing, structural scalars (`--rs-focus-ring-offset`, `--rs-disabled-opacity`). These stay in `:root`, declared once.
- **Token split — variant:** full neutral ramp, all semantic surface/border/text aliases, all hard-hex brand + status colors (+ hover/soft/bg-subtle/text/border families), all `--rs-shadow*`, `--rs-focus-ring` + new `--rs-focus-ring-color`, `--rs-disabled-bg`, `--rs-disabled-text`, new `--rs-overlay-veil`, `--rs-scrim`.
- **Scope:** Theme tokens live on `.rs-shell` and `[data-rulestead]` — **never** `:root` or `<html>`.
- **`color-scheme`:** Set per-theme on the scope element, not `:root` — no host leak.
- **Cascade:** light default on `.rs-shell, [data-rulestead]`; system dark via `@media (prefers-color-scheme: dark) { :not([data-theme]) }`; explicit `[data-theme="dark"]` and `[data-theme="light"]` override OS.
- **Duplicate dark block:** The dark token set appears verbatim in both the system `@media` block and the explicit `[data-theme="dark"]` block. Mark the pair with a comment. Plain CSS has no `@apply`; ~110 lines is acceptable.
- **Dark palette anchors:** base `--rs-neutral-0` ~`#10161f`, ramp direction flips (0 = darkest), `--rs-text` ~`#e8edf3`, `--rs-primary` stays ~`#3b82f6` (white-on-primary ≥4.5:1), brand/status lighten to AA. Shadows = deeper black + 1px inset hairline.
- **No-build discipline:** Hand-authored BEM `rs-*` CSS, no Tailwind, no CSS-in-JS, no build step. Non-negotiable.

### Claude's Discretion

- Exact per-stop hex values of the dark neutral ramp and precise desaturated brand/status hexes — chosen to satisfy the anchors above and WCAG AA, then verified.
- Internal ordering and comment structure of the refactored token blocks.

### Deferred Ideas (OUT OF SCOPE)

- Visible tri-state theme control + localStorage persistence + FOUC handling → Phase 90.
- Routing hardcoded-color hotspots through tokens → Phase 88.
- Unified `:focus-visible` two-stop ring → Phase 89.
- Token-contract documentation + full contrast reference fixture → Phase 91.
- Per-host theme branding overrides, forced-colors mode → Future (THM-07 / A11Y-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THM-01 | Operator sees dark theme automatically when OS reports `prefers-color-scheme: dark` | Cascade block 2: `@media (prefers-color-scheme: dark) { .rs-shell:not([data-theme]) … }` — verified pattern, no JS needed |
| THM-03 | Explicit Light or Dark choice overrides the OS; "System" tracks live OS changes | Cascade blocks 3+4: `[data-theme="dark"]` and `[data-theme="light"]` beat media query by specificity; Phase 90 sets the attribute; this phase authors the token sets those selectors use |
| THM-05 | Theme scoped to `.rs-shell`/`[data-rulestead]`, never alters host styling | Variant tokens on scope selectors only; `color-scheme` on scope element only; invariant tokens on `:root` are non-color, harmless |
| THM-06 | Dark theme is on-brand: mineral-dark surfaces, desaturated brand, elevation via lighter surfaces + hairline borders | Full dark token set authored here — verified hex values against WCAG AA on target surfaces |
</phase_requirements>

---

## Summary

Phase 87 is a pure CSS refactor of the `rulestead_admin` token layer. The file being edited is `rulestead_admin/priv/static/css/rulestead_admin.css` (3,997 lines). The token block is currently entirely in `:root` (lines 38–178). Nothing else in the codebase changes this phase.

The work has three parts: (1) move color/surface/border/text/shadow/focus tokens out of `:root` and onto `.rs-shell, [data-rulestead]` as the light default, (2) author the system-dark `@media` block and the explicit `[data-theme="dark"]` block with a complete mineral-dark token set, and (3) author the explicit `[data-theme="light"]` block that re-asserts the light values for OS-dark users who pin light. The dark token set appears verbatim in two selector contexts — that duplication is deliberate and acceptable at ~110 lines.

**Primary recommendation:** Work strictly token-layer-only. Every component rule that already consumes `var(--rs-*)` re-themes for free. The ~21 inline rgba literals scattered through component rules are explicitly left for Phase 88. Introducing the three new tokens (`--rs-focus-ring-color`, `--rs-overlay-veil`, `--rs-scrim`) in the dark block now costs nothing and unblocks Phases 88 and 89.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token layer split (invariant vs variant) | CSS file | — | Pure static CSS refactor; no runtime logic |
| Light default token set | `.rs-shell` scope block | — | Moves color tokens off `:root` to scope element |
| System dark via media query | `@media` block inside CSS | — | `prefers-color-scheme` resolves at first paint, no JS |
| Explicit theme override | CSS attribute selectors | LiveView shell attr (Phase 90) | CSS owns the rendering; Phase 90 sets the attribute |
| `color-scheme` native theming | Scope element CSS | — | Must not be on `:root`; leaks scrollbars to host otherwise |
| Scope containment (no host leak) | CSS selector discipline | — | All variant tokens scoped to `.rs-shell`/`[data-rulestead]` |

---

## 1. Exact Current Token Inventory

Verified by direct read of `:root` block, lines 38–178. [VERIFIED: source CSS file]

### Theme-Invariant (stay in `:root`)

**Typography families (lines 40–42)**
```
--rs-font-display, --rs-font-sans, --rs-font-mono
```

**Typography scale (lines 97–115)**
```
--rs-text-2xs, --rs-text-xs, --rs-text-sm, --rs-text-base, --rs-text-md,
--rs-text-lg, --rs-text-xl, --rs-text-2xl
--rs-leading-tight, --rs-leading-snug, --rs-leading-normal, --rs-leading-relaxed
--rs-weight-normal, --rs-weight-medium, --rs-weight-semibold, --rs-weight-bold
--rs-tracking-normal, --rs-tracking-wide, --rs-tracking-wider
```

**Radius (lines 117–122)**
```
--rs-radius-sm, --rs-radius-md, --rs-radius-lg, --rs-radius-xl, --rs-radius-full
```

**Layout + spacing (lines 130–142)**
```
--rs-shell-max: 1200px
--rs-space-1 … --rs-space-10  (0.25rem steps)
--rs-section-gap: 1rem
--rs-page-gap: 1.25rem
```

**Control sizing (lines 144–149)**
```
--rs-control-h: 2.5rem, --rs-control-h-sm: 2rem, --rs-control-h-lg: 3rem
--rs-control-px: 0.75rem
--rs-touch-target-min: 44px
```

**Focus structural scalars (lines 153–154) — note: `--rs-focus-ring` is VARIANT**
```
--rs-focus-ring-offset: 2px          ← invariant (distance, not color)
--rs-disabled-opacity: 0.55          ← invariant (scalar)
```

**Z-index ladder (lines 159–165)**
```
--rs-z-base: 0, --rs-z-raised: 1, --rs-z-dropdown: 100, --rs-z-sticky: 200,
--rs-z-overlay: 300, --rs-z-modal: 400, --rs-z-toast: 500
```

**Motion (lines 169–177)**
```
--rs-motion-fast: 150ms, --rs-motion-base: 200ms
--rs-motion-slow: 320ms, --rs-motion-slower: 480ms
--rs-ease-standard, --rs-ease-out, --rs-ease-in, --rs-ease-in-out, --rs-ease-emphasis
```

### Theme-Variant (move to `.rs-shell` / redeclare per theme)

**Neutral ramp (lines 44–55) — 10 stops, note gap at 800**
```
--rs-neutral-0:   #ffffff
--rs-neutral-25:  #f8fafc
--rs-neutral-50:  #f4f6f8
--rs-neutral-100: #eef1f5
--rs-neutral-200: #e7ebf0
--rs-neutral-300: #d8dee6
--rs-neutral-400: #b8c2cf
--rs-neutral-500: #99a3af
--rs-neutral-600: #5c6b7a
--rs-neutral-700: #263241
--rs-neutral-900: #1a2332     ← no --rs-neutral-800 stop
```

**Semantic surface/border/text aliases (lines 58–67)**
```
--rs-bg:               var(--rs-neutral-50)
--rs-surface:          var(--rs-neutral-0)
--rs-surface-muted:    var(--rs-neutral-100)
--rs-surface-faint:    var(--rs-neutral-25)
--rs-border:           var(--rs-neutral-300)
--rs-border-subtle:    var(--rs-neutral-200)
--rs-border-strong:    var(--rs-neutral-400)
--rs-text:             var(--rs-neutral-900)
--rs-text-muted:       var(--rs-neutral-600)
--rs-text-placeholder: var(--rs-neutral-500)
```

**Brand colors (lines 70–74)**
```
--rs-primary:       #2563eb
--rs-primary-hover: #1d4ed8
--rs-primary-soft:  #dbeafe
--rs-on-primary:    #ffffff
--rs-accent:        #c45c26
--rs-accent-soft:   #fde8dc
```

**Status — success (lines 76–81)**
```
--rs-success:           #15803d
--rs-success-hover:     #166534
--rs-success-soft:      #dcfce7
--rs-success-bg-subtle: #f7fff9
--rs-success-text:      #047857
--rs-success-border:    #86efac
```

**Status — warning (lines 83–85)**
```
--rs-warning:        #b45309
--rs-warning-soft:   #fef3c7
--rs-warning-text:   #a16207
--rs-warning-border: #fcd34d
```

**Status — error/critical (lines 86–94)**
```
--rs-error:              #b91c1c
--rs-error-hover:        #991b1b
--rs-critical:           #b91c1c    ← alias for error; same value
--rs-error-soft:         #fee2e2
--rs-error-bg-subtle:    #fff7f7
--rs-error-text:         #be123c
--rs-error-text-strong:  #7f1d1d
--rs-error-border:       #fca5a5
--rs-error-border-strong:#fecaca
```

**Shadows (lines 125–127)**
```
--rs-shadow-sm:    0 1px 2px rgba(26, 35, 50, 0.05)
--rs-shadow:       0 1px 2px rgba(26, 35, 50, 0.06), 0 8px 24px rgba(26, 35, 50, 0.06)
--rs-shadow-panel: 0 1px 2px rgba(26, 35, 50, 0.04), 0 12px 32px rgba(26, 35, 50, 0.07)
```
Note: these already embed hard rgba in the `:root` definition — acceptable in the variant block since they change per theme. Remediation of component-level inline shadows is Phase 88.

**Focus + disabled (lines 152–156)**
```
--rs-focus-ring:     0 0 0 3px rgba(37, 99, 235, 0.35)    ← variant (color)
--rs-disabled-bg:    var(--rs-neutral-100)                 ← variant
--rs-disabled-text:  var(--rs-neutral-500)                 ← variant
```
`--rs-focus-ring-offset: 2px` and `--rs-disabled-opacity: 0.55` are invariant (kept in `:root`).

**New tokens to introduce this phase (consumed by Phases 88 + 89)**
```
--rs-focus-ring-color    (variant — replaces raw rgba in --rs-focus-ring for Phase 89)
--rs-overlay-veil        (variant — for gradient veil patterns; Phase 88 consumes)
--rs-scrim               (variant — for cmdk backdrop; Phase 88 consumes)
```

**Component-local layout tokens (not in :root, already scoped locally)**
```
--rs-timeline-time-width  (line 3199, defined inside .rs-timeline component block)
--rs-timeline-marker-size (line 3200, same scope)
```
These are structural (not color) and component-scoped — leave in place, no action needed.

---

## 2. Cascade Mechanics

### The four-block structure

[VERIFIED: session-recap-inherited-micali.md §Approach 1]

```css
/* ── BLOCK 1: Light default (no media query, no modifier) ─────────────── */
.rs-shell,
[data-rulestead] {
  color-scheme: light;
  /* all variant tokens — light values */
}

/* ── BLOCK 2: System dark (media query, no pinned choice) ─────────────── */
@media (prefers-color-scheme: dark) {
  .rs-shell:not([data-theme]),
  [data-rulestead]:not([data-theme]) {
    color-scheme: dark;
    /* dark token set — VERBATIM COPY of Block 3 */
    /* !! SYNCED PAIR: keep this block identical to [data-theme="dark"] below !! */
  }
}

/* ── BLOCK 3: Explicit dark (pinned, beats OS in both directions) ─────── */
.rs-shell[data-theme="dark"],
[data-rulestead][data-theme="dark"] {
  color-scheme: dark;
  /* dark token set — VERBATIM COPY of Block 2 */
  /* !! SYNCED PAIR: keep this block identical to @media dark above !! */
}

/* ── BLOCK 4: Explicit light (re-asserts light over dark OS) ─────────── */
.rs-shell[data-theme="light"],
[data-rulestead][data-theme="light"] {
  color-scheme: light;
  /* light token set — VERBATIM COPY of Block 1 */
  /* !! SYNCED PAIR: keep this block identical to .rs-shell default above !! */
}
```

### Why `:not([data-theme])` is the key

Block 2 uses `.rs-shell:not([data-theme])`. When `data-theme` is absent (System mode), the media query applies dark on dark-OS and light on light-OS — both correct. When `data-theme` is present (pinned), Block 2 is suppressed; Block 3 or Block 4 wins regardless of OS. This is the "explicit-wins" guarantee.

### Specificity accounting

- Block 1: specificity (0,1,0) — one class
- Block 2: specificity (0,1,0) inside `@media` — same weight as Block 1, but media query constrains it
- Block 3: specificity (0,1,1) — class + attribute — **beats Block 2 at same OS condition because higher specificity**
- Block 4: specificity (0,1,1) — same as Block 3

Block 4 (explicit light) beats Block 2 (system dark) even without the `:not([data-theme])` guard — the attribute selector wins by specificity. The guard on Block 2 is belt-and-suspenders; it also avoids the media-query block matching unnecessarily when explicitly pinned.

### `color-scheme` scope discipline

`color-scheme: light|dark` on `.rs-shell` (not `:root`) tells the browser to theme native controls (scrollbars, date pickers, select chrome) to match the admin's theme — without affecting the host app. This is safe: the host continues to inherit from its own `:root`. [ASSUMED: `color-scheme` on a non-root element is well-supported in modern browsers — Chromium 89+, Firefox 96+, Safari 15+; adequate for operator tooling target.]

### `[data-rulestead]` selector

This selector appears in the cascade spec from CONTEXT.md and session-recap-inherited-micali.md but is **not currently used** anywhere in the codebase — neither in CSS nor in any Elixir template. It is forward-compatible for Phase 90 (or for host-integrated mounts). It must be introduced in all four blocks this phase even though no element carries it yet. No Elixir change needed this phase.

### Synced-pair maintenance

Blocks 2 and 3 carry identical token declarations. The comment `/* !! SYNCED PAIR: keep this block identical to … !! */` is the only maintenance mechanism — plain CSS cannot `@apply` one block's contents into another. The planner must treat them as a matched unit: any token edit in one requires an identical edit in the other. At ~110 variant token declarations, duplication adds ~110 lines to the file (~3% overhead at the current ~4000-line size).

---

## 3. Dark Value Derivation

### Dark neutral ramp — mineral dark

Anchors from plan [VERIFIED: session-recap-inherited-micali.md]: base `#10161f`, ramp direction flips (0 = darkest), compressed luminance steps. Purpose-built, not inverted from light.

The light ramp has 10 stops spanning #ffffff to #1a2332. The dark ramp needs the same 10 stop names covering approximately 18–88% luminance (compressed vs light's 0–94% span) to avoid banding.

**Proposed dark neutral ramp** [ASSUMED — verify AA against each use]:

```
--rs-neutral-0:   #10161f    ← bg base (deepest surface) — anchor from plan
--rs-neutral-25:  #141c27    ← surface-faint (one step up)
--rs-neutral-50:  #19222e    ← bg (app background)
--rs-neutral-100: #1f2a38    ← surface-muted
--rs-neutral-200: #253243    ← border-subtle
--rs-neutral-300: #2e3d52    ← border
--rs-neutral-400: #3d5168    ← border-strong
--rs-neutral-500: #7a8fa3    ← text-placeholder (must clear 3:1 on --rs-surface)
--rs-neutral-600: #a8b9ca    ← text-muted (must clear 4.5:1 on --rs-surface)
--rs-neutral-900: #e8edf3    ← text (off-white anchor from plan)
```

Note the gap at 800 is preserved from the light ramp. All hex values are proposals; exact verification against target surfaces is the Phase 87 success gate.

**Semantic surface/border/text aliases in dark** [ASSUMED — derived from ramp above]:
```
--rs-bg:               var(--rs-neutral-50)     → #19222e
--rs-surface:          var(--rs-neutral-25)     → #141c27  (one step lighter than bg)
--rs-surface-muted:    var(--rs-neutral-100)    → #1f2a38  (elevation = lighter)
--rs-surface-faint:    var(--rs-neutral-0)      → #10161f  (lowest — or same as neutral-25)
--rs-border:           var(--rs-neutral-300)    → #2e3d52
--rs-border-subtle:    var(--rs-neutral-200)    → #253243
--rs-border-strong:    var(--rs-neutral-400)    → #3d5168
--rs-text:             var(--rs-neutral-900)    → #e8edf3
--rs-text-muted:       var(--rs-neutral-600)    → #a8b9ca  (verify 4.5:1 on surface)
--rs-text-placeholder: var(--rs-neutral-500)    → #7a8fa3  (verify 3:1 on surface)
```

Important: in dark mode, `--rs-surface-faint` should be at or near the darkest level — empty-state backgrounds, page wells, and alternate-row fills should appear sunken (darker), not raised. This is the opposite of light mode. The alias to `--rs-neutral-0` achieves that.

### Brand/primary dark

`--rs-primary` must stay saturated for white-on-primary buttons at ≥4.5:1. [ASSUMED — verify contrast]:
```
--rs-primary:       #3b82f6    ← plan anchor (~WCAG 4.5:1 white on #3b82f6 = ~4.56:1 verify)
--rs-primary-hover: #60a5fa    ← lighter on hover (dark surface, lighter = more vivid)
--rs-primary-soft:  rgba(59, 130, 246, 0.12)   ← ~12% hue tint over dark surface
--rs-on-primary:    #ffffff
--rs-accent:        #e8834a    ← desaturated ember, lightened for dark
--rs-accent-soft:   rgba(232, 131, 74, 0.12)   ← ~12% hue tint
```

Note: `--rs-primary-soft` switches from a flat near-white hex to `rgba()` in dark mode. This is intentional: a flat `#dbeafe` on `#141c27` would look anaemic and wrong; a 12% tint of the actual hue reads as a genuine color-keyed surface.

### Status colors dark — three-move rule

Each status family gets: (a) base/text lightened to ≥4.5:1 on `--rs-surface`, (b) soft fill → low-alpha hue tint (~12%), (c) border darkened/desaturated to quiet edge. [ASSUMED — verify AA]:

**Success (green):**
```
--rs-success:           #4ade80    ← ~plan anchor; verify 4.5:1 on #141c27
--rs-success-hover:     #86efac
--rs-success-soft:      rgba(74, 222, 128, 0.12)
--rs-success-bg-subtle: rgba(74, 222, 128, 0.06)
--rs-success-text:      #4ade80    ← same as base (already light enough)
--rs-success-border:    #166534    ← dark desaturated green edge
```

**Warning (amber):**
```
--rs-warning:        #fbbf24    ← plan anchor; verify 4.5:1 on #141c27
--rs-warning-soft:   rgba(251, 191, 36, 0.12)
--rs-warning-text:   #fbbf24
--rs-warning-border: #78350f    ← dark desaturated amber edge
```

**Error/critical (red):**
```
--rs-error:              #f87171    ← plan anchor; verify 4.5:1 on #141c27
--rs-error-hover:        #fca5a5
--rs-critical:           #f87171    ← mirror error as in light
--rs-error-soft:         rgba(248, 113, 113, 0.12)
--rs-error-bg-subtle:    rgba(248, 113, 113, 0.06)
--rs-error-text:         #f87171
--rs-error-text-strong:  #fca5a5
--rs-error-border:       #7f1d1d    ← dark desaturated red edge
--rs-error-border-strong:#991b1b
```

### Shadows dark

[VERIFIED: session-recap-inherited-micali.md §1 dark-value rules]: deeper black + 1px inset light hairline so elevation reads on dark.

```css
--rs-shadow-sm:    0 1px 2px rgba(0, 0, 0, 0.35),
                   inset 0 1px 0 rgba(255, 255, 255, 0.04);
--rs-shadow:       0 1px 3px rgba(0, 0, 0, 0.4),
                   0 8px 24px rgba(0, 0, 0, 0.32),
                   inset 0 1px 0 rgba(255, 255, 255, 0.05);
--rs-shadow-panel: 0 1px 3px rgba(0, 0, 0, 0.45),
                   0 12px 32px rgba(0, 0, 0, 0.38),
                   inset 0 1px 0 rgba(255, 255, 255, 0.06);
```

The inset hairline (1px top edge, very low alpha white) gives dark cards a subtle top-edge "light source" that reads as elevation. The deeper black shadows replace the light-mode rgba(26,35,50,…) keys.

### New tokens

[VERIFIED: CONTEXT.md + session-recap-inherited-micali.md]

```css
/* Light values */
--rs-focus-ring-color: rgba(37, 99, 235, 0.55);   /* blue, mid alpha */
--rs-overlay-veil:     rgba(238, 241, 245, 0.9);  /* near-white fog for gradient veils */
--rs-scrim:            rgba(15, 23, 35, 0.45);    /* dark backdrop — same as current cmdk */

/* Dark values */
--rs-focus-ring-color: rgba(96, 165, 250, 0.75);  /* lighter blue, higher alpha for dark surfaces */
--rs-overlay-veil:     rgba(20, 28, 39, 0.85);    /* near-surface fog — dark version */
--rs-scrim:            rgba(0, 0, 0, 0.65);       /* deeper dark backdrop */
```

Updated `--rs-focus-ring` (the legacy composite token, still consumed by Phase 89):
```css
/* Light */
--rs-focus-ring: 0 0 0 3px var(--rs-focus-ring-color);

/* Dark */
--rs-focus-ring: 0 0 0 3px var(--rs-focus-ring-color);
```
Since `--rs-focus-ring` now references `--rs-focus-ring-color`, the ring colour adapts automatically with no additional duplication.

### Disabled tokens dark

```css
--rs-disabled-bg:   #253243    ← neutral-200 in dark (slightly visible surface)
--rs-disabled-text: #4a5e72    ← slightly darker than neutral-500 to clearly communicate disabled
```

---

## 4. Scope / Leak Risks

### Currently on `:root` — color tokens that would leak to host (MUST move)

All the variant tokens listed in Section 1 are currently on `:root`. Any component outside `.rs-shell` that happens to use `var(--rs-primary)` etc. currently inherits them. After this phase, those tokens are only declared on `.rs-shell` — so host components stop inheriting them. This is the correct behavior (better isolation), but it is worth noting: if the host application uses any `var(--rs-*)` tokens in its own templates today, those would stop working. Based on the mounted-package pattern, this is not a concern — adopter apps use their own token names. [ASSUMED: no host apps consume `var(--rs-*)` tokens in their own components]

### `[data-rulestead]` selector is not yet in HTML

`[data-rulestead]` appears in the cascade spec but is not currently emitted by any Elixir template. Adding it to the CSS blocks this phase costs nothing, but Phase 90 (or a host integration) must actually attach the attribute for it to take effect. This is a no-op risk: the selector exists in CSS, no element matches it → no effect either way.

### Hardcoded rgba literals in component rules (LEAVE for Phase 88)

Direct reads of the CSS confirm these 21 sites bypass tokens and will NOT re-theme by changing the token layer alone. They are Phase 88 work and must not be touched this phase:

| Line | Pattern | Component |
|------|---------|-----------|
| 451 | `box-shadow: 0 1px 2px rgba(26, 35, 50, 0.04)` | `.rs-flash` |
| 488 | `box-shadow: 0 1px 2px rgba(26, 35, 50, 0.04)` | `.rs-form-summary` |
| 583 | `box-shadow: 0 1px 1px rgba(26, 35, 50, 0.03)` | `.rs-radio-card__body` |
| 591 | `box-shadow: 0 4px 14px rgba(26, 35, 50, 0.07)` | `.rs-radio-card:hover` |
| 599 | `outline: 3px solid rgba(37, 99, 235, 0.18)` | radio-card focus |
| 606 | `box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.18), ...` | radio-card checked |
| 683 | `box-shadow: 0 18px 45px rgba(26, 35, 50, 0.16), ...` | `.rs-date-calendar` |
| 853 | `linear-gradient(180deg, rgba(255, 255, 255, 0.86), rgba(238, 241, 245, 0.9))` | `.rs-empty-state[data-variant="hero"]` |
| 1201 | `0 0 0 1px rgba(14, 165, 233, 0.22)` | `.rs-card--flag[data-highlighted]` |
| 1344 | `box-shadow: 0 1px 2px rgba(26, 35, 50, 0.04)` | `.rs-record-row` |
| 2343 | `box-shadow: 0 1px 2px rgba(26, 35, 50, 0.04)` | (stats area) |
| 2426 | `linear-gradient(135deg, rgba(219, 234, 254, 0.66), ...)` | `.rs-hub-hero` |
| 2475 | `background: rgba(244, 246, 248, 0.7)` | `.rs-signal` |
| 2544 | `background: rgba(244, 246, 248, 0.64)` | `.rs-env-state` |
| 2569 | `box-shadow: inset 0 0 0 1px rgba(37, 99, 235, 0.18)` | `.rs-env-state[data-current]` |
| 3284 | `box-shadow: 0 1px 2px rgba(26, 35, 50, 0.04)` | (another component) |
| 3859 | `background: rgba(15, 23, 35, 0.45)` | `.rs-cmdk__backdrop` |

Additionally, line 904:
```css
.rs-shell input:focus { outline: 2px solid var(--rs-primary-soft); }
```
`--rs-primary-soft` is a token (will re-theme), but using `outline` here instead of `box-shadow` conflicts with the Phase 89 unified ring pattern. Leave for Phase 89.

**Impact in dark mode without Phase 88:** The ~17 light-surface rgba shadows and the two gradient veils will look anaemic or wrong on dark surfaces, but the UI will still be usable. The shadow tokens themselves (--rs-shadow-sm etc.) will be correct, but individual component inline shadows remain light-keyed. This is the accepted ~5% "not yet fixed" state.

### `--rs-neutral-500` hardcode in component rule

Line 2207: `.rs-status-dot` uses `background: var(--rs-neutral-500)` directly (not the alias `--rs-text-placeholder`). Because `--rs-neutral-500` is a variant token that will be redeclared in the dark block, this will re-theme correctly without any component edit. This is fine — it's a token reference, just not via the alias layer.

### `--rs-neutral-700` direct reference

Line 2681 and 3532: `color: var(--rs-warning-text)`. Line-referenced above. These all use proper tokens, not hardcoded hex.

### Gradient veil patterns (lines 853, 2426)

These gradients embed hard rgba values for both the white-fog tint and the surface-tint. They will NOT re-theme until Phase 88 routes them through `--rs-overlay-veil`. Phase 87 introduces the token; Phase 88 uses it. In the interim, `.rs-empty-state[data-variant="hero"]` and `.rs-hub-hero` will show light gradients on dark surfaces. This is acceptable scoped-degradation.

---

## 5. Verification Approach for This Phase

### Success criteria (from CONTEXT.md)

1. System dark applies automatically — `@media (prefers-color-scheme: dark)` with `:not([data-theme])`.
2. Explicit `data-theme="dark"` override beats system; `data-theme="light"` re-asserts light.
3. `:root` and `<html>` carry no dark color overrides — inspect in devtools.
4. Representative surfaces in both themes look on-brand — mineral-dark, not grey generic.
5. First contrast pass on text/badge/border representative token pairs.

### Primary verification path: devtools flip

The fastest path requires no running server at all:

1. Open any page with `.rs-shell` rendered (the local dev loop at `:4010` suffices).
2. In Elements panel, add `data-theme="dark"` to the `.rs-shell` div.
3. Screenshot the three required screens: home, flags index, a flag detail screen.
4. Remove `data-theme`, add `data-theme="light"`, verify light re-asserts on dark OS.
5. In the Computed panel, confirm `:root` and `<html>` have no dark-variant `--rs-*` color values.

### Fallback: standalone static HTML harness

**Use when the local Phoenix demo is unavailable** (e.g. the known DB conflict issue where both `rulestead_demo_dev` and any other local Postgres database share the same name). The standalone harness requires no Elixir, no Phoenix, no seeds.

Create `/tmp/rs-theme-harness.html`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>rs theme harness</title>
  <link rel="stylesheet" href="/path/to/rulestead_admin/priv/static/css/rulestead_admin.css">
</head>
<body>
<div class="rs-shell" id="shell">
  <header class="rs-shell__header">
    <div>
      <p class="rs-shell__kicker">Rulestead</p>
      <h1 class="rs-shell__title">Flags</h1>
      <p class="rs-shell__summary">12 flags · staging</p>
    </div>
    <section class="rs-shell__context">
      <p class="rs-shell__context-label">Access</p>
      <div class="rs-shell__context-item">admin</div>
    </section>
  </header>
  <div class="rs-shell__layout">
    <nav class="rs-shell__rail">
      <div class="rs-shell__rail-group">
        <a href="#" class="rs-shell__rail-link" aria-current="page">Flags</a>
        <a href="#" class="rs-shell__rail-link">Rollouts</a>
        <a href="#" class="rs-shell__rail-link">Audiences</a>
      </div>
    </nav>
    <main class="rs-shell__main">
      <div class="rs-shell__body">
        <!-- badges -->
        <div style="display:flex;gap:0.5rem;flex-wrap:wrap;margin-bottom:1rem">
          <span class="rs-badge" data-tone="positive">positive</span>
          <span class="rs-badge" data-tone="warning">warning</span>
          <span class="rs-badge" data-tone="critical">critical</span>
          <span class="rs-badge" data-tone="neutral">neutral</span>
          <span class="rs-badge" data-tone="accent">accent</span>
        </div>
        <!-- card -->
        <div class="rs-card">
          <p>Card surface. Text on surface. <a href="#">Link</a></p>
        </div>
        <!-- flash -->
        <div class="rs-flash" data-kind="success">
          <strong>Success</strong>
          <p>Something worked.</p>
        </div>
        <div class="rs-flash" data-kind="error">
          <strong>Error</strong>
          <p>Something failed.</p>
        </div>
      </div>
    </main>
  </div>
</div>
<script>
  // Toggle theme from console: setTheme('dark') / setTheme('light') / setTheme('')
  window.setTheme = (t) => document.getElementById('shell').setAttribute('data-theme', t);
</script>
</body>
</html>
```

Open in browser via `file:///` or `python3 -m http.server` in the repo root. Use devtools to call `setTheme('dark')` and `setTheme('light')`. Screenshot with agent-browser or manually. The stylesheet link path must be absolute or adjusted for serve location.

**Known local-demo Playwright DB-conflict gotcha:** The memory file `admin-ui-dev-loop.md` notes that both Docker (port :4000) and local Phoenix (port :4010) use `rulestead_demo_dev` on the same Postgres. Running both simultaneously causes migration conflicts. Fix: either stop Docker before running local or use the static HTML harness for this phase's visual verification, reserving the full demo for the final screenshot gate.

### Contrast verification tool

For each text/surface pair, compute the WCAG relative luminance ratio. The W3C formula is:

```
L = 0.2126 * R + 0.7152 * G + 0.0722 * B  (linearized)
ratio = (Lmax + 0.05) / (Lmin + 0.05)
```

Pairs to verify as a minimum (all [ASSUMED — must verify]):

| Token pair | Light surface | Dark target | Required |
|------------|--------------|-------------|---------|
| `--rs-text` on `--rs-surface` | #1a2332 on #ffffff → ~14:1 ✓ | #e8edf3 on #141c27 → verify | ≥4.5:1 |
| `--rs-text-muted` on `--rs-surface` | #5c6b7a on #ffffff → ~6.0:1 ✓ | #a8b9ca on #141c27 → verify | ≥4.5:1 |
| `--rs-text-placeholder` on `--rs-surface` | #99a3af on #ffffff → ~3.4:1 ✓ | #7a8fa3 on #141c27 → verify | ≥3:1 |
| `--rs-success` on `--rs-surface` | #15803d on #ffffff → ~6.2:1 ✓ | #4ade80 on #141c27 → verify | ≥4.5:1 |
| `--rs-warning` on `--rs-surface` | #b45309 on #ffffff → ~5.0:1 ✓ | #fbbf24 on #141c27 → verify | ≥4.5:1 |
| `--rs-error` on `--rs-surface` | #b91c1c on #ffffff → ~6.0:1 ✓ | #f87171 on #141c27 → verify | ≥4.5:1 |
| `--rs-on-primary` on `--rs-primary` | #fff on #2563eb → ~5.0:1 ✓ | #fff on #3b82f6 → verify | ≥4.5:1 |
| badge text on badge soft fill | e.g. success on soft | e.g. #4ade80 on rgba(74,222,128,0.12) over #141c27 → verify | ≥4.5:1 |

Free contrast checker: https://webaim.org/resources/contrastchecker/ (or `node -e` with the WCAG formula).

---

## 6. Validation Architecture

`nyquist_validation: true` in `.planning/config.json`. [VERIFIED: config.json]

### Test framework

This phase is pure CSS with no Elixir code changes, no JS, and no new routes. There is no unit-testable logic. Validation is visual + automated contrast checks.

| Property | Value |
|----------|-------|
| Framework | Playwright (existing, `examples/demo/frontend`) |
| Config file | `examples/demo/frontend/playwright.config.ts` |
| Quick run | devtools `data-theme` flip + visual inspection |
| Full run | `cd examples/demo/frontend && npx playwright test` |
| Contrast tool | webaim.org/resources/contrastchecker or WCAG formula inline |

### Phase requirements → test map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| THM-01 | System dark applies on dark OS without any attribute | Visual | `data-theme` absent + OS dark → screenshot | ❌ Wave 0 (new spec needed) |
| THM-03 | Explicit `data-theme="dark"` beats system light | Visual | Set attribute + screenshot | ❌ Wave 0 |
| THM-03 | Explicit `data-theme="light"` beats system dark | Visual | Set attribute + screenshot | ❌ Wave 0 |
| THM-05 | `:root` carries no dark color variables | CSS inspection | Devtools computed panel / grep CSS | ✅ (can grep CSS) |
| THM-05 | `<html>` carries no dark color variables | CSS inspection | Same | ✅ |
| THM-06 | Dark palette reads as mineral-dark, on-brand | Visual | Screenshot + human review | ❌ Wave 0 |
| THM-06 | WCAG AA: all listed text/surface pairs pass | Contrast | WCAG ratio computation per pair | ❌ Wave 0 |

### Cascade-precedence test matrix

These cases must be explicitly validated (screenshot or inspect):

| Case | Setup | Expected |
|------|-------|---------|
| No attribute, light OS | No `data-theme`, `prefers-color-scheme: light` | Light tokens active |
| No attribute, dark OS | No `data-theme`, `prefers-color-scheme: dark` | Dark tokens active (THM-01) |
| Pinned dark, light OS | `data-theme="dark"`, OS light | Dark tokens active (THM-03) |
| Pinned light, dark OS | `data-theme="light"`, OS dark | Light tokens active (THM-03) |
| Pinned dark, dark OS | `data-theme="dark"`, OS dark | Dark tokens active (redundant, still verify) |

Use devtools media emulation (`prefers-color-scheme`) to test OS scenarios without changing actual OS setting.

### Scope-containment test

| Check | How |
|-------|-----|
| `:root` has no dark color values | Inspect computed styles on `<html>` in devtools — `--rs-neutral-0` etc. should not appear |
| `<html>` `color-scheme` unchanged | Should remain browser default or host value, not `dark` |
| Element outside `.rs-shell` has no `--rs-bg` | Create a `<div>` outside `.rs-shell` in the harness; `var(--rs-bg)` resolves to empty |

### Sampling rates

- **Per-commit during authoring:** visual inspect in static HTML harness for both themes
- **Phase gate before close:** full contrast check across all token pairs in table above + Playwright screenshot of home/flags/detail in both themes + cascade-precedence matrix covered
- **Phase 87 is complete when:** all 5 cascade cases screenshot correctly + all listed contrast pairs pass AA

### Wave 0 gaps

- [ ] `examples/demo/frontend/tests/theme-cascade.spec.ts` — covers THM-01, THM-03 (dark OS, pinned-dark, pinned-light cases)
- [ ] `examples/demo/frontend/tests/theme-scope.spec.ts` — covers THM-05 (`:root`/`<html>` containment)
- [ ] Static HTML harness `/tmp/rs-theme-harness.html` — covers THM-06 visual review and contrast sampling

---

## 7. Architecture Patterns

### Recommended file section order after refactor

```
:root {
  /* INVARIANT — typography, scale, radius, spacing, control sizing, z-index, motion */
  /* (unchanged from current; remove neutral ramp + all color + shadow + focus-ring) */
}

/* ─── THEME LAYER ─────────────────────────────────────────────────────── */

/* 1. Light default */
.rs-shell,
[data-rulestead] {
  color-scheme: light;
  /* neutral ramp */
  /* surface/border/text aliases */
  /* brand + status hard-hex */
  /* shadows */
  /* focus + disabled */
  /* new: --rs-focus-ring-color, --rs-overlay-veil, --rs-scrim */
}

/* 2. System dark (only when unpinned) */
@media (prefers-color-scheme: dark) {
  .rs-shell:not([data-theme]),
  [data-rulestead]:not([data-theme]) {
    color-scheme: dark;
    /* !! SYNCED PAIR — keep identical to [data-theme="dark"] below !! */
    /* … dark token set … */
  }
}

/* 3. Explicit dark (pinned; beats OS in both directions) */
.rs-shell[data-theme="dark"],
[data-rulestead][data-theme="dark"] {
  color-scheme: dark;
  /* !! SYNCED PAIR — keep identical to @media dark above !! */
  /* … dark token set … */
}

/* 4. Explicit light (re-asserts light over dark OS) */
.rs-shell[data-theme="light"],
[data-rulestead][data-theme="light"] {
  color-scheme: light;
  /* !! SYNCED PAIR — keep identical to .rs-shell default above !! */
  /* … light token set (verbatim copy of block 1) … */
}

/* ─── END THEME LAYER ──────────────────────────────────────────────────── */

/* (all existing component rules follow unchanged) */
```

### Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Color contrast check | Manual luminance calculation | webaim.org checker or WCAG formula | Error-prone for 20+ pairs |
| `@apply` for synced dark blocks | CSS preprocessor | Verbatim duplicate + comment | No build step; ~110 lines is acceptable |
| Dark mode toggle behavior | Session storage, cookie, event bus | Data attribute on `.rs-shell` set by Phase 90 hook | Already the pattern for `data-env-tone` |
| Light surface rgba values for dark | Opacity layers on light colors | Purpose-built dark ramp | Inverted-opacity approach produces muddy mid-tones |

---

## 8. Common Pitfalls

### Pitfall 1: Moving shadows to variant but leaving hard rgba in shadow definitions

**What goes wrong:** `--rs-shadow-sm: 0 1px 2px rgba(26, 35, 50, 0.05)` is moved to the variant block, but the dark version keeps the same `rgba(26,35,50,…)` key color. On dark surfaces, `rgba(26,35,50,…)` is near-invisible (the surface is already close to that color).
**Why it happens:** Copying the token definition without updating the rgba values.
**How to avoid:** Dark shadow definitions must use near-black rgba keys (`rgba(0,0,0,…)`) with higher opacity, plus the inset hairline.
**Warning signs:** Cards look flat/borderless in dark mode despite shadow token being declared.

### Pitfall 2: Declaring `color-scheme: dark` on `:root`

**What goes wrong:** Browser themes the host page's scrollbars, form controls, and native UI to dark — outside the mounted admin.
**Why it happens:** Forgetting the mounted-package discipline and following generic dark-mode tutorials that target `:root`.
**How to avoid:** `color-scheme` must only appear in the four `.rs-shell` / `[data-rulestead]` blocks.
**Warning signs:** Host page scrollbar switches to dark theme; browser devtools shows `color-scheme` on `<html>`.

### Pitfall 3: Forgetting `:not([data-theme])` on the system-dark media block

**What goes wrong:** When a user in system mode on a dark OS pins to Light, both Block 2 (system dark) and Block 4 (explicit light) apply. Without `:not([data-theme])` on Block 2, specificity decides — and (0,1,0) vs (0,1,1) means Block 4 wins, but this relies on source order and is fragile.
**Why it happens:** The `:not([data-theme])` guard is easy to miss.
**How to avoid:** Always use `.rs-shell:not([data-theme])` in the `@media` block. Test the pinned-light-over-dark-OS case explicitly.
**Warning signs:** Pinned Light on dark OS still shows dark tokens.

### Pitfall 4: `--rs-primary-soft` staying as a flat hex in dark mode

**What goes wrong:** `--rs-primary-soft: #dbeafe` (a near-white blue) placed on a `#141c27` surface looks washed out and disconnected from the blue hue. Rail active states, env-link selected states, and radio-card checked states all use this token.
**Why it happens:** Directly copying light values to dark without reconsidering opaque-hex vs rgba tints.
**How to avoid:** In dark mode, soft fills must become `rgba(hue, alpha)` tints at 10–14% over the dark surface, not opaque pale swatches.
**Warning signs:** Selected nav item shows a near-white slab on dark background.

### Pitfall 5: Out-of-sync synced pairs

**What goes wrong:** A token gets updated in the `@media` block but not in the `[data-theme="dark"]` block (or vice versa). Pinned-dark users see different values than system-dark users.
**Why it happens:** The duplicate is ~110 lines away; it's easy to miss when iterating on values.
**How to avoid:** The `/* !! SYNCED PAIR !! */` comment is the signal. Treat the two blocks as one logical unit. When writing the plan, express the dark token set once as a named constant in the task description — the task action is "paste identically into both blocks."
**Warning signs:** Pinned dark looks different from system dark.

### Pitfall 6: `--rs-surface-faint` assigned a lighter value than `--rs-surface` in dark

**What goes wrong:** In light mode, `--rs-surface-faint` is lighter than `--rs-surface` (near-white background). In dark mode, if the same direction is preserved, "faint" becomes lighter-than-surface — but in dark mode, "faint" should be darker (sunken), not lighter (elevated).
**Why it happens:** Mechanical mapping of light to dark without reconsidering the semantic meaning of "faint" in dark.
**How to avoid:** In dark mode: `bg` < `surface-faint` ≤ `surface` < `surface-muted`. Lighter = more elevated. `--rs-surface-faint` should map to `--rs-neutral-0` (deepest) in dark, not to a lighter stop.
**Warning signs:** Empty-state wells look elevated rather than recessed in dark mode.

---

## 9. Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark theme primitive | Invert light CSS values | Purpose-built dark ramp (`#10161f` base, flipped direction, compressed steps) | Inversion produces wrong luminance distribution and muddy mid-tones |
| Soft fill colors (dark) | Opaque pale tints | `rgba(hue, 0.12)` over dark surface | Pale opaque fills look anaemic on dark; hue tints maintain color identity |
| Shadow tokens (dark) | Reduce opacity on light shadows | Rebuild with `rgba(0,0,0,…)` keys + inset hairline | Light-key shadows disappear on near-same-color dark surfaces |
| `color-scheme` leak prevention | `!important` overrides | Scope `color-scheme` to `.rs-shell` only | Simpler, correct, respects host |

---

## 10. State of the Art

| Old Approach | Current Approach | Context |
|--------------|------------------|---------|
| Invert `filter: invert(1)` on entire page | Purpose-built dark ramp per token | Filter inversion breaks images and brand colors |
| `@media` only (no pinning) | `@media` + explicit attribute override | Allows persistent user preference without host cooperation |
| `prefers-color-scheme` on `:root` | Scoped to `.rs-shell` for mounted packages | Mounted package discipline; host theme isolation |
| Flat opaque soft fills | `rgba()` hue tints at 10–14% | Correct dark surface behavior; preserves hue identity |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Proposed dark neutral ramp hex values (neutral-0 through neutral-900) pass WCAG AA when used as described | §3 | Text/surface pairs fail contrast; must adjust hex values before shipping |
| A2 | Brand/status dark hex proposals (#4ade80, #f87171, #fbbf24, #3b82f6) all reach 4.5:1 on `#141c27` | §3 | Status indicators fail AA; must lighten further |
| A3 | `--rs-primary: #3b82f6` achieves ≥4.5:1 with white-on-primary | §3 | Primary buttons fail AA; must use lighter primary |
| A4 | `rgba(hue, 0.12)` soft tints over `#141c27` reach 3:1 for non-text UI components (borders) | §3 | Soft-fill borders fail 3:1; must increase opacity |
| A5 | `color-scheme` on `.rs-shell` (not `:root`) correctly scopes native control theming in all target browsers | §2 | Scrollbar or select theming leaks to host; or native controls don't theme correctly |
| A6 | No host adopter application uses `var(--rs-*)` tokens in its own components | §4 | Moving tokens off `:root` would break host styles; would require documenting breaking change |
| A7 | `[data-rulestead]` CSS selectors are forward-compatible placeholder for alternative mount approach | §2, §4 | If the selector is never applied to any element, the rules are dead CSS — benign but worth confirming |

---

## Open Questions

1. **`--rs-surface-faint` direction in dark**
   - What we know: In light, `surface-faint` = `neutral-25` (#f8fafc), lighter than `surface` (#ffffff is white). In the neutral ramp the naming implies "faint = almost invisible surface". In dark, the equivalent role is a recessed/sunken area.
   - What's unclear: Should `--rs-surface-faint` map to `neutral-0` (darkest) or stay as a slightly lighter-than-bg value? The elevation model says lighter = raised, so "faint" in dark should be darker than `surface` — but that conflicts with the "faint" naming intuition.
   - Recommendation: Map to `neutral-0` in dark (deepest). Update the comment to clarify "faint = recessed in dark, near-white in light."

2. **`--rs-warning-hover` missing from the token inventory**
   - What we know: `--rs-success-hover` and `--rs-error-hover` exist in the `:root` block. `--rs-warning-hover` is absent.
   - What's unclear: Is `--rs-warning` used without hover, or is there a component that expects `--rs-warning-hover`?
   - Recommendation: Add `--rs-warning-hover` to both light and dark blocks to complete the family (light: `#92400e`; dark: `#fcd34d`). Minor additive change; no Phase 88 dependency.

3. **`--rs-accent-text` / `--rs-accent-border` absent**
   - What we know: The accent family in `:root` has only `--rs-accent` and `--rs-accent-soft`. Badge accent uses `color: var(--rs-accent)` directly. No separate accent-text or accent-border token.
   - What's unclear: In dark mode, `#c45c26` (light accent) needs to lighten significantly. Will components that use `var(--rs-accent)` for both border and text need separate controls?
   - Recommendation: In dark, set `--rs-accent` to the lightened value (`#e8834a`) — since all component uses are for colored text/border (not fills), one token suffices. Add `--rs-accent-text: var(--rs-accent)` as an alias for semantic clarity if desired, but it's not required.

---

## Environment Availability

Step 2.6: Environment is CSS-only refactor. No external tooling dependencies beyond a browser. No package installs. The only environment consideration is the DB-conflict gotcha documented in Section 5 (fallback: static HTML harness).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Browser devtools | Theme verification | ✓ | N/A | — |
| Local Phoenix demo (`:4010`) | Full-stack screenshots | ✓ (requires one-time setup per dev-loop doc) | — | Static HTML harness |
| Playwright | Automated cascade tests | ✓ | Existing config | Manual devtools verification |
| agent-browser | Screenshot automation | ✓ (asdf shim) | — | Manual screenshots |

**Missing dependencies:** None blocking.

**DB-conflict fallback:** If both Docker (`rulestead_demo_dev` on :4000) and local Phoenix are running simultaneously, use the static HTML harness for visual verification and the `data-theme` devtools flip. The Playwright test suite against `:4010` can run with Docker stopped.

---

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/rulestead/rulestead_admin/priv/static/css/rulestead_admin.css` — direct read, lines 38–178 (token block) and full component scan for hardcoded rgba
- `/Users/jon/.claude/plans/session-recap-inherited-micali.md` — authoritative implementation plan; §Approach 1 cascade structure + dark-value rules
- `/Users/jon/projects/rulestead/.planning/phases/87-token-theme-foundation/87-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- `/Users/jon/projects/rulestead/.planning/REQUIREMENTS.md` — THM-01, THM-03, THM-05, THM-06 definitions
- `/Users/jon/projects/rulestead/.planning/STATE.md` — milestone context and accumulated decisions
- `/Users/jon/.claude/projects/-Users-jon-projects-rulestead/memory/admin-ui-dev-loop.md` — dev loop setup and DB-conflict gotcha

### Tertiary (LOW confidence / assumed)
- Dark neutral ramp hex values — derived from plan anchors + WCAG formula; not empirically checked
- Status/brand dark hex values — derived from plan transformation rules; not empirically verified
- Browser support for `color-scheme` on non-root elements — well-established but not tool-verified this session

---

## Metadata

**Confidence breakdown:**
- Token inventory: HIGH — directly read from source CSS
- Cascade mechanics: HIGH — verified against authoritative plan document
- Dark hex values: LOW — proposed per transformation rules; require contrast verification before commit
- Pitfalls: HIGH — derived from direct code inspection + known CSS cascade behavior
- Verification approach: HIGH — static HTML harness approach is standard practice

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (CSS token layer is stable; dark palette proposals need verification before use)
