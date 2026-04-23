defmodule Rulestead.Install do
  @moduledoc false

  alias Rulestead.Install.{ConfigWriter, MigrationWriter, RepoLocator}

  @spec run(keyword()) :: {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
  def run(opts \\ []) do
    with {:ok, repo} <- RepoLocator.resolve(opts),
         {:ok, migration_messages} <- MigrationWriter.copy_migrations(repo, opts),
         {:ok, config_messages} <- ConfigWriter.write(repo, opts) do
      {:ok, migration_messages ++ config_messages}
    end
  end
end
