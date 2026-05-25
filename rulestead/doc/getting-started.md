# Getting Started

This is the first-success path for `v0.1.0`: install the package, gate one
code path, and optionally mount the admin UI.

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

## 2. Install and migrate

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

## 3. Gate a code path

Use a `Plug.Conn`, a `%Rulestead.Context{}`, or another supported context
builder. The common first step is gating one controller path:

```elixir
if Rulestead.enabled?("checkout_v2", conn) do
  render_v2(conn)
else
  render_v1(conn)
end
```

When you need typed values or variants, keep the same runtime boundary:

```elixir
variant = Rulestead.get_variant("pricing_experiment", conn)
config = Rulestead.get_value("checkout_config", conn, default: %{"timeout_ms" => 1_000})
```

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

- Product mental model: [User Flows and JTBD](user-flows-and-jtbd.md)
- Runtime usage: [../flows/evaluation.md](../flows/evaluation.md)
- Rules and precedence: [../flows/rulesets.md](../flows/rulesets.md)
- Explain and support workflows: [../flows/explainability.md](../flows/explainability.md)
- Testing and fake-backed helpers: [../recipes/testing.md](../recipes/testing.md)
