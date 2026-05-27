# Phase 58: Change Request Integration - Context

**Gathered:** 2026-05-27 (assumptions mode — plan-phase without prior discuss)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire **high-blast-radius audience mutations** in **protected environments** through the **existing** `submit_change_request` → `approve_change_request` → `execute_change_request` envelope. No parallel governance workflow.

**In scope:** New governed action `:apply_audience_mutation`, frozen `command_snapshot` + metadata embedding Phase 57 assessment, submit validation, governed execute path with stale-preview rejection, terminal reject/cancel audit evidence, Fake+Ecto parity, contract tests.

**Out of scope:** Mounted admin UX routing (Phase 59), docs/release-contract (Phase 60), new `Rulestead.Error` `:type` atoms, scheduled execution for audience mutations (defer unless trivial reuse), threshold profile host config.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Governed action vocabulary
- Add `:apply_audience_mutation` to `ChangeRequest.governed_actions/0` and all normalization/serialization paths (`governed_action` string `"apply_audience_mutation"`).
- `resource_type` for audience CRs: `"audience"`; `resource_key`: `audience_key` from mutation command.
- Reuse existing `ApprovalRequirement` seams (`required_approvals`, `self_approval_allowed?`, `change_request_required?`) — no new approval struct fields.

### D-02 — Submission payload (CRQ-01)
- `SubmitChangeRequest.command` holds a **normalized map** of `Command.ApplyAudienceMutation` fields (via `GovernanceSupport.normalize_command/1`).
- `SubmitChangeRequest.metadata` MUST include:
  - `"blast_radius_assessment"` — Phase 57 assessment map (serialized)
  - `"affected_reference_summary"` — `%{reference_count, distinct_flag_count, reference_keys, rollout_hints, lifecycle_hints}` derived from preview at submit time
  - `"preview_fingerprint"`, `"preview_schema_version"`, `"operation"`, `"environment_key"`, `"tenant_key"` (when present)
- Submit validation module: `Rulestead.Governance.AudienceMutationChangeRequest` with `validate_submit/2` returning `:ok | {:error, Rulestead.Error.t()}`:
  - Protected environment only (`Compare.protected_target?/1`)
  - Assessment `verdict == :above_threshold` (reject submit when `:below_threshold` — use direct apply; reject when `:indeterminate` — fail closed)
  - Required mutation command keys present (`audience_key`, `operation`, preview fields, `after_definition` or archive fields per operation)
  - `preview_fingerprint` matches freshly computed preview at submit time (same `ensure_fresh_audience_preview` semantics)

### D-03 — Governed execute path (CRQ-02)
- `execute_bounded_governed_change/4` for `"apply_audience_mutation"` rebuilds `Command.ApplyAudienceMutation` from `command_snapshot` + execution metadata (`change_request_id`, `execution_stage: "execute"`).
- Call internal apply with **`governed_apply?: true`** (keyword to `validate_blast_radius_threshold` / `BlastRadiusThreshold.validate_protected_apply`) so **`:above_threshold` does not block**; **`:indeterminate` still blocks** (fail-closed).
- Still run: schema version check, **fresh preview fingerprint** at execute time, dependency validation, tenant scope.
- On stale preview at execute: `StoreError.invalid_command("audience preview is stale", ...)` — change request stays `:approved`, not `:executed` (same as other governed actions).

### D-04 — Terminal states leave audience unchanged (CRQ-03)
- `reject_change_request` / `cancel_change_request` already do not execute mutation — extend **audit metadata** on `change_request.rejected` / `change_request.cancelled` to include `blast_radius_assessment` + `affected_reference_summary` from stored change request metadata (no audience row writes).
- Optional: `expire` is not a first-class change-request state today — document as deferred; tests cover reject + cancel only.

### D-05 — Errors and audit
- Reuse `StoreError.invalid_command/2` — no new public `:type` atoms.
- Submit audit `change_request.submitted` metadata includes assessment summary (no raw predicate PII).
- Execute success: existing `audience.update` / `audience.archive` audit from apply path + `change_request.merged`.
- Execute failure (stale preview): audit `change_request.execution_failed` or reuse error path without marking executed — match existing governed execute failure patterns in Fake/Ecto.

### D-06 — Store parity and tests
- Fake + Ecto: submit validation hook before insert; execute branch; serialize `governed_action` filter for list.
- New contract test file: `test/rulestead/governance/audience_mutation_change_request_contract_test.exs` (Fake + Ecto via `@adapters`).
- Extend `governance_adapter_contract_test.exs` only if shared helpers reduce duplication — prefer dedicated audience CR contract file.
- Facade: ensure `Rulestead.submit_change_request/1` accepts `:apply_audience_mutation` through existing admin policy actions (extend `command_action` mapping if needed).

</decisions>

<canonical_refs>
## Canonical References

### Governance and targeting
- `rulestead/lib/rulestead/governance/change_request.ex` — governed action vocabulary
- `rulestead/lib/rulestead/governance/blast_radius_threshold.ex` — assessment shape for embedding
- `rulestead/lib/rulestead/governance/approval_requirement.ex` — approval policy seam
- `rulestead/lib/rulestead/store/command.ex` — `SubmitChangeRequest`, `ApplyAudienceMutation`, `ExecuteChangeRequest`
- `rulestead/lib/rulestead/fake.ex` — `submit_change_request`, `execute_governed_change`, `do_apply_audience_mutation`
- `rulestead/lib/rulestead/store/ecto.ex` — Ecto parity

### Prior phase
- `.planning/phases/57-blast-radius-threshold-contract/57-CONTEXT.md` — threshold verdict semantics
- `.planning/phases/57-blast-radius-threshold-contract/57-04-SUMMARY.md` — shipped threshold integration

### Tests (patterns)
- `rulestead/test/rulestead/store/governance_adapter_contract_test.exs`
- `rulestead/test/rulestead/store/audience_impact_contract_test.exs`

</canonical_refs>

<specifics>
## Specific Ideas

- Promotion governed apply uses `allow_protected_target?: true` on execute — mirror with `governed_apply?: true` for blast-radius threshold bypass only.
- Above-threshold direct-apply remediation already says "Submit a change request" — Phase 58 makes that path real.

</specifics>

<deferred>
## Deferred Ideas

- Change-request expiry job / `:expired` state (CRQ-03 "expired" — audit-only if state added later)
- Scheduled execution for audience mutations
- Mounted operator proposal UI (Phase 59)

</deferred>

---

*Phase: 58-change-request-integration*
*Context gathered: 2026-05-27 via assumptions mode (plan-phase)*
