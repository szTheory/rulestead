---
phase: 42-runtime-contract-parity
plan: 03
subsystem: admin-installer-proof
tags:
  - mounted-admin
  - installer
  - golden
  - verification
dependency_graph:
  requires:
    - "42-01 clean GA migration baseline"
    - "42-02 embed-only runtime contract"
  provides: "Mounted-admin and installer fixtures aligned to the single baseline migration"
  affects:
    - rulestead_admin/lib/rulestead_admin/live/
    - rulestead/test/fixtures/install_golden/
    - rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs
    - rulestead/test/support/install_fixture.ex
tech_stack:
  added: []
  patterns:
    - mounted-admin reads ownership from embeds
    - normalized installer golden fixtures track a single baseline migration
decisions:
  - Switched mounted-admin owner rendering and form hydration to read from `flag.ownership` instead of legacy top-level fields.
  - Replaced the normalized golden migration tree and stdout expectations with a single `create_rulestead_tables` baseline migration.
  - Hardened install-fixture Hex env defaults to reduce transient network timeouts during generated host-app verification.
metrics:
  duration: 1 session
  tasks_completed: 2
  tasks_total: 2
  files_modified: 10
---

# Phase 42 Plan 03: Mounted Admin And Installer Proof Summary

**Aligned mounted-admin views and installer goldens to the embed-only authored-state contract and the squashed migration baseline.**

## What Was Built
- Updated mounted-admin list/detail/experiment/rollout surfaces and the flag form to render owner data from `flag.ownership.owner_display || owner_ref`.
- Removed admin form persistence and hydration fallbacks that still wrote or read `owner`, `permanent`, and `expected_expiration`.
- Replaced installer expectations so both unit tests and golden fixtures now expect `.keep` plus one squashed migration file.
- Updated the normalized install-fixture tracked tree to follow `TIMESTAMP_create_rulestead_tables.exs`.

## Verification
- `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs`
- `cd rulestead_admin && mix compile`
- `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs`
- Result: passing on 2026-05-25.

## Bounded Verification Note
- `cd rulestead && mix test test/rulestead/integration/install_golden_test.exs` was re-run after the fixture update, but the generated host-app path remained long-running in this session and previously hit a Hex fetch timeout before the helper was hardened with `HEX_HTTP_CONCURRENCY=1` and `HEX_HTTP_TIMEOUT=120`.
- The fixture and unit installer truth are updated; one full golden integration rerun should still be treated as the final proof step before declaring Phase 42 fully verified.
