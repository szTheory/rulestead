# Phase 49: Guardrail Signal Contract - Context

**Gathered:** 2026-05-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the host-owned rollout-signal seam, authored-state contract, and explicit threshold semantics for guarded rollouts without widening package boundaries, turning Rulestead into an observability product, or pulling mounted-admin workflow work forward from later phases.
</domain>

<decisions>
## Implementation Decisions

### Host-owned signal seam
- **D-01:** Phase 49 introduces a host-provided guardrail signal seam only. Rulestead consumes normalized signal facts; it does not fetch metrics directly, own provider adapters, or store observability truth.
- **D-02:** Supported signal integration must follow the existing host-owned seam posture used elsewhere in the repo: the host app owns provider wiring, identity, environment access, and any upstream credentials.
- **D-03:** Missing or unsupported providers must fail closed with explicit bounded reasons instead of implying healthy rollout state.

### Authored-state contract
- **D-04:** Guardrail definitions attach to rollout authored state as explicit configuration, not as ambient runtime-only metadata and not as mutable health state hidden outside the authored contract.
- **D-05:** Each guardrail definition should carry stable authored fields for signal identity, threshold semantics, freshness requirements, minimum sample-size requirements, and scope expectations so later decision logic can stay deterministic.
- **D-06:** Phase 49 should preserve the existing explicit draft/publish and authored-state discipline rather than introducing a side-channel contract for rollout safety data.

### Signal status normalization
- **D-07:** Phase 49 should lock a bounded normalized signal vocabulary that distinguishes healthy data from fail-closed cases such as missing provider support, stale data, insufficient sample size, or otherwise unsupported queries.
- **D-08:** Threshold semantics must stay explicit in the contract. Later phases should evaluate normalized facts against authored thresholds rather than infer health from provider-specific error strings or implicit defaults.
- **D-09:** Weak or incomplete signal data is never equivalent to healthy data in the contract; later automation must inherit this fail-closed posture directly from Phase 49.

### Explicit environment and tenant scope
- **D-10:** Every signal query contract must preserve explicit environment scope and tenant scope when present, consistent with the repo’s existing explicit-scope posture.
- **D-11:** Scope provenance and related metadata should reuse the existing bounded normalization style used by command and audit metadata rather than inventing a second scope dialect for guardrails.
- **D-12:** Phase 49 must not rely on ambient runtime/session state to infer where a signal applies. Guardrail scope stays explicit at the contract seam.

### Governance, audit, and package-boundary discipline
- **D-13:** Phase 49 defines contract semantics only. It must not pre-build Phase 50 decision execution or Phase 51 mounted rollout UI behavior beyond the bounded reason vocabulary those phases will need.
- **D-14:** Guardrail contract design must stay compatible with the existing governed mutation and audit envelope so later automatic hold or rollback actions can record exact scope, breached signal identity, and bounded reasons without a second audit model.
- **D-15:** The sibling-package release shape remains unchanged: `rulestead` owns the core signal contract and `rulestead_admin` remains a mounted companion surface that will consume, not redefine, these semantics later.

### the agent's Discretion
- Exact module and struct names for the guardrail signal seam, provided the seam remains host-owned and explicit.
- Exact field names and enum labels for normalized signal facts, provided the vocabulary stays bounded and fail-closed.
- Exact authored-state nesting shape for rollout guardrail definitions, provided it composes with existing authored rollout state and preserves explicit scope.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 49 goal, success criteria, and milestone phase split
- `.planning/REQUIREMENTS.md` — `ROL-01` and adjacent `ROL`/`AUD` requirements that this contract feeds
- `.planning/PROJECT.md` — milestone framing, host-owned observability boundary, and linked-version package posture
- `.planning/STATE.md` — active milestone status and current planning posture

