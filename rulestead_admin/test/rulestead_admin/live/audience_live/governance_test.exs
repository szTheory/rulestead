defmodule RulesteadAdmin.Live.AudienceLive.GovernanceTest do
  use ExUnit.Case, async: false

  alias Rulestead.Targeting.ImpactPreview
  alias RulesteadAdmin.Live.AudienceLive.Governance

  setup do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, RulesteadAdmin.TestPolicy)
    Rulestead.Fake.Control.reset!()
    :ok
  end

  describe "governance_mode/3" do
    test "production above threshold requires change request" do
      assert Governance.governance_mode(:prod, %{verdict: :above_threshold}, :full) ==
               :change_request
    end

    test "non-protected environments are unrestricted" do
      assert Governance.governance_mode(:test, %{verdict: :above_threshold}, :full) ==
               :unrestricted

      assert Governance.governance_mode("test", %{verdict: :indeterminate}, :denied) ==
               :unrestricted
    end

    test "protected below threshold allows direct apply" do
      assert Governance.governance_mode("production", %{verdict: :below_threshold}, :full) ==
               :direct_apply
    end

    test "protected indeterminate or partial visibility blocks" do
      assert Governance.governance_mode("production", %{verdict: :indeterminate}, :full) ==
               :blocked

      assert Governance.governance_mode("production", %{verdict: :below_threshold}, :partial) ==
               :blocked

      assert Governance.governance_mode("production", %{verdict: :above_threshold}, :denied) ==
               :blocked
    end

    test "assess error (nil assessment) blocks protected environments" do
      assert Governance.governance_mode("production", nil, :full) == :blocked
    end
  end

  describe "visibility_tier/1" do
    test "hidden references yield partial tier" do
      assert Governance.visibility_tier(%{hidden_reference_count: 1}) == :partial
      assert Governance.visibility_tier(%{hidden_count: 2, denied?: false}) == :partial
    end

    test "auth denial yields denied tier" do
      assert Governance.visibility_tier(%{denied?: true, hidden_count: 0}) == :denied
    end

    test "full visibility when no hidden references" do
      assert Governance.visibility_tier(%{hidden_count: 0, denied?: false}) == :full
    end
  end

  describe "load_governance_context/3" do
    setup do
      seed_audience_flag!()
      :ok
    end

    test "assigns governance mode and assessment for protected preview" do
      socket = governance_socket("production")
      preview = build_preview("production", reference_count: 3)

      socket = Governance.load_governance_context(socket, preview, operation: :update)

      assert socket.assigns.governance_mode == :change_request
      assert socket.assigns.visibility_tier == :full
      assert socket.assigns.blast_radius_assessment.verdict == :above_threshold
      assert socket.assigns.dependency_inventory.summary =~ "authored references"
    end

    test "assigns unrestricted mode for non-protected environment" do
      preview = build_preview("test", reference_count: 1)
      socket = governance_socket("test")

      socket = Governance.load_governance_context(socket, preview, operation: :update)

      assert socket.assigns.governance_mode == :unrestricted
      assert socket.assigns.blast_radius_assessment.verdict == :below_threshold
    end

    test "indeterminate assessment blocks protected environments" do
      preview = build_preview("production", reference_count: 1, preview_fingerprint: nil)
      socket = governance_socket("production")

      socket = Governance.load_governance_context(socket, preview, operation: :update)

      assert socket.assigns.governance_mode == :blocked
      assert socket.assigns.blast_radius_assessment.verdict == :indeterminate
      assert socket.assigns.governance_blocked_reason =~ "cannot be evaluated"
    end
  end

  describe "approval_expectation_assigns/2" do
    test "returns policy-derived approval expectations" do
      socket = governance_socket("test")

      assigns = Governance.approval_expectation_assigns(socket, "vip-users")

      assert assigns.required_approvals == 0
      assert assigns.self_approval_allowed? == true
      assert assigns.can_submit? == true
    end
  end

  defp governance_socket(environment_key) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        current_environment: %{key: environment_key, name: String.capitalize(environment_key)},
        current_tenant: nil,
        current_actor: %{id: "editor-1", roles: [:editor]},
        audience_key: "vip-users",
        rulestead_admin_mount_path: "/admin/flags"
      }
    }
  end

  defp build_preview(environment_key, opts) do
    references =
      Keyword.get_lazy(opts, :affected_references, fn ->
        count = Keyword.get(opts, :reference_count, 1)
        flag_keys = ["checkout", "checkout-b", "checkout-c"]

        Enum.map(0..(count - 1), fn index ->
          flag_key = Enum.at(flag_keys, index, "checkout")

          %{
            reference_key: "flag:#{flag_key}:ruleset:1:rule:vip-#{index}",
            flag_key: flag_key,
            rule_strategy: "segment_match",
            rollout_context: %{available?: true, status: "active"},
            lifecycle_context: %{available?: true}
          }
        end)
      end)

    %{
      audience_key: "vip-users",
      preview_fingerprint: Keyword.get(opts, :preview_fingerprint, "audprev_governance"),
      preview_schema_version: ImpactPreview.schema_version(),
      preview_basis: "authored_state_and_explicit_samples",
      environment_scope: %{environment_key: environment_key},
      tenant_scope: %{tenant_key: nil},
      affected_references: List.wrap(references),
      uncertainty: %{authoritative_population_count?: false}
    }
  end

  defp seed_audience_flag! do
    alias Rulestead.Fake.Control

    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    for {flag_key, rule_key} <- [
          {"checkout", "vip-rule"},
          {"checkout-b", "vip-rule-b"},
          {"checkout-c", "vip-rule-c"}
        ] do
      Control.put_flag!(%{
        key: flag_key,
        description: "Checkout #{flag_key}",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: "growth",
        permanent: true,
        expected_expiration: nil,
        environment_keys: ["test", "production"]
      })

      publish_ruleset!(flag_key, "production", %{
        salt: "#{flag_key}:production",
        rules: [
          %{key: rule_key, strategy: :segment_match, audience_key: "vip-users", conditions: []}
        ]
      })
    end

    Rulestead.Fake.Control.rebuild_audience_reference_projection!()
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    alias Rulestead.Fake
    alias Rulestead.Store.Command

    assert {:ok, _} =
             Fake.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
             )

    assert {:ok, _} = Fake.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end
end
