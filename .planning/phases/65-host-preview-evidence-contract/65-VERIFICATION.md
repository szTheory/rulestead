---
phase: 65-host-preview-evidence-contract
status: passed
score: 13/13
requirements:
  - IMP-05
  - IMP-06
verified: 2026-05-27
---

# Phase 65 Verification: Host Preview Evidence Contract

**Verified:** 2026-05-27  
**Status:** passed  
**Score:** 13/13 plan must-have truths verified; 2/2 requirement IDs verified  
**Requirements:** IMP-05, IMP-06

## Summary

Phase 65 delivers the host-supplied preview evidence contract: `Rulestead.Targeting.PreviewEvidence` behaviour and facade, fail-closed limits validation, `ImpactPreview` schema v2 with impression fingerprints, Fake/Ecto store wiring before pure `ImpactPreview.build/1`, and adapter contract tests proving stale rejection on evidence drift and GOV-05 reference-count-only boundary. All four plans' must-haves are present in the codebase and pass automated verification.

## Phase Goal Achievement

| Goal element | Status | Evidence |
|--------------|--------|----------|
| Behaviour seam (host resolver) | ✅ | `preview_evidence.ex` — `@callback resolve/1`, `resolver_module/1`, Application env `:preview_evidence_resolver` + opts override |
| ImpactPreview v2 | ✅ | `@schema_version 2`, `impression_evidence`, `impression_fingerprint` in token payload |
| Store wiring (Fake + Ecto) | ✅ | `assemble_preview_evidence_attrs/5` → `PreviewEvidence.resolve/2` → `ImpactPreview.build/1` in both adapters |
| Contract tests: stale rejection | ✅ | `preview_evidence_contract_test.exs` — apply with old fingerprint after impression drift fails on both adapters |
| Contract tests: GOV-05 boundary | ✅ | `blast_radius_threshold_test.exs` — verdict unchanged with huge `impression_evidence` / `sample_evidence` |

## Plan Must-Haves

### 65-01 — Preview Evidence Resolver Seam And Limits (3/3 truths)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| Host configures resolver via Application env or opts override | ✅ | `PreviewEvidence.resolver_module/1` reads `:preview_evidence_resolver` and `Keyword.get(opts, :resolver)` |
| Bounded evidence validated fail-closed before `ImpactPreview.build` | ✅ | `Limits.validate_and_redact/2` — 25-row cap, 16 KiB payload bound, impression allowlist; facade pipes resolver output through limits |
| No resolver configured preserves today's preview path | ✅ | `resolve/2` returns `{:ok, %{}}` when `resolver_module/1` is nil; assembly sets `authored_state_and_explicit_samples` basis |

**Artifacts:** `preview_evidence.ex`, `preview_evidence/query.ex`, `preview_evidence/limits.ex`, `preview_evidence_test.exs` (7 tests)

### 65-02 — ImpactPreview Schema v2 And Evidence Fingerprints (4/4 truths)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| `schema_version` is 2 | ✅ | `@schema_version 2`; `ImpactPreview.schema_version/0` returns 2 |
| `preview_fingerprint` includes `impression_fingerprint` token | ✅ | Token payload at `impact_preview.ex:79` |
| `preview_basis` taxonomy matches D-05 | ✅ | Three bases with matching `@uncertainty_messages`; `preview_basis/1` helper |
| `authoritative_population_count?` remains false | ✅ | Build output sets `authoritative_population_count?: false` for all bases |

**Artifacts:** `impact_preview.ex` (v2), `impact_preview_test.exs` (9 tests)

### 65-03 — Store Adapter Wiring And Fake Test Resolver (3/3 truths)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| `audience_preview_payload` invokes resolver before `ImpactPreview.build` in Fake and Ecto | ✅ | `fake.ex:3951–3958`, `ecto.ex:2834+`; no `PreviewEvidence` references in `impact_preview.ex` |
| Union merge preserves explicit command samples | ✅ | `Limits.merge_samples/3` dedupes with command rows first; contract test "explicit command samples preserved with resolver" |
| No resolver → unchanged preview semantics | ✅ | Assembly nil-resolver branch; contract test "no resolver matches pre-v1.9 semantics" |

**Artifacts:** `fake/preview_evidence_resolver.ex`, updated `fake.ex` and `store/ecto.ex`, `audience_impact_contract_test.exs` resolver describe block

### 65-04 — Contract Tests: Evidence, Stale, Fail-Closed, Parity (3/3 truths)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| Fake and Ecto share contract tests for evidence, stale rejection, fail-closed | ✅ | `@adapters [Rulestead.Fake, StoreEcto]` in `preview_evidence_contract_test.exs` (7 tests) |
| Richer host evidence cannot bypass stale preview on apply | ✅ | Test "apply rejects stale fingerprint when host evidence changes across adapters" (IMP-06) |
| Blast-radius assessment ignores impression summaries (GOV-05 boundary) | ✅ | Test "assess ignores impression_evidence and sample_evidence for verdict"; `blast_radius_threshold.ex` has no `impression` references |

