# Phase 68: Proof, Docs, And Support Truth — Research

**Researched:** 2026-05-27  
**Phase:** 68-proof-docs-and-support-truth  
**Requirements:** VER-01, VER-02, VER-03

## RESEARCH COMPLETE

## Executive Summary

Phase 68 is the v1.9 capstone — mirror Phase 64 (v1.8) and Phase 60 (v1.7) exactly. Preview-evidence contracts are implemented and green in Phases 65–67; Phase 68 wires proof (`mix verify.phase68`), release-contract drift guards, host seam + flow docs, and CI scope `host_preview_evidence`. No core/admin contract changes.

## Key Findings

### Merge gate pattern (VER-01)

**Template:** `rulestead/lib/mix/tasks/verify.phase64.ex`

- Flat `@phase64_core_tests` list (27 paths) — copy verbatim into `verify.phase68.ex`
- Admin subprocess via `Path.expand("../../../../rulestead_admin", __DIR__)`
- **Never** delegate to `verify.phase64`, `verify.phase60`, or other sub-tasks

**v1.9 core delta (3 paths — all exist and green from Phases 65–66):**

| Path | Covers |
|------|--------|
| `test/rulestead/targeting/preview_evidence_contract_test.exs` | Resolver wiring, redaction, fingerprint determinism, stale rejection with evidence, Fake/Ecto parity |
| `test/rulestead/targeting/preview_evidence_test.exs` | ImpactPreview v2 fields, basis/uncertainty taxonomy |
| `test/rulestead/governance/preview_evidence_governance_contract_test.exs` | GOV-05 boundary — blast-radius ignores impression/sample evidence |

**v1.9 admin delta (1 path — not in phase64 admin list):**

| Path | Covers |
|------|--------|
| `test/rulestead_admin/components/audience_components_test.exs` | Sample/impression sections, basis copy, display limits |

Phase 64 admin subprocess already includes `test/rulestead_admin/live/audience_live` (edit/archive/delete preview tests from Phase 67). Only `audience_components_test.exs` is missing from the union.

**Registration:** Add `{:"verify.phase68", :test}` to `rulestead/mix.exs` `preferred_envs` (alongside phase64).

### Release contract (VER-02/03)

**Template:** `release_contract_test.exs` guarded-rollout auto-advance block (~L468)

**New test block:** `"host preview evidence support truth stays bounded across root package and maintainer docs"`

**Required asserts (root README):**

- `mix verify.phase68`
- Bounded vocabulary: `preview_evidence_resolver`, `host-supplied`, `sample cohort`, `impression summary`, `authoritative_population_count`
- `fail closed` (invalid/oversized/policy-denied evidence)
- `mix verify.phase64`, `mix verify.phase60`, `mix verify.phase56` preserved
- `RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh`

**Forbidden (retain + extend for preview evidence):**

- authoritative population, fleet-wide population, built-in observability, Rulestead dashboard, metrics ingestion, fleet dashboard, impression analytics platform, population analytics product

**Do not remove** v1.8 auto-advance forbidden-phrase relaxations from Phase 64.

### CI scope (VER-03)

**Template:** `scripts/ci/test.sh` `run_guarded_rollout_auto_advance/0`

Add `host_preview_evidence` scope calling `mix verify.phase68` with:

- `run_mix rulestead_admin deps.get` **before** `verify.phase68` (WR-01 lesson from Phase 64)

Update supported-scopes error to include `host_preview_evidence`.

### Docs gaps

| File | Current state | Phase 68 action |
|------|---------------|-----------------|
| `prompts/rulestead-host-app-integration-seam.md` | No preview-evidence subsection | Add after audience/governance ~§8: `PreviewEvidenceResolver` behaviour, opt-in config, redaction, no warehouse ingestion |
| `guides/flows/admin-ui.md` | No preview evidence content | Extend: sample cohort + impression summary on audience previews, fail-closed errors |
| `guides/flows/flag-lifecycle.md` or `guides/flows/explainability.md` | No preview basis copy | Extend in place: `preview_basis`, uncertainty, no authoritative population |
| `README.md` Proof today | Has v1.6–v1.8 entries only | Add v1.9 host preview evidence bullet |
| `MAINTAINING.md` | Lists preview test files in mounted section | Add **Host Preview Evidence Proof** section with `mix verify.phase68` |

### Prior phase verification evidence

- `65-VERIFICATION.md` — resolver contract, ImpactPreview v2, stale fingerprint
- `66-VERIFICATION.md` — audit/CR evidence summaries, GOV-05 boundary
- `67-VERIFICATION.md` — mounted rendering, forbidden copy guard, confirm fingerprint carry-through

## Validation Architecture

| Dimension | Approach |
|-----------|----------|
| Merge gate | `mix verify.phase68` — single maintainer command |
| Contract drift | `release_contract_test.exs` string asserts + forbidden phrases |
| CI scope | `RULESTEAD_TEST_SCOPE=host_preview_evidence` |
| Docs parity | Host seam + flow guides + README/MAINTAINING |
| Regression | `verify.phase64`, `verify.phase60`, `verify.phase56` remain valid; phase68 is superset |

**Wave 0:** Not required — all test files exist from Phases 65–67.

**Per-plan verify commands:**

| Plan | Primary verify |
|------|----------------|
| 68-01 | `cd rulestead && mix verify.phase68` |
| 68-02 | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| 68-03 | grep asserts on guide files + release_contract green |
| 68-04 | `RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh` |

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Delegating to verify.phase64 duplicates runs | medium | Flat union only |
| Docs claim authoritative population or fleet analytics | high | Forbidden phrases + `authoritative_population_count?: false` language |
| Admin deps.get after verify (Phase 64 WR-01) | medium | deps.get rulestead_admin before verify.phase68 |
| Changing core/admin contracts | high | Phase 68 selects existing tests; no contract rewrites |

## Planner Notes

- Four-plan shape mirrors Phase 64: merge gate → release contract/READMEs → host seam/flows → CI + verification artifact
- Phase directory has no CONTEXT.md; decisions derived from ROADMAP success criteria + Phase 64/65/67 artifacts
