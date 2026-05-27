defmodule Rulestead.Fake.PreviewEvidenceResolver do
  @moduledoc """
  Test-only preview evidence resolver for Fake/Ecto contract tests.

  Host applications supply a real `Rulestead.Targeting.PreviewEvidence`
  implementation via `:preview_evidence_resolver` Application config.
  """

  @behaviour Rulestead.Targeting.PreviewEvidence

  @impl true
  def resolve(%{audience_key: key}) do
    {:ok,
     %{
       samples: [
         %{"actor_key" => "fake-#{key}", "targeting_key" => "t-1", "matched?" => true}
       ],
       impression_summary: %{
         "window_label" => "last_24h",
         "sampled_impressions" => 100,
         "matched_impressions" => 12
       }
     }}
  end
end
