defmodule RulesteadAdmin.Live.SessionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  test "resolve/3 treats url env as canonical and only uses remembered env as fallback" do
    environments = [
      %{"key" => "dev", "name" => "Development"},
      %{"key" => "staging", "name" => "Staging"},
      %{"key" => "prod", "name" => "Production"}
    ]

    resolved_from_url =
      Session.resolve(
        %{"env" => "prod"},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_environments" => environments,
          "rulestead_admin_last_env" => "staging"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_url.actor == %{id: 7}
    assert resolved_from_url.environment.key == "prod"
    assert resolved_from_url.environment.name == "Production"
    assert resolved_from_url.env_source == :url

    resolved_from_memory =
      Session.resolve(
        %{},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_environments" => environments,
          "rulestead_admin_last_env" => "staging"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_memory.environment.key == "staging"
    assert resolved_from_memory.env_source == :remembered

    resolved_from_invalid_url =
      Session.resolve(
        %{"env" => "unknown"},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_environments" => environments,
          "rulestead_admin_last_env" => "staging"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_invalid_url.environment.key == "dev"
    assert resolved_from_invalid_url.env_source == :default
  end

  test "shared route helpers build canonical env paths and policy state for phase 7 screens" do
    assigns = %{
      current_environment: %{key: "prod", name: "Production"},
      available_environments: [
        %{key: "dev", name: "Development"},
        %{key: "prod", name: "Production"}
      ],
      current_actor: %{id: "sys", roles: [:admin]}
    }

    assert Session.current_path(assigns, "/admin/flags/pricing/simulate") ==
             "/admin/flags/pricing/simulate?env=prod"

    assert Session.current_path(assigns, "/admin/audit", %{"actor" => "sam", "before" => nil}) ==
             "/admin/audit?actor=sam&env=prod"

    assert Session.env_links(assigns, "/admin/flags/pricing/kill", %{"tab" => "confirm"}) == %{
             "dev" => "/admin/flags/pricing/kill?env=dev&tab=confirm",
             "prod" => "/admin/flags/pricing/kill?env=prod&tab=confirm"
           }

    assert Session.policy_state(assigns) == %{
             environment_key: "prod",
             production?: true,
             tone: "critical",
             label: "Production policy",
             summary: "Production actions should stay explicit and auditable.",
             capabilities: %{
               admin?: true,
               edit?: true,
               execute?: true,
               propose?: true,
               read?: true
             }
           }
  end

  test "shared route helpers preserve non-default mount roots for phase 7 screens" do
    assigns = %{
      current_environment: %{key: "staging", name: "Staging"},
      available_environments: [
        %{key: "staging", name: "Staging"},
        %{key: "prod", name: "Production"}
      ]
    }

    assert Session.current_path(assigns, "/ops/flags/checkout-redesign/rollouts") ==
             "/ops/flags/checkout-redesign/rollouts?env=staging"

    assert Session.env_links(assigns, "/ops/flags/audit", %{"mutation" => "ruleset.publish"}) == %{
             "prod" => "/ops/flags/audit?env=prod&mutation=ruleset.publish",
             "staging" => "/ops/flags/audit?env=staging&mutation=ruleset.publish"
           }
  end

  test "shell renders a global environment picker with explicit production styling" do
    html =
      render_component(&Shell.page/1,
        page_title: "Flags",
        page_kicker: "Flag inventory",
        page_summary: "Compile-safe placeholder",
        current_environment: %{key: "prod", name: "Production"},
        environments: [
          %{key: "dev", name: "Development"},
          %{key: "prod", name: "Production"}
        ],
        env_links: %{
          "dev" => "/admin/flags?env=dev",
          "prod" => "/admin/flags?env=prod"
        },
        inner_block: [
          %{
            inner_block: fn _changed, _slot_value -> "Flag list placeholder" end
          }
        ]
      )

    assert html =~ "Environment"
    assert html =~ "Production"
    assert html =~ "Flag list placeholder"
    assert html =~ "data-env-tone=\"production\""
    assert html =~ "/admin/flags?env=dev"
  end
end
