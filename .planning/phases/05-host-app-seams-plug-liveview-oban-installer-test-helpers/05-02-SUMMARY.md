---
phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
plan: 02
subsystem: installer
tags: [installer, config, nimble_options, router, oban]
requires:
  - 05-01
provides:
  - validated Phase 5 host seam defaults
  - deterministic endpoint/router/Oban injection
  - compile-safe Phase 5 admin mount seam
affects:
  - INST-01
  - INST-02
  - INST-06
tech_stack:
  added:
    - nimble_options
  patterns:
    - compiled NimbleOptions schema for host seam defaults
    - content-based installer mutation with explicit write/skip lines
    - empty-scope Phase 5 admin router seam that compiles before Phase 6 UI ships
key_files:
  created:
    - rulestead/lib/rulestead/config.ex
    - rulestead/lib/rulestead/install/file_injector.ex
    - rulestead_admin/test/rulestead_admin/router_test.exs
  modified:
    - rulestead/lib/rulestead/install.ex
    - rulestead/lib/rulestead/install/config_writer.ex
    - rulestead/lib/mix/tasks/rulestead.install.ex
    - rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs
    - rulestead_admin/lib/rulestead_admin/router.ex
    - rulestead/mix.exs
    - rulestead/mix.lock
decisions:
  - Phase 5 seam defaults now live behind a public `Rulestead.Config` NimbleOptions schema instead of ad hoc application env reads.
  - Installer mutations were centralized into `Rulestead.Install.FileInjector` so endpoint, router, config import, and Oban edits share the same write-or-skip contract.
  - The sibling admin seam now expands to an empty scoped mount so host routers compile cleanly before any Phase 6/7 UI routes exist.
metrics:
  completed_at: 2026-04-24T01:17:26Z
  verification_commands:
    - cd rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs
    - cd rulestead_admin && mix test test/rulestead_admin/router_test.exs
---

# Phase 05 Plan 02 Summary

`mix rulestead.install` now writes the full Phase 5 host-app seam deterministically: migrations, validated `config/rulestead.exs`, config import wiring, `Rulestead.Plug` injection, a compile-safe `/admin/flags` mount helper, and Oban middleware injection when host Oban config is present.

## What Shipped

- Added `Rulestead.Config` with a compiled NimbleOptions schema and explicit defaults for environment selection, Plug extraction, LiveView assignment mode, Oban context middleware, and the Phase 4 runtime facade module.
- Expanded `Rulestead.Install` into a thin orchestrator over migration copy, config writing, endpoint/router injection, and Oban config mutation.
- Added `Rulestead.Install.FileInjector` so installer edits are content-aware and reruns emit `skip ... already present` instead of duplicating lines.
- Replaced the hard-raising `RulesteadAdmin.Router.rulestead_admin/2` macro with a compile-safe empty scope seam and added focused router tests for the macro surface.
- Locked the installer behavior with scoped tests that assert deterministic output order, byte-stable reruns, and config validation failures for invalid seam settings.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking Issue] Added `nimble_options` to `rulestead/mix.exs` and `rulestead/mix.lock`.
   The Phase 5 config contract required a real validation library; the dependency was not already present.

## Verification

- `cd rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs`

## Known Stubs

- `RulesteadAdmin.Router.rulestead_admin/2` intentionally mounts an empty scope in Phase 5. This is the compile-safe seam only; Phase 6 adds real UI routes.

## Self-Check

PASSED
