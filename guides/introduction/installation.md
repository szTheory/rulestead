# Installation

Rulestead ships as two sibling packages:

- `rulestead` for runtime evaluation, installer support, context helpers, and tests
- `rulestead_admin` for the optional mounted admin UI

Install only the package boundary your app needs.

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
[rulestead_admin/README.md](../../rulestead_admin/README.md).

## What happens next

- Follow [Getting Started](getting-started.md) for the first-success path
- Use [Evaluation](../flows/evaluation.md) for runtime usage patterns
- Use [Admin UI](../flows/admin-ui.md) if your app mounts the operator surface
