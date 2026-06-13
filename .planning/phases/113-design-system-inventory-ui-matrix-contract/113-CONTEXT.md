# Phase 113: Design-System Inventory + UI Matrix Contract - Context

**Gathered:** 2026-06-13 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 113 defines the v1.17 design-system inventory and UI matrix contract before implementation broadens into harness work, foundation hardening, or component polish. It inventories real mounted-admin components and page usage, names the required stress states, ties the matrix to operator jobs-to-be-done, and locks acceptance gates for follow-on phases.

This phase may create planning/design artifacts and narrow inventory evidence. It must not implement the Phase 114 matrix harness, start Phase 115 CSS/foundation hardening, polish Phase 116 primitives/composites, change product runtime APIs, add schemas/migrations, redesign palette/logo, adopt a component framework, introduce broad pixel baselines, rebrand FleetDesk, change release workflow, or prepare `rulestead_admin` for standalone publication.
</domain>

<decisions>
## Implementation Decisions

### Phase Shape

- **D-01:** Treat Phase 113 as a contract/inventory phase. The deliverable is an implementation-ready taxonomy, state matrix, operator-lens map, fixture-data needs list, and acceptance gate definition for Phases 114-118, not code polish.
- **D-02:** Keep the contract grounded in the mounted admin as shipped today: actual `RulesteadAdmin.Components.*` modules, LiveView page markup, `rs-*` CSS classes, existing static fixtures, and current Playwright guard patterns.
- **D-03:** Do not add new public runtime APIs, schemas, release workflow changes, component libraries, palette/logo work, broad pixel-baseline infrastructure, FleetDesk brand changes, or `rulestead_admin` publish preparation.

### Taxonomy

- **D-04:** Inventory the design system in five buckets: foundations, primitives, composites, page patterns, and workflow states.
- **D-05:** Foundations include token categories, theme cascade, typography rhythm, spacing, breakpoints, radius, shadows/elevation, focus rings, reduced motion, responsive table behavior, logo usage, and token/logo/contrast guard scripts.
- **D-06:** Primitives include buttons, links, badges/status indicators, cards/sections, callouts/banners, stats/signals, tags, pagination, form controls, task links, detail grids, empty states, flash, command palette controls, environment/tenant controls, and table rows.
- **D-07:** Composites include mutation-confirm flows, audit/timeline/diff panels, rollout/guardrail/auto-advance panels, rule editor surfaces, audience dependency/impact panels, simulation/explain traces, governance/blast-radius panels, diagnostics summaries, schedule/webhook rows, and change-request rows.
- **D-08:** Page patterns include shell/header/rail/breadcrumb layout, home task launcher and attention band, flag inventory, flag detail subnav, rules workspace, simulate/explain/timeline/rollouts/kill routes, audience flows, audit, diagnostics, compare, schedule, webhooks, experiments, change requests, and permission-denied/read-only states.
- **D-09:** Distinguish reusable component modules from repeated raw `rs-*` LiveView markup. Repeated raw markup becomes either a later consolidation candidate for Phase 116 or an explicitly documented exception, but Phase 113 only inventories and classifies it.

### UI Matrix Contract

- **D-10:** The UI matrix contract must require normal, dense, empty, loading, error, permission-denied/read-only, long-label/long-key, narrow-width/mobile, destructive-action, disabled/unavailable, and focus/keyboard states.
- **D-11:** The matrix contract must require light, dark, system-dark, desktop, mobile/narrow, and reduced-motion evidence dimensions where they affect component behavior or visual correctness.
- **D-12:** Use real admin components and representative fixed assigns in the future Phase 114 matrix. Static HTML fixtures remain useful for token/theme/contrast guard assertions, but they must not become the primary component contract because they can duplicate and drift from HEEx.
- **D-13:** Fixture-data needs should be named by state and operator outcome, not by decorative examples. Required data should cover happy path, dense data, empty data, loading/error, permission-denied, long values, destructive confirmation, missing host evidence, archived/read-only records, stale/blocked guardrail signals, and audit diff/raw-detail rows.

### Operator Lenses

