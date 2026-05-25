<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Consolidate all historical migrations into a single cohesive `YYYYMMDDHHMMSS_create_rulestead_tables.exs` migration for the installer to copy.
- **D-02:** Drop the legacy `owner`, `expected_expiration`, and `permanent` columns from the `flags` schema and the new squoshed migration.
- **D-03:** Update `Rulestead.Flag` schema to exclusively rely on the `ownership` and `lifecycle` embeds. Drop the direct fields.
- **D-04:** Fix the missing `tenant_key` column on `environment_versions` in the squoshed migration.
- **D-05:** Update the `InstallGoldenTest` and `RulesteadInstallTest` golden outputs to match the new single-file squoshed installer behavior.

### the agent's Discretion
None explicitly specified.

### Deferred Ideas (OUT OF SCOPE)
- Adding new feature flags capabilities or evaluation behaviors.
- Modifying mounted-admin user interface screens beyond updating data requirements.
- Changing OpenFeature bridge implementation.
</user_constraints>

# Phase 42: Runtime Contract Parity - Research

**Researched:** 2026-05-24
**Domain:** Database Schema, Migrations, Installer, Golden Tests
**Confidence:** HIGH

## Summary

The goal of this phase is to consolidate the historical internal migrations into a single, clean "squoshed" migration file (`YYYYMMDDHHMMSS_create_rulestead_tables.exs`) that adopters will use when installing Rulestead. This GA-ready baseline will drop legacy fields (`owner`, `expected_expiration`, `permanent`) from both the database schema and the `Rulestead.Flag` Ecto schema, replacing them strictly with `ownership` and `lifecycle` embeds. 

Additionally, it addresses an existing drift by adding the missing `tenant_key` column to the `environment_versions` migration and aligns test factories and golden test fixtures with the new single-file contract. 

**Primary recommendation:** Delete the 16 existing migrations in `priv/repo/migrations` and replace them with a single squoshed migration. Update `Rulestead.Flag` to remove all legacy field casting and compatibility functions, and update `StoreFixtures` and golden test fixtures to reflect the single-file migration and embed-only attributes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Squoshed Migration | Database / Storage | API / Backend | Defines the final installed data model |
| Field Cleanup | API / Backend | Database / Storage | `Rulestead.Flag` and nested schemas must enforce the contract |
| Golden Tests | API / Backend | — | Golden test fixtures ensure the installer output is correct |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | Verified this is a schema and installer phase for host apps. |
| Live service config | None | Verified |
| OS-registered state | None | Verified |
| Secrets/env vars | None | Verified |
| Build artifacts | None | Verified |

## Implementation Details & File Paths

### 1. The Squoshed Migration
**Files to Delete:** 
- `rulestead/priv/repo/migrations/*.exs` (all 16 existing files)

**File to Create:**
- `rulestead/priv/repo/migrations/20260524000000_create_rulestead_tables.exs`

**Instructions:**
Combine the `up` blocks of all deleted migrations into a single cohesive script. 
*   **`flags` table**: Ensure you create `ownership` and `lifecycle` as `:map` columns (JSONB) with `default: fragment("'{}'::jsonb")`. **Do not** include `owner`, `expected_expiration`, or `permanent`. You can also include the check constraints for `lifecycle_requires_mode` and `ownership_requires_owner_ref`.
*   **`environment_versions` table**: Ensure `add(:tenant_key, :string)` is present.
*   **Seed Data**: Include the `INSERT INTO environments` block from the deleted `seed_default_environments.exs`.

### 2. Schema Cleanup (`Rulestead.Flag` & Embeds)
**Files to Modify:**
- `rulestead/lib/rulestead/flag.ex`
- `rulestead/lib/rulestead/flag/ownership.ex`
- `rulestead/lib/rulestead/flag/lifecycle_metadata.ex`

**Instructions:**
*   In `flag.ex`, remove the fields `:owner`, `:expected_expiration`, and `:permanent` from the `schema` block, `cast/3`, `validate_required/3`, and `validate_length/3`.
*   Remove the `normalize_embeds` fallback chain (`normalize_ownership_attr` and `normalize_lifecycle_attr`) since they convert legacy fields to the embeds.
*   Update `validate_lifecycle_mode/1` and `validate_lifecycle_contract/1` to extract `mode` and `review_by` strictly from the `lifecycle` embedded changeset (using `get_change(changeset, :lifecycle)` or `get_field(changeset, :lifecycle)`).
*   In `ownership.ex` and `lifecycle_metadata.ex`, remove the backward-compatibility functions: `default_from_owner/1`, `mode_from_flag/1`, and `default_from_flag/1`.

### 3. Installer Logic
**Files to Modify:**
- `rulestead/lib/rulestead/install/migration_writer.ex`

**Instructions:**
No logic changes are strictly necessary because `File.ls!(@source_dir)` will dynamically pick up the single squoshed migration. However, ensure that the stdout logs are clean and the migration correctly copies.

### 4. Tests and Factories
**Files to Modify:**
- `rulestead/test/support/store_fixtures.ex`
- `rulestead/test/rulestead/integration/install_golden_test.exs`
- `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs`
- `rulestead/test/fixtures/install_golden/tree/priv/repo/migrations/` (Fixture Directory)

**Instructions:**
*   In `StoreFixtures.valid_flag_attrs/1`, replace `owner`, `permanent`, and `expected_expiration` with the direct nested structures:
    ```elixir
    ownership: %{owner_ref: "growth", owner_kind: :team, owner_display: "growth"},
    lifecycle: %{mode: :permanent, review_by: nil, default_source: :operator_required, default_overridden: false}
    ```
*   Update `rulestead/test/fixtures/install_golden/tree/priv/repo/migrations/` by deleting the 16 old migrations and placing a copy of the new `YYYYMMDDHHMMSS_create_rulestead_tables.exs` inside the fixture directory.
*   Update the `STDOUT.txt` fixture (if applicable) since the installer will only output one "copy" statement for migrations instead of 16.
*   Ensure that any test asserting the number of copied migrations (in `rulestead_install_test.exs` or `install_smoke_test.exs`) is updated to expect 1 migration.

## Common Pitfalls
### Pitfall 1: Dangling Constraints in Squoshed Migration
**What goes wrong:** Adopters experience installation failures because of malformed `CHECK` constraints.
**Why it happens:** The `AddPhase35OwnershipLifecycleMetadata` migration added complex `CHECK` constraints requiring specific JSONB shapes. 
**How to avoid:** Ensure the exact Postgres string fragments for constraints (like `flags_ownership_requires_owner_ref`) are ported correctly into the new `execute` statements in the squoshed migration.

### Pitfall 2: `Mix.Task` State Retention in Tests
**What goes wrong:** `InstallGoldenTest` fails on `normalize_tree` because the fixture is outdated or not re-generated correctly.
**How to avoid:** Explicitly copy the newly created migration file into `test/fixtures/install_golden/tree/priv/repo/migrations/` and manually review the updated `STDOUT.txt` fixture to ensure the `copy_migrations` step output accurately reflects the single file copy.

## Standard Stack

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | ~> 3.10 | Migrations & schema | Elixir standard |
