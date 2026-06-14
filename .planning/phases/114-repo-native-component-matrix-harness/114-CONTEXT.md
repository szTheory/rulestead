# Phase 114: Repo-Native Component Matrix Harness - Context

**Gathered:** 2026-06-13 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 114 implements the v1.17 repo-native UI matrix harness for DSM-02. The phase may add a dev/test-only Phoenix surface and Playwright evidence that render real mounted-admin components, representative fixed assigns, and selected seeded admin flow links.

This phase must not harden CSS foundations (Phase 115), polish or consolidate primitives/composites (Phase 116), change page-flow IA (Phase 117), close the full milestone evidence set (Phase 118), alter public runtime APIs, add schemas/migrations, redesign palette/logo, adopt Storybook or another component framework, add broad pixel baselines, rebrand FleetDesk, change release workflow, or prepare `rulestead_admin` for standalone publication.
</domain>

<decisions>
## Implementation Decisions

### Harness Placement

- **D-01:** Build the matrix as a dev/test-only Phoenix LiveView surface in the demo host, not as a route added to `RulesteadAdmin.Router.rulestead_admin/2`. The demo host already mounts the real admin and ships the admin CSS for browser evidence; keeping the matrix outside the package router avoids widening the mounted product contract.
- **D-02:** Use an internal, unambiguous demo route outside `/admin/flags` catch-all routes, for example `/dev/rulestead-admin/ui-matrix`, guarded so it is unavailable in production. The exact guard may be a demo-host config flag or `Mix.env()`-style dev/test gate, but the route must not become part of the public mounted admin route set.
- **D-03:** The matrix may live in `examples/demo/backend` and import real `RulesteadAdmin.Components.*` modules directly. Do not copy component HEEx into a static catalog or move matrix-only helpers into publishable package API docs.

### Matrix Content Model

- **D-04:** Organize the matrix by the Phase 113 taxonomy: foundations reference rows, primitives, composites, page patterns, and workflow states. The visible matrix should be easy for Phase 115-118 planners to map back to Phase 113 tables.
- **D-05:** Render real function components with centralized fixed assigns for component states. Use helper functions/modules for fixture data so long labels, long keys, dense records, denied states, unavailable states, destructive confirmations, and audit raw detail remain deterministic.
- **D-06:** Use seeded/demo route links or embedded route examples only where the full LiveView flow is the real source of truth, such as flag inventory, rules, rollouts, audit/timeline, command palette shell, and destructive preview -> confirm -> audit paths. Component examples remain direct component renders.
- **D-07:** Cover the required Phase 113 states explicitly: normal, dense, empty, loading, error, permission-denied/read-only, long-label/long-key, narrow-width/mobile, destructive-action, disabled/unavailable, focus, and keyboard-relevant cases.
- **D-08:** Include at least one matrix example for every operator lens: build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding/happy paths, and destructive actions.

### Browser Evidence

- **D-09:** Add curated Playwright coverage for the matrix across light, dark, system-dark, desktop, mobile/narrow, and reduced-motion contexts. Reuse the existing `brand-ui-evidence.spec.ts` loop shape where practical.
- **D-10:** Browser assertions should prove matrix reachability, `.rs-shell` rendering, representative section visibility, no horizontal page overflow, theme-mode rendering, selected focus/keyboard affordances, and screenshot artifact creation. Do not assert broad visual pixel equality.
- **D-11:** Keep static fixtures (`design-system.html`, `theme-control-harness.html`, `theme-harness.html`) available for low-level token/theme/contrast guard assertions. They remain supporting evidence, not the component contract.

### Verification and Scope Control

- **D-12:** Keep verification narrow to DSM-02: route/component reachability tests, matrix fixture health assertions, Playwright browser proof, and existing lint/brand guard chain. Do not expand the guard chain unless the matrix exposes a concrete repeatable drift class.
- **D-13:** Preserve the linked-version sibling-package release model. No package metadata, Hex publish posture, release workflow, or public documentation should imply a standalone `rulestead_admin` publish path.
- **D-14:** Treat the matrix as an evidence harness for later work, not the polish work itself. If the matrix reveals CSS, focus, responsive, or component consistency defects, record them for Phase 115 or Phase 116 instead of fixing them inside Phase 114 unless the defect prevents the matrix from rendering.

### Methodology

- **D-15:** Apply the project methodology lenses as recommendation-first defaults. Because the selected shape does not change public API, security/governance posture, package boundary, or release model, no additional user decision is required before planning.

### the agent's Discretion

