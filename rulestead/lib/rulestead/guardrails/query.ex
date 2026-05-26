defmodule Rulestead.Guardrails.Query do
  @moduledoc false

  alias Rulestead.{Context, Store.Command}

  @enforce_keys [:signal_key]
  defstruct [
    :signal_key,
    :environment_key,
    :tenant_key,
    :environment_scope,
    :tenant_scope,
    :scope_source,
    :threshold_operator,
    :threshold_value,
    :freshness_window_seconds,
    :min_sample_size,
    metadata: %{}
  ]

  @threshold_operators [:lt, :lte, :gt, :gte]
  @environment_scopes [:environment]
  @tenant_scopes [:required, :not_applicable]
  @scope_sources ["explicit", "host_resolved", "single_tenant"]

  @type t :: %__MODULE__{
          signal_key: String.t(),
          environment_key: String.t() | nil,
          tenant_key: String.t() | nil,
          environment_scope: atom(),
          tenant_scope: atom(),
          scope_source: String.t(),
          threshold_operator: atom() | nil,
          threshold_value: number() | nil,
          freshness_window_seconds: non_neg_integer() | nil,
          min_sample_size: non_neg_integer() | nil,
          metadata: map()
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = query), do: query |> Map.from_struct() |> new()

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    context = attrs |> Map.get(:context, Map.get(attrs, "context")) |> normalize_context()
    signal_key = required_string(attrs, :signal_key) || "unknown_signal"
    tenant_key = optional_string(attrs, :tenant_key) || context.tenant_key

    %__MODULE__{
      signal_key: signal_key,
      environment_key: optional_string(attrs, :environment_key) || context.environment,
      tenant_key: tenant_key,
      environment_scope: normalize_environment_scope(optional_value(attrs, :environment_scope)),
      tenant_scope: normalize_tenant_scope(optional_value(attrs, :tenant_scope), tenant_key),
      scope_source: normalize_scope_source(optional_value(attrs, :scope_source), tenant_key),
      threshold_operator:
        normalize_threshold_operator(optional_value(attrs, :threshold_operator)),
      threshold_value: normalize_number(optional_value(attrs, :threshold_value)),
      freshness_window_seconds:
        normalize_non_negative_integer(
          optional_value(attrs, :freshness_window_seconds) ||
            optional_value(attrs, :max_age_seconds)
        ),
      min_sample_size: normalize_non_negative_integer(optional_value(attrs, :min_sample_size)),
      metadata:
        attrs
        |> optional_value(:metadata)
        |> Command.GovernanceSupport.normalize_metadata()
    }
  end

  @spec from_context(String.t() | atom(), Context.t() | map() | keyword(), keyword()) :: t()
  def from_context(signal_key, context, opts \\ []) do
    opts
    |> Keyword.put(:signal_key, signal_key)
    |> Keyword.put(:context, Context.normalize(context))
    |> new()
  end

  @spec metadata(t() | map() | keyword()) :: map()
  def metadata(query) do
    query = new(query)

    %{
      signal_key: query.signal_key,
      environment_key: query.environment_key,
      tenant_key: query.tenant_key,
      environment_scope: query.environment_scope,
      tenant_scope: query.tenant_scope,
      scope_source: query.scope_source,
      threshold_operator: query.threshold_operator,
      threshold_value: query.threshold_value,
      freshness_window_seconds: query.freshness_window_seconds,
      min_sample_size: query.min_sample_size,
      metadata: query.metadata
    }
  end

  @spec threshold_operators() :: [atom()]
  def threshold_operators, do: @threshold_operators

  @spec environment_scopes() :: [atom()]
  def environment_scopes, do: @environment_scopes

  @spec tenant_scopes() :: [atom()]
  def tenant_scopes, do: @tenant_scopes

  defp normalize_context(nil), do: Context.new(%{})
  defp normalize_context(context), do: Context.normalize(context)

  defp required_string(attrs, key), do: optional_string(attrs, key)

  defp optional_string(attrs, key) do
    attrs
    |> optional_value(key)
    |> Command.GovernanceSupport.normalize_string()
  end

  defp optional_value(attrs, key),
    do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp normalize_threshold_operator(operator) when operator in @threshold_operators, do: operator

  defp normalize_threshold_operator(operator) when is_binary(operator) do
    operator
    |> String.trim()
    |> case do
      "lt" -> :lt
      "lte" -> :lte
      "gt" -> :gt
      "gte" -> :gte
      _other -> nil
    end
  end

  defp normalize_threshold_operator(_operator), do: nil

  defp normalize_environment_scope(scope) when scope in @environment_scopes, do: scope
  defp normalize_environment_scope("environment"), do: :environment
  defp normalize_environment_scope(_scope), do: :environment

  defp normalize_tenant_scope(scope, _tenant_key) when scope in @tenant_scopes, do: scope
  defp normalize_tenant_scope("required", _tenant_key), do: :required
  defp normalize_tenant_scope("not_applicable", _tenant_key), do: :not_applicable
  defp normalize_tenant_scope(nil, nil), do: :not_applicable
  defp normalize_tenant_scope(_scope, _tenant_key), do: :required

  defp normalize_scope_source(scope_source, tenant_key) do
    normalized = Command.GovernanceSupport.normalize_string(scope_source)

    cond do
      normalized in @scope_sources ->
        normalized

      is_binary(tenant_key) ->
        "explicit"

      true ->
        "host_resolved"
    end
  end

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
end
