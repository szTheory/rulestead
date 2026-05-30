import Config

config :rulestead, :store, Rulestead.Store.Ecto
config :rulestead, :admin_policy, RulesteadDemo.AdminPolicy
config :rulestead, :preview_evidence_resolver, RulesteadDemo.PreviewEvidenceResolver

config :rulestead, :runtime, environment_keys: []

config :rulestead, :snapshot,
  refresh_interval_ms: 1_000,
  min_refresh_interval_ms: 1_000,
  max_refresh_interval_ms: 5_000,
  refresh_jitter_ms: 0

config :rulestead, :host,
  environment_key: "staging",
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
  runtime: [
    api: Rulestead.Runtime,
    notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
    health_peer_provider: nil,
    pubsub: RulesteadDemo.PubSub,
    pubsub_topic: "rulestead:runtime_snapshot"
  ],
  tenancy: [module: Rulestead.Tenancy.SingleTenant]
