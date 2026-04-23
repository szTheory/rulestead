---
phase: 02-data-model-error-model-ecto-store-fake-adapter
plan: 05
subsystem: store-and-installer
tags:
  - ecto
  - installer
  - smoke-test
requires:
  - 02-01
  - 02-02
  - 02-03
  - 02-04
provides:
  - STORE-01
affects:
  - rulestead store adapter parity
  - host-app installation seam
tech_stack:
  - elixir
  - ecto
  - phoenix
key_files:
  created:
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/install.ex
    - rulestead/lib/rulestead/install/repo_locator.ex
    - rulestead/lib/rulestead/install/migration_writer.ex
    - rulestead/lib/rulestead/install/config_writer.ex
    - rulestead/lib/mix/tasks/rulestead.install.ex
    - rulestead/priv/templates/rulestead.install/config/rulestead.exs
    - rulestead/test/rulestead/store/ecto_contract_test.exs
    - rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs
    - rulestead/test/rulestead/integration/install_smoke_test.exs
  modified: []
decisions:
  - Kept the Ecto adapter payloads aligned with the fake adapter so the shared contract suite stays adapter-neutral.
  - Limited installer writes to migrations plus config surfaces and encoded repo-selection failures as typed config errors.
metrics:
  completed_at: 2026-04-23
---

# Phase 02 Plan 05: Ecto Store And Minimal Installer Summary

Real Ecto authoring storage now sits behind the shared `Rulestead.Store` behavior, the Phase 2 installer only writes migrations plus config, and the repo has an explicit fresh-host smoke test for install plus migrate.

## What Shipped

- Added `Rulestead.Store.Ecto` with transactional publish semantics, `%Rulestead.Error{}` normalization, and payload shapes matching `Rulestead.Fake`.
- Added the minimal `mix rulestead.install` slice with repo resolution, migration copying, `config/rulestead.exs` generation, and idempotent `config/config.exs` import injection.
- Added parity coverage for the Ecto adapter, idempotency coverage for the installer, and a Phoenix-host smoke test that exercises generator, install, create, migrate, and schema probes.

## Deviations from Plan

None in shipped scope.

## Verification

- Passed: `cd rulestead && MIX_ENV=test mix ecto.drop --quiet && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate && MIX_ENV=test mix test test/rulestead/store/ecto_contract_test.exs`
- Passed: `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs`
- Implemented but not completed locally: `cd rulestead && mix test test/rulestead/integration/install_smoke_test.exs --timeout 600000`
  The generated Phoenix host app stalled in `mix deps.get` long enough to exceed the local timeout budget in this environment.

## Known Stubs

None.

## Threat Flags

None.

## Commits

- `49196ca` `feat(02-05): add ecto-backed store adapter`
- `0e0f5e8` `feat(02-05): add minimal install task`

## Self-Check: PASSED

- Found summary file: `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-05-SUMMARY.md`
- Found commit: `49196ca`
- Found commit: `0e0f5e8`
