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

  alias Rulestead.{ConfigError, Context, Error, Evaluator, Explainer, Result, Runtime, Store, StoreError}
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
    run_store(:fetch_flag, [command])
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
    run_store(:save_draft_ruleset, [command])
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
    run_store(:publish_ruleset, [command])
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
    run_store(:archive_flag, [command])
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
  Lists flags through the configured store adapter.

  Phase 2 keeps this as the shared list/search surface for store adapters.
  """
  @spec list_flags(Command.ListFlags.t()) :: Store.result([map()])
  def list_flags(%Command.ListFlags{} = command) do
    run_store(:list_flags, [command])
  end

  @doc """
  Lists flags with default query options.
  """
  @spec list_flags() :: Store.result([map()])
  def list_flags do
    list_flags(Command.ListFlags.new())
  end

  @doc """
  Bang variant of `list_flags/0` and `list_flags/1`.
  """
  @spec list_flags!() :: [map()]
  @spec list_flags!(Command.ListFlags.t()) :: [map()]
  def list_flags!(command \\ Command.ListFlags.new()) do
    command
    |> list_flags()
    |> unwrap!()
  end

  @doc """
  Evaluates an authored in-memory flag payload against an explicit context.
  """
  @spec evaluate(map(), Context.t() | keyword() | map(), keyword()) :: {:ok, Result.t()} | {:error, Error.t()}
  def evaluate(flag_payload, context, opts \\ []) do
    with {:ok, result} <- Evaluator.evaluate(flag_payload, normalize_eval_context(context, opts)) do
      emit_warnings(result)
      {:ok, result}
    end
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
  Returns bounded runtime diagnostics for the local node.
  """
  @spec diagnostics() :: map()
  def diagnostics, do: Runtime.diagnostics()

  defp run_store(operation, args) do
    case configured_store() do
      {:ok, adapter} -> invoke_store(adapter, operation, args)
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

  defp invoke_store(adapter, operation, args) do
    arity = length(args)

    cond do
      not function_exported?(adapter, operation, arity) ->
        {:error,
         ConfigError.store_adapter_invalid(
           metadata: %{adapter: inspect(adapter), operation: Atom.to_string(operation)},
           details: [%{message: "callback is not exported"}]
         )}

      true ->
        do_invoke_store(adapter, operation, args)
    end
  end

  defp do_invoke_store(adapter, operation, args) do
    result = apply(adapter, operation, args)
    normalize_store_result(result, adapter, operation)
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
      :telemetry.execute(
        [:rulestead, :eval, :warning],
        %{count: 1},
        %{
          flag_key: result.flag_key,
          environment: result.debug_trace[:environment],
          bucket_by: warning[:bucket_by],
          reason: warning[:type],
          strict?: warning[:strict?] || false
        }
      )
    end)
  end

  defp emit_warnings(_result), do: :ok
end
