# Research Summary: Rulestead v0.3.0 Focus

**Domain:** Feature Management Platform (SaaS)
**Researched:** 2026-05-14
**Overall confidence:** HIGH

## Executive Summary

Rulestead has successfully established its core runtime, admin UX, and governance workflows (v0.1.0 and v0.2.0). The decision for v0.3.0 comes down to three paths: Experimentation (analytics/A/B), Advanced Delivery (Redis/streaming), or Ecosystem Integration (OpenFeature, GitHub code references for stale flags). 

Our research indicates that the "Ecosystem Integration and Lifecycle Hygiene" path is the most critical next step for a self-hosted, batteries-included Elixir platform. In 2026, feature flag technical debt is the primary complaint from operators, and platforms like LaunchDarkly and Unleash have invested heavily in automated stale-flag cleanup via GitHub integrations. Furthermore, the CNCF OpenFeature standard has gained massive traction, serving as the de facto anti-lock-in API. By focusing on OpenFeature and GitHub integration, Rulestead will cement operator trust and enterprise readiness without introducing the heavy architectural burden of an experimentation statistics engine or a mandatory Redis dependency.

## Key Findings

**Stack:** Elixir standard library + Phoenix PubSub remain sufficient; OpenFeature requires a custom Provider package (`open_feature_rulestead`); GitHub integrations require a dedicated Action/App.
**Architecture:** Abstract the evaluation through OpenFeature `Provider` semantics and leverage external CI/CD hooks for code references rather than building an AST parser in Elixir.
**Critical pitfall:** "Zombie flags" (stale flags) crippling the codebase. Building flags is easy; removing them is hard.

## Implications for Roadmap

Based on research, suggested phase structure for `v0.3.0`:

1. **Phase 14: OpenFeature Ecosystem Integration** - Implement an official `open_feature_rulestead` provider. Reduces lock-in fear for adopters and aligns with 2026 CNCF standards.
   - Addresses: Vendor lock-in, enterprise adoption blockers.
   - Avoids: Forcing host apps to use Rulestead's native API if they prefer generic abstractions.

2. **Phase 15: Lifecycle Hygiene & Code References** - Build GitHub Actions / Webhooks to detect stale flags, find code references, and automate cleanup PRs.
   - Addresses: The #1 feature flag technical debt problem.
   - Avoids: The pitfall of Rulestead becoming a graveyard of 100% rolled-out, forgotten flags.

**Phase ordering rationale:**
- OpenFeature provides the API abstraction layer first, ensuring our telemetry and context maps well to standard formats. Then, Code References provides the operational tooling to manage the flags created via those APIs.

**Research flags for phases:**
- Phase 14: Standard patterns (OpenFeature SDK exists in Elixir, just needs a provider). Unlikely to need deep research.
- Phase 15: Likely needs deeper research into GitHub App vs GitHub Action auth models and Elixir AST parsing if we want to do native codebase scanning.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | OpenFeature Hex package exists and is maintained. |
| Features | HIGH | Stale flag cleanup is universally recognized as table stakes in 2026. |
| Architecture | HIGH | Standard provider patterns are well documented by CNCF. |
| Pitfalls | HIGH | Confirmed across multiple platforms (LD, Unleash). |

## Gaps to Address

- Whether to build our own GitHub Action (TypeScript) or parse Elixir AST natively using something like `Sourceror`.
- How to map Rulestead's unique "explainability" trace into OpenFeature's generic `EvaluationDetails`.