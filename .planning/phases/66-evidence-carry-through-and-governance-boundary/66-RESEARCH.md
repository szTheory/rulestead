# Phase 66: Evidence Carry-Through And Governance Boundary — Research

**Researched:** 2026-05-27
**Status:** Complete (plan-phase inline research; CONTEXT assumptions mode)

## Summary

Phase 66 closes the IMP-07 / GOV-05 gap left by Phase 65: host-supplied preview evidence (`ImpactPreview` schema v2) must appear in support-safe form on audience mutation audit events and change-request metadata, while blast-radius governance routing must remain reference-count-only.

Phase 65 shipped the resolver seam, v2 fingerprint with `impression_fingerprint`, redacted `sample_evidence` / `impression_evidence`, and a unit test proving `BlastRadiusThreshold.assess/2` ignores evidence fields. Phase 66 adds the **carry-through layer** at audit/CR boundaries and **contract-level GOV-05 regression** — no scoring changes.

## Key Findings

### Central helper gap (D-01)
- `ImpactPreview.build/1` already produces redacted evidence fields on the preview map
- No `audit_evidence_summary/1` exists — audit and CR paths would duplicate field extraction
- Recommended keys: `preview_basis`, `preview_schema_version`, `preview_fingerprint`, `uncertainty`, `sample_evidence`, `impression_evidence`, `affected_reference_keys` (keys only, not full reference graph)

### AuditEvent allowlist gap (D-02)
- `AuditEvent.audience_preview_metadata/1` allowlists `sample_evidence` but **not** `impression_evidence`
- `AuditEvent.metadata/1` merges audience preview keys from attrs — missing allowlist entry drops impression evidence even if passed

### Ecto audit wiring gap (D-02)
- `audience_audit_event_changeset/5` passes `sample_evidence` from `opts[:preview]` but **not** `impression_evidence`
- Blocked paths merge `blocked_audience_metadata/1` for blast-radius verdicts; dependency blockers pass partial manual metadata

### Fake audit parity gap (D-02)
- Success path (`append_audit_event` after apply) sets flat metadata with fingerprint/basis/keys only — **no** `sample_evidence` or `impression_evidence`
- Blocked dependency path same partial shape
- Blast-radius blocked uses `blast_radius_blocked_metadata/2` — separate from Ecto changeset path
- Refactor target: shared extraction via `ImpactPreview.audit_evidence_summary/1` from `current_preview` map

### Change-request metadata gap (D-03)
- `AudienceMutationChangeRequest.build_submission_metadata/2` embeds `blast_radius_assessment` + `affected_reference_summary` only
- No `"preview_evidence_summary"` nested key (Phase 58 nesting pattern)
- `audience_mutation_terminal_metadata/2` in Fake and Ecto carries blast-radius fields on reject/cancel but not preview evidence summary

### GOV-05 proof gap (D-04)
- Phase 65 unit test at `blast_radius_threshold_test.exs:139-185` proves `assess/2` parity with/without evidence
- GOV-05 requires contract-level proof:
  - `validate_protected_apply/3` verdict parity with huge impression/sample attrs
  - Full governed submit path with `Fake.PreviewEvidenceResolver` configured → same blast-radius verdict
  - Direct-apply vs change-request routing unchanged with richer preview evidence
- **No changes** to `BlastRadiusThreshold.assess/2` or scoring thresholds

## Recommended Module Touchpoints

| Surface | Change |
|---------|--------|
| `Rulestead.Targeting.ImpactPreview` | Add `audit_evidence_summary/1` |
| `Rulestead.AuditEvent` | Extend `audience_preview_metadata/1` allowlist |
| `Rulestead.Store.Ecto` | Pass impression evidence in changeset; use summary helper |
| `Rulestead.Fake` | Refactor audit metadata to shared summary extraction |
| `Rulestead.Governance.AudienceMutationChangeRequest` | Embed `"preview_evidence_summary"` in submit metadata |
| Fake/Ecto | Extend `audience_mutation_terminal_metadata/2` for CR terminal events |

## Test Strategy

| Behavior | Test file | Pattern |
|----------|-----------|---------|
| Summary helper shape + redaction | `impact_preview_test.exs` | Unit |
| Accepted/blocked/denied audit parity | `audience_mutation_audit_test.exs` | Extend with impression + resolver |
| Fake/Ecto audit parity | New or extended contract test | `@adapters` |
| CR submit + terminal metadata | `audience_mutation_change_request_contract_test.exs` | Extend |
| GOV-05 regression | `blast_radius_threshold_test.exs` + contract | `@adapters` with resolver env |

## Risk Notes

- **Field drift:** Single `audit_evidence_summary/1` prevents Fake/Ecto divergence
- **PII:** Summary must use already-redacted preview fields; never pass raw resolver blobs
- **Backward compat:** Flat audit keys remain; CR uses nested `"preview_evidence_summary"` per Phase 58 pattern
- **Frozen evidence:** CR summary captured at submit from `current_preview` — not re-resolved at execute

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17+) |
| Config | `rulestead/test/test_helper.exs`, `Rulestead.RepoCase` |
| Quick run | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` |
| Audit slice | `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs` |
| CR slice | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_contract_test.exs` |
| GOV slice | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs` |
| Full phase slice | `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs test/rulestead/governance/audience_mutation_change_request_contract_test.exs test/rulestead/governance/blast_radius_threshold_test.exs test/rulestead/governance/preview_evidence_governance_contract_test.exs` |
| Estimated runtime | ~45–120 seconds |

### Automated coverage map

| Behavior | Test type | Command |
|----------|-----------|---------|
| `audit_evidence_summary/1` | unit | `mix test test/rulestead/targeting/impact_preview_test.exs` |
| Audit allowlist + impression | unit | same + audit tests |
| Fake/Ecto accepted audit parity | contract | `mix test test/rulestead/audience_mutation_audit_test.exs` |
| CR frozen summary | contract | `mix test test/rulestead/governance/audience_mutation_change_request_contract_test.exs` |
| GOV-05 full path regression | contract | `mix test test/rulestead/governance/preview_evidence_governance_contract_test.exs` |

### Wave 0

Existing infrastructure covers phase requirements. No new framework install. Add `preview_evidence_governance_contract_test.exs` in plan 66-04.

## RESEARCH COMPLETE
