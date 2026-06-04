---
phase: 92
slug: ia-home-refinement
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 92 — Validation Strategy

> Real-screen refinement of home/overview + global nav. Validation = both-theme screenshots of the home + nav against the ISOLATED demo (built from this branch, alt ports; main :4000 untouched) + the Phase 91 contrast gate staying green + compile.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Real admin | isolated demo, backend `http://127.0.0.1:60485` (project rulestead_demo_jon_fix_admin-ui-...) |
| Auth | `goto /demo/sign-in` → auto-redirect to `/admin/flags` |
| Screenshot | Playwright (`examples/demo/frontend`), `addInitScript` presets `localStorage["rulestead_admin.theme"]` for dark |
| Gate | Phase 91 `design-system.spec.ts` stays 0-violation; theme-control/cascade/scope stay green |
| Compile | `cd rulestead_admin && mix compile --warnings-as-errors` |

## Sampling Rate
- Per edit: re-screenshot home + affected nav surface both themes; run design-system gate.
- Phase gate: home + nav legible/on-brand/clear in both themes; no new sub-AA pairs; compile clean.

## Per-Requirement Verification Map

| Req | Behavior | Method | Pass condition |
|-----|----------|--------|----------------|
| IA-01 | Home makes "what needs me / where do I go" obvious for operator/support/SRE, both themes | screenshot | clear hierarchy: Needs-you-now → What's-live-&-moving → task launcher; legible + on-brand light + dark |
| IA-02 | Global nav + orientation affordances consistent + least-surprise across screens, both themes | screenshot | task-rhythm rail consistent; header (incl. theme control) legible both themes; breadcrumbs/sub-nav consistent |
| — | Any refinement is token-driven; no new sub-AA pairs | design-system gate | 0 violations both themes |
| — | Existing theme specs green; compile clean | Playwright + compile | green; exit 0 |

## Baseline evidence (current state, pre-refinement)
Real isolated-demo screenshots captured at `/tmp/rs-shots/screens/{home,flags,flag-detail,rules,rollouts,explain,audit,experiments,audiences,schedule,diagnostics,compare,change-reqs}-{light,dark}.png`. Home + nav already render cleanly and on-brand in dark (theme control in header working; tone bars legible; task-rhythm IA intact). Refinement is evidence-driven and minimal — improve clarity/hierarchy/consistency where the real render shows a genuine gap; do NOT churn.

## Phase-Complete Definition
Home/overview + global nav are clear and on-brand in BOTH themes for the three personas (verified by both-theme screenshots), all refinements are token-driven, the Phase 91 contrast gate stays at zero violations, and existing theme specs + compile stay green.
