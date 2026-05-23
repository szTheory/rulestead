# Phase 34: Milestone Auditability Backfill - Patterns

## Canonical Patterns

### Pattern 1: Phase-level summaries use requirement frontmatter plus a compact execution narrative

- `29-SUMMARY.md`, `31-SUMMARY.md`, and `33-SUMMARY.md` are the current examples.
- The summary should list completed requirement IDs in frontmatter and then aggregate plan-level outcomes without duplicating every task detail.

### Pattern 2: Verification reports prove phase truths with reproducible commands

- Recent verification docs use frontmatter, a phase-goal header, an observable-truths table, requirements coverage, and explicit commands/results.
- Reconstructed verification should prefer commands that can still run now over undocumented one-off historical observations.

### Pattern 3: Milestone audits should be regenerated from currently checked-in evidence

- `REQUIREMENTS.md`, phase summaries, verification docs, and roadmap status are the current truth set.
- If an earlier milestone audit disagrees with later completed phases, refresh the audit instead of trying to preserve the stale mismatch.

### Pattern 4: Documentation backfill phases stay inside `.planning/`

- This phase should not touch `rulestead/` or `rulestead_admin/` production code unless a rerun of targeted suites proves a real missing fix.
- The default expectation is planning-doc-only output.

## File Anchors

- `.planning/v1.1.0-MILESTONE-AUDIT.md`
  - Current stale milestone scorecard and identified tech debt.
- `.planning/REQUIREMENTS.md`
  - Current tenancy requirement completion truth.
- `.planning/STATE.md`
  - Current activity log proving Phases 30, 32, and 33 were completed and verified.
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-01-SUMMARY.md`
  - Plan-level execution outcome for mounted session and shell scope.
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-02-SUMMARY.md`
  - Plan-level execution outcome for compare route tenant carry-through.
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-VALIDATION.md`
  - Existing validation dimensions and expected verification commands for Phase 30.
- `.planning/phases/29-tenancy-helpers-validation/29-SUMMARY.md`
- `.planning/phases/31-audit-tenant-provenance-enforcement/31-SUMMARY.md`
- `.planning/phases/33-compare-drill-in-preview-identity-closure/33-SUMMARY.md`
  - Canonical phase-summary shapes to mirror.

## Reusable Helpers

- `requirements-completed` frontmatter in phase-level summary files
- verification-report frontmatter fields: `phase`, `verified`, `status`, `score`
- `rg -n` and `test -f` for document integrity checks
- targeted `mix test` commands already listed in `30-VALIDATION.md`

## Anti-Patterns

- Reopening tenancy feature work inside Phase 34.
- Claiming milestone gaps still exist after Phases 32 and 33 without rerunning the audit.
- Writing a Phase 30 verification file that cannot be traced to current docs or rerunnable commands.
- Expanding the phase into milestone archival or future-roadmap work before the active audit inputs are internally consistent.

## Test Anchors

- `rulestead_admin/test/rulestead_admin/live/session_test.exs`
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs`
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs`
- `rulestead/test/rulestead/promotion/compare_test.exs`
- `rulestead/test/rulestead/store/compare_contract_test.exs`

## Practical Direction

- Create `30-SUMMARY.md` first so Phase 30 regains the standard traceability shape.
- Create `30-VERIFICATION.md` second, using `30-VALIDATION.md` and rerunnable targeted suites as the evidence skeleton.
- Refresh `v1.1.0-MILESTONE-AUDIT.md` only after those Phase 30 artifacts exist.
- Keep all Phase 34 execution output bounded to `.planning/` unless verification reruns expose a real product regression.
