# Phase 7: Admin UI - Simulation, Rollouts, Kill Switch, Audit, Security & Redaction - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Research mode:** one-shot synthesis from 4 parallel advisor passes across simulation UX, rollout controls, kill switch flow, and audit/security

<domain>
## Phase Boundary

Ship the second operator-facing half of `rulestead_admin` and the security envelope that makes it safe to run in production. Phase 7 completes the high-value operator workflows that justify the admin package: per-flag simulation/explain, rollout controls, a bookmarkable kill switch, a real audit timeline, policy enforcement, telemetry/audit redaction, and custom Credo checks that turn discipline into tooling.

**In scope:**
- Per-flag simulation/explain surface for one actor/context at a time
- Saved archetypes and copy-as-test-fixture flow
- Rollout control UX for deterministic sticky exposure ramps
- Per-flag per-environment kill switch with visible active state and safe restore
- Full audit timeline and rollback-as-inverse-write workflow
- `Rulestead.Admin.Policy` enforcement before every mutation
- Environment-sensitive authz defaults and typed unauthorized failures
- Telemetry/audit trait allowlisting and default redaction
- Phase 7 Credo checks for telemetry/logger hygiene, mutation discipline, LiveView async safety, and evaluation entrypoint discipline

**Out of scope (explicitly deferred):**
- Scheduled rollout automation, approval workflows, and change requests as first-class Phase 7 UI states
- Multi-flag playgrounds and broad diagnostics consoles
- Tenant-wide governance features, managed owner directories, and broader compliance workflows
- Phase 8 docs/publication artifacts and any publish-prep work for `rulestead_admin`

</domain>

<decisions>
## Implementation Decisions

### Simulation and Explain Surface
- **D-01:** Use one dedicated per-flag simulation screen at `/admin/flags/:key/simulate?env=...` rather than embedding simulation into the detail page or rules workspace.
- **D-02:** Keep simulation and explain on the same screen: enter or apply a context, submit once, then read the result summary first and expand trace detail only on demand.
- **D-03:** Preserve the Phase 6 surface boundaries. The detail page stays the calm read surface, the rules page stays the authoring surface, and simulation is its own operator/debug screen.
- **D-04:** The default result view shows only the highest-signal facts first: matched rule or default path, returned value/variant, reason, bucket result, snapshot version, and cache age.
- **D-05:** Per-rule pass/fail detail, bucket math inputs, and raw-ish trace structure live behind progressive disclosure rather than being dumped in full by default.
- **D-06:** Saved archetypes are part of Phase 7, but they are scoped to the simulation surface as reusable operator presets, not a generalized user-profile management system.
- **D-07:** The “Copy as test fixture” action must export an Elixir-friendly context literal shaped for direct ExUnit use so support and app engineers can move from “why did this happen?” to a regression test with minimal friction.
- **D-08:** Do not introduce persisted simulation runs or a separate explanation-history store in Phase 7. Sharing happens by URL plus rerunnable inputs, not by a new run-record system.

### Rollout Controls
- **D-09:** Keep the Phase 6 draft/publish boundary intact. Rollout editing is responsive and preview-rich, but it still operates inside explicit draft state and explicit publish actions.
- **D-10:** Use a hybrid LiveView editing model: optimistic local form updates and server-validated preview feedback during editing, with explicit confirmation for publish and for high-risk jumps.
- **D-11:** Phase 7 rollout control advances exposure percentage, not variant composition. Variant weights stay stable while the eligible audience widens monotonically.
- **D-12:** The rollout UI must visually reinforce ordered first-match-wins semantics so operators can see where the rollout rule sits relative to surrounding rules.
- **D-13:** Suggested next steps such as `5% -> 25% -> 50% -> 100%` are recommendations, not automation. They exist to reduce hesitation and encourage safe staged ramps.
- **D-14:** The preview panel simulates a bounded sample of targeting keys to compare intended exposure/variant weights against observed assignment distribution before publish.
- **D-15:** Do not auto-persist rollout changes on every interaction. Hidden persistence is a footgun for an OSS mountable admin package and conflicts with the project’s explicitness bias.
- **D-16:** Do not add built-in scheduled/progressive rollout runners in Phase 7. That is a future governance/automation concern, not part of this first coherent rollout surface.

### Kill Switch Flow
- **D-17:** Use a dedicated kill-switch page at `/admin/flags/:key/kill?env=...` as the canonical emergency control surface.
- **D-18:** The kill switch is implemented as a per-flag per-environment override record that forces evaluation to the flag’s default value while leaving authored rules and rollout definitions untouched underneath.
- **D-19:** Restore clears the override and returns the environment to its prior authored behavior. Restore is idempotent and must not require replaying audit history to reconstruct state.
- **D-20:** The flag detail page must show a prominent banner whenever a kill switch is active and provide a direct restore affordance from that banner.
- **D-21:** Production activation requires typed-key confirmation. Non-production may use lighter confirmation, but still records audit and telemetry.
- **D-22:** Do not model “kill switch” as editing the primary rule tree or toggling the flag’s authored state off in place. That creates restore ambiguity and makes incident behavior harder to reason about.
- **D-23:** Kill and restore both emit explicit audit rows and explicit telemetry. The kill switch is an operational override, not an invisible implementation detail.

