# Phase 24: GitOps Manifests & CLI Surface - Validation Plan

## Goal
Verify that Phase 24 adds deterministic, reviewable, and preview-first GitOps automation across `rulestead` without bypassing the existing governed promotion envelope, without widening into tenancy helpers, and without turning `rulestead_admin` into a standalone release-orchestration product.

## Dimension 1: Manifest Contract Correctness (MAN-01)
- [ ] **Environment-bounded authored export:** Verify export emits one canonical JSON manifest for one environment at a time, built from published authored state only rather than runtime snapshots, drafts, or governance metadata.
- [ ] **Deterministic semantic serialization:** Verify repeated exports for unchanged authored state produce byte-for-byte identical JSON with stable ordering of flags, dependency references, and nested semantic fields.
- [ ] **Shared parser/serializer contract:** Verify the manifest loader and serializer round-trip one canonical manifest shape that later validate, diff, and import flows consume without ad hoc per-task decoding.

## Dimension 2: Validation, Diff, and Output Stability (MAN-02)
- [ ] **Canonical result envelope:** Verify validate and diff render one shared semantic result envelope in both text and `--format json` modes rather than divergent human and machine DTOs.
- [ ] **Locked status and exit-code contract:** Verify `validate` and `diff` map clean success, changes, blocked/invalid/stale outcomes, and system failures onto the locked Phase 24 status vocabulary and exit codes `0`, `2`, `3`, and `1`.
- [ ] **Compare vocabulary reuse:** Verify diff findings reuse the Phase 22 compare semantics and stable ordering instead of inventing a second CLI-only taxonomy.

## Dimension 3: Import Preview / Apply Safety (MAN-03)
- [ ] **Saved-plan-only apply:** Verify manifest import preview emits a deterministic saved plan artifact and apply refuses raw manifests, requiring a previously generated plan plus explicit `--reason`.
- [ ] **Adapter-backed parity:** Verify Ecto and Fake enforce the same additive-only manifest import contract, including stale-plan rejection, dependency closure checks, archived dependency blocking, and protected-target governance-required posture.
- [ ] **No destructive widening:** Verify import omits prune, archive/revive, force, and tenancy-expanding semantics from both domain and CLI surfaces.

## Dimension 4: Promote CLI and Governance Reuse (MAN-03, MAN-04)
- [ ] **Saved promote plan artifact:** Verify promote preview emits a reviewed plan artifact carrying compare token, fingerprints, dependency closure, and bounded scope from the existing compare contract.
- [ ] **Governed protected-target apply:** Verify promote apply reloads only a saved plan artifact and routes protected targets through the existing governed action path instead of creating a CLI side door.
- [ ] **Stale promotion rejection:** Verify compare-token drift, fingerprint drift, and dependency drift surface as domain rejection rather than process failure during promote apply.

## Dimension 5: Public Task Surface and Phase Boundary (MAN-04)
- [ ] **Five separate Mix tasks:** Verify the public automation surface is exactly `mix rulestead.export`, `mix rulestead.validate`, `mix rulestead.diff`, `mix rulestead.import`, and `mix rulestead.promote`, with no bespoke umbrella subcommand shell.
- [ ] **Explicit scope and Unix-friendly I/O:** Verify tasks require explicit environment/source/target scope where needed, support `-` for stdin/stdout where promised, and keep JSON stdout pure in machine mode.
- [ ] **Phase-safe product shape:** Verify Phase 24 stays inside `rulestead` automation seams, preserves the linked-version sibling-package posture, avoids Phase 25 tenancy helpers, and does not publish or evolve `rulestead_admin` into a standalone control plane.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/manifest/export_test.exs test/rulestead/manifest/load_test.exs test/rulestead/store/manifest_export_contract_test.exs test/rulestead/mix/tasks/rulestead_export_test.exs`
- `cd rulestead && mix test test/rulestead/manifest/validate_test.exs test/rulestead/manifest/diff_test.exs test/rulestead/mix/tasks/rulestead_validate_test.exs test/rulestead/mix/tasks/rulestead_diff_test.exs`
- `cd rulestead && mix test test/rulestead/manifest/import_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/mix/tasks/rulestead_import_test.exs`
- `cd rulestead && mix test test/rulestead/store/promotion_governed_apply_contract_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs`
