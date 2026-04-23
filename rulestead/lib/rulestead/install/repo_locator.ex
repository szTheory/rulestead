defmodule Rulestead.Install.RepoLocator do
  @moduledoc false

  alias Rulestead.ConfigError

  @spec resolve(keyword()) :: {:ok, module()} | {:error, Rulestead.Error.t()}
  def resolve(opts \\ []) do
    repo_override = Keyword.get(opts, :repo) || Keyword.get(opts, :"--repo")
    repos = configured_repos(opts)

    cond do
      is_binary(repo_override) ->
        repo_override |> String.split(".") |> Module.concat() |> validate_repo(repos)

      is_atom(repo_override) and not is_nil(repo_override) ->
        validate_repo(repo_override, repos)

      repos == [] ->
        {:error, ConfigError.repo_not_configured()}

      length(repos) == 1 ->
        {:ok, hd(repos)}

      true ->
        {:error, ConfigError.repo_ambiguous(metadata: %{repos: Enum.map(repos, &inspect/1)})}
    end
  end

  defp validate_repo(repo, repos) do
    if repo in repos do
      {:ok, repo}
    else
      {:error,
       ConfigError.repo_not_configured(
         metadata: %{requested_repo: inspect(repo), repos: Enum.map(repos, &inspect/1)}
       )}
    end
  end

  defp configured_repos(opts) do
    case Keyword.fetch(opts, :repos) do
      {:ok, repos} ->
        repos

      :error ->
        case Keyword.fetch(opts, :ecto_repos) do
          {:ok, repos} -> repos
          :error -> Application.get_env(Mix.Project.config()[:app], :ecto_repos, [])
        end
    end
  end
end
