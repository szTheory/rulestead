# Phase 25: Tenancy Helpers Validation - Completion Summary

**Date:** 2026-05-19

## Actions Completed
- Added `tenant_key` fields to `EnvironmentVersion` and `Manifest.Plan` schemas to establish the durable persistence bounds.
- Added `tenant_key` support to `CompareEnvironments`, `ApplyPromotion`, and `ApplyManifestImport` commands.
- Updated `Rulestead.export_manifest` and `Rulestead.Manifest.Export` to include `tenant_key` metadata on exports to restrict snapshot boundaries.
- Modified `Manifest.Import` preview and apply stages to detect tenant scope drift (widening and mismatches).
- Added `validate_target_tenant` to `Manifest.Import` and `Rulestead.apply_promotion_plan` to block execution when the target tenant no longer matches the plan.
- Updated `Promotion.Compare` to consider `tenant_key` during `compare_token` computation, causing mismatched `ApplyPromotion` commands to correctly evaluate as stale previews.
- Modified the test schema for `environment_versions` to include `tenant_key` inside both adapter test contracts (`manifest_import_contract_test.exs` and `promotion_apply_contract_test.exs`).
- Wrote tests in `import_test.exs` and `apply_test.exs` to verify tenant mismatch is rejected across plans and application surfaces.

## Success Criteria Evaluation
- **Bounded Tenant Fields**: `tenant_key` field added to `EnvironmentVersion`, `Manifest.Plan`, and corresponding adapter persistence logic.
- **Save Tenant Mismatch Reject**: `apply_promotion_plan` and `Import.apply` properly validate and reject drifting tenant scope, translating the failure into standard block findings.
- **Compare Warning**: `compare_token` explicitly hashes the requested `tenant_key`, naturally surfacing staleness findings when parameters drift during revalidation, avoiding redundant validation shapes.
- **Backward Compatibility**: `tenant_key` remains an optional `nil` field, allowing all-tenant workflows to function smoothly as before.

## State
Phase 25 completed successfully.