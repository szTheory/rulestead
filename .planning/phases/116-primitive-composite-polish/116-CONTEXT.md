# Phase 116: Primitive + Composite Polish - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 116 tunes the reusable mounted-admin building blocks and repeated component groups as a coherent system. It covers primitive consistency for badges, buttons, forms, cards, callouts, stats, tags, pagination, detail grids, task links, and empty states; raw `rs-*` consolidation or documented exceptions; mutation-confirm consistency; reusable domain composite polish; and concise operator-specific microcopy.

This phase must not reopen Phase 115 foundation decisions, change page-flow IA for Phase 117, perform milestone-wide evidence closeout for Phase 118, add public runtime APIs, add schemas/migrations, redesign the palette or logo, adopt Storybook or a component framework, add broad checked-in pixel baselines, rebrand FleetDesk, change release workflow, or prepare `rulestead_admin` for standalone publication.
</domain>

<decisions>
## Implementation Decisions

### Component Consolidation

- **D-01:** Use existing Phoenix function component modules as the primary polish surface. Extend `RulesteadAdmin.Components.OperatorComponents`, `FlagComponents`, `ConfirmComponents`, and the existing domain component modules before adding new abstractions.
- **D-02:** Keep component APIs declarative with `attr` and `slot` contracts. Do not introduce LiveComponents for ordinary markup reuse, JavaScript component frameworks, Storybook, PhoenixStorybook, or third-party UI libraries.
- **D-03:** Prefer small canonical primitives for repeated form, filter, action-row, unavailable/blocked, and state-copy patterns when reuse is clear from current route call sites.

### Foundation Boundary

- **D-04:** Treat `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` as the active foundation contract. Use its token, breakpoint, focus, reduced-motion, radius, elevation, and dense-content containment rules instead of redefining foundations in this phase.
- **D-05:** CSS edits are allowed only where component polish needs selector support or consolidation. They must preserve the four-block theme cascade, existing token scope, foundation guard behavior, and no page-level mobile overflow posture.
- **D-06:** Do not change palette values, logo treatment, font families, scalar token hierarchy, breakpoint policy, focus-ring contract, reduced-motion floor, or broad guard-chain responsibilities in Phase 116.

### Mutation Confirm Flows

- **D-07:** Treat `RulesteadAdmin.Components.ConfirmComponents.mutation_confirm/1` as the canonical confirm affordance for governed mutations. The shared pattern remains preview -> confirm -> audit with scope/evidence, required reason, optional typed confirmation, danger emphasis, return link, and submit action.
- **D-08:** Strengthen mutation-confirm support for disabled, unavailable, read-only, and typed-confirm variants so confirm screens explain why an action cannot proceed without relying on opacity or color alone.
- **D-09:** Migrate bounded confirm-flow stragglers to the canonical confirm component where the shape matches. Keep the emergency kill-switch runbook layout page-owned, but align its reason, typed confirmation, danger emphasis, diagnostic/audit links, and disabled-state treatment with the canonical pattern.

### Domain Composites

- **D-10:** Polish reusable domain composites in place: audit/timeline/diff, rollout/guardrail/auto-advance, rule editor, audience impact/dependency, governance/blast-radius, simulate/explain trace, and audience trace groups.
- **D-11:** Use the repo-native UI matrix at `/dev/rulestead-admin/ui-matrix` as the primary stress surface for component/composite polish. Keep fixtures deterministic and extend them only when a polish decision needs a missing state.
- **D-12:** Preserve domain semantics while polishing. Do not change rollout eligibility, governance thresholds, audit provenance, authorization policy, preview uncertainty claims, or authored-state behavior.

### Raw `rs-*` Markup

- **D-13:** Consolidate repeated raw markup only when it represents a stable reusable primitive or composite. Good candidates include form-field/help text structure, filter-grid shell behavior, action-row layout, blocked/unavailable callouts, and shared status/detail rows.
- **D-14:** Document route-owned exceptions when extraction would hide important flow-specific behavior. Likely intentional exceptions include the flag inventory omnisearch/card stream, the rules workspace layout shell, the kill-switch runbook, and other page-specific workflow layouts that belong to Phase 117 IA review.
- **D-15:** Any raw `rs-*` consolidation must preserve LiveView stream behavior, URL-driven filter state, keyboard/focus affordances, and existing route semantics.

### Microcopy

