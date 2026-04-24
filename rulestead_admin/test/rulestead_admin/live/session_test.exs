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
