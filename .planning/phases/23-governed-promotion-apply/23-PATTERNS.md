# Phase 23: Governed Promotion Apply - Pattern Map

**Mapped:** 2026-05-18
**Scope:** Only reusable implementation patterns for Phase 23 apply/governed promotion work.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead.ex` | facade | request-response | `compare_environments/3` + governance facade verbs in [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:68) | exact |
| `rulestead/lib/rulestead/store/command.ex` | command model | request-response | `CompareEnvironments` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:177), `SubmitChangeRequest` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:640) | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | store adapter | authored-write + transaction | compare projection, governed submit/execute/schedule, snapshot write in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:54) | exact |
| `rulestead/lib/rulestead/fake.ex` | fake adapter | request-response | compare + governed execution handlers in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:391) | exact |
| `rulestead/lib/rulestead/governance/change_request.ex` | model | event-driven | [rulestead/lib/rulestead/governance/change_request.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/change_request.ex:8) | exact |
| `rulestead/lib/rulestead/governance/scheduled_execution.ex` | model | scheduled/event-driven | [rulestead/lib/rulestead/governance/scheduled_execution.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/scheduled_execution.ex:6) | exact |
| `rulestead/lib/rulestead/audit_event.ex` | model/utility | append-only audit | [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33) | exact |
| `rulestead/lib/rulestead/promotion/compare.ex` | domain projection | transform | [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:29) | exact |
| `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` | LiveView | route-backed review | [index.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:22) | exact |
| `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` | LiveView | route-backed review | [show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex:24) | exact |
| `rulestead_admin/lib/rulestead_admin/live/change_request_live/index.ex` | LiveView | queue/review | [index.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/change_request_live/index.ex:22) | exact |
| `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex` | LiveView | review/execute/schedule | [show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex:25) | exact |
| `rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex` | LiveView | scheduled execution detail | [show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex:22) | exact |

## Pattern Assignments

### 1. Public facade -> store command -> store callback -> Ecto/Fake implementation

**Copy from facade:**
- `compare_environments/3` and `compare_environments/1` in [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:68)
- governance write verbs in [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:261)

**Pattern to reuse**
- Public API exposes both convenience and command-first forms.
- Public write verbs delegate through `admin_write(...)`; compare/read verbs go through `Compare.compare/1` or `run_store(...)`.
- New promotion apply facade should look like compare/governance verbs, not like an admin-only helper.

**Copy command normalization from:**
- `CompareEnvironments` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:177)
- `SubmitChangeRequest` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:640)
- `ScheduleChangeRequest` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:886)

**What to copy**
- key-first normalized inputs
- trimmed strings
- deduped/sorted flag lists
- metadata normalization through `GovernanceSupport`
- governed commands carrying `command` and `approval_requirement` as normalized maps

**Copy adapter seam from:**
- Ecto compare callback in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:54)
- Fake compare callback in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:391)

**Recommendation**
- Add one first-class promotion command/bundle and make both direct apply and governed apply consume it.
- Extend both `Rulestead.Store.Ecto` and `Rulestead.Fake` in parallel. Do not hide Phase 23 semantics inside LiveView code or compose them from multiple unrelated existing commands.

### 2. Governance change request and scheduled execution patterns

**Canonical state contracts**
- Change request actions/states in [rulestead/lib/rulestead/governance/change_request.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/change_request.ex:8)
- Scheduled execution actions/snapshots in [rulestead/lib/rulestead/governance/scheduled_execution.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/scheduled_execution.ex:6)

**Persisted snapshot pattern**
- change request stores `approval_requirement_snapshot`, `command_snapshot`, `metadata`, `correlation_id` in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2136)
- schedule-from-change-request copies `approved_by_snapshot`, `command_snapshot`, `approval_requirement_snapshot`, `correlation_id` in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:928)

**Execution callback pattern**
- governed execution dispatch is a bounded action switch in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2418)
- publish execution reconstructs a typed command from `change_request.command_snapshot` and enriches metadata with `request_id`, `change_request_id`, `governance_action`, `execution_stage` in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2588)
- fake store mirrors the same pattern in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:1062) and [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:2138)

**Recommendation**
- Add promotion as another first-class governed action instead of smuggling it through `publish_ruleset`.
- Store the exact promotion bundle in `command_snapshot` and execute from that snapshot later.
- Re-run compare-token and dependency validation inside the execute path before mutation, the same way current governed execution rechecks schedulable state before delegating.

### 3. Append-only audit metadata patterns

**Core metadata shape**
- `before`, `after`, `diff`, `links`, `context` plus top-level governance/scheduling fields in [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33)

**Existing mutation audit enrichment**
- ruleset audit metadata keeps only selected metadata keys and merges ruleset diff details in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2056)
- governance audit command injects `request_id`, `change_request_id`, `governance_action`, `execution_stage`, `resource_key` in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2404)

**Recommendation**
- Promotion audit metadata should extend existing fields, not invent a parallel schema.
- Put compare/apply-specific linkage in metadata: `source_environment_key`, `target_environment_key`, `compare_token`, selected `flag_keys`, dependency fingerprint/keys, promotion bundle id or version artifact id, and `scheduled_execution_id` when present.
- Keep audit append-only. Revert must be modeled as a fresh promotion/re-apply event, not history mutation.

### 4. Transactional authored-write + snapshot regeneration patterns

**Primary analog**
- `publish_ruleset/1` transaction in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:220)

**Important spine**
- authored writes and runtime snapshot generation are inside one `Ecto.Multi`
- `Multi.run(:runtime_snapshot, ...)` happens before audit insert and before transaction commit
- on failure, the entire authored mutation fails

**Snapshot write path**
- `insert_runtime_snapshot/3` in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1578)
- persisted artifact contract in [rulestead/lib/rulestead/runtime_snapshot.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime_snapshot.ex:12)

**Important nuance**
- current code broadcasts invalidation inside `insert_runtime_snapshot/3` after snapshot insert succeeds but still from the transactional mutation path.
- Phase 23 should preserve one authoritative authored-write + snapshot-write transaction, but should not create a second snapshot pipeline just for promotions.

**Recommendation**
- Promotion apply should mutate target authored state and regenerate the target snapshot in the same `Ecto.Multi`.
- If multiple flags are promoted, build one transaction around the entire bounded bundle and regenerate the target snapshot once after all authored mutations succeed.
- Reuse the existing snapshot artifact table/contract for runtime truth. Add a separate immutable environment-version artifact only for revertable source history, not as a replacement for runtime snapshots.

### 5. Admin mounted route-backed review flows in `rulestead_admin`

**Mounted routes**
- compare, change request, and schedule routes are mounted beside existing admin routes in [rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:15)

**Compare summary route**
- URL-backed `source_env`, `target_env`, `compare_token` loading in [environment_compare_live/index.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:22)
- findings-first summary and token panel in [environment_compare_live/index.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:72)

**Compare drill-in route**
- per-flag compare fetch with `flag_keys: [socket.assigns.flag_key]` in [environment_compare_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex:132)
- explicit `source/current target/proposed target after apply` rendering in [environment_compare_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex:79)

**Governance review route**
- review page shape and explicit action split in [change_request_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex:96)
- `Approve`, `Reject`, `Execute now`, `Schedule` remain separate state-dependent controls in [change_request_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex:125)
- command submission calls public facade verbs, not store internals, in [change_request_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex:251)

**Schedule detail route**
- route-backed execution detail and requeue/cancel posture in [schedule_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex:84)

**Recommendation**
- Extend compare summary into `select set -> review -> confirm` without introducing hidden session state.
- For protected targets, hand off from compare review into the existing change-request review queue/detail pattern.
- Keep execution/scheduling on the existing change-request and scheduled-execution routes. Do not create a separate “promotion console”.

### 6. Phase 22 compare payload consumption patterns

**Canonical compare payload**
- token construction in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:29)
- `requested_flag_keys`, `dependency_closure_keys`, `source_fingerprint`, `target_fingerprint` in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:64)
- per-flag `source_state`, `current_target_state`, `proposed_target_state`, `changed_fields`, `findings` in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:118)
- stale preview detection via mismatched `compare_token` in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:194)

**UI consumption**
- compare summary uses `overall_status`, counts, top-level findings, and flag rows in [environment_compare_live/index.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:72)
- drill-in uses raw `source/current target/proposed target` payloads directly in [environment_compare_live/show.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex:79)

**Recommendation**
- Promotion apply should consume the compare payload contract, not rebuild its own review DTO.
- Persist the normalized promotion bundle from compare output, especially selected keys, compare token, dependency closure, fingerprints, and proposed target authored state.
- Governed review screens should keep using compare vocabulary: `source`, `current target`, `proposed target after apply`.

## Shared Patterns

### Correlation and authored intent snapshots
- Reuse `correlation_id`, `command_snapshot`, and `approval_requirement_snapshot` as the durable source of truth for later execution.
- Source: [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2136), [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:928)

### Metadata redaction/normalization
- Reuse `GovernanceSupport.normalize_metadata/1` and `AuditEvent.metadata/1` to strip session/socket data automatically.
- Source: [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:46), [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:36)

### Real/Fake parity
- Every new promotion callback needs the same command shape and state transitions in both Ecto and Fake.
- Source: [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:2418), [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:2138)

## Do Not Duplicate

- Do not duplicate compare serialization logic in apply code. Reuse `Rulestead.Promotion.Compare` payload fields and token semantics.
- Do not model governed promotion as a disguised `publish_ruleset`; Phase 23 needs a first-class governed action with its own snapshot payload.
- Do not create a second admin workflow hub. Extend `/compare`, `/change-requests/:id`, and `/schedule/:id`.
- Do not use `rollback_audit_event/1` as the revert model. Revert is a fresh promotion/re-apply from an immutable environment-version artifact.
- Do not create a second runtime propagation mechanism. Reuse snapshot regeneration and existing notifier/invalidation behavior.
- Do not put apply-only state in LiveView session assigns that cannot survive refresh or deep links. Keep the route/query-driven posture.

## Minimal Planner Notes

- Backend slice should anchor on `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead.ex`, `rulestead/lib/rulestead/store/ecto.ex`, and `rulestead/lib/rulestead/fake.ex`.
- Governance/audit slice should anchor on `change_request.ex`, `scheduled_execution.ex`, `audit_event.ex`, and the existing governed execution switch in `store/ecto.ex`.
- Admin slice should extend compare review entrypoints and reuse existing change-request/schedule review routes rather than introducing new top-level navigation.
