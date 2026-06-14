# Phase 115: Foundations Hardening - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 115 normalizes the mounted admin design foundations that every component and page depends on: breakpoint usage, scalar token documentation, typography rhythm, radius/shape rules, shadows/elevation, focus rings, reduced-motion behavior, dense-table responsiveness, and guard/docs agreement with the shipped brandbook and admin CSS.

This phase may harden `rulestead_admin.css`, static fixture expectations, foundation documentation, and focused UI-matrix evidence for FND-01 through FND-06. It must not polish or consolidate primitives/composites for Phase 116, change page-flow IA for Phase 117, perform milestone-wide evidence closeout for Phase 118, add public runtime APIs, add schemas/migrations, redesign the palette or logo, adopt Storybook or a component framework, add broad checked-in pixel baselines, rebrand FleetDesk, change release workflow, or prepare `rulestead_admin` for standalone publication.
</domain>

<decisions>
## Implementation Decisions

### Scope And Evidence Shape

- **D-01:** Treat Phase 115 as foundation hardening over the existing mounted admin CSS, token/static fixtures, brand/token docs, and the Phase 114 UI matrix. Do not introduce product capabilities, public routes, package metadata, component libraries, Storybook tooling, pixel baselines, FleetDesk branding, release workflow changes, or `rulestead_admin` publish preparation.
- **D-02:** Keep Phase 115 implementation scoped to FND-01 through FND-06. If a defect requires primitive/composite API changes, route it to Phase 116 unless it directly blocks foundation verification.

### Breakpoints And Scalar Foundation Contract

- **D-03:** Treat the documented breakpoint set in `rulestead_admin.css` as canonical: `40rem`, `48rem`, `60rem`, and `75rem`. Phase 115 should inventory every noncanonical media threshold, migrate obvious equivalents where safe, and record explicit selector-level exceptions for content-specific thresholds that remain.
- **D-04:** Preserve the existing responsive posture: the admin is responsive but not mobile-first. Mobile/narrow work should prevent overflow and preserve critical operator paths, not redesign desktop-first operator workflows.

### Tokens, Typography, Radius, Shadow, And Emphasis Rules

- **D-05:** Do not redesign token values, palette, typography families, or logo treatment. Align documentation and CSS behavior around the existing invariant tokens, brand-book shape rules, and guard-chain responsibilities.
- **D-06:** Make radius, pill usage, elevation, and colored emphasis explicit as product-surface rules. Prefer the existing brand-book direction: softened rectangles, precise separators, restrained pills, low-contrast elevation, and no playful/bubbly shape drift.
- **D-07:** Extend guard scripts only where Phase 115 finds a real repeatable drift class. Do not try to police every scalar token by default if a compact contract plus source assertions is the lower-maintenance proof.

### Focus And Reduced Motion

- **D-08:** Keep the unified `.rs-shell :where(...):focus-visible` ring as the standard focus treatment. Audit shell controls, buttons, links, form controls, command palette, environment/tenant controls, subnav, task links, and route-owned widgets for consistency.
- **D-09:** Any suppressed or customized focus treatment needs an explicit visible alternative or documented exception. The command-palette input is the known candidate exception because selection state and modal context provide the visible affordance.
- **D-10:** Put nonessential scale, translate, staged entrance, and hover motion behind `prefers-reduced-motion: no-preference`, or neutralize it for reduced-motion users. Preserve necessary state changes without relying on animation to communicate meaning.

### Dense Tables And Technical Rows

- **D-11:** Use the Phase 114 UI matrix route as the primary stress target for foundation behavior: mobile overflow, long labels, raw JSON/code, audit diffs, mutation-confirm rows, dense records, command palette, and static fixture links.
- **D-12:** Favor generic containment, wrapping, and local scrolling for technical content over route-specific table-to-card rewrites in Phase 115. Semantic or component-API changes belong to Phase 116 unless foundation verification is blocked.

### Verification Posture

- **D-13:** Verify Phase 115 with source assertions, existing guard scripts, focused ExUnit/LiveView coverage where useful, and Playwright matrix checks for overflow, focus, reduced motion, and theme/viewport behavior.
- **D-14:** Screenshots remain artifacts for human review, not checked-in baselines or pixel-diff gates. Preserve the v1.17 evidence posture from Phases 113 and 114.

### Methodology

- **D-15:** Apply the project methodology lenses as recommendation-first defaults. The selected foundation-hardening shape does not change public API, security/governance posture, package boundary, release model, or product scope, so no additional user decision is required before planning.

### the agent's Discretion

The planner may choose the exact artifact shape for breakpoint and foundation exceptions, provided it is compact, source-backed, and easy for later phases to consume. Prefer targeted source assertions and matrix evidence over broad new guard frameworks. If selector-level CSS changes are needed, keep them narrow and verify against the real Phase 114 UI matrix plus existing static fixtures.

### Folded Todos

