defmodule Rulestead.Analytics.TelemetryHandlerTest do
  use ExUnit.Case, async: false

  alias Rulestead.Analytics.TelemetryHandler
  alias Rulestead.Analytics.Batcher

  setup do
    try do
      Supervisor.terminate_child(Rulestead.Application.Supervisor, Rulestead.Analytics.Batcher)
    catch
      :exit, _ -> :ok
    end

    try do
      :ets.delete(:rulestead_analytics_batcher)
    rescue
      ArgumentError -> :ok
    end

    start_supervised!({Batcher, flush_interval: 0, batch_size: 10, max_size: 100})
    :ok
  end

  describe "handle_event/4" do
    test "plucks targeting metadata and pushes to batcher" do
      metadata = %{
        flag_key: "hero_banner",
        environment: "production",
        has_targeting_key?: true,
        targeting_key: "user_123",
        variant: "treatment",
        experiment_bucket: 42,
        pii_data: "secret@example.com"
      }

      TelemetryHandler.handle_event(
        [:rulestead, :eval, :decide, :stop],
        %{system_time: 123},
        metadata,
        nil
      )

      # Check ETS for the inserted event
      events = :ets.tab2list(:rulestead_analytics_batcher)
      assert length(events) == 1

      [{_key, event}] = events
      assert event.kind == "exposure"
      assert event.event_name == "evaluation"
      assert event.env == "production"

      # Ensure specific metadata is included
      assert event.metadata["flag_key"] == "hero_banner"
      assert event.metadata["environment"] == "production"
      assert event.metadata["targeting_key"] == "user_123"
      assert event.metadata["variant"] == "treatment"
      assert event.metadata["experiment_bucket"] == 42

      # Ensure PII is not included
      refute Map.has_key?(event.metadata, "pii_data")
    end
  end

  describe "attach/0" do
    test "attaches telemetry handler" do
      # Attempt attachment
      TelemetryHandler.attach()
      
      # Verify it's attached
      handlers = :telemetry.list_handlers([:rulestead, :eval, :decide, :stop])
      assert Enum.any?(handlers, fn h -> h.id == "rulestead-analytics-handler" end)
      
      # Cleanup
      :telemetry.detach("rulestead-analytics-handler")
    end
  end
end