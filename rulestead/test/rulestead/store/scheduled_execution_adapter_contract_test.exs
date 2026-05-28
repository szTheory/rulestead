# credo:disable-for-this-file
defmodule Rulestead.ScheduledExecutionAdapterContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    ensure_phase10_schema!()
    :ok
  end

  defp with_store_adapter(adapter, fun) when is_function(fun, 0) do
    previous_store = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, adapter)

    try do
      fun.()
    after
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end
  end

  test "transient failures append attempts and preserve the same scheduled execution identity" do
    Enum.each(@adapters, fn adapter ->
      with_store_adapter(adapter, fn ->
        reset_adapter!(adapter)
      seed_publishable_flag!(adapter)

      scheduled_for = ~U[2026-04-25 12:30:00Z]

      assert {:ok, %{scheduled_execution: scheduled_execution}} =
               adapter.schedule_governed_action(
                 Command.ScheduleGovernedAction.new(%{
                   action: :publish_ruleset,
                   environment_key: "test",
                   resource_type: "flag",
                   resource_key: "checkout-redesign",
                   command: %{"version" => 3},
                   scheduled_for: scheduled_for,
                   execution_mode: :policy_bypass,
                   actor: %{id: "scheduler-1", type: "operator", display: "Scheduler"},
                   reason: "Publish v3",
                   approval_requirement:
                     ApprovalRequirement.new(
                       action: :publish_ruleset,
                       environment_key: "test",
                       required_approvals: 0,
                       change_request_required?: false,
                       self_approval_allowed?: true
                     ),
                   metadata: %{request_id: "corr-transient", source: :admin_ui}
                 })
               )

      assert {:error, %Rulestead.Error{}} =
               adapter.execute_scheduled_execution(
                 Command.ExecuteScheduledExecution.new(scheduled_execution.id,
                   actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                   reason: "Due now",
                   metadata: %{request_id: "req-transient-1", source: :scheduled_execution_worker}
                 )
               )

      assert {:ok, %{scheduled_execution: failed_once, attempts: attempts}} =
               adapter.fetch_scheduled_execution(
                 Command.FetchScheduledExecution.new(scheduled_execution.id)
               )

      assert failed_once.id == scheduled_execution.id
      assert failed_once.state == :scheduled
      assert failed_once.attempt_count == 1
      assert [%{attempt_number: 1, state: :failed}] = attempts

      assert {:ok, _} =
               adapter.save_draft_ruleset(
                 StoreFixtures.save_draft_command(
                   "checkout-redesign",
                   "test",
                   StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v3"})
                 )
               )

      assert {:ok, %{scheduled_execution: completed}} =
               adapter.execute_scheduled_execution(
                 Command.ExecuteScheduledExecution.new(scheduled_execution.id,
                   actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                   reason: "Retry after fix",
                   metadata: %{request_id: "req-transient-2", source: :scheduled_execution_worker}
                 )
               )

      assert completed.id == scheduled_execution.id
      assert completed.state == :completed

      assert {:ok, %{scheduled_execution: fetched, attempts: completed_attempts}} =
               adapter.fetch_scheduled_execution(
                 Command.FetchScheduledExecution.new(scheduled_execution.id)
               )

      assert fetched.id == scheduled_execution.id
      assert fetched.state == :completed
      assert fetched.attempt_count == 2

      assert Enum.map(completed_attempts, &{&1.attempt_number, &1.state}) == [
               {1, :failed},
               {2, :completed}
             ]
      end)
    end)
  end

  test "completed executions are replay safe and quarantined executions require explicit requeue" do
    Enum.each(@adapters, fn adapter ->
      with_store_adapter(adapter, fn ->
        reset_adapter!(adapter)
      seed_publishable_flag!(adapter)

      assert {:ok, %{scheduled_execution: completed_schedule}} =
               adapter.schedule_governed_action(scheduled_publish_command(2, "corr-complete"))

      assert {:ok, %{scheduled_execution: completed}} =
               adapter.execute_scheduled_execution(
                 Command.ExecuteScheduledExecution.new(completed_schedule.id,
                   actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                   reason: "Execute",
                   metadata: %{request_id: "req-complete-1", source: :scheduled_execution_worker}
                 )
               )

      assert completed.state == :completed

      assert {:ok, %{scheduled_execution: replayed}} =
               adapter.execute_scheduled_execution(
                 Command.ExecuteScheduledExecution.new(completed_schedule.id,
                   actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                   reason: "Replay",
                   metadata: %{request_id: "req-complete-2", source: :scheduled_execution_worker}
                 )
               )

      assert replayed.id == completed_schedule.id
      assert replayed.state == :completed

      assert {:ok, %{scheduled_execution: failed_schedule}} =
               adapter.schedule_governed_action(scheduled_publish_command(9, "corr-quarantine"))

      for attempt <- 1..3 do
        assert {:error, %Rulestead.Error{}} =
                 adapter.execute_scheduled_execution(
                   Command.ExecuteScheduledExecution.new(failed_schedule.id,
                     actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                     reason: "Attempt #{attempt}",
                     metadata: %{
                       request_id: "req-quarantine-#{attempt}",
                       source: :scheduled_execution_worker
                     }
                   )
                 )
      end

      assert {:ok, %{scheduled_execution: quarantined}} =
               adapter.fetch_scheduled_execution(
                 Command.FetchScheduledExecution.new(failed_schedule.id)
               )

      assert quarantined.id == failed_schedule.id
      assert quarantined.state == :quarantined
      assert quarantined.attempt_count == 3
      assert is_binary(quarantined.failure_reason)
      assert quarantined.failure_reason != ""

      assert {:ok, %{scheduled_execution: requeued}} =
               adapter.requeue_scheduled_execution(
                 Command.RequeueScheduledExecution.new(failed_schedule.id,
                   actor: %{id: "operator-1", type: "operator", display: "Operator"},
                   reason: "Retry after repair",
                   metadata: %{request_id: "req-requeue", source: :admin_ui}
                 )
               )

      assert requeued.id == failed_schedule.id
      assert requeued.state == :scheduled
      assert requeued.failure_reason == nil
      end)
    end)
  end

  test "cancel fetch and list expose the same normalized vocabulary in fake and ecto" do
    Enum.each(@adapters, fn adapter ->
      with_store_adapter(adapter, fn ->
        reset_adapter!(adapter)
      seed_publishable_flag!(adapter)

      assert {:ok, %{scheduled_execution: cancelled_schedule}} =
               adapter.schedule_governed_action(scheduled_publish_command(2, "corr-cancel"))

      assert {:ok, %{scheduled_execution: cancelled}} =
               adapter.cancel_scheduled_execution(
                 Command.CancelScheduledExecution.new(cancelled_schedule.id,
                   actor: %{id: "operator-2", type: "operator", display: "Operator"},
                   reason: "Launch moved",
                   metadata: %{request_id: "req-cancel-scheduled", source: :admin_ui}
                 )
               )

      assert cancelled.state == :cancelled

      assert {:ok, %{scheduled_execution: quarantined_schedule}} =
               adapter.schedule_governed_action(
                 scheduled_publish_command(11, "corr-list-quarantine")
               )

      for attempt <- 1..3 do
        assert {:error, %Rulestead.Error{}} =
                 adapter.execute_scheduled_execution(
                   Command.ExecuteScheduledExecution.new(quarantined_schedule.id,
                     actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                     reason: "Attempt #{attempt}",
                     metadata: %{
                       request_id: "req-list-quarantine-#{attempt}",
                       source: :scheduled_execution_worker
                     }
                   )
                 )
      end

      assert {:ok, %{scheduled_execution: fetched_cancelled, attempts: cancelled_attempts}} =
               adapter.fetch_scheduled_execution(
                 Command.FetchScheduledExecution.new(cancelled_schedule.id)
               )

      assert fetched_cancelled.id == cancelled_schedule.id
      assert fetched_cancelled.state == :cancelled
      assert fetched_cancelled.action == :publish_ruleset
      assert fetched_cancelled.environment_key == "test"
      assert fetched_cancelled.resource_key == "checkout-redesign"
      assert cancelled_attempts == []

      assert {:ok, %{scheduled_execution: fetched_quarantined, attempts: quarantined_attempts}} =
               adapter.fetch_scheduled_execution(
                 Command.FetchScheduledExecution.new(quarantined_schedule.id)
               )

      assert fetched_quarantined.state == :quarantined
      assert length(quarantined_attempts) == 3

      assert {:ok, %Command.Page{entries: cancelled_entries}} =
               adapter.list_scheduled_executions(
                 Command.ListScheduledExecutions.new(
                   environment_key: "test",
                   state: :cancelled,
                   action: :publish_ruleset,
                   resource_key: "checkout-redesign",
                   after: ~U[2026-04-25 12:00:00Z],
                   before: ~U[2026-04-25 13:00:00Z],
                   limit: 10
                 )
               )

      assert Enum.any?(
               cancelled_entries,
               &(&1.id == cancelled_schedule.id and &1.state == :cancelled)
             )

      assert {:ok, %Command.Page{entries: quarantined_entries}} =
               adapter.list_scheduled_executions(
                 Command.ListScheduledExecutions.new(
                   environment_key: "test",
                   state: "quarantined",
                   action: "publish_ruleset",
                   resource_key: "checkout-redesign",
                   after: ~U[2026-04-25 12:00:00Z],
                   before: ~U[2026-04-25 13:00:00Z],
                   limit: 10
                 )
               )

      assert Enum.any?(
               quarantined_entries,
               &(&1.id == quarantined_schedule.id and &1.state == :quarantined)
             )
      end)
    end)
  end

  test "approved protected-target promotion executes the stored bundle snapshot" do
    Enum.each(@adapters, fn adapter ->
      with_store_adapter(adapter, fn ->
        reset_adapter!(adapter)
      seed_promotable_flag!(adapter)

      compare = promotion_compare!(adapter)

      assert {:ok, %{change_request: submitted}} =
               adapter.submit_change_request(
                 governed_promotion_command(compare, "corr-promote-approved")
               )

      assert {:ok, %{change_request: approved}} =
               adapter.approve_change_request(
                 Command.ApproveChangeRequest.new(submitted.id,
                   actor: %{id: "reviewer-1", type: "operator", display: "Reviewer"},
                   reason: "Approved",
                   metadata: %{request_id: "corr-promote-approved", source: :review_queue}
                 )
               )

      assert approved.state == :approved

      assert {:ok, %{change_request: executed, execution_result: execution_result}} =
               adapter.execute_change_request(
                 Command.ExecuteChangeRequest.new(approved.id,
                   actor: %{id: "executor-1", type: "operator", display: "Executor"},
                   reason: "Execute promotion",
                   metadata: %{request_id: "corr-promote-approved", source: :governance_worker}
                 )
               )

      assert executed.state == :executed
      assert execution_result.target_environment_key == "production"
      assert execution_result.applied_flag_keys == ["checkout-redesign"]
      assert is_binary(execution_result.environment_version_id)

      assert {:ok, target_payload} =
               adapter.fetch_flag(Command.FetchFlag.new("checkout-redesign", "production"))

      assert target_payload.active_ruleset.salt == "checkout-redesign:v2"
      end)
    end)
  end

  test "scheduled protected-target promotion revalidates the stored bundle before mutating target" do
    Enum.each(@adapters, fn adapter ->
      with_store_adapter(adapter, fn ->
        reset_adapter!(adapter)
      seed_promotable_flag!(adapter)

      compare = promotion_compare!(adapter)

      assert {:ok, %{scheduled_execution: scheduled_execution}} =
               adapter.schedule_governed_action(
                 scheduled_promotion_command(compare, "corr-promote-scheduled")
               )

      mutate_source_environment!(adapter, "checkout-redesign:v3")

      assert {:error,
              %Rulestead.Error{
                type: :invalid_command,
                message: "promotion compare preview is stale"
              }} =
               adapter.execute_scheduled_execution(
                 Command.ExecuteScheduledExecution.new(scheduled_execution.id,
                   actor: %{id: "scheduler", type: "system", display: "Scheduler"},
                   reason: "Execute scheduled promotion",
                   metadata: %{
                     request_id: "req-promote-scheduled",
                     source: :scheduled_execution_worker
                   }
                 )
               )

      assert {:ok, %{scheduled_execution: fetched, attempts: attempts}} =
               adapter.fetch_scheduled_execution(
                 Command.FetchScheduledExecution.new(scheduled_execution.id)
               )

      assert fetched.state == :scheduled
      assert fetched.attempt_count == 1
      assert [%{attempt_number: 1, state: :failed}] = attempts

      assert {:ok, target_payload} =
               adapter.fetch_flag(Command.FetchFlag.new("checkout-redesign", "production"))

      assert target_payload.active_ruleset.salt == "checkout-redesign:v1"
      end)
    end)
  end

  defp scheduled_publish_command(version, request_id) do
    Command.ScheduleGovernedAction.new(%{
      action: :publish_ruleset,
      environment_key: "test",
      resource_type: "flag",
      resource_key: "checkout-redesign",
      command: %{"version" => version},
      scheduled_for: ~U[2026-04-25 12:30:00Z],
      execution_mode: :policy_bypass,
      actor: %{id: "scheduler-1", type: "operator", display: "Scheduler"},
      reason: "Publish version #{version}",
      approval_requirement:
        ApprovalRequirement.new(
          action: :publish_ruleset,
          environment_key: "test",
          required_approvals: 0,
          change_request_required?: false,
          self_approval_allowed?: true
        ),
      metadata: %{request_id: request_id, source: :admin_ui}
    })
  end

  defp seed_publishable_flag!(adapter) do
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

  defp governed_promotion_command(compare, request_id) do
    Command.SubmitChangeRequest.new(
      %{
        action: :promote_environment,
        environment_key: "production",
        resource_type: "environment",
        resource_key: "production",
        command: promotion_command_attrs(compare),
        approval_requirement:
          ApprovalRequirement.new(
            action: :promote_environment,
            environment_key: "production",
            required_approvals: 1,
            change_request_required?: true,
            self_approval_allowed?: false
          )
      },
      actor: %{id: "submitter-1", type: "operator", display: "Submitter"},
      reason: "Promote checkout to production",
      metadata: %{request_id: request_id, source: :compare_review}
    )
  end

  defp scheduled_promotion_command(compare, request_id) do
    Command.ScheduleGovernedAction.new(
      %{
        action: :promote_environment,
        environment_key: "production",
        resource_type: "environment",
        resource_key: "production",
        command: promotion_command_attrs(compare),
        scheduled_for: ~U[2026-04-25 12:30:00Z],
        execution_mode: :policy_bypass,
        approval_requirement:
          ApprovalRequirement.new(
            action: :promote_environment,
            environment_key: "production",
            required_approvals: 0,
            change_request_required?: false,
            self_approval_allowed?: true
          )
      },
      actor: %{id: "scheduler-1", type: "operator", display: "Scheduler"},
      reason: "Run the reviewed promotion bundle",
      metadata: %{request_id: request_id, source: :compare_review}
    )
  end

  defp promotion_command_attrs(compare) do
    %{
      source_environment_key: compare.source_environment.key,
      target_environment_key: compare.target_environment.key,
      flag_keys: compare.requested_flag_keys,
      compare_token: compare.compare_token,
      compare_schema_version: compare.compare_schema_version,
      source_fingerprint: compare.source_fingerprint,
      target_fingerprint: compare.target_fingerprint,
      dependency_closure_keys: compare.dependency_closure_keys,
      proposed_target_bundle:
        Map.new(compare.flags, fn flag ->
          {flag.flag_key, flag.proposed_target_state}
        end)
    }
  end

  defp promotion_compare!(adapter) do
    assert {:ok, compare} =
             adapter.compare_environments(
               Command.CompareEnvironments.new("staging", "production",
                 flag_keys: ["checkout-redesign"]
               )
             )

    compare
  end

  defp seed_promotable_flag!(adapter) do
    ensure_environment!("staging")
    ensure_environment!("production")
    seed_default_audience!(adapter)

    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(
                 StoreFixtures.valid_flag_attrs(%{
                   permanent: true,
                   environment_keys: ["staging", "production"]
                 })
               )
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "staging",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "staging")
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
  end

  defp mutate_source_environment!(adapter, salt) do
    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "staging",
                 StoreFixtures.valid_ruleset_attrs(%{salt: salt})
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "staging")
             )
  end

  defp seed_default_audience!(Rulestead.Fake) do
    snapshot = Rulestead.Fake.Control.snapshot!()
    now = snapshot.now

    audience = %{
      id: Ecto.UUID.generate(),
      key: "vip-users",
      description: nil,
      definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]},
      archived_at: nil,
      inserted_at: now,
      updated_at: now
    }

    snapshot
    |> put_in([:audiences, "vip-users"], audience)
    |> Rulestead.Fake.Control.restore!()
  end

  defp seed_default_audience!(StoreEcto) do
    case Rulestead.Repo.get_by(Rulestead.Audience, key: "vip-users") do
      nil ->
        %Rulestead.Audience{}
        |> Rulestead.Audience.changeset(%{
          key: "vip-users",
          definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
        })
        |> Rulestead.Repo.insert!()

      _audience ->
        :ok
    end
  end

  defp reset_adapter!(Rulestead.Fake), do: Rulestead.Fake.Control.reset!()
  defp reset_adapter!(StoreEcto), do: :ok

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

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS environment_versions (
      id uuid PRIMARY KEY,
      environment_key varchar(128) NOT NULL,
      version integer NOT NULL,
      authored_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      source_environment_key varchar(128),
      target_environment_key varchar(128),
      compare_token varchar(256),
      source_fingerprint varchar(256),
      target_fingerprint varchar(256),
      dependency_closure_keys text[] NOT NULL DEFAULT '{}',
      applied_flag_keys text[] NOT NULL DEFAULT '{}',
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS environment_versions_environment_key_version_index ON environment_versions (environment_key, version)"
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

    Rulestead.Repo.query!(
      "ALTER TABLE change_requests DROP CONSTRAINT IF EXISTS change_requests_governed_action_must_be_valid"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE change_requests ADD CONSTRAINT change_requests_governed_action_must_be_valid CHECK (governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'manage_settings', 'promote_environment'))"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE scheduled_executions DROP CONSTRAINT IF EXISTS scheduled_executions_governed_action_must_be_valid"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE scheduled_executions ADD CONSTRAINT scheduled_executions_governed_action_must_be_valid CHECK (governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'release_kill_switch', 'promote_environment'))"
    )
  end
end
