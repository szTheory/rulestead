# Phase 13: Operational Carryover Closure and Milestone Verification - Research

**Researched:** 2024-05-24
**Domain:** Operational Verification & Milestone Auditing
**Confidence:** HIGH

## Summary

This phase closes the gaps carried over from `v0.1.0` to `v0.2.0`, primarily fixing the Phase 7 sibling-package simulation helper verification gap, executing the `0.1.0` Hex publish verification (or noting its blockage if Hex API remains 404), and closing the final milestone tracking docs for v0.2.0 operational flow. 

**Primary recommendation:** Apply the actor metadata (`@admin_actor`) to the remaining `SaveDraftRuleset` and `PublishRuleset` commands in the `simulate_test.exs` and `simulate_accessibility_test.exs` files, handle the Hex verification workflow, and write the final script `scripts/ci/verify_phase13_operational.sh` patterned after `verify_phase09_governance.sh`.

## User Constraints (from CONTEXT.md / requirements)

### Locked Decisions
- `OPS-01`: Close the remaining `v0.1.0` Phase 7 sibling-package verification gap from the real `rulestead_admin` entrypoint.
- `OPS-02`: Capture live evidence for `0.1.0` as soon as both packages are visible on Hex. (Currently Hex API returns 404 for `rulestead`).
- `OPS-03`: Release follow-through for the carryover items does not weaken the linked-version, two-package release workflow.

## Standard Stack
- `mix test` for running the verification gaps.
- `jq`, `curl`, and bash scripts for live evidence capture.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Simulation helper verification gap | Found target test files: `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs` and `simulate_accessibility_test.exs` where `SaveDraftRuleset.new` is missing the `actor:` keyword list injection. |
| OPS-02 | Hex publish visibility | Script `scripts/ci/verify_published_release.sh 0.1.0` returns a 404 currently, confirming the blockage. Action: provide a fallback/staging task to acknowledge this or verify the actual release. |
| OPS-03 | Governance flow doc/release closure | Create `scripts/ci/verify_phase13_operational.sh` applying the script pattern from `13-PATTERNS.md` to trigger the tests. |

## Code Examples

### Actor-Aware Seeding Fix

Update `SaveDraftRuleset.new/3` and `PublishRuleset.new/2` to include the actor context in test files like `simulate_test.exs` and `show_test.exs`:
```elixir
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
                 actor: @admin_actor
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, actor: @admin_actor)
             )
```

## Open Questions (RESOLVED)

1. **Hex Publication Visibility**
   - What we know: Running `scripts/ci/verify_published_release.sh 0.1.0` locally returns a 404 because Hex doesn't have the package yet.
   - Recommendation: Create a task to push the package to Hex or document the staged success in `13-02` by asserting the failure is expected as per `verify-published-release.yml`'s handling of `404`.
   - RESOLVED: Addressed in 13-02-PLAN.md.