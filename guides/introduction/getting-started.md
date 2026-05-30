# Getting Started

This is the first-success path for the current `0.1.x` package line on Hex: install
the runtime, gate one code path, and optionally mount the admin UI.

> **Two version lines:** GitHub repo milestones (e.g. `v1.0.0` GA, May 2026)
> track project delivery. **Hex packages** use `0.1.x` semver until a future `1.0`
> API freeze. Install with `{:rulestead, "~> 0.1"}`.

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

**Phoenix first-hour path:** [Phoenix Integration Spine](phoenix-integration-spine.md)
(supervision → config → Plug → first `Rulestead.Runtime` eval → lifecycle-honest
flag create).

> **Lifecycle required at flag create:** Every new flag must include
> **`owner_ref`** (host-owned team or service reference) and
> **`expected_expiration`** (review date). Rulestead does not maintain a team
> directory. See [Flag Lifecycle](../flows/flag-lifecycle.md) and
> [Create your first flag](phoenix-integration-spine.md#6-create-your-first-flag-lifecycle-required)
> in the spine.

> **Evaluating first?** See the [Adoption Lab **At a glance**](adoption-lab.md#at-a-glance)
> section (FleetDesk) to run Rulestead with realistic seeds and operator screens before
> installing into your app. Use `docker compose up --build` or `scripts/demo/proof.sh`.

## 3. Gate a code path

For the ordered Plug → snapshot runtime path, follow the
[Phoenix Integration Spine](phoenix-integration-spine.md). Below is the
payload-first contract for tests and simulations.

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

Phoenix apps with the snapshot cache typically use `Rulestead.Runtime` and
`conn.assigns[:rulestead_context]` — see the
[Phoenix Integration Spine](phoenix-integration-spine.md) and
[evaluation.md](../flows/evaluation.md). Projection helpers on `Rulestead`
(`enabled?/2`, `get_variant/2`) accept **flag payload + context**, not a string
key on `%Plug.Conn{}`.

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
[rulestead_admin on HexDocs](https://hexdocs.pm/rulestead_admin).

## 5. Continue from here

- In scope / deferred surfaces: [Product Boundary](product-boundary.md)
- Common mistakes: [Footguns](../recipes/footguns.md)
- Product mental model: [User Flows and JTBD](user-flows-and-jtbd.md)
- Flag from birth to retirement: [../flows/flag-lifecycle.md](../flows/flag-lifecycle.md)
- Runtime usage: [../flows/evaluation.md](../flows/evaluation.md)
- Rules and precedence: [../flows/rulesets.md](../flows/rulesets.md)
- Explain and support workflows: [../flows/explainability.md](../flows/explainability.md)
- Testing and fake-backed helpers: [../recipes/testing.md](../recipes/testing.md)
- Adoption lab (evaluate before integrate): [Adoption Lab](adoption-lab.md)
- Runnable proof path: [FleetDesk demo (examples/demo)](https://github.com/szTheory/rulestead/tree/main/examples/demo)
