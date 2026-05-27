defmodule RulesteadAdmin.Test.ForbiddenPreviewCopy do
  @moduledoc false

  @forbidden_preview_phrases [
    "fleet dashboard",
    "population analytics",
    "observability platform",
    "fleet-wide rollout",
    "warehouse query"
  ]

  def forbidden_preview_phrases, do: @forbidden_preview_phrases

  def offending_phrases(html) do
    lowered = String.downcase(html)

    Enum.filter(@forbidden_preview_phrases, &(lowered =~ &1))
  end
end
