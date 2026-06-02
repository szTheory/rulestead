defmodule RulesteadAdmin.StatusTone do
  @moduledoc """
  Single source of truth mapping domain entity states to the canonical tone
  vocabulary and a human label.

  The admin expresses state in many places — flag lifecycle badges, rollout
  guardrails, the change-request queue, the schedule list. Before this module
  each screen kept its own `state_tone/1`, so the same semantic state could
  drift to different colors. Screens now call `tone/2` (and optionally
  `label/2`) with a domain, so a given state renders one consistent way
  everywhere.

  Canonical tones — each has a `.rs-badge[data-tone=...]` (and related) CSS rule:
  `positive` · `warning` · `critical` · `neutral` · `muted` · `accent`.
  """

  @type domain ::
          :flag_lifecycle
          | :flag_readiness
          | :change_request
          | :schedule
          | :guardrail
          | :audience
  @type tone :: String.t()

  # domain => %{state => {tone, label}}
  @table %{
    flag_lifecycle: %{
      active: {"positive", "Active"},
      fresh: {"positive", "Active"},
      potentially_stale: {"warning", "Potentially stale"},
      stale: {"critical", "Stale"},
      archived: {"muted", "Archived"},
      draft: {"accent", "Draft"}
    },
    flag_readiness: %{
      keep_active: {"positive", "Keep active"},
      needs_review: {"warning", "Needs review"},
      archive_candidate: {"critical", "Archive candidate"}
    },
    change_request: %{
      submitted: {"warning", "Pending review"},
      approved: {"positive", "Approved"},
      rejected: {"critical", "Rejected"},
      executed: {"muted", "Executed"},
      cancelled: {"muted", "Cancelled"},
      merged: {"positive", "Merged"},
      scheduled: {"neutral", "Scheduled"}
    },
    schedule: %{
      scheduled: {"neutral", "Upcoming"},
      running: {"positive", "Running"},
      completed: {"positive", "Completed"},
      failed: {"critical", "Failed"},
      quarantined: {"warning", "Quarantined"},
      cancelled: {"muted", "Cancelled"}
    },
    guardrail: %{
      healthy: {"positive", "Healthy"},
      pending_data: {"warning", "Awaiting data"},
      held: {"warning", "Held"},
      breached: {"critical", "Breached"},
      failed_closed: {"critical", "Failed closed"},
      rollback_triggered: {"critical", "Rolled back"}
    },
    audience: %{
      active: {"positive", "Active"},
      draft: {"accent", "Draft"},
      archived: {"muted", "Archived"}
    }
  }

  @doc "Canonical tone string for a domain state. Falls back to `neutral`."
  @spec tone(domain(), atom() | String.t()) :: tone()
  def tone(domain, state), do: lookup(domain, state) |> elem(0)

  @doc "Canonical human label for a domain state. Falls back to a humanized state."
  @spec label(domain(), atom() | String.t()) :: String.t()
  def label(domain, state), do: lookup(domain, state) |> elem(1)

  defp lookup(domain, state) do
    state_atom = normalize_state(state)

    @table
    |> Map.get(domain, %{})
    |> Map.get(state_atom, {"neutral", default_label(state)})
  end

  defp normalize_state(state) when is_atom(state), do: state

  defp normalize_state(state) when is_binary(state) do
    String.to_existing_atom(state)
  rescue
    ArgumentError -> nil
  end

  defp normalize_state(_state), do: nil

  defp default_label(state) when is_atom(state) and not is_nil(state),
    do: state |> Atom.to_string() |> humanize()

  defp default_label(state) when is_binary(state), do: humanize(state)
  defp default_label(_state), do: "Unknown"

  defp humanize(value), do: value |> String.replace("_", " ") |> String.capitalize()
end
