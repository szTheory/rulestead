# Requirements: Rulestead — v1.10.1 Support-truth & Contract Honesty

**Defined:** 2026-05-28
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.10.1 Requirements

Patch milestone only — no new runtime or admin product APIs. Closes remaining adopter-trust leaks after v1.10.0 band closure.

### Context & Quickstart Honesty (`CTX`)

- [x] **CTX-01**: `Rulestead.Context.new/1` promotes deprecated `traits:` to `attributes` with explicit `:attributes` winning key conflicts (back-compat, not a second public field).
- [x] **CTX-02**: README, getting-started, and package docs teach `attributes:` for evaluation inputs; release-contract test forbids `traits: %{...}` in quickstart examples.

### API Stability Catalog (`API`)

- [x] **API-01**: `guides/api_stability.md` catalogs shipped post-GA public modules and facades that `release_contract_test.exs` already exercises (closes INV-API-01), or documents an explicit generate-from-contract workflow with CI enforcement.
- [x] **API-02**: Release-contract test guards api_stability ↔ documented telemetry events, config schema keys, and struct fields without silent drift.
- [x] **API-03**: `Rulestead.Runtime` and other supported adopter paths are documented in api_stability or `product-boundary.md` with honest semver posture (supported path vs closed module list).

### Maintainer & Doc Truth (`DOC`)

- [x] **DOC-01**: `MAINTAINING.md` no longer lists `guides/api_stability.md` as a deferred Phase 8 artifact (closes INV-MAINT-01).
- [ ] **DOC-02**: Maintainer proof matrix and path-to-done thread reference v1.10.1 exit criteria; stale “open gap” copy removed where band features shipped.

### Proof & Support Truth (`VER`)

- [ ] **VER-01**: `mix verify.phase73` flat-unions phase72 plus v1.10.1 contract guards (no kitchen-sink verifier).
- [ ] **VER-02**: `mix verify.adopter` delegates to phase73 as the integrator entrypoint.
- [x] **VER-03**: `release_contract_test.exs` and/or `post_ga_band_contract_test.exs` guard api_stability catalog drift and Context quickstart honesty.

### Milestone Auditability (`AUD`)

- [ ] **AUD-01**: Investigations INV-API-01 and INV-MAINT-01 marked closed in `STATE.md` with CI evidence pointers.
- [ ] **AUD-02**: `v1.10.1-MILESTONE-AUDIT.md` records support-truth closure evidence and proof spine.

## Future Requirements (deferred)

### Integration spine — v1.11 (docs-only, optional)

- **INT-01**: First-hour Phoenix path (supervision → config → Plug → first flag with lifecycle fields).
- **INT-02**: `evaluation.md` names `Rulestead.Runtime`; intro lifecycle callout (INV-INTRO-01).

### v2 wedges (triggered only)

- **GOV-02-ext**, **ROL-08**, **ADM-06** — see `.planning/DEFERRED.md`

## Out of Scope

| Feature | Reason |
|---------|--------|
| New runtime or admin product APIs | v1.10.x patch posture; feature band complete |
| v1.11 integration spine implementation | Separate docs-only milestone |
| GOV-02-ext / ROL-08 / ADM-06 | v2; requires deferred trigger |
| Kitchen-sink `mix verify.all` | Per-phase verify DNA |
| Hex semver bump to 0.2.0 | Out of band unless explicitly decided |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CTX-01 | Phase 73 | Complete |
| CTX-02 | Phase 73 | Complete |
| DOC-01 | Phase 73 | Complete |
| API-01 | Phase 74 | Complete |
| API-02 | Phase 74 | Complete |
| API-03 | Phase 74 | Complete |
| VER-03 | Phase 74 | Complete |
| VER-01 | Phase 75 | Pending |
| VER-02 | Phase 75 | Pending |
| DOC-02 | Phase 75 | Pending |
| AUD-01 | Phase 75 | Pending |
| AUD-02 | Phase 75 | Pending |

**Coverage:**

- v1.10.1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-28*
*Last updated: 2026-05-28 after v1.10.1 milestone initialization*
