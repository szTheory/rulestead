# Requirements: v1.9.0 - Host-Supplied Preview Evidence

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions - booleans, variants, and remote config - with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.9.0 Requirements

### Host Preview Evidence Contract (`IMP`)

- [x] **IMP-05**: Audience impact previews accept bounded, host-supplied sample cohorts and impression summaries through an explicit resolver seam; payloads declare preview basis, uncertainty, and redacted evidence without claiming Rulestead-owned identity or observability truth.
- [x] **IMP-06**: Preview fingerprints, stale-token validation, and apply paths incorporate host evidence metadata deterministically so richer evidence cannot bypass stale preview rejection or drift checks.
- [x] **IMP-07**: Audit events and change-request payloads for audience mutations carry support-safe preview evidence summaries (basis, bounded sample/impression metadata, redaction posture) needed to reconstruct the operator decision.

### Governance Boundary (`GOV`)

- [x] **GOV-05**: Blast-radius threshold evaluation for protected-environment audience mutations remains reference-count based and does not consume impression summaries or host cohort evidence for governance routing decisions.

### Mounted Preview Evidence Workflows (`ADM`)

- [x] **ADM-05**: Mounted audience edit, archive, and delete preview flows resolve host-supplied preview evidence when a host configures the resolver seam, render sample/impression evidence with honest uncertainty copy, and fail closed with actionable guidance when evidence is missing, invalid, or policy-denied.

### Verification And Support Truth (`VER`)

- [x] **VER-01**: Repo-local proof covers host evidence resolver wiring, redaction, fingerprint determinism, stale-token rejection with evidence present, governance unchanged semantics, and mounted preview rendering (`mix verify.phase68` or equivalent merge gate).
- [x] **VER-02**: Host-app integration seam docs and in-place flow guides describe bounded preview-evidence responsibilities, sample/impression limits, and forbidden overclaim phrases; `MAINTAINING.md` mounted proof file list matches CI/release-contract truth.
- [x] **VER-03**: Release-contract and public docs allow bounded host-supplied preview evidence claims only where implemented and preserve the linked-version sibling-package model without standalone-admin or observability-product widening.

## Future Requirements

### Deferred Beyond v1.9.0

- **ADM-06**: Optional targeting presets can generate concrete draft audiences or rules for common patterns without live inheritance or ongoing propagation.
- **ROL-08** (v1.5 memo): Guardrails can compare rollout health against bounded baselines or cohorts without embedding a bespoke statistics engine.
- **GOV-02-ext**: Host-configurable threshold profiles per environment or tenant beyond the bounded default blast-radius contract.

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| Host preview evidence resolver and payload contract | `rulestead` owns preview semantics, redaction, fingerprinting, and fail-closed validation | low-frequency semantic | high | high | merge-blocking deterministic preview and stale-token proof with evidence | `core` |
| Blast-radius governance boundary | `rulestead` owns threshold evaluation unchanged by evidence richness | low-frequency semantic | high | medium | merge-blocking proof that GOV thresholds ignore impression summaries | `core` |
| Mounted preview evidence presentation | `rulestead_admin` owns presentation inside host-mounted policy envelope | native screen | high | medium | mounted preview, confirm, and governance proof | `companion` |
| Metrics warehouse, population analytics, or authoritative affected-user counts | no route owner inside current product boundary | defer | high | high | n/a | `defer` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| Host preview evidence behavior, payload extension, fingerprinting, and audit metadata in `rulestead` | `core` | In scope |
| Blast-radius governance unchanged semantics in `rulestead` | `core` | In scope |
| Mounted audience preview evidence resolution and rendering in `rulestead_admin` | `companion` | In scope |
| Host seam docs, proof commands, release-contract checks, MAINTAINING drift fix | `example/docs-only` | In scope |
| Observability ingestion, population analytics dashboards, preset template inheritance, standalone admin | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| Host preview evidence contract | deterministic tests for resolver wiring, redaction, fingerprint with evidence, stale rejection, and invalid/oversized payload fail-closed | host-app walkthrough with wired resolver |
| Governance boundary | proof that blast-radius thresholds ignore impression summaries | protected-env governance regression |
| Mounted UX | LiveView tests for evidence rendering, missing-evidence copy, and confirm-path carry-through | browser smoke on audience preview |
| Docs and support truth | release-contract checks, `mix verify.phase68`, MAINTAINING file list parity | maintainer spot-check against host seam doc |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rulestead-owned impression ingestion or warehouse queries | Host owns observability truth; previews remain opt-in and bounded |
| Authoritative affected-user or population counts | Explicit product constraint from v1.6 preview basis |
| Impression-weighted blast-radius thresholds | GOV-05 keeps reference-count governance; IMP-05 does not change routing |
| Draft targeting presets / template inheritance (ADM-06) | Deferred; scope creep risk |
| Guardrail baseline comparison engine (ROL-08) | Future rollout deepening, not this milestone |
| Standalone admin control plane or fleet dashboards | Preserves mounted sibling-package design |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMP-05 | Phase 65 | Complete |
| IMP-06 | Phase 65 | Complete |
| IMP-07 | Phase 66 | Complete |
| GOV-05 | Phase 66 | Complete |
| ADM-05 | Phase 67 | Complete |
| VER-01 | Phase 68 | Complete |
| VER-02 | Phase 68 | Complete |
| VER-03 | Phase 68 | Complete |

**Coverage:**

- v1.9.0 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after v1.9.0 roadmap creation*
