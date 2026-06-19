# Roadmap: Rulestead

## Milestones

- 🔄 **v2.0 — 1.0 GA Release & Adoption** — Phases 124-130 (in progress)
- ✅ **v1.18 CI/CD Reliability** — Phases 119-123 (shipped 2026-06-17)
- ✅ **v1.17 Admin Design System Stress Test** — Phases 113-118 (shipped 2026-06-15)

## Phases

<details open>
<summary>🔄 v2.0 — 1.0 GA Release & Adoption (Phases 124-130) — IN PROGRESS</summary>

- [x] **Phase 124: API Surface Lock & Stability Contract** — Render the 3 hidden public modules; @doc/@spec audit; api_stability.md → "1.x" + Versioning & Deprecation Policy
- [x] **Phase 125: Version-Truth Sweep + Release Docs** — Reframe 14 stale 0.1.x files; delete README callout; add CI drift guard; upgrading.md + MAINTAINING.md runbook
- [x] **Phase 126: HexDocs Front Door** — 5 module groups, 6 extras groups, logo/favicon/assets (no 404), theming head-tag, README hero+badges, rulestead_admin docs parity
- [x] **Phase 127: Adoption Guides** — troubleshooting.md (7 patterns) + integrations-cookbook.md (4 recipes); wire into extras
- [x] **Phase 128: The Release Cut** — release-as 1.0.0, disable auto-merge, hand-merge, publish both packages, verify-trio green, post-cut cleanup
- [ ] **Phase 129: Provider Publish** — Manual open_feature_rulestead@1.0.0 publish, strictly after rulestead@1.0.0 is live
- [ ] **Phase 130: Announce & Closeout** — GitHub release + ElixirForum post + front-door confirmation + milestone audit

</details>

<details>
<summary>✅ v1.18 CI/CD Reliability (Phases 119-123) — SHIPPED 2026-06-17</summary>

- [x] Phase 119: Baseline + Expert Audit (3/3 plans) — completed 2026-06-16
- [x] Phase 119.1: Verify Phase 119 audit deliverable (CIDX-01/02/03) (1/1 plans) — completed 2026-06-17
- [x] Phase 120: Workflow Topology + Cache Hygiene (3/3 plans) — completed 2026-06-16
- [x] Phase 121: Mix/ExUnit Performance + Test Value Cleanup (3/3 plans) — completed 2026-06-17
- [x] Phase 122: Browser/Demo/Integration Determinism (1/1 plans) — completed 2026-06-17
- [x] Phase 123: DX + Closeout Proof (3/3 plans) — completed 2026-06-17

Full detail archived: [milestones/v1.18-ROADMAP.md](milestones/v1.18-ROADMAP.md) · requirements: [milestones/v1.18-REQUIREMENTS.md](milestones/v1.18-REQUIREMENTS.md) · audit: [milestones/v1.18-MILESTONE-AUDIT.md](milestones/v1.18-MILESTONE-AUDIT.md)

</details>

<details>
<summary>✅ v1.17 Admin Design System Stress Test (Phases 113-118) — SHIPPED 2026-06-15</summary>

- [x] Phase 113: Design-System Inventory + UI Matrix Contract (3/3 plans) — completed 2026-06-13
- [x] Phase 114: Repo-Native Component Matrix Harness (2/2 plans) — completed 2026-06-14
- [x] Phase 115: Foundations Hardening (3/3 plans) — completed 2026-06-14
- [x] Phase 116: Primitive + Composite Polish (4/4 plans) — completed 2026-06-14
- [x] Phase 117: Page Flow + IA Pass (4/4 plans) — completed 2026-06-14
- [x] Phase 118: Evidence + Idempotence Guardrails (3/3 plans) — completed 2026-06-14

Full detail archived: [milestones/v1.17-ROADMAP.md](milestones/v1.17-ROADMAP.md)

</details>

## Phase Details

### Phase 124: API Surface Lock & Stability Contract

**Goal:** The three public modules render on HexDocs and every public symbol carries a real doc + spec, with `api_stability.md` rewritten to the "1.x" contract and Versioning & Deprecation Policy.

