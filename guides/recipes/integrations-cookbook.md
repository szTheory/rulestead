# Integrations Cookbook

This cookbook gives Stripe-tier adopter teams copy-paste-grade integration
paths for the most common jobs-to-be-done. Every recipe follows the same fixed
template — **Goal → For → Prerequisites → Steps → Verification → Gotchas →
Related** — and uses only supported 1.x public seams from
[API Stability](../api_stability.md). Where a job touches a host
responsibility, the recipe says so plainly in an honest boundary line so you
integrate through stable seams instead of internals.

Each recipe maps to a named persona and flow from
[User Flows & JTBD](../introduction/user-flows-and-jtbd.md). Version strings are
`1.x` / `~> 1.0` throughout.

## Gate a Stripe-tier audience

### Goal

Roll out a feature to your premium accounts by targeting a Stripe-derived
`tier` attribute, and preview the bounded impact before you apply the change.

### For

The **Tech Lead** working **Flow 2: Target The Right Audience** — moving a flag
from a boolean convenience to a release control surface ("only for premium
accounts?").

### Prerequisites

- Rulestead installed and migrated (`mix rulestead.install`, `mix ecto.migrate`).
- A host path that maps a Stripe customer/subscription to a `tier` string
  (for example `"pro"`, `"team"`, `"enterprise"`) — typically your existing
  Stripe webhook handler.
- An admin policy wired so the acting operator may author audience mutations.

### Steps

1. Carry the tier into evaluation as a bounded context attribute. The host
   resolves the tier; Rulestead just reads it:

   ```elixir
   context =
     Rulestead.Context.new(%{
       targeting_key: "user-123",
       environment: "prod",
       attributes: %{"tier" => MyApp.Billing.tier_for(current_user)}
     })
   ```

2. Before changing the audience, preview the bounded impact with
   `Rulestead.preview_audience_impact/3`. The third argument carries options
   such as the environment scope:

   ```elixir
   {:ok, preview} =
     Rulestead.preview_audience_impact("premium-accounts", :update, environment: "prod")
   ```

3. Apply the mutation through the root facade's map form,
   `Rulestead.apply_audience_mutation/2`. Pass the attributes as a map and the
   options (including the fresh preview evidence your policy requires) as the
   second argument:

   ```elixir
   {:ok, result} =
     Rulestead.apply_audience_mutation(
       %{audience_key: "premium-accounts", operation: :update, rules: rules},
       environment: "prod", preview: preview
     )
   ```

### Verification

- `Rulestead.preview_audience_impact/3` returns an `:ok` preview map whose
  fields declare the basis of the estimate and its uncertainty.
- A premium-tier `%Rulestead.Context{}` evaluates to the gated path, while a
  free-tier context falls through to the safe default.

### Gotchas

- **Boundary:** the host owns the Stripe webhook and the population truth.
  Rulestead previews **declare basis and uncertainty** — they are bounded
  estimates, **not an authoritative affected-user count**. Treat preview
  evidence as evidence, not a census. See
  [Product Boundary](../introduction/product-boundary.md) ("Host always owns →
  Population truth") and [Footguns](footguns.md).
- Keep the `tier` attribute stable across requests for the same actor so
  bucketing stays deterministic.

### Related

- [User Flows & JTBD](../introduction/user-flows-and-jtbd.md)
- [Product Boundary](../introduction/product-boundary.md)
- [Footguns](footguns.md)

## Stream eval telemetry to Segment

### Goal

Forward Rulestead's evaluation decisions into Segment (or any analytics client)
so support and on-call engineers can correlate "what did this user see?" with
your product timeline.

### For

The **Support Engineer** and **SRE / On-call Engineer** working **Flow 5:
Explain One User's Reality** — quoting evidence for one actor without re-running
the incident in their head.

### Prerequisites

- A Segment (or equivalent) client already wired in your application layer.
- A handler module attached during application startup or in your supervision
  tree.

### Steps

1. Attach a handler with the safe wrapper `Rulestead.Telemetry.attach_many/4`,
   subscribing to the public decision event:

   ```elixir
   defmodule MyApp.RulesteadSegment do
     @events [[:rulestead, :eval, :decide, :stop]]

     def attach do
       Rulestead.Telemetry.attach_many(
         "my-app-rulestead-segment",
         @events,
         &__MODULE__.handle_event/4,
         nil
       )
     end

     def handle_event([:rulestead, :eval, :decide, :stop], _measurements, metadata, _config) do
       MyApp.Segment.track("flag_evaluated", %{
         flag_key: metadata.flag_key,
         environment: metadata.environment,
         reason: metadata.reason
       })
     end
   end
   ```

2. Route only the bounded, stable metadata keys (`:flag_key`, `:environment`,
   `:reason`, and friends). Correlate with your own request IDs from outside the
   Rulestead payload.

### Verification

- After attaching, each evaluation emits a `[:rulestead, :eval, :decide, :stop]`
  event your handler observes; a corresponding `flag_evaluated` event appears in
  Segment.
- The forwarded payload contains only documented metadata keys — no raw actor
  attributes.

### Gotchas

- **Boundary:** telemetry metadata is **redacted by default**. Raw actor
  payloads and targeting attributes are **not** part of the contract, so you
  cannot reconstruct user profiles from these events. The host owns the Segment
  client and any enrichment. See [Telemetry](telemetry.md) and
  [API Stability](../api_stability.md).
- Keep handler failures isolated — that is exactly what
  `Rulestead.Telemetry.attach_many/4` buys you over a raw `:telemetry.attach/4`.

### Related

- [Telemetry](telemetry.md)
- [User Flows & JTBD](../introduction/user-flows-and-jtbd.md)
- [API Stability](../api_stability.md)

## Promote a change from staging to prod, reviewably

### Goal

Move a configuration change from staging into a protected production
environment as a **governed, reviewable apply** that leaves an audit trail —
not an ad hoc SSH-and-pray mutation.

### For

The **Operator** and **Tech Lead** working **Flow 3: Preview Before You Regret
It** — making a reversible, reviewable change through an explicit approval path.

### Prerequisites

- A `Rulestead.Admin.Policy` implementation wired by the host, with production
  marked as a protected environment.
- A telemetry handler attached for the admin mutation event (see the Segment
  recipe for the attach pattern).

### Steps

1. Let the policy decide whether the apply needs review. The governance
   callback `Rulestead.Admin.Policy.change_request_required?/4` is the public
   seam — when it returns `true` for a protected environment, the apply is
   routed through review rather than executed immediately.

2. Drive the promotion by outcome. The governed apply either lands directly or
   is held for an approval path according to your policy; in protected
   environments the system favors a reviewable change over an immediate
   mutation. You do not need to reach for internal command structs to get this
   behavior.

3. Observe the outcome through the public admin mutation event and the audit
   log:

   ```elixir
   Rulestead.Telemetry.attach_many(
     "my-app-rulestead-mutations",
     [[:rulestead, :admin, :mutation, :stop]],
     &MyApp.RulesteadAudit.handle_event/4,
     nil
   )

   {:ok, events} = Rulestead.list_audit_events(environment: "prod")
   ```

### Verification

- A protected-environment apply for which
  `Rulestead.Admin.Policy.change_request_required?/4` returns `true` surfaces as
  a held / reviewable change, not an immediate write.
- The `[:rulestead, :admin, :mutation, :stop]` event fires for the apply, and
  `Rulestead.list_audit_events/1` returns a row describing who changed what.

### Gotchas

- **Boundary:** Rulestead provides **governed apply plus Promotion / GitOps** —
  it is **not a hosted control plane** and does not authenticate actors.
  Protected-environment gating is **host-policy-driven** through the
  `Rulestead.Admin.Policy` behaviour. See
  [Product Boundary](../introduction/product-boundary.md) ("Host always owns →
  Identity and authorization").
- Frame promotion by its outcome — a reviewable, audited change — rather than by
  any one internal entry point. The stable surface here is the policy callback,
  the mutation telemetry event, and the audit log.

### Related

- [Product Boundary](../introduction/product-boundary.md)
- [User Flows & JTBD](../introduction/user-flows-and-jtbd.md)
- [Telemetry](telemetry.md)

## Gate an Oban background job

### Goal

Gate a background job behind a flag, carrying explicit evaluation context from
the enqueue site into the worker so the decision is deterministic and bounded.

### For

The **App Developer** working **Flow 1: Ship Behind A Flag** — needing a safe
seam in application code without building a control plane first.

### Prerequisites

- Oban configured in your application.
- The Rulestead Oban middleware wired in host config.

### Steps

1. Wire the middleware seam in host config:

   ```elixir
   config :rulestead, :host,
     oban: [
       enabled: true,
       context_key: "rulestead_context",
       middlewares: [{Rulestead.Oban.Middleware, []}]
     ]
   ```

2. Attach a bounded context when enqueueing with
   `Rulestead.Oban.Middleware.attach/2`:

   ```elixir
   job =
     %Oban.Job{args: %{"task" => "sync"}}
     |> Rulestead.Oban.Middleware.attach(
       context: %{targeting_key: "user-123", environment: "prod"}
     )
   ```

3. Restore context in the worker via `use Rulestead.Oban.Worker` and gate the
   work with `Rulestead.Runtime.enabled?/3`:

   ```elixir
   defmodule MyApp.SyncWorker do
     use Rulestead.Oban.Worker

     def perform(%Oban.Job{} = job) do
       context = rulestead_context(job)

       case Rulestead.Runtime.enabled?(context.environment, "sync-enabled", context) do
         {:ok, true} -> MyApp.Sync.run(job)
         _ -> :ok
       end
     end
   end
   ```

### Verification

- `rulestead_context/1` rebuilds a `%Rulestead.Context{}` from the bounded
  serialized payload — not from arbitrary process state.
- `Rulestead.Runtime.enabled?/3` returns a deterministic `{:ok, boolean}` inside
  the worker for the same context.

### Gotchas

- **Boundary:** the Oban seam carries **bounded context only**. It is **not** a
  promise of hosted rollout orchestration, governance queues, or hidden admin
  mutation pipelines. If you want those workflows, build them in your own layer
  and keep Rulestead as the runtime decision engine plus context carrier. See
  [Oban Background Jobs](oban-background-jobs.md).
- Only bounded fields (`targeting_key`, `environment`, `attributes`, and the
  like) are serialized — never a raw `Plug.Conn` or LiveView socket.

### Related

- [Oban Background Jobs](oban-background-jobs.md)
- [User Flows & JTBD](../introduction/user-flows-and-jtbd.md)
- [Product Boundary](../introduction/product-boundary.md)
