# Phase 23: Governed Promotion Apply - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning
**Research mode:** discuss-all with parallel advisor passes across apply entrypoint/granularity, protected-environment workflow shape, revert posture, and snapshot regeneration behavior

<domain>
## Phase Boundary

Apply whole-flag environment promotion safely through the existing mutation, approval, audit, and runtime-snapshot envelope. Phase 23 turns the Phase 22 compare contract into a real apply path for lower-risk environments and a governed promotion path for protected targets.

**In scope:**
- whole-flag authored-state promotion apply from source environment to target environment
- bounded multi-flag promotion bundles with compare-token revalidation
- protected-target promotion through existing change-request, approval, execution, and scheduling surfaces
- immutable environment-version artifacts for minimal revert-by-reapply
- transactional target snapshot regeneration and explicit post-commit runtime propagation semantics

**Out of scope (explicitly deferred):**
- partial-rule, per-field, or cherry-pick promotion UX
- unbounded release-console style bulk apply
- hidden “apply latest at execution time” semantics
- Git-first reconciliation as the primary apply path
- cluster-wide “all nodes fresh” guarantees from the admin UI

</domain>

<decisions>
## Implementation Decisions

### Apply entrypoint and granularity
- **D-01:** Phase 23 starts from the existing compare summary route, not from a new release console and not from per-flag drill-in only.
- **D-02:** Promotion apply is **whole-flag only**. Operators may select a bounded set of flags from the summary surface, but Phase 23 does not support per-rule, per-field, or partial authored-state copy.
- **D-03:** The primary workflow is `compare -> review selected set -> confirm -> direct apply or governed request -> audit`.
- **D-04:** Per-flag drill-in remains the detailed inspection surface and single-flag fallback path, not the only place promotion can begin.
- **D-05:** The initial apply surface must stay **bounded batch**, not unbounded “apply entire environment.” Favor a low-tens cap and explicit scope review over a faster but riskier bulk path.
- **D-06:** Promotion copies authored desired state only. It must not treat kill-switch state, runtime counters, telemetry artifacts, rollout progress, or snapshot freshness as authored config.

### Promotion bundle contract
- **D-07:** Promotion apply is a first-class domain action, not a UI macro over unrelated per-flag commands.
- **D-08:** The canonical apply command/bundle should carry at least:
  - `source_environment_key`
  - `target_environment_key`
  - selected `flag_keys`
  - `compare_token`
  - compare schema version
  - source/target authored fingerprints
  - dependency-closure keys/fingerprint
  - normalized proposed target authored-state bundle
- **D-09:** Apply must re-run compare/revalidation against the supplied token and fail before mutation on stale previews, blockers, or dependency drift.
- **D-10:** Admin, future CLI, and future manifest/import flows should all reuse the same promotion bundle shape rather than inventing separate apply semantics.

### Protected-environment workflow shape
- **D-11:** Protected-target promotion uses a **new first-class governed promotion action** rather than being disguised as plain `publish_ruleset`.
- **D-12:** The governed request stores the promotion bundle snapshot and compare-token context so reviewers approve an exact proposed target state, not “whatever source looks like later.”
- **D-13:** Approval and execution remain separate actions. Once approved, the same review surface reveals `Execute now` or `Schedule`, consistent with existing Phase 11/10 posture.
- **D-14:** Scheduled promotion persists the same proposal snapshot and must rerun the same stale/conflict/dependency checks at execution time before mutation.
- **D-15:** Do **not** recompute “latest source state” at execution time for protected targets. That would break the repo’s review, audit, and stale-intent guarantees.
- **D-16:** Change-request and scheduled-execution metadata must explicitly link:
  - source env
  - target env
  - compare token
  - promoted flag set
  - change request id
  - scheduled execution id when present

### Revert posture
- **D-17:** “Revert” for Phase 23 means **re-applying a prior environment configuration version as a new governed promotion**, not mutating history and not replaying arbitrary audit inverses.
- **D-18:** Every successful promotion/apply produces an immutable environment-version artifact that can later serve as the source for re-apply.
- **D-19:** Re-apply-from-history uses the same compare/apply/governance flow as forward promotion:
  - historical source version
  - current target
  - proposed target after apply
- **D-20:** `rollback_audit_event/1` remains a narrow event-level inverse-write tool for existing operational cases such as kill-switch rollback; it is not the semantic model for environment promotion revert.
- **D-21:** Environment-version artifacts must fingerprint dependency closure and preserve promotion linkage so “revert” remains explainable and safe even after unrelated later changes.
- **D-22:** Use **“Re-apply version”** as the primary operator action label. “Rollback” may appear in explanatory copy, but the product truth is a fresh governed write.

