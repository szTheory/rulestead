import Config

config :rulestead, :store, Rulestead.Store.Ecto

config :rulestead, Rulestead.Repo,
  repo: HostApp.Repo

config :rulestead, :host,
  [
    environment_key: "dev",
    plug: [
      context_assign: :rulestead_context,
      targeting_key_sources: [
        session: "targeting_key",
        cookie: "rulestead_targeting_key",
        header: "x-rulestead-targeting-key"
      ]
    ],
    live_view: [
      context_assign: :rulestead_context,
      targeting_key_sources: [session: "targeting_key", assign: :targeting_key],
      assign_flags_mode: :enabled
    ],
    oban: [
      enabled: true,
      context_key: "rulestead_context",
      middlewares: [{Rulestead.Oban.Middleware, []}]
    ],
    runtime: [api: Rulestead.Runtime]
  ]
