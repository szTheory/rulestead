defmodule Rulestead.Guardrails.SignalFact do
  @moduledoc false

  alias Rulestead.Guardrails.Query
  alias Rulestead.Store.Command

  @enforce_keys [:signal_key, :status, :reason]
  defstruct [
    :signal_key,
    :status,
    :reason,
    :environment_key,
    :tenant_key,
    :environment_scope,
    :tenant_scope,
    :scope_source,
    :threshold_operator,
    :threshold_value,
    :observed_value,
    :freshness_window_seconds,
    :sample_size,
    :min_sample_size,
    :captured_at,
    :evaluated_at,
    metadata: %{}
  ]

  @statuses [:healthy, :breached, :failed_closed]
  @reasons [
    :healthy,
    :breached,
    :provider_missing,
    :unsupported_scope,
    :unsupported_signal,
    :stale,
    :insufficient_sample,
    :invalid_provider_response
  ]

  @type t :: %__MODULE__{
          signal_key: String.t(),
          status: atom(),
          reason: atom(),
          environment_key: String.t() | nil,
          tenant_key: String.t() | nil,
          environment_scope: atom(),
          tenant_scope: atom(),
          scope_source: String.t(),
          threshold_operator: atom() | nil,
          threshold_value: number() | nil,
          observed_value: number() | nil,
          freshness_window_seconds: non_neg_integer() | nil,
          sample_size: non_neg_integer() | nil,
          min_sample_size: non_neg_integer() | nil,
          captured_at: DateTime.t() | nil,
          evaluated_at: DateTime.t(),
          metadata: map()
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = fact), do: fact |> Map.from_struct() |> new()

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    signal_key = string_or_default(attrs, :signal_key, "unknown_signal")
    threshold_operator = normalize_threshold_operator(optional_value(attrs, :threshold_operator))
    threshold_value = normalize_number(optional_value(attrs, :threshold_value))
    observed_value = normalize_number(optional_value(attrs, :observed_value))

    freshness_window_seconds =
      normalize_non_negative_integer(optional_value(attrs, :freshness_window_seconds))

    sample_size = normalize_non_negative_integer(optional_value(attrs, :sample_size))
    min_sample_size = normalize_non_negative_integer(optional_value(attrs, :min_sample_size))
    captured_at = normalize_datetime(optional_value(attrs, :captured_at))
    evaluated_at = normalize_datetime(optional_value(attrs, :evaluated_at)) || DateTime.utc_now()

    reason =
      resolve_reason(
        optional_value(attrs, :reason),
        threshold_operator,
        threshold_value,
        observed_value,
        freshness_window_seconds,
        sample_size,
        min_sample_size,
        captured_at,
        evaluated_at
      )

    %__MODULE__{
      signal_key: signal_key,
      status: resolve_status(optional_value(attrs, :status), reason),
      reason: reason,
      environment_key: optional_string(attrs, :environment_key),
      tenant_key: optional_string(attrs, :tenant_key),
      environment_scope: normalize_environment_scope(optional_value(attrs, :environment_scope)),
      tenant_scope:
        Query.new(%{
          signal_key: signal_key,
          tenant_key: optional_string(attrs, :tenant_key),
          tenant_scope: optional_value(attrs, :tenant_scope)
        }).tenant_scope,
      scope_source:
        normalize_scope_source(
          optional_value(attrs, :scope_source),
          optional_string(attrs, :tenant_key)
        ),
      threshold_operator: threshold_operator,
      threshold_value: threshold_value,
      observed_value: observed_value,
      freshness_window_seconds: freshness_window_seconds,
      sample_size: sample_size,
      min_sample_size: min_sample_size,
      captured_at: captured_at,
      evaluated_at: DateTime.truncate(evaluated_at, :second),
      metadata:
        attrs
        |> optional_value(:metadata)
        |> Command.GovernanceSupport.normalize_metadata()
    }
  end

  @spec from_query_result(Query.t() | map() | keyword(), term()) :: t()
  def from_query_result(query, provider_result) do
    query = Query.new(query)

    attrs =
      case provider_result do
        %__MODULE__{} = fact ->
          Map.from_struct(fact)

        {:ok, value} when is_list(value) or is_map(value) ->
          Map.new(value)

        {:error, reason} ->
          %{reason: reason}

        value when is_list(value) or is_map(value) ->
          Map.new(value)

        _other ->
          %{reason: :invalid_provider_response}
      end

    new(
      attrs
      |> Map.put_new(:signal_key, query.signal_key)
      |> Map.put_new(:environment_key, query.environment_key)
      |> Map.put_new(:tenant_key, query.tenant_key)
      |> Map.put_new(:environment_scope, query.environment_scope)
      |> Map.put_new(:tenant_scope, query.tenant_scope)
      |> Map.put_new(:scope_source, query.scope_source)
      |> Map.put_new(:threshold_operator, query.threshold_operator)
      |> Map.put_new(:threshold_value, query.threshold_value)
      |> Map.put_new(:freshness_window_seconds, query.freshness_window_seconds)
      |> Map.put_new(:min_sample_size, query.min_sample_size)
    )
  end

  @spec provider_missing(Query.t() | map() | keyword()) :: t()
  def provider_missing(query),
    do: query |> Query.new() |> from_query_result({:error, :provider_missing})

  @spec metadata(t() | map() | keyword()) :: map()
  def metadata(fact) do
    fact = new(fact)

    Command.GovernanceSupport.normalize_guardrail_metadata(%{
      signal_key: fact.signal_key,
      environment_key: fact.environment_key,
      tenant_key: fact.tenant_key,
      environment_scope: fact.environment_scope,
      tenant_scope: fact.tenant_scope,
      scope_source: fact.scope_source,
      status: fact.status,
      reason: fact.reason,
      threshold_operator: fact.threshold_operator,
      threshold_value: fact.threshold_value,
      observed_value: fact.observed_value,
      freshness_window_seconds: fact.freshness_window_seconds,
      sample_size: fact.sample_size,
      min_sample_size: fact.min_sample_size,
      captured_at: fact.captured_at,
      evaluated_at: fact.evaluated_at,
      metadata: fact.metadata
    })
  end

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @spec reasons() :: [atom()]
  def reasons, do: @reasons

  defp resolve_reason(
         reason,
         _operator,
         _threshold,
         _observed,
         _freshness,
         _sample_size,
         _min_sample,
         _captured_at,
         _evaluated_at
       )
       when reason in @reasons,
       do: reason

  defp resolve_reason(
         reason,
         _operator,
         _threshold,
         _observed,
         _freshness,
         _sample_size,
         _min_sample,
         _captured_at,
         _evaluated_at
       )
       when is_binary(reason) do
    case String.trim(reason) do
      "healthy" -> :healthy
      "breached" -> :breached
      "provider_missing" -> :provider_missing
      "unsupported_scope" -> :unsupported_scope
      "unsupported_signal" -> :unsupported_signal
      "stale" -> :stale
      "insufficient_sample" -> :insufficient_sample
      _other -> :invalid_provider_response
    end
  end

  defp resolve_reason(
         _reason,
         operator,
         threshold_value,
         observed_value,
         freshness_window_seconds,
         sample_size,
         min_sample_size,
         captured_at,
         evaluated_at
       ) do
    cond do
      is_integer(freshness_window_seconds) and freshness_window_seconds >= 0 and
        not is_nil(captured_at) and
          DateTime.diff(evaluated_at, captured_at, :second) > freshness_window_seconds ->
        :stale

      is_integer(sample_size) and is_integer(min_sample_size) and sample_size < min_sample_size ->
        :insufficient_sample

      operator in [:lt, :lte, :gt, :gte] and is_number(threshold_value) and
          is_number(observed_value) ->
        if breached?(operator, observed_value, threshold_value), do: :breached, else: :healthy

      true ->
        :invalid_provider_response
    end
  end

  defp resolve_status(status, _reason) when status in @statuses, do: status
  defp resolve_status("healthy", _reason), do: :healthy
  defp resolve_status("breached", _reason), do: :breached
  defp resolve_status("failed_closed", _reason), do: :failed_closed
  defp resolve_status(_status, reason) when reason in [:healthy], do: :healthy
  defp resolve_status(_status, reason) when reason in [:breached], do: :breached
  defp resolve_status(_status, _reason), do: :failed_closed

  defp breached?(:lt, observed, threshold), do: observed < threshold
  defp breached?(:lte, observed, threshold), do: observed <= threshold
  defp breached?(:gt, observed, threshold), do: observed > threshold
  defp breached?(:gte, observed, threshold), do: observed >= threshold

  defp optional_value(attrs, key),
    do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp optional_string(attrs, key) do
    attrs
    |> optional_value(key)
    |> Command.GovernanceSupport.normalize_string()
  end

  defp string_or_default(attrs, key, default), do: optional_string(attrs, key) || default

  defp normalize_threshold_operator(value),
    do: Query.new(%{signal_key: "signal", threshold_operator: value}).threshold_operator

  defp normalize_environment_scope(value),
    do: Query.new(%{signal_key: "signal", environment_scope: value}).environment_scope

  defp normalize_scope_source(value, tenant_key),
    do:
      Query.new(%{signal_key: "signal", scope_source: value, tenant_key: tenant_key}).scope_source

  defp normalize_non_negative_integer(value) when is_integer(value) and value >= 0, do: value
  defp normalize_non_negative_integer(value) when is_float(value) and value >= 0, do: trunc(value)

  defp normalize_non_negative_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed, ""} when parsed >= 0 -> parsed
      _other -> nil
    end
  end

  defp normalize_non_negative_integer(_value), do: nil

  defp normalize_number(value) when is_integer(value) or is_float(value), do: value

  defp normalize_number(value) when is_binary(value) do
    value = String.trim(value)

    cond do
      value == "" ->
        nil

      String.contains?(value, ".") ->
        case Float.parse(value) do
          {parsed, ""} -> parsed
          _other -> nil
        end

      true ->
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _other -> nil
        end
    end
  end

  defp normalize_number(_value), do: nil

  defp normalize_datetime(%DateTime{} = value), do: DateTime.truncate(value, :second)

  defp normalize_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(String.trim(value)) do
      {:ok, parsed, _offset} -> DateTime.truncate(parsed, :second)
      _other -> nil
    end
  end

  defp normalize_datetime(_value), do: nil
end
