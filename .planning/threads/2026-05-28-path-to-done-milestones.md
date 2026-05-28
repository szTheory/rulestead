# Thread: Path to Done — Milestone Sequence

## Status

- **Active** — canonical ordering after 2026-05-28 milestone next-step assessment
- Supersedes ad-hoc “what next?” guidance in closed assessment threads

## Done band

**91–94%** for stated post-GA scope (near-done). Feature band v1.1–v1.9 is complete in code; v1.10.0 closed support-truth band (`band_complete`).

## Milestone sequence

| Order | Milestone | Type | Phases (from 73) | Exit criteria |
|-------|-----------|------|------------------|---------------|
| 1 | **v1.10.1 — Support-truth & contract honesty** | Patch | 2–3 | `mix verify.adopter` green; release_contract + post_ga guards; INV-API-01/INV-MAINT-01 resolved or scoped; stale proof threads closed |
| 2 | **v1.10.2 / v1.11 — Integration spine (docs)** | Docs only | 2–4 | First-hour Phoenix path (supervision → config → Plug → first flag with lifecycle fields); `evaluation.md` names `Rulestead.Runtime`; intro lifecycle callout |
| 3 | **v2.0 — GOV-02-ext** | Feature (triggered) | ~4 | Named/configurable blast-radius threshold profiles; config + tests + mounted UX; reference-count only |
| 4 | **v2.1 — ROL-08** | Feature (triggered) | ~4 | Host baseline comparison seam for guarded rollouts; fail-closed |
| 5 | **v2.2 — ADM-06** | Feature (triggered) | 3–4 | Draft-only targeting presets; no live inheritance |
| — | **Stop / maintenance** | — | — | No v2 triggers + v1.10.x shipped → patches and adopter support only |

**v2 default wedge order when multiple triggers fire:** GOV-02-ext → ROL-08 → ADM-06 (see `.planning/DEFERRED.md`).

**Do not open v2.0.0** without a real deferred trigger. **Run `/gsd-new-milestone`** for v1.10.1 when ready to plan phases 73+.

## Open investigations (carried)

| ID | Topic | Target milestone |
|----|-------|------------------|
| INV-API-01 | `api_stability.md` vs `release_contract_test` | v1.10.1 (sync or generate-from-contract) |
| INV-MAINT-01 | MAINTAINING Phase 8 deferral vs existing `api_stability.md` | v1.10.1 |
| INV-INTRO-01 | Intro spine missing Plug/supervision/lifecycle | v1.10.2 / v1.11 |
| INV-CTX-01 | Quickstart `traits:` vs `attributes:` | **Closed** (code + docs) |

## Graduation candidates

- Generate or diff-check `guides/api_stability.md` from `release_contract_test` closed export lists
- Release-contract or doc test: intro guides mention required `owner` + `expected_expiration` on flag create
- Formal `Rulestead.Runtime` stability stance in api_stability or product-boundary (supported adopter path vs semver-locked module list)
- Hex `@version` vs milestone label narrative (`rulestead/mix.exs` still `0.1.0`)

## Proof spine

- Adopter smoke: `cd rulestead && mix verify.adopter`
- Band closure: `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
- Mounted companion: `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` (re-verified 2026-05-28: 37 tests, 0 failures)

## Sources

- Milestone Next-Step Assessment plan (2026-05-28)
- `.planning/threads/2026-05-28-milestone-next-step-assessment.md` (closed)
- `.planning/milestones/v1.10.0-MILESTONE-AUDIT.md`
