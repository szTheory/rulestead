# Phase 93: Per-Screen Polish Across All Admin Screens - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Evidence-driven from the real isolated-demo both-theme sweep. Autonomous, hands-off. NO churn.

<domain>
## Phase Boundary

Confirm every mounted admin screen renders correctly and on-brand in BOTH themes, and fix the theme-specific stragglers the real-screen sweep surfaces. Requirements A11Y-01 (all text/pills/borders meet WCAG AA both themes) + SCRN-01 (every ~31 screen renders correctly, elevation/pills/empty-states correct, verified by both-theme screenshot + contrast).

**Reality (from the real isolated-demo sweep, both themes):** the Phase 87-91 token foundation makes every screen re-theme correctly by construction. The both-theme sweep of 13 representative screens spanning ALL nav groups + flag sub-screens (home, flags, flag-detail, rules, rollouts, explain, audit, experiments, audiences, schedule, diagnostics, compare, change-requests) shows clean, on-brand, legible dark rendering with no light-bleed, broken surfaces, or unreadable text. So this phase is CONFIRMATION + targeted straggler fixes, not a 31-screen rework.

**In scope:**
- Fix the one concrete A11Y-01 straggler the Phase 91 gate surfaced: the **accent badge in LIGHT mode** is ~3.62:1 (`--rs-accent` `#c45c26` text on `--rs-accent-soft` `#fde8dc`), below the 4.5:1 normal-text bar. Darken `--rs-accent` in the LIGHT token block so accent text on accent-soft clears 4.5:1; update the Phase 91 `design-system.spec.ts` expected hex + restore the accent pair to the normal (4.5) threshold (remove the "large" workaround). Dark accent already passes — leave it.
- Broaden the screenshot sweep to a few more screen types (e.g. simulate, kill, change-request detail, audience detail, scheduled-execution detail) to confirm no straggler; fix any genuine theme-specific issue found (low-contrast, sunken surface, broken elevation, illegible state).
- Any straggler must be fixed token-driven (no literals — Phase 88 invariant).

**OUT OF SCOPE:** motion/animation (Phase 94), new features, IA/home (92 done), token cascade restructuring, light-mode redesign beyond the accent AA fix. Placeholder light contrast stays WCAG-exempt (documented).
</domain>

<decisions>
## Implementation Decisions

### Accent-light AA fix (A11Y-01)
- Darken `--rs-accent` in the LIGHT block (`.rs-shell, [data-rulestead]`) from `#c45c26` to a value that yields ≥4.5:1 for accent text on `--rs-accent-soft` (#fde8dc). Candidate ~`#9a3f12`/`#8a3a10` region (verify exact ratio with the contrast helper). This is a deliberate light-mode brand value change appropriate to the A11Y phase. Accent stays the "restrained ember" identity, just AA-legible.
- Update `design-system.spec.ts`: set the accent-light pair to the new hex at the NORMAL 4.5 threshold (drop the `large` exception), so the gate now genuinely enforces it.
- Do NOT change dark `--rs-accent` (#e8834a) — it already passes.

### Sweep + stragglers
- Use the isolated demo (backend :60485, this branch) + the established Playwright sign-in→screenshot pattern; preset `localStorage["rulestead_admin.theme"]` for dark.
- Fix only genuine theme-specific defects (evidence-based). Record the both-theme sweep as SCRN-01 evidence.

### Claude's Discretion
- Exact darkened accent hex (meet 4.5:1, keep ember identity).
- Which additional screens to sweep for straggler-hunting (cover remaining screen TYPES/patterns).
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead_admin/priv/static/css/rulestead_admin.css` — `--rs-accent` in the 4 cascade blocks (only LIGHT changes here); `.rs-badge[data-tone="accent"]`/`draft` rules.
- `examples/demo/frontend/tests/design-system.spec.ts` + `support/contrast-check.ts` (Phase 91 gate — update the accent pair).
- Isolated demo (this branch) for real-screen screenshots; `tests/support/admin.ts` auth pattern; `/admin/flags/...` routes.
- Both-theme sweep already at `/tmp/rs-shots/screens/`.

### Established Patterns
- StatusTone single source; token-driven; both-theme cascade; design-system contrast gate.

### Integration Points
- rulestead_admin.css (light `--rs-accent` value + any straggler fix). design-system.spec.ts (accent pair). Possibly the isolated demo rebuild for final visual confirm.
</code_context>

<specifics>
## Specific Ideas
- Verify: design-system gate passes with the accent pair at the normal 4.5 threshold both themes (0 violations); the accent badge is legible in light; broadened both-theme sweep shows no straggler; existing theme specs green; compile clean.
- Final visual confirm: rebuild the isolated demo once (bakes 92 + 93 CSS) and re-screenshot the affected screens (accent badge, home refinements) both themes.
</specifics>

<deferred>
## Deferred Ideas
- Motion → Phase 94. Placeholder light contrast (WCAG-exempt) stays. forced-colors → Future (A11Y-04).
</deferred>
