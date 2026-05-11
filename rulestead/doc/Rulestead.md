# `Rulestead`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead.ex#L1)

Root public module for the `rulestead` package.

Phase 3 keeps the store-facing APIs from Phase 2 and adds the pure evaluator
over an explicit in-memory authored flag payload:

- store-facing calls return `{:ok, value} | {:error, %Rulestead.Error{}}`
- bang variants raise the same `%Rulestead.Error{}`
- evaluation helpers consume an authored flag payload first and explicit
  context second

# `archive_flag`

```elixir
@spec archive_flag(Rulestead.Store.Command.ArchiveFlag.t()) ::
  Rulestead.Store.result(map())
```

Archives a flag through the configured store adapter.

# `archive_flag!`

```elixir
@spec archive_flag!(Rulestead.Store.Command.ArchiveFlag.t()) :: map()
```

Bang variant of `archive_flag/1`.

# `create_flag`

```elixir
@spec create_flag(Rulestead.Store.Command.CreateFlag.t()) ::
  Rulestead.Store.result(map())
```

Creates a flag through the configured store adapter.

# `create_flag`

```elixir
@spec create_flag(
  map() | keyword(),
  keyword()
) :: Rulestead.Store.result(map())
```

Creates a flag from root-level attributes.

# `diagnostics`

```elixir
@spec diagnostics() :: map()
```

Returns bounded runtime diagnostics for the local node.

# `enabled?`

```elixir
@spec enabled?(map(), Rulestead.Context.t() | keyword() | map()) ::
  {:ok, boolean()} | {:error, Rulestead.Error.t()}
```

Returns the boolean enabled projection for an authored flag payload.

# `engage_kill_switch`

```elixir
@spec engage_kill_switch(Rulestead.Store.Command.EngageKillSwitch.t()) ::
  Rulestead.Store.result(map())
```

Engages a per-flag per-environment kill switch.

# `engage_kill_switch`

```elixir
@spec engage_kill_switch(String.t() | atom(), String.t() | atom(), map(), keyword()) ::
  Rulestead.Store.result(map())
```

# `evaluate`

```elixir
@spec evaluate(map(), Rulestead.Context.t() | keyword() | map(), keyword()) ::
  {:ok, Rulestead.Result.t()} | {:error, Rulestead.Error.t()}
```

Evaluates an authored in-memory flag payload against an explicit context.

# `evaluate!`

```elixir
@spec evaluate!(map(), Rulestead.Context.t() | keyword() | map(), keyword()) ::
  Rulestead.Result.t()
```

Bang variant of `evaluate/3`.

# `explain`

```elixir
@spec explain(map(), Rulestead.Context.t() | keyword() | map()) ::
  {:ok, String.t()} | {:error, Rulestead.Error.t()}
```

Returns a human-readable explanation derived from the evaluation trace.

# `explain_flag`

```elixir
@spec explain_flag(
  String.t() | atom(),
  String.t() | atom(),
  Rulestead.Context.t() | keyword() | map(),
  keyword()
) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

Admin-safe explain seam for one flag and environment.

# `fetch_flag`

```elixir
@spec fetch_flag(Rulestead.Store.Command.FetchFlag.t()) ::
  Rulestead.Store.result(map())
```

Fetches the authored flag state for a pre-built store command.

# `fetch_flag`

```elixir
@spec fetch_flag(String.t() | atom(), String.t() | atom(), keyword()) ::
  Rulestead.Store.result(map())
```

Fetches the authored flag state for a `flag_key` and `environment_key`.

# `fetch_flag!`

```elixir
@spec fetch_flag!(String.t() | atom(), String.t() | atom(), keyword()) :: map()
```

Bang variant of `fetch_flag/3`.

# `get_value`

```elixir
@spec get_value(map(), Rulestead.Context.t() | keyword() | map(), term()) ::
  {:ok, term()} | {:error, Rulestead.Error.t()}
```

Returns the projected value for an authored flag payload.

# `get_variant`

```elixir
@spec get_variant(map(), Rulestead.Context.t() | keyword() | map()) ::
  {:ok, String.t() | nil} | {:error, Rulestead.Error.t()}
