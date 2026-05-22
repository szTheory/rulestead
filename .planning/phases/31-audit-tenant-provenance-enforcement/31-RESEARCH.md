# Phase 31: Audit Tenant Provenance Enforcement - Research

**Researched:** 2026-05-22 [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
**Domain:** Automatic bounded tenant provenance across audit mutation, apply, governance, rollback, and scheduled-execution paths in the linked-version `rulestead` + `rulestead_admin` monorepo. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**Confidence:** HIGH [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Product shape and planning posture
- **D-01:** Phase 31 stays narrow and recommendation-first. Close the audit-provenance gap without reopening package boundaries, admin publishing posture, or broader tenancy architecture. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **D-02:** Preserve the linked-version sibling-package release design and keep `rulestead_admin` out of this phase except where existing bounded command facts already flow into core APIs. [VERIFIED: AGENTS.md] [VERIFIED: .planning/PROJECT.md]

### Provenance source of truth
- **D-03:** Canonical tenant provenance must come from normalized command fields and reviewed artifacts, not from freeform `command.metadata` or ambient runtime context. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **D-04:** Keep `tenant_key` as a first-class normalized command field where the command owns tenant scope today. Provenance is derived from that fact; it does not replace it. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/store/command.ex]
- **D-05:** Do not infer tenant scope from `conn`, `socket`, process dictionary, logger metadata, or other ambient host state. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Coverage and adapter parity
- **D-06:** Phase 31 must solve provenance with shared normalization and shared audit-builder seams, not per-callsite patching. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **D-07:** Ecto and Fake adapters must emit the same bounded tenant provenance shape and precedence rules. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **D-08:** Minimum required coverage includes direct writes, denied audit-only branches, direct apply paths, governed lifecycle rows, scheduled execution rows, rollback rows, and persisted replay payloads such as governed `command_snapshot` and scheduled execution metadata. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Missing-scope and replay semantics
- **D-09:** When no real tenant exists, audit rows must still emit explicit bounded semantics rather than silently omitting tenant provenance altogether. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **D-10:** `SingleTenant` without a real tenant key should emit `scope_source: single_tenant` and bounded validation evidence rather than fabricating tenant identity. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/tenancy/single_tenant.ex]
- **D-11:** Rollback and replay rows are current execution facts. They may link prior provenance, but their primary tenant truth must describe the action happening now. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Verification posture
- **D-12:** Focus verification on command/provenance normalization, audit-builder parity, scheduled/governed replay seams, and release-contract bounded metadata. Avoid broad E2E expansion. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEN-03 | Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the runtime seam unchanged and finish the remaining audit half by introducing one normalized tenant provenance builder, reusing `AuditEvent.metadata/1` plus shared audit-builder entry points in Ecto and Fake, and proving bounded persistence across apply/governance/scheduler/rollback flows. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] |
</phase_requirements>

## Summary

Phase 31 should not redesign tenancy. The repo already has the right enforcement seams: normalized command structs in `Rulestead.Store.Command`, one bounded audit metadata normalizer in `Rulestead.AuditEvent.metadata/1`, and centralized audit event creation in both `Rulestead.Store.Ecto` and `Rulestead.Fake`. The gap is that tenant provenance is still mostly implicit: `audit_event_changeset/5` and `build_audit_event/5` currently pass `command.metadata` into `context`, while apply/governance/scheduled paths only preserve tenant scope opportunistically through command snapshots and ad hoc metadata. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]

The implementation-ready recommendation is to complete the phase in two layers. First, add a shared provenance normalizer at the command/audit boundary so commands and persisted replay payloads carry one bounded tenant provenance object regardless of direct write, apply, governance, rollback, or scheduling path. Second, enforce that shared shape inside the Ecto and Fake audit builders so all emitted audit rows automatically merge the same provenance and no caller needs to hand-author it. This keeps `tenant_key` explicit, preserves current-action truth for rollback/replay rows, and avoids widening into ambient host state or UI-driven metadata hacks. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]

**Primary recommendation:** Plan Phase 31 as a core-only audit-seam closure with two execution slices: one for normalized tenant provenance helpers plus persisted replay payload shaping, and one for adapter audit-builder enforcement plus parity/release-contract verification. Keep the mounted-admin package untouched unless a test helper or existing public command constructor needs a bounded fixture update. [VERIFIED: AGENTS.md] [VERIFIED: .planning/ROADMAP.md]

## Recommended Plan Split

