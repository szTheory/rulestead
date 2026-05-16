# Feature Landscape

**Domain:** Feature Management Platform (SaaS)
**Researched:** 2026-05-14

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| OpenFeature Provider | Adopters want to avoid vendor lock-in. | Low | Elixir SDK exists, we just implement the `OpenFeature.Provider` behavior. |
| Stale Flag Detection | Flags left in code cause technical debt and bugs. | Medium | Rulestead already tracks lifecycle; we need UI/webhook alerts when flags pass expiration. |
| Code References | Operators need to know *where* a flag is used before removing it. | High | Requires GitHub Action to scan repo and push metadata to Rulestead via API. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Automated Cleanup PRs | AI or AST-driven removal of stale flags directly via GitHub PRs. | High | LaunchDarkly has a Copilot agent for this. We could use Elixir AST (`sourceror`) to do this reliably for Elixir hosts. |
| OpenFeature + Explainability | Exposing Rulestead's best-in-class "why did this match" traces through OpenFeature metadata. | Medium | The OpenFeature spec supports custom `reason` and metadata mapping. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Built-in Statistical A/B Engine | Extremely complex, often wrong, and distracts from core ops focus. | Provide `impression` telemetry events and webhooks to pipe data to PostHog/Mixpanel. |
| Mandatory Redis | Adds infrastructure burden to self-hosted users. | Rely on the existing Ecto + ETS snapshot polling architecture. |

## Feature Dependencies

```text
Stale Flag Detection → Code References (Requires knowing where it is)
Code References → Automated Cleanup PRs (Requires knowing it is safe to remove)
```

## MVP Recommendation (v0.3.0)

Prioritize:
1. `open_feature_rulestead` Elixir provider.
2. GitHub Action for scanning codebase for Rulestead flag keys (Code References).
3. Admin UI surfaces to display Code References and highlight Stale flags.

Defer: Advanced Analytics/Experimentation engine.

## Sources

- LaunchDarkly GitHub Action docs.
- Unleash technical debt management docs.