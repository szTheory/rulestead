# Oban Background Jobs

Rulestead's Oban seam is explicit and bounded. In `v0.1.0`, the supported job
story is:

- attach a serialized `%Rulestead.Context{}` when enqueueing
- restore that context inside the worker
- evaluate through the normal runtime APIs

There is no hidden process-dictionary propagation and no raw job payload magic.

## Configure the middleware seam

The generated host config wires Oban middleware like this:

```elixir
config :rulestead, :host,
  oban: [
    enabled: true,
    context_key: "rulestead_context",
    middlewares: [{Rulestead.Oban.Middleware, []}]
  ]
```

That keeps the context key and middleware list explicit in host configuration.

## Attach context when enqueueing

When a request or LiveView action enqueues work, pass the current context
deliberately:

```elixir
job =
  %Oban.Job{args: %{"task" => "sync"}}
  |> Rulestead.Oban.Middleware.attach(
    context: %{
      targeting_key: "user-123",
      environment: "prod",
      request_id: "req_123"
    }
  )
```

`Rulestead.Oban.Middleware.attach/2` requires `:context` and serializes only
the bounded fields that the Oban seam supports.

## Restore context in the worker

Use the worker helper to rebuild context from the serialized payload:

```elixir
defmodule MyApp.SyncWorker do
  use Rulestead.Oban.Worker

  def perform(%Oban.Job{} = job) do
    context = rulestead_context(job)

    Rulestead.Runtime.enabled?("prod", "sync-enabled", context)
  end
end
```

If you prefer, call `Rulestead.Oban.context_from_job/1` directly. The contract
is the same: restore only the bounded serialized payload, not arbitrary process
state.

## What gets serialized

The Oban seam keeps only bounded context fields such as:

- `actor`
- `targeting_key`
- `tenant_key`
- `environment`
- `attributes`
- `request_id`
- `session_id`
- `strict?`

Rulestead does not serialize raw `Plug.Conn`, LiveView socket, or arbitrary
application structs into job payloads.

## Keep evaluation in the worker explicit

Inside the worker, evaluate flags the same way application code does elsewhere:

```elixir
context = rulestead_context(job)
{:ok, enabled?} = Rulestead.Runtime.enabled?(context.environment, "sync-enabled", context)
```

That preserves one runtime contract across HTTP, LiveView, and Oban.

## Use jobs for work, not for control-plane invention

This seam is for propagating evaluation context into background work. It is not
a promise of hosted rollout orchestration, governance queues, or hidden admin
mutation pipelines.

If your app wants those workflows, build them in your own layer and keep
Rulestead as the runtime decision engine plus bounded context carrier.
