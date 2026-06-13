# credo:disable-for-this-file
defmodule Rulestead.ObanScheduledExecutionTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Context
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Oban, as: RulesteadOban
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  defmodule CapturingStore do
    @behaviour Rulestead.Store

    alias Rulestead.Store.Command

    def fetch_scheduled_execution(%Command.FetchScheduledExecution{} = command) do
      {:ok,
       %{
         scheduled_execution: %{
           id: command.scheduled_execution_id,
           action: :publish_ruleset,
           environment_key: "prod",
           attempt_count: 0,
           state: :scheduled
         }
       }}
    end

    def execute_scheduled_execution(%Command.ExecuteScheduledExecution{} = command) do
      send(self(), {:execute_scheduled_execution, command})

      {:ok,
       %{
         scheduled_execution: %{
           id: command.scheduled_execution_id,
           action: :publish_ruleset,
           environment_key: "prod",
           attempt_count: 1,
           state: :completed
         }
       }}
    end

    for callback <- [
          :compare_environments,
          :apply_promotion,
          :fetch_flag,
          :fetch_snapshot,
          :create_flag,
          :update_flag,
          :save_draft_ruleset,
          :publish_ruleset,
          :archive_flag,
          :list_flags,
          :list_environments,
          :list_audiences,
          :list_audience_dependencies,
          :preview_audience_impact,
          :apply_audience_mutation,
          :record_evaluation,
          :advance_rollout,
          :evaluate_guarded_rollout,
          :upsert_rollout_auto_advance_policy,
          :fetch_rollout_auto_advance_policy,
          :evaluate_rollout_auto_advance,
          :fetch_guardrail_status,
          :engage_kill_switch,
          :release_kill_switch,
          :list_audit_events,
          :rollback_audit_event,
          :submit_change_request,
          :approve_change_request,
          :reject_change_request,
          :cancel_change_request,
          :execute_change_request,
          :fetch_change_request,
          :list_change_requests,
          :schedule_change_request,
          :schedule_governed_action,
          :cancel_scheduled_execution,
          :requeue_scheduled_execution,
          :list_scheduled_executions,
          :preview_manifest_import,
          :apply_manifest_import,
          :receive_inbound_webhook,
          :fetch_webhook_record,
          :list_webhook_records,
          :create_webhook_destination,
          :update_webhook_destination,
          :fetch_webhook_destination,
          :list_webhook_destinations,
          :list_webhook_deliveries,
          :retry_webhook_delivery
        ] do
      def unquote(callback)(_), do: raise("unexpected callback #{unquote(callback)}/1")
    end
  end

  setup do
    ensure_phase10_schema!()
    previous_store = Application.get_env(:rulestead, :store)

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "scheduling a change request inserts one scheduled oban job with durable identity" do
    ensure_environment!("test")
    seed_governed_publish!()

    submitter = %{id: "submitter-oban", type: "operator", display: "Submitter"}
    reviewer = %{id: "reviewer-oban", type: "operator", display: "Reviewer"}
    scheduler = %{id: "scheduler-oban", type: "operator", display: "Scheduler"}
    scheduled_for = ~U[2026-04-25 12:30:00Z]

    assert {:ok, %{change_request: submitted}} =
             StoreEcto.submit_change_request(
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
                 reason: "Queue for launch window",
                 metadata: %{request_id: "corr-oban-schedule", source: :review_queue}
               )
             )

    assert {:ok, %{change_request: approved}} =
             StoreEcto.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: reviewer,
                 reason: "Approved",
                 metadata: %{request_id: "req-oban-approve"}
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             StoreEcto.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: scheduled_for,
                 actor: scheduler,
                 reason: "Deploy window",
                 metadata: %{request_id: "req-oban-schedule", source: :admin_ui}
               })
             )

    assert scheduled_execution.change_request_id == approved.id

    assert DateTime.truncate(scheduled_execution.scheduled_for, :second) ==
             DateTime.truncate(scheduled_for, :second)

    assert scheduled_execution.state == :scheduled

    [job] =
      Rulestead.Repo.query!(
        "SELECT worker, args, scheduled_at, state FROM rulestead.oban_jobs WHERE args->>'scheduled_execution_id' = $1",
        [scheduled_execution.id]
      ).rows

    [worker, args, queued_at, state] = job

    assert worker == "Elixir.Rulestead.Oban.ScheduledExecutionWorker"
    assert state == "scheduled"
    assert args["scheduled_execution_id"] == scheduled_execution.id
    assert args["correlation_id"] == scheduled_execution.correlation_id
    assert args["governed_action"] == "publish_ruleset"
    assert args["environment_key"] == "test"
    assert DateTime.truncate(queued_at, :second) == DateTime.truncate(scheduled_for, :second)
  end

  test "scheduled execution worker restores bounded context and delegates through the store contract" do
    Application.put_env(:rulestead, :store, CapturingStore)

    job =
      %Oban.Job{
        id: 42,
        worker: "Elixir.Rulestead.Oban.ScheduledExecutionWorker",
        args: %{
          "scheduled_execution_id" => "se-worker-123",
          "correlation_id" => "corr-worker-123",
          "governed_action" => "publish_ruleset",
          "environment_key" => "prod"
        }
      }
      |> RulesteadOban.put_context(
        Context.new(
          actor: %{id: "system:scheduler", type: "system", display: "Scheduler"},
          environment: "prod",
          request_id: "req-worker-123",
          attributes: %{"source" => "scheduled_execution_worker"}
        )
      )

    assert {:ok, %{scheduled_execution: %{id: "se-worker-123"}}} =
             Rulestead.Oban.ScheduledExecutionWorker.perform(job)

    assert_received {:execute_scheduled_execution, command}
    assert command.scheduled_execution_id == "se-worker-123"

    assert command.actor == %{
             "id" => "system:scheduler",
             "type" => "system",
             "display" => "Scheduler"
           }

    assert command.metadata["request_id"] == "corr-worker-123"
    assert command.metadata["environment_key"] == "prod"
    assert command.metadata["governed_action"] == "publish_ruleset"
    assert command.metadata["source"] == "scheduled_execution_worker"
  end

  defp seed_governed_publish! do
    assert {:ok, _} =
             StoreEcto.create_flag(
               Command.CreateFlag.new(StoreFixtures.valid_flag_attrs(%{permanent: true}))
             )

    assert {:ok, _} =
             StoreEcto.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "test",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             StoreEcto.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test")
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

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.scheduled_executions (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      state text NOT NULL DEFAULT 'scheduled',
      change_request_id uuid REFERENCES rulestead.change_requests(id) ON DELETE SET NULL,
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
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_correlation_id_index ON rulestead.scheduled_executions (correlation_id)"
    )

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_idempotency_key_index ON rulestead.scheduled_executions (idempotency_key)"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.execution_attempts (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      scheduled_execution_id uuid NOT NULL REFERENCES rulestead.scheduled_executions(id) ON DELETE CASCADE,
      attempt_number integer NOT NULL,
      state text NOT NULL,
      started_at timestamp(6) with time zone NOT NULL,
      finished_at timestamp(6) with time zone,
      failure_reason text,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS execution_attempts_scheduled_execution_attempt_number_index ON rulestead.execution_attempts (scheduled_execution_id, attempt_number)"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.oban_jobs (
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
