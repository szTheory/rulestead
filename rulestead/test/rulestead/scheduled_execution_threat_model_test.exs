unless Code.ensure_loaded?(Oban.Job) do
  defmodule Oban.Job do
    defstruct id: nil, args: %{}, meta: %{}, worker: nil, scheduled_at: nil
  end
end

defmodule Rulestead.ScheduledExecutionThreatModelTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.{AuditEvent, Context, Governance.ApprovalRequirement, Oban, Repo, Store.Command, StoreFixtures}
  alias Rulestead.Store.Ecto, as: StoreEcto

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, StoreEcto)
    ensure_phase10_schema!()
    ensure_environment!("test")
    seed_publishable_flag!()

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "duplicate worker delivery does not duplicate a completed scheduled mutation" do
    scheduled_execution = schedule_change_request!(2, "corr-replay-safe")
    job = scheduled_execution_job(scheduled_execution.id, scheduled_execution.correlation_id)

    assert {:ok, %{scheduled_execution: first}} =
             Rulestead.Oban.ScheduledExecutionWorker.perform(job)

    assert first.state == :completed

    assert {:ok, %{scheduled_execution: replayed}} =
             Rulestead.Oban.ScheduledExecutionWorker.perform(job)

    assert replayed.state == :completed

    assert {:ok, %{scheduled_execution: fetched, attempts: attempts}} =
             StoreEcto.fetch_scheduled_execution(Command.FetchScheduledExecution.new(scheduled_execution.id))

    assert fetched.state == :completed
    assert fetched.attempt_count == 1
    assert Enum.map(attempts, & &1.state) == [:completed]

    correlated_events =
      Repo.all(from event in AuditEvent, where: event.correlation_id == "corr-replay-safe", select: event)

    assert Enum.count(correlated_events, &(&1.event_type == "ruleset.publish")) == 1
    assert Enum.count(correlated_events, &(&1.event_type == "scheduled_execution.succeeded")) == 1
  end

  test "bounded retry exhaustion quarantines work and preserves correlated failure audit metadata" do
    scheduled_execution = schedule_change_request!(99, "corr-quarantine-audit")
    job = scheduled_execution_job(scheduled_execution.id, scheduled_execution.correlation_id)

    for _attempt <- 1..3 do
      assert {:error, %Rulestead.Error{message: "ruleset_not_publishable"}} =
               Rulestead.Oban.ScheduledExecutionWorker.perform(job)
    end

    assert {:ok, %{scheduled_execution: fetched, attempts: attempts}} =
             StoreEcto.fetch_scheduled_execution(Command.FetchScheduledExecution.new(scheduled_execution.id))

    assert fetched.state == :quarantined
    assert fetched.attempt_count == 3
    assert fetched.failure_reason == "ruleset_not_publishable"
    assert List.last(attempts).state == :quarantined

    correlated_events =
      Repo.all(from event in AuditEvent, where: event.correlation_id == "corr-quarantine-audit", select: event)

    failed_events = Enum.filter(correlated_events, &(&1.event_type == "scheduled_execution.failed"))
    [quarantined_event] = Enum.filter(correlated_events, &(&1.event_type == "scheduled_execution.quarantined"))

    assert length(failed_events) == 2
    assert quarantined_event.metadata["scheduled_execution_id"] == scheduled_execution.id
    assert quarantined_event.metadata["failure_reason"] == "ruleset_not_publishable"
    assert quarantined_event.metadata["attempt_count"] == 3
    assert quarantined_event.correlation_id == "corr-quarantine-audit"
  end

  test "phase 10 verifier script stays readable and scoped to core scheduling behavior" do
    verifier_path = Path.expand("../scripts/ci/verify_phase10_scheduling.sh", File.cwd!())

    assert File.exists?(verifier_path)

    verifier = File.read!(verifier_path)

    assert verifier =~ "[verify_phase10_scheduling]"
    assert verifier =~ "scheduled_execution_threat_model_test"
    refute verifier =~ "Phase 11"
    refute verifier =~ "webhook"
  end

  defp schedule_change_request!(version, correlation_id) do
    submitter = %{id: "submitter-#{version}", type: "operator", display: "Submitter"}
    reviewer = %{id: "reviewer-#{version}", type: "operator", display: "Reviewer"}
    scheduler = %{id: "scheduler-#{version}", type: "operator", display: "Scheduler"}

    assert {:ok, %{change_request: submitted}} =
             StoreEcto.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: :publish_ruleset,
                   environment_key: "test",
                   resource_type: "flag",
                   resource_key: "checkout-redesign",
                   command: %{"version" => version},
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
                 reason: "Threat model schedule",
                 metadata: %{request_id: correlation_id, source: :review_queue}
               )
             )

    assert {:ok, %{change_request: approved}} =
             StoreEcto.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: reviewer,
                 reason: "Approved",
                 metadata: %{request_id: "req-approve-#{version}", source: :review_queue}
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             StoreEcto.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: ~U[2026-04-25 15:00:00Z],
                 actor: scheduler,
                 reason: "Run scheduled change",
                 metadata: %{request_id: "req-schedule-#{version}", source: :admin_ui}
               })
             )

    scheduled_execution
  end

  defp scheduled_execution_job(scheduled_execution_id, correlation_id) do
    %Elixir.Oban.Job{
      id: System.unique_integer([:positive]),
      worker: "Elixir.Rulestead.Oban.ScheduledExecutionWorker",
      args: %{
        "scheduled_execution_id" => scheduled_execution_id,
        "correlation_id" => correlation_id,
        "governed_action" => "publish_ruleset",
        "environment_key" => "test"
      }
    }
    |> Oban.put_context(
      Context.new(
        actor: %{id: "system:scheduler", type: "system", display: "Scheduler"},
        environment: "test",
        request_id: correlation_id,
        attributes: %{"source" => "scheduled_execution_worker"}
      )
    )
  end

  defp seed_publishable_flag! do
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
             StoreEcto.publish_ruleset(StoreFixtures.publish_ruleset_command("checkout-redesign", "test"))

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
    case Repo.get_by(Rulestead.Environment, key: key) do
      nil ->
        attrs = StoreFixtures.valid_environment_attrs(%{key: key, name: String.upcase(key)})
        changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)
        assert {:ok, _env} = Repo.insert(changeset)

      _env ->
        :ok
    end
  end

  defp ensure_phase10_schema! do
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

    Repo.query!("CREATE TABLE IF NOT EXISTS scheduled_executions (
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

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_correlation_id_index ON scheduled_executions (correlation_id)"
    )

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_idempotency_key_index ON scheduled_executions (idempotency_key)"
    )

    Repo.query!("CREATE TABLE IF NOT EXISTS execution_attempts (
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

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS execution_attempts_scheduled_execution_attempt_number_index ON execution_attempts (scheduled_execution_id, attempt_number)"
    )

    Repo.query!("CREATE TABLE IF NOT EXISTS oban_jobs (
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
