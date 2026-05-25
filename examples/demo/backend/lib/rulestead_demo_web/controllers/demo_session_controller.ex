defmodule RulesteadDemoWeb.DemoSessionController do
  use RulesteadDemoWeb, :controller

  @demo_actor %{
    id: "demo-operator",
    email: "demo-operator@rulestead.local",
    display: "Demo Operator",
    roles: ["admin"]
  }

  @demo_environments [
    %{key: "staging", name: "Staging"},
    %{key: "production", name: "Production"}
  ]

  def create(conn, _params) do
    conn
    |> put_session("current_actor", @demo_actor)
    |> put_session("rulestead_admin_environments", @demo_environments)
    |> put_session("rulestead_admin_last_env", "staging")
    |> redirect(to: ~p"/admin/flags?env=staging")
  end
end
