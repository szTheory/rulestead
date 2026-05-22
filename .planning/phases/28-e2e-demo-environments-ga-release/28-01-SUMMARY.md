# 28-01 Summary

## Status

Completed on 2026-05-21.

## Outcome

Created the thin Phoenix host app under `examples/demo/backend` and kept the Phase 28 demo boundary confined to `examples/demo/**`. The backend now depends on the local `rulestead` and `rulestead_admin` sibling packages, owns the installer-generated persistence/runtime artifacts needed for `mix ecto.setup`, mounts `rulestead_admin` through a host policy seam, and exposes the deterministic `/demo/sign-in` route required by later automation.

## Verification

- `cd examples/demo/backend && mix deps.get`
- `cd examples/demo/backend && mix compile`
- `cd examples/demo/backend && mix ecto.create && mix ecto.migrate`

## Notes

- `mix rulestead.install` generated the host-owned migrations and `config/rulestead.exs` contract that the later seed/runtime plans build on.
- The runtime refresh workers are started from `RulesteadDemo.Application` so the host app controls startup ordering around repo and PubSub dependencies.
