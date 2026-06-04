# Phase 91: Design-System Consolidation - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Decisions sourced from the user-approved plan (`/Users/jon/.claude/plans/session-recap-inherited-micali.md` §Approach + P5). Autonomous, hands-off.

<domain>
## Phase Boundary

Consolidate and DOCUMENT the now-complete token-driven design system, and turn the ad-hoc theme harness into a comprehensive **token/contrast reference fixture** that serves as the regression gate for Phases 92-94. This is the "lock in the dividends" phase: make the system legible to future contributors and machine-checkable.

**In scope:**
- **Token-contract documentation:** a clear header comment block in `rulestead_admin.css` (and/or a short guide doc) explaining the invariant-vs-variant split, the 4-block cascade (light / system-dark / explicit-dark / explicit-light), the SYNCED-PAIR rule, the scale categories (color/space/radius/shadow/type/z/motion/control/focus), and how to add a token correctly (light + synced dark pair). This is DSY-02's documentation half.
- **Comprehensive contrast reference fixture:** evolve `theme-harness.html` (or a dedicated `design-system.html`) into a complete swatch board rendering EVERY token pair, every `.rs-badge[data-tone]`, every status/flash, focus rings, hover + disabled states, surface elevation ladder — in a layout that screenshots cleanly in both themes. Add an automated WCAG-ratio assertion (extend `tests/support/contrast-check.ts`) that iterates all text/surface + base-on-soft pairs and fails on any sub-AA pair — the regression gate Phases 92-94 run.
- **Fold one-off patterns into tokens:** any remaining ad-hoc color/shadow/spacing values discovered during 88/89 that aren't yet tokenized (sweep + tokenize); if a genuinely new token is needed, add it to the light block + synced dark pair.

**OUT OF SCOPE:** new visual features; IA/home changes (92); per-screen polish (93); motion (94); token VALUE re-tuning beyond fixing a discovered AA failure. Don't restructure the cascade (87 owns it).
</domain>

<decisions>
## Implementation Decisions

### Documentation
- Primary home for the token contract: a header comment block at the top of the token section in `rulestead_admin.css` (where contributors will look), plus a concise reference section in an existing guide (e.g. `prompts/rulestead-admin-ux-and-operator-ia.md` §9 theming, or the host-integration-seam guide). Keep it DRY — link, don't duplicate.
- Document: the scale categories + token names by category; the cascade precedence + `:not([data-theme])` rule; the SYNCED-PAIR maintenance rule (+ the python check command); the "how to add a token" recipe.

### Contrast fixture (the regression gate)
- One fixture page that renders the full system. Reuse the existing `theme-harness.html` foundation (it already has badges/flashes/surfaces/focus targets) and extend to completeness, OR split into a dedicated `design-system.html` if cleaner — Claude's discretion, but ONE canonical fixture.
- The automated gate: a Playwright spec (e.g. `design-system.spec.ts`) that, for both themes, reads computed token values and asserts WCAG AA on the enumerated pairs (text ≥4.5:1, large/UI ≥3:1, base-on-soft pill pairs ≥4.5:1), failing the build on any violation. This is the gate 92-94 re-run.

### Claude's Discretion
- Whether the fixture is the extended `theme-harness.html` or a new `design-system.html` (pick the cleaner; if new, keep the harness for the cascade/control specs or migrate them).
- Exact doc location split between CSS header comment vs guide (keep DRY).
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead_admin/priv/static/theme-harness.html` — already renders badges (5 tones), flashes (3), surface swatches, disabled, focus targets (input/select/buttons/tabs), scope probe. Strong base for the full fixture.
- `examples/demo/frontend/tests/support/contrast-check.ts` — `wcagRatio()` + `assertAA()` (Phase 87). Extend for the full enumerated pair set.
- The python SYNCED-PAIR check (from 87-03-PLAN.md) — reference in the docs.
- Token blocks are complete after 87-90 (incl. `--rs-focus-ring` two-stop, `--rs-primary-ring`, `--rs-overlay-veil`, `--rs-scrim`, `--rs-warning-hover`).

### Established Patterns
- BEM `rs-*`; file:// Playwright fixtures (no demo DB); both-theme screenshots; data-theme flip.

### Integration Points
- `rulestead_admin/priv/static/css/rulestead_admin.css` (header doc comment + any token folding).
- The fixture HTML + a contrast spec under `examples/demo/frontend/tests/`.
- A guide doc for the token-contract reference.
</code_context>

<specifics>
## Specific Ideas
- Verify: the fixture renders the complete system in both themes (screenshot); the automated contrast spec passes with ZERO sub-AA pairs in both themes (and would FAIL if a future phase regressed a token — prove by spot-perturbation if cheap); the docs accurately describe the shipped token set (grep token names exist).
- This fixture + spec is explicitly the gate Phases 92, 93, 94 run before closing.
</specifics>

<deferred>
## Deferred Ideas
- IA/home → 92. Per-screen polish → 93. Motion → 94. forced-colors → Future (A11Y-04).
</deferred>
