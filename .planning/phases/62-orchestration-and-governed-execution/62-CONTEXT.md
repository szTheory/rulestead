# Phase 62: Orchestration And Governed Execution - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire observation-window close into the existing `ScheduledExecution` / Oban worker envelope: schedule a tick at `monitoring_window_ends_at`, evaluate auto-advance eligibility, and — only when guardrails are `:healthy` after the window closes — execute governed `advance_rollout` with auditable `guardrail_automation` evidence and protected-environment change-request parity.

**In scope:** Schedule hook on `advance_rollout` when auto-advance policy enabled; tick execute path (evaluate → advance or change-request submit); fresh signal resolution at tick time; idempotency and race safety; Fake/Ecto store parity; contract tests for ORC-01, ORC-02, ROL-06, AUD-03.

**Out of scope:** Mounted toggle/pending UI (Phase 63), `mix verify.phase64` / release-contract / host seam docs (Phase 64), changes to v1.5 hold/rollback decision paths, observability-backed thresholds, new parallel Oban worker or ad-hoc mutation path, auto-approval of change requests in protected environments.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Single composite tick via existing ScheduledExecution envelope
- **D-01:** One `ScheduledExecution` tick at `monitoring_window_ends_at`, delivered by `Rulestead.Oban.ScheduledExecutionWorker` → `execute_scheduled_execution/1`.
- Tick uses governed action `:advance_rollout` with `command_snapshot` and metadata marking automation phase (`source: :guardrail_automation`, `automation_phase: "evaluate_and_advance"` or equivalent).
- Execute path: load policy + guardrail context → `evaluate_rollout_auto_advance/1` → on `:eligible` invoke governed `advance_rollout/1` with policy `next_stage` / `next_percentage`; on `:blocked` finalize tick without ruleset mutation.
- **Do not** add a parallel worker, ad-hoc GenServer scheduler, or second hop (evaluate tick + separate advance tick).

### D-02 — Schedule registration inside advance_rollout
- **D-02:** After successful `advance_rollout` (Fake + Ecto parity), when enabled auto-advance policy exists for `(flag_key, environment_key, rule_key)`, call `schedule_governed_action/1` for tick at command's `monitoring_window_ends_at`.
- `scheduled_for` = `monitoring_window_ends_at`; `execution_mode` = `:policy_bypass` for non-protected direct path (protected routing resolved at execute — D-04).
- Deterministic `idempotency_key`: `"scheduled_execution:auto_advance:#{flag_key}:#{environment_key}:#{rule_key}:#{stage}:#{iso8601(window_ends)}"` (exact segment order may vary in planning; must be stable per rollout stage + window).
- `command_snapshot` captures current stage, percentage, rule_key, monitoring window bounds, and rollout identity for stale-target checks at execute.
- Cancel or supersede prior pending ticks for same rollout rule when stage advances again before window close (bounded failure or skip — planner chooses minimal diff matching existing conflict patterns).

### D-03 — Idempotency and race safety (ORC-02)
- **D-03:** Compose existing primitives — do not invent parallel locking:
  - `execute_scheduled_execution` short-circuit on `"completed"` state (safe replay).
  - Stale snapshot → bounded failure (`rollout_stage_conflict` or dedicated `auto_advance_superseded` reason) matching `scheduled_execution_conflict_test.exs` posture.
  - Eligibility `:blocked` before any advance attempt (hold, rollback, pending window, empty/stale signals).
  - Re-check policy still `enabled` and complete at execute time.
- Duplicate Oban delivery must not double-advance or leave authored state inconsistent.
- Manual advance, rollback, hold, or cancellation between schedule and execute must fail closed with explicit bounded reason — no silent skip without audit.

