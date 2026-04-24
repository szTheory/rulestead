defmodule Rulestead.Store.Ecto do
  @moduledoc false

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.ConstraintError
  alias Ecto.Multi

  alias Rulestead.{
    Admin.Lifecycle,
    Audience,
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
      {:ok, build_flag_detail_payload(flag, environment, flag_environment, command.include_ruleset?)}
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
  def create_flag(%Command.CreateFlag{} = command) do
    with {:ok, environments} <- create_environments(command.environment_keys) do
      attrs = %{
        key: to_string(command.key),
        description: command.description,
        flag_type: command.flag_type,
        value_type: command.value_type,
        default_value: command.default_value,
        owner: command.owner,
        expected_expiration: command.expected_expiration,
        permanent: command.permanent,
        tags: command.tags
      }

      Multi.new()
      |> Multi.insert(:flag, Flag.changeset(%Flag{}, attrs))
      |> Multi.run(:flag_environments, fn repo, %{flag: flag} ->
        insert_flag_environments(repo, flag, environments)
      end)
      |> Repo.transact()
      |> case do
        {:ok, %{flag: flag}} ->
          flag = flag_by_key_query(flag.key) |> Repo.one()
          {:ok, build_create_payload(flag)}

        {:error, :flag, %Changeset{} = changeset, _changes} ->
          {:error, store_changeset_error(changeset, command.key, :all)}

        {:error, :flag_environments, %Rulestead.Error{} = error, _changes} ->
          {:error, error}

        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def update_flag(%Command.UpdateFlag{} = command) do
    case flag_by_key_query(command.flag_key) |> Repo.one() do
      nil ->
        {:error, StoreError.flag_not_found(command.flag_key, :all)}

      flag ->
        with :ok <- ensure_not_archived(command.flag_key, flag) do
          attrs =
            %{}
            |> maybe_put_update_field(:description, command.description)
            |> maybe_put_update_field(:owner, command.owner)
            |> maybe_put_update_field(:tags, command.tags)
            |> maybe_put_lifecycle_update(command)

          flag
          |> Flag.changeset(attrs)
          |> Repo.update()
          |> case do
            {:ok, updated_flag} ->
              updated_flag = flag_by_key_query(updated_flag.key) |> Repo.one()
              {:ok, build_update_payload(updated_flag, flag.owner)}

            {:error, %Changeset{} = changeset} ->
              {:error, store_changeset_error(changeset, command.flag_key, :all)}
          end
        end
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def save_draft_ruleset(%Command.SaveDraftRuleset{} = command) do
    case audit_result(command) do
      :denied ->
        with {:ok, audit_event} <- insert_audit_only_event(command, audit_event_type(command), :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
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
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def publish_ruleset(%Command.PublishRuleset{} = command) do
    case audit_result(command) do
      :denied ->
        with {:ok, audit_event} <- insert_audit_only_event(command, audit_event_type(command), :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
        with {:ok, environment} <- fetch_environment(command.environment_key),
             {:ok, flag, flag_environment} <-
               fetch_flag_environment(command.flag_key, environment.key),
             :ok <- ensure_not_archived(command.flag_key, flag),
             {:ok, ruleset} <-
               resolve_publishable_ruleset(flag_environment, environment.key, command.version) do
          published_at = now()
          previous_ruleset = active_ruleset(flag_environment)

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
          |> audit_multi(:audit_event, command, ruleset, environment, previous_ruleset)
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
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def archive_flag(%Command.ArchiveFlag{} = command) do
    case audit_result(command) do
      :denied ->
        with {:ok, audit_event} <- insert_audit_only_event(command, audit_event_type(command), :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
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
            |> audit_multi(:audit_event, command, nil, nil, nil)
            |> Repo.transact()
            |> case do
              {:ok, _changes} ->
                archived_flag = flag_by_key_query(command.flag_key) |> Repo.one()
                Enum.each(archived_flag.flag_environments, &insert_runtime_snapshot(Repo, &1.environment, archived_at))
                {:ok, build_archive_payload(archived_flag)}

              {:error, :flag, %Changeset{} = changeset, _changes} ->
                {:error, store_changeset_error(changeset, command.flag_key, :all)}

              {:error, _operation, reason, _changes} ->
                {:error, StoreError.unavailable(cause: reason)}
            end
        end
    end
  end

  @impl Store
  def list_flags(%Command.ListFlags{} = command) do
    with {:ok, environment_filter} <- list_environment_filter(command.environment_key) do
      entries =
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
        |> Repo.all()
        |> Enum.flat_map(fn flag ->
          Enum.map(flag.flag_environments, fn flag_environment ->
            build_list_entry(%{
              flag: flag,
              environment: flag_environment.environment,
              flag_environment: flag_environment
            })
          end)
        end)
        |> maybe_filter_owner(command.owner)
        |> maybe_filter_tags(command.tags)
        |> maybe_filter_lifecycle(command.lifecycle)
        |> maybe_filter_stale(command.stale)
        |> sort_entries(command.sort)

      {:ok, paginate_entries(entries, command)}
    end
  end

  @impl Store
  def list_environments(%Command.ListEnvironments{} = command) do
    environments =
      Environment
      |> maybe_filter_environment_query(command.query)
      |> order_by([environment], asc: environment.key)
      |> limit(^command.limit)
      |> Repo.all()
      |> Enum.map(&environment_summary/1)

    {:ok, environments}
  end

  @impl Store
  def list_audiences(%Command.ListAudiences{} = command) do
    audiences =
      Audience
      |> maybe_filter_archived_audiences(command.include_archived?)
      |> maybe_filter_audience_query(command.query)
      |> order_by([audience], asc: audience.key)
      |> limit(^command.limit)
      |> Repo.all()
      |> Enum.map(&audience_summary/1)

    {:ok, audiences}
  end

  @impl Store
  def record_evaluation(%Command.RecordEvaluation{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, _flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key) do
      timestamp = DateTime.truncate(command.last_evaluated_at, :microsecond)

      next_timestamp =
        case flag_environment.last_evaluated_at do
          %DateTime{} = existing ->
            case DateTime.compare(existing, timestamp) do
              :gt -> existing
              _ -> timestamp
            end

          _ -> timestamp
        end

      flag_environment
      |> FlagEnvironment.changeset(%{last_evaluated_at: next_timestamp})
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          {:ok,
           %{
             flag_key: to_string(command.flag_key),
             environment_key: environment.key,
             last_evaluated_at: updated.last_evaluated_at
           }}

        {:error, %Changeset{} = changeset} ->
          {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}
      end
    end
  end

  @impl Store
  def engage_kill_switch(%Command.EngageKillSwitch{} = command) do
    case audit_result(command) do
      :denied ->
        with {:ok, audit_event} <- insert_audit_only_event(command, "kill_switch.engage", :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
        with {:ok, environment} <- fetch_environment(command.environment_key),
             {:ok, flag, flag_environment} <-
               fetch_flag_environment(command.flag_key, environment.key),
             :ok <- ensure_not_archived(command.flag_key, flag) do
          before_state = audit_state(flag_environment)

          Multi.new()
          |> Multi.update(
            :flag_environment,
            FlagEnvironment.changeset(flag_environment, %{
              status: :killswitched,
              kill_switch_variant_key: "default"
            })
          )
          |> Multi.run(:runtime_snapshot, fn repo, _changes ->
            insert_runtime_snapshot(repo, environment, now())
          end)
          |> Multi.insert(
            :audit_event,
            audit_event_changeset(%AuditEvent{}, command, "kill_switch.engage", :ok, %{
              before: before_state,
              after: %{"status" => :killswitched, "kill_switch_variant_key" => "default"}
            })
          )
          |> Repo.transact()
          |> case do
            {:ok, _changes} -> fetch_flag(Command.FetchFlag.new(command.flag_key, command.environment_key))
            {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
              {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}
            {:error, _operation, reason, _changes} -> {:error, StoreError.unavailable(cause: reason)}
          end
        end
    end
  end

  @impl Store
  def release_kill_switch(%Command.ReleaseKillSwitch{} = command) do
    case audit_result(command) do
      :denied ->
        with {:ok, audit_event} <- insert_audit_only_event(command, "kill_switch.release", :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
        with {:ok, environment} <- fetch_environment(command.environment_key),
             {:ok, flag, flag_environment} <-
               fetch_flag_environment(command.flag_key, environment.key),
             :ok <- ensure_not_archived(command.flag_key, flag) do
          before_state = audit_state(flag_environment)
          next_status = if(flag_environment.status == :killswitched, do: :active, else: flag_environment.status || :active)

          Multi.new()
          |> Multi.update(
            :flag_environment,
            FlagEnvironment.changeset(flag_environment, %{
              status: next_status,
              kill_switch_variant_key: nil
            })
          )
          |> Multi.run(:runtime_snapshot, fn repo, _changes ->
            insert_runtime_snapshot(repo, environment, now())
          end)
          |> Multi.insert(
            :audit_event,
            audit_event_changeset(%AuditEvent{}, command, "kill_switch.release", :ok, %{
              before: before_state,
              after: %{"status" => next_status, "kill_switch_variant_key" => nil}
            })
          )
          |> Repo.transact()
          |> case do
            {:ok, _changes} -> fetch_flag(Command.FetchFlag.new(command.flag_key, command.environment_key))
            {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
              {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}
            {:error, _operation, reason, _changes} -> {:error, StoreError.unavailable(cause: reason)}
          end
        end
    end
  end

  @impl Store
  def list_audit_events(%Command.ListAuditEvents{} = command) do
    entries =
      AuditEvent
      |> maybe_filter_audit_flag(command.flag_key)
      |> maybe_filter_audit_environment(command.environment_key)
      |> maybe_filter_audit_actor_id(command.actor_id)
      |> maybe_filter_audit_mutation(command.mutation)
      |> maybe_filter_audit_occurred_after(command.occurred_after)
      |> maybe_filter_audit_occurred_before(command.occurred_before)
      |> order_by([event], desc: event.occurred_at, desc: event.inserted_at)
      |> limit(^command.limit)
      |> Repo.all()
      |> Enum.map(&AuditEvent.serialize/1)

    {:ok, %Command.Page{entries: entries, limit: command.limit, has_next_page?: false, has_previous_page?: false}}
  end

  @impl Store
  def rollback_audit_event(%Command.RollbackAuditEvent{} = command) do
    case Repo.get(AuditEvent, command.audit_event_id) do
      nil ->
        {:error, StoreError.invalid_command("audit event was not found")}

      audit_event ->
        rollback_audit_event(command, audit_event)
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
        if(include_ruleset?,
          do: runtime_ruleset_payload(active_ruleset_payload(flag_environment), flag_environment),
          else: nil
        ),
      draft_rulesets:
        if(include_ruleset?,
          do: draft_ruleset_payloads(flag_environment),
          else: []
        )
    }
  end

  defp build_flag_detail_payload(flag, environment, flag_environment, include_ruleset?) do
    build_flag_payload(flag, environment, flag_environment, include_ruleset?)
    |> decorate_payload(flag, environment, flag_environment)
  end

  defp build_list_entry(entry) do
    entry
    |> entry_to_payload()
    |> decorate_payload(entry.flag, entry.environment, entry.flag_environment)
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

  defp build_create_payload(flag) do
    %{
      flag: flag_summary(flag),
      archived?: not is_nil(flag.archived_at),
      environment_keys: flag.flag_environments |> Enum.map(& &1.environment.key) |> Enum.sort(),
      environments:
        flag.flag_environments
        |> Enum.map(&environment_summary(&1.environment))
        |> Enum.sort_by(& &1.key),
      recent_owners: recent_owners(flag.owner)
    }
  end

  defp build_update_payload(flag, previous_owner) do
    {environment, flag_environment} = preferred_environment(flag)
    build_flag_detail_payload(flag, environment, flag_environment, true)
    |> Map.put(:recent_owners, recent_owners(flag.owner, previous_owner))
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
      :permanent,
      :tags,
      :archived_at,
      :inserted_at,
      :updated_at
    ])
  end

  defp environment_summary(environment) do
    Map.take(environment, [:id, :key, :name, :description, :inserted_at, :updated_at])
  end

  defp audience_summary(audience) do
    Map.take(audience, [:id, :key, :description, :definition, :archived_at, :inserted_at, :updated_at])
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
      last_evaluated_at: flag_environment.last_evaluated_at,
      inserted_at: flag_environment.inserted_at,
      updated_at: flag_environment.updated_at
    }
  end

  defp entry_to_payload(entry) do
    %{
      flag: flag_summary(entry.flag),
      environment: environment_summary(entry.environment),
      flag_environment: flag_environment_summary(entry.flag_environment),
      active_ruleset: active_ruleset_payload(entry.flag_environment),
      draft_rulesets: draft_ruleset_payloads(entry.flag_environment)
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

  defp rollback_audit_event(command, %AuditEvent{event_type: event_type} = audit_event)
       when event_type in ["kill_switch.engage", "kill_switch.release"] do
    inverse_operation =
      if event_type == "kill_switch.engage",
        do: :release_kill_switch,
        else: :engage_kill_switch

    inverse_status =
      if event_type == "kill_switch.engage",
        do: %{status: :active, kill_switch_variant_key: nil},
        else: %{status: :killswitched, kill_switch_variant_key: "default"}

    with {:ok, environment} <- fetch_environment(audit_event.environment_key),
         {:ok, flag, flag_environment} <- fetch_flag_environment(audit_event.resource_key, environment.key),
         :ok <- ensure_not_archived(audit_event.resource_key, flag) do
      before_state = audit_state(flag_environment)

      Multi.new()
      |> Multi.update(:flag_environment, FlagEnvironment.changeset(flag_environment, inverse_status))
      |> Multi.insert(
        :audit_event,
        audit_event_changeset(%AuditEvent{}, command, "audit.rollback", :ok, %{
          environment_key: audit_event.environment_key,
          resource_key: audit_event.resource_key,
          before: before_state,
          after: %{
            "status" => inverse_status.status,
            "kill_switch_variant_key" => inverse_status.kill_switch_variant_key
          },
          rollback_of_event_id: audit_event.id,
          links: %{"inverse_event_type" => inverse_operation}
        })
      )
      |> Repo.transact()
      |> case do
        {:ok, %{audit_event: rollback_event}} ->
          {:ok, %{audit_event: AuditEvent.serialize(rollback_event)}}

        {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
          {:error, store_changeset_error(changeset, audit_event.resource_key, audit_event.environment_key)}

        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
    end
  end

  defp rollback_audit_event(_command, _audit_event),
    do: {:error, StoreError.invalid_command("audit event cannot be rolled back")}

  defp audit_multi(multi, key, command, ruleset, environment, previous_ruleset) do
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
        metadata: audit_metadata(command, ruleset, previous_ruleset),
        correlation_id: correlation_id(command),
        occurred_at: now()
      })
    )
  end

  defp audit_event_type(%Command.SaveDraftRuleset{}), do: "ruleset.save_draft"
  defp audit_event_type(%Command.PublishRuleset{}), do: "ruleset.publish"
  defp audit_event_type(%Command.ArchiveFlag{}), do: "flag.archive"

  defp audit_flag_key(command), do: to_string(Map.get(command, :flag_key))

  defp audit_metadata(command, ruleset, previous_ruleset) do
    metadata =
      command
      |> Map.get(:metadata, %{})
      |> Map.new()
      |> Map.take([:source, "source", :request_id, "request_id"])

    metadata =
      if ruleset do
        metadata
        |> Map.put(:version, ruleset.version)
        |> Map.merge(ruleset_audit_metadata(previous_ruleset, ruleset))
      else
        metadata
      end

    metadata
  end

  defp correlation_id(command) do
    command.metadata[:request_id] || command.metadata["request_id"]
  end

  defp audit_state(flag_environment) do
    %{
      "status" => flag_environment.status,
      "kill_switch_variant_key" => flag_environment.kill_switch_variant_key
    }
  end

  defp audit_result(command) do
    command.metadata[:audit_result] || command.metadata["audit_result"]
  end

  defp insert_audit_only_event(command, event_type, result) do
    %AuditEvent{}
    |> audit_event_changeset(command, event_type, result, %{})
    |> Repo.insert()
  end

  defp audit_event_changeset(audit_event, command, event_type, result, opts) do
    AuditEvent.changeset(audit_event, %{
      event_type: event_type,
      resource_type: "flag",
      resource_key: to_string(Map.get(opts, :resource_key, Map.get(command, :flag_key))),
      environment_key: to_string(Map.get(opts, :environment_key, Map.get(command, :environment_key))),
      actor_id: get_in(command.actor || %{}, [:id]),
      actor_type: to_string(get_in(command.actor || %{}, [:type]) || "operator"),
      actor_display: get_in(command.actor || %{}, [:display]),
      reason: Map.get(command, :reason),
      result: result,
      metadata:
        AuditEvent.metadata(%{
          before: Map.get(opts, :before, %{}),
          after: Map.get(opts, :after, %{}),
          diff: diff_map(Map.get(opts, :before, %{}), Map.get(opts, :after, %{})),
          links: Map.get(opts, :links, %{}),
          context: Map.get(command, :metadata, %{}),
          request_id: correlation_id(command),
          source: command.metadata[:source] || command.metadata["source"],
          rollback_of_event_id: Map.get(opts, :rollback_of_event_id)
        }),
      correlation_id: correlation_id(command),
      occurred_at: now()
    })
  end

  defp diff_map(before_state, after_state) do
    Map.new(after_state, fn {key, value} ->
      before_value = Map.get(before_state, key) || Map.get(before_state, to_string(key))
      {to_string(key), %{"from" => before_value, "to" => value}}
    end)
  end

  defp maybe_filter_audit_flag(query, nil), do: query
  defp maybe_filter_audit_flag(query, flag_key), do: where(query, [event], event.resource_key == ^to_string(flag_key))

  defp maybe_filter_audit_environment(query, nil), do: query
  defp maybe_filter_audit_environment(query, environment_key),
    do: where(query, [event], event.environment_key == ^to_string(environment_key))

  defp maybe_filter_audit_actor_id(query, nil), do: query
  defp maybe_filter_audit_actor_id(query, actor_id), do: where(query, [event], event.actor_id == ^actor_id)

  defp maybe_filter_audit_mutation(query, nil), do: query
  defp maybe_filter_audit_mutation(query, mutation), do: where(query, [event], event.event_type == ^mutation)

  defp maybe_filter_audit_occurred_after(query, %DateTime{} = occurred_after),
    do: where(query, [event], event.occurred_at >= ^occurred_after)

  defp maybe_filter_audit_occurred_after(query, _occurred_after), do: query

  defp maybe_filter_audit_occurred_before(query, %DateTime{} = occurred_before),
    do: where(query, [event], event.occurred_at <= ^occurred_before)

  defp maybe_filter_audit_occurred_before(query, _occurred_before), do: query

  defp active_ruleset(%{active_ruleset_id: nil}), do: nil

  defp active_ruleset(%{active_ruleset_id: active_ruleset_id}) do
    Repo.get(Ruleset, active_ruleset_id)
  end

  defp ruleset_audit_metadata(previous_ruleset, ruleset) do
    before = ruleset_audit_state(previous_ruleset)
    after_state = ruleset_audit_state(ruleset)

    %{
      before: before,
      after: after_state,
      diff: ruleset_position_diff(before, after_state)
    }
  end

  defp ruleset_audit_state(nil), do: %{rules: []}

  defp ruleset_audit_state(ruleset) do
    %{
      rules:
        ruleset.rules
        |> Enum.with_index()
        |> Enum.map(fn {rule, position} ->
          %{key: rule.key, position: position}
        end)
    }
  end

  defp ruleset_position_diff(before_state, after_state) do
    before_positions =
      before_state
      |> Map.get(:rules, [])
      |> Map.new(fn %{key: key, position: position} -> {key, position} end)

    %{
      rules:
        after_state
        |> Map.get(:rules, [])
        |> Enum.map(fn %{key: key, position: position} ->
          %{key: key, from: Map.get(before_positions, key), to: position}
        end)
    }
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)

  defp decorate_payload(payload, flag, environment, flag_environment) do
    environment_cards = environment_cards(flag)

    payload
    |> Map.put(:lifecycle, lifecycle(flag, flag_environment))
    |> Map.put(:has_draft_ruleset?, payload.draft_rulesets != [])
    |> Map.put(:recent_owners, recent_owners(flag.owner))
    |> Map.put(:environments, Enum.map(environment_cards, & &1.environment))
    |> Map.put(:environment_cards, environment_cards)
    |> Map.put(:environment_status, flag_environment.status)
    |> Map.put(:environment_key, environment.key)
  end

  defp environment_cards(flag) do
    flag.flag_environments
    |> Enum.sort_by(& &1.environment.key)
    |> Enum.map(fn flag_environment ->
      drafts = draft_ruleset_payloads(flag_environment)

      %{
        environment: environment_summary(flag_environment.environment),
        flag_environment: flag_environment_summary(flag_environment),
        active_ruleset: active_ruleset_payload(flag_environment),
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

  defp recent_owners(current_owner, extra_owner \\ nil) do
    owners =
      from(flag in Flag, order_by: [desc: flag.updated_at], select: flag.owner)
      |> Repo.all()

    [normalize_owner(current_owner), normalize_owner(extra_owner) | Enum.map(owners, &normalize_owner/1)]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.take(5)
  end

  defp preferred_environment(flag) do
    flag.flag_environments
    |> Enum.sort_by(fn flag_environment ->
      {flag_environment.environment.key != "test", flag_environment.environment.key}
    end)
    |> List.first()
    |> then(fn flag_environment -> {flag_environment.environment, flag_environment} end)
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

  defp maybe_filter_lifecycle(entries, lifecycle_state) do
    Enum.filter(entries, fn entry ->
      entry.lifecycle.state == lifecycle_state
    end)
  end

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

  defp sort_entries(entries, :inserted_at) do
    Enum.sort(entries, fn left, right ->
      compare_datetime_desc(left.flag.inserted_at, right.flag.inserted_at, left, right)
    end)
  end

  defp sort_entries(entries, :updated_at) do
    Enum.sort(entries, fn left, right ->
      compare_datetime_desc(left.flag.updated_at, right.flag.updated_at, left, right)
    end)
  end

  defp sort_entries(entries, _sort) do
    Enum.sort_by(entries, fn entry -> {entry.flag.key, entry.environment.key} end)
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

  defp maybe_filter_environment_query(query, nil), do: query
  defp maybe_filter_environment_query(query, ""), do: query

  defp maybe_filter_environment_query(query, search) do
    normalized = "%" <> String.downcase(String.trim(to_string(search))) <> "%"

    where(
      query,
      [environment],
      ilike(environment.key, ^normalized) or
        ilike(environment.name, ^normalized) or
      ilike(fragment("coalesce(?, '')", environment.description), ^normalized)
    )
  end

  defp maybe_filter_archived_audiences(query, true), do: query

  defp maybe_filter_archived_audiences(query, false) do
    where(query, [audience], is_nil(audience.archived_at))
  end

  defp maybe_filter_audience_query(query, nil), do: query
  defp maybe_filter_audience_query(query, ""), do: query

  defp maybe_filter_audience_query(query, search) do
    normalized = "%#{String.trim(search)}%"

    where(
      query,
      [audience],
      ilike(audience.key, ^normalized) or ilike(fragment("coalesce(?, '')", audience.description), ^normalized)
    )
  end

  defp create_environments([]) do
    environments =
      from(environment in Environment, order_by: [asc: environment.key])
      |> Repo.all()

    case environments do
      [] -> {:error, StoreError.environment_not_found(:all)}
      values -> {:ok, values}
    end
  end

  defp create_environments(environment_keys) do
    normalized_keys = environment_keys |> Enum.map(&to_string/1) |> Enum.uniq()

    environments =
      from(environment in Environment,
        where: environment.key in ^normalized_keys,
        order_by: [asc: environment.key]
      )
      |> Repo.all()

    case normalized_keys -- Enum.map(environments, & &1.key) do
      [] -> {:ok, environments}
      [missing | _] -> {:error, StoreError.environment_not_found(missing)}
    end
  end

  defp insert_flag_environments(repo, flag, environments) do
    Enum.reduce_while(environments, {:ok, []}, fn environment, {:ok, acc} ->
      attrs = %{flag_id: flag.id, environment_id: environment.id, status: :draft}

      case repo.insert(FlagEnvironment.changeset(%FlagEnvironment{}, attrs)) do
        {:ok, flag_environment} ->
          {:cont, {:ok, [flag_environment | acc]}}

        {:error, %Changeset{} = changeset} ->
          {:halt, {:error, store_changeset_error(changeset, flag.key, environment.key)}}
      end
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
      on: fe.flag_id == flag.id and fe.status in [:active, :killswitched] and not is_nil(fe.active_ruleset_id),
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

  defp runtime_ruleset_payload(nil, _flag_environment), do: nil

  defp runtime_ruleset_payload(ruleset, %{status: :killswitched}) do
    %{ruleset | rules: []}
  end

  defp runtime_ruleset_payload(ruleset, _flag_environment), do: ruleset
end
