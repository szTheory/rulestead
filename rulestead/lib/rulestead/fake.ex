# credo:disable-for-this-file
defmodule Rulestead.Fake do
  @moduledoc false
  # Contract-faithful in-memory store adapter for tests.

  # The fake reuses the same command structs, error taxonomy, and ruleset
  # validation semantics as the real store contract. Test-only reset, clock, and
  # inspection helpers live in `Rulestead.Fake.Control`.

  use GenServer

  alias Ecto.Changeset

  alias Rulestead.{
    Admin.Redaction,
    Admin.Lifecycle,
    Audience,
    AuditEvent,
    Environment,
    EnvironmentVersion,
    Flag,
    Guardrails.AutoAdvance,
    Guardrails.Decision,
    Guardrails.SignalFact,
    Governance.Approval,
    Governance.AudienceMutationChangeRequest,
    Governance.BlastRadiusThreshold,
    Governance.ChangeRequest,
    Governance.ExecutionAttempt,
    Governance.RolloutAutoAdvance,
    Governance.RolloutAutoAdvance.Schedule,
    Governance.ScheduledExecution,
    Manifest.Import,
    Promotion.Apply,
    Promotion.Compare,
    RolloutAutoAdvancePolicy,
    Ruleset,
    RulesetError,
    Store,
    StoreError,
    Targeting.AudienceDependencies,
    Targeting.DependencyInventory,
    Targeting.DependencyValidator,
    Targeting.ImpactPreview,
    Telemetry
  }

  alias Rulestead.Runtime.{Config, Notifier}
  alias Rulestead.Store.Command

  @behaviour Store

  @default_now ~U[2026-01-01 00:00:00Z]
  @snapshot_schema_version 1

  @type state :: %{
          now: DateTime.t(),
          environments: %{required(String.t()) => map()},
          audiences: %{required(String.t()) => map()},
          flags: %{required(String.t()) => map()},
          change_requests: %{required(String.t()) => map()},
          approvals: %{required(String.t()) => [map()]},
          scheduled_executions: %{required(String.t()) => map()},
          execution_attempts: %{required(String.t()) => [map()]},
          guardrail_decisions: [map()],
          auto_advance_policies: %{required(tuple()) => map()},
          audit_events: [map()],
          environment_versions: %{required(String.t()) => %{required(pos_integer()) => map()}},
          snapshots: %{required(String.t()) => %{required(pos_integer()) => map()}},
          webhook_receipts: %{required(String.t()) => map()},
          webhook_replay_claims: %{required(String.t()) => %{required(String.t()) => String.t()}},
          webhook_destinations: %{required(String.t()) => map()},
          webhook_outbound_events: %{required(String.t()) => map()},
          webhook_deliveries: %{required(String.t()) => map()},
          audience_reference_projection: %{required(tuple()) => map()},
          snapshot_reads_connected?: boolean()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @impl Store
  def fetch_flag(%Command.FetchFlag{} = command) do
    call({:fetch_flag, command})
  end

  @impl Store
  def compare_environments(%Command.CompareEnvironments{} = command) do
    call({:compare_environments, command})
  end

  @impl Store
  def apply_promotion(%Command.ApplyPromotion{} = command) do
    call({:apply_promotion, command})
  end

  @impl Store
  def preview_manifest_import(%Command.PreviewManifestImport{} = command) do
    call({:preview_manifest_import, command})
  end

  @impl Store
  def apply_manifest_import(%Command.ApplyManifestImport{} = command) do
    call({:apply_manifest_import, command})
  end

  @impl Store
  def fetch_snapshot(%Command.FetchSnapshot{} = command) do
    call({:fetch_snapshot, command})
  end

  @impl Store
  def create_flag(%Command.CreateFlag{} = command) do
    call({:create_flag, command})
  end

  @impl Store
  def update_flag(%Command.UpdateFlag{} = command) do
    call({:update_flag, command})
  end

  @impl Store
  def save_draft_ruleset(%Command.SaveDraftRuleset{} = command) do
    call({:save_draft_ruleset, command})
  end

  @impl Store
  def publish_ruleset(%Command.PublishRuleset{} = command) do
    call({:publish_ruleset, command})
  end

  @impl Store
  def archive_flag(%Command.ArchiveFlag{} = command) do
    call({:archive_flag, command})
  end

  @impl Store
  def list_flags(%Command.ListFlags{} = command) do
    call({:list_flags, command})
  end

  @impl Store
  def list_environments(%Command.ListEnvironments{} = command) do
    call({:list_environments, command})
  end

  @impl Store
  def list_audiences(%Command.ListAudiences{} = command) do
    call({:list_audiences, command})
  end

  @impl Store
  @spec list_audience_dependencies(Command.ListAudienceDependencies.t()) ::
          {:ok,
           %{
             entries: [DependencyInventory.entry()],
             limit: pos_integer(),
             offset: non_neg_integer(),
             returned: non_neg_integer(),
             total_count: non_neg_integer()
           }}
          | {:error, Rulestead.Error.t()}
  def list_audience_dependencies(%Command.ListAudienceDependencies{} = command) do
    call({:list_audience_dependencies, command})
  end

  def list_audience_dependencies(command) when is_map(command) do
    command
    |> list_audience_dependencies_command()
    |> list_audience_dependencies()
  end

  @doc false
  @spec rebuild_audience_reference_projection() ::
          {:ok, %{deleted_rows: non_neg_integer(), inserted_rows: non_neg_integer()}}
          | {:error, Rulestead.Error.t()}
  def rebuild_audience_reference_projection do
    call(:rebuild_audience_reference_projection)
  end

  @impl Store
  def preview_audience_impact(%Command.PreviewAudienceImpact{} = command) do
    call({:preview_audience_impact, command})
  end

  @impl Store
  def apply_audience_mutation(%Command.ApplyAudienceMutation{} = command) do
    call({:apply_audience_mutation, command})
  end

  @impl Store
  def record_evaluation(%Command.RecordEvaluation{} = command) do
    call({:record_evaluation, command})
  end

  @impl Store
  def advance_rollout(%Command.AdvanceRollout{} = command) do
    call({:advance_rollout, command})
  end

  @impl Store
  def evaluate_guarded_rollout(%Command.EvaluateGuardedRollout{} = command) do
    call({:evaluate_guarded_rollout, command})
  end

  @impl Store
  def upsert_rollout_auto_advance_policy(%Command.UpsertRolloutAutoAdvancePolicy{} = command) do
    call({:upsert_rollout_auto_advance_policy, command})
  end

  @impl Store
  def fetch_rollout_auto_advance_policy(%Command.FetchRolloutAutoAdvancePolicy{} = command) do
    call({:fetch_rollout_auto_advance_policy, command})
  end

  @impl Store
  def evaluate_rollout_auto_advance(%Command.EvaluateRolloutAutoAdvance{} = command) do
    call({:evaluate_rollout_auto_advance, command})
  end

  @impl Store
  def fetch_guardrail_status(%Command.FetchGuardrailStatus{} = command) do
    call({:fetch_guardrail_status, command})
  end

  @impl Store
  def engage_kill_switch(%Command.EngageKillSwitch{} = command) do
    call({:engage_kill_switch, command})
  end

  @impl Store
  def release_kill_switch(%Command.ReleaseKillSwitch{} = command) do
    call({:release_kill_switch, command})
  end

  @impl Store
  def list_audit_events(%Command.ListAuditEvents{} = command) do
    call({:list_audit_events, command})
  end

  @impl Store
  def rollback_audit_event(%Command.RollbackAuditEvent{} = command) do
    call({:rollback_audit_event, command})
  end

  @impl Store
  def submit_change_request(%Command.SubmitChangeRequest{} = command) do
    call({:submit_change_request, command})
  end

  @impl Store
  def approve_change_request(%Command.ApproveChangeRequest{} = command) do
    call({:approve_change_request, command})
  end

  @impl Store
  def reject_change_request(%Command.RejectChangeRequest{} = command) do
    call({:reject_change_request, command})
  end

  @impl Store
  def cancel_change_request(%Command.CancelChangeRequest{} = command) do
    call({:cancel_change_request, command})
  end

  @impl Store
  def execute_change_request(%Command.ExecuteChangeRequest{} = command) do
    call({:execute_change_request, command})
  end

  @impl Store
  def fetch_change_request(%Command.FetchChangeRequest{} = command) do
    call({:fetch_change_request, command})
  end

  @impl Store
  def list_change_requests(%Command.ListChangeRequests{} = command) do
    call({:list_change_requests, command})
  end

  @impl Store
  def schedule_change_request(%Command.ScheduleChangeRequest{} = command) do
    call({:schedule_change_request, command})
  end

  @impl Store
  def schedule_governed_action(%Command.ScheduleGovernedAction{} = command) do
    call({:schedule_governed_action, command})
  end

  @impl Store
  def cancel_scheduled_execution(%Command.CancelScheduledExecution{} = command) do
    call({:cancel_scheduled_execution, command})
  end

  @impl Store
  def requeue_scheduled_execution(%Command.RequeueScheduledExecution{} = command) do
    call({:requeue_scheduled_execution, command})
  end

  @impl Store
  def execute_scheduled_execution(%Command.ExecuteScheduledExecution{} = command) do
    call({:execute_scheduled_execution, command})
  end

  @impl Store
  def fetch_scheduled_execution(%Command.FetchScheduledExecution{} = command) do
    call({:fetch_scheduled_execution, command})
  end

  @impl Store
  def list_scheduled_executions(%Command.ListScheduledExecutions{} = command) do
    call({:list_scheduled_executions, command})
  end

  @impl Store
  def receive_inbound_webhook(%Command.ReceiveInboundWebhook{} = command) do
    call({:receive_inbound_webhook, command})
  end

  @impl Store
  def fetch_webhook_record(%Command.FetchWebhookRecord{} = command) do
    call({:fetch_webhook_record, command})
  end

  @impl Store
  def list_webhook_records(%Command.ListWebhookRecords{} = command) do
    call({:list_webhook_records, command})
  end

  @impl Store
  def create_webhook_destination(%Command.CreateWebhookDestination{} = command) do
    call({:create_webhook_destination, command})
  end

  @impl Store
  def update_webhook_destination(%Command.UpdateWebhookDestination{} = command) do
    call({:update_webhook_destination, command})
  end

  @impl Store
  def fetch_webhook_destination(%Command.FetchWebhookDestination{} = command) do
    call({:fetch_webhook_destination, command})
  end

  @impl Store
  def list_webhook_destinations(%Command.ListWebhookDestinations{} = command) do
    call({:list_webhook_destinations, command})
  end

  @impl Store
  def list_webhook_deliveries(%Command.ListWebhookDeliveries{} = command) do
    call({:list_webhook_deliveries, command})
  end

  @impl Store
  def retry_webhook_delivery(%Command.RetryWebhookDelivery{} = command) do
    call({:retry_webhook_delivery, command})
  end

  @doc false
  def reset(opts \\ []) do
    call({:control, :reset, opts})
  end

  @doc false
  def put_environment(attrs) when is_map(attrs) do
    call({:control, :put_environment, attrs})
  end

  @doc false
  def put_flag(attrs) when is_map(attrs) do
    call({:control, :put_flag, attrs})
  end

  @doc false
  def put_audience(attrs) when is_map(attrs) do
    call({:control, :put_audience, attrs})
  end

  @doc false
  def snapshot do
    call({:control, :snapshot})
  end

  @doc false
  def now do
    call({:control, :now})
  end

  @doc false
  def set_now(%DateTime{} = now) do
    call({:control, :set_now, now})
  end

  @doc false
  def advance_time(seconds) when is_integer(seconds) do
    call({:control, :advance_time, seconds})
  end

  @impl GenServer
  def init(_opts) do
    {:ok, new_state()}
  end

  @impl GenServer
  def handle_call({:control, :reset, opts}, _from, _state) do
    now = Keyword.get(opts, :now, @default_now)
    {:reply, :ok, new_state(now)}
  end

  def handle_call({:control, :put_environment, attrs}, _from, state) do
    case do_put_environment(state, attrs) do
      {:ok, environment, next_state} -> {:reply, {:ok, environment}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:control, :put_flag, attrs}, _from, state) do
    case do_put_flag(state, attrs) do
      {:ok, flag_state, next_state} -> {:reply, {:ok, flag_state}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:control, :put_audience, attrs}, _from, state) do
    case do_put_audience(state, attrs) do
      {:ok, audience, next_state} -> {:reply, {:ok, audience}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:control, :snapshot}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:control, :restore, restored_state}, _from, _state)
      when is_map(restored_state) do
    next_state =
      restored_state
      |> ensure_projection_state()
      |> rebuild_audience_reference_projection_state()

    {:reply, :ok, next_state}
  end

  def handle_call({:control, :now}, _from, state) do
    {:reply, {:ok, state.now}, state}
  end

  def handle_call({:control, :set_now, now}, _from, state) do
    next_state = %{state | now: now}
    {:reply, {:ok, now}, next_state}
  end

  def handle_call({:control, :disconnect}, _from, state) do
    {:reply, :ok, %{state | snapshot_reads_connected?: false}}
  end

  def handle_call({:control, :reconnect}, _from, state) do
    {:reply, :ok, %{state | snapshot_reads_connected?: true}}
  end

  def handle_call({:control, :latest_snapshot, environment_key}, _from, state) do
    reply =
      case state.snapshots
           |> Map.get(to_string(environment_key), %{})
           |> Enum.max_by(&elem(&1, 0), fn -> nil end) do
        nil -> {:error, StoreError.snapshot_not_found(environment_key)}
        {_version, snapshot} -> {:ok, snapshot}
      end

    {:reply, reply, state}
  end

  def handle_call({:control, :advance_time, seconds}, _from, state) do
    now = DateTime.add(state.now, seconds, :second)
    next_state = %{state | now: now}
    {:reply, {:ok, now}, next_state}
  end

  def handle_call({:fetch_flag, command}, _from, state) do
    reply =
      with_fetch_context(state, command.flag_key, command.environment_key, fn flag,
                                                                              environment,
                                                                              flag_environment ->
        {:ok,
         build_flag_detail_payload(
           state,
           flag,
           environment,
           flag_environment,
           command.include_ruleset?
         )}
      end)

    {:reply, reply, state}
  end

  def handle_call({:compare_environments, command}, _from, state) do
    {:reply, compare_environments_in_state(state, command), state}
  end

  def handle_call({:apply_promotion, command}, _from, state) do
    if Compare.protected_target?(command.target_environment_key) do
      {:reply,
       {:error, StoreError.invalid_command("promotion to protected targets requires governance")},
       state}
    else
      case do_apply_promotion(state, command, allow_protected_target?: false) do
        {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
        {:error, error} -> {:reply, {:error, error}, state}
      end
    end
  end

  def handle_call({:preview_manifest_import, command}, _from, state) do
    reply =
      with {:ok, target_manifest} <- Rulestead.export_manifest(command.target_environment_key) do
        {:ok,
         Import.preview(command.manifest, target_manifest,
           target_environment_key: command.target_environment_key
         )}
      end

    {:reply, reply, state}
  end

  def handle_call({:apply_manifest_import, command}, _from, state) do
    case do_apply_manifest_import(state, command, allow_protected_target?: false) do
      {:ok, result, next_state} -> {:reply, {:ok, result}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:fetch_snapshot, command}, _from, state) do
    reply =
      if state.snapshot_reads_connected? do
        with {:ok, environment} <- fetch_environment(state, command.environment_key),
             {:ok, snapshot} <- fetch_runtime_snapshot(state, environment.key, command.version) do
          {:ok, snapshot}
        end
      else
        {:error, StoreError.unavailable()}
      end

    {:reply, reply, state}
  end

  def handle_call({:create_flag, command}, _from, state) do
    attrs = %{
      key: command.key,
      description: command.description,
      flag_type: command.flag_type,
      value_type: command.value_type,
      default_value: command.default_value,
      ownership: command.ownership,
      lifecycle: command.lifecycle,
      tags: command.tags,
      environment_keys: command.environment_keys
    }

    case do_put_flag(state, attrs) do
      {:ok, flag_payload, next_state} -> {:reply, {:ok, flag_payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:update_flag, command}, _from, state) do
    flag_key = to_string(command.flag_key)

    reply =
      case Map.fetch(state.flags, flag_key) do
        :error ->
          {:error, StoreError.flag_not_found(command.flag_key, :all)}

        {:ok, flag} ->
          with :ok <- ensure_not_archived(command.flag_key, flag),
               {:ok, updated_flag} <- apply_flag_update(flag, command, state.now) do
            next_state = put_in(state.flags[flag_key], updated_flag)
            {:ok, build_update_payload(next_state, updated_flag), next_state}
          end
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:save_draft_ruleset, command}, _from, state) do
    case audit_only_result(state, command, "ruleset.save_draft") do
      {:ok, result, next_state} ->
        {:reply, result, next_state}

      :continue ->
        case with_mutable_context(state, command.flag_key, command.environment_key, fn flag,
                                                                                       environment,
                                                                                       flag_environment ->
               version = next_ruleset_version(flag, environment.key)

               attrs = %{
                 flag_environment_id: flag_environment.id,
                 version: version,
                 status: :draft,
                 salt: Map.get(command.ruleset, :salt) || Map.get(command.ruleset, "salt"),
                 published_at: nil,
                 metadata:
                   Map.get(command.ruleset, :metadata) || Map.get(command.ruleset, "metadata") ||
                     %{},
                 rules:
                   Map.get(command.ruleset, :rules) || Map.get(command.ruleset, "rules") || []
               }

               changeset = Ruleset.changeset(%Ruleset{}, attrs)

               case Changeset.apply_action(changeset, :insert) do
                 {:ok, ruleset} ->
                   ruleset_record = serialize_ruleset(ruleset, state.now)

                   next_state =
                     put_ruleset(state, command.flag_key, environment.key, ruleset_record)

                   {:ok, %{version: ruleset_record.version, ruleset: ruleset_record}, next_state}

                 {:error, invalid_changeset} ->
                   {:error,
                    ruleset_error(invalid_changeset, command.flag_key, command.environment_key)}
               end
             end) do
          {:ok, result, next_state} -> {:reply, {:ok, result}, next_state}
          {:error, error} -> {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:publish_ruleset, command}, _from, state) do
    case audit_only_result(state, command, "ruleset.publish") do
      {:ok, result, next_state} ->
        {:reply, result, next_state}

      :continue ->
        case with_mutable_context(state, command.flag_key, command.environment_key, fn flag,
                                                                                       environment,
                                                                                       flag_environment ->
               case resolve_publishable_ruleset(flag, environment.key, command.version) do
                 {:ok, ruleset_record} ->
                  dependency_entries =
                    publish_dependency_entries(environment.key, command, flag, ruleset_record)

                  dependency_findings = validate_dependency_entries(state, command, dependency_entries)

                  if DependencyValidator.blockers?(dependency_findings) do
                    error =
                      DependencyValidator.to_error(dependency_findings,
                        message: "ruleset publish blocked by dependency validation"
                      )

                    {audit_event, blocked_state} =
                      append_audit_event(state, command, "ruleset.publish_blocked", :error,
                        metadata: %{
                          "version" => ruleset_record.version,
                          "blockers" => dependency_blockers(dependency_findings),
                          "dependency_findings" =>
                            serialize_dependency_findings(dependency_findings)
                        }
                      )

                    {:dependency_blocked, error,
                     %{blocked_state | audit_events: [audit_event | blocked_state.audit_events]}}
                  else
                    before_ruleset =
                      active_ruleset_payload(
                        flag,
                        environment.key,
                        flag_environment.active_ruleset_version
                      )

                    {:ok, next_state} =
                      publish_ruleset_record(
                        state,
                        command.flag_key,
                        environment.key,
                        flag_environment,
                        ruleset_record
                      )

                    refreshed_flag = next_state.flags[to_string(command.flag_key)]
                    refreshed_flag_environment = refreshed_flag.environments[environment.key]

                    payload =
                      build_flag_detail_payload(
                        next_state,
                        refreshed_flag,
                        environment,
                        refreshed_flag_environment,
                        true
                      )

                    {audit_event, next_state} =
                      append_audit_event(next_state, command, "ruleset.publish", :ok,
                        before: ruleset_audit_state(before_ruleset),
                        after: ruleset_audit_state(ruleset_record),
                        diff: ruleset_position_diff(before_ruleset, ruleset_record),
                        metadata: %{version: ruleset_record.version}
                      )

                    {:ok, payload,
                     %{next_state | audit_events: [audit_event | next_state.audit_events]}}
                  end

                 {:error, error} ->
                   {:error, error}
               end
             end) do
          {:ok, result, next_state} -> {:reply, {:ok, result}, next_state}
          {:dependency_blocked, error, next_state} -> {:reply, {:error, error}, next_state}
          {:error, error} -> {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:archive_flag, command}, _from, state) do
    flag_key = to_string(command.flag_key)

    case audit_only_result(state, command, "flag.archive") do
      {:ok, result, next_state} ->
        {:reply, result, next_state}

      :continue ->
        case Map.fetch(state.flags, flag_key) do
          :error ->
            {:reply, {:error, StoreError.flag_not_found(command.flag_key, :all)}, state}

          {:ok, flag} ->
            archived_at = flag.archived_at || state.now

            archived_flag =
              flag
              |> Map.put(:archived_at, archived_at)
              |> Map.put(:updated_at, state.now)
              |> Map.update!(:environments, fn environments ->
                Map.new(environments, fn {environment_key, flag_environment} ->
                  {
                    environment_key,
                    flag_environment
                    |> Map.put(:status, :archived)
                    |> Map.put(:updated_at, state.now)
                  }
                end)
              end)

            next_state =
              put_in(state.flags[flag_key], archived_flag)
              |> rebuild_flag_snapshots(archived_flag)

            payload = build_archive_payload(archived_flag)
            {:reply, {:ok, payload}, next_state}
        end
    end
  end

  def handle_call({:list_flags, command}, _from, state) do
    reply =
      with_list_environment(state, command.environment_key, fn environment_filter ->
        entries =
          state.flags
          |> Map.values()
          |> Enum.flat_map(&list_entries_for_flag(&1, state.environments, environment_filter))
          |> Enum.reject(fn entry ->
            archived?(entry.flag) and not command.include_archived?
          end)
          |> Enum.filter(&matches_query?(&1, command.query))
          |> Enum.map(&build_list_entry(state, &1))
          |> maybe_filter_owner(command.owner)
          |> maybe_filter_tags(command.tags)
          |> maybe_filter_lifecycle(command.lifecycle)
          |> maybe_filter_stale(command.stale)
          |> maybe_filter_readiness(command.readiness)
          |> maybe_filter_evidence_quality(command.evidence_quality)
          |> maybe_filter_flag_type(command.flag_type)
          |> sort_entries(command.sort)

        {:ok, paginate_entries(entries, command)}
      end)

    {:reply, reply, state}
  end

  def handle_call({:list_environments, command}, _from, state) do
    environments =
      state.environments
      |> Map.values()
      |> Enum.filter(&matches_environment_query?(&1, command.query))
      |> Enum.sort_by(& &1.key)
      |> Enum.take(command.limit)

    {:reply, {:ok, environments}, state}
  end

  def handle_call({:list_audiences, command}, _from, state) do
    audiences =
      state
      |> Map.get(:audiences, %{})
      |> Map.values()
      |> Enum.reject(fn audience ->
        Map.get(audience, :archived_at) && not command.include_archived?
      end)
      |> Enum.filter(&matches_audience_query?(&1, command.query))
      |> Enum.sort_by(& &1.key)
      |> Enum.take(command.limit)

    {:reply, {:ok, audiences}, state}
  end

  def handle_call({:list_audience_dependencies, command}, _from, state) do
    all_entries =
      state.audience_reference_projection
      |> Map.values()
      |> maybe_filter_projection_scope(command)
      |> DependencyInventory.sort_entries()

    limit = command_limit(command)
    offset = command_offset(command)
    page_entries = all_entries |> Enum.drop(offset) |> Enum.take(limit)
    redacted = Redaction.redact_dependency_inventory(page_entries, redaction_options(command))

    {:reply,
     {:ok,
      %{
        entries: redacted.entries,
        reference_count: redacted.reference_count,
        hidden_reference_count: redacted.hidden_reference_count,
        redacted: redacted.redacted,
        redacted_entries: redacted.redacted_entries,
        limit: limit,
        offset: offset,
        returned: length(redacted.entries),
        total_count: length(all_entries)
      }}, state}
  end

  def handle_call(:rebuild_audience_reference_projection, _from, state) do
    next_state = rebuild_audience_reference_projection_state(state)

    {:reply,
     {:ok,
      %{
        deleted_rows: map_size(state.audience_reference_projection),
        inserted_rows: map_size(next_state.audience_reference_projection)
      }}, next_state}
  end

  def handle_call({:preview_audience_impact, command}, _from, state) do
    {:reply, build_audience_preview(state, command), state}
  end

  def handle_call({:apply_audience_mutation, command}, _from, state) do
    case audit_only_result(state, command, audience_event_type(command.operation)) do
      {:ok, result, next_state} ->
        {:reply, result, next_state}

      :continue ->
        case do_apply_audience_mutation(state, command) do
          {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
          {:dependency_blocked, error, next_state} -> {:reply, {:error, error}, next_state}
          {:blast_radius_blocked, error, next_state} -> {:reply, {:error, error}, next_state}
          {:error, error} -> {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:record_evaluation, command}, _from, state) do
    reply =
      with {:ok, environment} <- fetch_environment(state, command.environment_key),
           {:ok, _flag, flag_environment} <-
             fetch_flag_environment(state, command.flag_key, environment.key) do
        timestamp = DateTime.truncate(command.last_evaluated_at, :microsecond)

        next_timestamp =
          case flag_environment[:last_evaluated_at] do
            %DateTime{} = existing ->
              case DateTime.compare(existing, timestamp) do
                :gt -> existing
                _ -> timestamp
              end

            _ ->
              timestamp
          end

        next_state =
          put_in(
            state.flags[to_string(command.flag_key)].environments[environment.key].last_evaluated_at,
            next_timestamp
          )

        {:ok,
         %{
           flag_key: to_string(command.flag_key),
           environment_key: environment.key,
           last_evaluated_at: next_timestamp
         }, next_state}
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:advance_rollout, command}, _from, state) do
    case with_mutable_context(state, command.flag_key, command.environment_key, fn flag,
                                                                                   environment,
                                                                                   flag_environment ->
           with {:ok, active_ruleset} <-
                  ensure_active_ruleset_in_state(flag_environment, flag, environment.key),
                {:ok, rollout_rule} <-
                  resolve_rollout_rule_in_state(active_ruleset, command.rule_key),
                {:ok, percentage} <- ensure_rollout_percentage_in_state(command.percentage),
                {:ok, next_ruleset_attrs} <-
                  advanced_ruleset_attrs_in_state(active_ruleset, rollout_rule.key, percentage) do
             version = next_ruleset_version(state, command.flag_key, environment.key)

             ruleset = %{
               id: Ecto.UUID.generate(),
               version: version,
               status: :published,
               salt: next_ruleset_attrs.salt,
               published_at: state.now,
               metadata: next_ruleset_attrs.metadata,
               rules: next_ruleset_attrs.rules,
               inserted_at: state.now,
               updated_at: state.now
             }

             next_state =
               state
               |> put_ruleset(command.flag_key, environment.key, ruleset)
               |> put_in(
                 [:flags, to_string(command.flag_key), :environments, environment.key],
                 %{
                   flag_environment
                   | active_ruleset_version: version,
                     status: :active,
                     last_published_at: state.now,
                     updated_at: state.now
                 }
               )
               |> put_runtime_snapshot(environment.key)

             decision =
               build_guardrail_decision(%{
                 flag_key: command.flag_key,
                 environment_key: environment.key,
                 rule_key: rollout_rule.key,
                 stage: command.stage,
                 decision_state: :pending_data,
                 action_type: :advance,
                 decision_reason: "monitoring_window_active",
                 effective_percentage: percentage,
                 rollout_salt: rollout_rule.rollout.salt,
                 variant_fingerprint: variant_fingerprint_in_state(rollout_rule),
                 monitoring_window_started_at: command.monitoring_window_started_at || state.now,
                 monitoring_window_ends_at: command.monitoring_window_ends_at,
                 occurred_at: state.now,
                 signal_facts: Enum.map(command.signal_facts, &SignalFact.metadata/1),
                 guardrail_evidence: first_guardrail_evidence_in_state(command.signal_facts),
                 authored_snapshot: ruleset,
                 correlation_id: command.metadata["request_id"] || Ecto.UUID.generate(),
                 metadata: command.metadata
               })

             {audit_event, next_state} =
               append_audit_event(next_state, command, "rollout.advance", :ok,
                 before: ruleset_audit_state(active_ruleset),
                 after: ruleset_audit_state(ruleset),
                 diff: ruleset_position_diff(active_ruleset, ruleset),
                 links: %{"guardrail_decision_id" => decision.id}
               )

             next_state = %{
               next_state
               | guardrail_decisions: [decision | next_state.guardrail_decisions],
                 audit_events: [audit_event | next_state.audit_events]
             }

             next_state = maybe_schedule_auto_advance_tick_in_state(next_state, command)

             {:ok, guardrail_status_payload_in_state(decision, version), next_state}
           end
         end) do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:evaluate_guarded_rollout, command}, _from, state) do
    case with_mutable_context(state, command.flag_key, command.environment_key, fn flag,
                                                                                   environment,
                                                                                   flag_environment ->
           with {:ok, active_ruleset} <-
                  ensure_active_ruleset_in_state(flag_environment, flag, environment.key),
                {:ok, rollout_rule} <-
                  resolve_rollout_rule_in_state(active_ruleset, command.rule_key) do
             evaluated =
               Decision.evaluate(command.signal_facts,
                 evaluated_at: state.now,
                 monitoring_window_ends_at: command.monitoring_window_ends_at
               )

             persist_guardrail_evaluation_in_state(
               state,
               command,
               environment,
               flag_environment,
               active_ruleset,
               rollout_rule,
               evaluated
             )
           end
         end) do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:upsert_rollout_auto_advance_policy, command}, _from, state) do
    case upsert_rollout_auto_advance_policy_in_state(state, command) do
      {:ok, policy, next_state} -> {:reply, {:ok, %{policy: policy}}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:fetch_rollout_auto_advance_policy, command}, _from, state) do
    case fetch_rollout_auto_advance_policy_in_state(state, command) do
      {:ok, policy} -> {:reply, {:ok, %{policy: policy}}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:evaluate_rollout_auto_advance, command}, _from, state) do
    case evaluate_rollout_auto_advance_in_state(state, command) do
      {:ok, eligibility} -> {:reply, {:ok, %{eligibility: eligibility}}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:fetch_guardrail_status, command}, _from, state) do
    case fetch_guardrail_status_in_state(state, command) do
      {:ok, payload} -> {:reply, {:ok, payload}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:engage_kill_switch, command}, _from, state) do
    case audit_only_result(state, command, "kill_switch.engage") do
      {:ok, result, next_state} ->
        {:reply, result, next_state}

      :continue ->
        case with_mutable_context(state, command.flag_key, command.environment_key, fn _flag,
                                                                                       environment,
                                                                                       flag_environment ->
               updated_flag_environment =
                 flag_environment
                 |> Map.put(:status, :killswitched)
                 |> Map.put(:kill_switch_variant_key, "default")
                 |> Map.put(:updated_at, state.now)

               next_state =
                 put_in(
                   state.flags[to_string(command.flag_key)].environments[environment.key],
                   updated_flag_environment
                 )
                 |> put_runtime_snapshot(environment.key)

               {audit_event, next_state} =
                 append_audit_event(next_state, command, "kill_switch.engage", :ok,
                   before: audit_state(flag_environment),
                   after: audit_state(updated_flag_environment)
                 )

               payload =
                 build_flag_detail_payload(
                   next_state,
                   next_state.flags[to_string(command.flag_key)],
                   environment,
                   updated_flag_environment,
                   true
                 )

               {:ok, payload,
                %{next_state | audit_events: [audit_event | next_state.audit_events]}}
             end) do
          {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
          {:error, error} -> {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:release_kill_switch, command}, _from, state) do
    case audit_only_result(state, command, "kill_switch.release") do
      {:ok, result, next_state} ->
        {:reply, result, next_state}

      :continue ->
        case with_mutable_context(state, command.flag_key, command.environment_key, fn _flag,
                                                                                       environment,
                                                                                       flag_environment ->
               updated_flag_environment =
                 flag_environment
                 |> Map.put(
                   :status,
                   if(flag_environment.status == :killswitched,
                     do: :active,
                     else: flag_environment.status || :active
                   )
                 )
                 |> Map.put(:kill_switch_variant_key, nil)
                 |> Map.put(:updated_at, state.now)

               next_state =
                 put_in(
                   state.flags[to_string(command.flag_key)].environments[environment.key],
                   updated_flag_environment
                 )
                 |> put_runtime_snapshot(environment.key)

               {audit_event, next_state} =
                 append_audit_event(next_state, command, "kill_switch.release", :ok,
                   before: audit_state(flag_environment),
                   after: audit_state(updated_flag_environment)
                 )

               payload =
                 build_flag_detail_payload(
                   next_state,
                   next_state.flags[to_string(command.flag_key)],
                   environment,
                   updated_flag_environment,
                   true
                 )

               {:ok, payload,
                %{next_state | audit_events: [audit_event | next_state.audit_events]}}
             end) do
          {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
          {:error, error} -> {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:list_audit_events, command}, _from, state) do
    entries =
      state.audit_events
      |> Enum.filter(&matches_audit_filter?(&1, command))
      |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
      |> Enum.take(command.limit)

    page = %Command.Page{
      entries: entries,
      limit: command.limit,
      has_next_page?: false,
      has_previous_page?: false
    }

    {:reply, {:ok, page}, state}
  end

  def handle_call({:rollback_audit_event, command}, _from, state) do
    case Enum.find(state.audit_events, &(&1.id == command.audit_event_id)) do
      nil ->
        {:reply, {:error, StoreError.invalid_command("audit event was not found")}, state}

      audit_event ->
        inverse_command =
          case audit_event.event_type do
            "kill_switch.engage" ->
              Command.ReleaseKillSwitch.new(audit_event.resource_key, audit_event.environment_key,
                actor: command.actor,
                reason: command.reason,
                metadata: Map.put(command.metadata, :rollback_of_event_id, audit_event.id)
              )

            "kill_switch.release" ->
              Command.EngageKillSwitch.new(audit_event.resource_key, audit_event.environment_key,
                actor: command.actor,
                reason: command.reason,
                metadata: Map.put(command.metadata, :rollback_of_event_id, audit_event.id)
              )

            _other ->
              nil
          end

        if is_nil(inverse_command) do
          {:reply, {:error, StoreError.invalid_command("audit event cannot be rolled back")},
           state}
        else
          case do_rollback(state, inverse_command, command, audit_event) do
            {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
            {:error, error} -> {:reply, {:error, error}, state}
          end
        end
    end
  end

  def handle_call({:submit_change_request, command}, _from, state) do
    with {:ok, command} <- prepare_audience_mutation_change_request(state, command) do
      correlation_id = governance_correlation_id(command)

      change_request =
        %{
          id: Ecto.UUID.generate(),
          status: "submitted",
          governed_action: Atom.to_string(command.action),
          environment_key: command.environment_key,
          resource_type: command.resource_type,
          resource_key: command.resource_key,
          submitter_id: get_in(command.actor || %{}, ["id"]),
          submitter_type: get_in(command.actor || %{}, ["type"]) || "operator",
          submitter_display: get_in(command.actor || %{}, ["display"]),
          reason: command.reason,
          approval_requirement_snapshot: command.approval_requirement,
          command_snapshot: Command.GovernanceSupport.with_tenant_provenance(command.command),
          metadata: command.metadata,
          correlation_id: correlation_id,
          submitted_at: state.now,
          resolved_at: nil,
          executed_at: nil,
          inserted_at: state.now,
          updated_at: state.now
        }

      audit_command = governance_audit_command(command, change_request, "submitted")

      {audit_event, next_state} =
        append_audit_event(state, audit_command, "change_request.submitted", :ok,
          resource_key: change_request.resource_key,
          environment_key: change_request.environment_key
        )

      final_state =
        next_state
        |> put_in([:change_requests, change_request.id], change_request)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)
        |> enqueue_webhook_deliveries(
          "change_request.submitted",
          fn ->
            %{
              "change_request_id" => change_request.id,
              "status" => change_request.status,
              "governed_action" => change_request.governed_action,
              "reason" => change_request.reason,
              "submitter" => %{
                "id" => change_request.submitter_id,
                "type" => change_request.submitter_type,
                "display" => change_request.submitter_display
              }
            }
          end,
          environment_key: command.environment_key,
          resource_type: command.resource_type || "flag",
          resource_key: command.resource_key
        )

      emit_governance_telemetry(:submitted, audit_command, change_request, audit_event)

      {:reply, {:ok, %{change_request: serialize_change_request(change_request)}}, final_state}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:approve_change_request, command}, _from, state) do
    with {:ok, change_request} <- fetch_change_request_record(state, command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["submitted"]),
         :ok <- ensure_unique_reviewer(state, change_request.id, command) do
      approval =
        %{
          id: Ecto.UUID.generate(),
          change_request_id: change_request.id,
          decision: "approved",
          reviewer_id: get_in(command.actor || %{}, ["id"]),
          reviewer_type: get_in(command.actor || %{}, ["type"]) || "operator",
          reviewer_display: get_in(command.actor || %{}, ["display"]),
          reason: command.reason,
          metadata: command.metadata,
          correlation_id: change_request.correlation_id,
          reviewed_at: state.now,
          inserted_at: state.now
        }

      approvals = Map.get(state.approvals, change_request.id, []) ++ [approval]
      approved_count = Enum.count(approvals, &(&1.decision == "approved"))

      next_status =
        if approved_count >= required_approvals(change_request.approval_requirement_snapshot) do
          "approved"
        else
          "submitted"
        end

      updated_change_request =
        change_request
        |> Map.put(:status, next_status)
        |> Map.put(:resolved_at, if(next_status == "approved", do: state.now, else: nil))
        |> Map.put(:updated_at, state.now)

      audit_command =
        governance_audit_command(command, updated_change_request, "approved")
        |> Map.update!(:metadata, &Map.put(&1, "approval_id", approval.id))

      {audit_event, next_state} =
        append_audit_event(state, audit_command, "change_request.approved", :ok)

      final_state =
        next_state
        |> put_in([:change_requests, change_request.id], updated_change_request)
        |> put_in([:approvals, change_request.id], approvals)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)

      emit_governance_telemetry(:approved, audit_command, updated_change_request, audit_event)

      {:reply,
       {:ok,
        %{
          change_request: serialize_change_request(updated_change_request),
          approval: serialize_approval(approval)
        }}, final_state}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:reject_change_request, command}, _from, state) do
    with {:ok, change_request} <- fetch_change_request_record(state, command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["submitted"]) do
      approval =
        %{
          id: Ecto.UUID.generate(),
          change_request_id: change_request.id,
          decision: "rejected",
          reviewer_id: get_in(command.actor || %{}, ["id"]),
          reviewer_type: get_in(command.actor || %{}, ["type"]) || "operator",
          reviewer_display: get_in(command.actor || %{}, ["display"]),
          reason: command.reason,
          metadata: command.metadata,
          correlation_id: change_request.correlation_id,
          reviewed_at: state.now,
          inserted_at: state.now
        }

      updated_change_request =
        change_request
        |> Map.put(:status, "rejected")
        |> Map.put(:resolved_at, state.now)
        |> Map.put(:updated_at, state.now)

      audit_command =
        governance_audit_command(command, updated_change_request, "rejected")
        |> Map.update!(:metadata, fn metadata ->
          Map.merge(metadata, audience_mutation_terminal_metadata(change_request, command.reason))
        end)
        |> Map.update!(:metadata, &Map.put(&1, "approval_id", approval.id))

      {audit_event, next_state} =
        append_audit_event(state, audit_command, "change_request.rejected", :ok)

      final_state =
        next_state
        |> put_in([:change_requests, change_request.id], updated_change_request)
        |> update_in([:approvals, change_request.id], fn approvals ->
          (approvals || []) ++ [approval]
        end)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)

      emit_governance_telemetry(:rejected, audit_command, updated_change_request, audit_event)

      {:reply, {:ok, %{change_request: serialize_change_request(updated_change_request)}},
       final_state}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:cancel_change_request, command}, _from, state) do
    with {:ok, change_request} <- fetch_change_request_record(state, command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["submitted", "approved"]) do
      updated_change_request =
        change_request
        |> Map.put(:status, "cancelled")
        |> Map.put(:resolved_at, state.now)
        |> Map.put(:updated_at, state.now)

      audit_command =
        governance_audit_command(command, updated_change_request, "cancelled")
        |> Map.update!(:metadata, fn metadata ->
          Map.merge(metadata, audience_mutation_terminal_metadata(change_request, command.reason))
        end)

      {audit_event, next_state} =
        append_audit_event(state, audit_command, "change_request.cancelled", :ok)

      final_state =
        next_state
        |> put_in([:change_requests, change_request.id], updated_change_request)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)

      {:reply, {:ok, %{change_request: serialize_change_request(updated_change_request)}},
       final_state}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:execute_change_request, command}, _from, state) do
    with {:ok, change_request} <- fetch_change_request_record(state, command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["approved"]) do
      case execute_governed_change(state, change_request, command) do
        {:ok, execution_result, next_state} ->
          updated_change_request =
            change_request
            |> Map.put(:status, "executed")
            |> Map.put(:resolved_at, state.now)
            |> Map.put(:executed_at, state.now)
            |> Map.put(:updated_at, state.now)

          audit_command = governance_audit_command(command, updated_change_request, "merged")

          {audit_event, post_audit_state} =
            append_audit_event(next_state, audit_command, "change_request.merged", :ok)

          final_state =
            post_audit_state
            |> put_in([:change_requests, change_request.id], updated_change_request)
            |> update_in([:audit_events], fn events -> [audit_event | events] end)

          emit_governance_telemetry(:merged, audit_command, updated_change_request, audit_event)

          {:reply,
           {:ok,
            %{
              change_request: serialize_change_request(updated_change_request),
              execution_result: execution_result
            }}, final_state}

        {:error, error, next_state} ->
          {:reply, {:error, error}, next_state}

        {:error, error} ->
          {:reply, {:error, error}, state}
      end
    else
      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:fetch_change_request, command}, _from, state) do
    reply =
      with {:ok, change_request} <- fetch_change_request_record(state, command.change_request_id) do
        {:ok,
         %{
           change_request: serialize_change_request(change_request),
           approvals:
             state.approvals
             |> Map.get(change_request.id, [])
             |> Enum.map(&serialize_approval/1),
           audit_events: related_audit_events(state, change_request)
         }}
      end

    {:reply, reply, state}
  end

  def handle_call({:list_change_requests, command}, _from, state) do
    entries =
      state.change_requests
      |> Map.values()
      |> Enum.filter(&matches_change_request_filter?(&1, command))
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(command.limit)
      |> Enum.map(&serialize_change_request/1)

    {:reply,
     {:ok,
      %Command.Page{
        entries: entries,
        limit: command.limit,
        has_next_page?: false,
        has_previous_page?: false
      }}, state}
  end

  def handle_call({:schedule_change_request, command}, _from, state) do
    reply =
      with {:ok, change_request} <- fetch_change_request_record(state, command.change_request_id),
           :ok <- ensure_governance_transition(change_request, ["approved"]) do
        scheduled_execution =
          new_scheduled_execution_record(state, %{
            change_request_id: change_request.id,
            governed_action: change_request.governed_action,
            environment_key: change_request.environment_key,
            resource_type: change_request.resource_type,
            resource_key: change_request.resource_key,
            execution_mode: "change_request",
            scheduled_by_id: actor_value(command.actor, "id"),
            scheduled_by_type: actor_value(command.actor, "type") || "operator",
            scheduled_by_display: actor_value(command.actor, "display"),
            approved_by_snapshot: approved_snapshot(state, change_request.id),
            scheduled_for: command.scheduled_for,
            command_snapshot: change_request.command_snapshot,
            approval_requirement_snapshot: change_request.approval_requirement_snapshot,
            metadata:
              Command.GovernanceSupport.with_tenant_provenance(
                command.metadata,
                change_request.command_snapshot
              ),
            correlation_id: change_request.correlation_id,
            idempotency_key: "scheduled_execution:change_request:#{change_request.id}"
          })

        next_state =
          put_in(state.scheduled_executions[scheduled_execution.id], scheduled_execution)

        {:ok,
         %{scheduled_execution: serialize_scheduled_execution(scheduled_execution), attempts: []},
         next_state}
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:schedule_governed_action, command}, _from, state) do
    {:ok, payload, next_state} = schedule_governed_action_in_state(state, command)
    {:reply, {:ok, payload}, next_state}
  end

  def handle_call({:cancel_scheduled_execution, command}, _from, state) do
    reply =
      with {:ok, scheduled_execution} <-
             fetch_scheduled_execution_record(state, command.scheduled_execution_id),
           :ok <- ensure_scheduled_transition(scheduled_execution.state, ["scheduled", "running"]) do
        updated =
          scheduled_execution
          |> Map.put(:state, "cancelled")
          |> Map.put(:failure_reason, command.reason)
          |> Map.put(
            :execution_metadata,
            scheduled_transition_metadata(
              scheduled_execution.execution_metadata,
              "cancelled",
              command,
              state.now
            )
          )
          |> Map.put(:updated_at, state.now)

        next_state = put_in(state.scheduled_executions[updated.id], updated)

        {:ok, %{scheduled_execution: serialize_scheduled_execution(updated), attempts: []},
         next_state}
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:requeue_scheduled_execution, command}, _from, state) do
    reply =
      with {:ok, scheduled_execution} <-
             fetch_scheduled_execution_record(state, command.scheduled_execution_id),
           :ok <- ensure_scheduled_transition(scheduled_execution.state, ["quarantined"]) do
        updated =
          scheduled_execution
          |> Map.put(:state, "scheduled")
          |> Map.put(:failure_reason, nil)
          |> Map.put(
            :execution_metadata,
            scheduled_transition_metadata(
              scheduled_execution.execution_metadata,
              "requeued",
              command,
              state.now
            )
          )
          |> Map.put(:updated_at, state.now)

        next_state = put_in(state.scheduled_executions[updated.id], updated)

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(updated),
           attempts:
             list_execution_attempts(state, updated.id)
             |> Enum.map(&serialize_execution_attempt/1)
         }, next_state}
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:execute_scheduled_execution, command}, _from, state) do
    case fetch_scheduled_execution_record(state, command.scheduled_execution_id) do
      {:ok, %{state: "completed"} = scheduled_execution} ->
        {:reply,
         {:ok,
          %{
            scheduled_execution: serialize_scheduled_execution(scheduled_execution),
            attempts:
              list_execution_attempts(state, scheduled_execution.id)
              |> Enum.map(&serialize_execution_attempt/1)
          }}, state}

      {:ok, %{state: "cancelled"}} ->
        {:reply, {:error, StoreError.invalid_command("scheduled execution is cancelled")}, state}

      {:ok, %{state: "quarantined"}} ->
        {:reply,
         {:error, StoreError.invalid_command("scheduled execution requires explicit requeue")},
         state}

      {:ok, scheduled_execution} ->
        case run_scheduled_execution(state, scheduled_execution, command) do
          {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
          {:error, error, next_state} -> {:reply, {:error, error}, next_state}
        end

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:fetch_scheduled_execution, command}, _from, state) do
    reply =
      with {:ok, scheduled_execution} <-
             fetch_scheduled_execution_record(state, command.scheduled_execution_id) do
        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(scheduled_execution),
           attempts:
             list_execution_attempts(state, scheduled_execution.id)
             |> Enum.map(&serialize_execution_attempt/1)
         }}
      end

    {:reply, reply, state}
  end

  def handle_call({:list_scheduled_executions, command}, _from, state) do
    entries =
      state.scheduled_executions
      |> Map.values()
      |> Enum.filter(&matches_scheduled_execution_filter?(&1, command))
      |> Enum.sort_by(& &1.scheduled_for, DateTime)
      |> Enum.take(command.limit)
      |> Enum.map(&serialize_scheduled_execution/1)

    {:reply,
     {:ok,
      %Command.Page{
        entries: entries,
        limit: command.limit,
        has_next_page?: false,
        has_previous_page?: false
      }}, state}
  end

  def handle_call({:receive_inbound_webhook, command}, _from, state) do
    if command.verified_state == :accepted and
         get_in(state.webhook_replay_claims, [command.provider, command.delivery_id]) do
      {:reply, {:error, StoreError.invalid_command("duplicate webhook delivery")}, state}
    else
      id = Ecto.UUID.generate()
      correlation_id = command.correlation_id || Ecto.UUID.generate()

      receipt = %{
        id: id,
        provider: command.provider,
        endpoint_key: command.endpoint_key,
        delivery_id: command.delivery_id,
        attempt_id: command.attempt_id,
        topic: command.topic,
        occurred_at: command.occurred_at,
        received_at: command.received_at,
        raw_body_sha256: command.raw_body_sha256,
        verification_metadata: command.verification_metadata,
        normalized_payload: command.normalized_payload,
        dedupe_key: command.dedupe_key,
        verified_state: command.verified_state,
        rejection_reason: command.rejection_reason,
        correlation_id: correlation_id,
        inserted_at: state.now,
        updated_at: state.now
      }

      next_state =
        state
        |> put_in([:webhook_receipts, id], receipt)
        |> maybe_record_replay_claim(command, id)

      {:reply, {:ok, receipt}, next_state}
    end
  end

  def handle_call({:fetch_webhook_record, command}, _from, state) do
    reply =
      case Map.fetch(state.webhook_receipts, command.receipt_id) do
        {:ok, receipt} -> {:ok, receipt}
        :error -> {:error, StoreError.invalid_command("webhook record was not found")}
      end

    {:reply, reply, state}
  end

  def handle_call({:list_webhook_records, command}, _from, state) do
    entries =
      state.webhook_receipts
      |> Map.values()
      |> Enum.filter(&matches_webhook_filter?(&1, command))
      |> Enum.sort_by(& &1.received_at, {:desc, DateTime})
      |> Enum.take(command.limit)

    {:reply,
     {:ok,
      %Command.Page{
        entries: entries,
        limit: command.limit,
        has_next_page?: false,
        has_previous_page?: false
      }}, state}
  end

  def handle_call({:create_webhook_destination, command}, _from, state) do
    id = Ecto.UUID.generate()

    destination = %{
      id: id,
      name: command.name,
      description: command.description,
      url: command.url,
      secret_id: command.secret_id,
      environment_key: command.environment_key,
      subscriptions: command.subscriptions,
      enabled: command.enabled,
      metadata: command.metadata,
      inserted_at: state.now,
      updated_at: state.now
    }

    next_state = put_in(state.webhook_destinations[id], destination)
    {:reply, {:ok, destination}, next_state}
  end

  def handle_call({:update_webhook_destination, command}, _from, state) do
    case Map.fetch(state.webhook_destinations, command.id) do
      {:ok, destination} ->
        attrs =
          %{
            name: command.name,
            description: command.description,
            url: command.url,
            secret_id: command.secret_id,
            subscriptions: command.subscriptions,
            enabled: command.enabled,
            metadata: command.metadata
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()

        updated =
          destination
          |> Map.merge(attrs)
          |> Map.put(:updated_at, state.now)

        next_state = put_in(state.webhook_destinations[command.id], updated)
        {:reply, {:ok, updated}, next_state}

      :error ->
        {:reply, {:error, StoreError.invalid_command("webhook destination was not found")}, state}
    end
  end

  def handle_call({:fetch_webhook_destination, command}, _from, state) do
    reply =
      case Map.fetch(state.webhook_destinations, command.id) do
        {:ok, destination} -> {:ok, destination}
        :error -> {:error, StoreError.invalid_command("webhook destination was not found")}
      end

    {:reply, reply, state}
  end

  def handle_call({:list_webhook_destinations, command}, _from, state) do
    entries =
      state.webhook_destinations
      |> Map.values()
      |> Enum.filter(&matches_destination_filter?(&1, command))
      |> Enum.sort_by(& &1.name)
      |> Enum.take(command.limit)

    {:reply,
     {:ok,
      %Command.Page{
        entries: entries,
        limit: command.limit,
        has_next_page?: false,
        has_previous_page?: false
      }}, state}
  end

  def handle_call({:list_webhook_deliveries, command}, _from, state) do
    entries =
      state.webhook_deliveries
      |> Map.values()
      |> Enum.filter(&matches_delivery_filter?(&1, command))
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(command.limit)
      |> Enum.map(&enrich_delivery(&1, state))

    {:reply,
     {:ok,
      %Command.Page{
        entries: entries,
        limit: command.limit,
        has_next_page?: false,
        has_previous_page?: false
      }}, state}
  end

  def handle_call({:retry_webhook_delivery, command}, _from, state) do
    case Map.fetch(state.webhook_deliveries, command.delivery_id) do
      {:ok, delivery} ->
        updated = %{
          delivery
          | state: :pending,
            attempt_count: 0,
            terminal_failure_reason: nil,
            updated_at: state.now
        }

        next_state = put_in(state.webhook_deliveries[command.delivery_id], updated)
        {:reply, {:ok, enrich_delivery(updated, state)}, next_state}

      :error ->
        {:reply, {:error, StoreError.invalid_command("delivery was not found")}, state}
    end
  end

  defp call(message), do: call(message, false)

  defp call(message, restarted?) do
    case Process.whereis(__MODULE__) do
      nil ->
        {:error, StoreError.unavailable(details: [%{message: "fake store is not started"}])}

      _pid ->
        try do
          GenServer.call(__MODULE__, message)
        catch
          :exit, reason ->
            maybe_retry_call(message, reason, restarted?)
        end
    end
  end

  defp maybe_retry_call(message, {:noproc, _details}, false) do
    restart_for_retry()
    call(message, true)
  end

  defp maybe_retry_call(message, {{:noproc, _details}, _stack}, false) do
    restart_for_retry()
    call(message, true)
  end

  defp maybe_retry_call(_message, reason, _restarted?) do
    {:error,
     StoreError.unavailable(
       details: [%{message: "fake store is not started", reason: inspect(reason)}]
     )}
  end

  defp restart_for_retry do
    case start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, _reason} -> :ok
    end
  end

  defp new_state(now \\ @default_now) do
    %{
      now: now,
      environments: %{},
      audiences: %{},
      change_requests: %{},
      approvals: %{},
      scheduled_executions: %{},
      execution_attempts: %{},
      guardrail_decisions: [],
      auto_advance_policies: %{},
      audit_events: [],
      environment_versions: %{},
      flags: %{},
      snapshots: %{},
      webhook_receipts: %{},
      webhook_replay_claims: %{},
      webhook_destinations: %{},
      webhook_outbound_events: %{},
      webhook_deliveries: %{},
      audience_reference_projection: %{},
      snapshot_reads_connected?: true
    }
    |> seed_default_environment("development", "Development")
    |> seed_default_environment("staging", "Staging")
    |> seed_default_environment("production", "Production")
    |> seed_default_environment("test", "Test")
  end

  defp seed_default_environment(state, key, name) do
    environment = %{
      id: Ecto.UUID.generate(),
      key: key,
      name: name,
      description: nil,
      inserted_at: state.now,
      updated_at: state.now
    }

    put_in(state.environments[key], environment)
  end

  defp do_put_environment(state, attrs) do
    changeset = Environment.changeset(%Environment{}, attrs)

    with {:ok, environment} <- Changeset.apply_action(changeset, :insert) do
      key = environment.key

      if Map.has_key?(state.environments, key) do
        {:error,
         StoreError.invalid_command(
           "environment key already exists",
           metadata: %{environment_key: key}
         )}
      else
        record = %{
          id: Ecto.UUID.generate(),
          key: key,
          name: environment.name,
          description: environment.description,
          inserted_at: state.now,
          updated_at: state.now
        }

        next_state = put_in(state.environments[key], record)

        {:ok, record, next_state}
      end
    else
      {:error, changeset_error} ->
        {:error,
         StoreError.invalid_command(
           "environment seed is invalid",
           details: collect_changeset_details(changeset_error),
           cause: changeset_error
         )}
    end
  end

  defp do_put_flag(state, attrs) do
    environment_keys = normalize_environment_keys(attrs)

    flag_attrs = Map.drop(attrs, [:environment_keys, "environment_keys"])
    extra_attrs = Map.take(flag_attrs, [:code_reference_count, :code_refs_scan])
    changeset = Flag.changeset(%Flag{}, flag_attrs)

    with {:ok, flag} <- Changeset.apply_action(changeset, :insert),
         :ok <- ensure_environment_keys(state, environment_keys) do
      if Map.has_key?(state.flags, flag.key) do
        {:error,
         StoreError.invalid_command(
           "flag key already exists",
           metadata: %{flag_key: flag.key}
         )}
      else
        {flag_record, next_state} = build_flag_record(state, flag, environment_keys, extra_attrs)
        {:ok, build_create_payload(next_state, flag_record), next_state}
      end
    else
      {:error, %Changeset{} = changeset_error} ->
        {:error,
         StoreError.invalid_command(
           "flag seed is invalid",
           details: collect_changeset_details(changeset_error),
           cause: changeset_error
         )}

      {:error, %Rulestead.Error{} = error} ->
        {:error, error}
    end
  end

  defp do_put_audience(state, attrs) do
    normalized_attrs =
      attrs
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.update("key", nil, &Command.GovernanceSupport.normalize_string/1)
      |> Map.update("definition", %{}, &Command.GovernanceSupport.normalize_map/1)

    changeset = Audience.changeset(%Audience{}, normalized_attrs)

    with {:ok, audience} <- Changeset.apply_action(changeset, :insert) do
      record = %{
        id: Ecto.UUID.generate(),
        key: audience.key,
        tenant_key: Command.GovernanceSupport.normalize_string(normalized_attrs["tenant_key"]),
        description: audience.description,
        definition: audience.definition,
        archived_at: audience.archived_at,
        inserted_at: state.now,
        updated_at: state.now
      }

      {:ok, record, put_in(state.audiences[audience.key], record)}
    else
      {:error, changeset_error} ->
        {:error,
         StoreError.invalid_command(
           "audience seed is invalid",
           details: collect_changeset_details(changeset_error),
           cause: changeset_error
         )}
    end
  end

  defp fetch_environment_from_state(state, environment_key) do
    case Map.get(state.environments, to_string(environment_key)) do
      nil -> {:error, StoreError.environment_not_found(environment_key)}
      environment -> {:ok, environment}
    end
  end

  defp compare_payloads_for_environment(state, environment_key) do
    state.flags
    |> Enum.reduce(%{}, fn {flag_key, flag}, payloads ->
      case Map.get(flag.environments, environment_key) do
        nil ->
          payloads

        flag_environment ->
          environment = state.environments[environment_key]

          Map.put(
            payloads,
            flag_key,
            build_flag_payload(flag, environment, flag_environment, true)
          )
      end
    end)
  end

  defp ensure_projection_state(state) do
    state
    |> Map.put_new(:audience_reference_projection, %{})
    |> Map.put_new(:auto_advance_policies, %{})
  end

  defp auto_advance_policy_key(flag_key, environment_key, rule_key) do
    {to_string(flag_key), to_string(environment_key), to_string(rule_key)}
  end

  defp upsert_rollout_auto_advance_policy_in_state(state, command) do
    with :ok <- Command.UpsertRolloutAutoAdvancePolicy.validate_required_fields(command),
         {:ok, policy} <- validate_auto_advance_policy_changeset(command) do
      key = auto_advance_policy_key(command.flag_key, command.environment_key, command.rule_key)
      existing = Map.get(state.auto_advance_policies, key)
      now = state.now

      policy_map =
        policy
        |> Map.from_struct()
        |> Map.take([
          :flag_key,
          :environment_key,
          :rule_key,
          :enabled,
          :observation_window_seconds,
          :next_stage,
          :next_percentage,
          :metadata
        ])
        |> Map.merge(%{
          id: get_in(existing, [:id]) || Ecto.UUID.generate(),
          inserted_at: get_in(existing, [:inserted_at]) || now,
          updated_at: now
        })

      next_state = put_in(state.auto_advance_policies[key], policy_map)
      {:ok, policy_map, next_state}
    else
      {:error, %Changeset{} = changeset} ->
        {:error, auto_advance_policy_changeset_error(changeset, command)}

      {:error, errors} when is_map(errors) ->
        {:error,
         StoreError.invalid_command("rollout auto-advance policy is invalid",
           details: auto_advance_policy_field_errors(errors)
         )}
    end
  end

  @doc false
  def fetch_guardrail_status_in_state(state, command) do
    decision =
      state.guardrail_decisions
      |> Enum.filter(fn entry ->
        entry.flag_key == to_string(command.flag_key) and
          entry.environment_key == to_string(command.environment_key) and
          (is_nil(command.rule_key) or entry.rule_key == command.rule_key) and
          (is_nil(command.stage) or entry.stage == command.stage)
      end)
      |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
      |> List.first()

    case decision do
      nil ->
        {:error, StoreError.invalid_command("guardrail status was not found")}

      decision ->
        active_ruleset_version =
          state.flags[to_string(command.flag_key)].environments[
            to_string(command.environment_key)
          ].active_ruleset_version

        {:ok, guardrail_status_payload_in_state(decision, active_ruleset_version)}
    end
  end

  @doc false
  def fetch_flag_in_state(state, command) do
    with_fetch_context(state, command.flag_key, command.environment_key, fn flag,
                                                                            environment,
                                                                            flag_environment ->
      {:ok,
       build_flag_detail_payload(
         state,
         flag,
         environment,
         flag_environment,
         command.include_ruleset?
       )}
    end)
  end

  @doc false
  def fetch_rollout_auto_advance_policy_in_state(state, command) do
    key = auto_advance_policy_key(command.flag_key, command.environment_key, command.rule_key)

    case Map.get(state.auto_advance_policies, key) do
      nil -> {:error, rollout_auto_advance_policy_not_found_error(command)}
      policy -> {:ok, policy}
    end
  end

  @doc false
  def evaluate_rollout_auto_advance_in_state(state, command) do
    with {:ok, policy} <- fetch_rollout_auto_advance_policy_in_state(state, command) do
      evaluated_at =
        command.evaluated_at ||
          state.now
          |> DateTime.truncate(:second)

      AutoAdvance.evaluate_eligibility(policy, %{
        signal_facts: command.signal_facts,
        monitoring_window_ends_at: command.monitoring_window_ends_at,
        evaluated_at: evaluated_at
      })
      |> case do
        {:ok, eligibility} -> {:ok, eligibility}
      end
    end
  end

  @doc false
  def submit_change_request_in_state(state, command) do
    with {:ok, command} <- prepare_audience_mutation_change_request(state, command) do
      correlation_id = governance_correlation_id(command)

      change_request =
        %{
          id: Ecto.UUID.generate(),
          status: "submitted",
          governed_action: Atom.to_string(command.action),
          environment_key: command.environment_key,
          resource_type: command.resource_type,
          resource_key: command.resource_key,
          submitter_id: get_in(command.actor || %{}, ["id"]),
          submitter_type: get_in(command.actor || %{}, ["type"]) || "operator",
          submitter_display: get_in(command.actor || %{}, ["display"]),
          reason: command.reason,
          approval_requirement_snapshot: command.approval_requirement,
          command_snapshot: Command.GovernanceSupport.with_tenant_provenance(command.command),
          metadata: command.metadata,
          correlation_id: correlation_id,
          submitted_at: state.now,
          resolved_at: nil,
          executed_at: nil,
          inserted_at: state.now,
          updated_at: state.now
        }

      audit_command = governance_audit_command(command, change_request, "submitted")

      {audit_event, next_state} =
        append_audit_event(state, audit_command, "change_request.submitted", :ok,
          resource_key: change_request.resource_key,
          environment_key: change_request.environment_key
        )

      final_state =
        next_state
        |> put_in([:change_requests, change_request.id], change_request)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)
        |> enqueue_webhook_deliveries(
          "change_request.submitted",
          fn ->
            %{
              "change_request_id" => change_request.id,
              "status" => change_request.status,
              "governed_action" => change_request.governed_action,
              "reason" => change_request.reason,
              "submitter" => %{
                "id" => change_request.submitter_id,
                "type" => change_request.submitter_type,
                "display" => change_request.submitter_display
              }
            }
          end,
          environment_key: command.environment_key,
          resource_type: command.resource_type || "flag",
          resource_key: command.resource_key
        )

      emit_governance_telemetry(:submitted, audit_command, change_request, audit_event)

      {:ok, change_request, final_state}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp validate_auto_advance_policy_changeset(command) do
    %RolloutAutoAdvancePolicy{}
    |> RolloutAutoAdvancePolicy.changeset(auto_advance_policy_attrs(command))
    |> Changeset.apply_action(:insert)
  end

  defp auto_advance_policy_attrs(%Command.UpsertRolloutAutoAdvancePolicy{} = command) do
    %{
      flag_key: command.flag_key,
      environment_key: command.environment_key,
      rule_key: command.rule_key,
      enabled: command.enabled,
      observation_window_seconds: command.observation_window_seconds,
      next_stage: command.next_stage,
      next_percentage: command.next_percentage,
      metadata: command.metadata
    }
  end

  defp auto_advance_policy_changeset_error(changeset, command) do
    StoreError.invalid_command("rollout auto-advance policy is invalid",
      metadata: %{
        flag_key: command.flag_key,
        environment_key: command.environment_key,
        rule_key: command.rule_key
      },
      details: changeset_errors_to_details(changeset)
    )
  end

  defp auto_advance_policy_field_errors(errors) do
    Enum.map(errors, fn {field, message} ->
      %{field: to_string(field), message: message}
    end)
  end

  defp rollout_auto_advance_policy_not_found_error(command) do
    StoreError.invalid_command("rollout_auto_advance_policy_not_found",
      metadata: %{
        flag_key: command.flag_key,
        environment_key: command.environment_key,
        rule_key: command.rule_key
      }
    )
  end

  defp changeset_errors_to_details(changeset) do
    Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        %{field: to_string(field), message: message}
      end)
    end)
  end

  defp rebuild_audience_reference_projection_state(state) do
    projection =
      state.environments
      |> Map.keys()
      |> Enum.sort()
      |> Enum.reduce(%{}, fn environment_key, acc ->
        Map.merge(acc, projection_entries_for_environment(state, environment_key))
      end)

    %{state | audience_reference_projection: projection}
  end

  defp refresh_audience_reference_projection(state, environment_key) do
    normalized_environment_key = normalize_projection_environment_key(environment_key)

    retained =
      state.audience_reference_projection
      |> Enum.reject(fn {key, _entry} -> elem(key, 0) == normalized_environment_key end)
      |> Map.new()

    refreshed = projection_entries_for_environment(state, normalized_environment_key)

    %{state | audience_reference_projection: Map.merge(retained, refreshed)}
  end

  defp projection_entries_for_environment(state, environment_key) do
    state
    |> compare_payloads_for_environment(environment_key)
    |> Map.values()
    |> projection_entries_from_payloads()
    |> Enum.into(%{}, fn entry -> {projection_identity_key(entry), entry} end)
  end

  defp projection_entries_from_payloads(payloads) do
    payloads
    |> Enum.flat_map(&payload_projection_entries/1)
    |> Enum.reduce(%{}, fn entry, acc ->
      key = projection_identity_key(entry)
      Map.update(acc, key, entry, &Map.update!(&1, :reference_count, fn count -> count + 1 end))
    end)
    |> Map.values()
  end

  defp payload_projection_entries(payload) do
    payload
    |> projection_rules()
    |> Enum.flat_map(fn rule ->
      if projection_rule_strategy(rule) == "segment_match" do
        [
          DependencyInventory.normalize_entry(%{
            environment_key: payload_environment_key(payload),
            tenant_key: payload_tenant_key(payload),
            flag_key: get_in(payload, [:flag, :key]),
            ruleset_version: get_in(payload, [:active_ruleset, :version]),
            rule_key: projection_rule_key(rule),
            audience_key: projection_rule_audience_key(rule),
            ruleset_status: get_in(payload, [:active_ruleset, :status]),
            rollout_context: projection_rollout_context(rule),
            lifecycle_context: normalize_projection_context(payload.flag.lifecycle),
            visibility: %{status: "visible"},
            reference_count: 1,
            hidden_reference_count: 0
          })
        ]
      else
        []
      end
    end)
    |> Enum.reject(& &1.malformed?)
  end

  defp projection_rules(%{active_ruleset: %{rules: rules}}) when is_list(rules), do: rules
  defp projection_rules(_payload), do: []

  defp payload_environment_key(payload) do
    get_in(payload, [:environment, :key])
  end

  defp payload_tenant_key(payload) do
    payload
    |> Map.get(:tenant_key, Map.get(payload, "tenant_key"))
    |> case do
      nil -> "global"
      value -> to_string(value)
    end
  end

  defp projection_rule_strategy(rule) do
    rule
    |> Map.get(:strategy, Map.get(rule, "strategy"))
    |> to_string()
  end

  defp projection_rule_key(rule) do
    rule
    |> Map.get(:key, Map.get(rule, "key"))
    |> to_string()
  end

  defp projection_rule_audience_key(rule) do
    case Map.get(rule, :audience_key, Map.get(rule, "audience_key")) do
      nil -> nil
      value -> to_string(value)
    end
  end

  defp projection_rollout_context(rule) do
    case Map.get(rule, :rollout, Map.get(rule, "rollout")) do
      rollout when is_map(rollout) -> normalize_projection_context(rollout)
      _other -> %{}
    end
  end

  defp normalize_projection_context(%_{} = value) do
    value
    |> Map.from_struct()
    |> normalize_projection_context()
  end

  defp normalize_projection_context(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {key, normalize_projection_context(nested)} end)
  end

  defp normalize_projection_context(value) when is_list(value) do
    Enum.map(value, &normalize_projection_context/1)
  end

  defp normalize_projection_context(value), do: value

  defp publish_dependency_entries(environment_key, command, flag, ruleset) do
    tenant_key = publish_scope_tenant(command)
    flag_key = to_string(flag.key)

    ruleset_dependency_entries(environment_key, tenant_key, flag_key, ruleset)
  end

  defp ruleset_dependency_entries(environment_key, tenant_key, flag_key, ruleset) do
    rules = Map.get(ruleset, :rules) || Map.get(ruleset, "rules") || []
    ruleset_version = Map.get(ruleset, :version) || Map.get(ruleset, "version")
    ruleset_status = Map.get(ruleset, :status) || Map.get(ruleset, "status")

    rules
    |> Enum.flat_map(fn rule ->
      if projection_rule_strategy(rule) == "segment_match" do
        [
          DependencyInventory.normalize_entry(%{
            environment_key: environment_key,
            tenant_key: tenant_key || "global",
            audience_key: projection_rule_audience_key(rule),
            flag_key: flag_key,
            ruleset_version: ruleset_version,
            rule_key: projection_rule_key(rule),
            ruleset_status: ruleset_status,
            rollout_context: projection_rollout_context(rule),
            lifecycle_context: %{available?: false},
            visibility: %{status: "visible"},
            reference_count: 1,
            hidden_reference_count: 0,
            audience_schema_version: rule_audience_schema_version(rule),
            audience_version_hash: rule_audience_version_hash(rule)
          })
        ]
      else
        []
      end
    end)
    |> Enum.reject(&(&1.malformed? or is_nil(&1.audience_key)))
    |> DependencyInventory.sort_entries()
  end

  defp validate_dependency_entries(state, command, dependency_entries, opts \\ []) do
    findings =
      DependencyValidator.validate(
        %{
          tenant_key: publish_scope_tenant(command),
          audiences: Map.get(state, :audiences, %{}),
          expected_reference_keys: Keyword.get(opts, :expected_reference_keys),
          stale_reference_keys: Keyword.get(opts, :stale_reference_keys)
        },
        dependency_entries
      )

    DependencyValidator.sort_findings(findings)
  end

  defp publish_scope_tenant(command) do
    command
    |> Command.GovernanceSupport.tenant_provenance()
    |> Map.get("tenant_key")
  end

  defp rule_audience_schema_version(rule) do
    metadata = rule_metadata(rule)

    Map.get(rule, :audience_schema_version) ||
      Map.get(rule, "audience_schema_version") ||
      Map.get(metadata, :audience_schema_version) ||
      Map.get(metadata, "audience_schema_version")
  end

  defp rule_audience_version_hash(rule) do
    metadata = rule_metadata(rule)

    Map.get(rule, :audience_version_hash) ||
      Map.get(rule, "audience_version_hash") ||
      Map.get(metadata, :audience_version_hash) ||
      Map.get(metadata, "audience_version_hash")
  end

  defp rule_metadata(%_{} = rule), do: rule |> Map.from_struct() |> rule_metadata()

  defp rule_metadata(rule) when is_map(rule) do
    Map.get(rule, :metadata) || Map.get(rule, "metadata") || %{}
  end

  defp rule_metadata(_rule), do: %{}

  defp dependency_blockers(findings) when is_list(findings) do
    Enum.map(findings, fn finding ->
      %{
        "code" => to_string(Map.get(finding, :code)),
        "environment_key" => Map.get(finding, :environment_key),
        "tenant_key" => Map.get(finding, :tenant_key),
        "flag_key" => Map.get(finding, :flag_key),
        "ruleset_version" => Map.get(finding, :ruleset_version),
        "rule_key" => Map.get(finding, :rule_key),
        "audience_key" => Map.get(finding, :audience_key)
      }
    end)
  end

  defp dependency_blockers(_findings), do: []

  defp serialize_dependency_findings(findings) when is_list(findings) do
    Enum.map(findings, fn finding ->
      %{
        "code" => to_string(Map.get(finding, :code)),
        "severity" => to_string(Map.get(finding, :severity)),
        "message" => Map.get(finding, :message),
        "environment_key" => Map.get(finding, :environment_key),
        "tenant_key" => Map.get(finding, :tenant_key),
        "audience_key" => Map.get(finding, :audience_key),
        "flag_key" => Map.get(finding, :flag_key),
        "ruleset_version" => Map.get(finding, :ruleset_version),
        "rule_key" => Map.get(finding, :rule_key)
      }
    end)
  end

  defp serialize_dependency_findings(_findings), do: []

  defp projection_identity_key(entry) do
    {
      entry.environment_key,
      entry.tenant_key,
      entry.flag_key,
      entry.ruleset_version,
      entry.rule_key,
      entry.audience_key
    }
  end

  defp maybe_filter_projection_scope(entries, command) do
    entries
    |> maybe_filter_projection_environment(Map.get(command, :environment_key))
    |> maybe_filter_projection_tenant(Map.get(command, :tenant_key))
    |> maybe_filter_projection_audience(Map.get(command, :audience_key))
  end

  defp maybe_filter_projection_environment(entries, nil), do: entries

  defp maybe_filter_projection_environment(entries, environment_key) do
    normalized_environment_key = normalize_projection_environment_key(environment_key)
    Enum.filter(entries, &(&1.environment_key == normalized_environment_key))
  end

  defp maybe_filter_projection_tenant(entries, nil), do: entries

  defp maybe_filter_projection_tenant(entries, tenant_key) do
    normalized_tenant_key = normalize_projection_tenant_key(tenant_key)
    Enum.filter(entries, &(&1.tenant_key == normalized_tenant_key))
  end

  defp maybe_filter_projection_audience(entries, nil), do: entries

  defp maybe_filter_projection_audience(entries, audience_key) do
    normalized_audience_key = normalize_projection_audience_key(audience_key)
    Enum.filter(entries, &(&1.audience_key == normalized_audience_key))
  end

  defp command_limit(command) do
    case Map.get(command, :limit) do
      value when is_integer(value) and value > 0 -> value
      _other -> 50
    end
  end

  defp command_offset(command) do
    case Map.get(command, :offset) do
      value when is_integer(value) and value >= 0 -> value
      _other -> 0
    end
  end

  defp list_audience_dependencies_command(%Command.ListAudienceDependencies{} = command), do: command

  defp list_audience_dependencies_command(command) do
    Command.ListAudienceDependencies.new(
      environment_key: Map.get(command, :environment_key) || Map.get(command, "environment_key"),
      tenant_key: Map.get(command, :tenant_key) || Map.get(command, "tenant_key"),
      audience_key: Map.get(command, :audience_key) || Map.get(command, "audience_key"),
      limit: Map.get(command, :limit) || Map.get(command, "limit"),
      offset: Map.get(command, :offset) || Map.get(command, "offset"),
      actor: Map.get(command, :actor) || Map.get(command, "actor"),
      include_redacted_placeholders?:
        Map.get(command, :include_redacted_placeholders?) ||
          Map.get(command, "include_redacted_placeholders?"),
      visible_audience_keys:
        Map.get(command, :visible_audience_keys) || Map.get(command, "visible_audience_keys")
    )
  end

  defp redaction_options(command) do
    base = [
      visible_audience_keys: Map.get(command, :visible_audience_keys),
      include_redacted_placeholders?: Map.get(command, :include_redacted_placeholders?, false)
    ]

    case Map.get(command, :actor) do
      actor when is_map(actor) ->
        Keyword.put(base, :visibility_resolver, Rulestead.Admin.DependencyVisibility.visibility_resolver(actor))

      _ ->
        base
    end
  end

  defp normalize_projection_environment_key(environment_key), do: to_string(environment_key)
  defp normalize_projection_tenant_key(tenant_key), do: to_string(tenant_key)
  defp normalize_projection_audience_key(audience_key), do: to_string(audience_key)

  defp ensure_environment_keys(state, environment_keys) do
    case Enum.find(environment_keys, &(not Map.has_key?(state.environments, &1))) do
      nil -> :ok
      missing_environment -> {:error, StoreError.environment_not_found(missing_environment)}
    end
  end

  defp build_flag_record(state, flag, environment_keys, extra_attrs) do
    flag_id = Ecto.UUID.generate()

    {environments, state} =
      Enum.reduce(environment_keys, {%{}, state}, fn environment_key, {acc, acc_state} ->
        environment = acc_state.environments[environment_key]

        flag_environment = %{
          id: Ecto.UUID.generate(),
          flag_id: flag_id,
          environment_id: environment.id,
          environment_key: environment_key,
          status: :draft,
          kill_switch_variant_key: nil,
          active_ruleset_version: nil,
          last_published_at: nil,
          last_evaluated_at: nil,
          inserted_at: acc_state.now,
          updated_at: acc_state.now
        }

        {Map.put(acc, environment_key, flag_environment), acc_state}
      end)

    flag_record =
      %{
        id: flag_id,
        key: flag.key,
        description: flag.description,
        flag_type: flag.flag_type,
        value_type: flag.value_type,
        default_value: flag.default_value,
        ownership: flag.ownership,
        lifecycle: flag.lifecycle,
        tags: flag.tags,
        archived_at: flag.archived_at,
        previous_owners: [flag.ownership.owner_ref],
        inserted_at: state.now,
        updated_at: state.now,
        environments: environments,
        rulesets: Map.new(environment_keys, &{&1, %{}})
      }
      |> Map.merge(extra_attrs)

    next_state = put_in(state.flags[flag.key], flag_record)
    {flag_record, next_state}
  end

  defp with_fetch_context(state, flag_key, environment_key, fun) do
    with {:ok, environment} <- fetch_environment(state, environment_key),
         {:ok, flag, flag_environment} <- fetch_flag_environment(state, flag_key, environment.key) do
      fun.(flag, environment, flag_environment)
    end
  end

  defp with_mutable_context(state, flag_key, environment_key, fun) do
    with {:ok, environment} <- fetch_environment(state, environment_key),
         {:ok, flag, flag_environment} <- fetch_flag_environment(state, flag_key, environment.key),
         :ok <- ensure_not_archived(flag_key, flag) do
      fun.(flag, environment, flag_environment)
    end
  end

  defp with_list_environment(_state, nil, fun), do: fun.(nil)

  defp with_list_environment(state, environment_key, fun) do
    with {:ok, environment} <- fetch_environment(state, environment_key) do
      fun.(environment.key)
    end
  end

  defp fetch_environment(state, environment_key) do
    normalized_key = to_string(environment_key)

    case Map.fetch(state.environments, normalized_key) do
      {:ok, environment} -> {:ok, environment}
      :error -> {:error, StoreError.environment_not_found(environment_key)}
    end
  end

  defp fetch_flag_environment(state, flag_key, environment_key) do
    normalized_key = to_string(flag_key)

    with {:ok, flag} <- Map.fetch(state.flags, normalized_key),
         {:ok, flag_environment} <- Map.fetch(flag.environments, environment_key) do
      {:ok, flag, flag_environment}
    else
      :error -> {:error, StoreError.flag_not_found(flag_key, environment_key)}
    end
  end

  defp ensure_not_archived(flag_key, flag) do
    if archived?(flag) do
      {:error, StoreError.archived(flag_key)}
    else
      :ok
    end
  end

  defp archived?(flag), do: not is_nil(flag.archived_at)

  defp do_rollback(state, inverse_command, rollback_command, original_audit_event) do
    with {:ok, payload, next_state, before_state, after_state} <-
           apply_kill_switch_rollback(state, inverse_command) do
      rollback_event =
        build_audit_event(next_state, rollback_command, "audit.rollback", :ok,
          environment_key: original_audit_event.environment_key,
          resource_key: original_audit_event.resource_key,
          before: before_state,
          after: after_state,
          rollback_of_event_id: original_audit_event.id,
          links: %{"inverse_event_type" => original_audit_event.event_type}
        )

      audit_event = AuditEvent.serialize(rollback_event)
      final_state = %{next_state | audit_events: [audit_event | next_state.audit_events]}
      {:ok, %{payload: payload, audit_event: audit_event}, final_state}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp apply_kill_switch_rollback(state, %Command.EngageKillSwitch{} = command) do
    with_mutable_context(state, command.flag_key, command.environment_key, fn _flag,
                                                                              environment,
                                                                              flag_environment ->
      before_state = audit_state(flag_environment)

      updated_flag_environment =
        flag_environment
        |> Map.put(:status, :killswitched)
        |> Map.put(:kill_switch_variant_key, "default")
        |> Map.put(:updated_at, state.now)

      next_state =
        put_in(
          state.flags[to_string(command.flag_key)].environments[environment.key],
          updated_flag_environment
        )

      payload =
        build_flag_detail_payload(
          next_state,
          next_state.flags[to_string(command.flag_key)],
          environment,
          updated_flag_environment,
          true
        )

      {:ok, payload, next_state, before_state, audit_state(updated_flag_environment)}
    end)
  end

  defp apply_kill_switch_rollback(state, %Command.ReleaseKillSwitch{} = command) do
    with_mutable_context(state, command.flag_key, command.environment_key, fn _flag,
                                                                              environment,
                                                                              flag_environment ->
      before_state = audit_state(flag_environment)

      updated_flag_environment =
        flag_environment
        |> Map.put(
          :status,
          if(flag_environment.status == :killswitched,
            do: :active,
            else: flag_environment.status || :active
          )
        )
        |> Map.put(:kill_switch_variant_key, nil)
        |> Map.put(:updated_at, state.now)

      next_state =
        put_in(
          state.flags[to_string(command.flag_key)].environments[environment.key],
          updated_flag_environment
        )

      payload =
        build_flag_detail_payload(
          next_state,
          next_state.flags[to_string(command.flag_key)],
          environment,
          updated_flag_environment,
          true
        )

      {:ok, payload, next_state, before_state, audit_state(updated_flag_environment)}
    end)
  end

  defp append_audit_event(state, command, event_type, result, opts \\ []) do
    audit_event = build_audit_event(state, command, event_type, result, opts)
    {AuditEvent.serialize(audit_event), state}
  end

  defp build_audit_event(state, command, event_type, result, opts) do
    command_metadata = Map.get(command, :metadata, %{})

    metadata =
      AuditEvent.metadata(%{
        before: Keyword.get(opts, :before, %{}),
        after: Keyword.get(opts, :after, %{}),
        diff:
          Keyword.get(
            opts,
            :diff,
            diff_map(Keyword.get(opts, :before, %{}), Keyword.get(opts, :after, %{}))
          ),
        links:
          Keyword.get(opts, :links, %{})
          |> Map.new()
          |> maybe_put("rollback_of_event_id", Keyword.get(opts, :rollback_of_event_id)),
        tenant: Command.GovernanceSupport.tenant_provenance(command, metadata: command_metadata),
        context: command_metadata,
        request_id:
          Map.get(command_metadata, :request_id) || Map.get(command_metadata, "request_id"),
        source: Map.get(command_metadata, :source) || Map.get(command_metadata, "source"),
        rollback_of_event_id: Keyword.get(opts, :rollback_of_event_id)
      })
      |> Map.merge(Map.new(Keyword.get(opts, :metadata, %{})))

    %AuditEvent{
      id: Ecto.UUID.generate(),
      event_type: event_type,
      resource_type: Keyword.get(opts, :resource_type, "flag"),
      resource_key:
        Keyword.get(opts, :resource_key) ||
          Map.get(command_metadata, "resource_key") ||
          Map.get(command_metadata, :resource_key) ||
          Map.get(command, :resource_key) ||
          Map.get(command, :flag_key) ||
          "",
      environment_key:
        to_string(Keyword.get(opts, :environment_key, Map.get(command, :environment_key))),
      actor_id: actor_value(command.actor, "id"),
      actor_type: to_string(actor_value(command.actor, "type") || "operator"),
      actor_display: actor_value(command.actor, "display"),
      reason: Map.get(command, :reason),
      result: result,
      metadata: metadata,
      correlation_id:
        Map.get(command_metadata, :request_id) || Map.get(command_metadata, "request_id"),
      occurred_at: state.now,
      inserted_at: state.now
    }
  end

  defp audit_only_result(state, command, event_type) do
    case audit_result(command) do
      :denied ->
        {audit_event, next_state} = append_audit_event(state, command, event_type, :denied)

        {:ok, {:ok, %{audit_event: audit_event}},
         %{next_state | audit_events: [audit_event | next_state.audit_events]}}

      _other ->
        :continue
    end
  end

  defp audit_result(command) do
    command.metadata[:audit_result] || command.metadata["audit_result"]
  end

  defp audit_state(flag_environment) do
    %{
      "status" => flag_environment.status,
      "kill_switch_variant_key" => flag_environment.kill_switch_variant_key
    }
  end

  defp diff_map(before_state, after_state) do
    Map.new(after_state, fn {key, value} ->
      {to_string(key),
       %{
         "from" => Map.get(before_state, to_string(key)) || Map.get(before_state, key),
         "to" => value
       }}
    end)
  end

  defp matches_audit_filter?(entry, command) do
    matches_flag = is_nil(command.flag_key) or entry.resource_key == to_string(command.flag_key)

    matches_environment =
      is_nil(command.environment_key) or
        entry.environment_key == to_string(command.environment_key)

    matches_actor = is_nil(command.actor_id) or entry.actor_id == command.actor_id
    matches_mutation = is_nil(command.mutation) or entry.event_type == command.mutation

    matches_after =
      case command.occurred_after do
        %DateTime{} = boundary -> DateTime.compare(entry.occurred_at, boundary) != :lt
        _other -> true
      end

    matches_before =
      case command.occurred_before do
        %DateTime{} = boundary -> DateTime.compare(entry.occurred_at, boundary) != :gt
        _other -> true
      end

    matches_flag and matches_environment and matches_actor and matches_mutation and matches_after and
      matches_before
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp fetch_change_request_record(state, change_request_id) do
    case Map.fetch(state.change_requests, to_string(change_request_id)) do
      {:ok, change_request} -> {:ok, change_request}
      :error -> {:error, StoreError.invalid_command("change request was not found")}
    end
  end

  defp ensure_governance_transition(change_request, allowed_statuses) do
    if change_request.status in allowed_statuses do
      :ok
    else
      {:error,
       StoreError.invalid_command("change request is not in a valid state for this operation")}
    end
  end

  defp ensure_unique_reviewer(state, change_request_id, command) do
    reviewer_id = get_in(command.actor || %{}, ["id"])

    if Enum.any?(
         Map.get(state.approvals, change_request_id, []),
         &(&1.reviewer_id == reviewer_id)
       ) do
      {:error, StoreError.invalid_command("reviewer has already recorded a decision")}
    else
      :ok
    end
  end

  defp required_approvals(snapshot) do
    snapshot["required_approvals"] || snapshot[:required_approvals] || 0
  end

  defp serialize_change_request(change_request) do
    %{
      id: change_request.id,
      state: governance_state(change_request.status),
      action: governance_action(change_request.governed_action),
      environment_key: change_request.environment_key,
      resource_type: change_request.resource_type,
      resource_key: change_request.resource_key,
      submitted_by: %{
        id: change_request.submitter_id,
        type: change_request.submitter_type,
        display: change_request.submitter_display
      },
      command: change_request.command_snapshot,
      approval_requirement:
        normalize_approval_requirement_snapshot(change_request.approval_requirement_snapshot),
      correlation_id: change_request.correlation_id,
      metadata: change_request.metadata
    }
    |> ChangeRequest.new()
    |> ChangeRequest.serialize()
    |> Map.put(:id, change_request.id)
  end

  defp serialize_approval(approval) do
    %{
      change_request_id: approval.change_request_id,
      decision: governance_decision(approval.decision),
      reviewed_by: %{
        id: approval.reviewer_id,
        type: approval.reviewer_type,
        display: approval.reviewer_display
      },
      reason: approval.reason,
      correlation_id: approval.correlation_id
    }
    |> Approval.new()
    |> Approval.serialize()
    |> Map.put(:id, approval.id)
  end

  defp governance_state("submitted"), do: :submitted
  defp governance_state("approved"), do: :approved
  defp governance_state("rejected"), do: :rejected
  defp governance_state("cancelled"), do: :cancelled
  defp governance_state("executed"), do: :executed

  defp scheduled_state("scheduled"), do: :scheduled
  defp scheduled_state("running"), do: :running
  defp scheduled_state("completed"), do: :completed
  defp scheduled_state("failed"), do: :failed
  defp scheduled_state("quarantined"), do: :quarantined
  defp scheduled_state("cancelled"), do: :cancelled
  defp scheduled_state(_state), do: :scheduled

  defp governance_decision("approved"), do: :approved
  defp governance_decision(_decision), do: :rejected

  defp execution_attempt_state("running"), do: :running
  defp execution_attempt_state("completed"), do: :completed
  defp execution_attempt_state("failed"), do: :failed
  defp execution_attempt_state("quarantined"), do: :quarantined
  defp execution_attempt_state("cancelled"), do: :cancelled
  defp execution_attempt_state(_state), do: :failed

  defp scheduled_execution_mode("change_request"), do: :change_request
  defp scheduled_execution_mode("policy_bypass"), do: :policy_bypass
  defp scheduled_execution_mode("emergency_bypass"), do: :emergency_bypass
  defp scheduled_execution_mode(_mode), do: :change_request

  defp ensure_scheduled_transition(state, allowed_states) do
    if state in allowed_states do
      :ok
    else
      {:error,
       StoreError.invalid_command(
         "scheduled execution is not in a valid state for this operation"
       )}
    end
  end

  defp governance_action(action) when is_binary(action) do
    action
    |> String.trim()
    |> String.to_existing_atom()
  rescue
    ArgumentError -> :manage_settings
  end

  defp governance_audit_command(command, change_request, stage) do
    metadata =
      command.metadata
      |> Map.merge(%{
        "request_id" => change_request.correlation_id,
        "change_request_id" => change_request.id,
        "governance_action" => change_request.governed_action,
        "execution_stage" => stage,
        "resource_key" => change_request.resource_key,
        "tenant" => change_request.command_snapshot["tenant"]
      })

    Map.merge(command, %{
      metadata: metadata,
      reason: command.reason,
      actor: command.actor
    })
  end

  defp governance_correlation_id(command) do
    get_in(command.metadata, ["request_id"]) || Ecto.UUID.generate()
  end

  defp prepare_audience_mutation_change_request(state, %Command.SubmitChangeRequest{
         action: :apply_audience_mutation
       } = command) do
    apply_command =
      Command.ApplyAudienceMutation.new(
        command.command,
        actor: command.actor,
        reason: command.reason,
        metadata: command.metadata
      )

    with {:ok, environment} <- fetch_environment_from_state(state, apply_command.environment_key),
         {:ok, audience} <- fetch_audience_for_mutation(state, apply_command.audience_key),
         :ok <- ensure_audience_tenant(audience, apply_command.tenant_key),
         :ok <- ensure_audience_active(audience) do
      current_preview = audience_preview_payload(state, environment.key, audience, apply_command)

      with :ok <- AudienceMutationChangeRequest.validate_submit(command, current_preview),
           {:ok, assessment} <- audience_mutation_submit_assessment(command, current_preview) do
        metadata =
          command.metadata
          |> Map.new()
          |> Map.merge(
            AudienceMutationChangeRequest.build_submission_metadata(assessment, current_preview)
          )

        {:ok,
         %{
           command
           | metadata: metadata,
             resource_type: "audience",
             resource_key: apply_command.audience_key
         }}
      end
    end
  end

  defp prepare_audience_mutation_change_request(_state, command), do: {:ok, command}

  defp audience_mutation_submit_assessment(command, current_preview) do
    mutation_command = command.command || %{}
    references = Map.get(current_preview, :affected_references) || []

    BlastRadiusThreshold.assess(%{
      environment_key: command.environment_key,
      operation: Map.get(mutation_command, "operation") || Map.get(mutation_command, :operation),
      preview_fingerprint:
        Map.get(mutation_command, "preview_fingerprint") ||
          Map.get(mutation_command, :preview_fingerprint),
      preview_schema_version:
        Map.get(mutation_command, "preview_schema_version") ||
          Map.get(mutation_command, :preview_schema_version),
      affected_references: references,
      affected_reference_keys:
        Map.get(mutation_command, "affected_reference_keys") ||
          Map.get(mutation_command, :affected_reference_keys),
      tenant_key: Map.get(mutation_command, "tenant_key") || Map.get(mutation_command, :tenant_key)
    })
  end

  defp audience_mutation_terminal_metadata(%{governed_action: "apply_audience_mutation"} = change_request, reason) do
    %{
      "blast_radius_assessment" => get_in(change_request, [:metadata, "blast_radius_assessment"]),
      "affected_reference_summary" => get_in(change_request, [:metadata, "affected_reference_summary"]),
      "terminal_reason" => reason
    }
  end

  defp audience_mutation_terminal_metadata(_change_request, _reason), do: %{}

  defp scheduled_transition_metadata(existing, state, command, now) do
    Map.merge(existing || %{}, %{
      "last_transition" => state,
      "last_transition_at" => DateTime.to_iso8601(now),
      "last_actor" => command.actor || %{},
      "last_reason" => command.reason,
      "request_id" => command.metadata[:request_id] || command.metadata["request_id"]
    })
  end

  defp normalize_failure_reason(%Rulestead.Error{message: message}),
    do: normalize_failure_reason(message)

  defp normalize_failure_reason(reason) when is_binary(reason) do
    case String.trim(reason) do
      "" -> "scheduled execution failed"
      value -> value
    end
  end

  defp normalize_failure_reason(reason), do: inspect(reason)

  defp execute_governed_change(
         state,
         %{governed_action: governed_action} = change_request,
         command
       )
       when governed_action in [
              "publish_ruleset",
              "advance_rollout",
              "engage_kill_switch",
              "release_kill_switch",
              "promote_environment",
              "apply_audience_mutation"
            ] do
    execute_bounded_governed_change(state, governed_action, change_request, command)
  end

  defp execute_governed_change(_state, _change_request, _command) do
    {:error, StoreError.invalid_command("governed action is not implemented")}
  end

  defp run_scheduled_execution(state, scheduled_execution, command) do
    attempt_number = scheduled_execution.attempt_count + 1

    attempt = %{
      id: Ecto.UUID.generate(),
      scheduled_execution_id: scheduled_execution.id,
      attempt_number: attempt_number,
      state: "running",
      started_at: state.now,
      finished_at: nil,
      failure_reason: nil,
      metadata: command.metadata
    }

    state_with_attempt =
      update_in(state.execution_attempts[scheduled_execution.id], fn attempts ->
        (attempts || []) ++ [attempt]
      end)

    case perform_scheduled_execution(state_with_attempt, scheduled_execution, command) do
      {:ok, execution_result, execution_state} ->
        updated_attempt =
          attempt
          |> Map.put(:state, "completed")
          |> Map.put(:finished_at, execution_state.now)

        automation_metadata =
          RolloutAutoAdvance.automation_execution_metadata(execution_result || %{})

        updated_scheduled_execution =
          execution_state.scheduled_executions[scheduled_execution.id]
          |> Map.put(:state, "completed")
          |> Map.put(:attempt_count, attempt_number)
          |> Map.put(:executed_at, execution_state.now)
          |> Map.put(:failure_reason, nil)
          |> Map.put(
            :execution_metadata,
            scheduled_execution.execution_metadata
            |> scheduled_transition_metadata(
              "completed",
              command,
              execution_state.now
            )
            |> Map.merge(automation_metadata)
          )
          |> Map.put(:updated_at, execution_state.now)

        next_state =
          execution_state
          |> put_in(
            [:execution_attempts, scheduled_execution.id],
            replace_attempt(execution_state, updated_attempt)
          )
          |> put_in([:scheduled_executions, scheduled_execution.id], updated_scheduled_execution)

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(updated_scheduled_execution),
           execution_result: execution_result,
           attempts:
             list_execution_attempts(next_state, scheduled_execution.id)
             |> Enum.map(&serialize_execution_attempt/1)
         }, next_state}

      {:error, error, execution_state} ->
        failure_reason = normalize_failure_reason(error)
        next_state_name = if attempt_number >= 3, do: "quarantined", else: "scheduled"
        attempt_state = if next_state_name == "quarantined", do: "quarantined", else: "failed"

        updated_attempt =
          attempt
          |> Map.put(:state, attempt_state)
          |> Map.put(:finished_at, execution_state.now)
          |> Map.put(:failure_reason, failure_reason)

        updated_scheduled_execution =
          scheduled_execution
          |> Map.put(:state, next_state_name)
          |> Map.put(:attempt_count, attempt_number)
          |> Map.put(:failure_reason, failure_reason)
          |> Map.put(
            :execution_metadata,
            scheduled_transition_metadata(
              scheduled_execution.execution_metadata,
              next_state_name,
              command,
              execution_state.now
            )
          )
          |> Map.put(:updated_at, execution_state.now)

        next_state =
          execution_state
          |> put_in(
            [:execution_attempts, scheduled_execution.id],
            replace_attempt(execution_state, updated_attempt)
          )
          |> put_in([:scheduled_executions, scheduled_execution.id], updated_scheduled_execution)

        {:error, StoreError.invalid_command(failure_reason), next_state}
    end
  end

  defp perform_scheduled_execution(state, %{change_request_id: change_request_id}, command)
       when is_binary(change_request_id) do
    with {:ok, change_request} <- fetch_change_request_record(state, change_request_id),
         {:ok, execution_result, next_state} <-
           execute_governed_change(state, change_request, command) do
      updated_change_request =
        change_request
        |> Map.put(:status, "executed")
        |> Map.put(:resolved_at, next_state.now)
        |> Map.put(:executed_at, next_state.now)
        |> Map.put(:updated_at, next_state.now)

      audit_command = governance_audit_command(command, updated_change_request, "merged")

      {audit_event, post_audit_state} =
        append_audit_event(next_state, audit_command, "change_request.merged", :ok)

      final_state =
        post_audit_state
        |> put_in([:change_requests, change_request.id], updated_change_request)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)

      {:ok, execution_result, final_state}
    end
  end

  defp perform_scheduled_execution(
         state,
         %{governed_action: governed_action} = scheduled_execution,
         command
       )
       when governed_action in [
              "publish_ruleset",
              "advance_rollout",
              "engage_kill_switch",
              "release_kill_switch",
              "promote_environment"
            ] do
    execute_direct_scheduled_action(state, governed_action, scheduled_execution, command)
  end

  defp perform_scheduled_execution(state, _scheduled_execution, _command) do
    {:error, StoreError.invalid_command("governed action is not implemented"), state}
  end

  defp execute_bounded_governed_change(state, "publish_ruleset", change_request, command) do
    version = change_request.command_snapshot["version"]

    with {:ok, environment, flag, flag_environment} <-
           fetch_schedulable_flag_context(
             state,
             change_request.resource_key,
             change_request.environment_key
           ),
         {:ok, ruleset_record} <- ensure_publishable_ruleset(flag, environment.key, version),
         {:ok, next_state} <-
           publish_ruleset_record(
             state,
             change_request.resource_key,
             environment.key,
             flag_environment,
             ruleset_record
           ) do
      publish_command =
        Command.PublishRuleset.new(change_request.resource_key, environment.key,
          version: version,
          actor: command.actor,
          reason: command.reason,
          metadata: %{
            request_id: change_request.correlation_id,
            source: change_request.metadata["source"],
            change_request_id: change_request.id,
            governance_action: change_request.governed_action,
            execution_stage: "execute"
          }
        )

      before_ruleset =
        active_ruleset_payload(flag, environment.key, flag_environment.active_ruleset_version)

      updated_flag = next_state.flags[to_string(change_request.resource_key)]
      updated_flag_environment = updated_flag.environments[environment.key]

      execution_result =
        build_flag_detail_payload(
          next_state,
          updated_flag,
          environment,
          updated_flag_environment,
          true
        )

      {audit_event, post_audit_state} =
        append_audit_event(next_state, publish_command, "ruleset.publish", :ok,
          before: ruleset_audit_state(before_ruleset),
          after: ruleset_audit_state(ruleset_record),
          diff: ruleset_position_diff(before_ruleset, ruleset_record),
          metadata: %{"version" => ruleset_record.version}
        )

      {:ok, execution_result,
       %{post_audit_state | audit_events: [audit_event | post_audit_state.audit_events]}}
    end
  end

  defp execute_bounded_governed_change(state, "engage_kill_switch", change_request, command) do
    with {:ok, environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             state,
             change_request.resource_key,
             change_request.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :engage) do
      execute_kill_switch_transition(
        state,
        change_request.resource_key,
        environment.key,
        flag_environment,
        :engage,
        command,
        %{
          "request_id" => change_request.correlation_id,
          "source" => change_request.metadata["source"],
          "change_request_id" => change_request.id,
          "governance_action" => change_request.governed_action,
          "execution_stage" => "execute"
        }
      )
    end
  end

  defp execute_bounded_governed_change(state, "release_kill_switch", change_request, command) do
    with {:ok, environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             state,
             change_request.resource_key,
             change_request.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :release) do
      execute_kill_switch_transition(
        state,
        change_request.resource_key,
        environment.key,
        flag_environment,
        :release,
        command,
        %{
          "request_id" => change_request.correlation_id,
          "source" => change_request.metadata["source"],
          "change_request_id" => change_request.id,
          "governance_action" => change_request.governed_action,
          "execution_stage" => "execute"
        }
      )
    end
  end

  defp execute_bounded_governed_change(state, "advance_rollout", change_request, command) do
    case handle_advance_rollout_in_state(
           state,
           Command.AdvanceRollout.new(
             change_request.resource_key,
             change_request.environment_key,
             Map.merge(
               change_request.command_snapshot["rollout"] || change_request.command_snapshot,
               %{"signal_facts" => change_request.command_snapshot["signal_facts"]}
             ),
             actor: command.actor,
             reason: command.reason,
             metadata: %{
               request_id: change_request.correlation_id,
               source: change_request.metadata["source"],
               change_request_id: change_request.id,
               governance_action: change_request.governed_action,
               execution_stage: "execute",
               tenant: change_request.command_snapshot["tenant"]
             }
           )
         ) do
      {:ok, payload, next_state} -> {:ok, payload, next_state}
      {:error, error} -> {:error, error, state}
    end
  end

  defp execute_bounded_governed_change(state, "apply_audience_mutation", change_request, command) do
    apply_command =
      change_request.command_snapshot
      |> Command.ApplyAudienceMutation.new(
        actor: command.actor,
        reason: command.reason,
        metadata:
          Map.merge(command.metadata || %{}, %{
            "change_request_id" => change_request.id,
            "execution_stage" => "execute",
            "request_id" => change_request.correlation_id
          })
      )

    case do_apply_audience_mutation(state, apply_command, governed_apply?: true) do
      {:ok, execution_result, next_state} -> {:ok, execution_result, next_state}
      {:dependency_blocked, error, next_state} -> {:error, error, next_state}
      {:blast_radius_blocked, error, next_state} -> {:error, error, next_state}
      {:error, error} -> {:error, error, state}
    end
  end

  defp execute_bounded_governed_change(state, "promote_environment", change_request, command) do
    promotion_command =
      change_request.command_snapshot
      |> Command.ApplyPromotion.new(
        actor: command.actor,
        reason: command.reason,
        metadata:
          promotion_execution_metadata(
            command.metadata,
            change_request.correlation_id,
            change_request.metadata["source"],
            change_request_id: change_request.id,
            execution_stage: "execute"
          )
      )

    with :ok <- Apply.validate_governed_snapshot(promotion_command),
         {:ok, execution_result, next_state} <-
           do_apply_promotion(state, promotion_command, allow_protected_target?: true) do
      {:ok, execution_result, next_state}
    else
      {:error, error} -> {:error, error, state}
    end
  end

  defp execute_direct_scheduled_action(state, "publish_ruleset", scheduled_execution, command) do
    version = scheduled_execution.command_snapshot["version"]

    with {:ok, environment, flag, flag_environment} <-
           fetch_schedulable_flag_context(
             state,
             scheduled_execution.resource_key,
             scheduled_execution.environment_key
           ),
         {:ok, ruleset_record} <- ensure_publishable_ruleset(flag, environment.key, version),
         {:ok, next_state} <-
           publish_ruleset_record(
             state,
             scheduled_execution.resource_key,
             environment.key,
             flag_environment,
             ruleset_record
           ) do
      publish_command =
        Command.PublishRuleset.new(scheduled_execution.resource_key, environment.key,
          version: version,
          actor: command.actor,
          reason: command.reason,
          metadata: %{
            request_id: scheduled_execution.correlation_id,
            source: scheduled_execution.metadata["source"],
            scheduled_execution_id: scheduled_execution.id,
            execution_stage: "scheduled_execution"
          }
        )

      before_ruleset =
        active_ruleset_payload(flag, environment.key, flag_environment.active_ruleset_version)

      {audit_event, post_audit_state} =
        append_audit_event(next_state, publish_command, "ruleset.publish", :ok,
          before: ruleset_audit_state(before_ruleset),
          after: ruleset_audit_state(ruleset_record),
          diff: ruleset_position_diff(before_ruleset, ruleset_record),
          metadata: %{"version" => ruleset_record.version}
        )

      updated_state = %{
        post_audit_state
        | audit_events: [audit_event | post_audit_state.audit_events]
      }

      updated_flag = updated_state.flags[to_string(scheduled_execution.resource_key)]
      updated_flag_environment = updated_flag.environments[environment.key]

      execution_result =
        build_flag_detail_payload(
          updated_state,
          updated_flag,
          environment,
          updated_flag_environment,
          true
        )

      {:ok, execution_result, updated_state}
    else
      {:error, error} -> {:error, error, state}
    end
  end

  defp execute_direct_scheduled_action(state, "engage_kill_switch", scheduled_execution, command) do
    with {:ok, environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             state,
             scheduled_execution.resource_key,
             scheduled_execution.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :engage) do
      execute_kill_switch_transition(
        state,
        scheduled_execution.resource_key,
        environment.key,
        flag_environment,
        :engage,
        command,
        %{
          "request_id" => scheduled_execution.correlation_id,
          "source" => scheduled_execution.metadata["source"],
          "scheduled_execution_id" => scheduled_execution.id,
          "execution_stage" => "scheduled_execution"
        }
      )
    else
      {:error, error} -> {:error, error, state}
    end
  end

  defp execute_direct_scheduled_action(state, "release_kill_switch", scheduled_execution, command) do
    with {:ok, environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             state,
             scheduled_execution.resource_key,
             scheduled_execution.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :release) do
      execute_kill_switch_transition(
        state,
        scheduled_execution.resource_key,
        environment.key,
        flag_environment,
        :release,
        command,
        %{
          "request_id" => scheduled_execution.correlation_id,
          "source" => scheduled_execution.metadata["source"],
          "scheduled_execution_id" => scheduled_execution.id,
          "execution_stage" => "scheduled_execution"
        }
      )
    else
      {:error, error} -> {:error, error, state}
    end
  end

  defp execute_direct_scheduled_action(state, "advance_rollout", scheduled_execution, command) do
    normalized_scheduled_execution = serialize_scheduled_execution(scheduled_execution)

    if RolloutAutoAdvance.automation_tick?(normalized_scheduled_execution.metadata) do
      alias Rulestead.Fake.OrchestrationStore

      OrchestrationStore.put_state!(state)

      orchestration_result =
        RolloutAutoAdvance.execute_scheduled_tick(
          OrchestrationStore,
          normalized_scheduled_execution,
          command
        )

      state = OrchestrationStore.pop_state!() || state

      case orchestration_result do
        {:ok, %{outcome: :blocked} = blocked_result} ->
          {:ok, blocked_result, state}

        {:ok, %{outcome: :change_request_submitted} = cr_result} ->
          {:ok, cr_result, state}

        {:ok, %Command.AdvanceRollout{} = advance_command} ->
          case handle_advance_rollout_in_state(state, advance_command) do
            {:ok, payload, next_state} -> {:ok, payload, next_state}
            {:error, error} -> {:error, error, state}
          end

        {:error, reason} ->
          {:error, reason, state}
      end
    else
      case handle_advance_rollout_in_state(
             state,
             Command.AdvanceRollout.new(
               scheduled_execution.resource_key,
               scheduled_execution.environment_key,
               Map.merge(
                 scheduled_execution.command_snapshot["rollout"] ||
                   scheduled_execution.command_snapshot,
                 %{"signal_facts" => scheduled_execution.command_snapshot["signal_facts"]}
               ),
               actor: command.actor,
               reason: command.reason,
               metadata: %{
                 request_id: scheduled_execution.correlation_id,
                 source: scheduled_execution.metadata["source"],
                 scheduled_execution_id: scheduled_execution.id,
                 execution_stage: "scheduled_execution",
                 tenant: scheduled_execution.command_snapshot["tenant"]
               }
             )
           ) do
        {:ok, payload, next_state} -> {:ok, payload, next_state}
        {:error, error} -> {:error, error, state}
      end
    end
  end

  defp execute_direct_scheduled_action(state, "promote_environment", scheduled_execution, command) do
    promotion_command =
      scheduled_execution.command_snapshot
      |> Command.ApplyPromotion.new(
        actor: command.actor,
        reason: command.reason,
        metadata:
          promotion_execution_metadata(
            command.metadata,
            scheduled_execution.correlation_id,
            scheduled_execution.metadata["source"],
            scheduled_execution_id: scheduled_execution.id,
            execution_stage: "scheduled_execution"
          )
      )

    with {:ok, compare} <-
           compare_environments_in_state(state, compare_command(promotion_command)),
         :ok <-
           Apply.validate_with_compare(promotion_command, compare, allow_protected_target?: true),
         {:ok, execution_result, next_state} <-
           do_apply_promotion(state, promotion_command, allow_protected_target?: true) do
      {:ok, execution_result, next_state}
    else
      {:error, error} -> {:error, error, state}
    end
  end

  defp promotion_execution_metadata(metadata, request_id, source, links) do
    metadata
    |> Map.merge(%{
      "request_id" => request_id,
      "source" => source,
      "governance_action" => "promote_environment"
    })
    |> Map.merge(Map.new(links))
  end

  defp compare_command(%Command.ApplyPromotion{} = command) do
    Command.CompareEnvironments.new(
      command.source_environment_key,
      command.target_environment_key,
      flag_keys: command.flag_keys,
      compare_token: command.compare_token,
      tenant_key: command.tenant_key
    )
  end

  defp compare_environments_in_state(state, %Command.CompareEnvironments{} = command) do
    with {:ok, source_environment} <-
           fetch_environment_from_state(state, command.source_environment_key),
         {:ok, target_environment} <-
           fetch_environment_from_state(state, command.target_environment_key) do
      source_flags = compare_payloads_for_environment(state, source_environment.key)
      target_flags = compare_payloads_for_environment(state, target_environment.key)

      audiences =
        Map.new(state.audiences, fn {key, audience} -> {key, audience_summary(audience)} end)

      {:ok,
       Compare.compare_projected(%{
         source_environment: source_environment,
         target_environment: target_environment,
         requested_flag_keys: command.flag_keys,
         compare_token: command.compare_token,
         tenant_key: command.tenant_key,
         source_flags: source_flags,
         target_flags: target_flags,
         audiences: audiences
       })}
    end
  end

  defp build_audience_preview(state, %Command.PreviewAudienceImpact{} = command) do
    with {:ok, environment} <-
           fetch_environment_from_state(state, command.environment_key || "test"),
         {:ok, audience} <- fetch_audience_for_mutation(state, command.audience_key),
         :ok <- ensure_audience_tenant(audience, command.tenant_key),
         :ok <- ensure_audience_active(audience) do
      {:ok, audience_preview_payload(state, environment.key, audience, command)}
    end
  end

  defp do_apply_audience_mutation(state, %Command.ApplyAudienceMutation{} = command, opts \\ []) do
    with {:ok, environment} <- fetch_environment_from_state(state, command.environment_key),
         {:ok, audience} <- fetch_audience_for_mutation(state, command.audience_key),
         :ok <- ensure_audience_tenant(audience, command.tenant_key),
         :ok <- ensure_audience_active(audience),
         :ok <- ensure_supported_audience_operation(command),
         :ok <- ensure_audience_preview_schema(command),
         current_preview <- audience_preview_payload(state, environment.key, audience, command),
         :ok <- ensure_fresh_audience_preview(command, current_preview),
         :ok <-
           validate_blast_radius_threshold(command, current_preview, state.audiences,
             governed_apply?: Keyword.get(opts, :governed_apply?, false)
           ) do
      dependency_entries = audience_dependency_entries(current_preview, command)

      dependency_findings =
        validate_dependency_entries(state, command, dependency_entries,
          expected_reference_keys: command.affected_reference_keys
        )

      if DependencyValidator.blockers?(dependency_findings) do
        error =
          DependencyValidator.to_error(dependency_findings,
            message: "audience mutation blocked by dependency validation"
          )

        {audit_event, blocked_state} =
          append_audit_event(state, command, blocked_audience_event_type(command), :error,
            resource_type: "audience",
            resource_key: command.audience_key,
            metadata: %{
              "preview_fingerprint" => command.preview_fingerprint,
              "preview_schema_version" => command.preview_schema_version,
              "preview_basis" => command.preview_basis,
              "affected_reference_keys" => preview_reference_keys(current_preview),
              "blockers" => dependency_blockers(dependency_findings),
              "dependency_findings" => serialize_dependency_findings(dependency_findings)
            }
          )

        {:dependency_blocked, error,
         %{blocked_state | audit_events: [audit_event | blocked_state.audit_events]}}
      else
        with {:ok, updated_audience} <-
               apply_audience_operation(audience, command, state.now) do
          next_state =
            state
            |> put_in([:audiences, audience.key], updated_audience)
            |> put_runtime_snapshot(environment.key)

          {audit_event, next_state} =
            append_audit_event(next_state, command, audience_event_type(command.operation), :ok,
              resource_type: "audience",
              resource_key: audience.key,
              before: audience_audit_state(audience),
              after: audience_audit_state(updated_audience),
              metadata: %{
                "preview_fingerprint" => command.preview_fingerprint,
                "preview_schema_version" => command.preview_schema_version,
                "preview_basis" => command.preview_basis,
                "affected_reference_keys" => preview_reference_keys(current_preview),
                "dependency_findings" => []
              }
            )

          {:ok,
           %{
             result: :ok,
             operation: command.operation,
             audience: audience_summary(updated_audience),
             preview: current_preview,
             audit_event: audit_event
           }, %{next_state | audit_events: [audit_event | next_state.audit_events]}}
        end
      end
    else
      {:error, %Rulestead.Error{} = error} ->
        case blast_radius_blocked?(error) do
          true ->
            {audit_event, blocked_state} =
              append_audit_event(state, command, blocked_audience_event_type(command), :error,
                resource_type: "audience",
                resource_key: command.audience_key,
                metadata: blast_radius_blocked_metadata(command, error)
              )

            {:blast_radius_blocked, error,
             %{blocked_state | audit_events: [audit_event | blocked_state.audit_events]}}

          false ->
            {:error, error}
        end
    end
  end

  defp audience_preview_payload(state, environment_key, audience, command) do
    affected_references =
      state
      |> compare_payloads_for_environment(environment_key)
      |> Map.values()
      |> then(&AudienceDependencies.summarize(audience.key, &1))

    before_definition = command.before_definition || audience.definition

    after_definition =
      case command.operation do
        "update" -> command.after_definition || audience.definition
        _other -> command.after_definition
      end

    ImpactPreview.build(%{
      environment_key: environment_key,
      tenant_key: command.tenant_key || Map.get(audience, :tenant_key),
      audience_key: audience.key,
      operation: command.operation,
      before_definition: before_definition,
      after_definition: after_definition,
      samples: Map.get(command, :samples, []),
      affected_references: affected_references,
      preview_basis: Map.get(command, :preview_basis)
    })
  end

  defp fetch_audience_for_mutation(state, audience_key) do
    case Map.get(state.audiences, to_string(audience_key)) do
      nil -> {:error, StoreError.invalid_command("audience was not found")}
      audience -> {:ok, audience}
    end
  end

  defp ensure_audience_tenant(_audience, nil), do: :ok

  defp ensure_audience_tenant(audience, tenant_key) do
    audience_tenant = Map.get(audience, :tenant_key)

    if is_nil(audience_tenant) or audience_tenant == tenant_key do
      :ok
    else
      {:error, StoreError.invalid_command("audience tenant mismatch")}
    end
  end

  defp ensure_audience_active(audience) do
    if Map.get(audience, :archived_at) do
      {:error, StoreError.invalid_command("audience is archived")}
    else
      :ok
    end
  end

  defp ensure_supported_audience_operation(%Command.ApplyAudienceMutation{
         operation: "delete_attempt"
       }) do
    {:error, StoreError.invalid_command("audience_delete_unsupported")}
  end

  defp ensure_supported_audience_operation(_command), do: :ok

  defp ensure_audience_preview_schema(%Command.ApplyAudienceMutation{
         preview_schema_version: version
       }) do
    if version == ImpactPreview.schema_version() do
      :ok
    else
      {:error, StoreError.invalid_command("audience preview schema version is incompatible")}
    end
  end

  defp ensure_fresh_audience_preview(command, current_preview) do
    if command.preview_fingerprint == current_preview.preview_fingerprint do
      :ok
    else
      {:error,
       StoreError.invalid_command(
         "audience preview is stale",
         metadata: %{
           audience_key: command.audience_key,
           expected_preview_fingerprint: current_preview.preview_fingerprint,
           preview_fingerprint: command.preview_fingerprint
         }
       )}
    end
  end

  defp preview_reference_keys(%{affected_references: affected_references}) do
    AudienceDependencies.reference_keys(affected_references)
  end

  defp preview_reference_keys(_preview), do: []

  defp audience_dependency_entries(preview, command) do
    preview
    |> Map.get(:affected_references, [])
    |> Enum.map(fn reference ->
      DependencyInventory.normalize_entry(%{
        environment_key: reference_value(reference, :environment_key) || command.environment_key,
        tenant_key: command.tenant_key || reference_value(reference, :tenant_key) || "global",
        audience_key: command.audience_key,
        flag_key: reference_value(reference, :flag_key),
        ruleset_version: reference_value(reference, :ruleset_version),
        rule_key: reference_value(reference, :rule_key),
        ruleset_status: reference_value(reference, :ruleset_status),
        rollout_context: reference_value(reference, :rollout_context),
        lifecycle_context: reference_value(reference, :lifecycle_context),
        visibility: %{status: "visible"},
        reference_count: 1,
        hidden_reference_count: 0
      })
    end)
    |> Enum.reject(&(&1.malformed? or is_nil(&1.audience_key)))
    |> DependencyInventory.sort_entries()
  end

  defp reference_value(reference, key) when is_map(reference) do
    Map.get(reference, key) || Map.get(reference, Atom.to_string(key))
  end

  defp reference_value(_reference, _key), do: nil

  defp validate_blast_radius_threshold(command, current_preview, audiences, opts) do
    dependency_entries = audience_dependency_entries(current_preview, command)

    BlastRadiusThreshold.validate_protected_apply(
      command,
      current_preview,
      Keyword.merge([dependency_entries: dependency_entries, audiences: audiences], opts)
    )
  end

  defp blast_radius_blocked?(%Rulestead.Error{metadata: metadata}) do
    Map.get(metadata, :verdict) in ["above_threshold", "indeterminate"]
  end

  defp blast_radius_blocked?(_error), do: false

  defp blast_radius_blocked_metadata(command, error) do
    %{
      "preview_fingerprint" => command.preview_fingerprint,
      "preview_schema_version" => command.preview_schema_version,
      "preview_basis" => command.preview_basis,
      "blast_radius_verdict" => Map.get(error.metadata, :verdict),
      "blast_radius_reference_count" => Map.get(error.metadata, :reference_count),
      "blast_radius_breach_reasons" => serialize_blast_radius_breach_reasons(error),
      "blockers" => blast_radius_blockers(error)
    }
  end

  defp serialize_blast_radius_breach_reasons(%Rulestead.Error{cause: %{breach_reasons: reasons}})
       when is_list(reasons) do
    Enum.map(reasons, fn reason ->
      %{
        "code" => Map.get(reason, :code),
        "observed" => Map.get(reason, :observed),
        "limit" => Map.get(reason, :limit),
        "remediation" => Map.get(reason, :remediation)
      }
    end)
  end

  defp serialize_blast_radius_breach_reasons(_error), do: []

  defp blast_radius_blockers(error) do
    Enum.map(error.details || [], fn detail ->
      %{"code" => Map.get(detail, :code) || Map.get(detail, "code")}
    end)
  end

  defp apply_audience_operation(
         audience,
         %Command.ApplyAudienceMutation{operation: "update"} = command,
         now
       ) do
    updated =
      audience
      |> Map.put(:definition, command.after_definition || audience.definition)
      |> maybe_update_audience_description(command.metadata)
      |> Map.put(:updated_at, now)

    {:ok, updated}
  end

  defp apply_audience_operation(
         audience,
         %Command.ApplyAudienceMutation{operation: "archive"},
         now
       ) do
    {:ok, audience |> Map.put(:archived_at, now) |> Map.put(:updated_at, now)}
  end

  defp apply_audience_operation(_audience, command, _now) do
    {:error, StoreError.invalid_command("unsupported audience operation: #{command.operation}")}
  end

  defp maybe_update_audience_description(audience, metadata) do
    case Map.get(metadata, "description") || Map.get(metadata, :description) do
      nil -> audience
      description -> Map.put(audience, :description, description)
    end
  end

  defp audience_event_type("archive"), do: "audience.archived"
  defp audience_event_type("delete_attempt"), do: "audience.deleted"
  defp audience_event_type(_operation), do: "audience.updated"

  defp blocked_audience_event_type(%Command.ApplyAudienceMutation{operation: "delete_attempt"}),
    do: "audience.delete_blocked"

  defp blocked_audience_event_type(_command), do: "audience.mutation_blocked"

  defp audience_audit_state(audience) do
    %{
      "key" => audience.key,
      "tenant_key" => Map.get(audience, :tenant_key),
      "definition" => audience.definition,
      "archived_at" => Map.get(audience, :archived_at)
    }
  end

  defp fetch_schedulable_flag_context(state, flag_key, environment_key) do
    with {:ok, environment} <- fetch_environment(state, environment_key),
         {:ok, flag, flag_environment} <- fetch_flag_environment(state, flag_key, environment.key),
         :ok <- ensure_schedulable_flag_not_archived(flag) do
      {:ok, environment, flag, flag_environment}
    end
  end

  defp ensure_schedulable_flag_not_archived(flag) do
    if archived?(flag) do
      {:error, "archived_resource"}
    else
      :ok
    end
  end

  defp ensure_publishable_ruleset(flag, environment_key, version) do
    case resolve_publishable_ruleset(flag, environment_key, version) do
      {:ok, ruleset_record} -> {:ok, ruleset_record}
      {:error, _error} -> {:error, "ruleset_not_publishable"}
    end
  end

  defp ensure_kill_switch_transition(flag_environment, :engage) do
    if flag_environment.status == :killswitched or
         not is_nil(flag_environment.kill_switch_variant_key) do
      {:error, "kill_switch_already_engaged"}
    else
      :ok
    end
  end

  defp ensure_kill_switch_transition(flag_environment, :release) do
    if flag_environment.status == :killswitched or
         not is_nil(flag_environment.kill_switch_variant_key) do
      :ok
    else
      {:error, "kill_switch_already_released"}
    end
  end

  defp handle_advance_rollout_in_state(state, %Command.AdvanceRollout{} = command) do
    with_mutable_context(state, command.flag_key, command.environment_key, fn flag,
                                                                              environment,
                                                                              flag_environment ->
      with {:ok, active_ruleset} <-
             ensure_active_ruleset_in_state(flag_environment, flag, environment.key),
           {:ok, rollout_rule} <- resolve_rollout_rule_in_state(active_ruleset, command.rule_key),
           {:ok, percentage} <- ensure_rollout_percentage_in_state(command.percentage),
           {:ok, next_ruleset_attrs} <-
             advanced_ruleset_attrs_in_state(active_ruleset, rollout_rule.key, percentage) do
        version = next_ruleset_version(state, command.flag_key, environment.key)

        ruleset = %{
          id: Ecto.UUID.generate(),
          version: version,
          status: :published,
          salt: next_ruleset_attrs.salt,
          published_at: state.now,
          metadata: next_ruleset_attrs.metadata,
          rules: next_ruleset_attrs.rules,
          inserted_at: state.now,
          updated_at: state.now
        }

        next_state =
          state
          |> put_ruleset(command.flag_key, environment.key, ruleset)
          |> put_in(
            [:flags, to_string(command.flag_key), :environments, environment.key],
            %{
              flag_environment
              | active_ruleset_version: version,
                status: :active,
                last_published_at: state.now,
                updated_at: state.now
            }
          )
          |> put_runtime_snapshot(environment.key)

        decision =
          build_guardrail_decision(%{
            flag_key: command.flag_key,
            environment_key: environment.key,
            rule_key: rollout_rule.key,
            stage: command.stage,
            decision_state: :pending_data,
            action_type: :advance,
            decision_reason: "monitoring_window_active",
            effective_percentage: percentage,
            rollout_salt: rollout_rule.rollout.salt,
            variant_fingerprint: variant_fingerprint_in_state(rollout_rule),
            monitoring_window_started_at: command.monitoring_window_started_at || state.now,
            monitoring_window_ends_at: command.monitoring_window_ends_at,
            occurred_at: state.now,
            signal_facts: Enum.map(command.signal_facts, &SignalFact.metadata/1),
            guardrail_evidence: first_guardrail_evidence_in_state(command.signal_facts),
            authored_snapshot: ruleset,
            correlation_id: command.metadata["request_id"] || Ecto.UUID.generate(),
            metadata: command.metadata
          })

        {audit_event, next_state} =
          append_audit_event(next_state, command, "rollout.advance", :ok,
            before: ruleset_audit_state(active_ruleset),
            after: ruleset_audit_state(ruleset),
            diff: ruleset_position_diff(active_ruleset, ruleset),
            links: %{"guardrail_decision_id" => decision.id}
          )

        next_state = %{
          next_state
          | guardrail_decisions: [decision | next_state.guardrail_decisions],
            audit_events: [audit_event | next_state.audit_events]
        }

        next_state = maybe_schedule_auto_advance_tick_in_state(next_state, command)

        {:ok, guardrail_status_payload_in_state(decision, version), next_state}
      end
    end)
  end

  defp persist_guardrail_evaluation_in_state(
         state,
         command,
         environment,
         flag_environment,
         active_ruleset,
         rollout_rule,
         evaluated
       ) do
    stable_target =
      if evaluated.state == :rollback_triggered do
        latest_stable_guardrail_snapshot_in_state(
          state,
          command.flag_key,
          environment.key,
          rollout_rule.key,
          rollout_rule.rollout.salt,
          variant_fingerprint_in_state(rollout_rule),
          command.metadata["request_id"]
        )
      end

    cond do
      evaluated.state == :rollback_triggered and stable_target ->
        rollback_guardrail_in_state(
          state,
          command,
          environment,
          flag_environment,
          active_ruleset,
          rollout_rule,
          evaluated,
          stable_target
        )

      evaluated.state == :rollback_triggered ->
        persist_guardrail_decision_in_state(
          state,
          command,
          environment,
          flag_environment,
          active_ruleset,
          rollout_rule,
          %{evaluated | state: :held, reason: "stable_target_missing"},
          :hold,
          "rollout.guardrail_held"
        )

      evaluated.state == :held ->
        persist_guardrail_decision_in_state(
          state,
          command,
          environment,
          flag_environment,
          active_ruleset,
          rollout_rule,
          evaluated,
          :hold,
          "rollout.guardrail_held"
        )

      true ->
        persist_guardrail_decision_in_state(
          state,
          command,
          environment,
          flag_environment,
          active_ruleset,
          rollout_rule,
          evaluated,
          :evaluate,
          "rollout.guardrail_evaluated"
        )
    end
  end

  defp persist_guardrail_decision_in_state(
         state,
         command,
         environment,
         flag_environment,
         active_ruleset,
         rollout_rule,
         evaluated,
         action_type,
         event_type
       ) do
    authored_snapshot =
      if evaluated.state == :healthy and evaluated.monitoring_window_closed? do
        active_ruleset
      end

    decision =
      build_guardrail_decision(%{
        flag_key: command.flag_key,
        environment_key: environment.key,
        rule_key: rollout_rule.key,
        stage: command.stage,
        decision_state: evaluated.state,
        action_type: action_type,
        decision_reason: evaluated.reason,
        effective_percentage: rollout_rule.rollout.percentage,
        rollout_salt: rollout_rule.rollout.salt,
        variant_fingerprint: variant_fingerprint_in_state(rollout_rule),
        monitoring_window_started_at: command.monitoring_window_started_at,
        monitoring_window_ends_at: command.monitoring_window_ends_at,
        occurred_at: state.now,
        signal_facts: Enum.map(evaluated.signal_facts, &SignalFact.metadata/1),
        guardrail_evidence: first_guardrail_evidence_in_state(evaluated.signal_facts),
        authored_snapshot: authored_snapshot,
        correlation_id: command.metadata["request_id"] || Ecto.UUID.generate(),
        metadata: command.metadata
      })

    {audit_event, next_state} =
      append_audit_event(state, command, event_type, :ok,
        links: %{"guardrail_decision_id" => decision.id},
        guardrail: first_guardrail_evidence_in_state(evaluated.signal_facts)
      )

    next_state = %{
      next_state
      | guardrail_decisions: [decision | next_state.guardrail_decisions],
        audit_events: [audit_event | next_state.audit_events]
    }

    {:ok, guardrail_status_payload_in_state(decision, flag_environment.active_ruleset_version),
     next_state}
  end

  defp rollback_guardrail_in_state(
         state,
         command,
         environment,
         flag_environment,
         active_ruleset,
         rollout_rule,
         evaluated,
         stable_target
       ) do
    version = next_ruleset_version(state, command.flag_key, environment.key)

    ruleset =
      stable_target.authored_snapshot
      |> Map.put(:id, Ecto.UUID.generate())
      |> Map.put(:version, version)
      |> Map.put(:status, :published)
      |> Map.put(:published_at, state.now)
      |> Map.put(:updated_at, state.now)
      |> Map.put(:inserted_at, state.now)

    next_state =
      state
      |> put_ruleset(command.flag_key, environment.key, ruleset)
      |> put_in(
        [:flags, to_string(command.flag_key), :environments, environment.key],
        %{
          flag_environment
          | active_ruleset_version: version,
            status: :active,
            last_published_at: state.now,
            updated_at: state.now
        }
      )
      |> put_runtime_snapshot(environment.key)

    decision =
      build_guardrail_decision(%{
        flag_key: command.flag_key,
        environment_key: environment.key,
        rule_key: rollout_rule.key,
        stage: command.stage,
        decision_state: :rollback_triggered,
        action_type: :rollback,
        decision_reason: evaluated.reason,
        effective_percentage: rollout_rule.rollout.percentage,
        rollout_salt: rollout_rule.rollout.salt,
        variant_fingerprint: variant_fingerprint_in_state(rollout_rule),
        monitoring_window_started_at: command.monitoring_window_started_at,
        monitoring_window_ends_at: command.monitoring_window_ends_at,
        occurred_at: state.now,
        signal_facts: Enum.map(evaluated.signal_facts, &SignalFact.metadata/1),
        guardrail_evidence: first_guardrail_evidence_in_state(evaluated.signal_facts),
        authored_snapshot: active_ruleset,
        rollback_target_snapshot: stable_target.authored_snapshot,
        correlation_id: command.metadata["request_id"] || Ecto.UUID.generate(),
        metadata: command.metadata
      })

    {audit_event, next_state} =
      append_audit_event(next_state, command, "rollout.guardrail_rollback", :ok,
        before: ruleset_audit_state(active_ruleset),
        after: ruleset_audit_state(ruleset),
        diff: ruleset_position_diff(active_ruleset, ruleset),
        links: %{
          "guardrail_decision_id" => decision.id,
          "stable_guardrail_decision_id" => stable_target.id
        },
        guardrail: first_guardrail_evidence_in_state(evaluated.signal_facts)
      )

    next_state = %{
      next_state
      | guardrail_decisions: [decision | next_state.guardrail_decisions],
        audit_events: [audit_event | next_state.audit_events]
    }

    {:ok, guardrail_status_payload_in_state(decision, version), next_state}
  end

  defp ensure_active_ruleset_in_state(%{active_ruleset_version: nil}, _flag, _environment_key),
    do: {:error, StoreError.invalid_command("rollout_stage_conflict")}

  defp ensure_active_ruleset_in_state(flag_environment, flag, environment_key) do
    case active_ruleset_payload(flag, environment_key, flag_environment.active_ruleset_version) do
      nil -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
      ruleset -> {:ok, ruleset}
    end
  end

  defp resolve_rollout_rule_in_state(ruleset, nil) do
    rollout_rules = Enum.filter(ruleset.rules, &(not is_nil(&1.rollout)))

    case rollout_rules do
      [rule] -> {:ok, rule}
      _other -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
    end
  end

  defp resolve_rollout_rule_in_state(ruleset, rule_key) do
    case Enum.find(ruleset.rules, &(&1.key == rule_key and not is_nil(&1.rollout))) do
      nil -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
      rule -> {:ok, rule}
    end
  end

  defp ensure_rollout_percentage_in_state(percentage)
       when is_integer(percentage) and percentage >= 0 and percentage <= 100,
       do: {:ok, percentage}

  defp ensure_rollout_percentage_in_state(_percentage),
    do: {:error, StoreError.invalid_command("rollout_stage_conflict")}

  defp advanced_ruleset_attrs_in_state(ruleset, rule_key, percentage) do
    rules =
      Enum.map(ruleset.rules, fn rule ->
        if rule.key == rule_key and rule.rollout do
          put_in(rule.rollout.percentage, percentage)
        else
          rule
        end
      end)

    {:ok, %{salt: ruleset.salt, metadata: ruleset.metadata, rules: rules}}
  end

  defp latest_stable_guardrail_snapshot_in_state(
         state,
         flag_key,
         environment_key,
         rule_key,
         rollout_salt,
         variant_fingerprint,
         correlation_id
       ) do
    state.guardrail_decisions
    |> Enum.filter(fn decision ->
      decision.flag_key == to_string(flag_key) and
        decision.environment_key == to_string(environment_key) and
        decision.rule_key == to_string(rule_key) and
        decision.decision_state == :healthy and
        not is_nil(decision.authored_snapshot) and
        decision.rollout_salt == rollout_salt and
        decision.variant_fingerprint == variant_fingerprint and
        decision.correlation_id != correlation_id
    end)
    |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
    |> List.first()
  end

  defp build_guardrail_decision(attrs) do
    %{
      id: Ecto.UUID.generate(),
      flag_key: to_string(attrs.flag_key),
      environment_key: to_string(attrs.environment_key),
      rule_key: to_string(attrs.rule_key),
      stage: to_string(attrs.stage),
      tenant_key: attrs[:tenant_key],
      decision_state: attrs.decision_state,
      action_type: attrs.action_type,
      decision_reason: attrs.decision_reason,
      effective_percentage: attrs[:effective_percentage],
      rollout_salt: attrs[:rollout_salt],
      variant_fingerprint: attrs[:variant_fingerprint],
      monitoring_window_started_at: attrs[:monitoring_window_started_at],
      monitoring_window_ends_at: attrs[:monitoring_window_ends_at],
      occurred_at: attrs.occurred_at,
      signal_facts: attrs[:signal_facts] || [],
      guardrail_evidence: attrs[:guardrail_evidence] || %{},
      authored_snapshot: attrs[:authored_snapshot],
      rollback_target_snapshot: attrs[:rollback_target_snapshot],
      correlation_id: attrs[:correlation_id],
      metadata: attrs[:metadata] || %{},
      inserted_at: attrs.occurred_at
    }
  end

  defp guardrail_status_payload_in_state(decision, active_ruleset_version) do
    %{
      flag_key: decision.flag_key,
      environment_key: decision.environment_key,
      rule_key: decision.rule_key,
      stage: decision.stage,
      active_ruleset_version: active_ruleset_version,
      decision: decision
    }
  end

  defp first_guardrail_evidence_in_state([]), do: %{}
  defp first_guardrail_evidence_in_state([fact | _rest]), do: SignalFact.metadata(fact)

  defp variant_fingerprint_in_state(rule) do
    rule.variants
    |> Enum.map(fn variant ->
      %{key: variant.key, weight: variant.weight, value: variant.value}
    end)
    |> Jason.encode!()
  end

  defp execute_kill_switch_transition(
         state,
         flag_key,
         environment_key,
         flag_environment,
         direction,
         command,
         metadata
       ) do
    updated_flag_environment =
      case direction do
        :engage ->
          flag_environment
          |> Map.put(:status, :killswitched)
          |> Map.put(:kill_switch_variant_key, "default")
          |> Map.put(:updated_at, state.now)

        :release ->
          flag_environment
          |> Map.put(
            :status,
            if(flag_environment.status == :killswitched,
              do: :active,
              else: flag_environment.status || :active
            )
          )
          |> Map.put(:kill_switch_variant_key, nil)
          |> Map.put(:updated_at, state.now)
      end

    next_state =
      put_in(
        state.flags[to_string(flag_key)].environments[environment_key],
        updated_flag_environment
      )
      |> put_runtime_snapshot(environment_key)

    event_type =
      case direction do
        :engage -> "kill_switch.engage"
        :release -> "kill_switch.release"
      end

    audit_command =
      case direction do
        :engage ->
          Command.EngageKillSwitch.new(flag_key, environment_key,
            actor: command.actor,
            reason: command.reason,
            metadata: metadata
          )

        :release ->
          Command.ReleaseKillSwitch.new(flag_key, environment_key,
            actor: command.actor,
            reason: command.reason,
            metadata: metadata
          )
      end

    {audit_event, next_state} =
      append_audit_event(next_state, audit_command, event_type, :ok,
        before: audit_state(flag_environment),
        after: audit_state(updated_flag_environment)
      )

    payload =
      build_flag_detail_payload(
        next_state,
        next_state.flags[to_string(flag_key)],
        next_state.environments[environment_key],
        updated_flag_environment,
        true
      )

    {:ok, payload, %{next_state | audit_events: [audit_event | next_state.audit_events]}}
  end

  defp emit_governance_telemetry(event, command, change_request, audit_event) do
    change_request_map = if is_map(change_request), do: change_request, else: %{}
    audit_event_map = if is_map(audit_event), do: audit_event, else: %{}

    Telemetry.execute(
      [:rulestead, :admin, :change_request, event],
      %{count: 1},
      Telemetry.metadata(
        Telemetry.governance_metadata(command, %{
          event: event,
          action: governance_action(Map.get(change_request_map, :governed_action)),
          environment_key: Map.get(change_request_map, :environment_key),
          resource_key: Map.get(change_request_map, :resource_key),
          change_request_id: Map.get(change_request_map, :id),
          correlation_id: Map.get(change_request_map, :correlation_id),
          audit_event_id: Map.get(audit_event_map, :id)
        })
      )
    )
  end

  defp related_audit_events(state, change_request) do
    state.audit_events
    |> Enum.filter(&(&1.correlation_id == change_request.correlation_id))
    |> Enum.sort_by(& &1.occurred_at, DateTime)
  end

  defp matches_change_request_filter?(change_request, command) do
    matches_environment =
      is_nil(command.environment_key) or change_request.environment_key == command.environment_key

    matches_action =
      is_nil(command.action) or
        change_request.governed_action == normalize_change_request_filter(command.action)

    matches_status =
      is_nil(command.status) or
        change_request.status == normalize_change_request_filter(command.status)

    matches_resource_type =
      is_nil(command.resource_type) or change_request.resource_type == command.resource_type

    matches_resource_key =
      is_nil(command.resource_key) or change_request.resource_key == command.resource_key

    matches_submitter =
      is_nil(command.submitted_by_id) or change_request.submitter_id == command.submitted_by_id

    matches_environment and matches_action and matches_status and matches_resource_type and
      matches_resource_key and matches_submitter
  end

  defp fetch_scheduled_execution_record(state, scheduled_execution_id) do
    case Map.fetch(state.scheduled_executions, to_string(scheduled_execution_id)) do
      {:ok, scheduled_execution} -> {:ok, scheduled_execution}
      :error -> {:error, StoreError.invalid_command("scheduled execution was not found")}
    end
  end

  defp approved_snapshot(state, change_request_id) do
    state.approvals
    |> Map.get(change_request_id, [])
    |> Enum.filter(&(&1.decision == "approved"))
    |> Enum.map(fn approval ->
      %{
        "id" => approval.reviewer_id,
        "type" => approval.reviewer_type,
        "display" => approval.reviewer_display
      }
    end)
  end

  defp maybe_schedule_auto_advance_tick_in_state(state, %Command.AdvanceRollout{} = command) do
    fetch_command =
      Command.FetchRolloutAutoAdvancePolicy.new(
        command.flag_key,
        command.environment_key,
        command.rule_key
      )

    with {:ok, policy} <- fetch_rollout_auto_advance_policy_in_state(state, fetch_command),
         true <- Schedule.schedulable?(command, policy) do
      state =
        cancel_superseded_auto_advance_ticks_in_state(
          state,
          command.flag_key,
          command.environment_key,
          command.rule_key,
          Schedule.scheduler_actor()
        )

      schedule_command = Schedule.schedule_command(command, policy)

      {:ok, _payload, next_state} = schedule_governed_action_in_state(state, schedule_command)
      next_state
    else
      _ -> state
    end
  end

  defp schedule_governed_action_in_state(state, %Command.ScheduleGovernedAction{} = command) do
    correlation_id = governance_correlation_id(command)

    idempotency_key =
      command.idempotency_key ||
        "scheduled_execution:#{correlation_id}"

    case fetch_idempotent_scheduled_execution_in_state(state, idempotency_key) do
      {:ok, existing} ->
        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(existing),
           attempts:
             list_execution_attempts(state, existing.id)
             |> Enum.map(&serialize_execution_attempt/1)
         }, state}

      :not_found ->
        scheduled_execution =
          new_scheduled_execution_record(state, %{
            change_request_id: nil,
            governed_action: Atom.to_string(command.action),
            environment_key: command.environment_key,
            resource_type: command.resource_type,
            resource_key: command.resource_key,
            execution_mode: Atom.to_string(command.execution_mode),
            scheduled_by_id: actor_value(command.actor, "id"),
            scheduled_by_type: actor_value(command.actor, "type") || "operator",
            scheduled_by_display: actor_value(command.actor, "display"),
            approved_by_snapshot: [],
            scheduled_for: command.scheduled_for,
            command_snapshot: Command.GovernanceSupport.with_tenant_provenance(command.command),
            approval_requirement_snapshot: command.approval_requirement,
            metadata:
              Command.GovernanceSupport.with_tenant_provenance(command.metadata, command.command),
            correlation_id: correlation_id,
            idempotency_key: idempotency_key
          })

        next_state = put_in(state.scheduled_executions[scheduled_execution.id], scheduled_execution)

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(scheduled_execution),
           attempts: []
         }, next_state}
    end
  end

  defp cancel_superseded_auto_advance_ticks_in_state(
         state,
         flag_key,
         environment_key,
         rule_key,
         actor
       ) do
    flag_key = to_string(flag_key)
    environment_key = to_string(environment_key)
    rule_key = to_string(rule_key)

    pending_auto_advance_scheduled_executions_in_state(state, flag_key, environment_key, rule_key)
    |> Enum.reduce(state, fn scheduled_execution, acc_state ->
      case cancel_scheduled_execution_in_state(acc_state, %Command.CancelScheduledExecution{
             scheduled_execution_id: scheduled_execution.id,
             actor: actor,
             reason: "superseded by new auto-advance stage advance",
             metadata: %{"source" => "guardrail_automation"}
           }) do
        {:ok, _payload, next_state} -> next_state
        {:error, _error, unchanged_state} -> unchanged_state
      end
    end)
  end

  defp pending_auto_advance_scheduled_executions_in_state(
         state,
         flag_key,
         environment_key,
         rule_key
       ) do
    state.scheduled_executions
    |> Map.values()
    |> Enum.filter(fn scheduled_execution ->
      scheduled_execution.state == "scheduled" and
        scheduled_execution.governed_action == "advance_rollout" and
        to_string(scheduled_execution.resource_key) == flag_key and
        to_string(scheduled_execution.environment_key) == environment_key and
        get_in(scheduled_execution.metadata, ["source"]) == "guardrail_automation" and
        to_string(get_in(scheduled_execution.command_snapshot, ["rollout", "rule_key"]) || "") ==
          rule_key
    end)
  end

  defp cancel_scheduled_execution_in_state(state, %Command.CancelScheduledExecution{} = command) do
    with {:ok, scheduled_execution} <-
           fetch_scheduled_execution_record(state, command.scheduled_execution_id),
         :ok <- ensure_scheduled_transition(scheduled_execution.state, ["scheduled", "running"]) do
      updated =
        scheduled_execution
        |> Map.put(:state, "cancelled")
        |> Map.put(:failure_reason, command.reason)
        |> Map.put(
          :execution_metadata,
          scheduled_transition_metadata(
            scheduled_execution.execution_metadata,
            "cancelled",
            command,
            state.now
          )
        )
        |> Map.put(:updated_at, state.now)

      next_state = put_in(state.scheduled_executions[updated.id], updated)

      {:ok, %{scheduled_execution: serialize_scheduled_execution(updated), attempts: []},
       next_state}
    else
      {:error, error} -> {:error, error, state}
    end
  end

  defp fetch_idempotent_scheduled_execution_in_state(_state, nil), do: :not_found

  defp fetch_idempotent_scheduled_execution_in_state(state, idempotency_key) do
    state.scheduled_executions
    |> Map.values()
    |> Enum.find(fn row ->
      row.idempotency_key == idempotency_key and row.state in ["scheduled", "running", "completed"]
    end)
    |> case do
      nil -> :not_found
      existing -> {:ok, existing}
    end
  end

  defp new_scheduled_execution_record(state, attrs) do
    %{
      id: Ecto.UUID.generate(),
      state: "scheduled",
      change_request_id: attrs.change_request_id,
      governed_action: attrs.governed_action,
      environment_key: attrs.environment_key,
      resource_type: attrs.resource_type,
      resource_key: attrs.resource_key,
      execution_mode: attrs.execution_mode,
      scheduled_by_id: attrs.scheduled_by_id,
      scheduled_by_type: attrs.scheduled_by_type,
      scheduled_by_display: attrs.scheduled_by_display,
      approved_by_snapshot: attrs.approved_by_snapshot,
      execution_metadata: %{},
      scheduled_for: attrs.scheduled_for,
      executed_at: nil,
      attempt_count: 0,
      failure_reason: nil,
      last_oban_job_id: nil,
      command_snapshot: attrs.command_snapshot,
      approval_requirement_snapshot: attrs.approval_requirement_snapshot,
      metadata: attrs.metadata,
      correlation_id: attrs.correlation_id,
      idempotency_key: attrs.idempotency_key,
      inserted_at: state.now,
      updated_at: state.now
    }
  end

  defp replace_attempt(state, updated_attempt) do
    state.execution_attempts
    |> Map.get(updated_attempt.scheduled_execution_id, [])
    |> Enum.map(fn attempt ->
      if attempt.id == updated_attempt.id, do: updated_attempt, else: attempt
    end)
  end

  defp list_execution_attempts(state, scheduled_execution_id) do
    state.execution_attempts
    |> Map.get(scheduled_execution_id, [])
    |> Enum.sort_by(& &1.attempt_number)
  end

  defp serialize_scheduled_execution(row) do
    %{
      id: row.id,
      state: scheduled_state(row.state),
      action: governance_action(row.governed_action),
      change_request_id: row.change_request_id,
      environment_key: row.environment_key,
      resource_type: row.resource_type,
      resource_key: row.resource_key,
      execution_mode: scheduled_execution_mode(row.execution_mode),
      scheduled_by: %{
        "id" => row.scheduled_by_id,
        "type" => row.scheduled_by_type,
        "display" => row.scheduled_by_display
      },
      approved_by_snapshot: row.approved_by_snapshot || [],
      execution_metadata: row.execution_metadata || %{},
      scheduled_for: row.scheduled_for,
      executed_at: row.executed_at,
      attempt_count: row.attempt_count,
      failure_reason: row.failure_reason,
      last_oban_job_id: row.last_oban_job_id,
      correlation_id: row.correlation_id,
      idempotency_key: row.idempotency_key,
      command_snapshot: row.command_snapshot || %{},
      approval_requirement_snapshot: row.approval_requirement_snapshot || %{},
      metadata: row.metadata || %{}
    }
    |> ScheduledExecution.new()
    |> ScheduledExecution.serialize()
    |> Map.put(:id, row.id)
  end

  defp serialize_execution_attempt(row) do
    %{
      id: row.id,
      scheduled_execution_id: row.scheduled_execution_id,
      attempt_number: row.attempt_number,
      state: execution_attempt_state(row.state),
      started_at: row.started_at,
      finished_at: row.finished_at,
      failure_reason: row.failure_reason,
      metadata: row.metadata || %{}
    }
    |> ExecutionAttempt.new()
    |> ExecutionAttempt.serialize()
    |> Map.put(:id, row.id)
  end

  defp matches_scheduled_execution_filter?(scheduled_execution, command) do
    matches_environment =
      is_nil(command.environment_key) or
        scheduled_execution.environment_key == command.environment_key

    matches_state =
      is_nil(command.state) or
        scheduled_execution.state == normalize_change_request_filter(command.state)

    matches_action =
      is_nil(command.action) or
        scheduled_execution.governed_action == normalize_change_request_filter(command.action)

    matches_resource_type =
      is_nil(command.resource_type) or scheduled_execution.resource_type == command.resource_type

    matches_resource_key =
      is_nil(command.resource_key) or scheduled_execution.resource_key == command.resource_key

    matches_actor =
      is_nil(command.scheduled_by_id) or
        scheduled_execution.scheduled_by_id == command.scheduled_by_id

    matches_change_request =
      is_nil(command.change_request_id) or
        scheduled_execution.change_request_id == command.change_request_id

    matches_after =
      is_nil(command.after) or
        DateTime.compare(scheduled_execution.scheduled_for, command.after) != :lt

    matches_before =
      is_nil(command.before) or
        DateTime.compare(scheduled_execution.scheduled_for, command.before) != :gt

    matches_environment and matches_state and matches_action and matches_resource_type and
      matches_resource_key and matches_actor and matches_change_request and matches_after and
      matches_before
  end

  defp actor_value(nil, _key), do: nil
  defp actor_value(actor, key), do: Map.get(actor, key) || Map.get(actor, String.to_atom(key))

  defp normalize_change_request_filter(nil), do: nil
  defp normalize_change_request_filter(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_change_request_filter(value) when is_binary(value), do: String.trim(value)
  defp normalize_change_request_filter(_value), do: nil

  defp normalize_approval_requirement_snapshot(snapshot) do
    %{
      action: governance_action(snapshot["action"] || snapshot[:action] || "manage_settings"),
      environment_key: snapshot["environment_key"] || snapshot[:environment_key],
      required_approvals: snapshot["required_approvals"] || snapshot[:required_approvals] || 0,
      change_request_required?:
        snapshot["change_request_required?"] || snapshot[:change_request_required?] || false,
      self_approval_allowed?:
        snapshot["self_approval_allowed?"] || snapshot[:self_approval_allowed?] || false
    }
  end

  defp ruleset_audit_state(nil), do: %{"rules" => []}

  defp ruleset_audit_state(ruleset) do
    %{
      "rules" =>
        ruleset
        |> Map.get(:rules, [])
        |> Enum.with_index()
        |> Enum.map(fn {rule, position} ->
          %{"key" => rule[:key] || rule["key"], "position" => position}
        end)
    }
  end

  defp ruleset_position_diff(before_ruleset, after_ruleset) do
    before_positions =
      before_ruleset
      |> ruleset_audit_state()
      |> Map.get("rules", [])
      |> Map.new(fn %{"key" => key, "position" => position} -> {key, position} end)

    %{
      "rules" =>
        after_ruleset
        |> ruleset_audit_state()
        |> Map.get("rules", [])
        |> Enum.map(fn %{"key" => key, "position" => position} ->
          %{"key" => key, "from" => Map.get(before_positions, key), "to" => position}
        end)
    }
  end

  defp next_ruleset_version(flag, environment_key) do
    flag.rulesets
    |> Map.get(environment_key, %{})
    |> Map.keys()
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp put_ruleset(state, flag_key, environment_key, ruleset_record) do
    update_in(state.flags[to_string(flag_key)].rulesets[environment_key], fn rulesets ->
      Map.put(rulesets || %{}, ruleset_record.version, ruleset_record)
    end)
  end

  defp resolve_publishable_ruleset(flag, environment_key, version) do
    rulesets = Map.get(flag.rulesets, environment_key, %{})

    case normalize_publish_version(version, rulesets) do
      {:ok, publish_version} ->
        case Map.fetch(rulesets, publish_version) do
          {:ok, %{status: :draft} = ruleset_record} ->
            {:ok, ruleset_record}

          {:ok, _ruleset_record} ->
            {:error,
             StoreError.invalid_command(
               "requested ruleset version is not publishable",
               metadata: %{
                 requested_version: publish_version,
                 active_version: active_version(flag, environment_key)
               }
             )}

          :error ->
            {:error,
             RulesetError.not_found(
               metadata: %{requested_version: publish_version, environment_key: environment_key}
             )}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp normalize_publish_version(nil, rulesets) do
    draft_version =
      rulesets
      |> Enum.filter(fn {_version, ruleset} -> ruleset.status == :draft end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.max(fn -> nil end)

    case draft_version do
      nil -> {:error, RulesetError.not_found()}
      version -> {:ok, version}
    end
  end

  defp normalize_publish_version(version, _rulesets) when is_integer(version) and version > 0 do
    {:ok, version}
  end

  defp normalize_publish_version(version, _rulesets) when is_binary(version) do
    case Integer.parse(version) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, StoreError.invalid_command("publish version must be a positive integer")}
    end
  end

  defp normalize_publish_version(_version, _rulesets) do
    {:error, StoreError.invalid_command("publish version must be a positive integer")}
  end

  defp active_version(flag, environment_key) do
    flag.environments
    |> Map.get(environment_key, %{})
    |> Map.get(:active_ruleset_version)
  end

  defp publish_ruleset_record(state, flag_key, environment_key, flag_environment, ruleset_record) do
    published_ruleset =
      ruleset_record
      |> Map.put(:status, :published)
      |> Map.put(:published_at, state.now)
      |> Map.put(:updated_at, state.now)

    next_state =
      state
      |> put_in(
        [:flags, to_string(flag_key), :rulesets, environment_key, ruleset_record.version],
        published_ruleset
      )
      |> put_in(
        [:flags, to_string(flag_key), :environments, environment_key],
        %{
          flag_environment
          | active_ruleset_version: ruleset_record.version,
            last_published_at: state.now,
            status: :active,
            updated_at: state.now
        }
      )
      |> put_in([:flags, to_string(flag_key), :updated_at], state.now)
      |> put_runtime_snapshot(environment_key)

    {:ok, next_state}
  end

  defp do_apply_promotion(state, command, opts) do
    allow_protected_target? = Keyword.get(opts, :allow_protected_target?, false)

    with {:ok, _source_environment} <-
           fetch_environment_from_state(state, command.source_environment_key),
         {:ok, target_environment} <-
           fetch_environment_from_state(state, command.target_environment_key),
         :ok <-
           ensure_promotion_target_allowed(
             target_environment.key,
             allow_protected_target?
           ),
         # Fail closed for direct apply and replay/re-apply paths.
         :ok <-
           Apply.validate_live_dependencies(
             command,
             Map.get(state, :audiences, %{}),
             message: "promotion apply blocked by dependency validation"
           ),
         {:ok, compare} <- compare_environments_in_state(state, compare_command(command)),
         :ok <- Apply.validate_with_compare(command, compare, allow_protected_target?: allow_protected_target?),
         {:ok, applied_state} <- apply_promotion_bundle(state, target_environment.key, command) do
      version = next_environment_version(state, target_environment.key)

      environment_version =
        normalize_environment_version(%EnvironmentVersion{
          id: Ecto.UUID.generate(),
          environment_key: target_environment.key,
          version: version,
          authored_snapshot: command.proposed_target_bundle,
          source_environment_key: command.source_environment_key,
          target_environment_key: command.target_environment_key,
          compare_token: command.compare_token,
          source_fingerprint: command.source_fingerprint,
          target_fingerprint: command.target_fingerprint,
          dependency_closure_keys: command.dependency_closure_keys,
          applied_flag_keys: command.flag_keys,
          tenant_key: command.tenant_key,
          metadata: %{
            "actor" => command.actor || %{},
            "reason" => command.reason,
            "metadata" => command.metadata,
            "tenant" => Command.GovernanceSupport.tenant_provenance(command)
          },
          inserted_at: applied_state.now,
          updated_at: applied_state.now
        })

      next_state =
        applied_state
        |> update_in([:environment_versions], fn environment_versions ->
          Map.update(
            environment_versions,
            target_environment.key,
            %{version => environment_version},
            fn versions ->
              Map.put(versions, version, environment_version)
            end
          )
        end)
        |> put_runtime_snapshot(target_environment.key)

      snapshot_version = next_snapshot_version(applied_state, target_environment.key)

      {:ok,
       %{
         source_environment_key: command.source_environment_key,
         target_environment_key: command.target_environment_key,
         compare_token: command.compare_token,
         compare_schema_version: command.compare_schema_version,
         applied_flag_keys: command.flag_keys,
         dependency_closure_keys: command.dependency_closure_keys,
         environment_version_id: environment_version.id,
         environment_version_version: environment_version.version,
         snapshot_version: snapshot_version
       }, next_state}
    end
  end

  defp do_apply_manifest_import(state, command, opts) do
    with {:ok, target_environment} <-
           fetch_environment_from_state(state, command.target_environment_key),
         :ok <-
           ensure_promotion_target_allowed(
             target_environment.key,
             Keyword.get(opts, :allow_protected_target?, false)
           ),
         {:ok, applied_state} <-
           apply_manifest_import_bundle(state, target_environment.key, command) do
      version = next_environment_version(state, target_environment.key)

      environment_version =
        normalize_environment_version(%EnvironmentVersion{
          id: Ecto.UUID.generate(),
          environment_key: target_environment.key,
          version: version,
          authored_snapshot: command.proposed_target_bundle,
          source_environment_key: command.source_environment_key,
          target_environment_key: command.target_environment_key,
          compare_token: command.plan_token,
          source_fingerprint: nil,
          target_fingerprint: command.target_fingerprint,
          dependency_closure_keys: command.dependency_closure_keys,
          applied_flag_keys: command.flag_keys,
          tenant_key: command.tenant_key,
          metadata: %{
            "mode" => "manifest_import",
            "actor" => command.actor || %{},
            "reason" => command.reason,
            "metadata" => command.metadata,
            "tenant" => Command.GovernanceSupport.tenant_provenance(command)
          },
          inserted_at: applied_state.now,
          updated_at: applied_state.now
        })

      next_state =
        applied_state
        |> update_in([:environment_versions], fn environment_versions ->
          Map.update(
            environment_versions,
            target_environment.key,
            %{version => environment_version},
            fn versions ->
              Map.put(versions, version, environment_version)
            end
          )
        end)
        |> put_runtime_snapshot(target_environment.key)

      snapshot_version = next_snapshot_version(applied_state, target_environment.key)

      {:ok,
       %{
         source_environment_key: command.source_environment_key,
         target_environment_key: command.target_environment_key,
         plan_token: command.plan_token,
         applied_flag_keys: command.flag_keys,
         dependency_closure_keys: command.dependency_closure_keys,
         environment_version_id: environment_version.id,
         environment_version_version: environment_version.version,
         snapshot_version: snapshot_version
       }, next_state}
    end
  end

  defp ensure_promotion_target_allowed(_target_environment_key, true), do: :ok

  defp ensure_promotion_target_allowed(target_environment_key, false) do
    if Compare.protected_target?(target_environment_key) do
      {:error, StoreError.invalid_command("promotion to protected targets requires governance")}
    else
      :ok
    end
  end

  defp apply_promotion_bundle(state, target_environment_key, command) do
    Enum.reduce_while(command.flag_keys, {:ok, state}, fn flag_key, {:ok, acc_state} ->
      case apply_promoted_flag(acc_state, flag_key, target_environment_key, command) do
        {:ok, next_state} -> {:cont, {:ok, next_state}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp apply_manifest_import_bundle(state, target_environment_key, command) do
    Enum.reduce_while(command.flag_keys, {:ok, state}, fn flag_key, {:ok, acc_state} ->
      case apply_imported_flag(acc_state, flag_key, target_environment_key, command) do
        {:ok, next_state} -> {:cont, {:ok, next_state}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp apply_promoted_flag(state, flag_key, target_environment_key, command) do
    with {:ok, _environment, flag, flag_environment} <-
           fetch_flag_apply_context(state, flag_key, target_environment_key),
         proposed_state <- Map.get(command.proposed_target_bundle, flag_key),
         false <- is_nil(proposed_state) do
      proposed_flag = Map.get(proposed_state, "flag", %{}) |> denormalize_promoted_value()

      proposed_flag_environment =
        Map.get(proposed_state, "flag_environment", %{}) |> denormalize_promoted_value()

      proposed_ruleset =
        Map.get(proposed_state, "active_ruleset", %{}) |> denormalize_promoted_value()

      updated_flag =
        flag
        |> maybe_put(:description, proposed_flag["description"])
        |> maybe_put(:default_value, proposed_flag["default_value"])
        |> maybe_put(:tags, proposed_flag["tags"])
        |> Map.put(:updated_at, state.now)

      ruleset_version = next_ruleset_version(state, flag_key, target_environment_key)

      ruleset_attrs = %{
        flag_environment_id: flag_environment.id,
        version: ruleset_version,
        status: :published,
        salt: proposed_ruleset["salt"],
        published_at: state.now,
        metadata: Map.get(proposed_ruleset, "metadata", %{}),
        rules: Map.get(proposed_ruleset, "rules", [])
      }

      case Changeset.apply_action(Ruleset.changeset(%Ruleset{}, ruleset_attrs), :insert) do
        {:ok, ruleset} ->
          ruleset = serialize_ruleset(ruleset, state.now)

          updated_flag_environment =
            flag_environment
            |> Map.put(:active_ruleset_version, ruleset_version)
            |> Map.put(
              :status,
              normalize_flag_environment_status(proposed_flag_environment["status"])
            )
            |> Map.put(
              :kill_switch_variant_key,
              proposed_flag_environment["kill_switch_variant_key"]
            )
            |> Map.put(:last_published_at, state.now)
            |> Map.put(:last_evaluated_at, proposed_flag_environment["last_evaluated_at"])
            |> Map.put(
              :variants_served,
              Map.get(proposed_flag_environment, "variants_served", %{})
            )
            |> Map.put(:updated_at, state.now)

          next_state =
            state
            |> put_in([:flags, flag_key], updated_flag)
            |> put_in(
              [
                :flags,
                flag_key,
                :environments,
                target_environment_key
              ],
              updated_flag_environment
            )
            |> put_in(
              [:flags, flag_key, :rulesets, target_environment_key, ruleset_version],
              ruleset
            )

          {:ok, next_state}

        {:error, invalid_changeset} ->
          {:error, ruleset_error(invalid_changeset, flag_key, target_environment_key)}
      end
    else
      true ->
        {:error,
         StoreError.invalid_command("promotion bundle is missing a proposed target state",
           metadata: %{flag_key: flag_key}
         )}

      {:error, error} ->
        {:error, error}
    end
  end

  defp apply_imported_flag(state, flag_key, target_environment_key, command) do
    proposed_state = Map.get(command.proposed_target_bundle, flag_key)

    if is_nil(proposed_state) do
      {:error,
       StoreError.invalid_command("manifest import plan is missing a proposed target state",
         metadata: %{flag_key: flag_key}
       )}
    else
      proposed_flag = Map.get(proposed_state, "flag", %{}) |> denormalize_promoted_value()

      proposed_flag_environment =
        Map.get(proposed_state, "flag_environment", %{}) |> denormalize_promoted_value()

      proposed_ruleset =
        Map.get(proposed_state, "active_ruleset", %{}) |> denormalize_promoted_value()

      with {:ok, environment} <- fetch_environment(state, target_environment_key),
           {:ok, next_state, flag} <-
             upsert_import_flag(state, flag_key, proposed_flag, target_environment_key),
           :ok <- ensure_not_archived(flag_key, flag),
           {:ok, next_state, flag_environment} <-
             upsert_import_flag_environment(
               next_state,
               flag,
               environment,
               proposed_flag_environment
             ) do
        ruleset_version = next_ruleset_version(next_state, flag_key, target_environment_key)

        ruleset_attrs = %{
          flag_environment_id: flag_environment.id,
          version: ruleset_version,
          status: :published,
          salt: proposed_ruleset["salt"],
          published_at: next_state.now,
          metadata: Map.get(proposed_ruleset, "metadata", %{}),
          rules: Map.get(proposed_ruleset, "rules", [])
        }

        case Changeset.apply_action(Ruleset.changeset(%Ruleset{}, ruleset_attrs), :insert) do
          {:ok, ruleset} ->
            ruleset = serialize_ruleset(ruleset, next_state.now)

            updated_flag_environment =
              flag_environment
              |> Map.put(:active_ruleset_version, ruleset_version)
              |> Map.put(
                :status,
                normalize_flag_environment_status(proposed_flag_environment["status"])
              )
              |> Map.put(
                :kill_switch_variant_key,
                proposed_flag_environment["kill_switch_variant_key"]
              )
              |> Map.put(:last_published_at, next_state.now)
              |> Map.put(:last_evaluated_at, proposed_flag_environment["last_evaluated_at"])
              |> Map.put(
                :variants_served,
                Map.get(proposed_flag_environment, "variants_served", %{})
              )
              |> Map.put(:updated_at, next_state.now)

            final_state =
              next_state
              |> put_in(
                [:flags, flag_key, :environments, target_environment_key],
                updated_flag_environment
              )
              |> put_in(
                [:flags, flag_key, :rulesets, target_environment_key, ruleset_version],
                ruleset
              )

            {:ok, final_state}

          {:error, invalid_changeset} ->
            {:error, ruleset_error(invalid_changeset, flag_key, target_environment_key)}
        end
      end
    end
  end

  defp upsert_import_flag(state, flag_key, proposed_flag, target_environment_key) do
    normalized_flag_key = to_string(flag_key)

    case Map.get(state.flags, normalized_flag_key) do
      nil ->
        attrs = %{
          key: normalized_flag_key,
          description: proposed_flag["description"],
          flag_type: normalize_import_flag_type(proposed_flag["flag_type"]),
          value_type: normalize_import_value_type(proposed_flag["value_type"]),
          default_value: proposed_flag["default_value"] || %{},
          tags: proposed_flag["tags"] || [],
          environment_keys: [target_environment_key]
        }

        case do_put_flag(state, attrs) do
          {:ok, _payload, next_state} -> {:ok, next_state, next_state.flags[normalized_flag_key]}
          {:error, error} -> {:error, error}
        end

      flag ->
        updated_flag =
          flag
          |> maybe_put(:description, proposed_flag["description"])
          |> maybe_put(:default_value, proposed_flag["default_value"])
          |> maybe_put(:tags, proposed_flag["tags"])
          |> Map.put(:updated_at, state.now)

        {:ok, put_in(state.flags[normalized_flag_key], updated_flag), updated_flag}
    end
  end

  defp upsert_import_flag_environment(state, flag, environment, proposed_flag_environment) do
    case Map.get(flag.environments, environment.key) do
      %{status: :archived} ->
        {:error,
         StoreError.invalid_command("manifest import would revive an archived flag environment",
           metadata: %{flag_key: flag.key}
         )}

      nil ->
        flag_environment = %{
          id: Ecto.UUID.generate(),
          flag_id: flag.id,
          environment_id: environment.id,
          environment_key: environment.key,
          status: normalize_flag_environment_status(proposed_flag_environment["status"]),
          kill_switch_variant_key: proposed_flag_environment["kill_switch_variant_key"],
          active_ruleset_version: nil,
          last_published_at: nil,
          last_evaluated_at: proposed_flag_environment["last_evaluated_at"],
          variants_served: Map.get(proposed_flag_environment, "variants_served", %{}),
          inserted_at: state.now,
          updated_at: state.now
        }

        next_state =
          state
          |> put_in([:flags, flag.key, :environments, environment.key], flag_environment)
          |> update_in([:flags, flag.key, :rulesets], fn rulesets ->
            Map.put(rulesets || %{}, environment.key, %{})
          end)

        {:ok, next_state, flag_environment}

      flag_environment ->
        {:ok, state, flag_environment}
    end
  end

  defp normalize_import_flag_type(value) when is_binary(value) do
    try do
      parsed = String.to_existing_atom(value)
      if parsed in Flag.flag_types(), do: parsed, else: :release
    rescue
      ArgumentError -> :release
    end
  end

  defp normalize_import_flag_type(value) when is_atom(value) do
    if value in Flag.flag_types(), do: value, else: :release
  end

  defp normalize_import_flag_type(_value), do: :release

  defp normalize_import_value_type(value) when is_binary(value) do
    try do
      parsed = String.to_existing_atom(value)
      if parsed in Flag.value_types(), do: parsed, else: :boolean
    rescue
      ArgumentError -> :boolean
    end
  end

  defp normalize_import_value_type(value) when is_atom(value) do
    if value in Flag.value_types(), do: value, else: :boolean
  end

  defp normalize_import_value_type(_value), do: :boolean

  defp fetch_flag_apply_context(state, flag_key, environment_key) do
    with {:ok, environment} <- fetch_environment_from_state(state, environment_key),
         {:ok, flag, flag_environment} <- fetch_flag_environment(state, flag_key, environment_key) do
      {:ok, environment, flag, flag_environment}
    end
  end

  defp next_ruleset_version(state, flag_key, environment_key) do
    state.flags
    |> Map.fetch!(flag_key)
    |> next_ruleset_version(environment_key)
  end

  defp next_environment_version(state, environment_key) do
    state.environment_versions
    |> Map.get(environment_key, %{})
    |> Map.keys()
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp normalize_environment_version(%EnvironmentVersion{} = environment_version) do
    %{
      id: environment_version.id,
      environment_key: environment_version.environment_key,
      version: environment_version.version,
      authored_snapshot: environment_version.authored_snapshot,
      source_environment_key: environment_version.source_environment_key,
      target_environment_key: environment_version.target_environment_key,
      compare_token: environment_version.compare_token,
      source_fingerprint: environment_version.source_fingerprint,
      target_fingerprint: environment_version.target_fingerprint,
      dependency_closure_keys: environment_version.dependency_closure_keys,
      applied_flag_keys: environment_version.applied_flag_keys,
      tenant_key: environment_version.tenant_key,
      metadata: environment_version.metadata,
      inserted_at: environment_version.inserted_at,
      updated_at: environment_version.updated_at
    }
  end

  defp normalize_flag_environment_status(nil), do: :active

  defp normalize_flag_environment_status(status) when is_binary(status) do
    case String.to_existing_atom(status) do
      normalized ->
        if normalized in Rulestead.FlagEnvironment.statuses(), do: normalized, else: :active
    end
  rescue
    ArgumentError -> :active
  end

  defp normalize_flag_environment_status(status) when is_atom(status) do
    if status in Rulestead.FlagEnvironment.statuses(), do: status, else: :active
  end

  defp normalize_flag_environment_status(_status), do: :active

  defp denormalize_promoted_value(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {key, denormalize_promoted_value(value)} end)
  end

  defp denormalize_promoted_value(list) when is_list(list) do
    Enum.map(list, &denormalize_promoted_value/1)
  end

  defp denormalize_promoted_value("nil"), do: nil
  defp denormalize_promoted_value("true"), do: true
  defp denormalize_promoted_value("false"), do: false
  defp denormalize_promoted_value(value), do: value

  defp put_runtime_snapshot(state, environment_key) do
    snapshot_payload = build_environment_snapshot_payload(state, environment_key)
    payload = :erlang.term_to_binary(snapshot_payload)
    version = next_snapshot_version(state, environment_key)

    snapshot = %{
      id: Ecto.UUID.generate(),
      environment_key: environment_key,
      version: version,
      payload: payload,
      payload_checksum: payload_checksum(payload),
      metadata: %{
        schema_version: @snapshot_schema_version,
        flag_count: map_size(snapshot_payload.flags)
      },
      published_at: state.now,
      inserted_at: state.now,
      updated_at: state.now
    }

    Telemetry.execute(
      [:rulestead, :runtime, :snapshot, :published],
      %{count: 1},
      Telemetry.metadata(%{
        environment: environment_key,
        snapshot_version: version,
        reason: :published
      })
    )

    :ok =
      Notifier.broadcast(
        Config.notifier(),
        %{environment_key: environment_key, snapshot_version: version},
        pubsub: Config.pubsub(),
        pubsub_topic: Config.pubsub_topic()
      )

    state
    |> update_in([:snapshots], fn snapshots ->
      Map.update(snapshots, environment_key, %{version => snapshot}, fn environment_snapshots ->
        Map.put(environment_snapshots, version, snapshot)
      end)
    end)
    |> refresh_audience_reference_projection(environment_key)
  end

  defp build_environment_snapshot_payload(state, environment_key) do
    flags =
      state.flags
      |> Map.values()
      |> Enum.reject(&archived?/1)
      |> Enum.filter(fn flag ->
        match?(
          %{status: status, active_ruleset_version: version}
          when status in [:active, :killswitched] and not is_nil(version),
          flag.environments[environment_key]
        )
      end)
      |> Enum.sort_by(& &1.key)
      |> Map.new(fn flag ->
        flag_environment = flag.environments[environment_key]
        environment = state.environments[environment_key]

        {flag.key, build_flag_payload(flag, environment, flag_environment, true)}
      end)

    %{
      schema_version: @snapshot_schema_version,
      environment_key: environment_key,
      generated_at: state.now,
      flags: flags,
      audiences: compiled_audience_definitions(state)
    }
  end

  defp compiled_audience_definitions(state) do
    state.audiences
    |> Map.values()
    |> Enum.reject(&Map.get(&1, :archived_at))
    |> Enum.filter(&(Map.get(&1, :definition) |> is_map()))
    |> Enum.sort_by(& &1.key)
    |> Map.new(fn audience ->
      {audience.key,
       %{
         definition: audience.definition,
         archived_at: Map.get(audience, :archived_at)
       }}
    end)
  end

  defp next_snapshot_version(state, environment_key) do
    state.snapshots
    |> Map.get(environment_key, %{})
    |> Map.keys()
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp fetch_runtime_snapshot(state, environment_key, nil) do
    case state.snapshots
         |> Map.get(environment_key, %{})
         |> Enum.max_by(&elem(&1, 0), fn -> nil end) do
      nil -> {:error, StoreError.snapshot_not_found(environment_key)}
      {_version, snapshot} -> {:ok, snapshot}
    end
  end

  defp fetch_runtime_snapshot(state, environment_key, version) do
    case get_in(state.snapshots, [environment_key, version]) do
      nil ->
        {:error,
         StoreError.snapshot_not_found(
           environment_key,
           metadata: %{environment_key: environment_key, version: version}
         )}

      snapshot ->
        {:ok, snapshot}
    end
  end

  defp payload_checksum(payload) do
    :sha256
    |> :crypto.hash(payload)
    |> Base.encode16(case: :lower)
  end

  defp build_flag_payload(flag, environment, flag_environment, include_ruleset?) do
    %{
      flag: flag_summary(flag),
      environment: environment,
      flag_environment: flag_environment_summary(flag_environment),
      active_ruleset:
        if(include_ruleset?,
          do:
            runtime_ruleset_payload(
              active_ruleset_payload(
                flag,
                environment.key,
                flag_environment.active_ruleset_version
              ),
              flag_environment
            )
        ),
      draft_rulesets:
        if(include_ruleset?,
          do: draft_ruleset_payloads(flag, environment.key),
          else: []
        )
    }
  end

  defp build_flag_detail_payload(state, flag, environment, flag_environment, include_ruleset?) do
    build_flag_payload(flag, environment, flag_environment, include_ruleset?)
    |> decorate_payload(state, flag, environment, flag_environment)
  end

  defp build_archive_payload(flag) do
    %{
      flag: flag_summary(flag),
      archived?: archived?(flag),
      environment_keys: flag.environments |> Map.keys() |> Enum.sort()
    }
  end

  defp build_create_payload(state, flag) do
    %{
      flag: flag_summary(flag),
      archived?: archived?(flag),
      environment_keys: flag.environments |> Map.keys() |> Enum.sort(),
      environments:
        flag.environments
        |> Map.keys()
        |> Enum.map(&state.environments[&1])
        |> Enum.sort_by(& &1.key),
      recent_owners: recent_owners(state, flag.ownership.owner_ref)
    }
  end

  defp build_update_payload(state, flag) do
    {environment, flag_environment} = preferred_environment(state, flag)
    build_flag_detail_payload(state, flag, environment, flag_environment, true)
  end

  defp flag_summary(flag) do
    Map.take(flag, [
      :id,
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :ownership,
      :lifecycle,
      :tags,
      :code_reference_count,
      :code_refs_scan,
      :archived_at,
      :inserted_at,
      :updated_at
    ])
  end

  defp audience_summary(audience) do
    Map.take(audience, [
      :id,
      :key,
      :description,
      :definition,
      :archived_at,
      :inserted_at,
      :updated_at
    ])
  end

  defp flag_environment_summary(flag_environment) do
    Map.take(flag_environment, [
      :id,
      :environment_key,
      :status,
      :kill_switch_variant_key,
      :active_ruleset_version,
      :last_published_at,
      :last_evaluated_at,
      :inserted_at,
      :updated_at
    ])
  end

  defp active_ruleset_payload(_flag, _environment_key, nil), do: nil

  defp active_ruleset_payload(flag, environment_key, version) do
    flag.rulesets
    |> Map.get(environment_key, %{})
    |> Map.get(version)
  end

  defp runtime_ruleset_payload(nil, _flag_environment), do: nil

  defp runtime_ruleset_payload(ruleset, %{status: :killswitched}) do
    %{ruleset | rules: []}
  end

  defp runtime_ruleset_payload(ruleset, _flag_environment), do: ruleset

  defp maybe_record_replay_claim(
         state,
         %{verified_state: :accepted, delivery_id: delivery_id} = command,
         receipt_id
       )
       when not is_nil(delivery_id) do
    update_in(state.webhook_replay_claims, fn claims ->
      provider_claims = Map.get(claims, command.provider, %{})
      Map.put(claims, command.provider, Map.put(provider_claims, delivery_id, receipt_id))
    end)
  end

  defp maybe_record_replay_claim(state, _command, _receipt_id), do: state

  defp matches_webhook_filter?(receipt, command) do
    matches_provider = is_nil(command.provider) or receipt.provider == to_string(command.provider)

    matches_endpoint =
      is_nil(command.endpoint_key) or receipt.endpoint_key == to_string(command.endpoint_key)

    matches_state =
      is_nil(command.verified_state) or receipt.verified_state == command.verified_state

    matches_topic = is_nil(command.topic) or receipt.topic == to_string(command.topic)

    matches_provider and matches_endpoint and matches_state and matches_topic
  end

  defp matches_destination_filter?(destination, command) do
    is_nil(command.environment_key) or
      destination.environment_key == to_string(command.environment_key)
  end

  defp matches_delivery_filter?(delivery, command) do
    matches_dest =
      is_nil(command.destination_id) or delivery.webhook_destination_id == command.destination_id

    matches_event =
      is_nil(command.event_id) or delivery.webhook_outbound_event_id == command.event_id

    matches_state = is_nil(command.state) or delivery.state == command.state

    matches_dest and matches_event and matches_state
  end

  defp enrich_delivery(delivery, state) do
    delivery
    |> Map.put(:event, Map.get(state.webhook_outbound_events, delivery.webhook_outbound_event_id))
    |> Map.put(:destination, Map.get(state.webhook_destinations, delivery.webhook_destination_id))
  end

  defp draft_ruleset_payloads(flag, environment_key) do
    flag.rulesets
    |> Map.get(environment_key, %{})
    |> Map.values()
    |> Enum.filter(&(&1.status == :draft))
    |> Enum.sort_by(& &1.version, :desc)
  end

  defp list_entries_for_flag(flag, environments, nil) do
    Enum.map(flag.environments, fn {environment_key, flag_environment} ->
      %{
        flag: flag,
        environment: environments[environment_key],
        flag_environment: flag_environment
      }
    end)
  end

  defp list_entries_for_flag(flag, environments, environment_key) do
    case Map.fetch(flag.environments, environment_key) do
      {:ok, flag_environment} ->
        [
          %{
            flag: flag,
            environment: environments[environment_key],
            flag_environment: flag_environment
          }
        ]

      :error ->
        []
    end
  end

  defp matches_query?(_entry, nil), do: true
  defp matches_query?(_entry, ""), do: true

  defp matches_query?(entry, query) do
    normalized_query =
      query
      |> to_string()
      |> String.trim()
      |> String.downcase()

    normalized_query == "" or
      String.contains?(String.downcase(entry.flag.key), normalized_query) or
      String.contains?(String.downcase(entry.flag.description || ""), normalized_query)
  end

  defp sort_entries(entries, :inserted_at),
    do:
      Enum.sort(entries, fn left, right ->
        compare_datetime_desc(left.flag.inserted_at, right.flag.inserted_at, left, right)
      end)

  defp sort_entries(entries, :updated_at),
    do:
      Enum.sort(entries, fn left, right ->
        compare_datetime_desc(left.flag.updated_at, right.flag.updated_at, left, right)
      end)

  defp sort_entries(entries, _sort),
    do: Enum.sort_by(entries, fn entry -> {entry.flag.key, entry.environment.key} end)

  defp entry_to_payload(entry) do
    %{
      flag: flag_summary(entry.flag),
      environment: entry.environment,
      flag_environment: flag_environment_summary(entry.flag_environment),
      active_ruleset:
        active_ruleset_payload(
          entry.flag,
          entry.environment.key,
          entry.flag_environment.active_ruleset_version
        ),
      draft_rulesets: draft_ruleset_payloads(entry.flag, entry.environment.key)
    }
  end

  defp ruleset_error(changeset, flag_key, environment_key) do
    details = collect_changeset_details(changeset)

    opts = [
      metadata: %{flag_key: to_string(flag_key), environment_key: to_string(environment_key)},
      details: details,
      cause: changeset
    ]

    if Enum.any?(details, &(&1[:message] == "weights must sum to 100")) do
      RulesetError.invalid_variant_weights(opts)
    else
      RulesetError.invalid(opts)
    end
  end

  defp collect_changeset_details(%Changeset{} = changeset, path \\ nil) do
    own_details =
      Enum.map(changeset.errors, fn {field, {message, _opts}} ->
        detail =
          %{
            field: path_field(path, field),
            message: message
          }

        if path, do: Map.put(detail, :path, path), else: detail
      end)

    nested_details =
      Enum.flat_map(changeset.changes, fn
        {field, %Changeset{} = nested_changeset} ->
          collect_changeset_details(nested_changeset, path_field(path, field))

        {field, changesets} when is_list(changesets) ->
          changesets
          |> Enum.with_index()
          |> Enum.flat_map(fn
            {%Changeset{} = nested_changeset, index} ->
              collect_changeset_details(nested_changeset, path_field(path, "#{field}[#{index}]"))

            {_other, _index} ->
              []
          end)

        _other ->
          []
      end)

    own_details ++ nested_details
  end

  defp path_field(nil, field), do: to_string(field)
  defp path_field(path, field), do: path <> "." <> to_string(field)

  defp serialize_ruleset(ruleset, now) do
    %{
      id: nil,
      version: ruleset.version,
      status: ruleset.status,
      salt: ruleset.salt,
      published_at: ruleset.published_at,
      metadata: ruleset.metadata,
      rules: Enum.map(ruleset.rules, &serialize_rule/1),
      inserted_at: now,
      updated_at: now
    }
  end

  defp serialize_rule(rule) do
    %{
      key: rule.key,
      name: rule.name,
      description: rule.description,
      strategy: rule.strategy,
      value: normalize_embedded_value(rule.value),
      audience_id: rule.audience_id,
      audience_key: rule.audience_key,
      conditions: Enum.map(rule.conditions, &serialize_condition/1),
      variants: Enum.map(rule.variants, &serialize_variant/1),
      rollout: serialize_rollout(rule.rollout)
    }
  end

  defp serialize_condition(condition) do
    %{
      attribute: condition.attribute,
      operator: condition.operator,
      value: normalize_embedded_value(condition.value)
    }
  end

  defp serialize_variant(variant) do
    %{
      key: variant.key,
      value: normalize_embedded_value(variant.value),
      weight: variant.weight
    }
  end

  defp serialize_rollout(nil), do: nil

  defp serialize_rollout(rollout) do
    %{
      bucket_by: rollout.bucket_by,
      percentage: rollout.percentage,
      salt: rollout.salt,
      guardrails: Enum.map(rollout.guardrails || [], &serialize_guardrail/1)
    }
  end

  defp serialize_guardrail(guardrail) do
    %{
      signal_key: guardrail.signal_key,
      threshold_operator: guardrail.threshold_operator,
      threshold_value: guardrail.threshold_value,
      freshness_window_seconds: guardrail.freshness_window_seconds,
      min_sample_size: guardrail.min_sample_size,
      environment_scope: guardrail.environment_scope,
      tenant_scope: guardrail.tenant_scope
    }
  end

  defp normalize_embedded_value(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      normalized_key =
        if is_binary(key) do
          try do
            String.to_existing_atom(key)
          rescue
            ArgumentError -> key
          end
        else
          key
        end

      {normalized_key, normalize_embedded_value(value)}
    end)
  end

  defp normalize_embedded_value(list) when is_list(list) do
    Enum.map(list, &normalize_embedded_value/1)
  end

  defp normalize_embedded_value(value), do: value

  defp decorate_payload(payload, state, flag, environment, flag_environment) do
    environment_cards = environment_cards(state, flag)

    payload
    |> Map.put(:lifecycle, lifecycle(flag, flag_environment))
    |> Map.put(:has_draft_ruleset?, payload.draft_rulesets != [])
    |> Map.put(:recent_owners, recent_owners(state, flag.ownership.owner_ref))
    |> Map.put(:environments, Enum.map(environment_cards, & &1.environment))
    |> Map.put(:environment_cards, environment_cards)
    |> Map.put(:environment_status, flag_environment.status)
    |> Map.put(:environment_key, environment.key)
  end

  defp build_list_entry(state, entry) do
    entry
    |> entry_to_payload()
    |> decorate_payload(state, entry.flag, entry.environment, entry.flag_environment)
  end

  defp environment_cards(state, flag) do
    flag.environments
    |> Enum.sort_by(fn {environment_key, _flag_environment} -> environment_key end)
    |> Enum.map(fn {environment_key, flag_environment} ->
      drafts = draft_ruleset_payloads(flag, environment_key)

      %{
        environment: state.environments[environment_key],
        flag_environment: flag_environment_summary(flag_environment),
        active_ruleset:
          active_ruleset_payload(flag, environment_key, flag_environment.active_ruleset_version),
        draft_rulesets: drafts,
        has_draft_ruleset?: drafts != [],
        lifecycle: lifecycle(flag, flag_environment)
      }
    end)
  end

  defp lifecycle(flag, flag_environment) do
    Lifecycle.classify(
      flag_summary(flag),
      flag_environment_summary(flag_environment),
      lifecycle_opts(flag)
    )
  end

  defp lifecycle_opts(flag) do
    Application.get_env(:rulestead, :admin_lifecycle, [])
    |> Keyword.put(:code_reference_count, flag[:code_reference_count])
    |> Keyword.put(:code_refs_scan, flag[:code_refs_scan])
  end

  defp recent_owners(state, current_owner) do
    owners =
      state.flags
      |> Map.values()
      |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})
      |> Enum.flat_map(fn flag ->
        [flag.ownership.owner_ref | Map.get(flag, :previous_owners, [])]
      end)
      |> Enum.map(&normalize_owner/1)

    [normalize_owner(current_owner) | owners]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.take(5)
  end

  defp preferred_environment(state, flag) do
    flag.environments
    |> Map.keys()
    |> Enum.sort_by(fn environment_key -> {environment_key != "test", environment_key} end)
    |> List.first()
    |> then(fn environment_key ->
      {state.environments[environment_key], flag.environments[environment_key]}
    end)
  end

  defp maybe_filter_owner(entries, nil), do: entries
  defp maybe_filter_owner(entries, ""), do: entries

  defp maybe_filter_owner(entries, owner) do
    normalized = normalize_owner(owner)

    Enum.filter(entries, fn entry ->
      ownership = Map.get(entry.flag, :ownership) || %{}

      normalized in [
        normalize_owner(Map.get(ownership, :owner_ref) || Map.get(ownership, "owner_ref")),
        normalize_owner(Map.get(ownership, :owner_display) || Map.get(ownership, "owner_display"))
      ]
    end)
  end

  defp maybe_filter_flag_type(entries, nil), do: entries

  defp maybe_filter_flag_type(entries, flag_type) do
    Enum.filter(entries, &(&1.flag.flag_type == flag_type))
  end

  defp maybe_filter_tags(entries, []), do: entries

  defp maybe_filter_tags(entries, tags) do
    normalized_tags = tags |> Enum.map(&normalize_tag/1) |> Enum.reject(&is_nil/1)

    Enum.filter(entries, fn entry ->
      entry_tags = entry.flag.tags |> Enum.map(&normalize_tag/1) |> Enum.reject(&is_nil/1)
      Enum.all?(normalized_tags, &(&1 in entry_tags))
    end)
  end

  defp maybe_filter_lifecycle(entries, nil), do: entries

  defp maybe_filter_lifecycle(entries, lifecycle_state),
    do: Enum.filter(entries, &(&1.lifecycle.state == lifecycle_state))

  defp maybe_filter_stale(entries, nil), do: entries

  defp maybe_filter_stale(entries, stale_state) do
    Enum.filter(entries, fn entry ->
      case entry.lifecycle.freshness.state do
        :active -> stale_state == :fresh
        :potentially_stale -> stale_state == :potentially_stale
        :stale -> stale_state == :stale
        :archived -> false
      end
    end)
  end

  defp maybe_filter_readiness(entries, nil), do: entries

  defp maybe_filter_readiness(entries, readiness),
    do: Enum.filter(entries, &(&1.lifecycle.archive_readiness.readiness == readiness))

  defp maybe_filter_evidence_quality(entries, nil), do: entries

  defp maybe_filter_evidence_quality(entries, evidence_quality),
    do:
      Enum.filter(entries, &(&1.lifecycle.archive_readiness.evidence_quality == evidence_quality))

  defp paginate_entries(entries, command) do
    filtered_entries =
      entries
      |> apply_cursor(command.after, :after, command.sort)
      |> apply_cursor(command.before, :before, command.sort)

    page_entries = Enum.take(filtered_entries, command.limit)
    first_entry = List.first(page_entries)
    last_entry = List.last(page_entries)

    %Command.Page{
      entries: page_entries,
      limit: command.limit,
      next_cursor:
        if(length(filtered_entries) > command.limit and last_entry,
          do: encode_cursor(last_entry, command.sort)
        ),
      prev_cursor:
        if((command.after || command.before) && first_entry,
          do: encode_cursor(first_entry, command.sort)
        ),
      has_next_page?: length(filtered_entries) > command.limit,
      has_previous_page?: not is_nil(command.after) or not is_nil(command.before)
    }
  end

  defp apply_cursor(entries, nil, _direction, _sort), do: entries

  defp apply_cursor(entries, cursor, direction, sort) do
    with {:ok, decoded} <- decode_cursor(cursor) do
      Enum.filter(entries, fn entry -> compare_cursor(entry, decoded, sort, direction) end)
    else
      _ -> entries
    end
  end

  defp compare_cursor(entry, decoded, :inserted_at, :after),
    do:
      {entry.flag.inserted_at, entry.flag.key, entry.environment.key} <
        {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, :inserted_at, :before),
    do:
      {entry.flag.inserted_at, entry.flag.key, entry.environment.key} >
        {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, :updated_at, :after),
    do:
      {entry.flag.updated_at, entry.flag.key, entry.environment.key} <
        {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, :updated_at, :before),
    do:
      {entry.flag.updated_at, entry.flag.key, entry.environment.key} >
        {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, _sort, :after),
    do: {entry.flag.key, entry.environment.key} > {decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, _sort, :before),
    do: {entry.flag.key, entry.environment.key} < {decoded.flag_key, decoded.environment_key}

  defp encode_cursor(entry, sort) do
    %{
      sort: sort,
      sort_value:
        case sort do
          :inserted_at -> entry.flag.inserted_at
          :updated_at -> entry.flag.updated_at
          _ -> entry.flag.key
        end,
      flag_key: entry.flag.key,
      environment_key: entry.environment.key
    }
    |> :erlang.term_to_binary()
    |> Base.url_encode64(padding: false)
  end

  defp decode_cursor(cursor) do
    try do
      with {:ok, binary} <- Base.url_decode64(cursor, padding: false) do
        {:ok, :erlang.binary_to_term(binary)}
      end
    rescue
      _ -> :error
    end
  end

  defp matches_environment_query?(_environment, nil), do: true
  defp matches_environment_query?(_environment, ""), do: true

  defp matches_environment_query?(environment, query) do
    normalized_query = query |> to_string() |> String.trim() |> String.downcase()

    normalized_query == "" or
      String.contains?(String.downcase(environment.key), normalized_query) or
      String.contains?(String.downcase(environment.name || ""), normalized_query) or
      String.contains?(String.downcase(environment.description || ""), normalized_query)
  end

  defp matches_audience_query?(_audience, nil), do: true
  defp matches_audience_query?(_audience, ""), do: true

  defp matches_audience_query?(audience, query) do
    normalized_query = query |> to_string() |> String.trim() |> String.downcase()

    normalized_query == "" or
      String.contains?(String.downcase(audience.key || ""), normalized_query) or
      String.contains?(String.downcase(audience.description || ""), normalized_query)
  end

  defp apply_flag_update(flag, command, now) do
    attrs =
      %{}
      |> maybe_put_update_field(:description, command.description)
      |> maybe_put_update_field(:owner, command.owner)
      |> maybe_put_update_field(:ownership, command.ownership)
      |> maybe_put_update_field(:tags, command.tags)
      |> maybe_put_lifecycle_update(command)

    changeset =
      flag
      |> Map.take([
        :key,
        :description,
        :flag_type,
        :value_type,
        :default_value,
        :ownership,
        :lifecycle,
        :tags,
        :archived_at
      ])
      |> then(&Flag.changeset(struct(Flag, &1), attrs))

    case Changeset.apply_action(changeset, :update) do
      {:ok, updated_flag} ->
        {:ok,
         flag
         |> Map.put(:description, updated_flag.description)
         |> Map.put(:ownership, updated_flag.ownership)
         |> Map.put(:lifecycle, updated_flag.lifecycle)
         |> Map.put(:tags, updated_flag.tags)
         |> Map.put(
           :previous_owners,
           [flag.ownership.owner_ref | Map.get(flag, :previous_owners, [])] |> Enum.uniq()
         )
         |> Map.put(:updated_at, now)}

      {:error, changeset_error} ->
        {:error,
         StoreError.invalid_command(
           "store command is invalid",
           metadata: %{flag_key: to_string(command.flag_key), environment_key: "all"},
           details: collect_changeset_details(changeset_error),
           cause: changeset_error
         )}
    end
  end

  defp rebuild_flag_snapshots(state, flag) do
    flag.environments
    |> Map.keys()
    |> Enum.reduce(state, fn environment_key, acc ->
      put_runtime_snapshot(acc, environment_key)
    end)
  end

  defp normalize_owner(owner) when is_binary(owner) do
    case String.trim(owner) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_owner(_owner), do: nil

  defp normalize_tag(tag) when is_binary(tag) do
    case String.trim(tag) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_tag(_tag), do: nil

  defp maybe_put_update_field(attrs, _key, nil), do: attrs
  defp maybe_put_update_field(attrs, key, value), do: Map.put(attrs, key, value)

  defp maybe_put_lifecycle_update(attrs, command) do
    if not is_nil(command.lifecycle) do
      Map.put(attrs, :lifecycle, command.lifecycle)
    else
      attrs
    end
  end

  defp enqueue_webhook_deliveries(state, event_type, payload_fn, opts) do
    env_key = Keyword.get(opts, :environment_key)
    resource_type = Keyword.get(opts, :resource_type)
    resource_key = Keyword.get(opts, :resource_key)

    destinations =
      state.webhook_destinations
      |> Map.values()
      |> Enum.filter(fn d ->
        d.enabled == true and
          event_type in d.subscriptions and
          (is_nil(d.environment_key) or d.environment_key == env_key)
      end)

    if Enum.empty?(destinations) do
      state
    else
      correlation_id = Ecto.UUID.generate()
      payload = payload_fn.()

      event = %{
        id: Ecto.UUID.generate(),
        event_type: event_type,
        payload: payload,
        resource_type: resource_type,
        resource_key: resource_key,
        environment_key: env_key,
        correlation_id: correlation_id,
        inserted_at: state.now
      }

      state = put_in(state, [:webhook_outbound_events, event.id], event)

      Enum.reduce(destinations, state, fn dest, current_state ->
        delivery = %{
          id: Ecto.UUID.generate(),
          webhook_destination_id: dest.id,
          webhook_outbound_event_id: event.id,
          state: :pending,
          attempt_count: 0,
          inserted_at: current_state.now,
          updated_at: current_state.now
        }

        put_in(current_state, [:webhook_deliveries, delivery.id], delivery)
      end)
    end
  end

  defp compare_datetime_desc(left_datetime, right_datetime, left, right) do
    case DateTime.compare(left_datetime, right_datetime) do
      :gt -> true
      :lt -> false
      :eq -> {left.flag.key, left.environment.key} <= {right.flag.key, right.environment.key}
    end
  end

  defp normalize_environment_keys(attrs) do
    attrs
    |> Map.get(:environment_keys, Map.get(attrs, "environment_keys", ["test"]))
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
  end
end
