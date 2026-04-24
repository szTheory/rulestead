defmodule Rulestead.ScheduledExecutionAuditContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.{AuditEvent, Governance.ApprovalRequirement, Repo, Store.Command, StoreFixtures}
  alias Rulestead.Store.Ecto, as: StoreEcto

  @scheduled_events [
    [:rulestead, :admin, :scheduled_execution, :scheduled],
    [:rulestead, :admin, :scheduled_execution, :started],
    [:rulestead, :admin, :scheduled_execution, :succeeded],
    [:rulestead, :admin, :scheduled_execution, :failed],
    [:rulestead, :admin, :scheduled_execution, :quarantined],
    [:rulestead, :admin, :scheduled_execution, :cancelled],
    [:rulestead, :admin, :scheduled_execution, :requeued]
  ]

  setup do
    ensure_phase10_schema!()
    ensure_environment!("test")
    seed_publishable_flag!()
    attach_telemetry_handler!()

    on_exit(fn ->
      :telemetry.detach({__MODULE__, self()})
    end)

    :ok
  end

  test "successful scheduled execution emits correlated audit and telemetry with requested and actual timing" do
    submitter = %{id: "submitter-1", type: "operator", display: "Submitter"}
    reviewer = %{id: "reviewer-1", type: "operator", display: "Reviewer"}
    scheduler = %{id: "scheduler-1", type: "operator", display: "Scheduler"}
    scheduled_for = ~U[2026-04-25 12:30:00Z]

    assert {:ok, %{change_request: submitted}} =
             StoreEcto.submit_change_request(
               publish_change_request_command(submitter,
                 version: 2,
                 request_id: "corr-scheduled-success"
               )
             )

    assert {:ok, %{change_request: approved}} =
             StoreEcto.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: reviewer,
                 reason: "Approved",
                 metadata: %{request_id: "req-approve-success", source: :review_queue}
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             StoreEcto.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: scheduled_for,
                 actor: scheduler,
                 reason: "Ship in launch window",
                 metadata: %{
                   request_id: "req-schedule-success",
                   source: :admin_ui,
                   session_token: "secret-session-token",
                   socket_session: %{"raw" => "secret"}
                 }
               })
             )

    assert {:ok, %{scheduled_execution: completed}} =
             StoreEcto.execute_scheduled_execution(
               Command.ExecuteScheduledExecution.new(scheduled_execution.id,
                 actor: %{id: "system:scheduler", type: "system", display: "Scheduler"},
                 reason: "Due now",
                 metadata: %{
                   request_id: "req-execute-success",
                   source: :scheduled_execution_worker,
                   session_id: "secret-session-id"
                 }
               )
             )

    assert completed.state == :completed

    succeeded_event = receive_event!(:succeeded)
    scheduled_event = receive_event!(:scheduled)
    started_event = receive_event!(:started)

    assert scheduled_event.metadata.change_request_id == approved.id
    assert scheduled_event.metadata.correlation_id == approved.correlation_id
    assert scheduled_event.metadata.audit_action == :publish_ruleset
    assert scheduled_event.metadata.environment == "test"
    assert scheduled_event.metadata.attempt_count == 0

    assert started_event.metadata.change_request_id == approved.id
    assert started_event.metadata.correlation_id == approved.correlation_id
    assert started_event.metadata.audit_action == :publish_ruleset
    assert started_event.metadata.environment == "test"
    assert started_event.metadata.attempt_count == 1

    assert succeeded_event.metadata.change_request_id == approved.id
    assert succeeded_event.metadata.correlation_id == approved.correlation_id
    assert succeeded_event.metadata.audit_action == :publish_ruleset
    assert succeeded_event.metadata.environment == "test"
    assert succeeded_event.metadata.attempt_count == 1
    assert is_binary(succeeded_event.metadata.audit_event_id)

    scheduled_audit =
      Repo.all(from event in AuditEvent, order_by: [asc: event.inserted_at, asc: event.event_type], select: event)
      |> Enum.find(fn event ->
        event.event_type == "scheduled_execution.succeeded" and
          event.metadata["scheduled_execution_id"] == scheduled_execution.id
      end)

    assert scheduled_audit
    assert scheduled_audit.correlation_id == approved.correlation_id
    assert scheduled_audit.metadata["scheduled_execution_id"] == scheduled_execution.id
    assert scheduled_audit.metadata["attempt_count"] == 1
    assert scheduled_audit.metadata["scheduled_for"] == DateTime.to_iso8601(scheduled_for)
    assert scheduled_audit.metadata["executed_at"] == DateTime.to_iso8601(completed.executed_at)
    assert scheduled_audit.metadata["execution_mode"] == "change_request"
    assert scheduled_audit.metadata["failure_reason"] == nil
    assert scheduled_audit.metadata["executed_by"] == "scheduler"
    assert scheduled_audit.metadata["scheduled_by"]["id"] == "scheduler-1"
    assert scheduled_audit.metadata["approved_by"] == [%{"id" => "reviewer-1", "type" => "operator", "display" => "Reviewer"}]
    refute Map.has_key?(scheduled_audit.metadata["context"], "session_id")
    refute Map.has_key?(scheduled_audit.metadata["context"], "session_token")
    refute Map.has_key?(scheduled_audit.metadata["context"], "socket_session")
  end

  test "failed and quarantined scheduled execution records redacted failure metadata and honest runtime actor wording" do
    submitter = %{id: "submitter-2", type: "operator", display: "Submitter"}
    reviewer = %{id: "reviewer-2", type: "operator", display: "Reviewer"}
    scheduler = %{id: "scheduler-2", type: "operator", display: "Scheduler"}

    assert {:ok, %{change_request: submitted}} =
             StoreEcto.submit_change_request(
               publish_change_request_command(submitter,
                 version: 99,
                 request_id: "corr-scheduled-failure"
               )
             )

    assert {:ok, %{change_request: approved}} =
             StoreEcto.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: reviewer,
                 reason: "Approved",
                 metadata: %{request_id: "req-approve-failure", source: :review_queue}
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             StoreEcto.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: ~U[2026-04-25 14:00:00Z],
                 actor: scheduler,
                 reason: "Attempt publish",
                 metadata: %{
                   request_id: "req-schedule-failure",
                   source: :admin_ui,
                   session_data: %{"cookie" => "secret"}
                 }
               })
             )

    for attempt <- 1..3 do
      assert {:error, %Rulestead.Error{message: "ruleset_not_publishable"}} =
               StoreEcto.execute_scheduled_execution(
                 Command.ExecuteScheduledExecution.new(scheduled_execution.id,
                   actor: %{id: "system:scheduler", type: "system", display: "Scheduler"},
                   reason: "Attempt #{attempt}",
                   metadata: %{
                     request_id: "req-execute-failure-#{attempt}",
                     source: :scheduled_execution_worker,
                     session_token: "secret-token-#{attempt}"
                   }
                 )
               )
    end

    assert {:ok, %{scheduled_execution: quarantined}} =
             StoreEcto.fetch_scheduled_execution(Command.FetchScheduledExecution.new(scheduled_execution.id))

    assert quarantined.state == :quarantined
    assert quarantined.failure_reason == "ruleset_not_publishable"

    assert receive_event!(:failed).metadata.attempt_count == 1
    assert receive_event!(:failed).metadata.attempt_count == 2

    quarantined_event = receive_event!(:quarantined)
    assert quarantined_event.metadata.change_request_id == approved.id
    assert quarantined_event.metadata.correlation_id == approved.correlation_id
    assert quarantined_event.metadata.audit_action == :publish_ruleset
    assert quarantined_event.metadata.environment == "test"
    assert quarantined_event.metadata.attempt_count == 3
    assert is_binary(quarantined_event.metadata.audit_event_id)

    quarantined_audit =
      Repo.all(from event in AuditEvent, order_by: [asc: event.inserted_at, asc: event.event_type], select: event)
      |> Enum.find(fn event ->
        event.event_type == "scheduled_execution.quarantined" and
          event.metadata["scheduled_execution_id"] == scheduled_execution.id
      end)

    assert quarantined_audit
    assert quarantined_audit.correlation_id == approved.correlation_id
    assert quarantined_audit.metadata["attempt_count"] == 3
    assert quarantined_audit.metadata["failure_reason"] == "ruleset_not_publishable"
    assert quarantined_audit.metadata["execution_mode"] == "change_request"
    assert quarantined_audit.metadata["executed_by"] == "scheduler"
    assert quarantined_audit.metadata["scheduled_by"]["id"] == "scheduler-2"
    assert quarantined_audit.metadata["approved_by"] == [%{"id" => "reviewer-2", "type" => "operator", "display" => "Reviewer"}]
    refute Map.has_key?(quarantined_audit.metadata["context"], "session_data")
    refute Map.has_key?(quarantined_audit.metadata["context"], "session_token")
  end

  defp publish_change_request_command(actor, opts) do
    Command.SubmitChangeRequest.new(
      %{
        action: :publish_ruleset,
        environment_key: "test",
        resource_type: "flag",
        resource_key: "checkout-redesign",
        command: %{"version" => Keyword.fetch!(opts, :version)},
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
      reason: "Schedule governed publish",
      metadata: %{request_id: Keyword.fetch!(opts, :request_id), source: :review_queue}
    )
  end

  defp attach_telemetry_handler! do
    :ok =
      :telemetry.attach_many(
        {__MODULE__, self()},
        @scheduled_events,
        fn event, measurements, metadata, pid ->
          send(pid, {:telemetry_event, event, measurements, metadata})
        end,
        self()
      )
  end

  defp receive_event!(name) do
    event = [:rulestead, :admin, :scheduled_execution, name]

    receive do
      {:telemetry_event, ^event, measurements, metadata} -> %{measurements: measurements, metadata: metadata}
    after
      1_000 -> flunk("expected telemetry event #{inspect(event)}")
    end
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
