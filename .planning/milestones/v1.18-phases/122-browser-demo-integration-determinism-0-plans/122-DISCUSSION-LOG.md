# Phase 122: Browser/Demo/Integration Determinism - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-16
**Phase:** 122-browser-demo-integration-determinism
**Mode:** assumptions (--auto)
**Calibration:** minimal_decisive (vendor_philosophy: opinionated)
**Areas analyzed:** Playwright Determinism Config; Demo-Script Readiness/Cleanup/Failure Ergonomics; Artifact Hygiene + Low-Signal-Spec Evidence Posture

## Assumptions Presented

### Playwright Determinism Config (root-cause fix)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Fix trace/retry mismatch: `trace: 'retain-on-failure'`, `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`, explicit `reporter: [['html',{open:'never'}],['list']]`, keep `retries: 0`, no CI retries | Confident | `playwright.config.ts:10,15`; `package.json:19` (@playwright/test ^1.56.1); `119-CI-CD-AUDIT.md:~278`; web-first asserts `adoption-journeys.spec.ts:18`, `00-demo-toggle.spec.ts:9,27` |
| Do NOT add a `webServer` block; external Compose stack owns readiness; baseURL/ports stay env-driven | Confident | `playwright.config.ts:3-4,14`; `verify.sh:17,41`; `smoke.sh:25-47`; `compose-env.sh:236-264` |

### Demo-Script Readiness, Cleanup, and Failure Ergonomics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No readiness rework — `wait_for_health`/`retry_command` are legitimate polling, not flake-hiding sleeps; do not convert to fixed sleeps | Confident | `smoke.sh:25-47,42,49-64`; `proxy-smoke.sh:23-45`; cleanup traps `smoke.sh:23,89`/`verify.sh:14`/`proxy-smoke.sh:64,90`; zero `waitForTimeout` in specs |
| Fix `verify.sh` failure ergonomics: on Playwright failure print URLs, rerun command, artifact paths | Confident | `verify.sh:38-42` (subshell, no failure handler) |

### Artifact Hygiene and Low-Signal-Spec Evidence Posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Hygiene sound at source; add CI `upload-artifact` (`if: failure()`/`always()`) for `playwright-report/`+`test-results/` on `integration-placeholder` | Confident | `.gitignore` ignores both dirs; `git ls-files` zero committed artifacts; `ui-matrix.spec.ts:191,401-410`; `brand-ui-evidence.spec.ts:120`; `admin-flow-ia.spec.ts:185`; `ci.yml:188-200` (no upload step) |
| Treat ALL specs as KEEP — no concrete redundancy evidence for demotion under CIDX-05; specs role-distinct | Confident | functional-journey vs visual-evidence spec split; no overlapping assertion surface |

## Corrections Made

No corrections — all assumptions confirmed (auto mode, all Confident).

## Auto-Resolved

Not applicable — zero Unclear assumptions; no auto-defaulting required.

## External Research

None performed — `@playwright/test@^1.56.1` is pinned (`examples/demo/frontend/package.json:19`)
and `retain-on-failure`/`only-on-failure`/`html` reporter semantics are confirmed available in
that version; all findings grounded in repo files.
