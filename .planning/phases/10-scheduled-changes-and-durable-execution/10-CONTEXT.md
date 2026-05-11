# Phase 10: Scheduled Changes and Durable Execution - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning
**Research mode:** one-shot synthesis from parallel advisor passes across scheduling model, action scope, retry posture, and audit/actor semantics with ecosystem validation

<domain>
## Phase Boundary

Add future-dated governed mutations for the bounded Phase 10 action set using the existing Oban seam, with durable execution, idempotent retry/recovery semantics, rollout-stage and kill-switch integration, and clear audit/telemetry visibility. This phase extends the governed mutation path from Phase 9; it does not introduce a second execution substrate, a generic workflow engine, or the mounted admin UI surfaces from Phase 11.

</domain>

<decisions>
## Implementation Decisions

### Scheduling Model
- **D-01:** Scheduling is a separate durable execution record linked to an already-approved change request by default, not a field that collapses approval state and execution state into one object.
- **D-02:** The approval chain remains `change_request -> approval(s) -> scheduled_execution -> execution attempt(s) -> mutation audit`, all tied together by shared correlation identifiers.
- **D-03:** The scheduled execution record, not the Oban job row, is the source of truth for operator-facing state and replay safety. Oban is the delivery substrate.
- **D-04:** A narrow direct-scheduling bypass is allowed only when host policy says a change request is not required for that action/environment, or for a tightly-scoped emergency path that is louder in audit and UI. It must not become a shadow workflow.

### Scheduled Action Scope
- **D-05:** Phase 10 schedules only the bounded one-shot governed actions already implied by the roadmap and requirements: `publish_ruleset`, `advance_rollout`, `engage_kill_switch`, and `release_kill_switch`.
- **D-06:** Phase 10 does not add multi-step rollout ladders, chained schedules, recurring schedules, or generic arbitrary governed-command scheduling.
- **D-07:** If operators want a staged rollout ladder, they create multiple explicit scheduled one-shot actions rather than one higher-order campaign object in this phase.

### Durable Execution and Retry Posture
- **D-08:** Scheduled execution uses Oban’s native scheduled-job lifecycle and bounded retry semantics. The system retries transient failures automatically with bounded backoff, then stops.
- **D-09:** After bounded retries are exhausted, the scheduled execution enters a terminal failed/quarantined application state that requires explicit operator requeue or retry. Rulestead should not retry governed mutations forever in the background.
- **D-10:** Every scheduled execution must be replay-safe and idempotent by scheduled-execution identity. Re-running the same execution record must not duplicate side effects or create multiple final mutations.
- **D-11:** Recovery semantics must distinguish between retrying the same execution contract and creating a new scheduled change. Operators should not lose the original failed record when they recover it.

### Audit, Actor, and Operator Clarity
- **D-12:** Scheduled execution preserves human provenance and records system execution honestly. Submitter, approver(s), and scheduler/editor remain first-class human actors on the scheduled record; the actual runtime mutation is recorded as scheduler/system execution linked back to them.
- **D-13:** Audit and telemetry for scheduled execution must capture both requested and actual timing: original scheduled time, actual execution time, attempt count, execution outcome, and failure reason where applicable.
- **D-14:** Audit wording and UI should make the actor chain explicit in least-surprise language such as “scheduled by”, “approved by”, and “executed by scheduler”, rather than impersonating the original human at execution time.

### Conflict and Staleness Posture
- **D-15:** Scheduled execution must fail visibly rather than applying surprising stale intent when the underlying target becomes invalid or materially conflicting before execution. Examples include archived flags, deleted rollout targets, or invalidated draft/publish prerequisites.
- **D-16:** Conflict handling stays explicit and operator-visible. The system should surface why execution could not proceed instead of silently mutating toward the nearest available state.

### the agent's Discretion
- Exact schema split between scheduled change row, execution-attempt metadata, and Oban job linkage, provided the scheduled execution record remains the source of truth.
- Exact retry budget and backoff tuning, provided retries stay bounded and operator-visible.
- Exact naming of failed vs quarantined terminal states, provided the state clearly communicates “automatic retries are over; explicit operator action required.”
- Exact telemetry event names and metadata field layout, provided they preserve the current audit-correlation spine and operator-meaningful failure context.

</decisions>

<specifics>
## Specific Ideas

- Use the existing Phase 9 two-step governance model as the backbone instead of reopening it. Phase 9 intentionally kept approve and execute separate so scheduled execution can land cleanly.
- Prefer the Unleash-style lesson over the older LaunchDarkly-style coupling here: approved work can be scheduled later, and scheduling conflicts/staleness must be surfaced as real operator states.
- Preserve the project’s existing operator posture: explicit over magic, preview -> confirm -> audit, no hidden persistence, and no surprise background behavior that mutates prod long after intent was expressed.
- For Elixir/Phoenix/Ecto/Oban ergonomics, keep the app-level execution contract in Postgres and enqueue the worker transactionally from the same write path. Do not make Oban job state the only product state.
- Developer preference for this repo: push research and concrete recommendations earlier in GSD workflows, and only escalate questions that are truly high-impact or product-defining.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 10 goal, bounded plan slices, and explicit use of the existing Oban seam
- `.planning/PROJECT.md` — governance milestone goal, sibling-package constraints, and calm operator posture
- `.planning/REQUIREMENTS.md` — source of truth for `SCH-01`, `SCH-02`, and `SCH-04`
- `.planning/STATE.md` — current milestone sequencing and active requirement focus

