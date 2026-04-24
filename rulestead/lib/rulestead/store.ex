defmodule Rulestead.Store do
  @moduledoc """
  Key-first authoring store behavior for the Rulestead public API.

  The contract is semantic and domain-oriented rather than CRUD-oriented.
  Implementations must normalize misses into `{:error, %Rulestead.Error{}}`
  and may not return `nil` for not-found cases.
  """

  alias Rulestead.Error
  alias Rulestead.Store.Command

  @type result(value) :: {:ok, value} | {:error, Error.t()}

  @callback fetch_flag(Command.FetchFlag.t()) :: result(map())
  @callback fetch_snapshot(Command.FetchSnapshot.t()) :: result(map())
  @callback create_flag(Command.CreateFlag.t()) :: result(map())
  @callback update_flag(Command.UpdateFlag.t()) :: result(map())
  @callback save_draft_ruleset(Command.SaveDraftRuleset.t()) :: result(map())
  @callback publish_ruleset(Command.PublishRuleset.t()) :: result(map())
  @callback archive_flag(Command.ArchiveFlag.t()) :: result(map())
  @callback list_flags(Command.ListFlags.t()) :: result(Command.Page.t(map()))
  @callback list_environments(Command.ListEnvironments.t()) :: result([map()])
  @callback record_evaluation(Command.RecordEvaluation.t()) :: result(map())
end
