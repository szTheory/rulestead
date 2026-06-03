defmodule RulesteadDemo.Seeds do
  @moduledoc """
  Idempotent FleetDesk adoption-lab seed data.

  Exercises boolean rollout, variant copy, JSON remote config, guarded rollout,
  audience preview, and the primary kill-switch flag used by compose smoke +
  Playwright proofs.
  """

  import Ecto.Query

  alias Rulestead.AuditEvent
  alias Rulestead.Analytics.{Event, EventMapper}
  alias Rulestead.Audience
  alias Rulestead.CodeRefs.{CodeReference, ScanReceipt}
  alias Rulestead.FlagEnvironment
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.GuardrailDecision
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
    },
    %{
      key: "night-shift-dispatchers",
      description:
        "Draft cohort scoping the after-hours dispatch desk. Still under review, so it is not yet wired into any flag rule.",
      definition: %{
        conditions: [
          %{attribute: "plan", operator: "in", value: ["pro", "enterprise"]},
          %{attribute: "shift", operator: "eq", value: "night"}
        ]
      }
    },
    %{
      key: "legacy-eta-beta-fleet",
      description:
        "Retired beta cohort that previewed the legacy ETA wording experiment. Archived once route-eta-legacy was retired.",
      definition: %{
        conditions: [%{attribute: "tenant", operator: "eq", value: "beta-fleet"}]
      },
      archived?: true
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
    },
    %{
      key: "dispatch-kill-switch",
      description:
        "Standing kill switch that instantly forces all dispatch traffic back onto the safe legacy router. SREs engage it in production during incidents so the new routing path can be cut over in one click.",
      flag_type: :kill_switch,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "platform-team",
      tags: ["demo", "adoption-lab", "kill-switch"],
      ruleset: %{
        salt: "dispatch-kill-switch:fleetdesk:v1",
        rules: [
          %{
            key: "incident-cutover",
            name: "Force safe legacy routing during incidents",
            strategy: :forced_value,
            value: %{value: true},
            conditions: []
          }
        ]
      }
    },
    %{
      key: "dispatcher-only-access",
      description:
        "Permission gate that limits the live route-override console to verified dispatchers. Targets the Pro-plan dispatcher audience so non-dispatch roles never see the override controls.",
      flag_type: :permission,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "platform-team",
      tags: ["demo", "adoption-lab", "permission"],
      ruleset: %{
        salt: "dispatcher-only-access:fleetdesk:v1",
        rules: [
          %{
            key: "dispatchers-only",
            name: "Verified dispatchers only",
            strategy: :segment_match,
            audience_key: "fleet-ops-dispatchers",
            value: %{value: true},
            conditions: []
          }
        ]
      }
    },
    %{
      key: "route-solver-migration",
      description:
        "Migrates the route solver from the legacy nearest-neighbor heuristic to the v2 constraint solver. Staging already serves the v2 solver while production stays on the legacy path, giving Compare a real cross-environment difference to promote.",
      flag_type: :migration,
      value_type: :string,
      default_value: %{value: "legacy-solver"},
      owner: "maps-team",
      tags: ["demo", "adoption-lab", "migration"],
      ruleset: %{
        salt: "route-solver-migration:fleetdesk:v1",
        rules: [
          %{
            key: "v2-solver-cutover",
            name: "Route solver v2 cutover",
            strategy: :forced_value,
            value: %{value: "v2-solver"},
            conditions: []
          }
        ]
      },
      production_ruleset: %{
        salt: "route-solver-migration:fleetdesk:v1",
        rules: [
          %{
            key: "legacy-solver-hold",
            name: "Hold on legacy solver in production",
            strategy: :forced_value,
            value: %{value: "legacy-solver"},
            conditions: []
          }
        ]
      }
    },
    %{
      key: "dispatch-queue-throttle",
      description:
        "Operational throttle that caps how many concurrent route assignments the dispatch queue worker drains per tick. Ops tunes the integer ceiling to protect downstream routing during traffic spikes.",
      flag_type: :operational,
      value_type: :integer,
      default_value: %{value: 25},
      owner: "ops-team",
      tags: ["demo", "adoption-lab", "operational"],
      ruleset: %{
        salt: "dispatch-queue-throttle:fleetdesk:v1",
        rules: [
          %{
            key: "spike-throttle",
            name: "Throttle drain rate during spikes",
            strategy: :forced_value,
            value: %{value: 10},
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
    seed_governance_workflows!(actor, now)
    seed_scheduled_execution_states!(actor, now)
    seed_guardrail_decisions!(now)
    seed_experiment_analytics!(now)
    archive_seed_flags!(actor)
    engage_production_kill_switch!(actor)
    seed_audit_timelines!(actor, now)
    refresh_runtime!()

    IO.puts(
      "Seeded FleetDesk adoption lab: #{length(@flag_specs)} flags across #{inspect(Fixtures.environment_keys())}."
    )

    :ok
  end

  defp ensure_audience!(%{key: key} = spec) do
    archived_at = audience_archived_at(spec)

    case Repo.get_by(Audience, key: key) do
      %Audience{} = audience ->
        audience
        |> Audience.changeset(%{
          description: spec.description,
          definition: spec.definition,
          archived_at: archived_at || audience.archived_at
        })
        |> Repo.update!()

        :ok

      nil ->
        %Audience{}
        |> Audience.changeset(%{
          key: key,
          description: spec.description,
          definition: spec.definition,
          archived_at: archived_at
        })
        |> Repo.insert!()

        :ok
    end
  end

  defp audience_archived_at(spec) do
    if Map.get(spec, :archived?, false) do
      DateTime.utc_now()
      |> DateTime.add(-5 * 86_400, :second)
      |> DateTime.truncate(:microsecond)
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

  defp publish_ruleset!(%{key: key} = spec, actor) do
    if archived_seed_flag?(key) and archived_flag?(key) do
      :ok
    else
      do_publish_ruleset!(spec, actor)
    end
  end

  defp do_publish_ruleset!(%{key: key, ruleset: ruleset} = spec, actor) do
    production_ruleset = Map.get(spec, :production_ruleset, ruleset)

    Enum.each(Fixtures.environment_keys(), fn environment_key ->
      # Republishing resets an engaged kill switch back to active, which would
      # make the standing production kill-switch fixture non-idempotent. Skip any
      # environment that is currently killswitched so the override survives reruns.
      unless killswitched?(key, environment_key) do
        environment_ruleset =
          if environment_key == "production", do: production_ruleset, else: ruleset

        {:ok, _draft} =
          Rulestead.save_draft_ruleset(
            Command.SaveDraftRuleset.new(key, environment_key, environment_ruleset,
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
      end
    end)
  end

  defp seed_audit_timelines!(actor, now) do
    seed_archived_banner_timeline!(actor, now)
    seed_kill_switch_timeline!(actor)
    seed_guardrail_timeline!(actor, now)
    seed_denied_audience_preview!(actor, now)
    seed_rollout_rollback_timeline!(actor, now)
    seed_change_request_rollback_timeline!(actor, now)
  end

  # rollback_audit_event/2 only inverts kill-switch engage/release events, so the
  # rollout- and change-request-rollback timelines are authored directly as linked
  # inverse audit events with before/after + diff so the timeline diff cards render.
  defp seed_rollout_rollback_timeline!(actor, now) do
    flag_key = "fleet-map-v2"
    environment_key = "production"
    advance_request_id = seed_request_id(flag_key, environment_key, "rollout.advance:v1")
    rollback_request_id = seed_request_id(flag_key, environment_key, "rollout.rollback:v1")
    occurred_at = DateTime.add(now, -1_800, :second)

    seed_rollout_advance_event!(flag_key, environment_key, actor, advance_request_id, occurred_at)
    advance_event = find_seed_audit_event!(advance_request_id)

    ensure_seed_audit_event!(%{
      event_type: "rollout.advance",
      resource_key: flag_key,
      environment_key: environment_key,
      actor: actor,
      reason: "Rolled back the 75% ramp after client crash rate ticked up during validation.",
      correlation_id: rollback_request_id,
      occurred_at: DateTime.add(occurred_at, 900, :second),
      metadata: %{
        request_id: rollback_request_id,
        scenario: "rollout.rollback:v1",
        rollback_of_event_id: advance_event.id,
        links: %{"inverse_event_type" => "rollout.advance"},
        before: %{
          "status" => "active",
          "rules" => [%{"key" => "pro-percentage-rollout", "position" => 2, "percentage" => 75}]
        },
        after: %{
          "status" => "active",
          "rules" => [%{"key" => "pro-percentage-rollout", "position" => 2, "percentage" => 50}]
        },
        diff: %{
          "rollout_percentage" => %{"from" => 75, "to" => 50}
        }
      }
    })
  end

  defp seed_rollout_advance_event!(flag_key, environment_key, actor, request_id, occurred_at) do
    ensure_seed_audit_event!(%{
      event_type: "rollout.advance",
      resource_key: flag_key,
      environment_key: environment_key,
      actor: actor,
      reason: "Widened the Pro-plan rollout to 75% during the release window.",
      correlation_id: request_id,
      occurred_at: occurred_at,
      metadata: %{
        request_id: request_id,
        scenario: "rollout.advance:v1",
        before: %{
          "status" => "active",
          "rules" => [%{"key" => "pro-percentage-rollout", "position" => 2, "percentage" => 50}]
        },
        after: %{
          "status" => "active",
          "rules" => [%{"key" => "pro-percentage-rollout", "position" => 2, "percentage" => 75}]
        },
        diff: %{
          "rollout_percentage" => %{"from" => 50, "to" => 75}
        }
      }
    })
  end

  defp seed_change_request_rollback_timeline!(actor, now) do
    flag_key = "ops-banner-config"
    environment_key = "staging"
    merge_request_id = seed_request_id(flag_key, environment_key, "change_request.executed:v1")

    rollback_request_id =
      seed_request_id(flag_key, environment_key, "change_request.rollback:v1")

    merge_event = find_change_request_merge_event(merge_request_id)

    if merge_event do
      ensure_seed_audit_event!(%{
        event_type: "change_request.rollback",
        resource_key: flag_key,
        environment_key: environment_key,
        actor: actor,
        reason:
          "Reverted the merged banner publish after ops flagged the advisory copy as premature.",
        correlation_id: rollback_request_id,
        occurred_at: DateTime.add(now, -600, :second),
        metadata: %{
          request_id: rollback_request_id,
          scenario: "change_request.rollback:v1",
          rollback_of_event_id: merge_event.id,
          change_request_id: merge_event.metadata["change_request_id"],
          links: %{"inverse_event_type" => "change_request.merged"},
          before: %{
            "status" => "active",
            "rules" => [%{"key" => "winter-storm-banner", "position" => 1}]
          },
          after: %{
            "status" => "active",
            "rules" => [%{"key" => "winter-storm-banner", "position" => 1}]
          },
          diff: %{
            "banner_severity" => %{"from" => "warning", "to" => "info"},
            "banner_message" => %{
              "from" => "Winter storm advisory — review reroute playbook.",
              "to" => nil
            }
          }
        }
      })
    end
  end

  defp find_change_request_merge_event(correlation_id) do
    from(event in AuditEvent,
      where:
        event.correlation_id == ^correlation_id and event.event_type == "change_request.merged",
      limit: 1
    )
    |> Repo.one()
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

  defp seed_governance_workflows!(actor, now) do
    reviewer = %{
      "id" => "reviewer:ops-lead",
      "type" => "operator",
      "display" => "Maya Ops",
      "roles" => ["admin"]
    }

    pending =
      ensure_seed_change_request!(%{
        action: :publish_ruleset,
        flag_key: "ops-banner-config",
        environment_key: "production",
        actor: actor,
        reason: "Update storm advisory copy before the Northeast weather window.",
        request_id:
          seed_request_id("ops-banner-config", "production", "change_request.pending:v1"),
        command: %{
          "diff" => %{
            "title" => "Ops banner advisory copy",
            "summary" => "Promote the warning copy and playbook CTA from staging to production."
          },
          "tenant_key" => "acme-logistics"
        },
        approval_requirement:
          approval_requirement(:publish_ruleset, "production",
            required_approvals: 1,
            self_approval_allowed?: false
          )
      })

    _pending = pending

    scheduled =
      ensure_seed_change_request!(%{
        action: :publish_ruleset,
        flag_key: "fleet-map-v2",
        environment_key: "production",
        actor: actor,
        reason: "Advance Fleet Map v2 during the low-traffic release window.",
        request_id: seed_request_id("fleet-map-v2", "production", "change_request.scheduled:v1"),
        command: %{
          "diff" => %{
            "title" => "Fleet Map v2 staged production rollout",
            "summary" => "Promote the reviewed 50% Pro-plan rollout from staging."
          },
          "tenant_key" => "acme-logistics"
        },
        approval_requirement:
          approval_requirement(:publish_ruleset, "production",
            required_approvals: 1,
            self_approval_allowed?: false
          )
      })

    if scheduled && change_request_state(scheduled) == "submitted" do
      {:ok, %{change_request: _approved_change_request}} =
        Rulestead.approve_change_request(
          Command.ApproveChangeRequest.new(scheduled.id,
            actor: reviewer,
            reason: "Guardrail and preview evidence checked for the release window.",
            metadata:
              seed_command_metadata(
                scheduled.correlation_id,
                "change_request.scheduled.approve:v1"
              )
          )
        )
    end

    if scheduled && change_request_state(scheduled) in ["submitted", "approved"] do
      scheduled_for = DateTime.add(now, 7_200, :second) |> DateTime.truncate(:microsecond)

      _ =
        Rulestead.schedule_change_request(
          Command.ScheduleChangeRequest.new(%{
            change_request_id: scheduled.id,
            scheduled_for: scheduled_for,
            actor: reviewer,
            reason: "Queue for the next release window.",
            metadata:
              seed_command_metadata(
                scheduled.correlation_id,
                "change_request.scheduled.queue:v1"
              )
          })
        )
    end

    ensure_seed_direct_schedule!(%{
      action: :engage_kill_switch,
      flag_key: "enable-new-dashboard",
      environment_key: "production",
      actor: actor,
      scheduled_for: DateTime.add(now, 3_600, :second) |> DateTime.truncate(:microsecond),
      reason: "Pre-authorized rollback drill for dispatch latency response.",
      request_id:
        seed_request_id("enable-new-dashboard", "production", "scheduled.kill_switch:v1"),
      command: %{
        "flag_key" => "enable-new-dashboard",
        "environment_key" => "production",
        "tenant_key" => "acme-logistics"
      },
      approval_requirement:
        approval_requirement(:engage_kill_switch, "production",
          required_approvals: 0,
          self_approval_allowed?: true,
          change_request_required?: false
        )
    })

    seed_rejected_change_request!(actor, reviewer)
    seed_executed_change_request!(actor, reviewer)
  end

  defp seed_rejected_change_request!(actor, reviewer) do
    rejected =
      ensure_seed_change_request!(%{
        action: :publish_ruleset,
        flag_key: "dispatch-ops-copy",
        environment_key: "production",
        actor: actor,
        reason: "Promote the urgent-routes headline copy to production.",
        request_id:
          seed_request_id("dispatch-ops-copy", "production", "change_request.rejected:v1"),
        command: %{
          "diff" => %{
            "title" => "Dispatch ops headline copy",
            "summary" => "Ship the urgent-routes experiment winner to production."
          },
          "tenant_key" => "acme-logistics"
        },
        approval_requirement:
          approval_requirement(:publish_ruleset, "production",
            required_approvals: 1,
            self_approval_allowed?: false
          )
      })

    if rejected && change_request_state(rejected) == "submitted" do
      {:ok, %{change_request: _rejected}} =
        Rulestead.reject_change_request(
          Command.RejectChangeRequest.new(rejected.id,
            actor: reviewer,
            reason:
              "Holding promotion — the experiment has not cleared the significance bar yet, revisit after the next read.",
            metadata:
              seed_command_metadata(rejected.correlation_id, "change_request.rejected.review:v1")
          )
        )
    end

    :ok
  end

  defp seed_executed_change_request!(actor, reviewer) do
    request_id = seed_request_id("ops-banner-config", "staging", "change_request.executed:v1")

    # Executing a publish_ruleset change request requires a publishable draft to
    # exist. Stage one (idempotently) before submitting so the merge can run.
    unless fetch_seed_change_request(request_id) do
      ops_banner_spec = Enum.find(@flag_specs, &(&1.key == "ops-banner-config"))

      {:ok, _draft} =
        Rulestead.save_draft_ruleset(
          Command.SaveDraftRuleset.new(
            "ops-banner-config",
            "staging",
            ops_banner_spec.ruleset,
            actor: actor,
            metadata: seed_command_metadata(request_id, "change_request.executed.draft:v1")
          )
        )
    end

    executed =
      ensure_seed_change_request!(%{
        action: :publish_ruleset,
        flag_key: "ops-banner-config",
        environment_key: "staging",
        actor: actor,
        reason: "Republish the reviewed storm advisory payload in staging.",
        request_id: request_id,
        command: %{
          "diff" => %{
            "title" => "Ops banner advisory copy",
            "summary" => "Republish the reviewed warning payload in staging."
          },
          "tenant_key" => "acme-logistics"
        },
        approval_requirement:
          approval_requirement(:publish_ruleset, "staging",
            required_approvals: 1,
            self_approval_allowed?: false
          )
      })

    if executed && change_request_state(executed) == "submitted" do
      {:ok, %{change_request: _approved}} =
        Rulestead.approve_change_request(
          Command.ApproveChangeRequest.new(executed.id,
            actor: reviewer,
            reason: "Advisory copy reviewed for staging republish.",
            metadata:
              seed_command_metadata(executed.correlation_id, "change_request.executed.approve:v1")
          )
        )
    end

    executed = executed && fetch_seed_change_request(executed.correlation_id)

    if executed && change_request_state(executed) == "approved" do
      {:ok, %{change_request: _executed}} =
        Rulestead.execute_change_request(
          Command.ExecuteChangeRequest.new(executed.id,
            actor: reviewer,
            reason: "Executed during the staging release window.",
            metadata:
              seed_command_metadata(executed.correlation_id, "change_request.executed.merge:v1")
          )
        )
    end

    :ok
  end

  defp ensure_seed_change_request!(attrs) do
    request_id = Map.fetch!(attrs, :request_id)

    case fetch_seed_change_request(request_id) do
      nil ->
        {:ok, %{change_request: change_request}} =
          Rulestead.submit_change_request(
            Command.SubmitChangeRequest.new(
              %{
                action: Map.fetch!(attrs, :action),
                environment_key: Map.fetch!(attrs, :environment_key),
                resource_type: "flag",
                resource_key: Map.fetch!(attrs, :flag_key),
                command: Map.fetch!(attrs, :command),
                approval_requirement: Map.fetch!(attrs, :approval_requirement)
              },
              actor: Map.fetch!(attrs, :actor),
              reason: Map.fetch!(attrs, :reason),
              metadata: seed_command_metadata(request_id, "change_request.seed:v1")
            )
          )

        change_request

      change_request ->
        change_request
    end
  end

  defp change_request_state(change_request) do
    change_request[:status] || change_request[:state] |> to_string()
  end

  defp fetch_seed_change_request(request_id) do
    from(change_request in "change_requests",
      where: field(change_request, :correlation_id) == ^request_id,
      select: %{
        # Load id/status as their canonical types. A schemaless `field/2` returns the
        # raw 16-byte uuid binary, which loses its null byte when reused as a command
        # change_request_id (→ Postgrex "expected 16 bytes" errors ~6% of the time).
        id: type(field(change_request, :id), Ecto.UUID),
        status: field(change_request, :status),
        correlation_id: field(change_request, :correlation_id)
      }
    )
    |> Repo.one()
  end

  defp ensure_seed_direct_schedule!(attrs) do
    request_id = Map.fetch!(attrs, :request_id)

    unless seed_scheduled_execution_exists?(request_id) do
      _ =
        Rulestead.schedule_governed_action(
          Command.ScheduleGovernedAction.new(%{
            action: Map.fetch!(attrs, :action),
            environment_key: Map.fetch!(attrs, :environment_key),
            resource_type: "flag",
            resource_key: Map.fetch!(attrs, :flag_key),
            command: Map.fetch!(attrs, :command),
            scheduled_for: Map.fetch!(attrs, :scheduled_for),
            execution_mode: :emergency_bypass,
            actor: Map.fetch!(attrs, :actor),
            reason: Map.fetch!(attrs, :reason),
            approval_requirement: Map.fetch!(attrs, :approval_requirement),
            metadata: seed_command_metadata(request_id, "scheduled_execution.seed:v1"),
            idempotency_key: "seed:#{request_id}"
          })
        )
    end
  end

  defp seed_scheduled_execution_exists?(request_id) do
    from(scheduled_execution in "scheduled_executions",
      where: field(scheduled_execution, :correlation_id) == ^request_id,
      select: count()
    )
    |> Repo.one()
    |> then(&(&1 > 0))
  end

  defp seed_scheduled_execution_states!(actor, now) do
    naive_now = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    [
      %{
        state: "running",
        flag_key: "fleet-map-v2",
        environment_key: "production",
        scheduled_for: DateTime.add(now, -60, :second),
        failure_reason: nil,
        attempt_count: 1,
        reason: "Promoting the reviewed Fleet Map v2 rollout during the release window.",
        scenario: "scheduled_execution.running:v1"
      },
      %{
        state: "failed",
        flag_key: "dispatch-guarded-rollout",
        environment_key: "production",
        scheduled_for: DateTime.add(now, -3_600, :second),
        failure_reason:
          "Guardrail dispatch_error_rate breached threshold during execution; publish aborted fail-closed.",
        attempt_count: 3,
        reason: "Advance the priority-route split after the observation window.",
        scenario: "scheduled_execution.failed:v1"
      },
      %{
        state: "quarantined",
        flag_key: "ops-banner-config",
        environment_key: "production",
        scheduled_for: DateTime.add(now, -7_200, :second),
        failure_reason:
          "Quarantined after repeated execution failures; awaiting operator requeue decision.",
        attempt_count: 5,
        reason: "Publish the storm advisory payload ahead of the weather window.",
        scenario: "scheduled_execution.quarantined:v1"
      }
    ]
    |> Enum.each(fn entry ->
      request_id = seed_request_id(entry.flag_key, entry.environment_key, entry.scenario)

      unless seed_scheduled_execution_exists?(request_id) do
        insert_seed_scheduled_execution!(entry, actor, request_id, naive_now)
      end
    end)

    :ok
  end

  defp insert_seed_scheduled_execution!(entry, actor, request_id, naive_now) do
    scheduled_for =
      entry.scheduled_for |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    Repo.insert_all("scheduled_executions", [
      %{
        state: entry.state,
        governed_action: "publish_ruleset",
        environment_key: entry.environment_key,
        resource_type: "flag",
        resource_key: entry.flag_key,
        execution_mode: "change_request",
        scheduled_by_id: actor_value(actor, "id") || "demo-operator",
        scheduled_by_type: actor_value(actor, "type") || "operator",
        scheduled_by_display: actor_value(actor, "display"),
        approved_by_snapshot: [],
        execution_metadata: %{"reason" => entry.reason},
        scheduled_for: scheduled_for,
        attempt_count: entry.attempt_count,
        failure_reason: entry.failure_reason,
        command_snapshot: %{
          "flag_key" => entry.flag_key,
          "environment_key" => entry.environment_key,
          "tenant_key" => "acme-logistics"
        },
        approval_requirement_snapshot: %{},
        metadata: %{
          "seed" => @seed_name,
          "seed_version" => @seed_version,
          "scenario" => entry.scenario,
          "request_id" => request_id
        },
        correlation_id: request_id,
        idempotency_key: "seed:#{request_id}",
        inserted_at: naive_now,
        updated_at: naive_now
      }
    ])
  end

  defp seed_guardrail_decisions!(now) do
    base_time = DateTime.add(now, -2_700, :second) |> DateTime.truncate(:microsecond)

    [
      %{
        flag_key: "dispatch-guarded-rollout",
        environment_key: "staging",
        rule_key: "priority-routes-split",
        stage: "treatment-50",
        decision_state: :healthy,
        action_type: :evaluate,
        decision_reason: "Dispatch error rate within threshold; stage healthy.",
        effective_percentage: 50,
        observed_value: 0.031,
        occurred_at: base_time,
        scenario: "guardrail_decision.healthy:v1"
      },
      %{
        flag_key: "dispatch-guarded-rollout",
        environment_key: "production",
        rule_key: "priority-routes-split",
        stage: "treatment-50",
        decision_state: :held,
        action_type: :hold,
        decision_reason:
          "Dispatch error rate crossed the rollout hold threshold; advancement paused awaiting operator decision.",
        effective_percentage: 50,
        observed_value: 0.057,
        occurred_at: DateTime.add(base_time, 900, :second),
        scenario: "guardrail_decision.held:v1"
      },
      %{
        flag_key: "fleet-map-v2",
        environment_key: "production",
        rule_key: "pro-percentage-rollout",
        stage: "full-100",
        decision_state: :healthy,
        action_type: :advance,
        decision_reason: "Crash rate stable across the full rollout; ramp completed at 100%.",
        effective_percentage: 100,
        observed_value: 0.004,
        occurred_at: DateTime.add(base_time, 1_200, :second),
        scenario: "guardrail_decision.completed:v1"
      }
    ]
    |> Enum.each(fn decision ->
      request_id =
        seed_request_id(decision.flag_key, decision.environment_key, decision.scenario)

      unless seed_guardrail_decision_exists?(request_id) do
        insert_seed_guardrail_decision!(decision, request_id)
      end
    end)

    :ok
  end

  defp seed_guardrail_decision_exists?(correlation_id) do
    from(decision in GuardrailDecision,
      where: decision.correlation_id == ^correlation_id,
      select: count()
    )
    |> Repo.one()
    |> then(&(&1 > 0))
  end

  defp insert_seed_guardrail_decision!(decision, request_id) do
    window_started = DateTime.add(decision.occurred_at, -300, :second)

    %GuardrailDecision{}
    |> GuardrailDecision.changeset(%{
      flag_key: decision.flag_key,
      environment_key: decision.environment_key,
      rule_key: decision.rule_key,
      stage: decision.stage,
      tenant_key: "acme-logistics",
      decision_state: decision.decision_state,
      action_type: decision.action_type,
      decision_reason: decision.decision_reason,
      effective_percentage: decision.effective_percentage,
      rollout_salt: "#{decision.flag_key}:split",
      monitoring_window_started_at: window_started,
      monitoring_window_ends_at: decision.occurred_at,
      occurred_at: decision.occurred_at,
      guardrail_evidence: %{
        "signal_key" => "dispatch_error_rate",
        "status" => guardrail_evidence_status(decision.decision_state),
        "reason" => decision.decision_reason,
        "threshold_operator" => "gte",
        "threshold_value" => 0.05,
        "observed_value" => decision.observed_value,
        "freshness_window_seconds" => 300,
        "sample_size" => 148,
        "min_sample_size" => 100,
        "evaluated_at" => DateTime.to_iso8601(decision.occurred_at)
      },
      correlation_id: request_id,
      metadata: %{
        "seed" => @seed_name,
        "seed_version" => @seed_version,
        "scenario" => decision.scenario,
        "request_id" => request_id
      }
    })
    |> Repo.insert!()
  end

  defp guardrail_evidence_status(:healthy), do: "healthy"
  defp guardrail_evidence_status(_state), do: "breached"

  defp approval_requirement(action, environment_key, opts) do
    opts
    |> Keyword.put(:action, action)
    |> Keyword.put(:environment_key, environment_key)
    |> Keyword.put_new(:required_approvals, 1)
    |> Keyword.put_new(:change_request_required?, true)
    |> Keyword.put_new(:self_approval_allowed?, false)
    |> ApprovalRequirement.new()
  end

  defp seed_experiment_analytics!(now) do
    Repo.delete_all(
      from(event in Event,
        where: fragment("?->>'seed' = ?", event.metadata, ^@seed_name)
      )
    )

    events =
      []
      |> add_experiment_sample(
        "dispatch-ops-copy",
        "staging",
        "Standard dispatch queue",
        220,
        34,
        now
      )
      |> add_experiment_sample(
        "dispatch-ops-copy",
        "staging",
        "Prioritize urgent routes first.",
        218,
        48,
        now
      )
      |> add_experiment_sample(
        "dispatch-guarded-rollout",
        "production",
        "standard-route",
        310,
        52,
        now
      )
      |> add_experiment_sample(
        "dispatch-guarded-rollout",
        "production",
        "priority-route",
        305,
        67,
        now
      )

    events
    |> Enum.map(&EventMapper.to_insert_map/1)
    |> then(fn rows -> if rows == [], do: :ok, else: Repo.insert_all(Event, rows) end)
  end

  defp add_experiment_sample(
         events,
         flag_key,
         environment_key,
         value,
         exposures,
         conversions,
         now
       ) do
    subject_prefix = "#{flag_key}:#{environment_key}:#{value}"

    exposure_events =
      for index <- 1..exposures do
        subject_id = "#{subject_prefix}:#{index}"

        %{
          kind: "exposure",
          actor_id: subject_id,
          env: environment_key,
          metadata: %{
            "seed" => @seed_name,
            "seed_version" => @seed_version,
            "flag_key" => flag_key,
            "value" => value
          },
          occurred_at: DateTime.add(now, -index * 45, :second)
        }
      end

    conversion_events =
      for index <- 1..conversions do
        %{
          kind: "custom",
          actor_id: "#{subject_prefix}:#{index}",
          env: environment_key,
          event_name: "conversion",
          metadata: %{
            "seed" => @seed_name,
            "seed_version" => @seed_version,
            "flag_key" => flag_key,
            "value" => value
          },
          occurred_at: DateTime.add(now, -index * 41, :second)
        }
      end

    events ++ exposure_events ++ conversion_events
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

  defp engage_production_kill_switch!(actor) do
    flag_key = "dispatch-kill-switch"
    environment_key = "production"

    request_id = seed_request_id(flag_key, environment_key, "kill_switch.engage:v1")

    if not killswitched?(flag_key, environment_key) and
         not seed_kill_switch_engaged_before?(flag_key, environment_key) do
      {:ok, _flag} =
        Rulestead.engage_kill_switch(
          flag_key,
          environment_key,
          actor,
          reason:
            "Production incident drill — dispatch traffic forced back onto the safe legacy router.",
          metadata: seed_command_metadata(request_id, "kill_switch.engage:v1")
        )
    end

    :ok
  end

  defp seed_kill_switch_engaged_before?(flag_key, environment_key) do
    from(event in AuditEvent,
      where:
        event.resource_key == ^flag_key and event.environment_key == ^environment_key and
          event.event_type == "kill_switch.engage",
      select: count()
    )
    |> Repo.one()
    |> then(&(&1 > 0))
  end

  defp killswitched?(flag_key, environment_key) do
    from(flag_environment in FlagEnvironment,
      join: flag in assoc(flag_environment, :flag),
      join: environment in assoc(flag_environment, :environment),
      where:
        flag.key == ^flag_key and environment.key == ^environment_key and
          flag_environment.status == :killswitched,
      select: count()
    )
    |> Repo.one()
    |> then(&(&1 > 0))
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
