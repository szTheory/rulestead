# Requirements: v1.3.0 - Adopter Truth & Proof Closure

**Defined:** 2026-05-24
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.3.0 Requirements

### Release Truth & Docs (`DOC`)

- [x] **DOC-01**: Root and sibling package READMEs describe the shipped post-`v1.0.0` release posture, linked-version sibling-package model, and mounted-admin companion scope without stale pre-GA messaging.
- [x] **DOC-02**: Installation, onboarding, and support-facing docs explain the real current package, migration, demo, and verification posture without implying stronger proof than the repo currently provides.

### Runtime Contract Parity (`PAR`)

- [ ] **PAR-01**: The `rulestead` authored flag schema, Ecto migrations, and installer-facing database story agree on lifecycle and ownership fields end to end.
- [ ] **PAR-02**: Repo proof covers the lifecycle/ownership contract through migrations and runtime tests so adopters do not discover missing authored-state columns only after installation.

### Mounted Companion Proof (`ADM`)

- [ ] **ADM-01**: The mounted admin lifecycle form and permission contract expose one deliberate host-facing truth, with tests and docs aligned to the supported behavior.

### Cross-Package Verification (`VER`)

- [ ] **VER-01**: `rulestead` and `rulestead_admin` verification surfaces are green again, or any intentionally deferred failures are explicitly documented and bounded in release-facing truth.

### OpenFeature Bridge Proof (`OFE`)

- [ ] **OFE-01**: `open_feature_rulestead` has a runnable documented proof path that either passes in-repo verification or states its exact bounded support caveat honestly.

## Future Requirements

### Deferred Beyond v1.3.0

- **ROL-01**: Rollouts can attach host-supplied guardrail signals to staged progression and stop or roll back on explicit thresholds without widening Rulestead into an observability product.
- **ROL-02**: Guarded rollout decisions remain deterministic, tenant-aware, audited, and fail-closed when signals are weak, stale, or missing.
- **SEG-01**: Reusable targeting begins with shared audiences and impact previews before any broader targeting-template system.
- **SEG-02**: Shared targeting assets preserve explainability, compare correctness, import/export validity, and promotion safety without hidden inheritance graphs.

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| `rulestead` runtime docs, migrations, and installer truth | `core` | In scope |
| `rulestead_admin` mounted contract proof | `companion` | In scope |
| `open_feature_rulestead` bridge proof | `companion` | In scope |
| Standalone admin product posture | `defer` | Out of scope |
| New rollout or targeting capabilities | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| `rulestead` | README/release-contract checks plus migration/schema parity tests | demo walkthrough confirmation |
| `rulestead_admin` | targeted lifecycle and permission contract suites | manual mounted smoke path |
| `open_feature_rulestead` | runnable tests or explicit bounded-support documentation | demo integration notes |

## Support Truth Gate

| Surface | Required Truth |
|---------|----------------|
| Root + package READMEs | Must state the shipped GA/post-GA posture and sibling-package relationship accurately. |
| Installer and migrations | Must match the authored lifecycle/ownership contract adopters install into host apps. |
| Mounted admin | Must remain a mounted companion with host-owned auth, identity, and operator policy seams. |
| OpenFeature bridge | Must be either runnable now or clearly bounded as a companion proof surface. |

## Out of Scope

| Feature | Reason |
|---------|--------|
| New guarded rollout mechanics | Reserved for `v1.4.0`; this milestone is about trust closure, not new rollout capability |
| Shared audiences or broader targeting reuse | Reserved for `v1.5.0`; widening now would blur the proof-closure scope |
| Standalone `rulestead_admin` distribution posture | Conflicts with the mounted sibling-package design |
| Observability-product or hosted control-plane expansion | Violates the bounded host-owned architecture and support-truth focus |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOC-01 | Phase 41 | Complete |
| DOC-02 | Phase 41 | Complete |
| PAR-01 | Phase 42 | Pending |
| PAR-02 | Phase 42 | Pending |
| ADM-01 | Phase 43 | Pending |
| VER-01 | Phase 43 | Pending |
| OFE-01 | Phase 44 | Pending |

**Coverage:**
- v1.3.0 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after milestone initialization*
