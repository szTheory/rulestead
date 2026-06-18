---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: 1.0 GA Release & Adoption
current_phase: 127
current_phase_name: adoption-guides
status: planning
stopped_at: Phase 126 verified — UAT automated (render gate + published-docs gate)
last_updated: "2026-06-18T11:15:00.000Z"
last_activity: 2026-06-18
last_activity_desc: Phase 126 verified (4 UAT checks automated); advancing to Phase 127
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 12
  completed_plans: 12
  percent: 100
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-17)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Current focus:** Phase 126 — hexdocs-front-door

**Milestone:** v2.0 — 1.0 GA Release & Adoption — IN PROGRESS (Phases 124-130)

**Previous milestone:** v1.18 CI/CD Reliability — COMPLETE + ARCHIVED 2026-06-17 — see `.planning/milestones/v1.18-ROADMAP.md`.

## Current Position

Phase: 126 (hexdocs-front-door) — EXECUTING
Plan: 6 of 6
Status: Phase complete — ready for verification
Last activity: 2026-06-18 -- Phase 126 execution started

```
[Phase A — Pre-cut doc/contract truth] [Phase B] [Phase C] [Phase D]
  124 -> 125 -> 126                        128        129        130
               127 ---+
```

Progress: [██████████] 100%

## Phase Dependency Map

```
Phase A — Contract & doc truth (ALL must complete before the cut; 124-125 serial, 126-127 can parallel after 124+125):

  124 (API surface lock: @moduledoc, @doc/@spec, api_stability.md → "1.x")
    -> 125 (version-truth sweep: 14-file reframe + drift guard + upgrading.md + MAINTAINING.md runbook)
         -> 126 (HexDocs front door: 5 groups, logo/files, theming, admin parity)
         -> 127 (adoption guides: troubleshooting.md + integrations-cookbook.md)

Phase B — The cut (gated human-merge event; blocked on ALL of 124-127):

  128 (release-as 1.0.0, disable auto-merge, hand-merge, publish both, verify-trio, post-cut cleanup)

Phase C — Provider publish (strictly after rulestead@1.0.0 is live):

  129 (open_feature_rulestead manual publish, env-gated dep swap, fresh consumer verify)

Phase D — Announce & closeout (after verify-trio green + HexDocs renders + open_feature live):

  130 (GitHub release + ElixirForum post + front-door confirmation + milestone audit)
```

Hard ordering rules:

