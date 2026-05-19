defmodule Rulestead.Analytics.TelemetryHandler do
  @moduledoc false
  # Telemetry hook that captures evaluation events and pushes them to the Analytics Batcher.
  # Aligns with framework conventions from Rulestead.Telemetry.

  alias Rulestead.Analytics.Batcher

  @doc """
  Attaches the handler to evaluation stop events.
  """
  def attach do
    :telemetry.attach(
      "rulestead-analytics-handler",
      [:rulestead, :eval, :decide, :stop],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc false
  def handle_event([:rulestead, :eval, :decide, :stop], _measurements, metadata, _config) do
    # Pluck only specific targeting metadata to prevent PII leakage
    safe_metadata = %{
      "targeting_key" => Map.get(metadata, :targeting_key) || Map.get(metadata, :has_targeting_key?),
      "flag_key" => Map.get(metadata, :flag_key),
      "environment" => Map.get(metadata, :environment),
      "variant" => Map.get(metadata, :variant),
      "experiment_bucket" => Map.get(metadata, :experiment_bucket)
    }

    event = %{
      kind: "exposure",
      event_name: "evaluation",
      env: Map.get(metadata, :environment),
      metadata: safe_metadata
    }

    Batcher.insert(event)
  end
end