# Phase 28: E2E Demo Environments & GA Release - Context

## Objective
Provide a frictionless, one-command (`docker-compose up`) local demonstration of the entire Rulestead stack, proving cross-stack evaluation capabilities and readiness for GA.

## Scope
- Construct an `examples/demo` directory housing a Phoenix host backend and a Next.js frontend.
- Provide a root-level `docker-compose.yml`.
- Automate DB migrations and seed data execution on container boot.
- The `rulestead` and `rulestead_admin` core libraries are NOT modified in this phase (except possibly bug fixes discovered during demo creation). This phase strictly consumes the public APIs locked down in Phase 26.

## Decisions (Locked)

### Demo Architecture
- **D-01: Structure:** The demo code will live in `examples/demo/backend` (Phoenix) and `examples/demo/frontend` (Next.js).
- **D-02: Orchestration:** A `docker-compose.yml` file will be placed in the project root to satisfy the "under 5 minutes" and `docker-compose up` frictionlessness requirement. It will run Postgres, Redis, the Phoenix backend, and the Next.js frontend.
- **D-03: Bridging API:** The Phoenix demo backend will embed Rulestead and expose a custom `/api/flags` endpoint. The Next.js frontend will communicate with this endpoint via a standard HTTP client or an OpenFeature Web Provider, proving that Rulestead easily backs external frontends through a host's own API.
- **D-04: Auto-Seeding:** The Phoenix container's entrypoint will automatically run `ecto.setup` (migrations + seeds). The seeds will use `Rulestead.Admin` to create a Demo Project, Staging/Production environments, and a few initial feature flags so the Admin UI is populated immediately upon boot.

## Out of Scope
- Implementing an official OpenFeature Remote Evaluation Protocol (OFREP) server in the Rulestead core. The HTTP bridge remains the responsibility of the host app (the Demo Phoenix App, in this case).
- Adding new features to the core library or UI.

## Required Artifacts
- `docker-compose.yml`
- `examples/demo/backend/`
- `examples/demo/frontend/`
- Updated `README.md` referencing the demo setup instructions.