### D-04 — Protected-environment governance (ROL-06)
- **D-04:** At tick execute, resolve `Authorizer.approval_requirement/4` for `:advance_rollout` on the target environment.
- When `change_request_required?` is **false**: direct governed `advance_rollout` through scheduled execution (`:policy_bypass`, system scheduler actor `system:scheduler`).
- When `change_request_required?` is **true**: auto-**submit** change request (system actor) with policy-authored `next_stage` / `next_percentage`, guardrail evidence snapshot, and window context in CR metadata — **do not auto-approve**; advance only after human approval via existing `approve_change_request` → `execute_change_request` / `schedule_change_request` path.
- Close any governance gap where `advance_rollout` bypasses `authorize_governed_action` in protected environments (automation must not weaken manual posture).
- Pre-approved CR at policy-enable time is **out of scope** — defer.

### D-05 — Signal resolution and audit evidence (AUD-03)
- **D-05:** At tick execute, resolve **fresh** `signal_facts` via `Rulestead.Guardrails.fetch_signal/2` (configured `:guardrails_provider`) for signal keys from rollout rule / latest matching `GuardrailDecision` — **not** frozen at schedule time.
- Pass resolved facts + `monitoring_window_ends_at` + `evaluated_at` into `evaluate_rollout_auto_advance/1`.
- On successful auto-advance:
  - Persist `GuardrailDecision` row for the advance (Phase 61 D-07 deferred automation persistence to this phase).
  - Emit `rollout.advance` audit with `metadata.source: :guardrail_automation`, signal facts, observation window bounds, stage transition, and links to eligibility snapshot.
  - Blocked ticks may record non-mutating audit evidence where an existing pattern applies; default is scheduled-execution lifecycle audit only unless planning finds a established stub pattern.
- No raw PII in telemetry, logs, or audit metadata.

### D-06 — Advance payload on eligible tick
- **D-06:** Governed advance uses policy `next_stage`, `next_percentage`, and policy `observation_window_seconds` to set the **next** stage's `monitoring_window_started_at` / `monitoring_window_ends_at` (same semantics as manual advance flow — Phase 61 D-06).
- Metadata on advance command: `source: :guardrail_automation`, `scheduled_execution_id`, correlation to tick.
- If policy `next_stage` / percentage no longer matches authored ruleset (operator changed ruleset), fail closed with bounded conflict reason.

### D-07 — Four-plan execution shape
- **D-07:** Mirror Phases 57/61 plan structure:
  - **62-01** — Schedule hook on `advance_rollout` + tick snapshot/idempotency contract (ORC-01)
  - **62-02** — Execute orchestration module: signal fetch → evaluate → advance or CR submit (ORC-01, AUD-03)
  - **62-03** — Fake/Ecto store integration + protected-env routing + worker wiring (ROL-06)
  - **62-04** — Contract tests: healthy auto-advance, blocked non-advance, protected-env CR parity, idempotency races (ORC-02, AUD-03)

### Claude's Discretion
- Exact metadata key for automation phase marker (`automation_phase` vs nested map)
- Whether schedule-time duplicate idempotency uses ON CONFLICT fetch-existing vs pre-check query
- Exact blocked-tick audit event type if a lightweight pattern exists
- Module naming for execute orchestration helper (e.g. under `Rulestead.Governance` or `Rulestead.Guardrails`)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/REQUIREMENTS.md` — ROL-06, ORC-01, ORC-02, AUD-03 acceptance criteria
- `.planning/ROADMAP.md` — Phase 62 goal, success criteria, phase boundary vs 63–64
- `.planning/STATE.md` — reuse ScheduledExecution, no parallel mutation path
- `.planning/threads/2026-05-27-post-v1.7-milestone-assessment.md` — single governed envelope preference

### Prior phase (contract this phase executes)
- `.planning/phases/61-auto-advance-authored-contract/61-CONTEXT.md` — policy contract, eligibility pure module, phase boundary D-03/D-06/D-07

### Scheduled execution and governance
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` — governed action vocabulary (`:advance_rollout`)
- `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` — worker entrypoint (ExecuteScheduledExecution only)
- `rulestead/lib/rulestead/store/ecto.ex` — `advance_rollout`, `schedule_governed_action`, `execute_scheduled_execution`, `schedule_change_request`, `execute_bounded_governed_action("advance_rollout", ...)`
- `rulestead/lib/rulestead/fake.ex` — adapter parity reference
- `rulestead/lib/rulestead/admin/authorizer.ex` — `change_request_required?` defaults for protected environments

