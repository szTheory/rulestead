defmodule Rulestead.Repo.Migrations.SeedDefaultEnvironments do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO environments (id, key, name, description, inserted_at, updated_at)
    VALUES
      (gen_random_uuid(), 'development', 'Development', 'Local and developer-owned environments', NOW(), NOW()),
      (gen_random_uuid(), 'staging', 'Staging', 'Pre-production validation environments', NOW(), NOW()),
      (gen_random_uuid(), 'production', 'Production', 'Live customer-facing environments', NOW(), NOW()),
      (gen_random_uuid(), 'test', 'Test', 'Automated and ephemeral test environments', NOW(), NOW())
    ON CONFLICT (key) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM environments
    WHERE key IN ('development', 'staging', 'production', 'test')
    """)
  end
end
