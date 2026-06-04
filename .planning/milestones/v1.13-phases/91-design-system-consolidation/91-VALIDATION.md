---
phase: 91
slug: design-system-consolidation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 91 — Validation Strategy

> Consolidation + documentation + the regression-gate fixture. Validation = the new automated contrast spec passing zero sub-AA pairs in both themes + comprehensive fixture screenshots + doc-accuracy greps. file:// only (no demo).

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Playwright (`examples/demo/frontend`) + the canonical design-system fixture (`file://`) |
| Gate spec | `design-system.spec.ts` (enumerated WCAG-AA pair assertions, both themes) |
| Helper | `tests/support/contrast-check.ts` (extended) |
| Compile | static CSS — `cd rulestead_admin && mix compile --warnings-as-errors` stays clean |

## Sampling Rate
- Per edit: run the contrast spec.
- Phase gate: contrast spec passes 0 violations both themes; fixture renders the full system; docs match shipped tokens; existing theme-control/cascade/scope specs still green.

## Per-Requirement Verification Map

| Req | Behavior | Method | Pass condition |
|-----|----------|--------|----------------|
| DSY-02 | Token contract (invariant vs variant) documented | grep + read | CSS header comment + guide section describe the split, cascade, SYNCED-PAIR rule, add-a-token recipe |
| DSY-02 | Contrast reference fixture renders every token pair + tone + state | screenshot | fixture shows full system both themes |
| DSY-02 | Automated contrast gate fails on any sub-AA pair | spec | `design-system.spec.ts` enumerates pairs, asserts AA, 0 violations both themes |
| DSY-02 (fold) | No remaining un-tokenized one-off color/shadow in component rules | grep | literal-scan stays 0 (from Phase 88) |
| — | New tokens (if any) added to light + synced dark pair | python synced-pair | IDENTICAL |
| — | Gate would catch a regression | spot-check | (optional) perturb one token → spec FAILS → revert |
| — | Existing specs green; compile clean | Playwright + compile | theme-control 11 + cascade 5 + scope 3 green; exit 0 |

## Wave 0 Gaps
- [ ] Canonical design-system fixture (extend `theme-harness.html` to completeness OR new `design-system.html`).
- [ ] `design-system.spec.ts` — enumerated AA assertions over all text/surface + base-on-soft pairs, both themes.
- [ ] Extended `contrast-check.ts` with the full pair set.
- [ ] Token-contract doc (CSS header comment + guide section).

## Phase-Complete Definition
The token contract is documented (CSS header + guide); one canonical fixture renders the complete token/tone/state system in both themes; an automated contrast spec asserts WCAG AA across all enumerated pairs and passes with zero violations in both themes (and would fail on a regression); any one-off values are folded into tokens with the synced pair intact; existing specs + compile stay green. This fixture+spec is the gate Phases 92-94 run.
