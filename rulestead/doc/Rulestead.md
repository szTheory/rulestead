# `Rulestead`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead.ex#L1)

Root public module for the `rulestead` package.

Phase 3 keeps the store-facing APIs from Phase 2 and adds the pure evaluator
over an explicit in-memory authored flag payload:

- store-facing calls return `{:ok, value} | {:error, %Rulestead.Error{}}`
- bang variants raise the same `%Rulestead.Error{}`
- evaluation helpers consume an authored flag payload first and explicit
  context second

# `apply_manifest_plan`

```elixir
@spec apply_manifest_plan(
  binary() | map(),
  keyword()
) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

Applies a previously generated manifest import plan artifact.

# `apply_promotion`

```elixir
@spec apply_promotion(Rulestead.Store.Command.ApplyPromotion.t()) ::
  Rulestead.Store.result(map())
```

Applies a bounded direct promotion bundle through compare revalidation and the configured store.

# `apply_promotion`

```elixir
@spec apply_promotion(
  map() | keyword(),
  keyword()
) :: Rulestead.Store.result(map())
```

Builds and applies a direct promotion bundle from root-level attributes.

# `apply_promotion_plan`

```elixir
@spec apply_promotion_plan(
  binary() | map(),
  keyword()
) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

Applies a previously generated promote plan artifact.

# `approve_change_request`

```elixir
@spec approve_change_request(Rulestead.Store.Command.ApproveChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Approves a governed change request through the configured store adapter.

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

# `authorize_change_request_approval`

```elixir
@spec authorize_change_request_approval(
  term(),
  term(),
  atom(),
  term(),
  String.t() | atom() | nil
) ::
  {:ok, Rulestead.Governance.ApprovalRequirement.t()}
  | {:error, Rulestead.Error.t(), Rulestead.Admin.Authorizer.audit_payload()}
```

Resolves whether an actor may approve a specific change request.

# `authorize_governed_action`

```elixir
@spec authorize_governed_action(term(), atom(), term(), String.t() | atom() | nil) ::
  {:ok, Rulestead.Governance.ApprovalRequirement.t()}
  | {:error, Rulestead.Error.t(), Rulestead.Admin.Authorizer.audit_payload()}
