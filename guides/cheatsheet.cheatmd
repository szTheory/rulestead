# Rulestead Cheatsheet

One-page reference for the locked `v0.1.0` package surface.

## Add Dependencies

```elixir
{:rulestead, "~> 0.1"},
{:rulestead_admin, "~> 0.1"}
```

## Install In A Host App

```bash
mix deps.get
mix rulestead.install --yes
mix ecto.migrate
```

## Mount The Admin Package

```elixir
import RulesteadAdmin.Router

scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

Required host session keys:

- `"current_actor"`
- `"rulestead_admin_environments"`
- `"rulestead_admin_last_env"`

Canonical operator environment selector:

```text
?env=dev
?env=staging
?env=prod
```

## Build Context

```elixir
context =
  Rulestead.Context.new(
    actor: %{id: "user_123"},
    targeting_key: "user_123",
    environment: "prod",
    attributes: %{country: "US", plan: "pro"}
  )
```

## Payload-First Evaluation

```elixir
{:ok, result} = Rulestead.evaluate(flag_payload, context)
{:ok, enabled?} = Rulestead.enabled?(flag_payload, context)
{:ok, value} = Rulestead.get_value(flag_payload, context, %{timeout_ms: 500})
{:ok, variant} = Rulestead.get_variant(flag_payload, context)
{:ok, explanation} = Rulestead.explain(flag_payload, context)
```

Result fields:

```elixir
%Rulestead.Result{
  value: value,
  enabled?: enabled?,
  variant: variant,
  reason: reason,
  matched_rule: matched_rule,
  flag_key: flag_key,
  flag_version: flag_version,
  cache_age_ms: cache_age_ms,
  debug_trace: debug_trace
}
```

## Admin-Safe Runtime Seams

```elixir
{:ok, fetched} = Rulestead.fetch_flag("checkout_v2", "prod")
{:ok, simulation} = Rulestead.simulate_flag("checkout_v2", "prod", context, actor: actor)
{:ok, explained} = Rulestead.explain_flag("checkout_v2", "prod", context, actor: actor)
diagnostics = Rulestead.diagnostics()
```

## LiveView And Host Helpers

```elixir
context = Rulestead.Phoenix.context_from_conn(conn)
context = Rulestead.LiveView.context_from_socket(socket, session: session)
socket = Rulestead.LiveView.assign_flags(socket, [:checkout_v2], session: session)
```

## Test Helpers

```elixir
import Rulestead.TestHelpers

with_flag "checkout_v2", true do
  ...
end

put_flag("pricing_copy", "treatment")
seed_bucket("pricing_exp", "user_123", "treatment")
clear_flags()
```

Telemetry-backed assertion:

```elixir
assert_flag_evaluated "checkout_v2" do
  Rulestead.enabled?(flag_payload, context)
end
```

## Stable Operator Paths

```text
/admin/flags
/admin/flags/new
/admin/flags/audit
/admin/flags/:key
/admin/flags/:key/edit
/admin/flags/:key/rules
/admin/flags/:key/simulate
/admin/flags/:key/rollouts
/admin/flags/:key/kill
/admin/flags/:key/timeline
```

## Policy Behaviour

```elixir
defmodule MyApp.RulesteadPolicy do
  @behaviour Rulestead.Admin.Policy

  @impl true
  def can?(actor, action, resource, environment_key) do
    ...
  end
end
```
