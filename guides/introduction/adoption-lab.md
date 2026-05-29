# Adoption Lab

FleetDesk is Rulestead's **adoption lab** — a realistic-but-minimal B2B fleet-ops
host app you can run locally before wiring Rulestead into your own Phoenix app.

**Domain:** FleetDesk helps logistics teams dispatch drivers, monitor routes, and
respond to operations alerts.

**Stack:**

- `examples/demo/backend/` — Phoenix host embedding `rulestead` + mounted `rulestead_admin`
- `examples/demo/frontend/` — external Next.js app consuming flags through a custom OpenFeature web provider

Use this guide when you want to **see Rulestead working** with realistic data,
personas, and operator screens — not when you are ready to install into your app
(that path is [Getting Started](getting-started.md) and [Installation](installation.md)).

## Start here (30 seconds)

You want to see Rulestead working before installing into your app. From the repo
root, run `docker compose up --build`, wait until all services are healthy, then
open:

- **Host app:** `http://localhost:3000`
- **Operator admin:** `http://localhost:4000/demo/sign-in`
- **API host:** `http://localhost:4000`

The sections below walk through boot, connect, and persona-specific click paths.
For automation only, run `scripts/demo/proof.sh`.

## Who this is for

| Persona | Question | What to try in FleetDesk |
|---------|----------|--------------------------|
| App developer (Alex) | "Will this fit my Phoenix app?" | Compose boot, `/api/flags`, OpenFeature client |
| Tech lead (Tova) | "Can we roll out safely?" | Enterprise persona → `fleet-map-v2`; guarded rollout seeds |
| Operator (Priya) | "What does the admin feel like?" | Mounted admin at `/demo/sign-in`, rollout and audit screens |
| Support (Sam) | "Can we explain one user's outcome?" | Explain API panel + `/admin/flags/:key/simulate` |
| SRE (Shiori) | "Can we kill a flag at 3am?" | Kill switch on `enable-new-dashboard` |
| Evaluator (any) | "Should we adopt this?" | Run `scripts/demo/proof.sh` and click through |

The six flows in [User Flows and JTBD](user-flows-and-jtbd.md) map to concrete
demo actions — FleetDesk is the runnable version of that mental model.

## Two proof paths

Rulestead ships two complementary adopter proofs. Use both when you need maximum
confidence before integrating.

### Path A — FleetDesk (full stack, pre-installed)

Best for: evaluators, operators, and support personas who want a browser-ready
system with seeded flags, personas, and mounted admin.

#### Boot and wait

From the repo root:

```bash
docker compose up --build
```

Wait until compose shows `postgres`, `redis`, `backend`, and `frontend` as
**healthy**. First boot usually takes one to three minutes (image build + seed).

Keep this terminal open while you browse. If you run `scripts/demo/smoke.sh` on
its own, it tears the stack down when it finishes unless you set
`DEMO_SMOKE_KEEP_STACK=1`. Use `scripts/demo/proof.sh` for bounded automation
without losing a stack you are clicking through.

#### Connect

Once services are healthy, open these URLs in your browser:

| URL | You are… | What you'll see |
|-----|----------|-----------------|
| `http://localhost:3000` | Evaluating the host app | FleetDesk dispatch dashboard, persona switcher, flag cards, explain panel |
| `http://localhost:4000/demo/sign-in` | Trying operator workflows | Mounted admin (auto sign-in): inventory, rollouts, kill switch, audit |
| `http://localhost:4000` | Checking the API host | Phoenix backend home |

Optional API sanity checks (for integrators — not required for the UI demo):

```bash
curl http://localhost:4000/api/demo/personas
curl "http://localhost:4000/api/flags?env=staging&flag_key=enable-new-dashboard"
```

Postgres (`localhost:5432`) and Redis (`localhost:6379`) are exposed for
debugging but not needed to use the UI.

#### Persona click paths

Pick the path that matches your question. Each is a few minutes in the browser.

#### Evaluator — 5-minute adoption loop

1. Open `http://localhost:3000` — note the seeded banner and flag cards.
2. Switch persona to **Fleet manager** — map renderer flips to vector v2.
3. Read the **explain API** panel for the support journey trace.
4. Open `http://localhost:4000/demo/sign-in` → kill `enable-new-dashboard` on staging.
5. Return to the frontend — headline changes to **Classic dispatch map is holding steady.**

#### Operator — admin feel

