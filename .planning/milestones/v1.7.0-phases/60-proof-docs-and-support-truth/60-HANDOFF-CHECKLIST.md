# Phase 60 Maintainer Handoff Checklist

- [ ] `cd rulestead && mix verify.phase60` green
- [ ] `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh` green
- [ ] `cd rulestead && mix test test/rulestead/release_contract_test.exs` green
- [ ] README Proof today has v1.7 blast radius governance + v1.6 `verify.phase56` entries
- [ ] `MAINTAINING.md` has `## Blast Radius Governance Proof` section
- [ ] Upstream phase artifacts referenced (57, 58, 59 CONTEXT + VERIFICATION)
- [ ] `guides/introduction/getting-started.md` teaches payload-first `Rulestead.evaluate/3`
- [ ] Linked-version sibling-package release model unchanged in touched docs
