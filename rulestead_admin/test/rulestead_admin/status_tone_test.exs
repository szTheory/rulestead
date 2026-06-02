defmodule RulesteadAdmin.StatusToneTest do
  use ExUnit.Case, async: true

  alias RulesteadAdmin.StatusTone

  test "maps flag lifecycle states to canonical tones and labels" do
    assert StatusTone.tone(:flag_lifecycle, :active) == "positive"
    assert StatusTone.tone(:flag_lifecycle, :stale) == "critical"
    assert StatusTone.tone(:flag_lifecycle, :archived) == "muted"
    assert StatusTone.tone(:flag_lifecycle, :draft) == "accent"
    assert StatusTone.label(:flag_lifecycle, :potentially_stale) == "Potentially stale"
  end

  test "accepts string states (from query params / serialized state)" do
    assert StatusTone.tone(:change_request, "submitted") == "warning"
    assert StatusTone.label(:change_request, "submitted") == "Pending review"
  end

  test "covers the schedule and audience domains" do
    assert StatusTone.tone(:schedule, :failed) == "critical"
    assert StatusTone.tone(:schedule, :quarantined) == "warning"
    assert StatusTone.tone(:audience, :archived) == "muted"
    assert StatusTone.tone(:audience, :active) == "positive"
  end

  test "falls back to neutral with a humanized label for unknown states" do
    assert StatusTone.tone(:flag_lifecycle, :who_knows) == "neutral"
    assert StatusTone.label(:schedule, :brand_new_state) == "Brand new state"
    assert StatusTone.label(:change_request, "totally_unknown") == "Totally unknown"
  end
end
