defmodule Rulestead.ScheduledExecutionConflictTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    ensure_phase10_schema!()
    :ok
  end

  test "stale or conflicting scheduled targets fail visibly with bounded failure reasons" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_flag_with_draft!(adapter, "checkout-archived")

      archived_publish =
        schedule_action!(adapter, "checkout-archived", :publish_ruleset, %{"version" => 2})

      archive_flag!(adapter, "checkout-archived")

      assert_conflict_reason(
        adapter,
        archived_publish.id,
        "archived_resource"
      )

      reset_adapter!(adapter)
      seed_flag_with_draft!(adapter, "checkout-not-publishable")

      not_publishable =
        schedule_action!(adapter, "checkout-not-publishable", :publish_ruleset, %{"version" => 99})

      assert_conflict_reason(
        adapter,
        not_publishable.id,
        "ruleset_not_publishable"
      )

      reset_adapter!(adapter)
      seed_flag_with_draft!(adapter, "checkout-rollout")

      missing_stage =
        schedule_action!(
          adapter,
          "checkout-rollout",
          :advance_rollout,
          %{"stage" => "missing-stage", "percentage" => 50}
        )

      assert_conflict_reason(
        adapter,
        missing_stage.id,
        "rollout_stage_conflict"
      )

      reset_adapter!(adapter)
      seed_flag_with_draft!(adapter, "checkout-kill-switch")

      engage = schedule_action!(adapter, "checkout-kill-switch", :engage_kill_switch, %{})
      assert {:ok, %{scheduled_execution: engaged}} = execute_scheduled!(adapter, engage.id)
      assert engaged.state == :completed

      already_engaged =
        schedule_action!(adapter, "checkout-kill-switch", :engage_kill_switch, %{})

      assert_conflict_reason(
        adapter,
        already_engaged.id,
        "kill_switch_already_engaged"
      )

      release = schedule_action!(adapter, "checkout-kill-switch", :release_kill_switch, %{})
      assert {:ok, %{scheduled_execution: released}} = execute_scheduled!(adapter, release.id)
      assert released.state == :completed

      already_released =
        schedule_action!(adapter, "checkout-kill-switch", :release_kill_switch, %{})

      assert_conflict_reason(
        adapter,
        already_released.id,
        "kill_switch_already_released"
      )
    end)
  end

  defp assert_conflict_reason(adapter, scheduled_execution_id, expected_reason) do
    assert {:error, %Rulestead.Error{}} = execute_scheduled!(adapter, scheduled_execution_id)

    assert {:ok, %{scheduled_execution: scheduled_execution, attempts: attempts}} =
             adapter.fetch_scheduled_execution(
               Command.FetchScheduledExecution.new(scheduled_execution_id)
             )

    assert scheduled_execution.state in [:failed, :quarantined, :scheduled]
    assert scheduled_execution.failure_reason == expected_reason
    assert List.last(attempts).failure_reason == expected_reason
  end

  defp schedule_action!(adapter, flag_key, action, command_payload) do
    request_id = "req-#{flag_key}-#{action}-#{System.unique_integer([:positive])}"

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             adapter.schedule_governed_action(
               Command.ScheduleGovernedAction.new(%{
                 action: action,
                 environment_key: "test",
                 resource_type: "flag",
                 resource_key: flag_key,
                 command: command_payload,
                 scheduled_for: ~U[2026-04-25 20:00:00Z],
                 execution_mode: :policy_bypass,
                 actor: %{id: "scheduler-1", type: "operator", display: "Scheduler"},
                 reason: "Run bounded scheduled action",
                 metadata: %{request_id: request_id, source: :admin_ui}
               })
             )

    scheduled_execution
  end

  defp execute_scheduled!(adapter, scheduled_execution_id) do
    adapter.execute_scheduled_execution(
      Command.ExecuteScheduledExecution.new(scheduled_execution_id,
        actor: %{id: "scheduler", type: "system", display: "Scheduler"},
        reason: "Execute due scheduled action",
        metadata: %{
          request_id: "req-execute-#{scheduled_execution_id}",
          source: :scheduled_execution_worker
        }
      )
    )
  end

  defp archive_flag!(adapter, flag_key) do
    assert {:ok, _} =
             adapter.archive_flag(
               Command.ArchiveFlag.new(flag_key,
                 actor: %{id: "archiver-1", type: "operator", display: "Archiver"},
                 reason: "Archived before schedule fired",
                 metadata: %{request_id: "req-archive", source: :admin_ui}
               )
             )
  end

  defp seed_flag_with_draft!(adapter, flag_key) do
    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(
                 StoreFixtures.valid_flag_attrs(%{key: flag_key, permanent: true}),
                 actor: %{id: "creator-1", type: "operator", display: "Creator"}
               )
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 flag_key,
                 "test",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )
  end

  defp reset_adapter!(Rulestead.Fake), do: Rulestead.Fake.Control.reset!()
  defp reset_adapter!(StoreEcto), do: :ok

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
