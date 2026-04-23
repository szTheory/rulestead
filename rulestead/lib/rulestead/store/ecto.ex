defmodule Rulestead.Store.Ecto do
  @moduledoc false

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.ConstraintError
  alias Ecto.Multi

  alias Rulestead.{
    AuditEvent,
    Environment,
    Flag,
    FlagEnvironment,
    Repo,
    RuntimeSnapshot,
    Ruleset,
    RulesetError,
    Store,
    StoreError,
    Telemetry
  }

  alias Rulestead.Store.Command

  @snapshot_schema_version 1

  @behaviour Store

  @impl Store
  def fetch_flag(%Command.FetchFlag{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key) do
      {:ok, build_flag_payload(flag, environment, flag_environment, command.include_ruleset?)}
    end
  end

  @impl Store
  def fetch_snapshot(%Command.FetchSnapshot{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key) do
      command
      |> runtime_snapshot_query(environment.key)
      |> Repo.one()
      |> case do
        nil ->
          {:error,
           StoreError.snapshot_not_found(
             environment.key,
             metadata: snapshot_lookup_metadata(environment.key, command.version)
           )}

        snapshot ->
          {:ok, serialize_runtime_snapshot(snapshot)}
      end
    end
  end

  @impl Store
  def save_draft_ruleset(%Command.SaveDraftRuleset{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key),
         :ok <- ensure_not_archived(command.flag_key, flag) do
      attrs = %{
        flag_environment_id: flag_environment.id,
        version: next_ruleset_version(flag_environment.id),
        status: :draft,
        salt: Map.get(command.ruleset, :salt) || Map.get(command.ruleset, "salt"),
        published_at: nil,
        metadata:
          Map.get(command.ruleset, :metadata) || Map.get(command.ruleset, "metadata") || %{},
        rules: Map.get(command.ruleset, :rules) || Map.get(command.ruleset, "rules") || []
      }

      %Ruleset{}
      |> Ruleset.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, ruleset} ->
          {:ok, %{version: ruleset.version, ruleset: serialize_ruleset(ruleset)}}

        {:error, %Changeset{} = changeset} ->
          {:error, ruleset_error(changeset, command.flag_key, command.environment_key)}
      end
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def publish_ruleset(%Command.PublishRuleset{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key),
         :ok <- ensure_not_archived(command.flag_key, flag),
         {:ok, ruleset} <-
           resolve_publishable_ruleset(flag_environment, environment.key, command.version) do
      published_at = now()

      Multi.new()
      |> Multi.update(
        :ruleset,
        Ruleset.changeset(ruleset, %{status: :published, published_at: published_at})
      )
      |> Multi.update(
        :flag_environment,
        FlagEnvironment.changeset(flag_environment, %{
          active_ruleset_id: ruleset.id,
          status: :active,
          last_published_at: published_at
        })
      )
      |> Multi.update(:flag, Changeset.change(flag, updated_at: published_at))
      |> Multi.run(:runtime_snapshot, fn repo, _changes ->
        insert_runtime_snapshot(repo, environment, published_at)
      end)
      |> audit_multi(:audit_event, command, ruleset, environment)
      |> Repo.transact()
      |> case do
        {:ok, _changes} ->
          fetch_flag(Command.FetchFlag.new(command.flag_key, command.environment_key))

        {:error, :ruleset, %Changeset{} = changeset, _changes} ->
          {:error, ruleset_error(changeset, command.flag_key, command.environment_key)}

        {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
          {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def archive_flag(%Command.ArchiveFlag{} = command) do
    case flag_by_key_query(command.flag_key) |> Repo.one() do
      nil ->
        {:error, StoreError.flag_not_found(command.flag_key, :all)}

      flag ->
        archived_at = flag.archived_at || now()

        Multi.new()
        |> Multi.update(:flag, Flag.changeset(flag, %{archived_at: archived_at}))
        |> Multi.update_all(
          :flag_environments,
          from(fe in FlagEnvironment, where: fe.flag_id == ^flag.id),
          set: [status: :archived, updated_at: archived_at]
        )
        |> audit_multi(:audit_event, command, nil, nil)
        |> Repo.transact()
        |> case do
          {:ok, _changes} ->
            archived_flag = flag_by_key_query(command.flag_key) |> Repo.one()
            {:ok, build_archive_payload(archived_flag)}

          {:error, :flag, %Changeset{} = changeset, _changes} ->
            {:error, store_changeset_error(changeset, command.flag_key, :all)}

          {:error, _operation, reason, _changes} ->
            {:error, StoreError.unavailable(cause: reason)}
        end
    end
  end

  @impl Store
  def list_flags(%Command.ListFlags{} = command) do
    with {:ok, environment_filter} <- list_environment_filter(command.environment_key) do
      query =
        from(flag in Flag,
          join: fe in FlagEnvironment,
          on: fe.flag_id == flag.id,
          join: env in Environment,
          on: env.id == fe.environment_id,
          preload: [flag_environments: {fe, [:environment, :active_ruleset]}]
        )
        |> maybe_filter_environment(environment_filter)
        |> maybe_filter_archived(command.include_archived?)
        |> maybe_filter_query(command.query)
        |> maybe_sort(command.sort)
        |> limit(^command.limit)
        |> offset(^command.offset)

      flags =
        query
        |> Repo.all()
        |> Enum.flat_map(fn flag ->
          Enum.map(flag.flag_environments, fn flag_environment ->
            entry_to_payload(%{
              flag: flag,
              environment: flag_environment.environment,
              flag_environment: flag_environment
            })
          end)
        end)

      {:ok, flags}
    end
  end

  defp fetch_environment(environment_key) do
    case Repo.get_by(Environment, key: to_string(environment_key)) do
      nil -> {:error, StoreError.environment_not_found(environment_key)}
      environment -> {:ok, environment}
    end
  end

  defp fetch_flag_environment(flag_key, environment_key) do
    case flag_with_environment_query(flag_key, environment_key) |> Repo.one() do
      nil -> {:error, StoreError.flag_not_found(flag_key, environment_key)}
      %{flag_environments: [flag_environment]} = flag -> {:ok, flag, flag_environment}
    end
  end

  defp ensure_not_archived(flag_key, flag) do
    if flag.archived_at do
      {:error, StoreError.archived(flag_key)}
    else
      :ok
    end
  end

  defp next_ruleset_version(flag_environment_id) do
    from(r in Ruleset,
      where: r.flag_environment_id == ^flag_environment_id,
      select: max(r.version)
    )
    |> Repo.one()
    |> Kernel.||(0)
    |> Kernel.+(1)
  end

  defp resolve_publishable_ruleset(flag_environment, environment_key, version) do
    rulesets_query =
      from(r in Ruleset,
        where: r.flag_environment_id == ^flag_environment.id
      )

    rulesets = Repo.all(rulesets_query)

    with {:ok, publish_version} <- normalize_publish_version(version, rulesets) do
      case Enum.find(rulesets, &(&1.version == publish_version)) do
        %Ruleset{status: :draft} = ruleset ->
          {:ok, ruleset}

        %Ruleset{} ->
          {:error,
           StoreError.invalid_command(
             "requested ruleset version is not publishable",
             metadata: %{
               requested_version: publish_version,
               active_version: active_version(flag_environment)
             }
           )}

        nil ->
          {:error,
           RulesetError.not_found(
             metadata: %{requested_version: publish_version, environment_key: environment_key}
           )}
      end
    end
  end

  defp normalize_publish_version(nil, rulesets) do
    case rulesets
         |> Enum.filter(&(&1.status == :draft))
         |> Enum.map(& &1.version)
         |> Enum.max(fn -> nil end) do
      nil -> {:error, RulesetError.not_found()}
      version -> {:ok, version}
    end
  end

  defp normalize_publish_version(version, _rulesets) when is_integer(version) and version > 0,
    do: {:ok, version}

  defp normalize_publish_version(version, _rulesets) when is_binary(version) do
    case Integer.parse(version) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, StoreError.invalid_command("publish version must be a positive integer")}
    end
  end

  defp normalize_publish_version(_version, _rulesets),
    do: {:error, StoreError.invalid_command("publish version must be a positive integer")}

  defp active_version(flag_environment),
    do: flag_environment.active_ruleset && flag_environment.active_ruleset.version

  defp insert_runtime_snapshot(repo, environment, published_at) do
    snapshot_payload = build_environment_snapshot_payload(repo, environment)
    payload = :erlang.term_to_binary(snapshot_payload)

    attrs = %{
      environment_key: environment.key,
      version: next_snapshot_version(repo, environment.key),
      payload: payload,
      payload_checksum: payload_checksum(payload),
      metadata: %{
        schema_version: @snapshot_schema_version,
        flag_count: map_size(snapshot_payload.flags)
      },
      published_at: published_at
    }

    %RuntimeSnapshot{}
    |> RuntimeSnapshot.changeset(attrs)
    |> repo.insert()
    |> case do
      {:ok, snapshot} ->
        Telemetry.execute(
          [:rulestead, :runtime, :snapshot, :published],
          %{count: 1},
          Telemetry.metadata(%{
            environment: environment.key,
            snapshot_version: snapshot.version,
            reason: :published
          })
        )

        {:ok, snapshot}

      {:error, %Changeset{} = changeset} -> {:error, changeset}
    end
  end

  defp build_environment_snapshot_payload(repo, environment) do
    flags =
      environment_snapshot_flags_query(environment.key)
      |> repo.all()
      |> Map.new(fn flag ->
        [flag_environment] = flag.flag_environments

        {flag.key, build_flag_payload(flag, environment, flag_environment, true)}
      end)

    %{
      schema_version: @snapshot_schema_version,
      environment_key: environment.key,
      generated_at: now(),
      flags: flags
    }
  end

  defp next_snapshot_version(repo, environment_key) do
    from(snapshot in RuntimeSnapshot,
      where: snapshot.environment_key == ^environment_key,
      select: max(snapshot.version)
    )
    |> repo.one()
    |> Kernel.||(0)
    |> Kernel.+(1)
  end

  defp payload_checksum(payload) do
    :sha256
    |> :crypto.hash(payload)
    |> Base.encode16(case: :lower)
  end

  defp build_flag_payload(flag, environment, flag_environment, include_ruleset?) do
    %{
      flag: flag_summary(flag),
      environment: environment_summary(environment),
      flag_environment: flag_environment_summary(flag_environment),
      active_ruleset:
        if(include_ruleset?, do: active_ruleset_payload(flag_environment), else: nil),
      draft_rulesets:
        if(include_ruleset?,
          do: draft_ruleset_payloads(flag_environment),
          else: []
        )
    }
  end

  defp build_archive_payload(flag) do
    environment_keys =
      flag.flag_environments
      |> Enum.map(& &1.environment.key)
      |> Enum.sort()

    %{
      flag: flag_summary(flag),
      archived?: not is_nil(flag.archived_at),
      environment_keys: environment_keys
    }
  end

  defp active_ruleset_payload(%FlagEnvironment{active_ruleset: nil}), do: nil

  defp active_ruleset_payload(%FlagEnvironment{active_ruleset: ruleset}),
    do: serialize_ruleset(ruleset)

  defp draft_ruleset_payloads(%FlagEnvironment{id: id}) do
    from(r in Ruleset,
      where: r.flag_environment_id == ^id and r.status == :draft,
      order_by: [desc: r.version]
    )
    |> Repo.all()
    |> Enum.map(&serialize_ruleset/1)
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

  defp environment_summary(environment) do
    Map.take(environment, [:id, :key, :name, :description, :inserted_at, :updated_at])
  end

  defp flag_environment_summary(flag_environment) do
    %{
      id: flag_environment.id,
      environment_key: flag_environment.environment.key,
      status: flag_environment.status,
      kill_switch_variant_key: flag_environment.kill_switch_variant_key,
      active_ruleset_version:
        if(flag_environment.active_ruleset, do: flag_environment.active_ruleset.version),
      last_published_at: flag_environment.last_published_at,
      inserted_at: flag_environment.inserted_at,
      updated_at: flag_environment.updated_at
    }
  end

  defp entry_to_payload(entry) do
    %{
      flag: flag_summary(entry.flag),
      environment: environment_summary(entry.environment),
      flag_environment: flag_environment_summary(entry.flag_environment),
      active_ruleset: active_ruleset_payload(entry.flag_environment)
    }
  end

  defp serialize_ruleset(ruleset) do
    %{
      id: ruleset.id,
      flag_environment_id: ruleset.flag_environment_id,
      version: ruleset.version,
      status: ruleset.status,
      salt: ruleset.salt,
      published_at: ruleset.published_at,
      metadata: ruleset.metadata,
      rules: Enum.map(ruleset.rules, &serialize_rule/1),
      inserted_at: ruleset.inserted_at,
      updated_at: ruleset.updated_at
    }
  end

  defp serialize_rule(rule) when is_map(rule) do
    %{
      key: rule.key,
      name: rule.name,
      description: rule.description,
      strategy: rule.strategy,
      value: rule.value,
      audience_id: rule.audience_id,
      audience_key: rule.audience_key,
      conditions: Enum.map(rule.conditions || [], &serialize_condition/1),
      variants: Enum.map(rule.variants || [], &serialize_variant/1),
      rollout: serialize_rollout(rule.rollout)
    }
  end

  defp serialize_condition(condition) when is_map(condition) do
    %{
      attribute: condition.attribute,
      operator: condition.operator,
      value: condition.value
    }
  end

  defp serialize_variant(variant) when is_map(variant) do
    %{
      key: variant.key,
      value: variant.value,
      weight: variant.weight
    }
  end

  defp serialize_rollout(nil), do: nil

  defp serialize_rollout(rollout) when is_map(rollout) do
    %{
      bucket_by: rollout.bucket_by,
      percentage: rollout.percentage,
      salt: rollout.salt
    }
  end

  defp serialize_runtime_snapshot(snapshot) do
    %{
      id: snapshot.id,
      environment_key: snapshot.environment_key,
      version: snapshot.version,
      payload: snapshot.payload,
      payload_checksum: snapshot.payload_checksum,
      metadata: normalize_metadata(snapshot.metadata),
      published_at: snapshot.published_at,
      inserted_at: snapshot.inserted_at,
      updated_at: snapshot.updated_at
    }
  end

  defp normalize_metadata(metadata) when is_map(metadata) do
    %{
      schema_version: metadata[:schema_version] || metadata["schema_version"],
      flag_count: metadata[:flag_count] || metadata["flag_count"]
    }
  end

  defp normalize_metadata(_metadata), do: %{}

  defp list_environment_filter(nil), do: {:ok, nil}

  defp list_environment_filter(environment_key) do
    case Repo.get_by(Environment, key: to_string(environment_key)) do
      nil -> {:error, StoreError.environment_not_found(environment_key)}
      environment -> {:ok, environment.key}
    end
  end

  defp maybe_filter_environment(query, nil), do: query

  defp maybe_filter_environment(query, environment_key),
    do: where(query, [_, _, env], env.key == ^environment_key)

  defp maybe_filter_archived(query, true), do: query

  defp maybe_filter_archived(query, false),
    do: where(query, [flag, _, _], is_nil(flag.archived_at))

  defp maybe_filter_query(query, nil), do: query
  defp maybe_filter_query(query, ""), do: query

  defp maybe_filter_query(query, search) do
    normalized = "%" <> String.downcase(String.trim(to_string(search))) <> "%"

    where(
      query,
      [flag, _, _],
      ilike(flag.key, ^normalized) or
        ilike(fragment("coalesce(?, '')", flag.description), ^normalized)
    )
  end

  defp maybe_sort(query, :inserted_at), do: order_by(query, [flag, _, _], desc: flag.inserted_at)
  defp maybe_sort(query, :updated_at), do: order_by(query, [flag, _, _], desc: flag.updated_at)
  defp maybe_sort(query, _sort), do: order_by(query, [flag, _, _], asc: flag.key)

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

  defp store_changeset_error(changeset, flag_key, environment_key) do
    StoreError.invalid_command(
      "store command is invalid",
      metadata: %{flag_key: to_string(flag_key), environment_key: to_string(environment_key)},
      details: collect_changeset_details(changeset),
      cause: changeset
    )
  end

  defp collect_changeset_details(%Changeset{} = changeset, path \\ nil) do
    own_details =
      Enum.map(changeset.errors, fn {field, {message, _opts}} ->
        detail = %{field: path_field(path, field), message: message}
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

            _ ->
              []
          end)

        _ ->
          []
      end)

    own_details ++ nested_details
  end

  defp path_field(nil, field), do: to_string(field)
  defp path_field(path, field), do: "#{path}.#{field}"

  defp audit_multi(multi, key, command, ruleset, environment) do
    Multi.insert(
      multi,
      key,
      AuditEvent.changeset(%AuditEvent{}, %{
        event_type: audit_event_type(command),
        resource_type: "flag",
        resource_key: audit_flag_key(command),
        environment_key: environment && environment.key,
        actor_id: get_in(command.actor || %{}, [:id]),
        actor_type: get_in(command.actor || %{}, [:type]),
        actor_display: get_in(command.actor || %{}, [:display]),
        reason: Map.get(command, :reason),
        result: :ok,
        metadata: audit_metadata(command, ruleset),
        correlation_id: correlation_id(command),
        occurred_at: now()
      })
    )
  end

  defp audit_event_type(%Command.PublishRuleset{}), do: "ruleset.publish"
  defp audit_event_type(%Command.ArchiveFlag{}), do: "flag.archive"

  defp audit_flag_key(command), do: to_string(Map.get(command, :flag_key))

  defp audit_metadata(command, ruleset) do
    metadata =
      command
      |> Map.get(:metadata, %{})
      |> Map.new()
      |> Map.take([:source, "source", :request_id, "request_id"])

    if ruleset, do: Map.put(metadata, :version, ruleset.version), else: metadata
  end

  defp correlation_id(command) do
    command.metadata[:request_id] || command.metadata["request_id"]
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)

  defp flag_by_key_query(flag_key) do
    from(flag in Flag,
      where: flag.key == ^to_string(flag_key),
      preload: [flag_environments: [:environment, :active_ruleset]]
    )
  end

  defp flag_with_environment_query(flag_key, environment_key) do
    from(flag in Flag,
      where: flag.key == ^to_string(flag_key),
      join: fe in assoc(flag, :flag_environments),
      on: fe.flag_id == flag.id,
      join: env in assoc(fe, :environment),
      on: env.id == fe.environment_id and env.key == ^to_string(environment_key),
      preload: [flag_environments: {fe, [:environment, :active_ruleset]}]
    )
  end

  defp environment_snapshot_flags_query(environment_key) do
    from(flag in Flag,
      where: is_nil(flag.archived_at),
      join: fe in assoc(flag, :flag_environments),
      on: fe.flag_id == flag.id and fe.status == :active and not is_nil(fe.active_ruleset_id),
      join: env in assoc(fe, :environment),
      on: env.id == fe.environment_id and env.key == ^to_string(environment_key),
      order_by: [asc: flag.key],
      preload: [flag_environments: {fe, [:environment, :active_ruleset]}]
    )
  end

  defp runtime_snapshot_query(%Command.FetchSnapshot{version: nil}, environment_key) do
    from(snapshot in RuntimeSnapshot,
      where: snapshot.environment_key == ^environment_key,
      order_by: [desc: snapshot.version],
      limit: 1
    )
  end

  defp runtime_snapshot_query(%Command.FetchSnapshot{version: version}, environment_key) do
    from(snapshot in RuntimeSnapshot,
      where: snapshot.environment_key == ^environment_key and snapshot.version == ^version,
      limit: 1
    )
  end

  defp snapshot_lookup_metadata(environment_key, nil), do: %{environment_key: environment_key}

  defp snapshot_lookup_metadata(environment_key, version) do
    %{environment_key: environment_key, version: version}
  end
end
