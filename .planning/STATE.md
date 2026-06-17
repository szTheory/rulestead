---
gsd_state_version: 1.0
milestone: v1.18
milestone_name: CI/CD Reliability
status: Awaiting next milestone
last_updated: "2026-06-17T18:43:34.816Z"
last_activity: 2026-06-17 — Milestone v1.18 completed and archived
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 14
  completed_plans: 14
  percent: 100
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-17)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Current focus:** Planning next milestone (`/gsd:new-milestone`). v2 feature wedges (GOV-02-ext → ROL-08 → ADM-06) require an explicit new milestone per `.planning/DEFERRED.md`.

**Milestone:** v1.18 CI/CD Reliability — COMPLETE + ARCHIVED 2026-06-17 — see `.planning/milestones/v1.18-ROADMAP.md`.

**Previous milestone:** v1.17 Admin Design System Stress Test shipped 2026-06-15 — see `.planning/milestones/v1.17-ROADMAP.md`

**Assessment:** v1.18 is scoped as post-GA CI/CD reliability and maintainer-DX work. It should improve speed, determinism, cache correctness, runner efficiency, and failure actionability without weakening release-gate trust or widening product scope.

## Current Position

Phase: Milestone v1.18 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-17 — Milestone v1.18 completed and archived

## Phase Dependency Map

```
119 (baseline + expert audit)
  -> 120 (workflow topology + cache hygiene)
        -> 121 (Mix/ExUnit performance + test value cleanup)
              -> 122 (browser/demo/integration determinism)
                    -> 123 (DX + closeout proof)
```

Strictly sequential: **119 -> 120 -> 121 -> 122 -> 123**

Human checkpoints:

- Phase 119 should confirm the baseline, recommendations, test/check classification, and no-go guardrails before workflow or test behavior changes.
- v1.18 keeps the release-trust boundary: conservative signal-first optimization, no product runtime APIs, no schema changes, no admin publish-prep, and no cosmetic speedup that hides risk.

## Accumulated Context

### Roadmap Evolution

- v1.18 started after v1.17 audit closeout: CI/CD Reliability spans Phases 119-123 and focuses on baseline measurement, workflow/cache hygiene, Mix/ExUnit performance, browser/demo determinism, and contributor-DX closeout.
- v1.17 started after v1.16 audit closeout: Admin Design System Stress Test spans Phases 113-118 and focuses on repo-native component matrix evidence, foundations hardening, primitive/composite polish, page-flow IA, and idempotent design-system guardrails.
- Phase 112.1 inserted after Phase 112: Close gap: BUI-05/BUI-06 - dynamic FleetDesk launcher URL and evidence (URGENT)
- Phase 119.1 inserted after Phase 119: Verify Phase 119 audit deliverable (CIDX-01/02/03) (URGENT)
- Phase 119.1 executed and complete (2026-06-17): produced `119.1-VERIFICATION.md` (status: passed) covering CIDX-01/02/03 against `119-CI-CD-AUDIT.md` with line-cited section coverage; closed orphan gap from `.planning/v1.18-MILESTONE-AUDIT.md`.

### Decisions

