---
gsd_state_version: 1.0
milestone: v1.13
milestone_name: Admin UI Dark Mode + Design-System Polish
status: Awaiting next milestone
last_updated: "2026-06-04T15:29:30.532Z"
last_activity: 2026-06-04 — Milestone v1.13 completed and archived
progress:
  total_phases: 8
  completed_phases: 8
  total_plans: 14
  completed_plans: 14
  percent: 100
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-04)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Current focus:** Maintenance default — v1.13 shipped (Admin UI dark mode + design-system polish); next milestone on trigger

**Milestone:** v1.13 opened 2026-06-04 — see `.planning/ROADMAP.md` for phase structure

**Previous milestone:** v1.12 Adoption Evidence Depth shipped (2026-05-29) — see `.planning/milestones/v1.12-MILESTONE-AUDIT.md`

**Assessment:** `.planning/threads/2026-05-28-post-v1.11-milestone-next-step-assessment.md` (done band 93–95%)

## Current Position

Phase: Milestone v1.13 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-04 — Milestone v1.13 completed and archived

## Phase Dependency Map

```
87 (token foundation) ──► 88 (hardcoded-color remediation)   ──► 91 (design-system consolidation) ──► 92 (IA/home)
                      ──► 89 (focus/interaction unification)  ──┘                                  ──► 93 (per-screen polish) ──► 94 (micro-animation)
                      ──► 90 (tri-state control + FOUC)                                            89 also feeds 94
```

Strict spine: **87 → 91 → 93 → 94**
Parallel after 87: 88 ‖ 89 ‖ 90
92 after 91, can overlap start of 93

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
- Phase numbering continues at **95** if a new milestone opens.
- [Phase ?]: 87-01: Theme specs use file:// harness navigation (no Phoenix required). wcagRatio inline TypeScript, no external dep.
- [Phase ?]: Phase 88: --rs-primary-ring gap token added to all 4 cascade blocks; 18 hardcoded rgba() literals replaced; warning-flash amber border fixed
- [Phase ?]: Token-contract docs in CSS THEME LAYER comment; guide links to CSS (DRY)
- [Phase ?]: Use semibold + hairline --rs-border-subtle separator for overview rail link; suppress on mobile
- [Phase ?]: Swap .rs-attention-empty background to --rs-surface-muted for calm raised card in dark mode
- [Phase ?]: Darkened --rs-accent from #c45c26 to #9a3f12 in light Blocks 1+4; normal AA gate restored; dark accent unchanged

### Deferred Items (v2)

| Category | Item | Trigger |
|----------|------|---------|
| Governance | GOV-02-ext threshold profiles | Per-env/tenant thresholds needed |
| Rollouts | ROL-08 baseline comparison | Host baselines for guarded rollouts |
| Admin | ADM-06 draft presets | High authoring duplication pain |
| Theme | THM-07 per-host branding overrides | Host-supplied token palette |
| Accessibility | A11Y-04 forced-colors / high-contrast mode | v1.13 delivers AA in light+dark only |
| Motion | MOT-03 richer view-transition choreography | LiveView morph + View Transitions API |

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

- Start the next milestone with /gsd-new-milestone

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
