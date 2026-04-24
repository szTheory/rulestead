defmodule Rulestead.Fake do
  @moduledoc """
  Contract-faithful in-memory store adapter for tests.

  The fake reuses the same command structs, error taxonomy, and ruleset
  validation semantics as the real store contract. Test-only reset, clock, and
  inspection helpers live in `Rulestead.Fake.Control`.
  """

  use GenServer

  alias Ecto.Changeset
  alias Rulestead.{Admin.Lifecycle, AuditEvent, Environment, Flag, Ruleset, RulesetError, Store, StoreError, Telemetry}
  alias Rulestead.Store.Command

  @behaviour Store

  @default_now ~U[2026-01-01 00:00:00Z]
  @snapshot_schema_version 1

  @type state :: %{
          now: DateTime.t(),
          environments: %{required(String.t()) => map()},
          audiences: %{required(String.t()) => map()},
          flags: %{required(String.t()) => map()},
          audit_events: [map()],
          snapshots: %{required(String.t()) => %{required(pos_integer()) => map()}},
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

  def handle_call({:control, :restore, restored_state}, _from, _state) when is_map(restored_state) do
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
      case state.snapshots |> Map.get(to_string(environment_key), %{}) |> Enum.max_by(&elem(&1, 0), fn -> nil end) do
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
        {:ok, build_flag_detail_payload(state, flag, environment, flag_environment, command.include_ruleset?)}
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
                   Map.get(command.ruleset, :metadata) || Map.get(command.ruleset, "metadata") || %{},
                 rules: Map.get(command.ruleset, :rules) || Map.get(command.ruleset, "rules") || []
               }

               changeset = Ruleset.changeset(%Ruleset{}, attrs)

               case Changeset.apply_action(changeset, :insert) do
                 {:ok, ruleset} ->
                   ruleset_record = serialize_ruleset(ruleset, state.now)
                   next_state = put_ruleset(state, command.flag_key, environment.key, ruleset_record)
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
                     build_flag_detail_payload(next_state, refreshed_flag, environment, refreshed_flag_environment, true)

                   {:ok, payload, next_state}

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

            _ -> timestamp
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

               {:ok, payload, %{next_state | audit_events: [audit_event | next_state.audit_events]}}
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
                 |> Map.put(:status, if(flag_environment.status == :killswitched, do: :active, else: flag_environment.status || :active))
                 |> Map.put(:kill_switch_variant_key, nil)
                 |> Map.put(:updated_at, state.now)

               next_state =
                 put_in(
                   state.flags[to_string(command.flag_key)].environments[environment.key],
                   updated_flag_environment
                 )

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

               {:ok, payload, %{next_state | audit_events: [audit_event | next_state.audit_events]}}
             end) do
          {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
          {:error, error} -> {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:list_audit_events, command}, _from, state) do
    entries =
      state.audit_events
      |> Enum.filter(fn entry ->
        matches_audit_filter?(entry, command.flag_key, command.environment_key)
      end)
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
          {:reply, {:error, StoreError.invalid_command("audit event cannot be rolled back")}, state}
        else
          case do_rollback(state, inverse_command, command, audit_event) do
            {:ok, payload, next_state} -> {:reply, {:ok, payload}, next_state}
            {:error, error} -> {:reply, {:error, error}, state}
          end
        end
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
      audit_events: [],
      flags: %{},
      snapshots: %{},
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
        |> Map.put(:status, if(flag_environment.status == :killswitched, do: :active, else: flag_environment.status || :active))
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
    metadata =
      AuditEvent.metadata(%{
        before: Keyword.get(opts, :before, %{}),
        after: Keyword.get(opts, :after, %{}),
        diff: diff_map(Keyword.get(opts, :before, %{}), Keyword.get(opts, :after, %{})),
        links:
          Keyword.get(opts, :links, %{})
          |> Map.new()
          |> maybe_put("rollback_of_event_id", Keyword.get(opts, :rollback_of_event_id)),
        context: Map.get(command, :metadata, %{}),
        request_id: get_in(command.metadata, [:request_id]) || get_in(command.metadata, ["request_id"]),
        source: get_in(command.metadata, [:source]) || get_in(command.metadata, ["source"]),
        rollback_of_event_id: Keyword.get(opts, :rollback_of_event_id)
      })

    %AuditEvent{
      id: Ecto.UUID.generate(),
      event_type: event_type,
      resource_type: "flag",
      resource_key: to_string(Keyword.get(opts, :resource_key, Map.get(command, :flag_key))),
      environment_key: to_string(Keyword.get(opts, :environment_key, Map.get(command, :environment_key))),
      actor_id: get_in(command.actor || %{}, [:id]),
      actor_type: to_string(get_in(command.actor || %{}, [:type]) || "operator"),
      actor_display: get_in(command.actor || %{}, [:display]),
      reason: Map.get(command, :reason),
      result: result,
      metadata: metadata,
      correlation_id: get_in(command.metadata, [:request_id]) || get_in(command.metadata, ["request_id"]),
      occurred_at: state.now,
      inserted_at: state.now
    }
  end

  defp audit_only_result(state, command, event_type) do
    case audit_result(command) do
      :denied ->
        {audit_event, next_state} = append_audit_event(state, command, event_type, :denied)
        {:ok, {:ok, %{audit_event: audit_event}}, %{next_state | audit_events: [audit_event | next_state.audit_events]}}

      _other -> :continue
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
      {to_string(key), %{"from" => Map.get(before_state, to_string(key)) || Map.get(before_state, key), "to" => value}}
    end)
  end

  defp matches_audit_filter?(_entry, nil, nil), do: true
  defp matches_audit_filter?(entry, flag_key, nil), do: entry.resource_key == to_string(flag_key)
  defp matches_audit_filter?(entry, nil, environment_key), do: entry.environment_key == to_string(environment_key)

  defp matches_audit_filter?(entry, flag_key, environment_key) do
    entry.resource_key == to_string(flag_key) and entry.environment_key == to_string(environment_key)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

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
          %{status: :active, active_ruleset_version: version} when not is_nil(version),
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
            active_ruleset_payload(flag, environment.key, flag_environment.active_ruleset_version)
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
    do: Enum.sort(entries, fn left, right -> compare_datetime_desc(left.flag.inserted_at, right.flag.inserted_at, left, right) end)

  defp sort_entries(entries, :updated_at),
    do: Enum.sort(entries, fn left, right -> compare_datetime_desc(left.flag.updated_at, right.flag.updated_at, left, right) end)

  defp sort_entries(entries, _sort), do: Enum.sort_by(entries, fn entry -> {entry.flag.key, entry.environment.key} end)

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
        active_ruleset: active_ruleset_payload(flag, environment_key, flag_environment.active_ruleset_version),
        draft_rulesets: drafts,
        has_draft_ruleset?: drafts != [],
        lifecycle: lifecycle(flag, flag_environment)
      }
    end)
  end

  defp lifecycle(flag, flag_environment) do
    Lifecycle.classify(flag_summary(flag), flag_environment_summary(flag_environment), lifecycle_opts())
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
    |> then(fn environment_key -> {state.environments[environment_key], flag.environments[environment_key]} end)
  end

  defp maybe_filter_owner(entries, nil), do: entries
  defp maybe_filter_owner(entries, ""), do: entries

  defp maybe_filter_owner(entries, owner) do
    normalized = normalize_owner(owner)
    Enum.filter(entries, fn entry -> normalize_owner(entry.flag.owner) == normalized end)
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
  defp maybe_filter_lifecycle(entries, lifecycle_state), do: Enum.filter(entries, &(&1.lifecycle.state == lifecycle_state))

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
      next_cursor: if(length(filtered_entries) > command.limit and last_entry, do: encode_cursor(last_entry, command.sort)),
      prev_cursor: if((command.after || command.before) && first_entry, do: encode_cursor(first_entry, command.sort)),
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
    do: {entry.flag.inserted_at, entry.flag.key, entry.environment.key} < {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, :inserted_at, :before),
    do: {entry.flag.inserted_at, entry.flag.key, entry.environment.key} > {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, :updated_at, :after),
    do: {entry.flag.updated_at, entry.flag.key, entry.environment.key} < {decoded.sort_value, decoded.flag_key, decoded.environment_key}

  defp compare_cursor(entry, decoded, :updated_at, :before),
    do: {entry.flag.updated_at, entry.flag.key, entry.environment.key} > {decoded.sort_value, decoded.flag_key, decoded.environment_key}

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
         |> Map.put(:previous_owners, [flag.owner | Map.get(flag, :previous_owners, [])] |> Enum.uniq())
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
