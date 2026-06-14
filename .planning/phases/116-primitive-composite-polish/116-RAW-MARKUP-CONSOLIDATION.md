# Phase 116 Raw Markup Consolidation

## Scope

This ledger classifies current raw `rs-*` LiveView markup for Phase 116. It is not a CSS inventory and it is not a mandate to extract every class into a component.

Phase 116 may consolidate stable primitive structure, especially form fields, help text, action rows, blocked/unavailable copy, detail rows, and small status groups. Page-flow shells stay route-owned when extraction would hide URL state, LiveView streams, emergency workflow intent, or Phase 117 IA decisions.

CSS definition sites, token literals, static HTML fixtures, and matrix examples are not route-owned raw duplication. They remain evidence and styling inputs.

## Ledger

| Cluster | Source | Decision | Action | Reason | Follow-on |
| --- | --- | --- | --- | --- | --- |
| Flag inventory filters and omnisearch | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` (`rs-filter-panel`, `rs-omnisearch`, `rs-inventory-views`) | intentional page-owned | Keep the URL-driven omnisearch, token removal, suggestions, and inventory view patching route-owned. Consolidate only smaller form/action affordances if a stable primitive emerges. | The route owns committed query tokens, transient suggestions, pagination reset, and URL canonicalization. Extracting the full shell would hide critical state behavior. | Phase 117 reviews inventory IA and search ergonomics. |
| Flag inventory card stream | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` (`rs-card-list`, `rs-card--flag`, `rs-card__meta`, `rs-card__tags`) | intentional page-owned | Keep the streamed flag list route-owned. Reuse existing badge, tag, empty-state, and pagination primitives inside it. | The list is tied to `phx-update="stream"`, highlighted rows, stale cleanup links, and flag-specific metadata. | Phase 117 may revisit card/list IA after component polish. |
| Flag form fields | `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` (`rs-form-field`, `rs-form-help`, `rs-form-error`, `rs-fieldset`, radio-card groups) | consolidated target | Add or extend general form-field/help/action primitives only where they preserve caller-owned labels, inputs, errors, `phx-feedback-for`, and route validation. | Form field structure repeats across flag, audit, explain, and simulate routes, but the flag form has rich per-field validation and picker behavior that must stay route-owned. | Phase 116 Plan 01 primitive pass; Phase 117 only if full form IA changes are needed. |
| Rules workspace shell | `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` (`rs-rules-workspace`, layout, editor, toolbar, sidebar) | deferred to Phase 117 | Keep the workspace layout route-owned. Reuse and polish `RuleEditorComponents` in place rather than extracting the shell now. | The shell combines draft/publish behavior, ordered rule editing, sidebar context, and rule mutation state. It is page-flow IA, not a stable primitive. | Phase 117 page-flow and IA pass. |
| Kill-switch runbook | `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` (`rs-runbook`, state, signals, action, context, history, `rs-inline-actions`) | intentional page-owned | Keep the emergency runbook route-owned. Align copy, reason, typed confirmation, danger emphasis, diagnostics link, audit link, and disabled-state treatment with canonical confirm patterns. | The route is a 3am emergency workflow with distinct operator sequencing and audit context. The confirm/control semantics can align without hiding the runbook. | Phase 116 Plan 02 confirm alignment; Phase 117 may review emergency flow IA. |
| Audit filters | `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` (`rs-filter-grid`, `rs-form-field`) | consolidated target | Reuse shared form-field/filter-grid primitives where they do not change the audit query patching or empty-state behavior. | Audit filters are route-specific but use the same label/input/help layout repeated in explain and simulate forms. | Phase 116 Plan 01 primitive pass; Phase 118 evidence closeout keeps audit proof. |
| Explain form | `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex` (`rs-form`, `rs-form-grid`, `rs-form-field`, `rs-field-help`, `rs-form-actions`) | consolidated target | Move only stable field/help/action-row structure to primitives if it keeps URL permalink behavior, form names, and support-trace copy caller-owned. | Explain owns query-string permalink semantics and trait redaction boundaries. The reusable part is the form field/action skeleton. | Phase 116 Plan 01 primitive pass. |
| Simulate form | `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` (`rs-form`, `rs-form-grid`, `rs-form-field`, `rs-field-help`, `rs-form-actions`) | consolidated target | Reuse shared field/help/action primitives where possible. Keep archetypes, fixture export, redacted context, and trait parsing route-owned. | The simulation workspace has route-specific behavior, but the field/help/action structure repeats with explain and audit forms. | Phase 116 Plan 01 primitive pass; Phase 116 Plan 03 composite trace polish. |
| Audience edit preview action row | `rulestead_admin/lib/rulestead_admin/live/audience_live/edit_preview.ex` (`rs-mutation-confirm__actions`) | consolidated target | Replace or align the raw action row with a canonical action-row/confirm affordance when it preserves the preview-to-confirm route flow. | The raw class borrows confirm styling but this screen is a preview continuation, not the final mutation form. It should share layout semantics without pretending to be a confirm form. | Phase 116 Plan 02 confirm alignment. |
| Mutation confirm variants | `audience_live/archive_confirm.ex`, `audience_live/edit_confirm.ex`, `flag_live/cleanup_confirm.ex`, `flag_live/kill.ex` | consolidated target | Use `ConfirmComponents.mutation_confirm/1` where the shape matches. Document exceptions when route flow differs, especially kill-switch runbook and preview-only actions. | The shared confirm component is already canonical for governed mutation forms, but disabled, unavailable, read-only, and typed-confirm variants need first-class treatment. | Phase 116 Plan 02 owns this slice. |
| Audience inventory table | `rulestead_admin/lib/rulestead_admin/live/audience_live/index.ex` (`rs-table`, `rs-badge`) | intentional page-owned | Continue using table and badge primitives where present; do not extract the inventory page in Phase 116. | Inventory tables are route-specific and Phase 115 already owns dense table containment. Component polish should not rewrite page IA. | Phase 117 page-flow review if table IA needs changes. |
| Home attention and task board | `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex` (`rs-attention`, `rs-task-board`, `rs-task-group`) | deferred to Phase 117 | Leave the home launcher shell route-owned. Reuse task-link primitives but avoid redesigning dashboard composition in this phase. | Home is a page-flow surface around navigation, work queues, and operator orientation. | Phase 117 page-flow and IA pass. |

## Route-Owned Exceptions

- Flag inventory search, filters, and streamed cards remain route-owned because they manage URL state, transient suggestions, streams, highlighting, sorting, and pagination.
- Rules workspace layout remains route-owned because it combines editor flow, ordered rule behavior, validation, draft/publish actions, and sidebar context.
- Kill-switch runbook remains route-owned because it is an emergency workflow with distinct sequencing and after-action links.
- Audience inventory and home task board remain route-owned because they are page-flow surfaces, not stable primitive components.

## Deferred To Phase 117

Phase 117 should review page-flow and IA for:

- flag inventory search/card ergonomics
- rules workspace shell and sidebar composition
- kill-switch runbook sequencing
- home attention/task-board composition
- audience inventory table ergonomics

Phase 116 can leave these surfaces better aligned through shared primitives and copy, but it must not redesign their information architecture.

## Verification

- Every Phase 113 raw `rs-*` cluster named above is classified as `consolidated target`, `intentional page-owned`, or `deferred to Phase 117`.
- CSS definition sites, token literals, static fixtures, and UI matrix examples are explicitly excluded from raw LiveView duplication.
- Follow-on implementation must update this ledger in Plan 04 to reflect final status after extraction and polish.
