defmodule Rulestead.Governance.BlastRadiusThresholdTest do
  use ExUnit.Case, async: true

  alias Rulestead.Error
  alias Rulestead.Governance.BlastRadiusThreshold
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.{DependencyValidator, ImpactPreview}

  @reference %{
    reference_key: "flag:checkout:ruleset:1:rule:vip",
    flag_key: "checkout",
    rollout_context: %{available?: true, status: "active"},
    lifecycle_context: %{available?: true}
  }

  describe "assess/2" do
    test "below_threshold for protected prod update with two references" do
      assert {:ok, assessment} =
               assess(%{
                 environment_key: "production",
                 operation: "update",
                 preview_fingerprint: "audprev_test",
                 preview_schema_version: ImpactPreview.schema_version(),
                 affected_references: [@reference, %{@reference | reference_key: "flag:b:ruleset:1:rule:r2", flag_key: "b"}]
               })

      assert assessment.verdict == :below_threshold
      assert assessment.reference_count == 2
      assert assessment.distinct_flag_count == 2
      assert assessment.authoritative_population_count? == false
      assert assessment.breach_reasons == []
    end

    test "segment_match references without rollout do not force indeterminate" do
      references = [
        %{
          reference_key: "flag:a:ruleset:1:rule:r1",
          flag_key: "a",
          rule_strategy: "segment_match",
          rollout_context: %{available?: false},
          lifecycle_context: %{mode: "permanent"}
        }
      ]

      assert {:ok, assessment} = assess(prod_update_attrs(references))
      assert assessment.verdict == :below_threshold
    end

    test "above_threshold for protected prod update with three references" do
      references = [
        @reference,
        %{@reference | reference_key: "flag:b:ruleset:1:rule:r2", flag_key: "b"},
        %{@reference | reference_key: "flag:c:ruleset:1:rule:r3", flag_key: "c"}
      ]

      assert {:ok, assessment} = assess(prod_update_attrs(references))

      assert assessment.verdict == :above_threshold

      assert [%{code: "blast_radius_above_threshold", observed: 3, limit: 2}] =
               assessment.breach_reasons
    end

    test "above_threshold for protected prod archive with one reference" do
      assert {:ok, assessment} =
               assess(%{
                 environment_key: "production",
                 operation: "archive",
                 preview_fingerprint: "audprev_test",
                 preview_schema_version: ImpactPreview.schema_version(),
                 affected_references: [@reference]
               })

      assert assessment.verdict == :above_threshold

      assert [%{code: "blast_radius_above_threshold", observed: 1, limit: 0}] =
               assessment.breach_reasons
    end

    test "indeterminate for missing preview fingerprint" do
      assert {:ok, assessment} =
               assess(%{
                 environment_key: "production",
                 operation: "update",
                 preview_fingerprint: "",
                 preview_schema_version: ImpactPreview.schema_version(),
                 affected_references: [@reference]
               })

      assert assessment.verdict == :indeterminate

      assert Enum.any?(assessment.breach_reasons, &(&1.code == "blast_radius_missing_preview_inputs"))
    end

    test "indeterminate when rollout context is unavailable" do
      reference = %{@reference | rollout_context: %{available?: false}}

      assert {:ok, assessment} = assess(prod_update_attrs([reference]))
      assert assessment.verdict == :indeterminate
    end

    test "indeterminate when dependency validator reports blockers" do
      entries = [
        %{
          environment_key: "production",
          tenant_key: "tenant-a",
          audience_key: "vip-users",
          flag_key: "checkout",
          ruleset_version: 1,
          rule_key: "vip",
          ruleset_status: "active",
          rollout_context: %{available?: true},
          lifecycle_context: %{available?: true},
          visibility: %{status: "visible"},
          reference_count: 1,
          hidden_reference_count: 0
        }
      ]

      findings =
        DependencyValidator.validate(%{tenant_key: "tenant-a"}, entries)
        |> Enum.filter(&(Map.get(&1, :severity) == :blocker))

      assert findings != []

      assert {:ok, assessment} =
               assess(
                 prod_update_attrs([@reference],
                   dependency_entries: entries,
                   affected_reference_keys: ["flag:checkout:ruleset:1:rule:vip"]
                 )
               )

      assert assessment.verdict == :indeterminate

      assert Enum.any?(assessment.breach_reasons, &(&1.code == "blast_radius_unresolved_dependency_truth"))
    end

    test "assess ignores impression_evidence and sample_evidence for verdict" do
      references = [
        @reference,
        %{@reference | reference_key: "flag:b:ruleset:1:rule:r2", flag_key: "b"}
      ]

      base_attrs =
        prod_update_attrs(references, %{
          impression_evidence: %{
            window_label: "last_24h",
            sampled_impressions: 1,
            matched_impressions: 999_999_999
          },
          sample_evidence:
            for(index <- 1..25,
              do: %{actor_key: "actor-#{index}", targeting_key: "target-#{index}"}
            )
        })

      assert {:ok, baseline} = assess(Map.drop(base_attrs, [:impression_evidence, :sample_evidence]))
      assert {:ok, enriched} = assess(base_attrs)

      assert baseline.verdict == enriched.verdict
      assert baseline.reference_count == enriched.reference_count
      assert baseline.verdict == :below_threshold

      above_references = references ++ [
        %{@reference | reference_key: "flag:c:ruleset:1:rule:r3", flag_key: "c"}
      ]

      above_base = prod_update_attrs(above_references)

      above_with_impression =
        Map.merge(above_base, %{
          impression_evidence: %{
            window_label: "last_7d",
            matched_impressions: 50_000_000
          },
          sample_evidence: for(index <- 1..25, do: %{actor_key: "cohort-#{index}"})
        })

      assert {:ok, above_baseline} = assess(above_base)
      assert {:ok, above_enriched} = assess(above_with_impression)

      assert above_baseline.verdict == above_enriched.verdict
      assert above_baseline.verdict == :above_threshold
    end
  end

  describe "validate_protected_apply/3" do
    test "non-protected environment bypasses above-threshold verdict" do
      command = apply_command("test")
      preview = %{affected_references: three_references()}

      assert :ok =
               BlastRadiusThreshold.validate_protected_apply(command, preview,
                 dependency_entries: []
               )
    end

    test "protected production blocks above-threshold apply" do
      command = apply_command("production")
      preview = %{affected_references: three_references()}

      assert {:error, %Error{type: :invalid_command} = error} =
               BlastRadiusThreshold.validate_protected_apply(command, preview,
                 dependency_entries: []
               )

      assert error.metadata[:verdict] == "above_threshold"
      assert error.metadata[:reference_count] == 3
      assert Enum.any?(error.details, &(&1.code == "blast_radius_above_threshold"))
    end

    test "blocked apply error metadata includes verdict, reference_count, and breach reasons" do
      command = apply_command("production")
      preview = %{affected_references: three_references()}

      assert {:error, error} =
               BlastRadiusThreshold.validate_protected_apply(command, preview,
                 dependency_entries: []
               )

      assert error.metadata[:verdict] in ["above_threshold", "indeterminate"]
      assert is_integer(error.metadata[:reference_count])
      assert Enum.any?(error.details, &(Map.get(&1, :code) in ["blast_radius_above_threshold", "blast_radius_indeterminate"]))
    end

    test "governed_apply bypasses above_threshold in protected environment" do
      command = apply_command("production")
      preview = %{affected_references: three_references()}

      assert :ok =
               BlastRadiusThreshold.validate_protected_apply(command, preview,
                 dependency_entries: [],
                 governed_apply?: true
               )
    end

    test "governed_apply does not bypass indeterminate verdict" do
      command =
        Command.ApplyAudienceMutation.new(%{
          environment_key: "production",
          tenant_key: "tenant-a",
          audience_key: "vip-users",
          operation: :update,
          preview_schema_version: ImpactPreview.schema_version(),
          preview_fingerprint: "",
          preview_basis: "authored_state_and_explicit_samples",
          affected_reference_keys: [],
          after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
          actor: %{id: "editor-1", roles: [:editor]},
          reason: "apply update"
        })

      preview = %{affected_references: three_references()}

      assert {:error, %Error{type: :invalid_command} = error} =
               BlastRadiusThreshold.validate_protected_apply(command, preview,
                 dependency_entries: [],
                 governed_apply?: true
               )

      assert error.metadata[:verdict] == "indeterminate"
    end

    test "protected above_threshold without governed_apply remains blocked" do
      command = apply_command("production")
      preview = %{affected_references: three_references()}

      assert {:error, %Error{type: :invalid_command}} =
               BlastRadiusThreshold.validate_protected_apply(command, preview,
                 dependency_entries: []
               )
    end

    test "validate_protected_apply verdict unchanged with impression and sample evidence on preview" do
      preview_base = %{affected_references: three_references()}

      preview_enriched =
        Map.merge(preview_base, %{
          impression_evidence: %{"window_label" => "last_7d", "matched_impressions" => 50_000_000},
          sample_evidence: for(i <- 1..25, do: %{"actor_key" => "actor-#{i}"})
        })

      command = apply_command("production")

      assert {:error, base_error} =
               BlastRadiusThreshold.validate_protected_apply(command, preview_base,
                 dependency_entries: []
               )

      assert {:error, enriched_error} =
               BlastRadiusThreshold.validate_protected_apply(command, preview_enriched,
                 dependency_entries: []
               )

      assert base_error.metadata[:verdict] == enriched_error.metadata[:verdict]
      assert base_error.metadata[:reference_count] == enriched_error.metadata[:reference_count]
    end

    test "governed_apply bypass unchanged with enriched preview" do
      preview_enriched = %{
        affected_references: three_references(),
        impression_evidence: %{"window_label" => "last_7d", "matched_impressions" => 50_000_000},
        sample_evidence: for(i <- 1..25, do: %{"actor_key" => "actor-#{i}"})
      }

      command = apply_command("production")

      assert :ok =
               BlastRadiusThreshold.validate_protected_apply(command, preview_enriched,
                 dependency_entries: [],
                 governed_apply?: true
               )
    end
  end

  describe "Rulestead.assess_audience_blast_radius/2" do
    test "delegates to BlastRadiusThreshold" do
      preview = %{
        environment_key: "production",
        operation: "update",
        preview_fingerprint: "audprev_test123",
        preview_schema_version: ImpactPreview.schema_version(),
        affected_references: [@reference]
      }

      assert {:ok, assessment} = Rulestead.assess_audience_blast_radius(preview)
      assert assessment.verdict == :below_threshold
      assert assessment.reference_count == 1
      assert assessment.authoritative_population_count? == false
    end
  end

  defp assess(attrs) do
    BlastRadiusThreshold.assess(attrs)
  end

  defp prod_update_attrs(references, extra \\ []) do
    Map.merge(
      %{
        environment_key: "production",
        operation: "update",
        preview_fingerprint: "audprev_test",
        preview_schema_version: ImpactPreview.schema_version(),
        affected_references: references
      },
      Map.new(extra)
    )
  end

  defp apply_command(environment_key) do
    Command.ApplyAudienceMutation.new(%{
      environment_key: environment_key,
      tenant_key: "tenant-a",
      audience_key: "vip-users",
      operation: :update,
      preview_schema_version: ImpactPreview.schema_version(),
      preview_fingerprint: "audprev_test",
      preview_basis: "authored_state_and_explicit_samples",
      affected_reference_keys: Enum.map(three_references(), & &1.reference_key),
      after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
      actor: %{id: "editor-1", roles: [:editor]},
      reason: "apply update"
    })
  end

  defp three_references do
    [
      @reference,
      %{@reference | reference_key: "flag:b:ruleset:1:rule:r2", flag_key: "b"},
      %{@reference | reference_key: "flag:c:ruleset:1:rule:r3", flag_key: "c"}
    ]
  end
end
