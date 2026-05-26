defmodule RulesteadAdmin.Live.SessionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.Socket
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

  test "resolve/3 prefers bounded tenant scope and keeps invalid params fail-closed" do
    tenants = [
      %{"key" => "acme", "name" => "Acme"},
      %{"key" => "globex", "name" => "Globex"}
    ]

    resolved_from_url =
      Session.resolve(
        %{"tenant" => "globex"},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_tenants" => tenants,
          "rulestead_admin_default_tenant" => "acme",
          "rulestead_admin_last_tenant" => "acme"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_url.tenant.key == "globex"
    assert resolved_from_url.tenant_source == :url

    resolved_from_memory =
      Session.resolve(
        %{},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_tenants" => tenants,
          "rulestead_admin_default_tenant" => "acme",
          "rulestead_admin_last_tenant" => "globex"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_memory.tenant.key == "globex"
    assert resolved_from_memory.tenant_source == :remembered

    resolved_from_invalid_url =
      Session.resolve(
        %{"tenant" => "unknown"},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_tenants" => tenants,
          "rulestead_admin_default_tenant" => "acme",
          "rulestead_admin_last_tenant" => "globex"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_invalid_url.tenant.key == "globex"
    assert resolved_from_invalid_url.tenant_source == :remembered

    resolved_from_default =
      Session.resolve(
        %{},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_tenants" => tenants,
          "rulestead_admin_default_tenant" => "acme"
        },
        policy: RulesteadAdmin.TestPolicy,
        mount_path: "/admin/flags"
      )

    assert resolved_from_default.tenant.key == "acme"
    assert resolved_from_default.tenant_source == :default
  end

  test "on_mount/4 fails closed when mounted prerequisites are missing" do
    {:halt, socket} =
      Session.on_mount(
        :default,
        %{"env" => "prod"},
        %{
          "policy" => RulesteadAdmin.TestPolicy,
          "mount_path" => "/admin/flags",
          "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}]
        },
        %Socket{}
      )

    assert socket.redirected == {:redirect, %{to: "/admin/flags", status: 302}}

    {:halt, socket} =
      Session.on_mount(
        :default,
        %{"env" => "prod"},
        %{
          "current_actor" => %{id: 7},
          "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}]
        },
        %Socket{}
      )

    assert socket.redirected == {:redirect, %{to: "/", status: 302}}
  end

  test "shared route helpers build canonical env paths and policy state for phase 7 screens" do
    assigns = %{
      current_environment: %{key: "prod", name: "Production"},
      current_tenant: %{key: "acme", name: "Acme"},
      available_environments: [
        %{key: "dev", name: "Development"},
        %{key: "prod", name: "Production"}
      ],
      available_tenants: [
        %{key: "acme", name: "Acme"},
        %{key: "globex", name: "Globex"}
      ],
      current_actor: %{id: "sys", roles: [:admin]}
    }

    assert Session.current_path(assigns, "/admin/flags/pricing/simulate") ==
             "/admin/flags/pricing/simulate?env=prod&tenant=acme"

    assert Session.current_path(assigns, "/admin/audit", %{"actor" => "sam", "before" => nil}) ==
             "/admin/audit?actor=sam&env=prod&tenant=acme"

    assert Session.env_links(assigns, "/admin/flags/pricing/kill", %{"tab" => "confirm"}) == %{
             "dev" => "/admin/flags/pricing/kill?env=dev&tab=confirm&tenant=acme",
             "prod" => "/admin/flags/pricing/kill?env=prod&tab=confirm&tenant=acme"
           }

    assert Session.tenant_links(assigns, "/admin/audit", %{"actor" => "sam"}) == %{
             "acme" => "/admin/audit?actor=sam&env=prod&tenant=acme",
             "globex" => "/admin/audit?actor=sam&env=prod&tenant=globex"
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
      current_tenant: %{key: "acme", name: "Acme"},
      available_environments: [
        %{key: "staging", name: "Staging"},
        %{key: "prod", name: "Production"}
      ]
    }

    assert Session.current_path(assigns, "/ops/flags/checkout-redesign/rollouts") ==
             "/ops/flags/checkout-redesign/rollouts?env=staging&tenant=acme"

    assert Session.env_links(assigns, "/ops/flags/audit", %{"mutation" => "ruleset.publish"}) ==
             %{
               "prod" => "/ops/flags/audit?env=prod&mutation=ruleset.publish&tenant=acme",
               "staging" => "/ops/flags/audit?env=staging&mutation=ruleset.publish&tenant=acme"
             }
  end

  test "shell renders separate tenant scope chrome without implying an environment switcher" do
    html =
      render_component(&Shell.page/1,
        page_title: "Flags",
        page_kicker: "Flag inventory",
        page_summary: "Compile-safe placeholder",
        current_environment: %{key: "prod", name: "Production"},
        current_tenant: %{key: "acme", name: "Acme"},
        environments: [
          %{key: "dev", name: "Development"},
          %{key: "prod", name: "Production"}
        ],
        tenants: [
          %{key: "acme", name: "Acme"}
        ],
        env_links: %{
          "dev" => "/admin/flags?env=dev",
          "prod" => "/admin/flags?env=prod"
        },
        tenant_links: %{
          "acme" => "/admin/flags?env=prod&tenant=acme"
        },
        inner_block: [
          %{
            inner_block: fn _changed, _slot_value -> "Flag list placeholder" end
          }
        ]
      )

    assert html =~ "Environment"
    assert html =~ "Tenant"
    assert html =~ "Production"
    assert html =~ "Scoped to"
    assert html =~ "Acme"
    assert html =~ "Flag list placeholder"
    assert html =~ "data-env-tone=\"production\""
    assert html =~ "/admin/flags?env=dev"
  end
end