The planner may choose the exact module names, fixture helper names, and route guard implementation, provided the result remains demo-hosted, dev/test-only, real-component-backed, deterministic, and easy for Playwright to visit. Prefer small, explicit fixture helpers over metaprogrammed component discovery; the point is reliable review coverage, not automatic exhaustive inventory.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md`
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md`
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-UI-MATRIX-CONTRACT.md`
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-ACCEPTANCE-GATES.md`
- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`
- `examples/demo/backend/lib/rulestead_demo_web/router.ex`
- `examples/demo/backend/lib/rulestead_demo_web/components/layouts/root.html.heex`
- `examples/demo/backend/assets/js/app.js`
- `examples/demo/backend/assets/css/app.css`
- `examples/demo/backend/mix.exs`
- `examples/demo/frontend/playwright.config.ts`
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`
- `examples/demo/frontend/tests/support/admin.ts`
- `examples/demo/frontend/tests/support/contrast-check.ts`
- `rulestead_admin/lib/rulestead_admin/router.ex`
- `rulestead_admin/lib/rulestead_admin/navigation.ex`
- `rulestead_admin/lib/rulestead_admin/components/shell.ex`
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/rule_editor_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/audience_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/audience_trace_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/governance_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/simulate_components.ex`
- `rulestead_admin/test/support/conn_case.ex`
- `rulestead_admin/test/rulestead_admin/components/confirm_components_test.exs`
- `rulestead_admin/test/rulestead_admin/components/audience_components_test.exs`
- `rulestead_admin/test/rulestead_admin/components/governance_components_test.exs`
- `rulestead_admin/priv/static/css/rulestead_admin.css`
- `rulestead_admin/priv/static/design-system.html`
- `rulestead_admin/priv/static/theme-control-harness.html`
- `rulestead_admin/priv/static/theme-harness.html`
- `scripts/ci/lint.sh`
- `scripts/check_synced_pair.py`
- `scripts/check_brand_tokens.py`
- `scripts/check_tokens_css.py`
- `scripts/check_contrast.py`
- `scripts/check_brandbook_html.py`
- `scripts/check_logo_assets.py`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The demo backend already depends on `rulestead_admin`, mounts the real admin under `/admin/flags`, includes `rulestead_admin.css` in the root layout, and is the existing backend target for Playwright admin evidence.
- `RulesteadAdmin.Components.Shell.page/1` owns the real shell chrome, theme control, command palette, context controls, rail, breadcrumbs, flash stack, and brand lockup. It is the correct wrapper for matrix pages that need mounted-admin context.
- `RulesteadAdmin.Components.OperatorComponents` provides banners, page sections, record rows, detail grids, task links, signals, empty states, related links, summary grids, capability explanations, trace panels, status lists, rollout ladders, confirm modal shell, and audit timeline examples.
- `RulesteadAdmin.Components.FlagComponents`, `ConfirmComponents`, `RolloutComponents`, `RuleEditorComponents`, `AuditComponents`, `AudienceComponents`, `AudienceTraceComponents`, `GovernanceComponents`, and `SimulateComponents` provide the primary primitive and composite sources Phase 114 should render.
- Existing component tests already demonstrate fixed-assign rendering with `Phoenix.LiveViewTest.render_component/2`; use those assigns as practical seeds for matrix fixture helpers.
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` already implements theme/viewport loops, screenshot output, and no-horizontal-overflow assertions against the demo backend.

### Established Patterns

- The mounted admin is a Phoenix LiveView surface rendered inside a host app. The host owns auth/layout/CSP; `rulestead_admin` provides mounted UI modules and static CSS.
- Admin theme tokens and CSS are scoped to `.rs-shell` / `[data-rulestead]`; the matrix should render inside `.rs-shell` so theme/focus/responsive behavior is real.
- The project prefers function components with declarative `attr` and `slot` contracts over LiveComponents for ordinary markup reuse.
- Playwright evidence is curated and deterministic. Existing browser specs capture screenshots as artifacts and assert behavior such as shell visibility and horizontal overflow rather than maintaining checked-in pixel baselines.
- Static HTML fixtures remain useful for token/theme/contrast probes but are intentionally not the primary source of component truth.
- FleetDesk is host-owned and must remain visually distinct; Phase 114 matrix work should stay on Rulestead-owned admin/demo surfaces only.

### Integration Points

- Add the matrix route in the demo backend router or an equivalent demo-host route module, outside the `rulestead_admin("/flags", ...)` macro route set.
- Reuse the demo root layout so the matrix gets the same LiveView socket, admin CSS, and asset environment as existing admin browser evidence.
- Use `examples/demo/frontend/tests/support/admin.ts` and the existing `backendUrl` convention so Playwright can visit the matrix through the same configured demo backend.
- Existing `rulestead_admin/test/support/conn_case.ex` and component tests provide patterns for fast ExUnit verification of real admin component rendering before browser evidence runs.
- Phase 114 output should hand Phase 115 concrete foundation stress examples, Phase 116 component/composite examples, Phase 117 route-flow examples, and Phase 118 evidence targets.
</code_context>

<specifics>
## Specific Ideas

- Preferred route shape: `/dev/rulestead-admin/ui-matrix` or a similarly explicit demo-host-only path that cannot be confused with a flag key under `/admin/flags/:key`.
- Preferred matrix sections: Overview/shell, primitives, mutation confirm, rollout/guardrail, rule editor, audit/timeline/diff, audience impact/dependencies, governance, simulate/explain, dense tables, and rare states.
- Use concrete stress values: long flag keys, long audience keys, long environment and tenant names, long owner/team names, long audit reasons, long JSON/code values, long command palette labels, missing host evidence, stale guardrails, redacted audit detail, and disabled/destructive submit states.
- Playwright should capture matrix screenshots with names that encode matrix section, theme, viewport, and reduced-motion where applicable.
- Include source assertions that the matrix uses `RulesteadAdmin.Components.*` and does not add Storybook, PhoenixStorybook, pixel-baseline, release, schema, package, or publish-prep files.
</specifics>

<deferred>
## Deferred Ideas

- Breakpoint, typography, spacing, radius, shadow/elevation, focus-ring, reduced-motion, and responsive table hardening belongs to Phase 115.
- Primitive/composite visual polish, raw `rs-*` consolidation, and mutation-confirm consistency tuning belongs to Phase 116.
- Full page-flow and IA changes belong to Phase 117.
- Milestone-wide screenshot/assertion closeout and any reusable guard-chain extensions belong to Phase 118.
- PhoenixStorybook, JavaScript Storybook, broad checked-in pixel baselines, external AI visual judging, forced-colors/high-contrast OS mode, v2 product wedges, FleetDesk rebranding, and `rulestead_admin` standalone publish preparation remain out of scope.

### Reviewed Todos (not folded)

None - no pending todos matched Phase 114.
</deferred>