**Depends on:** Nothing (pre-cut work; can run in parallel with Phases 125-127)

**Requirements:** API-01, API-02, API-03

**Success Criteria** (what must be TRUE):

1. `Rulestead.Context`, `Rulestead.Runtime`, and `Rulestead.Admin.Policy` each carry a real `@moduledoc` (not `@moduledoc false`); running `mix docs` confirms all three render as navigable module pages with no module excluded from the HexDocs output.
2. Every symbol listed public in `api_stability.md` has `@doc` + `@spec`; `mix dialyzer` is clean on the public surface; `mix docs` produces zero undefined-reference warnings (treated as a release gate).
3. `api_stability.md` is rewritten from "0.1.x contract" to "1.x contract" and includes the full Versioning & Deprecation Policy (breaking-change table, telemetry stability rules, worked deprecation example, empty deprecations-table skeleton).
4. `release_contract_test.exs` stays green after all edits; the bidirectional `api_stability.md` ↔ code guard passes.
5. `Rulestead.Runtime` appears in `groups_for_modules`; `Rulestead.Runtime.Snapshot` is removed from any public group.

**Plans:** 3/3 plans complete

Plans:

- [x] 124-P01-PLAN.md — @moduledoc+@doc on Context, Runtime, Admin.Policy + mix.exs groups_for_modules update
- [x] 124-P02-PLAN.md — Rewrite api_stability.md to 1.x contract + update release_contract_test.exs in lockstep
- [x] 124-P03-PLAN.md — Release-gate verification: mix docs --warnings-as-errors, mix dialyzer, contract test

---

### Phase 125: Version-Truth Sweep + Release Docs

**Goal:** Every shipped file tells the truth about `1.x` — no stale `0.1.x` language anywhere in the public surface — and adopters have clear upgrade and maintainer-runbook docs ready before the cut.

**Depends on:** Phase 124 (api_stability.md rewrite anchors the sweep; reviewed together so `release_contract_test.exs` and the new drift guard stay green; can otherwise run in parallel with Phases 126-127)

**Requirements:** REL-02, REL-03

**Success Criteria** (what must be TRUE):

