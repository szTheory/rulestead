# `Rulestead.Store`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/store.ex#L1)

Key-first authoring store behavior for the Rulestead public API.

The contract is semantic and domain-oriented rather than CRUD-oriented.
Implementations must normalize misses into `{:error, %Rulestead.Error{}}`
and may not return `nil` for not-found cases.

# `result`

```elixir
@type result(value) :: {:ok, value} | {:error, Rulestead.Error.t()}
```

# `archive_flag`

```elixir
@callback archive_flag(Rulestead.Store.Command.ArchiveFlag.t()) :: result(map())
```

# `create_flag`

```elixir
@callback create_flag(Rulestead.Store.Command.CreateFlag.t()) :: result(map())
```

# `engage_kill_switch`

```elixir
@callback engage_kill_switch(Rulestead.Store.Command.EngageKillSwitch.t()) ::
  result(map())
```

# `fetch_flag`

```elixir
@callback fetch_flag(Rulestead.Store.Command.FetchFlag.t()) :: result(map())
```

# `fetch_snapshot`

```elixir
@callback fetch_snapshot(Rulestead.Store.Command.FetchSnapshot.t()) :: result(map())
```

# `list_audiences`

```elixir
@callback list_audiences(Rulestead.Store.Command.ListAudiences.t()) :: result([map()])
```

# `list_audit_events`

```elixir
@callback list_audit_events(Rulestead.Store.Command.ListAuditEvents.t()) ::
  result(Rulestead.Store.Command.Page.t(map()))
```

# `list_environments`

```elixir
@callback list_environments(Rulestead.Store.Command.ListEnvironments.t()) ::
  result([map()])
```

# `list_flags`

```elixir
@callback list_flags(Rulestead.Store.Command.ListFlags.t()) ::
  result(Rulestead.Store.Command.Page.t(map()))
```

# `publish_ruleset`

```elixir
@callback publish_ruleset(Rulestead.Store.Command.PublishRuleset.t()) :: result(map())
```

# `record_evaluation`

```elixir
@callback record_evaluation(Rulestead.Store.Command.RecordEvaluation.t()) :: result(map())
```

# `release_kill_switch`

```elixir
@callback release_kill_switch(Rulestead.Store.Command.ReleaseKillSwitch.t()) ::
  result(map())
```

# `rollback_audit_event`

```elixir
@callback rollback_audit_event(Rulestead.Store.Command.RollbackAuditEvent.t()) ::
  result(map())
```

# `save_draft_ruleset`

```elixir
@callback save_draft_ruleset(Rulestead.Store.Command.SaveDraftRuleset.t()) ::
  result(map())
```

# `update_flag`

```elixir
@callback update_flag(Rulestead.Store.Command.UpdateFlag.t()) :: result(map())
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
