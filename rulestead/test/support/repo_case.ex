defmodule Rulestead.RepoCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Rulestead.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Rulestead.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rulestead.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, {:shared, self()})
    end

    :ok
  end
end
