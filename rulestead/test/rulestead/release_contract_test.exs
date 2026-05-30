defmodule Rulestead.ReleaseContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.{Admin.Policy, Config, Context, Error, Result, Runtime, Store, Telemetry}
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.DependencyValidator

  @api_stability_path Path.expand("../../../guides/api_stability.md", __DIR__)
  @root_readme_path Path.expand("../../../README.md", __DIR__)
  @runtime_readme_path Path.expand("../../README.md", __DIR__)
  @admin_readme_path Path.expand("../../../rulestead_admin/README.md", __DIR__)
  @upgrading_path Path.expand("../../../guides/introduction/upgrading.md", __DIR__)
  @demo_readme_path Path.expand("../../../examples/demo/README.md", __DIR__)
  @maintaining_path Path.expand("../../../MAINTAINING.md", __DIR__)
  @flag_lifecycle_path Path.expand("../../../guides/flows/flag-lifecycle.md", __DIR__)
  @root_changelog_path Path.expand("../../CHANGELOG.md", __DIR__)
  @admin_changelog_path Path.expand("../../../rulestead_admin/CHANGELOG.md", __DIR__)
  @product_boundary_path Path.expand("../../../guides/introduction/product-boundary.md", __DIR__)

  # public API exports
  @root_exports [
    archive_flag: 1,
    archive_flag!: 1,
    apply_audience_mutation: 1,
    apply_audience_mutation: 2,
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
    list_audience_dependencies: 0,
    list_audience_dependencies: 1,
    list_environments: 0,
    list_environments: 1,
    list_flags: 0,
    list_flags: 1,
    list_flags!: 0,
    list_flags!: 1,
    preview_audience_impact: 1,
    preview_audience_impact: 2,
    preview_audience_impact: 3,
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

  # Store callbacks
  @store_callbacks [
    apply_audience_mutation: 1,
    archive_flag: 1,
    create_flag: 1,
    engage_kill_switch: 1,
    fetch_flag: 1,
    fetch_snapshot: 1,
    list_audiences: 1,
    list_audit_events: 1,
    list_audience_dependencies: 1,
    list_environments: 1,
    list_flags: 1,
    preview_audience_impact: 1,
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

  @documented_supported_facades ["Rulestead.Runtime", "Rulestead.TestHelpers"]

  @documented_runtime_functions [
    :evaluate,
    :enabled?,
    :get_value,
    :get_variant,
    :explain,
    :diagnostics
  ]

  @documented_test_helper_functions [
    "with_flag/3",
    "put_flag/3",
    "clear_flags/0",
    "seed_bucket/3",
    "assert_flag_evaluated/2"
  ]

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

  test "root and sibling docs route readers into the lifecycle spine without standalone admin drift" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    lifecycle_guide = File.read!(@flag_lifecycle_path)

    assert root_readme =~ "guides/flows/flag-lifecycle.md"
    assert lifecycle_guide =~ "birth to retirement"

    assert runtime_readme =~ "hexdocs.pm/rulestead/flag-lifecycle"
    refute runtime_readme =~ ~r/\]\(\.\.\//

    assert admin_readme =~ "hexdocs.pm/rulestead/flag-lifecycle"
    assert admin_readme =~ "mounted companion"

    assert lifecycle_guide =~ "mix rulestead.lifecycle"
    assert lifecycle_guide =~ "archive_candidate"
    assert lifecycle_guide =~ "preview, confirm, and audit"
  end

  test "public release docs state the shipped repo truth and bounded proof posture" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    upgrading = File.read!(@upgrading_path)
    demo_readme = File.read!(@demo_readme_path)
    maintaining = File.read!(@maintaining_path)

    assert root_readme =~ "v1.0.0"
    assert root_readme =~ "0.1.x"
    assert root_readme =~ "Two version lines"
    assert root_readme =~ "MAINTAINING.md"
    assert root_readme =~ "adoption-lab"
    assert root_readme =~ "rulestead_admin/README.md"
    refute root_readme =~ "Proof today"
    refute root_readme =~ "mix verify.phase"
    refute root_readme =~ "flag_live/form_test"
    refute root_readme =~ "cleanup_test"
    refute root_readme =~ "admin_mount_test"

    assert maintaining =~ "verify.release_publish"
    assert maintaining =~ "verify.release_parity"
    assert maintaining =~ "RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
    assert maintaining =~ "mounted companion proof"

    assert runtime_readme =~ "0.1.x"
    assert runtime_readme =~ "hexdocs.pm/rulestead"
    refute runtime_readme =~ ~r/\]\(\.\.\//
    refute runtime_readme =~ "mix verify.phase"

    assert admin_readme =~ "0.1.x"
    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "not a standalone control plane"
    assert admin_readme =~ "host owns auth"
    assert admin_readme =~ "it wins over remembered session state"
    refute admin_readme =~ ~r/\]\(\.\.\//

    assert upgrading =~ "v1.0.0"
    assert upgrading =~ "0.1.x"
    assert upgrading =~ "MAINTAINING.md"

    assert demo_readme =~ "0.1.x"
    assert demo_readme =~ "verify.release_publish"
    assert demo_readme =~ "verify.release_parity"
    assert demo_readme =~ "FleetDesk Adoption Lab"
    assert demo_readme =~ "adoption lab"
  end

  test "maintainer guidance matches the shipped release and support truth" do
    maintaining = File.read!(@maintaining_path)

    banned_phrases = [
      ["first public Hex release", "target is"],
      ["first public Hex release", "should happen only after"],
      ["planned for", "`v0.6.0`"],
      ["Phase 43", "restores"],
      ["aggregates `lint`, `test`, and `integration-placeholder`", "from `ci.yml`"]
    ]

    assert maintaining =~ "v1.0.0"
    assert maintaining =~ "2026-05-21"
    assert maintaining =~ "0.1.x"
    assert maintaining =~ "mounted companion"
    assert maintaining =~ "examples/demo/"
    assert maintaining =~ "mix verify.release_publish <version>"
    assert maintaining =~ "mix verify.release_parity <version>"
    assert maintaining =~ "RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
    assert maintaining =~ "mounted companion proof"
    assert maintaining =~ "mounted-proof-relevant paths change"
    assert maintaining =~ "integration-placeholder"

    for fragments <- banned_phrases do
      phrase = Enum.join(fragments, " ")
      refute maintaining =~ phrase
    end
  end

  test "guarded rollout support truth stays bounded across root package and maintainer docs" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    maintaining = File.read!(@maintaining_path)
    product_boundary = File.read!(@product_boundary_path)

    assert root_readme =~ ~r/guarded\s+rollouts/i
    assert root_readme =~ "product-boundary.md"
    refute root_readme =~ "mix verify.phase"

    assert product_boundary =~ "fail-closed"
    assert product_boundary =~ "hold/rollback"
    assert product_boundary =~ "Guarded rollouts"

    assert maintaining =~ "guarded rollout foundations proof"

    assert maintaining =~
             "RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh"

    refute runtime_readme =~ "mix verify.phase"

    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "not a standalone"

    assert maintaining =~ "VER-01"

    forbidden_phrases = [
      "automatic progressive delivery platform",
      "built-in observability",
      "real-time dashboards",
      "self-healing rollouts",
      "vendor metrics integrations",
      "experiment statistics",
      "standalone rulestead_admin"
    ]

    docs = [root_readme, runtime_readme, admin_readme, maintaining]

    for phrase <- forbidden_phrases, doc <- docs do
      refute doc =~ phrase
    end
  end

  test "reusable targeting deepening support truth stays bounded across root package and maintainer docs" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    maintaining = File.read!(@maintaining_path)
    product_boundary = File.read!(@product_boundary_path)

    refute root_readme =~ "mix verify.phase"
    assert root_readme =~ "reusable audiences"
    assert root_readme =~ "product-boundary.md"

    assert product_boundary =~ "preview→confirm→audit"
    assert product_boundary =~ "Reusable audiences"
    assert product_boundary =~ "fail-closed"

    assert maintaining =~ "mix verify.phase56"
    assert maintaining =~ "Reusable Targeting Deepening Proof"

    assert maintaining =~
             "RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh"

    refute runtime_readme =~ "mix verify.phase"

    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "not a standalone"

    assert maintaining =~ "54-HANDOFF-CHECKLIST"
    assert maintaining =~ "55-HANDOFF-CHECKLIST"
    assert maintaining =~ "VER-01"

    assert maintaining =~ "promotion"

    forbidden_phrases = [
      "standalone rulestead_admin",
      "standalone control plane",
      "graph visualizer",
      "bulk automation",
      "one-click bulk",
      "authoritative affected-user",
      "real user population",
      "built-in observability",
      "Rulestead dashboard",
      "metrics ingestion",
      "metrics warehouse",
      "automatic progressive delivery platform",
      "segment library",
      "manage segments"
    ]

    operator_docs = [root_readme, maintaining]

    for phrase <- forbidden_phrases, doc <- operator_docs do
      refute doc =~ phrase
    end
  end

  test "blast radius governance support truth stays bounded across root package and maintainer docs" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    maintaining = File.read!(@maintaining_path)
    product_boundary = File.read!(@product_boundary_path)

    refute root_readme =~ "mix verify.phase"
    assert root_readme =~ "blast-radius governance"
    assert root_readme =~ "product-boundary.md"

    assert product_boundary =~ ~r/blast[- ]radius/i
    assert product_boundary =~ "Change requests"
    assert product_boundary =~ "fail-closed"

    refute runtime_readme =~ "mix verify.phase"

    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "not a standalone"

    assert maintaining =~ "Blast Radius Governance Proof"
    assert maintaining =~ "mix verify.phase60"
    assert maintaining =~ "VER-01"
    assert maintaining =~ "57-blast-radius-threshold-contract"

    assert maintaining =~
             "RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh"

    forbidden_phrases = [
      "standalone rulestead_admin",
      "standalone control plane",
      "parallel governance workflow",
      "authoritative affected-user",
      "real user population",
      "built-in observability",
      "Rulestead dashboard",
      "metrics ingestion",
      "automatic progressive delivery platform"
    ]

    operator_docs = [root_readme, maintaining]

    for phrase <- forbidden_phrases, doc <- operator_docs do
      refute doc =~ phrase
    end
  end

  test "guarded rollout auto-advance support truth stays bounded across root package and maintainer docs" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    maintaining = File.read!(@maintaining_path)
    product_boundary = File.read!(@product_boundary_path)

    refute root_readme =~ "mix verify.phase"
    assert root_readme =~ ~r/guarded\s+rollouts/i
    assert root_readme =~ "product-boundary.md"

    assert product_boundary =~ ~r/observation[- ]window/i
    assert product_boundary =~ "auto-advance"
    assert product_boundary =~ "fail-closed"

    refute runtime_readme =~ "mix verify.phase"

    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "not a standalone"

    assert maintaining =~ "Guarded Rollout Auto-Advance Proof"
    assert maintaining =~ "mix verify.phase64"
    assert maintaining =~ "VER-01"
    assert maintaining =~ ~r/61-auto-advance-authored-contract|61-/

    assert maintaining =~
             "RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh"

    forbidden_phrases = [
      "standalone rulestead_admin",
      "standalone control plane",
      "built-in observability",
      "Rulestead dashboard",
      "metrics ingestion",
      "fleet dashboard",
      "self-healing rollouts",
      "time-based percentage rollout",
      "automatic progressive delivery platform"
    ]

    operator_docs = [root_readme, maintaining]

    for phrase <- forbidden_phrases, doc <- operator_docs do
      refute doc =~ phrase
    end
  end

  test "host preview evidence support truth stays bounded across root package and maintainer docs" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)
    maintaining = File.read!(@maintaining_path)
    product_boundary = File.read!(@product_boundary_path)

    refute root_readme =~ "mix verify.phase"
    assert root_readme =~ "product-boundary.md"

    assert product_boundary =~ "preview evidence"
    assert product_boundary =~ "Host always owns"
    assert product_boundary =~ "fail-closed"

    refute runtime_readme =~ "mix verify.phase"

    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "not a standalone"

    assert maintaining =~ "Host Preview Evidence Proof"
    assert maintaining =~ "mix verify.phase68"
    assert maintaining =~ "VER-01"
    assert maintaining =~ ~r/65-|65-host-preview-evidence/

    assert maintaining =~
             "RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh"

    forbidden_phrases = [
      "authoritative population counts",
      "fleet-wide population",
      "built-in observability",
      "Rulestead dashboard",
      "metrics ingestion",
      "fleet dashboard",
      "impression analytics platform",
      "population analytics product"
    ]

    operator_docs = [root_readme, maintaining]

    for phrase <- forbidden_phrases, doc <- operator_docs do
      refute doc =~ phrase
    end
  end

  test "quickstart teaches payload-first evaluation" do
    root_readme = File.read!(@root_readme_path)

    getting_started =
      File.read!(Path.expand("../../../guides/introduction/getting-started.md", __DIR__))

    for doc <- [root_readme, getting_started] do
      assert doc =~ "Rulestead.evaluate"
      assert doc =~ ~r/Rulestead\.Context\.new|%Rulestead\.Context\{\}/
      assert doc =~ ~r/payload|flag_payload/i
      assert doc =~ "Rulestead.Runtime"
      refute doc =~ ~r/Rulestead\.enabled\?\("[^"]+",\s*conn\)/
    end
  end

  test "quickstart Context.new examples use attributes not traits for evaluation inputs" do
    root_readme = File.read!(@root_readme_path)

    getting_started =
      File.read!(Path.expand("../../../guides/introduction/getting-started.md", __DIR__))

    for doc <- [root_readme, getting_started] do
      assert doc =~ "attributes:"
      refute doc =~ ~r/traits:\s*%\{/
    end
  end

  test "maintainer doc truth treats api_stability as live public contract" do
    maintaining = File.read!(@maintaining_path)

    refute maintaining =~ "Deferred Phase 8 artifacts"
    refute maintaining =~ "Do not create these early"
    refute maintaining =~ ~r/Phase 8, not bootstrap/
    assert maintaining =~ "Public surface contract (live)"
    assert maintaining =~ "guides/api_stability.md"
    assert maintaining =~ ~r/live|primary|semver/i
  end

  test "post-GA band closure support truth stays bounded across root package and maintainer docs" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    maintaining = File.read!(@maintaining_path)
    product_boundary = File.read!(@product_boundary_path)

    assert root_readme =~ ~r/post-GA|Post-GA/i
    assert root_readme =~ "product-boundary.md"
    refute root_readme =~ "mix verify.phase"
    refute root_readme =~ "ROL-04 remains unbuilt"
    refute root_readme =~ "GOV-01 gap"

    assert product_boundary =~ "mix verify.adopter"

    refute runtime_readme =~ "mix verify.phase"

    assert maintaining =~ "Post-GA Band Closure Proof"
    assert maintaining =~ "mix verify.phase82"
    assert maintaining =~ "mix verify.adopter"

    assert maintaining =~
             "RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh"

    refute maintaining =~ "IMP-05 partial"
  end

  test "v1.12 adoption lab support truth routes evaluators to FleetDesk proof paths" do
    root_readme = File.read!(@root_readme_path)

    adoption_lab =
      Path.expand("../../../guides/introduction/adoption-lab.md", __DIR__)
      |> File.read!()

    demo_readme = File.read!(@demo_readme_path)

    install_journey =
      Path.expand("../../../scripts/demo/install_journey.sh", __DIR__)
      |> File.read!()

    assert root_readme =~ "adoption-lab"
    refute root_readme =~ "install_journey"
    assert adoption_lab =~ "FleetDesk"
    assert adoption_lab =~ "scripts/demo/install_journey.sh"
    assert demo_readme =~ "dispatch-guarded-rollout"
    assert install_journey =~ "install_contract.sh"
  end

  test "v1.11 integration spine support truth routes adopters to first-hour path" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    maintaining = File.read!(@maintaining_path)

    assert root_readme =~ "phoenix-integration-spine"
    refute root_readme =~ "mix verify.phase"
    assert maintaining =~ "mix verify.phase82"

    spine_in_maintaining? =
      maintaining =~ "phoenix-integration-spine" or
        maintaining =~ ~r/integration spine/i

    assert spine_in_maintaining?

    assert runtime_readme =~ "phoenix-integration-spine"
    refute runtime_readme =~ "mix verify.phase"
  end

  test "the root module exposes the locked v0.1.0 public function catalog" do
    expected = MapSet.new(@root_exports)
    actual = MapSet.new(Rulestead.__info__(:functions))
    assert MapSet.subset?(expected, actual)
  end

  test "public helper modules keep their locked exports and callbacks" do
    assert Enum.sort(Context.__info__(:functions)) == [
             __struct__: 0,
             __struct__: 1,
             new: 1,
             normalize: 1
           ]

    assert Enum.sort(Result.__info__(:functions)) == [
             __struct__: 0,
             __struct__: 1,
             new: 1,
             normalize: 1
           ]

    assert Enum.sort(Error.__info__(:functions)) ==
             [
               __struct__: 0,
               __struct__: 1,
               domains: 0,
               exception: 1,
               leaf_types: 0,
               message: 1,
               new: 1,
               normalize: 1
             ]

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

    assert Enum.sort(Policy.behaviour_info(:callbacks)) == [
             allow_self_approval?: 4,
             can?: 4,
             change_request_required?: 4
           ]
  end

  test "dependency truth for promotion and manifest stays core-owned without rulestead_admin leakage" do
    assert {:list_audience_dependencies, 0} in Rulestead.__info__(:functions)
    assert {:list_audience_dependencies, 1} in Rulestead.__info__(:functions)
    assert Code.ensure_loaded?(DependencyValidator)
    assert {:validate, 2} in DependencyValidator.__info__(:functions)
    assert {:blockers?, 1} in DependencyValidator.__info__(:functions)

    core_mix_project = File.read!(Path.expand("../../mix.exs", __DIR__))
    core_public_api = File.read!(Path.expand("../../lib/rulestead.ex", __DIR__))

    # promotion + manifest dependency safety must remain in core; rulestead_admin is presentation-only.
    refute core_mix_project =~ "{:rulestead_admin"
    refute core_public_api =~ "RulesteadAdmin"
    assert File.read!(@admin_readme_path) =~ "rulestead_admin"
  end

  test "audience impact commands normalize preview and guarded mutation evidence" do
    preview =
      Command.PreviewAudienceImpact.new(:vip_users, :update,
        environment_key: :production,
        tenant_key: 123,
        before_definition: %{rules: [%{attribute: :plan}]},
        after_definition: %{"rules" => [%{"attribute" => "plan"}]},
        samples: [%{email: "secret@example.com", plan: :pro}],
        actor: %{id: 42, type: :operator, display: "Ada"},
        reason: "  evaluate blast radius  ",
        metadata: %{request_id: "req-1", password: "drop"}
      )

    assert %Command.PreviewAudienceImpact{
             environment_key: "production",
             tenant_key: "123",
             audience_key: "vip_users",
             operation: "update",
             before_definition: %{"rules" => [%{"attribute" => "plan"}]},
             after_definition: %{"rules" => [%{"attribute" => "plan"}]},
             samples: [%{"email" => "secret@example.com", "plan" => "pro"}],
             actor: %{"id" => "42", "type" => "operator", "display" => "Ada"},
             reason: "evaluate blast radius",
             metadata: %{"request_id" => "req-1"}
           } = preview

    apply =
      Command.ApplyAudienceMutation.new(%{
        environment_key: :production,
        tenant_key: 123,
        audience_key: :vip_users,
        operation: :archive,
        preview_schema_version: "1",
        preview_fingerprint: "audprev_abc",
        preview_basis: %{scope: :authored_state},
        affected_reference_keys: [:beta_flag, "checkout-redesign"],
        before_definition: %{rules: [%{attribute: :plan}]},
        after_definition: nil,
        protected_shared_targeting?: true,
        actor: %{id: 42},
        reason: "retire shared targeting",
        metadata: %{trace_id: "trace-1", token: "drop"}
      })

    assert %Command.ApplyAudienceMutation{
             environment_key: "production",
             tenant_key: "123",
             audience_key: "vip_users",
             operation: "archive",
             preview_schema_version: 1,
             preview_fingerprint: "audprev_abc",
             preview_basis: %{"scope" => "authored_state"},
             affected_reference_keys: ["beta_flag", "checkout-redesign"],
             before_definition: %{"rules" => [%{"attribute" => "plan"}]},
             after_definition: nil,
             actor: %{"id" => "42"},
             reason: "retire shared targeting",
             metadata: %{"trace_id" => "trace-1"},
             protected_shared_targeting?: true
           } = apply

    assert %Command.ListAudienceDependencies{
             environment_key: "production",
             tenant_key: "123",
             audience_key: "vip_users",
             limit: 25,
             offset: 2,
             actor: %{"id" => "42"},
             visible_audience_keys: ["beta_users", "vip_users"],
             include_redacted_placeholders?: true
           } =
             Command.ListAudienceDependencies.new(
               environment_key: :production,
               tenant_key: 123,
               audience_key: :vip_users,
               limit: 25,
               offset: 2,
               actor: %{id: 42},
               visible_audience_keys: [:vip_users, "beta_users"],
               include_redacted_placeholders?: true
             )
  end

  test "public structs keep the documented fields and closed atom sets" do
    assert context_fields() == [
             :actor,
             :attributes,
             :environment,
             :request_id,
             :session_id,
             :strict?,
             :targeting_key,
             :tenant_key
           ]

    assert result_fields() ==
             [
               :cache_age_ms,
               :debug_trace,
               :enabled?,
               :flag_key,
               :flag_version,
               :matched_rule,
               :reason,
               :value,
               :variant
             ]

    assert error_fields() == [
             :__exception__,
             :cause,
             :details,
             :domain,
             :message,
             :metadata,
             :plug_status,
             :type
           ]

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

    assert Map.keys(metadata) |> Enum.sort() ==
             Enum.sort(@shared_metadata_keys ++ @optional_metadata_keys)

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

  test "documented public surfaces stay listed in the api stability contract" do
    contract = File.read!(@api_stability_path)

    for {name, arity} <- @root_exports do
      assert contract =~ "`#{name}/#{arity}`"
    end

    for {name, arity} <- @store_callbacks do
      assert contract =~ "`#{name}/#{arity}`"
    end

    for {name, arity} <- Policy.behaviour_info(:callbacks) do
      assert contract =~ "`#{name}/#{arity}`" or contract =~ "`#{name}`"
    end

    for type <- Error.leaf_types() do
      assert contract =~ "`:#{type}`"
    end

    assert contract =~ ":tenancy"
    assert contract =~ "tenancy"

    for key <- @config_top_level_keys do
      assert contract =~ "`:#{key}`"
    end
  end

  test "supported adopter facades documented in api stability match the closed runtime catalog" do
    contract = File.read!(@api_stability_path)

    for module <- @documented_supported_facades do
      assert contract =~ module
    end

    for fun <- @documented_runtime_functions do
      assert contract =~ "`#{fun}/"
    end

    for helper <- @documented_test_helper_functions do
      assert contract =~ helper
    end

    documented_runtime = MapSet.new(@documented_runtime_functions)

    actual_runtime =
      Runtime.__info__(:functions)
      |> Enum.map(fn {name, _arity} -> name end)
      |> MapSet.new()

    assert MapSet.subset?(documented_runtime, actual_runtime)
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
