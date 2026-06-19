defmodule OpenFeatureRulestead.Provider do
  @moduledoc """
  OpenFeature provider implementation backed by `Rulestead.Runtime`.

  This module implements the `OpenFeature.Provider` behaviour, bridging the
  standard OpenFeature SDK evaluation API to Rulestead's deterministic flag
  evaluation engine.

  ## Initialization

  Create a provider struct and initialize it with the Rulestead environment
  (domain) you want to evaluate against:

      provider = %OpenFeatureRulestead.Provider{}
      {:ok, provider} =
        OpenFeatureRulestead.Provider.initialize(provider, "production", %{})
      OpenFeature.set_provider(provider, domain: "production")

  The `domain` argument becomes the provider's `environment_key` and is
  required — `initialize/3` returns `{:error, :invalid_context}` when the
  domain is missing or blank.

  ## Context translation

  OpenFeature evaluation context is translated into `%Rulestead.Context{}` via
  `OpenFeatureRulestead.ContextMapper.translate/1` before being passed to
  `Rulestead.Runtime.evaluate/3`. See `OpenFeatureRulestead.ContextMapper` for
  the full field mapping.

  ## Resolution metadata

  The provider exposes the following scalar fields from `Rulestead.Result`
  through the OpenFeature `flag_metadata` map:

  - `"matched_rule"` — which rule produced the result
  - `"flag_version"` — version of the flag definition evaluated
  - `"cache_age_ms"` — age of the cached snapshot at evaluation time

  The full internal Rulestead explanation payload is not promised through the
  OpenFeature metadata surface.
  """

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
