# Requirements: v1.4.0 - Mounted Companion Proof Reclosure

**Defined:** 2026-05-25
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.4.0 Requirements

### Companion Boot & Boundary Truth (`PKG`)

- [ ] **PKG-01**: The `rulestead_admin` mounted companion starts through one deliberate, host-owned boot contract whose required runtime wiring, config shape, and package boundary are consistent from repo root proof to mounted host usage.
- [ ] **PKG-02**: Missing or unsupported mounted companion prerequisites fail with explicit, bounded behavior instead of silent drift, misleading proof output, or docs that imply broader support than the repo provides.

### Mounted Companion Proof (`ADM`)

- [ ] **ADM-01**: The named `mounted_admin_contract` proof bar passes from the repo root against the supported mounted companion startup path and covers the repaired lifecycle, route, and permission contract.

### Verification & Support Truth (`VER`)

- [ ] **VER-01**: Shared verification scripts and CI distinguish the merge-blocking mounted companion proof from advisory smoke paths and report actionable remediation when the proof surface fails.

### Documentation & Support Truth (`DOC`)

- [ ] **DOC-01**: Root, package, and maintainer-facing docs describe the exact mounted companion prerequisites, commands, fallback behavior, and sibling-package posture without implying standalone admin support or stronger proof than is actually runnable.

## Future Requirements

### Deferred Beyond v1.4.0

- **ROL-01**: Rollouts can attach host-supplied guardrail signals to staged progression and stop or roll back on explicit thresholds without widening Rulestead into an observability product.
- **ROL-02**: Guarded rollout decisions remain deterministic, tenant-aware, audited, and fail-closed when signals are weak, stale, or missing.
- **SEG-01**: Reusable targeting deepening adds impact previews and dependency visibility for the already-shipped audience surface.
- **SEG-02**: Shared targeting assets preserve explainability, compare correctness, import/export validity, and promotion safety without hidden inheritance graphs.

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| Mounted companion boot/runtime contract | Host app owns auth, session, and router envelope | native screen | high | high | merge-blocking repo-root proof | `companion` |
| Mounted companion verification command | Maintainer- and adopter-facing repo workflow | low-frequency semantic | medium | high | merge-blocking scoped verifier | `companion` |
| Mounted support-truth docs and release guidance | Shared repo truth for adopters and maintainers | low-frequency semantic | medium | high | release-contract checks plus doc review | `example/docs-only` |
| Standalone admin packaging or widened control-plane posture | no route owner inside current architecture | defer | high | high | n/a | `defer` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| `rulestead` runtime/config seam needed by mounted proof | `core` | In scope |
| `rulestead_admin` mounted startup, routes, and verifier path | `companion` | In scope |
| Root/package README, maintainer guidance, and CI proof language | `example/docs-only` | In scope |
| Standalone `rulestead_admin` product posture | `defer` | Out of scope |
| New rollout, targeting, or observability capabilities | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| `rulestead_admin` mounted companion | repo-root `mounted_admin_contract` command plus targeted lifecycle/permission suites | manual mounted smoke path in host app |
| `rulestead` support seam for mounted companion | focused boot/runtime/config regression tests | maintainer debugging notes |
| Docs, scripts, and CI truth | release-contract checks for named proof commands and support wording | walkthrough/readme spot-check |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Rebuild / Setup Expectation | Rough-Edge Docs Required |
|---------|----------------------------|-------------------------------|-----------------------------|--------------------------|
| `rulestead_admin` mounted companion | Remains a mounted sibling-package companion only | Fail explicitly when host mount/config prerequisites are absent or unsupported | Host app must wire the documented mount/config path before proof is expected to pass | yes |
| Repo proof commands and CI scopes | Fail closed on broken mounted proof instead of silently skipping | Print actionable command/path guidance when required setup is missing | Repo-root verification remains the canonical support bar | yes |
| Root and package docs | Never imply standalone admin support | Must point users to the supported mounted path and exact proof commands | Docs must state what is runnable today versus advisory | yes |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Standalone `rulestead_admin` distribution or publish prep | Conflicts with the mounted sibling-package release design |
| New guarded rollout mechanics | Preserved for `v1.5.0`; this milestone is support-surface repair, not a new differentiator |
| Reworking reusable targeting as a net-new wedge | Reusable audiences are already shipped; deeper ergonomics come later |
| Admin UX redesign unrelated to mounted proof closure | Would blur the narrow support-truth scope and delay the trust fix |
| Runtime hot-path expansion for proof instrumentation | The milestone must not couple support repair to request-path complexity |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PKG-01 | Phase 45 | Pending |
| PKG-02 | Phase 45 | Pending |
| ADM-01 | Phase 46 | Pending |
| VER-01 | Phase 46 | Pending |
| DOC-01 | Phase 47 | Pending |

**Coverage:**
- v1.4.0 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 after activating milestone v1.4.0*
