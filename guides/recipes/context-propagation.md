# Context Propagation

Rulestead keeps context propagation explicit.

`%Rulestead.Context{}` is built at the host boundary, passed forward intentionally, and restored only from bounded serialized fields. There is no ambient process-dictionary lookup, no hidden cross-process mutation, and no raw Phoenix or Oban structs in telemetry or job payloads.

## Plug to Phoenix

Use `Rulestead.Plug` in the request pipeline to assign a normalized context onto the conn:

```elixir
plug Rulestead.Plug,
  actor: {:assign, :current_user},
  environment: "prod",
  request_id: {:header, "x-request-id"},
  session_id: {:session, "session_id"},
  targeting_key_sources: [
    {:session, "targeting_key"},
    {:cookie, "rulestead_targeting_key"},
    {:header, "x-rulestead-targeting-key"}
  ]
```

The plug writes only `conn.assigns[:rulestead_context]`.

If you need the context directly, call `Rulestead.Phoenix.context_from_conn/2`
with the same explicit sources. The contract is "project a bounded context from
request data", not "make the conn itself globally available."

## Phoenix to LiveView

Pass the bounded values you need during mount, then rebuild the context from socket assigns and explicit session data:

```elixir
def mount(_params, session, socket) do
  socket =
    assign(socket,
      rulestead_context: socket.assigns[:rulestead_context],
      current_user: socket.assigns[:current_user]
    )

  {:ok,
   Rulestead.LiveView.assign_flags(
     socket,
     %{checkout_enabled: "checkout-redesign"},
     session: session
   )}
end
```

`Rulestead.LiveView.assign_flags/3` resolves flags through the keyed runtime
layer only. It does not read the store, runtime cache internals, or the pure
payload-first evaluator directly.

If you only need to carry context without assigning flags yet, use
`Rulestead.LiveView.context_from_socket/2` and pass the resulting
`%Rulestead.Context{}` onward explicitly.

## LiveView or Request to Oban

Serialize the current context explicitly when enqueueing a job:

```elixir
job =
  %Oban.Job{args: %{"task" => "sync"}}
  |> Rulestead.Oban.Middleware.attach(context: socket.assigns.rulestead_context)
```

Inside a worker:

```elixir
defmodule MyApp.SyncWorker do
  use Rulestead.Oban.Worker
end

context = MyApp.SyncWorker.rulestead_context(job)
```

The Oban seam serializes only bounded context fields and restores them with
`Rulestead.Oban.context_from_job/1`.

## What "bounded" means

The supported propagation payload is limited to context fields such as:

- `actor`
- `targeting_key`
- `tenant_key`
- `environment`
- `attributes`
- `request_id`
- `session_id`
- `strict?`

That keeps propagation auditable and keeps framework structs, socket state, and
arbitrary request baggage out of telemetry and job payloads.

## Supported Chain

The supported propagation path is:

1. Build or assign `%Rulestead.Context{}` from request input with `Rulestead.Plug` or `Rulestead.Phoenix.context_from_conn/2`.
2. Rebuild or reuse that context in LiveView with `Rulestead.LiveView.context_from_socket/2`.
3. Serialize that context into jobs with `Rulestead.Oban.Middleware.attach/2`.
4. Restore it in workers with `use Rulestead.Oban.Worker`.

Every step is visible in application code. That is the point.

## Explicitly Unsupported

- Hidden process-dictionary propagation
- Reading context from unrelated process state
- Serializing raw Plug.Conn, Phoenix.LiveView.Socket, or Oban job structs into telemetry or job payloads
- Bypassing the keyed runtime layer from LiveView helpers
- Reconstructing context from private runtime cache or store internals
