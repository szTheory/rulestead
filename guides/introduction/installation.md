# Installation

Rulestead ships as two sibling packages:

- `rulestead` for runtime evaluation, installer support, context helpers, and tests
- `rulestead_admin` for the optional mounted admin UI

Repo GA shipped in `v1.0.0` on 2026-05-21, and the current installable package
line on Hex is **`0.1.4`** (`~> 0.1`). Install only the package boundary your app needs.

> **Two version lines:** GitHub repo milestones track project delivery. **Hex
> packages** use `0.1.x` semver until a future `1.0` API freeze.

## Runtime-only apps

Choose this path if application code needs flag evaluation but your team does
not need the mounted admin UI in the host Phoenix app.

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"}
  ]
end
```

## Apps that also mount the admin UI

Choose this path if a host Phoenix app needs both runtime evaluation and the
operator UI.

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:rulestead_admin, "~> 0.1"}
  ]
end
```

## Install and migrate

After adding the dependency set you need:

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

`mix rulestead.install` adds the package-owned setup needed for the runtime
surface. If you mount `rulestead_admin`, follow the router seam documented in
[rulestead_admin on HexDocs](https://hexdocs.pm/rulestead_admin).

## Two adoption paths

Choose the path that matches where you are:

1. **Evaluate first** — run the [Adoption Lab](adoption-lab.md#at-a-glance) (FleetDesk) with
   `docker compose up --build`. Pre-installed host with seeded flags; no changes
   to your app.
2. **Install into your app** — follow the steps below, then
   [Getting Started](getting-started.md) and the [Phoenix Integration Spine](phoenix-integration-spine.md).

Fresh-install wiring proof (installer golden-diff, no FleetDesk UI):

```bash
scripts/demo/install_journey.sh
```

## What happens next

- **Phoenix integrators:** [Phoenix Integration Spine](phoenix-integration-spine.md)
  — supervision → config → Plug → first flag (lifecycle fields required)
- **Lifecycle at create:** flags require **`owner_ref`** and
  **`expected_expiration`** before save — see
  [Flag Lifecycle](../flows/flag-lifecycle.md)
- Follow [Getting Started](getting-started.md) for the first-success path
- Use [Evaluation](../flows/evaluation.md) for runtime usage patterns
- Use [Admin UI](../flows/admin-ui.md) if your app mounts the operator surface
- Use [Adoption Lab](adoption-lab.md) for the persona-oriented evaluation guide
- Use [FleetDesk demo (examples/demo)](https://github.com/szTheory/rulestead/tree/main/examples/demo) for compose
  and Playwright command reference