### Prior Locked Decisions
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — explicit rollout, kill-switch, audit, and operator-trust decisions that scheduled execution must preserve
- `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-CONTEXT.md` — sibling-package public-boundary and release-shape constraints
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-01-SUMMARY.md` — governance contract vocabulary and actor/correlation model
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-02-SUMMARY.md` — governance persistence and store-command normalization
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-03-SUMMARY.md` — host-owned governance policy hooks and approval requirement snapshots
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-04-SUMMARY.md` — explicit two-step approve/execute lifecycle and adapter parity that Phase 10 should extend, not replace

### Product, UX, and Security Direction
- `prompts/rulestead-admin-ux-and-operator-ia.md` — operator IA, schedule surface expectations, and explicit mutation UX principles
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit/telemetry separation, correlation expectations, and admin event posture
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned auth, least-surprise governance, and immutable audit/security posture
- `prompts/rulestead-host-app-integration-seam.md` — host-owned identity boundary and Oban integration expectations

### Existing Code and Contracts
- `rulestead/lib/rulestead.ex` — public governance facade and existing admin mutation envelope
- `rulestead/lib/rulestead/store.ex` — store behavior surface that scheduling will extend
- `rulestead/lib/rulestead/store/command.ex` — command-first mutation envelope and governance command normalization
- `rulestead/lib/rulestead/store/ecto.ex` — transactional governance persistence and execution path to extend for scheduled execution
- `rulestead/lib/rulestead/fake.ex` — fake-adapter parity surface that scheduled execution must preserve
- `rulestead/lib/rulestead/oban.ex` — bounded Oban context serialization seam
- `rulestead/lib/rulestead/oban/worker.ex` — worker-side context restoration pattern
- `rulestead/lib/rulestead/telemetry.ex` — canonical governance metadata and event correlation expectations
- `rulestead/test/rulestead/governance_safety_contract_test.exs` — current public governance lifecycle guarantees
- `rulestead/test/rulestead/store/governance_adapter_contract_test.exs` — parity expectations that should grow with scheduled execution

### Ecosystem References
- `https://hexdocs.pm/oban/scheduling_jobs.html` — native future scheduling semantics
- `https://hexdocs.pm/oban/job_lifecycle.html` — scheduled, retryable, cancelled, and discarded job states
- `https://hexdocs.pm/oban/Oban.Worker.html` — worker retry/error behavior
- `https://hexdocs.pm/oban/unique_jobs.html` — uniqueness and duplicate-work prevention
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — transactional composition for durable write + enqueue boundaries
- `https://docs.getunleash.io/concepts/change-requests` — approved-then-scheduled change-request model and conflict/suspension lessons
- `https://launchdarkly.com/docs/home/releases/scheduled-changes` — scheduled flag changes and progressive rollout lessons
- `https://launchdarkly.com/docs/home/releases/scheduled-changes-manage` — conflict handling and operator warnings for scheduled changes

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Oban` and `Rulestead.Oban.Worker` already provide a bounded context propagation seam for Oban-backed execution.
- `Rulestead.Store.Ecto` already executes governed changes transactionally and emits correlated audit rows; scheduled execution should reuse that path rather than inventing a parallel mutation engine.
- `Rulestead.Fake` already mirrors governance lifecycle state in memory, which gives Phase 10 a strong place to prove retry/recovery parity before UI work lands.

### Established Patterns
- The repo prefers explicit domain records and command structs over magic background behavior.
- Governance writes already flow through the existing admin authorization and redaction envelope.
- Audit and telemetry already treat correlation fields as first-class and keep durable audit separate from ephemeral telemetry.

### Integration Points
- Phase 10 should extend the existing governance command/facade/store path with a scheduled-execution contract rather than bypassing `Rulestead.submit_change_request/1`, `approve_change_request/1`, and `execute_change_request/1`.
- The scheduled execution write path should persist the product state and enqueue the Oban job in one transactional boundary.
- Retry/recovery behavior should project into the same operator-facing audit and list surfaces that Phase 11 will mount inside `rulestead_admin`.

</code_context>

<deferred>
## Deferred Ideas

- Multi-step rollout ladders, chained schedule campaigns, and progressive-release workflow builders
- Generic arbitrary governed-command scheduling beyond the bounded Phase 10 action set
- Recurring schedules or cron-like operator workflows
- Rich schedule-calendar UX beyond the bounded visibility and status surfaces planned for Phase 11

</deferred>

---

*Phase: 10-scheduled-changes-and-durable-execution*
*Context gathered: 2026-04-24*
