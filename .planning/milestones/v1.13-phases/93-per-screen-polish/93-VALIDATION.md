---
phase: 93
slug: per-screen-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 93 — Validation Strategy

> Confirmation + targeted straggler fixes. Validation = the Phase 91 design-system contrast gate (now enforcing accent-light at normal 4.5) + broadened both-theme real-screen sweep + compile.

## Test Infrastructure
| Property | Value |
|----------|-------|
| Real admin | isolated demo backend http://127.0.0.1:60485 (this branch) |
| Gate | `design-system.spec.ts` — accent-light pair at NORMAL 4.5 threshold, 0 violations both themes |
| Sweep | Playwright sign-in→screenshot, `addInitScript` preset theme; /tmp/rs-shots/screens/ |
| Compile | `cd rulestead_admin && mix compile --warnings-as-errors` |

## Per-Requirement Verification Map
| Req | Behavior | Method | Pass |
|-----|----------|--------|------|
| A11Y-01 | All text/pills/borders meet WCAG AA both themes (incl. accent badge light) | design-system gate | accent pair ≥4.5 at normal threshold; 0 violations both themes |
| SCRN-01 | Every screen renders correctly/on-brand both themes (elevation, pills, empty states) | both-theme sweep | representative + broadened sweep shows no straggler; record at /tmp/rs-shots/screens/ |
| — | Stragglers fixed token-driven (no literals) | grep | literal-scan stays 0 |
| — | synced pair intact (light-only accent change) | check_synced_pair.py | IDENTICAL |
| — | specs green; compile clean | Playwright + compile | 28/28; exit 0 |

## Phase-Complete Definition
The design-system contrast gate enforces accent-light at the normal 4.5 threshold and passes 0 violations in both themes; the broadened both-theme real-screen sweep shows every screen correct/on-brand with any straggler fixed token-driven; synced pair intact; specs + compile green.
