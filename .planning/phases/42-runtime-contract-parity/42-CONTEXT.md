# Phase 42: Runtime Contract Parity - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Source:** discuss-phase synthesis with one-shot opinionated recommendations

<domain>
## Phase Boundary

Reconcile the `rulestead` runtime schema, Ecto migrations, and the installer-facing database story to ensure they agree on lifecycle and ownership authored-state fields. This phase must resolve the drift between the historical internal migrations and the clean schema adopters expect when they install Rulestead.

**In scope:**
- Consolidating and cleaning up the `priv/repo/migrations` that the installer copies into host apps.
- Dropping legacy duplicate columns (`owner`, `expected_expiration`, `permanent`) from the `flags` table in favor of the new `ownership` and `lifecycle` JSONB embeds.
- Updating `Rulestead.Flag` to accurately map strictly to the new fields without legacy duplication.
- Updating tests, factories, and the `InstallGoldenTest` to match the finalized contract.
- Fixing the missing `tenant_key` column in the `environment_versions` migration.

**Out of scope:**
- Adding new feature flags capabilities or evaluation behaviors.
- Modifying mounted-admin user interface screens beyond updating data requirements.
- Changing OpenFeature bridge implementation.

</domain>

<decisions>
## Implementation Decisions

### 1. Squosh Installer Migrations (The Clean Installer Story)
- **D-01:** Rulestead currently copies 17 separate internal development migrations into the host app. Adopters shouldn't inherit our internal milestone history. Consolidate all historical migrations into a single cohesive `YYYYMMDDHHMMSS_create_rulestead_tables.exs` migration for the installer to copy. 
- **Rationale:** This is highly idiomatic for Elixir libraries entering GA (similar to how Oban manages migrations), providing a single reliable source of truth for the database schema.

### 2. Drop Legacy Lifecycle and Ownership Columns
- **D-02:** Drop the legacy `owner`, `expected_expiration`, and `permanent` columns from the `flags` schema and the new squoshed migration.
- **Rationale:** Phase 35 kept them for "migration/normalization compatibility", but keeping them in the GA schema creates duplicate concepts that confuse adopters (violating PAR-01 and PAR-02). Adopters should only see the `ownership` and `lifecycle` JSONB embeds.

### 3. Reconcile Code and Tests
- **D-03:** Update `Rulestead.Flag` schema to exclusively rely on the `ownership` and `lifecycle` embeds. Drop the direct fields.
- **D-04:** Fix the missing `tenant_key` column on `environment_versions` in the squoshed migration to resolve the `mix test` contract failure observed during Phase 42 research.
- **D-05:** Update the `InstallGoldenTest` and `RulesteadInstallTest` golden outputs to match the new single-file squoshed installer behavior.

</decisions>

<specifics>
## Specific Ideas

- Think of the squoshed migration as the "v1.3.0 stable baseline". Any future migrations will be appended after this baseline.
- `copy_migrations` in the installer will now just copy the single consolidated migration file, making it much simpler and reducing stdout noise.
- Ensure all test factories (`StoreFixtures`, etc.) populate the `ownership` and `lifecycle` structs directly instead of relying on Ecto changesets that map from the legacy fields.

</specifics>
