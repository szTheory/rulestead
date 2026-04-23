---
phase: 02-data-model-error-model-ecto-store-fake-adapter
plan: 01
subsystem: database
tags: [ecto, ecto_sql, postgrex, postgres, testing, sandbox]
requires:
  - phase: 01-repo-bootstrap
    provides: sibling-package monorepo boundaries and package-level mix/test conventions
provides:
  - Internal `Rulestead.Repo` configured for Phase 2 persistence work
  - Shared SQL sandbox bootstrap in manual mode for Phase 2 tests
  - Reusable `Rulestead.RepoCase` for later Ecto-backed tests
affects: [phase-02-plans, store, schemas, installer, testing]
tech-stack:
  added: [ecto_sql, postgrex]
  patterns: [internal repo module, explicit test support compile paths, shared sandbox case template]
key-files:
  created:
    - rulestead/config/config.exs
    - rulestead/config/test.exs
    - rulestead/lib/rulestead/repo.ex
    - rulestead/test/support/repo_case.ex
  modified:
    - rulestead/mix.exs
    - rulestead/test/test_helper.exs
key-decisions:
  - "Kept the repo internal and package-scoped without adding application child wiring or other Phase 5 host-app seams."
  - "Enabled `test/support` only in the test compile path so shared repo helpers stay reusable without widening the runtime surface."
  - "Defaulted test repo credentials to `PGUSER` or the local shell user before falling back to `postgres` to reduce machine-specific bootstrap failures."
patterns-established:
  - "Phase 2 Ecto-backed tests start `Rulestead.Repo` in `test_helper.exs` and lock the SQL sandbox to `:manual`."
  - "DB-backed tests should `use Rulestead.RepoCase` instead of inlining sandbox checkout logic."
requirements-completed: [STORE-01]
duration: 15min
completed: 2026-04-23
---

# Phase 2 Plan 1: Repo and Sandbox Foundation Summary

**Internal Ecto repo wiring with manual SQL sandbox bootstrap for later Phase 2 store and schema work**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-23T18:40:00Z
- **Completed:** 2026-04-23T18:55:01Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added the minimal Ecto dependency and config foundation inside `rulestead/` only.
- Created `Rulestead.Repo` as the internal package repo for later Phase 2 persistence work.
- Established one shared ExUnit SQL sandbox pattern with `mode: :manual` and a reusable `Rulestead.RepoCase`.

## Task Commits

1. **Task 1: Add the minimal Ecto repo and dependency foundation inside `rulestead/`** - `b9a10a8` (`feat`)
2. **Task 2: Establish shared sandbox bootstrap and reusable repo case** - `dc102c3` (`feat`)

## Files Created/Modified
- `rulestead/mix.exs` - added `ecto_sql` and `postgrex`, kept `jason` explicit, and compiled `test/support` in test only.
- `rulestead/config/config.exs` - established package-scoped Ecto repo and JSON config without host-app seams.
- `rulestead/config/test.exs` - defined test-only repo settings and SQL sandbox pool defaults.
- `rulestead/lib/rulestead/repo.ex` - added the internal `Ecto.Repo` module.
- `rulestead/test/test_helper.exs` - starts the repo and locks sandbox mode to `:manual`.
- `rulestead/test/support/repo_case.ex` - centralizes checkout and shared mode setup for DB-backed tests.

## Decisions Made

- Kept the plan narrow to package-local repo wiring and test harness setup only.
- Started the repo from `test/test_helper.exs` rather than introducing an application supervisor or runtime child wiring before Phase 5.
- Used a standard `ExUnit.CaseTemplate`-based `RepoCase` so later plans inherit one DB setup pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Guarded environment-specific config imports**
- **Found during:** Task 1 verification
- **Issue:** `config/config.exs` initially assumed `dev.exs` and `prod.exs` existed, which broke `mix deps.get` and formatting in this package.
- **Fix:** Made env config import conditional so the new package config stays compile-safe with only `test.exs` present.
- **Files modified:** `rulestead/config/config.exs`
- **Verification:** `mix deps.get`, `mix format`, and `mix compile --warnings-as-errors` all completed successfully.
- **Committed in:** `b9a10a8`

**2. [Rule 3 - Blocking] Relaxed brittle default test DB credentials**
- **Found during:** Task 2 verification
- **Issue:** The initial hardcoded `postgres` username emitted local connection failures on machines where that role does not exist.
- **Fix:** Defaulted test credentials to `PGUSER` or the local shell user before falling back to `postgres`, while keeping explicit override env vars available.
- **Files modified:** `rulestead/config/test.exs`
- **Verification:** `mix test test/rulestead_test.exs` completed cleanly without repo connection errors in the current environment.
- **Committed in:** `b9a10a8`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required to keep the new repo/test foundation portable and verification-safe. No scope creep beyond the planned files.

## Issues Encountered

- Local verification depended on machine-specific Postgres defaults; resolving that in test config was enough to keep the Phase 2 harness narrow and stable.

## User Setup Required

None for this plan's current verification surface.

DB-backed Phase 2 tests added later will still require a reachable Postgres instance and a test database configured through `PG*` or `RULESTEAD_DB_*` environment variables as needed.

## Next Phase Readiness

- Later Phase 2 plans can add schemas, migrations, and adapter code against one shared internal repo.
- DB-backed tests can now reuse `Rulestead.RepoCase` instead of inventing per-test sandbox setup.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-01-SUMMARY.md`
- Commit `b9a10a8` exists in git history
- Commit `dc102c3` exists in git history

---
*Phase: 02-data-model-error-model-ecto-store-fake-adapter*
*Completed: 2026-04-23*
