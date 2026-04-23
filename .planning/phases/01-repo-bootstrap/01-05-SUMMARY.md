---
phase: 01-repo-bootstrap
plan: 05
subsystem: infra
tags: [github-actions, ci, release-please, hex, dependabot, actionlint]
requires:
  - phase: 01-01
    provides: sibling-package package metadata and repo skeleton
  - phase: 01-02
    provides: package metadata and docs surfaces consumed by CI
  - phase: 01-03
    provides: root formatter and tooling conventions used by workflows
provides:
  - Seven locally runnable CI and release shell entrypoints under scripts/ci
  - Seven Phase 1 GitHub Actions workflows with pinned actions and stable job ids
  - Docs-only CI filtering plus a stable release_gate aggregator
  - Linked-versions release-please bootstrap guidance and guarded manual Hex publish paths
affects: [phase-06, phase-08, branch-protection, release-runbook]
tech-stack:
  added: [GitHub Actions, release-please, actionlint, reviewdog]
  patterns: [scripts-first CI, SHA-pinned actions, docs-only job filtering, guarded manual publish]
key-files:
  created:
    - scripts/ci/lint.sh
    - scripts/ci/test.sh
    - scripts/ci/release_gate.sh
    - scripts/ci/check_package_whitelist.sh
    - .github/workflows/ci.yml
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
  modified:
    - scripts/ci/release_please_dry_run.sh
    - .github/workflows/pr-title.yml
    - .github/workflows/dependency-review.yml
    - .github/workflows/dependabot-automerge.yml
    - .github/workflows/actionlint.yml
key-decisions:
  - "Kept workflow logic thin by routing every non-trivial CI and publish check through scripts/ci entrypoints."
  - "Used job-scoped docs-only filtering instead of workflow-level paths-ignore so required checks never stick in Pending."
  - "Kept release_gate as the single stable aggregate check and normalized intentional docs-only skips before gate evaluation."
  - "Made release-please dry-run derive repo URL from RULESTEAD_RELEASE_PLEASE_REPO_URL or origin rather than a hardcoded guess."
patterns-established:
  - "Workflow files carry job-id contract comments and SHA-pinned action refs with trailing version comments."
  - "Manual publish remains workflow_dispatch-only and reuses whitelist plus admin-stub guards instead of inline YAML logic."
  - "Advisory workflows such as actionlint can be path-filtered when they are intentionally excluded from required checks."
requirements-completed: [REL-01, REL-02, REL-05, DOC-03]
duration: 8 min
completed: 2026-04-23
---

# Phase 01 Plan 05: Release Engineering and CI Workflow Summary

**Phase 1 GitHub Actions surface with scripts-first CI entrypoints, linked-versions release-please wiring, and guarded manual Hex publish paths**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-23T17:10:00Z
- **Completed:** 2026-04-23T17:18:19Z
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments

- Added the seven `scripts/ci/*.sh` entrypoints the plan requires, including the package whitelist, admin publish guard, release gate, and release-please dry-run helper.
- Added the five core Phase 1 workflows for CI, release-please, manual publish recovery, PR-title linting, and dependency review with SHA-pinned actions and stable job ids.
- Added the remaining Dependabot auto-merge and advisory `actionlint` workflows, then verified the workflow YAML locally with `actionlint`.

## Task Commits

1. **Task 1: Create the locally runnable Phase 1 CI and publish scripts** - `ba9095b` (`feat`)
2. **Task 2: Build the core CI and release workflows wired to the shared scripts** - `188112b` (`feat`)
3. **Task 3: Add the remaining GitHub workflow guards and local CI validation** - `564a69c` (`feat`)

## Files Created/Modified

- `scripts/ci/lint.sh` - explicit Phase 1 lint lane with formatter, compile, credo, docs, Hex audit, whitelist, and Dialyzer steps
- `scripts/ci/test.sh` - two-package test entrypoint for the CI matrix
- `scripts/ci/release_gate.sh` - shared aggregator that only accepts normalized `success` predecessor states
- `scripts/ci/integration_placeholder.sh` - intentional Phase 1 integration placeholder entrypoint
- `scripts/ci/check_package_whitelist.sh` - shared Hex dry-run tarball gate for both sibling packages
- `scripts/ci/admin_publish_guard.sh` - blocks `rulestead_admin` publication while the router stub remains in place
- `scripts/ci/release_please_dry_run.sh` - local linked-versions release-please helper with bootstrap assertions and configurable repo URL
- `.github/workflows/ci.yml` - docs-only-aware CI workflow with `changes`, `lint`, `test`, `integration-placeholder`, and `release_gate`
- `.github/workflows/release-please.yml` - linked-versions release workflow with Phase 1 bootstrap reminder and lockstep fallback logic
- `.github/workflows/publish-hex.yml` - manual recovery publish workflow with whitelist and admin guard reuse
- `.github/workflows/pr-title.yml` - stable `Validate PR title` required-check workflow on `pull_request`
- `.github/workflows/dependency-review.yml` - PR-only dependency review workflow
- `.github/workflows/dependabot-automerge.yml` - patch-only Dependabot auto-merge workflow
- `.github/workflows/actionlint.yml` - advisory workflow-only `actionlint` + reviewdog lane

