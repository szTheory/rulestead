---
gsd_state_version: 1.0
milestone: v1.14
milestone_name: Brand System Realization
status: verifying
last_updated: "2026-06-05T18:48:17.546Z"
last_activity: 2026-06-05
progress:
  total_phases: 7
  completed_phases: 3
  total_plans: 12
  completed_plans: 12
  percent: 43
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-04)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Current focus:** Phase 98 — admin re-skin (CSS cascade) — next up after Phase 97 complete

**Milestone:** v1.14 opened 2026-06-04 — see `.planning/ROADMAP.md` for phase structure

**Previous milestone:** v1.13 Admin UI dark mode + design-system polish shipped 2026-06-04 — see `.planning/milestones/v1.13-MILESTONE-AUDIT.md`

**Assessment:** `.planning/threads/2026-05-28-post-v1.11-milestone-next-step-assessment.md` (done band 93–95%)

## Current Position

Phase: 97 (logo-mark-svg-system) — COMPLETE
Plan: 4 of 4 complete
Status: Phase complete — ready for verification
Last activity: 2026-06-05

Progress bar: `[ ####░░░░░░ ] 43% — 3/7 phases` (Phase 101 — HTML brand book — appended as v1.14 capstone, queued after 98–100)

## Phase Dependency Map

```
95 (audit + palette reconciliation — GATE ZERO)
  └──► 96 (tokens + brandbook/ scaffold)
         └──► 98 (admin re-skin) ──► 99 (specimens) ──► 100 (copy + repo)
  └──► 97 (logo/mark SVG system) ──► 98 (confirms final hex)
         └──► 99 (specimens use final marks)
```

Strict spine: **95 → 96 → 98 → 99 → 100**
Phase 97 can overlap Phase 96 (logo design needs only Phase 95 palette, not committed tokens); Phase 97 must complete before Phase 98 closes.
Phase 100 is last — all prior artifacts must be committed for CI end-to-end confirmation.

Human checkpoints (cannot be automated):

- Phase 95 close: maintainer accepts each AA-adjusted hex as brand-compatible
- Phase 97 mid: maintainer selects logo concept A, B, or C before full lockup is produced

