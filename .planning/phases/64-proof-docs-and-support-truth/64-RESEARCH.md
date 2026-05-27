# Phase 64: Proof, Docs, And Support Truth — Research

**Researched:** 2026-05-27  
**Phase:** 64-proof-docs-and-support-truth  
**Requirements:** VER-01, VER-02, VER-03

## RESEARCH COMPLETE

## Executive Summary

Phase 64 is the v1.8 capstone — mirror Phase 60 (v1.7) exactly. All v1.8 auto-advance contracts are already implemented and green in Phases 61–63; Phase 64 wires proof (`mix verify.phase64`), release-contract drift guards, host seam + flow docs, and CI scope `guarded_rollout_auto_advance`. No core/admin contract changes.

## Key Findings

### Merge gate pattern (VER-01)

**Template:** `rulestead/lib/mix/tasks/verify.phase60.ex`

- Flat `@phase60_core_tests` list (22 paths) — copy verbatim into `verify.phase64.ex`
- Admin subprocess via `Path.expand("../../../../rulestead_admin", __DIR__)`
- **Never** delegate to `verify.phase60` or other sub-tasks

**v1.8 core delta (5 paths — all exist and green):**

| Path | Covers |
|------|--------|
| `test/rulestead/rollout_auto_advance_contract_test.exs` | Policy persistence, eligibility |
| `test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` | Healthy advance, blocked tick, protected-env CR, idempotency, manual race |
| `test/rulestead/guardrails/auto_advance_test.exs` | Pure fail-closed evaluator |
| `test/rulestead/guarded_rollout_test.exs` | ROL-07 hold/rollback preserved with auto-advance |
| `test/rulestead/scheduled_execution_conflict_test.exs` | Idempotency/conflict races |

**v1.8 admin delta (2 paths — not in phase60 admin list):**

| Path | Covers |
|------|--------|
| `test/rulestead_admin/live/flag_live/rollouts_test.exs` | Auto-advance panel, six fail-closed modes, policy save |
| `test/rulestead_admin/live/flag_live/timeline_test.exs` | `guardrail_automation` vs manual timeline labels |

**Registration:** Add `{:"verify.phase64", :test}` to `rulestead/mix.exs` `preferred_envs` (line ~25, alongside phase60).

### Release contract (VER-02/03)

**Template:** `release_contract_test.exs` blast-radius block (~L410)

**Forbidden phrase updates (CONTEXT D-02):**

1. **Guarded rollout block (~L328):** Remove `"auto-advance"` from `forbidden_phrases` — feature now shipped with bounded claims
2. **Blast-radius block (~L460):** Remove `"auto-advance guarded rollouts"` — v1.8 delivers ROL-04

**New test block:** `"guarded rollout auto-advance support truth stays bounded across root package and maintainer docs"`

**Required asserts (root README):**

- `mix verify.phase64`
- `observation window` or `observation-window`
- `authored next-stage` or `next-stage plan`
- `guardrail_automation`
- `fail closed`
- `host-owned` (metrics/signals)
- `mix verify.phase60` and `mix verify.phase56` preserved
- `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh`

**Forbidden (retain + extend):**

- built-in observability, fleet dashboards, self-healing rollouts, time-based percentage rollout, metrics ingestion, standalone admin, automatic progressive delivery platform

### CI scope (VER-03)

**Template:** `scripts/ci/test.sh` `run_blast_radius_governance/0` (~L223)

Add `guarded_rollout_auto_advance` scope calling `mix verify.phase64` with failure guidance mirroring blast-radius pattern.

Update supported-scopes error (~L317) to include `guarded_rollout_auto_advance`.

### Docs gaps

| File | Current state | Phase 64 action |
|------|---------------|-----------------|
| `prompts/rulestead-host-app-integration-seam.md` | No auto-advance subsection | Add after Oban/workers ~§7 |
| `guides/flows/admin-ui.md` | No auto-advance content | Extend in place |
| `guides/flows/rollout.md` | No observation window content | Extend in place |
| `README.md` Proof today | Has v1.6/v1.7 entries only | Add v1.8 auto-advance bullet |
| `MAINTAINING.md` | Has Guarded Rollout Foundations + Blast Radius | Add Guarded Rollout Auto-Advance Proof section |

### Prior phase verification evidence

- `61-VERIFICATION.md` — policy contract, pure eligibility
- `62-VERIFICATION.md` — scheduled tick, `guardrail_automation` audit, protected-env CR
- `63-VERIFICATION.md` — mounted panel, six modes, timeline labeling

## Validation Architecture

| Dimension | Approach |
|-----------|----------|
| Merge gate | `mix verify.phase64` — single maintainer command |
| Contract drift | `release_contract_test.exs` string asserts + forbidden phrases |
| CI scope | `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance` |
| Docs parity | Host seam + flow guides + README/MAINTAINING |
| Regression | `verify.phase60` and `verify.phase56` remain valid; phase64 is superset |

**Wave 0:** Not required — all test files exist from Phases 61–63.

**Per-plan verify commands:**

| Plan | Primary verify |
|------|----------------|
| 64-01 | `cd rulestead && mix verify.phase64` |
| 64-02 | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| 64-03 | grep asserts on guide files + release_contract green |
| 64-04 | `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` |

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Delegating to verify.phase60 duplicates runs | medium | Flat union only |
| Removing forbidden phrases too broadly | medium | Remove only the two stale entries; new block enforces bounded vocabulary |
| Docs overclaim observability/metrics | high | Forbidden phrases + host-owned signals language |
| Changing core/admin contracts | high | Phase 64 selects existing tests; no contract rewrites |

## Four-plan shape (locked in CONTEXT D-05)

1. **64-01** — `mix verify.phase64` merge gate (VER-01)
2. **64-02** — release_contract + README/MAINTAINING/package READMEs (VER-02/03)
3. **64-03** — host seam + flow guide updates (VER-02)
4. **64-04** — CI scope + verification artifact + handoff (VER-03)
