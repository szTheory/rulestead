# Phase 58 Research: Change Request Integration

**Researched:** 2026-05-27  
**Phase:** 58 — Change Request Integration  
**Requirements:** CRQ-01, CRQ-02, CRQ-03

---

## Executive Summary

Phase 58 extends the **existing** governance envelope to audience mutations that Phase 57 blocks from direct apply in protected environments. The work adds `:apply_audience_mutation` to governed actions, a pure submit validator (`AudienceMutationChangeRequest`), governed execute branches in Fake/Ecto, and a `governed_apply?: true` bypass on blast-radius **above-threshold** only (indeterminate remains fail-closed).

No new tables required — `change_requests.command_snapshot` and `metadata` JSON columns already store arbitrary command + evidence maps.

---

## Codebase Findings

### Current change-request flow

```
SubmitChangeRequest → insert change_request row + change_request.submitted audit
ApproveChangeRequest → approvals + optional state → approved
ExecuteChangeRequest → execute_governed_change → domain mutation + change_request.merged audit
Reject/Cancel → terminal state, no execute
```

`execute_governed_change/3` in `fake.ex` only handles:

- `publish_ruleset`, `advance_rollout`, `engage_kill_switch`, `release_kill_switch`, `promote_environment`

Unknown actions return `{:error, StoreError.invalid_command("governed action is not implemented")}`.

### Audience apply pipeline (Phase 57)

```
fresh preview → BlastRadiusThreshold.validate_protected_apply → dependency validation → mutate
```

Governed execute inserts bypass **before** threshold check:

```elixir
BlastRadiusThreshold.validate_protected_apply(command, preview,
  dependency_entries: entries,
  governed_apply?: true
)
```

Implementation: early `:ok` when `governed_apply?` and verdict is `:above_threshold`; still evaluate indeterminate triggers.

### Submit embedding shape

Store in `metadata` (JSON-serializable):

```elixir
%{
  "blast_radius_assessment" => %{...},  # Phase 57 assessment
  "affected_reference_summary" => %{
    "reference_count" => n,
    "distinct_flag_count" => m,
    "reference_keys" => [...],
    "rollout_hints" => [...],
    "lifecycle_hints" => [...]
  },
  "preview_fingerprint" => "...",
  "preview_schema_version" => 1,
  "operation" => "update",
  "environment_key" => "production",
  "tenant_key" => "global"
}
```

`command_snapshot` = full `ApplyAudienceMutation` map for execute reconstruction.

### Approval policy

Reuse `ApprovalRequirement.new(action: :apply_audience_mutation, environment_key: "production", ...)`. Extend `Rulestead.Admin.Authorizer` / policy tests only if action mapping missing — grep `governance_action` in authorizer.

### Ecto parity

`ecto.ex:1307` `execute_change_request` mirrors Fake — add `apply_audience_mutation` branch calling same internal `apply_confirmed_audience_mutation` with governed flag.

### Test strategy

| REQ | Test focus |
|-----|------------|
| CRQ-01 | Submit embeds metadata; below-threshold submit rejected; indeterminate submit rejected |
| CRQ-02 | Approve+execute applies audience; stale fingerprint at execute fails without execute state |
| CRQ-03 | Reject/cancel: audience unchanged; audit contains assessment summary |

Contract file with `@adapters [Rulestead.Fake, Rulestead.Store.Ecto]` following `governance_adapter_contract_test.exs`.

Seed pattern: reuse `audience_impact_contract_test` helpers / `seed_audience_reference!` for >2 refs in production.

---

## Implementation Approach

### Plan split (4 plans)

1. **Governance contract module** — `AudienceMutationChangeRequest`, extend `ChangeRequest`, unit tests
2. **Fake integration** — submit validation, execute branch, `governed_apply?` threshold bypass
3. **Ecto integration** — parity for submit/execute/reject audit metadata
4. **Contract proof + facade** — cross-adapter audience CR contract, authorizer action if needed

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_test.exs` |
| **Contract command** | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_contract_test.exs` |
| **Full phase command** | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_test.exs test/rulestead/governance/audience_mutation_change_request_contract_test.exs` |
| **Estimated runtime** | ~45 seconds |

### Per-requirement verification map

| REQ-ID | Verification | Command |
|--------|--------------|---------|
| CRQ-01 | Submit stores assessment + summary; invalid verdicts rejected | unit + contract |
| CRQ-02 | Execute applies with fresh preview; stale blocks | contract both adapters |
| CRQ-03 | Reject/cancel leaves audience definition unchanged | contract |

### Wave 0 requirements

Existing governance + audience contract infrastructure sufficient. No Wave 0 stubs.

---

## RESEARCH COMPLETE
