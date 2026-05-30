defmodule RulesteadDemo.PreviewEvidenceResolver do
  @moduledoc false

  @behaviour Rulestead.Targeting.PreviewEvidence

  @impl true
  def resolve(%{audience_key: key}) do
    {:ok,
     %{
       samples: [
         %{
           "actor_key" => "fleetdesk-#{key}",
           "targeting_key" => "demo-user",
           "matched?" => true
         }
       ],
       impression_summary: %{
         "window_label" => "last_24h",
         "sampled_impressions" => 240,
         "matched_impressions" => 36
       }
     }}
  end
end
