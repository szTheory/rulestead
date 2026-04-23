defmodule Rulestead do
  @moduledoc """
  Root public module for the `rulestead` package.

  Phase 2 reserves the stable bang/non-bang public API shape:

  - store-facing calls return `{:ok, value} | {:error, %Rulestead.Error{}}`
  - bang variants raise the same `%Rulestead.Error{}`
  - `evaluate/3` and `evaluate!/3` are intentionally reserved stubs until
    the runtime evaluator lands in Phase 3
  """

  alias Rulestead.{ConfigError, Error, EvaluationError, Store, StoreError}
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
  Reserved Phase 2 stub for the future runtime evaluator.
  """
  @spec evaluate(String.t() | atom(), term(), keyword()) :: {:error, Error.t()}
  def evaluate(flag_key, context, opts \\ []) do
    {:error,
     EvaluationError.not_implemented(
       metadata: evaluator_metadata(flag_key, opts),
       details: evaluator_details(context)
     )}
  end

  @doc """
  Bang variant of `evaluate/3`.
  """
  @spec evaluate!(String.t() | atom(), term(), keyword()) :: no_return()
  def evaluate!(flag_key, context, opts \\ []) do
    flag_key
    |> evaluate(context, opts)
    |> unwrap!()
  end

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

  defp evaluator_metadata(flag_key, opts) do
    %{
      feature: "evaluate/3",
      flag_key: to_string(flag_key),
      strict?: Keyword.get(opts, :strict?, false)
    }
  end

  defp evaluator_details(context) do
    [%{message: "runtime evaluator is not available in Phase 2", context_type: inspect(context.__struct__ || context)}]
  rescue
    _error -> [%{message: "runtime evaluator is not available in Phase 2"}]
  end
end
