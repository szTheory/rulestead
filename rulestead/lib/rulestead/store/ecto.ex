# credo:disable-for-this-file
defmodule Rulestead.Store.Ecto do
  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.ConstraintError
  alias Ecto.Multi

  alias Rulestead.{
    Admin.Redaction,
    Admin.Lifecycle,
    Audience,
    Governance.Approval,
    Governance.ChangeRequest,
    Governance.ExecutionAttempt,
    Governance.ScheduledExecution,
    AuditEvent,
    CodeRefs.CodeReference,
    CodeRefs.ScanReceipt,
    Context,
    Environment,
    EnvironmentVersion,
    Flag,
    FlagEnvironment,
    GuardrailDecision,
    Guardrails.Decision,
    Guardrails.SignalFact,
    Manifest.Import,
    Oban,
    Promotion.Apply,
    Promotion.Compare,
    Repo,
    RuntimeSnapshot,
    Ruleset,
    RulesetError,
    Store,
    StoreError,
    Targeting.AudienceDependencies,
    Targeting.AudienceReferenceProjection,
    Targeting.DependencyInventory,
    Targeting.DependencyValidator,
    Targeting.ImpactPreview,
    Telemetry,
    Webhooks.Destination,
    Webhooks.Delivery
  }

  alias Rulestead.Runtime.{Config, Notifier}
  alias Rulestead.Store.Command

  @snapshot_schema_version 1
  @scheduled_execution_retry_limit 3

  @behaviour Store

  @impl Store
  def fetch_flag(%Command.FetchFlag{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key) do
      lifecycle_context = lifecycle_context_for_flags([flag.key])

      {:ok,
       build_flag_detail_payload(
         flag,
         environment,
         flag_environment,
         command.include_ruleset?,
         lifecycle_context
       )}
    end
  end

  @impl Store
  def compare_environments(%Command.CompareEnvironments{} = command) do
    with {:ok, source_environment} <- fetch_environment(command.source_environment_key),
         {:ok, target_environment} <- fetch_environment(command.target_environment_key) do
      flags =
        compare_flags_query(
          source_environment.key,
          target_environment.key,
          command.flag_keys
        )
        |> Repo.all()

      audiences =
        from(audience in Audience)
        |> Repo.all()
        |> Map.new(&{&1.key, audience_summary(&1)})

      {:ok,
       Compare.compare_projected(%{
         source_environment: environment_summary(source_environment),
         target_environment: environment_summary(target_environment),
         requested_flag_keys: command.flag_keys,
         compare_token: command.compare_token,
         tenant_key: command.tenant_key,
         source_flags: compare_payloads(flags, source_environment),
         target_flags: compare_payloads(flags, target_environment),
         audiences: audiences
       })}
    end
  end

  @impl Store
  def apply_promotion(%Command.ApplyPromotion{} = command) do
    run_promotion_apply(command, allow_protected_target?: false)
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @impl Store
  def preview_manifest_import(%Command.PreviewManifestImport{} = command) do
    with {:ok, target_manifest} <- Rulestead.export_manifest(command.target_environment_key) do
      {:ok,
       Import.preview(command.manifest, target_manifest,
         target_environment_key: command.target_environment_key
       )}
    end
  end

  @impl Store
  def apply_manifest_import(%Command.ApplyManifestImport{} = command) do
    run_manifest_import_apply(command, allow_protected_target?: false)
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  @doc false
  @spec rebuild_audience_reference_projection() ::
          {:ok, %{deleted_rows: non_neg_integer(), inserted_rows: non_neg_integer()}}
          | {:error, Rulestead.Error.t()}
  def rebuild_audience_reference_projection do
    case refresh_audience_reference_projection(nil) do
      {:ok, result} -> {:ok, result}
      {:error, error} -> {:error, error}
    end
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
    limit = command_limit(command)
    offset = command_offset(command)

    all_entries =
      AudienceReferenceProjection
      |> maybe_filter_projection_scope(command)
      |> Repo.all()
      |> Enum.map(&projection_row_to_entry/1)
      |> DependencyInventory.sort_entries()

    page_entries = all_entries |> Enum.drop(offset) |> Enum.take(limit)
    redacted = Redaction.redact_dependency_inventory(page_entries, redaction_options(command))

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
     }}
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  def list_audience_dependencies(command) when is_map(command) do
    command
    |> list_audience_dependencies_command()
    |> list_audience_dependencies()
  end

  defp run_promotion_apply(%Command.ApplyPromotion{} = command, opts) do
    allow_protected_target? = Keyword.get(opts, :allow_protected_target?, false)

    with {:ok, _source_environment} <- fetch_environment(command.source_environment_key),
         {:ok, target_environment} <- fetch_environment(command.target_environment_key),
         :ok <-
           ensure_promotion_target_allowed(
             target_environment.key,
             allow_protected_target?
           ),
         # Fail closed for direct apply and replay/re-apply paths.
         :ok <-
           Apply.validate_live_dependencies(
             command,
             dependency_validation_audiences(),
             message: "promotion apply blocked by dependency validation"
           ),
         {:ok, compare} <-
           compare_environments(
             Command.CompareEnvironments.new(
               command.source_environment_key,
               command.target_environment_key,
               flag_keys: command.flag_keys,
               compare_token: command.compare_token,
               tenant_key: command.tenant_key
             )
           ),
         :ok <- Apply.validate_with_compare(command, compare, allow_protected_target?: allow_protected_target?) do
      published_at = now()

      Multi.new()
      |> Multi.run(:applied_flags, fn repo, _changes ->
        apply_promotion_bundle(repo, target_environment, command, published_at)
      end)
      |> Multi.run(:environment_version, fn repo, %{applied_flags: applied_flags} ->
        insert_environment_version(repo, target_environment, command, applied_flags)
      end)
      |> Multi.run(:runtime_snapshot, fn repo, _changes ->
        insert_runtime_snapshot(repo, target_environment, published_at)
      end)
      |> Repo.transact()
      |> case do
        {:ok, %{environment_version: environment_version, runtime_snapshot: runtime_snapshot}} ->
          _ = refresh_audience_reference_projection(target_environment.key)

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
             snapshot_version: runtime_snapshot.version
           }}

        {:error, _operation, %Rulestead.Error{} = error, _changes} ->
          {:error, error}

        {:error, _operation, %Changeset{} = changeset, _changes} ->
          {:error,
           StoreError.invalid_command("promotion apply could not be persisted", cause: changeset)}

        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp run_manifest_import_apply(%Command.ApplyManifestImport{} = command, opts) do
    with {:ok, target_environment} <- fetch_environment(command.target_environment_key),
         :ok <-
           ensure_promotion_target_allowed(
             target_environment.key,
             Keyword.get(opts, :allow_protected_target?, false)
           ) do
      published_at = now()

      Multi.new()
      |> Multi.run(:applied_flags, fn repo, _changes ->
        apply_manifest_import_bundle(repo, target_environment, command, published_at)
      end)
      |> Multi.run(:environment_version, fn repo, %{applied_flags: applied_flags} ->
        insert_manifest_import_environment_version(
          repo,
          target_environment,
          command,
          applied_flags,
          published_at
        )
      end)
      |> Multi.run(:runtime_snapshot, fn repo, _changes ->
        insert_runtime_snapshot(repo, target_environment, published_at)
      end)
      |> Repo.transact()
      |> case do
        {:ok, %{environment_version: environment_version, runtime_snapshot: runtime_snapshot}} ->
          _ = refresh_audience_reference_projection(target_environment.key)

          {:ok,
           %{
             source_environment_key: command.source_environment_key,
             target_environment_key: command.target_environment_key,
             plan_token: command.plan_token,
             applied_flag_keys: command.flag_keys,
             dependency_closure_keys: command.dependency_closure_keys,
             environment_version_id: environment_version.id,
             environment_version_version: environment_version.version,
             snapshot_version: runtime_snapshot.version
           }}

        {:error, _operation, %Rulestead.Error{} = error, _changes} ->
          {:error, error}

        {:error, _operation, %Changeset{} = changeset, _changes} ->
          {:error,
           StoreError.invalid_command("manifest import could not be persisted", cause: changeset)}

        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
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
        ownership: command.ownership,
        lifecycle: command.lifecycle,
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
            |> maybe_put_update_field(:ownership, command.ownership)
            |> maybe_put_update_field(:tags, command.tags)
            |> maybe_put_lifecycle_update(command)

          flag
          |> Flag.changeset(attrs)
          |> Repo.update()
          |> case do
            {:ok, updated_flag} ->
              updated_flag = flag_by_key_query(updated_flag.key) |> Repo.one()
              {:ok, build_update_payload(updated_flag, flag.ownership.owner_ref)}

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
        with {:ok, audit_event} <-
               insert_audit_only_event(command, audit_event_type(command), :denied) do
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
        with {:ok, audit_event} <-
               insert_audit_only_event(command, audit_event_type(command), :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
        with {:ok, environment} <- fetch_environment(command.environment_key),
             {:ok, flag, flag_environment} <-
               fetch_flag_environment(command.flag_key, environment.key),
             :ok <- ensure_not_archived(command.flag_key, flag),
             {:ok, ruleset} <-
               resolve_publishable_ruleset(flag_environment, environment.key, command.version) do
          dependency_entries =
            publish_dependency_entries(environment.key, command, flag, ruleset)

          dependency_findings = validate_dependency_entries(command, dependency_entries)

          if DependencyValidator.blockers?(dependency_findings) do
            error =
              DependencyValidator.to_error(dependency_findings,
                message: "ruleset publish blocked by dependency validation"
              )

            _ = insert_blocked_publish_event(command, ruleset, dependency_findings)

            {:error, error}
          else
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
                _ = refresh_audience_reference_projection(command.environment_key)
                fetch_flag(Command.FetchFlag.new(command.flag_key, command.environment_key))

              {:error, :ruleset, %Changeset{} = changeset, _changes} ->
                {:error, ruleset_error(changeset, command.flag_key, command.environment_key)}

              {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
                {:error,
                 store_changeset_error(changeset, command.flag_key, command.environment_key)}

              {:error, _operation, reason, _changes} ->
                {:error, StoreError.unavailable(cause: reason)}
            end
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
        with {:ok, audit_event} <-
               insert_audit_only_event(command, audit_event_type(command), :denied) do
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

                Enum.each(
                  archived_flag.flag_environments,
                  &insert_runtime_snapshot(Repo, &1.environment, archived_at)
                )

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
      raw_entries =
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
            %{
              flag: flag,
              environment: flag_environment.environment,
              flag_environment: flag_environment
            }
          end)
        end)

      lifecycle_context = lifecycle_context_for_flags(Enum.map(raw_entries, & &1.flag.key))

      entries =
        raw_entries
        |> Enum.map(&build_list_entry(&1, lifecycle_context))
        |> maybe_filter_owner(command.owner)
        |> maybe_filter_tags(command.tags)
        |> maybe_filter_lifecycle(command.lifecycle)
        |> maybe_filter_stale(command.stale)
        |> maybe_filter_readiness(command.readiness)
        |> maybe_filter_evidence_quality(command.evidence_quality)
        |> maybe_filter_flag_type(command.flag_type)
        |> sort_entries(command.sort)

      {:ok, paginate_entries(entries, command)}
    end
  end

  defp maybe_filter_flag_type(entries, nil), do: entries

  defp maybe_filter_flag_type(entries, flag_type) do
    Enum.filter(entries, fn entry ->
      entry.flag.flag_type == flag_type
    end)
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
  def preview_audience_impact(%Command.PreviewAudienceImpact{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key || "test"),
         {:ok, audience} <- fetch_audience_for_mutation(command.audience_key),
         :ok <- ensure_audience_active(audience) do
      {:ok, audience_preview_payload(Repo, environment.key, audience, command)}
    end
  end

  @impl Store
  def apply_audience_mutation(%Command.ApplyAudienceMutation{} = command) do
    if audit_result(command) == :denied do
      insert_audience_audit_only_event(command, "audience.mutation_blocked", :denied)
    else
      apply_confirmed_audience_mutation(command)
    end
  rescue
    error in [ConstraintError] ->
      {:error, StoreError.unavailable(cause: error)}
  end

  defp apply_confirmed_audience_mutation(%Command.ApplyAudienceMutation{} = command) do
    published_at = now()

    Multi.new()
    |> Multi.run(:environment, fn _repo, _changes ->
      fetch_environment(command.environment_key)
    end)
    |> Multi.run(:audience, fn _repo, _changes ->
      fetch_audience_for_mutation(command.audience_key)
    end)
    |> Multi.run(:preview, fn repo, %{environment: environment, audience: audience} ->
      with :ok <- ensure_audience_active(audience),
           :ok <- ensure_supported_audience_operation(command),
           :ok <- ensure_audience_preview_schema(command),
           preview <- audience_preview_payload(repo, environment.key, audience, command),
           :ok <- ensure_fresh_audience_preview(command, preview),
           :ok <- ensure_protected_audience_confirmation(command) do
        {:ok, preview}
      end
    end)
    |> Multi.run(:dependency_validation, fn _repo, %{preview: preview} ->
      dependency_entries = audience_dependency_entries(preview, command)

      dependency_findings =
        validate_dependency_entries(command, dependency_entries,
          expected_reference_keys: command.affected_reference_keys
        )

      if DependencyValidator.blockers?(dependency_findings) do
        {:error,
         DependencyValidator.to_error(dependency_findings,
           message: "audience mutation blocked by dependency validation"
         )}
      else
        {:ok, dependency_findings}
      end
    end)
    |> Multi.run(:audience_mutation, fn repo, %{audience: audience} ->
      apply_audience_operation(repo, audience, command, published_at)
    end)
    |> Multi.run(:runtime_snapshot, fn repo, %{environment: environment} ->
      insert_runtime_snapshot(repo, environment, published_at)
    end)
    |> Multi.run(:audit_event, fn repo,
                                  %{
                                    audience: audience,
                                    audience_mutation: updated_audience,
                                    environment: environment,
                                    preview: preview
                                  } ->
      repo.insert(
        audience_audit_event_changeset(
          %AuditEvent{},
          command,
          audience_event_type(command.operation),
          :ok,
          %{
            environment_key: environment.key,
            before: audience_audit_state(audience),
            after: audience_audit_state(updated_audience),
            preview: preview,
            dependency_findings: []
          }
        )
      )
    end)
    |> Repo.transact()
    |> case do
      {:ok,
       %{
         audience_mutation: audience,
         preview: preview,
         runtime_snapshot: snapshot,
         audit_event: audit_event
       }} ->
        _ = refresh_audience_reference_projection(command.environment_key)

        {:ok,
         %{
           result: :ok,
           operation: command.operation,
           audience: audience_summary(audience),
           preview: preview,
           snapshot_version: snapshot.version,
           audit_event: AuditEvent.serialize(audit_event)
         }}

      {:error, _operation, %Rulestead.Error{} = error, _changes} ->
        _ = insert_blocked_audience_event(command, error)
        {:error, error}

      {:error, _operation, %Changeset{} = changeset, _changes} ->
        error =
          StoreError.invalid_command("audience mutation could not be persisted", cause: changeset)

        _ = insert_blocked_audience_event(command, error)
        {:error, error}

      {:error, _operation, reason, _changes} ->
        error = StoreError.unavailable(cause: reason)
        _ = insert_blocked_audience_event(command, error)
        {:error, error}
    end
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

          _ ->
            timestamp
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
  def advance_rollout(%Command.AdvanceRollout{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key),
         :ok <- ensure_not_archived(command.flag_key, flag),
         {:ok, active_ruleset} <- ensure_active_ruleset(flag_environment, command),
         {:ok, rollout_rule} <- resolve_rollout_rule(active_ruleset, command.rule_key),
         {:ok, percentage} <- ensure_rollout_percentage(command.percentage),
         {:ok, next_ruleset_attrs} <-
           advanced_ruleset_attrs(active_ruleset, rollout_rule.key, percentage) do
      published_at = now()
      previous_ruleset = active_ruleset

      Multi.new()
      |> Multi.insert(
        :ruleset,
        Ruleset.changeset(%Ruleset{}, %{
          flag_environment_id: flag_environment.id,
          version: next_ruleset_version(flag_environment.id),
          status: :published,
          salt: next_ruleset_attrs.salt,
          published_at: published_at,
          metadata: next_ruleset_attrs.metadata,
          rules: next_ruleset_attrs.rules
        })
      )
      |> Multi.run(:flag_environment, fn repo, %{ruleset: ruleset} ->
        flag_environment
        |> FlagEnvironment.changeset(%{
          active_ruleset_id: ruleset.id,
          status: :active,
          last_published_at: published_at
        })
        |> repo.update()
      end)
      |> Multi.update(:flag, Changeset.change(flag, updated_at: published_at))
      |> Multi.run(:runtime_snapshot, fn repo, _changes ->
        insert_runtime_snapshot(repo, environment, published_at)
      end)
      |> Multi.run(:decision, fn repo, %{ruleset: ruleset} ->
        repo.insert(
          GuardrailDecision.changeset(
            %GuardrailDecision{},
            advance_decision_attrs(command, ruleset, rollout_rule, published_at)
          )
        )
      end)
      |> Multi.run(:audit_event, fn repo, %{ruleset: ruleset, decision: decision} ->
        repo.insert(
          audit_event_changeset(%AuditEvent{}, command, "rollout.advance", :ok, %{
            environment_key: environment.key,
            before: ruleset_audit_state(previous_ruleset),
            after: ruleset_audit_state(ruleset),
            diff: ruleset_position_diff(previous_ruleset, ruleset),
            links: %{"guardrail_decision_id" => decision.id}
          })
        )
      end)
      |> Repo.transact()
      |> case do
        {:ok, %{decision: decision, ruleset: ruleset}} ->
          {:ok, guardrail_status_payload(decision, ruleset.version)}

        {:error, :ruleset, %Changeset{} = changeset, _changes} ->
          {:error, ruleset_error(changeset, command.flag_key, command.environment_key)}

        {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
          {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

        {:error, :decision, %Changeset{} = changeset, _changes} ->
          {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

        {:error, _operation, reason, _changes} ->
          {:error, StoreError.unavailable(cause: reason)}
      end
    end
  end

  @impl Store
  def evaluate_guarded_rollout(%Command.EvaluateGuardedRollout{} = command) do
    with {:ok, environment} <- fetch_environment(command.environment_key),
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, environment.key),
         :ok <- ensure_not_archived(command.flag_key, flag),
         {:ok, active_ruleset} <- ensure_active_ruleset(flag_environment, command),
         {:ok, rollout_rule} <- resolve_rollout_rule(active_ruleset, command.rule_key) do
      signal_facts = Enum.map(command.signal_facts, &SignalFact.new/1)

      evaluated =
        Decision.evaluate(signal_facts,
          evaluated_at: now(),
          monitoring_window_ends_at: command.monitoring_window_ends_at
        )

      execute_guardrail_decision(
        command,
        environment,
        flag,
        flag_environment,
        active_ruleset,
        rollout_rule,
        evaluated
      )
    end
  end

  @impl Store
  def fetch_guardrail_status(%Command.FetchGuardrailStatus{} = command) do
    with {:ok, _environment} <- fetch_environment(command.environment_key),
         {:ok, _flag, flag_environment} <-
           fetch_flag_environment(command.flag_key, command.environment_key),
         %GuardrailDecision{} = decision <- latest_guardrail_decision(command) do
      {:ok, guardrail_status_payload(decision, active_ruleset_version(flag_environment))}
    else
      nil ->
        {:error, StoreError.invalid_command("guardrail status was not found")}

      {:error, error} ->
        {:error, error}
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
            {:ok, _changes} ->
              fetch_flag(Command.FetchFlag.new(command.flag_key, command.environment_key))

            {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
              {:error,
               store_changeset_error(changeset, command.flag_key, command.environment_key)}

            {:error, _operation, reason, _changes} ->
              {:error, StoreError.unavailable(cause: reason)}
          end
        end
    end
  end

  @impl Store
  def release_kill_switch(%Command.ReleaseKillSwitch{} = command) do
    case audit_result(command) do
      :denied ->
        with {:ok, audit_event} <-
               insert_audit_only_event(command, "kill_switch.release", :denied) do
          {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}
        end

      _other ->
        with {:ok, environment} <- fetch_environment(command.environment_key),
             {:ok, flag, flag_environment} <-
               fetch_flag_environment(command.flag_key, environment.key),
             :ok <- ensure_not_archived(command.flag_key, flag) do
          before_state = audit_state(flag_environment)

          next_status =
            if(flag_environment.status == :killswitched,
              do: :active,
              else: flag_environment.status || :active
            )

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
            {:ok, _changes} ->
              fetch_flag(Command.FetchFlag.new(command.flag_key, command.environment_key))

            {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
              {:error,
               store_changeset_error(changeset, command.flag_key, command.environment_key)}

            {:error, _operation, reason, _changes} ->
              {:error, StoreError.unavailable(cause: reason)}
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

    {:ok,
     %Command.Page{
       entries: entries,
       limit: command.limit,
       has_next_page?: false,
       has_previous_page?: false
     }}
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

  @impl Store
  def submit_change_request(%Command.SubmitChangeRequest{} = command) do
    correlation_id = governance_correlation_id(command)
    submitted_at = now()

    Multi.new()
    |> Multi.run(:change_request, fn repo, _changes ->
      insert_change_request(repo, command, correlation_id, submitted_at)
    end)
    |> Multi.run(:audit_event, fn repo, %{change_request: change_request} ->
      audit_command = governance_audit_command(command, change_request, "submitted")

      repo.insert(
        audit_event_changeset(%AuditEvent{}, audit_command, "change_request.submitted", :ok, %{
          resource_key: change_request.resource_key,
          environment_key: change_request.environment_key
        })
      )
    end)
    |> enqueue_webhook_deliveries(
      "change_request.submitted",
      fn %{change_request: cr} ->
        %{
          "change_request_id" => cr.id,
          "status" => to_string(cr[:status] || cr[:state]),
          "governed_action" => to_string(cr[:governed_action] || cr[:action]),
          "reason" => cr.reason,
          "submitter" => Map.take(cr, [:submitter_id, :submitter_type, :submitter_display])
        }
      end,
      environment_key: command.environment_key,
      resource_type: "flag",
      resource_key: command.resource_key
    )
    |> Repo.transact()
    |> case do
      {:ok, %{change_request: change_request, audit_event: audit_event}} ->
        emit_governance_telemetry(:submitted, command, change_request, audit_event)
        {:ok, %{change_request: serialize_change_request_row(change_request)}}

      {:error, _operation, reason, _changes} ->
        {:error, normalize_governance_failure(reason)}
    end
  end

  @impl Store
  def approve_change_request(%Command.ApproveChangeRequest{} = command) do
    with {:ok, change_request} <- fetch_change_request_row(command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["submitted"]),
         :ok <- ensure_unique_reviewer(change_request.id, command) do
      reviewed_at = now()

      Multi.new()
      |> Multi.run(:approval, fn repo, _changes ->
        insert_approval(repo, change_request, command, "approved", reviewed_at)
      end)
      |> Multi.run(:change_request, fn repo, _changes ->
        approved_count = approved_count(repo, change_request.id) + 1

        next_status =
          if(approved_count >= required_approvals(change_request.approval_requirement_snapshot),
            do: "approved",
            else: "submitted"
          )

        update_change_request(repo, change_request, %{
          status: next_status,
          resolved_at: if(next_status == "approved", do: reviewed_at, else: nil),
          updated_at: reviewed_at
        })
      end)
      |> Multi.run(:audit_event, fn repo,
                                    %{approval: approval, change_request: updated_change_request} ->
        audit_command =
          governance_audit_command(command, updated_change_request, "approved")
          |> Map.update!(:metadata, &Map.put(&1, "approval_id", approval.id))

        repo.insert(
          audit_event_changeset(%AuditEvent{}, audit_command, "change_request.approved", :ok, %{
            resource_key: updated_change_request.resource_key,
            environment_key: updated_change_request.environment_key
          })
        )
      end)
      |> enqueue_webhook_deliveries(
        "change_request.approved",
        fn %{change_request: cr} ->
          %{
            "change_request_id" => cr.id,
            "status" => to_string(cr[:status] || cr[:state]),
            "governed_action" => to_string(cr[:governed_action] || cr[:action]),
            "reason" => cr.reason,
            "submitter" => Map.take(cr, [:submitter_id, :submitter_type, :submitter_display])
          }
        end,
        environment_key: change_request.environment_key,
        resource_type: change_request.resource_type,
        resource_key: change_request.resource_key
      )
      |> Repo.transact()
      |> case do
        {:ok,
         %{approval: approval, change_request: updated_change_request, audit_event: audit_event}} ->
          emit_governance_telemetry(:approved, command, updated_change_request, audit_event)

          {:ok,
           %{
             change_request: serialize_change_request_row(updated_change_request),
             approval: serialize_approval_row(approval)
           }}

        {:error, _operation, reason, _changes} ->
          {:error, normalize_governance_failure(reason)}
      end
    end
  end

  @impl Store
  def reject_change_request(%Command.RejectChangeRequest{} = command) do
    with {:ok, change_request} <- fetch_change_request_row(command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["submitted"]) do
      reviewed_at = now()

      Multi.new()
      |> Multi.run(:approval, fn repo, _changes ->
        insert_approval(repo, change_request, command, "rejected", reviewed_at)
      end)
      |> Multi.run(:change_request, fn repo, _changes ->
        update_change_request(repo, change_request, %{
          status: "rejected",
          resolved_at: reviewed_at,
          updated_at: reviewed_at
        })
      end)
      |> Multi.run(:audit_event, fn repo,
                                    %{approval: approval, change_request: updated_change_request} ->
        audit_command =
          governance_audit_command(command, updated_change_request, "rejected")
          |> Map.update!(:metadata, &Map.put(&1, "approval_id", approval.id))

        repo.insert(
          audit_event_changeset(%AuditEvent{}, audit_command, "change_request.rejected", :ok, %{
            resource_key: updated_change_request.resource_key,
            environment_key: updated_change_request.environment_key
          })
        )
      end)
      |> enqueue_webhook_deliveries(
        "change_request.rejected",
        fn %{change_request: cr} ->
          %{
            "change_request_id" => cr.id,
            "status" => to_string(cr[:status] || cr[:state]),
            "governed_action" => to_string(cr[:governed_action] || cr[:action]),
            "reason" => cr.reason,
            "submitter" => Map.take(cr, [:submitter_id, :submitter_type, :submitter_display])
          }
        end,
        environment_key: change_request.environment_key,
        resource_type: change_request.resource_type,
        resource_key: change_request.resource_key
      )
      |> Repo.transact()
      |> case do
        {:ok, %{change_request: updated_change_request, audit_event: audit_event}} ->
          emit_governance_telemetry(:rejected, command, updated_change_request, audit_event)
          {:ok, %{change_request: serialize_change_request_row(updated_change_request)}}

        {:error, _operation, reason, _changes} ->
          {:error, normalize_governance_failure(reason)}
      end
    end
  end

  @impl Store
  def cancel_change_request(%Command.CancelChangeRequest{} = command) do
    with {:ok, change_request} <- fetch_change_request_row(command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["submitted", "approved"]) do
      cancelled_at = now()

      Multi.new()
      |> Multi.run(:change_request, fn repo, _changes ->
        update_change_request(repo, change_request, %{
          status: "cancelled",
          resolved_at: cancelled_at,
          updated_at: cancelled_at
        })
      end)
      |> Multi.run(:audit_event, fn repo, %{change_request: updated_change_request} ->
        audit_command = governance_audit_command(command, updated_change_request, "cancelled")

        repo.insert(
          audit_event_changeset(%AuditEvent{}, audit_command, "change_request.cancelled", :ok, %{
            resource_key: updated_change_request.resource_key,
            environment_key: updated_change_request.environment_key
          })
        )
      end)
      |> enqueue_webhook_deliveries(
        "change_request.cancelled",
        fn %{change_request: cr} ->
          %{
            "change_request_id" => cr.id,
            "status" => to_string(cr[:status] || cr[:state]),
            "governed_action" => to_string(cr[:governed_action] || cr[:action]),
            "reason" => cr.reason,
            "submitter" => Map.take(cr, [:submitter_id, :submitter_type, :submitter_display])
          }
        end,
        environment_key: change_request.environment_key,
        resource_type: change_request.resource_type,
        resource_key: change_request.resource_key
      )
      |> Repo.transact()
      |> case do
        {:ok, %{change_request: updated_change_request}} ->
          {:ok, %{change_request: serialize_change_request_row(updated_change_request)}}

        {:error, _operation, reason, _changes} ->
          {:error, normalize_governance_failure(reason)}
      end
    end
  end

  @impl Store
  def execute_change_request(%Command.ExecuteChangeRequest{} = command) do
    with {:ok, change_request} <- fetch_change_request_row(command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["approved"]) do
      executed_at = now()

      Multi.new()
      |> Multi.run(:execution, fn _repo, _changes ->
        case execute_governed_change(change_request, command) do
          {:ok, res, cr, evt} -> {:ok, {res, cr, evt}}
          {:error, err} -> {:error, err}
        end
      end)
      |> Multi.run(:change_request, fn repo, _changes ->
        update_change_request(repo, change_request, %{
          status: "executed",
          resolved_at: executed_at,
          executed_at: executed_at,
          updated_at: executed_at
        })
      end)
      |> Multi.run(:audit_event, fn repo, %{change_request: updated_change_request} ->
        audit_command = governance_audit_command(command, updated_change_request, "merged")

        repo.insert(
          audit_event_changeset(%AuditEvent{}, audit_command, "change_request.merged", :ok, %{
            resource_key: updated_change_request.resource_key,
            environment_key: updated_change_request.environment_key
          })
        )
      end)
      |> enqueue_webhook_deliveries(
        "change_request.merged",
        fn %{change_request: cr} ->
          %{
            "change_request_id" => cr.id,
            "status" => to_string(cr[:status] || cr[:state]),
            "governed_action" => to_string(cr[:governed_action] || cr[:action]),
            "reason" => cr.reason,
            "submitter" => Map.take(cr, [:submitter_id, :submitter_type, :submitter_display])
          }
        end,
        environment_key: change_request.environment_key,
        resource_type: change_request.resource_type,
        resource_key: change_request.resource_key
      )
      |> Repo.transact()
      |> case do
        {:ok,
         %{
           execution: {execution_result, _, _},
           change_request: updated_change_request,
           audit_event: audit_event
         }} ->
          emit_governance_telemetry(:merged, command, updated_change_request, audit_event)

          {:ok,
           %{
             change_request: serialize_change_request_row(updated_change_request),
             execution_result: execution_result
           }}

        {:error, _operation, reason, _changes} ->
          {:error, normalize_governance_failure(reason)}
      end
    end
  end

  @impl Store
  def fetch_change_request(%Command.FetchChangeRequest{} = command) do
    with {:ok, change_request} <- fetch_change_request_row(command.change_request_id) do
      {:ok,
       %{
         change_request: serialize_change_request_row(change_request),
         approvals: list_approval_rows(change_request.id) |> Enum.map(&serialize_approval_row/1),
         audit_events: list_change_request_audit_events(change_request)
       }}
    end
  end

  @impl Store
  def list_change_requests(%Command.ListChangeRequests{} = command) do
    entries =
      from(cr in "change_requests",
        order_by: [desc: field(cr, :inserted_at)],
        limit: ^command.limit,
        select:
          map(cr, [
            :id,
            :status,
            :governed_action,
            :environment_key,
            :resource_type,
            :resource_key,
            :submitter_id,
            :submitter_type,
            :submitter_display,
            :reason,
            :approval_requirement_snapshot,
            :command_snapshot,
            :metadata,
            :correlation_id,
            :submitted_at,
            :resolved_at,
            :executed_at,
            :inserted_at,
            :updated_at
          ])
      )
      |> maybe_filter_change_request(:environment_key, command.environment_key)
      |> maybe_filter_change_request(:resource_type, command.resource_type)
      |> maybe_filter_change_request(:resource_key, command.resource_key)
      |> maybe_filter_change_request(:submitter_id, command.submitted_by_id)
      |> maybe_filter_change_request(
        :governed_action,
        normalize_change_request_filter(command.action)
      )
      |> maybe_filter_change_request(:status, normalize_change_request_filter(command.status))
      |> Repo.all()
      |> Enum.map(&normalize_governance_row/1)
      |> Enum.map(&serialize_change_request_row/1)

    {:ok,
     %Command.Page{
       entries: entries,
       limit: command.limit,
       has_next_page?: false,
       has_previous_page?: false
     }}
  end

  @impl Store
  def schedule_change_request(%Command.ScheduleChangeRequest{} = command) do
    with {:ok, change_request} <- fetch_change_request_row(command.change_request_id),
         :ok <- ensure_governance_transition(change_request, ["approved"]),
         {:ok, approvals} <- approved_snapshot(change_request.id) do
      attrs = %{
        state: "scheduled",
        change_request_id: uuid_param(change_request.id),
        governed_action: change_request.governed_action,
        environment_key: change_request.environment_key,
        resource_type: change_request.resource_type,
        resource_key: change_request.resource_key,
        execution_mode: "change_request",
        scheduled_by_id: actor_value(command.actor, "id"),
        scheduled_by_type: actor_value(command.actor, "type") || "operator",
        scheduled_by_display: actor_value(command.actor, "display"),
        approved_by_snapshot: approvals,
        execution_metadata: %{},
        scheduled_for: command.scheduled_for,
        executed_at: nil,
        attempt_count: 0,
        failure_reason: nil,
        last_oban_job_id: nil,
        command_snapshot: change_request.command_snapshot,
        approval_requirement_snapshot: change_request.approval_requirement_snapshot,
        metadata:
          Command.GovernanceSupport.with_tenant_provenance(
            command.metadata,
            change_request.command_snapshot
          ),
        correlation_id: change_request.correlation_id,
        idempotency_key: "scheduled_execution:change_request:#{change_request.id}",
        inserted_at: now(),
        updated_at: now()
      }

      insert_scheduled_execution(attrs, command)
    end
  end

  @impl Store
  def schedule_governed_action(%Command.ScheduleGovernedAction{} = command) do
    correlation_id = governance_correlation_id(command)
    inserted_at = now()

    attrs = %{
      state: "scheduled",
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
      execution_metadata: %{},
      scheduled_for: command.scheduled_for,
      executed_at: nil,
      attempt_count: 0,
      failure_reason: nil,
      last_oban_job_id: nil,
      command_snapshot: Command.GovernanceSupport.with_tenant_provenance(command.command),
      approval_requirement_snapshot: command.approval_requirement,
      metadata:
        Command.GovernanceSupport.with_tenant_provenance(command.metadata, command.command),
      correlation_id: correlation_id,
      idempotency_key: "scheduled_execution:#{correlation_id}",
      inserted_at: inserted_at,
      updated_at: inserted_at
    }

    insert_scheduled_execution(attrs, command)
  end

  @impl Store
  def cancel_scheduled_execution(%Command.CancelScheduledExecution{} = command) do
    with {:ok, scheduled_execution} <-
           fetch_scheduled_execution_row(command.scheduled_execution_id),
         :ok <- ensure_scheduled_transition(scheduled_execution.state, ["scheduled", "running"]) do
      Multi.new()
      |> Multi.run(:scheduled_execution, fn repo, _changes ->
        repo.update_all(
          from(se in "scheduled_executions",
            where: field(se, :id) == ^uuid_param(scheduled_execution.id)
          ),
          set: [
            state: "cancelled",
            failure_reason: command.reason,
            executed_at: scheduled_execution.executed_at,
            execution_metadata:
              scheduled_transition_metadata(
                scheduled_execution.execution_metadata,
                "cancelled",
                command
              ),
            updated_at: now()
          ]
        )

        fetch_scheduled_execution_row(scheduled_execution.id)
      end)
      |> Multi.run(:audit_event, fn repo, %{scheduled_execution: updated} ->
        insert_scheduled_execution_audit_event(
          repo,
          updated,
          command,
          "scheduled_execution.cancelled",
          :ok
        )
      end)
      |> Repo.transact()
      |> case do
        {:ok, %{scheduled_execution: updated, audit_event: audit_event}} ->
          emit_scheduled_execution_telemetry(:cancelled, command, updated, audit_event)

          {:ok, %{scheduled_execution: serialize_scheduled_execution_row(updated), attempts: []}}

        {:error, _operation, error, _changes} ->
          {:error, normalize_governance_failure(error)}
      end
    end
  end

  @impl Store
  def requeue_scheduled_execution(%Command.RequeueScheduledExecution{} = command) do
    with {:ok, scheduled_execution} <-
           fetch_scheduled_execution_row(command.scheduled_execution_id),
         :ok <- ensure_scheduled_transition(scheduled_execution.state, ["quarantined"]) do
      Multi.new()
      |> Multi.run(:scheduled_execution, fn repo, _changes ->
        repo.update_all(
          from(se in "scheduled_executions",
            where: field(se, :id) == ^uuid_param(scheduled_execution.id)
          ),
          set: [
            state: "scheduled",
            failure_reason: nil,
            execution_metadata:
              scheduled_transition_metadata(
                scheduled_execution.execution_metadata,
                "requeued",
                command
              ),
            updated_at: now()
          ]
        )

        fetch_scheduled_execution_row(scheduled_execution.id)
      end)
      |> Multi.run(:oban_job, fn repo, %{scheduled_execution: updated} ->
        enqueue_scheduled_execution_job(repo, updated, command.actor, now())
      end)
      |> Multi.run(:persist_job_id, fn repo,
                                       %{scheduled_execution: updated, oban_job: oban_job} ->
        repo.update_all(
          from(se in "scheduled_executions", where: field(se, :id) == ^uuid_param(updated.id)),
          set: [last_oban_job_id: oban_job.id, updated_at: now()]
        )

        fetch_scheduled_execution_row(updated.id)
      end)
      |> Multi.run(:audit_event, fn repo, %{persist_job_id: updated} ->
        insert_scheduled_execution_audit_event(
          repo,
          updated,
          command,
          "scheduled_execution.requeued",
          :ok
        )
      end)
      |> Repo.transact()
      |> case do
        {:ok, %{persist_job_id: updated, audit_event: audit_event}} ->
          emit_scheduled_execution_telemetry(:requeued, command, updated, audit_event)

          {:ok,
           %{
             scheduled_execution: serialize_scheduled_execution_row(updated),
             attempts:
               list_execution_attempt_rows(updated.id)
               |> Enum.map(&serialize_execution_attempt_row/1)
           }}

        {:error, _operation, reason, _changes} ->
          {:error, normalize_governance_failure(reason)}
      end
    end
  end

  @impl Store
  def execute_scheduled_execution(%Command.ExecuteScheduledExecution{} = command) do
    with {:ok, scheduled_execution} <-
           fetch_scheduled_execution_row(command.scheduled_execution_id) do
      case scheduled_execution.state do
        "completed" ->
          {:ok,
           %{
             scheduled_execution: serialize_scheduled_execution_row(scheduled_execution),
             attempts:
               list_execution_attempt_rows(scheduled_execution.id)
               |> Enum.map(&serialize_execution_attempt_row/1)
           }}

        "cancelled" ->
          {:error, StoreError.invalid_command("scheduled execution is cancelled")}

        "quarantined" ->
          {:error, StoreError.invalid_command("scheduled execution requires explicit requeue")}

        _other ->
          if lifecycle_telemetry_enabled?(command) do
            emit_scheduled_execution_telemetry(:started, command, scheduled_execution, nil,
              attempt_count: scheduled_execution.attempt_count + 1
            )
          end

          run_scheduled_execution(command, scheduled_execution)
      end
    end
  end

  @impl Store
  def fetch_scheduled_execution(%Command.FetchScheduledExecution{} = command) do
    with {:ok, scheduled_execution} <-
           fetch_scheduled_execution_row(command.scheduled_execution_id) do
      {:ok,
       %{
         scheduled_execution: serialize_scheduled_execution_row(scheduled_execution),
         attempts:
           list_execution_attempt_rows(scheduled_execution.id)
           |> Enum.map(&serialize_execution_attempt_row/1)
       }}
    end
  end

  @impl Store
  def list_scheduled_executions(%Command.ListScheduledExecutions{} = command) do
    entries =
      from(se in "scheduled_executions",
        order_by: [asc: field(se, :scheduled_for), asc: field(se, :inserted_at)],
        limit: ^command.limit,
        select:
          map(se, [
            :id,
            :state,
            :change_request_id,
            :governed_action,
            :environment_key,
            :resource_type,
            :resource_key,
            :execution_mode,
            :scheduled_by_id,
            :scheduled_by_type,
            :scheduled_by_display,
            :approved_by_snapshot,
            :execution_metadata,
            :scheduled_for,
            :executed_at,
            :attempt_count,
            :failure_reason,
            :last_oban_job_id,
            :command_snapshot,
            :approval_requirement_snapshot,
            :metadata,
            :correlation_id,
            :idempotency_key
          ])
      )
      |> maybe_filter_scheduled_execution(:environment_key, command.environment_key)
      |> maybe_filter_scheduled_execution(:resource_type, command.resource_type)
      |> maybe_filter_scheduled_execution(:resource_key, command.resource_key)
      |> maybe_filter_scheduled_execution(:change_request_id, command.change_request_id)
      |> maybe_filter_scheduled_execution(:scheduled_by_id, command.scheduled_by_id)
      |> maybe_filter_scheduled_state(command.state)
      |> maybe_filter_scheduled_action(command.action)
      |> maybe_filter_scheduled_window(:after, command.after)
      |> maybe_filter_scheduled_window(:before, command.before)
      |> Repo.all()
      |> Enum.map(&normalize_scheduled_execution_row/1)
      |> Enum.map(&serialize_scheduled_execution_row/1)

    {:ok,
     %Command.Page{
       entries: entries,
       limit: command.limit,
       has_next_page?: false,
       has_previous_page?: false
     }}
  end

  @impl Store
  def receive_inbound_webhook(%Command.ReceiveInboundWebhook{} = command) do
    correlation_id = command.correlation_id || Ecto.UUID.generate()
    inserted_at = now()

    attrs = %{
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
      verified_state: Atom.to_string(command.verified_state),
      rejection_reason: command.rejection_reason,
      correlation_id: correlation_id,
      inserted_at: inserted_at,
      updated_at: inserted_at
    }

    Multi.new()
    |> Multi.run(:receipt, fn repo, _changes ->
      case repo.insert_all("webhook_receipts", [attrs], returning: webhook_receipt_fields()) do
        {1, [row]} -> {:ok, normalize_webhook_receipt_row(row)}
        _ -> {:error, StoreError.unavailable()}
      end
    end)
    |> Multi.run(:replay_claim, fn repo, %{receipt: receipt} ->
      if command.verified_state == :accepted and not is_nil(command.delivery_id) do
        case repo.insert_all("webhook_replay_claims", [
               %{
                 provider: command.provider,
                 delivery_id: command.delivery_id,
                 receipt_id: uuid_param(receipt.id),
                 inserted_at: inserted_at
               }
             ]) do
          {1, _} -> {:ok, :recorded}
          _ -> {:error, :duplicate}
        end
      else
        {:ok, :skipped}
      end
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{receipt: receipt}} ->
        {:ok, serialize_webhook_receipt_row(receipt)}

      {:error, :replay_claim, :duplicate, _changes} ->
        {:error, StoreError.invalid_command("duplicate webhook delivery")}

      {:error, _operation, reason, _changes} ->
        {:error, normalize_governance_failure(reason)}
    end
  rescue
    error in [ConstraintError, Postgrex.Error] ->
      {:error, StoreError.invalid_command("duplicate webhook delivery", cause: error)}
  end

  @impl Store
  def fetch_webhook_record(%Command.FetchWebhookRecord{} = command) do
    case from(wr in "webhook_receipts",
           where: field(wr, :id) == ^uuid_param(command.receipt_id),
           select: map(wr, ^webhook_receipt_fields())
         )
         |> Repo.one() do
      nil -> {:error, StoreError.invalid_command("webhook record was not found")}
      row -> {:ok, serialize_webhook_receipt_row(normalize_webhook_receipt_row(row))}
    end
  end

  @impl Store
  def list_webhook_records(%Command.ListWebhookRecords{} = command) do
    entries =
      from(wr in "webhook_receipts",
        order_by: [desc: field(wr, :received_at), desc: field(wr, :inserted_at)],
        limit: ^command.limit,
        select: map(wr, ^webhook_receipt_fields())
      )
      |> maybe_filter_webhook_record(:provider, command.provider)
      |> maybe_filter_webhook_record(:endpoint_key, command.endpoint_key)
      |> maybe_filter_webhook_record(
        :verified_state,
        normalize_webhook_state_filter(command.verified_state)
      )
      |> maybe_filter_webhook_record(:topic, command.topic)
      |> Repo.all()
      |> Enum.map(&normalize_webhook_receipt_row/1)
      |> Enum.map(&serialize_webhook_receipt_row/1)

    {:ok,
     %Command.Page{
       entries: entries,
       limit: command.limit,
       has_next_page?: false,
       has_previous_page?: false
     }}
  end

  @impl Store
  def create_webhook_destination(%Command.CreateWebhookDestination{} = command) do
    attrs = %{
      name: command.name,
      description: command.description,
      url: command.url,
      secret_id: command.secret_id,
      environment_key: command.environment_key,
      subscriptions: command.subscriptions,
      enabled: command.enabled,
      metadata: command.metadata
    }

    %Destination{}
    |> Destination.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, destination} ->
        {:ok, serialize_webhook_destination(destination)}

      {:error, changeset} ->
        {:error, StoreError.invalid_command("failed to create destination", cause: changeset)}
    end
  end

  @impl Store
  def update_webhook_destination(%Command.UpdateWebhookDestination{} = command) do
    with {:ok, destination} <- fetch_destination_by_id(command.id) do
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

      destination
      |> Destination.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          {:ok, serialize_webhook_destination(updated)}

        {:error, changeset} ->
          {:error, StoreError.invalid_command("failed to update destination", cause: changeset)}
      end
    end
  end

  @impl Store
  def fetch_webhook_destination(%Command.FetchWebhookDestination{} = command) do
    case fetch_destination_by_id(command.id) do
      {:ok, destination} -> {:ok, serialize_webhook_destination(destination)}
      error -> error
    end
  end

  @impl Store
  def list_webhook_destinations(%Command.ListWebhookDestinations{} = command) do
    entries =
      from(d in Destination,
        order_by: [asc: d.name, asc: d.inserted_at],
        limit: ^command.limit
      )
      |> maybe_filter_destination(:environment_key, command.environment_key)
      |> Repo.all()
      |> Enum.map(&serialize_webhook_destination/1)

    {:ok,
     %Command.Page{
       entries: entries,
       limit: command.limit,
       has_next_page?: false,
       has_previous_page?: false
     }}
  end

  @impl Store
  def list_webhook_deliveries(%Command.ListWebhookDeliveries{} = command) do
    entries =
      from(d in Delivery,
        order_by: [desc: d.inserted_at],
        limit: ^command.limit,
        preload: [:webhook_outbound_event, :webhook_destination]
      )
      |> maybe_filter_delivery(:webhook_destination_id, command.destination_id)
      |> maybe_filter_delivery(:webhook_outbound_event_id, command.event_id)
      |> maybe_filter_delivery(:state, command.state)
      |> Repo.all()
      |> Enum.map(&serialize_webhook_delivery/1)

    {:ok,
     %Command.Page{
       entries: entries,
       limit: command.limit,
       has_next_page?: false,
       has_previous_page?: false
     }}
  end

  @impl Store
  def retry_webhook_delivery(%Command.RetryWebhookDelivery{} = command) do
    case Repo.get(Delivery, command.delivery_id) do
      nil ->
        {:error, StoreError.invalid_command("delivery was not found")}

      delivery ->
        # Just reset state to pending, next worker run will pick it up
        delivery
        |> Delivery.changeset(%{
          state: :pending,
          attempt_count: 0,
          terminal_failure_reason: nil
        })
        |> Repo.update()
        |> case do
          {:ok, updated} ->
            {:ok, serialize_webhook_delivery(updated)}

          {:error, changeset} ->
            {:error, StoreError.invalid_command("failed to retry delivery", cause: changeset)}
        end
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

  defp compare_flags_query(source_environment_key, target_environment_key, flag_keys) do
    [source_environment_key, target_environment_key]
    |> then(fn environment_keys ->
      from(flag in Flag,
        join: fe in FlagEnvironment,
        on: fe.flag_id == flag.id,
        join: env in Environment,
        on: env.id == fe.environment_id,
        where: env.key in ^environment_keys,
        preload: [flag_environments: {fe, [:environment, :active_ruleset]}],
        distinct: true
      )
    end)
    |> maybe_filter_compare_flag_keys(flag_keys)
  end

  defp maybe_filter_compare_flag_keys(query, nil), do: query
  defp maybe_filter_compare_flag_keys(query, []), do: query

  defp maybe_filter_compare_flag_keys(query, flag_keys) do
    where(query, [flag], flag.key in ^flag_keys)
  end

  defp compare_payloads(flags, environment) do
    flags
    |> Enum.reduce(%{}, fn flag, payloads ->
      case Enum.find(flag.flag_environments, &(&1.environment.key == environment.key)) do
        nil ->
          payloads

        flag_environment ->
          Map.put(
            payloads,
            flag.key,
            build_flag_payload(flag, environment, flag_environment, true)
          )
      end
    end)
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

  defp apply_promotion_bundle(repo, target_environment, command, published_at) do
    Enum.reduce_while(command.flag_keys, {:ok, []}, fn flag_key, {:ok, acc} ->
      case apply_promoted_flag(repo, flag_key, target_environment.key, command, published_at) do
        {:ok, applied_flag} -> {:cont, {:ok, [applied_flag | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, applied_flags} -> {:ok, Enum.reverse(applied_flags)}
      {:error, error} -> {:error, error}
    end
  end

  defp apply_manifest_import_bundle(repo, target_environment, command, published_at) do
    Enum.reduce_while(command.flag_keys, {:ok, []}, fn flag_key, {:ok, acc} ->
      case apply_imported_flag(repo, flag_key, target_environment, command, published_at) do
        {:ok, applied_flag} -> {:cont, {:ok, [applied_flag | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, applied_flags} -> {:ok, Enum.reverse(applied_flags)}
      {:error, error} -> {:error, error}
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

  defp apply_promoted_flag(repo, flag_key, target_environment_key, command, published_at) do
    with {:ok, flag, flag_environment} <-
           fetch_flag_environment_for_repo(repo, flag_key, target_environment_key),
         proposed_state <- Map.get(command.proposed_target_bundle, flag_key),
         false <- is_nil(proposed_state) do
      proposed_flag = Map.get(proposed_state, "flag", %{}) |> denormalize_promoted_value()

      proposed_flag_environment =
        Map.get(proposed_state, "flag_environment", %{}) |> denormalize_promoted_value()

      proposed_ruleset =
        Map.get(proposed_state, "active_ruleset", %{}) |> denormalize_promoted_value()

      flag_attrs =
        %{}
        |> maybe_put_update_field(:description, proposed_flag["description"])
        |> maybe_put_update_field(:default_value, proposed_flag["default_value"])
        |> maybe_put_update_field(:tags, proposed_flag["tags"])

      {:ok, updated_flag} =
        flag
        |> Flag.changeset(flag_attrs)
        |> repo.update()

      {:ok, inserted_ruleset} =
        %Ruleset{}
        |> Ruleset.changeset(%{
          flag_environment_id: flag_environment.id,
          version: next_ruleset_version_for_repo(repo, flag_environment.id),
          status: :published,
          salt: proposed_ruleset["salt"],
          published_at: published_at,
          metadata: Map.get(proposed_ruleset, "metadata", %{}),
          rules: Map.get(proposed_ruleset, "rules", [])
        })
        |> repo.insert()

      {:ok, updated_flag_environment} =
        flag_environment
        |> FlagEnvironment.changeset(%{
          active_ruleset_id: inserted_ruleset.id,
          status: normalize_flag_environment_status(proposed_flag_environment["status"]),
          kill_switch_variant_key: proposed_flag_environment["kill_switch_variant_key"],
          last_published_at: published_at,
          last_evaluated_at: proposed_flag_environment["last_evaluated_at"],
          variants_served: Map.get(proposed_flag_environment, "variants_served", %{})
        })
        |> repo.update()

      {:ok,
       %{
         flag_key: flag_key,
         flag: updated_flag,
         flag_environment: updated_flag_environment,
         ruleset: inserted_ruleset
       }}
    else
      true ->
        {:error,
         StoreError.invalid_command("promotion bundle is missing a proposed target state",
           metadata: %{flag_key: flag_key}
         )}

      {:error, error} ->
        {:error, error}
    end
  rescue
    error in [Ecto.InvalidChangesetError] ->
      {:error, StoreError.invalid_command("promotion apply could not be persisted", cause: error)}
  end

  defp apply_imported_flag(repo, flag_key, target_environment, command, published_at) do
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

      with {:ok, flag} <- upsert_import_flag(repo, flag_key, proposed_flag),
           :ok <- ensure_not_archived(flag_key, flag),
           {:ok, flag_environment} <-
             upsert_import_flag_environment(
               repo,
               flag,
               target_environment,
               proposed_flag_environment,
               published_at
             ),
           {:ok, inserted_ruleset} <-
             insert_import_ruleset(repo, flag_environment, proposed_ruleset, published_at),
           {:ok, updated_flag_environment} <-
             finalize_import_flag_environment(
               repo,
               flag_environment,
               inserted_ruleset,
               proposed_flag_environment,
               published_at
             ) do
        {:ok,
         %{
           flag_key: flag_key,
           flag: flag,
           flag_environment: updated_flag_environment,
           ruleset: inserted_ruleset
         }}
      end
    end
  rescue
    error in [Ecto.InvalidChangesetError] ->
      {:error, StoreError.invalid_command("manifest import could not be persisted", cause: error)}
  end

  defp insert_environment_version(repo, target_environment, command, _applied_flags) do
    %EnvironmentVersion{}
    |> EnvironmentVersion.changeset(%{
      environment_key: target_environment.key,
      version: next_environment_version(repo, target_environment.key),
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
      }
    })
    |> repo.insert()
  end

  defp insert_manifest_import_environment_version(
         repo,
         target_environment,
         command,
         _applied_flags,
         published_at
       ) do
    %EnvironmentVersion{}
    |> EnvironmentVersion.changeset(%{
      environment_key: target_environment.key,
      version: next_environment_version(repo, target_environment.key),
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
        "tenant" => Command.GovernanceSupport.tenant_provenance(command),
        "published_at" => DateTime.to_iso8601(published_at)
      }
    })
    |> repo.insert()
  end

  defp fetch_flag_environment_for_repo(repo, flag_key, environment_key) do
    flag =
      from(flag in Flag,
        where: flag.key == ^to_string(flag_key),
        join: fe in assoc(flag, :flag_environments),
        join: env in assoc(fe, :environment),
        where: env.key == ^to_string(environment_key),
        preload: [flag_environments: {fe, [:environment, :active_ruleset]}]
      )
      |> repo.one()

    case flag do
      nil ->
        {:error, StoreError.flag_not_found(flag_key, environment_key)}

      %{flag_environments: [flag_environment]} ->
        {:ok, flag, flag_environment}
    end
  end

  defp upsert_import_flag(repo, flag_key, proposed_flag) do
    flag_attrs =
      %{
        key: flag_key,
        description: proposed_flag["description"],
        flag_type: normalize_flag_type(proposed_flag["flag_type"]),
        value_type: normalize_value_type(proposed_flag["value_type"]),
        default_value: proposed_flag["default_value"] || %{},
        tags: proposed_flag["tags"] || []
      }

    case flag_by_key_query(flag_key) |> repo.one() do
      nil ->
        %Flag{}
        |> Flag.changeset(flag_attrs)
        |> repo.insert()

      flag ->
        flag
        |> Flag.changeset(flag_attrs)
        |> repo.update()
    end
  end

  defp upsert_import_flag_environment(
         repo,
         flag,
         target_environment,
         proposed_flag_environment,
         published_at
       ) do
    case fetch_existing_flag_environment_for_repo(repo, flag.id, target_environment.id) do
      nil ->
        %FlagEnvironment{}
        |> FlagEnvironment.changeset(%{
          flag_id: flag.id,
          environment_id: target_environment.id,
          status: normalize_flag_environment_status(proposed_flag_environment["status"]),
          kill_switch_variant_key: proposed_flag_environment["kill_switch_variant_key"],
          last_published_at: published_at,
          last_evaluated_at: proposed_flag_environment["last_evaluated_at"],
          variants_served: Map.get(proposed_flag_environment, "variants_served", %{})
        })
        |> repo.insert()

      %FlagEnvironment{} = flag_environment ->
        if flag_environment.status == :archived do
          {:error,
           StoreError.invalid_command("manifest import would revive an archived flag environment",
             metadata: %{flag_key: flag.key}
           )}
        else
          {:ok, flag_environment}
        end
    end
  end

  defp insert_import_ruleset(repo, flag_environment, proposed_ruleset, published_at) do
    %Ruleset{}
    |> Ruleset.changeset(%{
      flag_environment_id: flag_environment.id,
      version: next_ruleset_version_for_repo(repo, flag_environment.id),
      status: :published,
      salt: proposed_ruleset["salt"],
      published_at: published_at,
      metadata: Map.get(proposed_ruleset, "metadata", %{}),
      rules: Map.get(proposed_ruleset, "rules", [])
    })
    |> repo.insert()
  end

  defp finalize_import_flag_environment(
         repo,
         flag_environment,
         inserted_ruleset,
         proposed_flag_environment,
         published_at
       ) do
    flag_environment
    |> FlagEnvironment.changeset(%{
      active_ruleset_id: inserted_ruleset.id,
      status: normalize_flag_environment_status(proposed_flag_environment["status"]),
      kill_switch_variant_key: proposed_flag_environment["kill_switch_variant_key"],
      last_published_at: published_at,
      last_evaluated_at: proposed_flag_environment["last_evaluated_at"],
      variants_served: Map.get(proposed_flag_environment, "variants_served", %{})
    })
    |> repo.update()
  end

  defp fetch_existing_flag_environment_for_repo(repo, flag_id, environment_id) do
    from(fe in FlagEnvironment,
      where: fe.flag_id == ^flag_id and fe.environment_id == ^environment_id
    )
    |> repo.one()
  end

  defp normalize_flag_type(nil), do: :release

  defp normalize_flag_type(value) when is_binary(value) do
    try do
      parsed = String.to_existing_atom(value)
      if parsed in Flag.flag_types(), do: parsed, else: :release
    rescue
      ArgumentError -> :release
    end
  end

  defp normalize_flag_type(value) when is_atom(value) do
    if value in Flag.flag_types(), do: value, else: :release
  end

  defp normalize_flag_type(_value), do: :release

  defp normalize_value_type(nil), do: :boolean

  defp normalize_value_type(value) when is_binary(value) do
    try do
      parsed = String.to_existing_atom(value)
      if parsed in Flag.value_types(), do: parsed, else: :boolean
    rescue
      ArgumentError -> :boolean
    end
  end

  defp normalize_value_type(value) when is_atom(value) do
    if value in Flag.value_types(), do: value, else: :boolean
  end

  defp normalize_value_type(_value), do: :boolean

  defp next_ruleset_version_for_repo(repo, flag_environment_id) do
    from(ruleset in Ruleset,
      where: ruleset.flag_environment_id == ^flag_environment_id,
      select: max(ruleset.version)
    )
    |> repo.one()
    |> Kernel.||(0)
    |> Kernel.+(1)
  end

  defp next_environment_version(repo, environment_key) do
    from(version in EnvironmentVersion,
      where: version.environment_key == ^environment_key,
      select: max(version.version)
    )
    |> repo.one()
    |> Kernel.||(0)
    |> Kernel.+(1)
  end

  defp normalize_flag_environment_status(nil), do: :active

  defp normalize_flag_environment_status(status) when is_binary(status) do
    case String.to_existing_atom(status) do
      normalized ->
        if normalized in FlagEnvironment.statuses(), do: normalized, else: :active
    end
  rescue
    ArgumentError -> :active
  end

  defp normalize_flag_environment_status(status) when is_atom(status) do
    if status in FlagEnvironment.statuses(), do: status, else: :active
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

        :ok =
          Notifier.broadcast(
            Config.notifier(),
            %{environment_key: environment.key, snapshot_version: snapshot.version},
            pubsub: Config.pubsub(),
            pubsub_topic: Config.pubsub_topic()
          )

        {:ok, snapshot}

      {:error, %Changeset{} = changeset} ->
        {:error, changeset}
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
      flags: flags,
      audiences: compiled_audience_definitions(repo, environment)
    }
  end

  defp compiled_audience_definitions(repo, _environment) do
    Audience
    |> where([audience], is_nil(audience.archived_at))
    |> order_by([audience], asc: audience.key)
    |> repo.all()
    |> Map.new(fn audience ->
      {audience.key,
       %{
         definition: audience.definition,
         archived_at: audience.archived_at
       }}
    end)
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

  defp build_flag_detail_payload(
         flag,
         environment,
         flag_environment,
         include_ruleset?,
         lifecycle_context
       ) do
    build_flag_payload(flag, environment, flag_environment, include_ruleset?)
    |> decorate_payload(flag, environment, flag_environment, lifecycle_context)
  end

  defp build_list_entry(entry, lifecycle_context) do
    entry
    |> entry_to_payload()
    |> decorate_payload(entry.flag, entry.environment, entry.flag_environment, lifecycle_context)
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
      recent_owners: recent_owners(flag.ownership.owner_ref)
    }
  end

  defp build_update_payload(flag, previous_owner) do
    {environment, flag_environment} = preferred_environment(flag)
    lifecycle_context = lifecycle_context_for_flags([flag.key])

    build_flag_detail_payload(flag, environment, flag_environment, true, lifecycle_context)
    |> Map.put(:recent_owners, recent_owners(flag.ownership.owner_ref, previous_owner))
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
      :ownership,
      :lifecycle,
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

  defp audience_preview_payload(repo, environment_key, audience, command) do
    affected_references =
      AudienceDependencies.summarize(
        audience.key,
        audience_reference_payloads(repo, environment_key)
      )

    before_definition = command.before_definition || audience.definition

    after_definition =
      case command.operation do
        "update" -> command.after_definition || audience.definition
        _other -> command.after_definition
      end

    ImpactPreview.build(%{
      environment_key: environment_key,
      tenant_key: command.tenant_key,
      audience_key: audience.key,
      operation: command.operation,
      before_definition: before_definition,
      after_definition: after_definition,
      samples: Map.get(command, :samples, []),
      affected_references: affected_references,
      preview_basis: Map.get(command, :preview_basis)
    })
  end

  defp audience_reference_payloads(repo, environment_key) do
    environment_snapshot_flags_query(environment_key)
    |> repo.all()
    |> Enum.map(fn flag ->
      [flag_environment] = flag.flag_environments
      environment = flag_environment.environment

      %{
        flag: flag_summary(flag),
        environment_key: environment.key,
        tenant_key: "global",
        active_ruleset: active_ruleset_payload(flag_environment),
        lifecycle: plain_struct_map(flag.lifecycle)
      }
    end)
  end

  defp refresh_audience_reference_projection(environment_key) do
    Repo.transaction(fn repo ->
      environments =
        case normalize_projection_environment_key(environment_key) do
          nil -> projection_environment_keys(repo)
          key -> [key]
        end

      deleted_rows =
        repo.delete_all(
          from(projection in AudienceReferenceProjection,
            where: projection.environment_key in ^environments
          )
        )
        |> elem(0)

      inserted_rows = insert_projection_rows(repo, environments)

      %{deleted_rows: deleted_rows, inserted_rows: inserted_rows}
    end)
    |> case do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, StoreError.unavailable(cause: reason)}
    end
  end

  defp projection_environment_keys(repo) do
    from(environment in Environment, select: environment.key)
    |> repo.all()
    |> Enum.sort()
  end

  defp insert_projection_rows(_repo, []), do: 0

  defp insert_projection_rows(repo, environments) do
    environments
    |> Enum.flat_map(fn environment_key ->
      repo
      |> audience_reference_payloads(environment_key)
      |> projection_entries_from_payloads()
    end)
    |> Enum.reduce(0, fn attrs, inserted ->
      changeset = AudienceReferenceProjection.changeset(%AudienceReferenceProjection{}, attrs)

      case repo.insert(changeset) do
        {:ok, _projection} -> inserted + 1
        {:error, _changeset} -> inserted
      end
    end)
  end

  defp projection_entries_from_payloads(payloads) do
    payloads
    |> Enum.flat_map(&payload_projection_entries/1)
    |> Enum.reduce(%{}, fn entry, acc ->
      key = projection_identity_key(entry)
      Map.update(acc, key, entry, &Map.update!(&1, :reference_count, fn count -> count + 1 end))
    end)
    |> Map.values()
    |> DependencyInventory.sort_entries()
    |> Enum.map(&projection_entry_attrs/1)
  end

  defp payload_projection_entries(payload) do
    payload
    |> projection_rules()
    |> Enum.flat_map(fn rule ->
      if projection_rule_strategy(rule) == "segment_match" do
        [
          DependencyInventory.normalize_entry(%{
            environment_key: payload.environment_key,
            tenant_key: payload.tenant_key || "global",
            flag_key: get_in(payload, [:flag, :key]),
            ruleset_version: get_in(payload, [:active_ruleset, :version]),
            rule_key: projection_rule_key(rule),
            audience_key: projection_rule_audience_key(rule),
            ruleset_status: get_in(payload, [:active_ruleset, :status]),
            rollout_context: projection_rollout_context(rule),
            lifecycle_context: payload.lifecycle,
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
      rollout when is_map(rollout) -> plain_struct_map(rollout)
      _other -> %{}
    end
  end

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

  defp projection_entry_attrs(entry) do
    %{
      environment_key: entry.environment_key,
      tenant_key: entry.tenant_key,
      audience_key: entry.audience_key,
      flag_key: entry.flag_key,
      ruleset_version: entry.ruleset_version,
      rule_key: entry.rule_key,
      rule_strategy: "segment_match",
      ruleset_status: entry.ruleset_status,
      rollout_context: entry.rollout_context,
      lifecycle_context: entry.lifecycle_context,
      visibility: entry.visibility,
      reference_count: entry.reference_count,
      hidden_reference_count: entry.hidden_reference_count
    }
  end

  defp projection_row_to_entry(%AudienceReferenceProjection{} = projection) do
    DependencyInventory.normalize_entry(%{
      environment_key: projection.environment_key,
      tenant_key: projection.tenant_key,
      audience_key: projection.audience_key,
      flag_key: projection.flag_key,
      ruleset_version: projection.ruleset_version,
      rule_key: projection.rule_key,
      ruleset_status: projection.ruleset_status,
      rollout_context: projection.rollout_context,
      lifecycle_context: projection.lifecycle_context,
      visibility: projection.visibility,
      reference_count: projection.reference_count,
      hidden_reference_count: projection.hidden_reference_count
    })
  end

  defp publish_dependency_entries(environment_key, command, flag, ruleset) do
    tenant_key = publish_scope_tenant(command)
    flag_key = to_string(flag.key)

    ruleset_dependency_entries(
      environment_key,
      tenant_key,
      flag_key,
      ruleset
    )
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

  defp validate_dependency_entries(command, dependency_entries, opts \\ []) do
    findings =
      DependencyValidator.validate(
        %{
          tenant_key: publish_scope_tenant(command),
          audiences: dependency_validation_audiences(),
          expected_reference_keys: Keyword.get(opts, :expected_reference_keys),
          stale_reference_keys: Keyword.get(opts, :stale_reference_keys)
        },
        dependency_entries
      )

    DependencyValidator.sort_findings(findings)
  end

  defp dependency_validation_audiences do
    from(audience in Audience)
    |> Repo.all()
    |> Map.new(fn audience ->
      {audience.key,
       %{
         key: audience.key,
         tenant_key: Map.get(audience, :tenant_key),
         archived_at: audience.archived_at,
         definition: audience.definition
       }}
    end)
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

  defp insert_blocked_publish_event(command, ruleset, findings) do
    metadata = %{
      "version" => Map.get(ruleset, :version),
      "blockers" => dependency_blockers(findings),
      "dependency_findings" => serialize_dependency_findings(findings)
    }

    %AuditEvent{}
    |> audit_event_changeset(command, "ruleset.publish_blocked", :error, %{metadata: metadata})
    |> Repo.insert()
  end

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

  defp maybe_filter_projection_scope(query, command) do
    query
    |> maybe_filter_projection_environment(command)
    |> maybe_filter_projection_tenant(command)
    |> maybe_filter_projection_audience(command)
  end

  defp maybe_filter_projection_environment(query, command) do
    case normalize_projection_environment_key(Map.get(command, :environment_key)) do
      nil -> query
      environment_key -> where(query, [projection], projection.environment_key == ^environment_key)
    end
  end

  defp maybe_filter_projection_tenant(query, command) do
    case normalize_projection_tenant_key(Map.get(command, :tenant_key)) do
      nil -> query
      tenant_key -> where(query, [projection], projection.tenant_key == ^tenant_key)
    end
  end

  defp maybe_filter_projection_audience(query, command) do
    case normalize_projection_audience_key(Map.get(command, :audience_key)) do
      nil -> query
      audience_key -> where(query, [projection], projection.audience_key == ^audience_key)
    end
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

  defp normalize_projection_environment_key(nil), do: nil
  defp normalize_projection_environment_key(environment_key), do: to_string(environment_key)

  defp normalize_projection_tenant_key(nil), do: nil
  defp normalize_projection_tenant_key(tenant_key), do: to_string(tenant_key)

  defp normalize_projection_audience_key(nil), do: nil
  defp normalize_projection_audience_key(audience_key), do: to_string(audience_key)

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
    [
      visible_audience_keys: Map.get(command, :visible_audience_keys),
      include_redacted_placeholders?: Map.get(command, :include_redacted_placeholders?, false)
    ]
  end

  defp plain_struct_map(%_{} = value), do: value |> Map.from_struct() |> plain_struct_map()

  defp plain_struct_map(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {key, plain_struct_map(nested)} end)
  end

  defp plain_struct_map(value) when is_list(value), do: Enum.map(value, &plain_struct_map/1)
  defp plain_struct_map(value), do: value

  defp fetch_audience_for_mutation(audience_key) do
    case Repo.get_by(Audience, key: to_string(audience_key)) do
      nil -> {:error, StoreError.invalid_command("audience was not found")}
      audience -> {:ok, audience}
    end
  end

  defp ensure_audience_active(%Audience{archived_at: nil}), do: :ok

  defp ensure_audience_active(%Audience{}),
    do: {:error, StoreError.invalid_command("audience is archived")}

  defp ensure_supported_audience_operation(%Command.ApplyAudienceMutation{
         operation: "delete_attempt"
       }) do
    {:error, StoreError.invalid_command("audience_delete_unsupported")}
  end

  defp ensure_supported_audience_operation(%Command.ApplyAudienceMutation{operation: operation})
       when operation in ["update", "archive"],
       do: :ok

  defp ensure_supported_audience_operation(%Command.ApplyAudienceMutation{} = command),
    do:
      {:error, StoreError.invalid_command("unsupported audience operation: #{command.operation}")}

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

  defp ensure_audience_reference_keys(command, current_preview) do
    expected_keys = preview_reference_keys(current_preview)

    if command.affected_reference_keys == expected_keys do
      :ok
    else
      {:error, StoreError.invalid_command("audience preview affected references do not match")}
    end
  end

  defp ensure_protected_audience_confirmation(%Command.ApplyAudienceMutation{
         protected_shared_targeting?: true
       }) do
    {:error,
     StoreError.invalid_command("protected shared targeting mutation requires confirmation")}
  end

  defp ensure_protected_audience_confirmation(%Command.ApplyAudienceMutation{}), do: :ok

  defp apply_audience_operation(
         repo,
         %Audience{} = audience,
         %Command.ApplyAudienceMutation{operation: "update"} = command,
         published_at
       ) do
    audience
    |> Audience.changeset(%{
      definition: command.after_definition || audience.definition,
      description: command.metadata["description"] || audience.description
    })
    |> Changeset.change(updated_at: published_at)
    |> repo.update()
  end

  defp apply_audience_operation(
         repo,
         %Audience{} = audience,
         %Command.ApplyAudienceMutation{operation: "archive"},
         published_at
       ) do
    audience
    |> Audience.changeset(%{archived_at: published_at})
    |> Changeset.change(updated_at: published_at)
    |> repo.update()
  end

  defp audience_event_type("archive"), do: "audience.archived"
  defp audience_event_type("delete_attempt"), do: "audience.delete_blocked"
  defp audience_event_type(_operation), do: "audience.updated"

  defp audience_audit_state(%Audience{} = audience) do
    %{
      "key" => audience.key,
      "definition" => audience.definition,
      "archived_at" => audience.archived_at && DateTime.to_iso8601(audience.archived_at)
    }
  end

  defp audience_audit_event_changeset(audit_event, command, event_type, result, opts) do
    metadata =
      AuditEvent.metadata(%{
        before: Map.get(opts, :before, %{}),
        after: Map.get(opts, :after, %{}),
        tenant: Command.GovernanceSupport.tenant_provenance(command),
        context: Map.get(command, :metadata, %{}),
        request_id: correlation_id(command),
        preview_fingerprint: command.preview_fingerprint,
        preview_schema_version: command.preview_schema_version,
        affected_reference_keys: audience_audit_reference_keys(command, opts),
        preview_basis: command.preview_basis,
        blockers: Map.get(opts, :blockers),
        dependency_findings: Map.get(opts, :dependency_findings, []),
        affected_references: Map.get(opts, :preview, %{}) |> Map.get(:affected_references),
        uncertainty: Map.get(opts, :preview, %{}) |> Map.get(:uncertainty),
        sample_evidence: Map.get(opts, :preview, %{}) |> Map.get(:sample_evidence)
      })
      |> Map.merge(Map.new(Map.get(opts, :metadata, %{})))

    AuditEvent.changeset(audit_event, %{
      event_type: event_type,
      resource_type: "audience",
      resource_key: command.audience_key,
      environment_key: Map.get(opts, :environment_key, command.environment_key),
      actor_id: actor_value(command.actor, "id"),
      actor_type: to_string(actor_value(command.actor, "type") || "operator"),
      actor_display: actor_value(command.actor, "display"),
      reason: command.reason,
      result: result,
      metadata: metadata,
      correlation_id: correlation_id(command),
      occurred_at: now()
    })
  end

  defp insert_audience_audit_only_event(command, event_type, result) do
    %AuditEvent{}
    |> audience_audit_event_changeset(command, event_type, result, %{
      blockers: audience_blockers(command, result)
    })
    |> Repo.insert()
    |> case do
      {:ok, audit_event} ->
        {:ok, %{audit_event: AuditEvent.serialize(audit_event)}}

      {:error, %Changeset{} = changeset} ->
        {:error,
         StoreError.invalid_command("audience audit could not be persisted", cause: changeset)}
    end
  end

  defp insert_blocked_audience_event(command, %Rulestead.Error{} = error) do
    event_type =
      if command.operation == "delete_attempt" do
        "audience.delete_blocked"
      else
        "audience.mutation_blocked"
      end

    %AuditEvent{}
    |> audience_audit_event_changeset(command, event_type, :error, %{
      blockers: audience_blockers(command, :error, error),
      metadata: %{"dependency_findings" => serialize_dependency_findings(error.details)}
    })
    |> Repo.insert()
  end

  defp audience_audit_reference_keys(command, opts) do
    case Map.fetch(opts, :preview) do
      {:ok, preview} -> preview_reference_keys(preview)
      :error -> command.affected_reference_keys
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

  defp audience_blockers(command, :denied),
    do: [%{"code" => "audience_mutation_denied", "operation" => command.operation}]

  defp audience_blockers(command, _result),
    do: [%{"code" => "audience_mutation_#{command.operation}_blocked"}]

  defp audience_blockers(_command, :error, %Rulestead.Error{details: details, message: message})
       when is_list(details) do
    dependency_codes =
      details
      |> Enum.map(fn detail -> Map.get(detail, :code) || Map.get(detail, "code") end)
      |> Enum.reject(&is_nil/1)

    if dependency_codes == [] do
      [%{"code" => audience_blocker_code(message)}]
    else
      serialize_dependency_findings(details)
    end
  end

  defp audience_blockers(_command, :error, %Rulestead.Error{message: message}) do
    [%{"code" => audience_blocker_code(message)}]
  end

  defp audience_blocker_code(message) when is_binary(message) do
    cond do
      String.contains?(message, "stale") ->
        "audience_preview_stale"

      String.contains?(message, "not found") ->
        "audience_missing"

      String.contains?(message, "archived") ->
        "audience_archived"

      String.contains?(message, "protected shared targeting") ->
        "protected_shared_targeting_requires_confirmation"

      String.contains?(message, "audience_delete_unsupported") ->
        "audience_delete_unsupported"

      String.contains?(message, "schema") ->
        "audience_preview_schema_incompatible"

      true ->
        "audience_mutation_blocked"
    end
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
      salt: rollout.salt,
      guardrails: Enum.map(rollout.guardrails || [], &serialize_guardrail/1)
    }
  end

  defp serialize_guardrail(guardrail) when is_map(guardrail) do
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

  defp maybe_filter_change_request(query, _field, nil), do: query

  defp maybe_filter_change_request(query, field_name, value) do
    where(query, [cr], field(cr, ^field_name) == ^value)
  end

  defp normalize_change_request_filter(nil), do: nil
  defp normalize_change_request_filter(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_change_request_filter(value) when is_binary(value), do: String.trim(value)
  defp normalize_change_request_filter(_value), do: nil

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
         {:ok, flag, flag_environment} <-
           fetch_flag_environment(audit_event.resource_key, environment.key),
         :ok <- ensure_not_archived(audit_event.resource_key, flag) do
      before_state = audit_state(flag_environment)

      Multi.new()
      |> Multi.update(
        :flag_environment,
        FlagEnvironment.changeset(flag_environment, inverse_status)
      )
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
          {:error,
           store_changeset_error(changeset, audit_event.resource_key, audit_event.environment_key)}

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
        actor_id: actor_value(command.actor, "id"),
        actor_type: actor_value(command.actor, "type"),
        actor_display: actor_value(command.actor, "display"),
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
      |> Map.take([
        :source,
        "source",
        :request_id,
        "request_id",
        :change_request_id,
        "change_request_id",
        :governance_action,
        "governance_action",
        :execution_stage,
        "execution_stage"
      ])

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
    metadata =
      AuditEvent.metadata(%{
        before: Map.get(opts, :before, %{}),
        after: Map.get(opts, :after, %{}),
        diff: diff_map(Map.get(opts, :before, %{}), Map.get(opts, :after, %{})),
        links: Map.get(opts, :links, %{}),
        tenant: Command.GovernanceSupport.tenant_provenance(command),
        context: Map.get(command, :metadata, %{}),
        request_id: correlation_id(command),
        source: command.metadata[:source] || command.metadata["source"],
        rollback_of_event_id: Map.get(opts, :rollback_of_event_id)
      })
      |> Map.merge(Map.new(Map.get(opts, :metadata, %{})))

    AuditEvent.changeset(audit_event, %{
      event_type: event_type,
      resource_type: "flag",
      resource_key: to_string(Map.get(opts, :resource_key, Map.get(command, :flag_key))),
      environment_key:
        to_string(Map.get(opts, :environment_key, Map.get(command, :environment_key))),
      actor_id: actor_value(command.actor, "id"),
      actor_type: to_string(actor_value(command.actor, "type") || "operator"),
      actor_display: actor_value(command.actor, "display"),
      reason: Map.get(command, :reason),
      result: result,
      metadata: metadata,
      correlation_id: correlation_id(command),
      occurred_at: now()
    })
  end

  defp insert_change_request(repo, command, correlation_id, submitted_at) do
    attrs = %{
      status: "submitted",
      governed_action: Atom.to_string(command.action),
      environment_key: command.environment_key,
      resource_type: command.resource_type,
      resource_key: command.resource_key,
      submitter_id: actor_value(command.actor, "id"),
      submitter_type: actor_value(command.actor, "type") || "operator",
      submitter_display: actor_value(command.actor, "display"),
      reason: command.reason,
      approval_requirement_snapshot: command.approval_requirement,
      command_snapshot: Command.GovernanceSupport.with_tenant_provenance(command.command),
      metadata: command.metadata,
      correlation_id: correlation_id,
      submitted_at: submitted_at,
      resolved_at: nil,
      executed_at: nil,
      inserted_at: submitted_at,
      updated_at: submitted_at
    }

    case repo.insert_all("change_requests", [attrs],
           returning: [
             :id,
             :status,
             :governed_action,
             :environment_key,
             :resource_type,
             :resource_key,
             :submitter_id,
             :submitter_type,
             :submitter_display,
             :reason,
             :approval_requirement_snapshot,
             :command_snapshot,
             :metadata,
             :correlation_id,
             :submitted_at,
             :resolved_at,
             :executed_at,
             :inserted_at,
             :updated_at
           ]
         ) do
      {1, [row]} -> {:ok, normalize_governance_row(row)}
      _ -> {:error, StoreError.unavailable()}
    end
  end

  defp insert_approval(repo, change_request, command, decision, reviewed_at) do
    attrs = %{
      change_request_id: uuid_param(change_request.id),
      decision: decision,
      reviewer_id: actor_value(command.actor, "id"),
      reviewer_type: actor_value(command.actor, "type") || "operator",
      reviewer_display: actor_value(command.actor, "display"),
      reason: command.reason,
      metadata: command.metadata,
      correlation_id: change_request.correlation_id,
      reviewed_at: reviewed_at,
      inserted_at: reviewed_at
    }

    case repo.insert_all("approvals", [attrs],
           returning: [
             :id,
             :change_request_id,
             :decision,
             :reviewer_id,
             :reviewer_type,
             :reviewer_display,
             :reason,
             :metadata,
             :correlation_id,
             :reviewed_at,
             :inserted_at
           ]
         ) do
      {1, [row]} -> {:ok, normalize_governance_row(row)}
      _ -> {:error, StoreError.unavailable()}
    end
  rescue
    error in [ConstraintError] ->
      {:error,
       StoreError.invalid_command("reviewer has already recorded a decision", cause: error)}
  end

  defp update_change_request(repo, change_request, attrs) do
    updates =
      attrs
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    query = from(cr in "change_requests", where: field(cr, :id) == ^uuid_param(change_request.id))

    case repo.update_all(query, set: Enum.to_list(updates)) do
      {1, _rows} -> fetch_change_request_row(change_request.id)
      _ -> {:error, StoreError.invalid_command("change request was not found")}
    end
  end

  defp fetch_change_request_row(change_request_id) do
    case from(cr in "change_requests",
           where: field(cr, :id) == ^uuid_param(change_request_id),
           select:
             map(cr, [
               :id,
               :status,
               :governed_action,
               :environment_key,
               :resource_type,
               :resource_key,
               :submitter_id,
               :submitter_type,
               :submitter_display,
               :reason,
               :approval_requirement_snapshot,
               :command_snapshot,
               :metadata,
               :correlation_id,
               :submitted_at,
               :resolved_at,
               :executed_at,
               :inserted_at,
               :updated_at
             ])
         )
         |> Repo.one() do
      nil -> {:error, StoreError.invalid_command("change request was not found")}
      row -> {:ok, normalize_governance_row(row)}
    end
  end

  defp list_approval_rows(change_request_id) do
    from(a in "approvals",
      where: field(a, :change_request_id) == ^uuid_param(change_request_id),
      order_by: [asc: field(a, :reviewed_at)],
      select:
        map(a, [
          :id,
          :change_request_id,
          :decision,
          :reviewer_id,
          :reviewer_type,
          :reviewer_display,
          :reason,
          :metadata,
          :correlation_id,
          :reviewed_at,
          :inserted_at
        ])
    )
    |> Repo.all()
    |> Enum.map(&normalize_governance_row/1)
  end

  defp list_change_request_audit_events(change_request) do
    AuditEvent
    |> where([event], event.correlation_id == ^change_request.correlation_id)
    |> order_by([event], asc: event.occurred_at, asc: event.inserted_at)
    |> Repo.all()
    |> Enum.map(&AuditEvent.serialize/1)
  end

  defp approved_count(repo, change_request_id) do
    from(a in "approvals",
      where:
        field(a, :change_request_id) == ^uuid_param(change_request_id) and
          field(a, :decision) == "approved",
      select: count("*")
    )
    |> repo.one()
  end

  defp ensure_governance_transition(change_request, allowed_statuses) do
    if change_request.status in allowed_statuses do
      :ok
    else
      {:error,
       StoreError.invalid_command("change request is not in a valid state for this operation")}
    end
  end

  defp ensure_unique_reviewer(change_request_id, command) do
    reviewer_id = actor_value(command.actor, "id")

    exists? =
      from(a in "approvals",
        where:
          field(a, :change_request_id) == ^uuid_param(change_request_id) and
            field(a, :reviewer_id) == ^reviewer_id,
        select: count("*")
      )
      |> Repo.one()

    if exists? > 0 do
      {:error, StoreError.invalid_command("reviewer has already recorded a decision")}
    else
      :ok
    end
  end

  defp required_approvals(snapshot) do
    snapshot["required_approvals"] || snapshot[:required_approvals] || 0
  end

  defp serialize_change_request_row(change_request) do
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

  defp serialize_approval_row(approval) do
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

  defp governance_decision("approved"), do: :approved
  defp governance_decision(_decision), do: :rejected

  defp governance_action(action) when is_binary(action) do
    action
    |> String.trim()
    |> String.to_existing_atom()
  rescue
    ArgumentError -> :manage_settings
  end

  defp governance_correlation_id(command) do
    command.metadata[:request_id] || command.metadata["request_id"] || Ecto.UUID.generate()
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

    Map.merge(command, %{metadata: metadata, actor: command.actor, reason: command.reason})
  end

  defp execute_governed_change(%{governed_action: governed_action} = change_request, command)
       when governed_action in [
              "publish_ruleset",
              "advance_rollout",
              "engage_kill_switch",
              "release_kill_switch",
              "promote_environment"
            ] do
    execute_bounded_governed_action(governed_action, change_request, command)
  end

  defp execute_governed_change(_change_request, _command) do
    {:error, StoreError.invalid_command("governed action is not implemented")}
  end

  defp insert_scheduled_execution(attrs, command) do
    Multi.new()
    |> Multi.run(:scheduled_execution, fn repo, _changes ->
      case repo.insert_all("scheduled_executions", [attrs],
             returning: scheduled_execution_fields()
           ) do
        {1, [row]} -> {:ok, normalize_scheduled_execution_row(row)}
        _ -> {:error, StoreError.unavailable()}
      end
    end)
    |> Multi.run(:oban_job, fn repo, %{scheduled_execution: scheduled_execution} ->
      enqueue_scheduled_execution_job(
        repo,
        scheduled_execution,
        command.actor,
        scheduled_execution.scheduled_for
      )
    end)
    |> Multi.run(:persist_job_id, fn repo,
                                     %{
                                       scheduled_execution: scheduled_execution,
                                       oban_job: oban_job
                                     } ->
      repo.update_all(
        from(se in "scheduled_executions",
          where: field(se, :id) == ^uuid_param(scheduled_execution.id)
        ),
        set: [last_oban_job_id: oban_job.id, updated_at: now()]
      )

      fetch_scheduled_execution_row(scheduled_execution.id)
    end)
    |> Multi.run(:audit_event, fn repo, %{persist_job_id: scheduled_execution} ->
      insert_scheduled_execution_audit_event(
        repo,
        scheduled_execution,
        command,
        "scheduled_execution.scheduled",
        :ok
      )
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{persist_job_id: scheduled_execution, audit_event: audit_event}} ->
        emit_scheduled_execution_telemetry(:scheduled, command, scheduled_execution, audit_event)

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution_row(scheduled_execution),
           attempts: []
         }}

      {:error, _operation, reason, _changes} ->
        {:error, normalize_governance_failure(reason)}
    end
  end

  defp enqueue_scheduled_execution_job(repo, scheduled_execution, actor, scheduled_at) do
    existing_job_id =
      from(job in "oban_jobs",
        where:
          fragment("?->>'scheduled_execution_id' = ?", field(job, :args), ^scheduled_execution.id) and
            field(job, :state) in ["scheduled", "available", "executing", "retryable"],
        select: field(job, :id),
        limit: 1
      )
      |> repo.one()

    case existing_job_id do
      nil ->
        job =
          scheduled_execution
          |> ScheduledExecution.new()
          |> Map.put(:scheduled_for, scheduled_at)
          |> Oban.scheduled_execution_job(
            Context.new(
              actor: Map.new(actor || %{}),
              environment: scheduled_execution.environment_key,
              request_id: scheduled_execution.correlation_id,
              attributes: %{"source" => "scheduled_execution_worker"}
            )
          )

        case repo.insert_all("oban_jobs", [job],
               returning: [:id, :worker, :args, :scheduled_at, :state]
             ) do
          {1, [row]} -> {:ok, Map.new(row)}
          _ -> {:error, StoreError.unavailable()}
        end

      job_id ->
        {:ok, %{id: job_id}}
    end
  end

  defp run_scheduled_execution(command, scheduled_execution) do
    attempt_number = scheduled_execution.attempt_count + 1
    started_at = now()

    with {:ok, attempt} <-
           insert_execution_attempt_row(
             scheduled_execution.id,
             attempt_number,
             "running",
             started_at,
             nil,
             command.metadata
           ) do
      case perform_scheduled_execution(scheduled_execution, command) do
        {:ok, execution_result} ->
          finalize_scheduled_execution_success(
            scheduled_execution,
            attempt,
            command,
            execution_result
          )

        {:error, reason} ->
          finalize_scheduled_execution_failure(scheduled_execution, attempt, command, reason)
      end
    end
  end

  defp perform_scheduled_execution(
         %{change_request_id: change_request_id} = _scheduled_execution,
         command
       )
       when is_binary(change_request_id) do
    with {:ok, change_request} <- fetch_change_request_row(change_request_id),
         {:ok, execution_result, _updated_change_request, _audit_event} <-
           execute_governed_change(change_request, command) do
      {:ok, execution_result}
    end
  end

  defp perform_scheduled_execution(
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
    execute_direct_scheduled_action(governed_action, scheduled_execution, command)
  end

  defp perform_scheduled_execution(_scheduled_execution, _command) do
    {:error, StoreError.invalid_command("governed action is not implemented")}
  end

  defp execute_bounded_governed_action("publish_ruleset", change_request, command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             change_request.resource_key,
             change_request.environment_key
           ),
         {:ok, _ruleset} <-
           ensure_publishable_ruleset(
             flag_environment,
             change_request.environment_key,
             change_request.command_snapshot["version"]
           ),
         {:ok, execution_result} <-
           publish_ruleset(
             Command.PublishRuleset.new(
               change_request.resource_key,
               change_request.environment_key,
               version: change_request.command_snapshot["version"],
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
           ) do
      persisted_change_request =
        case fetch_change_request_row(change_request.id) do
          {:ok, current_change_request} -> current_change_request
          {:error, _error} -> change_request
        end

      {:ok, execution_result, persisted_change_request, nil}
    end
  end

  defp execute_bounded_governed_action("engage_kill_switch", change_request, command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             change_request.resource_key,
             change_request.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :engage),
         {:ok, execution_result} <-
           engage_kill_switch(
             Command.EngageKillSwitch.new(
               change_request.resource_key,
               change_request.environment_key,
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
           ) do
      {:ok, execution_result, change_request, nil}
    end
  end

  defp execute_bounded_governed_action("release_kill_switch", change_request, command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             change_request.resource_key,
             change_request.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :release),
         {:ok, execution_result} <-
           release_kill_switch(
             Command.ReleaseKillSwitch.new(
               change_request.resource_key,
               change_request.environment_key,
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
           ) do
      {:ok, execution_result, change_request, nil}
    end
  end

  defp execute_bounded_governed_action("advance_rollout", change_request, command) do
    advance_rollout(
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
          tenant: change_request.command_snapshot["tenant"],
          signal_facts: change_request.command_snapshot["signal_facts"]
        }
      )
    )
  end

  defp execute_bounded_governed_action("promote_environment", change_request, command) do
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
         {:ok, execution_result} <-
           run_promotion_apply(promotion_command, allow_protected_target?: true) do
      persisted_change_request =
        case fetch_change_request_row(change_request.id) do
          {:ok, current_change_request} -> current_change_request
          {:error, _error} -> change_request
        end

      {:ok, execution_result, persisted_change_request, nil}
    end
  end

  defp execute_direct_scheduled_action("publish_ruleset", scheduled_execution, command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             scheduled_execution.resource_key,
             scheduled_execution.environment_key
           ),
         {:ok, _ruleset} <-
           ensure_publishable_ruleset(
             flag_environment,
             scheduled_execution.environment_key,
             scheduled_execution.command_snapshot["version"]
           ) do
      publish_ruleset(
        Command.PublishRuleset.new(
          scheduled_execution.resource_key,
          scheduled_execution.environment_key,
          version: scheduled_execution.command_snapshot["version"],
          actor: command.actor,
          reason: command.reason,
          metadata: %{
            request_id: scheduled_execution.correlation_id,
            source: scheduled_execution.metadata["source"],
            scheduled_execution_id: scheduled_execution.id,
            execution_stage: "scheduled_execution"
          }
        )
      )
    end
  end

  defp execute_direct_scheduled_action("engage_kill_switch", scheduled_execution, command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             scheduled_execution.resource_key,
             scheduled_execution.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :engage) do
      engage_kill_switch(
        Command.EngageKillSwitch.new(
          scheduled_execution.resource_key,
          scheduled_execution.environment_key,
          actor: command.actor,
          reason: command.reason,
          metadata: %{
            request_id: scheduled_execution.correlation_id,
            source: scheduled_execution.metadata["source"],
            scheduled_execution_id: scheduled_execution.id,
            execution_stage: "scheduled_execution"
          }
        )
      )
    end
  end

  defp execute_direct_scheduled_action("release_kill_switch", scheduled_execution, command) do
    with {:ok, _environment, _flag, flag_environment} <-
           fetch_schedulable_flag_context(
             scheduled_execution.resource_key,
             scheduled_execution.environment_key
           ),
         :ok <- ensure_kill_switch_transition(flag_environment, :release) do
      release_kill_switch(
        Command.ReleaseKillSwitch.new(
          scheduled_execution.resource_key,
          scheduled_execution.environment_key,
          actor: command.actor,
          reason: command.reason,
          metadata: %{
            request_id: scheduled_execution.correlation_id,
            source: scheduled_execution.metadata["source"],
            scheduled_execution_id: scheduled_execution.id,
            execution_stage: "scheduled_execution"
          }
        )
      )
    end
  end

  defp execute_direct_scheduled_action("advance_rollout", scheduled_execution, command) do
    advance_rollout(
      Command.AdvanceRollout.new(
        scheduled_execution.resource_key,
        scheduled_execution.environment_key,
        Map.merge(
          scheduled_execution.command_snapshot["rollout"] || scheduled_execution.command_snapshot,
          %{"signal_facts" => scheduled_execution.command_snapshot["signal_facts"]}
        ),
        actor: command.actor,
        reason: command.reason,
        metadata: %{
          request_id: scheduled_execution.correlation_id,
          source: scheduled_execution.metadata["source"],
          scheduled_execution_id: scheduled_execution.id,
          execution_stage: "scheduled_execution",
          tenant: scheduled_execution.command_snapshot["tenant"],
          signal_facts: scheduled_execution.command_snapshot["signal_facts"]
        }
      )
    )
  end

  defp execute_direct_scheduled_action("promote_environment", scheduled_execution, command) do
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

    with :ok <- Apply.validate_governed(promotion_command),
         {:ok, execution_result} <-
           run_promotion_apply(promotion_command, allow_protected_target?: true) do
      {:ok, execution_result}
    end
  end

  defp promotion_execution_metadata(metadata, request_id, source, links) do
    metadata
    |> Map.merge(%{
      request_id: request_id,
      source: source,
      governance_action: "promote_environment"
    })
    |> Map.merge(Map.new(links))
  end

  defp fetch_schedulable_flag_context(resource_key, environment_key) do
    with {:ok, environment} <- fetch_environment(environment_key),
         {:ok, flag, flag_environment} <- fetch_flag_environment(resource_key, environment.key),
         :ok <- ensure_schedulable_flag_not_archived(flag) do
      {:ok, environment, flag, flag_environment}
    end
  end

  defp ensure_schedulable_flag_not_archived(%{archived_at: nil}), do: :ok

  defp ensure_schedulable_flag_not_archived(_flag),
    do: {:error, StoreError.invalid_command("archived_resource")}

  defp ensure_publishable_ruleset(flag_environment, environment_key, version) do
    case resolve_publishable_ruleset(flag_environment, environment_key, version) do
      {:ok, ruleset} -> {:ok, ruleset}
      {:error, _error} -> {:error, StoreError.invalid_command("ruleset_not_publishable")}
    end
  end

  defp ensure_kill_switch_transition(flag_environment, :engage) do
    if flag_environment.status == :killswitched or
         not is_nil(flag_environment.kill_switch_variant_key) do
      {:error, StoreError.invalid_command("kill_switch_already_engaged")}
    else
      :ok
    end
  end

  defp ensure_kill_switch_transition(flag_environment, :release) do
    if flag_environment.status == :killswitched or
         not is_nil(flag_environment.kill_switch_variant_key) do
      :ok
    else
      {:error, StoreError.invalid_command("kill_switch_already_released")}
    end
  end

  defp ensure_active_ruleset(%FlagEnvironment{} = flag_environment, _command) do
    case active_ruleset(flag_environment) do
      %Ruleset{} = ruleset -> {:ok, ruleset}
      nil -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
    end
  end

  defp resolve_rollout_rule(%Ruleset{} = ruleset, nil) do
    rollout_rules = Enum.filter(ruleset.rules, &match?(%{rollout: %_{}}, &1))

    case rollout_rules do
      [rule] -> {:ok, rule}
      _other -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
    end
  end

  defp resolve_rollout_rule(%Ruleset{} = ruleset, rule_key) do
    case Enum.find(ruleset.rules, &(&1.key == rule_key and not is_nil(&1.rollout))) do
      nil -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
      rule -> {:ok, rule}
    end
  end

  defp ensure_rollout_percentage(nil),
    do: {:error, StoreError.invalid_command("rollout_stage_conflict")}

  defp ensure_rollout_percentage(percentage)
       when is_integer(percentage) and percentage >= 0 and percentage <= 100,
       do: {:ok, percentage}

  defp ensure_rollout_percentage(_percentage),
    do: {:error, StoreError.invalid_command("rollout_stage_conflict")}

  defp advanced_ruleset_attrs(%Ruleset{} = ruleset, rule_key, percentage) do
    rules =
      Enum.map(ruleset.rules, fn rule ->
        if rule.key == rule_key and rule.rollout do
          Map.put(rule, :rollout, %{rule.rollout | percentage: percentage})
        else
          rule
        end
      end)
      |> Enum.map(&serialize_rule/1)

    {:ok, %{salt: ruleset.salt, metadata: ruleset.metadata, rules: rules}}
  end

  defp advance_decision_attrs(command, ruleset, rollout_rule, occurred_at) do
    %{
      flag_key: command.flag_key,
      environment_key: command.environment_key,
      rule_key: rollout_rule.key,
      stage: command.stage,
      tenant_key:
        command.metadata["tenant_key"] || get_in(command.metadata, ["tenant", "tenant_key"]),
      decision_state: :pending_data,
      action_type: :advance,
      decision_reason: "monitoring_window_active",
      effective_percentage: command.percentage,
      rollout_salt: rollout_rule.rollout.salt,
      variant_fingerprint: variant_fingerprint(rollout_rule),
      monitoring_window_started_at: command.monitoring_window_started_at || occurred_at,
      monitoring_window_ends_at: command.monitoring_window_ends_at,
      occurred_at: occurred_at,
      signal_facts: Enum.map(command.signal_facts, &SignalFact.metadata/1),
      guardrail_evidence: first_guardrail_evidence(command.signal_facts),
      authored_snapshot: serialize_ruleset(ruleset),
      correlation_id: correlation_id(command),
      metadata: command.metadata
    }
  end

  defp execute_guardrail_decision(
         command,
         environment,
         flag,
         flag_environment,
         active_ruleset,
         rollout_rule,
         evaluated
       ) do
    stable_target =
      if evaluated.state == :rollback_triggered do
        latest_stable_guardrail_snapshot(
          command.flag_key,
          environment.key,
          rollout_rule.key,
          rollout_rule.rollout.salt,
          variant_fingerprint(rollout_rule),
          correlation_id(command)
        )
      end

    case evaluated.state do
      :rollback_triggered when is_nil(stable_target) ->
        persist_guardrail_decision_without_mutation(
          command,
          environment,
          flag_environment,
          active_ruleset,
          rollout_rule,
          %{evaluated | state: :held, reason: "stable_target_missing"},
          :hold,
          "rollout.guardrail_held"
        )

      :rollback_triggered ->
        rollback_from_stable_snapshot(
          command,
          environment,
          flag,
          flag_environment,
          active_ruleset,
          rollout_rule,
          evaluated,
          stable_target
        )

      :held ->
        persist_guardrail_decision_without_mutation(
          command,
          environment,
          flag_environment,
          active_ruleset,
          rollout_rule,
          evaluated,
          :hold,
          "rollout.guardrail_held"
        )

      _other ->
        persist_guardrail_decision_without_mutation(
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

  defp persist_guardrail_decision_without_mutation(
         command,
         environment,
         flag_environment,
         active_ruleset,
         rollout_rule,
         evaluated,
         action_type,
         event_type
       ) do
    occurred_at = evaluated.evaluated_at |> DateTime.truncate(:microsecond)

    authored_snapshot =
      if evaluated.state == :healthy and evaluated.monitoring_window_closed? do
        serialize_ruleset(active_ruleset)
      end

    Multi.new()
    |> Multi.insert(
      :decision,
      GuardrailDecision.changeset(%GuardrailDecision{}, %{
        flag_key: command.flag_key,
        environment_key: environment.key,
        rule_key: rollout_rule.key,
        stage: command.stage,
        tenant_key:
          command.metadata["tenant_key"] || get_in(command.metadata, ["tenant", "tenant_key"]),
        decision_state: evaluated.state,
        action_type: action_type,
        decision_reason: evaluated.reason,
        effective_percentage: rollout_rule.rollout.percentage,
        rollout_salt: rollout_rule.rollout.salt,
        variant_fingerprint: variant_fingerprint(rollout_rule),
        monitoring_window_started_at: command.monitoring_window_started_at,
        monitoring_window_ends_at: command.monitoring_window_ends_at,
        occurred_at: occurred_at,
        signal_facts: Enum.map(evaluated.signal_facts, &SignalFact.metadata/1),
        guardrail_evidence: first_guardrail_evidence(evaluated.signal_facts),
        authored_snapshot: authored_snapshot,
        correlation_id: correlation_id(command),
        metadata: command.metadata
      })
    )
    |> Multi.run(:audit_event, fn repo, %{decision: decision} ->
      repo.insert(
        audit_event_changeset(%AuditEvent{}, command, event_type, :ok, %{
          environment_key: environment.key,
          links: %{"guardrail_decision_id" => decision.id},
          guardrail: first_guardrail_evidence(evaluated.signal_facts)
        })
      )
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{decision: decision}} ->
        {:ok, guardrail_status_payload(decision, active_ruleset_version(flag_environment))}

      {:error, :decision, %Changeset{} = changeset, _changes} ->
        {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

      {:error, _operation, reason, _changes} ->
        {:error, StoreError.unavailable(cause: reason)}
    end
  end

  defp rollback_from_stable_snapshot(
         command,
         environment,
         flag,
         flag_environment,
         active_ruleset,
         rollout_rule,
         evaluated,
         stable_target
       ) do
    published_at = now()
    snapshot = stable_target.authored_snapshot || %{}

    Multi.new()
    |> Multi.insert(
      :ruleset,
      Ruleset.changeset(%Ruleset{}, %{
        flag_environment_id: flag_environment.id,
        version: next_ruleset_version(flag_environment.id),
        status: :published,
        salt: snapshot["salt"] || snapshot[:salt] || active_ruleset.salt,
        published_at: published_at,
        metadata: snapshot["metadata"] || snapshot[:metadata] || %{},
        rules: snapshot["rules"] || snapshot[:rules] || []
      })
    )
    |> Multi.run(:flag_environment, fn repo, %{ruleset: ruleset} ->
      flag_environment
      |> FlagEnvironment.changeset(%{
        active_ruleset_id: ruleset.id,
        status: :active,
        last_published_at: published_at
      })
      |> repo.update()
    end)
    |> Multi.update(:flag, Changeset.change(flag, updated_at: published_at))
    |> Multi.run(:runtime_snapshot, fn repo, _changes ->
      insert_runtime_snapshot(repo, environment, published_at)
    end)
    |> Multi.insert(
      :decision,
      GuardrailDecision.changeset(%GuardrailDecision{}, %{
        flag_key: command.flag_key,
        environment_key: environment.key,
        rule_key: rollout_rule.key,
        stage: command.stage,
        tenant_key:
          command.metadata["tenant_key"] || get_in(command.metadata, ["tenant", "tenant_key"]),
        decision_state: :rollback_triggered,
        action_type: :rollback,
        decision_reason: evaluated.reason,
        effective_percentage: rollout_rule.rollout.percentage,
        rollout_salt: rollout_rule.rollout.salt,
        variant_fingerprint: variant_fingerprint(rollout_rule),
        monitoring_window_started_at: command.monitoring_window_started_at,
        monitoring_window_ends_at: command.monitoring_window_ends_at,
        occurred_at: published_at,
        signal_facts: Enum.map(evaluated.signal_facts, &SignalFact.metadata/1),
        guardrail_evidence: first_guardrail_evidence(evaluated.signal_facts),
        authored_snapshot: serialize_ruleset(active_ruleset),
        rollback_target_snapshot: stable_target.authored_snapshot,
        correlation_id: correlation_id(command),
        metadata: command.metadata
      })
    )
    |> Multi.run(:audit_event, fn repo, %{decision: decision, ruleset: ruleset} ->
      repo.insert(
        audit_event_changeset(%AuditEvent{}, command, "rollout.guardrail_rollback", :ok, %{
          environment_key: environment.key,
          before: ruleset_audit_state(active_ruleset),
          after: ruleset_audit_state(ruleset),
          diff: ruleset_position_diff(active_ruleset, ruleset),
          links: %{
            "guardrail_decision_id" => decision.id,
            "stable_guardrail_decision_id" => stable_target.id
          },
          guardrail: first_guardrail_evidence(evaluated.signal_facts)
        })
      )
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{decision: decision, ruleset: ruleset}} ->
        {:ok, guardrail_status_payload(decision, ruleset.version)}

      {:error, :ruleset, %Changeset{} = changeset, _changes} ->
        {:error, ruleset_error(changeset, command.flag_key, command.environment_key)}

      {:error, :flag_environment, %Changeset{} = changeset, _changes} ->
        {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

      {:error, :decision, %Changeset{} = changeset, _changes} ->
        {:error, store_changeset_error(changeset, command.flag_key, command.environment_key)}

      {:error, _operation, reason, _changes} ->
        {:error, StoreError.unavailable(cause: reason)}
    end
  end

  defp latest_guardrail_decision(%Command.FetchGuardrailStatus{} = command) do
    GuardrailDecision
    |> where(
      [decision],
      decision.flag_key == ^to_string(command.flag_key) and
        decision.environment_key == ^to_string(command.environment_key)
    )
    |> maybe_filter_guardrail_decision_rule(command.rule_key)
    |> maybe_filter_guardrail_decision_stage(command.stage)
    |> order_by([decision], desc: decision.occurred_at, desc: decision.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp latest_stable_guardrail_snapshot(
         flag_key,
         environment_key,
         rule_key,
         rollout_salt,
         variant_fingerprint,
         correlation_id
       ) do
    GuardrailDecision
    |> where(
      [decision],
      decision.flag_key == ^to_string(flag_key) and
        decision.environment_key == ^to_string(environment_key) and
        decision.rule_key == ^to_string(rule_key) and
        decision.decision_state == :healthy and
        decision.rollout_salt == ^rollout_salt and
        decision.variant_fingerprint == ^variant_fingerprint and
        not is_nil(decision.authored_snapshot) and
        decision.correlation_id != ^correlation_id
    )
    |> order_by([decision], desc: decision.occurred_at, desc: decision.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp maybe_filter_guardrail_decision_rule(query, nil), do: query

  defp maybe_filter_guardrail_decision_rule(query, rule_key),
    do: where(query, [decision], decision.rule_key == ^to_string(rule_key))

  defp maybe_filter_guardrail_decision_stage(query, nil), do: query

  defp maybe_filter_guardrail_decision_stage(query, stage),
    do: where(query, [decision], decision.stage == ^to_string(stage))

  defp guardrail_status_payload(%GuardrailDecision{} = decision, active_ruleset_version) do
    %{
      flag_key: decision.flag_key,
      environment_key: decision.environment_key,
      rule_key: decision.rule_key,
      stage: decision.stage,
      active_ruleset_version: active_ruleset_version,
      decision: GuardrailDecision.serialize(decision)
    }
  end

  defp first_guardrail_evidence([]), do: %{}
  defp first_guardrail_evidence([fact | _rest]), do: SignalFact.metadata(fact)

  defp variant_fingerprint(rule) do
    rule.variants
    |> Enum.map(fn variant ->
      %{
        key: variant.key,
        weight: variant.weight,
        value: variant.value
      }
    end)
    |> Jason.encode!()
  end

  defp finalize_scheduled_execution_success(
         scheduled_execution,
         attempt,
         command,
         execution_result
       ) do
    finished_at = now()

    Multi.new()
    |> Multi.run(:attempt, fn repo, _changes ->
      update_execution_attempt_row(
        repo,
        attempt.id,
        "completed",
        finished_at,
        nil,
        command.metadata
      )
    end)
    |> Multi.run(:scheduled_execution, fn repo, _changes ->
      repo.update_all(
        from(se in "scheduled_executions",
          where: field(se, :id) == ^uuid_param(scheduled_execution.id)
        ),
        set: [
          state: "completed",
          attempt_count: scheduled_execution.attempt_count + 1,
          executed_at: finished_at,
          failure_reason: nil,
          execution_metadata:
            scheduled_transition_metadata(
              scheduled_execution.execution_metadata,
              "completed",
              command
            ),
          updated_at: finished_at
        ]
      )

      fetch_scheduled_execution_row(scheduled_execution.id)
    end)
    |> Multi.run(:audit_event, fn repo, %{scheduled_execution: updated} ->
      insert_scheduled_execution_audit_event(
        repo,
        updated,
        command,
        "scheduled_execution.succeeded",
        :ok
      )
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{scheduled_execution: updated, audit_event: audit_event}} ->
        if lifecycle_telemetry_enabled?(command) do
          emit_scheduled_execution_telemetry(:succeeded, command, updated, audit_event)
        end

        {:ok,
         %{
           scheduled_execution: serialize_scheduled_execution_row(updated),
           execution_result: execution_result,
           attempts:
             list_execution_attempt_rows(updated.id)
             |> Enum.map(&serialize_execution_attempt_row/1)
         }}

      {:error, _operation, reason, _changes} ->
        {:error, normalize_governance_failure(reason)}
    end
  end

  defp finalize_scheduled_execution_failure(
         scheduled_execution,
         attempt,
         command,
         %Rulestead.Error{} = error
       ) do
    finalize_scheduled_execution_failure(scheduled_execution, attempt, command, error.message)
  end

  defp finalize_scheduled_execution_failure(scheduled_execution, attempt, command, reason) do
    finished_at = now()
    failure_reason = normalize_failure_reason(reason)
    next_attempt_count = scheduled_execution.attempt_count + 1

    next_state =
      if next_attempt_count >= @scheduled_execution_retry_limit,
        do: "quarantined",
        else: "scheduled"

    attempt_state = if next_state == "quarantined", do: "quarantined", else: "failed"

    event_type =
      if next_state == "quarantined",
        do: "scheduled_execution.quarantined",
        else: "scheduled_execution.failed"

    telemetry_event = if next_state == "quarantined", do: :quarantined, else: :failed

    Multi.new()
    |> Multi.run(:attempt, fn repo, _changes ->
      update_execution_attempt_row(
        repo,
        attempt.id,
        attempt_state,
        finished_at,
        failure_reason,
        command.metadata
      )
    end)
    |> Multi.run(:scheduled_execution, fn repo, _changes ->
      repo.update_all(
        from(se in "scheduled_executions",
          where: field(se, :id) == ^uuid_param(scheduled_execution.id)
        ),
        set: [
          state: next_state,
          attempt_count: next_attempt_count,
          failure_reason: failure_reason,
          execution_metadata:
            scheduled_transition_metadata(
              scheduled_execution.execution_metadata,
              next_state,
              command
            ),
          updated_at: finished_at
        ]
      )

      fetch_scheduled_execution_row(scheduled_execution.id)
    end)
    |> Multi.run(:audit_event, fn repo, %{scheduled_execution: updated} ->
      insert_scheduled_execution_audit_event(repo, updated, command, event_type, :error)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{scheduled_execution: updated, audit_event: audit_event}} ->
        if lifecycle_telemetry_enabled?(command) do
          emit_scheduled_execution_telemetry(telemetry_event, command, updated, audit_event)
        end

        {:error, StoreError.invalid_command(failure_reason)}

      {:error, _operation, txn_reason, _changes} ->
        {:error, normalize_governance_failure(txn_reason)}
    end
  end

  defp insert_execution_attempt_row(
         scheduled_execution_id,
         attempt_number,
         state,
         started_at,
         failure_reason,
         metadata
       ) do
    attrs = %{
      scheduled_execution_id: uuid_param(scheduled_execution_id),
      attempt_number: attempt_number,
      state: state,
      started_at: started_at,
      finished_at: nil,
      failure_reason: failure_reason,
      metadata: metadata,
      inserted_at: started_at
    }

    case Repo.insert_all("execution_attempts", [attrs], returning: execution_attempt_fields()) do
      {1, [row]} -> {:ok, normalize_execution_attempt_row(row)}
      _ -> {:error, StoreError.unavailable()}
    end
  end

  defp update_execution_attempt_row(
         repo,
         attempt_id,
         state,
         finished_at,
         failure_reason,
         metadata
       ) do
    repo.update_all(
      from(attempt in "execution_attempts",
        where: field(attempt, :id) == ^uuid_param(attempt_id)
      ),
      set: [
        state: state,
        finished_at: finished_at,
        failure_reason: failure_reason,
        metadata: metadata
      ]
    )

    case from(attempt in "execution_attempts",
           where: field(attempt, :id) == ^uuid_param(attempt_id),
           select: map(attempt, ^execution_attempt_fields())
         )
         |> repo.one() do
      nil -> {:error, StoreError.invalid_command("execution attempt was not found")}
      row -> {:ok, normalize_execution_attempt_row(row)}
    end
  end

  defp fetch_scheduled_execution_row(scheduled_execution_id) do
    case from(se in "scheduled_executions",
           where: field(se, :id) == ^uuid_param(scheduled_execution_id),
           select: map(se, ^scheduled_execution_fields())
         )
         |> Repo.one() do
      nil -> {:error, StoreError.invalid_command("scheduled execution was not found")}
      row -> {:ok, normalize_scheduled_execution_row(row)}
    end
  end

  defp list_execution_attempt_rows(scheduled_execution_id) do
    from(attempt in "execution_attempts",
      where: field(attempt, :scheduled_execution_id) == ^uuid_param(scheduled_execution_id),
      order_by: [asc: field(attempt, :attempt_number)],
      select: map(attempt, ^execution_attempt_fields())
    )
    |> Repo.all()
    |> Enum.map(&normalize_execution_attempt_row/1)
  end

  defp approved_snapshot(change_request_id) do
    {:ok,
     from(a in "approvals",
       where:
         field(a, :change_request_id) == ^uuid_param(change_request_id) and
           field(a, :decision) == "approved",
       order_by: [asc: field(a, :reviewed_at)],
       select: map(a, [:reviewer_id, :reviewer_type, :reviewer_display])
     )
     |> Repo.all()
     |> Enum.map(fn approval ->
       %{
         "id" => approval.reviewer_id,
         "type" => approval.reviewer_type,
         "display" => approval.reviewer_display
       }
     end)}
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

  defp insert_scheduled_execution_audit_event(
         repo,
         scheduled_execution,
         command,
         event_type,
         result
       ) do
    %AuditEvent{}
    |> scheduled_execution_audit_changeset(scheduled_execution, command, event_type, result)
    |> repo.insert()
  end

  defp scheduled_execution_audit_changeset(
         audit_event,
         scheduled_execution,
         command,
         event_type,
         result
       ) do
    AuditEvent.changeset(audit_event, %{
      event_type: event_type,
      resource_type: scheduled_execution.resource_type || "flag",
      resource_key: scheduled_execution.resource_key,
      environment_key: scheduled_execution.environment_key,
      actor_id: actor_value(command.actor, "id"),
      actor_type: to_string(actor_value(command.actor, "type") || "system"),
      actor_display: actor_value(command.actor, "display"),
      reason: command.reason,
      result: result,
      metadata:
        AuditEvent.metadata(%{
          tenant:
            Command.GovernanceSupport.tenant_provenance(
              command,
              fallback: scheduled_execution.command_snapshot
            ),
          context: scheduled_execution_audit_context(scheduled_execution, command),
          request_id: scheduled_execution.correlation_id,
          source: scheduled_execution_source(scheduled_execution, command),
          change_request_id: scheduled_execution.change_request_id,
          governance_action: scheduled_execution.governed_action,
          execution_stage: scheduled_execution_stage(event_type),
          scheduled_execution_id: scheduled_execution.id,
          attempt_count: scheduled_execution.attempt_count,
          scheduled_for: scheduled_execution.scheduled_for,
          executed_at: scheduled_execution.executed_at,
          failure_reason: scheduled_execution.failure_reason,
          execution_mode: scheduled_execution.execution_mode,
          executed_by: executed_by_value(command.actor),
          scheduled_by: scheduled_by_payload(scheduled_execution),
          approved_by: normalize_array_map(scheduled_execution.approved_by_snapshot)
        }),
      correlation_id: scheduled_execution.correlation_id,
      occurred_at: now()
    })
  end

  defp scheduled_execution_audit_context(scheduled_execution, command) do
    scheduled_execution.metadata
    |> Map.new()
    |> Map.merge(Map.get(command, :metadata, %{}) |> Map.new())
    |> Map.put("scheduled_execution_id", scheduled_execution.id)
    |> Map.put("environment_key", scheduled_execution.environment_key)
    |> Map.put("governed_action", scheduled_execution.governed_action)
    |> Map.put("execution_mode", scheduled_execution.execution_mode)
  end

  defp scheduled_execution_stage("scheduled_execution.scheduled"), do: "scheduled"
  defp scheduled_execution_stage("scheduled_execution.cancelled"), do: "cancelled"
  defp scheduled_execution_stage("scheduled_execution.requeued"), do: "requeued"
  defp scheduled_execution_stage(_event_type), do: "execute"

  defp scheduled_execution_source(scheduled_execution, command) do
    command.metadata[:source] || command.metadata["source"] ||
      scheduled_execution.metadata["source"]
  end

  defp scheduled_by_payload(scheduled_execution) do
    %{
      "id" => scheduled_execution.scheduled_by_id,
      "type" => scheduled_execution.scheduled_by_type,
      "display" => scheduled_execution.scheduled_by_display
    }
  end

  defp executed_by_value(actor) when is_map(actor) do
    case actor_value(actor, "id") do
      "system:scheduler" -> "scheduler"
      "scheduler" -> "scheduler"
      _other -> "scheduler"
    end
  end

  defp executed_by_value(_actor), do: "scheduler"

  defp emit_scheduled_execution_telemetry(
         event,
         command,
         scheduled_execution,
         audit_event,
         extra \\ []
       ) do
    Telemetry.execute(
      Telemetry.scheduled_execution_event(event),
      %{count: 1},
      Telemetry.metadata(
        Telemetry.scheduled_execution_metadata(
          serialize_scheduled_execution_row(scheduled_execution),
          %{
            action: governance_action(scheduled_execution.governed_action),
            environment_key: scheduled_execution.environment_key,
            attempt_count: Keyword.get(extra, :attempt_count, scheduled_execution.attempt_count),
            audit_event_id: audit_event && audit_event.id,
            executed_by: executed_by_value(command.actor),
            event: event
          }
        )
      )
    )
  end

  defp lifecycle_telemetry_enabled?(command) do
    Map.get(
      command.metadata,
      :emit_lifecycle_telemetry,
      Map.get(command.metadata, "emit_lifecycle_telemetry", true)
    ) != false
  end

  defp normalize_governance_failure(%Rulestead.Error{} = error), do: error

  defp normalize_governance_failure(%Changeset{} = changeset),
    do: StoreError.unavailable(cause: changeset)

  defp normalize_governance_failure(other), do: StoreError.unavailable(cause: other)

  defp actor_value(nil, _key), do: nil
  defp actor_value(actor, key), do: Map.get(actor, key) || Map.get(actor, String.to_atom(key))

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

  defp normalize_governance_row(row) when is_map(row) do
    row
    |> maybe_normalize_uuid(:id)
    |> maybe_normalize_uuid(:change_request_id)
  end

  defp normalize_scheduled_execution_row(row) when is_map(row) do
    row
    |> maybe_normalize_uuid(:id)
    |> maybe_normalize_uuid(:change_request_id)
    |> maybe_normalize_datetime(:scheduled_for)
    |> maybe_normalize_datetime(:executed_at)
    |> maybe_normalize_datetime(:inserted_at)
    |> maybe_normalize_datetime(:updated_at)
    |> Map.update(:approved_by_snapshot, [], &normalize_array_map/1)
  end

  defp maybe_normalize_datetime(row, key) do
    case Map.get(row, key) do
      %NaiveDateTime{} = ndt -> Map.put(row, key, DateTime.from_naive!(ndt, "Etc/UTC"))
      _ -> row
    end
  end

  defp normalize_execution_attempt_row(row) when is_map(row) do
    row
    |> maybe_normalize_uuid(:id)
    |> maybe_normalize_uuid(:scheduled_execution_id)
    |> maybe_normalize_datetime(:started_at)
    |> maybe_normalize_datetime(:finished_at)
    |> maybe_normalize_datetime(:inserted_at)
  end

  defp serialize_scheduled_execution_row(row) do
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
      approved_by_snapshot: normalize_array_map(row.approved_by_snapshot),
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

  defp serialize_execution_attempt_row(row) do
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

  defp scheduled_execution_fields do
    [
      :id,
      :state,
      :change_request_id,
      :governed_action,
      :environment_key,
      :resource_type,
      :resource_key,
      :execution_mode,
      :scheduled_by_id,
      :scheduled_by_type,
      :scheduled_by_display,
      :approved_by_snapshot,
      :execution_metadata,
      :scheduled_for,
      :executed_at,
      :attempt_count,
      :failure_reason,
      :last_oban_job_id,
      :command_snapshot,
      :approval_requirement_snapshot,
      :metadata,
      :correlation_id,
      :idempotency_key
    ]
  end

  defp execution_attempt_fields do
    [
      :id,
      :scheduled_execution_id,
      :attempt_number,
      :state,
      :started_at,
      :finished_at,
      :failure_reason,
      :metadata
    ]
  end

  defp scheduled_state("scheduled"), do: :scheduled
  defp scheduled_state("running"), do: :running
  defp scheduled_state("completed"), do: :completed
  defp scheduled_state("failed"), do: :failed
  defp scheduled_state("quarantined"), do: :quarantined
  defp scheduled_state("cancelled"), do: :cancelled
  defp scheduled_state(_state), do: :scheduled

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

  defp maybe_filter_scheduled_execution(query, _field, nil), do: query

  defp maybe_filter_scheduled_execution(query, field_name, value) do
    where(
      query,
      [scheduled_execution],
      field(scheduled_execution, ^field_name) == ^to_string(value)
    )
  end

  defp maybe_filter_scheduled_state(query, nil), do: query

  defp maybe_filter_scheduled_state(query, value),
    do: where(query, [se], field(se, :state) == ^normalize_change_request_filter(value))

  defp maybe_filter_scheduled_action(query, nil), do: query

  defp maybe_filter_scheduled_action(query, value),
    do: where(query, [se], field(se, :governed_action) == ^normalize_change_request_filter(value))

  defp maybe_filter_scheduled_window(query, :after, nil), do: query

  defp maybe_filter_scheduled_window(query, :after, %DateTime{} = value),
    do: where(query, [se], field(se, :scheduled_for) >= ^value)

  defp maybe_filter_scheduled_window(query, :before, nil), do: query

  defp maybe_filter_scheduled_window(query, :before, %DateTime{} = value),
    do: where(query, [se], field(se, :scheduled_for) <= ^value)

  defp scheduled_transition_metadata(existing, state, command) do
    Map.merge(existing || %{}, %{
      "last_transition" => state,
      "last_transition_at" => DateTime.to_iso8601(now()),
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

  defp normalize_array_map(values) when is_list(values), do: Enum.map(values, &Map.new/1)
  defp normalize_array_map(_values), do: []

  defp maybe_normalize_uuid(row, key) do
    case Map.get(row, key) do
      value when is_binary(value) and byte_size(value) == 16 ->
        case Ecto.UUID.load(value) do
          {:ok, uuid} -> Map.put(row, key, uuid)
          :error -> row
        end

      _ ->
        row
    end
  end

  defp uuid_param(value) do
    case Ecto.UUID.dump(value) do
      {:ok, dumped} -> dumped
      :error -> value
    end
  end

  defp diff_map(before_state, after_state) do
    Map.new(after_state, fn {key, value} ->
      before_value = Map.get(before_state, key) || Map.get(before_state, to_string(key))
      {to_string(key), %{"from" => before_value, "to" => value}}
    end)
  end

  defp maybe_filter_audit_flag(query, nil), do: query

  defp maybe_filter_audit_flag(query, flag_key),
    do: where(query, [event], event.resource_key == ^to_string(flag_key))

  defp maybe_filter_audit_environment(query, nil), do: query

  defp maybe_filter_audit_environment(query, environment_key),
    do: where(query, [event], event.environment_key == ^to_string(environment_key))

  defp maybe_filter_audit_actor_id(query, nil), do: query

  defp maybe_filter_audit_actor_id(query, actor_id),
    do: where(query, [event], event.actor_id == ^actor_id)

  defp maybe_filter_audit_mutation(query, nil), do: query

  defp maybe_filter_audit_mutation(query, mutation),
    do: where(query, [event], event.event_type == ^mutation)

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

  defp active_ruleset_version(%FlagEnvironment{active_ruleset: %Ruleset{version: version}}),
    do: version

  defp active_ruleset_version(%FlagEnvironment{}), do: nil

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
      |> normalize_ruleset_position_state()
      |> Map.get(:rules, [])
      |> Map.new(fn %{key: key, position: position} -> {key, position} end)

    %{
      rules:
        after_state
        |> normalize_ruleset_position_state()
        |> Map.get(:rules, [])
        |> Enum.map(fn %{key: key, position: position} ->
          %{key: key, from: Map.get(before_positions, key), to: position}
        end)
    }
  end

  defp normalize_ruleset_position_state(%{rules: rules}) when is_list(rules) do
    case rules do
      [%{key: _key, position: _position} | _rest] ->
        %{rules: rules}

      _other ->
        %{
          rules:
            rules
            |> Enum.with_index()
            |> Enum.map(fn {rule, position} ->
              %{key: Map.get(rule, :key) || Map.get(rule, "key"), position: position}
            end)
        }
    end
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)

  defp decorate_payload(payload, flag, environment, flag_environment, lifecycle_context) do
    environment_cards = environment_cards(flag, lifecycle_context)

    payload
    |> Map.put(:lifecycle, lifecycle(flag, flag_environment, lifecycle_context))
    |> Map.put(:has_draft_ruleset?, payload.draft_rulesets != [])
    |> Map.put(:recent_owners, recent_owners(flag.ownership.owner_ref))
    |> Map.put(:environments, Enum.map(environment_cards, & &1.environment))
    |> Map.put(:environment_cards, environment_cards)
    |> Map.put(:environment_status, flag_environment.status)
    |> Map.put(:environment_key, environment.key)
  end

  defp environment_cards(flag, lifecycle_context) do
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
        lifecycle: lifecycle(flag, flag_environment, lifecycle_context)
      }
    end)
  end

  defp lifecycle(flag, flag_environment, lifecycle_context) do
    Lifecycle.classify(
      flag_summary(flag),
      flag_environment_summary(flag_environment),
      lifecycle_opts(flag, lifecycle_context)
    )
  end

  defp lifecycle_opts(flag, lifecycle_context) do
    evidence = Map.get(lifecycle_context, flag.key, %{})

    Application.get_env(:rulestead, :admin_lifecycle, [])
    |> Keyword.put(:code_reference_count, Map.get(evidence, :code_reference_count))
    |> Keyword.put(:code_refs_scan, Map.get(lifecycle_context, :code_refs_scan))
  end

  defp lifecycle_context_for_flags(flag_keys) do
    counts = code_reference_counts(flag_keys)
    scan = latest_code_refs_scan()

    Enum.reduce(flag_keys, %{code_refs_scan: scan}, fn flag_key, acc ->
      Map.put(acc, flag_key, %{code_reference_count: Map.get(counts, flag_key, 0)})
    end)
  end

  defp latest_code_refs_scan do
    ScanReceipt.latest_query()
    |> Repo.one()
    |> case do
      nil -> nil
      receipt -> %{received_at: receipt.received_at, reference_count: receipt.reference_count}
    end
  end

  defp code_reference_counts(flag_keys) do
    keys = flag_keys |> Enum.uniq() |> Enum.reject(&is_nil/1)

    from(code_reference in CodeReference,
      where: code_reference.flag_key in ^keys,
      group_by: code_reference.flag_key,
      select: {code_reference.flag_key, count(code_reference.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  defp recent_owners(current_owner, extra_owner \\ nil) do
    owners =
      from(flag in Flag,
        order_by: [desc: flag.updated_at],
        select: fragment("?->>'owner_ref'", flag.ownership)
      )
      |> Repo.all()

    [
      normalize_owner(current_owner),
      normalize_owner(extra_owner) | Enum.map(owners, &normalize_owner/1)
    ]
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

    Enum.filter(entries, fn entry ->
      ownership = Map.get(entry.flag, :ownership) || %{}

      normalized in [
        normalize_owner(Map.get(ownership, :owner_ref) || Map.get(ownership, "owner_ref")),
        normalize_owner(Map.get(ownership, :owner_display) || Map.get(ownership, "owner_display"))
      ]
    end)
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
      case entry.lifecycle.freshness.state do
        :active -> stale_state == :fresh
        :potentially_stale -> stale_state == :potentially_stale
        :stale -> stale_state == :stale
        :archived -> false
      end
    end)
  end

  defp maybe_filter_readiness(entries, nil), do: entries

  defp maybe_filter_readiness(entries, readiness) do
    Enum.filter(entries, &(&1.lifecycle.archive_readiness.readiness == readiness))
  end

  defp maybe_filter_evidence_quality(entries, nil), do: entries

  defp maybe_filter_evidence_quality(entries, evidence_quality) do
    Enum.filter(entries, &(&1.lifecycle.archive_readiness.evidence_quality == evidence_quality))
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
      ilike(audience.key, ^normalized) or
        ilike(fragment("coalesce(?, '')", audience.description), ^normalized)
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
    if not is_nil(command.lifecycle) do
      Map.put(attrs, :lifecycle, command.lifecycle)
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
      on:
        fe.flag_id == flag.id and fe.status in [:active, :killswitched] and
          not is_nil(fe.active_ruleset_id),
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

  defp webhook_receipt_fields do
    [
      :id,
      :provider,
      :endpoint_key,
      :delivery_id,
      :attempt_id,
      :topic,
      :occurred_at,
      :received_at,
      :raw_body_sha256,
      :verification_metadata,
      :normalized_payload,
      :dedupe_key,
      :verified_state,
      :rejection_reason,
      :correlation_id,
      :change_request_id,
      :scheduled_execution_id,
      :inserted_at,
      :updated_at
    ]
  end

  defp normalize_webhook_receipt_row(row) when is_map(row) do
    row
    |> maybe_normalize_uuid(:id)
    |> maybe_normalize_uuid(:change_request_id)
    |> maybe_normalize_uuid(:scheduled_execution_id)
  end

  defp serialize_webhook_receipt_row(row) do
    %{
      id: row.id,
      provider: row.provider,
      endpoint_key: row.endpoint_key,
      delivery_id: row.delivery_id,
      attempt_id: row.attempt_id,
      topic: row.topic,
      occurred_at: row.occurred_at,
      received_at: row.received_at,
      raw_body_sha256: row.raw_body_sha256,
      verification_metadata: row.verification_metadata || %{},
      normalized_payload: row.normalized_payload || %{},
      dedupe_key: row.dedupe_key,
      verified_state: String.to_existing_atom(row.verified_state),
      rejection_reason: row.rejection_reason,
      correlation_id: row.correlation_id,
      change_request_id: row.change_request_id,
      scheduled_execution_id: row.scheduled_execution_id,
      inserted_at: row.inserted_at,
      updated_at: row.updated_at
    }
  end

  defp maybe_filter_webhook_record(query, _field, nil), do: query

  defp maybe_filter_webhook_record(query, field_name, value) do
    where(query, [wr], field(wr, ^field_name) == ^to_string(value))
  end

  defp normalize_webhook_state_filter(nil), do: nil
  defp normalize_webhook_state_filter(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_webhook_state_filter(value) when is_binary(value), do: String.trim(value)

  defp fetch_destination_by_id(id) do
    case Repo.get(Destination, id) do
      nil -> {:error, StoreError.invalid_command("webhook destination was not found")}
      destination -> {:ok, destination}
    end
  end

  defp serialize_webhook_destination(destination) do
    %{
      id: destination.id,
      name: destination.name,
      description: destination.description,
      url: destination.url,
      secret_id: destination.secret_id,
      environment_key: destination.environment_key,
      subscriptions: destination.subscriptions || [],
      enabled: destination.enabled,
      metadata: destination.metadata || %{},
      inserted_at: destination.inserted_at,
      updated_at: destination.updated_at
    }
  end

  defp serialize_webhook_delivery(delivery) do
    %{
      id: delivery.id,
      destination_id: delivery.webhook_destination_id,
      event_id: delivery.webhook_outbound_event_id,
      state: delivery.state,
      attempt_count: delivery.attempt_count,
      last_attempt_at: delivery.last_attempt_at,
      next_attempt_at: delivery.next_attempt_at,
      terminal_failure_reason: delivery.terminal_failure_reason,
      last_response_code: delivery.last_response_code,
      last_response_body: delivery.last_response_body,
      inserted_at: delivery.inserted_at,
      updated_at: delivery.updated_at,
      # Preloaded associations
      event: maybe_serialize_outbound_event(delivery.webhook_outbound_event),
      destination: maybe_serialize_destination_summary(delivery.webhook_destination)
    }
  end

  defp maybe_serialize_outbound_event(%Ecto.Association.NotLoaded{}), do: nil
  defp maybe_serialize_outbound_event(nil), do: nil

  defp maybe_serialize_outbound_event(event) do
    %{
      id: event.id,
      event_type: event.event_type,
      payload: event.payload,
      resource_type: event.resource_type,
      resource_key: event.resource_key,
      environment_key: event.environment_key,
      correlation_id: event.correlation_id,
      inserted_at: event.inserted_at
    }
  end

  defp maybe_serialize_destination_summary(%Ecto.Association.NotLoaded{}), do: nil
  defp maybe_serialize_destination_summary(nil), do: nil

  defp maybe_serialize_destination_summary(destination) do
    %{
      id: destination.id,
      name: destination.name,
      url: destination.url
    }
  end

  defp maybe_filter_destination(query, _field, nil), do: query

  defp maybe_filter_destination(query, field_name, value) do
    where(query, [d], field(d, ^field_name) == ^to_string(value))
  end

  defp maybe_filter_delivery(query, _field, nil), do: query

  defp maybe_filter_delivery(query, field_name, value) do
    where(query, [d], field(d, ^field_name) == ^value)
  end

  defp enqueue_webhook_deliveries(multi, event_type, payload_fn, opts) do
    env_key = Keyword.get(opts, :environment_key)
    resource_type = Keyword.get(opts, :resource_type)
    resource_key = Keyword.get(opts, :resource_key)

    Multi.run(multi, :"outbound_webhooks_#{event_type}", fn repo, changes ->
      destinations =
        repo.all(
          from(d in Rulestead.Webhooks.Destination,
            where:
              d.enabled == true and ^event_type in d.subscriptions and
                (is_nil(d.environment_key) or d.environment_key == ^env_key)
          )
        )

      if Enum.empty?(destinations) do
        {:ok, []}
      else
        correlation_id = get_correlation_id(changes) || Ecto.UUID.generate()
        payload = payload_fn.(changes)

        {:ok, event} =
          Rulestead.Webhooks.OutboundEvent.changeset(%Rulestead.Webhooks.OutboundEvent{}, %{
            event_type: event_type,
            payload: payload,
            resource_type: resource_type,
            resource_key: resource_key,
            environment_key: env_key,
            correlation_id: correlation_id
          })
          |> repo.insert()

        deliveries =
          Enum.map(destinations, fn dest ->
            {:ok, delivery} =
              Rulestead.Webhooks.Delivery.changeset(%Rulestead.Webhooks.Delivery{}, %{
                webhook_destination_id: dest.id,
                webhook_outbound_event_id: event.id,
                state: :pending,
                attempt_count: 0
              })
              |> repo.insert()

            job = Rulestead.Oban.webhook_delivery_job(delivery.id)
            repo.insert_all("oban_jobs", [job], returning: [:id])

            delivery
          end)

        {:ok, deliveries}
      end
    end)
  end

  @doc false
  def requeue_webhook_delivery(delivery, schedule_in \\ 0) do
    job = Rulestead.Oban.webhook_delivery_job(delivery.id, schedule_in: schedule_in)
    Repo.insert_all("oban_jobs", [job], returning: [:id])
    :ok
  end

  defp get_correlation_id(%{audit_event: audit_event}), do: audit_event.correlation_id
  defp get_correlation_id(%{change_request: cr}), do: cr.correlation_id
  defp get_correlation_id(_), do: nil
end
