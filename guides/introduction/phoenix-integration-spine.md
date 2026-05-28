# Phoenix Integration Spine

This is the **first-hour path** for a Phoenix host app: from dependencies through
supervision, config, Plug, your first runtime evaluation, and a lifecycle-honest
flag create. Budget about fifteen minutes if you already have Postgres and a
running Phoenix app.

For the payload-first mental model (tests, simulations, and pure evaluation),
see [Evaluation](../flows/evaluation.md). This spine optimizes for the path most
teams take in production: snapshot cache + keyed lookup.

## 1. Before you start

Add the packages you need (see [Installation](installation.md)):

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:rulestead_admin, "~> 0.1"}  # optional operator UI
  ]
end
```

Then install and migrate:

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

`mix rulestead.install` writes host config, injects `Rulestead.Plug` into your
endpoint, and (when enabled) scaffolds the admin mount. It does **not** patch your
host `application.ex` — runtime supervision starts with the `:rulestead` OTP
application (next section).

## 2. How Rulestead runs in your BEAM

When `{:rulestead, ...}` is in your deps, the `:rulestead` application starts
`Rulestead.Application`. That supervisor owns the local snapshot runtime, not your
host app's root supervisor.

Typical children include:

- `Rulestead.Runtime.Supervisor` — snapshot cache and keyed lookup
- `Rulestead.Analytics.Batcher` — bounded analytics batching
- `Rulestead.Admin.StaleTracker` — lifecycle hygiene signals for operators

You do not add these modules to `MyApp.Application` children yourself. If the
`:rulestead` app is not running, keyed runtime calls will not see a warm cache.

## 3. Host config after install

The installer writes `config/rulestead.exs` and adds `import_config "rulestead.exs"`
to your host `config/config.exs`. The shape matches what the installer generates
(abbreviated):

```elixir
import Config

config :rulestead, :store, Rulestead.Store.Ecto

config :rulestead, Rulestead.Repo,
  repo: MyApp.Repo

config :rulestead, :host,
  environment_key: "dev",
  plug: [
    context_assign: :rulestead_context,
    targeting_key_sources: [
      session: "targeting_key",
      cookie: "rulestead_targeting_key",
      header: "x-rulestead-targeting-key"
    ]
  ],
  runtime: [
    api: Rulestead.Runtime,
    notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
    pubsub: MyApp.PubSub,
    pubsub_topic: "rulestead:runtime_snapshot"
  ]
```

Tune `environment_key` per deploy. The installer default is `"dev"` — keep
Runtime lookups, flag `environment_keys`, and admin `?env=` routing aligned with
that value (or your chosen override). Plug and runtime keys must stay aligned with
how you build `%Rulestead.Context{}` in request handlers.

## 4. Request boundary: Plug

The installer places `Rulestead.Plug` in your endpoint after
`Plug.Telemetry` — for example:

```elixir
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
plug Rulestead.Plug
```

The plug assigns a normalized `%Rulestead.Context{}` to
`conn.assigns[:rulestead_context]`. It does not evaluate flags by itself.

For LiveView mount, Oban workers, and explicit source lists, continue in
[Context Propagation](../recipes/context-propagation.md) — do not duplicate that
machinery here.

## 5. First runtime evaluation

In a controller (or Plug-aware context), read the assign the plug set:

```elixir
context = conn.assigns[:rulestead_context]

{:ok, enabled?} =
  Rulestead.Runtime.enabled?("dev", "checkout_v2", context)
```

The first argument must match `config :rulestead, :host, environment_key` (the
installer default is `"dev"`).

`Rulestead.Runtime` looks up the authored flag in the local snapshot cache for the
environment key. It is the supported Phoenix hot path when you already run the
snapshot runtime.

For unit tests, simulations, or inspecting one payload in isolation, use
payload-first `Rulestead.evaluate/3` instead — see
[Evaluation](../flows/evaluation.md). The root `Rulestead` projection helpers
(`enabled?/2`, `get_variant/2`) take **flag payload + context**, not a string key
on `%Plug.Conn{}`.

## 6. Create your first flag (lifecycle required)

Every flag must be born with explicit lifecycle metadata. Rulestead enforces this
at creation time.

Record at minimum:

- **`owner_ref`** — stable host-owned reference (`team-growth`, `svc-checkout`, a
  person id your systems already understand). Rulestead does not maintain a user
  or team directory.
- **`expected_expiration`** — review horizon as a date (or the lifecycle fields
  your authoring surface maps to it).

In the mounted admin UI, the create form requires these fields before save.

Programmatic create (IEx, seeds, or internal tooling) uses the same metadata:

```elixir
{:ok, _flag} =
  Rulestead.create_flag(
    key: "checkout_v2",
    flag_type: :release,
    value_type: :boolean,
    default_value: %{value: false},
    ownership: %{owner_ref: "team-checkout", owner_kind: :team},
    expected_expiration: ~D[2026-12-31],
    environment_keys: ["dev"]
  )
```

Use the same environment keys you pass to `Rulestead.Runtime` (see section 5).
If you author through other store APIs, pass the same lifecycle fields — missing
owner or expiration should fail closed rather than silently defaulting.

Honest posture:

- Owner truth stays in **your** systems; Rulestead stores bounded references.
- Lifecycle guidance is **advisory** for operators — it does not change hot-path
  evaluation semantics.

Full lifecycle flows (review queues, archive readiness, cleanup) live in
[Flag Lifecycle](../flows/flag-lifecycle.md).

## 7. Optional: mount the admin UI

If you installed `rulestead_admin`, the installer adds a router mount similar to:

```elixir
use RulesteadAdmin.Router

scope "/admin", MyAppWeb do
  pipe_through :browser
  rulestead_admin "/flags", policy: MyApp.AdminPolicy
end
```

Provide the host `policy:` module and session keys documented in
[rulestead_admin/README.md](../../rulestead_admin/README.md). Rulestead does not
bundle authentication — your app owns identity.

## 8. Next steps

- [Getting Started](getting-started.md) — alternate payload-first quick path
- [Footguns](../recipes/footguns.md) — targeting_key, Runtime vs root API, snapshots
- [Product Boundary](product-boundary.md) — in-scope vs deferred surfaces
- [Multi-environment](../flows/multi-env.md) — environment keys across deploys
- [../../examples/demo/README.md](../../examples/demo/README.md) — bounded demo proof
- **Prove the band:** `cd rulestead && mix verify.adopter`
