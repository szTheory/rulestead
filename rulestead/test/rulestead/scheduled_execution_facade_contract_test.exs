# credo:disable-for-this-file
defmodule Rulestead.ScheduledExecutionFacadeContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.Store.Command
  alias Rulestead.StoreFixtures

  setup do
    ensure_phase10_schema!()
    reset_fake_store!()
    :ok
  end

  test "approved change requests can be scheduled and fetched/listed from the public facade" do
    seed_publishable_flag!()
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.AllowAllPolicy)

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    assert {:ok, %{change_request: change_request}} =
             Rulestead.submit_change_request(
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
                       self_approval_allowed?: true
                     )
                 },
                 actor: %{
                   id: "operator-1",
                   type: "operator",
                   display: "Operator One",
                   roles: [:operator]
                 },
                 reason: "Schedule reviewed publish",
                 metadata: %{request_id: "req-cr-submit", source: :admin_ui}
               )
             )

    assert {:ok, %{change_request: approved_change_request}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(change_request.id,
                 actor: %{
                   id: "reviewer-1",
                   type: "operator",
                   display: "Reviewer One",
                   roles: [:operator]
                 },
                 reason: "Approved for scheduling",
                 metadata: %{request_id: "req-cr-approve", source: :admin_ui}
               )
             )

    scheduled_for = ~U[2026-04-25 18:00:00Z]

    assert {:ok, %{scheduled_execution: scheduled_execution, attempts: []}} =
             Rulestead.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved_change_request.id,
                 scheduled_for: scheduled_for,
                 actor: %{
                   id: "scheduler-1",
                   type: "operator",
                   display: "Scheduler One",
                   roles: [:operator]
                 },
                 reason: "Wait for launch window",
                 metadata: %{request_id: "req-schedule-cr", source: :admin_ui}
               })
             )

    assert scheduled_execution.change_request_id == approved_change_request.id
    assert scheduled_execution.action == :publish_ruleset
    assert scheduled_execution.execution_mode == :change_request

    assert scheduled_execution.scheduled_by == %{
             "id" => "scheduler-1",
             "type" => "operator",
             "display" => "Scheduler One"
           }

    assert {:ok, %{scheduled_execution: fetched, attempts: []}} =
             Rulestead.fetch_scheduled_execution(
               Command.FetchScheduledExecution.new(scheduled_execution.id)
             )

    assert fetched.id == scheduled_execution.id
    assert DateTime.compare(fetched.scheduled_for, scheduled_for) == :eq

    assert {:ok, %Command.Page{entries: entries}} =
             Rulestead.list_scheduled_executions(
               Command.ListScheduledExecutions.new(
                 change_request_id: approved_change_request.id,
                 environment_key: "test",
                 action: :publish_ruleset
               )
             )

    assert Enum.any?(entries, &(&1.id == scheduled_execution.id))
  end

  test "direct scheduling allows policy bypass only when policy allows it and requires loud emergency metadata" do
    seed_publishable_flag!()
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.SchedulingPolicy)

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    scheduled_for = ~U[2026-04-25 19:00:00Z]

    assert {:ok, %{scheduled_execution: policy_bypass}} =
             Rulestead.schedule_governed_action(
               Command.ScheduleGovernedAction.new(%{
                 action: :release_kill_switch,
                 environment_key: "staging",
                 resource_type: "flag",
                 resource_key: "checkout-redesign",
                 command: %{},
                 scheduled_for: scheduled_for,
                 execution_mode: :policy_bypass,
                 actor: %{id: "scheduler-2", type: "operator", display: "Scheduler Two"},
                 reason: "Clear the incident hold",
                 metadata: %{request_id: "req-policy-bypass", source: :admin_ui}
               })
             )

    assert policy_bypass.action == :release_kill_switch
    assert policy_bypass.execution_mode == :policy_bypass

    assert {:error, %Rulestead.Error{domain: :auth, type: :unauthorized}} =
             Rulestead.schedule_governed_action(
               Command.ScheduleGovernedAction.new(%{
                 action: :publish_ruleset,
                 environment_key: "production",
                 resource_type: "flag",
                 resource_key: "checkout-redesign",
                 command: %{"version" => 2},
                 scheduled_for: scheduled_for,
                 execution_mode: :policy_bypass,
                 actor: %{id: "scheduler-2", type: "operator", display: "Scheduler Two"},
                 reason: "Attempt direct production publish",
                 metadata: %{request_id: "req-policy-denied", source: :admin_ui}
               })
             )

    assert {:error, %Rulestead.Error{domain: :store, type: :invalid_command}} =
             Rulestead.schedule_governed_action(
               Command.ScheduleGovernedAction.new(%{
                 action: :engage_kill_switch,
                 environment_key: "production",
                 resource_type: "flag",
                 resource_key: "checkout-redesign",
                 command: %{},
                 scheduled_for: scheduled_for,
                 execution_mode: :emergency_bypass,
                 actor: %{id: "incident-1", type: "operator", display: "Incident Commander"},
                 reason: "Page is on fire",
                 metadata: %{request_id: "req-emergency-missing", source: :admin_ui}
               })
             )

    assert {:ok, %{scheduled_execution: emergency_bypass}} =
             Rulestead.schedule_governed_action(
               Command.ScheduleGovernedAction.new(%{
                 action: :engage_kill_switch,
                 environment_key: "production",
                 resource_type: "flag",
                 resource_key: "checkout-redesign",
                 command: %{},
                 scheduled_for: scheduled_for,
                 execution_mode: :emergency_bypass,
                 actor: %{id: "incident-1", type: "operator", display: "Incident Commander"},
                 reason: "Customer impact mitigation",
                 metadata: %{
                   request_id: "req-emergency-ok",
                   source: :admin_ui,
                   emergency_reason: "checkout outage"
                 }
               })
             )

    assert emergency_bypass.execution_mode == :emergency_bypass
    assert emergency_bypass.scheduled_by["id"] == "incident-1"
    assert emergency_bypass.metadata["emergency_reason"] == "checkout outage"
  end

  defmodule SchedulingPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, action, _resource, "production")
        when action in [
               :publish_ruleset,
               :advance_rollout,
               :engage_kill_switch,
               :release_kill_switch
             ],
        do: true

    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  defmodule AllowAllPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true
  end

  defp seed_publishable_flag! do
    assert {:ok, _} =
             StoreEcto.create_flag(
               Command.CreateFlag.new(
                 StoreFixtures.valid_flag_attrs(%{permanent: true}),
                 actor: %{id: "creator-1", type: "operator", display: "Creator One"}
               )
             )

    assert {:ok, _} =
             StoreEcto.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "test",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )
  end

  defp reset_fake_store! do
    Rulestead.Fake.Control.reset!()
  end

  defp ensure_phase10_schema! do
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

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS scheduled_executions (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      state text NOT NULL DEFAULT 'scheduled',
      change_request_id uuid REFERENCES change_requests(id) ON DELETE SET NULL,
      governed_action text NOT NULL,
      environment_key text,
      resource_type text,
      resource_key text,
      execution_mode text NOT NULL DEFAULT 'change_request',
      scheduled_by_id text NOT NULL,
      scheduled_by_type text NOT NULL,
      scheduled_by_display text,
      approved_by_snapshot jsonb NOT NULL DEFAULT '[]'::jsonb,
      execution_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      scheduled_for timestamp(6) with time zone NOT NULL,
      executed_at timestamp(6) with time zone,
      attempt_count integer NOT NULL DEFAULT 0,
      failure_reason text,
      last_oban_job_id bigint,
      command_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      approval_requirement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      idempotency_key text NOT NULL,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_correlation_id_index ON scheduled_executions (correlation_id)"
    )

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_idempotency_key_index ON scheduled_executions (idempotency_key)"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS execution_attempts (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      scheduled_execution_id uuid NOT NULL REFERENCES scheduled_executions(id) ON DELETE CASCADE,
      attempt_number integer NOT NULL,
      state text NOT NULL,
      started_at timestamp(6) with time zone NOT NULL,
      finished_at timestamp(6) with time zone,
      failure_reason text,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS execution_attempts_scheduled_execution_attempt_number_index ON execution_attempts (scheduled_execution_id, attempt_number)"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS oban_jobs (
      id bigserial PRIMARY KEY,
      state text NOT NULL DEFAULT 'scheduled',
      queue text NOT NULL DEFAULT 'default',
      worker text NOT NULL,
      args jsonb NOT NULL DEFAULT '{}'::jsonb,
      meta jsonb NOT NULL DEFAULT '{}'::jsonb,
      tags text[] NOT NULL DEFAULT '{}',
      errors jsonb[] NOT NULL DEFAULT '{}',
      attempt integer NOT NULL DEFAULT 0,
      max_attempts integer NOT NULL DEFAULT 3,
      priority integer NOT NULL DEFAULT 0,
      attempted_by text[],
      attempted_at timestamp(6) with time zone,
      cancelled_at timestamp(6) with time zone,
      completed_at timestamp(6) with time zone,
      discarded_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      scheduled_at timestamp(6) with time zone NOT NULL
    )")
  end
end
