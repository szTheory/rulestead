# Requirements: Rulestead — v2.0 "1.0 GA Release & Adoption"

**Defined:** 2026-06-17
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Milestone intent:** Cut a real, semver-stable `1.0.0` of all three Hex packages (`rulestead`, `rulestead_admin`, `open_feature_rulestead`) with a 1.0-grade front door (HexDocs + adoption guides + announce), telling the truth about the platform's actual maturity. **No new runtime features; public surface locked as-is.** Grounded in `.planning/research/SUMMARY.md` (R1 RELEASE · R2 HEXDOCS · R3 GUIDES · R4 POSITIONING).

## v1 Requirements

Requirements for the v2.0 milestone. Each maps to roadmap phases (continuing numbering from 124).

### API Surface Lock & Stability Contract

- [x] **API-01**: The three listed-public modules (`Rulestead.Context`, `Rulestead.Runtime`, `Rulestead.Admin.Policy`) carry real `@moduledoc` and render on HexDocs — no `@moduledoc false` on any module listed public in `api_stability.md`.
- [x] **API-02**: Every symbol listed public in `api_stability.md` has `@doc` + `@spec`; no accidental public surface; dialyzer is clean on the public surface; ExDoc undefined-reference warnings are treated as a release gate.
- [x] **API-03**: `api_stability.md` is rewritten to the "1.x" contract and adds a Versioning & Deprecation Policy (soft→hard `@deprecated`→remove-on-major window, telemetry-event stability, breaking-change table, a worked deprecation example); `release_contract_test.exs` stays green.

### HexDocs Front Door

- [x] **DOC-01**: `rulestead/mix.exs` `docs:` is configured with the 5 module groups (incl. `Rulestead.Runtime` grouped; non-public `Rulestead.Runtime.Snapshot` removed), 6 extras groups, and the onboarding-funnel `extras:` order.
- [x] **DOC-02**: Brand logo + favicon + assets are wired AND `brandbook/assets/logo` (+ specimens) is added to the package `files:` list, so `mix hex.build` ships the SVGs and the logo resolves on HexDocs/hex.pm (no launch-day 404).
- [x] **DOC-03**: A minimal `before_closing_head_tag` re-tints ExDoc CSS variables to the mineral palette and brand focus ring, respects ExDoc light/dark/system, and sets OG meta — with no theme JS and no custom stylesheet.
- [x] **DOC-04**: A "Why Rulestead?" positioning extra (`guides/introduction/why-rulestead.md`) is the first Introduction extra, sourced from the brandbook narrative (not a README duplicate).
- [x] **DOC-05**: The README has a brand hero (wordmark + tagline + 5 badges: Hex version · HexDocs · CI · License · Elixir version) and a `~> 1.0` install snippet; the "two version lines" callout is deleted; the social card is rasterized for the GitHub social-preview slot.
- [x] **DOC-06**: `rulestead_admin` docs reach parity — same logo/favicon/theming, a real `@moduledoc` on `RulesteadAdmin.Router`, and admin flow guides.

### Adoption Guides

- [ ] **GUIDE-01**: `guides/recipes/troubleshooting.md` ships 7 symptom-indexed patterns in Symptom → Cause → Fix → Verify form, cross-linking `footguns.md` for the "why" without duplicating it.
- [ ] **GUIDE-02**: `guides/recipes/integrations-cookbook.md` ships 4 persona/JTBD-grounded recipes on the fixed template (Goal → For → Prerequisites → Steps → Verification → Gotchas → Related), each with an honest boundary line and using only shipped public seams.
- [ ] **GUIDE-03**: Both guides are wired into the existing Recipes extras group (cookbook early, troubleshooting last); the 15-minute golden path stays untouched.

### Release Cut

