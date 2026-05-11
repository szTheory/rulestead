---
phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
plan: 01
subsystem: docs
tags: [hexdocs, readme, onboarding, conventions, release-docs]
requires:
  - phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
    provides: installer flow, runtime host seams, and mounted admin router contract
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    provides: admin host contract and environment URL posture
provides:
  - release-ready root and package README set for the v0.1.0 audience split
  - shipped introduction guides for installation, getting started, and upgrading
  - top-level conventions doc for determinism, precedence, tenancy, testing, and redaction
affects: [api-stability-docs, cheatsheet, release-verification, public-onboarding]
tech-stack:
  added: []
  patterns: [alex-first docs front door, sibling-package doc split, explicit public-contract language]
key-files:
  created: [CONVENTIONS.md, .planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-01-SUMMARY.md]
  modified: [README.md, rulestead/README.md, rulestead_admin/README.md, guides/introduction/installation.md, guides/introduction/getting-started.md, guides/introduction/upgrading.md]
key-decisions:
  - "The root README now routes readers immediately into build, operate, and extend paths instead of carrying pre-release framing."
  - "The core package README stays runtime-first while the admin package README promises only the mount seam, policy behavior, session inputs, and ?env= contract."
  - "The release introduction guides and CONVENTIONS.md only describe shipped v0.1.0 behavior and existing enforcement."
patterns-established:
  - "Public docs should describe package boundaries, not internal admin implementation details."
  - "Phase 8 docs should anchor compatibility language to documented contracts and shipped guides only."
requirements-completed: [DOC-04]
duration: 15min
completed: 2026-04-24
---

# Phase 8 Plan 01: Docs Front Door Summary

**Release-ready READMEs, onboarding guides, and conventions that make the v0.1.0 sibling-package contract explicit**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-24T12:34:00Z
- **Completed:** 2026-04-24T12:48:58Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Replaced the root README's pre-release framing with an Alex-first v0.1.0 front door and role-based path split.
- Tightened the package-local README boundary so `rulestead` stays runtime-first and `rulestead_admin` stays limited to the host seam contract.
- Replaced placeholder introduction pages and added `CONVENTIONS.md` to codify determinism, precedence, explicit scope, fake-first testing, and redaction expectations.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the root and package READMEs for the real v0.1.0 audience split** - `3498593` (`docs`)
2. **Task 2: Author release-ready introduction docs and the discipline layer** - `4eacfd8` (`docs`)

## Files Created/Modified

- `README.md` - new public front door with quickstart and build/operate/extend routing
- `rulestead/README.md` - runtime-first package README with minimal install and API surface links
- `rulestead_admin/README.md` - narrow host contract for mount seam, `policy:`, session inputs, and `?env=`
- `guides/introduction/installation.md` - explains when to install only `rulestead` versus both sibling packages
- `guides/introduction/getting-started.md` - mirrors the supported first-success install, gate, and optional mount path
- `guides/introduction/upgrading.md` - defines the pre-1.0 compatibility posture without over-promising future docs
- `CONVENTIONS.md` - codifies determinism, first-match precedence, explicit tenancy/environment scope, fake-first testing, and no-PII defaults

## Decisions Made

- Root onboarding now assumes the first reader is trying to ship application code quickly, then routes into operator and contributor paths instead of explaining project history.
- `rulestead_admin/README.md` deliberately excludes route inventories, internal module references, and UI implementation details so the public contract stays narrow.
- `guides/introduction/upgrading.md` references the future `guides/api_stability.md` only as a later Phase 8 source of truth, avoiding a broken link before that file exists.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first `mix docs --warnings-as-errors` run emitted ExDoc warnings from unchanged guides referencing hidden `Rulestead.Runtime` internals. A clean rerun passed without further scoped edits, so no out-of-scope file changes were made in this plan.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The release docs front door is now aligned with the shipped sibling-package install and admin mount story.
- Follow-on Phase 8 docs can cite `CONVENTIONS.md` and the narrowed admin contract without inheriting Phase 1 pre-release language.

## Self-Check: PASSED

- Found `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-01-SUMMARY.md`
- Found commit `3498593`
- Found commit `4eacfd8`
