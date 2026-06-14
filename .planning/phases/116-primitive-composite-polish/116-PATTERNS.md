# Phase 116: Primitive + Composite Polish - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 18
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/116-primitive-composite-polish/116-RAW-MARKUP-CONSOLIDATION.md` | planning handoff ledger | documentation | `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md` | role-match |
| `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | primitive component module | assigns -> HEEx | existing `OperatorComponents` primitives | exact |
| `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | flag primitive module | assigns -> HEEx | existing `FlagComponents` badge/card/callout helpers | exact |
| `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex` | mutation confirm component module | slots/assigns -> HEEx form | existing `mutation_confirm/1` | exact |
| `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` | rollout composite module | domain maps -> HEEx panels | existing rollout ladder/guardrail/auto-advance components | exact |
| `rulestead_admin/lib/rulestead_admin/components/rule_editor_components.ex` | rule editor composite module | rule/audience maps -> HEEx form controls | existing rule card/action/audience helpers | exact |
| `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` | audit/timeline/diff composite module | audit maps -> HEEx panels/details | existing timeline item/raw detail/readable diff components | exact |
| `rulestead_admin/lib/rulestead_admin/components/audience_components.ex` | audience composite module | dependency/preview maps -> HEEx tables/panels | existing used-by and impact preview components | exact |
| `rulestead_admin/lib/rulestead_admin/components/governance_components.ex` | governance composite module | assessment maps -> HEEx panel | existing blast radius panel | exact |
| `rulestead_admin/lib/rulestead_admin/components/simulate_components.ex` | simulate/explain composite module | trace/archetype maps -> HEEx panels | existing archetype, export, trace components | exact |
| `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` | matrix evidence route | deterministic assigns -> real components | existing Phase 114 matrix sections | exact |
| `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` | deterministic fixture helper | static maps/lists -> matrix assigns | existing long-label/dense/rare-state fixtures | exact |
| `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phoenix matrix test | LiveView render -> source/HTML assertions | existing matrix smoke/source-boundary tests | exact |
| `rulestead_admin/test/rulestead_admin/components/confirm_components_test.exs` | component test | render_component -> HTML assertions | existing confirm component test | exact |
| `rulestead_admin/test/rulestead_admin/components/audience_components_test.exs` | component test | render_component -> HTML assertions | existing audience component test | exact |
| `rulestead_admin/test/rulestead_admin/components/governance_components_test.exs` | component test | render_component -> HTML assertions | existing governance component test | exact |
| `examples/demo/frontend/tests/ui-matrix.spec.ts` | browser evidence | Playwright -> DOM/screenshots/overflow | existing Phase 114/115 matrix evidence spec | exact |
| `rulestead_admin/priv/static/css/rulestead_admin.css` | scoped component CSS | tokenized selectors -> mounted admin visuals | existing component selector blocks and Phase 115 foundation rules | exact |

## Pattern Assignments

### Function component extension pattern

Use existing Phoenix function component modules:

- declare `attr` and `slot` inputs near each component
- keep domain behavior outside the component
- render semantic HTML with existing `rs-*` classes
- avoid LiveComponents unless component-local state/event lifecycle is genuinely needed

Closest sources:

- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex`

Copy guidance:

- Add or extend components in-place before creating new modules.
- Keep actions concrete: `href`, `phx-click`, `phx-submit`, and labels should remain caller-owned when route semantics differ.
- Do not move authorization, governance, or mutation decisions into component helpers.

### Mutation confirm pattern

Use `ConfirmComponents.mutation_confirm/1` as the anchor:

- scope line first
- evidence slot second
- optional typed-confirm fields before the reason
- reason textarea always present unless explicitly read-only/unavailable
- back link and primary/danger submit grouped in `.rs-mutation-confirm__actions`

Closest sources:

- `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` mutation-flows section
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` `mutation_confirm_assigns/1`

Copy guidance:

- Add disabled/unavailable/read-only state support to the canonical component instead of hand-rolling route-specific alternatives.
- Preserve existing submit event names and route-level validation semantics.
- Keep emergency runbook layout page-owned but align copy and control semantics.

### Matrix evidence pattern

Extend the existing matrix route/spec:

- add deterministic fixtures in `UiMatrixFixtures`
- render real component modules in `UiMatrixLive`
- assert source/section behavior in `UiMatrixLiveTest`
- assert browser behavior in `ui-matrix.spec.ts`
- keep screenshots as artifacts through `testInfo.outputPath`

Closest sources:

- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex`
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs`
- `examples/demo/frontend/tests/ui-matrix.spec.ts`

Copy guidance:

- Do not add a new matrix route.
- Keep `/dev/rulestead-admin/ui-matrix` dev/test-only and outside `RulesteadAdmin.Router.rulestead_admin/2`.
- Do not add `toHaveScreenshot`, `matchSnapshot`, `pixelmatch`, visual-diff tooling, Storybook, or PhoenixStorybook.

### Scoped CSS component polish pattern

Edit `rulestead_admin.css` only in existing component selector neighborhoods:

- buttons/forms around the primitive control blocks
- card/callout/stat/badge blocks
- mutation-confirm block
- rollout/rules workspace block
- audit/timeline/diff/raw-detail block
- reduced-motion/foundation rules remain Phase 115-owned

Closest sources:

- `rulestead_admin/priv/static/css/rulestead_admin.css`
- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md`

Copy guidance:

- Use existing tokens and selectors.
- Do not add new hex literals outside existing theme-token cascade contexts.
- Preserve no page-level horizontal overflow on mobile.

### Raw markup ledger pattern

Use a compact documentation artifact to prevent hidden scope drift:

| Cluster | Source | Decision | Action | Reason | Follow-on |
|---------|--------|----------|--------|--------|-----------|

Closest source:

- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md`

Copy guidance:

- Every Phase 113 raw `rs-*` cluster should be marked consolidated, intentionally page-owned, or deferred to Phase 117.
- Do not treat CSS definition sites or static fixtures as raw LiveView duplication.

## Integration Notes

- Phase 116 plans should reference `116-UI-SPEC.md`, `116-RESEARCH.md`, and `115-FOUNDATIONS-CONTRACT.md` in every read set that touches CSS/components.
- Component tests should stay targeted; use backend matrix tests for integrated coverage.
- Browser evidence should stay on `ui-matrix.spec.ts` and the existing static fixture specs.
- Phase 117 needs a clear handoff of route-owned exceptions and any page-flow issues discovered during polish.
