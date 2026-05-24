# Demo Stack

This directory contains the Phase 28 GA demo stack:

- `backend/` is a thin Phoenix host app that embeds `rulestead` and mounts `rulestead_admin`
- `frontend/` is an external Next.js sample app that consumes the backend bridge through OpenFeature

This is the primary runnable proof path for the current `0.1.0` package line.
If you need support truth beyond static docs, start here, then pair it with
`mix verify.release_publish <version>` and `mix verify.release_parity <version>`
from the runtime package.

## One-command boot

From the repo root:

```bash
docker compose up --build
```

Services:

- Admin + backend: `http://localhost:4000`
- Deterministic sign-in: `http://localhost:4000/demo/sign-in`
- Frontend demo: `http://localhost:3000`
- Postgres: `localhost:5432`
- Redis: `localhost:6379`

## Expected demo loop

1. Open `http://localhost:3000` and confirm the page says `The new operator cockpit is live.`
2. Open `http://localhost:4000/demo/sign-in` to enter the mounted Admin UI as the deterministic demo operator.
3. Visit `http://localhost:4000/admin/flags/enable-new-dashboard/kill?env=staging`.
4. Enter a reason and submit `Confirm kill switch`.
5. Return to the frontend and confirm it flips to `The classic cockpit is holding.`

## Automation

Smoke verification:

```bash
scripts/demo/smoke.sh
```

Browser proof:

```bash
cd examples/demo/frontend
npm install
npx playwright install chromium
DEMO_BACKEND_URL=http://127.0.0.1:4000 DEMO_FRONTEND_URL=http://127.0.0.1:3000 npm run test:e2e
```

## What this proves

- A host Phoenix app can install `rulestead`, mount `rulestead_admin`, and
  serve a deterministic end-to-end flow locally.
- The frontend bridge path is discoverable through the demo, but it remains a
  companion proof surface rather than the primary product front door.
- This demo complements, but does not replace, the published-release checks
  from `mix verify.release_publish <version>` and
  `mix verify.release_parity <version>`.
