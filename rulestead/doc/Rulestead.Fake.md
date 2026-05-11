# `Rulestead.Fake`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/fake.ex#L1)

Contract-faithful in-memory store adapter for tests.

The fake reuses the same command structs, error taxonomy, and ruleset
validation semantics as the real store contract. Test-only reset, clock, and
inspection helpers live in `Rulestead.Fake.Control`.

# `state`

```elixir
@type state() :: %{
  now: DateTime.t(),
  environments: %{required(String.t()) =&gt; map()},
  audiences: %{required(String.t()) =&gt; map()},
  flags: %{required(String.t()) =&gt; map()},
  audit_events: [map()],
  snapshots: %{required(String.t()) =&gt; %{required(pos_integer()) =&gt; map()}},
  snapshot_reads_connected?: boolean()
}
```

# `child_spec`

```elixir
@spec child_spec(keyword()) :: Supervisor.child_spec()
```

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `start_link`

```elixir
@spec start_link(keyword()) :: GenServer.on_start()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
