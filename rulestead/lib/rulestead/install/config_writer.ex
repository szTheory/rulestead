defmodule Rulestead.Install.ConfigWriter do
  @moduledoc false

  alias Rulestead.Config, as: RulesteadConfig
  alias Rulestead.Install.FileInjector

  @import_line ~s(import_config "rulestead.exs")

  @spec write(module(), keyword()) :: {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
  def write(repo, opts \\ []) do
    config_dir = Keyword.get(opts, :config_path) || Path.join(File.cwd!(), "config")
    rulestead_path = Path.join(config_dir, "rulestead.exs")
    config_path = Path.join(config_dir, "config.exs")

    File.mkdir_p!(config_dir)

    rendered = render_template(repo)

    with {:ok, config_message} <- maybe_write_rulestead_config(rulestead_path, rendered),
         {:ok, import_message} <- maybe_inject_import(config_path) do
      {:ok, [config_message, import_message]}
    end
  end

  defp render_template(repo) do
    """
    import Config

    config :rulestead, :store, Rulestead.Store.Ecto

    config :rulestead, Rulestead.Repo,
      repo: #{inspect(repo)}

    config :rulestead, :host,
    #{render_keyword_block(RulesteadConfig.defaults(), 2)}
    """
  end

  defp maybe_write_rulestead_config(path, rendered) do
    case File.read(path) do
      {:ok, ^rendered} ->
        {:ok, "skip #{Path.relative_to_cwd(path)} already present"}

      {:ok, _existing} ->
        File.write!(path, rendered)
        {:ok, "write #{Path.relative_to_cwd(path)}"}

      {:error, :enoent} ->
        File.write!(path, rendered)
        {:ok, "write #{Path.relative_to_cwd(path)}"}
    end
  end

  defp maybe_inject_import(config_path) do
    FileInjector.inject_after(
      config_path,
      "import Config\n",
      "\n" <> @import_line <> "\n",
      "import"
    )
  end

  defp render_keyword_block(keyword, indent) do
    keyword
    |> inspect(pretty: true, limit: :infinity)
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> String.duplicate(" ", indent) <> line end)
  end
end
