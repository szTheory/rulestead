# Phase 61: Auto-Advance Authored Contract - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Core defines opt-in auto-advance policy with observation window and explicit authored next-stage plan, plus fail-closed pure eligibility evaluation on top of v1.5 guardrail semantics — without scheduling ticks, governed execution, mounted admin UX, or proof/docs.

**In scope:** Durable policy contract (Fake + Ecto parity), pure `Guardrails.AutoAdvance` evaluator, store read/write + eligibility command, deterministic contract tests, thin `Rulestead` facade wrappers matching existing rollout APIs.

**Out of scope:** Observation-window tick scheduling and governed `advance_rollout` execution (Phase 62), mounted toggle/pending UI (Phase 63), `mix verify.phase64` / release-contract / host seam docs (Phase 64), changes to v1.5 hold/rollback decision paths, observability-backed thresholds, admin ladder as source of truth.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Policy persistence (dedicated table)
- **D-01:** Add `rollout_auto_advance_policies` table keyed by `(flag_key, environment_key, rule_key)` with:
  - `enabled` (boolean, default `false`)
  - `observation_window_seconds` (positive integer, required when `enabled`)
  - `next_stage` (string, required when `enabled`)
  - `next_percentage` (0..100, required when `enabled`)
  - standard timestamps + optional `metadata` map (normalized via `Command.GovernanceSupport`)
- Upsert via new store command; unique index on the composite key.
- **Not** stored in ruleset embeds or `flag_environments` metadata — keeps rollout automation config separate from authored ruleset snapshots and rollback targets.
- Admin `@ladder_steps [5, 25, 50, 100]` remains UI-only suggestion; policy `next_stage` / `next_percentage` are operator-authored and required before auto-advance can be enabled.

### D-02 — Pure evaluator module
- **D-02:** Add `Rulestead.Guardrails.AutoAdvance` as a **pure module** (no behaviour, no GenServer, no DB).
- Public API: `evaluate_eligibility/2` → `{:ok, %Rulestead.Guardrails.AutoAdvance.Eligibility{}}` with `status: :eligible | :blocked`, `reasons: [string()]`, and bounded context fields (policy snapshot, decision summary, window closed flag).
- Composes existing `Rulestead.Guardrails.Decision.evaluate/2` — does **not** duplicate fail-closed state logic.
- **Eligible** only when **all** hold:
  - policy `enabled` with complete window + next-stage fields
  - evaluated guardrail state is `:healthy`
  - `monitoring_window_closed?` is true for the supplied `monitoring_window_ends_at` vs `evaluated_at`
  - signal facts present (non-empty) after window close
- **Blocked** with explicit reasons for: disabled/incomplete policy, `:pending_data`, `:held`, `:rollback_triggered`, empty facts after close, terminal/recoverable reasons while closed (`stale`, `insufficient_sample`, `provider_missing`, etc.), missing monitoring window end.
- Matches Phase 57 pattern (`Governance.BlastRadiusThreshold`): deterministic, IEx-testable, zero I/O.

### D-03 — Phase 61 stops at contract + eligibility (no execution)
- **D-03:** Phase 61 does **not** enqueue `ScheduledExecution`, call `advance_rollout` on eligibility success, or open change requests.
- Delivers: migration, Ecto schema, command structs, Fake/Ecto store callbacks, pure evaluator, contract tests across `@adapters [Rulestead.Fake, Rulestead.Store.Ecto]`.
- Phase 62 owns ORC-01 scheduling, governed execution, `guardrail_automation` audit evidence (AUD-03), and protected-env change-request routing (ROL-06).

### D-04 — v1.5 hold/rollback unchanged
- **D-04:** Do **not** modify `execute_guardrail_decision/7` hold/rollback branches in `store/ecto.ex` or `fake.ex`.
- Auto-advance eligibility is additive; existing `evaluate_guarded_rollout` → hold/rollback behavior is untouched (ROL-07).
- Enabling auto-advance on a rollout must not weaken, bypass, or race automatic hold/rollback.

### D-05 — Store surface and adapter parity
- **D-05:** New store callbacks (names may vary in planning) with Fake + Ecto implementations:
  - `upsert_rollout_auto_advance_policy/1`
  - `fetch_rollout_auto_advance_policy/1`
  - `evaluate_rollout_auto_advance/1` — loads policy + accepts `signal_facts` + window timestamps; returns eligibility struct (no ruleset mutation)
- Follow `guarded_rollout_test.exs` adapter parity discipline; errors via existing `Rulestead.Error` / `StoreError` shapes.

### D-06 — Observation window semantics
- **D-06:** Reuse existing `monitoring_window_started_at` / `monitoring_window_ends_at` on `AdvanceRollout` and `EvaluateGuardedRollout` commands for per-stage windows.
- Policy stores **duration** (`observation_window_seconds`); operators (or Phase 62 automation) set concrete window boundaries on each stage advance — same as today's manual advance flow.
- Eligibility evaluation receives explicit `monitoring_window_ends_at` and `evaluated_at` (default `DateTime.utc_now()` truncated); `Decision.monitoring_window_closed?/2` is authoritative.

### D-07 — Eligibility result shape (no new decision action_type yet)
- **D-07:** Return `%Rulestead.Guardrails.AutoAdvance.Eligibility{}` from evaluate command — **do not** add new `GuardrailDecision.action_type` values in Phase 61.
- Persisted `guardrail_decisions` rows for automation advances and `guardrail_automation` audit linkage ship in Phase 62.
- Store evaluate command may optionally record a non-mutating audit stub only if planning finds an existing pattern; default is eligibility result only.

