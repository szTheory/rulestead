defmodule RulesteadAdmin.Live.FlagLive.TimelineTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy
    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  defmodule DenyPolicy do
    @behaviour Rulestead.Admin.Policy
    def can?(_actor, _action, _resource, _environment_key), do: false
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

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
    seed_flag!()
    publish_ruleset!("checkout-redesign", "prod")

    assert {:ok, _} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "incident"
             )

    Application.put_env(:rulestead, :admin_policy, DenyPolicy)

    assert {:error, %Rulestead.Error{type: :unauthorized}} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "viewer-1", display: "Viewer", roles: [:viewer]},
               reason: "denied attempt"
             )

    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin", "auditor"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "per-flag timeline shows reverse-chronological redacted rows and appends rollback as a linked event",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Kill switch engage denied"
    assert html =~ "Kill switch engaged"
    assert html =~ "Request was denied. No serving change was applied."
    assert html =~ "History for this flag in the selected environment."
    assert html =~ "Use this timeline to see when"
    refute html =~ "redacted ledger"
    refute html =~ "projects into this per-flag view"
    refute html =~ "viewer@example.com"
    assert html =~ "Show redacted JSON"
    assert has_element?(view, "ol.rs-event-timeline[aria-label='Flag audit events']")
    assert has_element?(view, "li.rs-event-timeline__item[data-result='denied']")
    assert has_element?(view, ".rs-event-panel__result", "Denied")
    assert has_element?(view, ".rs-event-panel__result", "Applied")

    rollback_html =
      view
      |> element("button[phx-click='rollback']")
      |> render_click()

    assert rollback_html =~ "Rollback appended as audit event"
    assert rollback_html =~ "Rollback applied"
    assert rollback_html =~ "Rollback of audit event"
    assert rollback_html =~ "Restored Active and linked this correction"
  end

  test "timeline row disclosure keeps readable diff first and raw data behind details", %{
    conn: conn
  } do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "What changed"
    assert html =~ "Serving state"
    assert html =~ "Active; fallback variant None"
    assert html =~ "Kill switch on; fallback variant default"
    assert html =~ "Rules"
    assert html =~ "No published rules"
    assert html =~ "checkout-canary at position 1"
    assert html =~ "Added checkout-canary as the first rule."
    assert html =~ "Show redacted JSON"
    assert html =~ "Debug view. Sensitive or non-allowlisted fields may be hidden."
    assert html =~ "rs-json-token rs-json-token--key"
    assert html =~ "&quot;event&quot;"
    assert html =~ "&quot;metadata&quot;"
    refute html =~ "%{event:"

    {diff_index, _length} = :binary.match(html, "What changed")
    diff_item_html = binary_part(html, diff_index, byte_size(html) - diff_index)

    assert :binary.match(diff_item_html, "What changed") <
             :binary.match(diff_item_html, "Show redacted JSON")
  end

  @tag :auto_advance
  @tag :auto_advance_redaction
  test "timeline redacts auto-advance provider secrets but keeps allowed context", %{conn: conn} do
    seed_auto_advance_audit_with_secret!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "[REDACTED]"
    refute html =~ "provider-secret-auto-advance"
    assert html =~ "canary-75"
    assert html =~ "observation window closed"
  end

  @tag :auto_advance
  @tag :auto_advance_label
  test "timeline distinguishes automatic rollout advance from manual rollout actions", %{
    conn: conn
  } do
    seed_guardrail_interventions!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Automatic guardrail hold"
    assert html =~ "Automatic rollout advance"
    assert html =~ "Automatic"
    assert html =~ "Run by Guardrail automation"
    assert html =~ "Run by operator"
    refute html =~ "provider-secret-timeline"
  end

  test "timeline distinguishes automatic guardrail events from manual rollout actions", %{
    conn: conn
  } do
    seed_guardrail_interventions!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Automatic guardrail hold"
    assert html =~ "Automatic guardrail rollback"
    assert html =~ "Guardrail evaluated"
    assert html =~ "Automatic"
    assert html =~ "Run by Guardrail automation"
    assert html =~ "Run by operator"
    assert html =~ "Show redacted JSON"
    assert html =~ "[REDACTED]"
    refute html =~ "provider-secret-timeline"
  end

  test "timeline ignores URL environments outside the mounted session scope", %{conn: conn} do
    publish_ruleset!("checkout-redesign", "staging")

    scoped_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin", "auditor"]},
        "rulestead_admin_last_env" => "staging",
        "rulestead_admin_environments" => [
          %{"key" => "staging", "name" => "Staging"}
        ]
      })

    {:ok, _view, html} = live(scoped_conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Staging"
    assert html =~ "Ruleset publish"
    refute html =~ "Production"
    refute html =~ "Kill switch engaged"
  end

  defp seed_flag!(opts \\ []) do
    attrs = %{
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      environment_keys: Keyword.get(opts, :environment_keys, ["prod", "staging"])
    }

    assert %{flag: %{key: "checkout-redesign"}} = Control.put_flag!(attrs)
  end

  defp publish_ruleset!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "checkout-canary",
          strategy: :percentage_rollout,
          value: %{value: true},
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
          }
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

  defp seed_auto_advance_audit_with_secret! do
    command =
      Command.AdvanceRollout.new(
        "checkout-redesign",
        "prod",
        %{
          rule_key: "checkout-canary",
          stage: "canary-75",
          percentage: 75,
          monitoring_window_started_at: ~U[2026-04-23 16:05:00Z],
          monitoring_window_ends_at: ~U[2026-04-23 16:10:00Z]
        },
        metadata: %{
          source: :guardrail_automation,
          request_id: "req-auto-advance-redaction",
          eligibility: %{
            policy_snapshot: %{
              next_stage: "canary-75",
              next_percentage: 75,
              observation_window_seconds: 300
            }
          },
          observation_window_started_at: ~U[2026-04-23 16:05:00Z],
          observation_window_ends_at: ~U[2026-04-23 16:10:00Z],
          raw_provider_payload: "provider-secret-auto-advance"
        }
      )

    assert {:ok, _} = Rulestead.Fake.advance_rollout(command)
  end

  defp seed_guardrail_interventions! do
    assert {:ok, _advanced} =
             Rulestead.advance_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-50",
                 percentage: 50,
                 monitoring_window_started_at: ~U[2026-04-23 15:45:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 15:50:00Z]
               },
               metadata: %{request_id: "req-manual-advance", source: :admin_ui}
             )

    assert {:ok, _healthy} =
             Rulestead.evaluate_guarded_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-50",
                 monitoring_window_started_at: ~U[2026-04-23 15:45:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 15:50:00Z],
                 signal_facts: [
                   %{
                     signal_key: "checkout_error_rate",
                     status: :healthy,
                     reason: :healthy,
                     threshold_operator: :gte,
                     threshold_value: 0.05,
                     observed_value: 0.01,
                     sample_size: 500,
                     min_sample_size: 100,
                     evaluated_at: ~U[2026-04-23 15:51:00Z],
                     metadata: %{raw_provider_payload: "provider-secret-timeline"}
                   }
                 ]
               },
               metadata: %{request_id: "req-guardrail-evaluated", source: :guardrail_automation}
             )

    auto_advance_command =
      Command.AdvanceRollout.new(
        "checkout-redesign",
        "prod",
        %{
          rule_key: "checkout-canary",
          stage: "canary-55",
          percentage: 55,
          monitoring_window_started_at: ~U[2026-04-23 15:51:00Z],
          monitoring_window_ends_at: ~U[2026-04-23 15:56:00Z]
        },
        metadata: %{
          source: :guardrail_automation,
          request_id: "req-auto-advance-timeline",
          eligibility: %{
            policy_snapshot: %{
              next_stage: "canary-55",
              next_percentage: 55,
              observation_window_seconds: 300
            }
          },
          context: %{
            eligibility: %{
              policy_snapshot: %{
                next_stage: "canary-55",
                next_percentage: 55,
                observation_window_seconds: 300
              }
            },
            observation_window_started_at: "2026-04-23T15:51:00Z",
            observation_window_ends_at: "2026-04-23T15:56:00Z"
          },
          guardrail: %{
            provider: "provider-secret-timeline",
            signal_key: "checkout_error_rate"
          }
        }
      )

    assert {:ok, _} = Rulestead.Fake.advance_rollout(auto_advance_command)

    assert {:ok, _advanced} =
             Rulestead.advance_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-100",
                 percentage: 100,
                 monitoring_window_started_at: ~U[2026-04-23 15:55:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 16:00:00Z]
               },
               metadata: %{request_id: "req-manual-advance-100", source: :admin_ui}
             )

    assert {:ok, _rollback} =
             Rulestead.evaluate_guarded_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-100",
                 monitoring_window_started_at: ~U[2026-04-23 15:55:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 16:00:00Z],
                 signal_facts: [
                   %{
                     signal_key: "checkout_error_rate",
                     status: :breached,
                     reason: :breached,
                     threshold_operator: :gte,
                     threshold_value: 0.05,
                     observed_value: 0.14,
                     sample_size: 600,
                     min_sample_size: 100,
                     evaluated_at: ~U[2026-04-23 16:01:00Z]
                   }
                 ]
               },
               metadata: %{request_id: "req-guardrail-rollback", source: :guardrail_automation}
             )

    assert {:ok, _advanced} =
             Rulestead.advance_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-60",
                 percentage: 60,
                 monitoring_window_started_at: ~U[2026-04-23 15:55:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 16:00:00Z]
               },
               metadata: %{request_id: "req-manual-advance-60", source: :admin_ui}
             )

    assert {:ok, _held} =
             Rulestead.evaluate_guarded_rollout(
               "checkout-redesign",
               "prod",
               %{
                 rule_key: "checkout-canary",
                 stage: "canary-60",
                 monitoring_window_started_at: ~U[2026-04-23 15:55:00Z],
                 monitoring_window_ends_at: ~U[2026-04-23 16:00:00Z],
                 signal_facts: [
                   %{
                     signal_key: "checkout_error_rate",
                     status: :failed_closed,
                     reason: :stale,
                     threshold_operator: :gte,
                     threshold_value: 0.05,
                     observed_value: 0.03,
                     freshness_window_seconds: 300,
                     sample_size: 250,
                     min_sample_size: 100,
                     evaluated_at: ~U[2026-04-23 15:59:00Z]
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