- **D-16:** Component-level microcopy should be concise, operator-specific, and state-specific: success, warning, blocked, destructive, unavailable, permission-denied, and read-only states should name what happened, why it matters, and the next safe action.
- **D-17:** Preserve Rulestead's support-truth posture. Missing host evidence, stale guardrails, preview uncertainty, hidden references, and denied permissions must be explicit and must not be softened into optimistic or ambiguous copy.
- **D-18:** Status meaning must remain color plus text/semantics, never color-only. Danger/destructive language should stay calm and precise rather than dramatic.

### Methodology

- **D-19:** Apply the project methodology lenses as recommendation-first defaults. The selected polish approach does not change public API, schema, security/governance posture, package boundary, release model, product scope, FleetDesk branding, or publish posture, so no additional high-impact user decision is required before planning.

### Folded Todos

None - no pending todos matched Phase 116.

### the agent's Discretion

The planner may choose exact component function names, fixture helper names, test assertions, and extraction order, provided changes stay within Phase 116 scope and remain easy for later Phase 117/118 work to consume. Prefer a compact consolidation ledger or summary artifact that names each raw `rs-*` cluster as consolidated or intentionally page-owned.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning and Scope

- `.planning/ROADMAP.md` - Phase 116 goal, dependency, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - CMP-01 through CMP-05 requirements and v1.17 out-of-scope constraints.
- `.planning/STATE.md` - Current v1.17 state, prior phase decisions, and linked-version sibling-package constraints.
- `.planning/METHODOLOGY.md` - Recommendation-first, research-then-recommend, and architect-default discuss lenses.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md` - v1.17 taxonomy, raw `rs-*` classification, operator lenses, and evidence posture.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md` - Component taxonomy, raw LiveView markup ledger, and Phase 116 consolidation handoff.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-UI-MATRIX-CONTRACT.md` - Required states, evidence dimensions, operator lenses, and fixture-data needs.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-ACCEPTANCE-GATES.md` - Guard-chain responsibilities and downstream phase boundaries.
- `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md` - Matrix harness placement and real-component evidence decisions.
- `.planning/phases/114-repo-native-component-matrix-harness/114-UI-SPEC.md` - UI contract for the real Phoenix matrix surface.
- `.planning/phases/114-repo-native-component-matrix-harness/114-02-SUMMARY.md` - Playwright matrix evidence, screenshot posture, and mobile overflow fix history.
- `.planning/phases/115-foundations-hardening/115-CONTEXT.md` - Foundation-only boundary and Phase 116 deferrals.
- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` - Active token, breakpoint, focus, reduced-motion, radius/elevation, and dense-content foundation contract.
- `.planning/phases/115-foundations-hardening/115-VERIFICATION.md` - Proof that FND-01 through FND-06 are complete and should not be reopened.
- `.planning/phases/115-foundations-hardening/115-03-SUMMARY.md` - Matrix foundation evidence and residual command-palette evidence risk.

### Prompt Anchors

- `prompts/rulestead-admin-ux-and-operator-ia.md` - Mounted admin UX thesis, preview -> confirm -> audit, keyboard-first ergonomics, destructive action, empty/error, responsive, and accessibility rules.
- `prompts/rulestead-personas-jtbd-and-onboarding.md` - Operator, support, SRE, reviewer, and contributor jobs-to-be-done that shape component copy and state treatment.
- `prompts/rulestead-testing-and-e2e-strategy.md` - Curated Playwright evidence posture and deterministic assertion guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` - Function component, attr/slot, thin LiveView, URL-state, form, and behavior-test guidance.

### Source Files

