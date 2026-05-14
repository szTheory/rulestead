defmodule OpenFeatureRulestead.Provider do
  @behaviour OpenFeature.Provider

  alias OpenFeature.ResolutionDetails
  alias OpenFeatureRulestead.ContextMapper
  alias Rulestead.Runtime
  alias Rulestead.Result

  defstruct name: "Rulestead", state: :not_ready, environment_key: nil

  @impl true
  def initialize(%__MODULE__{} = provider, domain, _context)
      when is_binary(domain) and domain != "" do
    {:ok, %{provider | state: :ready, environment_key: domain}}
  end

  def initialize(%__MODULE__{}, _domain, _context) do
    {:error, :invalid_context}
  end

  @impl true
  def shutdown(_provider), do: :ok

  @impl true
  def resolve_boolean_value(provider, key, default, context) do
    do_resolve(provider, key, default, context, :boolean)
  end

  @impl true
  def resolve_string_value(provider, key, default, context) do
    do_resolve(provider, key, default, context, :string)
  end

  @impl true
  def resolve_number_value(provider, key, default, context) do
    do_resolve(provider, key, default, context, :number)
  end

  @impl true
  def resolve_map_value(provider, key, default, context) do
    do_resolve(provider, key, default, context, :map)
  end

  defp do_resolve(provider, key, default, context, type) do
    translated_context = ContextMapper.translate(context)
    runtime = Application.get_env(:open_feature_rulestead, :runtime_module, Runtime)

    case runtime.evaluate(provider.environment_key, key, translated_context) do
      {:ok, %Result{} = result} ->
        value = extract_value(result, type, default)

        flag_metadata =
          %{
            "matched_rule" => result.matched_rule,
            "flag_version" => result.flag_version,
            "cache_age_ms" => result.cache_age_ms
          }
          |> Enum.reject(fn {_, v} -> is_nil(v) end)
          |> Map.new()

        resolution = %ResolutionDetails{
          value: value,
          reason: map_reason(result.reason),
          variant: result.variant,
          flag_metadata: flag_metadata
        }

        {:ok, resolution}

      {:error, error} ->
        # Follow error normalization shared pattern
        {:error, map_error_code(error)}
    end
  end

  defp extract_value(%Result{enabled?: enabled?, value: value, reason: reason}, type, default) do
    case type do
      :boolean ->
        enabled?

      _other ->
        if reason == :default and is_nil(value) do
          default
        else
          if is_nil(value), do: default, else: value
        end
    end
  end

  defp map_reason(:rule_match), do: :targeting_match
  defp map_reason(:default), do: :default
  # Or :default ?
  defp map_reason(:targeting_key_missing), do: :error
  defp map_reason(:flag_off), do: :disabled
  defp map_reason(:error), do: :error
  defp map_reason(_), do: :unknown

  defp map_error_code(%Rulestead.Error{type: type}) do
    case type do
      :flag_not_found -> :flag_not_found
      :store_unavailable -> :provider_not_ready
      :invalid_context -> :invalid_context
      :parse_error -> :parse_error
      :type_mismatch -> :type_mismatch
      _ -> :general
    end
  end

  defp map_error_code(_), do: :general
end
