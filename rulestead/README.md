# rulestead

`rulestead` is the runtime package in the Rulestead sibling-package release.

Use this package when your application needs deterministic flag evaluation,
typed values, context builders, installer support, and fake-backed test helpers
without mounting the admin UI.

Lifecycle guidance still lives in the shared root docs. The canonical flag from
birth to retirement guide is
[../guides/flows/flag-lifecycle.md](../guides/flows/flag-lifecycle.md), and it
keeps owner truth host-owned instead of turning the runtime package into an
identity directory.

## Install

The first public Hex release for `rulestead` is planned for after `v0.6.0`.

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"}
  ]
end
```

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

## Runtime entrypoints

- `Rulestead.enabled?/2`
- `Rulestead.get_value/3`
- `Rulestead.get_variant/2`
- `Rulestead.evaluate/3`
- `Rulestead.explain/2`

## Next docs

- Root front door: [../README.md](../README.md)
- Guided onboarding: [../guides/introduction/getting-started.md](../guides/introduction/getting-started.md)
- Lifecycle guide: [../guides/flows/flag-lifecycle.md](../guides/flows/flag-lifecycle.md)
- Runtime usage: [../guides/flows/evaluation.md](../guides/flows/evaluation.md)
- Testing helpers: [../guides/recipes/testing.md](../guides/recipes/testing.md)
