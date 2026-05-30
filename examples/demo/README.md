# FleetDesk Adoption Lab

> **Evaluating Rulestead?** Start with the persona-oriented runbook:
> [Adoption Lab](../../guides/introduction/adoption-lab.md) (**At a glance** and
> **Quick start** at the top).
>
> **Maintaining the demo?** This file is the implementation reference (seeds,
> compose, Playwright, CI).

This directory contains the Rulestead **adoption lab** — a realistic-but-minimal B2B fleet-ops host app that exercises Rulestead across the main adopter journeys.

**Domain:** FleetDesk helps logistics teams dispatch drivers, monitor routes, and respond to operations alerts.

**Stack:**

- `backend/` — Phoenix host embedding `rulestead` + mounted `rulestead_admin`
- `frontend/` — external Next.js app consuming flags through a custom OpenFeature web provider

This is the primary runnable end-to-end proof path for the current `0.1.4` Hex package line.

## What this proves

| Journey | Persona | Flag(s) | Proof |
|---------|---------|---------|-------|
| Install + evaluate | Alex (app dev) | all flags via `/api/flags` | Compose boot + smoke |
| Targeted rollout | Tova (tech lead) | `fleet-map-v2` | Enterprise persona → map v2 on |
| Experiment copy | Priya (operator) | `dispatch-ops-copy` | Seeded headline variant |
| Remote config | Priya (operator) | `ops-banner-config` | Storm advisory banner |
| Explain decision | Sam (support) | `enable-new-dashboard` | `/api/flags/explain` trace |
| Kill switch | Shiori (SRE) | `enable-new-dashboard` | Admin kill → frontend flips |
| Guarded rollout | Tova / Shiori | `dispatch-guarded-rollout` | Rollout panel + guardrail copy |
| Audience preview | Tova / Priya | `ops-audience-preview` | Host resolver stub + impact preview |

## Seeded fixtures

After `mix run priv/repo/seeds.exs` (also run by compose entrypoint):

- **Personas:** dispatch operator (pro), fleet manager (enterprise), beta dispatcher (starter)
- **Flags:** `enable-new-dashboard`, `fleet-map-v2`, `dispatch-ops-copy`, `ops-banner-config`, `dispatch-guarded-rollout`, `ops-audience-preview`
- **Environments:** staging + production

Persona metadata: `GET /api/demo/personas`

## One-command boot

From the repo root:

```bash
docker compose up --build
```

Services:

- Admin + backend: `http://localhost:4000`
- Deterministic sign-in: `http://localhost:4000/demo/sign-in`
- Adoption lab UI: `http://localhost:3000`
- Postgres: `localhost:5432`
- Redis: `localhost:6379`

## Click-through paths

Persona-oriented browser paths (evaluator loop, operator, support, SRE) live in
the [Adoption Lab runbook](../../guides/introduction/adoption-lab.md#persona-click-paths).

## Automation

Smoke verification:

```bash
scripts/demo/smoke.sh
```

Browser proof (kill switch + adoption journeys + admin depth):

```bash
cd examples/demo/frontend
npm install
npx playwright install chromium
DEMO_BACKEND_URL=http://127.0.0.1:4000 DEMO_FRONTEND_URL=http://127.0.0.1:3000 npm run test:e2e
```

Curated Playwright specs: `flag-inventory`, `rollout-advance`, `explain-admin`,
`audit-timeline`, `guarded-rollout`, plus `adoption-journeys` and `demo-toggle`.

Fresh-install journey (no FleetDesk UI):

```bash
scripts/demo/install_journey.sh
```

Bounded adopter proof (smoke + `mix verify.adopter`):

```bash
scripts/demo/proof.sh
```

## OpenFeature companion

If you need the package-local OpenFeature companion proof first:

```bash
RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh
```

See [Adoption Lab](../../guides/introduction/adoption-lab.md) for the evaluator
runbook; this file covers automation and CI.

## Published-release checks

This lab complements, but does not replace:

- `mix verify.release_publish <version>`
- `mix verify.release_parity <version>`
- `bash scripts/ci/verify_published_release.sh <version>`
