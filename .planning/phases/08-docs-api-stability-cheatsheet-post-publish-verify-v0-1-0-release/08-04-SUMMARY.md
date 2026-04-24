---
phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
plan: 04
subsystem: docs
tags: [api-stability, exdoc, contract-tests, changelog, rulestead_admin]
requires:
  - phase: 03-context-rules-deterministic-bucketing-pure-evaluator
    provides: root facade, context/result contracts, and evaluation semantics
  - phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
    provides: telemetry catalog and runtime-facing diagnostics surface
  - phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
    provides: host config schema and mounted admin router seam
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    provides: shipped mounted admin routes and host-facing env conventions
provides:
  - authoritative `guides/api_stability.md` contract for the locked v0.1.0 public boundary
  - reflection-backed release contract tests for the core package
  - narrowed admin mount proof focused on the router seam and host-facing URL/session conventions
  - final Phase 8 ExDoc extras wiring in the core package plus narrow package-local admin docs config
affects: [REL-06, hexdocs, public-api, admin-boundary, release-docs]
tech-stack:
  added: []
  patterns: [closed public catalogs, reflection-based contract locks, mount-seam-only admin proof]
key-files:
  created:
    - guides/api_stability.md
    - rulestead/test/rulestead/release_contract_test.exs
    - .planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-04-SUMMARY.md
  modified:
    - rulestead/mix.exs
    - rulestead_admin/mix.exs
    - rulestead/CHANGELOG.md
    - rulestead_admin/CHANGELOG.md
    - rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs
key-decisions:
  - "The release contract documents the full exported v0.1.0 root facade that actually ships, including default-arity helpers, instead of the smaller aspirational subset from planning notes."
  - "The admin package contract remains limited to the router macro, required `policy:` behavior, session keys, and `?env=` plus mounted route-family conventions."
  - "The core package owns the shared Phase 8 docs set in ExDoc, while `rulestead_admin` keeps a narrow package-local docs surface."
requirements-completed: [REL-06]
duration: 24min
completed: 2026-04-24
---

# Phase 8 Plan 04 Summary

**Locked the v0.1.0 public boundary into one explicit guide, exposed it in HexDocs, and backed it with contract tests for both sibling packages**

## Performance

- **Duration:** 24 min
- **Completed:** 2026-04-24
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Authored `guides/api_stability.md` as the release contract for the root facade, public structs, error atoms, telemetry catalog, host config schema, and the intentionally narrow `rulestead_admin` seam.
- Pointed both package changelogs at the shared contract and added the final Phase 8 docs set to the existing `rulestead` ExDoc pipeline.
- Added `rulestead/test/rulestead/release_contract_test.exs` to lock the documented exports, struct fields, telemetry metadata catalog, config schema keys, and contract-doc presence.
- Reworked the admin integration proof so it validates mount behavior, remembered-env redirect, and stable mounted route/query conventions without treating internal LiveView modules as public API.

## Task Commits

1. **Task 1: Write `api_stability.md` with an explicit public/private boundary** - `d145103` (`docs`)
2. **Task 2: Add public-surface lock tests and final docs wiring** - `bc5ba90` (`test`)

## Files Created/Modified

- `guides/api_stability.md` - authoritative v0.1.0 public/private boundary with closed catalogs and non-public exclusions
- `rulestead/CHANGELOG.md` - points package readers at the contract guide
- `rulestead_admin/CHANGELOG.md` - points package readers at the contract guide
- `rulestead/mix.exs` - exposes `CONVENTIONS.md`, cheatsheet, API stability guide, and extending guide in the existing core ExDoc nav
- `rulestead_admin/mix.exs` - keeps the admin docs pipeline package-local and narrow
- `rulestead/test/rulestead/release_contract_test.exs` - reflection-backed lock suite for exports, structs, telemetry metadata, config schema keys, and contract docs
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` - mount contract proof limited to redirect/session/env/route conventions

## Verification

- `cd rulestead && mix docs --warnings-as-errors`
- `bash -lc 'cd rulestead && mix test test/rulestead/release_contract_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs'`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract drift] Expanded the written API catalog to match the exported v0.1.0 surface**
- **Found during:** Task 2 verification
- **Issue:** Reflection exposed additional shipped default-arity helpers on `Rulestead`, `Rulestead.Telemetry`, and `Rulestead.Config`, plus the standard `:__exception__` field on `%Rulestead.Error{}`, that were missing from the first draft of `guides/api_stability.md`.
- **Fix:** Updated `guides/api_stability.md` to enumerate the real shipped surface and explicitly mark `Rulestead.Telemetry.dispatch/4` as visible-but-non-public.
- **Files modified:** `guides/api_stability.md`
- **Committed in:** `bc5ba90`

**2. [Rule 3 - Blocking] Restored explicit admin policy setup for the mount integration proof**
- **Found during:** Task 2 verification
- **Issue:** The current workspace authorization contract required `:admin_policy` to be configured before the integration fixture could create flags and mount the admin routes.
- **Fix:** Added scoped `Application.put_env(:rulestead, :admin_policy, RulesteadAdmin.TestPolicy)` setup with cleanup in `admin_mount_test.exs`.
- **Files modified:** `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
- **Committed in:** `bc5ba90`

## Known Stubs

None.

## Self-Check: PASSED

- Found `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-04-SUMMARY.md`
- Found commit `d145103`
- Found commit `bc5ba90`
- No shared planning files were modified by this plan execution
