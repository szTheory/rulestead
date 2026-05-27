defmodule Rulestead.Governance.AudienceMutationChangeRequestTest do
  use ExUnit.Case, async: true

  alias Rulestead.Governance.{ApprovalRequirement, AudienceMutationChangeRequest}
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.ImpactPreview

  @reference %{
    reference_key: "flag:checkout:ruleset:1:rule:vip",
    flag_key: "checkout",
    rollout_context: %{available?: true, status: "active"},
    lifecycle_context: %{available?: true}
  }

  describe "validate_submit/2" do
    test "accepts protected above_threshold submission with matching fingerprint" do
      preview = above_threshold_preview()
      command = submit_command(preview)

      assert :ok = AudienceMutationChangeRequest.validate_submit(command, preview)
    end

    test "rejects non-protected environment_key staging" do
      preview = above_threshold_preview()
      command = submit_command(preview, environment_key: "staging")

      assert {:error, %Rulestead.Error{type: :invalid_command, message: message}} =
               AudienceMutationChangeRequest.validate_submit(command, preview)

      assert message =~ "protected environment"
    end

    test "rejects below_threshold assessment" do
      preview = below_threshold_preview()
      command = submit_command(preview)

      assert {:error, %Rulestead.Error{type: :invalid_command, message: message}} =
               AudienceMutationChangeRequest.validate_submit(command, preview)

      assert message =~ "Direct apply is allowed"
    end

    test "rejects indeterminate assessment when fingerprint missing" do
      preview = %{affected_references: [@reference], preview_fingerprint: "audprev_test"}
      command = submit_command(preview, preview_fingerprint: "")

      assert {:error, %Rulestead.Error{type: :invalid_command}} =
               AudienceMutationChangeRequest.validate_submit(command, preview)
    end
  end

  describe "build_submission_metadata/2" do
    test "includes blast_radius_assessment and affected_reference_summary keys" do
      preview = above_threshold_preview()

      {:ok, assessment} =
        Rulestead.Governance.BlastRadiusThreshold.assess(%{
          environment_key: "production",
          operation: "update",
          preview_fingerprint: preview.preview_fingerprint,
          preview_schema_version: ImpactPreview.schema_version(),
          affected_references: preview.affected_references
        })

      metadata = AudienceMutationChangeRequest.build_submission_metadata(assessment, preview)

      assert Map.has_key?(metadata, "blast_radius_assessment")
      assert Map.has_key?(metadata, "affected_reference_summary")
      assert metadata["blast_radius_assessment"]["verdict"] == "above_threshold"
      assert metadata["affected_reference_summary"]["reference_count"] == 3
      assert metadata["preview_evidence_summary"]["preview_fingerprint"] == preview.preview_fingerprint
      assert metadata["preview_evidence_summary"]["uncertainty"]["authoritative_population_count?"] == false
    end
  end

  defp submit_command(preview, overrides \\ []) do
    preview_fingerprint =
      Keyword.get(overrides, :preview_fingerprint, preview.preview_fingerprint)

    environment_key = Keyword.get(overrides, :environment_key, "production")

    Command.SubmitChangeRequest.new(
      %{
        action: :apply_audience_mutation,
        environment_key: environment_key,
        resource_type: "audience",
        resource_key: "vip-users",
        command: %{
          "audience_key" => "vip-users",
          "environment_key" => environment_key,
          "tenant_key" => "tenant-a",
          "operation" => "update",
          "preview_schema_version" => ImpactPreview.schema_version(),
          "preview_fingerprint" => preview_fingerprint,
          "preview_basis" => "authored_state_and_explicit_samples",
          "affected_reference_keys" =>
            Enum.map(preview.affected_references, & &1.reference_key),
          "after_definition" => %{
            "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "pro"}]
          }
        },
        approval_requirement:
          ApprovalRequirement.new(
            action: :apply_audience_mutation,
            environment_key: environment_key,
            required_approvals: 1,
            change_request_required?: true,
            self_approval_allowed?: false
          )
      },
      actor: %{id: "submitter-1", type: "operator", display: "Submitter"},
      reason: "Governed audience mutation",
      metadata: %{request_id: "corr-audience-cr"}
    )
  end

  defp above_threshold_preview do
    references = [
      @reference,
      %{@reference | reference_key: "flag:b:ruleset:1:rule:r2", flag_key: "b"},
      %{@reference | reference_key: "flag:c:ruleset:1:rule:r3", flag_key: "c"}
    ]

    ImpactPreview.build(%{
      environment_key: "production",
      tenant_key: "tenant-a",
      audience_key: "vip-users",
      operation: "update",
      before_definition: %{conditions: []},
      after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
      affected_references: references,
      preview_basis: "authored_state_and_explicit_samples"
    })
  end

  defp below_threshold_preview do
    ImpactPreview.build(%{
      environment_key: "production",
      tenant_key: "tenant-a",
      audience_key: "vip-users",
      operation: "update",
      before_definition: %{conditions: []},
      after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
      affected_references: [@reference],
      preview_basis: "authored_state_and_explicit_samples"
    })
  end
end
