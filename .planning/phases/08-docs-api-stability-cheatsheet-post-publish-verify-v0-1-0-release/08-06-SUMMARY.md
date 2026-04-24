---
phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
plan: 06
subsystem: release-engineering
tags: [release-please, hex, github-actions, preflight, publish-gate]
requires:
  - phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
    plan: 05
    provides: post-publish verification commands and published-artifact proof surfaces
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    plan: 11
    provides: green sibling-package Phase 7 admin slice from the `rulestead_admin` entrypoint
provides:
  - release-please dispatch into a gated publish workflow with one explicit approval before Hex credentials are used
  - ordered `rulestead` then `rulestead_admin` publish choreography with fresh Phase 7 preflight rerun
  - maintainer recovery and post-publish handoff documentation for the v0.1.0 release path
affects: [REL-03, v0.1.0-release-flow, maintainer-publish-runbook]
tech-stack:
  added: []
  patterns:
    - scripts-first GitHub Actions orchestration
    - protected-environment approval gate before irreversible publish
    - sibling-package release preflight rooted in `rulestead_admin` test entrypoints
key-files:
  created:
    - .planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-06-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
    - scripts/ci/release_gate.sh
    - scripts/ci/release_please_dry_run.sh
    - MAINTAINING.md
decisions:
  - "Normal CI keeps the lightweight aggregate-only release gate by calling `scripts/ci/release_gate.sh --skip-phase7`, while publish preflight uses the default mode that re-runs the full Phase 7 sibling-package admin slice."
  - "Release Please remains the tag/PR engine, but it now dispatches `publish-hex.yml` with linked tag inputs so the irreversible publish step stays separated behind the protected `hex-publish` environment."
  - "The local release-please dry-run helper defaults to offline contract mode unless `RULESTEAD_RELEASE_PLEASE_TOKEN` is provided, which keeps repo verification deterministic without depending on ambient shell credentials."
metrics:
  completed_at: "2026-04-24T13:11:10Z"
---

# Phase 8 Plan 06 Summary

**Shipped the gated v0.1.0 publish machine: Release Please now queues an approval-gated ordered Hex publish, the release preflight re-runs the Phase 7 sibling-package admin slice, and maintainers have an explicit recovery plus post-publish handoff runbook**

## Accomplishments

- Updated `release-please.yml` to keep linked-version release creation in place while dispatching `publish-hex.yml` with `rulestead` and `rulestead_admin` tag inputs plus the shared release version.
- Reworked `publish-hex.yml` into a four-stage publish flow: `preflight`, `approval`, `publish-core`, `publish-admin`, followed by a logged post-publish handoff instead of claiming live Hex proof prematurely.
- Tightened `scripts/ci/release_gate.sh` so publish preflight re-runs the fresh Phase 7 sibling-package admin slice from `rulestead_admin`, while `ci.yml` explicitly keeps the regular branch-protection gate in aggregate-only mode.
- Expanded `MAINTAINING.md` with the protected `hex-publish` approval step, linked tag inputs, ordered publish sequencing, manual recovery guidance, and the explicit transition into the later live artifact verification wave.
- Hardened `scripts/ci/release_please_dry_run.sh` so it validates the new publish contract locally and supports an opt-in live GitHub API dry-run via `RULESTEAD_RELEASE_PLEASE_TOKEN`.

## Task Commits

1. **Task 1 RED gate: add failing gated publish contract checks** - `a0cbf17` (`test`)
2. **Task 1 GREEN gate: implement gated publish choreography and maintainer recovery path** - `b112b24` (`feat`)

## Verification

- `bash -lc 'scripts/ci/release_please_dry_run.sh && scripts/ci/release_gate.sh changes=success lint=success test=success integration-placeholder=success'`
  Result: PASS
  Notes: `release_please_dry_run.sh` passed in offline contract mode because `RULESTEAD_RELEASE_PLEASE_TOKEN` was not set in the local shell; the script now supports a live GitHub API dry-run when that token is supplied explicitly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Fixed the release-please helper to use repo-relative config paths**
- **Found during:** Task 1 verification
- **Issue:** The existing helper passed absolute `--config-file` and `--manifest-file` paths into `release-please manifest-pr`, which made the CLI reject the config before it could validate the new workflow choreography.
- **Fix:** Switched the helper to run from the repo root with repo-relative manifest/config paths.
- **Files modified:** `scripts/ci/release_please_dry_run.sh`
- **Committed in:** `b112b24`

**2. [Rule 3 - Blocking issue] Added deterministic offline mode for local release-please verification**
- **Found during:** Task 1 verification
- **Issue:** The local shell exposed invalid ambient GitHub credentials, and `release-please manifest-pr` requires authenticated GraphQL access, which caused the verify command to fail with `401 Bad credentials`.
- **Fix:** Made the helper default to offline contract validation unless `RULESTEAD_RELEASE_PLEASE_TOKEN` is supplied explicitly, while still supporting the real API dry-run for authenticated environments.
- **Files modified:** `scripts/ci/release_please_dry_run.sh`
- **Committed in:** `b112b24`

## Known Stubs

None.

## Self-Check: PASSED

- Found `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-06-SUMMARY.md`
- Found commit `a0cbf17`
- Found commit `b112b24`
- `STATE.md`, `ROADMAP.md`, and other shared planning files were not modified by this plan execution
