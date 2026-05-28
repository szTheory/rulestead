# credo:disable-for-this-file
defmodule Rulestead.Governance.PreviewEvidenceGovernanceContractTest do
  use Rulestead.RepoCase, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.Error
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.Targeting.AudienceDependencies

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)

    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Fake.PreviewEvidenceResolver
    )

    on_exit(fn ->
      case previous_resolver do
        nil -> Application.delete_env(:rulestead, :preview_evidence_resolver)
        value -> Application.put_env(:rulestead, :preview_evidence_resolver, value)
      end
    end)

    ensure_phase9_schema!()
    :ok
  end

  test "direct apply blast-radius block unchanged with resolver evidence across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())
      assert map_size(preview.impression_evidence) > 0

      command = direct_apply_command(preview)

      assert {:error,
              %Error{
                type: :invalid_command,
                metadata: %{verdict: "above_threshold", reference_count: 3}
              }} =
               apply_audience_mutation(adapter, command)
    end)
  end

  test "change request submit verdict unchanged with resolver evidence across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      {:ok, preview_with_resolver} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: with_resolver}} =
               adapter.submit_change_request(
                 audience_submit_command(preview_with_resolver,
                   correlation_id: "corr-gov-resolver-#{adapter_label(adapter)}"
                 )
               )

      Application.delete_env(:rulestead, :preview_evidence_resolver)

      {:ok, preview_without_resolver} =
        preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: without_resolver}} =
               adapter.submit_change_request(
                 audience_submit_command(preview_without_resolver,
                   correlation_id: "corr-gov-baseline-#{adapter_label(adapter)}"
                 )
               )

      Application.put_env(
        :rulestead,
        :preview_evidence_resolver,
        Rulestead.Fake.PreviewEvidenceResolver
      )

      assert with_resolver.metadata["blast_radius_assessment"]["verdict"] ==
               without_resolver.metadata["blast_radius_assessment"]["verdict"]
    end)
  end

  test "below-threshold direct apply still allowed with resolver evidence across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 1)

      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())
      command = direct_apply_command(preview)

      assert {:ok, %{result: :ok}} = apply_audience_mutation(adapter, command)
    end)
  end

  test "above-threshold still blocks direct apply and allows change request submit across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:error, %Error{metadata: %{verdict: "above_threshold"}}} =
               apply_audience_mutation(adapter, direct_apply_command(preview))

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview,
                   correlation_id: "corr-gov-cr-path-#{adapter_label(adapter)}"
                 )
               )

      assert submitted.metadata["blast_radius_assessment"]["verdict"] == "above_threshold"
    end)
  end

  defp apply_audience_mutation(Rulestead.Fake, command) do
    Rulestead.apply_audience_mutation(Map.from_struct(command))
  end

  defp apply_audience_mutation(StoreEcto, command), do: StoreEcto.apply_audience_mutation(command)

  defp direct_apply_command(preview) do
    Command.ApplyAudienceMutation.new(%{
      environment_key: "production",
      tenant_key: "tenant-a",
      audience_key: "vip-users",
      operation: :update,
      preview_schema_version: preview.preview_schema_version,
      preview_fingerprint: preview.preview_fingerprint,
      preview_basis: preview.preview_basis,
      affected_reference_keys: AudienceDependencies.reference_keys(preview.affected_references),
      after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
      actor: %{id: "editor-1", type: "operator", display: "Editor"},
      reason: "direct apply attempt"
    })
  end

  defp audience_submit_command(preview, opts) do
    correlation_id = Keyword.fetch!(opts, :correlation_id)

    Command.SubmitChangeRequest.new(
      %{
        action: :apply_audience_mutation,
        environment_key: "production",
        resource_type: "audience",
        resource_key: "vip-users",
        command: %{
          "audience_key" => "vip-users",
          "environment_key" => "production",
          "tenant_key" => "tenant-a",
          "operation" => "update",
          "preview_schema_version" => preview.preview_schema_version,
          "preview_fingerprint" => preview.preview_fingerprint,
          "preview_basis" => preview.preview_basis,
          "affected_reference_keys" =>
            AudienceDependencies.reference_keys(preview.affected_references),
          "after_definition" => %{
            "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "pro"}]
          }
        },
        approval_requirement:
          ApprovalRequirement.new(
            action: :apply_audience_mutation,
            environment_key: "production",
            required_approvals: 1,
            change_request_required?: true,
            self_approval_allowed?: false
          )
      },
      actor: %{id: "submitter-1", type: "operator", display: "Submitter"},
      reason: "Submit governed audience mutation",
      metadata: %{request_id: correlation_id}
    )
  end

  defp production_preview_attrs do
    [
      environment_key: "production",
      tenant_key: "tenant-a",
      after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]}
    ]
  end

  defp preview_audience_impact(Rulestead.Fake, attrs) do
    Rulestead.preview_audience_impact(
      "vip-users",
      :update,
      Keyword.merge(attrs,
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )
    )
  end

  defp preview_audience_impact(StoreEcto, attrs) do
    StoreEcto.preview_audience_impact(
      Command.PreviewAudienceImpact.new("vip-users", :update, attrs)
    )
  end

  defp adapter_label(Rulestead.Fake), do: "fake"
  defp adapter_label(StoreEcto), do: "ecto"

  defp reset_adapter!(Rulestead.Fake) do
    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
  end

  defp reset_adapter!(StoreEcto) do
    import Ecto.Query

    alias Rulestead.{Audience, AuditEvent, Environment, Repo}

    Repo.delete_all(AuditEvent)
    Repo.delete_all(from(a in Audience))
    Repo.delete_all(from(f in Rulestead.Flag))
    Repo.delete_all(from(fe in Rulestead.FlagEnvironment))
    Repo.delete_all(from(r in Rulestead.Ruleset))
    Repo.delete_all(from(e in Environment))

    for attrs <- default_environments() do
      %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
    end

    %Audience{}
    |> Audience.changeset(%{
      key: "vip-users",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })
    |> Repo.insert!()
  end

  defp seed_production_audience_references!(Rulestead.Fake, count) do
    Rulestead.Fake.Control.put_audience!(%{
      key: "vip-users",
      tenant_key: "tenant-a",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })

    for index <- 1..count do
      flag_key = "checkout-redesign-#{index}"

      Rulestead.Fake.Control.put_flag!(
        valid_flag_attrs(%{key: flag_key, environment_keys: ["production"]})
      )

      ruleset =
        valid_ruleset_attrs(%{
          rules: [
            %{
              key: "vip-rule-#{index}",
              name: "VIP audience #{index}",
              strategy: :segment_match,
              audience_key: "vip-users",
              conditions: []
            }
          ]
        })

      assert {:ok, _draft} =
               Rulestead.Fake.save_draft_ruleset(
                 Command.SaveDraftRuleset.new(flag_key, "production", ruleset)
               )

      assert {:ok, _published} =
               Rulestead.Fake.publish_ruleset(Command.PublishRuleset.new(flag_key, "production"))
    end
  end

  defp seed_production_audience_references!(StoreEcto, count) do
    for index <- 1..count do
      flag_key = "checkout-redesign-#{index}"

      assert {:ok, _flag} =
               StoreEcto.create_flag(
                 Command.CreateFlag.new(
                   valid_flag_attrs(%{key: flag_key, environment_keys: ["production"]})
                 )
               )

      ruleset =
        valid_ruleset_attrs(%{
          rules: [
            %{
              key: "vip-rule-#{index}",
              name: "VIP audience #{index}",
              strategy: :segment_match,
              audience_key: "vip-users",
              conditions: []
            }
          ]
        })

      assert {:ok, _draft} =
               StoreEcto.save_draft_ruleset(
                 Command.SaveDraftRuleset.new(flag_key, "production", ruleset)
               )

      assert {:ok, _published} =
               StoreEcto.publish_ruleset(Command.PublishRuleset.new(flag_key, "production"))
    end
  end

  defp default_environments do
    [
      %{key: "development", name: "Development", description: "Local environments"},
      %{key: "staging", name: "Staging", description: "Pre-production environments"},
      %{key: "production", name: "Production", description: "Live environments"},
      %{key: "test", name: "Test", description: "Test environments"}
    ]
  end

  defp ensure_phase9_schema! do
    Rulestead.Repo.query!(
      "ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS change_requests (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      status text NOT NULL DEFAULT 'submitted',
      governed_action text NOT NULL,
      environment_key text NOT NULL,
      resource_type text NOT NULL,
      resource_key text NOT NULL,
      submitter_id text NOT NULL,
      submitter_type text NOT NULL,
      submitter_display text,
      reason text,
      approval_requirement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      command_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      submitted_at timestamp(6) with time zone NOT NULL,
      resolved_at timestamp(6) with time zone,
      executed_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS change_requests_correlation_id_index ON change_requests (correlation_id)"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS approvals (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      change_request_id uuid NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
      decision text NOT NULL,
      reviewer_id text NOT NULL,
      reviewer_type text NOT NULL,
      reviewer_display text,
      reason text,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      reviewed_at timestamp(6) with time zone NOT NULL,
      inserted_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "ALTER TABLE change_requests DROP CONSTRAINT IF EXISTS change_requests_governed_action_must_be_valid"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE change_requests ADD CONSTRAINT change_requests_governed_action_must_be_valid CHECK (governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'manage_settings', 'promote_environment', 'apply_audience_mutation'))"
    )
  end
end
