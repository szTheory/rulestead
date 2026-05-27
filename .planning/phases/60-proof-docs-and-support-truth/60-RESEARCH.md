# Phase 60 Research — Proof, Docs, And Support Truth

**Researched:** 2026-05-27  
**Phase:** 60-proof-docs-and-support-truth  
**Requirements:** VER-01, VER-02, VER-03

## RESEARCH COMPLETE

---

## Executive Summary

Phase 60 is a **capstone proof/docs phase** — not a feature phase. It mirrors the v1.6 Phase 56 closure pattern exactly: four plans (merge gate → release contract + READMEs → flow guides → CI scope + handoff). All v1.7 governance code (Phases 57–59) is already green; Phase 60 **selects and documents** existing tests rather than rewriting contracts.

**Primary template:** `Mix.Tasks.Verify.Phase56` + Phase 56's four-plan shape documented in `.planning/milestones/v1.6.0-ROADMAP.md`.

---

## D-01: Merge Gate (`mix verify.phase60`)

### Pattern (from `verify.phase56.ex`)

```elixir
# Flat union — do NOT call verify.phase56 or other sub-tasks (avoids duplicate runs)
@phase56_core_tests [ ... ]
@admin_test_paths [ ... ]

def run(_args) do
  Mix.Task.run("test", @phase56_core_tests)
  admin_dir = Path.expand("../../../../rulestead_admin", __DIR__)
  Mix.Task.run("cmd", ["sh", "-c", "cd #{admin_dir} && MIX_ENV=test mix test #{paths}"])
end
```

### Phase 60 core union

**Retain all 17 paths from `@phase56_core_tests`** in `verify.phase56.ex` plus v1.7 governance delta:

| Test file | Covers |
|-----------|--------|
| `test/rulestead/governance/blast_radius_threshold_test.exs` | Threshold evaluation, breach, fail-closed |
| `test/rulestead/governance/audience_mutation_change_request_test.exs` | CR submit/execute envelope |
| `test/rulestead/governance/audience_mutation_change_request_contract_test.exs` | CR contract |
| `test/rulestead/governance/change_request_contract_test.exs` | Existing CR contract |
| `test/rulestead/admin_governance_policy_test.exs` | Host policy seam |

### Phase 60 admin union

**Retain all 8 paths from `@admin_test_paths`** plus governance delta from Phase 59 verification:

| Test file / path | Covers |
|------------------|--------|
| `test/rulestead_admin/components/governance_components_test.exs` | Blast-radius panel |
| `test/rulestead_admin/live/governance_route_contract_test.exs` | No standalone routes |
| `test/rulestead_admin/live/audience_live/governance_test.exs` | Loader, mode/tier |
| `test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs` | Apply vs submit fork |
| `test/rulestead_admin/live/change_request_live/show_test.exs` | Frozen evidence |
| `test/rulestead_admin/live/audience_live/` (directory glob) | Preview/confirm tests incl. edit_preview, archive_preview, archive_confirm |

**Note:** Phase 59 proof used `audience_live/` directory glob — include full directory rather than cherry-picking individual files.

### Registration

Add `"verify.phase60" => :test` to `rulestead/mix.exs` `preferred_envs` alongside phase54–56.

---

## D-02: Release Contract Support Truth

### Template block

Mirror `test "reusable targeting deepening support truth stays bounded..."` at ~L338 in `release_contract_test.exs`.

### New test block: `"blast radius governance support truth stays bounded..."`

