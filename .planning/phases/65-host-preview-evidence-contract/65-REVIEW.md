---
phase: 65
status: issues_found
reviewed: 2026-05-27
depth: standard
---

# Phase 65 Code Review: Host Preview Evidence Contract

**Scope:** Preview evidence resolver seam, limits validation, ImpactPreview v2, Fake/Ecto store wiring, test resolver.

**Verdict:** Implementation is structurally sound — runtime purity preserved, PII redaction and fail-closed resolver errors are well-tested, stale fingerprint semantics cover evidence drift. Two correctness gaps in store assembly (`preview_basis` labeling and D-07 limit scope) warrant fixes before treating the phase as fully closed.

## Summary

| Area | Assessment |
|------|------------|
| Security (PII / fail-closed) | Strong — allowlisted redaction via `Redaction.redact_metadata/2`, impression key allowlist rejects unknown fields, resolver exceptions/denials/oversize map to stable error codes |
| Runtime purity | Clean — `ImpactPreview.build/1` and `preview_fingerprint/1` have zero `PreviewEvidence` references; I/O confined to store `assemble_preview_evidence_attrs/5` |
| Correctness (fingerprint / stale) | Good — v2 token includes `sample_fingerprint` + `impression_fingerprint`; contract tests prove apply rejection on impression drift |
| Correctness (merge / basis) | One labeling bug when resolver returns empty but command carries explicit samples |
| Limits enforcement | Resolver path capped at 25 rows via `merge_samples/3`; no-resolver and post-merge payload-size paths have gaps vs D-07 wording |

## Findings

| ID | Severity | File(s) | Finding | Recommendation |
|----|----------|---------|---------|----------------|
| F-01 | Warning | `fake.ex`, `store/ecto.ex` | **`preview_basis` mislabels explicit-only samples as host evidence.** When a resolver is configured but returns empty evidence, `preview_evidence_present?/2` checks `merged_samples` (command ∪ resolver). Explicit `command.samples` alone satisfy the predicate, so basis becomes `"authored_state_with_host_evidence"` even though the host resolver supplied nothing — contradicts D-05. | Derive basis from resolver-returned evidence only. Add contract test: resolver empty + explicit command samples → `"authored_state_and_explicit_samples"` or `"authored_state_host_evidence_unavailable"`. |
| F-02 | Warning | `preview_evidence/limits.ex`, `fake.ex`, `store/ecto.ex` | **D-07 row cap not enforced on no-resolver path.** The nil-resolver branch passes `command_samples` through unchanged; a caller can exceed 25 rows without hitting `preview_evidence_oversized`. | After assembly (both branches), enforce `length(samples) <= Limits.max_sample_rows()` or route all samples through `merge_samples(command_samples, [], opts)` even when resolver is nil. |
| F-03 | Warning | `preview_evidence/limits.ex`, `fake.ex`, `store/ecto.ex` | **16 KiB payload bound applies to resolver output only, not merged preview attrs.** `enforce_payload_size!/1` runs inside `Limits.validate_and_redact/2` before command samples are merged. | Re-run `Limits.enforce_payload_size!/1` on the final attrs map in `assemble_preview_evidence_attrs/5` before returning `{:ok, attrs}`. |
| F-04 | Info | `fake.ex`, `store/ecto.ex` | **Unreachable `:empty` error branch.** Both adapters pattern-match `{:error, %Rulestead.Error{metadata: %{reason: :empty}}}` but `PreviewEvidence.resolve/2` never emits `reason: :empty`. | Remove the branch or implement `:empty` in the facade if soft-empty semantics are still desired. |
| F-05 | Info | `preview_evidence/limits.ex`, `impact_preview.ex` | **Duplicated allowlists.** `@sample_allowlist` and `@impression_allowlist` are copy-pasted across `Limits` and `ImpactPreview`. | Extract shared constants or add a test asserting parity. |
| F-06 | Info | `fake.ex`, `store/ecto.ex` | **~85-line duplicate `assemble_preview_evidence_attrs/5`.** Intentional per 65-03 to avoid compile-dep cycle. | Consider `Rulestead.Targeting.PreviewEvidence.Assembly` extract once module graph allows. |

## Recommended Follow-up

1. Fix F-01 (basis labeling) — highest operator-trust impact.
2. Close F-02/F-03 limit gaps with a single post-assembly validation call in both adapters.
3. Optional hygiene: F-04–F-06 in a follow-up plan or Phase 66.
