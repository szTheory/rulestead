defmodule RulesteadAdmin.Live.FlagLive.RolloutsTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  defmodule DenyWritesPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, :access_admin, _resource, _environment_key), do: true
    def can?(_actor, :list_audit_events, _resource, _environment_key), do: true
    def can?(_actor, _action, _resource, _environment_key), do: false
  end

  defmodule DeniesAuditReadsPolicy do
    @behaviour Rulestead.Admin.Policy

    # Test policy deliberately denies :list_audit_events while keeping rollout reads available.
    def can?(_actor, :access_admin, _resource, _environment_key), do: true
    def can?(_actor, :read_flags, _resource, _environment_key), do: true
    def can?(_actor, :read_rollouts, _resource, _environment_key), do: true
    def can?(_actor, :list_audit_events, _resource, _environment_key), do: false
    def can?(_actor, _action, _resource, _environment_key), do: false
    def change_request_required?(_, _, _, _), do: false
  end

  defmodule DenyAdvanceRolloutPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, :access_admin, _resource, _environment_key), do: true
    def can?(_actor, :list_audit_events, _resource, _environment_key), do: true
    def can?(_actor, :read_flags, _resource, _environment_key), do: true
    def can?(_actor, :read_rollouts, _resource, _environment_key), do: true
    def can?(_actor, :advance_rollout, _resource, _environment_key), do: false
    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  defmodule ProtectedAdvancePolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true

    def change_request_required?(_actor, :advance_rollout, _resource, "prod"), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")
    ensure_environment!("staging", "Staging")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod", "staging"]
    )

    publish_ruleset!("checkout-redesign", "prod")

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "page shows rollout rule context, keeps variant weights locked, and saves draft percentage edits only",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Rollout controls"
    assert html =~ "Owner"
    assert html =~ "growth"
    assert html =~ "Production"
    assert html =~ "Rule 2 of 3"
    assert html =~ "VIP allowlist"
    assert html =~ "Checkout canary"
    assert html =~ "Fallback disabled"
    assert html =~ "Variant weights stay locked on this page"
    assert html =~ "control"
    assert html =~ "80%"
    assert html =~ "treatment"
    assert html =~ "20%"

    changed_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()

    assert changed_html =~ "50%"
    refute changed_html =~ "Draft saved for Production"

    saved_html =
      view
      |> element("button[phx-click='save_draft']")
      |> render_click()

    assert saved_html =~ "Draft saved for Production"

    detail = Rulestead.fetch_flag!("checkout-redesign", "prod")
    [draft | _rest] = detail.draft_rulesets
    rollout_rule = Enum.at(draft.rules, 1)

    assert rollout_rule.rollout.percentage == 50
    assert Enum.map(rollout_rule.variants, & &1.weight) == [80, 20]
    assert detail.active_ruleset.version == 1
    assert Enum.at(detail.active_ruleset.rules, 1).rollout.percentage == 25
  end

  test "preview samples a bounded deterministic set without persisting hidden changes", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    preview_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()
      |> then(fn _html ->
        view
        |> element("button[phx-click='preview']")
        |> render_click()
      end)

    assert preview_html =~ "Sample preview"
    assert preview_html =~ "20 deterministic sample keys"
    assert preview_html =~ "Intended exposure"
    assert preview_html =~ "50%"
    assert preview_html =~ "Observed assignments"
    assert preview_html =~ "Preview only"

    detail = Rulestead.fetch_flag!("checkout-redesign", "prod")

    assert detail.draft_rulesets == []
    assert Enum.at(detail.active_ruleset.rules, 1).rollout.percentage == 25
  end

  test "ordered first-match context stays visible around the rollout rule", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "First-match order"
    assert html =~ "Rule 1"
    assert html =~ "Rule 2"
    assert html =~ "Rule 3"
    assert html =~ "Current rollout rule"
  end

  test "page without rollout rule hides preview action and stays on the mounted workflow", %{conn: conn} do
    seed_flag!(
      key: "maintenance-mode",
      owner: "platform",
      tags: ["ops"],
      description: "Maintenance mode gate",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod"]
    )

    publish_non_rollout_ruleset!("maintenance-mode", "prod")

    {:ok, view, html} = live(conn, "/admin/flags/maintenance-mode/rollouts?env=prod")

    assert html =~ "Rollout controls"
    assert html =~ "No rollout rule is available for this environment."
    refute html =~ ~s(phx-click="preview")
    refute html =~ "Preview sample"

    preview_html = render_click(view, "preview")

    assert preview_html =~ "Rollout controls"
    assert preview_html =~ "No rollout rule is available for this environment."
  end

  test "page shows authored guardrails and latest operational status without raw provider payloads",
       %{
         conn: conn
       } do
    assert {:ok, _status} =
             Rulestead.evaluate_guarded_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-25",
                 monitoring_window_started_at: ~U[2026-04-23 15:50:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 16:00:00Z],
                 signal_facts: [
                   %{
                     signal_key: "checkout_error_rate",
                     status: :failed_closed,
                     reason: :insufficient_sample,
                     threshold_operator: :gte,
                     threshold_value: 0.05,
                     observed_value: 0.07,
                     freshness_window_seconds: 300,
                     sample_size: 42,
                     min_sample_size: 100,
                     evaluated_at: ~U[2026-04-23 15:59:00Z],
                     metadata: %{raw_provider_payload: "provider-secret-rollouts"}
                   }
                 ]
               },
               metadata: %{request_id: "req-rollouts-status", source: :guardrail_automation}
             )

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Guardrail status"
    assert html =~ "checkout_error_rate"
    assert html =~ "Thresholds and evidence"
    assert html =~ "Freshness"
    assert html =~ "Sample"
    assert html =~ "Held"
    assert html =~ "insufficient_sample"
    assert html =~ "0.05"
    assert html =~ "0.07"
    assert html =~ "42"
    assert html =~ "100"
    assert html =~ "[REDACTED]"
    refute html =~ "provider-secret-rollouts"
  end

  test "rollout page shows guardrail intervention excerpt with automatic labels", %{conn: conn} do
    seed_guardrail_hold!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Guardrail interventions"
    assert html =~ "Automatic guardrail hold"
    assert html =~ "Automatic"
    assert html =~ "Open full timeline"
  end

  @tag :auto_advance_label
  test "rollout intervention excerpt labels automatic rollout advance", %{conn: conn} do
    seed_auto_advance_intervention!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Guardrail interventions"
    assert html =~ "Automatic rollout advance"
    assert html =~ "Automatic"
  end

  @tag :auto_advance_panel
  @tag :auto_advance_load
  test "rollout page renders auto-advance panel with unavailable mode when no guardrails", %{
    conn: conn
  } do
    publish_ruleset_without_guardrails!("checkout-redesign", "prod")

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Auto-advance"
    assert html =~ "Wire guardrails on this rollout rule before enabling auto-advance."
    refute html =~ "fleet healthy"
    refute html =~ "metrics dashboard"
  end

  @tag :auto_advance_capability
  test "rollout page hides auto-advance save form when advance_rollout is denied", %{conn: conn} do
    Application.put_env(:rulestead, :admin_policy, DenyAdvanceRolloutPolicy)

    denied_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{
          id: "viewer-1",
          email: "viewer@example.com",
          display: "Viewer",
          roles: ["viewer"]
        },
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, _view, html} = live(denied_conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Auto-advance configuration requires advance permission"
    refute html =~ ~r/phx-submit="save_auto_advance_policy"/
  end

  @tag :auto_advance_protected
  test "protected environment shows change-request callout and still saves auto-advance policy",
       %{conn: conn} do
    Application.put_env(:rulestead, :admin_policy, ProtectedAdvancePolicy)
    seed_healthy_guardrail!()

    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "submits a change request for approval"
    assert html =~ "will not auto-apply"

    saved_html =
      view
      |> form("#auto-advance-form", %{
        "auto_advance" => %{
          "enabled" => "true",
          "observation_window_seconds" => "300",
          "next_stage" => "canary-50",
          "next_percentage" => "50",
          "rule_key" => "checkout-canary"
        }
      })
      |> render_submit()

    assert saved_html =~ "Auto-advance policy saved."

    assert {:ok, %{policy: policy}} =
             Rulestead.fetch_rollout_auto_advance_policy(
               "checkout-redesign",
               "prod",
               "checkout-canary"
             )

    assert policy.enabled == true
    assert policy.observation_window_seconds == 300
    assert policy.next_stage == "canary-50"
    assert policy.next_percentage == 50
  end

  @tag :auto_advance_save
  test "rollout page saves auto-advance policy via direct upsert", %{conn: conn} do
    seed_healthy_guardrail!()
    seed_auto_advance_policy!(false, %{observation_window_seconds: nil, next_stage: nil, next_percentage: nil})

    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Observation window (seconds)"

    saved_html =
      view
      |> form("#auto-advance-form", %{
        "auto_advance" => %{
          "enabled" => "true",
          "observation_window_seconds" => "300",
          "next_stage" => "canary-50",
          "next_percentage" => "50",
          "rule_key" => "checkout-canary"
        }
      })
      |> render_submit()

    assert saved_html =~ "Auto-advance policy saved."
    assert saved_html =~ "300"

    assert {:ok, %{policy: policy}} =
             Rulestead.fetch_rollout_auto_advance_policy(
               "checkout-redesign",
               "prod",
               "checkout-canary"
             )

    assert policy.enabled == true
    assert policy.observation_window_seconds == 300
    assert policy.next_stage == "canary-50"
    assert policy.next_percentage == 50
  end

  @tag :auto_advance_load
  test "rollout page renders auto-advance panel with blocked health copy when guardrails held", %{
    conn: conn
  } do
    seed_guardrail_hold!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Auto-advance"
    assert html =~ "Guardrail automation held this rollout fail-closed"
    refute html =~ "fleet healthy"
    refute html =~ "metrics dashboard"
  end

  test "rollout page hides guardrail intervention excerpt when audit reads are denied", %{
    conn: conn
  } do
    seed_guardrail_hold!()
    Application.put_env(:rulestead, :admin_policy, DeniesAuditReadsPolicy)

    denied_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: "viewer-1", email: "viewer@example.com", roles: []},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, _view, html} = live(denied_conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Rollout controls"
    assert html =~ "Guardrail status"
    refute html =~ "Automatic guardrail hold"
    refute html =~ "source guardrail_automation"
  end

  test "rollout page ignores URL environments outside the mounted session scope", %{conn: conn} do
    publish_ruleset!("checkout-redesign", "staging")
    seed_guardrail_hold!()

    scoped_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin"]},
        "rulestead_admin_last_env" => "staging",
        "rulestead_admin_environments" => [
          %{"key" => "staging", "name" => "Staging"}
        ]
      })

    {:ok, _view, html} = live(scoped_conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Staging"
    assert html =~ "No guardrail decision recorded"
    refute html =~ "Production"
    refute html =~ "Automatic guardrail hold"
  end

  test "page treats missing guardrail status as a prerequisite instead of healthy and preserves guardrails on save",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Guardrail status"
    assert html =~ "checkout_error_rate"
    assert html =~ "No guardrail decision recorded"

    assert html =~
             "This rollout stage has guardrail definitions, but no evaluated decision has been recorded for this environment yet. Wire the host signal provider or run the guarded evaluation before treating the stage as healthy."

    view
    |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
    |> render_change()

    view
    |> element("button[phx-click='save_draft']")
    |> render_click()

    detail = Rulestead.fetch_flag!("checkout-redesign", "prod")
    [draft | _rest] = detail.draft_rulesets
    rollout_rule = Enum.at(draft.rules, 1)

    assert [guardrail] = rollout_rule.rollout.guardrails
    assert guardrail.signal_key == "checkout_error_rate"
    assert guardrail.threshold_operator == :gte
    assert guardrail.threshold_value == 0.05
    assert guardrail.freshness_window_seconds == 300
    assert guardrail.min_sample_size == 100
    assert guardrail.environment_scope == :environment
    assert guardrail.tenant_scope == :required
  end

  test "rollout serializer does not intern dynamic enum strings" do
    source =
      Path.expand("../../../../lib/rulestead_admin/live/flag_live/rollouts.ex", __DIR__)
      |> File.read!()

    refute source =~ "String.to_atom"
    assert source =~ "Map.get(@strategy_atoms, value, value)"
  end

  test "safe next-step publish stays direct and explicit", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    published_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()
      |> then(fn _html ->
        view
        |> element("button[phx-click='publish']")
        |> render_click()
      end)

    assert published_html =~ "Published to Production"
    refute published_html =~ "Risky jump requires confirmation"

    assert Enum.at(Rulestead.fetch_flag!("checkout-redesign", "prod").active_ruleset.rules, 1).rollout.percentage ==
             50
  end

  test "risky jumps block publish until the operator confirms with a reason", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    risky_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "100"}})
      |> render_change()
      |> then(fn _html ->
        view
        |> element("button[phx-click='publish']")
        |> render_click()
      end)

    assert risky_html =~ "Risky jump requires confirmation"
    assert risky_html =~ "Reason for risky jump"
    refute risky_html =~ "Published to Production"

    assert Enum.at(Rulestead.fetch_flag!("checkout-redesign", "prod").active_ruleset.rules, 1).rollout.percentage ==
             25
  end

  test "rollout draft and publish writes fail closed when the current actor lacks permission", %{
    conn: conn
  } do
    Application.put_env(:rulestead, :admin_policy, DenyWritesPolicy)

    denied_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{
          id: "viewer-1",
          email: "viewer@example.com",
          display: "Viewer",
          roles: ["viewer"]
        },
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, view, _html} = live(denied_conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    denied_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()

    refute denied_html =~ ~s(phx-click="save_draft")
    refute denied_html =~ ~s(phx-click="publish")
    assert denied_html =~ "Read"
    assert denied_html =~ "Execute"
    assert denied_html =~ "Propose"

    assert Enum.at(Rulestead.fetch_flag!("checkout-redesign", "prod").active_ruleset.rules, 1).rollout.percentage ==
             25
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
  end

  defp publish_ruleset_without_guardrails!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:no-guardrails",
      rules: [
        %{
          key: "vip-allowlist",
          name: "VIP allowlist",
          strategy: :forced_value,
          value: %{value: true},
          conditions: [
            %{
              attribute: "attributes.segment",
              operator: :equals,
              value: %{equals: "vip"}
            }
          ]
        },
        %{
          key: "checkout-canary",
          name: "Checkout canary",
          strategy: :variant_split,
          conditions: [],
          rollout: %{
            bucket_by: :subject,
            percentage: 25,
            salt: "checkout-canary",
            guardrails: []
          },
          variants: [
            %{key: "control", value: %{value: false}, weight: 80},
            %{key: "treatment", value: %{value: true}, weight: 20}
          ]
        },
        %{
          key: "fallback-disabled",
          name: "Fallback disabled",
          strategy: :forced_value,
          value: %{value: false},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp publish_ruleset!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "vip-allowlist",
          name: "VIP allowlist",
          strategy: :forced_value,
          value: %{value: true},
          conditions: [
            %{
              attribute: "attributes.segment",
              operator: :equals,
              value: %{equals: "vip"}
            }
          ]
        },
        %{
          key: "checkout-canary",
          name: "Checkout canary",
          strategy: :variant_split,
          conditions: [],
          rollout: %{
            bucket_by: :subject,
            percentage: 25,
            salt: "checkout-canary",
            guardrails: [
              %{
                signal_key: "checkout_error_rate",
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
            %{key: "control", value: %{value: false}, weight: 80},
            %{key: "treatment", value: %{value: true}, weight: 20}
          ]
        },
        %{
          key: "fallback-disabled",
          name: "Fallback disabled",
          strategy: :forced_value,
          value: %{value: false},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp publish_non_rollout_ruleset!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:non-rollout",
      rules: [
        %{
          key: "#{flag_key}-enabled",
          name: "Enabled rule",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp seed_auto_advance_policy!(enabled \\ true, overrides \\ []) do
    attrs =
      Map.merge(
        %{
          rule_key: "checkout-canary",
          enabled: enabled,
          observation_window_seconds: 300,
          next_stage: "canary-50",
          next_percentage: 50
        },
        Map.new(overrides)
      )

    assert {:ok, _} =
             Rulestead.upsert_rollout_auto_advance_policy("checkout-redesign", "prod", attrs)
  end

  defp seed_healthy_guardrail! do
    assert {:ok, _status} =
             Rulestead.evaluate_guarded_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-25",
                 monitoring_window_started_at: ~U[2026-04-23 15:50:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 16:00:00Z],
                 signal_facts: [
                   %{
                     signal_key: "checkout_error_rate",
                     status: :healthy,
                     reason: :healthy,
                     threshold_operator: :gte,
                     threshold_value: 0.05,
                     observed_value: 0.01,
                     freshness_window_seconds: 300,
                     sample_size: 100,
                     min_sample_size: 100,
                     evaluated_at: ~U[2026-04-23 15:59:00Z],
                     metadata: %{}
                   }
                 ]
               },
               metadata: %{request_id: "req-rollouts-healthy", source: :guardrail_automation}
             )
  end

  defp seed_auto_advance_intervention! do
    assert {:ok, _manual} =
             Rulestead.advance_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-25",
                 percentage: 25,
                 monitoring_window_started_at: ~U[2026-04-23 15:40:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 15:45:00Z]
               },
               metadata: %{request_id: "req-manual-advance-rollouts", source: :admin_ui}
             )

    auto_command =
      Command.AdvanceRollout.new(
        "checkout-redesign",
        "prod",
        %{
          rule_key: "checkout-canary",
          stage: "canary-40",
          percentage: 40,
          monitoring_window_started_at: ~U[2026-04-23 15:46:00Z],
          monitoring_window_ends_at: ~U[2026-04-23 15:51:00Z]
        },
        metadata: %{
          source: :guardrail_automation,
          request_id: "req-auto-advance-rollouts",
          eligibility: %{
            policy_snapshot: %{
              next_stage: "canary-40",
              next_percentage: 40,
              observation_window_seconds: 300
            }
          }
        }
      )

    assert {:ok, _} = Rulestead.Fake.advance_rollout(auto_command)
  end

  defp seed_guardrail_hold! do
    assert {:ok, _advanced} =
             Rulestead.advance_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-60",
                 percentage: 60,
                 monitoring_window_started_at: ~U[2026-04-23 15:45:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 15:50:00Z]
               },
               metadata: %{request_id: "req-manual-advance", source: :admin_ui}
             )

    assert {:ok, _held} =
             Rulestead.evaluate_guarded_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-60",
                 monitoring_window_started_at: ~U[2026-04-23 15:45:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 15:50:00Z],
                 signal_facts: [
                   %{
                     signal_key: "checkout_error_rate",
                     status: :failed_closed,
                     reason: :insufficient_sample,
                     threshold_operator: :gte,
                     threshold_value: 0.05,
                     observed_value: 0.07,
                     freshness_window_seconds: 300,
                     sample_size: 42,
                     min_sample_size: 100,
                     evaluated_at: ~U[2026-04-23 15:49:00Z],
                     metadata: %{raw_provider_payload: "provider-secret-rollout-hold"}
                   }
                 ]
               },
               metadata: %{request_id: "req-guardrail-held", source: :guardrail_automation}
             )
  end

  defp ensure_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end
end
