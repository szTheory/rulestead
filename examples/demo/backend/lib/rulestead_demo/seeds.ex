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
      description: "Pro-plan dispatch operators for audience preview journeys.",
      definition: %{
        conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
      }
    }
  ]

  @flag_specs [
    %{
      key: "enable-new-dashboard",
      description: "Controls the new Fleet Map v2 cockpit layout for dispatch operators. Allows safe rollback if the new interface causes latency spikes or dispatch errors.",
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
      description: "Gradual release of the WebGL vector map renderer. Enables high-performance rendering for dense fleet routes, actively monitored for client-side crash rates.",
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
      description: "A/B testing the primary headline on the dispatch queue. Evaluates 'Urgent' vs 'Standard' framing to see if it reduces time-to-first-dispatch for critical routes.",
      flag_type: :experiment,
      value_type: :string,
      default_value: %{value: "Standard dispatch queue"},
      owner: "growth-team",
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
      description: "Dynamically controls the global operations alert banner via JSON payload. Used for broadcasting real-time system degradations or severe weather advisories to all dispatchers.",
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
      description: "Tests a new priority routing algorithm against the standard route. Monitored by a host-supplied guardrail that automatically halts the rollout if dispatch error rates exceed 5%.",
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
      description: "Gates the new operational dashboard specifically for Pro-plan dispatchers. Utilizes Rulestead's audience segmentation to ensure precise targeting during the beta phase.",
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
      %Audience{} ->
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
              permanent: true,
              tags: spec.tags,
              environment_keys: Fixtures.environment_keys()
            },
            actor: actor,
            metadata: @seed_metadata
          )
    end
  end

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
