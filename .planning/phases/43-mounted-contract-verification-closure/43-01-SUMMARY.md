---
phase: 43-mounted-contract-verification-closure
plan: 01
subsystem: mounted-contract-docs
tags:
  - mounted-admin
  - docs
  - integration
  - lifecycle
dependency_graph:
  requires: []
  provides: "Stable mounted companion seam and supported lifecycle workflow wording"
  affects:
    - rulestead_admin/README.md
    - guides/flows/admin-ui.md
    - guides/flows/flag-lifecycle.md
    - rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs
tech_stack:
  added: []
  patterns:
    - mounted companion contract
    - route-backed lifecycle workflow
decisions:
  - Kept the public mounted seam narrow around `policy:`, session inputs, `?env=`, and `return_to`.
  - Documented `cleanup -> preview -> confirm -> audit` as the supported workflow without freezing every inner route detail as public API.
metrics:
  duration: 1 session
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 43 Plan 01: Mounted Contract Docs And Route Proof Summary

**Clarified the mounted companion contract and aligned the host-facing route proof to the current lifecycle flow.**

## What Was Built
- Tightened `rulestead_admin/README.md` around host-owned auth/session/policy seams and the queue-preserving `return_to` convention.
- Updated `guides/flows/admin-ui.md` to distinguish the stable mounted seam from the supported lifecycle workflow.
- Updated `guides/flows/flag-lifecycle.md` so the canonical archive path explicitly starts at cleanup review before preview, confirm, and audit.
- Replaced the mount integration test's legacy seed shape with the current `ownership` and `lifecycle` embeds and added preview-route coverage.

## Verification
- `rg -n "mounted companion|host owns|policy:|session|\\?env=|return_to" rulestead_admin/README.md guides/flows/admin-ui.md`
- `rg -n "cleanup.*preview.*confirm.*audit|viewer|execute|admin" guides/flows/admin-ui.md guides/flows/flag-lifecycle.md`
- `cd rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs`
- Result: passing on 2026-05-25.

## Threat Flags
None.
