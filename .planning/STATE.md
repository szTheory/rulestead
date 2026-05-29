---
gsd_state_version: 1.0
milestone: v1.12
milestone_name: Adoption Evidence Depth
status: milestone complete
last_updated: "2026-05-29"
last_activity: 2026-05-29 — v1.12 Adoption Evidence Depth shipped (Phases 82–86)
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 5
  completed_plans: 5
  percent: 100
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Current focus:** Maintenance default — planning next milestone only when a v2 trigger fires

**Milestone:** v1.12 Adoption Evidence Depth shipped (2026-05-29) — see `.planning/milestones/v1.12-MILESTONE-AUDIT.md`

**Assessment:** `.planning/threads/2026-05-28-post-v1.11-milestone-next-step-assessment.md` (done band 93–95%)

## Current Position

Phase: —
Plan: —
Status: v1.12 milestone complete
Last activity: 2026-05-29 — adoption-lab docs, Playwright admin depth, install journey, FleetDesk seeds, `mix verify.phase82`

## Accumulated Context

### Decisions

- **Hex release:** `rulestead` + `rulestead_admin` **0.1.3** live (2026-05-28). Post-publish verify trio green.
- **Handoff thread:** `.planning/threads/2026-05-28-post-0.1.2-maintenance-handoff.md` — read after context clear.
- **Path-to-done: complete** (v1.10.1 + v1.11 + v1.11.1 gap closure + v1.12 adoption evidence shipped).
- **Done band (repo-verified):** 93–95% for stated post-GA scope — near-done; diminishing returns on major milestones.
- **Default next work:** maintenance (patches, adopter support); do not open v2 without a real trigger.
- **CI hygiene:** Mix + Dialyzer PLT caches; PLTs gitignored; `release-pr-ci` dispatch fixed; `gate-ci-green` polls for merge CI.
- **Ecto 3.14:** Coordinated `ecto_sql ~> 3.14` bump shipped (maintenance); Decimal 3.x via transitive lock.
- Open v2.0.0 **only** with a deferred trigger; default wedge order GOV-02-ext → ROL-08 → ADM-06.
- **Current adopter bar:** `mix verify.phase82` / `mix verify.adopter` (delegates to phase82).
- Phase numbering continues at **87** if a new milestone opens.

### Deferred Items (v2)

| Category | Item | Trigger |
|----------|------|---------|
| Governance | GOV-02-ext threshold profiles | Per-env/tenant thresholds needed |
| Rollouts | ROL-08 baseline comparison | Host baselines for guarded rollouts |
| Admin | ADM-06 draft presets | High authoring duplication pain |

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

- **Resume after context clear:** read `.planning/threads/2026-05-28-post-0.1.2-maintenance-handoff.md`.
- **Default:** maintenance — adopter issues, patch releases via release-please, keep `mix verify.adopter` green.
- **After each Hex cut:** `bash scripts/ci/verify_published_release.sh <version>`.
- **Optional:** `/gsd-audit-milestone` to archive v1.12 formally.
- **Triggered only:** `/gsd-new-milestone` for v2.0+ when a deferred trigger is real (see `.planning/DEFERRED.md`).
