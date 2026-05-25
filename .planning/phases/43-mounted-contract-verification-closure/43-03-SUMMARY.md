---
phase: 43-mounted-contract-verification-closure
plan: 03
subsystem: verification-truth
tags:
  - verification
  - ci
  - docs
  - maintainer
dependency_graph:
  requires:
    - "43-01 mounted companion contract wording"
    - "43-02 mounted lifecycle proof repair"
  provides: "Rerunnable mounted lifecycle/admin proof bar and bounded support truth"
  affects:
    - scripts/ci/test.sh
    - README.md
    - rulestead_admin/README.md
    - MAINTAINING.md
tech_stack:
  added: []
  patterns:
    - scoped CI proof entry
    - bounded release/support wording
decisions:
  - Added a dedicated `mounted_admin_contract` scope to `scripts/ci/test.sh` instead of widening Phase 43 into repo-wide cleanup.
  - Bound public and maintainer truth to the mounted lifecycle/admin surface that the scoped proof bar actually covers.
metrics:
  duration: 1 session
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 43 Plan 03: Verification Truth Closure Summary

**Encoded the repaired mounted lifecycle/admin proof bar and aligned public and maintainer truth to that scoped surface.**

## What Was Built
- Added `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` as the single rerunnable Phase 43 proof entry.
- Scoped that wrapper to the mounted companion form/index/cleanup/preview/confirm/admin-mount suites plus `rulestead`'s `admin_contract_test.exs` and `admin_lifecycle_test.exs`.
- Updated `README.md`, `rulestead_admin/README.md`, and `MAINTAINING.md` so they claim green only for the repaired mounted lifecycle/admin surface.
- Kept the docs explicit that this bounded proof bar is narrower than "all admin behavior" or future milestone closure.

## Verification
- `rg -n "flag_live/form_test|flag_live/index_test|cleanup_test|cleanup_preview_test|cleanup_confirm_test|admin_mount_test|admin_contract_test|admin_lifecycle_test" scripts/ci/test.sh MAINTAINING.md`
- `rg -n "mounted companion|lifecycle/admin|verification|proof|bounded" README.md rulestead_admin/README.md MAINTAINING.md`
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`
- Result: passing on 2026-05-25 (`20 tests, 0 failures` in `rulestead_admin`; `12 tests, 0 failures` in `rulestead`).

## Threat Flags
None.
