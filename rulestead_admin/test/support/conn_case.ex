defmodule RulesteadAdmin.TestPolicy do
  @behaviour Rulestead.Admin.Policy

  @impl true
  def can?(_actor, _action, _resource, _environment_key), do: true
end

defmodule RulesteadAdmin.TestRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  use RulesteadAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
  end

  scope "/" do
    pipe_through :browser

    rulestead_admin "/admin/flags", policy: RulesteadAdmin.TestPolicy
  end
end

defmodule RulesteadAdmin.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :rulestead_admin

  @session_options [
    store: :cookie,
    key: "_rulestead_admin_key",
    signing_salt: "endpoint-signing-salt"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  plug Plug.Session, @session_options
  plug Plug.RequestId
  plug Plug.Head
  plug RulesteadAdmin.TestRouter
end

defmodule RulesteadAdmin.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      import Phoenix.LiveViewTest

      @endpoint RulesteadAdmin.TestEndpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
