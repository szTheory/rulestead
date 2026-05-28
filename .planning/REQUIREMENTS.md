# Requirements: Rulestead — v1.11 Integration Spine (docs-only)

**Defined:** 2026-05-28
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.11 Requirements

Docs-only milestone — no new runtime or admin product APIs. Closes INV-INTRO-01 (intro spine missing Plug/supervision/lifecycle).

### Integration Spine (`INT`)

- [ ] **INT-01**: A first-hour Phoenix integration spine documents supervision → `config :rulestead` → Plug/context seam → first `Rulestead.Runtime` keyed evaluation with explicit `%Rulestead.Context{}`.
- [ ] **INT-02**: Flag creation in the spine requires lifecycle fields (`owner` + `expected_expiration`) with honest host-owned ownership copy and a link to [flag-lifecycle](../guides/flows/flag-lifecycle.md).
- [ ] **INT-03**: README, getting-started, and installation cross-link the spine as the canonical first-hour path (installer remains the entry command).

### Evaluation & Lifecycle Docs (`DOC`)

- [ ] **DOC-01**: `guides/flows/evaluation.md` names `Rulestead.Runtime` keyed lookup APIs with examples; payload-first contract remains primary.
- [ ] **DOC-02**: Intro docs (getting-started, installation) include a lifecycle-required-fields callout on flag create (closes INV-INTRO-01 narrative).
- [ ] **DOC-03**: `rulestead/README.md` API ordering aligns with footguns and evaluation spine (Runtime for keyed lookup; root module payload-first).

### Proof & Contract Guards (`VER`)

- [ ] **VER-01**: `release_contract_test.exs` (or dedicated doc contract test) guards intro spine presence and lifecycle-field mention in spine/getting-started.
- [ ] **VER-02**: `mix verify.phase76` flat-unions phase73 plus v1.11 doc contract guards; `mix verify.adopter` delegates to phase76 (or documents phase76 as successor).

### Milestone Auditability (`AUD`)

- [ ] **AUD-01**: `STATE.md` marks INV-INTRO-01 **Closed** with proof command pointers.
- [ ] **AUD-02**: `v1.11-MILESTONE-AUDIT.md` records integration-spine closure evidence and proof spine.

## Future Requirements (deferred)

### v2 wedges (triggered only)

- **GOV-02-ext**, **ROL-08**, **ADM-06** — see `.planning/DEFERRED.md`

## Out of Scope

| Feature | Reason |
|---------|--------|
| New runtime or admin product APIs | v1.11 is docs/guides only |
| Admin UI redesign or new mounted flows | v2 / separate phase |
| GOV-02-ext / ROL-08 / ADM-06 | v2; requires deferred trigger |
| Kitchen-sink `mix verify.all` | Per-phase verify DNA |
| Replacing `mix rulestead.install` UX | Installer ships; spine documents what it wires |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INT-01 | Phase 76 | Pending |
| INT-02 | Phase 76 | Pending |
| INT-03 | Phase 76 | Pending |
| DOC-01 | Phase 77 | Pending |
| DOC-02 | Phase 77 | Pending |
| DOC-03 | Phase 77 | Pending |
| VER-01 | Phase 78 | Pending |
| VER-02 | Phase 78 | Pending |
| AUD-01 | Phase 78 | Pending |
| AUD-02 | Phase 78 | Pending |

**Coverage:**

- v1.11 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-28*
*Last updated: 2026-05-28 — v1.11 milestone initialized*
