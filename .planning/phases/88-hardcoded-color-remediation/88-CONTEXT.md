# Phase 88: Hardcoded-Color Remediation - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Decisions sourced from the user-approved plan (`/Users/jon/.claude/plans/session-recap-inherited-micali.md` §Approach) + Phase 87 RESEARCH §4 hotspot catalogue + Phase 87 visual-review findings. Autonomous, hands-off.

<domain>
## Phase Boundary

Route every hardcoded color literal in `rulestead_admin/priv/static/css/rulestead_admin.css` component rules through the theme-variant tokens established in Phase 87, so the ~5% of the UI that did NOT re-theme for free in dark mode now does. After this phase, `grep` finds no raw color literals (`rgba(26,35,50…)`, `rgba(37,99,235…)`, `rgba(255,255,255…)`, bare hex) in component rules outside the token declaration blocks.

**In scope:** the ~21 hardcoded-rgba sites catalogued in Phase 87 RESEARCH §4 (inline `box-shadow` keys, gradient veils at ~lines 853/2426, cmdk backdrop ~3859, inline focus tints `rgba(37,99,235,…)`, any `--rs-neutral-500/700` direct hardcodes); plus the **Warning-flash blue-border** bug found in Phase 87 visual review (flash--warning border should reference `--rs-warning`, not a blue/primary value). Consume the `--rs-overlay-veil` and `--rs-scrim` tokens created in Phase 87 for the veils/scrim.

**Explicitly OUT OF SCOPE:** unified `:focus-visible` ring (Phase 89 — but DO route any inline focus *tint colors* to tokens here so 89 can build cleanly); theme toggle/JS (90); design-system doc + fixture (91); per-screen polish (93). Do NOT change token *values* (that was 87) — only redirect component rules to consume tokens.
</domain>

<decisions>
## Implementation Decisions

### What to tokenize (from 87-RESEARCH §4)
- All inline `box-shadow: … rgba(26,35,50,…)` sites → use `--rs-shadow-sm` / `--rs-shadow` / `--rs-shadow-panel` (which are now theme-variant; dark gets near-black + inset hairline automatically).
- Gradient veil patterns (~lines 853 `.rs-empty-state[data-variant="hero"]`, ~2426) → `--rs-overlay-veil`.
- Command-palette backdrop (~line 3859 `.rs-cmdk__backdrop`) → `--rs-scrim`.
- Inline focus tints `rgba(37,99,235,0.18|…)` (~599, 606, 2569) → `--rs-focus-ring-color` (or a soft variant); colors only — the ring *shape* unification is Phase 89.
- Direct `--rs-neutral-500`/`--rs-neutral-700` hardcodes in component rules → the appropriate semantic alias (e.g. `--rs-text-placeholder`, `--rs-text`, `--rs-border-strong`) so they track the theme.
- **Warning flash**: the flash/callout `--warning` left-border (and any tone bar) must reference `--rs-warning` / the warning family — fix the blue-border bug surfaced in Phase 87 dark/light screenshots.

### How
- Token-redirect only: replace literal with `var(--rs-…)`. Do NOT introduce new tokens beyond those Phase 87 created unless a genuine gap exists (if one does, add it to the theme-variant blocks in BOTH light + the synced dark pair, and note it).
- Preserve visual parity in LIGHT mode (the light token values equal the old literals by construction from Phase 87) — this should be a visually-neutral change in light, and a correctness fix in dark.
- No build step, no Tailwind. Hand-edit the CSS.

### Claude's Discretion
- Exact token choice per site where multiple semantic aliases would work (pick the most semantically correct).
- Whether a site genuinely needs a new soft-focus-tint token vs reusing `--rs-focus-ring-color`.
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 87 tokens now available and theme-aware: `--rs-shadow-sm/-/-panel`, `--rs-overlay-veil`, `--rs-scrim`, `--rs-focus-ring-color`, full status families incl. `--rs-warning*`.
- 87-RESEARCH.md §4 has the exact line-number catalogue of every hotspot (read it).
- Theme layer ends ~line 451; component rules begin ~459 (per 87 verifier).

### Established Patterns
- Components consume `var(--rs-*)`; redirecting literals to tokens is the established pattern.
- The static theme harness (`rulestead_admin/priv/static/theme-harness.html`) + Playwright `theme-*.spec.ts` can screenshot both themes via `file://` — reuse for verification (sidesteps the demo DB gotcha).

### Integration Points
- Single file: `rulestead_admin/priv/static/css/rulestead_admin.css` (component-rule region only).
- The harness can be extended with any component whose dark rendering must be re-checked (e.g. add a flash/callout already present; the warning-border fix is visible there).
</code_context>

<specifics>
## Specific Ideas
- Verification: `grep` proves zero `rgba(26,35,50`, `rgba(37,99,235`, `rgba(255,255,255` literals outside the token blocks; re-screenshot the harness in both themes and confirm shadows read on dark + warning flash border is amber + cmdk scrim/veil look right on dark.
- Carry the Phase 87 "Warning flash blue border" finding to closure here.
</specifics>

<deferred>
## Deferred Ideas
- Unified `:focus-visible` two-stop ring → Phase 89.
- Token-contract docs + full contrast fixture page → Phase 91.
</deferred>
