# Rulestead

> **Runtime decisions, made clear.**
> Typed feature flags, variants, and remote config for Elixir apps, with an
> optional mounted Phoenix LiveView admin.

> **Two version lines:** GitHub repo milestones (e.g. `v1.0.0` GA, May 2026)
> track project delivery. **Hex packages** use `0.1.x` semver (currently
> **0.1.x** on Hex) until a future `1.0` API freeze. Install with
> `{:rulestead, "~> 0.1"}`.

## What this is (60 seconds)

Rulestead ships as two sibling Hex packages:

- `rulestead` for the runtime evaluator, installer, context builders, and test helpers
- `rulestead_admin` for the optional host-mounted admin UI

The runtime promise is simple: evaluation stays deterministic, rule precedence
is explicit, and operators can explain why a decision happened without reverse
engineering application state.

Post-GA product surfaces — tenancy helpers, lifecycle hygiene, guarded
rollouts, reusable audiences, blast-radius governance — are documented in
[Product Boundary](guides/introduction/product-boundary.md).

**Prove it locally:** `docker compose up --build`, the
[Adoption Lab](guides/introduction/adoption-lab.md#at-a-glance) runbook, or
`scripts/demo/proof.sh`.

## 15-minute quickstart

Start with the runtime package:

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"}
  ]
end
```

Install and migrate:

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

**Phoenix integrators:** follow the
[Phoenix Integration Spine](guides/introduction/phoenix-integration-spine.md)
for supervision → Plug → `Rulestead.Runtime` → lifecycle-honest flag create.

Gate a code path (payload-first — see [evaluation.md](guides/flows/evaluation.md)):

```elixir
context =
  Rulestead.Context.new(
    environment: "production",
    targeting_key: "user-123",
    attributes: %{plan: :pro}
  )

flag_payload = ... # from snapshot or store

with {:ok, result} <- Rulestead.evaluate(flag_payload, context) do
  if result.enabled? do
    render_v2(conn)
  else
    render_v1(conn)
  end
end
```

When using Phoenix with the snapshot cache, load the flag by environment key via
`Rulestead.Runtime` (see [evaluation.md](guides/flows/evaluation.md) and
[multi-env.md](guides/flows/multi-env.md)):

```elixir
context = conn.assigns[:rulestead_context]

{:ok, enabled?} =
  Rulestead.Runtime.enabled?("production", "checkout_v2", context)
```

If your Phoenix app also needs the mounted companion admin, add
`rulestead_admin` immediately after the runtime dependency:

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:rulestead_admin, "~> 0.1"}
  ]
end
```

Mount the admin UI only if your app needs it:

```elixir
import RulesteadAdmin.Router

scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The guided walkthrough continues in
[Getting Started](guides/introduction/getting-started.md).

## Choose your path

### Build with Rulestead

- [Installation](guides/introduction/installation.md)
- [Getting Started](guides/introduction/getting-started.md)
- [Domain Language & Concepts](guides/introduction/domain_language.md)
- [Flag Lifecycle](guides/flows/flag-lifecycle.md)
- [User Flows and JTBD](guides/introduction/user-flows-and-jtbd.md)
- [Evaluation](guides/flows/evaluation.md), [Rulesets](guides/flows/rulesets.md),
  [Testing](guides/recipes/testing.md)

### Operate via Admin UI

- [rulestead_admin/README.md](rulestead_admin/README.md)
- [Admin UI](guides/flows/admin-ui.md)
- [Explainability](guides/flows/explainability.md)
- [Multi-environment usage](guides/flows/multi-env.md)

### Extend Rulestead

- [CONVENTIONS.md](CONVENTIONS.md)
- [CONTRIBUTING.md](CONTRIBUTING.md) and [MAINTAINING.md](MAINTAINING.md)

## Why teams adopt it

- Deterministic evaluation and sticky bucketing for predictable rollouts
- Ordered rules with first-match-wins precedence
- Explainable decisions for support, operators, and incident response
- Test helpers and fake-backed workflows that do not require Postgres in the hot loop
- A sibling-package layout so runtime-only apps do not carry LiveView admin weight

## Repository layout

- `rulestead/` — runtime package
- `rulestead_admin/` — optional admin package
- `examples/demo/` — FleetDesk adoption lab (backend + frontend)
- `guides/` — shared HexDocs guides

## Local demo

The **FleetDesk adoption lab** runs three surfaces locally: customer app
(`:3000`), Rulestead admin (`/demo/sign-in`), and API (`:4000`).

```bash
scripts/demo/up.sh
```

The script uses `3000` and `4000` when they are free, chooses fallback ports
when they are not, and prints the actual URLs to open.

**Runbook:** [Adoption Lab](guides/introduction/adoption-lab.md#at-a-glance)

Bounded automation: `scripts/demo/proof.sh`

## Maintainers

Proof bars, CI scopes, and release verification:
[MAINTAINING.md](MAINTAINING.md)

## Versioning

See [Upgrading](guides/introduction/upgrading.md) for compatibility posture on
the `0.1.x` package line.
