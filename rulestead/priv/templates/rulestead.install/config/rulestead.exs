import Config

config :rulestead, :store, Rulestead.Store.Ecto

config :rulestead, Rulestead.Repo,
  repo: __REPO_MODULE__,
  prefix: "rulestead"
