defmodule Rulestead.Guardrails.ContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.Guardrails
  alias Rulestead.Guardrails.{Query, SignalFact}

  defmodule StubProvider do
    @behaviour Rulestead.Guardrails.Provider

    @impl true
    def fetch_signal(%Query{signal_key: "unsupported-scope"}) do
      {:error, :unsupported_scope}
    end

    def fetch_signal(%Query{signal_key: "stale-signal"}) do
      {:ok,
       %{
         observed_value: 0.01,
         sample_size: 150,
         captured_at: DateTime.add(DateTime.utc_now(), -900, :second)
       }}
    end

    def fetch_signal(%Query{signal_key: "thin-signal"}) do
      {:ok,
       %{
         observed_value: 0.01,
         sample_size: 5,
         captured_at: DateTime.utc_now()
       }}
    end

    def fetch_signal(%Query{signal_key: "healthy-signal"}) do
      {:ok,
       %{
         observed_value: 0.01,
         sample_size: 150,
         captured_at: DateTime.utc_now()
       }}
    end

    def fetch_signal(%Query{signal_key: "breached-signal"}) do
      {:ok,
       %{
         observed_value: 0.12,
         sample_size: 150,
         captured_at: DateTime.utc_now()
       }}
    end

    def fetch_signal(_query), do: {:error, :unsupported_signal}
  end

  test "provider_missing fails closed when no host provider is configured" do
    fact =
      Guardrails.fetch_signal(%{
        signal_key: "checkout_error_rate",
        environment_key: "production",
        tenant_key: "tenant-a",
        threshold_operator: :gte,
        threshold_value: 0.05,
        freshness_window_seconds: 300,
        min_sample_size: 100
      })

    assert %SignalFact{
             status: :failed_closed,
             reason: :provider_missing,
             environment_key: "production",
             tenant_key: "tenant-a"
           } = fact
  end

  test "query construction preserves explicit environment tenant freshness and sample semantics" do
    query =
      Query.from_context(
        "checkout_error_rate",
        %{environment: "production", tenant_key: "tenant-a"},
        threshold_operator: :gte,
        threshold_value: 0.05,
        freshness_window_seconds: 300,
        min_sample_size: 100
      )

    assert query.environment_key == "production"
    assert query.tenant_key == "tenant-a"
    assert query.environment_scope == :environment
    assert query.tenant_scope == :required
    assert query.freshness_window_seconds == 300
    assert query.min_sample_size == 100
  end

  test "unsupported_scope stale insufficient_sample healthy and breached normalize into bounded facts" do
    unsupported_scope =
      Guardrails.fetch_signal(
        %{
          signal_key: "unsupported-scope",
          environment_key: "production",
          tenant_key: "tenant-a",
          threshold_operator: :gte,
          threshold_value: 0.05,
          freshness_window_seconds: 300,
          min_sample_size: 100
        },
        provider: StubProvider
      )

    stale =
      Guardrails.fetch_signal(
        %{
          signal_key: "stale-signal",
          environment_key: "production",
          tenant_key: "tenant-a",
          threshold_operator: :gte,
          threshold_value: 0.05,
          freshness_window_seconds: 300,
          min_sample_size: 100
        },
        provider: StubProvider
      )

    insufficient_sample =
      Guardrails.fetch_signal(
        %{
          signal_key: "thin-signal",
          environment_key: "production",
          tenant_key: "tenant-a",
          threshold_operator: :gte,
          threshold_value: 0.05,
          freshness_window_seconds: 300,
          min_sample_size: 100
        },
        provider: StubProvider
      )

    healthy =
      Guardrails.fetch_signal(
        %{
          signal_key: "healthy-signal",
          environment_key: "production",
          tenant_key: "tenant-a",
          threshold_operator: :gte,
          threshold_value: 0.05,
          freshness_window_seconds: 300,
          min_sample_size: 100
        },
        provider: StubProvider
      )

    breached =
      Guardrails.fetch_signal(
        %{
          signal_key: "breached-signal",
          environment_key: "production",
          tenant_key: "tenant-a",
          threshold_operator: :gte,
          threshold_value: 0.05,
          freshness_window_seconds: 300,
          min_sample_size: 100
        },
        provider: StubProvider
      )

    assert {unsupported_scope.status, unsupported_scope.reason} ==
             {:failed_closed, :unsupported_scope}

    assert {stale.status, stale.reason} == {:failed_closed, :stale}

    assert {insufficient_sample.status, insufficient_sample.reason} ==
             {:failed_closed, :insufficient_sample}

    assert {healthy.status, healthy.reason} == {:healthy, :healthy}
    assert {breached.status, breached.reason} == {:breached, :breached}
  end
end