### Prior locked decisions
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — rollout explicitness, draft/publish discipline, and bounded operator semantics
- `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md` — authored-state discipline, governed mutation posture, and append-only audit expectations
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` — explicit tenant/environment scope and bounded provenance vocabulary
- `.planning/phases/41-release-truth-alignment/41-CONTEXT.md` — sibling-package and mounted-companion guardrails
- `.planning/phases/48-final-verification-archive-prep/48-CONTEXT.md` — active milestone guardrails and bounded next-step framing

### Prompt anchors
- `prompts/rulestead-host-app-integration-seam.md` — host-owned integration boundary and explicit seam posture
- `prompts/rulestead-telemetry-observability-and-audit.md` — telemetry vs audit separation and bounded event/audit contract expectations
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed security posture and host-owned trust boundaries
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted-admin boundary and rollout/operator workflow posture
- `prompts/rulestead-domain-language-field-guide.md` — canonical rollout and operator vocabulary

### Existing code and public seams
- `rulestead/lib/rulestead/context.ex` — explicit runtime environment and tenant context shape
- `rulestead/lib/rulestead/store/command.ex` — bounded command metadata normalization and tenant provenance vocabulary
- `rulestead/lib/rulestead/audit_event.ex` — bounded audit metadata normalization and redaction path
- `rulestead/lib/rulestead/ruleset/rollout.ex` — current explicit rollout authored-state shape
- `rulestead/lib/rulestead/evaluator.ex` — deterministic rollout evaluation and explicit bucket semantics
- `rulestead/lib/rulestead/promotion/apply.ex` — exact-artifact revalidation and authored-state-first mutation posture
- `rulestead/lib/rulestead/admin/policy.ex` — host-owned authorization seam
- `rulestead/lib/rulestead/telemetry.ex` — bounded metadata/event shaping for runtime and governance flows
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — explicit mounted environment and tenant scope resolution
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` — current mounted rollout workflow boundary that later guardrail UI must extend without redefining

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Context` already gives Phase 49 an explicit environment and tenant scope carrier for runtime-facing guardrail queries.
- `Rulestead.Store.Command.GovernanceSupport` already provides the bounded normalization style for tenant provenance and metadata shaping that guardrail contracts should reuse.
- `Rulestead.AuditEvent.metadata/1` already normalizes and redacts bounded metadata, which is the right downstream audit shape for future guardrail evidence.
- `Rulestead.Ruleset.Rollout` already demonstrates the repo’s preferred authored-state pattern: small explicit embedded config with closed enums and validation.
- `RulesteadAdmin.Live.Session` already proves the mounted surface resolves environment and tenant scope explicitly rather than implicitly.

### Established Patterns
- The repo consistently prefers host-owned seams over built-in provider ownership.
- Authored-state changes are explicit, previewable, and revalidated rather than inferred from mutable runtime state.
- Fail-closed behavior is favored when scope, authorization, prerequisites, or upstream truth are missing.
- Audit metadata stays bounded and normalized instead of storing freeform provider payloads as durable truth.
- Mounted admin consumes core semantics from `rulestead`; it does not create a separate product boundary.

### Integration Points
- The new guardrail seam should connect to existing runtime context and command metadata paths so environment and tenant scope stay explicit end to end.
- Future guarded decisions should plug into the existing governance and audit envelope rather than inventing a second mutation workflow.
- Later mounted rollout status work should consume the normalized signal vocabulary defined here rather than translating provider-specific states inside the UI.
</code_context>

<specifics>
## Specific Ideas

- Treat guardrail signals like other host-owned seams in Rulestead: explicit inputs, bounded normalization, and clear ownership of upstream truth.
- Keep the contract deterministic and provider-agnostic enough that later hold/rollback logic can evaluate authored thresholds without bespoke adapter behavior.
- Preserve the explicit distinction between authored rollout truth, runtime evaluation, telemetry, and durable audit evidence.
</specifics>

<deferred>
## Deferred Ideas

- Rulestead-owned metrics ingestion, storage, dashboards, or anomaly detection
- Automatic stage advancement based on healthy guardrails
- Fleet-wide observability or standalone admin behavior for rollout health
- Provider-specific UI modeling in Phase 49 beyond bounded reason vocabulary
</deferred>

---

*Phase: 49-guardrail-signal-contract*
*Context gathered: 2026-05-26*