### Audit Timeline and Rollback
- **D-24:** Use one append-only redacted audit ledger and expose it through two surfaces: a per-flag timeline and a global audit timeline.
- **D-25:** The per-flag route is the day-to-day author/support surface; the global route exists for SRE and cross-flag investigation by actor, environment, date range, and mutation type.
- **D-26:** Before/after diff presentation must be structured and readable, with syntax-highlighted JSON only where it adds clarity rather than becoming the default entire payload view.
- **D-27:** Rollback is implemented as an inverse write that creates a new audit event linked back to the prior event. History is never erased or edited in place.
- **D-28:** Audit rows must record denied mutations as well as successful ones when Phase 7 policy checks reject an action. Denied actions are part of the security story, not silent failures.
- **D-29:** Actor identity remains an explicit host seam via `Rulestead.ActorResolver`; the library does not assume a built-in auth stack or actor schema.

### Policy, Authz, Redaction, and Credo Discipline
- **D-30:** Every admin mutation checks `Rulestead.Admin.Policy.can?(actor, action, resource, env)` before attempting the write.
- **D-31:** Default authz posture is environment-sensitive and conservative: read-only for viewers, non-prod edit for standard engineering/operator roles, and stricter explicit policy for production edits.
- **D-32:** Unauthorized mutations return typed auth errors and are also audit-visible as denied actions.
- **D-33:** Telemetry and audit surfaces default to redaction. Trait values are only preserved when explicitly allowlisted; otherwise they are replaced with sentinels or redacted representations before emission or persistence.
- **D-34:** Redaction happens before persistence/emission, not only in downstream rendering. Raw trait payloads must never become the stored source of truth for telemetry/audit rows.
- **D-35:** The highest-value strict Phase 7 Credo checks are:
  - `NoRawTraitsInTelemetryMeta`
  - `NoRawTraitsInLogger`
  - `NoMutationOutsideMulti`
  - `NoSocketCapturedInAsync`
  - `NoEvalOutsideContext`
- **D-36:** `NoUnscopedTenantQueryInLib` should land only if the sanctioned tenancy-scope helper is already the single clear path. Otherwise keep the check present but softer until the tenancy seam is fully real, so the rule does not outrun the architecture.

### the agent's Discretion
- Exact LiveView/module split for the new Phase 7 screens, provided route-backed boundaries remain intact
- Exact archetype persistence shape, provided it stays scoped to simulation and avoids becoming user-profile management
- Exact threshold policy for “risky” rollout jumps, provided publish remains explicit and small edits stay responsive
- Exact diff renderer implementation, provided it stays redacted, readable, and append-only in semantics
- Exact storage format for kill-switch override records, provided restore is clean and underlying authored rules remain untouched

</decisions>

<specifics>
## Specific Ideas

- Learn from LaunchDarkly, Unleash, GrowthBook, Flipt, Statsig, and Flipper without copying their entire surface area. What they consistently get right is explicit rule ordering, simulation before publish, env-scoped operational controls, and clear restore/history semantics.
- Avoid two common footguns from the space:
  - hidden persistence or silent rebucketing during rollout editing
  - emergency controls that mutate authored state and make restore ambiguous
- For Phoenix/LiveView specifically, favor route-backed screens, `handle_params`-driven env/filter state, server-validated forms, and bounded client-side enhancement over a JS-heavy console that fights the rest of the package.
- For Ecto specifically, every successful mutation should stay inside one explicit `Ecto.Multi` that also writes the audit row; do not rely on magic versioning layers that can capture raw unredacted payloads behind the library’s back.
- For DX, the simulation screen should end in concrete outputs engineers can use immediately: an ExUnit-ready context literal, a stable summary of why the decision happened, and enough trace detail to debug without forcing them to read a raw runtime struct dump.
- For operator calm, keep “what happened?” and “what can I safely do next?” visible at a glance: result summary, suggested rollout ladders, active kill banner, readable audit diff, and clearly prod-scoped affordances.
- Planning note: `.planning/ROADMAP.md` contains Phase 7, but `gsd-sdk query init.phase-op 7` currently returns `phase_found: false`. Downstream automation should repair that mismatch before plan/execution commands depend on SDK discovery.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 7 goal, scope, success criteria, and explicit boundary against Phase 8
- `.planning/PROJECT.md` — project non-negotiables: calm admin, explicit seams, no PII leakage, host-owned auth, mountable sibling-package design
- `.planning/REQUIREMENTS.md` — source of truth for `ADMIN-04..07`, `ADMIN-09`, `SEC-01..04`, and `TEL-03`
- `.planning/STATE.md` — current phase sequencing and the Phase 6 -> Phase 7 transition context