- `rulestead_admin/priv/static/css/rulestead_admin.css` - Live mounted-admin CSS for component selectors and Phase 115 foundation rules.
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` - Shared operator primitives: banners, sections, rows, detail grids, task links, signals, empty states, summary grids, status lists, trace panels, and timelines.
- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` - Badges, tags, pagination, stats, cards, callouts, and flag subnav.
- `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex` - Canonical mutation-confirm component.
- `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` - Rollout ladder, guardrail, risky-jump, and auto-advance composites.
- `rulestead_admin/lib/rulestead_admin/components/rule_editor_components.ex` - Rules workspace composites and rule cards.
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` - Kill-switch banner/form, audit timeline, raw detail, and diff components.
- `rulestead_admin/lib/rulestead_admin/components/audience_components.ex` - Audience dependency and impact preview composites.
- `rulestead_admin/lib/rulestead_admin/components/audience_trace_components.ex` - Audience trace composite.
- `rulestead_admin/lib/rulestead_admin/components/governance_components.ex` - Blast-radius governance panel.
- `rulestead_admin/lib/rulestead_admin/components/simulate_components.ex` - Simulation archetype, fixture export, and trace disclosure composites.
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - Real-component matrix surface and Phase 116 stress examples.
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - Deterministic long-label, dense, destructive, rare-state, and composite fixture assigns.
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - Backend matrix smoke/source-boundary tests.
- `examples/demo/frontend/tests/ui-matrix.spec.ts` - Playwright matrix evidence across themes, viewports, reduced motion, overflow, source markers, and screenshot artifacts.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` - Flag inventory raw markup and card/filter/omnisearch consolidation candidates.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` - Rules workspace route-owned shell and component call sites.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` - Emergency runbook and kill-switch confirm flow.
- `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` - Audit filter form and empty-state call sites.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex` - Explain form and explanation component call sites.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` - Simulation form and trace/archetype call sites.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` - Repeated flag form-field structure.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `RulesteadAdmin.Components.OperatorComponents` already owns many general primitives and should be extended before new primitive modules are introduced.
- `RulesteadAdmin.Components.FlagComponents` owns status badges, tag lists, pagination, stats, section cards, callouts, and the flag subnav.
- `RulesteadAdmin.Components.ConfirmComponents.mutation_confirm/1` already documents and renders the canonical confirm form shape.
- `RulesteadAdmin.Components.RolloutComponents`, `RuleEditorComponents`, `AuditComponents`, `AudienceComponents`, `AudienceTraceComponents`, `GovernanceComponents`, and `SimulateComponents` provide the reusable domain composite groups Phase 116 should polish.
- The Phase 114 UI matrix route renders all major primitive and composite families with deterministic long-label, long-key, dense, destructive, read-only, unavailable, and rare-state fixtures.

### Established Patterns

- The mounted admin is Phoenix LiveView with function components and scoped CSS, not a standalone JS app or component framework.
- Theme-sensitive tokens stay scoped to `.rs-shell` / `[data-rulestead]`; scalar tokens and foundation rules are now guard-backed by Phase 115.
- Evidence remains curated screenshots plus deterministic assertions, not broad checked-in pixel baselines or visual-diff tooling.
- Status and danger affordances need text/semantic reinforcement; color-only status remains disallowed.
- Mobile/narrow behavior is containment and usability focused, not a mobile-first redesign.
- FleetDesk remains a host-owned demo app and must not be brought into Rulestead component polish.

### Integration Points

- Component polish should update reusable component modules, their CSS selectors, the UI matrix fixtures/examples, focused ExUnit component/matrix tests, and targeted Playwright matrix evidence.
- Raw route markup should be touched only when consolidating stable repeated patterns or aligning mutation-confirm behavior without changing route semantics.
- Phase 116 output should hand Phase 117 a clear ledger of page-owned exceptions and any route-flow issues that require full IA review.
- Phase 118 will own milestone-wide screenshot/assertion closeout and any broader reusable guard extension.
</code_context>

<specifics>
## Specific Ideas

- Use a consolidation ledger with columns such as cluster, source files, decision, action taken, reason, and follow-on phase.
- Add or extend matrix rows only for states needed to verify CMP-01 through CMP-05, especially disabled/unavailable mutation-confirm variants and microcopy-sensitive blocked/destructive states.
- For forms, prefer a shared form-field/help/action-row primitive only if it can cover current flag, audit, explain, and simulate call sites without obscuring LiveView form behavior.
- For confirm flows, align copy around "preview", "reason", "type the key", "unavailable", "return", and "audit timeline" language.
- Keep high-density technical panels local-scroll capable and compatible with the Phase 115 raw-detail/table containment rules.
</specifics>

<deferred>
## Deferred Ideas

- Full page-flow and IA changes belong to Phase 117.
- Milestone-wide screenshot/assertion closeout and reusable guard-chain extensions belong to Phase 118.
- Broad redesign of flag inventory, rules workspace, or kill-switch runbook layout belongs to Phase 117 unless a small component extraction is clearly reusable and low-risk.
- Foundation breakpoints, token hierarchy, focus-ring contract, reduced-motion policy, radius/elevation rules, and dense-content containment are complete in Phase 115 and should not be reopened here.
- PhoenixStorybook, JavaScript Storybook, broad checked-in pixel baselines, external AI visual judging, forced-colors/high-contrast OS mode, v2 product wedges, FleetDesk rebranding, and `rulestead_admin` standalone publish preparation remain out of scope.

### Reviewed Todos (not folded)

None - no pending todos matched Phase 116.
</deferred>

---

*Phase: 116-primitive-composite-polish*
*Context gathered: 2026-06-14*
