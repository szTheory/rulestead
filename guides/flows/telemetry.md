# Telemetry

Phase 4 locks Rulestead telemetry as a versioned public API. The event names in
this guide are additive-only for the rest of `1.x`.

## Principles

- All events live under `[:rulestead, ...]`.
- The shared metadata spine is bounded and redacted at emission time.
- Runtime evaluation stays DB-free on the hot path once a snapshot is applied.
- Handler failures must not crash the instrumented operation when attached
  through `Rulestead.Telemetry.attach_many/4`.

## Event Catalog

### Evaluation

- `[:rulestead, :eval, :decide, :start]`
- `[:rulestead, :eval, :decide, :stop]`
- `[:rulestead, :eval, :decide, :exception]`

Emitted by the pure evaluator surface in `Rulestead.evaluate/3` and the keyed
runtime evaluation surface.

### Runtime Cache

- `[:rulestead, :runtime, :cache, :hit]`
- `[:rulestead, :runtime, :cache, :miss]`
- `[:rulestead, :runtime, :cache, :refresh]`
- `[:rulestead, :runtime, :cache, :stale_used]`

`cache:hit` and `cache:miss` describe ETS lookup outcomes. `cache:refresh`
marks refresh loop fetch/apply work. `cache:stale_used` is emitted when the
runtime serves a last-known-good snapshot while refresh status is stale.

### Runtime Snapshots

- `[:rulestead, :runtime, :snapshot, :published]`
- `[:rulestead, :runtime, :snapshot, :applied]`

`snapshot:published` is emitted when a store write publishes a new runtime
snapshot version. `snapshot:applied` is emitted when a node applies that
snapshot into ETS.

### Store Boundaries

- `[:rulestead, :store, :read, :start]`
- `[:rulestead, :store, :read, :stop]`
- `[:rulestead, :store, :read, :exception]`
- `[:rulestead, :store, :write, :start]`
- `[:rulestead, :store, :write, :stop]`
- `[:rulestead, :store, :write, :exception]`

These cover the public store facade plus the runtime refresh store fetch
boundary.

### Admin-Coarse Mutations

- `[:rulestead, :admin, :mutation, :start]`
- `[:rulestead, :admin, :mutation, :stop]`

These wrap the current Phase 4 public mutation verbs: save draft, publish
ruleset, and archive flag.

## Shared Metadata Spine

Handlers must tolerate missing optional keys and additive future keys. The
stable shared metadata keys are:

- `:flag_key`
- `:flag_type`
- `:environment`
- `:snapshot_version`
- `:cache_age_ms`
- `:reason`
- `:has_targeting_key?`
- `:matched_rule_count`

Domain-specific additions remain bounded. Today that includes keys like
`:operation`, `:source`, `:refresh_status`, and `:audit_action`.

## Redaction Rules

Telemetry metadata never includes:

- Raw attributes
- Raw resolved flag values
- Actor payloads
- Plug/Phoenix/Oban structs
- Secrets or arbitrary payload blobs

If a handler needs more context, derive it from the stable metadata or look it
up in your own system of record.

## Safe Handlers

Use `Rulestead.Telemetry.attach_many/4` to isolate handler failures from the
runtime, store, and admin operations they observe.

```elixir
Rulestead.Telemetry.attach_many(
  "my-rulestead-handlers",
  [
    [:rulestead, :eval, :decide, :stop],
    [:rulestead, :runtime, :cache, :stale_used]
  ],
  fn event, measurements, metadata, _config ->
    IO.inspect({event, measurements, metadata}, label: "rulestead")
  end,
  nil
)
```

Direct `:telemetry.attach/4` handlers still follow normal Telemetry semantics.
If you want handler isolation, use the Rulestead wrapper.
