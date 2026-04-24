---
phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
plan: 03
subsystem: docs
tags: [exdoc, guides, api-stability, telemetry, ecto, oban]
requires:
  - phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
    provides: Phase 4 telemetry and runtime contracts reflected in the recipes
  - phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
    provides: Published host-app seams and fake-backed test helpers documented here
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    provides: Admin mount and policy surface referenced by the extending guide
provides:
  - Release-grade recipe guides for testing, telemetry, Ecto, Oban, deployment, and context propagation
  - A normative extending guide that limits the main body to shipped seams and walls off planned seams in an appendix
affects: [guides, exdoc, release-docs, adopters, extenders]
tech-stack:
  added: []
  patterns: [fake-first testing docs, explicit context propagation, strict public-vs-planned seam split]
key-files:
  created: [guides/flows/extending-rulestead.md]
  modified:
    [
      guides/recipes/testing.md,
      guides/recipes/telemetry.md,
      guides/recipes/ecto-conventions.md,
      guides/recipes/oban-background-jobs.md,
      guides/recipes/deployment.md,
      guides/recipes/context-propagation.md
    ]
key-decisions:
  - "Kept recipe examples on published-package seams and avoided path-dependency or hosted-control-plane storytelling."
  - "Restricted the extending guide main body to `Rulestead.Store`, `Rulestead.Admin.Policy`, and `RulesteadAdmin.Router`."
  - "Moved roadmap-only seam names into a clearly labeled appendix excluded from API stability."
patterns-established:
  - "Recipe docs should describe only shipped runtime and host-app seams."
  - "Extension docs must separate supported seams from roadmap names explicitly."
requirements-completed: [DOC-06]
duration: 5min
completed: 2026-04-24
---

# Phase 8 Plan 03 Summary

**Release recipes for the shipped testing, telemetry, Ecto, Oban, deployment, and context seams plus a strict v0.1.0 extending guide**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-24T12:46:00Z
- **Completed:** 2026-04-24T12:50:55Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Replaced placeholder recipe docs with release-grade guidance aligned to the actual v0.1.0 runtime and host-app seams.
- Kept the testing recipe Fake-first and reinforced explicit, bounded context propagation across Plug, LiveView, and Oban.
- Added the extending guide and isolated roadmap-only seam names in a non-public appendix.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the recipes around the shipped release seams** - `6360bae` (docs)
2. **Task 2: Write the extending guide with a strict public-vs-planned seam split** - `dd99d92` (docs)

## Files Created/Modified

- `guides/recipes/testing.md` - Fake-first published-package testing recipe using the shipped helper surface
- `guides/recipes/telemetry.md` - App-level telemetry consumption recipe aligned with the public event catalog
- `guides/recipes/ecto-conventions.md` - Ecto authoring and install conventions without request-path DB evaluation
- `guides/recipes/oban-background-jobs.md` - Explicit Oban context attach/restore recipe
- `guides/recipes/deployment.md` - Runtime-local deployment posture without hosted-control-plane claims
- `guides/recipes/context-propagation.md` - Expanded explicit propagation and bounded-payload guidance
- `guides/flows/extending-rulestead.md` - Normative v0.1.0 extension guide with a strict public-versus-planned split

## Decisions Made

- Recipe prose stays on shipped public seams and avoids speculating about future hosted or governance capabilities.
- The extending guide treats `Rulestead.Store`, `Rulestead.Admin.Policy`, and `RulesteadAdmin.Router` as the only supported seams in its main body.
- Roadmap-only names remain documented only as excluded appendix material until they become shipped, tested contracts.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix docs --warnings-as-errors` initially flagged hidden-module cross-reference warnings from prose references to runtime internals. The recipe wording was tightened to describe the keyed runtime surface without treating hidden modules as ExDoc-visible API.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The docs set now teaches the shipped seams consistently with the release surface.
- The extending guide is ready to be paired with `api_stability.md` without stabilizing roadmap-only behavior names.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-03-SUMMARY.md`
- Task commits `6360bae` and `dd99d92` exist in git history
