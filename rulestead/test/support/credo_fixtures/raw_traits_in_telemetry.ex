defmodule Rulestead.CredoFixtures.RawTraitsInTelemetry do
  def emit do
    :telemetry.execute([:rulestead, :evaluate], %{count: 1}, %{email: "person@example.com", ip: "127.0.0.1"})
  end
end
