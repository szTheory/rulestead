# Architecture Patterns

**Domain:** Feature Management Platform (SaaS)
**Researched:** 2026-05-14

## Recommended Architecture

### OpenFeature Integration Pattern

Rulestead should be integrated as a **Provider** within the OpenFeature ecosystem, rather than changing its internal evaluation engine.

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `OpenFeature` (Core) | Exposes the standardized API (`OpenFeature.get_client().get_boolean_value(...)`). | `RulesteadProvider` |
| `RulesteadProvider` | Translates OpenFeature context to Rulestead context, calls `Rulestead.resolve`, and maps the result back. | `Rulestead` Core Evaluator |
| `Rulestead` | Evaluates rules deterministically based on ETS snapshots. | ETS Cache |

### Code References Pattern (The "Push" Model)

Instead of Rulestead reaching out to GitHub (which requires complex OAuth and permissions), the CI/CD pipeline pushes references to Rulestead.

1. **GitHub Action** runs on push to `main`.
2. Uses regex or AST to find `Rulestead.enabled?(:flag_key)`.
3. Pushes JSON payload (flag_key, file_path, line_number) to a new Rulestead webhook ingress endpoint (`/admin/api/code_references`).
4. Rulestead UI displays these references on the Flag Detail page.

## Patterns to Follow

### Pattern 1: Abstracted Evaluation via OpenFeature
**What:** Users do not call Rulestead directly. They call OpenFeature.
**When:** For host apps that mandate vendor-agnostic architecture.
**Example:**
```elixir
# Setup
OpenFeature.set_provider(RulesteadProvider.new())

# Usage
OpenFeature.get_client().get_boolean_value("new_checkout", false, open_feature_context)
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Rulestead polling GitHub
**What:** Making Rulestead poll the host app's GitHub repository to find code references.
**Why bad:** Huge security/permission footprint. Self-hosted Rulestead instances might not have outbound internet access.
**Instead:** Rely on a GitHub Action that pushes data *inward* to Rulestead via a secure webhook.

## Sources

- OpenFeature CNCF Specification
- LaunchDarkly code-references action architecture