- **D-14:** Organize route clusters and examples around operator jobs-to-be-done: build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding/happy paths, and destructive actions.
- **D-15:** Preserve the existing navigation mental model from `RulesteadAdmin.Navigation`: Overview, Build & release, Explain & diagnose, and Review & approve. The Phase 113 contract may map additional lenses, but it should not rename or restructure navigation as implementation.
- **D-16:** Treat destructive actions as a first-class lens. Kill switch, cleanup/archive, audience archive/delete, rollout risky jump, governed execution, and production typed-confirm paths need shared preview -> confirm -> audit expectations.

### Evidence and Acceptance Gates

- **D-17:** Phase 114 should build a repo-native Phoenix/Playwright UI matrix that renders real admin component modules and seeded LiveView flows. Do not introduce JavaScript Storybook or PhoenixStorybook in v1.17 unless this contract later proves repo-native evidence insufficient.
- **D-18:** Keep v1.17 evidence to curated screenshots plus deterministic assertions: fixture health, no horizontal overflow, focus visibility, keyboard flow, selected ARIA roles, selected contrast pairs, reduced-motion behavior, and light/dark/system mode rendering.
- **D-19:** Preserve existing guard chain responsibilities: `check_synced_pair.py`, `check_brand_tokens.py`, `check_tokens_css.py`, `check_contrast.py`, `check_brandbook_html.py`, `check_logo_assets.py`, SVG budgets, and existing Playwright theme/brand evidence. Extend guards later only where they prevent real design-system drift.
- **D-20:** Do not add broad checked-in pixel baselines or external AI visual judging. Human review remains the qualitative layer; deterministic assertions and screenshot artifacts provide repeatable evidence.

### the agent's Discretion

The planner may choose the exact document/file shape for the Phase 113 inventory artifact, provided it is easy for Phase 114 and later phases to consume. Prefer a compact table-driven contract over prose-only notes. If the implementation plan needs a helper script to inventory component functions or `rs-*` selectors, keep it repo-local, deterministic, and documentation-oriented.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/milestones/v1.16-phases/107-brand-ui-audit-ui-spec/107-CONTEXT.md`
- `.planning/milestones/v1.16-phases/107-brand-ui-audit-ui-spec/107-UI-SPEC.md`
- `.planning/milestones/v1.16-phases/112.1-close-gap-bui-05-bui-06-dynamic-fleetdesk-launcher-url-and-e/112.1-CONTEXT.md`
- `.planning/milestones/v1.13-phases/89-focus-interaction-state-unification/89-CONTEXT.md`
- `.planning/milestones/v1.13-phases/90-tri-state-theme-control/90-CONTEXT.md`
- `.planning/milestones/v1.13-phases/91-design-system-consolidation/91-CONTEXT.md`
- `.planning/milestones/v1.13-phases/94-restrained-micro-animation/94-CONTEXT.md`
- `.planning/milestones/v1.14-phases/96-design-tokens-brandbook-scaffold/96-CONTEXT.md`
- `.planning/milestones/v1.14-phases/98-admin-re-skin-css-cascade/98-CONTEXT.md`
- `.planning/milestones/v1.15-phases/104-winner-lockup-family/104-CONTEXT.md`
- `.planning/milestones/v1.15-phases/105-propagation-admin-demo/105-CONTEXT.md`
- `brandbook/brand-book.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `rulestead_admin/priv/static/css/rulestead_admin.css`
- `rulestead_admin/priv/static/design-system.html`
- `rulestead_admin/priv/static/theme-control-harness.html`
- `rulestead_admin/priv/static/theme-harness.html`
- `rulestead_admin/lib/rulestead_admin/navigation.ex`
- `rulestead_admin/lib/rulestead_admin/router.ex`
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
- `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`
- `rulestead_admin/lib/rulestead_admin/live/audience_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/schedule_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex`
- `scripts/ci/lint.sh`
- `scripts/check_synced_pair.py`
- `scripts/check_brand_tokens.py`
- `scripts/check_tokens_css.py`
- `scripts/check_contrast.py`
- `scripts/check_brandbook_html.py`
- `scripts/check_logo_assets.py`
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`
- `examples/demo/frontend/tests/theme-control.spec.ts`
- `examples/demo/frontend/tests/theme-cascade.spec.ts`
- `examples/demo/frontend/tests/theme-scope.spec.ts`
- `examples/demo/frontend/tests/support/contrast-check.ts`
- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `RulesteadAdmin.Components.OperatorComponents` already provides shared operator primitives and groups: banners, page sections, record rows, detail grids, task links, signals, empty states, related links, summary grids, capability explanations, trace panels, status lists, rollout ladders, confirm modal shell, and audit timeline.
- `RulesteadAdmin.Components.FlagComponents` provides lifecycle/stale/readiness/evidence badges, tags, pagination, stats, section cards, callouts, and per-flag subnav.
- `RulesteadAdmin.Components.ConfirmComponents.mutation_confirm/1` is the canonical governed mutation confirm shape and should anchor destructive-action matrix states.
- `RulesteadAdmin.Components.RolloutComponents`, `RuleEditorComponents`, `AuditComponents`, `AudienceComponents`, `GovernanceComponents`, `SimulateComponents`, and `AudienceTraceComponents` provide the major domain composite groups.
- `RulesteadAdmin.Components.Shell` owns the mounted shell, theme control, command palette, context clusters, brand lockup, breadcrumbs, rail, flash stack, and layout frame.
- Static fixtures (`design-system.html`, `theme-control-harness.html`, `theme-harness.html`) already exercise token, theme, logo, focus, and contrast surfaces without requiring Phoenix.
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` already demonstrates the route/theme/viewport screenshot pattern and no-horizontal-overflow assertion across mounted admin surfaces.

