# Phase 89: Focus + Interaction-State Unification - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Decisions sourced from the user-approved plan (`/Users/jon/.claude/plans/session-recap-inherited-micali.md` §Approach 3 "Unified focus + interaction states") + Phase 87 RESEARCH (focus inconsistency catalogue). Autonomous, hands-off.

<domain>
## Phase Boundary

Replace the three different focus idioms in `rulestead_admin/priv/static/css/rulestead_admin.css` with ONE unified `:focus-visible` two-stop ring applied to every interactive element, and ensure hover + disabled states are legible and WCAG-AA-compliant in BOTH themes. Builds on Phase 87 tokens (`--rs-focus-ring-color`, `--rs-focus-ring-offset`, `--rs-disabled-*`, surface tokens) and Phase 88 (which already routed inline focus *tint colors* to `--rs-focus-ring-color`).

**In scope:**
- Author one canonical rule: `.rs-shell :where(a, button, input, select, textarea, [tabindex], [role="option"], [role="tab"], summary):focus-visible { outline: none; box-shadow: <two-stop ring>; border-radius: inherit; }` — two-stop = surface-colored inner gap (`--rs-surface`) + brand outer ring (`--rs-focus-ring-color`), so it reads on light cards, dark surfaces, AND colored fills (e.g. primary buttons).
- Remove/replace the old idioms: `outline: 2px solid var(--rs-primary-soft)` on inputs (the near-invisible pale-fill bug), any remaining raw `outline`/`box-shadow` focus rules, and any bare `:focus` (switch to `:focus-visible` where the element is keyboard-interactive; keep `:focus-within` where semantically needed).
- Hover: audit `*-hover` token usage so hover is perceivable (≥3:1 vs resting) and legible in both themes — no white-on-light or crushed-on-dark.
- Disabled: prefer explicit `--rs-disabled-bg`/`--rs-disabled-text` over bare opacity (opacity over a dark surface can crush to invisible); keep ≥3:1 for usability though WCAG exempts disabled.
- Extend the theme harness with representative interactive elements (text input, select, a `[role="tab"]` strip, primary + secondary + danger buttons) so focus rings are screenshot-verifiable on every surface type.

**OUT OF SCOPE:** token VALUE changes (Phase 87 owns; only ADD a `--rs-focus-ring` shape token if cleaner), theme toggle/JS (90), design-system docs/fixture (91), IA/home (92), per-screen polish beyond focus/hover/disabled (93), motion (94). Do not restructure component layout/markup.
</domain>

<decisions>
## Implementation Decisions

### The unified ring (two-stop, theme-variant color)
- Define the ring shape once. Recommended token: `--rs-focus-ring: 0 0 0 var(--rs-focus-ring-offset) var(--rs-surface), 0 0 0 calc(var(--rs-focus-ring-offset) + 3px) var(--rs-focus-ring-color);` declared in the theme blocks so the gap color tracks the theme (`--rs-surface`) and the ring color is already theme-variant. NOTE: Phase 87 may have defined `--rs-focus-ring` as a single-stop ring — upgrade it to the two-stop form in ALL FOUR cascade blocks, keeping the dark pair synced. If the gap-color must differ per element (e.g. on a card vs page bg), accept `--rs-surface` as the common-case gap; elements on unusual fills still get a visible outer ring.
- Apply via a single `:where(...)` selector (zero specificity, easy to override per-element if ever needed) scoped under `.rs-shell`.
- `outline: none` only WITH the box-shadow replacement present (never bare `outline:none`).

### Hover / disabled
- Hover: verify each interactive component's `:hover` uses a token that shifts perceptibly from resting in both themes (e.g. `--rs-surface-muted`, `--rs-primary-hover`). Fix any that don't.
- Disabled: route disabled visuals through `--rs-disabled-bg`/`--rs-disabled-text` (theme-variant; Phase 87 set dark disabled-text to a legible value). Avoid `opacity:` as the sole disabled signal on dark.

### Claude's Discretion
- Exact `:where()` selector membership (cover all genuinely keyboard-focusable interactive elements actually used in the admin).
- Whether to keep `--rs-focus-ring` single-stop + add `--rs-focus-ring-2` two-stop, vs upgrading the existing token in place (prefer upgrading in place to avoid a second token).
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 87 tokens: `--rs-focus-ring`, `--rs-focus-ring-color` (theme-variant), `--rs-focus-ring-offset` (invariant), `--rs-surface`, `--rs-disabled-bg`, `--rs-disabled-text`.
- Phase 88 already redirected inline focus tint COLORS to `--rs-focus-ring-color` — so the remaining work is unifying ring SHAPE + replacing `outline` idioms + `:focus`→`:focus-visible`.
- 87-RESEARCH catalogued the focus inconsistency: ~15 `:focus-visible`, ~5 bare `:focus`, ~10 `outline:` rules; input focus used `outline: 2px solid var(--rs-primary-soft)` (pale, near-invisible).
- Static harness + Playwright (`file://`) verifies both themes without the demo DB.

### Established Patterns
- `.rs-shell`-scoped rules; `:where()` for low-specificity base rules is already used (87-RESEARCH noted a `:where()` base-link rule).

### Integration Points
- Single CSS file (focus/hover/disabled rules across component region + the `--rs-focus-ring` token in the 4 cascade blocks).
- Harness extension: `rulestead_admin/priv/static/theme-harness.html`.
</code_context>

<specifics>
## Specific Ideas
- Verify with: keyboard-tab through harness interactive elements in both themes, screenshot focus rings on a card, on the page bg, and on a primary (colored) button — confirm the ring is visible (surface gap separates it from the control) on all three. Run axe-core focus-indicator + contrast checks. Confirm no bare `outline:none` without a box-shadow replacement remains.
- WCAG targets: focus indicator ≥3:1 vs adjacent, ≥2px perimeter (2.4.11/2.4.13); text 4.5:1; UI components 3:1.
</specifics>

<deferred>
## Deferred Ideas
- Theme toggle/persistence → Phase 90.
- Token-contract docs + full contrast fixture → Phase 91.
- forced-colors / high-contrast mode → Future (A11Y-04).
</deferred>
