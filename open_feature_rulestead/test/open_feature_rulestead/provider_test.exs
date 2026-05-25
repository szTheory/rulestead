defmodule OpenFeatureRulestead.ProviderTest do
  # Async false because we modify app env
  use ExUnit.Case, async: false

  alias OpenFeature.ResolutionDetails
  alias OpenFeatureRulestead.Provider
  alias Rulestead.Context
  alias Rulestead.Result

  defmodule MockRuntime do
    def evaluate("test_env", "my_bool_flag", %Context{} = context) do
      send(self(), {:runtime_context, context})

      {:ok,
       %Result{
         enabled?: true,
         value: true,
         variant: "on",
         reason: :rule_match,
         matched_rule: "rule_1",
         flag_version: 2,
         cache_age_ms: 150
       }}
    end

    def evaluate("test_env", "my_string_flag", _context) do
      {:ok,
       %Result{
         enabled?: true,
         value: "blue",
         variant: "blue_variant",
         reason: :rule_match,
         matched_rule: "color_rule",
         flag_version: 1,
         cache_age_ms: 0
       }}
    end

    def evaluate("test_env", "missing_flag", _context) do
      {:error, %Rulestead.Error{type: :flag_not_found, message: "not found", domain: :runtime}}
    end

    def evaluate("test_env", "default_string_flag", _context) do
      {:ok,
       %Result{
         enabled?: true,
         value: nil,
         variant: nil,
         reason: :default,
         matched_rule: nil,
         flag_version: nil,
         cache_age_ms: nil
       }}
    end
  end

  setup do
    Application.put_env(:open_feature_rulestead, :runtime_module, MockRuntime)

    on_exit(fn ->
      Application.delete_env(:open_feature_rulestead, :runtime_module)
    end)

    provider = %Provider{}
    {:ok, provider} = Provider.initialize(provider, "test_env", %{})
    %{provider: provider}
  end

  test "initialize requires environment_key and returns ready state" do
    provider = %Provider{}
    assert {:ok, ready_provider} = Provider.initialize(provider, "env_key", %{})
    assert ready_provider.state == :ready
    assert ready_provider.environment_key == "env_key"

    assert {:error, :invalid_context} = Provider.initialize(provider, nil, %{})
    assert {:error, :invalid_context} = Provider.initialize(provider, "", %{})
  end

  test "resolve_boolean_value delegates to Runtime and returns mapped ResolutionDetails", %{
    provider: provider
  } do
    openfeature_context = %{
      "targetingKey" => "user-123",
      "tenantKey" => "acme",
      "region" => "eu-west-1"
    }

    assert {:ok, %ResolutionDetails{} = details} =
             Provider.resolve_boolean_value(provider, "my_bool_flag", false, openfeature_context)

    assert details.value == true
    assert details.reason == :targeting_match
    assert details.variant == "on"

    assert_received {:runtime_context, %Context{} = runtime_context}
    assert runtime_context.targeting_key == "user-123"
    assert runtime_context.tenant_key == "acme"
    assert runtime_context.attributes == %{"region" => "eu-west-1"}
  end

  test "Metadata in ResolutionDetails includes matched_rule, flag_version, and cache_age_ms from Rulestead.Result",
       %{provider: provider} do
    assert {:ok, %ResolutionDetails{} = details} =
             Provider.resolve_string_value(provider, "my_string_flag", "red", %{})

    assert details.value == "blue"
    assert details.reason == :targeting_match
    assert details.variant == "blue_variant"

    assert details.flag_metadata == %{
             "matched_rule" => "color_rule",
             "flag_version" => 1,
             "cache_age_ms" => 0
           }
  end

  test "uses the caller default for non-boolean default resolutions", %{provider: provider} do
    assert {:ok, %ResolutionDetails{} = details} =
             Provider.resolve_string_value(provider, "default_string_flag", "fallback", %{})

    assert details.value == "fallback"
    assert details.reason == :default
    assert details.flag_metadata == %{}
  end

  test "resolves values appropriately for unmocked/missing flags", %{provider: provider} do
    assert {:error, :flag_not_found} =
             Provider.resolve_boolean_value(provider, "missing_flag", false, %{})
  end
end
