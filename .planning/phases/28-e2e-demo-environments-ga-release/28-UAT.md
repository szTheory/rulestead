---
status: complete
mode: shift-left
phase: 28-e2e-demo-environments-ga-release
source:
  - 28-VALIDATION.md
  - 28-01-SUMMARY.md
  - 28-02-SUMMARY.md
  - 28-03-SUMMARY.md
  - 28-04-SUMMARY.md
  - examples/demo/frontend/package.json
  - examples/demo/frontend/playwright.config.ts
  - examples/demo/frontend/tests/rulestead-web-provider.test.ts
started: 2026-05-21T16:12:37Z
updated: 2026-05-21T18:13:34Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Automation Map

- Compose graph and readiness contract:
  `docker compose config`
- Backend bridge and seeded demo data:
  `cd examples/demo/backend && mix test test/rulestead_demo_web/controllers/flag_controller_test.exs test/rulestead_demo_web/controllers/flag_stream_controller_test.exs test/rulestead_demo/demo_seed_smoke_test.exs`
- Frontend OpenFeature provider contract:
  `cd examples/demo/frontend && npm test -- --runInBand tests/rulestead-web-provider.test.ts`
- Frontend production build:
  `cd examples/demo/frontend && npm run build`
- Cold-start smoke path:
  `scripts/demo/smoke.sh`
- Browser toggle proof:
  `cd examples/demo/frontend && npm run test:e2e`

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running demo services, start the application from scratch through the root Compose path, and observe healthy Postgres, Redis, backend, and frontend services with seeded admin/frontend surfaces reachable.
result: pass

### 2. Demo operator sign-in reaches the mounted Admin UI
expected: The deterministic `/demo/sign-in` route establishes the demo operator session, writes the mounted-admin session context, and redirects into `/admin/flags?env=staging`.
result: pass

### 3. The host-owned bridge resolves seeded flag state and emits bounded live updates
expected: `/api/flags` returns the seeded `enable-new-dashboard` evaluation state for `staging`, and `/api/flags/stream` emits bounded `configuration-changed` events suitable for frontend refresh.
result: pass

### 4. The external demo frontend consumes seeded state through OpenFeature
expected: The Next.js demo frontend builds cleanly and its provider resolves seeded backend state into an obvious flag-driven UI delta without direct database or cache access.
result: pass

### 5. The browser proof executes the Admin-to-frontend toggle loop
expected: `npm run test:e2e` runs the Playwright demo proof, signs in through `/demo/sign-in`, toggles the seeded flag in mounted Admin, and observes the frontend update without restart.
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
