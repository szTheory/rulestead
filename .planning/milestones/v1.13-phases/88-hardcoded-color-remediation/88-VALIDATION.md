---
phase: 88
slug: hardcoded-color-remediation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 88 — Validation Strategy

> Pure-CSS token-redirect phase (no Elixir/JS/route changes). Validation = grep assertions (no literals remain) + both-theme screenshot review via the Phase 87 static harness + Playwright.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Playwright (`examples/demo/frontend`) + static theme harness (`file://`, no demo DB) |
| Quick run | grep literal-scan + harness screenshot both themes |
| Full run | `cd examples/demo/frontend && npx playwright test theme-*.spec.ts` |
| Contrast tool | `tests/support/contrast-check.ts` (from Phase 87) |

## Sampling Rate
- Per edit batch: grep the file for residual literals; visual-inspect affected component in harness (both themes).
- Phase gate: zero residual literals outside token blocks + both-theme screenshots show shadows reading on dark, amber warning-flash border, correct cmdk scrim/veil.

## Per-Requirement Verification Map

| Req | Behavior | Method | Pass condition |
|-----|----------|--------|----------------|
| DSY-01 | No hardcoded `rgba(26,35,50…)` shadow keys in component rules | grep | 0 matches outside token blocks |
| DSY-01 | No hardcoded `rgba(37,99,235…)` focus tints in component rules | grep | 0 matches outside token blocks |
| DSY-01 | No `rgba(255,255,255…)` veil literals in component rules | grep | 0 matches outside token blocks |
| DSY-01 | Veils/scrim consume `--rs-overlay-veil`/`--rs-scrim` | grep + visual | tokens referenced; render correct on dark |
| DSY-01 | Shadows read on dark surfaces (elevation visible) | screenshot | cards/panels show elevation in dark harness |
| DSY-01 (carry) | Warning flash border is amber (`--rs-warning`), not blue | screenshot both themes | amber border in both themes |
| — | Light mode visually unchanged (token values == old literals) | screenshot diff | no visible light-mode regression |
| — | No component logic/markup changed; mix compile clean | grep + `mix compile --warnings-as-errors` | exit 0 |

## Wave 0 Gaps
- [ ] Extend the theme harness with a flash/callout block (warning variant) if not already present, so the amber-border fix is screenshot-verifiable.
- [ ] Literal-scan command codified (grep over component-rule region, excluding the token declaration blocks).

## Phase-Complete Definition
Zero hardcoded color literals remain in component rules (grep-proven), both-theme screenshots confirm dark elevation reads + amber warning border + correct scrim/veil, light mode shows no regression, and `mix compile --warnings-as-errors` is clean.
