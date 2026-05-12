defmodule RulesteadAdmin.Live.FlagLive.RulesTest do
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

    def can?(_actor, :list_audit_events, _resource, _environment_key), do: true
    def can?(_actor, :access_admin, _resource, _environment_key), do: true
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

    publish_flag!("checkout-redesign", "prod")
    save_draft!("checkout-redesign", "prod", draft_ruleset(2))
    put_audience!("vip-customers", "VIP customers")
    put_audience!("internal-beta", "Internal beta")

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "operators can edit, reorder, target audiences, and save draft rules for the selected environment", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rules?env=prod")

    assert html =~ "Rules workspace"
    assert html =~ "Draft ruleset"
    assert html =~ "Save draft"
    assert html =~ "Publish"
    assert html =~ "Reusable audience"
    assert has_element?(view, "select[aria-label='Reusable audience']")

    reordered_html =
      view
      |> element("button[phx-click='move_rule'][phx-value-direction='down'][phx-value-key='allow-vip']")
      |> render_click()

    assert reordered_html =~ "Rule order updated"
    assert rendered_rule_keys(reordered_html) == ["fallthrough-rollout", "allow-vip"]

    updated_html =
      view
      |> form("form[aria-label='Rules workspace form']", %{
        "ruleset" => %{
          "rules" => %{
            "0" => %{
              "key" => "fallthrough-rollout",
              "name" => "Fallback split",
              "strategy" => "variant_split",
              "audience_key" => "",
              "value" => "false",
              "conditions" => %{},
              "variants" => %{
                "0" => %{"key" => "control", "value" => "false", "weight" => "55"},
                "1" => %{"key" => "treatment", "value" => "true", "weight" => "45"}
              }
            },
            "1" => %{
              "key" => "allow-vip",
              "name" => "VIP audience",
              "strategy" => "segment_match",
              "audience_key" => "internal-beta",
              "value" => "true",
              "conditions" => %{},
              "variants" => %{}
            }
          }
        }
      })
      |> render_submit()

    assert updated_html =~ "Draft saved for Production"

    detail = Rulestead.fetch_flag!("checkout-redesign", "prod")
    [latest_draft | _rest] = detail.draft_rulesets
    [first_rule, second_rule] = latest_draft.rules

    assert Enum.map(latest_draft.rules, & &1.key) == ["fallthrough-rollout", "allow-vip"]
    assert first_rule.strategy == :variant_split
    assert Enum.map(first_rule.variants, & &1.weight) == [55, 45]
    assert second_rule.strategy == :segment_match
    assert second_rule.audience_key == "internal-beta"
  end

  test "variant totals validate live and block save plus publish until weights sum to 100", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/rules?env=prod")

    invalid_html =
      view
      |> form("form[aria-label='Rules workspace form']", %{
        "ruleset" => %{
          "rules" => %{
            "0" => %{
              "key" => "allow-vip",
              "name" => "VIP audience",
              "strategy" => "forced_value",
              "audience_key" => "",
              "value" => "true",
              "conditions" => %{},
              "variants" => %{}
            },
            "1" => %{
              "key" => "fallthrough-rollout",
              "name" => "Fallback split",
              "strategy" => "variant_split",
              "audience_key" => "",
              "value" => "false",
              "conditions" => %{},
              "variants" => %{
                "0" => %{"key" => "control", "value" => "false", "weight" => "60"},
                "1" => %{"key" => "treatment", "value" => "true", "weight" => "39"}
              }
            }
          }
        }
      })
      |> render_change()

    assert invalid_html =~ "Variant weights must total 100"
    assert invalid_html =~ "Save draft disabled until variant weights total 100"

    blocked_save_html =
      view
      |> element("button[phx-click='save_draft']")
      |> render_click()

    assert blocked_save_html =~ "Variant weights must total 100"

    blocked_publish_html =
      view
      |> element("button[phx-click='publish']")
      |> render_click()

    assert blocked_publish_html =~ "Variant weights must total 100"
    assert Rulestead.fetch_flag!("checkout-redesign", "prod").active_ruleset.version == 1
  end

  test "workspace keeps save and publish distinct, warns on existing draft, rejects missing audience, and becomes read-only after archive", %{
    conn: conn
  } do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rules?env=prod")

    assert html =~ "Draft ruleset ready"
    assert html =~ "Save draft"
    assert html =~ "Publish"
    refute html =~ "autosave"

    invalid_segment_html =
      view
      |> form("form[aria-label='Rules workspace form']", %{
        "ruleset" => %{
          "rules" => %{
            "0" => %{
              "key" => "allow-vip",
              "name" => "VIP audience",
              "strategy" => "segment_match",
              "audience_key" => "",
              "value" => "true",
              "conditions" => %{},
              "variants" => %{}
            },
            "1" => %{
              "key" => "fallthrough-rollout",
              "name" => "Fallback split",
              "strategy" => "forced_value",
              "audience_key" => "",
              "value" => "false",
              "conditions" => %{},
              "variants" => %{}
            }
          }
        }
      })
      |> render_submit()

    assert invalid_segment_html =~ "Choose a reusable audience for segment match rules"

    publish_html =
      view
      |> element("button[phx-click='publish']")
      |> render_click()

    assert publish_html =~ "Published to Production"
    assert Rulestead.fetch_flag!("checkout-redesign", "prod").active_ruleset.version >= 2

    assert {:ok, archived} = Rulestead.archive_flag(Command.ArchiveFlag.new("checkout-redesign"))
    assert archived.archived?

    {:ok, archived_view, archived_html} = live(conn, "/admin/flags/checkout-redesign/rules?env=prod")

    assert archived_html =~ "This flag is archived"
    assert archived_html =~ "Rules are read-only"
    refute has_element?(archived_view, "button[phx-click='save_draft']")
    refute has_element?(archived_view, "button[phx-click='publish']")
    refute has_element?(archived_view, "button[phx-click='archive_flag']")
  end

  test "denied draft and publish writes fail closed and leave denied audit rows visible", %{conn: conn} do
    Application.put_env(:rulestead, :admin_policy, DenyWritesPolicy)

    denied_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: "viewer-1", email: "viewer@example.com", display: "Viewer", roles: ["viewer"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, view, _html} = live(denied_conn, "/admin/flags/checkout-redesign/rules?env=prod")

    denied_save_html =
      view
      |> form("form[aria-label='Rules workspace form']", %{
        "ruleset" => %{
          "rules" => %{
            "0" => %{
              "key" => "allow-vip",
              "name" => "VIP audience",
              "strategy" => "forced_value",
              "audience_key" => "",
              "value" => "true",
              "conditions" => %{},
              "variants" => %{}
            },
            "1" => %{
              "key" => "fallthrough-rollout",
              "name" => "Fallback split",
              "strategy" => "variant_split",
              "audience_key" => "",
              "value" => "false",
              "conditions" => %{},
              "variants" => %{
                "0" => %{"key" => "control", "value" => "false", "weight" => "50"},
                "1" => %{"key" => "treatment", "value" => "true", "weight" => "50"}
              }
            }
          }
        }
      })
      |> render_submit()

    assert denied_save_html =~ "caller is not authorized to perform this action"

    denied_publish_html =
      view
      |> element("button[phx-click='publish']")
      |> render_click()

    assert denied_publish_html =~ "caller is not authorized to perform this action"

    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    {:ok, timeline_view, timeline_html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert timeline_html =~ "Ruleset save draft denied"
    assert timeline_html =~ "Viewer"
    refute timeline_html =~ "Ruleset publish denied"
    assert has_element?(timeline_view, "details")
  end

  defp rendered_rule_keys(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[data-role='rule-card']")
    |> Enum.map(fn node -> List.first(LazyHTML.attribute(node, "data-rule-key")) end)
  end

  defp draft_ruleset(version) do
    %{
      salt: "checkout-redesign:prod:v#{version}",
      rules: [
        %{
          key: "allow-vip",
          name: "VIP audience",
          strategy: :segment_match,
          audience_key: "vip-customers",
          value: %{value: true},
          conditions: []
        },
        %{
          key: "fallthrough-rollout",
          name: "Fallback split",
          strategy: :variant_split,
          conditions: [],
          variants: [
            %{key: "control", value: %{value: false}, weight: 50},
            %{key: "treatment", value: %{value: true}, weight: 50}
          ],
          rollout: %{bucket_by: :subject, percentage: 100}
        }
      ]
    }
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

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp publish_flag!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "baseline-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp save_draft!(flag_key, environment_key, ruleset) do
    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
  end

  defp put_audience!(key, name) do
    snapshot = Control.snapshot!()

    audience = %{
      id: "aud-" <> key,
      key: key,
      name: name,
      description: "#{name} reusable audience"
    }

    next_state = put_in(snapshot.audiences[key], audience)
    assert :ok = Control.restore!(next_state)
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
