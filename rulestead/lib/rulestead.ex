# credo:disable-for-this-file
defmodule Rulestead do
  @moduledoc """
  Root public module for the `rulestead` package.

  Phase 3 keeps the store-facing APIs from Phase 2 and adds the pure evaluator
  over an explicit in-memory authored flag payload:

  - store-facing calls return `{:ok, value} | {:error, %Rulestead.Error{}}`
  - bang variants raise the same `%Rulestead.Error{}`
  - evaluation helpers consume an authored flag payload first and explicit
    context second
  """

  alias Rulestead.{
    Admin.Authorizer,
    Admin.Redaction,
    ConfigError,
    Context,
    Error,
    Evaluator,
    Explainer,
    Governance.ApprovalRequirement,
    Governance.BlastRadiusThreshold,
    Manifest,
    Promotion.Apply,
    Promotion.Compare,
    Result,
    Runtime,
    Store,
    StoreError,
    Targeting.ImpactPreview,
    Telemetry
  }

  alias Rulestead.Manifest.Plan
  alias Rulestead.Manifest.Result, as: ManifestResult
  alias Rulestead.Store.Command

  @version Mix.Project.config()[:version] || "0.1.0"

  @doc """
  Returns the package version.
  """
  @spec version() :: String.t()
  def version, do: @version

  @doc """
  Tracks a custom analytics event.
  """
  @spec track(Context.t() | map() | String.t(), String.t(), map()) :: :ok
  defdelegate track(context_or_actor_id, event_name, metadata \\ %{}), to: Rulestead.Analytics

  @doc """
  Fetches the authored flag state for a `flag_key` and `environment_key`.
  """
  @spec fetch_flag(String.t() | atom(), String.t() | atom(), keyword()) :: Store.result(map())
  def fetch_flag(flag_key, environment_key, opts \\ []) do
    flag_key
    |> Command.FetchFlag.new(environment_key, opts)
    |> fetch_flag()
  end

  @doc """
  Fetches the authored flag state for a pre-built store command.
  """
  @spec fetch_flag(Command.FetchFlag.t()) :: Store.result(map())
  def fetch_flag(%Command.FetchFlag{} = command) do
    run_store(:fetch_flag, [command], command)
  end

  @doc """
  Compares authored source and target environment state for promotion preview flows.
  """
  @spec compare_environments(String.t() | atom(), String.t() | atom(), keyword()) ::
          Store.result(map())
  def compare_environments(source_environment_key, target_environment_key, opts \\ []) do
    source_environment_key
    |> Command.CompareEnvironments.new(target_environment_key, opts)
    |> compare_environments()
  end

  @doc """
  Compares authored source and target environment state for a pre-built compare command.
  """
  @spec compare_environments(Command.CompareEnvironments.t()) :: Store.result(map())
  def compare_environments(%Command.CompareEnvironments{} = command) do
    admin_read(:compare_environments, command)
  end

  @doc """
  Applies a bounded direct promotion bundle through compare revalidation and the configured store.
  """
  @spec apply_promotion(Command.ApplyPromotion.t()) :: Store.result(map())
  def apply_promotion(%Command.ApplyPromotion{} = command) do
    with :ok <- Apply.validate(command) do
      admin_write(:apply_promotion, command)
    end
  end

  @doc """
  Builds and applies a direct promotion bundle from root-level attributes.
  """
  @spec apply_promotion(map() | keyword(), keyword()) :: Store.result(map())
  def apply_promotion(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
    attrs
    |> Command.ApplyPromotion.new(opts)
    |> apply_promotion()
  end

  @doc """
  Exports a deterministic authored-state manifest for one environment.
  """
  @spec export_manifest(String.t() | atom(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def export_manifest(environment_key, opts \\ []) do
    Manifest.export(environment_key, opts)
  end

  @doc """
  Previews a manifest import as a saved apply plan artifact.
  """
  @spec import_manifest(binary() | map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def import_manifest(content, opts \\ []) do
    Manifest.Import.plan(content, opts)
  end

  @doc """
  Applies a previously generated manifest import plan artifact.
  """
  @spec apply_manifest_plan(binary() | map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def apply_manifest_plan(content, opts \\ []) do
    Manifest.Import.apply(content, opts)
  end

  @doc """
  Builds a saved promote plan artifact from a live compare preview.
  """
  @spec plan_promotion(String.t() | atom(), String.t() | atom(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def plan_promotion(source_environment_key, target_environment_key, opts \\ []) do
    compare_opts =
      opts
      |> Keyword.take([:flag_keys, :tenant_key])
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    with {:ok, compare} <-
           compare_environments(source_environment_key, target_environment_key, compare_opts) do
      plan =
        Plan.build_promote(%{
          source_environment_key: compare.source_environment.key,
          target_environment_key: compare.target_environment.key,
          status: promotion_plan_status(compare),
          tenant_key: compare.tenant_key,
          compare_token: compare.compare_token,
          source_fingerprint: compare.source_fingerprint,
          target_fingerprint: compare.target_fingerprint,
          dependency_closure_keys: compare.dependency_closure_keys,
          proposed_target_bundle:
            Map.new(compare.flags, fn flag ->
              {flag.flag_key, flag.proposed_target_state}
            end)
        })

      {:ok,
       ManifestResult.new(%{
         status: plan["status"],
         command: "rulestead.promote.plan",
         summary: %{
           "source_environment_key" => plan["source_environment_key"],
           "target_environment_key" => plan["target_environment_key"],
           "flag_count" => length(plan["flag_keys"]),
           "plan_token" => plan["plan_token"]
         },
         findings: promotion_findings(compare),
         details: %{"plan" => plan}
       })}
    end
  end

  @doc """
  Applies a previously generated promote plan artifact.
  """
  @spec apply_promotion_plan(binary() | map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def apply_promotion_plan(content, opts \\ []) do
    with {:ok, plan} <- Plan.load(content),
         :ok <- validate_promotion_plan_mode(plan),
         {:ok, reason} <- require_promotion_reason(opts),
         :ok <- validate_target_tenant(plan, opts),
         command <- promotion_apply_command(plan, reason, opts),
         {:ok, envelope} <- dispatch_promotion_plan(plan, command, reason, opts) do
      {:ok, envelope}
    else
      {:error, %Error{message: "promotion compare preview is stale"}} ->
        stale_promotion_result(content)

      {:error, %Error{message: "promotion target tenant drifted"}} ->
        stale_promotion_result(content, "target tenant drifted")

      {:error, %Error{} = error} ->
        map_promotion_apply_error(content, error)
    end
  end

  @doc """
  Creates a flag through the configured store adapter.
  """
  @spec create_flag(Command.CreateFlag.t()) :: Store.result(map())
  def create_flag(%Command.CreateFlag{} = command) do
    admin_write(:create_flag, command)
  end

  @doc """
  Creates a flag from root-level attributes.
  """
  @spec create_flag(map() | keyword(), keyword()) :: Store.result(map())
  def create_flag(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
    attrs
    |> Command.CreateFlag.new(opts)
    |> create_flag()
  end

  @doc """
  Updates flag metadata through the configured store adapter.
  """
  @spec update_flag(Command.UpdateFlag.t()) :: Store.result(map())
  def update_flag(%Command.UpdateFlag{} = command) do
    admin_write(:update_flag, command)
  end

  @doc """
  Updates a flag from root-level attributes.
  """
  @spec update_flag(String.t() | atom(), map() | keyword(), keyword()) :: Store.result(map())
  def update_flag(flag_key, attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
    flag_key
    |> Command.UpdateFlag.new(attrs, opts)
    |> update_flag()
  end

  @doc """
  Bang variant of `fetch_flag/3`.
  """
  @spec fetch_flag!(String.t() | atom(), String.t() | atom(), keyword()) :: map()
  def fetch_flag!(flag_key, environment_key, opts \\ []) do
    flag_key
    |> fetch_flag(environment_key, opts)
    |> unwrap!()
  end

  @doc """
  Saves a draft ruleset through the configured store adapter.
  """
  @spec save_draft_ruleset(Command.SaveDraftRuleset.t()) :: Store.result(map())
  def save_draft_ruleset(%Command.SaveDraftRuleset{} = command) do
    admin_write(:save_draft_ruleset, command)
  end

  @doc """
  Bang variant of `save_draft_ruleset/1`.
  """
  @spec save_draft_ruleset!(Command.SaveDraftRuleset.t()) :: map()
  def save_draft_ruleset!(%Command.SaveDraftRuleset{} = command) do
    command
    |> save_draft_ruleset()
    |> unwrap!()
  end

  @doc """
  Publishes a ruleset version through the configured store adapter.
  """
  @spec publish_ruleset(Command.PublishRuleset.t()) :: Store.result(map())
  def publish_ruleset(%Command.PublishRuleset{} = command) do
    admin_write(:publish_ruleset, command)
  end

  @doc """
  Bang variant of `publish_ruleset/1`.
  """
  @spec publish_ruleset!(Command.PublishRuleset.t()) :: map()
  def publish_ruleset!(%Command.PublishRuleset{} = command) do
    command
    |> publish_ruleset()
    |> unwrap!()
  end

  @doc """
  Archives a flag through the configured store adapter.
  """
  @spec archive_flag(Command.ArchiveFlag.t()) :: Store.result(map())
  def archive_flag(%Command.ArchiveFlag{} = command) do
    admin_write(:archive_flag, command)
  end

  @doc """
  Bang variant of `archive_flag/1`.
  """
  @spec archive_flag!(Command.ArchiveFlag.t()) :: map()
  def archive_flag!(%Command.ArchiveFlag{} = command) do
    command
    |> archive_flag()
    |> unwrap!()
  end

  @doc """
  Engages a per-flag per-environment kill switch.
  """
  @spec engage_kill_switch(Command.EngageKillSwitch.t()) :: Store.result(map())
  def engage_kill_switch(%Command.EngageKillSwitch{} = command) do
    admin_write(:engage_kill_switch, command)
  end

  @spec engage_kill_switch(String.t() | atom(), String.t() | atom(), map(), keyword()) ::
          Store.result(map())
  def engage_kill_switch(flag_key, environment_key, actor, opts \\ []) do
    flag_key
    |> Command.EngageKillSwitch.new(environment_key,
      actor: actor,
      reason: Keyword.get(opts, :reason),
      metadata: Keyword.get(opts, :metadata, %{})
    )
    |> engage_kill_switch()
  end

  @doc """
  Releases a per-flag per-environment kill switch.
  """
  @spec release_kill_switch(Command.ReleaseKillSwitch.t()) :: Store.result(map())
  def release_kill_switch(%Command.ReleaseKillSwitch{} = command) do
    admin_write(:release_kill_switch, command)
  end

  @spec release_kill_switch(String.t() | atom(), String.t() | atom(), map(), keyword()) ::
          Store.result(map())
  def release_kill_switch(flag_key, environment_key, actor, opts \\ []) do
    flag_key
    |> Command.ReleaseKillSwitch.new(environment_key,
      actor: actor,
      reason: Keyword.get(opts, :reason),
      metadata: Keyword.get(opts, :metadata, %{})
    )
    |> release_kill_switch()
  end

  @doc """
  Lists redacted audit events for one flag or all flags.
  """
  @spec list_audit_events(Command.ListAuditEvents.t() | keyword()) ::
          Store.result(Command.Page.t(map()))
  def list_audit_events(command_or_opts \\ Command.ListAuditEvents.new())

  def list_audit_events(%Command.ListAuditEvents{} = command) do
    admin_read(:list_audit_events, command)
  end

  def list_audit_events(opts) when is_list(opts) do
    opts
    |> Command.ListAuditEvents.new()
    |> list_audit_events()
  end

  @doc """
  Writes a linked inverse action for a prior audit event.
  """
  @spec rollback_audit_event(Command.RollbackAuditEvent.t()) :: Store.result(map())
  def rollback_audit_event(%Command.RollbackAuditEvent{} = command) do
    admin_write(:rollback_audit_event, command)
  end

  @spec rollback_audit_event(String.t(), keyword()) :: Store.result(map())
  def rollback_audit_event(audit_event_id, opts \\ []) when is_binary(audit_event_id) do
    audit_event_id
    |> Command.RollbackAuditEvent.new(
      actor: Keyword.get(opts, :actor),
      reason: Keyword.get(opts, :reason),
      metadata: Keyword.get(opts, :metadata, %{})
    )
    |> rollback_audit_event()
  end

  @doc """
  Submits a governed change request through the configured store adapter.
  """
  @spec submit_change_request(Command.SubmitChangeRequest.t()) :: Store.result(map())
  def submit_change_request(%Command.SubmitChangeRequest{} = command) do
    admin_write(:submit_change_request, command)
  end

  @doc """
  Approves a governed change request through the configured store adapter.
  """
  @spec approve_change_request(Command.ApproveChangeRequest.t()) :: Store.result(map())
  def approve_change_request(%Command.ApproveChangeRequest{} = command) do
    admin_write(:approve_change_request, command)
  end

  @doc """
  Rejects a governed change request through the configured store adapter.
  """
  @spec reject_change_request(Command.RejectChangeRequest.t()) :: Store.result(map())
  def reject_change_request(%Command.RejectChangeRequest{} = command) do
    admin_write(:reject_change_request, command)
  end

  @doc """
  Cancels a governed change request through the configured store adapter.
  """
  @spec cancel_change_request(Command.CancelChangeRequest.t()) :: Store.result(map())
  def cancel_change_request(%Command.CancelChangeRequest{} = command) do
    admin_write(:cancel_change_request, command)
  end

  @doc """
  Executes an approved governed change request through the configured store adapter.
  """
  @spec execute_change_request(Command.ExecuteChangeRequest.t()) :: Store.result(map())
  def execute_change_request(%Command.ExecuteChangeRequest{} = command) do
    admin_write(:execute_change_request, command)
  end

  @doc """
  Schedules an approved governed change request through the configured store adapter.
  """
  @spec schedule_change_request(Command.ScheduleChangeRequest.t()) :: Store.result(map())
  def schedule_change_request(%Command.ScheduleChangeRequest{} = command) do
    admin_write(:schedule_change_request, command)
  end

  @doc """
  Fetches one change request through the configured store adapter.
  """
  @spec fetch_change_request(Command.FetchChangeRequest.t()) :: Store.result(map())
  def fetch_change_request(%Command.FetchChangeRequest{} = command) do
    run_store(:fetch_change_request, [command], command)
  end

  @doc """
  Lists change requests through the configured store adapter.
  """
  @spec list_change_requests(Command.ListChangeRequests.t() | keyword()) ::
          Store.result(Command.Page.t(map()))
  def list_change_requests(command_or_opts \\ Command.ListChangeRequests.new())

  def list_change_requests(%Command.ListChangeRequests{} = command) do
    run_store(:list_change_requests, [command], command)
  end

  def list_change_requests(opts) when is_list(opts) do
    opts
    |> Command.ListChangeRequests.new()
    |> list_change_requests()
  end

  @doc """
  Schedules a narrowly allowed direct governed action through the configured store adapter.
  """
  @spec schedule_governed_action(Command.ScheduleGovernedAction.t()) :: Store.result(map())
  def schedule_governed_action(%Command.ScheduleGovernedAction{} = command) do
    admin_write(:schedule_governed_action, command)
  end

  @doc """
  Cancels a scheduled execution through the configured store adapter.
  """
  @spec cancel_scheduled_execution(Command.CancelScheduledExecution.t()) :: Store.result(map())
  def cancel_scheduled_execution(%Command.CancelScheduledExecution{} = command) do
    admin_write(:cancel_scheduled_execution, command)
  end

  @doc """
  Requeues a quarantined scheduled execution through the configured store adapter.
  """
  @spec requeue_scheduled_execution(Command.RequeueScheduledExecution.t()) :: Store.result(map())
  def requeue_scheduled_execution(%Command.RequeueScheduledExecution{} = command) do
    admin_write(:requeue_scheduled_execution, command)
  end

  @doc """
  Fetches one scheduled execution through the configured store adapter.
  """
  @spec fetch_scheduled_execution(Command.FetchScheduledExecution.t()) :: Store.result(map())
  def fetch_scheduled_execution(%Command.FetchScheduledExecution{} = command) do
    run_store(:fetch_scheduled_execution, [command], command)
  end

  @doc """
  Lists scheduled executions through the configured store adapter.
  """
  @spec list_scheduled_executions(Command.ListScheduledExecutions.t() | keyword()) ::
          Store.result(Command.Page.t(map()))
  def list_scheduled_executions(command_or_opts \\ Command.ListScheduledExecutions.new())

  def list_scheduled_executions(%Command.ListScheduledExecutions{} = command) do
    run_store(:list_scheduled_executions, [command], command)
  end

  def list_scheduled_executions(opts) when is_list(opts) do
    opts
    |> Command.ListScheduledExecutions.new()
    |> list_scheduled_executions()
  end

  @doc """
  Records an inbound webhook receipt through the configured store adapter.
  """
  @spec receive_inbound_webhook(Command.ReceiveInboundWebhook.t()) :: Store.result(map())
  def receive_inbound_webhook(%Command.ReceiveInboundWebhook{} = command) do
    result = run_store(:receive_inbound_webhook, [command], command)

    case result do
      {:ok, receipt} ->
        event = if receipt.verified_state == :accepted, do: :received, else: :rejected

        Telemetry.execute(
          [:rulestead, :ops, :webhook, event],
          %{count: 1},
          Telemetry.webhook_metadata(receipt, %{reason: event})
        )

      {:error, _error} ->
        :ok
    end

    result
  end

  @doc """
  Fetches one webhook receipt through the configured store adapter.
  """
  @spec fetch_webhook_record(String.t() | Command.FetchWebhookRecord.t(), keyword()) ::
          Store.result(map())
  def fetch_webhook_record(id_or_command, opts \\ [])

  def fetch_webhook_record(%Command.FetchWebhookRecord{} = command, _opts) do
    admin_read(:fetch_webhook_record, command)
  end

  def fetch_webhook_record(receipt_id, opts) when is_binary(receipt_id) do
    receipt_id
    |> Command.FetchWebhookRecord.new(opts)
    |> fetch_webhook_record([])
  end

  @doc """
  Lists webhook receipts through the configured store adapter.
  """
  @spec list_webhook_records(Command.ListWebhookRecords.t() | keyword()) ::
          Store.result(Command.Page.t(map()))
  def list_webhook_records(command_or_opts \\ [])

  def list_webhook_records(%Command.ListWebhookRecords{} = command) do
    admin_read(:list_webhook_records, command)
  end

  def list_webhook_records(opts) when is_list(opts) do
    opts
    |> Command.ListWebhookRecords.new()
    |> list_webhook_records()
  end

  @doc """
  Creates a new webhook destination.
  """
  @spec create_webhook_destination(Command.CreateWebhookDestination.t() | map() | keyword()) ::
          Store.result(map())
  def create_webhook_destination(%Command.CreateWebhookDestination{} = command) do
    admin_write(:create_webhook_destination, command)
  end

  def create_webhook_destination(attrs) when is_map(attrs) or is_list(attrs) do
    attrs
    |> Command.CreateWebhookDestination.new()
    |> create_webhook_destination()
  end

  @doc """
  Updates an existing webhook destination.
  """
  @spec update_webhook_destination(
          Command.UpdateWebhookDestination.t()
          | {String.t(), map() | keyword()}
        ) :: Store.result(map())
  def update_webhook_destination(%Command.UpdateWebhookDestination{} = command) do
    admin_write(:update_webhook_destination, command)
  end

  def update_webhook_destination(id, attrs)
      when is_binary(id) and (is_map(attrs) or is_list(attrs)) do
    id
    |> Command.UpdateWebhookDestination.new(attrs)
    |> update_webhook_destination()
  end

  @doc """
  Fetches a single webhook destination by ID.
  """
  @spec fetch_webhook_destination(Command.FetchWebhookDestination.t() | String.t(), keyword()) ::
          Store.result(map())
  def fetch_webhook_destination(id_or_command, opts \\ [])

  def fetch_webhook_destination(%Command.FetchWebhookDestination{} = command, _opts) do
    admin_read(:fetch_webhook_destination, command)
  end

  def fetch_webhook_destination(id, opts) when is_binary(id) do
    id
    |> Command.FetchWebhookDestination.new(opts)
    |> fetch_webhook_destination([])
  end

  @doc """
  Lists webhook destinations.
  """
  @spec list_webhook_destinations(Command.ListWebhookDestinations.t() | keyword()) ::
          Store.result(Command.Page.t(map()))
  def list_webhook_destinations(command_or_opts \\ [])

  def list_webhook_destinations(%Command.ListWebhookDestinations{} = command) do
    admin_read(:list_webhook_destinations, command)
  end

  def list_webhook_destinations(opts) when is_list(opts) do
    opts
    |> Command.ListWebhookDestinations.new()
    |> list_webhook_destinations()
  end

  @doc """
  Lists webhook outbound deliveries.
  """
  @spec list_webhook_deliveries(Command.ListWebhookDeliveries.t() | keyword()) ::
          Store.result(Command.Page.t(map()))
  def list_webhook_deliveries(command_or_opts \\ [])

  def list_webhook_deliveries(%Command.ListWebhookDeliveries{} = command) do
    admin_read(:list_webhook_deliveries, command)
  end

  def list_webhook_deliveries(opts) when is_list(opts) do
    opts
    |> Command.ListWebhookDeliveries.new()
    |> list_webhook_deliveries()
  end

  @doc """
  Retries a failed webhook delivery.
  """
  @spec retry_webhook_delivery(Command.RetryWebhookDelivery.t() | String.t(), keyword()) ::
          Store.result(map())
  def retry_webhook_delivery(id_or_command, opts \\ [])

  def retry_webhook_delivery(%Command.RetryWebhookDelivery{} = command, _opts) do
    admin_write(:retry_webhook_delivery, command)
  end

  def retry_webhook_delivery(delivery_id, opts) when is_binary(delivery_id) do
    delivery_id
    |> Command.RetryWebhookDelivery.new(opts)
    |> retry_webhook_delivery([])
  end

  @doc """
  Normalizes a verified inbound webhook event into the local governance path.
  """
  @spec execute_inbound_event(Rulestead.Webhooks.InboundEvent.t(), map()) :: Store.result(map())
  def execute_inbound_event(%Rulestead.Webhooks.InboundEvent{} = event, receipt) do
    actor = %{
      id: "system:webhook:#{event.endpoint_key || event.provider}",
      roles: [:operator, :prod_operator],
      display: "Webhook Ingress (#{event.provider})"
    }

    metadata =
      (event.metadata || %{})
      |> Map.put("webhook_provider", event.provider)
      |> Map.put("webhook_delivery_id", event.delivery_id)
      |> Map.put("webhook_receipt_id", receipt.id)
      |> Map.put("correlation_id", event.correlation_id)
      |> Map.put("environment_key", event.payload["environment_key"])

    # Convert inbound payload into a governance command
    case inbound_to_command(event, actor, metadata) do
      {:ok, command} ->
        dispatch_governance_command(command)

      {:error, error} ->
        {:error, error}
    end
  end

  defp inbound_to_command(event, actor, metadata) do
    action = event.payload["action"]
    resource_type = event.payload["resource_type"] || "flag"
    resource_key = event.payload["resource_key"] || event.payload["flag_key"]
    environment_key = event.payload["environment_key"]

    case action do
      "publish" ->
        {:ok,
         Command.PublishRuleset.new(resource_key, environment_key,
           actor: actor,
           version: event.payload["version"],
           metadata: metadata
         )}

      "submit_change_request" ->
        {:ok,
         Command.SubmitChangeRequest.new(
           %{
             resource_type: stringify_resource(resource_type),
             resource_key: resource_key,
             environment_key: environment_key,
             action: String.to_existing_atom(event.payload["command_operation"]),
             command: event.payload["command_attrs"] || %{},
             approval_requirement: %{
               # Placeholder, will be resolved by Authorizer
               action: String.to_existing_atom(event.payload["command_operation"]),
               environment_key: environment_key,
               required_approvals: 0,
               change_request_required?: true,
               self_approval_allowed?: false
             }
           },
           actor: actor,
           reason: event.payload["reason"],
           metadata: metadata
         )}

      "engage_kill_switch" ->
        {:ok,
         Command.EngageKillSwitch.new(resource_key, environment_key,
           actor: actor,
           reason: event.payload["reason"],
           metadata: metadata
         )}

      "release_kill_switch" ->
        {:ok,
         Command.ReleaseKillSwitch.new(resource_key, environment_key,
           actor: actor,
           reason: event.payload["reason"],
           metadata: metadata
         )}

      "schedule_governed_action" ->
        scheduled_for =
          event.payload["scheduled_for"] ||
            event.payload["received_at"] ||
            event.received_at

        execution_mode =
          case event.payload["execution_mode"] do
            nil -> :policy_bypass
            mode when is_atom(mode) -> mode
            mode when is_binary(mode) -> String.to_existing_atom(mode)
          end

        {:ok,
         Command.ScheduleGovernedAction.new(
           %{
             action: String.to_existing_atom(event.payload["command_operation"]),
             environment_key: environment_key,
             resource_type: stringify_resource(resource_type),
             resource_key: resource_key,
             command: event.payload["command_attrs"] || %{},
             scheduled_for: scheduled_for,
             execution_mode: execution_mode
           },
           actor: actor,
           reason: event.payload["reason"],
           metadata: metadata
         )}

      # We can expand this list as needed
      _ ->
        {:error, StoreError.invalid_command("unsupported inbound webhook action: #{action}")}
    end
  end

  defp dispatch_governance_command(%Command.PublishRuleset{} = command),
    do: publish_ruleset(command)

  defp dispatch_governance_command(%Command.SubmitChangeRequest{} = command),
    do: submit_change_request(command)

  defp dispatch_governance_command(%Command.EngageKillSwitch{} = command),
    do: engage_kill_switch(command)

  defp dispatch_governance_command(%Command.ReleaseKillSwitch{} = command),
    do: release_kill_switch(command)

  defp dispatch_governance_command(%Command.ScheduleGovernedAction{} = command),
    do: schedule_governed_action(command)

  @doc """
  Resolves whether a governed action must go through a change request.
  """
  @spec authorize_governed_action(term(), atom(), term(), String.t() | atom() | nil) ::
          {:ok, Rulestead.Governance.ApprovalRequirement.t()}
          | {:error, Rulestead.Error.t(), Authorizer.audit_payload()}
  def authorize_governed_action(actor, action, resource, environment_key) do
    Authorizer.authorize_governed_action(actor, action, resource, environment_key)
  end

  @doc """
  Resolves whether an actor may approve a specific change request.
  """
  @spec authorize_change_request_approval(
          term(),
          term(),
          atom(),
          term(),
          String.t() | atom() | nil
        ) ::
          {:ok, Rulestead.Governance.ApprovalRequirement.t()}
          | {:error, Rulestead.Error.t(), Authorizer.audit_payload()}
  def authorize_change_request_approval(actor, submitter, action, resource, environment_key) do
    Authorizer.authorize_change_request_approval(
      actor,
      submitter,
      action,
      resource,
      environment_key
    )
  end

  @doc """
  Lists flags through the configured store adapter.

  Phase 2 keeps this as the shared list/search surface for store adapters.
  """
  @spec list_flags() :: Store.result(Command.Page.t(map()))
  def list_flags do
    list_flags(Command.ListFlags.new())
  end

  @spec list_flags(keyword()) :: Store.result(Command.Page.t(map()))
  def list_flags(opts) when is_list(opts) do
    opts
    |> Command.ListFlags.new()
    |> list_flags()
  end

  @spec list_flags(Command.ListFlags.t()) :: Store.result(Command.Page.t(map()))
  def list_flags(%Command.ListFlags{} = command) do
    run_store(:list_flags, [command], command)
  end

  @doc """
  Bang variant of `list_flags/0` and `list_flags/1`.
  """
  @spec list_flags!() :: Command.Page.t(map())
  @spec list_flags!(Command.ListFlags.t() | keyword()) :: Command.Page.t(map())
  def list_flags!(command \\ Command.ListFlags.new()) do
    command
    |> list_flags()
    |> unwrap!()
  end

  @doc """
  Lists environments through the configured store adapter.
  """
  @spec list_environments() :: Store.result([map()])
  def list_environments do
    list_environments(Command.ListEnvironments.new())
  end

  @spec list_environments(keyword()) :: Store.result([map()])
  def list_environments(opts) when is_list(opts) do
    opts
    |> Command.ListEnvironments.new()
    |> list_environments()
  end

  @spec list_environments(Command.ListEnvironments.t()) :: Store.result([map()])
  def list_environments(%Command.ListEnvironments{} = command) do
    run_store(:list_environments, [command], command)
  end

  @doc """
  Lists reusable audiences through the configured store adapter.
  """
  @spec list_audiences() :: Store.result([map()])
  def list_audiences do
    list_audiences(Command.ListAudiences.new())
  end

  @spec list_audiences(keyword()) :: Store.result([map()])
  def list_audiences(opts) when is_list(opts) do
    opts
    |> Command.ListAudiences.new()
    |> list_audiences()
  end

  @spec list_audiences(Command.ListAudiences.t()) :: Store.result([map()])
  def list_audiences(%Command.ListAudiences{} = command) do
    run_store(:list_audiences, [command], command)
  end

  @doc """
  Lists audience dependency inventory rows with deterministic scoped ordering.
  """
  @spec list_audience_dependencies() :: Store.result(map())
  def list_audience_dependencies do
    list_audience_dependencies(Command.ListAudienceDependencies.new())
  end

  @spec list_audience_dependencies(keyword()) :: Store.result(map())
  def list_audience_dependencies(opts) when is_list(opts) do
    opts
    |> Command.ListAudienceDependencies.new()
    |> list_audience_dependencies()
  end

  @spec list_audience_dependencies(Command.ListAudienceDependencies.t()) :: Store.result(map())
  def list_audience_dependencies(%Command.ListAudienceDependencies{} = command) do
    admin_read(:list_audience_dependencies, command)
  end

  @doc """
  Previews the bounded impact of a reusable audience mutation.
  """
  @spec preview_audience_impact(String.t() | atom(), String.t() | atom(), keyword()) ::
          Store.result(map())
  def preview_audience_impact(audience_key, operation, opts \\ []) do
    audience_key
    |> Command.PreviewAudienceImpact.new(operation, opts)
    |> preview_audience_impact()
  end

  @spec preview_audience_impact(Command.PreviewAudienceImpact.t()) :: Store.result(map())
  def preview_audience_impact(%Command.PreviewAudienceImpact{} = command) do
    admin_read(:preview_audience_impact, command)
  end

  @doc """
  Assesses audience mutation blast radius from preview payload inputs.

  Returns a deterministic threshold verdict suitable for operator display and
  change-request embedding. Does not perform I/O — supply preview data from
  `preview_audience_impact/2`.
  """
  @spec assess_audience_blast_radius(map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def assess_audience_blast_radius(preview_or_attrs, opts \\ []) do
    BlastRadiusThreshold.assess(preview_or_attrs, opts)
  end

  @doc """
  Applies a reusable audience mutation after validating fresh preview evidence.

  Protected-environment threshold evaluation runs in the store pipeline via
  `Rulestead.Governance.BlastRadiusThreshold.validate_protected_apply/3`.
  Custom store adapters must call that helper to inherit the same contract.
  """
  @spec apply_audience_mutation(Command.ApplyAudienceMutation.t() | map() | keyword(), keyword()) ::
          Store.result(map())
  def apply_audience_mutation(command_or_attrs, opts \\ [])

  def apply_audience_mutation(%Command.ApplyAudienceMutation{} = command, _opts) do
    with :ok <- validate_audience_mutation_confirmation(command) do
      admin_write(:apply_audience_mutation, command)
    end
  end

  def apply_audience_mutation(attrs, opts) when is_map(attrs) or is_list(attrs) do
    attrs
    |> Command.ApplyAudienceMutation.new(opts)
    |> apply_audience_mutation()
  end

  @doc """
  Records bounded evaluation freshness for one flag/environment pair.
  """
  @spec record_evaluation(Command.RecordEvaluation.t()) :: Store.result(map())
  def record_evaluation(%Command.RecordEvaluation{} = command) do
    run_store(:record_evaluation, [command], command)
  end

  @doc """
  Records bounded evaluation freshness using root-level arguments.
  """
  @spec record_evaluation(String.t() | atom(), String.t() | atom(), DateTime.t()) ::
          Store.result(map())
  def record_evaluation(flag_key, environment_key, %DateTime{} = last_evaluated_at) do
    flag_key
    |> Command.RecordEvaluation.new(environment_key, last_evaluated_at)
    |> record_evaluation()
  end

  @doc """
  Publishes a bounded rollout stage advancement through the configured store adapter.
  """
  @spec advance_rollout(Command.AdvanceRollout.t()) :: Store.result(map())
  def advance_rollout(%Command.AdvanceRollout{} = command) do
    admin_write(:advance_rollout, command)
  end

  @doc """
  Builds and executes a bounded rollout stage advancement from root-level arguments.
  """
  @spec advance_rollout(String.t() | atom(), String.t() | atom(), map() | keyword(), keyword()) ::
          Store.result(map())
  def advance_rollout(flag_key, environment_key, attrs, opts \\ [])
      when is_map(attrs) or is_list(attrs) do
    flag_key
    |> Command.AdvanceRollout.new(environment_key, attrs, opts)
    |> advance_rollout()
  end

  @doc """
  Evaluates guardrail facts for an active rollout stage and records the resulting operational state.
  """
  @spec evaluate_guarded_rollout(Command.EvaluateGuardedRollout.t()) :: Store.result(map())
  def evaluate_guarded_rollout(%Command.EvaluateGuardedRollout{} = command) do
    run_store(:evaluate_guarded_rollout, [command], command)
  end

  @doc """
  Builds and executes a guarded rollout evaluation from root-level arguments.
  """
  @spec evaluate_guarded_rollout(
          String.t() | atom(),
          String.t() | atom(),
          map() | keyword(),
          keyword()
        ) :: Store.result(map())
  def evaluate_guarded_rollout(flag_key, environment_key, attrs, opts \\ [])
      when is_map(attrs) or is_list(attrs) do
    flag_key
    |> Command.EvaluateGuardedRollout.new(environment_key, attrs, opts)
    |> evaluate_guarded_rollout()
  end

  @doc """
  Fetches the latest derived guardrail status for one rollout rule or stage.
  """
  @spec fetch_guardrail_status(Command.FetchGuardrailStatus.t()) :: Store.result(map())
  def fetch_guardrail_status(%Command.FetchGuardrailStatus{} = command) do
    admin_read(:fetch_guardrail_status, command)
  end

  @doc """
  Builds a guardrail-status query from root-level arguments.
  """
  @spec fetch_guardrail_status(String.t() | atom(), String.t() | atom(), keyword()) ::
          Store.result(map())
  def fetch_guardrail_status(flag_key, environment_key, opts \\ []) do
    flag_key
    |> Command.FetchGuardrailStatus.new(environment_key, opts)
    |> fetch_guardrail_status()
  end

  @doc """
  Evaluates an authored in-memory flag payload against an explicit context.
  """
  @spec evaluate(map(), Context.t() | keyword() | map(), keyword()) ::
          {:ok, Result.t()} | {:error, Error.t()}
  def evaluate(flag_payload, context, opts \\ []) do
    context = normalize_eval_context(context, opts)

    Telemetry.span(
      [:rulestead, :eval, :decide],
      Telemetry.metadata(Telemetry.base_metadata(flag_payload, context)),
      fn ->
        result =
          with {:ok, result} <- Evaluator.evaluate(flag_payload, context) do
            emit_warnings(result)

            # Record telemetry evaluation for hygiene cleanup
            if result.flag_key do
              # We spawn to ensure non-blocking, although ETS is fast, write-behind should never block.
              # Alternatively, since our ETS is public and fast, we just call it directly.
              Rulestead.Telemetry.Cache.record_evaluation(
                result.flag_key,
                context.environment || "default",
                result.variant || "unknown",
                DateTime.utc_now()
              )
            end

            {:ok, result}
          end

        {result, eval_stop_metadata(result, flag_payload, context)}
      end
    )
  rescue
    error ->
      reraise(error, __STACKTRACE__)
  end

  @doc """
  Bang variant of `evaluate/3`.
  """
  @spec evaluate!(map(), Context.t() | keyword() | map(), keyword()) :: Result.t()
  def evaluate!(flag_payload, context, opts \\ []) do
    flag_payload
    |> evaluate(context, opts)
    |> unwrap!()
  end

  @doc """
  Returns the boolean enabled projection for an authored flag payload.
  """
  @spec enabled?(map(), Context.t() | keyword() | map()) :: {:ok, boolean()} | {:error, Error.t()}
  def enabled?(flag_payload, context) do
    with {:ok, %Result{} = result} <- evaluate(flag_payload, context) do
      {:ok, result.enabled?}
    end
  end

  @doc """
  Returns the projected value for an authored flag payload.
  """
  @spec get_value(map(), Context.t() | keyword() | map(), term()) ::
          {:ok, term()} | {:error, Error.t()}
  def get_value(flag_payload, context, default) do
    with {:ok, %Result{} = result} <- evaluate(flag_payload, context) do
      value =
        cond do
          result.reason == :default and is_nil(result.value) -> default
          is_nil(result.value) -> default
          true -> result.value
        end

      {:ok, value}
    end
  end

  @doc """
  Returns the assigned variant key for an authored flag payload.
  """
  @spec get_variant(map(), Context.t() | keyword() | map()) ::
          {:ok, String.t() | nil} | {:error, Error.t()}
  def get_variant(flag_payload, context) do
    with {:ok, %Result{} = result} <- evaluate(flag_payload, context) do
      {:ok, result.variant}
    end
  end

  @doc """
  Returns a human-readable explanation derived from the evaluation trace.
  """
  @spec explain(map(), Context.t() | keyword() | map()) :: {:ok, String.t()} | {:error, Error.t()}
  def explain(flag_payload, context) do
    with {:ok, %Result{} = result} <- evaluate(flag_payload, context) do
      {:ok, Explainer.explain(result.debug_trace)}
    end
  end

  @doc """
  Admin-safe runtime simulation for one flag and environment.
  """
  @spec simulate_flag(
          String.t() | atom(),
          String.t() | atom(),
          Context.t() | keyword() | map(),
          keyword()
        ) ::
          {:ok, map()} | {:error, Error.t()}
  def simulate_flag(flag_key, environment_key, context, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    with :ok <-
           authorize_admin_read(
             actor,
             :simulate_flag,
             %{resource_type: :flag, resource_key: flag_key},
             environment_key
           ),
         {:ok, result} <- Runtime.evaluate(environment_key, flag_key, context) do
      redacted =
        Redaction.redact_metadata(%{traits: Context.normalize(context).attributes},
          allow: Keyword.get(opts, :allow, ["targeting_key"])
        )

      {:ok, %{result: result, redacted_context: redacted}}
    end
  end

  @doc """
  Admin-safe explain seam for one flag and environment.
  """
  @spec explain_flag(
          String.t() | atom(),
          String.t() | atom(),
          Context.t() | keyword() | map(),
          keyword()
        ) ::
          {:ok, map()} | {:error, Error.t()}
  def explain_flag(flag_key, environment_key, context, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    with :ok <-
           authorize_admin_read(
             actor,
             :explain_flag,
             %{resource_type: :flag, resource_key: flag_key},
             environment_key
           ),
         {:ok, explanation} <- Runtime.explain(environment_key, flag_key, context) do
      redacted =
        Redaction.redact_metadata(%{traits: Context.normalize(context).attributes},
          allow: Keyword.get(opts, :allow, ["targeting_key"])
        )

      {:ok, %{explanation: explanation, redacted_context: redacted}}
    end
  end

  @doc """
  Returns bounded runtime diagnostics for the local node.
  """
  @spec diagnostics() :: map()
  def diagnostics, do: Runtime.diagnostics()

  @doc """
  Returns the bounded infrastructure health snapshot for the local node.
  """
  @spec infrastructure_health() :: map()
  def infrastructure_health, do: Runtime.Diagnostics.current().infrastructure_health

  defp run_store(operation, args, command) do
    case configured_store() do
      {:ok, adapter} -> invoke_store(adapter, operation, args, command)
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp configured_store do
    case Application.get_env(:rulestead, :store) ||
           Application.get_env(:rulestead, :store_adapter) do
      nil ->
        {:error, ConfigError.store_not_configured(metadata: %{config_key: "store"})}

      adapter when is_atom(adapter) ->
        ensure_adapter_module(adapter)

      adapter_opts when is_list(adapter_opts) ->
        adapter_opts
        |> Keyword.get(:adapter)
        |> normalize_configured_adapter(adapter_opts)

      %{adapter: adapter} = config ->
        normalize_configured_adapter(adapter, config)

      %{module: adapter} = config ->
        normalize_configured_adapter(adapter, config)

      invalid ->
        {:error,
         ConfigError.store_adapter_invalid(metadata: %{configured_value: inspect(invalid)})}
    end
  end

  defp normalize_configured_adapter(adapter, config) when is_atom(adapter) do
    case ensure_adapter_module(adapter) do
      {:ok, adapter} ->
        {:ok, adapter}

      {:error, error} ->
        {:error,
         Error.normalize(
           Map.put(Map.from_struct(error), :metadata, %{configured_value: inspect(config)})
         )}
    end
  end

  defp normalize_configured_adapter(_adapter, config) do
    {:error, ConfigError.store_adapter_invalid(metadata: %{configured_value: inspect(config)})}
  end

  defp ensure_adapter_module(adapter) when is_atom(adapter) do
    cond do
      not Code.ensure_loaded?(adapter) ->
        {:error,
         ConfigError.store_adapter_invalid(
           metadata: %{adapter: inspect(adapter)},
           details: [%{message: "module could not be loaded"}]
         )}

      true ->
        {:ok, adapter}
    end
  end

  defp invoke_store(adapter, operation, args, command) do
    arity = length(args)

    cond do
      not function_exported?(adapter, operation, arity) ->
        {:error,
         ConfigError.store_adapter_invalid(
           metadata: %{adapter: inspect(adapter), operation: Atom.to_string(operation)},
           details: [%{message: "callback is not exported"}]
         )}

      true ->
        do_invoke_store(adapter, operation, args, command)
    end
  end

  defp do_invoke_store(adapter, operation, args, command) do
    kind = store_event_kind(operation)
    command = command || List.first(args)

    Telemetry.span(
      [:rulestead, :store, kind],
      Telemetry.metadata(
        Telemetry.command_metadata(command, %{operation: Atom.to_string(operation)})
      ),
      fn ->
        result =
          adapter
          |> apply(operation, args)
          |> normalize_store_result(adapter, operation)

        {result, store_stop_metadata(result, operation)}
      end
    )
  rescue
    error in [Error] ->
      {:error, error}

    exception ->
      {:error,
       StoreError.unavailable(
         metadata: %{adapter: inspect(adapter), operation: Atom.to_string(operation)},
         cause: exception
       )}
  end

  defp normalize_store_result({:ok, value}, _adapter, _operation), do: {:ok, value}

  defp normalize_store_result({:error, %Error{} = error}, _adapter, _operation),
    do: {:error, error}

  defp normalize_store_result(nil, adapter, operation) do
    {:error,
     StoreError.unavailable(
       metadata: %{adapter: inspect(adapter), operation: Atom.to_string(operation)},
       details: [%{message: "store adapters must not return nil"}]
     )}
  end

  defp normalize_store_result(other, adapter, operation) do
    {:error,
     StoreError.unavailable(
       metadata: %{adapter: inspect(adapter), operation: Atom.to_string(operation)},
       details: [%{message: "store adapter returned an invalid response"}],
       cause: other
     )}
  end

  defp unwrap!({:ok, value}), do: value
  defp unwrap!({:error, %Error{} = error}), do: raise(error)

  defp normalize_eval_context(context, opts) do
    context = Context.normalize(context)

    if Keyword.has_key?(opts, :strict?) do
      Context.normalize(Map.put(Map.from_struct(context), :strict?, Keyword.get(opts, :strict?)))
    else
      context
    end
  end

  defp emit_warnings(%Result{debug_trace: %{warnings: warnings}} = result)
       when is_list(warnings) do
    Enum.each(warnings, fn warning ->
      Telemetry.execute(
        [:rulestead, :eval, :warning],
        %{count: 1},
        Telemetry.result_metadata(result, %{environment: result.debug_trace[:environment]}, %{
          reason: warning[:type]
        })
      )
    end)
  end

  defp emit_warnings(_result), do: :ok

  defp eval_stop_metadata({:ok, %Result{} = result}, flag_payload, context) do
    flag_payload
    |> Telemetry.base_metadata(context)
    |> Map.merge(Telemetry.result_metadata(result, context))
  end

  defp eval_stop_metadata({:error, %Error{} = error}, flag_payload, context) do
    flag_payload
    |> Telemetry.base_metadata(context)
    |> Map.merge(%{reason: error.type, matched_rule_count: 0})
  end

  defp admin_stop_metadata({:ok, value}, command) do
    command
    |> Telemetry.command_metadata()
    |> Map.merge(result_like_metadata(value))
    |> Map.put(:reason, :ok)
  end

  defp admin_stop_metadata({:error, %Error{} = error}, command) do
    command
    |> Telemetry.command_metadata()
    |> Map.put(:reason, error.type)
  end

  defp admin_write(operation, command) do
    redacted_command = redact_command(command)
    resource = command_resource(redacted_command)
    action = command_action(operation, redacted_command)

    Telemetry.span(
      [:rulestead, :admin, :mutation],
      Telemetry.metadata(
        redacted_command
        |> Telemetry.command_metadata(%{
          operation: Atom.to_string(operation),
          audit_action: Atom.to_string(action)
        })
        |> Map.merge(Telemetry.governance_metadata(redacted_command, %{action: action}))
      ),
      fn ->
        {result, executed_command} =
          case authorize_admin_write(operation, redacted_command, action, resource) do
            :ok ->
              {run_store(operation, [redacted_command], redacted_command), redacted_command}

            {:ok, authorized_command} ->
              {run_store(operation, [authorized_command], authorized_command), authorized_command}

            {:error, error} ->
              {{:error, error}, redacted_command}

            {:error, error, denied_audit} ->
              maybe_persist_denied_mutation(operation, redacted_command, denied_audit)
              {{:error, error}, redacted_command}
          end

        {result, admin_stop_metadata(result, executed_command)}
      end
    )
  end

  defp authorize_admin_write(:approve_change_request, command, _action, resource) do
    with {:ok, change_request} <-
           fetch_change_request_for_authorization(command.change_request_id) do
      command
      |> Map.get(:actor)
      |> Authorizer.authorize_change_request_approval(
        change_request.submitted_by,
        change_request.action,
        governance_change_request_resource(change_request, resource),
        change_request.environment_key
      )
      |> normalize_governance_authorization()
    end
  end

  defp authorize_admin_write(operation, command, action, resource)
       when operation in [:reject_change_request, :cancel_change_request, :execute_change_request] do
    with {:ok, change_request} <-
           fetch_change_request_for_authorization(command.change_request_id) do
      Authorizer.authorize(
        Map.get(command, :actor),
        action,
        governance_change_request_resource(change_request, resource),
        change_request.environment_key
      )
    end
  end

  defp authorize_admin_write(:submit_change_request, command, action, resource) do
    Authorizer.authorize(
      Map.get(command, :actor),
      action,
      resource,
      governance_environment(command, Map.get(command, :metadata, %{}))
    )
  end

  defp authorize_admin_write(:publish_ruleset, command, _action, resource) do
    command
    |> Map.get(:actor)
    |> Authorizer.authorize_governed_action(
      :publish_ruleset,
      resource,
      Map.get(command, :environment_key)
    )
    |> normalize_governance_authorization()
  end

  defp authorize_admin_write(
         :schedule_governed_action,
         %Command.ScheduleGovernedAction{} = command,
         _action,
         resource
       ) do
    actor = Map.get(command, :actor)
    environment_key = Map.get(command, :environment_key)

    with :ok <- ensure_bounded_scheduled_action(command.action),
         requirement <-
           Authorizer.approval_requirement(actor, command.action, resource, environment_key),
         {:ok, approval_requirement} <-
           authorize_direct_scheduled_execution(
             actor,
             command,
             resource,
             environment_key,
             requirement
           ) do
      {:ok,
       %{command | approval_requirement: ApprovalRequirement.serialize(approval_requirement)}}
    end
  end

  defp authorize_admin_write(_operation, command, action, resource) do
    Authorizer.authorize(
      Map.get(command, :actor),
      action,
      resource,
      Map.get(command, :environment_key)
    )
  end

  defp admin_read(operation, command) do
    action = command_action(operation, command)

    with :ok <-
           authorize_admin_read(
             Map.get(command, :actor),
             action,
             command_resource(command),
             Map.get(command, :environment_key)
           ) do
      run_store(operation, [command], command)
    end
  end

  defp authorize_admin_read(actor, action, resource, environment_key) do
    case Authorizer.authorize(actor, action, resource, environment_key) do
      :ok -> :ok
      {:error, error, _denied_audit} -> {:error, error}
    end
  end

  defp redact_command(command) do
    allow = [
      "request_id",
      "source",
      "reason",
      "emergency_reason",
      "targeting_key",
      "plan",
      "nested.region",
      "webhook_provider",
      "webhook_delivery_id",
      "webhook_receipt_id",
      "correlation_id",
      "environment_key"
    ]

    redacted_metadata = Redaction.redact_metadata(Map.get(command, :metadata, %{}), allow: allow)
    Map.put(command, :metadata, redacted_metadata.audit)
  end

  defp command_resource(%Command.PreviewAudienceImpact{audience_key: audience_key}) do
    %{resource_type: :audience, resource_key: audience_key}
  end

  defp command_resource(%Command.ApplyAudienceMutation{audience_key: audience_key}) do
    %{resource_type: :audience, resource_key: audience_key}
  end

  defp command_resource(%Command.ListAudienceDependencies{audience_key: audience_key}) do
    %{resource_type: :dependency_inventory, resource_key: audience_key || "*"}
  end

  defp command_resource(%Command.SubmitChangeRequest{
         resource_type: resource_type,
         resource_key: resource_key
       }) do
    %{resource_type: stringify_resource(resource_type), resource_key: resource_key}
  end

  defp command_resource(%Command.ScheduleGovernedAction{
         resource_type: resource_type,
         resource_key: resource_key
       }) do
    %{resource_type: stringify_resource(resource_type), resource_key: resource_key}
  end

  defp command_resource(%Command.RollbackAuditEvent{audit_event_id: audit_event_id}) do
    %{resource_type: :audit_event, resource_key: audit_event_id}
  end

  defp command_resource(command)
       when is_map(command) do
    metadata = Map.get(command, :metadata, %{})

    case {Map.get(metadata, "resource_type"), Map.get(metadata, "resource_key")} do
      {nil, _} ->
        %{resource_type: :flag, resource_key: Map.get(command, :flag_key)}

      {resource_type, resource_key} ->
        %{resource_type: stringify_resource(resource_type), resource_key: resource_key}
    end
  end

  defp command_action(:submit_change_request, _command), do: :submit_change_request
  defp command_action(:approve_change_request, _command), do: :approve_change_request
  defp command_action(:reject_change_request, _command), do: :reject_change_request
  defp command_action(:cancel_change_request, _command), do: :cancel_change_request
  defp command_action(:execute_change_request, _command), do: :execute_change_request
  defp command_action(:schedule_change_request, _command), do: :execute_change_request
  defp command_action(:cancel_scheduled_execution, _command), do: :execute_change_request
  defp command_action(:requeue_scheduled_execution, _command), do: :execute_change_request

  defp command_action(:schedule_governed_action, %Command.ScheduleGovernedAction{action: action}),
    do: action

  defp command_action(:engage_kill_switch, _command), do: :engage_kill_switch
  defp command_action(:release_kill_switch, _command), do: :release_kill_switch
  defp command_action(:fetch_guardrail_status, _command), do: :read_rollouts
  defp command_action(:rollback_audit_event, _command), do: :rollback_audit_event
  defp command_action(:list_audit_events, _command), do: :list_audit_events
  defp command_action(:apply_promotion, _command), do: :promote_environment
  defp command_action(:preview_audience_impact, _command), do: :preview_audience_impact
  defp command_action(:list_audience_dependencies, _command), do: :list_audience_dependencies
  defp command_action(:apply_audience_mutation, _command), do: :apply_audience_mutation
  defp command_action(:create_webhook_destination, _command), do: :manage_webhooks
  defp command_action(:update_webhook_destination, _command), do: :manage_webhooks
  defp command_action(:list_webhook_destinations, _command), do: :manage_webhooks
  defp command_action(:fetch_webhook_destination, _command), do: :manage_webhooks
  defp command_action(:list_webhook_deliveries, _command), do: :manage_webhooks
  defp command_action(:retry_webhook_delivery, _command), do: :manage_webhooks
  defp command_action(operation, _command), do: operation

  defp maybe_persist_denied_mutation(operation, command, denied_audit)
       when operation in [
              :save_draft_ruleset,
              :publish_ruleset,
              :advance_rollout,
              :archive_flag,
              :apply_audience_mutation,
              :engage_kill_switch,
              :release_kill_switch,
              :rollback_audit_event
            ] do
    denied_command =
      command
      |> Map.put(:reason, Map.get(command, :reason) || "unauthorized")
      |> Map.put(
        :metadata,
        Map.merge(command.metadata, %{
          audit_result: :denied,
          denied_action: denied_audit.action,
          denied_actor_id: get_in(denied_audit, [:actor, :id])
        })
      )

    _ = run_store(operation, [denied_command], denied_command)
    :ok
  end

  defp maybe_persist_denied_mutation(_operation, _command, _denied_audit), do: :ok

  defp validate_audience_mutation_confirmation(%Command.ApplyAudienceMutation{} = command) do
    cond do
      blank?(command.preview_fingerprint) ->
        {:error,
         StoreError.invalid_command(
           "audience mutation requires preview_fingerprint",
           metadata: %{audience_key: command.audience_key, operation: command.operation}
         )}

      command.preview_schema_version != ImpactPreview.schema_version() ->
        {:error,
         StoreError.invalid_command(
           "audience mutation requires current preview_schema_version",
           metadata: %{
             audience_key: command.audience_key,
             operation: command.operation,
             expected_preview_schema_version: ImpactPreview.schema_version(),
             preview_schema_version: command.preview_schema_version
           }
         )}

      command.operation in ["update", "archive", "delete_attempt"] and blank?(command.reason) ->
        {:error,
         StoreError.invalid_command(
           "audience mutation requires reason",
           metadata: %{audience_key: command.audience_key, operation: command.operation}
         )}

      true ->
        :ok
    end
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false

  defp store_stop_metadata({:ok, value}, operation) do
    value
    |> result_like_metadata()
    |> Map.put_new(:reason, store_success_reason(operation))
  end

  defp store_stop_metadata({:error, %Error{} = error}, _operation) do
    %{reason: error.type}
  end

  defp result_like_metadata(value) when is_map(value) do
    if Map.get(value, :__struct__) == Command.Page do
      %{}
    else
      %{}
      |> Map.put(:flag_key, get_in(value, [:flag, :key]))
      |> Map.put(:flag_type, get_in(value, [:flag, :flag_type]))
      |> Map.put(
        :environment,
        get_in(value, [:environment, :key]) || Map.get(value, :environment_key)
      )
      |> Map.put(
        :snapshot_version,
        Map.get(value, :version) || get_in(value, [:flag_environment, :active_ruleset_version])
      )
    end
  end

  defp result_like_metadata(_value), do: %{}

  defp store_event_kind(operation)
       when operation in [
              :fetch_flag,
              :fetch_snapshot,
              :list_flags,
              :list_environments,
              :list_audiences,
              :list_audience_dependencies
            ],
    do: :read

  defp store_event_kind(_operation), do: :write

  defp store_success_reason(:fetch_snapshot), do: :fetched
  defp store_success_reason(:fetch_flag), do: :fetched
  defp store_success_reason(:list_flags), do: :listed
  defp store_success_reason(:list_audience_dependencies), do: :listed
  defp store_success_reason(_operation), do: :stored

  defp governance_environment(command, metadata) do
    Map.get(command, :environment_key) || Map.get(metadata, "environment_key")
  end

  defp fetch_change_request_for_authorization(change_request_id) do
    case run_store(
           :fetch_change_request,
           [Command.FetchChangeRequest.new(change_request_id)],
           nil
         ) do
      {:ok, %{change_request: change_request}} -> {:ok, change_request}
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp normalize_governance_authorization({:ok, _requirement}), do: :ok

  defp normalize_governance_authorization({:error, error, denied_audit}),
    do: {:error, error, denied_audit}

  defp authorize_direct_scheduled_execution(
         actor,
         %Command.ScheduleGovernedAction{execution_mode: :policy_bypass, action: action} =
           _command,
         resource,
         environment_key,
         _requirement
       ) do
    case Authorizer.authorize_governed_action(actor, action, resource, environment_key) do
      {:ok, requirement} -> {:ok, requirement}
      {:error, error, denied_audit} -> {:error, error, denied_audit}
    end
  end

  defp authorize_direct_scheduled_execution(
         actor,
         %Command.ScheduleGovernedAction{
           execution_mode: :emergency_bypass,
           action: action,
           metadata: metadata,
           reason: reason
         },
         resource,
         environment_key,
         requirement
       ) do
    with :ok <- ensure_emergency_metadata(reason, metadata),
         :ok <- Authorizer.authorize(actor, action, resource, environment_key) do
      {:ok, requirement}
    end
  end

  defp authorize_direct_scheduled_execution(
         _actor,
         %Command.ScheduleGovernedAction{},
         _resource,
         _environment_key,
         _requirement
       ) do
    {:error,
     StoreError.invalid_command(
       "direct scheduled actions must use policy_bypass or emergency_bypass"
     )}
  end

  defp ensure_bounded_scheduled_action(action) do
    if action in Rulestead.Admin.Policy.governance_actions() do
      :ok
    else
      {:error,
       StoreError.invalid_command(
         "scheduled direct actions are limited to publish, rollout, and kill-switch operations"
       )}
    end
  end

  defp ensure_emergency_metadata(reason, metadata) do
    emergency_reason = Map.get(metadata, "emergency_reason")

    cond do
      is_nil(reason) or String.trim(reason) == "" ->
        {:error,
         StoreError.invalid_command("emergency_bypass requires an explicit operator reason")}

      is_nil(emergency_reason) or String.trim(emergency_reason) == "" ->
        {:error,
         StoreError.invalid_command("emergency_bypass requires metadata[\"emergency_reason\"]")}

      true ->
        :ok
    end
  end

  defp promotion_plan_status(compare) do
    cond do
      compare.flags == [] -> "no_changes"
      Compare.protected_target?(compare.target_environment.key) -> "governance_required"
      true -> "changes"
    end
  end

  defp promotion_findings(compare) do
    top_level =
      Enum.map(compare.findings, fn finding ->
        ManifestResult.finding(finding.code, finding.severity, compare.target_environment.key,
          message: finding[:message]
        )
      end)

    dependency_findings =
      compare
      |> Map.get(:dependency_findings, [])
      |> Enum.map(fn finding ->
        scope =
          [
            "source=#{finding.source_environment_key}",
            "target=#{finding.target_environment_key}",
            "tenant=#{finding.tenant_key || "global"}",
            "flag=#{finding.flag_key}",
            "ruleset=#{finding.ruleset_version}",
            "rule=#{finding.rule_key}",
            "audience=#{finding.audience_key}"
          ]
          |> Enum.join("|")

        ManifestResult.finding(finding.code, finding.severity, scope,
          message: finding[:message]
        )
      end)

    per_flag =
      Enum.flat_map(compare.flags, fn flag ->
        Enum.map(flag.findings, fn finding ->
          ManifestResult.finding(finding.code, finding.severity, flag.flag_key,
            message: finding[:message]
          )
        end)
      end)

    ManifestResult.sort_findings(top_level ++ dependency_findings ++ per_flag)
  end

  defp validate_promotion_plan_mode(plan) do
    if plan["mode"] == "promote" do
      :ok
    else
      {:error, Manifest.invalid("apply plan is not a promote plan")}
    end
  end

  defp require_promotion_reason(opts) do
    case Manifest.normalize_string(Keyword.get(opts, :reason)) do
      nil -> {:error, Manifest.invalid("promote apply requires an explicit reason")}
      value -> {:ok, value}
    end
  end

  defp promotion_apply_command(plan, reason, opts) do
    Command.ApplyPromotion.new(
      %{
        source_environment_key: plan["source_environment_key"],
        target_environment_key: plan["target_environment_key"],
        tenant_key: plan["tenant_key"],
        flag_keys: plan["flag_keys"],
        compare_token: plan["compare_token"],
        compare_schema_version: Compare.schema_version(),
        source_fingerprint: plan["source_fingerprint"],
        target_fingerprint: plan["target_fingerprint"],
        dependency_closure_keys: plan["dependency_closure_keys"],
        proposed_target_bundle: plan["proposed_target_bundle"]
      },
      actor: Keyword.get(opts, :actor, default_cli_actor()),
      reason: reason,
      metadata: Keyword.get(opts, :metadata, default_cli_metadata(plan))
    )
  end

  defp dispatch_promotion_plan(plan, command, _reason, _opts) do
    if Compare.protected_target?(plan["target_environment_key"]) or
         plan["status"] == "governance_required" do
      with :ok <- Apply.validate_governed(command),
           approval_requirement <-
             Authorizer.approval_requirement(
               command.actor,
               :promote_environment,
               %{resource_type: "environment", resource_key: plan["target_environment_key"]},
               plan["target_environment_key"]
             ),
           {:ok, %{change_request: change_request}} <-
             submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: :promote_environment,
                   environment_key: plan["target_environment_key"],
                   resource_type: "environment",
                   resource_key: plan["target_environment_key"],
                   command: promotion_governance_command_payload(plan),
                   approval_requirement: approval_requirement
                 },
                 actor: command.actor,
                 reason: command.reason,
                 metadata: command.metadata
               )
             ) do
        {:ok,
         ManifestResult.new(%{
           status: "queued",
           command: "rulestead.promote.apply",
           summary: %{
             "source_environment_key" => plan["source_environment_key"],
             "target_environment_key" => plan["target_environment_key"],
             "flag_count" => length(plan["flag_keys"]),
             "plan_token" => plan["plan_token"],
             "change_request_id" => change_request.id
           },
           details: %{
             "plan" => plan,
             "change_request" => Manifest.normalize_map(change_request)
           }
         })}
      end
    else
      with {:ok, result} <- apply_promotion(command) do
        {:ok,
         ManifestResult.new(%{
           status: "applied",
           command: "rulestead.promote.apply",
           summary: %{
             "source_environment_key" => plan["source_environment_key"],
             "target_environment_key" => plan["target_environment_key"],
             "flag_count" => length(plan["flag_keys"]),
             "plan_token" => plan["plan_token"]
           },
           details: %{
             "plan" => plan,
             "apply" => Manifest.normalize_map(result)
           }
         })}
      end
    end
  end

  defp promotion_governance_command_payload(plan) do
    %{
      "source_environment_key" => plan["source_environment_key"],
      "target_environment_key" => plan["target_environment_key"],
      "tenant_key" => plan["tenant_key"],
      "flag_keys" => plan["flag_keys"],
      "compare_token" => plan["compare_token"],
      "compare_schema_version" => Compare.schema_version(),
      "source_fingerprint" => plan["source_fingerprint"],
      "target_fingerprint" => plan["target_fingerprint"],
      "dependency_closure_keys" => plan["dependency_closure_keys"],
      "proposed_target_bundle" => plan["proposed_target_bundle"]
    }
  end

  defp stale_promotion_result(
         content,
         message \\ "saved promote plan no longer matches live compare state"
       ) do
    with {:ok, plan} <- Plan.load(content) do
      {:ok,
       ManifestResult.new(%{
         status: "stale",
         command: "rulestead.promote.apply",
         summary: %{
           "target_environment_key" => plan["target_environment_key"],
           "plan_token" => plan["plan_token"]
         },
         findings: [
           ManifestResult.finding("stale_plan", "blocker", plan["target_environment_key"],
             message: message
           )
         ],
         details: %{"plan" => plan}
       })}
    end
  end

  defp validate_target_tenant(plan, opts) do
    live_tenant = Rulestead.Manifest.normalize_string(Keyword.get(opts, :tenant_key))
    plan_tenant = plan["tenant_key"]

    if live_tenant == plan_tenant do
      :ok
    else
      {:error, StoreError.invalid_command("promotion target tenant drifted")}
    end
  end

  defp map_promotion_apply_error(content, %Error{} = error) do
    status =
      cond do
        String.contains?(error.message, "drifted") or String.contains?(error.message, "stale") ->
          "stale"

        String.contains?(error.message, "dependency") or
            String.contains?(error.message, "blocker") ->
          "blocked"

        true ->
          "invalid"
      end

    with {:ok, plan} <- Plan.load(content) do
      {:ok,
       ManifestResult.new(%{
         status: status,
         command: "rulestead.promote.apply",
         summary: %{
           "target_environment_key" => plan["target_environment_key"],
           "plan_token" => plan["plan_token"]
         },
         findings: [
           ManifestResult.finding(
             promotion_status_code(status),
             "blocker",
             plan["target_environment_key"],
             message: error.message
           )
         ],
         details: %{
           "plan" => plan,
           "error" => Manifest.normalize_map(%{message: error.message, type: error.type})
         }
       })}
    end
  end

  defp promotion_status_code("stale"), do: "stale_plan"
  defp promotion_status_code("blocked"), do: "blocked_promotion"
  defp promotion_status_code(_status), do: "invalid_promotion"

  defp default_cli_actor do
    %{id: "rulestead-cli", type: "system", display: "Rulestead CLI", roles: [:admin]}
  end

  defp default_cli_metadata(plan) do
    %{request_id: plan["plan_token"], source: :mix_task}
  end

  defp governance_change_request_resource(change_request, fallback_resource) do
    case {Map.get(change_request, :resource_type), Map.get(change_request, :resource_key)} do
      {nil, nil} ->
        fallback_resource

      {resource_type, resource_key} ->
        %{resource_type: stringify_resource(resource_type), resource_key: resource_key}
    end
  end

  defp stringify_resource(resource_type) when is_binary(resource_type) do
    resource_type
    |> String.trim()
    |> case do
      "" -> :flag
      "flag" -> :flag
      "audit_event" -> :audit_event
      "ruleset" -> :ruleset
      _ -> :flag
    end
  end

  defp stringify_resource(resource_type) when is_atom(resource_type), do: resource_type
  defp stringify_resource(_resource_type), do: :flag
end