**Artifacts:** `preview_evidence_contract_test.exs`, GOV regression in `blast_radius_threshold_test.exs`

## Requirement Cross-Reference

| Requirement | Phase 65 scope | Status | Evidence |
|-------------|----------------|--------|----------|
| **IMP-05** | Bounded host-supplied sample cohorts and impression summaries through explicit resolver seam; preview basis, uncertainty, redacted evidence without Rulestead-owned observability truth | ✅ | Behaviour + facade + limits; v2 `impression_evidence` / `sample_evidence`; three `preview_basis` values; all with `authoritative_population_count?: false`; opt-in resolver preserves pre-v1.9 path when unset |
| **IMP-06** | Fingerprints and stale-token validation incorporate host evidence metadata deterministically | ✅ | `impression_fingerprint` in `preview_fingerprint/1`; `ensure_fresh_audience_preview/2` compares full fingerprint; contract test proves apply rejection when `matched_impressions` drifts |

**Requirement IDs in plan frontmatter:** IMP-05 appears in 65-01, 65-02, 65-03, 65-04; IMP-06 in 65-02, 65-04. Both accounted for.

**Note:** Full **GOV-05** requirement (blast-radius governance routing) is Phase 66 per `.planning/REQUIREMENTS.md` traceability. Phase 65 correctly proves the **boundary** (D-10): impression/cohort evidence does not feed `BlastRadiusThreshold.assess/2`.

## Phase Boundary Checks (65-CONTEXT)

| Boundary | Status | Evidence |
|----------|--------|----------|
| No resolver inside `ImpactPreview` (runtime purity) | ✅ | Grep: no `PreviewEvidence` in `impact_preview.ex` |
| No Rulestead-owned impression ingestion | ✅ | Resolver is host behaviour only; Fake stub is test-only |
| No impression-weighted blast-radius scoring | ✅ | `blast_radius_threshold.ex` unchanged; regression test passes |
| No audit/CR evidence carry-through | ✅ | Deferred to Phase 66 (IMP-07) — not in this phase's code |
| No mounted admin UI wiring | ✅ | Deferred to Phase 67 (ADM-05) |
| No `mix verify.phase65` | ✅ | Deferred to Phase 68 per CONTEXT |

## Automated Verification Run

```bash
cd rulestead && mix compile --warnings-as-errors          # exit 0
cd rulestead && mix test test/rulestead/targeting/preview_evidence_test.exs \
                        test/rulestead/targeting/impact_preview_test.exs \
                        test/rulestead/targeting/preview_evidence_contract_test.exs \
                        test/rulestead/store/audience_impact_contract_test.exs \
                        test/rulestead/governance/blast_radius_threshold_test.exs
# Finished in 0.4s — 52 tests, 0 failures
```

| Suite | Tests | Failures |
|-------|-------|----------|
| `preview_evidence_test.exs` | 7 | 0 |
| `impact_preview_test.exs` | 9 | 0 |
| `preview_evidence_contract_test.exs` | 7 | 0 |
| `audience_impact_contract_test.exs` | 14 | 0 |
| `blast_radius_threshold_test.exs` | 15 | 0 |

## Error Codes Verified (D-07)

| Code | Verified in |
|------|-------------|
| `preview_evidence_oversized` | `preview_evidence_test.exs`, `preview_evidence_contract_test.exs` |
| `preview_evidence_invalid` | `preview_evidence_test.exs`, `preview_evidence_contract_test.exs` |
| `preview_evidence_policy_denied` | `preview_evidence_test.exs`, `preview_evidence_contract_test.exs` |
| `preview_evidence_resolver_failed` | `preview_evidence_test.exs` (exception rescue path) |

## Gaps

None blocking Phase 65 completion.

**Non-blocking notes:**

- `release_contract_test.exs` still asserts `preview_schema_version: 1` for release-contract surface — intentional per 65-04 summary (not audience mutation fixture).
- Full GOV-05 governance routing requirement ships in Phase 66; Phase 65 only proves impression evidence does not affect `assess/2`.

## Human Verification Items

None required. All acceptance criteria are covered by automated tests and artifact inspection.

## Verdict

**Phase 65 goal achieved.** Core accepts bounded host-supplied preview evidence through an explicit resolver seam, bumps `ImpactPreview` to schema v2 with deterministic evidence fingerprints, wires Fake/Ecto store paths with fail-closed validation, and proves stale apply rejection and GOV-05 scoring boundary via adapter contract tests — ready for Phase 66 audit/change-request evidence carry-through.