**Assert across:** root `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, `MAINTAINING.md`

**Required vocabulary:**
- `mix verify.phase60`
- blast radius, threshold, protected environment, change request
- fail closed, host-owned policy
- preview basis / explicit samples
- package boundary: core domain+validation; admin mounted presentation; not standalone admin
- `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh`

**Forbidden phrases:** Reuse/extend existing lists — no observability-backed counts, no parallel governance workflow, no standalone admin, no auto-advance beyond deferred ROL-04.

**Root README "Proof today":** Add v1.7 blast-radius governance entry **alongside** v1.6 `verify.phase56` — do not remove phase56.

---

## D-03: Flow Guide Updates

### Primary targets (in-place only)

| File | Additions |
|------|-----------|
| `guides/flows/admin-ui.md` | Governed audience mutations in protected envs: preview → submit CR → review → execute; threshold breach vs indeterminate blocked; host policy ownership |
| `guides/flows/multi-env.md` | Protected-environment threshold behavior; direct apply vs CR routing; fail-closed on missing preview/dependency |
| `guides/introduction/user-flows-and-jtbd.md` | Optional: one paragraph on blast-radius governance operator story |

**Teach preview-basis limits:** authored references + explicit samples only; no affected-user counts.

---

## D-04: Quickstart API Parity

### Source of truth

`guides/flows/evaluation.md` — payload-first canonical API.

### Gap today

`guides/introduction/getting-started.md` leads with `Rulestead.enabled?("checkout_v2", conn)` — conn-first mental model.

### Fix

- README and getting-started: build `%Rulestead.Context{}` explicitly, call `Rulestead.evaluate/3` (or `enabled?/get_value/2` with payload + context) as primary example.
- Short note: conn/plug helpers are convenience wrappers when using snapshot cache — secondary.
- `release_contract_test.exs` asserts key evaluation phrases in README + getting-started: `Rulestead.evaluate/3`, explicit context, payload-first language.

---

## D-05: CI Scope and Handoff

### `scripts/ci/test.sh` pattern (from `reusable_targeting_deepening`)

```bash
run_blast_radius_governance/0
  → mix verify.phase60 in rulestead/
  → print_blast_radius_governance_failure_guidance on failure

case blast_radius_governance)
  run_blast_radius_governance
```

Update supported-scopes error message to include `blast_radius_governance`.

### MAINTAINING.md

Add **"Blast Radius Governance Proof"** section:
- Bounded proof scope
- Rerun commands
- Upstream handoff refs: `.planning/phases/57-*`, `58-*`, `59-*` (CONTEXT + VERIFICATION)

### Phase artifacts

- `60-VERIFICATION.md` — required
- `60-HANDOFF-CHECKLIST.md` — optional maintainer release checklist

---

## Four-Plan Execution Shape (D-06)

| Plan | Scope | REQ |
|------|-------|-----|
| 60-01 | `mix verify.phase60` merge gate | VER-01 |
| 60-02 | `release_contract_test.exs` + README/MAINTAINING/package READMEs | VER-02 |
| 60-03 | In-place flow guide updates | VER-02 |
| 60-04 | CI scope, handoff checklist, verification artifact | VER-03 |

**Waves:** 01 (wave 1) → 02+03 (wave 2, parallel) → 04 (wave 3)

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config** | `rulestead/mix.exs`, `rulestead_admin/mix.exs` |
| **Quick run** | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs` |
| **Merge gate** | `cd rulestead && mix verify.phase60` |
| **CI scope** | `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh` |
| **Release contract** | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Estimated runtime** | ~2–4 minutes full phase60 union |

### Per-plan verification map

| Plan | Primary verify command | Requirement |
|------|------------------------|-------------|
| 60-01 | `mix verify.phase60` exits 0 | VER-01 |
| 60-02 | `mix test release_contract_test.exs` (new block green) | VER-02 |
| 60-03 | Manual read + release_contract if guide phrases asserted | VER-02 |
| 60-04 | `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh` | VER-03 |

### Wave 0 requirements

None — all test infrastructure exists from Phases 57–59.

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Calling `verify.phase56` from phase60 duplicates runs | Flat union only — never delegate to sub-tasks |
| Removing phase56 from README breaks v1.6 regression story | Add v1.7 entry alongside, not replacing |
| Over-broad admin test glob slows gate | Match Phase 59 proof scope; directory glob for `audience_live/` |
| Quickstart fix regresses conn-based users | Keep conn example as secondary with explicit note |

---

## Key File References

| Path | Role |
|------|------|
| `rulestead/lib/mix/tasks/verify.phase56.ex` | Merge gate template |
| `rulestead/test/rulestead/release_contract_test.exs` | Support-truth drift guards |
| `scripts/ci/test.sh` | Scoped CI proof bars |
| `MAINTAINING.md` | Maintainer proof sections |
| `guides/flows/evaluation.md` | Payload-first API source of truth |
| `.planning/phases/57-*/57-CONTEXT.md` | Frozen threshold contract |
| `.planning/phases/58-*/58-CONTEXT.md` | Frozen CR contract |
| `.planning/phases/59-*/59-VERIFICATION.md` | Admin test path evidence |

---

## RESEARCH COMPLETE
