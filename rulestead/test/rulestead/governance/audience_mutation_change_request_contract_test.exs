# credo:disable-for-this-file
defmodule Rulestead.Governance.AudienceMutationChangeRequestContractTest do
  use Rulestead.RepoCase, async: false

  import Ecto.Query
  import Rulestead.StoreFixtures

  alias Rulestead.{Audience, AuditEvent, Environment, Error, Repo}
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.Targeting.AudienceDependencies

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    ensure_phase9_schema!()
    :ok
  end

  test "submit approve execute applies governed audience mutation across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview, correlation_id: "corr-audience-happy-#{adapter_label(adapter)}")
               )

      assert submitted.state == :submitted
      assert submitted.metadata["blast_radius_assessment"]["verdict"] == "above_threshold"
      assert submitted.metadata["preview_evidence_summary"]["preview_fingerprint"] == preview.preview_fingerprint

      assert {:ok, %{change_request: approved}} =
               adapter.approve_change_request(
                 Command.ApproveChangeRequest.new(submitted.id,
                   actor: reviewer(),
                   reason: "Approved"
                 )
               )

      assert approved.state == :approved

      assert {:ok, %{change_request: executed, execution_result: execution_result}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(submitted.id,
                   actor: executor(),
                   reason: "Execute governed audience mutation"
                 )
               )

      assert executed.state == :executed
      assert execution_result.result == :ok

      assert audience_plan_value(audience_definition(adapter)) == "pro"
    end)
  end

  test "stale preview at execute keeps change request approved across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview, correlation_id: "corr-audience-stale-#{adapter_label(adapter)}")
               )

      assert {:ok, %{change_request: _approved}} =
               adapter.approve_change_request(
                 Command.ApproveChangeRequest.new(submitted.id, actor: reviewer(), reason: "Approved")
               )

      drift_audience_definition!(adapter)

      assert {:error, %Error{type: :invalid_command, message: message}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(submitted.id, actor: executor(), reason: "Execute")
               )

      assert message =~ "stale"

      assert {:ok, %{change_request: fetched}} =
               adapter.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

      assert fetched.state == :approved
    end)
  end

  test "reject leaves audience unchanged with blast radius audit evidence" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      before_definition = audience_definition(adapter)
      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview, correlation_id: "corr-audience-reject-#{adapter_label(adapter)}")
               )

      assert {:ok, %{change_request: rejected}} =
               adapter.reject_change_request(
                 Command.RejectChangeRequest.new(submitted.id,
                   actor: reviewer(),
                   reason: "Not ready"
                 )
               )

      assert rejected.state == :rejected
      assert audience_definition(adapter) == before_definition

      assert {:ok, %{audit_events: audit_events}} =
               adapter.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

      rejected_event = Enum.find(audit_events, &(&1.event_type == "change_request.rejected"))

      assert get_in(audit_context_metadata(rejected_event), ["blast_radius_assessment", "verdict"]) ==
               "above_threshold"

      assert get_in(audit_context_metadata(rejected_event), ["preview_evidence_summary", "preview_fingerprint"]) ==
               preview.preview_fingerprint
    end)
  end

  test "submit embeds frozen preview_evidence_summary across adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview,
                   correlation_id: "corr-audience-evidence-#{adapter_label(adapter)}"
                 )
               )

      summary = submitted.metadata["preview_evidence_summary"]
      assert summary["preview_fingerprint"] == preview.preview_fingerprint
      assert summary["uncertainty"]["authoritative_population_count?"] == false

      assert {:ok, %{change_request: fetched}} =
               adapter.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

      assert fetched.metadata["preview_evidence_summary"] == summary
    end)
  end

  test "cancel leaves audience definition unchanged" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)

      before_definition = audience_definition(adapter)
      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview, correlation_id: "corr-audience-cancel-#{adapter_label(adapter)}")
               )

      assert {:ok, %{change_request: cancelled}} =
               adapter.cancel_change_request(
                 Command.CancelChangeRequest.new(submitted.id,
                   actor: submitter(),
                   reason: "No longer needed"
                 )
               )

      assert cancelled.state == :cancelled
      assert audience_definition(adapter) == before_definition

      assert {:ok, %{audit_events: audit_events}} =
               adapter.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

      cancelled_event = Enum.find(audit_events, &(&1.event_type == "change_request.cancelled"))

      assert Map.has_key?(audit_context_metadata(cancelled_event), "blast_radius_assessment")

      assert get_in(audit_context_metadata(cancelled_event), ["preview_evidence_summary", "preview_fingerprint"]) ==
               preview.preview_fingerprint
    end)
  end

  test "execute rejected change request fails with invalid_command" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_production_audience_references!(adapter, 3)
      {:ok, preview} = preview_audience_impact(adapter, production_preview_attrs())

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 audience_submit_command(preview,
                   correlation_id: "corr-audience-exec-reject-#{adapter_label(adapter)}"
                 )
               )

      assert {:ok, %{change_request: rejected}} =
               adapter.reject_change_request(
                 Command.RejectChangeRequest.new(submitted.id, actor: reviewer(), reason: "Rejected")
               )

      assert rejected.state == :rejected

      assert {:error, %Error{type: :invalid_command}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(submitted.id, actor: executor(), reason: "Execute")
               )
    end)
  end

  defp audit_context_metadata(%{metadata: metadata}) do
    Map.get(metadata, "context") || Map.get(metadata, :context) || %{}
  end

  defp audience_plan_value(definition) do
    conditions = Map.get(definition, "conditions") || Map.get(definition, :conditions) || []
    first = hd(conditions)
    Map.get(first, "value") || Map.get(first, :value)
  end

  defp adapter_label(Rulestead.Fake), do: "fake"
  defp adapter_label(StoreEcto), do: "ecto"

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
          "affected_reference_keys" => AudienceDependencies.reference_keys(preview.affected_references),
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
      actor: submitter(),
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
    StoreEcto.preview_audience_impact(Command.PreviewAudienceImpact.new("vip-users", :update, attrs))
  end

  defp seed_production_audience_references!(Rulestead.Fake, count) do
    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()

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
    reset_repo!()

    %Audience{}
    |> Audience.changeset(%{
      key: "vip-users",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })
    |> Repo.insert!()

    for index <- 1..count do
      flag_key = "checkout-redesign-#{index}"

      assert {:ok, _flag} =
               StoreEcto.create_flag(
                 Command.CreateFlag.new(valid_flag_attrs(%{key: flag_key, environment_keys: ["production"]}))
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
               StoreEcto.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, "production", ruleset))

      assert {:ok, _published} =
               StoreEcto.publish_ruleset(Command.PublishRuleset.new(flag_key, "production"))
    end
  end

  defp audience_definition(Rulestead.Fake) do
    Rulestead.Fake.Control.snapshot!()
    |> get_in([:audiences, "vip-users", :definition])
  end

  defp audience_definition(StoreEcto) do
    Repo.get_by!(Audience, key: "vip-users").definition
  end

  defp drift_audience_definition!(Rulestead.Fake) do
    snapshot = Rulestead.Fake.Control.snapshot!()

    updated =
      put_in(snapshot, [:audiences, "vip-users", :definition], %{
        conditions: [%{attribute: "plan", operator: "eq", value: "drifted"}]
      })

    Rulestead.Fake.Control.restore!(updated)
  end

  defp drift_audience_definition!(StoreEcto) do
    Repo.get_by!(Audience, key: "vip-users")
    |> Audience.changeset(%{
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "drifted"}]}
    })
    |> Repo.update!()
  end

  defp reset_adapter!(Rulestead.Fake), do: :ok
  defp reset_adapter!(StoreEcto), do: reset_repo!()

  defp submitter, do: %{id: "submitter-1", type: "operator", display: "Submitter"}
  defp reviewer, do: %{id: "reviewer-1", type: "operator", display: "Reviewer"}
  defp executor, do: %{id: "executor-1", type: "operator", display: "Executor"}

  defp reset_repo! do
    Repo.delete_all(AuditEvent)
    Repo.delete_all(from(a in Audience))
    Repo.delete_all(from(f in Rulestead.Flag))
    Repo.delete_all(from(fe in Rulestead.FlagEnvironment))
    Repo.delete_all(from(r in Rulestead.Ruleset))
    Repo.delete_all(from(e in Environment))

    for attrs <- default_environments() do
      %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
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
