# credo:disable-for-this-file
defmodule Rulestead.GovernanceAdapterContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

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

  test "submit, approve, and execute stay correlated across fake and ecto adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_governed_publish!(adapter)

      submitter = %{id: "submitter-1", type: "operator", display: "Submitter"}
      reviewer = %{id: "reviewer-1", type: "operator", display: "Reviewer"}
      executor = %{id: "executor-1", type: "operator", display: "Executor"}

      submit_command =
        Command.SubmitChangeRequest.new(
          %{
            action: :publish_ruleset,
            environment_key: "test",
            resource_type: "flag",
            resource_key: "checkout-redesign",
            command: %{"version" => 2},
            approval_requirement:
              ApprovalRequirement.new(
                action: :publish_ruleset,
                environment_key: "test",
                required_approvals: 1,
                change_request_required?: true,
                self_approval_allowed?: false
              )
          },
          actor: submitter,
          reason: "Ship version 2",
          metadata: %{request_id: "corr-123", source: :review_queue}
        )

      assert {:ok, %{change_request: submitted}} = adapter.submit_change_request(submit_command)
      assert submitted.state == :submitted
      assert submitted.correlation_id == "corr-123"

      assert {:ok, %{change_request: approved, approval: approval}} =
               adapter.approve_change_request(
                 Command.ApproveChangeRequest.new(submitted.id,
                   actor: reviewer,
                   reason: "Approved",
                   metadata: %{request_id: "req-approve"}
                 )
               )

      assert approved.state == :approved
      assert approval.change_request_id == submitted.id
      assert approval.correlation_id == "corr-123"

      assert {:ok, %{change_request: executed, execution_result: execution_result}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(submitted.id,
                   actor: executor,
                   reason: "Execute now",
                   metadata: %{request_id: "req-execute"}
                 )
               )

      assert executed.state == :executed
      assert executed.correlation_id == "corr-123"
      assert execution_result.active_ruleset.version == 2

      assert {:ok, %{change_request: fetched, approvals: approvals, audit_events: audit_events}} =
               adapter.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

      assert fetched.state == :executed
      assert [%{decision: :approved, correlation_id: "corr-123"}] = approvals

      event_types = Enum.map(audit_events, & &1.event_type)

      assert "change_request.submitted" in event_types
      assert "change_request.approved" in event_types
      assert "change_request.merged" in event_types
      assert "ruleset.publish" in event_types
      assert Enum.all?(audit_events, &(&1.correlation_id == "corr-123"))
      assert Enum.all?(audit_events, &(&1.resource_key == "checkout-redesign"))

      assert {:ok, %Command.Page{entries: entries}} =
               adapter.list_change_requests(
                 Command.ListChangeRequests.new(environment_key: "test", status: :executed)
               )

      assert Enum.any?(entries, &(&1.id == submitted.id and &1.state == :executed))

      assert {:ok, %Command.Page{entries: string_entries}} =
               adapter.list_change_requests(
                 Command.ListChangeRequests.new(
                   environment_key: "test",
                   action: "publish_ruleset",
                   status: "executed"
                 )
               )

      assert Enum.any?(string_entries, &(&1.id == submitted.id and &1.state == :executed))
    end)
  end

  test "rejected and cancelled change requests are terminal in both adapters" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_governed_publish!(adapter)

      submitter = %{id: "submitter-2", type: "operator", display: "Submitter"}
      reviewer = %{id: "reviewer-2", type: "operator", display: "Reviewer"}

      assert {:ok, %{change_request: rejected_request}} =
               adapter.submit_change_request(
                 governed_publish_command("corr-reject", submitter, "Reject path")
               )

      assert {:ok, %{change_request: rejected}} =
               adapter.reject_change_request(
                 Command.RejectChangeRequest.new(rejected_request.id,
                   actor: reviewer,
                   reason: "Missing context",
                   metadata: %{request_id: "req-reject"}
                 )
               )

      assert rejected.state == :rejected

      assert {:error, %Rulestead.Error{type: :invalid_command}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(rejected.id, actor: reviewer)
               )

      assert {:ok, %{change_request: cancelled_request}} =
               adapter.submit_change_request(
                 governed_publish_command("corr-cancel", submitter, "Cancel path")
               )

      assert {:ok, %{change_request: cancelled}} =
               adapter.cancel_change_request(
                 Command.CancelChangeRequest.new(cancelled_request.id,
                   actor: submitter,
                   reason: "No longer needed",
                   metadata: %{request_id: "req-cancel"}
                 )
               )

      assert cancelled.state == :cancelled

      assert {:error, %Rulestead.Error{type: :invalid_command}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(cancelled.id, actor: reviewer)
               )
    end)
  end

  defp governed_publish_command(correlation_id, actor, reason) do
    Command.SubmitChangeRequest.new(
      %{
        action: :publish_ruleset,
        environment_key: "test",
        resource_type: "flag",
        resource_key: "checkout-redesign",
        command: %{"version" => 2},
        approval_requirement:
          ApprovalRequirement.new(
            action: :publish_ruleset,
            environment_key: "test",
            required_approvals: 1,
            change_request_required?: true,
            self_approval_allowed?: false
          )
      },
      actor: actor,
      reason: reason,
      metadata: %{request_id: correlation_id, source: :review_queue}
    )
  end

  defp seed_governed_publish!(adapter) do
    ensure_environment!("test")

    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(StoreFixtures.valid_flag_attrs(%{permanent: true}))
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "test",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test")
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "test",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )
  end

  defp reset_adapter!(Rulestead.Fake) do
    Rulestead.Fake.Control.reset!()
  end

  defp reset_adapter!(StoreEcto) do
    :ok
  end

  defp ensure_environment!(key) do
    case Rulestead.Repo.get_by(Rulestead.Environment, key: key) do
      nil ->
        attrs = StoreFixtures.valid_environment_attrs(%{key: key, name: String.upcase(key)})
        changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)
        assert {:ok, _env} = Rulestead.Repo.insert(changeset)

      _env ->
        :ok
    end
  end

  defp ensure_phase9_schema! do
    Rulestead.Repo.query!(
      "ALTER TABLE rulestead.flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE rulestead.flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.change_requests (
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
      "CREATE UNIQUE INDEX IF NOT EXISTS change_requests_correlation_id_index ON rulestead.change_requests (correlation_id)"
    )

    Rulestead.Repo.query!(
      "CREATE INDEX IF NOT EXISTS change_requests_environment_status_index ON rulestead.change_requests (environment_key, status)"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.approvals (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      change_request_id uuid NOT NULL REFERENCES rulestead.change_requests(id) ON DELETE CASCADE,
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
      "CREATE UNIQUE INDEX IF NOT EXISTS approvals_change_request_reviewer_index ON rulestead.approvals (change_request_id, reviewer_id)"
    )

    Rulestead.Repo.query!(
      "CREATE INDEX IF NOT EXISTS approvals_change_request_reviewed_at_index ON rulestead.approvals (change_request_id, reviewed_at)"
    )
  end
end
