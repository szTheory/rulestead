---
phase: 53
slug: impact-preview-contract
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 53 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix in the `rulestead` package |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs test/rulestead/store/audience_impact_contract_test.exs` |
| **Full suite command** | `cd rulestead && mix test` |
| **Estimated runtime** | Narrow task commands should stay under 60 seconds; full suite runtime depends on database sandbox startup |

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command from its PLAN.md.
- **After every plan wave:** Run all completed wave task commands plus `cd rulestead && mix compile --warnings-as-errors`.
- **Before `$gsd-verify-work`:** Run `cd rulestead && mix test` and `cd rulestead && mix compile --warnings-as-errors`.
- **Max feedback latency:** No implementation task may go more than one commit without an ExUnit or Mix compile command.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | IMP-01, IMP-02, IMP-04 | T-53-01, T-53-02, T-53-03, T-53-05 | Preview payloads are scope-bound, fingerprinted, uncertainty-labeled, and sample evidence is redacted by existing redaction/audit scrub helpers. | unit | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` | missing until task creates it | pending |
| 53-01-02 | 01 | 1 | IMP-01, IMP-04 | T-53-04, T-53-05 | Affected-reference summaries are derived from authored state only and contain no raw actor or sample evidence. | unit | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` | missing until task creates it | pending |
| 53-02-01 | 02 | 1 | IMP-03 | T-53-07, T-53-09, T-53-11 | Runtime snapshots validate and carry compiled audience definitions without live lookup dependencies. | runtime/unit | `cd rulestead && mix test test/rulestead/runtime/audience_snapshot_test.exs test/rulestead/runtime_snapshot_test.exs` | `runtime_snapshot_test.exs` exists; audience snapshot test missing until task creates it | pending |
| 53-02-02 | 02 | 1 | IMP-03 | T-53-07, T-53-08, T-53-10, T-53-12 | `segment_match` evaluation resolves audiences from snapshot-local data and traces missing or archived references without leaking context. | runtime/regression | `cd rulestead && mix test test/rulestead/runtime/audience_snapshot_test.exs test/rulestead/evaluator_test.exs` | `evaluator_test.exs` exists; audience snapshot test missing until task creates it | pending |
| 53-03-01 | 03 | 2 | IMP-01, IMP-02 | T-53-13, T-53-14, T-53-17 | Store commands require preview schema/fingerprint evidence for update, archive, and delete-attempt operations. | release contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | exists | pending |
| 53-03-02 | 03 | 2 | IMP-01, IMP-02 | T-53-14, T-53-17 | Public preview uses admin read authorization and mutation apply uses admin write authorization while failing closed before store mutation on missing confirmation evidence. | facade/security contract | `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/admin_security_contract_test.exs` | admin security test exists; audience impact contract test missing until task creates it | pending |
| 53-03-03 | 03 | 2 | IMP-01, IMP-02 | T-53-13, T-53-15, T-53-18 | Fake adapter rebuilds previews for freshness checks, Redis stays unsupported for new callbacks, and delete attempts fail closed when no delete primitive exists. | adapter contract | `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs` | missing until task creates it | pending |
| 53-04-01 | 04 | 3 | IMP-01, IMP-02, IMP-03 | T-53-19, T-53-20, T-53-24 | Ecto apply rebuilds preview inside the transaction, rejects stale or mismatched evidence, and leaves audience state unchanged on blocked operations. | Ecto contract | `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/store/audience_impact_contract_test.exs` | both phase-specific tests missing until tasks create them | pending |
| 53-04-02 | 04 | 3 | IMP-04 | T-53-21, T-53-23 | Accepted, blocked, and denied mutations persist reconstructable audit evidence without raw PII or telemetry-as-audit shortcuts. | audit contract | `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs test/rulestead/admin_security_contract_test.exs` | admin security test exists; audience audit test missing until task creates it | pending |
| 53-04-03 | 04 | 3 | IMP-03 | T-53-22 | Ecto snapshot publication includes compiled audience definitions consumed by runtime snapshot/evaluator tests. | Ecto/runtime integration | `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/runtime/audience_snapshot_test.exs` | missing until tasks create both phase-specific tests | pending |

Status values: pending, green, red, flaky.

## Wave 0 Requirements

- [ ] `rulestead/test/rulestead/targeting/impact_preview_test.exs` - created by Plan 01 Task 1 before implementation assertions pass.
- [ ] `rulestead/test/rulestead/runtime/audience_snapshot_test.exs` - created by Plan 02 Task 1 before runtime snapshot/evaluator implementation.
- [ ] `rulestead/test/rulestead/store/audience_impact_contract_test.exs` - created by Plan 03 Task 2 before facade/Fake contract implementation.
- [ ] `rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs` - created by Plan 04 Task 1 before Ecto adapter implementation.
- [ ] `rulestead/test/rulestead/audience_mutation_audit_test.exs` - created by Plan 04 Task 2 before audit implementation.

Existing ExUnit infrastructure covers this phase; no framework installation is required.

## Manual-Only Verifications

All Phase 53 behaviors have automated verification through Mix/ExUnit. No manual-only validation is planned.

## Phase Gate Commands

1. `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs`
2. `cd rulestead && mix test test/rulestead/runtime/audience_snapshot_test.exs test/rulestead/runtime_snapshot_test.exs test/rulestead/evaluator_test.exs`
3. `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/admin_security_contract_test.exs test/rulestead/release_contract_test.exs`
4. `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/audience_mutation_audit_test.exs test/rulestead/runtime/audience_snapshot_test.exs test/rulestead/store/audience_impact_contract_test.exs`
5. `cd rulestead && mix compile --warnings-as-errors`
6. `cd rulestead && mix test`

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands in their PLAN.md.
- [x] Sampling continuity: no implementation task lacks automated verification.
- [x] Wave 0 creates missing phase-specific test files before relying on them.
- [x] No watch-mode flags are used.
- [x] Quick feedback commands are scoped to changed test files.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** approved 2026-05-27
