# Phase 28: Discussion Log

*Generated during `/gsd-discuss-phase 28` on 2026-05-20*

## Process

Following the "one-shot opinionated recommendations" protocol, this phase skips the back-and-forth interview in favor of a cohesive, idiomatic set of recommendations for the Phase 28 Demo Environment and GA Release.

## Identified Gray Areas

### 1. Host App & Next.js Communication (Cross-Stack Usage)
**Context:** GA-02 requires the demo environment to include a sample external frontend (Next.js) using the OpenFeature client. However, Rulestead is primarily an embedded Elixir library, not a standalone HTTP microservice out-of-the-box.
**The Problem:** How does the Next.js frontend get feature flag evaluations from Rulestead?
**Options:**
- A: Have Next.js talk directly to Redis (anti-pattern, leaks implementation details).
- B: Provide an official Rulestead OFREP (OpenFeature Remote Evaluation Protocol) API in core (scope creep for GA, as Rulestead is an embedded engine).
- C: Expose a simple `/api/flags` endpoint in the Demo Phoenix App that delegates to `Rulestead.Runtime.evaluate/3`, demonstrating how a host application bridges Rulestead to its own frontend.

**Recommendation (Winner: Option C):** The primary value proposition of Rulestead is that it embeds cleanly into a Phoenix host application. The Demo Phoenix App should expose a `/api/v1/flags` endpoint. The Next.js frontend can then use a standard OpenFeature Web Provider (or a simple custom one) that fetches from this endpoint. This perfectly demonstrates the "bring your own API" embeddable nature of Rulestead.

### 2. Demo Repository Structure
**Context:** We need a frictionless `docker-compose up` experience.
**The Problem:** Where do we put the demo apps without cluttering the main Rulestead library root?
**Recommendation:** Create an `examples/demo/` directory containing:
- `backend/` - A thin Phoenix host app embedding `Rulestead` and `Rulestead.Admin`, configured to serve the Admin UI at `/admin` and an evaluation endpoint at `/api/flags`.
- `frontend/` - A Next.js (App Router) client application demonstrating feature flags in action.
- A `docker-compose.yml` in the project root that builds these and spins up Postgres and Redis. (Or place it in `examples/demo/docker-compose.yml` with instructions in the root `README.md`). To meet GA-01 ("A user can run `docker-compose up` and immediately access"), we should place the `docker-compose.yml` in the project root to guarantee frictionlessness.

### 3. Immediate Value via Data Seeding
**Context:** A demo is useless if it's completely empty when booted.
**The Problem:** How do we ensure the database has flags, environments, and metrics immediately upon startup?
**Recommendation:** The `backend` Demo Phoenix App should include a robust `priv/repo/seeds.exs` file. When the backend container starts, it should run migrations and seeds automatically. The seeds must use the `Rulestead.Admin` context to programmatically create:
- A "Demo Project".
- Two Environments ("Staging" and "Production").
- 2-3 feature flags (e.g., `enable-new-dashboard`, `beta-feature`, `maintenance-mode`).
- A demo API token (if required) for the Next.js app to authenticate against the `/api/flags` endpoint.

## Conclusion
All gray areas have been resolved with these pragmatic, zero-friction choices. The decisions are locked in `28-CONTEXT.md`.