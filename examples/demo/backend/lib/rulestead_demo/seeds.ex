defmodule RulesteadDemo.Seeds do
  @moduledoc """
  Idempotent FleetDesk adoption-lab seed data.

  Exercises boolean rollout, variant copy, JSON remote config, guarded rollout,
  audience preview, and the primary kill-switch flag used by compose smoke +
  Playwright proofs.
  """

  import Ecto.Query

  alias Rulestead.AuditEvent
  alias Rulestead.Audience
  alias Rulestead.CodeRefs.{CodeReference, ScanReceipt}
  alias Rulestead.FlagEnvironment
  alias Rulestead.Repo
  alias Rulestead.Store.Command
  alias Rulestead.Runtime.Refresh
  alias RulesteadDemo.Fixtures

  @seed_name "fleetdesk-adoption-lab"
  @seed_version "fleetdesk-adoption-lab:v2"
  @seed_metadata %{seed: @seed_name, seed_version: @seed_version}

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
      evaluation_age_days: 46,
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
      key: "route-eta-legacy",
      description:
        "Retired ETA wording experiment that compared precise arrival estimates against broader delivery windows. The route-planning team has moved to the newer prediction service, so this flag demonstrates an archive-ready cleanup candidate.",
      flag_type: :experiment,
      value_type: :string,
      default_value: %{value: "precise-eta"},
      owner: "growth-team",
      permanent: false,
      expected_expiration: ~D[2026-04-30],
      tags: ["demo", "adoption-lab", "cleanup"],
      ruleset: %{
        salt: "route-eta-legacy:fleetdesk:v1",
        rules: [
          %{
            key: "broad-window-copy",
            name: "Broad ETA window",
            strategy: :forced_value,
            value: %{value: "delivery-window"},
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
      key: "ops-banner-legacy",
      description:
        "Archived predecessor to the current operations banner config. It remains in the demo so operators can inspect how completed cleanup work appears after a flag leaves active inventory.",
      flag_type: :remote_config,
      value_type: :json,
      default_value: %{value: %{"message" => "Legacy advisory", "severity" => "info"}},
      owner: "ops-team",
      tags: ["demo", "adoption-lab", "archived"],
      archived?: true,
      ruleset: %{
        salt: "ops-banner-legacy:fleetdesk:v1",
        rules: [
          %{
            key: "legacy-banner",
            name: "Legacy banner payload",
            strategy: :forced_value,
            value: %{value: %{"message" => "Legacy advisory", "severity" => "info"}},
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
      evaluation_age_days: 46,
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

  @code_reference_specs [
    %{
      flag_key: "fleet-map-v2",
      file: "assets/js/fleet_map_renderer.js",
      line: 42
    },
    %{
      flag_key: "ops-banner-config",
      file: "lib/fleetdesk/ops_banner.ex",
      line: 18
    }
  ]

  @doc """
  Seeds all FleetDesk adoption-lab flags and refreshes runtime snapshots.
  """
  @spec run!() :: :ok
  def run! do
    actor = Fixtures.demo_actor()
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Enum.each(@audience_specs, &ensure_audience!/1)

    Enum.each(@flag_specs, fn spec ->
      ensure_flag!(spec, actor)
      publish_ruleset!(spec, actor)
    end)

    seed_evidence!(now)
    archive_seed_flags!(actor)
    seed_audit_timelines!(actor, now)
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
        unless Map.get(spec, :archived?, false) do
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
        end

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
    if archived_seed_flag?(key) and archived_flag?(key) do
      :ok
    else
      do_publish_ruleset!(key, ruleset, actor)
    end
  end

  defp do_publish_ruleset!(key, ruleset, actor) do
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

  defp seed_audit_timelines!(actor, now) do
    seed_archived_banner_timeline!(actor, now)
    seed_kill_switch_timeline!(actor)
    seed_guardrail_timeline!(actor, now)
    seed_denied_audience_preview!(actor, now)
  end

  defp seed_archived_banner_timeline!(actor, now) do
    occurred_at = DateTime.add(now, -3_600, :second)
    request_id = seed_request_id("ops-banner-legacy", "staging", "flag.archive:v1")

    ensure_seed_audit_event!(%{
      event_type: "flag.archive",
      resource_key: "ops-banner-legacy",
      environment_key: "staging",
      actor: actor,
      reason: "Retired after ops-banner-config replaced the legacy advisory payload.",
      correlation_id: request_id,
      occurred_at: occurred_at,
      metadata: %{
        request_id: request_id,
        scenario: "flag.archive:v1",
        before: %{
          "status" => "active",
          "archive_state" => "serving legacy operations banner payload"
        },
        after: %{
          "status" => "archived",
          "archive_state" => "ops-banner-config now owns advisory payloads"
        },
        diff: %{
          "status" => %{"from" => "active", "to" => "archived"},
          "replacement_flag_key" => %{"from" => nil, "to" => "ops-banner-config"}
        }
      }
    })
  end

  defp seed_kill_switch_timeline!(actor) do
    flag_key = "enable-new-dashboard"
    environment_key = "staging"
    engage_request_id = seed_request_id(flag_key, environment_key, "kill_switch.engage:v1")
    rollback_request_id = seed_request_id(flag_key, environment_key, "audit.rollback:v1")

    unless seed_audit_event_exists?(rollback_request_id) do
      engage_event =
        find_seed_audit_event(engage_request_id) ||
          engage_seed_kill_switch!(flag_key, environment_key, actor, engage_request_id)

      unless seed_audit_event_exists?(rollback_request_id) do
        {:ok, _rollback} =
          Rulestead.rollback_audit_event(
            engage_event.id,
            actor: actor,
            reason: "Demo rollback after dispatch latency returned to baseline.",
            metadata: seed_command_metadata(rollback_request_id, "audit.rollback:v1")
          )
      end
    end
  end

  defp engage_seed_kill_switch!(flag_key, environment_key, actor, request_id) do
    {:ok, _flag} =
      Rulestead.engage_kill_switch(
        flag_key,
        environment_key,
        actor,
        reason: "Temporary demo kill switch while operators investigate elevated latency.",
        metadata: seed_command_metadata(request_id, "kill_switch.engage:v1")
      )

    find_seed_audit_event!(request_id)
  end

  defp seed_guardrail_timeline!(actor, now) do
    flag_key = "dispatch-guarded-rollout"
    environment_key = "staging"
    base_time = DateTime.add(now, -2_700, :second)

    [
      {"rollout.guardrail_evaluated", "guardrail.evaluated:v1", "Guardrail evidence reviewed.",
       "healthy", "healthy", 0.031, base_time},
      {"rollout.guardrail_held", "guardrail.held:v1",
       "Dispatch error rate crossed the rollout hold threshold.", "breached", "breached", 0.057,
       DateTime.add(base_time, 900, :second)},
      {"rollout.guardrail_rollback", "guardrail.rollback:v1",
       "Automation restored the last stable rollout snapshot.", "breached", "breached", 0.061,
       DateTime.add(base_time, 1_800, :second)}
    ]
    |> Enum.each(fn {event_type, scenario, reason, status, guardrail_reason, observed,
                     occurred_at} ->
      request_id = seed_request_id(flag_key, environment_key, scenario)

      ensure_seed_audit_event!(%{
        event_type: event_type,
        resource_key: flag_key,
        environment_key: environment_key,
        actor: actor,
        reason: reason,
        correlation_id: request_id,
        occurred_at: occurred_at,
        metadata: %{
          request_id: request_id,
          scenario: scenario,
          source: "guardrail_automation",
          guardrail: %{
            signal_key: "dispatch_error_rate",
            environment_key: environment_key,
            tenant_key: "acme-logistics",
            status: status,
            reason: guardrail_reason,
            threshold_operator: "gte",
            threshold_value: 0.05,
            observed_value: observed,
            freshness_window_seconds: 300,
            sample_size: 148,
            min_sample_size: 100,
            evaluated_at: occurred_at
          },
          links: %{
            guardrail_decision_id: request_id,
            stable_guardrail_decision_id:
              seed_request_id(flag_key, environment_key, "guardrail.evaluated:v1")
          }
        }
      })
    end)
  end

  defp seed_denied_audience_preview!(actor, now) do
    request_id = seed_request_id("ops-audience-preview", "staging", "ruleset.publish.denied:v1")

    ensure_seed_audit_event!(%{
      event_type: "ruleset.publish",
      resource_key: "ops-audience-preview",
      environment_key: "staging",
      actor: actor,
      reason: "Viewer attempted to widen beta access before review completed.",
      result: :denied,
      correlation_id: request_id,
      occurred_at: DateTime.add(now, -1_200, :second),
      metadata: %{
        request_id: request_id,
        scenario: "ruleset.publish.denied:v1",
        before: %{"audience_key" => "fleet-ops-dispatchers", "status" => "draft"},
        after: %{"audience_key" => "all-dispatchers", "status" => "blocked"},
        diff: %{
          "audience_key" => %{"from" => "fleet-ops-dispatchers", "to" => "all-dispatchers"},
          "status" => %{"from" => "draft", "to" => "blocked"}
        }
      }
    })
  end

  defp ensure_seed_audit_event!(attrs) do
    request_id = Map.fetch!(attrs, :correlation_id)

    if seed_audit_event_exists?(request_id) do
      :ok
    else
      actor = Map.fetch!(attrs, :actor)
      metadata_attrs = Map.get(attrs, :metadata, %{})

      metadata =
        AuditEvent.metadata(metadata_attrs)
        |> Map.merge(%{
          "seed" => @seed_name,
          "seed_version" => @seed_version,
          "scenario" => metadata_attrs[:scenario] || metadata_attrs["scenario"],
          "request_id" =>
            metadata_attrs[:request_id] || metadata_attrs["request_id"] || request_id
        })

      %AuditEvent{}
      |> AuditEvent.changeset(%{
        event_type: Map.fetch!(attrs, :event_type),
        resource_type: "flag",
        resource_key: Map.fetch!(attrs, :resource_key),
        environment_key: Map.fetch!(attrs, :environment_key),
        actor_id: actor_value(actor, "id"),
        actor_type: actor_value(actor, "type") || "operator",
        actor_display: actor_value(actor, "display"),
        reason: Map.get(attrs, :reason),
        result: Map.get(attrs, :result, :ok),
        metadata: metadata,
        correlation_id: request_id,
        occurred_at: Map.get(attrs, :occurred_at)
      })
      |> Repo.insert!()

      :ok
    end
  end

  defp seed_audit_event_exists?(correlation_id),
    do: not is_nil(find_seed_audit_event(correlation_id))

  defp find_seed_audit_event!(correlation_id) do
    Repo.get_by!(AuditEvent, correlation_id: correlation_id)
  end

  defp find_seed_audit_event(correlation_id) do
    Repo.get_by(AuditEvent, correlation_id: correlation_id)
  end

  defp seed_request_id(flag_key, environment_key, scenario) do
    "#{@seed_version}:#{flag_key}:#{environment_key}:#{scenario}"
  end

  defp seed_command_metadata(request_id, scenario) do
    @seed_metadata
    |> Map.put(:request_id, request_id)
    |> Map.put(:scenario, scenario)
  end

  defp actor_value(actor, key) when is_map(actor) do
    actor[key] || actor[String.to_atom(key)]
  end

  defp actor_value(_actor, _key), do: nil

  defp seed_evidence!(now) do
    seed_code_references!(now)

    Enum.each(@flag_specs, fn spec ->
      days = Map.get(spec, :evaluation_age_days, 1)
      evaluated_at = DateTime.add(now, -days * 86_400, :second)

      Enum.each(Fixtures.environment_keys(), fn environment_key ->
        seed_evaluation_freshness!(spec.key, environment_key, evaluated_at)
      end)
    end)
  end

  defp seed_evaluation_freshness!(flag_key, environment_key, evaluated_at) do
    from(flag_environment in FlagEnvironment,
      join: flag in assoc(flag_environment, :flag),
      join: environment in assoc(flag_environment, :environment),
      where: flag.key == ^flag_key and environment.key == ^environment_key
    )
    |> Repo.update_all(set: [last_evaluated_at: evaluated_at])
  end

  defp seed_code_references!(now) do
    flag_keys = Enum.map(@flag_specs, & &1.key)

    Repo.delete_all(from(reference in CodeReference, where: reference.flag_key in ^flag_keys))

    Enum.each(@code_reference_specs, fn attrs ->
      %CodeReference{}
      |> CodeReference.changeset(%{
        flag_key: attrs.flag_key,
        file: attrs.file,
        line: attrs.line
      })
      |> Repo.insert!()
    end)

    %ScanReceipt{}
    |> ScanReceipt.changeset(%{
      received_at: now,
      reference_count: length(@code_reference_specs)
    })
    |> Repo.insert!()
  end

  defp archive_seed_flags!(actor) do
    @flag_specs
    |> Enum.filter(&Map.get(&1, :archived?, false))
    |> Enum.each(fn spec ->
      unless archived_flag?(spec.key) do
        {:ok, _archived} =
          Rulestead.archive_flag(
            Command.ArchiveFlag.new(spec.key,
              actor: actor,
              reason: "FleetDesk adoption-lab archived view fixture",
              metadata: @seed_metadata
            )
          )
      end
    end)
  end

  defp archived_seed_flag?(key) do
    Enum.any?(@flag_specs, &(&1.key == key and Map.get(&1, :archived?, false)))
  end

  defp archived_flag?(key) do
    case Repo.get_by(Rulestead.Flag, key: key) do
      %{archived_at: %DateTime{}} -> true
      _flag -> false
    end
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