### Auto-advance evaluation
- `rulestead/lib/rulestead/guardrails/auto_advance.ex` — pure eligibility evaluator
- `rulestead/lib/rulestead/guardrails.ex` — `fetch_signal/2` provider seam
- `rulestead/lib/rulestead/store/command.ex` — `EvaluateRolloutAutoAdvance`, `ScheduleGovernedAction`, `AdvanceRollout`

### Test patterns
- `rulestead/test/rulestead/scheduled_execution_conflict_test.exs` — stale target / `rollout_stage_conflict`
- `rulestead/test/rulestead/rollout_auto_advance_contract_test.exs` — Phase 61 eligibility parity
- `rulestead/test/rulestead/scheduled_execution_audit_contract_test.exs` — audit + telemetry correlation
- `rulestead/test/rulestead/oban_scheduled_execution_test.exs` — worker integration

### Operator and engineering policy
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — Fake adapter parity, error struct conventions
- `prompts/rulestead-domain-language-field-guide.md` — rollout/guardrail vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — `:advance_rollout` authorization posture
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit correlation, no PII in meta

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Governance.ScheduledExecution` — `:advance_rollout` already a governed action; serialize/idempotency fields ready
- `Rulestead.Oban.ScheduledExecutionWorker` — thin worker; no changes to hot-path evaluation
- `Rulestead.Guardrails.AutoAdvance.evaluate_eligibility/2` — Phase 61 pure evaluator; compose at tick execute
- `Rulestead.Guardrails.fetch_signal/2` — host provider seam for fresh facts at tick time
- `schedule_governed_action` / `schedule_change_request` / `execute_scheduled_execution` — full schedule→execute lifecycle
- `execute_bounded_governed_action("advance_rollout", ...)` — change-request execute path for protected env
- `Rulestead.Fake` + `Rulestead.Store.Ecto` — dual-adapter proof target

### Established Patterns
- Schedule registration co-located with mutating store command (advance creates decision + audit today)
- Deterministic idempotency keys for scheduled executions (`scheduled_execution:change_request:#{id}` precedent)
- Conflict tests assert bounded `failure_reason` strings, not exceptions
- `metadata.source: :guardrail_automation` already used in guardrail evaluation contract tests
- Completed scheduled execution returns `{:ok, ...}` without re-running mutation

### Integration Points
- Hook inside `advance_rollout` after successful ruleset publish + decision insert (both adapters)
- Execute hook inside `perform_scheduled_execution` / `execute_direct_scheduled_action("advance_rollout", ...)` when automation metadata present
- Protected path branches to `submit_change_request` with `:advance_rollout` governed action
- Phase 63 admin reads pending ticks + policy state via existing store/facade (no Phase 62 UI)

</code_context>

<specifics>
## Specific Ideas

- Single composite tick under existing envelope — assessment thread rejected parallel guardrail worker
- Protected env: automation initiates change request, humans approve — same envelope as manual advance, not bypass
- Fresh signals at execute time — observation window close means evaluate with current host metrics, not schedule-time snapshot

</specifics>

<deferred>
## Deferred Ideas

- Pre-approved change request at policy-enable time — adds state coupling; ROL-06 satisfied by submit-at-tick
- Separate `:evaluate_rollout_auto_advance` governed action — rejected; composite tick under `:advance_rollout` keeps vocabulary stable
- Host-explicit `schedule_rollout_auto_advance_tick/1` callback — rejected; schedule hook inside `advance_rollout` reduces host burden
- Periodic sweeper over open `GuardrailDecision` rows — rejected; enqueue-on-advance matches window semantics
- Mounted auto-advance UX — Phase 63 (ADM-04, AUD-04)
- Proof/docs/release-contract — Phase 64 (VER-01–03)

</deferred>

---

*Phase: 62-orchestration-and-governed-execution*
*Context gathered: 2026-05-27*
