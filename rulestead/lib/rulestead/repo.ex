defmodule Rulestead.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :rulestead,
    adapter: Ecto.Adapters.Postgres

  @impl Ecto.Repo
  def default_options(operation) do
    case operation do
      :transaction -> []
      :rollback -> []
      _operation -> Rulestead.RepoPrefix.repo_opts()
    end
  end
end
