defmodule RulesteadDemoWeb.DemoContextJSON do
  @moduledoc false

  alias RulesteadDemo.Fixtures

  def personas do
    %{
      product: "FleetDesk",
      domain: "B2B fleet operations for logistics teams",
      environmentKeys: Fixtures.environment_keys(),
      personas: Enum.map(Fixtures.personas(), &persona/1),
      flags: [
        %{
          key: "enable-new-dashboard",
          label: "Fleet map v2 cockpit",
          journey: "kill-switch"
        },
        %{
          key: "fleet-map-v2",
          label: "Vector map renderer",
          journey: "targeted-rollout"
        },
        %{
          key: "dispatch-ops-copy",
          label: "Dispatch headline copy",
          journey: "experiment"
        },
        %{
          key: "ops-banner-config",
          label: "Operations banner",
          journey: "remote-config"
        },
        %{
          key: "dispatch-guarded-rollout",
          label: "Guarded dispatch routing",
          journey: "guarded-rollout"
        },
        %{
          key: "ops-audience-preview",
          label: "Dispatcher audience panel",
          journey: "audience-preview"
        }
      ]
    }
  end

  defp persona(persona) do
    %{
      id: persona.id,
      label: persona.label,
      company: persona.company,
      tenantKey: persona.tenant_key,
      plan: persona.plan,
      targetingKey: persona.targeting_key,
      summary: persona.summary
    }
  end
end
