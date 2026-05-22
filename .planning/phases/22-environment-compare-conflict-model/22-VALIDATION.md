# Phase 22: Environment Compare & Conflict Model - Validation Plan

## Goal
Verify that Phase 22 adds a truthful, read-only authored-state compare contract across `rulestead` and `rulestead_admin`, surfacing dependency gaps, target drift, stale-preview conflicts, and operator-facing compare context before any apply behavior exists.

## Dimension 1: Functional Correctness (PROM-01)
- [ ] **Authored-only compare basis:** Verify compare uses flag metadata, published rulesets, and dependency closure rather than runtime snapshots, approvals, or draft rulesets as the promotable basis.
- [ ] **Canonical compare payload:** Verify one backend compare result carries source environment, target environment, compare token, severity summary, typed findings, and per-flag source/current-target/proposed-target sections.
- [ ] **Scoped result set:** Verify summary compare returns only differing or problematic flags, and single-flag drill-in consumes the same payload narrowed by `flag_keys`.

## Dimension 2: Conflict Safety (PROM-02)
- [ ] **Dependency blockers:** Verify missing prerequisite audiences or equivalent authored dependencies surface as `blocker` findings with typed classes.
- [ ] **Stale-preview blockers:** Verify source-changed, target-changed, and stale-token conditions surface as `blocker` findings before any mutation path exists.
- [ ] **Operational and draft warnings:** Verify operational overrides, protected-target notices, missing target `flag_environment` rows, and unpublished source drafts remain warnings or informational notices rather than authored diff input.

## Dimension 3: Contract Stability & Adapter Parity
- [ ] **Scoped compare token:** Verify the compare token changes only when scoped authored inputs or dependency closure change, not from unrelated environment churn.
- [ ] **Schema/version stability:** Verify the compare token and payload include explicit compare schema/version metadata for later Phase 23 and Phase 24 reuse.
- [ ] **Fake/Ecto parity:** Verify both adapters return the same canonical compare shape, severity ordering, and typed finding semantics for equivalent authored inputs.

## Dimension 4: Admin Route, Accessibility, and Phase Safety
- [ ] **Mounted admin routing:** Verify compare routes stay inside the existing `rulestead_admin` session/policy envelope and keep source/target/current-environment state URL-backed.
- [ ] **Read-only posture:** Verify the summary and drill-in pages expose no apply, schedule, submit, or publish controls in Phase 22.
- [ ] **Accessible disclosure:** Verify findings buckets, compare-token metadata, structured diffs, and raw payload disclosure stay keyboard-accessible and understandable without depending on color alone.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs test/rulestead_admin/live/environment_compare_live/accessibility_test.exs`
