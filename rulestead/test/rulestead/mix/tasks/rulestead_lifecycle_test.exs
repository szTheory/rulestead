defmodule Rulestead.Mix.Tasks.RulesteadLifecycleTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Rulestead.Lifecycle
  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  @admin_actor %{id: 7, email: "priya@example.com", roles: [:admin]}

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    now = ~U[2026-04-23 16:00:00Z]
    Control.ensure_started()
    Control.reset!(now: now)
    Control.set_now!(now)
    Control.put_environment!(%{key: "prod", name: "Production"})

    seed_flag!(
      key: "ops-cleanup",
      owner: "ops",
      tags: ["infra"],
      expected_expiration: ~D[2026-04-20],
      permanent: false,
      environment_keys: ["prod"],
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    seed_flag!(
      key: "search-ranking",
      ownership: %{owner_ref: "growth"},
      tags: ["search"],
      expected_expiration: ~D[2026-04-28],
      permanent: false,
      environment_keys: ["prod"]
    )

    publish_flag!("ops-cleanup")
    publish_flag!("search-ranking")

    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "prod", DateTime.add(now, -7_200, :second))
    assert {:ok, _} = Rulestead.record_evaluation("search-ranking", "prod", DateTime.add(now, -2_700, :second))

    on_exit(fn ->
      Mix.Task.reenable("rulestead.lifecycle")

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end

      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    :ok
  end

  test "renders text by default with advisory filters aligned to mounted admin" do
    output =
      capture_io(fn ->
        Lifecycle.run(["--env", "prod", "--readiness", "archive_candidate", "--evidence-quality", "strong"])
      end)

    assert output =~ "Lifecycle report"
    assert output =~ "Environment: prod"
    assert output =~ "* ops-cleanup [archive_candidate / strong]"
    assert output =~ "owner: ops"
    assert output =~ "code references: fresh_refs_absent"
    assert output =~ "primary action: archive_ready"
    refute output =~ "search-ranking"
  end

  test "emits canonical json with versioned schema and scan semantics" do
    output =
      capture_io(fn ->
        Lifecycle.run(["--env", "prod", "--format", "json"])
      end)

    payload = Jason.decode!(output)

    assert payload["schema_version"] == 1
    assert payload["format_version"] == 1
    assert payload["filters"]["env"] == "prod"

    ops_cleanup =
      Enum.find(payload["entries"], fn entry -> entry["flag_key"] == "ops-cleanup" end)

    search_ranking =
      Enum.find(payload["entries"], fn entry -> entry["flag_key"] == "search-ranking" end)

    assert ops_cleanup["freshness"]["code_references"] == "fresh_refs_absent"
    assert ops_cleanup["owner"] == "ops"
    assert ops_cleanup["archive_readiness"]["readiness"] == "archive_candidate"
    assert ops_cleanup["archive_readiness"]["recommended_next_action"] == "archive_ready"
    assert search_ranking["freshness"]["code_references"] == "scan_unknown"
    assert "code_refs_scan_missing" in search_ranking["archive_readiness"]["unknowns"]
  end

  test "stays read-only and rejects unsupported mutation-like switches" do
    assert_raise Mix.Error, ~r/read-only/, fn ->
      capture_io(fn ->
        Lifecycle.run(["--plan"])
      end)
    end
  end

  test "rejects unknown filter atoms without interning user input" do
    assert_raise Mix.Error, ~r/invalid --readiness value: unknown/, fn ->
      capture_io(fn ->
        Lifecycle.run(["--env", "prod", "--readiness", "unknown"])
      end)
    end
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:description, "Flag #{attrs[:key]}")
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    if Map.has_key?(attrs, :code_reference_count) or Map.has_key?(attrs, :code_refs_scan) do
      assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
    else
      assert {:ok, _payload} = Rulestead.create_flag(Map.put(attrs, :actor, @admin_actor))
    end
  end

  defp publish_flag!(flag_key) do
    ruleset = %{
      salt: "#{flag_key}:prod:v1",
      rules: [
        %{
          key: "#{flag_key}-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, "prod", ruleset, actor: @admin_actor)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, "prod", actor: @admin_actor)
             )
  end
end