- 124 → 125 (api_stability rewrite anchors the sweep; reviewed together for drift-guard coherence)
- 125 → 126 and 125 → 127 (version truth must land before HexDocs and guides reference it)
- 126 + 127 → 128 (ALL pre-cut work lands before the cut so the published tarball is complete and honest)
- 128 → 129 (open_feature dep ~> 1.0 can't resolve until rulestead@1.0.0 is live on Hex)
- 129 → 130 (announce only after verify-trio green + all three packages live + HexDocs front door confirmed)

Human checkpoints:

- Phase 128: disable auto-merge before adding `release-as`; hand-eyeball the release PR diff (both @version, manifest, CHANGELOG preamble); approve hex-publish environment manually.
- Phase 128 post-cut: REMOVE `"release-as"` from config immediately — leave it and release-please re-proposes 1.0.0 forever.
- Phase 129: confirm `hex.pm/api/packages/rulestead/releases/1.0.0` == 200 BEFORE publishing open_feature_rulestead.
- Phase 130: post to ElixirForum only AFTER verify-trio is green AND HexDocs renders the new shape.

## Accumulated Context

### Roadmap Evolution

- v2.0 started 2026-06-17 after v1.18 CI/CD Reliability archived (Phases 119-123 complete). Roadmap created with 7 phases (124-130): API surface lock → version-truth sweep → HexDocs front door + adoption guides (parallel) → release cut → provider publish → announce & closeout.
- Milestone-step assessment (2026-06-17) found feature band complete (~92-95% done for stated scope); published Hex is `0.1.7`/`0.1.0` despite internal v1.18 maturity (ZeroVer mismatch). Release truth + distribution is the highest-leverage lever.

### Decisions

- **All three packages publish at `1.0.0` together** (maintainer-chosen 2026-06-17): `rulestead` + `rulestead_admin` via release-please linked-versions; `open_feature_rulestead` manual publish strictly after `rulestead@1.0.0` is live.
- **`"release-as": "1.0.0"` is the ONLY mechanism to force 1.0.0** under the repo's `bump-minor-pre-major: true` + `bump-patch-for-minor-pre-major: true` config; `feat!:` yields only `0.2.0`, not `1.0.0`. Post-1.0 these two flags become no-ops.
- **Lock the existing public surface as-is** — no "last clean break" renames; API audit found no warts; zero breaking changes is the honest 1.0 story.
- **`brandbook/` is missing from package `files:`** — release-blocker; must add `brandbook/assets/logo` (and `specimens`) before the cut or logo/README 404s on hex.pm/HexDocs on launch day.
- **Three public modules are `@moduledoc false`** — `Rulestead.Context`, `Rulestead.Runtime`, `Rulestead.Admin.Policy` listed public in `api_stability.md` but excluded from HexDocs; **FIXED in 124-P01** (all three now have real `@moduledoc` and per-function `@doc`).
- **Admin.Policy `*_actions/0` helpers promoted to 1.x contract** (D-10, 124-P01) — `governance_actions/0`, `viewer_actions/0`, `editor_actions/0`, `admin_actions/0` promoted with `@doc` as read-only role-vocabulary / introspection helpers.
- **`mix.exs` `groups_for_modules` updated** (D-09, 124-P01) — "Runtime (cached lookup)": [Rulestead.Runtime] added; `Rulestead.Runtime.Snapshot` removed from Extensibility group.
- **14-file version-truth sweep** — stale `0.1.x`/`~> 0.1`/`future 1.0`/`API freeze` language across READMEs, guides, `api_stability.md`, `upgrading.md`, `MAINTAINING.md`; do not touch `.planning/` or `prompts/` (historically accurate).
- **README "Two version lines" callout must be deleted** — leaving it re-introduces the exact ZeroVer confusion the milestone exists to resolve.
- **Announce gate** — ElixirForum post only AFTER verify-trio green + `open_feature_rulestead@1.0.0` live + HexDocs front door confirmed rendered (logo, "Why Rulestead?", 3 public modules visible, badges resolve).
- **BRD-05 standalone marketing site deferred** — HexDocs + ElixirForum is the idiomatic, higher-leverage front door for an Elixir lib.
- **v2 feature wedges stay trigger-gated** — GOV-02-ext → ROL-08 → ADM-06; no trigger has fired.
- **`@deprecated` + `--warnings-as-errors` footgun** — repo's `lint.sh` runs `mix compile --warnings-as-errors`; hard-deprecating without migrating all internal callers first will break CI. Soft-deprecation (docs only) sidesteps this; document in the policy.
- **`open_feature_rulestead` dep swap** — use env-gated pattern (mirroring existing `RULESTEAD_ADMIN_HEX_RELEASE`) so local dev/CI keep the path dep; only swap to `~> 1.0` for the publish step.
- **CHANGELOG strategy** — keep release-please-generated, per-package; no root CHANGELOG; hand-author the "promotion, not rewrite" preamble above the bot's generated bullets in the release PR.
- **api_stability.md 1.x contract** (124-P02) — Opening sentence flipped to "1.x release contract"; Versioning & Deprecation Policy added (breaking-change table, telemetry stability rules, soft-deprecation worked example, empty deprecations skeleton); Admin.Policy *_actions/0 helpers added to both doc and bidirectional test guard.
- **release_contract_test.exs anchor updated** (124-P02) — Line ~181 assert updated to `1.x release contract` substring in lockstep (D-01); four *_actions/0 helpers assertion block added (D-12); all 26 tests pass.
- **Phase 124 release-gate verified green** (124-P03) — `mix docs --warnings-as-errors` exits 0 (three module HTML pages confirmed); `mix dialyzer` exits 0 (195 pre-existing skipped, unnecessary_skips: 0); `release_contract_test.exs` exits 0 (26 tests, 0 failures); no source edits required.
- [Phase ?]: 125-01: restored v1.0.0 GA fact in root README Versioning after deleting the Two version lines callout, keeping contract-test L232 green
- [Phase ?]: 125-02: shipped fail-closed scripts/check_version_truth.py — anchored ~> 0.1 lookahead skips third-party ~> 0.1.3 pin; wired into lint.sh under set -euo pipefail
- [Phase ?]: 125-02: guard exempts the sanctioned 0.1.x -> 1.0 upgrade-arrow line (line-scoped, Unicode+ASCII) so ROADMAP SC-4's Plan-03 heading stays satisfiable while other stale 0.1.x claims still caught
- [Phase 125]: 125-03: MAINTAINING runbook states open_feature_rulestead is a separate MANUAL publish (Phase 129), not release-please managed (D-08)
- [Phase 125]: 125-03: 1.0.0 CHANGELOG preamble staged in brandbook/, not committed into bot-managed CHANGELOGs (D-09)
- [Phase ?]: D-09 brandbook symlinks committed as mode 120000 in both packages
- [Phase ?]: D-19 rs-social-card.png rasterized at 1200x630 via @resvg/resvg-js JS API; pure-path SVG so no text-flatten needed
- [Phase ?]: D-10 check_logo_bytes.sh asserts real SVG bytes in core tarball; wired into contributor.sh; expected-fail until plan 05 adds files: glob
- [Phase ?]: Canonical positioning page, NOT a README quickstart duplicate
- [Phase ?]: Zero named competitor vendors, no comparison matrix — brand guardrail D-18 upheld
- [Phase ?]: D-20: Centered README hero uses rs-wordmark-tagline.svg (340x96) above existing H1; 5 shields.io badges each wrapped in <a href>; Hex version badge self-heals via shields hexpm/v/rulestead
- [Phase ?]: D-01..D-05: 6 module groups; D-06: API & Stability first-match defuse; D-13..D-16: before_closing_head_tag --main* retint, body.dark, PNG og:image
- [Phase ?]: Duplicated before_closing_head_tag/1 verbatim from core (D-21): two mix.exs cannot share code; only og:image host differs
- [Phase ?]: @doc false on __using__/1 + live_session/3 in RulesteadAdmin.Router; real @moduledoc leads with host-owns-auth + 3 contracted session keys verbatim from api_stability.md (D-22/D-23)

### Milestone-specific constraints (v2.0)

- No new runtime APIs or schema changes — release-truth milestone only.
- No renames — public surface locked as-is, zero breaking changes.
- Phases 124-127 MUST complete before Phase 128 (cut) — so the tarball is honest.
- Phase 128 MUST complete before Phase 129 — dep resolution order.
- Phase 129 MUST complete before Phase 130 — announce only after all three packages live.

### Deferred Items (v2)

| Category | Item | Trigger |
|----------|------|---------|
| Governance | GOV-02-ext threshold profiles | Per-env/tenant thresholds needed |
| Rollouts | ROL-08 baseline comparison | Host baselines for guarded rollouts |
| Admin | ADM-06 draft presets | High authoring duplication pain |
| Theme | THM-07 per-host branding overrides | Host-supplied token palette |
| Accessibility | A11Y-04 forced-colors / high-contrast mode | v1.13 delivers AA in light+dark only |
| Motion | MOT-03 richer view-transition choreography | LiveView morph + View Transitions API |
| Brand | BRD-04 full custom icon library | Sustained UI icon demand |
| Brand | BRD-05 standalone marketing/docs website | Adoption justifies dedicated site |

### Open investigations

| ID | Topic | Status | Proof |
|----|-------|--------|-------|
| INV-CTX-01 | Quickstart `traits:` vs `attributes:` | **Closed** | v1.10.1 context-truth work |
| INV-API-01 | `api_stability.md` vs release contract | **Closed** | v1.10.1 API contract work |
| INV-MAINT-01 | MAINTAINING vs `api_stability.md` | **Closed** | v1.10.1 maintainer-doc work |
| INV-INTRO-01 | Intro spine missing Plug/supervision/lifecycle | **Closed** | v1.11 integration-spine work |
| INV-REL-01 | `0.1.x` Hex line vs actual platform maturity (ZeroVer) | **Active — v2.0 milestone resolves** | Hex `0.1.7`/`0.1.0` + `api_stability.md` v0.1.0 carry-forward; v2.0 = 1.0.0 release + adoption |

## Operator Next Steps

- **Start Phase 124: API Surface Lock & Stability Contract** — run `/gsd:plan-phase 124` to create the plan.
- Phases 124 → 125 are serial; 126 and 127 can run in parallel once 124+125 are done.
- Phase 128 (the cut) is gated on ALL of 124-127 complete.
- Full dependency ordering and human checkpoints documented above.

## Latest Verification

- Requirements: `.planning/REQUIREMENTS.md` maps 21/21 v2.0 requirements to Phases 124-130. Coverage: 100%.
- Roadmap: `.planning/ROADMAP.md` defines 7 sequential phases with hard ordering rules enforcing all pre-cut work before the cut.
- Phase 128 gate: `mix ci` green + `release_contract_test.exs` green + `mix hex.build` tarball contains logo SVGs + Phases 124-127 complete.
- Active constraints: no new runtime APIs, no renames, no schema changes, no admin standalone publish prep.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 124 P03 | 2min | 2 tasks | 0 files |
| Phase 124 P02 | 8min | 2 tasks | 2 files |
| Phase 87 P01 | 15min | 2 tasks | 4 files |
| Phase 88 P01 | 8min | 2 tasks | 1 files |
| Phase 89-focus-interaction-state-unification P01 | 8 | 1 tasks | 1 files |
| Phase 89-focus-interaction-state-unification P02 | 18 | 2 tasks | 1 files |
| Phase 90 P01 | 15 | 2 tasks | 2 files |
| Phase 90 P02 | 15 | 3 tasks | 2 files |
| Phase 90 P03 | 5min | 1 tasks | 1 files |
| Phase 91 P01 | 2 | 2 tasks | 2 files |
| Phase 92-ia-home-refinement P01 | 10m | 2 tasks | 1 files |
| Phase 93-per-screen-polish P01 | 40 | 2 tasks | 2 files |
| Phase 95 P02 | 20 | 1 tasks | 1 files |
| Phase 95 P03 | 20 | 1 tasks | 1 files |
| Phase 96 P01 | 4min | 2 tasks | 2 files |
| Phase 96 P02 | 3min | 2 tasks | 4 files |
| Phase 96 P03 | 1min | 2 tasks | 2 files |
| Phase 96 P04 | 5min | 2 tasks | 2 files |
| Phase 97-logo-mark-svg-system P01 | 15 | 2 tasks | 5 files |
| Phase 97-logo-mark-svg-system P04 | 8 | 2 tasks | 3 files |
| Phase 98-admin-re-skin-css-cascade P01 | 8 | 2 tasks | 3 files |
| Phase 114-repo-native-component-matrix-harness P01 | 8min | 3 tasks | 4 files |
| Phase 98-admin-re-skin-css-cascade P02 | 7min | 2 tasks | 2 files |
| Phase 98-admin-re-skin-css-cascade P03 | 4min | 2 tasks | 1 files |
| Phase 98-admin-re-skin-css-cascade P04 | 5min | 2 tasks | 4 files |
| Phase 99-specimens P01 | 10min | 2 tasks | 2 files |
| Phase 99-specimens P02 | 2min | 2 tasks | 2 files |
| Phase 99-specimens P03 | 2min | 2 tasks | 2 files |
| Phase 99-specimens P04 | 5min | 2 tasks | 6 files |
| Phase 100-marketing-copy-repo-artifact-plan P01 | 4min | 2 tasks | 3 files |
| Phase 100-marketing-copy-repo-artifact-plan P02 | 2min | 1 tasks | 2 files |
| Phase 100-marketing-copy-repo-artifact-plan P03 | 5min | 2 tasks | 5 files |
| Phase 100-marketing-copy-repo-artifact-plan P04 | 5min | 2 tasks | 3 files |
| Phase 112.1-close-gap-bui-05-bui-06-dynamic-fleetdesk-launcher-url-and-e P01 | 8min | 3 tasks | 6 files |
| Phase 112.1-close-gap-bui-05-bui-06-dynamic-fleetdesk-launcher-url-and-e P02 | recovered | 2 tasks | 6 files |
| Phase 114-repo-native-component-matrix-harness P02 | 11min | 2 tasks | 2 files |
| Phase 115-foundations-hardening P01 | 6min | 2 tasks | 4 files |
| Phase 115-foundations-hardening P02 | 3min | 2 tasks | 3 files |
| Phase 115-foundations-hardening P03 | 10min | 2 tasks | 1 files |
| Phase 116 P01 | 5 min | 2 tasks | 5 files |
| Phase 116 P02 | 10 min | 2 tasks | 11 files |
| Phase 116 P03 | 16 min | 2 tasks | 12 files |
| Phase 116 P04 | 10 min | 2 tasks | 5 files |
| Phase 117-page-flow-ia-pass P01 | 7min | 2 tasks | 6 files |
| Phase 117-page-flow-ia-pass P02 | 7min | 2 tasks | 1 files |
| Phase 117-page-flow-ia-pass P03 | 22min | 2 tasks | 10 files |
| Phase 117-page-flow-ia-pass P04 | 6min | 2 tasks | 10 files |
| Phase 118-evidence-idempotence-guardrails P02 | 6min | 2 tasks | 1 files |
| Phase 119 P01 | 12 min | 3 tasks | 1 files |
| Phase 119 P02 | 38 min | 3 tasks | 1 files |
| Phase 119 P03 | 16 min | 3 tasks | 1 files |
| Phase 121 P01 | 6min | 2 tasks | 3 files |
| Phase 121-mix-exunit-performance-test-value-cleanup P03 | 15 | 2 tasks | 1 files |
| Phase 122-browser-demo-integration-determinism P01 | 4min | 4 tasks | 3 files |
| Phase 123-dx-closeout-proof P01 | 12min | 2 tasks | 2 files |
| Phase 123 P02 | 15 minutes | 2 tasks | 2 files |
| Phase 123 P03 | 15min | 2 tasks | 3 files |
| Phase 119.1-verify-phase-119-audit-deliverable-cidx-01-02-03 P01 | 3min | 2 tasks | 3 files |
| Phase 125 P01 | 6 min | 3 tasks | 13 files |
| Phase 125 P02 | 3min | 2 tasks | 3 files |
| Phase 125 P03 | 12m | 3 tasks | 3 files |
| Phase 126 P01 | 15 | 3 tasks | 5 files |
| Phase 126 P02 | 1 minute | 1 tasks | 1 files |
| Phase 126 P03 | 2min | 1 tasks | 1 files |
| Phase 126 P05 | 3m | 2 tasks | 2 files |
| Phase Phase 126 PP06 | 3min | 2 tasks | 2 files |

## Session

**Last session:** 2026-06-18T13:58:02.997Z
**Stopped at:** Completed 126-03-PLAN.md
**Resume file:** None
