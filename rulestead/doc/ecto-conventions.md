# Ecto Conventions

Rulestead's Ecto integration in `v0.1.0` is about authoring and publishing
rulesets, not about evaluating flags from the database on the hot path.

The core convention is:

- Ecto owns persisted authoring state.
- published snapshots feed the runtime.
- application code evaluates through the keyed runtime surface, not through
  `Repo` queries over Rulestead tables.

## Keep evaluation out of request-path queries

Do not join `rulestead_*` tables into request-path queries just to decide a
flag. The supported runtime path is:

1. author through the store
2. publish a snapshot
3. evaluate from the runtime cache

That preserves the explicit no-DB-on-the-hot-path contract.

## Use `mix rulestead.install` for schema setup

The published install path is the supported way to lay down the base store
schema and host-app wiring:

```bash
cd your_phoenix_app
mix deps.get
mix rulestead.install
mix ecto.migrate
```

The install smoke proof for `v0.1.0` verifies that this path creates the
expected tables and host wiring in a fresh Phoenix app.

## Treat `Rulestead.Store` as the extension seam

If you need a different persistence strategy, extend at the
[`Rulestead.Store`](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store.ex:1)
behavior boundary.

For ordinary app usage, prefer the public facade:

```elixir
{:ok, page} = Rulestead.list_flags(environment_key: "prod", owner: "growth")
{:ok, detail} = Rulestead.fetch_flag("checkout-redesign", "prod")
```

Those calls route through the configured store without exposing internal table
layout as your app's contract.

## Keep writes explicit and environment-scoped

Authoring operations should always be explicit about environment and mutation
intent:

```elixir
alias Rulestead.Store.Command

command =
  Command.PublishRuleset.new("checkout-redesign", "prod",
    actor: %{id: "operator-123"},
    version: 3
  )

{:ok, published} = Rulestead.publish_ruleset(command)
```

That keeps the store boundary semantic and auditable instead of turning it into
ad hoc CRUD.

## Let the host app own repo lifecycle

Rulestead does not ask you to replace your repo, migration workflow, or deploy
policy. The host app still owns:

- repo startup
- migration execution
- database credentials
- deployment ordering

Rulestead supplies migrations and a store contract. Your application remains
the system of record for repo lifecycle.

## Avoid leaking internal table assumptions

It is fine to inspect installed tables while debugging or verifying a release,
but treat those names as authoring-storage implementation details, not as an
invitation to build your own runtime evaluator on top of them.

If your app needs a reporting projection, build that in your own application
boundary instead of reading raw Rulestead rows from user-facing request code.

## Test with Fake, verify integration with Ecto

The recommended split is:

- host-app tests use `Rulestead.TestHelpers` and `Rulestead.Fake`
- installer and migration confidence use `mix rulestead.install` plus
  `mix ecto.migrate`
- store-specific integration tests are optional and app-owned

That keeps the main suite fast while still leaving room for higher-level Ecto
coverage where it matters.
