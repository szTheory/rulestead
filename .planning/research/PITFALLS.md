# Domain Pitfalls

**Domain:** Feature Management Platform (SaaS)
**Researched:** 2026-05-14

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Zombie Flags (Technical Debt)
**What goes wrong:** Teams use flags for a 2-week rollout but leave the `if/else` logic in the codebase for 3 years. The codebase becomes a combinatorial explosion of dead logic paths.
**Why it happens:** No operational visibility into which flags are 100% rolled out and no longer needed.
**Consequences:** Massive cognitive load for developers, brittle tests, and potential outages if an old flag is accidentally flipped.
**Prevention:** Build Stale Flag Detection and Code References. Make flag retirement a first-class citizen in the Admin UI.
**Detection:** "Potentially Stale" lifecycle states in the UI; automated GitHub issues.

## Moderate Pitfalls

### Pitfall 2: OpenFeature Context Mismatch
**What goes wrong:** OpenFeature's generic `EvaluationContext` doesn't perfectly map to Rulestead's explicit context struct (`subject_key`, `tenant_key`).
**Prevention:** The `RulesteadProvider` must handle missing attributes gracefully or explicitly map OpenFeature's `targetingKey` to Rulestead's `subject_key`. Document this mapping clearly.

### Pitfall 3: Regex-based Code Scanning False Positives
**What goes wrong:** A naive GitHub Action using `grep` finds commented-out flags or unrelated string matches, cluttering the Code References UI.
**Prevention:** Provide clear documentation on how to scan accurately, and ideally provide an Elixir-specific AST scanner (via `sourceror`) that strictly identifies `Rulestead.enabled?` calls.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Code References | Flooding the Rulestead API with massive payloads on every commit. | The GitHub action should diff against the previous commit or only send Delta updates; Rulestead must rate-limit the ingress. |
| OpenFeature | Losing Rulestead's "Explainability" traces. | Serialize the trace into the `reason` or `metadata` field of the OpenFeature `EvaluationDetails` struct. |

## Sources

- LaunchDarkly's "Definition of Done" for feature flags.
- OpenFeature Evaluation API spec.