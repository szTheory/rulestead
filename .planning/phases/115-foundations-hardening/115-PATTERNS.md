# Phase 115: Foundations Hardening - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` | planning-doc | documentation | `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md` | role-match |
| `scripts/check_admin_foundations.py` | source guard | file-read/validate | `scripts/check_brand_tokens.py`; `scripts/check_tokens_css.py`; `scripts/check_logo_assets.py` | exact |
| `scripts/ci/lint.sh` | CI wiring | command-chain | existing guard script calls in `scripts/ci/lint.sh` | exact |
| `rulestead_admin/priv/static/css/rulestead_admin.css` | CSS foundation | style cascade | existing token/focus/motion/table sections | exact |
| `examples/demo/frontend/tests/ui-matrix.spec.ts` | browser test | request-response | `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | exact |
| `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phoenix test | request-response | existing Phase 114 UI matrix test | exact |
| `rulestead_admin/priv/static/design-system.html` | static fixture | file/browser | existing static fixture preservation tests | exact |
| `rulestead_admin/priv/static/theme-control-harness.html` | static fixture | file/browser | existing static fixture preservation tests | exact |
| `rulestead_admin/priv/static/theme-harness.html` | static fixture | file/browser | existing static fixture preservation tests | exact |

## Pattern Assignments

### Guard script pattern

Use the existing Python guard shape:

- repo-relative constants at top
- direct `Path` reads
- deterministic parsing
- collect failures in a list
- print one clear pass line on success
- exit `1` with prefixed failure lines on drift

Closest sources:

- `scripts/check_brand_tokens.py`
- `scripts/check_tokens_css.py`
- `scripts/check_logo_assets.py`

Copy guidance:

- Keep `scripts/check_admin_foundations.py` stdlib-only.
- Do not import CSS parsers or add Python dependencies.
- Check only deterministic source facts: media thresholds are documented, reduced-motion floor exists, known focus exception marker exists, and the contract names the required foundation sections.

### CI wiring pattern

`scripts/ci/lint.sh` runs guard scripts from the repo root after Elixir package checks. New foundation guard wiring should follow the existing comment + `python3 "${RULESTEAD_REPO}/scripts/...py"` pattern.

Copy guidance:

- Add the foundation guard after token/contrast/logo guard scripts, before SVG budgets.
- Keep CI output readable with a single success line such as `ADMIN FOUNDATIONS OK`.

### CSS foundation pattern

`rulestead_admin.css` has established sections for:

- design tokens and breakpoint documentation near the top
- unified focus ring around line 607
- shell layout and component foundation blocks
- tables around `.rs-table`
- audit/diff/raw detail containment
- motion and command palette blocks near the end

Copy guidance:

- Prefer additive foundation rules over broad selector churn.
- Put reduced-motion floor near the existing motion section.
- Preserve `.rs-shell` / `[data-rulestead]` token scoping.
- Do not change palette/logo values.

### Browser evidence pattern

`examples/demo/frontend/tests/ui-matrix.spec.ts` already has:

- backend sign-in through `${backendUrl}/demo/sign-in`
- theme localStorage setup
- desktop/mobile contexts
- light/dark/system-dark contexts
- reduced-motion context
- `expectNoHorizontalOverflow(page)`
- screenshot artifacts through `testInfo.outputPath(...)`

Copy guidance:

- Extend that spec in place.
- Do not add `toHaveScreenshot`, `matchSnapshot`, `pixelmatch`, visual-diff tooling, Storybook, or PhoenixStorybook.
- Add deterministic checks for reduced-motion transform behavior and local scrolling/overflow where practical.

## Integration Notes

- Phase 115 should not create new routes. Use `/dev/rulestead-admin/ui-matrix` from Phase 114.
- The foundation guard should be a source gate, not a substitute for Playwright behavior checks.
- Matrix browser checks should target a small set of high-value foundation invariants, leaving full milestone evidence broadening to Phase 118.