1. Open `http://localhost:4000/demo/sign-in`.
2. Browse flag inventory at `/admin/flags?env=staging`.
3. Open rollouts for `fleet-map-v2` or `dispatch-guarded-rollout`.
4. Filter audit at `/admin/flags/audit`.

#### Support — explain one outcome

1. Open `http://localhost:3000` and read the explain API panel.
2. In admin, open simulate for `enable-new-dashboard` and compare the trace.

#### SRE — kill switch

1. Open `http://localhost:4000/demo/sign-in`.
2. Engage the kill switch for `enable-new-dashboard` on staging.
3. Confirm the frontend at `http://localhost:3000` flips.
4. Review the audit timeline for the kill event.

#### When something doesn't load

- Run `docker compose ps` — are all four services healthy?
- Run `scripts/demo/smoke.sh` for automated health checks (see teardown note above).
- See [examples/demo/README.md](../../examples/demo/README.md) for Playwright and CI commands.

Bounded automation (smoke + contract tests, no browser):

```bash
scripts/demo/proof.sh
```

Full automation (smoke + Playwright — same as CI integration job):

```bash
scripts/demo/verify.sh
```

**Honest boundary:** FleetDesk is a **pre-installed** host. Compose builds an image
that already ran `mix rulestead.install` and seeds. It proves host-shaped
integration, not your app's first-hour installer run.

### Path B — Fresh install journey (first-hour wiring)

Best for: Phoenix integrators validating `mix rulestead.install` → migrate →
runtime wiring in an ephemeral host app.

```bash
scripts/demo/install_journey.sh
```

This reuses the golden-diff installer contract under
`rulestead/fixtures/install_golden/` and asserts generated Phoenix wiring.
It does not boot FleetDesk or the Next.js frontend.

CI runs install-journey proof on the `install_journey` scoped lane (see
[Testing](../recipes/testing.md)). Merge-blocking CI still uses FleetDesk smoke
+ `mix verify.adopter`.

## Seeded fixtures

After `mix run priv/repo/seeds.exs` (also run by the compose entrypoint):

- **Personas:** dispatch operator (pro), fleet manager (enterprise), beta dispatcher (starter)
- **Flags:** `enable-new-dashboard`, `fleet-map-v2`, `dispatch-ops-copy`, `ops-banner-config`, `dispatch-guarded-rollout`, `ops-audience-preview`
- **Environments:** staging + production

Persona metadata: `GET /api/demo/personas`

Implementation detail lives in [examples/demo/README.md](../../examples/demo/README.md).

## Journey map

| Journey | Persona | Flag(s) | Proof |
|---------|---------|---------|-------|
| Install + evaluate | Alex | all flags via `/api/flags` | Compose boot + smoke |
| Targeted rollout | Tova | `fleet-map-v2` | Enterprise persona → map v2 on |
| Experiment copy | Priya | `dispatch-ops-copy` | Seeded headline variant |
| Remote config | Priya | `ops-banner-config` | Storm advisory banner |
| Explain decision | Sam | `enable-new-dashboard` | `/api/flags/explain` trace |
| Kill switch | Shiori | `enable-new-dashboard` | Admin kill → frontend flips |
| Guarded rollout | Tova / Shiori | `dispatch-guarded-rollout` | Rollout panel + hold path |
| Audience preview | Tova / Priya | `ops-audience-preview` | Impact preview with host resolver stub |

Post-GA governance seeds use **stub resolvers** for guardrail and preview evidence.
Sample cohorts and impression summaries are support-safe illustrations — not
authoritative population counts (GOV-05 boundary).

## Relationship to testing

- **Unit and app tests:** stay Fake-first — see [Testing](../recipes/testing.md)
- **Host-shaped integration:** FleetDesk + Playwright prove compose, admin mount, and browser glue
- **Installer contract:** `install_journey.sh` + golden-diff tests prove generated wiring
- **Library contract:** `cd rulestead && mix verify.adopter` unions post-GA band tests

Do not replace Fake-backed tests with Docker. Use the adoption lab when you need
end-to-end confidence that mirrors a real host app.

## Where to go next

- Install into your app: [Getting Started](getting-started.md)
- Operator workflows: [Admin UI](../flows/admin-ui.md)
- Support traces: [Explainability](../flows/explainability.md)
- Product mental model: [User Flows and JTBD](user-flows-and-jtbd.md)
