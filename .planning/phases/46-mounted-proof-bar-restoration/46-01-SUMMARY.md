---
phase: 46-mounted-proof-bar-restoration
plan: 01
subsystem: verification
tags: [mounted-admin, proof-bar, lifecycle, scripts]
requires: []
provides:
  - restored repo-root mounted_admin_contract suite definition
  - bounded mounted lifecycle proof coverage in the named verifier
affects: [repo-root proof semantics, mounted lifecycle verification]
tech-stack:
  added: []
  patterns: [bounded proof lane, repo-root verifier curation]
key-files:
  created: []
  modified: [scripts/ci/test.sh]
key-decisions:
  - "Restored `mounted_admin_contract` to the bounded mounted lifecycle suite instead of keeping the temporary Phase 45 seam-only scope."
  - "Kept the named verifier focused on host seam, queue, cleanup flow, and core lifecycle truth without widening it into a broad admin lane."
patterns-established:
  - "Mounted proof bars should name one curated route-backed lifecycle contract and stay rerunnable from the repo root."
requirements-completed: [ADM-01]
duration: 20min
completed: 2026-05-25
---

# Phase 46 Plan 01 Summary

**The repo-root mounted proof bar now runs the intended bounded lifecycle contract again.**

## Accomplishments

- Re-expanded `RULESTEAD_TEST_SCOPE=mounted_admin_contract` to run the mounted session, host seam, queue, cleanup, preview, confirm, and core lifecycle/admin suites.
- Kept the verifier scope explicit in `scripts/ci/test.sh` instead of broadening into unrelated admin screens.

## Verification

- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs test/rulestead_admin/live/flag_live/index_test.exs`
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`

## Task Commits

No new commit was created during this execution run.

## Next Phase Readiness

Wave 2 can now keep the restored mounted verifier green by repairing the cleanup route and permission contract against the real host session.