### Established Patterns

- Tokens and theme values are scoped to `.rs-shell` / `[data-rulestead]`; color-carrying tokens live in four synced cascade blocks while scalar tokens are invariant.
- System/Light/Dark theme control is client-only via localStorage and `.ThemeControl`; system mode is CSS-media-driven and pinned modes set `data-theme`.
- Focus is governed by a unified two-stop `:focus-visible` ring scoped under `.rs-shell`.
- Reduced motion is implemented by putting nonessential motion behind `prefers-reduced-motion: no-preference`.
- Navigation is grouped by operator task rhythm in `RulesteadAdmin.Navigation` and reused by shell, command palette, and home launcher.
- v1.16 evidence favors broad route screenshots plus deterministic assertions over broad checked-in pixel baselines.
- FleetDesk is host-owned and must remain distinct from Rulestead-owned mounted-admin/demo chrome.

### Integration Points

- Phase 113 output feeds the Phase 114 matrix harness, Phase 115 foundations hardening, Phase 116 component polish, Phase 117 page-flow/IA pass, and Phase 118 evidence guardrails.
- The future UI matrix should mount into a Phoenix/dev-test path that can render real component modules and seeded flow examples while preserving host/mounted-admin boundaries.
- Playwright should be able to target the matrix using the existing theme/viewport/reduced-motion patterns from frontend evidence specs.
- Guard scripts should remain part of normal lint and only be extended when the matrix reveals a real repeatable drift class.
</code_context>

<specifics>
## Specific Ideas

- Prefer a Phase 113 inventory table with columns: bucket, component/pattern, source file, states required, operator lens, current evidence, gap/exception, follow-on phase.
- Include a separate "raw `rs-*` repeated markup" section so Phase 116 can decide what to consolidate without prematurely refactoring.
- Name at least one matrix example for every operator lens, including destructive actions and permission-denied/read-only examples.
- Treat long-label stress as concrete values: long flag keys, long owner/team names, long environment/tenant names, long audit reasons, long JSON/code values, and long command palette labels.
- Treat narrow-width stress as a contract for no horizontal page overflow, preserved primary actions, usable kill-switch path, and table/card fallback behavior.
- Include fixture-data needs for host evidence unavailable, stale guardrail evidence, archived flags/audiences, denied audience dependencies, failed scheduled execution, and redacted audit detail.
</specifics>

<deferred>
## Deferred Ideas

- Repo-native UI matrix implementation is Phase 114.
- Breakpoint/token/focus/reduced-motion/table hardening is Phase 115.
- Primitive/composite consolidation and polish is Phase 116.
- Page-flow IA changes are Phase 117.
- Milestone-wide screenshot/guardrail closeout is Phase 118.
- PhoenixStorybook, JavaScript Storybook, broad pixel-baseline visual regression, external AI visual judging, forced-colors/high-contrast OS mode, v2 product wedges, and `rulestead_admin` publish preparation remain out of scope for v1.17 unless a later explicit roadmap change says otherwise.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 113.
</deferred>
