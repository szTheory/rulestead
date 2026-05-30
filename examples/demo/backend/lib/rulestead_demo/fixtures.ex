defmodule RulesteadDemo.Fixtures do
  @moduledoc """
  FleetDesk adoption-lab personas and tenants.

  A minimal B2B fleet-ops SaaS domain used to exercise Rulestead journeys
  without pretending to be a production product.
  """

  @demo_actor %{
    id: "demo-operator",
    email: "demo-operator@fleetdesk.local",
    display: "FleetDesk Demo Operator",
    roles: ["admin"]
  }

  @environment_keys ["staging", "production"]

  @personas [
    %{
      id: "demo-user",
      label: "Jordan Lee · Acme Logistics (Pro)",
      company: "Acme Logistics",
      tenant_key: "acme-logistics",
      plan: "pro",
      targeting_key: "demo-user",
      summary: "Dispatch lead managing weekday routes on the pro plan."
    },
    %{
      id: "fleet-manager",
      label: "Morgan Chen · Acme Logistics (Enterprise)",
      company: "Acme Logistics",
      tenant_key: "acme-logistics",
      plan: "enterprise",
      targeting_key: "fleet-manager-acme",
      summary: "Fleet manager with enterprise map-v2 rollout access."
    },
    %{
      id: "beta-dispatcher",
      label: "Riley Park · Beta Fleet Co (Starter)",
      company: "Beta Fleet Co",
      tenant_key: "beta-fleet",
      plan: "starter",
      targeting_key: "beta-dispatcher",
      summary: "Starter-plan dispatcher on the beta tenant."
    }
  ]

  def demo_actor, do: @demo_actor
  def environment_keys, do: @environment_keys
  def personas, do: @personas

  def persona(id) when is_binary(id) do
    Enum.find(@personas, &(&1.id == id))
  end

  def persona!(id) do
    case persona(id) do
      nil -> raise ArgumentError, "unknown demo persona #{inspect(id)}"
      persona -> persona
    end
  end

  def default_persona, do: hd(@personas)
end
