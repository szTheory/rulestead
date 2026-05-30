defmodule Rulestead.CredoChecksTest do
  use Credo.Test.Case, async: true

  alias Rulestead.Credo.NoEvalOutsideContext
  alias Rulestead.Credo.NoMutationOutsideMulti
  alias Rulestead.Credo.NoRawTraitsInLogger
  alias Rulestead.Credo.NoRawTraitsInTelemetryMeta
  alias Rulestead.Credo.NoSocketCapturedInAsync

  @fixtures_dir Path.expand("../support/credo_fixtures", __DIR__)

  setup_all do
    case Application.ensure_all_started(:credo) do
      {:ok, _} -> :ok
      {:error, {:credo, {:already_started, _}}} -> :ok
      other -> raise "failed to start :credo: #{inspect(other)}"
    end

    :ok
  end

  test "NoRawTraitsInTelemetryMeta flags raw telemetry trait keys" do
    issues =
      fixture_source_file("raw_traits_in_telemetry.ex")
      |> run_check(NoRawTraitsInTelemetryMeta)

    assert_issues(issues, fn found ->
      assert Enum.count(found) == 2
      assert Enum.sort(Enum.map(found, & &1.trigger)) == ["email", "ip"]
      assert Enum.all?(found, &String.contains?(&1.message, "Telemetry metadata"))
      assert Enum.all?(found, &is_nil(&1.line_no))
    end)
  end

  test "NoRawTraitsInLogger flags raw logger trait keys" do
    issues =
      fixture_source_file("raw_traits_in_logger.ex")
      |> run_check(NoRawTraitsInLogger)

    assert_issues(issues, fn found ->
      assert Enum.count(found) == 2
      assert Enum.sort(Enum.map(found, & &1.trigger)) == ["email", "ip"]
      assert Enum.all?(found, &String.contains?(&1.message, "Logger metadata"))
      assert Enum.all?(found, &is_nil(&1.line_no))
    end)
  end

  test "NoMutationOutsideMulti flags direct rulestead writes" do
    fixture_source_file("mutation_outside_multi.ex")
    |> run_check(NoMutationOutsideMulti)
    |> assert_issue(fn issue ->
      assert issue.line_no == 6
      assert issue.message =~ "Ecto.Multi-backed flow"
    end)
  end

  test "NoSocketCapturedInAsync flags async closures that capture socket" do
    fixture_source_file("socket_captured_in_async.ex")
    |> run_check(NoSocketCapturedInAsync)
    |> assert_issue(fn issue ->
      assert issue.trigger == "start_async"
      assert issue.line_no == 3
      assert issue.message =~ "must not capture `socket`"
    end)
  end

  test "NoEvalOutsideContext flags direct evaluator entrypoints" do
    fixture_source_file("eval_outside_context.ex")
    |> run_check(NoEvalOutsideContext)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.message =~ "public Rulestead facade"
    end)
  end

  defp fixture_source_file(filename) do
    path = Path.join(@fixtures_dir, filename)

    path
    |> File.read!()
    |> to_source_file(path)
  end
end
