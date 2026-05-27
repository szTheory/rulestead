defmodule RulesteadAdmin.Test.DenyPreviewEvidenceResolver do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  @impl true
  def resolve(_query), do: {:ok, %{policy_denied: true}}
end
