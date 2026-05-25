defmodule Rulestead.Mix.Tasks.RulesteadExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Rulestead.StoreFixtures

  alias Rulestead.{Fake, Manifest}
  alias Rulestead.Store.Command

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)

    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging"]})
               )
             )

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command("checkout-redesign", "staging", valid_ruleset_attrs())
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "staging")
             )

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "writes canonical JSON to stdout by default" do
    output =
      capture_io(fn ->
        Mix.Tasks.Rulestead.Export.run(["--environment", "staging"])
      end)

    assert {:ok, manifest} = Manifest.load(output)
    assert manifest["environment_key"] == "staging"
  end

  test "writes canonical JSON to a file and supports - for stdout" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "rulestead-export-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    out_path = Path.join(tmp_dir, "rulestead.staging.json")

    Mix.Tasks.Rulestead.Export.run(["--environment", "staging", "--out", out_path])
    file_output = File.read!(out_path)

    stdout_output =
      capture_io(fn ->
        Mix.Task.reenable("rulestead.export")
        Mix.Tasks.Rulestead.Export.run(["--environment", "staging", "--out", "-"])
      end)

    assert file_output == stdout_output
  end
end
