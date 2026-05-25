# credo:disable-for-this-file
defmodule Rulestead.Install do
  @moduledoc false

  alias Rulestead.Install.{ConfigWriter, FileInjector, MigrationWriter, RepoLocator}

  @spec run(keyword()) :: {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
  def run(opts \\ []) do
    with {:ok, repo} <- RepoLocator.resolve(opts),
         {:ok, migration_messages} <- MigrationWriter.copy_migrations(repo, opts),
         {:ok, config_messages} <- ConfigWriter.write(repo, opts),
         {:ok, endpoint_messages} <- inject_endpoint(repo, opts),
         {:ok, router_messages} <- inject_router(repo, opts),
         {:ok, oban_messages} <- inject_oban(repo, opts) do
      {:ok,
       migration_messages ++
         config_messages ++ endpoint_messages ++ router_messages ++ oban_messages}
    end
  end

  defp inject_endpoint(repo, opts) do
    endpoint_path = endpoint_path(repo, opts)
    anchor = "  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]\n"
    snippet = "  plug Rulestead.Plug\n"

    with {:ok, message} <- FileInjector.inject_after(endpoint_path, anchor, snippet, "plug") do
      {:ok, [message]}
    end
  end

  defp inject_router(repo, opts) do
    router_path = router_path(repo, opts)
    helper_anchor = "  use #{inspect(web_module(repo))}, :router\n"
    helper_snippet = "\n  use RulesteadAdmin.Router\n"

    mount_snippet = """

      scope "/admin", #{inspect(web_module(repo))} do
        pipe_through :browser
        rulestead_admin "/flags", policy: #{inspect(app_module(repo))}.AdminPolicy
      end
    """

    with {:ok, helper_message} <-
           FileInjector.inject_after(router_path, helper_anchor, helper_snippet, "admin helper"),
         {:ok, mount_message} <-
           FileInjector.inject_before_last(router_path, "\nend\n", mount_snippet, "admin mount") do
      {:ok, [helper_message, mount_message]}
    end
  end

  defp inject_oban(repo, opts) do
    config_path = config_path(opts)
    app_name = application_atom(repo)
    oban_anchor = "config :#{app_name}, Oban,\n"
    oban_snippet = "  middlewares: [{Rulestead.Oban.Middleware, []}],\n"

    case File.read(config_path) do
      {:ok, contents} ->
        if String.contains?(contents, oban_anchor) do
          with {:ok, message} <-
                 FileInjector.inject_after(
                   config_path,
                   oban_anchor,
                   oban_snippet,
                   "Oban middlewares"
                 ) do
            {:ok, [message]}
          end
        else
          {:ok, ["skip #{Path.relative_to_cwd(config_path)} Oban middlewares not configured"]}
        end

      {:error, _reason} ->
        {:ok, ["skip #{Path.relative_to_cwd(config_path)} Oban middlewares not configured"]}
    end
  end

  defp endpoint_path(repo, opts) do
    Path.join(lib_root(opts), "#{web_path(repo)}/endpoint.ex")
  end

  defp router_path(repo, opts) do
    Path.join(lib_root(opts), "#{web_path(repo)}/router.ex")
  end

  defp config_path(opts) do
    config_dir = Keyword.get(opts, :config_path) || Path.join(File.cwd!(), "config")
    Path.join(config_dir, "config.exs")
  end

  defp lib_root(opts) do
    Keyword.get(opts, :lib_path) || Path.join(File.cwd!(), "lib")
  end

  defp web_module(repo) do
    repo
    |> app_module()
    |> Module.split()
    |> List.update_at(-1, &"#{&1}Web")
    |> Module.concat()
  end

  defp web_path(repo), do: "#{application_atom(repo)}_web"

  defp application_atom(repo) do
    repo
    |> app_module()
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp app_module(repo) do
    repo
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end
end
