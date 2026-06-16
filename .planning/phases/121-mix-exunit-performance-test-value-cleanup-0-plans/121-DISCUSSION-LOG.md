# Phase 121: Mix/ExUnit Performance + Test Value Cleanup - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-16
**Phase:** 121-mix-exunit-performance-test-value-cleanup
**Mode:** assumptions
**Areas analyzed:** Async marking strategy & safety methodology, Dominant slow test + sample flake, Module splitting, Test partitioning, Dialyzer/PLT, test.sh value & failure-category preservation, Before/after measurement, Compile-connected xref cycle

## Assumptions Presented

### Async marking strategy & safety methodology
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Evidence-gated allowlist flip (RepoCase AND hazard-free only); no broad sweep | Confident | test_helper.exs:12-15 (global app env + named Fake); repo_case.ex:18-28 (correct async sandbox); store_contract_case.ex:21-41 (store env mutation) |
| Small net-new-async count (0–3); known serial modules must not flip | Confident | 78 async:false → ~53 bare ExUnit.Case, ~52 app-env, ~46 Fake.Control, ~9 telemetry; oban/stale_flag_worker, analytics/batcher, webhooks/inbound_http have real hazards |

### Dominant slow test (VerifyReleasePublishTest)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Only meaningful wall-clock lever; treat by tagging not deletion | Likely (lever Confident; placement was the open call) | 119-CI-CD-AUDIT.md:153-154 (~27.95s of ~42s); verify_release_publish_test.exs:201-217, 208-210 (live System.cmd to hex.pm); test_helper.exs:1-6 opt-in precedent |
| Sample flake is network jitter, not a logic bug | Confident | focused rerun passed 20.8s (audit); pinned @published_smoke_version "0.1.4" |

### Module splitting
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No splits in Phase 121 | Confident | next-slowest module ~1.6s (119-CI-CD-AUDIT.md:154); criterion #2 bar unmet |

### Test partitioning
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reject mix test --partitions with evidence | Confident | single serial network test dominates; global Fake + single sandbox needs per-partition DB isolation; no partition config in mix.exs; 18 schedulers |

### Dialyzer / PLT
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No Dialyzer/PLT change | Confident | 120-CONTEXT.md D-06 already scoped PLT key; Dialyzer in lint lane not test path; audit D-14 / 119-CI-CD-AUDIT.md:190 |

### test.sh value & failure-category preservation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep test.sh structurally; preserve scope dispatch + microcopy; keep relocated proof reachable | Confident | scripts/ci/test.sh case dispatch + Rerun microcopy; 119-CI-CD-AUDIT.md:196-205 (all scopes keep); criterion #4 |

### Before/after measurement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse Phase 119 commands (--slowest 25 / --slowest-modules 25), with/without dominant test | Confident | 119-CI-CD-AUDIT.md:144-154 locked baseline; criterion #5 |

### Compile-connected xref cycle
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Note only, do not refactor | Confident | 119-CI-CD-AUDIT.md:157,324 (architectural evidence, not refactor request) |

## Corrections Made

No assumptions were corrected. One genuinely high-impact, reversible-hard decision was escalated to the maintainer (per project METHODOLOGY high-impact exception):

### Dominant slow test placement (D-03)
- **Question:** Where should the ~28s live-hex.pm test run — opt-in tag, keep inline + harden, or tag + add retry?
- **Maintainer decision:** **Opt-in tag (recommended).** Tag it like `install_integration` so the default suite drops ~28s, with the published-package proof preserved under the release/adopter scope (`post_ga_band_closure`). No blind retry added (D-04) — the flake is network jitter and the proof stays on the release-trust path.
- **Reason:** Fast default loop without losing the published-package installability proof; consistent with the No-Go guardrail against hiding flakes behind blind retries.

## External Research

None — the Phase 119 audit plus direct codebase inspection provided sufficient evidence for every decision.