- **Phase 123 Plan 02 (D-12/D-13/D-14):** `MAINTAINING.md` shift-left gate section extended with command ladder paragraph naming `cd rulestead && mix ci` as the fast-loop alias for `bash scripts/ci/contributor.sh`; new `## CI Failure Triage` section added with 9-row 6-column table in `release_gate` pipeline order. Verbatim microcopy lifted from `scripts/ci/test.sh:67-90` (mounted-proof) and case switch (openfeature-companion) per D-12. `publish-hex` and `verify-published-release` rows labeled release-trust gate, not a speed target per D-13. D-14 guard: 5 `assert maintaining =~` assertions added inside existing maintainer guidance test in `release_contract_test.exs`; `mix test release_contract_test.exs` exits 0 (26 tests, 0 failures). Pre-existing `lint.sh` `ADMIN FOUNDATION DRIFT DETECTED` (missing 115-FOUNDATIONS-CONTRACT.md) is out-of-scope and deferred.
- **Phase 123 Plan 01 (D-03/D-05/D-09):** `123-CI-CD-CLOSEOUT.md` created as CIDX-10 milestone counterpart to `119-CI-CD-AUDIT.md`. Before/after deltas cited from `121-MEASUREMENT.md:136-154` (no re-measurement per D-03). p95 recorded as unavailable with verbatim `119-CI-CD-AUDIT.md:109` reason (D-05). Cache hit rate qualitative only per `scripts/ci/report_cache_hit.sh` (D-05). `119-CI-CD-AUDIT.md:213` reconciled: fast-contributor-loop now names `cd rulestead && mix ci` (alias for `bash scripts/ci/contributor.sh`) per D-09; zero behavioral change confirmed by `mix.exs:172`.
- **Phase 121 Plan 02 (D-01/D-02 audit):** Evidence-gated async audit of 23 async:false RepoCase candidates produced 121-ASYNC-AUDIT.md. Net flips = 0: every candidate carries at least one disqualifying hazard (global Rulestead.Fake singleton, Application.put_env, :telemetry.attach, capture_log, or DDL-in-setup). code_refs_plug_test.exs: KEEP SERIAL (DDL-in-setup = DB-ownership hazard). Do-not-flip trio preserved (stale_flag_worker, batcher, inbound_http). Suite remains green: 586 tests, 0 failures.
- **Phase 121 Plan 01 (D-03/D-08):** Published-Hex smoke test (`"admin consumer fixture compiles against published Hex packages"`) moved behind `@tag :published_hex_smoke` + `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` env, excluded by default in `test_helper.exs`. Proof preserved and confirmed running on `guarded_rollout_foundations` scope via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix rulestead test --include published_hex_smoke`. Default suite: ~5s, 586 tests, 0 failures (was ~42s). Failure microcopy added for guarded_rollout_foundations scope. No blind retry (D-04). install_integration gate preserved.
- **v1.18 scope:** Maintenance-quality CI/CD reliability milestone. Audit first, then implement conservative, evidence-backed improvements to pipeline performance, determinism, cache correctness, test value, release trust, and contributor DX.
- **v1.18 optimization posture:** Preserve high-value release/adopter/mounted/OpenFeature proof bars unless Phase 119 proves a narrower equivalent catches the same bug class. Do not delete slow tests solely because they are slow.
- **v1.18 research posture:** Put external-source and comparable-OSS workflow research inside Phase 119 audit artifacts instead of running a separate pre-milestone `.planning/research/` pass.
- **Phase 119 context:** `.planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md` locks the audit-first posture, one integrated `119-CI-CD-AUDIT.md`, always-triggered CI plus aggregate `release_gate` baseline, linked sibling-package release trust, Mix/ExUnit diagnostics before tuning, no Phase 119 behavior changes, generated browser artifacts over pixel baselines, and scripts-first contributor DX.
- **Phase 120 context:** `.planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-CONTEXT.md` locks D-01..D-12 — preserve always-triggered CI + single `release_gate` aggregate; **wire `openfeature-companion` into `release_gate.needs`** with the mounted-proof not-relevant→success transform; correctness-first cache hygiene (drop the cross-lane `${{ runner.os }}-mix-` fallback, scope lint/PLT `hashFiles` to `rulestead/mix.lock`, document busting rules); lightweight scripts-first version/cache/repro observability; preserve all release/supply-chain trust surfaces unchanged; **branch-protection 404 reconciled by docs only — no `gh api` writes**. Two audit-flagged open questions (OpenFeature gate, branch-protection scope) resolved with maintainer.
- **v1.17 harness choice:** Use a repo-native Phoenix/Playwright UI matrix that renders real admin components. Do not adopt standard JavaScript Storybook for this milestone; PhoenixStorybook remains a future option if maintainer-facing component docs become necessary.
- **v1.17 scope:** Full mounted admin/operator design-system pass, not runtime product work. No public runtime APIs, schemas, release workflow changes, palette redesign, logo redraw, component framework adoption, broad pixel-baseline maintenance, external AI judging dependency, v2 wedge, or `rulestead_admin` standalone publish prep.
- **v1.17 evidence posture:** Screenshots plus deterministic assertions and human review. Continue the v1.16 preference for broad Playwright artifacts over checked-in pixel baselines.
- **Phase 118 Plan 01:** Added `scripts/check_design_system_evidence.py`, a stdlib source guard for UI matrix/workflow evidence hooks, generated screenshot posture, selected contrast labels, fixture-health states, and forbidden visual-baseline tooling.
- **Phase 118 Plan 01 lint wiring:** `scripts/ci/lint.sh` now runs the design-system evidence guard after admin foundations and before SVG budgets, keeping the normal guard spine focused and dependency-free.
- **Phase 118 Plan 02 evidence map:** Created `118-EVIDENCE.md` with exact backend command, `DEMO_BACKEND_URL=http://localhost:4061`, generated screenshot artifact globs, PASS output, intentional exceptions, and residual risks for VER-01 through VER-04.
- **Phase 118 Plan 02 artifact posture:** Browser evidence was rerun with `--output=test-results/phase118-evidence`, producing 7 matrix screenshots and 48 workflow screenshots as ignored Playwright artifacts; no screenshots, baselines, or visual-diff tooling were committed.
- **Phase 118 Plan 03 closeout:** `118-EVIDENCE.md` now maps VER-01 through VER-04 to proof commands, artifact patterns, guard output, decision coverage D-01 through D-20, intentional exceptions, and residual risks; requirements, roadmap, state, and validation truth are updated after evidence exists.
- **Phase 113 context:** `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md` locks the inventory taxonomy, UI matrix state contract, operator lenses, evidence posture, and scope constraints for downstream planning.
- **Phase 114 context:** `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md` locks a demo-hosted, dev/test-only Phoenix/Playwright matrix that renders real `RulesteadAdmin.Components.*` and selected seeded admin flow examples without widening `RulesteadAdmin.Router.rulestead_admin/2`, package metadata, release workflow, CSS foundation work, or component polish scope.
- **Phase 114 Plan 01:** `/dev/rulestead-admin/ui-matrix` is a demo-hosted dev/test route outside `RulesteadAdmin.Router.rulestead_admin/2`; it renders real `RulesteadAdmin.Components.*` modules inside `Shell.page/1` with deterministic fixtures from `UiMatrixFixtures`.
- **Phase 114 Plan 01 evidence:** focused ExUnit coverage proves `.rs-shell`, all required `data-matrix-section` selectors, representative real component output, fixture health, demo/package router boundaries, and no Storybook/PhoenixStorybook/pixel-baseline tooling.
- **Phase 115 context:** `.planning/phases/115-foundations-hardening/115-CONTEXT.md` locks foundation-only hardening for breakpoints, scalar token/docs alignment, focus, reduced motion, radius/elevation/emphasis rules, dense-table/technical-row containment, and focused matrix/guard verification without widening product, package, release, component, Storybook, pixel-baseline, FleetDesk, or publish-prep scope.
- **Phase 116 context:** `.planning/phases/116-primitive-composite-polish/116-CONTEXT.md` locks component-function-first polish, Phase 115 foundation reuse, canonical mutation-confirm alignment, domain composite in-place polish, bounded raw `rs-*` consolidation/documented exceptions, and operator-specific microcopy without widening API, schema, release, package, FleetDesk, Storybook, pixel-baseline, or publish-prep scope.
- **Phase 117 context:** `.planning/phases/117-page-flow-ia-pass/117-CONTEXT.md` locks route-flow IA recommendations: preserve grouped JTBD navigation, review page-owned IA surfaces, use deterministic matrix plus selected route evidence, test keyboard/mobile/focus at route level, and keep audit/explain/simulate fixes evidence-triggered.
- **Hex release:** `rulestead` + `rulestead_admin` **0.1.3** live (2026-05-28). Post-publish verify trio green.
- **Handoff thread:** `.planning/threads/2026-05-28-post-0.1.2-maintenance-handoff.md` — read after context clear.
- **Path-to-done: complete** (v1.10.1 + v1.11 + v1.11.1 gap closure + v1.12 adoption evidence shipped).
- **Done band (repo-verified):** 93–95% for stated post-GA scope — near-done; diminishing returns on major milestones.
- **CI hygiene:** Mix + Dialyzer PLT caches; PLTs gitignored; `release-pr-ci` dispatch fixed; `gate-ci-green` polls for merge CI.
- **Ecto 3.14:** Coordinated `ecto_sql ~> 3.14` bump shipped (maintenance); Decimal 3.x via transitive lock.
- Open v2.0.0 **only** with a deferred trigger; default wedge order GOV-02-ext → ROL-08 → ADM-06.
- **Current adopter bar:** `mix verify.phase82` / `mix verify.adopter` (delegates to phase82).
- **v1.13 persistence:** localStorage via colocated JS hook (not cookie/host-session); follows existing CmdK hook pattern in `shell.ex`.
- **v1.13 control:** segmented System / Light / Dark in the shell header context cluster.
- **v1.13 dark palette:** purpose-built mineral-dark (base ~`#10161f`, never pure black); desaturated brand; elevation by lightening + hairline borders.
- **v1.13 FOUC strategy:** system users flash-free via `@media` (no JS); pinned users get `data-theme-pending` instant snap; optional documented host `<head>` script (not required).
- **v1.13 token scope:** `.rs-shell` / `[data-rulestead]` only — never `:root` / `<html>`.
- **v1.13 merge posture:** land on branch; merge to main (auto-publishes minor bump) only when both-theme/contrast gate is green across all phases.
- **v1.14 approach:** Mirror-not-generate. `tokens.json` is the canonical record; `tokens.css` and `rulestead_admin.css` are hand-authored mirrors kept honest by two composable drift-check scripts. No Style Dictionary, no SCSS preprocessor, no Node.js build step.
- **v1.14 dark base:** v1.13 `#10161f` is canonical; Basalt `#0F1720` is visually indistinguishable (1.01:1 contrast) — do not swap. Elevation by luminance increase, not hue shift.
- **v1.14 re-skin scope:** Colors only across all 4 cascade blocks. Zero non-color property changes in `rulestead_admin.css`. Confirmed by narrow-diff review in Phase 98.
- **v1.14 SVG policy:** Only raster binaries allowed in repo: `favicon.ico`, `favicon.png`, `apple-touch-icon.png`. All logo and specimen SVGs are source-controlled. PNGs generated on demand (never committed).
- **v1.14 font policy:** Google Fonts CDN references only (Sora, Inter, IBM Plex Mono — all SIL OFL 1.1). No font binaries committed. SVG wordmark text outlined to paths before committing.
- Phase numbering continues at **102** for v1.15.
- [Phase 97-02]: Selected mark: **G4c** — multivariate decision branch, lit route (Stead Blue structure/input/off-arms, Ember Copper active top route, Quarry off-nodes). Gate pre-resolved in 97-CONCEPT-REVIEW.md.
- [Phase 97-02]: Wordmark letterforms: geometric hand-authored outline paths (fontTools Pattern 6 fallback — Google Fonts CDN unreachable in exec env; script committed for future use).
- [Phase 97-02]: Mono mark treatment: G4f — active node filled, off nodes hollow-stroked, so active-vs-off survives in `fill="currentColor"` contexts.
- [Phase 97-02]: 7-file lockup set committed to `brandbook/assets/logo/` — all < 20KB, zero text elements, zero raster, accessible (title+desc+role=img).
- [Phase 97-03]: rs-mark.svg + rs-mark-dark.svg committed to `rulestead_admin/priv/static/images/` (LOGO-04 done); phoenix-flame (FD4F00) retired from demo logo (LOGO-05 done).
- [Phase 97-03]: New demo logo fingerprint: `2d303e8acdf20eb43468b22535dfba4e` (replaced `06a11be1f2cdde2c851763d00bdd2e80`); cache_manifest.json gitignored in demo backend — not committed but verified regenerated.
- [Phase 97-03]: Orchestrator visual confirmation passed — new mark renders at 36px in demo header on light+dark; favicon legible at 16px.
- [Phase 99-01]: palette.svg + typography.svg committed to brandbook/assets/specimens/. Both SVGO-optimized, accessible (role=img + title + desc + aria-labelledby), zero base64, well within 51200-byte CI budget (palette 10034 bytes, typography 3680 bytes). SPEC-01 done.
- [Phase 99-01]: SVGO preset-default strips role="img" via removeUnknownsAndDefaults — re-inserted via sed after optimization; shared svgo.config.mjs left unmodified.
- [Phase 99-02]: components.svg (3,455 bytes) + code-block.svg (1,785 bytes) committed to brandbook/assets/specimens/. Both SVGO-optimized, accessible (role=img + title + desc + aria-labelledby), zero base64, well within 51,200-byte CI budget. SPEC-02 done.
- [Phase 99-03]: readme-header.svg (1,227 bytes) + social-card.svg (1,501 bytes) committed to brandbook/assets/specimens/. Both SVGO-optimized, accessible, zero base64, well within 51,200-byte CI budget. readme-header: 480x96 light layout, inline light-mode mark, live-text wordmark #183247. social-card: 1200x630 Ink Blue #183247, inline dark-mode mark, live-text wordmark #e8edf3, token annotation. Phase 97 rs-social-card.svg untouched.
- [Phase 99]: 6 SVG specimens committed to brandbook/assets/specimens/ — palette, typography, components, code-block, readme-header, social-card
- [Phase 99]: All specimens use hard-coded hex literals (no var(--rs-*)); live <text> elements for typography.svg (not outlined paths); specimens are self-contained (no external <use href>)
- [Phase 99]: SVGO optimized with brandbook/assets/logo/svgo.config.mjs (removeDesc:false, cleanupIds:false, convertColors:false); all 6 files ≤51200 bytes
- [Phase 99]: social-card.svg in specimens/ is a new design reference distinct from Phase 97 brandbook/assets/logo/rs-social-card.svg (production asset untouched)
- [Phase 97-04]: Phase 97 complete 2026-06-05. Full Nyquist sweep passed (13/13 assertions green). Selected mark G4c (multivariate decision branch). 7-SVG lockup set in brandbook/assets/logo/. Admin copies in rulestead_admin/priv/static/images/. Phoenix-flame demo logo retired; new fingerprint `2d303e8acdf20eb43468b22535dfba4e`. LOGO-01..05 done.
- [Phase 87-01]: Theme specs use file:// harness navigation (no Phoenix required). wcagRatio inline TypeScript, no external dep.
- [Phase 88]: --rs-primary-ring gap token added to all 4 cascade blocks; 18 hardcoded rgba() literals replaced; warning-flash amber border fixed
- [Phase 98-03]: Block 3 source-of-truth; 8 mineral dark swaps applied verbatim from tokens.json admin_css_mapping.dark; --rs-success-border #166534→#166634 one-digit fix applied
- [Phase 98-03]: Dark synced-pair restored: Block 2 (@media) mirrors Block 3 ([data-theme=dark]); check_synced_pair.py exits 0 (56 dark + 57 light tokens)
- [Phase 98-03]: SKIN-01 complete — all 4 cascade blocks carry mineral palette; check_brand_tokens.py exits 0 (68 tokens, 15 mismatches resolved)
- [Phase 98]: All 4 cascade blocks re-skinned to mineral palette — colors only; 15 hex swaps (7 light Block 1+4, 8 dark Block 3+2)
- [Phase 98]: check_synced_pair.py extended to assert both Block 1≡4 (light) and Block 2≡3 (dark) pairs
- [Phase 98]: check_brand_tokens.py extended to diff Block 3 vs admin_css_mapping.dark
- [Phase 98]: lint.sh CWD bug fixed — cd back to RULESTEAD_REPO before guard invocations
- [Phase 98]: design-system.html swatches auto-reflected mineral palette via var(--rs-*) — zero manual edits; SC-1 diff reviewed and approved
- [Phase 100]: brandbook/VOICE.md and brandbook/RELEASE-TEMPLATE.md committed, grounded in brand-book sections 9/19/21, with 11 say-this/not-this examples across empty, error, and success states
- [Phase 100]: brandbook/COPY.md committed with GitHub description/topics, Hex descriptions, 140-char blurb, README/landing copy, three feature blurbs, and szTheory shared-vs-unique brand-architecture note
- [Phase 100]: rulestead and rulestead_admin package descriptions updated to functional Hex-ready wording; the admin package remains optional mounted Phoenix LiveView companion copy, not a widened runtime surface
- [Phase 100]: brandbook/README.md and docs/brand-usage.md finalized; stale Phase 96/98 "intentional exit 1" contributor guidance removed from live docs
- [Phase 100]: brandbook/BUDGET.md documents exact live limits (logo SVG <=20480 bytes, specimen SVG <=51200 bytes); root .gitattributes added for source-vs-binary asset review
- [Phase 101]: plan approved with 4 waves: generator core, page experience, drift/CI guard, browser evidence + v1.14 closeout
- [Phase 101-01]: generator core committed. `scripts/gen_brandbook_html.py` renders deterministic stdlib-only `brandbook/index.html` from brand-book, tokens, docs, final logo SVGs, and specimen SVGs; generated output is 119012 bytes and regenerates cleanly.
- [Phase 101-02]: full generated page experience committed. `brandbook/index.html` now has all nine source-driven sections, scoped System/Light/Dark control, no-JS baseline, inline logo/specimen previews, focus/reduced-motion polish, and visible links to the UI spec + admin shell theme-control precedent.
- [Phase 101-03]: generated HTML guard committed. `scripts/check_brandbook_html.py` enforces drift, required sections/source refs, unsafe marker exclusions, local link validity, unique inline SVG IDs, trailing newline, and the 262144-byte budget; `scripts/ci/lint.sh` now prints `BRANDBOOK HTML SYNCED (133280 bytes)` before `SVG SIZE BUDGET OK`.
- [Phase 101-04]: file:// browser evidence committed in `examples/demo/frontend/tests/brandbook.spec.ts`; `brandbook/README.md` now links generated `index.html` and generator/checker commands; final gate passed with `BRANDBOOK HTML SYNCED (133765 bytes)`, `BRAND TOKENS SYNCED (68 tokens)`, `TOKENS.CSS MIRROR SYNCED (68 tokens)`, `SVG SIZE BUDGET OK`, and `brandbook.spec.ts` 6/6 tests passing.
- [v1.14]: shipped 2026-06-06 after Phase 101 verification. No runtime API, schema, package-version, release-workflow, Hex publishing config, or `rulestead_admin` publish-prep changes were made in the capstone closeout.
- **v1.15 scope:** Tournament lockup unit = the whole integrated lockup (icon fused with type), not just the icon. Hard constraints every round: no icon-left-of-plain-text; no rectangular container behind mark; logotype visually fused; primary lockup tagline-free; a with-tagline secondary variant ships.
- **v1.15 font/color policy:** fonts/colors move ONLY if the tournament-winning design demands it; recorded explicitly in `103-WINNER.md`; palette/voice/copy otherwise frozen.
- **v1.15 curl policy:** `gen_glyph_paths.py` fetches TTFs via curl subprocess (not urllib — urllib hangs on gstatic fonts requiring browser UA per exec-env memory).
- **v1.15 parked branch:** `fix/admin-ui-polish-attention-rail-search` has dirty `shell.ex`, `rulestead_admin.css`, `root.html.heex`, `favicon.ico`, untracked `favicon.svg`. Merge-order decision required from maintainer before Phase 105 executes.
- **v1.16 brand boundary:** FleetDesk is intentionally a distinct host/example app. Rulestead identity applies to the mounted admin, brandbook, static fixtures, and demo launcher chrome; FleetDesk should be harmonized but not Rulestead-branded.
- **v1.16 token correction policy:** Palette and logo remain frozen. Evidence-proven semantic-token drift may be corrected using existing palette colors (for example foreground/focus/soft-primary roles) with token mirrors and generated brandbook kept in sync.
- **v1.16 evidence posture:** Prefer broad Playwright screenshot artifacts across route clusters/themes/viewports over checked-in pixel baselines for every screen.
- **v1.16 shipped scope:** Static fixtures now expose the v1.15 winner wordmark, copied admin wordmark assets are drift-checked, brandbook token output stays generated from canonical sources, and normal lint now covers logo drift + contrast.
- **v1.16 admin UI:** Shared primitives keep theme tokens scoped to `.rs-shell` / `[data-rulestead]`; primary-button foreground, soft-primary states, and focus rings are aligned to the frozen mineral palette in light/dark/system modes.
- **v1.16 demo boundary:** The Phoenix launcher carries Rulestead identity, while FleetDesk uses a separate host-app visual system. FleetDesk must not be converted into a Rulestead-branded app in future polish.
- **v1.16 runtime verifier fix:** Compose/browser evidence exposed a Redis publisher transaction race; the snapshot fetch is now deferred through the publisher process with a bounded retry so kill-switch browser proof reflects the committed runtime state.
- **v1.16 compose proof fix:** Dynamic-port browser proof now serves the frontend with a matching `NEXT_PUBLIC_FLAGS_API_BASE` and backend CORS allowlist for both selected loopback origins.
- **Phase 112.1-01:** Phoenix-owned FleetDesk launcher and shared layout navigation links now read `DEMO_FRONTEND_URL` through runtime application config, with `http://localhost:3000` only as the unaided local fallback. Backend regression tests prove a non-3000 configured URL renders in both surfaces.
- **Phase 112.1-02:** Compose-backed Playwright evidence now asserts both Phoenix-rendered FleetDesk links against the selected `DEMO_FRONTEND_URL`, clicks through from the launcher to FleetDesk, includes the fleet-map-v2 rollouts evidence row, and records D-01 through D-12 verification truth.
- **v1.16 audit close:** Backfilled canonical BUI requirement rows, `requirements-completed` summary frontmatter, and Nyquist validation artifacts for Phases 107-112; `.planning/milestones/v1.16-MILESTONE-AUDIT.md` is `passed`.
- [Phase 114]: Use curated Playwright screenshots and deterministic assertions instead of visual snapshot tooling. — Plan 114-02 followed the v1.17 evidence posture: screenshots are test artifacts only, with source guards blocking baseline/snapshot tooling.
- [Phase ?]: Phase 121 Plan 03 (D-09 measurement): Default lane ~4.6s real (was ~42s baseline); dominant test 17090ms on opt-in lane; delta -37s (-88%). D-06 partitioning REJECTED: 5 verified premises (serial network test; async:false suite; per-partition DB/Fake isolation fragility; no partition config; 18 schedulers absorb async set) -> FUT-01 deferred. D-05 no splits (next-slowest 303ms). D-07 no Dialyzer/PLT change. D-10 length-47 xref cycle noted only.
- [Phase ?]: Phase 122 Plan 01 (D-01..D-06): Fixed Playwright trace/retry mismatch at root cause (retain-on-failure, retries:0 unchanged). verify.sh gets failure-output block via || {} idiom. CI gets SHA-pinned upload-artifact step (ea165f8d/v4.6.2, if:failure()). D-03 audit evidence: demo readiness sound (real Docker health polling, zero waitForTimeout). D-06: 15 specs all KEEP (10 functional journeys + 5 visual-evidence matrices, no CIDX-05 demotion evidence).
- [Phase ?]: Phase 123 Plan 03 (D-15..D-20): Both mandatory verification gates passed; REQUIREMENTS.md already complete; ROADMAP.md updated with Phase 123 complete and all 10 CIDX rows Complete; STATE.md set to completed_phases 5, percent 100, v1.18 milestone closed.

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

