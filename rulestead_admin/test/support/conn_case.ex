# credo:disable-for-this-file
defmodule RulesteadAdmin.TestPolicy do
  @moduledoc false
  @behaviour Rulestead.Admin.Policy

  @impl true
  def can?(_actor, _action, _resource, _environment_key), do: true

  @impl true
  def change_request_required?(_actor, _action, _resource, _environment_key), do: false

  @impl true
  def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
end

defmodule RulesteadAdmin.DenyPolicy do
  @moduledoc false
  @behaviour Rulestead.Admin.Policy

  @impl true
  def can?(_actor, _action, _resource, _environment_key), do: false

  @impl true
  def change_request_required?(_actor, _action, _resource, _environment_key), do: true

  @impl true
  def allow_self_approval?(_actor, _action, _resource, _environment_key), do: false
end

defmodule RulesteadAdmin.TestRouter do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.LiveView.Router
  use RulesteadAdmin.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
  end

  scope "/" do
    pipe_through(:browser)

    rulestead_admin("/admin/flags", policy: RulesteadAdmin.TestPolicy)
  end
end

defmodule RulesteadAdmin.TestEndpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :rulestead_admin

  @session_options [
    store: :cookie,
    key: "_rulestead_admin_key",
    signing_salt: "endpoint-signing-salt"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Session, @session_options)
  plug(Plug.RequestId)
  plug(Plug.Head)
  plug(RulesteadAdmin.TestRouter)
end

defmodule RulesteadAdmin.ConnCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      alias Rulestead.Fake.Control
      alias Rulestead.Store.Command

      @endpoint RulesteadAdmin.TestEndpoint
    end
  end

  setup _tags do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, RulesteadAdmin.TestPolicy)

    Rulestead.Fake.Control.reset!()

    ExUnit.Callbacks.on_exit(fn ->
      if previous_policy,
        do: Application.put_env(:rulestead, :admin_policy, previous_policy),
        else: Application.delete_env(:rulestead, :admin_policy)

      if previous_store,
        do: Application.put_env(:rulestead, :store, previous_store),
        else: Application.delete_env(:rulestead, :store)
    end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
