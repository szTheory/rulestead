defmodule Rulestead.Result do
  @moduledoc """
  Stable Phase 3 evaluation result.
  """

  @enforce_keys []
  defstruct value: nil,
            enabled?: false,
            variant: nil,
            reason: :default,
            matched_rule: nil,
            flag_key: nil,
            flag_version: nil,
            cache_age_ms: nil,
            debug_trace: nil

  @type reason :: :rule_match | :default | :targeting_key_missing | :flag_off | :error

  @type debug_trace :: map() | nil

  @type t :: %__MODULE__{
          value: term(),
          enabled?: boolean(),
          variant: String.t() | nil,
          reason: reason(),
          matched_rule: String.t() | nil,
          flag_key: String.t() | nil,
          flag_version: integer() | nil,
          cache_age_ms: integer() | nil,
          debug_trace: debug_trace()
        }

  @reasons [:rule_match, :default, :targeting_key_missing, :flag_off, :error]

  @spec new(t() | keyword() | map()) :: t()
  def new(%__MODULE__{} = result), do: normalize(result)

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      value: Map.get(attrs, :value),
      enabled?: normalize_boolean(Map.get(attrs, :enabled?, false)),
      variant: normalize_string(Map.get(attrs, :variant)),
      reason: normalize_reason(Map.get(attrs, :reason)),
      matched_rule: normalize_string(Map.get(attrs, :matched_rule)),
      flag_key: normalize_string(Map.get(attrs, :flag_key)),
      flag_version: normalize_integer(Map.get(attrs, :flag_version)),
      cache_age_ms: normalize_integer(Map.get(attrs, :cache_age_ms)),
      debug_trace: normalize_debug_trace(Map.get(attrs, :debug_trace))
    }
  end

  @spec normalize(t() | keyword() | map()) :: t()
  def normalize(%__MODULE__{} = result), do: new(Map.from_struct(result))
  def normalize(attrs) when is_list(attrs) or is_map(attrs), do: new(attrs)

  defp normalize_reason(reason) when reason in @reasons, do: reason
  defp normalize_reason(_reason), do: :error

  defp normalize_debug_trace(trace) when is_map(trace), do: trace
  defp normalize_debug_trace(nil), do: nil
  defp normalize_debug_trace(_trace), do: nil

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(_value), do: nil

  defp normalize_integer(value) when is_integer(value), do: value
  defp normalize_integer(_value), do: nil

  defp normalize_boolean(value) when is_boolean(value), do: value
  defp normalize_boolean(_value), do: false
end
