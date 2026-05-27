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
    ensure_phase10_schema!()
    ensure_phase50_schema!()
    ensure_auto_advance_schema!()

    previous_provider = Application.get_env(:rulestead, :guardrails_provider)
    Application.put_env(:rulestead, :guardrails_provider, OrchestrationStubProvider)
    OrchestrationStubProvider.reset!()

    on_exit(fn ->
      OrchestrationStubProvider.reset!()

      if previous_provider do
        Application.put_env(:rulestead, :guardrails_provider, previous_provider)
      else
        Application.delete_env(:rulestead, :guardrails_provider)
      end
    end)

    :ok
  end

  defp ensure_phase10_schema! do
    Rulestead.Repo.query!(
      "ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS scheduled_executions (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      state text NOT NULL DEFAULT 'scheduled',
      change_request_id uuid,
      governed_action text NOT NULL,
      environment_key text,
      resource_type text,
      resource_key text,
      execution_mode text,
      scheduled_by_id text,
      scheduled_by_type text,
      scheduled_by_display text,
      approved_by_snapshot jsonb NOT NULL DEFAULT '[]'::jsonb,
      scheduled_for timestamp(6) with time zone NOT NULL,
      command_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      approval_requirement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      idempotency_key text NOT NULL,
      attempt_count integer NOT NULL DEFAULT 0,
      failure_reason text,
      execution_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS scheduled_executions_idempotency_key_index ON scheduled_executions (idempotency_key)"
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
  end

  defp ensure_phase50_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS guardrail_decisions (
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
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rollout_auto_advance_policies (
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
      "CREATE UNIQUE INDEX IF NOT EXISTS rollout_auto_advance_policies_flag_key_environment_key_rule_key_index ON rollout_auto_advance_policies (flag_key, environment_key, rule_key)"
    )
  end

  defp reset_adapter!(Rulestead.Fake), do: Rulestead.Fake.Control.reset!()
  defp reset_adapter!(StoreEcto), do: :ok

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
end

defmodule OrchestrationStubProvider do
  @moduledoc false

  alias Rulestead.Guardrails.Query

  @mode_key {__MODULE__, :mode}

  @spec reset!() :: :ok
  def reset!, do: Process.put(@mode_key, :healthy)

  @spec set_mode!(atom()) :: :ok
  def set_mode!(mode) when mode in [:healthy, :blocked], do: Process.put(@mode_key, mode)

  @spec fetch_signal(Query.t()) :: {:ok, map()} | {:error, atom()}
  def fetch_signal(%Query{} = _query) do
    case Process.get(@mode_key, :healthy) do
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
