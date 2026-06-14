# Phase 117: Page Flow + IA Pass - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-14T16:19:05Z
**Phase:** 117-page-flow-ia-pass
**Mode:** assumptions with advisor research
**Areas analyzed:** Navigation and route clusters, page-owned IA surfaces, workflow evidence strategy, mobile/keyboard/focus scope, audit/explain/simulate priority

## Assumptions Presented

### Navigation And Route Clusters

| Assumption | Confidence | Evidence |
| --- | --- | --- |
| Preserve Overview, Build & release, Explain & diagnose, and Review & approve as top-level navigation; use audiences, rollouts, audit, destructive actions, onboarding, and denied/unavailable states as lenses inside those groups. | Confident | `rulestead_admin/lib/rulestead_admin/navigation.ex`, `113-UI-MATRIX-CONTRACT.md`, `116-PHASE-117-HANDOFF.md` |

### Page-Owned IA Surfaces

| Assumption | Confidence | Evidence |
| --- | --- | --- |
| Phase 117 should review page-owned IA surfaces rather than reopen primitive/composite polish. | Confident | `116-RAW-MARKUP-CONSOLIDATION.md`, `116-PHASE-117-HANDOFF.md`, `flag_live/index.ex`, `flag_live/rules.ex`, `flag_live/kill.ex`, `home_live/index.ex`, `audience_live/index.ex` |

### Workflow Evidence Strategy

| Assumption | Confidence | Evidence |
| --- | --- | --- |
| Use deterministic matrix fixtures plus selected real admin route evidence; avoid seed semantics, public routes, schemas, Storybook, and pixel baselines. | Likely, upgraded to Confident after advisor research | `114-CONTEXT.md`, `ui_matrix_live.ex`, `ui_matrix_fixtures.ex`, `ui-matrix.spec.ts`, `brand-ui-evidence.spec.ts`, Playwright visual comparison docs |

### Mobile, Keyboard, And Focus

| Assumption | Confidence | Evidence |
| --- | --- | --- |
| Test route-level keyboard flow, focus order, command palette behavior, destructive sequencing, and narrow viewport behavior while preserving Phase 115 foundations. | Confident | `115-FOUNDATIONS-CONTRACT.md`, `ui-matrix.spec.ts`, `brand-ui-evidence.spec.ts`, `shell.ex`, WAI-ARIA combobox/dialog patterns |

### Audit, Explain, And Simulate Priority

| Assumption | Confidence | Evidence |
| --- | --- | --- |
| Audit, explain, and simulate should receive route evidence but only issue-triggered fixes; priority implementation remains inventory, rules, kill switch, home, and audience IA. | Likely, upgraded to Confident after advisor research | `116-PHASE-117-HANDOFF.md`, `audit_live/index.ex`, `flag_live/explain.ex`, `flag_live/simulate.ex`, `simulate_components.ex`, `audit_components.ex` |

## Advisor Research Requested

After the first assumptions were presented, the user asked for deeper subagent-backed research for each gray area:

- Pros, cons, tradeoffs, and examples for each approach.
- Idiomatic Elixir, Plug, Ecto, Phoenix, and LiveView fit.
- Lessons from successful feature-flag, admin, observability, and design-system tools.
- UX, accessibility, microcopy, design-system, dark/light/system, and persona/JTBD lenses where applicable.
- One cohesive recommendation set so downstream planning does not push routine choices back to the user.

Five `gsd-advisor-researcher` agents were spawned, one per gray area. All five converged on the same strategy: keep Phase 117 route-flow focused, preserve the current navigation model, review the named page-owned surfaces, use deterministic matrix plus selected route evidence, test keyboard/mobile/focus at route level, and keep audit/explain/simulate fixes evidence-triggered.

## Alternatives Considered

### Navigation Alternatives

| Option | Reason Rejected |
| --- | --- |
| Flat entity rail | Familiar in standalone tools, but scan-heavy under pressure and inconsistent with current grouped mounted-admin model. |
| Role/mode navigation | Adds hidden state, complicates shared URLs and keyboard paths, and risks mismatching host-owned auth. |
| New top-level domain groups | Useful for larger standalone consoles, but overfits v1.17 stress lenses into permanent route shape. |

### IA Surface Alternatives

| Option | Reason Rejected |
| --- | --- |
| Component extraction first | Would hide route-owned URL state, streams, draft/publish behavior, and emergency sequencing. |
| Uniform page redesign | Too broad for v1.17 and likely to create Phase 118 screenshot/evidence churn. |
| Bugfix-only pass | Too narrow to satisfy FLOW-01 and FLOW-02. |

### Evidence Alternatives

| Option | Reason Rejected |
| --- | --- |
| Broad demo seed expansion | Creates setup fragility and semantic drift between demo fixtures and product truth. |
| Source-only audit | Cannot prove rendered keyboard, focus, mobile, overflow, and hierarchy behavior. |
| Checked-in pixel baselines | Playwright supports them, but browser rendering varies by environment and baselines add review churn. |
| Storybook/PhoenixStorybook | Useful future documentation option, but duplicates or widens the current Phoenix matrix evidence surface. |

### Mobile/Accessibility Alternatives

| Option | Reason Rejected |
| --- | --- |
| Foundation-wide CSS rewrite | Reopens Phase 115 without evidence of a shared foundation defect. |
| Mobile-first admin redesign | Conflicts with the current responsive-but-not-mobile-first operator posture. |
| Matrix-only checks | Insufficient for real route tab order, URL state, destructive sequencing, and scan order. |

### Audit/Explain/Simulate Alternatives

| Option | Reason Rejected |
| --- | --- |
| Full route redesign | Could improve polish, but reopens Phase 116 and crowds out higher-risk Phase 117 surfaces. |
| No review | Fails explain/diagnose and audit route-cluster coverage. |
| Treat forms as component debt | Misclassifies route-owned URL state, redaction, fixture export, and support-safe copy as reusable component work. |

## External Research

- Phoenix LiveView docs reinforced route-owned state handling through `mount/3`, `handle_params/3`, live patches, events, assigns, and regular HTML fallback.
- Phoenix LiveComponent docs reinforced that component abstraction should be used for real state/event encapsulation, not organization-only extraction.
- LaunchDarkly kill switch docs reinforced keeping emergency shutdown workflows simple, prominent, and contextual.
- Unleash segment docs reinforced reusable audience/segment reachability and dependency clarity without forcing new top-level IA.
- Flagsmith audit docs reinforced audit history as a governance/compliance surface that must remain easy to inspect.
- Playwright visual comparison docs reinforced why checked-in screenshot baselines are useful but environment-sensitive and higher maintenance than generated artifacts for this milestone.
- WAI-ARIA combobox and modal dialog patterns reinforced explicit keyboard/focus evidence for command palette and destructive/modal-like flows.

## Corrections Made

No corrections were made to the original assumption direction. The user requested deeper research before accepting them; the researched recommendation set strengthened and refined the decisions captured in `117-CONTEXT.md`.

## Auto-Resolved

Not applicable.
