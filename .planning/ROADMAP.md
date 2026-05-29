# Roadmap: Rulestead

## Milestones

- ✅ **v1.11.1 - Gap Closure** — Phases 79-81 (shipped 2026-05-29) — [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md) · [audit](milestones/v1.11.1-MILESTONE-AUDIT.md)
- ✅ **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (shipped 2026-05-28) — [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Current focus

**Maintenance default** — post-GA band and v1.11 (including gap closure) are shipped. Open v2 wedges only when deferred triggers fire (see `.planning/DEFERRED.md`).

**Proof spine:** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

**Recommended:** `/gsd-audit-milestone` to re-verify v1.11 audit gaps are closed, then maintenance-only work until a v2 trigger.

## Phase numbering

Phases 76–81 complete the v1.11 integration-spine and audit-gap-closure bands. Next milestone phases start at **82** when `/gsd-new-milestone` opens scoped work.

<details>
<summary>✅ v1.11.1 Gap Closure (Phases 79-81) — SHIPPED 2026-05-29</summary>

- [x] Phase 79: Lifecycle Deep-Link Anchor Fix — DOC-02, INT-02
- [x] Phase 80: Phase 76–77 Verification Backfill — INT-01, INT-03, DOC-01, DOC-03
- [x] Phase 81: Doc Contract Hardening — DOC-01 (contract guards), Nyquist Phase 76

**Archive:** [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md)

**Audit:** [.planning/milestones/v1.11.1-MILESTONE-AUDIT.md](milestones/v1.11.1-MILESTONE-AUDIT.md) (`passed`)

</details>

<details>
<summary>✅ v1.11 Integration Spine (Phases 76-78) — SHIPPED 2026-05-28</summary>

**Audit:** [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)

- [x] Phase 76: Phoenix Integration Spine Doc — INT-01–03
- [x] Phase 77: Evaluation And Lifecycle Doc Alignment — DOC-01–03
- [x] Phase 78: Doc Contract Guards And Milestone Closure — VER-01–02, AUD-01–02

**Proof:** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

</details>

<details>
<summary>✅ v1.10.1 Support-truth & Contract Honesty (Phases 73-75) — SHIPPED 2026-05-28</summary>

**Audit:** [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)

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
