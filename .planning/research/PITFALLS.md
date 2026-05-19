# Domain Pitfalls: v1.0.0 (GA)

**Domain:** Feature Management Platform
**Researched:** 2026-05-17

## Critical Pitfalls

Mistakes that cause rewrites or major issues upon GA release.

### Pitfall 1: Leaking Internal APIs
**What goes wrong:** Developers in the host application start calling `Rulestead.Engine.evaluate_ast/2` because it's public, even though it wasn't meant to be part of the stable API.
**Why it happens:** Forgetting to add `@moduledoc false` to internal modules before tagging v1.0.0.
**Consequences:** In v1.1.0, you rewrite the engine, breaking the host application and violating SemVer expectations.
**Prevention:** Strict review of `mix docs` output. If a module shouldn't be guaranteed for 10 years, hide it.

### Pitfall 2: Dependency Conflicts in Host Apps
**What goes wrong:** Rulestead v1.0.0 requires `{:ecto, "~> 3.11.0"}` or `{:permit, "~> 1.0"}`.
**Why it happens:** Adding heavy, opinionated dependencies for features like RBAC.
**Consequences:** Users cannot install Rulestead because their app relies on an older/newer version of that dependency.
**Prevention:** Keep dependencies to the absolute bare minimum (`ecto`, `phoenix`, `jason`). Implement RBAC using standard Elixir pattern matching instead of a framework.

## Moderate Pitfalls

### Pitfall 3: "Empty Room" Demo Experience
**What goes wrong:** A user successfully installs Rulestead, opens the dashboard, and stares at a blank screen, unsure how it connects to their frontend.
**Prevention:** The E2E Demo Environment must come pre-seeded with 3-4 flags, a mock user base, and a functioning frontend (e.g., Next.js) that visibly changes when a flag is toggled in the admin UI.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| API Lockdown | Breaking changes immediately after 1.0 | Aggressive use of `@moduledoc false` for anything not strictly meant for public use. |
| RBAC | Over-engineering custom roles | Ship with static roles: Admin, Editor, Viewer. |
| Demo Environments | Flaky Docker builds | Use official, pinned image versions for Postgres/Redis in the `docker-compose.yml`. |

## Sources

- SemVer 2.0.0 Specifications
- Maintainer experiences from high-profile Elixir libraries (Oban, Absinthe).
