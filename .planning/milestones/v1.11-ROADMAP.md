# Roadmap: Rulestead

## Milestones

- ✅ **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (shipped 2026-05-28) — [.planning/v1.11-MILESTONE-AUDIT.md](v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Shipped Milestone: v1.11 Integration Spine (docs-only)

**Shipped:** 2026-05-28 — [.planning/v1.11-MILESTONE-AUDIT.md](v1.11-MILESTONE-AUDIT.md) (`integration_spine_complete`)

**Proof spine:** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

<details>
<summary>v1.11 phases (76–78)</summary>

### Phase 76: Phoenix Integration Spine Doc

**Goal:** Author the first-hour Phoenix integration spine and wire it from intro docs.

**Depends on:** Phase 75 (v1.10.1)

**Requirements:** INT-01, INT-02, INT-03

**Success criteria:**

1. New spine doc (e.g. `guides/introduction/phoenix-integration-spine.md`) walks supervision → `config :rulestead` → Plug/context → first `Rulestead.Runtime` evaluation with explicit context.
2. Spine shows flag create with required `owner` + `expected_expiration` and host-owned ownership honesty.
3. README, getting-started, and installation link the spine as the canonical first-hour path after `mix rulestead.install`.

---

### Phase 77: Evaluation And Lifecycle Doc Alignment ✅

**Goal:** Name `Rulestead.Runtime` in evaluation docs and add intro lifecycle callouts (INV-INTRO-01 narrative closure).

**Depends on:** Phase 76

**Requirements:** DOC-01, DOC-02, DOC-03

**Status:** Complete 2026-05-28 — [.planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-01-SUMMARY.md](phases/77-evaluation-and-lifecycle-doc-alignment/77-01-SUMMARY.md)

**Success criteria:**

1. `guides/flows/evaluation.md` documents `Rulestead.Runtime` keyed lookup with examples; payload-first `Rulestead.evaluate/3` remains canonical.
2. getting-started and installation include lifecycle-required-fields callout linking to flag-lifecycle.
3. `rulestead/README.md` API ordering matches footguns and evaluation spine.

---

### Phase 78: Doc Contract Guards And Milestone Closure ✅

**Goal:** Guard intro spine with release-contract tests, extend verify entrypoint, close INV-INTRO-01, record v1.11 audit.

**Status:** Complete 2026-05-28 — [.planning/phases/78-doc-contract-guards-and-milestone-closure/78-VERIFICATION.md](phases/78-doc-contract-guards-and-milestone-closure/78-VERIFICATION.md)

</details>

---

## Phase numbering

Continues at **76** (v1.11). v2 wedges (GOV-02-ext → ROL-08 → ADM-06) only when deferred triggers fire.

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