### Snapshot regeneration and runtime propagation
- **D-23:** Apply success means two linked but different truths:
  - authored target state committed
  - canonical target runtime snapshot generated
- **D-24:** Target snapshot regeneration is part of the authoritative apply transaction. If authored mutation succeeds but target snapshot generation fails, the whole apply fails and rolls back.
- **D-25:** Distributed invalidation and runtime node refresh happen **after commit**. They are real post-commit propagation work, not part of the authored transaction boundary.
- **D-26:** Notifier or PubSub failure after commit must be treated as **degraded propagation**, not as a reason to undo a valid committed authored change.
- **D-27:** The admin/operator truth model after apply should distinguish:
  - authored apply status
  - snapshot version/generated-at/published-at
  - runtime propagation state
- **D-28:** Do not imply cluster-wide freshness unless Rulestead has explicit evidence for it. Node-local/runtime propagation facts stay honest and bounded, consistent with prior observability decisions.

### Recommendation-heavy planning posture
- **D-29:** For this repo and this phase, downstream research and planning should default to **recommendation-first** decisions rather than re-asking the user about ordinary implementation tradeoffs.
- **D-30:** Only escalate future questions that would materially change product scope, public contract, security posture, or release shape. Normal implementation choices should come back with a coherent default path.

### the agent's Discretion
- Exact command/module names for promotion apply, governed promotion, and environment-version artifacts, provided promotion remains a first-class domain action
- Exact bounded-batch cap and selection UX, provided the surface stays explicit and not release-console-like
- Exact review-page layout for selected-set promotion, provided summary-first and explicit `source/current target/proposed target` language remains intact
- Exact post-commit notifier repair mechanism, provided snapshot truth stays transactional and invalidation stays advisory transport
- Exact audit event names and metadata layout, provided forward promotion, scheduled promotion, and re-apply-version all remain distinguishable and linked

</decisions>

<specifics>
## Specific Ideas

- Treat promotion like the environment-level equivalent of a clean publish review: exact proposal first, approval second, execution third.
- Learn from LaunchDarkly’s summary-plus-drill-in compare flow and optimistic-locking mindset, but avoid drifting into a release-pipeline console.
- Learn from Unleash’s validated import/change-request posture: when targets are protected, route the exact proposal into governance instead of mutating directly or recomputing later.
- Keep the operator mental model calm and explicit:
  - compare result explains what would change
  - promotion bundle captures exactly what was reviewed
  - authored apply commits target truth
  - runtime propagation converges afterward and is reported honestly
- Preserve the repo’s existing authored/runtime split: promotion changes desired config; snapshots and invalidation are downstream consequences, not the authored source of truth.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 23 goal, plan slices, and explicit revert expectation
- `.planning/REQUIREMENTS.md` — source of truth for `PROM-03` and `PROM-04`
- `.planning/PROJECT.md` — linked-version release shape, calm mounted admin posture, and `v0.6.0` product goals
- `.planning/STATE.md` — current milestone focus and planning posture

### Prior locked decisions
- `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md` — authored-state compare boundary, whole-flag posture, compare token semantics, and explicit `source/current target/proposed target` language
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — route-backed review/approval surfaces, explicit approval/execution split, and calm governance IA
- `.planning/phases/10-scheduled-changes-and-durable-execution/10-CONTEXT.md` — durable execution truth model, stale-intent posture, and scheduling semantics
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — append-only audit, explicit inverse-write rollback semantics, and operational override posture
- `.planning/phases/19-redis-storage-and-caching-adapter/19-CONTEXT.md` — runtime snapshots as distributed evaluation artifacts, not authored control-plane truth
- `.planning/phases/20-pubsub-distributed-invalidation/20-CONTEXT.md` — invalidation as advisory wake-up transport, not state replication
- `.planning/phases/21-infrastructure-observability-ui/21-01-SUMMARY.md` — node-local truth posture and additive invalidation observability

### Milestone-shape and product research anchors
- `.planning/research/V0_6_PRODUCT_SHAPE.md` — unified flag/environment overlay model, compare/apply recommendation, and rejection of Git-first primary authoring
- `prompts/elixir_feature_flags_research_brief.md` — ecosystem lessons from LaunchDarkly, Unleash, GrowthBook, Flagsmith, and related systems
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted operator IA, preview/confirm/audit spine, and route-backed heavy workflows
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — explicit seams, OSS library ergonomics, and recommendation-heavy product posture
- `prompts/rulestead-domain-language-field-guide.md` — canonical vocabulary for promotion, environment, audit, change requests, and operator copy
- `prompts/rulestead-host-app-integration-seam.md` — mounted sibling-package and host-owned integration constraints
- `prompts/rulestead-security-privacy-and-threat-model.md` — protected-environment posture, least surprise, and immutable audit/security expectations
- `prompts/rulestead-telemetry-observability-and-audit.md` — durable audit vs ephemeral telemetry boundary and propagation/status reporting expectations

