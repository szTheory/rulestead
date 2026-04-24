# Deployment

Rulestead deployment in `v0.1.0` follows the same split as the rest of the
package:

- authoring state is installed and migrated like normal Ecto-backed app data
- runtime evaluation stays local to each node via snapshots and cache refresh
- host apps own deployment orchestration, secrets, and rollout order

This recipe covers the seams that ship today. It does not assume a hosted
control plane or centralized governance service.

## Deploy migrations before expecting authored state

After adding the package and running `mix rulestead.install`, include the
generated migrations in your normal deploy flow:

```bash
mix ecto.migrate
```

The installed schema is required for authoring and snapshot publication. If the
tables are not present yet, the runtime can only serve what it already has in
memory or on disk backup.

## Start with degraded-mode expectations

The runtime is designed to tolerate startup-order imperfections better than a
request-path DB lookup model. Your deployment posture should still assume:

- a node may boot before the store is reachable
- a node may temporarily serve defaults or last-known-good snapshots
- refresh health should be observed explicitly in ops tooling

## Keep runtime evaluation local to each node

Application code should keep evaluating through the keyed runtime surface
during deploys:

```elixir
{:ok, enabled?} =
  Rulestead.Runtime.enabled?(
    "prod",
    "checkout-redesign",
    %{targeting_key: "user-123", environment: "prod"}
  )
```

Do not switch to request-time SQL queries or ad hoc fallbacks during deploys.

## Preserve refresh infrastructure

In production, ensure the pieces your host app already owns remain healthy:

- Postgres for authored state
- Phoenix.PubSub for snapshot fanout where configured
- Oban only if your app is using the documented Oban seam

Rulestead does not require a separate deployment tier. It expects to live
inside the host application's release model.

## Treat disk backup as resilience, not authoring truth

If you enable runtime backup persistence, use it as a restart and degraded-mode
aid. Do not treat it as the place where operators author or repair flag state.

The source of truth for published rulesets remains the configured store.

## Release in the same order your app already trusts

The safe deployment order is:

1. migrate the database
2. deploy the application release
3. verify runtime refresh and evaluation behavior
4. then publish or mutate new rulesets if needed

That ordering matches the shipped seams and avoids depending on unpublished
future features.

## Watch telemetry instead of scraping internals

During a deploy, use the public telemetry contract to observe:

- cache misses
- stale snapshot usage
- refresh outcomes
- evaluation reasons and cache age

That gives you deployment confidence without locking tooling to internal
processes or ETS table names.
