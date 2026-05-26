---
phase: 47-support-truth-reclosure
plan: 03
subsystem: release-contract
tags: [maintaining, ci, drift-guards, release-contract]
requires:
  - phase: 47-support-truth-reclosure
    provides: bounded root-mounted proof wording
  - phase: 47-support-truth-reclosure
    provides: explicit mounted prerequisite contract
provides:
  - evergreen mounted-proof maintainer runbook wording
  - CI-accurate release_gate semantics in docs
  - automated drift guards for mounted support-truth wording
affects: [maintainer docs, release verification, support-truth regression detection]
tech-stack:
  added: []
  patterns: [command-first runbooks, banned-phrase drift guards, CI-aligned proof docs]
key-files:
  created: []
  modified: [MAINTAINING.md, rulestead/test/rulestead/release_contract_test.exs, rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs]
key-decisions:
  - "Dropped stale phase-number framing from the mounted proof runbook so the section reads as standing repo posture rather than temporary milestone text."
  - "Added both required-phrase and banned-phrase assertions so future doc edits fail closed if they reintroduce suite-level public claims or outdated gate wording."
patterns-established:
  - "Support-truth closure should end with maintainer docs that match the named CI lanes and tests that reject stale public or runbook language."
requirements-completed: [DOC-01]
duration: 25min
completed: 2026-05-26
---

# Phase 47 Plan 03 Summary

**Maintainer wording and release-contract tests now enforce the repaired mounted support story.**

## Accomplishments

- Updated `MAINTAINING.md` to describe the canonical local mounted-proof rerun command, the named `mounted companion proof` job, and `release_gate`'s path-gated semantics without stale phase framing.
- Extended `Rulestead.ReleaseContractTest` to require bounded public proof wording and the new mounted package fail-closed/fallback semantics while banning suite-level root README drift.
- Extended `verify_release_publish` drift checks to keep published-release verification tied to the same mounted support-truth language.

## Verification

- `rg -n 'Phase 43|mounted companion proof|release_gate|integration-placeholder|mounted-proof|aggregates \`lint\`, \`test\`, \`integration-placeholder\`' /Users/jon/projects/rulestead/MAINTAINING.md /Users/jon/projects/rulestead/.github/workflows/ci.yml`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs`
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`

## Task Commits

No new commit was created during this execution run.

## Next Phase Readiness

Phase 48 can now verify and archive against one stable support narrative across the root README, mounted package README, maintainer runbook, scripts, and release-contract tests.
