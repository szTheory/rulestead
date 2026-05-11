# Phase 12: Webhook Ingress, Outbound Notifications, and Operator Visibility - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning
**Research mode:** one-shot advisor synthesis across inbound trust boundary, governance normalization, outbound delivery model, and mounted operator visibility

<domain>
## Phase Boundary

Normalize signed webhook-driven governance events into the same trusted mutation path already used by direct admin actions and scheduled execution, then expose webhook rejection and delivery visibility inside `rulestead_admin` without breaking the mounted sibling-package boundary.

**In scope:**
- Signed inbound webhook verification with raw-body signature validation, replay protection, and durable rejection visibility
- Normalized inbound event records that feed the existing governed mutation path instead of inventing a parallel mutation engine
- Outbound webhook destinations for bounded high-impact governance events with retry-safe delivery semantics
- Mounted admin visibility for inbound rejections, outbound delivery status, retry history, and related follow-up links

**Out of scope (explicitly deferred):**
- Generic arbitrary inbound mutation execution from third-party payloads
- Provider-specific product integrations that leak raw payload semantics through the core domain
- A standalone `rulestead_admin` integrations app or broad settings workbench expansion
- General-purpose event bus, DLQ portal, or workflow-automation platform behavior

</domain>

<decisions>
## Implementation Decisions

### Inbound Trust Boundary and Event Shape
- **D-01:** Phase 12 uses a library-owned inbound webhook verifier boundary with provider-specific verification adapters at the edge and one canonical internal inbound event envelope in `rulestead`.
- **D-02:** Signature verification proves only origin, integrity, freshness, and replay eligibility. It does **not** grant authority to mutate state by itself.
- **D-03:** Every inbound delivery attempt gets a durable receipt record with explicit fields such as provider, endpoint key, delivery id, attempt id, topic, occurred-at, received-at, raw-body verification metadata, normalized payload, dedupe key, verified state, and rejection reason.
- **D-04:** Malformed payloads, invalid signatures, stale timestamps, and replayed deliveries fail closed before any mutation path runs, but still persist operator-visible rejection records and `[:rulestead, :ops, :webhook, :rejected]` telemetry.
- **D-05:** Provider-specific payload quirks stop at the verifier/normalizer layer. Downstream governance code works from the canonical inbound event envelope and existing command structs, not raw provider payload shapes.

### Inbound Governance Normalization
- **D-06:** Accepted inbound events normalize onto the existing public governance path rather than store-internal shortcuts. The ingress layer may call `submit_change_request`, `schedule_governed_action`, or the bounded direct governed command path, but only through the same facade and authorizer seams already used by admin UI and scheduler flows.
- **D-07:** The default posture is policy-gated normalization: if the resolved approval requirement says a change request is required, inbound webhook work creates a local change request; if policy allows lower-risk direct execution or scheduling, the same bounded governance path may continue without a change request.
- **D-08:** Valid inbound events do **not** become an external-system-authoritative bypass for production governance. Rulestead remains the local source of truth for approval, execution stage, and conflict handling.
- **D-09:** The local actor chain stays explicit and honest. The acting source is a system actor such as `system:webhook:<endpoint_or_provider>`, while upstream human or system identity is preserved in metadata only. Rulestead must not impersonate an upstream human as the local executor.
- **D-10:** Inbound webhook support stays bounded to the existing high-impact governed action set already coherent with this milestone: publish, rollout advance, kill-switch engage/release, and closely related governed actions already represented by current contracts. It must not become arbitrary admin mutation plumbing in Phase 12.
- **D-11:** Stale, conflicting, or no-longer-valid inbound intent fails visibly and explicitly instead of mutating toward the nearest available state. Phase 10 conflict posture applies here too.

### Outbound Destination and Delivery Model
- **D-12:** Phase 12 persists named outbound webhook destinations in core, scoped by environment, with explicit subscriptions from a small fixed enum of high-impact governance events.
- **D-13:** New destinations default to a strong preset such as `all_high_impact_governance_events`; narrowing subscriptions is allowed, but the product should not force checkbox-heavy decision-making during the happy path.
- **D-14:** Outbound product truth lives in durable destination, event, and delivery records inside `rulestead`; Oban remains the delivery substrate rather than the only state model.
- **D-15:** Each delivery attempt is replay-safe and correlated by durable delivery identity. Automatic retries are bounded and visible; exhausted retries stop and require explicit operator action instead of silent background retry forever.
- **D-16:** Delivery uses explicit HTTP client semantics with bounded timeouts, signed payloads, dedupe/idempotency headers where appropriate, and secret handling that keeps sensitive values out of immutable audit and UI surfaces.
- **D-17:** Phase 12 does not choose the host-callback-only model for outbound notifications. The library owns the reliable delivery and visibility substrate so operators are not forced to rebuild retry, delivery history, and failure inspection in every host app.

