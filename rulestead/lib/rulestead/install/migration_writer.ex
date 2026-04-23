defmodule Rulestead.Install.MigrationWriter do
  @moduledoc false

  @source_dir Application.app_dir(:rulestead, "priv/repo/migrations")

  @spec copy_migrations(module(), keyword()) ::
          {:ok, [String.t()]} | {:error, Rulestead.Error.t()}
  def copy_migrations(repo, opts \\ []) do
    target_dir = Keyword.get(opts, :migrations_path) || target_path_for_repo(repo)
    File.mkdir_p!(target_dir)

    messages =
      @source_dir
      |> File.ls!()
      |> Enum.sort()
      |> Enum.map(fn filename ->
        source = Path.join(@source_dir, filename)
        target = Path.join(target_dir, filename)

        case File.exists?(target) do
          true ->
            "skip #{Path.relative_to_cwd(target)} already present"

          false ->
            File.cp!(source, target)
            "copy #{Path.relative_to_cwd(target)}"
        end
      end)

    {:ok, messages}
  end

  defp target_path_for_repo(repo) do
    _repo = repo
    Path.join(File.cwd!(), "priv/repo/migrations")
  end
end