### Graduation candidates (doc / release — not blocking)

All closed — v1.12 adoption evidence depth complete.

### Open investigations

| ID | Topic | Status | Proof |
|----|-------|--------|-------|
| INV-CTX-01 | Quickstart `traits:` vs `attributes:` | **Closed** | v1.10.1 context-truth work |
| INV-API-01 | `api_stability.md` vs release contract | **Closed** | v1.10.1 API contract work |
| INV-MAINT-01 | MAINTAINING vs `api_stability.md` | **Closed** | v1.10.1 maintainer-doc work |
| INV-INTRO-01 | Intro spine missing Plug/supervision/lifecycle | **Closed** | v1.11 integration-spine work |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone

## Latest Verification

Current v1.18 planning proof:

- Requirements: `.planning/REQUIREMENTS.md` maps 10/10 v1.18 requirements to Phases 119-123.
- Roadmap: `.planning/ROADMAP.md` defines 5 sequential phases and preserves linked-version sibling-package release constraints.
- Phase 119 scope: baseline first; no workflow or test behavior changes before the audit and classification artifact.
- Phase 120 scope: workflow topology, cache hygiene, required-check semantics, release gate, and supply-chain posture.
- Phase 121 scope: Mix/ExUnit performance and test value cleanup, with async/partitioning only after evidence.
- Phase 122 scope: browser, demo, integration, Playwright, and generated-evidence determinism.
- Phase 123 scope: contributor DX, docs alignment, measured closeout, and rollback notes.
- Active constraints: no product runtime APIs, schemas, release workflow trust reduction, admin standalone publish prep, broad pixel baselines, or cosmetic speedups that hide risk.
- Baseline inherited from v1.17: design-system evidence guard, admin foundations guard, brand/token/logo/contrast guard chain, UI matrix/workflow Playwright evidence, core/admin/demo tests, and passed v1.17 milestone audit.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
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
