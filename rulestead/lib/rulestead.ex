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
    Result,
    Runtime,
    Store,
    StoreError,
    Telemetry
  }
  alias Rulestead.Store.Command

  @version Mix.Project.config()[:version] || "0.1.0"

  @doc """
  Returns the package version.
  """
  @spec version() :: String.t()
  def version, do: @version

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
    Telemetry.span(
      [:rulestead, :admin, :mutation],
      Telemetry.metadata(
        Telemetry.command_metadata(command, %{operation: "save_draft_ruleset", audit_action: "save_draft_ruleset"})
      ),
      fn ->
        result = run_store(:save_draft_ruleset, [command], command)
        {result, admin_stop_metadata(result, command)}
      end
    )
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
    Telemetry.span(
      [:rulestead, :admin, :mutation],
      Telemetry.metadata(
        Telemetry.command_metadata(command, %{operation: "publish_ruleset", audit_action: "publish_ruleset"})
      ),
      fn ->
        result = run_store(:publish_ruleset, [command], command)
        {result, admin_stop_metadata(result, command)}
      end
    )
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
    Telemetry.span(
      [:rulestead, :admin, :mutation],
      Telemetry.metadata(
        Telemetry.command_metadata(command, %{operation: "archive_flag", audit_action: "archive_flag"})
      ),
      fn ->
        result = run_store(:archive_flag, [command], command)
        {result, admin_stop_metadata(result, command)}
      end
    )
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

  @spec engage_kill_switch(String.t() | atom(), String.t() | atom(), map(), keyword()) :: Store.result(map())
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

  @spec release_kill_switch(String.t() | atom(), String.t() | atom(), map(), keyword()) :: Store.result(map())
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
  @spec list_audit_events(Command.ListAuditEvents.t() | keyword()) :: Store.result(Command.Page.t(map()))
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
  Records bounded evaluation freshness for one flag/environment pair.
  """
  @spec record_evaluation(Command.RecordEvaluation.t()) :: Store.result(map())
  def record_evaluation(%Command.RecordEvaluation{} = command) do
    admin_write(:record_evaluation, command)
  end

  @doc """
  Records bounded evaluation freshness using root-level arguments.
  """
  @spec record_evaluation(String.t() | atom(), String.t() | atom(), DateTime.t()) :: Store.result(map())
  def record_evaluation(flag_key, environment_key, %DateTime{} = last_evaluated_at) do
    flag_key
    |> Command.RecordEvaluation.new(environment_key, last_evaluated_at)
    |> record_evaluation()
  end

  @doc """
  Evaluates an authored in-memory flag payload against an explicit context.
  """
  @spec evaluate(map(), Context.t() | keyword() | map(), keyword()) :: {:ok, Result.t()} | {:error, Error.t()}
  def evaluate(flag_payload, context, opts \\ []) do
    context = normalize_eval_context(context, opts)

    Telemetry.span(
      [:rulestead, :eval, :decide],
      Telemetry.metadata(Telemetry.base_metadata(flag_payload, context)),
      fn ->
        result =
          with {:ok, result} <- Evaluator.evaluate(flag_payload, context) do
            emit_warnings(result)
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
  @spec get_value(map(), Context.t() | keyword() | map(), term()) :: {:ok, term()} | {:error, Error.t()}
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
  @spec get_variant(map(), Context.t() | keyword() | map()) :: {:ok, String.t() | nil} | {:error, Error.t()}
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
  @spec simulate_flag(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def simulate_flag(flag_key, environment_key, context, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    with :ok <- authorize_admin_read(actor, :simulate_flag, %{resource_type: :flag, resource_key: flag_key}, environment_key),
         {:ok, result} <- Runtime.evaluate(environment_key, flag_key, context) do
      redacted = Redaction.redact_metadata(%{traits: Context.normalize(context).attributes}, allow: Keyword.get(opts, :allow, ["targeting_key"]))
      {:ok, %{result: result, redacted_context: redacted}}
    end
  end

  @doc """
  Admin-safe explain seam for one flag and environment.
  """
  @spec explain_flag(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def explain_flag(flag_key, environment_key, context, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    with :ok <- authorize_admin_read(actor, :explain_flag, %{resource_type: :flag, resource_key: flag_key}, environment_key),
         {:ok, explanation} <- Runtime.explain(environment_key, flag_key, context) do
      redacted = Redaction.redact_metadata(%{traits: Context.normalize(context).attributes}, allow: Keyword.get(opts, :allow, ["targeting_key"]))
      {:ok, %{explanation: explanation, redacted_context: redacted}}
    end
  end

  @doc """
  Returns bounded runtime diagnostics for the local node.
  """
  @spec diagnostics() :: map()
  def diagnostics, do: Runtime.diagnostics()

  defp run_store(operation, args, command) do
    case configured_store() do
      {:ok, adapter} -> invoke_store(adapter, operation, args, command)
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp configured_store do
    case Application.get_env(:rulestead, :store) || Application.get_env(:rulestead, :store_adapter) do
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
        {:error, ConfigError.store_adapter_invalid(metadata: %{configured_value: inspect(invalid)})}
    end
  end

  defp normalize_configured_adapter(adapter, config) when is_atom(adapter) do
    case ensure_adapter_module(adapter) do
      {:ok, adapter} -> {:ok, adapter}
      {:error, error} -> {:error, Error.normalize(Map.put(Map.from_struct(error), :metadata, %{configured_value: inspect(config)}))}
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
  defp normalize_store_result({:error, %Error{} = error}, _adapter, _operation), do: {:error, error}

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

  defp emit_warnings(%Result{debug_trace: %{warnings: warnings}} = result) when is_list(warnings) do
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
    action = command_action(operation)

    Telemetry.span(
      [:rulestead, :admin, :mutation],
      Telemetry.metadata(
        Telemetry.command_metadata(redacted_command, %{operation: Atom.to_string(operation), audit_action: Atom.to_string(operation)})
      ),
      fn ->
        result =
          case Authorizer.authorize(redacted_command.actor, action, resource, Map.get(redacted_command, :environment_key)) do
            :ok ->
              run_store(operation, [redacted_command], redacted_command)

            {:error, error, denied_audit} ->
              maybe_persist_denied_mutation(operation, redacted_command, denied_audit)
              {:error, error}
          end

        {result, admin_stop_metadata(result, redacted_command)}
      end
    )
  end

  defp admin_read(operation, command) do
    action = command_action(operation)

    with :ok <- authorize_admin_read(command.actor, action, command_resource(command), Map.get(command, :environment_key)) do
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
    allow = ["request_id", "source", "reason", "targeting_key", "plan", "nested.region"]
    redacted_metadata = Redaction.redact_metadata(Map.get(command, :metadata, %{}), allow: allow)
    Map.put(command, :metadata, redacted_metadata.audit)
  end

  defp command_resource(%Command.RollbackAuditEvent{audit_event_id: audit_event_id}) do
    %{resource_type: :audit_event, resource_key: audit_event_id}
  end

  defp command_resource(command) do
    %{resource_type: :flag, resource_key: Map.get(command, :flag_key)}
  end

  defp command_action(:engage_kill_switch), do: :engage_kill_switch
  defp command_action(:release_kill_switch), do: :release_kill_switch
  defp command_action(:rollback_audit_event), do: :rollback_audit_event
  defp command_action(:list_audit_events), do: :list_audit_events
  defp command_action(operation), do: operation

  defp maybe_persist_denied_mutation(operation, command, denied_audit)
       when operation in [:engage_kill_switch, :release_kill_switch] do
    denied_command =
      command
      |> Map.put(:reason, command.reason || "unauthorized")
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
      |> Map.put(:environment, get_in(value, [:environment, :key]) || Map.get(value, :environment_key))
      |> Map.put(:snapshot_version, Map.get(value, :version) || get_in(value, [:flag_environment, :active_ruleset_version]))
    end
  end

  defp result_like_metadata(_value), do: %{}

  defp store_event_kind(operation) when operation in [:fetch_flag, :fetch_snapshot, :list_flags], do: :read
  defp store_event_kind(_operation), do: :write

  defp store_success_reason(:fetch_snapshot), do: :fetched
  defp store_success_reason(:fetch_flag), do: :fetched
  defp store_success_reason(:list_flags), do: :listed
  defp store_success_reason(_operation), do: :stored
end
