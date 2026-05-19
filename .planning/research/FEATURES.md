# Feature Landscape: v1.0.0 (GA)

**Domain:** Feature Management Platform (SaaS / Self-Hosted)
**Researched:** 2026-05-17

## Table Stakes (GA Requirements)

Features users expect in a 1.0 release. Missing = product feels unstable or unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| API Stability Lockdown | SemVer dictates 1.x means no breaking changes. | Medium | Requires strict auditing of public vs private modules (`@moduledoc false`). |
| Comprehensive RBAC | Enterprise teams cannot use a tool where any dev can delete production flags. | High | Needs Admin, Editor, and Viewer roles baked into the Admin UI and core API. |
| Documentation Perfection | Operators evaluate tools based on how quickly they can solve problems using docs. | Medium | Complete `ex_doc` coverage, architecture guides, and deployment recipes. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| E2E Demo Environments | Allows a Platform Engineer to evaluate the entire system (Redis, DB, UI, Client) locally in 5 minutes. | Medium | A Docker Compose stack with a sample OpenFeature client (e.g., Next.js). |
| FunWithFlags Migration Guide | Lowers the barrier to entry for the most common existing Elixir feature flag library. | Low | Simple markdown guide in hexdocs. |

## Anti-Features

Features to explicitly NOT build in v1.0.0.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| New Flag Evaluation Strategies | 1.0 is for locking down what exists. Adding new evaluation types resets the stability clock. | Defer to v1.1.0+ |
| Complex Custom Role Definitions | Letting users define arbitrary roles with granular permissions is overkill for 1.0. | Stick to static roles (Admin, Editor, Viewer). |

## Feature Dependencies

```text
API Stability Lockdown → Comprehensive RBAC (RBAC relies on stable core contexts)
Comprehensive RBAC → E2E Demo Environments (Demo should showcase roles)
```

## MVP Recommendation

Prioritize:
1. Strict `@moduledoc false` on all internals and Dialyzer 100% pass.
2. Built-in Admin/Editor/Viewer RBAC policies.
3. Docker Compose E2E Demo.

## Sources

- Rulestead `.planning/research/EPIC_ARC.md`