1. `grep -rn '0\.1\.x\|~> 0\.1\b\|0\.1\.7\|future.*1\.0\|1\.0 API freeze' README.md rulestead/README.md rulestead_admin/README.md open_feature_rulestead/README.md guides/ MAINTAINING.md CONTRIBUTING.md` returns zero hits in the shipped surface (`.planning/` and `prompts/` historical references are intentionally excluded).
2. The README "Two version lines" callout (the admonition block describing the ZeroVer mismatch) is deleted entirely — leaving it would re-introduce the exact confusion the milestone resolves.
3. A CI drift guard in `lint.sh` fails if `~> 0.1` or "future `1.0`" reappears in the shipped doc surface, same posture as the existing brand-token drift guards.
4. `guides/introduction/upgrading.md` has a clear "Upgrading 0.1.x → 1.0" section stating zero code changes, only a dep-pin bump (`~> 0.1` → `~> 1.0`); the "promotion, not rewrite" framing is explicit.
5. `MAINTAINING.md` has a "Cutting a major (X.0.0)" runbook covering the `Release-As` mechanism, the three-package sequence, the deprecation-window checklist, and the mandatory post-cut `"release-as"` removal step.
6. The "promotion, not rewrite" CHANGELOG preamble is pre-authored as a ready artifact for both packages (to be applied during the release PR in Phase 128).

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 125-01-PLAN.md — Atomic version-truth sweep of 13 shipped files (delete "Two version lines" callout; `~> 0.1`→`~> 1.0`) + lockstep re-anchor of 6 `release_contract_test.exs` asserts (REL-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 125-02-PLAN.md — Fail-closed `scripts/check_version_truth.py` drift guard (`~> 0.1.3`-safe lookahead) wired into `scripts/ci/lint.sh` (REL-02)
- [x] 125-03-PLAN.md — Release docs: upgrading.md "Upgrading 0.1.x → 1.0" section, MAINTAINING.md "Cutting a major" runbook, staged `brandbook/CHANGELOG-PREAMBLE-1.0.md` (REL-03)

---

### Phase 126: HexDocs Front Door

**Goal:** The published HexDocs for both packages present a 1.0-grade, branded, onboarding-funnel experience — with the logo resolving (no 404s), the five module groups, six extras groups, mineral-palette theming, and `rulestead_admin` docs at parity.

**Depends on:** Phases 124 and 125 (module docs and version truth must land so the published tarball is complete and honest; can run in parallel with Phase 127)

**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05, DOC-06

**Success Criteria** (what must be TRUE):

1. `mix hex.build` (run from `rulestead/`) produces a tarball that contains `brandbook/assets/logo/` SVGs (and `specimens/` for the README header); `brandbook/assets/logo` is present in `files:` in `mix.exs`, proving no logo 404 on launch day.
2. `rulestead/mix.exs` `docs:` is configured with the 5 module groups (Core API · Runtime (cached lookup) · Behaviours & Seams · Store Adapters · Telemetry & Config) and 6 extras groups in the onboarding-funnel `extras:` order (Why → Install → Getting Started → Spine → concepts → flows → recipes → API & Stability → Contributing).
3. The logo (`rs-mark.svg`) and favicon (`rs-favicon.svg`) are wired into ExDoc config; `before_closing_head_tag` re-tints ExDoc CSS variables to the mineral palette and sets OG meta — with no custom theme JS.
4. "Why Rulestead?" (`guides/introduction/why-rulestead.md`) exists as the first Introduction extra, sourced from the brandbook narrative (not a README duplicate), and renders correctly on HexDocs.
5. The README has the centered brand hero (wordmark + tagline + 5 badges: Hex version, HexDocs, CI, License, Elixir version) with `~> 1.0` install snippets.
6. `rulestead_admin` docs reach parity — same logo/favicon/theming, a real `@moduledoc` on `RulesteadAdmin.Router`, and admin flow guides wired into its docs configuration.

**Plans:** 6/6 plans complete

Plans:
**Wave 1**

- [x] 126-01-PLAN.md — Wave-0 prereqs: committed `brandbook` symlinks (both packages, D-09), rasterized `rs-social-card.png` (D-19), D-10 logo-bytes CI tarball assertion (DOC-02)
- [x] 126-02-PLAN.md — New `guides/introduction/why-rulestead.md` positioning extra, brandbook-sourced, no named vendors (D-17/D-18, DOC-04)
- [x] 126-03-PLAN.md — README centered wordmark-tagline hero + 5-badge clickable row, self-healing version badge (D-20, DOC-05)
- [x] 126-04-PLAN.md — Un-hide `TestHelpers`/`Telemetry`/`Config` `@moduledoc false`→real (D-02/D-03, DOC-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 126-05-PLAN.md — Core `rulestead/mix.exs`: 6 module groups, funnel extras + "API & Stability" first, logo/favicon/assets wiring, `--main*` re-tint + PNG OG meta (D-01..D-16, DOC-01/02/03/05)
- [x] 126-06-PLAN.md — `rulestead_admin` parity: docs config + duplicated `--main*` head-tag + real host-owns-auth `RulesteadAdmin.Router` `@moduledoc` (D-21/D-22/D-23, DOC-06)

**UI hint**: yes

> Note: Success-criterion 2 says "5 module groups"; D-02 (user-confirmed) ships **6** — the 6th "Testing" group renders the contracted `Rulestead.TestHelpers` facade. Treat criterion-2 as satisfied-with-correction (do not flag the count).

---

### Phase 127: Adoption Guides

**Goal:** Adopters have a blame-free troubleshooting reference and four persona-grounded integration recipes that use only shipped public seams, wired into the existing Recipes extras group.

**Depends on:** Phases 124 and 125 (guides must reference the correct public API surface and version truth; can run in parallel with Phase 126)

**Requirements:** GUIDE-01, GUIDE-02, GUIDE-03

**Success Criteria** (what must be TRUE):

1. `guides/recipes/troubleshooting.md` ships with 7 symptom-indexed patterns in Symptom → Cause → Fix → Verify form (install/migration, payload-vs-keyed-runtime, snapshot boot race, context propagation, RBAC 403, change-request block, OpenFeature/Redis stale), cross-linking `footguns.md` for the "why" without duplicating it; tone is blame-free.
2. `guides/recipes/integrations-cookbook.md` ships with 4 persona/JTBD-grounded recipes (Stripe-tier audience, eval-telemetry → Segment, staging→prod CR promotion, Oban-gated job), each using the fixed template (Goal → For → Prerequisites → Steps → Verification → Gotchas → Related), with an honest boundary line and using only shipped public seams.
3. Both guides are wired into the existing Recipes extras group (cookbook early, troubleshooting last); the 15-minute golden-path guide is untouched; no new extras group is added.

**Plans:** 3 plans
- [ ] 127-01-PLAN.md — troubleshooting.md: 7 symptom-indexed patterns (GUIDE-01)
- [ ] 127-02-PLAN.md — integrations-cookbook.md: 4 persona-grounded recipes (GUIDE-02)
- [ ] 127-03-PLAN.md — wire both into Recipes extras group in mix.exs (GUIDE-03)

---

### Phase 128: The Release Cut

**Goal:** `rulestead` and `rulestead_admin` are published at `1.0.0` via the gated release-please pipeline, the post-publish verify-trio is green, and post-cut cleanup is complete.

**Depends on:** Phases 124, 125, 126, AND 127 — ALL pre-cut doc/contract work must land before the cut so the published tarball is complete and honest.

**Gate entering this phase:** `cd rulestead && mix ci` green; `bash scripts/ci/local.sh` green; `release_contract_test.exs` green; `mix hex.build` tarball contains the logo SVGs; all of Phases 124-127 complete.

**Requirements:** REL-01, REL-04, REL-06

**Success Criteria** (what must be TRUE):

1. `"release-as": "1.0.0"` is added to the `rulestead` block in `release-please-config.json`; release-PR auto-merge is disabled; the release PR diff shows `@version "1.0.0"` in both `rulestead/mix.exs` and `rulestead_admin/mix.exs` (linked-versions propagated correctly) before the deliberate hand-merge.
2. The release PR includes the hand-authored "promotion, not rewrite" preamble in both CHANGELOGs (explicit zero breaking changes statement); the maintainer hand-merges the PR after eyeballing the diff.
3. `rulestead` and `rulestead_admin` are published at `1.0.0` via the gated `hex-publish` environment approval; `handoff-post-publish` dispatches `verify-published-release.yml`.
4. The post-publish verify-trio (`bash scripts/ci/verify_published_release.sh 1.0.0`) is green: workspace clean, fresh consumer compiles against Hex `1.0.0`, HexDocs `1.0.0` reachable, and Hex tarball matches tagged source.
5. Post-cut cleanup is complete: `"release-as"` is removed from `release-please-config.json` (so release-please stops re-proposing `1.0.0`), release-PR auto-merge is re-enabled, and `MAINTAINING.md` notes that `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` are now no-ops post-1.0.

**Plans:** 3/3 plans complete

Plans:
- [x] 128-01-PLAN.md — Pre-cut gate + disable auto-merge + add release-as + open release PR + hand-add preamble + eyeball diff (REL-01)
- [x] 128-02-PLAN.md — Hand-merge release PR + approve hex-publish env + confirm both packages live + verify-trio green (REL-04)
- [x] 128-03-PLAN.md — Remove release-as + re-enable auto-merge + confirm MAINTAINING.md no-op note (REL-06)

---

### Phase 129: Provider Publish

**Goal:** `open_feature_rulestead` is published at `1.0.0` manually, strictly after `rulestead@1.0.0` is live on Hex, with a fresh consumer able to resolve `rulestead ~> 1.0`.

**Depends on:** Phase 128 — `rulestead@1.0.0` must be live on Hex before `~> 1.0` dep can resolve; this phase is strictly serial.

**Gate entering this phase:** `curl hex.pm/api/packages/rulestead/releases/1.0.0` returns 200.

**Requirements:** REL-05

**Success Criteria** (what must be TRUE):

1. `open_feature_rulestead/mix.exs` is bumped to `@version "1.0.0"` with its dep flipped to `{:rulestead, "~> 1.0"}` via the env-gated swap (mirroring the existing `RULESTEAD_ADMIN_HEX_RELEASE` pattern); the version+dep bump is committed to main.
2. `open_feature_rulestead` is published at `1.0.0` via `mix hex.publish`; `hex.pm/api/packages/open_feature_rulestead/releases/1.0.0` returns 200 and HexDocs renders the provider.
3. A fresh consumer with `{:open_feature_rulestead, "~> 1.0"}` resolves `rulestead ~> 1.0` from Hex (not a path dep); the `openfeature_companion` contract tests pass against the published provider.
4. A minimal CHANGELOG entry is added to `open_feature_rulestead` for trust parity (version-truth promotion, zero breaking changes).

**Plans:** 3 plans
- [ ] 129-01-PLAN.md — Package-ready: version 1.0.0 + env-gated rulestead dep swap + ex_doc/docs + LICENSE + 1.0.0 CHANGELOG + moduledocs (criteria 1, 4)
- [ ] 129-02-PLAN.md — Scripts-first pre-publish guard + MAINTAINING.md ordered runbook (D-12/D-13/D-14)
- [ ] 129-03-PLAN.md — Guarded manual publish + git tag + post-publish verification → 129-VERIFICATION.md (criteria 2, 3)

---

### Phase 130: Announce & Closeout

**Goal:** The GitHub release and ElixirForum post are published linking only confirmed-live artifacts; the HexDocs front door is provably live and honest; the milestone is closed.

**Depends on:** Phase 129 — announce waits for verify-trio green + HexDocs front door confirmed rendered + `open_feature_rulestead@1.0.0` live.

**Gate entering this phase:** verify-trio green; `open_feature_rulestead@1.0.0` live; HexDocs renders the new shape (logo visible, "Why Rulestead?" present, all 3 public modules visible, all 5 badges resolve).

**Requirements:** ANN-01, ANN-02, ANN-03

**Success Criteria** (what must be TRUE):

1. A GitHub release is published from `brandbook/RELEASE-TEMPLATE.md` with filled content — three packages, one note, operator-consequence-first framing, explicit "no behavior changes" statement.
2. An ElixirForum post is published in Libraries (single post, `announcement` tag) containing: tl;dr → real `Rulestead.evaluate/3` snippet → honest maturity story → proof bullets → scope honesty → respectful FunWithFlags note → confirmed-live artifact links only; the post is made only after the verify-trio is green and the HexDocs front door renders.
3. The front door is confirmed provably live and honest: logo resolves on HexDocs, "Why Rulestead?" extra renders as the first Introduction page, all three public modules (`Rulestead.Context`, `Rulestead.Runtime`, `Rulestead.Admin.Policy`) are visible as navigable HexDocs pages, and all 5 README badges resolve to live targets.
4. The milestone audit captures evidence (hex.pm live URLs, HexDocs URL, ElixirForum post link, GitHub release URL); zero new runtime APIs confirmed; `INV-REL-01` investigation closed.

**Plans:** TBD

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 124. API Surface Lock & Stability Contract | 3/3 | Complete    | 2026-06-18 |
| 125. Version-Truth Sweep + Release Docs | 3/3 | Complete   | 2026-06-18 |
| 126. HexDocs Front Door | 6/6 | Complete   | 2026-06-18 |
| 127. Adoption Guides | 0/TBD | Not started | - |
| 128. The Release Cut | 3/3 | Complete    | 2026-06-19 |
| 129. Provider Publish | 0/TBD | Not started | - |
| 130. Announce & Closeout | 0/TBD | Not started | - |
