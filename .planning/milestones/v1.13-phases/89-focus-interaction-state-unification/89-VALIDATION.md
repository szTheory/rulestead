---
phase: 89
slug: focus-interaction-state-unification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 89 — Validation Strategy

> CSS interaction-state phase. Validation = keyboard-focus screenshots on multiple surface types in both themes + axe-core focus/contrast checks + grep assertions (one ring rule, no bare `outline:none`, no bare `:focus` on interactive elements).

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Playwright (`examples/demo/frontend`) + extended static theme harness (`file://`) |
| Quick run | tab through harness, screenshot focus on card/page-bg/colored-button, both themes |
| Full run | `cd examples/demo/frontend && npx playwright test theme-*.spec.ts focus-*.spec.ts` |
| A11y | axe-core focus-indicator + contrast (or `tests/support/contrast-check.ts` ratios over computed colors) |

## Sampling Rate
- Per edit: grep the focus idioms; visual focus screenshot in harness (both themes).
- Phase gate: one canonical `:focus-visible` rule covers all interactive elements; focus ring visible (≥3:1) on light card, dark surface, AND colored fill; hover perceivable both themes; disabled legible both themes.

## Per-Requirement Verification Map

| Req | Behavior | Method | Pass condition |
|-----|----------|--------|----------------|
| A11Y-02 | One unified two-stop `:focus-visible` ring on every interactive element | grep + screenshot | single `:where(...):focus-visible` rule; ring visible on all 3 surface types both themes |
| A11Y-02 | Ring meets WCAG 2.4.11/2.4.13 (≥3:1, ≥2px) on light/dark/colored fills | axe + contrast calc | outer-ring vs adjacent ≥3:1 both themes; surface-gap separates ring from control |
| A11Y-02 | No `outline: …pale…` bug; no bare `outline:none` without box-shadow replacement | grep | 0 bare `outline:none` outside the unified rule; old input outline gone |
| A11Y-03 | Hover perceivable + legible both themes (no white-on-light / crushed-on-dark) | screenshot | hover state shifts ≥3:1 from resting; legible |
| A11Y-03 | Disabled legible via explicit `--rs-disabled-*`, not opacity that crushes on dark | screenshot + grep | disabled uses `--rs-disabled-bg`/`-text`; legible in dark |
| — | `:focus` → `:focus-visible` on keyboard-interactive elements | grep | no bare `:focus {` on interactive elements (allow `:focus-within` where intended) |
| — | Synced dark pair still identical after `--rs-focus-ring` upgrade | python synced-pair check | IDENTICAL |
| — | mix compile clean; existing theme specs still 8/8 | compile + Playwright | exit 0; 8/8 |

## Wave 0 Gaps
- [ ] Extend `theme-harness.html` with: text input, select, a `[role="tab"]` strip, and primary/secondary/danger buttons (focus targets on varied surfaces).
- [ ] `focus-states.spec.ts` (optional) — Playwright focuses each element type and asserts a non-empty box-shadow on `:focus-visible`; or rely on screenshot review.

## Phase-Complete Definition
One canonical two-stop `:focus-visible` ring applies to all interactive elements and is visibly ≥3:1 on light card, dark surface, and colored button in both themes; hover and disabled states are legible in both themes; no pale/invisible focus or bare `outline:none` remains; synced pair intact; compile + theme specs green.
