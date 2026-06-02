defmodule RulesteadAdmin.Navigation do
  @moduledoc false

  # Single source of truth for the admin's top-level navigation.
  #
  # Destinations are grouped by the operator's task rhythm — the group headers
  # name the *job* (a GDS "start with the user's task" framing), so the left rail
  # and the home console teach the same build → release → explain → recover
  # mental model:
  #
  #   Build & release    — author flags, target audiences, schedule and ship
  #   Explain & diagnose — answer "why did this happen?" and check health
  #   Review & approve    — govern changes through the approval queue
  #
  # Each item: %{key, label, suffix}. `suffix` is appended to the admin mount
  # path (e.g. "/admin/flags"). Only destinations with real routes appear here.
  # Per-flag verbs (rules/simulate/explain/rollouts/kill/timeline) are a
  # contextual sub-nav scoped to a flag, not global destinations.
  #
  # Intentional departures from the original UX spec (prompts/rulestead-admin-
  # ux-and-operator-ia.md), recorded here so future readers don't "fix" them:
  #
  #   * Grouped, not a flat 8-item rail. Three task-rhythm groups scan faster
  #     under pressure (a 3am SRE jumps to "Explain & diagnose") than one flat
  #     list the eye must read end-to-end.
  #   * No top-level "Rulesets" destination. Rulesets are edited per-flag at
  #     `/:key/rules`; there is no global ruleset browser.
  #   * No top-level "Settings" destination yet (deferred).
  #   * Progressive disclosure is contextual (capability gating, optional-dep
  #     gating, <details> panels) rather than a per-user Simple/Advanced mode.

  @groups [
    {"Build & release",
     [
       %{key: :flags, label: "Flags", suffix: "/flags"},
       %{key: :experiments, label: "Experiments", suffix: "/experiments"},
       %{key: :audiences, label: "Audiences", suffix: "/audiences"},
       %{key: :schedule, label: "Schedule", suffix: "/schedule"}
     ]},
    {"Explain & diagnose",
     [
       %{key: :diagnostics, label: "Diagnostics", suffix: "/diagnostics"},
       %{key: :audit, label: "Audit", suffix: "/audit"},
       %{key: :compare, label: "Compare", suffix: "/compare"}
     ]},
    {"Review & approve",
     [
       %{key: :change_requests, label: "Change requests", suffix: "/change-requests"},
       %{key: :webhooks, label: "Webhooks", suffix: "/webhooks"}
     ]}
  ]

  @doc """
  Returns the grouped navigation for the left rail.

  Each group is `%{title, items}` where each item carries a resolved `path`
  (scoped to the current environment) and a `current?` flag.

  `current` is the active section key (e.g. `:flags`) or `nil`.
  """
  @doc """
  The standalone Overview (home console) destination, rendered above the groups.
  """
  def overview(base_path, env_key, current \\ nil) when is_binary(base_path) do
    %{
      key: :home,
      label: "Overview",
      path: base_path <> env_query(env_key),
      current?: current == :home
    }
  end

  def groups(base_path, env_key, current \\ nil) when is_binary(base_path) do
    env_q = env_query(env_key)

    for {title, items} <- @groups do
      %{
        title: title,
        items:
          for item <- items do
            %{
              key: item.key,
              label: item.label,
              path: base_path <> item.suffix <> env_q,
              current?: item.key == current
            }
          end
      }
    end
  end

  @doc """
  Flat list of all destination items (no group structure), resolved against the
  environment. Useful for the home console and the command palette.
  """
  def items(base_path, env_key, current \\ nil) when is_binary(base_path) do
    base_path
    |> groups(env_key, current)
    |> Enum.flat_map(& &1.items)
  end

  defp env_query(nil), do: ""
  defp env_query(""), do: ""
  defp env_query(env_key), do: "?env=#{env_key}"
end
