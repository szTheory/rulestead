# Phase 116 Raw Markup Consolidation

## Scope

This ledger classifies current raw `rs-*` LiveView markup for Phase 116. It is not a CSS inventory and it is not a mandate to extract every class into a component.

Phase 116 may consolidate stable primitive structure, especially form fields, help text, action rows, blocked/unavailable copy, detail rows, and small status groups. Page-flow shells stay route-owned when extraction would hide URL state, LiveView streams, emergency workflow intent, or Phase 117 IA decisions.

CSS definition sites, token literals, static HTML fixtures, and matrix examples are not route-owned raw duplication. They remain evidence and styling inputs.

## Ledger

| Cluster | Source | Decision | Action | Reason | Follow-on |
| --- | --- | --- | --- | --- | --- |
| Flag inventory filters and omnisearch | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` (`rs-filter-panel`, `rs-omnisearch`, `rs-inventory-views`) | final: intentional page-owned | Kept the URL-driven omnisearch, token removal, suggestions, and inventory view patching route-owned. No Phase 116 extraction was made. | The route owns committed query tokens, transient suggestions, pagination reset, and URL canonicalization. Extracting the full shell would hide critical state behavior. | Phase 117 reviews inventory IA, search ergonomics, and filter hierarchy. |
| Flag inventory card stream | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` (`rs-card-list`, `rs-card--flag`, `rs-card__meta`, `rs-card__tags`) | final: intentional page-owned | Kept the streamed flag list route-owned while preserving existing badge, tag, empty-state, and pagination primitive usage. | The list is tied to `phx-update="stream"`, highlighted rows, stale cleanup links, and flag-specific metadata. | Phase 117 may revisit card/list IA after component polish. |
| Flag form fields | `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` (`rs-form-field`, `rs-form-help`, `rs-form-error`, `rs-fieldset`, radio-card groups) | final: primitive support landed, rich form remains route-owned | Added `OperatorComponents.form_field/1`, `action_row/1`, and `state_note/1` as reusable primitives. Did not broadly rewrite the rich flag form because field validation, picker behavior, and feedback ownership remain route-specific. | Form field structure repeats across flag, audit, explain, and simulate routes, but the flag form has rich per-field validation and picker behavior that must stay route-owned. | Phase 117 only if full form IA or route flow changes are needed. |
| Rules workspace shell | `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` (`rs-rules-workspace`, layout, editor, toolbar, sidebar) | final: deferred page-flow surface | Kept the workspace layout route-owned. Polished `RuleEditorComponents` in place and added matrix evidence for authored-state boundaries instead of extracting the shell. | The shell combines draft/publish behavior, ordered rule editing, sidebar context, and rule mutation state. It is page-flow IA, not a stable primitive. | Phase 117 page-flow and IA pass should review workspace layout and sidebar composition. |
| Kill-switch runbook | `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex` (`rs-runbook`, state, signals, action, context, history, `rs-inline-actions`) | final: intentional page-owned, copy/control aligned | Kept the emergency runbook route-owned while aligning reason, typed confirmation, danger emphasis, diagnostics link, audit link, and disabled-state treatment with canonical confirm patterns. | The route is a 3am emergency workflow with distinct operator sequencing and audit context. The confirm/control semantics can align without hiding the runbook. | Phase 117 may review emergency flow sequencing and after-action IA. |
| Audit filters | `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` (`rs-filter-grid`, `rs-form-field`) | final: primitive support available, route behavior retained | Added reusable form-field/action primitives for future safe call-site use, but did not rewrite audit query patching or empty-state behavior in Phase 116. | Audit filters are route-specific but use the same label/input/help layout repeated in explain and simulate forms. | Phase 117 may review audit filter hierarchy; Phase 118 keeps audit proof in milestone evidence. |
| Explain form | `rulestead_admin/lib/rulestead_admin/live/flag_live/explain.ex` (`rs-form`, `rs-form-grid`, `rs-form-field`, `rs-field-help`, `rs-form-actions`) | final: primitive support available, route behavior retained | Added reusable field/help/action primitives and polished trace copy in reusable simulation/explain components. Did not hide URL permalink behavior, form names, or support-trace copy inside a broader component. | Explain owns query-string permalink semantics and trait redaction boundaries. The reusable part is the form field/action skeleton. | Phase 117 can assess explain route form hierarchy if page-flow evidence demands it. |
| Simulate form | `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` (`rs-form`, `rs-form-grid`, `rs-form-field`, `rs-field-help`, `rs-form-actions`) | final: primitive support available, trace composite polished | Added reusable field/help/action primitives and support-safe trace labels. Kept archetypes, fixture export, redacted context, and trait parsing route-owned. | The simulation workspace has route-specific behavior, but the field/help/action structure repeats with explain and audit forms. | Phase 117 can review simulation page hierarchy; no hidden Phase 116 component work remains. |
| Audience edit preview action row | `rulestead_admin/lib/rulestead_admin/live/audience_live/edit_preview.ex` (`rs-mutation-confirm__actions`) | final: consolidated | Replaced borrowed confirm action-row markup with `OperatorComponents.action_row/1` while preserving the preview-to-confirm route flow. | The raw class borrowed confirm styling but this screen is a preview continuation, not the final mutation form. It now shares layout semantics without pretending to be a confirm form. | None for Phase 117 unless broader audience preview flow IA changes are planned. |
| Mutation confirm variants | `audience_live/archive_confirm.ex`, `audience_live/edit_confirm.ex`, `flag_live/cleanup_confirm.ex`, `flag_live/kill.ex` | final: canonicalized where shapes match; exception documented | Strengthened `ConfirmComponents.mutation_confirm/1` for typed, disabled, unavailable, read-only, scope, evidence, and back-link states. Audience archive/edit and cleanup confirm flows use the canonical component where shape matches; kill-switch remains runbook-owned. | The shared confirm component is canonical for governed mutation forms, but emergency runbook sequencing differs and stays page-owned. | Phase 117 may review destructive route flow sequencing, not confirm component behavior. |
| Audience inventory table | `rulestead_admin/lib/rulestead_admin/live/audience_live/index.ex` (`rs-table`, `rs-badge`) | final: intentional page-owned | Continued using table and badge primitives where present. Did not extract the inventory page in Phase 116. | Inventory tables are route-specific and Phase 115 already owns dense table containment. Component polish should not rewrite page IA. | Phase 117 page-flow review if table IA needs changes. |
| Home attention and task board | `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex` (`rs-attention`, `rs-task-board`, `rs-task-group`) | final: deferred page-flow surface | Left the home launcher shell route-owned. Task-link primitives remain the reusable layer; dashboard composition was not redesigned in Phase 116. | Home is a page-flow surface around navigation, work queues, and operator orientation. | Phase 117 page-flow and IA pass should review home attention/task-board composition. |

