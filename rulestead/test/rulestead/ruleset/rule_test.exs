defmodule Rulestead.Ruleset.RuleTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Rulestead.Ruleset.Rule

  describe "experiment strategy" do
    test "fails if experiment is missing" do
      attrs = %{
        key: "test-rule",
        strategy: "experiment",
        variants: [
          %{key: "v1", weight: 50, value: %{"a" => 1}},
          %{key: "v2", weight: 50, value: %{"a" => 2}}
        ]
      }

      changeset = Rule.changeset(%Rule{}, attrs)
      refute changeset.valid?
      assert {"must be present for experiment rules", _} = changeset.errors[:experiment]
    end

    test "fails if iteration_salt or holdout_percentage are missing in experiment" do
      attrs = %{
        key: "test-rule",
        strategy: "experiment",
        experiment: %{},
        variants: [
          %{key: "v1", weight: 50, value: %{"a" => 1}},
          %{key: "v2", weight: 50, value: %{"a" => 2}}
        ]
      }

      changeset = Rule.changeset(%Rule{}, attrs)
      refute changeset.valid?

      experiment_changeset = changeset.changes.experiment
      assert {"can't be blank", _} = experiment_changeset.errors[:iteration_salt]
    end

    test "handles :experiment strategy and validates embedded struct" do
      attrs = %{
        key: "test-rule",
        strategy: "experiment",
        experiment: %{
          iteration_salt: "some-salt",
          bucket_by: "subject",
          holdout_percentage: 10
        },
        variants: [
          %{key: "v1", weight: 50, value: %{"a" => 1}},
          %{key: "v2", weight: 50, value: %{"a" => 2}}
        ]
      }

      changeset = Rule.changeset(%Rule{}, attrs)
      assert changeset.valid?
      assert changeset.changes.strategy == :experiment
      assert changeset.changes.experiment.changes.iteration_salt == "some-salt"
      assert changeset.changes.experiment.changes.holdout_percentage == 10
    end
  end
end