### Prior Locked Decisions
- `.planning/phases/03-context-rules-deterministic-bucketing-pure-evaluator/03-CONTEXT.md` — explain/debug substrate, deterministic bucketing semantics, and no hidden evaluator lookup behavior
- `.planning/phases/04-snapshot-cache-runtime-refresh-telemetry-explain-wiring/04-CONTEXT.md` — runtime diagnostics envelope, telemetry metadata spine, and redaction-at-emission expectations
- `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-CONTEXT.md` — Phase 6 admin boundaries, env query-param model, calm detail page, dedicated rules workspace, and explicit production emphasis

### Product, UX, and Security Direction
- `prompts/rulestead-admin-ux-and-operator-ia.md` — simulation, explain, audit, rollout, and kill-switch IA direction
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned auth, least privilege, redaction boundary, and audit/security posture
- `prompts/rulestead-telemetry-observability-and-audit.md` — event catalog direction, audit-vs-telemetry distinction, and redaction principles
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — Shiori, Sam, Priya, and Tova workflows that Phase 7 must satisfy
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — custom Credo checks, audit discipline, LiveView async footguns, and operator-tool patterns
- `prompts/rulestead-domain-language-field-guide.md` — canonical wording for kill switch, engage/release, audit language, and operator nouns
- `prompts/elixir_feature_flags_research_brief.md` — prior-art lessons for simulation, rollout, explainability, and feature-flag footguns

### Existing Code and Contracts
- `rulestead_admin/lib/rulestead_admin/router.ex` — current mount seam and existing Phase 6 route shape
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — current env/session/policy resolution model
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — current detail-page boundary and explicit Phase 7 placeholder
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rules.ex` — existing draft/publish authoring workflow that rollout controls must not undermine
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — production emphasis and shared shell conventions
- `rulestead_admin/README.md` — explicit note that Phase 7 surfaces are not shipped yet
- `rulestead/lib/rulestead.ex` — public admin/runtime entrypoints and telemetry-wrapped mutation surface
- `rulestead/lib/rulestead/admin/policy.ex` — host-owned authorization seam
- `rulestead/lib/rulestead/audit_event.ex` — current audit-event schema baseline Phase 7 will extend/query
- `rulestead/lib/rulestead/telemetry.ex` — telemetry metadata/redaction expectations and event shape
- `rulestead/lib/rulestead/kill_switch_error.ex` — typed kill-switch error baseline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RulesteadAdmin.Router` already gives Phase 7 the correct mount seam and route style. New workflows should extend this surface rather than inventing a separate router model.
- `RulesteadAdmin.Live.Session` already resolves the current actor, environment, available environments, and host policy module. Phase 7 should build directly on this seam for env-sensitive authz.
- `RulesteadAdmin.Live.FlagLive.Show` already reserves the detail page as the calm read surface and explicitly leaves audit/kill/simulation out of Phase 6.
- `RulesteadAdmin.Live.FlagLive.Rules` already models the explicit draft/save/publish workflow that rollout UX must preserve.
- `Rulestead.AuditEvent` already exists as the append-only row shape baseline, even though Phase 7 must make it richer and query-friendly.
- Phase 4 already locked runtime explain and diagnostics facts that the simulation page should render rather than recomputing independently.

### Established Patterns
- The repo consistently prefers explicit seams over magic: host policy instead of bundled auth, explicit runtime APIs instead of hidden global lookups, explicit draft/publish rather than autosave mutability.
- URL-backed environment state is already canonical for admin pages. Phase 7 should keep using `?env=` rather than splitting semantics across path, session, and transient assigns.
- The codebase already treats telemetry and audit as bounded structured contracts, which makes “redact before emit/persist” a natural continuation rather than a new philosophy.

### Integration Points
- Simulation should consume the existing runtime explain/result surface, not create a second evaluation engine inside `rulestead_admin`.
- Rollout controls must compose with the existing rules workspace and published ruleset model rather than bypassing it with side-channel mutations.
- Kill-switch state should integrate with runtime snapshot refresh and the existing telemetry/audit mutation surface.
- Audit queries will need both per-flag and cross-flag read paths, but should still resolve through one shared redacted audit-event model to avoid divergence between operator surfaces.

</code_context>

<deferred>
## Deferred Ideas

- Scheduled or automated rollout ladders, approvals, and change-request orchestration
- Persisted explanation runs or simulation history stores
- Cross-flag multi-result playgrounds and broader diagnostics workbenches
- Compliance-grade DB trigger history systems or adapter-specific audit frameworks
- Strong tenancy linting as a hard failure before the tenancy seam itself is fully real

</deferred>

---

*Phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction*
*Context gathered: 2026-04-23*
