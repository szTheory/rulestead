---
phase: 38-lifecycle-docs-runbooks-verification
plan: 01
subsystem: docs
tags: [docs, lifecycle, readme, onboarding, release-surface]
requires: []
provides:
  - canonical shared lifecycle guide from birth to retirement
  - onboarding and package-guide routing into the shared lifecycle spine
  - root and sibling-package README lifecycle discoverability without standalone admin drift
affects: [LIF-05, docs-surface, sibling-package-entrypoints]
tech-stack:
  added: []
  patterns: [one lifecycle story many entrypoints, host-owned ownership posture, advisory archive-readiness wording]
key-files:
  created:
    - guides/flows/flag-lifecycle.md
  modified:
    - guides/introduction/getting-started.md
    - rulestead/guides/README.md
    - README.md
    - rulestead/README.md
    - rulestead_admin/README.md
key-decisions:
  - "Placed the lifecycle narrative in shared root guides so the runtime and mounted companion can point to one canonical story."
  - "Kept the lifecycle order opinionated: authored intent, queue review, archive preview/confirm/audit, then support and cleanup follow-through."
  - "Preserved host-owned owner truth and advisory archive-readiness language in every entrypoint instead of duplicating a second lifecycle taxonomy."
requirements-completed: [LIF-05]
duration: 18min
completed: 2026-05-23
---

# Phase 38 Plan 01: Lifecycle Spine Guide Summary

**Shared lifecycle spine plus front-door routing into one canonical birth to retirement story**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-23T21:08:00Z
- **Completed:** 2026-05-23T21:26:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `guides/flows/flag-lifecycle.md` as the canonical lifecycle narrative across authoring, review, advisory readiness, archive flow, and host cleanup.
- Routed onboarding and package-guide readers from `guides/introduction/getting-started.md` and `rulestead/guides/README.md` into the shared lifecycle spine.
- Tightened the root, runtime-package, and mounted-companion READMEs so lifecycle discoverability is obvious without duplicating the whole workflow or implying standalone admin posture.

## Task Commits

- `docs(38-01): add lifecycle spine guide`
- `docs(38-01): route entrypoints to lifecycle guide`

## Files Created/Modified

- [guides/flows/flag-lifecycle.md](/Users/jon/projects/rulestead/guides/flows/flag-lifecycle.md:1) - canonical lifecycle guide covering authored intent, review, advisory readiness, archive flow, and support/SRE handoff
- [guides/introduction/getting-started.md](/Users/jon/projects/rulestead/guides/introduction/getting-started.md:69) - onboarding handoff into the lifecycle spine
- [rulestead/guides/README.md](/Users/jon/projects/rulestead/rulestead/guides/README.md:1) - package guide index pointer to the shared lifecycle story
- [README.md](/Users/jon/projects/rulestead/README.md:74) - root front-door lifecycle routing
- [rulestead/README.md](/Users/jon/projects/rulestead/rulestead/README.md:1) - runtime package lifecycle discoverability with host-owned owner truth
- [rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:1) - mounted companion lifecycle routing without standalone control-plane drift

## Verification

- `test -f /Users/jon/projects/rulestead/guides/flows/flag-lifecycle.md`
- `rg -n "birth to retirement|host owns identity|archive_candidate.*not permission|preview.*confirm.*audit|mix rulestead\.lifecycle" /Users/jon/projects/rulestead/guides/flows/flag-lifecycle.md`
- `rg -n "flag-lifecycle|birth to retirement|lifecycle guide" /Users/jon/projects/rulestead/guides/introduction/getting-started.md /Users/jon/projects/rulestead/rulestead/guides/README.md`
- `rg -n "flag-lifecycle|birth to retirement" /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md`
- `rg -n "mounted companion|mounted admin companion|not a standalone" /Users/jon/projects/rulestead/rulestead_admin/README.md`
- `rg -n "host-owned|host owns|owner truth" /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/rulestead/README.md`

## Decisions Made

- The lifecycle guide lives at the monorepo root because the operator story spans runtime docs, mounted admin, and CLI/reporting surfaces.
- The guide teaches archive readiness as evidence, not permission, and keeps host-owned owner truth explicit.
- The sibling-package READMEs route into the shared guide instead of trying to retell the lifecycle story locally.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `README.md` and `guides/introduction/getting-started.md` already had local edits before this run. The lifecycle updates were layered on top of those current contents without normalizing unrelated changes.

## User Setup Required

None.

## Next Phase Readiness

- The canonical lifecycle vocabulary now exists in one shared guide.
- Plan `38-02` can align admin, explainability, evaluation, testing, API-stability, and maintainer docs to this shared lifecycle spine.

---
*Phase: 38-lifecycle-docs-runbooks-verification*
*Completed: 2026-05-23*
