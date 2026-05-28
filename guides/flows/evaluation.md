# Evaluation

Rulestead evaluates an authored flag payload against an explicit
`%Rulestead.Context{}`. The runtime call is pure from the caller's
perspective: no hidden store lookup, no process-dictionary context, and no
surprise framework structs crossing the boundary.

## Core Calls

- `Rulestead.evaluate(flag_payload, context, opts \\ [])`
- `Rulestead.enabled?(flag_payload, context)`
- `Rulestead.get_value(flag_payload, context, default)`
- `Rulestead.get_variant(flag_payload, context)`
- `Rulestead.explain(flag_payload, context)`

Lifecycle posture is adjacent to these calls, not part of them. Owner truth is
host-owned, lifecycle guidance is advisory, and lifecycle review does not
change hot-path evaluation semantics.

Each call accepts the in-memory authored flag payload first and the evaluation
context second. `context` may already be a `%Rulestead.Context{}` or any
map/keyword input that `Rulestead.Context.new/1` can normalize.

## Build Context Explicitly

Use `Rulestead.Context.new/1` when you are outside Phoenix helpers or when you
want to see exactly what the evaluator receives:

```elixir
context =
  Rulestead.Context.new(
    actor: %{id: "user_123"},
    targeting_key: "user_123",
    environment: "prod",
    attributes: %{
      country: "US",
      plan: "pro"
    }
  )
```

`%Rulestead.Context{}` carries bounded fields only:

- `actor`
- `targeting_key`
- `tenant_key`
- `environment`
- `attributes`
- `request_id`
- `session_id`
- `strict?`

If you are entering from Plug, LiveView, or Oban, build the same context
through the host seams documented in
[Context Propagation](../recipes/context-propagation.md).

## Read The Result

`Rulestead.evaluate/3` returns `{:ok, %Rulestead.Result{}}` or
`{:error, %Rulestead.Error{}}`.

The stable result fields are:

- `value`
- `enabled?`
- `variant`
- `reason`
- `matched_rule`
- `flag_key`
- `flag_version`
- `cache_age_ms`
- `debug_trace`

Typical usage:

```elixir
with {:ok, result} <- Rulestead.evaluate(flag_payload, context) do
  case result do
    %{enabled?: true, variant: "treatment"} -> :show_new_checkout
    %{enabled?: true} -> :show_enabled_default
    _result -> :show_old_checkout
  end
end
```

Projection helpers save boilerplate when you only need one piece:

```elixir
{:ok, enabled?} = Rulestead.enabled?(flag_payload, context)
{:ok, value} = Rulestead.get_value(flag_payload, context, %{timeout_ms: 500})
{:ok, variant} = Rulestead.get_variant(flag_payload, context)
{:ok, explanation} = Rulestead.explain(flag_payload, context)
```

## Ordered Rules, First Match Wins

Evaluation walks rules in authored order. The first matching rule decides the
result. If no rule matches, the flag falls back to its default value.

That model is intentional:

- rule order is part of the authored contract
- the evaluator never merges multiple matching rules
- the explanation path can point to one matched rule or to the default path

When you design rulesets, put broad defaults later and the most specific rules
earlier. The deeper authoring guidance is in [Rulesets](rulesets.md).

## Sticky Rollouts Need A Targeting Key

Percentage and variant rollouts stay stable by hashing the flag, rule, salt,
and `targeting_key`. That means the context must carry a targeting key when the
rule needs stickiness.

In permissive mode, a missing targeting key yields a bounded warning and the
result falls back safely. In strict mode, the evaluator returns a typed error:

```elixir
context = Rulestead.Context.new(strict?: true, environment: "prod")

{:error, error} = Rulestead.evaluate(flag_payload, context)
error.type
#=> :missing_targeting_key
```

## Pure Evaluation Versus Runtime Lookup

Use the payload-first calls in this guide when:

- you already have the authored flag payload
- you want pure evaluation in tests
- you are simulating or inspecting one payload in isolation

Use the keyed runtime layer when you want the local snapshot cache to look up
the flag by environment and key.

Those runtime calls are what mounted admin workflows use under the hood. They
remain within the shipped public package boundary; they do not expose admin UI
internals.

### Runtime keyed lookup (`Rulestead.Runtime`)

When your app runs the snapshot cache (typical Phoenix path), call
`Rulestead.Runtime` with an **environment key**, **flag key**, and
**context** — not a flag payload string on `%Plug.Conn{}`:

| API | Arity | Use when |
|-----|-------|----------|
| `Rulestead.Runtime.evaluate/3` | 3 | Full `{:ok, %Rulestead.Result{}}` from cache |
| `Rulestead.Runtime.enabled?/3` | 3 | Boolean gate only |
| `Rulestead.Runtime.get_variant/3` | 3 | Variant string only |
| `Rulestead.Runtime.get_value/4` | 4 | Value with default when unset |
| `Rulestead.Runtime.explain/3` | 3 | Human-readable trace from cache |

`context` may be `%Rulestead.Context{}` or any map/keyword that
`Rulestead.Context.new/1` can normalize — often
`conn.assigns[:rulestead_context]` after `plug Rulestead.Plug`.

Example:

```elixir
context =
  Rulestead.Context.new(
    environment: "production",
    targeting_key: "user-123",
    attributes: %{plan: :pro}
  )

{:ok, enabled?} =
  Rulestead.Runtime.enabled?("production", "checkout_v2", context)
```

Root-module projection helpers (`Rulestead.enabled?/2`, `get_variant/2`, and
so on) take **(flag_payload, context)** — see
[Footguns](../recipes/footguns.md). For Plug → assigns → first eval, follow the
[Phoenix Integration Spine](../introduction/phoenix-integration-spine.md).

## Lifecycle Boundary

Keep this boundary explicit:

- owner truth is host-owned metadata
- lifecycle guidance is advisory operator support
- archive readiness does not affect evaluation
- cleanup review does not change the evaluator's rule order, bucket math, or
  result semantics

That means a flag can be under lifecycle review while `Rulestead.evaluate/3`
continues to behave exactly the same for a given payload and context. Lifecycle
docs should help operators decide what to do next; they should not change the
runtime contract.

## Common Pattern

For host apps, the common shape is:

1. Normalize request or job input into `%Rulestead.Context{}`.
2. Fetch or receive the authored flag payload.
3. Call `Rulestead.evaluate/3` or a projection helper.
4. Use `Rulestead.explain/2` when support or incident response needs a human
   trace.

Start there before building rollout or operator workflows.
