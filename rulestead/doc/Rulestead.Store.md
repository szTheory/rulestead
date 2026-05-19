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

# `apply_manifest_import`

```elixir
@callback apply_manifest_import(Rulestead.Store.Command.ApplyManifestImport.t()) ::
  result(map())
```

# `apply_promotion`

```elixir
@callback apply_promotion(Rulestead.Store.Command.ApplyPromotion.t()) :: result(map())
```

# `approve_change_request`

```elixir
@callback approve_change_request(Rulestead.Store.Command.ApproveChangeRequest.t()) ::
  result(map())
```

# `archive_flag`

```elixir
@callback archive_flag(Rulestead.Store.Command.ArchiveFlag.t()) :: result(map())
```

# `cancel_change_request`

```elixir
@callback cancel_change_request(Rulestead.Store.Command.CancelChangeRequest.t()) ::
  result(map())
```

# `cancel_scheduled_execution`

```elixir
@callback cancel_scheduled_execution(Rulestead.Store.Command.CancelScheduledExecution.t()) ::
  result(map())
```

# `compare_environments`

```elixir
@callback compare_environments(Rulestead.Store.Command.CompareEnvironments.t()) ::
  result(map())
```

# `create_flag`

```elixir
@callback create_flag(Rulestead.Store.Command.CreateFlag.t()) :: result(map())
```

# `create_webhook_destination`

```elixir
@callback create_webhook_destination(Rulestead.Store.Command.CreateWebhookDestination.t()) ::
  result(map())
```

# `engage_kill_switch`

```elixir
@callback engage_kill_switch(Rulestead.Store.Command.EngageKillSwitch.t()) ::
  result(map())
```

# `execute_change_request`

```elixir
@callback execute_change_request(Rulestead.Store.Command.ExecuteChangeRequest.t()) ::
  result(map())
```

# `execute_scheduled_execution`

```elixir
@callback execute_scheduled_execution(
  Rulestead.Store.Command.ExecuteScheduledExecution.t()
) ::
  result(map())
```

# `fetch_change_request`

```elixir
@callback fetch_change_request(Rulestead.Store.Command.FetchChangeRequest.t()) ::
  result(map())
```

# `fetch_flag`

```elixir
@callback fetch_flag(Rulestead.Store.Command.FetchFlag.t()) :: result(map())
```

# `fetch_scheduled_execution`

```elixir
@callback fetch_scheduled_execution(Rulestead.Store.Command.FetchScheduledExecution.t()) ::
  result(map())
```

# `fetch_snapshot`

```elixir
@callback fetch_snapshot(Rulestead.Store.Command.FetchSnapshot.t()) :: result(map())
```

# `fetch_webhook_destination`

```elixir
@callback fetch_webhook_destination(Rulestead.Store.Command.FetchWebhookDestination.t()) ::
  result(map())
```

# `fetch_webhook_record`

```elixir
@callback fetch_webhook_record(Rulestead.Store.Command.FetchWebhookRecord.t()) ::
  result(map())
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

# `list_change_requests`

```elixir
@callback list_change_requests(Rulestead.Store.Command.ListChangeRequests.t()) ::
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

# `list_scheduled_executions`

```elixir
@callback list_scheduled_executions(Rulestead.Store.Command.ListScheduledExecutions.t()) ::
  result(Rulestead.Store.Command.Page.t(map()))
```

# `list_webhook_deliveries`

```elixir
@callback list_webhook_deliveries(Rulestead.Store.Command.ListWebhookDeliveries.t()) ::
  result(Rulestead.Store.Command.Page.t(map()))
```

# `list_webhook_destinations`

```elixir
@callback list_webhook_destinations(Rulestead.Store.Command.ListWebhookDestinations.t()) ::
  result(Rulestead.Store.Command.Page.t(map()))
```

# `list_webhook_records`

```elixir
@callback list_webhook_records(Rulestead.Store.Command.ListWebhookRecords.t()) ::
  result(Rulestead.Store.Command.Page.t(map()))
```

# `preview_manifest_import`

```elixir
@callback preview_manifest_import(Rulestead.Store.Command.PreviewManifestImport.t()) ::
  result(map())
```

# `publish_ruleset`

```elixir
@callback publish_ruleset(Rulestead.Store.Command.PublishRuleset.t()) :: result(map())
```

# `receive_inbound_webhook`

```elixir
@callback receive_inbound_webhook(Rulestead.Store.Command.ReceiveInboundWebhook.t()) ::
  result(map())
```

# `record_evaluation`

```elixir
@callback record_evaluation(Rulestead.Store.Command.RecordEvaluation.t()) :: result(map())
```

# `reject_change_request`

```elixir
@callback reject_change_request(Rulestead.Store.Command.RejectChangeRequest.t()) ::
  result(map())
```

# `release_kill_switch`

```elixir
@callback release_kill_switch(Rulestead.Store.Command.ReleaseKillSwitch.t()) ::
  result(map())
```

# `requeue_scheduled_execution`

```elixir
@callback requeue_scheduled_execution(
  Rulestead.Store.Command.RequeueScheduledExecution.t()
) ::
  result(map())
```

# `retry_webhook_delivery`

```elixir
@callback retry_webhook_delivery(Rulestead.Store.Command.RetryWebhookDelivery.t()) ::
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

# `schedule_change_request`

```elixir
@callback schedule_change_request(Rulestead.Store.Command.ScheduleChangeRequest.t()) ::
  result(map())
```

# `schedule_governed_action`

```elixir
@callback schedule_governed_action(Rulestead.Store.Command.ScheduleGovernedAction.t()) ::
  result(map())
```

# `submit_change_request`

```elixir
@callback submit_change_request(Rulestead.Store.Command.SubmitChangeRequest.t()) ::
  result(map())
```

# `update_flag`

```elixir
@callback update_flag(Rulestead.Store.Command.UpdateFlag.t()) :: result(map())
```

# `update_webhook_destination`

```elixir
@callback update_webhook_destination(Rulestead.Store.Command.UpdateWebhookDestination.t()) ::
  result(map())
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
