# Phase 64 Maintainer Handoff Checklist

Use before tagging or publishing a v1.8 release that includes guarded rollout auto-advance.

## Proof bars

- [ ] `cd rulestead && mix verify.phase64` green
- [ ] `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` green
- [ ] `cd rulestead && mix test test/rulestead/release_contract_test.exs` green

## Public support truth

- [ ] README Proof today has v1.8 + v1.7 + v1.6 entries
- [ ] `MAINTAINING.md` **Guarded Rollout Auto-Advance Proof** section present
- [ ] `prompts/rulestead-host-app-integration-seam.md` auto-advance subsection present
- [ ] `guides/flows/admin-ui.md` and `guides/flows/rollout.md` auto-advance sections present

## Upstream contracts (do not regress)

- [ ] Phase 61 policy + fail-closed eligibility — [61-VERIFICATION.md](../61-auto-advance-authored-contract/61-VERIFICATION.md)
- [ ] Phase 62 orchestration + governed execution — [62-VERIFICATION.md](../62-orchestration-and-governed-execution/62-VERIFICATION.md)
- [ ] Phase 63 mounted workflows — [63-VERIFICATION.md](../63-mounted-auto-advance-workflows/63-VERIFICATION.md)

## Explicit non-claims (spot-check)

- [ ] No Rulestead-owned metrics ingestion or fleet dashboards in public docs
- [ ] No time-based percentage rollout as first-class semantics
- [ ] `guarded_rollout_foundations` CI scope unchanged (auto-advance proof is separate scope)
