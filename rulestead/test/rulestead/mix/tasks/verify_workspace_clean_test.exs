defmodule Rulestead.Mix.Tasks.VerifyWorkspaceCleanTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Verify.WorkspaceClean

  test "scopes cleanliness to package files plus test" do
    project_config = [package: [files: ~w(lib priv README.md guides)]]

    assert WorkspaceClean.scoped_paths(project_config) == [
             "README.md",
             "guides",
             "lib",
             "priv",
             "test"
           ]
  end

  test "reports dirty publishable surfaces" do
    status_output = """
     M lib/rulestead.ex
    ?? test/rulestead/mix/tasks/verify_workspace_clean_test.exs
    """

    assert {:dirty, paths} = WorkspaceClean.verify_status(status_output)

    assert paths == [
             "lib/rulestead.ex",
             "test/rulestead/mix/tasks/verify_workspace_clean_test.exs"
           ]
  end

  test "rejects unknown escape-hatch flags" do
    assert_raise Mix.Error, ~r/unknown option/, fn ->
      WorkspaceClean.run(["--allow-dirty"])
    end
  end
end
