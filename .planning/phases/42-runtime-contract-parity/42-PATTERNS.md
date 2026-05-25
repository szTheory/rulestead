# Phase 42: Runtime Contract Parity - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/repo/migrations/YYYYMMDDHHMMSS_create_rulestead_tables.exs` | migration | schema definition | `priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs` | exact |
| `lib/rulestead/install/migration_writer.ex` | utility | file I/O | `lib/rulestead/install/migration_writer.ex` | exact |
| `lib/rulestead/flag.ex` | model | CRUD / schema mapping | `lib/rulestead/ruleset.ex` | role-match |
| `test/support/store_fixtures.ex` | test/factory | CRUD setup | `test/support/store_fixtures.ex` | exact |
| `test/rulestead/integration/install_golden_test.exs` | test | golden/snapshot | `test/rulestead/integration/install_golden_test.exs` | exact |

## Pattern Assignments

### `priv/repo/migrations/YYYYMMDDHHMMSS_create_rulestead_tables.exs` (migration, schema definition)

**Analog:** `priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs`

**Core Pattern: Squoshed Migration Structure**
The new squoshed migration will aggregate the creation of all tables into a single `up`/`down` (or `change`) block. It should follow the standard Rulestead Ecto migration pattern with UUIDs and precise timestamps:

```elixir
defmodule Rulestead.Repo.Migrations.CreateRulesteadTables do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto", "DROP EXTENSION IF EXISTS pgcrypto")

    create table(:flags, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:description, :text)
      add(:flag_type, :text, null: false)
      add(:value_type, :text, null: false)
      add(:default_value, :map, null: false, default: fragment("'{}'::jsonb"))
      
      # NOTE: legacy fields `owner`, `expected_expiration`, `permanent` are intentionally omitted
      
      add(:ownership, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:lifecycle, :map, null: false, default: fragment("'{}'::jsonb"))
      
      add(:tags, {:array, :text}, null: false, default: [])
      add(:archived_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end
    create(unique_index(:flags, [:key]))

    # ... (other tables squoshed here)
    
    create table(:environment_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_key, :string, null: false # Fixing the missing tenant_key column
      add :environment_key, :string, null: false
      add :version, :integer, null: false
      add :authored_snapshot, :map, null: false, default: %{}
      # ...
      timestamps(type: :utc_datetime_usec)
    end
  end
end
```

---

### `lib/rulestead/install/migration_writer.ex` (utility, file I/O)

**Analog:** `lib/rulestead/install/migration_writer.ex` (Current state)

**Core Pattern: Iterating Over Migrations**
The `copy_migrations` function currently scans the directory and copies files. This pattern will naturally accommodate the change to a single squoshed migration by simply having one file to iterate over.

```elixir
  @source_dir Application.app_dir(:rulestead, "priv/repo/migrations")

  def copy_migrations(repo, opts \\ []) do
    target_dir = Keyword.get(opts, :migrations_path) || target_path_for_repo(repo)
    File.mkdir_p!(target_dir)

    messages =
      @source_dir
      |> File.ls!()
      |> Enum.sort()
      |> Enum.map(fn filename ->
        source = Path.join(@source_dir, filename)
        target = Path.join(target_dir, filename)
        # ... exists? check and File.cp!
      end)
```

---

### `lib/rulestead/flag.ex` (model, CRUD / schema mapping)

**Analog:** `lib/rulestead/ruleset.ex` (for exclusive embeds pattern)

**Core Pattern: Exclusively using JSONB embeds**
We will remove the legacy top-level fields `owner`, `expected_expiration`, and `permanent` from the `schema` block and the `cast` parameters. The model will exclusively use `embeds_one`.

**Removed fields pattern** (from current `lib/rulestead/flag.ex`):
```elixir
    # DROP THESE:
    # field(:owner, :string)
    # field(:expected_expiration, :date)
    # field(:permanent, :boolean, default: false)
```

**New schema pattern** (similar to `Ruleset.rules`):
```elixir
  schema "flags" do
    field(:key, :string)
    # ...
    embeds_one(:ownership, Ownership, on_replace: :update)
    embeds_one(:lifecycle, LifecycleMetadata, on_replace: :update)
    # ...
  end
```

**Changeset pattern:**
```elixir
  def changeset(flag, attrs) do
    attrs = normalize_embeds(attrs)

    flag
    |> cast(attrs, [
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :tags,
      :archived_at
    ])
    |> cast_embed(:ownership, required: true, with: &Ownership.changeset/2)
    |> cast_embed(:lifecycle, required: true, with: &LifecycleMetadata.changeset/2)
    # Validation for the embed contents replaces top-level validation
  end
```

---

### `test/support/store_fixtures.ex` (test/factory, CRUD setup)

**Analog:** `test/support/store_fixtures.ex` (Current state)

**Core Pattern: Populating Embedded Structs**
`valid_flag_attrs` currently populates top-level legacy fields. It must be updated to structure the data exactly how the API expects the embeds to be provided (either as nested maps if simulating external input, or structurally).

**Updated pattern for `valid_flag_attrs`:**
```elixir
  def valid_flag_attrs(overrides \\ %{}) do
    defaults = %{
      key: "checkout-redesign",
      description: "Release the new checkout flow",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{
        owner: "growth"
      },
      lifecycle: %{
        mode: :permanent
      },
      tags: ["checkout", "release"],
      environment_keys: ["test"]
    }

    Map.merge(defaults, overrides)
  end
```

---

### `test/rulestead/integration/install_golden_test.exs` (test, golden/snapshot)

**Analog:** `test/rulestead/integration/install_golden_test.exs` (Current state)

**Core Pattern: Golden File Testing**
Since the installer will now only copy 1 squoshed migration instead of 17, the golden outputs (`test/fixtures/install_golden/STDOUT.txt` and `test/fixtures/install_golden/tree`) must be updated to reflect the new state. This usually involves running a setup script or updating the expected artifacts in the filesystem manually. The test pattern itself remains identical.

```elixir
  @fixture_root Path.expand("../../fixtures/install_golden", __DIR__)
  @tree_fixture_root Path.join(@fixture_root, "tree")
  @stdout_fixture_path Path.join(@fixture_root, "STDOUT.txt")

  test "installer output matches the normalized golden tree and stdout" do
    result = setup_tmp_app!()
    on_exit(fn -> cleanup_tmp_app!(result) end)

    assert normalize_stdout(result.stdout) == File.read!(@stdout_fixture_path)
    # The golden fixtures will need to be re-generated to account for
    # the single migration file.
  end
```

## Shared Patterns

### Squoshed Migration
**Source:** Standard Ecto GA practice (similar to Oban)
**Apply to:** `priv/repo/migrations/*`
Rulestead will move from a history of incremental development migrations to a single `YYYYMMDDHHMMSS_create_rulestead_tables.exs` baseline, establishing the "v1.3.0 stable baseline".

## Metadata

**Analog search scope:** `lib/rulestead/`, `priv/repo/migrations/`, `test/`
**Files scanned:** ~30
**Pattern extraction date:** 2026-05-24
