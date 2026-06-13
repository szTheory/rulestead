# credo:disable-for-this-file
defmodule Rulestead.RolloutAutoAdvanceOrchestrationContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.{AuditEvent, Repo}
  alias Rulestead.Governance.RolloutAutoAdvance.Schedule
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    ensure_environment!("test")
    ensure_phase10_schema!()
    ensure_phase50_schema!()
    ensure_auto_advance_schema!()

    previous_provider = Application.get_env(:rulestead, :guardrails_provider)
    previous_policy = Application.get_env(:rulestead, :admin_policy)

    Application.put_env(:rulestead, :guardrails_provider, OrchestrationStubProvider)
    Application.delete_env(:rulestead, :admin_policy)
    OrchestrationStubProvider.reset!()

    on_exit(fn ->
      OrchestrationStubProvider.reset!()

      if previous_provider do
        Application.put_env(:rulestead, :guardrails_provider, previous_provider)
      else
        Application.delete_env(:rulestead, :guardrails_provider)
      end

      if previous_policy do
        Application.put_env(:rulestead, :admin_policy, previous_policy)
      else
        Application.delete_env(:rulestead, :admin_policy)
      end
    end)

    :ok
  end

  defp ensure_phase10_schema! do
    Rulestead.Repo.query!(
      "ALTER TABLE rulestead.flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false"
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

    Rulestead.Repo.query!(
      "ALTER TABLE rulestead.scheduled_executions ADD COLUMN IF NOT EXISTS last_oban_job_id bigint"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE rulestead.scheduled_executions ADD COLUMN IF NOT EXISTS executed_at timestamp(6) with time zone"
    )
  end

  defp ensure_phase50_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.guardrail_decisions (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      flag_key text NOT NULL,
      environment_key text NOT NULL,
      rule_key text NOT NULL,
      stage text NOT NULL,
      tenant_key text,
      decision_state text NOT NULL,
      action_type text NOT NULL,
      decision_reason text,
      effective_percentage integer,
      rollout_salt text,
      variant_fingerprint text,
      monitoring_window_started_at timestamp(6) with time zone,
      monitoring_window_ends_at timestamp(6) with time zone,
      occurred_at timestamp(6) with time zone NOT NULL,
      signal_facts jsonb[] NOT NULL DEFAULT '{}',
      guardrail_evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
      authored_snapshot jsonb,
      rollback_target_snapshot jsonb,
      correlation_id text,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone
    )")
  end

  defp ensure_auto_advance_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.rollout_auto_advance_policies (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      flag_key text NOT NULL,
      environment_key text NOT NULL,
      rule_key text NOT NULL,
      enabled boolean NOT NULL DEFAULT false,
      observation_window_seconds integer,
      next_stage text,
      next_percentage integer,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS rollout_auto_advance_policies_flag_key_environment_key_rule_key_index ON rulestead.rollout_auto_advance_policies (flag_key, environment_key, rule_key)"
    )
  end

  defp reset_adapter!(Rulestead.Fake), do: Rulestead.Fake.Control.reset!()

  defp reset_adapter!(StoreEcto) do
    for table <- ~w(
         rulestead.execution_attempts rulestead.approvals rulestead.change_requests
         rulestead.scheduled_executions rulestead.rollout_auto_advance_policies
         rulestead.audit_events rulestead.rulesets rulestead.flag_environments rulestead.flags
       ) do
      Repo.query!("DELETE FROM #{table}")
    end
  end

  defp adapter_suffix(Rulestead.Fake), do: "fake"
  defp adapter_suffix(StoreEcto), do: "ecto"

  defp ensure_environment!(key) do
    case Repo.get_by(Rulestead.Environment, key: key) do
      nil ->
        attrs = StoreFixtures.valid_environment_attrs(%{key: key, name: String.upcase(key)})

        assert {:ok, _env} =
                 %Rulestead.Environment{}
                 |> Rulestead.Environment.changeset(attrs)
                 |> Repo.insert()

      _env ->
        :ok
    end
  end

  test "advance_rollout schedules auto_advance tick at monitoring_window_ends_at" do
    window_ends = ~U[2026-06-01 12:05:00Z]

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "orc-schedule-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(adapter, flag_key)

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: ~U[2026-06-01 12:00:00Z],
                 monitoring_window_ends_at: window_ends
               })

      [tick] = StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key)

      assert tick.action in ["advance_rollout", :advance_rollout]
      assert DateTime.compare(normalize_datetime(tick.scheduled_for), window_ends) == :eq
      assert auto_advance_source?(tick.metadata)
    end)
  end

  test "disabled policy does not schedule tick" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "orc-disabled-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(
        adapter,
        flag_key,
        policy: StoreFixtures.default_auto_advance_policy_attrs(enabled: false)
      )

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: ~U[2026-06-01 12:00:00Z],
                 monitoring_window_ends_at: ~U[2026-06-01 12:05:00Z]
               })

      assert StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key) == []
    end)
  end

  test "healthy tick executes governed advance with guardrail_automation audit" do
    {window_start, window_ends} = past_monitoring_window_bounds()

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      OrchestrationStubProvider.set_mode!(:healthy)
      flag_key = "orc-healthy-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(adapter, flag_key)

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: window_start,
                 monitoring_window_ends_at: window_ends
               })

      assert {:ok, %{scheduled_execution: completed}} =
               StoreFixtures.execute_auto_advance_tick!(adapter, flag_key: flag_key)

      assert completed.state in [:completed, "completed"]
      assert rollout_percentage(adapter, flag_key, "test") == 100

      automation_advances =
        list_rollout_advance_audits(adapter, flag_key, "test")
        |> Enum.filter(&automation_audit?/1)

      assert length(automation_advances) == 1
      assert automation_audit?(hd(automation_advances))
    end)
  end

  test "blocked tick completes without stage mutation" do
    {window_start, window_ends} = past_monitoring_window_bounds()

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      OrchestrationStubProvider.set_mode!(:blocked)
      flag_key = "orc-blocked-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(adapter, flag_key)

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: window_start,
                 monitoring_window_ends_at: window_ends
               })

      percentage_before = rollout_percentage(adapter, flag_key, "test")

      result = StoreFixtures.execute_auto_advance_tick!(adapter, flag_key: flag_key)

      assert {:ok, %{scheduled_execution: completed}} = result,
             "execute failed: #{inspect(result)}"

      assert completed.state in [:completed, "completed"]
      assert rollout_percentage(adapter, flag_key, "test") == percentage_before

      execution_metadata = normalize_map(completed.execution_metadata)
      assert execution_metadata["outcome"] == "blocked"
      assert is_list(execution_metadata["reasons"])
      assert execution_metadata["reasons"] != []
    end)
  end

  test "protected environment submits change request does not auto-advance" do
    {window_start, window_ends} = past_monitoring_window_bounds()

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      ensure_environment!("production")
      OrchestrationStubProvider.set_mode!(:healthy)
      flag_key = "orc-protected-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(
        adapter,
        flag_key,
        environment_key: "production"
      )

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "production", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: window_start,
                 monitoring_window_ends_at: window_ends
               })

      percentage_before = rollout_percentage(adapter, flag_key, "production")

      assert {:ok, %{scheduled_execution: completed}} =
               StoreFixtures.execute_auto_advance_tick!(adapter,
                 flag_key: flag_key,
                 environment_key: "production"
               )

      assert completed.state in [:completed, "completed"]
      assert rollout_percentage(adapter, flag_key, "production") == percentage_before

      execution_metadata = normalize_map(completed.execution_metadata)
      assert execution_metadata["outcome"] == "change_request_submitted"
      assert is_binary(execution_metadata["change_request_id"])

      assert length(list_submitted_change_requests(adapter, flag_key, "production")) == 1
    end)
  end

  test "duplicate execute is replay safe" do
    {window_start, window_ends} = past_monitoring_window_bounds()

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      OrchestrationStubProvider.set_mode!(:healthy)
      flag_key = "orc-replay-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(adapter, flag_key)

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: window_start,
                 monitoring_window_ends_at: window_ends
               })

      [tick] = StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key)

      assert {:ok, %{scheduled_execution: completed}} =
               execute_tick!(adapter, tick.id)

      assert completed.state in [:completed, "completed"]

      assert {:ok, %{scheduled_execution: replayed}} = execute_tick!(adapter, tick.id)
      assert replayed.state in [:completed, "completed"]
      assert replayed.id == tick.id

      automation_advances =
        list_rollout_advance_audits(adapter, flag_key, "test")
        |> Enum.filter(&automation_audit?/1)

      assert length(automation_advances) == 1
      assert rollout_percentage(adapter, flag_key, "test") == 100
    end)
  end

  test "manual advance before tick fails closed with bounded reason" do
    window_ends =
      DateTime.utc_now()
      |> DateTime.add(300, :second)
      |> DateTime.truncate(:second)

    window_start = DateTime.add(window_ends, -300, :second)

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      OrchestrationStubProvider.set_mode!(:healthy)
      flag_key = "orc-race-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(adapter, flag_key)

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: window_start,
                 monitoring_window_ends_at: window_ends
               })

      [tick] = StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key)

      assert {:ok, _} =
               advance_rollout!(adapter, flag_key, "test", %{
                 stage: "canary-75",
                 percentage: 75,
                 monitoring_window_started_at: window_start,
                 monitoring_window_ends_at: window_ends
               })

      assert {:error, %Rulestead.Error{message: reason}} = execute_tick!(adapter, tick.id)

      assert reason =~ "auto_advance_superseded" or reason =~ "rollout_stage_conflict" or
               reason =~ "cancelled"
    end)
  end

  test "deterministic idempotency_key prevents duplicate ticks" do
    window_ends = ~U[2026-06-01 12:05:00Z]

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "orc-idempotent-#{adapter_suffix(adapter)}"

      StoreFixtures.seed_rollout_with_auto_advance_policy!(adapter, flag_key)

      rollout_attrs = %{
        stage: "canary-50",
        percentage: 50,
        monitoring_window_started_at: ~U[2026-06-01 12:00:00Z],
        monitoring_window_ends_at: window_ends
      }

      assert {:ok, _} = advance_rollout!(adapter, flag_key, "test", rollout_attrs)
      [tick] = StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key)

      advance_command =
        Command.AdvanceRollout.new(
          flag_key,
          "test",
          Map.merge(%{rule_key: "variant-split"}, rollout_attrs)
        )

      {:ok, %{policy: policy}} =
        adapter.fetch_rollout_auto_advance_policy(
          Command.FetchRolloutAutoAdvancePolicy.new(flag_key, "test", "variant-split")
        )

      schedule_command = Schedule.schedule_command(advance_command, policy)

      assert {:ok, _} = adapter.schedule_governed_action(schedule_command)
      assert length(StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key)) == 1
      assert hd(StoreFixtures.list_auto_advance_ticks(adapter, flag_key: flag_key)).id == tick.id
    end)
  end

  defp past_monitoring_window_bounds do
    window_ends =
      DateTime.utc_now()
      |> DateTime.add(-120, :second)
      |> DateTime.truncate(:second)

    window_start = DateTime.add(window_ends, -300, :second)
    {window_start, window_ends}
  end

  defp execute_tick!(adapter, scheduled_execution_id) do
    adapter.execute_scheduled_execution(
      Command.ExecuteScheduledExecution.new(scheduled_execution_id,
        actor: %{id: "system:scheduler", type: "system", display: "Scheduler"},
        reason: "Execute auto-advance observation window tick",
        metadata: %{
          request_id: "req-auto-advance-#{System.unique_integer([:positive])}",
          source: :scheduled_execution_worker
        }
      )
    )
  end

  defp list_submitted_change_requests(adapter, flag_key, environment_key) do
    case adapter.list_change_requests(
           Command.ListChangeRequests.new(
             environment_key: environment_key,
             resource_key: flag_key,
             status: :submitted
           )
         ) do
      {:ok, %{change_requests: change_requests}} -> change_requests
      {:ok, %{entries: change_requests}} -> change_requests
      other -> raise "unexpected change request page: #{inspect(other)}"
    end
  end

  defp advance_rollout!(adapter, flag_key, environment_key, rollout_attrs) do
    adapter.advance_rollout(
      Command.AdvanceRollout.new(
        flag_key,
        environment_key,
        Map.merge(%{rule_key: "variant-split"}, rollout_attrs),
        metadata: %{
          request_id: "req-#{flag_key}-advance-#{System.unique_integer([:positive])}",
          source: :admin_ui
        }
      )
    )
  end

  defp rollout_percentage(adapter, flag_key, environment_key) do
    {:ok, payload} =
      adapter.fetch_flag(StoreFixtures.fetch_flag_command(flag_key, environment_key))

    rule = Enum.find(payload.active_ruleset.rules, &(&1.key == "variant-split"))
    rule.rollout.percentage
  end

  defp list_rollout_advance_audits(adapter, flag_key, environment_key) do
    events =
      case adapter do
        Rulestead.Fake ->
          case adapter.list_audit_events(
                 Command.ListAuditEvents.new(flag_key: flag_key, environment_key: environment_key)
               ) do
            {:ok, %{audit_events: audit_events}} -> audit_events
            {:ok, %{entries: audit_events}} -> audit_events
            other -> raise "unexpected audit page: #{inspect(other)}"
          end

        StoreEcto ->
          Repo.all(
            from(event in AuditEvent,
              where:
                event.resource_key == ^flag_key and event.environment_key == ^environment_key and
                  event.event_type == "rollout.advance",
              order_by: [asc: event.inserted_at]
            )
          )
      end

    Enum.filter(events, &(&1.event_type == "rollout.advance"))
  end

  defp automation_audit?(event) do
    metadata = normalize_map(Map.get(event, :metadata) || Map.get(event, "metadata") || %{})
    source = metadata["source"] || metadata[:source]
    source in ["guardrail_automation", :guardrail_automation]
  end

  defp auto_advance_source?(metadata) do
    metadata = normalize_map(metadata)
    source = metadata["source"] || metadata[:source]
    source in ["guardrail_automation", :guardrail_automation]
  end

  defp normalize_datetime(%DateTime{} = value), do: DateTime.truncate(value, :second)

  defp normalize_datetime(value) when is_binary(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    DateTime.truncate(datetime, :second)
  end

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), normalize_map(value)}
      {key, value} -> {key, normalize_map(value)}
    end)
  end

  defp normalize_map(value) when is_list(value), do: Enum.map(value, &normalize_map/1)
  defp normalize_map(value), do: value
end

defmodule OrchestrationStubProvider do
  @moduledoc false

  @behaviour Rulestead.Guardrails.Provider

  alias Rulestead.Guardrails.Query

  @env_key :orchestration_stub_provider_mode

  @spec reset!() :: :ok
  def reset!, do: Application.put_env(:rulestead, @env_key, :healthy)

  @spec set_mode!(atom()) :: :ok
  def set_mode!(mode) when mode in [:healthy, :blocked],
    do: Application.put_env(:rulestead, @env_key, mode)

  @impl true
  def fetch_signal(%Query{} = _query) do
    case Application.get_env(:rulestead, @env_key, :healthy) do
      :blocked ->
        {:ok,
         %{
           observed_value: 0.99,
           sample_size: 150,
           captured_at: DateTime.utc_now() |> DateTime.truncate(:second)
         }}

      :healthy ->
        {:ok,
         %{
           observed_value: 0.01,
           sample_size: 150,
           captured_at: DateTime.utc_now() |> DateTime.truncate(:second)
         }}
    end
  end
end
