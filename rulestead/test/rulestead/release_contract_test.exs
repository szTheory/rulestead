defmodule Rulestead.ReleaseContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.{Admin.Policy, Config, Context, Error, Result, Store, Telemetry}

  @api_stability_path Path.expand("../../../guides/api_stability.md", __DIR__)
  @root_changelog_path Path.expand("../../CHANGELOG.md", __DIR__)
  @admin_changelog_path Path.expand("../../../rulestead_admin/CHANGELOG.md", __DIR__)

  @root_exports [
    archive_flag: 1,
    archive_flag!: 1,
    create_flag: 1,
    create_flag: 2,
    diagnostics: 0,
    enabled?: 2,
    engage_kill_switch: 1,
    engage_kill_switch: 3,
    engage_kill_switch: 4,
    evaluate: 2,
    evaluate: 3,
    evaluate!: 2,
    evaluate!: 3,
    explain: 2,
    explain_flag: 3,
    explain_flag: 4,
    fetch_flag: 1,
    fetch_flag: 2,
    fetch_flag: 3,
    fetch_flag!: 2,
    fetch_flag!: 3,
    get_value: 3,
    get_variant: 2,
    list_audiences: 0,
    list_audiences: 1,
    list_audit_events: 0,
    list_audit_events: 1,
    list_environments: 0,
    list_environments: 1,
    list_flags: 0,
    list_flags: 1,
    list_flags!: 0,
    list_flags!: 1,
    publish_ruleset: 1,
    publish_ruleset!: 1,
    record_evaluation: 1,
    record_evaluation: 3,
    release_kill_switch: 1,
    release_kill_switch: 3,
    release_kill_switch: 4,
    rollback_audit_event: 1,
    rollback_audit_event: 2,
    save_draft_ruleset: 1,
    save_draft_ruleset!: 1,
    simulate_flag: 3,
    simulate_flag: 4,
    update_flag: 1,
    update_flag: 2,
    update_flag: 3,
    version: 0
  ]

  @telemetry_exports [
    attach_many: 4,
    base_metadata: 2,
    base_metadata: 3,
    command_metadata: 1,
    command_metadata: 2,
    detach: 1,
    execute: 3,
    metadata: 1,
    result_metadata: 2,
    result_metadata: 3,
    runtime_metadata: 1,
    runtime_metadata: 2,
    span: 3
  ]

  @store_callbacks [
    archive_flag: 1,
    create_flag: 1,
    engage_kill_switch: 1,
    fetch_flag: 1,
    fetch_snapshot: 1,
    list_audiences: 1,
    list_audit_events: 1,
    list_environments: 1,
    list_flags: 1,
    publish_ruleset: 1,
    record_evaluation: 1,
    release_kill_switch: 1,
    rollback_audit_event: 1,
    save_draft_ruleset: 1,
    update_flag: 1
  ]

  @telemetry_events [
    [:rulestead, :eval, :decide, :start],
    [:rulestead, :eval, :decide, :stop],
    [:rulestead, :eval, :decide, :exception],
    [:rulestead, :runtime, :cache, :hit],
    [:rulestead, :runtime, :cache, :miss],
    [:rulestead, :runtime, :cache, :refresh],
    [:rulestead, :runtime, :cache, :stale_used],
    [:rulestead, :runtime, :snapshot, :published],
    [:rulestead, :runtime, :snapshot, :applied],
    [:rulestead, :store, :read, :start],
    [:rulestead, :store, :read, :stop],
    [:rulestead, :store, :read, :exception],
    [:rulestead, :store, :write, :start],
    [:rulestead, :store, :write, :stop],
    [:rulestead, :store, :write, :exception],
    [:rulestead, :admin, :mutation, :start],
    [:rulestead, :admin, :mutation, :stop]
  ]

  @shared_metadata_keys [
    :flag_key,
    :flag_type,
    :environment,
    :snapshot_version,
    :cache_age_ms,
    :reason,
    :has_targeting_key?,
    :matched_rule_count
  ]

  @optional_metadata_keys [:operation, :source, :refresh_status, :audit_action, :error_kind]

  @config_top_level_keys [:environment_key, :plug, :live_view, :oban, :runtime, :tenancy]
  @plug_keys [:context_assign, :targeting_key_sources]
  @live_view_keys [:context_assign, :targeting_key_sources, :assign_flags_mode]
  @oban_keys [:enabled, :context_key, :middlewares]
  @runtime_keys [:api, :notifier, :health_peer_provider, :pubsub, :pubsub_topic]
  @tenancy_keys [:module]

  test "api stability guide states the explicit public and private boundary" do
    contract = File.read!(@api_stability_path)

    assert contract =~ "`guides/api_stability.md` is the v0.1.0 release contract"
    assert contract =~ "## Stable `rulestead` Modules"
    assert contract =~ "## Stable `rulestead_admin` Boundary"
    assert contract =~ "## Non-Public Surface"

    assert contract =~ "RulesteadAdmin.Live.*"
    assert contract =~ "RulesteadAdmin.Components.*"
    assert contract =~ "socket assigns"
    assert contract =~ "DOM structure, CSS classes, and test selectors"
    assert contract =~ "The `env` query parameter is the canonical environment selector"

    assert contract =~ "Rulestead.RuleEngine"
    assert contract =~ "Rulestead.EvaluationCache"
    assert contract =~ "Rulestead.AuditStore"
    assert contract =~ "Rulestead.ActorResolver"
    assert contract =~ "excluded from the stability contract"
  end

  test "package changelogs point at the shared api stability contract" do
    assert File.read!(@root_changelog_path) =~ "../guides/api_stability.md"
    assert File.read!(@admin_changelog_path) =~ "../guides/api_stability.md"
  end

  test "the root module exposes the locked v0.1.0 public function catalog" do
    expected = MapSet.new(@root_exports)
    actual = MapSet.new(Rulestead.__info__(:functions))
    assert MapSet.subset?(expected, actual)
  end

  test "public helper modules keep their locked exports and callbacks" do
    assert Enum.sort(Context.__info__(:functions)) == [__struct__: 0, __struct__: 1, new: 1, normalize: 1]
    assert Enum.sort(Result.__info__(:functions)) == [__struct__: 0, __struct__: 1, new: 1, normalize: 1]

    assert Enum.sort(Error.__info__(:functions)) ==
             [__struct__: 0, __struct__: 1, domains: 0, exception: 1, leaf_types: 0, message: 1, new: 1, normalize: 1]

    expected_telemetry = MapSet.new(@telemetry_exports ++ [dispatch: 4])
    actual_telemetry = MapSet.new(Telemetry.__info__(:functions))
    assert MapSet.subset?(expected_telemetry, actual_telemetry)

    assert Enum.sort(Config.__info__(:functions)) ==
             [
               defaults: 0,
               load: 0,
               load: 1,
               schema: 0,
               validate: 0,
               validate: 1,
               validate!: 0,
               validate!: 1,
               validate_optional_module: 1,
               validate_pubsub: 1
             ]

    expected_store = MapSet.new(@store_callbacks)
    actual_store = MapSet.new(Store.behaviour_info(:callbacks))
    assert MapSet.subset?(expected_store, actual_store)
    assert Enum.sort(Policy.behaviour_info(:callbacks)) == [allow_self_approval?: 4, can?: 4, change_request_required?: 4]
  end

  test "public structs keep the documented fields and closed atom sets" do
    assert context_fields() == [:actor, :attributes, :environment, :request_id, :session_id, :strict?, :targeting_key, :tenant_key]

    assert result_fields() ==
             [:cache_age_ms, :debug_trace, :enabled?, :flag_key, :flag_version, :matched_rule, :reason, :value, :variant]

    assert error_fields() == [:__exception__, :cause, :details, :domain, :message, :metadata, :plug_status, :type]

    assert Error.domains() == [:evaluation, :ruleset, :kill_switch, :config, :store, :auth]

    assert Error.leaf_types() == [
             :flag_not_found,
             :environment_not_found,
             :snapshot_not_found,
             :ruleset_not_found,
             :missing_targeting_key,
             :repo_not_configured,
             :repo_ambiguous,
             :store_not_configured,
             :store_adapter_invalid,
             :store_unavailable,
             :invalid_command,
             :invalid_ruleset,
             :variant_weights_invalid,
             :invalid_value_projection,
             :malformed_runtime_data,
             :flag_archived,
             :unauthorized,
             :kill_switch_active,
             :not_implemented
           ]
  end

  test "telemetry metadata stays within the documented bounded key catalog" do
    metadata =
      Telemetry.metadata(%{
        flag_key: "checkout-redesign",
        flag_type: :release,
        environment: "prod",
        snapshot_version: 3,
        cache_age_ms: 12,
        reason: :rule_match,
        has_targeting_key?: true,
        matched_rule_count: 1,
        operation: "publish_ruleset",
        source: :cache,
        refresh_status: :ok,
        audit_action: "publish_ruleset",
        error_kind: :exception,
        actor: %{id: 1},
        traits: %{email: "secret@example.com"},
        value: true
      })

    assert Map.keys(metadata) |> Enum.sort() == Enum.sort(@shared_metadata_keys ++ @optional_metadata_keys)
    refute Map.has_key?(metadata, :actor)
    refute Map.has_key?(metadata, :traits)
    refute Map.has_key?(metadata, :value)
  end

  test "the documented telemetry event catalog stays listed in the contract doc" do
    contract = File.read!(@api_stability_path)

    for event <- @telemetry_events do
      assert contract =~ "`#{inspect(event)}`"
    end
  end

  test "the host config schema keeps the documented closed keys and enum values" do
    schema = Config.schema()

    assert Keyword.keys(schema) == @config_top_level_keys
    assert nested_schema_keys(schema, :plug) == @plug_keys
    assert nested_schema_keys(schema, :live_view) == @live_view_keys
    assert nested_schema_keys(schema, :oban) == @oban_keys
    assert nested_schema_keys(schema, :runtime) == @runtime_keys
    assert nested_schema_keys(schema, :tenancy) == @tenancy_keys

    assert schema
           |> nested_schema(:live_view)
           |> Keyword.fetch!(:assign_flags_mode)
           |> Keyword.fetch!(:type) == {:in, [:enabled, :variant, :value, :evaluate]}
  end

  defp context_fields do
    Context.__struct__()
    |> Map.delete(:__struct__)
    |> Map.keys()
    |> Enum.sort()
  end

  defp result_fields do
    Result.__struct__()
    |> Map.delete(:__struct__)
    |> Map.keys()
    |> Enum.sort()
  end

  defp error_fields do
    Error.__struct__()
    |> Map.delete(:__struct__)
    |> Map.keys()
    |> Enum.sort()
  end

  defp nested_schema_keys(schema, key) do
    schema
    |> nested_schema(key)
    |> Keyword.keys()
  end

  defp nested_schema(schema, key) do
    schema
    |> Keyword.fetch!(key)
    |> Keyword.fetch!(:keys)
  end
end
