---
phase: 07
plan: 03
subsystem: rulestead_admin
tags:
  - admin-ui
  - simulation
  - redaction
  - accessibility
requires:
  - 07-01
  - 07-02
provides:
  - ADMIN-04
  - ADMIN-09
  - SEC-03
key_files:
  created:
    - rulestead_admin/lib/rulestead_admin/components/simulate_components.ex
    - rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs
    - rulestead_admin/test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex
decisions:
  - Use the dedicated `/simulate` route as a one-context workflow that calls `Rulestead.simulate_flag/4` directly.
  - Keep raw trait values out of visible metadata by rendering redacted context output separately from the canonical fixture export.
  - Keep archetypes page-scoped and in LiveView state rather than persisting simulation history or profiles.
---

# Phase 07 Plan 03 Summary

Dedicated simulation/explain workflow for one flag and one environment with summary-first results, page-scoped archetypes, collapsed trace detail, and canonical `%Rulestead.Context{}` fixture export.

## Completed Work

- Replaced the placeholder simulation LiveView with a real operator workflow that accepts one targeting key plus traits, runs `Rulestead.simulate_flag/4`, and renders matched rule, returned value, variant, reason, bucket result, snapshot version, and cache age before trace detail.
- Added shared simulation components for archetype chips, fixture export presentation, and disclosure-based trace rendering.
- Added LiveView behavior coverage for simulation submit, summary-first rendering, page-scoped archetype apply/reset, and ExUnit fixture export.
- Added route-specific accessibility and redaction proof for the populated simulation screen.

## Verification

- `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_test.exs test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs`

## Commits

- `8bb04aa` `test(07-03): add failing simulation screen coverage`
- `b77449a` `feat(07-03): implement simulation liveview workflow`
- `adcb9f9` `test(07-03): add simulation accessibility proof`

## Deviations from Plan

### Auto-fixed Issues

- None.

### Execution Notes

- Task 2 landed as a test-only commit because the Task 1 implementation already satisfied the accessibility and redaction expectations once the route-specific proof was added.

## Known Stubs

- None.

## Threat Flags

- None.

## Self-Check

PASSED