## Route-Owned Exceptions

- Flag inventory search, filters, and streamed cards remain route-owned because they manage URL state, transient suggestions, streams, highlighting, sorting, and pagination.
- Rules workspace layout remains route-owned because it combines editor flow, ordered rule behavior, validation, draft/publish actions, and sidebar context.
- Kill-switch runbook remains route-owned because it is an emergency workflow with distinct sequencing and after-action links.
- Audience inventory and home task board remain route-owned because they are page-flow surfaces, not stable primitive components.

## Phase 117 Follow-On

Phase 117 should review page-flow and IA for:

- flag inventory search/card ergonomics
- rules workspace shell and sidebar composition
- kill-switch runbook sequencing
- home attention/task-board composition
- audience inventory table ergonomics
- audit/explain/simulate form hierarchy only if full-route evidence shows least-surprise issues

Phase 116 can leave these surfaces better aligned through shared primitives and copy, but it must not redesign their information architecture.

## Verification

- Every Phase 113 raw `rs-*` cluster named above is now classified with a final Phase 116 disposition: `final: consolidated`, `final: primitive support available`, `final: intentional page-owned`, or `final: deferred page-flow surface`.
- CSS definition sites, token literals, static fixtures, and UI matrix examples are explicitly excluded from raw LiveView duplication.
- No pending or unknown raw-markup decisions remain for Phase 116.
- Phase 117 receives page-flow and IA follow-ons only; no hidden primitive, confirm, or composite consolidation work remains in this ledger.
