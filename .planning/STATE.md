---
gsd_state_version: 1.0
milestone: v1.16
milestone_name: Brand-Faithful UI Iteration
status: executing
last_updated: "2026-06-12T21:50:21.447Z"
last_activity: 2026-06-12 -- Phase 112.1 planning complete
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 8
  completed_plans: 6
  percent: 75
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-12)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Current focus:** v1.16 gap closure — Phase 112.1 dynamic FleetDesk launcher URL and evidence

**Milestone:** v1.16 Brand-Faithful UI Iteration shipped 2026-06-12 — see `.planning/ROADMAP.md` for phase structure

**Previous milestone:** v1.15 Identity Tournament shipped 2026-06-12 — see `.planning/milestones/v1.15-ROADMAP.md`

**Assessment:** `.planning/threads/2026-05-28-post-v1.11-milestone-next-step-assessment.md` (done band 93–95%)

## Current Position

Phase: 112.1
Plan: not planned
Status: Ready to execute
Last activity: 2026-06-12 -- Phase 112.1 planning complete

## Phase Dependency Map

```
107 (brand/UI audit + UI-SPEC)
  └──► 108 (fixture + guardrail alignment)
         └──► 109 (shared admin primitive pass)
                └──► 110 (admin workflow screen pass)
                       └──► 111 (demo surface alignment)
                              └──► 112 (visual evidence + closeout)
```

Strictly sequential: **107 → 108 → 109 → 110 → 111 → 112**

Human checkpoints:

- None currently required. FleetDesk brand boundary is locked: FleetDesk remains host-branded, Rulestead-owned demo/admin chrome uses the v1.15 identity.

## Accumulated Context

### Roadmap Evolution

- Phase 112.1 inserted after Phase 112: Close gap: BUI-05/BUI-06 - dynamic FleetDesk launcher URL and evidence (URGENT)

### Decisions

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

- Decide branch topology for the still-unmerged v1.13 -> v1.16 chain before merging to `main` because main auto-publishes to Hex.
- Preserve scope boundaries in any follow-up: no public runtime APIs, schemas, component framework, admin publish prep, palette redesign, or logo redraw.
- If the parked admin-polish WIP is resumed, merge it after this branch and resolve against the Phase 105/v1.16 shell component class scheme.

## Latest Verification

Fresh v1.16 proof bars:

- Deterministic brand/token/logo guard chain: `check_synced_pair.py`, `check_brand_tokens.py`, `check_tokens_css.py`, `check_contrast.py`, `check_brandbook_html.py`, `check_logo_assets.py`.
- Frontend fixture/file evidence: `brandbook.spec.ts`, `design-system.spec.ts`, `theme-cascade.spec.ts`, `theme-control.spec.ts`, `theme-scope.spec.ts`.
- Full compose/browser proof: `scripts/demo/verify.sh` including smoke health and browser suite.
- Core package proof: `cd rulestead && mix test`.
- Admin package proof: `cd rulestead_admin && mix test`.
- Demo backend proof: `cd examples/demo/backend && mix test --max-cases 1`.

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
