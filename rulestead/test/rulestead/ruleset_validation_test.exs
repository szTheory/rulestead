defmodule Rulestead.RulesetValidationTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Rulestead.Ruleset
  import Rulestead.StoreFixtures

  test "accepts Phase 3 authored semantics including nested paths, regex payloads, and segment rules" do
    changeset = Ruleset.changeset(%Ruleset{}, ruleset_attrs(valid_ruleset_attrs()))

    assert changeset.valid?
  end

  test "rejects unsupported path syntax before runtime evaluation" do
    changeset = Ruleset.changeset(%Ruleset{}, ruleset_attrs(invalid_path_ruleset_attrs()))

    refute changeset.valid?
    assert error_on(changeset, :rules) =~ "dot-separated map paths only"
  end

  test "rejects malformed regex payloads and mixed-type list payloads" do
    regex_changeset = Ruleset.changeset(%Ruleset{}, ruleset_attrs(invalid_regex_ruleset_attrs()))
    mixed_list_changeset = Ruleset.changeset(%Ruleset{}, ruleset_attrs(invalid_operator_payload_ruleset_attrs()))

    refute regex_changeset.valid?
    refute mixed_list_changeset.valid?
    assert error_on(regex_changeset, :rules) =~ "valid regex pattern"
    assert error_on(mixed_list_changeset, :rules) =~ "single type"
  end

  test "keeps variant weights and rollout authoring rules enforced" do
    changeset = Ruleset.changeset(%Ruleset{}, ruleset_attrs(invalid_variant_weight_ruleset_attrs()))

    refute changeset.valid?
    assert error_on(changeset, :rules) =~ "weights must sum to 100"
  end

  defp ruleset_attrs(attrs) do
    Map.merge(attrs, %{flag_environment_id: Ecto.UUID.generate(), version: 1, status: :draft})
  end

  defp error_on(changeset, field) do
    {message, _opts} = Keyword.fetch!(changeset.errors, field)
    message
  rescue
    KeyError ->
      changeset
      |> Changeset.traverse_errors(fn {message, _opts} -> message end)
      |> inspect()
  end
end
