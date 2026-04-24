Application.put_env(:rulestead_admin, RulesteadAdmin.TestEndpoint,
  secret_key_base: String.duplicate("r", 64),
  server: false,
  url: [host: "localhost"],
  live_view: [signing_salt: "session-signing-salt"],
  pubsub_server: RulesteadAdmin.PubSub
)

ExUnit.start()
