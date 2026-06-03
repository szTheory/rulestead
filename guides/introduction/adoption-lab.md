# Adoption Lab

FleetDesk is Rulestead's **adoption lab** — a realistic-but-minimal B2B fleet-ops
host app you can run locally before wiring Rulestead into your own Phoenix app.

**Domain:** FleetDesk helps logistics teams dispatch drivers, monitor routes, and
respond to operations alerts.

Use this guide when you want to **see Rulestead working** with realistic data and
operator screens — not when you are ready to install into your app (that path is
[Getting Started](getting-started.md) and [Installation](installation.md)).

## At a glance

You are running **three things**:

1. **FleetDesk** (`http://localhost:3000`) — sample customer app. Flags change what
   dispatchers see.
2. **Rulestead admin** (`http://localhost:4000/demo/sign-in`) — where operators manage
   flags, rollouts, and kill switches.
3. **Rulestead API** (`http://localhost:4000/api/...`) — what both apps talk to.

## Quick start (5 minutes)

1. From the repo root: `scripts/demo/up.sh`
2. Wait until `postgres`, `redis`, `backend`, and `frontend` are **healthy** (first boot
   usually takes one to three minutes).
3. Open **FleetDesk** at the frontend URL printed by the script → use **View as** to switch accounts →
   watch the map and dispatch headline change.
4. Open **Rulestead admin** at the admin sign-in URL printed by the script → kill
   `enable-new-dashboard` on staging.
5. Return to FleetDesk — the headline changes to **Classic dispatch map is holding
   steady.**
6. Optional: expand **Developer tools** on FleetDesk to see the explain trace and flag
   snapshots.

For automation only: `scripts/demo/proof.sh`.

## What am I looking at?

| URL | What it is | What you'll see |
|-----|------------|-----------------|
| `http://localhost:3000` | **FleetDesk** — sample customer SaaS app | Dispatch dashboard, storm advisory, live map, route list |
| `http://localhost:4000/demo/sign-in` | **Rulestead admin** — mounted operator UI | Flag inventory, rollouts, kill switch, audit (auto sign-in) |
| `http://localhost:4000` | **Phoenix host + Rulestead API** | Orientation page + API links |
| `http://localhost:4000/api/flags` | Rulestead evaluation API | JSON flag payloads for integrators |

These are the preferred default URLs. If those ports are already in use,
`scripts/demo/up.sh` chooses free fallback ports and prints the actual URLs.
Postgres and Redis stay on the internal Compose network by default.

Optional API sanity checks:

```bash
curl http://localhost:4000/api/demo/personas
curl "http://localhost:4000/api/flags?env=staging&flag_key=enable-new-dashboard"
```

**Stack:**

- `examples/demo/backend/` — Phoenix host embedding `rulestead` + mounted `rulestead_admin`
- `examples/demo/frontend/` — external Next.js app consuming flags through a custom OpenFeature web provider

## Who this is for

| Persona | Question | What to try in FleetDesk |
|---------|----------|--------------------------|
| App developer (Alex) | "Will this fit my Phoenix app?" | Compose boot, `/api/flags`, OpenFeature client |
| Tech lead (Tova) | "Can we roll out safely?" | Enterprise account → vector map v2; guarded rollout seeds |
| Operator (Priya) | "What does the admin feel like?" | Mounted admin at `/demo/sign-in`, rollout and audit screens |
| Support (Sam) | "Can we explain one user's outcome?" | Developer tools explain trace + `/admin/flags/:key/simulate` |
| SRE (Shiori) | "Can we kill a flag at 3am?" | Kill switch on `enable-new-dashboard` |
| Evaluator (any) | "Should we adopt this?" | Run `scripts/demo/proof.sh` and click through |

The six flows in [User Flows and JTBD](user-flows-and-jtbd.md) map to concrete demo
actions — FleetDesk is the runnable version of that mental model.

## Persona click paths

Pick the path that matches your question. Each is a few minutes in the browser.

### Evaluator — 5-minute adoption loop

1. Open `http://localhost:3000` — note the storm advisory and dispatch workspace.
2. Switch **View as** to **Morgan Chen · Acme Logistics (Enterprise)** — map flips to
   vector v2.