## Accumulated Context

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
- Phase numbering continues at **101** if a new milestone opens.
- [Phase 97-02]: Selected mark: **G4c** — multivariate decision branch, lit route (Stead Blue structure/input/off-arms, Ember Copper active top route, Quarry off-nodes). Gate pre-resolved in 97-CONCEPT-REVIEW.md.
- [Phase 97-02]: Wordmark letterforms: geometric hand-authored outline paths (fontTools Pattern 6 fallback — Google Fonts CDN unreachable in exec env; script committed for future use).
- [Phase 97-02]: Mono mark treatment: G4f — active node filled, off nodes hollow-stroked, so active-vs-off survives in `fill="currentColor"` contexts.
- [Phase 97-02]: 7-file lockup set committed to `brandbook/assets/logo/` — all < 20KB, zero text elements, zero raster, accessible (title+desc+role=img).
- [Phase 97-03]: rs-mark.svg + rs-mark-dark.svg committed to `rulestead_admin/priv/static/images/` (LOGO-04 done); phoenix-flame (FD4F00) retired from demo logo (LOGO-05 done).
- [Phase 97-03]: New demo logo fingerprint: `2d303e8acdf20eb43468b22535dfba4e` (replaced `06a11be1f2cdde2c851763d00bdd2e80`); cache_manifest.json gitignored in demo backend — not committed but verified regenerated.
- [Phase 97-03]: Orchestrator visual confirmation passed — new mark renders at 36px in demo header on light+dark; favicon legible at 16px.
- [Phase 97-04]: Phase 97 complete 2026-06-05. Full Nyquist sweep passed (13/13 assertions green). Selected mark G4c (multivariate decision branch). 7-SVG lockup set in brandbook/assets/logo/. Admin copies in rulestead_admin/priv/static/images/. Phoenix-flame demo logo retired; new fingerprint `2d303e8acdf20eb43468b22535dfba4e`. LOGO-01..05 done.
- [Phase 87-01]: Theme specs use file:// harness navigation (no Phoenix required). wcagRatio inline TypeScript, no external dep.
- [Phase 88]: --rs-primary-ring gap token added to all 4 cascade blocks; 18 hardcoded rgba() literals replaced; warning-flash amber border fixed
- [Phase ?]: Token-contract docs in CSS THEME LAYER comment; guide links to CSS (DRY)
- [Phase ?]: Use semibold + hairline --rs-border-subtle separator for overview rail link; suppress on mobile
- [Phase ?]: Swap .rs-attention-empty background to --rs-surface-muted for calm raised card in dark mode
- [Phase ?]: Darkened --rs-accent from #c45c26 to #9a3f12 in light Blocks 1+4; normal AA gate restored; dark accent unchanged
- [Phase ?]: Canonical light-surface hex per role = Stone-Mist-passing value (trivially passes all three light surfaces)
- [Phase ?]: Gap 2 resolution (Success/Danger on Stone Mist) escalated to D-11 maintainer gate
- [Phase ?]: Dark shipped generics (#4ade80 #fbbf24 #f87171) documented as non-mineral; Phase 98 replaces with mineral equivalents
- [Phase 95-03]: Brand-book pressure-test audit complete: 17 KEEP, 8 TIGHTEN, 1 REWORK (§12 color system), 3 ADD, 0 REMOVE across 27 sections
- [Phase 95-03]: §12 REWORK (primary blocker for Phase 96): replace book-literal hexes with AA-verified values from 95-PALETTE-RECONCILIATION.md
- [Phase 95-03]: ADD-2 BRD-03 szTheory suite note scoped to Phase 100; content outline provided in 95-BRAND-AUDIT.md
- [Phase 95-03]: §8 tagline lock target: "Runtime decisions, made clear." — Phase 96 action
- [Phase 96-01]: DTCG 2025.10 tokens.json committed with 37-light/31-dark admin_css_mapping; 7 primary mismatch tokens (#3A6F8F vs #2563eb, #9b5931 vs #9a3f12, #2d7753 vs #15803d, #8f601a vs #b45309, #B44949 vs #b91c1c) guarantee check_brand_tokens.py exits 1 against current CSS
- [Phase 96-01]: tokens.css reference mirror committed with :root invariant block + two-block light/dark + Tailwind excerpt; no color token on :root (D-05)
- [Phase 96-01]: --rs-primary-hover interim target #2d5f7c (darkened Stead Blue); Phase 98 may refine the hover shade
- [Phase 96]: [Phase 96-03]: check_brand_tokens.py exits 1 by design against un-re-skinned CSS — Phase 96 success criterion 3 — proves the guard mechanism works before Phase 98 re-skins the admin CSS
- [Phase 96]: brandbook/ scaffold committed — tokens.json (DTCG 2025.10), tokens.css (--rs-* mirror), check_brand_tokens.py (exits 1 intentionally against generic CSS), lint.sh extended additively
- [Phase 96]: brand-book.md relocated from prompts/ via git mv; §12 hexes reconciled to AA-verified canonicals; Gap-2 per-surface notes added for Success/Danger on Stone Mist
- [Phase 96]: check_synced_pair.py wired into lint.sh (was dev-only; now CI guard)

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
| INV-CTX-01 | Quickstart `traits:` vs `attributes:` | **Closed** | Phase 73 |
| INV-API-01 | `api_stability.md` vs release contract | **Closed** | Phase 74–75 |
| INV-MAINT-01 | MAINTAINING vs `api_stability.md` | **Closed** | Phase 73 |
| INV-INTRO-01 | Intro spine missing Plug/supervision/lifecycle | **Closed** | Phase 78 |

## Operator Next Steps

- Start Phase 98 with `/gsd:plan-phase 98` (Admin Re-skin — colors-only CSS cascade edit)
- Note: Phase 96 check_brand_tokens.py intentionally exits 1 until Phase 98 re-skins rulestead_admin.css
- Note: lint.sh has a pre-existing CWD bug (check_synced_pair.py relative path fails after `cd rulestead/`) — fix before Phase 98 closes

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