### Mounted Operator Visibility
- **D-18:** Phase 12 adds a dedicated mounted `Webhooks` hub with route-backed list and detail pages, following the same hub-and-spoke IA used for change requests and schedule surfaces in Phase 11.
- **D-19:** The canonical mounted routes stay under the existing admin mount path and preserve canonical `?env=` state. Concretely: `/admin/flags/webhooks` and `/admin/flags/webhooks/:id` or the equivalent mounted-path-relative pair.
- **D-20:** The webhook hub is the primary operator surface for inbound rejections, outbound delivery attempts, retry state, and correlation links. `Audit` remains append-only history, and `Settings` remains configuration-oriented; neither becomes the primary webhook triage surface.
- **D-21:** Detail pages use one normalized route shell with explicit type labels such as `Inbound rejection`, `Inbound accepted event`, and `Outbound delivery`, plus links back to the related flag, change request, scheduled execution, and audit context where present.
- **D-22:** Existing flag, change-request, and schedule routes may add compact read-only summary links/cards into the webhook hub, but they do not become inline delivery workbenches.
- **D-23:** Operator wording stays explicit and least-surprise: `received from`, `rejected by verifier`, `requested by webhook`, `delivered to`, `retried by worker`, `failed after retries`.

### Defaults and Recommendation Posture
- **D-24:** Downstream planning and implementation should assume strong defaults and left-shifted recommendations for webhook behavior, subscriptions, and UI layout. Future GSD work should only escalate questions that materially change external contracts, security posture, or operator mental model.

### the agent's Discretion
- Exact module split between verifier, provider adapter, receipt record, delivery worker, and mounted LiveViews, provided the trust boundary and same-path normalization stay intact.
- Exact event enum names and subscription preset naming, provided the enum stays small, governance-focused, and operator-readable.
- Exact durable schema split between inbound receipts, outbound events, outbound deliveries, and replay claims, provided product truth stays in Rulestead tables and correlation is preserved.
- Exact admin filter controls, groupings, and row density, provided the webhook hub remains list-first, route-backed, and calm under incident use.

</decisions>

<specifics>
## Specific Ideas

- Treat `verified transport != authorized mutation` as the core Phase 12 design rule.
- Follow the existing repo posture: explicit over magic, preview/confirm/audit for human-driven work, honest actor chains, and no hidden background mutation semantics.
- Learn from Stripe, GitHub, and Svix on raw-body verification, constant-time comparison, timestamps, duplicates, and replay windows.
- Learn from Unleash and LaunchDarkly on keeping approvals, schedules, conflicts, and operator review as first-class local workflow objects instead of letting external systems bypass them.
- Learn from GitHub, Stripe, and CircleCI on outbound destinations: named endpoints, bounded event subscriptions, durable delivery attempts, and operator-visible retries.
- Use calm route-backed operator UX closer to Phase 11 schedule/change-request surfaces than to a drawer-heavy settings screen or a calendar-style workbench.
- Preference note from the user for this project: shift recommendation work left within GSD and only escalate webhook choices that are truly high-impact.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 12 goal, plan slices, and explicit webhook boundary within the governance milestone
- `.planning/PROJECT.md` — milestone posture, sibling-package constraints, and explicit operator-trust goals
- `.planning/REQUIREMENTS.md` — source of truth for `HOOK-01`, `HOOK-02`, `HOOK-03`, and `HOOK-04`
- `.planning/STATE.md` — confirms Phase 12 is the current frontier and Phase 11 is already complete

### Prior Locked Decisions
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — append-only audit posture, route-backed admin flows, and explicit operator-trust constraints
- `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-CONTEXT.md` — sibling-package release boundary and public-surface discipline
- `.planning/phases/10-scheduled-changes-and-durable-execution/10-CONTEXT.md` — product-truth-vs-Oban semantics, bounded retry posture, actor-chain honesty, and conflict handling
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — mounted route philosophy, canonical `?env=` model, summary-card posture, and calm operator IA
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-01-SUMMARY.md` — governance actor/correlation model and fixed vocabulary
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-02-SUMMARY.md` — governance command normalization and immutable audit metadata posture
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-03-SUMMARY.md` — host-owned policy seam and fail-closed approval requirement resolution
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-04-SUMMARY.md` — same admin envelope for governed writes and two-step approve/execute contract
- `.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-05-SUMMARY.md` — persisted governance-context authorization and direct publish governance guardrails

### Product, Security, and Integration Direction
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed webhook posture, replay protection, immutable audit, and redaction/security principles
- `prompts/rulestead-telemetry-observability-and-audit.md` — canonical webhook telemetry tuples and audit/telemetry separation
- `prompts/rulestead-host-app-integration-seam.md` — host integration posture, mounted seam, and existing config direction including webhook-related config space
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted operator IA, route-backed workflow patterns, and settings vs workflow separation
- `prompts/rulestead-domain-language-field-guide.md` — canonical webhook/administrative wording and event naming direction
- `prompts/rulestead-brand-book.md` — calm infrastructure-grade copy posture for operator-facing surfaces

