# Phase 117: Page Flow + IA Pass - Context

**Gathered:** 2026-06-14 (assumptions mode with advisor research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 117 validates the polished v1.17 admin components inside full operator workflows and route clusters. It may review and adjust route-owned information architecture for FLOW-01 through FLOW-04: operator jobs-to-be-done mapping, least-surprise page hierarchy, route-level keyboard/focus/mobile behavior, and deterministic fixture or demo evidence for happy, error, boundary, and rare states.

This phase must not reopen Phase 115 foundation rules, redo Phase 116 primitive/composite polish, perform Phase 118 milestone-wide evidence closeout, add public runtime APIs, add schemas/migrations, redesign the palette or logo, adopt Storybook or a component framework, add broad checked-in pixel baselines, rebrand FleetDesk, change release workflow, introduce v2 feature wedges, or prepare `rulestead_admin` for standalone publication.
</domain>

<decisions>
## Implementation Decisions

### Navigation And Route Clusters

- **D-01:** Preserve the current top-level navigation model from `RulesteadAdmin.Navigation`: Overview, Build & release, Explain & diagnose, and Review & approve.
- **D-02:** Treat audiences, rollouts, audit, destructive actions, onboarding/happy paths, denied states, unavailable states, and rare states as operator lenses inside the current route clusters, not as new top-level navigation groups.
- **D-03:** Do not add a flat entity rail, role/mode-based navigation, top-level Rulesets, top-level Settings, or a top-level destructive/emergency destination in Phase 117. Home launcher, rail, command palette, breadcrumbs, and contextual subnav should stay consistent with the existing grouped model.

### Route-Owned IA Surfaces

- **D-04:** Drive Phase 117 through route-owned IA review, not component extraction or broad page redesign.
- **D-05:** Prioritize the page-owned surfaces handed off by Phase 116: flag inventory search/cards, rules workspace shell/sidebar/action hierarchy, kill-switch runbook sequencing, home attention/task-board composition, and audience inventory/dependency placement.
- **D-06:** Keep these surfaces route-owned unless the IA pass discovers a genuinely stable subpattern worth extracting. Inventory URL filters/search, LiveView streams, rules draft/publish state, kill-switch emergency sequencing, and home/audience page orientation should remain visible in their route modules.

### Workflow Evidence Strategy

- **D-07:** Validate workflows with deterministic UI matrix fixtures plus selected real mounted-admin route evidence. Use the Phase 114 matrix for fixed component/state stress and real routes for route order, keyboard paths, mobile scan order, and workflow sequencing.
- **D-08:** Keep screenshots as generated artifacts for human review, not checked-in baselines or pixel-diff gates.
- **D-09:** Do not add broad demo seed semantics, product data assumptions, public routes, schemas, migrations, release workflow changes, Storybook, PhoenixStorybook, or pixel-baseline infrastructure for Phase 117 evidence.

### Mobile, Keyboard, And Focus

- **D-10:** Add route-level evidence for keyboard flow, focus order, command palette behavior, destructive-flow sequencing, and narrow viewport behavior across representative primary route clusters.
- **D-11:** Preserve the Phase 115 foundation contract for breakpoints, focus ring, reduced motion, radius/elevation, and dense technical containment unless multiple route failures prove a concrete shared foundation regression.
- **D-12:** Prefer semantic links, buttons, and forms in route fixes. Use DOM-aware JavaScript only for focus-heavy widgets that already require it, such as the command palette.

### Explain, Simulate, And Audit

- **D-13:** Include audit, explain, and simulate in route-cluster evidence so FLOW-01 through FLOW-04 cover explain/diagnose and audit jobs.
- **D-14:** Edit audit, explain, and simulate only when route evidence shows a hierarchy failure: missing first-glance answer, buried permalink/sample/context, unclear redaction, inaccessible raw detail, poor mobile/keyboard flow, or audit rows that strand Support/SRE instead of linking back to the next useful surface.
- **D-15:** Do not treat audit/explain/simulate forms as remaining Phase 116 component debt. Their URL state, redaction boundaries, fixture export, raw detail, and support-safe trace copy remain route-owned.

### Ecosystem Lessons Applied

- **D-16:** Borrow external-product lessons at the concept level only. Successful flag/admin tools make flags, audiences/segments, kill switches, approvals, and audit history reachable; Phase 117 should improve reachability and route hierarchy without copying standalone-console rail sprawl.
- **D-17:** Keep emergency and destructive workflows contextual. Kill-switch and archive/delete paths should remain guarded flows with clear evidence, reason, typed confirmation where needed, back links, disabled/unavailable explanations, and audit handoff.
- **D-18:** Keep evidence pragmatic and CI-readable. Playwright should prove browser-only concerns such as focus, keyboard, overflow, roles, screenshots, and route sequencing; ExUnit/source assertions remain preferable for component/source boundary checks.

### the agent's Discretion

The planner may choose the exact plan split, route evidence set, and names for any Phase 117 review artifacts. Prefer a compact route-cluster IA review artifact that maps operator job, route, page-owned surface, state coverage, issue found, action taken, and proof command. Keep fixes vertical and small: evidence first, then route-level IA adjustment, then focused verification.

### Folded Todos

None - no pending todos matched Phase 117.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Prior Phase Artifacts

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
- `.planning/phases/115-foundations-hardening/115-CONTEXT.md`
- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md`
- `.planning/phases/115-foundations-hardening/115-VERIFICATION.md`
- `.planning/phases/116-primitive-composite-polish/116-CONTEXT.md`
- `.planning/phases/116-primitive-composite-polish/116-RAW-MARKUP-CONSOLIDATION.md`
- `.planning/phases/116-primitive-composite-polish/116-PHASE-117-HANDOFF.md`
- `.planning/phases/116-primitive-composite-polish/116-VERIFICATION.md`

### Prompt Anchors

- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/rulestead-domain-language-field-guide.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `prompts/rulestead-telemetry-observability-and-audit.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`

### Source Files

- `rulestead_admin/lib/rulestead_admin/navigation.ex`
- `rulestead_admin/lib/rulestead_admin/components/shell.ex`
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`
- `rulestead_admin/lib/rulestead_admin/components/simulate_components.ex`
- `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex`
- `rulestead_admin/lib/rulestead_admin/live/audience_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex`
- `rulestead_admin/priv/static/css/rulestead_admin.css`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex`
- `examples/demo/frontend/tests/ui-matrix.spec.ts`
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`
- `examples/demo/frontend/tests/support/admin.ts`

### External Research References

- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html`
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html`
- `https://launchdarkly.com/docs/home/flags/killswitch`
- `https://docs.getunleash.io/concepts/segments`
- `https://docs.flagsmith.com/administration-and-security/governance-and-compliance/audit-logs`
- `https://playwright.dev/docs/test-snapshots`
- `https://www.w3.org/WAI/ARIA/apg/patterns/combobox/`
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `RulesteadAdmin.Navigation` is already the single source of truth for the top-level rail, home launcher, and command-palette grouping.
- `RulesteadAdmin.Components.Shell.page/1` owns shell chrome, command palette, context controls, theme control, breadcrumbs, rail, flash stack, and brand lockup.
- Phase 116 completed reusable primitives and composites: `OperatorComponents.form_field/1`, `action_row/1`, `state_note/1`, `ConfirmComponents.mutation_confirm/1`, and polished domain composites for audit, rollout, rule editor, audience, governance, simulate, and traces.
- `/dev/rulestead-admin/ui-matrix` already renders real admin components with deterministic long-label, dense, destructive, read-only, unavailable, audit, rollout, audience, governance, and rare-state fixtures.
- `examples/demo/frontend/tests/ui-matrix.spec.ts` already provides the matrix evidence pattern for themes, viewports, reduced motion, no horizontal overflow, command palette structure, source boundaries, and screenshot artifacts.

### Established Patterns

- The mounted admin is a Phoenix LiveView surface inside a host app. Host applications own auth, session, layout, and deployment; Rulestead should not widen the mounted route/public package contract in Phase 117.
- Route/query state belongs in route modules via `handle_params/3`, `push_patch`, streams, and route-owned form handling. Component extraction should not hide URL state, streams, draft/publish state, redaction semantics, or emergency sequencing.
- The admin is responsive but not mobile-first. Narrow viewport work should preserve critical operator paths, avoid page-level overflow, and keep primary actions reachable without weakening desktop density.
- v1.17 evidence uses deterministic assertions and generated screenshot artifacts, not broad checked-in visual baselines or external AI judging.
- Brand and UI polish should stay inside the current brandbook/token system. No palette, logo, radius, shadow, or foundation language should be redesigned in Phase 117.

### Integration Points

- Phase 117 should add a compact IA/review artifact or equivalent summary that is easy for Phase 118 to verify against FLOW-01 through FLOW-04.
- Route-level Playwright evidence should reuse the existing demo backend URL conventions and theme/viewport patterns from `ui-matrix.spec.ts` and `brand-ui-evidence.spec.ts`.
- Backend/source assertions may prove route-cluster mappings, forbidden tooling boundaries, and fixture health; Playwright should be reserved for rendered route behavior.
- Phase 118 will own milestone-wide screenshot/assertion closeout and any durable guard-chain extension. Phase 117 should hand it a route evidence map and proof commands, not broad new infrastructure.
</code_context>

<specifics>
## Specific Ideas

- Preferred review artifact: `117-FLOW-IA-REVIEW.md` with columns for operator job, route cluster, page-owned surface, evidence state, finding, action, proof, and follow-on.
- Inventory IA focus: search/filter hierarchy, token removal, suggestion visibility, clear-query affordances, view tabs, result count/pagination relationship, stale cleanup prominence, and mobile card scan order.
- Rules workspace focus: draft versus active status, publish/save/move/archive hierarchy, sidebar balance, missing-audience recovery, keyboard order through editor controls, and narrow viewport action reachability.
- Kill-switch focus: emergency decision order, current serving state, evidence, reason, typed key, disabled/unavailable escalation, diagnostics link, audit history, and after-action return path.
- Home focus: attention priority, navigation group consistency, onboarding versus intermediate versus advanced task balance, empty/no-urgent-work copy, and command-palette alignment.
- Audience focus: inventory density, hidden/denied dependency placement, action visibility, archived/read-only distinction, and mobile table/list usability.
- Audit/explain/simulate evidence should cover support-safe diagnosis, but fixes should be issue-triggered. Look for buried first answers, unclear sample/context, inaccessible raw detail, redaction ambiguity, weak links back to flag/timeline/explain, or keyboard/mobile failures.
- Route evidence should include light, dark, system-dark where visual behavior differs, desktop and mobile/narrow viewports, and at least one keyboard/focus path through a destructive or review workflow.
</specifics>

<deferred>
## Deferred Ideas

- Flat entity navigation, role/mode-based navigation, top-level Rollouts/Audiences/Audit/Destructive groups, top-level Rulesets, and top-level Settings remain deferred until a future explicit IA/product milestone.
- Component extraction for inventory/cards/rules/kill/home/audience remains deferred unless Phase 117 route evidence proves a stable reusable subpattern.
- Broad product-wide page redesign, mobile-first admin redesign, Phase 115 foundation rewrite, and Phase 116 primitive/composite re-polish are out of scope.
- Broad demo seed expansion, product seed semantics, checked-in pixel baselines, Storybook, PhoenixStorybook, and external AI visual judging remain deferred.
- Full audit/explain/simulate redesign remains deferred unless Phase 117 evidence proves those routes block explain/diagnose or audit jobs.
- Public runtime APIs, schemas/migrations, release workflow changes, palette/logo redesign, FleetDesk rebranding, v2 product wedges, and `rulestead_admin` standalone publish preparation remain out of scope.

### Reviewed Todos (not folded)

None - no pending todos matched Phase 117.
</deferred>

---

*Phase: 117-page-flow-ia-pass*
*Context gathered: 2026-06-14*
