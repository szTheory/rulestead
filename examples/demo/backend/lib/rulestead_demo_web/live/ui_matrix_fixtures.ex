defmodule RulesteadDemoWeb.UiMatrixFixtures do
  @moduledoc false

  @long_flag_key "enterprise-checkout-redesign-rollout-experiment-long-key-for-wrapping-proof"
  @long_audience_key "audience:enterprise:regional:vip:long-key-for-matrix-proof"
  @long_reason "Reviewing a production checkout redesign with intentionally long operator rationale, stale guardrail notes, and support-safe audit context for wrapping proof."

  def shell_assigns do
    %{
      breadcrumbs: [
        %{label: "Admin", path: "/admin/flags"},
        %{label: "UI matrix", path: "/dev/rulestead-admin/ui-matrix"}
      ],
      current_environment: %{
        key: "production-eu-central-operations-with-an-intentionally-long-name",
        name: "Production EU Central Operations With An Intentionally Long Name",
        status: :healthy,
        production?: true
      },
      environments: [
        %{key: "development", name: "Development", status: :healthy, production?: false},
        %{
          key: "production-eu-central-operations-with-an-intentionally-long-name",
          name: "Production EU Central Operations With An Intentionally Long Name",
          status: :healthy,
          production?: true
        },
        %{key: "disabled-region", name: "Disabled regional failover", status: :unavailable}
      ],
      env_options: [
        %{
          environment: %{
            key: "development",
            name: "Development",
            status: :healthy,
            production?: false
          },
          href: "/dev/rulestead-admin/ui-matrix?env=development",
          current?: false,
          available?: true,
          tone: "neutral",
          title: "Development fixture scope"
        },
        %{
          environment: %{
            key: "production-eu-central-operations-with-an-intentionally-long-name",
            name: "Production EU Central Operations With An Intentionally Long Name",
            status: :healthy,
            production?: true
          },
          href:
            "/dev/rulestead-admin/ui-matrix?env=production-eu-central-operations-with-an-intentionally-long-name",
          current?: true,
          available?: true,
          tone: "critical",
          title: "Production fixture scope"
        },
        %{
          environment: %{
            key: "disabled-region",
            name: "Disabled regional failover",
            status: :unavailable
          },
          href: "#",
          current?: false,
          available?: false,
          tone: "warning",
          title: "Unavailable fixture example"
        }
      ],
      current_tenant: %{
        key: "tenant-enterprise-regional-long-name",
        name: "Enterprise Regional Tenant With An Intentionally Long Name"
      },
      tenants: [
        %{
          key: "tenant-enterprise-regional-long-name",
          name: "Enterprise Regional Tenant With An Intentionally Long Name"
        },
        %{key: "tenant-read-only", name: "Read-only tenant fixture"}
      ],
      tenant_links: %{
        "tenant-enterprise-regional-long-name" =>
          "/dev/rulestead-admin/ui-matrix?tenant=tenant-enterprise-regional-long-name",
        "tenant-read-only" => "/dev/rulestead-admin/ui-matrix?tenant=tenant-read-only"
      },
      policy_state: %{
        capabilities: %{read?: true, propose?: false, execute?: false, admin?: false},
        denied_reason:
          "Fixture read-only policy: destructive writes are unavailable for this matrix example."
      },
      flash: %{
        info:
          "Fixture-only matrix route; no database, cache, filesystem, environment, or network reads."
      }
    }
  end

  def section_index do
    [
      {"overview-shell", "Overview and shell"},
      {"foundations-reference", "Foundations reference"},
      {"primitives", "Primitives"},
      {"composites", "Composites"},
      {"mutation-flows", "Mutation flows"},
      {"dense-tables", "Dense tables"},
      {"timelines", "Timelines"},
      {"rule-editor", "Rule editor"},
      {"rollout-panels", "Rollout panels"},
      {"command-palette", "Command palette"},
      {"workflow-states", "Workflow states"},
      {"rare-states", "Rare states"},
      {"static-fixtures", "Static fixture links"}
    ]
  end

  def static_fixture_links do
    [
      %{label: "Design system fixture", path: "/rulestead_admin/design-system.html"},
      %{label: "Theme control harness", path: "/rulestead_admin/theme-control-harness.html"},
      %{label: "Theme harness", path: "/rulestead_admin/theme-harness.html"}
    ]
  end

  def route_examples do
    [
      %{label: "Inventory", path: "/admin/flags?env=production-eu-central"},
      %{label: "Rules", path: "/admin/flags/#{@long_flag_key}/rules?env=production-eu-central"},
      %{
        label: "Rollouts",
        path: "/admin/flags/#{@long_flag_key}/rollouts?env=production-eu-central"
      },
      %{
        label: "Timeline and audit",
        path: "/admin/flags/#{@long_flag_key}/timeline?env=production-eu-central"
      },
      %{
        label: "Explain and simulate",
        path: "/admin/flags/#{@long_flag_key}/simulate?env=production-eu-central"
      },
      %{
        label: "Destructive preview",
        path: "/admin/flags/#{@long_flag_key}/kill?env=production-eu-central"
      }
    ]
  end

  def long_flag_key, do: @long_flag_key
  def long_audience_key, do: @long_audience_key
  def long_reason, do: @long_reason

  def dense_records do
    for index <- 1..14 do
      %{
        title: "Dense matrix flag #{index}: #{@long_flag_key}",
        href: "/admin/flags/#{@long_flag_key}-#{index}?env=production-eu-central",
        meta:
          "owner=Checkout Platform Reliability And Release Team #{index} / #{@long_audience_key}",
        tone: if(rem(index, 4) == 0, do: "warning", else: "neutral")
      }
    end
  end

  def audit_entries do
    [
      readable_diff_entry(),
      %{
        id: "audit-rollback-002",
        title: "Rollout held by stale guardrail",
        summary: "Automation held the rollout because host evidence was stale.",
        meta: "2026-06-14 03:10Z / production-eu-central",
        result: :denied,
        occurred_at_iso: "2026-06-14T03:10:00Z",
        occurred_at_label: "03:10 UTC",
        environment_key: "production-eu-central",
        actor_label: "Guardrail automation",
        automatic?: true,
        source_label: "guarded_rollout_auto_advance",
        resource_key: @long_flag_key,
        reason: @long_reason,
        rollback_of_event_id: nil,
        raw: audit_raw("rollout.held")
      },
      %{
        id: "audit-operator-003",
        title: "Operator reviewed denied dependency",
        summary: "A reviewer opened the audience dependency panel in read-only mode.",
        meta: "2026-06-14 03:18Z / production-eu-central",
        result: :ok,
        occurred_at_iso: "2026-06-14T03:18:00Z",
        occurred_at_label: "03:18 UTC",
        environment_key: "production-eu-central",
        actor_label: "Support lead",
        automatic?: false,
        source_label: nil,
        resource_key: @long_flag_key,
        reason: "Read-only audit fixture for denied audience dependency review.",
        rollback_of_event_id: nil,
        raw: audit_raw("audience.reviewed")
      }
    ]
  end

  def readable_diff_entry do
    %{
      id: "audit-diff-001",
      title: "Changed rollout threshold",
      summary: "Production rollout threshold changed after preview.",
      meta: "2026-06-14 03:00Z / production-eu-central",
      result: :ok,
      occurred_at_iso: "2026-06-14T03:00:00Z",
      occurred_at_label: "03:00 UTC",
      environment_key: "production-eu-central",
      actor_label: "Release operator",
      automatic?: false,
      source_label: nil,
      resource_key: @long_flag_key,
      reason: @long_reason,
      rollback_of_event_id: nil,
      show_diff?: true,
      change_label: "Rollout percentage and guardrail fingerprint changed.",
      source_summary: "10% / rs_guardrail_old_fingerprint_for_wrapping",
      proposed_target_summary: "25% / rs_guardrail_new_fingerprint_for_wrapping",
      diff_lines: ["percentage: 10 -> 25", "guardrail: stale -> healthy"],
      raw: audit_raw("rollout.threshold_changed")
    }
  end

  def rule_editor_assigns do
    %{
      detail: %{
        has_draft_ruleset?: true,
        draft_rulesets: [%{version: 8}],
        active_ruleset: %{version: 7}
      },
      editable?: true,
      status_message: "Draft uses fixed matrix fixtures only.",
      error_messages: ["Condition references missing host evidence for #{@long_audience_key}."],
      audiences: [
        %{key: @long_audience_key, description: "Enterprise VIP audience with long wrapping key"},
        %{
          key: "audience:archived:read-only",
          description: "Archived read-only audience",
          archived_at: "2026-06-01T00:00:00Z"
        }
      ],
      rule: %{
        "key" => "rule-long-key-for-enterprise-checkout-redesign",
        "name" => "Enterprise checkout redesign audience rule with long display name",
        "strategy" => "variant_split",
        "audience_key" => @long_audience_key,
        "value" => "true",
        "conditions" => [%{attribute: "account.plan", operator: "equals"}],
        "variants" => [
          %{"key" => "control", "value" => "false", "weight" => 75},
          %{"key" => "redesign", "value" => "true", "weight" => 25}
        ]
      }
    }
  end

  def rollout_assigns do
    %{
      ladder_steps: [0, 1, 5, 10, 25, 50, 100],
      current: 10,
      selected: 25,
      guardrail_definitions: [
        %{
          signal_key: "checkout.error_rate.long.guardrail.signal",
          threshold_operator: "<=",
          threshold_value: 0.02,
          freshness_window_seconds: 900,
          min_sample_size: 1000,
          environment_scope: "production-eu-central",
          tenant_scope: "tenant-enterprise-regional-long-name"
        }
      ],
      guardrail_status: %{
        state: :held,
        state_label: "Held - stale host evidence",
        reason: "host evidence stale for checkout.error_rate.long.guardrail.signal",
        effective_percentage: 10,
        evidence: %{
          signal_key: "checkout.error_rate.long.guardrail.signal",
          threshold_operator: "<=",
          threshold_value: 0.02,
          observed_value: 0.031,
          freshness_window_seconds: 900,
          sample_size: 840,
          min_sample_size: 1000,
          reason: "sample below minimum and stale",
          evaluated_at: "2026-06-14T03:15:00Z"
        },
        window_started_at: "2026-06-14T03:00:00Z",
        window_ends_at: "2026-06-14T03:30:00Z",
        occurred_at: "2026-06-14T03:16:00Z",
        correlation_id: "rollout-correlation-long-fingerprint-for-wrapping-proof"
      }
    }
  end

  def auto_advance_assigns do
    %{
      mode: :blocked_health,
      policy: %{
        enabled: true,
        observation_window_seconds: 1800,
        next_stage: "25_percent",
        next_percentage: 25
      },
      guardrail_status: rollout_assigns().guardrail_status,
      guardrail_definitions: rollout_assigns().guardrail_definitions,
      scheduled_tick: nil,
      protected_callout?: true,
      approval_requirement: %{required?: true, reason: "production environment"},
      can_save?: false,
      capability_denied_reason: "Read-only matrix fixture prevents policy mutation.",
      form_error: "Guardrail evidence unavailable; auto-advance remains blocked.",
      rollout_rule_key: "rule-long-key-for-enterprise-checkout-redesign",
      ladder_steps: rollout_assigns().ladder_steps
    }
  end

  def impact_preview do
    %{
      preview_basis: "authored_state_with_host_evidence",
      preview_fingerprint: "audprev_long_fingerprint_for_matrix_wrapping_proof",
      environment_scope: %{environment_key: "production-eu-central"},
      tenant_scope: %{tenant_key: "tenant-enterprise-regional-long-name"},
      affected_references: [%{reference_key: "flag:#{@long_flag_key}:ruleset:8:rule:vip"}],
      uncertainty: %{
        message:
          "authored state with bounded host-supplied evidence; not an authoritative population count",
        authoritative_population_count?: false
      },
      sample_evidence:
        for index <- 1..11 do
          %{
            actor_key: "actor-enterprise-regional-vip-#{index}",
            targeting_key: "targeting-key-with-long-value-#{index}",
            matched?: rem(index, 3) != 0,
            reason: if(rem(index, 3) == 0, do: "missed_segment", else: "segment_match")
          }
        end,
      impression_evidence: %{
        window_label: "last_24h",
        sampled_impressions: 10_400,
        matched_impressions: 2_750,
        variant_breakdown: [
          %{variant: "control", count: 7_650},
          %{variant: "redesign", count: 2_750}
        ]
      }
    }
  end

  def audience_dependencies do
    %{
      summary: "Dense dependency fixture for #{@long_audience_key}.",
      denied?: false,
      hidden_count: 2,
      entries:
        for index <- 1..12 do
          %{
            environment_key: "production-eu-central",
            tenant_key: "tenant-enterprise-regional-long-name",
            flag_key: "#{@long_flag_key}-#{index}",
            rule_key: "rule-#{index}-long-audience-reference",
            ruleset_version: 8
          }
        end,
      redacted_entries: [%{policy: :denied}, %{policy: :denied}]
    }
  end

  def governance_assessment do
    %{
      verdict: :above_threshold,
      operation: :update,
      reference_count: 12,
      authoritative_population_count?: false,
      preview_fingerprint: "gov_preview_long_fingerprint_for_matrix_wrapping_proof",
      breach_reasons: [
        %{
          code: "reference_limit_exceeded",
          observed: %{reference_keys: Enum.map(1..12, &"#{@long_flag_key}-#{&1}")},
          limit: 2,
          remediation: "Route through change request review."
        },
        %{
          code: "production_requires_review",
          observed: "production-eu-central",
          limit: "direct apply unavailable",
          remediation: "Assign a reviewer before execution."
        },
        %{
          code: "bounded_host_evidence",
          observed: "explicit sample and impression evidence only",
          limit: "not an authoritative population count",
          remediation: "Keep the uncertainty line visible."
        }
      ]
    }
  end

  def simulate_trace do
    %{
      outcome: :variant_redesign,
      rule_traces: [
        %{
          rule_key: "rule-long-key-for-enterprise-checkout-redesign",
          matched?: true,
          audience_trace: %{audience_key: @long_audience_key, matched?: true, reason: :matched},
          conditions: [%{attribute: "account.plan", reason: :matched, actual: "enterprise"}],
          rollout: %{
            bucket_by: "actor-enterprise-regional-vip-1",
            bucket: 24,
            variant_bucket: 8,
            percentage: 25
          }
        },
        %{
          rule_key: "rule-missing-audience-fixture",
          matched?: false,
          audience_trace: %{
            audience_key: "audience:missing:matrix",
            matched?: false,
            reason: :missing
          },
          conditions: [],
          rollout: %{}
        }
      ]
    }
  end

  def audience_trace_steps, do: Map.fetch!(simulate_trace(), :rule_traces)

  def mutation_confirm_variants do
    [
      %{
        title: "Destructive confirmation",
        summary: "Production-scoped archive requires typed key entry before the reason.",
        evidence:
          "Preview destructive fixture: review the scope, type the flag key, record the reason, then archive or return.",
        assigns: mutation_confirm_assigns(:destructive)
      },
      %{
        title: "Unavailable confirmation",
        summary: "Host evidence is stale, so the action is disabled with a safe return path.",
        evidence: "Guardrail evidence is older than the fixture threshold.",
        assigns: mutation_confirm_assigns(:disabled)
      },
      %{
        title: "Read-only confirmation",
        summary: "Policy permits inspection but blocks mutation.",
        evidence:
          "Viewer role can inspect the preview and audit trail but cannot apply the change.",
        assigns: mutation_confirm_assigns(:read_only)
      }
    ]
  end

  def mutation_confirm_assigns(variant) do
    base = %{
      submit_event: "render_destructive_preview",
      submit_label: "Render Destructive Preview",
      reason_value: @long_reason,
      back_href: "/dev/rulestead-admin/ui-matrix#overview-shell",
      back_label: "Return to matrix overview",
      scope: %{
        environment: "production-eu-central",
        tenant: "tenant-enterprise-regional-long-name",
        fingerprint: "confirm_fixture_long_fingerprint_for_matrix_wrapping_proof"
      }
    }

    case variant do
      :destructive ->
        Map.merge(base, %{
          danger?: true,
          submit_label: "Archive fixture flag",
          aria_label: "Confirm destructive fixture action",
          typed_confirmation_label: "Type production flag key",
          typed_confirmation_value: @long_flag_key,
          typed_confirmation_required: true,
          typed_confirmation_help: "Production fixture archive requires the exact flag key."
        })

      :disabled ->
        Map.merge(base, %{
          danger?: false,
          reason_required: false,
          submit_label: "Unavailable fixture action",
          aria_label: "Unavailable fixture action",
          unavailable_reason:
            "Host evidence is stale. Refresh guardrail evidence before mutating."
        })

      :read_only ->
        Map.merge(base, %{
          danger?: false,
          reason_required: false,
          submit_label: "Read-only preview",
          aria_label: "Read-only fixture action",
          read_only?: true,
          read_only_reason: "Actor can inspect this fixture and audit trail but cannot mutate it."
        })

      _normal ->
        base
    end
  end

  def rare_state_examples do
    [
      %{
        state: :empty,
        label: "No matrix examples match this section",
        summary: "Valid empty fixture state."
      },
      %{
        state: :loading,
        label: "Loading host evidence",
        summary: "Pending async state with no mutation allowed."
      },
      %{
        state: :error,
        label: "Matrix fixture failed to render",
        summary: "Inspect the named fixture helper."
      },
      %{
        state: :permission_denied,
        label: "Permission denied",
        summary: "Actor can preview but not mutate."
      },
      %{
        state: :read_only,
        label: "Read-only archived record",
        summary: "Navigation remains available."
      },
      %{
        state: :unavailable,
        label: "Host evidence unavailable",
        summary: "Action is disabled with explanation."
      },
      %{
        state: :focus,
        label: "Keyboard focus target",
        summary: "Stable target for focus assertions."
      },
      %{
        state: :destructive,
        label: "Destructive action",
        summary: "Preview, confirm, audit handoff."
      }
    ]
  end

  defp audit_raw(event_type) do
    %{
      event: %{
        event_type: event_type,
        flag_key: @long_flag_key,
        audience_key: @long_audience_key,
        reason: @long_reason
      },
      payload: %{
        before: %{"percentage" => 10, "guardrail" => "stale"},
        after: %{"percentage" => 25, "guardrail" => "healthy"}
      }
    }
  end
end