### D-08 — Public facade
- **D-08:** Add thin `Rulestead` wrappers mirroring `advance_rollout` / `evaluate_guarded_rollout`:
  - `upsert_rollout_auto_advance_policy/3`
  - `fetch_rollout_auto_advance_policy/2`
  - `evaluate_rollout_auto_advance/3`
- Delegates to store; suitable for host integration tests and Phase 62 orchestration worker.

### D-09 — Four-plan execution shape
- **D-09:** Mirror Phases 57/60 plan structure:
  - **61-01** — migration + `RolloutAutoAdvancePolicy` schema + command structs (ROL-04 policy representation)
  - **61-02** — pure `Guardrails.AutoAdvance` + unit tests (ROL-05 fail-closed matrix)
  - **61-03** — Fake/Ecto store integration + facade (ROL-04 parity, ROL-07 non-regression guard)
  - **61-04** — contract tests: policy CRUD, eligibility matrix, adapter parity (SC #4)

### Claude's Discretion
- Exact module/file names if they fit existing namespaces better
- Whether `evaluate_rollout_auto_advance` loads latest `GuardrailDecision` for context or requires caller-supplied facts (prefer explicit caller facts for purity in 61-02 tests; store may enrich in 61-03)
- Migration timestamp and index naming conventions per repo norms

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/REQUIREMENTS.md` — ROL-04, ROL-05, ROL-07 acceptance criteria and capability rubric
- `.planning/ROADMAP.md` — Phase 61 goal, success criteria, phase boundary vs 62–64
- `.planning/STATE.md` — v1.8.0 decisions (reuse ScheduledExecution, no parallel decision model)
- `.planning/threads/2026-05-27-post-v1.7-milestone-assessment.md` — ROL-04 stage-plan vs admin ladder, orchestration notes

### Existing guardrail and rollout implementation
- `rulestead/lib/rulestead/guardrails/decision.ex` — fail-closed state machine, `monitoring_window_closed?`
- `rulestead/lib/rulestead/guardrails/signal_fact.ex` — host signal shape
- `rulestead/lib/rulestead/guardrail_decision.ex` — persisted decision schema and action types
- `rulestead/lib/rulestead/store/command.ex` — `AdvanceRollout`, `EvaluateGuardedRollout` command shapes
- `rulestead/lib/rulestead/store/ecto.ex` — `advance_rollout`, `evaluate_guarded_rollout`, `execute_guardrail_decision`
- `rulestead/lib/rulestead/fake.ex` — adapter parity reference
- `rulestead/test/rulestead/guarded_rollout_test.exs` — Fake + Ecto contract pattern

### Prior milestone patterns (pure policy modules)
- `.planning/milestones/v1.7.0-phases/57-blast-radius-threshold-contract/57-CONTEXT.md` — pure evaluator + store gate pattern
- `.planning/milestones/v1.7.0-phases/60-proof-docs-and-support-truth/60-CONTEXT.md` — verify.phaseNN and release-contract discipline (Phase 64 applies later)

### Operator and engineering policy
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — runtime purity, Fake adapter parity, error struct conventions
- `prompts/rulestead-domain-language-field-guide.md` — canonical rollout/guardrail vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — `:advance_rollout` authorization posture
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit correlation patterns (Phase 62 automation evidence)
- `guides/flows/rollout.md` — staged rollout operator mental model (no auto-advance claims until Phase 64)

### Admin ladder (explicitly not authoritative for policy)
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` — `@ladder_steps [5, 25, 50, 100]` UI suggestion only

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Guardrails.Decision.evaluate/2` — authoritative fail-closed evaluation; auto-advance composes this
- `Command.AdvanceRollout` / `Command.EvaluateGuardedRollout` — stage, percentage, monitoring window fields
- `GuardrailDecision` — persisted rollout stage state; Phase 62 will link automation rows
- `Rulestead.Governance.ScheduledExecution` — `:advance_rollout` action exists; scheduling deferred to Phase 62
- `Rulestead.Fake` + `Rulestead.Store.Ecto` — dual-adapter proof target

### Established Patterns
- Pure policy modules colocated under `lib/rulestead/guardrails/` or `lib/rulestead/governance/`
- Store commands in `Rulestead.Store.Command` with `GovernanceSupport` normalization
- Contract tests enumerating `@adapters [Rulestead.Fake, StoreEcto]`
- Advance records `:pending_data` + `monitoring_window_active` until evaluate closes window

### Integration Points
- New table + store callbacks; no changes to runtime snapshot evaluator hot path
- `Rulestead` facade delegates to configured store adapter
- Phase 62 Oban worker will call `evaluate_rollout_auto_advance` then governed `advance_rollout`
- Phase 63 admin reads policy via store/facade for toggle and pending state

</code_context>

<specifics>
## Specific Ideas

- Authored next-stage plan must exist before auto-advance can be enabled — not inferred from admin ladder `[5, 25, 50, 100]`
- Orchestration reuses existing `Guardrails.Decision` and governed `advance_rollout`; no parallel decision model (assessment thread)
- Fail-closed on missing provider/signals matches v1.5 operator trust bar

</specifics>

<deferred>
## Deferred Ideas

- Observation-window tick scheduling and governed `advance_rollout` execution — Phase 62 (ORC-01, ROL-06, AUD-03)
- Mounted auto-advance toggle, pending observation UI, timeline `guardrail_automation` distinction — Phase 63 (ADM-04, AUD-04)
- `mix verify.phase64`, release-contract auto-advance claims, host seam subsection — Phase 64 (VER-01–03)
- Impression-weighted guardrail thresholds / observability-backed blast radius — post-v1.8 (REQUIREMENTS deferred)
- Draft targeting presets (ADM-05) — defer

</deferred>

---

*Phase: 61-auto-advance-authored-contract*
*Context gathered: 2026-05-27*
