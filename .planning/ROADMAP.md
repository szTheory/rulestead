# Roadmap: Rulestead

## Milestones

- ✅ **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (shipped 2026-05-28) — [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Active: v1.11 Gap Closure (Phases 79–81)

**Audit gaps:** [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md) (`gaps_found`, 2026-05-28)

- [ ] Phase 79: Lifecycle Deep-Link Anchor Fix — DOC-02, INT-02
- [ ] Phase 80: Phase 76–77 Verification Backfill — INT-01, INT-03, DOC-01, DOC-03
- [ ] Phase 81: Doc Contract Hardening — DOC-01 (contract guards), Nyquist Phase 76

**Proof spine (unchanged):** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

### Phase 79: Lifecycle Deep-Link Anchor Fix

**Goal:** Fix broken getting-started → spine §6 lifecycle deep-link on GitHub/HexDocs.

**Depends on:** Phase 78

**Requirements:** DOC-02, INT-02

**Gap Closure:** Closes gaps from v1.11 audit — anchor slug mismatch, first-hour adopter lifecycle deep-link flow

**Success criteria:**

1. `getting-started.md` links to `#6-create-your-first-flag-lifecycle-required` (numbered heading slug).
2. Historical plan references aligned (77-01-PLAN.md).
3. Contract test guards correct anchor slug (regression-safe).

---

### Phase 80: Phase 76–77 Verification Backfill

**Goal:** Add missing phase-level `VERIFICATION.md` files and refresh stale validation task status for Phases 76–77.

**Depends on:** Phase 79

**Requirements:** INT-01, INT-03, DOC-01, DOC-03

**Gap Closure:** Closes unverified-phase blocker from v1.11 audit (Phases 76–77 complete via SUMMARY only)

**Success criteria:**

1. `76-VERIFICATION.md` records INT-01–03 proof checklist with commands.
2. `77-VERIFICATION.md` records DOC-01–03 proof checklist with commands.
3. `77-VALIDATION.md` task rows reflect shipped work (not ⬜ pending).
4. `mix verify.phase76` green with proof documented in both VERIFICATION files.

---

### Phase 81: Doc Contract Hardening

**Goal:** Extend intro contract guards for `evaluation.md` Runtime subsection and add Phase 76 Nyquist validation artifact.

**Depends on:** Phase 80

**Requirements:** DOC-01 (contract guard extension)

**Gap Closure:** Optional audit hardening — evaluation.md Runtime not in contract test union; Phase 76 missing VALIDATION.md

**Success criteria:**

1. `intro_integration_spine_contract_test.exs` asserts `evaluation.md` Runtime strings (DOC-01 regression guard).
2. `76-VALIDATION.md` present with Nyquist-compliant per-task verification map.
3. `mix verify.phase76` green including new contract assertions.

---

## Phase numbering

v1.11 substance shipped (Phases 76–78); gap closure Phases 79–81 close audit findings. After gap closure: `/gsd-audit-milestone` then maintenance default. v2 wedges only when deferred triggers fire (see `.planning/DEFERRED.md`).

<details>
<summary>✅ v1.11 Integration Spine (Phases 76-78) — SHIPPED 2026-05-28</summary>

**Audit:** [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md) (`integration_spine_complete`)

- [x] Phase 76: Phoenix Integration Spine Doc — INT-01–03
- [x] Phase 77: Evaluation And Lifecycle Doc Alignment — DOC-01–03
- [x] Phase 78: Doc Contract Guards And Milestone Closure — VER-01–02, AUD-01–02

**Proof:** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

</details>

<details>
<summary>✅ v1.10.1 Support-truth & Contract Honesty (Phases 73-75) — SHIPPED 2026-05-28</summary>

**Audit:** [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md) (`support_truth_complete`)

- [x] Phase 73: Context And Maintainer Doc Truth — CTX-01, CTX-02, DOC-01
- [x] Phase 74: API Stability Catalog Sync — API-01–03, VER-03
- [x] Phase 75: Proof Umbrella And Milestone Closure — VER-01–02, DOC-02, AUD-01–02

**Proof:** `cd rulestead && mix verify.phase73` · `mix verify.adopter`

</details>

<details>
<summary>✅ v1.10.0 Post-GA Band Truth & Adopter Closure (Phases 69-72) — SHIPPED 2026-05-28</summary>

Archived to `.planning/milestones/v1.10.0-phases/`.

</details>

<details>
<summary>✅ v1.9.0 Host-Supplied Preview Evidence (Phases 65-68) — SHIPPED 2026-05-28</summary>

Archived to `.planning/milestones/v1.9.0-phases/`.

</details>
