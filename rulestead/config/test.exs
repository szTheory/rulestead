import Config

default_username =
  System.get_env("PGUSER") ||
    System.get_env("RULESTEAD_DB_USERNAME") ||
    System.get_env("USER") ||
    "postgres"

config :rulestead, Rulestead.Repo,
  username: default_username,
  password: System.get_env("PGPASSWORD") || System.get_env("RULESTEAD_DB_PASSWORD"),
  hostname: System.get_env("RULESTEAD_DB_HOSTNAME", "localhost"),
  port: String.to_integer(System.get_env("RULESTEAD_DB_PORT", "5432")),
  database: System.get_env("RULESTEAD_TEST_DATABASE", "rulestead_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true