3. Expand **Developer tools** and read the explain trace.
4. Open `http://localhost:4000/demo/sign-in` → kill `enable-new-dashboard` on staging.
5. Return to FleetDesk — headline changes to **Classic dispatch map is holding steady.**

### Operator — admin feel

1. Open `http://localhost:4000/demo/sign-in`.
2. Browse flag inventory at `/admin/flags?env=staging`.
3. Open rollouts for `fleet-map-v2` or `dispatch-guarded-rollout`.
4. Filter audit at `/admin/flags/audit`.

### Support — explain one outcome

1. Open `http://localhost:3000`, expand **Developer tools**, and read the explain trace.
2. In admin, open simulate for `enable-new-dashboard` and compare the trace.

### SRE — kill switch

1. Open `http://localhost:4000/demo/sign-in`.
2. Engage the kill switch for `enable-new-dashboard` on staging.
3. Confirm FleetDesk at `http://localhost:3000` flips.
4. Review the audit timeline for the kill event.

### When something doesn't load

- Run `docker compose ps` — are all four services healthy?
- Run `scripts/demo/smoke.sh` for automated health checks. It tears the stack down
  when it finishes unless you set `DEMO_SMOKE_KEEP_STACK=1`. Use `scripts/demo/proof.sh`
  for bounded automation without losing a stack you are clicking through.
- See [FleetDesk demo (examples/demo)](https://github.com/szTheory/rulestead/tree/main/examples/demo) for Playwright and CI
  commands.

## Two proof paths

Rulestead ships two complementary adopter proofs. Use both when you need maximum
confidence before integrating.

### Path A — FleetDesk (full stack, pre-installed)

Best for: evaluators, operators, and support personas who want a browser-ready system
with seeded flags, accounts, and mounted admin.

From the repo root:

```bash
docker compose up --build
```

**Honest boundary:** FleetDesk is a **pre-installed** host. Compose builds an image that
already ran `mix rulestead.install` and seeds. It proves host-shaped integration, not
your app's first-hour installer run.

Bounded automation (smoke + contract tests, no browser):

```bash
scripts/demo/proof.sh
```

Full automation (smoke + Playwright — same as CI integration job):

```bash
scripts/demo/verify.sh
```

### Path B — Fresh install journey (first-hour wiring)

Best for: Phoenix integrators validating `mix rulestead.install` → migrate → runtime
wiring in an ephemeral host app.

```bash
scripts/demo/install_journey.sh
```

This reuses the golden-diff installer contract under
`rulestead/fixtures/install_golden/` and asserts generated Phoenix wiring. It does not
boot FleetDesk or the Next.js frontend.

CI runs install-journey proof on the `install_journey` scoped lane (see
[Testing](../recipes/testing.md)). Merge-blocking CI still uses FleetDesk smoke +
`mix verify.adopter`.

## Seeded fixtures

After `mix run priv/repo/seeds.exs` (also run by the compose entrypoint):

- **Accounts:** Jordan Lee (pro), Morgan Chen (enterprise), Riley Park (starter)
- **Flags:** `enable-new-dashboard`, `fleet-map-v2`, `dispatch-ops-copy`, `ops-banner-config`, `dispatch-guarded-rollout`, `ops-audience-preview`
- **Environments:** staging + production

Persona metadata: `GET /api/demo/personas`

Implementation detail lives in [examples/demo on GitHub](https://github.com/szTheory/rulestead/tree/main/examples/demo).

## Journey map

| Journey | Persona | Flag(s) | Proof |
|---------|---------|---------|-------|
| Install + evaluate | Alex | all flags via `/api/flags` | Compose boot + smoke |
| Targeted rollout | Tova | `fleet-map-v2` | Enterprise account → map v2 on |
| Experiment copy | Priya | `dispatch-ops-copy` | Seeded headline variant |
| Remote config | Priya | `ops-banner-config` | Storm advisory banner |
| Explain decision | Sam | `enable-new-dashboard` | `/api/flags/explain` trace |
| Kill switch | Shiori | `enable-new-dashboard` | Admin kill → FleetDesk flips |
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