### Existing code and contracts
- `rulestead/lib/rulestead/promotion/compare.ex` — compare token construction, compare result contract, authored-state projection, and blocker/warning semantics
- `rulestead/lib/rulestead.ex` — public compare, governance, audit rollback, and snapshot-related facades
- `rulestead/lib/rulestead/store/command.ex` — existing compare and governance command vocabulary that promotion apply should extend
- `rulestead/lib/rulestead/store/ecto.ex` — compare projection, current governed execution flow, snapshot insertion path, and transactional mutation spine
- `rulestead/lib/rulestead/governance/change_request.ex` — governed mutation contract and state vocabulary
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` — durable execution contract and scheduling truth model
- `rulestead/lib/rulestead/audit_event.ex` — append-only audit metadata and correlated governance fields
- `rulestead/lib/rulestead/runtime/snapshot.ex` — snapshot projection contract
- `rulestead/lib/rulestead/runtime_snapshot.ex` — persisted runtime snapshot artifact shape
- `rulestead/lib/rulestead/runtime/cache.ex` — monotonic runtime snapshot application semantics
- `rulestead/lib/rulestead/runtime/refresh.ex` — version-aware invalidation and refresh behavior
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` — summary compare route and existing entrypoint for selection/review evolution
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` — drill-in compare route and explicit three-way state review surface
- `rulestead/test/rulestead/promotion/compare_test.exs` — compare contract expectations
- `rulestead/test/rulestead/governance_safety_contract_test.exs` — approval/execution guarantees and correlation expectations
- `rulestead/test/rulestead/governance_facade_contract_test.exs` — public governance facade and typed command conventions
- `rulestead/test/rulestead/audit_event_governance_test.exs` — governance metadata serialization expectations
- `rulestead/test/rulestead/runtime_snapshot_test.exs` — runtime snapshot persistence/contract expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Promotion.Compare` already provides the correct compare-token, authored-state, finding taxonomy, and three-way source/target/proposed structure for Phase 23 apply review.
- `Rulestead.Store.Command.CompareEnvironments` already defines the right scoped inputs (`source`, `target`, optional `flag_keys`, `compare_token`) that a promotion apply command should parallel.
- The current governance stack (`ChangeRequest`, `ScheduledExecution`, public facade functions, and Ecto execution path) already supports the approval/execution/scheduling envelope that protected promotion should reuse.
- The existing runtime snapshot path already persists canonical compiled artifacts and feeds invalidation-driven convergence; Phase 23 should extend that path rather than inventing a second propagation system.
- The mounted compare LiveViews already establish the correct route-backed entrypoint plus drill-in inspection pattern that apply should grow out of.

### Established Patterns
- The repo consistently prefers explicit route-backed workflows over hidden session state or “latest state wins” magic.
- Governance review and execution are deliberately separate, and scheduled execution is product truth rather than background-job truth.
- Audit is append-only and correlation-rich. Inverse-write rollback exists for narrow operational cases, not as a generic environment restore engine.
- Runtime reads are local and compiled-snapshot based; invalidation is advisory, monotonic, and safe under duplication/out-of-order delivery.
- The project already prefers recommendation-heavy downstream work and fewer reopenings of routine tradeoffs.

### Integration Points
- A new promotion apply command should feed both direct lower-risk apply and governed protected-target apply without splitting into two incompatible domain models.
- Successful promotion should atomically mutate authored target state and create the canonical target snapshot artifact before post-commit invalidation starts.
- The compare summary page should evolve into “select set -> review promotion” while the drill-in page remains the place for exact per-flag inspection and explanation.
- Re-apply-version should reuse the same compare/apply bundle path, with historical environment-version artifacts acting as the source side.

</code_context>

<deferred>
## Deferred Ideas

- Partial-rule, per-field, or cherry-pick promotion UX (`PROM-05`)
- Unbounded “apply all changed flags in environment” console behavior
- Git-first reconcile/apply as the primary authoring model
- Automatic release-pipeline/stage-engine orchestration
- Claiming cluster-wide convergence from admin UI without explicit evidence
- Treating audit rollback as the primary environment-promotion revert model

</deferred>

---

*Phase: 23-governed-promotion-apply*
*Context gathered: 2026-05-18*
