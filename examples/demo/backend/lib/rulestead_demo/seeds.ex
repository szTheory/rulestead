defmodule RulesteadDemo.Seeds do
  @moduledoc """
  Idempotent FleetDesk adoption-lab seed data.

  Exercises boolean rollout, variant copy, JSON remote config, guarded rollout,
  audience preview, and the primary kill-switch flag used by compose smoke +
  Playwright proofs.
  """

  alias Rulestead.Audience
  alias Rulestead.Repo
  alias Rulestead.Store.Command
  alias Rulestead.Runtime.Refresh
  alias RulesteadDemo.Fixtures

  @seed_metadata %{seed: "fleetdesk-adoption-lab"}

  @audience_specs [
    %{
      key: "fleet-ops-dispatchers",
      description:
        "Pro-plan dispatch operators who manage live route queues and validate audience previews before an ops-facing rollout changes targeting.",
      definition: %{
        conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
      }
    }
  ]

  @flag_specs [
    %{
      key: "enable-new-dashboard",
      description:
        "Replaces the legacy dispatch cockpit with the Fleet Map v2 layout for operators. Kept as a permanent kill switch so SREs can roll back quickly if dispatch latency or error rates spike.",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "platform-team",
      tags: ["demo", "adoption-lab", "kill-switch"],
      ruleset: %{
        salt: "enable-new-dashboard:fleetdesk:v1",
        rules: [
          %{
            key: "always-on-demo-dashboard",
            name: "Always on in the adoption lab",
            strategy: :forced_value,
            value: %{value: true},
            conditions: []
          }
        ]
      }
    },
    %{
      key: "fleet-map-v2",
      description:
        "Rolls out the WebGL vector map renderer for dense fleet routes. The staged release measures smoother map interaction while watching client crash rates before full production exposure.",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "maps-team",
      tags: ["demo", "adoption-lab", "rollout"],
      ruleset: %{
        salt: "fleet-map-v2:fleetdesk:v1",
        rules: [
          %{
            key: "enterprise-map-v2",
            name: "Enterprise fleet managers",
            strategy: :forced_value,
            value: %{value: true},
            conditions: [
              %{
                attribute: "attributes.plan",
                operator: :equals,
                value: %{equals: "enterprise"}
              }
            ]
          },
          %{
            key: "pro-percentage-rollout",
            name: "Pro plan staged rollout",
            strategy: :percentage_rollout,
            value: %{value: true},
            rollout: %{bucket_by: :subject, percentage: 50, salt: "fleet-map-v2:pro"},
            conditions: [
              %{
                attribute: "attributes.plan",
                operator: :equals,
                value: %{equals: "pro"}
              }
            ]
          }
        ]
      }
    },
    %{
      key: "dispatch-ops-copy",
      description:
        "Tests changing the dispatch queue headline from neutral queue status to urgent-route prioritization. The experiment looks for faster first action on critical routes without adding operator noise.",
      flag_type: :experiment,
      value_type: :string,
      default_value: %{value: "Standard dispatch queue"},
      owner: "growth-team",
      permanent: false,
      expected_expiration: ~D[2026-07-31],
      tags: ["demo", "adoption-lab", "experiment"],
      ruleset: %{
        salt: "dispatch-ops-copy:fleetdesk:v1",
        rules: [
          %{
            key: "urgent-routes-copy",
            name: "Urgent routes headline",
            strategy: :forced_value,
            value: %{value: "Prioritize urgent routes first."},
            conditions: []
          }
        ]
      }
    },
    %{
      key: "ops-banner-config",
      description:
        "Controls the global operations banner payload for weather, outage, and reroute advisories. Lets ops update severity, message, and call to action without shipping frontend code.",
      flag_type: :remote_config,
      value_type: :json,
      default_value: %{value: %{"message" => nil, "severity" => "info", "cta" => nil}},
      owner: "ops-team",
      tags: ["demo", "adoption-lab", "remote-config"],
      ruleset: %{
        salt: "ops-banner-config:fleetdesk:v1",
        rules: [
          %{
            key: "winter-storm-banner",
            name: "Winter storm advisory",
            strategy: :forced_value,
            value: %{
              value: %{
                "message" => "Winter storm advisory — review reroute playbook.",
                "severity" => "warning",
                "cta" => "Open reroute playbook"
              }
            },
            conditions: []
          }
        ]
      }
    },
    %{
      key: "dispatch-guarded-rollout",
      description:
        "Compares standard routing with a priority-route algorithm meant to surface time-sensitive jobs earlier. Host-supplied guardrails halt advancement if dispatch error rate reaches 5%.",
      flag_type: :experiment,
      value_type: :string,
      default_value: %{value: "standard-route"},
      owner: "platform-team",
      tags: ["demo", "adoption-lab", "guarded-rollout"],
      ruleset: %{
        salt: "dispatch-guarded-rollout:fleetdesk:v1",
        rules: [
          %{
            key: "priority-routes-split",
            name: "Priority routes split",
            strategy: :variant_split,
            rollout: %{
              bucket_by: :subject,
              percentage: 100,
              salt: "dispatch-guarded-rollout:split",
              guardrails: [
                %{
                  signal_key: "dispatch_error_rate",
                  threshold_operator: :gte,
                  threshold_value: 0.05,
                  freshness_window_seconds: 300,
                  min_sample_size: 100,
                  environment_scope: :environment,
                  tenant_scope: :required
                }
              ]
            },
            variants: [
              %{key: "control", weight: 50, value: %{value: "standard-route"}},
              %{key: "treatment", weight: 50, value: %{value: "priority-route"}}
            ]
          }
        ]
      }
    },
    %{
      key: "ops-audience-preview",
      description:
        "Limits the new operations panel to Pro-plan dispatchers during beta. The flag demonstrates audience preview evidence before widening access to more dispatcher cohorts.",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "ops-team",
      tags: ["demo", "adoption-lab", "audience-preview"],
      ruleset: %{
        salt: "ops-audience-preview:fleetdesk:v1",
        rules: [
          %{
            key: "dispatcher-audience",
            name: "Fleet dispatchers audience",
            strategy: :segment_match,
            audience_key: "fleet-ops-dispatchers",
            value: %{value: true},
            conditions: []
          }
        ]
      }
    }
  ]

  @doc """
  Seeds all FleetDesk adoption-lab flags and refreshes runtime snapshots.
  """
  @spec run!() :: :ok
  def run! do
    actor = Fixtures.demo_actor()

    Enum.each(@audience_specs, &ensure_audience!/1)

    Enum.each(@flag_specs, fn spec ->
      ensure_flag!(spec, actor)
      publish_ruleset!(spec, actor)
    end)

    refresh_runtime!()

    IO.puts(
      "Seeded FleetDesk adoption lab: #{length(@flag_specs)} flags across #{inspect(Fixtures.environment_keys())}."
    )

    :ok
  end

  defp ensure_audience!(%{key: key} = spec) do
    case Repo.get_by(Audience, key: key) do
      %Audience{} = audience ->
        audience
        |> Audience.changeset(%{
          description: spec.description,
          definition: spec.definition
        })
        |> Repo.update!()

        :ok

      nil ->
        %Audience{}
        |> Audience.changeset(%{
          key: key,
          description: spec.description,
          definition: spec.definition
        })
        |> Repo.insert!()

        :ok
    end
  end

  defp ensure_flag!(%{key: key} = spec, actor) do
    case Rulestead.fetch_flag(key, "staging", include_ruleset?: false) do
      {:ok, _flag} ->
        {:ok, _updated} =
          Rulestead.update_flag(
            key,
            %{
              description: spec.description,
              owner: spec.owner,
              permanent: flag_permanent?(spec),
              expected_expiration: Map.get(spec, :expected_expiration),
              tags: spec.tags
            },
            actor: actor,
            metadata: @seed_metadata
          )

        :ok

      {:error, _error} ->
        {:ok, _flag} =
          Rulestead.create_flag(
            %{
              key: key,
              description: spec.description,
              flag_type: spec.flag_type,
              value_type: spec.value_type,
              default_value: spec.default_value,
              owner: spec.owner,
              permanent: flag_permanent?(spec),
              expected_expiration: Map.get(spec, :expected_expiration),
              tags: spec.tags,
              environment_keys: Fixtures.environment_keys()
            },
            actor: actor,
            metadata: @seed_metadata
          )
    end
  end

  defp flag_permanent?(spec), do: Map.get(spec, :permanent, true)

  defp publish_ruleset!(%{key: key, ruleset: ruleset}, actor) do
    Enum.each(Fixtures.environment_keys(), fn environment_key ->
      {:ok, _draft} =
        Rulestead.save_draft_ruleset(
          Command.SaveDraftRuleset.new(key, environment_key, ruleset,
            actor: actor,
            metadata: @seed_metadata
          )
        )

      {:ok, _published} =
        Rulestead.publish_ruleset(
          Command.PublishRuleset.new(key, environment_key,
            actor: actor,
            metadata: @seed_metadata
          )
        )
    end)
  end

  defp refresh_runtime! do
    Enum.each(
      [
        RulesteadDemo.RuntimeRefresh.Staging,
        RulesteadDemo.RuntimeRefresh.Production
      ],
      fn refresh_name ->
        if Process.whereis(refresh_name) do
          :ok = Refresh.refresh_now(refresh_name)
        end
      end
    )
  end
end