### Existing Code and Contracts
- `rulestead/lib/rulestead.ex` — public governance and scheduled-execution facade that inbound webhook normalization must reuse
- `rulestead/lib/rulestead/store.ex` — store behavior surface that webhook records and delivery flows should extend coherently
- `rulestead/lib/rulestead/store/command.ex` — normalized actor/metadata envelope and bounded governance command style
- `rulestead/lib/rulestead/store/ecto.ex` — transactional governance persistence, schedule semantics, and audit-correlation patterns
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` — current source-of-truth execution object and actor/execution-stage vocabulary
- `rulestead/lib/rulestead/oban.ex` — bounded Oban serialization seam
- `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` — worker-side context restoration and product-truth-vs-job-state pattern
- `rulestead/lib/rulestead/audit_event.ex` — immutable audit metadata normalization expectations
- `rulestead/lib/rulestead/telemetry.ex` — canonical telemetry metadata and event-field allowlisting
- `rulestead_admin/lib/rulestead_admin/router.ex` — current mount seam and route shape Phase 12 should extend
- `rulestead_admin/lib/rulestead_admin/live/schedule_live/index.ex` — dense route-backed operator list precedent
- `rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex` — route-backed detail precedent for state, actor chain, and explicit follow-up actions
- `rulestead/doc/admin-ui.md` — host-facing mounted admin navigation contract that Phase 12 UI work may need to extend carefully

### Ecosystem References
- `https://hexdocs.pm/plug/Plug.Parsers.html` — raw-body verification via `:body_reader`
- `https://hexdocs.pm/plug/Plug.Conn.html` — request body handling and halt behavior
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — atomic persistence for receipt/replay/mutation/audit boundaries
- `https://hexdocs.pm/oban/job_lifecycle.html` — bounded retry and terminal-state semantics
- `https://hexdocs.pm/oban/unique_jobs.html` — duplicate-work prevention for delivery/replay handling
- `https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries` — HMAC validation posture
- `https://docs.github.com/en/webhooks/using-webhooks/handling-webhook-deliveries` — delivery history and replay/debug posture
- `https://docs.stripe.com/webhooks` — raw-payload verification, retries, and delivery semantics
- `https://docs.getunleash.io/concepts/change-requests` — governance workflow posture for external triggers
- `https://launchdarkly.com/docs/home/releases/approval-reviews` — review and approval workflow lessons
- `https://launchdarkly.com/docs/home/releases/scheduled-changes-manage` — conflict handling and operator warning posture

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead` public governance and schedule verbs already expose the mutation path webhook ingress should reuse instead of bypassing.
- `Rulestead.Store.Command.GovernanceSupport` already normalizes actor and metadata envelopes into string-keyed maps while stripping session-shaped fields.
- `Rulestead.Store.Ecto` already provides transactional audit correlation, persisted execution records, and bounded retry/quarantine semantics that webhook work can mirror.
- `Rulestead.Oban` and `Rulestead.Oban.ScheduledExecutionWorker` already establish the pattern that durable application records are the product truth and Oban jobs are the execution substrate.
- `RulesteadAdmin.Live.ScheduleLive.Index` and `.Show` already provide a strong mounted operator pattern for list-first scanning and explicit detail routes.

### Established Patterns
- Governed writes stay inside the existing admin authorization and redaction envelope rather than introducing a second mutation engine.
- The codebase prefers key-first explicit command structs, persisted correlation identifiers, and fail-closed policy resolution.
- Mounted admin screens use route-backed workflows, canonical `?env=` state, compact summary links, and calm read surfaces rather than inline workbenches.
- Audit is durable truth; telemetry is correlated but ephemeral. Webhook surfaces must preserve that distinction.

### Integration Points
- Inbound webhook verification should connect at the Plug/router edge, then terminate in core command/facade calls rather than controller-specific business logic.
- Durable receipt, replay, event, and delivery records should integrate with the existing audit and telemetry spine through shared correlation ids and linked governance objects.
- Outbound delivery should enqueue through the same transactional `Ecto.Multi` mindset already used for schedule persistence and execution.
- Mounted webhook visibility should integrate with existing flag, change-request, and schedule routes via deep links and summary cards, not duplicated workflow logic.

</code_context>

<deferred>
## Deferred Ideas

- Provider marketplace breadth beyond a small bounded provider/verifier set
- Generic manual-review inbox mode for low-trust inbound integrations
- Rich settings-centric integrations workbench, secret rotation UI, or destination health dashboards beyond Phase 12 visibility needs
- General-purpose event bus, audit export sinks, or non-webhook notification channels
- Arbitrary inbound admin mutation support beyond the bounded governance action set

</deferred>

---

*Phase: 12-webhook-ingress-outbound-notifications-and-operator-visibili*
*Context gathered: 2026-04-24*