```

Resolves whether a governed action must go through a change request.

# `cancel_change_request`

```elixir
@spec cancel_change_request(Rulestead.Store.Command.CancelChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Cancels a governed change request through the configured store adapter.

# `cancel_scheduled_execution`

```elixir
@spec cancel_scheduled_execution(Rulestead.Store.Command.CancelScheduledExecution.t()) ::
  Rulestead.Store.result(map())
```

Cancels a scheduled execution through the configured store adapter.

# `compare_environments`

```elixir
@spec compare_environments(Rulestead.Store.Command.CompareEnvironments.t()) ::
  Rulestead.Store.result(map())
```

Compares authored source and target environment state for a pre-built compare command.

# `compare_environments`

```elixir
@spec compare_environments(String.t() | atom(), String.t() | atom(), keyword()) ::
  Rulestead.Store.result(map())
```

Compares authored source and target environment state for promotion preview flows.

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

# `create_webhook_destination`

```elixir
@spec create_webhook_destination(
  Rulestead.Store.Command.CreateWebhookDestination.t()
  | map()
  | keyword()
) :: Rulestead.Store.result(map())
```

Creates a new webhook destination.

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

# `execute_change_request`

```elixir
@spec execute_change_request(Rulestead.Store.Command.ExecuteChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Executes an approved governed change request through the configured store adapter.

# `execute_inbound_event`

```elixir
@spec execute_inbound_event(Rulestead.Webhooks.InboundEvent.t(), map()) ::
  Rulestead.Store.result(map())
```

Normalizes a verified inbound webhook event into the local governance path.

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

# `export_manifest`

```elixir
@spec export_manifest(
  String.t() | atom(),
  keyword()
) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

Exports a deterministic authored-state manifest for one environment.

# `fetch_change_request`

```elixir
@spec fetch_change_request(Rulestead.Store.Command.FetchChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Fetches one change request through the configured store adapter.

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

# `fetch_scheduled_execution`

```elixir
@spec fetch_scheduled_execution(Rulestead.Store.Command.FetchScheduledExecution.t()) ::
  Rulestead.Store.result(map())
```

Fetches one scheduled execution through the configured store adapter.

# `fetch_webhook_destination`

```elixir
@spec fetch_webhook_destination(
  Rulestead.Store.Command.FetchWebhookDestination.t() | String.t(),
  keyword()
) :: Rulestead.Store.result(map())
```

Fetches a single webhook destination by ID.

# `fetch_webhook_record`

```elixir
@spec fetch_webhook_record(
  String.t() | Rulestead.Store.Command.FetchWebhookRecord.t(),
  keyword()
) :: Rulestead.Store.result(map())
```

Fetches one webhook receipt through the configured store adapter.

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

# `import_manifest`

```elixir
@spec import_manifest(
  binary() | map(),
  keyword()
) :: {:ok, map()} | {:error, Rulestead.Error.t()}
```

Previews a manifest import as a saved apply plan artifact.

# `infrastructure_health`

```elixir
@spec infrastructure_health() :: map()
```

Returns the bounded infrastructure health snapshot for the local node.

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

# `list_change_requests`

```elixir
@spec list_change_requests(Rulestead.Store.Command.ListChangeRequests.t() | keyword()) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists change requests through the configured store adapter.

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

# `list_scheduled_executions`

```elixir
@spec list_scheduled_executions(
  Rulestead.Store.Command.ListScheduledExecutions.t()
  | keyword()
) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists scheduled executions through the configured store adapter.

# `list_webhook_deliveries`

```elixir
@spec list_webhook_deliveries(
  Rulestead.Store.Command.ListWebhookDeliveries.t()
  | keyword()
) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists webhook outbound deliveries.

# `list_webhook_destinations`

```elixir
@spec list_webhook_destinations(
  Rulestead.Store.Command.ListWebhookDestinations.t()
  | keyword()
) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists webhook destinations.

# `list_webhook_records`

```elixir
@spec list_webhook_records(Rulestead.Store.Command.ListWebhookRecords.t() | keyword()) ::
  Rulestead.Store.result(Rulestead.Store.Command.Page.t(map()))
```

Lists webhook receipts through the configured store adapter.

# `plan_promotion`

```elixir
@spec plan_promotion(String.t() | atom(), String.t() | atom(), keyword()) ::
  {:ok, map()} | {:error, Rulestead.Error.t()}
```

Builds a saved promote plan artifact from a live compare preview.

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

# `receive_inbound_webhook`

```elixir
@spec receive_inbound_webhook(Rulestead.Store.Command.ReceiveInboundWebhook.t()) ::
  Rulestead.Store.result(map())
```

Records an inbound webhook receipt through the configured store adapter.

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

# `reject_change_request`

```elixir
@spec reject_change_request(Rulestead.Store.Command.RejectChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Rejects a governed change request through the configured store adapter.

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

# `requeue_scheduled_execution`

```elixir
@spec requeue_scheduled_execution(
  Rulestead.Store.Command.RequeueScheduledExecution.t()
) ::
  Rulestead.Store.result(map())
```

Requeues a quarantined scheduled execution through the configured store adapter.

# `retry_webhook_delivery`

```elixir
@spec retry_webhook_delivery(
  Rulestead.Store.Command.RetryWebhookDelivery.t() | String.t(),
  keyword()
) :: Rulestead.Store.result(map())
```

Retries a failed webhook delivery.

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

# `schedule_change_request`

```elixir
@spec schedule_change_request(Rulestead.Store.Command.ScheduleChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Schedules an approved governed change request through the configured store adapter.

# `schedule_governed_action`

```elixir
@spec schedule_governed_action(Rulestead.Store.Command.ScheduleGovernedAction.t()) ::
  Rulestead.Store.result(map())
```

Schedules a narrowly allowed direct governed action through the configured store adapter.

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

# `submit_change_request`

```elixir
@spec submit_change_request(Rulestead.Store.Command.SubmitChangeRequest.t()) ::
  Rulestead.Store.result(map())
```

Submits a governed change request through the configured store adapter.

# `track`

```elixir
@spec track(Rulestead.Context.t() | map() | String.t(), String.t(), map()) :: :ok
```

Tracks a custom analytics event.

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

# `update_webhook_destination`

```elixir
@spec update_webhook_destination(
  Rulestead.Store.Command.UpdateWebhookDestination.t()
  | {String.t(), map() | keyword()}
) :: Rulestead.Store.result(map())
```

Updates an existing webhook destination.

# `update_webhook_destination`

# `version`

```elixir
@spec version() :: String.t()
```

Returns the package version.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
