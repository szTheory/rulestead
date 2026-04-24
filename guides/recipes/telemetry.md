# Telemetry

Use this recipe when you want to consume Rulestead's public event catalog from
your application. The event names and bounded metadata contract are described
in [Telemetry](/Users/jon/projects/rulestead/guides/flows/telemetry.md:1); this
guide shows how to attach handlers safely and route those signals into your own
metrics, logs, or alerts.

## What is stable in `v0.1.0`

Rulestead treats these as public contract material:

- event names under `[:rulestead, ...]`
- the shared bounded metadata spine
- the `Rulestead.Telemetry` helper wrapper

Your downstream handler implementation is app-owned.

## Prefer the safe wrapper

Use `Rulestead.Telemetry.attach_many/4` when you want handler failures isolated
from the runtime, store, or admin operations being observed:

```elixir
defmodule MyApp.RulesteadTelemetry do
  @events [
    [:rulestead, :eval, :decide, :stop],
    [:rulestead, :runtime, :cache, :stale_used],
    [:rulestead, :store, :write, :stop]
  ]

  def attach do
    Rulestead.Telemetry.attach_many(
      "my-app-rulestead",
      @events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, metadata, _config) do
    MyApp.Metrics.observe(event, measurements, metadata)
  end
end
```

If you call `:telemetry.attach/4` directly, normal Telemetry semantics apply.

## Start with stop and stale events

For most apps, the highest-signal events are:

- `[:rulestead, :eval, :decide, :stop]`
- `[:rulestead, :runtime, :cache, :stale_used]`
- `[:rulestead, :runtime, :cache, :miss]`
- `[:rulestead, :store, :write, :stop]`

That gives you evaluation rate, stale-serving visibility, cache misses, and
authored mutation outcomes without scraping internals.

## Route bounded metadata, not user payloads

Rulestead intentionally redacts raw traits, resolved values, and framework
structs from telemetry metadata.

Safe downstream patterns:

- increment counters by `flag_key`, `environment`, or `reason`
- record durations for `:stop` events
- alert on repeated `:stale_used`
- correlate with your own request IDs outside the Rulestead payload

Avoid trying to reconstruct user profiles from telemetry. The library does not
promise raw targeting attributes in emitted metadata.

## Example: record evaluation latency

```elixir
def handle_event([:rulestead, :eval, :decide, :stop], measurements, metadata, _config) do
  :ok =
    MyApp.StatsD.timing(
      "rulestead.eval.duration",
      measurements.duration,
      tags: [
        "flag:#{metadata.flag_key}",
        "environment:#{metadata.environment}",
        "reason:#{metadata.reason}"
      ]
    )
end
```

Stick to stable metadata keys such as `:flag_key`, `:environment`,
`:snapshot_version`, `:cache_age_ms`, and `:reason`.

## Watch runtime health without scraping internals

The runtime emits cache and snapshot events so you can observe health without
reaching into ETS tables or refresh processes directly.

Good operational uses:

- page on repeated `:stale_used` in production
- dashboard `cache_age_ms` by environment
- alert when refresh status degrades for too long

Bad operational uses:

- reading private runtime process state
- depending on internal module names
- parsing exception text for control flow

## Keep handler registration explicit

Attach handlers in your app startup path or supervision tree. Rulestead does
not auto-register global subscribers for you, and that boundary is deliberate.

## OpenTelemetry bridge policy

If your app already bridges `:telemetry` into OpenTelemetry or another metrics
stack, wire that in your application layer. `v0.1.0` does not require an
OpenTelemetry dependency and does not ship a hosted observability control
plane.
