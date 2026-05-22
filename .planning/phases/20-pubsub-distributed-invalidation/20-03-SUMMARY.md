---
phase: 20
plan: 03
subsystem: installer
tags: [installer, config, pubsub]
requires:
  - 20-01
provides:
  - generated runtime pubsub wiring
affects:
  - install config scaffold
  - install direct tests
  - install golden fixture
key_files_modified:
  - rulestead/lib/rulestead/install/config_writer.ex
  - rulestead/test/fixtures/install_golden/tree/config/rulestead.exs
  - rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs
completed_date: "2026-05-17"
---

# Phase 20 Plan 03: Installer PubSub Wiring Summary

Updated the installer generator so `config/rulestead.exs` now renders the Phase 20 runtime wiring directly from code. Generated host config includes the default notifier, the host app PubSub module, and the runtime topic, while direct installer tests and the golden tree lock the scaffold against drift.

## Verification

- `mix test test/rulestead/mix/tasks/rulestead_install_test.exs test/rulestead/integration/install_golden_test.exs`

## Deviations from Plan

- The existing golden integration test already covered the normalized tree contract, so only the generated fixture content needed to change.
