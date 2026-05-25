---
phase: 43-mounted-contract-verification-closure
plan: 02
subsystem: mounted-lifecycle-proof
tags:
  - mounted-admin
  - tests
  - lifecycle
  - permissions
dependency_graph:
  requires:
    - "43-01 mounted companion contract wording"
  provides: "Mounted lifecycle/admin proof aligned to the embed-based authored-state contract"
  affects:
    - rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs
    - rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs
    - rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs
    - rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs
tech_stack:
  added: []
  patterns:
    - embed-based ownership/lifecycle seeds
    - viewer versus execute/admin route gating
decisions:
  - Removed stale `owner`, `permanent`, and `expected_expiration` seeds from the mounted lifecycle/admin suites.
  - Preserved the intended permission split: cleanup readable to viewers, preview and confirm execute/admin only.
metrics:
  duration: 1 session
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 43 Plan 02: Mounted Lifecycle Proof Repair Summary

**Repaired the mounted lifecycle/admin suites to prove the current authored-state contract instead of the removed legacy seed shape.**

## What Was Built
- Replaced stale lifecycle/admin test seeds with explicit `ownership` and `lifecycle` embeds across the queue, cleanup, preview, and confirm suites.
- Kept code-reference scan and readiness fixtures additive to the authored payload rather than using legacy top-level fields as stand-ins.
- Updated the confirm drift test to mutate the lifecycle embed directly instead of removed `permanent` and `expected_expiration` fields.
- Preserved the explicit proof that cleanup stays viewer-readable while preview and confirm reject unauthorized actors.

## Verification
- `! rg -n "owner:|permanent:|expected_expiration:" rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs test/rulestead_admin/integration/admin_mount_test.exs`
- Result: passing on 2026-05-25 (`20 tests, 0 failures`).

## Threat Flags
None.
