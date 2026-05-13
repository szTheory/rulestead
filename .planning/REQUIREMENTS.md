# Requirements: Rulestead

**Defined:** 2026-04-24
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v0.2.0 Requirements

### Governance (GOV)

- [x] **GOV-01**: Operator can submit a change request instead of directly executing a governed production mutation.
- [x] **GOV-02**: Host policy can require approvals by environment and action for publish, rollout, kill-switch, and settings mutations.
- [x] **GOV-03**: Default governance policy prevents self-approval for production change requests unless the host explicitly overrides it.
- [x] **GOV-04**: Approval, rejection, execution, and cancellation of change requests append correlated immutable audit events.
- [ ] **GOV-05**: Admin review surfaces show diff, simulation context, actor, environment, and approval state before execution.

### Scheduled Changes (SCH)

- [x] **SCH-01**: Operator can schedule a ruleset publish, rollout advance, or kill-switch action for future execution.
- [x] **SCH-02
**: Scheduled changes execute durably and idempotently through the supported job path, surviving retries and restarts without duplicate side effects.
- [ ] **SCH-03**: Operator can view upcoming, completed, failed, and canceled scheduled changes in the mounted admin UI.
- [x] **SCH-04**: Execution of a scheduled change records audit correlation and exposes operator-meaningful status and failure reason.

### Webhooks & Integrations (HOOK)

- [x] **HOOK-01**: Rulestead can verify and reject malformed, unsigned, or replayed inbound webhook mutations before any state change occurs.
- [x] **HOOK-02**: Accepted inbound webhook events normalize into the same governed mutation path used by the admin UI and preserve audit metadata.
- [x] **HOOK-03**: Host can configure outbound webhook destinations for high-impact governance events with retry-safe delivery semantics.
- [x] **HOOK-04**: Operators can inspect webhook delivery status or rejection reason without leaving the mounted admin surface.

### Operational Follow-through (OPS)

- [ ] **OPS-01**: The remaining `v0.1.0` Phase 7 sibling-package verification gap is closed from the real `rulestead_admin` entrypoint.
- [x] **OPS-02**: The published-release verification script captures live evidence for `0.1.0` as soon as both packages are visible on Hex.
- [ ] **OPS-03**: Release follow-through for the carryover items does not weaken the linked-version, two-package release workflow.

## vNext Requirements

### Experiments & Ecosystem

- **EXP-01**: Impression and conversion hooks expand into experiment analytics and guardrail metrics.
- **ECO-01**: OpenFeature provider bridge and broader external ecosystem adapters land as a separate milestone.
- **ECO-02**: Redis or other non-Postgres store adapters expand runtime/store topology.
- **ECO-03**: Emit deliberate telemetry events for all state mutations (publish, kill-switch, rollouts) to serve as deploy markers for SRE tools like Parapet.
- **ECO-04**: Ensure Rulestead evaluation context can seamlessly ingest cross-library metadata (e.g., Scoria trace IDs, Cairnloop ticket states) for deterministic bucketing.
- **ECO-05**: Design Rulestead's admin APIs such that they can be easily wrapped as MCP (Model Context Protocol) Tools for AI agents (e.g., Scoria).

### Platform Expansion

- **PLAT-01**: Import/export grows beyond current snapshot-oriented flows.
- **PLAT-02**: Multi-tenant helpers and broader namespace/project organization ship after governance fundamentals.
- **PLAT-03**: OpenTelemetry bridging and richer ops telemetry surfaces move forward once governance state transitions are stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full experimentation analytics | Different milestone with separate statistical and tracking requirements |
| New admin packaging or publish posture | Current release design keeps `rulestead_admin` as a sibling package, not a separately prepared release target |
| Streaming real-time updates | Useful later, but not required for the current governance and scheduling safety slice |
| Broad manifest import/export expansion | Governance can ship against the existing runtime/store foundation |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GOV-01 | Phase 9 | Completed in 09-02 |
| GOV-02 | Phase 9 | Completed in 09-03 |
| GOV-03 | Phase 9 | Completed in 09-03 |
| GOV-04 | Phase 9 | Completed in 09-02 |
| GOV-05 | Phase 11 | Pending |
| SCH-01 | Phase 10 | Completed in 10-01 |
| SCH-02 | Phase 10 | Completed in 10-02 |
| SCH-03 | Phase 11 | Pending |
| SCH-04 | Phase 10 | Completed in 10-02 |
| HOOK-01 | Phase 12 | Implemented |
| HOOK-02 | Phase 12 | Completed in 12-02 |
| HOOK-03 | Phase 12 | Implemented |
| HOOK-04 | Phase 12 | Implemented |
| OPS-01 | Phase 13 | Pending |
| OPS-02 | Phase 13 | Completed in 13-02 |
| OPS-03 | Phase 13 | Pending |

**Coverage:**
- v0.2.0 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-04-24*
*Last updated: 2026-04-24 after completing 10-02*
