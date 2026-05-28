# Getting Started

This is the first-success path for the current `0.1.0` package line: install
the runtime, gate one code path, and optionally mount the admin UI.

## 1. Add dependencies

Runtime only:

```elixir
{:rulestead, "~> 0.1"}
```

Runtime plus admin UI:

```elixir
{:rulestead, "~> 0.1"},
{:rulestead_admin, "~> 0.1"}
```

Repo GA shipped in `v1.0.0` on 2026-05-21, but adoption today still starts
from the `0.1.x` sibling packages shown above.

## 2. Install and migrate

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

## 3. Gate a code path

Build an explicit `%Rulestead.Context{}` and evaluate against a flag payload.
This is the canonical contract documented in [../flows/evaluation.md](../flows/evaluation.md):

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

### Snapshot runtime lookup

When using Phoenix with the snapshot cache, use `Rulestead.Runtime` with the
environment key and context from Plug (see
[evaluation.md](../flows/evaluation.md)):

```elixir
context = conn.assigns[:rulestead_context]

{:ok, enabled?} =
  Rulestead.Runtime.enabled?("production", "checkout_v2", context)

{:ok, variant} =
  Rulestead.Runtime.get_variant("production", "pricing_experiment", context)
```

Projection helpers on `Rulestead` (`enabled?/2`, `get_variant/2`) accept
**flag payload + context**, not a string key on `%Plug.Conn{}`.

## 4. Optionally mount the admin UI

If your host Phoenix app needs the operator UI:

```elixir
import RulesteadAdmin.Router

scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The host contract is intentionally narrow: provide the required `policy:`
module, the documented session keys, and preserve the canonical `?env=`
selector. The package-local details are in
[../../rulestead_admin/README.md](../../rulestead_admin/README.md).

## 5. Continue from here

- In scope / deferred surfaces: [Product Boundary](product-boundary.md)
- Common mistakes: [Footguns](../recipes/footguns.md)
- Product mental model: [User Flows and JTBD](user-flows-and-jtbd.md)
- Flag from birth to retirement: [../flows/flag-lifecycle.md](../flows/flag-lifecycle.md)
- Runtime usage: [../flows/evaluation.md](../flows/evaluation.md)
- Rules and precedence: [../flows/rulesets.md](../flows/rulesets.md)
- Explain and support workflows: [../flows/explainability.md](../flows/explainability.md)
- Testing and fake-backed helpers: [../recipes/testing.md](../recipes/testing.md)
- Runnable proof path: [../../examples/demo/README.md](../../examples/demo/README.md)
