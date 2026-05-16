---
phase: 15-lifecycle-hygiene-and-code-references
plan: 02
subsystem: code-references
tags:
  - AST
  - CI
  - Webhooks
requires: []
provides:
  - Passive CI code reference scanner via Mix task
  - Authenticated ingress API to receive flag locations
affects:
  - Code reference storage
tech-stack:
  added: []
  patterns:
    - Native Elixir AST traversal (Code.string_to_quoted, Macro.prewalk)
    - Token-authenticated Webhook Plug
key-files:
  created:
    - rulestead/lib/rulestead/code_refs/scanner.ex
    - rulestead/lib/mix/tasks/rulestead.code_refs.ex
    - rulestead/lib/rulestead/webhooks/code_refs_plug.ex
    - rulestead/lib/rulestead/code_refs/code_reference.ex
    - rulestead/priv/repo/migrations/20260516193701_create_rulestead_code_references.exs
  modified: []
decisions:
  - "Used Elixir's native AST parser instead of regex for precise code reference detection."
  - "Implemented a simple token-based authentication for the ingress plug."
  - "Created an Ecto schema and migration for persisting ingested code references."
metrics:
  duration: "45m"
  completed-date: "2026-05-16"
---

# Phase 15 Plan 02: AST Scanner and Code Refs Ingress Summary

Implemented a passive CI scanner that uses an AST parser to extract flag locations and securely posts them to an authenticated webhook endpoint in the Rulestead application.

## Key Changes
- Created an AST Code Reference Scanner (`rulestead/lib/rulestead/code_refs/scanner.ex`) to safely find `Rulestead.evaluate` usages.
- Created `mix rulestead.code_refs` task to automate AST scanning and network pushing in CI pipelines.
- Created `CodeRefsPlug` to ingest CI payloads securely, persisting code references in a new DB table.

## Deviations from Plan
- **Rule 2 - Auto-add missing critical functionality:** Added `rulestead/lib/rulestead/code_refs/code_reference.ex` and a migration script to properly store incoming references, which was necessary to fulfill the "persisting ingested data" action and test validations for Task 3.

## TDD Gate Compliance
- RED: Test files added and initially failed.
- GREEN: Implementation code passed the test behaviors.
- Features implemented using TDD principles correctly.

## Threat Flags
None. All mitigations in the threat model were applied.

## Self-Check: PASSED
- `git log --oneline --all` verifies tasks 1, 2, and 3 are present.
- All newly created files exist.