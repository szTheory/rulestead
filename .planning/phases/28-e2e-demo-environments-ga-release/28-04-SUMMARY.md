# 28-04 Summary

## Status

Completed on 2026-05-21.

## Outcome

Expanded the root `docker-compose.yml` into the four-service Phase 28 graph, added deterministic backend container boot through `examples/demo/backend/entrypoint.sh`, added `scripts/demo/smoke.sh`, wired the frontend Playwright proof, and documented the one-command demo path in the root README plus `examples/demo/README.md`.

## Verification

- `docker compose config`
- `cd examples/demo/backend && MIX_ENV=prod mix compile`
- `cd examples/demo/backend && MIX_ENV=prod mix assets.deploy`
- `DEMO_SMOKE_KEEP_STACK=1 ./scripts/demo/smoke.sh`
- `cd examples/demo/frontend && npm run test:e2e`

## Notes

- The backend Dockerfile needed a compile-order fix: `mix compile` must run before `mix assets.deploy` so LiveView colocated hooks are generated under `_build/prod/phoenix-colocated`.
