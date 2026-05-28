# Roadmap: Rulestead

## Milestones

- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Shipped Milestone: v1.10.1 Support-truth & Contract Honesty (2026-05-28)

**Goal:** Close the last adopter-trust leaks in docs, API catalog, and contract tests — no new product APIs.

**Audit:** [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md) (`support_truth_complete`)

**Requirements:** CTX-01–02, API-01–03, DOC-01–02, VER-01–03, AUD-01–02 (see [.planning/REQUIREMENTS.md](REQUIREMENTS.md))

**Path-to-done:** [.planning/threads/2026-05-28-path-to-done-milestones.md](threads/2026-05-28-path-to-done-milestones.md)

### Phase 73: Context And Maintainer Doc Truth

**Goal:** Finish Context `traits:` back-compat and align maintainer docs with shipped api_stability reality.

**Depends on:** Phase 72 (v1.10.0)

**Requirements:** CTX-01, CTX-02, DOC-01

**Success criteria:**

1. `Rulestead.Context.new/1` promotes `traits:` to `attributes` with attributes winning conflicts; unit tests cover promotion and conflict resolution.
2. Public quickstart docs use `attributes:` only; release-contract test fails on `traits: %{...}` in getting-started/README examples.
3. `MAINTAINING.md` describes `api_stability.md` as the live public contract, not a deferred Phase 8 artifact.

---

### Phase 74: API Stability Catalog Sync

**Goal:** Reconcile `guides/api_stability.md` with shipped post-GA surface and release-contract guards (INV-API-01).

**Depends on:** Phase 73

**Requirements:** API-01, API-02, API-03, VER-03

**Success criteria:**

1. api_stability catalogs post-GA modules/facades that adopters rely on (`Rulestead.Runtime`, governance/preview seams, etc.) or CI enforces generate-from-contract.
2. Release-contract tests guard telemetry catalog, config schema keys, and struct fields against silent api_stability drift.
3. `Rulestead.Runtime` support posture is explicit in api_stability or product-boundary (supported adopter path vs closed module list).

---

### Phase 75: Proof Umbrella And Milestone Closure

**Goal:** Extend adopter verify entrypoint, close investigations, and record v1.10.1 audit evidence.

**Depends on:** Phase 74

**Requirements:** VER-01, VER-02, DOC-02, AUD-01, AUD-02

**Success criteria:**

1. `mix verify.phase73` flat-unions phase72 plus v1.10.1 guards; `mix verify.adopter` delegates to phase73.
2. `STATE.md` marks INV-API-01 and INV-MAINT-01 closed with proof command references.
3. `v1.10.1-MILESTONE-AUDIT.md` records support-truth closure; maintainer docs no longer imply pre-v1.8 gaps are open.

**Proof spine:** `cd rulestead && mix verify.phase73` · `mix verify.adopter` · `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`

---

## Phase numbering

Continues at **73** (v1.10.1). Next optional milestone: **v1.11** integration spine (docs-only). v2 wedges (GOV-02-ext → ROL-08 → ADM-06) only when deferred triggers fire.

<details>
<summary>✅ v1.10.0 Post-GA Band Truth & Adopter Closure (Phases 69-72) — SHIPPED 2026-05-28</summary>

Archived to `.planning/milestones/v1.10.0-phases/`.

- [x] Phase 69: Band Assessment And Planning Truth — PLN-01–03
- [x] Phase 70: Doc Contract And API Honesty — DOC-01–04
- [x] Phase 71: Proof Umbrella — VER-01–04, AUD-01, AUD-03
- [x] Phase 72: Adopter Closure — DOC-05, VER-05, AUD-02

**Proof:** `cd rulestead && mix verify.phase72` · `scripts/demo/proof.sh`

</details>

<details>
<summary>✅ v1.9.0 Host-Supplied Preview Evidence (Phases 65-68) — SHIPPED 2026-05-28</summary>

Archived to `.planning/milestones/v1.9.0-phases/`.

</details>
