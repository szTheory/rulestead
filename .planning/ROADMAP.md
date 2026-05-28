# Roadmap: Rulestead

## Milestones

- **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (active)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Active Milestone: v1.11 Integration Spine (docs-only)

**Goal:** Close INV-INTRO-01 with a first-hour Phoenix integration path — no new product APIs.

**Requirements:** INT-01–03, DOC-01–03, VER-01–02, AUD-01–02 (see [.planning/REQUIREMENTS.md](REQUIREMENTS.md))

**Path-to-done:** [.planning/threads/2026-05-28-path-to-done-milestones.md](threads/2026-05-28-path-to-done-milestones.md)

**Canonical refs:** `prompts/rulestead-host-app-integration-seam.md`, `prompts/rulestead-personas-jtbd-and-onboarding.md`, `guides/recipes/context-propagation.md`, `guides/flows/flag-lifecycle.md`

### Phase 76: Phoenix Integration Spine Doc

**Goal:** Author the first-hour Phoenix integration spine and wire it from intro docs.

**Depends on:** Phase 75 (v1.10.1)

**Requirements:** INT-01, INT-02, INT-03

**Success criteria:**

1. New spine doc (e.g. `guides/introduction/phoenix-integration-spine.md`) walks supervision → `config :rulestead` → Plug/context → first `Rulestead.Runtime` evaluation with explicit context.
2. Spine shows flag create with required `owner` + `expected_expiration` and host-owned ownership honesty.
3. README, getting-started, and installation link the spine as the canonical first-hour path after `mix rulestead.install`.

---

### Phase 77: Evaluation And Lifecycle Doc Alignment

**Goal:** Name `Rulestead.Runtime` in evaluation docs and add intro lifecycle callouts (INV-INTRO-01 narrative closure).

**Depends on:** Phase 76

**Requirements:** DOC-01, DOC-02, DOC-03

**Success criteria:**

1. `guides/flows/evaluation.md` documents `Rulestead.Runtime` keyed lookup with examples; payload-first `Rulestead.evaluate/3` remains canonical.
2. getting-started and installation include lifecycle-required-fields callout linking to flag-lifecycle.
3. `rulestead/README.md` API ordering matches footguns and evaluation spine.

---

### Phase 78: Doc Contract Guards And Milestone Closure

**Goal:** Guard intro spine with release-contract tests, extend verify entrypoint, close INV-INTRO-01, record v1.11 audit.

**Depends on:** Phase 77

**Requirements:** VER-01, VER-02, AUD-01, AUD-02

**Success criteria:**

1. Release-contract or doc contract test fails if spine or lifecycle callouts regress.
2. `mix verify.phase76` flat-unions phase73 plus v1.11 guards; adopter entrypoint documents successor.
3. `STATE.md` marks INV-INTRO-01 closed; `v1.11-MILESTONE-AUDIT.md` records integration-spine closure.

**Proof spine (target):** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

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