- [ ] **REL-01**: `"release-as": "1.0.0"` is added to the `rulestead` block, release-PR auto-merge is disabled for the cut, and the release PR diff is verified to bump BOTH linked packages before a deliberate hand-merge.
- [x] **REL-02**: The version-truth sweep reframes the ~14 stale `0.1.x` files (READMEs, `api_stability.md`, `upgrading.md`, `MAINTAINING.md`) to the 1.0 reality and deletes the README "two version lines" callout; a CI drift guard is added to `lint.sh`; `.planning/` and `prompts/` historical references are left untouched.
- [x] **REL-03**: `1.0.0` CHANGELOG entries are framed "promotion, not rewrite" (explicit zero breaking changes); `upgrading.md` documents the 0.1.x→1.0 path (dep-pin bump only); `MAINTAINING.md` gains a major-bump ("Cutting a major") runbook.
- [ ] **REL-04**: `rulestead` and `rulestead_admin` are published at `1.0.0` via the gated release-please pipeline, and the post-publish verify-trio (`scripts/ci/verify_published_release.sh 1.0.0`) is green.
- [x] **REL-05**: `open_feature_rulestead` is published at `1.0.0` manually, strictly after `rulestead@1.0.0` is live, with its dep flipped to `rulestead ~> 1.0` (env-gated); a fresh consumer resolves the published provider; a minimal CHANGELOG is added for trust parity.
- [ ] **REL-06**: Post-cut cleanup — `"release-as"` is removed from the config (so release-please stops re-proposing `1.0.0`), release-PR auto-merge is re-enabled, and the now-no-op `bump-*-pre-major` flags are documented as such.

### Announce & Closeout

- [ ] **ANN-01**: A GitHub release is published from `brandbook/RELEASE-TEMPLATE.md` (three packages, one note, operator-consequence-first framing).
- [ ] **ANN-02**: An ElixirForum announcement is posted (single Libraries post, `announcement` tag, tl;dr + real `Rulestead.evaluate/3` snippet + honest maturity story + scope honesty + respectful FunWithFlags note), linking only confirmed-live artifacts, and only after the verify-trio is green and the HexDocs front door renders.
- [ ] **ANN-03**: Closeout confirms the front door is provably live and honest (logo, "Why Rulestead?", the 3 public modules visible, badges resolve); the milestone audit captures evidence; zero new runtime APIs confirmed.

## Out of Scope

Explicitly excluded for v2.0. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New runtime APIs / schema changes | Release-truth milestone; the platform is API-frozen and the public surface is locked as-is. |
| "Last clean break" renames of the public surface | API audit found no warts; renaming would be overbuild and would break the zero-breaking-change framing. |
| BRD-05 standalone marketing/docs website | HexDocs + ElixirForum is the idiomatic, higher-leverage front door for an Elixir lib. |
| Interactive rule builder, blog/CMS, email funnel, video tutorials, client SDKs, stats engine, comparison microsite | Out of the adoption scope; not idiomatic for an Elixir lib launch. |
| v2 feature wedges: GOV-02-ext, ROL-08, ADM-06 | Trigger-gated per `.planning/DEFERRED.md`; no trigger has fired. |
| Vendor comparison matrix / "X for Elixir" / price-parity messaging | Brand guardrails forbid copycat framing and head-on SaaS parity fights. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| API-01 | Phase 124 | Complete |
| API-02 | Phase 124 | Complete |
| API-03 | Phase 124 | Complete |
| DOC-01 | Phase 126 | Complete |
| DOC-02 | Phase 126 | Complete |
| DOC-03 | Phase 126 | Complete |
| DOC-04 | Phase 126 | Complete |
| DOC-05 | Phase 126 | Complete |
| DOC-06 | Phase 126 | Complete |
| GUIDE-01 | Phase 127 | Pending |
| GUIDE-02 | Phase 127 | Pending |
| GUIDE-03 | Phase 127 | Pending |
| REL-01 | Phase 128 | Pending |
| REL-02 | Phase 125 | Complete |
| REL-03 | Phase 125 | Complete |
| REL-04 | Phase 128 | Pending |
| REL-05 | Phase 129 | Complete |
| REL-06 | Phase 128 | Pending |
| ANN-01 | Phase 130 | Pending |
| ANN-02 | Phase 130 | Pending |
| ANN-03 | Phase 130 | Pending |

**Coverage:**

- v1 requirements: 21 total
- Mapped to phases: 21 (roadmap complete)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-17 from `.planning/research/SUMMARY.md`*
*Last updated: 2026-06-17 — traceability filled by roadmap creation (Phases 124-130)*
