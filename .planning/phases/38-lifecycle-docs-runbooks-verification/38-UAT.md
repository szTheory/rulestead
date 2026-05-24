---
status: complete
mode: shift-left
phase: 38-lifecycle-docs-runbooks-verification
source:
  - 38-01-SUMMARY.md
  - 38-02-SUMMARY.md
  - 38-03-SUMMARY.md
started: 2026-05-24T10:16:21Z
updated: 2026-05-24T10:16:21Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Automation Map

### 1. Canonical lifecycle guide and entrypoint routing
commands:
  - `rg -n "birth to retirement|host owns identity|archive_candidate.*not permission|preview.*confirm.*audit|mix rulestead\.lifecycle" guides/flows/flag-lifecycle.md`
  - `rg -n "flag-lifecycle|birth to retirement" README.md rulestead/README.md rulestead_admin/README.md`

### 2. Satellite runbook lifecycle vocabulary
commands:
  - `rg -n "mix rulestead\.lifecycle|preview.*confirm.*audit|\?env=|return_to|mounted companion" guides/flows/admin-ui.md`
  - `rg -n "explain|audit history|lifecycle evidence|support|SRE" guides/flows/explainability.md`
  - `rg -n "host-owned|advisory|does not affect evaluation|owner truth" guides/flows/evaluation.md`
  - `rg -n "rulestead\.lifecycle|release_contract_test|admin_mount_test|public seam|browser-heavy" guides/recipes/testing.md`
  - `rg -n "DOM|CSS|socket assigns|not public|route|query|mount" guides/api_stability.md`
  - `rg -n "38-VERIFICATION|lifecycle release surface|machine-backed" MAINTAINING.md`

### 3. Core lifecycle release-surface tests
commands:
  - `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs test/rulestead/mix/tasks/verify_release_parity_test.exs`

### 4. Mounted admin lifecycle host seam tests
commands:
  - `cd rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs`
  - `! rg -n "CSS|selector|socket assign" rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`

### 5. Phase-local lifecycle evidence artifact
commands:
  - `test -f .planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md`
  - `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json`

## Tests

### 1. Lifecycle guide is discoverable from repo and package entrypoints
expected: Root and sibling-package entrypoints point readers to one canonical birth-to-retirement lifecycle guide without implying standalone admin ownership.
result: pass

### 2. Supporting runbooks use one lifecycle vocabulary
expected: Admin, explainability, evaluation, testing, API-stability, and maintainer docs consistently describe queue-first review, advisory archive-readiness, and host-owned ownership boundaries.
result: pass

### 3. Core lifecycle CLI and release-surface contracts stay green
expected: The targeted `rulestead` lifecycle suites pass and keep the public lifecycle docs plus `mix rulestead.lifecycle` contract aligned.
result: pass

### 4. Mounted admin lifecycle host seam stays release-safe
expected: The mounted admin lifecycle route, `?env=` query behavior, cleanup review flow, and `return_to` seam pass without freezing private DOM or CSS details.
result: pass

### 5. LIF-05 closeout stays machine-backed and phase-local
expected: Phase 38 keeps a traceable `38-VERIFICATION.md` artifact and no open phase-local verification debt remains.
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
