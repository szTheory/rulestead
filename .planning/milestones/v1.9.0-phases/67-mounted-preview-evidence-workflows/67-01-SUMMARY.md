---
phase: 67-mounted-preview-evidence-workflows
plan: 67-01
subsystem: ui
tags: [liveview, impact-preview, adm-05]

requires:
  - phase: 66-evidence-carry-through-and-governance-boundary
    provides: ImpactPreview v2 evidence fields on preview maps
provides:
  - Sample cohort and impression summary sections in impact_preview/1
  - Basis-specific uncertainty copy from core messages
affects: [67-02, 67-03, 67-04]

key-files:
  created:
    - rulestead_admin/test/rulestead_admin/components/audience_components_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/components/audience_components.ex

requirements-completed: [ADM-05]

completed: 2026-05-27
---

# Phase 67 Plan 01 Summary

**Extended `AudienceComponents.impact_preview/1` to render bounded sample cohort and impression summary evidence with core-driven uncertainty copy.**

## Accomplishments

- Added Sample cohort table (10-row cap, +N more) and Impression summary block with variant breakdown
- Replaced static uncertainty paragraph with `uncertainty_message/1` from preview map
- Extended `humanize_preview_basis/1` for Phase 65 basis strings
- Component tests cover full evidence, empty omission, truncation, and forbidden fleet/dashboard copy

## Self-Check: PASSED

- `mix test test/rulestead_admin/components/audience_components_test.exs` — 4 tests, 0 failures
- `mix compile --warnings-as-errors` — OK
