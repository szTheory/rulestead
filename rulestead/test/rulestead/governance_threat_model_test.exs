defmodule Rulestead.GovernanceThreatModelTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.{AuditEvent, Error, Governance.ApprovalRequirement, Repo, Store.Command}
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, StoreEcto)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.GovernancePolicy)
    ensure_phase9_schema!()
    seed_governed_publish!(StoreEcto)

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "direct production publish is denied and records a denied audit row" do
    actor = %{id: "prod-operator-1", roles: [:prod_operator], display: "Prod Operator"}

    assert {:error, %Error{domain: :auth, type: :unauthorized}} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "production",
                 version: 2,
                 actor: actor,
                 metadata: %{request_id: "req-direct-publish"}
               )
             )

    assert {:ok, page} =
             Rulestead.list_audit_events(
               flag_key: "checkout-redesign",
               actor: %{id: "auditor-1", roles: [:auditor]},
               limit: 10
             )

    assert Enum.any?(page.entries, fn event ->
             event.event_type == "ruleset.publish" and event.result == :denied and
               event.correlation_id == "req-direct-publish"
           end)
  end

  test "production self-approval is denied by default without caller-supplied submitter metadata" do
    actor = %{
      id: "prod-operator-1",
      type: "operator",
      display: "Prod Operator",
      roles: [:prod_operator]
    }

    assert {:ok, %{change_request: submitted}} =
             Rulestead.submit_change_request(
               governed_publish_command(actor,
                 reason: "Self approval should fail",
                 request_id: "corr-self-approval"
               )
             )

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: actor,
                 reason: "Approving my own request"
               )
             )

    assert error.metadata == %{
             action: "approve_change_request",
             environment_key: "production",
             reason: "self_approval_forbidden"
           }
  end

  test "audit rows stay correlated across submit approve execute and cancellation lifecycles" do
    submitter = %{
      id: "submitter-3",
      type: "operator",
      display: "Submitter",
      roles: [:prod_operator]
    }

    reviewer = %{id: "reviewer-3", type: "operator", display: "Reviewer", roles: [:prod_operator]}
    executor = %{id: "executor-3", type: "operator", display: "Executor", roles: [:prod_operator]}

    assert {:ok, %{change_request: executed_request}} =
             Rulestead.submit_change_request(
               governed_publish_command(submitter,
                 reason: "Execute path",
                 request_id: "corr-execute"
               )
             )
             |> then(fn {:ok, %{change_request: submitted}} ->
               assert {:ok, %{change_request: _approved}} =
                        Rulestead.approve_change_request(
                          Command.ApproveChangeRequest.new(submitted.id,
                            actor: reviewer,
                            reason: "Peer approved"
                          )
                        )

               Rulestead.execute_change_request(
                 Command.ExecuteChangeRequest.new(submitted.id,
                   actor: executor,
                   reason: "Execute now"
                 )
               )
             end)

    assert {:ok, %{change_request: cancelled_request}} =
             Rulestead.submit_change_request(
               governed_publish_command(submitter,
                 reason: "Cancel path",
                 request_id: "corr-cancelled"
               )
             )

    assert {:ok, %{change_request: cancelled_request}} =
             Rulestead.cancel_change_request(
               Command.CancelChangeRequest.new(cancelled_request.id,
                 actor: submitter,
                 reason: "No longer needed"
               )
             )

    correlated =
      Repo.all(
        from(event in AuditEvent,
          order_by: [asc: event.inserted_at, asc: event.event_type],
          select: event
        )
      )
      |> Enum.group_by(& &1.correlation_id)

    assert Map.has_key?(correlated, "corr-execute")
    assert Map.has_key?(correlated, "corr-cancelled")

    assert Enum.map(correlated["corr-execute"], & &1.event_type) == [
             "change_request.submitted",
             "change_request.approved",
             "ruleset.publish",
             "change_request.merged"
           ]

    assert Enum.map(correlated["corr-cancelled"], & &1.event_type) == [
             "change_request.submitted",
             "change_request.cancelled"
           ]

    assert Enum.all?(
             correlated["corr-execute"],
             &(&1.metadata["change_request_id"] == executed_request.id)
           )

    assert Enum.all?(
             correlated["corr-cancelled"],
             &(&1.metadata["change_request_id"] == cancelled_request.id)
           )
  end

  defp governed_publish_command(actor, opts) do
    Command.SubmitChangeRequest.new(
      %{
        action: :publish_ruleset,
        environment_key: "production",
        resource_type: "flag",
        resource_key: "checkout-redesign",
        command: %{"version" => 2},
        approval_requirement:
          ApprovalRequirement.new(
            action: :publish_ruleset,
            environment_key: "production",
            required_approvals: 1,
            change_request_required?: true,
            self_approval_allowed?: false
          )
      },
      actor: actor,
      reason: Keyword.fetch!(opts, :reason),
      metadata: %{request_id: Keyword.fetch!(opts, :request_id), source: :review_queue}
    )
  end

  defp seed_governed_publish!(adapter) do
    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(
                 StoreFixtures.valid_flag_attrs(%{
                   permanent: true,
                   environment_keys: ["production"]
                 })
               )
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "production",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "production")
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "production",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )
  end

  defp ensure_phase9_schema! do
    Repo.query!("ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false")

    Repo.query!(
      "ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone"
    )

    Repo.query!("CREATE TABLE IF NOT EXISTS change_requests (
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

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS change_requests_correlation_id_index ON change_requests (correlation_id)"
    )

    Repo.query!(
      "CREATE INDEX IF NOT EXISTS change_requests_environment_status_index ON change_requests (environment_key, status)"
    )

    Repo.query!("CREATE TABLE IF NOT EXISTS approvals (
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

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS approvals_change_request_reviewer_index ON approvals (change_request_id, reviewer_id)"
    )

    Repo.query!(
      "CREATE INDEX IF NOT EXISTS approvals_change_request_reviewed_at_index ON approvals (change_request_id, reviewed_at)"
    )
  end

  defmodule GovernancePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, :publish_ruleset, _resource, "production"), do: true

    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def allow_self_approval?(_actor, _action, _resource, "production"), do: false

    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end
end
