---
phase: 127-adoption-guides
plan: 03
subsystem: docs
tags: [exdoc, mix.exs, extras, hexdocs, adoption-guides]

# Dependency graph
requires:
  - phase: 127-01
    provides: guides/recipes/troubleshooting.md (symptom-indexed troubleshooting guide)
  - phase: 127-02
    provides: guides/recipes/integrations-cookbook.md (persona-grounded integration recipes)
provides:
  - Both new recipes wired into the existing ExDoc "Recipes" extras group (cookbook early, troubleshooting last)
  - Live mix docs --warnings-as-errors coverage of both new guide files under real extras wiring
affects: [adoption-guides, hexdocs-release, docs-render-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hidden internal Mix tasks (@moduledoc false) are referenced as bold plain text in guides, not code spans, to avoid ExDoc hidden-reference autolink warnings under --warnings-as-errors"

key-files:
  created: []
  modified:
    - rulestead/mix.exs
    - guides/recipes/troubleshooting.md

key-decisions:
  - "Wired both guides via the extras: list only; no groups_for_extras change (existing ~r\"guides/recipes/\" regex auto-includes them)"
  - "Render the intentionally-hidden mix rulestead.redis.sync task as bold plain text instead of a code span, rather than touching mix.exs skip-config, to clear the docs gate with the narrowest change"

patterns-established:
  - "Extras list order drives sidebar order within a regex-defined group; new recipes slot by position, not by group membership edits"

requirements-completed: [GUIDE-03]

# Metrics
duration: 9min
completed: 2026-06-18
status: complete
---

# Phase 127 Plan 03: Wire Recipes into Extras Summary

**Both new adopter recipes (integrations-cookbook early, troubleshooting last) wired into the existing ExDoc "Recipes" extras group in rulestead/mix.exs, with a green `mix docs --warnings-as-errors` gate and passing version-truth guard.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-06-18T15:28:00Z
- **Completed:** 2026-06-18T15:37:06Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Inserted `../guides/recipes/integrations-cookbook.md` as the FIRST recipe in the extras block (before `testing.md`).
- Inserted `../guides/recipes/troubleshooting.md` as the LAST recipe in the extras block (after `migrating-from-funwithflags.md`, before `api_stability.md`).
- No new `groups_for_extras` entry; the existing `"Recipes": ~r"guides/recipes/"` regex auto-includes both files.
- `getting-started.md` golden path left byte-identical.
- `mix docs --warnings-as-errors` exits 0 with zero warnings under live extras wiring exercising both new files.
- `python3 scripts/check_version_truth.py` exits 0 (36 files clean).

## Task Commits

Each task was committed atomically:

1. **Task 1: Insert the two new recipes into the extras list** - `07ca9ca` (docs)
2. **Task 2: Verify sidebar order and the green docs gate** - `94f440a` (fix — see Deviations)

_Plan metadata commit (SUMMARY) follows separately._

## Files Created/Modified
- `rulestead/mix.exs` - Two-line insertion into the `extras:` recipes block: cookbook early, troubleshooting last. No group or other-entry changes.
- `guides/recipes/troubleshooting.md` - One-line prose fix: render the hidden internal `mix rulestead.redis.sync` task as bold plain text rather than an autolinking code span (deviation fix, see below).

## Decisions Made
- Wired purely via `extras:` ordering; no `groups_for_extras` edit (regex membership already covers both files).
- Chose to fix the docs-gate failure in the guide prose (the actual source of the bad reference) rather than broadening mix.exs ExDoc skip-config, keeping mix.exs limited to the plan's intended two-line wiring.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Hidden Mix-task code span tripped the docs gate**
- **Found during:** Task 2 (Verify sidebar order and the green docs gate)
- **Issue:** Wiring `troubleshooting.md` into the live `extras:` list is what first exercises it under `mix docs --warnings-as-errors`. The guide contained the inline code span `` `mix rulestead.redis.sync` ``, which ExDoc autolinked to `Mix.Tasks.Rulestead.Redis.Sync` — a task carrying `@moduledoc false` (intentionally hidden, not in the locked 1.x public surface). ExDoc emitted a "references module ... but it is hidden" warning, which `--warnings-as-errors` escalated to a build failure (exit 1). This warning class is not silenced by the existing `skip_undefined_reference_warnings_on` (undefined-only) or `skip_code_autolink_to` hooks for this reference form.
- **Fix:** Rendered the intentionally-internal task name as bold plain text (`**mix rulestead.redis.sync**`) instead of a code span, so ExDoc no longer resolves it as a module/task reference. The task name remains readable and the footguns cross-link is unaffected. No mix.exs ExDoc skip-config change was needed (experimental skip-config edits were reverted; mix.exs carries only the intended two-line extras wiring).
- **Files modified:** guides/recipes/troubleshooting.md
- **Verification:** `mix docs --warnings-as-errors` now exits 0 with zero warnings; rendered HTML shows `<strong>mix rulestead.redis.sync</strong>` with no autolink and no backslash artifact.
- **Committed in:** 94f440a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The fix was required to satisfy the plan's own green-bar gate. It is narrow (one line of guide prose), introduces no new dependency or group, and keeps mix.exs scoped to the intended extras wiring. No scope creep.

## Issues Encountered
- Initial attempts to suppress the hidden-reference warning via ExDoc config were ineffective: `skip_undefined_reference_warnings_on` does not cover hidden-reference warnings, and `skip_code_autolink_to` (even with the `Mix.Tasks.Rulestead.` module-form prefix) did not suppress the escalated warning for this reference. Resolved by fixing the reference at its source in the guide prose and reverting all config experiments.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GUIDE-03 complete: both adopter recipes are live in the HexDocs sidebar under the Recipes group in the specified order.
- Docs render gate (`mix docs --warnings-as-errors`) and version-truth guard are both green for the full phase-127 guide set.
- Phase 127 (adoption-guides) authoring + wiring work is fully landed across plans 01/02/03.

## Self-Check: PASSED

- FOUND: `.planning/phases/127-adoption-guides/127-03-SUMMARY.md`
- FOUND commit: `07ca9ca` (mix.exs extras wiring)
- FOUND commit: `94f440a` (troubleshooting.md docs-gate fix)

---
*Phase: 127-adoption-guides*
*Completed: 2026-06-18*
