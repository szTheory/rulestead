# Phase 28: E2E Demo Environments & GA Release - Validation Plan

## Goal
Verify that Phase 28 delivers a truthful, one-command local demo of the full Rulestead stack through a thin Phoenix host app and a separate Next.js client, while preserving the sibling-package posture, the host-owned mounted-admin auth seam, and the locked `/api/flags` bridge contract.

## Dimension 1: Host-App Bootstrap and Persistence Contract (GA-01, GA-02)
- [x] **Example-app boundary only:** Demo-specific backend code lives under `examples/demo/backend`; no new `rulestead` or `rulestead_admin` product surface was introduced.
- [x] **Installer-backed persistence ownership:** The demo backend owns the `mix rulestead.install` output required for `mix ecto.setup`, including host repo/runtime config and install-generated migrations.
- [x] **Auto-seeded first boot:** `priv/repo/seeds.exs` seeds the demo environments and flag set, and the backend entrypoint runs `mix ecto.setup` automatically in the container boot path.

## Dimension 2: Host-Owned Bridge and Live-Update Contract (GA-02)
- [x] **Locked bridge routes:** The backend exposes `/api/flags` and `/api/flags/stream` exactly per D-03.
- [x] **Runtime-only evaluation path:** Bridge requests delegate through `Rulestead.Runtime` APIs rather than direct browser-facing storage reads.
- [x] **Bounded event and payload shape:** JSON and SSE responses are normalized and limited to the data required by the OpenFeature demo.
- [x] **Fail-closed input handling:** Targeted controller tests cover missing and invalid `env` / `flag_key` inputs and bounded errors.

## Dimension 3: Demo Operator Session and Mounted Admin Posture (GA-01)
- [x] **Host-owned sign-in seam:** The deterministic sign-in route is `/demo/sign-in` and is the documented automation path.
- [x] **Documented session contract:** The session path writes `"current_actor"`, `"rulestead_admin_environments"`, and `"rulestead_admin_last_env"` before redirecting into mounted admin routes.
- [x] **Phase 27 posture preserved:** Mounted admin authorization still flows through the explicit host `policy:` seam.

## Dimension 4: Frontend OpenFeature Contract and Container Readiness (GA-02)
- [x] **Example-app boundary only:** All sample-client code lives under `examples/demo/frontend`.
- [x] **OpenFeature provider proof:** The provider resolves seeded state through `/api/flags`, listens to `/api/flags/stream`, and emits configuration-change events; targeted tests pass.
- [x] **Compose-consumable build target:** The frontend Docker image is defined with the frontend app slice and consumed by root Compose.
- [x] **Visible seeded state:** The sample page renders an obvious seeded flag-driven delta.

## Dimension 5: One-Command Compose, Reachability, and Browser Proof (GA-01, GA-02)
- [x] **Four-service root graph:** `docker-compose.yml` defines Postgres, Redis, backend, and frontend together.
- [x] **Readiness gates, not sleep loops:** Healthchecks and readiness-gated dependencies control startup order.
- [x] **Frontend reachability included:** `scripts/demo/smoke.sh` includes frontend rendering checks in addition to backend/admin checks.
- [x] **End-to-end toggle loop:** Executed successfully on 2026-05-21 through the kept-alive demo stack using the Playwright browser proof.

## Dimension 6: Docs, Product Shape, and Scope Guardrails
- [x] **Honest local-demo docs:** `README.md` and `examples/demo/README.md` document the one-command path, URLs, deterministic sign-in route, and expected toggle loop.
- [x] **Sibling-package release shape preserved:** Docs still present `rulestead` and `rulestead_admin` as sibling packages and do not create a standalone `rulestead_admin` publish posture.
- [x] **No future-scope creep:** No OFREP server, direct browser storage access, or future-phase documentation promises were added.

## Session Verification Result

Targeted backend tests passed, targeted frontend tests passed, the frontend production build passed, `docker compose config` passed, the backend production asset pipeline was verified after a Dockerfile compile-order fix, `DEMO_SMOKE_KEEP_STACK=1 ./scripts/demo/smoke.sh` passed, and `cd examples/demo/frontend && npm run test:e2e` passed on 2026-05-21.

## Verification Evidence
Primary evidence should come from:

- `cd examples/demo/backend && mix deps.get && mix compile`
- `cd examples/demo/backend && mix test test/rulestead_demo_web/controllers/flag_controller_test.exs test/rulestead_demo_web/controllers/flag_stream_controller_test.exs test/rulestead_demo/demo_seed_smoke_test.exs`
- `cd examples/demo/frontend && npm test -- --runInBand rulestead-web-provider.test.ts`
- `docker compose config`
- `scripts/demo/smoke.sh`
- `cd examples/demo/frontend && npm run test:e2e`
- `rg -n "/api/flags|/api/flags/stream|/demo/sign-in|mix rulestead.install|rulestead_admin" README.md examples/demo .planning/phases/28-e2e-demo-environments-ga-release/28-0{1,2,3,4}-PLAN.md`

## Source Coverage Audit

### Goal Coverage
- [x] **ROADMAP goal:** `28-01` establishes the host backend, installer-backed bootstrap, and deterministic demo auth seam; `28-02` establishes the bridge contract plus seeded authored state; `28-03` establishes the external frontend and container contract; `28-04` proves the one-command Compose and browser loop.

### Requirement Coverage
- [x] **GA-01:** Covered by `28-01` backend bootstrap/auth seams, `28-02` seeded authored state, and `28-04` Compose, smoke, docs, and browser verification.
- [x] **GA-02:** Covered by `28-02` bridge/live-update contract, `28-03` frontend provider/app contract, and `28-04` browser proof.

### Research Coverage
- [x] **Backend-first sequencing:** Covered by the wave order `28-01` -> (`28-02`, `28-03`) -> `28-04`.
- [x] **Host-owned bridge, not OFREP:** Covered by `/api/flags` and `/api/flags/stream` in `28-02` and `28-03`.
- [x] **Compose readiness and smoke verification:** Covered by `28-04`.
- [x] **Small custom OpenFeature provider with configuration-changed events:** Covered by `28-03`.
- [x] **Resolved auth/session seam:** Covered by the deterministic demo sign-in path in `28-01` and exercised in `28-02` and `28-04`.

### Context Decision Coverage
- [x] **D-01 Structure:** Implemented by `28-01` and `28-03`, with demo code confined to `examples/demo/**`.
- [x] **D-02 Orchestration:** Implemented by `28-04` through the root four-service Compose graph.
- [x] **D-03 Bridging API:** Implemented by `28-02` and consumed by `28-03` through `/api/flags` and `/api/flags/stream`.
- [x] **D-04 Auto-Seeding:** Implemented by `28-01` install/bootstrap ownership, `28-02` seeds, and `28-04` `ecto.setup` boot automation.
