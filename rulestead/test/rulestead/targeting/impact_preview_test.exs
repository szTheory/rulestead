defmodule Rulestead.Targeting.ImpactPreviewTest do
  use ExUnit.Case, async: true

  alias Rulestead.Targeting.AudienceDependencies
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

    test "build does not atomize caller-controlled output keys" do
      preview =
        ImpactPreview.build(
          preview_attrs(%{
            affected_references: [
              %{
                "reference_key" => "flag:checkout:ruleset:7:rule:vip",
                "caller_supplied_unique_key_53" => "kept as string"
              }
            ]
          })
        )

      assert [
               %{
                 :reference_key => "flag:checkout:ruleset:7:rule:vip",
                 "caller_supplied_unique_key_53" => "kept as string"
               }
             ] = preview.affected_references
    end
  end

  describe "audience dependency summaries" do
    test "summarize finds segment_match rules for the target audience and sorts references" do
      references =
        AudienceDependencies.summarize("vip-users", [
          authored_flag("pricing", "production", "acme", 3, [
            %{
              "key" => "vip-pricing",
              "strategy" => "segment_match",
              "audience_key" => "vip-users",
              "rollout" => %{"percentage" => 50}
            }
          ]),
          authored_flag("checkout", "production", "acme", 7, [
            %{
              key: "vip-checkout",
              strategy: :segment_match,
              audience_key: "vip-users",
              lifecycle: %{state: "active"}
            },
            %{key: "trial-checkout", strategy: :segment_match, audience_key: "trial-users"}
          ]),
          authored_flag("docs", "staging", nil, 1, [
            %{key: "vip-docs", strategy: :forced_value, audience_key: "vip-users"}
          ])
        ])

      assert Enum.map(references, & &1.reference_key) == [
               "flag:checkout:ruleset:7:rule:vip-checkout",
               "flag:pricing:ruleset:3:rule:vip-pricing"
             ]

      assert [
               %{
                 flag_key: "checkout",
                 ruleset_version: 7,
                 ruleset_status: "active",
                 rule_key: "vip-checkout",
                 rule_strategy: "segment_match",
                 rollout_context: %{available?: false},
                 lifecycle_context: %{state: "active"},
                 environment_key: "production",
                 tenant_key: "acme"
               },
               %{
                 flag_key: "pricing",
                 ruleset_version: 3,
                 ruleset_status: "active",
                 rule_key: "vip-pricing",
                 rule_strategy: "segment_match",
                 rollout_context: %{"percentage" => 50},
                 lifecycle_context: %{available?: false},
                 environment_key: "production",
                 tenant_key: "acme"
               }
             ] = references

      refute inspect(references) =~ "actor_key"
      refute inspect(references) =~ "sample"

      preview =
        ImpactPreview.build(
          preview_attrs(%{
            affected_references: references,
            samples: [%{actor_key: "user-1", traits: %{plan: "pro"}}]
          })
        )

      assert preview.affected_references == references
      assert AudienceDependencies.reference_keys(references) == [
               "flag:checkout:ruleset:7:rule:vip-checkout",
               "flag:pricing:ruleset:3:rule:vip-pricing"
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

  defp authored_flag(flag_key, environment_key, tenant_key, version, rules) do
    %{
      flag: %{key: flag_key},
      active_ruleset: %{version: version, status: "active", rules: rules},
      environment_key: environment_key,
      tenant_key: tenant_key
    }
  end
end
