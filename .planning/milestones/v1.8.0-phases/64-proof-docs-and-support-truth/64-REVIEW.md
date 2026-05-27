---
phase: 64-proof-docs-and-support-truth
reviewed: 2026-05-27T22:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - rulestead/lib/mix/tasks/verify.phase64.ex
  - rulestead/mix.exs
  - rulestead/test/rulestead/release_contract_test.exs
  - rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
  - scripts/ci/test.sh
  - README.md
  - rulestead/README.md
  - rulestead_admin/README.md
  - MAINTAINING.md
  - prompts/rulestead-host-app-integration-seam.md
  - guides/flows/admin-ui.md
  - guides/flows/rollout.md
  - guides/introduction/user-flows-and-jtbd.md
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues
---

# Phase 64: Code Review Report

**Reviewed:** 2026-05-27T22:00:00Z  
**Depth:** standard  
**Files Reviewed:** 13  
**Status:** issues

## Summary

Phase 64 is a proof-and-docs capstone: `mix verify.phase64` unions phase60 core regression with five v1.8 auto-advance delta paths and an admin subprocess (rollouts + timeline), `release_contract_test.exs` enforces bounded support truth, and `scripts/ci/test.sh` adds `guarded_rollout_auto_advance` for maintainer reruns. No core/admin feature code beyond orchestration contract isolation fixes.

**Security assessment:** No new runtime surfaces. Orchestration test `DELETE FROM` uses a static table list (test-only). `verify.phase64` admin subprocess uses `sh -c` with a path derived from `Path.expand/2` (not user input). Release-contract tests continue to assert telemetry/command metadata stripping for PII-adjacent keys.

**Quality assessment:** Merge-gate composition matches `64-CONTEXT.md` D-01 (27 core paths, 11 admin paths, no sub-task delegation). VER-01 scenarios are covered in the flat union. One CI ordering inconsistency vs `run_guarded_rollout_foundations` remains. Docs and contract tests align; `mix test test/rulestead/release_contract_test.exs` and `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` pass locally.

---

## Findings

### WR-01 — `guarded_rollout_auto_advance` CI scope installs admin deps after `verify.phase64`

**Severity:** warning  
**Requirement ref:** VER-03 (CI scope reruns)  
**Files:** `scripts/ci/test.sh`

```294:321:scripts/ci/test.sh
run_guarded_rollout_auto_advance() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead "${log_file}" verify.phase64; then
      if run_mix_logged rulestead_admin "${log_file}" deps.get; then
        :
```

`verify.phase64` runs `mix test` in `rulestead_admin` via subprocess **before** `rulestead_admin deps.get` in this scope. Sibling packages are not linked in `rulestead/mix.exs`, so a clean checkout can fail the admin subprocess with dependency errors even though the trailing `deps.get` would have fixed it.

**Contrast:** `run_guarded_rollout_foundations/0` runs `rulestead_admin deps.get` before admin tests (L175–178). `mounted-proof` CI job also pre-installs both packages (`.github/workflows/ci.yml` L187–190).

**Impact:** Maintainer/local reruns on fresh clones may flake or mis-categorize failures as contract regressions; post-success `deps.get` only validates resolution, not test prerequisites.

**Recommendation:** Run `run_mix rulestead_admin deps.get` (and optionally compile) **before** `verify.phase64`. Mirror the same fix in `run_blast_radius_governance/0` and `run_reusable_targeting_deepening/0` for consistency.

---

### IN-01 — Auto-advance forbidden-phrase refutes skip `rulestead/README.md`

**Severity:** info  
**Requirement ref:** VER-03  
**Files:** `rulestead/test/rulestead/release_contract_test.exs`

The new `guarded rollout auto-advance support truth` block asserts positive phrases on `runtime_readme` but applies `forbidden_phrases` only to `[root_readme, admin_readme, maintaining]`. A future overclaim in `rulestead/README.md` would not trip the refute loop.

**Recommendation:** Include `runtime_readme` in `operator_docs` for the auto-advance forbidden list (same pattern as blast-radius block).

---

### IN-02 — `guarded_rollout_auto_advance` is maintainer-local, not a CI workflow job

**Severity:** info  
**Files:** `scripts/ci/test.sh`, `.github/workflows/ci.yml`

The new scope is documented in README/MAINTAINING and passes when invoked locally, but `ci.yml` does not run it (unlike `mounted-proof` / `openfeature-companion`). Default `test` scope runs full `mix test` for both packages, which is a superset but slower.

**Impact:** No regression signal if someone breaks only the phase64 union paths without running full suite or `mix verify.phase64` before merge.

**Recommendation:** Accept as intentional bounded proof, or add a path-filtered job when auto-advance paths change (mirror `mounted-proof`).

---

### IN-03 — Orchestration suite isolation uses unordered `DELETE FROM` per table

**Severity:** info  
**Files:** `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs`

```196:202:rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
  defp reset_adapter!(StoreEcto) do
    for table <- ~w(
         execution_attempts approvals change_requests scheduled_executions
         rollout_auto_advance_policies audit_events rulesets flag_environments flags
       ) do
      Repo.query!("DELETE FROM #{table}")
```

Table names are static. Order is child-before-parent today; a new FK between listed tables could make resets order-sensitive. Clearing `admin_policy` in `setup` (L19–23) correctly fixes the phase64 full-suite isolation bug from 64-01.

**Recommendation:** Consider `Ecto.Adapters.SQL.Sandbox` restart or `TRUNCATE ... CASCADE` if FK graph grows.

---

## Positive Observations

- **`verify.phase64.ex`:** Flat 27-path core union matches phase60 + five documented deltas; admin paths add only `rollouts_test.exs` and `timeline_test.exs`. No `verify.phase60` delegation (grep-clean).
- **`release_contract_test.exs`:** Auto-advance block asserts `mix verify.phase64`, CI scope string, observation-window vocabulary, `guardrail_automation`, and host-owned boundaries; forbidden lists were trimmed per D-02 (no blanket `"auto-advance"` in v1.5 block).
- **Orchestration isolation fix:** Deleting `admin_policy` during setup restores production governed defaults under `AllowPolicy` in `test_helper` — correct root cause for protected-env test flake.
- **Docs:** Host seam subsection and in-place flow guides repeat fail-closed, host-owned signals, and explicit non-claims without new standalone docs.

---

## Verification Performed

| Command | Result |
|---------|--------|
| `cd rulestead && mix test test/rulestead/release_contract_test.exs` | 18 tests, 0 failures |
| `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` | Exit 0 |

---

## Requirements Traceability

| Requirement | Review note |
|-------------|-------------|
| **VER-01** | Merge gate paths cover healthy advance, blocked tick, protected-env CR, idempotency/race, stale signals (`guardrails/auto_advance_test.exs`), hold/rollback (`guarded_rollout_test.exs`). |
| **VER-02** | Release contract + README/package/flow docs enforce bounded vocabulary. |
| **VER-03** | CI scope present; WR-01 ordering weakens isolated rerun ergonomics. |

---

*Phase: 64-proof-docs-and-support-truth*