## Decisions Made

- Followed the Phase 1 scripts-first rule strictly: all non-trivial shell logic lives in `scripts/ci/*.sh`, not inline YAML.
- Preserved the anti-pattern guard from the plan by avoiding workflow-level `paths-ignore` on required checks and using a dedicated `changes` job instead.
- Kept the admin publish fallback manual-only and guarded it with the existing router stub rather than weakening the Phase 6-7 boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected docs-only detection so mixed PRs cannot skip CI**
- **Found during:** Task 2
- **Issue:** A naive `paths-filter` output would have treated any PR containing docs changes as docs-only, even when code changed too.
- **Fix:** Split the filter into `docs` and `code`, then derived a `docs-only` output only when docs changed and code did not.
- **Files modified:** `.github/workflows/ci.yml`
- **Verification:** `rg -n "dorny/paths-filter@v3|docs-only|if:" .github/workflows/ci.yml`
- **Committed in:** `188112b`

**2. [Rule 1 - Bug] Tightened release gate semantics to require normalized success states**
- **Found during:** Task 2
- **Issue:** The first pass allowed `skipped` directly in the shared gate script, which weakened the plan’s required-check contract.
- **Fix:** Restricted `scripts/ci/release_gate.sh` to `success` only and normalized docs-only skips inside `ci.yml` before invoking the script.
- **Files modified:** `scripts/ci/release_gate.sh`, `.github/workflows/ci.yml`
- **Verification:** `bash scripts/ci/release_gate.sh changes=success lint=success test=success integration-placeholder=success`
- **Committed in:** `188112b`

**3. [Rule 1 - Bug] Hardened the release-please dry-run helper after local execution failures**
- **Found during:** Task 3
- **Issue:** The initial helper used brittle bootstrap regexes and a hardcoded repo guess that failed in this workspace.
- **Fix:** Replaced the brittle checks, added repo URL normalization, and required `RULESTEAD_RELEASE_PLEASE_REPO_URL` or `origin` for local dry runs.
- **Files modified:** `scripts/ci/release_please_dry_run.sh`
- **Verification:** `bash -n scripts/ci/release_please_dry_run.sh` and `bash scripts/ci/release_please_dry_run.sh`
- **Committed in:** `ba9095b`

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All fixes were required for the CI/release surface to behave as specified. No extra product scope was added.

## Issues Encountered

- The documented Docker fallback command for `actionlint` passed `actionlint` twice for the current `rhysd/actionlint` image entrypoint. Local verification succeeded with `docker run --rm -v "$PWD:/work" -w /work rhysd/actionlint:latest .github/workflows/*.yml`.
- `scripts/ci/check_package_whitelist.sh` currently fails in this workspace because `rulestead/mix.exs` references package-file paths (`priv/templates`, `priv/repo/migrations`, `guides`) that are missing outside this plan’s ownership surface.
- `scripts/ci/release_please_dry_run.sh` now fails clearly without a configured `origin` remote or `RULESTEAD_RELEASE_PLEASE_REPO_URL`, which this local workspace does not currently provide.

## Known Stubs

- `scripts/ci/integration_placeholder.sh:6` - intentional Phase 1 placeholder line until the real integration lane lands in Phase 5.

## User Setup Required

None - no external service configuration was added by this plan.

## Next Phase Readiness

- The repo now has the required Phase 1 workflow and script surface for CI, release automation, and merge gating.
- Two external blockers remain before every helper can go green locally: the missing package-file directories referenced by `rulestead/mix.exs`, and the absence of a GitHub remote or `RULESTEAD_RELEASE_PLEASE_REPO_URL` for Release Please dry runs.

## Self-Check

PASSED

---
*Phase: 01-repo-bootstrap*
*Completed: 2026-04-23*
