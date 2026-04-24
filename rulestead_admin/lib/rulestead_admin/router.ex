defmodule RulesteadAdmin.Router do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import RulesteadAdmin.Router, only: [rulestead_admin: 1, rulestead_admin: 2]
    end
  end

  defmacro rulestead_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      policy = Keyword.fetch!(opts, :policy)
      live_session_name = Module.concat(policy, AdminSession)

      scope path, as: :rulestead_admin do
        live_session live_session_name,
          session: %{
            "policy" => policy,
            "mount_path" => path
          },
          on_mount: [{RulesteadAdmin.Live.Session, :default}] do
          live "/", RulesteadAdmin.Live.FlagLive.Index, :index
          live "/new", RulesteadAdmin.Live.FlagLive.Form, :new
          live "/:key", RulesteadAdmin.Live.FlagLive.Show, :show
          live "/:key/edit", RulesteadAdmin.Live.FlagLive.Form, :edit
          live "/:key/rules", RulesteadAdmin.Live.FlagLive.Rules, :index
        end
      end
    end
  end
end
