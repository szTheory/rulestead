defmodule Rulestead.Targeting.ImpactPreviewTest do
  use ExUnit.Case, async: true

  alias Rulestead.Targeting.ImpactPreview

  describe "impact preview contract" do
    test "preview fingerprints are stable across map key order and change with scoped basis" do
      attrs = preview_attrs()

      fingerprint = ImpactPreview.preview_fingerprint(attrs)

      assert is_binary(fingerprint)
      assert String.starts_with?(fingerprint, "audprev_")

      assert fingerprint ==
               ImpactPreview.preview_fingerprint(%{
                 "samples" => [%{"plan" => "pro", "actor_key" => "user-1"}],
                 "affected_references" => [%{"reference_key" => "flag:checkout:ruleset:7:rule:vip"}],
                 "after_definition" => %{"conditions" => [%{"field" => "plan", "op" => "eq", "value" => "pro"}]},
                 "before_definition" => %{"conditions" => [%{"field" => "plan", "op" => "eq", "value" => "basic"}]},
                 "operation" => "update",
                 "audience_key" => "vip-users",
                 "tenant_key" => "acme",
                 "environment_key" => "production",
                 "preview_basis" => "authored_state_and_explicit_samples"
               })

      for changed <- [
            %{environment_key: "staging"},
            %{tenant_key: "globex"},
            %{audience_key: "trial-users"},
            %{before_definition: %{conditions: [%{field: "plan", op: "eq", value: "starter"}]}},
            %{after_definition: %{conditions: [%{field: "country", op: "eq", value: "US"}]}},
            %{affected_references: [%{reference_key: "flag:pricing:ruleset:3:rule:vip"}]},
            %{samples: [%{actor_key: "user-2", plan: "enterprise"}]}
          ] do
        refute fingerprint == ImpactPreview.preview_fingerprint(Map.merge(attrs, changed))
      end
    end

    test "build returns scoped preview payload with uncertainty and redacted sample evidence" do
      preview =
        ImpactPreview.build(
          preview_attrs(%{
            "environment_key" => " production ",
            "tenant_key" => " acme ",
            samples: [
              %{
                actor_key: "user-1",
                traits: %{
                  plan: "pro",
                  email: "person@example.com",
                  phone: "+15555550123",
                  session: "raw-session",
                  session_token: "raw-token",
                  socket_session: "raw-socket"
                }
              }
            ],
            findings: [
              ImpactPreview.finding(:blocker, :staleness_conflict, "preview_stale",
                message: "Audience preview is stale",
                provided_preview_fingerprint: "audprev_old"
              )
            ]
          })
        )

      assert preview.preview_schema_version == 1
      assert String.starts_with?(preview.preview_fingerprint, "audprev_")
      assert preview.environment_scope == %{environment_key: "production"}
      assert preview.tenant_scope == %{tenant_key: "acme"}
      assert preview.audience_key == "vip-users"
      assert preview.preview_basis == "authored_state_and_explicit_samples"

      assert preview.uncertainty == %{
               basis: "authored_state_and_explicit_samples",
               authoritative_population_count?: false,
               message: "authored-state and explicit-sample preview only"
             }

      assert [%{traits: traits}] = preview.sample_evidence
      assert traits.plan == "pro"
      refute Map.has_key?(traits, :email)
      refute Map.has_key?(traits, :phone)
      refute Map.has_key?(traits, :session)
      refute Map.has_key?(traits, :session_token)
      refute Map.has_key?(traits, :socket_session)

      assert [%{severity: :blocker, class: :staleness_conflict, code: "preview_stale"}] =
               preview.findings

      assert preview.affected_references == [
               %{reference_key: "flag:checkout:ruleset:7:rule:vip"}
             ]
    end
  end

  defp preview_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        environment_key: "production",
        tenant_key: "acme",
        audience_key: "vip-users",
        operation: "update",
        before_definition: %{conditions: [%{field: "plan", op: "eq", value: "basic"}]},
        after_definition: %{conditions: [%{field: "plan", op: "eq", value: "pro"}]},
        affected_references: [%{reference_key: "flag:checkout:ruleset:7:rule:vip"}],
        samples: [%{actor_key: "user-1", plan: "pro"}],
        preview_basis: "authored_state_and_explicit_samples",
        findings: []
      },
      overrides
    )
  end
end
