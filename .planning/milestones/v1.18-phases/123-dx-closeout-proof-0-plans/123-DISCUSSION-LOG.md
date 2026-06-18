# Phase 123: DX + Closeout Proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-17
**Phase:** 123-dx-closeout-proof-0-plans
**Mode:** assumptions (+ architect-default research, per user request)
**Areas analyzed:** Closeout doc shape, MAINTAINING.md reconciliation, CI failure-triage
table, metrics provenance, final verification scope, traceability + STATE closeout

## Assumptions Presented (gsd-assumptions-analyzer)

### Closeout Doc Shape & Location
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `123-CI-CD-CLOSEOUT.md` in `123-dx-closeout-proof-0-plans/`, field-by-field CIDX-10 ledger, counterpart to 119 audit | Confident | slug convention across 119-122 dirs; `119-CI-CD-AUDIT.md:332-336` handoff; `REQUIREMENTS.md:28` |

### MAINTAINING.md Reconciliation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 120/121/122 substance already reconciled; 123 edits narrow (triage table + fast-loop naming + ~5s default posture); do not rewrite cache/branch-protection/release | Likely | `MAINTAINING.md:63-78,34-38,80-119`; `119-CI-CD-AUDIT.md:213` names `contributor.sh`; `STATE.md:68` |

### CI Failure-Triage Table
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Lives in MAINTAINING.md; eight lanes mapped to ci.yml job ids; 5-slot microcopy contract | Confident | ROADMAP criteria 1+2; `ci.yml:188-189,212-213,255-256,280-281`; `119-CI-CD-AUDIT.md:249-255`; `test.sh:67-90` |

### Metrics Provenance
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Cited from prior phases not re-measured; p95 honest "not available"; cache-hit qualitative; flake notes cite 122 | Confident | `121-MEASUREMENT.md:138-154,224`; `119-CI-CD-AUDIT.md:109`; `report_cache_hit.sh:14-19`; `122-01-SUMMARY.md:39,147` |

### Final Verification Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Run runnable local gates (local.sh, mix ci, scope proofs, doc-drift guards); cite CI timing/gh-api/publish as not re-runnable | Likely | `local.sh:36-58`; `MAINTAINING.md:80-106`; `test.sh:160,533` grep release_contract_test; `STATE.md:73` |

### Traceability + STATE Closeout Mechanics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Flip CIDX-08/CIDX-10 → Complete in both tables; mark phase complete; correct STATE (4→5, 80→100, fix "Phase 122 final") | Confident | `REQUIREMENTS.md:63,65`; `ROADMAP.md:160,162,17,147`; `STATE.md:11-14,37,43-50` |

## Architect-Default Research (4 parallel gsd-advisor-researcher streams)

User requested one-shot expert recommendations with pros/cons/tradeoffs, Elixir/ecosystem
idioms, lessons from successful libs/apps, DX emphasis, prompts-subdir grounding, and a
coherent recommendation set. Four research streams run; findings refined the assumptions into
the locked decisions D-01–D-20.

### A — Closeout impact-report design
- Recommendation: **ledger-mirror** of 119 audit with `[VERIFIED]/[CITED]/[ASSUMED]` tags;
  **cite prior numbers, do not re-measure** (121 already re-ran exact 119 commands);
  per-decision git-revert-granular rollback table with cache-key-bump notes.
- Idiom: Oban changelog ("both endpoints + corpus + factor"), but add the methodology/caveat
  line Oban omits. p95 and cache-rate shown as honest gaps, never fabricated.
- Sources: Oban Pro changelog; Splunk CI/CD monitoring; Semaphore CI build performance.

### B — Contributor command surface (MAINTAINING.md)
- Recommendation: **Option A** — `mix ci` = canonical fast loop (already a thin delegate to
  `contributor.sh`, zero behavioral change), `scripts/ci/local.sh` (+`--fast`) = full gate;
  document fast→full→rerun ladder; reconcile `119-CI-CD-AUDIT.md:213` to name `mix ci`.
- Idiom: `mix` is the least-surprising Elixir entrypoint (ex_check `mix check`, Oban
  `mix test.ci`); scripts-first correct for multi-package full gate. DNA precedent
  `engineering-dna:175`. Footgun: same job under two literal command strings (current drift).
- Guard: run `release_contract_test.exs` + `post_ga_band_contract_test.exs` after edit —
  they pin scope-wrapper strings + `mix verify.adopter`, NOT `mix ci`/`contributor.sh`, so
  Option A edits are contract-safe.
- Sources: ex_check `mix check`; Oban `mix test.ci`.

### C — CI failure-triage table UX
- Recommendation: **Option A** — single 6-column table (`Lane | What failed | Boundary |
  Exact rerun | Likely remediation | When to stop`) mirroring the locked 5-slot contract;
  **pipeline order** (release lanes last); microcopy lifted **verbatim** from `test.sh`
  guidance functions; lead rows with immutable ci.yml job id; add anti-drift guard.
- Idiom: Google SRE structured playbook entries; counter the documented blind-rerun
  anti-pattern (~16% silent reruns); tone imperative/boundary-anchored, not preachy.
- Sources: Google SRE Book/Workbook; Emmer runbook template; arXiv 2509.14347 build-reruns;
  Datadog CI failure analysis.

### D — Closeout verification posture
- Recommendation: **Option B** — lint.sh + **explicit** `mix test
  test/rulestead/release_contract_test.exs` + `mix verify.adopter` (if adopter guide
  changed). Critical catch: **lint.sh does NOT run the doc-drift test**; the support-truth
  asserts live in `mix test`, so lint-only would falsely claim "verified."
- Cite-as-not-runnable: `publish-hex`, `verify-published-release`, live `gh api`
  branch-protection, CI matrix timing — honest non-execution, never silent skip
  (mirrors `122-VERIFICATION.md:89-91`). Run `prepare_rulestead_test_db` only if a focused
  run reports a DB error (asserts are file-content asserts, `release_contract_test.exs:9-14`).
- Sources: rel-eng prompt paths-ignore/push-main (78-85); 119 No-Go guardrails (286-309).

## Corrections Made

No corrections — the user did not reject any assumption. Instead the user requested deep
research across all areas; the four research streams confirmed every assumption and sharpened
them into the locked decisions D-01–D-20 (notably: D-03 cite-don't-re-measure, D-05 honest
p95/cache gaps, D-07 `mix ci` canonical with zero behavioral change, D-14 anti-drift guard,
D-15 mandatory explicit doc-drift test run).

## External Research

- A: Oban Pro changelog; Splunk; Semaphore (impact-report rigor + honest-gap posture).
- B: ex_check `mix check`; Oban `mix test.ci` (Elixir `mix`-front-door idiom).
- C: Google SRE Book/Workbook; Emmer runbook template; arXiv 2509.14347; Datadog (triage UX).
- D: repo prompts + 119/122 artifacts (verification posture; no external web needed).
</content>