1. **`31-01-PLAN.md — Normalize tenant provenance for commands, replay payloads, and bounded audit metadata input`** should own the shared provenance vocabulary implementation: command helper(s), `AuditEvent.metadata/1` support, governed `command_snapshot` / scheduled execution metadata shaping, and any direct apply/rollback helper updates needed so replay payloads remain self-describing before audit emission. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]
2. **`31-02-PLAN.md — Enforce provenance in Ecto/Fake audit builders and extend contract coverage`** should own final audit emission parity: direct writes, denied branches, scheduled execution audit rows, change-request lifecycle rows, rollback rows, fake adapter parity, and release-contract bounded metadata assertions. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] [VERIFIED: rulestead/test/rulestead/release_contract_test.exs]
3. **Do not split by package.** This phase is primarily a `rulestead` core/store concern, and splitting by adapter or package would duplicate the provenance contract in both plans. Split instead by “normalize inputs/persisted replay state” and “enforce emitted audit rows/verification.” [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tenant provenance normalization | API / Backend | Database / Storage | Command structs and audit metadata normalization already own stable, bounded field shaping before persistence. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] |
| Audit row emission parity | Database / Storage | API / Backend | Ecto and Fake adapters each funnel writes through central audit builders, making them the right backstop for automatic provenance merging. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] |
| Governed and scheduled replay payload persistence | API / Backend | Database / Storage | Change requests, approvals, scheduled execution rows, and rollback commands are normalized before they are persisted and later replayed. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] |
| Operator-visible provenance semantics | API / Backend | Frontend Server (SSR/LiveView) | The current phase only needs durable bounded metadata and serialization guarantees; the mounted UI already consumes audit events and does not need a new surface. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: `elixir --version`] | Runtime and ExUnit surface for both sibling packages. | Phase 31 is an internal contract and test change, so standard Elixir/Mix workflows are sufficient. [VERIFIED: rulestead/mix.exs] [VERIFIED: rulestead_admin/mix.exs] |
| Ecto | 3.13.5 [VERIFIED: rulestead/mix.lock] | Audit event schema, Ecto-backed adapter writes, and transactional governance/scheduler flows. | The real-store provenance closure lands in Ecto audit builders and persisted replay rows. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] |
| ExUnit + `Rulestead.Fake` | repo-standard [VERIFIED: rulestead/test/] | Fast parity and contract coverage without broad browser or host-app expansion. | The testing strategy explicitly treats Fake adapter parity as the merge-blocking proof surface. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md] [VERIFIED: rulestead/lib/rulestead/fake.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| StreamData | repo floor `~> 1.1` [VERIFIED: rulestead/mix.exs] | Optional for bounded provenance invariants if a planner chooses one high-value property test. | Use only if a simple deterministic property helps lock enum/status normalization across helper inputs. |
| Phoenix LiveView / `rulestead_admin` | existing repo versions [VERIFIED: rulestead_admin/mix.lock] | Not a primary implementation target for this phase. | Only touch if an existing audit fixture or mounted test helper requires tenant provenance-aware sample data. |

## Architecture Patterns

### Pattern 1: Shared command-first provenance builder
**What:** Introduce one helper near `Rulestead.Store.Command.GovernanceSupport` and/or `Rulestead.AuditEvent` that derives bounded provenance from normalized command facts. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/audit_event.ex]
**When to use:** Any direct mutation, apply command, rollback command, governed `command_snapshot`, or scheduled execution metadata payload that needs durable tenant provenance. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]
**Recommended shape:**
```elixir
%{
  "tenant_key" => "acme" | nil,
  "scope_source" => "explicit" | "host_resolved" | "single_tenant",
  "validation" => %{
    "evidence" => "same_tenant_guard" | "single_tenant" | "not_applicable",
    "status" => "passed" | "bypassed"
  }
}
```
This shape matches the locked vocabulary from Phase 29/31 context while remaining bounded and serializable. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Pattern 2: Audit builders merge provenance automatically
**What:** Make `audit_event_changeset/5`, `scheduled_execution_audit_changeset/5`, `insert_audit_only_event/3`, and Fake `build_audit_event/5` pull the shared provenance helper instead of relying on whatever a caller happened to place in `command.metadata`. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**When to use:** Every audit event write path, including denied mutation branches and rollback-generated rows. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**Why:** This provides the final fail-closed backstop. Even if a caller forgets metadata shaping, the audit builder can still emit bounded tenant provenance from the command itself. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Pattern 3: Replay payloads stay self-describing before execution
**What:** Persist normalized tenant provenance inside governed `command_snapshot`, scheduled execution metadata, and other replay payloads so replay/worker paths do not have to reconstruct tenant truth from ad hoc context later. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**When to use:** Change-request submit/approve/merge paths, scheduled execution creation, direct scheduled governed actions, and promotion/manifest apply plan execution. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead.ex]
**Why:** Phase 31 explicitly requires replay payloads to remain self-describing, not merely the final audit rows. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Pattern 4: Current-action truth with bounded origin linkage
**What:** Rollback and replay rows should record the tenant provenance of the current execution while linking prior context through immutable ids plus an optional bounded origin snapshot. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**When to use:** `rollback_audit_event/2`, direct scheduled actions, and governed execution merges. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**Anti-pattern:** copying a previous audit row’s tenant truth wholesale into the new row and thereby obscuring what tenant scope the current operator or scheduler actually executed under. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

## Current Gaps

