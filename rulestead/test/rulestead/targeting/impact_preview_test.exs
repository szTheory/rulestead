defmodule Rulestead.Targeting.ImpactPreviewTest do
  use ExUnit.Case, async: true

  alias Rulestead.AuditEvent
  alias Rulestead.Targeting.AudienceDependencies
  alias Rulestead.Targeting.ImpactPreview

  describe "audit_evidence_summary/1" do
    test "returns bounded summary from built preview" do
      preview =
        ImpactPreview.build(
          preview_attrs(%{
            impression_summary: %{
              "window_label" => "last_7d",
              "matched_impressions" => 120
            }
          })
        )

      summary = ImpactPreview.audit_evidence_summary(preview)

      assert summary["preview_fingerprint"] == preview.preview_fingerprint
      assert is_list(summary["sample_evidence"])
      assert summary["impression_evidence"]["window_label"] == "last_7d"
      assert summary["affected_reference_keys"] == ["flag:checkout:ruleset:7:rule:vip"]
      refute Map.has_key?(summary, "affected_references")
    end

    test "uncertainty remains non-authoritative" do
      preview = ImpactPreview.build(preview_attrs())

      summary = ImpactPreview.audit_evidence_summary(preview)

      assert summary["uncertainty"]["authoritative_population_count?"] == false
    end

    test "empty impression omits impression_evidence key" do
      preview = ImpactPreview.build(preview_attrs())

      summary = ImpactPreview.audit_evidence_summary(preview)

      refute Map.has_key?(summary, "impression_evidence")
    end

    test "accepts atom-key preview map" do
      preview = ImpactPreview.build(preview_attrs(%{impression_summary: %{"window_label" => "last_24h"}}))
      string_summary = ImpactPreview.audit_evidence_summary(preview)

      atom_preview =
        preview
        |> Map.new(fn {key, value} -> {if(is_binary(key), do: String.to_existing_atom(key), else: key), value} end)

      assert ImpactPreview.audit_evidence_summary(atom_preview) == string_summary
    end

    test "AuditEvent.metadata carries impression_evidence through allowlist" do
      metadata =
        AuditEvent.metadata(%{
          preview_fingerprint: "audprev_abc",
          impression_evidence: %{"window_label" => "last_24h", "matched_impressions" => 42}
        })

      assert metadata["impression_evidence"]["window_label"] == "last_24h"
      refute Map.has_key?(metadata, "email")
    end
  end

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

      assert preview.preview_schema_version == 2
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

      assert preview.impression_evidence == %{}
    end

    test "schema version 2 on build" do
      preview = ImpactPreview.build(preview_attrs())
      assert preview.preview_schema_version == 2
      assert ImpactPreview.schema_version() == 2
    end

    test "fingerprint changes when impression_summary changes" do
      base = preview_attrs()

      fingerprint_a =
        ImpactPreview.preview_fingerprint(
          Map.put(base, :impression_summary, %{window_label: "last_24h"})
        )

      fingerprint_b =
        ImpactPreview.preview_fingerprint(
          Map.put(base, :impression_summary, %{window_label: "last_7d"})
        )

      refute fingerprint_a == fingerprint_b
    end

    test "fingerprint stable for identical impression evidence" do
      attrs =
        preview_attrs(%{
          impression_summary: %{
            window_label: "last_24h",
            sampled_impressions: 100,
            matched_impressions: 42
          }
        })

      assert ImpactPreview.preview_fingerprint(attrs) == ImpactPreview.preview_fingerprint(attrs)
    end

    test "impression_evidence redaction" do
      preview =
        ImpactPreview.build(
          preview_attrs(%{
            impression_summary: %{
              window_label: "last_24h",
              sampled_impressions: 10,
              email: "person@example.com"
            }
          })
        )

      assert preview.impression_evidence == %{
               window_label: "last_24h",
               sampled_impressions: 10
             }

      refute Map.has_key?(preview.impression_evidence, :email)
    end

    test "basis messages" do
      for {basis, expected_fragment} <- [
            {"authored_state_and_explicit_samples", "explicit-sample preview only"},
            {"authored_state_with_host_evidence", "bounded host-supplied evidence"},
            {"authored_state_host_evidence_unavailable", "host evidence unavailable or denied"}
          ] do
        preview = ImpactPreview.build(preview_attrs(%{preview_basis: basis}))

        assert preview.preview_basis == basis
        assert preview.uncertainty.basis == basis
        assert preview.uncertainty.authoritative_population_count? == false
        assert preview.uncertainty.message =~ expected_fragment
      end
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
