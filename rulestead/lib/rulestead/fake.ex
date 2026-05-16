defmodule Rulestead.Fake do
  @moduledoc """
  Contract-faithful in-memory store adapter for tests.

  The fake reuses the same command structs, error taxonomy, and ruleset
  validation semantics as the real store contract. Test-only reset, clock, and
  inspection helpers live in `Rulestead.Fake.Control`.
  """

  use GenServer

  alias Ecto.Changeset

  alias Rulestead.{
    Admin.Lifecycle,
    AuditEvent,
    Environment,
    Flag,
    Governance.Approval,
    Governance.ChangeRequest,
    Governance.ExecutionAttempt,
    Governance.ScheduledExecution,
    Ruleset,
    RulesetError,
    Store,
    StoreError,
    Telemetry
  }

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
          audit_events: [map()],
          snapshots: %{required(String.t()) => %{required(pos_integer()) => map()}},
          webhook_receipts: %{required(String.t()) => map()},
          webhook_replay_claims: %{required(String.t()) => %{required(String.t()) => String.t()}},
          webhook_destinations: %{required(String.t()) => map()},
          webhook_outbound_events: %{required(String.t()) => map()},
          webhook_deliveries: %{required(String.t()) => map()},
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
  def record_evaluation(%Command.RecordEvaluation{} = command) do
    call({:record_evaluation, command})
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

  def handle_call({:control, :snapshot}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:control, :restore, restored_state}, _from, _state)
      when is_map(restored_state) do
    {:reply, :ok, restored_state}
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
      owner: command.owner,
      expected_expiration: command.expected_expiration,
      permanent: command.permanent,
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

                 {:error, error} ->
                   {:error, error}
               end
             end) do
          {:ok, result, next_state} -> {:reply, {:ok, result}, next_state}
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
        command_snapshot: command.command,
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
        resource_type: "flag",
        resource_key: command.resource_key
      )

    emit_governance_telemetry(:submitted, audit_command, change_request, audit_event)

    {:reply, {:ok, %{change_request: serialize_change_request(change_request)}}, final_state}
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

      audit_command = governance_audit_command(command, updated_change_request, "cancelled")

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
         :ok <- ensure_governance_transition(change_request, ["approved"]),
         {:ok, execution_result, next_state} <-
           execute_governed_change(state, change_request, command) do
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
    else
      {:error, error} -> {:reply, {:error, error}, state}
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
            metadata: command.metadata,
            correlation_id: change_request.correlation_id,
            idempotency_key: "scheduled_execution:change_request:#{change_request.id}"
          })

        next_state = put_in(state.scheduled_executions[scheduled_execution.id], scheduled_execution)
        {:ok, %{scheduled_execution: serialize_scheduled_execution(scheduled_execution), attempts: []}, next_state}
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:schedule_governed_action, command}, _from, state) do
    correlation_id = governance_correlation_id(command)

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
        command_snapshot: command.command,
        approval_requirement_snapshot: command.approval_requirement,
        metadata: command.metadata,
        correlation_id: correlation_id,
        idempotency_key: "scheduled_execution:#{correlation_id}"
      })

    next_state = put_in(state.scheduled_executions[scheduled_execution.id], scheduled_execution)
    {:reply, {:ok, %{scheduled_execution: serialize_scheduled_execution(scheduled_execution), attempts: []}}, next_state}
  end

  def handle_call({:cancel_scheduled_execution, command}, _from, state) do
    reply =
      with {:ok, scheduled_execution} <- fetch_scheduled_execution_record(state, command.scheduled_execution_id),
           :ok <- ensure_scheduled_transition(scheduled_execution.state, ["scheduled", "running"]) do
        updated =
          scheduled_execution
          |> Map.put(:state, "cancelled")
          |> Map.put(:failure_reason, command.reason)
          |> Map.put(:execution_metadata, scheduled_transition_metadata(scheduled_execution.execution_metadata, "cancelled", command, state.now))
          |> Map.put(:updated_at, state.now)

        next_state = put_in(state.scheduled_executions[updated.id], updated)
        {:ok, %{scheduled_execution: serialize_scheduled_execution(updated), attempts: []}, next_state}
      end

    case reply do
      {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:requeue_scheduled_execution, command}, _from, state) do
    reply =
      with {:ok, scheduled_execution} <- fetch_scheduled_execution_record(state, command.scheduled_execution_id),
           :ok <- ensure_scheduled_transition(scheduled_execution.state, ["quarantined"]) do
        updated =
          scheduled_execution
          |> Map.put(:state, "scheduled")
          |> Map.put(:failure_reason, nil)
          |> Map.put(:execution_metadata, scheduled_transition_metadata(scheduled_execution.execution_metadata, "requeued", command, state.now))
          |> Map.put(:updated_at, state.now)

        next_state = put_in(state.scheduled_executions[updated.id], updated)

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(updated),
           attempts: list_execution_attempts(state, updated.id) |> Enum.map(&serialize_execution_attempt/1)
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
            attempts: list_execution_attempts(state, scheduled_execution.id) |> Enum.map(&serialize_execution_attempt/1)
          }}, state}

      {:ok, %{state: "cancelled"}} ->
        {:reply, {:error, StoreError.invalid_command("scheduled execution is cancelled")}, state}

      {:ok, %{state: "quarantined"}} ->
        {:reply, {:error, StoreError.invalid_command("scheduled execution requires explicit requeue")}, state}

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
      with {:ok, scheduled_execution} <- fetch_scheduled_execution_record(state, command.scheduled_execution_id) do
        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(scheduled_execution),
           attempts: list_execution_attempts(state, scheduled_execution.id) |> Enum.map(&serialize_execution_attempt/1)
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

  defp call(message) do
    case Process.whereis(__MODULE__) do
      nil -> {:error, StoreError.unavailable(details: [%{message: "fake store is not started"}])}
      _pid -> GenServer.call(__MODULE__, message)
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
      audit_events: [],
      flags: %{},
      snapshots: %{},
      webhook_receipts: %{},
      webhook_replay_claims: %{},
      webhook_destinations: %{},
      webhook_outbound_events: %{},
      webhook_deliveries: %{},
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
        {flag_record, next_state} = build_flag_record(state, flag, environment_keys)
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

  defp ensure_environment_keys(state, environment_keys) do
    case Enum.find(environment_keys, &(not Map.has_key?(state.environments, &1))) do
      nil -> :ok
      missing_environment -> {:error, StoreError.environment_not_found(missing_environment)}
    end
  end

  defp build_flag_record(state, flag, environment_keys) do
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

    flag_record = %{
      id: flag_id,
      key: flag.key,
      description: flag.description,
      flag_type: flag.flag_type,
      value_type: flag.value_type,
      default_value: flag.default_value,
      owner: flag.owner,
      expected_expiration: flag.expected_expiration,
      permanent: flag.permanent,
      tags: flag.tags,
      archived_at: flag.archived_at,
      previous_owners: [flag.owner],
      inserted_at: state.now,
      updated_at: state.now,
      environments: environments,
      rulesets: Map.new(environment_keys, &{&1, %{}})
    }

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
      resource_type: "flag",
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
      {:error, StoreError.invalid_command("scheduled execution is not in a valid state for this operation")}
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
        "resource_key" => change_request.resource_key
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

  defp scheduled_transition_metadata(existing, state, command, now) do
    Map.merge(existing || %{}, %{
      "last_transition" => state,
      "last_transition_at" => DateTime.to_iso8601(now),
      "last_actor" => command.actor || %{},
      "last_reason" => command.reason,
      "request_id" => command.metadata[:request_id] || command.metadata["request_id"]
    })
  end

  defp normalize_failure_reason(%Rulestead.Error{message: message}), do: normalize_failure_reason(message)

  defp normalize_failure_reason(reason) when is_binary(reason) do
    case String.trim(reason) do
      "" -> "scheduled execution failed"
      value -> value
    end
  end

  defp normalize_failure_reason(reason), do: inspect(reason)

  defp execute_governed_change(state, %{governed_action: governed_action} = change_request, command)
       when governed_action in ["publish_ruleset", "advance_rollout", "engage_kill_switch", "release_kill_switch"] do
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

        updated_scheduled_execution =
          execution_state.scheduled_executions[scheduled_execution.id]
          |> Map.put(:state, "completed")
          |> Map.put(:attempt_count, attempt_number)
          |> Map.put(:executed_at, execution_state.now)
          |> Map.put(:failure_reason, nil)
          |> Map.put(
            :execution_metadata,
            scheduled_transition_metadata(
              scheduled_execution.execution_metadata,
              "completed",
              command,
              execution_state.now
            )
          )
          |> Map.put(:updated_at, execution_state.now)

        next_state =
          execution_state
          |> put_in([:execution_attempts, scheduled_execution.id], replace_attempt(execution_state, updated_attempt))
          |> put_in([:scheduled_executions, scheduled_execution.id], updated_scheduled_execution)

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution(updated_scheduled_execution),
           execution_result: execution_result,
           attempts: list_execution_attempts(next_state, scheduled_execution.id) |> Enum.map(&serialize_execution_attempt/1)
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
          |> put_in([:execution_attempts, scheduled_execution.id], replace_attempt(execution_state, updated_attempt))
          |> put_in([:scheduled_executions, scheduled_execution.id], updated_scheduled_execution)

        {:error, StoreError.invalid_command(failure_reason), next_state}
    end
  end

  defp perform_scheduled_execution(state, %{change_request_id: change_request_id}, command)
       when is_binary(change_request_id) do
    with {:ok, change_request} <- fetch_change_request_record(state, change_request_id),
         {:ok, execution_result, next_state} <- execute_governed_change(state, change_request, command) do
      updated_change_request =
        change_request
        |> Map.put(:status, "executed")
        |> Map.put(:resolved_at, next_state.now)
        |> Map.put(:executed_at, next_state.now)
        |> Map.put(:updated_at, next_state.now)

      audit_command = governance_audit_command(command, updated_change_request, "merged")
      {audit_event, post_audit_state} = append_audit_event(next_state, audit_command, "change_request.merged", :ok)

      final_state =
        post_audit_state
        |> put_in([:change_requests, change_request.id], updated_change_request)
        |> update_in([:audit_events], fn events -> [audit_event | events] end)

      {:ok, execution_result, final_state}
    end
  end

  defp perform_scheduled_execution(state, %{governed_action: governed_action} = scheduled_execution, command)
       when governed_action in ["publish_ruleset", "advance_rollout", "engage_kill_switch", "release_kill_switch"] do
    execute_direct_scheduled_action(state, governed_action, scheduled_execution, command)
  end

  defp perform_scheduled_execution(state, _scheduled_execution, _command) do
    {:error, StoreError.invalid_command("governed action is not implemented"), state}
  end

  defp execute_bounded_governed_change(state, "publish_ruleset", change_request, command) do
    version = change_request.command_snapshot["version"]

    with {:ok, environment, flag, flag_environment} <-
           fetch_schedulable_flag_context(state, change_request.resource_key, change_request.environment_key),
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
           fetch_schedulable_flag_context(state, change_request.resource_key, change_request.environment_key),
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
           fetch_schedulable_flag_context(state, change_request.resource_key, change_request.environment_key),
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

  defp execute_bounded_governed_change(state, "advance_rollout", change_request, _command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(state, change_request.resource_key, change_request.environment_key),
         :ok <- ensure_rollout_stage_available(flag_environment, change_request.command_snapshot) do
      {:error, "rollout_stage_conflict", state}
    end
  end

  defp execute_direct_scheduled_action(state, "publish_ruleset", scheduled_execution, command) do
    version = scheduled_execution.command_snapshot["version"]

    with {:ok, environment, flag, flag_environment} <-
           fetch_schedulable_flag_context(state, scheduled_execution.resource_key, scheduled_execution.environment_key),
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

      updated_state = %{post_audit_state | audit_events: [audit_event | post_audit_state.audit_events]}
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
           fetch_schedulable_flag_context(state, scheduled_execution.resource_key, scheduled_execution.environment_key),
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
           fetch_schedulable_flag_context(state, scheduled_execution.resource_key, scheduled_execution.environment_key),
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

  defp execute_direct_scheduled_action(state, "advance_rollout", scheduled_execution, _command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(state, scheduled_execution.resource_key, scheduled_execution.environment_key),
         :ok <- ensure_rollout_stage_available(flag_environment, scheduled_execution.command_snapshot) do
      {:error, "rollout_stage_conflict", state}
    else
      {:error, error} -> {:error, error, state}
    end
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
    if flag_environment.status == :killswitched or not is_nil(flag_environment.kill_switch_variant_key) do
      {:error, "kill_switch_already_engaged"}
    else
      :ok
    end
  end

  defp ensure_kill_switch_transition(flag_environment, :release) do
    if flag_environment.status == :killswitched or not is_nil(flag_environment.kill_switch_variant_key) do
      :ok
    else
      {:error, "kill_switch_already_released"}
    end
  end

  defp ensure_rollout_stage_available(_flag_environment, _command_snapshot),
    do: {:error, "rollout_stage_conflict"}

  defp execute_kill_switch_transition(state, flag_key, environment_key, flag_environment, direction, command, metadata) do
    updated_flag_environment =
      case direction do
        :engage ->
          flag_environment
          |> Map.put(:status, :killswitched)
          |> Map.put(:kill_switch_variant_key, "default")
          |> Map.put(:updated_at, state.now)

        :release ->
          flag_environment
          |> Map.put(:status, if(flag_environment.status == :killswitched, do: :active, else: flag_environment.status || :active))
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
      is_nil(command.environment_key) or scheduled_execution.environment_key == command.environment_key

    matches_state =
      is_nil(command.state) or scheduled_execution.state == normalize_change_request_filter(command.state)

    matches_action =
      is_nil(command.action) or scheduled_execution.governed_action == normalize_change_request_filter(command.action)

    matches_resource_type =
      is_nil(command.resource_type) or scheduled_execution.resource_type == command.resource_type

    matches_resource_key =
      is_nil(command.resource_key) or scheduled_execution.resource_key == command.resource_key

    matches_actor =
      is_nil(command.scheduled_by_id) or scheduled_execution.scheduled_by_id == command.scheduled_by_id

    matches_change_request =
      is_nil(command.change_request_id) or scheduled_execution.change_request_id == command.change_request_id

    matches_after =
      is_nil(command.after) or DateTime.compare(scheduled_execution.scheduled_for, command.after) != :lt

    matches_before =
      is_nil(command.before) or DateTime.compare(scheduled_execution.scheduled_for, command.before) != :gt

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

    update_in(state.snapshots, fn snapshots ->
      Map.update(snapshots, environment_key, %{version => snapshot}, fn environment_snapshots ->
        Map.put(environment_snapshots, version, snapshot)
      end)
    end)
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
      flags: flags
    }
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
      recent_owners: recent_owners(state, flag.owner)
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
      :owner,
      :expected_expiration,
      :permanent,
      :tags,
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

    matches_state = is_nil(command.verified_state) or receipt.verified_state == command.verified_state
    matches_topic = is_nil(command.topic) or receipt.topic == to_string(command.topic)

    matches_provider and matches_endpoint and matches_state and matches_topic
  end

  defp matches_destination_filter?(destination, command) do
    is_nil(command.environment_key) or destination.environment_key == to_string(command.environment_key)
  end

  defp matches_delivery_filter?(delivery, command) do
    matches_dest = is_nil(command.destination_id) or delivery.webhook_destination_id == command.destination_id
    matches_event = is_nil(command.event_id) or delivery.webhook_outbound_event_id == command.event_id
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
      value: rule.value,
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
      value: condition.value
    }
  end

  defp serialize_variant(variant) do
    %{
      key: variant.key,
      value: variant.value,
      weight: variant.weight
    }
  end

  defp serialize_rollout(nil), do: nil

  defp serialize_rollout(rollout) do
    %{
      bucket_by: rollout.bucket_by,
      percentage: rollout.percentage,
      salt: rollout.salt
    }
  end

  defp decorate_payload(payload, state, flag, environment, flag_environment) do
    environment_cards = environment_cards(state, flag)

    payload
    |> Map.put(:lifecycle, lifecycle(flag, flag_environment))
    |> Map.put(:has_draft_ruleset?, payload.draft_rulesets != [])
    |> Map.put(:recent_owners, recent_owners(state, flag.owner))
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
      lifecycle_opts()
    )
  end

  defp lifecycle_opts do
    Application.get_env(:rulestead, :admin_lifecycle, [])
  end

  defp recent_owners(state, current_owner) do
    owners =
      state.flags
      |> Map.values()
      |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})
      |> Enum.flat_map(fn flag -> [flag.owner | Map.get(flag, :previous_owners, [])] end)
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
    Enum.filter(entries, fn entry -> normalize_owner(entry.flag.owner) == normalized end)
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
      case entry.lifecycle.state do
        :active -> stale_state == :fresh
        :potentially_stale -> stale_state == :potentially_stale
        :stale -> stale_state == :stale
        :archived -> false
      end
    end)
  end

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
        :owner,
        :expected_expiration,
        :permanent,
        :tags,
        :archived_at
      ])
      |> then(&Flag.changeset(struct(Flag, &1), attrs))

    case Changeset.apply_action(changeset, :update) do
      {:ok, updated_flag} ->
        {:ok,
         flag
         |> Map.put(:description, updated_flag.description)
         |> Map.put(:owner, updated_flag.owner)
         |> Map.put(:expected_expiration, updated_flag.expected_expiration)
         |> Map.put(:permanent, updated_flag.permanent)
         |> Map.put(:tags, updated_flag.tags)
         |> Map.put(
           :previous_owners,
           [flag.owner | Map.get(flag, :previous_owners, [])] |> Enum.uniq()
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
    attrs =
      if not is_nil(command.permanent) do
        Map.put(attrs, :permanent, command.permanent)
      else
        attrs
      end

    if Map.has_key?(attrs, :permanent) or not is_nil(command.expected_expiration) do
      Map.put(attrs, :expected_expiration, command.expected_expiration)
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
