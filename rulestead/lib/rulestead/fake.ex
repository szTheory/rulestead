defmodule Rulestead.Fake do
  @moduledoc """
  Contract-faithful in-memory store adapter for tests.

  The fake reuses the same command structs, error taxonomy, and ruleset
  validation semantics as the real store contract. Test-only reset, clock, and
  inspection helpers live in `Rulestead.Fake.Control`.
  """

  use GenServer

  alias Ecto.Changeset
  alias Rulestead.{Environment, Flag, Ruleset, RulesetError, Store, StoreError, Telemetry}
  alias Rulestead.Store.Command

  @behaviour Store

  @default_now ~U[2026-01-01 00:00:00Z]
  @snapshot_schema_version 1

  @type state :: %{
          now: DateTime.t(),
          environments: %{required(String.t()) => map()},
          flags: %{required(String.t()) => map()},
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
        {:ok, build_flag_payload(flag, environment, flag_environment, command.include_ruleset?)}
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

  def handle_call({:save_draft_ruleset, command}, _from, state) do
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

  def handle_call({:publish_ruleset, command}, _from, state) do
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
                 build_flag_payload(refreshed_flag, environment, refreshed_flag_environment, true)

               {:ok, payload, next_state}

             {:error, error} ->
               {:error, error}
           end
         end) do
      {:ok, result, next_state} -> {:reply, {:ok, result}, next_state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:archive_flag, command}, _from, state) do
    flag_key = to_string(command.flag_key)

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

        next_state = put_in(state.flags[flag_key], archived_flag)
        payload = build_archive_payload(archived_flag)
        {:reply, {:ok, payload}, next_state}
    end
  end

  def handle_call({:list_flags, command}, _from, state) do
    reply =
      with_list_environment(state, command.environment_key, fn environment_filter ->
        flags =
          state.flags
          |> Map.values()
          |> Enum.flat_map(&list_entries_for_flag(&1, state.environments, environment_filter))
          |> Enum.reject(fn entry ->
            archived?(entry.flag) and not command.include_archived?
          end)
          |> Enum.filter(&matches_query?(&1, command.query))
          |> sort_entries(command.sort)
          |> Enum.drop(command.offset)
          |> Enum.take(command.limit)

        {:ok, Enum.map(flags, &entry_to_payload/1)}
      end)

    {:reply, reply, state}
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
        {:ok, build_archive_payload(flag_record), next_state}
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
      tags: flag.tags,
      archived_at: flag.archived_at,
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

  defp build_archive_payload(flag) do
    %{
      flag: flag_summary(flag),
      archived?: archived?(flag),
      environment_keys: flag.environments |> Map.keys() |> Enum.sort()
    }
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
    do: Enum.sort_by(entries, & &1.flag.inserted_at, {:desc, DateTime})

  defp sort_entries(entries, :updated_at),
    do: Enum.sort_by(entries, & &1.flag.updated_at, {:desc, DateTime})

  defp sort_entries(entries, _sort), do: Enum.sort_by(entries, & &1.flag.key)

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
        )
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

  defp normalize_environment_keys(attrs) do
    attrs
    |> Map.get(:environment_keys, Map.get(attrs, "environment_keys", ["test"]))
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
  end
end
