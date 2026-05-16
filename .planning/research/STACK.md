# Technology Stack

**Project:** Rulestead
**Researched:** 2026-05-14

## Recommended Stack

### Core Framework (Additions for v0.3.0)
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `open_feature` (Elixir SDK) | ~> 1.0 | Standardized feature flag evaluation API | CNCF standard; prevents vendor lock-in and aligns with modern enterprise architectures. |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| GitHub Actions | v2/v3 | Stale flag detection and code reference scanning | Ecosystem standard for CI/CD. LaunchDarkly and Unleash both use Actions for code ref scanning. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sourceror` | ~> 1.0 | Elixir AST manipulation | If we decide to build an Elixir-native stale flag remover instead of relying purely on regex in GitHub Actions. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Scale Strategy | ETS + Ecto (Status Quo) | Redis + Streaming | Rulestead's current snapshot-based ETS architecture handles 95% of use cases. Redis breaks the "batteries included" philosophy and adds infrastructure overhead. |
| Analytics | Tracking Hooks | Built-in A/B Stats Engine | Building a statistically rigorous A/B testing engine (CUPED, Bayesian stats) is a massive undertaking that distracts from the core mission of operator confidence. Hooks are sufficient. |

## Installation

```bash
# To add OpenFeature support
def deps do
  [
    {:open_feature, "~> 1.0"},
    {:open_feature_rulestead, path: "../open_feature_rulestead"} # Sibling package
  ]
end
```

## Sources

- Context7 CLI lookups (OpenFeature Elixir SDK)
- LaunchDarkly and Unleash GitHub integration documentation.