- `AuditEvent.metadata/1` normalizes governance and scheduled fields, but it has no first-class tenant provenance block yet. [VERIFIED: rulestead/lib/rulestead/audit_event.ex]
- Real and fake audit builders mainly pass `command.metadata` into `context`, so provenance can silently vary by caller and may disappear in replay paths. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
- Scheduled execution audit rows already build rich bounded metadata, but tenant provenance is not injected as a stable first-class shape. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]
- Rollback rows link prior audit ids, but current-execution tenant provenance is not normalized as an explicit primary fact. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
- Release-contract and adapter-contract tests cover bounded metadata generally, but Phase 31 still needs explicit assertions that tenant provenance cannot silently drop across direct, apply, governance, rollback, and scheduling seams. [VERIFIED: rulestead/test/rulestead/release_contract_test.exs] [VERIFIED: rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs]

## Recommended Project Structure

```text
rulestead/lib/rulestead/
├── audit_event.ex                      # bounded audit metadata normalization + provenance field support
├── store/command.ex                    # normalized command facts + shared tenant provenance helper
├── store/ecto.ex                       # real-store audit builders, scheduled/governed persistence, rollback emission
├── fake.ex                             # fake-store audit builder parity
├── promotion/apply.ex                  # apply-time provenance normalization feed
└── manifest/import.ex                  # import/apply provenance normalization feed

rulestead/test/rulestead/
├── audit_event_governance_test.exs
├── promotion/apply_test.exs
├── manifest/import_test.exs
├── store/promotion_apply_contract_test.exs
├── store/manifest_import_contract_test.exs
├── store/governance_adapter_contract_test.exs
├── store/scheduled_execution_adapter_contract_test.exs
├── scheduled_execution_audit_contract_test.exs
└── release_contract_test.exs
```

## Anti-Patterns to Avoid

- **Caller-authored tenant truth:** Do not require every mutation callsite to stuff `tenant_provenance` manually into `metadata`; that recreates the current gap and will drift. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **Ambient-scope derivation:** Do not read tenant from host-only runtime state inside audit builders; Phase 31 explicitly forbids hidden ambient derivation. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **Audit-only fix:** Do not patch only final audit rows while leaving governed `command_snapshot` and scheduled execution payloads opaque; replay paths must stay self-describing before emission. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
- **Tenant fabrication in `SingleTenant`:** Do not synthesize a fake tenant id from module name, actor, or environment. Emit bounded bypass semantics instead. [VERIFIED: rulestead/lib/rulestead/tenancy/single_tenant.ex] [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

## Validation Architecture

### Recommended verification surfaces
- **Unit/contract tests first:** Extend command, audit metadata, apply/import, governance, scheduler, rollback, and release-contract suites with explicit provenance assertions. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
- **Adapter parity focus:** Any new provenance assertion added for Ecto must either also run through Fake or be backed by a shared contract-style helper. [VERIFIED: rulestead/lib/rulestead/fake.ex] [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
- **No broad browser expansion:** This phase is backend durability and parity work, so the mounted admin/browser layers are not the primary confidence surface. [VERIFIED: AGENTS.md] [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]

### High-value verification targets
1. `AuditEvent.metadata/1` emits a stable bounded tenant provenance block for real-tenant, explicit-unscoped, and `SingleTenant` cases.
2. `Command`-level helpers persist provenance into governed `command_snapshot` / scheduled execution metadata and survive load/replay.
3. `audit_event_changeset/5` and Fake `build_audit_event/5` merge the same provenance shape automatically for direct writes and denied audit-only branches.
4. Scheduled execution audit rows preserve tenant provenance on `scheduled`, `requeued`, `cancelled`, `failed`, `quarantined`, and `succeeded` events.
5. Rollback-generated audit rows preserve current-action provenance plus immutable linkage to the prior row.
6. `release_contract_test.exs` keeps the bounded metadata catalog stable so tenant provenance additions remain intentional and documented.

## Common Pitfalls

### Pitfall 1: provenance lives only inside `context`
**What goes wrong:** tenant provenance is technically present somewhere under redacted `context`, but there is no stable first-class key for downstream contract tests, audit exports, or replay logic. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]
**How to avoid:** add a dedicated bounded tenant provenance section to the durable audit metadata contract and feed it from shared helpers. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]

### Pitfall 2: replay rows copy old truth instead of describing current execution
**What goes wrong:** rollback or scheduled execution rows appear tenant-correct only because they copied an older row’s metadata, obscuring who executed what now. [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md]
**How to avoid:** keep current execution provenance primary, retain lineage through immutable ids, and optionally carry a bounded origin snapshot for explainability. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]

### Pitfall 3: Ecto and Fake drift on metadata shape
**What goes wrong:** one adapter serializes provenance under top-level audit metadata while the other only buries it inside `context`, causing false confidence from single-adapter tests. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex]
**How to avoid:** define one helper and assert parity through shared contract tests plus explicit adapter comparisons. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]

---
*Phase: 31-audit-tenant-provenance-enforcement*
*Research completed: 2026-05-22*