None - no pending todos matched Phase 115.
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
- `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md`
- `.planning/phases/114-repo-native-component-matrix-harness/114-UI-SPEC.md`
- `.planning/phases/114-repo-native-component-matrix-harness/114-02-SUMMARY.md`
- `brandbook/brand-book.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `rulestead_admin/priv/static/css/rulestead_admin.css`
- `rulestead_admin/priv/static/design-system.html`
- `rulestead_admin/priv/static/theme-control-harness.html`
- `rulestead_admin/priv/static/theme-harness.html`
- `rulestead_admin/lib/rulestead_admin/components/shell.ex`
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/rule_editor_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/audience_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/governance_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/simulate_components.ex`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex`
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs`
- `examples/demo/frontend/tests/ui-matrix.spec.ts`
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`
- `examples/demo/frontend/tests/support/admin.ts`
- `scripts/ci/lint.sh`
- `scripts/check_synced_pair.py`
- `scripts/check_brand_tokens.py`
- `scripts/check_tokens_css.py`
- `scripts/check_contrast.py`
- `scripts/check_brandbook_html.py`
- `scripts/check_logo_assets.py`
- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `rulestead_admin/priv/static/css/rulestead_admin.css` already contains the foundation token layer, documented breakpoint set, four-block light/dark/system cascade, unified focus ring, motion tokens, micro-animation block, responsive shell layout, table styling, command palette styling, and recent containment fixes for matrix-discovered overflow.
- `brandbook/tokens.json` is the canonical machine-readable token record; `brandbook/tokens.css` is the reference mirror; `rulestead_admin.css` is the live mounted-admin cascade.
- Existing guard scripts cover synced theme-pair drift, brand token drift, token mirror drift, selected contrast checks, generated brandbook HTML, logo asset drift, and SVG budgets.
- The Phase 114 UI matrix route at `/dev/rulestead-admin/ui-matrix` renders real admin components inside `Shell.page/1` with deterministic long-label, dense, rare-state, raw-detail, and destructive-flow fixture assigns.
- `examples/demo/frontend/tests/ui-matrix.spec.ts` already proves matrix reachability, every required section, no page-level horizontal overflow, command palette keyboard behavior, reduced-motion context rendering, static fixture preservation, and no snapshot/baseline tooling.
- `RulesteadAdmin.Components.Shell` owns the shell, theme control, command palette, context controls, rail, breadcrumbs, flash stack, and inline wordmark.
- `RulesteadAdmin.Components.OperatorComponents` and related component modules provide the real component output the matrix uses to expose foundation stress cases.

### Established Patterns

- Theme-sensitive color, surface, border, text, shadow, focus-color, overlay, and logo tokens are scoped to `.rs-shell` / `[data-rulestead]`; invariant scalar tokens live in `:root`.
- The four-block cascade remains required: light default, system dark media block, explicit dark pin, and explicit light pin. Light blocks and dark blocks are synced pairs.
- The existing canonical breakpoint documentation is mobile-first and rem-based, while the current CSS still contains legacy pixel thresholds that need inventory or exception treatment.
- Focus is intended to use a unified two-stop `:focus-visible` ring, with a few local overrides for component-specific behavior.
- Nonessential motion should be bounded by `prefers-reduced-motion: no-preference`; current CSS already follows that pattern for several animations but still needs audit coverage for transforms outside the motion block.
- Dense tables and technical rows should avoid page-level overflow through containment, wrapping, and local scrolling, especially for raw JSON, long keys, audit diffs, and mutation-confirm evidence.
- The v1.17 evidence posture is curated screenshots plus deterministic assertions, not checked-in pixel baselines or external AI visual judging.

### Integration Points

- Phase 115 should extend or reuse the Phase 114 matrix evidence target rather than creating a new component catalog.
- Static fixtures remain useful for token/theme/contrast/focus probes but are supporting evidence, not the primary component contract.
- `scripts/ci/lint.sh` is the normal guard-chain entry point; any guard extension should fit that structure and remain readable in CI output.
- Phase 115 output should hand Phase 116 explicit primitive/composite polish candidates only when foundation work reveals them, not perform that consolidation itself.
</code_context>

<specifics>
## Specific Ideas

- Prefer a compact foundation exceptions artifact or section with columns such as: foundation, selector/source, current behavior, rule, exception/migration, proof command, and follow-on phase.
- For FND-01, start by enumerating all `@media` thresholds in `rulestead_admin.css`; migrate obvious near-equivalents to `40rem`, `48rem`, or `60rem`, and document content-specific thresholds that remain.
- For FND-03, audit the focus path across shell search, command palette options, theme segmented control, environment/tenant controls, form controls, task links, subnav links, text buttons, destructive actions, and raw-detail summaries.
- For FND-04, search for `transform`, `animation`, `transition`, `scale`, `translate`, and `blur`; ensure nonessential effects are absent or gated for reduced-motion users.
- For FND-05, make pill usage and elevation levels explicit: status/badge/chip controls can use full radius; product panels/cards use softened rectangles; elevation stays low contrast and purposeful.
- For FND-06, keep using the matrix long flag key, long audience key, long reason, raw audit JSON, dense records, mutation confirm, and audit diff examples as the no-overflow stress set.
</specifics>

<deferred>
## Deferred Ideas

- Primitive/composite visual polish, raw `rs-*` consolidation, and mutation-confirm pattern tuning belong to Phase 116.
- Full page-flow and IA changes belong to Phase 117.
- Milestone-wide screenshot/assertion closeout and reusable evidence guardrails belong to Phase 118.
- PhoenixStorybook, JavaScript Storybook, broad checked-in pixel baselines, external AI visual judging, forced-colors/high-contrast OS mode, v2 product wedges, FleetDesk rebranding, and `rulestead_admin` standalone publish preparation remain out of scope.

### Reviewed Todos (not folded)

None - no pending todos matched Phase 115.
</deferred>