```

Returns the assigned variant key for an authored flag payload.

# `list_audiences`

```elixir
@spec list_audiences() :: Rulestead.Store.result([map()])
```

Lists reusable audiences through the configured store adapter.

# `list_audiences`

```elixir
@spec list_audiences(keyword()) :: Rulestead.Store.result([map()])
@spec list_audiences(Rulestead.Store.Command.ListAudiences.t()) ::
  Rulestead.Store.result([map()])
```

# `list_audit_events`

```elixir
@spec list_audit_events(Rulestead.Store.Command.ListAuditEvents.t() | keyword()) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists redacted audit events for one flag or all flags.

# `list_environments`

```elixir
@spec list_environments() :: Rulestead.Store.result([map()])
```

Lists environments through the configured store adapter.

# `list_environments`

```elixir
@spec list_environments(keyword()) :: Rulestead.Store.result([map()])
@spec list_environments(Rulestead.Store.Command.ListEnvironments.t()) ::
  Rulestead.Store.result([map()])
```

# `list_flags`

```elixir
@spec list_flags() :: Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists flags through the configured store adapter.

Phase 2 keeps this as the shared list/search surface for store adapters.

# `list_flags`

```elixir
@spec list_flags(keyword()) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
@spec list_flags(Rulestead.Store.Command.ListFlags.t()) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

# `list_flags!`

```elixir
@spec list_flags!(Rulestead.Store.Command.ListFlags.t() | keyword()) ::
  Rulestead.Store.Command.Page.t(map())
```

Bang variant of `list_flags/0` and `list_flags/1`.

# `publish_ruleset`

```elixir
@spec publish_ruleset(Rulestead.Store.Command.PublishRuleset.t()) ::
  Rulestead.Store.result(map())
```

Publishes a ruleset version through the configured store adapter.

# `publish_ruleset!`

```elixir
@spec publish_ruleset!(Rulestead.Store.Command.PublishRuleset.t()) :: map()
```

Bang variant of `publish_ruleset/1`.

# `record_evaluation`

```elixir
@spec record_evaluation(Rulestead.Store.Command.RecordEvaluation.t()) ::
  Rulestead.Store.result(map())
```

Records bounded evaluation freshness for one flag/environment pair.

# `record_evaluation`

```elixir
@spec record_evaluation(String.t() | atom(), String.t() | atom(), DateTime.t()) ::
  Rulestead.Store.result(map())
```

Records bounded evaluation freshness using root-level arguments.

# `release_kill_switch`

```elixir
@spec release_kill_switch(Rulestead.Store.Command.ReleaseKillSwitch.t()) ::
  Rulestead.Store.result(map())
```

Releases a per-flag per-environment kill switch.

# `release_kill_switch`

```elixir
@spec release_kill_switch(String.t() | atom(), String.t() | atom(), map(), keyword()) ::
  Rulestead.Store.result(map())
```

# `rollback_audit_event`

```elixir
@spec rollback_audit_event(Rulestead.Store.Command.RollbackAuditEvent.t()) ::
  Rulestead.Store.result(map())
```

Writes a linked inverse action for a prior audit event.

# `rollback_audit_event`

```elixir
@spec rollback_audit_event(
  String.t(),
  keyword()
) :: Rulestead.Store.result(map())
```

# `save_draft_ruleset`

```elixir
@spec save_draft_ruleset(Rulestead.Store.Command.SaveDraftRuleset.t()) ::
  Rulestead.Store.result(map())
```

Saves a draft ruleset through the configured store adapter.

# `save_draft_ruleset!`

```elixir
@spec save_draft_ruleset!(Rulestead.Store.Command.SaveDraftRuleset.t()) :: map()
```

Bang variant of `save_draft_ruleset/1`.

# `simulate_flag`

```elixir
@spec simulate_flag(
  String.t() | atom(),
  String.t() | atom(),
  Rulestead.Context.t() | keyword() | map(),
  keyword()
) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

Admin-safe runtime simulation for one flag and environment.

# `update_flag`

```elixir
@spec update_flag(Rulestead.Store.Command.UpdateFlag.t()) ::
  Rulestead.Store.result(map())
```

Updates flag metadata through the configured store adapter.

# `update_flag`

```elixir
@spec update_flag(String.t() | atom(), map() | keyword(), keyword()) ::
  Rulestead.Store.result(map())
```

Updates a flag from root-level attributes.

# `version`

```elixir
@spec version() :: String.t()
```

Returns the package version.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
