---
status: complete
mode: shift-left
phase: 42-runtime-contract-parity
source:
  - 42-01-SUMMARY.md
  - 42-02-SUMMARY.md
  - 42-03-SUMMARY.md
started: 2026-05-25T05:24:31Z
updated: 2026-05-25T05:24:31Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Automation Map

### 1. Cold start smoke test
commands:
  - `cd rulestead && HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=120 mix test test/rulestead/integration/install_golden_test.exs`

### 2. GA-ready migration baseline matches authored-state schema
commands:
  - `rg -n "create table\\(:flags|ownership|lifecycle|environment_versions|tenant_key" rulestead/priv/repo/migrations/20260524000000_create_rulestead_tables.exs`

### 3. Core runtime authored-state contract stays green
commands:
  - `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/admin_test.exs`

### 4. Mounted admin reads and submits ownership through embeds
commands:
  - `cd rulestead_admin && mix compile`
  - `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs`

### 5. Installer golden output matches the squashed baseline
commands:
  - `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs`
  - `cd rulestead && HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=120 mix test test/rulestead/integration/install_golden_test.exs`

## Tests

### 1. Cold Start Smoke Test
expected: A fresh generated Phoenix host app can install `rulestead`, create the database, run the squashed migration, and finish the installer proof path without warm-state assumptions or Hex timeout drift.
result: pass

### 2. Authored-state migration baseline matches runtime contract
expected: New adopters receive one GA-ready migration where `flags` store ownership and lifecycle as embeds and `environment_versions` includes `tenant_key`, with no legacy top-level owner or lifecycle columns required by runtime code.
result: pass

### 3. Core runtime lifecycle and ownership parity holds end to end
expected: Targeted `rulestead` tests prove create, update, list, and admin flows read and write authored ownership and lifecycle data through the embed-only contract.
result: pass

### 4. Mounted admin form and rendering stay aligned with embed ownership
expected: `rulestead_admin` compiles and its flag form tests prove owner display and persistence use `flag.ownership` semantics instead of legacy top-level fields.
result: pass

### 5. Installer unit and golden fixtures agree on the single migration baseline
expected: Installer tests and generated-host golden verification both expect `.keep` plus one normalized `create_rulestead_tables` migration, with stdout and tracked tree matching the current contract.
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

none
