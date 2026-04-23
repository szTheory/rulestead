defmodule Rulestead.Telemetry do
  @moduledoc """
  Shared telemetry helpers for the locked Phase 4 public event catalog.
  """

  alias Rulestead.{Context, Result}

  @handler_table :rulestead_telemetry_handlers
  @shared_keys ~w(flag_key flag_type environment snapshot_version cache_age_ms reason has_targeting_key? matched_rule_count)a
  @optional_keys ~w(operation source refresh_status audit_action error_kind)a

  @type event_prefix :: [atom()]
  @type event_name :: [atom()]
  @type metadata :: map()

  @spec span(event_prefix(), metadata(), (() -> {term(), metadata()} | term())) :: term()
  def span(event_prefix, metadata, fun) when is_list(event_prefix) and is_map(metadata) and is_function(fun, 0) do
    normalized_prefix = normalize_event_prefix(event_prefix)
    start_metadata = metadata(metadata)

    :telemetry.span(normalized_prefix, start_metadata, fn ->
      case fun.() do
        {result, stop_metadata} when is_map(stop_metadata) ->
          {result, metadata(Map.merge(start_metadata, stop_metadata))}

        other ->
          {other, start_metadata}
      end
    end)
  end

  @spec execute(event_name(), map(), metadata()) :: :ok
  def execute(event_name, measurements, metadata)
      when is_list(event_name) and is_map(measurements) and is_map(metadata) do
    :telemetry.execute(event_name, measurements, metadata(metadata))
  end

  @spec attach_many(term(), [event_name()], :telemetry.handler_function(), term()) :: :ok | {:error, term()}
  def attach_many(handler_id, events, function, config)
      when is_list(events) and is_function(function, 4) do
    ensure_handler_table()

    Enum.each(events, fn event ->
      ensure_dispatcher(event)
      :ets.insert(@handler_table, {{handler_id, event}, function, config})
    end)

    :ok
  end

  @spec detach(term()) :: :ok
  def detach(handler_id) do
    ensure_handler_table()
    :ets.match_delete(@handler_table, {{handler_id, :_}, :_, :_})
    :ok
  end

  @spec metadata(map()) :: map()
  def metadata(attrs) when is_map(attrs) do
    attrs
    |> Map.take(@shared_keys ++ @optional_keys)
    |> Enum.reduce(%{}, fn
      {_key, nil}, acc -> acc
      {key, value}, acc -> Map.put(acc, key, sanitize_value(key, value))
    end)
  end

  @spec base_metadata(map() | nil, Context.t() | map() | keyword() | nil, map()) :: map()
  def base_metadata(flag_payload, context, attrs \\ %{}) do
    context = normalize_context(context)

    attrs
    |> Map.new()
    |> Map.put_new(:flag_key, get_in(flag_payload || %{}, [:flag, :key]) |> stringify())
    |> Map.put_new(:flag_type, get_in(flag_payload || %{}, [:flag, :flag_type]) |> normalize_atom())
    |> Map.put_new(:environment, environment_value(flag_payload, context, attrs))
    |> Map.put_new(:has_targeting_key?, not is_nil(context.targeting_key))
  end

  @spec result_metadata(Result.t(), Context.t() | map() | keyword() | nil, map()) :: map()
  def result_metadata(%Result{} = result, context, attrs \\ %{}) do
    context = normalize_context(context)
    trace = result.debug_trace || %{}

    attrs
    |> Map.new()
    |> Map.put_new(:flag_key, stringify(result.flag_key))
    |> Map.put_new(:environment, stringify(trace[:environment] || context.environment))
    |> Map.put_new(:reason, normalize_atom(result.reason))
    |> Map.put_new(:cache_age_ms, result.cache_age_ms)
    |> Map.put_new(:snapshot_version, result.flag_version)
    |> Map.put_new(:has_targeting_key?, not is_nil(context.targeting_key))
    |> Map.put_new(:matched_rule_count, matched_rule_count(trace, result))
  end

  @spec runtime_metadata(map(), map()) :: map()
  def runtime_metadata(runtime_metadata, attrs \\ %{}) when is_map(runtime_metadata) do
    attrs
    |> Map.new()
    |> Map.put_new(:environment, stringify(runtime_metadata[:environment_key] || runtime_metadata["environment_key"]))
    |> Map.put_new(:snapshot_version, runtime_metadata[:snapshot_version] || runtime_metadata["snapshot_version"])
    |> Map.put_new(:cache_age_ms, runtime_metadata[:cache_age_ms] || runtime_metadata["cache_age_ms"])
    |> Map.put_new(:refresh_status, normalize_atom(runtime_metadata[:refresh_status] || runtime_metadata["refresh_status"]))
    |> Map.put_new(:source, normalize_atom(runtime_metadata[:source] || runtime_metadata["source"]))
    |> Map.put_new(:reason, normalize_atom(runtime_metadata[:last_refresh_error] || runtime_metadata["last_refresh_error"]))
  end

  @spec command_metadata(struct(), map()) :: map()
  def command_metadata(command, attrs \\ %{}) when is_struct(command) do
    command_map = Map.from_struct(command)

    attrs
    |> Map.new()
    |> Map.put_new(:flag_key, stringify(Map.get(command_map, :flag_key)))
    |> Map.put_new(:environment, stringify(Map.get(command_map, :environment_key)))
    |> Map.put_new(:reason, normalize_atom(Map.get(command_map, :reason)))
    |> Map.put_new(:has_targeting_key?, false)
  end

  @spec dispatch(event_name(), map(), metadata(), event_name()) :: :ok
  def dispatch(event, measurements, metadata, registered_event) do
    ensure_handler_table()

    @handler_table
    |> :ets.match_object({{:_, registered_event}, :_, :_})
    |> Enum.each(fn {{_handler_id, _event}, function, config} ->
      safely_invoke(function, event, measurements, metadata, config)
    end)

    :ok
  end

  defp safely_invoke(function, event, measurements, metadata, config) do
    function.(event, measurements, metadata, config)
  rescue
    _error -> :ok
  catch
    _kind, _reason -> :ok
  end

  defp normalize_event_prefix([:rulestead | _] = event_prefix), do: event_prefix
  defp normalize_event_prefix(event_prefix), do: [:rulestead | event_prefix]

  defp ensure_handler_table do
    case :ets.whereis(@handler_table) do
      :undefined ->
        try do
          :ets.new(@handler_table, [:named_table, :public, :bag])
        rescue
          ArgumentError -> @handler_table
        end

      _table ->
        @handler_table
    end

    :ok
  end

  defp ensure_dispatcher(event) do
    dispatcher_id = dispatcher_id(event)

    case :telemetry.attach(dispatcher_id, event, &__MODULE__.dispatch/4, event) do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
  end

  defp dispatcher_id(event), do: {__MODULE__, event}

  defp normalize_context(nil), do: Context.new(%{})
  defp normalize_context(context), do: Context.normalize(context)

  defp environment_value(flag_payload, context, attrs) do
    stringify(
      attrs[:environment] ||
        get_in(flag_payload || %{}, [:environment, :key]) ||
        context.environment
    )
  end

  defp matched_rule_count(_trace, %Result{matched_rule: nil}), do: 0
  defp matched_rule_count(_trace, %Result{}), do: 1

  defp sanitize_value(:cache_age_ms, value) when is_integer(value) and value >= 0, do: value
  defp sanitize_value(:snapshot_version, value) when is_integer(value) and value > 0, do: value
  defp sanitize_value(key, value) when key in [:has_targeting_key?] and is_boolean(value), do: value
  defp sanitize_value(key, value) when key in [:matched_rule_count] and is_integer(value) and value >= 0, do: value
  defp sanitize_value(key, value) when key in [:flag_key, :environment, :operation, :audit_action], do: stringify(value)
  defp sanitize_value(key, value) when key in [:flag_type, :reason, :source, :refresh_status, :error_kind], do: normalize_atom(value)
  defp sanitize_value(_key, _value), do: nil

  defp stringify(nil), do: nil
  defp stringify(value) when is_binary(value), do: String.trim(value)
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_integer(value), do: Integer.to_string(value)
  defp stringify(_value), do: nil

  defp normalize_atom(nil), do: nil
  defp normalize_atom(value) when is_atom(value), do: value
  defp normalize_atom(value) when is_binary(value), do: value |> String.trim() |> binary_atom()

  defp normalize_atom(_value), do: nil

  defp binary_atom(""), do: nil

  defp binary_atom(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end
end
